import QtQuick
import QtQuick.Controls
import "../"

Button {
    id: activateLinuxToggle

    contentItem: Text {
        text: Variables.activateLinux ? "󰶐" : "󰍹"
        font.pixelSize: Variables.fontSize * 2
        color: Variables.activateLinux ? Variables.iconColor : Variables.uiColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: 64
        implicitHeight: 64
        radius: Variables.radius
        color: Variables.activateLinux ? Variables.uiColor : Variables.iconColor
        border.color: Variables.activateLinux ? Variables.iconColor : Variables.uiColor
        border.width: Variables.borderWidth

        Behavior on color {
            ColorAnimation{ duration: Variables.animationDurationUI}
        } 
    }

    onClicked: {

        if (!Variables.activateLinux) {
            Variables.activateLinux = true
        }
        else {
            Variables.activateLinux = false
        }
    }
}