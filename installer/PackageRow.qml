import QtQuick
import QtQuick.Layouts

import "../Colors.js" as Colors

Item {
  id: root

  required property var modelData
  required property int index

  property bool selected: false

  signal picked()
  signal installRequested()

  width: ListView.view ? ListView.view.width : 0
  height: 56

  Rectangle {
    anchors.fill: parent
    radius: Colors.radius
    color: Colors.highlight
    opacity: root.selected ? 0.15 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: 100
      }
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 12

    Rectangle {
      Layout.preferredWidth: 56
      Layout.fillHeight: true
      radius: 6
      color: Colors.highlight
      opacity: 0.12

      Text {
        anchors.centerIn: parent
        text: root.modelData.source === "aur" ? "AUR" : root.modelData.repo
        color: Colors.text
        font.pixelSize: 11
        font.bold: root.modelData.source === "aur"
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      Text {
        text: root.modelData.name
        color: Colors.text
        font.pixelSize: 15
        font.bold: true
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        text: root.modelData.description
        color: Colors.text
        opacity: 0.6
        font.pixelSize: 12
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }
    }

    RowLayout {
      spacing: 6

      Text {
        text: root.modelData.outOfDate ? "update" : ""
        visible: text !== ""
        color: Colors.negative
        font.family: "Material Symbols Rounded"
        font.pixelSize: 16
        font.variableAxes: {
          "FILL": 0,
          "wght": 600,
          "GRAD": 0,
          "opsz": 16
        }
      }

      Text {
        text: root.modelData.installed ? "check" : ""
        visible: text !== ""
        color: Colors.green
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
        font.variableAxes: {
          "FILL": 0,
          "wght": 600,
          "GRAD": 0,
          "opsz": 18
        }
      }

      ColumnLayout {
        spacing: 0

        Text {
          text: root.modelData.version
          color: Colors.text
          opacity: 0.6
          font.pixelSize: 11
          horizontalAlignment: Text.AlignRight
          Layout.preferredWidth: 96
          elide: Text.ElideRight
        }

        Text {
          text: root.modelData.votes > 0 ? root.modelData.votes + "★" : ""
          visible: text !== ""
          color: Colors.text
          opacity: 0.5
          font.pixelSize: 11
          horizontalAlignment: Text.AlignRight
          Layout.preferredWidth: 96
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.picked()
    onDoubleClicked: root.installRequested()
  }
}
