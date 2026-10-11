# Phase 2 — Production asset manifest (SPECIFICATION ONLY)

Branch `chatgpt/approved-anime-art-integration`, base `17dbb0b`. Official visual direction = the five images in `assets/approved_anime/reference/` (files 01-05). **No production-ready art exists yet.** Every asset below has status `MISSING` until real transparent artwork is committed and passes `docs/demo25d/phase2/ARTWORK_VALIDATION_CHECKLIST.md` plus owner approval. Nothing here changes gameplay or runs Godot. Machine-readable list: `asset_manifest.json`.

## 0. Rules
- Original, hand-crafted-looking premium anime art only. No procedural substitutes, no pixel art, no flat vector mannequins, no third-party copyrighted characters.
- Preserve identity from the references (section 2). Season 1 = exactly 10 episodes; main heroes Black; supporting cast predominantly Black.
- HUD, minimap, joystick, prompts, mission text and speech bubbles in files 03 and 05 are **not** art assets and must never be cropped into gameplay backgrounds or sprites.
- The four unidentified cast portraits (file 02) stay **UNASSIGNED** until the owner approves identities; no sprites or briefs beyond reference are produced for them.
- No paid generation/credits without owner approval. Provenance (tool, date, prompt, seed, edits) must be recorded for every asset.

## 1. Global technical conventions
| Item | Spec |
|---|---|
| Format | PNG, RGBA 8-bit, straight (non-premultiplied) alpha, sRGB. No embedded text, borders, watermarks, UI, drop shadows or background remnants |
| Edge quality | clean anti-aliased 1-2 px edge, no halo/fringe from matte removal, no stair-stepping at 100% and 50% zoom |
| Source scale | authored at **2x** engine scale. Character frame canvas **576 x 1152 px** (engine reference 288 x 576). Engine will scale by 0.5 (and by depth 0.74-1.0); do not downscale before delivery |
| Colour | keep palette from references; neutral colour of skin tones preserved across all frames (no per-frame colour drift) |
| Naming | lower snake_case, zero-padded frame index, e.g. `front_walk_03.png` |
| Provenance | `PROVENANCE.md` per character/environment: tool, date, prompts, seeds, manual edits, who approved |

