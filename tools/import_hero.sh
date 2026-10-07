#!/usr/bin/env bash
# Reproducible Hero import from assets/_incoming/hero/hero_approved_curly_sprite_sheet.png.
# Panel rectangles are (x0,y0,x1,y1) in the 1536x1024 board. Re-run after changing any value, then build frames.tres.
set -euo pipefail
cd "$(dirname "$0")/.."
SHEET=assets/_incoming/hero/hero_approved_curly_sprite_sheet.png
OUT=assets/characters/hero
M="--bg-mode matte --tol 26 --tol-hi 46 --opening 2 --enclosed 11 --gap 4 --floor-strip"
rm -rf "$OUT/_trimmed" "$OUT/frames" "$OUT/manifest.json" "$OUT/frames.tres"
S="python3 tools/slice_sheet.py slice $SHEET --out $OUT"
$S --anim idle   --region 958,306,1522,404 --frames 6 --fps 6 $M
$S --anim walk   --region 16,452,384,531   --grid 1x8 --valley --fps 10 $M
$S --anim hurt   --region 18,722,246,803   --grid 1x4 --valley --fps 12 --loop false $M
$S --anim defeat --region 492,722,844,806  --grid 1x6 --valley --fps 8  --loop false --scale-like hurt $M
F="python3 tools/slice_sheet.py flag --out $OUT --source hero_approved_curly_sprite_sheet.png"
$F --anim run      --reason "Run panel (6 clean poses + 2 lightning frames, label says 8): neighbouring frames overlap through the cape, grid/valley cuts leave slivers of the next figure."
$F --anim dash     --reason "Label says 6 frames but the panel holds 2 full-bleed lightning frames; no separable character frames."
$F --anim jump     --reason "Effect streaks split into detached fragments; background does not matte cleanly."
$F --anim land     --reason "Dust clouds overlap neighbouring frames; frames are cut by the cell boundaries."
$F --anim block    --reason "Frames are cut by neighbours/shield effect; not used by Episode 1 (block uses an overlay)."
$F --anim attack1  --reason "Label says 6 frames, 4 present; cell 3 is a slash-effect cell with the character at a different scale."
$F --anim attack2  --reason "Label says 8 frames, 4 present; slash arcs and neighbouring figures overlap every cell."
$F --anim attack3  --reason "Label says 8 frames, 4 present; cell 3 is a pure effect swoosh with no character."
$F --anim skill    --reason "Full-bleed lightning scenes; the character cannot be separated from the effect background."
$F --anim finisher --reason "Full-bleed lightning scenes; the character cannot be separated from the effect background."
python3 tools/slice_sheet.py finalize --out "$OUT" --ref-anim idle
