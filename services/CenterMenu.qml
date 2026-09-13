pragma Singleton
import QtQuick

QtObject {
    id: centerMenu

    property var items: []
    property bool anyShown: false

    function addMenu(menu) {
        if (items.indexOf(menu) === -1)
            items = items.concat(menu)
    }

    function removeMenu(menu) {
        items = items.filter(item => item !== menu)
        refresh()
    }

    function hideOthers(menu) {
        items.forEach(item => {
            if (item !== menu)
                item.show = false
        })
    }

    function refresh() {
        anyShown = items.some(item => item.show)
    }
}
