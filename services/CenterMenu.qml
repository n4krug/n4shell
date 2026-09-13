pragma Singleton
import QtQuick
import Quickshell.Wayland

QtObject {
    id: centerMenu

    property var items: []
    property bool anyShown: false

    function addMenu(menu) {
        if (items.indexOf(menu) === -1)
            items = items.concat(menu)
    }

    function hideOthers(menu) {
        items.forEach(item => {
            if (item !== menu)
                item.show = false
        })
    }

    onAnyShownChanged: {
        console.log(anyShown)
    }
    
}