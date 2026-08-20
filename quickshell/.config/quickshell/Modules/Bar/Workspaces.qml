import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import "../../"
import "./"

Rectangle {

  Layout.alignment: Qt.AlignTop
  implicitHeight: rowLayout.implicitHeight + Variables.height
  implicitWidth: Variables.workspacesHidden ? 5 : rowLayout.implicitWidth + Variables.width
  color: Variables.uiColor
  topLeftRadius: 0
  topRightRadius: 0
  bottomLeftRadius: 0
  bottomRightRadius: Variables.radius
  //border.color: Variables.borderColor
  //border.width: Variables.borderWidth

    readonly property bool hasSpecialWindows: {
        let hasWin = false;
        let windows = Hyprland.toplevels.values;
        for (let i = 0; i < windows.length; i++) {
            let win = windows[i];
            if (win.workspace && win.workspace.name.startsWith("special:")) {
                hasWin = true;
                break;
            }
        }
        return hasWin;
    }

    Behavior on implicitWidth {
        NumberAnimation { id: widthAnim; duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI}
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI}
    }
  
    Shape {
        id: rightConcave

        width: Variables.radius
        height: Variables.radius
        anchors.top: parent.top
        anchors.left: parent.right

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: 0; y: 0 }
            PathLine { x: 0; y: Variables.radius }
            PathArc {
                x: Variables.radius; y: 0
                radiusX: Variables.radius
                radiusY: Variables.radius
                direction: PathArc.Clockwise
            }
            PathLine { x: 0; y: 0 }
        }
    }

    Shape {
        width: Variables.radius
        height: Variables.radius
        anchors.top: parent.bottom
        anchors.left: parent.left

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: 0; y: 0 }
            PathLine { x: 0; y: Variables.radius }
            PathArc {
                x: Variables.radius; y: 0
                radiusX: Variables.radius
                radiusY: Variables.radius
                direction: PathArc.Clockwise
            }
            PathLine { x: 0; y: 0 }
        }
    }

    Rectangle {
        id: focus

        readonly property int activeId: Hyprland.focusedWorkspace?.id ?? 1
        readonly property int targetIndex: activeId - 1
        readonly property bool isOutOfRange: activeId > rowLayout.children.length - 2
        readonly property Item targetItem: (!isOutOfRange && targetIndex >= 0) ? rowLayout.children[targetIndex] : null

        anchors.verticalCenter: parent.verticalCenter 
        x: targetItem ? (rowLayout.x + targetItem.x) - ((width - targetItem.width) / 2) : x
        implicitHeight: Variables.circleHeight
        implicitWidth: Variables.circleWidth
        color: (!isOutOfRange && targetItem) ? Variables.buttonColor : "transparent"
        radius: Variables.circleRadius

        Behavior on x {
        NumberAnimation { duration: Variables.animationDuration; easing.type: Variables.animationType }
        }
    }

    RowLayout{
        id: rowLayout
        anchors {
            fill: parent
            leftMargin: Variables.leftMargin
            rightMargin: Variables.rightMargin
        }
        spacing: Variables.spacing
        
        Repeater {
        model: Variables.workspaceCount

        Text {
            readonly property int wsId: index + 1
            
            readonly property bool isOccupied: {
                let occupied = false;
                let workspaces = Hyprland.workspaces.values; 
                for (let i = 0; i < workspaces.length; i++) {
                    if (workspaces[i].id === wsId) {
                        occupied = true; 
                        break;
                    }
                }
                return occupied;
            }

            text: wsId
            color: isOccupied ? Variables.textColor : Colors.color1
            font.pixelSize: Variables.fontSize
        }
        }

        Rectangle {
            id: specialWorkspace

            anchors.verticalCenter: parent.verticalCenter 
            visible: hasSpecialWindows
            width: Variables.circleWidth
            height: Variables.circleHeight
            color: Variables.borderColor
            radius: Variables.circleRadius
            
            Text {text: "S"; anchors.centerIn: parent}
        }
    }
}


