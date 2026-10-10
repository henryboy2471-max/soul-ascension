#!/usr/bin/env python3
"""Concept comparison sheets for the NPC cast redesign: BEFORE (first placeholder pass) / A (recommended) / B (alternate direction).
Run after chargen: python3 tools/art25d/concepts.py docs/demo25d"""
import os, sys, copy
sys.path.insert(0, os.path.dirname(__file__))
import chargen as c
from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else 'docs/demo25d'
BEFORE = os.path.join(OUT, 'before')

# Alternate (B) directions: bolder silhouettes / palettes while keeping each character's identity
B = {
    'kofi': dict(hair='afro', outfit='vest', top='1f5a4a', coat_in='f0a040', trim='ffb040', glow='5af0c0', acc=['bracers', 'earrings', 'scar', 'sole_glow'], expr=1),
    'imani': dict(hair='braids', hair_c='3a2418', hair_sh='1a0e08', outfit='jacket', top='2a4a6a', coat_in='ffc060', trim='ffc060', pants='1f2a3a', acc=['pouches', 'bracers', 'seams', 'earrings'], expr=2),
    'adaeze': dict(hair='locs', hair_c='cfcfe0', hair_sh='8a8aa0', top='1f6a6a', coat_in='e0c060', trim='f6d070', pants='1f6a6a', acc=['mantle', 'earrings', 'cane', 'marks'], expr=1),
    'zuri': dict(hair='bantu', top='7a4ad8', coat_in='ffffff', trim='ff7ac0', glow='7a4ad8', acc=['headphones_neck', 'beads', 'sole_glow', 'freckles'], expr=1),
    'okoye': dict(hair='fade', hair_c='140f12', hair_sh='0a0709', outfit='jacket', top='1a2a50', coat_in='ff5a6a', trim='ff5a6a', glow='ff5a6a', acc=['lens', 'epaulets', 'seams', 'collar'], expr=0, glasses=False),
    'ngozi': dict(hair='braids', hair_c='1c0f12', hair_sh='0a0507', top='e0702a', coat_in='2a7a5a', trim='ffd070', acc=['mantle', 'earrings', 'marks'], expr=1),
    'tunde': dict(hair='locs', hair_c='1a0f0a', hair_sh='0a0604', top='2a7a6a', glow='7affc0', acc=['headphones', 'bracers', 'sole_glow', 'seams'], expr=1),
    'sade': dict(hair='afro', hair_c='1c120e', top='7a3ad0', coat_in='ffe080', trim='ffe080', glow='ffd060', acc=['earrings', 'bag', 'sole_glow', 'marks'], expr=1),
    'bayo': dict(hair='twists', hair_c='e0a040', hair_sh='9a6a20', top='1a1a2a', coat_in='f09a4a', trim='f09a4a', glow='ff9a4a', acc=['bag', 'sole_glow', 'earrings'], expr=2),
    'musa': dict(hair='fade', hair_c='140f12', hair_sh='0a0709', outfit='coat', top='3a2a2a', coat_in='ff6a4a', trim='ff6a4a', acc=['scar', 'bracers', 'epaulets', 'sole_glow', 'collar'], expr=0),
}
NOTES = {
    'kofi': ("Kofi, noodle-stall owner", "A: broad, warm, fade + full beard, bib apron, gold stud, ember-orange glow. B: short afro, green work vest, teal glow, scar for a past."),
    'imani': ("Imani, tram mechanic", "A: shoulder-length locs, goggles up, cyan-seamed overalls, tool pouches. B: long braids, tailored jacket with gold trim."),
    'adaeze': ("Mama Adaeze, elder", "A: gold-edged purple mantle over robe, braids, glowing cane. B: silver locs, deep-teal robe, same cane and mantle."),
    'zuri': ("Zuri, street kid", "A: two puffs with beads, pink hoodie, headphones, light-up sneakers. B: bantu knots and electric-violet hoodie."),
    'okoye': ("Officer Okoye", "A: bald, tactical glasses plus a glowing blue lens, epaulets, popped collar. B: fade cut, navy jacket with red-glow trim, no glasses."),
    'ngozi': ("Ngozi, Noodle House owner", "A: gele headwrap, ornate gold mantle, cheek marks. B: long gold-tipped braids, burnt-orange outfit with green lining."),
    'tunde': ("Tunde, courier", "A: full afro, green jacket, over-ear headphones, wrist tech. B: shoulder locs, teal jacket, mint glow accents."),
    'sade': ("Sade, designer", "A: bantu knots, sunshine jacket, cross-body bag. B: big afro, violet jacket with gold lining."),
    'bayo': ("Bayo, arcade regular", "A: sharp fade, indigo hoodie, bag, smirk. B: bleach-amber twists, black jacket with orange lining."),
    'musa': ("Musa, dock guard", "A: heavy build, locs with beads, scar, vest and bracers. B: fade, long dark coat with ember-red lining."),
}

def variant(name):
    ch = copy.deepcopy(c.CHARS[name])
    ch.update(B[name])
    return ch

def label(d, xy, text, size=15, fill=(230, 232, 250)):
    try:
        f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', size)
    except Exception:
        f = ImageFont.load_default()
    d.text(xy, text, fill=fill, font=f)

def panel(name):
    A = c.CHARS[name]
    h = 330
    img = Image.new('RGBA', (1500, h), (26, 30, 48, 255))
    d = ImageDraw.Draw(img)
    cols = [('BEFORE (first placeholder pass)', None), ('A  /  RECOMMENDED', A), ('B  /  ALTERNATE', variant(name))]
    for i, (title, ch) in enumerate(cols):
        x0 = i * 500
        label(d, (x0 + 12, 8), title, 15, (255, 214, 140) if i == 1 else (170, 178, 205))
        if ch is None:
            body = Image.open(os.path.join(BEFORE, f'{name}_front_idle.png')).convert('RGBA')
            port = Image.open(os.path.join(BEFORE, f'{name}_portrait.png')).convert('RGBA')
        else:
            body = c.render_frame(ch, 'front', 0, True)
            port = c.render_portrait(ch, 512)
        img.alpha_composite(body.resize((168, 336)).crop((0, 0, 168, 304)), (x0 + 8, 30))
        img.alpha_composite(port.resize((256, 256)), (x0 + 190, 40))
    t, note = NOTES[name]
    label(d, (14, h - 24), t + '  -  ' + note, 13)
    return img

if __name__ == '__main__':
    names = sys.argv[2:] or list(NOTES)
    os.makedirs(OUT, exist_ok=True)
    panels = [panel(n) for n in names]
    per = 5
    for pg in range(0, len(panels), per):
        chunk = panels[pg:pg + per]
        sheet = Image.new('RGBA', (1500, 330 * len(chunk)), (20, 22, 36, 255))
        for i, pnl in enumerate(chunk):
            sheet.alpha_composite(pnl, (0, i * 330))
        sheet.convert('RGB').save(os.path.join(OUT, f'npc_redesign_{pg // per + 1}.png'))
        print('wrote page', pg // per + 1)
