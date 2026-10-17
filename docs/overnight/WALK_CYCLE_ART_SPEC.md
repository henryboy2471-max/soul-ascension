# Echo walk cycle: what the art must provide to stop foot sliding

## Why code cannot fix it (measured on the current art)
`python3 tools/measure_foot_travel.py assets/characters/hero/frames walk --speed 90 --fps 5.3`

Echo's current 8-frame walk keeps the planted feet almost still relative to the body (back foot -18.6, -17.5, -19.4, -17.0 source px from the torso across frames 1-4; front foot moves about 2 px per frame). At the game's 90 px/s the ground needs a planted foot to move backward 9.0 source px per frame at 5.3 fps (4.8 at 10 fps). The art delivers a mean of 1.5 (median 0.5):

| ground speed, playback | needed per frame | art gives | skate (share of ground speed) |
|---|---|---|---|
| 90 px/s at 5.3 fps (now) | 9.0 px | 1.5 px | about 84% |
| 90 px/s at 10 fps | 4.8 px | 1.5 px | about 69% |
| 300 px/s at 10 fps (Warden chamber) | 15.9 px | 1.5 px | about 91% |
Playback speed only trades one kind of mismatch for another; the feet never plant.

## What a proper walk cycle needs (for review before any art is made)
Keep the approved Echo V2 design, palette, outline weight and proportions exactly. Only the pose sequence is new.
1. **Format**: transparent PNGs, same canvas as the current frames (136 x 108 source px, character about 94 px tall, feet on the bottom row, drawn facing right). A 2x canvas (272 x 216) would also remove the known softness from scaling the art up by 1.89; if made, tell me and the loader scale changes by one constant.
2. **Frames**: 8 frames, loops seamlessly, intended playback 8 fps (1.0 s per cycle, two steps).
3. **Planted-foot travel (the requirement)**: from heel strike to toe-off the planted foot moves BACKWARD relative to the pelvis by one step, about **6 source px per frame at 8 fps** (about 24 px per step) for the 90 px/s walk. `tools/measure_foot_travel.py <dir> walk --speed 90 --fps 8` must report planted-foot travel within 25% of the "needed per frame" figure.
4. **Registration**: pelvis/torso at the same x in every frame (the torso centroid range at most 2 px, `tools/align_character_frames.py` can verify), feet sole on the bottom row for the planted foot, no whole-body drift across the canvas.
5. **Vertical bob** at most 2 source px; head and cape follow-through small and symmetric (they are what read as "shaking" when frames disagree).
6. **Idle (optional, if a living idle is wanted instead of the current still pose)**: 4-6 frames where only cape/hair/breath move; feet and body identical in every frame to the pixel; the frame-to-frame difference must be small (measured as the premultiplied difference used in the overnight analysis; the current idle frames score 156-321, a usable one should score under about 40).
7. **Warden chamber / run**: the chamber moves at 300 px/s. A planted foot needs about 13 source px per frame even at 12 fps, so it needs its own faster run cycle (or a decision to leave that room as is).
8. **Mira**: her run cycle has the same problem plus a large torso lean (after this session's torso alignment the body no longer slides across the frame, but her feet still barely travel). Same spec, her proportions.

## How it will be checked
- `tools/measure_foot_travel.py` (planted-foot travel vs required), `tools/align_character_frames.py` (registration), `tests/test_character_stability.gd` (frames inside tolerance), and the stationary/walking footage method in `tools/qa/idle_footage.cjs` + `idle_report.py` before and after.
- Nothing is changed in the game until you approve the art.
