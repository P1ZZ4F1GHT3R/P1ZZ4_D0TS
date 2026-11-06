pragma Singleton
import QtQuick
import QtCore
import Quickshell
import "./"

QtObject {
    id: root

    // The original layout was designed for a 2560x1440 monitor.
    readonly property int referenceScreenWidth: 2560
    readonly property int referenceScreenHeight: 1440
    property var monitor: null
    readonly property real uiScale: monitor && monitor.width > 0 && monitor.height > 0
        ? Math.min(monitor.width / referenceScreenWidth, monitor.height / referenceScreenHeight)
        : 1.0

    function scaled(value) {
        return Math.round(value * uiScale)
    }

    readonly property int radius: scaled(24)
    readonly property int height: scaled(24)
    readonly property int width: scaled(64)
    readonly property int leftMargin: rightMargin * 1.5
    readonly property int rightMargin: scaled(12)
    readonly property int topMargin: scaled(4)
    readonly property int fontSize: scaled(18)
    readonly property int spacing: scaled(12)
    readonly property int exclusiveZoneTop: scaled(36)
    readonly property int circleHeight: fontSize * (1 + 1/3)
    readonly property int circleWidth: circleHeight
    readonly property int circleRadius: circleHeight / 2
    readonly property int borderWidth: scaled(2)
    readonly property int systemPoll: 5000
    readonly property int profilePoll: 30000
    readonly property int brightnessPoll: 2000
    readonly property int imgHeight: scaled(24)
    readonly property int imgWidth: imgHeight
    readonly property int imgRadius: scaled(8)
    readonly property int toggleSize: scaled(64)
    readonly property int userWidth: scaled(368)
    readonly property int userHeight: scaled(64)
    readonly property int notificationTraySize: scaled(368)
    readonly property int pomodoroWidth: scaled(216)
    readonly property int pomodoroHeight: scaled(256)
    readonly property int volumeWidth: scaled(64)
    readonly property int volumeHeight: scaled(256)
    readonly property int sliderTrackWidth: scaled(6)
    readonly property int sliderTrackHeight: scaled(200)
    readonly property int sliderHandleSize: scaled(16)
    readonly property int sliderButtonSize: scaled(32)
    readonly property int wallpaperPickerWidth: scaled(800)
    readonly property int wallpaperPickerHeight: scaled(250)
    readonly property int wallpaperItemOffset: scaled(70)
    readonly property int wallpaperCardWidth: scaled(300)
    readonly property int wallpaperCardInset: scaled(30)
    readonly property int wallpaperCardMargin: scaled(3)
    readonly property int musicArtSize: scaled(128)
    readonly property int musicBlurMax: scaled(64)
    readonly property int visualizerGap: scaled(2)
    readonly property int visualizerMinHeight: scaled(2)
    readonly property int mprisVisualizerMinHeight: scaled(8)
    readonly property int controlCenterClosedWidth: scaled(12)
    readonly property int controlCenterButtonWidth: scaled(368)
    readonly property int controlCenterButtonHeight: scaled(64)
    readonly property int barControlCenterWidth: scaled(500)
    readonly property int lockscreenBlurMax: scaled(64)
    readonly property int lockscreenClockOffset: scaled(-100)
    readonly property int notificationActionMargin: scaled(8)
    readonly property int animationTypeUI: Easing.OutBack
    readonly property int animationDurationUI: 450
    readonly property int barRadius: scaled(4)
    readonly property int fadeAnimation: 300
    readonly property int bouncingAnimationUI: Easing.OutElastic
    readonly property int bouncingDurationUI: 2400
    readonly property int pauseDuration: 150
    readonly property int exclusiveZoneSide: 0
    readonly property int workspaceAnimationType: Easing.InOutBack
    readonly property int launcherWidth: scaled(666)
    readonly property int launcherSearchHeight: scaled(64)
    readonly property int launcherExpandedHeight: scaled(400)
    readonly property var shadowBlur: 1.0
    readonly property int settingsWidth: scaled(1500)
    readonly property int settingsHeight: scaled(1000)
    readonly property int settingsSidebarWidth: scaled(192)
    readonly property int settingsSidebarItemSpacing: 0
    readonly property int settingsSidebarHeaderMargin: scaled(6)
    readonly property int settingsBrandIconSize: scaled(30)
    readonly property int settingsBrandGap: scaled(9)
    readonly property int settingsCategoryHeight: scaled(48)
    readonly property int settingsCategoryRadius: scaled(14)
    readonly property int settingsCategoryLeftPadding: scaled(12)
    readonly property int settingsCategoryRightPadding: scaled(10)
    readonly property int settingsCategoryIndicatorSize: scaled(5)
    readonly property int settingsHeaderHeight: scaled(52)
    readonly property int settingsCloseButtonSize: scaled(34)
    readonly property int settingsListSpacing: scaled(8)
    readonly property int settingsListMargin: scaled(2)
    readonly property int settingsCardHeight: scaled(96)
    readonly property int settingsCardRadius: scaled(16)
    readonly property int settingsCardPadding: scaled(12)
    readonly property int settingsResetButtonSize: scaled(26)
    readonly property int settingsResetButtonMargin: scaled(10)
    readonly property int settingsPresetManagerHeight: scaled(210)
    readonly property int settingsPresetFieldHeight: scaled(32)
    readonly property int settingsPresetNameWidth: scaled(112)
    readonly property int settingsPresetSaveWidth: scaled(52)
    readonly property int settingsPresetDeleteSize: scaled(32)
    readonly property int settingsPresetListRowHeight: scaled(30)
    readonly property int settingsProfilePictureHeight: scaled(88)
    readonly property int settingsProfilePictureSize: scaled(72)
    readonly property int settingsConnectivityHeight: scaled(476)
    readonly property int settingsConnectivityListHeight: scaled(94)
    readonly property int settingsActivationHeight: scaled(360)
    readonly property int settingsActivationProgressHeight: scaled(8)
    readonly property int settingsActivationButtonHeight: scaled(36)
    readonly property int settingsActivationButtonWidth: scaled(188)
    readonly property int settingsScrollbarWidth: scaled(5)
    readonly property int settingsControlHeight: scaled(56)
    readonly property int settingsSliderControlHeight: scaled(60)
    readonly property int settingsControlLabelWidth: scaled(178)
    readonly property int settingsControlLabelMaxWidth: scaled(210)
    readonly property int settingsControlTextSpacing: scaled(2)
    readonly property int settingsFieldHeight: scaled(34)
    readonly property int settingsFieldHorizontalPadding: scaled(10)
    readonly property int settingsInputRadius: scaled(10)
    readonly property int settingsControlGap: scaled(8)
    readonly property int settingsValueFieldWidth: scaled(60)
    readonly property int settingsValueFieldHeight: scaled(28)
    readonly property int settingsValueSuffixWidth: scaled(42)
    readonly property int settingsSliderValueGroupWidth: scaled(104)
    readonly property int settingsChoiceTextRightPadding: scaled(28)
    readonly property int settingsChoicePopupOffset: scaled(4)
    readonly property int settingsChoicePopupPadding: scaled(2)
    readonly property int settingsToggleControlHeight: scaled(52)
    readonly property int settingsToggleTrackWidth: scaled(48)
    readonly property int settingsToggleTrackHeight: scaled(26)
    readonly property int settingsToggleHandleInset: scaled(3)
    readonly property int settingsToggleHandleSize: scaled(20)
    readonly property int settingsSliderTrackWidth: scaled(140)
    readonly property int settingsSliderTrackHeight: scaled(6)
    readonly property int settingsSliderHandleSize: scaled(16)
    readonly property int settingsColorPreviewSize: scaled(30)
    readonly property int settingsColorPreviewRadius: scaled(9)
    readonly property int settingsColorPreviewInset: scaled(10)

    // The defaults for the settingspanel
    readonly property var settingDefaults: ({
        hoverEnabled: false,
        lockScreenMpris: true,
        enableLyrics: true,
        wallpaperPreviewEnabled: true,
        lockOnStart: true,
        idleLockTime: 300,
        idleSleepTime: 900,
        updateTreshold: 125,
        updateNotifStart: 300000,
        updateNotifRunning: 900000,
        notifTimer: 3000,
        hoverTimer: 50,
        workspaceCount: 5,
        pomodoroTime: 25 * 60,
        breakTime: 5 * 60,
        idleMonitor: true,
        disablePopups: false,
        activateLinux: false,
        uiColorSource: "background",
        textColorSource: "foreground",
        iconColorSource: "color13",
        borderColorSource: "color12",
        buttonColorSource: "color9",
        lockscreenColorSource: "color11",
        backgroundColorUISource: "color8",
        shadowColorValue: "#000000",
        activePasswordPreset: "oneZero",
        customPresetName: "",
        customPasswordPreset: "",
        customPasswordPresets: "[]",
        preferredMonitorIndex: preferredMonitorIndex,
    })

    property bool hoverEnabled: settingDefaults.hoverEnabled
    property bool clickEnabled: !hoverEnabled
    property bool lockScreenMpris: settingDefaults.lockScreenMpris
    property bool enableLyrics: settingDefaults.enableLyrics
    property bool wallpaperPreviewEnabled: settingDefaults.wallpaperPreviewEnabled
    property bool lockOnStart: settingDefaults.lockOnStart

    property int idleLockTime: settingDefaults.idleLockTime
    property int idleSleepTime: settingDefaults.idleSleepTime
    property int updateTreshold: settingDefaults.updateTreshold
    property int updateNotifStart: settingDefaults.updateNotifStart
    property int updateNotifRunning: settingDefaults.updateNotifRunning
    property int notifTimer: settingDefaults.notifTimer
    property int hoverTimer: settingDefaults.hoverTimer
    property int workspaceCount: settingDefaults.workspaceCount
    property int preferredMonitorIndex: settingDefaults.preferredMonitorIndex

    property var monitorOptions: {
    let options = [];
    for (let i = 0; i < Quickshell.screens.length; i++) {
        let s = Quickshell.screens[i];
        // Use the hardware name if available, otherwise fallback to "Display 1", etc.
        let displayName = s.name ? s.name : ("Display " + (i + 1));
        options.push({ value: i.toString(), label: displayName });
    }
    return options;
}

    // Colors
    readonly property var colorSources: [
        { value: "background", label: "Background" },
        { value: "foreground", label: "Foreground" },
        { value: "cursor", label: "Cursor" },
        { value: "color0", label: "Color 0" }, { value: "color1", label: "Color 1" },
        { value: "color2", label: "Color 2" }, { value: "color3", label: "Color 3" },
        { value: "color4", label: "Color 4" }, { value: "color5", label: "Color 5" },
        { value: "color6", label: "Color 6" }, { value: "color7", label: "Color 7" },
        { value: "color8", label: "Color 8" }, { value: "color9", label: "Color 9" },
        { value: "color10", label: "Color 10" }, { value: "color11", label: "Color 11" },
        { value: "color12", label: "Color 12" }, { value: "color13", label: "Color 13" },
        { value: "color14", label: "Color 14" }, { value: "color15", label: "Color 15" }
    ]

    function colorFromSource(source) {
        const color = Colors[source]
        return color === undefined ? Colors.background : color
    }

    property string uiColorSource: settingDefaults.uiColorSource
    property string textColorSource: settingDefaults.textColorSource
    property string iconColorSource: settingDefaults.iconColorSource
    property string borderColorSource: settingDefaults.borderColorSource
    property string buttonColorSource: settingDefaults.buttonColorSource
    property string lockscreenColorSource: settingDefaults.lockscreenColorSource
    property string backgroundColorUISource: settingDefaults.backgroundColorUISource
    property string shadowColorValue: settingDefaults.shadowColorValue

    readonly property color uiColor: colorFromSource(uiColorSource)
    readonly property color textColor: colorFromSource(textColorSource)
    readonly property color iconColor: colorFromSource(iconColorSource)
    readonly property color borderColor: colorFromSource(borderColorSource)
    readonly property color buttonColor: colorFromSource(buttonColorSource)
    readonly property color lockscreenColor: colorFromSource(lockscreenColorSource)
    readonly property color backgroundColorUI: colorFromSource(backgroundColorUISource)
    readonly property color shadowColor: shadowColorValue

    // Password presets
    readonly property var oneZero: ["1", "0"]
    readonly property var fullRandom: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    readonly property var blocks: ["■", "◼", "◾", "▪", "⬝", "▢", "▅", "█", "▮", "▯"]
    readonly property var mineCraft: ["ᔑ", "ʖ", "ᓵ", "↸", "ᒷ", "⎓", "⊣", "⍑", "╎", "⋮", "ꖌ", "ꖎ", "ᒲ", "リ", "𝙹", "!¡", "ᑑ", "∷", "ᓭ", "ℸ ̣", "⚍", "⍊", "∴", "̇/", "||", "⨅"]
    readonly property var matrix: ["ﾊ", "ﾐ", "ﾋ", "ｰ", "ｳ", "ｼ", "ﾅ", "ﾓ", "ﾆ", "ｻ"]
    readonly property var standard: [""]
    property string activePasswordPreset: settingDefaults.activePasswordPreset
    property string customPresetName: settingDefaults.customPresetName
    property string customPasswordPreset: settingDefaults.customPasswordPreset
    property string customPasswordPresets: settingDefaults.customPasswordPresets

    function savedCustomPasswordPresets() {
        try {
            const presets = JSON.parse(customPasswordPresets)
            return Array.isArray(presets) ? presets.filter(preset =>
                preset && typeof preset.name === "string" && typeof preset.glyphs === "string") : []
        } catch (error) {
            return []
        }
    }

    readonly property var passwordPresetOptions: {
        const options = [
            { value: "standard", label: "Standard" },
            { value: "oneZero", label: "One / Zero" },
            { value: "fullRandom", label: "Full random" },
            { value: "blocks", label: "Blocks" },
            { value: "mineCraft", label: "Minecraft" },
            { value: "matrix", label: "Matrix" }
        ]
        savedCustomPasswordPresets().forEach(preset => {
            options.push({ value: "custom:" + preset.name, label: "Custom · " + preset.name })
        })
        return options
    }

    function customPresetGlyphs(presetId) {
        if (presetId === "custom")
            return customPasswordPreset
        if (typeof presetId !== "string" || !presetId.startsWith("custom:"))
            return ""
        const name = presetId.slice("custom:".length)
        const preset = savedCustomPasswordPresets().find(candidate => candidate.name === name)
        return preset ? preset.glyphs : ""
    }

    function saveCustomPasswordPreset() {
        const name = customPresetName.trim()
        const glyphs = customPasswordPreset
        if (name.length === 0 || glyphs.length === 0)
            return false

        const presets = savedCustomPasswordPresets()
        const index = presets.findIndex(preset => preset.name === name)
        const entry = { name: name, glyphs: glyphs }
        if (index === -1)
            presets.push(entry)
        else
            presets[index] = entry

        customPasswordPresets = JSON.stringify(presets)
        activePasswordPreset = "custom:" + name
        return true
    }

    function removeActiveCustomPasswordPreset() {
        if (!activePasswordPreset.startsWith("custom:"))
            return false

        const name = activePasswordPreset.slice("custom:".length)
        customPasswordPresets = JSON.stringify(savedCustomPasswordPresets().filter(preset => preset.name !== name))
        activePasswordPreset = settingDefaults.activePasswordPreset
        return true
    }

    function clearCustomPresetDraft() {
        customPresetName = ""
        customPasswordPreset = ""
    }

    function selectPasswordPreset(presetId) {
        activePasswordPreset = presetId
        if (typeof presetId !== "string" || !presetId.startsWith("custom:"))
            return

        const name = presetId.slice("custom:".length)
        const preset = savedCustomPasswordPresets().find(candidate => candidate.name === name)
        if (preset) {
            customPresetName = preset.name
            customPasswordPreset = preset.glyphs
        }
    }

    Component.onCompleted: {
        if (activePasswordPreset === "custom" && customPasswordPreset.length > 0) {
            customPresetName = "Imported custom"
            saveCustomPasswordPreset()
        } else if (activePasswordPreset === "custom") {
            activePasswordPreset = settingDefaults.activePasswordPreset
        }
        if (profilePicture === "" && legacyProfilePictureSettings.savedPfp !== "")
            profilePicture = legacyProfilePictureSettings.savedPfp.toString()
        clearCustomPresetDraft()
    }

    // State Variables
    property string currentProfile: "balanced"
    property bool expandedState: false
    property bool powerMenu: false
    property bool notifWidget: false
    property bool lockScreen: false
    property var currentNotif: null
    property int activeAnimationUI: animationTypeUI
    property int activeDurationUI: animationDurationUI
    property bool notchHidden: false
    property bool workspacesHidden: false
    property bool systemHidden: false
    property bool controlCenter: false
    property bool idleMonitor: settingDefaults.idleMonitor
    property bool disablePopups: settingDefaults.disablePopups
    property bool focusMode: false
    property bool focused: false 
    property int pomodoroTime: settingDefaults.pomodoroTime
    property int breakTime: settingDefaults.breakTime
    property bool pomodoroClock: false
    property int pomodoroTimeLeft: pomodoroTime
    property bool pomodoroIsRunning: false
    property bool pomodoroIsBreak: false
    property bool wallpaperPicker: launcherOpen && launcherMode === "wallpaper"
    property bool wallpaperPreview: false
    property string previewPath: ""
    property string profilePicture: ""
    property bool activateLinux: settingDefaults.activateLinux
    property bool volumeOSD: false
    property bool brightnessOSD: false
    property bool osdPreExpanded: false
    property bool toolBar: false
    property bool snippingMode: false
    property string captureAction: "screenshot"
    property bool isRecording: false
    property bool launcherOpen: false
    property string launcherMode: "apps"

    property Settings legacyProfilePictureSettings: Settings {
        property url savedPfp: ""
    }

    onPomodoroTimeChanged: {
        if (!pomodoroIsRunning && !pomodoroIsBreak)
            pomodoroTimeLeft = pomodoroTime
    }

    onBreakTimeChanged: {
        if (!pomodoroIsRunning && pomodoroIsBreak)
            pomodoroTimeLeft = breakTime
    }

    // Persistence
    property Settings settings: Settings {
        category: "QuickshellSettings"
        
        // State
        property alias idleMonitor: root.idleMonitor
        property alias disablePopups: root.disablePopups
        property alias activateLinux: root.activateLinux
        property alias currentProfile: root.currentProfile
        property alias profilePicture: root.profilePicture
        
        // Settings
        property alias hoverEnabled: root.hoverEnabled
        property alias lockScreenMpris: root.lockScreenMpris
        property alias enableLyrics: root.enableLyrics
        property alias wallpaperPreviewEnabled: root.wallpaperPreviewEnabled
        property alias lockOnStart: root.lockOnStart
        property alias preferredMonitorIndex: root.preferredMonitorIndex
        
        // Integers
        property alias idleLockTime: root.idleLockTime
        property alias idleSleepTime: root.idleSleepTime
        property alias workspaceCount: root.workspaceCount
        property alias hoverTimer: root.hoverTimer
        property alias notifTimer: root.notifTimer
        property alias updateTreshold: root.updateTreshold
        property alias updateNotifStart: root.updateNotifStart
        property alias updateNotifRunning: root.updateNotifRunning
        property alias pomodoroTime: root.pomodoroTime
        property alias breakTime: root.breakTime
        
        // Colour palette sources
        property alias uiColorSource: root.uiColorSource
        property alias textColorSource: root.textColorSource
        property alias iconColorSource: root.iconColorSource
        property alias borderColorSource: root.borderColorSource
        property alias buttonColorSource: root.buttonColorSource
        property alias lockscreenColorSource: root.lockscreenColorSource
        property alias backgroundColorUISource: root.backgroundColorUISource
        property alias shadowColorValue: root.shadowColorValue

        // Password settings
        property alias activePasswordPreset: root.activePasswordPreset
        property alias customPresetName: root.customPresetName
        property alias customPasswordPreset: root.customPasswordPreset
        property alias customPasswordPresets: root.customPasswordPresets
    }
}
