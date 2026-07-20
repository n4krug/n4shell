import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

import "../../drawing"

Item {
    id: root

    property color boxColor: "#009999"
    property real boxHeight: 28
    property real boxWidth: 100

    enum Anchor {
        Top,
        Bottom,
        Left,
        Right
    }

    property Item canvasRef: null

    signal geometryChanged

    Component.onCompleted: {
        DrawRegistry.addItem(this)
    }
    Component.onDestruction: {
        DrawRegistry.removeItem(this)
    }

    onGeometryChanged: DrawRegistry.itemGeometryChanged()

    onXChanged: geometryChanged()
    onYChanged: geometryChanged()
    onWidthChanged: geometryChanged()
    onBoxHeightChanged: geometryChanged()
    onCalculatedTopMarginChanged: geometryChanged()
    onAnimatedTopMarginChanged: geometryChanged()
    onBoxColorChanged: geometryChanged()

    Connections {
        target: root.parent
        ignoreUnknownSignals: true
        function onXChanged() { root.geometryChanged() }
        function onYChanged() { root.geometryChanged() }
        function onWidthChanged() { root.geometryChanged() }
    }

    function rectIn(target) {
        const topPt = root.mapToItem(target, 0, root.x)
        const bottomPt = root.mapToItem(target, 0, root.x + root.height)
        return { x: topPt.x, y: topPt.y, w: root.width, h: bottomPt.y - topPt.y }
    }

    function geomIn(target) {
        return {
            rect: rectIn(target),
            color: root.boxColor,
        }
    }

    readonly property real calculatedTopMargin: {
        if (root.exclusiveToScreen && Hyprland.focusedMonitor != root.exclusiveMonitor) {
            return root.hiddenTopMargin
        }

        if (forceHidden) {
            if (root.hoverableWhenHidden && hoverState.hovered) {
                return root.visibleTopMargin
            }
            return root.hiddenTopMargin
        }

        return root.visibleTopMargin
    }

    property real animatedTopMargin: root.calculatedTopMargin
    Behavior on animatedTopMargin {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutCubic
        }
    }
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutCubic
        }
    }

    property bool exclusiveToScreen: false
    required property HyprlandMonitor exclusiveMonitor
    property double visibleTopMargin: 0
    property bool forceHidden: false
    property bool hoverableWhenHidden: false
    property double hiddenTopMargin: 2 - root.boxHeight

    property alias hover: hoverHandler

    implicitHeight: boxHeight
    implicitWidth: boxWidth

    HoverHandler {
        id: hoverHandler
    }

    // Rectangle {
    //     anchors.fill: parent
    //     color: root.boxColor
    // }

    QtObject {
        id: hoverState
        property bool hovered: false
    }

    hover.onHoveredChanged: {
        if (hover.hovered) {
            hoverState.hovered = true
        }
        hoverTimer.start()
    }

    Timer {
        id: hoverTimer

        interval: 500
        repeat: false
        running: false

        onTriggered: {
            if (!root.hover.hovered) {
                hoverState.hovered = false
            }
        }
    }

    anchors {
        top: parent.top
        topMargin: root.animatedTopMargin
    }
}