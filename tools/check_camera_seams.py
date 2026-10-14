#!/usr/bin/env python3
"""Moving-camera seam check for the assembled environment plates (review aid, not a production gate).
1. per-plate seam score: luminance step across each stitch (crossfade) zone vs the plate's typical column-to-column step
2. camera sweep: composite every STEP px from 0 to 1220 and report frame-to-frame change spikes (a pop = one step far above its neighbours)
Writes <out>/seam_report.json, camera_sweep_filmstrip_REVIEW_ONLY.png and camera_sweep_REVIEW_ONLY.gif.   Usage: python3 tools/check_camera_seams.py [--dir DIR] [--out OUT] [--step 10]"""
import argparse, importlib.util, json
from pathlib import Path
import numpy as np
from PIL import Image
ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("v", ROOT / "tools/validate_env_plates.py"); V = importlib.util.module_from_spec(spec); spec.loader.exec_module(V)
SEAM_RATIO_MAX = 3.0     # a stitch whose luminance step is more than 3x the plate's typical step is flagged for a look
POP_RATIO_MAX = 2.5      # a camera step whose frame change is more than 2.5x its neighbours' median is flagged
def seam_scores(d):
    out = []
    for n in ("plate_far", "plate_mid", "plate_near", "plate_street", "plate_foreground"):
        pv = json.loads((Path(d) / (n + ".provenance.json")).read_text()); im = V.load(d, n)
        a = np.asarray(im).astype(np.float32) / 255; L = V.lum(a[..., :3] * a[..., 3:4]); al = a[..., 3]
        D = np.abs(np.diff(L, axis=1)); m = (al[:, 1:] > .5) & (al[:, :-1] > .5)
        col = np.array([D[:, x][m[:, x]].mean() if m[:, x].sum() > 20 else np.nan for x in range(D.shape[1])])
        zones = []
        for c in pv["components"][1:]:
            x0 = c["mosaic_x"]; w = c.get("seam_crossfade_px") or 120; zones.append((x0, x0 + w))
        mask = np.ones(len(col), bool)
        for x0, x1 in zones: mask[max(x0 - 20, 0):x1 + 20] = False
        base = np.nanmedian(col[mask])
        for (x0, x1), c in zip(zones, pv["components"][1:]):
            seg = col[max(x0 - 4, 0):x1 + 4]; r = float(np.nanmax(seg) / base)
            out.append({"plate": n, "seam_px": [x0, x1], "joins": c["file"].split("/")[-1], "step_ratio": round(r, 2), "flag": bool(r > SEAM_RATIO_MAX)})
    return out
def sweep(d, step, out):
    pl = {n: V.load(d, n) for n in V.PLATES}; tr = V.load(d, V.PROP_TRAM[0])
    cams = list(range(0, 1221, step)); frames = [V.composite(pl, tr, c) for c in cams]
    diffs = np.array([np.abs(frames[i + 1] - frames[i]).mean() for i in range(len(frames) - 1)])
    k = 5; res = []
    for i, dv in enumerate(diffs):
        nb = np.concatenate([diffs[max(i - k, 0):i], diffs[i + 1:i + 1 + k]]); r = float(dv / max(np.median(nb), 1e-6))
        res.append({"camera": cams[i], "change": round(float(dv), 5), "ratio_vs_neighbours": round(r, 2), "flag": bool(r > POP_RATIO_MAX)})
    thumbs = [Image.fromarray((f * 255).astype("uint8")).resize((640, 360), Image.LANCZOS) for f in frames]
    pick = [0, 150, 300, 450, 600, 750, 900, 1050, 1220]; sheet = Image.new("RGB", (1920, 1080))
    for i, c in enumerate(pick):
        j = min(range(len(cams)), key=lambda q: abs(cams[q] - c)); sheet.paste(thumbs[j], ((i % 3) * 640, (i // 3) * 360))
    sheet.save(out / "camera_sweep_filmstrip_REVIEW_ONLY.png")
    g = [t.resize((480, 270), Image.LANCZOS).convert("P", palette=Image.ADAPTIVE, colors=128) for t in thumbs[::4]]
    g[0].save(out / "camera_sweep_REVIEW_ONLY.gif", save_all=True, append_images=g[1:], duration=70, loop=0)
    return res
def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--dir", default=str(ROOT / "assets/environment/neon_district")); ap.add_argument("--out", default=str(ROOT / "docs/visual_redesign/environment_review")); ap.add_argument("--step", type=int, default=10); a = ap.parse_args()
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    seams = seam_scores(a.dir); pops = sweep(a.dir, a.step, out)
    (out / "seam_report.json").write_text(json.dumps({"seam_step_ratio_limit": SEAM_RATIO_MAX, "pop_ratio_limit": POP_RATIO_MAX, "seams": seams, "frame_changes": pops}, indent=1))
    for s in seams: print(f"{'FLAG' if s['flag'] else 'ok  '} {s['plate']:17} seam x {s['seam_px']} joins {s['joins']:18} step ratio {s['step_ratio']}")
    fl = [p for p in pops if p["flag"]]; print(f"camera sweep: {len(pops) + 1} frames, step {a.step}px, flagged pops: {len(fl)} (max ratio {max(p['ratio_vs_neighbours'] for p in pops)})")
    for p in fl: print("  pop at camera", p["camera"], p["ratio_vs_neighbours"])
if __name__ == "__main__": main()
