#!/usr/bin/env python3
"""DIAGNOSTIC ONLY — AI-assisted enlargement of an Echo V2 reference crop (Real-ESRGAN x4plus anime 6B, free/open source, CPU).
The output is NOT native production art and must never be labelled native: it is an enlargement of a reference with hallucinated detail.
It exists to measure what the free-tool route yields and as step 1 of a disclosed, human-finished 'assisted-native' workflow.
Needs a venv with torch (see docs). Usage:
  python tools/echo_v2_assisted_enlarge.py <in.png|webp> <out.png> [--weights path] [--fig 2000]
Writes <out>.provenance.json next to the output. Alpha is enlarged separately and re-thresholded; nothing is painted or invented by script."""
import argparse, json, sys, time, hashlib
from pathlib import Path
import numpy as np
import torch, torch.nn as nn, torch.nn.functional as F
from PIL import Image

class RDB(nn.Module):
    def __init__(s, nf=64, gc=32):
        super().__init__()
        s.conv1 = nn.Conv2d(nf, gc, 3, 1, 1); s.conv2 = nn.Conv2d(nf + gc, gc, 3, 1, 1); s.conv3 = nn.Conv2d(nf + 2 * gc, gc, 3, 1, 1)
        s.conv4 = nn.Conv2d(nf + 3 * gc, gc, 3, 1, 1); s.conv5 = nn.Conv2d(nf + 4 * gc, nf, 3, 1, 1); s.act = nn.LeakyReLU(0.2, True)
    def forward(s, x):
        x1 = s.act(s.conv1(x)); x2 = s.act(s.conv2(torch.cat((x, x1), 1))); x3 = s.act(s.conv3(torch.cat((x, x1, x2), 1)))
        x4 = s.act(s.conv4(torch.cat((x, x1, x2, x3), 1))); x5 = s.conv5(torch.cat((x, x1, x2, x3, x4), 1)); return x5 * 0.2 + x
class RRDB(nn.Module):
    def __init__(s, nf, gc=32):
        super().__init__(); s.rdb1 = RDB(nf, gc); s.rdb2 = RDB(nf, gc); s.rdb3 = RDB(nf, gc)
    def forward(s, x): return s.rdb3(s.rdb2(s.rdb1(x))) * 0.2 + x
class RRDBNet(nn.Module):
    def __init__(s, nb=6, nf=64, gc=32):
        super().__init__()
        s.conv_first = nn.Conv2d(3, nf, 3, 1, 1); s.body = nn.Sequential(*[RRDB(nf, gc) for _ in range(nb)]); s.conv_body = nn.Conv2d(nf, nf, 3, 1, 1)
        s.conv_up1 = nn.Conv2d(nf, nf, 3, 1, 1); s.conv_up2 = nn.Conv2d(nf, nf, 3, 1, 1); s.conv_hr = nn.Conv2d(nf, nf, 3, 1, 1); s.conv_last = nn.Conv2d(nf, 3, 3, 1, 1); s.act = nn.LeakyReLU(0.2, True)
    def forward(s, x):
        f = s.conv_first(x); f = f + s.conv_body(s.body(f))
        f = s.act(s.conv_up1(F.interpolate(f, scale_factor=2, mode="nearest"))); f = s.act(s.conv_up2(F.interpolate(f, scale_factor=2, mode="nearest")))
        return s.conv_last(s.act(s.conv_hr(f)))

def upscale(net, img, tile=128, pad=12):
    x = torch.from_numpy(np.asarray(img, dtype=np.float32) / 255.0).permute(2, 0, 1)[None]
    _, _, H, W = x.shape; out = torch.zeros(1, 3, H * 4, W * 4)
    with torch.no_grad():
        for y0 in range(0, H, tile):
            for x0 in range(0, W, tile):
                ys, xs = max(0, y0 - pad), max(0, x0 - pad); ye, xe = min(H, y0 + tile + pad), min(W, x0 + tile + pad)
                o = net(x[:, :, ys:ye, xs:xe])
                cy, cx = (y0 - ys) * 4, (x0 - xs) * 4; h, w = min(tile, H - y0) * 4, min(tile, W - x0) * 4
                out[:, :, y0 * 4:y0 * 4 + h, x0 * 4:x0 * 4 + w] = o[:, :, cy:cy + h, cx:cx + w]
    return Image.fromarray((out[0].clamp(0, 1).permute(1, 2, 0).numpy() * 255).round().astype(np.uint8))

def main():
    ap = argparse.ArgumentParser(); ap.add_argument("inp"); ap.add_argument("out"); ap.add_argument("--weights", default="/tmp/esr/RealESRGAN_x4plus_anime_6B.pth"); ap.add_argument("--fig", type=int, default=2000)
    a = ap.parse_args(); t0 = time.time(); torch.set_num_threads(4)
    src = Image.open(a.inp).convert("RGBA"); rgba = np.array(src); al = rgba[:, :, 3]
    bbox = Image.fromarray(((al > 16) * 255).astype("uint8")).getbbox(); fig_h = bbox[3] - bbox[1]
    rgb = rgba[:, :, :3].copy(); bg = (rgb.reshape(-1, 3)[al.reshape(-1) > 250]).mean(axis=0) if (al > 250).any() else np.array([20, 20, 20])
    rgb[al < 128] = bg.astype(np.uint8)   # neutral fill outside the figure so the network never sees white halo pixels
    net = RRDBNet(); sd = torch.load(a.weights, map_location="cpu", weights_only=True); net.load_state_dict(sd.get("params_ema", sd.get("params", sd)), strict=True); net.eval()
    big_rgb = upscale(net, Image.fromarray(rgb)); big_a = upscale(net, Image.fromarray(np.stack([al] * 3, -1))).convert("L")
    scale = a.fig / (fig_h * 4.0)
    size = (round(big_rgb.width * scale), round(big_rgb.height * scale))
    rgb2 = big_rgb.resize(size, Image.LANCZOS); a2 = np.array(big_a.resize(size, Image.LANCZOS)).astype(np.float32) / 255.0
    a2 = np.clip((a2 - 0.35) / 0.3, 0, 1)   # tighten the soft edge band; never adds area outside the figure
    out = Image.fromarray(np.dstack([np.array(rgb2), (a2 * 255).round().astype(np.uint8)]), "RGBA")
    out.save(a.out)
    Path(str(a.out) + ".provenance.json").write_text(json.dumps({"status": "DIAGNOSTIC_ENLARGEMENT_NOT_NATIVE", "tool": "Real-ESRGAN x4plus anime 6B (free, CPU, own RRDBNet loader)", "input": str(a.inp), "input_sha256": hashlib.sha256(Path(a.inp).read_bytes()).hexdigest()[:16], "input_figure_height": int(fig_h), "output_size": list(out.size), "seconds": round(time.time() - t0, 1)}, indent=1))
    print("wrote", a.out, out.size, round(time.time() - t0), "s")
if __name__ == "__main__":
    sys.exit(main())
