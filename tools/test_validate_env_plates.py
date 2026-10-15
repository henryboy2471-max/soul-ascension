#!/usr/bin/env python3
"""Self-test for tools/validate_env_plates.py with throw-away synthetic fixtures (temp dir only; flat colour fields, NOT artwork)."""
import json, shutil, subprocess, sys, tempfile
from pathlib import Path
import numpy as np
from PIL import Image
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import validate_env_plates as V
COL = {"plate_sky": (0.30, 0.25, 0.75), "plate_far": (0.28, 0.24, 0.62), "plate_mid": (0.25, 0.22, 0.55), "plate_near": (0.22, 0.18, 0.50), "plate_street": (0.20, 0.15, 0.50), "plate_foreground": (0.18, 0.15, 0.45)}
def plate(name, size=None, alpha=None, scale=1.5):
    f, lw, lh, y0, has_alpha = V.PLATES[name]
    w, h = size or (int(lw * scale), int(lh * scale))
    rng = np.random.default_rng(1)
    rgb = np.array(COL[name]) * 255 + rng.normal(0, 4, (h, w, 3))
    a = np.full((h, w, 1), 255 if (alpha is None) else alpha, dtype=np.float32)
    return Image.fromarray(np.concatenate([np.clip(rgb, 0, 255), a], -1).astype(np.uint8), "RGBA")
def write_set(d, **over):
    d = Path(d); d.mkdir(parents=True, exist_ok=True)
    for n in V.PLATES:
        im = over.get(n) or plate(n)
        im.save(d / f"{n}.png")
        (d / f"{n}.provenance.json").write_text(json.dumps({"tool": "synthetic test fixture", "method": "native_generation", "independent_plate": True, "resolution": "native", "original_dimensions": list(im.size)}))
def run(d, *extra):
    r = subprocess.run([sys.executable, str(ROOT / "tools/validate_env_plates.py"), "--dir", str(d), *extra], capture_output=True, text=True)
    return r.returncode, r.stdout
