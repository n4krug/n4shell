import QtQuick
import QtQuick.Layouts

import "../bar/components"
import "../services"
import "../Colors.js" as Colors

Container {
  id: root

  property var installer: null
  property var updater: null

  readonly property var target: UpdateManager.active ? UpdateManager : PackageManager
  readonly property bool updating: root.target === UpdateManager
  readonly property bool shown: (PackageManager.active || UpdateManager.active)
    && !(root.installer && root.installer.show)
    && !(root.updater && root.updater.show)

  readonly property color accent: {
    switch (root.target.status) {
      case "done": return Colors.green
      case "failed": return Colors.negative
      case "cancelled": return Colors.negative
      default: return Colors.text
    }
  }
  readonly property string icon: {
    switch (root.target.status) {
      case "checking": return "hourglass_empty"
      case "auth": return "lock"
      case "installing": return "download"
      case "updating": return "upgrade"
      case "done": return "check"
      case "failed": return "error"
      case "cancelled": return "block"
      default: return root.updating ? "upgrade" : "download"
    }
  }
  readonly property string detail: root.target.busy ? root.target.lastLogLine : root.target.currentPackage
  readonly property string percent: root.target.busy && root.target.progress >= 0
    ? Math.round(root.target.progress * 100) + "%"
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

  function openTarget() {
    if (root.updating) {
      if (root.updater)
        root.updater.show = true
    } else if (root.installer) {
      root.installer.show = true
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: root.shown
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true

    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) {
        if (root.target.busy)
          root.target.cancel()
        else
          root.target.dismiss()
        return
      }

      root.openTarget()
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
        text: root.target.statusLabel + " " + root.target.currentPackage + (root.percent !== "" ? "  " + root.percent : "")
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
          if (root.target.busy)
            root.target.cancel()
          else
            root.target.dismiss()
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
    visible: root.target.busy

    Rectangle {
      anchors {
        left: parent.left
        top: parent.top
        bottom: parent.bottom
      }
      width: root.target.progress >= 0 ? parent.width * root.target.progress : parent.width
      radius: 2
      color: root.accent

      NumberAnimation on opacity {
        running: root.target.progress < 0
        from: 0.3
        to: 1
        duration: 700
        loops: Animation.Infinite
      }
    }
  }
}
