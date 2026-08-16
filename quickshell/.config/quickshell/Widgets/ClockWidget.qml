import QtQuick
import "../"

Text {
    id: clockItem

    property bool showSeconds: true
    property string format: "HH:mm"

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