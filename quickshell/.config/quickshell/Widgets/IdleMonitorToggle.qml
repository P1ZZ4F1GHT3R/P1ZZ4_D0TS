import QtQuick
import QtQuick.Controls
import "../"

Button {
    id: idleMonitorToggle

    padding: 0

    contentItem: Text {
        text: Variables.idleMonitor ? "󰅶" : "󰛊"
        font.pixelSize: Variables.fontSize * 2
        color: Variables.idleMonitor ? Variables.iconColor : Variables.uiColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: Variables.toggleSize
        implicitHeight: Variables.toggleSize
        radius: Variables.radius
        color: Variables.idleMonitor ? Variables.uiColor : Variables.iconColor
        border.color: Variables.idleMonitor ? Variables.iconColor : Variables.uiColor
        border.width: Variables.borderWidth

        Behavior on color {
            ColorAnimation{ duration: Variables.animationDurationUI}
        } 
    }

    onClicked: {
        Variables.idleMonitor = !Variables.idleMonitor
    }   
}
