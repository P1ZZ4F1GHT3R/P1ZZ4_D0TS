import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../../"
import "./"

Rectangle {
  implicitHeight: rowLayout.implicitHeight + Variables.height
  implicitWidth: rowLayout.implicitWidth + Variables.width
  color: Variables.uiColor
  topLeftRadius: 0
  topRightRadius: 0
  bottomLeftRadius: 0
  bottomRightRadius: Variables.radius
  //border.color: Variables.borderColor
  //border.width: Variables.borderWidth

  Rectangle {
    id: focus

    readonly property int activeId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int targetIndex: activeId - 1
    readonly property bool isOutOfRange: activeId > rowLayout.children.length - 1
    readonly property Item targetItem: (!isOutOfRange && targetIndex >= 0) ? rowLayout.children[targetIndex] : null

    anchors.verticalCenter: parent.verticalCenter 
    x: targetItem ? (rowLayout.x + targetItem.x) - ((width - targetItem.width) / 2) : x
    implicitHeight: Variables.circleHeight
    implicitWidth: Variables.circleWidth
    color: (!isOutOfRange && targetItem) ? Colors.color10 : "transparent"
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
  }
}


