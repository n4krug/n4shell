import QtQuick
import Quickshell
import QtQuick.Effects
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.UPower

import "../components"
import "../../Colors.js" as Colors

pragma ComponentBehavior: Bound

Container {
    id: root

    required property real iconSize

    boxHeight: iconSize
    boxWidth: iconSize

    Text {
        text: {
            let level = UPower.displayDevice.percentage*100
            if (level >= 95) return "󰁹"
            else if (level >= 90) return "󰂂"
            else if (level >= 80) return "󰂁"
            else if (level >= 70) return "󰂀"
            else if (level >= 60) return "󰁿"
            else if (level >= 50) return "󰁾"
            else if (level >= 40) return "󰁽"
            else if (level >= 30) return "󰁼"
            else if (level >= 20) return "󰁻"
            else if (level >= 10) return "󰁺"
            else return "󰂃"
        }
        color: UPower.displayDevice.percentage > 0.3 ? Colors.text : Colors.outline
        anchors.centerIn: parent
        font.family: "Symbols Nerd Font" // Or Material Icons
        font.pixelSize: 12
    }

    BatteryInfo {
        exclusiveMonitor: root.exclusiveMonitor
        open: true
    }

        hover.onHoveredChanged: {
            console.log("hover")
        }

        HoverHandler {
            id: hoverHandler
        }
}
