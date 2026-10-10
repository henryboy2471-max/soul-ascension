#!/usr/bin/env python3
"""Procedural 4-direction anime character renderer for the SOUL ASCENSION 2.5D demo (PLACEHOLDER / PROPOSAL ART).

Original art drawn in code (no external assets, no paid services). Renders front / back / side (side is mirrored for the other direction)
walk strips (idle + 4 walk frames) and a high-resolution bust portrait for dialogue. All vector shapes are supersampled, so faces stay crisp
at any size. Run: python3 tools/art25d/chargen.py [out_dir] [name ...]
"""
import math, os, sys, random
from PIL import Image, ImageDraw, ImageChops, ImageFilter

W, H = 144, 288          # final sprite frame size (centred, feet near the bottom)
INK = (22, 14, 30, 255)
HEAD_K = 0.76   # head scale for ~6-head anime proportions


def hexc(s, a=255):
    s = s.lstrip('#')
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def mix(c, d, t):
    return tuple(int(c[i] + (d[i] - c[i]) * t) for i in range(3)) + (255,)


def shade_of(c, t=0.38):   # shadow: darker + slightly violet (cool, matches the neon scene)
    return mix(mix(c, (20, 10, 50), t), (0, 0, 0), 0.05)


def skin_shade(c, t=0.4):
    # warm, saturated shadow for dark skin tones (reads richer than a grey/violet shadow)
    return mix(mix(c, (70, 18, 24), t * 0.9), (10, 4, 20), t * 0.25)


def light_of(c, t=0.25):
    return mix(c, (255, 240, 220), t)


def smooth(pts, n=6, closed=True):
    """Catmull-Rom smoothing of a control polygon."""
    out = []
    m = len(pts)
    rng = range(m) if closed else range(m - 1)
    for i in rng:
        p0 = pts[(i - 1) % m] if (closed or i > 0) else pts[i]
        p1 = pts[i]
        p2 = pts[(i + 1) % m]
        p3 = pts[(i + 2) % m] if (closed or i + 2 < m) else pts[(i + 1) % m]
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            out.append((0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3),
                        0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)))
    return out


class Cv:
    """Supersampled canvas. Coordinates are in final-sprite pixels; zoom/origin allow portrait close-ups."""

    def __init__(self, w, h, ss, zoom=1.0, ox=0.0, oy=0.0):
        self.w, self.h, self.ss, self.zoom, self.ox, self.oy = w, h, ss, zoom, ox, oy
        self.img = Image.new('RGBA', (w * ss, h * ss), (0, 0, 0, 0))
        self.ow = max(2, int(round(1.15 * ss * zoom)))   # outline width in working px
        self.hk = 1.0
        self.hc = (0.0, 0.0)

    def P(self, p):
        if self.hk != 1.0:
            p = (self.hc[0] + (p[0] - self.hc[0]) * self.hk, self.hc[1] + (p[1] - self.hc[1]) * self.hk)
        return ((p[0] - self.ox) * self.zoom * self.ss, (p[1] - self.oy) * self.zoom * self.ss)

    def R(self, v):
        return v * self.zoom * self.ss * self.hk

    def mask(self):
        return Image.new('L', self.img.size, 0)

    def mpoly(self, m, pts):
        ImageDraw.Draw(m).polygon([self.P(p) for p in pts], fill=255)
        return m

    def mell(self, m, cx, cy, rx, ry):
        a = self.P((cx - rx, cy - ry))
        b = self.P((cx + rx, cy + ry))
        ImageDraw.Draw(m).ellipse([a, b], fill=255)
        return m

    def mlimb(self, m, p0, p1, w0, w1):
        d = ImageDraw.Draw(m)
        dx, dy = p1[0] - p0[0], p1[1] - p0[1]
        L = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / L, dx / L
        quad = [(p0[0] + nx * w0 / 2, p0[1] + ny * w0 / 2), (p1[0] + nx * w1 / 2, p1[1] + ny * w1 / 2),
                (p1[0] - nx * w1 / 2, p1[1] - ny * w1 / 2), (p0[0] - nx * w0 / 2, p0[1] - ny * w0 / 2)]
        d.polygon([self.P(p) for p in quad], fill=255)
        for (p, w) in ((p0, w0), (p1, w1)):
            a = self.P((p[0] - w / 2, p[1] - w / 2))
            b = self.P((p[0] + w / 2, p[1] + w / 2))
            d.ellipse([a, b], fill=255)
        return m

    def paint(self, m, base, shadow=None, rim=None, ink=True, k=3.0, rimk=1.6, hi=None):
        """Cel-shade a mask: outline, base, shadow crescent (light from upper left), optional cool rim light on the right edge."""
        ss = self.ss * self.zoom
        if ink:
            iw = max(1, int(round(0.55 * ss)))
            ol = m.filter(ImageFilter.MaxFilter(iw * 2 + 1))
            self.img.paste(mix(base, INK, 0.72), mask=ol)
        self.img.paste(base, mask=m)
        if shadow is None:
            shadow = shade_of(base)
        dk = int(max(1, k * ss))
        sh = ImageChops.subtract(m, ImageChops.offset(m, -dk, -int(dk * 0.8)))
        self.img.paste(shadow, mask=sh)
        if hi is not None:
            hk = int(max(1, 1.6 * ss))
            h2 = ImageChops.subtract(m, ImageChops.offset(m, hk, hk))
            self.img.paste(hi, mask=h2)
        if rim is not None:
            rk = int(max(1, rimk * ss))
            r = ImageChops.subtract(m, ImageChops.offset(m, -rk, 0))
            r = ImageChops.multiply(r, ImageChops.offset(m, -2, 0))
            self.img.paste(rim, mask=r)

    def line(self, pts, color, wpx, closed=False):
        pp = [self.P(p) for p in pts]
        d = ImageDraw.Draw(self.img)
        d.line(pp + ([pp[0]] if closed else []), fill=color, width=max(1, int(self.R(wpx))), joint='curve')
        r = self.R(wpx) / 2
        for p in (pp[0], pp[-1]):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=color)

    def fpoly(self, pts, color):
        ImageDraw.Draw(self.img).polygon([self.P(p) for p in pts], fill=color)

    def fell(self, cx, cy, rx, ry, color):
        a = self.P((cx - rx, cy - ry))
        b = self.P((cx + rx, cy + ry))
        ImageDraw.Draw(self.img).ellipse([a, b], fill=color)

    def clipped(self, m, draw_fn):
        """Run draw_fn(cv_layer) on a temp layer and composite only inside mask m (for patterns on parts)."""
        tmp = Cv(self.w, self.h, self.ss, self.zoom, self.ox, self.oy)
        tmp.hk, tmp.hc = self.hk, self.hc
        draw_fn(tmp)
        a = ImageChops.multiply(tmp.img.split()[3], m)
        tmp.img.putalpha(a)
        self.img.alpha_composite(tmp.img)

    def out(self):
        # thick dark silhouette line around the whole figure (premium cel look); inner part lines stay thin and tinted
        r = max(2, int(round(1.25 * self.ss * min(self.zoom, 2.4))))
        a = self.img.split()[3]
        edge = a.filter(ImageFilter.MaxFilter(r * 2 + 1))
        base = Image.new('RGBA', self.img.size, INK)
        base.putalpha(edge)
        base.alpha_composite(self.img)
        return base.resize((self.w, self.h), Image.LANCZOS)


SKIN = {
    'ebony': '3d261e', 'deep': '55372a', 'brown': '70482f', 'warm': '8a5a3c', 'bronze': '9c6a46', 'honey': 'b27d52',
}

# ---------------------------------------------------------------- character definitions (demo cast; Echo and Mira follow the approved designs)
CHARS = {
    'echo': dict(acc=['collar','earrings','seams','sole_glow','epaulets_off'], expr=0, skin='deep', hair='twists', hair_c='e9eaf4', hair_sh='9aa0c0', eye='e0a020', outfit='coat', top='15141f', coat_in='3b2f9e', trim='d9b45a',
                 pants='1a1824', boots='241f30', armor=True, gauntlet=True, brow=1.0, jaw=0.9, nose=0.9, lip=0.9, eyes=1.0, sw=1.0, h=1.0, glow='9a6bff'),
    'mira': dict(acc=['earrings','beads','bracers','seams','hair_pin'], expr=2, skin='brown', hair='curly_long', hair_c='2b1d33', hair_sh='1a1022', eye='9a5a26', outfit='jacket', top='2a2340', coat_in='8a4fd8', trim='f0c050',
                 pants='19151f', boots='2a2036', cape=True, band=True, brow=0.8, jaw=0.75, nose=0.8, lip=1.15, eyes=1.12, sw=0.82, h=0.95, glow='c27bff'),
    'kofi': dict(acc=['earrings','bracers','sole_glow'], expr=1, skin='ebony', hair='fade', hair_c='140f12', hair_sh='0a0709', eye='7a4a22', outfit='apron', top='7a2a2a', coat_in='e8e2d0', trim='f0a040',
                 pants='2b2b38', boots='3a2a22', beard=True, brow=1.25, jaw=1.15, nose=1.15, lip=1.0, eyes=0.9, sw=1.18, h=0.97, glow='ffb040'),
    'imani': dict(acc=['pouches','bracers','seams','earrings'], expr=2, skin='warm', hair='locs', hair_c='2a1810', hair_sh='140a06', eye='8a5a2a', outfit='overall', top='2f6f86', coat_in='e6c04a', trim='f6d86a',
                  pants='2f6f86', boots='3a3330', goggles=True, brow=0.9, jaw=0.95, nose=1.0, lip=1.1, eyes=1.05, sw=0.95, h=0.98, glow='4ad0ff'),
    'zuri': dict(acc=['headphones_neck','beads','sole_glow','freckles'], expr=1, skin='bronze', hair='puffs', hair_c='1a100c', hair_sh='0a0605', eye='8a5a2a', outfit='hoodie', top='d0508a', coat_in='f2f2fa', trim='5ae0f0',
                 pants='2a2a44', boots='f2f2fa', brow=0.8, jaw=0.7, nose=0.7, lip=1.0, eyes=1.25, sw=0.72, h=0.74, glow='ff7ac0'),
    'okoye': dict(acc=['lens','epaulets','seams','collar'], expr=0, skin='ebony', hair='bald', hair_c='140f12', hair_sh='0a0709', eye='5a4a3a', outfit='suit', top='2a3550', coat_in='c8c8d8', trim='9aa6c8',
                  pants='232a3e', boots='15161c', glasses=True, brow=1.3, jaw=1.25, nose=1.1, lip=0.85, eyes=0.85, sw=1.15, h=1.04, glow='7aa8ff'),
    'adaeze': dict(acc=['mantle','earrings','cane','marks'], expr=1, skin='deep', hair='braids', hair_c='1c0f12', hair_sh='0a0507', eye='7a4a24', outfit='robe', top='6a3a8e', coat_in='d9b45a', trim='f0c860',
                   pants='3a2a54', boots='2a2036', brow=0.85, jaw=0.85, nose=0.85, lip=1.2, eyes=1.0, sw=0.88, h=0.98, glow='d890ff'),
    'tunde': dict(acc=['headphones','bracers','sole_glow','seams'], expr=1, skin='brown', hair='afro', hair_c='1a0f0a', hair_sh='0a0604', eye='7a4a22', outfit='jacket', top='2f8f5a', coat_in='f0e8d0', trim='f0d050',
                  pants='3a3430', boots='20202a', brow=1.0, jaw=1.0, nose=1.05, lip=1.0, eyes=1.0, sw=1.05, h=1.0, glow='5af0a0'),
    'sade': dict(acc=['earrings','bag','sole_glow','marks'], expr=1, skin='honey', hair='bantu', hair_c='1c120e', hair_sh='0c0705', eye='9a5a26', outfit='jacket', top='e0a030', coat_in='2a2a3a', trim='ffe080',
                 pants='2a2438', boots='3a2a22', brow=0.85, jaw=0.8, nose=0.8, lip=1.1, eyes=1.1, sw=0.85, h=0.96, glow='ffd060'),
    'bayo': dict(acc=['bag','sole_glow','earrings'], expr=2, skin='warm', hair='fade', hair_c='140f12', hair_sh='0a0709', eye='6a4424', outfit='hoodie', top='3a3a8a', coat_in='f2f2fa', trim='f09a4a',
                 pants='25252f', boots='f0f0f0', brow=1.1, jaw=1.1, nose=1.0, lip=0.95, eyes=0.95, sw=1.08, h=1.0, glow='7a7aff'),
    'ngozi': dict(acc=['mantle','earrings','marks'], expr=1, skin='bronze', hair='headwrap', hair_c='c0402a', hair_sh='7a2418', eye='8a5424', outfit='robe', top='e0a030', coat_in='3a7a5a', trim='ffe080',
                  pants='3a7a5a', boots='2a2036', brow=0.9, jaw=0.9, nose=0.9, lip=1.15, eyes=1.05, sw=0.95, h=0.97, glow='ffb050'),
    'musa': dict(acc=['scar','bracers','beads','epaulets','sole_glow'], expr=0, skin='ebony', hair='locs', hair_c='140f12', hair_sh='0a0709', eye='6a4020', outfit='vest', top='4a4a52', coat_in='b8b8c8', trim='ff6a4a',
                 pants='2a2a30', boots='3a2e2a', beard=True, brow=1.15, jaw=1.2, nose=1.2, lip=1.0, eyes=0.88, sw=1.2, h=1.05, glow='ff6a4a'),
}


