# Module 0: The Math of Balance

**Part of:** [Game Balance Learning Roadmap](game-balance-roadmap.md)
**Estimated study time:** 2–3 hours
**Prerequisites:** None

---

## Overview

Game balance is applied math. Not hard math — you won't need calculus or linear algebra. But you need a firm grip on probability, expected value, variance, and how humans perceive numbers. These tools let you compare options that look incomparable ("is a 20% crit chance worth more than +15 attack?"), predict how systems behave before building them, and identify when something feels wrong even if you can't immediately explain why.

This module builds the statistical vocabulary you'll use throughout the rest of the roadmap. Expected value is the universal currency of balance. Variance explains why two options with the same average feel completely different. The Weber-Fechner Law explains why a +10 stat gain is exciting at level 1 and boring at level 50. Risk-reward framing through EV explains why players avoid "fair" gambles. And back-of-envelope estimation gives you the ability to sanity-check any number in seconds.

None of this is academic. Every concept directly maps to a balance decision you'll face: how to price upgrades, how to set damage ranges, how to space stat gains across a progression curve, how to evaluate whether a "risky" ability is actually better or worse than a "safe" one.

---

## 1. Expected Value — The Universal Currency

**Expected value (EV)** is the average outcome of a random event if you repeated it infinitely many times. It's calculated by multiplying each possible outcome by its probability and summing the results.

**Formula:**
```
EV = Σ (outcome_i × probability_i)
```

**Example — Weapon comparison:**
- **Sword:** 50 damage, 100% hit rate → EV = 50 × 1.0 = **50**
- **Bow:** 80 damage, 70% hit rate → EV = 80 × 0.7 = **56**
- **Bomb:** 200 damage, 25% hit rate → EV = 200 × 0.25 = **50**

The Bow has the highest EV. The Sword and Bomb have identical EV. But they *feel* completely different — which is where variance comes in (Section 2).

**EV with multiple outcomes:**

A critical hit system: 75% chance of 40 damage, 25% chance of 100 damage (crit).
```
EV = (0.75 × 40) + (0.25 × 100) = 30 + 25 = 55
```

**Why EV matters for balance:**

EV is how you put different options on the same scale. Without EV, you can't answer "is +10% crit chance better or worse than +5 attack?" With EV, you can. Calculate the EV of each option and compare. The one with higher EV is mathematically stronger — though "mathematically stronger" isn't always the same as "better for the game" (Sections 4 and 5 address this).

**Common EV traps:**
- **Ignoring conditional probability.** "This ability does 200 damage" — but only if the enemy is burning. What percentage of the time are enemies burning? If 30%, the effective EV is 60 damage, not 200.
- **Confusing average with guarantee.** An EV of 50 doesn't mean you'll get 50. The Bomb above (EV=50) gives you either 0 or 200 — never 50. EV describes the long run, not any individual event.
- **Adding EV incorrectly across dependent events.** If event B's outcome depends on event A, you can't just add their EVs independently. You need conditional EV.

---

## 2. Variance and Standard Deviation

Two options with the same EV can feel completely different. **Variance** measures how spread out outcomes are around the expected value. **Standard deviation** is the square root of variance — it's in the same units as the original measurement, making it more intuitive.

**Formula:**
```
Variance = Σ (outcome_i - EV)² × probability_i
Standard Deviation = √Variance
```

**Example — Same EV, different variance:**

Both weapons have EV = 50 damage per hit.

**Weapon A:** Always deals 50 damage.
```
Variance = (50 - 50)² × 1.0 = 0
StdDev = 0
```

**Weapon B:** Deals 10 damage (50% chance) or 90 damage (50% chance).
```
EV = (0.5 × 10) + (0.5 × 90) = 50
Variance = (10 - 50)² × 0.5 + (90 - 50)² × 0.5 = 800 + 800 = 1600
StdDev = 40
```

Weapon A is perfectly consistent. Weapon B swings wildly. Over 10 hits, Weapon A always deals 500 damage. Weapon B deals between 100 and 900, with an average of 500.

**Why variance matters for balance:**

