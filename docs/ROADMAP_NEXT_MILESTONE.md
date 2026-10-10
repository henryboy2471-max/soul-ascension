# Next adventure milestone - development roadmap (APPROVED by the owner; priority order A -> E)

## Owner decisions on record
- Priority order: A movement/exploration/connected zones, B interactive environments + NPC conversations + puzzles + non-combat missions, C premium anime cinematics/dialogue/cutscenes, D character development/progression/abilities/upgrades, E consistent premium anime artwork + optimization + release readiness.
- Direction: SOUL ASCENSION is an anime ADVENTURE game, not primarily a fighting game: premium anime-illustration characters, detailed environments, responsive movement, interactive NPCs, exploration, mysteries, story missions, dramatic boss encounters, cinematic storytelling - "an anime series the player can explore and participate in".
- Season 1 contains exactly 10 episodes (1-1 ... 1-10 in `docs/STORY_AND_ROADMAP.md`); no expansion to 12+ without owner approval.
- Major new character/NPC/environment artwork is NOT generated or commissioned until the owner approves a visual direction proposal (`docs/VISUAL_DIRECTION_PROPOSAL.md`).
- Do not start Episode 3 until told. Web graphics: both Cantor texture variants stay available (see `docs/WEB_TEXTURE_COMPARISON.md`) until the owner decides.
- Platform claims: a device/browser test is reported as passed only if it actually ran.


Goal: finish a polished, playable anime adventure in the approved v2.1 style, not keep redesigning one boss. Combat stays as it is (frozen); this milestone is about everything around it. Episode 3 implementation does NOT start until this roadmap is approved.

## Where the code stands today (read from the repo)
- Exploration (`scripts/world/explore.gd`, ~420 lines): side-view walk along a 2500 px strip, one speed (300 px/s), a fixed ground line, hard-coded interaction "spots", hold-to-channel, objective HUD + waypoint, touch stick + action button. Worlds are procedural parallax art (`world_art.gd`, `lantern_art.gd`).
- Story (`scripts/story/*`): linear typewriter dialogue (`dialogue_box.gd`, portraits are procedural), scripted episode controllers (`episode.gd`, `lantern_episode.gd`), data in `episode_data.gd` / `episode2_data.gd`. No choices, no flags-driven branching, no cutscene runner (cinematics are hand-coded fades/letterbox).
- Missions are data (`mission_defs.gd`), saves are versioned-by-shape in `profile.gd`. Progression is thin (`progression.gd` is 13 lines): level/XP/gold, one hero (Echo). Design doc lists Mira/Oren/Sable kits, equipment and passives as backlog (`docs/STORY_AND_ROADMAP.md`).
- Art: Hero, Shade, Mira, Enforcer and Cantor v2.1 are approved sprite sets; world, NPC walkers and portraits are still procedural placeholders.

## Principles
1. Vertical slices, each playable end to end and tested in Chromium at 1280x720 / 844x390 / 667x375 before moving on.
2. Data-driven first: build the system once (zones, interactables, dialogue, objectives, cutscenes), then author content as data.
3. Each slice ends with an owner approval gate with screenshots/video-like captures, as we did for Episode 2.
4. No new paid services; any new art source needs your approval first.

