# Adventure structure (direction change)

Soul Ascension is moving from a single arena fight to an episodic anime action-adventure: story, exploration, NPC conversations, objectives, Soul Realm mission zones and boss battles. Combat is one system inside that loop.

## Episode 1 flow (playable now)

1. Cinematic title card (key art, slow push-in, letterbox).
2. Opening scene (narration + the hero) over dimmed key art.
3. **Explore** Skybridge 09 (2500 px wide, parallax neon district, rain, wet street, stalled tram).
4. **Objective 1** find Mira Vey (NPC dialogue with portrait) -> **Objective 2** hold the relay terminal to reboot it (hold-to-channel, not a tap) -> the terminal opens a **Soul Realm breach** -> **Objective 3** enter it.
5. Mission-zone card, then the **Soul Realm battle** (costs 6 energy; if short, the player stays in the district): wave 1 a Resonance Shade (240 HP), then the Soul-Warped Enforcer boss (820 HP). Clearing a wave heals 60 HP and refills 40 Aether.
6. Boss escalates at 50% HP (Phase 2: faster telegraphs, harder hits, red aura, banner, letterbox). The killing blow plays a cinematic finisher (flash, push-in, letterbox).
7. Ending scene, "Next Episode" teaser card, then the reward screen (first clear 120 XP / 250 Gold).

"BATTLE ONLY" on the mission screen and "REPLAY BATTLE" on the result screen keep the original fight available.

## Code map

- `scripts/story/episode_data.gd` - all Episode 1 dialogue, speakers and teaser text.
- `scripts/story/episode.gd` - flow controller (objectives, NPC/terminal/breach events, battle request, ending).
- `scripts/story/dialogue_box.gd` - typewriter conversation UI (tap/Enter/Space/E/J, SKIP).
- `scripts/story/title_card.gd` - cinematic cards.
- `scripts/world/explore.gd` - walkable scene, interaction spots, objective HUD, waypoint, touch controls.
  - Walking pace: `top_speed()` = `SPEED` (300, the original speed) x `walk_scale` (0.3 by default = 90 px/s; the Warden chamber zone sets `walk_scale: 1.0` because `WardenLogic` timing assumes 300). Ease-in 0.3 s / ease-out 0.25 s. Frame delta is capped at 0.1 s (`MAX_FRAME`). Camera: scenery on whole device pixels, characters at exact positions, look-ahead holds when the hero stops.
  - Characters (`scripts/combat/fighter.gd`): in exploration `idle_hold` stands on ONE idle frame with a 1% eased breath, walk<->idle and turning dissolve over 0.12 s (`start_blend`); `calm` (reduced-motion setting) turns both off. `gait` scales the walk/run playback (`ANIM_REF` 170 px/s: an estimate; see docs/overnight/STABILITY_QA.md for why the walk art cannot plant its feet at any rate).
  - Frames: the Hero's idle/walk and Mira's run come from `assets/characters/<name>/frames_aligned/` (pixel-exact shifted COPIES made by `tools/align_character_frames.py hero|mira`; originals untouched). Re-run the tool and `godot --headless --editor --import --quit` if the source frames change.
- `scripts/world/world_art.gd` - procedural parallax layers, props, breach, rain, vignette.
- `scripts/combat/battle.gd` - combat, boss intro, Phase 2.
- `scripts/ui/main.gd` - screen router (`start_episode`, `start_battle(from_episode)`, `show_ending`, `show_result`).

## Presentation notes

- The hero portrait is a crop of the real key art. Mira and the Enforcer portraits and all world characters are still procedural rigs (placeholder level). Replacing them needs commissioned or generated art that the owner approves.
- World backgrounds are procedural. Static layers are drawn once and only moved for parallax to stay cheap in the browser build.

## Tests

`tests/test_adventure.gd` drives the full Episode 1 flow headless (20 checks). `tests/capture_adventure.gd` renders screenshots.
