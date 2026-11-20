import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../"

Rectangle {
    id: powerProfiles

    readonly property bool isHidden: Variables.systemHidden || Variables.lockScreen

    Layout.alignment: Qt.AlignTop
    Layout.topMargin: Variables.borderWidth * 6 + Variables.topMargin
    implicitHeight: Variables.circleHeight * 1.3
    implicitWidth: Variables.circleWidth * 1.3
    color: Variables.uiColor
    radius: Variables.radius
    border.color: actionMouse.containsMouse ? Variables.iconColor : Variables.borderColor
    border.width: Variables.borderWidth

    opacity: isHidden ? 0.0 : (actionMouse.containsMouse ? 0.9 : 1.0)
    scale: isHidden ? 0.0 : (actionMouse.pressed ? 0.94 : (actionMouse.containsMouse ? 1.05 : 1.0))
    visible: opacity > 0.001
    enabled: !isHidden

    property string currentProfile: Variables.currentProfile
    property string displayedProfile: Variables.currentProfile
    property int switchDirection: 1

    onCurrentProfileChanged: {
        if (displayedProfile === currentProfile)
            return;

        if (!visible) {
            displayedProfile = currentProfile;
            profileIcon.y = 0;
            profileIcon.opacity = 1.0;
            return;
        }

        modeSwitchAnim.restart();
    }

    Behavior on scale {
        NumberAnimation {
            duration: powerProfiles.isHidden ? Variables.activeDurationUI * 0.5 : Variables.activeDurationUI * 0.64
            easing.type: Variables.activeAnimationUI
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Variables.fadeAnimation
            easing.type: Easing.OutCubic
        }
    }

    Behavior on border.color {
        ColorAnimation { duration: Variables.fadeAnimation }
    }

    Behavior on color {
        ColorAnimation { duration: Variables.fadeAnimation }
    }

    function refresh() {
        if (!getProf.running)
            getProf.running = true;
    }

    readonly property var profiles: ["balanced", "performance", "power-saver"]

    readonly property var profileIcons: ({
        "performance": "",
        "balanced": "",
        "power-saver": ""
    })

    function cycleProfile(step) {
        const delta = step === undefined ? 1 : step;
        const currentIndex = profiles.indexOf(currentProfile);
        const nextIndex = currentIndex === -1
            ? 0
            : (currentIndex + delta + profiles.length) % profiles.length;
        const nextProfile = profiles[nextIndex];

        switchDirection = delta >= 0 ? 1 : -1;

        setProf.command = ["powerprofilesctl", "set", nextProfile];
        setProf.running = true;

        currentProfile = nextProfile;
        Variables.currentProfile = nextProfile;
    }

    Process {
        id: getProf

        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                let profile = data.trim();
                if (profile !== "") {
                    powerProfiles.switchDirection = 1;
                    powerProfiles.currentProfile = profile;
                    Variables.currentProfile = profile;
                }
            }
        }
    }

    Process {
        id: setProf
    }

    Timer {
        interval: Variables.profilePoll
        running: !Variables.systemHidden && !Variables.lockScreen
        triggeredOnStart: true
        onTriggered: powerProfiles.refresh()
    }

    Connections {
        target: Variables

        function onSystemHiddenChanged() {
            if (!Variables.systemHidden)
                powerProfiles.refresh();
        }

        function onLockScreenChanged() {
            if (!Variables.lockScreen && !Variables.systemHidden)
                powerProfiles.refresh();
        }
    }

    Item {
        id: iconClip
        anchors.fill: parent
        anchors.margins: Variables.borderWidth
        clip: true

        Text {
            id: profileIcon
            width: iconClip.width
            height: iconClip.height
            x: 0
            y: 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: powerProfiles.profileIcons[powerProfiles.displayedProfile] || ""
            color: Variables.iconColor
            font.pixelSize: Variables.fontSize * 0.9

            SequentialAnimation {
                id: modeSwitchAnim

                ParallelAnimation {
                    NumberAnimation {
                        target: profileIcon
                        property: "y"
                        to: -powerProfiles.switchDirection * (iconClip.height * 0.55)
                        duration: Variables.fadeAnimation * 0.4
                        easing.type: Easing.InCubic
                    }
                    NumberAnimation {
                        target: profileIcon
                        property: "opacity"
                        to: 0.0
                        duration: Variables.fadeAnimation * 0.4
                        easing.type: Easing.InCubic
                    }
                }

                ScriptAction {
                    script: {
                        powerProfiles.displayedProfile = powerProfiles.currentProfile;
                        profileIcon.y = powerProfiles.switchDirection * (iconClip.height * 0.55);
                    }
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: profileIcon
                        property: "y"
                        to: 0
                        duration: Variables.fadeAnimation * 0.65
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: profileIcon
                        property: "opacity"
                        to: 1.0
                        duration: Variables.fadeAnimation * 0.65
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    MouseArea {
        id: actionMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                cycleProfile(-1);
            else
                cycleProfile(1);
        }
    }
}