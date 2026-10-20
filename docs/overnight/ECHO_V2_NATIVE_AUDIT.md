# Echo V2 reference audit (round-2 views) against the G2/G4 requirements

> **Update:** the native master canvas is now **1280x2304** (owner decision, foot midpoint x=640). Figures below that say 1152 and 576 describe the checker as audited at the time; see `ECHO_V2_G2_1280_AUDIT.md` for the revised constants and tests.

Read: `ECHO_V2_DESIGN_AUTHORITY.md`, `ECHO_V2_FRONT_PRODUCTION_READINESS_REPORT.md`, `HERO_PRODUCTION_DELIVERABLES_CHECKLIST.md`, `ARTWORK_VALIDATION_CHECKLIST.md`, `tools/check_hero_turnaround.py` (G2 constants), `tools/validate_approved_art.py` (G4). Views audited: `assets/approved_anime/review/echo_v2_review/round2_consistency_pass/` front 530x887, back 450x887, left-facing 434x887, right-facing 360x887. Visual notes come from crops up to 8x of these 887 px sources, so fine detail is at the limit of what the pixels hold; where I could not see something I say so. Nothing was generated, enlarged or edited, and no paid service was used.

## 1. Structural result against G2 (`tools/check_hero_turnaround.py`, run on temporary copies renamed as the native views)
BLOCKED, as expected for reference crops (32 issues, listed per view in the run output). Measured:
| view | size | figure height | alpha 255 share | soft (<250) share | touches canvas edge | foot midpoint x |
|---|---|---|---|---|---|---|
| front | 530x887 | 868 | 0.2% | 12.5% | right | 278 |
| back | 450x887 | 864 | 0.2% | 15.0% | left and right | 232 |
| left-facing | 434x887 | 871 | 0.1% | 13.7% | left | 208 |
| right-facing | 360x887 | 866 | 0.1% | 14.4% | left and right | 212 |
Required for each: 1152x2304 native, figure 2000 px (+/-30), head top y=176, soles y=2176, foot midpoint x=576 (+/-90), 24 px margin, at least 90% fully opaque, at most 8% soft pixels, no #00FF00, transparent corners; four views within 20 px of the same figure height; left not a mirror of right; plus two detail sheets (long side at least 2048) and `PROVENANCE.md`. The four figures are within 7 px of each other in height, so the cross-view scale is consistent; every other number fails because the sources are 2.3x too small. `tools/test_check_hero_turnaround.py` and `tools/test_validate_approved_art.py` still pass (checker logic intact); `tools/validate_approved_art.py` reports BLOCKED (no native characters or environment assets exist).

## 2. Identity checks (what I could and could not verify)
| item | front | back | left-facing | right-facing | verdict |
|---|---|---|---|---|---|
| **Forearm band** (left forearm only) | present on the viewer's-right forearm | present on the viewer's-left forearm | present on the near forearm | absent (correct: the band is on his other arm) | **Consistent.** Matches the authority rule |
| **Ponytail with gold band** | NOT identifiable (loose locs on top, no ponytail rising behind) | clear, gold band at the crown | clear | clear | **Front incomplete** (documented blocker) |
| **Loose forehead locs** | present, one crosses the viewer's-left eye | n/a | present | present | consistent |
| **Gold earring** | gold earring(s) on the viewer's-right ear | n/a | stud | stud | consistent (count in the front is hard to read) |
| **Eyes (warm brown, amber highlights)** | viewer's-right iris reads dark brown with a light highlight; the other eye is mostly hidden by a loc | n/a | iris reads **pale grey-blue with white highlight** | iris mostly hidden, dark with an amber glint | **Not consistent: the left-facing view does not read warm brown.** Needs repaint; at this resolution I cannot judge amber highlights |
| **Brow scar** | see 3 | n/a | none visible | none visible | **Unverified** |
| Costume: red-lined black coat, sleeve diamond patches, red cuffs, chains/pendant, red belts, red-striped trousers, black-and-red boots with red soles | present | back emblem and cuffs present | present | present | consistent where visible |
| Bead count and placement on the locs | differs by view | differs | differs | differs | open item (authority doc), unresolved |
| Proportions | figure heights 864-871 across views | | | | cross-view scale consistent; "7.5 heads" [Unverified]: head top to chin is about 142 of 868 px (about 6.1 heads) when the hair mass is included, so 7.5 only holds if the head is measured without the locs |

## 3. The brow scar: not invented
The authority document lists "whether the small dark mark near the brow in the front view is an intended scar" as an open item; your earlier instruction names a scar. In the four views I find **no scar line** at the brow or anywhere on the face. The front has a few faint dark specks near the hairline above the viewer's-right brow (these are most likely the "dark mark"), the left-facing view has two small white highlight dots on the cheek, and the undercut carries carved lines that are hair design, not a scar. The records give no side, length, angle or shape. I have therefore recorded the scar as **UNSPECIFIED** in the native specification. A native render must neither add nor omit a scar until you specify it (side, position relative to the brow, length, angle, healed or raised) or state that there is none.

## 4. Artwork requirements that remain incomplete
1. Four native 1152x2304 views (front, right, back, left): none exists. The round-2 files are reference only, "not repairable to native".
2. Face detail sheet and costume detail sheet (long side at least 2048): missing.
3. Eye colour fixed to one warm brown with amber highlights in every view (left-facing is off).
4. Front ponytail made identifiable.
5. Scar decision (3).
6. Single bead count and placement.
7. Clipped hems and edges: the back, left and right references touch the canvas edge, so the hem and coat flare are partly missing and have to be redrawn.
8. Provenance record, and the owner's visual approval of the four views before any parts or animation (gate G2).
9. A contract for this game's side-view animation states (the existing G4 contract does not match it; see `ECHO_V2_NATIVE_SPEC.md`).

## 5. Reference images that need your approval
- The four round-2 views as the **reference of record** for the native render, subject to the fixes in 4. The round-1 four-view composite and its crops stay historical (round 2 supersedes them).
- Your decisions on: scar (3), eye colour (all views one warm brown, including the left), front ponytail, and the bead count.
