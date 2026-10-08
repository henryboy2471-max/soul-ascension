# UI polish notes

Style: black/navy panels, gold trim, Hero blue, Soul Realm purple, boss red/orange. Before/after screenshots are in `docs/ui/` (left = before, right = after; desktop 1280x720 and phone landscape 844x390). Regenerate with `tests/capture_ui.gd` (see the header comment) and `tests/test_ui_polish.gd` checks the layout rules below.

- **Battle HUD** (`scripts/combat/battle.gd`, `scripts/ui/hud_bar.gd`): Hero HP / Aether / Ultimate bars with numeric readouts, a trailing damage ghost, low-HP warning; foe panel colored per wave (Shade purple, Enforcer orange, Phase 2 red) with a WAVE n/2 chip and a 50% phase tick; on Phase 2 the panel flips to a PHASE 2 chip and "SOUL ASCENDED / PHASE 2". Cinematic bars are 22 px and no longer cover the HUD.
- **Buttons** (`scripts/combat/touch_controls.gd`): 96 px, per-action tint, dark cooldown sweep with remaining seconds, dim state when Aether is short or the ultimate is not charged, ready glow on the ultimate.
- **Feedback:** outlined, popping damage numbers (bigger criticals), red edge vignette (`hurt_vignette.gd`) when the Hero is hit, status/tip text moved clear of the controls.
- **Dialogue** (`dialogue_box.gd`): speaker-colored box, nameplate, portrait ring, line counter, pulsing continue hint. While a conversation is open the street lifts (`Explore.lift`) and touch controls hide, so the box never covers characters.
- **Explore HUD** (`explore.gd`): objective panel with accent bar and distance chip, distance readout on the waypoint, key-cap interaction pill (accent per target: gold talk, cyan terminal, violet breach) with an in-pill hold progress bar (nothing drawn over the character), Codex toast card under EXIT.
- **Result / menus** (`main.gd`): reward tiles, LEVEL UP chip, XP bar with readout, gold trim on modals and home panels.

Layout rules (tested): every button inside 1280x720, no button overlaps another or a HUD panel, fighters stand below the HUD panels, feet above the dialogue box.
