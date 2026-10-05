import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../"

RowLayout {
    id: root

    property var audioNode: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    implicitWidth: osdContent.implicitWidth
    implicitHeight: osdContent.implicitHeight

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    function cancelOsd() {
        osdTimer.stop();
        Variables.volumeOSD = false;
    }

    Timer {
        id: startupDelay
        interval: 1000
        running: true
    }

    Connections {
        target: root.audioNode
        ignoreUnknownSignals: true

        function onVolumeChanged() { root.triggerOsd() }
        function onMutedChanged() { root.triggerOsd() }
    }

    Connections {
        target: Variables
        function onVolumeOSDChanged() {
            if (!Variables.volumeOSD) {
                osdTimer.stop();
            }
        }
    }

    Timer {
        id: osdTimer
        interval: 1500
        onTriggered: {
            Variables.volumeOSD = false;
            Variables.expandedState = Variables.osdPreExpanded;
            Variables.osdPreExpanded = false;
        }
    }

    function triggerOsd() {
        if (startupDelay.running || Variables.lockScreen || Variables.powerMenu) return;

        if (!Variables.volumeOSD && !Variables.brightnessOSD) {
            Variables.osdPreExpanded = Variables.expandedState;
        }

        Variables.brightnessOSD = false;
        Variables.expandedState = false;
        Variables.volumeOSD = true;

        osdTimer.restart();
    }

    RowLayout {
        id: osdContent
        spacing: Variables.spacing

        Text {
            text: (root.audioNode && root.audioNode.muted) ? "" : ""
            font.pixelSize: Variables.fontSize
            color: (root.audioNode && root.audioNode.muted) ? Variables.iconColor : Variables.textColor
            Layout.alignment: Qt.AlignVCenter
        }

        Slider {
            id: osdSlider

            Layout.preferredWidth: Variables.volumeHeight
            Layout.alignment: Qt.AlignVCenter

            from: 0.0
            to: 1.0
            value: root.audioNode ? root.audioNode.volume : 0.0

            onMoved: {
                if (root.audioNode) {
                    root.audioNode.volume = value
                }
                osdTimer.restart()
            }

            background: Rectangle {
                x: osdSlider.leftPadding
                y: osdSlider.topPadding + osdSlider.availableHeight / 2 - height / 2
                implicitWidth: osdSlider.Layout.preferredWidth
                implicitHeight: Variables.sliderTrackWidth
                width: osdSlider.availableWidth
                height: implicitHeight
                radius: Variables.radius
                color: Variables.uiColor

                Rectangle {
                    anchors.left: parent.left
                    height: parent.height
                    width: osdSlider.visualPosition * parent.width
                    color: Variables.borderColor
                    radius: Variables.radius
                }
            }

            handle: Rectangle {
                x: osdSlider.leftPadding + osdSlider.visualPosition * (osdSlider.availableWidth - width)
                y: osdSlider.topPadding + osdSlider.availableHeight / 2 - height / 2
                implicitWidth: Variables.sliderHandleSize
                implicitHeight: Variables.sliderHandleSize
                radius: Variables.circleRadius
                color: Variables.textColor
                opacity: osdSlider.pressed ? 0.85 : 1.0
            }
        }

        Text {
            text: Math.round((root.audioNode ? root.audioNode.volume : 0) * 100) + "%"
            font.pixelSize: Variables.fontSize
            color: Variables.textColor
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: 40
            horizontalAlignment: Text.AlignRight
        }
    }
}