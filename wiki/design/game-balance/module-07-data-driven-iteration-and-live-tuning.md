# Module 7: Data-Driven Iteration & Live Tuning

**Part of:** [Game Balance Learning Roadmap](game-balance-roadmap.md)
**Estimated study time:** 3–4 hours
**Prerequisites:** All previous modules (capstone)

---

## Overview

Everything in Modules 0–6 is pre-launch theory. You build damage formulas, set power budgets, design curves, validate with simulation — and then real players arrive and immediately find a build you never considered, skip a system you thought was essential, and declare the "balanced" boss either trivially easy or impossibly hard. Pre-launch work gets you to 80% of good balance. The remaining 20% requires data from real players.

This module covers the discipline of data-driven balance: what telemetry to collect, how to build dashboards that surface problems, how to structure balance patches, and how to iterate without introducing new problems. It's the capstone because it ties every previous module together — you need damage formulas to interpret combat data, power budgets to evaluate items, scaling curves to understand progression data, and simulation to validate proposed changes before shipping them.

---

## 1. Telemetry Design — What to Track

Every interaction in your game generates data. The challenge isn't collecting data — it's collecting the *right* data. Too little, and you can't diagnose problems. Too much, and you drown in noise.

### The Essential Events

These are the minimum events every game with balance concerns should track:

```
Event: run_start
Data: player_id, timestamp, meta_progression_level, selected_character

Event: upgrade_offered
Data: run_id, floor, upgrades_offered[], upgrade_chosen, player_stats_snapshot

Event: upgrade_skipped (if the player can skip)
Data: run_id, floor, upgrades_offered[]

Event: encounter_complete
Data: run_id, floor, enemy_types[], duration_seconds, damage_dealt,
      damage_taken, abilities_used[], player_hp_remaining

Event: boss_fight_complete
Data: run_id, floor, boss_id, duration_seconds, damage_dealt,
      damage_taken, phases_reached, player_hp_remaining, result (win/loss)

Event: run_end
Data: run_id, result (win/loss/abandon), floor_reached, total_duration,
      final_stats_snapshot, upgrades_collected[], cause_of_death (if loss)
```

### Derived Metrics

Raw events become useful when aggregated into metrics:

```
Win rate:        count(run_end where result=win) / count(run_end)
Abandon rate:    count(run_end where result=abandon) / count(run_end)
Avg run duration: mean(total_duration where result=win)
Death floor distribution: histogram of floor_reached where result=loss
Upgrade pick rate: count(chosen=X) / count(offered contains X) for each upgrade
Boss clear rate: count(boss result=win) / count(boss result=any) per boss
DPS at floor N:  median(damage_dealt / duration) at floor N
```

### What NOT to Track

