# Module 3: Scaling Curves & Progression Math

**Part of:** [Game Balance Learning Roadmap](game-balance-roadmap.md)
**Estimated study time:** 4–5 hours
**Prerequisites:** [Module 1: Damage Formulas & DPS Modeling](module-01-damage-formulas-and-dps-modeling.md)

---

## Overview

Every game with progression faces the same question: how should power change over time? A linear curve (+10 attack per level) is easy to understand but feels increasingly flat — level 2 is a 100% increase over level 1, but level 50 is only a 2% increase over level 49. An exponential curve (×1.2 per level) maintains that relative excitement but spirals into numbers so large they lose meaning. Between these extremes lies a rich design space of polynomial, logarithmic, and piecewise curves — each with distinct tradeoffs for feel, readability, and balance.

This module covers the math behind progression curves for both player power and enemy difficulty, how to design XP and leveling systems, techniques for keeping power growth in check (diminishing returns, soft caps), and the special considerations roguelikes face with prestige systems and run-to-run progression.

The goal isn't to find the "best" curve — it's to understand each curve family well enough to pick the right one for each system in your game. Attack scaling, HP scaling, XP requirements, enemy density, and gold income might each use different curve types. The art is in choosing which curve goes where.

---

## 1. The Four Curve Families

Every progression curve in games is built from four basic families. Understanding their shapes and tradeoffs is the foundation.

### Linear: f(x) = a·x + b

```
Level:  1    5    10    20    50    100
Value:  10   50   100   200   500   1000

Growth rate: constant (+10 per level)
Relative growth: decreasing (100%, 25%, 11%, 5%, 2%, 1%)
```

**Properties:**
- Easy to understand and predict
- Absolute gains are constant, but perceived gains shrink (Weber-Fechner)
- Late-game upgrades feel trivial compared to early-game
- Total power scales proportionally with level — doubling the level doubles the power

**Best for:** Systems where you want diminishing excitement naturally — resource costs that players "outgrow," enemy stats in the early game, tutorial pacing.

**Problem:** In a 50-level game, the level 50 upgrade feels 50× less impactful than level 1. Players stop caring about individual level-ups long before the cap.

### Polynomial: f(x) = a·x^n

```
Quadratic (n=2):
Level:  1    5    10    20    50    100
Value:  1    25   100   400   2500  10000

Cubic (n=3):
Level:  1    5    10    20    50    100
Value:  1    125  1000  8000  125k  1M
```

**Properties:**
- Growth accelerates but at a controlled rate
- The exponent `n` controls how aggressive the acceleration is
- n=2 (quadratic) is the sweet spot for most games — noticeable acceleration without runaway numbers
- Ratio between consecutive levels approaches 1 as levels increase (like linear) but more slowly

**Best for:** Player HP scaling, enemy HP scaling, XP requirements per level. Quadratic is the workhorse curve of RPG design.

**Why quadratic works:** At level 10, going to 11 is a 21% increase (121/100). At level 50, going to 51 is a 4% increase (2601/2500). The relative gain shrinks, but much more slowly than linear. A level-up still *feels* meaningful at level 50. By level 100, the 2% relative gain is approaching the perception threshold, which is roughly where you want the endgame to flatten.

### Exponential: f(x) = a·b^x

```
b=1.1 (10% per level):
Level:  1    5    10    20    50    100
Value:  1.1  1.6  2.6   6.7   117   13,781

b=1.05 (5% per level):
Level:  1    5    10    20    50    100
Value:  1.05 1.28 1.63  2.65  11.5  131.5
```

**Properties:**
- Constant *relative* growth — every level feels equally impactful (percentage-wise)
- Numbers grow extremely fast — 10% per level reaches 13,000× by level 100
- Even modest bases (1.05) produce large numbers over many levels
- Creates "number inflation" that makes late-game values unreadable

**Best for:** Short progressions (roguelike runs of 10-20 levels), within-run power scaling where you want every upgrade to feel equally exciting, prestige multipliers.

**Problem:** In any game with more than ~30 levels, exponential scaling produces numbers so large they lose meaning. This is why games with hundreds of levels (idle games, some MMOs) use number abbreviation (1.5M, 2.3B) — it's an admission that exponential scaling outran human comprehension.

