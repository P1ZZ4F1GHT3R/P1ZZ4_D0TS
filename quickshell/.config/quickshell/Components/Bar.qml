import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../Modules/Bar"
import "../"

PanelWindow {
    id: bar 

    anchors {
        top: true
        left: true
        right: true
    }

    color: "transparent"
    implicitHeight: 48
    exclusiveZone: Variables.exclusiveZone

    RowLayout {
        id: left

        anchors {
            left: parent.left
        }
        spacing: Variables.spacing

        Workspaces {}

        UpdateButton {}

    }

    RowLayout {
        id: center

        anchors.horizontalCenter: parent.horizontalCenter

            Notch {}
    }

    RowLayout {
        id: right

        anchors {
            right: parent.right
        }
        PowerProfiles{}
        System {}
    }
}