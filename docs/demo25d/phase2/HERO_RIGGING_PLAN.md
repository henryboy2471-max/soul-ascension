# Hero layered-rig plan (PLAN ONLY — no animation implemented, no artwork created)

## 0. Input status and validation (what I actually checked)
- **No new image files arrived with this request.** The four files in the uploads folder are byte-identical (SHA-256 prefixes `3a1052594b70`, `fc8758cf8c5c`, `8f4c435de72e`, `20a9758fa564`) to the candidate already staged at `assets/approved_anime/preview/hero_turnaround_candidate/`. I therefore validated those. If the owner's "approved" four-view art is a different/corrected set, send it and I will re-run the checks.
- **Design question RESOLVED (owner, later in this session): the candidate is the official Hero; reference 01 is superseded for the Hero. See `HERO_DESIGN_LOCK_AND_PRODUCTION_SPEC.md`. (Original note:)** this candidate differs from approved reference 01 (red lining, white tee, brown belts, bandages, ponytail/undercut, circle-crosshair back emblem, per-view eye colour; see `HERO_TURNAROUND_REVIEW.md`). The owner's message calls the art "approved", which I take as approval of the candidate as the Hero design, **but please confirm in one line that reference 01 is superseded for the Hero**. The plan below assumes the candidate.

### Measured results (per view)
| View | Size / mode | Alpha | Height | Lowest solid px | Sole x-ranges | Silhouette centre x |
|---|---|---|---|---|---|---|
| front | 576x1152 RGBA | 0-255 | 999 | y=1087 | 90-215 and 361-492 (two feet) | 287 |
| right (faces right) | 576x1152 RGBA | 0-255 | 997 | y=1085 | 246-422 (feet overlap) | 287 |
| back | 576x1152 RGBA | 0-255 | 999 | y=1087 | 89-213 and 369-495 | 287 |
| left (faces left) | 576x1152 RGBA | 0-255 | 999 | y=1087 | 194-364 (feet overlap) | 288 |
Pass: exact 576x1152, RGBA, transparent corners, no #00FF00 residue, content >= 44 px from the sides, soles on the y=1088 baseline within the 4 px tolerance, left is not a mirror of right.
### Problems to report before anything is rigged
1. **Not native art.** Per ChatGPT's own README the files are enlarged crops of one 1774x887 composite (scale factors 1.14-1.16): soft detail and matte artifacts. Rig parts must be re-created at native resolution.
2. **Edge quality:** about 13% of non-zero pixels are semi-transparent edge pixels and about 4.5% of those are light (grey-background fringe). Needs a clean matte before use.
3. **Faint dashed/dotted line** near y~88 above the head in all four images (visible on inspection; sits at the same height as the head top).
4. **Foot alignment:** baselines are acceptable, but the silhouettes were centred by *bounding box* (x=287-288), not by pelvis/foot midpoint. The pelvis centre therefore differs per view (the coat flare and the side stance shift it). Frames must be re-anchored by the planted foot / pelvis, not the bbox. In the side views both feet overlap, so contact poses cannot be read from the stills.
5. **Consistency:** eye colour and hair silhouette differ between views (see review); the back emblem is not the sleeve diamond.
6. **Rig suitability:** flat single-layer images — no separated parts, no painted occluded areas (under the head, coat, arms, behind the hood, inside the coat, hand backs, boot undersides).
Result: the stills are valid **visual references** for the rig, **not rig-ready parts**. Status stays MISSING for all production assets; the validator stays BLOCKED.

## 1. Method (locked): layered skeletal-style 2D animation, one rig per view
- Four genuine rigs: front, right, back, left. Never mirror (asymmetric strap, pouches, earring, hair). Parts are drawn per view; shared parts (e.g. boots) only if a human artist confirms they read correctly.
- Parts are hand-painted (or ChatGPT/artist-generated and manually corrected) at **native 2x master resolution (576x1152 canvas, 1000 px figure)** with painted-under overlaps at every joint. No procedural fill, no automatic inpainting passed off as art.
- Animation is authored in a free tool (no purchases): candidate = Godot `Skeleton2D` + `Bone2D` + `Polygon2D`/`Sprite2D` parts with `AnimationPlayer`, exported offline to frames; alternative = any open-source 2D rig tool. Output must be exactly the frame contract (`PRODUCTION_ASSET_MANIFEST.md` section 3) so `tools/validate_approved_art.py` checks it unchanged. Runtime rigging in-game is out of scope.

