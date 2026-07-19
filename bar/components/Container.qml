import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

Item {
    id: root

    property color boxColor: "#009999"
    property real boxHeight: 28
    property real boxRadius: 8
    property var boxTLRadius: undefined
    property var boxTRRadius: undefined
    property var boxBRRadius: undefined
    property var boxBLRadius: undefined
    property real boxWidth: 100

    enum Anchor {
        Top,
        Bottom,
        Left,
        Right
    }

    property list<int> anchoredSides: []

    QtObject {
        id: boxRadii
        readonly property real tl: root.boxTLRadius !== undefined ? root.boxTLRadius : root.boxRadius
        readonly property real tr: root.boxTRRadius !== undefined ? root.boxTRRadius : root.boxRadius
        readonly property real br: root.boxBRRadius !== undefined ? root.boxBRRadius : root.boxRadius
        readonly property real bl: root.boxBLRadius !== undefined ? root.boxBLRadius : root.boxRadius
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

    readonly property real visibleHeight: {
        return boxHeight + calculatedTopMargin
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

    Rectangle {
        id: container

        property real yTranslate: root.calculatedTopMargin
        transform: Translate {
            y: container.yTranslate
        } 
        anchors.fill: parent
        clip: true
        color: root.boxColor
        topLeftRadius: boxRadii.tl
        topRightRadius: boxRadii.tr
        bottomRightRadius: boxRadii.br
        bottomLeftRadius: boxRadii.bl
        Behavior on yTranslate {
            animation: defaultCurve
        }
        NumberAnimation {
            id: defaultCurve

            duration: 200
            easing: Easing.Linear
        }

        Item {
            id: contentHolder
            anchors.fill: parent
        }
    }

    Item {
        id: invertedCorners
        anchors.fill: container
        // TOP
        InvertedCorner {
            visible: boxRadii.tl < 0 && root.anchoredSides.includes(Container.Top)
            corner: InvertedCorner.TopRight
            radius: Math.max(Math.min(-boxRadii.tl, root.visibleHeight - boxRadii.bl), 0)
            color: root.boxColor
            anchors.top: parent.top
            anchors.right: parent.left
        }

        InvertedCorner {
            visible: boxRadii.tr < 0 && root.anchoredSides.includes(Container.Top)
            corner: InvertedCorner.TopLeft
            radius: Math.max(Math.min(-boxRadii.tr, root.visibleHeight - boxRadii.br), 0)
            color: root.boxColor
            anchors.top: parent.top
            anchors.left: parent.right
        }

        // Bottom
        InvertedCorner {
            visible: boxRadii.br < 0 && root.anchoredSides.includes(Container.Bottom)
            corner: InvertedCorner.BottomLeft
            radius: Math.max(Math.min(-boxRadii.br, root.visibleHeight - boxRadii.tr), 0)
            color: root.boxColor
            anchors.top: parent.top
            anchors.left: parent.right
        }

        InvertedCorner {
            visible: boxRadii.bl < 0 && root.anchoredSides.includes(Container.Bottom)
            corner: InvertedCorner.BottomRight
            radius: Math.max(Math.min(-boxRadii.bl, root.visibleHeight - boxRadii.tl), 0)
            color: root.boxColor
            anchors.top: parent.top
            anchors.left: parent.right
        }

        // Left
        InvertedCorner {
            visible: boxRadii.tl < 0 && root.anchoredSides.includes(Container.Left)
            corner: InvertedCorner.BottomLeft
            radius: -boxRadii.tl
            color: root.boxColor
            anchors.bottom: parent.top
            anchors.left: parent.left
        }

        InvertedCorner {
            visible: boxRadii.bl < 0 && root.anchoredSides.includes(Container.Left)
            corner: InvertedCorner.TopLeft
            radius: -boxRadii.bl
            color: root.boxColor
            anchors.top: parent.bottom
            anchors.left: parent.left
        }

        // Right
        InvertedCorner {
            visible: boxRadii.tr < 0 && root.anchoredSides.includes(Container.Right)
            corner: InvertedCorner.BottomRight
            radius: -boxRadii.tr
            color: root.boxColor
            anchors.bottom: parent.top
            anchors.right: parent.right
        }

        InvertedCorner {
            visible: boxRadii.br < 0 && root.anchoredSides.includes(Container.Right)
            corner: InvertedCorner.TopRight
            radius: -boxRadii.br
            color: root.boxColor
            anchors.top: parent.bottom
            anchors.right: parent.right
        }

    }
}