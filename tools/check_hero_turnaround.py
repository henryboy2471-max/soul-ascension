#!/usr/bin/env python3
"""Read-only gate G2 check for the Hero's four NATIVE turnaround renders (before any rigging).
    python3 tools/check_hero_turnaround.py [--dir assets/approved_anime/source/hero]
Expects hero_turnaround_{front,right,back,left}_native.png (+ hero_face_detail_sheet.png, hero_costume_detail_sheet.png).
Structural only: passing never proves the art matches hero_reference_pack_v2 or looks good; the owner's visual approval is still required.
Exit 0 = structural pass, 1 = blocked."""
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image, ImageOps

W, H = 1152, 2304
FIG_H, HEAD_TOP, BASELINE = 2000, 176, 2176
TOL_TOP, TOL_BASE, MARGIN = 12, 8, 24  # side/top margin 48 -> 24 px: owner-approved (front at 2000 px is ~1095 px wide on a 1152 canvas)
FOOT_MID_X, FOOT_TOL = 576, 90
OPAQUE_MIN, SOFT_MAX = 0.90, 0.08
VIEWS = ("front", "right", "back", "left")
SHEETS = ("hero_face_detail_sheet.png", "hero_costume_detail_sheet.png")


def check_view(path: Path, view: str):
    label = f"{view}"
    if not path.is_file():
        return [f"{label}: missing {path.name}"], None
    try:
        im = Image.open(path); im.load()
    except (OSError, ValueError) as exc:
        return [f"{label}: unreadable: {exc}"], None
    issues = []
    if im.size != (W, H):
        issues.append(f"{label}: must be exactly {W}x{H} native render, got {im.width}x{im.height} (enlarged references are not accepted)")
    if im.mode != "RGBA":
        return issues + [f"{label}: expected RGBA, got {im.mode}"], None
    a = im.getchannel("A")
    hist = a.histogram(); nz = sum(hist[1:])
    if nz == 0:
        return issues + [f"{label}: empty image"], None
    if any(a.getpixel(p) > 0 for p in ((0, 0), (im.width - 1, 0), (0, im.height - 1), (im.width - 1, im.height - 1))):
        issues.append(f"{label}: corners not transparent")
    if hist[255] / nz < OPAQUE_MIN:
        issues.append(f"{label}: only {hist[255]/nz:.1%} of silhouette pixels are fully opaque (alpha 255); interiors must be opaque (min {OPAQUE_MIN:.0%})")
    soft = sum(hist[1:250]) / nz
    if soft > SOFT_MAX:
        issues.append(f"{label}: soft/fringed edges {soft:.1%} of silhouette pixels (max {SOFT_MAX:.0%})")
    px = im.load(); step = 4
    for y in range(0, im.height, step):
        for x in range(0, im.width, step):
            r, g, b, al = px[x, y]
            if al > 8 and g > 215 and r < 40 and b < 40:
                issues.append(f"{label}: leftover #00FF00 key colour"); y = im.height; break
        else:
            continue
        break
    bbox = a.point(lambda v: 255 if v > 16 else 0).getbbox()
    left, top, right, bottom = bbox
    if abs(top - HEAD_TOP) > TOL_TOP:
        issues.append(f"{label}: head top y={top}, expected {HEAD_TOP}+/-{TOL_TOP}")
    if abs(bottom - BASELINE) > TOL_BASE:
        issues.append(f"{label}: sole bottom y={bottom}, expected baseline {BASELINE}+/-{TOL_BASE}")
    if abs((bottom - top) - FIG_H) > 30:
        issues.append(f"{label}: figure height {bottom-top}px, expected ~{FIG_H}")
    if left < MARGIN or W - right < MARGIN or top < MARGIN:
        issues.append(f"{label}: content within {MARGIN}px of the canvas edge (clipping risk)")
    mask = a.point(lambda v: 255 if v > 16 else 0).crop((0, bottom - 40, W, bottom))
    mb = mask.getbbox()
    if mb:
        mid = (mb[0] + mb[2]) / 2
        if abs(mid - FOOT_MID_X) > FOOT_TOL:
            issues.append(f"{label}: planted-foot midpoint x={mid:.0f}, expected {FOOT_MID_X}+/-{FOOT_TOL} (anchor on feet/pelvis, not the bounding box)")
    return issues, (im, bottom - top)


def main() -> int:
    ap = argparse.ArgumentParser(); ap.add_argument("--dir", type=Path, default=Path("assets/approved_anime/source/hero"))
    d = ap.parse_args().dir
    problems, loaded = [], {}
    for v in VIEWS:
        iss, res = check_view(d / f"hero_turnaround_{v}_native.png", v)
        problems += iss
        if res: loaded[v] = res
    if len(loaded) == 4:
        heights = [h for _, h in loaded.values()]
        if max(heights) - min(heights) > 20:
            problems.append(f"views differ in figure height by {max(heights)-min(heights)}px (max 20): scale must be identical")
        if ImageOps.mirror(loaded["right"][0]).tobytes() == loaded["left"][0].tobytes():
            problems.append("left is an exact mirror of right (must be genuinely drawn)")
    for s in SHEETS:
        p = d / s
        if not p.is_file():
            problems.append(f"missing {s}")
        else:
            try:
                w, h = Image.open(p).size
                if max(w, h) < 2048:
                    problems.append(f"{s}: long side {max(w,h)} < 2048")
            except (OSError, ValueError) as exc:
                problems.append(f"{s}: unreadable: {exc}")
    if problems:
        print("BLOCKED: Hero native turnaround is not ready (gate G2, structural):")
        for p in problems: print(" - " + p)
        return 1
    print("STRUCTURAL PASS for gate G2. Still required: visual match to hero_reference_pack_v2 (face, eyes, hair, costume, emblem), consistency across views, and owner approval before rigging.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
