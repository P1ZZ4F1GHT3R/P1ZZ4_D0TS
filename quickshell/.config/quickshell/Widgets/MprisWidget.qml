import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../"      
            
        
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

        Layout.topMargin: -4
        Layout.preferredHeight: Variables.imgHeight
        Layout.preferredWidth: Variables.imgWidth
        radius: Variables.imgRadius

        Image {
            source: mpris.activePlayer ? (mpris.activePlayer.trackArtUrl || "") : ""

            fillMode: Image.PreserveAspectCrop
            visible: source != ""
        }

    }

    Item {  
        Layout.preferredWidth: Variables.spacing / 2
        visible: mpris.activePlayer !== null && Variables.expandedState ? true : false
    }

    ColumnLayout {
        visible: mpris.activePlayer !== null && Variables.expandedState

        Text {
            text: mpris.activePlayer ? (mpris.activePlayer.trackArtist + " - " + mpris.activePlayer.trackTitle) : ""
            color: Variables.textColor
            font.bold: true
            elide: Text.ElideRight
            width: parent.width - 20
            horizontalAlignment: Text.AlignHCenter
        }
        Rectangle {
            id: progressBarBackground

            Layout.topMargin: Variables.height / 2
            Layout.preferredWidth: Variables.width / 8 * 6
            Layout.preferredHeight: Variables.height / 2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            color: Colors.color9
            radius: Variables.barRadius

            Rectangle {
                id: progressFill

                height: parent.height
                radius: Variables.barRadius
                color: Variables.borderColor

                width: {
                    if (mpris.activePlayer && mpris.activePlayer.length > 0) {
                        return parent.width * (mpris.activePlayer.position / mpris.activePlayer.length)
                    }
                    return 0
                }

                Behavior on width { NumberAnimation { duration: 200 } }
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: Variables.spacing * 2

            visible: mpris.activePlayer !== null && Variables.expandedState 

            Rectangle {
                width: Variables.circleWidth; height: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.buttonColor
                Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ""; color: Variables.textColor}
                MouseArea {
                    anchors.fill: parent
                    onClicked: mpris.activePlayer && mpris.activePlayer.previous()
                }
            }

            Rectangle {
                width: Variables.circleWidth; height: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.buttonColor
            Text { 
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: mpris.activePlayer && mpris.activePlayer.isPlaying ? "" : "" 
                color: Variables.textColor
            }
                MouseArea {
                    anchors.fill: parent
                    onClicked: mpris.activePlayer && mpris.activePlayer.togglePlaying()
                }
            }

            Rectangle {
                width: Variables.circleWidth; height: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.buttonColor
                Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ""; color: Variables.textColor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: mpris.activePlayer && mpris.activePlayer.next()
                }
            }
        }
    }
    Item { Layout.fillWidth: Variables.expandedState 
        visible: mpris.activePlayer !== null && Variables.expandedState ? true : false}
}