def skin_c(ch):
    return hexc(SKIN[ch['skin']])


# ---------------------------------------------------------------- pose
def pose(view, phase, idle):
    s = 0.0 if idle else math.sin(phase * 2 * math.pi)
    c = 0.0 if idle else math.cos(phase * 2 * math.pi)
    bob = 0.0 if idle else -abs(c) * 2.6
    return dict(s=s, c=c, bob=bob)


# ---------------------------------------------------------------- head
def face_shape(ch, cx, cy):
    """Anime face outline (front): wide cheeks tapering to a jaw; jaw param widens or narrows."""
    j = ch['jaw']
    fw = 21.5 + 1.0 * (j - 0.9)   # half width at cheeks
    jw = 12.5 * j                   # half width near chin
    pts = [(cx, cy - 26), (cx + fw * 0.82, cy - 22), (cx + fw, cy - 8), (cx + fw * 0.97, cy + 3), (cx + jw + 4, cy + 15),
           (cx + jw * 0.55, cy + 23.5), (cx, cy + 26), (cx - jw * 0.55, cy + 23.5), (cx - jw - 4, cy + 15), (cx - fw * 0.97, cy + 3),
           (cx - fw, cy - 8), (cx - fw * 0.82, cy - 22)]
    return smooth(pts, 7)


def draw_eye(cv, ch, x, y, side, look=0.0):
    """One anime eye (side = -1 viewer-left / +1 viewer-right). Wider than tall, iris clipped by the lid, heavy upper lash line."""
    sc = ch['eyes']
    ew, eh = 6.9 * sc, 4.9 * sc
    sk = skin_c(ch)
    shape = smooth([(x - ew, y + 0.8), (x - ew * 0.55, y - eh * 0.8), (x + ew * 0.2, y - eh), (x + ew * 0.85, y - eh * 0.55), (x + ew, y - 0.2 * side + 0.2),
                    (x + ew * 0.6, y + eh * 0.75), (x - ew * 0.1, y + eh), (x - ew * 0.7, y + eh * 0.6)], 5)
    m = cv.mask()
    cv.mpoly(m, shape)
    cv.img.paste((247, 242, 242, 255), mask=m)
    ir = hexc(ch['eye'])
    ix = x + look + side * -0.2

    def iris(t):
        t.fell(ix, y + 0.3, 4.9 * sc, 6.2 * sc, mix(ir, (0, 0, 0), 0.5))
        t.fell(ix, y + 1.0, 4.4 * sc, 5.6 * sc, ir)
        t.fell(ix, y + 2.8, 3.4 * sc, 2.6 * sc, light_of(mix(ir, (255, 170, 60), 0.35), 0.4))
        t.fell(ix, y + 0.2, 1.9 * sc, 2.6 * sc, (14, 8, 12, 255))
        t.fell(ix, y - eh, 9.0 * sc, 2.6 * sc, (30, 14, 40, 110))     # lid shadow on the eyeball
        t.fell(ix - 1.5 * sc, y - 1.4 * sc, 1.5 * sc, 1.5 * sc, (255, 255, 255, 255))
        t.fell(ix + 1.7 * sc, y + 2.2 * sc, 0.8 * sc, 0.8 * sc, (255, 255, 255, 230))
    cv.clipped(m, iris)
    lid = [(x - ew - 0.3, y + 0.9), (x - ew * 0.55, y - eh * 0.85), (x + ew * 0.2, y - eh - 0.7), (x + ew * 0.85, y - eh * 0.6), (x + ew + 0.7, y - 0.6)]
    cv.line(smooth(lid, 6, False), INK, 1.8 * sc)
    fx = x + side * (ew + 0.4)
    cv.line([(fx - side * 1.0, y - 0.6), (fx + side * 2.4, y - 2.4)], INK, 1.3)
    cv.line(smooth([(x - ew * 0.6, y + eh * 0.8), (x, y + eh + 0.2), (x + ew * 0.6, y + eh * 0.8)], 5, False), mix(sk, (30, 10, 40), 0.5), 0.7)
    cv.line(smooth([(x - ew * 0.5, y - eh - 1.6), (x + ew * 0.3, y - eh - 2.3), (x + ew * 0.8, y - eh - 1.2)], 5, False), mix(sk, (30, 10, 40), 0.35), 0.6)


def draw_face_front(cv, ch, cx, cy, expr=0):
    sk = skin_c(ch)
    # neck
    nm = cv.mask()
    cv.mpoly(nm, [(cx - 9.5, cy + 16), (cx + 9.5, cy + 16), (cx + 10.5, cy + 36), (cx - 10.5, cy + 36)])
    cv.paint(nm, mix(sk, (20, 10, 40), 0.12), skin_shade(sk, 0.5), ink=True, k=4)
    # ears
    for sd in (-1, 1):
        em = cv.mask()
        cv.mell(em, cx + sd * 22.2, cy + 2.5, 3.8, 6.2)
        cv.paint(em, sk, skin_shade(sk), k=1.4)
    fm = cv.mask()
    cv.mpoly(fm, face_shape(ch, cx, cy))
    cv.paint(fm, sk, skin_shade(sk, 0.42), k=2.6, hi=light_of(sk, 0.16))
    # cheek light + chin shadow (soft, via clipped patches)
    def soft(t):
        t.fell(cx - 11, cy + 8, 5.5, 3.5, (255, 190, 160, 40))
        t.fell(cx + 11, cy + 8, 5.5, 3.5, (255, 190, 160, 40))
        t.fell(cx, cy + 25, 15, 6, (20, 6, 40, 55))
        t.fell(cx - 8, cy - 15, 9, 3.4, (255, 230, 200, 46))      # forehead light
        t.fell(cx - 12.5, cy + 3, 4.2, 2.4, (255, 225, 190, 70))   # cheekbone light
        t.fell(cx + 12.5, cy + 3, 4.2, 2.4, (255, 225, 190, 38))
        t.line([(cx - 1.2, cy - 2), (cx - 1.6, cy + 6)], (255, 225, 190, 60), 1.0)   # nose bridge light
        t.fell(cx, cy + 18.5, 4, 1.2, (255, 210, 190, 40))
    cv.clipped(fm, soft)
    ex = 9.6 + 0.6 * (ch['eyes'] - 1.0)
    ey = cy + 0.5
    draw_eye(cv, ch, cx - ex, ey, -1)
    draw_eye(cv, ch, cx + ex, ey, 1)
    # brows
    bw = 1.3 + 0.9 * ch['brow']
    hair = hexc(ch['hair_c'])
    bc = mix(hair, (0, 0, 0), 0.25) if sum(hair[:3]) < 400 else mix(hexc(SKIN[ch['skin']]), (0, 0, 0), 0.55)
    for sd in (-1, 1):
        by = ey - 9.2 - (1.0 if expr == 1 else 0)
        pts = [(cx + sd * (ex + 6.5), by + 1.6), (cx + sd * (ex + 1), by - 1.2 - (1 if expr == 1 else 0)), (cx + sd * (ex - 5.5), by + 0.8)]
        cv.line(smooth(pts, 5, False), bc, bw)
    # nose: soft shadow + nostrils
    n = ch['nose']
    cv.line([(cx - 0.4, cy + 2), (cx - 1.2 * n, cy + 8.5)], mix(sk, (20, 6, 40), 0.35), 1.1)
    cv.fell(cx - 2.8 * n, cy + 9.6, 1.5 * n, 1.0, mix(sk, (20, 6, 40), 0.6))
    cv.fell(cx + 2.8 * n, cy + 9.6, 1.5 * n, 1.0, mix(sk, (20, 6, 40), 0.6))
    cv.fell(cx + 0.2, cy + 8.2, 2.0 * n, 1.2, light_of(sk, 0.3))
    # mouth: upper lip line + fuller lower lip tint
    lp = ch['lip']
    my = cy + 16.2
    lipc = mix(sk, (120, 30, 50), 0.35)
    cv.fell(cx, my + 1.4, 4.8 * lp, 1.9 * lp, lipc)
    cv.line(smooth([(cx - 5.2 * lp, my), (cx - 2, my - 0.8), (cx, my - 0.4), (cx + 2, my - 0.8), (cx + 5.2 * lp, my)], 5, False), mix(sk, (20, 4, 30), 0.7), 1.0)
    if expr == 2:   # smirk: one corner lifts
        cv.line([(cx + 5.2 * lp, my - 0.4), (cx + 7.4 * lp, my - 2.2)], mix(sk, (20, 4, 30), 0.7), 1.0)
        cv.line([(cx - 5.2 * lp, my), (cx - 6.0 * lp, my + 0.4)], mix(sk, (20, 4, 30), 0.7), 0.9)
    if expr == 1:   # slight smile
        cv.line([(cx - 5.5 * lp, my - 0.4), (cx - 6.8 * lp, my - 1.6)], mix(sk, (20, 4, 30), 0.7), 0.9)
        cv.line([(cx + 5.5 * lp, my - 0.4), (cx + 6.8 * lp, my - 1.6)], mix(sk, (20, 4, 30), 0.7), 0.9)
    cv.fell(cx, my + 2.3, 2.2 * lp, 0.6, (255, 220, 215, 90))
    if sum(sk[:3]) < 260:   # very deep skin: lift the lip and nose so the features stay readable
        cv.fell(cx, my + 1.6, 3.6 * lp, 1.1, (150, 70, 70, 120))
        cv.fell(cx + 0.3, cy + 8.0, 1.6 * n, 0.8, (255, 215, 190, 70))
    if ch.get('beard'):
        bm = cv.mask()
        pts = smooth([(cx - 17, cy + 6), (cx - 13, cy + 20), (cx, cy + 29), (cx + 13, cy + 20), (cx + 17, cy + 6), (cx + 11, cy + 15), (cx, cy + 19.5), (cx - 11, cy + 15)], 6)
        cv.mpoly(bm, pts)
        cv.paint(bm, hexc(ch['hair_c']), hexc(ch['hair_sh']), ink=False, k=2)
        cv.fell(cx, my + 1.5, 4.4 * lp, 1.6, lipc)
    if ch.get('glasses'):
        for sd in (-1, 1):
            cv.line(smooth([(cx + sd * (ex - 7.8), ey - 5.5), (cx + sd * (ex + 7.8), ey - 5.5), (cx + sd * (ex + 7.8), ey + 6.5), (cx + sd * (ex - 7.8), ey + 6.5)], 4, True), (190, 200, 235, 255), 1.5)
        cv.line([(cx - ex + 7.8, ey - 1), (cx + ex - 7.8, ey - 1)], (190, 200, 235, 255), 1.3)
    return fm


