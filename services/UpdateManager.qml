pragma Singleton
import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property var pending: []
  property var pendingNames: []
  property bool refreshing: false

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

  readonly property bool busy: root.status === "checking" || root.status === "auth" || root.status === "updating"
  readonly property bool needsPassword: root.status === "auth"
  readonly property bool active: root.busy || finishTimer.running
  readonly property string lastLogLine: root.log.length > 0 ? root.log[root.log.length - 1] : ""
  readonly property int pendingCount: root.pending.length
  readonly property int selectedCount: root.pending.filter(entry => root.selected[entry.name] === true).length

  property int updateCount: 0
  readonly property int updateThreshold: 10

  readonly property string statusLabel: {
    switch (root.status) {
      case "checking": return "Checking permissions"
      case "auth": return "Password required"
      case "updating": return "Updating"
      case "done": return "Updated"
      case "failed": return "Failed"
      case "cancelled": return "Cancelled"
      default: return ""
    }
  }

  property var repoPending: []
  property var aurPending: []
  property bool repoDone: true
  property bool aurDone: true
  property int generation: 0
  property int repoGen: -1
  property int aurGen: -1

  function refresh() {
    if (root.busy)
      return

    root.generation++
    root.refreshing = true
    root.repoPending = []
    root.aurPending = []
    root.repoDone = false
    root.aurDone = false
    root.repoGen = root.generation
    root.aurGen = root.generation

    repoProc.running = false
    repoProc.command = ["checkupdates", "--nocolor"]
    repoProc.running = true

    aurProc.running = false
    aurProc.command = ["yay", "-Qua"]
    aurProc.running = true
  }

  function onRepoFinished(text) {
    if (root.repoGen !== root.generation)
      return

    root.repoPending = root.parsePending(text, "repo")
    root.repoDone = true
    root.merge()
  }

  function onAurFinished(text) {
    if (root.aurGen !== root.generation)
      return

    root.aurPending = root.parsePending(text, "aur")
    root.aurDone = true
    root.merge()
  }

  function parsePending(text, source) {
    const out = []

    String(text).split("\n").forEach(line => {
      const trimmed = line.trim()

      if (trimmed.length === 0)
        return

      const match = /^(\S+)\s+(\S+)\s*->\s*(\S+)/.exec(trimmed)

      if (!match)
        return

      out.push({
        name: match[1],
        from: match[2],
        to: match[3],
        source: source
      })
    })

    return out
  }

  function merge() {
    if (!root.repoDone || !root.aurDone)
      return

    const byName = ({})

    root.repoPending.forEach(entry => {
      byName[entry.name] = entry
    })

    root.aurPending.forEach(entry => {
      if (!byName[entry.name])
        byName[entry.name] = entry
    })

    const list = Object.keys(byName).map(key => byName[key])

    list.sort((a, b) => a.name.localeCompare(b.name))

    root.pending = list

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

    root.pending.forEach(entry => {
      next[entry.name] = true
    })

    root.selected = next
  }

  function selectNone() {
    root.selected = ({})
  }

  function selectedNames() {
    return root.pending.filter(entry => root.isSelected(entry.name)).map(entry => entry.name)
  }

  function hasAurSelected() {
    return root.pending.some(entry => entry.source === "aur" && root.isSelected(entry.name))
  }

  function updateSelected() {
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
    root.requireAuth("update")
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

    root.beginUpdate()
  }

  function beginUpdate() {
    const command = root.updateCommand()

    root.status = "updating"
    root.appendLog("$ " + command.join(" "))
    updateProc.running = false
    updateProc.command = command
    updateProc.running = true
  }

  function updateCommand() {
    const names = root.pendingNames

    if (root.hasAurSelected())
      return ["yay", "-Sy", "--noconfirm", "--sudoloop"].concat(names)

    return ["sudo", "-n", "pacman", "-Sy", "--noconfirm"].concat(names)
  }

  function cancel() {
    if (!root.busy)
      return

    root.cancelled = true

    if (updateProc.running)
      updateProc.signal(15)
    else
      root.finishUpdate(1)
  }

  function clearLock() {
    root.requireAuth("unlock")
  }

  function finishUpdate(exitCode) {
    if (root.cancelled) {
      root.status = "cancelled"
      root.error = "Cancelled"
    } else if (exitCode === 0) {
      root.status = "done"
      root.progress = 1
      PackageManager.refreshInstalled()
      root.refresh()
    } else {
      root.status = "failed"
      root.error = root.lockedDb ? "Package database is locked" : "Exited with code " + exitCode
    }

    finishTimer.restart()
    UpdateManager.refreshCount()
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

  readonly property bool updatesAvailable: updateCount > updateThreshold

  function refreshCount() {
    if (countProc.running) return
    countProc.running = false
    countProc.running = true
  }

  Timer {
    id: finishTimer
    interval: 8000
    repeat: false
    onTriggered: root.dismiss()
  }

  Timer {
    id: countTimer
    interval: 15*60*1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refreshCount()
  }

  Process {
    id: countProc
    command: ["checkupdates", "--nocolor"]
    running: false
    stdout: StdioCollector { id: countOut }
    stderr: StdioCollector {}
    onExited: exitCode => {
      if(exitCode === 0)
        root.updateCount = root.parsePending(countOut.text, "repo").length
    }
  }

  Process {
    id: repoProc
    running: false

    stdout: StdioCollector {
      onStreamFinished: root.onRepoFinished(this.text)
    }
  }

  Process {
    id: aurProc
    running: false

    stdout: StdioCollector {
      onStreamFinished: root.onAurFinished(this.text)
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
    id: updateProc
    running: false

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: data => root.appendLog(data)
    }

    stderr: SplitParser {
      splitMarker: "\n"
      onRead: data => root.appendLog(data)
    }

    onExited: exitCode => root.finishUpdate(exitCode)
  }
}
