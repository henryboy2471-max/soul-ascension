# SOUL ASCENSION — Monetization, Progression & Social Roadmap

Status: **DESIGN ONLY.** Branch `monetization/design`. Not merged into the release candidate or any episode branch. Episode 3 remains the active development priority; Episode 4 remains in planning.

Labels used in this document: **[Owner]** = stated by the owner. **[Design]** = a proposal made here, not yet approved and not playtested. **[Inference]** = reasoning from general industry patterns, not verified. **[Unverified]** = a factual claim about an outside party (store fees, policy, law) that was *not* checked against a live source in this session and must be verified before any commitment.

## 0. Hard rules (apply to every section)

1. Season 1 is exactly **10 episodes**. All 10 are completable with **no purchase**. [Owner]
2. **Cosmetic only.** No stats, power, damage, HP, XP boosts, energy, story unlocks or episode unlocks can be bought or gated behind a purchase. [Owner]
3. **No randomized paid rewards** (no gacha, loot boxes, banners, pity). Every price is shown up front. [Owner]
4. **No real payments.** All purchases in development use `MockBilling` with test SKUs. `ShopService.PAYMENTS_ENABLED = false`. Nothing is live, published, or deployed without owner approval. [Owner]
5. **No manipulative pressure:** no countdown timers on purchases, no fake scarcity, no "last chance" popups, no daily-login guilt, no punishment for absence, no purchase prompts inside story scenes or battles. [Owner/Design]
6. Existing progress, characters, cosmetics, purchases and currencies are **never reset or removed** by any feature here (see §14 migration).
7. Approved planning prices are preserved exactly (§3). They are **not** approved live products.
8. This work must not interrupt Episode 3 milestones M1–M5 and must not alter the approved Episode 3 or Episode 4 stories.

## 1. Currencies

| Currency | Premium? | Source | Notes |
|---|---|---|---|
| Gold | no | missions, battles | existing |
| Echo Shards | no | exploration discoveries, optional quests, free pass track | free route to cosmetics (items have a `free_route`) |
| Soul Crystals — **purchased** | yes | store packs only | tracked in its own balance |
| Soul Crystals — **earned** | yes (same use) | loyalty, milestones, prestige, pass free track | tracked in its own balance, with a per-source cap |

**Purchased and earned crystals are recorded separately** [Owner]. Implementation: two ledger currencies, `crystals_paid` and `crystals_earned`; the UI shows one total with a breakdown on tap.

- Spend order [Design, owner decision D3]: **earned first, then purchased.** Rationale [Inference]: refunds then claw back from the paid balance, which is untouched more often, and it never makes a player feel their purchase was "used up" by free currency.
- Refund clawback only ever debits `crystals_paid`. A refund can create a *debt* on the paid balance; debt blocks further crystal spending until cleared and never touches earned crystals, story access, or owned cosmetics other than those bought with that order.
- Earned crystals can never be converted into or exported as paid crystals; neither is transferable between accounts.

**Status of code:** the current `Ledger` (scripts/shop) has a single `crystals` currency. Splitting into `crystals_paid`/`crystals_earned` is milestone MON-1 (§13). The existing profile fields `crystals`, `purchases`, `vip_xp`, `battle_pass_xp` come from the earlier prototype and must be audited and migrated, not deleted (§14).

## 2. Free earning philosophy

Premium currency is earned for **actual gameplay**, never for login or for repeating trivial actions. [Owner]

- Eligible: **one-time** first clears, first boss defeats, completed optional quest chains, complete discovery sets for an area, story-adjacent achievements. Each has a unique `challenge_id`.
- Not eligible: repeatable battles, repeat mission replays, daily login, ads, idle time, replays of the same encounter, opening menus.
- Everything repeatable pays **Gold / Echo Shards only**.
- A global **earned-crystal ceiling per rolling 7 days** [Design, value to be tuned in playtest] stops farming even if a bug makes a challenge claimable twice.

## 3. Approved planning prices (owner-proposed, NOT live) [Owner]

