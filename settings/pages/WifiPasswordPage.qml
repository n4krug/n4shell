import QtQuick

import ".."

MenuPage {
    id: root

    title: network ? (network.name || "Hidden network") : "Enter password"

    property bool passwordMode: true
    property string password: ""
    property var network: null

    signal submitted()

    function submitPassword() {
        if (!root.network || root.password === "")
            return

        root.network.connectWithPsk(root.password)
        root.submitted()
    }

    MenuRow {
        kind: "action"
        title: "Connect"
        subtitle: root.password === "" ? "type a password" : ""
        icon: "wifi"
        enabled: root.password !== ""

        onTriggered: root.submitPassword()
    }
}
