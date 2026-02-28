# Module 1: Damage Formulas & DPS Modeling

**Part of:** [Game Balance Learning Roadmap](game-balance-roadmap.md)
**Estimated study time:** 3–4 hours
**Prerequisites:** [Module 0: The Math of Balance](module-00-the-math-of-balance.md)

---

## Overview

The damage formula is the most consequential single equation in a combat game. It determines how attack and defense interact, where breakpoints create interesting decisions or frustrating cliffs, whether player power growth feels satisfying or broken, and how long combat encounters last. Two games with identical content but different damage formulas will play completely differently.

This module covers the three major formula families (subtractive, divisive, hybrid), how to analyze them using DPS and TTK, the breakpoint problem, additive vs. multiplicative stacking as a deliberate design choice, and effective HP as the unified metric for survivability. By the end, you'll be able to pick and defend a damage formula for your game, predict where it will break down, and model combat encounters on paper before writing a line of game code.

---

## 1. The Three Formula Families

Every damage formula maps **attack** and **defense** to **damage dealt.** The shape of that mapping — whether defense creates hard walls, smooth diminishing returns, or something in between — is the fundamental design choice.

### Flat (Subtractive)

```
damage = max(0, attack - defense)
```

Attack minus defense. Simple and intuitive. Used in many classic RPGs and tactical games.

**Properties:**
- **Hard breakpoints.** When defense ≥ attack, damage is zero. The target is invulnerable.
- **Linear scaling.** Each point of attack adds exactly 1 damage (until defense nullifies it). Each point of defense removes exactly 1 damage.
- **Favors big hits over fast hits.** An attack dealing 100 damage once against 40 defense deals 60 damage. Two attacks dealing 50 each deal 10 + 10 = 20. The single big hit is 3× better against the same defense.

**When to use it:** Tactical games where defense should create meaningful thresholds. Fire Emblem uses subtractive formulas — units with high defense genuinely wall physical attacks, creating tactical puzzles.

**When to avoid it:** Any game where you don't want complete damage negation. If enemies can become invulnerable through stat stacking, it can lock players out of content.

**Spreadsheet:**
```
Attack=10, Defense=5  → damage = 5
Attack=10, Defense=10 → damage = 0  ← breakpoint!
Attack=10, Defense=15 → damage = 0
Attack=20, Defense=10 → damage = 10
```

### Divisive (Multiplicative Reduction)

```
damage = attack × (k / (k + defense))
```

Where `k` is a constant that determines how effective defense is. Common values: k = 100, k = 50.

**Properties:**
- **No hard breakpoints.** Defense never reduces damage to zero. At defense = k, damage is halved. At defense = 2k, damage is reduced to 1/3. Asymptotically approaches zero but never reaches it.
- **Diminishing returns.** The first 100 points of defense are more impactful than the next 100. Going from 0 → 100 defense (with k=100) halves damage. Going from 100 → 200 reduces it from 50% to 33% — only a further 17% reduction.
- **Neutral to hit speed.** Two hits of 50 and one hit of 100 produce the same total damage. The formula is proportional.

**When to use it:** Most action RPGs, ARPGs, and roguelikes. Diablo, League of Legends, and many Hades-style games use divisive formulas. Players always deal *some* damage, which keeps combat from stalling.

**When to avoid it:** Games where you want defense to create complete immunity in certain matchups. Divisive formulas always let damage through.

**The k constant:**

`k` controls how much defense you need to halve incoming damage. Small `k` (e.g., 50) means defense is very effective — 50 defense halves damage. Large `k` (e.g., 500) means defense is weak — you need 500 defense to halve damage. Choose `k` relative to the defense values you expect in your game.

**Spreadsheet:**
```
k=100:
Attack=100, Defense=0   → damage = 100
Attack=100, Defense=50  → damage = 66.7
Attack=100, Defense=100 → damage = 50    ← half damage
Attack=100, Defense=200 → damage = 33.3
Attack=100, Defense=500 → damage = 16.7
```

### Hybrid (Subtractive + Multiplicative)

```
damage = max(min_damage, attack × (k / (k + defense)) - flat_reduction)
```

Combines a multiplicative reduction with a flat subtraction. Offers the diminishing-returns feel of divisive formulas with the hard-threshold feel of flat subtraction for low damage values.

**Properties:**
- **Soft breakpoints.** Low damage is floored by `min_damage` or reduced to zero by the flat component, creating thresholds without total immunity.
- **Two defense stats.** Some games separate "armor" (multiplicative) from "toughness" (flat reduction), giving players two defensive stats to invest in with different scaling properties.
- **Harder to tune.** Three parameters (k, flat_reduction, min_damage) create a larger tuning surface. But they also give more design control.

**When to use it:** Games that want nuanced defense — where heavy armor reduces big hits and damage absorption nullifies chip damage. Dark Souls uses a hybrid formula.

