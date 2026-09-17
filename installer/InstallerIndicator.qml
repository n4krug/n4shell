import QtQuick
import QtQuick.Layouts

import "../bar/components"
import "../services"
import "../Colors.js" as Colors

Container {
  id: root

  property var installer: null

  readonly property bool shown: PackageManager.active && !(root.installer && root.installer.show)
  readonly property color accent: {
    switch (PackageManager.status) {
      case "done": return Colors.green
      case "failed": return Colors.negative
      case "cancelled": return Colors.negative
      default: return Colors.text
    }
  }
  readonly property string icon: {
    switch (PackageManager.status) {
      case "checking": return "hourglass_empty"
      case "auth": return "lock"
      case "installing": return "download"
      case "done": return "check"
      case "failed": return "error"
      case "cancelled": return "block"
      default: return "download"
    }
  }
  readonly property string detail: PackageManager.busy ? PackageManager.lastLogLine : PackageManager.currentPackage
  readonly property string percent: PackageManager.busy && PackageManager.progress >= 0
    ? Math.round(PackageManager.progress * 100) + "%"
    : ""

  boxWidth: root.shown ? 240 : 0
  boxHeight: root.shown ? 52 : 0

  clip: true

  anchors {
    bottom: parent.bottom
    right: parent.right
    top: undefined
    bottomMargin: 8
    rightMargin: 8
  }

  function openInstaller() {
    if (root.installer)
      root.installer.show = true
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: root.shown
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true

    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) {
        if (PackageManager.busy)
          PackageManager.cancel()
        else
          PackageManager.dismiss()
        return
      }

      root.openInstaller()
    }
  }

  RowLayout {
    anchors {
      fill: parent
      margins: 10
      bottomMargin: 14
    }
    spacing: 10
    opacity: root.shown ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: 120
      }
    }

    Text {
      text: root.icon
      color: root.accent
      font.family: "Material Symbols Rounded"
      font.pixelSize: 20
      font.variableAxes: {
        "FILL": 0,
        "wght": 600,
        "GRAD": 0,
        "opsz": 20
      }
      Layout.alignment: Qt.AlignVCenter
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 0

      Text {
        text: PackageManager.statusLabel + " " + PackageManager.currentPackage + (root.percent !== "" ? "  " + root.percent : "")
        color: Colors.text
        font.pixelSize: 13
        font.bold: true
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        text: root.detail
        color: Colors.text
        opacity: 0.6
        font.pixelSize: 11
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }
    }

    Text {
      text: "close"
      color: Colors.text
      opacity: 0.7
      font.family: "Material Symbols Rounded"
      font.pixelSize: 16
      font.variableAxes: {
        "FILL": 0,
        "wght": 600,
        "GRAD": 0,
        "opsz": 16
      }
      Layout.alignment: Qt.AlignVCenter

      TapHandler {
        onTapped: {
          if (PackageManager.busy)
            PackageManager.cancel()
          else
            PackageManager.dismiss()
        }
      }
    }
  }

  Rectangle {
    anchors {
      left: parent.left
      right: parent.right
      bottom: parent.bottom
      bottomMargin: 6
      leftMargin: 10
      rightMargin: 10
    }
    height: 3
    radius: 2
    color: Colors.highlight
    opacity: 0.15
    visible: PackageManager.busy

    Rectangle {
      anchors {
        left: parent.left
        top: parent.top
        bottom: parent.bottom
      }
      width: PackageManager.progress >= 0 ? parent.width * PackageManager.progress : parent.width
      radius: 2
      color: root.accent

      NumberAnimation on opacity {
        running: PackageManager.progress < 0
        from: 0.3
        to: 1
        duration: 700
        loops: Animation.Infinite
      }
    }
  }
}
