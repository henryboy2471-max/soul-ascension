# Echo V2 native art: production checklist and reference package

Decisions applied: warm brown eyes in every view; the approved gold-banded ponytail kept consistent; scar position and bead count NOT invented (flagged); native 1152x2304 views; premium anime art direction (no pixel art); current in-game Echo kept until the complete V2 replacement is approved. Specification: `ECHO_V2_NATIVE_SPEC.md`; audit: `ECHO_V2_NATIVE_AUDIT.md`; animation contract: `ECHO_V2_G4_GAME_CONTRACT.md`. Nothing here is wired into the game, no image service is purchased, and no gate is bypassed.

## 1. Reference package (give these to the artist or generator)
| file | role |
|---|---|
| `assets/approved_anime/review/echo_v2_review/round2_consistency_pass/echo_v2_r2_right_facing_360x887_REVIEW_ONLY.png` | primary side view (the game uses right-facing art) |
| `.../echo_v2_r2_left_facing_434x887_REVIEW_ONLY.png` | asymmetric details: left-forearm band, undercut lines, carved hair detail. **Eyes in this view read grey-blue: do not copy them; use warm brown** |
| `.../echo_v2_r2_front_530x887_REVIEW_ONLY.webp` | costume, pendant, chains; **ponytail not visible here: draw it rising behind the head** like the profiles and back |
| `.../echo_v2_r2_back_450x887_REVIEW_ONLY.png` | back emblem, ponytail with gold band, rear vent lining |
| `docs/demo25d/phase2/ECHO_V2_DESIGN_AUTHORITY.md` | written appearance lock |
| `assets/characters/hero/frames_proposed/echo_v2_native/confirmation_sheet.png` | magnified crops of brow and hair for the two open questions |
| `assets/characters/hero/frames_proposed/{walk,run}/` | pose guides, params and generation instructions for later animation |
Hand these over unmodified (the round-2 files are the reference of record, review-only, about 865 px tall). The superseded old-Echo files (`assets/characters/hero/frames`, `echo_key_art.png`) are not references for design.

## 2. Close-ups needed to settle the two open items
Neither can be settled from the references: the sources are only about 865 px tall and the brow/locs are tiny in them (see the confirmation sheet).
1. **Scar:** one extreme close-up of the face, front view, at least 1500 px on the long side, covering forehead and both brows; plus a matching left-profile and right-profile close-up of the brow. The owner then states: scar yes/no; if yes, side, position relative to the brow, length, angle, style. Until answered the spec says UNSPECIFIED and nothing is drawn. The faint specks near the viewer's-right hairline in the front reference are not accepted as a scar without confirmation.
2. **Bead count:** a close-up of the hair from the back and one from each side at the same scale, showing every loc end. The owner confirms the canonical count, which locs carry beads, and the pattern (gold cuffs on loc ends versus small beads along the locs; the reference shows both). The four references disagree today.
The owner can mark answers directly on `confirmation_sheet.png`.

## 3. Production checklist (in order; each line is a gate)
1. [ ] Owner answers: scar (yes/no and exact description), canonical bead count and placement.
2. [ ] Four native 1152x2304 views, one image per view, same scale (figure 2000 px, head top y=176, soles y=2176, foot midpoint x=576), 24 px margin, transparent background; right view faces screen-right; left view genuinely drawn.
3. [ ] Every view: warm brown eyes with amber highlights; gold-banded ponytail identifiable in the front too; left-forearm band on every view where that arm shows, absent on the right forearm; no scar or beads beyond what the owner specified.
4. [ ] Face detail sheet and costume detail sheet (long side at least 2048); `PROVENANCE.md` (tool, date, prompts, seeds, edits; `source: native` or disclosed `assisted-native`).
5. [ ] `python3 tools/check_hero_turnaround.py` STRUCTURAL PASS on the genuine files (never on references), then the owner's visual approval of the four views (G2).
6. [ ] Layered master (Krita, 2304x4608 working canvas, one layer per part) and rig-part sources (G3); approval.
7. [ ] Animation frames per `ECHO_V2_G4_GAME_CONTRACT.md`, one state at a time in `frames_proposed/<state>/`, each checked with `tools/check_echo_v2_frames.py` and (walk, run) `tools/measure_foot_travel.py`, then old-versus-new at gameplay speed and the owner's approval.
8. [ ] Only after the complete V2 replacement (all states, portraits, key art, and the integration plan) is approved: the separate wiring checkpoint, including the per-animation scale-and-offset loader change. Until then the current in-game Echo stays.
Validators run on genuine finished artwork only. As of this commit no finished Echo V2 artwork exists, so none of the art validators was run on art (their self-tests pass on synthetic data).

## 4. Mira
Upright side-view proposal: `assets/characters/mira/frames_proposed/side_profile/upright_proposal.png` (approved run_14 as anchor, approved front idle for identity, magnified detail crops, the approved walk guides over run_14, and a brief for the new pose). run_14 stands left of the canvas centre and leans slightly, so the new pose is centred and upright (0-2 degrees); costume, hair, cape, boots, skin and outline weight stay exactly as approved. It needs your review before any art is drawn.
