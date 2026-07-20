import QtQuick
import Quickshell.Hyprland

import "../components"
import "./"
import "../../Colors.js" as Colors

Item {
    id: root

    required property HyprlandMonitor exclusiveMonitor

    implicitHeight: iconContainer.implicitHeight + popup.implicitHeight
    implicitWidth: Math.max(icons.implicitWidth + icons.anchors.rightMargin*2, popup.width)

    property real margin: 8

    property real iconSize: Colors.barHeight - margin

    Container {
        id: iconContainer
        exclusiveMonitor: root.exclusiveMonitor
        anchors {
            top: parent.top
            right: parent.right
        }
        boxWidth: icons.implicitWidth + icons.anchors.rightMargin*2
        boxHeight: Colors.barHeight
        Row {
            id: icons

            anchors.right: parent.right
            anchors.rightMargin: root.margin
            // anchors.verticalCenter: parent.verticalCenter
            anchors.top: parent.top
            anchors.topMargin: root.margin/2

            spacing: 4

            Battery {
                iconSize: root.iconSize
                exclusiveMonitor: root.exclusiveMonitor

                popupContainer: popup
            }
        }
    }

    PopupContainer {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: root.margin + root.iconSize
            rightMargin: root.margin
        }
        exclusiveMonitor: root.exclusiveMonitor
        id: popup
    }
}