### Logarithmic: f(x) = a·ln(x) + b

```
Level:  1    5    10    20    50    100
Value:  0    1.6  2.3   3.0   3.9   4.6
```

**Properties:**
- Rapid early gains that flatten dramatically
- Hard ceiling on total growth — going from level 50 to 100 adds less than going from 1 to 5
- Creates natural diminishing returns without explicit caps
- Players feel most progression early, creating a "honeymoon" effect

**Best for:** Diminishing returns on stats that shouldn't scale infinitely (crit chance, damage reduction, movement speed), "mastery" systems where the first few ranks are transformative and later ranks are refinement.

**The asymptotic advantage:** Logarithmic curves naturally prevent any stat from becoming degenerate. If crit chance scales logarithmically with crit rating, no amount of crit rating produces 100% crit. The curve does the cap enforcement for you, without needing a hard cap that players can discover and game around.

---

## 2. Designing XP Curves

The XP-to-next-level curve determines pacing — how long each level takes and how the grind feels over time.

### The Standard Quadratic

Most RPGs and roguelites use a variant of:

```
XP_to_next_level(n) = base × n^exponent

Example (base=100, exponent=1.8):
Level 1→2:   100 XP
Level 5→6:   478 XP
Level 10→11: 1,585 XP
Level 20→21: 5,480 XP
Level 50→51: 25,704 XP
```

**Why exponent 1.5–2.0 works:**
- Below 1.5: Levels come too evenly. There's no acceleration. Players feel like the game "doesn't get harder."
- At 1.8–2.0: Each level takes roughly 1.5–2× as long as the previous few. Progression slows noticeably but not punitively.
- Above 2.5: The late-game grind becomes extreme. Level 50 takes 100× longer than level 10. Players quit before reaching it.

### Coupling XP Curves with XP Sources

The XP curve only matters relative to how much XP the player earns. If enemies at level 50 give 100× more XP than enemies at level 1, even a steep XP curve feels flat (because income scaled to match). The *effective* leveling speed is:

```
Time per level ∝ XP_required(n) / XP_income(n)
```

**Three design patterns:**

1. **Fixed income, scaling requirements.** XP from enemies doesn't change much. The curve alone controls pacing. Simple, but enemies must stay relevant throughout the game (the player fights the same enemies longer, not harder enemies).

2. **Scaling income, steeper requirements.** Enemies scale with zones, giving more XP. The curve must outpace income growth to maintain slow-down. Most common in zone-based games.

3. **Fixed requirements, scaling income.** Every level takes the same XP, but enemies give more. Leveling speed *increases* over time. Used in games that want "power fantasy acceleration" — each level comes faster, the player feels unstoppable. Common in idle games and late-game prestige systems.

### The Level-Duration Table

Before finalizing your XP curve, build a level-duration table:

```
| Level | XP Required | XP/minute (estimated) | Minutes to Level | Cumulative Hours |
|-------|-------------|----------------------|-----------------|-----------------|
| 1→2   | 100         | 50                   | 2               | 0.03            |
| 5→6   | 478         | 80                   | 6               | 0.3             |
| 10→11 | 1,585       | 120                  | 13              | 1.2             |
| 20→21 | 5,480       | 200                  | 27              | 5.5             |
| 50→51 | 25,704      | 500                  | 51              | 28              |
```

If level 50 takes 51 minutes and you expect players to reach level 50, that's fine. If your game expects players to reach level 200 and each level takes 3 hours, you've designed a game that requires 600+ hours. Is that intentional? The level-duration table forces you to answer this question before shipping.

---

## 3. Enemy Scaling Strategies

How enemy stats change across zones/floors determines how the player's power curve *feels*. Even with the same player power curve, different enemy scaling strategies create radically different experiences.

### Strategy 1: Static Enemies, Player Scales Up

Enemies have fixed stats per zone. The player grows stronger through upgrades. Early zones become trivially easy. Late zones are challenging.

