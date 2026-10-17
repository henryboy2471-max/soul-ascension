# Overnight progress report (started 2026-10-17 01:04 MDT, stop 07:00 MDT)
## Completed
- Character shaking cause found and fixed for the Hero and Mira (see STABILITY_QA.md), verified in the real browser; full suite 40/40; Ep1 12/12, Ep3 20/20.
- Walk<->idle and turning now dissolve (0.12 s) in exploration; found and fixed a draw-order bug in it by looking at real footage (tests alone had passed).
- Mira's run cycle had her torso sliding 105 src px across the canvas and snapping back at the loop: aligned on the torso (pixel shifts of existing frames), test added.
- Idle experiment: the 6 hero idle frames differ from each other by 156-321 (premultiplied-difference x1000) and no cyclic ordering is smoother than the original (223.7 vs 224.1), so no calm idle loop exists in the approved frames: static frame + 1% breath is the best idle available (documented evidence).
- Episode 2 reachable from Missions and steady (deviation 3.4, 0.0 sprite-frame changes/s).
- Performance: script _process cost is 34 us per frame for the whole exploration scene (negligible); draw-recording cost cannot be measured headless; export already excludes docs/tools/incoming/reference art. No speculative optimisation made.
- Verified candidate (commit 1c6d24c content): full suite 41/41; Ep1 production playthrough 12/12; Ep3 keyboard 20/20; production gate + CI pck check pass; stuck-input (touch cancel, focus loss) pass; window-resize check clean; memory soak shows no RSS leak trend.
- New tests/tools: test_character_stability (63), test_explore_fuzz (24: Ep1, Ep3 market, Warden chamber, random input/hitches/locks/teleports with coverage asserted), idle/transition/walk footage drivers, stuck_input, resize_check, memory_soak, cpu/script cost probes.
- Found and documented: the hero's walk art has near-static planted feet (shuffle), so foot skating cannot be removed by timing alone (needs a new walk cycle: art decision).
## Active
- Next: Ep2 deeper checks, remaining polish; final refresh of the ZIP before 07:00.
## Commits
- 79366ed shaking fix
- 8da4dca report + footage
- dbdf661, 9a706df dissolve transitions (+draw-order fix)
- a5ca4fb Mira run alignment; a157238..01d17e7 soak/stuck-input/resize/fuzz/tooling
## Remaining defects / blockers
- (none recorded yet)
## QA build
- pending ZIP for the commit that follows 79366ed
