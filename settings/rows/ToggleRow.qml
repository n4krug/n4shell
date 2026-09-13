import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../Colors.js" as Colors

Item {
    id: root

    property var row: null
    property var select: null
    property var openRequested: null

    opacity: root.row && root.row.enabled ? 1 : 0.4

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!root.row || !root.row.enabled)
                return

            if (root.select)
                root.select()

            root.row.activate()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 12

        Text {
            text: root.row ? root.row.icon : ""
            visible: text !== ""
            color: Colors.text
            font.family: "Material Symbols Rounded"
            font.pixelSize: 28
            font.variableAxes: {
                "FILL": 0,
                "wght": 600,
                "GRAD": 0,
                "opsz": 28
            }
            Layout.preferredWidth: 32
            horizontalAlignment: Text.AlignHCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.row ? root.row.title : ""
                color: Colors.text
                font.pixelSize: 16
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.row ? root.row.subtitle : ""
                visible: text !== ""
                color: Colors.text
                opacity: 0.6
                font.pixelSize: 14
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Switch {
        //     id: toggle
        //     checked: root.row ? root.row.checked : false
        //     focusPolicy: Qt.NoFocus
        // }
        Text {
            text: root.row && root.row.checked ? "toggle_on" : "toggle_off"
            visible: text !== ""
            color: Colors.text
            font.family: "Material Symbols Rounded"
            font.pixelSize: 32
            font.variableAxes: {
                "FILL": 0,
                "wght": 600,
                "GRAD": 0,
                "opsz": 32
            }
            Layout.preferredWidth: 32
            // horizontalAlignment: Text.AlignHCenter
            Layout.rightMargin: 8
        }
    }
}
