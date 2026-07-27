import QtQuick
import Quickshell.Hyprland

import "../components"
import "./"
import "../../Colors.js" as Colors

Item {
    id: root

    required property HyprlandMonitor exclusiveMonitor

    implicitHeight: iconContainer.implicitHeight + popup.implicitHeight
    implicitWidth: Math.max(iconContainer.width, popup.width)

    property real margin: 8

    property real iconSize: Colors.barHeight - margin

    Container {
        id: iconContainer
        exclusiveMonitor: root.exclusiveMonitor
        anchors {
            top: parent.top
            right: parent.right
        }
        boxWidth: icons.width + icons.anchors.rightMargin*2
        boxHeight: Colors.barHeight
        Row {
            id: icons

            anchors.right: parent.right
            anchors.rightMargin: root.margin
            // anchors.verticalCenter: parent.verticalCenter
            anchors.top: parent.top
            anchors.topMargin: root.margin/2
            // anchors.fill: parent

            spacing: 4

            // Item {
            //     clip: true
            //     // height: root.height
            //     anchors {
            //         top: parent.top
            //         bottom: parent.bottom
            //         right: parent.right
            //     }
            //     width: iconContainer.hover.hovered ? 100 : 0

            //     Row {
            //         id: tray
            //         anchors {
            //             top: parent.right
            //             right: parent.right
            //             // bottom: parent.bottom
            //         }
            //         height: parent.height
            //         width: animatedWidth
            //         property real animatedWidth: parent.width

            //         Behavior on animatedWidth {
            //             NumberAnimation {
            //                 duration: 200
            //                 easing.type: Easing.Linear
            //             }
            //         }

            //         spacing: 4
                    
                    
            //     }
            // }

            Bluetooth {
                iconSize: root.iconSize
                exclusiveMonitor: root.exclusiveMonitor
                
                popupContainer: popup
            }

            Network {
                iconSize: root.iconSize
                exclusiveMonitor: root.exclusiveMonitor
            }

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
            rightMargin: root.margin
        }
        visibleTopMargin: root.margin + root.iconSize

        exclusiveMonitor: root.exclusiveMonitor
        id: popup
    }
}