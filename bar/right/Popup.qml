pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property QtObject popupWindow
    property var closeCb
    
    function create(root, file, pos, closeCallback = null) {
        close()
        if (closeCallback != null) {
            closeCb = closeCallback
        }
        const component = Qt.createComponent(file)
        if (component.status === Component.Ready) {
            popupWindow = component.createObject(root, {
                x: pos.x,
                y: pos.y,
                exclusiveMonitor: root.monitor
            })
            console.log("Spawned Popup at", pos.x, pos.y)
        } else {
            console.log("Error loading component:", component.errorString());
        }
    }

    function close() {
        if (popupWindow != null) {
            closeCb()
            closeCb = null
            popupWindow.destroy()
            popupWindow = null
        }
    }

    function isOpen() {
        return popupWindow != null
    }
}