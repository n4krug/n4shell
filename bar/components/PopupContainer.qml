import QtQuick

import "../components"
import "../../Colors.js" as Colors

Container {
    id: root
    property real margin: 4
    default property Component source

    property real animatedOpacity: 0
    opacity: animatedOpacity

    readonly property bool shown: loader.active

    Behavior on animatedOpacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.Linear
        }
    }

    hiddenTopMargin: - (Colors.barHeight + root.height)
    forceHidden: true

    Loader {
        id: loader
        sourceComponent: root.source
        active: false
        onLoaded: {
            item.parent = root;
            // item.anchors.fill = root
        }
        anchors.fill: parent
    }

    boxHeight: loader.item ? loader.item.implicitHeight + margin*2 : 0
    boxWidth: loader.item ? loader.item.implicitWidth + margin*2 : 0

    function show(component) {
        root.source = component
        loader.active = true
        animatedOpacity = 1
        forceHidden = false
    }

    function hide() {
        animatedOpacity = 0
        forceHidden = true
        // loader.active = false
        deactivateTimer.start()
    }

    Timer {
        id: deactivateTimer
        repeat: false
        running: false
        onTriggered: {loader.active = false}
        interval: 200
    }

    hover.onHoveredChanged: {
        if (opacity == 1 && !hover.hovered) {
            hide()
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 0
        }
    }
}