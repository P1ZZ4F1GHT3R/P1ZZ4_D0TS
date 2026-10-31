import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

RowLayout {
    id: root
    spacing: Variables.spacing
    implicitWidth: parent ? parent.width : 300
    implicitHeight: Variables.scaled(40)

    property string label: ""
    property string textValue: ""
    signal valueChanged(string newValue)

    Text {
        text: root.label
        Layout.preferredWidth: Variables.scaled(160)
        font.pixelSize: Variables.fontSize * 0.9
        font.weight: Font.Medium
        color: Variables.textColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    TextField {
        id: inputField
        text: root.textValue
        Layout.fillWidth: true
        Layout.preferredHeight: Variables.scaled(32)
        font.pixelSize: Variables.fontSize * 0.85
        color: Variables.textColor
        selectedTextColor: Variables.uiColor
        selectionColor: Variables.iconColor
        verticalAlignment: Text.AlignVCenter
        leftPadding: Variables.scaled(10)
        rightPadding: Variables.scaled(10)

        background: Rectangle {
            color: Variables.uiColor
            radius: Variables.barRadius
            border.color: inputField.activeFocus ? Variables.iconColor : Variables.borderColor
            border.width: Variables.borderWidth

            Behavior on border.color {
                ColorAnimation { duration: Variables.fadeAnimation }
            }
        }

        onEditingFinished: root.valueChanged(text)
    }
}