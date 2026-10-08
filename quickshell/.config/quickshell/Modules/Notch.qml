import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import QtQuick.Effects
import "../"
import "../Widgets"

Rectangle {
    id: notchRoot

    property var notifServer

    implicitHeight: Variables.notchHidden ? 0 : notch.implicitHeight + Variables.height + Variables.borderWidth * 4
    implicitWidth: {
        if (Variables.notchHidden) return 0; 
        return Variables.expandedState ? notch.implicitWidth + Variables.width * 10 : notch.implicitWidth + Variables.width;
        }
    bottomLeftRadius: Variables.radius
    bottomRightRadius: Variables.radius
    color: Variables.uiColor
    scale: Variables.lockScreen ? 1.25 : 1.0
    transformOrigin: Item.Top

    IpcHandler {
        target: "powermenu"

        function toggle(): void {
            powerMenuLoader.active = !powerMenuLoader.active
            if (powerMenuLoader.active) {
                Variables.powerMenu = true;
                Variables.expandedState = false;
                volumeOsd.cancelOsd();
                brightnessOsd.cancelOsd();
            }
            else {
                Variables.powerMenu = false;
            }
        }
    }

    Timer {
        id: lockTransitionTimer
        interval: 250
        repeat: false
        property bool isLocking: false

        onTriggered: {
            if (isLocking) {
                if (Variables.lockScreenMpris && mprisWidget.activePlayer !== null) {
                    Variables.expandedState = true;
                    Variables.notchHidden = false;
                }
            } else {
                Variables.activeAnimationUI = Variables.bouncingAnimationUI;
                Variables.activeDurationUI = Variables.bouncingDurationUI;
                Variables.expandedState = false;
                Variables.notchHidden = false;
                if (!Variables.pomodoroClock) {
                    Variables.workspacesHidden = false;
                    Variables.systemHidden = false;
                }
                animationSwitch.start();
            }
        }
    }

   Connections {
        target: Variables
        
        function onlockScreenChanged() {
            lockTransitionTimer.stop();
            if (Variables.lockScreen) {
                Variables.powerMenu = false;
                powerMenuLoader.active = false;
                Variables.expandedState = false;
                Variables.notchHidden = true;
                Variables.workspacesHidden = true;
                Variables.systemHidden = true;
                hovertimer.stop();

                lockTransitionTimer.isLocking = true;
                lockTransitionTimer.start();
            }
            else {
                Variables.expandedState = false; 
                
                Variables.notchHidden = true;
                hovertimer.stop();

                lockTransitionTimer.isLocking = false;
                lockTransitionTimer.start();
            }
        }
    }

    Connections {
        target: mprisWidget
        ignoreUnknownSignals: true

        function onActivePlayerChanged() {
            if (Variables.lockScreen && Variables.lockScreenMpris) {
                if (mprisWidget.activePlayer !== null) {
                    Variables.expandedState = true;
                    Variables.notchHidden = false;
                } else {
                    Variables.expandedState = false;
                    Variables.notchHidden = true;
                }
            }
        }
    }

    Shape {
        id: leftConcave
        
        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
        
        visible: cornerSize > 0

        width: cornerSize
        height: cornerSize
        anchors.top: parent.top
        anchors.right: parent.left
        anchors.topMargin: Variables.borderWidth * 4 / notchRoot.scale

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: leftConcave.cornerSize; y: 0 }
            PathLine { x: leftConcave.cornerSize; y: leftConcave.cornerSize }
            PathArc {
                x: 0; y: 0
                radiusX: leftConcave.cornerSize
                radiusY: leftConcave.cornerSize
                direction: PathArc.Counterclockwise
            }
            PathLine { x: leftConcave.cornerSize; y: 0 }
        }
    }

    Shape {
        id: rightConcave

        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
        
        visible: cornerSize > 0
        
        width: cornerSize
        height: cornerSize
        anchors.top: parent.top
        anchors.left: parent.right
        anchors.topMargin: Variables.borderWidth * 4 / notchRoot.scale

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: 0; y: 0 }
            PathLine { x: 0; y: rightConcave.cornerSize }
            PathArc {
                x: rightConcave.cornerSize; y: 0
                radiusX: rightConcave.cornerSize
                radiusY: rightConcave.cornerSize
                direction: PathArc.Clockwise
            }
            PathLine { x: 0; y: 0 }
        }
    }

    Behavior on implicitWidth {
        NumberAnimation { duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI }
    }

    MouseArea {
        id: mousearea

        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            if (Variables.lockScreen) return; 
            Variables.clickEnabled && !Variables.expandedState && !Variables.powerMenu && !Variables.notifWidget ? Variables.expandedState = true : Variables.expandedState = false
        }
        onEntered: {
            if (Variables.lockScreen) return;
            Variables.hoverEnabled && !Variables.powerMenu && !Variables.notifWidget ? hovertimer.start() : null
        }
        onExited: {
            if (Variables.lockScreen) return;
            Variables.hoverEnabled ? (Variables.expandedState = false, hovertimer.stop()) : null
        }
    }

    Timer {
        id: hovertimer
        interval: Variables.hoverTimer
        running: false
        repeat: false
        triggeredOnStart: false
        onTriggered: Variables.expandedState = true
    }

    Timer {
        id: animationSwitch
        interval: 200
        running: false
        repeat: false
        onTriggered: {
            Variables.activeDurationUI = Variables.animationDurationUI;
            Variables.activeAnimationUI = Variables.animationTypeUI;
        }
    }

    RowLayout {
        id: notch

        clip: true

        anchors {
            fill: parent
            leftMargin: Variables.rightMargin
            rightMargin: Variables.rightMargin
        } 

        MprisWidget {
            id: mprisWidget
            visible: !Variables.powerMenu && !Variables.notifWidget && !Variables.pomodoroClock && mprisWidget.activePlayer !== null && !Variables.volumeOSD && !Variables.brightnessOSD
        }

        ClockWidget {
            id: clockWidget 
            
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            visible: !(mprisWidget.activePlayer !== null && Variables.expandedState) && !Variables.powerMenu && !Variables.notifWidget && !Variables.volumeOSD && !Variables.brightnessOSD
        }

        NotificationWidget {
            id: notificationWidget
            daemon: notchRoot.notifServer
            visible: Variables.notifWidget && !Variables.powerMenu && !Variables.lockScreen
        }

        Loader {
            id: powerMenuLoader
            active: Variables.powerMenu
            visible: active
            source: "../Widgets/PowerMenuWidget.qml"
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            focus: true
        }

        VisualizerWidget {
            id: visualizerWidget 
            activePlayer: mprisWidget.activePlayer
            visible: !Variables.powerMenu && !Variables.expandedState && !Variables.notifWidget && !Variables.pomodoroClock && mprisWidget.activePlayer !== null && !Variables.volumeOSD && !Variables.brightnessOSD
        }

        VolumeOSD {
            id: volumeOsd

            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            z: 10

            opacity: Variables.volumeOSD ? 1.0 : 0.0
            visible: Variables.volumeOSD && !Variables.powerMenu && !Variables.notifWidget && !Variables.brightnessOSD

            Behavior on opacity {
                NumberAnimation { duration: Variables.fadeAnimation }
            }
        }

        BrightnessOSD {
            id: brightnessOSD

            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            z: 10

            opacity: Variables.brightnessOSD ? 1.0 : 0.0
            visible: Variables.brightnessOSD && !Variables.powerMenu && !Variables.notifWidget && !Variables.volumeOSD

            Behavior on opacity {
                NumberAnimation { duration: Variables.fadeAnimation }
            }
        }
    }
}