#!/usr/bin/env python3
"""Slice an animation sheet into normalized, foot-anchored, transparent frames.

Two phases (run slice once per sheet, then finalize once per character):

  slice_sheet.py slice SHEET.png --out assets/characters/hero --anim walk [--frames 8]
  slice_sheet.py finalize --out assets/characters/hero

slice    removes the background, finds frames by their gaps (rows, then columns), trims each frame,
         records its foot point, and stores the trimmed frames under <out>/_trimmed/ plus manifest entries.
finalize pads every trimmed frame of every animation onto ONE canvas so that the foot point sits at the same
         bottom-centre pixel in every frame (no jitter), writes <out>/frames/<anim>_<NN>.png and manifest.json.

Nothing is ever stretched, redrawn or invented. If a sheet cannot be split reliably the animation is marked
with warnings in the manifest ("flagged") and no frames are written for it unless --force is given.
"""
import argparse, json, os, sys
import numpy as np
from PIL import Image

ALPHA_THRESHOLD = 8


def load_rgba(path):
    return np.array(Image.open(path).convert("RGBA"))


def has_real_alpha(arr):
    a = arr[..., 3]
    return (a == 0).mean() > 0.02 and (a == 255).mean() > 0.005


def guess_background(arr):
    h, w = arr.shape[:2]
    # robust: median colour of a 2px border ring (panel interior is usually a flat plate)
    ring = np.concatenate([arr[:2, :, :3].reshape(-1, 3), arr[-2:, :, :3].reshape(-1, 3),
                           arr[:, :2, :3].reshape(-1, 3), arr[:, -2:, :3].reshape(-1, 3)])
    if h > 8 and w > 8:
        return np.median(ring, axis=0).astype(int)
    corners = np.array([arr[0, 0, :3], arr[0, w - 1, :3], arr[h - 1, 0, :3], arr[h - 1, w - 1, :3]], dtype=int)
    # most common corner colour (corners usually agree on a solid background)
    vals, counts = np.unique(corners, axis=0, return_counts=True)
    return vals[counts.argmax()]


def _propagate(reach, near, axis):
    """Spread `reach` along runs of `near` pixels in one axis (numpy-only flood-fill step)."""
    r = reach if axis == 1 else reach.T
    n = near if axis == 1 else near.T
    flat_n = n.ravel()
    starts = np.zeros_like(n, dtype=bool)
    starts[:, 0] = True
    boundary = (~flat_n) | starts.ravel()
    gid = np.cumsum(boundary)
    hit = np.bincount(gid, weights=r.ravel().astype(float), minlength=gid[-1] + 1) > 0
    out = (hit[gid] & flat_n).reshape(n.shape) | r
    return out if axis == 1 else out.T


def _dilate(mask, r):
    out = mask.copy()
    for _ in range(r):
        p = np.pad(out, 1)
        out = out | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return out


def _erode(mask, r):
    return ~_dilate(~mask, r)


