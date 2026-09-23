import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Hyprland

import "../components"
import "../../services"
import "../../Colors.js" as Colors
pragma ComponentBehavior: Bound

// Context menu for a SystemTray item.
//
// The chrome comes from Container (DrawRegistry -> DrawCanvas), the entries
// come from the item's dbusmenu via QsMenuOpener. The same component is used
// for the root menu and for submenu flyouts, which it creates lazily from
// root.submenuComponent.
Container {
    id: root

    property var menuSource: null
    property Item anchorItem: null
    property var parentMenu: null
    property Component submenuComponent: null

    property bool show: false
    property bool anchorHovered: false

    // Row whose flyout is currently open, if any.
    property var submenuRow: null
    property bool submenuOpen: false

    readonly property bool isSubmenu: root.parentMenu != null

    property real maxMenuWidth: 320
    property real minMenuWidth: 140

    property real animatedOpacity: 0
    property bool dismissalArmed: false
    property bool registered: false

    readonly property bool windowActive: Window.active

    // Container anchors itself to the top of its parent for the bar; this menu
    // is placed explicitly instead.
    anchors.top: undefined

    z: root.isSubmenu ? 200 : 100

    visible: false
    opacity: root.animatedOpacity

    Behavior on animatedOpacity {
        NumberAnimation {
            duration: 150
        }
    }

    boxWidth: Math.min(root.maxMenuWidth, Math.max(root.minMenuWidth, root.contentWidth + 12))
    boxHeight: Math.min(column.implicitHeight + 12, Math.max(120, Window.height - 24))

    readonly property real contentWidth: {
        let w = 0

        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i)
            if (item && item.implicitWidth > w)
                w = item.implicitWidth
        }

        return w
    }

    readonly property bool submenuActive: root.firstOpenSubmenu() != null

    QsMenuOpener {
        id: opener

        // Only holds a reference (and loads the menu) while the menu is open.
        menu: root.show ? root.menuSource : null
    }

    Flickable {
        id: flick

        x: 6
        y: 6
        width: root.boxWidth - 12
        height: root.boxHeight - 12
        contentWidth: column.width
        contentHeight: column.implicitHeight

        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column

            width: flick.width
            height: implicitHeight
            spacing: 2

            Repeater {
                id: repeater

                model: opener.children

                delegate: TrayMenuRow {
                    menu: root
                    submenuComponent: root.submenuComponent
                }
            }
        }
    }

    // Flyouts live here rather than in the row so they aren't clipped by the
    // Flickable above.
    Loader {
        id: submenuLoader

        active: root.submenuOpen && root.submenuRow != null
        sourceComponent: root.submenuComponent
        z: 10

        onLoaded: {
            item.menuSource = root.submenuRow.entry
            item.anchorItem = root.submenuRow
            item.parentMenu = root
            item.anchorHovered = Qt.binding(() => root.submenuRow ? root.submenuRow.hovered : false)
            item.show = true
        }
    }

    Connections {
        target: submenuLoader.item
        ignoreUnknownSignals: true

        function onShowChanged() {
            if (submenuLoader.item && !submenuLoader.item.show)
                root.closeSubmenu()
        }
    }

    HoverHandler {
        id: menuHover

        onHoveredChanged: root.updateDismissTimer()
    }

    // Submenus are placed relative to their parent menu and row, so they have
    // to follow both while either is still settling.
    Connections {
        target: root.parentMenu
        ignoreUnknownSignals: true
        enabled: root.show && root.parentMenu != null

        function onXChanged() { root.position() }
        function onYChanged() { root.position() }
        function onWidthChanged() { root.position() }
        function onHeightChanged() { root.position() }
    }

    Connections {
        target: root.anchorItem
        ignoreUnknownSignals: true
        enabled: root.show && root.parentMenu != null

        function onXChanged() { root.position() }
        function onYChanged() { root.position() }
    }

    Item {
        id: focusScope

        anchors.fill: parent
        focus: root.show && !root.isSubmenu

        Keys.onEscapePressed: event => {
            event.accepted = true
            root.handleEscape()
        }
    }

    function openFor(source, anchor) {
        root.menuSource = source
        root.anchorItem = anchor
        hideTimer.stop()
        root.visible = true
        root.animatedOpacity = 1
        root.show = true
        root.position()
        root.armDismissal()
        if (!root.isSubmenu)
            Qt.callLater(() => focusScope.forceActiveFocus())
    }

    function close() {
        root.show = false
    }

    function closeChain() {
        if (root.parentMenu)
            root.parentMenu.closeChain()
        else
            root.close()
    }

    function handleEscape() {
        const sub = root.firstOpenSubmenu()
        if (sub)
            sub.handleEscape()
        else
            root.close()
    }

    function requestSubmenu(row) {
        if (root.submenuOpen && root.submenuRow === row)
            return

        root.submenuRow = row
        root.submenuOpen = true
    }

    function closeSubmenu() {
        root.submenuOpen = false
        root.submenuRow = null
        root.updateDismissTimer()
    }

    function firstOpenSubmenu() {
        if (root.submenuOpen && submenuLoader.item)
            return submenuLoader.item

        return null
    }

    function armDismissal() {
        root.dismissalArmed = false
        armTimer.restart()
    }

    function position() {
        if (!root.anchorItem || !root.parent)
            return

        const w = root.boxWidth
        const h = root.boxHeight
        const p = root.anchorItem.mapToItem(null, 0, 0)
        const margin = 8
        const winW = Window.width
        const winH = Window.height

        let x
        let y

        if (root.parentMenu) {
            // Fly out beside the parent menu, aligned with the row it belongs
            // to. The gap keeps DrawCanvas from merging the two boxes into one
            // shape.
            const pm = root.parentMenu
            const pmp = pm.mapToItem(null, 0, 0)

            x = pmp.x + pm.width + 6
            if (x + w > winW - margin)
                x = pmp.x - w - 6
            y = p.y - 6
        } else {
            x = p.x + root.anchorItem.width / 2 - w / 2
            y = p.y + root.anchorItem.height + margin
            if (y + h > winH - margin)
                y = p.y - h - margin
        }

        const local = root.parent.mapFromItem(null, Math.max(margin, Math.min(x, winW - w - margin)), Math.max(margin, Math.min(y, winH - h - margin)))
        root.x = local.x
        root.y = local.y
    }

    function updateDismissTimer() {
        if (!root.show)
            return

        if (menuHover.hovered || root.anchorHovered || root.submenuActive)
            dismissTimer.stop()
        else
            dismissTimer.restart()
    }

    onShowChanged: {
        if (root.show) {
            hideTimer.stop()
            root.visible = true
            root.animatedOpacity = 1
            root.position()
            root.armDismissal()

            if (!root.isSubmenu) {
                if (!root.registered) {
                    CenterMenu.addMenu(root)
                    root.registered = true
                }

                CenterMenu.hideOthers(root)
                CenterMenu.refresh()
                Qt.callLater(() => focusScope.forceActiveFocus())
            }
        } else {
            root.animatedOpacity = 0
            root.closeSubmenu()
            armTimer.stop()
            dismissTimer.stop()
            hideTimer.restart()
            if (root.registered)
                CenterMenu.refresh()
        }

        root.updateDismissTimer()
    }

    onBoxWidthChanged: {
        if (root.show)
            root.position()
    }

    onBoxHeightChanged: {
        if (root.show)
            root.position()
    }

    onAnchorHoveredChanged: root.updateDismissTimer()

    onWindowActiveChanged: {
        if (root.show && root.dismissalArmed && !root.windowActive)
            root.close()
    }

    Component.onDestruction: {
        if (root.registered)
            CenterMenu.removeMenu(root)
    }

    Timer {
        id: hideTimer

        interval: 170
        repeat: false
        onTriggered: root.visible = false
    }

    Timer {
        id: dismissTimer

        // Submenus get a longer grace so crossing the gap between the row and
        // the flyout doesn't close it under the pointer.
        interval: root.parentMenu ? 700 : 400
        repeat: false
        onTriggered: root.close()
    }

    Timer {
        id: armTimer

        interval: 400
        repeat: false
        onTriggered: root.dismissalArmed = root.windowActive
    }
}
