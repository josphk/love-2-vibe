# Module 5: Probability Design & Loot Systems

**Part of:** [Game Balance Learning Roadmap](game-balance-roadmap.md)
**Estimated study time:** 4–5 hours
**Prerequisites:** [Module 0: The Math of Balance](module-00-the-math-of-balance.md) (better after [Module 1](module-01-damage-formulas-and-dps-modeling.md))

---

## Overview

Every game with random rewards faces the same tension: randomness creates excitement ("will I get the legendary?") but also creates frustration ("I've killed 200 enemies and still nothing"). Raw probability is indifferent to player experience — a 1% drop rate means 1% of players get the item on their first kill, and 1% of players still don't have it after 458 kills. Both outcomes are mathematically correct. Only one is fun.

This module covers how to design probability systems that *feel* fair: loot table architecture, rarity tier design, pseudo-random distribution (the algorithm that makes randomness feel less random), pity timers, duplicate protection, and the critical distinction between "frequency of opportunity" and "probability per opportunity" that determines whether a reward system feels generous or stingy.

The math here is all discrete probability — no calculus needed, just combinatorics and geometric series. The hard part isn't the math; it's aligning the math with player psychology.

---

## 1. Loot Table Architecture

A loot table is a weighted list of possible outcomes. Every random reward in a game — enemy drops, chest contents, shop offerings, ability selections — is a loot table.

### Flat Tables

Every item has a weight. Roll once, pick one.

```
Enemy drop table:
  Nothing:         60% (weight 60)
  Gold (10-20):    20% (weight 20)
  Common item:     12% (weight 12)
  Uncommon item:    5% (weight 5)
  Rare item:        2% (weight 2)
  Legendary item:   1% (weight 1)
  Total:          100% (weight 100)
```

**Calculation:** To determine the probability of any item, divide its weight by the total weight. This is straightforward when weights are percentages, but weight systems often use arbitrary numbers:

```
Alternative weight system:
  Nothing:      600
  Gold:         200
  Common:       120
  Uncommon:      50
  Rare:          20
  Legendary:     10
  Total:       1000

P(Legendary) = 10 / 1000 = 1%
```

Both tables are identical. Arbitrary weights are easier to modify — changing Legendary from 10 to 15 doesn't require rebalancing all other weights to sum to 100%.

### Tiered Tables (Roll Twice)

First roll determines the rarity tier. Second roll picks a specific item within that tier.

```
Roll 1 — Rarity:
  Common:    60%
  Uncommon:  25%
  Rare:      12%
  Legendary:  3%

Roll 2 — Item within tier:
  Common pool:    15 items (equal weight)
  Uncommon pool:  10 items (equal weight)
  Rare pool:       6 items (equal weight)
  Legendary pool:  3 items (equal weight)

P(specific Legendary) = 3% × (1/3) = 1%
P(specific Common)    = 60% × (1/15) = 4%
```

**Why tiered is better for balance:** You can tune rarity distribution independently from item selection. Adding a new Common item changes the Common pool (now 1/16 instead of 1/15) but doesn't affect Legendary drop rates. In a flat table, adding any item changes every other item's probability.

### Conditional Tables

Different tables activate based on context.

```
Boss drop table (always drops something):
  Common:    40%
  Uncommon:  35%
  Rare:      20%
  Legendary:  5%

Regular enemy table (usually drops nothing):
  Nothing:   80%
  Common:    15%
  Uncommon:   4%
  Rare:        1%
  Legendary:  0%  ← Legendaries only from bosses/chests
```

**Conditional tables control the "where" of loot.** If Legendaries only drop from bosses, the player knows to focus on boss fights. If they can drop from any enemy, the player grinds regular enemies (more kills per minute, higher total rolls).

---

## 2. Rarity Tier Design

Rarity tiers serve two purposes: they communicate value to the player ("purple = rare = exciting") and they organize your power budget system (Module 2).

### Standard Tier Structure

