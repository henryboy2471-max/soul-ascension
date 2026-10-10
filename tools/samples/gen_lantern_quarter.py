#!/usr/bin/env python3
"""Lantern Quarter environment sample (violet-rain night): painted-style parallax layers rendered procedurally.
SAMPLE FOR OWNER REVIEW. Layers are saved separately (sky, far, mid, street, fore, rain) for parallax use, plus a composite with the approved
Hero and Mira sprites at gameplay scale. Usage: python3 tools/samples/gen_lantern_quarter.py OUT_DIR"""
import math, os, random, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
S = 2
W, H = 1280 * S, 720 * S
INK = (14, 6, 30)
HORIZON = 470 * S            # street top (screen y at 2x)
GROUND = 548               # where characters stand (screen units)
rnd = random.Random(21)
FONT = ImageFont.truetype("DejaVuSans-Bold.ttf", 22 * S)
FONT_S = ImageFont.truetype("DejaVuSans-Bold.ttf", 13 * S)

def blank():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))

def poly(img, pts, fill, alpha=1.0, grad=None):
    pp = [(x * S, y * S) for x, y in pts]
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).polygon(pp, fill=255)
    if grad:
        ys = [p[1] for p in pp]; y0, y1 = min(ys), max(ys)
        t = np.clip((np.arange(H)[:, None] - y0) / max(1, y1 - y0), 0, 1)
        arr = np.zeros((H, W, 4), np.uint8)
        for k in range(3):
            arr[:, :, k] = (grad[0][k] + (grad[1][k] - grad[0][k]) * t).astype(np.uint8)
        arr[:, :, 3] = 255
        col = Image.fromarray(arr, "RGBA")
    else:
        col = Image.new("RGBA", img.size, fill + (255,))
    col.putalpha(m.point(lambda v: int(v * alpha)))
    img.alpha_composite(col)

def line(img, pts, color, width, alpha=1.0):
    l = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(l).line([(x * S, y * S) for x, y in pts], fill=color + (int(255 * alpha),), width=max(1, int(width * S)), joint="curve")
    img.alpha_composite(l)

def rect(img, x0, y0, x1, y1, fill, alpha=1.0, grad=None):
    poly(img, [(x0, y0), (x1, y0), (x1, y1), (x0, y1)], fill, alpha, grad)

def glow(img, c, r, color, strength=1.0, blur=None):
    pad = int(r * 3 * S)
    x0, y0 = int(c[0] * S - pad), int(c[1] * S - pad)
    size = pad * 2
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse([pad - r * S, pad - r * S, pad + r * S, pad + r * S], fill=255)
    m = m.filter(ImageFilter.GaussianBlur((blur or r * 0.8) * S)).point(lambda v: min(255, int(v * strength)))
    col = Image.new("RGBA", (size, size), color + (255,)); col.putalpha(m)
    img.alpha_composite(col, (x0, y0)) if x0 >= 0 and y0 >= 0 and x0 + size <= W and y0 + size <= H else img.paste(col, (x0, y0), col)

def vgrad(top, bottom, y0=0, y1=None):
    y1 = y1 or H
    t = np.clip((np.arange(H)[:, None] - y0) / max(1, y1 - y0), 0, 1)
    arr = np.zeros((H, W, 4), np.uint8)
    for k in range(3):
        arr[:, :, k] = (top[k] + (bottom[k] - top[k]) * t).astype(np.uint8)
    arr[:, :, 3] = 255
    return Image.fromarray(arr, "RGBA")

WARM = [(255, 190, 100), (255, 150, 90), (255, 214, 140), (255, 120, 110)]

