# Playable preview checkpoint (branch `dev/ep1-gameplay-polish`)

Not merged, not deployed. Based on `chatgpt/approved-anime-art-integration` (includes the stabilized release candidate and the 2.5D demo) plus `dev/ep1-2-polish`.

**Art status:** the Hero and Mira sprites in this build are TEMPORARY stand-ins. They are not Echo V2 production artwork, which is still pending native renders and has not passed production validation. Explore shows a small "PREVIEW BUILD / TEMPORARY CHARACTER ART" notice. Echo V2 remains the approved protagonist design.

**Changes:** NPCs are solid in Explore (the Hero eases around them instead of walking through); the relay prompt is retired once the terminal is rebooted; the exploration HUD overlay repaints only while it has content; temporary-art notice.

**Test:** `godot --headless --editor --import --quit`, then run the `tests/test_*.gd` suites (see CLAUDE.md). Web: `godot --headless --path . --export-release Web build/web/index.html`, serve `build/web` over HTTP and open `index.html` (WASD/arrows move, E/Enter acts, hold E at the relay).

## Checkpoint 2 (camera, dialogue, browser QA)
- Camera: smooth float camera, but every layer/sprite is placed from the whole-pixel camera (no sub-pixel shimmer); boundaries clamp at both ends. Dialogue fades in/out, portraits fade on speaker change, text has a dark outline. The Explore EXIT button hides during dialogue (it overlapped the dialogue SKIP button; found in browser screenshots, not by headless tests).
- Browser QA (real Godot 4.4.1 web export, Chromium + SwiftShader, `tools/qa/make_ep1_qa_build.sh` + `tools/qa/ep1_checkpoint.cjs`): 11/11 checks at 1280x720 keyboard, 844x390 touch and 667x375 touch. Screenshots and per-viewport results JSON are in `docs/qa/ep1_checkpoint/`.
- Pedestrian cost: profiled (about 2 ms of ~27 ms in software GL). Hiding off-screen pedestrians gave no measurable gain over run-to-run noise (+-3 ms), so it was NOT kept. `tests/probe_explore_perf.gd` is the probe.
- KNOWN: the Hero dialogue portrait is still a crop of the old key art (white-twist Echo, superseded for Echo). It is a temporary stand-in, not Echo V2; replacing it needs approved art.
