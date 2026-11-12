import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../Services"
import "../"

ColumnLayout {
    id: root
    spacing: Variables.settingsControlGap
    implicitWidth: parent ? parent.width : 300
    implicitHeight: Variables.settingsConnectivityHeight

    property var selectedWifiNetwork: null
    property bool passwordRequired: false
    property bool wifiPasswordVisible: false

    Binding {
        target: ConnectivityService
        property: "wifiScanActive"
        value: root.visible
    }

    Component.onCompleted: {
        if (ConnectivityService.bluetoothEnabled)
            ConnectivityService.scanBluetooth()
    }

    onVisibleChanged: {
        if (visible) {
            if (ConnectivityService.bluetoothEnabled)
                ConnectivityService.scanBluetooth()
        } else {
            ConnectivityService.stopBluetoothScan()
        }
    }

    Connections {
        target: ConnectivityService
        function onWifiNeedsPassword(network) {
            root.selectedWifiNetwork = network
            root.passwordRequired = true
            wifiPassword.clear()
            Qt.callLater(() => wifiPassword.forceActiveFocus())
        }
    }

    ScriptModel {
        id: wifiModel
        values: {
            const dev = ConnectivityService.wifiDevice
            if (!dev) return []
            return dev.networks.values.slice().sort((a, b) => {
                if (a.connected !== b.connected) return a.connected ? -1 : 1
                return b.signalStrength - a.signalStrength
            })
        }
    }

    function selectWifi(network) {
        if (network.connected)
            return
        selectedWifiNetwork = network
        passwordRequired = false
        wifiPassword.clear()

        if (network.security === WifiSecurityType.Open || network.known) {
            ConnectivityService.connectWifi(network, "")
        } else if (ConnectivityService.supportsPsk(network)) {
            passwordRequired = true
            Qt.callLater(() => wifiPassword.forceActiveFocus())
        } else {
            ConnectivityService.showWifiStatus("Unsupported security: " + WifiSecurityType.toString(network.security))
        }
    }

    function activateSelectedWifi() {
        if (selectedWifiNetwork) {
            ConnectivityService.connectWifi(selectedWifiNetwork, wifiPassword.text)
            wifiPassword.clear()
            passwordRequired = false
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Variables.settingsPresetListRowHeight
        radius: Variables.settingsInputRadius
        color: Variables.uiColor
        border.color: Variables.borderColor
        border.width: Variables.borderWidth
        visible: ConnectivityService.hasEthernet

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Variables.settingsFieldHorizontalPadding
            anchors.rightMargin: Variables.settingsFieldHorizontalPadding
            spacing: Variables.settingsControlGap

            Text {
                text: "󰈀"
                font.pixelSize: Variables.fontSize * 0.9
                color: Variables.iconColor
            }

            Text {
                Layout.fillWidth: true
                text: "Ethernet Connected"
                font.pixelSize: Variables.fontSize * 0.75
                font.weight: Font.DemiBold
                color: Variables.textColor
            }
        }
    }

    SettingsToggle {
        Layout.fillWidth: true
        label: "Wi-Fi"
        description: ConnectivityService.wifiMessage
        checkedState: ConnectivityService.wifiEnabled
        onValueChanged: value => {
            ConnectivityService.setWifiEnabled(value)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: ConnectivityService.wifiEnabled

        Text {
            Layout.fillWidth: true
            text: "Available networks"
            font.pixelSize: Variables.fontSize * 0.7
            font.weight: Font.DemiBold
            color: Variables.textColor
        }

        Rectangle {
            id: wifiRefresh
            Layout.preferredWidth: Variables.settingsPresetFieldHeight
            Layout.preferredHeight: width
            radius: Variables.settingsInputRadius
            color: wifiRefreshMouse.containsMouse ? Variables.iconColor : Variables.uiColor
            border.color: wifiRefreshMouse.containsMouse ? Variables.buttonColor : Variables.borderColor
            border.width: Variables.borderWidth
            activeFocusOnTab: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    ConnectivityService.refreshWifiNetworks()
                    event.accepted = true
                }
            }

            Text {
                anchors.centerIn: parent
                text: "↻"
                font.pixelSize: Variables.fontSize * 0.9
                color: wifiRefreshMouse.containsMouse ? Variables.uiColor : Variables.textColor
            }

            MouseArea {
                id: wifiRefreshMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: ConnectivityService.refreshWifiNetworks()
            }
        }
    }

    ListView {
        id: wifiList
        Layout.fillWidth: true
        Layout.preferredHeight: 240
        clip: true
        spacing: Variables.settingsControlTextSpacing
        visible: ConnectivityService.wifiEnabled

        model: wifiModel

        delegate: Rectangle {
            id: wifiRow
            required property var modelData
            width: ListView.view.width
            height: Variables.settingsPresetListRowHeight
            radius: Variables.settingsInputRadius
            
            property bool isConnected: modelData.connected
            property string networkName: modelData.name || "Hidden Network"
            property bool isSecured: modelData.security !== WifiSecurityType.Open
            
            color: wifiMouse.containsMouse || isConnected ? Variables.iconColor : Variables.uiColor
            border.color: wifiMouse.containsMouse || isConnected ? Variables.buttonColor : Variables.borderColor
            border.width: Variables.borderWidth
            activeFocusOnTab: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.selectWifi(wifiRow.modelData)
                    event.accepted = true
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Variables.settingsFieldHorizontalPadding
                anchors.rightMargin: Variables.settingsFieldHorizontalPadding
                spacing: Variables.settingsControlGap

                Text {
                    text: ""
                    font.pixelSize: Variables.fontSize * 0.78
                    color: wifiMouse.containsMouse || wifiRow.isConnected ? Variables.uiColor : Variables.iconColor
                }

                Text {
                    Layout.fillWidth: true
                    text: wifiRow.networkName
                    font.pixelSize: Variables.fontSize * 0.68
                    font.weight: wifiRow.isConnected ? Font.DemiBold : Font.Normal
                    color: wifiMouse.containsMouse || wifiRow.isConnected ? Variables.uiColor : Variables.textColor
                    elide: Text.ElideRight
                }

                Text {
                    text: wifiRow.isSecured ? "" : ""
                    font.pixelSize: Variables.fontSize * 0.58
                    color: wifiMouse.containsMouse || wifiRow.isConnected ? Variables.uiColor : Variables.textColor
                    opacity: wifiRow.isSecured ? 1 : 0.42
                }

                Text {
                    text: wifiRow.isConnected ? "Connected" : (wifiRow.modelData.stateChanging ? "Connecting…" : Math.round(wifiRow.modelData.signalStrength * 100) + "%")
                    font.pixelSize: Variables.fontSize * 0.58
                    color: wifiMouse.containsMouse || wifiRow.isConnected ? Variables.uiColor : Variables.textColor
                }
            }

            MouseArea {
                id: wifiMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.selectWifi(wifiRow.modelData)
            }
        }

        Text {
            anchors.centerIn: parent
            visible: wifiList.count === 0
            text: !ConnectivityService.wifiEnabled ? "Turn on Wi-Fi to scan" : (ConnectivityService.wifiDevice ? "Scanning for networks…" : "No Wi-Fi adapter found")
            font.pixelSize: Variables.fontSize * 0.66
            color: Variables.textColor
            opacity: 0.7
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: ConnectivityService.wifiEnabled && root.passwordRequired && root.selectedWifiNetwork !== null

        TextField {
            id: wifiPassword
            Layout.fillWidth: true
            Layout.preferredHeight: Variables.settingsPresetFieldHeight
            placeholderText: root.selectedWifiNetwork ? "Password for " + root.selectedWifiNetwork.name : "Password"
            placeholderTextColor: Variables.textColor
            color: Variables.textColor
            echoMode: root.wifiPasswordVisible ? TextInput.Normal : TextInput.Password
            selectByMouse: true
            leftPadding: Variables.settingsFieldHorizontalPadding
            rightPadding: Variables.settingsFieldHorizontalPadding
            onAccepted: root.activateSelectedWifi()

            background: Rectangle {
                color: Variables.uiColor
                radius: Variables.settingsInputRadius
                border.color: wifiPassword.activeFocus ? Variables.iconColor : Variables.borderColor
                border.width: Variables.borderWidth
            }
        }
    }

    SettingsToggle {
        Layout.fillWidth: true
        label: "Bluetooth"
        description: ConnectivityService.bluetoothMessage
        checkedState: ConnectivityService.bluetoothEnabled
        onValueChanged: value => {
            ConnectivityService.setBluetoothEnabled(value)
            if (value) ConnectivityService.scanBluetooth()
        }
    }

    ListView {
        id: bluetoothList
        Layout.fillWidth: true
        Layout.preferredHeight: 280
        clip: true
        spacing: Variables.settingsControlTextSpacing
        
        model: ConnectivityService.btAdapter ? ConnectivityService.btAdapter.devices : null

        delegate: Rectangle {
            id: bluetoothRow
            required property var modelData
            width: ListView.view.width
            height: Variables.settingsPresetListRowHeight
            radius: Variables.settingsInputRadius
            
            color: bluetoothMouse.containsMouse || bluetoothRow.modelData.connected ? Variables.iconColor : Variables.uiColor
            border.color: bluetoothMouse.containsMouse || bluetoothRow.modelData.connected ? Variables.buttonColor : Variables.borderColor
            border.width: Variables.borderWidth
            activeFocusOnTab: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    if (bluetoothRow.modelData.paired)
                        ConnectivityService.toggleBluetoothDevice(bluetoothRow.modelData, bluetoothRow.modelData.connected)
                    else
                        ConnectivityService.pairBluetoothDevice(bluetoothRow.modelData)
                    event.accepted = true
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Variables.settingsFieldHorizontalPadding
                anchors.rightMargin: Variables.settingsFieldHorizontalPadding
                spacing: Variables.settingsControlGap

                Text {
                    text: ""
                    font.pixelSize: Variables.fontSize * 0.78
                    color: bluetoothMouse.containsMouse || bluetoothRow.modelData.connected ? Variables.uiColor : Variables.iconColor
                }

                Text {
                    Layout.fillWidth: true
                    text: bluetoothRow.modelData.name || bluetoothRow.modelData.address || "Unknown Device"
                    font.pixelSize: Variables.fontSize * 0.68
                    font.weight: bluetoothRow.modelData.connected ? Font.DemiBold : Font.Normal
                    color: bluetoothMouse.containsMouse || bluetoothRow.modelData.connected ? Variables.uiColor : Variables.textColor
                    elide: Text.ElideRight
                }

                Text {
                    text: bluetoothRow.modelData.connected ? "Connected"
                        : bluetoothRow.modelData.paired ? "Connect" : "Pair"
                    font.pixelSize: Variables.fontSize * 0.58
                    color: bluetoothMouse.containsMouse || bluetoothRow.modelData.connected ? Variables.uiColor : Variables.textColor
                }
            }

            MouseArea {
                id: bluetoothMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (bluetoothRow.modelData.paired)
                        ConnectivityService.toggleBluetoothDevice(bluetoothRow.modelData, bluetoothRow.modelData.connected)
                    else
                        ConnectivityService.pairBluetoothDevice(bluetoothRow.modelData)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: bluetoothList.count === 0
            text: ConnectivityService.bluetoothEnabled ? "No known devices" : "Turn on Bluetooth to view devices"
            font.pixelSize: Variables.fontSize * 0.66
            color: Variables.textColor
            opacity: 0.7
        }
    }
}