```
Zone 1 enemy HP: 100    Player DPS: 50  → TTK: 2.0s
Zone 5 enemy HP: 500    Player DPS: 200 → TTK: 2.5s
Zone 10 enemy HP: 1500  Player DPS: 500 → TTK: 3.0s
```

**Feel:** Power fantasy. Returning to zone 1 at endgame feels incredible. The danger is late-game zones feeling like a wall if the player is underleveled.

**Tuning knob:** The ratio of enemy HP scaling to player DPS scaling. If enemies scale at x^2 and player DPS scales at x^1.5, TTK slowly increases — fights get harder. If both scale at x^2, TTK stays constant.

### Strategy 2: Enemies Scale with Player (Rubber Banding)

Enemies adjust to the player's current power level. The game is always "challenging."

```
Enemy HP = base_hp × (1 + player_level × 0.15)
Enemy DPS = base_dps × (1 + player_level × 0.10)
```

**Feel:** Consistent challenge. Never too easy, never too hard. But upgrades feel meaningless — if the enemies scale up with you, what's the point of leveling?

**The rubber banding problem:** Pure rubber banding kills the power fantasy. The player gets stronger but can't tell. The solution is *partial* rubber banding — enemies scale at 60-80% of the player's rate, so the player always stays slightly ahead.

```
Partial rubber banding:
  Player DPS growth: 10% per level
  Enemy HP growth: 7% per level
  Net advantage per level: ~3%
  After 10 levels: player is ~34% ahead → fights are ~25% faster
```

### Strategy 3: Encounter Composition Scaling

Individual enemy stats stay relatively flat, but *encounter design* scales — more enemies, tougher combinations, environmental hazards, elite frequency.

```
Zone 1: 3 basic enemies per room
Zone 5: 5 enemies per room, 1 elite every 3 rooms
Zone 10: 6 enemies per room, 1 elite per room, mini-boss every 5 rooms
Zone 15: 8 enemies per room with 2 elites, environmental hazards
```

**Feel:** The player feels powerful against individual enemies (power fantasy preserved) but the *situation* becomes more demanding. This is the Hades approach — enemies don't become damage sponges, but the combinations and density increase.

**Tuning knobs:**
- Enemies per encounter
- Elite frequency (every N rooms)
- Boss cadence (every N floors)
- Rest room spacing (every N encounters — the "relief valve")
- Hazard count and type
- Enemy type diversity per encounter

### Strategy 4: Zone-Based Step Functions

Instead of smooth scaling, enemies jump in power at zone boundaries.

```
Zone 1 (floors 1-5):   enemies have 100 HP, deal 10 DPS
Zone 2 (floors 6-10):  enemies have 250 HP, deal 20 DPS  (2.5× / 2×)
Zone 3 (floors 11-15): enemies have 600 HP, deal 35 DPS  (2.4× / 1.75×)
```

**Feel:** Each new zone is a difficulty spike. The player must have upgraded enough to handle the jump. Within a zone, the player feels increasingly powerful. This creates a sawtooth pattern of challenge → mastery → challenge.

**The roguelike standard:** Most roguelikes use a combination of strategies 3 and 4 — step functions at floor/zone boundaries with composition scaling within zones. The step function creates clear "checkpoints" where the player feels the difficulty increase, while composition scaling provides gradual ramp within zones.

---

## 4. Diminishing Returns

When a stat becomes too valuable at high levels — or when you need to prevent a stat from reaching a breakpoint (like 100% crit) — diminishing returns reduce the marginal value of additional investment.

### Soft Cap (Piecewise Linear)

Full value up to a threshold, reduced value above it.

```
If rating ≤ 50:  effective = rating
If rating > 50:  effective = 50 + (rating - 50) × 0.5

Example:
  40 rating → 40 effective (below cap)
  60 rating → 55 effective (10 over cap, halved to 5)
  100 rating → 75 effective (50 over cap, halved to 25)
```

**Pros:** Simple, transparent. Players can learn the cap number and plan around it.
**Cons:** The transition at 50 is abrupt. Players feel "punished" the moment they cross the threshold.

### Hyperbolic (Asymptotic)

Approaches but never reaches a ceiling.

