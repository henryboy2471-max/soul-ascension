# Free art pipeline proposal (Hollow Cantor) - DRAFT, awaiting owner approval

Status: feasibility only. No pipeline implemented. v2 branch (`art/hollow-cantor-v2`) untouched.

## Environment facts (verified in this sandbox)
- 4 CPU, 16 GB RAM, no GPU. Hugging Face is blocked, PyPI works.
- `bpy` 5.2.2 (Blender as a Python module) installs from PyPI; EEVEE renders under `xvfb-run` with software GL. ~14-19 s for one 640 px frame (CPU only).

## Options
1. Blender toon 3D -> sprite frames (original geometry, scripted, fully offline). Output is ours; Blender's license does not claim rendered output.
2. Local diffusion (SDXL / FLUX schnell, ControlNet/img2img). NOT runnable here (no GPU, model downloads blocked). Possible only on the owner's own machine. Caveats: model license terms, uncertain copyright status of AI output, store policies on AI content, style consistency across animation frames is hard.
3. Improve current procedural 2D painter (v2). Works today, already integrated; ceiling is its flat/hard-edged look.

## Prototype result (see images in docs/art/free_pipeline_proposal/)
Honest assessment: the first Blender prototype (`tools/blender/cantor_proto.py`) is NOT yet at Hero/Shade quality and currently reads worse than v2: chess-piece-like robe stack, no visible bell halo glow, no bloom, Phase 2 wings do not read, no visible mask detail. It proves the toolchain (toon shading, outlines, rim light, transparent PNG output) works headless; it does not yet prove the visual target is reachable. Reaching it would need substantial modelling, a compositing/bloom pass, hand-tuned materials and a rig for animation.

## Recommendation (open to debate)
Hybrid: keep v2 as the shipping baseline, use Blender only as a lighting/volume pass that is composited with 2D painted detail (halo, mask, bloom, wings stay 2D/VFX where they already look better). Do not expect a pure 3D render to beat v2 without significant extra work. Diffusion should be an optional owner-run experiment only.

## Android budget (plan, not yet measured)
Render at ~half current resolution, trim transparent borders, lazy-load Phase 2 frames, ETC2/ASTC import. Current v2 is ~63 MB uncompressed texture memory for 64 frames.
