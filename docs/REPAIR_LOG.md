# Repair log — takeover pass 1

Engine: Godot 4.4.1 (GL Compatibility), GDScript. Verified headless and under Xvfb/llvmpipe, and as a Web export in headless Chromium. Not verified on a phone.

## Reproduced problems (measured on the original build)

| Problem | Measurement |
| --- | --- |
| Start-of-fight input lock | All input ignored for 2.0 s |
| Slow movement | 241 px/s; 4.6 s to cross the arena |
| Keyboard dodge ignored WASD | Space+W dashed horizontally away from the enemy |
| Combat HUD unfinished | No numeric HP, no ultimate meter, ULTIMATE label overflowing its button, one-tap unstyled Retreat over the moon |
| Currency icons broken in web export | Diamond/bolt glyphs rendered as empty boxes (fallback font lacks them) |
| Wrapped text overflowed panels | Label width was overridden before wrapping (mission briefing ran off the modal) |
| Home key art | Hard left/right image edges; tagline touching headline |
| `project.godot` | `config/features` said 4.7 while the project is 4.4.1 |

## Changes

- Input lock cut from 2.0 s to 0.8 s and replaced by a boss-introduction card with letterbox bars.
- Hero speed 240 -> 340; enemy chase 150 -> 170; arena depth range 155 px -> 195 px; blocking slows to 55% (was 40%).
- Dodge reads WASD + stick, and is a 0.16 s dash instead of a teleport.
- Early presses during a cooldown are buffered for 0.18 s.
- Floating joystick: a touch anywhere in the lower-left zone steers; the fixed circle still works. Touch buttons have a slightly larger hit area.
- Battle buttons cannot hold keyboard focus (Space/Enter can no longer be eaten by a UI button).
- Retreat is styled and needs a confirming second tap.
- HUD: numeric HP for both sides, ultimate meter bar and READY state; ultimate button is larger with a charge ring and pulse; hero gets a gold aura when ultimate is ready.
- Ultimate finisher: white flash, background dim, letterbox bars, title + subtitle card; hit-stop on crits/heavy/ultimate.
- Fixed label wrapping, currency glyphs, home art edges, tagline spacing, project feature tag.
- Added a Web export preset.

## Tests

`tests/test_phase1.gd` (34), `tests/test_live_combat.gd` (live win + auto replay), new `tests/test_repairs.gd` (13). All pass.
`tests/capture_battle.gd` and `tests/capture_screens.gd` render screenshots (need a display or Xvfb).

## Still placeholder / not built

- Combat characters, arena and enemy are still procedural placeholders. Real character art and animation need an art source.
- The following are not in the project and were not built in this pass: overworld exploration, NPC interaction, Soul Realm / virtual missions, character portraits and dialogue, transformations, extra bosses and missions 1-2 to 1-10. Only the 1-1 story fight and its menus exist.
- Android export untested. Touch behavior only checked with synthetic events.
