# Samples for owner review: Lantern Quarter environment + Mira expression set

Branch `art/lantern-quarter-mira-samples` (off `dev/overnight-stabilize`). **Not merged into the release candidate, not wired into the game.** Both are produced by our own procedural 2D renderers (production option C of `docs/VISUAL_DIRECTION_PROPOSAL.md`), no paid service, no external assets; the Hero and Mira sprites in the environment composite are the approved ones.

## Files
- `lantern_quarter/lantern_quarter_sample_1280x720.png` - composite at gameplay scale (violet-rain night, Depot 4, terraced Lantern Circuit buildings, lantern strings, wet street with reflections, Hero + Mira sprites).
- `lantern_quarter/layer_{sky,far,mid,street,fore,rain}.png` - the six parallax layers (1280x720) a future zone renderer would scroll at different factors.
- `lantern_quarter_before_after.png` - current in-game Lantern Quarter (top) vs the sample (bottom).
- `mira/mira_{neutral,speaking,worried,determined,smile}.png` (512x512) and `mira/mira_expressions_sheet.png`.
- `mira_dialogue_before_after.png`, `mira_dialogue_strip_before_after.png` - the current dialogue portrait (an enlarged crop of her sprite) vs the new bust at the real dialogue-box size.
- Generators: `tools/samples/gen_lantern_quarter.py`, `tools/samples/gen_mira_expressions.py` (about 20 s each).

## What this shows
- Environment: layered depth (distant spire and city, terraced mid-ground with lit windows, balconies, banners, awnings, ink contours, rim light), warm lantern light against violet shadows, emissive Depot 4 sign and arch, rain, reflections, bloom. It keeps the approved neon/violet palette and the Episode 2 story set (depot of sleepers, distant Meridian spire).
- Mira: one consistent bust (deep-brown skin, dark-violet curls, gold clips and armor, violet cape, crimson chest gem - all from her approved sprite) in five expressions: neutral, speaking, worried, determined, warm smile. At the 172 px dialogue-frame size the expressions still read.

## Honest limits
- Procedural illustration, not hand-painted: faces are clean and consistent but simpler than a commissioned portrait; hair reads as stylised locks, the neck/jaw shading is basic. This is the quality ceiling of option C, so portraits/key art remain the recommended place to spend any commission budget.
- The environment is a single scene composed in code; real zones need prop variety, interactive prop states and a layer-streaming budget.
- Nothing here changes gameplay; integration (dialogue line tags to pick an expression, a zone renderer using these layers) is future work after approval.

## Android/performance estimate (arithmetic, [Unverified] on device)
- Mira set: 5 x 512x512 RGBA = 5.2 MB uncompressed, ~1.3 MB ETC2 per speaker (could be atlased and halved by authoring at 256 for the 172 px display).
- Environment: 6 layers x 1280x720 RGBA = ~21 MB uncompressed (~5 MB ETC2); the sky/far layers could be merged and the rain generated as particles to cut this further.

## Decision needed
Do you approve the direction of these two samples (and the Mira likeness) so I can plan integration, or do you want changes first?
