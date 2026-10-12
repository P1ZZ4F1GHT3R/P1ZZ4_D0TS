import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../"

Rectangle {
    id: powerProfiles


    Layout.alignment: Qt.AlignTop
    Layout.topMargin: Variables.borderWidth * 6 + Variables.topMargin
    implicitHeight: Variables.circleHeight * 1.3
    implicitWidth: Variables.circleWidth * 1.3
    color: Variables.uiColor
    radius: Variables.radius
    border.color: Variables.borderColor
    border.width: Variables.borderWidth
    opacity: actionMouse.containsMouse ? 0.85 : 1

    property string currentProfile: Variables.currentProfile

    function refresh() {
        if (!getProf.running)
            getProf.running = true
    }

    readonly property var profileIcons: ({
        "performance": "",
        "balanced": "",
        "power-saver": ""
    })

    function cycleProfile() {
        var nextProfile = "balanced";
        
        if (currentProfile === "balanced") {
            nextProfile = "performance";
        } else if (currentProfile === "performance") {
            nextProfile = "power-saver";
        } else if (currentProfile === "power-saver") {
            nextProfile = "balanced";
        }

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
                    PowerProfiles.currentProfile = profile;
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
                powerProfiles.refresh()
        }

        function onLockScreenChanged() {
            if (!Variables.lockScreen && !Variables.systemHidden)
                powerProfiles.refresh()
        }

    }

    Text {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: powerProfiles.profileIcons[powerProfiles.currentProfile] || ""
        color: Variables.iconColor
        font.pixelSize: Variables.fontSize * 0.9
    }

    MouseArea {
        id: actionMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: cycleProfile()
    }
}
