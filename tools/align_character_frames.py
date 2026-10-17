#!/usr/bin/env python3
"""Writes pixel-exact horizontally shifted COPIES of a character's idle and walk frames so the feet sit under the same anchor in every frame.
The originals are never modified; frames.tres decides which set the game uses. Only whole-pixel shifts inside the existing canvas (no resampling, no redraw, no new art).
Anchor: the midpoint of the feet (solid leg/boot pixels in the band just above the ground shadow) is moved to the canvas centre, which is also the point a horizontally flipped sprite mirrors around, so
turning around does not shift the character either.
Mira's run cycle has the whole body sliding across the canvas (torso x 112 -> 193 source px, then snapping back at the loop point), so her run frames are aligned on the TORSO instead,
to the torso position of her standing pose.
usage: tools/align_character_frames.py hero | mira      (writes assets/characters/<name>/frames_aligned/*.png and shifts.json)"""
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

def torso_centre(im):
    """x centroid of the dark clothing pixels in the torso band (25-62% of the figure height); bright cape and hair highlights are excluded"""
    a = im[:, :, 3].astype(int); rgb = im[:, :, :3].astype(int)
    ys = np.nonzero(a > 40)[0]; y0, y1 = ys.min(), ys.max(); H = y1 - y0
    dark = (a > 120) & (rgb.max(axis=2) < 110)
    rows = np.arange(im.shape[0])[:, None]
    band = dark & (rows > y0 + H * 0.25) & (rows < y0 + H * 0.62)
    return np.nonzero(band)[1].mean()

def shift(im, dx):
    out = np.zeros_like(im)
    if dx > 0: out[:, dx:] = im[:, :-dx]
    elif dx < 0: out[:, :dx] = im[:, -dx:]
    else: out[:] = im
    return out

SPECS = {"hero": [("idle", "feet", None), ("walk", "feet", None)],
         "mira": [("run", "torso", "idle_00.png")]}   # target for the torso anchor: the torso of the standing pose

def main(who):
    src = f"assets/characters/{who}/frames"; dst = f"assets/characters/{who}/frames_aligned"; os.makedirs(dst, exist_ok=True)
    report = {}
    for anim, mode, target_frame in SPECS[who]:
        target = None
        if mode == "torso":
            target = torso_centre(np.array(Image.open(f"{src}/{target_frame}").convert("RGBA")))
        for f in sorted(glob.glob(f"{src}/{anim}_*.png")):
            im = np.array(Image.open(f).convert("RGBA")); h, w = im.shape[:2]
            c = feet_centre(im[:, :, 3]) if mode == "feet" else torso_centre(im)
            dx = int(round((w / 2.0 if mode == "feet" else target) - c))
            xs = np.nonzero(im[:, :, 3] > 0)[1]
            assert xs.min() + dx >= 0 and xs.max() + dx < w, f"{f}: shift {dx} would clip the figure"
            Image.fromarray(shift(im, dx)).save(f"{dst}/{os.path.basename(f)}")
            report[os.path.basename(f)] = {"anchor": mode, "centre_before": round(float(c), 1), "shift_px": dx, "centre_after": round(float(c + dx), 1)}
    json.dump(report, open(f"{dst}/shifts.json", "w"), indent=1)
    for k, v in report.items(): print(k, v)

if __name__ == "__main__":
    main(sys.argv[1])
