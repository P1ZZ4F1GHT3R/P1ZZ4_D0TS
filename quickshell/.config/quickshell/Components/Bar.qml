import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import "../Modules/Bar"
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

    PanelWindow {
        id: bar 

        HyprlandFocusGrab {
            active: Variables.powerMenu
            windows: [ bar ] 
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
}
