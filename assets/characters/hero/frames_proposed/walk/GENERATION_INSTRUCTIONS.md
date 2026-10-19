# Final-art instructions: echo_walk (hero walk)
Status: NOT STARTED. These instructions and the reference packet are preparation only; nothing is wired into the game and the pose sketches are guides, never final art.

## Deliverable
- 8 transparent PNG frames `walk_00.png` .. `walk_07.png` in this folder, canvas **272x216**, character drawn facing right, loops seamlessly, plays at **8 fps** (1.00 s per cycle) at ground speed **90 px/s**.
- Figure height about 190 px; the planted sole sits on the bottom row; the pelvis x is the canvas centre (x = 136) in every frame.
- Screen scale 0.9444: the cycle must keep the current on-screen size.

## Foot rule (the whole point)
A planted foot moves BACK **11.91 px per frame** relative to the pelvis; one step covers 47.65 px. Foot x is measured from the pelvis (+ = forward); lift is height above the ground. Leg B is leg A shifted by four frames.
| frame | leg A foot x | leg A lift | leg B foot x | pelvis height vs mean |
|---|---|---|---|---|
| 1 | +23.8 | 0.0 | -23.8 | +0.0 |
| 2 | +11.9 | 0.0 | -11.9 | -1.9 |
| 3 | +0.0 | 0.0 | +0.0 | +0.0 |
| 4 | -11.9 | 0.0 | +11.9 | +1.9 |
| 5 | -23.8 | 0.0 | +23.8 | +0.0 |
| 6 | -11.9 | 6.0 | +11.9 | -1.9 |
| 7 | +0.0 | 17.1 | +0.0 | +0.0 |
| 8 | +11.9 | 7.7 | -11.9 | +1.9 |
Walk: contact (1, 5), down (2, 6), passing (3, 7), up (4, 8); pelvis bob at most 2% of leg length; torso lean 0-2 degrees; opposite arm swings with each leg.
The pose guides for each frame are `sketch_00..07.png` (stick figure over the reference silhouette, pelvis axis in red); `contact_sheet.png` and `compare_*.gif` show them at gameplay speed.

## Identity (must not change)
- Echo V2 (owner design authority `docs/demo25d/phase2/ECHO_V2_DESIGN_AUTHORITY.md`): lean athletic, dark-brown skin, about 7.5 heads tall, composed intense expression, warm brown eyes.
- Hair: black locs with gold beads, HIGH PONYTAIL with a gold band (same length every frame), loose forehead locs, side undercut, gold earring. Scar/brow mark: the owner listed a scar; the docs list it as unconfirmed, see missing assets.
- Black turtleneck, gold chain with large gold diamond pendant, black long hooded coat with RED lining, gold-tipped hem corners, split rear vent (red lining, gold trim) that carries the cape motion.
- Rolled sleeves with red cuffs and black buckled straps, red-and-gold diamond sleeve patches, black fingerless gloves with gold plates, dark FOREARM BAND on the LEFT forearm only.
- Red belts with gold buckles, red-striped black trousers, red thigh straps, black-and-red boots with RED SOLES. Palette: black, red, gold, brown skin. Same outline weight and shading as the approved art.

Extracted palette (from the reference, for checking only): #34302f, #242020, #0a0505, #1a1515, #c70614, #131010, #70060b, #f4081c, #db964d, #47332e, #794a33, #3d2725

## Reference packet (originals are referenced by path and sha256 in `reference/reference_packet.json`, never copied or edited)
- `assets/approved_anime/review/echo_v2_review/round2_consistency_pass/echo_v2_r2_right_facing_360x887_REVIEW_ONLY.png`: primary side reference (the walk/run is drawn facing right) (REVIEW ONLY; soft alpha; cropped at left/right edges)
- `assets/approved_anime/review/echo_v2_review/round2_consistency_pass/echo_v2_r2_left_facing_434x887_REVIEW_ONLY.png`: far-side arm/leg and left-forearm band check (REVIEW ONLY)
- `assets/approved_anime/review/echo_v2_review/round2_consistency_pass/echo_v2_r2_front_530x887_REVIEW_ONLY.webp`: front: costume, chain/pendant, brow mark; ponytail not clearly visible (REVIEW ONLY)
- `assets/approved_anime/review/echo_v2_review/round2_consistency_pass/echo_v2_r2_back_450x887_REVIEW_ONLY.png`: back: winged-diamond emblem, ponytail, rear vent lining (cape motion) (REVIEW ONLY)
- `assets/approved_anime/review/echo_v2_review/echo_v2_four_view_composite_1774x887_REVIEW_ONLY.webp`: all four views from one generation (round 1) (REVIEW ONLY; superseded in detail by round 2)
- `docs/demo25d/phase2/ECHO_V2_DESIGN_AUTHORITY.md`: written appearance lock and consistency rules (authoritative text)
`reference/reference_board.png` shows them with the palette and the guides on one page.

## No-cost production routes, in order (no credits, subscriptions or paid APIs; none was used or attempted)
1. **Hand-drawn / pixel-painted by an artist** over `sketch_*.png` in a free editor (for example Krita, GIMP or LibreSprite), one layer per body part so poses can be re-timed. Preferred: it is the only route that keeps costume details exact.
2. **Part-rigged from native art:** once native hero art exists, cut it into parts (head/ponytail, torso, coat/cape, arms, legs) and pose them from `params.json`, then hand-correct. Not possible for Echo V2 until native art exists (see missing assets).
3. **Open-source local AI assistance** (the repo's earlier diagnostic, `tools/echo_v2_assisted_enlarge.py`, used a free Real-ESRGAN model): only as a disclosed, human-finished step; output must be labelled assisted, never native. Any hosted or paid generator needs the owner's explicit approval first.
Do not substitute the stick-figure guides for art; do not redraw the character; do not edit the reference files.

## Acceptance checks (run on the finished folder)
- `python3 tools/measure_foot_travel.py <this folder> walk --speed 90 --fps 8 --scale 0.9444`: planted travel within 25% of 11.91 px per frame.
- Alignment: pelvis/torso centroid range at most 2 px, planted sole on the bottom row, no whole-body drift (`tools/align_character_frames.py` method).
- 8 frames, exact canvas, transparent background, loops with no pop between frame 8 and frame 1.
- Palette and outline weight compared with the reference board, then the owner's visual review of the finished animation (the final gate).
