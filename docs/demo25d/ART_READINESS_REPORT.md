# Art readiness report (Claude, 2026-10-11) — playable integration STOPPED

Branch `chatgpt/approved-anime-art-integration`, base commit `4fb8411`.

## Check run
`python3 tools/validate_approved_art.py --root .` -> **BLOCKED**:
- hero: missing `assets/approved_anime/characters/hero/manifest.json`
- imani: missing `assets/approved_anime/characters/imani/manifest.json`
- environment: missing `far_skyline.png`, `mid_buildings.png`, `street_floor.png`, `foreground.png`

`assets/approved_anime/` does not exist in the repository. The only Imani/hero-like files present are the rejected procedural strips in `assets/demo25d/chars/` (mechanical-test fallback only) and the older `assets/_incoming/hero/` sheet.

## Verdict
No production Hero or Imani animation frames, no transparent portraits, and no separated Neon District layers are available. The approved concept montages and HUD mockup live only in the ChatGPT conversation and are not in the repo; even if committed they are references, not sprites/layers. I created **no** substitute procedural characters or backgrounds, built no checkpoint scene, and spent no credits.

## Exactly what is needed (per the contract in `CHATGPT_APPROVED_ART_INTEGRATION.md`)
1. Hero and Imani: transparent RGBA frames, 3 views (front, side-right, back) x (idle + >=5 walk frames), identical size/anchor, >=288x576 per frame, plus a >=512x512 transparent portrait each, and `manifest.json` in the `build_spriteframes.gd` shape, under `assets/approved_anime/characters/<name>/`.
2. Neon District: `far_skyline.png`, `mid_buildings.png`, `street_floor.png`, `foreground.png` (occlusion layer, no HUD) under `assets/approved_anime/environments/neon_district/`, plus provenance notes. Tram repair kiosk and Clinic 24 signage readable.
3. Frames should be artist-corrected or from a layered rig; AI views are not guaranteed consistent. Paid generation needs owner approval.

## Once the assets are committed (next steps, not started)
Run the checker (must pass) -> inspect at 100% and gameplay scale -> add an isolated `visual_checkpoint` scene behind a dev flag reusing `Stage25`/`SpriteActor` (frame size and view mapping are constants/one loader) with NPC dialogue, depth, collisions, mobile controls -> validate at 1280x720, 844x390, 667x375 with screenshots, movement evidence and real test results -> stop for owner review. Existing episodes, saves and combat are untouched.

## Not run
No Godot tests, screenshots or browser sessions were run in this step, since there is nothing new to validate; earlier results on `demo/neon-district-2.5d` still stand for the engine only.