def matte_background(arr, bg, lo, hi, band, opening=2, enclosed=0.0):
    """Safe matte for dark art on a dark flat background.
    1) Background core = pixels within `lo` of the background colour that are connected to the border.
    2) Only a thin `band` (px) around that core gets a soft alpha ramp between `lo` and `hi`, and the
       background colour is un-mixed from those edge pixels. Everything deeper inside stays fully opaque,
       so dark armour/pants that resemble the background are never punched out.
    """
    rgb = arr[..., :3].astype(float)
    dist = np.sqrt(((rgb - np.array(bg, dtype=float)) ** 2).sum(axis=2))
    near = dist <= lo
    if opening > 0:
        # opening removes hairline channels so the background cannot leak into dark armour of a similar colour
        near = _dilate(_erode(near, opening), opening)
    reach = np.zeros_like(near)
    reach[0, :], reach[-1, :], reach[:, 0], reach[:, -1] = near[0, :], near[-1, :], near[:, 0], near[:, -1]
    for _ in range(400):
        new = _propagate(_propagate(reach, near, 1), near, 0)
        if (new == reach).all():
            break
        reach = new
    core = reach
    edge = _dilate(core, band) & ~core
    alpha = np.ones(dist.shape)
    ramp = np.clip((dist - lo) / max(1e-6, hi - lo), 0.0, 1.0)
    alpha[edge] = ramp[edge]
    alpha[core] = 0.0
    out = arr.copy().astype(float)
    a = np.clip(alpha, 0.05, 1.0)[..., None]
    fix = edge & (alpha > 0.0) & (alpha < 1.0)
    unmixed = (rgb - (1 - a) * np.array(bg, dtype=float)) / a
    out[..., :3] = np.where(fix[..., None], np.clip(unmixed, 0, 255), rgb)
    if enclosed > 0:
        # pixels almost exactly the background colour that the opening protected (enclosed pockets between legs/cape)
        alpha = np.where(dist <= enclosed, 0.0, alpha)
    out[..., 3] = alpha * 255.0
    return out.round().astype(np.uint8), "matte"


def remove_background(arr, bg, tol, mode):
    """Return RGBA with the background made transparent. mode: border (flood from edges) or all."""
    if bg is None:
        return arr, "none"
    dist = np.sqrt(((arr[..., :3].astype(int) - np.array(bg)) ** 2).sum(axis=2))
    near = dist <= tol
    if mode == "all":
        bgmask = near
    else:
        reach = np.zeros_like(near)
        reach[0, :] = near[0, :]
        reach[-1, :] = near[-1, :]
        reach[:, 0] = near[:, 0]
        reach[:, -1] = near[:, -1]
        for _ in range(400):
            new = _propagate(_propagate(reach, near, 1), near, 0)
            if (new == reach).all():
                break
            reach = new
        bgmask = reach
    out = arr.copy()
    out[bgmask, 3] = 0
    # defringe: semi-background pixels touching transparency (anti-aliased halo)
    fringe = (~bgmask) & (dist <= tol * 2.2)
    pad = np.pad(bgmask, 1)
    touch = pad[:-2, 1:-1] | pad[2:, 1:-1] | pad[1:-1, :-2] | pad[1:-1, 2:]
    out[fringe & touch, 3] = 0
    return out, "removed"


def runs(profile, gap):
    """Index ranges of non-empty entries, merging ranges separated by fewer than `gap` empty entries."""
    idx = np.flatnonzero(profile)
    if idx.size == 0:
        return []
    out = []
    start = prev = idx[0]
    for i in idx[1:]:
        if i - prev > gap:
            out.append((start, prev + 1))
            start = i
        prev = i
    out.append((start, prev + 1))
    return out


def detect_frames(alpha, gap, min_area_ratio):
    mask = alpha > ALPHA_THRESHOLD
    boxes = []
    for y0, y1 in runs(mask.any(axis=1), gap):
        band = mask[y0:y1]
        for x0, x1 in runs(band.any(axis=0), gap):
            sub = mask[y0:y1, x0:x1]
            ys = np.flatnonzero(sub.any(axis=1))
            xs = np.flatnonzero(sub.any(axis=0))
            boxes.append((x0 + xs[0], y0 + ys[0], x0 + xs[-1] + 1, y0 + ys[-1] + 1, int(sub.sum())))
    if not boxes:
        return []
    median_area = float(np.median([b[4] for b in boxes]))
    return [b for b in boxes if b[4] >= median_area * min_area_ratio]


def merge_to_count(boxes, target):
    """Merge neighbouring boxes (smallest horizontal gap first) until `target` remain. Same row only."""
    boxes = [list(b) for b in boxes]
    while len(boxes) > target:
        best = None
        for i in range(len(boxes) - 1):
            a, b = boxes[i], boxes[i + 1]
            same_row = min(a[3], b[3]) - max(a[1], b[1]) > 0
            gap = b[0] - a[2]
            if same_row and (best is None or gap < best[0]):
                best = (gap, i)
        if best is None:
            break
        i = best[1]
        a, b = boxes[i], boxes[i + 1]
        boxes[i:i + 2] = [[min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]), a[4] + b[4]]]
    return [tuple(b) for b in boxes]


