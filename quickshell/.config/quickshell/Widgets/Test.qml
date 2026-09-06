import QtQuick
import QtQuick.Controls
import "../"

Button {
    id: focusModeToggle

    contentItem: Text {
        text: ""
        font.pixelSize: Variables.fontSize * 2
        color: Variables.uiColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: 64
        implicitHeight: 64
        radius: Variables.radius
        color: Variables.uiColor
        border.color: Variables.iconColor
        border.width: Variables.borderWidth

        Behavior on color {
            ColorAnimation{ duration: Variables.animationDurationUI}
        } 
    }

    onClicked: {
    }
}