import QtQuick
import Quickshell
import Quickshell.Hyprland

import "../components"
import "../../services"
import "../../Colors.js" as Colors

Container {
    id: root

    boxHeight: Colors.barHeight

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
            model: ScriptModel {
                values: WorkspaceManager.getAllNumberedWorkspaces()
            }

            delegate: Rectangle {
                id: box
                required property HyprlandWorkspace modelData

                radius: 4

                implicitWidth: Colors.barHeight - workspaces.anchors.leftMargin 
                implicitHeight: Colors.barHeight - workspaces.anchors.leftMargin 

                property real animatedOpacity: 0
                opacity: animatedOpacity
                Component.onCompleted: {
                    animatedOpacity = 1
                }

                Behavior on animatedOpacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.Linear
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.InOutCubic
                    }
                }

                color: modelData.active ? modelData.focused ? Colors.highlight : Colors.bg3 : "transparent"

                Text {
                    text: box.modelData.name
                    anchors.centerIn: parent
                    font.bold: true
                    font.pixelSize: Colors.barHeight - 10
                    color: box.modelData.active ? !box.modelData.focused ? Colors.bg1 : "transparent" : Colors.text
                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                            easing.type: Easing.InOutCubic
                        }
                    }
                }
            }
        }
    }
}