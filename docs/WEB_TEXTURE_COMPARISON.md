# Web / Android texture variants for the Hollow Cantor - comparison (owner decision pending; both variants remain available)

Variants: **lossless** (`compress/mode=0`) and **VRAM-compressed** (`compress/mode=2`: S3TC on desktop web, ETC2 on Android/mobile web). Switch with `tools/set_cantor_textures.sh lossless|vram` then re-import. Repo default = VRAM (owner-approved); the GitHub Pages workflow defaults to lossless and has a manual `cantor_textures=vram` option (nothing removed).

## Results (RC branch `episode-2/under-the-violet-rain`, Chromium 1280x720 via the real web export)
| | lossless | VRAM S3TC-only | VRAM ETC2-only | VRAM both (earlier measurement) |
|---|---|---|---|---|
| web `index.pck` | 17.7 MB | 22.1 MB | 22.1 MB | 36.0 MB |
| boot to home (software GL) | 2.9 s | 2.6 s | 2.5 s | - |
| GPU-process RSS at Cantor Phase 1 / Phase 2 | 266 / 267 MB | 254 / 263 MB | 253 / 263 MB | - |
| avg frame time Phase 1 / Phase 2 | 117 / 139 ms | 123 / 146 ms | 121 / 140 ms | - |
| Episode 2 run (both phases, Mira once, rewards once, console clean) | pass | pass | pass | pass |
| compression error vs source PNG (`tools/texture_error.gd`) | none | mean PSNR 36.3 / 35.7 dB (Phase 1 / 2), worst alpha error 12% on soft glow edges | same data (same encoder family) | - |
GPU texture memory for the 64 Cantor frames, arithmetic: 60.2 MB RGBA8 (lossless) vs ~15 MB (VRAM). Images: `docs/art/hollow_cantor_v2_1/web_texture_compare/` (in-engine lineups, lossless vs VRAM, and 4x zooms; the lineups differ by rain particles, so use the zooms and the PSNR line for quality).

## Reading the numbers honestly
- Chromium here runs on SwiftShader (software GL). Frame times (~117 ms) and RSS are dominated by software rendering and do NOT show the VRAM memory saving or real-GPU smoothness; no variant difference is distinguishable in these measurements. A real device is required for memory and frame rate.
- Visual quality: the compressed frames are close to lossless at gameplay scale (~36 dB, soft-edge alpha blocks only visible when zoomed); lossless is exact.
- Compatibility: ETC2-only and S3TC-only both load and play in Chromium (it exposes both). Forum reports (unverified for Godot 4.4.1) say S3TC-only web builds can lose textures on mobile browsers that lack S3TC; shipping both variants costs 36 MB.

## Recommendation (pending your decision and device tests)
- **Web/Pages: lossless** (best quality, smallest download at 17.7 MB, no GPU-format dependency).
- **Android: VRAM (ETC2)** for roughly 4x lower texture memory, once an on-device check confirms no visible banding on the glows.
- Keep both variants in the repo until the device results are in.

## Addendum (overnight investigation on `dev/overnight-stabilize`)
### The unexplained build-size difference: explained
The 2 MB gap (17.7 MB vs 15.7 MB lossless) came from **gitignored local pipeline leftovers**: `assets/{characters,enemies}/*/_trimmed/` (92 textures, ~2 MB) exist only in the sandbox working copy. The export preset exports all resources, so builds made from that working copy included them; clean checkouts (CI) do not. Verified by reading both `.pck` directories (184 extra files, all `_trimmed` imports and their `.ctex`). **Clean-checkout sizes, measured from `git archive HEAD`:** lossless **15.7 MB**, VRAM S3TC-only **20.1 MB**, VRAM ETC2-only **20.1 MB**, both variants **36.0 MB**, Basis Universal 20.1 MB. The earlier 22.1 / 36.0 / 17.7 MB figures above include those 2 MB of strays (the "both" 36.0 was also measured from the working copy). Suggested (not applied, export config needs your approval): add `assets/*/*/_trimmed/*` to `exclude_filter` as a safety net.

### Compatibility options compared
| Option | Size (clean) | Works in Chromium web | Phase 2 frames load (desktop headless) | Notes |
|---|---|---|---|---|
| Lossless (WebP in `.ctex`) | 15.7 MB | yes | ~180 ms CPU decode | works everywhere; GPU memory ~60 MB for all Cantor frames |
| VRAM S3TC only | 20.1 MB | yes (SwiftShader exposes S3TC) | ~10 ms | desktop GPUs; forum reports (unverified) of missing textures on mobile browsers without S3TC |
| VRAM ETC2 only | 20.1 MB | yes | ~10 ms | Android and iOS-class GPUs; desktop NVIDIA/AMD/Intel support is not guaranteed |
| VRAM both | 36.0 MB | yes | ~10 ms | safest compressed option, +20 MB download |
| Basis Universal | 20.1 MB | **NO: the web build crashed in battle with `null function or function signature mismatch` and never finished the Cantor fight** | ~117 ms | transcodes at runtime; the 4.4.1 web template path is not usable here, so it is rejected for web |
Conclusion: the only safe web options are lossless (smallest download, exact quality) or both VRAM variants (+20 MB). S3TC-only is risky on phones; ETC2-only is risky on some desktops; Basis fails in the web export. Android native always has ETC2, so VRAM there is safe.

### Loading hitch found and fixed
Phase 2 art was loaded synchronously at the transformation: ~180 ms on desktop for lossless frames (more on phones/wasm), ~10 ms for VRAM frames. `Battle.spawn_foe` now requests the Phase 2 frames during the Cantor intro (`ResourceLoader.load_threaded_request`), covered by a focused test that fails without the change. Measured in the web export before the fix: no per-variant frame-time difference under software GL (so the benefit is expected on real devices, [Unverified] there).
