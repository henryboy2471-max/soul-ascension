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
