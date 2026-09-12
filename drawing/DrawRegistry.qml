pragma Singleton
import QtQuick

QtObject {
    id: drawRegistry
    property var items: []

    signal itemGeometryChanged

    function addItem(item) {
        if (items.indexOf(item) === -1)
            items = items.concat(item)
    }

    function removeItem(item) {
        if (items.indexOf(item) === -1)
            return
        items = items.filter(i => i !== item)
    }

    function getAll() {
        return items
    }

    function getOnMonitor(monitor) {
        return items.filter(item => item.exclusiveMonitor === monitor && item.visible)
    }
}