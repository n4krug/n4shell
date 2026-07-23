import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Hyprland
import Quickshell.Widgets

import "../components"
import "../../Colors.js" as Colors




Container {
    id: root

    required property PopupContainer popupContainer

    anchors {
        top: parent.bottom
        right: parent.right
    }
    boxHeight: 70
    boxWidth: 70

    Text {
        readonly property UPowerDevice device: UPower.displayDevice
        readonly property string percentage: Math.round(device.percentage*100) + "%"
        readonly property string rate: Math.round(device.changeRate) + "W"
        readonly property string timeLeft: Math.round(device.timeToEmpty/6)/10 + "min"

        text: percentage + "\n" + rate + "\n" + timeLeft
        color: Colors.text
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
    }

 }