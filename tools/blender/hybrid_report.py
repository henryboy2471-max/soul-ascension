#!/usr/bin/env python3
"""Hybrid experiment report: mobile-viewport lineups (from the in-engine 1280x720 captures), v2-vs-hybrid close-ups, size/memory metrics.
Usage: python3 hybrid_report.py DOCS_DIR HYB_P1 HYB_P2"""
import sys, os, glob, json
import numpy as np
from PIL import Image
D, H1, H2 = sys.argv[1], sys.argv[2], sys.argv[3]
V1 = "assets/enemies/hollow_cantor/frames/idle_00.png"
V2 = "assets/enemies/hollow_cantor/phase2/frames/idle_00.png"
# mobile viewports: the game uses canvas_items stretch, so 1280x720 content is scaled to fit the short side
for ph in (1, 2):
    src = Image.open(os.path.join(D, "lineup_phase%d_1280x720.png" % ph)).convert("RGB")
    for (w, h) in ((844, 390), (667, 375)):
        k = min(w / 1280, h / 720)
        im = src.resize((int(1280 * k), int(720 * k)), Image.LANCZOS)
        canvas = Image.new("RGB", (w, h), (0, 0, 0))
        canvas.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
        canvas.save(os.path.join(D, "lineup_phase%d_%dx%d.png" % (ph, w, h)))
        canvas.resize((w * 2, h * 2), Image.NEAREST).save(os.path.join(D, "lineup_phase%d_%dx%d_shown_2x.png" % (ph, w, h)))
# close-ups on a flat dark backdrop at native frame size
def closeup(pairs, out):
    ims = [Image.open(p).convert("RGBA") for p in pairs]
    Hh = max(i.height for i in ims)
    sheet = Image.new("RGBA", (sum(i.width for i in ims) + 10 * (len(ims) + 1), Hh + 20), (30, 18, 64, 255))
    x = 10
    for i in ims:
        sheet.alpha_composite(i, (x, 10 + Hh - i.height)); x += i.width + 10
    sheet.convert("RGB").save(out)
closeup([V1, H1, V2, H2], os.path.join(D, "closeup_v2_vs_hybrid_native.png"))
# metrics
def stats(path):
    im = Image.open(path).convert("RGBA")
    a = np.asarray(im)[..., 3]
    ys, xs = np.where(a > 8)
    bb = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    return dict(size=im.size, bytes=os.path.getsize(path), bbox=bb, tight_px=(bb[2] - bb[0]) * (bb[3] - bb[1]), full_px=im.width * im.height)
m = {}
for name, p in (("v2_p1", V1), ("hybrid_p1", H1), ("v2_p2", V2), ("hybrid_p2", H2)):
    s = stats(p)
    s["rgba_mb_full"] = s["full_px"] * 4 / 2**20
    s["rgba_mb_trimmed"] = s["tight_px"] * 4 / 2**20
    s["etc2_kb_full"] = s["full_px"] * 1 / 1024        # ETC2 RGBA8 = 8 bpp
    s["astc6x6_kb_full"] = s["full_px"] * (128 / 36) / 8 / 1024
    s["astc6x6_kb_trimmed"] = s["tight_px"] * (128 / 36) / 8 / 1024
    m[name] = s
    print(name, {k: (round(v, 2) if isinstance(v, float) else v) for k, v in s.items()})
# 64-frame sheet estimate (32 frames per phase, same as v2)
for k in ("v2", "hybrid"):
    full = 32 * (m[k + "_p1"]["rgba_mb_full"] + m[k + "_p2"]["rgba_mb_full"])
    trim = 32 * (m[k + "_p1"]["rgba_mb_trimmed"] + m[k + "_p2"]["rgba_mb_trimmed"])
    astc = 32 * (m[k + "_p1"]["astc6x6_kb_trimmed"] + m[k + "_p2"]["astc6x6_kb_trimmed"]) / 1024
    png = 32 * (m[k + "_p1"]["bytes"] + m[k + "_p2"]["bytes"]) / 2**20
    print("%s 64-frame est: uncompressed RGBA %.1f MB | trimmed %.1f MB | ASTC6x6 trimmed %.1f MB | PNG payload %.1f MB (single-frame size x32)" % (k, full, trim, astc, png))
json.dump({k: {a: (list(map(int, b)) if isinstance(b, tuple) else b) for a, b in v.items()} for k, v in m.items()}, open(os.path.join(D, "metrics.json"), "w"), indent=1, default=str)
