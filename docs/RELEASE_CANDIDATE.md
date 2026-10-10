# Episode 1 release-candidate QA

Candidate = `main` after the RC commit. Everything below was run against local builds of the same code (the sandbox cannot reach GitHub Pages).

## Bugs found and fixed
- Player-visible prototype wording: "PROTOTYPE COMBAT ART", "PHASE 1 PROTOTYPE", "DEVELOPMENT BUILD", "SUMMON / PHASE 03", "Placeholder rig", "Phase 2 upgrades", "Character art is a prototype placeholder".
- The out-of-energy card was a coming-soon card ("PLANNED FEATURE / NOT PLAYABLE YET", "The playable build focuses on...").
- Onboarding offered a male/female choice that did nothing (the approved Hero art is fixed).
- Secondary phone text too small (AETHER, ULT, foe subtitle, button subtitles, counters); battle tips named keyboard keys on touch devices.
- The Hero could walk behind the right-hand touch buttons.
- The web build opened with the default engine splash.

## Verified
- Fresh-save full runs, keyboard (1280x720) and touch with real joystick drags (1280x720, 844x390, 667x375): onboarding, intro, district, Mira, relay hold, Codex, breach, Shade, Enforcer, Phase 2, finisher, ending, first-clear rewards (+120 XP / +250 gold), replay (+55 / +100), home, settings. Zero browser console errors or warnings.
- `tests/test_release_candidate.gd`: real touch-event joystick drags (district and battle, diagonals, release, second finger STRIKE while dragging), wording audit of every menu and card, settings/audio toggles, no-energy path, first-clear then replay rewards.
- Performance (`tests/probe_perf_rc.gd`, software GL under xvfb, so pessimistic): median frame 14 ms home/result, 25 ms district, 25-27 ms battle, 29 ms Phase 2 transformation, p95 <= 33 ms everywhere, max 51 ms once.

## Known non-blocking issues
- Replay Battle uses the battle-only mode (procedural Enforcer, Skybridge arena), not the Soul Realm sprites.
- Phone text is readable but small at ~0.5x canvas scale; a true adaptive HUD scale is future work.
- Browser touch tests are single-finger (CDP cannot release one finger of several); multi-finger is covered by the engine-level test.
- Audio is verified by state (loop on/off, settings saved), not by ear.

## Update: Cantor art, texture variants and testing since this report
- The interim Shade stand-in for the Hollow Cantor has been replaced by the approved v2.1 art (see `docs/ART_V2_1.md`). Open question about the sprite sheet is closed.
- Browser matrix (Episode 1 and 2 at 1280x720 / 844x390 / 667x375), texture variant comparison and the Android checklist: `docs/WEB_TEXTURE_COMPARISON.md`, `docs/DEVICE_TEST_CHECKLIST.md`, `tools/qa/`.
- Android and physical-device tests have NOT been run (no SDK/device in the sandbox).
