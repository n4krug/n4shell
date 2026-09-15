import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "components"
import "center"
import "left"
import "right"
import "../drawing"
import "../Colors.js" as Colors
import "../services"
import "../settings"
import "."

Scope {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: win

                required property var modelData
                property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)


                color: "transparent"
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: 21

                screen: modelData

                WlrLayershell.keyboardFocus: CenterMenu.anyShown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                anchors {
                    top: true
                    left: true
                    right: true
                }

                DrawCanvas {
                    anchors.fill: parent
                    monitor: win.monitor
                }
                    
                implicitHeight: monitor.height / monitor.scale

                mask: Region {
                    Region {
                        item: left
                    }

                    Region {
                        item: center
                    }

                    Region {
                        item: right
                    }

                    Region {
                        item: notifications
                    }
                    
                    Region {
                        item: appLauncher
                    }
                    
                    Region {
                        item: settings
                    }
                }

                Item {
                    anchors {
                        fill: parent
                        topMargin: 0
                    }

                    Container {
                        exclusiveMonitor: win.monitor
                        anchors {
                            top: parent.top
                            right: parent.right
                            left: parent.left
                        }
                        boxHeight: 1
                    }

                    
                    Column {
                        id: notifications

                        anchors {
                            top: parent.top
                            topMargin: Colors.barHeight + 8
                            right: parent.right
                            rightMargin: 8
                        }

                        spacing: 8

                        Repeater {
                            model: NotificationManager.notifications

                            delegate: NotificationBox {
                                exclusiveMonitor: win.monitor
                            }
                        }
                    }

                    VolumePopup {
                        exclusiveMonitor: win.monitor
                    }

                    Launcher {
                        id: appLauncher

                        exclusiveMonitor: win.monitor
                        anchors.centerIn: parent
                    }
                    
                    Settings {
                        id: settings

                        exclusiveMonitor: win.monitor
                        anchors.centerIn: parent
                    }
                    
                    Row {
                        id: left

                        height: childrenRect.height

                        Left {
                            monitor: win.monitor
                            exclusiveMonitor: win.monitor
                        }
                    }
                    
                    Row {
                        id: center

                        height: childrenRect.height

                        anchors {
                            horizontalCenter: parent.horizontalCenter
                        }

                        Center {
                            exclusiveMonitor: win.monitor
                        }
                    }

                    Row {
                        id: right

                        height: childrenRect.height

                        anchors {
                            right: parent.right
                        }

                        Right {
                            exclusiveMonitor: win.monitor
                        }
                    }
                }

                // Column {
                //     id: notifications

                //     anchors {
                //         top: parent.top
                //         topMargin: Colors.barHeight + 8
                //         right: parent.right
                //         rightMargin: 8
                //     }

                //     spacing: 8

                //     Repeater {
                //         model: NotificationManager.notifications

                //         delegate: NotificationBox {
                //             exclusiveMonitor: Hyprland.monitorFor(modelData)
                //         }
                //     }
                // }
            }
        }
    }
}