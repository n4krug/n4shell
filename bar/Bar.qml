import QtQuick
import Quickshell
import Quickshell.Hyprland

import "components"
import "center"
import "left"
import "../drawing"

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
                exclusiveZone: 20

                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                }

                Container {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.left: parent.left
                    implicitHeight: 5

                    exclusiveMonitor: win.monitor
                    
                    Component.onCompleted: {
                        DrawRegistry.addItem(this)
                    }

                    // Rectangle {
                    //     color: "green"
                    //     anchors.fill: parent
                    // }
                }

                Canvas {
                    anchors.fill: parent
                    monitor: win.monitor
                }
                    
                implicitHeight: 1000

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
                }

                Item {
                    anchors {
                        fill: parent
                        topMargin: 0
                    }

                    
                    Row {
                        id: left

                        height: childrenRect.height

                        anchors {
                            left: parent.left
                        }

                        // Container {
                        //     exclusiveMonitor: win.monitor
                        //     anchoredSides: [Container.Top, Container.Left]
                        //     boxTLRadius: 0
                        //     boxHeight: 16
                        //     boxRadius: 8
                        //     boxTRRadius: -boxRadius
                        //     boxBLRadius: 0
                        // }

                        Left {
                            monitor: win.monitor
                            exclusiveMonitor: win.monitor
                            Component.onCompleted: {
                                DrawRegistry.addItem(this)
                            }
                        }
                    }
                    
                    Row {
                        id: center

                        height: childrenRect.height

                        anchors {
                            horizontalCenter: parent.horizontalCenter
                        }

                        // Container {
                        //     exclusiveMonitor: win.monitor
                        //     hoverableWhenHidden: true
                        //     exclusiveToScreen: true
                        //     // forceHidden: true
                        //     hiddenTopMargin: (4-boxHeight)
                        //     boxHeight: 25
                        //     boxRadius: 12
                        //     boxTLRadius: -boxRadius
                        //     boxTRRadius: -boxRadius
                        //     anchoredSides: [Container.Top]
                        // }
                        Center {
                            exclusiveMonitor: win.monitor
                            Component.onCompleted: {
                                DrawRegistry.addItem(this)
                            }
                        }
                    }

                    Row {
                        id: right

                        height: childrenRect.height

                        anchors {
                            right: parent.right
                        }

                        Container {
                            exclusiveMonitor: win.monitor
                            anchoredSides: [Container.Top]
                            boxTRRadius: 0
                            boxRadius: 12
                            boxTLRadius: -boxRadius
                            boxBRRadius: 0
                            hiddenTopMargin: (4-boxHeight)
                            forceHidden: true
                            hoverableWhenHidden: true
                            Component.onCompleted: {
                                DrawRegistry.addItem(this)
                            }
                        }
                    }
                }
            }
        }
    }
}