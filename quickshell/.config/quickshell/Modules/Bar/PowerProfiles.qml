import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../../"
import "./"

Rectangle {
    id: powerProfiles

    implicitHeight: Variables.circleHeight * 1.7
    implicitWidth: Variables.circleWidth * 1.7
    color: Variables.uiColor
    radius: Variables.radius
    border.color: Variables.borderColor
    border.width: Variables.borderWidth

    property string currentProfile: Variables.currentProfile

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
        interval: Variables.systemPoll
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!getProf.running) {
            getProf.running = true;
            }
        }

    }

    Text {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: powerProfiles.profileIcons[powerProfiles.currentProfile] || ""
        color: Variables.iconColor
        font.pixelSize: Variables.fontSize
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: cycleProfile()
    }
}