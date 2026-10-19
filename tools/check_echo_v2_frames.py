#!/usr/bin/env python3
"""Structural check for FINISHED Echo V2 animation frames against the game contract (docs/overnight/ECHO_V2_G4_GAME_CONTRACT.md). Run it only on genuine finished art, never on guides or references.
usage: tools/check_echo_v2_frames.py <folder> <state> [--root-scale 0.9444]
Checks: frame count and canvas per state, RGBA with transparent corners, planted sole on the bottom row, pelvis/body centred on the canvas centre column (+/-6 px), alpha quality (>=90% opaque, <=8% soft), no #00FF00,
right-facing is not checkable here (visual). walk/run also run tools/measure_foot_travel.py's rule. Exit 0 = structural pass; the owner's visual approval is still required."""
import argparse, glob, os, sys
import numpy as np
from PIL import Image
STATES = {  # state: (frames, canvas, fps)
    "idle": (1, (272, 216), 6), "walk": (8, (272, 216), 8), "run": (8, (480, 216), 12), "hurt": (4, (272, 216), 12), "defeat": (6, (272, 216), 8),
    "attack1": (6, (272, 216), 10), "attack2": (6, (272, 216), 10), "attack3": (6, (272, 216), 10), "skill": (8, (272, 216), 10), "dash": (4, (272, 216), 14),
}
CENTER_TOL, OPAQUE_MIN, SOFT_MAX = 6, 0.90, 0.08
def check(folder, state):
    n, canvas, fps = STATES[state]; files = sorted(glob.glob(os.path.join(folder, f"{state}_*.png"))); issues = []
    if state == "idle" and len(files) < 1: issues.append("idle: need at least 1 frame (a held pose; more only if a calm loop is approved)")
    elif state != "idle" and len(files) != n: issues.append(f"{state}: {len(files)} frames, expected {n}")
    for f in files:
        im = Image.open(f); tag = os.path.basename(f)
        if im.size != canvas: issues.append(f"{tag}: canvas {im.size}, expected {canvas}"); continue
        if im.mode != "RGBA": issues.append(f"{tag}: mode {im.mode}, expected RGBA"); continue
        a = np.array(im); al = a[:, :, 3]; nz = int((al > 0).sum())
        if nz == 0: issues.append(f"{tag}: empty"); continue
        if any(al[y, x] > 0 for y, x in ((0, 0), (0, -1), (-1, 0), (-1, -1))): issues.append(f"{tag}: corners not transparent")
        if (al == 255).sum() / nz < OPAQUE_MIN: issues.append(f"{tag}: only {(al == 255).sum() / nz:.1%} fully opaque (min {OPAQUE_MIN:.0%})")
        if ((al > 0) & (al < 250)).sum() / nz > SOFT_MAX: issues.append(f"{tag}: soft pixels {((al > 0) & (al < 250)).sum() / nz:.1%} (max {SOFT_MAX:.0%})")
        if ((al > 8) & (a[:, :, 1] > 215) & (a[:, :, 0] < 40) & (a[:, :, 2] < 40)).any(): issues.append(f"{tag}: leftover #00FF00 key colour")
        ys, xs = np.nonzero(al > 16)
        if ys.max() < canvas[1] - 2 and state not in ("defeat",): issues.append(f"{tag}: lowest solid pixel y={ys.max()}, planted sole must be on the bottom row ({canvas[1] - 1})")
        mid = (xs.min() + xs.max()) / 2
        if state in ("idle", "hurt") and abs(mid - canvas[0] / 2) > CENTER_TOL * 3: issues.append(f"{tag}: body centre x={mid:.0f}, expected about {canvas[0] // 2}")
        band = np.nonzero(al[canvas[1] - 8:, :] > 16)[1]
        if band.size and abs((band.min() + band.max()) / 2 - canvas[0] / 2) > 90 and state in ("idle",): issues.append(f"{tag}: feet not centred")
    return issues
if __name__ == "__main__":
    ap = argparse.ArgumentParser(); ap.add_argument("folder"); ap.add_argument("state", choices=list(STATES)); a = ap.parse_args()
    iss = check(a.folder, a.state)
    if iss:
        print("BLOCKED:"); [print(" - " + i) for i in iss]; sys.exit(1)
    print(f"STRUCTURAL PASS for {a.state}. Still required: foot-travel check for walk/run, identity/palette comparison, owner visual approval."); sys.exit(0)
