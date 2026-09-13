import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland

import "../bar/components"
import "../services"

pragma ComponentBehavior: Bound

Container {
    id: root

    property bool show: false
    boxHeight: show ? 384 : 0
    boxWidth: show ? 512 : 0

    readonly property bool windowActive: Window.active
    property bool dismissalArmed: false

    GlobalShortcut {
        appid: "n4shell"
        name: "settings"
        onPressed: {
            if (Hyprland.focusedMonitor !== root.exclusiveMonitor) return
            root.show = !root.show
        }
    }

    Component.onCompleted: {
        CenterMenu.addMenu(this)
    }

    Component.onDestruction: {
        CenterMenu.removeMenu(this)
    }

    onShowChanged: {
        if (show) {
            stack.clear(StackView.Immediate)
            stack.push(pagePane, { rows: Pages.rows, title: Pages.title }, StackView.Immediate)
            Qt.callLater(() => root.focusCurrent())
            CenterMenu.hideOthers(root)
        } else {
            stack.clear(StackView.Immediate)
        }

        root.dismissalArmed = false
        armTimer.running = show
        CenterMenu.refresh()
    }

    onWindowActiveChanged: {
        if (root.show && root.dismissalArmed && !root.windowActive)
            root.show = false
    }

    Timer {
        id: armTimer
        interval: 400
        repeat: false
        onTriggered: root.dismissalArmed = root.windowActive
    }

    function focusCurrent() {
        if (stack.currentItem)
            stack.currentItem.requestFocus()
    }

    function goBack() {
        if (stack.depth > 1) {
            stack.pop()
            Qt.callLater(() => root.focusCurrent())
        } else {
            root.show = false
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 16
        visible: root.show

        StackView {
            id: stack
            anchors.fill: parent
            clip: true
        }
    }

    Component {
        id: pagePane

        MenuPane {
            canGoBack: stack.depth > 1

            onBackRequested: root.goBack()

            onSubmenuRequested: page => {
                stack.push(pagePane, { pageComponent: page })
                Qt.callLater(() => root.focusCurrent())
            }

            onCloseRequested: root.show = false
        }
    }
}
