# Mira side-profile reference proposal (proposal only; no art redrawn, identity unchanged)

Board: `board.png` (every image is an unmodified approved frame). Lean numbers: `lean.json`. Rebuild: `python3 tools/build_mira_side_profile_board.py`.

Findings from inspecting her approved sheet and frames:
- `assets/_incoming/mira/mira_sprite_sheet.png` is 1774x887 for every cell, so each cell is low resolution (her in-game canvas is 258x153, figure about 139 px).
- Approved states: idle 16 frames (FRONT-facing, upright), run 15 frames (leaning SIDE views), dash 6 frames (SIDE, horizontal). No approved upright side view exists, and no walk.
- Most upright approved side frames by torso lean (head x minus hip x per figure height): **run_14 (+0.07)**, run_00 (+0.14), run_13 (+0.17); the rest lean 0.18-0.35.

Proposal: use **run_14** as the anchor for the upright side silhouette of her walk (the closest approved side pose to standing), run_00 and run_13 as backups, and the front idle for face, costume and colour identity. The walk's pose table is already specified (`../walk/params.json`: 8 frames at 8 fps, planted foot 9.25 px per frame at scale 1.216). Her run for the Warden chamber may keep the lean (about 10 degrees).
Identity locks: long dark hair with purple highlights, dark coat with gold trim, purple-tinted cape, brown skin; outline weight and proportions as approved.
Needs your approval: (1) run_14 as the upright side anchor; (2) whether an upright side pose may be drawn from the front idle plus run_14 (new drawing, not in the approved set); (3) the cast montage `02_cast_portrait_montage_2x2.png` was not used because none of its portraits is clearly her [Unverified].

## Update: owner decisions
run_14 is approved as the side-profile reference anchor, and preparing a new upright side pose from her existing approved references is approved. The review sheet is `upright_proposal.png` (rebuild with `python3 tools/build_mira_upright_proposal.py`). No pose has been drawn: it is a proposal for review, and her identity is unchanged.
