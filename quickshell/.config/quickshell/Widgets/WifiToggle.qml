import QtQuick
import QtQuick.Controls
import "../Services"
import "../"

Button {
    id: networkToggle
    padding: 0
    enabled: !ConnectivityService.wifiBusy

    // Display Ethernet icon if connected via cable, otherwise Wi-Fi icon
    property string currentIcon: ConnectivityService.hasEthernet ? "󰈀" : !networkToggle.isActive ? "󰖪" : "󰖩"
    property bool isActive: ConnectivityService.hasEthernet || ConnectivityService.wifiEnabled

    contentItem: Text {
        text: networkToggle.currentIcon
        font.pixelSize: Variables.fontSize * 2
        color: ConnectivityService.hasEthernet ? Variables.iconColor : !networkToggle.isActive ? Variables.iconColor : Variables.uiColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: Variables.toggleSize
        implicitHeight: Variables.toggleSize
        radius: Variables.radius
        color: ConnectivityService.hasEthernet ? Variables.uiColor : !networkToggle.isActive ? Variables.uiColor : Variables.iconColor
        border.color: ConnectivityService.hasEthernet ? Variables.iconColor : !networkToggle.isActive ? Variables.iconColor : Variables.uiColor
        border.width: Variables.borderWidth
        opacity: networkToggle.enabled ? 1 : 0.65
        Behavior on color { ColorAnimation { duration: Variables.animationDurationUI } }
    }

    onClicked: {
        if (!ConnectivityService.hasEthernet) {
            ConnectivityService.setWifiEnabled(!ConnectivityService.wifiEnabled)
        }
    }
}