def hair_front(cv, ch, cx, cy, back=False):
    """Hair drawn over (front) or behind (back=True) the face. Natural textures: bumpy silhouettes, twist/loc/braid strands."""
    hc, hs = hexc(ch['hair_c']), hexc(ch['hair_sh'])
    st = ch['hair']
    rng = random.Random(hash(ch['hair_c'] + st) & 0xffff)
    hl = light_of(hc, 0.28) if sum(hc[:3]) < 450 else (255, 255, 255, 255)

    def bumps(m, cxx, cyy, rx, ry, n, r, a0=0, a1=2 * math.pi, jit=0.0):
        for i in range(n):
            a = a0 + (a1 - a0) * i / max(1, n - 1)
            j = 1.0 + rng.uniform(-jit, jit)
            cv.mell(m, cxx + math.cos(a) * rx * j, cyy + math.sin(a) * ry * j, r, r)

    if st == 'twists':
        if back:
            return
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 22, cy - 2), (cx - 23, cy - 18), (cx - 14, cy - 29), (cx, cy - 32), (cx + 14, cy - 29), (cx + 23, cy - 18), (cx + 22, cy - 2),
                            (cx + 17, cy - 12), (cx + 7, cy - 16), (cx - 3, cy - 15), (cx - 11, cy - 17), (cx - 18, cy - 11)], 6))
        for i in range(-5, 6):   # fan of short twists on the crown
            a0 = i * 0.2
            bx, by0 = cx + math.sin(a0) * 19, cy - 20 - math.cos(a0) * 11
            tx, ty = cx + math.sin(a0) * 25, cy - 20 - math.cos(a0) * 17 - (2.5 - abs(i) * 0.35)
            cv.mlimb(m, (bx, by0), (tx, ty), 6.0, 5.2)
        hair_paint(cv, m, hc, hs, hl, cx, cy, 2.6)
        for i in range(-5, 6):
            a0 = i * 0.2
            for t in range(3):   # coil marks along each twist
                u = 0.3 + t * 0.22
                px = cx + math.sin(a0) * (19 + 8 * u)
                py = cy - 20 - math.cos(a0) * (11 + 10 * u) - (3 - abs(i) * 0.4) * u
                cv.line([(px - 1.8, py + 0.6), (px + 1.8, py - 0.6)], hs, 0.7)
        cv.clipped(m, lambda t: [t.fell(cx - 8, cy - 28, 7, 2.4, (255, 255, 255, 40))])
    elif st == 'afro':
        m = cv.mask()
        if back:
            cv.mell(m, cx, cy - 12, 34, 34)
            bumps(m, cx, cy - 12, 33, 33, 22, 5.0, 0, 2 * math.pi, 0.05)
            cv.paint(m, hs, shade_of(hs, 0.4), k=2)
            return
        cv.mell(m, cx, cy - 15, 31, 28)
        bumps(m, cx, cy - 15, 30, 27, 22, 5.5, math.pi * 0.95, math.pi * 2.05, 0.05)
        cv.mpoly(m, smooth([(cx - 24, cy), (cx - 20, cy - 14), (cx - 8, cy - 16), (cx + 8, cy - 16), (cx + 20, cy - 14), (cx + 24, cy)], 5))
        hair_paint(cv, m, hc, hs, hl, cx, cy, 3.4)
        cv.clipped(m, lambda t: [t.fell(cx - 14 + (i % 4) * 9, cy - 36 + (i // 4) * 8, 2.4, 1.2, (255, 255, 255, 18)) for i in range(12)])
    elif st == 'puffs':
        m = cv.mask()
        if back:
            return
        for sd in (-1, 1):
            cv.mell(m, cx + sd * 19, cy - 30, 15, 14)
            bumps(m, cx + sd * 19, cy - 30, 14, 13, 10, 4.2, 0, 2 * math.pi, 0.05)
        cv.mpoly(m, smooth([(cx - 22, cy - 8), (cx - 22, cy - 24), (cx - 10, cy - 33), (cx + 10, cy - 33), (cx + 22, cy - 24), (cx + 22, cy - 8),
                            (cx + 14, cy - 15), (cx, cy - 18), (cx - 14, cy - 15)], 6))
        hair_paint(cv, m, hc, hs, hl, cx, cy, 3)
        for sd in (-1, 1):   # ties
            cv.fell(cx + sd * 12, cy - 24, 2.6, 2.6, hexc(ch['trim']))
    elif st == 'locs':
        if back:
            for i in range(-6, 7):
                x0 = cx + i * 3.4
                m = cv.mask()
                cv.mlimb(m, (x0, cy - 12), (x0 + i * 1.4, cy + 50 + abs(i) * 2), 5.2, 4.2)
                cv.paint(m, hs, shade_of(hs, 0.4), k=1.5)
            return
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 24, cy - 2), (cx - 24, cy - 22), (cx - 14, cy - 35), (cx, cy - 38), (cx + 14, cy - 35), (cx + 24, cy - 22), (cx + 24, cy - 2),
                            (cx + 17, cy - 14), (cx + 5, cy - 20), (cx - 8, cy - 16), (cx - 18, cy - 10)], 6))
        bumps(m, cx, cy - 22, 25, 14, 12, 4.4, math.pi * 1.02, math.pi * 1.98, 0.05)
        hair_paint(cv, m, hc, hs, hl, cx, cy, 3)
        for sd in (-1, 1):   # front locs framing the face
            for j in range(3):
                mm = cv.mask()
                x0 = cx + sd * (23 + j * 2.6)
                cv.mlimb(mm, (x0, cy - 12), (x0 + sd * (1.5 + j), cy + 36 + j * 6), 5.0, 4.0)
                cv.paint(mm, hc, hs, k=1.5, hi=hl)
    elif st == 'braids':
        if back:
            for i in range(-5, 6):
                x0 = cx + i * 4.0
                m = cv.mask()
                cv.mlimb(m, (x0, cy - 14), (x0 + i * 1.8, cy + 62), 4.8, 3.6)
                cv.paint(m, hs, shade_of(hs, 0.4), k=1.4)
                for t in range(9):
                    cv.fell(x0 + i * 0.1 * t, cy - 8 + t * 7.6, 2.1, 0.8, (255, 255, 255, 22))
            return
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 23, cy - 4), (cx - 24, cy - 22), (cx - 14, cy - 34), (cx, cy - 37), (cx + 14, cy - 34), (cx + 24, cy - 22), (cx + 23, cy - 4),
                            (cx + 14, cy - 15), (cx + 2, cy - 21), (cx - 3, cy - 17), (cx - 14, cy - 13)], 6))
        bumps(m, cx, cy - 22, 24, 14, 11, 3.6, math.pi * 1.02, math.pi * 1.98, 0.03)
        hair_paint(cv, m, hc, hs, hl, cx, cy, 3)
        cv.line([(cx, cy - 36), (cx + 2, cy - 20)], hs, 1.2)
        for i in range(-4, 5):
            cv.line([(cx + i * 4.2, cy - 33 + abs(i) * 0.5), (cx + i * 4.2 + i * 0.5, cy - 14 + abs(i))], hs, 0.9)
        for sd in (-1, 1):
            for j in range(2):
                mm = cv.mask()
                x0 = cx + sd * (23 + j * 3)
                cv.mlimb(mm, (x0, cy - 8), (x0 + sd * 2, cy + 44 + j * 8), 4.6, 3.4)
                cv.paint(mm, hc, hs, k=1.3, hi=hl)
                cv.fell(x0 + sd * 2, cy + 44 + j * 8, 2.6, 2.6, hexc(ch['trim']))
    elif st == 'curly_long':
        if back:
            m = cv.mask()
            cv.mpoly(m, smooth([(cx - 30, cy - 18), (cx - 36, cy + 20), (cx - 34, cy + 66), (cx - 20, cy + 82), (cx, cy + 78), (cx + 20, cy + 82), (cx + 34, cy + 66),
                                (cx + 36, cy + 20), (cx + 30, cy - 18), (cx, cy - 36)], 6))
            bumps(m, cx, cy + 30, 33, 48, 28, 5.2, 0, 2 * math.pi, 0.07)
            cv.paint(m, hs, shade_of(hs, 0.5), k=2.5)
            return
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 27, cy + 4), (cx - 30, cy - 18), (cx - 18, cy - 34), (cx, cy - 39), (cx + 18, cy - 34), (cx + 30, cy - 18), (cx + 27, cy + 4),
                            (cx + 21, cy - 10), (cx + 9, cy - 19), (cx - 4, cy - 17), (cx - 14, cy - 11), (cx - 21, cy - 4)], 6))
        bumps(m, cx, cy - 21, 28, 16, 15, 5.0, math.pi * 1.0, math.pi * 2.0, 0.05)
        hair_paint(cv, m, hc, hs, hl, cx, cy, 3.2)
        for sd in (-1, 1):   # long curls falling in front of the shoulders
            mm = cv.mask()
            pts = [(cx + sd * 24, cy - 10), (cx + sd * 30, cy + 20), (cx + sd * 27, cy + 56), (cx + sd * 22, cy + 70), (cx + sd * 19, cy + 40), (cx + sd * 20, cy + 6)]
            cv.mpoly(mm, smooth(pts, 6))
            bumps(mm, cx + sd * 25, cy + 36, 4, 30, 10, 4.2, 0, 2 * math.pi, 0.05)
            cv.paint(mm, hc, hs, k=2.4, hi=hl)
        if ch.get('band'):
            cv.line(smooth([(cx - 25, cy - 20), (cx - 12, cy - 30), (cx + 10, cy - 30), (cx + 25, cy - 20)], 5, False), hexc(ch['trim']), 3.2)
            cv.fell(cx + 20, cy - 25, 3.2, 3.2, (255, 244, 190, 255))
    elif st == 'fade':
        if back:
            return
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 21, cy - 6), (cx - 21, cy - 20), (cx - 12, cy - 30), (cx, cy - 33), (cx + 12, cy - 30), (cx + 21, cy - 20), (cx + 21, cy - 6),
                            (cx + 14, cy - 17), (cx, cy - 20), (cx - 14, cy - 17)], 6))
        hair_paint(cv, m, hc, hs, hl, cx, cy, 2.4)
        cv.clipped(m, lambda t: [t.line([(cx - 16 + i * 4, cy - 31), (cx - 16 + i * 4 + 1, cy - 20)], (255, 255, 255, 14), 0.8) for i in range(9)])
    elif st == 'bantu':
        if back:
            return
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 22, cy - 6), (cx - 22, cy - 20), (cx - 12, cy - 29), (cx + 12, cy - 29), (cx + 22, cy - 20), (cx + 22, cy - 6),
                            (cx + 14, cy - 16), (cx, cy - 19), (cx - 14, cy - 16)], 6))
        for i in range(7):
            cv.mell(m, cx - 18 + i * 6, cy - 31 - (1 if i % 2 else 0), 4.6, 4.6)
        hair_paint(cv, m, hc, hs, hl, cx, cy, 2.6)
        for i in range(7):
            cv.fell(cx - 18 + i * 6, cy - 31 - (1 if i % 2 else 0), 1.4, 1.4, hs)
    elif st == 'headwrap':
        if back:
            return
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 24, cy - 4), (cx - 24, cy - 24), (cx - 12, cy - 38), (cx + 4, cy - 44), (cx + 20, cy - 36), (cx + 25, cy - 20), (cx + 23, cy - 4),
                            (cx + 14, cy - 12), (cx, cy - 15), (cx - 14, cy - 12)], 6))
        hair_paint(cv, m, hc, hs, hl, cx, cy, 3)
        cv.clipped(m, lambda t: [t.line([(cx - 26, cy - 8 - i * 6), (cx + 26, cy - 20 - i * 6)], hexc(ch['trim']), 1.3) for i in range(5)])
        mm = cv.mask()
        cv.mell(mm, cx + 11, cy - 41, 8, 5)
        cv.paint(mm, hc, hs, k=2)
    elif st == 'bald':
        if back:
            return
        sk = skin_c(ch)
        cv.fell(cx - 8, cy - 23, 6, 2.2, light_of(sk, 0.35))


