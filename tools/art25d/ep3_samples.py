#!/usr/bin/env python3
"""Episode 3 REVIEW-ONLY character samples: Teo Marrow, Anselm Dray, the Relay Warden.

Procedural 2D art drawn in code with the project's existing renderer (tools/art25d/chargen.py: ink outline, 3-tone cel shading, upper-left light, cool rim) - no external
assets, no paid service, nothing imported into the game. Output goes to docs/episodes/episode-03/art_samples/ (a .gdignore keeps Godot from importing it).
Each character gets two directions (A, B). Teo A and Warden A are preferred concept directions only; nothing is approved. Run: python3 tools/art25d/ep3_samples.py [out_dir]
"""
import os, sys, math, random
sys.path.insert(0, os.path.dirname(__file__))
import chargen as c
from chargen import Cv, hexc, mix, shade_of, light_of
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

OUT = sys.argv[1] if len(sys.argv) > 1 else 'docs/episodes/episode-03/art_samples'
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
BG = (22, 25, 42, 255)

def font(sz, bold=False):
    try:
        return ImageFont.truetype(BOLD if bold else FONT, sz)
    except Exception:
        return ImageFont.load_default()

# ------------------------------------------------------------------ humans (chargen)
TEO_A = dict(acc=['collar', 'bracers', 'cane', 'pouches', 'seams'], expr=0, skin='brown', hair='locs', hair_c='ece9f2', hair_sh='a9a6bd', eye='8a5a26', outfit='coat', top='3a2c28',
             coat_in='c89a4a', trim='e8b878', pants='2a2420', boots='3a2e26', glasses=True, beard=True, brow=1.15, jaw=1.1, nose=1.05, lip=0.95, eyes=0.95, sw=1.05, h=1.06, glow='e8b878')
TEO_B = dict(TEO_A, hair='twists', outfit='jacket', top='2f3a3c', coat_in='e8b878', trim='d8a85a', acc=['collar', 'bracers', 'pouches', 'seams', 'sole_glow'], expr=1, sw=1.12, h=1.02, beard=True)
ANS_A = dict(acc=['collar', 'bracers', 'epaulets'], expr=2, skin='honey', hair='fade', hair_c='2a2230', hair_sh='140e1a', eye='5a4a3a', outfit='jacket', top='5a6072', coat_in='7c8498',
             trim='c0384a', pants='3c4152', boots='1c1c24', glasses=False, brow=1.2, jaw=1.15, nose=1.1, lip=0.8, eyes=0.85, sw=1.0, h=1.02, glow='9fb4d8')   # he/him: stronger brow and jaw, smaller eyes (the renderer has no gender switch; these are its masculine-coding sliders)
ANS_B = dict(ANS_A, outfit='coat', top='46506a', coat_in='9fb4d8', acc=['collar', 'bracers', 'epaulets'], glasses=True, expr=0, hair='fade', hair_c='3a3040')

def human_panel(ch, x_label):
    views = [c.render_frame(ch, v, 0, True).resize((216, 432), Image.LANCZOS) for v in ('front', 'side', 'back')]
    ports = [c.render_portrait(ch, 300, e) for e in (0, 1, 2)]
    img = Image.new('RGBA', (216 * 3 + 300 * 3 + 40, 470), BG)
    for i, v in enumerate(views):
        img.alpha_composite(v, (i * 216, 24))
    for i, p in enumerate(ports):
        img.alpha_composite(p, (216 * 3 + 40 + i * 300, 60))
    d = ImageDraw.Draw(img)
    for i, t in enumerate(('FRONT', 'SIDE', 'BACK')):
        d.text((i * 216 + 8, 4), t, fill=(150, 158, 190), font=font(12))
    for i, t in enumerate(('NEUTRAL', 'SPEAKING / WARY', 'WORRIED / DETERMINED')):
        d.text((216 * 3 + 48 + i * 300, 40), t, fill=(150, 158, 190), font=font(12))
    return img

# ------------------------------------------------------------------ the Relay Warden (custom construct, drawn with the same Cv primitives)
PAL = dict(iron='2b2540', plate='3d3556', plate_hi='5a4f7a', brass='b8924a', brass_dk='7a5c2a', verdigris='4a8c86', white='f2f6ff', dark='15121f')

