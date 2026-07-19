import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../components"
import "../../services"
import "../../Colors.js" as Colors

Container {
    id: root

    anchoredSides: [Container.Top, Container.Left]
    boxHeight: 20

    implicitWidth: workspaces.implicitWidth + workspaces.anchors.leftMargin*2

    required property HyprlandMonitor monitor


    Row {
        id: workspaces
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        spacing: 4


        Repeater {
            // model: WorkspaceManager.getWorkspacesForMonitor(root.monitor)
            model: WorkspaceManager.getAllNumberedWorkspaces()

            Rectangle {
                id: box
                required property HyprlandWorkspace modelData

                radius: 4

                implicitWidth: 12
                implicitHeight: 12

                color: modelData.active ? modelData.focused ? Colors.highlight : Colors.bg2 : "transparent"

                Text {
                    text: box.modelData.name
                    visible: !box.modelData.active
                    anchors.centerIn: parent
                    font.bold: true
                    font.pixelSize: 10
                    color: Colors.text
                    // font.family: "JetBrainsMono Nerd Font Mono"
                }
            }
        }
    }
}