def keep_main_components(mask, min_ratio):
    """8-connected components; keep those with area >= min_ratio * largest. Returns keep-mask."""
    h, w = mask.shape
    label = np.zeros((h, w), dtype=np.int32)
    sizes = []
    cur = 0
    for sy, sx in zip(*np.nonzero(mask)):
        if label[sy, sx]:
            continue
        cur += 1
        stack = [(sy, sx)]
        label[sy, sx] = cur
        n = 0
        while stack:
            y, x = stack.pop()
            n += 1
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and not label[yy, xx]:
                        label[yy, xx] = cur
                        stack.append((yy, xx))
        sizes.append(n)
    if not sizes:
        return mask
    big = max(sizes)
    keep_ids = [i + 1 for i, n in enumerate(sizes) if n >= big * min_ratio]
    return np.isin(label, keep_ids)


def valley_cuts(alpha, n, search=0.38):
    """Cut positions for n equal-ish cells, nudged to the emptiest column near each expected boundary."""
    h, w = alpha.shape
    profile = (alpha > ALPHA_THRESHOLD).sum(axis=0).astype(float)
    k = np.ones(5) / 5.0
    smooth = np.convolve(profile, k, mode="same")
    cuts = [0]
    cell = w / n
    for i in range(1, n):
        centre = int(round(i * cell))
        lo, hi = max(cuts[-1] + 8, int(centre - cell * search)), min(w - 8, int(centre + cell * search))
        cuts.append(int(lo + np.argmin(smooth[lo:hi + 1])) if hi > lo else centre)
    cuts.append(w)
    return cuts


def strip_floor_line(crop, max_rows=4):
    """Remove a thin dark panel-floor line stuck to the bottom of a frame."""
    alpha = crop[..., 3] > ALPHA_THRESHOLD
    h, w = alpha.shape
    removed = 0
    for y in range(h - 1, max(h - 1 - max_rows, 0), -1):
        row = alpha[y]
        lum = crop[y, :, :3].astype(float).mean(axis=1)
        if row.sum() >= 0.5 * w and lum[row].mean() < 85:
            crop[y, :, 3] = 0
            removed += 1
        else:
            break
    return crop


def head_width(frame_alpha):
    """Width of the top slice of the silhouette (the head for upright/leaning poses): a scale reference."""
    mask = frame_alpha > ALPHA_THRESHOLD
    ys = np.flatnonzero(mask.any(axis=1))
    top, bottom = ys[0], ys[-1] + 1
    band = mask[top: top + max(3, int((bottom - top) * 0.12))]
    xs = np.flatnonzero(band.any(axis=0))
    return int(xs[-1] - xs[0] + 1) if xs.size else 0


def foot_point(frame_alpha):
    h, w = frame_alpha.shape
    mask = frame_alpha > ALPHA_THRESHOLD
    ys = np.flatnonzero(mask.any(axis=1))
    bottom = ys[-1] + 1
    band_top = max(ys[0], bottom - max(2, int(round((bottom - ys[0]) * 0.08))))
    xs = np.flatnonzero(mask[band_top:bottom].any(axis=0))
    if xs.size == 0:
        xs = np.flatnonzero(mask.any(axis=0))
    return float(xs.mean()) + 0.5, int(bottom)


def load_manifest(out):
    path = os.path.join(out, "manifest.json")
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return {"character": os.path.basename(out.rstrip("/")), "animations": {}}


def save_manifest(out, data):
    with open(os.path.join(out, "manifest.json"), "w") as f:
        json.dump(data, f, indent=1, sort_keys=True)


