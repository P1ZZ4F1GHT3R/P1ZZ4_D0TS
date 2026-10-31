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
    property real sliderValue: 0
    property real fromValue: 0
    property real toValue: 100
    signal valueChanged(real newValue)

    Text {
        text: root.label
        Layout.preferredWidth: Variables.scaled(160)
        font.pixelSize: Variables.fontSize * 0.9
        font.weight: Font.Medium
        color: Variables.textColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        from: root.fromValue
        to: root.toValue
        value: root.sliderValue

        onMoved: root.valueChanged(value)

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: Variables.scaled(140)
            implicitHeight: Variables.scaled(6)
            width: slider.availableWidth
            height: implicitHeight
            radius: height / 2
            color: Variables.uiColor
            border.color: Variables.borderColor
            border.width: 1

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                color: Variables.iconColor
                radius: parent.radius
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: Variables.scaled(16)
            implicitHeight: Variables.scaled(16)
            radius: width / 2
            color: Variables.textColor
            border.color: Variables.borderColor
            border.width: Variables.borderWidth
        }
    }

    Rectangle {
        Layout.preferredWidth: Variables.scaled(54)
        Layout.preferredHeight: Variables.scaled(28)
        color: Variables.uiColor
        radius: Variables.barRadius
        border.color: Variables.borderColor
        border.width: Variables.borderWidth

        Text {
            anchors.centerIn: parent
            text: Math.round(slider.value)
            font.pixelSize: Variables.fontSize * 0.8
            color: Variables.textColor
        }
    }
}