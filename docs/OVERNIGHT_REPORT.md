# Overnight report - Soul Ascension direction change

Repo: `henryboy2471-max/soul-ascension` (only this repo was touched). Live preview (GitHub Pages): https://henryboy2471-max.github.io/soul-ascension/

## 1. Completed
Episode 1 is now an adventure episode instead of one arena fight: cinematic title card, opening scene, explorable Neon District, NPC conversation with portraits, objective chain with waypoint, hold-to-channel relay terminal, optional lore spots, Soul Realm breach, a two-wave Soul Realm battle (Resonance Shade, then the Soul-Warped Enforcer boss with a Phase 2 and a cinematic finisher), ending scene, next-episode teaser, rewards. Plus Codex progression, ambient audio, a rotate prompt for portrait phones, and several fixes found by real playthroughs.

## 2. Commits this session (newest first)
- aa02083 Home push-in, Episode 1 labels, CLAUDE.md working notes
- d4247c8 Codex unlocks, in-world toasts and a portrait-orientation rotate prompt
- 805144c Soul Realm waves and cinematic boss finisher
- ecfbd62 Fix engine warnings when closing menus and screens on touch
- 6de5363 Fix conversations instantly re-triggering after they close
- 0f4aae5 Ambient audio, lore mural, sharper hero face, baked background layers
- 2750eca Soul Realm arena, warped boss, dash trails, slash effects, ambient district life
- 66c1267 Add Episode 1 adventure structure: exploration, NPC dialogue, objectives, boss phase
- 30ef2ca / 0496096 Pages workflow
- 31e891c Takeover repairs (earlier)

## 3. Tested
- Godot suites: test_phase1 (34), test_repairs (13), test_adventure (30, drives the whole Episode 1 flow), test_live_combat (live win + auto replay). All pass locally and in CI on every push.
- Browser (headless Chromium, local build of the exact commit): full keyboard playthrough title -> NPC -> terminal hold -> breach -> shade -> boss -> ending -> rewards, no console errors. Phone-sized touch run (fixed + floating stick, tap-to-advance, ACT button), no console errors.
- Performance probe (software renderer, pessimistic): district about 22 ms/frame, boss battle about 20 ms/frame; static layers are baked to textures.

## 4. Browser build
CI builds and deploys on every push (latest code run green). The live GitHub Pages URL could not be opened from the sandbox (egress policy), so live-site playback was verified through local builds of the same commits, not the hosted page itself.

## 5. Visual changes
Cinematic title/ending cards with the key art, dimmed key-art backdrop for scenes, layered parallax neon district with rain, wet street, stalled tram, signs, lamps, ambient pedestrians; dialogue box with portraits (hero = real key-art crop); Soul Realm arena (mirrored city, runic floor, shards, motes); warped boss with halo, core and spikes; dash afterimages, slash streaks, finisher flash/push-in; sharper hero face/hair; home screen slow push-in and faded art edges.

## 6. Gameplay changes
Exploration with objectives and waypoint; NPC/lore interaction; hold-to-channel activation; energy spent only when entering the Soul Realm; two-wave battle with Phase 2; Codex (6 entries, saved); episode flow with rewards; battle-only mode kept; input guard and buffering, floating joystick, tighter movement (earlier pass).

## 7. Remaining problems
- Characters, enemies and the district are still procedural shapes (placeholder level). The biggest remaining gap to the target anime look is real character art/animation.
- No music (only ambient loops and short effects). Fonts are Godot's fallback font.
- Touch tested with synthetic events only; Android export never built or run on a device.
- Only Episode 1 exists. Episode 2 is a teaser. The episode logic is hardcoded; a data-driven objective system is the next structural step.
- Live Pages page not directly verified from the sandbox (see 4).
- Battle-only mode still shows the old arena and "PROTOTYPE COMBAT ART" label.

## 8. Next recommended step
Decide the art route. Approve either commissioned/generated character art (hero, Mira, shade, boss, enforcer: idle/walk/attack frames and portraits) or a spend limit for AI image generation, then swap the procedural rigs for sprite-based characters. Everything else (episode flow, tests, deploy) is ready for that swap. After art: generalize objectives into data for Episode 2.
