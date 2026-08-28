import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../" 

Rectangle {
    id: root

    radius: Variables.radius
    color: Variables.backgroundColorUI

    property var daemon 
    property var seenNotifs: []
    property bool isClearingAll: false

    RowLayout {
        id: headerLayout

        anchors{
            top: parent.top
            right: parent.right
            left: parent.left
            margins: Variables.topMargin
        }

        spacing: Variables.spacing

        Rectangle {

            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Variables.uiColor
            radius: Variables.radius

            Text { text: "Notifications"; color: Variables.textColor; anchors.centerIn: parent; font.pixelSize: Variables.fontSize}
        }

        Button {
            
            Layout.preferredHeight: Variables.circleHeight * 1.5
            Layout.preferredWidth: Variables.circleWidth * 1.5

            text: Variables.disablePopups ? "" : ""

            contentItem: Text {
                text: parent.text
                font.pixelSize: Variables.fontSize * 1.2
                color: Variables.disablePopups ? Variables.uiColor : Variables.buttonColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            background: Rectangle {
                radius: Variables.circleRadius * 1.5
                color: Variables.disablePopups ? Variables.buttonColor : Variables.uiColor
                border.color: Variables.disablePopups ? Variables.uiColor : Variables.buttonColor
                border.width: Variables.borderWidth

                Behavior on color {
                    ColorAnimation{ duration: Variables.animationDurationUI}
                } 
            }

            onClicked: {
                Variables.disablePopups = !Variables.disablePopups
            }
        }

        Rectangle {

            Layout.alignment: Qt.AlignRight
            
            Layout.preferredHeight: Variables.circleHeight * 1.5
            Layout.preferredWidth: Variables.circleWidth * 1.5
            
            radius: Variables.circleRadius * 1.5
            color: Variables.uiColor
            border.color: Variables.iconColor
            border.width: Variables.borderWidth
            opacity: closeAllMouse.pressed ? 0.85 : 1

            Text { 
                text: ""
                color: Variables.iconColor
                anchors.centerIn: parent
                font.pixelSize: Variables.fontSize * 1.2
            }

            MouseArea {
                id: closeAllMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.isClearingAll || notifList.count === 0) return; 
                    
                    root.isClearingAll = true;
                    clearAllTimer.start();
                }
            }

            Timer {
                id: clearAllTimer
                interval: Variables.animationDurationUI
                repeat: false
                onTriggered: {
                    daemon.clearAll();
                    root.isClearingAll = false; 
                    root.seenNotifs = []; 
                }
            }

        }
    }

    ListView {
        id: notifList

        anchors {
            top: headerLayout.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            
            margins: Variables.topMargin
        }

        spacing: Variables.topMargin
        clip: true

        model: daemon ? daemon.trackedNotifications.values : []

        delegate: Rectangle {
            id: delegateRect
            width: notifList.width
            
            property real targetHeight: contentLayout.implicitHeight + (Variables.spacing * 2)

            property bool isReady: false
            property bool localRemoving: false
            property bool isRemoving: localRemoving || root.isClearingAll
            property bool animationsEnabled: false

            height: (isReady && !isRemoving) ? targetHeight : 0
            opacity: (isReady && !isRemoving) ? 1.0 : 0.0
            scale: (isReady && !isRemoving) ? 1.0 : 0.9
            
            color: Variables.uiColor
            radius: Variables.radius
            clip: true 

            Behavior on height {
                enabled: animationsEnabled
                NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
            }
            Behavior on opacity {
                enabled: animationsEnabled
                NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
            }
            Behavior on scale {
                enabled: animationsEnabled
                NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
            }

            Component.onCompleted: {
                if (root.seenNotifs.indexOf(modelData.id) !== -1) {
                    isReady = true;
                    
                    Qt.callLater(function() {
                        animationsEnabled = true;
                    });
                } else {
                    root.seenNotifs.push(modelData.id);
                    
                    animationsEnabled = true;
                    Qt.callLater(function() {
                        isReady = true;
                    });
                }
            }

            RowLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: Variables.spacing
                spacing: Variables.spacing

                Rectangle {
                    Layout.preferredWidth: Variables.fontSize * 2
                    Layout.preferredHeight: Variables.fontSize * 2
                    radius: Variables.imgRadius
                    color: "transparent"
                    visible: daemon && daemon.notificationImage(modelData) !== ""

                    Image {
                        anchors.fill: parent
                        source: daemon ? daemon.notificationImage(modelData) : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        Layout.fillWidth: true
                        color: Variables.textColor
                        elide: Text.ElideRight
                        font.bold: true
                        font.pixelSize: Variables.fontSize
                        text: daemon ? (daemon.notificationApp(modelData) + " - " + daemon.notificationTitle(modelData)) : ""
                    }

                    Text {
                        Layout.fillWidth: true
                        color: Variables.textColor
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        font.pixelSize: Variables.fontSize
                        text: daemon ? daemon.notificationBody(modelData) : ""
                    }
                }

                Rectangle {
                    Layout.preferredWidth: Variables.circleWidth
                    Layout.preferredHeight: Variables.circleHeight 
                    Layout.alignment: Qt.AlignTop
                    radius: Variables.circleRadius
                    color: Variables.buttonColor

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
                        onClicked: {
                            if (delegateRect.isRemoving) return; 

                            delegateRect.isRemoving = true
                            delegateRect.opacity = 0.0
                            delegateRect.scale = 0.9
                            
                            removalTimer.start()
                        }
                    }

                    Timer {
                        id: removalTimer
                        interval: Variables.animationDurationUI
                        repeat: false
                        onTriggered: daemon.dismissNotification(modelData)
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "A tumbleweed tumbles..."
            color: Variables.textColor
            font.pixelSize: Variables.fontSize
            opacity: 0.5
            visible: notifList.count === 0
        }
    }
}