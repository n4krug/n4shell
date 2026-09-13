import QtQuick
import Quickshell
import Quickshell.Networking

import ".."

Item {
    id: root

    property string title: "Connect to Wi-Fi"
    property var rows: []

    property var device: null

    readonly property var networks: {
        if (!root.device)
            return []

        return [...root.device.networks.values].sort((a, b) => b.signalStrength - a.signalStrength)
    }

    onNetworksChanged: root.rebuild()

    Component.onCompleted: {
        if (root.device)
            root.device.scannerEnabled = true

        root.rebuild()
    }

    Component.onDestruction: {
        if (root.device)
            root.device.scannerEnabled = false
    }

    function setRows(next) {
        root.rows.forEach(row => row.destroy())
        root.rows = next
    }

    function rebuild() {
        root.setRows(root.networks.map(network => networkRow.createObject(root, {
            network: network,
        })))
    }

    Component {
        id: networkRow

        MenuRow {
            kind: "action"

            property var network: null

            title: network ? (network.name || "Hidden network") : ""
            subtitle: {
                if (!network)
                    return ""

                const parts = [Math.round(network.signalStrength * 100) + "%"]

                if (network.security !== WifiSecurityType.Open)
                    parts.push("secured")

                if (network.connected)
                    parts.push("connected")

                return parts.join(" · ")
            }
            icon: "wifi"

            onTriggered: {
                if (network)
                    network.connect()
            }
        }
    }
}
