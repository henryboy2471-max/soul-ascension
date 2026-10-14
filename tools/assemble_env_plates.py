#!/usr/bin/env python3
"""Assembles the Episode 1 Neon District plates from the 15 native source panels (reference/source_panels_v2).
Only crop, uniform downscale (never up) and a seam crossfade are used; every operation is written to <plate>.provenance.json.
Usage: python3 tools/assemble_env_plates.py [--out assets/environment/neon_district]"""
import argparse, hashlib, json
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter
ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/environment/neon_district/reference/source_panels_v2"
OV = 240   # default seam crossfade width in delivered px (a plate may set ovs per seam; trims and widths were picked by a search that minimises the visible luminance step across each stitch)
# name: size, scale ("fit" = largest uniform scale <= 1 that keeps every part's artwork inside the plate height), outer-trim bias (share taken from the left), parts
# part = (panel, ops); ops: opaque (alpha 1), clean (alpha >= .94 -> 1), feather=f (top alpha ramp over f of the height), burn=local exposure multiply, trim=(left,right) px after scaling
INSERT_TRACK = dict(file="reference/tram_track_source/tram_track_insert_1230x190.png", sha256="d5b676f4a282e2a63dc507eb40fc322798cccc15ee36183c6e0c19714f520505", at=(862, 280),
 source="reference/tram_track_source/tram_track_source.png", source_sha256="b5151895424ef7d47e95241e88c41500aaadb2a50604ddc59d3ccec1d4bce3b3", source_dims=(2021, 778), source_crop=(82, 242, 1939, 529), scale=0.66236)
PLATES = {
 "plate_far":        dict(size=(2550, 720), s="fit", bias=.5, parts=[("far_left", {}), ("far_right", {})]),
 "plate_mid":        dict(size=(2700, 615), s="fit", bias=.5, ovs=[160, 240], parts=[("mid_left", {"trim": (0, 160)}), ("mid_center", {"trim": (60, 20)}), ("mid_right", {"trim": (360, 0)})]),
 "plate_near":       dict(size=(3450, 690), s="fit", bias=.5, ovs=[160, 160], parts=[("near_left", {"trim": (0, 20)}), ("near_center", {"trim": (240, 60)}), ("near_right", {"trim": (120, 0)})]),
 "plate_street":     dict(size=(3750, 630), s=.85, bias=0., ovs=[360, 120], floor_soften=(300, 10), inserts=[INSERT_TRACK], parts=[("street_left", {"clean": 1}), ("street_center", {"opaque": 1, "feather": .3, "trim": (260, 425)}), ("street_right", {"opaque": 1, "feather": .3, "burn": (529, 139, 1051, 509, .55, 50)})]),
 "plate_foreground": dict(size=(4200, 210), s=.75, bias=.5, top_feather=.55, ovs=[160, 160], parts=[("foreground_1", {"trim": (0, 20)}), ("foreground_2", {"trim": (0, 220)}), ("foreground_3", {})]),
}
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def load(name):
    im = Image.open(SRC / "panels" / (name + ".png")).convert("RGBA")
    return im
def alpha_ops(im, ops):
    a = np.asarray(im).copy(); al = a[..., 3].astype(np.float32) / 255
    if ops.get("opaque"): al[:] = 1.0
    if ops.get("clean"): al = np.where(al >= .94, 1.0, al)
    if ops.get("feather"):
        h = a.shape[0]; t = np.clip(np.arange(h) / (ops["feather"] * h), 0, 1); t = t * t * (3 - 2 * t)
        al = al * t[:, None]
    a[..., 3] = np.round(al * 255).astype(np.uint8)
    if ops.get("burn"):   # local exposure burn (x0, y0, x1, y1, factor, feather_px) in source px: keeps a code-drawn prop slot calm
        x0, y0, x1, y1, k, fe = ops["burn"]; m = np.zeros(a.shape[:2], np.float32); m[y0:y1, x0:x1] = 1
        m = np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(fe)), np.float32) / 255
        a[..., :3] = np.round(a[..., :3] * (1 - m * (1 - k))[..., None]).astype(np.uint8)
    return Image.fromarray(a, "RGBA")
def content_h(im):
    rows = np.nonzero((np.asarray(im)[..., 3] > 12).any(axis=1))[0]
    return int(rows[-1] - rows[0] + 1) if len(rows) else 0