def cmd_slice(args):
    arr = load_rgba(args.sheet)
    if args.region:
        x0, y0, x1, y1 = [int(v) for v in args.region.split(",")]
        arr = arr[y0:y1, x0:x1].copy()
    warnings = []
    if has_real_alpha(arr):
        bg_note = "alpha"
    else:
        bg = None
        if args.bg == "auto":
            bg = guess_background(arr)
        elif args.bg != "none":
            bg = [int(args.bg[i:i + 2], 16) for i in (1, 3, 5)]
        if args.bg_mode == "matte" and bg is not None:
            arr, bg_note = matte_background(arr, bg, args.tol, args.tol_hi, args.band, args.opening, args.enclosed)
        else:
            arr, bg_note = remove_background(arr, bg, args.tol, args.bg_mode)
    boxes = detect_frames(arr[..., 3], args.gap, args.min_area_ratio)
    if args.grid:
        rows, cols = [int(v) for v in args.grid.lower().split("x")]
        h, w = arr.shape[:2]
        boxes = []
        xcuts = valley_cuts(arr[..., 3], cols) if (args.valley and rows == 1) else [c * w // cols for c in range(cols + 1)]
        for r in range(rows):
            for c in range(cols):
                x0, y0, x1, y1 = xcuts[c], r * h // rows, xcuts[c + 1], (r + 1) * h // rows
                sub = arr[y0:y1, x0:x1, 3] > ALPHA_THRESHOLD
                if sub.any():
                    ys, xs = np.flatnonzero(sub.any(axis=1)), np.flatnonzero(sub.any(axis=0))
                    boxes.append((x0 + xs[0], y0 + ys[0], x0 + xs[-1] + 1, y0 + ys[-1] + 1, int(sub.sum())))
    elif args.frames and len(boxes) > args.frames:
        boxes = merge_to_count(boxes, args.frames)
        warnings.append("frames were merged to reach the requested count; check them by eye")
    if args.frames and len(boxes) != args.frames:
        warnings.append(f"expected {args.frames} frames but found {len(boxes)}")
    if boxes:
        heights = [b[3] - b[1] for b in boxes]
        widths = [b[2] - b[0] for b in boxes]
        if max(widths) > 1.8 * float(np.median(widths)) and not args.grid:
            warnings.append("one or more frames are much wider than the rest (touching or overlapping frames?)")
        if max(heights) > 1.6 * float(np.median(heights)) and args.ground == "frame":
            warnings.append("frame heights vary a lot; if this is a jump/air animation use --ground row")
    # reading order: group by row, then left to right
    row_height = max(1.0, float(np.median([bb[3] - bb[1] for bb in boxes]))) if boxes else 1.0
    boxes.sort(key=lambda b: (round((b[1] + b[3]) / 2 / row_height), b[0]))
    flagged = (not boxes) or (args.frames and len(boxes) != args.frames and not args.force)
    trimmed = os.path.join(args.out, "_trimmed")
    os.makedirs(trimmed, exist_ok=True)
    for old in os.listdir(trimmed):
        if old.startswith(args.anim + "_"):
            os.remove(os.path.join(trimmed, old))
    manifest = load_manifest(args.out)
    entry = {"fps": args.fps, "loop": args.loop == "true", "ground": args.ground, "source": os.path.basename(args.sheet),
             "background": bg_note, "warnings": warnings, "flagged": bool(flagged), "frames": [], "scale_like": args.scale_like}
    if flagged:
        entry["warnings"].append("FLAGGED: not used in the game until fixed or --force is given")
    else:
        for n, (x0, y0, x1, y1, _) in enumerate(boxes):
            crop = arr[y0:y1, x0:x1].copy()
            if args.floor_strip:
                crop = strip_floor_line(crop)
            if args.speck > 0:
                keep = keep_main_components(crop[..., 3] > ALPHA_THRESHOLD, args.speck)
                crop[~keep, 3] = 0
                ys, xs = np.flatnonzero(keep.any(axis=1)), np.flatnonzero(keep.any(axis=0))
                crop = crop[ys[0]:ys[-1] + 1, xs[0]:xs[-1] + 1]
                x1, y1 = x0 + xs[-1] + 1, y0 + ys[-1] + 1
                x0, y0 = x0 + xs[0], y0 + ys[0]
            fx, fy = foot_point(crop[..., 3])
            name = f"{args.anim}_{n:02d}.png"
            Image.fromarray(crop).save(os.path.join(trimmed, name))
            entry["frames"].append({"file": name, "foot_x": float(fx), "bottom": int(fy), "w": int(x1 - x0), "h": int(y1 - y0),
                                    "head_w": head_width(crop[..., 3])})
    manifest["animations"][args.anim] = entry
    os.makedirs(args.out, exist_ok=True)
    save_manifest(args.out, manifest)
    print(f"{args.anim}: {len(entry['frames'])} frames" + (" FLAGGED" if flagged else ""))
    for w in entry["warnings"]:
        print("  warning:", w)
    return 0


def cmd_flag(args):
    manifest = load_manifest(args.out)
    manifest["animations"][args.anim] = {"fps": 10.0, "loop": True, "ground": "frame", "source": args.source or "",
                                         "background": "n/a", "warnings": [args.reason], "flagged": True, "frames": [],
                                         "scale_like": None}
    os.makedirs(args.out, exist_ok=True)
    save_manifest(args.out, manifest)
    print(f"{args.anim}: FLAGGED - {args.reason}")
    return 0


def cmd_finalize(args):
    manifest = load_manifest(args.out)
    trimmed = os.path.join(args.out, "_trimmed")
    anims = {k: v for k, v in manifest["animations"].items() if v["frames"] and not v["flagged"]}
    if not anims:
        print("nothing to finalize")
        return 1
    pad = args.pad
    # --- scale normalisation: every animation is brought to the reference animation's head width (uniform resize) ---
    factors = {}
    ref = None
    if args.ref_anim and args.ref_anim in anims:
        ref = float(np.median([f["head_w"] for f in anims[args.ref_anim]["frames"] if f.get("head_w")]))
    for name, entry in anims.items():
        widths = [f["head_w"] for f in entry["frames"] if f.get("head_w")]
        factors[name] = 1.0
        if ref and widths and not entry.get("scale_like"):
            factors[name] = float(np.clip(ref / float(np.median(widths)), 0.5, 2.5))
    for name, entry in anims.items():
        like = entry.get("scale_like")
        if like and like in factors:
            factors[name] = factors[like]
        entry["scale"] = round(factors[name], 4)
    placed = {}
    half, above, below = 0.0, 0.0, 0.0
    for name, entry in anims.items():
        k = factors[name]
        bottoms = [f["bottom"] * k for f in entry["frames"]]
        baseline = float(max(bottoms)) if entry["ground"] == "row" else None
        placed[name] = []
        for f in entry["frames"]:
            fx, bot, h, w = f["foot_x"] * k, f["bottom"] * k, f["h"] * k, f["w"] * k
            ground_y = bot if baseline is None else baseline
            half = max(half, fx, w - fx)
            above = max(above, ground_y)
            below = max(below, h - ground_y)
            placed[name].append((f, ground_y, k, fx))
    width = int(np.ceil(half * 2)) + pad * 2
    if width % 2:
        width += 1
    height = int(np.ceil(above + max(below, 0))) + pad * 2
    ground_row = int(np.ceil(above)) + pad
    out_frames = os.path.join(args.out, "frames")
    os.makedirs(out_frames, exist_ok=True)
    for old in os.listdir(out_frames):
        if old.endswith(".png"):
            os.remove(os.path.join(out_frames, old))
    for name, items in placed.items():
        manifest["animations"][name]["frames_out"] = []
        for n, (f, ground_y, k, fx) in enumerate(items):
            img = Image.open(os.path.join(trimmed, f["file"])).convert("RGBA")
            if abs(k - 1.0) > 1e-3:
                img = img.resize((max(1, round(img.width * k)), max(1, round(img.height * k))), Image.LANCZOS)
            canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
            x = int(round(width / 2 - fx))
            y = int(round(ground_row - ground_y))
            canvas.paste(img, (x, y), img)
            fname = f"{name}_{n:02d}.png"
            canvas.save(os.path.join(out_frames, fname))
            manifest["animations"][name]["frames_out"].append(fname)
    manifest["canvas"] = [width, height]
    manifest["ground_row"] = ground_row
    manifest["pad"] = pad
    manifest["ref_anim"] = args.ref_anim
    save_manifest(args.out, manifest)
    flagged = [k for k, v in manifest["animations"].items() if v["flagged"] or not v["frames"]]
    print(f"canvas {width}x{height}, ground row {ground_row}, animations: {', '.join(anims)}")
    print("scale factors:", {k: round(v, 3) for k, v in factors.items()})
    if flagged:
        print("flagged (not exported):", ", ".join(flagged))
    return 0


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("slice")
    s.add_argument("sheet")
    s.add_argument("--out", required=True)
    s.add_argument("--anim", required=True)
    s.add_argument("--frames", type=int, default=0, help="expected frame count (warns if different)")
    s.add_argument("--region", help="x0,y0,x1,y1 sub-rectangle of the sheet to use (one animation panel)")
    s.add_argument("--valley", action="store_true", help="1xN grid: cut at the emptiest column near each boundary")
    s.add_argument("--floor-strip", action="store_true", help="remove a thin dark floor line under each frame")
    s.add_argument("--grid", help="force a ROWSxCOLS grid instead of gap detection, e.g. 2x4")
    s.add_argument("--bg", default="auto", help="auto, none, or #rrggbb (ignored if the sheet already has alpha)")
    s.add_argument("--bg-mode", default="border", choices=["border", "all", "matte"])
    s.add_argument("--tol-hi", type=float, default=26.0, help="matte: full-opacity distance")
    s.add_argument("--opening", type=int, default=2, help="matte: background opening radius (blocks leaks into dark art)")
    s.add_argument("--enclosed", type=float, default=0.0, help="matte: also clear enclosed pixels this close to the background colour")
    s.add_argument("--band", type=int, default=2, help="matte: soft edge width in pixels")
    s.add_argument("--tol", type=float, default=28.0)
    s.add_argument("--gap", type=int, default=3, help="empty pixels that separate two frames")
    s.add_argument("--speck", type=float, default=0.04, help="drop disconnected pieces smaller than this fraction of the largest piece (0 = keep all)")
    s.add_argument("--min-area-ratio", type=float, default=0.08)
    s.add_argument("--ground", default="frame", choices=["frame", "row"], help="row keeps vertical offsets (jump/air)")
    s.add_argument("--fps", type=float, default=10.0)
    s.add_argument("--loop", default="true", choices=["true", "false"])
    s.add_argument("--scale-like", help="use another animation's normalization factor (for poses where the head is not on top)")
    s.add_argument("--force", action="store_true")
    s.set_defaults(fn=cmd_slice)
    g = sub.add_parser("flag", help="record an animation as not reliably extractable (not exported)")
    g.add_argument("--out", required=True)
    g.add_argument("--anim", required=True)
    g.add_argument("--reason", required=True)
    g.add_argument("--source")
    g.set_defaults(fn=cmd_flag)
    f = sub.add_parser("finalize")
    f.add_argument("--out", required=True)
    f.add_argument("--pad", type=int, default=6)
    f.add_argument("--ref-anim", default="", help="normalise every animation to this animation's head width (uniform resize)")
    f.set_defaults(fn=cmd_finalize)
    args = p.parse_args()
    sys.exit(args.fn(args))


if __name__ == "__main__":
    main()
