# Episode 1 Neon District: environment plate requirements (approval gate)
Owner-approved direction: Concepts A and B with corrections. This is the production contract for ChatGPT / the artist. Nothing is integrated until genuine independent plates pass `tools/validate_env_plates.py` and the owner approves the result. Do not stretch the flat concept into the game; do not cut a flat image into "layers".

## Look (owner corrections applied)
Bright electric blue and violet primary; restrained magenta and warm gold accents. Aether storm: stormy lit sky, wet pavement with controlled realistic reflections, mist banks, rain (rain streaks are drawn by the game, do not paint them in). The tram is stalled and dark ("service halted"): no moving or crowded lit tram. Detailed original anime architecture, elevated tracks, illuminated storefronts (RAMEN stays), layered depth. Sparse, low-contrast background people only (silhouettes), or none. No baked-in Hero, Mira, other NPCs, HUD, text that is a gameplay marker, arrows, glows marking interactions, or logos. No scenery that implies new collision (benches, bollards, fences, planters in the walking lane); the only solid object in the game is Mira. Original art, no real brands or copied franchise elements. Echo V2 is not drawn anywhere in the environment.

## Delivery
PNG, RGBA (sky may be RGB), sRGB, delivered at 1.5x the logical size (logical canvas 1280x720; 1.5x = 1920x1080 reference). Each file is its own independent generation or painting, plus `<name>.provenance.json` = `{"tool": "...", "method": "native_generation|painted|...", "independent_plate": true, "date": "..."}`. Folder: `assets/environment/neon_district/`.

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
Objective panel (24, 20, 440 x 82); EXIT / SKIP (1106, 22, 150 x 48); touch stick (36, 520, 180 x 180); ACT button (1110, 586, 104 x 104). Interaction prompt band (0, 250, 1280 x 70): luminance <= 0.55. The dialogue box (40, 468, 1200 x 208) is opaque; the street lifts 125 px while it is open. Walking lane (hero feet) y 515-585, Mira's feet y 548: keep the lane readable, no strong vertical stripes or objects that look like obstacles. Code-drawn props, so the street plate stays calm (mean luminance <= 0.30) in these world rectangles: relay (1500, 380, 120 x 125), mural (1790, 360, 140 x 100), breach (2050, 330, 300 x 160).

## Validation (automatic: `python3 tools/validate_env_plates.py`; exit 0 pass, 1 fail, 2 = no plates)
Exact sizes; sky fully opaque; no empty left/right edges; no #00FF00 matte; provenance file per plate with `independent_plate: true` and a method other than splitting a flat image; composite check at cameras 0 / 400 / 800 / 1220 for HUD-safe luminance and detail; palette share on lit pixels (blue-violet >= 55%, magenta <= 22%, warm gold <= 12%, red/orange <= 8%); street-plate prop slots calm; decoded texture total <= 64 MB (the design set is about 45 MB; the real device budget is still unmeasured).
Manual checklist (owner / me by eye, not automatable): no baked characters, HUD, markers or collision-implying objects; storm mood and stalled tram; sparse crowd; consistent light direction; seamless across the whole width; original art; same game as the home screen.

## Integration (only after approval)
Plates replace the procedural sky/far/mid/near/ground layers in Explore at the factors above; code keeps drawing the relay, mural, breach, board, lamp posts, rain and dynamic fog; the stalled tram prop replaces the procedural tram. Collision, objectives, NPCs, save/resume, combat and rewards are not touched. Frame time and memory are re-measured before and after (software GL here; a real device is still needed).
