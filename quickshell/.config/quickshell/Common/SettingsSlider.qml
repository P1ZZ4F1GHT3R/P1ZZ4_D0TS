import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

RowLayout {
    id: root
    spacing: Variables.spacing
    implicitWidth: parent ? parent.width : 300
    implicitHeight: Variables.settingsSliderControlHeight

    property string label: ""
    property string description: ""
    property real sliderValue: 0
    property real fromValue: 0
    property real toValue: 100
    property real valueFactor: 1
    property string valueSuffix: ""
    property real stepSize: 1
    signal valueChanged(real newValue)

    function normalisedValue(rawValue) {
        const value = Number(rawValue)
        if (!isFinite(value))
            return Math.round(slider.value)
        return Math.round(Math.max(fromValue, Math.min(toValue, value)))
    }

    function commitValue(rawValue) {
        const value = normalisedValue(rawValue)
        valueField.text = value.toString()
        root.valueChanged(value * root.valueFactor)
    }

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

    Slider {
        id: slider
        Layout.fillWidth: true
        from: root.fromValue
        to: root.toValue
        value: root.sliderValue / root.valueFactor
        stepSize: root.stepSize
        hoverEnabled: true

        onMoved: root.commitValue(value)

        SettingsToolTip {
            visible: slider.hovered && !slider.pressed && !valueField.activeFocus
            text: "Drag to adjust " + root.label + ", or type an exact value from "
                + Math.ceil(root.fromValue) + " to " + Math.floor(root.toValue) + "."
        }

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: Variables.settingsSliderTrackWidth
            implicitHeight: Variables.settingsSliderTrackHeight
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
            implicitWidth: Variables.settingsSliderHandleSize
            implicitHeight: Variables.settingsSliderHandleSize
            radius: width / 2
            color: Variables.textColor
            border.color: Variables.borderColor
            border.width: Variables.borderWidth

            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            scale: slider.pressed ? 1.2 : 1.0
        }
    }

    RowLayout {
        Layout.preferredWidth: Variables.settingsValueFieldWidth
            + (root.valueSuffix.length > 0 ? Variables.settingsValueSuffixWidth : 0)
        spacing: Variables.settingsControlTextSpacing

        TextField {
            id: valueField
            Layout.preferredWidth: Variables.settingsValueFieldWidth
            Layout.preferredHeight: Variables.settingsValueFieldHeight
            text: Math.round(slider.value).toString()
            font.pixelSize: Variables.fontSize * 0.8
            color: Variables.textColor
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            selectByMouse: true
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator {
                bottom: Math.ceil(root.fromValue)
                top: Math.floor(root.toValue)
            }

            background: Rectangle {
                color: Variables.uiColor
                radius: Variables.settingsInputRadius
                border.color: valueField.activeFocus ? Variables.iconColor : Variables.borderColor
                border.width: Variables.borderWidth
            }

            onEditingFinished: root.commitValue(text)

            SettingsToolTip {
                visible: valueField.hovered && !valueField.activeFocus
                text: "Type an exact value for " + root.label + " from "
                    + Math.ceil(root.fromValue) + " to " + Math.floor(root.toValue) + "."
            }
        }

        Text {
            visible: root.valueSuffix.length > 0
            text: root.valueSuffix.trim()
            font.pixelSize: Variables.fontSize * 0.68
            color: Variables.textColor
            opacity: 0.78
        }
    }
}
