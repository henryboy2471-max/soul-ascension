#!/usr/bin/env bash
# Reproducible Mira import from assets/_incoming/mira/mira_sprite_sheet.png (1774x887 strip sheet with alpha).
# Regions are (x0,y0,x1,y1). All rows share one source scale, so --scale-fixed 1.0 (no head-based rescaling).
set -euo pipefail
cd "$(dirname "$0")/.."
SHEET=assets/_incoming/mira/mira_sprite_sheet.png
OUT=assets/characters/mira
A="--bg none --alpha-min 150 --alpha-floor 24 --gap 3 --scale-fixed 1.0 --crop-pad 5"
rm -rf "$OUT/_trimmed" "$OUT/frames" "$OUT/manifest.json" "$OUT/frames.tres"
S="python3 tools/slice_sheet.py slice $SHEET --out $OUT"
$S --anim idle --region 0,0,1774,152     --frames 16 --fps 8  $A
$S --anim run  --region 0,150,1774,285   --grid 1x15 --valley --fps 14 $A
$S --anim dash --region 0,284,864,412    --frames 6 --fps 14 --loop false $A
F="python3 tools/slice_sheet.py flag --out $OUT --source mira_sprite_sheet.png"
$F --anim walk     --reason "No separate walk row exists; run (side view) is used as the walk fallback."
$F --anim jump     --reason "Row 3 holds an unlabeled 8-pose jump/crouch strip after the dash; the jump/land boundary cannot be determined reliably."
$F --anim land     --reason "See jump: unlabeled strip, boundary between jump and land is a guess."
$F --anim hurt     --reason "Row 6: frame 4 merges with neighbours and the row above spills into the cells."
$F --anim defeat   --reason "Row 6: prone frames overlap each other and pick up spill from the row above."
$F --anim attack1  --reason "Rows 4/7: slash arcs extend across neighbouring frames and fuse them into one blob; frame boundaries are not recoverable."
$F --anim attack2  --reason "Rows 4/7: same as attack1."
$F --anim attack3  --reason "Rows 4/7: same as attack1."
$F --anim skill    --reason "Row 5: orbs and shock rings extend across neighbouring frames; heights and widths vary wildly."
$F --anim finisher --reason "Rows 6/7: full-bleed energy scene; the character cannot be separated from the effect."
python3 tools/slice_sheet.py finalize --out "$OUT"
