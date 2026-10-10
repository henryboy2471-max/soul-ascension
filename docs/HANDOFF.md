# SOUL ASCENSION — Handoff (for ChatGPT / next Claude session, via GitHub)

Repo: `henryboy2471-max/soul-ascension`. Godot 4.4.1 (GL Compatibility), GDScript, one-space indentation. Read `CLAUDE.md`, `docs/ADVENTURE.md`, `docs/WORKFLOW.md` first.

## Standing rules (owner)
Season 1 = exactly 10 episodes. Never merge to `main` or deploy/publish without owner approval. No paid services, credits or real money. ChatGPT writes official episode stories/plans; Claude implements; never replace an approved story. Do not start Episode 4 (waiting for ChatGPT's official plan). Report only tests that actually ran; list untested/blocked items separately. No major art batches before the owner approves visual direction.

## Branches (all pushed)
| Branch | Contents | State |
|---|---|---|
| `main` | public build base | untouched |
| `integration/hollow-cantor-v2.1-into-rc`, `dev/overnight-stabilize`, `episode-2/under-the-violet-rain` | Episodes 1-2 release candidate (Cantor v2.1 art, lossless web textures) | verified green earlier; not merged to main |
| `dev/ep1-2-polish` | Episode 1-2 polish | owner has not decided whether to merge into RC |
| `episode-3/the-relay-keeper` (`677241e`) | Episode 3 **M1 Exploration** done: 7 zones/5 areas, `RelayEpisode`, `ZoneDefs`, `RelayArt` (placeholder), tests, `docs/episodes/episode-03/{STORY_PLAN,APPROVAL,IMPLEMENTATION}.md` | M1 tested (headless 19/19; browser touch 12/12; regression green). **Waiting for owner approval of M1 before M2** |
| `monetization/design` (`6f72bd1`) | `docs/MONETIZATION_PLAN.md` (loyalty tiers, Prestige I-III, Hall of Legends, Soul Shop, mock billing, costs [Unverified], decisions D1-D10) + `scripts/shop/*` + `tests/test_shop_design.gd` (12/12) | design/test data only; `PAYMENTS_ENABLED=false`; ledger still single `crystals` (paid/earned split = MON-1) |
| `demo/neon-district-2.5d` (`7019254`) | working 2.5D engine demo (`scripts/demo/*`, `tests/test_neon_demo.gd` 41/41, `tools/qa/neon_demo_qa.cjs` browser 12/12 x3 viewports, 19 regression suites green), new footsteps in `Sound`, `DialogueBox` speaker/portrait override, `main.gd` launcher (`--demo-neon` / `?demo=neon`), docs in `docs/demo25d/` | **Art REJECTED by owner**; engine/gameplay is reusable |
| `art/premium-25d-checkpoint` (this handoff's base) | `docs/demo25d/PREMIUM_ART_CHECKPOINT.md` records the art blocker | no art produced |
| `art/lantern-quarter-mira-samples`, `art/hollow-cantor*`, `art/free-pipeline-proposal` | earlier art samples/proposals | Lantern/Mira samples awaiting owner approval |
| `docs/next-milestone-roadmap` | roadmap docs | |

## Complete
Episodes 1-2 playable and verified; Cantor v2.1 integrated; Episode 3 M1; monetization design + mock shop (test data); 2.5D architecture decision and working demo engine; footstep sound rework; dialogue crisp-portrait support.

## Not complete / blocked
- **Art (top blocker):** owner rejected the procedural characters and city. Premium assets need a generator/artist. Higgsfield MCP is reachable but the account has **0 credits (free plan)** and paid use needs owner approval. No substitute art should be made.
- Episode 3 M2-M5 (investigation, puzzles, cinematics+boss, polish) not started; character concept sheets (Teo, Anselm, Pip, Warden) not made.
- Android: no SDK/devices, so no device tests. Web build smoothness on real phones unmeasured (software GL ran ~6-8 fps in browser QA).
- Existing episodes still use old flat side-view sprites; their blurry portraits (low-res sprites upscaled) are unfixed outside the demo.
- Monetization MON-1+ not started; Google Play fee/policy figures in the plan are unverified.
- Footsteps judged by synthesis/tests only, not by ear.

## Exact next steps (after owner approval)
1. Owner chooses an art route: (a) approved paid generation budget for a checkpoint only, (b) supplied art, or (c) another approved tool. Checkpoint = 1 hero, 1 Black female NPC, 1 city environment at gameplay size, front/side/back movement, 1280x720 screenshots, before/after. Stop for approval before any rollout.
2. Owner approves/rejects Episode 3 M1 -> then M2 on `episode-3/the-relay-keeper` per `docs/episodes/episode-03/STORY_PLAN.md`.
3. Owner decisions pending: Lantern Quarter/Mira samples; merge `dev/ep1-2-polish`; monetization D1-D10; 2.5D architecture approval (`docs/demo25d/ARCHITECTURE_25D.md`); wait for ChatGPT's official Episode 4 plan.
4. Before any push: run `godot --headless --editor --import --quit` (after adding class_name scripts), then the suites listed in `CLAUDE.md` with a separate `XDG_DATA_HOME`.

## Gotchas
In `--script` tests do not reference `class_name`s that use autoloads (Profile/Sound); use `load()` and duck typing. Closing a modal from its own button: hide + queue_free, never remove_child. Headless frames run faster than real time: use real timers. Do not use `pkill` in a compound shell command.

Safe to review on GitHub: all branches above are pushed; nothing was merged or deployed.
