#!/usr/bin/env python3
"""Contact sheet for eyeballing sliced frames: python3 tools/preview_frames.py DIR_WITH_PNGS OUT.png [bg=#ff00ff]"""
import os, sys
from PIL import Image

def main():
    src, out = sys.argv[1], sys.argv[2]
    bg = sys.argv[3] if len(sys.argv) > 3 else "#c026a3"
    files = sorted(f for f in os.listdir(src) if f.endswith(".png"))
    if not files:
        print("no frames"); return 1
    imgs = [Image.open(os.path.join(src, f)).convert("RGBA") for f in files]
    w = max(i.width for i in imgs); h = max(i.height for i in imgs)
    cols = min(8, len(imgs)); rows = (len(imgs) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * (w + 6) + 6, rows * (h + 6) + 6), bg)
    for n, im in enumerate(imgs):
        x = 6 + (n % cols) * (w + 6); y = 6 + (n // cols) * (h + 6)
        sheet.alpha_composite(im, (x + (w - im.width) // 2, y + h - im.height))
    sheet.convert("RGB").save(out)
    print(f"{len(imgs)} frames -> {out} ({sheet.width}x{sheet.height})")

if __name__ == "__main__":
    sys.exit(main() or 0)
