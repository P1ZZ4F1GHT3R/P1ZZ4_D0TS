import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../"

RowLayout {
    id: root
    spacing: Variables.settingsControlGap
    implicitWidth: parent ? parent.width : 300
    implicitHeight: Variables.settingsProfilePictureHeight

    property string label: ""
    property string description: ""

    function choosePicture() {
        imageDialog.open()
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
            text: root.description
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: Variables.fontSize * 0.68
            color: Variables.textColor
            opacity: 0.78
        }
    }

    Rectangle {
        id: chooseButton
        Layout.preferredWidth: Variables.settingsActivationButtonWidth * 0.72
        Layout.preferredHeight: Variables.settingsPresetFieldHeight
        radius: Variables.barRadius
        color: chooseMouse.containsMouse ? Variables.iconColor : Variables.uiColor
        border.color: chooseMouse.containsMouse ? Variables.buttonColor : Variables.borderColor
        border.width: Variables.borderWidth
        activeFocusOnTab: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.choosePicture()
                event.accepted = true
            }
        }

        Text {
            anchors.centerIn: parent
            text: copyProcess.running ? "Saving…" : "Choose image"
            font.pixelSize: Variables.fontSize * 0.7
            font.weight: Font.DemiBold
            color: chooseMouse.containsMouse ? Variables.uiColor : Variables.textColor
        }

        MouseArea {
            id: chooseMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !copyProcess.running
            onClicked: {
                root.choosePicture()
                chooseButton.forceActiveFocus()
            }
        }

        SettingsToolTip {
            visible: chooseMouse.containsMouse
            text: "Choose an image for the control-center user card."
        }
    }

    ClippingWrapperRectangle {
        Layout.preferredWidth: Variables.settingsProfilePictureSize
        Layout.preferredHeight: width
        radius: width / 2
        visible: Variables.profilePicture !== ""

        Image {
            anchors.fill: parent
            source: Variables.profilePicture
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
    }

    Rectangle {
        Layout.preferredWidth: Variables.settingsProfilePictureSize
        Layout.preferredHeight: width
        radius: width / 2
        visible: Variables.profilePicture === ""
        color: Variables.buttonColor
        border.color: Variables.borderColor
        border.width: Variables.borderWidth

        Text {
            anchors.centerIn: parent
            text: "󰀄"
            font.pixelSize: Variables.fontSize * 1.15
            color: Variables.textColor
        }
    }

    FileDialog {
        id: imageDialog
        title: "Choose a profile picture"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.svg *.webp)", "All files (*)"]

        onAccepted: {
            copyProcess.sourceFile = selectedFile.toLocalFile()
            copyProcess.running = true
        }
    }

    Process {
        id: copyProcess
        property string sourceFile: ""
        property string destinationFile: Quickshell.env("HOME") + "/.config/quickshell/pfp_icon"
        command: ["cp", sourceFile, destinationFile]

        onExited: {
            Variables.profilePicture = "file://" + destinationFile + "?t=" + Date.now()
        }
    }
}
