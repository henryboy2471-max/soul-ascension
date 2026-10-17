# Overnight progress report (started 2026-10-17 01:04 MDT, stop 07:00 MDT)
## Completed
- Character shaking cause found and fixed for the Hero and Mira (see STABILITY_QA.md), verified in the real browser; full suite 40/40; Ep1 12/12, Ep3 20/20.
- Walk<->idle and turning now dissolve (0.12 s) in exploration; found and fixed a draw-order bug in it by looking at real footage (tests alone had passed).
- Mira's run cycle had her torso sliding 105 src px across the canvas and snapping back at the loop: aligned on the torso (pixel shifts of existing frames), test added.
- Idle experiment: the 6 hero idle frames differ from each other by 156-321 (premultiplied-difference x1000) and no cyclic ordering is smoother than the original (223.7 vs 224.1), so no calm idle loop exists in the approved frames: static frame + 1% breath is the best idle available (documented evidence).
- Episode 2 reachable from Missions and steady (deviation 3.4, 0.0 sprite-frame changes/s).
- Performance: script _process cost is 34 us per frame for the whole exploration scene (negligible); draw-recording cost cannot be measured headless; export already excludes docs/tools/incoming/reference art. No speculative optimisation made.
## Active
- Full suite + browser playthroughs on the latest build; next candidates: Ep2 browser playthrough, remaining polish.
## Commits
- 79366ed shaking fix
- 8da4dca report + footage
- dbdf661, 9a706df dissolve transitions (+draw-order fix)
- next: Mira run alignment
## Remaining defects / blockers
- (none recorded yet)
## QA build
- pending ZIP for the commit that follows 79366ed
