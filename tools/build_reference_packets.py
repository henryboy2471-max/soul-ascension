#!/usr/bin/env python3
"""Builds the final-art reference packet for each proposed cycle: reference_packet.json (approved/reference files with sha256, role, status; originals are referenced, never copied or edited),
reference_board.png (reference views + extracted palette + the pose guides), palette.json, and GENERATION_INSTRUCTIONS.md. Run tools/walk_cycle_sketch.py first.
usage: tools/build_reference_packets.py"""
import hashlib, json, os
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.normpath(os.path.join(HERE, ".."))
A = "assets/approved_anime/review/echo_v2_review"; R2 = A + "/round2_consistency_pass"
ECHO_REFS = [
    (R2 + "/echo_v2_r2_right_facing_360x887_REVIEW_ONLY.png", "primary side reference (the walk/run is drawn facing right)", "REVIEW ONLY; soft alpha; cropped at left/right edges"),
    (R2 + "/echo_v2_r2_left_facing_434x887_REVIEW_ONLY.png", "far-side arm/leg and left-forearm band check", "REVIEW ONLY"),
    (R2 + "/echo_v2_r2_front_530x887_REVIEW_ONLY.webp", "front: costume, chain/pendant, brow mark; ponytail not clearly visible", "REVIEW ONLY"),
    (R2 + "/echo_v2_r2_back_450x887_REVIEW_ONLY.png", "back: winged-diamond emblem, ponytail, rear vent lining (cape motion)", "REVIEW ONLY"),
    (A + "/echo_v2_four_view_composite_1774x887_REVIEW_ONLY.webp", "all four views from one generation (round 1)", "REVIEW ONLY; superseded in detail by round 2"),
    ("docs/demo25d/phase2/ECHO_V2_DESIGN_AUTHORITY.md", "written appearance lock and consistency rules", "authoritative text"),
]
MIRA_REFS = [
    ("assets/_incoming/mira/mira_sprite_sheet.png", "approved original sprite sheet (idle 16, run 15, dash 6 cells; 1774x887 total, so a cell is low resolution)", "approved in-game source"),
    ("assets/characters/mira/frames/idle_00.png", "approved upright standing pose (258x153 canvas, feet on the bottom row)", "approved in-game frame"),
    ("assets/characters/mira/frames/run_00.png", "approved run pose (note: leaned forward, unlike her idle)", "approved in-game frame"),
    ("assets/characters/mira/frames/run_07.png", "approved run pose, mid-cycle", "approved in-game frame"),
    ("assets/characters/mira/frames/dash_00.png", "approved dash pose (cape and coat motion reference)", "approved in-game frame"),
    ("assets/approved_anime/reference/02_cast_portrait_montage_2x2.png", "cast montage; [Unverified] whether it contains Mira", "reference, character assignment unconfirmed"),
]
SETS = {  # key: (character, anim folder, refs, palette source, canvas note)
    "echo_walk": ("hero", "walk", ECHO_REFS, R2 + "/echo_v2_r2_right_facing_360x887_REVIEW_ONLY.png"),
    "echo_run": ("hero", "run", ECHO_REFS, R2 + "/echo_v2_r2_right_facing_360x887_REVIEW_ONLY.png"),
    "mira_walk": ("mira", "walk", MIRA_REFS, "assets/characters/mira/frames/idle_00.png"),
    "mira_run": ("mira", "run", MIRA_REFS, "assets/characters/mira/frames/idle_00.png"),
}
IDENTITY = {
    "hero": ["Echo V2 (owner design authority `docs/demo25d/phase2/ECHO_V2_DESIGN_AUTHORITY.md`): lean athletic, dark-brown skin, about 7.5 heads tall, composed intense expression, warm brown eyes.",
             "Hair: black locs with gold beads, HIGH PONYTAIL with a gold band (same length every frame), loose forehead locs, side undercut, gold earring. Scar/brow mark: the owner listed a scar; the docs list it as unconfirmed, see missing assets.",
             "Black turtleneck, gold chain with large gold diamond pendant, black long hooded coat with RED lining, gold-tipped hem corners, split rear vent (red lining, gold trim) that carries the cape motion.",
             "Rolled sleeves with red cuffs and black buckled straps, red-and-gold diamond sleeve patches, black fingerless gloves with gold plates, dark FOREARM BAND on the LEFT forearm only.",
             "Red belts with gold buckles, red-striped black trousers, red thigh straps, black-and-red boots with RED SOLES. Palette: black, red, gold, brown skin. Same outline weight and shading as the approved art."],
    "mira": ["Mira as in the approved sprite sheet and in-game frames: dark long hair with purple highlights, dark coat with gold trim and a purple-tinted cape, brown skin (in-game skin tone `#9a6a52`, hair `#2b2233`, coat `#2b3350`, accent gold `#ffd86b`, overlay `#c27bff` per `scripts/world/explore.gd`).",
             "Keep her upright idle posture, her proportions (figure about 139 px tall on the 258x153 canvas) and her outline weight. The walk is keyed to her UPRIGHT idle; the run may lean about 10 degrees.",
             "No new costume pieces, no recolouring, no redesign."],
}