def hair_paint(cv, m, hc, hs, hl, cx, cy, k):
    cv.paint(m, hc, hs, k=k, hi=hl)
    dark = sum(hc[:3]) < 450
    shine = (255, 255, 255, 120) if not dark else mix(hc, (200, 190, 255), 0.55)[:3] + (150,)
    def sh(t):
        t.line(smooth([(cx - 17, cy - 21), (cx - 9, cy - 28), (cx + 3, cy - 30), (cx + 14, cy - 24)], 6, False), shine, 3.2)
        t.line(smooth([(cx - 12, cy - 17), (cx - 4, cy - 23)], 4, False), shine[:3] + (70,), 1.6)
        t.line(smooth([(cx + 13, cy - 27), (cx + 20, cy - 18)], 4, False), (130, 110, 255, 90), 1.6)   # cool rim from the neon
    cv.clipped(m, sh)


def head_front(cv, ch, cx, cy, expr=0):
    hair_front(cv, ch, cx, cy, back=True)
    fm = draw_face_front(cv, ch, cx, cy, expr)
    hair_front(cv, ch, cx, cy, back=False)
    if ch.get('goggles'):
        gc = hexc(ch['trim'])
        m = cv.mask()
        cv.line(smooth([(cx - 24, cy - 24), (cx, cy - 29), (cx + 24, cy - 24)], 5, False), (40, 36, 44, 255), 3.2)
        for sd in (-1, 1):
            m = cv.mask()
            cv.mell(m, cx + sd * 10, cy - 28, 7.2, 6.2)
            cv.paint(m, (60, 54, 66, 255), (30, 26, 34, 255), k=1.6)
            cv.fell(cx + sd * 10, cy - 28, 5, 4.2, mix(hexc(ch['glow']), (0, 0, 0), 0.25))
            cv.fell(cx + sd * 10 - 1.4, cy - 29.4, 1.8, 1.4, (255, 255, 255, 190))


# ---------------------------------------------------------------- head side / back
def head_side(cv, ch, cx, cy, expr=0):
    """Profile facing right."""
    sk = skin_c(ch)
    hair_front(cv, ch, cx, cy, back=True) if ch['hair'] in ('locs', 'braids', 'curly_long', 'afro') else None
    nm = cv.mask()
    cv.mpoly(nm, [(cx - 7, cy + 14), (cx + 6, cy + 14), (cx + 7, cy + 36), (cx - 9, cy + 36)])
    cv.paint(nm, mix(sk, (20, 10, 40), 0.12), skin_shade(sk, 0.5), k=3)
    nose = 4.5 * ch['nose']
    pts = [(cx - 19, cy - 14), (cx - 20, cy + 2), (cx - 15, cy + 15), (cx - 5, cy + 22), (cx + 5, cy + 26), (cx + 13, cy + 21.5), (cx + 16.5, cy + 17), (cx + 17.5, cy + 14.5),
           (cx + 17, cy + 12), (cx + 14, cy + 10.5), (cx + 19 + nose * 0.3, cy + 8), (cx + 20 + nose, cy + 5), (cx + 17.5, cy + 1), (cx + 17.5, cy - 4),
           (cx + 19.5, cy - 12), (cx + 14, cy - 23), (cx + 2, cy - 27), (cx - 12, cy - 24)]
    fm = cv.mask()
    cv.mpoly(fm, smooth(pts, 5))
    cv.paint(fm, sk, skin_shade(sk, 0.42), k=3, hi=light_of(sk, 0.16))
    em = cv.mask()
    cv.mell(em, cx - 6, cy + 4, 4.6, 6.6)
    cv.paint(em, mix(sk, (30, 10, 20), 0.1), skin_shade(sk, 0.5), k=1.4)
    cv.line([(cx - 7, cy + 2), (cx - 5, cy + 5), (cx - 7.5, cy + 7)], skin_shade(sk, 0.7), 0.8)
    # eye
    sc = ch['eyes']
    ex, ey = cx + 11, cy - 0.5
    cv.fell(ex, ey, 4.8 * sc, 6.0 * sc, (246, 240, 240, 255))
    ir = hexc(ch['eye'])
    cv.fell(ex + 1.4, ey + 0.8, 3.2 * sc, 5.2 * sc, ir)
    cv.fell(ex + 1.6, ey + 0.4, 1.6 * sc, 2.9 * sc, (14, 8, 12, 255))
    cv.fell(ex + 0.5, ey - 1.8 * sc, 1.3, 1.3, (255, 255, 255, 255))
    cv.line(smooth([(ex - 4.2 * sc, ey - 1), (ex, ey - 5.8 * sc), (ex + 5.2 * sc, ey - 2.6)], 5, False), INK, 1.7)
    cv.line([(ex - 4, ey - 5.4 * sc), (ex - 6, ey - 4.2)], INK, 1.2)
    cv.line(smooth([(ex - 3, ey - 9.5), (ex + 3, ey - 10.5), (ex + 8, ey - 8.5)], 4, False), mix(hexc(ch['hair_c']), (0, 0, 0), 0.3) if sum(hexc(ch['hair_c'])[:3]) < 400 else skin_shade(sk, 0.7), 1.2 + 0.8 * ch['brow'])
    my = cy + 16.5
    cv.line([(cx + 17, my - 0.2), (cx + 12, my + 0.4)], mix(sk, (20, 4, 30), 0.7), 0.9)
    cv.fell(cx + 15.6, my + 2.0, 2.0 * ch['lip'], 1.4, mix(sk, (120, 30, 50), 0.3))
    if ch.get('beard'):
        bm = cv.mask()
        cv.mpoly(bm, smooth([(cx - 5, cy + 6), (cx + 6, cy + 14), (cx + 15, cy + 15), (cx + 17, cy + 24), (cx + 6, cy + 30), (cx - 8, cy + 22)], 5))
        cv.paint(bm, hexc(ch['hair_c']), hexc(ch['hair_sh']), ink=False, k=2)
    # hair on the profile head
    hc, hs = hexc(ch['hair_c']), hexc(ch['hair_sh'])
    hl = light_of(hc, 0.28) if sum(hc[:3]) < 450 else (255, 255, 255, 255)
    st = ch['hair']
    if st == 'bald':
        pass
    else:
        m = cv.mask()
        if st in ('afro',):
            cv.mell(m, cx - 2, cy - 16, 30, 27)
        elif st == 'puffs':
            cv.mell(m, cx - 10, cy - 28, 14, 14)
            cv.mpoly(m, smooth([(cx - 20, cy - 4), (cx - 20, cy - 22), (cx, cy - 31), (cx + 14, cy - 24), (cx + 19, cy - 12), (cx + 8, cy - 14), (cx - 4, cy - 10)], 5))
        elif st == 'headwrap':
            cv.mpoly(m, smooth([(cx - 24, cy + 2), (cx - 24, cy - 24), (cx - 8, cy - 40), (cx + 12, cy - 36), (cx + 21, cy - 20), (cx + 19, cy - 6), (cx + 8, cy - 12), (cx - 6, cy - 8)], 6))
        else:
            ext = 26 if st in ('curly_long',) else 22
            cv.mpoly(m, smooth([(cx - ext, cy + 6), (cx - ext - 1, cy - 20), (cx - 8, cy - 33), (cx + 8, cy - 32), (cx + 20, cy - 18), (cx + 19, cy - 8), (cx + 9, cy - 13), (cx - 2, cy - 12), (cx - 8, cy - 2)], 6))
        if st in ('twists', 'afro', 'curly_long', 'locs', 'bantu', 'braids'):
            for i in range(10):
                a = math.pi * (1.0 + i / 9.0 * 1.1)
                cv.mell(m, cx - 2 + math.cos(a) * 20, cy - 16 + math.sin(a) * 18, 4.2, 4.2)
        if st == 'bantu':
            for i in range(4):
                cv.mell(m, cx - 14 + i * 7, cy - 33, 4.6, 4.6)
        hair_paint(cv, m, hc, hs, hl, cx, cy, 3)
        if st in ('locs', 'braids', 'curly_long'):
            L = {'locs': 52, 'braids': 62, 'curly_long': 70}[st]
            for i in range(5 if st != 'curly_long' else 7):
                mm = cv.mask()
                x0 = cx - 18 + i * 3.4
                cv.mlimb(mm, (x0, cy - 10), (x0 - 3, cy + L - i * 2), 5.0, 3.6 if st != 'curly_long' else 6.4)
                cv.paint(mm, hc, hs, k=1.4, hi=hl)
        if ch.get('band'):
            cv.line(smooth([(cx - 22, cy - 15), (cx - 8, cy - 27), (cx + 10, cy - 25), (cx + 19, cy - 14)], 5, False), hexc(ch['trim']), 3.0)
    if ch.get('goggles'):
        cv.line(smooth([(cx - 22, cy - 22), (cx, cy - 28), (cx + 18, cy - 22)], 5, False), (40, 36, 44, 255), 3.0)
        m = cv.mask()
        cv.mell(m, cx + 8, cy - 27, 7, 6)
        cv.paint(m, (60, 54, 66, 255), (30, 26, 34, 255), k=1.5)
        cv.fell(cx + 8, cy - 27, 4.6, 4, mix(hexc(ch['glow']), (0, 0, 0), 0.25))
    if ch.get('glasses'):
        cv.line(smooth([(cx + 5, ey - 5), (cx + 17, ey - 5), (cx + 17, ey + 6), (cx + 5, ey + 6)], 4, True), (190, 200, 235, 255), 1.4)
        cv.line([(cx + 5, ey - 2), (cx - 16, ey - 2)], (190, 200, 235, 255), 1.2)


