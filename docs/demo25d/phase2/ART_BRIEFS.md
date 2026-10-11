# Phase 2 — Image-generation / illustration briefs (for ChatGPT or a human artist)

Use with `PRODUCTION_ASSET_MANIFEST.md`. Reference images: `assets/approved_anime/reference/01..05`. Give the relevant reference image(s) to the generator for every brief. No paid services without owner approval. Report generation tool, date, prompts and seeds in `PROVENANCE.md`. Never include HUD, text, logos other than the in-universe diamond emblem on the hero's clothing, borders or watermarks.

## Shared style block (paste into every brief)
"Premium crisp 2.5D anime game art, hand-crafted look, clean confident line work with varied line weight, cel shading with rich soft secondary shading, strong rim light in violet/cyan/gold from a neon city, detailed eyes with highlights and defined nose and lips, natural Black hair rendered with believable texture, correct anime proportions (about 7-7.5 heads), proper hands with defined fingers, believable fabric folds and layered futuristic clothing, sharp 4K detail. Not pixel art, not chibi, not flat vector, not 3D render, no blur, no noise, no text."
**Global negative:** "blurry, low resolution, deformed hands, extra fingers, stretched nose, distorted face, asymmetrical eyes, uneven proportions, mannequin pose, cropped feet or head, text, watermark, UI, HUD, speech bubbles, borders, cast shadow on background, white halo, mixed art styles, changed outfit, changed hairstyle, lighter or darker skin than reference."
**Background rule for sprite-source art:** flat solid #00FF00 key background (green is absent from every outfit/palette), no gradient, no floor shadow, no reflection, subject fully inside frame with >= 24 px margin; so a clean matte is possible. If a generator cannot honour this, request a plain light-grey background and a separate hand-cleaned alpha pass, and flag it.

## A. Hero — clean orthographic turnaround (PRIORITY 1)
Reference: file 01. Output 3 separate images (or one sheet with exact equal panels, no borders), each 1152 x 2304 or larger: front, right-facing profile, back.
Prompt: "Full-body orthographic character turnaround of the SOUL ASCENSION Main Hero exactly as the reference: young Black man, dark-brown skin, short black twists with small gold hair cuffs, amber eyes, gold hoop earring on his left ear, black hooded long coat with gold trim and glowing gold hardware, gold-lined hood interior, glowing gold diamond emblem on the upper sleeve and large on the back, cross-body strap with a gold-framed pouch, black layer with armoured gold-trimmed forearm bracers and fingerless gloves with gold knuckle studs, black cargo trousers with a thigh strap and utility pouch, chunky black-and-gold boots. Neutral standing A-pose, arms slightly away from the body, feet shoulder-width, same height in all three views, eye line and boot soles aligned across views. Style block. Flat solid #00FF00 background."
Consistency locks: hair length and cuff positions identical front/side/back (reference back view looks shorter — correct it to match the front), emblem position, strap side, earring side, glove details.
Acceptance: passes checklist sections C and D.

## B. Hero — layered rig parts (PRIORITY 2, recommended) or walk key-pose sheets
Preferred: separate transparent part layers from the approved turnaround so a skeletal 2D rig (or an animator) can build fluid walk/turn/idle: head (with hair front/back split), neck, torso, coat front panels L/R, coat back panels, hood, upper arm L/R, forearm+bracer L/R, hand L/R, pelvis, thigh L/R, shin L/R, boot L/R, pouch, strap, hair strands/cuffs (secondary), for front, side and back. Each part transparent, same scale, overlapping join areas painted underneath so joints do not show gaps. Layout sheet plus individual PNGs.
Alternative if owner declines rigging: six key walk poses per direction (contact A, down, passing, contact B, down, passing) on the green key background, same camera and scale, identical costume, feet planted on a horizontal reference line. Generate each pose from the approved turnaround as an image reference; reject any frame that changes face, hair or costume.
Prompt (key poses): "Same character, same costume, same scale and camera as the reference turnaround, walking cycle pose <N> of 6, <direction> view, ..., flat #00FF00 background, orthographic, full body, feet on the same baseline."

## C. Imani — clean orthographic turnaround (PRIORITY 3)
Reference: file 04. Output front, right profile, back, 1152 x 2304+.
Prompt: "Full-body orthographic turnaround of Imani, young Black woman, warm medium-brown skin, very long black box braids with violet tints and gold braid cuffs (hair falls past the waist, braid length and gold cuff placement identical in all views), brown eyes, large gold hoop earrings, gold choker with a diamond pendant, purple off-shoulder crop top over a black under-layer, purple arm bands, black fingerless gloves with gold accents, black wide cargo trousers with a layered asymmetric purple skirt panel with gold diamond motifs, gold belt and thigh strap with a small pouch, black-and-gold lace-up boots. Neutral A-pose, ~0.94x the hero's height. Style block. Flat solid #00FF00 background."
Then repeat brief B (parts or six key poses) with extra follow-through: braids and skirt panels sway on a delay, never clipping through the body.

