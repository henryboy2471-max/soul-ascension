#!/usr/bin/env bash
# End-to-end check of the sprite pipeline on a synthetic character: slice -> finalize -> import -> SpriteFrames -> Fighter.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
OUT=tests/fixtures/_pipeline
rm -rf "$OUT" && mkdir -p "$OUT"
python3 - <<'PY'
import sys
sys.path.insert(0, "tools")
import test_slice_sheet as t
t.make_sheet("tests/fixtures/_pipeline/walk.png", 6, [6, 20, 9, 44, 12, 7], [180, 183, 178, 181, 180, 185])
t.make_sheet("tests/fixtures/_pipeline/idle.png", 4, [10, 10, 10, 10], [180, 181, 180, 181], seed=5)
PY
python3 tools/slice_sheet.py slice "$OUT/idle.png" --out "$OUT/char" --anim idle --frames 4 --fps 6
python3 tools/slice_sheet.py slice "$OUT/walk.png" --out "$OUT/char" --anim walk --frames 6 --fps 10
python3 tools/slice_sheet.py finalize --out "$OUT/char"
$GODOT --headless --editor --import --quit >/dev/null 2>&1
$GODOT --headless --path . --script res://tools/build_spriteframes.gd -- res://tests/fixtures/_pipeline/char 2>&1 | grep -E "BUILT|SKIP|ERROR"
cat > "$OUT/check.gd" <<'GD'
extends SceneTree
func _initialize() -> void:
 var f=load("res://scripts/combat/fighter.gd").new()
 var ok=f.load_sprite_set("res://tests/fixtures/_pipeline/char/frames.tres")
 var frames=f.sprite_frames
 var good=ok and frames.get_frame_count("idle")==4 and frames.get_frame_count("walk")==6 and is_equal_approx(frames.get_animation_speed("idle"),6.0)
 print("PIPELINE ", "PASS" if good else "FAIL", " anims=", frames.get_animation_names() if frames else [])
 quit(0 if good else 1)
GD
$GODOT --headless --path . --script res://tests/fixtures/_pipeline/check.gd 2>&1 | grep -E "PIPELINE|SCRIPT"
