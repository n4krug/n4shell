import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Hyprland
import Quickshell.Widgets

import "../components"
import "../../Colors.js" as Colors




Container {
    id: root
    exclusiveMonitor: root.exclusiveMonitor

    required property bool open
    anchors {
        top: parent.bottom
        right: parent.right
        rightMargin: 5
        topMargin: 4
    }
    boxHeight: 100
    boxWidth: 100

    Rectangle {
        id: rect
        anchors.fill: parent
        opacity: 0.5
    }

    hover.onHoveredChanged: {
        console.log("hover")
        if (hover.hovered) {
            rect.color = "green"
        } else {
            rect.color = "red"
        }
    }

    HoverHandler {
        id: hoverHandler
    }
 }