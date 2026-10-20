# Echo V2 animation contract (replaces the proposed G4 contract for THIS game)

The old G4 contract (`tools/validate_approved_art.py`, `HERO_PRODUCTION_DELIVERABLES_CHECKLIST.md`) assumes four directions, 576x1152 frames, idle 2 and walk 6 per view. The Godot game does not work that way, so the proposed requirement is rewritten from the code. The old validator and the G2 gate are **unchanged**; this contract is a proposal that takes effect only when you approve it, and the new checker (`tools/check_echo_v2_frames.py`) is separate from the existing gates.

## How the game uses character art (read from `scripts/combat/fighter.gd`, `battle.gd`, `explore.gd`)
- **One facing.** Art is drawn facing RIGHT; the engine flips horizontally when the character faces left (`sprite.flip_h = facing < 0`). No front, back, three-quarter or left frames are used in play. The four native 1280x2304 views are the master from which the side frames are made; the left view is design reference for asymmetric details.
- **Anchor and scale.** Frames are bottom-centre anchored (feet on the bottom row, body centred; the node origin is the canvas bottom-centre). Scale is `world_height / idle canvas height x node scale 1.2`, taken from the idle frame only, so every state that shares the idle canvas scales identically. A different canvas (the 480x216 run) needs the approved per-animation scale-and-offset loader change, which is not implemented and is not part of this contract's delivery.
- **Premium anime rendering, not pixel art.** Frames are downsampled from the native master with one fixed recipe (smooth, anti-aliased, same palette and outline weight in every state). Nothing is pixel-snapped or posterised.
- **Exploration** (`explore.gd`): idle is a held frame 0 plus a 1% breath; walk plays at gait-scaled speed; walk <-> idle and turns dissolve over 0.12 s; reduced motion disables the breath and dissolves. The Warden chamber currently plays "walk" at full speed (a future switch to "run" there is a code change, separately approved).
- **Battle** (`battle.gd`): moving uses "run" (`run_speed_threshold = 1.0`), a swing uses `attack1..3` (combo), casting uses `skill`, dodging uses `dash` (trailing), a hit uses `hurt`, defeat uses `defeat`. Missing animations fall back (attack3 -> attack2 -> attack1 -> skill; skill -> attack1; finisher -> skill/attack3/attack1; run <-> walk; dash -> run/walk; hurt/jump/land -> idle; defeat -> hurt -> idle); with no `attack1`/`skill` art the code draws procedural swing and cast effects.

## Required states, frame counts, canvases (proposal; frame counts for combat are sizing proposals needing your approval)
| state | used by | frames @ fps | canvas | notes |
|---|---|---|---|---|
| idle | exploration, battle | 1 held pose (optional 4-6 frame calm loop later) @ 6 | 272x216 | defines scale for the others; feet and body identical in any loop |
| walk | exploration | 8 @ 8 | 272x216 | pose guides approved; planted foot 11.91 px/frame at 90 px/s |
| run | battle movement; Warden chamber (future) | 8 @ 12 | **480x216** | 300 px/s; planted foot 26.47 px/frame; both feet airborne on frames 3-4 and 7-8 |
| attack1, attack2, attack3 | battle combo | 6 @ 10 each (swing lasts 0.30 s) | 272x216 | anticipation, strike, follow-through; no baked VFX |
| skill | battle cast (0.45 s) | 8 @ 10 | 272x216 | no baked VFX (effects stay in code) |
| dash | battle dodge | 4 @ 14 | 272x216 | horizontal, feet may leave the bottom row only if the pose is airborne |
| hurt | on hit | 4 @ 12 | 272x216 | same recipe |
| defeat | KO | 6 @ 8 | 272x216 | ends on a held final pose; may lie low on the canvas |
Not required by the code today: block, jump, land, finisher (fallbacks exist). Portraits, key art, title/home screens and dialogue art are separate assets outside this contract.

## Per-frame requirements (structural, enforced by `tools/check_echo_v2_frames.py`)
Exact canvas; PNG RGBA with transparent corners; planted sole on the bottom row (idle, walk, run, hurt, attacks); body centred on the canvas centre column; at least 90% opaque and at most 8% soft pixels; no #00FF00; frame count exactly as in the table; files named `<state>_00.png ...` in `assets/characters/hero/frames_proposed/<state>/`. Walk and run also pass `tools/measure_foot_travel.py` (planted travel within 25% of the guide value). Visual gates the tools cannot judge (identity, palette, face, ponytail, costume, eyes, no scar change) are the owner's.
Nothing is wired into the game, and the current in-game Echo stays until the complete V2 replacement is approved.
