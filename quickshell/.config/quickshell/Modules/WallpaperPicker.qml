import QtQuick
import QtCore
import Quickshell
import Qt.labs.folderlistmodel
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Shapes
import "../"

Rectangle {
    id: root

    readonly property string homePath: Quickshell.env("HOME")
    readonly property string wallpaperDirectory: homePath + "/Pictures/Wallpapers"
    readonly property string previewScript: homePath + "/.config/scripts/theme/theme-preview.sh"
    readonly property string syncScript: homePath + "/.config/scripts/theme/theme-sync.sh"
    readonly property string txtDir: Quickshell.env("HOME") + "/.config/wallpaper/wallpaper.txt"

    implicitWidth: 800
    implicitHeight: Variables.wallpaperPicker ? 250 : 0
    color: Variables.uiColor
    topLeftRadius: Variables.radius
    topRightRadius: Variables.radius

    Behavior on implicitHeight {
        NumberAnimation { duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI}
    }

    function localPath(fileUrl) {
        var path = String(fileUrl || "");
        if (path.indexOf("file://") === 0)
            path = path.substring(7);
        try {
            return decodeURIComponent(path);
        } catch (error) {
            return path;
        }
    }

    function previewCurrentWallpaper() {
        if (!Variables.wallpaperPicker || !wallpaperList.currentItem)
            return;

        Variables.previewPath = wallpaperList.currentItem.imagePath;
        previewTimer.restart();
    }

    Process {
        id: previewProcess
    }

    Process {
        id: applyProcess
    }

    FolderListModel {
        id: wallpaperModel
        folder: "file://" + root.wallpaperDirectory
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false

        onCountChanged: {
            if (count > 0 && wallpaperList.currentIndex <= 0) {
                var middleIndex = Math.floor(count / 2);
                wallpaperList.currentIndex = middleIndex;
                wallpaperList.positionViewAtIndex(middleIndex, ListView.Center);
            }
        }
    }

    Process {
        id: imagePath
        command: ["cat", txtDir]
        running: true 
        
        stdout: StdioCollector {
            onStreamFinished: {
                lockScreen.currentWallpaper = "file://" + this.text.trim();
            }
        }
    }

    Shape {
        id: bottomLeftConcave
        
        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
        
        visible: cornerSize > 0

        width: cornerSize
        height: cornerSize
        anchors.bottom: parent.bottom
        anchors.right: parent.left
        anchors.bottomMargin: Variables.borderWidth * 4

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: bottomLeftConcave.cornerSize; y: bottomLeftConcave.cornerSize }
            PathLine { x: bottomLeftConcave.cornerSize; y: 0 }
            PathArc {
                x: 0; y: bottomLeftConcave.cornerSize
                radiusX: bottomLeftConcave.cornerSize
                radiusY: bottomLeftConcave.cornerSize
                direction: PathArc.Clockwise
            }
            PathLine { x: bottomLeftConcave.cornerSize; y: bottomLeftConcave.cornerSize }
        }
    }

    Shape {
        id: bottomRightConcave

        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
        
        visible: cornerSize > 0
        
        width: cornerSize
        height: cornerSize
        anchors.bottom: parent.bottom
        anchors.left: parent.right
        anchors.bottomMargin: Variables.borderWidth * 4

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: 0; y: bottomRightConcave.cornerSize }
            PathLine { x: 0; y: 0 }
            PathArc {
                x: bottomRightConcave.cornerSize; y: bottomRightConcave.cornerSize
                radiusX: bottomRightConcave.cornerSize
                radiusY: bottomRightConcave.cornerSize
                direction: PathArc.Counterclockwise
            }
            PathLine { x: 0; y: bottomRightConcave.cornerSize }
        }
    }

    ListView {
        id: wallpaperList

        anchors.fill: parent
        anchors.margins: Variables.spacing
        orientation: ListView.Horizontal
        spacing: Variables.spacing
        model: wallpaperModel
        currentIndex: -1
        boundsBehavior: Flickable.StopAtBounds
        focus: Variables.wallpaperPicker
        preferredHighlightBegin: width / 2 - 150
        preferredHighlightEnd: width / 2 + 150
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 100
        clip: true
        
        interactive: true

        onCurrentItemChanged: root.previewCurrentWallpaper()
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (!currentItem || !currentItem.imagePath || applyProcess.running)
                    return;

                previewProcess.running = false;
                applyProcess.command = ["/bin/bash", root.syncScript, currentItem.imagePath];
                applyProcess.running = true;
                Variables.wallpaperPicker = false;
                wallpaperTimer.start();
                
                event.accepted = true;
            }
        }

        delegate: Rectangle {
            id: scrollList

            required property string filePath
            required property int index

            readonly property bool isSelected: ListView.isCurrentItem

            property string imagePath: root.localPath(filePath)

            width: 300
            height: ListView.view.height - 20
            color: scrollList.isSelected ? Variables.borderColor : "transparent"
            border.color: Variables.borderColor
            border.width: scrollList.isSelected ? Variables.borderWidth : 0
            radius: Variables.radius
            clip: true

            ClippingWrapperRectangle {
                anchors.fill: parent
                anchors.margins: scrollList.isSelected ? Math.max(Variables.borderWidth) : 3
                radius: Variables.radius
                color: Variables.uiColor

                Image {
                    anchors.fill: scrollList
                    anchors.margins: 3
                    source: filePath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: scrollList.isSelected ? 1.0 : 0.4

                    Behavior on opacity {
                        NumberAnimation { duration: Variables.fadeAnimation }
                    }
                }
            }
        }
    }

    Connections {
        target: Variables

        function onWallpaperPickerChanged() {
            if (!Variables.wallpaperPicker) {
                previewProcess.running = false;
                previewProcess.command = [
                    "/bin/bash", 
                    "-c", 
                    root.previewScript + " \"$(cat " + root.txtDir + ")\""
                ];
                previewProcess.running = true;
            } else {
                initialPreviewTimer.restart();
            }
        }
    }

    Timer {
        id: wallpaperTimer

        interval: Variables.animationDurationUI
        running: false
        repeat: false
        triggeredOnStart: false
        onTriggered: Variables.wallpaperPreview = false
    }

    Timer {
        id: previewTimer
        interval: 100
        repeat: false

        onTriggered: {
            if (!wallpaperList.currentItem)
                return;

            previewProcess.running = false;
            previewProcess.command = ["/bin/bash", root.previewScript, wallpaperList.currentItem.imagePath];
            previewProcess.running = true;
        }
    }

    Timer {
        id: initialPreviewTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (wallpaperList.currentIndex >= 0) {
                wallpaperList.positionViewAtIndex(wallpaperList.currentIndex, ListView.Center);
            }
            root.previewCurrentWallpaper();
        }
    }
}
