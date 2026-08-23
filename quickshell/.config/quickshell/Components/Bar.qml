import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Shapes
import Quickshell.Io
import Quickshell.Services.Notifications
import "../Modules"
import "../Services"
import "../Widgets"
import "../"

Scope {
    id: root
    

    NotificationDaemon {
        id: notifDaemon
    }

    PackageUpdateService{
        id: packageUpdateService
    }

    Lockscreen{
        id: lockScreen
    }

    PanelWindow {
        id: topBar 

        HyprlandFocusGrab {
            active: Variables.powerMenu
            windows: [ topBar ] 
        }

        anchors {
            top: true
            left: true
            right: true
        }

        color: "transparent"
        implicitHeight: 150
        exclusiveZone: Variables.exclusiveZone

        mask: Region {
            item: left
            Region { item: center }
            Region { item: right }
        }

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

            Notch {
                notifServer: notifDaemon
            }
        }

        RowLayout {
            id: right

            anchors {
                right: parent.right
            }
            PowerProfiles{}
            Item { Layout.fillWidth: true }
            System {}
        }
    }

    PanelWindow {
        id: sideBar

        anchors {
            right: true
            top: true
            bottom: true
        }

        mask: Region {
            item: controlCenter
        }

        color: "transparent"
        implicitWidth: 350
        exclusiveZone: Variables.exclusiveZoneSide

        ControlCenter{
            id: controlCenter
        }
    }
}
