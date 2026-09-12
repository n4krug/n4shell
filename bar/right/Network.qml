import QtQuick
import Quickshell
import Quickshell.Networking

import "../components"
import "../../Colors.js" as Colors

Container {
    id: root
    required property real iconSize
    boxHeight: iconSize
    boxWidth: iconSize

    Text {
        // readonly property Network net: Network 
        readonly property string icon: {
            const fullConnectivity = Networking.connectivity == NetworkConnectivity.Full
            const wifiLevels = [
                "signal_wifi_0_bar",
                "network_wifi_1_bar",
                "network_wifi_2_bar",
                "network_wifi_3_bar",
                "signal_wifi_4_bar",
            ]

            let dev = null
            let net = null

            for (let i = 0; i < Networking.devices.values.length; i++) {
                const device = Networking.devices.values[i]
                if (device.connected) {
                    dev = device
                    net = device.networks.values[0]
                }
            }

            if (dev.type == DeviceType.Wifi) {
                let iconId = (Math.floor(net.signalStrength*wifiLevels.length))
                if (iconId == wifiLevels.length) {
                    iconId--
                }

                return wifiLevels[iconId]
            }

            if (dev.type == DeviceType.Wired) {
                return "settings_ethernet"
                // return fullConnectivity ? "󰛳" : "󰲛"
            }
            
            return "signal_wifi_off"
        }
        text: icon
        font.pixelSize: root.iconSize
        color: Colors.text
        anchors.centerIn: parent
        font.family: "Material Symbols Rounded" // Or Material Icons
        font.variableAxes: {
            "FILL": 0,
            "wght": 600,
            "GRAD": 0,
            "opsz": root.iconSize
        }
    }
}