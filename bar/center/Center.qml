import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../components"
import "../../services"
import "../../Colors.js" as Colors

Container {
    id: center
    
    hoverableWhenHidden: true
    exclusiveToScreen: true
    // forceHidden: true
    hiddenTopMargin: -boxHeight
    boxHeight: Colors.barHeight
    boxWidth: 70

    Text {
        text: Time.time
        font.bold: true
        anchors.centerIn: parent
        color: Colors.text
    }
}