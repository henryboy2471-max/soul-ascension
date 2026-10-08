#!/usr/bin/env python3
"""Procedural sprite renderer for the Hollow Cantor (Episode 2 boss).

Original art authored in code (no external art service, no reused sheet): a tall, thin spectral conductor in pale violet /
rain-white robes over a dark inner body, floating segmented robes instead of legs, a bell-shaped halo behind a masked face,
long conductor's fingers and suspended bell fragments. Two forms of the SAME character are rendered:
  frames/        Phase 1: controlled, ritual
  frames_p2/     Phase 2 "THE CHORUS RISES": larger halo, more shards and rings, brighter glow, robes and energy flaring outward
Frames are authored 4x supersampled and reduced, feet (robe hem) on the bottom edge, figure centred horizontally, facing RIGHT
(the Fighter node flips the sprite for facing left), like every other sprite set in the project.

Usage: python3 tools/gen_hollow_cantor.py          (writes PNGs + manifest.json for both forms, contact sheets in /tmp)
Then:  godot --headless --editor --import --quit
       godot --headless --path . --script res://tools/build_spriteframes.gd -- res://assets/enemies/hollow_cantor
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 4                       # supersampling
H = 260                     # art height (px) the figure is drawn in
TOP_PAD = 32                # transparent rows added above the art so no frame can touch the top edge
CH = H + TOP_PAD            # canvas height (px); the wave data scales it so the figure keeps its intended in-game size
W1, W2 = 360, 400           # canvas width, Phase 1 / Phase 2 (the flare is wider)
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "enemies", "hollow_cantor")

# palette
ROBE_HI = (240, 236, 255)
ROBE_MID = (205, 190, 255)
ROBE_LO = (122, 92, 205)
DARK = (14, 8, 34)
DARK2 = (38, 22, 78)
GLOW = (190, 160, 255)
EYE = (160, 240, 255)
BELL = (236, 226, 255)
SEAM = (250, 246, 255)
OUTLINE = (52, 30, 112)


def lerp(a, b, t):
    return a + (b - a) * t


def lerpc(a, b, t):
    return tuple(int(lerp(a[i], b[i], t)) for i in range(3))


class OffsetDraw:
    """ImageDraw proxy that shifts art coordinates down by the top padding."""
    def __init__(self, d, oy):
        self.d, self.oy = d, oy

    def _fix(self, c):
        if isinstance(c[0], (tuple, list)):
            return [(x, y + self.oy) for x, y in c]
        return [v + (self.oy if i % 2 else 0) for i, v in enumerate(c)]

    def ellipse(self, box, **kw):
        self.d.ellipse(self._fix(box), **kw)

    def polygon(self, pts, **kw):
        self.d.polygon(self._fix(pts), **kw)

    def line(self, pts, **kw):
        self.d.line(self._fix(pts), **kw)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h + TOP_PAD
        self.img = Image.new("RGBA", (w * S, (h + TOP_PAD) * S), (0, 0, 0, 0))

    def pt(self, p):
        return (p[0] * S, (p[1] + TOP_PAD) * S)

    def alpha_over(self, layer):
        self.img.alpha_composite(layer)

    def layer(self):
        return Image.new("RGBA", self.img.size, (0, 0, 0, 0))

    def poly(self, pts, fill, alpha=1.0, grad=None):
        """Filled polygon; fill=(r,g,b). grad=(c_top, c_bottom) blends vertically across the polygon's bounds."""
        m = Image.new("L", self.img.size, 0)
        ImageDraw.Draw(m).polygon([self.pt(p) for p in pts], fill=int(255 * alpha))
        if grad is None:
            col = Image.new("RGBA", self.img.size, fill + (255,))
        else:
            ys = [(p[1] + TOP_PAD) * S for p in pts]
            y0, y1 = min(ys), max(ys)
            t = np.clip((np.arange(self.img.size[1])[:, None] - y0) / max(1.0, (y1 - y0)), 0, 1)
            arr = np.zeros((self.img.size[1], self.img.size[0], 4), np.uint8)
            for k in range(3):
                arr[:, :, k] = (grad[0][k] + (grad[1][k] - grad[0][k]) * t).astype(np.uint8)
            arr[:, :, 3] = 255
            col = Image.fromarray(arr, "RGBA")
        col.putalpha(ImageChops.multiply(col.getchannel("A"), m))
        self.alpha_over(col)

    def line(self, pts, color, width, alpha=1.0):
        l = self.layer()
        d = ImageDraw.Draw(l)
        c = color + (int(255 * alpha),)
        P = [self.pt(p) for p in pts]
        d.line(P, fill=c, width=max(1, int(width * S)), joint="curve")
        r = width * S / 2.0
        for p in (P[0], P[-1]):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=c)
        self.alpha_over(l)

    def circle(self, c, r, color, alpha=1.0, outline=None, width=1.0):
        l = self.layer()
        d = ImageDraw.Draw(l)
        x, y = self.pt(c)
        rr = r * S
        if outline is None:
            d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=color + (int(255 * alpha),))
        else:
            d.ellipse([x - rr, y - rr, x + rr, y + rr], outline=color + (int(255 * alpha),), width=max(1, int(width * S)))
        self.alpha_over(l)

    def arc(self, c, r, a0, a1, color, width, alpha=1.0, squash=1.0):
        l = self.layer()
        d = ImageDraw.Draw(l)
        x, y = self.pt(c)
        rr = r * S
        d.arc([x - rr, y - rr * squash, x + rr, y + rr * squash], a0, a1, fill=color + (int(255 * alpha),), width=max(1, int(width * S)))
        self.alpha_over(l)

    def glow(self, draw_fn, blur, color, strength=1.0):
        """draw_fn(ImageDraw, scale) draws white shapes on a mask; the blurred mask is added as coloured light."""
        m = Image.new("L", self.img.size, 0)
        draw_fn(OffsetDraw(ImageDraw.Draw(m), TOP_PAD * S), S)
        m = m.filter(ImageFilter.GaussianBlur(blur * S))
        m = m.point(lambda v: min(255, int(v * strength)))
        col = Image.new("RGBA", self.img.size, color + (255,))
        col.putalpha(m)
        self.alpha_over(col)

    def finish(self, w, h, alpha_mul=1.0):
        out = self.img.resize((w, h + TOP_PAD), Image.LANCZOS)
        # safety band: light that would reach the canvas border fades out over 5 px (3 px at the bottom, where the hem hovers)
        arr = np.array(out).astype(np.float32)
        hh, ww = arr.shape[:2]
        yy = np.arange(hh)[:, None]
        xx = np.arange(ww)[None, :]
        fx = np.clip(np.minimum(xx, ww - 1 - xx) / 5.0, 0, 1)
        fy = np.clip(np.minimum(yy / 5.0, (hh - 1 - yy) / 3.0), 0, 1)
        arr[:, :, 3] *= fx * fy
        out = Image.fromarray(arr.astype(np.uint8), "RGBA")
        if alpha_mul < 1.0:
            a = out.getchannel("A").point(lambda v: int(v * alpha_mul))
            out.putalpha(a)
        return out