def main():
    bad = 0
    def expect(label, cond):
        nonlocal bad; print(("PASS" if cond else "FAIL") + ": " + label); bad += 0 if cond else 1
    base = Path(tempfile.mkdtemp())
    try:
        d = base / "ok"; write_set(d)
        rc, out = run(d); expect("conformant synthetic set passes", rc == 0 and "PASS" in out)
        import hashlib
        def assembled(d, **kw):
            write_set(d); d = Path(d); (d / "reference").mkdir(exist_ok=True)
            Image.fromarray(np.zeros((900, 2000, 4), np.uint8) + 5, "RGBA").save(d / "reference/p.png")
            pv = {"tool": "synthetic", "method": "assembled_from_native_source_panels", "independent_plate": True, "resolution": "assembled_native", "mosaic_dimensions": [2550, 720], "final_crop_px": [0, 0],
                  "components": [{"file": "reference/p.png", "sha256": hashlib.sha256((d / "reference/p.png").read_bytes()).hexdigest(), "original_dimensions": [2000, 900], "scale": 0.8, "scaled_dimensions": [1600, 720]}]}
            pv.update(kw); (d / "plate_far.provenance.json").write_text(json.dumps(pv)); return d
        d = assembled(base / "asm_ok"); rc, out = run(d); expect("an assembled plate with verified components passes", rc == 0 and "assembled from 1 native" in out)
        d = assembled(base / "asm_up", components=[{"file": "reference/p.png", "sha256": "0", "original_dimensions": [2000, 900], "scale": 1.2, "scaled_dimensions": [2400, 1080]}]); rc, out = run(d); expect("an assembled plate with an upscaled component is rejected", rc == 1 and "upscaling is not allowed" in out)
        d = assembled(base / "asm_sha", components=[{"file": "reference/p.png", "sha256": "0" * 64, "original_dimensions": [2000, 900], "scale": 0.8, "scaled_dimensions": [1600, 720]}]); rc, out = run(d); expect("an assembled plate whose component hash does not match is rejected", rc == 1 and "sha256 does not match" in out)
        d = assembled(base / "asm_crop", mosaic_dimensions=[2700, 720], final_crop_px=[150, 0]); rc, out = run(d); expect("an assembled plate cropped more than 3% at the end is rejected", rc == 1 and "exceeds 3%" in out)
        d = assembled(base / "asm_single", method="single_generation"); rc, out = run(d); expect("an assembly claiming a single generation is rejected", rc == 1 and "assembled_from_native" in out)
        d = base / "empty"; d.mkdir(); rc, out = run(d); expect("no plates delivered is BLOCKED (exit 2)", rc == 2 and "BLOCKED" in out)
        d = base / "size"; write_set(d, plate_far=plate("plate_far", (100, 100))); rc, out = run(d); expect("wrong plate size is rejected", rc == 1 and "plate_far: size" in out)
        d = base / "missing"; write_set(d); (d / "plate_mid.png").unlink(); rc, out = run(d); expect("a missing plate is rejected", rc == 1 and "plate_mid.png: file missing" in out)
        d = base / "prov"; write_set(d); (d / "plate_near.provenance.json").unlink(); rc, out = run(d); expect("missing provenance is rejected", rc == 1 and "plate_near: provenance" in out)
        d = base / "split"; write_set(d); (d / "plate_far.provenance.json").write_text(json.dumps({"tool": "x", "method": "split_from_flat_image", "independent_plate": False})); rc, out = run(d); expect("a plate cut out of a flat concept is rejected", rc == 1 and "plate_far: provenance" in out)
        d = base / "opaque"; write_set(d, plate_sky=plate("plate_sky", alpha=200)); rc, out = run(d); expect("a translucent sky is rejected", rc == 1 and "plate_sky: must be fully opaque" in out)
        # busy bright objective-panel zone in the sky plate
        sky = plate("plate_sky"); a = np.asarray(sky).copy(); a[45:230, 36:700, :3] = (np.indices((185, 664)).sum(0) // 6 % 2 * 255)[..., None]; d = base / "hud"; write_set(d, plate_sky=Image.fromarray(a, "RGBA"))
        rc, out = run(d); expect("a bright busy HUD-safe zone is rejected", rc == 1 and "HUD zone 'objective panel'" in out)
        green = plate("plate_street"); g = np.asarray(green).copy(); g[..., :3] = (0.1 * 255, 0.6 * 255, 0.2 * 255); d = base / "green"; write_set(d, plate_street=Image.fromarray(g, "RGBA"))
        rc, out = run(d); expect("an off-palette (green) set is rejected", rc == 1 and "palette" in out)
        key = plate("plate_far"); k = np.asarray(key).copy(); k[100:140, 100:140] = (0, 255, 0, 255); d = base / "key"; write_set(d, plate_far=Image.fromarray(k, "RGBA"))
        rc, out = run(d); expect("leftover #00FF00 matte is rejected", rc == 1 and "#00FF00" in out)
        edge = plate("plate_near"); e = np.asarray(edge).copy(); e[:, :40, 3] = 0; d = base / "edge"; write_set(d, plate_near=Image.fromarray(e, "RGBA"))
        rc, out = run(d); expect("an empty left edge (gap in the pan range) is rejected", rc == 1 and "plate_near: left edge is empty" in out)
        st = plate("plate_street"); s2 = np.asarray(st).copy(); s2[int((380 - 300) * 1.5):int((380 - 300 + 125) * 1.5), int(1500 * 1.5):int(1620 * 1.5), :3] = 255; d = base / "slot"; write_set(d, plate_street=Image.fromarray(s2, "RGBA"))
        rc, out = run(d); expect("a bright relay slot (competes with the code-drawn prop) is rejected", rc == 1 and "relay slot" in out)
        # ---- owner policy (sky may be resampled up <= 10% with a full record; the skyline stays strict) ----
        def prov(d, n, **kw):
            base_p = json.loads((d / f"{n}.provenance.json").read_text()); base_p.update(kw)
            (d / f"{n}.provenance.json").write_text(json.dumps(base_p))
        ok_sky = dict(resolution="resampled_up", resample_factor=1.0568, original_dimensions=[2129, 739], tool="OpenAI image generator", source="a_wide_cinematic_ultra_detailed_sci_fi_fantasy_s.png", owner_approved_resample=True)
        d = base / "skyok"; write_set(d); prov(d, "plate_sky", **ok_sky)
        rc, out = run(d); expect("an owner-approved sky resample (1.0568x, full record) passes and is reported as RESAMPLED, not native", rc == 0 and "RESAMPLED up 1.057x" in out and "NOT native" in out)
        d = base / "sky12"; write_set(d); prov(d, "plate_sky", **{**ok_sky, "resample_factor": 1.12, "original_dimensions": [2009, 697]})
        rc, out = run(d); expect("a sky enlargement above 10% is rejected", rc == 1 and "exceeds the approved 10%" in out)
        d = base / "skynoappr"; write_set(d); prov(d, "plate_sky", **{**ok_sky, "owner_approved_resample": False})
        rc, out = run(d); expect("a resampled sky without owner approval is rejected", rc == 1 and "owner_approved_resample" in out)
        d = base / "skymiss"; write_set(d); prov(d, "plate_sky", **{**ok_sky, "source": "", "tool": ""})
        rc, out = run(d); expect("a resampled sky with an incomplete record (tool, source) is rejected", rc == 1 and "missing" in out)
        d = base / "skyfactor"; write_set(d); prov(d, "plate_sky", **{**ok_sky, "resample_factor": 1.02})
        rc, out = run(d); expect("a stated resample factor that does not match the real dimensions is rejected", rc == 1 and "does not match the actual factor" in out)
        d = base / "skystretch"; write_set(d); prov(d, "plate_sky", **{**ok_sky, "original_dimensions": [2250, 700], "resample_factor": 1.114})
        rc, out = run(d); expect("a stretched or heavily cropped sky is rejected", rc == 1)
        d = base / "farup"; write_set(d); prov(d, "plate_far", resolution="resampled_up", resample_factor=1.05, original_dimensions=[2429, 686], owner_approved_resample=True)
        rc, out = run(d); expect("the skyline may not be resampled up even with an approval flag", rc == 1 and "plate_far: resampled enlargement is not allowed" in out)
        d = base / "farnative_up"; write_set(d); prov(d, "plate_far", original_dimensions=[1983, 793])
        rc, out = run(d); expect("a skyline claiming native from a smaller source (upscaling) is rejected", rc == 1 and "plate_far: provenance says native but the source" in out)
        d = base / "farnoorig"; write_set(d); prov(d, "plate_far", original_dimensions=None)
        rc, out = run(d); expect("a skyline without original_dimensions cannot prove native resolution and is rejected", rc == 1 and "original_dimensions" in out)
        d = base / "farstretch"; write_set(d); prov(d, "plate_far", original_dimensions=[2550, 900])
        rc, out = run(d); expect("a skyline stretched horizontally (source 2550x900 squeezed to 2550x720 shape change) is rejected", rc == 1 and "plate_far: the artwork was stretched" in out)
        far_ok = plate("plate_far"); fa = np.asarray(far_ok).copy(); fa[:, :375, 3] = 0; fa[:, -375:, 3] = 0
        d = base / "fargutter"; write_set(d, plate_far=Image.fromarray(fa, "RGBA"))
        rc, out = run(d); expect("transparent gutters (375 px each side, as in the assisted candidate) are rejected", rc == 1 and "transparent gutter" in out)
        d = base / "farassisted"; write_set(d); prov(d, "plate_far", status="ASSISTED_REVIEW_ONLY_NOT_PRODUCTION", independent_plate=False)
        rc, out = run(d); expect("an ASSISTED_REVIEW_ONLY / independent_plate=false skyline is rejected", rc == 1 and "not a production status" in out and "independent_plate=true" in out)
        d = base / "farlarger"; write_set(d); prov(d, "plate_far", original_dimensions=[3060, 864])
        rc, out = run(d); expect("a skyline downscaled from a larger native source is accepted", rc == 0)
        d = base / "midup"; write_set(d); prov(d, "plate_mid", resolution="resampled_up", resample_factor=1.05, original_dimensions=[2571, 586], owner_approved_resample=True)
        rc, out = run(d); expect("no other plate may be resampled up", rc == 1 and "plate_mid: resampled enlargement is not allowed" in out)
        # ---- individual sky checks (--only plate_sky) ----
        d = base / "skyonly"; d.mkdir(); plate("plate_sky").save(d / "plate_sky.png")
        (d / "plate_sky.provenance.json").write_text(json.dumps({"tool": "t", "method": "uniform_lanczos_resample_crop_bottom_1px", "independent_plate": True, "resolution": "resampled_up", "resample_factor": 1.05683419, "original_dimensions": [2129, 739], "source": "src.png", "owner_approved_resample": True}))
        rc, out = run(d, "--only", "plate_sky"); expect("the individual sky checks pass for a conforming resampled sky and say the set is NOT validated", rc == 0 and "SKY PASS" in out and "NOT validated" in out and "RESAMPLED" in out)
        skyb = plate("plate_sky"); a2 = np.asarray(skyb).copy(); a2[45:230, 36:700, :3] = (np.indices((185, 664)).sum(0) // 6 % 2 * 255)[..., None]
        d = base / "skybusy"; d.mkdir(); Image.fromarray(a2, "RGBA").save(d / "plate_sky.png"); (d / "plate_sky.provenance.json").write_text((base / "skyonly" / "plate_sky.provenance.json").read_text())
        rc, out = run(d, "--only", "plate_sky"); expect("the individual sky checks reject a bright busy HUD zone", rc == 1 and "HUD zone" in out)
        skyp = plate("plate_sky"); a3 = np.asarray(skyp).copy(); a3[int(255 * 1.5):int(315 * 1.5), :, :3] = (np.indices((90, a3.shape[1])).sum(0) // 4 % 2 * 90 + 30)[..., None]   # busy but dark band
        d = base / "skyprompt_dark"; d.mkdir(); Image.fromarray(a3, "RGBA").save(d / "plate_sky.png"); (d / "plate_sky.provenance.json").write_text((base / "skyonly" / "plate_sky.provenance.json").read_text())
        rc, out = run(d, "--only", "plate_sky"); expect("the interaction-prompt band is limited by brightness only: busy but dark passes", rc == 0)
        a4 = a3.copy(); a4[int(255 * 1.5):int(315 * 1.5), :, :3] = 255
        d = base / "skyprompt_bright"; d.mkdir(); Image.fromarray(a4, "RGBA").save(d / "plate_sky.png"); (d / "plate_sky.provenance.json").write_text((base / "skyonly" / "plate_sky.provenance.json").read_text())
        rc, out = run(d, "--only", "plate_sky"); expect("a bright interaction-prompt band is still rejected", rc == 1 and "interaction prompt band" in out)
        d = base / "skyunappr"; d.mkdir(); plate("plate_sky").save(d / "plate_sky.png"); (d / "plate_sky.provenance.json").write_text(json.dumps({**json.loads((base / "skyonly" / "plate_sky.provenance.json").read_text()), "owner_approved_resample": False}))
        rc, out = run(d, "--only", "plate_sky"); expect("the individual sky checks reject an unapproved resample", rc == 1 and "owner_approved_resample" in out)
        d = base / "ok"; rc, out = run(d, "--budget-mb", "5"); expect("the texture budget is enforced", rc == 1 and "texture budget" in out)
        rc, out = run(base / "ok"); expect("the standard 1.5x set stays under the 64 MB ceiling (about 56 MB with mipmaps)", rc == 0 and "scale 1.5x" in out)
        d = base / "lite"; write_set(d, **{n: plate(n, scale=1.0) for n in V.PLATES})
        rc, out = run(d, "--scale", "1.0"); expect("the lite (1.0x) lower-memory tier validates at --scale 1.0", rc == 0 and "scale 1.0x" in out)
        rc, out = run(d); expect("a lite-size set is rejected by the standard tier (exact sizes)", rc == 1 and "expected exactly" in out)
    finally:
        shutil.rmtree(base, ignore_errors=True)
    rc, out = run(ROOT / "assets/environment/neon_district")
    sky_there = (ROOT / "assets/environment/neon_district/plate_sky.png").exists()
    expect("the repository set is NOT production-ready: " + ("only plate_sky exists, the other six plates are reported missing" if sky_there else "no plates exist yet (BLOCKED)"),
           (rc == 1 and "plate_far.png: file missing" in out and "PASS" not in out) if sky_there else rc == 2)
    if sky_there:
        rc, out = run(ROOT / "assets/environment/neon_district", "--only", "plate_sky"); expect("the delivered repository plate_sky.png passes its individual checks (RESAMPLED, set not validated)", rc == 0 and "SKY PASS" in out and "NOT validated" in out)
    print("RESULT:", "ALL PASS" if not bad else f"{bad} FAILED"); return 1 if bad else 0
if __name__ == "__main__":
    raise SystemExit(main())
