#!/bin/sh
# The game's pictures, made again from their sources: the characters and
# blocks are built and rendered by Blender (make.py), packed into sheets
# (pack.py), and the things are drawn pixel by pixel (items.py).
# It needs Blender and Python's Pillow. The frames go to art/frames (not kept).
set -e
here=$(dirname "$(readlink -f "$0")")
blender -b --factory-startup -P "$here/make.py" -- "$here/frames"
python3 "$here/pack.py" "$here/frames"
python3 "$here/items.py"
