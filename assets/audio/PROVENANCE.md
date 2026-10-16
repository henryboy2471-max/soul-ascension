# Audio provenance
- `music_ep1.ogg`, `music_ep2.ogg`, `music_ep3.ogg`: original background music, generated in code by `tools/gen_music.py` (sine/FM-style synthesis, no samples, recordings or third-party material). Owned by the project; no external licence applies. Regenerate with `python3 tools/gen_music.py` (needs ffmpeg with libvorbis).
- Sound effects, footsteps and ambience loops are synthesized at start-up by `scripts/audio/sound.gd` (see `docs/ASSETS.md`).
