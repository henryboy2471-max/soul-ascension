# Sprite pipeline

Episode 1 characters are procedural (`Fighter` rig) until approved sprite art is imported. The sprite layer is already in the game: a character with `assets/<group>/<name>/frames.tres` uses it automatically, otherwise it keeps the procedural rig. Gameplay state (health, combo, dash, hit flash, facing) stays on `Fighter`; only the visuals change.

## Folders
`assets/characters/hero`, `assets/characters/mira`, `assets/enemies/resonance_shade`, `assets/enemies/enforcer`, `assets/vfx`. Originals go in `assets/_incoming/<name>/` (not exported).

## Importing a sheet
```sh
python3 tools/slice_sheet.py slice assets/_incoming/hero/walk.png --out assets/characters/hero --anim walk --frames 8 --fps 10
python3 tools/slice_sheet.py slice assets/_incoming/hero/jump.png --out assets/characters/hero --anim jump --frames 6 --ground row --loop false
# ...one slice per animation, then:
python3 tools/slice_sheet.py finalize --out assets/characters/hero
godot --headless --editor --import --quit
godot --headless --path . --script res://tools/build_spriteframes.gd -- res://assets/characters/hero
```
- `slice` removes a solid background (or uses existing alpha), finds frames by their gaps (irregular spacing is fine), trims, and records each frame's foot point. `--grid RxC` forces a grid; `--bg #rrggbb`, `--tol`, `--gap` tune detection.
- `finalize` puts every frame of every animation on one canvas with the foot point at the same bottom-centre pixel, so there is no jitter. `--ground row` keeps vertical offsets for jump/air frames.
- Frames are never stretched, redrawn or invented. If the frame count differs from `--frames`, or frames touch/overlap, the animation is marked **flagged** in `manifest.json` and is not exported. Fix the sheet or re-run with `--force` after checking by eye.
- Sheets must face **right** (the game flips for left).

## Animations the game looks for
`idle` (required), `walk`, `run`, `dash`, `jump`, `land`, `attack1`, `attack2`, `attack3`, `skill`, `hurt`, `defeat`, `finisher`. Missing ones fall back (attack3 -> attack2 -> attack1 -> skill; run <-> walk; dash -> run -> walk; hurt/jump/land -> idle; finisher -> skill). Nothing is invented.
Combat mapping: attacks cycle attack1-3 per swing; Pulse/Rift/Ultimate/Mend play `skill`; dash plays `dash`; the district uses `walk`, battle movement uses `run`. `jump`/`land` are not used by Episode 1 yet.

## Tests
`python3 tools/test_slice_sheet.py`, `tools/test_pipeline.sh`, `tests/test_sprites.gd` (all synthetic fixtures, no game art).
