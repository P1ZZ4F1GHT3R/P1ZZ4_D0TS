pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.theme

Singleton {
    id: root

    property var availableProfiles: []
    property string currentProfile: ""
    property bool isAvailable: false
    property string backendType: ""

    signal profileChanged(string profile)

    function _startProc(proc) {
        proc.running = false;
        Qt.callLater(() => { proc.running = true; });
    }

    Timer {
        id: startupDelay
        interval: 2000
        running: true
        onTriggered: initialize()
    }

    Timer {
        id: retryTimer
        interval: 3000
        repeat: false
        onTriggered: {
            console.info("PowerProfile: Retrying initialization...");
            _initialized = false;
            initialize();
        }
    }

    property bool _initialized: false

    function initialize() {
        if (_initialized) return;
        _initialized = true;
        console.info("PowerProfile: Initializing");
        _startProc(checkPowerProfilesCtl);
    }

    Process {
        id: checkPowerProfilesCtl
        workingDirectory: "/"
        command: ["powerprofilesctl", "version"]
        running: false
        stdout: SplitParser {}

        onExited: exitCode => {
            if (exitCode === 0) {
                console.info("PowerProfile: powerprofilesctl detected");
                backendType = "powerprofilesctl";
                isAvailable = true;
                _startProc(getProc);
                listProc.fullOutput = "";
                listDelayTimer.restart();
            } else {
                console.info("PowerProfile: powerprofilesctl not found, trying tlp...");
                _startProc(checkTLP);
            }
        }
    }

    Timer {
        id: listDelayTimer
        interval: 100
        repeat: false
        onTriggered: _startProc(listProc)
    }

    Process {
        id: checkTLP
        workingDirectory: "/"
        command: ["/sbin/tlp", "--version"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const output = data.trim();
                if (output.length > 0)
                    console.info("PowerProfile: TLP version:", output);
            }
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                console.info("PowerProfile: TLP detected");
                backendType = "tlp";
                isAvailable = true;
                availableProfiles = ["power-saver", "balanced", "performance"];
                _startProc(getTLPProc);
            } else {
                console.warn("PowerProfile: No supported backend found, retrying in 3s...");
                isAvailable = false;
                retryTimer.start();
            }
        }
    }

    Process {
        id: getProc
        workingDirectory: "/"
        command: ["powerprofilesctl", "get"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const profile = data.trim();
                if (profile.length > 0) {
                    console.info("PowerProfile: Current profile:", profile);
                    currentProfile = profile;
                    profileChanged(profile);
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("PowerProfile: powerprofilesctl get failed");
        }
    }

    Process {
        id: listProc
        workingDirectory: "/"
        command: ["bash", "-c", "powerprofilesctl list 2>&1"]
        running: false

        property string fullOutput: ""

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                listProc.fullOutput += data + "\n";
            }
        }

        onExited: exitCode => {
            if (exitCode === 0 && fullOutput.trim().length > 0) {
                const lines = fullOutput.split('\n');
                const profiles = [];

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (line.endsWith(':')) {
                        const profileName = line.replace('*', '').replace(':', '').trim();
                        if (profileName.length > 0 && profiles.indexOf(profileName) === -1)
                            profiles.push(profileName);
                    }
                }

                const order = ["power-saver", "balanced", "performance"];
                profiles.sort((a, b) => {
                    const ia = order.indexOf(a);
                    const ib = order.indexOf(b);
                    if (ia === -1) return 1;
                    if (ib === -1) return -1;
                    return ia - ib;
                });

                availableProfiles = profiles;
                console.info("PowerProfile: Profiles loaded:", availableProfiles);
            } else {
                console.warn("PowerProfile: powerprofilesctl list failed (exit " + exitCode + "), retrying in 3s...");
                backendType = "";
                isAvailable = false;
                retryTimer.start();
            }

            fullOutput = "";
        }
    }

    Process {
        id: getTLPProc
        workingDirectory: "/"
        command: ["bash", "-c", "/sbin/tlp-stat -p 2>/dev/null | grep -i 'Active profile' | head -1"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line) return;

                console.info("PowerProfile: tlp-stat output:", line);
                let profile = "";

                if (line.includes("power-saver") || line.includes("powersaver"))
                    profile = "power-saver";
                else if (line.includes("balanced"))
                    profile = "balanced";
                else if (line.includes("performance"))
                    profile = "performance";

                if (profile && currentProfile !== profile) {
                    currentProfile = profile;
                    console.info("PowerProfile: Current profile:", profile);
                    profileChanged(profile);
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("PowerProfile: Failed to get TLP profile");
        }
    }

    Process {
        id: setProc
        workingDirectory: "/"
        running: false
        stdout: SplitParser {}
        stderr: SplitParser {
            onRead: data => {
                const err = data.trim();
                if (err.length > 0)
                    console.warn("PowerProfile: stderr:", err);
            }
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                console.info("PowerProfile: Profile set successfully");
                if (backendType === "powerprofilesctl")
                    _startProc(getProc);
                else if (backendType === "tlp")
                    _startProc(getTLPProc);
            } else {
                console.warn("PowerProfile: Failed to set profile (exit " + exitCode + ")");
            }
        }
    }

    function updateCurrentProfile() {
        if (!isAvailable) return;
        if (backendType === "powerprofilesctl")
            _startProc(getProc);
        else if (backendType === "tlp")
            _startProc(getTLPProc);
    }

    function updateAvailableProfiles() {
        if (!isAvailable) return;
        if (backendType === "powerprofilesctl") {
            availableProfiles = [];
            listProc.fullOutput = "";
            _startProc(listProc);
        } else {
            console.info("PowerProfile: TLP profiles are fixed:", availableProfiles);
        }
    }

    function setProfile(profileName) {
        if (!isAvailable) {
            console.warn("PowerProfile: Cannot set profile, backend not available");
            return;
        }

        let found = false;
        for (let i = 0; i < availableProfiles.length; i++) {
            if (availableProfiles[i] === profileName) {
                found = true;
                break;
            }
        }

        if (!found) {
            console.warn("PowerProfile: Unknown profile:", profileName);
            return;
        }

        console.info("PowerProfile: Setting profile to:", profileName, "via", backendType);
        currentProfile = profileName;
        profileChanged(profileName);

        if (backendType === "powerprofilesctl")
            setProc.command = ["powerprofilesctl", "set", profileName];
        else if (backendType === "tlp")
            setProc.command = ["sudo", "/sbin/tlp", profileName];

        _startProc(setProc);
    }

    function getProfileIcon(profileName) {
        if (profileName === "power-saver") return Icons.powerSave;
        if (profileName === "balanced") return Icons.balanced;
        if (profileName === "performance") return Icons.performance;
        return Icons.balanced;
    }

    function getProfileDisplayName(profileName) {
        if (profileName === "power-saver") return "Power Save";
        if (profileName === "balanced") return "Balanced";
        if (profileName === "performance") return "Performance";
        return profileName;
    }
}