#!/usr/bin/env python3
"""Hollow Cantor hybrid prototype - 2D stage. Takes the Blender passes (body, mask matte, glow matte, anchors) and paints/composites:
painterly body treatment, ink + rim, masked-face detail, luminous bell halo with bloom, Phase 2 energy wings, glowing bells, motes.
Usage: python3 cantor_hybrid_comp.py IN_DIR PHASE OUT.png [final_scale=0.5]   (PIL + numpy only)"""
import sys, os, json, math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

IN, PHASE, OUTP = sys.argv[1], int(sys.argv[2]), sys.argv[3]
FS = float(sys.argv[4]) if len(sys.argv) > 4 else 0.5
P2 = PHASE == 2
A = json.load(open(os.path.join(IN, "anchors_p%d.json" % PHASE)))
W, H = A["size"]
PPU = A["px_per_unit"]
rng = np.random.default_rng(5)

def load(n):
    return Image.open(os.path.join(IN, "%s_p%d.png" % (n, PHASE))).convert("RGBA")

body, maskm, glowm = load("body"), load("maskmatte"), load("glowmatte")

def blur(im, r):
    return im.filter(ImageFilter.GaussianBlur(r))

def screen_add(base, layer, k=1.0):
    """Additive-ish light on an RGBA premultiplied-like layer: base/layer are float arrays (H,W,4) straight alpha."""
    la = layer[..., 3:4] * k
    base[..., :3] = np.clip(base[..., :3] * base[..., 3:4] + layer[..., :3] * la, 0, 1.6)
    base[..., 3:4] = np.clip(base[..., 3:4] + la * (1 - base[..., 3:4]), 0, 1)
    return base

def over(base, top):
    ta = top[..., 3:4]
    ba = base[..., 3:4]
    oa = ta + ba * (1 - ta)
    rgb = (top[..., :3] * ta + base[..., :3] * ba * (1 - ta)) / np.maximum(oa, 1e-6)
    return np.concatenate([rgb, oa], -1)

def fa(im):
    return np.asarray(im, np.float32) / 255.0

def toim(a):
    return Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")

def glow_layer(draw_fn, rad, color, strength=1.0, passes=(1.0, 2.5, 6.0)):
    """Draw white-on-black shapes with draw_fn(ImageDraw), then build a coloured bloom from several blur radii."""
    m = Image.new("L", (W, H), 0)
    draw_fn(ImageDraw.Draw(m))
    acc = np.zeros((H, W), np.float32)
    for i, p in enumerate(passes):
        acc += np.asarray(blur(m, rad * p), np.float32) / 255.0 * (strength / (1 + i * 0.6))
    acc = np.clip(acc, 0, 1)
    out = np.zeros((H, W, 4), np.float32)
    out[..., :3] = np.array(color, np.float32) / 255.0
    out[..., 3] = acc
    return out

