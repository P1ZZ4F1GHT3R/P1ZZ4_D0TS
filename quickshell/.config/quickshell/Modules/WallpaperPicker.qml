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

    property bool isApplying: false

    implicitWidth: 800
    implicitHeight: Variables.wallpaperPicker ? 250 : 0
    color: Variables.uiColor
    topLeftRadius: Variables.radius
    topRightRadius: Variables.radius

    Behavior on implicitHeight {
        NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
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

    function shuffleWallpapers() {
        if (folderModel.status !== FolderListModel.Ready) return;

        var tempArray = [];
        for (var i = 0; i < folderModel.count; i++) {
            tempArray.push({ "filePath": folderModel.get(i, "fileUrl").toString() });
        }

        for (var j = tempArray.length - 1; j > 0; j--) {
            var k = Math.floor(Math.random() * (j + 1));
            var temp = tempArray[j];
            tempArray[j] = tempArray[k];
            tempArray[k] = temp;
        }

        shuffledModel.clear();
        for (var n = 0; n < tempArray.length; n++) {
            shuffledModel.append(tempArray[n]);
        }

        if (shuffledModel.count > 0) {
            wallpaperList.currentIndex = Math.floor(Math.random() * shuffledModel.count);
        }
    }

    Process {
        id: previewProcess
    }

    Process {
        id: applyProcess
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + root.wallpaperDirectory
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false

        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                root.shuffleWallpapers();
            }
        }
    }

    ListModel {
        id: shuffledModel
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

    PathView {
        id: wallpaperList

        anchors.fill: parent
        anchors.margins: Variables.spacing
        focus: Variables.wallpaperPicker
        clip: true
        interactive: true
        model: shuffledModel
        currentIndex: -1
        pathItemCount: 7 
        
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightMoveDuration: Variables.animationDurationUI / 1.5

        path: Path {
            startX: -wallpaperList.width / 2
            startY: wallpaperList.height / 2

            PathLine {
                x: wallpaperList.width * 1.5
                y: wallpaperList.height / 2
            }
        }

        Keys.onLeftPressed: decrementCurrentIndex()
        Keys.onRightPressed: incrementCurrentIndex()

        onCurrentItemChanged: root.previewCurrentWallpaper()
        
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (!currentItem || !currentItem.imagePath || applyProcess.running)
                    return;

                previewProcess.running = false;
                applyProcess.command = ["/bin/bash", root.syncScript, currentItem.imagePath];
                applyProcess.running = true;
                
                root.isApplying = true;
                Variables.wallpaperPicker = false;
                
                wallpaperTimer.start();
                event.accepted = true;
            }
        }

        delegate: Item {
            id: delegateRoot

            required property string filePath
            required property int index

            property string imagePath: root.localPath(filePath)

            readonly property int totalItems: PathView.view ? PathView.view.count : 1
            
            readonly property int signedDistance: {
                if (!PathView.view) return 0;
                var diff = index - PathView.view.currentIndex;
                var half = Math.floor(totalItems / 2);
                if (diff > half) diff -= totalItems;
                else if (diff < -half) diff += totalItems;
                return diff;
            }
            
            readonly property int distance: Math.abs(signedDistance)

            readonly property real itemOffsetX: {
                if (signedDistance <= -2) return 70;  
                if (signedDistance >= 2) return -70;  
                return 0;                             
            }

            readonly property real itemScale: {
                if (distance === 0) return 1.1;
                if (distance === 1) return 0.80;    
                return 0.70;                           
            }

            readonly property real itemOpacity: {
                if (distance === 0) return 1.0;     
                if (distance === 1) return 0.60;     
                return 0.20;                          
            }

            width: 300
            height: PathView.view.height
            z: distance === 0 ? 20 : (distance === 1 ? 10 : 0)

            Rectangle {
                id: scrollList
                
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: delegateRoot.itemOffsetX
                
                width: parent.width
                height: parent.height - 30
                
                scale: delegateRoot.itemScale

                Behavior on anchors.horizontalCenterOffset {
                    NumberAnimation {
                        duration: Variables.animationDurationUI / 2
                        easing.type: easing.InOutQuad
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Variables.animationDurationUI / 2
                        easing.type: easing.InOutQuad
                    }
                }

                color: "transparent"
                border.width: 0 
                radius: Variables.radius
                clip: true

                ClippingWrapperRectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: Variables.radius
                    color: Variables.uiColor

                    Image {
                        anchors.fill: parent
                        source: filePath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        
                        opacity: delegateRoot.itemOpacity

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Variables.animationDurationUI / 1.5
                                easing.type: Variables.animationTypeUI
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: selectionBorder
        
        anchors.centerIn: wallpaperList
        width: 300
        height: wallpaperList.height - 30
        
        scale: 1.1 
        
        color: "transparent"
        border.color: Variables.borderColor
        border.width: Variables.borderWidth * 2
        radius: Variables.radius
        z: 30
        visible: Variables.wallpaperPicker && wallpaperList.count > 0
    }

    Connections {
        target: Variables

        function onWallpaperPickerChanged() {
            if (!Variables.wallpaperPicker) {
                if (root.isApplying) {
                    root.isApplying = false;
                } else {
                    previewProcess.running = false;
                    previewProcess.command = [
                        "/bin/bash", 
                        "-c", 
                        root.previewScript + " \"$(cat " + root.txtDir + ")\""
                    ];
                    previewProcess.running = true;
                }
                reshuffleTimer.start();
            } else {
                reshuffleTimer.stop();
                initialPreviewTimer.restart();
            }
        }
    }

    Timer {
        id: wallpaperTimer
        interval: Variables.animationDurationUI / 2
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
        id: reshuffleTimer
        interval: Variables.animationDurationUI / 2
        repeat: false
        onTriggered: {
            root.shuffleWallpapers(); 
        }
    }

    Timer {
        id: initialPreviewTimer
        interval: 50
        repeat: false
        onTriggered: {
            root.previewCurrentWallpaper();
        }
    }
}