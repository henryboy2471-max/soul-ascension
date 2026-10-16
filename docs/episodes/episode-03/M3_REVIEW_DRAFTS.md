# Episode 3 M3: puzzle targets and wording: drafts for review (Henry)

Generated from the code at the M3 commit (`ebc97aa`) so the text below is exactly what the game shows. **All of it is Claude's draft. Nothing here is from `STORY_PLAN.md`** beyond the three design briefs in §7 (signal frequency, power routing, memory reconstruction) and the Mira/Echo/Teo characterisations. Please approve, edit or reject each block. Where I judge difficulty, that is [Inference]: none of it has been played by a person.

How to reply: for each section answer APPROVE / CHANGE (with your wording or numbers). The strings live in `scripts/puzzle/puzzle_logic.gd` and `scripts/story/episode3_data.gd`, so edits are cheap and do not touch puzzle code.

---
## 1. Signal Frequency (floor 1, "signal resonator")
Brief in the plan (§7.1): *"identify a transmission by matching waveform or audio-visual patterns."*

Mechanic as built: three rounds, one per transmission the player scanned in the market. The recorded wave is drawn in cyan, the live wave in gold; turn FREQUENCY (1 to 12 waves) and HEIGHT (1 to 8) until they overlay, then LOCK. Knobs start at frequency 6, height 4.

| Round | Transmission | Target frequency | Target height | Descriptive hint (hint 1) |
|---|---|---|---|---|
| 1 | THE LULLABY | 3 | 3 | Slow and soft: only a few waves, and none of them tall. |
| 2 | THE BULLETIN | 8 | 5 | Quick and clipped: many waves, of middling height. |
| 3 | THE LONG TONE | 5 | 7 | A steady note with a deep swell: a middling count of tall waves. |

- Feedback by distance from the target (frequency steps + height steps): 0 → `LOCKED  /  THE PATTERNS MATCH`; 1 → `VERY CLOSE  /  ONE MORE TURN`; 3 → `CLOSE  /  THE PATTERN ALMOST FITS`; 6 → `OFF  /  THE WAVES DO NOT FIT YET`. Thresholds: 0 locked, 1-2 very close, 3-5 close, 6+ off.
- Hint 2 (direction, never the value): `FREQUENCY: too high   /   HEIGHT: too tall` (shown for the live knobs; values vary).
- On-screen text: **SIGNAL RESONATOR**: "Match the live wave to the recorded transmission. Turn FREQUENCY (how many waves) and HEIGHT (how tall), then LOCK."

Review notes:
- The targets (3/3, 8/5, 5/7) are arbitrary numbers I picked so each wave looks different; the round names tie them to the M2 scene (lullaby, tram bulletin, the tone that matches Echo). [Inference] Difficulty is low because the recorded wave is visible; if you want it harder the options are: hide the recorded wave and show only a description, dim it, or add the audio cue (the game has no puzzle audio yet).
- The third round's hint says "deep swell"; there is no sound, so that word is flavour, not information.

---
## 2. Power Routing (floor 2, "power resonator")
Brief in the plan (§7.2): *"reconnect physical energy paths and activate a damaged relay."*

Mechanic as built: a 6×4 board of rotatable pipe tiles. Current flows from the source tile (left, row 3) to the relay lamp (right side). Burnt tiles carry nothing. Tap/click a tile or use arrows + Enter to turn it clockwise. Powered tiles glow; the header counts how far the current reaches.

Board (S source, R relay lamp, X burnt, | straight, L corner, T tee; `*` marks the intended path):
```
X   |   L   L   |   L 
L   L*  T*  L*  T   R 
S   L*  T   L*  |*  L*
|   L   T   L   |   X 
```
- Intended path (cell indexes, source to relay): [12, 13, 7, 8, 9, 15, 16, 17, 11]; solving rotations: cell 7 (x1,y1): rot 1, cell 8 (x2,y1): rot 0, cell 9 (x3,y1): rot 2, cell 13 (x1,y2): rot 3, cell 15 (x3,y2): rot 0, cell 16 (x4,y2): rot 1, cell 17 (x5,y2): rot 3.
- Fixed starting scramble for those tiles: cell 7 rot 3, cell 8 rot 1, cell 9 rot 0, cell 13 rot 0, cell 15 rot 1, cell 16 rot 0, cell 17 rot 0. No path tile starts in its solving rotation; the minimum number of turns from the start is 17 (measured by `test_puzzle_logic`).
- [Inference] The decoys make wrong turns visible rather than hidden, so this is the middle difficulty of the three. The board is the same every time (no randomness), so it is testable and solvable by construction (a search over tile orientations proves a connecting rotation exists).
- Hints: hint 1 `Follow the current from the source. It stops where a tile does not meet its neighbour.`; hint 2 `A tile on the way is turned the wrong way. It is marked.` (the first wrong tile on the intended path pulses red).
- On-screen text: **POWER RESONATOR**: "The relay is dead. Tap a tile to turn it and send current from the source (left) to the relay lamp (right side). Burnt tiles carry nothing."

---
## 3. Memory Reconstruction (floor 3, "memory resonator")
Brief in the plan (§7.3): *"place evidence fragments into the correct sequence using discovered clues."*

