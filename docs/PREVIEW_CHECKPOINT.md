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

## Episode 1 final review checkpoint
Branch `dev/ep1-gameplay-polish`. Not merged, not deployed. Episode 2 not started.

**Play the clean build (no QA hook):** from a checkout of this branch run `godot --headless --editor --import --quit`, then `godot --headless --path . --export-release Web build/web/index.html` (Godot 4.4.1 + its web export templates), then `python3 -m http.server -d build/web 8000` and open http://localhost:8000/index.html in Chromium/Chrome (a normal HTTP server is required; file:// does not work). `build/` is git-ignored. Or open the project in the Godot 4.4.1 editor and press Play. Controls: WASD/arrows or left stick to move, E/Enter/ACT to act (hold E at the relay), J strike, K heavy, Space dodge, hold L block, Q pulse, E rift, R mend, F ultimate. A fresh save asks for a name once; progress is kept in the browser's local storage.

**Verified on the final build** (real browser = Chromium with software GL, so frame rates are low and NOT representative of phones):
- Clean build: `window.__qa` is undefined, no console errors; real-input smoke (onboarding, Settings, reload keeps the save, mission card, Episode 1 start, walking) at 1280x720 keyboard, 844x390 touch and 667x375 touch (`tools/qa/clean_build_smoke.cjs`, screenshots in `docs/qa/ep1_final/clean/`).
- Exploration checkpoint, 11 checks per viewport (camera tracking and whole-pixel parallax, Mira collision, dialogue, relay hold, breach, battle start): 11/11 at all three viewports (`ep1_checkpoint.cjs`).
- Full Episode 1 playthrough (exploration, Mira, relay, breach, Resonance Shade, boss, Phase 2, finisher, ending, reward screen) on the QA-hook build of the same tree (the automated player needs the hook): all three viewports reach the result screen with +120 XP, +250 gold, energy 60 to 54, completion saved, 6 Codex entries, zero console errors (`e1b.cjs`; logs and screenshots in `docs/qa/ep1_final/playthrough/`).
- Headless regression: all 21 suites pass (includes the new `test_ep1_save_replay.gd`: first-clear vs replay rewards, defeat pays nothing, no double rewards, settings saved, sound gating). Sound was checked by state only; nobody has listened to it.

**Defects fixed in this checkpoint (all reproduced first):** dialogue SKIP overlapped the Explore EXIT button; dead relay prompt after the reboot; NPC walk-through; the temporary-art notice was missing on the home, intro, battle and reward screens (now one global notice).

**Known, not changed (need an owner decision or approved art):**
- The home screen, intro backdrop and the Hero's dialogue portrait still use the old key art (white-twist Echo, superseded by Echo V2). They are temporary and marked by the notice; replacing them needs approved Echo V2 art.
- Mira's dialogue portrait is an enlarged small sprite and looks soft at 3x.
- Episode 1 is not resumable: if the page is closed or reloaded during the Soul Realm battle, the 6 energy already paid is not refunded and the run is not resumed (Episode 2 does resume). Making Episode 1 resumable would change save behaviour, so it is left for the owner.
- Frame cost in software GL: Explore about 25-29 ms median, boss battle about 27 ms; pedestrians about 2 ms of that. No real-device measurement exists.

## Episode 1 save and resume (checkpoint 3)
What is saved (inside the existing checksummed save, `mission_progress["1-1"]`): `intro` (opening scene seen), `step` (0 find Mira, 1 relay, 2 breach), `px` (Hero position), plus the existing `combat_run` (energy paid, fight not finished) and `battle_won` (boss beaten, ending not finished).
- Closing, reloading or pressing EXIT mid-episode and choosing the mission again shows **RESUME EPISODE 1**, skips the title card and opening scene, and returns to the saved objective, with the relay still rebooted and the breach open when that was done.
- Combat: the 6 energy is paid and saved when the breach is entered. If the page is closed or reloaded during the fight, nothing is refunded and entering the breach again costs nothing ("RESUME / SOUL REALM BREACH / ENERGY PAID"). The fight itself restarts from wave 1; mid-fight state is not saved.
- Boss beaten but the ending not finished: the next start replays the ending only (no fight, no energy), then pays rewards once.
- Rewards are unchanged and only come from the single reward call at the end (first clear 120 XP / 250 gold, replay 55 / 100); Codex unlocks are idempotent. Finishing the mission clears the resume keys so the next play-through starts from the title card again.
- Hardening: saved values are read strictly (wrong types, out-of-range, non-finite numbers or flags such as `"yes"` are ignored; only a real `true` marks an attempt paid or an ending pending). Corrupted files fall back to the backup copy, then to a fresh profile; checksum-mismatched or tampered files are rejected; old saves without progress/Codex keys load with defaults. A pre-existing crash on non-boolean flags (`bool("yes")`) was found by the new tests and fixed.
- Not saved on purpose: the fight's mid-state (HP, wave progress), the Hero's depth lane, optional lore reads (their Codex entries are saved when read).

