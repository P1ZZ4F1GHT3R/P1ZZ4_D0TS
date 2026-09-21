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

        command: [
            "ghostty", "-e", "bash", "-lc",
            "failures=0; " +
            "sudo pacman -Syu --noconfirm || failures=1; " +
            "if command -v hyprpm >/dev/null 2>&1; then hyprpm update || failures=1; else failures=1; fi; " +
            "if command -v zsh >/dev/null 2>&1; then zsh -ic 'source \"${ZSH:-$HOME/.oh-my-zsh}/oh-my-zsh.sh\" && omz update' || failures=1; else failures=1; fi; " +
            "if (( failures == 0 )); then " +
                "notify-send --app-name=system-update --icon=pamac-updater 'System is up to date' 'Pacman, Hyprpm, and Oh My Zsh updates completed.'; " +
            "else " +
                "notify-send --urgency=critical --app-name=system-update --icon=dialog-error 'System update completed with errors' 'One or more update steps failed. Check the terminal.'; " +
            "fi; " +
            "read -r -p 'Press enter to exit...'"
        ]
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
