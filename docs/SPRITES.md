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

## Hero import report (hero_approved_curly_sprite_sheet.png)

The board is a 1536x1024 presentation sheet (opaque dark background, labelled panels, reference art, effects, an in-game mock-up), not a frame grid. Every panel was inspected at 2-3x before cutting. Reproduce with `tools/import_hero.sh` (panel rectangles are in the script).

| Animation | Status | Notes |
| --- | --- | --- |
| idle | exported, 6 frames | Clean cut. The sheet's "side view" idles face the camera (front/three-quarter); the game flips them for left/right. |
| walk | exported, 8 frames | Cut at the emptiest column between figures (capes overlap, so an even grid slices bodies). Small dark shadow remnants at the feet in some frames. Scale-normalized (x1.29). |
| hurt | exported, 4 frames | Clean. Scale-normalized (x1.13). |
| defeat | exported, 6 frames | Good poses; a faint floor line remains on the last frame. Uses hurt's scale factor. |
| run | FLAGGED | 6 clean poses + 2 lightning frames against a label of 8; neighbouring frames overlap through the cape and every cut leaves slivers of the next figure. Game falls back to walk. |
| dash | FLAGGED | Label says 6, the panel holds 2 full-bleed lightning frames. Game shows code-drawn speed streaks over walk. |
| jump, land | FLAGGED | Effect streaks/dust split into fragments or overlap neighbours; not used by Episode 1. |
| block | FLAGGED | Frames cut by neighbours/shield effect; Episode 1 uses a code-drawn shield arc instead. |
| attack1, attack2, attack3 | FLAGGED | Labels promise 6/8/8 frames but 4 are present; attack1 cell 3 is a mis-scaled effect cell, attack3 cell 3 has no character, attack2 cells overlap their neighbours. Game shows code-drawn slash arcs over the idle/walk frames. |
| skill, finisher | FLAGGED | Full-bleed lightning scenes; the character cannot be separated from the effect background. Skill shows a code-drawn ring. |

How the cut was made: the dark armour is nearly the same colour as the dark navy background, so a plain colour key punched holes in legs and armour. The matte therefore removes only background connected to the panel edge (with a morphological opening that blocks leaks into armour), softens a 2 px edge band while un-mixing the navy fringe, and clears only enclosed pockets that are almost exactly the background colour. Each panel was normalized uniformly to the idle head width (no stretching), aligned on one canvas by its foot point.

Known limits: source frames are small (about 75-110 px tall) and are scaled about 1.6x in game, so the Hero is softer than a native-resolution sprite. Fully usable run/dash/attack/skill/jump animations need cleaner source cells (one animation per row with gaps, or transparent PNG strips). Until then the flagged states use the fallbacks above, which are code-drawn effects and never invented character frames.

## Mira import report (mira_sprite_sheet.png)

A 1774x887 production-style sheet with real transparency: seven rows of frames, all at one source scale (so no per-animation rescaling, `--scale-fixed 1.0`). The alpha has a faint low-alpha haze, so frames are detected on solid pixels (alpha > 150), haze below alpha 24 is cleared, and each crop keeps 5 px of glow falloff clamped away from neighbours. Reproduce with `tools/import_mira.sh`.

| Animation | Status | Notes |
| --- | --- | --- |
| idle | exported, 16 frames | Row 1, front-facing, clean gaps. |
| run | exported, 15 frames | Row 2, side view, valley cuts, no neighbour bleed. Also serves as the `walk` fallback (no separate walk row). |
| dash | exported, 6 frames | Row 3 frames 1-6 (side view with speed streaks), cleanly gap-separated. |
| walk | FLAGGED | No separate row; run is used. |
| jump, land | FLAGGED | Row 3 continues with an unlabeled 8-pose jump/crouch strip; the jump/land boundary would be a guess. |
| hurt, defeat | FLAGGED | Row 6: frame 4 merges with neighbours, prone frames overlap, and the row above spills into the cells. |
| attack1-3 | FLAGGED | Rows 4/7: slash arcs extend across neighbouring frames and fuse them into one blob. |
| skill | FLAGGED | Row 5: orbs and shock rings extend across neighbours; sizes vary wildly. |
| finisher | FLAGGED | Full-bleed energy scene; the character cannot be separated. |

In Episode 1 Mira only stands in the district and speaks in dialogue, so idle is what she uses; run/dash are ready for later episodes. Scale: world height 155 (set by measurement) makes her standing figure about 5% shorter than the Hero (167.8 px vs 177.6 px in the district). Her dialogue portrait is the idle sprite enlarged to face and shoulders.
