# Episode 3 preparation - "The Relay Keeper" (NOT authorized for implementation; planning only)

No Episode 3 code, data, art or tests have been written. This document is the technical plan, reuse map, asset list and checklist so implementation can start the moment you approve it. Story context: `docs/SEASON1_PLAN.md` (Episode 3 = mission `1-3` in the design doc table).

## 1. Outline under review (from the design doc and the Episode 2 teaser: "THE RELAY KEEPER / SIX ARRAYS REMAIN")
Restore the tram network (design doc: objective "Restore the tram network", mini-boss "Relay Warden"). Proposed shape: find the missing relay keeper -> restore three track junctions -> silence Array 6 in the relay core -> breach -> Relay Warden -> aftermath with a sealed cargo labeled ECHO.

## 2. Technical plan (follows the Episode 2 milestone pattern: M1 data, M2 exploration, M3 battle, M4 ending)
- **M1 - Data first.** Add mission `1-3` to `scripts/missions/mission_defs.gd` (unlock requires `1-2`; flow `relay`; objectives, rewards, codex ids, story flags `relay_restored`, `arrays_remaining=5`). Extend `tests/test_episode_defs.gd` pins; Episode 1/2 golden traces must stay byte-identical.
- **M2 - Exploration.** New `scripts/story/relay_episode.gd` that follows `lantern_episode.gd`. Prefer extracting the shared parts (progress save, fade, step machine, objective HUD, hold-to-sync) into a small base class FIRST, with the Episode 2 tests as the safety net, rather than copy-pasting 295 lines. Zone art: new `RelayArt` (like `lantern_art.gd`), procedural placeholder first, final art only after the visual direction is approved.
- **M3 - Battle.** Wave 1: Resonance Shade variant or a new light enemy; boss: Relay Warden via `MissionDefs` wave data (`pace`, `phase2`, `frames` hook) exactly as the Cantor does. Placeholder art uses the existing interim-art fallback (Shade tinted) until approved art exists; Phase 2 "FULL SERVICE" through `phase2_def`. A mid-fight support hook can reuse `battle_support.gd`.
- **M4 - Ending.** Aftermath scene, rewards via `Profile.finish_run`, flags, NEXT EPISODE card (Episode 4).
- **Cross-cutting.** Save format: add `mission_progress["1-3"]`; keep `completed`/`codex` shapes; add a save-version field in the roadmap's slice D rather than here. All new strings go through data files; run `tests/test_layout_overflow.gd` patterns on the new flow.

## 3. Reusable systems (verified in the repo)
| System | Where | Reuse |
|---|---|---|
| Mission data and unlock/rewards | `scripts/missions/mission_defs.gd` | add `1-3`; no code change |
| Explore (walk, spots, hold-to-channel, gate, objective HUD, counter objective, toast) | `scripts/world/explore.gd` | as is (now with eased movement) |
| Lantern-style step/progress controller | `scripts/story/lantern_episode.gd` | extract a shared base, then subclass |
| Dialogue UI, title card, codex/toast | `dialogue_box.gd`, `title_card.gd`, `episode.gd` | unchanged |
| Battle, boss intro, Phase 2, Mira support, whispers | `scripts/combat/*` | data-driven via wave defs |
| Sprite pipeline (generator, manifest, `frames.tres`, margin test) | `tools/gen_hollow_cantor.py`, `tools/build_spriteframes.gd`, `tests/test_cantor_sprites.gd` | template for the Relay Warden if the procedural route is approved |
| Browser QA harness | `tools/qa/` | extend for Episode 3 |

## 4. New for Episode 3 (the real work)
- A track-junction routing puzzle (objective type beyond hold-to-sync): new interactable type with a small rule set (junction states, win condition) and its test.
- Relay Warden boss behavior profile (track-sweep telegraphs): new `pace`/telegraph style values; any new attack shape needs a `Telegraph` style.
- Stalled-tram passengers: ambient NPCs with a branching reply (needs dialogue v2 from roadmap slice B, or a simple two-option prompt).
- Echo Dash (movement ability) is proposed as the unlock; it belongs to roadmap slice A/D and should not block the episode.

## 5. Assets and dependencies
- **Characters (need owner-approved art/direction first):** Relay Keeper (portrait + sprite), Relay Warden (boss sprites: idle/walk/attack/hurt/defeat for both phases, like the Cantor's 64 frames), 2-3 passenger sprites.
- **Environment:** tram relay hall, switchyard, stalled tram line (parallax layers + interactive prop states).
- **Audio:** none required; tram ambience is optional, any pack needs an approved licence.
- **Dependencies:** approval of this plan; approval of the visual direction proposal; Season 1 canon approval for new names/roles; the shared-base extraction (small refactor with tests) before M2.
- **No-art fallback:** procedural placeholders and tinted existing sprites keep the whole episode playable and testable before final art, as Episode 2 did with the Shade.

## 6. Development checklist
- [ ] Owner approves Episode 3 start, the plan, and new names/roles
- [ ] M1 mission data + pinned tests (Episode 1/2 goldens unchanged)
- [ ] Extract shared episode base from `lantern_episode.gd` (Episode 2 tests green)
- [ ] M2 zone, NPCs, junction puzzle, saves per step, resume tests
- [ ] M3 Shade variant + Relay Warden wave, Phase 2, pacing from data
- [ ] M4 ending, rewards once, Codex, teaser, replay behavior
- [ ] `test_episode_*` additions, layout overflow audit, browser matrix (1280x720, 844x390, 667x375) with the QA harness
- [ ] Full regression, web export check (lossless web build), device checklist (`docs/DEVICE_TEST_CHECKLIST.md`)
- [ ] Owner visual review before any merge

## 7. Estimate and risks
About 4 milestone-sized sessions (data, exploration, battle, ending) plus the base-class extraction ([Inference] from how long Episode 2's M1-M4 took). Risks: scope creep in the puzzle; boss art cost; touching shared code (mitigated by extracting behind the existing tests).