Mechanic as built: the evidence the player already found becomes fragment cards; each card only appears if its clue was found. Place all four from oldest to newest, then CHECK. The correct order is fixed and the cards carry their own "when".

| Order | Card title | Card text | Appears when the player has |
|---|---|---|---|
| 1 | REGISTRY LINE | Filed years before the first awakening. | clue `records` |
| 2 | DELETED INDEX | Forty files deleted by hand six nights ago. | clue `terminal` |
| 3 | THE LONG TONE | Heard in the market tonight, in Echo's own note. | clue `tx_3` |
| 4 | CRASH BULLETIN | Tram forty-one. Dated tomorrow evening. | clue `tx_2` |

- Feedback (**revised per owner**: the "N OF 4 IN PLACE" count is removed): incomplete → `PLACE ALL FOUR FRAGMENTS, THEN CHECK`; wrong order → `NOT YET  /  THE ORDER IS WRONG`; solved → `THE MEMORY HOLDS  /  IN ORDER`.
- Hints: hint 1 `Oldest first. Look for the words that say WHEN.`; hint 2 `The oldest fragment is the one about the registry.`.
- On-screen text: **MEMORY RESONATOR**: "Place the four fragments from the oldest to the newest. Select a fragment, then choose its slot."

Review notes (be critical here):
- The order is decided by the time words on the cards ("years before", "six nights ago", "tonight", "tomorrow evening"). Those words come from the M2 dialogue you approved (registry "years before the first recorded awakening"; terminal "six nights ago"; bulletin "tomorrow evening"); "tonight" for the long tone is my addition, since the plan gives no date. **Owner decision: keep "tonight".**
- [Inference] This is the easiest of the three: there is no decoy fragment, only one of 24 orders is right, and (before the owner-approved revision) an "N OF 4 IN PLACE" count let a player narrow it down. That count is now removed; CHECK only says solved or not. [Inference] A player can still brute-force it with CHECK, just more slowly. Further options if you want it harder: add a decoy from an optional clue, or word the cards without explicit time words. If you want it to matter for story, the order could instead follow the plan's chain (counted, kept, replayed, answered), but that would need new canon wording from you.
- All four cards come from main-path clues, so the puzzle can never be blocked by skipping optional content.

---
## 4. Resonator, chamber and archive dialogue (draft)
Mira introduces each puzzle but never solves it.

**Signal resonator, first visit**
> **NARRATOR**: The first resonator stands silent, its dial ring dark. Your scanner stored every transmission you heard. It can be tuned to each of them.
> **MIRA**: Line the waves up until they match. I'll hold the lamp, but the dial is yours.
Repeat visit: > **NARRATOR**: The resonator waits for you.
**Signal solved**
> **NARRATOR**: The three transmissions lock one after another. The resonator draws breath, and somewhere above, a stairwell door unlatches.
> **MIRA**: The lullaby, the bulletin, the tone. They were all pointed at this room.

**Power resonator, first visit**
> **NARRATOR**: The power resonator is dead. A relay lamp waits at the far end of a broken conduit board, and current cannot reach it.
> **MIRA**: Burnt tiles carry nothing. Find a way around them.
**Power solved**
> **NARRATOR**: Current reaches the relay lamp. Light climbs the stairwell in a flicker, and somewhere in the wall a sealed chamber hums awake.
> **MIRA**: Hear that? Something behind the panel just got its power back.

**Memory resonator, first visit**
> **NARRATOR**: The memory resonator holds fragments of everything you have gathered, scattered out of order.
> **MIRA**: Evidence is only a story once it is in order. What happened first?
**Memory solved**
> **NARRATOR**: The fragments fall into line. For a moment the resonator replays the whole chain, and at the end of the floor the sealed archive gate stirs.
> **MIRA**: Evidence in order is a story. I don't like how this one ends.

**Sealed chamber (optional quest; appears after the power resonator is restored)**
> **NARRATOR**: Behind the panel the power just woke, a sealed chamber: one cradle, holding a recording crystal, mostly static. A voice counts seven, softly.
> **PLAYER**: Counting what?
> **MIRA**: I don't know. But I don't think it's ours to take apart.
Plan §6 names this: *"a sealed relay chamber containing an additional fragment of the First Memory."* **Owner revision applied:** only the voice counting seven remains; the lamp and "We kept it safe in the towers" are removed here, from the finale payoff and from the Codex text.

**Archive gate**, while a resonator is silent:
> **NARRATOR**: A sealed archive gate. Three resonators feed it: 1 of 3 restored.
**Archive gate**, all three restored:
> **NARRATOR**: The sealed archive gate answers at last. Behind it something large shifts in the dark, a guardian old enough to remember the tower being built.
> **MIRA**: Echo... something in there is waking up. Whatever it is, it knows we're here.

**Stair locks:** floor 2: `LOCKED  /  THE STAIRS WAKE WHEN THE SIGNAL RESONATOR SINGS`; floor 3: `LOCKED  /  THE STAIRS WAKE WHEN THE POWER RESONATOR BURNS`.

Quest line the HUD shows after the tower is entered: Restore the signal resonator on the first floor → Restore the power resonator on the second floor → Reconstruct the memory resonator on the third floor → Examine the sealed archive at the top of the tower.
