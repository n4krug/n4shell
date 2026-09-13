import QtQuick
import Quickshell
import Quickshell.Bluetooth

import ".."

MenuPage {
    id: root

    title: "Bluetooth"

    property var adapter: Bluetooth.defaultAdapter

    readonly property var activeDevice: {
        if (!root.adapter)
            return null

        return root.adapter.devices.values.find(device => device.connected) || null
    }

    MenuRow {
        kind: "toggle"
        title: "Bluetooth"
        subtitle: root.adapter ? root.adapter.name : "No Bluetooth adapter"
        icon: "bluetooth"
        enabled: root.adapter !== null
        checked: root.adapter ? root.adapter.enabled : false
        onToggled: newValue => {
            if (root.adapter)
                root.adapter.enabled = newValue
        }
    }

    MenuRow {
        kind: "submenu"
        title: "Connect to Bluetooth"
        subtitle: root.activeDevice ? (root.activeDevice.name || root.activeDevice.deviceName) : "Not connected"
        icon: "bluetooth_searching"
        enabled: root.adapter !== null
        page: bluetoothListPage

        Component {
            id: bluetoothListPage

            BluetoothListPage {
                adapter: root.adapter
            }
        }
    }
}
