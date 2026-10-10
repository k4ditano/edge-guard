#!/bin/sh
# Edge guard on your desktop, along the bottom edge of a monitor.
#
#   ./play.sh            on the monitor your compositor picks
#   ./play.sh DP-1       on that one (their names: `wlr-randr`, `hyprctl monitors`…)
#   ./play.sh stop       closes it
#
# It needs pleamar 0.3.0 or newer (https://github.com/k4ditano/pleamar) and a
# Wayland compositor with layer-shell. The first time, it puts the game's font
# (Monocraft, fonts/OFL.txt) in ~/.local/share/fonts.
here=$(dirname "$(readlink -f "$0")")
if ! command -v pleamar > /dev/null 2>&1; then
    echo "pleamar is not installed: see https://github.com/k4ditano/pleamar#install" >&2
    exit 1
fi
if [ "$1" = stop ]; then
    exec pleamar --say guard quit
fi
if command -v fc-list > /dev/null 2>&1 && ! fc-list | grep -qi monocraft; then
    fonts="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
    mkdir -p "$fonts" && cp "$here/fonts/Monocraft.ttc" "$fonts/" && fc-cache "$fonts" > /dev/null 2>&1
    echo "the game's font is now in $fonts"
fi
cd "$here" || exit 1
if [ -n "$1" ]; then
    exec pleamar --no-hud --scene guard.plm --screen "$1"
fi
exec pleamar --no-hud --scene guard.plm
