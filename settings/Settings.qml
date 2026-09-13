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
    boxHeight: show ? 512 : 0
    boxWidth: show ? 256*1.5 : 0

    readonly property bool windowActive: Window.active
    property bool dismissalArmed: false
    property var pendingPath: []

    GlobalShortcut {
        appid: "n4shell"
        name: "settings"
        onPressed: {
            if (Hyprland.focusedMonitor !== root.exclusiveMonitor) return
            if (root.show)
                root.show = false
            else
                root.openPath([])
        }
    }

    PageShortcuts {
        target: root
    }

    Component.onCompleted: {
        CenterMenu.addMenu(this)
    }

    Component.onDestruction: {
        CenterMenu.removeMenu(this)
    }

    onShowChanged: {
        if (show) {
            root.applyPath(root.pendingPath)
            root.pendingPath = []
            CenterMenu.hideOthers(root)
        } else {
            stack.clear(StackView.Immediate)
            root.pendingPath = []
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

    function openPath(path) {
        if (root.show) {
            root.applyPath(path)
            return
        }

        root.pendingPath = path
        root.show = true
    }

    function applyPath(path) {
        root.pushRoot()

        const steps = path ? path : []

        for (let i = 0; i < steps.length; i++) {
            const pane = stack.currentItem
            const row = pane ? root.findRow(pane.visibleRows, steps[i]) : null

            if (!row || !row.page)
                break

            root.pushPage(row.page)
        }

        Qt.callLater(() => root.focusCurrent())
    }

    function findRow(rows, step) {
        for (let i = 0; i < rows.length; i++) {
            const row = rows[i]

            if (!row)
                continue

            if ((row.rowId && row.rowId === step) || row.title === step)
                return row
        }

        return null
    }

    function pushRoot() {
        stack.clear(StackView.Immediate)
        stack.push(pagePane, { rows: Pages.rows, title: Pages.title }, StackView.Immediate)
    }

    function pushPage(component) {
        stack.push(pagePane, { pageComponent: component }, StackView.Immediate)
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
                root.pushPage(page)
                Qt.callLater(() => root.focusCurrent())
            }

            onCloseRequested: root.show = false
        }
    }
}
