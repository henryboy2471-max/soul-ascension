# Hero — official design lock and production specification

**Owner decision (this session):** the four-view Hero candidate (staged at `assets/approved_anime/preview/hero_turnaround_candidate/`, SHA-256 prefixes `3a1052594b70` back, `fc8758cf8c5c` front, `8f4c435de72e` left-facing, `20a9758fa564` right-facing) is the **officially approved Hero design**. Reference 01 is **superseded for the Hero only**. Do not redesign the character. These four images are **visual references, not production sprites**. All production assets stay `MISSING` until genuine artwork is delivered and passes `tools/validate_approved_art.py`, the manual checklist and the owner's visual approval.

## 1. Reference status (what is approved and what is not)
| Reference | Status |
|---|---|
| Hero candidate, 4 views (preview folder above) | **APPROVED — official Hero design; visual reference only** |
| `01_main_hero_turnaround_portrait.png` | **SUPERSEDED for the Hero** (keep for history; do not use as design source; its portrait panel is no longer the Hero's face reference) |
| `04_imani_black_female_npc_turnaround_portrait.png` | approved visual direction for Imani (unchanged); reference only |
| `05_neon_district_gameplay_mockup_with_hud.png` | approved look/lighting/signage for the Neon District; reference only; HUD never extracted |
| `03_overview_mockup_hero_npc_environment_with_hud.png` | composition reference only; its Hero turnaround panel is superseded; HUD never extracted |
| `02_cast_portrait_montage_2x2.png` | four portraits **UNASSIGNED** until the owner approves identities |
| Everything under `assets/approved_anime/characters/` and `.../environments/` | does not exist yet: **MISSING** |

## 2. Identity lock (as depicted in the four approved views; do not change)
- **Person:** young, lean-athletic Black man, dark-brown skin, strong straight brows, intense composed expression, ~7.5 heads tall. Preserve face structure, nose and lips exactly as in the front and profile views.
- **Hair:** black locs/twists, side undercut, gathered into a **high ponytail** (seen in both profiles) with loose locs/strands over the forehead in the front view; gold hair cuff/tie at the ponytail base.
- **Earrings:** gold stud earrings (visible in both profile views); the front/back views must show both ears consistently.
- **Neck/chest:** layered gold chains with a gold pendant (key/ankh-like glyph); white t-shirt.
- **Coat:** black hooded long coat, gold-piped lapels and hem, **red inner lining and red hood interior**, sleeves pushed to the elbow with gold-lined bunched cuffs, gold diamond emblem on the upper sleeve, hood drawstring tassels, long open front with split rear vent showing red lining.
- **Back emblem:** large gold **circle-and-crosshair** glyph on the upper back with a gold diamond below it (as in the back view).
- **Forearms/hands:** white bandage wraps on both forearms; black fingerless gloves with gold knuckle plates and a gold diamond plate on the back of the hand.
- **Belt/pouches:** two brown leather buckled belts, small brown satchel/pouch at the hip, thigh cargo pockets with brown straps and gold buckles.
- **Trousers:** wide black cargo trousers with gold glyph accents on the pockets and gathered ankle cuffs.
- **Boots:** black high-top boots with gold panels, red top cuff and chunky white soles.
- **Palette:** near-black, gold, red lining, white (shirt, wraps, soles), brown leather.

## 3. Cross-view inconsistencies the native re-render MUST fix (without changing the design)
| Issue seen in the candidate | Canonical rule for the native art |
|---|---|
| Eye colour differs between views (front brown, right-facing yellow-green) | **One colour in every view: the front-view warm brown with amber highlights** (owner may override in one line); same iris size/highlight placement |
| Hair silhouette differs (ponytail clear in profiles, not readable in front/back) | ponytail + undercut visible and identical in length/cuff position from all four views; back view must show the ponytail and undercut, front shows the ponytail rising behind the head and the loose forehead locs |
| Earring/pendant visibility unclear in front/back | both studs and the pendant chain visible in the front view; both studs visible in the back view |
| Back emblem exists only in the back view; sleeve diamond only in profiles | both emblems placed identically in every view they appear in; draw the sleeve diamond in the front view on the visible sleeve |
| Foot spacing and stance differ per view | A-pose, feet shoulder-width in front/back; in profiles feet staggered by a consistent step; same boot design and sole height in all four |
| Left view not the mirror of right (good) | keep genuinely drawn left side: strap/pouch/glove details follow the 3D logic of the costume |

## 4. Native-resolution turnaround specification (the next deliverable)
- Four **separate** transparent PNGs: `hero_turnaround_{front,right,back,left}_native.png`; recommended working canvas 1152 x 2304 (2x of the 576 x 1152 master), figure 2000 px tall; deliver downscaled 576 x 1152 masters as well after approval.
- Rendered/painted **at native resolution** — no enlargement of the existing 1774x887 composite, no AI upscaling of those crops.
- Delivery matte: first deliver on a flat **#00FF00** background (no gradient/shadow/reflection), then a clean alpha version with: edge anti-aliasing <= 1 px; **no light/grey/green fringe (de-spill the key colour)**; **semi-transparent pixels <= 8% of silhouette pixels** (validator-enforced); **no stray dots/dashes or floating fragments** (the faint dotted line near the head top in the candidate must not recur); no baked shadow, text, borders or UI.
- Alignment: identical canvas and scale in all four views; the standing figure is 1000 px tall at the 576x1152 master (head top y=88, sole y=1088); **anchor on the planted-foot midpoint / pelvis (x=288), not on the bounding box**; side views keep the feet staggered so contact poses are legible.
- Lighting: flat even lighting with the approved cel shading and gold/red accents; no strong cast shadows that would not survive on the wet neon street.
- Premium quality: crisp line work with varied weight, defined eyes with highlights, defined nose and lips, believable hands (five fingers), clean fabric folds, gold hardware with controlled highlights; "not blurry, not cartoonish, not pixel art".
- Also deliver `hero_face_detail_sheet.png` (front, both profiles, back-of-head, eyes close-up) and `hero_costume_detail_sheet.png` (back emblem, sleeve emblem, pendant, glove plates, belts/pouches, boots front/side/back) to lock identity before parts are cut.

## 5. Layered rigging requirements (starts only after the turnaround is approved)
Four separate rigs (front, right, back, left); no mirroring. Every part is a transparent PNG at master scale with a pivot, parent bone and z-order in `rig_pivots.json`, with painted-under overlap at each joint so no gaps show during animation.

**Movable arms:** shoulder (under coat), upper arm + rolled sleeve and cuff, forearm with bandage wrap, **hand**. Hands: relaxed hand plus an alternate swung/open hand per side; glove plate and knuckle gold pieces as separate or baked-in layers (decide with artist).
**Movable legs:** pelvis/hip, thigh with cargo pocket + strap, shin with trouser cuff, **boot** (upper, sole as separate layer for heel lift/toe flex), left and right drawn separately.
**Hair:** back hair/undercut plate, front hair mass, **ponytail 3-4 segments**, loose forehead locs 2 segments each, hair cuff; behind-head plate for the back view.
**Clothing:** hood (outer + red inner, 2 segments), coat collar/lapels, coat front panels (L/R, outer + red lining, 3 segments each), coat rear panel(s) with vent and back emblem, sleeve cuffs, t-shirt, trousers, belts.
**Accessories:** pendant chain + pendant (1-2 segments), earrings, satchel/pouch (pendulum), thigh strap and buckles, hood drawstring tassels (1 segment each), bandage tails.
**Face:** head with a clean face layer; optional separate eyes/brows/mouth layers for blink and expressions (front view first).
**Hidden-area painting required:** torso under head/neck, shoulder joints under coat, upper arm under sleeve, coat interior and lining when panels swing, trousers under belts, hip under coat tails, behind-head hair, ear under hair, hand backs/palms, heel/sole undersides when lifted, hood back.
Animation targets, skeleton and gates remain as in `HERO_RIGGING_PLAN.md`.

## 6. Files that must be created next (all `MISSING`)
1. `hero_turnaround_front_native.png`, `hero_turnaround_right_native.png`, `hero_turnaround_back_native.png`, `hero_turnaround_left_native.png` (+ the #00FF00-matte originals).
2. `hero_face_detail_sheet.png` and `hero_costume_detail_sheet.png` (identity lock).
3. **After the owner approves 1-2:** `source/hero/parts/{front,right,back,left}/*.png` + `rig_pivots.json`; alternate hand poses; blink/expression layers.
4. **After rigging:** `assets/approved_anime/characters/hero/frames/{front,right,back,left}_{idle_00..01,walk_00..05}.png`, `manifest.json`, `anchor.json`, `portrait.png` (1024) + expression portraits, `PROVENANCE.md`.
The Imani, NPC and environment deliverables are unchanged (`PRODUCTION_ASSET_MANIFEST.md`, `ART_BRIEFS.md`).
