import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

import "../components"
import "../../Colors.js" as Colors

pragma ComponentBehavior: Bound
Container {
    id: root

    property int playerId: 0
    readonly property list<MprisPlayer> players: Mpris.players.values
    readonly property MprisPlayer player: players[playerId]

    Component.onCompleted: {
        const firstPlaying = players.findIndex(elem => elem.isPlaying)

        if (firstPlaying >= 0) {
            changePlayer(firstPlaying)
        }
    }

    readonly property real margin: 8

    function changePlayer(i) {
        playerId = Math.max(0, Math.min(players.length - 1, playerId + i))
        selectedPlayerIndicator.move()
    }

    readonly property real controlHeights: 175
    // boxHeight: players.length > 1 ? controlHeights + idIndicators.height + idIndicators.anchors.bottomMargin*2 : controlHeights
    boxHeight: controlHeights
    boxWidth: 350

    MouseArea {
        anchors.fill: parent
        ClippingRectangle {
            id: playerInfoContainer
            color: "transparent"
            radius: Colors.radius - root.margin
            clip: true
            anchors {
                fill: parent
                margins: root.margin
                // bottomMargin: root.players.length > 1 ? idIndicators.height + idIndicators.anchors.bottomMargin*2 : root.margin
            }

            Row {
                width: playerInfoContainer.width * 2 + spacing
                // anchors.fill: parent
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }

                property real animatedMargin: -root.playerId * (playerInfoContainer.width + spacing)
                anchors.leftMargin: animatedMargin

                // Rectangle {
                //     color: "cyan"
                //     opacity: 0.5
                //     anchors.fill: parent
                // }

                Behavior on animatedMargin {
                    NumberAnimation {
                        duration: (selectedPlayerIndicator.fast + selectedPlayerIndicator.slow)/2
                        easing.type: Easing.InOutCubic
                    }
                }
                spacing: root.margin
                Repeater {
                    model: root.players

                    delegate: Item {
                        id: playerInfoBox
                        required property MprisPlayer modelData
                        required property int index

                        anchors {
                            // left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: playerInfoContainer.width

                        Rectangle {
                            color: Colors.bg3
                            opacity: 0.3
                            anchors.fill: parent
                            radius: playerInfoContainer.radius
                            Image {
                                anchors {
                                    fill: parent
                                }
                                source: playerInfoBox.modelData.trackArtUrl
                                fillMode: Image.PreserveAspectCrop

                                Component.onCompleted: {
                                    const origUrl = playerInfoBox.modelData.metadata["xesam:url"]
                                    if (origUrl.includes("youtube")) {
                                        const id = origUrl.split("=")[1]
                                        source = "https://img.youtube.com/vi/" + id + "/maxresdefault.jpg"
                                    }
                                }
                            }

                            
                            Rectangle {
                                anchors.fill: parent
                                color: "black"
                            }
                        }

                        
                        Text {
                            id: playerIcon
                            anchors {
                                top: parent.top
                                topMargin: root.margin*2 - 2
                                leftMargin: root.margin*2
                                left: parent.left
                            }
                            text: icon
                            color: Colors.text
                            font.pixelSize: 20
                            readonly property string icon: {
                                // console.log(JSON.stringify(playerInfoBox.modelData))
                                switch (playerInfoBox.modelData.desktopEntry) {
                                    case "zen":
                                        return ""
                                    case "spotify":
                                        return ""
                                    default:
                                        return "󰎆"
                                }
                            }
                        }

                        Text {
                            id: title
                            text: playerInfoBox.modelData.trackTitle || "Title Unknown"
                            font {
                                pixelSize: 18
                                bold: true
                            }
                            color: Colors.text
                            width: 200
                            elide: Text.ElideRight
                            anchors {
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: -10
                                left: parent.left
                                leftMargin: root.margin*2
                            }
                        }
                        Text {
                            id: artist
                            text: playerInfoBox.modelData.trackArtist || "Artist Unknown"
                            font {
                                pixelSize: 16
                                bold: false
                            }
                            color: Colors.text
                            width: root.width - 100
                            elide: Text.ElideRight
                            anchors {
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: 10
                                left: parent.left
                                leftMargin: root.margin*2
                            }
                        }
                        Rectangle {
                            id: playPauseBox
                            width: 50
                            height: 40
                            radius: Colors.radius * 1.5
                            color: Colors.text

                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                rightMargin: root.margin*2

                            }

                            Text {
                                text: playerInfoBox.modelData.isPlaying ? "" : ""
                                font.pixelSize: 18
                                anchors.centerIn: parent
                                color: Colors.bg1
                            }

                            TapHandler {
                                onTapped: {
                                    if (playerInfoBox.modelData.canTogglePlaying) {
                                        playerInfoBox.modelData.togglePlaying()
                                    }
                                }
                            }
                        }

                        Text {
                            id: previous

                            text: ""

                            font.pixelSize: 18
                            color: playerInfoBox.modelData.canGoPrevious ? Colors.text : Colors.bg3

                            anchors {
                                left: parent.left
                                bottom: parent.bottom
                                leftMargin: root.margin*2
                                bottomMargin: root.margin*2
                            }

                            TapHandler {
                                onTapped: {
                                    if (playerInfoBox.modelData.canGoPrevious) {
                                        playerInfoBox.modelData.previous()
                                    }
                                }
                            }
                        }
                        Text {
                            id: next

                            text: ""

                            font.pixelSize: 18
                            color: playerInfoBox.modelData.canGoNext ? Colors.text : Colors.bg3

                            anchors {
                                right: parent.right
                                bottom: parent.bottom
                                rightMargin: root.margin*2 + (shuffle.visible ? shuffle.width + root.margin*2 : 0)
                                bottomMargin: root.margin*2
                            }

                            TapHandler {
                                onTapped: {
                                    if (playerInfoBox.modelData.canGoNext) {
                                        playerInfoBox.modelData.next()
                                    }
                                }
                            }
                        }
                        Text {
                            id: shuffle

                            text: ""

                            font.pixelSize: 18
                            color: playerInfoBox.modelData.shuffle ? Colors.text : Colors.bg3
                            visible: playerInfoBox.modelData.shuffleSupported

                            anchors {
                                right: parent.right
                                bottom: parent.bottom
                                rightMargin: root.margin*2
                                bottomMargin: root.margin*2
                            }

                            TapHandler {
                                onTapped: {
                                    if (playerInfoBox.modelData.shuffleSupported) {
                                        playerInfoBox.modelData.shuffle = !playerInfoBox.modelData.shuffle
                                    }
                                }
                            }
                        }
                        MouseArea {
                            id: seekBar

                            visible: playerInfoBox.modelData.lengthSupported

                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                                bottomMargin: root.margin*2
                                leftMargin: root.margin*4 + previous.width
                                rightMargin: root.margin*4 + next.width + (shuffle.visible ? shuffle.width + root.margin*2 : 0)
                            }

                            height: previous.height

                            Rectangle {
                                color: Colors.bg3
                                anchors {
                                    right: parent.right
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                                height: 2
                                radius: Colors.radius
                            }

                            Rectangle {
                                id: seekProgress
                                color: Colors.text
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                                height: 2
                                width: widthFraction * seekBar.width
                                radius: Colors.radius
                                property real widthFraction: playerInfoBox.modelData.position/(playerInfoBox.modelData.length || 1)

                                Timer {
                                    running: playerInfoBox.modelData.isPlaying

                                    interval: 200
                                    repeat: true

                                    onTriggered: playerInfoBox.modelData.positionChanged()
                                }

                                Behavior on widthFraction {
                                    NumberAnimation {
                                        duration: 175
                                        easing.type: Easing.Linear
                                    }
                                }
                            }

                            Rectangle {
                                color: Colors.text
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: seekProgress.width - width
                                }
                                width: 4
                                height: 12
                                radius: Colors.radius
                            }

                            onPressed: mouse => {
                                const frac = mouse.x/width
                                if (playerInfoBox.modelData.positionSupported) {
                                    playerInfoBox.modelData.position = playerInfoBox.modelData.length * frac
                                }
                            }
                        }
                    }
                }
            }
        }

        Row {
            visible: root.players.length > 1
            id: idIndicators
            anchors {
                bottom: parent.bottom
                bottomMargin: root.margin*2
                horizontalCenter: parent.horizontalCenter
                topMargin: root.margin
            }
            spacing: root.margin
            Repeater {
                model: root.players.length

                delegate: Rectangle {
                    required property int index

                    implicitHeight: (Colors.barHeight - root.margin)/2
                    implicitWidth: (Colors.barHeight - root.margin)

                    radius: 4

                    color: Colors.bg3
                }
            }
        }
        Rectangle {
            visible: root.players.length > 1
            id: selectedPlayerIndicator

            height: idIndicators.height
            readonly property real targetWidth: (Colors.barHeight - root.margin)
            width: animatedRight - animatedLeft
            x: idIndicators.x + animatedLeft
            y: 0
            z: 1

            property real animatedLeft: 0
            property real animatedRight: targetWidth

            readonly property real fast: 180
            readonly property real slow: 700

            property real leftDuration: fast
            property real rightDuration: fast

            // property real rightMargin: root.playerId*(Colors.barHeight-8+idIndicators.spacing)

            function slotX(index) {
                return index * (targetWidth + idIndicators.spacing)
            }

            property int oldPlayerId: 0
            function move() {
                const left = slotX(root.playerId)
                const right = left + targetWidth

                if (root.playerId > oldPlayerId) { // moving right
                    rightDuration = fast
                    leftDuration = slow
                } else if (root.playerId < oldPlayerId) { // moving left
                    rightDuration = slow
                    leftDuration = fast
                }

                animatedLeft = left
                animatedRight = right

                oldPlayerId = root.playerId
            }

            Component.onCompleted: {
                move()
            }

            Behavior on animatedLeft {
                NumberAnimation {
                    duration: selectedPlayerIndicator.leftDuration
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on animatedRight {
                NumberAnimation {
                    duration: selectedPlayerIndicator.rightDuration
                    easing.type: Easing.OutCubic
                }
            }

            radius: 4

            color: Colors.text

            anchors {
                bottom: parent.bottom
                bottomMargin: root.margin*2
                // horizontalCenter: parent.horizontalCenter
                // horizontalCenterOffset: -(idIndicators.implicitWidth - this.implicitWidth)/2 + Math.min(edgeA, edgeB)
                // left: parent.left
            }
        }

        onWheel: (wheel) => {
            const i = wheel.angleDelta.y > 0 ? -1 : 1
            root.changePlayer(i)
        }
    }
}