---

## 2. DPS — The Universal Comparison Metric

**Damage per second (DPS)** normalizes different weapons, builds, and strategies onto a single scale. It accounts for damage per hit, attack speed, hit chance, and crit.

**Basic DPS formula:**

```
DPS = (base_damage × hit_chance × crit_multiplier_factor) × attack_speed
```

Where `crit_multiplier_factor = 1 + crit_chance × (crit_multiplier - 1)`.

**Example:**
```
Base damage:     50
Attack speed:    1.5 hits/sec
Hit chance:      90%
Crit chance:     20%
Crit multiplier: 2.0×

Crit factor = 1 + 0.20 × (2.0 - 1) = 1.20
DPS = (50 × 0.90 × 1.20) × 1.5 = 54 × 1.5 = 81
```

**Why DPS and not "damage per hit"?**

Damage per hit is misleading when weapons have different attack speeds. A dagger dealing 20 damage at 3 hits/sec (60 DPS) outperforms a hammer dealing 100 damage at 0.5 hits/sec (50 DPS). DPS lets you compare them directly.

**DPS with damage formulas:**

DPS after defense is `DPS × damage_reduction_factor`. For a divisive formula:
```
Effective DPS = raw_DPS × (k / (k + target_defense))
```

This is the number that determines how long fights actually last.

---

## 3. Time to Kill (TTK)

**TTK** is the most important derived metric in combat design. It determines the pace and feel of every encounter.

```
TTK = target_HP / attacker_effective_DPS
```

**Example:**
```
Attacker effective DPS: 81 (from above)
Target HP: 500
TTK = 500 / 81 ≈ 6.2 seconds
```

**TTK design ranges:**

| TTK Range | Feel | Genre Examples |
|-----------|------|---------------|
| 0.1–0.5s | Instant, lethal | FPS headshots, one-shot mechanics |
| 0.5–2s | Fast, twitchy | Shooters, fast action games |
| 2–8s | Standard action | Hades, action RPGs, roguelikes |
| 8–30s | Extended encounter | MMO trash mobs, bullet sponges |
| 30s–5min | Boss fight | Roguelike bosses, raid bosses |

**The TTK determines:**
- **Player attention span per encounter.** Roguelike rooms with 15 enemies at 10s TTK each = 2.5 minutes per room. Is that too long?
- **Healing viability.** If TTK is 2 seconds, healing during combat is impossible. If TTK is 30 seconds, healing becomes a viable strategy.
- **Skill expression.** Short TTK rewards reaction and positioning. Long TTK rewards resource management and optimization.

**Bidirectional TTK:**

Don't just calculate how long the player takes to kill the enemy — calculate how long the enemy takes to kill the player.

```
Player kills enemy in: enemy_HP / player_DPS
Enemy kills player in: player_HP / enemy_DPS

If player_TTK < enemy_TTK → player wins
If player_TTK > enemy_TTK → player loses (without healing/evasion)
```

The ratio between these two TTKs is the **pressure ratio.** A pressure ratio of 3:1 (player kills 3× faster than enemy) feels comfortable. 1.5:1 feels tense. 1:1 is a coinflip. Below 1:1, the player needs skill or sustain to survive.

---

## 4. Breakpoints

A **breakpoint** is a threshold where a small stat change causes a qualitative shift in gameplay. Breakpoints create interesting build decisions — but also frustrating dead zones.

### Damage Breakpoints

In a subtractive formula, the breakpoint is where attack = defense. Below it, damage is zero. Above it, every point of attack adds full damage. This creates a sharp transition:

```
Flat formula, defense = 50:
Attack 48: damage = 0
Attack 49: damage = 0
Attack 50: damage = 0  ← breakpoint
Attack 51: damage = 1
Attack 52: damage = 2
```

The jump from "zero damage" to "some damage" is the most important breakpoint in any flat formula.

### Speed Breakpoints

Attack speed breakpoints occur when the game has discrete timing. If an attack animation takes 0.5 seconds and the game ticks at 60 FPS:
- 1.9 attacks/sec → 1 attack per animation cycle
- 2.0 attacks/sec → 2 attacks per animation cycle (if the engine allows overlapping)

In games with animation locks, there are speed thresholds where additional attack speed doesn't help until you can fit one more attack into a window. This creates "dead zones" where attack speed investment is wasted.

### Hit-Count Breakpoints

How many hits does it take to kill a target?

```
Target HP: 100, Damage per hit: 34
Hits to kill: ceil(100/34) = 3 hits

Target HP: 100, Damage per hit: 33
Hits to kill: ceil(100/33) = 4 hits  ← one less damage, one more hit
```

A single point of damage changed the hit count. That extra hit could mean an extra half-second of combat per enemy, which across hundreds of enemies per run adds minutes. The difference between 3-hit and 4-hit kills is the difference between a fast, fluid run and a sluggish one.