```
effective = max_value × rating / (rating + k)

With max_value = 80%, k = 100:
  20 rating → 13.3%
  50 rating → 26.7%
  100 rating → 40.0%
  200 rating → 53.3%
  500 rating → 66.7%
  ∞ rating  → 80.0% (never reached)
```

**Pros:** Smooth — no abrupt transition. Natural ceiling that's impossible to reach. Each point always has *some* value.
**Cons:** Less transparent to players. Hard to explain "why did my last 50 points only give me 3%?"

**This is the same formula as divisive damage reduction from Module 1** — `DR = armor / (armor + k)`. The pattern shows up everywhere: crit chance from crit rating, dodge chance from agility, cooldown reduction from haste.

### Logarithmic Diminishing Returns

```
effective = a × ln(1 + rating / b)

With a = 20, b = 10:
  10 rating → 13.9
  50 rating → 35.8
  100 rating → 46.1
  200 rating → 60.6
  500 rating → 78.6
```

**Pros:** Smoother than soft cap, more aggressive diminishing than hyperbolic at high values.
**Cons:** No fixed ceiling (unlike hyperbolic) — still grows, just slowly. Can eventually reach unintended values in long games.

### Choosing the Right DR Curve

| Situation | Recommended | Why |
|-----------|-------------|-----|
| Stat must never reach X% | Hyperbolic | Asymptote guarantees it |
| Stat should feel "full" after N points | Soft cap | Clear threshold, players plan for it |
| Stat has no hard limit but should slow down | Logarithmic | Gentle slowdown, no wall |
| Short progression (roguelike run) | None | DR adds complexity without payoff in 20 levels |

---

## 5. Prestige and Reset Curves

Roguelikes and roguelites have a unique scaling challenge: progression happens both within a run (temporary) and across runs (permanent). The relationship between these two progression layers is the prestige curve.

### Within-Run Progression

The player starts at baseline and accumulates power over 15-30 minutes (action roguelike) or 30-90 minutes (traditional roguelike). The curve should feel like:

```
Power relative to baseline:
  Start:    1.0×
  25% run:  1.5–2.0×
  50% run:  2.5–4.0×
  75% run:  4.0–8.0×
  End:      6.0–15.0×
```

This is roughly exponential within a single run, which is fine because runs are short. The "10× power from start to finish" target is common in the genre — the player should feel dramatically more powerful by the end.

**Tuning the within-run curve:**

```
Average budget per upgrade: B
Number of upgrades per run: N
Target end-power: T × starting_power

If upgrades are additive:
  T = 1 + (N × B) / base_power

If upgrades are multiplicative:
  T = (1 + B/base_power)^N

For 20 additive upgrades to reach 5× power:
  B = (5 - 1) × base_power / 20 = 0.2 × base_power per upgrade

For 20 multiplicative upgrades to reach 5× power:
  (1 + B/base_power)^20 = 5
  B/base_power = 5^(1/20) - 1 ≈ 0.083 → 8.3% per upgrade
```

### Cross-Run (Meta) Progression

Permanent upgrades that carry across runs. These multiply or add to the within-run baseline. The design tension: too much meta-progression trivializes early content. Too little makes runs feel identical.

**Common meta-progression structures:**

1. **Flat bonuses to base stats.** +5 max HP, +2 base attack per meta-upgrade. Simple, additive. The first few meta-upgrades are impactful; later ones are marginal (linear scaling against a growing base).

2. **Percentage multipliers.** +10% starting HP, +5% damage per meta-upgrade. Maintains impact longer than flat bonuses. But compounds: 20 meta-upgrades of +5% damage = 2.65× damage. The game must expect this.

3. **Unlocks rather than power.** New upgrade options, new characters, new abilities — but no direct stat increases. Keeps run 1 and run 100 at the same difficulty. Used by Spelunky, FTL, and games that prioritize skill progression over stat progression.

4. **The hybrid model (Hades-like).** Permanent upgrades exist but are bounded. There's a maximum number of meta-upgrades, and after purchasing all of them, the player has a modest advantage (maybe 1.5–2× baseline). The real progression is skill + build knowledge. The meta-upgrades smooth the learning curve, not remove the challenge.

