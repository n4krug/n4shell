import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

import "../components"
import "../../Colors.js" as Colors

Container {
    id: root

    property string query: ""

    property bool show: true
    boxHeight: show ? 256 * 1.5 : 0
    boxWidth: show ? 512 : 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        visible: root.show

        TextField {
            id: input
            Layout.fillWidth: true
            placeholderText: "Launch..."
            focus: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
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