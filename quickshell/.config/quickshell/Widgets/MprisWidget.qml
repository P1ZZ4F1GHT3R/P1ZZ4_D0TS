import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../"   
import "../Modules/Bar"   
            
        
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
        id: musicIcon

        Layout.topMargin: -(Variables.topMargin)
        Layout.preferredHeight: Variables.imgHeight
        Layout.preferredWidth: Variables.imgWidth
        radius: Variables.imgRadius

        opacity: Variables.expandedState || Variables.powerMenu || Variables.notifWidget ? 0.0 : 1.0
        visible: !Variables.expandedState
    
        Behavior on opacity {
            NumberAnimation { duration: Variables.fadeAnimation }
        }

        Image {
            source: mpris.activePlayer ? (mpris.activePlayer.trackArtUrl || "") : ""

            fillMode: Image.PreserveAspectCrop
            visible: source != ""
        }

    }

    ColumnLayout {
        visible: mpris.activePlayer !== null && Variables.expandedState
        opacity: !Variables.expandedState ? 0.0 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: Variables.fadeAnimation }
        }

        Item {
            id: textContainer
            clip: true
            Layout.fillWidth: true
            implicitHeight: trackText.implicitHeight

            Text {
                id: trackText
                text: {
                    const player = mprisWidget?.activePlayer
                    if (!player) return ""
                    return `${player.trackTitle || "Unknown"} - ${player.trackArtist || "Unknown"}`
                }
                color: Variables.textColor
                font.bold: true

                SequentialAnimation on x {
                    running: trackText.text.length > Variables.trackTitleLength && Variables.expandedState === true
                    loops: Animation.Infinite

                    PauseAnimation { duration: 1500 }

                    NumberAnimation {
                        to: -(trackText.implicitWidth - textContainer.width)
                        duration: 4000
                        easing.type: Linear
                    }
                    
                    PauseAnimation { duration: 1500 }
                    
                    NumberAnimation {
                        to: 0
                        duration: 600
                        easing.type: Linear
                    }

                    onRunningChanged: {
                        if (!running) {
                            trackText.x = 0
                            }
                    }
                }
            }
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

                Behavior on width { NumberAnimation { duration: Variables.fadeAnimation } }
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter 
            Layout.topMargin: 10
            spacing: Variables.spacing * 2

            opacity: !Variables.expandedState ? 0.0 : 1.0

            visible: mpris.activePlayer !== null && Variables.expandedState

            Behavior on opacity {
                NumberAnimation { duration: Variables.fadeAnimation }
            } 

            Rectangle {
                width: Variables.circleWidth; height: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.buttonColor
                Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ""; color: Variables.textColor}
                MouseArea {
                    anchors.fill: parent
                    onClicked: mpris.activePlayer && mpris.activePlayer.previous()
                    cursorShape: Qt.PointingHandCursor
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
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Rectangle {
                width: Variables.circleWidth; height: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.buttonColor
                Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ""; color: Variables.textColor }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mpris.activePlayer && mpris.activePlayer.next()
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
    Item { Layout.fillWidth: Variables.expandedState 
    visible: mpris.activePlayer !== null && Variables.expandedState ? true : false
    }
}