# ------------------------------------------------------------------------------------------------ SKY
def make_sky():
    img = vgrad((8, 4, 26), (88, 46, 140), 0, HORIZON + 40 * S)
    glow(img, (640, 330), 360, (130, 80, 235), 0.55, 200)
    glow(img, (1010, 250), 190, (200, 120, 255), 0.35, 120)
    # rain cloud streaks
    for _ in range(14):
        y = rnd.uniform(20, 300)
        line(img, [(rnd.uniform(-100, 700), y), (rnd.uniform(700, 1400), y + rnd.uniform(-20, 30))], (120, 80, 200), rnd.uniform(14, 40), 0.08)
    img = img.filter(ImageFilter.GaussianBlur(3 * S))
    # distant Meridian spire with a red beacon, and a rain-array mast (the Episode 2 antagonist's hint)
    poly(img, [(1010, 470), (1014, 190), (1018, 150), (1022, 190), (1026, 470)], (24, 12, 56))
    poly(img, [(996, 470), (1004, 300), (1036, 300), (1044, 470)], (30, 16, 66))
    for k in range(5):
        y = 260 + k * 38
        line(img, [(1006, y), (1030, y)], (140, 110, 230), 1.2, 0.5)
    glow(img, (1018, 146), 10, (255, 70, 90), 1.0, 12)
    for dx in (-60, 60):
        line(img, [(1018 + dx * 0.2, 330), (1018 + dx, 270)], (36, 20, 74), 3)
        poly(img, [(1018 + dx - 14, 270), (1018 + dx + 14, 270), (1018 + dx, 252)], (36, 20, 74))
    return img

# ------------------------------------------------------------------------------------------------ FAR CITY
def make_far():
    img = blank()
    x = -20
    while x < 1300:
        w = rnd.uniform(34, 80); h = rnd.uniform(110, 300)
        top = HORIZON / S - 10 - h
        poly(img, [(x, HORIZON / S), (x, top), (x + w, top), (x + w, HORIZON / S)], (36, 22, 78), grad=((58, 38, 110), (30, 18, 66)))
        for wy in np.arange(top + 10, HORIZON / S - 14, 13):
            for wx in np.arange(x + 6, x + w - 8, 11):
                if rnd.random() < 0.22:
                    c = (110, 210, 230) if rnd.random() < 0.4 else (250, 176, 96)
                    rect(img, wx, wy, wx + 4, wy + 6, c, 0.85)
        if rnd.random() < 0.3:
            line(img, [(x + w / 2, top), (x + w / 2, top - rnd.uniform(14, 40))], (60, 40, 120), 1.4)
        x += w + rnd.uniform(-4, 6)
    fog = vgrad((70, 40, 130), (110, 60, 170), int(HORIZON - 160 * S), HORIZON + 20 * S)
    fm = Image.new("L", (W, H), 0)
    ImageDraw.Draw(fm).rectangle([0, int(HORIZON - 160 * S), W, HORIZON + 20 * S], fill=255)
    fm = fm.filter(ImageFilter.GaussianBlur(30 * S))
    arr = np.asarray(fm, np.float32) / 255.0
    arr = np.minimum(arr, np.clip((np.arange(H)[:, None] - (HORIZON - 160 * S)) / (140 * S), 0, 1)) * 0.55
    fog.putalpha(Image.fromarray((arr * 255).astype(np.uint8)))
    img.alpha_composite(fog)
    return img

# ------------------------------------------------------------------------------------------------ MID: the Lantern Quarter
LANTERNS = []   # (x, y, color) collected for glow + reflections

def window(img, x, y, w, h, lit):
    poly(img, [(x, y + h), (x, y + 6), (x + w / 2, y), (x + w, y + 6), (x + w, y + h)], INK)
    if lit:
        c = rnd.choice(WARM)
        poly(img, [(x + 2, y + h - 1), (x + 2, y + 7), (x + w / 2, y + 2), (x + w - 2, y + 7), (x + w - 2, y + h - 1)], c, grad=((255, 236, 170), c))
        line(img, [(x + w / 2, y + 2), (x + w / 2, y + h - 1)], (90, 40, 40), 1.2, 0.6)
        line(img, [(x + 2, y + h * 0.55), (x + w - 2, y + h * 0.55)], (90, 40, 40), 1.0, 0.5)
        LANTERNS.append((x + w / 2, y + h / 2, c, 0.35, 16))
    else:
        poly(img, [(x + 2, y + h - 1), (x + 2, y + 7), (x + w / 2, y + 2), (x + w - 2, y + 7), (x + w - 2, y + h - 1)], (40, 30, 90), grad=((54, 42, 110), (30, 20, 70)))