- **Player experience:** High-variance weapons feel exciting on crits and frustrating on misses. Low-variance weapons feel reliable but boring. The right amount depends on your game's identity.
- **TTK consistency:** If your target TTK is 5 seconds, high-variance damage makes actual TTK range from 3–10 seconds. Low-variance damage keeps it at 4.5–5.5. Consistent TTK is important for competitive/skill-based games. Variable TTK can work for PvE and roguelikes where each encounter is a story.
- **Build diversity:** High-variance options appeal to risk-seeking players. Low-variance options appeal to risk-averse players. Both options can coexist if EVs are balanced — see Module 4.
- **Streaks and droughts:** High variance creates memorable streaks (three crits in a row!) and frustrating droughts (eight misses in a row). Module 5 covers pseudo-random distribution, which reduces streak variance without changing EV.

**Coefficient of variation (CV):**

To compare variance across different scales, use the coefficient of variation: `CV = StdDev / EV`. A weapon with EV=50, StdDev=10 (CV=0.2) has the same relative variance as a weapon with EV=500, StdDev=100 (CV=0.2). CV is useful when comparing options that operate at different damage scales.

---

## 3. Distributions You'll Encounter

Not all randomness is the same. The **distribution** describes the shape of possible outcomes — where they cluster, how they spread, whether they're symmetric.

### Uniform Distribution

Every outcome is equally likely. Rolling a fair die. Picking a random number between 1 and 100.

```
Damage range: 20–40 (uniform)
EV = (20 + 40) / 2 = 30
Any value between 20 and 40 is equally likely
```

**When you'll use it:** Base damage ranges, random loot selection within a tier, random upgrade offers. Uniform is the default assumption and the simplest to reason about.

### Normal (Gaussian) Distribution

Outcomes cluster around the mean with a bell-curve shape. Most outcomes are near the center; extreme outcomes are rare.

```
Damage: mean=50, stddev=10
~68% of hits deal 40–60 damage
~95% of hits deal 30–70 damage
~99.7% of hits deal 20–80 damage
```

**When you'll use it:** Aggregated outcomes (total damage over a run, total gold earned), player skill distributions, anything that results from the sum of many small random factors. The Central Limit Theorem says that sums of random variables tend toward normal, which is why simulation results (Module 6) often look bell-shaped.

### Weighted (Discrete) Distribution

Each outcome has a specific, potentially different probability. Loot tables, crit systems, ability procs.

```
Common item:  60% chance
Uncommon:     25% chance
Rare:         12% chance
Legendary:     3% chance
```

**When you'll use it:** Every loot table, every rarity system, every proc chance. This is the most common distribution in game design. Module 5 covers it extensively.

### Geometric Distribution

How many trials until the first success. "How many enemies do I need to kill before a Legendary drops?"

```
P(success) = 0.03 (3% per kill)
Expected kills until first drop: 1 / 0.03 ≈ 33
But the distribution is heavily skewed — 50% of players get it within 23 kills,
while 5% need 100+ kills
```

**When you'll use it:** Any "grind until drop" scenario. The skew is the problem — the average is 33, but the unluckiest 5% need 3× as many attempts. This is why pity timers exist (Module 5).

---

## 4. The Weber-Fechner Law

The Weber-Fechner Law states that **perceived change is proportional to the relative change, not the absolute change.** Going from 10 → 20 attack (+100%) feels massive. Going from 100 → 110 (+10%) feels trivial. Same +10, completely different perception.

**The math:**
```
Perceived change ≈ log(new_value / old_value)
```

**Implication for stat gains:**

If you want each level-up to *feel* equally impactful, you need to scale gains proportionally. If level 1 → 2 gives +10 attack (10 → 20, +100%), then level 10 → 11 needs +10 as well (100 → 110, +10%) — but that feels like nothing. To match the perceived impact, you'd need level 10 → 11 to give +100 attack (100 → 200, +100%). This is why:

- **Linear stat growth feels increasingly disappointing.** Same absolute gain each level, but the relative gain shrinks.
- **Percentage-based growth maintains feel.** +20% per level always feels like +20%, regardless of the current value.
- **Exponential growth eventually breaks.** +20% per level compounds: after 20 levels, the value is 38× the starting value. After 50 levels, 9,100×. Numbers become meaningless.

