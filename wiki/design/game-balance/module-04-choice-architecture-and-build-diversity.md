# Module 4: Choice Architecture & Build Diversity

**Part of:** [Game Balance Learning Roadmap](game-balance-roadmap.md)
**Estimated study time:** 3–4 hours
**Prerequisites:** [Module 2: Power Budgets & Stat Allocation](module-02-power-budgets-and-stat-allocation.md)

---

## Overview

A balanced game with only one viable strategy isn't balanced — it's solved. True balance means multiple builds, playstyles, and upgrade paths can succeed. The challenge is that players are optimization machines: given any system, they'll find the mathematically best option and converge on it, collapsing build diversity to zero. Your job as a designer is to create a system where the "best" option depends on context, so different players in different situations make different choices — and all of those choices are reasonable.

This module covers the math and design patterns behind build diversity: why it collapses, how to create meaningful choices through mutual exclusion and opportunity cost, how to design synergies that reward build commitment without creating dominant strategies, and how to validate that your system actually supports the diversity you intended.

---

## 1. Why Build Diversity Collapses

In any system where options can be compared, players gravitate toward the best one. This isn't a player problem — it's a system problem. Understanding *why* diversity collapses tells you where to intervene.

### The Dominance Problem

An option **dominates** another when it's better in every dimension. If Sword A has more damage, more crit, AND more speed than Sword B, there's no reason to ever pick Sword B. Dominated options are dead options.

```
Sword A: 50 attack, 10% crit, 1.2 speed  → DPS: 66.0
Sword B: 45 attack,  8% crit, 1.1 speed  → DPS: 53.5
Sword C: 40 attack, 15% crit, 1.4 speed  → DPS: 64.4

A dominates B (better in every stat).
A vs C is a tradeoff: A has more attack, C has more crit and speed.
DPS favors A, but C is close enough that player preference matters.
```

**Fix:** Never release an item that's worse than another item of the same tier in every stat. Every item needs at least one dimension where it's the best (or tied for best) option. This is what power budgets (Module 2) enforce — if both items hit the same budget, they must allocate stats differently.

### The Convergence Problem

Even without dominance, build diversity can collapse when one stat combination is mathematically optimal. If attack + crit always produces higher DPS than attack + speed at the same budget, every damage-focused player will choose attack + crit.

```
Same budget (60 points), two allocations:
  Build A: 12 attack + 8% crit → DPS: 50.7
  Build B: 8 attack + 0.2 speed → DPS: 47.2

Build A is 7% better. Over many runs, every experienced player chooses A.
```

**Fix:** Create contexts where the "best" build changes. Speed might be better against enemies that have brief vulnerability windows. Crit might be worse against bosses with crit resistance. If the optimal build varies by encounter, players are incentivized to diversify — or at least make choices based on the specific run, not a solved formula.

### The Information Problem

Even in a well-designed system with genuine tradeoffs, build diversity collapses if players can easily calculate the optimal path. The more transparent your math, the faster the community solves it. This creates a tension: transparency helps players make informed choices, but too much transparency eliminates choice.

**The solution isn't obfuscation** — hiding your formulas is frustrating and anti-player. The solution is **creating complexity that resists simplification.** If the optimal choice depends on the other upgrades you've taken, the enemy composition of the next zone, and a probabilistic offering system, the optimization problem is computationally hard enough that different players arrive at different answers.

---

## 2. Mutual Exclusion as a Design Tool

The most powerful technique for creating meaningful choices is **mutual exclusion** — you can't have everything. Opportunity cost is what makes choices matter.

### Hard Exclusion

The player literally cannot combine certain options.

```
Class system:
  Warrior: access to melee abilities, heavy armor
  Mage:    access to spell abilities, cloth armor
  Rogue:   access to stealth abilities, light armor

Choosing Warrior means you cannot use spells.
The cost of Warrior isn't just "no spells" — it's all the builds
that spells would have enabled.
```

**Slot systems** create hard exclusion naturally: you can only equip one weapon, one armor, one accessory. Each slot is a choice point where picking item A means not picking item B.

### Soft Exclusion (Opportunity Cost)

