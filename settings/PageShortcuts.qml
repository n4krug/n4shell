import QtQuick
import Quickshell
import Quickshell.Hyprland

pragma ComponentBehavior: Bound

Item {
    id: root

    property var target: null

    Component.onCompleted: root.walk(Pages.rows, [])

    function slug(text) {
        return String(text).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
    }

    function walk(rows, path) {
        const source = rows ? rows : []
        const taken = []

        for (let i = 0; i < source.length; i++) {
            const row = source[i]

            if (!row || !row.page)
                continue

            const step = row.rowId ? row.rowId : row.title
            const name = "settings-" + root.slug(step)

            if (taken.indexOf(name) !== -1) {
                console.warn("PageShortcuts: duplicate shortcut " + name + ", skipping")
                continue
            }

            taken.push(name)

            shortcutComponent.createObject(root, {
                name: name,
                path: path.concat([step]),
            })

            const page = row.page.createObject(root, { preview: true })

            if (page) {
                root.walk(page.rows, path.concat([step]))
                page.destroy()
            }
        }
    }

    Component {
        id: shortcutComponent

        Item {
            id: holder

            property string name: ""
            property var path: []

            GlobalShortcut {
                appid: "n4shell"
                name: holder.name

                onPressed: {
                    if (!root.target)
                        return

                    if (Hyprland.focusedMonitor !== root.target.exclusiveMonitor)
                        return

                    root.target.openPath(holder.path)
                }
            }
        }
    }
}
