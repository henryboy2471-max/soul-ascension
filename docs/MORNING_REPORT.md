# Overnight development report (branch `dev/overnight-stabilize`)

Base: Episode 2 release candidate `episode-2/under-the-violet-rain` at `bca1b98`. Nothing was merged into the RC or `main`, nothing was released or published, no money was spent, no new major art was generated, and Episode 3 was not implemented.

## Commits (all on `dev/overnight-stabilize`)
- Exploration: eased walking (accel 0.12 s / stop 0.08 s) + camera look-ahead; `tests/test_explore_motion.gd` (9 checks), added to the CI test list.
- Battle: Cantor Phase 2 frames are requested during the intro instead of loading synchronously at the transformation (~180 ms on desktop for lossless frames; ~10 ms for VRAM); focused check added (fails without the change).
- Test fix: the release-candidate joystick-release test now waits real time for the eased stop (the one regression the walking change caused; found by the final regression, fixed).
- Hygiene: ignore editor-generated `.import` files under `docs/`.
- Docs: `SEASON1_PLAN.md`, `EPISODE3_PREP.md`, `VISUAL_UPGRADE_PLAN.md`, `DEVICE_TEST_CHECKLIST.md`, `WEB_TEXTURE_COMPARISON.md` addendum, stale-limitation notes, roadmap + visual direction proposal merged in.
Branches: `dev/overnight-stabilize` (work), earlier `docs/next-milestone-roadmap` (merged), RC `episode-2/under-the-violet-rain` (untouched since `bca1b98`).

## Bugs and defects
- Fixed: Phase 2 transformation load stall (performance); joystick-release test regression caused by the new eased stop.
- Explained: the 2 MB build-size discrepancy = gitignored local `assets/*/*/_trimmed/` leftovers exported from the sandbox working copy (not in clean checkouts). Proposed, not applied: add them to the export `exclude_filter`.
- Found, not fixed (needs approval or device): S3TC-only web builds may lose textures on mobile browsers (forum reports, unverified); Basis Universal crashes the web build (`null function or function signature mismatch`), so it is rejected; battle intro text can briefly share the screen with combat popups (cosmetic); phone text is small at ~0.5x scale (known).

## Test results
Tested (final checkpoint, headless): adventure 30, boss_transform 27, cantor_sprites 19, enforcer 17, episode2 38, episode3 67, episode4 32, episode_defs 24 (Episode 1 golden trace), explore_motion 9, hero 18, layout_overflow 15, mira 14, phase1 34, release_candidate 38 (after the test fix, re-run alone), repairs 13, shade 17, sprites 16, ui_polish 24, live_combat manual + auto replay PASS (earlier checkpoint on the same combat code), sprite pipeline tests pass. Failures at checkpoint: 1 (release_candidate joystick release), fixed and re-run green.
Tested (browser, lossless web build of this branch with the QA hook): Episode 2 keyboard 1280x720 and touch 667x375 end to end (Phase 2 + Mira once, no overlaps, energy 54, rewards once, console clean); Episode 1 keyboard 1280x720 and touch 844x390 end to end (rewards 250 gold / 120 XP, console clean). Earlier checkpoints covered all three viewports for both episodes.
Untested: Android (any kind), physical touch devices, iOS/Safari, mobile browsers without S3TC, audio by ear, real-GPU frame rates/memory.
Blocked: Android SDK/build tools unreachable (Google host blocked, no templates, no device) - not retried; see `docs/DEVICE_TEST_CHECKLIST.md`.
Note: the final full regression was run once before the test fix; only `test_release_candidate` was re-run after it (credit saving), and it passed 38/38.

## Performance
- Phase 2 art preload (above). VRAM-compressed frames load ~18x faster than lossless (10 ms vs 180 ms) and use ~4x less GPU memory (arithmetic: 15 MB vs 60 MB). Eased walking changes feel, not speed.
- Web frame-time/RSS numbers are from software GL and are not representative; no real-GPU measurement exists.

## Season 1 and Episode 3
Season 1 is exactly 10 episodes, fully documented with arcs, casts, locations, objectives, NPCs, revelations, encounters, rewards and cliffhangers (`docs/SEASON1_PLAN.md`); Episodes 1-2 are canon, 3-10 are proposals. Episode 3 preparation is complete as documents only (`docs/EPISODE3_PREP.md`): technical plan, reuse map, asset list, checklist.

## Recommended visual direction
Option C + D: our procedural renderer for environments, props, effects and UI (free, consistent, already approved quality), plus paid or commissioned work only for dialogue portrait busts with expressions and 4-6 key-art stills. Optional experiment B on your own machine. First sample for approval: one Lantern Quarter backdrop + one Mira expression mock-up (`docs/VISUAL_UPGRADE_PLAN.md`).

## Remaining blockers
Owner approvals (below); Android SDK/device; visual direction; Season 1 canon for proposed characters.

## The three decisions needed tomorrow
1. Web texture strategy: lossless web (15.7 MB, safest) + ETC2 on Android (recommended), versus shipping both VRAM variants (36 MB), plus whether to add `_trimmed` to the export exclude filter.
2. Visual direction and production option (recommended C + D) and approval of the first backdrop + portrait samples.
3. Approve Season 1's seven-array structure and new character roles so Episode 3 can start (and say whether to merge `dev/overnight-stabilize` into the RC).
