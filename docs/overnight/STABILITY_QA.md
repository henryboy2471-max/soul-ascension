# Character shaking: cause, fix and evidence (commit 79366ed + docs)

## Cause (measured)
- The engine held the standing Hero perfectly still: node position range **0.000 px over 30 s** in the real browser, in both episodes. The camera, rounding and physics timing were NOT the cause.
- The shaking came from the art. The Hero's idle loop is 6 frames played at 6 fps, and between those frames the legs shift up to 6.6 source px and the torso 6.4 px (12 screen px), the cape changes shape, and the feet midpoint wanders 9 px (63.5 to 69.5). Mira's 16-frame idle at 8 fps is worse (legs 28 screen px, torso 44, including a large gesture frame). Pure shifting removes only 6-22% of the mismatch, so most of it is real pose change between frames, not just registration.
- The walk frames had the same problem (feet midpoint wandered 9 px across the 8 frames) and the flip for turning mirrored about a point 4.5 px away from the feet.

## Fix
- `tools/align_character_frames.py` writes pixel-exact shifted COPIES of the Hero's idle and walk frames (`assets/characters/hero/frames_aligned/`) so the feet midpoint is within 0.5 px of the canvas centre (the flip axis). Originals untouched; `frames.tres` points idle and walk at the copies. No resampling, no new art.
- In exploration (`Fighter.idle_hold`) the Hero and Mira stand on ONE existing idle frame with a smooth, eased breath (cosine, 3.6 s period, 1.0% tall, anchored at the feet). This is a temporary static-plus-breath idle chosen because it was the only option that met the stillness requirement with existing frames; it is NOT a final idle animation.
- Walk playback follows the ground speed: 90 px/s plays the 0.8 s cycle at 5.3 fps (reference 170 px/s from the foot spacing in the art, +-25%). Warden chamber unchanged.

## Stationary footage, before (c664430) vs after (real Chromium, 30 s, 25 fps video crops)
| metric | before | after |
|---|---|---|
| Hero (Ep 3) deviation from its average picture | 10.15 | 3.30 |
| Hero (Ep 3) frame-to-frame change | 4.41 | 0.99 |
| Hero (Ep 1) deviation / frame-to-frame | 11.21 / 4.32 | 4.20 / 1.16 |
| Mira (Ep 3) deviation / frame-to-frame | 7.85 / 3.53 | 2.22 / 0.62 |
| Engine sprite-frame changes per second (Hero) | 6.0 | 0.0 |
| Node position range x / y | 0.000 / 0.000 | 0.000 / 0.000 |
Noise floor (empty street patch, same video): about 1.0 deviation, 0.3 frame-to-frame. The remaining Hero value is the deliberate 1% breath. GIFs: `standing_hero_before_after.gif`, `standing_mira_before_after.gif`, `walking_before_after.gif`.

## Tests
`tests/test_character_stability.gd` (56 checks: 30 s standing at 60 fps and ragged pacing in both scenes, smooth breath, walk -> stop -> idle, turning, conversation, aligned frames within 1 px). Full suite 40/40 scripts. Browser: Episode 1 (production export, real input) 12/12; Episode 3 keyboard 20/20; production gate checks pass. Walking in the browser: 90 px/s, pose held ~194 ms (5.3 fps = 189 ms).

## Foot sliding: what the art allows (measured, overnight)
- Foot position relative to the TORSO (so independent of any frame alignment; identical in the original and aligned frames), frames 1-4 where a foot is planted: the back foot stays at -18.6, -17.5, -19.4, -17.0 source px from the torso (static within 1-2 px) and the front foot goes 13.0 -> 11.6 -> 9.5 (about 2 px per frame backward). Frames 5-7 have the legs together (-3.0, -2.0, -0.9). The hero's 8-frame walk is a near-static foot pattern ("shuffle") about 30 px wide.
- To glue a planted foot to ground moving at 90 px/s at 5.3 fps the body-relative foot travel would need to be about 9 source px per frame. It is about 0-2, so the planted feet skate at roughly 80-100% of the ground speed whatever the playback rate (a rate that would glue them, ~25+ fps, would be a cartoonish rapid shuffle). Matching playback to the ground and aligning the frames remove the lurching and the timing mismatch, not this.
- The real fix is art: a walk cycle whose planted feet travel about one step length (~36 source px) per half cycle. Not attempted (approved character art; needs your visual approval).
- Correction to an earlier figure: the 170 px/s animation reference came from foot SPACING; the foot TRAVEL measurement above shows spacing was not a valid stand-in for stride. The playback rate (5.3 fps) is therefore a judgement call, not a measured match.

## Other characters
- Procedural NPCs (Anselm 4.1, Teo 2.8 deviation) stand as steadily as the sprite characters (2.6-3.3) in the same footage method; their slow +-2 px sine bob is smooth. No change.
- Mira's run cycle slid her torso ~105 src px across the canvas and snapped back every loop: aligned on the torso (range now 0.8 px). Her run art also has little foot travel.

## Limits
- Static-plus-breath idle is a QA solution. Mira's run cycle art still swings her torso about +-50 px against her feet.
- Real Chromebook GPU frame pacing is unmeasured (F3 overlay in the QA build).
