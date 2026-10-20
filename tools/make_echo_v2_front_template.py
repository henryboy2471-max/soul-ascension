#!/usr/bin/env python3
"""Krita/GIMP painting template for the native Echo V2 FRONT view (1152x2304). Not art. Writes to assets/characters/hero/frames_proposed/echo_v2_native/front/:
  front_template_guides.png   transparent canvas with the G2 guide lines (head top y=176, soles y=2176, foot midpoint x=576, 24 px margin, figure box)
  front_UNDERLAY_NOT_ART.png  the approved round-2 front reference resized (Lanczos, translation+scale only) to the 2000 px figure box at 50% opacity, for the artist to paint over on a layer BELOW their linework. It is an enlargement, so it is deliberately soft and carries the reference's known defects.
usage: tools/make_echo_v2_front_template.py"""
import os
from PIL import Image, ImageDraw
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SRC = os.path.join(REPO, "assets/approved_anime/review/echo_v2_review/round2_consistency_pass/echo_v2_r2_front_530x887_REVIEW_ONLY.webp")
OUT = os.path.join(REPO, "assets/characters/hero/frames_proposed/echo_v2_native/front")
W, H, FIG, TOP, BASE, MID, MARGIN = 1152, 2304, 2000, 176, 2176, 576, 24
def main():
    os.makedirs(OUT, exist_ok=True)
    g = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(g)
    for y, c, t in ((TOP, (230, 40, 40, 255), "head top y=176"), (BASE, (40, 120, 230, 255), "soles y=2176")): d.line([(0, y), (W, y)], fill=c, width=3); d.text((8, y - 14), t, fill=c)
    d.line([(MID, 0), (MID, H)], fill=(40, 170, 90, 255), width=3); d.text((MID + 8, 8), "foot midpoint x=576", fill=(40, 170, 90, 255))
    d.rectangle([MARGIN, MARGIN, W - MARGIN, H - MARGIN], outline=(160, 160, 160, 255), width=2); d.text((MARGIN + 6, MARGIN + 4), "24 px margin: nothing may touch or cross", fill=(120, 120, 120, 255))
    g.save(os.path.join(OUT, "front_template_guides.png"))
    im = Image.open(SRC).convert("RGBA"); box = im.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox(); im = im.crop(box)
    k = FIG / im.height; im = im.resize((round(im.width * k), FIG), Image.LANCZOS)
    u = Image.new("RGBA", (W, H), (0, 0, 0, 0)); u.alpha_composite(im, (MID - im.width // 2, TOP))
    u.putalpha(u.getchannel("A").point(lambda v: v // 2)); u.save(os.path.join(OUT, "front_UNDERLAY_NOT_ART.png"))
    print("underlay figure", im.size, "left/right margin", MID - im.width // 2, W - (MID - im.width // 2 + im.width))
if __name__ == "__main__": main()
