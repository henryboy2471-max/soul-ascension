# Episode 3 M4: drafts for Henry's review (revision 2)

Generated from the code (so this is exactly what the game says and does). **Every line, number and Codex text below is Claude's draft** unless marked as owner-approved. The plan fixes only the beats (§9: opening, Teo reveals the memory network, Anselm exposes Echo's registry entry, Warden recognition, First Echo recording; §8: the Warden is restored, not destroyed). Marked [Inference] where I am judging difficulty or fit without a player.

## Revision 2: what changed since the first draft (owner instructions)
- **No unsupported timeline.** The opening no longer says "the morning after the Rain Array fell silent" or that it is "third time since sunrise". It now says "shortly after the Rain Array fell silent" (the plan: "Episode 3 begins shortly afterward in Lantern Quarter") and "the third time today". [Inference] "Third time today" still implies the same day, which is mild; say if you want that removed too.
- **Echo and the First Echo stay open.** Removed: "RETURN... NOT EXPECTED", "THE SIGNATURE THAT WAS FILED FIRST", "It is your note, to the last decimal", "That isn't a copy. That's you.", "Or whoever I came from", and "Whoever carries it now will come looking for the one who first sang it". **Kept: the exact signature match and the Vaust hook.** The scenes now say only that the signature matches exactly ("MATCH: ARCHIVE RECORD 0001. EXACT.", "It matches yours exactly.", "That's your signature. Exactly.") and end on Echo's question "Then who is the First Echo?". Nothing says Echo is, is not, or descends from the First Echo.
- **Sealed fragment (owner-approved M3 revisions applied):** only the voice counting seven remains; the lamp and "We kept it safe in the towers" are gone from the chamber, the finale payoff and the Codex text. "tonight" stays on the long-tone card, and the memory puzzle no longer reports how many cards are in place.
- **Rewards are provisional** (section 7).

For each block reply APPROVE / CHANGE (with your wording). Text lives in `scripts/story/episode3_data.gd` (CINE, CODEX, `finale_extras`), numbers in `scripts/story/warden_logic.gd`, puzzle data in `scripts/puzzle/puzzle_logic.gd`.

---
## 1. Cinematics (draft dialogue)
**Episode opening (plan §9.1)**
> **NARRATOR**: Lantern Quarter, shortly after the Rain Array fell silent. Every Meridian screen still loops the same announcement: forty-eight hours.
> **NARRATOR**: Up on the rooftops the old relay towers stand dark. Down in the market, the speakers have started to talk.
> **MIRA**: Echo. The tower on Ninth just spoke again, the third time today. People are standing in the street, listening.
> **PLAYER**: Listening to who?
> **MIRA**: That's what we're here to find out. Stay close, and don't flinch when you hear your own name.

**Anselm exposes Echo's registry entry (§9.3), after the sealed door opens**
> **NARRATOR**: The rail lock slides home. Behind the door is a single drawer of cards, each stamped with the same faded seal.
> **ANSELM**: I told myself these were all burned. I lied, even to myself.
> **NARRATOR**: He draws out one card. It is the original of the line someone scraped bare: a signature column, still inked.
> **ANSELM**: Hold your hand over the signature.
> **NARRATOR**: The card hums on one long, low note. Your note.
> **PLAYER**: That's the tone from the market. From the tower.
> **ANSELM**: The same signature, filed years before the first awakening on record. Whoever scraped the other copy knew exactly whose it was. I think they knew before you did.
> **MIRA**: Someone already knew who you were, Echo. I said it out loud. I just didn't want it to be this.
> **PLAYER**: Who filed it?
> **ANSELM**: The handler column is blank. It's the only line anyone ever thought to erase completely. Take the card to Teo. The towers keep what the registry lost.

**Teo reveals the memory network (§9.2), after the relay map is repaired**
> **NARRATOR**: Seven lamps wake on the chalk map, and the old relay network lights up the wall of Teo's workshop.
> **TEO**: There. Seven arrays, all on one line. Not antennas. Memory.
> **TEO**: Everyone who has stood in the rain in this quarter has been recorded a little: a name, a lullaby, the last thing they said. The towers keep it, and play it back to anyone who listens hard enough.
> **MIRA**: That's what the voices are. Somebody's missing family, still talking.
> **TEO**: And someone changed the system. It used to keep. Now it chooses what to keep, what to replay, and to whom.
> **PLAYER**: My note is in there too.
> **TEO**: At the very bottom, older than everything above it. I can't hear the Central Relay. Whatever it holds, it holds from before.

**Arrival in the Warden's chamber**
> **NARRATOR**: The Central Relay is a drowned cathedral of cable. Three huge mechanisms stand dark along its length, and at the far end something very old turns toward you.
> **WARDEN**: UNREGISTERED SIGNATURE. HOLD POSITION.
> **MIRA**: It isn't threatening us. It's reading us. These machines were meant to be started in some order. Look for a plaque, an inscription, anything.

