import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

import "rows"
import "../Colors.js" as Colors

pragma ComponentBehavior: Bound

Item {
    id: root

    property string title: ""
    property var rows: []
    property bool canGoBack: false

    property Component pageComponent: null
    property var page: null

    readonly property var visibleRows: root.toArray(root.page ? root.page.rows : root.rows)
    readonly property string pageTitle: root.page ? root.page.title : root.title
    readonly property bool inputFocused: input.activeFocus

    property string query: ""

    signal backRequested()
    signal closeRequested()
    signal submenuRequested(var page)

    onPageComponentChanged: {
        root.page = root.pageComponent ? root.pageComponent.createObject(root) : null
    }

    function requestFocus() {
        input.forceActiveFocus()
    }

    function toArray(source) {
        const out = []

        if (!source)
            return out

        for (let i = 0; i < source.length; i++)
            out.push(source[i])

        return out
    }

    function currentRow() {
        const values = filtered.values

        if (list.currentIndex >= 0 && list.currentIndex < values.length)
            return values[list.currentIndex]

        return null
    }

    function activateCurrent() {
        const row = root.currentRow()

        if (!row)
            return

        if (row.kind === "submenu") {
            if (row.page)
                root.submenuRequested(row.page)
            return
        }

        row.activate()
    }

    function nudgeCurrent(direction) {
        const row = root.currentRow()

        if (!row || row.kind !== "slider")
            return

        root.moveSlider(row, direction)
    }

    function moveSlider(row, direction) {
        const next = Math.min(row.to, Math.max(row.from, row.value + direction * row.step))
        row.moved(Math.round(next / row.step) * row.step)
    }

    ScriptModel {
        id: filtered
        values: {
            const q = root.query.trim().toLowerCase()

            if (q === "")
                return root.visibleRows

            return root.visibleRows.filter(row => row.title && row.title.toLowerCase().includes(q))
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "arrow_back"
                visible: root.canGoBack
                color: Colors.text
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                font.variableAxes: {
                    "FILL": 0,
                    "wght": 600,
                    "GRAD": 0,
                    "opsz": 20
                }

                TapHandler {
                    onTapped: root.backRequested()
                }
            }

            Text {
                text: root.pageTitle
                color: Colors.text
                font.bold: true
                font.pixelSize: 16
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        TextField {
            id: input
            Layout.fillWidth: true
            placeholderText: "Search..."
            padding: 12
            color: Colors.text
            placeholderTextColor: Colors.text
            font.pixelSize: 16
            background: Rectangle {
                color: Colors.highlight
                border.width: 0
                opacity: 0.15
                radius: Colors.radius
            }

            onTextChanged: {
                root.query = text
                list.currentIndex = filtered.values.length > 0 ? 0 : -1
            }

            Keys.onEscapePressed: {
                if (root.query !== "")
                    input.text = ""
                else
                    root.backRequested()
            }

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;

                if (event.key === Qt.Key_Up || event.key === Qt.Key_K && ctrl) {
                    event.accepted = true;
                    if (list.currentIndex > 0)
                        list.currentIndex--;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J && ctrl) {
                    event.accepted = true;
                    if (list.currentIndex < list.count - 1)
                        list.currentIndex++;
                } else if (event.key === Qt.Key_Right) {
                    event.accepted = true;
                    root.nudgeCurrent(1)
                } else if (event.key === Qt.Key_Left) {
                    event.accepted = true;
                    root.nudgeCurrent(-1)
                } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
                    event.accepted = true;
                    root.activateCurrent();
                } else if (event.key === Qt.Key_Q && ctrl) {
                    event.accepted = true;
                    root.closeRequested();
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            spacing: 4

            model: filtered.values
            currentIndex: filtered.values.length > 0 ? 0 : -1
            keyNavigationWraps: true
            preferredHighlightBegin: 0
            preferredHighlightEnd: height
            highlightRangeMode: ListView.ApplyRange
            highlightMoveDuration: 80
            highlightResizeDuration: 0
            highlight: Rectangle {
                radius: Colors.radius
                opacity: 0.15
                color: Colors.highlight
            }

            delegate: Item {
                id: entry

                required property int index
                required property var modelData

                width: ListView.view.width
                height: 52

                Loader {
                    id: loader
                    anchors.fill: parent
                    sourceComponent: {
                        switch (entry.modelData.kind) {
                            case "submenu": return submenuRow
                            case "toggle": return toggleRow
                            case "slider": return sliderRow
                            default: return actionRow
                        }
                    }
                    onLoaded: {
                        item.row = entry.modelData
                        item.select = () => {
                            list.currentIndex = entry.index
                            root.requestFocus()
                        }
                        item.openRequested = () => root.activateCurrent()
                    }
                }
            }
        }
    }

    Component { id: actionRow; ActionRow {} }
    Component { id: toggleRow; ToggleRow {} }
    Component { id: sliderRow; SliderRow {} }
    Component { id: submenuRow; SubmenuRow {} }
}