| Item | Planning price |
|---|---|
| Crystals 150 / 600 / 1,400 / 3,000 / 6,500 / 10,000 | $2.99 / $9.99 / $19.99 / $39.99 / $79.99 / $99.99 |
| Basic outfit | $5.99 |
| Premium skin | $9.99 |
| Legendary cosmetic transformation | $19.99 |
| Exclusive animated outfit | $24.99 |
| Soul Companion | $7.99 – $14.99 |
| Cosmetic bundle | $29.99 |
| Season Pass / Deluxe Season Pass | $14.99 / $24.99 |

Crystal prices of cosmetics are derived at the planning rate `CRYSTAL_RATE = 60` per USD (the 600-crystal pack). Larger packs include a bonus rate. These are encoded in `scripts/shop/shop_catalog.gd` with every entry `"live": false`; `tests/test_shop_design.gd` verifies the six pack sizes/prices and that nothing is live. Nothing in the loyalty, prestige or Hall systems changes these prices. Free earning must never make paid items feel mandatory: free crystal income (§4–5) is deliberately small compared to catalog prices.

## 4. Progressive Loyalty Reward System [Owner request; numbers are Design]

### 4.1 Tiers (by player level)

| Tier | Levels | Name | Crystal reward per eligible challenge |
|---|---|---|---|
| 1 | 1–10 | New Ascendant | 1–3 |
| 2 | 11–25 | Soul Explorer | 3–6 |
| 3 | 26–50 | Soul Guardian | 6–10 |
| 4 | 51–75 | Elite Ascendant | 10–15 |
| 5 | 76–100 | Legendary Ascendant | 15–25 |

The tier is determined by the player's level *when the challenge is completed*. Rewards start small and grow with long-term engagement.

### 4.2 Illustrative total free-crystal budget [Design — not balanced by playtest]

| Source | Count x avg | Total |
|---|---|---|
| Tier 1 challenges | 8 x 2 | 16 |
| Tier 2 | 12 x 4 | 48 |
| Tier 3 | 20 x 8 | 160 |
| Tier 4 | 20 x 12 | 240 |
| Tier 5 | 20 x 20 | 400 |
| Active-day milestones (§4.3) | 6 | 275 |
| Prestige I–III (§5) | 3 | 175 |
| **Total earnable over the whole journey** | | **≈ 1,314** |

At the planning rate of 60 crystals per USD [Design] this is roughly the cosmetic value of a few basic outfits over a very long play history — enough to feel rewarding, not enough to remove the shop. The owner decides whether that ratio is right (D4).

### 4.3 Cumulative active-day milestones

An **active day** is a calendar day on which the player completed at least one *qualifying gameplay event*: a mission objective, an exploration discovery, or a battle win. Login alone does not count.

Milestones are **cumulative counts of active days** — they never reset and missing a day costs nothing. [Owner]

| Active days | Crystals | Exclusive cosmetic (cosmetic only) |
|---|---|---|
| 3 | 5 | Profile emblem "First Steps" |
| 7 | 10 | Echo hair tint |
| 14 | 20 | Title "Steadfast" |
| 30 | 40 | Companion accessory |
| 60 | 75 | Animated frame |
| 90 | 125 | Outfit recolor set |

(The cosmetics are placeholders until art direction is approved.)

### 4.4 Anti-abuse

- **Duplicate claims:** every reward has a unique `claim_ref` (`loyalty:<challenge_id>`, `milestone:<days>`). The ledger rejects any `earn` whose `ref` already exists (already implemented and tested: "duplicate earn ref rejected").
- **Infinite farming:** only one-time challenges pay crystals; weekly ceiling (§2); repeatable content pays Gold/Shards only.
- **Clock manipulation:** device time is **untrusted**. Rules [Design]: (a) an active day is credited at most once per 20 trusted hours since the last credited day; (b) if the device clock moves backwards, last-seen is kept and the jump is ignored; (c) forward jumps larger than a threshold do not credit extra days; (d) milestone crystals are **held pending** until a backend timestamp confirms the day count. Until a backend exists, milestone crystals are test-only.
- **Fraudulent transactions:** see §9.
- **Reward actual gameplay:** an active day needs a server-confirmable qualifying event, not a menu session.
- Missing days never reduce any counter.

## 5. Ascendant Prestige System [Owner-approved; requirements are Design]

Unlocks at **Level 100**. Prestige is **additive**: it never resets levels, story progress, characters, cosmetics, purchases, currencies or unlocked episodes. [Owner]

