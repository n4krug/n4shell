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

                Container { // thin 2px line at the top of the bar
                    id: topLine
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.left: parent.left
                    implicitHeight: 2

                    exclusiveMonitor: win.monitor
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

                        Container {
                            exclusiveMonitor: win.monitor
                            anchoredSides: [Container.Top]
                            hiddenTopMargin: (4-boxHeight)
                            forceHidden: true
                            hoverableWhenHidden: true
                        }
                    }
                }
            }
        }
    }
}