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
    hiddenTopMargin: (4-boxHeight)
    boxHeight: 18
    boxWidth: 70
    anchoredSides: [Container.Top]

    Text {
        text: Time.time
        font.bold: true
        anchors.centerIn: parent
        color: Colors.text
    }
}