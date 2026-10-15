#!/usr/bin/env python3
"""Review images for the tram-track insert (REVIEW ONLY): camera 0/400/800/1220 composites, left/right end sweeps, 6x wheel-contact zoom, HUD and prop-slot numbers.
Usage: python3 tools/render_track_review.py"""
import importlib.util
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("v", ROOT / "tools/validate_env_plates.py"); V = importlib.util.module_from_spec(spec); spec.loader.exec_module(V)
D = ROOT / "assets/environment/neon_district"; R = ROOT / "docs/visual_redesign/environment_review"
INS_X0, INS_X1, RAIL_ROW = 862, 2092, 291     # insert span (delivered px on plate_street) and the wheel-contact row
WHEELS = [(1049, 1086), (1155, 1184), (1771, 1801), (1869, 1906)]
pl = {n: V.load(D, n) for n in V.PLATES}; tr = V.load(D, V.PROP_TRAM[0])
frame = lambda c: Image.fromarray((V.composite(pl, tr, c) * 255).astype("uint8"))
def label(im, t):
    dr = ImageDraw.Draw(im); dr.rectangle((0, 0, len(t) * 6 + 8, 14), fill=(0, 0, 0)); dr.text((4, 2), t, fill=(255, 255, 255)); return im
def grid(tiles, cols, tw, th, path):
    sh = Image.new("RGB", (tw * cols, th * ((len(tiles) + cols - 1) // cols)))
    for i, t in enumerate(tiles): sh.paste(t, ((i % cols) * tw, (i // cols) * th))
    sh.save(path)
for c in (0, 400, 800, 1220): frame(c).resize((1280, 720), Image.LANCZOS).save(R / f"composite_cam{c}_REVIEW_ONLY.png")
tiles = []
for c in (0, 100, 200, 300, 400, 500, 570):
    x = int(INS_X0 - 1.5 * c); x0 = max(min(x - 120, 1920 - 360), 0); tiles.append(label(frame(c).crop((x0, 690, x0 + 360, 930)), f"cam {c}: left end, delivered x {x}"))
grid(tiles, 4, 360, 240, R / "track_left_end_sweep_REVIEW_ONLY.png")
tiles = []
for c in (115, 300, 500, 700, 900, 1100, 1220):
    x = int(INS_X1 - 1.5 * c); x0 = max(min(x - 180, 1920 - 360), 0); tiles.append(label(frame(c).crop((x0, 690, x0 + 360, 930)), f"cam {c}: right end (fade), delivered x {x}"))
grid(tiles, 4, 360, 240, R / "track_right_end_sweep_REVIEW_ONLY.png")
tiles = []
for c, (a, b) in ((0, WHEELS[0]), (0, WHEELS[1]), (400, WHEELS[2]), (400, WHEELS[3])):
    x0 = int(a - 1.5 * c); f = frame(c).crop((x0 - 20, 722, x0 + (b - a) + 20, 762)); f = f.resize((f.width * 6, f.height * 6), Image.NEAREST); tiles.append(label(f, f"cam {c} wheel x {a}-{b} (6x)"))
w = max(t.width for t in tiles); sh = Image.new("RGB", (w, sum(t.height for t in tiles))); y = 0
for t in tiles: sh.paste(t, (0, y)); y += t.height
sh.save(R / "track_wheel_contact_zoom_REVIEW_ONLY.png")
for c in (0, 400, 800, 1220):
    L = V.lum(V.composite(pl, tr, c)); print("cam", c, {zn: (round(float(L[int(y * 1.5):int((y + h) * 1.5), int(x * 1.5):int((x + w) * 1.5)].mean()), 2), round(V.tile_std(L[int(y * 1.5):int((y + h) * 1.5), int(x * 1.5):int((x + w) * 1.5)]), 3)) for zn, (x, y, w, h) in V.HUD_ZONES.items()})
st = np.asarray(pl["plate_street"].convert("RGB"), dtype=np.float32) / 255; Ls = V.lum(st)
for zn, (x, y, w, h) in V.SLOTS.items():
    z = Ls[int((y - 300) * 1.5):int((y - 300 + h) * 1.5), int(x * 1.5):int((x + w) * 1.5)]; print(zn, "mean", round(float(z.mean()), 2), "detail", round(V.tile_std(z), 3))