### Prestige Math

If meta-upgrades multiply the within-run baseline:

```
Effective power = meta_multiplier × within_run_multiplier

With meta = 2× (fully upgraded) and within_run_end = 8×:
  Run end power = 16× baseline

Compare to a new player:
  Run end power = 1× × 8× = 8× baseline

The veteran is 2× stronger — noticeable but not game-breaking.
```

**The danger zone:** If meta-progression is unbounded, veterans reach 50× baseline and the game can't challenge them without making it impossible for new players. This is the core problem of idle games and "infinite prestige" systems.

**Rule of thumb for roguelites:** Cap meta-progression at 1.5–3× the new-player baseline. The difficulty system (heat, ascension, etc.) should outpace meta-progression, so veterans *choose* harder challenges rather than coasting on accumulated power.

---

## 6. Encounter Pacing as a Curve

Beyond individual enemy scaling, the *rhythm* of encounters over a run or zone follows its own curve. This pacing curve affects tension, resource management, and player fatigue.

### The Sawtooth Pattern

Most roguelikes follow a sawtooth pattern within each zone:

```
Tension
  ▲
  │    /\      /\       /\
  │   /  \    /  \     /  \
  │  /    \  /    \   /    \
  │ /      \/      \ /      \
  └────────────────────────── Rooms
  │  encounters │ rest │ encounters │ boss │
```

- **Rising tension:** Consecutive combat rooms drain resources (HP, ammo, cooldowns)
- **Relief:** Shop/rest rooms restore some resources and let the player upgrade
- **Climax:** Boss fight tests the player's accumulated power and remaining resources
- **Reset:** New zone starts with fresh encounter budget

### Pacing Variables

```
Encounters per zone: 8–15 (varies by genre)
Rest rooms per zone: 1–3 (every 3–5 encounters)
Elites per zone: 1–3 (mid-zone challenge spike)
Boss per zone: 1 (zone finale)

Resource drain per encounter: 5–15% of max HP (without healing)
Resource restore per rest: 20–40% of max HP

Math check:
  8 encounters × 10% drain = 80% HP lost
  2 rest rooms × 30% restore = 60% HP restored
  Net drain entering boss: 20% HP lost → player has ~80% HP
  → Boss fight starts with the player slightly weakened but not desperate
```

### Elite and Boss Cadence

Elites serve as mid-zone difficulty spikes that test whether the player's build is on track. Their placement follows a pattern:

```
Zone 1 (learning):    No elites, easy boss
Zone 2 (first test):  1 elite at room 5/8, moderate boss
Zone 3 (escalation):  2 elites at rooms 4 and 7/10, hard boss
Zone 4 (endgame):     3 elites mixed in, brutal boss

Elite stat multiplier: 2–4× base enemy of same zone
Boss stat multiplier:  5–10× base enemy of same zone
```

**Boss health pools and the "3-phase" pattern:**

Many roguelikes structure bosses in phases. Each phase is a difficulty check:

```
Boss total HP: 10,000
Phase 1 (0-40%):   Basic attack patterns, tests DPS
Phase 2 (40-75%):  Adds mechanics, tests adaptation
Phase 3 (75-100%): Enrage or desperation, tests survival + DPS

Player needs ~120 DPS to clear the boss in the expected time
Player with 80 DPS can clear phases 1-2 but will timeout/die in phase 3
→ Phase 3 is the DPS check
```

---

## 7. Building Piecewise Curves

In practice, no single curve family works for an entire game. Real progression systems are **piecewise** — different curves stitched together at transition points.

### Example: Hybrid Player Power Curve

```
Levels 1-10 (tutorial):   Linear, steep slope → fast, predictable gains
Levels 11-30 (core game): Quadratic (n=1.8) → accelerating but manageable
Levels 31-50 (endgame):   Logarithmic → flattening, approaching asymptote
```

**Implementation:**

```
function power(level):
  if level <= 10:
    return 10 + level × 5                    // Linear: 15 at level 1, 60 at level 10
  else if level <= 30:
    base = 60                                 // Match endpoint of previous segment
    return base + 2.5 × (level - 10)^1.8     // Quadratic from offset
  else:
    base = power(30)                          // Match endpoint of previous segment
    return base + 80 × ln((level - 29) / 1)  // Logarithmic to cap
```

