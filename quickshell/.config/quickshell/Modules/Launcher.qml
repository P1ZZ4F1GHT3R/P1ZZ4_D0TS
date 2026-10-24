import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../"

Rectangle {
    id: root

    ListModel { 
        id: resultsModel 
        dynamicRoles: true
    }

    readonly property real itemHeight: Variables.fontSize * 2.5
    readonly property real gridItemSize: Variables.fontSize * 3
    readonly property real baseHeight: Variables.launcherSearchHeight + Variables.borderWidth * 4 + Variables.spacing * 2
    readonly property bool isGridMode: searchMode === "emoji" || searchMode === "nerdfont"
    readonly property int gridColumns: Math.max(1, Math.floor((root.width - Variables.spacing * 2) / gridItemSize))
    readonly property real calculatedListHeight: isGridMode 
        ? Math.ceil(resultsModel.count / gridColumns) * gridItemSize 
        : resultsModel.count * itemHeight
    readonly property real maxListHeight: Variables.launcherExpandedHeight - baseHeight

    implicitWidth: Variables.launcherWidth
    implicitHeight: Variables.launcherOpen ? (searchInput.text.length > 0 || searchMode !== "apps" ? baseHeight + Math.min(calculatedListHeight, maxListHeight) : baseHeight) : 0
    
    color: Variables.uiColor
    topLeftRadius: Variables.radius
    topRightRadius: Variables.radius

    Behavior on implicitHeight {
        NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
    }

    property var allApps: []
    property var allClipboard: []
    property var allEmojis: []
    property var allNerdIcons: []
    property string searchMode: "apps"

    function loadEmojis() {
        if (allEmojis.length > 0) return;
        let xhrEmoji = new XMLHttpRequest();
        xhrEmoji.open("GET", "https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json");
        xhrEmoji.onreadystatechange = function() {
            if (xhrEmoji.readyState === XMLHttpRequest.DONE && xhrEmoji.status === 200) {
                let data = JSON.parse(xhrEmoji.responseText);
                let emojis = [];
                for (let i = 0; i < data.length; i++) {
                    if (data[i].emoji) {
                        emojis.push({
                            char: data[i].emoji,
                            desc: data[i].description || "",
                            aliases: data[i].aliases ? data[i].aliases.join(" ") : ""
                        });
                    }
                }
                root.allEmojis = emojis;
                if (root.searchMode === "emoji") filterResults(searchInput.text);
            }
        }
        xhrEmoji.send();
    }

    function loadNerdIcons() {
        if (allNerdIcons.length > 0) return;
        let xhrNf = new XMLHttpRequest();
        xhrNf.open("GET", "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json");
        xhrNf.onreadystatechange = function() {
            if (xhrNf.readyState === XMLHttpRequest.DONE && xhrNf.status === 200) {
                let data = JSON.parse(xhrNf.responseText);
                let icons = [];
                for (let key in data) {
                    if (key === "METADATA") continue;
                    let item = data[key];
                    let glyphChar = item.char || (item.code ? String.fromCharCode(parseInt(item.code, 16)) : "");
                    if (glyphChar) {
                        icons.push({
                            char: glyphChar,
                            name: key.replace(/^nf-/, "").replace(/_/g, "-")
                        });
                    }
                }
                root.allNerdIcons = icons;
                if (root.searchMode === "nerdfont") filterResults(searchInput.text);
            }
        }
        xhrNf.send();
    }

    function evaluateMath(expr) {
        let clean = expr.trim().replace(/,/g, '.');
        if (!/^[0-9+\-*/%^().\s]+$/.test(clean)) return null;
        if (!/[+\-*/%^]/.test(clean)) return null;

        try {
            let jsExpr = clean.replace(/\^/g, '**');
            let res = Function('"use strict"; return (' + jsExpr + ')')();
            if (typeof res === 'number' && !isNaN(res) && isFinite(res)) {
                return Math.round(res * 100000000) / 100000000;
            }
        } catch (e) {
            return null;
        }
        return null;
    }

    Process {
        id: appFetcher
        running: true
        command: [
            "bash", 
            "-c", 
            "for f in /usr/share/applications/*.desktop " + Quickshell.env("HOME") + "/.local/share/applications/*.desktop; do [ -f \"$f\" ] || continue; grep -qi '^\\(NoDisplay\\|Hidden\\)=true' \"$f\" && continue; tryexec=$(grep -m 1 '^TryExec=' \"$f\" | cut -d '=' -f 2-); if [ -n \"$tryexec\" ] && ! command -v \"$tryexec\" >/dev/null 2>&1; then continue; fi; name=$(grep -m 1 '^Name=' \"$f\" | cut -d '=' -f 2-); cmd=$(grep -m 1 '^Exec=' \"$f\" | cut -d '=' -f 2- | sed 's/ %[a-zA-Z]//g'); icon=$(grep -m 1 '^Icon=' \"$f\" | cut -d '=' -f 2-); if [ -n \"$name\" ] && [ -n \"$cmd\" ]; then echo \"$name|$cmd|$icon\"; fi; done | sort -u"
        ]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let parsedApps = [];
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split("|");
                    if (parts.length >= 2) {
                        parsedApps.push({ 
                            name: parts[0].trim(), 
                            command: parts[1].trim(), 
                            icon: parts.length > 2 ? parts[2].trim() : "" 
                        });
                    }
                }
                root.allApps = parsedApps;
            }
        }
    }

    Process {
        id: clipboardFetcher
        command: ["bash", "-c", "cliphist list | head -n 50"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let parsedCb = [];
                for (let i = 0; i < lines.length; i++) {
                    let sep = lines[i].indexOf("\t");
                    if (sep !== -1) {
                        parsedCb.push({
                            id: lines[i].substring(0, sep),
                            text: lines[i].substring(sep + 1),
                            rawLine: lines[i]
                        });
                    }
                }
                root.allClipboard = parsedCb;
                if (root.searchMode === "clipboard") filterResults(searchInput.text);
            }
        }
    }

    Process {
        id: fileSearchProcess
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                resultsModel.clear();
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].length > 0) {
                        resultsModel.append({
                            displayTitle: lines[i].split('/').pop(),
                            actionData: lines[i],
                            displayIcon: "text-x-generic",
                            resultType: "file"
                        });
                    }
                }
                resultsList.currentIndex = 0;
            }
        }
    }

    Timer {
        id: fileSearchTimer
        interval: 150 
        onTriggered: {
            if (searchInput.text.trim().length > 0) {
                let safeQuery = searchInput.text.trim().replace(/'/g, "");
                fileSearchProcess.command = ["bash", "-c", "fd -i -t f '" + safeQuery + "' $HOME -E '.git' -E '.cache' | head -n 20"];
                fileSearchProcess.running = true;
            } else {
                resultsModel.clear();
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
            PathArc { x: 0; y: bottomLeftConcave.cornerSize; radiusX: bottomLeftConcave.cornerSize; radiusY: bottomLeftConcave.cornerSize; direction: PathArc.Clockwise }
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
            PathArc { x: bottomRightConcave.cornerSize; y: bottomRightConcave.cornerSize; radiusX: bottomRightConcave.cornerSize; radiusY: bottomRightConcave.cornerSize; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: bottomRightConcave.cornerSize }
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: Variables.spacing
        anchors.bottomMargin: Variables.borderWidth * 4
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: Variables.spacing

            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.preferredHeight: Variables.launcherSearchHeight
                Layout.alignment: Qt.AlignTop
                
                placeholderText: {
                    if (root.searchMode === "clipboard") return "Search clipboard...";
                    if (root.searchMode === "files") return "Search files...";
                    if (root.searchMode === "emoji") return "Search emojis...";
                    if (root.searchMode === "nerdfont") return "Search NerdFont icons...";
                    return "Search apps (type / for commands)...";
                }
                color: Variables.uiColor
                font.pixelSize: Variables.fontSize
                horizontalAlignment: TextInput.AlignLeft
                verticalAlignment: TextInput.AlignVCenter
                
                background: Rectangle {
                    color: Variables.lockscreenColor
                    radius: Variables.radius
                }

                Timer {
                    interval: 50
                    running: Variables.launcherOpen && !searchInput.activeFocus
                    repeat: true
                    onTriggered: searchInput.forceActiveFocus()
                }

                onTextChanged: {
                    if (text.startsWith("/") && root.searchMode !== "apps") {
                        root.searchMode = "apps";
                    }
                    if (root.searchMode === "files") {
                        fileSearchTimer.restart();
                    } else {
                        filterResults(text);
                    }
                }

                Keys.onEscapePressed: Variables.launcherOpen = false
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Backspace) {
                        if (text.length === 0 && root.searchMode !== "apps") {
                            root.searchMode = "apps";
                            filterResults("");
                        }
                    } else if (root.isGridMode) {
                        if (event.key === Qt.Key_Left) {
                            resultsGrid.moveCurrentIndexLeft();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            resultsGrid.moveCurrentIndexRight();
                            event.accepted = true;
                        }
                    }
                }
                Keys.onDownPressed: {
                    if (root.isGridMode) resultsGrid.moveCurrentIndexDown();
                    else resultsList.incrementCurrentIndex();
                }
                Keys.onUpPressed: {
                    if (root.isGridMode) resultsGrid.moveCurrentIndexUp();
                    else resultsList.decrementCurrentIndex();
                }
                Keys.onReturnPressed: {
                    if (resultsModel.count > 0) {
                        let activeIdx = root.isGridMode ? resultsGrid.currentIndex : resultsList.currentIndex;
                        let item = resultsModel.get(activeIdx);
                        executeResult(item.resultType, item.actionData);
                    }
                }
            }

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: (searchInput.text.length > 0 || root.searchMode !== "apps") && !root.isGridMode
                model: resultsModel

                delegate: Item {
                    width: resultsList.width
                    height: root.itemHeight
                    
                    Rectangle {
                        anchors.fill: parent
                        color: index === resultsList.currentIndex ? Variables.lockscreenColor : "transparent"
                        radius: Variables.radius

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Variables.spacing
                            spacing: Variables.spacing * 2

                            Image {
                                Layout.preferredWidth: Variables.fontSize * 1.5
                                Layout.preferredHeight: Variables.fontSize * 1.5
                                Layout.alignment: Qt.AlignVCenter
                                visible: model.displayIcon !== ""
                                source: model.displayIcon.startsWith("/") ? "file://" + model.displayIcon : (model.displayIcon ? "image://icon/" + model.displayIcon : "")
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: model.displayTitle || ""
                                color: index === resultsList.currentIndex ? Variables.uiColor : Variables.textColor
                                font.pixelSize: Variables.fontSize
                                elide: Text.ElideRight

                                Behavior on color {
                                    ColorAnimation {duration: Variables.fadeAnimation / 1.5}
                                }
                            }
                        }

                        Behavior on color {
                            ColorAnimation {duration: Variables.fadeAnimation / 1.5}
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            executeResult(model.resultType, model.actionData)
                        }
                    }
                }
            }

            GridView {
                id: resultsGrid
                Layout.preferredWidth: root.gridColumns * cellWidth
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                clip: true
                cellWidth: root.gridItemSize
                cellHeight: root.gridItemSize
                visible: (searchInput.text.length > 0 || root.searchMode !== "apps") && root.isGridMode
                model: resultsModel

                delegate: Item {
                    width: resultsGrid.cellWidth
                    height: resultsGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Variables.spacing / 2
                        color: index === resultsGrid.currentIndex ? Variables.lockscreenColor : "transparent"
                        radius: Variables.radius

                        Text {
                            anchors.centerIn: parent
                            text: model.actionData || ""
                            color: index === resultsGrid.currentIndex ? Variables.uiColor : Variables.textColor
                            font.pixelSize: Variables.fontSize * 1.5
                        }

                        ToolTip.visible: mouseArea.containsMouse
                        ToolTip.text: model.displayTitle || ""
                        ToolTip.delay: 300

                        Behavior on color {
                            ColorAnimation {duration: Variables.fadeAnimation / 1.5}
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            executeResult(model.resultType, model.actionData)
                        }
                    }
                }
            }
        }
    }

    function filterResults(query) {
        if (root.searchMode === "files") return; 
        
        resultsModel.clear()
        let lowerQuery = query.toLowerCase()
        let scoredItems = []

        const virtualModes = [
            { name: "Clipboard History", command: "clipboard", trigger: "clipboard", icon: "edit-paste", type: "mode" },
            { name: "File Search", command: "files", trigger: "files", icon: "system-file-manager", type: "mode" },
            { name: "Emoji Picker", command: "emoji", trigger: "emoji", icon: "face-smile", type: "mode" },
            { name: "NerdFont Icons", command: "nerdfont", trigger: "nerdfont", icon: "utilities-terminal", type: "mode" }
        ];

        if (root.searchMode === "apps") {
            if (query.length === 0) return;

            let calcVal = evaluateMath(query);
            if (calcVal !== null) {
                scoredItems.push({
                    title: "= " + calcVal,
                    data: String(calcVal),
                    icon: "accessories-calculator",
                    type: "calc",
                    score: 1000
                });
            }

            if (query.startsWith("/")) {
                let slashQuery = lowerQuery.substring(1);
                for (let j = 0; j < virtualModes.length; j++) {
                    let vName = virtualModes[j].name.toLowerCase();
                    let vTrig = virtualModes[j].trigger.toLowerCase();
                    if (slashQuery === "" || vName.includes(slashQuery) || vTrig.includes(slashQuery)) {
                        let score = (vTrig === slashQuery) ? 110 : (vTrig.startsWith(slashQuery) ? 60 : 30);
                        scoredItems.push({
                            title: virtualModes[j].name,
                            data: virtualModes[j].command,
                            icon: virtualModes[j].icon,
                            type: virtualModes[j].type,
                            score: slashQuery === "" ? (virtualModes.length - j) : score
                        });
                    }
                }
            } else {
                for (let i = 0; i < allApps.length; i++) {
                    let name = allApps[i].name;
                    let lowerName = name.toLowerCase();
                    
                    if (lowerName.includes(lowerQuery)) {
                        let score = 0;
                        if (lowerName === lowerQuery) score = 100;
                        else if (lowerName.startsWith(lowerQuery)) score = 50;
                        else if (lowerName.includes(" " + lowerQuery)) score = 25;
                        else score = 10;

                        scoredItems.push({
                            title: name,
                            data: allApps[i].command,
                            icon: allApps[i].icon,
                            type: "app",
                            score: score
                        });
                    }
                }
            }
        } else if (root.searchMode === "clipboard") {
            for (let i = 0; i < allClipboard.length; i++) {
                let text = allClipboard[i].text;
                let lowerText = text.toLowerCase();
                
                if (query.length === 0 || lowerText.includes(lowerQuery)) {
                    let score = query.length === 0 ? (allClipboard.length - i) : 0; 
                    if (query.length > 0) {
                        if (lowerText === lowerQuery) score = 100;
                        else if (lowerText.startsWith(lowerQuery)) score = 50;
                        else if (lowerText.includes(" " + lowerQuery)) score = 25;
                        else score = 10;
                        score += (allClipboard.length - i) * 0.01;
                    }

                    scoredItems.push({
                        title: text.replace(/\n/g, " "),
                        data: allClipboard[i].rawLine,
                        icon: "edit-paste",
                        type: "clipboard",
                        score: score
                    });
                }
            }
        } else if (root.searchMode === "emoji") {
            for (let i = 0; i < allEmojis.length; i++) {
                let e = allEmojis[i];
                let desc = e.desc.toLowerCase();
                let aliases = e.aliases.toLowerCase();
                let fullSearchStr = desc + " " + aliases;

                if (query.length === 0 || fullSearchStr.includes(lowerQuery)) {
                    let score = 0;
                    if (query.length > 0) {
                        if (desc === lowerQuery || aliases === lowerQuery) {
                            score = 100;
                        } else if (desc.startsWith(lowerQuery) || aliases.startsWith(lowerQuery)) {
                            score = 50;
                        } else if (desc.includes(" " + lowerQuery) || desc.includes("_" + lowerQuery) || aliases.includes(" " + lowerQuery) || aliases.includes("_" + lowerQuery)) {
                            score = 25;
                        } else {
                            score = 10;
                        }
                    }

                    scoredItems.push({
                        title: e.desc,
                        data: e.char,
                        icon: "", 
                        type: "emoji",
                        score: score
                    });
                }
            }
        } else if (root.searchMode === "nerdfont") {
            for (let i = 0; i < allNerdIcons.length; i++) {
                let icon = allNerdIcons[i];
                let name = icon.name.toLowerCase();

                if (query.length === 0 || name.includes(lowerQuery)) {
                    let score = 0;
                    if (query.length > 0) {
                        if (name === lowerQuery) {
                            score = 100;
                        } else if (name.startsWith(lowerQuery)) {
                            score = 50;
                        } else if (name.includes(" " + lowerQuery) || name.includes("-" + lowerQuery) || name.includes("_" + lowerQuery)) {
                            score = 25;
                        } else {
                            score = 10;
                        }
                    }

                    scoredItems.push({
                        title: icon.name,
                        data: icon.char,
                        icon: "",
                        type: "nerdfont",
                        score: score
                    });
                }
            }
        }

        if (query.length > 0) {
            scoredItems.sort((a, b) => b.score - a.score);
        }

        let max = Math.min(scoredItems.length, root.isGridMode ? 120 : 20);
        for (let i = 0; i < max; i++) {
            resultsModel.append({
                displayTitle: scoredItems[i].title,
                actionData: scoredItems[i].data,
                displayIcon: scoredItems[i].icon,
                resultType: scoredItems[i].type
            });
        }
        resultsList.currentIndex = 0;
        resultsGrid.currentIndex = 0;
    }

    function executeResult(type, data) {
        if (type === "mode") {
            root.searchMode = data;
            searchInput.text = "";
            if (data === "clipboard") clipboardFetcher.running = true;
            if (data === "emoji") loadEmojis();
            if (data === "nerdfont") loadNerdIcons();
            if (data === "emoji" || data === "nerdfont") filterResults("");
            return; 
        } else if (type === "app") {
            actionProcess.command = ["/bin/bash", "-c", data + " &"];
        } else if (type === "clipboard") {
            let safeData = "'" + data.replace(/'/g, "'\\''") + "'";
            actionProcess.command = ["/bin/bash", "-c", "printf \"%s\\n\" " + safeData + " | cliphist decode | wl-copy"];
        } else if (type === "file") {
            let safePath = "'" + data.replace(/'/g, "'\\''") + "'";
            actionProcess.command = ["/bin/bash", "-c", "xdg-open " + safePath + " &"];
        } else if (type === "emoji" || type === "nerdfont" || type === "calc") {
            actionProcess.command = ["/bin/bash", "-c", "printf \"%s\" '" + data + "' | wl-copy"];
        }
        
        actionProcess.running = true;
        Variables.launcherOpen = false;
    }

    Process { id: actionProcess }

    Connections {
        target: Variables
        function onLauncherOpenChanged() {
            if (Variables.launcherOpen) {
                if (root.searchMode === "clipboard") clipboardFetcher.running = true;
            } else {
                searchInput.text = "";
                root.searchMode = "apps";
                root.allEmojis = [];
                root.allNerdIcons = [];
            }
        }
    }
}