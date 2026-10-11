# Artwork validation checklist (run for every delivered asset; all boxes must pass before "production-ready")

An asset is **not** production-ready until actual transparent artwork/animations exist, pass every applicable item below, and the owner approves how it looks. Automated checks: `python3 tools/validate_approved_art.py --root .` (structure only; passing it never implies quality). Record results in the asset's `PROVENANCE.md`.

## A. Package and provenance
- [ ] Files are in the contract folders; names/frame counts match the manifest; `manifest.json` + `anchor.json` present
- [ ] Provenance recorded (tool, date, prompts, seed, edits); no paid service used without approval; no third-party copyrighted characters
- [ ] The four unidentified cast portraits are still unassigned (unless the owner approved identities)
- [ ] No HUD, minimap, joystick, text, speech bubble or border from files 03/05 appears in any asset

## B. Transparency and image hygiene
- [ ] PNG RGBA, straight alpha; alpha min 0 and max 255; no opaque rectangle or leftover key colour (#00FF00) anywhere (check at 400% on dark and light backdrops)
- [ ] No halo/fringe, no baked cast shadow, no reflection, no stray pixels
- [ ] Canvas exactly 576x1152 for every character frame (or the declared size), >= 24 px transparent margin, nothing clipped (coat flare, braids, gold accents)
- [ ] Portraits >= 1024x1024 transparent, no text/borders

## C. Identity and consistency (compare each view against references 01/04)
- [ ] Skin tone identical across all frames/views (sample same skin pixel: delta small)
- [ ] Hairstyle, hair length and accessory placement identical (hero back hair matches front; Imani braid length/cuffs constant)
- [ ] Costume layers, emblem position, strap/pouch/earring sides, boots and glove details identical across frames
- [ ] Head proportion and height match the manifest (Hero 1000 px, Imani 940 px); no frame-to-frame size or head-size drift
- [ ] Faces: eyes sharp with highlights, symmetrical, defined nose and lips, no stretching/distortion in any pose or view
- [ ] Hands correct (five fingers, defined) and limbs do not overlap incorrectly

## D. Foot alignment and animation
- [ ] Planted-foot sole on baseline y=1088 and pelvis x within +/-6 px of 288 in every frame; no vertical jitter other than intended bob
- [ ] Walk = 6 frames per direction (>=5), correct contact/down/passing sequence, arm counter-swing, believable weight shift; loop is seamless
- [ ] Idle = 2 frames; turns acceptable (3-frame transitions or matched snap)
- [ ] Left-facing: either separate frames or an explicit approval that mirroring is acceptable
- [ ] Play each loop at 100% and at engine scale 0.5 x depth 0.74-1.0: no shimmer, no sliding feet, no popping parts

## E. Environment layers
- [ ] Layer sizes/tiles per manifest; tiles seamless; far/mid/floor/foreground separated (each viewable alone) with real transparency where required
- [ ] No characters or HUD baked in; no repeated window grid patterns; visible structural variation and distinct neighbourhood areas
- [ ] Signs readable at 1280x720: TRAM REPAIR, CLINIC 24, SKYBRIDGE 09, MIDDLE HOUSE
- [ ] Building base line y=784 (2x) and walkable plane match the engine projection; collision mask aligns to the floor art
- [ ] Props/occluders have anchors and transparent edges; lighting consistent (neon violet/cyan/gold, wet reflections)
- [ ] Foreground sparse enough that the player and NPCs stay readable; perspective decision (manifest section 5) recorded

## F. Visual review at gameplay size (before any Godot work)
- [ ] Composite mock check (images only, not Godot): hero and Imani over layers at 1280x720, 844x390 and 667x375 — faces readable, silhouettes distinct, feet on ground, no blur
- [ ] Owner approves how it looks (signed in the PR/commit message); then and only then prepare the Godot visual-checkpoint scene
- [ ] Only after approval: Godot import, regression tests, movement/collision/dialogue/mobile validation, screenshots and test results reported honestly

## G. Safety
- [ ] No gameplay, episode, save, combat or progression file changed; no merge, deploy or publish