def scaled_premult(im, s):
    if s > 1.0: raise SystemExit("refusing to upscale")
    w, h = round(im.width * s), round(im.height * s)
    p = im.convert("RGBa")
    p = p.resize((w, h), Image.LANCZOS) if s < 1.0 else p
    return np.asarray(p).astype(np.float32) / 255        # premultiplied RGBA, 0..1
def assemble(name, cfg):
    ovs = list(cfg.get("ovs") or [cfg.get("ov", OV)] * (len(cfg["parts"]) - 1))     # crossfade width per seam
    W, H = cfg["size"]; srcs = [load(p) for p, _ in cfg["parts"]]
    s = cfg["s"]
    if s == "fit": s = min(1.0, H / max(content_h(im) for im in srcs))
    arrs = []
    for (pn, ops), im in zip(cfg["parts"], srcs):
        arrs.append(scaled_premult(alpha_ops(im, ops), s))
    # vertical: bottom aligned, crop the top / pad with transparent
    vert = []
    for (pn, ops), a in zip(cfg["parts"], arrs):
        h = a.shape[0]
        if h >= H: vert.append((a[h - H:], h - H, 0))          # (array, rows cropped from the top, rows padded on the top)
        else: vert.append((np.concatenate([np.zeros((H - h, a.shape[1], 4), np.float32), a]), 0, H - h))
    tl = [list(o.get("trim", (0, 0))) for _, o in cfg["parts"]]
    def total():
        e = [v[0].shape[1] - l - r for v, (l, r) in zip(vert, tl)]
        return e, sum(e) - sum(ovs)
    e, T = total()
    if T < W: raise SystemExit(f"{name}: assembled width {T} < {W}; cannot reach the target without upscaling")
    sur = T - W; left = int(round(cfg["bias"] * sur)); tl[0][0] += left; tl[-1][1] += sur - left
    e, T = total(); assert T == W, (T, W)
    out = np.zeros((H, W, 4), np.float32); pos = 0; parts_rec = []
    for i, ((pn, ops), (a, cropped, padded)) in enumerate(zip(cfg["parts"], vert)):
        seg = a[:, tl[i][0]: a.shape[1] - tl[i][1]]; w = seg.shape[1]
        wt = np.ones(w, np.float32)
        def ramp_of(n): r = np.linspace(0, 1, n, dtype=np.float32); return r * r * (3 - 2 * r)
        if i > 0: wt[:ovs[i - 1]] = ramp_of(ovs[i - 1])
        if i < len(vert) - 1: wt[w - ovs[i]:] = np.minimum(wt[w - ovs[i]:], ramp_of(ovs[i])[::-1])
        out[:, pos:pos + w] += seg * wt[None, :, None]
        im = srcs[i]
        parts_rec.append({"file": f"reference/source_panels_v2/panels/{pn}.png", "sha256": sha(SRC / "panels" / (pn + ".png")),
            "original_dimensions": [im.width, im.height], "scale": round(s, 6), "scaled_dimensions": [round(im.width * s), round(im.height * s)],
            "source_crop_px": [round(tl[i][0] / s), round(cropped / s), round((a.shape[1] - tl[i][1]) / s), im.height],
            "top_rows_padded_transparent": padded, "mosaic_x": pos, "mosaic_width": w,
            "seam_crossfade_px": ovs[i - 1] if i > 0 else 0,
            "edits": {k: v for k, v in ops.items() if k != "trim"}, "trim_px": tl[i]})
        pos += w - (ovs[i] if i < len(ovs) else 0)
    if cfg.get("floor_soften"):   # depth-of-field softening of the near ground (from row r0, Gaussian sigma): keeps the touch-stick HUD zone calm
        r0, sg = cfg["floor_soften"]
        pm = Image.fromarray(np.round(np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBa"); b = np.asarray(pm.filter(ImageFilter.GaussianBlur(sg))).astype(np.float32) / 255
        t = np.clip((np.arange(H) - r0) / (H - r0), 0, 1); t = (t * t * (3 - 2 * t))[:, None, None]
        out = out * (1 - t) + b * t
    ins_rec = []
    for ins in cfg.get("inserts", []):   # authored RGBA insert, alpha-composited over the finished (already softened) plate
        fp = ROOT / "assets/environment/neon_district" / ins["file"]
        assert sha(fp) == ins["sha256"], f"{fp} sha256 mismatch"
        pm = np.asarray(Image.open(fp).convert("RGBa")).astype(np.float32) / 255; x0, y0 = ins["at"]; h, w = pm.shape[:2]
        out[y0:y0 + h, x0:x0 + w] = pm + out[y0:y0 + h, x0:x0 + w] * (1 - pm[..., 3:4])
        so, sc = ins["source_dims"], ins["scale"]
        ins_rec.append({"role": "insert", "file": ins["source"], "sha256": ins["source_sha256"], "original_dimensions": list(so), "scale": sc, "scaled_dimensions": [round(so[0] * sc), round(so[1] * sc)],
            "source_crop_px": list(ins["source_crop"]), "placed_at": list(ins["at"]), "derived_insert": {"file": ins["file"], "sha256": ins["sha256"], "dimensions": [w, h]}, "edits": {}})
    parts_rec += ins_rec
    if cfg.get("top_feather"):   # soft top edge of the finished strip (applied after the vertical crop so it is really visible)
        t = np.clip(np.arange(H) / (cfg["top_feather"] * H), 0, 1); out = out * (t * t * (3 - 2 * t))[:, None, None]
    a = out[..., 3:4]; rgb = np.where(a > 1e-6, out[..., :3] / np.maximum(a, 1e-6), 0)
    px = np.concatenate([np.clip(rgb, 0, 1), np.clip(a, 0, 1)], -1)
    return Image.fromarray(np.round(px * 255).astype(np.uint8), "RGBA"), parts_rec, s
def tram():
    im = load("tram"); W, H = 1050, 234
    box = Image.fromarray((np.asarray(im)[..., 3] > 12).astype(np.uint8) * 255).getbbox()
    sub = im.crop(box); s = min(1.0, W / sub.width, H / sub.height)
    p = sub.convert("RGBa").resize((round(sub.width * s), round(sub.height * s)), Image.LANCZOS).convert("RGBA")
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0)); ox, oy = (W - p.width) // 2, H - p.height - 2
    canvas.alpha_composite(p, (ox, oy))
    rec = [{"file": "reference/source_panels_v2/panels/tram.png", "sha256": sha(SRC / "panels" / "tram.png"), "original_dimensions": [im.width, im.height],
        "scale": round(s, 6), "scaled_dimensions": [round(im.width * s), round(im.height * s)], "subject_scaled_dimensions": [p.width, p.height], "source_crop_px": list(box), "placed_at": [ox, oy], "edits": {}}]
    return canvas, rec, s
