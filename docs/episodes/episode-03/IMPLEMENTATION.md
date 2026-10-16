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
- Puzzles (signal, power routing, memory reconstruction) and the resonators were delivered in M3; the Relay Warden and the cinematics (Teo's reveal, Anselm exposing Echo's entry, Warden recognition, First Echo recording) are M4. The archive door and relay map: see "Scope reconciliation" below. The scraped registry line and Teo's "not here, in the Central Relay" are set-ups only.
- No separate quest-log screen; no portraits for Teo/Anselm/Pip (no approved art: dialogue shows name plates only); placeholder procedural art.
- Touch controls were not exercised in the window runs (keyboard path); no browser (web export) or Android run for this milestone; software-GL only.
- Existing Episode 1–2 Codex entries (up to 5 lines) overlap the next row in the old single-page layout; untouched here (visible only with 7–12 entries).

---
# M3 — Puzzles (implemented; awaiting owner approval before M4)

Branch `episode-3/the-relay-keeper`. Not merged to `main`, not deployed; mission 1-3 is still `playable:false`.

## What was built (STORY_PLAN §7, "three different designs")
One puzzle per tower floor, at the resonator that M1 placed there. Rules are pure (`scripts/puzzle/puzzle_logic.gd`), the overlay is `scripts/puzzle/puzzle_screen.gd`, and the episode wiring is in `relay_episode.gd` (`run_puzzle`, `puzzle_done`).
1. **Signal Frequency** (floor 1): three rounds, one per transmission the player scanned (the lullaby, the bulletin, the long tone). Tune FREQUENCY (waves) and HEIGHT (amplitude) until the live wave overlays the recorded one, then LOCK. Feedback is proximity only (OFF / CLOSE / VERY CLOSE / LOCKED).
2. **Power Routing** (floor 2): a 6×4 conduit board. Turn tiles to carry current from the source to the relay lamp; two tiles are burnt out; most tiles are decoys. Powered tiles glow, and the header counts how far the current reaches.
3. **Memory Reconstruction** (floor 3): the evidence the player already found (registry line, deleted index, the long tone, the crash bulletin) becomes four fragment cards; place them oldest to newest using the "when" in each. A fragment only appears if its clue was found. CHECK says only whether the order is right (the "N OF 4 IN PLACE" count was removed after owner review; see "Revisions after owner review").
- **Hints (optional, tiered, never the answer)**: H or the HINT button. Signal: a description of the pattern, then a direction (too high / too low). Power: a general rule, then the first wrong tile on the intended path is marked. Memory: "look for the words that say WHEN", then which fragment is oldest. Mira introduces each puzzle but never solves it.
- **Controls**: keyboard (arrows/WASD, Enter/Space/E, H, C, Esc), mouse and touch (every control is a large button; the power board takes taps/clicks). All three are tested.
- **Persistence**: every move is saved (`mission_progress["1-3"].puzzles`); leaving with Esc/BACK and returning resumes the same board, tuning, placement and hint count. A solved resonator stays solved and does not reopen.
- **Progression**: solving the signal resonator opens the floor-1 stairs; the power resonator opens the floor-2 stairs and wakes a hidden **sealed chamber** (the plan's third optional quest: a recording-crystal fragment, Codex entry "A Sealed Fragment"); the memory resonator makes the **archive gate** stir (clue `archive_examined`). The objective HUD walks signal → power → memory → archive. New clue ids: `puzzle_signal`, `puzzle_power`, `puzzle_memory`, `first_memory_fragment`, `archive_examined`, `seen_resonator_N`.
- Not changed: Episode 1–2 progress, combat, rewards, mission playability.

## Tests actually run
- `tests/test_puzzle_logic.gd` 24/24: all three puzzles are solvable (power: a DFS over tile orientations proves a connecting rotation exists; signal: stepping one notch at a time reaches every target; memory: exactly one of the 24 orders is correct), start unsolved, clamp, feedback and hints never state the answer.
- `tests/test_relay_m3.gd` 36/36: the real `RelayEpisode` + `PuzzleScreen` driven by key events, mouse clicks and button callbacks: floor locks, intros, hints, leave and return, solving each puzzle, the sealed chamber, the archive gate, objectives, resume.
- `tests/test_layout_overflow.gd` extended (23/23): the three puzzle screens and every new dialogue line fit at 1280×720 logic size. `test_relay_m1/m2` were updated for the new tower rules (stairs lock until a floor's puzzle is solved; objectives continue past the tower).
- Real-window playthrough `tests/playtest_relay_puzzles.gd` (Godot window under Xvfb, injected key events, software GL): resume at the tower with the M2 evidence, solve all three puzzles by keyboard (including a hint, Esc and return), climb the unlocked stairs, take the sealed fragment, examine the archive. Results per size in the final report and `relay_puzzles_*.txt`.
- Full runner `tools/run_tests.sh`: see `suite_m3.txt`.
- The playthrough's first screenshots found two real layout defects, both fixed: the memory cards stretched into one bar (text now lives on wrapped labels inside fixed-size buttons), and the power board overlapped its status line (board and cell size reduced).

## Not done / gaps
- **M4**: the Relay Warden encounter (telegraphed attacks plus mechanisms, a checkpoint), Teo's reveal, Anselm exposing Echo's registry entry, the Warden recognition scene and the First Echo recording. The archive stirring is only the set-up.
- Gameplay-feel of the puzzles (difficulty, pacing, hint thresholds) is untested with real players; the signal puzzle's targets and the memory puzzle's "when" wording are my draft and need owner review. The spatial puzzle for the station's archive door and the relay-map repair (plan areas B and D) are not implemented: see "Scope reconciliation" below for why and where they are recorded.
- Touch input was tested via mouse/button events and Godot's mouse emulation path, not on a real touch device; no web export or Android run for M3; software GL only.
- No sound for the puzzles; no new art (procedural drawing only).


---
# Scope reconciliation: archive-door spatial puzzle and relay-map repair (after M3, before M4)

Question: do these two belong to M3? Answer after re-reading `STORY_PLAN.md`: **no. The plan does not assign either to any milestone, and M3 as the plan defines it excludes both.** They are recorded as carried to M4 (proposed pairing below), pending Henry's confirmation. No code changed for this reconciliation; the M1/M2 story text was not touched.

## What the plan says (verbatim)
| Item | Plan text | Where |
|---|---|---|
| Archive-door spatial puzzle | "B. Meridian Transit Station: ... meet Anselm and investigate the Ascendant registry; **a spatial puzzle to reach sealed files**." | §4 area B (mission 3-2 "The Missing Register" says only: "question Anselm and locate hidden Ascendant records") |
| Relay-map repair | "D. Teo's Workshop: central evidence board and signal-decoding equipment; assemble discovered clues into a coherent theory; **restore a broken relay map; reveal the connection between the seven arrays**." and mission 3-4 "The Keeper's Secret: meet Teo, **reconstruct the signal route, and decode the relay map**." | §4 area D, §5 |
| M3 definition | "M3 Puzzles: **signal, power-routing and memory-reconstruction mechanics**." | §12 |
| Puzzle designs | "Puzzles and investigation (**three different designs**): 1. Signal Frequency ... 2. Power Routing ... 3. Memory Reconstruction." | §7 |
| M2 definition | "M2 Investigation: NPC dialogue, quest tracking, discoverable clues, optional side quests, evidence gathering." | §12 |
| M4 definition | "M4 Cinematics and Boss: Warden encounter, archive reveal, character expressions, story scenes." (required cinematics §9: Teo revealing the memory network; Anselm exposing Echo's registry entry; Warden recognition; First Echo recording) | §9, §12 |

## Mapping (my reading; items marked [Inference] are not stated in the plan)
- **Neither is an M3 deliverable.** §12 names three mechanics for M3 and §7 caps puzzle designs at three; a "spatial puzzle" is not one of the three, and "restore a broken relay map" is described as area content, not as a mechanic. Building them in M3 would have meant adding a fourth design or duplicating an existing one without the plan asking for it.
- **Relay-map repair**: its stated payoff is "reveal the connection between the seven arrays", which is the substance of the required Teo cinematic (§9). [Inference] It belongs with that scene in **M4**, and should reuse the M3 power-routing/signal mechanics (the plan's "signal route") rather than add a new design. The M2 board already delivers "assemble discovered clues into a coherent theory"; the map spot currently only describes a chalk map with a torn corner and records the clue `map_seen`.
- **Archive-door spatial puzzle**: it guards "sealed files" in the station; the required cinematic that exposes Echo's registry entry (§9, Anselm) is the natural payoff. [Inference] It belongs with that scene in **M4**. M2 already set it up (the scraped registry line; the door's "resonance lock" line). Alternative: treat it as an optional extra in M5. Because the plan says "three different designs", a fourth mechanic needs Henry's decision.
- Not M5: M5 is "artwork integration, performance, saving, regression tests, browser playthroughs" (§12), not new puzzles.

## Current in-game state of the two spots (unchanged)
- `archive_door` (station): examine text only (a sealed door with a resonance lock; Mira: "We'll need the right pieces to open it. The old registry is a start."). No state.
- `relay_map` (workshop): examine text only; records clue `map_seen`. No state.

## Gate
M3 awaits owner approval of the puzzle targets and wording (`M3_REVIEW_DRAFTS.md`). **M4 is not started and stays gated for Henry's sign-off**; its exact scope is in `M4_SCOPE.md`.

---
# M4: Cinematics and Boss (implemented; awaiting owner approval before M5)

Branch `episode-3/the-relay-keeper`. Not merged to `main`, not deployed. Mission 1-3 is still `playable:false` (the dev-only `settings.dev_unlock` starts it). Signed off by Henry at the start of M4 (see `APPROVAL.md`); the six recommended decisions in `M4_SCOPE.md` section H were followed.

## What was built
- **Relay Warden encounter** (plan §8, mission 3-6), as a new Explore-style arena (decision 1; the battle scene and frozen combat are untouched). `WardenLogic` (pure rules) + `WardenArena` (live node: floor telegraphs, closing bar, resonance meter) inside a new chamber zone reached through the archive gate on floor 3. Echo restores three mechanisms in the order on a brass plaque (VALVE, BELL, SEAL; deliberately not left to right). A correct one interrupts the Warden (6 s stun); a wrong one shocks Echo (-1 of 5 resonance) and rouses it. Telegraphs are 1.7 s floor zones (slam, sweep, pillars). Running out of resonance returns to the last checkpoint (entrance, or beside the last restored mechanism) with progress kept; reloading mid-fight resumes there (decision 5). The Warden is restored, not destroyed.
- **The five required cinematics** (§9) plus the chamber's arrival scene: letterbox, slow push-in, flash and shake, name plates (decision 4: no new art), subtitles via the dialogue box, control returned afterwards: opening, Anselm's exposure, Teo's reveal, Warden recognition, First Echo recording.
- **The two carried-over puzzles** (decision 2): the sealed archive door (a 6x6 sliding-rail puzzle) and the relay map (the power-routing mechanic on a 7x5 board with seven lamps). The door opens after the records; its payoff is the exposure scene. The map opens after the evidence board; its payoff is Teo's reveal. Both save per move and resume.
- **Finale and completion** (§5 3-7, §11): the archive core plays the recording; the episode completes through the shared rewards screen (first clear paid once; replay pays the replay reward; mission progress, puzzles and checkpoints reset on completion so a replay starts fresh; completion, rewards and the Codex are kept); NEXT EPISODE shows the Episode 4 teaser; no Episode 4 content exists.
- **Finale payoffs from the investigation** (§6): up to five extra lines in the recording scene, one per investigated payoff (all three witnesses, the journal, the hidden registry, the sealed fragment, Pip's quest).
- **Quest line** now: transmissions → terminal → Anselm → records → sealed door → Teo → decoder → board → relay map → tower → three resonators → archive → Warden → recording. The archive gate also needs the map and the door.
- **Codex**: four new secret entries (Echo's Registry Entry, The Seven Arrays, The Relay Warden, The First Echo).
- Rewards unchanged at 180 XP / 340 gold (replay 80 / 150) and now explicitly **PROVISIONAL** (flagged in `mission_defs.gd` and the review document) until you confirm them.

## Defects found and fixed during M4
1. `next_step` indexed past the mechanism list in the moment between the third mechanism and the recognition scene (caught by the flow test).
2. A cinematic left its slow push-in tween running after the scene (the view stayed zoomed): the tween is now killed; regression test.
3. `Explore.set_cinematic(false)` re-showed the deliberately hidden prompt-text label, so each cinematic left a doubled prompt under the pill (shared Explore code; Episode 2's single cinematic never exposed it): fixed; regression test.
4. The arena drew the outdoor skyline (no palette for the zone): it now has an interior palette.
5. The Warden drifted onto Echo: it now keeps 340 px away; regression test.
6. The old M1/M2/M3 tests encoded the pre-M4 shape (7 strips, no door/map steps, the opening not holding the episode busy): updated, not loosened.

## Tests actually run
- **Full runner `tools/run_tests.sh`: 31 Godot test files discovered, 31 run, 0 failing, plus the Python self-tests** (`suite_m4.txt`).
- **Real-window playthrough `tests/playtest_relay_finale.gd` at 1280x720, 844x390 and 667x375: 0 failures at each** (410 s, 406 s, 406 s; `relay_finale_*.txt`, screenshots in `shots/m4/`). It plays with injected key events from the station through the sealed door, the walk to Teo, the relay map, the tower climb, the archive gate, the Warden fight (a wrong mechanism first, then VALVE, BELL, SEAL, dodging telegraphs the way a player would), the recognition scene, the recording, the rewards screen, NEXT EPISODE and the teaser. The segment before the station (M2 evidence and the three resonators) is seeded into the save; those are covered by the M2/M3 playthroughs.
- New: `test_warden_logic` (17), `test_relay_m4` (40), extended `test_puzzle_logic` (38), `test_layout_overflow` (27), and the real-window `playtest_relay_finale.gd`.
- Warden fairness is proven by exhaustive check: for every Warden position, player position and pattern, the player can leave the zone within the telegraph (worst case 161 px of walking against a 331 px reach under a 0.4 s reaction and 85% speed model). The bot in the playthrough walks out of telegraphs from the same state the game exposes.
- Puzzle solvability: the relay map's stored solution lights all seven lamps and starts mostly wrong; the rail puzzle's shortest solution is 11 moves and every position reachable by sliding can still be solved (checked over the first 150 positions).

## Not done / gaps (honest list)
- **One unexplained engine abort.** One full-length 1280x720 playthrough (before the fixes above) aborted with an engine segfault (signal 11) right after the Warden was restored; the same run repeated cleanly, and I could not reproduce it in 8 runs of the finale tail and 6 runs of the arena segment (all under the same renderer). The backtrace had no symbols. It may have been a one-off in the software renderer or a real use-after-free in the cinematic/arena teardown; I do not know. If a later run crashes again it needs a debug build.
- **Art and audio**: the Warden is the pedestrian rig scaled up and tinted (a placeholder; the plan says no generic placeholder in the final build); Teo, Anselm and the Warden have no portraits; the chamber is procedural art; no sound anywhere in M3/M4 content. All M5.
- Difficulty and pacing of the fight and the two new puzzles are untested with a person. Wording of every cinematic is my draft (`M4_REVIEW_DRAFTS.md`).
- No quest-log screen; hints for the fight itself are Mira's two lines and the plaque.
- Touch was exercised only through Godot's mouse emulation and the keyboard path in the window runs; no web export, Android or device run (M5, §12).
- Mission 1-3 stays unplayable; the home screen and mission card do not show it (M5 release decision).


---
# Revisions after owner review (between M4 and M5; nothing from M5 started)

Requested by Henry after M4; applied on `episode-3/the-relay-keeper`. Not merged, not deployed.
- **M3 revisions (owner-approved):** keep "tonight" on the long-tone card; the memory puzzle no longer reports how many cards are in place (wrong order now says `NOT YET  /  THE ORDER IS WRONG`); the sealed-chamber clue keeps only the voice counting seven. The lamp and "We kept it safe in the towers" are removed from the chamber, the finale payoff line and the Codex text.
- **M4 draft revisions:** the opening no longer asserts "the morning after" or "since sunrise" (final, owner-approved: "shortly after the Rain Array incident"; Mira's "the third time today" removed); the Warden and recording scenes keep the exact signature match and the Vaust hook but no longer state or imply that Echo is, or came from, the First Echo (the recording ends on Echo's question "Then who is the First Echo?").
- **Rewards** stay 180 XP / 340 gold and 80 / 150 and are flagged PROVISIONAL (`"provisional":true` in the mission data, a comment beside it, and a labelled table in `M4_REVIEW_DRAFTS.md`).
- Confirmed by Henry: Pip's "Lio's lamp glass" line stays as the M2-established keepsake, separate from the sealed-chamber clue (pinned by a test).
- Tests updated and extended: `test_puzzle_logic`, `test_relay_m3`, `playtest_relay_puzzles` (feedback text); `test_relay_m4` gained data checks that pin each wording change (no lamp / no "kept it safe" in the chamber, finale payoff and Codex; "tonight" kept; no time-of-day in the opening; the exact match, the Vaust hook and the open question kept; nothing says Echo is the First Echo; rewards unchanged and provisional).


---
# M5: Polish and testing (started after the owner's M4 sign-off; in progress)

Owner sign-off (recorded in `APPROVAL.md`): M4 approved with two opening edits (applied: "shortly after the Rain Array incident"; "the third time today" removed). Lio's lamp glass stays. Rewards 180 XP / 340 gold and 80 / 150 are approved **only as provisional values for M5 economy testing**. Limits: mission 1-3 stays unplayable until the M5 release review; no merge to `main`; no deploy; no new character art before Henry approves samples.

## Done so far
- **Release gate pinned** (`tests/test_relay_m5.gd`): with Episodes 1-2 cleared, 1-3 is unlocked but not playable, is not the home mission, shows `PLANNED`, and `start_episode("1-3")` opens nothing and writes no progress. [Inference] The only way in is the hidden `settings.dev_unlock` save flag (QA); it should be removed or gated out of release builds at the release review.
- **Bug found and fixed:** `Profile.mission_progress` raised a script error when a save's entry for a mission (or the whole `mission_progress`) was not a dictionary. It is shared by every mission, so the fix is there: a damaged or hand-edited entry now reads as "no progress". Seven damaged-save shapes for 1-3 (unknown zone, wrong types, the arena with no clues, bogus clue ids, ...) now each resume into a valid zone.
- **Performance probe** (`tests/probe_relay_perf.gd`), software GL under xvfb at 1280x720, all eight zones: median 28-33 ms/frame, p95 34-41 ms, 99-162 draw calls (market highest). [Unverified for devices] Software rendering says nothing about phone GPUs; zones are uniform, none stands out.

## Not done / blocked
- **Web export and browser playthrough**: no Godot export templates are installed in this container (`export_templates` is empty), so a web build cannot be produced or played here. No browser or device claim is made.
- **Artwork integration**: the Warden is still the scaled, tinted pedestrian rig; Teo, Anselm and the Warden have no portraits. Fixing that needs new character art, which is blocked until Henry approves samples. No audio exists for the M3/M4 content.
