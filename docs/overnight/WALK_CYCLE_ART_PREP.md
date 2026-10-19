# Walk / run cycle art preparation (owner decisions applied; nothing wired into the game)

**Update (final-art preparation):** Echo's run canvas is now 480x216 (owner decision); the 240x108 numbers further down are superseded by the row below and by `FINAL_ART_PREP.md`.

Supersedes the numbers in `WALK_CYCLE_FRAME_SPEC.md` where they differ (that table assumed Echo's 136x108 canvas). Regenerate everything with `python3 tools/walk_cycle_sketch.py`.

## Facts read from the code (this turn)
- Mira DOES follow Echo into the Warden chamber: `zone_defs.explore_config` sets `companion: true` for every Episode 3 zone, the arena sets no `no_default_npc`, and a headless run of the arena showed her visible, in her `run` animation, at 300 px/s beside Echo (hero 300.0, Mira peak 300.0). So Mira needs a RUN cycle as well as a WALK.
- Real on-screen scales (`fighter.attach_frames` = world_height / idle canvas height, times node scale 1.2): Echo 170/108 x 1.2 = **1.889**; Mira 155/153 x 1.2 = **1.216**. A 272x216 Echo walk canvas needs **0.944** (half), so when it is wired in the loader needs a per-animation scale and sprite offset (the code takes both from the idle frame only). That is a code change for the later wiring checkpoint.

## Required cycles (planted foot must move back this far per frame: speed / (scale x fps))
| set | canvas | fps | speed | planted travel / frame | step | cycle |
|---|---|---|---|---|---|---|
| Echo walk | 272x216 | 8 | 90 | **11.91** | 47.6 | 1.00 s |
| Echo Warden run (REVISED: 480x216, matches the walk's pixel density) | 480x216 | 12 | 300 | **26.47** | 105.9 | 0.67 s |
| Mira walk | 258x153 | 8 | 90 | **9.25** | 37.0 | 1.00 s |
| Mira run (Warden chamber) | 258x153 | 12 | 300 | **20.56** | 82.2 | 0.67 s |
Run cycles: contact on frames 1 and 5, mid-stance 2 and 6, AIR on 3-4 and 7-8 (both feet off the ground in two of every four frames), torso lean about 10 degrees, hardest pelvis drop in mid-stance (about 6% of leg length), rise in flight.
Walk cycles: pose table in `WALK_CYCLE_FRAME_SPEC.md` (contact, down, passing, up), scaled by the numbers above; pelvis bob at most 2% of leg length each way.
Identity constraints for the artist: approved Echo V2 design, scar, ponytail, forearm band, costume, palette, outline weight and on-screen size; approved Mira design and colours. The faint figure under every guide is the approved idle frame (scaled for the guide only), so the guide shows the proportions to match.

## What was produced (guides only, not art)
Under `assets/characters/{hero,mira}/frames_proposed/{walk,run}/`: `sketch_00..07.png` (stick pose over the idle silhouette), `contact_sheet.png` (pose names, foot x from the pelvis per frame), `params.json` (all numbers, foot x/lift/pelvis per frame), `compare_90pxs.gif` / `compare_300pxs.gif` (current art vs proposed guide at the real ground speed, real on-screen scale, scrolling ground ticks). A `.gdignore` in each `frames_proposed/` keeps Godot from importing or exporting them. Final art goes in the same folder as `walk_00..07.png` / `run_00..07.png`.
Built-in check: in the guide the planted foot moves at the ground speed (error 0 over 8 walk segments, 2 run segments). That is true by construction, so it proves the table arithmetic, not that any art is good. The real check is `tools/measure_foot_travel.py <folder> walk --speed 90 --fps 8 --scale 0.944` on the finished art.

## Points the owner should weigh [Inference unless noted]
1. **Resolution mismatch:** Echo's walk (272x216) and his run (240x108) differ by 2x in pixel density, so he will look sharper walking than running, and the 240x108 run needs the same per-animation scale code. A 480x216 run canvas would match; it is your call. (The idle stays at 136x108 either way.)
2. **Mira's current run art is leaned forward** while her idle is upright, which is part of why switching feels like a different pose; the new walk is keyed to her upright idle.
3. At 12 fps the run cycle is 8 frames in 0.67 s: each frame is on screen 83 ms. Foot positions jump 13-21 source px per frame; that is normal for sprite running but is why two of four frames are airborne.
4. Guides are mechanical (two-bone legs, fixed arm swing). They fix foot positions and timing, not drawing quality, costume or cape motion.
