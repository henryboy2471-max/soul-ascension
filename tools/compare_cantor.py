#!/usr/bin/env python3
"""Side-by-side of Hero, Shade, Cantor Phase 1 and Cantor Phase 2 at actual gameplay scale (1280x720 canvas units).
Usage: python3 tools/compare_cantor.py OUT.png [frames_p1_dir frames_p2_dir] [zoom]"""
import sys
from PIL import Image, ImageDraw
import numpy as np

def load(path):
    return Image.open(path).convert("RGBA")

def place(sheet, im, world_h, node_scale, cx, feet_y):
    k = world_h / im.height * node_scale
    im2 = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    sheet.alpha_composite(im2, (int(cx - im2.width / 2), int(feet_y - im2.height)))
    return im2

def main():
    out = sys.argv[1]
    p1 = sys.argv[2] if len(sys.argv) > 2 else "assets/enemies/hollow_cantor/frames"
    p2 = sys.argv[3] if len(sys.argv) > 3 else "assets/enemies/hollow_cantor/phase2/frames"
    zoom = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
    W, H = 1280, 480
    bg = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    px = np.zeros((H, W, 4), np.uint8)
    for y in range(H):
        t = y / H
        px[y, :, 0] = int(14 + 40 * t); px[y, :, 1] = int(8 + 18 * t); px[y, :, 2] = int(44 + 70 * t); px[y, :, 3] = 255
    sheet = Image.fromarray(px, "RGBA")
    d = ImageDraw.Draw(sheet)
    d.line([(0, 300), (W, 300)], fill=(190, 150, 255, 200), width=2)
    feet = 440
    names = [("HERO  (170 px)", "assets/characters/hero/frames/idle_00.png", 170, 1.0, 170),
             ("SHADE  (185 px)", "assets/enemies/resonance_shade/frames/idle_00.png", 185, 1.0, 460),
             ("CANTOR  PHASE 1  (x1.45)", p1 + "/idle_00.png", 213.46, 1.45, 800),
             ("CANTOR  PHASE 2  (x1.62)", p2 + "/idle_00.png", 213.46, 1.62, 1120)]
    for label, path, wh, sc, cx in names:
        d.ellipse([cx - 44, feet - 8, cx + 44, feet + 8], fill=(0, 0, 0, 120))
        place(sheet, load(path), wh, sc, cx, feet)
        d.text((cx - 80, 455), label, fill=(240, 230, 255, 255))
    if zoom != 1.0:
        sheet = sheet.resize((int(W * zoom), int(H * zoom)), Image.LANCZOS)
    sheet.convert("RGB").save(out)
    print("wrote", out, sheet.size)

if __name__ == "__main__":
    main()
