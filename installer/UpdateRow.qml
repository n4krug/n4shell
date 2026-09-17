import QtQuick
import QtQuick.Layouts

import "../Colors.js" as Colors

Item {
  id: root

  required property var modelData
  required property int index

  property bool selected: false
  property bool checked: false

  signal picked()
  signal toggled()

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

    Text {
      text: root.checked ? "check_box" : "check_box_outline_blank"
      color: root.checked ? Colors.text : Colors.text
      opacity: root.checked ? 1 : 0.5
      font.family: "Material Symbols Rounded"
      font.pixelSize: 22
      font.variableAxes: {
        "FILL": root.checked ? 1 : 0,
        "wght": 400,
        "GRAD": 0,
        "opsz": 22
      }
      Layout.alignment: Qt.AlignVCenter

      TapHandler {
        onTapped: root.toggled()
      }
    }

    Rectangle {
      Layout.preferredWidth: 56
      Layout.fillHeight: true
      radius: 6
      color: Colors.highlight
      opacity: 0.12

      Text {
        anchors.centerIn: parent
        text: root.modelData.source === "aur" ? "AUR" : "Repo"
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
        text: root.modelData.from + " → " + root.modelData.to
        color: Colors.text
        opacity: 0.6
        font.pixelSize: 12
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.picked()
    onDoubleClicked: root.toggled()
  }
}
