# Phase 1 validation

Tested with Godot 4.4.1 stable on Linux. Desktop screenshots were rendered by Godot with the Compatibility renderer / Mesa llvmpipe, not recreated as mockups.

## Passed

- Headless project import and script loading.
- 34 automated checks: progression, multiple level gains, currency validation, offline energy, caps and clock rollback, save round trip, corrupt-file backup recovery, mission cost, duplicate settlement protection, first/repeat rewards, no loss rewards, insufficient energy, five detail screens, attack damage/cooldown, blocking, dodge invulnerability, skill energy and stagger, healing, ultimate charge, independent multitouch IDs, win/loss result transitions and persistence reload.
- Live first-clear run using ordinary combat actions with approach/strike/pulse/mend/ultimate; no direct enemy health override.
- Live auto-battle replay after the first clear.
- Godot-rendered home and battle screenshots visually inspected. Fixed character framing, bar sizes and telegraph layering.
- The only renderer warning during capture concerns unavailable V-Sync control in the virtual display. No script error was emitted by the final automated test run.

The detailed 34-check log is in `test_results.txt`. Live combat checks can be rerun with `godot --headless --script res://tests/test_live_combat.gd` using a separate test save directory.

## Not verified

No Android APK/AAB was built, signed, installed or device-tested. No iPhone build or touch-device performance measurement was performed. No billing, rewarded ads, cloud backend, network gameplay or store integration exists. Desktop-generated touch events are not a substitute for physical phone multitouch testing. UI is a fixed landscape canvas scaled with letterboxing; test notches, ultrawide phones and small displays before release.

Combat is an early short encounter, not a validated long-term balance model. Asset quality differs intentionally between generated home key art and procedural combat placeholders. Full animation, real-world performance and player enjoyment need the next playtest pass.