def building(img, x0, x1, base, tiers, side):
    """Stepped terrace building. side=-1 steps up toward the left edge, +1 toward the right edge."""
    y = base
    for t in range(tiers):
        h = rnd.uniform(86, 118)
        inset = t * 18
        a, b = (x0 + (inset if side > 0 else 0), x1 - (inset if side < 0 else 0))
        top = y - h
        poly(img, [(a, y), (a, top), (b, top), (b, y)], (34, 22, 72), grad=((60, 42, 118), (30, 18, 64)))
        # plaster panel seams and brick hatch
        for yy in np.arange(top + 14, y, 14):
            line(img, [(a, yy), (b, yy)], (24, 14, 54), 0.8, 0.35)
        # rim light on the edge facing the street centre, ink on the others
        edge = b if side > 0 else a
        line(img, [(edge, top), (edge, y)], (160, 130, 245), 2.2, 0.55)
        line(img, [(a, top), (a, y)], INK, 2.2, 0.8)
        line(img, [(b, top), (b, y)], INK, 2.2, 0.8)
        # tiled roof overhang
        poly(img, [(a - 8, top + 2), (a + 6, top - 12), (b - 6, top - 12), (b + 8, top + 2)], (86, 44, 124), grad=((120, 66, 168), (60, 30, 96)))
        line(img, [(a - 8, top + 2), (a + 6, top - 12), (b - 6, top - 12), (b + 8, top + 2), (a - 8, top + 2)], INK, 2.0, 0.9)
        line(img, [(a + 6, top - 11), (b - 6, top - 11)], (200, 160, 255), 1.6, 0.55)
        # windows
        ww = 18
        for wx in np.arange(a + 12, b - ww - 6, 30):
            window(img, wx, top + 20, ww, 30, rnd.random() < 0.55)
        # balcony rail with posts
        line(img, [(a + 4, y - 22), (b - 4, y - 22)], (190, 150, 90), 2.0, 0.9)
        for px in np.arange(a + 6, b - 4, 9):
            line(img, [(px, y - 22), (px, y - 8)], (150, 110, 70), 1.2, 0.8)
        # hanging banner with a glyph
        if rnd.random() < 0.7:
            bx = rnd.uniform(a + 14, b - 14)
            poly(img, [(bx - 7, top + 54), (bx + 7, top + 54), (bx + 7, top + 86), (bx, top + 80), (bx - 7, top + 86)], rnd.choice([(190, 60, 90), (60, 150, 170), (214, 170, 70)]), 0.9)
            line(img, [(bx, top + 62), (bx, top + 74)], (255, 240, 200), 1.4, 0.9)
        # vertical pipe
        if rnd.random() < 0.6:
            pxx = a + rnd.uniform(4, 10)
            line(img, [(pxx, top + 8), (pxx, y)], (70, 60, 110), 3.0, 0.9)
            for jy in np.arange(top + 20, y, 28):
                line(img, [(pxx - 3, jy), (pxx + 3, jy)], (130, 120, 180), 1.6, 0.9)
        y = top - 12

