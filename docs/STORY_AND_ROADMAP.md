# The Unbound Chronicles

## Original universe

Twenty-one years ago, the sky fractured into silent bands of light. The energy left behind—Aether—rewrote human potential. Awakened people became Ascendants. Meridian built the infrastructure that made Aether useful and the surveillance that made it controllable.

The protagonist is an unnamed worker in Neon District. Their Echo Aether initially produces an almost unreadable signal. Unlike conventional Aether, Echo can learn from the resonance of others without stealing their identity or abilities. Growth comes through relationships and repeated struggle. Meridian classifies the protagonist as harmless until an enforcer's suppression field unexpectedly amplifies their power.

### Original cast and factions

| Name | Role | Personal conflict |
| --- | --- | --- |
| The Unbound | Player; Echo Striker | Power could protect friends or make them targets. |
| Mira Vey | Volt Vanguard; tram mechanic | Keeps an illegal power line running for displaced families. |
| Oren Vale | Ember Breaker; rival champion | Must win sanctioned fights to buy his brother's freedom. |
| Sable Irix | Void Controller; archivist | Remembers discarded futures and mistrusts every apparent victory. |
| Director Vaust | Neon District antagonist | Believes compulsory Aether control is the only way to prevent another fracture. |
| Tessel Nox | Hidden boss; discarded prototype | Guards the city's first laboratory because leaving would erase its memories. |
| Meridian Directorate | Public infrastructure authority | Converts safety mandates into control over Ascendants. |
| Quiet Index | Secret organization | Catalogs possible futures and quietly eliminates unpredictable people. |
| Lantern Circuit | Mutual-aid network | Hides awakened civilians inside ordinary city services. |

### Season structure — planned

1. **The Fracture**: the city hunts an insignificant signal. Mira becomes the player's first friend. A Lantern informant betrays the safehouse to protect their own family. Defeating Vaust exposes a signal originating beyond the atmosphere.
2. **Crown of Frequencies**: a regional tournament promises Ascendants legal protection. Oren becomes rival, ally, then reluctant opponent. The Quiet Index uses the bracket to identify people capable of opening the sky.
3. **The Second Silence**: the world-ending threat is a lattice that harvests entire possible futures. Sable must choose between preserving one remembered future and trusting people who have not lived it yet.

## Neon District content plan

Only mission 1-1 is playable now. All other entries below are design backlog.

| Story mission | Objective | Encounter |
| --- | --- | --- |
| 1-1 A spark in the static | Survive a suppression scan on Skybridge 09 | Meridian enforcer — implemented |
| 1-2 Under the violet rain | Escort Mira's relay through alleyways | Patrol squads |
| 1-3 The relay keeper | Restore the tram network | Mini-boss: Relay Warden |
| 1-4 A debt to lightning | Defend a community substation | Disruptor waves |
| 1-5 Glasshound pursuit | Escape a surveillance pursuit | Mini-boss: Glasshound |
| 1-6 A city beneath the city | Enter the underground laboratory | Sensor maze and guards |
| 1-7 The Null surgeon | Recover suppressed Aether records | Mini-boss: Null Surgeon |
| 1-8 A friend's frequency | Rescue an informant who betrayed the Circuit | Split rescue objectives |
| 1-9 Break the broadcast | Disable district suppression pylons | Multi-lane defense |
| 1-10 Director Vaust | Confront the district's architect | Major boss: Vaust |

Five side missions: **Lost Signal**, **Night Courier**, **The Last Tram**, **Borrowed Light**, and **Names in the Rain**. Completing their evidence chain unlocks **Tessel Nox**, the hidden boss. These missions are not implemented.

## Development phases

### Phase 1 — delivered prototype

Project structure, home UI, profile and currencies, player, enemy, basic combat, arena, results, XP/levels and local saves. Also includes prototype touch support, skills/ultimate, combat effects and completed-stage auto-battle. Validate enjoyment and touch ergonomics on real Android devices before expanding scope.

### Phase 2 — next

- Build missions 1-2 through 1-10 with the three mini-bosses and Vaust.
- Add the five side missions and hidden boss evidence chain after the main chapter works.
- Make Mira, Oren and Sable playable with genuinely different kits.
- Add collection, leveling, star ratings, passives, skill upgrades and character inspection.
- Equipment slots: weapon, armor, boots, gloves, accessory and artifact. Upgrade, enhance, evolve and reforge via explicit material recipes.
- Rarities: Common, Rare, Epic, Legendary, Mythic, Ascended.
- Add elemental strengths/weaknesses and explicit on-screen explanations.
- Replace procedural rigs with commissioned or otherwise cleared original animation assets.

### Phase 3 — economy and monetization, not implemented

> **SUPERSEDED (owner direction, October 2026):** the lines below describing paid power, summons/banners, pity, energy refills and accelerated progression no longer apply. The current direction is cosmetic-only, no pay-to-win, no randomized paid rewards; see `docs/MONETIZATION_PLAN.md`. Kept only as history.

The intended design permits paid power and accelerated progression. No prices, banner rates or purchasing behavior are active in this prototype.

- Gold stays earnable in combat; Crystals become purchasable only through supported platform billing with verified receipts and idempotent grants.
- Single/ten summons, premium/limited/beginner banners, a guaranteed strong starter, visible probabilities, guarantees and pity. Define pity carryover and duplicate-shard conversion before implementation. Persist and expose summon history.
- VIP 0–15: purchase-earned VIP XP; increasing energy, XP/gold bonuses, daily rewards, dungeon attempts, farming speed, resource drops, cosmetics, shop access and selected exclusive heroes. Publish every threshold and benefit before purchase. Final values require balance testing.
- Power packs: Starter Power Pack, Elite Warrior Pack, Legendary Upgrade Pack, Ascension Pack, Boss Slayer Pack and Mythic Hero Pack. Each requires a clear pre-purchase item list.
- Free/premium battle-pass tracks with Crystals, Gold, shards, tickets, materials, skins, gear and energy.
- Optional monthly membership: daily Crystals, energy, XP/gold bonuses, auto-battle rewards and a daily ticket. Implement subscription restoration, cancellation information and expiry behavior.
- Progression offers for level 10, first boss, new world, first Legendary and first Mythic. Use real persisted expiration timestamps, never a resetting countdown.
- Energy: daily free claims, optional rewarded ads, Crystal refills and VIP bonuses. The delivered prototype has only regeneration and mission costs.
- Daily login, daily/weekly missions, achievements, returner rewards, event calendar, free daily summon and free shop chest.
- Verify current store, payment and audience requirements before release. No cash-out, tradable real-money value or player wagering.

### Phase 4 — expansion

Transformations: Base, Awakened, Elite, Ascended, Celestial, Mythic. Each needs distinct appearance, aura, stats, skills and ultimate animation. Add worlds and stories progressively.

Potential modes, in independent increments: Boss Rush, Tower, Training Arena, Daily Dungeons, Resource Dungeons, Character Trials, Survival, Guild Battles, PvP, Ranked Arena, Seasonal Events and Limited-Time Bosses.

Cloud architecture must precede competitive modes: authenticated identity, authoritative economy and battle settlement, server time, receipt validation, audit trail, reconciliation, version migrations and abuse controls. The local backend can be replaced behind the profile coordinator; local purchase data must never be trusted as proof of payment.

## FTUE backlog

Current: name/body selection, brief introduction, mission briefing, contextual combat hints and home return. Future: animated logo/intro, guided input gating, first summon with a strong starter and return-home celebration. No fake summon or fake unlock appears in this build.
