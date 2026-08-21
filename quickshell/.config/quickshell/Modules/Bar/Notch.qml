import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import "../../"
import "../../Widgets"

Rectangle {
    id: notchRoot

    property var notifServer

    implicitHeight: Variables.notchHidden ? 0 : notch.implicitHeight + Variables.height 
    implicitWidth: {
        if (Variables.notchHidden) return 0; 
        return Variables.expandedState ? notch.implicitWidth + Variables.width * 3 : notch.implicitWidth + Variables.width;
        }
    bottomLeftRadius: Variables.radius
    bottomRightRadius: Variables.radius
    color: Variables.uiColor

    IpcHandler {
        target: "powermenu"

        function toggle(): void {
            powerMenuLoader.active = !powerMenuLoader.active
            if (powerMenuLoader.active) {
                Variables.powerMenu = true;
                Variables.expandedState = false;
            }
            else {
                Variables.powerMenu = false;
            }
        }
    }

    Connections {
        target: Variables
        
        function onlockScreenChanged() {
            if (Variables.lockScreen) {
                Variables.powerMenu = false;
                powerMenuLoader.active = false;
                Variables.expandedState = false;
                Variables.notchHidden = true;
                Variables.workspacesHidden = true;
                Variables.systemHidden = true;
                hovertimer.stop();
            }
            else {
                Variables.activeAnimationUI = Variables.bouncingAnimationUI;
                Variables.activeDurationUI = Variables.bouncingDurationUI;
                Variables.notchHidden = false;
                Variables.workspacesHidden = false;
                Variables.systemHidden = false;
                animationSwitch.start();
            }
        }
    }

    Shape {
        id: leftConcave

        width: Variables.radius
        height: Variables.radius
        anchors.top: parent.top
        anchors.right: parent.left

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: Variables.radius; y: 0 }
            PathLine { x: Variables.radius; y: Variables.radius }
            PathArc {
                x: 0; y: 0
                radiusX: Variables.radius
                radiusY: Variables.radius
                direction: PathArc.Counterclockwise
            }
            PathLine { x: Variables.radius; y: 0 }
        }
    }

    Shape {
        id: rightConcave

        width: Variables.radius
        height: Variables.radius
        anchors.top: parent.top
        anchors.left: parent.right

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: 0; y: 0 }
            PathLine { x: 0; y: Variables.radius }
            PathArc {
                x: Variables.radius; y: 0
                radiusX: Variables.radius
                radiusY: Variables.radius
                direction: PathArc.Clockwise
            }
            PathLine { x: 0; y: 0 }
        }
    }

     Behavior on implicitWidth {
        NumberAnimation { duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI}
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI}
    }


    MouseArea {
        id: mousearea

        anchors.fill: parent
        hoverEnabled: true

        onClicked: Variables.clickEnabled && !Variables.expandedState && !Variables.powerMenu && !Variables.notifWidget ? Variables.expandedState = true : Variables.expandedState = false
        onEntered: Variables.hoverEnabled && !Variables.powerMenu && !Variables.notifWidget ? hovertimer.start() : null
        onExited: Variables.hoverEnabled ? (Variables.expandedState = false, hovertimer.stop()) : null
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
            leftMargin: Variables.leftMargin
            rightMargin: Variables.rightMargin
        } 

        MprisWidget {
            id: mprisWidget
            visible: !Variables.powerMenu && !Variables.notifWidget && mprisWidget.activePlayer !== null
        }

        ClockWidget {
            id: clockWidget 
            
            Layout.alignment: Qt.AlignHCenter

            visible: !(mprisWidget.activePlayer !== null && Variables.expandedState) && !Variables.powerMenu && !Variables.notifWidget
        }

        NotificationWidget {
            id: notificationWidget
            daemon: notchRoot.notifServer
            visible: Variables.notifWidget && !Variables.powerMenu
        }

        Loader {
            id: powerMenuLoader
            active: Variables.powerMenu
            visible: active
            source: "../../Widgets/PowerMenuWidget.qml"
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            focus: true
        }

        VisualizerWidget {
            id: visualizerWidget 
            activePlayer: mprisWidget.activePlayer
            visible: !Variables.powerMenu && !Variables.expandedState && !Variables.notifWidget && mprisWidget.activePlayer !== null
        }
    }
}
