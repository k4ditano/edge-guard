#!/bin/sh
# Edge guard on your desktop, along the bottom edge of a monitor.
#
#   ./play.sh            on the monitor your compositor picks
#   ./play.sh DP-1       on that one (their names: `wlr-randr`, `hyprctl monitors`…)
#   ./play.sh stow       puts it away into its corner, or brings it back (for a key)
#   ./play.sh stop       closes it
#
# It needs pleamar 0.4.10 or newer (https://github.com/k4ditano/pleamar) and a
# Wayland compositor with layer-shell. The first time, it puts the game's font
# (Monocraft, fonts/OFL.txt) in ~/.local/share/fonts.
here=$(dirname "$(readlink -f "$0")")
# Started with the desktop, ~/.local/bin (where pleamar's installer puts it) may not be on the PATH yet.
PATH="$PATH:$HOME/.local/bin"
if ! command -v pleamar > /dev/null 2>&1; then
    echo "pleamar is not installed: see https://github.com/k4ditano/edge-guard#install" >&2
    exit 1
fi
running() { pleamar --say guard "get away" > /dev/null 2>&1; }
case "$1" in
    stop) exec pleamar --say guard quit ;;
    stow) exec pleamar --say guard "emit stow" ;;
esac
if running; then
    echo "Edge guard is already on your desktop: ./play.sh stow brings it out, ./play.sh stop closes it" >&2
    exit 1
fi
need=0.4.10
have=$(pleamar --version 2>/dev/null | sed -n 's/^pleamar \([0-9.]*\).*/\1/p')
if [ -n "$have" ] && [ "$(printf '%s\n%s\n' "$need" "$have" | sort -V | head -1)" != "$need" ]; then
    echo "Edge guard needs pleamar $need or newer, and this is $have: update it (pleamar-update, or nix flake update)" >&2
    exit 1
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
