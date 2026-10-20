#!/usr/bin/env python3
"""Krita/GIMP painting templates for the four native Echo V2 turnaround views at the corrected master canvas 1280x2304 (owner decision: figure centre and foot midpoint x=640). Not art.
Writes to assets/characters/hero/frames_proposed/echo_v2_native/<view>/ for front, right, back, left:
  <view>_template_guides.png    transparent canvas with the guide lines (head top y=176, soles y=2176, foot midpoint x=640, 24 px margin box)
  <view>_UNDERLAY_NOT_ART.png   the approved round-2 reference resized (Lanczos; scale and translation only) so the figure is 2000 px tall with its planted-foot midpoint on x=640, at 50% opacity,
                                for painting over on a layer BELOW the linework. It is an enlargement: soft, and it carries the reference's defects (clipped edges, eye colour, missing front ponytail).
Prints the silhouette extents after placement so clipping/margin problems are visible. usage: tools/make_echo_v2_front_template.py"""
import json, os
import numpy as np
from PIL import Image, ImageDraw
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
R = os.path.join(REPO, "assets/approved_anime/review/echo_v2_review/round2_consistency_pass")
VIEWS = {"front": "echo_v2_r2_front_530x887_REVIEW_ONLY.webp", "right": "echo_v2_r2_right_facing_360x887_REVIEW_ONLY.png", "back": "echo_v2_r2_back_450x887_REVIEW_ONLY.png", "left": "echo_v2_r2_left_facing_434x887_REVIEW_ONLY.png"}
W, H, FIG, TOP, BASE, MID, MARGIN = 1280, 2304, 2000, 176, 2176, 640, 24
BASE_OUT = os.path.join(REPO, "assets/characters/hero/frames_proposed/echo_v2_native")
def guides():
    g = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(g)
    for y, c, t in ((TOP, (230, 40, 40, 255), f"head top y={TOP}"), (BASE, (40, 120, 230, 255), f"soles y={BASE}")): d.line([(0, y), (W, y)], fill=c, width=3); d.text((8, y - 14), t, fill=c)
    d.line([(MID, 0), (MID, H)], fill=(40, 170, 90, 255), width=3); d.text((MID + 8, 8), f"figure centre and foot midpoint x={MID}", fill=(40, 170, 90, 255))
    d.rectangle([MARGIN, MARGIN, W - MARGIN, H - MARGIN], outline=(160, 160, 160, 255), width=2); d.text((MARGIN + 6, MARGIN + 4), "24 px margin: nothing may touch or cross", fill=(120, 120, 120, 255))
    return g
def main():
    report = {}
    for view, name in VIEWS.items():
        out = os.path.join(BASE_OUT, view); os.makedirs(out, exist_ok=True); guides().save(os.path.join(out, f"{view}_template_guides.png"))
        im = Image.open(os.path.join(R, name)).convert("RGBA"); a = np.array(im.getchannel("A")); ys, xs = np.nonzero(a > 24); box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
        touches = [s for s, c in (("left", a[:, 0]), ("right", a[:, -1]), ("top", a[0, :]), ("bottom", a[-1, :])) if (c > 24).any()]
        im = im.crop(box); a = np.array(im.getchannel("A")); k = FIG / im.height; im = im.resize((round(im.width * k), FIG), Image.LANCZOS)
        a2 = np.array(im.getchannel("A")); foot = np.nonzero(a2[-40:, :] > 24)[1]; foot_mid = (foot.min() + foot.max()) / 2.0   # same rule as tools/check_hero_turnaround.py
        x0 = round(MID - foot_mid); u = Image.new("RGBA", (W, H), (0, 0, 0, 0)); u.alpha_composite(im, (x0, TOP)) if x0 >= 0 else u.alpha_composite(im.crop((-x0, 0, im.width, im.height)), (0, TOP))
        u.putalpha(u.getchannel("A").point(lambda v: v // 2)); u.save(os.path.join(out, f"{view}_UNDERLAY_NOT_ART.png"))
        left, right = x0, x0 + im.width; report[view] = dict(scaled_width=im.width, left=left, right=right, spare_left=left - MARGIN, spare_right=(W - MARGIN) - right, reference_edges_touched=touches)
        print(f"{view}: figure {im.width}x{FIG}, x {left}..{right}, margin spare L {left - MARGIN:+d} R {(W - MARGIN) - right:+d}, reference touches canvas edge: {touches or 'no'}")
    json.dump(report, open(os.path.join(BASE_OUT, "silhouette_report_1280.json"), "w"), indent=1)
if __name__ == "__main__": main()
