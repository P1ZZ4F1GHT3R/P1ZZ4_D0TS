import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Common"
import "../"

Item {
    id: contentRoot

    required property var controller
    property bool expanded: false
    property real launcherHeight: 0

    readonly property real navHiddenOffset: -(Variables.settingsNavWidth + Variables.settingsCanvasInset + Variables.settingsTransitionOffset)
    readonly property real launcherOverlap: Math.max(0, launcherHeight - Variables.frameBorderWidth)
    readonly property real bottomInset: Variables.launcherOpen
        ? Math.max(Variables.settingsCanvasInset, launcherOverlap + Variables.spacing)
        : Variables.settingsCanvasInset

    function focusCurrentCategory() {
        const item = categoryRepeater.itemAt(controller.activeCategory);
        if (item)
            item.forceActiveFocus();
    }

    function scrollToHighlightedSetting() {
        if (!Variables.highlightedSettingKey)
            return;

        const items = controller.categories[controller.activeCategory].settings || [];
        const idx = items.findIndex(entry =>
            (entry.key || entry.type) === Variables.highlightedSettingKey
        );
        if (idx >= 0) {
            settingsList.positionViewAtIndex(idx, ListView.Center);
            highlightClearTimer.restart();
        }
    }

    Timer {
        id: highlightClearTimer
        interval: 1600
        repeat: false
        onTriggered: Variables.highlightedSettingKey = ""
    }

    Keys.onEscapePressed: {
        if (!Variables.launcherOpen)
            Variables.closeSettings();
    }

    onExpandedChanged: {
        if (expanded) {
            closeAnim.stop();
            openAnim.restart();
        } else {
            openAnim.stop();
            closeAnim.restart();
        }
    }

    // Choreographed entrance: navigation rail slides in from the left frame edge,
    // followed slightly later by the main settings card area.
    ParallelAnimation {
        id: openAnim

        NumberAnimation {
            target: navTranslate
            property: "x"
            to: 0
            duration: Variables.activeDurationUI * 0.64
            easing.type: Variables.activeAnimationUI
        }

        NumberAnimation {
            target: navRail
            property: "opacity"
            to: 1.0
            duration: Variables.fadeAnimation
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            PauseAnimation { duration: Variables.settingsContentEnterDelay }

            ParallelAnimation {
                NumberAnimation {
                    target: contentTranslate
                    property: "x"
                    to: 0
                    duration: Variables.activeDurationUI * 0.64
                    easing.type: Variables.activeAnimationUI
                }

                NumberAnimation {
                    target: contentArea
                    property: "opacity"
                    to: 1.0
                    duration: Variables.fadeAnimation
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    // Reversed exit transition: cards fade/slide out while navigation rail retracts left
    ParallelAnimation {
        id: closeAnim

        NumberAnimation {
            target: contentTranslate
            property: "x"
            to: Variables.settingsTransitionOffset
            duration: Variables.fadeAnimation * 0.85
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: contentArea
            property: "opacity"
            to: 0.0
            duration: Variables.fadeAnimation * 0.75
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            PauseAnimation { duration: Variables.settingsContentEnterDelay * 0.5 }

            ParallelAnimation {
                NumberAnimation {
                    target: navTranslate
                    property: "x"
                    to: contentRoot.navHiddenOffset
                    duration: Variables.fadeAnimation
                    easing.type: Easing.InCubic
                }

                NumberAnimation {
                    target: navRail
                    property: "opacity"
                    to: 0.0
                    duration: Variables.fadeAnimation * 0.85
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    // Left category rail aligned with the left inner shell edge
    Rectangle {
        id: navRail

        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: Variables.settingsCanvasInset
            topMargin: Variables.settingsCanvasInset
            bottomMargin: Variables.settingsCanvasInset
        }
        width: Variables.settingsNavWidth
        color: Variables.uiColor
        radius: Variables.radius
        border.color: Variables.borderColor
        border.width: Variables.borderWidth
        opacity: 0.0

        transform: Translate {
            id: navTranslate
            x: contentRoot.navHiddenOffset
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Variables.spacing
            spacing: Variables.settingsSidebarItemSpacing

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Variables.settingsBrandIconSize + Variables.spacing * 2
                Layout.bottomMargin: Variables.settingsSidebarHeaderMargin
                radius: Variables.settingsCategoryRadius
                border.color: Variables.borderColor
                border.width: Variables.borderWidth
                color: Variables.backgroundColorUI

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Variables.settingsBrandGap

                    Rectangle {
                        Layout.preferredWidth: Variables.settingsBrandIconSize
                        Layout.preferredHeight: width
                        radius: width / 2
                        color: Variables.borderColor

                        Text {
                            anchors.centerIn: parent
                            text: "󰒓"
                            color: Variables.uiColor
                            font.pixelSize: Variables.fontSize
                        }
                    }

                    ColumnLayout {
                        spacing: Variables.settingsControlTextSpacing
                        Text {
                            text: "SETTINGS"
                            font.pixelSize: Variables.fontSize * 1.05
                            font.weight: Font.Bold
                            font.letterSpacing: 2.3 * Variables.uiScale
                            color: Variables.textColor
                        }
                        Text {
                            text: "P1ZZ4_D0TS"
                            font.pixelSize: Variables.fontSize * 0.68
                            font.letterSpacing: 2.0 * Variables.uiScale
                            color: Variables.borderColor
                        }
                    }
                }
            }

            Repeater {
                id: categoryRepeater
                model: contentRoot.controller.categories

                delegate: Rectangle {
                    id: categoryButton
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: Variables.settingsCategoryHeight
                    radius: Variables.settingsCategoryRadius
                    color: contentRoot.controller.activeCategory === index ? Variables.backgroundColorUI
                          : categoryHover.containsMouse ? Variables.iconColor : Variables.uiColor
                    border.color: categoryHover.containsMouse ? Variables.buttonColor
                          : contentRoot.controller.activeCategory === index ? Variables.iconColor : Variables.borderColor
                    border.width: Variables.borderWidth
                    activeFocusOnTab: true

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                            contentRoot.controller.focusCategory(categoryButton.index - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                            contentRoot.controller.focusCategory(categoryButton.index + 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            contentRoot.controller.selectCategory(categoryButton.index);
                            event.accepted = true;
                        }
                    }

                    Behavior on color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Variables.settingsCategoryLeftPadding
                        anchors.rightMargin: Variables.settingsCategoryRightPadding
                        spacing: Variables.settingsCategoryRightPadding

                        Text {
                            text: categoryButton.modelData.icon
                            font.pixelSize: Variables.fontSize * 1.15
                            color: categoryHover.containsMouse && contentRoot.controller.activeCategory !== categoryButton.index
                                ? Variables.uiColor : Variables.iconColor
                        }
                        Text {
                            Layout.fillWidth: true
                            text: categoryButton.modelData.name
                            font.pixelSize: Variables.fontSize * 0.85
                            font.weight: contentRoot.controller.activeCategory === index ? Font.DemiBold : Font.Medium
                            color: categoryHover.containsMouse && contentRoot.controller.activeCategory !== categoryButton.index
                                ? Variables.uiColor : Variables.textColor
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: categoryHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            contentRoot.controller.selectCategory(categoryButton.index);
                            categoryButton.forceActiveFocus();
                        }
                    }

                    SettingsToolTip {
                        visible: categoryHover.containsMouse
                        text: "Open " + categoryButton.modelData.subtitle.toLowerCase() + "."
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

// Main scrollable settings card surface, centered on the screen
    Item {
        id: contentArea

        readonly property real minLeftX: Variables.settingsCanvasInset + Variables.settingsNavWidth + (Variables.spacing * 1.5)
        readonly property real maxAvailableWidth: Math.max(0, width - minLeftX - Variables.settingsCanvasInset)

        anchors {
            fill: parent
            topMargin: Variables.settingsCanvasInset
            bottomMargin: contentRoot.bottomInset
        }
        opacity: 0.0

        transform: Translate {
            id: contentTranslate
            x: Variables.settingsTransitionOffset
        }

        Rectangle {
            id: cardSurface
            width: Math.min(contentArea.maxAvailableWidth, Variables.settingsContentMaxWidth)
            height: parent.height
            x: Math.max(contentArea.minLeftX, (parent.width - width) / 2)
            color: Variables.uiColor
            radius: Variables.radius
            border.color: Variables.borderColor
            border.width: Variables.borderWidth
            clip: true

            ListView {
                id: settingsList
                anchors.fill: parent
                anchors.margins: Variables.spacing * 1.5
                clip: true
                spacing: Variables.settingsListSpacing
                model: contentRoot.controller.categories[contentRoot.controller.activeCategory].settings
                topMargin: Variables.settingsListMargin
                bottomMargin: Variables.settingsListMargin

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160 }
                    NumberAnimation { property: "y"; from: Variables.settingsListSpacing; duration: 160; easing.type: Easing.OutCubic }
                }

                delegate: Rectangle {
                    id: settingCard
                    required property var modelData
                    readonly property bool isSearchHighlighted: Variables.highlightedSettingKey !== ""
                        && (settingCard.modelData.key || settingCard.modelData.type) === Variables.highlightedSettingKey

                    width: ListView.view.width
                    height: settingCard.modelData.fillHeight
                            ? ListView.view.height - (Variables.settingsListMargin * 2)
                            : (settingCard.modelData.height || Variables.settingsCardHeight)
                    radius: Variables.settingsCardRadius
                    color: cardMouse.containsMouse ? Variables.iconColor : Variables.backgroundColorUI
                    border.color: (cardMouse.containsMouse || settingCard.isSearchHighlighted)
                        ? Variables.buttonColor : Variables.borderColor
                    border.width: settingCard.isSearchHighlighted ? Variables.borderWidth * 1.5 : Variables.borderWidth

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    SettingsToggle {
                        anchors.fill: parent
                        anchors.leftMargin: Variables.settingsCardPadding
                        anchors.topMargin: Variables.settingsCardPadding
                        anchors.bottomMargin: Variables.settingsCardPadding
                        anchors.rightMargin: Variables.settingsCardPadding + Variables.settingsResetButtonSize + Variables.settingsResetButtonMargin
                        visible: settingCard.modelData.type === "toggle"
                        label: settingCard.modelData.label
                        description: settingCard.modelData.description
                        checkedState: Boolean(Variables[settingCard.modelData.key])
                        onValueChanged: value => contentRoot.controller.setSetting(settingCard.modelData.key, value)
                    }

                    SettingsSlider {
                        anchors.fill: parent
                        anchors.leftMargin: Variables.settingsCardPadding
                        anchors.topMargin: Variables.settingsCardPadding
                        anchors.bottomMargin: Variables.settingsCardPadding
                        anchors.rightMargin: Variables.settingsCardPadding + Variables.settingsResetButtonSize + Variables.settingsResetButtonMargin
                        visible: settingCard.modelData.type === "slider"
                        label: settingCard.modelData.label
                        description: settingCard.modelData.description
                        fromValue: settingCard.modelData.min
                        toValue: settingCard.modelData.max
                        valueFactor: settingCard.modelData.factor || 1
                        valueSuffix: settingCard.modelData.suffix || ""
                        sliderValue: Number(Variables[settingCard.modelData.key])
                        onValueChanged: value => contentRoot.controller.setSetting(settingCard.modelData.key, value)
                    }

                    SettingsInput {
                        anchors.fill: parent
                        anchors.leftMargin: Variables.settingsCardPadding
                        anchors.topMargin: Variables.settingsCardPadding
                        anchors.bottomMargin: Variables.settingsCardPadding
                        anchors.rightMargin: Variables.settingsCardPadding + Variables.settingsResetButtonSize + Variables.settingsResetButtonMargin
                        visible: settingCard.modelData.type === "input"
                        label: settingCard.modelData.label
                        description: settingCard.modelData.description
                        textValue: contentRoot.controller.settingValue(settingCard.modelData.key)
                        hexColor: Boolean(settingCard.modelData.hexColor)
                        onValueChanged: value => contentRoot.controller.setSetting(settingCard.modelData.key, value)
                    }

                    SettingsChoice {
                        anchors.fill: parent
                        anchors.leftMargin: Variables.settingsCardPadding
                        anchors.topMargin: Variables.settingsCardPadding
                        anchors.bottomMargin: Variables.settingsCardPadding
                        anchors.rightMargin: Variables.settingsCardPadding + Variables.settingsResetButtonSize + Variables.settingsResetButtonMargin
                        visible: settingCard.modelData.type === "choice"
                        label: settingCard.modelData.label
                        description: settingCard.modelData.description
                        currentValue: contentRoot.controller.settingValue(settingCard.modelData.key)
                        options: settingCard.modelData.options || []
                        showColorPreview: Boolean(settingCard.modelData.palette)
                        previewColor: settingCard.modelData.palette
                            ? Variables.colorFromSource(contentRoot.controller.settingValue(settingCard.modelData.key))
                            : "transparent"
                        onValueChanged: value => contentRoot.controller.setSetting(settingCard.modelData.key, value)
                    }

                    SettingsPresetManager {
                        anchors.fill: parent
                        anchors.leftMargin: Variables.settingsCardPadding
                        anchors.topMargin: Variables.settingsCardPadding
                        anchors.bottomMargin: Variables.settingsCardPadding
                        anchors.rightMargin: Variables.settingsCardPadding + Variables.settingsResetButtonSize + Variables.settingsResetButtonMargin
                        visible: settingCard.modelData.type === "presetManager"
                        label: settingCard.modelData.label || ""
                        description: settingCard.modelData.description || ""
                    }

                    SettingsProfilePicture {
                        anchors.fill: parent
                        anchors.margins: Variables.settingsCardPadding
                        visible: settingCard.modelData.type === "profilePicture"
                        label: settingCard.modelData.label || ""
                        description: settingCard.modelData.description || ""
                    }

                    SettingsConnectivity {
                        anchors.fill: parent
                        anchors.margins: Variables.settingsCardPadding
                        visible: settingCard.modelData.type === "connectivity"
                    }

                    SettingsActivation {
                        anchors.fill: parent
                        anchors.margins: Variables.settingsCardPadding
                        visible: settingCard.modelData.type === "activation"
                    }

                    Rectangle {
                        id: resetButton
                        visible: settingCard.modelData.type !== "presetManager"
                            && settingCard.modelData.type !== "profilePicture"
                            && settingCard.modelData.type !== "connectivity"
                            && settingCard.modelData.type !== "activation"
                        anchors.right: parent.right
                        anchors.rightMargin: Variables.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        width: Variables.settingsResetButtonSize
                        height: width
                        radius: width / 2
                        opacity: resetButton.isDefault ? 0.0 : (resetMouse.containsMouse ? 1.0 : 0.6)
                        color: resetMouse.containsMouse && !resetButton.isDefault
                            ? Variables.iconColor : Variables.uiColor
                        border.color: resetMouse.containsMouse && !resetButton.isDefault
                            ? Variables.buttonColor : Variables.borderColor
                        border.width: 1

                        readonly property bool isDefault: contentRoot.controller.isSettingDefault(settingCard.modelData.key)
                        activeFocusOnTab: visible

                        Keys.onPressed: event => {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                                    && !resetButton.isDefault) {
                                contentRoot.controller.resetSetting(settingCard.modelData.key);
                                event.accepted = true;
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "↺"
                            font.pixelSize: Variables.fontSize * 0.9
                            color: resetMouse.containsMouse && !resetButton.isDefault
                                ? Variables.backgroundColorUI : Variables.iconColor
                        }

                        MouseArea {
                            id: resetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (!resetButton.isDefault)
                                    contentRoot.controller.resetSetting(settingCard.modelData.key);
                                resetButton.forceActiveFocus();
                            }
                        }

                        SettingsToolTip {
                            visible: resetMouse.containsMouse && !resetButton.isDefault
                            text: "Restore " + settingCard.modelData.label + " to its default value."
                        }

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }
                }
            }
        }
    }
}