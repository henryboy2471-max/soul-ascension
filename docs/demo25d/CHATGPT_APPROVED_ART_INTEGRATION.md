# SOUL ASCENSION — approved anime art integration checkpoint

Status: **PREPARATION ONLY — NOT IMPORTED OR PLAYABLE**
Source branch: `demo/neon-district-2.5d`
Working branch: `chatgpt/approved-anime-art-integration`
Owner approved the visual direction in chat on October 10, 2026. No merge or deployment is authorized.

## Approved visual target
- Premium, crisp 2.5D anime; predominantly Black cast with individualized detailed facial features, natural Black hairstyles and varied silhouettes.
- Hero: black-and-gold futuristic coat, dark twist/loc hairstyle, detailed boots and gloves; keep face and costume consistent front, side, back.
- Imani: Black female character with long braids, purple-and-black futuristic outfit and gold accents, consistent in all views. **Note:** previous demo depicts Imani as a tram-repair worker in different clothing. Treat the new design as proposed visual replacement; preserve her story role and dialogue.
- Neon District: multilayered futuristic rainy city, varied architecture, elevated tram, readable tram repair kiosk and Clinic 24 signage, atmospheric lighting, reflective wet street, readable interactive path and foreground occlusion.
- Reject existing flat procedurally rendered people/city as final art; keep only for non-production mechanical testing.

## Art currently available
ChatGPT generated approved *composite concept illustrations*: hero turnaround/portrait, Imani turnaround/portrait, Neon District illustrated gameplay mockup. These are **references**, not clean transparent sprite frames, layer-separated backgrounds, or runnable scenes. Images exist in the conversation, but no corresponding binary game assets have been committed to this repository in this checkpoint. Do not imply otherwise.

## Verified loader and tooling on source branch
- Godot 4.4 project; 1280x720 viewport, canvas_items stretch, GL Compatibility renderer (`project.godot`).
- `tools/art25d/chargen.py` outputs placeholder front/side/back strips with 5 frames per direction (one idle plus walking frames), 144 x 288 frame size; these are **rejected final art**.
- `tools/slice_sheet.py` can slice, trim and foot-anchor real sprite sheets, but automatic background removal and frame detection require careful visual QA; don't process the composite character sheets directly.
- `tools/build_spriteframes.gd` reads `assets/characters/<name>/manifest.json`, with `animations` entries specifying `fps`, `loop`, `frames_out`, and optional `flagged`; reads individual PNGs from `frames/` and saves `frames.tres`. Flagged/empty animations are skipped.
- The earlier art checkpoint records four-direction movement, depth/collisions, dialogue, touch controls and test history, but that history is **not a fresh test run on this branch**.

## Required production asset contract
1. For **each** character: three coherent views (front, profile facing right, back); mirror side only if costume/lighting symmetry works. Supply idle and believable walk animation, 5 or more transparent RGBA PNG frames per view. Same head proportions, clothing, accessories, height and foot-anchor across frames. No text, montage borders or embedded UI.
2. Prefer source art at 2x (minimum 288x576 per frame) or higher, and downsample only after inspecting the character **at actual on-screen scale**. Confirm exact per-frame size in consuming GDScript before changing constants.
3. Add one crisp 512x512+ RGBA dialogue portrait per character (or use portrait-sized art with alpha).
4. City: separate sky/far skyline/mid-buildings/storefronts/floor/near foreground/interactive overlays, with suitable transparent occlusion layers. Preserve collision shapes and collision-safe readable ground. The illustration with HUD overlaid is reference only; never use it as a single static gameplay background.
5. Provide asset provenance and generation method; no paid service without explicit approval. Do not use third-party copyrighted character art.
6. For animations, prefer artist-corrected frames or layered 2D skeletal rigging when AI-generated view consistency is unreliable. Never stretch one still to simulate a walk.

## Safe integration checklist (after usable art is supplied)
- [ ] Stage raw source images outside final imported assets; review hero and Imani front/side/back at 100% zoom.
- [ ] Validate alpha, absence of text/borders, silhouette, no clipped limbs, matching identity and foot anchor.
- [ ] Produce and inspect per-direction idle/walk frames at 1280x720 game screen scale.
- [ ] Put approved frames in separate new asset folders so existing prototype remains a fallback.
- [ ] Run `python3 tools/slice_sheet.py` as appropriate, review the manifest warnings, then Godot import before `tools/build_spriteframes.gd`; do not force flagged output into release art.
- [ ] Wire frames, portraits and layered scene by feature flag / separate scene, without touching story flags, player saves or episode data.
- [ ] Validate static screenshot *and movement video* for all views, NPC interactions, depth/occlusion, mobile joystick and frame-time budget on Chromebook/mobile.
- [ ] Record exact commands, branch, commit, 1280x720 screenshots, before/after comparison, failures and known gaps.
- [ ] STOP for owner's approval. Do not merge into main; do not publish or deploy.

## Current blockers
Clean separate sprite assets / animations and separated layered environment images have not been authored. Concept montages and HUD mockups are insufficient for a production import. This branch intentionally changes **documentation only**.
