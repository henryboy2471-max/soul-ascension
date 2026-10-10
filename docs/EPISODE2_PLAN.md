# Episode 2 design plan (proposal, not yet approved)

Episode 1 is locked at `80f54c3` on `main`. This branch (`episode-2/under-the-violet-rain`) holds Episode 2 work only. Nothing below is implemented yet.

## 1. Title
**UNDER THE VIOLET RAIN** (already teased by the Episode 1 ending card and listed as mission `1-2` in `MissionData`).

## 2. Premise
The breach did not close cleanly. By dawn a violet rain is falling over Neon District, and each drop carries a trace of the Echo "second signal". Awakened civilians sheltering in the Lantern Circuit's hidden depot start sleepwalking toward the sky while their Soul Realm fears leak into the street. Mira needs the Hero, because Echo is the only resonance that listens without being consumed, to find what is tuning the rain before it peaks.

## 3. Location
The **Lantern Quarter**, a terraced lower district of Neon District: wet terraces, hanging lanterns, a drained tram depot ("Depot 4") used as the Lantern Circuit shelter, and a rooftop Meridian relay (the "Rain Array").

## 4. Mission objective (not "defeat enemies")
**Calm the rain:** sync three lantern resonators to shelter the sleepers, then reach and silence the Rain Array. Combat only appears as the obstacle at the very end.

## 5. NPCs
- **Mira Vey** (existing sprite and portrait): guide and conscience; stays at the depot, guides by radio.
- **Pell** (new, dialogue only): Lantern Circuit medic heard over the radio; no new character art needed (radio/lantern portrait).
- **The sleepers** (ambient): existing pedestrian rigs standing still in the depot.
- **The Hollow Cantor** (new, boss): see section 8.

