# Hollow Cantor v2.1 - art upgrade (awaiting owner visual approval; NOT merged)

Branch `art/hollow-cantor-v2.1` (off `art/hollow-cantor-v2` d96e701). Episode 2 RC branch untouched. No Blender, no paid services, no Episode 3.
v2 is preserved: git branch `art/hollow-cantor-v2`, and a runtime-loadable copy at `assets/enemies/hollow_cantor_v2/` (own `frames.tres` + `phase2/frames.tres`; excluded from exports via `export_presets.cfg`). To fall back, point `frames`/`phase2.frames` in `scripts/missions/mission_defs.gd` at that folder.

## What changed (tools/gen_hollow_cantor.py only; same 64 frames, same animation names/fps/loop, same canvas 495x450 / 600x450)
1. Face/mask: porcelain mask kept pale, painted almond eyes with glowing slits, brow, nose, mouth seam, tear/hairline resonance cracks, glowing bell-diamond forehead sigil (all frames, intensity follows the existing eye/glow pose values).
2. Halo/Phase 2: brighter bell halo (interior wash, wide + tight bloom, small hanging bells). Phase 2: outer halo ring fractured into drifting segments; feathered wings replaced by angular fractured energy blades with void cores and hot magenta tips, echo copies, broken sound-wave arcs, waveform lines, a void membrane tying them into one silhouette, and broken bell fragments.
3. Palette: dark indigo cloth foundation, saturated violet accents, luminous silver trim, layered sheer panels, torn hems (deterministic per plate so frames do not flicker).
4. Painterly: calmer paint-dab variation instead of scratchy grain, deeper hem shadows, S-curve contrast, uniform ink contours on every cloth shape, broad+tight rim light, stronger bloom; porcelain/silver stay luminous.

## Verification (all run on this branch)
- Headless suites: adventure 30, boss_transform 27, cantor_sprites 18 (safe margins kept; one fix: top fade lengthened 36->42 px so Phase 2 top margin is >=24 px; test now decompresses VRAM textures before reading pixels), enforcer 17, episode2 38, episode3 67, episode4 32, episode_defs 24, hero 18, layout_overflow 15, mira 14, phase1 34, release_candidate 37, repairs 13, shade 17, sprites 16, ui_polish 24, live_combat manual+auto PASS, sprite pipeline/slice tests pass. 0 failures.
- Chromium (web export of this branch, seeded save): keyboard 1280x720, touch 844x390, touch 667x375 each: Phase 2 and Mira once (transform count 1, support count 1), Mira line starts after the banner clears (gap 257-331 ms), no overlaps, energy 60->54 once, rewards 800 gold/150 XP once (no duplicates), Codex unlocked, MEND works on touch, console clean, Phase 2 art path `phase2/frames.tres` at scale 1.62.
- Images: `docs/art/hollow_cantor_v2_1/` lineups (Hero, Shade, v2, v2.1) at 1280x720 / 844x390 / 667x375, close-ups (idle, attack, face), defeat sequence, and real gameplay screenshots in `gameplay/` (Phase 1, telegraph, Phase 2 transformation banner, Phase 2 attack, defeat) per viewport.

## Size / memory (measured where stated)
| | v2 | v2.1 lossless | v2.1 VRAM-compressed (committed) |
|---|---|---|---|
| web index.pck (measured) | 14.2 MB | 17.7 MB | 22.1 MB |
| source PNGs, 64 frames | 12.4 MB | 14.0 MB | 14.0 MB |
| GPU texture memory, 64 frames (arithmetic) | 60.2 MB RGBA8 | 60.2 MB | ~15 MB (S3TC / ETC2, 1 byte/px) |
Frames are VRAM-compressed (`compress/mode=2`, `import_etc2_astc=true`): S3TC on web/desktop, ETC2 on Android. No visible change at gameplay scale in the in-engine lineup. Trade-off: +4.4 MB download vs lossless for ~4x less GPU memory. To revert: set the cantor `.png.import` files to `compress/mode=0`. [Unverified] on a real Android device or a mobile browser without S3TC: Android performance and memory were not measured here (no device), and the web export ships only the S3TC variant (as before: for_desktop=true, for_mobile=false); whether every mobile browser falls back cleanly is untested.

## Known limitations
- Still a procedural 2D render: the face at gameplay scale is a few pixels wide, so recognition comes from the sigil/eye glow and the pale mask against the dark hood, not fine detail.
- Hero and Shade have denser hand-painted detail; v2.1 is closer in value structure and contrast, not identical in texture.
- The captured "defeat_a" screenshot is the finishing blow; the defeat animation itself is in `defeat_sequence_v2_v21.png`.
