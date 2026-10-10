# Browser QA harness (Chromium via Playwright, real web export)
Not part of the game build (`tools/*` is excluded from exports). Paths in the scripts are the ones used in the cloud sandbox; adjust them.
- `main_qa_hook.gd.txt`: copy over `scripts/ui/main.gd` in a THROWAWAY copy of the project; it publishes game state to `window.__qa` (scene, step, wave/phase, HUD rects, rewards). Never commit it over main.gd.
- `profile_ep2_seed.gd.txt` / `profile_ep1_seed.gd.txt`: copy over `scripts/core/profile.gd` in the throwaway copy to start from a seeded save (Episode 2 mid-quest / fresh Episode 1 at level 4).
- `rc21.cjs`: Episode 2 end-to-end (keyboard or touch at any viewport) with overlap sampler, MEND, rewards, energy checks. `perf.cjs`: same plus boot time, process RSS and frame-time stats. `e1b.cjs`: Episode 1 end-to-end. `web_matrix.sh`: builds lossless / S3TC-only / ETC2-only exports and runs the matrix.
- Software GL (SwiftShader) is used, so frame times/RSS are NOT representative of real GPUs.
