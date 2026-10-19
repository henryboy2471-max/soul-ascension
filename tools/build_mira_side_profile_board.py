#!/usr/bin/env python3
"""Mira side-profile reference proposal: a board built ONLY from her approved frames (nothing redrawn). It ranks the approved run/dash frames by torso lean (head x vs hip x, as a share of figure height)
so the owner can pick which approved side view should anchor an upright side-profile walk. Output: assets/characters/mira/frames_proposed/side_profile/{board.png,lean.json}.
usage: tools/build_mira_side_profile_board.py"""
import glob, json, os
import numpy as np
from PIL import Image, ImageDraw
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SRC = os.path.join(REPO, "assets", "characters", "mira", "frames"); OUT = os.path.join(REPO, "assets", "characters", "mira", "frames_proposed", "side_profile")

def lean(path):
    a = np.array(Image.open(path).convert("RGBA"))[:, :, 3] > 120; ys, xs = np.nonzero(a); y0, y1 = ys.min(), ys.max(); h = y1 - y0
    def cx(lo, hi):
        m = a[int(y0 + h * lo): int(y0 + h * hi)]; c = np.nonzero(m)[1]; return c.mean() if c.size else np.nan
    return (cx(0.0, 0.14) - cx(0.50, 0.62)) / h   # head x minus hip x, per figure height (+ = head forward of the hips)

def main():
    os.makedirs(OUT, exist_ok=True); rows = []
    for anim in ("idle", "run", "dash"):
        for f in sorted(glob.glob(os.path.join(SRC, f"{anim}_*.png"))): rows.append((anim, os.path.basename(f), lean(f), f))
    json.dump([dict(anim=a, file=n, lean=round(float(l), 3)) for a, n, l, _ in rows], open(os.path.join(OUT, "lean.json"), "w"), indent=1)
    run = sorted([r for r in rows if r[0] == "run"], key=lambda r: abs(r[2]))
    cell = (258, 153); sc = 1.0; cols = 5
    tiles = run + [r for r in rows if r[0] == "dash"][:1] + [r for r in rows if r[0] == "idle"][:1]
    W = cols * (cell[0] + 6) + 6; Hh = ((len(tiles) + cols - 1) // cols) * (cell[1] + 34) + 220
    board = Image.new("RGB", (W, Hh), (255, 255, 255)); d = ImageDraw.Draw(board)
    d.text((8, 6), "MIRA SIDE-PROFILE REFERENCE PROPOSAL (proposal only; every image is an unmodified approved frame; nothing redrawn). Sorted by upright-ness of the run frames (lean = head x - hip x, per figure height).", fill=(0, 0, 0))
    notes = ["Identity locks: long dark hair with purple highlights, dark coat with gold trim, purple-tinted cape, brown skin; same outline weight and proportions (figure ~139 px tall on 258x153).",
             "Her approved idle is FRONT-facing and every approved run/dash frame is a leaning SIDE view, so no approved upright side view exists: the walk's upright side pose must be CONFIRMED by the owner, using the most upright approved side frame as the anchor.",
             f"Most upright approved run frames (candidates): " + ", ".join(f"{r[1]} (lean {r[2]:+.2f})" for r in run[:3]) + ". Front idle lean is not comparable (front view)."]
    for i, t in enumerate(notes): d.text((8, 24 + i * 14), t, fill=(60, 60, 60))
    y0 = 80
    for i, (a, n, l, f) in enumerate(tiles):
        im = Image.open(f).convert("RGBA"); bg = Image.new("RGBA", im.size, (244, 244, 240, 255)); bg.alpha_composite(im)
        x, y = 6 + (i % cols) * (cell[0] + 6), y0 + (i // cols) * (cell[1] + 34); board.paste(bg.convert("RGB"), (x, y + 16)); d.text((x, y), f"{n}  lean {l:+.2f}" + ("  <- candidate" if i < 3 else ""), fill=(0, 0, 0))
    board.crop((0, 0, W, y0 + ((len(tiles) + cols - 1) // cols) * (cell[1] + 34) + 8)).save(os.path.join(OUT, "board.png")); print("ok", [(r[1], round(float(r[2]), 3)) for r in run[:5]])
if __name__ == "__main__": main()
