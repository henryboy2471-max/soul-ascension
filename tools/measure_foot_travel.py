#!/usr/bin/env python3
"""Does a walk cycle plant its feet? Measures, frame by frame, how far each PLANTED foot moves relative to the body, and compares it with what the ground speed requires.
A planted foot (its sole on the ground row) must travel BACKWARD relative to the body by speed / (fps x display_scale) source px per frame, or it will skate over the ground.
usage: tools/measure_foot_travel.py <frames_dir> [anim=walk] [--speed 90] [--fps 10] [--scale 1.889]
Foot x is measured in solid leg/boot columns just above the ground shadow; body x is the dark-clothing torso centroid, so alignment shifts of whole frames do not matter."""
import argparse, glob
import numpy as np
from PIL import Image

def analyse(path):
    im = np.array(Image.open(path).convert("RGBA")).astype(int); a = im[:, :, 3]; rgb = im[:, :, :3]
    solid = a > 200; ys = np.nonzero(solid)[0]; y1 = ys.max(); y0 = np.nonzero(a > 40)[0].min(); H = y1 - y0
    dark = (a > 120) & (rgb.max(axis=2) < 110); rows = np.arange(im.shape[0])[:, None]
    torso = np.nonzero(dark & (rows > y0 + H * 0.25) & (rows < y0 + H * 0.62))[1].mean()
    band = solid.copy(); band[:y1 - 12, :] = False; band[y1 - 1:, :] = False
    cols = np.nonzero(band.sum(axis=0) >= 1)[0]; groups = []; s = cols[0]; p = cols[0]
    for c in cols[1:]:
        if c - p > 3: groups.append((s, p)); s = c
        p = c
    groups.append((s, p)); feet = []
    for g in [g for g in groups if g[1] - g[0] >= 5]:
        low = np.nonzero(solid[:, g[0]:g[1] + 1].any(axis=1))[0].max()
        feet.append(((g[0] + g[1]) / 2.0 - torso, low >= y1 - 1))   # (x relative to the torso, planted?)
    return feet

if __name__ == "__main__":
    ap = argparse.ArgumentParser(); ap.add_argument("dir"); ap.add_argument("anim", nargs="?", default="walk")
    ap.add_argument("--speed", type=float, default=90.0); ap.add_argument("--fps", type=float, default=10.0); ap.add_argument("--scale", type=float, default=204 / 108)
    a = ap.parse_args()
    files = sorted(glob.glob(f"{a.dir}/{a.anim}_*.png")); need = a.speed / (a.fps * a.scale)
    data = [analyse(f) for f in files]
    print(f"{len(files)} frames of '{a.anim}'; ground {a.speed:.0f} px/s at {a.fps:.1f} fps and display scale {a.scale:.2f} needs a planted foot to move BACK {need:.1f} source px per frame")
    travel = []
    for i, feet in enumerate(data):
        nxt = data[(i + 1) % len(data)]
        for x, planted in feet:
            if not planted: continue
            # follow the same foot into the next frame: the nearest planted foot within 14 px
            cand = [(abs(x2 - x), x2) for x2, p2 in nxt if p2 and abs(x2 - x) < 14]
            if cand: travel.append(min(cand)[1] - x)
        print(f"  frame {i:02d} feet (x from torso, planted): " + ", ".join(f"{x:6.1f}{'*' if p else ' '}" for x, p in feet))
    if travel:
        back = [-t for t in travel]; print(f"planted-foot travel per frame (positive = backward): mean {np.mean(back):.2f}, median {np.median(back):.2f}, max {max(back):.2f} source px")
        print(f"=> planted feet move {100 * np.mean(back) / need:.0f}% of what the ground requires: roughly {max(0, 100 - 100 * np.mean(back) / need):.0f}% of the ground speed shows as foot skate")
    else: print("no planted foot could be followed between frames")
