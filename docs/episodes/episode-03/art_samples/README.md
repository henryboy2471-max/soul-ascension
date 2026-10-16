# Episode 3 character samples (REVIEW ONLY)

Teo Marrow, Anselm Dray (he/him) and the Relay Warden, two directions each. **Teo A, Anselm A and the Warden A are Henry's preferred concept directions. That is a direction choice only: nothing here is approved as final art, and nothing is approved for integration.** **Nothing here is imported into the game, no batch has been made, and no paid service was used.** The directory has a `.gdignore`, so Godot does not import these files, and `docs/*` is excluded from every export.

- `overview.png`: all three characters, both directions, one page.
- `teo_marrow_samples.png`, `anselm_dray_samples.png`: front/side/back plus three portrait expressions per direction, palette strip, story grounding.
- `relay_warden_samples.png`: front view in the two states the player sees (corrupted, restored), palette strip, story grounding.
- Regenerate: `python3 tools/art25d/ep3_samples.py` (uses `tools/art25d/chargen.py`, the project's procedural renderer; Warden drawn with the same primitives).

## What these are, and are not
- Procedural concept samples (visual-direction option C). They show silhouette, costume, palette, props and, for the Warden, the three mechanisms on the body (VALVE, BELL, SEAL). They are **not** hand-painted final art; `VISUAL_DIRECTION_PROPOSAL.md` says this renderer does not reach painted-portrait detail and recommends option D (an artist paints key assets). The existing human cast (Kofi, Imani and others) came from the same renderer, so Teo and Anselm match it.
- Grounding, in priority order: `STORY_PLAN.md` (official), the in-game text and speaker colours in `scripts/story/episode3_data.gd` (Teo e8b878, Anselm 9fb4d8, Warden 6fd7e4), and the style rules in `docs/VISUAL_DIRECTION_PROPOSAL.md` section 1. The older `EPISODE3_STORY_PROPOSAL.md` (superseded by the official plan) supplied costume hints for Teo and Anselm (brass lantern fittings, braided white hair, rail-spike cane; grey uniform, crimson armband); they are used as hints only. Its Warden (a Meridian tram construct) conflicts with the official plan (an ancient guardian), so only the lamp head and clamp hands were kept.
- The plan says: reuse established Episode 1-2 designs and create new concept sheets before replacing existing approved assets. These are those concept sheets. The game currently shows the Warden as the scaled, tinted pedestrian rig and Teo/Anselm without portraits.

## Known limits
Teo's spectacle lenses are not amber-tinted (the renderer draws pale frames only); hands are simple; Anselm's ink-stained fingers are not visible at this size; expressions differ only slightly; the Warden is a front view only (no side/back, no animation frames, no attack poses), and an approved design would still need a Cantor-style frame set before it could replace the placeholder.

## Anselm revision (he/him)
The in-game Codex says "He could not." The first sheet read as ambiguous or feminine because the renderer has no gender setting and the suit template draws a skirt-like lower body. Both options now use a jacket-and-trousers or overcoat silhouette with stronger brow, jaw and nose sliders, smaller eyes and a thinner mouth. The faces still keep this renderer's soft style; a painted portrait would settle it. (`STORY_PLAN.md` itself states no pronouns for Anselm that I could find; the Codex text is the pronoun source I used.)

## Direction record
- Teo A, Anselm A (chosen after the he/him revision) and Warden A are the preferred concept directions; the B options are not chosen.
- Not recorded as approved: final art, sprite sets, portraits, integration into the game, a production method, or a batch. Those each need a separate go-ahead from Henry.
- Open (not a decision for now): how final art would be produced (these procedural samples, an artist, or a generator Henry approves and pays for; CLAUDE.md requires explicit approval for paid art). None is started.
