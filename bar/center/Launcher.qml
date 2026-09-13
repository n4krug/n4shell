import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

import "../components"
import "../../services"
import "../../Colors.js" as Colors

pragma ComponentBehavior: Bound

Container {
    id: root

    property string query: ""

    function launchSelected() {
        if (list.currentItem && list.currentItem.modelData) {
            list.currentItem.modelData.execute();
            show = false
        }
    }

    property bool show: false
    boxHeight: show ? 256 * 1.5 : 0
    boxWidth: show ? 512 : 0

    GlobalShortcut {
        appid: "n4shell"
        name: "launcher"
        onPressed: {
            if (Hyprland.focusedMonitor !== root.exclusiveMonitor) return
            root.show = !root.show
        }
    }

    Component.onCompleted: {
        CenterMenu.addMenu(this)
    }

    Component.onDestruction: {
        CenterMenu.removeMenu(this)
    }

    onShowChanged: {
        if (show) {
            Qt.callLater(()=>input.forceActiveFocus())
            CenterMenu.hideOthers(root)
        } else {
            input.text = ""
            input.focus = false
        }
        CenterMenu.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        visible: root.show

        TextField {
            id: input
            Layout.fillWidth: true
            placeholderText: "Launch..."
            focus: true
            padding: 16
            onTextChanged: {
                root.query = text
                list.currentIndex = filtered.values.length > 0 ? 0 : -1
            }
            color: Colors.text
            placeholderTextColor: Colors.text
            font.pixelSize: 24
            background: Rectangle {
                color: Colors.highlight
                border.width: 0
                opacity: 0.15
                radius: Colors.radius
            }
            Keys.onEscapePressed: {
                root.show = false
            }

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;
                if (event.key == Qt.Key_Up || event.key == Qt.Key_K && ctrl) {
                    event.accepted = true;
                    if (list.currentIndex > 0)
                        list.currentIndex--;
                } else if (event.key == Qt.Key_Down || event.key == Qt.Key_J && ctrl) {
                    event.accepted = true;
                    if (list.currentIndex < list.count - 1)
                        list.currentIndex++;
                } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
                    event.accepted = true;
                    root.launchSelected();
                } else if (event.key == Qt.Key_Q && ctrl) {
                    event.accepted = true;
                    root.show = false
                }
            }
        }

        // Filtered model: only items matching the query
        // From: https://gist.github.com/tylerjl/5bc79f1ee0e4f66abed29b66f4f5f3cc
        ScriptModel {
            id: filtered
            values: {
                const allEntries = [...DesktopEntries.applications.values].sort((a,b) => {
                    return ('' + a.name).localeCompare(b.name);
                });
                const q = root.query.trim();

                if (q === "") {
                    return allEntries;
                } else {
                    return allEntries.filter(d => d.name && d.name.toLowerCase().includes(q));
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true

            model: filtered.values
            currentIndex: filtered.values.length > 0 ? 0 : -1
            keyNavigationWraps: true
            preferredHighlightBegin: 0
            preferredHighlightEnd: height
            highlightRangeMode: ListView.ApplyRange
            highlightMoveDuration: 80
            highlight: Rectangle {
                radius: Colors.radius
                opacity: 0.15
                color: Colors.highlight
            }
            highlightResizeDuration: 0

            delegate: Item {
                id: entry
                required property var modelData
                height: 64
                width: ListView.view.width
                property real margin: 8

                MouseArea {
                    anchors.fill: parent
                    onClicked: list.currentIndex = entry.index
                    onDoubleClicked: root.launchSelected()
                }

                Row {
                    // anchors.fill: parent
                    anchors.right: parent.right
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: entry.margin
                    spacing: 16

                    IconImage {
                        source: Quickshell.iconPath(modelData.icon, true)
                        width: entry.height - entry.margin*2
                        height: entry.height - entry.margin*2
                    }
                    Text {
                        id: label
                        color: "white"
                        text: modelData.name
                        font.pointSize: 16
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Keys.onReturnPressed: root.launchSelected()
        }
    }


    property bool hasHovered: false
    hover.onHoveredChanged: {
        if (hover.hovered) {
            hasHovered = true
        } else if (!hover.hovered && hasHovered) {
            show = false
            hasHovered = false
        }
    }
}