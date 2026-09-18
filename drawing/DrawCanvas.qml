import QtQuick
import Quickshell
import QtQuick.Shapes
import Quickshell.Hyprland

import "BoxUnion.js" as BoxUnion
import "../Colors.js" as Colors
import "./"

// The bar/popup chrome is drawn as the union of every registered Container.
//
// This used to be a Canvas, which meant a full-viewport CPU rasterisation
// (clearRect + full texture re-upload) on every animation frame. It is now a
// Shape with the CurveRenderer, so the same geometry is tessellated and
// rasterised on the GPU and the per-frame cost is limited to rebuilding a
// small SVG path string.
Shape {
    id: shape
    required property HyprlandMonitor monitor

    // Keep the outline in lockstep with the animated boxes instead of lagging
    // a frame behind them.
    asynchronous: false
    preferredRendererType: Shape.CurveRenderer

    property real radius: 12

    // Bumped when anything registered with DrawRegistry moves. DrawRegistry
    // already coalesces the raw emissions with Qt.callLater, so this is at most
    // one rebuild per frame.
    property int revision: 0

    Connections {
        target: DrawRegistry
        ignoreUnknownSignals: true
        function onItemsChanged() { shape.revision++ }
        function onItemGeometryChanged() { shape.revision++ }
    }

    readonly property string svgPath: buildPath(revision, width, height)

    // Cache holder. Mutating the fields of this object does not notify QML
    // bindings, so writing to it from inside the binding above is safe.
    property var cache: ({ signature: "", path: "" })

    function buildPath(revision, w, h) {
        const items = DrawRegistry.getOnMonitor(monitor)
        const rects = BoxUnion.rectsFromItems(items)

        const signature = BoxUnion.rectsSignature(rects, w, h)
        if (signature === cache.signature)
            return cache.path

        const min = { x: 0, y: 0 }
        const max = { x: w, y: h }

        const contours = BoxUnion.unionRectangles(rects)

        let path = ""
        contours.forEach(contour => {
            path += BoxUnion.roundedSvgPath(contour["points"], radius, min, max)
        })

        cache.signature = signature
        cache.path = path
        return path
    }

    // ShapePath renders the stroke on top of the fill, but the old Canvas code
    // did ctx.stroke() then ctx.fill(), so the fill covered the inner half of
    // the line and only the OUTER half of the outline was ever visible. Two
    // stacked ShapePaths reproduce that layering: without it the outline is
    // twice as thick, and it no longer disappears where it runs off the edge
    // of the surface (the outer half is outside the surface, so it was clipped).
    ShapePath {
        // Outline only. Full stroke width, centred on the path.
        fillColor: "transparent"
        strokeColor: Hyprland.focusedMonitor == shape.monitor ? Colors.outline : Colors.bg2
        strokeWidth: Colors.outlineWidth
        joinStyle: ShapePath.RoundJoin
        capStyle: ShapePath.RoundCap

        PathSvg {
            path: shape.svgPath
        }
    }

    ShapePath {
        // Fill only, painted over the outline so just the outer half shows.
        fillColor: Colors.bg1
        // Holes (contours with negative area) punch through the fill.
        fillRule: ShapePath.OddEvenFill
        strokeWidth: 0

        PathSvg {
            path: shape.svgPath
        }
    }
}
