import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../"

Item {
    id: visualizer
    
    property var activePlayer: null
    readonly property var audioDataDefault: [0, 0, 0, 0]
    property var audioData: [0, 0, 0, 0]

    Layout.preferredWidth: Variables.width / 16 * 7
    Layout.preferredHeight: Variables.height / 2
    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    opacity: Variables.expandedState || Variables.powerMenu || Variables.notifWidget ? 0.0 : 1.0
    
    Behavior on opacity {
        NumberAnimation { duration: Variables.fadeAnimation }
    } 

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
                    let targetBars = 4
                    let binSize = parts.length / targetBars
                    let newAudioData = []
                    
                    for (let i = 0; i < targetBars; i++) {
                        let start = Math.floor(i * binSize)
                        let end = Math.floor((i + 1) * binSize)
                        let sum = 0
                        let count = 0
                        
                        for (let j = start; j < end && j < parts.length; j++) {
                            sum += parseInt(parts[j]) || 0
                            count++
                        }
                        
                        let avg = count > 0 ? (sum / count) / 600.0 : 0
                        newAudioData.push(avg)
                    }
                    
                    visualizer.audioData = newAudioData
                }
            }
        }
    }

    Connections {
        target: visualizer.activePlayer
        ignoreUnknownSignals: true
        function onIsPlayingChanged() {
            if (!visualizer.activePlayer || !visualizer.activePlayer.isPlaying) {
                Qt.callLater(function() {
                    visualizer.audioData = visualizer.audioDataDefault
                })
            }
        }
    }
    

    Column {
        anchors.centerIn: parent
        spacing: -Variables.visualizerGap
        
        Row {
            spacing: Variables.spacing / 6
            height: visualizer.height
            
            Repeater {
                model: 4
                Rectangle {
                    width: Variables.width / 16
                    height: Math.max(Variables.visualizerMinHeight, (visualizer.audioData[index] || 0) * parent.height)
                    color: Variables.iconColor
                    radius: Variables.barRadius
                    
                    anchors.bottom: parent.bottom
                    
                    Behavior on height {
                        NumberAnimation { 
                            duration: visualizer.activePlayer.isPlaying ? 0 : Variables.animationDurationUI
                            easing.type: Easing.InOutCubic
                        }
                    }
                }
            }
        }
        
        Row {
            spacing: Variables.spacing / 6
            height: visualizer.height 
            
            Repeater {
                model: 4
                Rectangle {
                    width: Variables.width / 16
                    height: Math.max(Variables.visualizerMinHeight, (visualizer.audioData[index] || 0) * parent.height)
                    color: Variables.buttonColor
                    radius: Variables.barRadius
                    
                    anchors.top: parent.top 
                    
                    Behavior on height {
                        NumberAnimation { 
                            duration: visualizer.activePlayer.isPlaying ? 0 : Variables.animationDurationUI
                            easing.type: Easing.InOutCubic
                        }
                    }
                }
            }
        }
    }
}
