#!/usr/bin/env python3
"""Builds the side-by-side visual review sheet for gate G2 (read-only: writes only the output PNG).
    python3 tools/make_echo_review_sheet.py [--native assets/approved_anime/source/hero] [--reference <composite>] [--out review_sheet.png]
Row 1: the four views of the authoritative Echo V2 REVIEW composite (split into four equal panels).
Row 2: the four NATIVE renders (hero_turnaround_{front,right,back,left}_native.png) scaled to the same height.
Row 3: the native renders at gameplay size (~250 px tall at 1x) on a dark street-colour block.
Refuses to run if a native render is missing (never substitutes art). Pillow only."""
import argparse, sys
from pathlib import Path
from PIL import Image
VIEWS = ("front", "right", "back", "left")
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--native", type=Path, default=Path("assets/approved_anime/source/hero"))
    ap.add_argument("--reference", type=Path, default=Path("assets/approved_anime/review/echo_v2_review/echo_v2_four_view_composite_1774x887_REVIEW_ONLY.webp"))
    ap.add_argument("--out", type=Path, default=Path("echo_v2_g2_review_sheet.png"))
    a = ap.parse_args()
    missing = [v for v in VIEWS if not (a.native / f"hero_turnaround_{v}_native.png").is_file()]
    if missing or not a.reference.is_file():
        print("BLOCKED: cannot build the review sheet; missing native renders:", missing or "none", "| reference present:", a.reference.is_file())
        return 1
    ref = Image.open(a.reference).convert("RGBA"); pw = ref.width // 4
    H = 887
    cell_w = pw
    sheet = Image.new("RGBA", (cell_w * 4, H * 2 + 330), (24, 26, 40, 255))
    for i in range(4):
        panel = ref.crop((i * pw, 0, (i + 1) * pw, ref.height)); panel = panel.resize((cell_w, int(panel.height * H / ref.height)))
        sheet.alpha_composite(panel, (i * cell_w, 0))
        nat = Image.open(a.native / f"hero_turnaround_{VIEWS[i]}_native.png").convert("RGBA")
        sc = H / nat.height; nat_s = nat.resize((int(nat.width * sc), H), Image.LANCZOS)
        sheet.alpha_composite(nat_s, (i * cell_w + (cell_w - nat_s.width) // 2, H))
        gp = nat.resize((int(nat.width * 250 / (nat.height * 2000 / 2304)), 288), Image.LANCZOS)
        sheet.alpha_composite(gp, (i * cell_w + (cell_w - gp.width) // 2, H * 2 + 20))
    sheet.convert("RGB").save(a.out); print("wrote", a.out); return 0
if __name__ == "__main__":
    sys.exit(main())
