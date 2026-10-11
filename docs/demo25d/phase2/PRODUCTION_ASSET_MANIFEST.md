# Phase 2 — Production asset manifest (SPECIFICATION ONLY)

Branch `chatgpt/approved-anime-art-integration`. Revision 2 (applies the Phase 2 review corrections; base `91eea11`). Official visual direction = the five images in `assets/approved_anime/reference/` (files 01-05). **No production-ready art exists yet.** Every asset below has status `MISSING` until real transparent artwork is committed and passes `docs/demo25d/phase2/ARTWORK_VALIDATION_CHECKLIST.md` plus owner approval. Nothing here changes gameplay or runs Godot. Machine-readable list: `asset_manifest.json`.

## Locked decisions (owner/ChatGPT Phase 2 review)
1. Keep the existing **frontal 2.5D depth projection** for Phase 2. 2. Preserve the cinematic Neon District look of reference 05 (lighting, signage, wet street, tram, density). 3. **Layered skeletal-style 2D animation** for Hero and Imani. 4. **Four genuine directional views — front, right, back, left. Asymmetric characters are never mirrored.** 5. Preserve approved faces, hairstyles, skin tones, accessories and costumes. 6. The four unidentified portraits (file 02) stay unassigned. 7. Season 1 remains exactly 10 episodes.
**Hero design (owner-confirmed):** the four-view Hero candidate in `assets/approved_anime/preview/hero_turnaround_candidate/` is the official Hero design; **reference 01 is superseded for the Hero only** (see `HERO_DESIGN_LOCK_AND_PRODUCTION_SPEC.md`). **Next visual deliverable:** the Hero's clean native-resolution four-view turnaround (front, right, back, left) based on that approved design. It needs the owner's visual approval **before any rigging begins**.
All asset statuses below stay `MISSING` until genuine transparent artwork exists, passes `tools/validate_approved_art.py` plus the manual checklist, and is approved. Passing the validator proves structure only.

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
| Source scale (characters) | **master art 576 x 1152 px** (standing figure 1000 px) = 4x the intended on-screen size: target figure height on screen is ~250 px at z=1 and ~185 px at z=0 in 1280x720 (matches the current prototype's ~250 px figure). Display scale of the master = 0.25 x depth scale. A runtime package may be downsampled **2:1 to 288 x 576** (figure 500 px, displayed at 0.5 x depth scale = 1:1 physical pixels on 2x-DPR phones); downsample only after inspecting at gameplay scale, and keep the 576 x 1152 masters. Environment layers are authored at 2x (displayed at 0.5) |
| Colour | keep palette from references; neutral colour of skin tones preserved across all frames (no per-frame colour drift) |
| Naming | lower snake_case, zero-padded frame index, e.g. `front_walk_03.png` |
| Provenance | `PROVENANCE.md` per character/environment: tool, date, prompts, seeds, manual edits, who approved |

## 2. Character identity locks (from the references; do not redesign)
**Main Hero** (superseded identity text from file 01 — the authoritative Hero identity is now `HERO_DESIGN_LOCK_AND_PRODUCTION_SPEC.md`): young Black man, dark-brown skin, short black twists/locs with gold cuff accents, amber eyes, gold hoop earring on one ear; black hooded long coat with gold trim and glowing gold hardware, gold-lined hood interior, diamond emblem on sleeve and back, cross-body strap with gold pouch, black short-sleeve layer with armoured gold-trimmed forearm bracers/fingerless gloves, black cargo trousers with thigh strap and pouch, chunky black-and-gold boots. Palette: near-black, gold (#F2B72A range), grey accents. Build: lean athletic, ~7.5 heads tall.
**Imani** (file 04, "Neon District resident, tram repair kiosk"): Black young woman, warm medium-brown skin, very long black box braids with violet tints and gold cuffs, brown eyes, large gold hoop earrings, gold choker with pendant; purple off-shoulder crop top with black under-layer, purple arm bands, black fingerless gloves, black wide cargo trousers with layered purple asymmetric skirt panels and diamond motifs, gold belt/thigh strap, black-and-gold boots. Palette: violet, black, gold. Slightly shorter than the hero (~0.94x). Story role/dialogue preserved (meet Imani at the tram repair kiosk); the demo's earlier tram-mechanic costume is superseded by this design.
Consistency risks to track: hero back-view hair currently reads shorter than the front; keep hair length, gold cuff placement and emblem position identical in every view.

## 2b. Animation method (locked)
Hero and Imani are produced as **layered 2D part sets** (head with front/back hair split, torso, coat/skirt panels, upper arm, forearm+bracer, hand, pelvis, thigh, shin, boot, pouch/strap, braid/loc/hair-cuff secondary chains) for each of the four views, then animated skeletally (offline in a 2D rig tool, or in engine) and **exported to the frame contract below** so validation and the engine see ordinary frames. Joints are painted under overlaps; secondary motion (coat, braids, skirt) follows with delay. No stretching a single still to fake a walk. Rigging starts only after the clean four-view turnaround of that character is approved.

## 3. Character frame layout (all animated characters)
| Item | Spec |
|---|---|
| Frame canvas | 576 x 1152 master, transparent, identical for every frame of a character (validator-enforced) |
| Foot anchor | horizontal centre x = 288; ground contact baseline y = 1088 (64 px below for soft shadow/reflection headroom). The lowest sole pixel of the planted foot sits on y = 1088 in every frame; the character's *pelvis centre* stays on x = 288 +/- 6 px except for natural walk offset |
| Standing height (head top to sole) | Hero 1000 px; Imani 940 px; other NPCs 860-1020 px per role (record in manifest). Head top y = 1088 - height |
| Headroom/side margin | >= 24 px of transparent margin on all sides incl. coat flare, braids and gold accents |
| Views | **four genuine views**: `front` (facing camera/down), `right`, `back` (facing away/up), `left`. `left` is drawn/rigged separately — **never a mirror of `right`** (hero strap/pouch/earring side and Imani earrings/pouch/skirt are asymmetric). The validator rejects left frames that are exact mirrors of right frames |
| Idle | exactly 2 frames per view (subtle breathing/hair/cloth), 4 fps loop |
| Walk | exactly **6 frames per view** (enforced by `tools/validate_approved_art.py`): contact A, down, passing, contact B, down, passing; 8-10 fps loop. Arms counter-swing, weight shift, coat/braids/skirt follow-through; no sliding feet |
| Turning | optional 3-frame transitions `turn_front_to_side` and `turn_side_to_back` (+ mirrored) so direction changes do not pop; at minimum an acceptable snap with matched pose |
| Interaction extras (Hero, Imani) | `talk_idle` (2 frames, per view optional), `react_surprised` (1), `hurt` (1) — optional for the checkpoint, required before any episode use |
| Files | `assets/approved_anime/characters/<id>/frames/{front,right,back,left}_{idle_00..01,walk_00..05}.png` (exact names; the validator enforces them), `manifest.json` (shape accepted by `tools/build_spriteframes.gd`: `animations.<name>.{fps,loop,flagged,frames_out}`), `anchor.json` (`canvas`, `anchor_x`, `baseline_y`, `height_px`), `portrait.png`, `PROVENANCE.md` |
| Total per hero/Imani/NPC-A | 4 views x (2 idle + 6 walk) = **32 frames** (+ optional turn transitions) |

### Portraits and expressions
- `portrait.png`: transparent bust, **1024 x 1024** (>= 512 required), head-and-shoulders, same lighting as the sheet, no text/borders. Face must stay crisp at 172 px in the dialogue box.
- Expression set (transparent, 1024 x 1024 each): Hero — neutral, determined, smirk, surprised, hurt. Imani — neutral, smile, smirk, wink, thoughtful (matching the five heads in file 04). Files `portrait_<expression>.png`.

## 4. NPC roster (art needed; names not final)
Tier A = named speaking NPC, full four-view idle+walk like the hero (rigged). Tier B = background character, same quality, may use fewer frames (decision deferred; not validated by the current tool). All predominantly Black, individual silhouettes/hairstyles/skin tones, same rendering quality as the hero (no lower-quality crowd art).
| ID | Role | Tier | Source in references | Status |
|---|---|---|---|---|
| npc_a1_tram_technician | Tram repair kiosk technician (bearded, cap + blue goggles, tool vest) | A | files 03/05 | MISSING (name TBD by owner) |
| npc_a2_courier | White tactical jacket + backpack courier | A | files 03/05 | MISSING |
| npc_a3_grey_hoodie | Grey-hoodie pedestrian | A | file 03 | MISSING |
| npc_b01..b10 | Crowd: umbrella walkers, backpack student, vendor, couple, security guard, elder, teen with headphones, etc. | B | painted crowd in 03/05 | MISSING (variety list in ART_BRIEFS) |
| cast_portrait_c1..c4 | Four unlabelled busts in file 02 | — | file 02 | **UNASSIGNED — do not produce until owner approves identities** |
Previous demo NPC names/designs (Kofi, Zuri, Okoye etc.) are not approved and are not carried over.

## 5. Neon District environment (premium 2.5D) — coordinates, origins and parallax
**Projection (locked):** the current frontal depth plane of `scripts/demo/stage25.gd`. Art is authored at **2x**; engine coordinates below are **1x** px (divide art pixels by 2; the engine will draw layer sprites at scale 0.5). View = 1280x720; world width W = 4800 (9600 art px). Camera `cam_c` follows the player (x clamped to [640/zoom, W-640/zoom]); zoom is 1.00-1.05 (deeper = closer) and cam y shifts +/-17 px with depth.

| Quantity | Value (1x engine px) |
|---|---|
| World x | 0..4800; art x = 2 * world x |
| Building base line (`Y_BACK`) | y = 392 — the line where buildings meet the walkable plane |
| Walkable plane | y = 392 (back, depth z=0) to y = 656 (front, z=1), `DEPTH` = 264 z-pixels; screen y = 392 + z*264 |
| Actor/prop scale by depth | 0.74 (z=0) to 1.00 (z=1), linear |
| Gutter/kerb below the plane | y = 656..752 (overscan so camera zoom/tilt never exposes empty pixels) |
| Camera overscan | art must extend 32 px (1x) beyond the 720 px view at top/bottom where noted below |

**Layer origins and parallax** (origin = where the layer image's top-left pixel sits, in that layer's own coordinate space; `cam.x`, `cam.y` = camera centre):
| Layer (files in `assets/approved_anime/environments/neon_district/`) | Art canvas @2x | Origin (1x) | Parallax / layer position | Content rules |
|---|---|---|---|---|
| `sky.png` (opaque) | 2560 x 1440 | screen (0,0) | fixed to screen, no parallax | storm sky only; no buildings, no HUD |
| `far_skyline.png` (RGBA) | 4640 x 900 | (-130, 0) in far-layer space | far layer position = (-(cam.x-640)*0.22, -(cam.y-360)*0.10); width = 1280 + 3520*0.22 + 260 = 2320 px (1x) | towers/haze/elevated tram silhouette; opaque down to the bottom row (y=450) so nothing shows through behind the mid layer |
| `mid_buildings_0.png .. _2.png` (RGBA, **exactly 3 tiles**) | 3200 x 784 each | tile i at world (1600*i, 0); tile spans y 0..392 | parallax 1.0 (moves with the world) | street-level and upper facades; **bottom row of each tile = building base line y=392**; tiles seamless at x=1600*i; no HUD/characters; real structural variation, no repeating window grids |
| `street_floor_0.png .. _2.png` (opaque, **exactly 3 tiles**) | 3200 x 720 each | tile i at world (1600*i, 392) | parallax 1.0 | **top row = y=392 base line** (must meet mid_buildings bottom row exactly); rows 0..528 (1x 0..264) are the walkable plane with perspective rows widening toward the bottom; rows 528..720 are kerb/gutter/overscan; seamless at tile joins |
| `foreground_0.png .. _3.png` (RGBA, **exactly 4 tiles**) | 3200 x 1440 each | tile i at fore-layer (1600*i, 0) | fore layer position = (-(cam.x-640)*1.4, -(cam.y-360)*0.4); width covered = 1280 + 3520*1.4 = 6208 px (1x) <= 6400 | sparse blurred poles/signs/cables/umbrellas; centre of screen kept open; mostly transparent |
| `reflection_plate_{0..2}.png` (optional, RGBA) | 3200 x 400 | tile i at world (1600*i, 392) | 1.0 | soft neon streaks blended over the floor |
| `props/<name>.png`, `occluders/<name>.png` | per prop | **origin = ground-contact point** (`anchor.json` gives px offset) | placed at world (wx, 392 + z*264), scaled 0.5 x depth scale; y-sorted with actors | transparent; occluders hide the player when the player is behind them |
| `light_masks/<name>.png` | per mask | glow centre | additive, parallax 1.0 | greyscale/RGBA glows |
| `collision_mask.png` | 4800 x 264 (1x) | world (0, z-pixel 0) | not rendered | white = walkable, black = blocked, coloured = interactive; x = world x, y = z*264 |

**Ground alignment rules:** (1) mid_buildings bottom row and street_floor top row share y=392 and must visually continue (no gap/overlap seam); (2) prop and actor ground-contact points lie inside the floor art at the y their z maps to; (3) collision_mask rows map 1:1 to the walkable-plane rows; (4) neon reflections on the floor should sit under their signs (same x).
**Perspective (resolved):** frontal depth plane for Phase 2; layers keep the *look* of reference 05 (density, neon, wet reflections, tram, signage). Any change of engine camera is a separate approved task.

## 6. Priority order (what ChatGPT must create first)
1. **Hero clean four-view turnaround** (front, right, back, left; strictly from reference 01; flat solid key-colour background, no text/borders, 2x size) — the master for all frames. **Needs visual approval before rigging.**
2. **Hero layered part sheets** (rig parts, four views) — only after step 1 is approved.
3. **Imani clean four-view turnaround**, then her layered parts, same rules.
4. **Hero and Imani transparent portraits + expression sets.**
5. **Neon District layers** (sky, far skyline, mid buildings, street floor, foreground) without HUD, then props/occluders/light masks/collision mask.
6. Tier-A NPCs, then Tier-B crowd.