**Warden recognition scene (§9.4), after the third mechanism**
> **NARRATOR**: The last mechanism turns. The Warden's light flickers, steadies, and finds you.
> **WARDEN**: SIGNATURE CONFIRMED: ECHO.
> **WARDEN**: MATCH: ARCHIVE RECORD 0001. EXACT.
> **PLAYER**: Exact? Whose record?
> **WARDEN**: ORIGINAL INSTRUCTION RESTORED: KEEP. NEVER CHOOSE. THE ARCHIVE OPENS FOR THIS SIGNATURE.
> **MIRA**: This signature. Echo...
> **NARRATOR**: At the end of the chamber, the sealed archive latch lets go.

**The First Echo recording (§9.5), at the archive core**
> **NARRATOR**: A single crystal cradle, and static. Then a voice, calm and tired and a very long time ago.
> **RECORDING**: Recording zero. If you are hearing this, the arrays have been changed, and the keeping has become a choosing.
> **RECORDING**: The signature in this recording is exact. It belongs to the First Echo, the resonance all the others learned from.
> **RECORDING**: If the note in your chest answers it, then Vaust is listening for the same note. Do not let Vaust find the First Echo.
> **NARRATOR**: The note rolls out of the crystal. It matches yours exactly.
> **MIRA**: Echo. That's your signature. Exactly.
> **PLAYER**: Then who is the First Echo?
> **NARRATOR**: Far above, every Meridian screen in the Quarter flickers to the same word: ECHO.

Presentation (no new art): letterbox bars, a slow push-in on the opening and arrival scenes, a violet flash and a shake on recognition and the recording, name plates for Teo, Anselm, the Warden and the recording (only Echo and Mira have portraits). Control is handed back after each scene; the dialogue box carries the subtitles. No sound exists yet.

Review notes (be critical here):
- **Kept by instruction:** the exact signature match, and the Vaust hook ("Do not let Vaust find the First Echo").
- The Warden's "SIGNATURE CONFIRMED: ECHO" and "MATCH: ARCHIVE RECORD 0001" and the recording's "It belongs to the First Echo" together make the First Echo a record and a person-or-signature that the story has not yet identified. [Inference] A player will probably suspect Echo; the text does not say so.
- "If the note in your chest answers it" assumes the listener has the note; it is Echo's own line of sight, not a claim about origin.
- The exposure scene says the card is the original of the line scraped in M2 and that "whoever scraped the other copy knew exactly whose it was": that is about the registry entry (approved M2 setup), not about the First Echo.

## 2. Finale payoffs from the investigation (plan §6)
Each saved clue adds one line to the recording scene, before the closing screen-flicker line. A run that investigated nothing gets none.
- **first_memory_fragment**: The crystal from the sealed chamber answers it: the voice counting seven.
- **hidden_registry**: The candidates ledger had a dozen names, each marked RETAINED or LOST. This voice isn't one of them.
- **journal**: The technician's journal was right. The towers aren't broadcasting. They're remembering.
- **pip_done**: In your pocket, Lio's lamp glass hums, very faintly, on the same note. Somewhere in the static behind the recording a boy laughs: 'Pip, catch!'
- **w_a**: Three people, three different nights. The towers answer whoever is listening. That's why nobody heard the same thing.

(`w_a` means all three witnesses were questioned.) Which clue unlocks which line is my choice. Note: the **pip_done** line mentions "Lio's lamp glass", which is Pip's keepsake from the approved M2 scene, not the removed sealed-chamber lamp; say if you want it changed too.

## 3. Arena inscription and puzzle intros
**Brass plaque (gives the mechanism order)**
> **NARRATOR**: A brass plaque is bolted to the wall, worn smooth by a great many hands.
> **NARRATOR**: 'TO WAKE THE GUARDIAN, WAKE THE TOWER IN THIS ORDER. FIRST THE VALVE, THAT THE TOWER MAY BREATHE. THEN THE BELL, THAT IT MAY BE HEARD. LAST THE SEAL, THAT THE GUARDIAN MAY HEAR ITSELF. WAKE THEM OUT OF ORDER AND THE TOWER WILL ANSWER WITH ITS FEAR.'
> **MIRA**: Valve, bell, seal. And it won't be left to right. Read the machines.

**Sealed archive door, first visit after the records are found**
> **NARRATOR**: With the old registry in your hands, the door's rail lock makes sense: a gold carriage jammed at the left end of a track, blocked by loose bars.
> **MIRA**: It's a lock made of blocks. Slide them clear and the carriage can run out the end. Slowly. It's older than both of us.

**Relay map, first visit after the evidence board**
> **TEO**: Now that you've laid it all out, this is the piece I couldn't mend alone: the old map of the network. Seven arrays on one line, all dark.
> **TEO**: Turn the tiles until the current reaches every lamp. I'll hold the chalk.
> **MIRA**: Don't look at me. I'm not allowed to solve this one for you.