| Tier      | Color  | Budget Range | Drop Rate | Per-Run Expected     |
|-----------|--------|--------------|-----------|----------------------|
| Common    | White  | 25-40        | ~60%      | 8-12                 |
| Uncommon  | Green  | 40-60        | ~25%      | 4-6                  |
| Rare      | Blue   | 60-85        | ~12%      | 1-3                  |
| Epic      | Purple | 85-120       | ~3%       | 0-1                  |
| Legendary | Gold   | 120-180      | <1%       | 0-1 (not guaranteed) |

**The 3:2:1 ratio:** A common pattern is roughly 3 Commons per 2 Uncommons per 1 Rare. This means the player's inventory is mostly Common and Uncommon, with Rares as exciting upgrades. Epics and Legendaries are rare enough to be memorable.

### Rarity and Power Budgets

Each rarity tier corresponds to a power budget range (Module 2). The critical rule: **rarity communicates power.** If a player sees a gold (Legendary) item, they expect it to be powerful. If your Legendary is weaker than a well-rolled Rare, the rarity system is lying to the player.

```
Budget enforcement:
  Every Common:    25-40 budget (hard limits)
  Every Uncommon:  40-60 budget
  Every Rare:      60-85 budget

  VIOLATION: a Common with 55 budget → should be Uncommon
  VIOLATION: a Rare with 38 budget → should be Common
```

### The "Legendary Problem"

Legendaries are tricky. They need to feel special (high power), but they can't be so powerful that getting one trivializes the game. Two approaches:

1. **Legendaries are overbudget but constrained.** They exceed the tier budget in one specific dimension but are average or below in others. A legendary sword with 3× crit damage but 0.5× attack speed. The player builds around the strength.

2. **Legendaries have unique mechanics, not just bigger numbers.** Instead of "+80 attack" (just a bigger version of a Rare), the Legendary gives "Critical hits spawn a lightning bolt that chains to 3 enemies." The power is in the mechanic, not the raw stats. This makes budget comparison harder (how many budget points is "lightning chain"?) but creates more memorable items.

Most successful roguelikes use approach 2. The legendary is "build-defining" rather than "stat-defining."

---

## 3. Pseudo-Random Distribution (PRD)

True randomness feels unfair. A 25% proc chance can produce runs of 0 procs in 15 attempts (probability: 1.3%) or 5 procs in a row (probability: 0.1%). Both are "correct" but feel broken. PRD solves this by making the actual proc chance increase with each failure, keeping the long-run average at the stated rate while eliminating extreme streaks.

### How PRD Works

Instead of a fixed probability `P` per trial, PRD uses an increasing probability `C × N`, where:
- `C` is a constant derived from the desired average rate
- `N` is the number of trials since the last success
- On success, `N` resets to 0

```
Desired rate: 25%
PRD constant C: 0.0667 (derived from the target)

Trial 1: P = 0.0667 × 1 = 6.67%  → likely miss
Trial 2: P = 0.0667 × 2 = 13.33% → probably miss
Trial 3: P = 0.0667 × 3 = 20.00% → getting likely
Trial 4: P = 0.0667 × 4 = 26.67% → most proc here
Trial 5: P = 0.0667 × 5 = 33.33% → very likely
...
Trial 8: P = 0.0667 × 8 = 53.33% → almost guaranteed

Average procs per 100 trials: ~25 (same as true 25%)
Max streak without proc: ~8 (vs. theoretically unlimited with true random)
Max streak with proc: ~3 (vs. theoretically unlimited)
```

### Deriving the C Constant

For a target probability `P`, the C constant is found by solving:

```
P = Σ(n=1 to N_max) [C×n × Π(k=1 to n-1)(1 - C×k)] for all possible success points

This doesn't have a clean closed-form solution. Use a lookup table:

Target P     C value     Max streak (99th percentile)
10%          0.0148      24
15%          0.0282      16
20%          0.0380      13
25%          0.0667      8
30%          0.0847      7
50%          0.1667      4
75%          0.3750      2
```

### When to Use PRD

