import QtQuick

import "../components"

Container {
    id: root
    property real margin: 4
    default property Component source

    Loader {
        id: loader
        sourceComponent: root.source
        active: false
        onLoaded: {
            item.parent = root;
            // item.anchors.fill = root
        }
    }

    boxHeight: loader.item ? loader.item.implicitHeight + margin*2 : 0
    boxWidth: loader.item ? loader.item.implicitWidth + margin*2 : 0

    function show(component) {
        root.source = component
        loader.active = true
    }

    function hide() {
        loader.active = false
    }

}