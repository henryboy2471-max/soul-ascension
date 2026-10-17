# Exploration walking pace 90 px/s: final QA report

Branch `episode-3/the-relay-keeper`, baseline `2d32183`. QA/dev only: not merged, not deployed, production release gate unchanged. Animation speed deliberately NOT changed (waiting for visual review).

## What changed
Normal exploration walks at 30% of the original 300 px/s = **90 px/s** (`Explore.WALK_SCALE`). The Warden chamber keeps **300 px/s** (`walk_scale: 1.0` in its zone) because its telegraph timing and fairness proof are built for it (`WardenLogic.SPEED`, 1.7 s telegraphs, 300 px sweeps). Scaled with the Hero: ease-in 0.3 s / ease-out 0.25 s, walk/idle thresholds, companion speed cap (1.15x top speed), pedestrians (35-70 -> 10.5-21 px/s), collision ease-around, footstep cadence, walk-cycle playback (gait = speed / 300). Camera smoothing constants, dialogue, combat, effects and UI are untouched.

## Exact speeds, before (`2d32183`) and after (headless simulation, identical code paths, 60 fps unless noted)
| measurement | before | after |
|---|---|---|
| Hero top speed, horizontal | 300 px/s | 90 px/s |
| Hero top speed, down/up the street | 165 px/s | 49.5 px/s |
| Time to walk 600 px from rest | 2.05 s | 6.82 s |
| Ease-in (to 95% speed) | 0.12 s | 0.30 s |
| Ease-out (release to stop) | 0.08 s | 0.25 s |
| Ambient pedestrians | 35.4-51.1 px/s | 10.6-15.3 px/s |
| Mira, steady follow | 300 px/s | 90 px/s |
| Mira, fastest after the hero turns around | 1,077 px/s | 103.5 px/s |
| Camera speed while walking | 300 px/s | 90 px/s |
| Walk animation playback | 10 fps (0.8 s per cycle) | 3 fps (2.67 s per cycle) |
| Distance in 6 s from rest, 30 / 60 / 144 / 240 fps | 1787 / 1785 / 1784 / 1783 px | 528 / 527 / 527 / 527 px |

Frame-rate independence: spread under 1% at every rate, so high-refresh screens do not run faster.

## Real browser (Chromium, 480x270, same drivers, baseline vs new build)
| | before | after |
|---|---|---|
| World distance walked holding the key for 5 s, Episode 1 / 3 | 1502 / 1507 px | 449 / 448 px (29.8%) |
| Time to walk 200 px from rest, Episode 1 / 3 | 0.75 / 0.91 s | 2.42 / 2.40 s |
| Top velocity reported by the game | 300 px/s | 90 px/s |
| Walk pose held on screen | ~100 ms | ~332 ms |
| Slow pedestrian step spread (lower = smoother) | 0.23 / 0.31 | 0.10 / 0.10 |
| Hero slide on screen after release | 2.5 / 1.9 s | 0.22 s |
| Console errors | 0 | 0 |

## Results
- Full automated suite on the final code: **39 scripts discovered, ran, 0 failing** (includes new `tests/test_walk_speed.gd`, 25 checks, and `tests/test_motion_smooth.gd`, 44 checks). Five older tests encoded the 300 px/s pace and were updated: `test_explore_motion`, `test_adventure`, `test_episode2`, `test_hero_sprites`, `test_release_candidate`.
- Episode 3 end to end in the browser: keyboard 667x375 **20/20**, touch 844x390 **20/20** (1196 s).
- Episode 1 end to end in the browser on the production export (real input): **12/12**. The first run showed 2 failures that were the driver's, not the game's: energy regenerates +1 per 300 s and the slower walk pushed the run to 370 s, so energy read 55 instead of 54 (gold, XP, level were exact). The driver now allows regeneration; the re-run passes.
- Production gate: CI pck check passes (no packed `scripts/qa/qa_hook`), `tools/test_release_gate.py` passes, production browser check shows no QA hook.

## Warden at original combat speed
Evidence: (1) headless: the Warden chamber config gives top speed 300 px/s and 95% speed in 0.12 s; `WardenLogic.SPEED` is still 300; (2) `test_warden_logic` and `test_relay_m4` (fairness proofs) pass in the suite; (3) the real-browser keyboard and touch playthroughs both defeat the Warden with real input (restoring VALVE, BELL, SEAL while dodging real telegraphs) and reach the rewards screen. **Not measured:** the driver does not log hit points taken, and the browser run did not sample the Hero's velocity inside the arena; (1) is the direct speed evidence.

## Walking animation: does 3 fps need improvement?
Short answer: **probably yes** (a visual judgement I cannot make myself; see the comparison GIF `walk_choppiness_3fps_vs_5fps.gif`).
- Measured: each pose is held ~332 ms on screen (was ~100 ms). The hero's 8-frame cycle takes 2.67 s.
- **Correction: I previously made an unverified claim. That was incorrect.** I stated that 3 fps gives "no foot sliding" because the cycle was "authored for 240 px of ground per cycle". That 240 px figure was my assumption (10 fps x 300 px/s x 0.8 s), never checked against the art, and `test_walk_speed.gd` currently encodes it.
- [Inference] From the boot positions in the 8 walk frames (5-15 px samples per foot, so roughly +-30%): one step is about 25-40 source px = 47-75 screen px, so a full cycle covers about 95-150 px of ground, not 240. At 90 px/s the cycle should then take about 1.1-1.7 s (4.8-7.6 fps, centre ~5.5-6), not 2.67 s.
- [Inference] At 3 fps the feet sweep at roughly 35-55 px/s against 90 px/s of ground: they glide forward relative to the ground (skating). The original 300 px/s with 10 fps had the same mismatch in the other direction (feet ~150-190 px/s against 300 px/s), which may be part of why the original looked slidy.
- Both slow poses and skating are therefore [Unverified] visually; the recommended candidate (NOT applied) is changing the animation reference speed from 300 to about 150 px/s, giving ~6 fps at 90 px/s. Alternatives: keep 3 fps, or a new walk cycle in an art phase. Mira's run cycle has the same slow-motion look (and her art has a separate torso drift).

## Remaining limits
- No real Chromebook GPU measurement exists. Press F3 in the QA build for a frame-time overlay. Software-GL frame-pacing numbers are noise (dropped-frame counts varied randomly between interleaved runs).
- Below ~10 fps the game runs in slow motion (0.1 s frame cap).
- Crossing the 3,400 px Episode 3 market now takes about 38 s.
- The hero still stops dead against a solid NPC (existing collision rule).
- Companion speed read from browser captures is a 3-frame screen estimate (about +-25 px/s; it showed 127 against the 103.5 cap); the exact values are from the simulation.
