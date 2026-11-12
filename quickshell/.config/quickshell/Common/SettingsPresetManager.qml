import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

RowLayout {
    id: root
    spacing: Variables.spacing
    implicitWidth: parent ? parent.width : 300
    implicitHeight: Variables.settingsPresetManagerHeight

    property string label: ""
    property string description: ""

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
            text: root.description
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: Variables.fontSize * 0.68
            color: Variables.textColor
            opacity: 0.78
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Variables.settingsControlGap

        RowLayout {
            Layout.fillWidth: true
            spacing: Variables.settingsControlGap

            TextField {
                id: nameField
                Layout.preferredWidth: Variables.settingsPresetNameWidth
                Layout.preferredHeight: Variables.settingsPresetFieldHeight
                text: Variables.customPresetName
                placeholderText: "Preset name"
                placeholderTextColor: Variables.textColor
                selectByMouse: true
                color: Variables.textColor
                font.pixelSize: Variables.fontSize * 0.75
                leftPadding: Variables.settingsFieldHorizontalPadding
                rightPadding: Variables.settingsFieldHorizontalPadding
                onTextEdited: Variables.customPresetName = text

                background: Rectangle {
                    color: Variables.uiColor
                    radius: Variables.settingsInputRadius
                    border.color: nameField.activeFocus ? Variables.iconColor : Variables.borderColor
                    border.width: Variables.borderWidth
                }

                SettingsToolTip {
                    visible: nameField.hovered && !nameField.activeFocus
                    text: "Name this preset. Saving the same name updates its glyphs."
                }
            }

            TextField {
                id: glyphField
                Layout.fillWidth: true
                Layout.preferredHeight: Variables.settingsPresetFieldHeight
                text: Variables.customPasswordPreset
                placeholderText: "Mask glyphs, e.g. ◇◆○"
                placeholderTextColor: Variables.textColor
                selectByMouse: true
                color: Variables.textColor
                font.pixelSize: Variables.fontSize * 0.75
                leftPadding: Variables.settingsFieldHorizontalPadding
                rightPadding: Variables.settingsFieldHorizontalPadding
                onTextEdited: Variables.customPasswordPreset = text

                background: Rectangle {
                    color: Variables.uiColor
                    radius: Variables.settingsInputRadius
                    border.color: glyphField.activeFocus ? Variables.iconColor : Variables.borderColor
                    border.width: Variables.borderWidth
                }

                SettingsToolTip {
                    visible: glyphField.hovered && !glyphField.activeFocus
                    text: "Characters used randomly to mask password input."
                }
            }

            Rectangle {
                id: saveButton
                Layout.preferredWidth: Variables.settingsPresetSaveWidth
                Layout.preferredHeight: Variables.settingsPresetFieldHeight
                radius: Variables.barRadius
                color: saveMouse.containsMouse ? Variables.iconColor : Variables.backgroundColorUI
                border.color: saveMouse.containsMouse ? Variables.buttonColor : Variables.borderColor
                border.width: Variables.borderWidth
                activeFocusOnTab: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        if (Variables.saveCustomPasswordPreset())
                            Variables.clearCustomPresetDraft()
                        event.accepted = true
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    font.pixelSize: Variables.fontSize * 0.7
                    font.weight: Font.DemiBold
                    color: saveMouse.containsMouse ? Variables.uiColor : Variables.textColor
                }

                MouseArea {
                    id: saveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (Variables.saveCustomPasswordPreset())
                            Variables.clearCustomPresetDraft()
                        saveButton.forceActiveFocus()
                    }
                }

                SettingsToolTip {
                    visible: saveMouse.containsMouse
                    text: "Save this preset and make it the active password mask."
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Saved masks"
                font.pixelSize: Variables.fontSize * 0.68
                font.weight: Font.DemiBold
                color: Variables.textColor
            }

            Text {
                text: Variables.savedCustomPasswordPresets().length
                    + " preset" + (Variables.savedCustomPasswordPresets().length === 1 ? "" : "s")
                font.pixelSize: Variables.fontSize * 0.64
                color: Variables.textColor
                opacity: 0.78
            }
        }

        ListView {
            id: savedPresets
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Variables.settingsControlTextSpacing
            model: Variables.savedCustomPasswordPresets()

            delegate: Rectangle {
                id: presetRow
                required property var modelData

                readonly property string presetId: "custom:" + presetRow.modelData.name
                readonly property bool isActive: Variables.activePasswordPreset === presetId
                readonly property bool isRowHovered: editMouse.containsMouse || rowDeleteMouse.containsMouse
                readonly property int deleteButtonSize: Math.max(
                    14,
                    Math.min(
                        Variables.settingsPresetDeleteSize > 0
                            ? Variables.settingsPresetDeleteSize - Variables.settingsControlTextSpacing * 2
                            : Math.round(height * 0.64),
                        Math.round(height * 0.64)
                    )
                )

                function deletePreset() {
                    const wasActive = presetRow.isActive
                    const previousActive = Variables.activePasswordPreset
                    const draftMatchesDeleted = Variables.customPresetName === presetRow.modelData.name

                    Variables.selectPasswordPreset(presetRow.presetId)
                    Variables.removeActiveCustomPasswordPreset()

                    if (wasActive || draftMatchesDeleted)
                        Variables.clearCustomPresetDraft()

                    if (!wasActive && previousActive && previousActive !== presetRow.presetId)
                        Variables.selectPasswordPreset(previousActive)
                }

                width: ListView.view.width
                height: Variables.settingsPresetListRowHeight
                radius: Variables.barRadius
                color: presetRow.isRowHovered || presetRow.isActive
                    ? Variables.iconColor : Variables.uiColor
                border.color: presetRow.isRowHovered || presetRow.isActive
                    ? Variables.buttonColor : Variables.borderColor
                border.width: 1
                activeFocusOnTab: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        Variables.selectPasswordPreset(presetRow.presetId)
                        event.accepted = true
                    }
                }

                MouseArea {
                    id: editMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Variables.selectPasswordPreset(presetRow.presetId)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Variables.settingsFieldHorizontalPadding
                    anchors.rightMargin: Math.max(
                        Variables.settingsControlTextSpacing,
                        Math.round((presetRow.height - presetRow.deleteButtonSize) / 2)
                    )
                    spacing: Variables.settingsControlGap

                    Text {
                        Layout.preferredWidth: Variables.settingsPresetNameWidth
                        text: presetRow.modelData.name
                        font.pixelSize: Variables.fontSize * 0.68
                        font.weight: Font.DemiBold
                        color: presetRow.isRowHovered || presetRow.isActive ? Variables.uiColor : Variables.textColor
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: presetRow.modelData.glyphs
                        font.pixelSize: Variables.fontSize * 0.72
                        color: presetRow.isRowHovered || presetRow.isActive ? Variables.uiColor : Variables.textColor
                        opacity: 0.82
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        id: rowDelete
                        Layout.preferredWidth: presetRow.deleteButtonSize
                        Layout.preferredHeight: presetRow.deleteButtonSize
                        Layout.alignment: Qt.AlignVCenter
                        radius: Math.max(3, Variables.barRadius - 2)
                        color: rowDeleteMouse.containsMouse
                            ? Variables.buttonColor
                            : (presetRow.isRowHovered || presetRow.isActive ? "transparent" : Variables.backgroundColorUI)
                        border.color: rowDeleteMouse.containsMouse
                            ? Variables.buttonColor
                            : (presetRow.isRowHovered || presetRow.isActive ? Variables.uiColor : Variables.borderColor)
                        border.width: 1
                        activeFocusOnTab: true

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                presetRow.deletePreset()
                                event.accepted = true
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            font.pixelSize: Variables.fontSize * 0.72
                            font.weight: Font.Bold
                            color: rowDeleteMouse.containsMouse || presetRow.isRowHovered || presetRow.isActive
                                ? Variables.uiColor
                                : Variables.textColor
                        }

                        MouseArea {
                            id: rowDeleteMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                presetRow.deletePreset()
                                rowDelete.forceActiveFocus()
                            }
                        }

                        SettingsToolTip {
                            visible: rowDeleteMouse.containsMouse
                            text: "Delete “" + presetRow.modelData.name + "”."
                        }
                    }
                }

                SettingsToolTip {
                    visible: editMouse.containsMouse && !rowDeleteMouse.containsMouse
                    text: "Load “" + presetRow.modelData.name + "” into the editor above."
                }
            }

            Text {
                anchors.centerIn: parent
                visible: savedPresets.count === 0
                text: "No saved masks yet"
                font.pixelSize: Variables.fontSize * 0.68
                color: Variables.textColor
                opacity: 0.7
            }
        }
    }

    Connections {
        target: Variables

        function onCustomPresetNameChanged() {
            if (nameField.text !== Variables.customPresetName)
                nameField.text = Variables.customPresetName
        }

        function onCustomPasswordPresetChanged() {
            if (glyphField.text !== Variables.customPasswordPreset)
                glyphField.text = Variables.customPasswordPreset
        }
    }
}