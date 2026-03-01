# Module 2: Power Budgets & Stat Allocation

**Part of:** [Game Balance Learning Roadmap](game-balance-roadmap.md)
**Estimated study time:** 3–4 hours
**Prerequisites:** [Module 1: Damage Formulas & DPS Modeling](module-01-damage-formulas-and-dps-modeling.md)

---

## Overview

When a designer says "this item is too strong," what do they mean? Compared to what? A power budget is a system for quantifying "how strong" — assigning a numeric power value to every item, upgrade, enemy, and ability so that "too strong" has a specific, measurable definition. Without a budget, balance is subjective ("this feels overpowered"). With a budget, balance is auditable ("this common item has 145 budget points — 45% over the tier cap").

The power budget concept comes from tabletop RPG design, where designers have used "gold piece equivalent" systems for decades. Digital game designers apply the same idea: derive the DPS or survivability value of each stat, convert all stats to a common currency (budget points), and set budget caps per item tier. If every item in a tier hits its budget target, the items are balanced relative to each other — even if they allocate stats completely differently.

This module covers deriving stat weights from your damage formula, building a budget system, applying budgets to item tiers and equipment slots, detecting power creep, and designing intentional budget violations for exciting chase items.

---

## 1. Stat Weighting — The Common Currency

Different stats contribute differently to a character's effectiveness. +1 Attack might add 1.5 DPS. +1% Crit Chance might add 0.8 DPS. +1 Defense might add 15 eHP. To compare them, you need to convert everything to a common currency.

**Step 1: Define your baseline character.**

```
Base Stats:
  Attack:         30
  Attack Speed:   1.2 hits/sec
  Crit Chance:    10%
  Crit Multiplier: 2.0×
  HP:             400
  Defense:        20 (k=100)
```

**Step 2: Calculate baseline effectiveness.**

```
Crit factor = 1 + 0.10 × (2.0 - 1) = 1.10
Base DPS = 30 × 1.10 × 1.2 = 39.6
Base eHP = 400 × (1 + 20/100) = 480
```

**Step 3: Calculate the marginal value of +1 of each stat.**

Add +1 to each stat and measure the change:

```
+1 Attack:      DPS = 31 × 1.10 × 1.2 = 40.92    → +1.32 DPS
+1% Crit:       DPS = 30 × 1.11 × 1.2 = 39.96    → +0.36 DPS
+0.1 Speed:     DPS = 30 × 1.10 × 1.3 = 42.90    → +3.30 DPS
+1 Defense:     eHP = 400 × (1 + 21/100) = 484    → +4 eHP
+1 HP:          eHP = 401 × (1 + 20/100) = 481.2  → +1.2 eHP
```

**Step 4: Choose a budget unit.**

Pick the stat with the smallest impact as your unit. Here, +1% Crit = +0.36 DPS is smallest.

```
1 budget point = +0.36 DPS

Stat weights:
  +1 Attack      = 1.32 / 0.36 ≈ 3.7 budget points
  +1% Crit       = 0.36 / 0.36 = 1.0 budget point
  +0.1 Speed     = 3.30 / 0.36 ≈ 9.2 budget points
  +1 Defense     → separate survivability budget (see below)
  +1 HP          → separate survivability budget
```

**The offense/defense split:**

DPS and eHP are different currencies. You can't directly compare them — "is 1 DPS worth more than 1 eHP?" is a design question, not a math one. Two approaches:

1. **Separate budgets.** Offensive budget (DPS-weighted) and defensive budget (eHP-weighted) tracked independently. Each item has both. Simpler and more transparent.

2. **Unified budget via TTK.** Define "1 budget point = 1% faster kill in the standard encounter." Both DPS and survivability contribute to killing faster (DPS directly, survivability by surviving long enough to deal damage). More complex but creates a single budget number.

For most roguelikes, **separate budgets** are cleaner. An offensive item's power comes from DPS. A defensive item's power comes from eHP. Hybrid items split their budget between both.

---

