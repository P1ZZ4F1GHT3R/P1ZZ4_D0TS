import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../Services"
import "../" 

Rectangle {
    id: root

    Layout.preferredWidth: Variables.volumeWidth
    Layout.preferredHeight: Variables.volumeHeight
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
                implicitWidth: Variables.sliderTrackWidth
                implicitHeight: Variables.sliderTrackHeight
                width: implicitWidth
                height: brightnessSlider.availableHeight
                radius: Variables.radius
                color: Variables.borderColor

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: brightnessSlider.visualPosition * parent.height
                    y: height - parent.height
                    color: Variables.uiColor
                    radius: Variables.radius
                }
            }

            handle: Rectangle {
                x: brightnessSlider.leftPadding + brightnessSlider.availableWidth / 2 - width / 2
                y: brightnessSlider.topPadding + brightnessSlider.visualPosition * (brightnessSlider.availableHeight - height)
                implicitWidth: Variables.sliderHandleSize
                implicitHeight: Variables.sliderHandleSize
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
                implicitWidth: Variables.sliderButtonSize
                implicitHeight: Variables.sliderButtonSize
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
