# SOUL ASCENSION - OFFICIAL EPISODE 3 DEVELOPMENT HANDOFF: THE RELAY KEEPER
(Official plan written by ChatGPT, delivered by the owner in chat; copied here as the source of truth. Claude does not edit the story. Status: story and exploration-first direction APPROVED; staged development authorized on its own branch.)

Season: 1 of 10 episodes. Engine: Godot 4. Primary QA: browser build. Future platform: Android.

## 1. Core creative direction
SOUL ASCENSION is a premium anime adventure game, not primarily a fighting game. Episode 3 must emphasize: freely controlled exploration of interconnected areas; investigating mysteries and finding hidden clues; meaningful conversations and NPC relationships; environmental puzzles and interactive objects; optional missions that reveal deeper lore; beautiful anime environments and character artwork; cinematic story moments without excessive interruption; one significant boss encounter tied to the mystery. Avoid repetitive combat, placeholder battle graphics, sluggish movement, and long sequences where the player cannot interact. Exploration and discovery are the primary experience.

## 2. Official story continuity
Episode 2 ended with the Hollow Cantor defeated and the Rain Array's secrets partially exposed. Seven connected arrays exist. Vaust announced a 48-hour Resonance Amnesty, and Echo's name appeared in the Ascendant registry. Mira warned that someone already knew Echo's identity. Episode 3 begins shortly afterward in Lantern Quarter. Residents hear voices from abandoned relay towers, including voices of missing relatives and messages about events that have not happened. Echo and Mira investigate and meet Teo Marrow, the Relay Keeper. They discover that the relay network stores fragments of human memories and that the seven-array system has been modified. The investigation leads to the Resonance Amnesty registry, Echo's mysterious history, and the First Memory. At the Central Relay Tower, the player restores corrupted mechanisms and confronts the Relay Warden. The Warden recognizes Echo and unlocks a recording from years earlier containing Echo's exact Resonance signature. The final revelation identifies someone known as the First Echo. End with a cinematic cliffhanger leading into Episode 4: THE FIRST ECHO.

## 3. Main characters
Echo (player-controlled protagonist; curious, increasingly unsettled by evidence of their forgotten connection to the array network). Mira (companion and narrative guide; helps interpret clues but does not automatically solve puzzles). Teo Marrow (Relay Keeper who understands the abandoned network; initially cautious, eventually an ally). Anselm Dray (former Meridian registry clerk who conceals evidence of falsified and unusually old Ascendant records). Pip (Lantern Quarter child searching for answers about a missing family member; central to the emotional optional quest). Relay Warden (ancient guardian protecting the Central Relay; its original purpose has been corrupted). Reuse established Episode 1-2 character designs and continuity. Create new character concept sheets before replacing existing approved assets.

## 4. World and exploration - five connected playable areas
A. Lantern Market: civilian NPCs, illuminated stalls, branching walkways; three witnesses with different versions of the same incident; signal disturbances that can be investigated; hidden journal and optional clues.
B. Meridian Transit Station: abandoned platforms and administrative archives; searchable records, access terminals, locked rooms; meet Anselm and investigate the Ascendant registry; a spatial puzzle to reach sealed files.
C. Forgotten Alleyways (optional area): Pip's missing-family-member quest; hidden memory fragments and environmental storytelling; an optional shortcut unlocked through investigation.
D. Teo's Workshop: central evidence board and signal-decoding equipment; assemble discovered clues into a coherent theory; restore a broken relay map; reveal the connection between the seven arrays.
E. Central Relay Tower: large atmospheric interior with interconnected floors; three distinct resonator puzzles; environmental hazards and unlockable pathways; Relay Warden encounter; final archive and Episode 4 cliffhanger.
Design these as connected, explorable spaces appropriate for the existing game architecture and performance budget. Do not promise a seamless open world unless the engine and existing code support it.

