# Ambxst Portable Shell

This tree has been trimmed for use inside an existing rice. It keeps:

- lockscreen
- bar
- original-style notch dashboard with the default widgets tab and system monitor tab
- matugen color generation
- IPC actions through `ambxst run ...`

Removed from startup/runtime:

- wallpaper manager and wallpaper picker
- settings window
- presets popup/switcher
- dock and desktop layer
- overview popup
- lockscreen music player
- bar layout switcher
- bar weather icon/weather popup
- bar system tray
- bar pin/auto-hide controls

The shell surface follows the configured bar screen list, which defaults to monitor `DP-1`.

## IPC Actions

Bind these from your compositor:

```sh
ambxst run dashboard
ambxst run assistant
ambxst run default
ambxst run system-monitor
ambxst run metrics
ambxst run launcher
ambxst run clipboard
ambxst run emoji
ambxst run notes
ambxst run tmux
ambxst run powermenu
ambxst run tools
ambxst run lockscreen
ambxst run close
```

Optional tool actions still available:

```sh
ambxst run screenshot
ambxst run screenrecord
ambxst run lens
```

## Matugen Without Wallpaper Management

Ambxst does not set wallpapers in this build. Your rice keeps owning wallpaper selection through `swww`/waytrogen, and Ambxst only consumes the selected image for colors and lockscreen display.

Your dotfiles already cache the currently selected wallpaper at:

```sh
~/.config/waytrogen/wallpaper.txt
```

The lockscreen reads that file directly. If the selected wallpaper is a GIF, it uses:

```sh
~/.config/waytrogen/gif-frame.jpg
```

That matches the existing `theme-sync.sh` behavior in your dotfiles.

To generate Ambxst colors from the active wallpaper after your wallpaper script runs:

```sh
wallpaper="$(cat ~/.config/waytrogen/wallpaper.txt)"
ambxst matugen "$wallpaper"
```

For GIF wallpapers, use the extracted frame for color generation:

```sh
wallpaper="$(cat ~/.config/waytrogen/wallpaper.txt)"
if [[ "$wallpaper" =~ \.(gif|GIF)$ ]]; then
  wallpaper="$HOME/.config/waytrogen/gif-frame.jpg"
fi
ambxst matugen "$wallpaper"
```

You can choose a matugen scheme explicitly:

```sh
ambxst matugen "$wallpaper" scheme-tonal-spot
ambxst matugen "$wallpaper" scheme-expressive
ambxst matugen "$wallpaper" scheme-fidelity
ambxst matugen "$wallpaper" scheme-content
```

`ambxst matugen` does two things:

- runs `matugen image <wallpaper> -c assets/matugen/config.toml -t <scheme>` so Ambxst gets `~/.cache/ambxst/colors.json`
- runs normal `matugen image <wallpaper> -t <scheme>` so your existing matugen templates can still update

To reuse the last source image:

```sh
ambxst run matugen-rerun
```

Suggested integration point for your dotfiles is near the end of `~/.config/scripts/theme/theme-sync.sh`, after the current wallpaper has been processed:

```sh
ambxst matugen "$wallpaper" scheme-tonal-spot
```

If Ambxst is not running yet, the command will print an IPC error. That is harmless during early startup; run it after Ambxst starts or guard it:

```sh
if pgrep -f 'qs.*Ambxst/shell.qml' >/dev/null; then
  ambxst matugen "$wallpaper" scheme-tonal-spot
fi
```

## Monitor And Workspaces

The bar/notch shell follows `screenList` and defaults to `DP-1`. Workspace indicators are fixed to five numbered buttons: `1 2 3 4 5`.

If you already have old generated Ambxst config, make sure these files agree:

```json
// ~/.config/ambxst/config/bar.json
{ "screenList": ["DP-1"], "showPinButton": false, "hoverToReveal": false }
```

```json
// ~/.config/ambxst/config/workspaces.json
{ "shown": 5, "showAppIcons": false, "alwaysShowNumbers": true, "showNumbers": true, "dynamic": false }
```

## Fullscreen Behavior

The bar is pinned for normal windows. It disappears under fullscreen windows and does not expose hover auto-hide or a pin button.
