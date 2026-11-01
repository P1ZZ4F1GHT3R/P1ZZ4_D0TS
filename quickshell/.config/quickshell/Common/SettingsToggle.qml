import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

RowLayout {
    id: root
    spacing: Variables.spacing
    implicitWidth: parent ? parent.width : 300
    implicitHeight: Variables.settingsToggleControlHeight

    property string label: ""
    property string description: ""
    property bool checkedState: false
    signal valueChanged(bool newValue)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Variables.settingsControlTextSpacing

        Text {
            text: root.label
            Layout.fillWidth: true
            font.pixelSize: Variables.fontSize * 0.9
            font.weight: Font.DemiBold
            color: Variables.textColor
            elide: Text.ElideRight
        }

        Text {
            visible: root.description.length > 0
            text: root.description
            Layout.fillWidth: true
            font.pixelSize: Variables.fontSize * 0.68
            color: Variables.textColor
            opacity: 0.78
            wrapMode: Text.WordWrap
        }
    }

    Switch {
        id: control
        checked: root.checkedState
        hoverEnabled: true
        onCheckedChanged: {
            if (checked !== root.checkedState) {
                root.valueChanged(checked)
            }
        }

        SettingsToolTip {
            visible: control.hovered && !control.activeFocus
            text: "Turn " + root.label + " " + (control.checked ? "off" : "on") + ". " + root.description
        }

        indicator: Rectangle {
            implicitWidth: Variables.settingsToggleTrackWidth
            implicitHeight: Variables.settingsToggleTrackHeight
            x: control.leftPadding
            y: parent.height / 2 - height / 2
            radius: height / 2
            color: control.checked ? Variables.iconColor : Variables.uiColor
            border.color: Variables.borderColor
            border.width: Variables.borderWidth

            Behavior on color {
                ColorAnimation { duration: Variables.fadeAnimation }
            }

            Rectangle {
                x: control.checked ? parent.width - width - Variables.settingsToggleHandleInset : Variables.settingsToggleHandleInset
                y: (parent.height - height) / 2
                width: Variables.settingsToggleHandleSize
                height: Variables.settingsToggleHandleSize
                radius: width / 2
                color: control.checked ? Variables.uiColor : Variables.textColor

                Behavior on x {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
