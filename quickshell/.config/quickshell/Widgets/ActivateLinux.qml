import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../"

    
Rectangle { 
    implicitHeight: textColumn.implicitHeight
    implicitWidth: textColumn.implicitWidth

    color: "transparent"

    ColumnLayout {
        id: textColumn

        anchors.fill: parent
        visible: Variables.activateLinux

        Text {text: "Activate Linux"; font.pixelSize: Variables.fontSize * 2; color: Variables.textColor; opacity: 0.5} 
        Text {text: "Go to settings to activate Linux"; font.pixelSize: Variables.fontSize; color: Variables.textColor; opacity: 0.5}
    }
} 