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

    // ssids we tried to connect to and failed, kept here because rows are
    // recreated on every scan.
    property var failed: []

    // network the password step is being shown for.
    property var pendingNetwork: null

    signal pageRequested(var component)

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

    // enterprise networks need more than a psk, so they keep the old behavior.
    readonly property var pskSecurityTypes: [
        WifiSecurityType.Wpa3SuiteB192,
        WifiSecurityType.Sae,
        WifiSecurityType.Wpa2Psk,
        WifiSecurityType.WpaPsk,
        WifiSecurityType.StaticWep,
        WifiSecurityType.DynamicWep,
        WifiSecurityType.Leap,
    ]

    function needsPassword(network) {
        if (!network || network.known)
            return false

        return root.pskSecurityTypes.includes(network.security)
    }

    function openPasswordPrompt(network) {
        root.pendingNetwork = network
        root.pageRequested(passwordPage)
    }

    function markFailed(network) {
        if (!network || network.connected)
            return

        const name = network.name || ""

        if (name !== "" && root.failed.indexOf(name) === -1)
            root.failed = root.failed.concat(name)
    }

    function clearFailed(network) {
        if (!network)
            return

        const name = network.name || ""

        if (root.failed.indexOf(name) !== -1)
            root.failed = root.failed.filter(candidate => candidate !== name)
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
        id: passwordPage

        WifiPasswordPage {
            network: root.pendingNetwork
        }
    }

    Component {
        id: networkRow

        MenuRow {
            id: row

            kind: "action"

            property var network: null

            title: network ? (network.name || "Hidden network") : ""
            subtitle: {
                if (!network)
                    return ""

                if (root.failed.includes(network.name || ""))
                    return "couldn't connect · tap to retry"

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
                if (!network)
                    return

                if (root.needsPassword(network)) {
                    root.openPasswordPrompt(network)
                } else {
                    network.connect()
                }
            }

            Connections {
                target: row.network
                ignoreUnknownSignals: true

                function onConnectionFailed(reason) {
                    root.markFailed(row.network)
                }

                function onConnectedChanged() {
                    if (row.network && row.network.connected)
                        root.clearFailed(row.network)
                }
            }
        }
    }
}
