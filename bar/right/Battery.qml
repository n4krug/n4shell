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
        function findClosest(arr, target) {
            return arr.reduce((prev, curr) => {
                return Math.abs(curr - target) < Math.abs(prev - target) ? curr : prev;
            });
        }
        text: {
            let frac = UPower.displayDevice.percentage
            let level = Math.round(7*frac)
            if (level == 7) {
                return "battery_full"
            }
            if (UPower.displayDevice.state === UPowerDeviceState.Charging) {
                let icons = [
                    "battery_charging_full",
                    "battery_charging_20",
                    "battery_charging_30",
                    "battery_charging_50",
                    "battery_charging_60",
                    "battery_charging_80",
                    "battery_charging_90",
                ]
                return icons[Math.round(frac*icons.length)]
            }
            return `battery_${level}_bar`
            // if (level >= 95) return "󰁹"
            // else if (level >= 90) return "󰂂"
            // else if (level >= 80) return "󰂁"
            // else if (level >= 70) return "󰂀"
            // else if (level >= 60) return "󰁿"
            // else if (level >= 50) return "󰁾"
            // else if (level >= 40) return "󰁽"
            // else if (level >= 30) return "󰁼"
            // else if (level >= 20) return "󰁻"
            // else if (level >= 10) return "󰁺"
            // else return "󰂃"
        }
        readonly property string colorString: {

            if (UPower.displayDevice.percentage < 0.3) {
                return Colors.negative
            }

            // console.log(UPower.displayDevice.state)
            if (UPower.displayDevice.state === UPowerDeviceState.Charging) {
                return Colors.green
            }            

            return Colors.text
        }
        color: colorString
        anchors.centerIn: parent
        font.family: "Material Symbols Rounded" // Or Material Icons
        font.pixelSize: root.iconSize
        font.variableAxes: {
            "FILL": 0,
            "wght": 600,
            "GRAD": 0,
            "opsz": root.iconSize
        }
    }

    Component {
        id: batteryInfoComp
        BatteryInfo { 
            exclusiveMonitor: root.exclusiveMonitor
            anchors.fill: parent 
            // popupContainer: root.popupContainer
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.popupContainer.show(batteryInfoComp)
    }
}