**Designing around breakpoints:**

- **Lean into them** in tactical games. Fire Emblem's damage negation is a feature, not a bug — it creates matchup puzzles.
- **Smooth them out** in action games. Divisive formulas avoid hard breakpoints. Minimum damage floors prevent zero-damage scenarios.
- **Communicate them** if they exist. If players can see that they need 5 more attack to hit the next breakpoint, that creates a clear, satisfying goal.

---

## 5. Additive vs. Multiplicative Stacking

When multiple damage modifiers apply, do they add or multiply? This is a **design decision**, not just a math question, because it fundamentally changes how builds work.

### Additive Stacking

All bonuses are summed, then applied once.

```
Base damage: 100
Bonus 1: +20%
Bonus 2: +30%
Bonus 3: +15%

Total bonus: 20 + 30 + 15 = 65%
Final damage: 100 × (1 + 0.65) = 165
```

**Properties:**
- **Linear scaling.** Each additional bonus adds the same absolute amount. The 4th +10% bonus adds the same 10 damage as the 1st.
- **Easy to value.** +10% is always worth +10% of base, regardless of how many other bonuses you have.
- **Hard to get exciting.** Stacking 10 bonuses of +10% gives +100% — doubled damage. Fine, but not explosive.

### Multiplicative Stacking

Each bonus multiplies independently.

```
Base damage: 100
Bonus 1: +20% → ×1.20
Bonus 2: +30% → ×1.30
Bonus 3: +15% → ×1.15

Final damage: 100 × 1.20 × 1.30 × 1.15 = 179.4
```

**Properties:**
- **Exponential scaling.** Each additional bonus multiplies all previous gains. Ten +10% bonuses give 100 × 1.1^10 = 259 — not 200, but 259.
- **Increasing value.** The more bonuses you have, the more each new bonus is worth. The 10th bonus is worth more than the 1st in absolute terms.
- **Creates explosive power.** Stacking multiplicative bonuses creates the "broken build" feeling that roguelike players love. But it can also blow past your power budget.

### The Design Decision

Most games use **both**, carefully separated into categories:

```
Final damage = base_damage
             × (1 + sum_of_additive_bonuses)
             × multiplicative_bonus_1
             × multiplicative_bonus_2
             × ...
```

**Additive within categories, multiplicative between categories.** This is the Path of Exile / Diablo approach. "Increased damage" bonuses are additive with each other. "More damage" bonuses multiply everything. Players who stack only "increased" get linear growth. Players who collect sources from different categories get multiplicative growth — rewarding build diversity.

**For roguelikes:** The multiplicative-between-categories approach is ideal. Each upgrade category adds linearly (preventing any single category from dominating). But collecting upgrades from multiple categories creates satisfying power spikes through multiplication. The player feels clever for combining synergies, and the math stays bounded because each category has limited options.

---

## 6. Effective HP

**Effective HP (eHP)** is the total raw damage an entity can absorb before dying, accounting for all damage reduction. It unifies HP, armor, evasion, and damage resistance into one number.

**With multiplicative damage reduction:**
```
eHP = HP / (1 - damage_reduction)
```

Or equivalently for a divisive formula:
```
eHP = HP × (1 + defense/k)
```

**Examples:**
```
500 HP, 0% reduction      → eHP = 500
500 HP, 50% reduction     → eHP = 1,000
500 HP, 75% reduction     → eHP = 2,000
500 HP, 90% reduction     → eHP = 5,000
```

**With evasion:**
```
eHP = HP / (1 - damage_reduction) / hit_chance
```

A character with 300 HP, 30% damage reduction, and 20% evasion:
```
eHP = 300 / 0.70 / 0.80 = 535.7
```

**Why eHP matters:**

- **Comparing builds.** A tank with 1,000 HP and 60% reduction (eHP=2,500) is tankier than a character with 2,000 HP and 0% reduction (eHP=2,000).
- **Stat efficiency.** Is the next point of HP or the next point of defense worth more? Calculate the eHP gain from each and compare. The answer changes based on current values — when you have lots of HP but little defense, defense is efficient, and vice versa. This creates natural diminishing returns on stacking a single stat.
- **Balancing healing.** A 100 HP heal on a character with 50% damage reduction is effectively 200 eHP restored. High-defense characters get more value from flat healing.

### The HP × Defense Quadratic

For a divisive formula, eHP = HP × (1 + def/k). Both HP and defense contribute multiplicatively to survivability. This means the most efficient build invests in *both* — pure HP or pure defense are suboptimal compared to balanced investment.

