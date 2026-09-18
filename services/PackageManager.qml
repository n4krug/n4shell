pragma Singleton
import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property int minQueryLength: 2
  readonly property int maxResults: 200

  property string query: ""
  property string source: "all"
  property var results: []
  property bool searching: false

  property string status: "idle"
  property string currentPackage: ""
  property string currentSource: "repo"
  property var pendingNames: []
  property var log: []
  property real progress: -1
  property string error: ""
  property bool lockedDb: false
  property string pendingAction: ""
  property bool cancelled: false

  property string password: ""

  property var selected: ({})

  readonly property var entries: root.results
  readonly property bool busy: root.status === "checking" || root.status === "auth" || root.status === "installing"
  readonly property bool needsPassword: root.status === "auth"
  readonly property bool active: root.busy || finishTimer.running
  readonly property string lastLogLine: root.log.length > 0 ? root.log[root.log.length - 1] : ""
  readonly property int selectedCount: root.results.filter(entry => root.selected[entry.name] === true).length

  readonly property string statusLabel: {
    switch (root.status) {
      case "checking": return "Checking permissions"
      case "auth": return "Password required"
      case "installing": return "Installing"
      case "done": return "Installed"
      case "failed": return "Failed"
      case "cancelled": return "Cancelled"
      default: return ""
    }
  }

  property var installedMap: ({})
  property var repoResults: []
  property var aurResults: []
  property bool repoDone: true
  property bool aurDone: true
  property int generation: 0
  property int repoGen: -1
  property int aurGen: -1

  onQueryChanged: root.search()
  onSourceChanged: root.search()

  function search() {
    debounce.restart()
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

    root.results.forEach(entry => {
      next[entry.name] = true
    })

    root.selected = next
  }

  function selectNone() {
    root.selected = ({})
  }

  function selectedNames() {
    return root.results.filter(entry => root.isSelected(entry.name)).map(entry => entry.name)
  }

  function hasAurSelected() {
    return root.results.some(entry => entry.source === "aur" && root.isSelected(entry.name))
  }

  function isInstalled(name) {
    return root.installedMap[name] === true
  }

  function refreshInstalled() {
    installedProc.running = true
  }

  function runSearch() {
    const q = root.query.trim()

    if (q.length < root.minQueryLength) {
      root.results = []
      root.searching = false
      return
    }

    root.generation++
    root.searching = true
    root.repoResults = []
    root.aurResults = []
    root.repoDone = root.source === "aur"
    root.aurDone = root.source === "repo"

    if (!root.repoDone) {
      root.repoGen = root.generation
      repoProc.running = false
      repoProc.command = ["pacman", "-Ss", q]
      repoProc.running = true
    }

    if (!root.aurDone) {
      root.aurGen = root.generation
      aurProc.running = false
      aurProc.command = ["curl", "-s", "--max-time", "10", "https://aur.archlinux.org/rpc/v5/search/" + encodeURIComponent(q) + "?by=name-desc"]
      aurProc.running = true
    }

    if (root.repoDone && root.aurDone)
      root.merge()
  }

  function onRepoFinished(text) {
    if (root.repoGen !== root.generation)
      return

    root.repoResults = root.parseRepo(text)
    root.repoDone = true
    root.merge()
  }

  function onAurFinished(text) {
    if (root.aurGen !== root.generation)
      return

    root.aurResults = root.parseAur(text)
    root.aurDone = true
    root.merge()
  }

  function parseRepo(text) {
    const out = []
    const lines = String(text).split("\n")
    let pending = null

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i]

      if (line.length === 0)
        continue

      if (line[0] === " ") {
        if (pending) {
          pending.description = line.trim()
          out.push(pending)
          pending = null
        }
        continue
      }

      const match = /^([^\s/]+)\/(\S+)\s+(\S+)(?:\s+\[installed[^\]]*\])?/.exec(line)

      if (!match) {
        if (pending)
          out.push(pending)
        pending = null
        continue
      }

      if (pending)
        out.push(pending)

      pending = {
        name: match[2],
        repo: match[1],
        version: match[3],
        installed: /\[installed[^\]]*\]/.test(line) || root.isInstalled(match[2]),
        description: "",
        source: "repo",
        votes: 0,
        popularity: 0,
        outOfDate: false
      }
    }

    if (pending)
      out.push(pending)

    return out
  }

  function parseAur(text) {
    let parsed = null

    try {
      parsed = JSON.parse(String(text))
    } catch (e) {
      parsed = null
    }

    if (!parsed || !parsed.results)
      return []

    return parsed.results.map(entry => ({
      name: entry.Name || "",
      repo: "aur",
      version: entry.Version || "",
      installed: root.isInstalled(entry.Name),
      description: entry.Description || "",
      source: "aur",
      votes: entry.NumVotes || 0,
      popularity: entry.Popularity || 0,
      outOfDate: entry.OutOfDate !== null && entry.OutOfDate !== undefined
    })).filter(entry => entry.name.length > 0)
  }

  function merge() {
    if (!root.repoDone || !root.aurDone)
      return

    const q = root.query.trim().toLowerCase()
    const byName = ({})

    root.repoResults.forEach(entry => {
      byName[entry.name] = entry
    })

    root.aurResults.forEach(entry => {
      if (!byName[entry.name])
        byName[entry.name] = entry
    })

    const list = Object.keys(byName).map(key => byName[key])

    const rank = entry => {
      const name = entry.name.toLowerCase()

      if (name === q)
        return 0
      if (name.startsWith(q))
        return 1
      if (name.includes(q))
        return 2
      if (entry.description && entry.description.toLowerCase().includes(q))
        return 3

      return 4
    }

    list.sort((a, b) => {
      const ra = rank(a)
      const rb = rank(b)

      if (ra !== rb)
        return ra - rb

      if (a.source === "aur" && b.source === "aur" && a.votes !== b.votes)
        return b.votes - a.votes

      return a.name.localeCompare(b.name)
    })

    root.results = list.slice(0, root.maxResults)

    const next = ({})

    root.results.forEach(entry => {
      next[entry.name] = root.selected[entry.name] === true
    })

    root.selected = next
    root.searching = false
  }

  function commitSelected() {
    if (root.busy)
      return

    const names = root.selectedNames()

    if (names.length === 0)
      return

    root.startInstall(names, root.hasAurSelected() ? "aur" : "repo")
  }

  function install(entry) {
    if (!entry || !entry.name || root.busy)
      return

    root.startInstall([entry.name], entry.source === "aur" ? "aur" : "repo")
  }

  function startInstall(names, source) {
    root.pendingNames = names
    root.currentSource = source
    root.currentPackage = names.length === 1 ? names[0] : names.length + " packages"
    root.log = []
    root.progress = -1
    root.error = ""
    root.lockedDb = false
    root.cancelled = false
    root.requireAuth("install")
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

    root.beginInstall()
  }

  function beginInstall() {
    root.status = "installing"
    root.appendLog("$ " + root.installCommand().join(" "))
    installProc.running = false
    installProc.command = root.installCommand()
    installProc.running = true
  }

  function installCommand() {
    if (root.currentSource === "aur")
      return ["yay", "-S", "--noconfirm", "--sudoloop"].concat(root.pendingNames)

    return ["sudo", "-n", "pacman", "-Sy", "--noconfirm"].concat(root.pendingNames)
  }

  function cancel() {
    if (!root.busy)
      return

    root.cancelled = true

    if (installProc.running)
      installProc.signal(15)
    else
      root.finishInstall(1)
  }

  function clearLock() {
    root.requireAuth("unlock")
  }

  function finishInstall(exitCode) {
    if (root.cancelled) {
      root.status = "cancelled"
      root.error = "Cancelled"
    } else if (exitCode === 0) {
      root.status = "done"
      root.progress = 1
      root.selectNone()
      root.refreshInstalled()
      root.runSearch()
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
    id: debounce
    interval: 300
    repeat: false
    onTriggered: root.runSearch()
  }

  Timer {
    id: finishTimer
    interval: 8000
    repeat: false
    onTriggered: root.dismiss()
  }

  Process {
    id: installedProc
    command: ["pacman", "-Qq"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const map = ({})

        String(this.text).split("\n").forEach(line => {
          const name = line.trim()

          if (name)
            map[name] = true
        })

        root.installedMap = map
      }
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
    id: installProc
    running: false

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: data => root.appendLog(data)
    }

    stderr: SplitParser {
      splitMarker: "\n"
      onRead: data => root.appendLog(data)
    }

    onExited: exitCode => root.finishInstall(exitCode)
  }
}
