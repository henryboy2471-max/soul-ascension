# G2 validator audit for the 1280x2304 native master (owner decision, Option 1)

Nothing in the production gates was weakened or bypassed: the **default** profile of `tools/check_hero_turnaround.py` is byte-for-byte the old behaviour (1152x2304, foot midpoint 576), the G4 validator `tools/validate_approved_art.py` (576x1152) is untouched, and the new profile is opt-in until you separately approve making it the default.

## Assumptions found in the tools and docs
| where | assumption | action |
|---|---|---|
| `tools/check_hero_turnaround.py` | `W,H = 1152,2304`; `FOOT_MID_X = 576`; comment "front at 2000 px is ~1095 px wide on a 1152 canvas" | added `--profile {legacy,1280}`; legacy = (1152, 576) stays the default; 1280 = (1280, 640). Every other limit is identical: figure 2000 (+/-30), head top 176 (+/-12), soles 2176 (+/-8), foot tolerance +/-90, margin 24, opaque >= 90%, soft <= 8%, heights within 20 px, left not a mirror, detail sheets >= 2048, no #00FF00 |
| `tools/test_check_hero_turnaround.py` | all fixtures are 1152 wide | existing 7 cases unchanged and passing; 7 new cases for the 1280 profile (conformant set passes; default profile still rejects 1280-wide files; 1280 profile rejects 1152-wide files; figure with exactly 24 px margins passes, 23 px rejected; feet 200 px off x=640 rejected; feet at x=576, 64 px off, still inside the 90 px tolerance) |
| `tools/finalize_native_matte.py` | places figures on 1152x2304 at foot midpoint 576 | added `--width {1152,1280}` (default 1152 unchanged); new `tools/test_finalize_native_matte.py` (1152 and 1280 placement, and a wrong-height image is refused, never scaled) |
| `tools/validate_approved_art.py` | G4 frames 576x1152, anchor x=288 | unchanged; the proposed game animation contract is separate (`ECHO_V2_G4_GAME_CONTRACT.md`) |
| `HERO_PRODUCTION_DELIVERABLES_CHECKLIST.md`, `ART_BRIEFS.md`, `ARTWORK_VALIDATION_CHECKLIST.md`, `PRODUCTION_ASSET_MANIFEST.md`, `asset_manifest.json`, `HERO_DESIGN_LOCK_AND_PRODUCTION_SPEC.md`, `HERO_RIGGING_PLAN.md`, `INTEGRATION_ADAPTER.md`, `HERO_TURNAROUND_REVIEW.md` | still say 1152 | a canvas-update banner was added to the deliverables checklist; the others are historical/superseded for Echo and were not edited. Revising `asset_manifest.json` and the manifest document is part of the approval that makes 1280 the default |
| `docs/overnight/ECHO_V2_NATIVE_SPEC.md`, `..._PRODUCTION_PACKAGE.md`, `..._G4_GAME_CONTRACT.md` | said 1152 / x=576 | updated to 1280 / x=640 |

To make the new profile the default later (needs your approval): change the `--profile` default to `1280` in `check_hero_turnaround.py`, update the legacy tests to the 1280 geometry, update `asset_manifest.json`, and set `finalize_native_matte.py --width` default to 1280.

## Silhouette and margin check on the four approved references, at the new geometry
`python3 tools/make_echo_v2_front_template.py` scales each round-2 reference to the 2000 px figure and puts its planted-foot midpoint on x=640 (usable width 24..1256 = 1232 px). Result (also in `assets/characters/hero/frames_proposed/echo_v2_native/silhouette_report_1280.json`):
| view | figure width at 2000 px | x range | spare to the 24 px margin (left / right) | reference clipped at |
|---|---|---|---|---|
| front | 1194 | 27..1221 | **+3 / +35** | right edge |
| right-facing | 831 | 151..982 | +127 / +274 | left and right |
| back | 1044 | 102..1146 | +78 / +110 | left and right |
| left-facing | 990 | 116..1106 | +92 / +150 | left |

## Remaining clipping and margin problems
1. **Front: the left margin has only 3 px to spare and the reference hem is cut off at its right edge** (88 solid pixels in the last column), so the true right flare is wider than 1221 and only 35 px of room remain on the right. If the painted hem or flare extends more than about 35 px beyond the reference (and nothing may move left), the front fails the 24 px margin. Moving the figure right is limited by the same margin, and the 90 px foot tolerance does not help because the margin binds. This is the tight one. If it is a problem, the coat silhouette must not be narrowed (it is locked), so the remaining options are a slightly wider canvas (for example 1344) or a smaller figure height; it only needs deciding once the painter reports the real flare width.
2. **Back, right, left:** the references touch the canvas edge (coat or hem clipped), so their true widths are also unknown; all have more spare room than the front, but the missing clipped parts have to be painted in and re-measured.
3. The foot midpoint rule can sit off the figure's visual centre for asymmetric stances (the front's feet are left of the silhouette centre); it is a G2 rule and was not changed.
The underlays are enlargements for tracing placement only; none of this is native art, and no validator was run on art.