The player *can* combine options, but doing so means giving up something else.

```
Upgrade shop with limited currency:
  +20 Attack:     200 gold
  +15% Crit:      200 gold
  +50 HP:         200 gold
  Player has:     400 gold

Player can buy any 2, but not all 3.
Each choice excludes one option.
```

**Roguelike offering systems** are soft exclusion engines: you're offered 3 upgrades, pick 1, lose the other 2. The offering itself creates the opportunity cost.

### Diminishing Returns as Soft Exclusion

When stacking the same stat has diminishing returns, diversity becomes the mathematically optimal strategy — even without explicit exclusion.

```
Attack upgrades with diminishing returns:
  1st +10 attack: +3.7 DPS per budget point
  2nd +10 attack: +3.5 DPS per budget point (crit hasn't scaled)
  3rd +10 attack: +3.3 DPS per budget point

Crit upgrades:
  1st +5% crit: +1.0 DPS per budget point
  2nd +5% crit: +1.0 DPS per budget point (still scaling well)

After 2 attack upgrades, crit becomes more efficient per budget point.
The system naturally pushes toward diverse stat allocation.
```

This is the **interaction between stat weights from Module 2 and diminishing returns from Module 3.** As you stack one stat, its marginal value drops relative to other stats. A player who only takes attack upgrades falls behind a player who diversifies — not because of a rule, but because of math.

---

## 3. Synergy Design

Synergies are the engine of build identity. When two upgrades are stronger together than separately, players are rewarded for building toward a theme. The design challenge is making synergies strong enough to incentivize commitment without making them so strong that they dominate all non-synergistic builds.

### Linear Synergy (Additive)

Two effects add together but don't multiply.

```
Upgrade A: +20% fire damage
Upgrade B: +20% fire damage
Combined:  +40% fire damage

Value of A alone: 20% boost
Value of A given B: 20% boost (same — no interaction)
```

Linear synergies don't create "build-around" moments — taking A doesn't make B more attractive. They're safe and boring. Use them for generic stat boosts, not build-defining upgrades.

### Multiplicative Synergy

Two effects multiply together, creating a value greater than the sum of parts.

```
Upgrade A: Attacks apply "Burn" (3 DPS for 5 seconds)
Upgrade B: +50% damage to Burning enemies

A alone: +15 total damage per hit (burn ticks)
B alone: +0 damage (nothing to trigger it)
A + B:   +15 burn damage + 50% bonus to every hit on burning targets

If base hit = 50 DPS:
  A only: 50 + 3 = 53 effective DPS
  B only: 50 DPS (no burning enemies to trigger it)
  A + B:  (50 × 1.5) + 3 = 78 DPS

Combined value: 78 DPS
Sum of individual values: 53 + 50 = 103 → but this double-counts the base
Actual synergy bonus: 78 - 53 = 25 DPS from the synergy interaction
```

**This is the Hades model.** Boons that apply status effects synergize with boons that benefit from those effects. Taking "Hangover" (Dionysus damage-over-time) makes "Privileged Status" (+40% to enemies with two status effects) more valuable.

### Exponential Synergy (Dangerous)

Effects that multiply each other directly, creating compounding returns.

```
Upgrade A: +30% damage
Upgrade B: +30% attack speed
Upgrade C: +30% crit damage

Individual: each is a 30% boost
A + B: 1.3 × 1.3 = 1.69× (69% boost, not 60%)
A + B + C: 1.3 × 1.3 × 1.3 = 2.20× (120% boost, not 90%)

Add a 4th multiplicative upgrade:
A + B + C + D: 1.3^4 = 2.86×
```

Exponential synergy is exciting — but it creates dominant strategies. If the player can stack enough multipliers, the compounding outscales anything else. This is why Slay the Spire's most powerful decks are ones that create multiplicative loops (Strength × multi-hit cards, for example).

**Rules for controlling exponential synergy:**
1. **Limit the number of multipliers.** If players can only get 2-3 multiplicative effects, compounding stays manageable.
2. **Make multipliers exclusive.** If the best multiplier is a class-specific ability and each class gets one, the player gets exactly one multiplicative axis.
3. **Use additive stacking within a category.** Two "+30% damage" upgrades stack to 60%, not 1.3 × 1.3. Multiplicative stacking only happens *between* categories (damage × speed × crit).