## 2. Character identity locks (from the references; do not redesign)
**Main Hero** (file 01): young Black man, dark-brown skin, short black twists/locs with gold cuff accents, amber eyes, gold hoop earring on one ear; black hooded long coat with gold trim and glowing gold hardware, gold-lined hood interior, diamond emblem on sleeve and back, cross-body strap with gold pouch, black short-sleeve layer with armoured gold-trimmed forearm bracers/fingerless gloves, black cargo trousers with thigh strap and pouch, chunky black-and-gold boots. Palette: near-black, gold (#F2B72A range), grey accents. Build: lean athletic, ~7.5 heads tall.
**Imani** (file 04, "Neon District resident, tram repair kiosk"): Black young woman, warm medium-brown skin, very long black box braids with violet tints and gold cuffs, brown eyes, large gold hoop earrings, gold choker with pendant; purple off-shoulder crop top with black under-layer, purple arm bands, black fingerless gloves, black wide cargo trousers with layered purple asymmetric skirt panels and diamond motifs, gold belt/thigh strap, black-and-gold boots. Palette: violet, black, gold. Slightly shorter than the hero (~0.94x). Story role/dialogue preserved (meet Imani at the tram repair kiosk); the demo's earlier tram-mechanic costume is superseded by this design.
Consistency risks to track: hero back-view hair currently reads shorter than the front; keep hair length, gold cuff placement and emblem position identical in every view.

## 3. Character frame layout (all animated characters)
| Item | Spec |
|---|---|
| Frame canvas | 576 x 1152, transparent, identical for every frame of a character |
| Foot anchor | horizontal centre x = 288; ground contact baseline y = 1088 (64 px below for soft shadow/reflection headroom). The lowest sole pixel of the planted foot sits on y = 1088 in every frame; the character's *pelvis centre* stays on x = 288 +/- 6 px except for natural walk offset |
| Standing height (head top to sole) | Hero 1000 px; Imani 940 px; other NPCs 860-1020 px per role (record in manifest). Head top y = 1088 - height |
| Headroom/side margin | >= 24 px of transparent margin on all sides incl. coat flare, braids and gold accents |
| Views | `front` (facing camera/down), `side` (facing **right**), `back` (facing away/up). `left` = mirrored `side` **only if** the owner/artist confirms the asymmetric details (hero pouch/strap/earring side, Imani earrings/pouch/skirt) survive mirroring; otherwise supply `left_*` frames |
| Idle | 2 frames per view (subtle breathing/hair/cloth), 4 fps loop |
| Walk | **6 frames per view** (>= the 5 required by `tools/validate_approved_art.py`): contact A, down, passing, contact B, down, passing; 8-10 fps loop. Arms counter-swing, weight shift, coat/braids/skirt follow-through; no sliding feet |
| Turning | optional 3-frame transitions `turn_front_to_side` and `turn_side_to_back` (+ mirrored) so direction changes do not pop; at minimum an acceptable snap with matched pose |
| Interaction extras (Hero, Imani) | `talk_idle` (2 frames, per view optional), `react_surprised` (1), `hurt` (1) — optional for the checkpoint, required before any episode use |
| Files | `assets/approved_anime/characters/<id>/frames/{front,side,back}_{idle_00..01,walk_00..05}.png`, `manifest.json` (shape accepted by `tools/build_spriteframes.gd`: `animations.<name>.{fps,loop,flagged,frames_out}`), `anchor.json` (`canvas`, `anchor_x`, `baseline_y`, `height_px`), `portrait.png`, `PROVENANCE.md` |
| Total per hero/NPC-A | 3 views x (2 idle + 6 walk) = 24 frames (+ optional left 8, turns 12) |

### Portraits and expressions
- `portrait.png`: transparent bust, **1024 x 1024** (>= 512 required), head-and-shoulders, same lighting as the sheet, no text/borders. Face must stay crisp at 172 px in the dialogue box.
- Expression set (transparent, 1024 x 1024 each): Hero — neutral, determined, smirk, surprised, hurt. Imani — neutral, smile, smirk, wink, thoughtful (matching the five heads in file 04). Files `portrait_<expression>.png`.

## 4. NPC roster (art needed; names not final)
Tier A = named speaking NPC, full 3-view idle+walk like the hero. Tier B = background character, 3-view idle + 4-6 walk frames at 560 px tall class. All predominantly Black, individual silhouettes/hairstyles/skin tones, same rendering quality as the hero (no lower-quality crowd art).
| ID | Role | Tier | Source in references | Status |
|---|---|---|---|---|
| npc_a1_tram_technician | Tram repair kiosk technician (bearded, cap + blue goggles, tool vest) | A | files 03/05 | MISSING (name TBD by owner) |
| npc_a2_courier | White tactical jacket + backpack courier | A | files 03/05 | MISSING |
| npc_a3_grey_hoodie | Grey-hoodie pedestrian | A | file 03 | MISSING |
| npc_b01..b10 | Crowd: umbrella walkers, backpack student, vendor, couple, security guard, elder, teen with headphones, etc. | B | painted crowd in 03/05 | MISSING (variety list in ART_BRIEFS) |
| cast_portrait_c1..c4 | Four unlabelled busts in file 02 | — | file 02 | **UNASSIGNED — do not produce until owner approves identities** |
Previous demo NPC names/designs (Kofi, Zuri, Okoye etc.) are not approved and are not carried over.

## 5. Neon District environment (premium 2.5D)
Engine projection that the art must match (from `scripts/demo/stage25.gd`, current demo): 1280x720 view, world width 4800 px (9600 at 2x), walkable plane from y = 392 (back, building base) to y = 656 (front) in 720p space, actor scale 0.74 (back) to 1.0 (front), parallax: sky fixed, far skyline 0.22, mid/facade 1.0, foreground 1.4. **Decision needed from owner:** file 05 is drawn in a low-angle, two-point street perspective; the engine uses a frontal depth plane. Either (a) layers are authored for the engine's frontal-plane projection with the same mood/lighting, or (b) a camera/perspective change to the engine is approved as a separate task. Layers below assume (a).

| Layer file (`assets/approved_anime/environments/neon_district/`) | Canvas @2x | Parallax | Content / notes |
|---|---|---|---|
| `sky.png` | 2560 x 1440, opaque | 0 (fixed) | rainy violet/magenta storm sky, cloud banks, distant halo glow; no buildings, no HUD |
| `far_skyline.png` | 4608 x 900, RGBA (alpha above skyline) | 0.22 | layered towers, observation spire, elevated-tram silhouette, haze; seamless over its width |
| `mid_buildings.png` | 9600 x 760 in <= 3 tiles of 3200 (`mid_buildings_0..2.png`), RGBA | 1.0 | varied architecture with real structural variation: balconies, scaffolds, rooftop gardens, shopfronts, signage mounts; no repeated window grids; bottom edge = building base line at y = 784 (2x) |
| `storefront_details.png` (optional split) | same tiling | 1.0 | doors, awnings, lit interiors if split from mid_buildings |
| `street_floor.png` | 9600 x 656 in <= 3 tiles, RGBA/opaque | 1.0 | wet pavement, puddles, kerb, road with lane markings, crosswalks, painted reflections of neon; ground plane rows widen toward the camera; **no characters, no HUD** |
| `reflection_plate.png` | 9600 x 400 | 1.0 | separate soft neon reflection streaks for blending over the floor |
| `foreground.png` | 9600 x 1440 in tiles, RGBA mostly transparent | 1.4 | out-of-focus poles, hanging signs/cables, umbrellas, plants, rain-streaked glass; sparse so gameplay stays readable |
| `occluders/*.png` | per prop | 1.0 | props that hide the player when walked behind (lamp post, pole, planter, awning edge) as separate transparent sprites with anchors |
| `props/*.png` | per prop | 1.0 | Tram Repair kiosk (readable sign + glowing wrench panel), Clinic 24 sign tower, skybridge-09 sign, MIDDLE HOUSE storefront, lamp posts (2 variants), hover car (side + 3/4), elevated tram (side, animated 4-frame light cycle optional), vending machine, bench, planter, crates, umbrellas — each transparent with foot/base anchor |
| `light_masks/*.png` | greyscale/RGBA | — | neon glow cut-outs for additive lighting (sign glows, lamp pools, window light) |
| `collision_mask.png` | 4800 x 360 at 1x, flat colours | — | walkable = white, blocked = black, interactive spots = distinct colours; drives collision authoring, never shown |
Rain streaks, ripples and particle glows may stay engine FX; the painted layers must already feel wet and lit. Environment must read as a cinematic anime city, with distinctive neighbourhood areas (market row, tram plaza, clinic block, hidden alley) — see ART_BRIEFS.

## 6. Priority order (what ChatGPT must create first)
1. **Hero clean orthographic turnaround** (front/side-right/back, flat solid key-colour background, no text/borders, 2x size) — the master for all frames.
2. **Hero layered body-part sheet** (rig parts) or six-pose walk key sheet per direction — chosen after the owner approves the approach (rigging is recommended because AI per-frame consistency is unreliable).
3. **Imani clean orthographic turnaround + layered parts**, same spec.
4. **Hero and Imani transparent portraits + expression sets.**
5. **Neon District layers** (sky, far skyline, mid buildings, street floor, foreground) without HUD, then props/occluders/light masks/collision mask.
6. Tier-A NPCs, then Tier-B crowd.
