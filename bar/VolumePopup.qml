import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

import "./components"
import "../Colors.js" as Colors

Container {
    id: root
    anchors {
        bottom: parent.bottom
        top: undefined
        horizontalCenter: parent.horizontalCenter
        bottomMargin: animatedBottomMargin
    }

    property real animatedBottomMargin: show ? 64 : - height - Colors.outlineWidth

    readonly property var audio: Pipewire.defaultAudioSink.audio
    readonly property real volume: audio.volume

    property bool show: false

    Behavior on animatedBottomMargin {
        NumberAnimation {
            duration: 80
            easing.type: Easing.InOutCubic
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    boxHeight: 64
    boxWidth: 256

    Timer {
        id: hideTimer
        repeat: false
        running: false
        onTriggered: {root.show=false}
        interval: 1000
    }

    GlobalShortcut {
        appid: "n4shell"
        name: "volume-up"
        onPressed: {
            root.show = true
            root.audio.volume = Math.min(root.volume + 0.05, 1.0)
            if (root.audio.muted) 
                root.audio.muted = false
            
            hideTimer.restart()
        }
    }

    GlobalShortcut {
        appid: "n4shell"
        name: "volume-down"
        onPressed: {
            root.show = true
            root.audio.volume = Math.max(root.volume - 0.05, 0.0)
            if (root.audio.muted) 
                root.audio.muted = false

            hideTimer.restart()
        }
    }

    GlobalShortcut {
        appid: "n4shell"
        name: "volume-mute"
        onPressed: {
            root.show = true
            root.audio.muted = !root.audio.muted
            hideTimer.restart()
        }
    }

    RowLayout {
        id: row
        // anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.rightMargin: 16
        // Layout.fillWidth: true
        spacing: 12
        
        Text {
            id: icon
            text: root.audio.muted ? "volume_off" : root.volume > 0.5 ? "volume_up" : "volume_down"
            color: Colors.text
            font.family: "Material Symbols Rounded" // Or Material Icons
            font.variableAxes: {
                "FILL": 0,
                "wght": 400,
                "GRAD": 0,
                "opsz": 48
            }
            font.pixelSize: 48
        }

        Rectangle {
            id: barBg
            // implicitWidth: root.width - icon.width - 32
            Layout.fillWidth: true
            height: 8
            radius: Colors.radius
            color: Colors.bg2
        }

        Rectangle {
            height: barBg.height
            color: Colors.highlight
            anchors {
                right: barBg.right
                left: barBg.left
                // leftMargin: icon.width + row.spacing
                rightMargin: animatedRightMargin
            }
            property real animatedRightMargin: barBg.width * (1-root.volume)
            Behavior on animatedRightMargin {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.Linear
                }
            }
            radius: Colors.radius
        }
    }
}