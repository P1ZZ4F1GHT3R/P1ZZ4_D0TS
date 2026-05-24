-- Application keybinds

hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("godot"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("github-desktop fullscreen 0"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("codium"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd(terminal .. " -e pipes-rs -f 45 -k heavy,light -r 0.6"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(launcher .. " open"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(launcher .. " deeplink vicinae://launch/clipboard/history"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("ambxst run powermenu"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("skwd wall toggle"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("ambxst run lockscreen"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("ambxst run assistant"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(launcher .. " deeplink vicinae://extensions/vicinae/core/search-emojis"))
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("bash ~/.config/scripts/quickshell/qs_manager.sh toggle monitors"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("bash ~/.config/scripts/quickshell/qs_manager.sh toggle focustime"))


