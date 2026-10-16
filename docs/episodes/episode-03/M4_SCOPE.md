# Episode 3 M4 (Cinematics and Boss): exact remaining scope, for Henry's sign-off

**Status: not started. Gated for Henry's sign-off.** Branch `episode-3/the-relay-keeper` stays unmerged and undeployed. Sources are cited as `§n` of `STORY_PLAN.md` (the official plan, unchanged). "Today" = after M3 at commit `ebc97aa` plus the doc-only reconciliation commit.

## A. The Relay Warden encounter (§8, §5 mission 3-6 "The Warden's Truth")
Required by the plan:
1. Telegraphed attacks that are visible and readable; the player avoids them while navigating the arena.
2. **Three corrupted mechanisms** in the arena that the player restores. [The plan separates these from the three resonators; today the resonators exist and are solved. The arena mechanisms are new.]
3. The player must discover how the machinery works and activate the mechanisms in the intended sequence.
4. Use the environment to interrupt the Warden.
5. Restore the guardian rather than destroy it. The Warden then recognizes Echo and unlocks the archive.
6. **A checkpoint** so failure does not mean replaying the tower; resume at a valid checkpoint (§11).
Today: the archive gate only sets `archive_examined` and says it "stirs". No arena, no Warden, no checkpoint.

## B. The five required cinematics (§9)
1. Episode opening overlooking the rain-soaked Lantern Quarter (today: a title card only).
2. Teo revealing the true nature of the memory network.
3. Anselm exposing Echo's historical registry entry.
4. Relay Warden recognition scene.
5. Final First Echo recording.
Plus: expressions and portrait changes, camera movement, environmental effects, sound, readable subtitles; concise; "Do not remove player control during normal exploration."
Constraint today: portraits exist only for Echo and Mira; Teo, Anselm, Pip and the Warden have name plates only, and there is no puzzle or cinematic audio. The plan says to prepare sample art for approval before major batches, so new portraits need your approved direction.

## C. Finish the episode (§5 missions 3-6 and 3-7, §11)
- 3-7 "The First Echo": unlock the archive, recover the historical recording, complete the episode.
- Ending lines and codex ids (today `ending.lines=[]` for mission 1-3), then the cliffhanger into Episode 4: THE FIRST ECHO (the teaser card data already exists).
- Completion through `Profile.finish_run`: rewards (placeholders today: 180 XP / 340 gold first clear, 80 / 150 replay), completion flag, replay behaviour, separate flags, no overwrite of Episode 1-2 saves.
- Not Episode 4 content. "Unlocking Episode 4 when ready" only means the teaser; nothing of Episode 4 is built.

## D. Finale payoffs from the investigation (§6: "Player investigation can unlock extra dialogue during the finale")
Flags already saved that M4 can read: witnesses (`w_a`, `w_b`, `w_c`), `journal`, `hidden_registry`, `scraped_entry`, `pip_done`, marks `frag_1..3`, `first_memory_fragment`, `map_seen`. Which flag unlocks which extra line is a writing decision for you.

## E. Items the plan names but assigns to no milestone (carried here, see IMPLEMENTATION.md "Scope reconciliation")
- Relay-map repair (area D, mission 3-4): proposed with the Teo reveal (A-B2), reusing the M3 routing or signal mechanics, no new design.
- Archive-door spatial puzzle (area B): proposed with the Anselm exposure (B3). It needs a decision because it would be a fourth puzzle design (the plan says three).
- Optional: if you prefer, drop either to "extra" and keep them out of M4.

## F. Setups from M2/M3 that M4 must pay off (so they are not dropped)
The scraped registry line (humming signature column); Teo's "Not here. In the Central Relay"; the archive stirring; the sealed fragment ("a voice counting seven, ... a lamp"); the Echo-matching tone; Pip's promise "I'll find him" (Lio).

## G. Tests and checks M4 will add (same standard as M2/M3)
Godot flow tests (Warden sequence, mechanisms in/out of order, checkpoint and resume, ending, rewards once, replay), layout test for every new line and screen, the full `tools/run_tests.sh`, and a real-window playthrough at 1280x720, 844x390 and 667x375. Web export, Android, device and performance passes are M5 (§12), not M4.

## H. Decisions I need from you before starting (with my recommendation)
1. **Warden engine approach.** Combat is frozen. Recommended: a new Explore-style arena (player movement plus telegraphed hazard zones plus three mechanisms), not the battle scene, because the plan says "not a conventional defeat-the-boss fight". Alternative: reuse the battle scene with mechanisms layered on. [Inference] The first is more new code but avoids touching frozen combat.
2. **Relay-map and archive-door**: pair with the cinematics in M4 (recommended), or demote to extras.
3. **Approve or edit the M3 puzzle targets and wording** (`M3_REVIEW_DRAFTS.md`).
4. **Cinematic look without new art**: letterbox, camera moves, name plates and the existing Echo/Mira portraits (recommended for M4), with Teo/Anselm/Warden portraits deferred to M5 art. Or pause M4 until sample portraits are approved.
5. **Checkpoint rule**: recommended at the arena entrance and after each restored mechanism.
6. **Rewards and Codex text** for 3-7 (placeholders today).

## Explicitly out of M4
Episode 4; merging to `main`; deploying; major batches of new character art before samples are approved; M5 items (artwork integration, performance, web/Android/device runs); flipping mission 1-3 to playable.
