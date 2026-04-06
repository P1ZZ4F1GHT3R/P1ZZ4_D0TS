#!/usr/bin/env bash

# Kill any child listening jobs on exit so we don't spawn infinite zombies
trap 'kill $(jobs -p) 2>/dev/null' EXIT

# Wrap each listener in a subshell that sleeps infinitely if the command fails.
( pactl subscribe 2>/dev/null | grep --line-buffered -E "Event 'change' on sink" | head -n 1 || sleep infinity ) &
( nmcli monitor 2>/dev/null | grep --line-buffered -E "connected|disconnected|unavailable|enabled|disabled" | head -n 1 || sleep infinity ) &
( dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.bluez.Device1'" 2>/dev/null | grep --line-buffered "interface" | head -n 1 || sleep infinity ) &
( udevadm monitor --subsystem-match=power_supply 2>/dev/null | grep --line-buffered "change" | head -n 1 || sleep infinity ) &
( socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - 2>/dev/null | grep --line-buffered "activelayout" | head -n 1 || sleep infinity ) &

# --- THE 0-CPU MUSIC WATCHER ---
# playerctl outputs the current state on line 1, then waits silently. 
# `grep -m 2 ""` waits for line 2 (which means the song or status actually changed!).
# If playerctl crashes or no players are open, the pipeline fails safely into `sleep infinity`.
( playerctl metadata --follow --format '{{status}} {{title}}' 2>/dev/null | grep -m 2 "" | tail -n 1 | grep -q . && exit 0 || sleep infinity ) &

# Failsafe: Force a silent UI refresh every 60 seconds just in case an event is missed
sleep 60 &

# Wait for the *first* background job to successfully complete an event
wait -n

# Output a signal to ensure Quickshell's StdioCollector registers the stream completion
echo "trigger"
