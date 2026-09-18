import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

import "../bar/components"
import "../services"
import "../Colors.js" as Colors

pragma ComponentBehavior: Bound

// Shared GUI for every package panel (install / update / uninstall).
// All differences live in the properties below, the manager is expected to
// expose: entries, selectedCount, toggle(name), selectAll(), commitSelected(),
// isSelected(name), refresh(), active, busy, needsPassword, status,
// statusLabel, currentPackage, progress, log, error, lockedDb, cancel(),
// clearLock(), submitPassword(value) and dismiss().
Container {
  id: root

  property var manager: null

  property string title: ""
  property string shortcutName: ""

  property string filterPlaceholder: "Filter..."
  property string hint: ""
  property string commitVerb: "install"

  property bool checkable: true
  property bool clientFilter: true
  property bool refreshOnOpen: true
  property bool showMeta: false

  property var chips: []
  property string activeChip: ""
  property string statusText: ""

  property string linkTo: ""
  property string linkIcon: ""

  property bool show: false
  property string query: ""

  signal chipTapped(string key)

  focus: true

  boxHeight: show ? 256 * 2 : 0
  boxWidth: show ? 640 : 0

  readonly property bool logVisible: root.manager && root.manager.active && !root.manager.needsPassword

  readonly property bool windowActive: Window.active
  property bool dismissalArmed: false

  readonly property var visibleEntries: root.clientFilter
    ? filtered.values
    : (root.manager ? root.manager.entries : [])

  function currentEntry() {
    const values = root.visibleEntries

    if (list.currentIndex >= 0 && list.currentIndex < values.length)
      return values[list.currentIndex]

    return null
  }

  function toggleCurrent() {
    const entry = root.currentEntry()

    if (!entry || !root.manager)
      return

    root.manager.toggle(entry.name)
  }

  function commitSelected() {
    if (root.manager)
      root.manager.commitSelected()
  }

  function submitPassword() {
    if (passwordField.text === "" || !root.manager)
      return

    root.manager.submitPassword(passwordField.text)
    passwordField.text = ""
  }

  function open() {
    root.show = true
  }

  GlobalShortcut {
    appid: "n4shell"
    name: root.shortcutName
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
      if (root.refreshOnOpen && root.manager)
        root.manager.refresh()

      Qt.callLater(() => input.forceActiveFocus())
      CenterMenu.hideOthers(root)
    } else {
      passwordField.text = ""

      if (root.clientFilter)
        input.text = ""

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

  ScriptModel {
    id: filtered

    values: {
      const entries = root.manager ? root.manager.entries : []
      const q = root.query.trim().toLowerCase()

      if (q === "")
        return entries

      return entries.filter(entry => entry.name.toLowerCase().includes(q))
    }
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
        text: root.title
        color: Colors.text
        font.bold: true
        font.pixelSize: 16
      }

      Text {
        text: root.statusText
        color: Colors.text
        opacity: 0.5
        font.pixelSize: 13
      }

      Item {
        Layout.fillWidth: true
      }

      Text {
        visible: root.linkTo !== ""
        text: root.linkIcon
        color: Colors.text
        opacity: 0.7
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
        font.variableAxes: {
          "FILL": 0,
          "wght": 600,
          "GRAD": 0,
          "opsz": 18
        }

        TapHandler {
          onTapped: {
            root.show = false
            CenterMenu.openMenu(root.linkTo, root.exclusiveMonitor)
          }
        }
      }

      RowLayout {
        spacing: 6

        Repeater {
          model: root.chips

          delegate: Text {
            id: chip

            required property var modelData

            text: chip.modelData.label
            color: Colors.text
            opacity: root.activeChip === chip.modelData.key ? 1 : 0.4
            font.pixelSize: 13
            font.bold: root.activeChip === chip.modelData.key

            TapHandler {
              onTapped: root.chipTapped(chip.modelData.key)
            }
          }
        }
      }

      Text {
        visible: root.refreshOnOpen
        text: "refresh"
        color: Colors.text
        opacity: root.manager && root.manager.refreshing ? 0.3 : 0.7
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
        font.variableAxes: {
          "FILL": 0,
          "wght": 600,
          "GRAD": 0,
          "opsz": 18
        }

        TapHandler {
          onTapped: root.manager.refresh()
        }
      }
    }

    TextField {
      id: input
      Layout.fillWidth: true
      placeholderText: root.filterPlaceholder
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
        root.query = text

        if (!root.clientFilter && root.manager)
          root.manager.query = text

        list.currentIndex = root.visibleEntries.length > 0 ? 0 : -1
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
        } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key) && !ctrl) {
          event.accepted = true;
          root.toggleCurrent();
        } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key) && ctrl) {
          event.accepted = true;
          root.commitSelected();
        } else if (event.key === Qt.Key_Space) {
          event.accepted = true;
          root.toggleCurrent();
        } else if (event.key === Qt.Key_Q && ctrl) {
          event.accepted = true;
          root.show = false
        } else if (event.key === Qt.Key_A && ctrl) {
          if (root.checkable && root.manager)
            root.manager.selectAll()
        }
      }
    }

    ListView {
      id: list
      Layout.fillWidth: true
      Layout.fillHeight: true

      clip: true
      spacing: 4

      model: root.visibleEntries
      currentIndex: root.visibleEntries.length > 0 ? 0 : -1
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
        checked: root.checkable && root.manager ? root.manager.isSelected(modelData.name) : false
        checkable: root.checkable
        showMeta: root.showMeta

        onPicked: list.currentIndex = index
        onToggled: root.manager.toggle(modelData.name)
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 8
      visible: root.manager && !root.manager.active

      Text {
        text: !root.manager || root.manager.selectedCount === 0
          ? "nothing selected"
          : root.commitVerb + " " + root.manager.selectedCount + " package" + (root.manager.selectedCount === 1 ? "" : "s")
        color: Colors.text
        font.pixelSize: 14
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        text: "arrow_forward"
        color: Colors.text
        opacity: root.manager && root.manager.selectedCount === 0 ? 0.3 : 1
        font.family: "Material Symbols Rounded"
        font.pixelSize: 20
        font.variableAxes: {
          "FILL": 0,
          "wght": 600,
          "GRAD": 0,
          "opsz": 20
        }

        TapHandler {
          onTapped: root.commitSelected()
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6
      visible: root.manager && root.manager.needsPassword

      onVisibleChanged: {
        if (visible)
          Qt.callLater(() => passwordField.forceActiveFocus())
      }

      Text {
        text: "sudo password for " + root.manager.currentPackage
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
        text: root.manager.error
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
          text: root.manager.statusLabel
          color: Colors.text
          font.bold: true
          font.pixelSize: 14
        }

        Text {
          text: root.manager.currentPackage
          color: Colors.text
          font.pixelSize: 14
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          text: "close"
          visible: root.manager.busy
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
            onTapped: root.manager.cancel()
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
          width: root.manager.progress >= 0 ? parent.width * root.manager.progress : parent.width
          radius: 2
          color: root.manager.status === "done" ? Colors.green : Colors.highlight

          NumberAnimation on opacity {
            running: root.manager.progress < 0 && root.manager.busy
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
          text: root.manager.log.slice(-120).join("\n")
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
        visible: root.manager.lockedDb

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
            onTapped: root.manager.clearLock()
          }
        }
      }
    }

    Text {
      Layout.fillWidth: true
      visible: root.manager && !root.manager.active
      text: root.hint
      color: Colors.text
      opacity: 0.4
      font.pixelSize: 12
    }
  }
}
