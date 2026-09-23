import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications

import "../components"
import "./"
import "../../services"
import "../../Colors.js" as Colors
pragma ComponentBehavior: Bound
Item {
    id: root

    required property HyprlandMonitor exclusiveMonitor

    implicitHeight: iconContainer.implicitHeight + popup.implicitHeight
    implicitWidth: Math.max(iconContainer.width, popup.width)

    property real margin: 6

        property real iconSize: Colors.barHeight - margin

    // Tray icon currently under the cursor, used to keep the right click menu
    // open while the pointer is still on its anchor.
    property Item hoveredTray: null

    Container {
        id: iconContainer
        exclusiveMonitor: root.exclusiveMonitor
        anchors {
            top: parent.top
            right: parent.right
        }
        width: icons.width + icons.anchors.rightMargin*2
        boxHeight: Colors.barHeight
        Row {
            id: icons

            anchors.right: parent.right
            anchors.rightMargin: root.margin*1.5
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
            Container {
                id: sysTray
                exclusiveMonitor: root.exclusiveMonitor

                // anchors {
                //     right: root.right
                //     top: root.top
                // }
                // Rectangle {
                //     anchors.fill: parent
                //     opacity: 0.2
                // }

                boxHeight: root.iconSize
                boxWidth: iconContainer.hover.hovered || trayMenu.show ? sysTrayRow.implicitWidth : 0

                Row {
                    id: sysTrayRow
                    anchors.fill: parent
                    spacing: icons.spacing
                    Repeater {
                        model: SystemTray.items

                        MouseArea {
                            id: sysItem
                            height: root.iconSize
                            width: root.iconSize

                            required property SystemTrayItem modelData

                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            Image {
                                source: sysItem.modelData.icon
                                anchors.fill: parent
                            }

                            function openMenu() {
                                trayMenu.openFor(sysItem.modelData.menu, sysItem)
                            }

                            onClicked: mouse => {
                                const item = sysItem.modelData

                                if (mouse.button === Qt.RightButton) {
                                    if (item.hasMenu)
                                        sysItem.openMenu()
                                    else
                                        item.secondaryActivate()
                                    return
                                }

                                if (item.onlyMenu && item.hasMenu)
                                    sysItem.openMenu()
                                else
                                    item.activate()
                            }

                            onWheel: wheel => {
                                sysItem.modelData.scroll(wheel.angleDelta.y)
                                wheel.accepted = true
                            }

                            property bool hovered: false

                            onEntered: {
                                hovered = true
                                root.hoveredTray = sysItem
                            }

                            onExited: {
                                hovered = false
                                if (root.hoveredTray === sysItem)
                                    root.hoveredTray = null
                            }

                            hoverEnabled: true

                            Container {
                                exclusiveMonitor: root.exclusiveMonitor
                                height: root.iconSize*2

                                anchors {
                                    top: parent.bottom
                                    topMargin: 12
                                    horizontalCenter: parent.horizontalCenter

                                }

                                boxWidth: txt.width + root.iconSize*2

                                Text {
                                    id: txt
                                    text: sysItem.modelData.title
                                    color: Colors.text
                                    anchors.centerIn: parent
                                }

                                visible: sysItem.hovered

                            }

                        }
                    }
                }
            }

            Container {
                id: updates

                boxWidth: root.iconSize
                boxHeight: root.iconSize
                exclusiveMonitor: root.exclusiveMonitor

                visible: UpdateManager.updatesAvailable

                GlobalShortcut {
                    appid: "n4shell"
                    name: "check-updates"
                    onPressed: UpdateManager.refreshCount()
                }

                Text {
                    text: "update"
                    color: Colors.text
                    font.pixelSize: root.iconSize
                    anchors.centerIn: parent
                    font.family: "Material Symbols Rounded" // Or Material Icons
                    font.variableAxes: {
                        "FILL": 0,
                        "wght": 600,
                        "GRAD": 0,
                        "opsz": root.iconSize
                    }
                }

                TapHandler {
                    onTapped: CenterMenu.openMenu("updater", root.exclusiveMonitor)
                }

                Container {
                    visible: updates.hover.hovered

                    exclusiveMonitor: root.exclusiveMonitor
                    anchors {
                        top: parent.bottom
                        topMargin: 12
                        horizontalCenter: parent.horizontalCenter
                    }
                    boxWidth: updateTooltip.width + root.iconSize*2

                    Text {
                        id: updateTooltip
                        color: Colors.text
                        anchors.centerIn: parent

                        text: UpdateManager.updateCount
                    }
                }
            }

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

    // Submenus reuse the same component, which is why it is declared here
    // rather than inside TrayMenu.qml.
    Component {
        id: trayMenuComponent

        TrayMenu {
            exclusiveMonitor: root.exclusiveMonitor
            submenuComponent: trayMenuComponent
        }
    }

    TrayMenu {
        id: trayMenu

        exclusiveMonitor: root.exclusiveMonitor
        submenuComponent: trayMenuComponent
        anchorHovered: root.hoveredTray === trayMenu.anchorItem
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

    // Column {
    //     anchors {
    //         top: parent.bottom
    //         topMargin: 8
    //         right: parent.right
    //         rightMargin: 8
    //     }

    //     spacing: 8

    //     Repeater {
    //         model: NotificationManager.notifications

    //         delegate: NotificationBox {
    //             exclusiveMonitor: root.exclusiveMonitor
    //         }
    //     }
    // }
}