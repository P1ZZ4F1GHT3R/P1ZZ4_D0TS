import QtQuick
import QtQuick.Controls
import "../"

Button {
    id: focusModeToggle

    contentItem: Text {
        text: Variables.focusMode ? "󰒲" : "󰒳"
        font.pixelSize: Variables.fontSize * 2
        color: Variables.focusMode ? Variables.iconColor : Variables.backgroundColorUI
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: 64
        implicitHeight: 64
        radius: Variables.radius
        color: Variables.focusMode ? Variables.backgroundColorUI : Variables.iconColor
        border.color: Variables.focusMode ? Variables.iconColor : Variables.backgroundColorUI
        opacity: parent.down ? 0.85 : 1.0

        Behavior on color {
            ColorAnimation{ duration: Variables.animationDurationUI}
        } 
    }

    onClicked: {
        Variables.focusMode = !Variables.focusMode
    }   
}