# SOUL ASCENSION — 2.5D Neon District demonstration

Branch `demo/neon-district-2.5d` (from the release-candidate base). **Not merged, not deployed.** Awaiting owner approval before the architecture is extended to any episode.
The demo is a small, non-canon, playable slice. It never reads or writes saves and does not touch the Episode 1–3 flows. Start it with `--demo-neon` (desktop) or `?demo=neon` (web); the web URL flag `&qa=1` publishes test state.

## 1. What I inspected and what is reusable

| Existing system | Reused / changed |
|---|---|
| `VirtualStick`, `TouchAction` (mobile controls) | reused as-is (stick + ACT, hold-to-channel) |
| `DialogueBox` | reused; added optional `speakers` override and crisp `tex:` portraits (episodes unaffected) |
| `UI` kit, `Sound` autoload | reused; `Sound` got new footsteps (below) |
| `WorldArt` bake-to-SubViewport technique | reused idea (`Stage25.bake`) |
| `Explore` (flat left/right strip) | not extended; the 2.5D stage is a separate system. Footstep timing in Explore now follows speed |
| Fighter side-view sprites (hero 136x108 px, Mira 258x153 px) | **root cause of blurry faces**: portraits are 3x upscales of tiny side-view sprites. Not changed; the demo uses vector-rendered portraits |
| Episodes, `Profile`, saves, mission data | untouched |

## 2. 2D-depth (layered 2.5D) vs true 3D with 2D character sprites

| | 2D layered 2.5D (built) | True 3D scene + Sprite3D billboards (prototyped only in `tests/bench_depth.gd`) |
|---|---|---|
| Depth cues | perspective scale + y-sort + parallax layers + foreground fade; fully art-directed | real perspective, free camera moves, real occlusion by depth buffer |
| Art cost | static art baked from layers; no 3D assets | needs 3D set pieces/props or many textured quads; lighting must be faked for 2D art |
| Collisions / movement | simple (x, depth) rectangles, deterministic, easy to test | 3D physics or custom; more moving parts |
| Rendering cost (Compatibility renderer, Android/web) | 2D batching; cost grows with number of draw items; fill-rate bound by overdraw | depth buffer + 3D pipeline; billboards need alpha-test sorting; generally heavier per object on low-end GPUs [Inference] |
| Risk | camera moves are limited to pan/zoom/shift | web/Android 3D in Compatibility is workable but untested here; larger change |

**Recommendation: keep the 2D layered 2.5D stage as the production architecture** for exploration, with baked layers, y-sorted actors and a few additive light sprites. It matches the existing Compatibility renderer and web/Android targets, is far cheaper to author and test, and already delivers the requested depth, occlusion and cinematic camera. Reserve true 3D for a possible later set-piece (e.g., a single flythrough) only if the owner wants it. [This is a judgment from the prototype and general engine knowledge, not a device measurement.]

## 3. What the demo contains

- **Stage25**: walkable plane (world x + depth z), perspective scale, y-sorted actors/props/vehicles, parallax sky/skyline/facade/ground/foreground bokeh, rain (two CPU particle layers), wet-street ripples and splashes on footsteps, additive neon glows with flicker, camera follow + look-ahead + depth tilt/zoom + dialogue dolly + letterbox.
- **Collisions**: (x, depth) rectangles for props, NPCs, pedestrians and vehicles; axis-separated sliding; world/plane edges.
- **Foreground occlusion**: poles/banners in front of the player fade to 30% opacity while the player is behind them.
- **Traffic and pedestrians**: two lanes of hover vehicles that stop for anyone in the lane; 8 pedestrians walking with the same four-direction rig.
- **Interiors**: Noodle House, hidden passage, Backroom Arcade; the street is paused/hidden and restored on return.
- **Mission slice (original, non-canon)**: talk to Imani, listen to the NEON DISTRICT tower (hold ACT) to learn a colour combination, optional hint from Kofi, solve the Junction 7 breaker puzzle, open a hidden wall panel, follow the passage to the arcade terminal. Optional NPCs: Adaeze, Zuri, Okoye, Ngozi, notice board.
- **Characters**: procedural four-direction renderer (`tools/art25d/chargen.py`): front/back/side strips (idle + 4 walk frames; left = mirrored side), per-character hair, face and costume parameters, accessories, and 512 px vector portraits.
- **Sound**: new footsteps (see §5).

## 4. Character direction (see also `npc_redesign_1.png`, `npc_redesign_2.png`)

Echo and Mira follow their approved designs (Echo: dark skin, short white twists, amber eyes, long black coat with indigo lining, silver shoulder armor, glowing violet gauntlet; Mira: dark brown skin, long curls, gold band, violet cape). Everyone else is a **demo-only** NPC invented for this slice; their designs need owner approval. All twelve characters are Black with different skin tones, hair textures (twists, afro, locs, braids, puffs, bantu knots, fade, gele headwrap, bald), face structures and builds.

Redesign process: first pass ("before") -> pass A (recommended: accessories, glow accents, tinted inner lines + thick silhouette line, hair highlights, warm skin shading, per-character costume layers and expressions) -> alternate B per NPC. The sheets show before / A / B for the ten NPCs with a one-line rationale each.

