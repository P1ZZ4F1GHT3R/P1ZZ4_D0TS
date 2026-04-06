import Quickshell.Io
import QtQuick

Process {
  id: dlProc

  property string workshopId
  property string steamDir: ""
  property string steamUsername: ""

  signal progressUpdate(string id, real pct)
  signal done(string id, bool success)

  readonly property string _login: steamUsername || "anonymous"

  command: steamDir
    ? ["steamcmd", "+force_install_dir", steamDir, "+login", _login, "+workshop_download_item", "431960", workshopId, "+quit"]
    : ["steamcmd", "+login", _login, "+workshop_download_item", "431960", workshopId, "+quit"]

  stderr: SplitParser {
    splitMarker: "\n"
    onRead: data => {
      var match = data.match(/(\d+)\s*\/\s*(\d+)\s*bytes/)
      if (match) {
        var got = parseInt(match[1])
        var total = parseInt(match[2])
        if (total > 0) dlProc.progressUpdate(dlProc.workshopId, got / total)
      }

      var pctMatch = data.match(/(\d+(?:\.\d+)?)\s*%/)
      if (pctMatch) {
        dlProc.progressUpdate(dlProc.workshopId, parseFloat(pctMatch[1]) / 100.0)
      }
    }
  }

  stdout: SplitParser {
    splitMarker: "\n"
    onRead: data => {
      var match = data.match(/(\d+(?:\.\d+)?)\s*%/)
      if (match) {
        dlProc.progressUpdate(dlProc.workshopId, parseFloat(match[1]) / 100.0)
      }

      if (data.indexOf("Success") >= 0 || data.indexOf("fully installed") >= 0) {
        dlProc.progressUpdate(dlProc.workshopId, 1.0)
      }
    }
  }

  onExited: function(exitCode, exitStatus) {
    if (exitCode === 0) {
      dlProc.progressUpdate(dlProc.workshopId, 1.0)
      dlProc.done(dlProc.workshopId, true)
    } else {
      dlProc.done(dlProc.workshopId, false)
    }
  }
}
