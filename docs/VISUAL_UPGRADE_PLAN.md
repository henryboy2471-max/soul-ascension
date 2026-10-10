# Visual upgrade plan (plan only; no new major art generated, purchased, commissioned or integrated)

Companion to `docs/VISUAL_DIRECTION_PROPOSAL.md` (style, deliverables, four production options) - this adds the inspection findings, the area-by-area plan, the option comparison and the Android budget. Everything here waits for owner approval of the visual direction.

## 1. Inspection of the current build (Chromium captures of Episode 1/2 at 1280x720, 844x390, 667x375)
What already reads as premium anime: Hero, Mira, Enforcer, Shade and Cantor v2.1 sprites (dark ink outline, rim light, saturated accent, glow), the neon/violet palette, the Soul Realm arena with rain and halo rings, the objective HUD with the diamond waypoint, the boss intro cards and Phase 2 banner.
What reads as placeholder or generic:
1. **Environments**: Skybridge/Lantern Quarter are procedural flat-shaded buildings with window rectangles; little depth, no painted detail, repeating shapes. This is the largest gap to "detailed futuristic environments".
2. **NPC walkers and sleepers**: simple hooded figures; no faces, no expression, no idle life.
3. **Dialogue portraits**: crops of existing art with a single expression; no emotion changes during talks, so scenes feel like text boxes rather than anime.
4. **Battle HUD**: dense fighting-game button cluster is always visible; for an adventure-first feel the explore HUD is better than the battle one. (Do not change combat logic; only presentation.)
5. **Small defects found** (not fixed overnight, cosmetic): boss intro card text can overlap combat popups ("CRITICAL / 6 HIT") for ~1-2 s at the start of a fight; phone text is small at ~0.5x scale (already a documented known issue).
6. **Cinematics**: transitions are fades, letterbox and title cards; no staged shots, no camera moves in story scenes.

## 2. Plan by area
| Area | Plan | Needs approval? | Cost |
|---|---|---|---|
| Character sprites | Keep approved sprites. New characters/NPCs follow the v2.1 pipeline (procedural renderer) or commissioned sheets (see options). Add 2-3 extra idle/talk poses for NPCs rather than full sets. | New designs: yes | low (procedural) / paid (artist) |
| Expressions and animation | Dialogue portraits get 5 expressions (layered eye/mouth/brow overlays on a base bust); sprites get blink/breath idle micro-motion. Engine-side: swap portrait layer on a dialogue line tag. | Art: yes. Engine hook: no | low |
| Futuristic fantasy environments | Rebuild each zone as 4-5 painted-style parallax layers (sky/skyline, mid buildings, props, street, foreground) using the same techniques as the Cantor renderer (ink contours, rim light, fog, bloom, window glow, signage with emissive text), plus interactive prop states. | New art: yes (direction) | medium |
| Soul Realm effects | Extend existing arena: layered volumetric rays, resonance rings, drifting bell/mote particles, palette shift per episode; reuse Cantor halo/wing language for bosses. | No (effects only) | low |
| Premium UI | Unified frame language (silver-lavender bracket frames), animated dialogue frame, quest log, codex pages, softer HUD in explore, adaptive scale for phones. | Direction: yes | low |
| Dialogue portraits + cinematics | Portrait bust set per speaker (Echo, Mira, Pell, Vaust, Sable...), key-art stills for episode openers/endings, parallax shots with the cutscene runner (roadmap slice C). | Art: yes | medium-high |
| Android performance | Budget below; VRAM (ETC2) for sprite sets; lazy-load per zone; preload next-phase assets during intros (done for the Cantor). | Export changes: later | low |

## 3. Comparison of the four production options (from the proposal)
| Option | Visual quality | Cost | Consistency with approved style | Speed | Risk | Verdict |
|---|---|---|---|---|---|---|
| A. Commissioned artist | highest for faces/portraits/key art | paid, quote needed (I will not guess prices) | high with a brief + our reference sheet | slow (external schedule) | budget, hand-off | best for portraits + key art only |
| B. Local open-source image models | potentially high, uneven | free software; needs the owner's GPU/time (not runnable in this sandbox) | low-medium (frame-to-frame drift) | medium | licence terms, AI-output copyright, store policies | optional experiment only |
| C. Our procedural 2D renderer | good for sprites/props/effects (proved with the Cantor v2.1: owner approved); limited for painted faces and detailed backdrops | free | highest (same code, same palette) | fast iteration | ceiling on hand-painted detail | do first for environments/effects |
| D. Hybrid (artist key assets + engine/procedural animation and lighting) | best quality per cost | partial paid | high | medium | needs an art source | recommended |
**Recommendation (minimal cost, high quality): C + D.** Use the procedural renderer for environments, props, particles and UI (free, already approved quality), and spend any budget only on what code cannot fake: dialogue portrait busts with expressions and 4-6 key-art stills. Run B only as an optional owner-side experiment. Blender 3D stays ruled out (tested, not better).
Suggested first sample (for approval): one Lantern Quarter backdrop rebuilt with the procedural renderer plus one Mira portrait expression set mock-up, shown before any batch work.

## 4. Android-friendly graphics budget (targets; to be validated on a device - none was available)
- Per-zone background: <= 5 parallax layers at 1280x720 logical, authored at 1x (not 2x), lossy/VRAM-compressed, lazy-loaded per zone; unload on zone exit.
- Per sprite set: author at <= 2x display size, trimmed, ETC2 (Android) - the Cantor's 64 frames are ~15 MB compressed vs ~60 MB lossless.
- Portraits: 512x512 busts, atlas of 5 expressions per speaker, ETC2.
- Particles: cap simultaneous emissive overdraw; reuse the bloom-baked sprites rather than runtime blur.
- Load budget: zone transition < 1.5 s on mid-range ([Unverified] target); preload during dialogue.
- Add a texture-budget lint test (size/margin like `tests/test_cantor_sprites.gd`) for every new asset set.
