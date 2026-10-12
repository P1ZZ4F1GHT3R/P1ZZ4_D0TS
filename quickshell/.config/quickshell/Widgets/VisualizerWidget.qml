import QtQuick
import QtQuick.Layouts
import "../Services"
import "../"

Item {
    id: visualizer
    
    property var activePlayer: null
    readonly property var audioDataDefault: [0, 0, 0, 0]
    readonly property var audioData: AudioVisualizerService.compactAudioData

    implicitWidth: Variables.width / 16 * 7
    implicitHeight: Variables.height / 2    
    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    opacity: Variables.expandedState || Variables.powerMenu || Variables.notifWidget ? 0.0 : 1.0
    
    Behavior on opacity {
        NumberAnimation { duration: Variables.fadeAnimation }
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
                            duration: visualizer.activePlayer && visualizer.activePlayer.isPlaying ? 0 : Variables.animationDurationUI
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
                            duration: visualizer.activePlayer && visualizer.activePlayer.isPlaying ? 0 : Variables.animationDurationUI
                            easing.type: Easing.InOutCubic
                        }
                    }
                }
            }
        }
    }
}