def head_back(cv, ch, cx, cy):
    sk = skin_c(ch)
    st = ch['hair']
    hair_front(cv, ch, cx, cy, back=True)
    nm = cv.mask()
    cv.mpoly(nm, [(cx - 9.5, cy + 14), (cx + 9.5, cy + 14), (cx + 10.5, cy + 36), (cx - 10.5, cy + 36)])
    cv.paint(nm, mix(sk, (20, 10, 40), 0.12), skin_shade(sk, 0.5), k=3)
    for sd in (-1, 1):
        em = cv.mask()
        cv.mell(em, cx + sd * 22.2, cy + 2.5, 3.6, 6)
        cv.paint(em, sk, skin_shade(sk), k=1.2)
    fm = cv.mask()
    cv.mpoly(fm, face_shape(ch, cx, cy))
    cv.paint(fm, sk, skin_shade(sk, 0.42), k=2.6)
    hc, hs = hexc(ch['hair_c']), hexc(ch['hair_sh'])
    hl = light_of(hc, 0.28) if sum(hc[:3]) < 450 else (255, 255, 255, 255)
    if st != 'bald':
        m = cv.mask()
        if st == 'afro':
            cv.mell(m, cx, cy - 12, 34, 33)
            for i in range(26):
                a = i / 26 * 2 * math.pi
                cv.mell(m, cx + math.cos(a) * 33, cy - 12 + math.sin(a) * 32, 5, 5)
        elif st == 'puffs':
            for sd in (-1, 1):
                cv.mell(m, cx + sd * 19, cy - 30, 15, 14)
            cv.mpoly(m, smooth([(cx - 23, cy + 8), (cx - 24, cy - 20), (cx - 10, cy - 33), (cx + 10, cy - 33), (cx + 24, cy - 20), (cx + 23, cy + 8), (cx + 12, cy + 4), (cx - 12, cy + 4)], 6))
        elif st == 'curly_long':
            cv.mpoly(m, smooth([(cx - 30, cy - 18), (cx - 36, cy + 20), (cx - 32, cy + 70), (cx - 16, cy + 84), (cx, cy + 80), (cx + 16, cy + 84), (cx + 32, cy + 70), (cx + 36, cy + 20), (cx + 30, cy - 18), (cx, cy - 37)], 6))
            for i in range(30):
                a = i / 30 * 2 * math.pi
                cv.mell(m, cx + math.cos(a) * 33, cy + 28 + math.sin(a) * 50, 5, 5)
        elif st == 'headwrap':
            cv.mpoly(m, smooth([(cx - 24, cy + 6), (cx - 24, cy - 24), (cx - 10, cy - 38), (cx + 6, cy - 44), (cx + 20, cy - 36), (cx + 25, cy - 20), (cx + 23, cy + 6), (cx, cy + 12)], 6))
        else:
            cv.mpoly(m, smooth([(cx - 23, cy + 8), (cx - 24, cy - 20), (cx - 12, cy - 34), (cx, cy - 37), (cx + 12, cy - 34), (cx + 24, cy - 20), (cx + 23, cy + 8), (cx + 12, cy + 2), (cx - 12, cy + 2)], 6))
            if st in ('twists', 'bantu', 'locs', 'braids'):
                for i in range(12):
                    a = math.pi * (1.0 + i / 11.0)
                    cv.mell(m, cx + math.cos(a) * 22, cy - 15 + math.sin(a) * 19, 4.6, 4.6)
        hair_paint(cv, m, hc, hs, hl, cx, cy, 3.4)
        if st in ('locs', 'braids'):
            for i in range(-6, 7):
                mm = cv.mask()
                x0 = cx + i * 3.4
                cv.mlimb(mm, (x0, cy - 6), (x0 + i * 1.3, cy + (50 if st == 'locs' else 62) + abs(i)), 5.0, 3.6)
                cv.paint(mm, hc, hs, k=1.4, hi=hl)
        if ch.get('band'):
            cv.line(smooth([(cx - 25, cy - 20), (cx, cy - 12), (cx + 25, cy - 20)], 5, False), hexc(ch['trim']), 3.2)
        if st == 'bantu':
            for i in range(5):
                mm = cv.mask()
                cv.mell(mm, cx - 15 + i * 7.5, cy - 33, 4.8, 4.8)
                cv.paint(mm, hc, hs, k=1.5)
    if ch.get('goggles'):
        cv.line(smooth([(cx - 24, cy - 24), (cx, cy - 18), (cx + 24, cy - 24)], 5, False), (40, 36, 44, 255), 3.0)


# ---------------------------------------------------------------- body
def clothing_colors(ch):
    return hexc(ch['top']), hexc(ch['coat_in']), hexc(ch['trim']), hexc(ch['pants']), hexc(ch['boots'])


