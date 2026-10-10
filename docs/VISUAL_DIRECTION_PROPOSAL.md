# Visual direction proposal - for owner approval BEFORE any major new character/NPC/environment art

Status: proposal only. Nothing in this document has been generated or commissioned. Goal: premium anime-illustration characters and detailed futuristic environments that read as one series, consistent with the approved Hero, Shade, Mira, Enforcer and Hollow Cantor v2.1.

## 1. What "our style" is (taken from the approved sprites, not invented)
- Value structure: near-black base (#101010-#101030), deep indigo/violet midtones, one saturated accent per character, small areas of luminous light (silver/lavender/cyan) for focal points. Hero: cobalt blue + gold trim over black. Mira: violet + warm orange accents. Shade: black armor with violet energy. Enforcer: black with crimson. Cantor v2.1: indigo robes, silver trim, pale porcelain mask, bell-halo bloom.
- Rendering rules: clean dark ink outline of uniform weight, 3-tone cel shading with a deeper shadow core, cool rim light from the upper left, restrained grain (no scratchy hatching), bloom only on emissive elements (halos, eyes, sigils, bells).
- World: rainy neon night city (Neon District), violet Soul Realm. Warm window/lantern lights against cool blue-violet shadows; wet-street reflections; parallax depth with fog.

## 2. Deliverables this direction would cover (each needs its own go-ahead before production)
1. Environment kit for Lantern Quarter and the next Season 1 zones: 4-5 painted parallax layers per zone (sky/skyline, mid buildings, props layer, street, foreground), signage/props sheet, interactive-prop states (on/off/broken), ambience VFX sprites.
2. Character portraits for dialogue: bust portraits with 5 expressions each (neutral, speaking, worried, determined, smiling/angry as needed) for Echo, Mira and the next three NPCs; consistent crop and lighting.
3. NPC full-body sprites: idle/walk/talk poses, 3 at first (the Lantern Quarter hub cast).
4. Cinematic key art: 4-6 stills for the hub finale and Episode 3-10 teasers, plus layered parallax shots for cutscenes.
5. UI skin: dialogue frame, quest log, objective HUD, codex pages aligned to the palette.

## 3. Production options (to compare, you choose)
| Option | Quality ceiling | Cost | Risk |
|---|---|---|---|
| A. Commissioned/hired artist, art brief + reference sheet from this document | Highest, matches "premium anime illustration" | Paid - needs your approval and budget | Schedule and style handoff |
| B. Local open-source image models run on YOUR machine (SDXL/FLUX-class, ControlNet), then hand cleanup | High potential, uneven consistency across frames | Free software, your GPU/time; I could not run it in this sandbox (no GPU, model hosts blocked) | Model licence terms, unclear copyright status of AI output, store policies, frame-to-frame consistency |
| C. Our procedural 2D renderer (as v2.1) | Good for sprites, limited for painted backdrops/portraits | Free, fast to iterate | Does not reach hand-painted detail for faces and environments |
| D. Hybrid: artist paints key assets, we animate/parallax/light them in-engine | Best quality/cost balance | Moderate | Needs an art source anyway |
My recommendation: D (A for portraits and key art, C/engine tooling for animation and lighting), with B only as an optional experiment you run and approve. Blender 3D is ruled out (tested; not better than v2).

## 4. Technical budget (applies to any option)
- Sprites/portraits: author at 2x the display size at most; trim transparent borders; atlas where practical; VRAM-compress (ETC2 Android / S3TC desktop) with a lossless web option kept until you approve one (see the web texture comparison).
- Backgrounds: parallax layers at 1280x720 logical size, 1-2 layers lossy-compressed; lazy-load per zone; target <= ~25 MB GPU texture memory per zone on mobile ([Inference] budget, to validate on device).
- Every new asset set gets a margin/size lint test like `tests/test_cantor_sprites.gd`.

## 5. Approval gate
Please approve: (a) this style description, (b) the production option, (c) which deliverables to start with. First sample (one portrait or one backdrop layer set) is shown for approval before any batch work.
