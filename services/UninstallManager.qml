pragma Singleton
import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property var installed: []
  property bool refreshing: false

  property string mode: "deps"

  property string status: "idle"
  property string currentPackage: ""
  property var log: []
  property real progress: -1
  property string error: ""
  property bool lockedDb: false
  property string pendingAction: ""
  property bool cancelled: false

  property string password: ""

  property var selected: ({})
  property var pendingNames: []

  readonly property var entries: root.installed
  readonly property bool busy: root.status === "checking" || root.status === "auth" || root.status === "removing"
  readonly property bool needsPassword: root.status === "auth"
  readonly property bool active: root.busy || finishTimer.running
  readonly property string lastLogLine: root.log.length > 0 ? root.log[root.log.length - 1] : ""
  readonly property int pendingCount: root.installed.length
  readonly property int selectedCount: root.installed.filter(entry => root.selected[entry.name] === true).length

  readonly property string statusLabel: {
    switch (root.status) {
      case "checking": return "Checking permissions"
      case "auth": return "Password required"
      case "removing": return "Removing"
      case "done": return "Removed"
      case "failed": return "Failed"
      case "cancelled": return "Cancelled"
      default: return ""
    }
  }

  readonly property string removeFlag: {
    if (root.mode === "pkg") return "-R"
    if (root.mode === "purge") return "-Rns"

    return "-Rs"
  }

  property var infoEntries: []
  property var foreignNames: ({})
  property bool infoDone: true
  property bool foreignDone: true

  function refresh() {
    if (root.busy)
      return

    root.refreshing = true
    root.infoEntries = []
    root.foreignNames = ({})
    root.infoDone = false
    root.foreignDone = false

    infoProc.running = false
    infoProc.command = ["pacman", "-Qi"]
    infoProc.running = true

    foreignProc.running = false
    foreignProc.command = ["pacman", "-Qqm"]
    foreignProc.running = true
  }

  function onInfoFinished(text) {
    root.infoEntries = root.parseInstalled(text)
    root.infoDone = true
    root.merge()
  }

  function onForeignFinished(text) {
    const names = ({})

    String(text).split("\n").forEach(line => {
      const name = line.trim()

      if (name)
        names[name] = true
    })

    root.foreignNames = names
    root.foreignDone = true
    root.merge()
  }

  function parseInstalled(text) {
    const out = []
    let current = null

    String(text).split("\n").forEach(line => {
      if (line.trim().length === 0) {
        if (current) {
          out.push(current)
          current = null
        }

        return
      }

      const split = line.indexOf(":")

      if (split <= 0)
        return

      const key = line.slice(0, split).trim()
      const value = line.slice(split + 1).trim()

      if (key === "Name") {
        if (current)
          out.push(current)

        current = {
          name: value,
          version: "",
          description: "",
          size: "",
          repo: "",
          source: "repo"
        }
      } else if (current) {
        if (key === "Version")
          current.version = value
        else if (key === "Description")
          current.description = value
        else if (key === "Installed Size")
          current.size = value
      }
    })

    if (current)
      out.push(current)

    return out
  }

  function merge() {
    if (!root.infoDone || !root.foreignDone)
      return

    const list = root.infoEntries

    list.forEach(entry => {
      if (root.foreignNames[entry.name]) {
        entry.source = "aur"
        entry.repo = "aur"
      }
    })

    list.sort((a, b) => a.name.localeCompare(b.name))

    root.installed = list

    const next = ({})

    list.forEach(entry => {
      next[entry.name] = root.selected[entry.name] === true
    })

    root.selected = next
    root.refreshing = false
  }

  function isSelected(name) {
    return root.selected[name] === true
  }

  function toggle(name) {
    const next = Object.assign({}, root.selected)
    next[name] = !root.isSelected(name)
    root.selected = next
  }

  function selectAll() {
    const next = ({})

    root.installed.forEach(entry => {
      next[entry.name] = true
    })

    root.selected = next
  }

  function selectNone() {
    root.selected = ({})
  }

  function selectedNames() {
    return root.installed.filter(entry => root.isSelected(entry.name)).map(entry => entry.name)
  }

  function commitSelected() {
    if (root.busy)
      return

    const names = root.selectedNames()

    if (names.length === 0)
      return

    root.currentPackage = names.length === 1 ? names[0] : names.length + " packages"
    root.log = []
    root.progress = -1
    root.error = ""
    root.lockedDb = false
    root.cancelled = false
    root.pendingNames = names
    root.requireAuth("remove")
  }

  function requireAuth(action) {
    root.pendingAction = action
    root.status = "checking"
    checkProc.running = false
    checkProc.running = true
  }

  function onChecked(exitCode) {
    if (exitCode === 0)
      root.runPending()
    else
      root.status = "auth"
  }

  function submitPassword(value) {
    if (!value)
      return

    root.password = value
    sudoProc.running = false
    sudoProc.command = ["sudo", "-S", "-v", "-p", ""]
    sudoProc.running = true
  }

  function onAuthenticated(exitCode) {
    const value = root.password
    root.password = ""

    if (exitCode !== 0) {
      root.error = "Wrong password"
      root.status = "auth"
      return
    }

    root.runPending()
  }

  function runPending() {
    const action = root.pendingAction
    root.pendingAction = ""

    if (action === "unlock") {
      unlockProc.running = false
      unlockProc.command = ["sudo", "-n", "rm", "-f", "/var/lib/pacman/db.lck"]
      unlockProc.running = true
      return
    }

    root.beginRemove()
  }

  function beginRemove() {
    const command = root.removeCommand()

    root.status = "removing"
    root.appendLog("$ " + command.join(" "))
    removeProc.running = false
    removeProc.command = command
    removeProc.running = true
  }

  function removeCommand() {
    return ["sudo", "-n", "pacman", root.removeFlag, "--noconfirm"].concat(root.pendingNames)
  }

  function cancel() {
    if (!root.busy)
      return

    root.cancelled = true

    if (removeProc.running)
      removeProc.signal(15)
    else
      root.finishRemove(1)
  }

  function clearLock() {
    root.requireAuth("unlock")
  }

  function finishRemove(exitCode) {
    if (root.cancelled) {
      root.status = "cancelled"
      root.error = "Cancelled"
    } else if (exitCode === 0) {
      root.status = "done"
      root.progress = 1
      root.selectNone()
      PackageManager.refreshInstalled()
      root.refresh()
    } else {
      root.status = "failed"
      root.error = root.lockedDb ? "Package database is locked" : "Exited with code " + exitCode
    }

    finishTimer.restart()
  }

  function appendLog(line) {
    const text = String(line).replace(/\r/g, "").replace(/\s+$/, "")

    if (text.length === 0)
      return

    const match = /(\d{1,3})%/.exec(text)

    if (match)
      root.progress = Math.min(1, Math.max(0, parseInt(match[1], 10) / 100))

    if (/unable to lock database/i.test(text))
      root.lockedDb = true

    const next = root.log.concat([text])
    root.log = next.length > 500 ? next.slice(next.length - 500) : next
  }

  function dismiss() {
    if (root.busy)
      return

    root.status = "idle"
    root.currentPackage = ""
    root.log = []
    root.error = ""
    root.progress = -1
    finishTimer.stop()
  }

  Timer {
    id: finishTimer
    interval: 8000
    repeat: false
    onTriggered: root.dismiss()
  }

  Process {
    id: infoProc
    running: false

    stdout: StdioCollector {
      onStreamFinished: root.onInfoFinished(this.text)
    }
  }

  Process {
    id: foreignProc
    running: false

    stdout: StdioCollector {
      onStreamFinished: root.onForeignFinished(this.text)
    }
  }

  Process {
    id: checkProc
    command: ["sudo", "-n", "-v"]
    running: false

    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: exitCode => root.onChecked(exitCode)
  }

  Process {
    id: sudoProc
    running: false
    stdinEnabled: true

    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onStarted: {
      write(root.password + "\n")
      root.password = ""
    }

    onExited: exitCode => root.onAuthenticated(exitCode)
  }

  Process {
    id: unlockProc
    running: false

    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: exitCode => {
      if (exitCode === 0)
        root.lockedDb = false
    }
  }

  Process {
    id: removeProc
    running: false

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: data => root.appendLog(data)
    }

    stderr: SplitParser {
      splitMarker: "\n"
      onRead: data => root.appendLog(data)
    }

    onExited: exitCode => root.finishRemove(exitCode)
  }
}