def body_front(cv, ch, cx, P, back=False):
    """Draw torso/legs/arms for a front or back view. P = pose dict."""
    sk = skin_c(ch)
    top, inn, trim, pants, boots = clothing_colors(ch)
    sw = 29 * ch['sw']
    by = P['bob']
    s = P['s']
    out = ch['outfit']
    glow = hexc(ch['glow'])
    legs_y = 164 + by
    lift_l = max(0.0, s) * 9
    lift_r = max(0.0, -s) * 9
    # legs
    for sd, lift in ((-1, lift_l), (1, lift_r)):
        hx = cx + sd * 11.5
        kx, ky = hx + sd * 0.8, 216 + by - lift * 0.55
        ax, ay = hx + sd * 0.4, 266 - lift
        m = cv.mask()
        cv.mlimb(m, (hx, legs_y), (kx, ky), 19, 15.5)
        cv.mlimb(m, (kx, ky), (ax, ay), 15.5, 12.0)
        cv.paint(m, pants, shade_of(pants, 0.45), k=2.6, rim=mix(glow, (0, 0, 0), 0.2) if sd > 0 else None)
        bm = cv.mask()
        cv.mpoly(bm, smooth([(ax - 8, ay - 10), (ax + 8, ay - 10), (ax + 9, ay + 2), (ax + 10.5, ay + 9), (ax - 10.5, ay + 9), (ax - 9, ay + 2)], 4))
        cv.paint(bm, boots, shade_of(boots, 0.45), k=2.2)
        cv.line([(ax - 9.5, ay + 6.5), (ax + 9.5, ay + 6.5)], (10, 8, 14, 255), 1.4)
        cv.line([(ax - 7.5, ay - 6), (ax + 7.5, ay - 6)], trim, 1.0)
    if ch.get('cape') and not back:
        for sd in (-1, 1):
            m = cv.mask()
            cv.mpoly(m, smooth([(cx + sd * 22, 98 + by), (cx + sd * 40 - sd * s * 2, 140 + by), (cx + sd * 42, 200 + by), (cx + sd * 32, 238 + by), (cx + sd * 24, 150 + by)], 5))
            cv.paint(m, inn, shade_of(inn, 0.45), k=3)
            cv.line([(cx + sd * 42, 200 + by), (cx + sd * 32, 238 + by)], trim, 1.4)
    # coat tails / skirt (behind arms, over legs)
    long_coat = out in ('coat', 'robe', 'jacket' if ch.get('cape') else '')
    if out in ('coat',):
        for sd in (-1, 1):
            m = cv.mask()
            sway = s * 2.0 * sd
            cv.mpoly(m, smooth([(cx + sd * 3, 150 + by), (cx + sd * 26, 150 + by), (cx + sd * 33 + sway, 205 + by), (cx + sd * 31 + sway * 1.5, 246 + by), (cx + sd * 15, 240 + by), (cx + sd * 4, 244 + by)], 5))
            cv.paint(m, top, shade_of(top, 0.5), k=3, rim=mix(glow, (0, 0, 0), 0.3) if sd > 0 else None)
            cv.clipped(m, lambda t: t.line([(cx + sd * 4, 160 + by), (cx + sd * 5, 244 + by)], inn, 2.4))
            cv.line([(cx + sd * 31 + sway * 1.5, 244 + by), (cx + sd * 15, 238 + by)], trim, 1.2)
    elif out == 'robe':
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 24, 150 + by), (cx + 24, 150 + by), (cx + 36, 238 + by), (cx + 12, 250 + by), (cx - 12, 250 + by), (cx - 36, 238 + by)], 5))
        cv.paint(m, top, shade_of(top, 0.5), k=3)
        cv.clipped(m, lambda t: [t.line([(cx - 36 + i * 9, 160 + by), (cx - 40 + i * 10, 250 + by)], (255, 255, 255, 20), 1) for i in range(8)])
        cv.line([(cx - 35, 236 + by), (cx - 12, 248 + by), (cx + 12, 248 + by), (cx + 35, 236 + by)], trim, 1.6)
    elif out in ('jacket', 'hoodie', 'vest', 'apron', 'overall', 'suit'):
        hem = {'jacket': 188, 'hoodie': 190, 'vest': 182, 'apron': 224, 'overall': 176, 'suit': 205}[out]
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 23, 148 + by), (cx + 23, 148 + by), (cx + 27, hem + by), (cx, hem + 4 + by), (cx - 27, hem + by)], 5))
        cv.paint(m, top, shade_of(top, 0.5), k=3, rim=mix(glow, (0, 0, 0), 0.3))
    # torso
    tm = cv.mask()
    tw = sw * 0.94
    cv.mpoly(tm, smooth([(cx - sw, 100 + by), (cx - sw * 0.35, 94 + by), (cx + sw * 0.35, 94 + by), (cx + sw, 100 + by), (cx + tw * 0.74, 130 + by), (cx + 22, 154 + by),
                         (cx + 25, 168 + by), (cx - 25, 168 + by), (cx - 22, 154 + by), (cx - tw * 0.74, 130 + by)], 5))
    shirt = top
    if out == 'coat':
        shirt = hexc('2a2740')
    if out in ('apron',):
        shirt = hexc('d8d0c0')
    if out == 'overall':
        shirt = hexc('e8dcc0')
    if out == 'suit':
        shirt = hexc('e8ecf4')
    if out == 'hoodie':
        shirt = top
    cv.paint(tm, shirt, shade_of(shirt, 0.5), k=3.4, rim=mix(glow, (0, 0, 0), 0.3))
    # outfit front details
    if back:
        if out == 'coat':
            cv.clipped(tm, lambda t: t.line([(cx, 98 + by), (cx, 166 + by)], trim, 1.2))
        if ch.get('cape'):
            m = cv.mask()
            sway = s * 3
            cv.mpoly(m, smooth([(cx - 26, 100 + by), (cx + 26, 100 + by), (cx + 38 + sway, 200 + by), (cx + 24 + sway, 252 + by), (cx - 10, 244 + by), (cx - 36 + sway, 230 + by)], 5))
            cv.paint(m, inn, shade_of(inn, 0.45), k=3)
            cv.line([(cx - 36 + sway, 230 + by), (cx - 10, 244 + by), (cx + 24 + sway, 252 + by)], trim, 1.6)
        if out == 'hoodie':
            m = cv.mask()
            cv.mpoly(m, smooth([(cx - 18, 94 + by), (cx + 18, 94 + by), (cx + 14, 112 + by), (cx - 14, 112 + by)], 5))
            cv.paint(m, shade_of(top, 0.2), shade_of(top, 0.5), k=2)
    else:
        if out == 'coat':
            cv.clipped(tm, lambda t: [t.line([(cx - 9, 96 + by), (cx - 2, 166 + by)], trim, 1.3), t.line([(cx + 9, 96 + by), (cx + 2, 166 + by)], trim, 1.3)])
            m = cv.mask()
            cv.mpoly(m, smooth([(cx - 12, 94 + by), (cx - 3, 96 + by), (cx - 1, 150 + by), (cx - 20, 150 + by), (cx - 17, 108 + by)], 4))
            cv.paint(m, top, shade_of(top, 0.5), ink=True, k=2)
            m2 = cv.mask()
            cv.mpoly(m2, smooth([(cx + 12, 94 + by), (cx + 3, 96 + by), (cx + 1, 150 + by), (cx + 20, 150 + by), (cx + 17, 108 + by)], 4))
            cv.paint(m2, top, shade_of(top, 0.5), ink=True, k=2, rim=mix(glow, (0, 0, 0), 0.3))
            cv.line([(cx - 20, 96 + by), (cx - 14, 150 + by)], inn, 2.2)
            cv.line([(cx + 20, 96 + by), (cx + 14, 150 + by)], inn, 2.2)
            for yy in (122, 134, 146):   # strap harness + ring
                cv.line([(cx - 20, yy + by), (cx + 20, yy + by)], (40, 30, 24, 255), 1.6)
            cv.fell(cx, 138 + by, 3.2, 3.2, trim)
            cv.fell(cx, 138 + by, 1.6, 1.6, (20, 14, 24, 255))
        elif out == 'jacket':
            cv.clipped(tm, lambda t: t.line([(cx, 98 + by), (cx, 166 + by)], trim, 1.4))
            cv.line([(cx - 20, 118 + by), (cx - 12, 140 + by)], trim, 1.2)
            cv.line([(cx + 20, 118 + by), (cx + 12, 140 + by)], trim, 1.2)
        elif out == 'apron':
            m = cv.mask()
            cv.mpoly(m, smooth([(cx - 12, 108 + by), (cx + 12, 108 + by), (cx + 16, 150 + by), (cx + 24, 222 + by), (cx - 24, 222 + by), (cx - 16, 150 + by)], 4))
            cv.paint(m, hexc('d9cdb4'), shade_of(hexc('d9cdb4'), 0.4), k=3)
            cv.clipped(m, lambda t: [t.line([(cx - 24, 160 + by + k * 10), (cx + 24, 160 + by + k * 10)], (120, 90, 70, 60), 0.8) for k in range(7)])
            cv.line([(cx - 17, 108 + by), (cx - 22, 96 + by)], hexc('e8e2d0'), 2.5)
            cv.line([(cx + 17, 108 + by), (cx + 22, 96 + by)], hexc('e8e2d0'), 2.5)
            cv.clipped(m, lambda t: [t.fell(cx - 8, 190 + by, 3, 4, (240, 150, 60, 150)), t.fell(cx + 7, 204 + by, 4, 3, (240, 150, 60, 130))])
            cv.line([(cx - 12, 142 + by), (cx + 12, 142 + by)], hexc(ch['trim']), 1.4)
            cv.mpoly(cv.mask(), [(0, 0), (1, 1), (0, 1)])
        elif out == 'overall':
            m = cv.mask()
            cv.mpoly(m, smooth([(cx - 14, 108 + by), (cx + 14, 108 + by), (cx + 22, 150 + by), (cx + 24, 168 + by), (cx - 24, 168 + by), (cx - 22, 150 + by)], 5))
            cv.paint(m, top, shade_of(top, 0.45), k=3)
            cv.line([(cx - 14, 108 + by), (cx - 22, 94 + by)], top, 3)
            cv.line([(cx + 14, 108 + by), (cx + 22, 94 + by)], top, 3)
            cv.fell(cx - 14, 112 + by, 2.2, 2.2, hexc(ch['trim']))
            cv.fell(cx + 14, 112 + by, 2.2, 2.2, hexc(ch['trim']))
            cv.clipped(m, lambda t: t.fell(cx, 138 + by, 11, 6, shade_of(top, 0.3)))
        elif out == 'suit':
            for sd in (-1, 1):
                m = cv.mask()
                cv.mpoly(m, [(cx + sd * 2, 94 + by), (cx + sd * 15, 100 + by), (cx + sd * 7, 140 + by), (cx + sd * 2, 160 + by)])
                cv.paint(m, top, shade_of(top, 0.5), k=2)
            cv.line([(cx, 100 + by), (cx, 150 + by)], hexc('c04050'), 2.2)
        elif out == 'vest':
            for sd in (-1, 1):
                m = cv.mask()
                cv.mpoly(m, [(cx + sd * 3, 96 + by), (cx + sd * 25, 100 + by), (cx + sd * 22, 160 + by), (cx + sd * 3, 164 + by)])
                cv.paint(m, top, shade_of(top, 0.5), k=2)
            cv.line([(cx - 20, 150 + by), (cx - 4, 150 + by)], hexc(ch['trim']), 1.4)
        elif out == 'hoodie':
            cv.clipped(tm, lambda t: [t.fell(cx, 148 + by, 14, 8, shade_of(top, 0.3)), t.line([(cx - 4, 98 + by), (cx - 5, 124 + by)], (240, 240, 250, 255), 1), t.line([(cx + 4, 98 + by), (cx + 5, 124 + by)], (240, 240, 250, 255), 1)])
            cv.line([(cx - 21, 128 + by), (cx + 21, 128 + by)], hexc(ch['trim']), 1.4)
        elif out == 'robe':
            cv.clipped(tm, lambda t: [t.line([(cx - 16, 96 + by), (cx + 4, 168 + by)], trim, 2.0), t.line([(cx + 16, 96 + by), (cx - 4, 168 + by)], trim, 2.0)])
        # belt
        if out in ('coat', 'jacket', 'suit', 'overall'):
            cv.line([(cx - 24, 156 + by), (cx + 24, 156 + by)], (30, 22, 24, 255), 3)
            cv.fell(cx, 156 + by, 3.4, 2.8, trim)
    # arms
    for sd in (-1, 1):
        shx = cx + sd * (sw - 2)
        swing = s * 7 * (-sd)
        ex, ey = shx + sd * 3.5, 140 + by + swing * 0.3
        wx, wy = ex + sd * 1.5, 178 + by + swing
        m = cv.mask()
        sleeve = top if out not in ('apron', 'overall', 'vest', 'suit', 'hoodie') else (hexc('2a2740') if out == 'coat' else top)
        if out == 'apron':
            sleeve = hexc('7a2a2a')
        if out == 'overall':
            sleeve = hexc('e8dcc0')
        if out == 'suit':
            sleeve = top
        if out == 'vest':
            sleeve = None
        cv.mlimb(m, (shx, 102 + by), (ex, ey), 15.5, 13.2)
        cv.mlimb(m, (ex, ey), (wx, wy), 13.2, 11.0)
        if sleeve is None:
            cv.paint(m, sk, skin_shade(sk, 0.42), k=2.4)
            if out == 'vest':
                cv.line([(ex - 6, ey + 12), (ex + 6, ey + 12)], hexc(ch['trim']), 2.0)
        else:
            cv.paint(m, sleeve, shade_of(sleeve, 0.5), k=2.6, rim=mix(glow, (0, 0, 0), 0.3) if sd > 0 else None)
        # cuff + hand
        cm = cv.mask()
        cv.mlimb(cm, (wx, wy - 3), (wx, wy + 1), 12.2, 12.2)
        cv.paint(cm, trim if out != 'hoodie' else hexc('f0f0fa'), shade_of(trim, 0.4), k=1.5)
        hm = cv.mask()
        cv.mell(hm, wx, wy + 8, 5.4, 6.8)
        glove = ch.get('gauntlet') and sd > 0
        if glove:
            cv.paint(hm, hexc('1a1424'), hexc('0a0612'), k=1.8)
            cv.line([(wx - 3, wy + 4), (wx - 1, wy + 8), (wx + 2, wy + 6), (wx + 3, wy + 12)], glow, 1.0)
            cv.fell(wx, wy + 8, 3.6, 4.6, mix(glow, (0, 0, 0), 0.55))
            cv.line([(wx - 4, wy - 14), (wx - 1, wy - 6), (wx + 2, wy - 2)], glow, 0.9)
        else:
            cv.paint(hm, sk, skin_shade(sk, 0.42), k=1.8)
    # pauldron / shoulder armor (Echo)
    if ch.get('armor'):
        m = cv.mask()
        sx = cx - sw + 1
        cv.mpoly(m, smooth([(sx - 9, 100 + by), (sx - 6, 88 + by), (sx + 8, 84 + by), (sx + 18, 94 + by), (sx + 14, 108 + by), (sx - 2, 116 + by), (sx - 12, 114 + by)], 4))
        cv.paint(m, (172, 176, 196, 255), (96, 100, 132, 255), k=3, hi=(236, 240, 252, 255))
        cv.line([(sx - 8, 100 + by), (sx + 6, 90 + by), (sx + 16, 96 + by)], trim, 1.4)
        for t in range(3):
            cv.fpoly([(sx - 10 + t * 5, 112 + by), (sx - 6 + t * 5, 120 + by), (sx - 2 + t * 5, 112 + by)], trim)
    if ch.get('scarf'):
        pass
    return tm


