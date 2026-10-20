#!/usr/bin/env python3
"""Self-test for tools/finalize_native_matte.py on synthetic blocks (temp dir; not art): default 1152 canvas unchanged, --width 1280 puts the foot midpoint on x=640, a wrong-height figure is refused."""
import subprocess, sys, tempfile
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
ROOT = Path(__file__).resolve().parent.parent; TOOL = str(ROOT / "tools/finalize_native_matte.py"); bad = 0
def expect(label, c):
    global bad; print(("PASS: " if c else "FAIL: ") + label); bad += 0 if c else 1
def block(path, h=2000, w=500):
    im = Image.new("RGBA", (w + 40, h + 40), (0, 0, 0, 0)); ImageDraw.Draw(im).rectangle([20, 20, 20 + w, 20 + h], fill=(80, 60, 40, 255)); im.save(path)
with tempfile.TemporaryDirectory() as t:
    t = Path(t); block(t / "in.png")
    for width, mid in ((1152, 576), (1280, 640)):
        args = [sys.executable, TOOL, str(t / "in.png"), str(t / "out.png")] + (["--width", "1280"] if width == 1280 else [])
        r = subprocess.run(args, capture_output=True, text=True); im = Image.open(t / "out.png"); a = np.array(im.getchannel("A")); ys, xs = np.nonzero(a > 16)
        expect(f"{width}: canvas {im.size}, sole bottom {ys.max() + 1}, foot midpoint {(xs.min() + xs.max()) / 2:.1f}", r.returncode == 0 and im.size == (width, 2304) and ys.max() + 1 == 2176 and abs((xs.min() + xs.max()) / 2 - mid) <= 1.0)
    block(t / "small.png", h=900); r = subprocess.run([sys.executable, TOOL, str(t / "small.png"), str(t / "o2.png"), "--width", "1280"], capture_output=True, text=True)
    expect("a smaller (non-native-height) image is refused, never scaled", r.returncode == 1 and "REFUSED" in r.stdout)
print("RESULT:", "ALL PASS" if not bad else f"{bad} FAILED"); sys.exit(1 if bad else 0)
