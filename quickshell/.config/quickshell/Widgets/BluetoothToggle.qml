import QtQuick
import QtQuick.Controls
import "../Services"
import "../"

Button {
    id: bluetoothToggle
    padding: 0
    enabled: !ConnectivityService.bluetoothBusy

    contentItem: Text {
        text: !ConnectivityService.bluetoothEnabled ? "󰂲" : "󰂯" 
        font.pixelSize: Variables.fontSize * 2
        color: !ConnectivityService.bluetoothEnabled ? Variables.iconColor : Variables.uiColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: Variables.toggleSize
        implicitHeight: Variables.toggleSize
        radius: Variables.radius
        color: !ConnectivityService.bluetoothEnabled ? Variables.uiColor : Variables.iconColor
        border.color: !ConnectivityService.bluetoothEnabled ? Variables.iconColor : Variables.uiColor
        border.width: Variables.borderWidth
        opacity: bluetoothToggle.enabled ? 1 : 0.65
        Behavior on color { ColorAnimation { duration: Variables.animationDurationUI } }
    }

    onClicked: ConnectivityService.setBluetoothEnabled(!ConnectivityService.bluetoothEnabled)
}