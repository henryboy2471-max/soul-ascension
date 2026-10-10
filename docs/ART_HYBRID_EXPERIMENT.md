# Hollow Cantor hybrid (Blender + 2D) experiment - result

Branch `art/hollow-cantor-hybrid-proto` (off `art/free-pipeline-proposal`, off v2). No game code, combat, data or shipping assets changed. Experiment files: `tools/blender/cantor_hybrid_body.py` (Blender: body, depth, shadows, lighting, matte passes, anchors), `tools/blender/cantor_hybrid_comp.py` (2D: painterly pass, ink/rim, face paint, bell halo + bloom, Phase 2 wings, motes), `tests/capture_hybrid_lineup.gd`, `tools/blender/hybrid_report.py`, images in `docs/art/hollow_cantor_hybrid_proto/`.

## Verdict: NOT clearly better than v2 -> stop Blender, improve the 2D pipeline
Better than v2: visible porcelain mask with painted eyes/brow/crack/sigil, solid readable anatomy and robe layering, a bell-shaped halo with a real bloom, a large Phase 2 wing silhouette.
Worse than v2 / not matching Hero+Shade: reads as a cel-shaded 3D doll; value structure is pale lavender while Hero/Shade are dark with saturated accents and dense painted detail; fold strokes look scratchy; wings read as generic striped angel wings; v2's aura integrates into the Soul Realm better. Hybrid frames also touch the canvas edge (alpha bbox y=1..449 at 450 px high) - fails v2's safe-margin rule without re-framing.

## Measured (single idle frame each; same canvas as v2: 495x450 / 600x450)
- Blender stage, Phase 1, 3 passes at 990x900 on 4 CPU software GL: ~68 s wall incl. startup; 2D stage ~5 s. Phase 2 not separately timed. 64 animated frames would be roughly 1-1.5 h of render time ([Inference] from the Phase 1 timing) plus rig/pose work that does not exist yet.
- PNG: 192 KB (P1) / 316 KB (P2) vs v2 167 KB / 257 KB.
- Texture memory, 64 frames at the same dimensions: 60.2 MB uncompressed RGBA (same as v2); ~48.6 MB if trimmed vs ~39.1 MB for v2; ASTC 6x6 trimmed ~5.4 MB vs ~4.3 MB ([Inference] arithmetic from bits-per-pixel, not measured on a device or in an Android export).
- Android performance was not measured; no device or emulator here.

## Recommendation
Improve v2's 2D pipeline: adopt the hybrid's face paint (mask instead of blank visor), a solid bell-halo fill + bloom, and a fuller Phase 2 wing silhouette; move the robe toward a darker base with luminous trim and torn hems like the Shade; add stronger painted texture. Reaching Hero/Shade's hand-painted detail density is [Unverified] possible with procedural code alone; a hand-painted source sheet or an owner-run local image model would need your approval.
