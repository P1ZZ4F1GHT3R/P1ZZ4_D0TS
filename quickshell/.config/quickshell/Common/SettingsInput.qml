import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

RowLayout {
    id: root
    spacing: Variables.spacing
    implicitWidth: parent ? parent.width : 300
    implicitHeight: Variables.settingsControlHeight

    property string label: ""
    property string description: ""
    property string textValue: ""
    property bool hexColor: false
    signal valueChanged(string newValue)

    ColumnLayout {
        Layout.preferredWidth: Variables.settingsControlLabelWidth
        Layout.maximumWidth: Variables.settingsControlLabelMaxWidth
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

    RowLayout {
        Layout.fillWidth: true
        spacing: Variables.settingsControlGap

        TextField {
            id: inputField
            text: root.textValue
            Layout.fillWidth: true
            Layout.preferredHeight: Variables.settingsFieldHeight
            font.pixelSize: Variables.fontSize * 0.82
            color: Variables.textColor
            selectedTextColor: Variables.uiColor
            selectionColor: Variables.iconColor
            verticalAlignment: Text.AlignVCenter
            leftPadding: Variables.settingsFieldHorizontalPadding
            rightPadding: Variables.settingsFieldHorizontalPadding
            selectByMouse: true
            placeholderText: root.hexColor ? "#000000" : ""
            validator: RegularExpressionValidator {
                regularExpression: root.hexColor ? /^#[0-9a-fA-F]{0,8}$/ : /.*/
            }

            background: Rectangle {
                color: Variables.uiColor
                radius: Variables.settingsInputRadius
                border.color: inputField.activeFocus ? Variables.iconColor : Variables.borderColor
                border.width: Variables.borderWidth

                Behavior on border.color {
                    ColorAnimation { duration: Variables.fadeAnimation }
                }
            }

            onEditingFinished: root.valueChanged(text)

            SettingsToolTip {
                visible: inputField.hovered && !inputField.activeFocus
                text: root.hexColor
                    ? "Enter a hexadecimal colour such as #000000, then press Enter or click away to save."
                    : "Enter a value for " + root.label + ", then press Enter or click away to save."
            }
        }
    }
}
