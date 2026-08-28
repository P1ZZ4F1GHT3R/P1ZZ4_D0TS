import QtQuick
import QtQuick.Controls
import "../"

Button {
    id: idleMonitorSwitch

    contentItem: Text {
        text: ""
        font.pixelSize: Variables.fontSize * 2
        color: Variables.idleMonitor ? Variables.iconColor : Variables.backgroundColorUI
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: 64
        implicitHeight: 64
        radius: Variables.radius
        color: Variables.idleMonitor ? Variables.backgroundColorUI : Variables.iconColor
        border.color: Variables.idleMonitor ? Variables.iconColor : Variables.backgroundColorUI
        opacity: parent.down ? 0.85 : 1.0

        Behavior on color {
            ColorAnimation{ duration: Variables.animationDurationUI}
        } 
    }

    onClicked: {
        Variables.idleMonitor = !Variables.idleMonitor
    }   
}