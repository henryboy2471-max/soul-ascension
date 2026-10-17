# Overnight report (2026-10-17, started 01:04 MDT, written 03:55 MDT)
Branch `episode-3/the-relay-keeper`. Nothing merged, deployed or published; production release gate and export presets untouched.

## Result in one paragraph
Standing characters no longer tremble. The cause was the idle ART (6 mismatched frames cycled at 6 fps for Echo; 16 for Mira), not the camera or engine (node position range 0.000 px). Fix: one steady idle frame with a 1% eased breath in exploration, aligned frame copies, torso-aligned Mira run, dissolves for walk<->idle and turning, reduced-motion support. Verified on real browser video before/after, 63+ tests, full suite 41/41, Episode 1 and 3 playthroughs with keyboard and touch, production gate checks.

## Completed
| Item | Evidence |
|---|---|
| Shaking cause found | Hero idle frames differ 156-321 (premultiplied diff x1000), feet midpoint wandered 9 px; Mira legs 28 px, torso 44 px; no calmer cyclic order exists (223.7 vs 224.1), so static+breath is the best idle from existing art |
| Stillness footage (30 s, real Chromium) | Echo deviation 10.2 -> 3.3, frame-to-frame 4.4 -> 1.0; Mira 7.9 -> 2.2; sprite-frame changes/s 6.0 -> 0.0; same at 2x DPR (3.15); Episode 2 3.4; procedural NPCs (Anselm 4.1, Teo 2.8) already steady |
| Aligned frames | `tools/align_character_frames.py` (originals untouched): feet midpoint within 0.5 px of canvas centre (was 9 px range); Mira run torso range 0.8 px (was 105 px sawtooth with a snap at the loop point) |
| Transitions | 0.12 s dissolve for walk<->idle and turning; a draw-order bug (old pose sinking under the scenery) was caught by looking at real footage, not by tests; battle fighters unchanged |
| Pace | 90 px/s unchanged; walk playback 5.3 fps; Warden chamber unchanged at 300 px/s |
| Accessibility | reduced-motion setting now disables breath and dissolves |
| Robustness | `test_explore_fuzz` 24 checks (Ep1, Ep3 market, Warden chamber; ~170 dissolves, 35 locks, 19 teleports, 2000 hitches per run), no stuck input after touch-cancel or focus loss, window resize clean (16:9, 4:3, portrait overlay), console audit: only the 2 engine info lines |
| Performance | script `_process` total 34 us per frame (negligible); memory soak: no RSS leak trend (465-575 MB sawtooth), JS heap growth is QA-hook garbage [Inference]; draw cost cannot be measured headless; export already excludes docs/tools/incoming/reference art |

## Tests performed on the final code (8f17d87)
Full suite 41/41 scripts, 0 failing. Browser: Episode 1 production build 12/12 (keyboard) and 12/12 (touch, earlier code); Episode 3 20/20 keyboard and 20/20 touch (earlier code); prod gate browser check, CI pck check and `test_release_gate.py` pass; stuck-input pass; console audit clean.

## Commits (newest last, all on the branch)
79366ed shaking fix; 8da4dca report; dbdf661/9a706df dissolve (+draw-order fix); a5ca4fb Mira run; a157238..28291aa tools, fuzz, reduced motion; 8f17d87 docs.

## Remaining defects and decisions for you (none are code bugs I can fix alone)
1. **Foot skating is an art limit.** Planted feet barely travel relative to the body in Echo's walk (back foot static within 1-2 px, front foot ~2 px/frame; needed ~9 at 5.3 fps), so feet glide at ~80-100% of ground speed at any playback rate. Needs a new walk cycle (planted foot travel ~36 px per half cycle). The 5.3 fps playback is a judgement call, not a measured match (correction recorded in STABILITY_QA.md).
2. Idle is "static pose + breath" (a QA solution, not a final idle animation). If you want a living idle, it needs new frames that are registered to each other.
3. Mira's run art has little foot travel too and a large torso lean.
4. Real Chromebook GPU frame pacing is unmeasured: press F3 in the QA build and send the numbers.
5. Hero stops dead against a solid NPC (existing collision rule); below ~10 fps the game runs in slow motion (0.1 s frame cap).
6. Episode 2 has no end-to-end browser driver (the old driver replaces main.gd with an outdated copy); it is covered by `test_episode2` (38 checks), a browser start + stillness + console check.

## QA build
`soul-ascension-qa-<hash>-night2.zip` attached to the chat: NOT FOR RELEASE, README inside, exported assets verified present, pck identical to the build that passed the playthroughs.