---

## 4. The 8-Build Test

How do you know if your system has enough build diversity? The 8-build test is a practical validation method.

### The Method

1. **Define 8 distinct build archetypes** that your system is designed to support. These should differ in primary stat focus, playstyle, or upgrade priority.

```
Example archetypes for an action roguelike:
  1. Glass Cannon:    Max attack, min HP, fast kills or die trying
  2. Tank:            Max HP/defense, low DPS, outlasts everything
  3. Crit Fisher:     Crit chance + crit damage, high variance
  4. Speed Demon:     Attack speed + movement, death by a thousand cuts
  5. DoT Specialist:  Burn/poison/bleed stacking, sustained damage
  6. Burst Mage:      Cooldown-based abilities, huge burst windows
  7. Lifesteal Hybrid: Moderate damage + healing on hit, sustain
  8. Summoner:        Minion-based damage, player is support
```

2. **Build each archetype** using your upgrade system. Select only upgrades that fit the archetype's theme.

3. **Evaluate each build against 3 benchmarks:**
   - **Standard encounter:** Can it clear a typical room? What's the TTK?
   - **Boss fight:** Can it defeat the final boss? How much margin of error?
   - **Worst-case scenario:** What's this build's kryptonite? Is the kryptonite frequent enough to kill the run?

4. **Compare build performance.**

| Build          | Room TTK | Boss TTK | Worst Case     | Win Rate* |
|---------------|----------|----------|----------------|-----------|
| Glass Cannon  | 1.5s     | 45s      | Multi-hit boss | ~60%      |
| Tank          | 4.0s     | 120s     | Enrage timers  | ~70%      |
| Crit Fisher   | 2.0s     | 55s      | Long droughts  | ~55%      |
| Speed Demon   | 2.5s     | 60s      | Armor-heavy foe | ~65%      |
| DoT Specialist| 3.0s     | 70s      | Cleanse bosses | ~55%      |
| Burst Mage    | 1.0s     | 50s      | Sustained DPS  | ~60%      |
| Lifesteal     | 3.5s     | 90s      | One-shot spike | ~75%      |
| Summoner      | 3.0s     | 80s      | AoE bosses     | ~50%      |

*Win rates are simulation estimates or playtest data.

5. **Evaluate the spread.**
   - **Win rate range:** If the best build wins 90% and the worst wins 20%, diversity is dead — everyone plays the 90% build. Target a range of ±15 percentage points (e.g., 50–80%).
   - **Speed range:** The fastest clear build should be no more than 2.5× faster than the slowest. If Glass Cannon clears 4× faster than Tank, Tank is unviable in any context where speed matters.
   - **Weakness coverage:** Every build should have a weakness. If one build has no bad matchup, it dominates.

### Failure Modes

- **One build has no weakness.** Often a hybrid build that's "good enough" at everything and terrible at nothing. Fix: ensure each build has a genuine vulnerability — a boss type, encounter type, or resource constraint that punishes it.
- **All builds converge to the same strategy.** Usually means generic upgrades are too strong relative to thematic ones. Fix: reduce the power of generic options, increase the power of synergistic options.
- **Some builds can't complete the game.** Usually the niche builds (Summoner, DoT) that need specific upgrades to function. Fix: ensure offering systems provide enough thematic upgrades, or give niche builds a power floor through innate abilities.
- **Win rates are too compressed.** All builds win 60-65% of the time. This means the game is too easy or builds don't matter enough. Some spread is healthy — it means choices have consequences.

---

## 5. Trap Options

A **trap option** is an upgrade that looks attractive but is mathematically inferior. Traps come in two kinds: unintentional (design mistakes) and intentional (design tools).

### Unintentional Traps

These are simply bad options that the designer didn't realize were bad.

