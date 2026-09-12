pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
  id: root

  property alias server: server
  // Expose the model directly for use in Repeaters
  property alias notifications: server.trackedNotifications

  // Convenience getter for the latest notification
  readonly property var latest: {
    const vals = server.trackedNotifications.values;
    return vals.length > 0 ? vals[vals.length - 1] : null;
  }

  NotificationServer {
    id: server

    actionsSupported: true
    bodyMarkupSupported: true
    bodySupported: true

    onNotification: notification => {
      notification.tracked = true;
    }
  }
}