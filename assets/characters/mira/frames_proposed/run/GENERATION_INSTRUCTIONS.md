# Final-art instructions: mira_run (mira run)
Status: NOT STARTED. These instructions and the reference packet are preparation only; nothing is wired into the game and the pose sketches are guides, never final art.

## Deliverable
- 8 transparent PNG frames `run_00.png` .. `run_07.png` in this folder, canvas **258x153**, character drawn facing right, loops seamlessly, plays at **12 fps** (0.67 s per cycle) at ground speed **300 px/s**.
- Figure height about 139 px; the planted sole sits on the bottom row; the pelvis x is the canvas centre (x = 129) in every frame.
- Screen scale 1.2157: the cycle must keep the current on-screen size.

## Foot rule (the whole point)
A planted foot moves BACK **20.56 px per frame** relative to the pelvis; one step covers 82.26 px. Foot x is measured from the pelvis (+ = forward); lift is height above the ground. Leg B is leg A shifted by four frames.
| frame | leg A foot x | leg A lift | leg B foot x | pelvis height vs mean |
|---|---|---|---|---|
| 1 | +20.6 | 0.0 | -28.8 | +0.0 |
| 2 | +0.0 | 0.0 | +0.0 | -4.2 |
| 3 | -20.6 | 4.7 | +28.8 | +0.0 |
| 4 | -47.3 | 27.2 | +39.1 | +4.9 |
| 5 | -28.8 | 38.9 | +20.6 | +0.0 |
| 6 | +0.0 | 29.2 | +0.0 | -4.2 |
| 7 | +28.8 | 11.7 | -20.6 | +0.0 |
| 8 | +39.1 | 3.1 | -47.3 | +4.9 |
Run: contact on frames 1 and 5, mid-stance on 2 and 6, both feet airborne on 3-4 and 7-8, torso lean about 10 degrees, arms bent and pumping.
The pose guides for each frame are `sketch_00..07.png` (stick figure over the reference silhouette, pelvis axis in red); `contact_sheet.png` and `compare_*.gif` show them at gameplay speed.

## Identity (must not change)
- Mira as in the approved sprite sheet and in-game frames: dark long hair with purple highlights, dark coat with gold trim and a purple-tinted cape, brown skin (in-game skin tone `#9a6a52`, hair `#2b2233`, coat `#2b3350`, accent gold `#ffd86b`, overlay `#c27bff` per `scripts/world/explore.gd`).
- Keep her upright idle posture, her proportions (figure about 139 px tall on the 258x153 canvas) and her outline weight. The walk is keyed to her UPRIGHT idle; the run may lean about 10 degrees.
- No new costume pieces, no recolouring, no redesign.

Extracted palette (from the reference, for checking only): #260f1e, #442438, #0b0209, #99585b, #793274, #190e13, #351430, #ecc7d7, #130610, #4e1665, #cf93a4, #622a66

## Reference packet (originals are referenced by path and sha256 in `reference/reference_packet.json`, never copied or edited)
- `assets/_incoming/mira/mira_sprite_sheet.png`: approved original sprite sheet (idle 16, run 15, dash 6 cells; 1774x887 total, so a cell is low resolution) (approved in-game source)
- `assets/characters/mira/frames/idle_00.png`: approved upright standing pose (258x153 canvas, feet on the bottom row) (approved in-game frame)
- `assets/characters/mira/frames/run_00.png`: approved run pose (note: leaned forward, unlike her idle) (approved in-game frame)
- `assets/characters/mira/frames/run_07.png`: approved run pose, mid-cycle (approved in-game frame)
- `assets/characters/mira/frames/dash_00.png`: approved dash pose (cape and coat motion reference) (approved in-game frame)
- `assets/approved_anime/reference/02_cast_portrait_montage_2x2.png`: cast montage; [Unverified] whether it contains Mira (reference, character assignment unconfirmed)
`reference/reference_board.png` shows them with the palette and the guides on one page.

## No-cost production routes, in order (no credits, subscriptions or paid APIs; none was used or attempted)
1. **Hand-drawn / pixel-painted by an artist** over `sketch_*.png` in a free editor (for example Krita, GIMP or LibreSprite), one layer per body part so poses can be re-timed. Preferred: it is the only route that keeps costume details exact.
2. **Part-rigged from native art:** once native mira art exists, cut it into parts (head/ponytail, torso, coat/cape, arms, legs) and pose them from `params.json`, then hand-correct. Not possible for Echo V2 until native art exists (see missing assets).
3. **Open-source local AI assistance** (the repo's earlier diagnostic, `tools/echo_v2_assisted_enlarge.py`, used a free Real-ESRGAN model): only as a disclosed, human-finished step; output must be labelled assisted, never native. Any hosted or paid generator needs the owner's explicit approval first.
Do not substitute the stick-figure guides for art; do not redraw the character; do not edit the reference files.

## Acceptance checks (run on the finished folder)
- `python3 tools/measure_foot_travel.py <this folder> run --speed 300 --fps 12 --scale 1.2157`: planted travel within 25% of 20.56 px per frame.
- Alignment: pelvis/torso centroid range at most 2 px, planted sole on the bottom row, no whole-body drift (`tools/align_character_frames.py` method).
- 8 frames, exact canvas, transparent background, loops with no pop between frame 8 and frame 1.
- Palette and outline weight compared with the reference board, then the owner's visual review of the finished animation (the final gate).
