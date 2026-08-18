pragma Singleton
import QtQuick
import "./"

QtObject {
    readonly property int radius: 24
    readonly property int height: 24
    readonly property int width: 64
    readonly property int leftMargin: rightMargin * 1.5
    readonly property int rightMargin: 12
    readonly property int topMargin: 4
    readonly property int fontSize: 18
    readonly property int spacing: 12
    readonly property int exclusiveZone: 48
    readonly property int workspaceCount: 5
    readonly property int circleHeight: fontSize * (1 + 1/3)
    readonly property int circleWidth: circleHeight
    readonly property int circleRadius: circleHeight / 2
    readonly property int animationType: Easing.InOutQuad
    readonly property int animationDuration: 200
    readonly property int borderWidth: 2
    readonly property int systemPoll: 2000
    readonly property int imgHeight: 24
    readonly property int imgWidth: imgHeight
    readonly property int imgRadius: 8
    readonly property int animationTypeUI: Easing.InOutQuad
    readonly property int animationDurationUI: 200
    readonly property int hoverTimer: 500
    readonly property int barRadius: 4
    readonly property int trackTitleLength: 28
    readonly property int notifTimer: 3000
    readonly property int fadeAnimation: 300

    readonly property bool hoverEnabled: false
    readonly property bool clickEnabled: hoverEnabled ? false : true
    readonly property bool scrollingNotifs: false

    readonly property color uiColor: Colors.background
    readonly property color textColor: Colors.foreground
    readonly property color iconColor: Colors.color14
    readonly property color borderColor: Colors.color13
    readonly property color buttonColor: Colors.color10



    
    property string currentProfile: "balanced"
    property bool expandedState: false
    property bool powerMenu: false
    property bool notifWidget: false
    property var currentNotif: null
    
}