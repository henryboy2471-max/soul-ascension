#!/bin/sh
# Switch the Hollow Cantor frame import mode (both variants stay supported): lossless | vram
# Usage: tools/set_cantor_textures.sh lossless|vram   then re-import: godot --headless --editor --import --quit
case "$1" in
 lossless) from=2; to=0;;
 vram) from=0; to=2;;
 *) echo "usage: $0 lossless|vram"; exit 2;;
esac
dir="$(dirname "$0")/../assets/enemies/hollow_cantor"
find "$dir" -name '*.png.import' -exec sed -i "s/compress\/mode=$from/compress\/mode=$to/" {} +
echo "Cantor frames set to $1 (re-import the project)"
