import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import Quickshell.Services.Pipewire
import QtQuick.Dialogs
import QtCore
import Quickshell.Widgets
import "../Widgets"
import "../"


Rectangle { 
    id: controlCenter
    anchors{
        right: parent.right
        verticalCenter: parent.verticalCenter
    }

    width: Variables.controlCenter ? 270 : 10
    height: Variables.controlCenter ? 800: 400 
    color: Variables.uiColor
    topLeftRadius: Variables.radius
    bottomLeftRadius: Variables.radius
    clip: true

    Shape {
        id: bottomRightConcave
        
        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
        visible: cornerSize > 0

        width: cornerSize
        height: cornerSize
        anchors.top: parent.bottom
        anchors.right: parent.right

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: bottomRightConcave.cornerSize; y: 0 }
            PathLine { x: bottomRightConcave.cornerSize; y: bottomRightConcave.cornerSize }
            PathArc {
                x: 0; y: 0
                radiusX: bottomRightConcave.cornerSize
                radiusY: bottomRightConcave.cornerSize
                direction: PathArc.Counterclockwise
            }
            PathLine { x: bottomRightConcave.cornerSize; y: 0 }
        }
    }

    Shape {
        id: topRightConcave
        
        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
        visible: cornerSize > 0

        width: cornerSize
        height: cornerSize
        anchors.bottom: parent.top
        anchors.right: parent.right

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: topRightConcave.cornerSize; y: topRightConcave.cornerSize }
            
            PathLine { x: topRightConcave.cornerSize; y: 0 }
            
            PathArc {
                x: 0; y: topRightConcave.cornerSize
                radiusX: topRightConcave.cornerSize
                radiusY: topRightConcave.cornerSize
                direction: PathArc.Clockwise
            }
            
            PathLine { x: topRightConcave.cornerSize; y: topRightConcave.cornerSize }
        }
    }

    Behavior on width {
        NumberAnimation {duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI}
    }

    Behavior on height {
        NumberAnimation {duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI}
    }

    MouseArea {
        id: mousearea

        anchors.fill: parent
        hoverEnabled: true

        onClicked: Variables.clickEnabled && !Variables.controlCenter ? Variables.controlCenter = true : Variables.controlCenter = false
        onEntered: Variables.hoverEnabled ? hovertimer.start() : null
        onExited: Variables.hoverEnabled ? (Variables.controlCenter = false, hovertimer.stop()) : null
    }

    Timer {
        id: hovertimer
        interval: Variables.hoverTimer
        running: false
        repeat: false
        triggeredOnStart: false
        onTriggered: Variables.controlCenter = true
    }

    ColumnLayout {
        
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }

        spacing: Variables.spacing
        visible: Variables.controlCenter
        opacity: Variables.controlCenter ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Variables.fadeAnimation }
        }

        UserStats{
            Layout.topMargin: Variables.topMargin * 4
            Layout.leftMargin: Variables.topMargin * 4
            Layout.rightMargin: Variables.topMargin * 4
        }
        Volume{}
        IdleMonitorSwitch{}
    }
}