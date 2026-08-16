import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Io
import Quickshell.Widgets
import "../../"
import "../../Widgets"

Rectangle {
    implicitHeight: notch.implicitHeight + Variables.height
    implicitWidth: Variables.expandedState ? notch.implicitWidth + Variables.width * 3 : notch.implicitWidth + Variables.width
    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: Variables.radius
    bottomRightRadius: Variables.radius
    color: Variables.uiColor
    //border.color: Variables.borderColor
    //border.width: Variables.borderWidth

     Behavior on implicitWidth {
        NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
    }


    MouseArea {
        id: mousearea

        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: hovertimer.start()
        onExited: Variables.expandedState = false, hovertimer.stop()
    }

    Timer {
        id: hovertimer
        interval: Variables.hoverTimer
        running: false
        repeat: false
        triggeredOnStart: false
        onTriggered: Variables.expandedState = true
    }

    RowLayout {
        id: notch

        anchors {
            fill: parent
            leftMargin: Variables.leftMargin
            rightMargin: Variables.rightMargin
        } 

        MprisWidget{
            id: mprisWidget
        }

        ClockWidget {
            id: clockWidget 
            
            Layout.alignment: Qt.AlignHCenter

            visible: !(mprisWidget.activePlayer !== null && Variables.expandedState)
        }

        VisualizerWidget {
            id: visualizerWidget 
            activePlayer: mprisWidget.activePlayer
        }
    }
}