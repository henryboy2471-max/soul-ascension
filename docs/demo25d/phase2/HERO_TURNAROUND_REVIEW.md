# Hero four-view turnaround candidate — Claude review (not an approval)

Staged at `assets/approved_anime/preview/hero_turnaround_candidate/` (preview only). Supplied by ChatGPT as `hero_*_turnaround_preview.png` + `preparation_metadata.json` + README. Source: one 1774x887 composite, color-keyed, cropped and enlarged; the package itself says it is *visual preparation only, not production-ready, no separated rig parts*.

## Verdict
**Do not start rigging.** The candidate is technically close to the frame contract but **depicts a different character design from approved reference 01**, while the phase brief says the turnaround must be "strictly from reference 01". Only the owner can decide whether this new design replaces reference 01. The README says it was "approved as the new visual design reference in conversation"; I cannot verify that approval from anything in the repository. If it is the new canonical design, reference 01 must be formally superseded (and the 1774x887 source sheet committed as the new reference); if not, the turnaround must be redone from reference 01.

## 1. Identity comparison against reference 01
| Element | Reference 01 (approved) | Candidate turnaround |
|---|---|---|
| Hair | short, messy black twists/locs with small gold cuffs | longer dreadlocks, high ponytail with shaved side undercut (side views), loose strands over the forehead; **no gold hair cuffs** |
| Eyes | amber | dark brown (front); yellow-green in the right-facing view — **inconsistent across views** |
| Coat | black hooded long coat, **gold** trim and glowing gold hardware, gold-lined hood | black hooded coat with gold trim but **red** lining/collar and red hood interior; no glowing gold hardware |
| Under layer | black short-sleeve layer | **white** t-shirt |
| Accessories | gold hoop earring, cross-body strap with gold-framed pouch, gold chain/pendant detail | gold pendant necklaces, small stud earring, **brown leather belts and pouches**, thigh pouches |
| Arms | armoured gold-trimmed forearm bracers, fingerless gloves with gold knuckle studs | **white bandage wraps**, fingerless gloves with small gold plates |
| Emblem | gold diamond emblem on sleeve and large on back | diamond on sleeve (side views) but the **back emblem is a circle/crosshair glyph**, not the diamond |
| Boots | chunky black-and-gold boots | black/gold boots with **red cuffs and white soles** |
| Palette | near-black + gold + grey | near-black + gold + **red + white + brown** |
Same: dark-brown skin, young lean athletic build, black coat/cargo trousers, long coat silhouette. Overall this is a re-design, not a faithful turnaround, so it breaks "preserve approved faces, hairstyles, accessories and costumes".

## 2. Technical findings (measured in Python)
- All four: 576x1152, RGBA, alpha 0-255, transparent corners, no #00FF00 residue.
- Standing height 997-999 px; lowest solid pixel y=1085-1087 (baseline 1088 +/-4 OK); content margins >= 44 px left/right, top y=88. Silhouette widths: front 486, back 458, left 356, right 424 px.
- **Left is not a mirror of right** (silhouette IoU 0.69 against the mirrored right; mean pixel difference 19) — consistent with the "four genuine views" decision.
- Visual issues to fix before use: faint dotted/dashed matte-artifact line near the top (y~88) in all four images; soft/upscaled detail (single enlarged composite); fringe artifacts around coat edges and boots; eye colour mismatch between views; the foot spacing differs between views.
- File-to-view mapping is by content (back, front, faces-left, faces-right); the metadata lists panels in front/right/back/left order, so confirm the mapping before anything is renamed for production.
- Not rig-ready: no separated parts, no painted occluded joints, no native-resolution master.

## 3. Status after this review
Hero turnaround: **MISSING (candidate received, not approved)**. Imani, portraits, NPCs, environment layers: unchanged, MISSING. `tools/validate_approved_art.py --root .` remains BLOCKED (verified). Four unidentified cast portraits stay unassigned.

## 4. Decisions / next steps
1. Owner: is this candidate design the new canonical Hero, replacing reference 01? (yes -> supersede ref 01 in writing and commit the source sheet; no -> ChatGPT redoes the turnaround strictly from ref 01.)
2. Either way ask for a native-resolution (not enlarged) re-render, clean matte, consistent eye colour/hair across all four views, correct back emblem, and no dotted artifacts, delivered per `ART_BRIEFS.md` brief A.
3. Rigging (brief B) starts only after the owner visually approves the corrected turnaround.
