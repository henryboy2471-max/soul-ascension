# Soul Ascension — Neon District integration gate

## Approval
Owner explicitly approved **all environment artwork at commit `1242c5165c75e05c3456a60cfd4352d06cd793b9`** on 2026-10-15. This approves the artwork, not gameplay edits, merge, or deployment.

Source branch: `art/home-screen-layout-concept`
Integration branch: `integration/approved-neon-district`
Selected treatment: glow −30%, haze sigma 9.

## Pre-integration validation
- [ ] Verify all six environment plates and stalled tram against `docs/visual_redesign/ENV_PLATE_ASSET_REQUIREMENTS.md`.
- [ ] Run `python3 tools/validate_env_plates.py` on this branch: require exit code 0; capture complete log.
- [ ] Run `python3 tools/check_camera_seams.py`; record seam and camera sweep evidence.
- [ ] Confirm provenance/native-source hashes, delivered PNG sizes/alpha, texture budget, HUD safe zones, and calm relay/mural/breach slots.
- [ ] Record exact branch head and compare against `main` before scene changes.

## Godot implementation (only after validator pass)
- [ ] Locate the existing Episode 1 Explore scene and identify the procedural sky/far/mid/near/ground and tram renderers.
- [ ] Preserve existing gameplay/collision, Mira, dialogue, objectives, relay, mural, breach, dynamic fog, rain, HUD, save/resume, combat, and rewards.
- [ ] Replace only environment visuals with approved plates at scroll factors 0.03, 0.12, 0.30, 0.60, 1.00, 1.20 and their documented offsets; stalled tram is world-aligned at (635,340).
- [ ] Avoid doubling the original procedural scenery under or over new plates.
- [ ] Test 1280×720 camera positions 0, 400, 800, 1220 and movement/camera sweep from x=0 to 1220.
- [ ] Run Godot headless import/scene checks and project tests; capture actual outputs, not assumptions.
- [ ] Measure frame rate and texture memory on real Android hardware before promoting. Use the lite 1.0x tier only if justified by measurements and owner approval.

## Release guardrails
No merge to main, deployment, or release without separate owner authorization after presenting screenshots, actual test results, outstanding defects, and rollback plan.
