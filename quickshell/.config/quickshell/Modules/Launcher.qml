import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtCore
import Quickshell
import Quickshell.Io
import "../Common"
import "../"

Rectangle {
    id: root

    Settings {
        id: appUsageSettings
        category: "Launcher"
        property string usageJson: "{}"
    }

    ListModel { 
        id: resultsModel 
        dynamicRoles: true
    }

    readonly property real itemHeight: Variables.fontSize * 2.5
    readonly property real gridItemSize: Variables.fontSize * 3
    readonly property real baseHeight: searchMode === "wallpaper" 
        ? Variables.borderWidth * 4 + Variables.spacing * 2 
        : Variables.launcherSearchHeight + Variables.borderWidth * 4 + Variables.spacing * 2
    readonly property bool isGridMode: searchMode === "emoji" || searchMode === "nerdfont"
    readonly property int gridColumns: Math.max(1, Math.floor((root.width - Variables.spacing * 2) / gridItemSize))
    readonly property real calculatedListHeight: isGridMode 
        ? Math.ceil(resultsModel.count / gridColumns) * gridItemSize 
        : resultsModel.count * itemHeight
    readonly property real maxListHeight: Variables.launcherExpandedHeight - baseHeight
    readonly property bool searchFocused: searchInput.hasFocus

    property bool needsInitialFocus: false

    function focusSearch() {
        needsInitialFocus = true;
        searchInput.forceInputFocus();
    }

    implicitWidth: Variables.launcherOpen ? ((Variables.wallpaperPicker || searchMode === "wallpaper") ? Variables.wallpaperPickerWidth : Variables.launcherWidth) : Variables.launcherWidth / 3
    implicitHeight: Variables.launcherOpen ? (
        searchMode === "wallpaper" ? baseHeight + Variables.wallpaperPickerHeight : 
        (searchInput.text.trim().length > 0 || (searchMode !== "apps" && searchMode !== "settings")
            ? baseHeight + Math.min(calculatedListHeight, maxListHeight)
            : baseHeight)
    ) : 0 
    
    color: Variables.uiColor
    topLeftRadius: Variables.radius
    topRightRadius: Variables.radius

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Variables.launcherOpen ? Variables.activeDurationUI * 0.55 : Variables.activeDurationUI * 0.45
            easing.type: Easing.OutCubic
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Variables.launcherOpen ? Variables.activeDurationUI * 0.55 : Variables.activeDurationUI * 0.45
            easing.type: Easing.OutCubic
        }
    }

    property var allClipboard: []
    property var allEmojis: []
    property var allNerdIcons: []

    property string searchMode: Variables.launcherMode

    onSearchModeChanged: {
        if (Variables.settingsOpen && searchMode !== "settings") {
            Variables.launcherMode = "settings";
            searchMode = "settings";
            return;
        }

        if (searchMode === "wallpaper") {
            Variables.wallpaperPicker = true;
            if (wallpaperLoader.item) {
                wallpaperLoader.item.forceActiveFocus();
            }
        } else {
            Variables.wallpaperPicker = false;
            if (Variables.launcherOpen) {
                focusSearch();
            }
            if (searchMode === "emoji") loadEmojis();
            if (searchMode === "nerdfont") loadNerdIcons();
            if (searchMode === "settings") {
                resultsModel.clear();
                if (searchInput.text.trim().length > 0) {
                    filterResults(searchInput.text);
                }
            }
        }
    }

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

    function collectMatchingSettings(lowerQuery, includeAllWhenEmpty) {
        let matches = [];
        const cats = Variables.settingsCategories || [];

        for (let c = 0; c < cats.length; c++) {
            const cat = cats[c];
            const catName = (cat.name || "").toLowerCase();
            const catSub = (cat.subtitle || "").toLowerCase();

            let catScore = 0;
            if (includeAllWhenEmpty && lowerQuery.length === 0) {
                catScore = 500 - c;
            } else if (lowerQuery.length > 0) {
                if (catName === lowerQuery) catScore = 920;
                else if (catName.startsWith(lowerQuery)) catScore = 760;
                else if (catName.includes(lowerQuery) || catSub.includes(lowerQuery)) catScore = 520;
            }

            if (catScore > 0) {
                matches.push({
                    title: cat.name + "  ·  " + cat.subtitle,
                    data: String(c),
                    extra: "",
                    icon: "",
                    glyph: cat.icon || "󰒓",
                    badge: "Category",
                    type: "setting",
                    score: catScore
                });
            }

            const items = cat.settings || [];
            for (let s = 0; s < items.length; s++) {
                const item = items[s];
                if (!item.label) continue;

                const lowerLabel = item.label.toLowerCase();
                const lowerDesc = (item.description || "").toLowerCase();
                let score = 0;

                if (includeAllWhenEmpty && lowerQuery.length === 0) {
                    score = 300 - (c * 20) - s;
                } else if (lowerQuery.length > 0) {
                    if (lowerLabel === lowerQuery) score = 950;
                    else if (lowerLabel.startsWith(lowerQuery)) score = 780;
                    else if (lowerLabel.includes(" " + lowerQuery)) score = 680;
                    else if (lowerLabel.includes(lowerQuery)) score = 580;
                    else if (lowerDesc.includes(lowerQuery)) score = 420;
                    else if (catName.includes(lowerQuery)) score = 340;
                }

                if (score > 0) {
                    matches.push({
                        title: item.label,
                        data: String(c),
                        extra: item.key || item.type || "",
                        icon: "",
                        glyph: cat.icon || "󰒓",
                        badge: cat.name,
                        type: "setting",
                        score: score
                    });
                }
            }
        }
        return matches;
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
                            extraData: "",
                            displayIcon: "text-x-generic",
                            displayGlyph: "",
                            displayBadge: "",
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

    MouseArea {
        anchors.fill: parent
        enabled: Variables.launcherOpen && root.searchMode !== "wallpaper"
        onPressed: mouse => {
            root.focusSearch();
            mouse.accepted = false;
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

            AnimatedInput {
                id: searchInput
                Layout.fillWidth: true
                visible: root.searchMode !== "wallpaper"
                Layout.preferredHeight: Variables.launcherSearchHeight
                Layout.alignment: Qt.AlignTop

                placeholderText: {
                    if (root.searchMode === "clipboard") return "Search clipboard...";
                    if (root.searchMode === "files") return "Search files...";
                    if (root.searchMode === "emoji") return "Search emojis...";
                    if (root.searchMode === "nerdfont") return "Search NerdFont icons...";
                    if (root.searchMode === "settings") return "Search settings...";
                    return "Search apps or settings (type / for commands)...";
                }

                onHasFocusChanged: {
                    if (hasFocus) {
                        root.needsInitialFocus = false;
                    }
                }

                Timer {
                    interval: 50
                    running: Variables.launcherOpen && root.searchMode !== "wallpaper" && root.needsInitialFocus && !searchInput.hasFocus
                    repeat: true
                    onTriggered: searchInput.forceInputFocus()
                }

                onTextEdited: (newText) => {
                    if (!Variables.settingsOpen && newText.startsWith("/") && root.searchMode !== "apps") {
                        Variables.launcherMode = "apps";
                    }
                    if (root.searchMode === "files") {
                        fileSearchTimer.restart();
                    } else {
                        filterResults(newText);
                    }
                }

                inputItem.Keys.onEscapePressed: {
                    if (Variables.settingsOpen) {
                        Variables.closeSettings();
                    } else {
                        Variables.launcherOpen = false;
                        Variables.wallpaperPicker = false;
                    }
                }

                inputItem.Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Backspace && searchInput.text.length === 0 && root.searchMode !== "apps" && !Variables.settingsOpen) {
                        Variables.launcherMode = "apps";
                        filterResults("");
                    } else if (root.isGridMode) {
                        if (event.key === Qt.Key_Left) { resultsGrid.moveCurrentIndexLeft(); event.accepted = true; }
                        else if (event.key === Qt.Key_Right) { resultsGrid.moveCurrentIndexRight(); event.accepted = true; }
                    }
                }

                inputItem.Keys.onDownPressed: {
                    if (root.isGridMode) resultsGrid.moveCurrentIndexDown();
                    else resultsList.incrementCurrentIndex();
                }

                inputItem.Keys.onUpPressed: {
                    if (root.isGridMode) resultsGrid.moveCurrentIndexUp();
                    else resultsList.decrementCurrentIndex();
                }
                
                inputItem.Keys.onReturnPressed: {
                    if (resultsModel.count > 0) {
                        let activeIdx = root.isGridMode ? resultsGrid.currentIndex : resultsList.currentIndex;
                        let item = resultsModel.get(activeIdx);
                        executeResult(item.resultType, item.actionData, item.extraData || "");
                    }
                }
            }

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: (searchInput.text.trim().length > 0 || (root.searchMode !== "apps" && root.searchMode !== "settings")) && !root.isGridMode && root.searchMode !== "wallpaper"
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
                            anchors.rightMargin: Variables.spacing
                            spacing: Variables.spacing * 2

                            Image {
                                Layout.preferredWidth: Variables.fontSize * 1.5
                                Layout.preferredHeight: Variables.fontSize * 1.5
                                Layout.alignment: Qt.AlignVCenter
                                visible: (model.displayIcon || "") !== "" && (model.displayGlyph || "") === ""
                                source: model.displayIcon.startsWith("/") ? "file://" + model.displayIcon : (model.displayIcon ? Quickshell.iconPath(model.displayIcon, "help-contents") : "")
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                Layout.preferredWidth: Variables.fontSize * 1.5
                                Layout.alignment: Qt.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                visible: (model.displayGlyph || "") !== ""
                                text: model.displayGlyph || ""
                                color: index === resultsList.currentIndex ? Variables.uiColor : Variables.iconColor
                                font.pixelSize: Variables.fontSize * 1.2
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

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                visible: (model.displayBadge || "") !== ""
                                text: model.displayBadge || ""
                                color: index === resultsList.currentIndex ? Variables.uiColor : Variables.borderColor
                                font.pixelSize: Variables.fontSize * 0.78
                            }
                        }

                        Behavior on color {
                            ColorAnimation {duration: Variables.fadeAnimation / 1.5}
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            executeResult(model.resultType, model.actionData, model.extraData || "")
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
                visible: (searchInput.text.length > 0 || root.searchMode !== "apps") && root.isGridMode && root.searchMode !== "wallpaper"
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
                            executeResult(model.resultType, model.actionData, model.extraData || "")
                        }
                    }
                }
            }

            Loader {
                id: wallpaperLoader
                Layout.fillWidth: true
                Layout.preferredHeight: Variables.wallpaperPickerHeight
                visible: root.searchMode === "wallpaper"
                active: true
                onLoaded: if (visible) item.forceActiveFocus()
                source: "WallpaperPicker.qml"
            }
        }
    }

    function filterResults(query) {
        if (root.searchMode === "files") return; 
        
        resultsModel.clear()
        let lowerQuery = query.toLowerCase()
        let scoredItems = []

        const virtualModes = [
            { name: "Settings Search", command: "settings", trigger: "settings", icon: "preferences-system", type: "mode" },
            { name: "Clipboard History", command: "clipboard", trigger: "clipboard", icon: "edit-paste", type: "mode" },
            { name: "File Search", command: "files", trigger: "files", icon: "system-file-manager", type: "mode" },
            { name: "Emoji Picker", command: "emoji", trigger: "emoji", icon: "face-smile", type: "mode" },
            { name: "NerdFont Icons", command: "nerdfont", trigger: "nerdfont", icon: "utilities-terminal", type: "mode" },
            { name: "Wallpaper Picker", command: "wallpaper", trigger: "wallpaper", icon: "preferences-desktop-wallpaper", type: "mode" }
        ];

        if (root.searchMode === "apps") {
            if (query.length === 0) return;

            let calcVal = evaluateMath(query);
            if (calcVal !== null) {
                scoredItems.push({
                    title: "= " + calcVal,
                    data: String(calcVal),
                    extra: "",
                    icon: "accessories-calculator",
                    glyph: "",
                    badge: "",
                    type: "calc",
                    score: 9999
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
                            extra: "",
                            icon: virtualModes[j].icon,
                            glyph: "",
                            badge: "",
                            type: virtualModes[j].type,
                            score: slashQuery === "" ? (virtualModes.length - j) : score
                        });
                    }
                }
            } else {
                let allApps = [...DesktopEntries.applications.values];
                let usageCache = {};
                try { usageCache = JSON.parse(appUsageSettings.usageJson || "{}"); } catch (e) {}

                for (let i = 0; i < allApps.length; i++) {
                    let entry = allApps[i];
                    if (!entry || entry.noDisplay) continue;
                    
                    let lowerName = (entry.name || "").toLowerCase();
                    let lowerGeneric = (entry.genericName || "").toLowerCase();
                    let score = 0;

                    if (lowerName === lowerQuery) score = 1000;
                    else if (lowerName.startsWith(lowerQuery)) score = 800;
                    else if (lowerName.includes(" " + lowerQuery)) score = 700;
                    else if (lowerName.includes(lowerQuery)) score = 600;
                    else if (lowerGeneric === lowerQuery) score = 550;
                    else if (lowerGeneric.startsWith(lowerQuery)) score = 450;
                    else if (lowerGeneric.includes(" " + lowerQuery)) score = 400;
                    else if (lowerGeneric.includes(lowerQuery)) score = 350;
                    else {
                        let queryIdx = 0;
                        let fuzzyScore = 0;
                        for (let c = 0; c < lowerName.length; c++) {
                            if (lowerName[c] === lowerQuery[queryIdx]) {
                                fuzzyScore += 10;
                                queryIdx++;
                                if (queryIdx === lowerQuery.length) break;
                            }
                        }
                        if (queryIdx === lowerQuery.length) {
                            score = 200 + fuzzyScore;
                        }
                    }

                    if (score > 0) {
                        let usageCount = usageCache[entry.id] || 0;
                        score += Math.min(usageCount * 15, 200); 

                        scoredItems.push({
                            title: entry.name || "",
                            data: entry.id, 
                            extra: entry.id,
                            icon: entry.icon || "dialog-question",
                            glyph: "",
                            badge: "",
                            type: "app",
                            score: score
                        });
                    }
                }

                scoredItems = scoredItems.concat(collectMatchingSettings(lowerQuery, false));
            }
        } else if (root.searchMode === "settings") {
            if (query.trim().length === 0) return;
            scoredItems = collectMatchingSettings(lowerQuery.trim(), false);
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
                        extra: "",
                        icon: "edit-paste",
                        glyph: "",
                        badge: "",
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
                        extra: "",
                        icon: "",
                        glyph: "",
                        badge: "",
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
                        extra: "",
                        icon: "",
                        glyph: "",
                        badge: "",
                        type: "nerdfont",
                        score: score
                    });
                }
            }
        }

        if (query.length > 0) {
            scoredItems.sort((a, b) => b.score - a.score);
        }

        let max = Math.min(scoredItems.length, root.isGridMode ? 999 : 20);
        for (let i = 0; i < max; i++) {
            resultsModel.append({
                displayTitle: scoredItems[i].title,
                actionData: scoredItems[i].data,
                extraData: scoredItems[i].extra,
                displayIcon: scoredItems[i].icon || "",
                displayGlyph: scoredItems[i].glyph || "",
                displayBadge: scoredItems[i].badge || "",
                resultType: scoredItems[i].type
            });
        }
        resultsList.currentIndex = 0;
        resultsGrid.currentIndex = 0;
    }

    function executeResult(type, data, extra) {
        if (type === "mode") {
            if (Variables.settingsOpen) return;
            Variables.launcherMode = data;
            searchInput.text = "";
            resultsModel.clear();
            if (data === "clipboard") clipboardFetcher.running = true;
            if (data === "emoji") loadEmojis();
            if (data === "nerdfont") loadNerdIcons();
            if (data === "emoji" || data === "nerdfont") filterResults("");
            if (data === "wallpaper") {
                Variables.wallpaperPicker = true;
                Variables.wallpaperPreview = true;
            }
            return; 
        } else if (type === "setting") {
            const catIdx = parseInt(data) || 0;
            Variables.launcherOpen = false;
            Variables.wallpaperPicker = false;
            Variables.openSettingsTo(catIdx, extra || "");
            return;
        } else if (type === "app") {
            let usageCache = {};
            try { usageCache = JSON.parse(appUsageSettings.usageJson || "{}"); } catch (e) {}
            usageCache[extra] = (usageCache[extra] || 0) + 1;
            appUsageSettings.usageJson = JSON.stringify(usageCache);

            appUsageSettings.sync();

            let entry = DesktopEntries.byId(extra);
            if (entry) {
                entry.execute();
            }

            Variables.launcherOpen = false;
            Variables.wallpaperPicker = false;
            return;
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
        Variables.wallpaperPicker = false;
    }

    Process { id: actionProcess }

    Connections {
        target: Variables
        function onLauncherModeChanged() {
            if (Variables.settingsOpen && Variables.launcherMode !== "settings") {
                Variables.launcherMode = "settings";
                return;
            }
            if (root.searchMode !== Variables.launcherMode)
                root.searchMode = Variables.launcherMode;
        }

        function onLauncherOpenChanged() {
            if (Variables.launcherOpen) {
                if (Variables.settingsOpen) {
                    Variables.launcherMode = "settings";
                }
                root.needsInitialFocus = true;
                searchInput.text = "";
                resultsModel.clear();
                if (Variables.launcherMode === "clipboard") clipboardFetcher.running = true;
                if (Variables.launcherMode === "emoji") loadEmojis();
                if (Variables.launcherMode === "nerdfont") loadNerdIcons();
            } else {
                root.needsInitialFocus = false;
                searchInput.text = "";
                resultsModel.clear();
                Variables.launcherMode = Variables.settingsOpen ? "settings" : "apps";
                Variables.wallpaperPicker = false;
                root.allEmojis = [];
                root.allNerdIcons = [];
            }
        }
    }
}