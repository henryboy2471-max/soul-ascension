#!/usr/bin/env python3
"""Stillness metrics from tools/qa/idle_footage.cjs output: how much the picture of a character that is standing still changes over time.
usage: idle_report.py <outdir> <tag> [--gif other_tag out.gif]      (needs ffmpeg + Pillow + numpy)
Metrics (hero crop, 25 fps video frames): mean/p95/max absolute pixel difference to the temporal median ("how far the picture is from its own average"),
share of frame-to-frame changes that are visible pops (consecutive-frame difference above 1.5 x the median), and the engine's sprite-frame changes per second."""
import json, subprocess, sys, tempfile, os, glob
import numpy as np
from PIL import Image

def frames_of(out, tag, rect, secs, fps=25):
    d = tempfile.mkdtemp(prefix="idle_")
    subprocess.run(["ffmpeg", "-loglevel", "error", "-sseof", f"-{secs}", "-i", f"{out}/{tag}.webm", "-vf", f"crop={rect['width']}:{rect['height']}:{rect['x']}:{rect['y']},fps={fps}", f"{d}/%05d.png"], check=True)
    fs = sorted(glob.glob(d + "/*.png"))
    return np.stack([np.asarray(Image.open(f).convert("RGB"), dtype=np.float32) for f in fs]), fs

def metrics(out, tag, who="hero"):
    st = json.load(open(f"{out}/{tag}_stats.json")); rect = st["rect"] if who == "hero" else st["rectMira"]
    fr, files = frames_of(out, tag, rect, st["SECS"])
    fr = fr[25:]                                   # skip the first second of the standing period
    med = np.median(fr, axis=0)
    dev = np.abs(fr - med).mean(axis=(1, 2, 3))    # distance of each frame from the average picture
    step = np.abs(np.diff(fr, axis=0)).mean(axis=(1, 2, 3))
    pops = float((step > 1.5 * max(np.median(step), 0.05)).mean())
    tr = st["trace"]; sw = sum(1 for i in range(1, len(tr)) if tr[i][7] != tr[i - 1][7] or tr[i][8] != tr[i - 1][8]); secs = st["SECS"]
    hx = [r[3] for r in tr]; hy = [r[4] for r in tr]
    return {"frames analysed": len(fr), "deviation from average picture (mean/p95/max, 0-255)": f"{dev.mean():.2f} / {np.percentile(dev, 95):.2f} / {dev.max():.2f}",
            "frame-to-frame change (mean)": f"{step.mean():.2f}", "share of frame transitions that are visible pops": f"{100 * pops:.0f}%",
            "engine sprite-frame changes per second": f"{sw / secs:.1f}", "hero node position range x / y (px)": f"{max(hx) - min(hx):.3f} / {max(hy) - min(hy):.3f}"}, fr

def gif(frs, labels, out, secs=6, fps=12, Z=2):
    n = int(secs * fps); step = 25 // fps
    h, w = frs[0].shape[1:3]; ims = []
    from PIL import ImageDraw
    for i in range(n):
        canvas = Image.new("RGB", (w * Z * len(frs), h * Z + 16), (24, 26, 40)); d = ImageDraw.Draw(canvas)
        for k, f in enumerate(frs):
            canvas.paste(Image.fromarray(f[min(i * step, len(f) - 1)].astype(np.uint8)).resize((w * Z, h * Z), Image.NEAREST), (k * w * Z, 16)); d.text((k * w * Z + 4, 2), labels[k], fill=(255, 255, 120))
        ims.append(canvas.convert("P", palette=Image.ADAPTIVE, colors=96))
    ims[0].save(out, save_all=True, append_images=ims[1:], duration=int(1000 / fps), loop=0, optimize=True)

if __name__ == "__main__":
    out, tag = sys.argv[1], sys.argv[2]
    m, fr = metrics(out, tag)
    print(f"== {tag} (hero)")
    for k, v in m.items(): print(f"   {k}: {v}")
    try:
        st = json.load(open(f"{out}/{tag}_stats.json"))
        if st["EP"] == "3":
            m2, fr2 = metrics(out, tag, "mira"); print(f"== {tag} (Mira)")
            for k, v in m2.items(): print(f"   {k}: {v}")
    except Exception as e: print("mira skipped:", e)
