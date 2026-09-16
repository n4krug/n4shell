import QtQuick
import Quickshell
import Quickshell.Networking

import ".."

Item {
    id: root

    property string title: "Connect to Wi-Fi"
    property var rows: []

    property bool preview: false
    property var device: null

    readonly property var networks: {
        if (!root.device)
            return []

        return [...root.device.networks.values].sort((a, b) => b.signalStrength - a.signalStrength)
    }

    onNetworksChanged: root.rebuild()

    Component.onCompleted: {
        if (root.device && !root.preview)
            root.device.scannerEnabled = true

        root.rebuild()
    }

    Component.onDestruction: {
        if (root.device && !root.preview)
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
            icon: {
                const wifiLevels = [
                          "signal_wifi_0_bar",
                          "network_wifi_1_bar",
                          "network_wifi_2_bar",
                          "network_wifi_3_bar",
                          "signal_wifi_4_bar",
                      ]
                const lockedLevels = [
                    "wifi_lock",
                    "network_wifi_1_bar_locked",
                    "network_wifi_2_bar_locked",
                    "network_wifi_3_bar_locked",
                    "network_wifi_locked"
                ]

                let iconId = (Math.floor(network.signalStrength*wifiLevels.length))
                if (iconId == wifiLevels.length) {
                    iconId--
                }

                if (network.security !== WifiSecurityType.Open)
                    return lockedLevels[iconId]
                return wifiLevels[iconId]

            }


            onTriggered: {
                if (network)
                    network.connect()
            }
        }
    }
}
