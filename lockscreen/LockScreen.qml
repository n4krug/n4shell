import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
pragma ComponentBehavior: Bound

Item {
    id: root

	LockContext {
		id: lockContext
        onUnlocked: {
            console.log("unlocked")
            lock.locked = false
        }
	}

	WlSessionLock {
        id: lock

        locked: false

		WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }

	}

    GlobalShortcut {
        appid: "n4shell"
        name: "lock"

        onPressed: {
            lock.locked = true
        }
    }
}