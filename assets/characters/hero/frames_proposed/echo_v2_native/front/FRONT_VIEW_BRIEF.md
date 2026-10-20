# Echo V2 native FRONT view: painting brief (no art exists yet)

Status: NOT PRODUCED. A faithful native 1152x2304 front view cannot be made by enlarging the 530x887 reference (the pixels do not exist; the reference also has a clipped hem, soft edges, an invisible ponytail and a front eye reading wrong), and I cannot paint it. This folder holds the template for the person who will. References are ONLY the approved round-2 views and `ECHO_V2_DESIGN_AUTHORITY.md`. The navy-and-gold image the owner rejected is not a reference (see `docs/overnight/ECHO_V2_REJECTED_REFERENCES.md`).

Files: `front_template_guides.png` (guide lines: head top y=176, soles y=2176, foot midpoint x=576, 24 px margin) and `front_UNDERLAY_NOT_ART.png` (the approved front reference scaled to the 2000 px figure box at 50% opacity, for painting over on a layer below the linework). Rebuild: `python3 tools/make_echo_v2_front_template.py`.

## Width problem to decide before painting
Scaled to the required 2000 px height, the approved front figure is about **1194 px wide** (the coat flare), wider than the 1152 px canvas and beyond the 24 px margin limit (1104 px usable), and the reference hem is already clipped on the right, so the true width is larger. Options (owner decision; I changed no gate): (a) widen the front (ideally all four views) canvas, for example to 1280x2304, and update the G2 constants; (b) keep 1152 and paint all four views at a smaller figure height of about 1840 px, relaxing the 2000 +/-30 rule; (c) draw a narrower coat flare (a design adjustment that needs your approval). Until you choose, no front view can pass G2 as specified.

## What the front view must contain (from the locked design)
- Black hooded coat with red lining, red inner collar, gold-tipped hem corners; black turtleneck; gold chain with a large gold diamond pendant; second gold chain at the hips.
- Rolled sleeves with red cuffs and black buckled straps; red-and-gold diamond patches on both upper sleeves; red-trimmed epaulettes; black fingerless gloves with gold plates and wrist cuffs.
- Dark band/tattoo on the LEFT forearm (the viewer's right arm), none on the right forearm.
- Red belts with gold buckles; black trousers with red stripes; red thigh straps; cargo pockets; black-and-red boots with RED soles, black buckle straps, gold diamond studs.
- Warm brown eyes with amber highlights in BOTH eyes (the left-profile reference's grey-blue eyes are wrong).
- Black locs with gold beads/cuffs, side undercut with carved lines, loose forehead locs, gold earring, and the **gold-banded high ponytail made identifiable from the front** (rising behind the head, band visible), same length and bead pattern as the profiles and back.
- **Brow scar: leave the brow unmarked until the owner confirms side, position, length, angle and style.** Do not add one; do not invent bead counts: copy the front reference's loc and bead pattern and flag anything unclear.
- Delivery: opaque interior (at least 90%), at most 8% soft pixels, transparent corners, no #00FF00, hem and flare unclipped, `PROVENANCE.md`. Then `python3 tools/check_hero_turnaround.py` (all four views and both detail sheets must exist for a full pass) and the owner's visual approval (gate G2).
