# Exploration movement smoothness (Episode 1 and Episode 3 scenes)

Branch `episode-3/the-relay-keeper`, from `2d32183`. QA/dev only: no merge, no deploy, production release gate unchanged, no artwork touched.

## What was wrong (measured, not assumed)
| # | Cause | Evidence before the fix |
|---|---|---|
| 1 | Companion (Mira) chased a target that flipped 180 px when the hero turned around, with a pure exponential ease and no speed limit | Peak speed 1,058 px/s in simulation (596-631 px/s measured in the browser at 30 fps) against a hero top speed of 300 px/s: the "teleport" |
| 2 | Characters and scenery were rounded to whole *logical* pixels | A 40 px/s pedestrian moved 0, 1, 1, 0, 1 px per frame; step spread (std/mean) 0.27-0.35 in the browser. On a stretched Chromebook window one logical pixel is 1.07-2 device pixels, so this was coarser than the screen |
| 3 | Camera look-ahead recentred 70 px after the hero stopped, plus an exponential tail that never ended | The world kept gliding for 1.4-2.4 s after the hero stopped (idle hero moved 1 px in the final idle second at 30 fps) |
| 4 | Walk/run animations played at a fixed rate whatever the speed (hero 10 fps, Mira 14 fps, rig at 12/s) | Walking up or down (0.55 of full speed) played the cycle at 100% speed: feet skate |
| 5 | No cap on frame delta | A 600 ms hitch moved the hero 180 px in one frame (and could step past a solid NPC) |
| 6 | walk/idle flag flipped at a single 25 px/s threshold | no visible flicker was found in the browser runs; hysteresis added as a cheap guard |

Checked and **not** causes: walkers flipping direction at the world edges (they flip once), footstep audio (pre-generated clips from a pool), the idle pose (idle characters were already stable).

## Fix (smallest set that addressed each measured cause)
- `Explore`: companion eases toward a side that blends over ~0.7 s and her speed is capped at 345 px/s; scenery snaps to whole **device** pixels, characters keep their exact position in that view; camera look-ahead holds when the hero stops and the camera settles instead of creeping; frame delta capped at 0.1 s; walk flag with hysteresis; companion facing hysteresis.
- `Fighter.gait`: walk/run animation speed and the procedural leg swing follow the real pace (battle fighters keep 1.0).
- Test change: `tests/test_explore_motion.gd` asserted "sprites are whole pixels"; it now asserts scenery on whole device pixels and characters at their exact position.

## Before and after (Chromium, software GL, 480x270 so the renderer reaches ~30 fps; interleaved runs)
| metric | before | after |
|---|---|---|
| Slow pedestrian, step spread (lower = smoother), Ep1 | 0.27 / 0.35 | 0.08 / 0.06 |
| Slow pedestrian, step spread, Ep3 | 0.34 / 0.31 | 0.11 / 0.09 |
| Hero keeps sliding on screen after release, Ep1 | 1.46 / 1.42 s | 0.46 / 0.44 s |
| Hero keeps sliding on screen after release, Ep3 | 1.39 / 0.87 s | 0.54 / 0.55 s |
| Companion fastest speed after turning (hero 300), Ep3 | 596 / 631 px/s | 314 / 305 px/s |
| Idle hero on-screen range | 0 to 1 px | 0 px |
| 1366x768 (device-pixel scale 1.07), Ep3 slide after release | 2.00 s | 0.67 s |
| Console errors | 0 | 0 |

Deterministic simulation (`tests/test_motion_smooth.gd`, 60 fps, 30 fps and ragged 30/20 fps, both episode scenes): 44 checks, 28 fail on `2d32183`, 0 fail now. Chart: `tools/qa/motion_chart.py`.

## What did NOT change (be careful with claims)
- **Frame pacing / dropped frames: unchanged.** Interleaved before/after runs gave dropped-frame counts of 46 vs 31, 9 vs 17, 31 vs 15, 7 vs 7: noise. No code path that affects render cost was changed.
- No single render hot spot exists (hiding layers, props, fighters, HUD, atmosphere each saved only a few ms); SwiftShader numbers do not represent a Chromebook GPU.

## Remaining limits and findings
- **Chromebook performance is unverified.** Software GL cannot reproduce a real GPU. In the QA build press **F3** to show FPS / average ms / worst ms / frames over 25 ms for the last second, and note them while walking.
- Mira's run art: torso swings about +-50 source px relative to her feet over the loop (art registration). Left alone; it is an art-pass item.
- The hero still stops dead against a solid NPC (existing collision rule).
- If a device runs below 10 fps the game runs in slow motion because of the 0.1 s frame cap.

## Tools
`tools/qa/motion_browser.cjs` (EP=1|3) records per-frame positions through the QA hook probe, `tools/qa/motion_report.py [--table before after]` reports them, `tools/qa/cost_browser.cjs` is the render-cost experiment. The hook and F3 overlay exist only in the "Web QA" export; the production pck is verified free of them (the CI check passes).
