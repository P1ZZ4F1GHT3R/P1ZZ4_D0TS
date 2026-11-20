import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../Common"

Item {
    id: settingsPanel

    visible: Variables.settingsOpen || exitAnimTimer.running
    enabled: Variables.settingsOpen
    focus: Variables.settingsOpen && !Variables.launcherOpen
    clip: true

    property int activeCategory: 0
    property bool visualExpanded: false
    property real launcherHeight: 0

    IpcHandler {
        target: "settings"

        function toggle(): void { Variables.toggleSettings(); }
        function open(): void { Variables.openSettings(); }
        function close(): void { Variables.closeSettings(); }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: Variables.settingsOpen
        onActivated: Variables.closeSettings()
    }

    function syncCategoryMetadata() {
        const cat = categories[activeCategory] || categories[0];
        Variables.currentSettingsCategory = {
            name: cat.name,
            icon: cat.icon,
            subtitle: cat.subtitle
        };
    }

    function selectCategory(index) {
        activeCategory = Math.max(0, Math.min(categories.length - 1, index));
    }

    function focusCategory(index) {
        selectCategory(index);
        if (contentLoader.item)
            contentLoader.item.focusCurrentCategory();
    }

    Component.onCompleted: {
        Variables.settingsCategories = categories;
        syncCategoryMetadata();
    }

    onActiveCategoryChanged: {
        syncCategoryMetadata();
        if (categories[activeCategory].name !== "Lockscreen")
            Variables.clearCustomPresetDraft();
    }

    Timer {
        id: exitAnimTimer
        interval: Variables.activeDurationUI
        repeat: false
        onTriggered: {
            if (!Variables.settingsOpen) {
                settingsPanel.activeCategory = 0;
                Variables.requestedSettingsCategory = 0;
                Variables.highlightedSettingKey = "";
                Variables.clearCustomPresetDraft();
            }
        }
    }

    Timer {
        id: focusEnsureTimer
        interval: 40
        repeat: true
        running: Variables.settingsOpen && !Variables.launcherOpen && contentLoader.item !== null && !settingsPanel.activeFocus
        onTriggered: settingsPanel.focusCategory(settingsPanel.activeCategory)
    }

    Connections {
        target: Variables

        function onSettingsOpenChanged() {
            if (Variables.settingsOpen) {
                exitAnimTimer.stop();
                settingsPanel.selectCategory(Variables.requestedSettingsCategory);
                Variables.clearCustomPresetDraft();
                settingsPanel.syncCategoryMetadata();
                Qt.callLater(() => {
                    settingsPanel.visualExpanded = true;
                    if (!Variables.launcherOpen)
                        settingsPanel.focusCategory(settingsPanel.activeCategory);
                    if (contentLoader.item && Variables.highlightedSettingKey !== "")
                        contentLoader.item.scrollToHighlightedSetting();
                });
            } else {
                settingsPanel.visualExpanded = false;
                exitAnimTimer.restart();
            }
        }

        function onRequestedSettingsCategoryChanged() {
            if (Variables.settingsOpen) {
                settingsPanel.selectCategory(Variables.requestedSettingsCategory);
                Qt.callLater(() => {
                    if (contentLoader.item && Variables.highlightedSettingKey !== "")
                        contentLoader.item.scrollToHighlightedSetting();
                });
            }
        }

        function onHighlightedSettingKeyChanged() {
            if (Variables.settingsOpen && Variables.highlightedSettingKey !== "" && contentLoader.item) {
                Qt.callLater(() => contentLoader.item.scrollToHighlightedSetting());
            }
        }

        function onLauncherOpenChanged() {
            if (!Variables.launcherOpen && Variables.settingsOpen) {
                Qt.callLater(() => settingsPanel.focusCategory(settingsPanel.activeCategory));
            }
        }
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

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: Variables.settingsOpen || exitAnimTimer.running
        sourceComponent: Component {
            SettingsContent {
                controller: settingsPanel
                expanded: settingsPanel.visualExpanded
                launcherHeight: settingsPanel.launcherHeight
            }
        }
    }
}