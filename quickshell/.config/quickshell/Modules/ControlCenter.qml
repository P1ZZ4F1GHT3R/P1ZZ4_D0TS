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

    width: Variables.controlCenter ? controlLayout.implicitWidth + Variables.borderWidth * 4 : Variables.controlCenterClosedWidth
    height: Variables.controlCenter ? controlLayout.implicitHeight : Variables.controlCenterClosedHeight
    color: Variables.uiColor
    topLeftRadius: Variables.radius
    bottomLeftRadius: Variables.radius
    
    property var notifServer

    Shape {
        id: bottomRightConcave
        
        anchors.top: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: Variables.controlCenter ? Variables.borderWidth * 4 : 0

        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
        visible: cornerSize > 0

        width: cornerSize
        height: cornerSize

        ShapePath {
            fillColor: controlCenter.color
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
        anchors.rightMargin: Variables.controlCenter ? Variables.borderWidth * 4 : 0

        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
        visible: cornerSize > 0

        width: cornerSize
        height: cornerSize

        ShapePath {
            fillColor: controlCenter.color
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
            NumberAnimation { duration: Variables.controlCenter ? Variables.animationDurationUI : Variables.animationDurationUI * 1.8; easing.type: !Variables.controlCenter ? Variables.animationTypeUI : Easing.InOutSine }
        }

    Behavior on height {
        NumberAnimation { duration: !Variables.controlCenter ? Variables.animationDurationUI : Variables.animationDurationUI * 1.2; easing.type: Variables.animationTypeUI }
    }

    Behavior on color {
        ColorAnimation { duration: Variables.fadeAnimation}
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


    Rectangle {
        id: clipContainer
        
        color: "transparent"
        radius: Variables.radius
        clip: true
        anchors {
            fill: parent
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
            
                implicitWidth: Math.max(Variables.controlCenterButtonWidth,
                    buttonRow.implicitWidth + Variables.borderWidth * 4)
                implicitHeight: Math.max(Variables.controlCenterButtonHeight + Variables.topMargin * 2,
                    buttonRow.implicitHeight + Variables.borderWidth * 4)
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

                    ActivateLinuxToggle{}
                    
                    WifiToggle{}

                    BluetoothToggle{}
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
}
