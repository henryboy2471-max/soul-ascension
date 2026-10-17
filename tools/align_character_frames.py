#!/usr/bin/env python3
"""Writes pixel-exact horizontally shifted COPIES of a character's idle and walk frames so the feet sit under the same anchor in every frame.
The originals are never modified; frames.tres decides which set the game uses. Only whole-pixel shifts inside the existing canvas (no resampling, no redraw, no new art).
Anchor: the midpoint of the feet (solid leg/boot pixels in the band just above the ground shadow) is moved to the canvas centre, which is also the point a horizontally flipped sprite mirrors around, so
turning around does not shift the character either.
usage: tools/align_character_frames.py hero      (writes assets/characters/hero/frames_aligned/*.png and shifts.json)"""
import glob, json, os, sys
import numpy as np
from PIL import Image

def feet_centre(a):
    """midpoint (source px) of the left-most and right-most solid pixel columns in the band just above the ground shadow"""
    solid = a > 200
    ys = np.nonzero(solid)[0]; y1 = ys.max()
    band = solid.copy(); band[:y1 - 16, :] = False; band[y1 - 2:, :] = False
    cols = np.nonzero(band.sum(axis=0) >= 2)[0]
    return (cols.min() + cols.max()) / 2.0

def shift(im, dx):
    out = np.zeros_like(im)
    if dx > 0: out[:, dx:] = im[:, :-dx]
    elif dx < 0: out[:, :dx] = im[:, -dx:]
    else: out[:] = im
    return out

def main(who, anims=("idle", "walk")):
    src = f"assets/characters/{who}/frames"; dst = f"assets/characters/{who}/frames_aligned"; os.makedirs(dst, exist_ok=True)
    report = {}
    for anim in anims:
        for f in sorted(glob.glob(f"{src}/{anim}_*.png")):
            im = np.array(Image.open(f).convert("RGBA")); h, w = im.shape[:2]
            c = feet_centre(im[:, :, 3]); dx = int(round(w / 2.0 - c))
            xs = np.nonzero(im[:, :, 3] > 0)[1]
            assert xs.min() + dx >= 0 and xs.max() + dx < w, f"{f}: shift {dx} would clip the figure"
            Image.fromarray(shift(im, dx)).save(f"{dst}/{os.path.basename(f)}")
            report[os.path.basename(f)] = {"feet_centre_before": round(float(c), 1), "shift_px": dx, "feet_centre_after": round(float(c + dx), 1)}
    json.dump(report, open(f"{dst}/shifts.json", "w"), indent=1)
    for k, v in report.items(): print(k, v)

if __name__ == "__main__":
    main(sys.argv[1])
