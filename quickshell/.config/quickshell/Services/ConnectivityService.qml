pragma Singleton
import QtQuick
import Quickshell.Networking
import Quickshell.Bluetooth

Item {
    id: root

    signal wifiNeedsPassword(var network)

    function firstDevice(type) {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === type)
                return devs[i]
        }
        return null
    }

    readonly property var wifiDevice: firstDevice(DeviceType.Wifi)

    readonly property bool hasEthernet: {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wired && devs[i].connected)
                return true
        }
        return false
    }

    onWifiDeviceChanged: console.log("[Connectivity] wifi device:", wifiDevice ? wifiDevice.name : "none")
    onHasEthernetChanged: console.log("[Connectivity] ethernet connected:", hasEthernet)

    readonly property bool wifiEnabled: Networking.wifiEnabled
    property bool wifiScanActive: false

    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.wifiEnabled && root.wifiScanActive
        when: root.wifiDevice !== null
    }

    readonly property var connectedWifiNetwork: {
        const dev = wifiDevice
        if (!dev) return null
        const nets = dev.networks.values
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected)
                return nets[i]
        }
        return null
    }

    property var pendingNetwork: null
    readonly property bool wifiBusy: pendingNetwork !== null && pendingNetwork.stateChanging

    property string wifiStatusOverride: ""
    readonly property string wifiMessage: {
        if (wifiStatusOverride !== "") return wifiStatusOverride
        if (!wifiEnabled) return "Wi-Fi is off"
        if (!wifiDevice) return "No Wi-Fi adapter found"
        if (wifiBusy) return "Connecting…"
        if (connectedWifiNetwork) return "Connected to " + connectedWifiNetwork.name
        return "Wi-Fi is on"
    }

    Timer {
        id: statusResetTimer
        interval: 4000
        repeat: false
        onTriggered: root.wifiStatusOverride = ""
    }

    Connections {
        target: root.pendingNetwork
        ignoreUnknownSignals: true

        function onConnectionFailed(reason) {
            const net = root.pendingNetwork
            root.pendingNetwork = null
            if (reason === ConnectionFailReason.NoSecrets) {
                root.showWifiStatus("Password required or incorrect")
                root.wifiNeedsPassword(net)
            } else {
                root.showWifiStatus("Connection failed")
            }
        }

        function onConnectedChanged() {
            if (root.pendingNetwork && root.pendingNetwork.connected)
                root.pendingNetwork = null
        }
    }

    function showWifiStatus(text) {
        wifiStatusOverride = text
        statusResetTimer.restart()
    }

    function supportsPsk(network) {
        const s = network.security
        return s === WifiSecurityType.WpaPsk
            || s === WifiSecurityType.Wpa2Psk
            || s === WifiSecurityType.Sae
    }

    function refreshWifiNetworks() {
        const dev = wifiDevice
        if (!dev || !wifiEnabled) return
        dev.scannerEnabled = false
        Qt.callLater(() => {
            if (root.wifiDevice)
                root.wifiDevice.scannerEnabled = root.wifiEnabled && root.wifiScanActive
        })
    }

    function setWifiEnabled(enabled) {
        Networking.wifiEnabled = enabled
    }

    function connectWifi(network, password) {
        if (!network) return
        wifiStatusOverride = ""
        pendingNetwork = network
        if (password && password.length > 0)
            network.connectWithPsk(password)
        else
            network.connect()
    }

    property var btAdapter: Bluetooth.defaultAdapter
    property bool bluetoothEnabled: btAdapter ? btAdapter.enabled : false
    property bool bluetoothBusy: false

    property string bluetoothStatusOverride: ""
    readonly property string bluetoothMessage: {
        if (bluetoothStatusOverride !== "") return bluetoothStatusOverride
        if (!btAdapter) return "No Bluetooth adapter found"
        if (!bluetoothEnabled) return "Bluetooth is off"
        if (btAdapter.discovering) return "Scanning for Bluetooth devices…"
        return "Bluetooth is on"
    }

    Timer {
        id: btScanDelay
        interval: 500
        repeat: false
        onTriggered: {
            if (root.btAdapter && root.btAdapter.enabled)
                root.btAdapter.discovering = true
        }
    }

    Timer {
        id: btToggleDelay
        interval: 600
        repeat: false
        onTriggered: {
            root.bluetoothBusy = false
            root.bluetoothStatusOverride = ""
            if (root.bluetoothEnabled)
                root.scanBluetooth()
        }
    }

    function setBluetoothEnabled(enabled) {
        if (!btAdapter) return
        bluetoothBusy = true
        bluetoothStatusOverride = enabled ? "Turning Bluetooth on…" : "Turning Bluetooth off…"
        btAdapter.enabled = enabled
        btToggleDelay.restart()
    }

    function scanBluetooth() {
        if (btAdapter && !bluetoothBusy)
            btScanDelay.restart()
    }

    function stopBluetoothScan() {
        btScanDelay.stop()
        if (btAdapter && btAdapter.discovering)
            btAdapter.discovering = false
    }

    function toggleBluetoothDevice(device, isConnected) {
        if (!device) return
        if (isConnected) device.disconnect()
        else device.connect()
    }

    function pairBluetoothDevice(device) {
        if (!device) return
        device.pair()
    }
}
