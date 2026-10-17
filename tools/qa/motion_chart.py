#!/usr/bin/env python3
"""Before/after chart from two motion_browser.cjs captures of the same episode (Pillow only).
usage: motion_chart.py before.json after.json out.png"""
import json, sys
from PIL import Image, ImageDraw
B, A, OUT = sys.argv[1:4]

def series(path, walk, idle, col, world=False):
 d = {s["seg"]: s["tr"] for s in json.load(open(path))["out"]}
 tr = d[walk] + d[idle]; t = 0.0; xs = []; ys = []
 for i, r in enumerate(tr):
  t += r[0] / 1000.0; xs.append(t)
  ys.append(r[col] if not world else r[col] + r[1])
 return xs, ys

def panel(img, box, title, curves, ylabel, yconv=None):
 dr = ImageDraw.Draw(img); x0, y0, x1, y1 = box
 dr.rectangle(box, outline=(120, 120, 140)); dr.text((x0 + 6, y0 + 4), title, fill=(240, 240, 240))
 allx = [x for c in curves for x in c[1]]; ally = [y for c in curves for y in c[2]]
 tx = (min(allx), max(allx)); ty = (min(ally), max(ally) + 1e-6)
 for name, xs, ys, col in curves:
  pts = [(x0 + 8 + (x - tx[0]) / (tx[1] - tx[0]) * (x1 - x0 - 16), y1 - 22 - (y - ty[0]) / (ty[1] - ty[0]) * (y1 - y0 - 50)) for x, y in zip(xs, ys)]
  dr.line(pts, fill=col, width=2)
 dr.text((x0 + 6, y1 - 16), f"{ylabel}   y {ty[0]:.0f}..{ty[1]:.0f}   t 0..{tx[1]:.1f} s", fill=(170, 170, 190))
 for k, (name, _, _, col) in enumerate(curves): dr.text((x1 - 150, y0 + 6 + 14 * k), name, fill=col)

img = Image.new("RGB", (1200, 800), (24, 26, 40)); RED = (255, 110, 110); GRN = (110, 230, 140)
# hero screen x from the moment it walks right until it has stood still for a while
xb, yb = series(B, "right", "idle_after_right", 3); xa, ya = series(A, "right", "idle_after_right", 3)
panel(img, (10, 10, 590, 390), "Hero on-screen x: walk right, release, stand", [("before", xb, yb, RED), ("after", xa, ya, GRN)], "px")
# companion world x speed during the whole 'left' reversal
def speed(path):
 d = {s["seg"]: s["tr"] for s in json.load(open(path))["out"]}; tr = d["left"]; t = 0.0; xs = []; ys = []
 for i in range(3, len(tr)):
  dt = sum(tr[k][0] for k in range(i - 2, i + 1)) / 1000.0; t += tr[i][0] / 1000.0
  xs.append(t); ys.append(abs((tr[i][5] + tr[i][1]) - (tr[i - 3][5] + tr[i - 3][1])) / dt if dt else 0)
 return xs, ys
sb, sa = speed(B), speed(A)
panel(img, (610, 10, 1190, 390), "Companion speed after the hero turns around (px/s; hero walks 300)", [("before", sb[0], sb[1], RED), ("after", sa[0], sa[1], GRN)], "px/s")
# slow walker per-frame step in the idle segment
def steps(path):
 d = {s["seg"]: s["tr"] for s in json.load(open(path))["out"]}; tr = d["idle_start"]; xs = []; ys = []; t = 0.0
 for i in range(1, len(tr)):
  t += tr[i][0] / 1000.0; xs.append(t); ys.append(abs(tr[i][6] - tr[i - 1][6]))
 return xs, ys
tb, ta = steps(B), steps(A)
panel(img, (10, 410, 590, 790), "Slow pedestrian: px moved on screen per frame (camera still)", [("before", tb[0], tb[1], RED), ("after", ta[0], ta[1], GRN)], "px/frame")
img.save(OUT)
