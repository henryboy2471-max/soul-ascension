# Character art layout

```
assets/characters/hero/            approved Hero art: frames + frames.tres
assets/characters/mira/
assets/enemies/resonance_shade/
assets/enemies/enforcer/
assets/vfx/
assets/_incoming/<character>/      drop the original sheet PNGs here; tools write results next to the character
```

Each character folder contains `frames/<animation>_<NN>.png` (normalized, transparent, foot-anchored), `manifest.json` and the generated `frames.tres` (a `SpriteFrames` resource). The game loads `frames.tres` automatically; a character without one keeps the procedural rig. Pipeline and rules: `docs/SPRITES.md`.
