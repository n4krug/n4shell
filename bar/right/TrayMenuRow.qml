import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../Colors.js" as Colors
pragma ComponentBehavior: Bound

// A single row of a TrayMenu. Also owns the flyout submenu for entries that
// have children.
Item {
    id: root

    // Supplied by the Repeater in TrayMenu. It has to be a required property:
    // a plain binding on the delegate would be resolved in the enclosing
    // component's scope instead of the delegate's model context.
    required property var modelData

    property var entry: modelData
    property var menu: null
    property Component submenuComponent: null

    readonly property bool isSeparator: root.entry ? root.entry.isSeparator === true : false
    readonly property bool hasChildren: root.entry ? root.entry.hasChildren === true : false
    readonly property bool entryEnabled: root.entry ? root.entry.enabled !== false : true
    readonly property bool checked: root.entry ? root.entry.checkState === Qt.Checked : false

    property bool hovered: false

    implicitWidth: layout.implicitWidth + 24
    height: root.isSeparator ? 9 : 32
    width: parent ? parent.width : implicitWidth

    // dbusmenu labels mark their mnemonic with a leading underscore ("_Quit").

    function label() {
        const raw = root.entry ? root.entry.text : ""
        return raw.replace(/_([^_])/g, "$1")
    }

    function activate() {
        if (!root.entry || !root.entryEnabled)
            return

        root.entry.triggered()

        const owner = root.menu
        if (owner)
            Qt.callLater(() => owner.closeChain())
    }

    Rectangle {
        id: highlight

        anchors.fill: parent
        radius: Colors.radius
        color: Colors.highlight
        opacity: root.hovered && !root.isSeparator ? 0.15 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    Rectangle {
        visible: root.isSeparator

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 10
            rightMargin: 10
        }

        height: 1
        color: Colors.text
        opacity: 0.25
    }

    RowLayout {
        id: layout

        visible: !root.isSeparator

        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }

        spacing: 8

        Image {
            visible: root.entry && root.entry.icon !== ""
            source: root.entry ? root.entry.icon : ""
            fillMode: Image.PreserveAspectFit

            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            sourceSize.width: 16
            sourceSize.height: 16
        }

        Text {
            text: root.label()
            color: Colors.text
            opacity: root.entryEnabled ? 1 : 0.4
            font.pixelSize: 14
            elide: Text.ElideRight

            Layout.fillWidth: true
        }

        Text {
            visible: root.entry && root.entry.buttonType !== QsMenuButtonType.None

            text: {
                if (!root.entry)
                    return ""
                if (root.entry.buttonType === QsMenuButtonType.RadioButton)
                    return root.checked ? "radio_button_checked" : "radio_button_unchecked"
                return root.checked ? "check_box" : "check_box_outline_blank"
            }

            color: Colors.text
            opacity: root.entryEnabled ? 1 : 0.4
            font.pixelSize: 16
            font.family: "Material Symbols Rounded"
            font.variableAxes: {
                "FILL": 1,
                "wght": 400,
                "GRAD": 0,
                "opsz": 16
            }
        }

        Text {
            visible: root.hasChildren

            text: "chevron_right"
            color: Colors.text
            font.pixelSize: 16
            font.family: "Material Symbols Rounded"
            font.variableAxes: {
                "FILL": 0,
                "wght": 600,
                "GRAD": 0,
                "opsz": 16
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.isSeparator
        acceptedButtons: Qt.LeftButton

        onContainsMouseChanged: {
            root.hovered = area.containsMouse

            if (area.containsMouse && root.hasChildren)
                openTimer.restart()
            else
                openTimer.stop()
        }

        onClicked: root.activate()
    }

    // Hovering a row with children asks the owning menu for a flyout. The menu
    // owns it (rather than this row) so it isn't clipped by the menu's Flickable.
    Timer {
        id: openTimer

        interval: 250
        repeat: false
        onTriggered: {
            if (area.containsMouse && root.menu)
                root.menu.requestSubmenu(root)
        }
    }
}