def sha(p):
    h = hashlib.sha256(); h.update(open(os.path.join(REPO, p), "rb").read()); return h.hexdigest()

def palette(path, n=12):
    im = Image.open(os.path.join(REPO, path)).convert("RGBA"); px = [p for p in im.getdata() if p[3] > 200]
    if not px: return []
    q = Image.new("RGB", (len(px), 1)); q.putdata([p[:3] for p in px]); q = q.quantize(colors=n, method=Image.MEDIANCUT)
    pal = q.getpalette()[: 3 * n]; counts = sorted(q.getcolors(), reverse=True)
    return ["#%02x%02x%02x" % tuple(pal[3 * i: 3 * i + 3]) for _, i in counts]

def board(key, refs, pal, out, guide_sheet):
    tiles = []
    for p, role, st in refs:
        if p.endswith((".png", ".webp")):
            im = Image.open(os.path.join(REPO, p)).convert("RGBA"); k = 300 / im.height if im.height > 300 else (2 if im.height < 160 else 1)
            im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS if k < 1 else Image.NEAREST)
            bg = Image.new("RGBA", im.size, (245, 245, 240, 255)); bg.alpha_composite(im); tiles.append((bg.convert("RGB"), os.path.basename(p)[:40]))
    W = 1500; x = y = 8; rowh = 0; placed = []
    for im, name in tiles:
        if x + im.width > W: x = 8; y += rowh + 22; rowh = 0
        placed.append((im, name, x, y)); x += im.width + 8; rowh = max(rowh, im.height)
    y += rowh + 30; gs = Image.open(guide_sheet).convert("RGB"); gs = gs.resize((W - 16, int(gs.height * (W - 16) / gs.width)))
    H = y + 50 + gs.height + 20; board_im = Image.new("RGB", (W, H), (255, 255, 255)); d = ImageDraw.Draw(board_im)
    d.text((8, 0), f"{key}: REFERENCE BOARD (derived image; originals untouched). Identity references on top, extracted palette, then the approved pose guides.", fill=(0, 0, 0))
    for im, name, px_, py in placed: board_im.paste(im, (px_, py + 12)); d.text((px_, py), name, fill=(80, 80, 80))
    for i, c in enumerate(pal): d.rectangle([8 + i * 60, y, 64 + i * 60, y + 24], fill=c); d.text((10 + i * 60, y + 27), c, fill=(0, 0, 0))
    board_im.paste(gs, (8, y + 48)); board_im.save(out)