def tapered(points, widths):
    """Polygon around a centreline with per-point widths (smooth limb / sleeve / ribbon)."""
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


def bell_outline(cx, top, height, width, n=20):
    """Silhouette of a bell: round dome, narrow shoulders, flared lip. Returns a closed list of points."""
    pts = []
    for i in range(n + 1):
        t = i / n
        y = top + height * t
        # half width profile: dome -> waist -> flare
        if t < 0.35:
            hw = width * 0.5 * math.sin(t / 0.35 * math.pi / 2) ** 0.7 * 0.72
        else:
            u = (t - 0.35) / 0.65
            hw = width * 0.5 * (0.72 + 0.28 * u ** 2.2)
        pts.append((cx + hw, y))
    left = [(2 * cx - p[0], p[1]) for p in pts[::-1]]
    return pts + left


def draw_bell_glyph(cv, c, size, color, alpha, glow_strength=0.0, ring=False):
    cx, cy = c
    pts = bell_outline(cx, cy - size * 0.5, size, size * 0.9, 12)
    cv.poly(pts, color, alpha)
    cv.circle((cx, cy + size * 0.5 + size * 0.12), size * 0.11, color, alpha)


def fingers(cv, wrist, direction, spread, length, color, alpha=1.0, curl=0.0, width=1.3):
    """Five long conductor's fingers fanning out from the wrist along `direction` (radians)."""
    for k in range(5):
        a = direction + (k - 2) * spread
        l = length * (0.78 if k in (0, 4) else 1.0) * (1.0 if k != 2 else 1.08)
        p0 = wrist
        p1 = (p0[0] + math.cos(a) * l * 0.5, p0[1] + math.sin(a) * l * 0.5)
        a2 = a + curl * (1 if k < 2 else -0.4)
        p2 = (p1[0] + math.cos(a2) * l * 0.38, p1[1] + math.sin(a2) * l * 0.38)
        p3 = (p2[0] + math.cos(a2 + curl) * l * 0.18, p2[1] + math.sin(a2 + curl) * l * 0.18)
        cv.line([p0, p1, p2, p3], color, width, alpha)
        cv.circle(p3, width * 0.55, SEAM, alpha * 0.9)


