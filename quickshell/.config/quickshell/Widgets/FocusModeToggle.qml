import QtQuick
import QtQuick.Controls
import "../"

Button {
    id: focusModeToggle

    padding: 0

    contentItem: Text {
        text: Variables.focusMode ? "󰒲" : "󰒳"
        font.pixelSize: Variables.fontSize * 2
        color: !Variables.focusMode ? Variables.iconColor : Variables.uiColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: Variables.toggleSize
        implicitHeight: Variables.toggleSize
        radius: Variables.radius
        color: !Variables.focusMode ? Variables.uiColor : Variables.iconColor
        border.color: !Variables.focusMode ? Variables.iconColor : Variables.uiColor
        border.width: Variables.borderWidth

        Behavior on color {
            ColorAnimation { duration: Variables.animationDurationUI }
        } 
    }

    onClicked: {
        Variables.focusMode = !Variables.focusMode
        Variables.notchHidden = Variables.focusMode
        Variables.workspacesHidden = Variables.focusMode
        Variables.systemHidden = Variables.focusMode

        if (Variables.focusMode) {
            focusTimer.restart()
        } else {
            focusTimer.stop()
            Variables.focused = false
        }
    }

    Timer {
        id: focusTimer

        interval: Variables.animationDurationUI
        running: false
        repeat: false
        onTriggered: {
            if (Variables.focusMode) {
                Variables.focused = true
            }
        }
    }   
}