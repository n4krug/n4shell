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
                "󰤯",
                "󰤟",
                "󰤢",
                "󰤥",
                "󰤨"
            ]
            const wifiLevelsNotFull = [
                "󰤫",
                "󰤠",
                "󰤣",
                "󰤦",
                "󰤩"
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

                return fullConnectivity ? wifiLevels[iconId] : wifiLevelsNotFull[iconId]
            }

            if (dev.type == DeviceType.Wired) {
                return fullConnectivity ? "󰛳" : "󰲛"
            }
            
            return "󰤯"
        }
        text: icon
        font.pixelSize: root.iconSize
        color: Colors.text
        anchors.centerIn: parent
    }
}