def body_side(cv, ch, cx, P):
    """Profile facing right."""
    sk = skin_c(ch)
    top, inn, trim, pants, boots = clothing_colors(ch)
    by = P['bob']
    s = P['s']
    out = ch['outfit']
    glow = hexc(ch['glow'])
    hipx, hipy = cx - 1, 164 + by
    th = 24.0   # thigh len
    sh = 24.0
    ang = s * 0.52   # rad swing
    legs = []
    for ph in (0, 1):   # 0 = far leg, 1 = near leg
        a = ang * (1 if ph else -1)
        kneex = hipx + math.sin(a) * th
        kneey = hipy + math.cos(a) * th
        bend = max(0.0, -a) * 0.9 if a < 0 else 0.0
        a2 = a - bend
        ankx = kneex + math.sin(a2) * sh
        anky = kneey + math.cos(a2) * sh
        # keep feet on the ground plane in contact phases
        anky = min(anky, 268 + by - (0 if a >= 0 else 0))
        legs.append(((hipx, hipy), (kneex, kneey), (ankx, anky), a2))
    far_arm_ang = -ang * 1.1
    near_arm_ang = ang * 1.1

    def leg(i, shadowed):
        hp, kn, an, a2 = legs[i]
        pc = shade_of(pants, 0.3) if shadowed else pants
        m = cv.mask()
        cv.mlimb(m, hp, kn, 17, 14)
        cv.mlimb(m, kn, an, 14, 11)
        cv.paint(m, pc, shade_of(pants, 0.5), k=2.4, rim=mix(glow, (0, 0, 0), 0.2) if not shadowed else None)
        bm = cv.mask()
        fx = an[0] + 5
        cv.mpoly(bm, smooth([(an[0] - 6, an[1] - 8), (an[0] + 6, an[1] - 8), (an[0] + 7, an[1] + 2), (fx + 8, an[1] + 7), (fx + 8, an[1] + 9.5), (an[0] - 7, an[1] + 9.5)], 4))
        cv.paint(bm, shade_of(boots, 0.25) if shadowed else boots, shade_of(boots, 0.5), k=2)

    def arm(a, near):
        shx, shy = cx - 1, 103 + by
        elx, ely = shx + math.sin(a) * 19, shy + math.cos(a) * 19
        a2 = a + 0.35 + (0.25 if near else 0.0)
        wx, wy = elx + math.sin(a2) * 17, ely + math.cos(a2) * 17
        sleeve = top if out not in ('apron', 'overall', 'vest', 'coat') else ({'apron': hexc('7a2a2a'), 'overall': hexc('e8dcc0'), 'coat': hexc('2a2740')}.get(out))
        m = cv.mask()
        cv.mlimb(m, (shx, shy), (elx, ely), 13.5, 11.5)
        cv.mlimb(m, (elx, ely), (wx, wy), 11.5, 10)
        if sleeve is None:
            cv.paint(m, sk, skin_shade(sk, 0.42), k=2)
        else:
            sc = shade_of(sleeve, 0.25) if not near else sleeve
            cv.paint(m, sc, shade_of(sleeve, 0.5), k=2.2, rim=mix(glow, (0, 0, 0), 0.3) if near else None)
        cm = cv.mask()
        cv.mlimb(cm, (wx - math.sin(a2) * 3, wy - math.cos(a2) * 3), (wx, wy), 11.5, 11.5)
        cv.paint(cm, trim, shade_of(trim, 0.4), k=1.4)
        hm = cv.mask()
        cv.mell(hm, wx + math.sin(a2) * 5, wy + math.cos(a2) * 6, 5, 6)
        if ch.get('gauntlet') and near:
            cv.paint(hm, hexc('1a1424'), hexc('0a0612'), k=1.6)
            cv.fell(wx + math.sin(a2) * 5, wy + math.cos(a2) * 6, 3, 4, mix(glow, (0, 0, 0), 0.5))
        else:
            cv.paint(hm, sk, skin_shade(sk, 0.42), k=1.6)

    # back parts first
    if ch.get('cape'):
        m = cv.mask()
        sway = s * 4
        cv.mpoly(m, smooth([(cx - 4, 100 + by), (cx - 12, 130 + by), (cx - 24 - sway, 190 + by), (cx - 30 - sway, 246 + by), (cx - 10, 238 + by), (cx + 2, 160 + by)], 5))
        cv.paint(m, inn, shade_of(inn, 0.45), k=3)
        cv.line([(cx - 30 - sway, 244 + by), (cx - 10, 238 + by)], trim, 1.5)
    if out == 'coat':
        m = cv.mask()
        sway = s * 3
        cv.mpoly(m, smooth([(cx - 2, 150 + by), (cx - 15, 156 + by), (cx - 24 - sway, 206 + by), (cx - 22 - sway, 248 + by), (cx - 4, 240 + by), (cx + 2, 200 + by)], 5))
        cv.paint(m, top, shade_of(top, 0.5), k=3)
        cv.line([(cx - 22 - sway, 246 + by), (cx - 4, 240 + by)], trim, 1.2)
    arm(far_arm_ang, False)
    leg(0, True)
    leg(1, False)
    tm = cv.mask()
    cv.mpoly(tm, smooth([(cx - 13, 98 + by), (cx + 3, 94 + by), (cx + 13, 102 + by), (cx + 14, 130 + by), (cx + 12, 156 + by), (cx + 14, 168 + by), (cx - 14, 168 + by), (cx - 12, 150 + by), (cx - 14, 120 + by)], 5))
    shirt = {'coat': hexc('2a2740'), 'apron': hexc('d8d0c0'), 'overall': hexc('e8dcc0'), 'suit': hexc('e8ecf4')}.get(out, top)
    cv.paint(tm, shirt, shade_of(shirt, 0.5), k=3, rim=mix(glow, (0, 0, 0), 0.3))
    if out == 'coat':
        m = cv.mask()
        sway = s * 2
        cv.mpoly(m, smooth([(cx - 1, 100 + by), (cx + 12, 106 + by), (cx + 12, 156 + by), (cx + 15, 214 + by), (cx + 11, 238 + by + sway * 0.3), (cx - 6, 244 + by), (cx - 10, 150 + by)], 5))
        cv.paint(m, top, shade_of(top, 0.5), k=3, rim=mix(glow, (0, 0, 0), 0.3))
        cv.line([(cx + 12, 106 + by), (cx + 13, 236 + by)], trim, 1.2)
        cv.line([(cx - 8, 98 + by), (cx - 8, 150 + by)], inn, 2.2)
    elif out == 'apron':
        m = cv.mask()
        cv.mpoly(m, smooth([(cx + 2, 108 + by), (cx + 13, 112 + by), (cx + 15, 160 + by), (cx + 16, 228 + by), (cx - 4, 228 + by), (cx - 4, 160 + by)], 5))
        cv.paint(m, hexc('e8e2d0'), shade_of(hexc('e8e2d0'), 0.4), k=2.4)
    elif out == 'robe':
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 14, 150 + by), (cx + 14, 150 + by), (cx + 26, 236 + by), (cx + 8, 250 + by), (cx - 14, 250 + by), (cx - 26, 236 + by)], 5))
        cv.paint(m, top, shade_of(top, 0.5), k=3)
        cv.line([(cx - 26, 236 + by), (cx + 8, 250 + by), (cx + 26, 236 + by)], trim, 1.5)
    elif out in ('jacket', 'hoodie', 'suit', 'overall'):
        hem = {'jacket': 188, 'hoodie': 190, 'suit': 205, 'overall': 176}[out]
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 14, 150 + by), (cx + 15, 150 + by), (cx + 17, hem + by), (cx - 16, hem + by)], 4))
        cv.paint(m, top, shade_of(top, 0.5), k=2.6, rim=mix(glow, (0, 0, 0), 0.3))
        if out == 'hoodie':
            m2 = cv.mask()
            cv.mpoly(m2, smooth([(cx - 12, 94 + by), (cx + 2, 92 + by), (cx - 4, 112 + by), (cx - 15, 108 + by)], 4))
            cv.paint(m2, shade_of(top, 0.15), shade_of(top, 0.5), k=2)
    if out in ('coat', 'jacket', 'suit', 'overall'):
        cv.line([(cx - 14, 156 + by), (cx + 14, 156 + by)], (30, 22, 24, 255), 3)
        cv.fell(cx + 12, 156 + by, 2.6, 2.6, trim)
    if ch.get('armor'):
        m = cv.mask()
        cv.mpoly(m, smooth([(cx - 11, 100 + by), (cx - 6, 88 + by), (cx + 8, 87 + by), (cx + 14, 98 + by), (cx + 9, 112 + by), (cx - 8, 114 + by)], 4))
        cv.paint(m, (172, 176, 196, 255), (96, 100, 132, 255), k=3, hi=(236, 240, 252, 255))
        cv.line([(cx - 8, 98 + by), (cx + 4, 90 + by), (cx + 12, 98 + by)], trim, 1.4)
    arm(near_arm_ang, True)



# ---------------------------------------------------------------- accessories & costume layers (drawn over the base body / head)
def arm_pts(ch, view, cx, P):
    """Approximate wrist/elbow positions used to hang bracers, canes and bags (matches body_front / body_side)."""
    by, s = P['bob'], P['s']
    sw = 29 * ch['sw']
    out = {}
    for sd in (-1, 1):
        out[sd] = (cx + sd * (sw + 3.0), 178 + by + s * 7 * (-sd))
    return out


def acc_body(cv, ch, view, cx, P):
    acc = ch.get('acc', [])
    if not acc:
        return
    by, s = P['bob'], P['s']
    sw = 29 * ch['sw']
    trim = hexc(ch['trim'])
    glow = hexc(ch['glow'])
    inn = hexc(ch['coat_in'])
    top = hexc(ch['top'])
    sk = skin_c(ch)
    W_ = arm_pts(ch, view, cx, P)
    front = view in ('front', 'back')
    if 'collar' in acc and front:      # popped high collar lined with the coat colour
        for sd in (-1, 1):
            m = cv.mask()
            cv.mpoly(m, smooth([(cx + sd * 6, 92 + by), (cx + sd * 17, 76 + by), (cx + sd * 21, 98 + by), (cx + sd * 10, 104 + by)], 4))
            cv.paint(m, top, shade_of(top, 0.5), k=2)
            cv.line([(cx + sd * 8, 94 + by), (cx + sd * 17, 80 + by)], inn, 1.6)
    if 'mantle' in acc:               # ornate shoulder mantle / shawl
        m = cv.mask()
        if front:
            cv.mpoly(m, smooth([(cx - sw - 5, 100 + by), (cx - sw * 0.6, 88 + by), (cx, 96 + by), (cx + sw * 0.6, 88 + by), (cx + sw + 5, 100 + by), (cx + sw - 2, 122 + by), (cx, 112 + by), (cx - sw + 2, 122 + by)], 5))
        else:
            cv.mpoly(m, smooth([(cx - 12, 92 + by), (cx + 12, 94 + by), (cx + 14, 120 + by), (cx - 12, 124 + by)], 4))
        cv.paint(m, inn, shade_of(inn, 0.45), k=2.4, rim=mix(glow, (0, 0, 0), 0.2))
        cv.line([(cx - sw - 3, 114 + by), (cx - 8, 116 + by), (cx + 8, 116 + by), (cx + sw + 3, 114 + by)] if front else [(cx - 12, 122 + by), (cx + 13, 118 + by)], trim, 1.6)
        for k in range(5 if front else 2):
            cv.fell(cx - 22 + k * 11 if front else cx - 4 + k * 8, 112 + by, 1.8, 1.8, trim)
    if 'epaulets' in acc and front:
        for sd in (-1, 1):
            m = cv.mask()
            cv.mpoly(m, smooth([(cx + sd * (sw - 12), 94 + by), (cx + sd * (sw + 6), 98 + by), (cx + sd * (sw + 8), 108 + by), (cx + sd * (sw - 10), 104 + by)], 4))
            cv.paint(m, shade_of(top, 0.1), shade_of(top, 0.5), k=2, rim=glow)
            cv.line([(cx + sd * (sw - 10), 100 + by), (cx + sd * (sw + 5), 103 + by)], trim, 1.6)
    if 'seams' in acc and front:      # glowing piping along the torso sides and the outer trouser seams
        for sd in (-1, 1):
            cv.line([(cx + sd * (sw * 0.72), 104 + by), (cx + sd * 21, 150 + by)], glow, 1.0)
            cv.line([(cx + sd * 21, 168 + by), (cx + sd * 22, 262 + by)], mix(glow, (0, 0, 0), 0.15), 0.9)
    if 'scarf' in acc:
        sc = trim
        m = cv.mask()
        if front:
            cv.mpoly(m, smooth([(cx - 16, 92 + by), (cx + 16, 92 + by), (cx + 15, 104 + by), (cx - 15, 104 + by)], 4))
            cv.paint(m, sc, shade_of(sc, 0.4), k=1.8)
            m2 = cv.mask()
            sway = s * 3
            cv.mpoly(m2, smooth([(cx + 8, 102 + by), (cx + 17, 102 + by), (cx + 20 + sway, 160 + by), (cx + 12 + sway, 168 + by)], 4))
            cv.paint(m2, sc, shade_of(sc, 0.4), k=1.8)
        elif view == 'back':
            cv.mpoly(m, smooth([(cx - 16, 92 + by), (cx + 16, 92 + by), (cx + 22, 100 + by), (cx + 12, 160 + by), (cx - 4, 150 + by)], 4))
            cv.paint(m, sc, shade_of(sc, 0.4), k=1.8)
        else:
            sway = s * 5
            cv.mpoly(m, smooth([(cx - 8, 92 + by), (cx + 8, 92 + by), (cx - 20 - sway, 118 + by), (cx - 36 - sway, 150 + by), (cx - 12, 130 + by)], 4))
            cv.paint(m, sc, shade_of(sc, 0.4), k=1.8)
    if 'bag' in acc:
        if front:
            cv.line([(cx - sw * 0.8, 98 + by), (cx + 14, 164 + by)], (30, 24, 34, 255), 2.6)
            cv.line([(cx - sw * 0.8, 98 + by), (cx + 14, 164 + by)], trim, 0.8)
            m = cv.mask()
            cv.mpoly(m, [(cx + 14, 160 + by), (cx + 36, 160 + by), (cx + 36, 186 + by), (cx + 14, 186 + by)])
            cv.paint(m, shade_of(top, 0.2), shade_of(top, 0.5), k=2, rim=glow)
            cv.line([(cx + 14, 168 + by), (cx + 36, 168 + by)], trim, 1.0)
        elif view == 'side':
            m = cv.mask()
            cv.mpoly(m, [(cx - 14, 150 + by), (cx + 8, 150 + by), (cx + 8, 178 + by), (cx - 14, 178 + by)])
            cv.paint(m, shade_of(top, 0.2), shade_of(top, 0.5), k=2)
    if 'pouches' in acc and front:
        for sd in (-1, 1):
            m = cv.mask()
            cv.mpoly(m, [(cx + sd * 18, 160 + by), (cx + sd * 32, 160 + by), (cx + sd * 32, 178 + by), (cx + sd * 18, 178 + by)])
            cv.paint(m, shade_of(top, 0.15), shade_of(top, 0.5), k=1.6)
            cv.line([(cx + sd * 18, 166 + by), (cx + sd * 32, 166 + by)], trim, 1.0)
    if 'bracers' in acc:
        for sd in (-1, 1):
            if view == 'side' and sd < 0:
                continue
            x, y = W_[sd]
            if view == 'side':
                x, y = cx + 4 + s * 9, 168 + by
            m = cv.mask()
            cv.mpoly(m, [(x - 7, y - 14), (x + 7, y - 14), (x + 6.5, y - 3), (x - 6.5, y - 3)])
            cv.paint(m, shade_of(top, 0.3), shade_of(top, 0.6), k=1.6, rim=glow)
            cv.line([(x - 6, y - 8), (x + 6, y - 8)], glow, 1.2)
    if 'cane' in acc and view != 'back':
        x, y = W_[1] if front else (cx + 8, 178 + by)
        cv.line([(x + 2, y + 8), (x + 5, 270)], (40, 30, 40, 255), 3.2)
        cv.line([(x + 2, y + 8), (x + 5, 270)], trim, 1.0)
        cv.fell(x + 2, y + 3, 4.2, 4.2, trim)
        cv.fell(x + 2, y + 3, 2.2, 2.2, glow)
    if 'sole_glow' in acc and front:
        for sd in (-1, 1):
            cv.line([(cx + sd * 11.5 - 9, 276 + by * 0), (cx + sd * 11.5 + 9, 276)], glow, 1.6)
    if 'headphones_neck' in acc and front:
        cv.line(smooth([(cx - 13, 96 + by), (cx, 108 + by), (cx + 13, 96 + by)], 5, False), (30, 24, 34, 255), 3.2)
        for sd in (-1, 1):
            cv.fell(cx + sd * 14, 98 + by, 5, 6, glow)
            cv.fell(cx + sd * 14, 98 + by, 3, 4, (30, 24, 34, 255))


