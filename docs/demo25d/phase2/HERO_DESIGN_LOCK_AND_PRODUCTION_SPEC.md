# Hero — official design lock and production specification

> **DESIGN AUTHORITY UPDATE:** Echo V2 is now the official protagonist design (`ECHO_V2_DESIGN_AUTHORITY.md`). Everything in this document describing Hero pack v2, the preview candidate, reference 01 or the white-twist Echo is **SUPERSEDED FOR ECHO** and kept only as a historical record.


**Owner decision (this session):** the four-view Hero candidate (staged at `assets/approved_anime/preview/hero_turnaround_candidate/`, SHA-256 prefixes `3a1052594b70` back, `fc8758cf8c5c` front, `8f4c435de72e` left-facing, `20a9758fa564` right-facing) is the **officially approved Hero design**. Reference 01 is **superseded for the Hero only**. Do not redesign the character. These four images are **visual references, not production sprites**. All production assets stay `MISSING` until genuine artwork is delivered and passes `tools/validate_approved_art.py`, the manual checklist and the owner's visual approval.
## REVISION 2 — current approved Hero reference pack (supersedes the earlier preview candidate)
Owner confirmed (this session) the new four-view pack at `assets/approved_anime/reference/hero_reference_pack_v2/` as the approved Hero reference, labelled **REFERENCE ONLY**. The earlier preview candidate (`assets/approved_anime/preview/hero_turnaround_candidate/`) is now history. Canonical eyes: **warm brown with amber highlights** (owner-stated). Everything in sections 2-3 below describes the *earlier* candidate and is **superseded by this block** wherever they differ.

### Identity as depicted in pack v2 (do not redesign)
- Young lean-athletic Black man, dark-brown skin, strong straight brows, composed intense expression; ~7.5 heads.
- Hair: black locs gathered in a high ponytail/bun with gold wire ties and gold beads/cuffs on loose locs; side undercut with carved line pattern; loose forehead locs.
- Small gold stud earring; two fine chains with a gold diamond pendant holding a red gem; white t-shirt.
- Coat: black hooded long coat, red piping, **red lining and red hood interior**, sleeves rolled to the forearm with red cuffs, brown leather harness straps over shoulders/chest with gold buckles, buckled straps on the sleeves (profiles), small gold-and-red patches on the upper sleeves (front).
- Back: large gold winged-diamond emblem with a red gem and vertical gold line; gold tassel hanging from the belt; split rear vent with red lining.
- Forearms/hands: white bandage wraps; black fingerless gloves with gold plate details.
- Belts: several brown leather belts with gold buckles crossing the hips, hanging straps, gold arrowhead charm; cargo trousers with thigh pockets and **red side stripe/piping**, gathered cuffs.
- Boots: black lace-up boots with brown buckle straps, **red soles/trim**, white socks visible.
- Palette: black, red, brown leather, gold, white. (Replaces the earlier gold-boot/white-sole/circle-crosshair description.)

### Consistency check of pack v2 (what I verified by inspection)
Consistent across views: skin tone, build, hair concept (ponytail + undercut), red-lined black coat, brown harness/belts, boots with red soles, left-view being a distinct drawing (not a mirror).
Inconsistencies/uncertainties the native render must resolve (without redesigning):
1. **Bandage wraps:** front shows a wrap on one forearm and a gold-plated glove/bracer on the other; the back view shows wraps on both forearms. Decide per arm (recommend: wraps on both forearms, consistent in all views).
2. **Sleeve details:** front shows small emblem patches on both upper sleeves; the profiles show buckled straps and no patch. Place patch and straps identically in every view.
3. **Eye hue:** front eyes read red-orange, profiles darker red-brown; native render must use the single canonical warm brown with amber highlights.
4. **Hair back view:** shows a bun/ponytail top-knot; profiles show a longer ponytail with beads. Same length/volume in all four.
5. **Pendant/chain** visible only in the front; keep consistent chain visibility (not required in back/profiles).
6. **Scale/baseline:** the four crops have different scales and baselines (see measurements) and very tight crops.

### Measured properties of pack v2 (Python)
| View | Size | Standing height | Lowest solid pixel | Head-top clearance | Notes |
|---|---|---|---|---|---|
| front | 464x881 | 865 | y=869 | 5 px | feet 54-138 and 365-451 |
| right (faces right) | 348x887 | 874 | y=879 | 6 px | feet overlap |
| back | 519x881 | 861 | y=870 | 10 px | feet 122-203 and 339-428 |
| left (faces left) | 420x887 | 873 | y=874 | 2 px (hair near the crop edge) | feet overlap |
RGBA with transparent corners and no green residue, **but** alpha never reaches 255 anywhere: about 77-80% of the figure's pixels have alpha 250-254 (the manifest's "99.9% semi-transparent"); true soft/fringed edge pixels (alpha < 250) are a small share. Production art must have fully opaque interiors (alpha = 255). Heights 861-874 px at different scales: the figure is ~865 px of the 887 px source height, i.e. the pack is ~0.43x the 2000 px figure that 1152x2304 production renders require (a 2.3x enlargement would be needed, which is exactly what must not be done).

### What is still needed for clean, separate 1152 x 2304 production renders
1. Four **native** renders (not enlargements): `hero_turnaround_{front,right,back,left}_native.png`, canvas 1152 x 2304, figure 2000 px tall, feet baseline y=2176 (the 576x1152 master baseline y=1088 x 2), head top y=176, >= 48 px transparent margin on all sides (the pack's 2-10 px margins risk clipping hair), identical scale and the planted-foot midpoint on x=576 in all four.
2. Clean matte: interior alpha exactly 255; edges <= 1 px anti-aliased; no fringe/spill; no dotted artifacts; no baked shadow/text/borders; deliver #00FF00 originals as well.
3. Resolve consistency items 1-5 above; one canonical eye colour.
4. `hero_face_detail_sheet.png` and `hero_costume_detail_sheet.png` (back emblem, sleeve patches/straps, pendant, glove plates, belts, boots).
5. Only after the owner approves the native renders: layered rig parts (`HERO_RIGGING_PLAN.md`), then animation frames and validation. No rigging or animation before that.
Validator status: unchanged — BLOCKED (no production assets). The validator's soft-edge check now counts only alpha < 250 so near-opaque interiors are not mistaken for fringes; production art must still be fully opaque.

---
## (Earlier candidate) sections below — superseded where they conflict with Revision 2

## 1. Reference status (what is approved and what is not)
| Reference | Status |
|---|---|
| `reference/hero_reference_pack_v2/` (4 views, REFERENCE ONLY) | **APPROVED — current official Hero reference** (supersedes the preview candidate below) |
| Hero preview candidate (preview folder above) | superseded by pack v2; kept for history |
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
