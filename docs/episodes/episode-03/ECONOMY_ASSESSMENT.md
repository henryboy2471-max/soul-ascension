# Episode 3 reward assessment (provisional 180 XP / 340 gold, replay 80 / 150)

Status: review-only analysis from the code and data, no human playtest. Pinned by `tests/test_economy_ep123.gd` (12 checks, in the suite). **Recommendation: leave the provisional values as they are.** Nothing here needs Henry's decision yet; the values stay flagged provisional until the two missing inputs below exist.

## What the data says (`scripts/missions/mission_defs.gd`, `scripts/progression/progression.gd`, `scripts/economy/economy.gd`)
| | 1-1 | 1-2 | 1-3 (provisional) |
|---|---|---|---|
| First clear | 120 XP / 250 gold | 150 XP / 300 gold | 180 XP / 340 gold |
| Replay | 55 / 100 | 65 / 120 | 80 / 150 |
| Replay as % of first (XP / gold) | 46% / 40% | 43% / 40% | 44% / 44% |
| Energy cost of the run | 6 (boss battle) | 6 | **0** |
- XP rises by a constant 30 per episode, gold by +50 then +40, so 1-3 continues the existing curve. Replay ratios sit in the same 40-46% band as 1-1 and 1-2.
- XP per level is `100 + 65 x (level - 1)` (100, 165, 230, 295, ...). On the intended path a fresh profile is level 2 with 20 XP after 1-1, level 3 with 5 XP after 1-2, and still **level 3 with 185 of 230 XP after 1-3**: Episode 3 does not by itself produce a level-up on the intended path. (The level-up seen on the rewards screen in the QA browser runs happens only because the QA flavor marks 1-1 and 1-2 cleared without paying their rewards; do not read it as the real experience.) Two replays (160 XP) would carry a player to level 4.
- Gold: 500 at the start, 1390 after the three first clears. **Gold has no sink yet**: the Shop and other menus say SOON, and the Upgrade screen says gear and material upgrades arrive in later episodes. So the gold values cannot be tested for balance beyond the arithmetic above.
- XP: levels add combat stats (24 health, 3 attack, 2 defense per level, per the Upgrade screen). Episode 3 has no combat battle (the Warden is an arena of mechanisms and telegraphs, not the battle scene), so its XP only matters for Episode 1-2 replays and later episodes.
- Optional content (Pip's trail, hidden registry, sealed chamber, witnesses) pays no XP or gold, only Codex entries; the Episode 3 rewards are paid once, at the finale, on the first clear (replay pays the replay amounts once, covered by `test_relay_m4`).

## Risks and judgement
1. **Unmetered replay [Inference]**: Episodes 1 and 2 replays cost 6 energy (1 energy regenerates per 300 s, cap 120), so they are rate-limited. A 1-3 replay costs 0 energy and pays 80 XP / 150 gold, limited only by the time to replay the route (the story restarts from the market with a clean save; the cinematics have a SKIP button). There is no human timing for any episode, so I cannot say whether 1-3 replays would pay more per minute than 1-1/1-2 replays. Today it does not matter: gold is inert and the extra XP is only useful for combat levels. It starts to matter the moment a gold sink or XP-gated content ships. At that point either give the 1-3 replay an energy cost or lower its replay payout; this is a tuning knob, not a decision to make now.
2. **Scripted run length is not play time**: the full-route browser bot (keyboard, 1280x720) took 540 to 1401 s depending on machine load (three runs in parallel were the slowest), with perfect solutions and no thinking time; the earlier story proposal estimated 20-25 minutes for a person ([Inference], unmeasured). The bump from 150 to 180 XP (+20%) is modest next to an episode that is likely longer than 1-2; if human playtests show Episode 3 is much longer than Episode 2, raise the first-clear reward rather than the replay.
3. **No sink and no human data means the rewards are not final**: sign-off needs (a) at least one real playthrough time for Episodes 1, 2 and 3, and (b) the first gold sink. Until then the flag stays.

## Not done
No human playtest, no per-minute comparison, no balance pass on Warden difficulty against reward, no change to any reward value or energy cost.
