# Episode 3 "The Relay Keeper" — Implementation notes (M1)

Story source: `STORY_PLAN.md` (official, unchanged). Branch `episode-3/the-relay-keeper`. Not merged to `main`, not deployed.

## Architecture
- Reuses the config-driven `Explore` side-view strip. `ZoneDefs` defines 7 strips for the 5 areas (the tower has 3 floors); `RelayEpisode` swaps strips under a fade and saves progress per step in `mission_progress["1-3"]` (Episode 1–2 save keys are untouched).
- `RelayArt` draws placeholder per-zone art (no new character/environment art batches; gated on owner-approved visual direction).
- `Explore` gained `extra_npcs`, `companion` (follows Echo), `no_default_npc`, `no_walkers`.
- Locks: `shortcut` (alleys <-> station, opened by the alley lever) and `tower` (workshop -> tower; **opens in M2** via the investigation).
- Mission `1-3` data exists but is `playable:false`; the dev-only `settings.dev_unlock` flag lets QA start it.

## Assumptions / placeholders
7 strips for 5 areas; reward numbers on mission 1-3 are placeholders; NPCs (Teo, Anselm, Pip, Warden) are not yet placed with final art; interaction text is placeholder (`Episode3Data.INSPECT`).

## Gaps and risks
- Tower floors are not reachable in-game until M2 (lock); covered by the headless reachability test only.
- Browser frame times (SwiftShader) are not representative of devices; no Android device testing (SDK/devices unavailable).
- Character concept sheets (Teo, Anselm, Pip, Warden) not produced; owner approval is needed before final art.

## Milestone plan
M2 Investigation (clues, Teo reveal setup, opens tower lock) · M3 Puzzles (signal frequency, power routing, memory reconstruction) · M4 Cinematics + Relay Warden · M5 Polish/testing. Optional quests (Pip's trail, hidden registry entries, sealed chamber fragment) are placed across M2–M4.

## M1 test results (actually run)
- Headless: `test_relay_m1` 19/19, `test_phase1` 34/34, `test_repairs` 13/13, `test_adventure` 30/30, `test_episode2` 38/38, `test_live_combat` PASS (manual + auto replay).
- Browser (Chromium/SwiftShader, web export of this branch): 844x390 touch 12/12, 667x375 touch 12/12, console clean. 1280x720 keyboard: 11 steps passed; its last two checks expected the tower door to open (a wrong expectation — it is sealed by design in M1), so they are recorded as failed and were superseded by the corrected "sealed" check in the touch runs. The keyboard run was not re-run with the corrected check.
- Screenshots: `shots/`.

---
# M2 — Investigation (implemented on this branch; awaiting owner approval before M3)

Branch `episode-3/the-relay-keeper`, merged with `dev/ep1-gameplay-polish` first (Episode 1 completion flow, test runner, pedestrian/banner fixes); one conflict in `explore.gd` resolved by keeping both sides (Episode 3 companion/extra NPCs + whole-pixel placement). Not merged to `main`, not deployed. Mission 1-3 is still `playable:false` (dev-only `settings.dev_unlock` starts it).

## What was built
- **Dialogue** for every interaction (witnesses ×3 with conflicting versions, three transmissions, vendor, notice, hidden journal, terminal, Anselm, records, hidden registry, archive door, Pip, three faded marks, lever, Teo, decoder, evidence board, relay map). **All wording is a Claude draft derived from `STORY_PLAN.md` and needs owner review** (`scripts/story/episode3_data.gd`). Invented small specifics to flag: Pip's brother is named Lio; Anselm's terminal login "DRAY, A."; the hidden ledger "CANDIDATES / PRE-AWAKENING".
- **Clue + gating rules** as pure functions: `Episode3Data.respond(id, clues)` and `next_step(clues)`. Order matters only where the story needs it: terminal log → Anselm admits → records → hidden panel; Teo's permission + all three transmissions → decoder; decoder + records + Teo → evidence board → **opens the tower**. Out-of-order attempts give feedback and a nudge, never a dead end.
- **Quest tracking**: the HUD objective is derived from saved clues (so it cannot disagree with the save): transmissions 0/3 counter (waypoint to the nearest unscanned), terminal, Anselm, records, Teo, decoder, board, tower. The waypoint follows open exits between zones (`ZoneDefs.route_x`). No separate quest-log screen yet.
- **Optional content**: Pip's trail (three marks + return), hidden registry panel (appears after the records), hidden journal. None blocks the main path (tested: the main path alone opens the tower).
- **Codex**: seven Episode 3 entries (hidden until Episode 2 is cleared; three are secrets). With more than 12 entries the Codex now pages (6 per page, NEXT PAGE); 12 or fewer keep the old single-page layout.
- Per-step saving under `mission_progress["1-3"].clues`; resume restores clues, objective and hidden spots. Episode 1–2 progress untouched.

## Tests actually run
- `tests/test_relay_m2.gd`: 40 checks (data completeness, gating, 60 random orders always reach the theory / no dead ends, objective order, routing, the real `RelayEpisode` flow with objectives/counter/waypoints, hidden spot, Codex, tower lock, optional quest, resume, Episode 1–2 untouched).
- `tests/test_relay_m1.gd` 19/19 (unchanged), `tests/test_layout_overflow.gd` extended (Codex pages, every Episode 3 line in the real dialogue box).
- Real-window playthrough `tests/playtest_relay_window.gd` (Godot window under Xvfb, injected key events, software GL): market → station → alleys → workshop → tower floor 1, at **1280×720, 844×390 and 667×375**, 0 failures each (`relay_report_*.txt`, screenshots in `shots/m2/`). The playthrough found the Codex overflow, fixed by paging.
- Full runner `tools/run_tests.sh`: 27 discovered / 27 run / 0 failing (27 Godot test files incl. relay M1/M2 + 4 Python self-tests), after two fixes the first full run exposed: (1) the Codex listed unreleased Episode 3 entries as UNDISCOVERED once Episode 2 was cleared (`test_episode4`); now entries of a not-yet-playable episode show only once found. (2) The missions screen labelled the unreleased Episode 3 "UP NEXT" instead of "PLANNED" (`test_episode_defs`; this had been failing since M1, whose test list did not include it); not-yet-playable missions now stay PLANNED.
- The 1280×720 window playthrough was re-run on the final code: 0 failures (the 844×390 and 667×375 runs were made before those two UI fixes, which do not touch the exploration flow).

## Not done / gaps
- Third optional quest (**sealed relay chamber fragment**) belongs in the tower: M3/M4.
- Puzzles (signal, power routing, memory reconstruction), the archive door, resonators, the Relay Warden and the cinematics (Teo's reveal, Anselm exposing Echo's entry, Warden recognition, First Echo recording) are M3–M4. The scraped registry line and Teo's "not here, in the Central Relay" are set-ups only.
- No separate quest-log screen; no portraits for Teo/Anselm/Pip (no approved art: dialogue shows name plates only); placeholder procedural art.
- Touch controls were not exercised in the window runs (keyboard path); no browser (web export) or Android run for this milestone; software-GL only.
- Existing Episode 1–2 Codex entries (up to 5 lines) overlap the next row in the old single-page layout; untouched here (visible only with 7–12 entries).
