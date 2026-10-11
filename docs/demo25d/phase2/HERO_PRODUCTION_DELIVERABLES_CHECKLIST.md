# Hero production deliverables checklist (authoritative design reference: `assets/approved_anime/reference/hero_reference_pack_v2/` — REFERENCE ONLY)

Status of every item below: **MISSING**. Nothing here is rigged, animated or production-ready. Rigging/animation is **forbidden until gate G2** (four native turnaround renders visually approved). No enlargement of the reference crops, no procedural/placeholder characters, no paid credits without approval. Design must not change: face, skin tone, hair (ponytail + undercut, gold ties), warm brown eyes with amber highlights, costume, emblem, proportions all as in pack v2 (`HERO_DESIGN_LOCK_AND_PRODUCTION_SPEC.md`, Revision 2).

## G2 package — the next visual approval gate (needed first)
Folder: `assets/approved_anime/source/hero/` (staging, outside final `characters/`).
| # | File | Size / format | Requirements | Acceptance (checked by `tools/check_hero_turnaround.py` unless "visual") |
|---|---|---|---|---|
| 1 | `hero_turnaround_front_native.png` | 1152 x 2304 PNG RGBA | native render (not enlarged), figure 2000 px, head top y=176, soles y=2176, planted-foot midpoint x=576, >= 48 px margin | size exact; interior alpha 255 (>= 90% of silhouette pixels); soft-edge pixels (alpha<250) <= 8%; no #00FF00; corners transparent; head/baseline/margin/foot tolerances; visual: matches pack v2 |
| 2 | `hero_turnaround_right_native.png` | same | faces screen-right; feet staggered consistently | same + visual |
| 3 | `hero_turnaround_back_native.png` | same | shows ponytail/undercut, winged-diamond back emblem, tassel | same + visual |
| 4 | `hero_turnaround_left_native.png` | same | genuinely drawn left side, **not a mirror** | same + not an exact mirror of right + visual |
| 5 | `hero_face_detail_sheet.png` | long side >= 2048, PNG | front, both profiles, back-of-head, eyes close-up (warm brown + amber highlights) | exists, size; visual |
| 6 | `hero_costume_detail_sheet.png` | long side >= 2048, PNG | back emblem, sleeve patches/straps, pendant, glove plates, belts/buckles, boots (soles) | exists, size; visual |
| 7 | `hero_turnaround_{front,right,back,left}_matte_green.png` (optional but requested) | 1152 x 2304 | same renders on flat #00FF00 | not validated; provenance aid |
| 8 | `PROVENANCE.md` | text | tool, date, prompts, seeds, manual edits, who approved | present |
Cross-view rules (visual, owner decides): one eye colour; ponytail/undercut identical; bandage wraps resolved (recommend both forearms); sleeve patches and straps placed identically in every view they appear; same scale across the four views (figure heights within 20 px); identical costume details.
**Visual review package I will assemble once files exist** (no assembly before then): the four renders side by side against pack v2, a 400% edge/fringe crop of each view on dark and light backdrops, the same figures reduced to gameplay size (about 250 px tall at 1x) over a neutral wet-street colour block to check face/readability, the checker output, and a list of every consistency item. Gate G2 = owner approves how it looks.

## After G2 only (do not start earlier)
| Gate | Deliverable | Spec |
|---|---|---|
| G3 | `assets/approved_anime/source/hero/parts/{front,right,back,left}/<part>.png` + `rig_pivots.json` | transparent parts at 2x native scale, painted-under overlaps, pivot/parent/z-order per part (list in the design-lock doc section 5 and `HERO_RIGGING_PLAN.md`); alternate hand poses; optional blink layers |
| G4 | `assets/approved_anime/characters/hero/frames/{front,right,back,left}_{idle_00..01,walk_00..05}.png` (32 files) | 576 x 1152 RGBA, planted sole y=1088, foot midpoint x=288, 24 px margin, interior alpha 255, soft edges <= 8%; **idle exactly 2, walk exactly 6 per view**; left genuinely drawn |
| G4 | `manifest.json`, `anchor.json` (`canvas [576,1152]`, `anchor_x 288`, `baseline_y 1088`, `height_px 1000`) | exact shape enforced by `tools/validate_approved_art.py` |
| G4 | `portrait.png` (1024 x 1024 transparent) and `portrait_<expression>.png` (neutral, determined, smirk, surprised, hurt) | face matches pack v2; crisp at 172 px |
| G5 | Godot visual-checkpoint scene | only after validator STATIC CHECK PASS, manual checklist and owner approval (`INTEGRATION_ADAPTER.md`) |

## Other characters/environment (unchanged, all MISSING)
Imani set, Tier-A/B NPCs, Neon District layers and props: see `PRODUCTION_ASSET_MANIFEST.md`, `ART_BRIEFS.md`, `asset_manifest.json`. The four unlabelled portraits stay UNASSIGNED.

## Reference assets that exist (all REFERENCE ONLY)
`reference/01..05` (01 superseded for the Hero), `reference/hero_reference_pack_v2/` (authoritative Hero design), `preview/hero_turnaround_candidate/` (superseded history).

## Checks actually executed for this checkpoint vs earlier results
| Item | Executed now (this session turn) | Earlier reported only |
|---|---|---|
| `git` HEAD vs remote, clean working tree | yes: HEAD = remote = `b06f656`, clean | — |
| `python3 tools/validate_approved_art.py --root .` | yes: BLOCKED (no characters/environment assets) | — |
| `python3 tools/test_validate_approved_art.py` | yes: ALL PASS | earlier runs |
| `python3 tools/test_check_hero_turnaround.py` (new) | yes: ALL PASS | — |
| `python3 tools/check_hero_turnaround.py` on pack v2 renamed into a temp dir | yes: BLOCKED as expected (464x881 etc.; 20% soft-edge pixels; head/baseline/margin/foot failures) | — |
| Godot, gameplay tests, browser QA, demo tests (41/41, 12/12, 19 suites) | **not run** (no Godot, no gameplay changed) | results on `demo/neon-district-2.5d` remain valid for that branch only |