## 5. Main mission structure
3-1 Voices in the Rain: explore Lantern Market and investigate three unusual transmissions.
3-2 The Missing Register: question Anselm and locate hidden Ascendant records.
3-3 Fragments of the Past: recover memory fragments and investigate the Forgotten Alleyways.
3-4 The Keeper's Secret: meet Teo, reconstruct the signal route, and decode the relay map.
3-5 The Seven Connections: enter the Central Relay Tower and solve three distinct environmental puzzles.
3-6 The Warden's Truth: restore the corrupted guardian's original instructions through a cinematic encounter involving player-controlled movement and mechanisms.
3-7 The First Echo: unlock the archive, recover the historical recording, and complete the episode.
Ensure mission objectives update correctly and exploration choices matter.

## 6. Optional quests and secrets (at least three)
Pip's missing-family-member memory trail; hidden registry entries revealing earlier Ascendant candidates; a sealed relay chamber containing an additional fragment of the First Memory. Optional content provides meaningful lore, collectibles, or cosmetic rewards. No optional quest may permanently block the main storyline. Player investigation can unlock extra dialogue during the finale.

## 7. Puzzles and investigation (three different designs)
1. Signal Frequency: identify a transmission by matching waveform or audio-visual patterns. 2. Power Routing: reconnect physical energy paths and activate a damaged relay. 3. Memory Reconstruction: place evidence fragments into the correct sequence using discovered clues. Puzzles must give understandable feedback, remain solvable, and support returning after leaving the area. Provide optional hints that don't immediately reveal the solution. Support keyboard, mouse, and touch-friendly controls where applicable.

## 8. Relay Warden encounter
Not a conventional defeat-the-boss fight. The Warden uses telegraphed attacks while Echo navigates the arena and restores three corrupted mechanisms. The player must avoid visible, readable attack patterns; discover how the arena machinery works; activate mechanisms in the intended sequence; use the environment to interrupt the Warden; restore the guardian rather than destroy it. Finish with the Warden recognizing Echo and unlocking the archive. Provide a checkpoint so failure doesn't require replaying the entire tower.

## 9. Cinematics and dialogue
Required: episode opening overlooking the rain-soaked Lantern Quarter; Teo revealing the true nature of the memory network; Anselm exposing Echo's historical registry entry; Relay Warden recognition scene; final First Echo recording. Keep cinematics concise and polished. Use expressions, portrait changes, camera movement, environmental effects, sound, and readable subtitles. Do not remove player control during normal exploration.

## 10. Visual direction
Preserve the established premium anime art style: detailed illustrated environments; expressive anime character portraits; consistent proportions and designs; purple, violet, blue and warm-gold lighting; atmospheric rain, lighting and particle effects; distinct environmental silhouettes; high-quality UI and readable quest markers; polished movement and animation. No generic placeholder characters in the final approved build. Maintain consistent designs between menus, exploration, dialogue and cinematic sequences. Prepare sample artwork for review before producing major batches of new assets.

## 11. Progression and saving
Separate mission completion flags; exploration discoveries and codex updates; optional quest progress; persistent puzzle state; checkpoints before major encounters; rewards and progression after completion; unlocking Episode 4 when ready. Do not overwrite Episode 1-2 saves or progression. Returning players resume at a valid checkpoint.

## 12. Development milestones (complete and test each before starting the next)
M1 Exploration: Lantern Market and connected areas, basic interactions, responsive movement, camera behavior, traversal tests.
M2 Investigation: NPC dialogue, quest tracking, discoverable clues, optional side quests, evidence gathering.
M3 Puzzles: signal, power-routing and memory-reconstruction mechanics.
M4 Cinematics and Boss: Warden encounter, archive reveal, character expressions, story scenes.
M5 Polish and Testing: artwork integration, performance, saving, regression tests, browser playthroughs.

## 13. Development safety / 14. First action / 15. Reporting
Inspect architecture and latest approved Episode 1-2 work; dedicated Episode 3 branch from the correct integration point; do not overwrite completed work; preserve Episodes 1-2; run existing tests after each milestone; verify keyboard and touch; report actual test results; no merge to main/deploy without approval; do not start Episode 4; keep changes reviewable; use approved, legally usable assets and document licenses. After each milestone report: what was implemented, tested/passed, failed/unfinished, branch and commit, screenshots or preview, what needs owner approval. Do not claim completion until verified.
FINAL DIRECTIVE: exploration-first anime mystery, connected world, meaningful player choices, atmospheric environments, dramatic story revelation; exactly 10-episode Season 1.
