import QtQuick
import Quickshell
import QtQuick.Shapes
import Quickshell.Hyprland

Item {
    id: canvas
    required property HyprlandMonitor monitor

    Component.onCompleted: {
        const items = DrawRegistry.getOnMonitor(monitor)

        items.forEach(item => {
            console.log(monitor.name, item, item.mapFromGlobal(0, 0))
        })
    }

}