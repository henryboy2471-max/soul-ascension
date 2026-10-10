#!/usr/bin/env python3
"""Procedural sprite renderer for the Hollow Cantor (Episode 2 boss), v2 "painted" pass.

Original art authored in code (no external art service, no reused sheet): a tall, thin spectral conductor in pale violet /
rain-white robes over a dark inner body, floating segmented robes instead of legs, a bell-shaped halo behind a masked face,
long conductor's fingers and suspended bell fragments.

v2 renders like the project's painted anime sprites instead of flat vector shapes: ink outline around the whole silhouette,
three-tone cel shading with crisp shadow shapes, rim light from the halo, fabric grain, silver trim / gems / embroidery,
sheer layered cloth, volumetric rays, bloom and sparkles. Two forms of the SAME character:
  frames/         Phase 1: controlled, ritual
  phase2/frames/  Phase 2 "THE CHORUS RISES": a much larger double halo, energy wings, shockwave rings at the hem, flared robes,
                  a blazing eye and chest sigil, many more orbiting bells
Frames are drawn supersampled and reduced. Feet (robe hem) sit on the bottom edge, the figure is centred horizontally and
faces RIGHT (the Fighter node flips the sprite), like every other sprite set in the project.

Usage: python3 tools/gen_hollow_cantor.py [both|p1|p2] [OUT_DIR]
Then:  godot --headless --editor --import --quit
       godot --headless --path . --script res://tools/build_spriteframes.gd -- res://assets/enemies/hollow_cantor
       godot --headless --path . --script res://tools/build_spriteframes.gd -- res://assets/enemies/hollow_cantor/phase2
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

K = 1.5                     # final pixels per art unit (art is authored on a 200-unit-wide scale)
S = 3                       # supersampling
SC = S * K
H = 260                     # art height (units)
TOP_PAD = 40                # transparent rows above the art so no frame can touch the top edge
CH = H + TOP_PAD            # canvas height (units); the wave data scales it so the figure keeps its intended in-game size
W1, W2 = 330, 400           # canvas width (units), Phase 1 / Phase 2
FW1, FW2, FH = round(W1 * K), round(W2 * K), round(CH * K)
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "enemies", "hollow_cantor")

# palette
ROBE_HI = (244, 240, 255)
ROBE_MID = (196, 180, 252)
ROBE_LO = (112, 82, 200)
SHADOW = (50, 30, 116)
DARK = (16, 9, 38)
DARK2 = (32, 18, 74)
INK = (18, 8, 46)
GLOW = (190, 160, 255)
EYE = (160, 242, 255)
BELL = (238, 230, 255)
SEAM = (252, 249, 255)
TRIM = (248, 244, 255)
GEM = (176, 128, 255)
CYAN = (140, 232, 255)


def lerp(a, b, t):
    return a + (b - a) * t


def smooth(pts, it=2):
    """Chaikin corner cutting: turns angular polygons into soft cloth-like shapes."""
    for _ in range(it):
        n = len(pts)
        out = []
        for i in range(n):
            p, q = pts[i], pts[(i + 1) % n]
            out.append((0.75 * p[0] + 0.25 * q[0], 0.75 * p[1] + 0.25 * q[1]))
            out.append((0.25 * p[0] + 0.75 * q[0], 0.25 * p[1] + 0.75 * q[1]))
        pts = out
    return pts


class Canvas:
    def __init__(self, w, h):
        self.w = w
        self.size = (round(w * SC), round((h + TOP_PAD) * SC))
        self.img = Image.new("RGBA", self.size, (0, 0, 0, 0))
        self._stack = []

    # -- geometry -----------------------------------------------------------------------------------------------
    def P(self, p):
        return (p[0] * SC, (p[1] + TOP_PAD) * SC)

    def _box(self, pts, pad=2):
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        x0 = max(0, int(math.floor(min(xs))) - pad)
        y0 = max(0, int(math.floor(min(ys))) - pad)
        x1 = min(self.size[0], int(math.ceil(max(xs))) + pad)
        y1 = min(self.size[1], int(math.ceil(max(ys))) + pad)
        return x0, y0, x1, y1

    def _blit(self, layer, x0, y0):
        self.img.alpha_composite(layer, (x0, y0))

    # -- layers -------------------------------------------------------------------------------------------------
    def push(self):
        self._stack.append(self.img)
        self.img = Image.new("RGBA", self.size, (0, 0, 0, 0))

    def pop(self):
        layer = self.img
        self.img = self._stack.pop()
        return layer

    # -- primitives ---------------------------------------------------------------------------------------------
    def poly(self, pts, fill, alpha=1.0, grad=None, agrad=None, soft=0):
        """Filled polygon. grad=(c_top, c_bottom) blends vertically across the polygon; agrad=(a_top, a_bottom) fades alpha; soft=n rounds corners."""
        if soft:
            pts = smooth(pts, soft)
        pp = [self.P(p) for p in pts]
        x0, y0, x1, y1 = self._box(pp)
        if x1 <= x0 or y1 <= y0:
            return
        w, h = x1 - x0, y1 - y0
        m = Image.new("L", (w, h), 0)
        ImageDraw.Draw(m).polygon([(x - x0, y - y0) for x, y in pp], fill=255)
        arr = np.zeros((h, w, 4), np.uint8)
        gy0 = min(p[1] for p in pp)
        gy1 = max(p[1] for p in pp)
        rows = np.arange(y0, y1)
        t = np.clip((rows - gy0) / max(1.0, gy1 - gy0), 0, 1)[:, None]
        if grad is None:
            arr[:, :, 0], arr[:, :, 1], arr[:, :, 2] = fill
        else:
            for k in range(3):
                arr[:, :, k] = (grad[0][k] + (grad[1][k] - grad[0][k]) * t).astype(np.uint8)
        a = np.array(m, np.float32) / 255.0 * alpha
        if agrad is not None:
            a = a * (agrad[0] + (agrad[1] - agrad[0]) * t)
        arr[:, :, 3] = np.clip(a * 255, 0, 255).astype(np.uint8)
        self._blit(Image.fromarray(arr, "RGBA"), x0, y0)

    def line(self, pts, color, width, alpha=1.0):
        pp = [self.P(p) for p in pts]
        wpx = max(1.0, width * SC)
        x0, y0, x1, y1 = self._box(pp, int(wpx) + 3)
        if x1 <= x0 or y1 <= y0:
            return
        l = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
        d = ImageDraw.Draw(l)
        c = color + (int(255 * alpha),)
        q = [(x - x0, y - y0) for x, y in pp]
        d.line(q, fill=c, width=int(wpx), joint="curve")
        r = wpx / 2.0
        for p in (q[0], q[-1]):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=c)
        self._blit(l, x0, y0)

    def circle(self, c, r, color, alpha=1.0, outline=False, width=1.0):
        x, y = self.P(c)
        rr = r * SC
        x0, y0, x1, y1 = self._box([(x - rr, y - rr), (x + rr, y + rr)], int(width * SC) + 3)
        if x1 <= x0 or y1 <= y0:
            return
        l = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
        d = ImageDraw.Draw(l)
        box = [x - x0 - rr, y - y0 - rr, x - x0 + rr, y - y0 + rr]
        if outline:
            d.ellipse(box, outline=color + (int(255 * alpha),), width=max(1, int(width * SC)))
        else:
            d.ellipse(box, fill=color + (int(255 * alpha),))
        self._blit(l, x0, y0)

    def ellipse(self, c, rx, ry, color, alpha=1.0, outline=False, width=1.0):
        x, y = self.P(c)
        a, b = rx * SC, ry * SC
        x0, y0, x1, y1 = self._box([(x - a, y - b), (x + a, y + b)], int(width * SC) + 3)
        if x1 <= x0 or y1 <= y0:
            return
        l = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
        d = ImageDraw.Draw(l)
        box = [x - x0 - a, y - y0 - b, x - x0 + a, y - y0 + b]
        if outline:
            d.ellipse(box, outline=color + (int(255 * alpha),), width=max(1, int(width * SC)))
        else:
            d.ellipse(box, fill=color + (int(255 * alpha),))
        self._blit(l, x0, y0)

    def arc(self, c, r, a0, a1, color, width, alpha=1.0, squash=1.0):
        x, y = self.P(c)
        rr = r * SC
        x0, y0, x1, y1 = self._box([(x - rr, y - rr * squash), (x + rr, y + rr * squash)], int(width * SC) + 3)
        if x1 <= x0 or y1 <= y0:
            return
        l = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
        ImageDraw.Draw(l).arc([x - x0 - rr, y - y0 - rr * squash, x - x0 + rr, y - y0 + rr * squash], a0, a1,
                              fill=color + (int(255 * alpha),), width=max(1, int(width * SC)))
        self._blit(l, x0, y0)

    def hatch(self, pts, spacing, angle, color, alpha=0.2, width=0.5, soft=0):
        """Fine line pattern (brocade / weave) clipped to a polygon."""
        if soft:
            pts = smooth(pts, soft)
        pp = [self.P(p) for p in pts]
        x0, y0, x1, y1 = self._box(pp, 1)
        if x1 <= x0 or y1 <= y0:
            return
        w, h = x1 - x0, y1 - y0
        m = Image.new("L", (w, h), 0)
        ImageDraw.Draw(m).polygon([(x - x0, y - y0) for x, y in pp], fill=255)
        lines = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(lines)
        sp = spacing * SC
        ca, sa = math.cos(angle), math.sin(angle)
        reach = w + h
        k = -reach
        while k < reach:
            ox, oy = w / 2 + (-sa) * k, h / 2 + ca * k
            d.line([(ox - ca * reach, oy - sa * reach), (ox + ca * reach, oy + sa * reach)], fill=255, width=max(1, int(width * SC)))
            k += sp
        a = ImageChops.multiply(lines, m).point(lambda v: int(v * alpha))
        col = Image.new("RGBA", (w, h), color + (255,))
        col.putalpha(a)
        self._blit(col, x0, y0)

    # -- light --------------------------------------------------------------------------------------------------
    def glow(self, draw_fn, bounds, blur, color, strength=1.0):
        """draw_fn(draw, ox, oy) paints white shapes (pixel coords minus offsets); bounds are art-unit points of the area."""
        bp = [self.P(p) for p in bounds]
        pad = int(blur * SC * 3) + 2
        x0, y0, x1, y1 = self._box(bp, pad)
        if x1 <= x0 or y1 <= y0:
            return
        m = Image.new("L", (x1 - x0, y1 - y0), 0)
        draw_fn(ImageDraw.Draw(m), x0, y0)
        m = m.filter(ImageFilter.GaussianBlur(blur * SC))
        m = m.point(lambda v: min(255, int(v * strength)))
        col = Image.new("RGBA", m.size, color + (255,))
        col.putalpha(m)
        self._blit(col, x0, y0)

    def rays(self, origin, angles, length, half_width, color, strength=1.0):
        """Soft volumetric rays: thin wedges from `origin`, fading with distance and slightly blurred."""
        ox_, oy_ = self.P(origin)
        L = length * SC
        x0, y0 = max(0, int(ox_ - L)), max(0, int(oy_ - L))
        x1, y1 = min(self.size[0], int(ox_ + L)), min(self.size[1], int(oy_ + L))
        if x1 <= x0 or y1 <= y0:
            return
        m = Image.new("L", (x1 - x0, y1 - y0), 0)
        d = ImageDraw.Draw(m)
        for a in angles:
            w = half_width[0] if isinstance(half_width, tuple) else half_width
            d.polygon([(ox_ - x0, oy_ - y0), (ox_ - x0 + math.cos(a - w) * L * 1.05, oy_ - y0 + math.sin(a - w) * L * 1.05),
                       (ox_ - x0 + math.cos(a + w) * L * 1.05, oy_ - y0 + math.sin(a + w) * L * 1.05)], fill=255)
        m = m.filter(ImageFilter.GaussianBlur(1.6 * SC))
        yy, xx = np.mgrid[y0:y1, x0:x1]
        dist = np.sqrt((xx - ox_) ** 2 + (yy - oy_) ** 2) / L
        fall = np.clip(1.0 - dist, 0, 1) ** 1.7
        a = np.array(m, np.float32) / 255.0 * fall * strength
        arr = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
        arr[:, :, 0], arr[:, :, 1], arr[:, :, 2] = color
        arr[:, :, 3] = np.clip(a * 255, 0, 255).astype(np.uint8)
        self._blit(Image.fromarray(arr, "RGBA"), x0, y0)

    def glow_circle(self, c, r, blur, color, strength=1.0):
        x, y = self.P(c)
        rr = r * SC
        self.glow(lambda d, ox, oy: d.ellipse([x - ox - rr, y - oy - rr, x - ox + rr, y - oy + rr], fill=255),
                  [(c[0] - r, c[1] - r), (c[0] + r, c[1] + r)], blur, color, strength)

    def glow_ellipse(self, c, rx, ry, blur, color, strength=1.0):
        x, y = self.P(c)
        a, b = rx * SC, ry * SC
        self.glow(lambda d, ox, oy: d.ellipse([x - ox - a, y - oy - b, x - ox + a, y - oy + b], fill=255),
                  [(c[0] - rx, c[1] - ry), (c[0] + rx, c[1] + ry)], blur, color, strength)

    def glow_line(self, pts, width, blur, color, strength=1.0):
        pp = [self.P(p) for p in pts]
        wpx = max(1, int(width * SC))
        self.glow(lambda d, ox, oy: d.line([(x - ox, y - oy) for x, y in pp], fill=255, width=wpx, joint="curve"), pts, blur, color, strength)

    def glow_poly(self, pts, blur, color, strength=1.0, outline=0.0):
        pp = [self.P(p) for p in pts]
        if outline > 0:
            self.glow(lambda d, ox, oy: d.line([(x - ox, y - oy) for x, y in pp] + [(pp[0][0] - ox, pp[0][1] - oy)], fill=255,
                                               width=max(1, int(outline * SC)), joint="curve"), pts, blur, color, strength)
        else:
            self.glow(lambda d, ox, oy: d.polygon([(x - ox, y - oy) for x, y in pp], fill=255), pts, blur, color, strength)


_NOISE = {}


def fabric_noise(size, seed=11):
    """Static low-frequency + fine-grain noise in [-1, 1], vertical fibre streaks for cloth."""
    key = (size, seed)
    if key not in _NOISE:
        rng = np.random.RandomState(seed)
        w, h = size
        low = rng.normal(0, 1, (h // 24 + 2, w // 24 + 2)).astype(np.float32)
        low = np.array(Image.fromarray(low).resize((w, h), Image.BICUBIC))
        fine = rng.normal(0, 1, (h, w)).astype(np.float32)
        row = rng.normal(0, 1, w).astype(np.float32)
        kern = np.exp(-0.5 * (np.arange(-8, 9) / 3.0) ** 2)
        row = np.convolve(row, kern / kern.sum(), mode="same")
        row = row / (row.std() + 1e-6)
        streak = np.repeat(row[None, :], h, axis=0)
        _NOISE[key] = np.clip(0.7 * low + 0.25 * fine + 0.35 * streak, -2.5, 2.5)
    return _NOISE[key]


def add_body(cv, body, outline=1.5, rim=True, grain=0.07):
    """Composite a body layer with ink outline, fabric grain, rim light and inner shadow."""
    a = body.getchannel("A")
    # ink outline: dilated alpha behind the body
    r = outline * SC
    big = a.filter(ImageFilter.GaussianBlur(r * 0.8)).point(lambda v: 255 if v > 22 else 0)
    big = big.filter(ImageFilter.GaussianBlur(0.6 * SC / 2))
    ink = Image.new("RGBA", body.size, INK + (255,))
    ink.putalpha(ImageChops.multiply(big, Image.new("L", body.size, 235)))
    cv.img.alpha_composite(ink)
    # grain + volume lighting (top lit by the halo, deeper violet toward the hem and the far side)
    arr = np.array(body).astype(np.float32)
    n = fabric_noise(body.size)
    mod = 1.0 + grain * n[:, :, None]
    hh, ww = arr.shape[:2]
    ys = np.where(np.array(a).max(axis=1) > 20)[0]
    if len(ys):
        yt, yb = ys.min(), ys.max()
        fy = np.clip((np.arange(hh) - yt) / max(1.0, yb - yt), 0, 1)
        vol_y = (1.05 - 0.40 * fy ** 1.1)[:, None, None]
        vol_x = (0.94 + 0.12 * np.linspace(0, 1, ww))[None, :, None]
        tint = np.ones((hh, ww, 3), np.float32)
        tint[:, :, 0] -= 0.10 * fy[:, None] ** 1.5
        tint[:, :, 1] -= 0.14 * fy[:, None] ** 1.5
        mod = mod * vol_y * vol_x * tint
    arr[:, :, :3] = np.clip(arr[:, :, :3] * mod, 0, 255)
    body = Image.fromarray(arr.astype(np.uint8), "RGBA")
    cv.img.alpha_composite(body)
    if rim:
        d = int(1.7 * SC)
        sh = ImageChops.offset(a, d, d)
        edge = ImageChops.subtract(a, sh)                      # top-left facing edges
        edge = edge.filter(ImageFilter.GaussianBlur(0.5 * SC / 2))
        rimc = Image.new("RGBA", body.size, (236, 246, 255, 255))
        rimc.putalpha(ImageChops.multiply(edge, Image.new("L", body.size, 150)))
        cv.img.alpha_composite(rimc)
        sh2 = ImageChops.offset(a, -d, -d)
        edge2 = ImageChops.subtract(a, sh2).filter(ImageFilter.GaussianBlur(0.8 * SC / 2))   # bottom-right inner shadow
        shc = Image.new("RGBA", body.size, SHADOW + (255,))
        shc.putalpha(ImageChops.multiply(edge2, Image.new("L", body.size, 150)))
        cv.img.alpha_composite(shc)


def tapered(points, widths):
    left, right = [], []
    n = len(points)
    for i in range(n):
        p = points[i]
        a = points[max(0, i - 1)]
        b = points[min(n - 1, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / L, dx / L
        w = widths[i] / 2.0
        left.append((p[0] + nx * w, p[1] + ny * w))
        right.append((p[0] - nx * w, p[1] - ny * w))
    return left + right[::-1]


def bell_outline(cx, top, height, width, n=24):
    pts = []
    for i in range(n + 1):
        t = i / n
        y = top + height * t
        if t < 0.35:
            hw = width * 0.5 * math.sin(t / 0.35 * math.pi / 2) ** 0.7 * 0.72
        else:
            u = (t - 0.35) / 0.65
            hw = width * 0.5 * (0.72 + 0.28 * u ** 2.2)
        pts.append((cx + hw, y))
    left = [(2 * cx - p[0], p[1]) for p in pts[::-1]]
    return pts + left


def bell_glyph(cv, c, size, color=BELL, alpha=1.0, outline=True):
    cx, cy = c
    pts = bell_outline(cx, cy - size * 0.5, size, size * 0.9, 12)
    if outline:
        cv.poly([(x + (x - cx) * 0.22, y + (y - cy) * 0.12) for x, y in pts], INK, 0.85 * alpha)
    cv.poly(pts, color, alpha, grad=(SEAM, ROBE_MID))
    cv.circle((cx, cy + size * 0.5 + size * 0.12), size * 0.11, color, alpha)


def sparkle(cv, c, r, color=SEAM, alpha=1.0):
    x, y = c
    cv.glow_circle(c, r * 0.9, r * 0.5, color, 0.55 * alpha)
    cv.line([(x - r, y), (x + r, y)], color, 0.5, alpha)
    cv.line([(x, y - r), (x, y + r)], color, 0.5, alpha)
    cv.circle(c, r * 0.28, color, alpha)


class Pose(dict):
    def __getattr__(self, k):
        return self.get(k)


def default_pose(**kw):
    p = Pose(
        bob=0.0, sway=0.0, lean=0.0, t=0.0, flare=0.0, glow=1.0, eye=1.0, alpha=1.0, brk=0.0, recoil=0.0, tollspark=0.0,
        r_el=(40, 120), r_wr=(62, 92), r_dir=-0.35, r_spread=0.20, r_curl=0.35,
        l_el=(-34, 124), l_wr=(-48, 150), l_dir=1.9, l_spread=0.16, l_curl=0.25,
    )
    p.update(kw)
    return p


def render(pose, p2=False):
    W = W2 if p2 else W1
    cv = Canvas(W, H)
    cx = W / 2.0
    t = pose.t
    ph0 = t * 2 * math.pi
    bob = pose.bob
    lean = pose.lean + pose.recoil
    sway = pose.sway
    brk = pose.brk                          # 0..1 defeat progress
    fl = pose.flare + (0.7 if p2 else 0.0)
    gl = pose.glow * (1.35 if p2 else 1.0)
    keep = 1.0 - brk
    base = H - 19 + bob * 0.3
    sh_y = 90 + bob
    hx, hy = cx + 9 + lean * 0.5, 50 + bob
    sx = cx + lean * 0.6
    top_y = 148 + bob
    crown = (1.0 + (0.4 if p2 else 0.0)) + 0.05 * math.sin(ph0) + pose.tollspark * 0.1

    # ============================================================== BACK LIGHT (behind the figure)
    cv.glow_ellipse((cx + 3, 140 + bob), 62 + 20 * fl, 112, 16, (112, 74, 226), 0.46 * keep)
    # volumetric rays fanning from the halo (soft, fading with distance)
    rays = 17 if p2 else 11
    angs = [-math.pi / 2 + (k - (rays - 1) / 2) * (0.27 if p2 else 0.25) + 0.035 * math.sin(ph0 + k) for k in range(rays)]
    cv.rays((hx + 2, hy - 6), angs, 90 if p2 else 92, 0.035, GLOW, (0.55 if p2 else 0.34) * keep * min(gl, 1.4))
    cv.rays((hx + 2, hy - 6), [a + 0.12 for a in angs[::2]], 72 if p2 else 70, 0.02, ROBE_HI, (0.4 if p2 else 0.22) * keep)
    if p2:
        # shockwave rings on the ground under the hem
        for k in range(3):
            u = (t + k / 3.0) % 1.0
            cv.ellipse((cx + 4, H - 8), 36 + 90 * u, 7 + 17 * u, GLOW, 0.55 * (1 - u) * keep, outline=True, width=1.4)
        cv.glow_ellipse((cx + 4, H - 8), 70, 12, 8, (150, 110, 255), 0.5 * keep)
        # energy wings: bold layered spectral blades sweeping up and out behind the shoulders
        for side in (-1, 1):
            for k in range(6):
                ph = ph0 + k * 0.8 + (0 if side > 0 else 1.7)
                reach = 52 + k * 18
                rise = (92 - k * 13) * (0.8 + 0.2 * math.sin(ph))
                pts = []
                for i in range(14):
                    u = i / 13.0
                    ang_u = u * 1.35
                    px = sx + side * (10 + reach * math.sin(ang_u + 0.15) * (0.55 + 0.45 * u))
                    py = sh_y - 2 - rise * (1 - math.cos(ang_u)) * 0.95 + 36 * u ** 2.2 * (0.5 + 0.18 * k)
                    pts.append((px + 3 * math.sin(ph + u * 3), py))
                widths = [4 + 22 * math.sin(math.pi * (i / 13.0)) ** 0.8 * (1.0 - 0.07 * k) for i in range(14)]
                blade = tapered(pts, widths)
                cv.poly(blade, GLOW, (0.42 - 0.04 * k) * keep, grad=(ROBE_HI, ROBE_LO), soft=1)
                cv.line(pts, SEAM, 1.0, (0.85 - 0.08 * k) * keep)
                cv.glow_line(pts, 2.0, 3.0, (176, 146, 255), 0.7 * keep)
                inner_edge = [(x, y + 1.5) for x, y in pts[2:-2]]
                cv.line(inner_edge, ROBE_HI, 0.6, 0.5 * keep)

    # ============================================================== BELL HALO (emissive, behind head and shoulders)
    bell_h, bell_w = 96 * crown, 76 * crown
    bpts = bell_outline(hx + 2, hy - 30 * crown, bell_h, bell_w, 28)
    if brk > 0:
        bpts = [(x + (16 * brk if x > hx else -16 * brk), y + 7 * brk) for x, y in bpts]
    ring = bpts + [bpts[0]]
    cv.poly(bpts, ROBE_MID, 0.22 * keep, grad=(ROBE_HI, ROBE_LO), agrad=(0.60, 0.12))
    cv.glow_poly(bpts, 4.2, GLOW, 1.15 * gl * keep, outline=5.0)
    cv.line(ring, SEAM, 1.9, 0.97 * keep)
    inner = [(hx + 2 + (x - hx - 2) * 0.84, hy - 30 * crown + (y - (hy - 30 * crown)) * 0.88 + 5) for x, y in bpts]
    cv.line(inner[2:-2], GLOW, 1.0, 0.6 * keep)
    for k in range(3, len(bpts) - 3, 3):
        cv.circle(bpts[k], 1.35, SEAM, 0.95 * keep)                # studs along the rim
    for sgn in (-1, 1):                                              # bell finials at the lip
        lipx = hx + 2 + sgn * bell_w * 0.5
        lipy = hy - 30 * crown + bell_h
        bell_glyph(cv, (lipx, lipy + 3), 7.5, BELL, 0.95 * keep)
    cv.line([(hx + 2, hy - 30 * crown + bell_h * 0.47), (hx + 2, hy - 30 * crown + bell_h * 0.47 + 10)], SEAM, 1.3, 0.8 * keep)
    cv.circle((hx + 2, hy - 30 * crown + bell_h * 0.47 + 12), 3.1, SEAM, 0.9 * keep)
    cv.glow_circle((hx + 2, hy + 4), 34 * crown, 14, (160, 120, 255), 0.55 * gl * keep)
    if p2:
        # second, outer halo ring (a larger bell) and a crown of tiny orbiting bells
        big = bell_outline(hx + 2, hy - 30 * crown - 16, bell_h * 1.18, bell_w * 1.32, 28)
        cv.glow_poly(big, 3.4, GLOW, 0.8 * keep, outline=3.0)
        cv.line(big + [big[0]], BELL, 1.0, 0.7 * keep)
        for k in range(10):
            a = ph0 + k * (2 * math.pi / 10)
            bx = hx + 2 + math.cos(a) * bell_w * 0.78
            by = hy - 30 * crown + bell_h * 0.46 + math.sin(a) * bell_h * 0.5
            bell_glyph(cv, (bx, by), 5.5, BELL, 0.9 * keep)

    # ============================================================== BODY LAYER (outlined)
    cv.push()
    a_b = keep * pose.alpha
    # ---- long ceremonial cape hanging behind the body (gives the thin figure its mass and a dramatic silhouette)
    for side, wsc, al in ((-1, 1.0, 0.92), (1, 0.62, 0.8)):
        sway_c = sway * 0.8 + 3.0 * math.sin(ph0 - 0.8) * (1 if side < 0 else 0.6)
        top = (sx + side * 12, sh_y + 6)
        spread = 11 * wsc + 22 * fl
        cape = [top, (sx + side * (24 + 4 * wsc), sh_y + 44), (sx + side * (spread + 18) + sway_c * 0.6, top_y + 24), (sx + side * (spread + 26) + sway_c, base - 34),
                (sx + side * (spread * 0.62) + sway_c * 1.2, base - 12), (sx + side * (spread * 0.30) + sway_c * 1.1, base - 28), (sx + side * 6, base - 40),
                (sx + side * 4, top_y + 6)]
        cv.poly(cape, ROBE_LO, al * a_b, grad=(ROBE_MID, DARK2), soft=2)
        cv.hatch(cape, 4.2, 0.75, ROBE_HI, 0.20 * a_b, 0.45, soft=2)
        cv.hatch(cape, 4.2, -0.75, ROBE_HI, 0.14 * a_b, 0.45, soft=2)
        cv.poly([top, (sx + side * (24 + 4 * wsc), sh_y + 44), (sx + side * 12, top_y + 20), (sx + side * 4, top_y + 6)], SHADOW, 0.55 * a_b, soft=1)
        for k in range(3):
            fo = 0.28 + 0.24 * k
            cv.line([(sx + side * (12 + 10 * fo), sh_y + 18), (sx + side * (spread * fo + 12) + sway_c * 0.6 * fo, top_y + 20), (sx + side * (spread * fo * 1.06 + 14) + sway_c * fo, base - 40)], SHADOW, 0.9, 0.55 * a_b)
        cv.line(cape[2:5], TRIM, 1.0, 0.85 * a_b)
        cv.line([cape[1], cape[2]], ROBE_HI, 0.8, 0.5 * a_b)
        cv.circle((cape[3][0], cape[3][1]), 1.6, GEM, a_b)
        bell_glyph(cv, (cape[4][0], cape[4][1] + 5), 6.5, BELL, 0.95 * a_b)

    # ---- rear robe train: five floating tabards
    n_plate = 5
    hem_y = base
    for i in range(n_plate):
        u0, u1 = i / n_plate, (i + 1) / n_plate
        y0 = top_y + (hem_y - top_y) * u0 + 1.6
        y1 = top_y + (hem_y - top_y) * u1 - 4.2
        w0 = 13 + 46 * (u0 ** 1.5) + 24 * fl * u0 + (3 if i % 2 else 0)
        w1 = 13 + 46 * (u1 ** 1.5) + 24 * fl * u1 + (3 if i % 2 else 0)
        ph = ph0 - i * 0.55
        dx = sway * (0.5 + u0) + 2.6 * math.sin(ph) * (0.4 + u0) - 4 * u0 * lean * 0.3
        dy = brk * (10 + 14 * i) * (1 if i % 2 == 0 else 0.6)
        dxb = brk * (i - 2.0) * 10
        c0 = cx + dx + dxb - 3 * u0 + (1.0 if i % 2 else -0.8)
        c1 = cx + dx * 1.1 + dxb - 3 * u1 + (1.0 if i % 2 else -0.8)
        tip = 11.0 if i < n_plate - 1 else 14.0
        dy = min(dy, (H - 7) - (y1 + tip))
        a = a_b
        yb = y1 + dy
        y0d = y0 + dy
        shape = [(c0 - w0 / 2, y0d), (c0 + w0 / 2, y0d), (c1 + w1 / 2, yb), (c1 + w1 * 0.25, yb + tip * 0.55), (c1, yb + tip),
                 (c1 - w1 * 0.25, yb + tip * 0.55), (c1 - w1 / 2, yb)]
        # sheer outer panels that billow past the plate and show the dark body between folds
        for sgn in (-1, 1):
            cv.poly([(c0 + sgn * w0 / 2, y0d + 2), (c0 + sgn * (w0 / 2 + 5 + 7 * u0 + 10 * fl), y0d + (yb - y0d) * 0.55),
                     (c1 + sgn * (w1 / 2 + 3 + 5 * fl), yb + tip * 0.35), (c1 + sgn * w1 / 2, yb)], ROBE_MID, 0.32 * a, grad=(ROBE_HI, ROBE_LO))
        cv.poly([(c0 - w0 * 0.3, y0d), (c0 + w0 * 0.3, y0d), (c1 + w1 * 0.26, yb), (c1, yb + tip * 0.7), (c1 - w1 * 0.26, yb)], DARK, 0.96 * a, soft=1)
        cv.poly(shape, ROBE_MID, 0.90 * a, grad=(ROBE_HI, ROBE_MID), soft=2)
        cv.hatch(shape, 3.2, math.pi / 2 - 0.14, ROBE_LO, 0.30 * a, 0.4, soft=2)
        # tone 2: shadow side and lower hem
        cv.poly([shape[0], (shape[0][0] + w0 * 0.40, y0d), (c1 - w1 * 0.08, yb + tip * 0.62), shape[5], shape[6]], ROBE_LO, 0.78 * a, soft=1)
        cv.poly([shape[0], (shape[0][0] + w0 * 0.20, y0d), (c1 - w1 * 0.28, yb + tip * 0.4), shape[6]], SHADOW, 0.72 * a, soft=1)
        # contact shadow from the plate above
        cv.poly([(c0 - w0 / 2, y0d), (c0 + w0 / 2, y0d), (c0 + w0 / 2 - 1, y0d + 8), (c0 - w0 / 2 + 1, y0d + 8)], DARK2, 0.7 * a, agrad=(1.0, 0.0))
        # tone 3: highlight on the lit edge
        cv.poly([(c0 + w0 * 0.30, y0d + 1), (c0 + w0 / 2, y0d + 1), (c1 + w1 / 2, yb), (c1 + w1 * 0.40, yb)], SEAM, 0.50 * a)
        # folds
        for fo, al in ((-0.20, 0.55), (0.04, 0.4), (0.26, 0.5)):
            cv.line([(c0 + w0 * fo, y0d + 5), (c1 + w1 * fo * 1.15, yb + tip * 0.2)], ROBE_LO, 0.8, al * a)
        cv.line([(c0 + w0 * 0.16, y0d + 4), (c1 + w1 * 0.20, yb + tip * 0.3)], SEAM, 0.6, 0.5 * a)
        # silver top band with amethyst gem, embroidery, hem trim
        cv.poly([(c0 - w0 / 2, y0d), (c0 + w0 / 2, y0d), (c0 + w0 / 2 - 0.5, y0d + 3.4), (c0 - w0 / 2 + 0.5, y0d + 3.4)], TRIM, 0.97 * a)
        cv.circle((c0 + 1, y0d + 1.8), 1.7, GEM, a)
        cv.glow_circle((c0 + 1, y0d + 1.8), 3.6, 2.2, GEM, 0.7 * gl * a)
        bell_glyph(cv, (c0 + 1, (y0d + yb) / 2 + 2), 7 + 2 * u1, ROBE_HI, 0.55 * a, outline=False)
        cv.line([(c1 - w1 / 2 + 1, yb - 1.5), (c1 - w1 * 0.25 + 1, yb + tip * 0.55 - 1.5), (c1, yb + tip - 1.8), (c1 + w1 * 0.25 - 1, yb + tip * 0.55 - 1.5), (c1 + w1 / 2 - 1, yb - 1.5)], TRIM, 0.9, 0.9 * a)
        cv.line([(c1 - w1 / 2, yb), (c1 - w1 * 0.25, yb + tip * 0.55), (c1, yb + tip), (c1 + w1 * 0.25, yb + tip * 0.55), (c1 + w1 / 2, yb)], ROBE_LO, 0.9, 0.9 * a)
        if i % 2 == 1:
            tx, ty = c1 + w1 * 0.30, yb - 2
            cv.line([(tx, ty), (tx, ty + 7)], SEAM, 0.9, 0.95 * a)
            bell_glyph(cv, (tx, ty + 11), 6.8, BELL, 0.97 * a)

    # ---- torso: slim hourglass vest under a crossed, sheer ceremonial coat
    a_t = a_b * (1 - brk * 0.9)
    waist_y = sh_y + 48
    vest = [(sx - 13, sh_y + 2), (sx + 15, sh_y + 1), (sx + 11, sh_y + 24), (sx + 6.5, waist_y), (sx + 9, top_y + 5), (sx - 8, top_y + 5), (sx - 6.5, waist_y), (sx - 10, sh_y + 24)]
    cv.poly(vest, DARK, 0.99 * a_t, soft=1)
    flap_a = [(sx - 12, sh_y + 3), (sx + 5, sh_y + 3), (sx + 9, waist_y), (sx + 10, top_y + 5), (sx - 3, top_y + 5), (sx - 6, waist_y)]
    flap_b = [(sx + 15, sh_y + 2), (sx - 1, sh_y + 5), (sx - 6, waist_y), (sx - 8, top_y + 5), (sx + 8, top_y + 4), (sx + 7, waist_y)]
    cv.poly(flap_a, ROBE_LO, 0.96 * a_t, grad=(ROBE_MID, SHADOW), soft=1)
    cv.poly(flap_b, ROBE_MID, 0.84 * a_t, grad=(ROBE_HI, ROBE_LO), soft=1)
    cv.line([(sx + 15, sh_y + 3), (sx - 1, sh_y + 6), (sx - 6, waist_y), (sx - 8, top_y + 4)], TRIM, 1.1, 0.95 * a_t)
    cv.line([(sx - 12, sh_y + 4), (sx + 5, sh_y + 4), (sx + 9, waist_y), (sx + 10, top_y + 4)], ROBE_LO, 0.9, 0.8 * a_t)
    for k in range(4):
        cv.circle((sx + 4 - k * 2.2, sh_y + 12 + k * 9), 0.9, GEM, 0.9 * a_t)
    # sash and chest sigil
    cv.poly([(sx - 8, waist_y - 4), (sx + 9, waist_y - 5), (sx + 8, waist_y + 4), (sx - 7, waist_y + 5)], ROBE_LO, 0.97 * a_t, grad=(ROBE_MID, SHADOW), soft=1)
    cv.line([(sx - 8, waist_y - 4), (sx + 9, waist_y - 5)], TRIM, 1.0, 0.95 * a_t)
    cv.line([(sx - 7, waist_y + 4), (sx + 8, waist_y + 3)], TRIM, 0.8, 0.8 * a_t)
    cv.poly([(sx - 1, waist_y + 4), (sx + 2, waist_y + 4), (sx + 5, waist_y + 19), (sx - 4, waist_y + 19)], ROBE_HI, 0.8 * a_t, grad=(SEAM, ROBE_MID), soft=1)   # sash tail
    bell_glyph(cv, (sx + 1, sh_y + 24), 11.5, BELL, 0.95 * a_t)
    # ---- mantle: three overlapping shoulder plates
    for k, (ox, oy, sc) in enumerate(((-4, 9, 1.22), (1, 3, 1.28), (5, -2, 1.12))):
        m = [(sx - 21 * sc + ox, sh_y + 2 + oy * 0.2), (sx - 14 * sc + ox, sh_y - 9 + oy * 0.3), (sx + 8 + ox, sh_y - 13 + oy * 0.35),
             (sx + 25 * sc + ox, sh_y - 4 + oy * 0.4), (sx + 21 * sc + ox, sh_y + 7 + oy * 0.5), (sx + 6 + ox, sh_y + 12 + oy * 0.5), (sx - 11 + ox, sh_y + 12 + oy * 0.5)]
        if k == 0:
            cv.poly(m, ROBE_LO, 0.95 * a_t, grad=(ROBE_MID, SHADOW), soft=2)
        elif k == 1:
            cv.poly(m, ROBE_MID, 0.96 * a_t, grad=(ROBE_HI, ROBE_LO), soft=2)
        else:
            cv.poly(m, ROBE_HI, 0.55 * a_t, grad=(SEAM, ROBE_MID), soft=2)
        if k == 1:
            cv.hatch(m, 3.4, 0.7, ROBE_LO, 0.30 * a_t, 0.45, soft=2)
            cv.hatch(m, 3.4, -0.7, ROBE_LO, 0.30 * a_t, 0.45, soft=2)
        cv.line(m[:5], TRIM, 1.1, 0.95 * a_t)
        for q in range(1, 4):
            cv.circle(m[q], 1.3, GEM, 0.9 * a_t)
    cv.line([(sx - 16, sh_y + 5), (sx + 18, sh_y + 3)], ROBE_LO, 0.9, 0.7 * a_t)
    # tall collar rising behind the head
    cv.poly([(sx - 6, sh_y - 8), (sx - 13, sh_y - 36), (sx + 2, sh_y - 23), (sx + 17, sh_y - 33), (sx + 14, sh_y - 6)], ROBE_LO, 0.96 * a_t, grad=(ROBE_MID, DARK2))
    cv.line([(sx - 13, sh_y - 36), (sx + 2, sh_y - 23), (sx + 17, sh_y - 33)], TRIM, 1.1, 0.95 * a_t)
    cv.poly([(sx - 3, sh_y - 8), (sx - 8, sh_y - 30), (sx + 2, sh_y - 20), (sx + 12, sh_y - 28), (sx + 11, sh_y - 7)], DARK2, 0.55 * a_t)

    # ---- head: cowl, porcelain mask, veil, ornaments
    a_h = a_b * (1 - brk * 0.9)
    cv.poly([(hx - 12, hy + 6), (hx - 10, hy - 18), (hx - 2, hy - 32), (hx + 13, hy - 24), (hx + 15, hy + 6), (hx + 9, hy + 27), (hx - 5, hy + 24)], ROBE_LO, a_h, grad=(ROBE_MID, DARK2))
    cv.line([(hx - 10, hy - 18), (hx - 2, hy - 32), (hx + 13, hy - 24), (hx + 15, hy + 6)], TRIM, 1.0, 0.9 * a_h)
    cv.poly([(hx - 10, hy - 6), (hx - 3, hy - 22), (hx + 11, hy - 17), (hx + 12, hy + 4), (hx + 4, hy + 24), (hx - 2, hy + 27), (hx - 8, hy + 9)], DARK2, a_h)
    mask = [(hx - 6, hy - 14), (hx + 3, hy - 21), (hx + 11, hy - 14), (hx + 12, hy + 2), (hx + 7, hy + 18), (hx + 2, hy + 25), (hx - 3, hy + 12), (hx - 7, hy - 2)]
    cv.poly(mask, ROBE_HI, 0.99 * a_h, grad=(SEAM, ROBE_MID))
    cv.poly([mask[0], (hx + 1, hy - 18), (hx + 1, hy + 14), (hx - 3, hy + 12), mask[7]], ROBE_LO, 0.55 * a_h)             # far-side shadow
    cv.poly([(hx + 6, hy - 12), mask[2], mask[3], (hx + 9, hy + 6), (hx + 7, hy - 4)], SEAM, 0.7 * a_h)                  # lit cheek
    cv.line([mask[0], mask[1], mask[2], mask[3], mask[4], mask[5], mask[6], mask[7], mask[0]], ROBE_LO, 0.9, 0.85 * a_h)
    cv.line([(hx + 1, hy - 8), (hx + 10, hy - 9)], SHADOW, 0.9, 0.85 * a_h)                                                 # brow
    cv.line([(hx + 4, hy + 4), (hx + 3, hy + 14)], ROBE_LO, 0.7, 0.55 * a_h)                                                # nose / cheek line
    cv.line([(hx + 5, hy + 15), (hx + 8, hy + 12)], ROBE_LO, 0.6, 0.5 * a_h)
    gx, gy = hx + 3.5, hy - 15
    cv.poly([(gx, gy - 3), (gx + 2, gy), (gx, gy + 3), (gx - 2, gy)], GEM, a_h)                                              # forehead gem
    cv.glow_circle((gx, gy), 4.5, 2.6, GEM, 0.9 * gl * a_h)
    # veil panels
    cv.poly([(hx - 7, hy - 10), (hx - 16 - lean * 0.3, hy + 14), (hx - 12, hy + 42), (hx - 2, hy + 24)], ROBE_MID, 0.62 * a_h, grad=(ROBE_HI, ROBE_LO))
    cv.line([(hx - 7, hy - 10), (hx - 12, hy + 42)], SEAM, 0.7, 0.6 * a_h)
    cv.poly([(hx + 8, hy + 14), (hx + 14, hy + 30), (hx + 8, hy + 46), (hx + 3, hy + 28)], ROBE_MID, 0.5 * a_h, grad=(ROBE_HI, ROBE_LO))
    # hanging bell ornaments at the temples
    for ox in (-9, 13):
        cv.line([(hx + ox, hy + 8), (hx + ox, hy + 15)], SEAM, 0.7, 0.9 * a_h)
        bell_glyph(cv, (hx + ox, hy + 19), 5.2, BELL, 0.95 * a_h)
    # eye slit
    ex, ey = hx + 6.5, hy - 2
    eye_a = min(1.0, pose.eye) * a_h
    cv.line([(ex, ey - 5), (ex + 0.5, ey + 6)], (235, 252, 255), 1.5, eye_a)
    cv.line([(ex - 0.3, ey - 3), (ex + 0.3, ey + 4)], (255, 255, 255), 0.6, eye_a)

    # ---- arms: long sleeves, lined cuffs, hanging sheer cloth, conductor's hands
    def arm(sx0, sy0, el, wr, direction, spread, curl, front):
        a = a_b
        S0 = (sx0, sy0)
        E = (cx + el[0] + lean * 0.4, el[1] + bob)
        Wr = (cx + wr[0] + lean * 0.4, wr[1] + bob)
        E = (S0[0] + (E[0] - S0[0]) * 1.12, S0[1] + (E[1] - S0[1]) * 1.12)
        Wr = (E[0] + (Wr[0] - E[0]) * 1.2, E[1] + (Wr[1] - E[1]) * 1.2)
        pts = [S0, ((S0[0] + E[0]) / 2, (S0[1] + E[1]) / 2 + 3), E, ((E[0] + Wr[0]) / 2, (E[1] + Wr[1]) / 2 + 2), Wr]
        cv.poly(tapered(pts, [10.5, 11.5, 10.0, 8.5, 7.0]), ROBE_MID, 0.96 * a, grad=(ROBE_HI, ROBE_LO))
        shade = tapered([(p[0] + 2.2, p[1] + 2.4) for p in pts], [5.0, 5.4, 4.6, 4.0, 3.4])
        cv.poly(shade, SHADOW, 0.78 * a)
        cv.line(pts, SEAM, 0.9, 0.75 * a)
        cv.line([(E[0] - 4, E[1] - 1), (E[0] + 4, E[1] + 1)], TRIM, 0.9, 0.8 * a)
        fa = math.atan2(Wr[1] - E[1], Wr[0] - E[0])
        nrm = (-math.sin(fa), math.cos(fa))
        f = (math.cos(fa), math.sin(fa))
        cw = 12 + (4 if p2 else 0)
        cuff = [(Wr[0] - f[0] * 10 + nrm[0] * 4.5, Wr[1] - f[1] * 10 + nrm[1] * 4.5), (Wr[0] + f[0] * 3 + nrm[0] * cw * 0.5, Wr[1] + f[1] * 3 + nrm[1] * cw * 0.5),
                (Wr[0] + f[0] * 3 - nrm[0] * cw * 0.5, Wr[1] + f[1] * 3 - nrm[1] * cw * 0.5), (Wr[0] - f[0] * 10 - nrm[0] * 4.5, Wr[1] - f[1] * 10 - nrm[1] * 4.5)]
        # sheer sleeve cloth trailing from the cuff
        sway_c = math.sin(ph0 + (0 if front else 1.4)) * 4
        cv.poly([cuff[0], cuff[3], (Wr[0] - f[0] * 14 - 2 + sway_c, Wr[1] + 24 + sway_c), (Wr[0] - f[0] * 6 + 8 + sway_c, Wr[1] + 18)], ROBE_MID, 0.42 * a, grad=(ROBE_HI, ROBE_LO))
        cv.poly(cuff, ROBE_HI, 0.96 * a, grad=(SEAM, ROBE_LO))
        cv.poly([cuff[1], cuff[2], (cuff[2][0] - f[0] * 5, cuff[2][1] - f[1] * 5), (cuff[1][0] - f[0] * 5, cuff[1][1] - f[1] * 5)], DARK2, 0.7 * a)   # lining
        cv.line([cuff[1], cuff[2]], TRIM, 1.2, 0.97 * a)
        cv.circle(((cuff[1][0] + cuff[2][0]) / 2 - f[0] * 2, (cuff[1][1] + cuff[2][1]) / 2 - f[1] * 2), 1.5, GEM, a)
        hand = (Wr[0] + f[0] * 4, Wr[1] + f[1] * 4)
        cv.poly([(hand[0] + nrm[0] * 3.2, hand[1] + nrm[1] * 3.2), (hand[0] + f[0] * 8 + nrm[0] * 2.6, hand[1] + f[1] * 8 + nrm[1] * 2.6),
                 (hand[0] + f[0] * 8 - nrm[0] * 2.6, hand[1] + f[1] * 8 - nrm[1] * 2.6), (hand[0] - nrm[0] * 3.2, hand[1] - nrm[1] * 3.2)], ROBE_HI, 0.99 * a, grad=(SEAM, ROBE_MID))
        flen = 24 + (4 if p2 else 0)
        for k in range(5):
            aa = direction + (k - 2) * spread
            l = flen * (0.78 if k in (0, 4) else 1.0) * (1.08 if k == 2 else 1.0)
            o = (hand[0] + f[0] * 7, hand[1] + f[1] * 7)
            p1 = (o[0] + math.cos(aa) * l * 0.5, o[1] + math.sin(aa) * l * 0.5)
            a2 = aa + curl * (1 if k < 2 else -0.4)
            p2_ = (p1[0] + math.cos(a2) * l * 0.38, p1[1] + math.sin(a2) * l * 0.38)
            p3 = (p2_[0] + math.cos(a2 + curl) * l * 0.18, p2_[1] + math.sin(a2 + curl) * l * 0.18)
            cv.poly(tapered([o, p1, p2_, p3], [2.6, 2.2, 1.7, 1.0]), ROBE_HI, 0.99 * a)
            cv.line([o, p1, p2_, p3], ROBE_LO, 0.5, 0.45 * a)
            cv.circle(p3, 0.8, SEAM, a)
            for jp in (p1, p2_):
                cv.circle(jp, 0.7, ROBE_LO, 0.7 * a)
        return hand

    arm(sx - 17, sh_y + 4, pose.l_el, pose.l_wr, pose.l_dir, pose.l_spread, pose.l_curl, False)
    hand_r = arm(sx + 17, sh_y + 2, pose.r_el, pose.r_wr, pose.r_dir, pose.r_spread, pose.r_curl, True)
    add_body(cv, cv.pop(), outline=1.35, grain=0.075)

    # ============================================================== FRONT EFFECTS
    # resonance threads from the conducting hand (soft, glowing, thicker in Phase 2)
    if brk < 0.6:
        for k in range(4 + (3 if p2 else 0)):
            ph = ph0 + k
            a0 = pose.r_dir + (k - 1.5) * 0.26
            pts = []
            for i in range(10):
                u = i / 9
                r = 6 + (44 if p2 else 36) * u
                pts.append((hand_r[0] + math.cos(a0 + 0.38 * math.sin(ph + u * 3)) * r, max(6.0, hand_r[1] + math.sin(a0 + 0.38 * math.sin(ph + u * 3)) * r)))
            cv.glow_line(pts, 1.0, 2.0, (170, 140, 255), (0.8 - 0.1 * k) * keep)
            cv.line(pts, SEAM, 0.55, (0.8 - 0.1 * k) * keep)
    # chest sigil, eye and gem bloom
    cv.glow_circle((sx + 1, sh_y + 24), 9 + (4 if p2 else 0), 4, (176, 140, 255), 0.9 * gl * a_t)
    cv.glow_line([(ex, ey - 5), (ex + 0.5, ey + 6)], 2.8, 3.0 + (2.0 if p2 else 0), EYE, 1.5 * min(1.0, pose.eye) * gl * a_h)
    cv.glow_circle((ex, ey), 2.4, 1.6, (240, 255, 255), 1.0 * min(1.0, pose.eye) * a_h)
    if p2:
        # eye flare: cross streaks and a long trailing light
        cv.line([(ex - 14, ey), (ex + 14, ey)], EYE, 0.6, 0.65 * a_h)
        cv.line([(ex, ey - 12), (ex, ey + 12)], EYE, 0.6, 0.45 * a_h)
        cv.line([(ex, ey), (ex - 26, ey - 9)], EYE, 0.9, 0.55 * a_h)
        cv.glow_line([(ex, ey), (ex - 26, ey - 9)], 1.4, 2.6, EYE, 0.7 * a_h)
    if pose.tollspark > 0:
        k = pose.tollspark
        cv.glow_circle(hand_r, 18 * k, 6, SEAM, 1.3)
        for r_ in (10, 20, 30, 42):
            cv.arc(hand_r, r_ * k, 0, 360, SEAM, 1.3, 0.9 * (1 - r_ / 50))
        for i in range(8):
            aa = i * math.pi / 4 + 0.3
            cv.line([(hand_r[0] + math.cos(aa) * 8 * k, hand_r[1] + math.sin(aa) * 8 * k), (hand_r[0] + math.cos(aa) * 30 * k, hand_r[1] + math.sin(aa) * 30 * k)], SEAM, 0.8, 0.8)

    # suspended bell fragments / resonance shards / sparkles
    nfrag = 16 if p2 else 8
    rng = np.random.RandomState(7)
    for k in range(nfrag):
        ang0 = rng.uniform(0, 2 * math.pi)
        rad = rng.uniform(46, 78) + (22 if p2 else 0)
        yc = rng.uniform(64, 222)
        ph = ph0 * (1 if k % 2 == 0 else -1) + ang0
        fx = cx + math.cos(ph) * rad * 0.64 + (6 if k % 3 == 0 else -4)
        fy = yc + 6 * math.sin(ph * 1.7) + bob * 0.7
        scatter = brk * (20 + 60 * (k / nfrag))
        fx += math.cos(ang0) * scatter
        fy += math.sin(ang0) * scatter * 0.7 - brk * 30
        fa = (1 - brk * 0.55) * pose.alpha
        sz = rng.uniform(5.5, 10.0)
        if k % 3 == 0:
            cv.glow_circle((fx, fy), sz * 0.8, 2.6, GLOW, 0.8 * gl * fa)
            bell_glyph(cv, (fx, fy), sz, BELL, 0.97 * fa)
        elif k % 3 == 1:
            tri = [(fx, fy - sz), (fx + sz * 0.55, fy + sz * 0.7), (fx - sz * 0.55, fy + sz * 0.4)]
            cv.poly([(x + (x - fx) * 0.25, y + (y - fy) * 0.25) for x, y in tri], INK, 0.85 * fa)
            cv.poly(tri, ROBE_HI, 0.97 * fa, grad=(SEAM, ROBE_LO))
            cv.line(tri + [tri[0]], SEAM, 0.7, 0.9 * fa)
            cv.glow_circle((fx, fy), sz * 0.7, 2.2, GLOW, 0.6 * gl * fa)
        else:
            cv.circle((fx, fy), sz * 0.75, GLOW, 0.9 * fa, outline=True, width=1.0)
            cv.circle((fx, fy), sz * 0.22, SEAM, fa)
    for k in range(10 if p2 else 5):
        sparkle(cv, (cx + rng.uniform(-80, 90), rng.uniform(40, 230) + bob * 0.5), rng.uniform(2.0, 4.2), SEAM, (0.5 + 0.5 * math.sin(ph0 * 2 + k)) * keep)
    if p2:
        for k in range(3):                                        # extra resonance rings
            ph = (t + k / 3.0) % 1.0
            cv.arc((cx + 4, 130 + bob), 44 + 62 * ph, 0, 360, GLOW, 1.2, 0.42 * (1 - ph) * keep)
    return cv.finish(FW2 if p2 else FW1, FH)


def _finish(self, w, h):
    out = self.img.resize((w, h), Image.LANCZOS)
    # bloom: only the brightest parts bleed light; then a safety fade over the outer border so no frame touches its edge
    arr = np.array(out).astype(np.float32)
    lum = arr[:, :, :3].min(axis=2)
    mask = np.where((lum > 232) & (arr[:, :, 3] > 120), 1.0, 0.0).astype(np.float32)
    bm = Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(4.0))
    bl = np.array(bm).astype(np.float32) / 255.0
    bloom = np.zeros_like(arr)
    bloom[:, :, 0], bloom[:, :, 1], bloom[:, :, 2] = 205, 180, 255
    bloom[:, :, 3] = np.clip(bl * 105, 0, 255)
    out = Image.fromarray(arr.astype(np.uint8), "RGBA")
    out = Image.alpha_composite(Image.fromarray(bloom.astype(np.uint8), "RGBA"), out)
    arr = np.array(out).astype(np.float32)
    hh, ww = arr.shape[:2]
    yy = np.arange(hh)[:, None]
    xx = np.arange(ww)[None, :]
    def smoothstep(v):
        v = np.clip(v, 0, 1)
        return v * v * (3 - 2 * v)
    # light fades out over the outer 26 px (top/sides) so nothing is cut off at the border; 4 px at the bottom (the hem anchor)
    fx = smoothstep((np.minimum(xx, ww - 1 - xx) - 1.5) / 26.0)
    fy = smoothstep(np.minimum((yy - 1.5) / 36.0, (hh - 1 - yy - 1.5) / 4.0))
    arr[:, :, 3] *= fx * fy
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


Canvas.finish = _finish


# ---------------------------------------------------------------------------------------------------------------------
# Animations (timing, pose and frame counts are unchanged from v1)
# ---------------------------------------------------------------------------------------------------------------------
def anim_idle(n=8):
    out = []
    for i in range(n):
        t = i / n
        a = 2 * math.pi * t
        out.append(default_pose(
            t=t, bob=3.2 * math.sin(a), sway=1.8 * math.sin(a + 0.8), lean=1.0 * math.sin(a),
            r_el=(40 + 2 * math.sin(a), 118), r_wr=(62 + 5 * math.cos(a), 92 + 7 * math.sin(a)), r_dir=-0.35 + 0.16 * math.sin(a),
            l_el=(-34, 124 + 2 * math.sin(a)), l_wr=(-46 + 2 * math.sin(a), 150 + 3 * math.sin(a + 1)),
            glow=0.92 + 0.1 * math.sin(a), eye=0.85 + 0.15 * math.sin(a * 2)))
    return out


def anim_walk(n=6):
    out = []
    for i in range(n):
        t = i / n
        a = 2 * math.pi * t
        out.append(default_pose(
            t=t, bob=4.2 * math.sin(a * 2), sway=-5 + 2.5 * math.sin(a), lean=6 + 1.5 * math.sin(a), flare=0.12,
            r_el=(44, 112 + 3 * math.sin(a)), r_wr=(70 + 3 * math.cos(a), 84 + 6 * math.sin(a)), r_dir=-0.45 + 0.14 * math.sin(a),
            l_el=(-36, 118), l_wr=(-54 + 4 * math.sin(a), 142), l_dir=1.7,
            glow=1.0, eye=0.95))
    return out


def anim_attack(n=8):
    """Toll strike: the conducting arm sweeps up, then down through the strike with a flare; settles back."""
    keys = [
        ((60, 80), (42, 108), -0.9, 0.05, 0.0, -2, 0),
        ((56, 76), (40, 100), -1.2, 0.12, 0.0, -4, -1),
        ((62, 66), (46, 96), -1.35, 0.2, 0.0, -5, -2),
        ((82, 112), (58, 98), 0.2, 0.5, 1.0, 6, 2),
        ((90, 136), (62, 112), 0.55, 0.62, 0.8, 8, 3),
        ((82, 126), (58, 112), 0.4, 0.38, 0.4, 5, 1),
        ((72, 108), (50, 112), 0.0, 0.2, 0.1, 2, 0),
        ((64, 94), (42, 116), -0.3, 0.08, 0.0, 0, 0),
    ]
    out = []
    for i in range(n):
        wr, el, d, fl, ts, ln, bb = keys[i]
        out.append(default_pose(t=i / n, bob=bb, lean=ln, flare=fl, tollspark=ts, r_wr=wr, r_el=el, r_dir=d, r_spread=0.26,
                                l_el=(-30, 112 - 6 * fl * 4), l_wr=(-40, 130 - 18 * fl * 2), l_dir=1.5, glow=1.0 + 0.5 * fl, eye=1.0))
    return out


def anim_hurt(n=2):
    out = []
    for i in range(n):
        k = 1.0 if i == 0 else 0.6
        out.append(default_pose(t=i / n, recoil=-7 * k, bob=-3 * k, flare=0.28 * k, glow=1.3, eye=1.0,
                                r_el=(34, 112), r_wr=(46, 82), r_dir=-0.9, r_spread=0.34, l_el=(-40, 112), l_wr=(-62, 120), l_dir=2.4, l_spread=0.3))
    return out


def anim_defeat(n=8):
    out = []
    for i in range(n):
        p = i / (n - 1)
        out.append(default_pose(t=p * 0.6, brk=p ** 1.2, bob=-6 * p + 4 * math.sin(p * 6), flare=0.3 * (1 - p), glow=1.2 * (1 - 0.5 * p), eye=1.0 - 0.9 * p,
                                recoil=-8 * min(1, p * 2), alpha=1.0 - 0.1 * p,
                                r_el=(30, 118 + 20 * p), r_wr=(40, 96 + 40 * p), r_dir=0.8 * p - 0.3, r_spread=0.3,
                                l_el=(-38, 124), l_wr=(-60, 144 + 20 * p), l_dir=2.2, l_spread=0.3))
    return out


ANIMS = [("idle", anim_idle, 8.0, True), ("walk", anim_walk, 9.0, True), ("attack1", anim_attack, 20.0, False),
         ("hurt", anim_hurt, 14.0, False), ("defeat", anim_defeat, 9.0, False)]


def build(p2, outdir, only=None):
    os.makedirs(os.path.join(outdir, "frames"), exist_ok=True)
    w, h = (FW2 if p2 else FW1), FH
    manifest = {"character": "hollow_cantor" + ("_phase2" if p2 else ""), "canvas": [w, h], "ground_row": h, "pad": 0,
                "ref_anim": "idle", "animations": {}}
    sheets = []
    for name, fn, fps, loop in ANIMS:
        if only and name not in only:
            continue
        poses = fn()
        files = []
        row = []
        for i, pose in enumerate(poses):
            im = render(pose, p2)
            fname = f"{name}_{i:02d}.png"
            im.save(os.path.join(outdir, "frames", fname), optimize=True)
            files.append(fname)
            row.append(im)
            print("  ", name, i, flush=True)
        manifest["animations"][name] = {"background": "none", "flagged": False, "fps": fps, "loop": loop, "frames_out": files,
                                        "frames": [{"file": f, "w": w, "h": h, "bottom": h} for f in files],
                                        "ground": "frame", "scale_like": None, "source": "tools/gen_hollow_cantor.py", "warnings": []}
        sheets.append((name, row))
    if not only:
        with open(os.path.join(outdir, "manifest.json"), "w") as f:
            json.dump(manifest, f, indent=1, sort_keys=True)
    return sheets


def contact(sheets, path, bg=(30, 18, 64)):
    w = max(im.width for _, row in sheets for im in row)
    h = max(im.height for _, row in sheets for im in row)
    cols = max(len(row) for _, row in sheets)
    sheet = Image.new("RGBA", (cols * (w + 6) + 6, len(sheets) * (h + 6) + 6), bg + (255,))
    for r, (_, row) in enumerate(sheets):
        for c, im in enumerate(row):
            sheet.alpha_composite(im, (6 + c * (w + 6) + (w - im.width) // 2, 6 + r * (h + 6)))
    sheet.convert("RGB").save(path)


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "both"
    out = sys.argv[2] if len(sys.argv) > 2 else OUT
    only = sys.argv[3].split(",") if len(sys.argv) > 3 else None
    if which in ("both", "p1"):
        s = build(False, out, only)
        contact(s, "/tmp/cantor_p1.png")
    if which in ("both", "p2"):
        s = build(True, os.path.join(out, "phase2"), only)
        contact(s, "/tmp/cantor_p2.png")
    print("done")
