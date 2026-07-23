// From voidarc's - Quickshell
// https://git.voidarc.co.uk/voidarc/quickshell

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
  id: root

  property BluetoothAdapter defaultAdapter: Bluetooth.defaultAdapter
  property string defaultAdapterName: Bluetooth.defaultAdapter.adapterId

  function getConnected() {
	let deviceList = getDevicesList();
	for (let device in deviceList) {
	  let currentDevice = deviceList[device];
	  if (currentDevice.connected == true) {
		return true;
	  }
	}
	return false;
  }

  function getDevicesList() {
	return root.defaultAdapter.devices.values;
  }

  function getIcon(name) {
	const icons = {
	  "audio-card": "󰓃",
	  "audio-input-microphone": "",
	  "audio-headphones": "󰋋",
	  "audio-headset": "󰋋",
	  "battery": "󰂀",
	  "camera-photo": "󰻛",
	  "computer": "",
	  "input-keyboard": "󰌌",
	  "input-mouse": "󰍽",
	  "input-gaming": "󰊴",
	  "phone": "󰏲"
	};

	return icons[name] || "󰾰";
  }

  function pairTrustConnect(device) {
	device.pair();
	device.trusted = true;
	device.connect();
  }

  function toggleDiscover() {
	if (defaultAdapter.discovering == true) {
	  defaultAdapter.discovering = false;
	} else {
	  defaultAdapter.discovering = true;
	  discoveringTimeout.running = true;
	}
  }

  Timer {
	id: discoveringTimeout

	interval: 15000
	repeat: false
	running: false

	onTriggered: defaultAdapter.discovering = false
  }
}

