# Soul Ascension - working notes for Claude Code sessions

Godot 4.4.1 (GL Compatibility), GDScript. Anime-inspired action-adventure: episodes with exploration, NPC dialogue, objectives, Soul Realm battles. Play in the browser via GitHub Pages (`.github/workflows/web-preview.yml` builds and deploys on every push to `main`).

## Rules
- Work only in this repo. Do not touch other repositories.
- Keep the browser build deployable. Run the tests before every push.
- Small commits at working milestones. Do not delete working systems without a replacement.
- No secrets, API keys or paid-service calls. Do not change repo visibility or settings.
- Generating new art with a paid service needs the owner's explicit approval.

## Commands (Godot 4.4.1 on PATH as `godot`)
```sh
godot --headless --editor --import --quit          # REQUIRED after adding/renaming any class_name script
godot --headless --path . --script res://tests/test_phase1.gd
godot --headless --path . --script res://tests/test_repairs.gd
godot --headless --path . --script res://tests/test_adventure.gd
godot --headless --path . --script res://tests/test_live_combat.gd
```
Use a separate `XDG_DATA_HOME` so test saves do not touch a real save. `tests/capture_*.gd` render screenshots (need a display; use xvfb-run with `--rendering-driver opengl3`).

## Gotchas
- Code style: one-space indentation, terse GDScript, matching the surrounding files.
- In `--script` test files, never reference a `class_name` that uses autoloads (Sound/Profile); use duck typing (`has_method`) or compile fails.
- Web export needs the project imported first (class cache) and web export templates matching 4.4.1.
- Closing a modal/screen from inside its own button callback must not call `remove_child` (use hide + disable + queue_free).
- Enter/E both advance dialogue and act in the world; Explore ignores act input for 0.45s after a scene ends.
- Headless frames run much faster than real time: time-based tests must use real seconds (`create_timer`, `Time.get_ticks_msec`).

## Structure
See `docs/ADVENTURE.md` (flow and code map) and `docs/REPAIR_LOG.md` (history).
