# Playable visual checkpoint — Phase A handoff

Branch: `chatgpt/approved-anime-art-integration`
Status: **NOT PLAYABLE YET**. This is a gated preparation checkpoint, not a completed Godot art swap.

## Work committed
- Art direction and source/asset contract: `docs/demo25d/CHATGPT_APPROVED_ART_INTEGRATION.md`
- Read-only readiness checker: `tools/validate_approved_art.py` (fails closed when missing PNGs/frames).

## Why gameplay integration is blocked
The approved images supplied in the ChatGPT conversation are composite concept/montage illustrations. They contain multiple character views and decorative backgrounds in one image, not clean, separate alpha-transparent walk frames. The approved city mockup includes a HUD and is not a layered map. The images therefore cannot safely be loaded as production sprites or a scrolling/occluding environment without additional artwork and cleanup.

## Staging layout (new only; do not overwrite the prototype)
```
assets/approved_anime/
  characters/
    hero/
      portrait.png
      manifest.json
      frames/
        front_idle_00.png
        front_walk_00.png ... front_walk_04.png
        side_idle_00.png
        side_walk_00.png ... side_walk_04.png
        back_idle_00.png
        back_walk_00.png ... back_walk_04.png
    imani/ (same layout)
  environments/neon_district/
    far_skyline.png
    mid_buildings.png
    street_floor.png
    foreground.png
```
Manifest uses the existing `build_spriteframes.gd` shape:
```json
{
  "animations": {
    "front_idle": {"fps": 4, "loop": true, "flagged": false, "frames_out": ["front_idle_00.png"]},
    "front_walk": {"fps": 8, "loop": true, "flagged": false, "frames_out": ["front_walk_00.png", "front_walk_01.png", "front_walk_02.png", "front_walk_03.png", "front_walk_04.png"]}
  }
}
```
Populate side/back idle/walk identically. Keep frame dimensions identical, preserve feet alignment, and use coherent art across all directions.

## Validation command (after staging genuine assets)
```sh
python3 -m pip install Pillow
python3 tools/validate_approved_art.py --root .
```
The checker intentionally fails until real transparent sprite frames and layer images are present. Passing the checker alone does not establish animation quality or gameplay readiness.

## Next safe implementation sequence
1. Extract/redraw approved concepts into consistent transparent character parts; create actual front/side/back idle and walk frames. **Do not just crop the concept montage into frames.**
2. Split the city painting into real environment layers, or produce layers individually; no HUD embedded in scrolling background.
3. Run readiness checker; inspect faces, eyes, nose shapes, anatomy, feet and sprite continuity at real screen size.
4. After all artwork is truly ready, add a separate `visual_checkpoint` Godot scene or an explicit dev-only feature flag. Load the approved `SpriteFrames` through the existing tooling. Preserve old scene and saves. Wire input, walk animation, NPC, depth, collision and dialogue.
5. Re-import in Godot 4.4, run existing regression tests and a **manual** 1280x720 comparison video/screenshots on keyboard and touch. Preserve original character logic/episode progression.
6. Present before/after images and a private local preview for owner review. STOP. No merge, production build, GitHub Pages publish, or deployment.

## Guardrails
- Do not spend Higgsfield/Claude credits without approval.
- No secret keys, keystore, or payments necessary.
- Do not claim source concepts are imported sprites.
- No automatic merge/deploy; no changes to `main`.
