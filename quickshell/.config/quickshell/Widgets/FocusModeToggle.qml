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
            ColorAnimation{ duration: Variables.animationDurationUI}
        } 
    }

    onClicked: {
        Variables.notchHidden = !Variables.notchHidden
        Variables.workspacesHidden = !Variables.workspacesHidden
        Variables.systemHidden = !Variables.systemHidden
        Variables.focusMode = !Variables.focusMode
        if (!Variables.focused) {
            focusTimer.start();
        }
        else {
            Variables.focused = false
        }
    }

    Timer {
        id: focusTimer

        interval: Variables.animationDurationUI
        running: false
        repeat: false
        triggeredOnStart: false
        onTriggered: Variables.focused = true
    }   
}