**The sweet spot** for most roguelikes is polynomial growth — faster than linear, slower than exponential. Module 3 covers this in detail.

**Weber-Fechner in practice:**
- **Damage numbers:** Players barely notice a +5% damage buff. They definitely notice +20%. Below the perception threshold, your buff is wasted design effort.
- **Upgrade pricing:** If upgrade 1 costs 100 gold and upgrade 2 costs 110 gold, they feel almost the same. If upgrade 2 costs 200 gold, the doubling is immediately felt. Scale costs by ratios, not differences.
- **Difficulty spikes:** An enemy with +10% more HP than the last zone is barely noticeable. An enemy with +50% more HP is a wall. Difficulty tuning operates on the log scale.

---

## 5. Risk-Reward as Expected Value

In theory, two options with the same EV are equivalent. In practice, players are **risk-averse** — they value guaranteed outcomes more than uncertain ones, even when the EV is identical.

**Prospect theory** (Kahneman & Tversky) describes how humans actually evaluate risky options:

- **Loss aversion:** Losing 50 gold feels roughly twice as bad as gaining 50 gold feels good. Losses loom larger than gains.
- **Certainty effect:** A 100% chance of 50 gold is valued more than a 50% chance of 110 gold (EV = 55), even though the risky option has higher EV.
- **Small probability overweighting:** Players overestimate the chance of rare events (crits, legendary drops). A 5% crit chance feels like it "almost never happens" until they're on the receiving end.

**Implications for balance:**

If you offer a "safe" upgrade (guaranteed +20 damage) and a "risky" upgrade (50% chance of +50 damage, 50% chance of +0), the risky option has higher EV (25 vs. 20) but most players will take the safe one. To make risky options equally appealing, you need to give them *more* EV — the risk premium.

```
Risk premium = how much extra EV a risky option needs to be equally attractive

For moderate risk: ~20–30% EV bonus
For high risk (chance of total loss): ~50–100% EV bonus
```

**Practical rules:**
- If you want players to take risky options, make the EV noticeably higher (not subtly higher).
- If you want meaningful choice between safe and risky, make the EV roughly equal — risk-averse players take safe, risk-seeking players take risky. Both are correct.
- If a risky option has *lower* EV than the safe option, it's a trap — no rational player should take it, and risk-seeking players are being punished.

---

## 6. Back-of-Envelope Estimation

Before you build a spreadsheet, simulate, or playtest, you should be able to estimate whether a number is in the right ballpark in 30 seconds. This is the single most practical skill in game balance.

**The method:**

1. **Identify the key rate.** DPS, gold per minute, upgrades per zone, enemies per encounter.
2. **Multiply by time/quantity.** 120 DPS × 60-second boss fight = 7,200 total damage.
3. **Compare against the target.** Boss has 10,000 HP. Player does 7,200 damage. Player loses. Boss should have ~6,000 HP for a comfortable win.

**Examples:**

*"Is this boss beatable?"*
- Player DPS: ~80 (20 base attack × 2 hits/sec × 2.0 average multiplier from upgrades)
- Boss HP: 5,000
- Boss DPS to player: ~40
- Player HP: 500
- Player kills boss in: 5,000 / 80 = 62.5 seconds
- Boss kills player in: 500 / 40 = 12.5 seconds
- **Player dies 5× before killing the boss.** Something's wrong. Either player DPS is too low, boss HP is too high, or the player needs sustain (healing, evasion).

*"Is this drop rate reasonable?"*
- Legendary drop rate: 1%
- Enemies per run: ~200
- Expected Legendaries per run: 200 × 0.01 = 2
- Probability of zero Legendaries in a run: (0.99)^200 ≈ 13%
- **13% of runs get zero Legendaries.** That's frustrating. Either increase the rate or add a pity timer.

*"Does this upgrade matter?"*
- Current DPS: 100
- Upgrade: +5 attack (on a base of 50)
- DPS increase: roughly 10% (5/50)
- Weber-Fechner threshold: players notice ~15–20% changes
- **This upgrade barely registers.** Buff it or make it cheaper.