## 2. Building the Budget System

Once you have stat weights, you can assign a total budget to any game element.

### Item Budget Example

```
Common Sword:
  +8 Attack (8 × 3.7 = 29.6 budget)
  +3% Crit  (3 × 1.0 = 3.0 budget)
  Total: 32.6 offensive budget

Common Shield:
  +50 HP   (50 × eHP_weight)
  +8 Defense (8 × eHP_weight)
  Total: [defensive budget]

Rare Sword:
  +14 Attack (14 × 3.7 = 51.8 budget)
  +5% Crit   (5 × 1.0 = 5.0 budget)
  +0.1 Speed  (1 × 9.2 = 9.2 budget)
  Total: 66.0 offensive budget
```

### Defining Tier Budgets

Set a budget range for each rarity tier:

```
Tier Budget Ranges (offensive):
  Common:    25 – 40
  Uncommon:  40 – 60
  Rare:      60 – 85
  Epic:      85 – 120
  Legendary: 120 – 180
```

The ranges overlap slightly by design — a high-end Common and a low-end Uncommon can be close in power, which prevents "always discard anything from a lower tier."

**Budget ratios between tiers:**

A clean pattern is 1.5× per tier:

```
Common:    30 (base)
Uncommon:  45 (1.5×)
Rare:      67 (1.5²×)
Epic:      101 (1.5³×)
Legendary: 151 (1.5⁴×)
```

The 1.5× ratio means upgrading from one tier to the next always feels meaningful (50% power increase), which aligns with Weber-Fechner (Module 0) — players perceive ratio changes, and 1.5× is above the "noticeable" threshold.

---

## 3. Slot Budgets and Equipment Systems

Different equipment slots should have different budgets. A weapon is the primary source of attack — it should have the largest offensive budget. Boots might contribute movement speed and minor defensive stats — smaller budget.

### Slot Budget Distribution

Decide what percentage of total character power comes from each slot:

```
Total equipment budget: 300 (at Common tier)

Weapon:     35% → 105 budget (primary offense)
Armor:      25% →  75 budget (primary defense)
Helmet:     15% →  45 budget (secondary defense)
Boots:      10% →  30 budget (utility/speed)
Accessory:  15% →  45 budget (flexible)
Total:     100% → 300 budget
```

**Why this matters:** If you assign budgets to items without considering slots, you might create a boot that's stronger than most weapons. Slot budgets ensure each piece of gear has a defined role.

### Roguelike Upgrade Budgets

In roguelikes without traditional equipment, upgrades (boons, cards, relics) serve the same role. Each upgrade has a budget based on its rarity:

```
Roguelike upgrade budgets:
  Common upgrade:   15 – 25 budget
  Rare upgrade:     30 – 45 budget
  Legendary upgrade: 50 – 80 budget

Expected upgrades per run: 15–20
Expected total budget:     ~400–600

Power curve target: start at 100% base power, end at 300–500% base power
```

The total budget across all upgrades determines the player's power ceiling. If you offer too many high-budget upgrades, the player reaches 1,000% base power and trivializes the final boss.

---

## 4. Stat Weights Change Over Time

Stat weights aren't constant — they shift as the character's stats change. This is critical and often overlooked.

**Example: Crit chance scaling**

At 10% base crit, +1% crit adds:
```
DPS change = base × 0.01 × (crit_multi - 1) × speed = 30 × 0.01 × 1.0 × 1.2 = 0.36
```

At 50% base crit, +1% crit adds the same absolute DPS — but relative to the now-higher base DPS, it's worth proportionally less. Meanwhile, +1 Attack at 50% crit is now boosted by the higher crit rate:
```
DPS change = 1 × (1 + 0.50 × 1.0) × 1.2 = 1.80 DPS (was 1.32 at 10% crit)
```

**The implication:** Early in a run, crit upgrades might be the best investment. Late in a run, after stacking crit, flat attack becomes more efficient. Stats that multiply other stats become more valuable as the stats they multiply increase.

