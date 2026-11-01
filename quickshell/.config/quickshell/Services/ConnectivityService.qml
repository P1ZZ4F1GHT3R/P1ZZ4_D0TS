pragma Singleton
import QtQuick
import Quickshell.Networking
import Quickshell.Bluetooth

Item {
    id: root

    // Emitted when a connect attempt failed because we need (or have the wrong) PSK.
    signal wifiNeedsPassword(var network)

    // ------------------------------------------------------------------
    // Devices
    //
    // Networking.devices is a Quickshell ObjectModel. It has NO count, get()
    // or length. The only way to read it as a list is .values, which is also
    // what makes these bindings re-evaluate when devices come and go.
    // (The old code probed .count/.get/.length, got undefined, looped zero
    // times, and silently returned null for every device.)
    // ------------------------------------------------------------------
    function firstDevice(type) {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === type)
                return devs[i]
        }
        return null
    }

    readonly property var wifiDevice: firstDevice(DeviceType.Wifi)

    // True if ANY wired device is connected
    readonly property bool hasEthernet: {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wired && devs[i].connected)
                return true
        }
        return false
    }

    // Remove these two once you trust it. They exist so the log tells you something.
    onWifiDeviceChanged: console.log("[Connectivity] wifi device:", wifiDevice ? wifiDevice.name : "none")
    onHasEthernetChanged: console.log("[Connectivity] ethernet connected:", hasEthernet)

    // ------------------------------------------------------------------
    // Wi-Fi
    // ------------------------------------------------------------------
    readonly property bool wifiEnabled: Networking.wifiEnabled

    // Set by the settings page while it is visible, so we don't scan forever.
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

    // Temporary message ("Connection failed" etc). Cleared by statusResetTimer.
    // wifiMessage is a pure binding on purpose: never assign to it directly,
    // that permanently destroys the binding.
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

    // ------------------------------------------------------------------
    // Bluetooth
    // ------------------------------------------------------------------
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

    // BluetoothDevice has connect()/disconnect(), not connectDevice()/disconnectDevice().
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