def instructions(key, ch, anim, params, refs, pal):
    p = params; fl = p["foot_x_from_pelvis_per_frame"]; lift = p["foot_lift_src_px_per_frame"]["leg_A"]; run = anim == "run"
    rows = "\n".join(f"| {i + 1} | {fl['leg_A'][i]:+.1f} | {lift[i]:.1f} | {fl['leg_B'][i]:+.1f} | {p['pelvis_up_src_px'][i]:+.1f} |" for i in range(8))
    return f"""# Final-art instructions: {key} ({ch} {anim})
Status: NOT STARTED. These instructions and the reference packet are preparation only; nothing is wired into the game and the pose sketches are guides, never final art.

## Deliverable
- 8 transparent PNG frames `{anim}_00.png` .. `{anim}_07.png` in this folder, canvas **{p['canvas'][0]}x{p['canvas'][1]}**, character drawn facing right, loops seamlessly, plays at **{p['fps']} fps** ({p['cycle_seconds']:.2f} s per cycle) at ground speed **{p['ground_speed_px_s']:.0f} px/s**.
- Figure height about {p['figure_height_src_px']} px; the planted sole sits on the bottom row; the pelvis x is the canvas centre (x = {p['canvas'][0] // 2}) in every frame.
- Screen scale {p['screen_scale']}: the cycle must keep the current on-screen size.

## Foot rule (the whole point)
A planted foot moves BACK **{p['planted_foot_travel_src_px_per_frame']} px per frame** relative to the pelvis; one step covers {p['step_length_src_px']} px. Foot x is measured from the pelvis (+ = forward); lift is height above the ground. Leg B is leg A shifted by four frames.
| frame | leg A foot x | leg A lift | leg B foot x | pelvis height vs mean |
|---|---|---|---|---|
{rows}
{'Run: contact on frames 1 and 5, mid-stance on 2 and 6, both feet airborne on 3-4 and 7-8, torso lean about 10 degrees, arms bent and pumping.' if run else 'Walk: contact (1, 5), down (2, 6), passing (3, 7), up (4, 8); pelvis bob at most 2% of leg length; torso lean 0-2 degrees; opposite arm swings with each leg.'}
The pose guides for each frame are `sketch_00..07.png` (stick figure over the reference silhouette, pelvis axis in red); `contact_sheet.png` and `compare_*.gif` show them at gameplay speed.

## Identity (must not change)
""" + "\n".join("- " + t for t in IDENTITY[ch]) + f"""

Extracted palette (from the reference, for checking only): {', '.join(pal)}

## Reference packet (originals are referenced by path and sha256 in `reference/reference_packet.json`, never copied or edited)
""" + "\n".join(f"- `{r[0]}`: {r[1]} ({r[2]})" for r in refs) + f"""
`reference/reference_board.png` shows them with the palette and the guides on one page.

## No-cost production routes, in order (no credits, subscriptions or paid APIs; none was used or attempted)
1. **Hand-drawn / pixel-painted by an artist** over `sketch_*.png` in a free editor (for example Krita, GIMP or LibreSprite), one layer per body part so poses can be re-timed. Preferred: it is the only route that keeps costume details exact.
2. **Part-rigged from native art:** once native {ch} art exists, cut it into parts (head/ponytail, torso, coat/cape, arms, legs) and pose them from `params.json`, then hand-correct. Not possible for Echo V2 until native art exists (see missing assets).
3. **Open-source local AI assistance** (the repo's earlier diagnostic, `tools/echo_v2_assisted_enlarge.py`, used a free Real-ESRGAN model): only as a disclosed, human-finished step; output must be labelled assisted, never native. Any hosted or paid generator needs the owner's explicit approval first.
Do not substitute the stick-figure guides for art; do not redraw the character; do not edit the reference files.

## Acceptance checks (run on the finished folder)
- `python3 tools/measure_foot_travel.py <this folder> {anim} --speed {p['ground_speed_px_s']:.0f} --fps {p['fps']} --scale {p['screen_scale']}`: planted travel within 25% of {p['planted_foot_travel_src_px_per_frame']} px per frame.
- Alignment: pelvis/torso centroid range at most 2 px, planted sole on the bottom row, no whole-body drift (`tools/align_character_frames.py` method).
- 8 frames, exact canvas, transparent background, loops with no pop between frame 8 and frame 1.
- Palette and outline weight compared with the reference board, then the owner's visual review of the finished animation (the final gate).
"""

def main():
    for key, (ch, anim, refs, pal_src) in SETS.items():
        d = os.path.join(REPO, "assets", "characters", ch, "frames_proposed", anim); os.makedirs(os.path.join(d, "reference"), exist_ok=True)
        params = json.load(open(os.path.join(d, "params.json"))); pal = palette(pal_src)
        pk = dict(set=key, note="originals are referenced, never copied or edited", palette_source=pal_src, palette=pal,
                  references=[dict(path=p, role=r, status=s, exists=os.path.exists(os.path.join(REPO, p)), sha256=sha(p) if os.path.exists(os.path.join(REPO, p)) else None) for p, r, s in refs])
        json.dump(pk, open(os.path.join(d, "reference", "reference_packet.json"), "w"), indent=1)
        json.dump(pal, open(os.path.join(d, "reference", "palette.json"), "w"))
        board(key, refs, pal, os.path.join(d, "reference", "reference_board.png"), os.path.join(d, "contact_sheet.png"))
        open(os.path.join(d, "GENERATION_INSTRUCTIONS.md"), "w").write(instructions(key, ch, anim, params, refs, pal))
        print(key, "packet ok,", sum(1 for r in pk["references"] if r["exists"]), "of", len(refs), "references present")
if __name__ == "__main__": main()
