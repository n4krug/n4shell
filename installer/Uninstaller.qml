import QtQuick

import "../services"

PackagePanel {
  id: root

  objectName: "uninstaller"
  shortcutName: "uninstaller"

  title: "Uninstall"
  manager: UninstallManager

  filterPlaceholder: "Filter installed..."
  hint: "enter toggle · ctrl+enter uninstall · esc hide"
  commitVerb: "uninstall"

  checkable: true
  clientFilter: true
  refreshOnOpen: true
  showMeta: true

  chips: [
    { key: "pkg", label: "Pkg" },
    { key: "deps", label: "+Deps" },
    { key: "purge", label: "Purge" }
  ]
  activeChip: UninstallManager.mode

  statusText: UninstallManager.refreshing
    ? "loading..."
    : UninstallManager.selectedCount + " / " + UninstallManager.pendingCount + " selected"

  onChipTapped: key => UninstallManager.mode = key
}
