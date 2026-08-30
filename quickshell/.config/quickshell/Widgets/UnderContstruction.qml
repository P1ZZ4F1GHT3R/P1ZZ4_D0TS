import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import "../"

    
Rectangle {

    Layout.fillWidth: true
    implicitHeight: test.implicitHeight + (Variables.spacing * 2)
    radius: Variables.radius
    color: Variables.backgroundColorUI
    border.color: Variables.borderColor
    border.width: Variables.borderWidth

    Text{id: test; text: "Under Construction"; color: Variables.textColor; font.pixelSize: Variables.fontSize; anchors.centerIn: parent}
}