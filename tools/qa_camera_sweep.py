#!/usr/bin/env python3
"""Region-level QA over the camera sweep (review aid): mist band stability (current vs the pre-toning plate), pops in the mist band and in the track/street band, screen-edge artifacts, the foreground top edge, and the track ends.
Usage: python3 tools/qa_camera_sweep.py [--before c413a84] [--step 10]"""
import argparse, importlib.util, io, subprocess
from pathlib import Path
import numpy as np
from PIL import Image
ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("v", ROOT / "tools/validate_env_plates.py"); V = importlib.util.module_from_spec(spec); spec.loader.exec_module(V)
D = ROOT / "assets/environment/neon_district"
ap = argparse.ArgumentParser(); ap.add_argument("--before", default="c413a84"); ap.add_argument("--step", type=int, default=10); a = ap.parse_args()
pl = {n: V.load(D, n) for n in V.PLATES}; tr = V.load(D, V.PROP_TRAM[0])
old = dict(pl); old["plate_foreground"] = Image.open(io.BytesIO(subprocess.check_output(["git", "-C", str(ROOT), "show", f"{a.before}:assets/environment/neon_distr" "ict/plate_foreground.png"]))).convert("RGBA")
cams = list(range(0, 1221, a.step)); MIST = slice(870, 1080); TRACK = slice(690, 930); issues = []
def band_stats(fr):
    L = V.lum(fr[MIST]); return float(np.percentile(L, 99.9)), float(L.mean())
new_f, old_f = [], []; pk_n, pk_o, mn_n, mn_o = [], [], [], []
for c in cams:
    fn, fo = V.composite(pl, tr, c), V.composite(old, tr, c); new_f.append(fn); old_f.append(fo)
    a1, b1 = band_stats(fn); a2, b2 = band_stats(fo); pk_n.append(a1); pk_o.append(a2); mn_n.append(b1); mn_o.append(b2)
pk_n, pk_o, mn_n, mn_o = map(np.array, (pk_n, pk_o, mn_n, mn_o)); red = 1 - pk_n / pk_o
print(f"mist band p99.9 luminance: before {pk_o.mean():.3f} -> now {pk_n.mean():.3f}; reduction per frame min {red.min()*100:.0f}% / mean {red.mean()*100:.0f}% / max {red.max()*100:.0f}%")
print(f"mist band mean luminance: before {mn_o.mean():.3f} -> now {mn_n.mean():.3f} (worst frame {mn_n.max():.3f})")
if red.min() < 0.05: issues.append("some frames show almost no glow reduction")
def pops(frames, rows, name, lim=2.5):
    d = np.array([np.abs(frames[i + 1][rows] - frames[i][rows]).mean() for i in range(len(frames) - 1)]); k = 5; worst = (0, 0)
    for i, dv in enumerate(d):
        nb = np.concatenate([d[max(i - k, 0):i], d[i + 1:i + 1 + k]]); r = dv / max(np.median(nb), 1e-6)
        if r > worst[0]: worst = (r, cams[i])
    print(f"{name}: max frame-change ratio vs neighbours {worst[0]:.2f} at camera {worst[1]} (limit {lim})")
    if worst[0] > lim: issues.append(f"{name} pop at camera {worst[1]}")
pops(new_f, MIST, "mist band"); pops(new_f, TRACK, "track/street band"); pops(new_f, slice(0, 870), "scene above the mist")
# screen edges: first/last 6 columns vs the next 40, whole height
worst = 0
for fr in (new_f[0], new_f[-1]):
    L = V.lum(fr)
    for e in (L[:, :6].mean(), L[:, -6:].mean()): pass
    worst = max(worst, abs(L[:, :6].mean() - L[:, 6:46].mean()), abs(L[:, -6:].mean() - L[:, -46:-6].mean()))
print(f"screen-edge luminance step (first/last frame, edge 6 px vs next 40 px): {worst:.3f}")
if worst > 0.08: issues.append("screen edge differs noticeably from its neighbourhood")
# foreground top edge: row step at the top of the foreground (screen y 580 -> delivered 870)
steps = [float(np.abs(V.lum(f)[872] - V.lum(f)[866]).mean()) for f in new_f]; base = [float(np.abs(V.lum(f)[880] - V.lum(f)[874]).mean()) for f in new_f]
print(f"foreground top edge: row-step at y 580 {np.mean(steps):.4f} vs 6 rows further down {np.mean(base):.4f} (a hard edge would be far larger)")
if np.mean(steps) > 2.5 * max(np.mean(base), 1e-4): issues.append("foreground top edge is a visible line")
# track ends: luminance jump across the girder's left start and right fade, per camera where visible
for nm, wx in (("left start", 862), ("right fade end", 2092)):
    vals = []
    for c, f in zip(cams, new_f):
        x = int(wx - 1.5 * c)
        if 40 < x < 1880: L = V.lum(f); vals.append(float(np.abs(L[741:790, x + 3].mean() - L[741:790, x - 3].mean())))
    print(f"track {nm}: luminance step across the end, mean {np.mean(vals):.3f} max {np.max(vals):.3f} over {len(vals)} cameras")
# contact sheet of the mist band as the camera moves (bottom 200 px of the frame, current plates), 9 cameras, 2 columns
from PIL import ImageDraw
pick = [0, 150, 300, 450, 600, 750, 900, 1050, 1220]; tiles = []
for c in pick:
    j = min(range(len(cams)), key=lambda q: abs(cams[q] - c)); t = Image.fromarray((new_f[j][870:1080] * 255).astype("uint8")).resize((800, 131), Image.LANCZOS)
    dr = ImageDraw.Draw(t); dr.rectangle((0, 0, 190, 13), fill=(0, 0, 0)); dr.text((3, 1), f"cam {cams[j]}: glow -30%, haze s9", fill=(255, 255, 255)); tiles.append(t)
sh = Image.new("RGB", (1600, 131 * 5))
for i, t in enumerate(tiles): sh.paste(t, ((i % 2) * 800, (i // 2) * 131))
sh.save(ROOT / "docs/visual_redesign/environment_review/mist_band_sweep_REVIEW_ONLY.png")
print("QA:", "ISSUES: " + "; ".join(issues) if issues else "no defects found")
