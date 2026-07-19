import QtQuick
import Quickshell
import Quickshell.Hyprland

import "components"
import "center"
import "left"
import "right"
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
                exclusiveZone: 21

                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
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

                    Container {
                        exclusiveMonitor: win.monitor
                        anchors {
                            top: parent.top
                            right: parent.right
                            left: parent.left
                        }
                        boxHeight: 1
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
                        // Container {
                        //     exclusiveMonitor: win.monitor
                        //     anchoredSides: []
                        //     hiddenTopMargin: (4-boxHeight)
                        //     visibleTopMargin: 5
                        //     forceHidden: true
                        //     hoverableWhenHidden: true
                        // }
                    }
                }
            }
        }
    }
}