def glow_layer(size, items, blur):
    """items: (kind, args, color) drawn on a transparent layer, blurred = bloom."""
    lay = Image.new('RGBA', size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for kind, a, col in items:
        if kind == 'e':
            d.ellipse(a, fill=col)
        elif kind == 'p':
            d.polygon(a, fill=col)
        elif kind == 'l':
            d.line(a, fill=col, width=int(a_w(col)))
    return lay.filter(ImageFilter.GaussianBlur(blur))

def a_w(col):
    return 6

def warden(design, state, W=360, H=560, ss=3, seed=7):
    rnd = random.Random(seed)
    ok = state == 'restored'
    acc = hexc('6fd7e4') if ok else hexc('ff4d63')
    acc_soft = mix(acc, (255, 255, 255), 0.55)
    cv = Cv(W, H, ss)
    cx = W / 2
    iron, plate, hi = hexc(PAL['iron']), hexc(PAL['plate']), hexc(PAL['plate_hi'])
    brass, brass_dk, vd = hexc(PAL['brass']), hexc(PAL['brass_dk']), hexc(PAL['verdigris'])
    if not ok:
        plate = mix(plate, (60, 20, 30), 0.25)
    glows = []   # bloom items (final-pixel coordinates, scaled below)

    def P(m, base, shadow=None, **kw):
        cv.paint(m, base, shadow, **kw)

    if design == 'A':
        # ---- A: the Lamp Guardian (tall humanoid sentinel, plate coat, lamp head, bell chest, valve shoulder, seal back-disc)
        # legs and boots
        for sd in (-1, 1):
            m = cv.mask(); cv.mpoly(m, [(cx + sd * 18, 392), (cx + sd * 52, 392), (cx + sd * 56, 520), (cx + sd * 14, 520)]); P(m, iron, rim=hi)
            m = cv.mask(); cv.mpoly(m, [(cx + sd * 10, 514), (cx + sd * 62, 514), (cx + sd * 72, 540), (cx + sd * 6, 540)]); P(m, plate, rim=hi)
            cv.line([(cx + sd * 16, 500), (cx + sd * 56, 500)], brass, 3)
        # long plate coat (the conductor's / keeper's coat of steel plates), vertical seams
        m = cv.mask(); cv.mpoly(m, [(cx - 62, 318), (cx + 62, 318), (cx + 104, 486), (cx + 70, 500), (cx, 492), (cx - 70, 500), (cx - 104, 486)]); P(m, plate, rim=hi)
        for i in range(-3, 4):
            cv.line([(cx + i * 15, 330), (cx + i * 26, 484)], mix(plate, (0, 0, 0), 0.45), 1.6)
        cv.line([(cx - 100, 480), (cx - 66, 494), (cx, 487), (cx + 66, 494), (cx + 100, 480)], brass, 3)
        # torso
        m = cv.mask(); cv.mpoly(m, [(cx - 88, 186), (cx + 88, 186), (cx + 66, 322), (cx - 66, 322)]); P(m, iron, rim=hi)
        for i in range(3):
            cv.line([(cx - 74 + i * 4, 208 + i * 38), (cx + 74 - i * 4, 208 + i * 38)], mix(iron, (0, 0, 0), 0.5), 2)
        # BELL: the chest bell (the second mechanism), clapper glows
        m = cv.mask(); cv.mpoly(m, c.smooth([(cx - 18, 214), (cx + 18, 214), (cx + 30, 262), (cx + 46, 308), (cx - 46, 308), (cx - 30, 262)], 6)); P(m, brass, shade_of(brass, 0.5), rim=light_of(brass, 0.5), hi=light_of(brass, 0.35))
        cv.line([(cx - 44, 304), (cx + 44, 304)], brass_dk, 3)
        cv.fell(cx, 314, 10, 10, acc)
        glows.append(('e', (cx - 14, 300, cx + 14, 328), acc))
        # shoulders
        for sd in (-1, 1):
            m = cv.mask(); cv.mell(m, cx + sd * 98, 206, 40, 34); P(m, plate, rim=hi)
            cv.line([(cx + sd * 66, 196), (cx + sd * 128, 214)], brass, 3)
        # VALVE: hand-wheel on the right pauldron (the first mechanism)
        vx, vy = cx + 104, 190
        cv.line([(vx - 0, vy - 0), (vx, vy)], brass, 2)
        for k in range(8):
            a = k * math.pi / 4
            cv.line([(vx, vy), (vx + math.cos(a) * 26, vy + math.sin(a) * 26)], brass, 3)
        for k in range(24):
            a0, a1 = k * math.pi / 12, (k + 1) * math.pi / 12
            cv.line([(vx + math.cos(a0) * 26, vy + math.sin(a0) * 26), (vx + math.cos(a1) * 26, vy + math.sin(a1) * 26)], brass, 3.4)
        cv.fell(vx, vy, 6, 6, vd)
        # arms with rail-clamp hands
        for sd in (-1, 1):
            m = cv.mask(); cv.mlimb(m, (cx + sd * 112, 232), (cx + sd * 124, 330), 26, 22); P(m, iron, rim=hi)
            m = cv.mask(); cv.mlimb(m, (cx + sd * 124, 330), (cx + sd * 120, 396), 22, 20); P(m, plate, rim=hi)
            for prong in (-1, 1):
                m = cv.mask(); cv.mpoly(m, [(cx + sd * 120 + prong * 4, 392), (cx + sd * 120 + prong * 16, 392), (cx + sd * 120 + prong * 10, 430), (cx + sd * 120 + prong * 5, 430)]); P(m, brass_dk, rim=brass)
        # neck + gorget
        m = cv.mask(); cv.mpoly(m, [(cx - 30, 160), (cx + 30, 160), (cx + 44, 196), (cx - 44, 196)]); P(m, plate, rim=hi)
        cv.line([(cx - 38, 186), (cx + 38, 186)], brass, 2.4)
        # lamp head: hexagonal signal-lamp housing, crown fins, glass lens (the Warden's light), SEAL disc on the crown
        for k, (dx, h2) in enumerate(((-30, 30), (-16, 46), (0, 56), (16, 46), (30, 30))):
            m = cv.mask(); cv.mpoly(m, [(cx + dx - 4, 70), (cx + dx + 4, 70), (cx + dx + 2, 70 - h2), (cx + dx - 2, 70 - h2)]); P(m, brass_dk, rim=brass, ink=True)
        m = cv.mask(); cv.mpoly(m, [(cx - 36, 70), (cx + 36, 70), (cx + 46, 160), (cx - 46, 160)]); P(m, plate, shade_of(plate, 0.5), rim=hi)
        m = cv.mask(); cv.mpoly(m, [(cx - 30, 78), (cx + 30, 78), (cx + 37, 150), (cx - 37, 150)]); P(m, iron)
        lens = [(cx - 15, 84), (cx + 15, 84), (cx + 19, 120), (cx + 14, 148), (cx - 14, 148), (cx - 19, 120)]
        m = cv.mask(); cv.mpoly(m, c.smooth(lens, 5)); P(m, acc, mix(acc, (0, 0, 0), 0.35), rim=acc_soft, hi=acc_soft)
        cv.line([(cx, 86), (cx, 146)], mix(acc, (255, 255, 255), 0.8), 2)
        glows.append(('e', (cx - 30, 80, cx + 30, 150), acc))
        cv.line([(cx - 40, 74), (cx + 40, 74)], brass, 3.2)
        cv.line([(cx - 44, 158), (cx + 44, 158)], brass, 3.2)
        # SEAL: a disc with a cross-seal rune on the lamp crown (the third mechanism)
        cv.fell(cx, 34, 13, 13, brass_dk); cv.fell(cx, 34, 10, 10, iron)
        cv.line([(cx - 7, 34), (cx + 7, 34)], acc, 2); cv.line([(cx, 27), (cx, 41)], acc, 2)
        glows.append(('e', (cx - 12, 22, cx + 12, 46), acc))
        if not ok:
            # corrupted: hanging cut cables, cracked plates, red static slices
            for k in range(5):
                x = cx - 70 + k * 35 + rnd.randint(-6, 6)
                pts = [(x, 322), (x + rnd.randint(-10, 10), 352), (x + rnd.randint(-14, 14), 388 + rnd.randint(0, 24))]
                cv.line(pts, mix(iron, (0, 0, 0), 0.3), 3)
                cv.fell(pts[-1][0], pts[-1][1], 3.5, 3.5, acc)
            for pts in ([(cx - 60, 220), (cx - 44, 246), (cx - 52, 262)], [(cx + 56, 238), (cx + 40, 270), (cx + 52, 290)], [(cx - 20, 380), (cx - 6, 420), (cx - 16, 450)]):
                cv.line(pts, acc, 2.2)
                glows.append(('l', [(p[0], p[1]) for p in pts], acc))
        else:
            # restored: a thin steady halo ring behind the lamp and brass polished (no cracks, no cables)
            cv.line([(cx - 52, 40), (cx - 26, 8), (cx + 26, 8), (cx + 52, 40)], acc_soft, 2.2)
    else:
        # ---- B: the Bell-Tower Sentinel (monolithic bell body, floating lamp head and clamp hands, three seal rings)
        m = cv.mask(); cv.mpoly(m, c.smooth([(cx - 26, 190), (cx + 26, 190), (cx + 44, 270), (cx + 86, 380), (cx + 112, 482), (cx - 112, 482), (cx - 86, 380), (cx - 44, 270)], 7)); P(m, plate, shade_of(plate, 0.5), rim=hi)
        m = cv.mask(); cv.mpoly(m, [(cx - 118, 480), (cx + 118, 480), (cx + 126, 516), (cx - 126, 516)]); P(m, brass_dk, rim=brass)
        cv.line([(cx - 112, 490), (cx + 112, 490)], brass, 3)
        for i in range(-3, 4):
            cv.line([(cx + i * 12, 200), (cx + i * 28, 478)], mix(plate, (0, 0, 0), 0.4), 1.5)
        # VALVE wheel embedded high on the bell, SEAL disc on the lower body, the bell mouth is the BELL
        vx, vy = cx, 262
        for k in range(8):
            a = k * math.pi / 4
            cv.line([(vx, vy), (vx + math.cos(a) * 30, vy + math.sin(a) * 30)], brass, 3)
        for k in range(24):
            a0, a1 = k * math.pi / 12, (k + 1) * math.pi / 12
            cv.line([(vx + math.cos(a0) * 30, vy + math.sin(a0) * 30), (vx + math.cos(a1) * 30, vy + math.sin(a1) * 30)], brass, 3.4)
        cv.fell(vx, vy, 7, 7, vd)
        cv.fell(cx, 404, 26, 26, brass_dk); cv.fell(cx, 404, 21, 21, iron)
        cv.line([(cx - 14, 404), (cx + 14, 404)], acc, 2.6); cv.line([(cx, 390), (cx, 418)], acc, 2.6)
        glows.append(('e', (cx - 22, 382, cx + 22, 426), acc))
        m = cv.mask(); cv.mell(m, cx, 482, 62, 12); P(m, iron)
        cv.fell(cx, 486, 11, 11, acc)
        glows.append(('e', (cx - 12, 474, cx + 12, 498), acc))
        # floating lamp head
        m = cv.mask(); cv.mpoly(m, [(cx - 40, 92), (cx + 40, 92), (cx + 50, 170), (cx - 50, 170)]); P(m, plate, shade_of(plate, 0.5), rim=hi)
        m = cv.mask(); cv.mpoly(m, [(cx - 32, 100), (cx + 32, 100), (cx + 40, 162), (cx - 40, 162)]); P(m, iron)
        m = cv.mask(); cv.mpoly(m, c.smooth([(cx - 18, 106), (cx + 18, 106), (cx + 22, 134), (cx + 15, 158), (cx - 15, 158), (cx - 22, 134)], 5)); P(m, acc, mix(acc, (0, 0, 0), 0.35), rim=acc_soft, hi=acc_soft)
        cv.line([(cx, 110), (cx, 154)], mix(acc, (255, 255, 255), 0.8), 2)
        glows.append(('e', (cx - 34, 102, cx + 34, 162), acc))
        cv.line([(cx - 46, 94), (cx + 46, 94)], brass, 3.4); cv.line([(cx - 52, 168), (cx + 52, 168)], brass, 3.4)
        for dx in (-26, -9, 9, 26):
            m = cv.mask(); cv.mpoly(m, [(cx + dx - 3, 92), (cx + dx + 3, 92), (cx + dx + 1, 56 - abs(dx) * 0.4), (cx + dx - 1, 56 - abs(dx) * 0.4)]); P(m, brass_dk, rim=brass)
        # floating clamp hands
        for sd in (-1, 1):
            hx, hy = cx + sd * 150, 300 + (14 if not ok else 0) * sd
            m = cv.mask(); cv.mell(m, hx, hy, 24, 20); P(m, plate, rim=hi)
            for prong in (-1, 1):
                m = cv.mask(); cv.mpoly(m, [(hx + prong * 6, hy + 14), (hx + prong * 15, hy + 14), (hx + prong * 11, hy + 52), (hx + prong * 6, hy + 52)]); P(m, brass_dk, rim=brass)
            cv.line([(hx, hy - 20), (hx - sd * 24, 214)], mix(iron, (0, 0, 0), 0.2), 3)
        # seal rings orbiting the body: aligned and calm when restored, broken and tilted when corrupted
        for i, (rx, ry, y0) in enumerate(((120, 26, 330), (96, 20, 292), (72, 15, 256))):
            segs = 18
            for k in range(segs):
                if not ok and rnd.random() < 0.3:
                    continue
                a0, a1 = k * 2 * math.pi / segs, (k + 0.8) * 2 * math.pi / segs
                jit = 0 if ok else rnd.randint(-5, 5)
                pts = [(cx + math.cos(a) * rx, y0 + jit + math.sin(a) * ry) for a in (a0, (a0 + a1) / 2, a1)]
                cv.line(pts, acc if ok else acc, 2.2)
        if not ok:
            for pts in ([(cx - 30, 300), (cx - 22, 340), (cx - 34, 372)], [(cx + 40, 330), (cx + 30, 380), (cx + 44, 420)]):
                cv.line(pts, acc, 2.2)
                glows.append(('l', [(p[0], p[1]) for p in pts], acc))
    img = cv.out()
    # bloom on emissive parts only
    items = [(k, tuple(v * 1 for v in a) if k == 'e' else a, col) for k, a, col in glows]
    lay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for kind, a, col in items:
        if kind == 'e':
            d.ellipse(a, fill=col[:3] + (200,))
        else:
            d.line(a, fill=col[:3] + (200,), width=5)
    bloom = lay.filter(ImageFilter.GaussianBlur(9))
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    out.alpha_composite(bloom)
    out.alpha_composite(img)
    out.alpha_composite(lay.filter(ImageFilter.GaussianBlur(2)))
    if not ok:   # glitch: a few horizontal slices shifted sideways
        rr = random.Random(seed + 3)
        for _ in range(5):
            y = rr.randint(60, 500); h = rr.randint(6, 14); dx = rr.randint(-9, 9)
            strip = out.crop((0, y, W, y + h))
            out.paste((0, 0, 0, 0), (0, y, W, y + h))
            out.alpha_composite(strip, (dx, y))
    return out

def warden_panel(design):
    img = Image.new('RGBA', (360 * 2 + 40, 580), BG)
    for i, st in enumerate(('corrupted', 'restored')):
        img.alpha_composite(warden(design, st), (i * (360 + 40), 10))
        d = ImageDraw.Draw(img)
        d.text((i * 400 + 10, 4), 'CORRUPTED  /  as met in the chamber' if st == 'corrupted' else 'RESTORED  /  after the SEAL', fill=(150, 158, 190), font=font(12))
    return img

# ------------------------------------------------------------------ sheets
def wrap(d, text, f, width):
    words, lines, cur = text.split(), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if d.textlength(t, font=f) > width and cur:
            lines.append(cur); cur = w
        else:
            cur = t
    lines.append(cur)
    return lines

def sheet(title, sub, panels, notes, palette, fname, width=1700):
    pad = 24
    heights = [p[1].height + 56 for p in panels]
    notes_h = 40 + 22 * sum(len(wrap(ImageDraw.Draw(Image.new('RGB', (10, 10))), n, font(14), width - 2 * pad)) for n in notes) + 80
    img = Image.new('RGBA', (width, 120 + sum(heights) + notes_h), BG)
    d = ImageDraw.Draw(img)
    d.text((pad, 18), title, fill=(255, 255, 255), font=font(30, True))
    d.text((pad, 62), sub, fill=(255, 214, 140), font=font(15))
    d.text((pad, 88), 'REVIEW ONLY  -  procedural concept sample, NOT integrated, NOT final painted art, no paid service used', fill=(255, 120, 140), font=font(13, True))
    y = 120
    for (label, pimg), h in zip(panels, heights):
        d.text((pad, y + 6), label, fill=(255, 214, 140), font=font(17, True))
        img.alpha_composite(pimg, (pad, y + 36))
        y += h
    for i, (name, hexv) in enumerate(palette):
        d.rectangle([pad + i * 170, y + 4, pad + i * 170 + 28, y + 32], fill=hexc(hexv), outline=(230, 230, 240))
        d.text((pad + i * 170 + 36, y + 9), f'{name} #{hexv}', fill=(200, 205, 225), font=font(12))
    y += 54
    for n in notes:
        for ln in wrap(d, n, font(14), width - 2 * pad):
            d.text((pad, y), ln, fill=(205, 210, 230), font=font(14)); y += 22
        y += 6
    img.convert('RGB').save(os.path.join(OUT, fname))
    return img

def main():
    os.makedirs(OUT, exist_ok=True)
    teo = sheet('TEO MARROW  /  THE RELAY KEEPER', 'Sample sheet  -  story: STORY_PLAN.md sec. 3 (cautious, eventually an ally); in-game accent e8b878',
                [('A  /  PREFERRED CONCEPT DIRECTION (not approved)   long white locs, brass-trimmed long coat, rail-spike cane, round spectacles (amber lens tint not yet rendered)', human_panel(TEO_A, 'A')),
                 ('B  /  ALTERNATE   shorter white twists, work jacket with brass lantern fittings, no cane', human_panel(TEO_B, 'B'))],
                ['Grounding: the plan calls Teo the Relay Keeper who understands the abandoned network, initially cautious, eventually an ally; the game text has him keeping the network alive from a workshop behind the alleyways and wary of anyone who looks like Meridian; his dialogue colour is amber e8b878. The earlier (superseded) Episode 3 proposal described him as tall and weathered, in a long coat with brass lantern fittings, round amber-lens spectacles, braided white hair and a rail-spike cane. Those details are a hint, not an approved design; A leans on them, B tests a plainer work look.',
                 'Palette follows the approved style: near-black base, one saturated accent (amber/brass), small luminous areas. Known limits of this renderer: spectacle lenses are drawn pale (the amber tint is not rendered yet), hands are mitten-simple, and expressions differ only slightly. A hand-painted portrait set would be needed for final art (see VISUAL_DIRECTION_PROPOSAL.md option D).'],
                [('base', '3a2c28'), ('coat', '2f3a3c'), ('brass', 'c89a4a'), ('accent', 'e8b878'), ('hair', 'ece9f2'), ('skin', '70482f')], 'teo_marrow_samples.png')
    ans = sheet('ANSELM DRAY  /  FORMER REGISTRY CLERK', 'Sample sheet (revised: he/him)  -  story: STORY_PLAN.md sec. 3; in-game accent 9fb4d8; direction chosen: A (a direction choice only, not approval of final art or integration)',
                [('A  /  PREFERRED CONCEPT DIRECTION (not approved)   neat grey Meridian clerk jacket and trousers, crimson registry armband trim, anxious', human_panel(ANS_A, 'A')),
                 ('B  /  ALTERNATE (not chosen)   slate-blue registry overcoat, round spectacles, composed', human_panel(ANS_B, 'B'))],
                ['Revision: Anselm is he/him (the in-game Codex text says "He could not."). The first sheet read as ambiguous or feminine because the renderer has no gender switch and the suit template draws a skirt-like lower body; both options now use a jacket-and-trousers silhouette and stronger brow, jaw and nose sliders with smaller eyes and a thinner mouth. Grounding: the plan calls Anselm a former Meridian registry clerk who conceals evidence of falsified and unusually old Ascendant records; the game text has him ordered to burn the old registry and unable to, hiding at the Transit Station, anxious and a rule-follower who slowly questions the rules; his dialogue colour is pale blue-grey 9fb4d8. The earlier (superseded) proposal gave him a neat grey uniform, a Meridian-crimson registry armband and ink-stained fingers. Treated as a hint, not approved. Meridian crimson also reads as the Enforcer accent, which is intended: he still wears the institution.',
                 'Known limits: ink-stained fingers are not visible at this resolution; both options are recoloured templates; the faces keep the renderer soft style, so he/him reads mainly from the silhouette, brow and jaw, and a painted portrait would settle it; expressions differ only slightly.'],
                [('uniform', '5a6072'), ('overcoat (B)', '46506a'), ('armband', 'c0384a'), ('accent', '9fb4d8'), ('hair', '2a2230'), ('skin', 'b27d52')], 'anselm_dray_samples.png')
    wa = sheet('THE RELAY WARDEN', 'Sample sheet  -  story: STORY_PLAN.md sec. 3 and 8; M4 arena; in-game accent 6fd7e4 (restored) / signal red (corrupted)',
               [('A  /  PREFERRED CONCEPT DIRECTION (not approved)   the Lamp Guardian: tall sentinel, plate coat, lamp-lens head, bell chest, valve wheel shoulder, seal disc crown', warden_panel('A')),
                ('B  /  ALTERNATE   the Bell-Tower Sentinel: bell-shaped body, floating lamp head and clamp hands, three seal rings', warden_panel('B'))],
               ['Grounding: the plan calls the Warden an ancient guardian protecting the Central Relay whose original purpose has been corrupted; the fight restores it instead of destroying it (sec. 8): the player wakes three mechanisms in order (VALVE, BELL, SEAL), and in the game text its light flickers, steadies and finds Echo, and its first instruction was to keep, never to choose. So both designs carry the three mechanisms on the body (valve wheel, bell, seal disc) and a single lamp-lens eye, and each is drawn in the two states the player sees: corrupted (signal red, cut cables or broken rings, glitch slices) and restored (steady cyan, intact). The earlier superseded proposal described a Meridian tram construct (signal-lamp head, rail-clamp arms, steel-plate conductor coat); the lamp head and clamp hands are kept, the tram theme is not, because the official plan makes it an ancient guardian.',
                'Distinct from the existing bosses: Hollow Cantor (halo, porcelain mask), Shade (cloak), Enforcer (flame). Palette: indigo iron, aged brass, one accent (cyan restored / red corrupted). Known limits: this is a drawn-in-code front view only, no side/back, no animation frames, no attack poses; the game currently shows the Warden as the scaled, tinted pedestrian rig, so an approved design would also need a 64-frame-style sprite set (like the Cantor) before it could replace that.'],
               [('iron', '2b2540'), ('plate', '3d3556'), ('brass', 'b8924a'), ('verdigris', '4a8c86'), ('restored', '6fd7e4'), ('corrupted', 'ff4d63')], 'relay_warden_samples.png')
    # overview contact sheet
    ov = Image.new('RGB', (1700, 1010), BG[:3])
    d = ImageDraw.Draw(ov)
    d.text((24, 14), 'EPISODE 3 CHARACTER SAMPLES  /  REVIEW ONLY', fill=(255, 255, 255), font=font(28, True))
    d.text((24, 54), 'Teo Marrow, Anselm Dray, the Relay Warden. Teo A and Warden A are preferred concept directions only (not approved); Anselm A/B await a choice. Not integrated. Procedural concept art, no paid service.', fill=(255, 214, 140), font=font(15))
    x = 24
    for ch, lab in ((TEO_A, 'TEO  A'), (TEO_B, 'TEO  B'), (ANS_A, 'ANSELM  A'), (ANS_B, 'ANSELM  B')):
        f = c.render_frame(ch, 'front', 0, True).resize((216, 432), Image.LANCZOS)
        ov.paste(f, (x, 100), f); d.text((x + 50, 540), lab, fill=(200, 205, 225), font=font(14)); x += 230
    x = 24
    for dsg, st in (('A', 'corrupted'), ('A', 'restored'), ('B', 'corrupted'), ('B', 'restored')):
        w = warden(dsg, st).resize((300, 467), Image.LANCZOS)
        ov.paste(w, (x, 540), w); d.text((x + 40, 1000 - 22), f'WARDEN {dsg}  {st}', fill=(200, 205, 225), font=font(14)); x += 420
    ov.save(os.path.join(OUT, 'overview.png'))
    print('wrote', [f for f in os.listdir(OUT) if f.endswith('.png')])

if __name__ == '__main__':
    main()
