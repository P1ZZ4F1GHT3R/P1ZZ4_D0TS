pragma Singleton
import QtQuick
import "./"

QtObject {
    readonly property int radius: 24
    readonly property int height: 24
    readonly property int width: 64
    readonly property int leftMargin: rightMargin * 1.5
    readonly property int rightMargin: 12
    readonly property int fontSize: 18
    readonly property int spacing: 12
    readonly property int exclusiveZone: 40
    readonly property int workspaceCount: 5
    readonly property int circleHeight: fontSize * (1 + 1/3)
    readonly property int circleWidth: circleHeight
    readonly property int circleRadius: circleHeight / 2
    readonly property int animationType: Easing.InOutQuad
    readonly property int animationDuration: 200
    readonly property int borderWidth: 2
    readonly property int systemPoll: 2000
    readonly property int imgHeight: height
    readonly property int imgWidth: height
    readonly property int imgRadius: 8
    readonly property int animationTypeUI: Easing.InOutQuad
    readonly property int animationDurationUI: 400


    readonly property color uiColor: Colors.background
    readonly property color textColor: Colors.foreground
    readonly property color iconColor: Colors.color14
    readonly property color borderColor: Colors.color13



    
    property string currentProfile: "balanced"
}