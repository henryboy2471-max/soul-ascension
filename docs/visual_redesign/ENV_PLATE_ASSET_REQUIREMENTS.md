# Episode 1 Neon District: environment plate requirements (approval gate)
Owner-approved direction: Concepts A and B with corrections. This is the production contract for ChatGPT / the artist. Nothing is integrated until genuine independent plates pass `tools/validate_env_plates.py` and the owner approves the result. Do not stretch the flat concept into the game; do not cut a flat image into "layers".

## Look (owner corrections applied)
Bright electric blue and violet primary; restrained magenta and warm gold accents. Aether storm: stormy lit sky, wet pavement with controlled realistic reflections, mist banks, rain (rain streaks are drawn by the game, do not paint them in). The tram is stalled and dark ("service halted"): no moving or crowded lit tram. Detailed original anime architecture, elevated tracks, illuminated storefronts (RAMEN stays), layered depth. Sparse, low-contrast background people only (silhouettes), or none. No baked-in Hero, Mira, other NPCs, HUD, text that is a gameplay marker, arrows, glows marking interactions, or logos. No scenery that implies new collision (benches, bollards, fences, planters in the walking lane); the only solid object in the game is Mira. Original art, no real brands or copied franchise elements. Echo V2 is not drawn anywhere in the environment.

## Delivery
PNG, RGBA (sky may be RGB), sRGB, delivered at 1.5x the logical size (logical canvas 1280x720; 1.5x = 1920x1080 reference). Each file is its own independent generation or painting, plus `<name>.provenance.json` (see "Artwork policy" below for the exact fields). Folder: `assets/environment/neon_district/`.

| File | Scroll factor | Logical size (w x h) | Screen y origin | Delivered px (exact) | Alpha | Content |
|---|---|---|---|---|---|---|
| plate_sky.png | 0.03 | 1500 x 520 | 0 | 2250 x 780 | opaque | storm sky, cloud banks, distant glow, far arcology hints |
| plate_far.png | 0.12 | 1700 x 480 | 40 | 2550 x 720 | yes | far skyline, hazy, soft light |
| plate_mid.png | 0.30 | 1800 x 410 | 110 | 2700 x 615 | yes | mid buildings, signage glows (no readable text needed) |
| plate_near.png | 0.60 | 2300 x 460 | 60 | 3450 x 690 | yes | near structures: elevated tracks, upper facades, overhead cables |
| plate_street.png | 1.00 (world-aligned) | 2500 x 420 | 300 | 3750 x 630 | yes | storefronts, station canopy, wet pavement, reflections, mist |
| plate_foreground.png | 1.20 | 2800 x 140 | 580 | 4200 x 210 | yes | sparse, low-contrast foreground: puddle rim light, soft mist, bokeh; nothing in the walking lane |
| prop_tram_stalled.png | world prop at (635, 340) | 700 x 156 | n/a | 1050 x 234 | yes | the stalled tram, dark windows, no text (the game draws OUT OF SERVICE) |

Coverage rule: a plate with scroll factor f must be at least 1280 + f x 1220 logical px wide (sky 1317, far 1426, mid 1646, near 2012, street 2500, foreground 2744); the sizes above include margin. Plates are not tiled, but their left and right edges must be filled (no empty columns).

## Scene coverage (world x, 0..2500; camera x = clamp(hero x - 640, 0, 1220))
| Zone | Hero x | Camera x | `plate_street` (world-aligned) must show |
|---|---|---|---|
| 1 Start + ramen street | 80-560 | 0 | RAMEN storefront (lit), alley mouth, wet pavement, shop windows |
| 2 Mira + stalled tram | 400-1330 | 0-690 | tram platform and station canopy behind the tram prop (x 640-1330), dim "SERVICE HALTED" board area at x 994-1106 (the board itself is drawn by the game) |
| 3 Relay | 1330-1760 | 690-1120 | service/equipment frontage, overhead cable run, calm wall behind the relay console |
| 4 Mural | 1760-2060 | 1120-1220 | blank low-detail wall panel at x 1790-1930, y 360-460 (the mural is drawn by the game) |
| 5 Breach + world end | 2060-2500 | 1220 | open dark plaza around x 2050-2350 for the breach portal; closing storefront near x 2400 |
Far/mid/near plates must read as one continuous city across their whole width (no repeated copy-paste blocks, no seams). Zones 3-5 share almost the same camera, so the last stretch of the near/mid/far plates is seen in all three.

## HUD-safe areas (logical screen px; keep mean luminance <= 0.42 and low detail)
Objective panel (24, 20, 440 x 82); EXIT / SKIP (1106, 22, 150 x 48); touch stick (36, 520, 180 x 180); ACT button (1110, 586, 104 x 104). Interaction prompt band (0, 250, 1280 x 70): mean luminance <= 0.55 (brightness only; the prompt pill has its own opaque panel, so background detail there is not limited). The dialogue box (40, 468, 1200 x 208) is opaque; the street lifts 125 px while it is open. Walking lane (hero feet) y 515-585, Mira's feet y 548: keep the lane readable, no strong vertical stripes or objects that look like obstacles. Code-drawn props, so the street plate stays calm (mean luminance <= 0.30) in these world rectangles: relay (1500, 380, 120 x 125), mural (1790, 360, 140 x 100), breach (2050, 330, 300 x 160).

