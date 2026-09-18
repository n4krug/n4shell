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
        kind: "submenu"
        title: "Packages"
        icon: "package_2"
        page: packagePage

        Component {
            id: packagePage

            MenuPage {
                title: "Packages"

                MenuRow {
                    kind: "action"
                    title: "Update"
                    subtitle: UpdateManager.busy
                        ? UpdateManager.statusLabel + " " + UpdateManager.currentPackage
                        : UpdateManager.pendingCount > 0
                            ? UpdateManager.pendingCount + " updates available"
                            : "Up to date"
                    icon: "upload"
                    onTriggered: CenterMenu.openMenu("updater", Hyprland.focusedMonitor)
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

                MenuRow {
                    kind: "action"
                    title: "Uninstall"
                    subtitle: UninstallManager.busy
                        ? UninstallManager.statusLabel + " " + UninstallManager.currentPackage
                        : UninstallManager.pendingCount > 0
                            ? UninstallManager.pendingCount + " packages installed"
                            : ""
                    icon: "delete"
                    onTriggered: CenterMenu.openMenu("uninstaller", Hyprland.focusedMonitor)
                }


            }
        }
    }
}
