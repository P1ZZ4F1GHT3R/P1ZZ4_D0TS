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
    property string currentValue: ""
    property var options: []
    property bool showColorPreview: false
    property color previewColor: "transparent"
    signal valueChanged(string newValue)

    function optionValue(option) {
        return typeof option === "object" ? option.value : option;
    }

    function optionLabel(option) {
        return typeof option === "object" ? option.label : option;
    }

    function optionIndex(value) {
        for (let index = 0; index < options.length; index++) {
            if (optionValue(options[index]) === value)
                return index;
        }
        return 0;
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

    ComboBox {
        id: choice
        Layout.fillWidth: true
        Layout.preferredHeight: Variables.settingsFieldHeight
        model: root.options
        currentIndex: root.optionIndex(root.currentValue)
        font.pixelSize: Variables.fontSize * 0.8
        hoverEnabled: true

        contentItem: Text {
            leftPadding: Variables.settingsFieldHorizontalPadding
            rightPadding: Variables.settingsChoiceTextRightPadding
            text: root.optionLabel(root.options[choice.currentIndex])
            font: choice.font
            color: Variables.textColor
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Text {
            x: choice.width - width - Variables.settingsFieldHorizontalPadding
            y: (choice.height - height) / 2
            text: "⌄"
            font.pixelSize: Variables.fontSize
            color: Variables.iconColor
        }

        background: Rectangle {
            color: Variables.uiColor
            radius: Variables.settingsInputRadius
            border.color: choice.activeFocus ? Variables.iconColor : Variables.borderColor
            border.width: Variables.borderWidth
        }

        delegate: ItemDelegate {
            id: optionDelegate
            width: choice.width
            height: Variables.settingsFieldHeight
            highlighted: choice.highlightedIndex === index
            contentItem: Text {
                text: root.optionLabel(modelData)
                color: optionDelegate.highlighted ? Variables.uiColor : Variables.textColor
                font.pixelSize: Variables.fontSize * 0.8
                verticalAlignment: Text.AlignVCenter
                leftPadding: Variables.settingsFieldHorizontalPadding
            }
            background: Rectangle {
                color: optionDelegate.highlighted ? Variables.iconColor : Variables.uiColor
                border.color: optionDelegate.highlighted ? Variables.buttonColor : "transparent"
                border.width: optionDelegate.highlighted ? 1 : 0
            }
        }

        popup: Popup {
            y: choice.height + Variables.settingsChoicePopupOffset
            width: choice.width
            implicitHeight: contentItem.implicitHeight
            padding: Variables.settingsChoicePopupPadding
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: choice.popup.visible ? choice.delegateModel : null
                currentIndex: choice.highlightedIndex
            }
            background: Rectangle {
                color: Variables.uiColor
                radius: Variables.settingsInputRadius
                border.color: Variables.borderColor
                border.width: Variables.borderWidth
            }
        }

        onActivated: root.valueChanged(root.optionValue(root.options[currentIndex]))

        SettingsToolTip {
            visible: choice.hovered && !choice.popup.visible && !choice.activeFocus
            text: root.showColorPreview
                ? "Choose the Colors.qml palette role used for " + root.label + "."
                : "Choose a value for " + root.label + "."
        }
    }

    Rectangle {
        visible: root.showColorPreview
        Layout.preferredWidth: Variables.settingsColorPreviewSize
        Layout.preferredHeight: Variables.settingsColorPreviewSize
        radius: Variables.settingsColorPreviewRadius
        color: root.previewColor
        border.color: Variables.borderColor
        border.width: Variables.borderWidth
    }
}
