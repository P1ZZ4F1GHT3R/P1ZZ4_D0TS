import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import Quickshell.Services.Pipewire
import QtQuick.Dialogs
import QtCore
import Quickshell.Widgets
import "../"

RowLayout {
    id: userStats

    Layout.fillWidth: parent
    spacing: Variables.spacing

    Scope {
        id: uptimeChecker

        FileView {
            id: uptimeFile
            path: "/proc/uptime"
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: uptimeFile.reload()
        }

        readonly property string uptimeText: {
            if (!uptimeFile.text()) return "Loading..."
            
            const totalSeconds = Math.floor(parseFloat(uptimeFile.text().split(" ")[0]))
            const days = Math.floor(totalSeconds / 86400)
            const hours = Math.floor((totalSeconds % 86400) / 3600)
            const minutes = Math.floor((totalSeconds % 3600) / 60)
            const seconds = Math.floor(totalSeconds % 60)

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

    Settings {
        id: pfpSave
        property url savedPfp: "" 
    }

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
            pfpSave.savedPfp = "file://" + destFile + "?t=" + Date.now()
        }
    }

    ClippingWrapperRectangle {
        id: pfpIcon
        Layout.preferredHeight: Variables.imgHeight
        Layout.preferredWidth: Variables.imgWidth
        radius: Variables.imgRadius
        visible: pfpSave.savedPfp !== ""

        Image{
            anchors.fill: parent
            source: pfpSave.savedPfp
            visible: pfpSave.savedPfp !== ""
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
        height: Variables.imgHeight
        width: Variables.imgWidth
        color: Variables.buttonColor
        radius: Variables.imgRadius
        visible: pfpSave.savedPfp === ""

        Text{ text: "󰀄"; color: Variables.textColor; font.pixelSize: Variables.fontSize; visible: pfpSave.savedPfp === ""; anchors.centerIn: parent }

        MouseArea {
            anchors.fill: parent
            onClicked: imageDialog.open()
            cursorShape: Qt.PointingHandCursor
        }
    }
    Text{ text: Quickshell.env("USER"); color: Variables.textColor; font.pixelSize: Variables.fontSize}
    Text{ text: "-"; color: Variables.textColor; font.pixelSize: Variables.fontSize}
    Text{ text: uptimeChecker.uptimeText; color: Variables.textColor; font.pixelSize: Variables.fontSize}
    Item{ Layout.fillWidth: parent}
}