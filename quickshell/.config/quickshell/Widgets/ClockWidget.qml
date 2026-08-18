import QtQuick
import "../"

Text {
    id: clockItem

    property bool showSeconds: true
    property string format: "HH:mm"

    text: new Date().toLocaleTimeString(Qt.locale(), showSeconds ? format + ":ss" : format)
    font.pixelSize: Variables.fontSize
    color: Variables.textColor
    opacity: mprisWidget.activePlayer && Variables.expandedState ? 0.0 : 1.0

    Behavior on opacity {
        NumberAnimation { duration: 200 }
    } 


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