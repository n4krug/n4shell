import QtQuick
import Quickshell.Hyprland

import "../components"
import "./"
import "../../Colors.js" as Colors

Container {
    id: root

    boxHeight: Colors.barHeight
    boxWidth: icons.implicitWidth + icons.anchors.rightMargin*2

    property real iconSize: Colors.barHeight - 8

    Row {
        id: icons

        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        spacing: 4

        Battery {
            iconSize: root.iconSize
            exclusiveMonitor: root.exclusiveMonitor
        }
    }
}