import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../Services"
import "../" 

Rectangle {
    id: root

    width: 64 
    height: 256
    radius: Variables.radius
    color: Variables.backgroundColorUI
    border.color: Variables.borderColor
    border.width: Variables.borderWidth

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: Variables.topMargin * 2
            bottomMargin: Variables.topMargin * 2
        }

        spacing: Variables.spacing

        Slider {
            id: brightnessSlider

            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            
            orientation: Qt.Vertical
            from: 0.0
            to: 1.0 

            value: BrightnessService.level

            onMoved: {
                BrightnessService.setBrightness(value)
            }

            background: Rectangle {
                x: brightnessSlider.leftPadding + brightnessSlider.availableWidth / 2 - width / 2
                y: brightnessSlider.topPadding
                implicitWidth: 6
                implicitHeight: 200
                width: implicitWidth
                height: brightnessSlider.availableHeight
                radius: Variables.radius
                color: Variables.borderColor

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: brightnessSlider.visualPosition * parent.height
                    y: height - parent.height
                    color: Variables.progressBarBackground
                    radius: Variables.radius
                }
            }

            handle: Rectangle {
                x: brightnessSlider.leftPadding + brightnessSlider.availableWidth / 2 - width / 2
                y: brightnessSlider.topPadding + brightnessSlider.visualPosition * (brightnessSlider.availableHeight - height)
                implicitWidth: 16
                implicitHeight: 16
                radius: Variables.circleRadius
                color: Variables.textColor
                opacity: brightnessSlider.pressed ? 0.85 : 1.0
            }
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            text: ""

            contentItem: Text {
                text: parent.text
                font.pixelSize: Variables.fontSize
                color: Variables.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: Variables.radius
                color: Variables.uiColor
                border.color: Variables.textColor
                opacity: parent.down ? 0.85 : 1.0
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = false
        onWheel: (wheel) => {
            let step = 0.05; 
            let delta = wheel.angleDelta.y > 0 ? step : -step;
            let newValue = Math.max(brightnessSlider.from, Math.min(brightnessSlider.to, BrightnessService.level + delta));
            BrightnessService.setBrightness(newValue);
        }
    }
}