**How to handle this:**

1. **Recalculate weights at key progression points.** Check stat weights at "early game" (base stats), "mid game" (after ~50% of upgrades), and "late game" (near-cap stats). If a stat's weight changes by more than 2× across the game, it needs attention.

2. **Design for interaction.** The fact that crit and attack multiply each other is a *feature* in roguelikes. It creates the satisfying realization that "I should take attack upgrades now because I already have high crit." If stat weights never changed, there'd be no build optimization beyond the first choice.

3. **Set diminishing returns where needed.** If a stat becomes too valuable at high levels, add explicit diminishing returns — a soft cap that reduces the marginal value beyond a threshold. See Module 3 for the math.

---

## 5. Power Creep Detection

**Power creep** is when newly added content is systematically more powerful than existing content. It happens gradually — each new item is "just a little" stronger than the average — until the old content is obsolete.

### Quantifying Power Creep

With a budget system, detection is straightforward:

```
For each new item:
  1. Calculate its budget
  2. Compare against the tier average
  3. Flag if > 10% above the tier's median budget

Average Common weapon budget: 33
New Common weapon budget: 42
Overbudget: (42 - 33) / 33 = 27% → FLAGGED
```

### Tracking Budget Drift

Maintain a spreadsheet or database with every item's budget. Plot average budget over time (by release date or patch version). If the line trends upward, you have power creep.

```
Patch 1.0 Common avg budget: 30
Patch 1.1 Common avg budget: 32
Patch 1.2 Common avg budget: 35
Patch 1.3 Common avg budget: 39  ← 30% creep over 3 patches
```

### Power Creep Prevention

- **Budget reviews.** Every new item goes through a budget check before shipping. If it's overbudget, the designer must justify the violation or reduce the stats.
- **Anchor items.** Designate 2–3 items per tier as "anchors" that define the expected power level. New items are compared against anchors, not against the most recent additions (which may themselves be crept).
- **Periodic rebalance.** Every few patches, audit the full item set. If the average budget has drifted, either nerf outliers or buff underperformers. Nerfs are more effective at controlling creep but less popular with players.

---

## 6. Intentional Budget Violations

Not everything should be on-budget. The most exciting items in any game are the ones that break the rules — that feel impossibly powerful. The key is that these violations are **intentional, bounded, and earned.**

### When to Violate the Budget

- **Legendaries and uniques.** A legendary weapon that's just "more stats" than a rare weapon is boring. A legendary that breaks a specific rule — "crits deal 4× damage instead of 2×" — creates build-defining moments. The violation is in one specific dimension, not across all stats.
- **Set bonuses.** Individual set pieces are on-budget. The set bonus is a "free" power injection that rewards committing to a theme. The total power of a complete set should exceed what mixing-and-matching provides — that's the incentive.
- **Build synergies.** Two upgrades that are on-budget individually but combine for exponential value. "Attacks have +20% chance to burn" (on-budget) + "Deal +50% damage to burning enemies" (on-budget) = combined, they're massively overbudget. This is desirable — it rewards build planning. Module 4 covers synergy design in depth.
- **Boss drops / run rewards.** An end-of-run reward that's 50% overbudget feels earned. The player beat the boss — they deserve something that feels broken.

### Bounding the Violation

Unlimited violations destroy balance. Rules for keeping violations exciting but not game-breaking:

1. **Constrain the dimension.** An overbudget weapon shouldn't be best at everything — it should be best at one thing and average or below at others. "Insane crit damage but slow attack speed" creates a tradeoff.
2. **Limit availability.** If every player gets the broken item, it becomes the baseline. If 10% of runs feature it, it's a memorable highlight.
3. **Create counterplay.** In a game with enemy diversity, an overbudget fire weapon is countered by fire-resistant enemies. The violation works in some contexts but not all.
4. **Budget the violation itself.** If a legendary is 60% overbudget, plan for it. Your boss fights should assume the player might have one legendary-tier item, not three.

---

## 7. The Budget Spreadsheet

