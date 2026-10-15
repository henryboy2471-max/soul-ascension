#!/usr/bin/env python3
"""Self-test for tools/validate_approved_art.py using throw-away synthetic fixtures in a temp directory.
The fixtures are plain geometric test blocks used ONLY to exercise validation rules; they are never written into the repository
and are not artwork. Run: python3 tools/test_validate_approved_art.py"""
import json, shutil, sys, tempfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import validate_approved_art as v
from PIL import Image, ImageDraw, ImageFilter

def frame(shape="right", color=(200, 160, 40, 255)):
    im = Image.new("RGBA", (v.FRAME_W, v.FRAME_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    x0 = 170 if shape == "right" else 200   # deliberately not mirror-symmetric between right and left
    d.rectangle([x0, 120, x0 + 230, v.BASELINE_Y], fill=color)
    d.rectangle([x0 + 20, 60, x0 + 120, 120], fill=color)
    return im

def build(root: Path):
    for c in v.CHARACTERS:
        folder = root / "assets/approved_anime/characters" / c
        (folder / "frames").mkdir(parents=True)
        anims = {}
        for view in v.VIEWS:
            for kind, n in (("idle", v.IDLE_FRAMES), ("walk", v.WALK_FRAMES)):
                names = [f"{view}_{kind}_{i:02d}.png" for i in range(n)]
                for nm in names:
                    frame("left" if view == "left" else "right").save(folder / "frames" / nm)
                anims[f"{view}_{kind}"] = {"fps": 4 if kind == "idle" else 9, "loop": True, "flagged": False, "frames_out": names}
        (folder / "manifest.json").write_text(json.dumps({"animations": anims}))
        (folder / "anchor.json").write_text(json.dumps({"canvas": [576, 1152], "anchor_x": 288, "baseline_y": 1088, "height_px": 1000}))
        p = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0)); ImageDraw.Draw(p).ellipse([200, 100, 800, 900], fill=(120, 80, 60, 255)); p.save(folder / "portrait.png")
    env = root / "assets/approved_anime/environments/neon_district"
    env.mkdir(parents=True)
    def solid(w, h, transparent):
        im = Image.new("RGBA", (w, h), (30, 20, 60, 255))
        if transparent:
            ImageDraw.Draw(im).rectangle([0, 0, w, h // 2], fill=(0, 0, 0, 0))
        return im
    for f, (w, h, t) in v.ENV_SINGLE.items():
        solid(w, h, t).save(env / f)
    for base, (n, w, h, t) in v.ENV_TILED.items():
        for i in range(n):
            solid(w, h, t).save(env / f"{base}_{i}.png")

def run(root):
    return v.validate_character(root, "hero") + v.validate_character(root, "imani") + v.validate_environment(root)

def main():
    failures = 0
    def expect(label, cond):
        nonlocal failures
        print(("PASS" if cond else "FAIL") + ": " + label)
        failures += 0 if cond else 1
    tmp = Path(tempfile.mkdtemp())
    try:
        build(tmp)
        expect("conformant synthetic set passes", run(tmp) == [])
        hero = tmp / "assets/approved_anime/characters/hero/frames"
        env = tmp / "assets/approved_anime/environments/neon_district"
        def mutate(label, fn, needle):
            snapshot = tmp.with_name(tmp.name + "_m")
            shutil.copytree(tmp, snapshot)
            try:
                fn(snapshot)
                issues = run(snapshot)
                expect(label, any(needle in i for i in issues))
            finally:
                shutil.rmtree(snapshot)
        H = lambda r: r / "assets/approved_anime/characters/hero"
        E = lambda r: r / "assets/approved_anime/environments/neon_district"
        mutate("wrong frame size is rejected", lambda r: Image.new("RGBA", (500, 1000), (0, 0, 0, 0)).save(H(r) / "frames/front_idle_00.png"), "must be exactly 576x1152")
        mutate("RGB frame is rejected", lambda r: Image.new("RGB", (576, 1152), (0, 0, 0)).save(H(r) / "frames/front_walk_00.png"), "expected RGBA")
        mutate("opaque background is rejected", lambda r: Image.new("RGBA", (576, 1152), (10, 10, 10, 255)).save(H(r) / "frames/back_walk_01.png"), "corner pixels")
        mutate("key green remnant is rejected", lambda r: (lambda im: (ImageDraw.Draw(im).rectangle([200, 300, 260, 340], fill=(0, 255, 0, 255)), im.save(H(r) / "frames/back_walk_02.png")))(frame()), "key colour")
        mutate("baseline mismatch is rejected", lambda r: (lambda im: (ImageDraw.Draw(im).rectangle([170, 120, 400, 1000], fill=(200, 160, 40, 255)), im.save(H(r) / "frames/front_walk_03.png")))(Image.new("RGBA", (576, 1152), (0, 0, 0, 0))), "baseline")
        mutate("edge-clipped content is rejected", lambda r: (lambda im: (ImageDraw.Draw(im).rectangle([0, 120, 300, 1088], fill=(200, 160, 40, 255)), im.save(H(r) / "frames/right_walk_00.png")))(Image.new("RGBA", (576, 1152), (0, 0, 0, 0))), "frame edge")
        def five_walk(r):
            p = H(r) / "manifest.json"; m = json.loads(p.read_text()); m["animations"]["right_walk"]["frames_out"].pop(); p.write_text(json.dumps(m))
        mutate("five walk frames are rejected (need six)", five_walk, "frames_out must be exactly")
        def one_idle(r):
            p = H(r) / "manifest.json"; m = json.loads(p.read_text()); m["animations"]["back_idle"]["frames_out"].pop(); p.write_text(json.dumps(m))
        mutate("one idle frame is rejected (need two)", one_idle, "back_idle")
        def drop_left(r):
            p = H(r) / "manifest.json"; m = json.loads(p.read_text()); del m["animations"]["left_walk"]; p.write_text(json.dumps(m))
        mutate("missing left view is rejected (four views required)", drop_left, "missing animation left_walk")
        def mirror_left(r):
            from PIL import ImageOps
            for kind, n in (("idle", 2), ("walk", 6)):
                for i in range(n):
                    ImageOps.mirror(Image.open(H(r) / f"frames/right_{kind}_{i:02d}.png")).save(H(r) / f"frames/left_{kind}_{i:02d}.png")
        mutate("mirrored left frames are rejected", mirror_left, "exact mirror")
        mutate("soft blurred edges are rejected", lambda r: frame().filter(ImageFilter.GaussianBlur(7)).save(H(r) / "frames/front_idle_01.png"), "soft/fringed edge")
        mutate("small portrait is rejected", lambda r: Image.new("RGBA", (600, 600), (0, 0, 0, 0)).save(H(r) / "portrait.png"), "portrait smaller")
        mutate("missing mid tile is rejected", lambda r: (E(r) / "mid_buildings_1.png").unlink(), "missing mid_buildings_1.png")
        mutate("wrong tile size is rejected", lambda r: Image.new("RGBA", (3000, 784), (0, 0, 0, 0)).save(E(r) / "mid_buildings_0.png"), "must be exactly 3200x784")
        mutate("opaque foreground layer is rejected", lambda r: Image.new("RGBA", (3200, 1440), (9, 9, 9, 255)).save(E(r) / "foreground_2.png"), "real transparency")
        mutate("extra tile index is rejected", lambda r: shutil.copy(E(r) / "mid_buildings_0.png", E(r) / "mid_buildings_3.png"), "unexpected tile names")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    real = Path(__file__).resolve().parent.parent
    real_issues = run(real)
    expect("repository itself is still BLOCKED (no production art present)", len(real_issues) > 0)
    print("RESULT: %s" % ("ALL PASS" if failures == 0 else f"{failures} FAILED"))
    return 1 if failures else 0

if __name__ == "__main__":
    raise SystemExit(main())
