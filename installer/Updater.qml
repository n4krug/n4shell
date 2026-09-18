import QtQuick

import "../services"

PackagePanel {
  id: root

  objectName: "updater"
  shortcutName: "updater"

  title: "Update"
  manager: UpdateManager

  filterPlaceholder: "Filter updates..."
  hint: "enter toggle · ctrl+enter update · esc hide"
  commitVerb: "update"

  checkable: true
  clientFilter: true
  refreshOnOpen: true
  showMeta: false

  chips: [
    { key: "all", label: "All" },
    { key: "none", label: "None" }
  ]

  statusText: UpdateManager.refreshing
    ? "checking..."
    : UpdateManager.selectedCount + " / " + UpdateManager.pendingCount + " selected"

  onChipTapped: key => {
    if (key === "all")
      UpdateManager.selectAll()
    else
      UpdateManager.selectNone()
  }
}
