#!/usr/bin/env bash
# Reproducible Soul-Warped Enforcer import from assets/_incoming/enforcer/enforcer_sprite_sheet.png
# (1774x887 strip sheet with alpha and a heavy orange haze, one source scale -> --scale-fixed 1.0).
# The haze needs a high threshold (alpha-min 200). Regions are (x0,y0,x1,y1).
set -euo pipefail
cd "$(dirname "$0")/.."
SHEET=assets/_incoming/enforcer/enforcer_sprite_sheet.png
OUT=assets/enemies/enforcer
A="--bg none --alpha-min 200 --alpha-floor 24 --gap 3 --scale-fixed 1.0 --crop-pad 5"
rm -rf "$OUT/_trimmed" "$OUT/frames" "$OUT/manifest.json" "$OUT/frames.tres"
S="python3 tools/slice_sheet.py slice $SHEET --out $OUT"
# Row 1 holds 14 separated frames: 1-8 front-facing idle, 9-10 a turn into the lean (skipped), 11-14 side-view stepping.
$S --anim idle --region 0,0,916,176      --frames 8 --fps 8 $A
$S --anim walk --region 1180,0,1774,176  --frames 4 --fps 9 $A
# Row 2 frames 1-6 are the side-view run; frame 7 onward (spear thrust) fuses through the fire trails.
$S --anim run  --region 0,170,842,312    --frames 6 --fps 11 $A
F="python3 tools/slice_sheet.py flag --out $OUT --source enforcer_sprite_sheet.png"
$F --anim dash     --reason "Row 2 frames 7-11 (spear-thrust lunge) fuse with their neighbours through the fire trails; not separable."
$F --anim hurt     --reason "Lower rows mix recoil, lunge and falling poses with no labels; assigning a hit-reaction would be a guess. Game uses a white hit flash over idle."
$F --anim defeat   --reason "Lower rows contain stagger/prone/collapse frames that overlap each other and the full-bleed scenes. Game fades the idle sprite with a code-drawn dissolve."
$F --anim attack1  --reason "Row 3: slash crescents and fire arcs fuse frames together; cannot be separated."
$F --anim attack2  --reason "Row 3: same as attack1."
$F --anim attack3  --reason "Row 3: same as attack1."
$F --anim skill    --reason "Row 4: orbs, beams and flame rings fuse into merged blobs."
$F --anim finisher --reason "Bottom rows: full-bleed rock/fire scenes with no separable character."
$F --anim jump     --reason "No jump/land frames identifiable on the sheet."
$F --anim land     --reason "No jump/land frames identifiable on the sheet."
python3 tools/slice_sheet.py finalize --out "$OUT"