class Pose(dict):
    def __getattr__(self, k):
        return self.get(k)


def default_pose(**kw):
    p = Pose(
        bob=0.0, sway=0.0, lean=0.0, t=0.0, flare=0.0, glow=1.0, eye=1.0, alpha=1.0, brk=0.0, recoil=0.0, tollspark=0.0,
        # right (front) arm points: shoulder offset is fixed; elbow and wrist are absolute canvas offsets from centre-x
        r_el=(40, 120), r_wr=(62, 92), r_dir=-0.35, r_spread=0.20, r_curl=0.35,
        l_el=(-34, 124), l_wr=(-48, 150), l_dir=1.9, l_spread=0.16, l_curl=0.25,
        hem=0.0, frags=0.0,
    )
    p.update(kw)
    return p


def render(pose, p2=False):
    W = W2 if p2 else W1
    cv = Canvas(W, H)
    cx = W / 2.0
    t = pose.t
    bob = pose.bob
    lean = pose.lean + pose.recoil
    sway = pose.sway
    brk = pose.brk              # 0..1 defeat progress (robes unravel, halo cracks, shards scatter)
    fl = pose.flare + (0.55 if p2 else 0.0)
    gl = pose.glow * (1.25 if p2 else 1.0)
    base = H - 17 + bob * 0.3           # robe hem hovers above the ground line
    sh_y = 90 + bob                     # shoulder line
    head_c = (cx + 9 + lean * 0.5, 50 + bob)

    # ------------------------------------------------------------------ back glow / aura (behind everything)
    def aura(d, s):
        d.ellipse([(cx - 52 - 14 * fl) * s, (40 + bob) * s, (cx + 58 + 14 * fl) * s, (base + 4) * s], fill=int(120 * gl))
    cv.glow(aura, 14, (120, 80, 230), 0.55 * (1 - brk * 0.8))

    if p2:
        # outer energy ribbons streaming out behind the shoulders and hem (robes and energy flaring outward)
        for k in range(5):
            ph = t * 2 * math.pi + k * 1.3
            side = -1 if k % 2 == 0 else 1
            y0 = 98 + k * 20 + bob
            pts = []
            for i in range(9):
                u = i / 8
                pts.append((cx + side * (16 + 70 * u * (0.7 + 0.3 * math.sin(ph))) - 8 * u, y0 + 28 * u * (k % 3 - 1) + 6 * math.sin(ph + u * 4)))
            cv.poly(tapered(pts, [7 - 5 * (i / 8) for i in range(9)]), GLOW, 0.34 * (1 - brk))
            cv.line(pts, SEAM, 1.0, 0.45 * (1 - brk))

    # ------------------------------------------------------------------ bell halo behind the head (silhouette bell, glowing rim)
    crown = 1.0 + (0.28 if p2 else 0.0) + 0.05 * math.sin(t * 2 * math.pi) + pose.tollspark * 0.12
    crown_alpha = (1.0 - 0.85 * brk)
    bell_h, bell_w = 86 * crown, 58 * crown
    bpts = bell_outline(head_c[0] + 2, head_c[1] - 30 * crown, bell_h, bell_w, 24)
    if brk > 0:
        # the halo cracks apart: the two halves drift sideways
        bpts = [(x + (14 * brk if x > head_c[0] else -14 * brk), y + 6 * brk) for x, y in bpts]
    cv.glow(lambda d, s: d.polygon([(x * s, y * s) for x, y in bpts], outline=255, width=int(5 * s)), 3.5, GLOW, 1.2 * gl * crown_alpha)
    cv.poly(bpts, ROBE_MID, 0.16 * crown_alpha)
    ring = [(x, y) for x, y in bpts]
    cv.line(ring + [ring[0]], SEAM, 1.7, 0.95 * crown_alpha)
    cv.line([(x, y + 3.5) for x, y in ring[2:-2]], GLOW, 1.0, 0.55 * crown_alpha)
    # clapper hanging inside the bell
    cv.line([(head_c[0] + 2, head_c[1] + bell_h * 0.46), (head_c[0] + 2, head_c[1] + bell_h * 0.46 + 10)], SEAM, 1.3, 0.8 * crown_alpha)
    cv.circle((head_c[0] + 2, head_c[1] + bell_h * 0.46 + 12), 3.2, SEAM, 0.9 * crown_alpha)

    # ------------------------------------------------------------------ rear robe train: translucent floating plates
    n_plate = 5
    top_y = 148 + bob
    hem_y = base
    for i in range(n_plate):
        u0, u1 = i / n_plate, (i + 1) / n_plate
        y0 = top_y + (hem_y - top_y) * u0 + 1.6
        y1 = top_y + (hem_y - top_y) * u1 - 4.2
        # long hanging panels that widen to the hem like an inverted bell; plates drift apart when the body breaks up
        w0 = 13 + 46 * (u0 ** 1.5) + 22 * fl * u0 + (3 if i % 2 else 0)
        w1 = 13 + 46 * (u1 ** 1.5) + 22 * fl * u1 + (3 if i % 2 else 0)
        ph = t * 2 * math.pi - i * 0.55
        dx = sway * (0.5 + u0) + 2.6 * math.sin(ph) * (0.4 + u0) - 4 * u0 * lean * 0.3
        dy = brk * (10 + 14 * i) * (1 if i % 2 == 0 else 0.6)
        dxb = brk * (i - 2.0) * 10
        dy = min(dy, (H - 7) - (y1 + (11.0 if i < n_plate - 1 else 14.0)))   # collapsing plates settle above the bottom edge
        a = (1 - brk) * pose.alpha
        c0 = cx + dx + dxb - 3 * u0 + (2.2 if i % 2 else -1.6)
        c1 = cx + dx * 1.1 + dxb - 3 * u1 + (2.2 if i % 2 else -1.6)
        tip = 11.0 if i < n_plate - 1 else 14.0
        shape = [(c0 - w0 / 2, y0 + dy), (c0 + w0 / 2, y0 + dy), (c1 + w1 / 2, y1 + dy), (c1, y1 + tip + dy), (c1 - w1 / 2, y1 + dy)]
        inner = [(c0 - w0 * 0.30, y0 + dy), (c0 + w0 * 0.30, y0 + dy), (c1 + w1 * 0.24, y1 + dy), (c1, y1 + tip * 0.7 + dy), (c1 - w1 * 0.24, y1 + dy)]
        cv.poly(inner, DARK, 0.94 * a)                                                  # dark inner body under the robe
        cv.poly(shape, ROBE_MID, 0.74 * a, grad=(ROBE_HI, ROBE_LO))
        cv.poly([shape[0], (shape[0][0] + w0 * 0.38, shape[0][1]), (c1 - w1 * 0.1, y1 + tip * 0.8 + dy), shape[3], shape[4]], DARK2, 0.38 * a)   # shaded side
        cv.line(shape + [shape[0]], OUTLINE, 0.9, 0.75 * a)
        cv.line([shape[0], shape[1]], SEAM, 1.2, 0.95 * a)
        cv.line([shape[1], shape[2], shape[3]], ROBE_HI, 0.9, 0.55 * a)
        # fold lines
        cv.line([(c0 - w0 * 0.12, y0 + 3 + dy), (c1 - w1 * 0.16, y1 + dy)], ROBE_LO, 0.8, 0.5 * a)
        cv.line([(c0 + w0 * 0.2, y0 + 3 + dy), (c1 + w1 * 0.22, y1 + dy)], ROBE_LO, 0.8, 0.4 * a)
        if i < n_plate - 1:
            cv.line([(c1 - w1 * 0.16, y1 + tip * 0.5 + dy + 1.5), (c1 + w1 * 0.16, y1 + tip * 0.5 + dy + 1.5)], GLOW, 1.1, 0.55 * a)
        # hanging bell tassel on alternate plates
        if i % 2 == 1:
            tx, ty = c1 + w1 * 0.30, y1 + dy - 2
            cv.line([(tx, ty), (tx, ty + 7)], SEAM, 0.9, 0.9 * a)
            draw_bell_glyph(cv, (tx, ty + 11), 6.5, BELL, 0.95 * a)

    # ------------------------------------------------------------------ torso (long thin vestment), mantle and high collar
    a_t = (1 - brk * 0.9) * pose.alpha
    sx = cx + lean * 0.6
    torso = [(sx - 12, sh_y), (sx + 14, sh_y - 1), (sx + 8, top_y + 4), (sx - 7, top_y + 4)]
    cv.poly(torso, DARK, 0.96 * a_t)
    cv.poly([(sx - 10, sh_y + 2), (sx + 12, sh_y + 1), (sx + 7, top_y + 2), (sx - 5, top_y + 2)], ROBE_MID, 0.72 * a_t, grad=(ROBE_HI, ROBE_LO))
    cv.line([(sx + 2, sh_y + 6), (sx + 1, top_y)], SEAM, 1.1, 0.85 * a_t)
    # sash with a bell sigil
    cv.poly([(sx - 9, sh_y + 36), (sx + 11, sh_y + 35), (sx + 10, sh_y + 43), (sx - 8, sh_y + 44)], ROBE_LO, 0.95 * a_t)
    cv.line([(sx - 9, sh_y + 36), (sx + 11, sh_y + 35)], SEAM, 1.0, 0.9 * a_t)
    draw_bell_glyph(cv, (sx + 1, sh_y + 24), 11, BELL, 0.9 * a_t)
    cv.glow(lambda d, s: d.ellipse([(sx - 7) * s, (sh_y + 17) * s, (sx + 9) * s, (sh_y + 34) * s], fill=255), 3.5, GLOW, 0.9 * gl * a_t)
    # layered mantle across the shoulders (asymmetric: tall on the hero-facing side)
    mantle = [(sx - 21, sh_y + 2), (sx - 14, sh_y - 9), (sx + 8, sh_y - 13), (sx + 25, sh_y - 4), (sx + 21, sh_y + 7), (sx + 6, sh_y + 12), (sx - 11, sh_y + 12)]
    cv.poly(mantle, ROBE_MID, 0.85 * a_t, grad=(ROBE_HI, ROBE_LO))
    cv.line(mantle[:5], SEAM, 1.3, 0.95 * a_t)
    cv.poly([(sx - 18, sh_y + 8), (sx + 21, sh_y + 6), (sx + 17, sh_y + 17), (sx - 12, sh_y + 17)], ROBE_LO, 0.78 * a_t)
    cv.line([(sx - 18, sh_y + 8), (sx + 21, sh_y + 6)], GLOW, 1.0, 0.7 * a_t)
    # tall collar rising behind the head
    cv.poly([(sx - 6, sh_y - 8), (sx - 12, sh_y - 34), (sx + 2, sh_y - 22), (sx + 16, sh_y - 31), (sx + 14, sh_y - 6)], ROBE_LO, 0.9 * a_t, grad=(ROBE_MID, DARK2))
    cv.line([(sx - 12, sh_y - 34), (sx + 2, sh_y - 22), (sx + 16, sh_y - 31)], SEAM, 1.1, 0.9 * a_t)

    # ------------------------------------------------------------------ head: long veiled mask, one glowing slit
    hx, hy = head_c
    a_h = (1 - brk * 0.9) * pose.alpha
    cv.poly([(hx - 10, hy - 6), (hx - 3, hy - 22), (hx + 11, hy - 17), (hx + 12, hy + 4), (hx + 4, hy + 24), (hx - 2, hy + 27), (hx - 8, hy + 9)], DARK2, a_h)   # hood interior
    mask = [(hx - 6, hy - 14), (hx + 3, hy - 20), (hx + 11, hy - 14), (hx + 12, hy + 2), (hx + 7, hy + 18), (hx + 2, hy + 24), (hx - 3, hy + 12), (hx - 7, hy - 2)]
    cv.poly(mask, ROBE_HI, 0.97 * a_h, grad=(SEAM, ROBE_MID))
    cv.line(mask + [mask[0]], ROBE_LO, 0.9, 0.7 * a_h)
    # veil drapes from the mask
    cv.poly([(hx - 7, hy - 10), (hx - 15 - lean * 0.3, hy + 14), (hx - 11, hy + 40), (hx - 2, hy + 24)], ROBE_MID, 0.5 * a_h, grad=(ROBE_HI, ROBE_LO))
    # single glowing slit eye + faint brow mark
    ex, ey = hx + 6.5, hy - 2
    eye_a = min(1.0, pose.eye) * a_h
    cv.glow(lambda d, s: d.line([(ex * s, (ey - 5) * s), ((ex + 0.5) * s, (ey + 6) * s)], fill=255, width=int(3 * s)), 3.0 + (1.5 if p2 else 0), EYE, 1.4 * eye_a * gl)
    cv.line([(ex, ey - 5), (ex + 0.4, ey + 6)], (235, 252, 255), 1.5, eye_a)
    cv.line([(hx + 2, hy - 8), (hx + 10, hy - 9)], ROBE_LO, 0.8, 0.7 * a_h)
    if p2:
        # trailing light from the eye in Phase 2
        cv.line([(ex, ey), (ex - 18, ey - 7)], EYE, 1.0, 0.6 * a_h)
        cv.line([(ex, ey + 3), (ex - 14, ey + 2)], EYE, 0.8, 0.4 * a_h)

    # ------------------------------------------------------------------ arms: long sleeves ending in bell cuffs and conductor's fingers
    def arm(sx0, sy0, el, wr, direction, spread, curl, front, mirror=1.0):
        a = (1 - brk) * pose.alpha
        S0 = (sx0, sy0)
        E = (cx + el[0] + lean * 0.4, el[1] + bob)
        Wr = (cx + wr[0] + lean * 0.4, wr[1] + bob)
        E = (S0[0] + (E[0] - S0[0]) * 1.12, S0[1] + (E[1] - S0[1]) * 1.12)
        Wr = (E[0] + (Wr[0] - E[0]) * 1.2, E[1] + (Wr[1] - E[1]) * 1.2)
        # drape of the upper sleeve
        pts = [S0, ((S0[0] + E[0]) / 2, (S0[1] + E[1]) / 2 + 3), E, ((E[0] + Wr[0]) / 2, (E[1] + Wr[1]) / 2 + 2), Wr]
        cv.poly(tapered(pts, [7.5, 8, 6.5, 5.5, 5]), ROBE_MID, 0.82 * a, grad=(ROBE_HI, ROBE_LO))
        cv.line(pts, SEAM, 0.9, 0.75 * a)
        # wide bell cuff at the wrist, pointing along the forearm
        fa = math.atan2(Wr[1] - E[1], Wr[0] - E[0])
        n = (-math.sin(fa), math.cos(fa))
        f = (math.cos(fa), math.sin(fa))
        cw = 11 + (4 if p2 else 0)
        cuff = [(Wr[0] - f[0] * 10 + n[0] * 4.5, Wr[1] - f[1] * 10 + n[1] * 4.5), (Wr[0] + f[0] * 2 + n[0] * cw * 0.5, Wr[1] + f[1] * 2 + n[1] * cw * 0.5),
                (Wr[0] + f[0] * 2 - n[0] * cw * 0.5, Wr[1] + f[1] * 2 - n[1] * cw * 0.5), (Wr[0] - f[0] * 10 - n[0] * 4.5, Wr[1] - f[1] * 10 - n[1] * 4.5)]
        cv.poly(cuff, ROBE_HI, 0.88 * a, grad=(SEAM, ROBE_LO))
        cv.line([cuff[1], cuff[2]], SEAM, 1.2, 0.95 * a)
        cv.line([cuff[1], cuff[2]], GLOW, 0.8, 0.0 * a)
        hand = (Wr[0] + f[0] * 4, Wr[1] + f[1] * 4)
        fingers(cv, hand, direction, spread, 24 + (4 if p2 else 0), ROBE_HI, 0.95 * a, curl, 1.5)
        return hand

    # back (away) arm first, then front arm over the body
    arm(sx - 17, sh_y + 4, pose.l_el, pose.l_wr, pose.l_dir, pose.l_spread, pose.l_curl, False)
    hand_r = arm(sx + 17, sh_y + 2, pose.r_el, pose.r_wr, pose.r_dir, pose.r_spread, pose.r_curl, True)

    # invisible choir: faint resonance threads from the conducting fingertips
    if brk < 0.6:
        for k in range(3 + (2 if p2 else 0)):
            ph = t * 2 * math.pi + k
            a0 = pose.r_dir + (k - 1) * 0.28
            pts = []
            for i in range(8):
                u = i / 7
                r = 6 + 36 * u
                pts.append((hand_r[0] + math.cos(a0 + 0.35 * math.sin(ph + u * 3)) * r, max(6.0, hand_r[1] + math.sin(a0 + 0.35 * math.sin(ph + u * 3)) * r)))
            cv.line(pts, GLOW, 0.9, (0.55 - 0.1 * k) * (1 - brk))
    if pose.tollspark > 0:
        # strike: a flare of resonance at the conducting hand
        k = pose.tollspark
        cv.glow(lambda d, s: d.ellipse([(hand_r[0] - 14 * k) * s, (hand_r[1] - 14 * k) * s, (hand_r[0] + 14 * k) * s, (hand_r[1] + 14 * k) * s], fill=255), 5, SEAM, 1.4)
        for r_ in (10, 20, 30):
            cv.arc(hand_r, r_ * k, 0, 360, SEAM, 1.4, 0.9 * (1 - r_ / 40))

    # ------------------------------------------------------------------ suspended bell fragments / resonance shards
    nfrag = 12 if p2 else 7
    rng = np.random.RandomState(7)
    for k in range(nfrag):
        ang0 = rng.uniform(0, 2 * math.pi)
        rad = rng.uniform(44, 74) + (14 if p2 else 0)
        yc = rng.uniform(70, 215)
        ph = t * 2 * math.pi * (1 if k % 2 == 0 else -1) + ang0
        fx = cx + math.cos(ph) * rad * 0.62 + (6 if k % 3 == 0 else -4)
        fy = yc + 6 * math.sin(ph * 1.7) + bob * 0.7
        scatter = brk * (20 + 60 * (k / nfrag))
        fx += math.cos(ang0) * scatter
        fy += math.sin(ang0) * scatter * 0.7 - brk * 30
        fa = (1 - brk * 0.55) * pose.alpha
        sz = rng.uniform(5, 9)
        # in front of or behind the body depending on orbit side
        if k % 3 == 0:
            draw_bell_glyph(cv, (fx, fy), sz, BELL, 0.95 * fa)
            cv.glow(lambda d, s, fx=fx, fy=fy, sz=sz: d.ellipse([(fx - sz * 0.7) * s, (fy - sz * 0.7) * s, (fx + sz * 0.7) * s, (fy + sz * 0.7) * s], fill=255), 2.4, GLOW, 0.8 * gl * fa)
        elif k % 3 == 1:
            tri = [(fx, fy - sz), (fx + sz * 0.55, fy + sz * 0.7), (fx - sz * 0.55, fy + sz * 0.4)]
            cv.poly(tri, ROBE_HI, 0.92 * fa, grad=(SEAM, ROBE_LO))
            cv.line(tri + [tri[0]], SEAM, 0.7, 0.9 * fa)
        else:
            cv.circle((fx, fy), sz * 0.75, GLOW, 0.9 * fa, outline=True, width=0.9)
            cv.circle((fx, fy), sz * 0.22, SEAM, fa)

    if p2:
        # extra resonance rings behind the figure
        for k in range(3):
            ph = (t + k / 3.0) % 1.0
            cv.arc((cx + 4, 130 + bob), 40 + 56 * ph, 0, 360, GLOW, 1.2, 0.42 * (1 - ph) * (1 - brk))

    return cv.finish(W, H)


