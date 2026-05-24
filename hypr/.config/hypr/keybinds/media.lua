-- Media and system keybinds

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(volumeBrightness .. " volume_up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(volumeBrightness .. " volume_down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(volumeBrightness .. " volume_mute"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(volumeBrightness .. " mic_mute"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(volumeBrightness .. " brightness_up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(volumeBrightness .. " brightness_down"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(volumeBrightness .. " play_pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(volumeBrightness .. " play_pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(volumeBrightness .. " next_track"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(volumeBrightness .. " prev_track"), { locked = true })

-- Tools
hl.bind("ALT + SHIFT + S", hl.dsp.exec_cmd("ambxst run tools"))