def provenance(name, size, rec, note, post=None):
    return {"tool": "OpenAI built-in image generator (source panels); Pillow/NumPy (assembly, tools/assemble_env_plates.py)",
        "method": "assembled_from_native_source_panels: crop, uniform downscale (never up) and a seam crossfade; not a single generation",
        "independent_plate": True, "resolution": "assembled_native", "status": "PRODUCTION_CANDIDATE_PENDING_OWNER_REVIEW",
        "mosaic_dimensions": list(size), "delivered_dimensions": list(size), "final_crop_px": [0, 0], "components": rec,
        "source_manifest": "reference/source_panels_v2/manifest.json", "notes": note, "post_process": post}
def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--out", default=str(ROOT / "assets/environment/neon_district")); a = ap.parse_args()
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    for name, cfg in PLATES.items():
        im, rec, s = assemble(name, cfg)
        im.save(out / (name + ".png"), optimize=True)
        (out / (name + ".provenance.json")).write_text(json.dumps(provenance(name, cfg["size"], rec, f"uniform scale {s:.4f} on every component; bottom-aligned", {"floor_soften": {"from_row": cfg["floor_soften"][0], "gaussian_sigma_px": cfg["floor_soften"][1], "why": "depth-of-field softening of the near ground so the touch-stick HUD zone stays calm"}} if cfg.get("floor_soften") else ({"top_feather_fraction": cfg["top_feather"], "why": "soft top edge of the foreground mist strip"} if cfg.get("top_feather") else None)), indent=1) + "\n")
        print(name, im.size, f"scale {s:.4f}")
    im, rec, s = tram(); im.save(out / "prop_tram_stalled.png", optimize=True)
    (out / "prop_tram_stalled.provenance.json").write_text(json.dumps(provenance("prop_tram_stalled", (1050, 234), rec, "subject cropped from the transparent margins, uniformly scaled into the canvas"), indent=1) + "\n")
    print("prop_tram_stalled", im.size, f"scale {s:.4f}")
if __name__ == "__main__": main()
