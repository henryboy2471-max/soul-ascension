#!/usr/bin/env python3
"""Mira Vey dialogue-portrait sample: one bust, five expressions (neutral, speaking, worried, determined, warm smile).
SAMPLE FOR OWNER REVIEW. Procedural 2D (same family of techniques as the approved Cantor v2.1 renderer); design follows her approved
sprite: deep-brown skin, long dark-violet curly hair with gold clips, gold armor, violet cape, violet-crimson chest gem.
Usage: python3 tools/samples/gen_mira_expressions.py OUT_DIR"""
import math, os, sys, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 4                      # supersampling
N = 512                    # output size
W = N * S
OUT = sys.argv[1] if len(sys.argv) > 1 else "."

INK = (22, 10, 34)
SKIN = (150, 98, 74)
SKIN_HI = (190, 128, 98)
SKIN_LO = (96, 58, 52)
HAIR = (44, 26, 78)
HAIR_LO = (20, 11, 44)
HAIR_HI = (126, 92, 214)
GOLD = (236, 184, 74)
GOLD_LO = (150, 98, 36)
GOLD_HI = (255, 232, 150)
VIOLET = (126, 74, 214)
VIOLET_LO = (58, 30, 112)
CRIMSON = (232, 70, 110)

def P(x, y):
    return (x * S, y * S)

def smooth(pts, it=2):
    for _ in range(it):
        out = []
        n = len(pts)
        for i in range(n):
            p, q = pts[i], pts[(i + 1) % n]
            out += [(0.75 * p[0] + 0.25 * q[0], 0.75 * p[1] + 0.25 * q[1]), (0.25 * p[0] + 0.75 * q[0], 0.25 * p[1] + 0.75 * q[1])]
        pts = out
    return pts

def layer():
    return Image.new("RGBA", (W, W), (0, 0, 0, 0))

def fillpoly(img, pts, color, alpha=1.0, soft=0, grad=None):
    if soft:
        pts = smooth(pts, soft)
    pp = [P(*p) for p in pts]
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).polygon(pp, fill=255)
    if grad:
        ys = [p[1] for p in pp]
        y0, y1 = min(ys), max(ys)
        yy = np.linspace(0, 1, img.size[1])[:, None]
        t = np.clip((np.arange(img.size[1])[:, None] - y0) / max(1, y1 - y0), 0, 1)
        arr = np.zeros((img.size[1], img.size[0], 4), np.uint8)
        for k in range(3):
            arr[:, :, k] = (grad[0][k] + (grad[1][k] - grad[0][k]) * t).astype(np.uint8)
        arr[:, :, 3] = 255
        col = Image.fromarray(arr, "RGBA")
    else:
        col = Image.new("RGBA", img.size, color + (255,))
    m = m.point(lambda v: int(v * alpha))
    col.putalpha(m)
    img.alpha_composite(col)

def stroke(img, pts, color, width, alpha=1.0, soft=0):
    if soft:
        # open-curve smoothing
        for _ in range(soft):
            out = [pts[0]]
            for i in range(len(pts) - 1):
                p, q = pts[i], pts[i + 1]
                out += [(0.75 * p[0] + 0.25 * q[0], 0.75 * p[1] + 0.25 * q[1]), (0.25 * p[0] + 0.75 * q[0], 0.25 * p[1] + 0.75 * q[1])]
            out.append(pts[-1])
            pts = out
    l = layer()
    d = ImageDraw.Draw(l)
    c = color + (int(255 * alpha),)
    pp = [P(*p) for p in pts]
    w = max(1, int(width * S))
    d.line(pp, fill=c, width=w, joint="curve")
    r = w / 2
    for p in (pp[0], pp[-1]):
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=c)
    img.alpha_composite(l)