- **Combat procs** (crit, dodge, on-hit effects): Yes. Streaks of 10 crits or 10 misses feel broken. PRD eliminates them.
- **Loot drops:** Maybe. PRD prevents extreme drought, but pity timers (Section 4) are simpler for loot.
- **Encounter generation** (room types, enemy spawns): Usually not. Encounter variety benefits from true randomness — back-to-back elite rooms can be exciting or terrifying, both valid.

### Implementation

```
// Pseudo-code for PRD
state = { count: 0 }

function prd_check(target_rate):
    C = lookup_c_constant(target_rate)
    state.count += 1
    roll = random(0, 1)

    if roll < C * state.count:
        state.count = 0  // Reset on success
        return true
    return false
```

---

## 4. Pity Timers

A pity timer guarantees a reward within a maximum number of attempts, regardless of probability. It's the "bad luck protection" that prevents the worst-case outlier experience.

### Hard Pity

After N failed attempts, the next attempt is guaranteed to succeed.

```
Legendary drop rate: 1% per chest
Hard pity: guaranteed Legendary after 100 chests with no Legendary

Without pity:
  P(no Legendary in 100 chests) = 0.99^100 = 36.6%
  P(no Legendary in 200 chests) = 0.99^200 = 13.4%
  P(no Legendary in 500 chests) = 0.99^500 = 0.66%

With hard pity at 100:
  P(no Legendary in 100 chests) = 0% ← guaranteed
  Expected chests per Legendary: slightly less than 100 (pity kicks in for unlucky players)
  Average rate is slightly above 1% due to pity contributions
```

### Soft Pity

Instead of a hard guarantee, the drop rate increases after a drought, ramping up as the pity counter grows.

```
Base rate: 1%
After 50 chests without Legendary: rate increases by 2% per chest

Chest 50: 1% + 0% = 1%
Chest 51: 1% + 2% = 3%
Chest 60: 1% + 20% = 21%
Chest 70: 1% + 40% = 41%
Chest 80: 1% + 60% = 61% ← most players hit it by here
Chest 100: 1% + 100% = guaranteed (hard floor)
```

**Genshin Impact uses this model.** The "soft pity" at 75 pulls and hard pity at 90 pulls creates a ramping system where most players get the 5-star around pull 76-80.

### Designing Pity Thresholds

```
For a target rate of P:

Conservative pity: 3× the expected value
  P = 1%, EV = 100 → pity at 300
  Protects only extreme outliers (0.05% of players)

Standard pity: 2× the expected value
  P = 1%, EV = 100 → pity at 200
  Protects ~13% of players who would otherwise have nothing

Generous pity: 1× the expected value
  P = 1%, EV = 100 → pity at 100
  Protects ~37% of players. This significantly raises the effective rate.

Aggressive pity: 0.5× the expected value
  P = 1%, EV = 100 → pity at 50
  Most players are now guaranteed within pity. The "1%" rate is misleading —
  the effective rate is much higher.
```

**Rule of thumb:** Set hard pity at 2× the expected value. Set soft pity to start at 1× the expected value. This protects the unluckiest players without dramatically changing the average experience.

---

## 5. Duplicate Protection

Once a player has an item, getting it again is usually less exciting (and sometimes worthless). Duplicate protection ensures the pool of possible rewards narrows as the player acquires items.

### Remove-on-Acquire

After receiving an item, remove it from the loot table entirely.

```
Pool: 20 items, equal weight
Roll 1: 1/20 chance per item → acquire item A
Roll 2: 1/19 chance per item (A removed)
Roll 3: 1/18 chance per item
...

P(completing the full set of 20):
  Much higher than without protection.
  Without: need ~72 rolls to see all 20 (coupon collector problem)
  With: exactly 20 rolls to see all 20
```

**Best for:** Roguelikes where each upgrade is unique and non-stackable. Slay the Spire uses this for relics — once you have a relic, it can't appear again.

### Weight Reduction

Instead of removing, reduce the weight of acquired items.

