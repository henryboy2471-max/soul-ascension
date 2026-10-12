# Playable preview checkpoint (branch `dev/ep1-gameplay-polish`)

Not merged, not deployed. Based on `chatgpt/approved-anime-art-integration` (includes the stabilized release candidate and the 2.5D demo) plus `dev/ep1-2-polish`.

**Art status:** the Hero and Mira sprites in this build are TEMPORARY stand-ins. They are not Echo V2 production artwork, which is still pending native renders and has not passed production validation. Explore shows a small "PREVIEW BUILD / TEMPORARY CHARACTER ART" notice. Echo V2 remains the approved protagonist design.

**Changes:** NPCs are solid in Explore (the Hero eases around them instead of walking through); the relay prompt is retired once the terminal is rebooted; the exploration HUD overlay repaints only while it has content; temporary-art notice.

**Test:** `godot --headless --editor --import --quit`, then run the `tests/test_*.gd` suites (see CLAUDE.md). Web: `godot --headless --path . --export-release Web build/web/index.html`, serve `build/web` over HTTP and open `index.html` (WASD/arrows move, E/Enter acts, hold E at the relay).
