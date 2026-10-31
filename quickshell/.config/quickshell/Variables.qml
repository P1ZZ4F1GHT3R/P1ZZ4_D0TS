pragma Singleton
import QtQuick
import QtCore
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
    readonly property int settingsWidth: scaled(600)
    readonly property int settingsHeight: scaled(700)

    property bool hoverEnabled: false
    property bool clickEnabled: !hoverEnabled // Automatically updates when hoverEnabled changes
    property bool lockScreenMpris: true
    property bool enableLyrics: true
    property bool wallpaperPreviewEnabled: true
    property bool lockOnStart: false
    
    property int idleLockTime: 300
    property int idleSleepTime: 900
    property int updateTreshold: 125
    property int updateNotifStart: 300000
    property int updateNotifRunning: 900000
    property int notifTimer: 3000
    property int hoverTimer: 50
    property int workspaceCount: 5

    // --- Colors (Made editable) ---
    property color uiColor: Colors.background
    property color textColor: Colors.foreground
    property color iconColor: Colors.color13
    property color borderColor: Colors.color12
    property color buttonColor: Colors.color9
    property color lockscreenColor: Colors.color11
    property color backgroundColorUI: Colors.color8
    property color shadowColor: '#000000'

    // --- Password Presets (Readonly defaults, custom string for user additions) ---
    readonly property var oneZero: ["1", "0"]
    readonly property var fullRandom: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    readonly property var blocks: ["■", "◼", "◾", "▪", "⬝", "▢", "▅", "█", "▮", "▯"]
    readonly property var mineCraft: ["ᔑ", "ʖ", "ᓵ", "↸", "ᒷ", "⎓", "⊣", "⍑", "╎", "⋮", "ꖌ", "ꖎ", "ᒲ", "リ", "𝙹", "!¡", "ᑑ", "∷", "ᓭ", "ℸ ̣", "⚍", "⍊", "∴", "̇/", "||", "⨅"]
    readonly property var matrix: ["ﾊ", "ﾐ", "ﾋ", "ｰ", "ｳ", "ｼ", "ﾅ", "ﾓ", "ﾆ", "ｻ"]
    readonly property var standard: [""]
    property string activePasswordPreset: "standard" 
    property string customPasswordPreset: "" // For users to save their own

    // --- State Variables ---
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
    property bool idleMonitor: true
    property bool disablePopups: false
    property bool focusMode: false
    property bool focused: false 
    property int pomodoroTime: 25 * 60
    property int breakTime: 5 * 60
    property bool pomodoroClock: false
    property int pomodoroTimeLeft: pomodoroTime
    property bool pomodoroIsRunning: false
    property bool pomodoroIsBreak: false
    property bool wallpaperPicker: launcherOpen && launcherMode === "wallpaper"
    property bool wallpaperPreview: false
    property string previewPath: ""
    property bool activateLinux: false
    property bool volumeOSD: false
    property bool brightnessOSD: false
    property bool osdPreExpanded: false
    property bool toolBar: false
    property bool snippingMode: false
    property string captureAction: "screenshot"
    property bool isRecording: false
    property bool launcherOpen: false
    property string launcherMode: "apps"

    // --- Persistence ---
    property Settings settings: Settings {
        category: "QuickshellSettings"
        
        // State
        property alias idleMonitor: root.idleMonitor
        property alias disablePopups: root.disablePopups
        property alias activateLinux: root.activateLinux
        property alias currentProfile: root.currentProfile
        
        // Settings
        property alias hoverEnabled: root.hoverEnabled
        property alias lockScreenMpris: root.lockScreenMpris
        property alias enableLyrics: root.enableLyrics
        property alias wallpaperPreviewEnabled: root.wallpaperPreviewEnabled
        property alias lockOnStart: root.lockOnStart
        
        // Integers
        property alias idleLockTime: root.idleLockTime
        property alias idleSleepTime: root.idleSleepTime
        property alias workspaceCount: root.workspaceCount
        property alias hoverTimer: root.hoverTimer
        property alias notifTimer: root.notifTimer
        
        // Colors
        property alias uiColor: root.uiColor
        property alias textColor: root.textColor
        property alias iconColor: root.iconColor
        property alias borderColor: root.borderColor
        property alias buttonColor: root.buttonColor
        property alias lockscreenColor: root.lockscreenColor
        property alias backgroundColorUI: root.backgroundColorUI
        property alias shadowColor: root.shadowColor

        // Password settings
        property alias activePasswordPreset: root.activePasswordPreset
        property alias customPasswordPreset: root.customPasswordPreset
    }
}
