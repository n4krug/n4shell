pragma Singleton
import QtQuick

import "pages"

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
}
