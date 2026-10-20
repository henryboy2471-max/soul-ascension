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