def acc_head(cv, ch, view, cx, cy):
    acc = ch.get('acc', [])
    if not acc:
        return
    trim = hexc(ch['trim'])
    glow = hexc(ch['glow'])
    sk = skin_c(ch)
    hc = hexc(ch['hair_c'])
    ex = 9.6 + 0.6 * (ch['eyes'] - 1.0)
    if 'earrings' in acc:
        if view == 'front':
            for sd in (-1, 1):
                cv.line(smooth([(cx + sd * 22.4, cy + 7), (cx + sd * 25.5, cy + 11), (cx + sd * 22.4, cy + 15)], 5, False), trim, 1.3)
                cv.fell(cx + sd * 22.4, cy + 7, 1.6, 1.6, light_of(trim, 0.4))
        elif view == 'side':
            cv.line(smooth([(cx - 6, cy + 8), (cx - 9, cy + 12), (cx - 6, cy + 16)], 5, False), trim, 1.3)
        else:
            for sd in (-1, 1):
                cv.fell(cx + sd * 22.4, cy + 8, 1.6, 1.6, trim)
    if 'marks' in acc:
        if view == 'front':
            for k in range(3):
                cv.fell(cx - 12 + k * 3.2, cy + 8 + (k % 2) * 1.2, 0.9, 0.9, trim)
                cv.fell(cx + 12 - k * 3.2, cy + 8 + (k % 2) * 1.2, 0.9, 0.9, trim)
        elif view == 'side':
            for k in range(3):
                cv.fell(cx + 10 + k * 2.2, cy + 8 + (k % 2), 0.9, 0.9, trim)
    if 'scar' in acc and view in ('front', 'side'):
        if view == 'front':
            cv.line([(cx + ex - 3, cy - 14), (cx + ex + 5, cy + 6)], mix(sk, (255, 190, 170), 0.35), 1.2)
        else:
            cv.line([(cx + 8, cy - 8), (cx + 14, cy + 6)], mix(sk, (255, 190, 170), 0.35), 1.2)
    if 'freckles' in acc and view == 'front':
        for k in range(5):
            cv.fell(cx - 9 + k * 2.2, cy + 6 + (k % 2) * 1.3, 0.55, 0.55, skin_shade(sk, 0.55))
            cv.fell(cx + 9 - k * 2.2, cy + 6 + (k % 2) * 1.3, 0.55, 0.55, skin_shade(sk, 0.55))
    if 'lens' in acc:
        if view == 'front':
            cv.line(smooth([(cx + ex - 7.5, cy - 4), (cx + ex + 7.5, cy - 4), (cx + ex + 7.5, cy + 6), (cx + ex - 7.5, cy + 6)], 3, True), glow, 1.3)
            cv.fell(cx + ex, cy + 1, 7.6, 5.2, (glow[0], glow[1], glow[2], 55))
            cv.line([(cx + ex + 7.5, cy), (cx + 22, cy - 1)], glow, 1.0)
        elif view == 'side':
            cv.fell(cx + 12, cy, 6.5, 5.5, (glow[0], glow[1], glow[2], 70))
            cv.line([(cx + 12, cy - 5), (cx - 4, cy - 4)], glow, 1.0)
    if 'headphones' in acc:
        if view == 'front':
            cv.line(smooth([(cx - 24, cy - 2), (cx - 22, cy - 26), (cx, cy - 34), (cx + 22, cy - 26), (cx + 24, cy - 2)], 5, False), (30, 24, 34, 255), 3.0)
            for sd in (-1, 1):
                m = cv.mask()
                cv.mell(m, cx + sd * 24.5, cy + 4, 5.2, 8)
                cv.paint(m, (36, 30, 44, 255), (18, 14, 26, 255), k=1.6, rim=glow)
                cv.fell(cx + sd * 24.8, cy + 4, 2.4, 4, glow)
        elif view == 'side':
            cv.line(smooth([(cx - 6, cy - 4), (cx - 4, cy - 28), (cx + 10, cy - 26)], 5, False), (30, 24, 34, 255), 3.0)
            m = cv.mask()
            cv.mell(m, cx - 5, cy + 4, 5.6, 8)
            cv.paint(m, (36, 30, 44, 255), (18, 14, 26, 255), k=1.6, rim=glow)
            cv.fell(cx - 5, cy + 4, 2.6, 4, glow)
        else:
            cv.line(smooth([(cx - 24, cy - 2), (cx - 22, cy - 26), (cx, cy - 34), (cx + 22, cy - 26), (cx + 24, cy - 2)], 5, False), (30, 24, 34, 255), 3.0)
            for sd in (-1, 1):
                cv.fell(cx + sd * 24.5, cy + 4, 5, 7.5, (36, 30, 44, 255))
                cv.fell(cx + sd * 24.8, cy + 4, 2.4, 3.8, glow)
    if 'beads' in acc:
        rng = random.Random(5)
        if view == 'front':
            for sd in (-1, 1):
                for k in range(6):
                    cv.fell(cx + sd * (27 + (k % 2) * 1.2), cy + 6 + k * 8.5, 1.9, 1.9, trim if k % 2 == 0 else glow)
        elif view == 'side':
            for k in range(5):
                cv.fell(cx - 17 + (k % 2) * 3, cy + 8 + k * 9, 1.9, 1.9, trim if k % 2 == 0 else glow)
        else:
            for k in range(8):
                cv.fell(cx - 22 + k * 6.4, cy + 40 + (k % 3) * 8, 1.9, 1.9, trim if k % 2 == 0 else glow)
    if 'hair_pin' in acc and view in ('front', 'side'):
        cv.line([(cx + 12, cy - 28), (cx + 20, cy - 22)], trim, 1.6)
        cv.fell(cx + 20, cy - 22, 2.4, 2.4, glow)


# ---------------------------------------------------------------- render entry points
def render_frame(ch, view, phase, idle, ss=3):
    cv = Cv(W, H, ss)
    P = pose(view, phase, idle)
    cx = W / 2.0
    cy = 58.0 + P['bob'] + (0 if ch['h'] >= 1 else 0)
    if view == 'front':
        body_front(cv, ch, cx, P)
        acc_body(cv, ch, view, cx, P)
        cv.hk, cv.hc = HEAD_K, (cx, cy + 36)
        head_front(cv, ch, cx, cy, ch.get('expr', 0))
        acc_head(cv, ch, view, cx, cy)
    elif view == 'back':
        body_front(cv, ch, cx, P, back=True)
        acc_body(cv, ch, view, cx, P)
        cv.hk, cv.hc = HEAD_K, (cx, cy + 36)
        head_back(cv, ch, cx, cy)
        acc_head(cv, ch, view, cx, cy)
    else:
        body_side(cv, ch, cx, P)
        acc_body(cv, ch, view, cx, P)
        cv.hk, cv.hc = HEAD_K, (cx, cy + 36)
        head_side(cv, ch, cx, cy)
        acc_head(cv, ch, view, cx, cy)
    img = cv.out()
    # scale for character height (kids/tall), feet stay on the baseline
    hs = ch['h']
    if abs(hs - 1.0) > 0.005:
        nw, nh = int(W * hs), int(H * hs)
        sm = img.resize((nw, nh), Image.LANCZOS)
        out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        out.alpha_composite(sm, ((W - nw) // 2, H - 4 - (nh - 4)))
        img = out
    return img


def render_strip(ch, view, ss=3):
    frames = [render_frame(ch, view, 0.0, True, ss)] + [render_frame(ch, view, p, False, ss) for p in (0.0, 0.25, 0.5, 0.75)]
    strip = Image.new('RGBA', (W * len(frames), H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.alpha_composite(f, (i * W, 0))
    return strip


def render_portrait(ch, size=512, expr=0):
    ss = 2
    zoom = 6.0
    cx, cy = 96.0, 62.0
    cv = Cv(size, size, ss, zoom, cx - size / (2 * zoom), cy + 8.6 - size * 0.42 / zoom)
    cv.ow = max(3, int(round(1.2 * ss * zoom)))
    P = pose('front', 0, True)
    body_front(cv, ch, cx, P)
    acc_body(cv, ch, 'front', cx, P)
    cv.hk, cv.hc = HEAD_K, (cx, cy + 36)
    head_front(cv, ch, cx, cy, expr or ch.get('expr', 0))
    acc_head(cv, ch, 'front', cx, cy)
    return cv.out()


def sheet(names, out_png, view_set=('front', 'side', 'back')):
    pass


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else 'assets/demo25d/chars'
    names = [a for a in sys.argv[2:] if not a.startswith('--')] or list(CHARS)
    only_portraits = '--portraits' in sys.argv
    os.makedirs(out, exist_ok=True)
    for n in names:
        ch = CHARS[n]
        for v in ([] if only_portraits else ('front', 'side', 'back')):
            render_strip(ch, v).save(f'{out}/{n}_{v}.png')
        render_portrait(ch).save(f'{out}/{n}_portrait.png')
        print('rendered', n)
