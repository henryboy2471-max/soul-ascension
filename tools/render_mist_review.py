#!/usr/bin/env python3
"""Review images for the foreground-mist treatment "glow -30%, haze sigma 9" (REVIEW ONLY): before/after strips at cameras 0/400/800/1220 and full frames at 0 and 400.
BEFORE = the plate_foreground committed at --before (default c413a84, the version without mist toning).   Usage: python3 tools/render_mist_review.py [--before c413a84]"""
import argparse, importlib.util, io, subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("v", ROOT / "tools/validate_env_plates.py"); V = importlib.util.module_from_spec(spec); spec.loader.exec_module(V)
D = ROOT / "assets/environment/neon_district"; R = ROOT / "docs/visual_redesign/environment_review"; TAG = "glow -30%, haze sigma 9"
ap = argparse.ArgumentParser(); ap.add_argument("--before", default="c413a84"); a = ap.parse_args()
pl = {n: V.load(D, n) for n in V.PLATES}; tr = V.load(D, V.PROP_TRAM[0])
old = dict(pl); old["plate_foreground"] = Image.open(io.BytesIO(subprocess.check_output(["git", "-C", str(ROOT), "show", f"{a.before}:assets/environment/neon_district/plate_foreground.png"]))).convert("RGBA")
def frame(p, c): return Image.fromarray((V.composite(p, tr, c) * 255).astype("uint8")).resize((1280, 720), Image.LANCZOS)
def label(im, t):
    dr = ImageDraw.Draw(im); dr.rectangle((0, 0, len(t) * 6 + 8, 14), fill=(0, 0, 0)); dr.text((4, 2), t, fill=(255, 255, 255)); return im
def strips(cams, path):
    sh = Image.new("RGB", (1280, 200 * 2 * len(cams)))
    for i, c in enumerate(cams):
        sh.paste(label(frame(old, c).crop((0, 520, 1280, 720)), f"cam {c} BEFORE (no mist toning, {a.before})"), (0, 400 * i))
        sh.paste(label(frame(pl, c).crop((0, 520, 1280, 720)), f"cam {c} SELECTED: {TAG}"), (0, 400 * i + 200))
    sh.save(path)
strips((0, 400), R / "mist_glow30_haze9_compare_cam0_400_REVIEW_ONLY.png"); strips((800, 1220), R / "mist_glow30_haze9_compare_cam800_1220_REVIEW_ONLY.png")
for c in (0, 400): label(frame(pl, c), f"cam {c}: {TAG}").convert("RGB").save(R / f"mist_glow30_haze9_cam{c}_full_REVIEW_ONLY.jpg", quality=90)
for c in (0, 400, 800, 1220): frame(pl, c).save(R / f"composite_cam{c}_REVIEW_ONLY.png")
for c in (0, 400, 800, 1220):
    L = V.lum(V.composite(pl, tr, c)); print("cam", c, {zn: (round(float(L[int(y * 1.5):int((y + h) * 1.5), int(x * 1.5):int((x + w) * 1.5)].mean()), 2), round(V.tile_std(L[int(y * 1.5):int((y + h) * 1.5), int(x * 1.5):int((x + w) * 1.5)]), 3)) for zn, (x, y, w, h) in V.HUD_ZONES.items()})
f_old, f_new = (np.asarray(p["plate_foreground"]).astype(float) / 255 for p in (old, pl)); m = f_old[..., 3] > .3
Lo, Ln = V.lum(f_old[..., :3])[m], V.lum(f_new[..., :3])[m]; print(f"foreground luminance: peak {Lo.max():.3f} -> {Ln.max():.3f} ({100 * (1 - Ln.max() / Lo.max()):.0f}% lower), mean {Lo.mean():.3f} -> {Ln.mean():.3f}")
rows = slice(int(.75 * f_old.shape[0]), None); d = np.abs(f_new[rows, :, :3] - f_old[rows, :, :3]); print(f"lowest 25% of rows (reflections): mean abs RGB change {d.mean():.4f}")
