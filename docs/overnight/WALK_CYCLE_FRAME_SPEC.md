# Walk / run cycle production spec (for review; no art or gameplay changed)

Extends `WALK_CYCLE_ART_SPEC.md`. Identity rule: Echo V2 and Mira keep their approved design, costume, palette, outline weight and proportions. Only the pose sequence is new. Existing frames stay in the game until the new set is approved.

## Current art, measured (`tools/measure_foot_travel.py`, body-relative)
| character | frames | canvas / figure | foot travel per frame | skate at 90 px/s |
|---|---|---|---|---|
| Echo walk | 8 @ 10 fps (played ~5.3) | 136x108 / 95 px tall | mean 1.5 (needs 9.0 at 5.3 fps) | ~84% |
| Mira run | 15 @ 14 fps (played slowed) | 258x153 / 122-139 px tall | mean 3.1 (needs ~half of that of Echo's per source px, see below) | ~65% at 5.3 fps |
Mira's on-screen scale was not read this turn [Unverified]; the 65% uses the tool's default scale.

## The rule that sets the numbers
planted-foot travel per frame (source px) = ground speed / (screen scale x playback fps).
Echo scale is 1.89 (from the earlier spec), so 90 px/s = 47.6 source px/s.

| cycle | speed | scale | fps x frames | cycle length | step (one foot to the other) | planted foot travel |
|---|---|---|---|---|---|---|
| Echo walk | 90 px/s | 1.89 | 8 x 8 | 1.0 s | 23.8 src px | 5.95 / frame |
| Echo Warden run | 300 px/s | 1.89 | 12 x 8 | 0.67 s | 52.9 src px | 13.2 / frame |
| Mira walk | 90 px/s | S (read from `attach_frames`) | 8 x 8 | 1.0 s | 90 / (2S) | 90 / (8S) |
Mira's S is needed before her art is drawn. Mira also needs a WALK: she follows at 90 px/s using her run art slowed down, and a run pose slowed to walking pace looks like slow motion.

## Echo walk: 8 frames, foot x relative to the pelvis (+ = forward), drawn facing right
Pelvis x is identical in every frame. The planted foot moves back 6 px per frame (24 px per step). Frames 5-8 mirror 1-4 with the other leg.
| # | pose | planted foot | swing foot | pelvis y | arms / cape |
|---|---|---|---|---|---|
| 1 | contact: heel strike, both feet on ground | +12 heel | -12 toes (heel up) | mid | opposite arm forward, cape trails back |
| 2 | down (recoil): weight onto front leg, knee bends | +6 flat | -6, lifting, knee bent | lowest (-1) | arms near body, cape settles |
| 3 | passing: swing foot beside the planted knee | 0 under pelvis | 0, raised highest | mid | arms cross the body, cape neutral |
| 4 | up: body rises over the planted leg, heel starts to lift | -6 | +6, reaching | highest (+1) | arms nearly at full swing, cape lifts forward |
| 5 | contact (other foot) | = frame 1 with legs swapped | | | |
| 6-8 | = frames 2-4 with legs swapped | | | | |
Weight transfer: pelvis dips at 2 and 6, rises at 4 and 8, total bob at most 2 source px. Torso lean 0-2 degrees forward. Head height changes by the same bob only (no separate head bounce). Cape and hair lag one frame behind the body and return smoothly; they are what reads as "shaking" if frames disagree.

## Echo Warden run: 8 frames at 12 fps, 300 px/s
Same registration rules, but the step is 52.9 source px, so the canvas must be wider (about 240 x 108) and the feet travel 13.2 px per frame while planted. Flight phase (both feet off the ground) in frames 3 and 7, contact in 1 and 5, torso lean 8-12 degrees, arms bent and pumping. If a wider canvas is not wanted, the fallback is 16 fps x 8 frames (0.5 s, step 39.7 px, 9.9 px per frame); that needs a speed-reference decision from the owner. The room's 300 px/s speed and `WardenLogic.SPEED` are not changed by any of this.

## Mira
- Walk: 8 frames, same table as Echo but scaled to her proportions (planted travel 90/(8S) per frame).
- Run (needed only where she actually moves faster than a walk; to be confirmed whether she follows in the Warden chamber [Unverified]): 8 frames at 12 fps, travel 300/(12S) per frame.
- Keep her current torso-lean style only if the owner wants it; otherwise lean 0-2 degrees for the walk. Idle frames stay as they are.

## Assets to commission
1. Echo walk, 8 frames, 136x108 (or 272x216).
2. Echo Warden-chamber run, 8 frames, about 240x108.
3. Mira walk, 8 frames, her canvas.
4. Mira run (conditional, see above).
Also per set: a contact sheet and a one-page pose sketch for approval before final frames. Transparent PNG, sole of the planted foot on the bottom row, drawn facing right (the game flips), frame names `walk_00..07`, `run_00..07`.

## Acceptance checks (all existing tools)
- `tools/measure_foot_travel.py <dir> walk --speed 90 --fps 8`: planted travel within 25% of the table.
- `tools/align_character_frames.py`: torso centroid range at most 2 px; bob at most 2 px.
- Palette / outline comparison with the approved idle frame (owner's visual check is the final gate).
- `tests/test_character_stability.gd` still passes; stationary footage unchanged.

## Next safe implementation checkpoint
1. Owner approves this spec (and answers: wider Warden canvas vs 16 fps fallback, 2x canvas yes/no, Mira run in the Warden chamber yes/no).
2. New art arrives in separate folders (`assets/characters/<name>/frames_proposed/`), not wired in. I run the checks above and build a side-by-side GIF (old vs new at 90 px/s).
3. Owner approves visually, then one commit re-points `frames.tres`, sets `ANIM_REF` / playback to 8 fps (one constant), adds the foot-travel check as a test, and a new QA ZIP is built. Idle fix, 90 px/s pace and the release gate stay untouched.
