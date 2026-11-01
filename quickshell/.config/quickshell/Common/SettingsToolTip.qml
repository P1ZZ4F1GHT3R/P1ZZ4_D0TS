import QtQuick
import QtQuick.Controls
import "../"

ToolTip {
    id: root
    delay: 650
    timeout: 5000
    focus: false
    modal: false
    padding: Variables.settingsControlGap
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent | Popup.CloseOnReleaseOutsideParent

    contentItem: Text {
        text: root.text
        color: Variables.textColor
        font.pixelSize: Variables.fontSize * 0.68
        wrapMode: Text.WordWrap
        width: Variables.settingsSidebarWidth * 1.45
    }

    background: Rectangle {
        color: Variables.backgroundColorUI
        radius: Variables.barRadius
        border.color: Variables.iconColor
        border.width: 1
        opacity: 0.98
    }
}
