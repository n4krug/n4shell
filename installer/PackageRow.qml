import QtQuick
import QtQuick.Layouts

import "../Colors.js" as Colors

Item {
  id: root

  required property var modelData
  required property int index

  property bool selected: false
  property bool checked: false
  property bool checkable: false
  property bool showMeta: false

  readonly property string badgeText: {
    if (root.modelData.source === "aur")
      return "AUR"

    return root.modelData.repo || "Repo"
  }

  readonly property string subtitleText: {
    if (root.modelData.from !== undefined)
      return root.modelData.from + " → " + root.modelData.to

    return root.modelData.description || ""
  }

  readonly property string metaNote: {
    if (root.modelData.votes !== undefined && root.modelData.votes > 0)
      return root.modelData.votes + "★"

    if (root.modelData.size !== undefined)
      return root.modelData.size

    return ""
  }

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
      visible: root.checkable
      text: root.checked ? "check_box" : "check_box_outline_blank"
      color: Colors.text
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
        text: root.badgeText
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
        text: root.subtitleText
        color: Colors.text
        opacity: 0.6
        font.pixelSize: 12
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }
    }

    RowLayout {
      visible: root.showMeta
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
          text: root.modelData.version || ""
          color: Colors.text
          opacity: 0.6
          font.pixelSize: 11
          horizontalAlignment: Text.AlignRight
          Layout.preferredWidth: 96
          elide: Text.ElideRight
        }

        Text {
          text: root.metaNote
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
    onDoubleClicked: root.toggled()
  }
}
