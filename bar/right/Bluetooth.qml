import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

import "../../Colors.js" as Colors
import "../components"
import "../../services"

pragma ComponentBehavior: Bound

Container {
    id: root
    required property real iconSize
    required property PopupContainer popupContainer
    readonly property real itemHeight: 32
    boxHeight: iconSize
    boxWidth: iconSize

    visible: Bluetooth.defaultAdapter.enabled

    Text {
		text: BluetoothManager.getConnected() == true ? "bluetooth_connected" : BluetoothManager.defaultAdapter.enabled ? "bluetooth" : "bluetooth_disabled"
        color: BluetoothManager.defaultAdapter.enabled ? Colors.text : Colors.negative
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

    Component {
        id: bluetoothPopup

        Container {
            exclusiveMonitor: root.exclusiveMonitor
            boxHeight: Math.min(400, (root.itemHeight)*BluetoothManager.getDevicesList().length + (BluetoothManager.getDevicesList().length-1)*listView.spacing + listView.anchors.margins*2)
            boxWidth: 200

            ListView {
                boundsBehavior: Flickable.StopAtBounds

                id: listView
                clip: true
                model: BluetoothManager.getDevicesList()

                spacing: 4

                anchors {
                    fill: parent
                    margins: 8
                }

                delegate: Item {
                    id: itemRoot
                    implicitHeight: root.itemHeight
                    required property real index
                    required property BluetoothDevice modelData
                    anchors {
                        right: parent.right
                        left: parent.left
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: Colors.bg1

                        radius: Colors.radius

                        border {
                            color: itemRoot.modelData.connected ? Colors.highlight : Colors.bg2
                            width: 3
                        }

                        states: [
                            State {
                                name: "hovered"

                                PropertyChanges {
                                    colorBox {
                                        animatedOpacity: 0.5
                                        color: Colors.bg2
                                    }
                                }
                            }
                        ]


                        HoverHandler {
                            onHoveredChanged: hovered == true ? parent.state = "hovered" : parent.state = ""
                        }


                        Rectangle {
                            id: colorBox
                            anchors.fill: parent
                            color: "transparent"
                            opacity: animatedOpacity
                            radius: Colors.radius
                            
                            property real animatedOpacity: 0
                            // Behavior on animatedOpacity {
                            //     NumberAnimation {
                            //         duration: 200
                            //         easing: Easing.InOutCubic
                            //     }
                            // }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 8
                            }

                            Text {
                                text: BluetoothManager.getIcon(itemRoot.modelData.icon)
                                color: Colors.text
                                font.family: "Material Symbols Rounded" // Or Material Icons
                                font.variableAxes: {
                                    "FILL": 0,
                                    "wght": 600,
                                    "GRAD": 0,
                                    "opsz": root.iconSize
                                }
                            }
                            Text {
                                text: itemRoot.modelData.deviceName
                                color: Colors.text
                                // anchors.centerIn: parent
                            }
                        }

                    }
                }
            }
        }
    }
    
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.popupContainer.show(bluetoothPopup)
    }
}