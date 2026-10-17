# Playable checkpoint for approval: `soul-ascension-qa-fcb8a6e-checkpoint.zip`
Built from commit `fcb8a6e` on `episode-3/the-relay-keeper` (later commits change documentation only). NOT FOR RELEASE. Not merged, deployed or published; production release gate unchanged.

## What was verified (all against the unzipped ZIP unless noted)
| Check | Result |
|---|---|
| Branch / commit | local HEAD = origin/episode-3/the-relay-keeper; only `docs/overnight/MORNING_REPORT.md` differed from the previously fully tested code (8f17d87) |
| Night 2 ZIP (c11015c) contents | all 9 game files byte-identical to a fresh export of HEAD; `frames_aligned` art present in its pck |
| Full automated suite | 41 scripts discovered, ran, 0 failing |
| Episode 1, production build, real input | 12/12 (372 s) |
| Episode 3, the ZIP's QA build, real input | 20/20 (540 s) |
| Production safety | pck has no packed QA hook; `test_release_gate.py` passes; production browser gate passes |
| Stuck input | touch cancel stops the hero; focus loss stops the hero |
| Console | only the 2 engine info lines per load; no warnings, errors or failed requests |
| Standing still 30 s (real video) | Echo Ep3 deviation 3.13 (was 10.15), Ep1 4.34 (was 11.21); Mira 2.07 (was 7.85); sprite-frame changes per second 0.0 (was 6.0); node position range 0.000 px |
| Walking / stopping / turning | walk -> stand and turn dissolve over ~0.12 s with the figure solid (stills strip); 90 px/s unchanged; Mira follows in place |
| Frame alignment (shipped art) | Echo idle/walk feet midpoint range 9.0 -> 1.0 px, worst 0.5 px from canvas centre; Mira run torso range 105.6 -> 0.7 px |

## Unresolved
1. Foot sliding: Echo's walk art plants no foot (planted feet move ~1.5 of the 9.0 source px per frame the ground needs at 90 px/s; about 84% of ground speed shows as skate). Needs new art: `docs/overnight/WALK_CYCLE_ART_SPEC.md`; measure with `tools/measure_foot_travel.py`. The 5.3 fps playback is a judgement, not a measured match.
2. Idle is "one steady pose + 1% breath" (a QA idle; no calm loop exists in the current frames).
3. Chromebook GPU frame pacing unmeasured: F3 check in the ZIP README.
4. The Warden chamber (300 px/s) skates more; it needs its own run cycle.
5. Episode 2: start, standing stillness and console verified in the browser; full run covered only by the 38-check headless test.