def depot(img):
    """Depot 4: the drained tram shed the Lantern Circuit uses as a shelter (arched mouth, teal lamp light, sign)."""
    x0, x1, base = 520, 760, HORIZON / S + 8
    poly(img, [(x0, base), (x0, base - 170), (x1, base - 170), (x1, base)], (40, 28, 84), grad=((66, 48, 126), (32, 20, 70)))
    line(img, [(x0, base - 170), (x0, base)], INK, 2.4); line(img, [(x1, base - 170), (x1, base)], INK, 2.4)
    arch = [(x0 + 30, base)] + [(640 + math.cos(a) * 90, base - 90 - math.sin(a) * 70) for a in np.linspace(math.pi, 0, 24)] + [(x1 - 30, base)]
    poly(img, arch, (8, 4, 24))
    inner = [(x0 + 44, base)] + [(640 + math.cos(a) * 76, base - 86 - math.sin(a) * 58) for a in np.linspace(math.pi, 0, 24)] + [(x1 - 44, base)]
    poly(img, inner, (40, 150, 170), grad=((70, 200, 215), (16, 70, 100)))
    glow(img, (640, base - 70), 80, (80, 210, 230), 0.55, 50)
    for k in range(-2, 3):   # rows of standing sleepers silhouetted in the depot light
        poly(img, [(640 + k * 22 - 6, base), (640 + k * 22 - 5, base - 34), (640 + k * 22 - 2, base - 40), (640 + k * 22 + 2, base - 40), (640 + k * 22 + 5, base - 34), (640 + k * 22 + 6, base)], (14, 10, 40))
    line(img, [(x0 + 30, base), (640, base - 156), (x1 - 30, base)], INK, 2.4, 0.0)
    line(img, [(x0 + 30, base)] + [(640 + math.cos(a) * 90, base - 90 - math.sin(a) * 70) for a in np.linspace(math.pi, 0, 24)] + [(x1 - 30, base)], (190, 150, 90), 3.2, 0.9)
    # neon sign "DEPOT 4"
    sign = (600, 252, 680, 278)
    rect(img, sign[0], sign[1], sign[2], sign[3], (18, 12, 44))
    line(img, [(sign[0], sign[1]), (sign[2], sign[1]), (sign[2], sign[3]), (sign[0], sign[3]), (sign[0], sign[1])], (110, 220, 235), 1.6, 0.9)
    d = ImageDraw.Draw(img)
    d.text((640 * S, 265 * S), "DEPOT 4", font=FONT_S, fill=(190, 250, 255, 255), anchor="mm")
    glow(img, (640, 265), 40, (90, 220, 240), 0.5, 20)
    # tram rails running toward the viewer
    for off in (-14, 14):
        line(img, [(640 + off * 0.5, base), (640 + off * 6, 720)], (150, 140, 200), 2.0, 0.7)

def lantern(img, x, y, r, color):
    glow(img, (x, y), r * 3.2, color, 0.55, r * 2.2)
    poly(img, [(x - r * 0.35, y - r), (x + r * 0.35, y - r), (x + r, y - r * 0.2), (x + r * 0.8, y + r * 0.7), (x, y + r), (x - r * 0.8, y + r * 0.7), (x - r, y - r * 0.2)], color, grad=((255, 240, 190), color))
    for k in (-0.5, 0.0, 0.5):
        line(img, [(x + k * r, y - r * 0.95), (x + k * r * 1.3, y + r * 0.9)], (120, 40, 40), 0.9, 0.55)
    poly(img, [(x - r * 0.42, y - r - 3), (x + r * 0.42, y - r - 3), (x + r * 0.3, y - r), (x - r * 0.3, y - r)], (60, 30, 40))
    line(img, [(x, y + r), (x, y + r + r * 0.8)], (240, 190, 120), 1.0, 0.8)
    LANTERNS.append((x, y, color, 0.6, int(r * 2)))

def lantern_string(img, a, b, sag, n, r):
    pts = [(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t + math.sin(t * math.pi) * sag) for t in np.linspace(0, 1, 40)]
    line(img, pts, (40, 24, 56), 1.8, 0.95)
    for k in range(1, n):
        t = k / n
        x = a[0] + (b[0] - a[0]) * t; y = a[1] + (b[1] - a[1]) * t + math.sin(t * math.pi) * sag
        lantern(img, x, y + r, r, rnd.choice(WARM))