| Rank | Name | Crystals | Other rewards |
|---|---|---|---|
| I | Awakened Soul | 25 | exclusive title, animated profile border |
| II | Celestial Guardian | 50 | exclusive aura, special cosmetic outfit |
| III | Eternal Ascendant | 100 | legendary title, exclusive cosmetic transformation |

### 5.1 Requirements — meaningful play, not purchases

Each rank requires completing a set of **Prestige Trials** (all free, none purchasable, none skippable with currency). Draft [Design]:

- **I:** reach Level 100 plus 10 trials (e.g., clear each episode's hardest optional encounter, complete all discovery sets for Episodes 1–2, finish 3 optional quest chains).
- **II:** 15 further trials (e.g., all areas fully explored through the latest released episode, no-assist encounters, codex 100% for released episodes).
- **III:** 20 further trials (e.g., challenge variants of every boss, complete every optional quest chain released).

Prestige progress is a separate counter (**Prestige Marks**), not levels, so buying anything cannot "purchase levels". No store item grants XP, levels or trial progress. Trial lists grow only as new episodes release; the full Season 1 list is defined when all 10 episodes are approved (never more than 10 episodes).

### 5.2 After Prestige III — Legacy Challenges

Repeatable cosmetic challenges (rotating weekly objectives, collection variants) that award **cosmetics, titles, frame variants and Echo Shards only**. **Zero** Soul Crystals [Design, owner decision D5]; if the owner prefers a trickle, the cap would be a fixed small number per season, enforced in the ledger.

### 5.3 Data structures

```
prestige = {
 "rank": 0,                       # 0..3
 "marks": 0,                      # Prestige Marks (trial progress)
 "trials_done": ["p1_t01", ...],  # unique ids, append-only
 "claimed": ["prestige:1"],       # claim refs; one crystal grant per rank
 "legacy": {"season": "s1", "done": []}
}
reward_def = {"id":"prestige:1","crystals":25,"grants":["title_awakened","frame_awakened_anim"],"requires":{"level":100,"marks":10}}
```

Advancing = `rank += 1` guarded by `requires`; grant happens in one atomic step keyed on `claim_ref`, so a crash/retry cannot pay twice.

### 5.4 Interface concept

A "Prestige" page in the Hall of Legends (§6): three constellation nodes (I–III) in violet and gold, each showing its trial checklist with progress bars, the reward preview, and a locked/ready/claimed state. A confirmation shows exactly what is granted and states "Nothing is reset." No timers, no "buy progress" button.

## 6. Hall of Legends [Owner-approved feature; Design]

A premium anime-inspired showcase room where players display their character, prestige rank, achievements, rare cosmetics and exploration accomplishments. **Personal Hall first.** Friends' profiles and leaderboards come later, only after privacy, safe names and anti-cheat exist. Hall upgrades are cosmetic and earned through gameplay, never required purchases. [Owner]

### 6.1 Interface concept

Chrome, violet and gold, matching the Soul Shop. A 3/4 hall with: a central plinth with the player's hero in their equipped outfit; wall niches for achievement medals; a "Prestige Banner" and animated border; a cosmetic display case (owned rare items); an exploration map wall (areas fully discovered per episode); companion perch. Touch-first: tap a niche to see details; edit mode to arrange. A "Share" button does not exist in phase 1.

### 6.2 Data structure

```
hall = {
 "version": 1,
 "display": {"hero":"echo","outfit":"id","title":"id","border":"id","aura":"id","companion":"id"},
 "slots": {"medals":[ids], "cases":[ids], "banners":[ids]},   # only owned/earned ids
 "upgrades": ["hall_marble_floor", ...],                       # earned, cosmetic
 "stats": {"episodes_cleared":2,"discovery_pct":0.0,"codex":0,"prestige":0,"active_days":0},
 "privacy": {"visibility":"private","show_prestige":false,"show_stats":false}
}
```

The Hall is a **view over existing data** (inventory, achievements, prestige, mission_progress). It stores layout only, so it can never mint rewards.

### 6.3 Hall upgrades

Earned by gameplay (milestones, prestige, episode completion, exploration sets); optionally also obtainable in the shop **only as cosmetics with a free route**; none required.

### 6.4 Social phase (later; not before the gates below)

Gates that must exist and be tested **before** any social feature is enabled [Owner]:
- **Privacy controls:** default `private`; opt-in visibility levels (private / friends / public); per-field toggles.
- **Safe display names:** no free-text names in the first social release — chosen from a curated word list + number, or a name filter with moderation and reporting [Inference: free text needs moderation staff/tooling].
- **Anti-cheat:** leaderboard values are computed server-side from validated events, not accepted from the client.
- Age/consent requirements for social features [Unverified: legal requirements vary by region; needs review].

Leaderboards are **achievement-based and fair**: e.g., exploration completion, codex completion, challenge clears, active-day streak-free totals. They never rank by spending, never rank by prestige purchases, and use per-episode or seasonal boards so new players can compete. No spending-based status.

### 6.5 Hall of Legends milestones [Design; each needs owner approval; none starts before the Episode 3 milestones allow]

| ID | Scope |
|---|---|
| HL-0 | This specification, data structure and interface concept (**done**) |
| HL-1 | Art direction samples for the Hall (concept only; approval before any art batch) |
| HL-2 | Personal Hall, local only: display slots over existing inventory/achievements/prestige, layout save, privacy defaults private; tests |
| HL-3 | Earned Hall upgrades (cosmetic) tied to milestones, prestige and exploration sets |
| HL-4 | Social gates: safe display names, privacy controls, server-side anti-cheat, moderation/reporting — all tested **before** HL-5 |
| HL-5 | Friends' profiles (opt-in) and fair achievement-based leaderboards — **requires approval** |

Season 1 stays exactly 10 episodes; Hall exploration stats count only released, approved episodes.

## 7. Season Pass (cosmetic only)

Season Pass $14.99, Deluxe $24.99 (planning). Pass XP comes from **play**, never from spending. Free track and premium track both cosmetic; Deluxe adds extra cosmetics only; no tier-skipping with money [Design]. Non-consumable; restorable. (Implemented in `ShopService` for test data.)

## 8. Soul Shop UI

Chrome, violet and gold. Implemented as a prototype in `scripts/shop/shop_screen.gd` with a persistent banner "TEST DATA · PAYMENTS DISABLED · NO REAL PURCHASES". Tabs: Featured, Outfits, Skins, Hairstyles, Transformations, Companions, Bundles, Crystals, Season Pass, Restore. Rules: price visible before tap, confirm step, no timers, no random content, clear "free route" shown on each cosmetic. Screenshot capture is a remaining task (needs a display).

## 9. Purchase verification, inventory, refunds, restore

Architecture for the later Android release (not built; mock only) [Design]:

1. Client uses Google Play Billing through a Godot plugin (the first-party GodotGooglePlayBilling plugin requires an Android Gradle build template — [Unverified] against current plugin docs).
2. After purchase the client sends the purchase token + SKU to **our backend**; the backend verifies with the Google Play Developer API (never trust the client), credits the ledger once keyed on the order id, then the client acknowledges/consumes. Unacknowledged purchases are refunded by Google after a few days ([Unverified] exact period; the design acknowledges immediately after grant).
3. **Restore:** query owned purchases; non-consumables (passes) are re-granted; consumable crystals are not re-grantable.
4. **Refunds:** poll voided purchases / receive real-time notifications ([Unverified]); apply `refund:<order>` once, revoke pass benefits, claw back only unspent `crystals_paid`, record debt if spent.
5. Inventory records `source` and `ref` for every grant so revocations are exact.

Everything above except the real Google calls is already exercised against `MockBilling` (sha256 signature check, duplicates, refunds, restore).

**Fraud controls** (all): idempotency keys on every grant; append-only ledger; signature verification; server-side verification; rate limits; reconciliation job comparing ledger to store records; no client-authoritative balances in the live version.

## 10. Projected integration costs

All numbers are estimates; none verified this session.

| Item | Cost | Label |
|---|---|---|
| Google Play developer registration | $25 one-time | [Unverified — verify on Google's page] |
| Google Play service fee | 15% on the first $1M/yr of revenue, 30% above; 15% on subscriptions | [Unverified — verify; programs change] |
| Backend (verification, ledger, leaderboard) | small hosting, order of tens of USD/month at launch; more with scale | [Inference] |
| Moderation / support tooling for social phase | variable | [Inference] |
| Art for cosmetics, Hall, shop | main cost; paid art services need explicit owner approval | [Inference] |
| Legal (privacy policy, terms, data-safety form, age rating) | owner/counsel time | [Inference] |
| Engineering | this project's own time; no extra license cost identified | [Inference] |

## 11. Compliance checklist (before any live release)

Privacy policy and data-safety declaration; age rating questionnaire; no randomized rewards (so no odds disclosure needed) — confirm; refund policy text; purchase confirmation screens; receipts; accessible price display; legal review of social features. [All Unverified: confirm with current store policy.]

## 12. Testing plan

Automated (`godot --headless`, test data only):
- **Catalog:** validate() (no forbidden power fields; all `live:false`); the six approved pack prices.
- **Ledger:** append-only; duplicate `ref` rejected; separate `crystals_paid` / `crystals_earned`; spend order; refund clawback hits only paid; debt blocks spending.
- **Loyalty:** each tier's reward range; one-time challenges pay once; repeatables pay 0 crystals; weekly ceiling; active day credited once per day; clock backward/forward jumps; a missed day keeps the count; milestones pay once at 3/7/14/30/60/90.
- **Prestige:** locked before Level 100; requires trials; atomic single grant per rank; nothing reset (levels, episodes, inventory, currencies, purchases identical before/after); legacy challenges award zero crystals.
- **Hall:** layout can only reference owned ids; privacy defaults private; never mints rewards; hidden fields not serialized to others.
- **Story:** all 10 episodes reachable with zero spending (negative test: no shop item or currency gates any episode).
- **Migration:** existing saves load unchanged; Episode 1–2 saves untouched.
- **Fraud:** replayed purchase token, forged signature, duplicate order id, refund replay.
Manual: shop on 1280x720, 844x390, 667x375; text overflow; no purchase UI inside story/battle.

## 13. Implementation milestones (each gated on owner approval; none interrupts Episode 3)

| ID | Scope |
|---|---|
| MON-0 | This design + catalog/ledger/inventory/mock billing/shop prototype (**done on this branch, test data**) |
| MON-1 | Split ledger into `crystals_paid` / `crystals_earned`; spend order; per-source and weekly caps; migration of old fields |
| MON-2 | Loyalty: challenge definitions, tiers, active-day tracker with clock safeguards, milestones; tests |
| MON-3 | Prestige: trial definitions, atomic rank grants, Legacy Challenges; UI page; tests |
| MON-4 | Hall of Legends personal (layout, display, upgrades, privacy defaults); art direction approval first |
| MON-5 | Backend design/prototype: verification, ledger reconciliation (still no live payments) |
| MON-6 | Google Play Billing adapter, closed-test track, compliance — **requires explicit owner approval** |
| MON-7 | Social phase: safe names, privacy, anti-cheat, friends, fair leaderboards — **requires approval and MON-5/6** |

Suggested order interleaves after Episode 3 milestones; nothing here is scheduled against them.

## 14. Safety of existing data

Additive saves only: new keys (`shop`, `loyalty`, `prestige`, `hall`) with defaults on load; no deletion of `purchases`, `crystals`, `inventory`, `completed`, `mission_progress`. Back up before migration; a migration test loads saved fixtures and compares unchanged fields.

## 15. Decisions needed from the owner

| # | Decision |
|---|---|
| D1 | Approve cosmetics-only scope and the "no timers / no pressure" rules as written |
| D2 | Approve the separate paid/earned crystal ledger (MON-1) |
| D3 | Spend order: earned first (recommended) or paid first |
| D4 | Approve the free-crystal budget (~1,314 total) or change tier ranges / milestone values |
| D5 | Post-Prestige-III: zero crystals (recommended) or a small fixed seasonal cap |
| D6 | Prestige trial lists and Hall art direction (needs concept samples first) |
| D7 | Whether the Season Pass is included in the first release or later |
| D8 | Backend choice and hosting budget; who verifies store fees/policies |
| D9 | Approval gate for MON-6 (any billing) and MON-7 (any social) |
| D10 | Minimum age / data-collection stance for the social phase |
