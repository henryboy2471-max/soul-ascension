# Overnight master development mission (2026-10-20): working log
(Final report is written at the end of the session; this file is the running record.)

## Verified so far
- Baseline: branch `episode-3/the-relay-keeper`, start `c88d7bf`, full suite 41/41 before any change.
- Hero walking into the NPC footprint: measured at four start rows; passes after a 0.2-0.5 s hesitation (eases around, no dead stop). No code change.
- `tools/finalize_native_matte.py` now refuses figures with under 24 px margin (matches the G2 gate), tests added; commit `1c772ae`.
- `tests/test_zone_integrity.gd` (236 checks): Episode 3 zone ids, positions, exits, spawn points, reachability both ways, no soft-lock before the tower. No defects found.
- Combat: PULSE and RIFT pressed out of reach no longer spend energy or start a cooldown (basic attack and HEAVY unchanged); `tests/test_combat_whiff.gd` (7 checks). Existing combat tests pass (phase1 34, repairs 13, finisher banner 5, boss transform 27, live combat manual + auto).
- `tests/test_battle_fuzz.gd` (24 checks): standalone and boss-mode battles, 4 seeds each, random input and hitches up to 0.4 s: no invariant violation.
- "Web QA" export preset now excludes `assets/approved_anime/*` (reference/review images no script loads): pck 58.6 MB -> 39.1 MB (-33%). The QA build runs boot, Missions and the start of Episodes 1, 2 and 3 with no console error and no failed request (`tools/qa/console_audit.cjs`). Boot time on loopback with software GL showed no clear difference (2.6-2.9 s new vs 2.6-3.9 s old, noise), so the gain is download size. The production "Web" and "Android" presets are NOT changed; applying the same exclude to them needs your approval.
- Puzzle screen: `set_anchors_preset` plus an explicit size on a full-rect node logged "non-equal opposite anchors" warnings (21 in the suite); now `set_anchors_and_offsets_preset` like every other full-screen layer. Layout unchanged; relay m3/m4/m5, puzzle logic, layout overflow and QA-gate tests pass and the warnings are gone. Commit `Puzzle screen: ...`.
- Virtual stick: 12% dead zone with a smooth ramp (full travel still 1.0 at 60 px), so a resting thumb no longer creeps the hero (touch drift on Android). `tests/test_joystick.gd` (11 checks). Touch-using suites (adventure 31, episode3 67, explore motion 20, Ep1 completion 22) pass.
- Sound boot: footstep variants and ambience loops were synthesised in `Sound._ready` (about 300 ms natively, more in the browser, before the first frame). They are now built one per frame after boot, with an on-demand fallback and `prepare_all()`; `Sound._ready` measures 7.7 ms (was about 330 ms). `tests/test_sound_boot.gd` (8 checks); three older tests call `prepare_all()` first.

## Final verification (build of commit d19e3f3; later commits are docs and .uid files only)
- Full suite (`tools/run_tests.sh`): discovered 46, ran 46, failing 0.
- Production "Web" export: pck has no packed QA hook; `tools/test_release_gate.py` passes. Production and Android presets unchanged.
- Browser (Chromium, software GL, real input): Episode 1 on the production export, keyboard 1280x720: 12/12 (927 s; the run was much slower than the earlier 372 s run on this loaded container, all checks still passed [cause not isolated]); Episode 3 on the QA export, touch 844x390: 20/20 (959 s) and keyboard 667x375: 20/20 (534 s); console audit of boot, Missions and the start of Episodes 1, 2 and 3: no console error, no failed request.
- QA zip: `soul-ascension-qa-d19e3f3-overnight2.zip` (38 MB; pck byte-identical to the tested export), delivered as a chat attachment, not published anywhere.
## Not done / remaining
- No real-device (Chromebook GPU, Android) frame-pacing or touch measurement exists: F3 numbers from the owner are still needed.
- Episode 2 has no browser playthrough on this code (headless `test_episode2` 38 checks pass).
- Echo's foot skating and Echo V2 native art are art-blocked (owner decisions: scar, beads, art source, front-margin).
- Production/Android presets still pack the unreferenced `assets/approved_anime/*` images (about 19.5 MB); excluding them there needs approval.
- Parallax/particle/lighting polish was not attempted (no verifiable objective defect found, and approved art must not change).
