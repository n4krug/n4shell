import QtQuick

import "../services"

PackagePanel {
  id: root

  objectName: "installer"
  shortcutName: "installer"

  title: "Install"
  manager: PackageManager

  filterPlaceholder: "Search packages..."
  hint: "enter toggle · ctrl+enter install · esc hide"
  commitVerb: "install"

  checkable: true
  clientFilter: false
  refreshOnOpen: false
  showMeta: true

  chips: [
    { key: "all", label: "All" },
    { key: "repo", label: "Repo" },
    { key: "aur", label: "AUR" }
  ]
  activeChip: PackageManager.source

  linkTo: "updater"
  linkIcon: "upgrade"

  statusText: PackageManager.searching
    ? "searching..."
    : PackageManager.results.length + " results"

  onChipTapped: key => PackageManager.source = key
}
