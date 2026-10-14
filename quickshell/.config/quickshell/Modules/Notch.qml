import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell.Services.Mpris
import "../"
import "../Widgets"

Rectangle {
    id: notchRoot

    implicitHeight: Variables.notchHidden ? 0 : notch.implicitHeight + Variables.height + Variables.borderWidth * 4
    implicitWidth: Variables.notchHidden ? 0 : notch.implicitWidth + Variables.width
    bottomLeftRadius: Variables.radius
    bottomRightRadius: Variables.radius
    color: Variables.uiColor
    scale: Variables.lockScreen ? 1.2 : 1.0
    transformOrigin: Item.Top

    property var notifServer
    property bool enablePowerMenuIpc: true

    property var activePlayer: {
        let players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            let p = players[i];
            if (p.identity.toLowerCase() === "spotify" || p.desktopEntry.toLowerCase() === "spotify") {
                return p;
            }
        }
        return null; 
    }

    Process {
        id: recChecker

        command: [
            "/bin/bash", 
            "-c", 
            "pgrep -x wf-recorder >/dev/null || " +
            "pgrep -x wl-screenrec >/dev/null || " +
            "pgrep -x gpu-screen-recorder >/dev/null || " +
            "pw-cli list-objects Node 2>/dev/null | grep -E 'media.class = \"Video/Source\"|media.role = \"Screen\"' >/dev/null " +
            "&& echo 1 || echo 0"
        ]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let status = this.text.trim()
                Variables.isRecording = (status === "1")
            }
        }
    }

    Behavior on scale {
        NumberAnimation { duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI }
    }

    IpcHandler {
        target: "powermenu"
        enabled: notchRoot.enablePowerMenuIpc

        function toggle(): void {
            if (!Variables.powerMenu) {
                Variables.powerMenu = true;
                Variables.toolBar = false;
                Variables.expandedState = false;
                volumeOsd.cancelOsd();
                brightnessOSD.cancelOsd();
            } else {
                Variables.powerMenu = false;
            }
        }
    }

    IpcHandler {
        target: "capture"
        enabled: notchRoot.enablePowerMenuIpc

        function toggle(): void {
            if (!Variables.toolBar) {
                Variables.toolBar = true;
                Variables.powerMenu = false;
                Variables.expandedState = false;
                volumeOsd.cancelOsd();
                brightnessOSD.cancelOsd();
            } else {
                Variables.toolBar = false;
            }
        }
    }

    onActivePlayerChanged: {
        if (Variables.lockScreen && Variables.lockScreenMpris && !Variables.pomodoroClock) {
            if (notchRoot.activePlayer !== null) {
                Variables.expandedState = true;
                Variables.notchHidden = false;
            } else {
                Variables.expandedState = false;
                Variables.notchHidden = true;
            }
        }
    }

    Connections {
        target: Variables
        
        function onLockScreenChanged() {
            lockTransitionTimer.stop();
            if (Variables.lockScreen) {
                Variables.powerMenu = false;
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

        function onPomodoroClockChanged() {
            if (Variables.lockScreen) {
                if (Variables.pomodoroClock) {
                    Variables.expandedState = false;
                    Variables.notchHidden = true;
                } else if (Variables.lockScreenMpris && notchRoot.activePlayer !== null) {
                    Variables.expandedState = true;
                    Variables.notchHidden = false;
                }
            }
        }
    }

    Shape {
        id: leftConcave
        
        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height))) / notchRoot.scale
        
        visible: cornerSize > 0

        width: cornerSize
        height: cornerSize
        anchors.top: parent.top
        anchors.right: parent.left
        anchors.topMargin: (Variables.borderWidth * 4) / notchRoot.scale

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

        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height))) / notchRoot.scale
        
        visible: cornerSize > 0
        
        width: cornerSize
        height: cornerSize
        anchors.top: parent.top
        anchors.left: parent.right
        anchors.topMargin: (Variables.borderWidth * 4) / notchRoot.scale

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
            Variables.clickEnabled && !Variables.expandedState && !Variables.powerMenu && !Variables.toolBar && !Variables.notifWidget ? Variables.expandedState = true : Variables.expandedState = false
        }
        onEntered: {
            if (Variables.lockScreen) return;
            Variables.hoverEnabled && !Variables.powerMenu && !Variables.toolBar && !Variables.notifWidget ? hovertimer.start() : null
        }
        onExited: {
            if (Variables.lockScreen) return;
            Variables.hoverEnabled ? (Variables.expandedState = false, hovertimer.stop()) : null
        }
    }

    Timer {
        id: lockTransitionTimer
        
        interval: 250
        repeat: false
        property bool isLocking: false

        onTriggered: {
            if (isLocking) {
                if (Variables.lockScreenMpris && notchRoot.activePlayer !== null && !Variables.pomodoroClock) {
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

    Timer {
        id: recCheckerTimer

        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            recChecker.running = false
            recChecker.running = true
        }
    }

    Rectangle {
        id: clipContainer
        
        color: "transparent"
        radius: Variables.radius
        clip: true
        anchors {
            fill: parent
        }
        
        RowLayout {
            id: notch

            anchors.fill: parent
            anchors.margins: Variables.rightMargin

            Loader {
                id: mprisWidgetLoader

                Layout.preferredWidth: item ? item.implicitWidth : 0
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: active
                active: !Variables.powerMenu && !Variables.notifWidget && !Variables.pomodoroClock && notchRoot.activePlayer !== null && !Variables.volumeOSD && !Variables.brightnessOSD && !Variables.notchHidden && !Variables.toolBar
                
                sourceComponent: Component {
                    MprisWidget {
                        activePlayer: notchRoot.activePlayer
                    }
                }
            }

            Loader {
                id: clockWidgetLoader

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: active
                active: !(notchRoot.activePlayer !== null && Variables.expandedState) && !Variables.powerMenu && !Variables.notifWidget && !Variables.volumeOSD && !Variables.brightnessOSD && !Variables.notchHidden && !Variables.toolBar
                sourceComponent: Component {
                    ClockWidget {
                        activePlayer: notchRoot.activePlayer
                    }
                }
            }

            Loader {
                id: notificationWidgetLoader

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: active
                active: Variables.notifWidget && !Variables.powerMenu  && !Variables.notchHidden && !Variables.toolBar && !Variables.lockScreen
                sourceComponent: Component {
                    NotificationWidget {
                        daemon: notchRoot.notifServer
                    }
                }
            }

            Loader {
                id: powerMenuLoader
                active: Variables.powerMenu && !Variables.notchHidden
                visible: active
                source: "../Widgets/PowerMenuWidget.qml"
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                focus: true
            }

            Loader {
                id: captureMenuLoader
                active: Variables.toolBar && !Variables.notchHidden
                visible: active
                source: "ToolBar.qml" 
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                focus: true
            }

            Loader {
                id: visualizerWidgetLoader

                Layout.alignment: Qt.AlignVCenter
                
                visible: active
                active: !Variables.powerMenu && !Variables.expandedState && !Variables.lockScreen && !Variables.notifWidget && !Variables.pomodoroClock && notchRoot.activePlayer !== null && !Variables.volumeOSD && !Variables.brightnessOSD  && !Variables.notchHidden && !Variables.toolBar
                sourceComponent: Component {
                    VisualizerWidget {
                        activePlayer: notchRoot.activePlayer
                    }
                }
            }

            VolumeOSD {
                id: volumeOsd

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                z: 10

                opacity: Variables.volumeOSD ? 1.0 : 0.0
                visible: Variables.volumeOSD && !Variables.powerMenu && !Variables.notifWidget && !Variables.brightnessOSD && !Variables.notchHidden && !Variables.toolBar

                Behavior on opacity {
                    NumberAnimation { duration: Variables.fadeAnimation }
                }
            }

            BrightnessOSD {
                id: brightnessOSD

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                z: 10

                opacity: Variables.brightnessOSD ? 1.0 : 0.0
                visible: Variables.brightnessOSD && !Variables.powerMenu && !Variables.notifWidget && !Variables.volumeOSD && !Variables.notchHidden && !Variables.toolBar

                Behavior on opacity {
                    NumberAnimation { duration: Variables.fadeAnimation }
                }
            }

            Loader {
                id: recordingIndicatorLoader

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: active
                active: Variables.isRecording && !Variables.powerMenu && !Variables.notifWidget && !Variables.expandedState && !Variables.toolBar

                sourceComponent: Component {
                    RecordingIndicator{}
                }
            }
        }
    }
}
