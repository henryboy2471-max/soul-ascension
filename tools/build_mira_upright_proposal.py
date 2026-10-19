#!/usr/bin/env python3
"""Mira upright side-view proposal sheet for owner review: approved run_14 (closest approved side pose to standing) and approved front idle, magnified detail crops of her identity features taken from the approved frames,
and the approved walk pose guides (contact, passing) laid over run_14's silhouette. Guides are not art; no new pose has been drawn. Output: assets/characters/mira/frames_proposed/side_profile/upright_proposal.png
usage: tools/build_mira_upright_proposal.py"""
import os, sys
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import walk_cycle_sketch as W
REPO = os.path.normpath(os.path.join(HERE, ".."))
SRC = os.path.join(REPO, "assets/characters/mira/frames"); OUT = os.path.join(REPO, "assets/characters/mira/frames_proposed/side_profile")
def flat(p, z=1, box=None):
    im = Image.open(p).convert("RGBA"); bg = Image.new("RGBA", im.size, (244, 244, 240, 255)); bg.alpha_composite(im); c = bg.convert("RGB")
    if box: c = c.crop(box)
    return c.resize((c.width * z, c.height * z), Image.NEAREST)
def main():
    s = dict(W.SETS["mira_walk"]); s["idle"] = ("mira/frames/run_14.png", 1)   # ghost = approved run_14 (note: its figure is ~122 px tall, the guide assumes 139)
    ghost = W.idle_ghost(s); g1 = W.sketch_frame(s, 0, ghost).convert("RGB"); g3 = W.sketch_frame(s, 2, ghost).convert("RGB")
    run14 = os.path.join(SRC, "run_14.png"); idle = os.path.join(SRC, "idle_00.png")
    tiles = [("APPROVED run_14 (anchor, lean +0.07)", flat(run14, 2)), ("APPROVED idle_00 (front, identity)", flat(idle, 2)),
             ("guide: contact (frame 1) over run_14", g1.resize((g1.width * 2, g1.height * 2), Image.NEAREST)), ("guide: passing (frame 3) over run_14", g3.resize((g3.width * 2, g3.height * 2), Image.NEAREST))]
    crops = [("run_14: hair + head x5", flat(run14, 5, (60, 20, 170, 80))), ("run_14: cape + coat x5", flat(run14, 5, (40, 60, 150, 125))), ("run_14: boots x5", flat(run14, 5, (60, 105, 170, 153))), ("idle_00: face + collar x5", flat(idle, 5, (95, 10, 165, 60)))]
    Wd = max(sum(t[1].width + 8 for t in tiles), sum(t[1].width + 8 for t in crops)) + 8; Hh = 40 + max(t[1].height for t in tiles) + 30 + max(t[1].height for t in crops) + 120
    board = Image.new("RGB", (Wd, Hh), (255, 255, 255)); d = ImageDraw.Draw(board)
    d.text((8, 4), "MIRA UPRIGHT SIDE-VIEW PROPOSAL (for review; no new pose drawn). Approved frames are unmodified (nearest-neighbour magnified). Guides show where the planted feet and pelvis must sit for the 90 px/s walk.", fill=(0, 0, 0))
    x = 8
    for n, im in tiles: d.text((x, 22), n, fill=(0, 0, 0)); board.paste(im, (x, 38)); x += im.width + 8
    y = 38 + max(t[1].height for t in tiles) + 14; x = 8
    for n, im in crops: d.text((x, y), n, fill=(0, 0, 0)); board.paste(im, (x, y + 16)); x += im.width + 8
    y += 16 + max(t[1].height for t in crops) + 10
    for i, t in enumerate(["Brief for the new upright side pose (to be drawn by an artist from these approved references, then reviewed):", "- standing/passing silhouette in the SIDE view facing right, torso upright (0-2 degree lean, unlike run_14's +0.07 and the run's 10+), 258x153 canvas, feet on the bottom row, pelvis at x=129",
                           "- same hair (long, dark, purple highlights, same length and wave), same dark coat with gold trim, same purple-tinted cape with the same cut and the same gold accents, same boots, same skin tone, same outline weight; no new costume parts", "- cape and hair settle behind her (one frame lag), as in run_14; the front idle is the colour and costume authority"]):
        d.text((8, y + i * 14), t, fill=(60, 60, 60))
    board.save(os.path.join(OUT, "upright_proposal.png")); print("ok", board.size)
if __name__ == "__main__": main()
