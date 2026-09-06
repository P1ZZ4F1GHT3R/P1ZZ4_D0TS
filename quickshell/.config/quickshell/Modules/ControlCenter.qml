import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Wayland
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

    width: Variables.controlCenter ? controlLayout.implicitWidth + Variables.borderWidth * 4 : 12
    height: controlLayout.implicitHeight
    color: Variables.uiColor
    topLeftRadius: Variables.radius
    bottomLeftRadius: Variables.radius

    property var notifServer

    Shape {
        id: bottomRightConcave
        
        anchors.top: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: Variables.borderWidth * 4

        property real closedWidth: 12
        property real openWidth: controlLayout.implicitWidth + Variables.borderWidth * 4
        property real progress: Math.max(0, Math.min(1, (parent.width - closedWidth) / Math.max(1, openWidth - closedWidth)))

        readonly property real cornerSize: Variables.radius * progress

        width: cornerSize
        height: cornerSize

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

        anchors.bottom: parent.top
        anchors.right: parent.right
        anchors.rightMargin: Variables.borderWidth * 4

        property real closedWidth: 12
        property real openWidth: controlLayout.implicitWidth + Variables.borderWidth * 4
        property real progress: Math.max(0, Math.min(1, (parent.width - closedWidth) / Math.max(1, openWidth - closedWidth)))

        readonly property real cornerSize: Variables.radius * progress

        width: cornerSize
        height: cornerSize

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
    }

    HoverHandler {
        id: hoverHandler
        enabled: Variables.hoverEnabled

        onHoveredChanged: {
            if (hovered) {
                hovertimer.start()
            } else {
                hovertimer.stop()
                Variables.controlCenter = false
            }
        }
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
        id: controlLayout
        
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        spacing: Variables.spacing
        opacity: Variables.controlCenter ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Variables.fadeAnimation }
        }

        User{
            Layout.topMargin: Variables.topMargin * 4
            Layout.leftMargin: Variables.topMargin * 4
            Layout.rightMargin: Variables.topMargin * 4
        }

        RowLayout {
            id: sliderRow

            Layout.leftMargin: Variables.topMargin * 4
            Layout.rightMargin: Variables.topMargin * 4
            spacing: Variables.spacing

            Volume{}

            PomodoroTimer{}

            Brightness{}
        }

        Rectangle {
            id: buttonrowBackground
        
            implicitWidth: 368
            implicitHeight: 64 + Variables.topMargin * 2
            Layout.leftMargin: Variables.topMargin * 4
            Layout.rightMargin: Variables.topMargin * 4

            color: Variables.backgroundColorUI
            radius: Variables.radius
            border.color: Variables.borderColor
            border.width: Variables.borderWidth

            RowLayout {
                id: buttonRow

                anchors {
                    centerIn: parent
                    margins: Variables.topMargin * 4
                }
                spacing: Variables.spacing / 1.2

                IdleMonitorToggle{}

                FocusModeToggle{}

                Test{}
                
                Test{}

                Test{}
            }
        }

        NotificationTray {
            Layout.leftMargin: Variables.topMargin * 4
            Layout.rightMargin: Variables.topMargin * 4
            Layout.bottomMargin: Variables.topMargin * 4
            
            daemon: controlCenter.notifServer 
        }
    }
}