- **Frame-level data.** Input timing, exact positions, animation states. These are useful for game feel analysis but not balance. They're also extremely expensive to store.
- **Pre-aggregated summaries.** Don't send "average DPS per run" — send individual encounter data and aggregate later. Pre-aggregation hides distribution information.
- **PII or unnecessary player identifiers.** You need player IDs for session tracking but not real names, emails, or device info (unless you're doing device-specific performance analysis).

---

## 2. The Five Essential Charts

You could build hundreds of dashboards. Start with these five. They surface 90% of balance problems.

### Chart 1: Win Rate Over Time

```
X-axis: Date (or patch version)
Y-axis: Win rate (%)
Lines: Overall, per-character, per-difficulty

What it tells you:
  - Trending upward: players are getting better, or recent patches made it easier
  - Trending downward: something is frustrating players, or a buff target was nerfed too hard
  - Sudden spike: exploit discovered, or a patch broke something
  - Steady at target: balance is stable — don't touch it

Red flags:
  - Win rate above 80%: game is too easy for the population
  - Win rate below 15%: game is too hard, only hardcore players persist
  - One character at 70%, another at 25%: character imbalance
```

### Chart 2: Upgrade Pick Rates

```
X-axis: Upgrade name (sorted by pick rate)
Y-axis: Pick rate (%) — how often it's chosen when offered

What it tells you:
  - Flat distribution (~3-5% each for 30 upgrades): healthy variety
  - One upgrade at 25%+: dominant option, probably overbudget
  - Five upgrades below 1%: dead options, clutter the pool
  - Cluster of similar upgrades all at low rates: redundant design

This is the single most actionable chart. It directly maps to power budget violations.
```

### Chart 3: Death Floor Distribution

```
X-axis: Floor number
Y-axis: Percentage of deaths occurring on this floor

What it tells you:
  - Spike at a specific floor: difficulty spike — often a boss or new enemy type
  - Deaths concentrated in first 3 floors: early game is too punishing
  - Deaths spread evenly: difficulty is smooth (possibly too uniformly hard)
  - No deaths after floor 10: late game is trivially easy

Target: A gentle rightward skew. Most deaths in mid-to-late floors, fewer in early floors.
The final boss should account for 15-30% of deaths.
```

### Chart 4: Power Curve (DPS/eHP at Each Floor)

```
X-axis: Floor number
Y-axis: Median player DPS (with 25th/75th percentile bands)

What it tells you:
  - Band too wide: high variance in upgrade quality or availability
  - Band narrowing: convergent builds (everyone picks the same things)
  - Curve flattening early: upgrades aren't impactful enough
  - Curve exploding: multiplicative scaling is unchecked

Compare against your designed power curve (Module 3).
If the actual curve diverges from the designed curve, find out why.
```

### Chart 5: Build Archetype Distribution

```
X-axis: Build archetype (classified by primary upgrade cluster)
Y-axis: Percentage of runs using this archetype

What it tells you:
  - One archetype at 50%+: dominant strategy, build diversity has collapsed
  - All archetypes at 10-15% each: healthy diversity
  - An archetype at <3%: non-viable, needs buff or redesign
  - Win rate per archetype (color-coded): shows which archetypes succeed

This requires classifying runs into archetypes post-hoc. Simple approach:
  "If >40% of chosen upgrades are fire-themed, classify as Fire build."
```

---

## 3. Knob-Based Tuning

Balance changes should feel like turning knobs, not rewriting systems. Every tunable parameter in your game is a knob. Good architecture exposes the right knobs; bad architecture buries them in code.

### Identifying Your Knobs

```
Global knobs (affect everything):
  - Base player stats (HP, attack, defense)
  - Global damage multiplier
  - Global enemy HP multiplier
  - Upgrade budget scaling factor

Per-element knobs (affect one thing):
  - Specific upgrade values (+X attack, +Y% crit)
  - Specific enemy stats
  - Specific boss phase durations
  - Drop rates per tier

Meta knobs (affect system behavior):
  - Offering algorithm weights
  - Pity timer thresholds
  - Rarity distribution per floor
  - Rest room frequency
```

### The Knob Hierarchy

When you need to adjust difficulty, move through knobs from least disruptive to most disruptive:

```
Level 1 (numbers only):
  Adjust a specific value — boss HP, upgrade damage, drop rate.
  Impact: targeted. Side effects: minimal.
  Example: "Boss 3 HP: 8000 → 7200"

Level 2 (tier-wide):
  Adjust all values in a tier — all Rare upgrade budgets, all zone 3 enemies.
  Impact: moderate. Side effects: changes relative balance within tier.
  Example: "All Rare upgrade budgets: +10%"

Level 3 (system-wide):
  Adjust a global multiplier — all enemy HP, all player damage, upgrade frequency.
  Impact: broad. Side effects: changes the game's fundamental feel.
  Example: "Global enemy HP: ×0.9"

Level 4 (structural):
  Change game rules — add a new upgrade tier, change how stacking works,
  redesign a boss fight.
  Impact: massive. Side effects: unpredictable, requires re-simulation.
  Example: "Add healing items between floors"
```

**Rule:** Always try Level 1 before Level 2, Level 2 before Level 3, and so on. The minimum effective intervention is the best one.

### Data-Driven Knob Adjustment

```
Problem: Boss 3 has 35% clear rate (target: 55%).

Step 1: Look at the data.
  - Median DPS at boss 3: 150
  - Boss 3 HP: 12,000
  - Median fight duration: 80 seconds
  - Boss DPS to player: 45
  - Player median HP at boss entry: 380

Step 2: Diagnose.
  - Player kills boss in 80s. Boss kills player in 380/45 = 8.4s.
  Wait — that doesn't match the 35% clear rate.
  - Check: boss has phases. Phase 3 deals 90 DPS (double normal).
  - Players die in phase 3. Boss enters phase 3 at 25% HP = 3000 HP.
  - Time in phase 3: 3000 / 150 = 20s. Player takes 90 × 20 = 1800 damage.
  - 1800 damage >> 380 HP. Only players with high HP or lifesteal survive.

Step 3: Adjust (Level 1 knob).
  - Reduce phase 3 boss DPS from 90 to 65.
  - New damage in phase 3: 65 × 20 = 1300. Still deadly, but survivable
    for players with >300 HP (median is 380).

Step 4: Validate with simulation, then ship.
```

---

## 4. The 10% Rule

When adjusting values, the **10% rule** provides a guardrail: never change a value by more than 10-15% in a single patch. Larger changes overshoot, and each overshoot requires another correction, creating a pendulum of nerfs and buffs.

### Why 10%

```
Problem: An upgrade is too strong (picked 35%, should be ~8%).

Tempting: Nerf it by 50%. "It's way too strong, cut it in half."
Reality: After a 50% nerf, it drops to 2% pick rate. Now it's dead.
         Players who relied on it are frustrated. You've created a new problem.

Better: Nerf by 15%. Pick rate drops to ~20%. Still popular but less dominant.
Next patch: If still over target, nerf another 10%. Pick rate drops to ~12%.
Next patch: Close to target. Maybe one more 5% adjustment.

Total nerfs: 3 patches of small changes, arriving at the right spot.
Time: 3 weeks instead of the whiplash of halving and then buffing back.
```

### When to Break the 10% Rule

- **Exploits.** If an interaction is so broken it ruins the game (infinite damage loop, softlock), fix it immediately regardless of magnitude.
- **New content is wildly off.** If a new item shipped at 3× the intended budget (missed the review process), a large correction is warranted because players haven't yet formed habits around it.
- **Dead on arrival.** If a new feature has 0% pick rate and clearly doesn't work, a large buff is fine because no one was using it anyway.

---

## 5. Archetype Testing

Before each balance patch, test changes against build archetypes to ensure you're not accidentally killing a playstyle.

### The Archetype Roster

Maintain a list of 6-10 "representative builds" that span your game's build diversity. For each build, define:

```
Build: "Fire Crit"
  Core upgrades: Flame Strike, Crit Damage+, Burn Duration, Ember Proc
  Primary stat: Crit damage, fire damage
  Weakness: Ice-resistant enemies
  Target win rate: 45-55%
  Current win rate: 52% (healthy)
```

### Pre-Patch Simulation

Before shipping a balance patch, simulate all archetype builds with the proposed changes:

| Archetype    | Win Rate (pre) | Win Rate (post) | Change | Status    |
|-------------|----------------|-----------------|--------|-----------|
| Fire Crit   | 52%            | 48%             | -4%    | OK        |
| Tank        | 48%            | 47%             | -1%    | OK        |
| Speed DoT   | 55%            | 42%             | -13%   | WARNING   |
| Summoner    | 38%            | 35%             | -3%    | LOW (pre) |
| Lifesteal   | 62%            | 51%             | -11%   | Intended  |

**Speed DoT dropped 13% — why?** The patch nerfed a generic "damage over time" upgrade. It was targeted at Lifesteal builds (which were dominant), but Speed DoT relied on it too. Solution: nerf the Lifesteal-specific interaction (lifesteal + DoT) rather than DoT generically.

**Summoner was already low at 38%** — any nerf-oriented patch risks pushing it to unviable. Either buff Summoner in the same patch or ensure the changes don't affect it.

---

## 6. Edge Case Hunting

Real players find combinations that simulation and archetype testing miss. Edge case hunting is a structured approach to finding them proactively.

### Common Edge Case Categories

**1. Multiplicative stacking.** Any time three or more multipliers can stack, check the extreme case.

```
Example: +50% damage × +40% crit damage × +30% attack speed
  Individual: each is a moderate buff
  Combined: 1.5 × 1.4 × 1.3 = 2.73× DPS
  Add a 4th multiplier (+25% elemental): 2.73 × 1.25 = 3.41× DPS
  Is 3.41× achievable in a normal run? If yes, is it too strong?
```

**2. Interaction loopholes.** Two systems that interact in unintended ways.

```
Example: "Heal 5% of damage dealt" + "Attacks deal 200% bonus damage
  to burning enemies" + "All enemies start burning"
  = Effective lifesteal is 15% of base damage, not 5%
  Was this intended? If not, does it break survivability assumptions?
```

**3. Scaling breakpoints.** Stats that become degenerate beyond a threshold.

```
Example: Attack speed at 5.0 hits/sec — beyond what the animation can display.
  Player is technically attacking 5 times per second but the visual shows 2.
  Feels bad, might be exploitable in combat calculations.
  Solution: cap visual speed at 3/sec and make excess speed a damage multiplier.
```

**4. Resource exploits.** Ways to generate infinite or near-infinite resources.

```
Example: Selling an item gives 50 gold. Buying it back costs 45 gold.
  Repeat 100 times: +500 gold profit.
  This breaks the economy. Fix: buyback price = sell price, or no buyback.
```

### Systematic Edge Case Checking

```
For each new upgrade/item:
  1. List every other upgrade it interacts with multiplicatively
  2. Calculate the combined effect of the top 3 synergies
  3. Check if the combined budget exceeds 2× what any single build should reach
  4. Simulate 1,000 runs where the player aggressively pursues this combination
  5. If win rate exceeds 90%, the combination is too strong
```

---

## 7. Patch Cadence and Communication

Balance patches are a dialogue with your player community. When you change numbers, players who've optimized around those numbers feel the change acutely. How you communicate and pace changes affects player trust.

### Patch Cadence

```
Weekly hotfixes:
  Scope: Exploit fixes, critical bugs, values that are 50%+ off target
  Communication: Brief note — "Fixed an issue where X did unintended damage"

Biweekly balance passes:
  Scope: 5-10 value adjustments, each within the 10% rule
  Communication: Full patch notes with reasoning

Monthly major patches:
  Scope: New content, system changes, larger balance adjustments
  Communication: Design blog explaining the "why" behind changes

Quarterly retrospectives:
  Scope: Review all metrics against targets, identify systemic issues
  Communication: "State of the game" post or video
```

### Patch Note Style

Bad: `"Flame Strike damage: 150 → 120"`
Players don't know why. They feel punished.

Good: `"Flame Strike damage: 150 → 120. Fire Crit builds were achieving 68% win rates, well above our 50% target. This brings them in line while preserving the build's identity as a high-burst option."`
Players understand the reasoning. They can disagree, but they can't say you're being arbitrary.

Best: Include the data that motivated the change. `"Pick rate: 42% (target ~8%). Win rate with 3+ fire upgrades: 68% (target 50%). We're reducing Flame Strike damage by 20% to bring fire builds in line with other archetypes."`

---

## 8. A/B Testing for Balance

When you're uncertain about a change, A/B testing lets you compare two versions with real players.

### When A/B Testing Works

```
Good candidates:
  - "Should boss HP be 8000 or 10000?" (quantitative, measurable)
  - "Does adding a rest room on floor 7 improve retention?" (behavioral)
  - "Do players prefer 3 upgrade choices or 4?" (preference)

Bad candidates:
  - "Is this new mechanic fun?" (too complex for A/B)
  - "Which art style is better?" (subjective, not balance)
  - "Should we redesign the upgrade system?" (too large for A/B)
```

### A/B Test Structure

```
Population: Split players 50/50 into Group A and Group B
Duration: 1-2 weeks (need enough data for statistical significance)
Metric: Primary metric (win rate) + secondary metrics (retention, session length)

Group A (control): Boss 3 HP = 10,000
Group B (test):    Boss 3 HP = 8,000

After 2 weeks:
  Group A win rate: 42% (n=5,000)
  Group B win rate: 51% (n=5,000)
  Difference: 9 percentage points
  Statistical significance: p < 0.01 (yes, this is real)

Decision: Ship the 8,000 HP version.
```

### Sample Size Requirements

```
To detect a 5 percentage point difference in win rate (50% base):
  ~1,600 runs per group (3,200 total)

To detect a 2 percentage point difference:
  ~10,000 runs per group (20,000 total)

To detect a 1 percentage point difference:
  ~40,000 runs per group (80,000 total)

For indie games with smaller populations, focus on larger changes
where 5+ percentage point differences are expected.
```

---

## Exercises

### Exercise 1: Design a Telemetry Schema

For a roguelike with 15 floors, 5 bosses, 30 upgrades, and 4 playable characters:
1. Define the complete set of events you would track (event name + data fields)
2. Estimate the data volume: how many events per run? Per day (assuming 10,000 daily active players)?
3. Which 3 derived metrics would you compute first?

### Exercise 2: Diagnose from Charts

Given the following data from a live game:

```
Win rates by character:
  Knight: 62%    Mage: 35%    Rogue: 51%    Archer: 48%

Top 5 upgrade pick rates:
  "Iron Skin" (defense): 38%
  "Power Strike" (attack): 22%
  "Quick Step" (speed): 15%
  "Fire Ball" (spell): 4%
  "Poison Cloud" (DoT): 3%

Death floor distribution:
  Floors 1-3: 5%,  Floors 4-6: 15%,  Floors 7-9: 50%,  Floors 10-12: 25%, Final boss: 5%
```

1. What's the most urgent balance problem?
2. Why might Mage have a 35% win rate? (Propose 2 hypotheses)
3. Why are floors 7-9 responsible for 50% of deaths?
4. Propose 3 specific changes (with expected impact) to improve overall balance

### Exercise 3: Patch Note Writing

You've identified these problems:
- "Vampiric Strike" (lifesteal upgrade) has a 45% pick rate and builds using it have a 72% win rate
- The Summoner archetype has a 22% win rate (target: 45%)
- Boss 4 has a 15% clear rate (target: 50%)

Write a complete patch note that:
1. Addresses all three problems with specific number changes
2. Explains the reasoning behind each change
3. Follows the 10% rule (if multiple patches are needed, outline the roadmap)

### Exercise 4: Knob Identification

For your game (or a game you're designing):
1. List every tunable knob (aim for at least 20)
2. Classify each as Level 1, 2, 3, or 4 (per the hierarchy in Section 3)
3. For the 5 most important knobs, define: what metric it affects, what the current target is, and what direction you'd turn it if the metric was 20% off target

---

## Further Reading

- **"Data-Driven Game Design" GDC talks** — search for talks by Riot Games, Supercell, and Blizzard on using telemetry for balance. Riot's balance framework for League of Legends is the gold standard.
- **"A/B Testing for Games" by Anders Drachen et al.** — academic treatment of experimental design applied to games. Covers sample size, significance testing, and common pitfalls.
- **"Game Analytics" by Magy Seif El-Nasr et al.** — comprehensive textbook on game telemetry, visualization, and data-driven design. Covers both the technical pipeline and the design applications.
- **"Balancing League of Legends" Riot developer blogs** — Riot regularly publishes their balance philosophy, including how they use data, their patch cadence, and their archetype testing process.
- **[Module 2: Power Budgets](module-02-power-budgets-and-stat-allocation.md)** — power budgets are the audit tool that telemetry data feeds. An overbudget item detected via pick rate is exactly the scenario Module 2 prepares you for.
- **[Module 6: Monte Carlo Simulation](module-06-monte-carlo-simulation-and-validation.md)** — simulation validates changes before they ship. Telemetry validates them after. They form a feedback loop: telemetry reveals problems → you design a fix → simulation validates the fix → you ship it → telemetry confirms.
