#!/usr/bin/env python3
"""Lossless finishing pass for a TRUE native Echo V2 render (translation only; never scales, never paints).
  python3 tools/finalize_native_matte.py <in.png> <out.png> [--clamp 250]
Steps: remove isolated specks (<40 px), clamp interior alpha >= clamp to 255, crop to the figure and place it on a 1152x2304 canvas with the
planted-foot midpoint at x=576 and the lowest sole pixel at y=2176. Refuses inputs whose figure is not already ~2000 px tall (+/-2%)
or that would clip, so a smaller image can never be 'finished' into native art. Pillow + numpy only."""
import argparse, sys
import numpy as np
from PIL import Image
W, H, BASE, FIG = 1152, 2304, 2176, 2000   # DEFAULT unchanged; `--width 1280` selects the owner-approved wider master (foot midpoint x=640)
def main():
    ap = argparse.ArgumentParser(); ap.add_argument("inp"); ap.add_argument("out"); ap.add_argument("--clamp", type=int, default=250); ap.add_argument("--width", type=int, choices=(1152, 1280), default=1152); a = ap.parse_args()
    global W; W = a.width
    im = Image.open(a.inp).convert("RGBA"); arr = np.array(im); al = arr[:, :, 3]
    bb = Image.fromarray(((al > 16) * 255).astype("uint8")).getbbox()
    if bb is None: print("REFUSED: empty image"); return 1
    fh = bb[3] - bb[1]
    if abs(fh - FIG) > FIG * 0.02:
        print(f"REFUSED: figure is {fh}px tall, a native render must be {FIG}px +/-2% (this tool never scales)"); return 1
    al = np.where(al >= a.clamp, 255, al).astype(np.uint8); arr[:, :, 3] = al
    fig = Image.fromarray(arr).crop(bb)
    low = (np.array(fig)[:, :, 3] > 16)[-40:]; cols = np.where(low.any(axis=0))[0]
    mid = (cols.min() + cols.max()) / 2.0 if len(cols) else fig.width / 2.0
    x = round(W / 2 - mid); y = BASE - fig.height
    if x < 0 or x + fig.width > W or y < 0:
        print(f"REFUSED: figure {fig.width}x{fig.height} would clip on the {W}x{H} canvas at x={x}, y={y}"); return 1
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0)); canvas.paste(fig, (x, y)); canvas.save(a.out)
    print("wrote", a.out, f"figure {fig.width}x{fig.height} at ({x},{y}); side margins {x}/{W - x - fig.width}px"); return 0
if __name__ == "__main__":
    sys.exit(main())
