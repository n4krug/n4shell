import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../components"
import "../../services"

Container {
    id: root

    anchoredSides: [Container.Top, Container.Left]
    boxHeight: 20

    implicitWidth: workspaces.implicitWidth + workspaces.anchors.leftMargin + 8

    required property HyprlandMonitor monitor

    content: [
        Row {
            id: workspaces
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            spacing: 4

            Repeater {
                model: WorkspaceManager.getWorkspacesForMonitor(root.monitor)


                Rectangle {
                    id: box
                    required property HyprlandWorkspace modelData

                    radius: 4

                    implicitWidth: 12
                    implicitHeight: 12

                    color: modelData.active ? "#00FFFF" : "#005555" 

                    Text {
                        text: box.modelData.name
                        visible: !box.modelData.active
                        anchors.centerIn: parent
                        font.bold: true
                        font.pixelSize: 8
                        color: "white"
                        font.family: "JetBrainsMono Nerd Font Mono"
                    }
                }
            }
        }
    ]
}