## 6. Exploration sequence
1. Title card and opening dialogue (rain over the quarter, Mira's call).
2. Depot 4: talk to Mira, see the sleepers; Codex "VIOLET RAIN".
3. Terrace investigation: three lantern posts (hold-to-sync, any order) each play a memory fragment from a sleeper; objective shows a 0/3 counter; Codex "THE SLEEPERS".
4. Optional lore spot (like the mural): a Meridian maintenance notice about "Rain Array 7".
5. Roof access unlocks at 3/3: the Rain Array console (hold to sync) opens a breach.

## 7. Soul Realm sequence
**The Sleepers' Stair:** the Soul Realm arena with a violet-rain layer and lantern motes. Before the fight, three whispers (one per resonator memory) play over the realm, tying the fragments together. Entering costs 6 energy as in Episode 1.

## 8. Enemy and boss concept
- Wave 1: a **Resonance Shade** (existing sprite), faster than Episode 1's.
- Boss: **The Hollow Cantor**, the echo of the Meridian technician who tuned the array and is now trapped singing in it. Bell-toll attacks use a larger telegraph. At 50% health the existing Phase 2 system triggers as **"THE CHORUS RISES"**: the rain intensifies, telegraphs speed up, and Mira's lantern lights once to heal the Hero (a support event).
- Art: the Cantor needs a new sprite sheet from the owner. Until one exists, the plan is to reuse the Shade sprite at boss scale with a rain-white tint and code-drawn bell and rain VFX through the existing `frames.tres` hook (`assets/enemies/...`). No new art will be generated without approval.

## 9. Ending cliffhanger
The rain stops and the sleepers wake. Every Meridian screen in the quarter lights up with **Director Vaust** announcing a 48-hour "Resonance Amnesty": all Ascendants must register or be suppressed. The Hero's name is already on the list. Next Episode card: **EPISODE 3 / THE RELAY KEEPER** (the next title already in `MissionData`).

Rewards (proposal): first clear 150 XP and 300 gold, replay 65 XP and 120 gold, Codex entries Violet Rain, The Sleepers, Rain Array, Hollow Cantor.

## 10. Reused versus new
**Reused unchanged:** Hero and Mira sprites and portraits, Shade sprite, `DialogueBox`, `TitleCard`, `Episode`/`Explore` flow (prompts, hold-to-channel, waypoint, dialogue lift, toast), battle HUD, controls and mobile joystick, Phase 2 transformation, Codex and toast, save format (`completed` and `codex` lists just gain ids; no schema change), rewards screen, `MissionData`, sprite pipeline, and the test and QA tooling (adventure-style flow test, wording audit, UI layout tests, `capture_ui.gd`, browser RC scripts).

**Genuinely new (limitations found in the Episode 1 code):**
1. A data-driven episode definition. Episode 1's spots, steps, objectives, battle waves and ending are hard-coded in `EpisodeData`, `Episode`, `Explore` and `Battle.wave_defs`.
2. Run and reward generalization: `Profile.begin_run` accepts only `"1-1"` and `finish_run` hard-codes the rewards; the result screen and mission card text are Episode 1 strings.
3. A counter-style objective (0/3) and order-free investigation spots.
4. Lantern Quarter world art plus a rain layer, and a rain variant of the Soul Realm arena.
5. Per-foe battle options: telegraph radius (currently fixed at 100) and a mid-fight support event.
6. Optional new art (Cantor sheet), pending owner approval.
7. Episode 2 flow test, wording-audit and RC pass.

## Proposed milestones (each needs approval before the next)
- M1: make Episode 1 data-driven with every existing test unchanged and green.
- M2: Episode 2 exploration, dialogue, investigation, Codex.
- M3: Soul Realm, battle, boss and support event.
- M4: ending, rewards, teaser, Episode 2 release-candidate pass.

## Open questions for the owner
- Is the Vaust "Resonance Amnesty" cliffhanger acceptable canon?
- Will you supply a Hollow Cantor sprite sheet, or approve the interim reuse of the Shade sprite?
- Are the reward numbers acceptable, and should Episode 2 unlock only after Episode 1 is cleared (my recommendation)?

## M1 status (data extraction, done on this branch)
`scripts/missions/mission_defs.gd` (`MissionDefs`) now holds mission data; Episode 1 behaviour is pinned by `tests/golden/episode1_trace.json`, recorded from the locked commit `80f54c3` with `tests/support/episode1_trace.gd` and checked by `tests/test_episode_defs.gd`. Mission 1-2 exists as data (unlock requires 1-1, rewards 150/300 first and 65/120 replay, Codex ids), still `playable: false` with no scenes.

## M2-M4 status (Episode 2 complete on this branch)
- **M2** exploration (Lantern Quarter, three resonators, roof gate, Rain Array), saved per step in `mission_progress["1-2"]`.
- **M3** breach confirmation (6 energy only on entry, `combat_run` saved so a reload never charges twice), Soul Realm rain arena, Resonance Shade (mission-data pacing), Hollow Cantor (interim Shade art, `assets/enemies/hollow_cantor/frames.tres` hook), Phase 2 "THE CHORUS RISES", Mira's one-shot lantern support (`Battle.run_support`).
- **M4** ending: Cantor defeat -> `Profile.mark_battle_won` (combat_run cleared, `battle_won` saved) -> `LanternEpisode.run_ending` (calm Soul Realm scene with Mira's lantern signal, then the Lantern Quarter aftermath: rain thinned, resonators steady, breach folding shut, Meridian screens lit by Director Vaust's "Resonance Amnesty" broadcast) -> `Profile.finish_run` pays the normal 150 XP / 300 gold (replay 65 / 120) and records story flags -> rewards screen -> NEXT EPISODE teaser (EPISODE 3 / THE RELAY KEEPER, "SIX ARRAYS REMAIN") -> home.
- **Persistence rules:** mission 1-2 is completed only when the ending finishes. A reload during the ending resumes it (`Profile.begin_ending`, no energy, no fight); `finish_run` consumes `battle_won` and sets flags `cantor_defeated`, `ending_seen`, `arrays_remaining=6`, `amnesty_declared`, so rewards and story state cannot be paid twice. A completed Episode 2 reopens at the breach as a replay.
- **Tests:** `tests/test_episode2.gd`, `test_episode3.gd`, `test_episode4.gd` (ending, rewards, reload, replay), `test_layout_overflow.gd` (canvas overflow audit of the Episode 2 flow); screenshots via `tests/capture_episode3.gd` / `capture_episode4.gd`.
- **Limitations:** the Hollow Cantor still borrows the Shade sprite; the replay plays the full ending again; Mira appears in the calm Soul Realm as a tinted projection of her approved sprite (no new art).

## Hollow Cantor dedicated art (branch `art/hollow-cantor`)
`assets/enemies/hollow_cantor/frames.tres` (Phase 1) and `.../phase2/frames.tres` (Phase 2, same character intensified) replace the temporary Shade reuse. Both are generated by `tools/gen_hollow_cantor.py` (original procedural art, no external service): idle 8, walk 6, attack1 8, hurt 2, defeat 8. Canvases carry transparent safety padding (>= 31 px top, >= 37 px sides, hem >= 7 px above the bottom row); `frames_height` / `phase2.height` in `MissionDefs` (213.46 = 185 x 292/260) keep the figure at its intended in-game size. The tinted Shade stays as the fallback if `frames.tres` is missing. Regenerate: `python3 tools/gen_hollow_cantor.py`, then `godot --headless --editor --import --quit` and `tools/build_spriteframes.gd` for both directories. Checked by `tests/test_cantor_sprites.gd`.

### Hollow Cantor art v2 (branch `art/hollow-cantor-v2`)
Same character, same animation set and timing; rendered at 1.5x resolution with ink outlines, cel shading, rim light, fabric grain, brocade, silver trim and gems, a cape for mass, volumetric rays and bloom. Phase 2 adds a double bell halo, energy wings, shockwave rings, a blazing eye and many more orbiting bells. `frames_height` / `phase2.height` are now 213.46 (= 185 x 300/260) because the top padding grew to 40 units. Fighter: the code-drawn halo is drawn only for the interim Shade sprite (the dedicated art has its own), and the Phase 2 charge-up/burst gained converging motes and a pillar of light. Comparisons: `docs/art/hollow_cantor_v2/`.

## Status update (after the Cantor art passes)
The "Hollow Cantor borrows the Shade sprite" limitation above is obsolete: the Cantor now has its own approved v2.1 sprite sets (Phase 1 and Phase 2, 64 frames, `assets/enemies/hollow_cantor`, VRAM-compressed; v2 kept at `assets/enemies/hollow_cantor_v2`), with the Shade fallback kept for a missing resource. See `docs/ART_V2_1.md` and `docs/WEB_TEXTURE_COMPARISON.md`. Mira in the calm Soul Realm remains a tinted projection of her approved sprite.
