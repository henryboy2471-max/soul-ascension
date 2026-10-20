#!/usr/bin/env python3
"""Self-test for tools/check_hero_turnaround.py with throw-away synthetic fixtures (temp dir only; geometric blocks, not artwork)."""
import shutil, subprocess, sys, tempfile
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parent.parent
def fig(offset=0, w=380, cw=1152):
    im = Image.new("RGBA", (cw, 2304), (0, 0, 0, 0)); c = cw // 2
    ImageDraw.Draw(im).rectangle([c - w // 2 + offset, 176, c + w // 2 + offset, 2176], fill=(90, 70, 40, 255))
    return im
def run(d, *extra):
    r = subprocess.run([sys.executable, str(ROOT / "tools/check_hero_turnaround.py"), "--dir", str(d), *extra], capture_output=True, text=True)
    return r.returncode, r.stdout
def main():
    bad = 0
    def expect(label, cond):
        nonlocal bad; print(("PASS" if cond else "FAIL") + ": " + label); bad += 0 if cond else 1
    t = Path(tempfile.mkdtemp())
    try:
        for i, v in enumerate(("front", "right", "back", "left")):
            fig(offset=i * 3, w=380 + i * 10).save(t / f"hero_turnaround_{v}_native.png")
        for s in ("hero_face_detail_sheet.png", "hero_costume_detail_sheet.png"):
            Image.new("RGB", (2048, 1024), (20, 20, 20)).save(t / s)
        rc, out = run(t); expect("conformant synthetic set passes", rc == 0)
        Image.new("RGBA", (464, 881), (0, 0, 0, 0)).save(t / "hero_turnaround_front_native.png")
        rc, out = run(t); expect("reference-sized (non-native) render is rejected", rc == 1 and "must be exactly 1152x2304" in out)
        fig(offset=300).save(t / "hero_turnaround_front_native.png")
        rc, out = run(t); expect("off-centre feet / edge clipping is rejected", rc == 1 and ("foot" in out or "edge" in out))
        fig(w=1102).save(t / "hero_turnaround_front_native.png")
        rc, out = run(t); expect("exactly 24 px side margin passes", "edge" not in out)
        fig(w=1106).save(t / "hero_turnaround_front_native.png")
        rc, out = run(t); expect("23 px side margin is rejected", rc == 1 and "within 24px of the canvas edge" in out)
        fig().save(t / "hero_turnaround_front_native.png"); (t / "hero_face_detail_sheet.png").unlink()
        rc, out = run(t); expect("missing detail sheet is rejected", rc == 1 and "hero_face_detail_sheet" in out)
    finally:
        shutil.rmtree(t, ignore_errors=True)
    # ---- the owner-approved 1280x2304 profile (opt-in; the default profile above is unchanged)
    t = Path(tempfile.mkdtemp())
    try:
        P = ("--profile", "1280")
        for i, v in enumerate(("front", "right", "back", "left")):
            fig(offset=i * 3, w=380 + i * 10, cw=1280).save(t / f"hero_turnaround_{v}_native.png")
        for s in ("hero_face_detail_sheet.png", "hero_costume_detail_sheet.png"):
            Image.new("RGB", (2048, 1024), (20, 20, 20)).save(t / s)
        rc, out = run(t, *P); expect("1280 profile: conformant 1280x2304 set passes", rc == 0)
        rc, out = run(t); expect("default profile still rejects 1280-wide files (gate not loosened)", rc == 1 and "must be exactly 1152x2304" in out)
        fig(cw=1152).save(t / "hero_turnaround_front_native.png")
        rc, out = run(t, *P); expect("1280 profile rejects a 1152-wide file", rc == 1 and "must be exactly 1280x2304" in out)
        fig(w=1230, cw=1280).save(t / "hero_turnaround_front_native.png")
        rc, out = run(t, *P); expect("1280 profile: figure with exactly 24 px side margins passes (same geometry as the legacy 1102 px case)", rc == 0)
        fig(w=1234, cw=1280).save(t / "hero_turnaround_front_native.png")
        rc, out = run(t, *P); expect("1280 profile: figure with 23 px side margins is rejected", rc == 1 and "within 24px of the canvas edge" in out)
        fig(offset=200, w=400, cw=1280).save(t / "hero_turnaround_front_native.png")
        rc, out = run(t, *P); expect("1280 profile: feet 200 px off x=640 are rejected", rc == 1 and "foot" in out)
        fig(offset=-64, w=400, cw=1280).save(t / "hero_turnaround_front_native.png")
        rc, out = run(t, *P); expect("1280 profile: feet at x=576 (64 px off, inside the 90 px tolerance) still pass the foot check", "foot" not in out)
    finally:
        shutil.rmtree(t, ignore_errors=True)
    rc, out = run(ROOT / "assets/approved_anime/source/hero")
    expect("repository itself is BLOCKED (no native renders exist)", rc == 1)
    print("RESULT:", "ALL PASS" if not bad else f"{bad} FAILED"); return 1 if bad else 0
if __name__ == "__main__":
    raise SystemExit(main())