```
Pool: 20 items, weight 10 each (total 200)
Acquire item A → A's weight drops to 2 (total 192)

P(A again) = 2/192 = 1.04% (was 5%)
P(any new item) = 190/192 = 98.96%
```

**Best for:** Systems where duplicates have some value (upgrade material, selling for currency) but shouldn't dominate offerings.

### Smart Reroll

When a duplicate would be offered, reroll with a chance of replacing it.

```
Offering: 3 items from pool of 40. Player owns 10 items.
Initial roll: [Item A (owned), Item B (new), Item C (owned)]

Reroll duplicates with 80% chance:
  Item A: 80% chance of being replaced by a random non-owned item
  Item C: 80% chance of being replaced by a random non-owned item

Final offering likely: [Item X (new), Item B (new), Item Y (new)]
```

**Best for:** Offering-based systems (roguelike upgrade selections) where the player shouldn't see mostly-owned items. The 80% reroll (rather than 100%) keeps a small chance of duplicates, which can matter if duplicates have value (selling, upgrading).

---

## 6. Frequency of Opportunity vs. Probability per Opportunity

Two reward systems can have identical expected rates but feel completely different based on how often the player interacts with the system.

### The Key Distinction

```
System A: Kill 1 boss per floor. Boss has 20% Legendary drop rate.
System B: Kill 50 enemies per floor. Each has 0.4% Legendary drop rate.

Expected Legendaries per floor:
  A: 1 × 0.20 = 0.20 per floor
  B: 50 × 0.004 = 0.20 per floor (identical!)

But the experience is completely different:
  A: Player gets a Legendary every ~5 floors. Each boss kill is exciting.
  B: Player gets a Legendary every ~5 floors on average, but with high
     variance. Some floors give 2, some droughts last 10+ floors.
     Individual kills are never exciting (0.4% is below perception).
```

### Frequency vs. Probability Tradeoffs

| | High Frequency, Low Probability | Low Frequency, High Probability |
|---|---|---|
| **Feel** | Gradual, "farming" | Event-driven, exciting |
| **Variance** | Low (law of large numbers) | High (few trials) |
| **Worst case** | Long drought possible but rare | Shorter drought but each miss hurts |
| **Best for** | Background rewards, passive income | Milestone rewards, boss loot |

### Designing for Feel

**If you want the reward to feel like an event:** Low frequency, high probability. Make the reward come from a specific, infrequent source (boss, chest, quest completion) with a high drop rate. Each interaction with the source is a moment of anticipation.

**If you want the reward to feel like accumulation:** High frequency, low probability. Make the reward possible from every enemy kill or every action. Individual moments don't feel special, but the player develops a sense of "it's coming soon" based on time invested.

**The roguelike sweet spot:** Most roguelikes use both. Common upgrades come from high-frequency sources (enemy drops, room clears). Rare and Legendary upgrades come from low-frequency, high-probability sources (boss kills, treasure rooms, shops). This creates a rhythm: constant small upgrades punctuated by exciting rare finds.

---

## 7. Drop Rate "Feel" — Perceived vs. Actual Rates

Players are terrible at estimating probabilities. A 10% proc rate *feels* like it "never happens." A 30% proc rate *feels* like it happens "about half the time." Understanding this perception gap lets you set rates that create the intended experience.

### The Perception Table

