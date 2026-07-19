import QtQuick
import Quickshell.Hyprland

import "../components"
import "./"

Container {
    id: root

    boxHeight: 20
    boxWidth: icons.implicitWidth + icons.anchors.rightMargin*2

    property real iconSize: 12

    Row {
        id: icons

        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        spacing: 4

        Battery {
            iconSize: root.iconSize
            monitor: root.exclusiveMonitor
        }
    }
}