import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick.Effects
import "../"   
import "../Modules"   
            
        
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

   Item {
        id: expandedContainer
        
        visible: mpris.activePlayer !== null && Variables.expandedState
        opacity: !Variables.expandedState ? 0.0 : 1.0

        Layout.fillWidth: true
        Layout.preferredHeight: expandedContent.implicitHeight + (Variables.spacing * 4)

        Behavior on opacity {
            NumberAnimation { duration: Variables.fadeAnimation }
        }

        Rectangle {
            anchors.fill: parent
            radius: Variables.radius
            color: Variables.backgroundColorUI
            border.color: Variables.borderColor
            border.width: Variables.borderWidth

            ClippingWrapperRectangle {
                anchors.fill: parent
                anchors.margins: Variables.borderWidth
                radius: Math.max(0, Variables.radius - Variables.borderWidth)

                Item {
                    anchors.fill: parent

                    Image {
                        id: blurredBgSource
                        source: mpris.activePlayer ? (mpris.activePlayer.trackArtUrl || "") : ""
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        visible: false 
                    }

                    MultiEffect {
                        source: blurredBgSource
                        anchors.fill: parent
                        blurEnabled: true
                        blurMax: 64
                        blur: 0.69 //heh nice
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Variables.borderColor
                        opacity: 0.5
                    }
                }
            }
        }

        RowLayout {
            id: expandedContent

            anchors.fill: parent
            anchors.margins: Variables.spacing * 2
            spacing: Variables.spacing * 2

            ClippingWrapperRectangle {
                Layout.preferredWidth: 128 
                Layout.preferredHeight: 128
                Layout.alignment: Qt.AlignVCenter
                radius: Variables.imgRadius

                Image {
                    source: mpris.activePlayer ? (mpris.activePlayer.trackArtUrl || "") : ""
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                }
            }

            ColumnLayout {
                id: controlsColumn

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Variables.spacing

                Item {
                    id: textContainer

                    clip: true
                    Layout.fillWidth: true
                    implicitHeight: trackText.implicitHeight

                    onWidthChanged: {
                        if (marqueeAnim.running) marqueeAnim.restart()
                    }

                    Text {
                        id: trackText
                        
                        x: (textContainer.width > implicitWidth) ? (textContainer.width - implicitWidth) / 2 : 0

                        text: {
                            const player = mpris.activePlayer
                            if (!player) return ""
                            return `${player.trackTitle || "Unknown"} - ${player.trackArtist || "Unknown"}`
                        }
                        color: Variables.uiColor
                        font.bold: true

                        onImplicitWidthChanged: {
                            if (marqueeAnim.running) marqueeAnim.restart()
                        }

                        SequentialAnimation on x {
                            id: marqueeAnim

                            running: textContainer.width > 0 && trackText.implicitWidth > textContainer.width && Variables.expandedState === true
                                     
                            loops: Animation.Infinite

                            PauseAnimation { duration: 1500 }
                            NumberAnimation {
                                to: -(trackText.implicitWidth - textContainer.width)
                                duration: 3000
                            }
                            PauseAnimation { duration: 1500 }
                            NumberAnimation {
                                to: 0
                                duration: 600
                            }

                            onRunningChanged: {
                                if (!running) {
                                    trackText.x = Qt.binding(function() {
                                        return (textContainer.width > trackText.implicitWidth) ? (textContainer.width - trackText.implicitWidth) / 2 : 0
                                    })
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: uiColor

                    Layout.topMargin: Variables.height / 4
                    Layout.fillWidth: true
                    Layout.preferredHeight: Variables.height / 2
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    color: Variables.uiColor
                    radius: Variables.barRadius

                    Rectangle {
                        id: progressFill
                        height: parent.height
                        radius: Variables.barRadius
                        color: Variables.iconColor
                        width: {
                            if (mpris.activePlayer && mpris.activePlayer.length > 0) {
                                return parent.width * (mpris.activePlayer.position / mpris.activePlayer.length)
                            }
                            return 0
                        }
                        Behavior on width { NumberAnimation { duration: Variables.fadeAnimation } }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Variables.topMargin
                    spacing: Variables.spacing * 4

                    Rectangle {
                        width: Variables.circleWidth; height: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.uiColor

                        Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ""; color: Variables.textColor}

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mpris.activePlayer && mpris.activePlayer.previous()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Rectangle {
                        width: Variables.circleWidth; height: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.iconColor

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
                        width: Variables.circleWidth; height: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.uiColor

                        Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ""; color: Variables.textColor }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mpris.activePlayer && mpris.activePlayer.next()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }
}