# ---------------------------------------------------------------------------------------------------------------------
# Animations
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
            t=t, bob=4.2 * math.sin(a * 2) , sway=-5 + 2.5 * math.sin(a), lean=6 + 1.5 * math.sin(a), flare=0.12,
            r_el=(44, 112 + 3 * math.sin(a)), r_wr=(70 + 3 * math.cos(a), 84 + 6 * math.sin(a)), r_dir=-0.45 + 0.14 * math.sin(a),
            l_el=(-36, 118), l_wr=(-54 + 4 * math.sin(a), 142), l_dir=1.7,
            glow=1.0, eye=0.95))
    return out


def anim_attack(n=8):
    """Toll strike: the conducting arm sweeps up, then down through the strike with a flare; settles back."""
    keys = [
        # r_wr, r_el, r_dir, flare, tollspark, lean, bob
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


def build(p2, outdir):
    os.makedirs(os.path.join(outdir, "frames"), exist_ok=True)
    manifest = {"character": "hollow_cantor" + ("_phase2" if p2 else ""), "canvas": [W2 if p2 else W1, CH], "ground_row": CH, "pad": 0,
                "ref_anim": "idle", "animations": {}}
    sheets = []
    for name, fn, fps, loop in ANIMS:
        poses = fn()
        files = []
        row = []
        for i, pose in enumerate(poses):
            im = render(pose, p2)
            fname = f"{name}_{i:02d}.png"
            im.save(os.path.join(outdir, "frames", fname))
            files.append(fname)
            row.append(im)
        manifest["animations"][name] = {"background": "none", "flagged": False, "fps": fps, "loop": loop, "frames_out": files,
                                        "frames": [{"file": f, "w": W2 if p2 else W1, "h": CH, "bottom": CH} for f in files],
                                        "ground": "frame", "scale_like": None, "source": "tools/gen_hollow_cantor.py", "warnings": []}
        sheets.append((name, row))
    with open(os.path.join(outdir, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
    return sheets


def contact(sheets, path, bg=(30, 18, 64)):
    w = max(im.width for _, row in sheets for im in row)
    cols = max(len(row) for _, row in sheets)
    sheet = Image.new("RGBA", (cols * (w + 6) + 6, len(sheets) * (CH + 6) + 6), bg + (255,))
    for r, (_, row) in enumerate(sheets):
        for c, im in enumerate(row):
            sheet.alpha_composite(im, (6 + c * (w + 6) + (w - im.width) // 2, 6 + r * (CH + 6)))
    sheet.convert("RGB").save(path)


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "both"
    if which in ("both", "p1"):
        s = build(False, OUT)
        contact(s, "/tmp/cantor_p1.png")
    if which in ("both", "p2"):
        s = build(True, os.path.join(OUT, "phase2"))
        contact(s, "/tmp/cantor_p2.png")
    print("done")