Tests: `tests/test_ep1_resume.gd` (37 checks: reload after Mira / relay / paid fight / pending ending, no second charge, 0-energy resume, no duplicate Codex or rewards, replay rewards unchanged, EXIT, RESUME button, six malformed-progress cases, non-boolean flags, corrupt file and backup, tampered checksum, outdated save) plus all 21 earlier suites: 22/22 suites pass. Browser: `tools/qa/ep1_resume.cjs` (QA-hook build, real page reloads; browser saves persisted) 12/12 at 1280x720 keyboard, 844x390 touch and 667x375 touch; `tools/qa/clean_build_resume.cjs` on the clean build (real input only, `window.__qa` undefined, zero console errors) at the same three viewports, judged from screenshots in `docs/qa/ep1_resume/`.
Not tested: a real phone, a real browser cache eviction, saving at the exact moment the tab is killed (the harness waits a few seconds so the browser's IndexedDB write completes; an abrupt kill during that write falls back to the previous save or its backup).

## Episode 1 owner playtest checkpoint (clean build)
Verified on branch `dev/ep1-gameplay-polish` with the CLEAN web export (no QA hook; `window.__qa` undefined). Not merged, not deployed, no authorized public preview exists: run it locally (below).

**Run it locally:** `godot --headless --editor --import --quit`, then `godot --headless --path . --export-release Web build/web/index.html` (Godot 4.4.1 + web export templates), then `python3 -m http.server -d build/web 8000` and open http://localhost:8000/index.html in Chrome/Chromium (needs HTTP, not file://). To test a phone layout use the browser's device toolbar at 844x390 or 667x375 with touch emulation. To start fresh clear the site's storage.

**Real-input smoke test (`tools/qa/clean_build_playthrough.cjs`, no telemetry; it reads the game's own save out of the browser's IndexedDB):** onboarding, opening, exploration, Mira, page reload + RESUME EPISODE 1, relay, breach, Soul Realm battle, ending, rewards, final reload. 9/9 checks at 1280x720 keyboard, 844x390 touch and 667x375 touch: first clear saved once (+250 gold, +120 XP = level 1 to 2 with 20 XP left, energy 60 to 54), 6 Codex entries without duplicates, resume state cleared, identical save after reload, zero console errors. Screenshots (readable full-size frames; selected event frames, see file names) and logs are in `docs/qa/ep1_owner_playtest/`. The blind-input harness hit one test-script defect on the first run (touch strike taps landing on REPLAY BATTLE after the win); the game behaved correctly (the replay cost its 6 energy) and the script was fixed and re-run clean.

Headless regression at this commit: all 22 suites pass.

**Genuine remaining blockers before a public release (none are code defects found in Episode 1):**
1. Echo V2 is not in the game. The Hero/Echo sprites, the home key art and the Hero's dialogue portrait are temporary and the old white-twist design; the in-game notice says so. A release that presents Echo V2 needs the approved native artwork.
2. Mira's dialogue portrait is an enlarged small sprite and looks soft; fixing it needs approved art.
3. No real-device evidence: performance, touch feel, thermals and battery are untested (software GL only), and sound has been checked by state only, never by ear.
Not blockers but known: the fight itself restarts from wave 1 after a reload (the energy stays paid); Episode 2 and later are out of scope here.