Every game with items needs a budget spreadsheet. Here's the structure:

| Item Name    | Tier      | Slot    | Attack | Crit% | Speed | HP  | Def | Off Budget | Def Budget | Over? |
|-------------|-----------|---------|--------|-------|-------|-----|-----|-----------|-----------|-------|
| Iron Sword  | Common    | Weapon  | 8      | 3     | —     | —   | —   | 32.6      | —         | No    |
| Steel Sword | Uncommon  | Weapon  | 14     | 5     | 0.1   | —   | —   | 66.0      | —         | No    |
| Fire Blade  | Rare      | Weapon  | 16     | 8     | 0.1   | —   | —   | 76.4      | —         | No    |
| Excalibur   | Legendary | Weapon  | 25     | 15    | 0.3   | —   | —   | 135.2     | —         | Yes*  |

*Intentional violation: legendary with build-defining crit synergy.

**Maintaining the spreadsheet:**
- Update it before finalizing any new item
- Sort by tier and compare within-tier budgets
- Flag anything > 10% above tier median as needing review
- Chart budget distribution per tier to spot outliers visually

---

## Exercises

### Exercise 1: Derive Stat Weights

Given a baseline character:
- Attack: 25, Speed: 1.0/sec, Crit: 5%, CritMulti: 2×, HP: 350, Defense: 15, k=100

Calculate:
1. Baseline DPS and eHP
2. The DPS gain from +1 Attack, +1% Crit, +0.1 Speed
3. The eHP gain from +10 HP, +5 Defense
4. Express all stats in budget points (choose your unit)

### Exercise 2: Build a Tier System

Using the stat weights from Exercise 1, design 3 tiers:
- Common: 3 weapons, 3 armor pieces
- Rare: 2 weapons, 2 armor pieces
- Legendary: 1 weapon, 1 armor piece

Requirements:
1. All items within a tier should have budgets within ±15% of the tier target
2. Each item should have a different stat allocation (no two items are just "more attack")
3. The legendary weapon should intentionally violate the budget in one dimension — document why

### Exercise 3: Power Creep Audit

You've shipped 10 Common weapons. Their offensive budgets are: 28, 30, 31, 32, 29, 33, 35, 34, 37, 38.

1. Calculate the average budget over time (first 5 vs. last 5)
2. Is there power creep? Quantify it.
3. If you were to add an 11th weapon, what budget should it have?
4. Propose a rebalance: which weapons need adjustment, and by how much?

### Exercise 4: Roguelike Run Budget

Design a 20-upgrade roguelike run with 3 tiers of upgrades (Common/Rare/Legendary). The player receives 12 Common, 6 Rare, and 2 Legendary upgrades over the run.

1. Set budget targets per tier so that total run power is ~4× the starting power
2. Create 5 Common upgrades, 3 Rare upgrades, and 2 Legendary upgrades with specific stat allocations
3. Verify the total budget of a typical run (12C + 6R + 2L) hits your 4× target
4. What happens if the player gets lucky and receives 8 Rare + 4 Legendary instead? How overbudget are they?

---

## Further Reading

- **"Item Budget Systems" in Diablo-style games** — search for community analyses of Diablo 2/3/4 itemization. The budget concept originated here and has been refined over decades.
- **"Stat Weights" from WoW/FFXIV theorycrafting** — these communities have built sophisticated tools (SimulationCraft, XIVAnalysis) that automatically derive stat weights for different builds. The methodology is the same as Section 1.
- **"Power Budget" GDC talks** — search for talks by Riot, Blizzard, or indie developers on power budgeting. The terminology varies but the concept is universal.
- **"The Lens of Balance" from "The Art of Game Design" by Jesse Schell** — covers balance from a designer's perspective, including the role of quantifiable systems.
- **[Game Design Theory Module 5: Economy](../game-design-theory/module-05-game-economy-resource-design.md)** — covers sources, sinks, and opportunity cost at a conceptual level. Power budgets are the quantitative implementation.
