# Episode 3 device pass: the run sheet (next concrete review checkpoint)

Nothing in this sheet has been run. It exists so that someone with a phone or tablet can produce the first real-device evidence for Episode 3 in about 30-40 minutes. It complements `docs/DEVICE_TEST_CHECKLIST.md` (Android/mobile) and `AUDIO_AND_DEVICE_GAPS.md` (why each item is here). The QA build unlocks Episode 3 and is **for local testing only: do not publish, deploy or share it beyond your own network.** Production stays locked.

## Setup (on a computer with the repo, Godot 4.4.1 and the Web export templates)
1. `tools/qa/serve_qa_local.sh --build` (exports the "Web QA" preset to `build/web_qa` and serves it on port 8801 for your network). Without `--build` it serves the last export.
2. On the phone (same Wi-Fi) open `http://<computer-LAN-IP>:8801/index.html`. The footer must read "QA BUILD / NOT FOR RELEASE". On first launch choose a name, close the mission card, tap MISSIONS, then **QA: PLAY EPISODE 3**.
3. Record: device model, OS and browser version, screen size, whether the page was added to the home screen, battery level.

## What to record (pass / fail / note)
1. **Boot and load**: seconds to the home screen; any blank screen or crash; the browser's memory warning, if any.
2. **Touch targets** (the biggest known risk): the relay-map puzzle (tap-only tiles, about 32-34 CSS px at phone size), the rail lock, the power board, the memory cards, HINT/BACK and CHECK buttons. Note every mistap and every control that is hard to hit with a thumb.
3. **Walk, scan, channel**: joystick walking; hold ACT on a scan (about 1.4 s) and on the three arena mechanisms; **joystick and ACT used together** (hold a mechanism, slide to dodge, hold again).
4. **Warden**: can the telegraphs be read and dodged on this screen and frame rate? Does the checkpoint behave after a fail? Note any frame drops during the fight.
5. **Frame rate and heat**: rough feel in the market, the tower floors and the arena; any stutter; device warm after 15 minutes. (If you can, open the browser's performance overlay or remote-debug from a desktop and note numbers.)
6. **Save and resume** (new in M5): play to the workshop, wait for the top "SAVING..." mark to clear, switch app or lock the screen for a minute, come back; then close the tab, reopen the URL and re-enter with the QA button: same zone, same clues? Then repeat while the "SAVING..." mark is showing (close the tab immediately after a scan). Note whether the clue survived.
7. **Safe areas and orientation**: notch or gesture bar overlaps, rotating the phone mid-puzzle, back button behaviour, incoming call or notification during a cinematic.
8. **Audio**: Episode 3 has almost no sound of its own (see `AUDIO_AND_DEVICE_GAPS.md`); only note whether the existing city ambience and footsteps start after the first tap and whether the Settings sound switch mutes them.
9. **Finish**: rewards (+180 XP / +340 gold on a fresh QA save), NEXT EPISODE teaser, return to home.

## Where the results go
Add them under a new heading in `IMPLEMENTATION.md`, or send them to the next session; a failing item becomes a fix before any release review. Until a real device has run this, no mobile, GPU or touch-accuracy claim for Episode 3 is made.
