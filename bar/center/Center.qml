import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "../components"
import "../../services"
import "../../Colors.js" as Colors
pragma ComponentBehavior: Bound

Item {
    id: root

    required property HyprlandMonitor exclusiveMonitor

    implicitHeight: center.implicitHeight + popup.implicitHeight
    implicitWidth: Math.max(center.implicitWidth, popup.width)

    Container {
        id: center

        anchors.horizontalCenter: parent.horizontalCenter

        exclusiveMonitor: root.exclusiveMonitor
        hoverableWhenHidden: true
        exclusiveToScreen: true
        // forceHidden: true
        hiddenTopMargin: -boxHeight
        boxHeight: Colors.barHeight
        boxWidth: 70

        Text {
            text: Time.time
            font.bold: true
            // font.family: "Rubik 80s Fade"
            anchors.centerIn: parent
            color: Colors.text
        }
        
        HoverHandler {
            id: hoverHandler
        }

        hover.onHoveredChanged: {
            if (hover.hovered && !popup.shown) {
                popup.show(testPopup)
            }
        }
    }
    
    PopupContainer {
        id: popup
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            // right: parent.right
            // left: parent.left
        }
        visibleTopMargin: center.boxHeight + Colors.barHeight

        exclusiveMonitor: center.exclusiveMonitor
    }



    Component {
        id: testPopup

        MediaControl {
            exclusiveMonitor: root.exclusiveMonitor
        }
    }
}