**Rules of thumb:**
- If you need more than 3 numbers to estimate the answer, you've overcomplicated it.
- If the estimate is off by more than 2×, the design has a major problem — fine-tuning won't fix it.
- Estimate first, then simulate. If the estimate says it's wrong, you don't need the simulation to confirm.

---

## 7. Putting It Together — A Balance Vocabulary

The concepts in this module form a vocabulary that you'll use throughout the rest of the roadmap:

| Term | What It Answers | Where It Applies |
|------|----------------|-----------------|
| Expected value | "Which option is mathematically better?" | Every comparison between upgrades, weapons, builds |
| Variance / StdDev | "How consistent is this?" | Combat feel, TTK ranges, build reliability |
| Weber-Fechner | "Will the player even notice this change?" | Stat gains, upgrade design, difficulty tuning |
| Risk premium | "How much extra EV does a risky option need?" | Upgrade pricing, build tradeoffs |
| Back-of-envelope | "Is this number in the right ballpark?" | Every single design decision |
| Distribution | "What shape does the randomness take?" | Loot, damage ranges, proc systems |

These aren't just definitions — they're tools. When someone on your team says "this weapon feels weak," you should be able to quantify it: "The EV is 45, compared to 60 for the other options. The variance is also high (StdDev 25), so it feels even weaker because of droughts. We need to either raise the EV to 55+ or reduce the variance."

---

## Exercises

### Exercise 1: Weapon Trio Analysis

A game has three weapons:
- **Dagger:** 25 damage, 2.0 attacks/sec, 0% crit chance
- **Sword:** 60 damage, 1.0 attacks/sec, 10% crit chance, 2× crit multiplier
- **Hammer:** 150 damage, 0.4 attacks/sec, 5% crit chance, 3× crit multiplier

For each weapon, calculate:
1. DPS (damage per second), accounting for crit
2. Variance per second (how much DPS fluctuates)
3. Coefficient of variation (StdDev / EV)

Which weapon is best for a consistent-TTK game? Which is best for a high-variance roguelike? If you wanted all three to be equally viable, what would you adjust?

### Exercise 2: Upgrade Pricing

A shop sells three upgrades:
- **+10 Attack** (base attack is 50) — currently priced at 100 gold
- **+15% Crit Chance** (base crit is 5%, crit multiplier is 2×) — currently priced at 150 gold
- **+0.3 Attack Speed** (base speed is 1.0 attacks/sec) — currently priced at 120 gold

Calculate the DPS gain per gold spent for each upgrade. Are the prices balanced? If not, what should they be? Use Weber-Fechner to evaluate whether each upgrade would "feel" impactful.

### Exercise 3: Back-of-Envelope Sprint

For each scenario, estimate the answer in under 60 seconds (no spreadsheets):

1. Player deals 75 DPS. Boss has 8,000 HP and heals 10 HP/sec. How long does the fight take?
2. A roguelike run has 50 upgrade opportunities. Each offers 3 random upgrades from a pool of 20. What's the expected number of times a specific upgrade appears per run?
3. A weapon has a 15% chance to proc "double strike." Over a 120-second boss fight at 1.5 attacks/sec, how many double strikes do you expect?
4. An upgrade gives +8% damage. The player's current DPS is 120. How much does total damage increase over a 90-second boss fight? Would a +12 flat damage upgrade be better?

---

## Further Reading

- **"Probability and Statistics for Game Designers"** — search for Ian Schreiber's game balance course. Comprehensive and game-focused.
- **"Thinking, Fast and Slow" by Daniel Kahneman** — Chapters 26–28 cover prospect theory and risk evaluation. Explains why players don't behave like EV maximizers.
- **"How to Measure Anything" by Douglas Hubbard** — covers estimation techniques and calibration. The back-of-envelope skills in Section 6 are a subset of what Hubbard teaches.
- **"Math for Game Programmers" GDC talks** — search for the Squirrel Eiserloh series. Covers randomness, curves, and probability with game-specific examples.
- **Weber-Fechner Law in game design** — search for blog posts by game designers applying psychophysics. The concept shows up in GDC talks on RPG stat design and economy tuning.
