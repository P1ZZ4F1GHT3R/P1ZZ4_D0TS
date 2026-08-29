import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../"

Rectangle {
    id: updateButton

    Layout.alignment: Qt.AlignTop
    Layout.topMargin: Variables.borderWidth * 4 + Variables.topMargin
    Layout.leftMargin: -(Variables.topMargin)
    
    implicitHeight: Variables.circleHeight * 1.3
    implicitWidth: Variables.circleWidth * 1.3
    color: Variables.uiColor
    radius: Variables.radius
    border.color: Variables.borderColor
    border.width: Variables.borderWidth
    opacity: actionMouse.containsMouse ? 0.85 : 1
    visible: !Variables.workspacesHidden

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

        command: ["ghostty", "-e", "sh", "-c", "sudo pacman -Syu --noconfirm && notify-send --app-name=$USER --icon=pamac-updater 'System is up to date' 'All packages have been successfully checked and updated.'; read -p 'Press enter to exit...'"]
    }

        MouseArea {
            id: actionMouse
            
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!updateProc.running) {
                    updateProc.running = true
                }
            }
    }
}