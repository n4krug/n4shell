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

                TapHandler {
                    onTapped: {
                        box.modelData.activate()
                    }
                }

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

                color: modelData.active ? Colors.bg3 : "transparent"

                Text {
                    text: box.modelData.name
                    anchors.centerIn: parent
                    font.bold: true
                    font.pixelSize: Colors.barHeight - 10
                    color: box.modelData.active && !box.modelData.focused ? Colors.bg1 : Colors.text
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

    Rectangle {
        id: focusIndicator

        property int oldIndex: 0
        readonly property real targetWidth: Colors.barHeight - workspaces.anchors.leftMargin

        property real animatedLeft: 0
        property real animatedRight: targetWidth
        
        readonly property real fast: 80
        readonly property real slow: 300

        property real leftDuration: fast
        property real rightDuration: fast

        height: targetWidth
        width: animatedRight - animatedLeft
        x: animatedLeft + workspaces.anchors.leftMargin
        y: workspaces.anchors.leftMargin/2

        color: Colors.highlight

        radius: 4

        // property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace

        // onFocusedWorkspaceChanged: {
        //     move()
        // }

        readonly property var numberedWorkspaces: WorkspaceManager.getAllNumberedWorkspaces()
        readonly property int focusIndex: numberedWorkspaces.findIndex(w => w.focused)
        onNumberedWorkspacesChanged: move()
        onFocusIndexChanged: move()
        function slotX(index) {
            return index * (targetWidth + workspaces.spacing)
        }

        function move() {
            const index = focusIndex
            const left = slotX(index)
            const right = left + targetWidth

            if (index > oldIndex) { // moving right
                rightDuration = fast
                leftDuration = slow
            } else if (index < oldIndex) { // moving left
                rightDuration = slow
                leftDuration = fast
            }

            animatedLeft = left
            animatedRight = right

            oldIndex = index
        }

        Component.onCompleted: {
            move()
        }

        Behavior on animatedLeft {
            NumberAnimation {
                duration: focusIndicator.leftDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on animatedRight {
            NumberAnimation {
                duration: focusIndicator.rightDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}