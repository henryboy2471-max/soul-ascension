#!/usr/bin/env python3
"""Read-only readiness check for SOUL ASCENSION's approved anime art checkpoint.

Run from project root:
    python3 tools/validate_approved_art.py --root .
Requires Pillow: pip install Pillow
Never generates fallback art, modifies existing files, or deploys the game.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

REQUIRED_ANIMATIONS = ("front_idle", "front_walk", "side_idle", "side_walk", "back_idle", "back_walk")
CHARACTERS = ("hero", "imani")
MIN_SOURCE_WIDTH, MIN_SOURCE_HEIGHT = 288, 576


def validate_character(root: Path, name: str) -> list[str]:
    issues = []
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
        from PIL import Image
    except ImportError:
        return ["Pillow missing: install Pillow to check image dimensions and transparency"]
    for anim in REQUIRED_ANIMATIONS:
        entry = animations.get(anim)
        if not isinstance(entry, dict):
            issues.append(f"{name}: missing animation {anim}")
            continue
        if entry.get("flagged"):
            issues.append(f"{name}/{anim}: flagged and not ready")
        frames = entry.get("frames_out", [])
        if not isinstance(frames, list) or len(frames) < (5 if anim.endswith("walk") else 1):
            issues.append(f"{name}/{anim}: requires >=5 walk frames or >=1 idle frame")
            continue
        if not isinstance(entry.get("fps"), (int, float)) or entry["fps"] <= 0:
            issues.append(f"{name}/{anim}: invalid fps")
        for filename in frames:
            if not isinstance(filename, str) or Path(filename).name != filename or not filename.lower().endswith(".png"):
                issues.append(f"{name}/{anim}: unsafe or invalid frame filename {filename!r}")
                continue
            image_path = folder / "frames" / filename
            if not image_path.is_file():
                issues.append(f"{name}/{anim}: missing {filename}")
                continue
            try:
                with Image.open(image_path) as image:
                    if image.mode != "RGBA":
                        issues.append(f"{name}/{anim}/{filename}: expected RGBA, got {image.mode}")
                    if image.width < MIN_SOURCE_WIDTH or image.height < MIN_SOURCE_HEIGHT:
                        issues.append(f"{name}/{anim}/{filename}: too small ({image.width}x{image.height})")
                    if image.mode == "RGBA":
                        low, high = image.getchannel("A").getextrema()
                        if low > 0 or high == 0:
                            issues.append(f"{name}/{anim}/{filename}: no useful transparent silhouette")
            except (OSError, ValueError) as exc:
                issues.append(f"{name}/{anim}/{filename}: unreadable PNG: {exc}")
    portrait = folder / "portrait.png"
    if not portrait.is_file():
        issues.append(f"{name}: missing portrait.png")
    else:
        try:
            with Image.open(portrait) as image:
                if image.width < 512 or image.height < 512:
                    issues.append(f"{name}: portrait smaller than 512x512")
        except (OSError, ValueError) as exc:
            issues.append(f"{name}: unreadable portrait: {exc}")
    return issues


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path("."))
    args = parser.parse_args()
    root = args.root.resolve()
    problems = []
    for name in CHARACTERS:
        problems.extend(validate_character(root, name))
    environment = root / "assets" / "approved_anime" / "environments" / "neon_district"
    for name in ("far_skyline.png", "mid_buildings.png", "street_floor.png", "foreground.png"):
        if not (environment / name).is_file():
            problems.append(f"environment: missing {name}")
    if problems:
        print("BLOCKED: Approved anime art is not ready for Godot integration:")
        for problem in problems:
            print(" - " + problem)
        return 1
    print("STATIC CHECK PASS: Files meet minimal structure; manual visual QA, Godot import and motion testing are still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
