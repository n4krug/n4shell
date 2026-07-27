import QtQuick
import Quickshell
import QtQuick.Shapes
import Quickshell.Hyprland

import "BoxUnion.js" as BoxUnion
import "../Colors.js" as Colors
import "./"

Canvas {
    id: canvas
    required property HyprlandMonitor monitor

    Connections {
        target: DrawRegistry
        ignoreUnknownSignals: true
        function onItemsChanged() { canvas.requestPaint() }
        function onItemGeometryChanged() { canvas.requestPaint() }
    }

    property real radius: 12

    onPaint: {
        const items = DrawRegistry.getOnMonitor(monitor)

        const rects = BoxUnion.rectsFromItems(items)

        const contours = BoxUnion.unionRectangles(rects)

        const rounded = []
        
        contours.forEach(contour => {
            rounded.push(BoxUnion.roundPath(contour["points"], radius, { x: canvas.x, y: canvas.y }, { x: canvas.x + canvas.width, y: canvas.y + canvas.height }))
        })

        const ctx = getContext('2d')

        ctx.reset()
        ctx.clearRect(0,0, width, height)

        rounded.forEach(contour => {
            
            ctx.beginPath()
            ctx.strokeStyle = Hyprland.focusedMonitor == canvas.monitor ? Colors.outline : Colors.bg2
            ctx.fillStyle = Colors.bg1
            ctx.lineWidth = Colors.outlineWidth
            ctx.lineJoin = "round"

            contour.forEach(point => {
                if (point.length == 6) { // Bezier
                    ctx.bezierCurveTo(point[0], point[1], point[2], point[3], point[4], point[5])                    
                } else { // Straight
                    ctx.lineTo(point[0], point[1])
                }
            })

            ctx.stroke()
            ctx.fill()
        })

    }

}