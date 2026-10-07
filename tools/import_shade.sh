#!/usr/bin/env bash
# Reproducible Resonance Shade import from assets/_incoming/resonance_shade/resonance_shade_sprite_sheet.png
# (1774x887 strip sheet with alpha, one source scale -> --scale-fixed 1.0). Regions are (x0,y0,x1,y1).
set -euo pipefail
cd "$(dirname "$0")/.."
SHEET=assets/_incoming/resonance_shade/resonance_shade_sprite_sheet.png
OUT=assets/enemies/resonance_shade
A="--bg none --alpha-min 150 --alpha-floor 24 --gap 3 --scale-fixed 1.0 --crop-pad 5"
rm -rf "$OUT/_trimmed" "$OUT/frames" "$OUT/manifest.json" "$OUT/frames.tres"
S="python3 tools/slice_sheet.py slice $SHEET --out $OUT"
# Row 1 holds 14 cleanly separated frames: 1-8 front-facing idle, 9 a three-quarter turn, 10-14 side-view stepping.
$S --anim idle --region 0,0,993,176      --frames 8 --fps 8 $A
$S --anim walk --region 1117,0,1774,176  --frames 5 --fps 9 $A
F="python3 tools/slice_sheet.py flag --out $OUT --source resonance_shade_sprite_sheet.png"
$F --anim run      --reason "Row 2 (11 side-view frames): smoke trails chain neighbouring frames together; no empty column between frames 1-5, adaptive and even cuts both merge or slice figures. Walk is used instead."
$F --anim dash     --reason "Row 2 frames 8-11 (lightning-flare variants of the run) fuse with their neighbours; not separable."
$F --anim hurt     --reason "Rows 5-6 mix recoil, lunge, summon-beam and falling poses with no labels; assigning a hit-reaction would be a guess. Game uses a white hit flash over idle."
$F --anim defeat   --reason "Rows 6-7 contain stagger, prone, collapse and dissolve frames, but prone frames overlap each other (one 413 px blob) and the rows mix an attack frame with a crescent. Game fades the idle sprite with a code-drawn purple dissolve."
$F --anim attack1  --reason "Row 3: large crescent slashes fuse every frame into two blobs (390 px and 1349 px wide); frames cannot be separated."
$F --anim attack2  --reason "Row 3: same as attack1."
$F --anim attack3  --reason "Row 3: same as attack1."
$F --anim skill    --reason "Row 4: orbs, staff beams and rings fuse into two blobs (538 px and 1205 px wide)."
$F --anim finisher --reason "Row 5-7 right: full-bleed rock/energy scenes with no separable character."
$F --anim jump     --reason "No jump/land frames identifiable on the sheet."
$F --anim land     --reason "No jump/land frames identifiable on the sheet."
python3 tools/slice_sheet.py finalize --out "$OUT"
