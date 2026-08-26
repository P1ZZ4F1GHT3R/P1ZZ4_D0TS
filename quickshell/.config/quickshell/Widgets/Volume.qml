import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../"

Rectangle {
    id: root

    width: 50 
    height: 200
    radius: Variables.radius
    color: Variables.backgroundColorUI


    property var audioNode: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    ColumnLayout {

        anchors{
            fill: parent
            topMargin: Variables.topMargin * 2
            bottomMargin: Variables.topMargin * 2
        }

        spacing: Variables.spacing

        Slider {
            id: volSlider

            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            
            orientation: Qt.Vertical
            from: 0.0
            to: 1.0 

            value: root.audioNode ? root.audioNode.volume : 0.0

            onMoved: {
                if (root.audioNode) {
                    root.audioNode.volume = value
                }
            }

            background: Rectangle {
                x: volSlider.leftPadding + volSlider.availableWidth / 2 - width / 2
                y: volSlider.topPadding
                implicitWidth: 6
                implicitHeight: 200
                width: implicitWidth
                height: volSlider.availableHeight
                radius: Variables.radius
                color: Variables.iconColor

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: volSlider.visualPosition * parent.height
                    y: height - parent.height
                    color: Variables.uiColor
                    radius: Variables.radius
                }
            }

            handle: Rectangle {
                x: volSlider.leftPadding + volSlider.availableWidth / 2 - width / 2
                y: volSlider.topPadding + volSlider.visualPosition * (volSlider.availableHeight - height)
                implicitWidth: 16
                implicitHeight: 16
                radius: Variables.circleRadius
                color: Variables.textColor
                opacity: volSlider.pressed ? 0.85 : 1.0
            }
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            text: (root.audioNode && root.audioNode.muted) ? "" : ""

            contentItem: Text {
                text: parent.text
                font.pixelSize: Variables.fontSize
                color: (root.audioNode && root.audioNode.muted) ? Variables.iconColor : Variables.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: Variables.radius
                color: Variables.uiColor
                border.color: (root.audioNode && root.audioNode.muted) ? Variables.iconColor : Variables.textColor
                opacity: parent.down ? 0.85 :  1.0
            }
            
            onClicked: {
                if (root.audioNode) {
                    root.audioNode.muted = !root.audioNode.muted
                }
            }
        }
    }

    MouseArea {
    anchors.fill: parent
    onPressed: (mouse) => mouse.accepted = false
    onWheel: (wheel) => {
        if (!root.audioNode) return;
        let step = 0.02; 
        let delta = wheel.angleDelta.y > 0 ? step : -step;
        root.audioNode.volume = Math.max(volSlider.from, Math.min(volSlider.to, root.audioNode.volume + delta));
    }
}
}