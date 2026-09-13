import QtQuick
import QtQuick.Layouts

import "../../Colors.js" as Colors

Item {
    id: root

    property var row: null
    property var select: null
    property var openRequested: null

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
            font.pixelSize: 20
            font.variableAxes: {
                "FILL": 0,
                "wght": 600,
                "GRAD": 0,
                "opsz": 20
            }
            Layout.preferredWidth: 24
            horizontalAlignment: Text.AlignHCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.row ? root.row.title : ""
                color: Colors.text
                font.pixelSize: 14
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.row ? root.row.subtitle : ""
                visible: text !== ""
                color: Colors.text
                opacity: 0.6
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    opacity: root.row && root.row.enabled ? 1 : 0.4

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.select)
                root.select()
        }
        onDoubleClicked: {
            if (root.openRequested)
                root.openRequested()
        }
    }
}
