import QtQuick
import Quickshell
import Quickshell.Bluetooth

import ".."

Item {
    id: root

    property string title: "Connect to Bluetooth"
    property var rows: []

    property var entries: []

    property bool preview: false
    property var adapter: null

    readonly property var devices: {
        if (!root.adapter)
            return []

        return [...root.adapter.devices.values].sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1

            return root.nameOf(a).localeCompare(root.nameOf(b))
        })
    }

    onDevicesChanged: root.rebuild()

    Component.onCompleted: {
        if (root.adapter && !root.preview)
            root.adapter.discovering = true

        root.rebuild()
    }

    Component.onDestruction: {
        if (root.adapter && !root.preview)
            root.adapter.discovering = false
    }

    function nameOf(device) {
        return device.name || device.deviceName || device.address || "Unknown device"
    }

    // rows are kept per device instead of recreated on every device change,
    // otherwise in flight connections lose their pending/watchdog state.
    function rebuild() {
        const entries = []
        const next = []

        root.devices.forEach(device => {
            let entry = root.entries.find(candidate => candidate.device === device)

            if (!entry)
                entry = ({ device: device, row: deviceRow.createObject(root, { device: device }) })

            entries.push(entry)
            next.push(entry.row)
        })

        root.entries.filter(entry => !entries.includes(entry)).forEach(entry => entry.row.destroy())

        root.entries = entries
        root.rows = next
    }

    Component {
        id: deviceRow

        MenuRow {
            id: row

            kind: "action"

            property var device: null
            property bool pendingConnect: false
            property bool needsRepair: false

            title: device ? root.nameOf(device) : ""
            subtitle: {
                if (!device)
                    return ""

                if (row.needsRepair)
                    return "couldn't connect · tap to re-pair"

                const parts = []

                if (device.batteryAvailable)
                    parts.push(Math.round(device.battery * 100) + "%")

                if (device.connected)
                    parts.push("connected")
                else if (device.pairing)
                    parts.push("pairing")
                else if (device.state === BluetoothDeviceState.Connecting)
                    parts.push("connecting")
                else if (device.paired || device.bonded)
                    parts.push("paired")
                else
                    parts.push("not paired")

                return parts.join(" · ")
            }
            icon: device && device.connected ? "bluetooth_connected" : "bluetooth"

            onTriggered: {
                if (!device)
                    return

                if (row.needsRepair) {
                    row.needsRepair = false
                    device.forget()

                    if (root.adapter)
                        root.adapter.discovering = true
                } else if (device.connected) {
                    device.disconnect()
                } else if (device.pairing) {
                    device.cancelPair()
                } else if (device.paired || device.bonded) {
                    device.connect()
                    watchdog.restart()
                } else {
                    row.pendingConnect = true
                    device.trusted = true
                    device.pair()
                }
            }

            onDeviceChanged: {
                row.pendingConnect = false
                row.needsRepair = false
                watchdog.stop()
            }

            Connections {
                target: row.device

                function onConnectedChanged() {
                    if (!row.device || !row.device.connected)
                        return

                    row.pendingConnect = false
                    row.needsRepair = false
                }

                function onPairedChanged() {
                    if (!row.pendingConnect || !row.device || !row.device.paired)
                        return

                    row.pendingConnect = false
                    row.device.connect()
                    watchdog.restart()
                }

                function onPairingChanged() {
                    if (!row.device || row.device.pairing || row.device.paired)
                        return

                    row.pendingConnect = false
                }
            }

            Timer {
                id: watchdog

                interval: 8000
                repeat: false

                onTriggered: {
                    if (row.device && !row.device.connected)
                        row.needsRepair = true
                }
            }
        }
    }
}
