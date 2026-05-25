#!/bin/bash

sleep 1
hyprctl dispatch 'hl.dsp.focus({workspace = "6"})' 
sleep 0.5
hyprctl dispatch 'hl.dsp.exec_cmd("ghostty -e pipes-rs -f 45 -k heavy,light -r 0.6", {fullscreen = true})'
sleep 1
hyprctl dispatch 'hl.dsp.focus({workspace = "1"})'