```
"Thorns" upgrade: Reflect 5 damage when hit.

Player takes ~20 hits per encounter.
Thorns damage per encounter: 100.
Player's DPS: 80. Encounter length: ~8 seconds.
Player total damage: 640.
Thorns contribution: 100/640 = 15.6%

But this was offered instead of "+15% damage" which would give:
  640 × 0.15 = 96 extra damage — almost the same.

At first glance, thorns seems comparable. But thorns scales with
how much you get hit (bad) while +15% scales with your DPS (good).
In boss fights where you dodge most attacks, thorns contributes
almost nothing. +15% is better in almost every scenario.

Thorns is an unintentional trap.
```

**Detection:** Calculate the budget value of each upgrade across multiple scenarios (easy encounter, hard encounter, boss). If an upgrade is bottom-tier in all scenarios, it's a trap.

**Fix:** Either buff it until it's competitive in at least one scenario, or remove it. Dead options clutter the upgrade pool and make offerings feel bad.

### Intentional Traps (Noob Traps)

Upgrades that are strong in isolation but bad in context — they teach players to think about the system.

```
"+50 flat HP" vs "+20% max HP"

At 200 base HP:
  +50 flat: 250 HP (25% increase)
  +20%:    240 HP (20% increase)
  Flat wins.

At 500 base HP (after other upgrades):
  +50 flat: 550 HP (10% increase)
  +20%:    600 HP (20% increase)
  Percentage wins.

Early in the run, flat HP is better. Late in the run, percentage is better.
A new player takes flat HP because the number is bigger.
An experienced player thinks about when they're offered the choice.
```

Intentional traps are **design tools** for teaching depth. They're only valid if the "trap" option is still playable — just suboptimal. If taking the wrong upgrade means the run is dead, that's not a learning experience, it's punishment.

---

## 6. Offering Algorithms

The system that determines *which* upgrades the player is offered is as important as the upgrades themselves. The offering algorithm controls build diversity at the systemic level.

### Pure Random

Pick N upgrades uniformly from the full pool. Simple, but has problems:

```
Pool: 60 upgrades, 15 fire-themed, 15 ice-themed, 30 generic
Offerings per run: 20 (pick 1 of 3 each time)
Total upgrades seen: 60

P(seeing a specific fire upgrade at least once): 1 - (59/60)^60 ≈ 63%
P(seeing 5+ fire upgrades in a run): depends on pool size, but low

Problem: A "fire build" needs ~6 fire upgrades to come online.
Pure random makes it unlikely that any thematic build gets enough pieces.
```

### Weighted Random

Upgrades are weighted based on what the player has already taken.

```
After taking a fire upgrade, fire upgrades get +50% weight:
  Base weight: 1.0 per upgrade
  Fire upgrade weight after 1 fire taken: 1.5
  Fire upgrade weight after 2 fire taken: 2.0

This increases the chance of being offered more fire upgrades,
making thematic builds more achievable.
```

**The risk:** Weighting too aggressively creates "forced" builds — the player takes one fire upgrade and is funneled into a fire build regardless of intent. A 25-50% weight increase is enough to nudge without forcing.

### Rarity Gating

Higher-rarity upgrades only appear after certain thresholds.

```
Floors 1-3:   Only Common upgrades offered
Floors 4-7:   Common + Rare (20% chance per slot)
Floors 8-10:  Common + Rare (40%) + Legendary (5%)
Floors 11+:   Rare guaranteed in at least 1 slot, Legendary (15%)
```

**Purpose:** Prevents the player from getting a build-defining legendary on floor 1 (which would make all subsequent choices trivial). Rarity gating ensures the power curve matches the intended progression.

### Pity Timers

Guarantee that the player sees certain upgrade types within a maximum number of offerings.

```
Pity timer for Rare upgrades: max 5 offerings without a Rare
If 5 consecutive offerings have no Rare, the next offering guarantees one

Pity timer for build-relevant upgrades: max 8 offerings without
  an upgrade matching the player's most-invested archetype
If 8 consecutive offerings miss the player's theme, force one

This prevents the worst-case scenario: "I committed to fire builds
but haven't seen a fire upgrade in 10 offerings."
```

### Duplicate Protection

After the player takes an upgrade, remove it from the pool (or reduce its weight dramatically).