**The key rule:** At every transition point, the value and ideally the derivative (slope) should be continuous. If level 10 gives 60 power and level 11 gives 62, the transition is smooth. If level 10 gives 60 and level 11 gives 45 because you switched to a new formula, the player feels robbed.

### Tuning Piecewise Curves

1. **Define the endpoints.** Level 1 power = X. Max level power = Y. These are design constraints.
2. **Define the phases.** How many phases? Where do they transition? What's the intended feel of each phase?
3. **Choose a curve family for each phase.** Linear for tutorial, polynomial for core, logarithmic for endgame.
4. **Solve for continuity at boundaries.** Each phase must start where the previous one ended.
5. **Playtest the transitions.** Even mathematically smooth transitions can feel abrupt if the *rate of change* shifts dramatically. If your tutorial is +5 per level and your core game is +0.5 per level, the player notices the slowdown even if the curve is continuous.

---

## Exercises

### Exercise 1: Curve Comparison

Plot (by hand or in a spreadsheet) the following four curves for levels 1-50:
- Linear: f(x) = 10x
- Quadratic: f(x) = 0.5x²
- Exponential: f(x) = 10 × 1.08^x
- Logarithmic: f(x) = 100 × ln(x)

For each curve:
1. What is the value at level 10, 25, and 50?
2. What is the relative gain from level 24 → 25 (percentage increase)?
3. At what level does the exponential exceed the quadratic?
4. At what level would a player stop noticing individual level-ups (relative gain < 5%)?

### Exercise 2: XP Curve Design

Design an XP curve for a 30-level roguelite where:
- Level 1→2 takes 30 seconds of gameplay
- Level 15→16 takes about 3 minutes
- Level 29→30 takes about 8 minutes
- Total time to max level: approximately 90 minutes

1. Choose a curve formula and solve for its parameters
2. Build the full level-duration table
3. Calculate cumulative time at each level
4. Verify the total matches your 90-minute target (±10%)

### Exercise 3: Enemy Scaling

You're building a 5-zone roguelike. Player DPS at the start of each zone (after upgrades):
- Zone 1: 50, Zone 2: 120, Zone 3: 250, Zone 4: 500, Zone 5: 900

Design enemy HP values such that:
1. Base enemy TTK is 2 seconds in zone 1, rising to 3 seconds in zone 5
2. Elite TTK is 8 seconds (constant across zones)
3. Boss TTK is 30 seconds (zone 1) scaling to 45 seconds (zone 5)

Show your enemy HP table and verify the TTK targets.

### Exercise 4: Prestige System

Design a meta-progression system for a roguelike with 10 permanent upgrades. Requirements:
1. A new player completes a run with ~6× base power
2. A fully upgraded player completes a run with ~10× base power
3. Meta-progression accounts for no more than 40% of total end-run power
4. Each meta-upgrade should feel impactful (at least +5% total power)

Define the 10 upgrades, their costs, and their cumulative effect on run power. Verify the math.

---

## Further Reading

- **"Balancing Exponential Growth" in idle game design** — idle/incremental game designers are the world experts on managing exponential curves. Search for posts on r/incremental_games about "soft cap," "prestige math," and "number scaling."
- **"The Compounding Problem" by Riot Games** — Riot has published analyses of how multiplicative scaling creates balance challenges in League of Legends. The same math applies to roguelikes.
- **"Tuning the Difficulty Curve" GDC talks** — search for talks on difficulty pacing. The sawtooth tension model appears in talks by Supergiant (Hades), MegaCrit (Slay the Spire), and others.
- **[Module 0: The Math of Balance](module-00-the-math-of-balance.md)** — Weber-Fechner Law explains why exponential curves "feel" linear and linear curves feel flattening.
- **[Game Design Theory Module 6: Difficulty & Challenge](../game-design-theory/module-06-difficulty-challenge-fairness.md)** — covers the player experience of difficulty curves. This module provides the math underneath.