## Validation (automatic: `python3 tools/validate_env_plates.py`; exit 0 pass, 1 fail, 2 = no plates)
Exact sizes; sky fully opaque; no empty left/right edges and no transparent gutters (far, mid, near, street); no #00FF00 matte; provenance per plate enforcing the Artwork policy above (independent, native or the approved sky resample, no upscaling, no stretching); composite check at cameras 0 / 400 / 800 / 1220 for HUD-safe luminance and detail; palette share on lit pixels (blue-violet >= 55%, magenta <= 22%, warm gold <= 12%, red/orange <= 8%); street-plate prop slots calm; decoded texture total <= 64 MB including mipmaps (see Texture budget).
Manual checklist (owner / me by eye, not automatable): no baked characters, HUD, markers or collision-implying objects; storm mood and stalled tram; sparse crowd; consistent light direction; seamless across the whole width; original art; same game as the home screen.

## Artwork policy (owner-approved)
1. **Native resolution is the rule.** Every plate must be delivered at its exact size from an independent generation or painting; downscaling a larger native source is fine. Provenance (`<name>.provenance.json`) must contain `tool`, `method`, `independent_plate: true`, `resolution: "native"` and `original_dimensions: [w, h]` of the generated source, and the source may not be smaller than the delivered plate (that would be upscaling).
2. **Sky exception.** Only the independent Aether Storm Sky (`plate_sky.png`, a sky-only image, no skyline) may be resampled up, by at most 10%, with uniform scaling (a crop of up to 3% is tolerated). Its provenance must then say `resolution: "resampled_up"` and record `resample_factor` (the actual factor), `original_dimensions`, `tool`, `source` (the source file or generation) and `owner_approved_resample: true`. Resampled art is never called native: the validator prints "RESAMPLED ... NOT native resolution".
3. **Skyline is strict.** `plate_far.png` is 2550x720 RGBA, covers the full width (no transparent gutters wider than 4 px at either edge), is never stretched horizontally and is never upscaled; no other plate may be resampled up either.
4. **Not production:** anything whose provenance status says REVIEW_ONLY / REFERENCE / ASSISTED / NOT_PRODUCTION, or `independent_plate: false`, or that was cut out of a flat concept, fails validation. Reference images and assisted previews stay in `reference/` and are ignored by the validator.

Provenance example (resampled sky): `{"tool": "OpenAI image generator", "method": "native_generation", "independent_plate": true, "resolution": "resampled_up", "resample_factor": 1.0568, "original_dimensions": [2129, 739], "source": "a_wide_cinematic_ultra_detailed_sci_fi_fantasy_s.png", "owner_approved_resample": true}`. Example (native skyline): `{"tool": "...", "method": "native_generation", "independent_plate": true, "resolution": "native", "original_dimensions": [2550, 720]}`.

## Texture budget (owner-approved, provisional)
Ceiling: 64 MB of decoded environment texture memory for the initial artwork integration and testing. It is a provisional ceiling, not a guaranteed mobile-performance target. Accounting counts full mipmaps (x 4/3) because the game samples these textures with mipmaps.
- Standard tier (the contract above, 1.5x): 42.4 MB base level, 56.6 MB with mipmaps. Headroom under the ceiling: 7.4 MB. No quality is given up now.
- Lite tier (prepared lower-memory option, 1.0x): the same seven files, same scroll factors, HUD-safe regions and validation rules, delivered at the logical sizes (sky 1500x520, far 1700x480, mid 1800x410, near 2300x460, street 2500x420, foreground 2800x140, tram 700x156): 18.9 MB base, 25.1 MB with mipmaps. Validate with `python3 tools/validate_env_plates.py --scale 1.0`.
- The lite tier is produced by downscaling the genuine standard plates (no new or procedural art), and is used only if real-device testing shows memory or frame problems. Switching tiers is an owner decision made on device evidence; no device exists in this environment, so nothing about phone performance is claimed.

## Integration (only after approval)
Plates replace the procedural sky/far/mid/near/ground layers in Explore at the factors above; code keeps drawing the relay, mural, breach, board, lamp posts, rain and dynamic fog; the stalled tram prop replaces the procedural tram. Collision, objectives, NPCs, save/resume, combat and rewards are not touched. Frame time and memory are re-measured before and after (software GL here; a real device is still needed).

## Assembled plates (native source panels)
The far, mid, near, street and foreground plates and the tram are assembled by `tools/assemble_env_plates.py` from the 15 native source panels in `reference/source_panels_v2/` (verified against its manifest by SHA-256). Only crop, uniform downscale (never up), a seam crossfade and the documented edits below are used; no plate is described as one generation. Provenance uses `resolution: "assembled_native"` with `components` (file, sha256, original_dimensions, scale, crop, position), `mosaic_dimensions` and `final_crop_px` (at most 3%). The validator checks every component hash and refuses any scale above 1.0.
Documented edits (all recorded per component): street_center/street_right alpha made opaque with a top feather; street_left alpha cleaned (>=0.94 -> 1); a local exposure burn on the street_right wall to keep the mural prop slot calm; depth-of-field softening of the near street floor (sigma 10 px from row 300) to keep the touch-stick zone calm; a soft top edge on the finished foreground strip; per-seam trims and crossfade widths picked by a search that minimises the visible luminance step across each stitch (`tools/check_camera_seams.py` reports it and sweeps the camera for pops). The warm street_left palette is unchanged. The tram floats about 106 logical px above the street's ground; the painted track it needs is specified in `docs/visual_redesign/environment_review/tram_track_request/`.

Tram track: `plate_street` includes the authored RGBA insert `reference/tram_track_source/tram_track_insert_1230x190.png` (sha256 verified, from the unchanged 2021x778 native source, crop then uniform downscale 0.66236) alpha-composited at (862, 278) after the floor softening, so it stays sharp; the tram prop is drawn after the street layer. Edits recorded in provenance: placement moved from (862, 280) to (862, 278) so the rail top (rows 291-292) meets the wheel bottoms (row 291); a 72 px smoothstep alpha fade on the girder's right end (no terminal pier). `tools/render_track_review.py` regenerates the review images. Awaits Henry's visual approval.
