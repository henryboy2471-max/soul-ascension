#!/usr/bin/env python3
"""Validator for the Episode 1 Neon District environment plates (see docs/visual_redesign/ENV_PLATE_ASSET_REQUIREMENTS.md).
Checks sizes, alpha, provenance, HUD-safe calm, prop slots, palette and texture budget on ACTUAL plate files only.
Exit 0 = all automatic checks pass (manual checks in the document still apply), 1 = failures, 2 = no plates delivered (BLOCKED)."""
import argparse, json, sys
from pathlib import Path
import numpy as np
from PIL import Image
S = 1.5                      # delivery scale: 1 logical px = 1.5 delivered px (standard tier); the lower-memory "lite" tier uses 1.0 (--scale 1.0)
MIP = 4.0 / 3.0              # budget accounting assumes full mipmaps (Godot generates them when used with mipmapped filtering)
CAM_MAX = 1220.0             # world 2500 - screen 1280
# name: (factor, logical_w, logical_h, logical_y0, has_alpha)
PLATES = {
 "plate_sky":        (0.03, 1500, 520, 0,   False),
 "plate_far":        (0.12, 1700, 480, 40,  True),
 "plate_mid":        (0.30, 1800, 410, 110, True),
 "plate_near":       (0.60, 2300, 460, 60,  True),
 "plate_street":     (1.00, 2500, 420, 300, True),
 "plate_foreground": (1.20, 2800, 140, 580, True),
}
PROP_TRAM = ("prop_tram_stalled", 700, 156, (635, 340))   # logical size and world top-left
CAMERAS = [0, 400, 800, 1220]
HUD_ZONES = {"objective panel": (24, 20, 440, 82), "exit/skip": (1106, 22, 150, 48), "touch stick": (36, 520, 180, 180), "act button": (1110, 586, 104, 104), "interaction prompt band": (0, 250, 1280, 70)}
SLOTS = {"relay slot": (1500, 380, 120, 125), "mural slot": (1790, 360, 140, 100), "breach slot": (2050, 330, 300, 160)}   # world coords on the street plate
MAX_LUM, MAX_TILE_STD = 0.42, 0.10
BUDGET_MB = 64.0
def lum(a): return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]
def tile_std(l, tile=24):
    h, w = (l.shape[0] // tile) * tile, (l.shape[1] // tile) * tile
    if h == 0 or w == 0: return 0.0
    t = l[:h, :w].reshape(h // tile, tile, w // tile, tile).std(axis=(1, 3))
    return float(t.mean())
def hsv(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx, mn = rgb.max(-1), rgb.min(-1); d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-6
    rr = m & (mx == r); gg = m & (mx == g) & ~rr; bb = m & ~rr & ~gg
    h[rr] = ((g - b)[rr] / d[rr]) % 6; h[gg] = (b - r)[gg] / d[gg] + 2; h[bb] = (r - g)[bb] / d[bb] + 4
    return (h * 60.0) % 360.0, np.where(mx > 0, d / np.maximum(mx, 1e-6), 0.0), mx
def load(d, name):
    p = Path(d) / (name + ".png")
    return Image.open(p).convert("RGBA") if p.exists() else None
def composite(plates, tram, cam):
    W, H = int(1280 * S), int(720 * S)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    def put(im, f, ox_world, y0):
        # plate pixel x (delivered) visible at screen x = plate_x - f*cam*S ; world props use f=1
        sx = int(round((ox_world - f * cam) * S)); sy = int(round(y0 * S))
        canvas.alpha_composite(im, (sx, sy)) if (0 <= sx and sx + im.width <= W) else _paste_clipped(canvas, im, sx, sy)
    for name in ("plate_sky", "plate_far", "plate_mid", "plate_near", "plate_street"):
        f, _, _, y0, _ = PLATES[name]; put(plates[name], f, 0, y0)
    if tram is not None: put(tram, 1.0, PROP_TRAM[3][0], PROP_TRAM[3][1])
    f, _, _, y0, _ = PLATES["plate_foreground"]; put(plates["plate_foreground"], f, 0, y0)
    return np.asarray(canvas.convert("RGB"), dtype=np.float32) / 255.0
def _paste_clipped(canvas, im, sx, sy):
    W, H = canvas.size
    x0, y0 = max(sx, 0), max(sy, 0); x1, y1 = min(sx + im.width, W), min(sy + im.height, H)
    if x1 <= x0 or y1 <= y0: return
    canvas.alpha_composite(im.crop((x0 - sx, y0 - sy, x1 - sx, y1 - sy)), (x0, y0))
SKY_MAX_RESAMPLE = 1.10      # owner policy: only the independent Aether Storm Sky may be resampled up, by at most 10%
GUTTER_MAX = 4               # a plate may not start or end with more than this many fully empty columns
def edge_gutters(al):
    cols = (al > 8).any(axis=0)
    if not cols.any(): return al.shape[1], al.shape[1]
    idx = np.nonzero(cols)[0]
    return int(idx[0]), int(al.shape[1] - 1 - idx[-1])
def check_provenance(n, pv, size, issues, notes):
    """Enforces the artwork policy on a plate's provenance. size = delivered (w, h)."""
    status = str(pv.get("status", "")).upper()
    if any(t in status for t in ("REVIEW_ONLY", "REFERENCE", "NOT_PRODUCTION", "ASSISTED")):
        issues.append(f"{n}: provenance status '{pv.get('status')}' is not a production status")
    if pv.get("independent_plate") is not True or pv.get("method") in (None, "split_from_flat_image") or not pv.get("tool"):
        issues.append(f"{n}: provenance must state tool, method and independent_plate=true (a plate cut out of a flattened concept is not accepted)")
    res = pv.get("resolution")
    orig = pv.get("original_dimensions")
    W, H = size
    valid_orig = isinstance(orig, (list, tuple)) and len(orig) == 2 and all(isinstance(v, (int, float)) and v > 0 for v in orig)
    if res not in ("native", "resampled_up"):
        issues.append(f"{n}: provenance 'resolution' must be \"native\" (or, for plate_sky only, \"resampled_up\")")
        return
    if not valid_orig:
        issues.append(f"{n}: provenance original_dimensions [width, height] of the generated source is required (it is how native resolution is verified)")
        return
    if res == "native":
        if valid_orig:
            ow, oh = orig
            if ow < W or oh < H:
                issues.append(f"{n}: provenance says native but the source {int(ow)}x{int(oh)} is smaller than the delivered {W}x{H} (upscaling is not native)")
            elif not _cover_crop_ok(ow, oh, W, H):
                issues.append(f"{n}: the artwork was stretched or cropped by more than 3% (source {int(ow)}x{int(oh)} -> {W}x{H}); only uniform scaling is allowed")
        return
    # resampled_up: only plate_sky, with a full record
    if n != "plate_sky":
        issues.append(f"{n}: resampled enlargement is not allowed for this plate (only the independent sky may be resampled; this plate must be native or downscaled)")
        return
    need = ["resample_factor", "original_dimensions", "tool", "source"]
    miss = [k for k in need if not pv.get(k)]
    if miss: issues.append(f"{n}: resampled sky provenance missing {', '.join(miss)}")
    if pv.get("owner_approved_resample") is not True: issues.append(f"{n}: resampled sky requires owner_approved_resample=true in its provenance")
    if miss: return
    ow, oh = orig
    f = max(W / ow, H / oh)
    stated = pv.get("resample_factor")
    if not isinstance(stated, (int, float)) or abs(stated - f) > 0.005:
        issues.append(f"{n}: stated resample_factor {stated} does not match the actual factor {f:.4f} ({int(ow)}x{int(oh)} -> {W}x{H})")
    if f <= 1.0: issues.append(f"{n}: marked resampled_up but the actual factor is {f:.4f} (not an enlargement)")
    if f > SKY_MAX_RESAMPLE + 1e-9: issues.append(f"{n}: resample factor {f:.4f} exceeds the approved 10% maximum")
    if not _cover_crop_ok(ow, oh, W, H): issues.append(f"{n}: the sky was stretched or cropped by more than 3% (source {int(ow)}x{int(oh)} -> {W}x{H}); only uniform scaling is allowed")
    notes.append(f"{n}: RESAMPLED up {f:.3f}x from {int(ow)}x{int(oh)} (owner-approved); this is NOT native resolution")
def _cover_crop_ok(ow, oh, W, H):
    f = max(W / ow, H / oh)
    cw, ch = ow * f - W, oh * f - H
    return -1.5 <= cw <= 0.03 * W and -1.5 <= ch <= 0.03 * H
def validate_sky(d):
    """Individual checks for plate_sky.png alone (the full set is validated separately): size, opacity, provenance policy, palette, HUD-safe zones above y=520."""
    global S
    issues, notes = [], []
    d = Path(d)
    im = load(d, "plate_sky")
    if im is None: return None, ["BLOCKED: plate_sky.png not found in " + str(d)], notes
    f, lw, lh, y0, _ = PLATES["plate_sky"]
    exp = (int(lw * S), int(lh * S))
    if im.size != exp: issues.append(f"plate_sky: size {im.size}, expected exactly {exp[0]}x{exp[1]}")
    a = np.asarray(im)
    if (a[..., 3] < 255).any(): issues.append("plate_sky: must be fully opaque")
    prov = d / "plate_sky.provenance.json"
    if not prov.exists(): issues.append("plate_sky: provenance file plate_sky.provenance.json missing")
    else:
        try: pv = json.loads(prov.read_text())
        except Exception: pv = {}
        check_provenance("plate_sky", pv, im.size, issues, notes)
    rgb = a[..., :3].astype(np.float32) / 255.0
    H_, S_, V_ = hsv(rgb); lit = (S_ > 0.25) & (V_ > 0.35)
    if lit.sum() == 0: issues.append("palette: no lit coloured pixels")
    else:
        hh = H_[lit]; n = lit.sum()
        bv, mg, gd, rd = [(((hh >= lo) & (hh < hi)).sum() / n) for lo, hi in ((200, 300), (300, 345), (25, 65))] + [(((hh >= 345) | (hh < 25)).sum() / n)]
        notes.append(f"palette share: blue-violet {bv:.0%}, magenta {mg:.0%}, warm gold {gd:.0%}, red/orange {rd:.0%}")
        if bv < 0.55: issues.append(f"palette: blue-violet share {bv:.0%} < 55%")
        if mg > 0.22: issues.append(f"palette: magenta share {mg:.0%} > 22%")
        if gd > 0.12: issues.append(f"palette: warm gold share {gd:.0%} > 12%")
        if rd > 0.08: issues.append(f"palette: red/orange share {rd:.0%} > 8%")
    L = lum(rgb)
    worst = {}
    for cam in CAMERAS:
        off = int(round(f * cam * S))
        for zn, (x, y, w, h) in HUD_ZONES.items():
            if y + h > lh: continue            # zones below the sky's rows (stick, ACT) are covered by other plates
            z = L[int(y * S):int((y + h) * S), off + int(x * S):off + int((x + w) * S)]
            ml, ts = float(z.mean()), tile_std(z)
            lim = 0.55 if "prompt" in zn else MAX_LUM   # the interaction prompt pill has its own opaque panel: the contract limits only the brightness of that band, not its detail
            worst[zn] = (max(worst.get(zn, (0, 0))[0], ml), max(worst.get(zn, (0, 0))[1], ts))
            if ml > lim or (ts > MAX_TILE_STD and "prompt" not in zn): issues.append(f"camera {cam}: HUD zone '{zn}' too bright or busy (mean {ml:.2f} > {lim} or detail {ts:.3f} > {MAX_TILE_STD})")
    for zn, (ml, ts) in worst.items(): notes.append(f"HUD zone '{zn}': worst mean {ml:.2f}, worst detail {ts:.3f} over cameras {CAMERAS}")
    return (not issues), issues, notes
def validate(d, budget_mb=BUDGET_MB, scale=None):
    global S
    if scale is not None: S = scale
    issues, notes = [], []
    d = Path(d)
    plates = {n: load(d, n) for n in PLATES}
    missing = [n + ".png" for n, im in plates.items() if im is None]
    if len(missing) == len(PLATES):
        return None, ["BLOCKED: no environment plates delivered in " + str(d)], notes
    for n in missing: issues.append(f"{n}: file missing")
    budget = 0
    for n, (f, lw, lh, y0, alpha) in PLATES.items():
        im = plates[n]
        if im is None: continue
        exp = (int(lw * S), int(lh * S))
        if im.size != exp: issues.append(f"{n}: size {im.size}, expected exactly {exp[0]}x{exp[1]} (logical {lw}x{lh} at {S}x)")
        budget += im.width * im.height * 4
        a = np.asarray(im)
        al = a[..., 3]
        if not alpha and (al < 255).any(): issues.append(f"{n}: must be fully opaque")
        if alpha:
            if al.mean() < 25: issues.append(f"{n}: almost fully transparent (mean alpha {al.mean():.0f})")
            band = al[:, :8], al[:, -8:]
            if n != "plate_foreground" and n != "plate_sky":
                for side, b in zip(("left", "right"), band):
                    if b.mean() < 20: issues.append(f"{n}: {side} edge is empty; the plate must cover the whole pan range")
            if n in ("plate_far", "plate_mid", "plate_near", "plate_street"):
                gl, gr = edge_gutters(al)
                if gl > GUTTER_MAX or gr > GUTTER_MAX:
                    issues.append(f"{n}: transparent gutter of {gl}px left / {gr}px right (limit {GUTTER_MAX}); the artwork must cover the full width, without horizontal stretching or upscaling to get there")
            key = (al > 8) & (a[..., 1] > 215) & (a[..., 0] < 40) & (a[..., 2] < 40)
            if key.any(): issues.append(f"{n}: leftover #00FF00 key colour")
        prov = d / (n + ".provenance.json")
        if not prov.exists(): issues.append(f"{n}: provenance file {n}.provenance.json missing")
        else:
            try: pv = json.loads(prov.read_text())
            except Exception: pv = {}
            check_provenance(n, pv, im.size, issues, notes)
    tram = load(d, PROP_TRAM[0])
    if tram is not None:
        exp = (int(PROP_TRAM[1] * S), int(PROP_TRAM[2] * S))
        if tram.size != exp: issues.append(f"{PROP_TRAM[0]}: size {tram.size}, expected {exp}")
        budget += tram.width * tram.height * 4
        tp = d / (PROP_TRAM[0] + ".provenance.json")
        if not tp.exists(): issues.append(f"{PROP_TRAM[0]}: provenance file missing")
        else:
            try: tv = json.loads(tp.read_text())
            except Exception: tv = {}
            check_provenance(PROP_TRAM[0], tv, tram.size, issues, notes)
    mb = budget * MIP / 1048576.0
    if mb > budget_mb: issues.append(f"texture budget: {mb:.1f} MB decoded RGBA exceeds {budget_mb:.0f} MB")
    notes.append(f"decoded texture total {mb:.1f} MB incl. mipmaps ({budget / 1048576.0:.1f} MB base level), budget {budget_mb:.0f} MB, scale {S}x")
    if issues: return False, issues, notes
    # composite checks
    hist = np.zeros(4); total = 0
    for cam in CAMERAS:
        frame = composite(plates, tram, cam)
        L = lum(frame)
        for zn, (x, y, w, h) in HUD_ZONES.items():
            z = L[int(y * S):int((y + h) * S), int(x * S):int((x + w) * S)]
            ml, ts = float(z.mean()), tile_std(z)
            lim = 0.55 if "prompt" in zn else MAX_LUM   # the interaction prompt pill has its own opaque panel: the contract limits only the brightness of that band, not its detail
            if ml > lim or (ts > MAX_TILE_STD and "prompt" not in zn): issues.append(f"camera {cam}: HUD zone '{zn}' too bright or busy (mean {ml:.2f} > {lim} or detail {ts:.3f} > {MAX_TILE_STD})")
        H_, S_, V_ = hsv(frame)
        lit = (S_ > 0.25) & (V_ > 0.35)
        if lit.sum() > 0:
            hh = H_[lit]
            hist += np.array([((hh >= 200) & (hh < 300)).sum(), ((hh >= 300) & (hh < 345)).sum(), ((hh >= 25) & (hh < 65)).sum(), ((hh >= 345) | (hh < 25)).sum()])
            total += lit.sum()
    if total == 0: issues.append("palette: no lit coloured pixels found")
    else:
        bv, mg, gd, rd = hist / total
        notes.append(f"palette share: blue-violet {bv:.0%}, magenta {mg:.0%}, warm gold {gd:.0%}, red/orange {rd:.0%}")
        if bv < 0.55: issues.append(f"palette: blue-violet share {bv:.0%} < 55%")
        if mg > 0.22: issues.append(f"palette: magenta share {mg:.0%} > 22%")
        if gd > 0.12: issues.append(f"palette: warm gold share {gd:.0%} > 12%")
        if rd > 0.08: issues.append(f"palette: red/orange share {rd:.0%} > 8%")
    st = plates["plate_street"]
    sa = np.asarray(st).astype(np.float32) / 255.0
    for zn, (x, y, w, h) in SLOTS.items():
        x0, y0, x1, y1 = int(x * S), int((y - 300) * S), int((x + w) * S), int((y - 300 + h) * S)
        z = sa[y0:y1, x0:x1]; zl = lum(z[..., :3] * z[..., 3:4])
        if float(zl.mean()) > 0.30 or tile_std(zl) > 0.07: issues.append(f"street plate: {zn} (code-drawn prop) is too bright or busy")
    return (not issues), issues, notes
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default="assets/environment/neon_district")
    ap.add_argument("--budget-mb", type=float, default=BUDGET_MB)
    ap.add_argument("--scale", type=float, default=1.5, help="1.5 = standard tier (default), 1.0 = lite lower-memory tier")
    ap.add_argument("--only", choices=["plate_sky"], help="run only the individual checks of one plate (the full set must still be validated before production)")
    a = ap.parse_args()
    if a.only == "plate_sky":
        ok, issues, notes = validate_sky(a.dir)
        for n in notes: print("note:", n)
        if ok is None: print(issues[0]); print("RESULT: BLOCKED"); return 2
        for i in issues: print("FAIL:", i)
        print("RESULT:", "SKY PASS (individual checks only; the full environment set is NOT validated; the sky is RESAMPLED, not native resolution)" if ok else "SKY FAIL")
        return 0 if ok else 1
    ok, issues, notes = validate(a.dir, a.budget_mb, a.scale)
    for n in notes: print("note:", n)
    if ok is None:
        print(issues[0]); print("RESULT: BLOCKED"); return 2
    for i in issues: print("FAIL:", i)
    print("RESULT:", "PASS (automatic checks; the manual checklist still applies; any RESAMPLED plate above is not native resolution)" if ok else "FAIL")
    return 0 if ok else 1
if __name__ == "__main__":
    sys.exit(main())
