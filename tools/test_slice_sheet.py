#!/usr/bin/env python3
"""Self-test for slice_sheet.py using throw-away synthetic sheets (test fixtures only, not game art)."""
import json, os, subprocess, sys, tempfile
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(HERE, "slice_sheet.py")
BG = (30, 200, 60)


def figure(draw, cx, ground, lean, height):
    """A stand-in 'character': legs, torso, head and a detached floating spark. Feet end at `ground`."""
    draw.rectangle([cx - 10 + lean, ground - 30, cx - 3 + lean, ground], fill=(200, 60, 60))
    draw.rectangle([cx + 3 - lean, ground - 30, cx + 10 - lean, ground], fill=(200, 60, 60))
    draw.rectangle([cx - 14, ground - height, cx + 14, ground - 30], fill=(80, 90, 220))
    draw.ellipse([cx - 11, ground - height - 24, cx + 11, ground - height - 2], fill=(240, 200, 160))
    draw.ellipse([cx + 30, ground - height, cx + 36, ground - height + 6], fill=(255, 255, 0))


def make_sheet(path, count, gaps, grounds, noise=True, seed=1):
    rng = np.random.default_rng(seed)
    w = sum(60 + g for g in gaps) + 120
    img = Image.new("RGB", (w, 220), BG)
    d = ImageDraw.Draw(img)
    x = 50
    for i in range(count):
        figure(d, x + 30, grounds[i], lean=int(rng.integers(-4, 5)), height=int(rng.integers(70, 95)))
        x += 60 + gaps[i]
    arr = np.array(img).astype(int)
    if noise:
        arr += rng.integers(-5, 6, arr.shape)
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).save(path)


def run(*args):
    r = subprocess.run([sys.executable, TOOL, *args], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def check(ok, name):
    print(("PASS: " if ok else "FAIL: ") + name)
    return ok


def main():
    ok = True
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "hero")
        walk = os.path.join(tmp, "walk.png")
        jump = os.path.join(tmp, "jump.png")
        touch = os.path.join(tmp, "touch.png")
        # irregular spacing, grounds wobble by a few px (generated art is rarely perfectly aligned)
        make_sheet(walk, 6, [6, 20, 9, 44, 12, 7], [180, 183, 178, 181, 180, 185])
        make_sheet(jump, 5, [10, 10, 10, 10, 10], [180, 150, 120, 150, 180], seed=2)
        make_sheet(touch, 4, [-52, -52, -52, -52], [180] * 4, seed=3)  # frames overlap -> cannot be split
        code, text = run("slice", walk, "--out", out, "--anim", "walk", "--frames", "6")
        ok &= check(code == 0 and "6 frames" in text, "walk sheet with irregular gaps splits into 6 frames")
        code, text = run("slice", jump, "--out", out, "--anim", "jump", "--frames", "5", "--ground", "row", "--loop", "false")
        ok &= check("5 frames" in text, "jump sheet splits into 5 frames")
        code, text = run("slice", touch, "--out", out, "--anim", "attack1", "--frames", "4")
        manifest = json.load(open(os.path.join(out, "manifest.json")))
        ok &= check(manifest["animations"]["attack1"]["flagged"], "overlapping frames are flagged instead of guessed")
        code, text = run("finalize", "--out", out)
        ok &= check(code == 0 and "flagged" in text, "finalize skips flagged animations")
        manifest = json.load(open(os.path.join(out, "manifest.json")))
        width, height = manifest["canvas"]
        ground_row = manifest["ground_row"]
        files = sorted(f for f in os.listdir(os.path.join(out, "frames")) if f.endswith(".png"))
        ok &= check(len(files) == 11 and not any(f.startswith("attack1") for f in files), "only reliable animations are exported")
        sizes = {Image.open(os.path.join(out, "frames", f)).size for f in files}
        ok &= check(sizes == {(width, height)}, "every frame shares one canvas size")
        bottoms, centres, corner_ok = [], [], True
        for f in files:
            a = np.array(Image.open(os.path.join(out, "frames", f)).convert("RGBA"))[..., 3]
            corner_ok &= a[0, 0] == 0 and a[-1, -1] == 0
            if f.startswith("walk"):
                ys = np.flatnonzero((a > 8).any(axis=1))
                bottoms.append(ys[-1] + 1)
                band = (a[ys[-1] - 3: ys[-1] + 1] > 8).any(axis=0)
                centres.append(np.flatnonzero(band).mean() + 0.5)
        ok &= check(corner_ok, "background is fully transparent")
        ok &= check(set(bottoms) == {ground_row}, "all walk frames end on the same ground row (no vertical jitter)")
        ok &= check(max(abs(c - width / 2) for c in centres) <= 8, "feet stay horizontally centred in every walk frame")
        jb = []
        for f in files:
            if f.startswith("jump"):
                a = np.array(Image.open(os.path.join(out, "frames", f)).convert("RGBA"))[..., 3]
                jb.append(np.flatnonzero((a > 8).any(axis=1))[-1] + 1)
        ok &= check(len(set(jb)) >= 3 and max(jb) <= ground_row, "air frames keep their height above the ground line")
    print("RESULT:", "all passed" if ok else "FAILURES")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
