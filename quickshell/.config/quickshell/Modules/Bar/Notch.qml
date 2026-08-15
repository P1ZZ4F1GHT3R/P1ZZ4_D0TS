import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Io
import Quickshell.Widgets
import "../../"

Rectangle {
    implicitHeight: notch.implicitHeight + Variables.height
    implicitWidth: hover.hovered ? notch.implicitWidth + Variables.width * 3 : notch.implicitWidth + Variables.width
    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: Variables.radius
    bottomRightRadius: Variables.radius
    color: Variables.uiColor
    //border.color: Variables.borderColor
    //border.width: Variables.borderWidth

     Behavior on implicitWidth {
        NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
    }

    Process {
        id: cavaProc
        command: ["sh", "-c", "cava -p ~/.config/cava/config_quickshell"]
        
        running: mpris.activePlayer !== null && mpris.activePlayer.isPlaying
        
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

    RowLayout {
        id: notch
        anchors {
            fill: parent
            leftMargin: Variables.leftMargin
            rightMargin: Variables.rightMargin
        }
        spacing: Variables.spacing

        RowLayout {
            id: mpris
            
            property var activePlayer: {
                let players = Mpris.players.values;
                for (let i = 0; i < players.length; i++) {
                    let p = players[i];
                    if (p.identity.toLowerCase() === "spotify" || p.desktopEntry.toLowerCase() === "spotify") {
                        return p;
                    }
                }
                return null; 
            }

            visible: mpris.activePlayer !== null
            
            ClippingWrapperRectangle{
              anchors{
                verticalCenter: parent.verticalCenter
              }
              radius: Variables.imgRadius
              implicitHeight: Variables.imgHeight
              implicitWidth: Variables.imgWidth

              Image {
                  source: mpris.activePlayer ? (mpris.activePlayer.trackArtUrl || "") : ""
                  
                  Layout.preferredWidth: Variables.fontSize * 1.5
                  Layout.preferredHeight: Variables.fontSize * 1.5
                  
                  fillMode: Image.PreserveAspectCrop
                  visible: source != ""
              }

            }
        }

        Item { Layout.fillWidth: true }

        Text {
            id: clockItem

            property bool showSeconds: true
            property string format: "HH:mm"
            property string dateFormat: "dddd, MMMM d"

            text: new Date().toLocaleTimeString(Qt.locale(), showSeconds ? format + ":ss" : format)
            font.pixelSize: Variables.fontSize
            color: Variables.textColor

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: clockItem.text = new Date().toLocaleTimeString(
                    Qt.locale(), clockItem.showSeconds ? clockItem.format + ":ss" : clockItem.format
                )
            }
        }

        Item { Layout.fillWidth: true } 

        Item {
            id: visualizer
            
            property var audioData: [0, 0, 0, 0]

            visible: mpris.activePlayer !== null
        
            Layout.preferredWidth: Variables.width / 16 * 7
            Layout.preferredHeight: Variables.height / 2
            Layout.alignment: Qt.AlignVCenter

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
                        radius: 4
                        anchors.bottom: parent.bottom
                    }
                }
            }
        }
    }

    HoverHandler {
        id: hover
    }
}