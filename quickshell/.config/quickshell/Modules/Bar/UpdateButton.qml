import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../../"
import "./"

Rectangle {
    id: updateButton

    Layout.alignment: Qt.AlignTop
    Layout.topMargin: Variables.topMargin
    Layout.leftMargin: -(Variables.topMargin)
    
    implicitHeight: Variables.circleHeight * 1.7
    implicitWidth: Variables.circleWidth * 1.7
    color: Variables.uiColor
    radius: Variables.radius
    border.color: Variables.borderColor
    border.width: Variables.borderWidth

    Text {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "󰣇"
        color: Variables.iconColor
        font.pixelSize: Variables.fontSize
    }

    Process {
        id: updateProc

        command: ["ghostty", "-e", "sh", "-c", "sudo pacman -Syu && notify-send --app-name=$USER --icon=pamac-updater 'System is up to date' 'All packages have been successfully checked and updated.'; read -p 'Press enter to exit...'"]
    }

        MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!updateProc.running) {
                updateProc.running = true
            }
        }
    }
}