# ---------------------------------------------------------------- 1. painterly body treatment
b = fa(body)
alpha = b[..., 3]
rgb = b[..., :3]
# gentle median to flatten render aliasing into painted shapes, then keep hard cel edges
rgb_i = Image.fromarray((rgb * 255).astype(np.uint8), "RGB").filter(ImageFilter.MedianFilter(3))
rgb = np.asarray(rgb_i, np.float32) / 255.0
lum = rgb @ np.array([0.3, 0.55, 0.15], np.float32)
# brush grain: anisotropic noise (long diagonal strokes) modulating value
def strokes(seed, ang, length):
    r = np.random.default_rng(seed)
    n = Image.fromarray((r.random((H // 2, W // 2)) * 255).astype(np.uint8), "L").resize((W, H), Image.BICUBIC)
    n = n.filter(ImageFilter.GaussianBlur(1.2))
    a = np.asarray(n, np.float32) / 255.0
    # directional smear along `ang`
    out = np.zeros_like(a)
    dx, dy = math.cos(ang), math.sin(ang)
    for s in range(-length, length + 1, 2):
        out += np.roll(np.roll(a, int(dy * s), 0), int(dx * s), 1)
    return out / (length + 1)
g1 = strokes(3, math.radians(62), 9)
g2 = strokes(9, math.radians(-30), 5)
grain = (g1 - g1.mean()) * 3.2 + (g2 - g2.mean()) * 1.6
mk0 = fa(maskm)[..., 3]
rgb = np.clip(rgb * (1 + (grain * (1 - mk0))[..., None] * 0.20), 0, 1.2)
# cross-hatch in the shadow band (Hero/Shade painted shading), clipped to the body
yy, xx = np.mgrid[0:H, 0:W]
hatch = (np.sin((xx * 0.8 + yy * 1.1) * 0.55) > 0.82).astype(np.float32)
shadow = np.clip((0.20 - lum) / 0.12, 0, 1)
rgb = rgb * (1 - 0.30 * hatch[..., None] * shadow[..., None])
# colour grade: deeper shadows with violet/blue push, brighter highlights toward lavender (matches Hero/Shade contrast)
rgb = np.clip((rgb - 0.04) * 1.12, 0, 1.2)
shade_tint = np.array([0.04, 0.0, 0.16], np.float32)
rgb = rgb + (1 - np.clip(lum * 2.4, 0, 1))[..., None] * shade_tint
body_a = np.concatenate([np.clip(rgb, 0, 1), alpha[..., None]], -1)

# ink line: dilate alpha, fill with deep indigo, sits behind body (outer contour); inner contours come from Blender's hull
def dilate(mask_img, r):
    return mask_img.filter(ImageFilter.MaxFilter(r * 2 + 1))
al = Image.fromarray((alpha * 255).astype(np.uint8), "L")
ink_a = np.asarray(blur(dilate(al, 3), 0.8), np.float32) / 255.0
ink = np.zeros((H, W, 4), np.float32)
ink[..., :3] = np.array([0.045, 0.02, 0.12], np.float32)
ink[..., 3] = ink_a
# rim light: lit edge on the right/top (cool cyan-white) from an offset-subtract of alpha
off = np.roll(np.roll(alpha, 4, 1), -3, 0)
rim = np.clip(alpha - off, 0, 1)
rim = np.asarray(blur(Image.fromarray((rim * 255).astype(np.uint8), "L"), 1.1), np.float32) / 255.0
rim_l = np.zeros((H, W, 4), np.float32)
rim_l[..., :3] = np.array([0.72, 0.9, 1.0], np.float32)
rim_l[..., 3] = np.clip(rim * 1.2, 0, 1) * alpha

# ---------------------------------------------------------------- 2. face details (clipped to the mask matte)
ma = fa(maskm)[..., 3]
face = Image.new("RGBA", (W, H), (0, 0, 0, 0))
fd = ImageDraw.Draw(face)
S = 3                                                     # local supersample for crisp small strokes
big = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
bd = ImageDraw.Draw(big)
def P(p):
    return (p[0] * S, p[1] * S)
mc = A["mask"]
u = PPU / 248.6
ex_l = [mc[0] - 9 * u, mc[1] - 14 * u]
ex_r = [mc[0] + 22 * u, mc[1] - 14 * u]                                           # scale features with render scale
# slit eyes: dark almond socket, cyan glow slit
for e in (ex_l, ex_r):
    ex, ey = e[0], e[1] + 3 * u
    pts = [(ex - 17 * u, ey), (ex, ey - 6 * u), (ex + 17 * u, ey - 1 * u), (ex, ey + 4 * u)]
    bd.polygon([P(p) for p in pts], fill=(24, 10, 58, 235))
    bd.line([P((ex - 15 * u, ey)), P((ex + 1 * u, ey - 1 * u)), P((ex + 15 * u, ey - 1 * u))], fill=(190, 250, 255, 255), width=int(2.2 * S * u))
    # painted brow stroke above each eye
    bd.line([P((ex - 20 * u, ey - 9 * u)), P((ex, ey - 15 * u)), P((ex + 20 * u, ey - 10 * u))], fill=(52, 30, 112, 230), width=int(2.4 * S * u))
    # tear line: resonance crack running down the cheek, with a gold chip
    bd.line([P((ex + 2 * u, ey + 6 * u)), P((ex - 1 * u, ey + 24 * u)), P((ex + 3 * u, ey + 42 * u)), P((ex, ey + 58 * u))], fill=(96, 70, 190, 230), width=int(2.0 * S * u))
# nose shadow and a thin painted mouth seam
nx, ny = (ex_l[0] + ex_r[0]) / 2, (ex_l[1] + ex_r[1]) / 2
bd.line([P((nx, ny + 6 * u)), P((nx + 2 * u, ny + 26 * u)), P((nx - 3 * u, ny + 32 * u))], fill=(112, 96, 190, 200), width=int(1.8 * S * u))
bd.line([P((nx - 14 * u, ny + 50 * u)), P((nx, ny + 53 * u)), P((nx + 14 * u, ny + 50 * u))], fill=(70, 44, 140, 220), width=int(1.8 * S * u))
# forehead sigil: bell glyph in a diamond, gem-lit
fx, fy = nx, ny - 38 * u
bd.polygon([P((fx, fy - 12 * u)), P((fx + 8 * u, fy)), P((fx, fy + 12 * u)), P((fx - 8 * u, fy))], fill=(166, 110, 255, 255), outline=(60, 30, 130, 255))
bd.line([P((fx, fy - 5 * u)), P((fx, fy + 6 * u))], fill=(245, 235, 255, 255), width=int(1.6 * S * u))
# gold-lavender hairline cracks across the porcelain
for (a0, a1) in (((fx - 20 * u, fy - 4 * u), (fx - 34 * u, fy + 12 * u)), ((fx + 22 * u, fy + 2 * u), (fx + 30 * u, fy + 20 * u))):
    bd.line([P(a0), P((a0[0] * .5 + a1[0] * .5 - 2 * u, a0[1] * .5 + a1[1] * .5 + 3 * u)), P(a1)], fill=(120, 88, 214, 200), width=int(1.3 * S * u))
face = big.resize((W, H), Image.LANCZOS)
fa_ = fa(face)
fa_[..., 3] *= (ma > 0.5).astype(np.float32)[..., None][..., 0] * np.minimum(1, ma * 2)
eyeglow = glow_layer(lambda d: [d.line([e[0] - 15 * u, e[1] + 3 * u, e[0] + 15 * u, e[1] + 2 * u], fill=255, width=3) for e in (ex_l, ex_r)], 4 * u, (150, 240, 255), 1.1)

# ---------------------------------------------------------------- 3. luminous bell halo (2D + bloom)
hx, hy = A["head"][0], A["head"][1]
hh = 500 * u * (1.0 if not P2 else 1.12)                  # halo height (pixels at render scale)
hw = 640 * u * (1.0 if not P2 else 1.25)
top = (30 if not P2 else 22) * u
def bell_pts(cx, top_y, height, width, n=60, inset=0.0):
    pts = []
    for i in range(n + 1):
        t = i / n
        y = top_y + t * height
        if t < 0.30:
            r = width * 0.5 * math.sin(t / 0.30 * math.pi / 2) ** 0.7 * 0.58
        else:
            v = (t - 0.30) / 0.70
            r = width * 0.5 * (0.58 + 0.42 * v ** 1.7)
        pts.append((cx - r + inset, y))
    right = [(2 * cx - x + 2 * inset * 0, y) for (x, y) in pts]
    return pts, right
L, R = bell_pts(hx, top, hh, hw)
ring = L + R[::-1]
def halo_main(d):
    d.line(L, fill=255, width=4)
    d.line(R, fill=255, width=4)
    d.line([L[-1], R[-1]], fill=110, width=2)
def halo_inner(d):
    l2, r2 = bell_pts(hx, top + hh * 0.06, hh * 0.9, hw * 0.88)
    d.line(l2, fill=190, width=2)
    d.line(r2, fill=190, width=2)
halo_bloom = glow_layer(halo_main, 7 * u, (150, 110, 255), 5.0)
halo_core = glow_layer(halo_main, 1.0 * u, (255, 250, 255), 2.2, passes=(1.0, 1.6))
halo_in = glow_layer(halo_inner, 3 * u, (190, 160, 255), 2.5)
# soft translucent fill, brighter near the head (a radial halo of light behind the figure)
fill = Image.new("L", (W, H), 0)
ImageDraw.Draw(fill).polygon(ring, fill=255)
fill = np.asarray(blur(fill, 6), np.float32) / 255.0
d2 = np.sqrt(((xx - hx) / (hw * 0.62)) ** 2 + ((yy - (hy + 20 * u)) / (hh * 0.55)) ** 2)
radial = np.clip(1 - d2, 0, 1) ** 1.6
halo_fill = np.zeros((H, W, 4), np.float32)
halo_fill[..., :3] = np.array([0.55, 0.40, 0.98], np.float32) * (0.7 + 0.3 * radial[..., None]) + radial[..., None] * np.array([0.3, 0.3, 0.1], np.float32)
halo_fill[..., 3] = fill * (0.10 + 0.55 * radial)
# bells hung along the halo arc and rays fanning from behind the head
def halo_bells(d):
    for k in range(7 if not P2 else 11):
        t = 0.10 + 0.78 * k / (6 if not P2 else 10)
        side = -1 if k % 2 == 0 else 1
        i = int(t * 60)
        px, py = (L[i] if side < 0 else R[i])
        d.ellipse([px - 5, py - 4, px + 5, py + 8], fill=255)
hb = glow_layer(halo_bells, 4 * u, (220, 205, 255), 3.0)
def rays_fn(d):
    for k in range(18 if not P2 else 28):
        a = math.radians(-160 + k * (140 / (17 if not P2 else 27)))
        l0, l1 = 120 * u, (330 if not P2 else 480) * u * (0.7 + 0.3 * ((k * 7) % 5) / 4)
        d.line([hx + math.cos(a) * l0, hy + math.sin(a) * l0 - 10, hx + math.cos(a) * l1, hy + math.sin(a) * l1 - 10], fill=150 if k % 2 else 255, width=3)
rays = glow_layer(rays_fn, 5 * u, (190, 165, 255), 1.4, passes=(1.0, 2.2))

# ---------------------------------------------------------------- 4. Phase 2: energy wings, ground sigil, extra bloom
wings = np.zeros((H, W, 4), np.float32)
wing_lines = np.zeros((H, W, 4), np.float32)
if P2:
    sx0, sy0 = A["chest"][0], A["chest"][1] - 40 * u
    wmask = np.zeros((H, W), np.float32)       # blade intensity (0..1)
    wedge = np.zeros((H, W), np.float32)       # bright leading edges
    wxn = np.zeros((H, W), np.float32)         # normalised distance from the body, to tint inner->outer
    for side in (-1, 1):
        for k in range(9):
            span = (190 + k * 36) * u
            rise = (330 - k * 26) * u
            drop = (-30 + k * 44) * u
            up_, lo_ = [], []
            n = 34
            for i in range(n + 1):
                t = i / n
                x = sx0 + side * (50 * u + span * math.sin(t * 1.3) * (0.55 + 0.45 * t))
                y = sy0 - rise * math.sin(t * math.pi * 0.60) * (1 - 0.35 * t) + drop * (t ** 2.0)
                wid = (16 + 62 * math.sin(math.pi * min(1, t * 1.04)) ** 0.8) * u * (1 - 0.03 * k)
                up_.append((x, y - wid)); lo_.append((x, y + wid * 0.55))
            poly = up_ + lo_[::-1]
            m1 = Image.new("L", (W, H), 0)
            ImageDraw.Draw(m1).polygon(poly, fill=int(255 * (0.95 - 0.055 * k)))
            wmask = np.maximum(wmask, np.asarray(m1, np.float32) / 255.0)
            m2 = Image.new("L", (W, H), 0)
            ImageDraw.Draw(m2).line(up_, fill=255, width=3)
            wedge = np.maximum(wedge, np.asarray(m2, np.float32) / 255.0)
    wxn = np.clip(np.abs(xx - sx0) / (520 * u), 0, 1)
    wsoft = np.asarray(blur(Image.fromarray((wmask * 255).astype(np.uint8), "L"), 1.6 * u), np.float32) / 255.0
    wings = np.zeros((H, W, 4), np.float32)
    inner = np.array([0.92, 0.95, 1.0], np.float32); outer = np.array([0.50, 0.34, 0.98], np.float32)
    wings[..., :3] = inner * (1 - wxn[..., None]) + outer * wxn[..., None]
    wings[..., 3] = np.clip(wsoft * (0.78 - 0.30 * wxn), 0, 1)
    wing_glow = np.zeros((H, W, 4), np.float32)
    wing_glow[..., :3] = np.array([0.62, 0.45, 1.0], np.float32)
    wing_glow[..., 3] = np.clip(np.asarray(blur(Image.fromarray((wmask * 255).astype(np.uint8), "L"), 16 * u), np.float32) / 255.0 * 1.5, 0, 1)
    wing_core = np.zeros((H, W, 4), np.float32)
    wing_core[..., :3] = np.array([1.0, 1.0, 1.0], np.float32)
    wing_core[..., 3] = np.clip(np.asarray(blur(Image.fromarray((wedge * 255).astype(np.uint8), "L"), 1.0), np.float32) / 255.0 * 1.2, 0, 1)
    wing_lines = (wing_glow, wing_core)
    # ground resonance rings
    ground = glow_layer(lambda d: [d.ellipse([A["feet"][0] - r * u, A["feet"][1] - r * 0.22 * u - 8, A["feet"][0] + r * u, A["feet"][1] + r * 0.22 * u - 8], outline=255, width=3) for r in (190, 270, 360)], 4 * u, (160, 130, 255), 1.6)
else:
    ground = glow_layer(lambda d: d.ellipse([A["feet"][0] - 170 * u, A["feet"][1] - 24 * u, A["feet"][0] + 170 * u, A["feet"][1] + 10 * u], fill=255), 30 * u, (120, 90, 235), 0.9, passes=(1.0, 1.5))

# floating motes / sparkles
def motes(d):
    r = random.Random(4)
    for _ in range(40 if P2 else 18):
        x = hx + r.uniform(-1, 1) * (W * (0.42 if P2 else 0.30))
        y = r.uniform(H * 0.1, H * 0.9)
        s = r.uniform(1.5, 3.2)
        d.ellipse([x - s, y - s, x + s, y + s], fill=255)
mo = glow_layer(motes, 2.5 * u, (225, 210, 255), 3.0)

# glowing bells: Blender matte -> bloom; the bells keep their 3D shading and get a halo of light
gm = Image.fromarray((fa(glowm)[..., 3] * 255).astype(np.uint8), "L")
bell_bloom = np.zeros((H, W, 4), np.float32)
bell_bloom[..., :3] = np.array([0.72, 0.58, 1.0], np.float32)
bell_bloom[..., 3] = np.clip(np.asarray(blur(gm, 9 * u), np.float32) / 255.0 * 1.6 + np.asarray(blur(gm, 22 * u), np.float32) / 255.0 * 0.9, 0, 1)


# ---------------------------------------------------------------- 4b. painted detail on the robe: folds, embroidery, halo light spill
big = Image.new("RGBA", (W * 2, H * 2), (0, 0, 0, 0))
dd = ImageDraw.Draw(big)
r2 = random.Random(21)
fx0, fy0 = A["tab_top"]; fx1, fy1 = A["tab_bot"]
waist = (A["chest"][0], A["chest"][1] + 150 * u)
for k in range(15):                                       # fold strokes flowing from the waist to the hem, dark crease + light edge
    t0 = r2.uniform(-1, 1)
    x0 = waist[0] + t0 * 70 * u
    y0 = waist[1] + r2.uniform(0, 60) * u
    x1 = waist[0] + t0 * 260 * u + r2.uniform(-18, 18) * u
    y1 = A["feet"][1] - r2.uniform(15, 140) * u
    pts = []
    for i in range(14):
        t = i / 13
        pts.append(((x0 + (x1 - x0) * t + math.sin(t * 5 + k) * 7 * u) * 2, (y0 + (y1 - y0) * t) * 2))
    dd.line(pts, fill=(14, 6, 44, 90), width=int(3.4 * u * 2))
    dd.line([(x + 3, y) for x, y in pts], fill=(150, 125, 235, 70), width=int(1.4 * u * 2))
# tabard embroidery: a column of small bell glyphs and diamonds in silver-lavender, following the banner's slant
for k in range(9):
    t = 0.08 + k * 0.10
    cx_ = fx0 + (fx1 - fx0) * t
    cy_ = fy0 + (fy1 - fy0) * t
    sz = (9 - k * 0.4) * u
    if k % 2 == 0:
        dd.polygon([((cx_) * 2, (cy_ - sz) * 2), ((cx_ + sz * .7) * 2, cy_ * 2), (cx_ * 2, (cy_ + sz) * 2), ((cx_ - sz * .7) * 2, cy_ * 2)], fill=(214, 200, 255, 215), outline=(40, 20, 100, 255))
    else:
        dd.ellipse([(cx_ - sz * .6) * 2, (cy_ - sz * .6) * 2, (cx_ + sz * .6) * 2, (cy_ + sz * .8) * 2], fill=(150, 110, 255, 230), outline=(40, 20, 100, 255))
detail = big.resize((W, H), Image.LANCZOS)
det = fa(detail)
det[..., 3] *= alpha * (1 - np.clip(ma * 1.5, 0, 1))
canvas_detail = det
# violet halo spill on the upper body (screen), strongest at the shoulders: ties the figure to its own light
spill = np.zeros((H, W, 4), np.float32)
dsp = np.sqrt(((xx - hx) / (260 * u)) ** 2 + ((yy - (hy + 90 * u)) / (330 * u)) ** 2)
spill[..., :3] = np.array([0.55, 0.42, 1.0], np.float32)
spill[..., 3] = np.clip(1 - dsp, 0, 1) ** 1.5 * alpha * 0.38
# bottom falloff: robe fades darker toward the hem like the Shade's cape tatters
hemshade = np.zeros((H, W, 4), np.float32)
hemshade[..., :3] = np.array([0.02, 0.0, 0.08], np.float32)
hemshade[..., 3] = np.clip((yy - (A["feet"][1] - 280 * u)) / (260 * u), 0, 1) ** 1.3 * alpha * 0.45

# ---------------------------------------------------------------- 5. composite
canvas = np.zeros((H, W, 4), np.float32)
canvas = screen_add(canvas, rays, 0.55)
canvas = screen_add(canvas, halo_fill, 0.9)
canvas = screen_add(canvas, halo_bloom, 1.0)
canvas = screen_add(canvas, halo_in, 0.8)
canvas = screen_add(canvas, halo_core, 1.0)
canvas = screen_add(canvas, ground, 0.9)
if P2:
    canvas = screen_add(canvas, wing_lines[0], 0.8)
    canvas = over(canvas, wings)
    canvas = screen_add(canvas, wing_lines[1], 0.9)
canvas = over(canvas, ink)
canvas = over(canvas, body_a)
canvas = over(canvas, hemshade)
canvas = over(canvas, canvas_detail)
canvas = screen_add(canvas, spill, 0.6)
canvas = over(canvas, rim_l * np.array([1, 1, 1, 0.5], np.float32))
canvas = over(canvas, fa_)
canvas = screen_add(canvas, eyeglow, 1.0)
canvas = screen_add(canvas, bell_bloom, 0.65)
# bell glow matte drawn again on top so bells stay crisp over their own bloom
bells_top = fa(glowm)
canvas = over(canvas, bells_top)
canvas = screen_add(canvas, hb, 0.9)
canvas = screen_add(canvas, mo, 0.9)
if P2:
    # transformation flare behind the head: hot bloom core
    flare = glow_layer(lambda d: d.ellipse([hx - 40 * u, hy - 60 * u, hx + 40 * u, hy + 60 * u], fill=255), 30 * u, (230, 215, 255), 0.7)
    canvas = screen_add(canvas, flare, 0.5)

# edge fade bands so no frame touches the canvas border (matches v2's safe margin rule)
a = canvas[..., 3]
m = 28
fade = np.ones((H, W), np.float32)
for d_, sl in ((np.linspace(0, 1, m), (slice(0, m), slice(None))), (np.linspace(1, 0, m), (slice(H - m, H), slice(None)))):
    fade[sl] *= d_[:, None]
for d_, sl in ((np.linspace(0, 1, m), (slice(None), slice(0, m))), (np.linspace(1, 0, m), (slice(None), slice(W - m, W)))):
    fade[sl] *= d_[None, :]
canvas[..., 3] = a * np.where(a > 0, (np.minimum(1, fade * 1.0)), 0) if False else a * fade ** 1.0

out = toim(canvas)
if FS != 1.0:
    out = out.resize((int(W * FS), int(H * FS)), Image.LANCZOS)
out.save(OUTP, optimize=True)
print("wrote", OUTP, out.size, os.path.getsize(OUTP) // 1024, "KB")
