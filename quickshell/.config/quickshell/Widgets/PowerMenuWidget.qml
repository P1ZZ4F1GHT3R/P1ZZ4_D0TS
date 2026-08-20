import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import "../"   

RowLayout {
    id: powermenu

    focus:true
    Component.onCompleted: forceActiveFocus()

    spacing: Variables.spacing * 8  

    property int selectedIndex: 0

    Keys.onLeftPressed: {
        if (selectedIndex > 0) selectedIndex--
        else selectedIndex = 4
    }

    Keys.onRightPressed: {
        if (selectedIndex < repeater.count - 1) selectedIndex ++
        else selectedIndex = 0
    }

    Keys.onReturnPressed: triggerSelected()
    Keys.onEnterPressed: triggerSelected()

    function triggerSelected() {
        let currentAction = repeater.model[selectedIndex].action
        powermenu[currentAction]()
    }

    function lockscreen() {
        Quickshell.execDetached(["qs", "ipc", "call", "PC", "lock"])
    }

    function logout() {
        Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")])
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"])
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"])
    }

    function shutdown() {
        Quickshell.execDetached(["systemctl", "poweroff"])
    }

    Repeater {
        id: repeater

        model: [            
            { icon: "", label: "Lock", action: "lockscreen" },
            { icon: "󰍃", label: "Log Out", action: "logout" },
            { icon: "󰤄", label: "Sleep", action: "suspend" },
            { icon: "", label: "Restart", action: "reboot" },
            { icon: "", label: "Shut Down", action: "shutdown" }
          ]

        Rectangle {

            Layout.preferredWidth: iconText.implicitWidth + Variables.height / 4 * 5
            Layout.preferredHeight: iconText.implicitHeight + Variables.height / 8 * 5
            radius: Variables.radius
            color: powermenu.selectedIndex === index ? Variables.borderColor : "transparent"

            opacity: Variables.powerMenu ? 1.0 : 0.0

            Behavior on opacity{
                NumberAnimation{ duration: Variables.fadeAnimation}
            }

            Behavior on color{
                ColorAnimation {duration: Variables.animationDurationUI}

            }

            Text {
                id: iconText

                text: modelData.icon
                font.pixelSize: Variables.fontSize * 2
                color: Variables.iconColor
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                onClicked: powermenu[modelData.action]()
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: powermenu.selectedIndex = index
            }
        }
    }
}



