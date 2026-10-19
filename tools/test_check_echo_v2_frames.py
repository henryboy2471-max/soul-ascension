#!/usr/bin/env python3
"""Self-test for check_echo_v2_frames.py using synthetic placeholder images in a temp dir (not art): a valid set passes, wrong canvas/count/floating feet fail, and the repo's proposed folders (guides only) are rejected."""
import os, subprocess, sys, tempfile
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); TOOL = os.path.join(HERE, "check_echo_v2_frames.py")
def make(d, state, n, size, floating=False):
    for i in range(n):
        im = Image.new("RGBA", size, (0, 0, 0, 0)); ImageDraw.Draw(im).rectangle([size[0] // 2 - 30, 20, size[0] // 2 + 30, size[1] - (10 if floating else 1)], fill=(40, 40, 60, 255)); im.save(os.path.join(d, f"{state}_{i:02d}.png"))
def run(d, state): return subprocess.run([sys.executable, TOOL, d, state], capture_output=True, text=True).returncode
ok = True
def check(c, name):
    global ok
    print(("PASS: " if c else "FAIL: ") + name); ok = ok and c
with tempfile.TemporaryDirectory() as t:
    a = os.path.join(t, "a"); os.mkdir(a); make(a, "walk", 8, (272, 216)); check(run(a, "walk") == 0, "valid walk set passes")
    b = os.path.join(t, "b"); os.mkdir(b); make(b, "walk", 7, (272, 216)); check(run(b, "walk") == 1, "wrong frame count fails")
    c = os.path.join(t, "c"); os.mkdir(c); make(c, "walk", 8, (136, 108)); check(run(c, "walk") == 1, "wrong canvas fails")
    d = os.path.join(t, "d"); os.mkdir(d); make(d, "run", 8, (480, 216), floating=True); check(run(d, "run") == 1, "feet off the bottom row fail")
    e = os.path.join(t, "e"); os.mkdir(e); make(e, "run", 8, (480, 216)); check(run(e, "run") == 0, "valid run set passes (480x216)")
with tempfile.TemporaryDirectory() as t2:
    for i in range(8): Image.new("RGBA", (272, 216), (250, 250, 246, 255)).save(os.path.join(t2, f"walk_{i:02d}.png"))
    check(run(t2, "walk") == 1, "an opaque-background guide image (not finished art) is rejected")
print("RESULT: ALL PASS" if ok else "RESULT: FAILURES"); sys.exit(0 if ok else 1)
