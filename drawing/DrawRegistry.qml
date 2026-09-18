pragma Singleton
import QtQuick

QtObject {
    id: drawRegistry
    property var items: []

    signal itemGeometryChanged

    // Coalesces the flood of per-property geometryChanged() emissions from every
    // Container into a single signal per frame. Without this, one animation frame
    // can emit itemGeometryChanged() dozens of times, each one asking every
    // DrawCanvas to repaint.
    property bool dirty: false

    function markDirty() {
        if (dirty) return
        dirty = true
        Qt.callLater(flush)
    }

    function flush() {
        if (!dirty) return
        dirty = false
        itemGeometryChanged()
    }

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
