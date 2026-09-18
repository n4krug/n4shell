// Time.qml

// with this line our type becomes a Singleton
pragma Singleton
import QtQuick

import Quickshell
import Quickshell.Io

// your singletons should always have Singleton as the type
Singleton {
  id: root

  property string date: Qt.formatDate(new Date(), "dddd MMMM d yyyy")
  property string time: Qt.formatDateTime(new Date(), "hh:mm")

//   Process {
// 	id: timeProc

// 	command: ["date", "+%H:%M"]
// 	running: true

// 	stdout: StdioCollector {
// 	  onStreamFinished: root.time = this.text
// 	}
//   }

//   Process {
// 	id: dateProc

// 	command: ["date", "+%A %B %d %Y"]
// 	running: true

// 	stdout: StdioCollector {
// 	  onStreamFinished: root.date = this.text
// 	}
//   }

  Timer {
   	interval: 1000
    repeat: true
    running: true

    onTriggered: {
      root.date = Qt.formatDate(new Date(), "dddd MMMM d yyyy")
      root.time = Qt.formatDateTime(new Date(), "hh:mm")
 	  }
  }
}
