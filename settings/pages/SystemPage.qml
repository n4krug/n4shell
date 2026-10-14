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
        id: logout

        kind: "action"

        title: "Logout"
        icon: "logout"
        command: ["hyprshutdown", "-t", "'Logging out...'"]
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
        command: ["systemctl", "reboot"]
    }

    MenuRow {
        id: restartWindows

        kind: "action"

        title: "Boot Windows"
        icon: "view_compact_alt"
        command: ["sudo", "efibootmgr", "--bootnext", "0000", "&&", "systemctl", "reboot"]
    }

    MenuRow {
        id: shutdown

        kind: "action"

        title: "Shutdown"
        icon: "power_settings_new"
        command: ["systemctl", "poweroff"]
    }
}