## 2. Skeleton (all views; draw order differs per view)
Root (ground, anchor x=288, baseline y=1088) -> Pelvis -> Spine1 -> Chest -> Neck -> Head. Chest -> Shoulder L/R -> UpperArm -> Forearm -> Hand (+ fingerless-glove plate). Pelvis -> Thigh L/R -> Shin -> Foot (boot, with toe-flex bone). Secondary chains (keyframed follow-through, no physics): Hair (ponytail/locs 3-4 segments + loose front strands 2 segments), Hood (2 segments at neck), Coat front panel L/R (3 segments each), Coat back panel(s) (3 segments), Coat sleeve cuffs, Cross-body strap (1), Pouches/belt items (pendulum, 1 each), Necklace/pendants (1-2), Earring (1).

### Part list per view (each a separate transparent PNG with a pivot)
Head (face with eyes/brows/mouth kept as one clean layer; separate eye layers for optional blink), hair front, hair back/ponytail segments, ear + earring, neck, hood (outer + inner lining), torso/t-shirt, coat chest panels, coat tails (outer + inner lining, per panel), upper arms with sleeve, sleeve emblem, forearms with wraps/bracers, hands (relaxed; plus swung-open variant), pelvis, belts and pouches, thigh pouches, trousers (thigh/shin cuff pieces), boots (upper, sole), strap, necklace + pendants. Per view the visible subset and z-order differ (e.g. back view shows hood back, back emblem, no face).
Painted-under/occlusion regions the artist must supply: torso under head/neck; shoulders under coat; upper arm under sleeve; coat interior and lining where panels swing open; trouser top under belt; thigh/hip under coat tails; hair back plate behind the head; ear under hair; hands' back/palm sides; boot undersides/heel when lifted; back of hood.

## 3. Animation specs to rig (per view, exported to frames)
**Idle (2 frames, 4 fps loop):** chest scale +/-1.5%, shoulders +/-2 px, head +/-1 px, coat hem and ponytail sway 2-4 px with delay, optional blink only as an extra later.
**Walk (6 frames, ~9 fps, loop 0.67 s):** 1 contact A, 2 down, 3 passing, 4 contact B, 5 down, 6 passing. Targets (art px, tune visually): body bob 10-14 px (lowest on 'down'), pelvis lateral sway 8 px (front/back) with the head counter-sway 3 px, torso lean 2-3 deg, arm counter-swing +/-20 deg forearm bend 15 deg (side) or arm foreshortening (front/back), hip +/-25 deg (side stride), knee 35-45 deg on passing/lift, foot flex at toe-off, planted sole exactly on y=1088 in contact frames. Coat tails, ponytail, hood and strap follow with 1-2 frame delay; the coat must never clip through the legs. Footstep contact frames: 1 and 4 (confirm after delivery).
**Direction specifics:** front/back = legs foreshortened with alternating lift and lateral weight shift; left/right = classic scissor with visible near/far limbs.
**Optional later:** 3-frame turns (front<->right, right<->back and mirrors drawn separately), talk idle, react, hurt.

## 4. Deliverables ChatGPT/an artist must produce (all currently MISSING)
1. Confirmation of the canonical Hero design (candidate vs reference 01) and a **native-resolution, clean-matte four-view turnaround** with consistent eyes/hair/emblem (brief A) — needed before parts.
2. Layered part sets for the four views + `rig_pivots.json` (pivot per part, parent bone, z-order) (brief B).
3. Painted occluded regions listed above.
4. Alternative hand poses and (optional) blink layers.
5. Rigged, exported frames: `{front,right,back,left}_{idle_00..01,walk_00..05}.png`, `manifest.json`, `anchor.json`, `portrait.png` (1024) + expressions, `PROVENANCE.md`.

## 5. Gates (nothing proceeds without them)
G1 owner confirms design -> G2 corrected four-view turnaround visually approved -> G3 parts delivered and spot-checked at 100% (joints show no gaps) -> G4 animations exported, validator STATIC CHECK PASS, manual checklist, owner approves how it moves -> G5 only then the Godot visual-checkpoint scene (`INTEGRATION_ADAPTER.md`). No gameplay change, merge, deploy or paid credits at any step.

## 6. Status
No animation implemented, no part extraction attempted (cutting a flat enlarged image would leave missing occlusion areas and soft edges, i.e. substitute-quality art). Stopped here for owner validation.
