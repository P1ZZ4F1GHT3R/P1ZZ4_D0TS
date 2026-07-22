pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/ambxst"
    readonly property string stateFile: cacheDir + "/matugen-source"
    readonly property string matugenConfig: Qt.resolvedUrl("../../assets/matugen/config.toml").toString().replace("file://", "")
    readonly property string userConfigDir: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string liveMatugenConfig: userConfigDir + "/matugen/config.toml"
    readonly property string liveWallustConfig: userConfigDir + "/wallust/wallust.toml"
    readonly property string dotfilesMatugenConfig: Quickshell.env("HOME") + "/.config/matugen/config.toml"
    readonly property string dotfilesWallustConfig: Quickshell.env("HOME") + "/.config/wallust/wallust.toml"

    property string lastSource: ""
    property string scheme: "scheme-tonal-spot"
    property bool runWallust: true

    function run(source, requestedScheme, includeWallust) {
        if (!source || source.trim() === "") {
            console.warn("MatugenService: missing image/source path");
            return;
        }

        lastSource = source.trim();
        if (requestedScheme && requestedScheme.trim() !== "") {
            scheme = requestedScheme.trim();
        }

        persistSource.command = ["sh", "-c", "mkdir -p '" + cacheDir + "' && printf '%s\n' '" + lastSource.replace(/'/g, "'\\''") + "' > '" + stateFile + "'"];
        persistSource.running = true;

        if (matugenWithConfig.running)
            matugenWithConfig.running = false;
        if (matugenNormal.running)
            matugenNormal.running = false;
        if (matugenDotfiles.running)
            matugenDotfiles.running = false;
        if (wallustProcess.running)
            wallustProcess.running = false;

        matugenWithConfig.command = ["matugen", "image", lastSource, "--source-color-index", "0", "-c", matugenConfig, "-t", scheme];
        matugenNormal.command = ["matugen", "image", lastSource, "--source-color-index", "0", "-t", scheme];
        matugenDotfiles.command = ["sh", "-c", "config=''; if test -f '" + liveMatugenConfig + "'; then config='" + liveMatugenConfig + "'; elif test -f '" + dotfilesMatugenConfig + "'; then config='" + dotfilesMatugenConfig + "'; fi; if test -n \"$config\"; then matugen image '" + lastSource.replace(/'/g, "'\\''") + "' --source-color-index 0 -c \"$config\" -t '" + scheme.replace(/'/g, "'\\''") + "'; fi"];
        wallustProcess.command = ["sh", "-c", "if command -v wallust >/dev/null 2>&1; then config=''; if test -f '" + liveWallustConfig + "'; then config='" + liveWallustConfig + "'; elif test -f '" + dotfilesWallustConfig + "'; then config='" + dotfilesWallustConfig + "'; fi; if test -n \"$config\"; then wallust -C \"$config\" run '" + lastSource.replace(/'/g, "'\\''") + "' --dynamic-threshold; else wallust run '" + lastSource.replace(/'/g, "'\\''") + "' --dynamic-threshold; fi; fi"];
        matugenWithConfig.running = true;
        matugenNormal.running = true;
        matugenDotfiles.running = true;
        if (runWallust && includeWallust === true)
            wallustProcess.running = true;
    }

    function runTheme(source, requestedScheme) {
        run(source, requestedScheme, true);
    }

    function runWallustOnly(source) {
        if (!source || source.trim() === "") {
            console.warn("MatugenService: missing image/source path for wallust");
            return;
        }

        lastSource = source.trim();
        if (wallustProcess.running)
            wallustProcess.running = false;
        wallustProcess.command = ["sh", "-c", "config=''; if test -f '" + liveWallustConfig + "'; then config='" + liveWallustConfig + "'; elif test -f '" + dotfilesWallustConfig + "'; then config='" + dotfilesWallustConfig + "'; fi; if test -n \"$config\"; then wallust -C \"$config\" run '" + lastSource.replace(/'/g, "'\\''") + "' --dynamic-threshold; else wallust run '" + lastSource.replace(/'/g, "'\\''") + "' --dynamic-threshold; fi"];
        wallustProcess.running = true;
    }

    function rerun() {
        if (lastSource && lastSource.trim() !== "") {
            run(lastSource, scheme, true);
            return;
        }
        readLastSource.running = true;
    }

    Process {
        id: persistSource
    }

    Process {
        id: readLastSource
        command: ["sh", "-c", "test -f '" + root.stateFile + "' && cat '" + root.stateFile + "' || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const source = text.trim();
                if (source !== "")
                    root.runTheme(source, root.scheme);
            }
        }
    }

    Process {
        id: matugenWithConfig
        onExited: code => {
            if (code !== 0)
                console.warn("MatugenService: configured matugen exited with code", code);
        }
    }

    Process {
        id: matugenNormal
        onExited: code => {
            if (code !== 0)
                console.warn("MatugenService: matugen exited with code", code);
        }
    }

    Process {
        id: matugenDotfiles
        onExited: code => {
            if (code !== 0)
                console.warn("MatugenService: dotfiles matugen exited with code", code);
        }
    }

    Process {
        id: wallustProcess
        onExited: code => {
            if (code !== 0)
                console.warn("MatugenService: wallust exited with code", code);
        }
    }

    IpcHandler {
        target: "matugen"

        function run(source: string, requestedScheme: string) {
            root.run(source, requestedScheme);
        }

        function theme(source: string, requestedScheme: string) {
            root.runTheme(source, requestedScheme);
        }

        function rerun() {
            root.rerun();
        }

        function wallust(source: string) {
            root.runWallustOnly(source);
        }
    }
}
