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

    property list<int> anchoredSides: []

    onGeometryChanged: DrawRegistry.itemGeometryChanged()

    onXChanged: geometryChanged()
    onYChanged: geometryChanged()
    onWidthChanged: geometryChanged()
    onBoxHeightChanged: geometryChanged()
    onCalculatedTopMarginChanged: geometryChanged()
    onAnimatedTopMarginChanged: geometryChanged()
    onBoxColorChanged: geometryChanged()
    onAnchoredSidesChanged: geometryChanged()

    Connections {
        target: root.parent
        ignoreUnknownSignals: true
        function onXChanged() { root.geometryChanged() }
        function onYChanged() { root.geometryChanged() }
        function onWidthChanged() { root.geometryChanged() }
    }

    function rectIn(target) {
        const topPt = root.mapToItem(target, 0, root.animatedTopMargin)
        const bottomPt = root.mapToItem(target, 0, root.animatedTopMargin + root.boxHeight)
        return { x: topPt.x, y: topPt.y, w: root.width, h: bottomPt.y - topPt.y }
    }

    function geomIn(target) {
        return {
            rect: rectIn(target),
            color: root.boxColor,
            anchoredSides: root.anchoredSides
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
            easing.type: Easing.Linear
        }
    }

    readonly property real visibleHeight: {
        return boxHeight + animatedTopMargin
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

    property alias content: contentHolder.children

    HoverHandler {
        id: hoverHandler
    }

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
    }

    Item {
        id: contentHolder
        anchors.fill: parent
        clip: true
        transform: Translate { y: root.animatedTopMargin }
    }
}