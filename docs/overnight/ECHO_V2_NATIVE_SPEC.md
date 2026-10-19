# Echo V2 native art: specification, acceptance checklist and state replacement plan

Preparation only. Nothing here changes the playable game, the current QA build, the idle fix, the 90 px/s pace or any release gate. Companion: `ECHO_V2_NATIVE_AUDIT.md` (what the references do and do not show). No paid service is used or authorised.

## A. Native master specification (gate G2; numbers are the constants in `tools/check_hero_turnaround.py`)
| item | requirement |
|---|---|
| Files | `assets/approved_anime/source/hero/hero_turnaround_{front,right,back,left}_native.png`, plus `hero_face_detail_sheet.png`, `hero_costume_detail_sheet.png`, `PROVENANCE.md` (optional matte-green copies) |
| Canvas | exactly **1152 x 2304**, PNG RGBA, straight alpha, rendered or painted natively (never enlarged from a smaller image) |
| Figure | **2000 px** tall (+/-30), head top y = **176** (+/-12), planted soles y = **2176** (+/-8), planted-foot midpoint x = **576** (+/-90) |
| Margin | at least **24 px** transparent on every side (the coat flare, hem, ponytail and locs must not be clipped) |
| Alpha | corners transparent; at least **90%** of silhouette pixels fully opaque; at most **8%** soft pixels; no #00FF00 key colour, halo, fringe, baked shadow or reflection |
| Views | front, right (faces screen-right), back, left (genuinely drawn, not a mirror of right); figure heights within 20 px of each other; identical scale, costume, skin tone, eye colour, hair and ponytail length across views |
| Detail sheets | long side at least 2048: face (front, both profiles, back of head, eyes close-up) and costume (back emblem, sleeve patches and straps, pendant, glove plates, belts and buckles, boots with soles) |
| Provenance | tool, date, prompts, seeds, manual edits, who approved; recorded as `source: native`, `assisted-native` (disclosed) or human-painted |

Identity lock (from `ECHO_V2_DESIGN_AUTHORITY.md`, do not redesign): dark-brown skin, lean athletic, composed intense expression, strong straight brows, **warm brown eyes with amber highlights**; black locs with gold beads and cuffs; **high ponytail with a gold band, identifiable from every angle including the front**; loose forehead locs; side undercut with carved lines; gold earring; black turtleneck, gold chain and diamond pendant, second gold chain at the hips; black hooded coat with red lining, gold-tipped hem, split rear vent; rolled sleeves, red cuffs, black buckled straps; red-and-gold diamond sleeve patches; fingerless gloves with gold plates; **dark band/tattoo on the LEFT forearm only, in every view where that arm is visible**; red belts with gold buckles, red-striped black trousers, red thigh straps; black-and-red boots with red soles; gold winged-diamond back emblem.
**Brow scar: UNSPECIFIED.** Do not add, omit or place one until the owner gives side, position, length, angle and style (or says there is none). It is a blocking question for the face detail sheet.

## B. Acceptance checklist (every box before the owner is asked to approve)
- [ ] `python3 tools/check_hero_turnaround.py` prints STRUCTURAL PASS (it is BLOCKED today, 32 issues on the four reference crops)
- [ ] Section C of `ARTWORK_VALIDATION_CHECKLIST.md` (identity, same skin sample, same costume layers, eyes sharp and symmetrical, hands correct)
- [ ] One eye colour in all four views and both detail sheets (the left-facing reference currently reads grey-blue)
- [ ] Ponytail and gold band identifiable in front, both profiles and back, same length and bead pattern
- [ ] Left-forearm band present front (viewer's right arm), back (viewer's left), left-facing; absent on the right forearm
- [ ] Scar handled exactly as the owner specifies
- [ ] Hems, coat flare and locs not clipped; 400% crops on dark and light backdrops show no fringe
- [ ] Reduced to the game's size (figure about 190-205 screen px) over a neutral street colour block: face and silhouette read, feet on the ground
- [ ] `PROVENANCE.md` complete; no paid service used without approval; no HUD, text or borders in any file
- [ ] Owner visual approval of how the four views look (gate G2). Only then layered parts (G3) and animation frames

## C. From the 2000 px master to the game frames
The game draws Echo about 204 screen px tall (170 world px x 1.2 node scale), so the master is about 10x oversampled. Frames are produced from the master (or from its layered parts) by one fixed recipe, so every state matches:
- Echo state canvases: **272 x 216** (figure about 190 px, planted sole on the bottom row, pelvis at x = 136), except the run at **480 x 216** (approved). That is a factor of about 0.095 from the master; the per-animation scale-and-offset loader change (approved in principle, not implemented) is only needed for the run canvas if every other state uses 272x216, because the loader derives scale and offset from the idle frame.
- Same downsample recipe for every frame, same palette file extracted from the approved master, same outline weight; no per-frame retouching that changes colours.
- **Style decision needed:** Echo V2 is smooth anime art, while Mira's in-game frames are chunky low-resolution pixels. Downsampled Echo V2 will look cleaner and sharper than Mira beside her. Options: (a) accept the difference, (b) later redo Mira at the same fidelity, (c) pixel-snap Echo's frames. This is your call before frames are produced.

## D. State replacement plan (current art is the OLD Echo, so a partial swap would show two different characters)
| state | current Echo art in the game | V2 plan |
|---|---|---|
| idle | 6 frames, 6 fps (the game holds frame 0 and breathes) | 1 hold pose at 272x216, identical across frames; optional 4-6 frame calm loop later (cape/locs only; feet and body identical) |
| walk | 8 frames, 10 fps (played ~5.3 fps) | 8 frames at 8 fps, 272x216 (pose guides approved) |
| run | none (falls back to walk) | 8 frames at 12 fps, **480x216**, 300 px/s Warden chamber |
| hurt | 4 frames, 12 fps | 4 frames, 12 fps, 272x216 (same recipe) |
| defeat | 6 frames, 8 fps | 6 frames, 8 fps, 272x216 |
| attack1-3, skill, finisher, block, dash, jump, land | none (the game falls back to other animations or the idle) | [scope decision] the current game does not show Echo-specific art for these; a V2 set would be new content. Proposed counts for sizing only, not approved: attack 1-3 at 6 frames each, skill 8, finisher 10, block 2, dash 4, jump 4, land 3, on 272x216 |
| portraits, key art, dialogue, home and title screens | old Echo | not in this plan; replaced in the separate V2 integration step |
Order: G2 native views approved, then a layered master (Krita, 2304x4608 working canvas, one layer per part; doubles as the rig-part source, gate G3), then states built from it in the order walk, run, hurt, defeat, idle, then any combat scope. Each set is proposed in `frames_proposed/` with its foot/alignment checks and compared old vs new at gameplay speed, then approved by you; wiring (including the loader change) is a separate checkpoint, and the full V2 swap across episodes is separately approved.

## E. Production routes (free first)
1. Human illustrator or the owner paints the four native views over the approved references in Krita/GIMP (best quality; the layered file feeds G3).
2. If a generator is used, only on an account the owner supplies, one view per image at the largest size it allows, flat #00FF00 background, 8%+ margin, no composite sheets; disclosed as `assisted-native` if upscaled; owner decides whether that meets "native".
3. Not recommended: enlarging the reference crops, tracing them, a 3D proxy, any procedural redraw.
