import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import Quickshell.Services.Pipewire
import QtQuick.Dialogs
import Quickshell.Widgets
import "../"

Rectangle {
    id: root

    implicitWidth: Variables.userWidth
    implicitHeight: Variables.userHeight

    color: Variables.backgroundColorUI
    radius: Variables.radius
    border.color: Variables.borderColor
    border.width: Variables.borderWidth

    Scope {
        id: uptimeChecker

        FileView {
            id: uptimeFile
            path: "/proc/uptime"
            watchChanges: false
        }

        Timer {
            interval: uptimeChecker.totalSeconds < 3600 ? 1000 : 60000
            running: Variables.controlCenter
            repeat: true
            onTriggered: uptimeFile.reload()
        }

        Connections {
            target: Variables

            function onControlCenterChanged() {
                if (Variables.controlCenter)
                    uptimeFile.reload()
            }
        }

        readonly property int totalSeconds: {
            const raw = uptimeFile.text()
            return raw ? Math.floor(parseFloat(raw.split(" ")[0])) : 0
        }

        readonly property string uptimeText: {
            if (!uptimeFile.text()) return "Loading..."
            
            const days = Math.floor(uptimeChecker.totalSeconds / 86400)
            const hours = Math.floor((uptimeChecker.totalSeconds % 86400) / 3600)
            const minutes = Math.floor((uptimeChecker.totalSeconds % 3600) / 60)
            const seconds = Math.floor(uptimeChecker.totalSeconds % 60)

            if (days > 0) {
                return `${days} day${days === 1 ? '' : 's'}, ${hours} hr${hours === 1 ? '' : 's'}`
            } else if (hours > 0) {
                return `${hours} hr${hours === 1 ? '' : 's'}, ${minutes} min${minutes === 1 ? '' : 's'}`
            } else if (minutes > 0) {
                return `${minutes} min${minutes === 1 ? '' : 's'}, ${seconds} sec${seconds === 1 ? '' : 's'}`
            } else {
                return `${seconds} sec${seconds === 1 ? '' : 's'}`
            }
        }
    }

    RowLayout {
        id: userStats

        anchors {
            fill: parent
            leftMargin: Variables.spacing
            rightMargin: Variables.spacing
        }
        spacing: Variables.spacing * 0.75

        FileDialog {
            id: imageDialog
            title: "Choose an Icon Image"
            fileMode: FileDialog.OpenFile 
            nameFilters: ["Image files (*.png *.jpg *.jpeg *.svg)", "All files (*)"]
            
            onAccepted: {
                let cleanPath = selectedFile.toString().replace("file://", "")
                
                copyProcess.sourceFile = cleanPath

                copyProcess.running = true
            }
        }

        Process {
            id: copyProcess

            property string sourceFile: ""
            property string destFile: Quickshell.env("HOME") + "/.config/quickshell/pfp_icon"

            command: ["bash", "-c", `mkdir -p ~/.config/quickshell && cp "${sourceFile}" "${destFile}"`]
            
            running: false 
            
            onExited: {
                Variables.profilePicture = "file://" + destFile + "?t=" + Date.now()
            }
        }

        Item { Layout.fillWidth: true }

        ClippingWrapperRectangle {
            id: pfpIcon
            Layout.preferredHeight: Variables.imgHeight
            Layout.preferredWidth: Variables.imgWidth
            Layout.alignment: Qt.AlignVCenter
            radius: Variables.imgRadius
            visible: Variables.profilePicture !== ""

            Image {
                anchors.fill: parent
                source: Variables.profilePicture
                visible: Variables.profilePicture !== ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false

                MouseArea {
                    anchors.fill: parent
                    onClicked: imageDialog.open()
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        Rectangle {
            Layout.preferredHeight: Variables.imgHeight
            Layout.preferredWidth: Variables.imgWidth
            Layout.alignment: Qt.AlignVCenter
            color: Variables.buttonColor
            radius: Variables.imgRadius
            visible: Variables.profilePicture === ""

            Text {
                text: "󰀄"
                color: Variables.textColor
                font.pixelSize: Variables.fontSize
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                onClicked: imageDialog.open()
                cursorShape: Qt.PointingHandCursor
            }
        }

        Text {
            text: Quickshell.env("USER") + " - " + uptimeChecker.uptimeText
            color: Variables.textColor
            font.pixelSize: Variables.fontSize
            elide: Text.ElideRight
            Layout.maximumWidth: root.width - Variables.imgWidth - Variables.sliderButtonSize - (Variables.spacing * 4)
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            id: settingsButton

            Layout.preferredWidth: Variables.sliderButtonSize
            Layout.preferredHeight: Variables.sliderButtonSize
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: settingsMouse.containsMouse ? Variables.iconColor : Variables.uiColor
            border.color: settingsMouse.containsMouse ? Variables.buttonColor : Variables.borderColor
            border.width: Variables.borderWidth

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            Text {
                anchors.centerIn: parent
                text: "󰒓"
                font.pixelSize: Variables.fontSize
                color: settingsMouse.containsMouse ? Variables.uiColor : Variables.iconColor

                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: settingsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Variables.openSettings()
            }
        }

        Item { Layout.fillWidth: true }

    }
}