```
Budget: 100 points. 1 point = 10 HP or 5 defense. k=100.

All HP:      HP=1000, def=0   → eHP = 1000 × 1.00 = 1,000
All defense: HP=0,    def=500 → eHP = 0 (dead instantly)
Balanced:    HP=500,  def=250 → eHP = 500 × 3.50  = 1,750
Optimized:   HP=600,  def=200 → eHP = 600 × 3.00  = 1,800
```

The balanced build has nearly 2× the eHP of all-HP. This is why games with multiplicative defense naturally encourage build diversity — pure stacking one survivability stat is mathematically inefficient.

---

## 7. Designing Your Damage Formula

Choosing a formula isn't about finding the "right" one — it's about matching the formula to your game's design goals.

**Decision matrix:**

| Question | If Yes → | If No → |
|----------|----------|---------|
| Should defense ever fully negate damage? | Subtractive | Divisive or hybrid |
| Should stacking one stat be viable? | Additive stacking | Multiplicative categories |
| Should heavy armor feel qualitatively different? | Hybrid with flat component | Pure divisive |
| Is your game fast-paced with short TTK? | Simpler formula, fewer terms | More complex formula with more knobs |
| Do you want build diversity in survivability? | Divisive (HP × def quadratic) | Subtractive (stacking one stat works) |

**Recommended starting point for roguelikes:**

```
damage = base_attack
       × (1 + sum_of_additive_bonuses)
       × category_multiplier_1
       × category_multiplier_2
       × (k / (k + target_defense))
       - flat_reduction (if any)

Final = max(1, damage)   // minimum 1 damage, no zeroes
```

This gives you additive scaling within bonus categories, multiplicative scaling between categories, diminishing returns on defense, no hard immunity thresholds, and a minimum damage floor.

---

## Exercises

### Exercise 1: Formula Comparison

Implement all three formula families in a spreadsheet:

1. **Flat:** `max(0, attack - defense)`
2. **Divisive:** `attack × 100/(100 + defense)`
3. **Hybrid:** `max(1, attack × 100/(100 + defense) - defense/5)`

For each:
- Chart damage as attack varies from 10–200, defense fixed at 50
- Chart damage as defense varies from 0–200, attack fixed at 100
- Identify all breakpoints (where damage qualitatively changes)

### Exercise 2: DPS and TTK Modeling

Using the divisive formula with k=100:

A player has: Attack=45, Speed=1.5/sec, Crit%=15%, CritMulti=2×.
An enemy has: HP=400, Defense=30.

1. Calculate player DPS (accounting for crit)
2. Calculate effective DPS after enemy defense
3. Calculate TTK
4. The player gets a +10 attack upgrade. What's the new TTK? How much faster (percentage) is the kill?
5. Instead of +10 attack, the player gets +0.3 attack speed. What's the new TTK? Which upgrade is better?

### Exercise 3: eHP Analysis

A roguelike has three defensive upgrade paths:
- **Tough:** +100 HP (base HP: 300)
- **Armored:** +30 defense (base defense: 20, k=100)
- **Evasive:** +10% evasion (base evasion: 0%)

1. Calculate the eHP gain from each upgrade
2. If the player already has +200 HP from previous upgrades, recalculate. Which upgrade is now best?
3. If the player already has +60 defense from previous upgrades, recalculate. Which upgrade is now best?
4. At what point does each upgrade become the least efficient?

### Exercise 4: Stacking Design

Design a roguelike damage system with 3 bonus categories: "Might" (additive within category), "Ferocity" (additive within category), and "Amplify" (each source is a separate multiplier). A run offers 12 total bonuses: 5 Might (+8% each), 4 Ferocity (+12% each), 3 Amplify (+15% each).

1. Calculate final damage for a build that takes all 5 Might (and nothing else)
2. Calculate final damage for a build that takes 2 Might + 2 Ferocity + 2 Amplify
3. Calculate final damage for a build that takes 1 Might + 1 Ferocity + 3 Amplify
4. Which build has the highest damage? Is that the design intent?

---

## Further Reading

- **"Damage Calculation" game wiki comparisons** — compare Dark Souls (subtractive + multiplicative hybrid), Pokémon (type multiplier + stat-based), Diablo (multiplicative categories), and Hades (divisive with flat reduction). Each makes different tradeoffs.
- **"Effective HP and Armor Math"** — League of Legends and Dota 2 theorycrafting communities have analyzed these formulas exhaustively. The math transfers to any game.
- **"Armor Penetration and Effective Defense"** — search for blog posts on armor pen as a mechanic. Armor penetration creates secondary breakpoints and adds a stat interaction layer.
- **"GDC: Math for Game Programmers"** — Squirrel Eiserloh's series covers curves and formulas with interactive examples. The damage formula session is directly relevant.
- **[GAS Module 1: Attributes & Modifier Stacking](../gas/module-01-attributes-and-modifier-stacking.md)** — covers the implementation of modifier pipelines. This module covers the design choices that determine how those modifiers should stack.