```
Without duplicate protection:
  Player takes "+20% fire damage" three times → stacks to +60%
  One upgrade dominates the pool

With duplicate protection:
  After taking "+20% fire damage," it's removed from the pool
  Player must diversify within the fire archetype:
    "+20% fire damage" → "+Burn duration +2s" → "+Burn applies to AoE"
  This creates varied fire builds, not stacking the same effect
```

**Which approach to use:** Most roguelikes combine weighted random, rarity gating, and pity timers. The specific weights and thresholds are tuning knobs — Module 7 covers how to tune them with telemetry.

---

## Exercises

### Exercise 1: Dominance Check

Given 6 weapons with these stats:

| Weapon      | Attack | Crit% | Speed | Special          |
|-------------|--------|-------|-------|------------------|
| Iron Sword  | 30     | 5%    | 1.0   | —                |
| Fire Blade  | 25     | 5%    | 1.0   | +Burn (3 DPS/5s) |
| Quick Dagger| 15     | 15%   | 2.0   | —                |
| War Hammer  | 60     | 0%    | 0.5   | —                |
| Lucky Blade | 20     | 25%   | 1.2   | —                |
| Dark Sword  | 35     | 8%    | 0.9   | —                |

1. Calculate the DPS of each weapon (crit multi = 2×)
2. Does any weapon dominate another? (Better in every dimension including DPS)
3. If so, how would you fix the dominated weapon?
4. Rank by DPS. Is the ranking "interesting" (top 3 within 15% of each other) or "solved" (one is clearly best)?

### Exercise 2: Synergy Math

Design a 3-upgrade synergy chain for a "poison" build:
- Upgrade A: A standalone upgrade that's on-budget (worth ~25 budget points alone)
- Upgrade B: Moderate standalone value (~15 points) but synergizes with A to create ~50 points combined
- Upgrade C: Weak standalone (~10 points) but completing A+B+C gives ~100 points combined

Define the specific effects, calculate the DPS contribution of each combination (A, B, A+B, A+B+C), and verify the synergy creates a compelling "build moment" without being so strong that it dominates non-synergistic builds.

### Exercise 3: The 8-Build Test

Take the 8 archetypes from Section 4 (or define your own). For each archetype:
1. List the 5 most important upgrades the build needs
2. Estimate the build's DPS and eHP at "fully online" state
3. Identify the build's worst matchup (which enemy type punishes it?)
4. Estimate a win rate (as a percentage)

Are all 8 builds viable (win rate > 40%)? Is any build dominant (win rate > 80%)? What's the spread?

### Exercise 4: Offering Algorithm

You have a pool of 40 upgrades: 10 fire, 10 ice, 10 lightning, 10 generic. The player is offered 3 choices, 15 times per run (45 total seen, 15 taken).

1. With pure random offering, what's the probability the player sees at least 8 fire upgrades in a run?
2. Design a weighted offering system where taking a fire upgrade increases future fire offering weight by 40%. After taking 3 fire upgrades, what percentage of offerings will be fire-themed?
3. Design a pity timer that guarantees the player sees their "invested" element within every 4 offerings. How does this change the expected number of fire upgrades seen per run?

---

## Further Reading

- **"Slay the Spire" design talks** — MegaCrit has discussed how they designed card synergies, offering algorithms, and rarity distribution. Search for GDC and community talks by Casey Yano.
- **"Hades" boon system analysis** — community analyses of how Supergiant designed boon interactions, duo boons, and the offering system. The weighted offering with pity timers is well-documented.
- **"The Binding of Isaac" item pool design** — Edmund McMillen has discussed the design of 700+ items across multiple pools. The pool-based offering system with transformation bonuses is a masterclass in synergy design at scale.
- **"Build Diversity in Path of Exile"** — Grinding Gear Games has published extensively on how they design and measure build diversity. Their approach of creating 100+ skills with distinct mechanics is an extreme case study.
- **[Module 2: Power Budgets](module-02-power-budgets-and-stat-allocation.md)** — budget enforcement is the foundation of preventing dominance.
- **[Game Design Theory Module 3: Player Psychology](../game-design-theory/module-03-player-psychology-motivation.md)** — covers player motivation and decision-making psychology.
