pragma Singleton
import QtQuick
import QtCore
import "./"

QtObject {
    id: root

    readonly property int radius: 24
    readonly property int height: 24
    readonly property int width: 64
    readonly property int leftMargin: rightMargin * 1.5
    readonly property int rightMargin: 12
    readonly property int topMargin: 4
    readonly property int fontSize: 18
    readonly property int spacing: 12
    readonly property int exclusiveZoneTop: 36
    readonly property int workspaceCount: 5
    readonly property int circleHeight: fontSize * (1 + 1/3)
    readonly property int circleWidth: circleHeight
    readonly property int circleRadius: circleHeight / 2
    readonly property int borderWidth: 2
    readonly property int systemPoll: 2000
    readonly property int imgHeight: 24
    readonly property int imgWidth: imgHeight
    readonly property int imgRadius: 8
    readonly property int animationTypeUI: Easing.InOutQuad
    readonly property int animationDurationUI: 200
    readonly property int hoverTimer: 250
    readonly property int barRadius: 4
    readonly property int trackTitleLength: 40
    readonly property int notifTimer: 3000
    readonly property int fadeAnimation: 300
    readonly property int updateNotifStart: 300000
    readonly property int updateNotifRunning: 900000
    readonly property int updateTreshold: 50
    readonly property int bouncingAnimationUI: Easing.OutElastic
    readonly property int bouncingDurationUI: 2400
    readonly property int pauseDuration: 150
    readonly property int exclusiveZoneSide: 0
    readonly property int idleLockTime: 300
    readonly property int idleSleepTime: 900
    readonly property int workspaceAnimationType: Easing.InOutBack
    
    readonly property bool hoverEnabled: false
    readonly property bool clickEnabled: hoverEnabled ? false : true

    readonly property color uiColor: Colors.background
    readonly property color textColor: Colors.foreground
    readonly property color iconColor: Colors.color14
    readonly property color borderColor: Colors.color13
    readonly property color buttonColor: Colors.color10
    readonly property color lockscreenColor: Colors.color5
    readonly property color backgroundColorUI: Colors.color1
    readonly property color progressBarBackground: Colors.color9
    
    readonly property var oneZero: ["1", "0"]
    readonly property var fullRandom: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    readonly property var blocks: ["■", "◼", "◾", "▪", "⬝", "▢", "▅", "█", "▮", "▯"]
    readonly property var mineCraft: ["ᔑ", "ʖ", "ᓵ", "↸", "ᒷ", "⎓", "⊣", "⍑", "╎", "⋮", "ꖌ", "ꖎ", "ᒲ", "リ", "𝙹", "!¡", "ᑑ", "∷", "ᓭ", "ℸ ̣", "⚍", "⍊", "∴", "̇/", "||", "⨅"]
    readonly property var matrix: ["ﾊ", "ﾐ", "ﾋ", "ｰ", "ｳ", "ｼ", "ﾅ", "ﾓ", "ﾆ", "ｻ"]
    readonly property var standard: [""]

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
    property bool wallpaperPicker: false
    property bool wallpaperPreview: false
    property string previewPath: ""



    property Settings settings: Settings {
        category: "ControlCenter"
        property alias idleMonitor: root.idleMonitor
        property alias disablePopups: root.disablePopups
    }
    
}