def make_mid():
    img = blank()
    base = HORIZON / S + 6
    # left and right terraces step up toward the screen edges; the depot sits in the centre
    for (x0, x1, tiers, side) in ((-30, 160, 3, -1), (150, 330, 2, -1), (330, 520, 2, -1), (760, 940, 2, 1), (930, 1110, 2, 1), (1100, 1310, 3, 1)):
        building(img, x0, x1, base, tiers, side)
    depot(img)
    # lantern strings across the street, with a few at different depths
    lantern_string(img, (60, 190), (560, 230), 36, 8, 7)
    lantern_string(img, (720, 230), (1230, 180), 40, 9, 7)
    lantern_string(img, (330, 240), (950, 250), 52, 12, 6)
    lantern_string(img, (150, 330), (520, 350), 28, 6, 5.5)
    lantern_string(img, (760, 350), (1130, 330), 28, 6, 5.5)
    return img

# ------------------------------------------------------------------------------------------------ STREET
def make_street(mid):
    img = vgrad((26, 14, 58), (12, 6, 30), HORIZON, H)
    al = np.asarray(img).copy(); al[:HORIZON, :, 3] = 0; img = Image.fromarray(al, 'RGBA')
    # wet cobble perspective
    for k in range(40):
        t = (k / 40.0) ** 1.8
        y = HORIZON / S + t * (720 - HORIZON / S)
        line(img, [(0, y), (1280, y)], (60, 40, 110), 0.8 + t * 1.2, 0.35)
    for k in range(-14, 15):
        line(img, [(640 + k * 9, HORIZON / S), (640 + k * 150, 720)], (60, 40, 110), 1.0, 0.25)
    # reflections of the lantern light and the depot glow: mirror the mid layer below the street line, blur, fade with distance
    mir = mid.crop((0, HORIZON - 260 * S, W, HORIZON)).transpose(Image.FLIP_TOP_BOTTOM).filter(ImageFilter.GaussianBlur(5 * S))
    a = np.asarray(mir).astype(np.float32)
    fade = np.clip(1.0 - np.arange(a.shape[0])[:, None] / (260.0 * S), 0, 1) ** 1.4
    a[:, :, 3] *= fade * 0.55
    mir = Image.fromarray(a.astype(np.uint8), "RGBA")
    img.alpha_composite(mir, (0, HORIZON))
    # puddles catching the sky and lantern colour
    for _ in range(9):
        cx, cy = rnd.uniform(60, 1220), rnd.uniform(520, 700)
        rx = rnd.uniform(50, 130); ry = rx * 0.14
        m = Image.new("L", (W, H), 0)
        ImageDraw.Draw(m).ellipse([(cx - rx) * S, (cy - ry) * S, (cx + rx) * S, (cy + ry) * S], fill=255)
        m = m.filter(ImageFilter.GaussianBlur(2 * S))
        col = Image.new("RGBA", (W, H), rnd.choice([(150, 110, 240), (255, 170, 100), (110, 200, 230)]) + (255,))
        col.putalpha(m.point(lambda v: int(v * 0.35)))
        img.alpha_composite(col)
    # stairs on the right leading up to the terrace and the Rain Array roof (story hint)
    for k in range(7):
        y = 470 + k * 4
        rect(img, 1120 + k * 6, y - 10, 1290, y - 2, (50 + k * 6, 34 + k * 4, 100 + k * 6))
        line(img, [(1120 + k * 6, y - 10), (1290, y - 10)], (190, 160, 255), 1.4, 0.5)
    return img

# ------------------------------------------------------------------------------------------------ FOREGROUND
def make_fore():
    img = blank()
    # big out-of-focus lanterns hanging in the top corners
    for (x, y, r, c) in ((70, 70, 44, (255, 160, 90)), (180, 30, 30, (255, 120, 110)), (1210, 80, 48, (255, 190, 100)), (1110, 30, 32, (255, 214, 140))):
        glow(img, (x, y), r * 1.6, c, 0.75, r * 1.1)
        lantern(img, x, y, r * 0.55, c)
        line(img, [(x, -10), (x, y - r * 0.6)], (30, 16, 44), 2.4, 0.95)
    # dark cable swag and a railing silhouette in the lower corners
    line(img, [(-20, 40), (300, 70), (620, 30)], (20, 10, 34), 2.4, 0.9)
    line(img, [(700, 26), (980, 66), (1300, 36)], (20, 10, 34), 2.4, 0.9)
    poly(img, [(-10, 720), (-10, 640), (160, 636), (190, 720)], (10, 5, 24))
    for px in range(0, 170, 22):
        line(img, [(px, 636), (px, 720)], (22, 12, 44), 3.0, 0.95)
    line(img, [(-10, 650), (190, 646)], (60, 40, 110), 1.6, 0.8)
    poly(img, [(1290, 720), (1290, 650), (1140, 648), (1110, 720)], (10, 5, 24))
    return img

