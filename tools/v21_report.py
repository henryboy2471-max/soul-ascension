#!/usr/bin/env python3
"""v2 vs v2.1 report: mobile-viewport lineups (from the in-engine 1280x720 captures), native close-ups, file-size / texture-memory metrics.
Usage: python3 tools/v21_report.py DOCS_DIR"""
import sys, os, glob, json
import numpy as np
from PIL import Image
D = sys.argv[1]
V = {"v2": "assets/enemies/hollow_cantor_v2", "v2.1": "assets/enemies/hollow_cantor"}
for ph in (1, 2):
    src = Image.open(os.path.join(D, "lineup_phase%d_1280x720.png" % ph)).convert("RGB")
    for (w, h) in ((844, 390), (667, 375)):
        k = min(w / 1280, h / 720)           # canvas_items stretch: the 1280x720 scene is scaled to fit the short side
        im = src.resize((int(1280 * k), int(720 * k)), Image.LANCZOS)
        canvas = Image.new("RGB", (w, h), (0, 0, 0))
        canvas.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
        canvas.save(os.path.join(D, "lineup_phase%d_%dx%d.png" % (ph, w, h)))
        canvas.resize((w * 2, h * 2), Image.NEAREST).save(os.path.join(D, "lineup_phase%d_%dx%d_shown_2x.png" % (ph, w, h)))
def closeup(paths, out, labels=None):
    ims = [Image.open(p).convert("RGBA") for p in paths]
    Hh = max(i.height for i in ims)
    sheet = Image.new("RGBA", (sum(i.width for i in ims) + 10 * (len(ims) + 1), Hh + 20), (30, 18, 64, 255))
    x = 10
    for i in ims:
        sheet.alpha_composite(i, (x, 10 + Hh - i.height)); x += i.width + 10
    sheet.convert("RGB").save(out)
closeup([V["v2"] + "/frames/idle_00.png", V["v2.1"] + "/frames/idle_00.png", V["v2"] + "/phase2/frames/idle_00.png", V["v2.1"] + "/phase2/frames/idle_00.png"], os.path.join(D, "closeup_v2_vs_v21_idle.png"))
closeup([V["v2"] + "/frames/attack1_04.png", V["v2.1"] + "/frames/attack1_04.png", V["v2"] + "/phase2/frames/attack1_04.png", V["v2.1"] + "/phase2/frames/attack1_04.png"], os.path.join(D, "closeup_v2_vs_v21_attack.png"))
# face close-up (idle_00, 3x on the head)
def face(path):
    im = Image.open(path).convert("RGBA"); bg = Image.new("RGBA", im.size, (30, 18, 64, 255)); bg.alpha_composite(im)
    return bg.crop((190, 60, 330, 200)).resize((420, 420), Image.LANCZOS)
fs = [face(V["v2"] + "/frames/idle_00.png"), face(V["v2.1"] + "/frames/idle_00.png")]
sh = Image.new("RGB", (860, 420), (0, 0, 0)); sh.paste(fs[0], (0, 0)); sh.paste(fs[1], (440, 0)); sh.save(os.path.join(D, "closeup_face_v2_vs_v21.png"))
# metrics
def dir_stats(d):
    fr = sorted(glob.glob(d + "/frames/*.png") + glob.glob(d + "/phase2/frames/*.png"))
    png = sum(os.path.getsize(f) for f in fr)
    px = 0; tight = 0
    for f in fr:
        im = Image.open(f).convert("RGBA"); px += im.width * im.height
        a = np.asarray(im)[..., 3]; ys, xs = np.where(a > 8)
        tight += (xs.max() - xs.min() + 1) * (ys.max() - ys.min() + 1)
    return dict(frames=len(fr), png_mb=png / 2**20, rgba8_mb=px * 4 / 2**20, etc2_dxt5_mb=px / 2**20, astc6x6_mb=px * (128 / 36) / 8 / 2**20, trimmed_rgba8_mb=tight * 4 / 2**20)
m = {k: dir_stats(v) for k, v in V.items()}
for k, v in m.items():
    print(k, {a: round(b, 2) for a, b in v.items()})
json.dump(m, open(os.path.join(D, "metrics.json"), "w"), indent=1)
