pragma Singleton
import QtQuick
import Quickshell.Hyprland

import "pages"
import "../services"

MenuPage {
    id: root

    title: "Settings"

    MenuRow {
        kind: "submenu"
        title: "Network"
        icon: "lan"
        page: networkPage

        Component {
            id: networkPage

            NetworkPage {}
        }
    }

    MenuRow {
        kind: "submenu"
        title: "Bluetooth"
        icon: "bluetooth"
        page: bluetoothPage

        Component {
            id: bluetoothPage

            BluetoothPage {}
        }
    }

    MenuRow {
        kind: "submenu"
        title: "System"
        icon: "settings_power"
        page: systemPage

        Component {
            id: systemPage

            SystemPage {}
        }
    }

    MenuRow {
        kind: "action"
        title: "Install"
        subtitle: PackageManager.busy
            ? PackageManager.statusLabel + " " + PackageManager.currentPackage
            : ""
        icon: "download"
        onTriggered: CenterMenu.openMenu("installer", Hyprland.focusedMonitor)
    }
}