def make_rain():
    img = blank()
    d = ImageDraw.Draw(img)
    for _ in range(520):
        x, y = rnd.uniform(-40, 1320), rnd.uniform(-20, 720)
        L = rnd.uniform(14, 40)
        a = rnd.choice([60, 90, 130])
        d.line([(x * S, y * S), ((x - L * 0.22) * S, (y + L) * S)], fill=(196, 176, 255, a), width=max(1, S))
    for _ in range(60):  # ripples on the street
        cx, cy = rnd.uniform(40, 1240), rnd.uniform(520, 710)
        rx = rnd.uniform(6, 20)
        d.ellipse([(cx - rx) * S, (cy - rx * 0.25) * S, (cx + rx) * S, (cy + rx * 0.25) * S], outline=(190, 170, 255, 80), width=1)
    return img

# ------------------------------------------------------------------------------------------------ compose
def lights_bloom(base):
    a = np.asarray(base.convert("RGB")).astype(np.float32)
    lum = a.max(axis=2)
    mask = np.clip((lum - 190) / 65.0, 0, 1)
    b = Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(14 * S))
    b2 = Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(40 * S))
    bm = np.clip(np.asarray(b, np.float32) / 255.0 * 0.55 + np.asarray(b2, np.float32) / 255.0 * 0.5, 0, 1)
    out = a + bm[:, :, None] * np.array([170, 120, 255], np.float32) * 0.6
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGB").convert("RGBA")

def sprite(path, world_h, x, feet_y):
    im = Image.open(path).convert("RGBA")
    bbox = im.getbbox()
    k = world_h / im.height * S
    im2 = im.resize((int(im.width * k), int(im.height * k)), Image.LANCZOS)
    return im2, (int(x * S - im2.width / 2), int(feet_y * S - im2.height))

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    sky = make_sky(); far = make_far(); LANTERNS.clear(); mid = make_mid(); street = make_street(mid); fore = make_fore(); rain = make_rain()
    for name, im in (("sky", sky), ("far", far), ("mid", mid), ("street", street), ("fore", fore), ("rain", rain)):
        im.resize((1280, 720), Image.LANCZOS).save(os.path.join(OUT, f"layer_{name}.png"), optimize=True)
    comp = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    for im in (sky, far, mid, street):
        comp.alpha_composite(im)
    # characters at gameplay scale (approved sprites): Hero and Mira on the street, warm lantern rim light
    chars = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for path, hh, x in (("assets/characters/hero/frames/idle_00.png", 170, 470), ("assets/characters/mira/frames/idle_00.png", 170, 800)):
        im, pos = sprite(path, hh, x, GROUND)
        shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).ellipse([(x - 40) * S, (GROUND - 6) * S, (x + 40) * S, (GROUND + 8) * S], fill=(0, 0, 0, 120))
        chars.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3 * S)))
        chars.alpha_composite(im, pos)
    comp.alpha_composite(chars)
    comp.alpha_composite(fore); comp.alpha_composite(rain)
    comp = lights_bloom(comp)
    # vignette
    yy, xx = np.mgrid[0:H, 0:W]
    v = 1 - 0.38 * np.clip(((xx - W / 2) / (W / 2)) ** 2 * 0.7 + ((yy - H / 2) / (H / 2)) ** 2 * 0.9, 0, 1)
    arr = np.asarray(comp.convert("RGB")).astype(np.float32) * v[:, :, None]
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).resize((1280, 720), Image.LANCZOS).save(os.path.join(OUT, "lantern_quarter_sample_1280x720.png"), optimize=True)
    print("wrote", OUT)