def tapered(pts, widths):
    left, right = [], []
    n = len(pts)
    for i in range(n):
        a, b = pts[max(0, i - 1)], pts[min(n - 1, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        w = widths[i] / 2
        left.append((pts[i][0] + nx * w, pts[i][1] + ny * w))
        right.append((pts[i][0] - nx * w, pts[i][1] - ny * w))
    return left + right[::-1]

def ellipse(img, c, rx, ry, color, alpha=1.0):
    l = layer()
    ImageDraw.Draw(l).ellipse([P(c[0] - rx, c[1] - ry), P(c[0] + rx, c[1] + ry)], fill=color + (int(255 * alpha),))
    img.alpha_composite(l)

def glow(img, c, r, color, strength=1.0, blur=None):
    l = Image.new("L", img.size, 0)
    ImageDraw.Draw(l).ellipse([P(c[0] - r, c[1] - r), P(c[0] + r, c[1] + r)], fill=255)
    l = l.filter(ImageFilter.GaussianBlur((blur or r * 0.8) * S))
    l = l.point(lambda v: min(255, int(v * strength)))
    col = Image.new("RGBA", img.size, color + (255,))
    col.putalpha(l)
    img.alpha_composite(col)

def lerp(a, b, t):
    return a + (b - a) * t

def eye(img, cx, cy, side, openness, tilt, iris_dx, iris_dy, happy=False, sparkle=False):
    """Anime eye. side=-1 left (viewer's left), +1 right. openness in units; happy = closed smiling arc."""
    w = 22.0
    def top(t):   # t in [-1,1] across the eye, outer corner at side*1
        return cy - openness * (1 - t * t) ** 0.8 + tilt * t * side * 0.9
    def bot(t):
        return cy + openness * 0.32 * (1 - t * t) + tilt * t * side * 0.9
    ts = [i / 20.0 * 2 - 1 for i in range(21)]
    if happy:
        arc = [(cx + t * w * side, cy - 7.0 * (1 - t * t)) for t in ts]
        stroke(img, arc, INK, 3.6)
        flick = [(arc[-1][0], arc[-1][1]), (arc[-1][0] + side * 4.5, arc[-1][1] - 2.4)] if side > 0 else [(arc[0][0], arc[0][1]), (arc[0][0] - 4.5, arc[0][1] - 2.4)]
        stroke(img, flick, INK, 3.0)
        return
    xs = lambda t: cx + t * w * side
    lid_top = [(xs(t), top(t)) for t in ts]
    lid_bot = [(xs(t), bot(t)) for t in ts][::-1]
    fillpoly(img, lid_top + lid_bot, (244, 238, 252), grad=((250, 246, 255), (214, 204, 232)))
    # iris clipped between the lids
    ir = openness * 0.95 + 3.0
    ix, iy = cx + iris_dx, cy + iris_dy + openness * 0.05
    pts = []
    for k in range(40):
        a = 2 * math.pi * k / 40
        x, y = ix + math.cos(a) * ir * 0.92, iy + math.sin(a) * ir * 1.08
        t = max(-1, min(1, (x - cx) / (w * side))) if side != 0 else 0
        y = max(top(t) + 0.6, min(bot(t) - 0.2, y))
        pts.append((x, y))
    fillpoly(img, pts, (118, 66, 200), grad=((70, 34, 140), (206, 150, 255)))
    # inner darker ring and pupil
    fillpoly(img, [(ix + (x - ix) * 0.55, iy + (y - iy) * 0.55) for x, y in pts], (40, 18, 80), alpha=0.9)
    # lower warm glow (resonance gold) and highlights
    fillpoly(img, [(ix + (x - ix) * 0.9, iy + (y - iy) * 0.9) for x, y in pts if y > iy + ir * 0.1] or pts[:3], (255, 196, 110), alpha=0.35)
    ellipse(img, (ix - ir * 0.32, iy - ir * 0.38), ir * 0.26, ir * 0.30, (255, 255, 255), 0.95)
    ellipse(img, (ix + ir * 0.34, iy + ir * 0.34), ir * 0.12, ir * 0.12, (255, 255, 255), 0.85)
    if sparkle:
        ellipse(img, (ix, iy), ir * 0.9, ir * 0.9, (255, 205, 120), 0.12)
    # upper lid shadow and thick lash line with outer flick, lower lid hint
    shadow = [(xs(t), top(t)) for t in ts] + [(xs(t), top(t) + 3.4) for t in ts][::-1]
    fillpoly(img, shadow, (30, 12, 50), alpha=0.5)
    stroke(img, lid_top, INK, 3.8)
    outer = lid_top[-1] if side > 0 else lid_top[0]
    stroke(img, [(outer[0], outer[1] + 0.2), (outer[0] + side * 5.0, outer[1] - 2.6)], INK, 3.2)
    stroke(img, [(xs(t), bot(t) + 0.3) for t in ts[2:-2]], SKIN_LO, 0.9, 0.7)

def draw_mira(expr):
    global cx, cy
    img = layer()
    bg = layer()
    # ---- background: indigo gradient + warm lantern bokeh + violet halo behind the head
    yy = np.linspace(0, 1, W)[:, None]
    arr = np.zeros((W, W, 4), np.uint8)
    arr[:, :, 0] = (16 + 26 * yy).astype(np.uint8)
    arr[:, :, 1] = (10 + 12 * yy).astype(np.uint8)
    arr[:, :, 2] = (40 + 60 * yy).astype(np.uint8)
    arr[:, :, 3] = 255
    bg = Image.fromarray(arr, "RGBA")
    glow(bg, (256, 190), 150, (112, 74, 226), 0.75, 70)
    rnd = random.Random(5)
    for _ in range(14):
        glow(bg, (rnd.uniform(20, 492), rnd.uniform(20, 250)), rnd.uniform(8, 20), (255, 176, 90), rnd.uniform(0.25, 0.55), 6)
    img.alpha_composite(bg)

    # ---- cape collar (behind), hair mass (behind)
    fillpoly(img, [(60, 512), (40, 420), (86, 372), (170, 400), (200, 512)], VIOLET, grad=((120, 76, 214), (36, 18, 78)), soft=1)
    fillpoly(img, [(452, 512), (472, 420), (426, 372), (342, 400), (312, 512)], VIOLET, grad=((120, 76, 214), (36, 18, 78)), soft=1)
    hair_back = [(176, 240), (170, 176), (200, 118), (256, 96), (312, 118), (342, 176), (336, 240), (366, 330), (356, 430), (392, 490), (356, 512), (156, 512), (120, 490), (156, 430), (146, 330)]
    fillpoly(img, hair_back, HAIR, grad=((70, 44, 130), (16, 8, 36)), soft=2)
    # curl locks: thick S-shaped ribbons with a lit edge (clean cel hair instead of scribbles)
    rr = random.Random(11)
    for k in range(14):
        side = -1 if k % 2 == 0 else 1
        x0 = 256 + side * rr.uniform(96, 116)
        y0 = 250 + (k // 2) * 34 + rr.uniform(-6, 6)
        path = [(x0 + side * (math.sin(a) * 16 + a * 3.0), y0 + a * 19) for a in np.linspace(0, 3.2, 9)]
        shape = tapered(path, [24, 26, 24, 22, 20, 16, 12, 7, 2])
        fillpoly(img, shape, HAIR, grad=((82, 52, 150), (22, 10, 50)), soft=1)
        stroke(img, [(x - side * 6, y) for x, y in path[1:-2]], HAIR_HI, 2.4, 0.5, soft=1)
        stroke(img, [(x + side * 8, y + 2) for x, y in path[1:-2]], HAIR_LO, 3.0, 0.6, soft=1)
    # ---- body: dark underlayer, gold armor, violet-crimson chest gem
    fillpoly(img, [(150, 512), (176, 440), (230, 408), (282, 408), (336, 440), (362, 512)], (34, 20, 54), grad=((52, 32, 80), (18, 10, 34)), soft=1)
    # pauldrons
    for side in (-1, 1):
        px = 256 + side * 128
        pts = [(256 + side * 70, 420), (px - side * 10, 410), (px + side * 40, 430), (px + side * 52, 480), (px + side * 20, 512), (256 + side * 100, 512)]
        fillpoly(img, pts, GOLD, grad=(GOLD_HI, GOLD_LO), soft=2)
        stroke(img, [(px - side * 10, 414), (px + side * 38, 434), (px + side * 50, 478)], INK, 2.4, 0.9, soft=1)
        stroke(img, [(px - side * 6, 420), (px + side * 30, 438)], GOLD_HI, 1.6, 0.9, soft=1)
    # gorget and chest piece
    fillpoly(img, [(214, 410), (298, 410), (310, 458), (256, 498), (202, 458)], GOLD, grad=(GOLD_HI, GOLD_LO), soft=1)
    stroke(img, [(214, 410), (202, 458), (256, 498), (310, 458), (298, 410)], INK, 2.4, 0.9)
    glow(img, (256, 452), 26, CRIMSON, 0.9, 12)
    fillpoly(img, [(256, 436), (270, 452), (256, 470), (242, 452)], (255, 120, 160), grad=((255, 190, 210), (186, 40, 100)))
    stroke(img, [(256, 436), (270, 452), (256, 470), (242, 452), (256, 436)], INK, 1.6)
    # neck
    fillpoly(img, [(236, 334), (278, 334), (284, 410), (256, 420), (228, 410)], SKIN, grad=((SKIN[0], SKIN[1], SKIN[2]), SKIN_LO), soft=1)
    fillpoly(img, [(238, 340), (276, 340), (274, 366), (256, 376), (240, 366)], (70, 38, 40), alpha=0.5, soft=1)  # chin shadow on neck
    stroke(img, [(237, 336), (230, 408)], INK, 1.8, 0.6)
    stroke(img, [(277, 336), (283, 408)], INK, 1.8, 0.6)

    # ---- face
    face = [(196, 236), (200, 200), (222, 172), (256, 164), (290, 172), (312, 200), (316, 236), (308, 284), (286, 324), (256, 344), (226, 324), (204, 284)]
    fillpoly(img, face, SKIN, grad=((176, 118, 92), (128, 80, 62)), soft=2)
    # soft shading: right side and under the hair, light on the forehead/cheek, blush
    fillpoly(img, [(290, 174), (312, 200), (316, 236), (308, 284), (286, 324), (276, 304), (298, 256), (294, 206)], SKIN_LO, alpha=0.40, soft=2)
    fillpoly(img, [(210, 184), (256, 172), (304, 184), (294, 202), (256, 196), (218, 202)], SKIN_LO, alpha=0.32, soft=2)  # fringe shadow
    glow(img, (228, 252), 16, SKIN_HI, 0.35, 10)
    blush = {"neutral": 0.22, "speaking": 0.24, "worried": 0.12, "determined": 0.2, "smile": 0.5}[expr]
    glow(img, (214, 280), 18, (224, 104, 110), blush, 9)
    glow(img, (298, 280), 18, (224, 104, 110), blush, 9)
    # ears hidden by hair; gold earring on the right
    stroke(img, [(313, 276), (316, 296)], GOLD_HI, 2.4)
    ellipse(img, (316, 302), 5, 7, GOLD, 1.0)
    # nose
    stroke(img, [(252, 270), (248, 290), (257, 296)], SKIN_LO, 2.0, 0.8, soft=1)
    ellipse(img, (254, 280), 2.2, 3.6, SKIN_HI, 0.5)

    # ---- eyes and brows (the expression)
    cfg = {
     "neutral":    dict(open=13.5, tilt=0.0, idx=0.0, idy=0.0, brow_y=-34, brow_in=0.0, brow_arc=1.0, happy=False, spark=False),
     "speaking":   dict(open=14.0, tilt=0.0, idx=0.4, idy=0.0, brow_y=-36, brow_in=-1.0, brow_arc=1.1, happy=False, spark=False),
     "worried":    dict(open=15.5, tilt=1.0, idx=-0.5, idy=-1.2, brow_y=-37, brow_in=-6.0, brow_arc=0.4, happy=False, spark=False),
     "determined": dict(open=10.5, tilt=-1.4, idx=0.0, idy=0.4, brow_y=-30, brow_in=5.5, brow_arc=0.2, happy=False, spark=True),
     "smile":      dict(open=0, tilt=0, idx=0, idy=0, brow_y=-38, brow_in=-1.5, brow_arc=1.3, happy=True, spark=False),
    }[expr]
    for side in (-1, 1):
        cx = 256 + side * 35
        cy = 248
        eye(img, cx, cy, side, cfg["open"], cfg["tilt"], cfg["idx"], cfg["idy"], cfg["happy"], cfg["spark"])
        # eyebrow: tapered stroke; inner end (toward the nose) moves per expression
        ox = 256 + side * 60
        ix_ = 256 + side * 16
        by = 248 + cfg["brow_y"] - 6
        pts = [(ix_, by + cfg["brow_in"]), (lerp(ix_, ox, 0.5), by - 3 * cfg["brow_arc"] + cfg["brow_in"] * 0.3), (ox, by + 1.5 - cfg["brow_in"] * 0.2)]
        shape = tapered([(pts[0][0], pts[0][1])] + [(lerp(pts[0][0], pts[1][0], t), lerp(pts[0][1], pts[1][1], t)) for t in (0.5,)] + [pts[1]] + [(lerp(pts[1][0], pts[2][0], 0.5), lerp(pts[1][1], pts[2][1], 0.5)), pts[2]], [7.0, 6.6, 5.8, 4.0, 2.0])
        fillpoly(img, shape, (30, 16, 46), soft=1)
    if expr == "worried":
        # sweat drop at the temple
        fillpoly(img, [(306, 214), (313, 232), (306, 244), (299, 232)], (190, 220, 255), alpha=0.85, soft=1)
        ellipse(img, (305, 233), 1.8, 2.6, (255, 255, 255), 0.9)

    # ---- mouth
    mx, my = 256, 316
    if expr == "neutral":
        stroke(img, [(mx - 15, my), (mx - 5, my + 3), (mx + 6, my + 3.2), (mx + 16, my - 0.5)], (96, 40, 54), 3.2, soft=1)
        stroke(img, [(mx - 8, my + 7), (mx + 8, my + 7)], (186, 100, 96), 3.0, 0.5, soft=1)
    elif expr == "speaking":
        fillpoly(img, [(mx - 15, my - 1), (mx - 6, my - 4), (mx, my - 3), (mx + 6, my - 4), (mx + 15, my - 1), (mx + 11, my + 10), (mx, my + 14), (mx - 11, my + 10)], (88, 28, 48), soft=2)
        fillpoly(img, [(mx - 8, my + 6), (mx, my + 4), (mx + 8, my + 6), (mx, my + 12)], (222, 108, 120), soft=1)
        fillpoly(img, [(mx - 9, my - 3), (mx, my - 2), (mx + 9, my - 3), (mx + 8, my + 1), (mx, my + 2), (mx - 8, my + 1)], (248, 240, 246), soft=1)
        stroke(img, [(mx - 15, my - 1), (mx - 6, my - 4), (mx, my - 3), (mx + 6, my - 4), (mx + 15, my - 1)], (70, 24, 40), 2.2, soft=1)
    elif expr == "worried":
        stroke(img, [(mx - 12, my + 4), (mx - 4, my), (mx + 5, my + 0.5), (mx + 13, my + 5)], (92, 38, 52), 3.0, soft=1)
        fillpoly(img, [(mx - 3, my + 1), (mx + 3, my + 1), (mx + 2, my + 6), (mx - 2, my + 6)], (70, 22, 40), alpha=0.8, soft=1)
    elif expr == "determined":
        stroke(img, [(mx - 15, my + 1), (mx - 5, my + 4), (mx + 6, my + 4), (mx + 16, my)], (86, 34, 50), 3.4, soft=1)
        stroke(img, [(mx + 15, my - 0.5), (mx + 19, my - 3)], (86, 34, 50), 2.0)
    else:
        fillpoly(img, [(mx - 20, my - 4), (mx, my + 1), (mx + 20, my - 4), (mx + 15, my + 10), (mx, my + 18), (mx - 15, my + 10)], (88, 28, 48), soft=2)
        fillpoly(img, [(mx - 15, my - 2), (mx, my + 2), (mx + 15, my - 2), (mx + 12, my + 3), (mx, my + 5), (mx - 12, my + 3)], (250, 244, 248), soft=1)
        fillpoly(img, [(mx - 8, my + 10), (mx, my + 8), (mx + 8, my + 10), (mx, my + 15)], (226, 112, 124), soft=1)
        stroke(img, [(mx - 20, my - 4), (mx, my + 1), (mx + 20, my - 4)], (70, 24, 40), 2.2, soft=1)
        stroke(img, [(mx - 23, my - 6), (mx - 20, my - 2)], SKIN_LO, 1.6)
        stroke(img, [(mx + 23, my - 6), (mx + 20, my - 2)], SKIN_LO, 1.6)

    # ---- front hair: parted fringe, long face-framing locks, curls, gold clips
    fr = layer()
    fillpoly(fr, [(184, 246), (186, 196), (210, 148), (256, 128), (302, 148), (326, 196), (328, 246), (318, 232), (310, 200), (292, 184), (272, 174), (258, 160), (242, 174), (220, 186), (202, 200), (194, 232)], HAIR, grad=((88, 58, 160), (28, 14, 60)), soft=2)
    for side in (-1, 1):
        lock = [(256 + side * 52, 176), (256 + side * 68, 196), (256 + side * 74, 236), (256 + side * 80, 296), (256 + side * 72, 350), (256 + side * 86, 410), (256 + side * 74, 436), (256 + side * 62, 400), (256 + side * 56, 336), (256 + side * 58, 268), (256 + side * 48, 214)]
        fillpoly(fr, lock, HAIR, grad=((74, 46, 140), (20, 10, 44)), soft=2)
        for t in range(6):   # curl ringlets at the ends
            cxr, cyr = 256 + side * (84 - 2 * t), 372 + t * 12
            stroke(fr, [(cxr + math.cos(a) * (8 - t * 0.4), cyr + a * 3 + math.sin(a) * 6) for a in np.linspace(0, 5, 12)], HAIR_HI, 1.4, 0.35, soft=1)
    # highlight sheen on the fringe and lock edges (anime hair shine)
    stroke(fr, [(218, 186), (238, 168), (262, 164), (292, 172)], HAIR_HI, 3.0, 0.6, soft=2)
    stroke(fr, [(206, 206), (196, 240)], HAIR_HI, 2.2, 0.5, soft=1)
    stroke(fr, [(196, 260), (190, 320), (186, 372)], HAIR_HI, 2.4, 0.45, soft=2)
    stroke(fr, [(318, 260), (324, 320), (328, 372)], HAIR_HI, 2.0, 0.3, soft=2)
    # ink contour on the fringe edge
    stroke(fr, [(194, 232), (202, 200), (220, 186), (242, 174), (258, 160), (272, 174), (292, 184), (310, 200), (318, 232)], INK, 2.0, 0.8, soft=1)
    img.alpha_composite(fr)
    for gx, gy, gs in ((222, 156, 1.0), (244, 148, 0.8)):
        fillpoly(img, [(gx - 9 * gs, gy), (gx, gy - 5 * gs), (gx + 9 * gs, gy), (gx, gy + 5 * gs)], GOLD, grad=(GOLD_HI, GOLD_LO))
        stroke(img, [(gx - 9 * gs, gy), (gx, gy - 5 * gs), (gx + 9 * gs, gy), (gx, gy + 5 * gs), (gx - 9 * gs, gy)], INK, 1.4, 0.8)
        glow(img, (gx, gy), 8, GOLD_HI, 0.4, 5)

    # ---- face contour ink, rim light from the upper left, violet lantern light from the lower right
    stroke(img, [(196, 240), (200, 206)], INK, 2.0, 0.6)
    stroke(img, [(286, 324), (256, 344), (226, 324)], INK, 1.8, 0.45, soft=1)
    glow(img, (330, 340), 60, (150, 100, 255), 0.18, 40)
    # tiny resonance motes around her (Echo/lantern theme)
    for _ in range(10):
        x, y = rnd.uniform(30, 480), rnd.uniform(30, 300)
        glow(img, (x, y), 3, (255, 214, 140), 0.9, 2)
    return img.resize((N, N), Image.LANCZOS).convert("RGBA")

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    exprs = ["neutral", "speaking", "worried", "determined", "smile"]
    ims = []
    for e in exprs:
        im = draw_mira(e)
        im.save(os.path.join(OUT, "mira_%s.png" % e), optimize=True)
        ims.append(im)
        print("wrote", e, flush=True)
    sheet = Image.new("RGB", (5 * 260 + 10, 300), (14, 10, 30))
    d = ImageDraw.Draw(sheet)
    for i, (e, im) in enumerate(zip(exprs, ims)):
        sheet.paste(im.resize((256, 256), Image.LANCZOS).convert("RGB"), (8 + i * 260, 6))
        d.text((12 + i * 260, 270), e.upper(), fill=(230, 220, 255))
    sheet.save(os.path.join(OUT, "mira_expressions_sheet.png"))
