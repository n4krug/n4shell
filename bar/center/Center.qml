import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../components"
import "../../services"

Container {
    id: center
    
    hoverableWhenHidden: true
    exclusiveToScreen: true
    // forceHidden: true
    hiddenTopMargin: (2-boxHeight)
    boxHeight: 16
    boxWidth: 70
    boxRadius: 8
    boxTLRadius: -boxRadius
    boxTRRadius: -boxRadius
    anchoredSides: [Container.Top]

    content: [
        Text {
            text: Time.time
            font.bold: true
            anchors.centerIn: parent
        }
    ]
}