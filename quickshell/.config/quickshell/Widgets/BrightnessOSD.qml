import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Services"
import "../"

RowLayout {
    id: root

    implicitWidth: osdContent.implicitWidth
    implicitHeight: osdContent.implicitHeight

    function cancelOsd() {
        osdTimer.stop();
        Variables.brightnessOSD = false;
    }

    Timer {
        id: startupDelay
        interval: 1000
        running: true
    }

    Connections {
        target: BrightnessService
        ignoreUnknownSignals: true

        function onLevelChanged() { root.triggerOsd() }
    }

    Connections {
        target: Variables
        function onBrightnessOSDChanged() {
            if (!Variables.brightnessOSD) {
                osdTimer.stop();
            }
        }
    }

    Timer {
        id: osdTimer
        interval: 1500
        onTriggered: {
            Variables.brightnessOSD = false;
            Variables.expandedState = Variables.osdPreExpanded;
            Variables.osdPreExpanded = false;
        }
    }

    function triggerOsd() {
        if (startupDelay.running || Variables.lockScreen || Variables.powerMenu) return;

        if (!Variables.volumeOSD && !Variables.brightnessOSD) {
            Variables.osdPreExpanded = Variables.expandedState;
        }

        Variables.volumeOSD = false;
        Variables.expandedState = false;
        Variables.brightnessOSD = true;

        osdTimer.restart();
    }

    RowLayout {
        id: osdContent
        spacing: Variables.spacing

        Text {
            text: ""
            font.pixelSize: Variables.fontSize
            color: Variables.textColor
            Layout.alignment: Qt.AlignVCenter
        }

        Slider {
            id: osdSlider

            Layout.preferredWidth: Variables.volumeHeight
            Layout.alignment: Qt.AlignVCenter

            from: 0.0
            to: 1.0
            value: BrightnessService.level

            onMoved: {
                BrightnessService.setBrightness(value)
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
            text: Math.round(BrightnessService.level * 100) + "%"
            font.pixelSize: Variables.fontSize
            color: Variables.textColor
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: 40
            horizontalAlignment: Text.AlignRight
        }
    }
}