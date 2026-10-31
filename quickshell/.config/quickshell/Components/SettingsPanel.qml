import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../Common"
import "../"

PanelWindow {
    id: settingsPanel
    visible: false
    implicitWidth: Variables.settingsWidth
    implicitHeight: Variables.settingsHeight
    color: "transparent"
    
    // Ensure the window sits on top and accepts text input
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // --- 1. IPC Handler for CLI commands ---
    IpcHandler {
        target: "settings"

        function toggle(): void {
            settingsPanel.visible = !settingsPanel.visible;
        }
        function open(): void {
            settingsPanel.visible = true;
        }
        function close(): void {
            settingsPanel.visible = false;
        }
    }

    // --- 2. Tab Categorized Settings Models ---
    property var categories: [
        { name: "General", icon: "⚙️" },
        { name: "Media & Notifs", icon: "🎵" },
        { name: "System", icon: "🖥️" },
        { name: "Appearance", icon: "🎨" }
    ]

    property var generalSettings: [
        { key: "hoverEnabled", label: "Enable Hover Focus", type: "toggle" },
        { key: "lockOnStart", label: "Lock Session on Startup", type: "toggle" },
        { key: "workspaceCount", label: "Active Workspaces", type: "slider", min: 1, max: 10 },
        { key: "activateLinux", label: "Activate Linux Watermark", type: "toggle" },
        { key: "activePasswordPreset", label: "Password Preset", type: "input" }
    ]

    property var mediaSettings: [
        { key: "lockScreenMpris", label: "Lockscreen MPRIS Widget", type: "toggle" },
        { key: "enableLyrics", label: "Enable Lyrics Display", type: "toggle" },
        { key: "wallpaperPreviewEnabled", label: "Wallpaper Live Preview", type: "toggle" },
        { key: "disablePopups", label: "Disable Toast Popups", type: "toggle" }
    ]

    property var systemSettings: [
        { key: "idleMonitor", label: "Idle Monitor Daemon", type: "toggle" },
        { key: "idleLockTime", label: "Idle Lock Timeout (s)", type: "slider", min: 60, max: 1800 },
        { key: "idleSleepTime", label: "Idle Sleep Timeout (s)", type: "slider", min: 120, max: 3600 },
        { key: "hoverTimer", label: "Hover Delay (ms)", type: "slider", min: 10, max: 1000 },
        { key: "notifTimer", label: "Notification Timeout (ms)", type: "slider", min: 1000, max: 10000 }
    ]

    property var appearanceSettings: [
        { key: "uiColor", label: "UI Primary Background", type: "input" },
        { key: "textColor", label: "Primary Text Color", type: "input" },
        { key: "iconColor", label: "Accent / Icon Color", type: "input" },
        { key: "borderColor", label: "Container Border Color", type: "input" },
        { key: "buttonColor", label: "Button Background Color", type: "input" },
        { key: "backgroundColorUI", label: "Card / UI Secondary", type: "input" }
    ]

    // Helper to safely extract color/string settings
    function getSettingValue(key) {
        let val = Variables[key];
        return (val !== undefined && val !== null) ? val.toString() : "";
    }

    // --- 3. Reusable Delegate Components ---
    Component {
        id: toggleComp
        SettingsToggle {
            label: loader.rowData ? loader.rowData.label : ""
            checkedState: loader.rowData ? Boolean(Variables[loader.rowData.key]) : false
            onValueChanged: (newValue) => {
                if (loader.rowData) Variables[loader.rowData.key] = newValue;
            }
        }
    }

    Component {
        id: sliderComp
        SettingsSlider {
            label: loader.rowData ? loader.rowData.label : ""
            fromValue: loader.rowData && loader.rowData.min !== undefined ? loader.rowData.min : 0
            toValue: loader.rowData && loader.rowData.max !== undefined ? loader.rowData.max : 100
            sliderValue: loader.rowData ? Number(Variables[loader.rowData.key]) : 0
            onValueChanged: (newValue) => {
                if (loader.rowData) Variables[loader.rowData.key] = newValue;
            }
        }
    }

    Component {
        id: inputComp
        SettingsInput {
            label: loader.rowData ? loader.rowData.label : ""
            textValue: loader.rowData ? getSettingValue(loader.rowData.key) : ""
            onValueChanged: (newValue) => {
                if (loader.rowData) Variables[loader.rowData.key] = newValue;
            }
        }
    }

    // Ambxst / Tide-Island style item card delegate
    Component {
        id: itemDelegate
        Rectangle {
            id: delegateRoot
            required property var modelData
            required property int index

            width: ListView.view ? ListView.view.width : parent.width
            implicitHeight: cardContainer.implicitHeight + Variables.scaled(4)
            color: "transparent"

            Rectangle {
                id: cardContainer
                anchors.fill: parent
                anchors.bottomMargin: Variables.scaled(4)
                color: Variables.backgroundColorUI
                radius: Variables.radius / 2
                border.color: cardMouseArea.containsMouse ? Variables.iconColor : Variables.borderColor
                border.width: Variables.borderWidth

                Behavior on border.color {
                    ColorAnimation { duration: Variables.fadeAnimation }
                }

                MouseArea {
                    id: cardMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                Loader {
                    id: loader
                    anchors.fill: parent
                    anchors.margins: Variables.spacing
                    property var rowData: delegateRoot.modelData

                    sourceComponent: {
                        if (delegateRoot.modelData.type === "toggle") return toggleComp;
                        if (delegateRoot.modelData.type === "slider") return sliderComp;
                        if (delegateRoot.modelData.type === "input") return inputComp;
                        return null;
                    }
                }
            }
        }
    }

    // --- 4. Main Panel Outer Frame ---
    Rectangle {
        anchors.fill: parent
        color: Variables.uiColor
        radius: Variables.radius
        border.color: Variables.borderColor
        border.width: Variables.borderWidth

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Variables.spacing * 1.5
            spacing: Variables.spacing * 1.2

            // Header Bar (Ambxst Style)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Variables.scaled(44)
                spacing: Variables.spacing

                Text {
                    text: "SETTINGS"
                    font.pixelSize: Variables.fontSize * 1.1
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    color: Variables.textColor
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    Layout.preferredHeight: Variables.scaled(24)
                    Layout.preferredWidth: profileText.implicitWidth + Variables.scaled(16)
                    color: Variables.backgroundColorUI
                    radius: height / 2
                    border.color: Variables.borderColor
                    border.width: 1

                    Text {
                        id: profileText
                        anchors.centerIn: parent
                        text: Variables.currentProfile.toUpperCase()
                        font.pixelSize: Variables.fontSize * 0.7
                        font.weight: Font.DemiBold
                        color: Variables.iconColor
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: Variables.scaled(32)
                    Layout.preferredHeight: Variables.scaled(32)
                    radius: width / 2
                    color: closeArea.containsMouse ? Variables.buttonColor : Variables.backgroundColorUI
                    border.color: Variables.borderColor
                    border.width: Variables.borderWidth

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Variables.textColor
                        font.pixelSize: Variables.fontSize * 0.85
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: settingsPanel.visible = false
                    }

                    Behavior on color {
                        ColorAnimation { duration: Variables.fadeAnimation }
                    }
                }
            }

            // Tide-Island / Ambxst Horizontal Navigation Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Variables.scaled(48)
                color: Variables.backgroundColorUI
                radius: Variables.radius / 2
                border.color: Variables.borderColor
                border.width: Variables.borderWidth

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Variables.scaled(4)
                    spacing: Variables.scaled(4)

                    Repeater {
                        model: categories
                        
                        Rectangle {
                            id: tabItem
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: (Variables.radius / 2) - Variables.scaled(2)
                            color: activeCategory === index ? Variables.iconColor : (tabMouseArea.containsMouse ? Variables.buttonColor : "transparent")

                            Behavior on color {
                                ColorAnimation { duration: Variables.fadeAnimation }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Variables.spacing / 2

                                Text {
                                    text: tabItem.modelData.icon
                                    font.pixelSize: Variables.fontSize * 0.85
                                }

                                Text {
                                    text: tabItem.modelData.name
                                    font.pixelSize: Variables.fontSize * 0.85
                                    font.weight: activeCategory === tabItem.index ? Font.Bold : Font.Medium
                                    color: activeCategory === tabItem.index ? Variables.uiColor : Variables.textColor
                                }
                            }

                            MouseArea {
                                id: tabMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: activeCategory = tabItem.index
                            }
                        }
                    }
                }
            }

            property int activeCategory: 0

            // Stack Content Pages
            StackLayout {
                currentIndex: activeCategory
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    model: generalSettings
                    spacing: Variables.spacing / 2
                    clip: true
                    delegate: itemDelegate
                }
                ListView {
                    model: mediaSettings
                    spacing: Variables.spacing / 2
                    clip: true
                    delegate: itemDelegate
                }
                ListView {
                    model: systemSettings
                    spacing: Variables.spacing / 2
                    clip: true
                    delegate: itemDelegate
                }
                ListView {
                    model: appearanceSettings
                    spacing: Variables.spacing / 2
                    clip: true
                    delegate: itemDelegate
                }
            }
        }
    }
}