| Actual Rate | Player Perception              | Design Implication                     |
|-------------|--------------------------------|----------------------------------------|
| 1-5%        | "Almost never"                 | Needs pity timer or it feels broken    |
| 5-10%       | "Rarely"                       | Noticeable over many encounters        |
| 10-20%      | "Sometimes"                    | Feels like a real part of the kit      |
| 20-30%      | "Often"                        | Player plans around it happening       |
| 30-50%      | "Most of the time"             | Reliable enough to depend on           |
| 50-70%      | "Usually"                      | More notable when it fails             |
| 70-90%      | "Almost always"                | Failures feel like bugs                |
| 90-99%      | "Guaranteed" (in player's mind) | Failures cause rage                    |

### Calibrating Rates for Intent

**"I want this to feel like a bonus."** Set at 10-20%. It happens often enough to be noticed, rarely enough to feel like a treat. Crit chance, on-hit procs, bonus gold drops.

**"I want this to be a build mechanic."** Set at 25-40%. Happens often enough to plan around. "Every third hit procs lightning" (33%) feels like a rhythm the player can learn.

**"I want this to feel reliable."** Set at 50%+ or use a deterministic system. If the player needs to count on it, don't use low probability. Use cooldowns, charge systems, or guaranteed procs every Nth hit.

**"I want this to be a rare moment of wonder."** Set at 1-5% with a pity timer. The player can't plan around it, but when it happens, it's memorable. Legendary drops, critical-hit chain reactions.

---

## Exercises

### Exercise 1: Loot Table Design

Design a tiered loot table for a dungeon chest with these requirements:
- 4 rarity tiers (Common, Uncommon, Rare, Legendary)
- 8 Common items, 5 Uncommon, 3 Rare, 1 Legendary
- Average "value" per chest should be ~35 budget points
- The player opens ~50 chests per run

1. Set the rarity drop rates
2. Calculate the expected number of each rarity per run
3. Calculate the expected total budget points from 50 chests
4. What's the probability of getting zero Legendaries in a full run?
5. Design a pity timer to make zero-Legendary runs less than 5% likely

### Exercise 2: PRD Implementation

A weapon has a 20% chance to "stun" on hit. The player attacks 2 times per second over a 60-second boss fight (120 total attacks).

1. With true random: calculate the expected number of stuns, and the probability of getting 0 stuns in the first 20 hits
2. With PRD (C = 0.0380 for 20%): calculate the maximum possible streak without a stun
3. Compare the variance of stun timing between true random and PRD
4. If the boss has a 5-second vulnerability window every 15 seconds, which system (true random or PRD) is more likely to produce a stun during the window?

### Exercise 3: Pity Timer Math

A gacha system has a 2% featured rate with:
- Soft pity starting at pull 60 (+3% per pull)
- Hard pity at pull 80

1. What's the effective average rate (accounting for pity)?
2. What percentage of players hit hard pity?
3. What percentage of players get the featured item before pull 60 (before soft pity kicks in)?
4. Plot the cumulative probability of having received the item by pull N, for N = 1 to 80

### Exercise 4: Offering System

Design a roguelike upgrade offering system for a game with 45 upgrades (15 per element: fire/ice/lightning). The player is offered 3 choices, 20 times per run.

Requirements:
- By run's end, the player should have seen at least 12 upgrades from their primary element
- No more than 3 offerings in a row should be "all generic" (no element the player has invested in)
- Legendary upgrades should only appear after floor 5

Design the offering algorithm (weights, pity timers, rarity gating) and calculate:
1. Expected fire upgrades seen per run (with and without investment weighting)
2. Probability of "all generic" streak of 4+ offerings
3. Average floor where the first Legendary appears

---

## Further Reading

- **"Pseudo-Random Distribution" on Dota 2 Wiki** — the most detailed public documentation of PRD, including C constant tables and edge cases. Dota 2 uses PRD for critical strikes, evasion, and bash.
- **"Designing Ethical Loot Boxes" by Rami Ismail** — covers the ethics of randomized reward systems and techniques for making them feel fair. Relevant to any game with random drops.
- **"Gacha design" community analyses** — search for analyses of Genshin Impact, Arknights, or Fire Emblem Heroes pity systems. These games have the most sophisticated public pity timer implementations.
- **"The Coupon Collector Problem"** — the classic probability problem underlying duplicate protection. Answers "how many rolls until I've seen everything?" for uniform random selection.
- **[Module 0: The Math of Balance](module-00-the-math-of-balance.md)** — Section 3 (distributions) and Section 5 (risk-reward) are prerequisites for understanding why players misperceive probabilities.
- **[Game Design Theory Module 5: Economy](../game-design-theory/module-05-game-economy-resource-design.md)** — covers the design philosophy of reward systems. This module provides the implementation math.
