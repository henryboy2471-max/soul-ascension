# Android / mobile device test checklist (NOT RUN - the Android SDK and devices are unavailable in the cloud sandbox)

Status as of this branch: **no physical-device test has been run.** Everything below is blocked, not passed. Why blocked: the sandbox has no Android SDK (`Unable to open Android 'build-tools' directory`), the Google SDK host is unreachable (curl returns 000), there are no Android export templates, and there is no device or emulator. Do not repeat the SDK download attempts from the cloud; run these on a machine with the SDK.

## Build
1. Install Android SDK (platform-tools, build-tools 34.x, platform android-34) + JDK 17; set the paths in Godot Editor Settings.
2. Install Godot 4.4.1 Android export templates.
3. Export the debug APK with the repo's Android preset (arm64-v8a). Record APK size.
4. Install with `adb install -r`.

## Functional (record pass/fail and device model)
- Cold start to home; time to interactive.
- Episode 1 full run (intro, explore, terminal hold, breach, Shade, Enforcer, ending, rewards). Episode 2 full run (resonators, array, Shade, Cantor Phase 1/2, Mira support, ending).
- Touch: stick (diagonals, release), STRIKE/HEAVY/DODGE/BLOCK/MEND/RIFT/PULSE, second finger while dragging, dialogue tap, SKIP, retreat. Multi-touch on real hardware (browser harness is single-finger only).
- Safe areas / notch / gesture bars at 20:9 and 16:9; rotation lock; immersive mode.
- Pause/resume, incoming call, app switch, back button; save persistence after force-stop; energy regeneration after hours closed.
- Audio: loop, mute setting, latency on dodge/strike.

## Performance (use `adb shell dumpsys meminfo <pkg>`, Godot's `--print-fps`/remote debugger or `adb shell dumpsys gfxinfo`)
- Average/1%-low frame rate in the district, Soul Realm battle, Cantor Phase 2 transformation (most effects).
- Total/graphics memory during the Cantor fight (expect ~15 MB of Cantor textures with ETC2 vs ~60 MB lossless).
- Thermal throttling after 10 minutes; battery drain per 10 minutes.
- ETC2 visual check on the Cantor halo/glow gradients (banding) and the mask face.
- Low-RAM device (2-3 GB) behavior; loading time of the Phase 2 transformation (preloaded since `dev/overnight-stabilize`).

## Mobile browsers (if the web build is shipped to phones)
- Chrome Android and Safari iOS: textures present (both lossless and VRAM variants), touch input, audio unlock on first tap, orientation, memory. Chromium here exposes every compressed format, so devices without S3TC could not be simulated.
