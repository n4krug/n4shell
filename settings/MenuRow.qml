import QtQuick
import Quickshell.Io

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property string kind: "action"
    property bool enabled: true

    property Component page: null

    property var command: []

    property bool checked: false

    property real value: 0
    property real from: 0
    property real to: 1
    property real step: 0.01

    signal triggered()
    signal toggled(bool newValue)
    signal moved(real newValue)

    function run(extra) {
        if (!root.command || root.command.length === 0)
            return

        process.command = root.command.concat(extra === undefined ? [] : extra)
        process.running = true
    }

    function activate() {
        if (!root.enabled)
            return

        if (root.kind === "toggle") {
            root.toggled(!root.checked)
            root.run([!root.checked ? "on" : "off"])
        } else if (root.kind === "action") {
            root.triggered()
            root.run([])
        }
    }

    Process {
        id: process
        running: false
    }
}
