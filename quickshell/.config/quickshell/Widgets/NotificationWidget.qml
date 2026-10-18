import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell
import "../"

Item {
    id: root

    property var daemon: null
    readonly property var notification: daemon ? daemon.currentPopup : Variables.currentNotif
    property bool expanded: false

    implicitWidth: expanded ? Math.min(notifLayout.implicitWidth, Variables.width * 8) : Variables.width * 5
    implicitHeight: (expanded ? Variables.height + notifLayout.implicitHeight : Math.max(Variables.height * 3, notifLayout.implicitHeight)) + progressBarTrack.height
    Layout.fillWidth: expanded

    Connections {
        target: Variables

        function onNotifWidgetChanged() {
            if (Variables.notifWidget) {
                Variables.expandedState = false
            }
        }
    }

    Connections {
        target: daemon || null
        enabled: daemon !== null
        ignoreUnknownSignals: true

        function onPopupAdded() {
            if (Variables.notifWidget && !root.expanded) {
                progressAnim.restart()
            }
        }

        function onNotificationClosed() {
            if (Variables.notifWidget && !root.expanded) {
                progressAnim.restart()
            }
        }
    }

    RowLayout {
        id: notifLayout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: progressBarTrack.top
        anchors.bottomMargin: Variables.spacing
        spacing: Variables.spacing
        opacity: !Variables.notifWidget ? 0.0 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: Variables.fadeAnimation }
        }

        ClippingWrapperRectangle {
            Layout.preferredWidth: Variables.fontSize * 2
            Layout.preferredHeight: Variables.fontSize * 2
            radius: Variables.imgRadius
            color: Colors.color1
            visible: notification && daemon && daemon.notificationImage(notification) !== ""

            Image {
                anchors.fill: parent
                source: notification && daemon ? daemon.notificationImage(notification) : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            clip: true

            Text {
                Layout.fillWidth: true
                color: Variables.textColor
                elide: Text.ElideRight
                font.bold: true
                font.pixelSize: Variables.fontSize
                text: notification && daemon
                    ? daemon.notificationApp(notification) + " - " + daemon.notificationTitle(notification)
                    : ""
            }

            Text {
                Layout.fillWidth: true
                color: Variables.textColor
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: expanded ? 3 : 2
                font.pixelSize: Variables.fontSize
                text: notification && daemon ? daemon.notificationBody(notification) : ""
            }

            RowLayout {
                Layout.fillWidth: true
                visible: expanded && notification && notification.actions && notification.actions.length > 0
                spacing: Variables.spacing / 2

                Repeater {
                    model: visible ? Math.min(notification.actions.length, 2) : 0

                    Rectangle {
                        id: actionButton

                        readonly property var action: notification.actions[index]

                        Layout.preferredHeight: Variables.height
                        Layout.fillWidth: true
                        radius: Variables.barRadius
                        color: Variables.buttonColor
                        opacity: actionMouse.containsMouse ? 0.85 : 1

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: Variables.notificationActionMargin
                            anchors.rightMargin: Variables.notificationActionMargin
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: Variables.textColor
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pixelSize: Variables.fontSize / 1.3
                            text: actionButton.action ? actionButton.action.text : ""
                        }

                        MouseArea {
                            id: actionMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: daemon.invokeAction(actionButton.action, notification)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: Variables.circleWidth
            Layout.preferredHeight: Variables.circleHeight
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Variables.topMargin * 2
            Layout.rightMargin: Variables.topMargin * 3
            radius: Variables.circleRadius
            color: Variables.buttonColor
            opacity: closeMouse.containsMouse ? 0.85 : 1
            visible: expanded

            Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: Variables.textColor
                text: "X"
                font.bold: true
            }

            MouseArea {
                id: closeMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: daemon.dismissNotification(notification)
            }
        }
    }

    Rectangle {
        id: progressBarTrack

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Variables.borderWidth
        color: "transparent"
        visible: Variables.notifWidget

        Rectangle {
            id: progressBarFill

            height: parent.height
            color: Variables.textColor
            radius: height / 2
        }

        NumberAnimation {
            id: progressAnim

            target: progressBarFill
            property: "width"
            from: progressBarTrack.width
            to: 0
            duration: Variables.notifTimer
            running: Variables.notifWidget
            paused: root.expanded

            onFinished: {
                if (daemon && daemon.currentPopup) {
                    daemon.removePopup(daemon.currentPopup)
                    if (daemon.currentPopup && !root.expanded) {
                        progressAnim.restart()
                    }
                } else {
                    Variables.notifWidget = false
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: root.expanded = true
        onExited: root.expanded = false
    }
}