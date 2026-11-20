import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../"

Rectangle {
    id: updateButton

    readonly property bool isHidden: Variables.workspacesHidden

    Layout.alignment: Qt.AlignTop
    Layout.topMargin: Variables.borderWidth * 6 + Variables.topMargin
    implicitHeight: Variables.circleHeight * 1.3
    implicitWidth: Variables.circleWidth * 1.3
    color: Variables.uiColor
    radius: Variables.radius
    border.color: (actionMouse.containsMouse || updateProc.running) ? Variables.iconColor : Variables.borderColor
    border.width: Variables.borderWidth

    opacity: isHidden ? 0.0 : (actionMouse.containsMouse ? 0.9 : 1.0)
    scale: isHidden ? 0.0 : (actionMouse.pressed ? 0.92 : (actionMouse.containsMouse ? 1.06 : 1.0))
    visible: opacity > 0.001
    enabled: !isHidden

    Behavior on scale {
        NumberAnimation {
            duration: updateButton.isHidden ? Variables.activeDurationUI * 0.5 : Variables.activeDurationUI * 0.64
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

    Text {
        id: iconText
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "󰣇"
        color: Variables.iconColor
        font.pixelSize: Variables.fontSize
        opacity: updateProc.running ? 1.0 : 1.0

        SequentialAnimation on opacity {
            running: updateProc.running
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
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
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!updateProc.running) {
                updateProc.running = true
            }
        }
    }
}