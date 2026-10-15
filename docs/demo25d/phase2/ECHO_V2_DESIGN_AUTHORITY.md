# Echo V2 — final design authority (owner decision; do not re-ask)

**Echo V2 is the official, authoritative protagonist design for SOUL ASCENSION.** It replaces, for this character only: (a) the previous white-twist Echo appearance (`assets/echo_key_art.png`, the Episode 1-2 sprite sheets under `assets/characters/hero/` and `assets/_incoming/hero/`, the in-game Echo look) and (b) the Hero pack v2 design. Everything older is kept as a **historical record, marked SUPERSEDED FOR ECHO**; no original file was deleted or edited.

**Authoritative visual reference (REVIEW ONLY, not native production art):** `assets/approved_anime/review/echo_v2_review/` — the four-view composite `echo_v2_four_view_composite_1774x887_REVIEW_ONLY.webp` plus the crops. These are original-pixel crops of one generated composite; alpha never reaches 255, figure ~870 px tall, not native 1152x2304, not validated. They define *what the character looks like*, not production sprites.

Naming: the "Hero" in the production manifests and the validator is **Echo (V2)**. The folder/id `hero` is kept as an alias so `tools/validate_approved_art.py` keeps working (`assets/approved_anime/characters/hero/`).

## Appearance lock (owner-approved; do not redesign)
- Black male protagonist, dark-brown skin, lean athletic, ~7.5 heads tall, composed intense expression, strong straight brows, **brown eyes** (warm brown, amber highlights).
- **Hair:** black locs with gold beads/cuffs; **high ponytail** (gold band) plus **loose forehead locs**; side undercut with carved lines; gold earring.
- **Neck/torso:** **black turtleneck** (mock-neck), **gold chain with a large gold diamond pendant**; a second gold chain hangs at the hips.
- **Coat:** black long hooded coat with **red lining** and red inner collar, gold-tipped hem corners, split rear vent with red lining and gold trim; sleeves rolled with red cuffs and black buckled straps; red-trimmed shoulder epaulettes; **red-and-gold diamond patches on both upper sleeves** (all views where visible).
- **Back:** large **gold winged-diamond emblem**; gold-buckled straps/belt hardware.
- **Belts/legs:** **red belts** with gold buckles, **red-striped black trousers**, red thigh straps with gold buckles, cargo pockets.
- **Hands:** black fingerless gloves with gold plates; wrist cuffs with a gold plate.
- **Boots:** **black-and-red boots with red soles**, black buckle straps with gold buckles and gold diamond studs.
- **Palette:** black, red, gold, brown skin.

## Consistency rules for the native renders (mandatory)
1. **Forearm band/tattoo:** the dark forearm band/tattoo seen on the character's **left forearm** in the back and left-facing views must appear in **every view where that arm is visible** (front: viewer's right arm; back: viewer's left arm; left-facing profile; not on the right forearm unless the owner says otherwise). The review front currently shows a glove/wrist plate with no visible band — fix in the native front.
2. **One hairstyle and one ponytail length in all four directions:** the ponytail and its gold band must be identifiable from the front (rising behind the head), both profiles and the back; same bead pattern and length; loose forehead locs identical.
3. One eye colour (warm brown), one skin tone, identical costume details (patches, straps, chains, buckles) in every view.
4. Left view is genuinely drawn (never a mirror).
5. Open items to confirm during review (not redesigns): whether the small dark mark near the brow in the front view is an intended scar; the exact bead count on the locs.

## Superseded for Echo (historical records — do not delete, do not use as the design source)
| Item | Path | Status |
|---|---|---|
| Original Echo key art (white twists, indigo coat) | `assets/echo_key_art.png` | SUPERSEDED FOR ECHO (still used by the shipped Episode 1-2 build until replaced) |
| Episode 1-2 Echo/Hero sprites | `assets/characters/hero/`, `assets/_incoming/hero/` | SUPERSEDED FOR ECHO (gameplay untouched) |
| Reference 01 Main Hero sheet | `assets/approved_anime/reference/01_main_hero_turnaround_portrait.png` | SUPERSEDED FOR ECHO (already superseded for the Hero) |
| Hero preview candidate | `assets/approved_anime/preview/hero_turnaround_candidate/` | SUPERSEDED FOR ECHO |
| Hero reference pack v2 | `assets/approved_anime/reference/hero_reference_pack_v2/` | SUPERSEDED FOR ECHO |
| Overview mockup hero panel | `reference/03_overview_mockup_hero_npc_environment_with_hud.png` (hero panel only) | SUPERSEDED FOR ECHO |
| Procedural prototype Echo | `assets/demo25d/chars/echo_*`, `tools/art25d/chargen.py` | rejected as final art; superseded |
| Docs: `HERO_DESIGN_LOCK_AND_PRODUCTION_SPEC.md` Revisions 1-2, `HERO_TURNAROUND_REVIEW.md`, `HERO_RIGGING_PLAN.md` identity text, `docs/demo25d/*` older Echo mentions | docs | historical; Echo V2 section above governs |
Still current and unchanged: Imani sheet (04) as Imani's direction, Neon District mockup (05) for look/lighting only (HUD never extracted), cast montage (02) unassigned.
**Consequence to track (not done here):** Episodes 1-2 in the current build still show the old Echo. Replacing Echo in shipped episodes is a later, separately approved integration after the new assets pass validation; no gameplay, episode, mission, save or combat file was touched.

## Status
All Echo V2 production assets are `MISSING` until genuine native art exists and passes `tools/check_hero_turnaround.py` (G2), `tools/validate_approved_art.py` (G4) and the owner's visual approval. No rigging or animation before G2.