## D. Portraits and expressions (PRIORITY 4)
Reference: portrait panels of files 01 and 04. 1024 x 1024 transparent (or on #00FF00), head-and-shoulders, three-quarter angle toward screen-right and a front-facing variant, same lighting as the sheets.
Hero set: neutral, determined, smirk, surprised, hurt. Imani set: neutral, smile, smirk, wink, thoughtful (the five heads in file 04 are the target). Eyes sharp with highlights, defined nose, consistent face structure across all expressions, no text/frames.

## E. NPCs
Same turnaround + walk spec as Hero (tier A) or compact (tier B). Produce one clean turnaround per NPC first and wait for approval before frames. Variety rules: predominantly Black cast, different skin tones, face shapes, ages, builds and hair (locs, afro, fade, twists, braids, puffs, bantu knots, headwraps, shaved); fashion mix of futuristic streetwear, workwear and cultural-influenced pieces; each silhouette distinct at 100 px height.
- npc_a1_tram_technician: stocky bearded man, flat cap, blue holo-goggles, sleeveless tool vest over grey work shirt, gloves, utility belt, glowing wrench datapad; works at the kiosk (reference files 03/05).
- npc_a2_courier: courier in white tactical jacket and black pants with large backpack and delivery tablet.
- npc_a3_grey_hoodie: relaxed pedestrian in grey hoodie, cargo trousers, sneakers with lit soles.
- Tier B list (10): umbrella walker (transparent umbrella with neon edge), student with backpack, noodle vendor with apron, elder with cane and headwrap, teen with headphones and puffs, security guard with visor, two-person couple (separate sprites), delivery runner, tram commuter in raincoat. Names TBD by owner.
- **UNASSIGNED:** file 02's four busts. Do not generate bodies or names for them. Only produce a clean transparent portrait crop if the owner approves identities.

## F. Neon District layers (PRIORITY 5) — one image per brief, no HUD, no characters
Reference: file 05 (mood, signage, lighting), file 03 (composition). Projection note: author for the engine's frontal depth plane (see manifest section 5); keep the same buildings/signs/lighting so the district is recognisable.
Shared env prompt: "Cinematic futuristic anime city district at night in heavy rain, premium hand-painted anime background art, dramatic violet/magenta/cyan/gold neon lighting, wet reflective pavement, atmospheric haze, rich architectural variation (balconies, scaffolding, rooftop gardens, signage, pipes, cables, awnings), no repeated window grids, no flat geometric blocks, no characters, no HUD, no text except readable shop signs: TRAM REPAIR, CLINIC 24, SKYBRIDGE 09, MIDDLE HOUSE, NEXS."
1. `sky.png` 2560 x 1440 opaque: storm clouds, violet glow, faint rain, no buildings.
2. `far_skyline.png` 4608 x 900 transparent above the skyline: three depth bands of towers, a saucer-ring observation spire, an elevated tram line and bridges in silhouette with lit windows; horizontally seamless.
3. `mid_buildings_0..2.png` 3200 x 760 each, seamless edges between tiles: street-level facades with tram repair kiosk bay, Clinic 24 block, MIDDLE HOUSE restaurant, market arcade, residential stack with balconies and rooftop garden, each distinct neighbourhood strip. Building base line at y=784; ground contact area left clean for the floor layer.
4. `street_floor_0..2.png` 3200 x 656: wet paving with puddles, kerb, road lanes and crosswalks, grates, neon reflection smears; perspective rows widening toward the bottom edge; no cars or people.
5. `foreground.png` tiles 3200 x 1440 transparent: sparse blurred poles, hanging signs and cables, umbrella edges, leaves, rain-streaked glass; centre of frame kept open.
6. Props (individual transparent PNGs with base anchor): Tram Repair kiosk with readable sign and holo-wrench panel; Clinic 24 sign tower with large cross; SKYBRIDGE 09 sign; lamp post (2 variants); hover car (side view and 3/4 view, 2 colourways); elevated tram segment with lit windows; vending machine; bench; planter with glowing flowers; crates; umbrellas. Each on #00FF00 or transparent, lit consistently from neon sources.
7. `light_masks`, `reflection_plate.png`, `collision_mask.png` per manifest — authored after layers are approved so they align exactly.

## G. Process rules
- One asset class at a time; send each result to the owner for approval before the next.
- After generation: record provenance, remove matte, verify transparency, run the checklist; reject and regenerate rather than patching a flawed face or hand.
- Never stretch a single still to fake a walk. Never reuse the HUD-bearing mockups as backgrounds or sprites.
