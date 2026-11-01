import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

ColumnLayout {
    id: root
    spacing: Variables.settingsControlGap

    property bool activating: false
    property bool confirmDeactivation: false
    property bool licenseError: false
    property string licenseKey: ""
    property int activationStep: 0
    property var activationLogs: []
    readonly property int activationLogLimit: 12
    
    readonly property var activationSteps: [
        "Validating cryptographic licence key…",
        "Negotiating connection with attestation servers…",
        "Verifying hardware root-of-trust and TPM state…",
        "Applying updated DRM display policies…"
    ]

    function randomActivationDelay() {
        return 1000 + Math.floor(Math.random() * 2201)
    }

    function randomLogDelay() {
        return 350 + Math.floor(Math.random() * 451)
    }

    function getSyslogTimestamp() {
        const d = new Date()
        const m = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        const pad = (n) => ("0" + n).slice(-2)
        return m[d.getMonth()] + " " + pad(d.getDate()) + " " + pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
    }

    function randomActivationLog() {
        const messages = [
            "actd[412]: Validating hardware UUID against DMI tables...",
            "actd[412]: TPM 2.0 PCR7 state matches expected Secure Boot policy",
            "kernel: tpm_crb MSFT0101:00: [Firmware Bug]: ACPI region does not cover the entire buffer",
            "actd[412]: Initiating TLS 1.3 handshake with attestation.kernel.org:443",
            "actd[412]: Handshake complete. Cipher: TLS_AES_256_GCM_SHA384",
            "actd[412]: Transmitting cryptographic attestation payload (2048 bytes)...",
            "kernel: [drm] Updating display DRM policy (0x0 -> 0x1)",
            "actd[412]: Server challenge received, computing ECDH response...",
            "actd[412]: Signature verified against trusted Root CA",
            "actd[412]: Provisioning offline activation token to /sys/firmware/efi/efivars/",
            "dbus-daemon[390]: [system] Activating service name='org.freedesktop.LicenseManager'",
            "dbus-daemon[390]: [system] Successfully activated service 'org.freedesktop.LicenseManager'",
            "systemd[1]: Reloading system manager configuration...",
            "audit[412]: USER_AUTH pid=412 uid=0 auid=4294967295 ses=4294967295 msg='op=license_verify'",
            "actd[412]: Hardware fingerprint match: 99.4% (acceptable threshold >= 95%)"
        ]
        return getSyslogTimestamp() + " localhost " + messages[Math.floor(Math.random() * messages.length)]
    }

    function addActivationLog(message) {
        const entries = activationLogs.slice()
        entries.push(message)
        activationLogs = entries.slice(-activationLogLimit)
        Qt.callLater(() => activationLogView.positionViewAtEnd())
    }

    function hasValidLicenceKey() {
        return /^[A-Za-z0-9]{5}(-[A-Za-z0-9]{5}){4}$/.test(licenseKey.trim())
    }

    function formatLicenceKey(value) {
        const compact = String(value).replace(/[^A-Za-z0-9]/g, "").slice(0, 25)
        return compact.replace(/(.{5})(?=.)/g, "$1-")
    }

    function beginActivation() {
        if (!hasValidLicenceKey()) {
            licenseError = true
            return
        }

        licenseError = false
        confirmDeactivation = false
        activating = true
        activationStep = 0
        activationLogs = []
        addActivationLog(getSyslogTimestamp() + " localhost systemd[1]: Starting Linux Hardware Attestation Daemon...")
        activationTimer.interval = randomActivationDelay()
        activationTimer.start()
        activationLogTimer.interval = randomLogDelay()
        activationLogTimer.start()
    }

    function deactivate() {
        activationTimer.stop()
        activating = false
        activationStep = 0
        confirmDeactivation = false
        activationLogTimer.stop()
        activationLogs = [getSyslogTimestamp() + " localhost systemd[1]: linux-activation.service: Deactivated successfully."]
        Variables.activateLinux = true
    }

    Timer {
        id: activationTimer
        interval: 800
        repeat: true
        onTriggered: {
            activationStep += 1
            if (activationStep >= activationSteps.length) {
                stop()
                activationLogTimer.stop()
                activating = false
                root.addActivationLog(root.getSyslogTimestamp() + " localhost actd[412]: Activation successful. DRM watermark revoked.")
                Variables.activateLinux = false
                root.licenseKey = ""
                licenceField.clear()
            } else {
                root.addActivationLog(root.randomActivationLog())
                interval = root.randomActivationDelay()
            }
        }
    }

    Timer {
        id: activationLogTimer
        interval: 500
        repeat: true
        onTriggered: {
            root.addActivationLog(root.randomActivationLog())
            interval = root.randomLogDelay()
        }
    }

    Text {
        Layout.fillWidth: true
        text: !Variables.activateLinux ? "Linux is activated" : "Activate Linux"
        font.pixelSize: Variables.fontSize * 1.05
        font.weight: Font.DemiBold
        color: Variables.textColor
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        Layout.fillWidth: true
        text: activating ? activationSteps[Math.min(activationStep, activationSteps.length - 1)]
            : confirmDeactivation
                ? "Warning: this will restore the Activate Linux watermark."
                : !Variables.activateLinux
                ? "Your copy of Linux is genuine."
                : "Activate Linux to remove this completely necessary warning."
        font.pixelSize: Variables.fontSize * 0.7
        color: Variables.textColor
        opacity: 0.8
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    TextField {
        id: licenceField
        Layout.fillWidth: true
        Layout.preferredHeight: Variables.settingsFieldHeight
        visible: Variables.activateLinux && !root.activating && !root.confirmDeactivation
        text: root.licenseKey
        placeholderText: "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
        placeholderTextColor: Variables.textColor
        selectByMouse: true
        color: Variables.textColor
        font.pixelSize: Variables.fontSize * 0.72
        horizontalAlignment: TextInput.AlignHCenter
        leftPadding: Variables.settingsFieldHorizontalPadding
        rightPadding: Variables.settingsFieldHorizontalPadding
        onTextEdited: {
            const formatted = root.formatLicenceKey(text)
            if (text !== formatted) {
                text = formatted
                cursorPosition = text.length
            }
            root.licenseKey = formatted
            root.licenseError = false
        }
        onAccepted: root.beginActivation()

        background: Rectangle {
            color: Variables.uiColor
            radius: Variables.settingsInputRadius
            border.color: root.licenseError ? Variables.buttonColor
                : licenceField.activeFocus ? Variables.iconColor : Variables.borderColor
            border.width: Variables.borderWidth
        }

        SettingsToolTip {
            visible: licenceField.hovered && !licenceField.activeFocus
            text: "Enter a completely legitimate five-part licence key to activate Linux."
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.licenseError
        text: "That key is not legitimate enough. Use five groups of five letters or digits."
        color: Variables.buttonColor
        font.pixelSize: Variables.fontSize * 0.62
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.minimumHeight: Variables.settingsFieldHeight * 3
        Layout.fillHeight: true
        visible: root.activating || root.activationLogs.length > 0
        color: Variables.uiColor
        radius: Variables.barRadius
        border.color: root.activating ? Variables.buttonColor : Variables.borderColor
        border.width: Variables.borderWidth
        clip: true

        ListView {
            id: activationLogView
            anchors.fill: parent
            anchors.margins: Variables.settingsControlTextSpacing + 1
            clip: true
            spacing: 1
            model: root.activationLogs

            header: Rectangle {
                width: activationLogView.width
                height: Variables.settingsFieldHeight * 0.6
                color: root.activating ? Variables.buttonColor : Variables.uiColor

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Variables.settingsControlGap
                    
                    text: root.activating ? "● linux-activation.service - Activating" : "○ linux-activation.service - Inactive"
                    
                    color: root.activating ? Variables.uiColor : Variables.textColor
                    font.family: "monospace"
                    font.pixelSize: Variables.fontSize * 0.58
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }
            }

            delegate: Text {
                required property var modelData
                width: ListView.view.width
                text: modelData
                color: Variables.textColor
                opacity: 0.76
                font.family: "monospace"
                font.pixelSize: Variables.fontSize * 0.58
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Variables.settingsActivationProgressHeight
        radius: height / 2
        color: Variables.uiColor
        border.color: Variables.borderColor
        border.width: 1

        Rectangle {
            width: parent.width * (activating
                ? (root.activationStep + 1) / root.activationSteps.length
                : !Variables.activateLinux ? 1 : 0)
            height: parent.height
            radius: parent.radius
            color: Variables.buttonColor

            Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        }
    }

    Rectangle {
        id: activationButton
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Variables.settingsActivationButtonWidth
        Layout.preferredHeight: Variables.settingsActivationButtonHeight
        radius: Variables.barRadius
        color: activationMouse.containsMouse ? Variables.iconColor : Variables.uiColor
        border.color: activationMouse.containsMouse ? Variables.buttonColor : Variables.borderColor
        border.width: Variables.borderWidth
        activeFocusOnTab: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (!Variables.activateLinux) {
                    if (root.confirmDeactivation)
                        root.deactivate()
                    else
                        root.confirmDeactivation = true
                } else if (!root.activating)
                    root.beginActivation()
                event.accepted = true
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.activating ? "Activating…"
                : !Variables.activateLinux ? root.confirmDeactivation ? "Confirm deactivation" : "Deactivate Linux"
                : "Activate Linux"
            font.pixelSize: Variables.fontSize * 0.75
            font.weight: Font.DemiBold
            color: activationMouse.containsMouse ? Variables.uiColor : Variables.textColor
        }

        MouseArea {
            id: activationMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (!Variables.activateLinux) {
                    if (root.confirmDeactivation)
                        root.deactivate()
                    else
                        root.confirmDeactivation = true
                } else if (!root.activating)
                    root.beginActivation()
                activationButton.forceActiveFocus()
            }
        }

        SettingsToolTip {
            visible: activationMouse.containsMouse
            text: Variables.activateLinux
                ? "Enter a valid-looking licence key, then begin activation."
                : root.confirmDeactivation
                    ? "Confirm to bring the Activate Linux watermark back."
                    : "Deactivate Linux and restore the Activate Linux watermark."
        }
    }
}
