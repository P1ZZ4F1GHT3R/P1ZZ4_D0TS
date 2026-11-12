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

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    IpcHandler {
        target: "settings"

        function toggle(): void { settingsPanel.visible = !settingsPanel.visible; }
        function open(): void { settingsPanel.visible = true; }
        function close(): void { settingsPanel.visible = false; }
    }

    property int activeCategory: 0

    function selectCategory(index) {
        activeCategory = Math.max(0, Math.min(categories.length - 1, index))
    }

    function focusCategory(index) {
        selectCategory(index)
        if (panelContentLoader.item)
            panelContentLoader.item.focusCurrentCategory()
    }

    onActiveCategoryChanged: {
        if (categories[activeCategory].name !== "Lockscreen")
            Variables.clearCustomPresetDraft()
    }

    onVisibleChanged: {
        if (!visible) {
            activeCategory = 0
            Variables.clearCustomPresetDraft()
        } else {
            Qt.callLater(() => focusCategory(activeCategory))
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: settingsPanel.visible
        onActivated: settingsPanel.visible = false
    }

    property var shellSettings: [
        { 
            key: "preferredMonitorIndex", 
            label: "Primary Monitor", 
            description: "Select the display to render the shell on.", 
            type: "choice", 
            options: Variables.monitorOptions 
        },
        { key: "hoverEnabled", label: "Hover to open panels", description: "Open the notch and control center when you hover.", type: "toggle" },
        { key: "hoverTimer", label: "Hover delay", description: "How long the pointer must rest before opening.", type: "slider", min: 10, max: 1000, suffix: " ms" },
        { key: "workspaceCount", label: "Workspace count", description: "Number of workspaces shown in the bar.", type: "slider", min: 1, max: 10 },
        { key: "lockOnStart", label: "Lock on startup", description: "Start a locked session whenever Quickshell launches.", type: "toggle" },
        { key: "lockScreenClockSec", label: "Enable seconds on the lockscreen", description: "Wether the lockscreen clock shows seconds or not", type: "toggle" },
        { key: "lockscreenDate", label: "Enable date display on the lockscreen", description: "Wether the lockscreen displays the date or not", type: "toggle" },
        { key: "notchClockSec", label: "Enable seconds in the notch", description: "Wether the notch clock shows seconds or not", type: "toggle" },
    ]

    property var mediaSettings: [
        { key: "lockScreenMpris", label: "Lockscreen media", description: "Keep playback controls available while locked.", type: "toggle" },
        { key: "enableLyrics", label: "Synced lyrics", description: "Show lyrics in the expanded media widget.", type: "toggle" },
        { key: "wallpaperPreviewEnabled", label: "Live wallpaper preview", description: "Preview a selected wallpaper before applying it.", type: "toggle" },
        { key: "disablePopups", label: "Quiet notifications", description: "Suppress desktop toast popups without disabling notifications.", type: "toggle" },
        { key: "notifTimer", label: "Toast duration", description: "How long a notification stays on screen.", type: "slider", min: 1000, max: 10000, suffix: " ms" },
        { key: "compactVisualizerSize", label: "Visualizer bar count", description: "Number of visualizer bars in the closed notch", type: "slider", min: 3, max: 12},
        { key: "enableVisualizer", label: "Enable the visualizer", description: "Enable the visualizer in the notch", type: "toggle"},
        { key: "enableMusicIcon", label: "Enable the musicicon", description: "Enable the musicicon in the notch", type: "toggle"},
    ]

    property var systemSettings: [
        { key: "idleMonitor", label: "Idle monitor", description: "Enable automatic lock and sleep handling.", type: "toggle" },
        { key: "idleLockTime", label: "Lock after", description: "Idle time before the session locks.", type: "slider", min: 60, max: 1800, suffix: " s" },
        { key: "idleSleepTime", label: "Sleep after", description: "Idle time before the system sleeps.", type: "slider", min: 120, max: 3600, suffix: " s" },
        { key: "updateTreshold", label: "Update alert threshold", description: "Notify when this many package updates are available.", type: "slider", min: 1, max: 500 },
        { key: "updateNotifStart", label: "First update reminder", description: "Delay before an available-update reminder appears.", type: "slider", min: 1, max: 60, factor: 60000, suffix: " min" },
        { key: "updateNotifRunning", label: "Update reminder interval", description: "How often to repeat the available-update reminder.", type: "slider", min: 1, max: 120, factor: 60000, suffix: " min" },
        { key: "pomodoroTime", label: "Pomodoro duration", description: "Focus time before the timer starts a break.", type: "slider", min: 1, max: 120, factor: 60, suffix: " min" },
        { key: "breakTime", label: "Pomodoro break", description: "Break time before the next focus session begins.", type: "slider", min: 1, max: 60, factor: 60, suffix: " min" },
    ]

    property var connectivitySettings: [
        { type: "connectivity", fillHeight: true }
    ]

    property var appearanceSettings: [
        { label: "Profile picture", description: "Choose the avatar shown in the control-center user card.", type: "profilePicture", height: Variables.settingsProfilePictureHeight + Variables.settingsCardPadding * 2 },
        { key: "uiColorSource", label: "Panel background", description: "Choose a role from the current Colors.qml palette.", type: "choice", palette: true, options: Variables.colorSources },
        { key: "backgroundColorUISource", label: "Raised surface", description: "Choose a role from the current Colors.qml palette.", type: "choice", palette: true, options: Variables.colorSources },
        { key: "textColorSource", label: "Text", description: "Choose a role from the current Colors.qml palette.", type: "choice", palette: true, options: Variables.colorSources },
        { key: "iconColorSource", label: "Accent", description: "Choose a role from the current Colors.qml palette.", type: "choice", palette: true, options: Variables.colorSources },
        { key: "borderColorSource", label: "Borders", description: "Choose a role from the current Colors.qml palette.", type: "choice", palette: true, options: Variables.colorSources },
        { key: "buttonColorSource", label: "Button surface", description: "Choose a role from the current Colors.qml palette.", type: "choice", palette: true, options: Variables.colorSources },
        { key: "lockscreenColorSource", label: "Lockscreen accent", description: "Choose a role from the current Colors.qml palette.", type: "choice", palette: true, options: Variables.colorSources },
        { key: "shadowColorValue", label: "Shadow", description: "Enter a hex shadow colour. The default is #000000.", type: "input", hexColor: true },
    ]

    property var lockscreenSettings: [
        { key: "activePasswordPreset", label: "Password animation", description: "Glyph set used by the lockscreen password mask.", type: "choice", options: Variables.passwordPresetOptions },
        { label: "Custom mask presets", description: "Save several named glyph sets. Select one above to edit or use it.", type: "presetManager", height: Variables.settingsPresetManagerHeight + Variables.settingsCardPadding * 2 },
    ]

    property var activationSettings: [
        { type: "activation", height: Variables.settingsActivationHeight + Variables.settingsCardPadding * 2 },
    ]

    property var categories: [
        { name: "Shell", icon: "", subtitle: "Interaction & layout", settings: shellSettings },
        { name: "Media", icon: "󰎇", subtitle: "Playback & notifications", settings: mediaSettings },
        { name: "Connectivity", icon: "󰖩", subtitle: "Wi-Fi & Bluetooth", settings: connectivitySettings },
        { name: "System", icon: "󰍹", subtitle: "Idle & updates", settings: systemSettings },
        { name: "Appearance", icon: "", subtitle: "Palette & surfaces", settings: appearanceSettings },
        { name: "Lockscreen", icon: "󰌾", subtitle: "Animation details", settings: lockscreenSettings },
        { name: "Activation", icon: "", subtitle: "Activate your copy of Linux here", settings: activationSettings },
    ]

    function settingValue(key) {
        const value = Variables[key];
        return value === undefined || value === null ? "" : value.toString();
    }

    function setSetting(key, value) {
        if (key === "shadowColorValue") {
            const colour = String(value).trim();
            if (!/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(colour))
                return;
            Variables[key] = colour;
            return;
        }

        if (key === "activePasswordPreset") {
            Variables.selectPasswordPreset(value);
            return;
        }

        Variables[key] = value;
    }

    function resetSetting(key) {
        if (Variables.settingDefaults[key] !== undefined)
            Variables[key] = Variables.settingDefaults[key];
    }

    function isSettingDefault(key) {
        return Variables[key] === Variables.settingDefaults[key];
    }

    Component {
        id: panelContent

        Rectangle {
            id: panelFrame

            function focusCurrentCategory() {
                const item = categoryRepeater.itemAt(settingsPanel.activeCategory)
                if (item)
                    item.forceActiveFocus()
            }
            anchors.fill: parent
            color: Variables.uiColor
            radius: Variables.radius
            border.color: Variables.borderColor
            border.width: Variables.borderWidth
            clip: true

            RowLayout {
                anchors.fill: parent

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: Variables.settingsSidebarWidth
                    Layout.maximumWidth: Variables.settingsSidebarWidth
                    color: Variables.backgroundColorUI
                    topLeftRadius: Variables.radius
                    bottomLeftRadius: Variables.radius
                    topRightRadius: 0
                    bottomRightRadius: 0
                    border.color: Variables.borderColor
                    border.width: Variables.borderWidth

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Variables.spacing
                        spacing: Variables.settingsSidebarItemSpacing

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Variables.settingsBrandIconSize + Variables.spacing * 2
                            Layout.bottomMargin: Variables.settingsSidebarHeaderMargin
                            radius: Variables.settingsCategoryRadius
                            border.color: Variables.borderColor
                            border.width: Variables.borderWidth
                            color: Variables.uiColor

                            RowLayout {
                                id: logoRow

                                anchors.centerIn: parent
                                spacing: Variables.settingsBrandGap

                                Rectangle {
                                    Layout.preferredWidth: Variables.settingsBrandIconSize
                                    Layout.preferredHeight: width
                                    radius: width / 2
                                    color: Variables.borderColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒓"
                                        color: Variables.uiColor
                                        font.pixelSize: Variables.fontSize
                                    }
                                }

                                ColumnLayout {
                                    spacing: Variables.settingsControlTextSpacing
                                    Text {
                                        text: "SETTINGS"
                                        font.pixelSize: Variables.fontSize * 1.1
                                        font.weight: Font.Bold
                                        font.letterSpacing: 2.5 * Variables.uiScale
                                        color: Variables.textColor
                                    }
                                    Text {
                                        text: "P1ZZ4_D0TS"
                                        font.pixelSize: Variables.fontSize * 0.69 
                                        font.letterSpacing: 2.1 * Variables.uiScale
                                        color: Variables.borderColor
                                    }
                                }
                            }
                        }

                        Repeater {
                            id: categoryRepeater
                            model: settingsPanel.categories

                            delegate: Rectangle {
                                id: categoryButton
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredHeight: Variables.settingsCategoryHeight
                                radius: Variables.settingsCategoryRadius
                                color: settingsPanel.activeCategory === index ? Variables.uiColor
                                      : categoryHover.containsMouse ? Variables.iconColor : Variables.borderColor
                                border.color: categoryHover.containsMouse ? Variables.buttonColor
                                      : settingsPanel.activeCategory === index ? Variables.iconColor : Variables.uiColor
                                border.width: Variables.borderWidth
                                activeFocusOnTab: true

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                                        settingsPanel.focusCategory(categoryButton.index - 1)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                                        settingsPanel.focusCategory(categoryButton.index + 1)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                        settingsPanel.selectCategory(categoryButton.index)
                                        event.accepted = true
                                    }
                                }

                                Behavior on color { ColorAnimation { duration: 140 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Variables.settingsCategoryLeftPadding
                                    anchors.rightMargin: Variables.settingsCategoryRightPadding
                                    spacing: Variables.settingsCategoryRightPadding

                                    Text {
                                        text: categoryButton.modelData.icon
                                        font.pixelSize: Variables.fontSize * 1.15
                                        color: categoryHover.containsMouse && settingsPanel.activeCategory !== categoryButton.index
                                            ? Variables.uiColor : Variables.iconColor
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: categoryButton.modelData.name
                                        font.pixelSize: Variables.fontSize * 0.8
                                        font.weight: settingsPanel.activeCategory === index ? Font.DemiBold : Font.Medium
                                        color: categoryHover.containsMouse && settingsPanel.activeCategory !== categoryButton.index
                                            ? Variables.uiColor : Variables.textColor
                                    }
                                }

                                MouseArea {
                                    id: categoryHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        settingsPanel.selectCategory(categoryButton.index)
                                        categoryButton.forceActiveFocus()
                                    }
                                }

                                SettingsToolTip {
                                    visible: categoryHover.containsMouse
                                    text: "Open " + categoryButton.modelData.subtitle.toLowerCase() + "."
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Variables.spacing * 1.5
                        spacing: Variables.spacing

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Variables.settingsHeaderHeight

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Variables.settingsControlTextSpacing
                                Text {
                                    text: settingsPanel.categories[settingsPanel.activeCategory].name
                                    font.pixelSize: Variables.fontSize * 1.35
                                    font.weight: Font.DemiBold
                                    color: Variables.textColor
                                }
                                Text {
                                    text: settingsPanel.categories[settingsPanel.activeCategory].subtitle
                                    font.pixelSize: Variables.fontSize * 0.7
                                    color: Variables.textColor
                                    opacity: 0.78
                                }
                            }

                            Item { Layout.preferredWidth: Variables.settingsCloseButtonSize + Variables.spacing }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Variables.borderColor
                            opacity: 0.6
                        }

                        ListView {
                            id: settingsList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: Variables.settingsListSpacing
                            model: settingsPanel.categories[settingsPanel.activeCategory].settings
                            topMargin: Variables.settingsListMargin
                            bottomMargin: Variables.settingsListMargin

                            add: Transition {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160 }
                                NumberAnimation { property: "y"; from: Variables.settingsListSpacing; duration: 160; easing.type: Easing.OutCubic }
                            }

                            delegate: Rectangle {
                                id: settingCard
                                required property var modelData
                                width: ListView.view.width
                                height: settingCard.modelData.fillHeight
                                        ? ListView.view.height - (Variables.settingsListMargin * 2)
                                        : (settingCard.modelData.height || Variables.settingsCardHeight)
                                radius: Variables.settingsCardRadius
                                color: cardMouse.containsMouse ? Variables.iconColor : Variables.backgroundColorUI
                                border.color: cardMouse.containsMouse ? Variables.buttonColor : Variables.borderColor
                                border.width: Variables.borderWidth

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }

                                SettingsToggle {
                                    anchors.fill: parent
                                    anchors.leftMargin: Variables.settingsCardPadding
                                    anchors.topMargin: Variables.settingsCardPadding
                                    anchors.bottomMargin: Variables.settingsCardPadding
                                    anchors.rightMargin: Variables.settingsCardPadding + Variables.settingsResetButtonSize + Variables.settingsResetButtonMargin
                                    visible: settingCard.modelData.type === "toggle"
                                    label: settingCard.modelData.label
                                    description: settingCard.modelData.description
                                    checkedState: Boolean(Variables[settingCard.modelData.key])
                                    onValueChanged: value => settingsPanel.setSetting(settingCard.modelData.key, value)
                                }

                                SettingsSlider {
                                    anchors.fill: parent
                                    anchors.leftMargin: Variables.settingsCardPadding
                                    anchors.topMargin: Variables.settingsCardPadding
                                    anchors.bottomMargin: Variables.settingsCardPadding
                                    anchors.rightMargin: Variables.settingsCardPadding + Variables.settingsResetButtonSize + Variables.settingsResetButtonMargin
                                    visible: settingCard.modelData.type === "slider"
                                    label: settingCard.modelData.label
                                    description: settingCard.modelData.description
                                    fromValue: settingCard.modelData.min
                                    toValue: settingCard.modelData.max
                                    valueFactor: settingCard.modelData.factor || 1
                                    valueSuffix: settingCard.modelData.suffix || ""
                                    sliderValue: Number(Variables[settingCard.modelData.key])
                                    onValueChanged: value => settingsPanel.setSetting(settingCard.modelData.key, value)
                                }

                                SettingsInput {
                                    anchors.fill: parent
                                    anchors.leftMargin: Variables.settingsCardPadding
                                    anchors.topMargin: Variables.settingsCardPadding
                                    anchors.bottomMargin: Variables.settingsCardPadding
                                    anchors.rightMargin: Variables.settingsCardPadding + Variables.settingsResetButtonSize + Variables.settingsResetButtonMargin
                                    visible: settingCard.modelData.type === "input"
                                    label: settingCard.modelData.label
                                    description: settingCard.modelData.description
                                    textValue: settingsPanel.settingValue(settingCard.modelData.key)
                                    hexColor: Boolean(settingCard.modelData.hexColor)
                                    onValueChanged: value => settingsPanel.setSetting(settingCard.modelData.key, value)
                                }

                                SettingsChoice {
                                    anchors.fill: parent
                                    anchors.leftMargin: Variables.settingsCardPadding
                                    anchors.topMargin: Variables.settingsCardPadding
                                    anchors.bottomMargin: Variables.settingsCardPadding
                                    anchors.rightMargin: Variables.settingsCardPadding + Variables.settingsResetButtonSize + Variables.settingsResetButtonMargin
                                    visible: settingCard.modelData.type === "choice"
                                    label: settingCard.modelData.label
                                    description: settingCard.modelData.description
                                    currentValue: settingsPanel.settingValue(settingCard.modelData.key)
                                    options: settingCard.modelData.options || []
                                    showColorPreview: Boolean(settingCard.modelData.palette)
                                    previewColor: settingCard.modelData.palette
                                        ? Variables.colorFromSource(settingsPanel.settingValue(settingCard.modelData.key))
                                        : "transparent"
                                    onValueChanged: value => settingsPanel.setSetting(settingCard.modelData.key, value)
                                }

                                SettingsPresetManager {
                                    anchors.fill: parent
                                    anchors.leftMargin: Variables.settingsCardPadding
                                    anchors.topMargin: Variables.settingsCardPadding
                                    anchors.bottomMargin: Variables.settingsCardPadding
                                    anchors.rightMargin: Variables.settingsCardPadding + Variables.settingsResetButtonSize + Variables.settingsResetButtonMargin
                                    visible: settingCard.modelData.type === "presetManager"
                                    label: settingCard.modelData.label || ""
                                    description: settingCard.modelData.description || ""
                                }

                                SettingsProfilePicture {
                                    anchors.fill: parent
                                    anchors.margins: Variables.settingsCardPadding
                                    visible: settingCard.modelData.type === "profilePicture"
                                    label: settingCard.modelData.label || ""
                                    description: settingCard.modelData.description || ""
                                }

                                SettingsConnectivity {
                                    anchors.fill: parent
                                    anchors.margins: Variables.settingsCardPadding
                                    visible: settingCard.modelData.type === "connectivity"
                                }

                                SettingsActivation {
                                    anchors.fill: parent
                                    anchors.margins: Variables.settingsCardPadding
                                    visible: settingCard.modelData.type === "activation"
                                }

                                Rectangle {
                                    id: resetButton
                                    visible: settingCard.modelData.type !== "presetManager"
                                        && settingCard.modelData.type !== "profilePicture"
                                        && settingCard.modelData.type !== "connectivity"
                                        && settingCard.modelData.type !== "activation"
                                    anchors.right: parent.right
                                    anchors.rightMargin: Variables.spacing
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Variables.settingsResetButtonSize
                                    height: width
                                    radius: width / 2
                                    opacity: resetButton.isDefault ? 0.0 : (resetMouse.containsMouse ? 1.0 : 0.6)
                                    color: resetMouse.containsMouse && !resetButton.isDefault
                                        ? Variables.iconColor : Variables.uiColor
                                    border.color: resetMouse.containsMouse && !resetButton.isDefault
                                        ? Variables.buttonColor : Variables.borderColor
                                    border.width: 1

                                    readonly property bool isDefault: settingsPanel.isSettingDefault(settingCard.modelData.key)
                                    activeFocusOnTab: visible

                                    Keys.onPressed: event => {
                                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                                                && !resetButton.isDefault) {
                                            settingsPanel.resetSetting(settingCard.modelData.key)
                                            event.accepted = true
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↺"
                                        font.pixelSize: Variables.fontSize * 0.9
                                        color: resetMouse.containsMouse && !resetButton.isDefault
                                            ? Variables.backgroundColorUI : Variables.iconColor
                                    }

                                    MouseArea {
                                        id: resetMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (!resetButton.isDefault)
                                                settingsPanel.resetSetting(settingCard.modelData.key)
                                            resetButton.forceActiveFocus()
                                        }
                                    }

                                    SettingsToolTip {
                                        visible: resetMouse.containsMouse && !resetButton.isDefault
                                        text: "Restore " + settingCard.modelData.label + " to its default value."
                                    }

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: closeButton

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Variables.spacing
                anchors.rightMargin: Variables.spacing
                width: Variables.settingsCloseButtonSize
                height: width
                radius: width / 2
                color: closeMouse.containsMouse ? Variables.iconColor : Variables.backgroundColorUI
                border.color: closeMouse.containsMouse ? Variables.buttonColor : Variables.borderColor
                border.width: Variables.borderWidth
                z: 2
                activeFocusOnTab: true

                Keys.onReturnPressed: settingsPanel.visible = false
                Keys.onEnterPressed: settingsPanel.visible = false
                Keys.onSpacePressed: settingsPanel.visible = false

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: Variables.fontSize * 1.25
                    color: closeMouse.containsMouse ? Variables.uiColor : Variables.textColor
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        settingsPanel.visible = false
                        closeButton.forceActiveFocus()
                    }
                }

                SettingsToolTip {
                    visible: closeMouse.containsMouse
                    text: "Close settings. Escape also closes this panel."
                }

                Behavior on color { ColorAnimation { duration: 140 } }
            }
        }
    }

    Loader {
        id: panelContentLoader
        anchors.fill: parent
        active: settingsPanel.visible
        sourceComponent: panelContent
    }
}