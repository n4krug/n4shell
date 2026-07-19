import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.UPower

import "../../Colors.js" as Colors

MouseArea {
    id: root

    required property real iconSize

    required property HyprlandMonitor monitor

    implicitHeight: iconSize
    implicitWidth: iconSize
    
    // Rectangle {
    //     anchors.fill: parent
    //     anchors {
    //         margins: 2
    //     }
    //     color: Colors.bg2
    //     radius: Colors.radius/2
    // }

    property bool popupOpen: false

    onPressed: (mouse) => {
        var mappedPos = root.mapToItem(null, root.x, root.y)

        if (popupOpen) {
            Popup.close()
        } else {
            Popup.create(root, "BatteryInfo.qml", mappedPos, () => {
                popupOpen = false
            })
            popupOpen = true   
        }
    }

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

}