**Archive gate while the map or the door is unrepaired**
> **NARRATOR**: All three resonators answer, but the archive gate keeps two dark lights lit, as though two other keys are still missing: one from the Keeper's workshop, one from the station's sealed archive.

**On solving**: door: The carriage runs out along the rail and the lock gives with a sound like a held breath.  Map: The last tile turns. Seven lamps wake on the chalk map, one after another.

## 4. The Warden fight (numbers)
It is not a defeat-the-boss fight: Echo restores three mechanisms in the order on the plaque (VALVE, BELL, SEAL); each correct one interrupts the Warden for 6 s; a wrong one costs Echo one resonance point and rouses the Warden. Echo has 5 resonance points; at 0 the attempt resets to the last checkpoint (the entrance, or beside the last restored mechanism) with full resonance and restored mechanisms kept.
- Attack cycle: telegraph 1.7 s (red floor zone with a closing bar), strike 0.35 s, recover 1.0 s; first attack 2.5 s after the chamber starts; invulnerability 1.5 s after a hit. Patterns repeat as slam, sweep, pillars, slam, sweep: slam (240 px wide, centred where Echo stood), sweep (300 px in front of the Warden), pillars (two 180 px zones flanking it).
- Fairness is proven by test: from every position, every pattern can be left within the telegraph time (a player who reacts in 0.4 s and walks at 85% speed covers 331 px; the worst case any pattern ever requires is 161 px). The Warden drifts toward Echo between attacks but stops 340 px away.
- Holding E to restore a mechanism takes 1.4 s, so it can be started in the recover window and finished before the next strike, or aborted to dodge.
- [Inference] Difficulty: the plan asks for readable attacks and a puzzle-like fight, so I tuned toward forgiving (1.7 s telegraphs, 5 points, free checkpoints). Not playtested by a person; if it feels too easy, shorten the telegraph (under the same fairness model 1.3 s still leaves 230 px of reach against the 161 px worst case; the proof test would be re-run) or add a fourth pattern.
- The Warden is currently the pedestrian rig scaled up and tinted: a placeholder. The plan says no generic placeholder in the final build, so this needs approved art (M5).

## 5. The two carried-over puzzles
- **Sealed archive door (station), a sliding-rail puzzle**: 6x6 board, 7 blocks, the gold carriage must run out of the right edge; shortest solution is 11 moves (proven by search; every position reachable by sliding can still be solved). This is the "spatial puzzle to reach sealed files" (§4B). It is a fourth mechanic beyond the plan's three designs; you approved building it.
- **Relay map (workshop), the power-routing mechanic on a bigger board**: 7x5, one source, seven array lamps, 23 tiles on the solution line, the rest decoys. All lamps must be lit. No new design: the same rules as the power board. Its payoff is Teo's reveal.

## 6. New Codex entries (secret until found)
- **ECHO'S REGISTRY ENTRY** (echo_entry): The original card from the sealed archive door: a signature that hums one long note, filed years before the first awakening. The handler column is blank.
- **THE SEVEN ARRAYS** (seven_arrays): Seven relay arrays on one line. Not antennas but a memory network: everything said in the rain is kept, and someone changed what it keeps and replays.
- **THE RELAY WARDEN** (relay_warden): The guardian of the Central Relay. Its first instruction was to keep, never to choose. It recognised Echo's signature on sight.
- **THE FIRST ECHO** (first_echo): Recording 0001 carries the signature of the First Echo, the resonance every other signature learned from. It matches Echo's exactly. Who the First Echo is has not been said.
- **A Sealed Fragment** (first_memory, from M3, revised): A recording crystal in a sealed relay chamber holds a voice counting seven.

## 7. Completion and rewards (PROVISIONAL, for your sign-off)
**Reward values for sign-off. These are PROVISIONAL placeholders, not final:**

| | XP | Gold |
|---|---|---|
| First clear (PROVISIONAL) | 180 | 340 |
| Replay (PROVISIONAL) | 80 | 150 |

They are unchanged since the M1 placeholder data, are flagged `provisional` in `mission_defs.gd`, and stay so until you confirm or replace them. Nothing else depends on the numbers (the rewards screen simply shows whatever the data says). For scale, [Inference] Episode 2 pays 150 XP / 300 gold (replay 65 / 120) and Episode 1 pays 120 / 250 (replay 55 / 100).
- The rewards screen offers NEXT EPISODE (EPISODE 4 / THE FIRST ECHO) and REPLAY EPISODE. Replaying starts the story again from the market (progress, puzzles and checkpoints reset; completion, rewards and the Codex are kept). No Episode 4 content exists.
- Mission 1-3 is still **not playable** for players (`playable:false`); flipping that is an M5/release decision.
