import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import '../components'
import '../../services'

import '../../Colors.js' as Colors

Container {
    id: root

    readonly property int timeOut: 10 * 1000

    required property Notification modelData

    boxHeight: 48
    boxWidth: 256

    anchors {
        top: undefined
    }

    Row {
        padding: 8
        spacing: 16

        anchors {
            // horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        Image {
            id: icon
            visible: root.modelData.image

            source: root.modelData.image

            height: root.boxHeight - 16
            width: height
        }

        Column {
            width: root.width - 28 - (icon.visible ? icon.width + 16 : 0)
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: root.modelData.summary
                color: Colors.text
                enabled: root.modelData.appName
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: root.modelData.body
                color: Colors.text
                width: parent.width
                elide: Text.ElideRight
            }

        }
    }

    Rectangle {
        id: closeBtn
        
        Text {
            text: "close"
            font.family: "Material Symbols Rounded" // Or Material Icons
            font.pixelSize: 16
            font.variableAxes: {
                "FILL": 0,
                "wght": 600,
                "GRAD": 0,
                "opsz": 16
            }
            anchors.centerIn: parent
            color: Colors.text
        }

        height: 16
        width: 16

        color: "transparent"

        anchors {
            top: parent.top
            right: parent.right
            rightMargin: 4
            topMargin: 4
        }

        TapHandler {
            onTapped: {
                root.modelData.dismiss()
            }
        }

    }


    Timer {
        interval: root.timeOut
        repeat: false
        running: true
        onTriggered: {
            root.modelData.dismiss()
        }
    }
}