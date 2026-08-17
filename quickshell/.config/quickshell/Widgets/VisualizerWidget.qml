import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../"

Item {
    id: visualizer
    
    property var activePlayer: null
    property var audioData: [0, 0, 0, 0]

    visible: activePlayer !== null 
    Layout.preferredWidth: Variables.width / 16 * 7
    Layout.preferredHeight: Variables.height / 2
    Layout.alignment: Qt.AlignVCenter

    Process {
        id: cavaProc
        command: ["sh", "-c", "cava -p ~/.config/cava/config_quickshell"]
        running: visualizer.activePlayer !== null && visualizer.activePlayer.isPlaying
        
        stdout: SplitParser {
            onRead: data => {
                let val = data.trim()
                if (val === "") return
                let parts = val.split(";")
                if (parts.length >= 4) {
                    visualizer.audioData = [
                        (parseInt(parts[0]) || 0) / 1000.0,
                        (parseInt(parts[1]) || 0) / 1000.0,
                        (parseInt(parts[2]) || 0) / 1000.0,
                        (parseInt(parts[3]) || 0) / 1000.0
                    ]
                }
            }
        }
    }

    Row {
        spacing: Variables.spacing / 6
        anchors.bottom: parent.bottom
        height: parent.height

        Repeater {
            model: 4
            Rectangle {
                width: Variables.width / 16
                height: Math.max(2, (visualizer.audioData[index] || 0) * parent.height)
                color: Variables.iconColor
                radius: Variables.barRadius
                anchors.bottom: parent.bottom
            }
        }
    }
}