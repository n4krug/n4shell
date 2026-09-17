import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland

import "../bar/components"
import "../services"
import "../Colors.js" as Colors

pragma ComponentBehavior: Bound

Container {
  id: root

  property bool show: false

  focus: true

  boxHeight: show ? 256 * 2 : 0
  boxWidth: show ? 640 : 0

  readonly property bool logVisible: PackageManager.active && !PackageManager.needsPassword

  readonly property bool windowActive: Window.active
  property bool dismissalArmed: false

  function currentEntry() {
    const results = PackageManager.results

    if (list.currentIndex >= 0 && list.currentIndex < results.length)
      return results[list.currentIndex]

    return null
  }

  function installCurrent() {
    const entry = root.currentEntry()

    if (!entry || PackageManager.busy)
      return

    PackageManager.install(entry)
  }

  function chipLabel(value) {
    if (value === "repo")
      return "Repo"
    if (value === "aur")
      return "AUR"

    return "All"
  }

  function submitPassword() {
    if (passwordField.text === "")
      return

    PackageManager.submitPassword(passwordField.text)
    passwordField.text = ""
  }

  GlobalShortcut {
    appid: "n4shell"
    name: "installer"
    onPressed: {
      if (Hyprland.focusedMonitor !== root.exclusiveMonitor) return
      if (root.show)
        root.show = false
      else
        root.open()
    }
  }

  Component.onCompleted: {
    CenterMenu.addMenu(this)
  }

  Component.onDestruction: {
    CenterMenu.removeMenu(this)
  }

  function open() {
    root.show = true
  }

  Keys.onEscapePressed: {
    root.show = false
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Q && event.modifiers & Qt.ControlModifier) {
      event.accepted = true;
      root.show = false
    }
  }

  onWindowActiveChanged: {
    if (root.show && root.dismissalArmed && !root.windowActive)
      root.show = false
  }

  onShowChanged: {
    if (show) {
      Qt.callLater(() => input.forceActiveFocus())
      CenterMenu.hideOthers(root)
    } else {
      passwordField.text = ""
      input.focus = false
    }

    root.dismissalArmed = false
    armTimer.running = show
    CenterMenu.refresh()
  }

  Timer {
    id: armTimer
    interval: 400
    repeat: false
    onTriggered: root.dismissalArmed = root.windowActive
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12
    visible: root.show

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: "Install"
        color: Colors.text
        font.bold: true
        font.pixelSize: 16
      }

      Text {
        text: PackageManager.searching ? "searching..." : PackageManager.results.length + " results"
        color: Colors.text
        opacity: 0.5
        font.pixelSize: 13
      }

      Item {
        Layout.fillWidth: true
      }

      RowLayout {
        spacing: 6

        Repeater {
          model: ["all", "repo", "aur"]

          delegate: Text {
            id: chip

            required property var modelData

            text: root.chipLabel(modelData)
            color: Colors.text
            opacity: PackageManager.source === modelData ? 1 : 0.4
            font.pixelSize: 13
            font.bold: PackageManager.source === modelData

            TapHandler {
              onTapped: PackageManager.source = chip.modelData
            }
          }
        }
      }
    }

    TextField {
      id: input
      Layout.fillWidth: true
      placeholderText: "Search packages..."
      padding: 12
      color: Colors.text
      placeholderTextColor: Colors.text
      font.pixelSize: 16
      background: Rectangle {
        color: Colors.highlight
        border.width: 0
        opacity: 0.15
        radius: Colors.radius
      }

      onTextChanged: {
        PackageManager.query = text
        list.currentIndex = PackageManager.results.length > 0 ? 0 : -1
      }

      Keys.onEscapePressed: {
        root.show = false
      }

      Keys.onPressed: event => {
        const ctrl = event.modifiers & Qt.ControlModifier;

        if (event.key === Qt.Key_Up || event.key === Qt.Key_K && ctrl) {
          event.accepted = true;
          if (list.currentIndex > 0)
            list.currentIndex--;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J && ctrl) {
          event.accepted = true;
          if (list.currentIndex < list.count - 1)
            list.currentIndex++;
        } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
          event.accepted = true;
          root.installCurrent();
        } else if (event.key === Qt.Key_Q && ctrl) {
          event.accepted = true;
          root.show = false
        }
      }
    }

    ListView {
      id: list
      Layout.fillWidth: true
      Layout.fillHeight: true

      clip: true
      spacing: 4

      model: PackageManager.results
      currentIndex: PackageManager.results.length > 0 ? 0 : -1
      keyNavigationWraps: true
      preferredHighlightBegin: 0
      preferredHighlightEnd: height
      highlightRangeMode: ListView.ApplyRange
      highlightMoveDuration: 80
      highlightResizeDuration: 0
      highlight: Rectangle {
        radius: Colors.radius
        opacity: 0.15
        color: Colors.highlight
      }

      delegate: PackageRow {
        selected: ListView.isCurrentItem

        onPicked: list.currentIndex = index
        onInstallRequested: PackageManager.install(modelData)
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6
      visible: PackageManager.needsPassword

      onVisibleChanged: {
        if (visible)
          Qt.callLater(() => passwordField.forceActiveFocus())
      }

      Text {
        text: "sudo password for " + PackageManager.currentPackage
        color: Colors.text
        font.pixelSize: 13
        opacity: 0.7
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        TextField {
          id: passwordField
          Layout.fillWidth: true
          placeholderText: "Password..."
          echoMode: TextInput.Password
          inputMethodHints: Qt.ImhSensitiveData
          padding: 12
          color: Colors.text
          placeholderTextColor: Colors.text
          font.pixelSize: 16
          background: Rectangle {
            color: Colors.highlight
            border.width: 0
            opacity: 0.15
            radius: Colors.radius
          }

          Keys.onReturnPressed: root.submitPassword()
          Keys.onEscapePressed: root.show = false
        }

        Text {
          text: "arrow_forward"
          color: Colors.text
          font.family: "Material Symbols Rounded"
          font.pixelSize: 20
          font.variableAxes: {
            "FILL": 0,
            "wght": 600,
            "GRAD": 0,
            "opsz": 20
          }

          TapHandler {
            onTapped: root.submitPassword()
          }
        }
      }

      Text {
        text: PackageManager.error
        visible: text !== ""
        color: Colors.negative
        font.pixelSize: 13
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 150
      spacing: 6
      visible: root.logVisible

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: PackageManager.statusLabel
          color: Colors.text
          font.bold: true
          font.pixelSize: 14
        }

        Text {
          text: PackageManager.currentPackage
          color: Colors.text
          font.pixelSize: 14
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          text: PackageManager.queuedCount > 1 ? "+" + (PackageManager.queuedCount - 1) + " queued" : ""
          visible: text !== ""
          color: Colors.text
          opacity: 0.5
          font.pixelSize: 12
        }

        Text {
          text: "close"
          visible: PackageManager.busy
          color: Colors.text
          font.family: "Material Symbols Rounded"
          font.pixelSize: 18
          font.variableAxes: {
            "FILL": 0,
            "wght": 600,
            "GRAD": 0,
            "opsz": 18
          }

          TapHandler {
            onTapped: PackageManager.cancel()
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 4
        radius: 2
        color: Colors.highlight
        opacity: 0.15

        Rectangle {
          anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
          }
          width: PackageManager.progress >= 0 ? parent.width * PackageManager.progress : parent.width
          radius: 2
          color: PackageManager.status === "done" ? Colors.green : Colors.highlight

          NumberAnimation on opacity {
            running: PackageManager.progress < 0 && PackageManager.busy
            from: 0.3
            to: 1
            duration: 700
            loops: Animation.Infinite
          }
        }
      }

      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentHeight: logText.height
        contentWidth: width

        onContentHeightChanged: {
          contentY = Math.max(0, contentHeight - height)
        }

        Text {
          id: logText
          width: parent.width
          text: PackageManager.log.slice(-120).join("\n")
          color: Colors.text
          opacity: 0.8
          font.family: "Monospace"
          font.pixelSize: 11
          wrapMode: Text.Wrap
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: PackageManager.lockedDb

        Text {
          text: "pacman is locked, clear /var/lib/pacman/db.lck?"
          color: Colors.text
          font.pixelSize: 12
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          text: "delete"
          color: Colors.negative
          font.family: "Material Symbols Rounded"
          font.pixelSize: 18
          font.variableAxes: {
            "FILL": 0,
            "wght": 600,
            "GRAD": 0,
            "opsz": 18
          }

          TapHandler {
            onTapped: PackageManager.clearLock()
          }
        }
      }
    }

    Text {
      Layout.fillWidth: true
      visible: !PackageManager.active
      text: "enter install · esc hide"
      color: Colors.text
      opacity: 0.4
      font.pixelSize: 12
    }
  }
}
