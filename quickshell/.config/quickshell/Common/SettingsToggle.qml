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
    property bool checkedState: false
    signal valueChanged(bool newValue)

    Text {
        text: root.label
        Layout.fillWidth: true
        font.pixelSize: Variables.fontSize * 0.9
        font.weight: Font.Medium
        color: Variables.textColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Switch {
        id: control
        checked: root.checkedState
        onCheckedChanged: {
            if (checked !== root.checkedState) {
                root.valueChanged(checked)
            }
        }

        indicator: Rectangle {
            implicitWidth: Variables.scaled(44)
            implicitHeight: Variables.scaled(24)
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
                x: control.checked ? parent.width - width - Variables.scaled(3) : Variables.scaled(3)
                y: (parent.height - height) / 2
                width: Variables.scaled(18)
                height: Variables.scaled(18)
                radius: width / 2
                color: control.checked ? Variables.uiColor : Variables.textColor

                Behavior on x {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}