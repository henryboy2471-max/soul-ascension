# Episode 3: audio and device/GPU gaps (what exists, what was never tested)

Review-only documentation; no audio or rendering code was changed for this.

## Audio: what exists
`scripts/audio/sound.gd` (autoload) synthesizes a few original tones at start-up: `tap`, `hit`, `special`, `win`, `hurt` (short sine sweeps), wet/wood/metal footstep clips (5 variants each), and two ambient loops (`city`, `realm`). Nothing is recorded or imported (`docs/ASSETS.md`: placeholder sound design, no music). The Settings screen has a Sound effects switch (`settings.sound`).

What Episode 3 inherits for free: the `city` loop that `Explore` starts, wet-surface footsteps (the explore code always asks for "wet"), the dialogue-advance tick (`Sound.play("tap")`) and UI button taps. `RelayEpisode`, `PuzzleScreen`, `WardenArena` and the cinematics contain **no Sound calls**.

## Update (presentation pass): background music now exists (three original loops, -20 dB, its own Settings switch) and footsteps were turned down to -24 dB; the gaps below that concern effects and cues are unchanged.

## Audio: gaps (none are implemented; this is the cue list a sound pass would need)
- Footstep surfaces: tower floors and the arena are metal, the station is concrete; the existing `metal`/`wood` clips are never selected in Episode 3.
- Scans and mechanisms: hold-to-channel start, progress, completion (3 scans, VALVE, BELL, SEAL).
- Puzzles: signal tune and lock, tile rotation, rail slide and blocked, memory place/remove, wrong order, solved (five puzzles).
- Warden: telegraph warning, strike, hit on Echo, stun, restore, the lamp light "finding" Echo, the archive opening.
- Cinematics and finale: ambience change per zone (market rain, station hall, workshop, tower interior, arena), the recording's voice and the counting-seven crystal, the Episode 4 teaser sting. No music anywhere.
- Mix and accessibility: no volume slider (only on/off), no captions for non-speech sounds (dialogue is text, so speech is already readable).
- Licensing: `EPISODE3_PREP.md` says any sound pack needs an approved licence; none was added.

## Audio: what was and was not tested
Nothing about audio was asserted in the browser runs; the QA runs did not record whether the QA save had sound on. Chromium headless output is not evidence of audible playback. Not tested: web audio unlock on first tap (Safari/iOS and Chrome Android require a gesture), latency, clipping, the mute setting in a live session, loop seams, background-tab behaviour.

## Device and GPU: what was measured
- Software rendering only (SwiftShader under headless Chromium; Godot headless/xvfb OpenGL for the playthroughs). Frame time in the Episode 3 zones: median 28 to 33 ms, 99 to 162 draw calls (an earlier probe); the web page's frame interval was about 130 to 140 ms in the production export under the same software renderer. **These are diagnostic numbers, not mobile performance approval.**
- Download size of the web export: about 54 MB `index.pck` plus 44 MB `index.wasm` (not assessed against any budget).
- Browser save latency to IndexedDB: 0.8 to 4.3 s under software rendering (see `IMPLEMENTATION.md`); real devices unmeasured.

## Device and GPU: gaps
No phone, tablet, real GPU, mobile browser (Safari iOS, Chrome Android), Android APK, or low-RAM device has been used for Episode 3; `docs/DEVICE_TEST_CHECKLIST.md` remains the run-sheet (Android SDK and templates are unavailable in this sandbox). Episode 3 additions to that checklist:
1. **Touch target sizes at the small viewports (computed, not tested on a device)**: the canvas scales 1280x720 down by 0.54 (844x390) or 0.52 (667x375). The relay-map tiles are 62 game px, so about 34 and 32 CSS px; rail-lock cells 54 px, about 29 and 28 CSS px; power tiles 82 px, about 44 and 43 CSS px; most buttons are 52 to 80 px tall, about 27 to 42 CSS px. Commonly cited touch-target guidance is roughly 44 to 48 px, so the **relay-map puzzle (tap-only tiles, no button alternative) is the likeliest to be hard on a phone**; the rail puzzle has big NEXT BLOCK/arrow buttons as an alternative. Emulated taps are pixel-exact, so the browser runs say nothing about finger accuracy.
2. Simultaneous joystick plus ACT (holding a mechanism while sliding the stick) and two-finger use in the Warden arena; the browser driver used one finger at a time.
3. Frame rate and memory in the tower zones and the arena; thermal throttling over a 15-minute run; GPU memory (the Warden is currently the scaled pedestrian rig, so final Warden art would add a Cantor-sized frame set).
4. Save durability on real browsers: IndexedDB latency, localStorage availability (private modes), `SAVING...` behaviour on slow storage, storage quota.
5. Safe areas, rotation and app-switch/back-button handling during a puzzle or cinematic; resume after force-stop mid-puzzle.
6. Mobile-browser audio unlock, once audio exists.
