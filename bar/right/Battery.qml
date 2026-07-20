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

    required property PopupContainer popupContainer

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
        readonly property string colorString: {

            if (UPower.displayDevice.percentage < 0.3) {
                return Colors.outline
            }

            if (UPower.displayDevice.changeRate > 0) {
                return Colors.green
            }            

            return Colors.text
        }
        color: colorString
        anchors.centerIn: parent
        font.family: "Symbols Nerd Font" // Or Material Icons
        font.pixelSize: root.iconSize
    }

    Component {
        id: batteryInfoComp
        BatteryInfo { 
            exclusiveMonitor: root.exclusiveMonitor
            anchors.fill: parent 
            popupContainer: root.popupContainer
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.popupContainer.show(batteryInfoComp)
    }
}
