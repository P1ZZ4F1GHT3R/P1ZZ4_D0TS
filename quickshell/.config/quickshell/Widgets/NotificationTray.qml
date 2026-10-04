import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../" 

Rectangle {
    id: root

    implicitWidth: Variables.notificationTraySize
    implicitHeight: Variables.notificationTraySize
    radius: Variables.radius
    color: Variables.backgroundColorUI
    border.color: Variables.borderColor
    border.width: Variables.borderWidth

    property var daemon 
    property bool isClearingAll: false
    property var expandedGroups: []

    function toggleGroup(groupKey) {
        var next = expandedGroups.slice()
        var idx = next.indexOf(groupKey)
        if (idx === -1) next.push(groupKey)
        else next.splice(idx, 1)
        expandedGroups = next
    }

    RowLayout {
        id: headerLayout
        anchors {
            top: parent.top
            right: parent.right
            left: parent.left
            margins: Variables.topMargin * 2
        }
        spacing: Variables.spacing

        Rectangle {
            id: titleRect
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Variables.uiColor
            radius: Variables.radius

            Text { 
                text: "Notifications"
                color: Variables.textColor
                anchors.centerIn: parent
                font.pixelSize: Variables.fontSize
            }
        }

        Button {
            id: togglePopupsButton
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
                Behavior on color { ColorAnimation { duration: Variables.animationDurationUI } } 
            }

            onClicked: Variables.disablePopups = !Variables.disablePopups
        }

        Rectangle {
            id: closeAllRect
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
                onTriggered: {
                    daemon.clearAll();
                    root.isClearingAll = false; 
                    root.expandedGroups = [];
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
        spacing: Variables.spacing
        clip: true

        model: root.daemon ? root.daemon.groupedNotifications : []

        delegate: Column {
            id: groupColumn
            width: ListView.view.width
            spacing: Variables.spacing / 2

            property var group: modelData
            property bool isExpanded: root.expandedGroups.indexOf(group.key) !== -1

            Repeater {
                model: groupColumn.group.notifications

                delegate: Item {
                    id: delegateWrapper
                    width: groupColumn.width
                    
                    property var notification: modelData
                    property bool isStackTop: !groupColumn.isExpanded && index === 0 && groupColumn.group.notifications.length > 1
                    property int stackCount: groupColumn.group.notifications.length
                    property bool isVisibleInStack: groupColumn.isExpanded || index === 0
                    
                    property real stackOffset: isStackTop ? Math.min(2, stackCount - 1) * (Variables.spacing * 0.8) : 0
                    Behavior on stackOffset { NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI } }
                    
                    height: contentCard.height + stackOffset
                    opacity: isVisibleInStack ? 1.0 : 0.0
                    scale: isVisibleInStack ? 1.0 : 0.95
                    clip: true

                    Behavior on opacity { NumberAnimation { duration: Variables.animationDurationUI } }
                    Behavior on scale { NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI } }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            topMargin: Variables.spacing * 1.6
                        }
                        height: contentCard.height
                        color: Variables.uiColor
                        radius: Variables.radius
                        border.color: Variables.borderColor
                        border.width: Variables.borderWidth
                        visible: delegateWrapper.isStackTop && delegateWrapper.stackCount > 2
                        opacity: 0.85
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            topMargin: Variables.spacing * 0.8
                        }
                        height: contentCard.height
                        color: Variables.uiColor
                        radius: Variables.radius
                        border.color: Variables.borderColor
                        border.width: Variables.borderWidth
                        visible: delegateWrapper.isStackTop && delegateWrapper.stackCount > 1
                        opacity: 0.9
                    }

                    Rectangle {
                        id: contentCard
                        width: parent.width
                        
                        property bool localRemoving: false
                        property bool isRemoving: localRemoving || root.isClearingAll
                        property bool itemExpanded: false
                        
                        height: (isRemoving || !delegateWrapper.isVisibleInStack) ? 0 : contentLayout.implicitHeight + (Variables.spacing * 2)
                        
                        color: Variables.uiColor
                        radius: Variables.radius
                        border.color: Variables.borderColor
                        border.width: Variables.borderWidth
                        clip: true

                        Behavior on height { NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI } }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton && groupColumn.group.notifications.length > 1) {
                                    root.toggleGroup(groupColumn.group.key)
                                } else if (mouse.button === Qt.LeftButton) {
                                    contentCard.itemExpanded = !contentCard.itemExpanded
                                }
                            }
                        }

                        RowLayout {
                            id: contentLayout
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Variables.spacing
                            }
                            spacing: Variables.spacing

                            Rectangle {
                                Layout.preferredWidth: Variables.fontSize * 2
                                Layout.preferredHeight: Variables.fontSize * 2
                                radius: Variables.imgRadius
                                color: "transparent"
                                Layout.alignment: Qt.AlignTop
                                visible: daemon && notification && daemon.notificationImage(notification) !== ""

                                Image {
                                    anchors.fill: parent
                                    source: daemon && notification ? daemon.notificationImage(notification) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        color: Variables.textColor
                                        elide: Text.ElideRight
                                        font.bold: true
                                        font.pixelSize: Variables.fontSize
                                        text: {
                                            if (!daemon || !notification) return "";
                                            let title = daemon.notificationTitle(notification);
                                            let app = daemon.notificationApp(notification);
                                            let stackCountStr = delegateWrapper.isStackTop ? " (" + delegateWrapper.stackCount + ")" : "";
                                            return app + stackCountStr + " - " + title;
                                        }
                                    }

                                    Text {
                                        color: Variables.textColor
                                        opacity: 0.6
                                        font.pixelSize: Variables.fontSize * 0.8
                                        text: daemon && notification ? daemon.notificationTime(notification) : ""
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    color: Variables.textColor
                                    elide: Text.ElideRight
                                    wrapMode: Text.Wrap
                                    maximumLineCount: contentCard.itemExpanded ? 999 : 2
                                    font.pixelSize: Variables.fontSize
                                    text: daemon && notification ? daemon.notificationBody(notification) : ""
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: contentCard.itemExpanded && notification && notification.actions && notification.actions.length > 0
                                    spacing: Variables.spacing / 2

                                    Repeater {
                                        model: parent.visible && notification && notification.actions ? Math.min(notification.actions.length, 2) : 0
                                        
                                        delegate: Rectangle {
                                            required property int index
                                            readonly property var action: notification.actions[index]

                                            Layout.preferredHeight: Variables.circleHeight
                                            Layout.fillWidth: true
                                            radius: Variables.radius
                                            color: Variables.buttonColor
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                color: Variables.textColor
                                                font.pixelSize: Variables.fontSize * 0.9
                                                text: action && action.text ? action.text : ""
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (action) daemon.invokeAction(action, notification)
                                                }
                                            }
                                        }
                                    }
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
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (contentCard.isRemoving) return; 
                                        contentCard.localRemoving = true;
                                        collapsedRemovalTimer.start()
                                    }
                                }

                                Timer {
                                    id: collapsedRemovalTimer
                                    interval: Variables.animationDurationUI
                                    onTriggered: daemon.dismissNotification(notification)
                                }
                            }
                        }
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