**Recommended cast direction (my pick; the owner decides):** A for Kofi, Imani, Zuri, Ngozi, Sade, Tunde, Musa and Okoye; **B for Adaeze** (silver locs read as an elder instantly and give a distinct silhouette) and **B for Bayo** (bleach-amber twists make a memorable silhouette). Rationale per character is the caption on each sheet row. Rule applied: if a character still read as a placeholder after pass A, it got a bolder alternative instead of a recolor.

**Honest assessment:** A is clearly more distinctive than the first pass, but the art is still procedural vector art. It is not the quality of the approved painted key art (`assets/echo_key_art.png`) and I do not consider it final or commercial grade. Hands are simple blobs, torsos are boxy, and costumes are flat compared with the key art. Matching the key art needs hand-painted or properly generated assets, which needs the owner's approval for any paid tool. Recommended next step: approve a direction (A or B per NPC), then commission/produce painted sprite sheets using these renders as layout/silhouette guides.

## 5. Sound

Old footstep: a 70 ms noise burst on a fixed 0.28 s timer. New: heel thump + toe tap (two contacts ~70 ms apart), a surface layer (wet-street splash, wood knock, metal clink), five variants per surface, never the same variant twice in a row, random pitch/volume jitter, an audio-player pool, and playback on the walk-cycle contact frames (stage) or speed-scaled stride timer (Explore). Judged by synthesis design and automated checks only; **I cannot listen to it, so whether it sounds natural still needs a human ear.**

## 6. Test and performance results (actually run)

| Check | Result |
|---|---|
| `tests/test_neon_demo.gd` (headless, deterministic) | 41/41 pass: four-direction movement + facing, walk cycle frames, idle return, perspective scale, y-sort, collisions (stall, world edge, plane edge, traffic stops for a pedestrian), foreground pole fade, camera follow/clamp/depth zoom, NPC dialogue open/close + movement lock, mission steps, puzzle wrong/right order, hidden path, three interiors, art coverage (12 chars x 3 views x 5 frames + portraits), footsteps (5 variants x 3 surfaces, no immediate repeat), demo leaves the profile untouched |
| Browser (Chromium, web export of this branch, `tools/qa/neon_demo_qa.cjs`) | 12/12 pass at 1280x720 keyboard, 844x390 touch and 667x375 touch: movement in four directions, camera tracking, stall collision, interaction prompt, dialogue open/close, clean console. (An earlier scripted run failed 2 checks because blind timed walking ran into traffic/a planter; the script was changed to closed-loop aiming. Not a game fix.) |
| Existing regression suites (19 headless suites incl. phase1, repairs, adventure, live combat, episodes 2-4, release candidate, sprites, layout, ui polish) | all pass after the Sound/DialogueBox/main.gd/Explore edits |
| `tests/capture_neon_demo.gd` screenshots | 15 frames in `docs/demo25d/screens/` (opening, Echo walking in four directions, NPC crowd, plaza, junction puzzle, dialogue, hidden path opening/open, Noodle House, passage, arcade) plus 3 browser touch frames |
| Performance (software GL under xvfb, **not representative of phones**) | frame ~16-17 ms (~63 fps) and ~95 draw calls in the capture view; worst case over 240 frames in the benchmark ~226 draw calls / ~350 objects / ~6.6k primitives; texture memory ~73-84 MB. In the browser the software renderer ran at only ~6-8 fps; that is a SwiftShader limit, but it also means **I have no evidence the web build is smooth on a real phone**. |
| 3D comparison prototype (`tests/bench_depth.gd`) | a stripped scene with the same actor count but no real art/props/rain/reflections: 83 draw calls, ~40 MB; not like-for-like, so it does not prove 3D is cheaper or dearer |

**Not tested:** any real Android device/GPU, thermals, battery, sound on real speakers, long sessions, gamepad/Bluetooth input, the web build on real phones.

### Graphics honesty check (do not read the passing tests as "finished graphics")
Compared with the approved Echo key art (`assets/echo_key_art.png`): matches dark skin, short white twists, amber eyes, long black coat with indigo lining, silver pauldron with gold trim, violet gauntlet glow, popped collar. Does not match: painted cel shading and fine detail, angular face structure, coat folds and layered armor, the energy blade, cinematic lighting. Echo's front/back walk is a deliberately small step cycle (leg lift, arm swing, weight shift); it reads as walking but is far from fluid. Hands are simple, torsos boxy. The environment is procedural (lit windows, neon signs, wet street, rain, reflections, glow) and reads as a moody neon street, but it is not hand-painted anime backdrop quality. Treat all of this as a working prototype for architecture and direction approval.

## 7. Known gaps / decisions for the owner

1. Approve (or redirect) the 2D layered 2.5D architecture before any episode is ported.
2. Approve the redesign direction per NPC (A / B / mix); decide how final painted art will be produced (paid image tools need explicit approval).
3. Echo/Mira 4-direction adaptations are proposals matched to the approved designs, not approved sprites.
4. Existing episodes still use the old flat side-view scenes and portraits (blurry faces remain there until portraits are replaced).
5. Android performance must be measured on real devices before committing to this budget.
