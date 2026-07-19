pragma Singleton
import QtQuick

QtObject {
    id: drawRegistry
    property var items: []

    function addItem(item) {
        if (items.indexOf(item) === -1) 
            items.push(item)
    }

    function removeItem(item) {
        const index = items.indexOf(item)
        if (index !== -1)
            items.splice(index, 1)
    }

    function getAll() {
        return items
    }

    function getOnMonitor(monitor) {
        return items.filter(item => item.exclusiveMonitor === monitor)        
    }
}