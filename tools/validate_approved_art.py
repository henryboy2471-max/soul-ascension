#!/usr/bin/env python3
"""Read-only readiness check for SOUL ASCENSION's approved anime art (Phase 2 contract).

Run from the project root:
    python3 tools/validate_approved_art.py --root .
Requires Pillow. Never generates fallback art, never modifies files, never runs Godot.
Passing this STATIC check proves structure only (sizes, counts, transparency, naming, anchors). It never proves the art looks right:
manual visual QA against the references and owner approval are still required (docs/demo25d/phase2/ARTWORK_VALIDATION_CHECKLIST.md).
Exit code 0 = static check passed, 1 = blocked.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path

FRAME_W, FRAME_H = 576, 1152
ANCHOR_X, BASELINE_Y = 288, 1088
IDLE_FRAMES, WALK_FRAMES = 2, 6
VIEWS = ("front", "right", "back", "left")          # four genuine views; left is NOT a mirror of right
CHARACTERS = ("hero", "imani")
PORTRAIT_MIN = 1024
MARGIN = 24
ALPHA_SOLID = 16                                      # alpha above this counts as "ink" for bbox/anchor checks
KEY_GREEN = (0, 255, 0)
BASELINE_TOL = 4
MAX_PARTIAL_ALPHA = 0.08   # share of non-zero pixels with 0<alpha<255; soft/enlarged mattes exceed this (the first Hero candidate measured ~0.13)
X_TOL = 6

# Tiled environment scheme: (base name, tile count, tile size (w, h), needs transparency). Tiles are <base>_0.png .. <base>_{n-1}.png.
# Coordinates are documented in docs/demo25d/phase2/PRODUCTION_ASSET_MANIFEST.md section 5 (1x engine px = 2x art px / 2).
ENV_SINGLE = {            # name -> (w, h, transparent)
    "sky.png": (2560, 1440, False),
    "far_skyline.png": (4640, 900, True),
}
ENV_TILED = {             # base -> (count, w, h, transparent)
    "mid_buildings": (3, 3200, 784, True),
    "street_floor": (3, 3200, 720, False),
    "foreground": (4, 3200, 1440, True),
}


def _open_rgba(path: Path):
    from PIL import Image
    image = Image.open(path)
    image.load()
    return image


def _transparency_issues(label: str, image) -> list[str]:
    issues = []
    if image.mode != "RGBA":
        return [f"{label}: expected RGBA, got {image.mode}"]
    alpha = image.getchannel("A")
    low, high = alpha.getextrema()
    if low > 0 or high == 0:
        issues.append(f"{label}: no useful transparent silhouette (alpha range {low}-{high})")
    w, h = image.size
    corners = [alpha.getpixel(p) for p in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))]
    if any(c > 0 for c in corners):
        issues.append(f"{label}: corner pixels are not transparent (opaque background or rectangle remnant)")
    px = image.load()
    step = max(1, min(w, h) // 256)
    for y in range(0, h, step):
        for x in range(0, w, step):
            r, g, b, a = px[x, y]
            if a > 8 and abs(r - KEY_GREEN[0]) < 40 and g > 215 and b < 40:
                issues.append(f"{label}: leftover #00FF00 key colour (matte not removed)")
                return issues
    return issues


def _frame_issues(label: str, path: Path) -> tuple[list[str], object]:
    try:
        image = _open_rgba(path)
    except (OSError, ValueError) as exc:
        return [f"{label}: unreadable PNG: {exc}"], None
    issues = []
    if image.size != (FRAME_W, FRAME_H):
        issues.append(f"{label}: must be exactly {FRAME_W}x{FRAME_H}, got {image.width}x{image.height}")
    issues += _transparency_issues(label, image)
    if image.mode == "RGBA":
        hist = image.getchannel("A").histogram()
        nonzero = sum(hist[1:])
        if nonzero:
            partial = sum(hist[1:255]) / nonzero
            if partial > MAX_PARTIAL_ALPHA:
                issues.append(f"{label}: soft/fringed edge, {partial:.1%} of the silhouette pixels are semi-transparent (max {MAX_PARTIAL_ALPHA:.0%}); re-matte or re-render at native resolution")
    if image.mode == "RGBA" and image.size == (FRAME_W, FRAME_H):
        bbox = image.getchannel("A").point(lambda v: 255 if v > ALPHA_SOLID else 0).getbbox()
        if bbox is None:
            issues.append(f"{label}: empty frame")
        else:
            left, top, right, bottom = bbox
            if left < MARGIN or top < MARGIN or FRAME_W - right < MARGIN:
                issues.append(f"{label}: content closer than {MARGIN}px to the frame edge (clipped coat/braids/accents?)")
            if abs(bottom - BASELINE_Y) > BASELINE_TOL:
                issues.append(f"{label}: lowest solid pixel at y={bottom}, planted sole must sit on baseline y={BASELINE_Y}+/-{BASELINE_TOL}")
            centre = (left + right) / 2.0
            # walk poses legitimately shift the silhouette (stride, coat sway); only flag gross drift
            if abs(centre - ANCHOR_X) > 90:
                issues.append(f"{label}: silhouette centre x={centre:.0f} far from anchor x={ANCHOR_X}")
    return issues, image


def validate_character(root: Path, name: str) -> list[str]:
    folder = root / "assets" / "approved_anime" / "characters" / name
    manifest_path = folder / "manifest.json"
    if not manifest_path.is_file():
        return [f"{name}: missing {manifest_path.relative_to(root)}"]
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (ValueError, OSError) as exc:
        return [f"{name}: manifest cannot be read: {exc}"]
    animations = manifest.get("animations")
    if not isinstance(animations, dict):
        return [f"{name}: manifest.animations must be an object"]
    try:
        import PIL  # noqa: F401
    except ImportError:
        return ["Pillow missing: install Pillow to check image dimensions and transparency"]
    issues: list[str] = []
    anchor_path = folder / "anchor.json"
    if not anchor_path.is_file():
        issues.append(f"{name}: missing anchor.json")
    else:
        try:
            anchor = json.loads(anchor_path.read_text(encoding="utf-8"))
            if anchor.get("canvas") != [FRAME_W, FRAME_H] or anchor.get("anchor_x") != ANCHOR_X or anchor.get("baseline_y") != BASELINE_Y:
                issues.append(f"{name}: anchor.json must declare canvas [{FRAME_W},{FRAME_H}], anchor_x {ANCHOR_X}, baseline_y {BASELINE_Y}")
        except (ValueError, OSError) as exc:
            issues.append(f"{name}: anchor.json unreadable: {exc}")
    loaded: dict[str, list] = {}
    for view in VIEWS:
        for kind, count in (("idle", IDLE_FRAMES), ("walk", WALK_FRAMES)):
            anim = f"{view}_{kind}"
            entry = animations.get(anim)
            if not isinstance(entry, dict):
                issues.append(f"{name}: missing animation {anim}")
                continue
            if entry.get("flagged"):
                issues.append(f"{name}/{anim}: flagged and not ready")
            expected = [f"{view}_{kind}_{i:02d}.png" for i in range(count)]
            frames = entry.get("frames_out")
            if frames != expected:
                issues.append(f"{name}/{anim}: frames_out must be exactly {expected}")
                continue
            fps = entry.get("fps")
            if not isinstance(fps, (int, float)) or fps <= 0:
                issues.append(f"{name}/{anim}: invalid fps")
            images = []
            for filename in expected:
                path = folder / "frames" / filename
                if not path.is_file():
                    issues.append(f"{name}/{anim}: missing {filename}")
                    continue
                frame_issues, image = _frame_issues(f"{name}/{anim}/{filename}", path)
                issues += frame_issues
                images.append(image)
            loaded[anim] = images
    # left must be genuinely drawn: reject an exact horizontal mirror of the right view
    try:
        from PIL import ImageOps
        for kind, count in (("idle", IDLE_FRAMES), ("walk", WALK_FRAMES)):
            right, left = loaded.get(f"right_{kind}", []), loaded.get(f"left_{kind}", [])
            for i in range(min(len(right), len(left))):
                if right[i] is not None and left[i] is not None and right[i].size == left[i].size and ImageOps.mirror(right[i]).tobytes() == left[i].tobytes():
                    issues.append(f"{name}/left_{kind}_{i:02d}.png: is an exact mirror of the right frame (asymmetric characters need a genuine left view)")
    except Exception as exc:  # pragma: no cover
        issues.append(f"{name}: mirror check failed: {exc}")
    portrait = folder / "portrait.png"
    if not portrait.is_file():
        issues.append(f"{name}: missing portrait.png")
    else:
        try:
            image = _open_rgba(portrait)
            if image.width < PORTRAIT_MIN or image.height < PORTRAIT_MIN:
                issues.append(f"{name}: portrait smaller than {PORTRAIT_MIN}x{PORTRAIT_MIN}")
            issues += _transparency_issues(f"{name}/portrait.png", image)
        except (OSError, ValueError) as exc:
            issues.append(f"{name}: unreadable portrait: {exc}")
    return issues


def validate_environment(root: Path) -> list[str]:
    env = root / "assets" / "approved_anime" / "environments" / "neon_district"
    issues: list[str] = []
    try:
        from PIL import Image
    except ImportError:
        return ["Pillow missing: install Pillow to check environment layers"]

    def check(path: Path, label: str, w: int, h: int, transparent: bool) -> None:
        if not path.is_file():
            issues.append(f"environment: missing {label}")
            return
        try:
            image = Image.open(path)
            image.load()
        except (OSError, ValueError) as exc:
            issues.append(f"environment/{label}: unreadable PNG: {exc}")
            return
        if image.size != (w, h):
            issues.append(f"environment/{label}: must be exactly {w}x{h}, got {image.width}x{image.height}")
        if transparent:
            if image.mode != "RGBA":
                issues.append(f"environment/{label}: expected RGBA, got {image.mode}")
            else:
                low, high = image.getchannel("A").getextrema()
                if low > 0 or high == 0:
                    issues.append(f"environment/{label}: layer must contain real transparency (alpha {low}-{high})")

    for fname, (w, h, transparent) in ENV_SINGLE.items():
        check(env / fname, fname, w, h, transparent)
    for base, (count, w, h, transparent) in ENV_TILED.items():
        found = sorted(p.name for p in env.glob(f"{base}_*.png")) if env.is_dir() else []
        expected = [f"{base}_{i}.png" for i in range(count)]
        extra = [f for f in found if f not in expected]
        if extra:
            issues.append(f"environment: unexpected tile names {extra}; expected exactly {expected}")
        for fname in expected:
            check(env / fname, fname, w, h, transparent)
    return issues


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path("."))
    args = parser.parse_args()
    root = args.root.resolve()
    problems: list[str] = []
    for name in CHARACTERS:
        problems.extend(validate_character(root, name))
    problems.extend(validate_environment(root))
    if problems:
        print("BLOCKED: Approved anime art is not ready for Godot integration:")
        for problem in problems:
            print(" - " + problem)
        return 1
    print("STATIC CHECK PASS: files meet the structural contract; manual visual QA against references 01/04/05, owner approval, Godot import and motion testing are still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
