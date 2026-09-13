import QtQuick
import Quickshell
import Quickshell.Networking

import ".."

MenuPage {
    id: root

    title: "Network"

    property var wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) || null

    readonly property var activeNetwork: {
        if (!root.wifiDevice)
            return null

        return root.wifiDevice.networks.values.find(network => network.connected) || null
    }

    MenuRow {
        kind: "toggle"
        title: "Wi-Fi"
        subtitle: root.wifiDevice ? root.wifiDevice.name : "No Wi-Fi device"
        icon: "wifi"
        checked: Networking.wifiEnabled
        onToggled: newValue => Networking.wifiEnabled = newValue
    }

    MenuRow {
        kind: "submenu"
        title: "Connect to Wi-Fi"
        subtitle: root.activeNetwork ? root.activeNetwork.name : "Not connected"
        icon: "wifi_find"
        enabled: root.wifiDevice !== null
        page: wifiListPage

        Component {
            id: wifiListPage

            WifiListPage {
                device: root.wifiDevice
            }
        }
    }
}
