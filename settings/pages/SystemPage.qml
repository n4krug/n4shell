import QtQuick
import Quickshell
import Quickshell.Bluetooth

import ".."

MenuPage {
    id: root

    title: "System"

    MenuRow {
        id: lock

        kind: "action"

        title: "Lock"
        icon: "lock"
        command: ["loginctl", "lock-session"]
    }

    MenuRow {
        id: sleep

        kind: "action"

        title: "Sleep"
        icon: "bedtime"
        command: ["systemctl", "sleep"]
    }
    
    MenuRow {
        id: restart

        kind: "action"

        title: "Restart"
        icon: "restart_alt"
        command: ["loginctl", "reboot"]
    }

    MenuRow {
        id: shutdown

        kind: "action"

        title: "Shutdown"
        icon: "power_settings_new"
        command: ["systemctl", "poweroff"]
    }
}