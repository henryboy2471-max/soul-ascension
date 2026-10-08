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