## Proposed sequence (each slice = one approval gate; effort in work sessions comparable to one Episode 2 milestone, [Inference] estimates)
### Slice A - Movement and zones (~2 sessions)
- Movement feel: acceleration/deceleration, sprint/dash, short depth lane (move a little toward/away from camera), camera look-ahead and soft bounds, footstep/ambience hooks, input buffering, stick dead-zone/curve tuning on touch.
- Zone system: data-defined zones (width, layers, spawn points, exits), doorway/fade transitions between zones, per-zone ambience, remembered position on save.
- Exit gate: walk a 3-zone test strip on keyboard and both phone sizes with no overlap/clipping bugs.
### Slice B - Interactive environments, NPCs, non-combat objectives (~3 sessions)
- Interactable types as data: inspect, hold-to-channel (exists), pick-up, lever/gate, switchable props, ambient reactions (puddle ripples, signs, tram doors), world-state flags persisted in the save.
- Dialogue v2: choices (2-3), flag/relationship effects (bounded: Mira trust), emotes/portrait expressions, NPC barks and idle routines, a dialogue data validator test.
- Objective types beyond combat: find/talk, deliver item, timed hold, avoid-the-scanner (light stealth), bell-resonance rhythm puzzle, repair; quest log UI; rewards that are not combat; first two side missions from the design doc as skeletons.
- Exit gate: a playable non-combat hub chapter ("Lantern Quarter hub": 3 NPCs, 2 objectives, 1 puzzle) that reuses the Episode 2 Quarter, so no Episode 3 content is needed yet.
### Slice C - Cinematic dialogue and cutscenes (~2 sessions)
- Cutscene runner driven by data timelines: camera moves/punch-ins, character walk/pose, letterbox, fades, SFX/music cues, dialogue lines, skip/auto-advance, reduced-motion respect.
- Convert existing hand-coded scenes (Episode 1/2 intros/endings) to the runner behind a flag, keeping the tested behaviour; stage the hub finale as the showcase.
- Exit gate: one 60-90 s staged scene with a capture at all three viewports.
### Slice D - Character development and progression (~2 sessions)
- Character screen; Echo passive/skill tree v1 (three small branches tied to resonance); first equipment slots (accessory + artifact) with explicit recipes; stat tables as data; save migration with a version field and tests.
- Mira as a bounded ally mechanic (support skill already exists) before any full playable-kit work. Monetization/gacha stays out of scope.
- Exit gate: level 1->10 pacing sheet and a regression for save migration.
### Slice E - Visual consistency and release readiness (~2 sessions, partly parallel with A-D)
- One-page style guide taken from the approved sprites (value structure, outline weight, rim light, bloom limits, palette); apply to UI and world.
- World/NPC/portrait art upgrade plan: replace procedural placeholders in priority order (Mira portrait, Lantern Quarter backdrop, NPC walkers). Source must be approved by you (commission, or free local tools tested first with a quick feasibility check, as we learned with Blender).
- Texture budget table + a size/memory lint test (VRAM-compressed frames, lazy-load Phase 2), web+Android compatibility checks, device test pass.
- Exit gate: release candidate for the milestone with the full regression, Chromium matrix and device checklist.

## Not in this milestone
Episode 3 implementation (its design lives in `docs/STORY_AND_ROADMAP.md`; the hub chapter above produces the tools it will need), Cantor changes (unless a serious defect appears), monetization, new heroes' full kits, online features.

## Risks / decisions needed from you
1. Art source for world/NPC/portraits (largest quality lever and the main unknown cost); approval needed before any generation or commission.
2. Keep the side-view-with-depth-lane exploration (recommended: matches battle and mobile controls) vs top-down (larger rewrite).
3. Writing capacity: choices/side missions need approved dialogue; I can draft, you approve tone.
4. Audio: current sound is synthesized; any music/SFX pack needs a licence you approve.
5. Real-device testing (Android) needs your device or a device farm; I cannot measure it here.

## Owner decisions, update 2 (recorded)
- Web build = lossless Cantor textures; Android = ETC2 (VRAM); both stay selectable (`tools/set_cantor_textures.sh`, Pages workflow `cantor_textures` input). Android ETC2 remains untested on a device.
- `_trimmed` pipeline folders verified unreferenced by the game and excluded from exports (export file set identical to a clean checkout).
- Season 1 = exactly 10 episodes. Seven-array storyline stays the proposed direction; Episode 3 story and new characters are in `docs/EPISODE3_STORY_PROPOSAL.md` awaiting approval before any implementation.
- Priority emphasis: premium anime adventure (exploration, movement, NPC interaction, story missions, cinematics) over constant fighting.
- Review samples (not integrated): branch `art/lantern-quarter-mira-samples`, `docs/art/samples/README.md` there.
- `dev/overnight-stabilize` was merged (fast-forward) into the release-candidate branch after the full regression; `main` is untouched and nothing was deployed.
