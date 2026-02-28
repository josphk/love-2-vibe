# Module 6: Monte Carlo Simulation & Validation

**Part of:** [Game Balance Learning Roadmap](game-balance-roadmap.md)
**Estimated study time:** 4–5 hours
**Prerequisites:** [Module 1: Damage Formulas & DPS Modeling](module-01-damage-formulas-and-dps-modeling.md), [Module 5: Probability Design & Loot Systems](module-05-probability-design-and-loot-systems.md)

---

## Overview

Back-of-envelope calculations (Module 0) and budget analysis (Module 2) tell you what *should* happen. Monte Carlo simulation tells you what *actually* happens when probability, player choice, and system interaction combine over thousands of runs. A damage formula might look balanced on paper, but when a player stacks three multiplicative upgrades and fights a boss that's weak to their element, the actual DPS is 4× your estimate. You can't see that analytically — you need to simulate it.

Monte Carlo simulation is named after the famous casino: run the game thousands of times with random inputs and observe the distribution of outcomes. It's the bridge between theory and playtesting. Theory is fast but imprecise. Playtesting is precise but slow. Simulation is in between — precise enough to catch major balance problems, fast enough to iterate in minutes instead of hours.

This module walks through building a simulation from scratch, running it against your game's systems, interpreting the results, and knowing when simulation is sufficient versus when you need real playtesting.

---

## 1. What Monte Carlo Simulation Is (and Isn't)

### What It Is

Monte Carlo simulation is repeated random sampling. You model a system (combat, a roguelike run, a loot table), execute it with random inputs, record the outcome, and repeat thousands of times. The distribution of outcomes tells you what your system actually produces.

```
Simple example: "How long does a boss fight take?"

Model:
  Player DPS: 80 (with ±15% variance per hit)
  Boss HP: 5,000
  Player HP: 500
  Boss DPS: 30 (with ±20% variance)

Run the fight 10,000 times:
  Record: fight duration, player survived (yes/no), remaining HP

Results:
  Median fight duration: 63 seconds
  90th percentile: 78 seconds
  Win rate: 72%
  Median remaining HP on win: 120
```

These numbers are more useful than the back-of-envelope estimate (5,000/80 = 62.5 seconds) because they include variance, the interaction between player and boss damage, and the win/loss distribution.

### What It Isn't

- **It's not a game engine.** You don't need to simulate physics, rendering, or input handling. You simulate the *math* — damage calculations, upgrade selections, drop rolls.
- **It's not a replacement for playtesting.** Simulation can't tell you if something "feels" fun. It can tell you if the numbers are in the right range for fun to be possible.
- **It's not proof.** 10,000 runs with a 55% win rate doesn't prove the true win rate is 55%. It proves it's *probably* between 54% and 56% (confidence interval). More runs = tighter interval.

---

## 2. Building a Combat Simulator

Start simple: a single encounter between player and enemy. This is the atom of your simulation — everything else is built on top of it.

### Step 1: Define the State

```
Player state:
  hp: current health
  max_hp: maximum health
  attack: base damage
  attack_speed: hits per second
  crit_chance: 0.0 – 1.0
  crit_multiplier: e.g. 2.0

Enemy state:
  hp: current health
  attack: base damage
  attack_speed: hits per second
  defense: damage reduction stat
  k: defense formula constant
```

### Step 2: Define the Combat Loop

```
function simulate_combat(player, enemy):
  time = 0
  dt = 0.1  // simulate in 0.1-second ticks

  player_attack_timer = 0
  enemy_attack_timer = 0

  while player.hp > 0 and enemy.hp > 0:
    time += dt

    // Player attacks
    player_attack_timer += dt
    if player_attack_timer >= 1.0 / player.attack_speed:
      player_attack_timer -= 1.0 / player.attack_speed
      damage = calculate_damage(player, enemy)
      enemy.hp -= damage

    // Enemy attacks
    enemy_attack_timer += dt
    if enemy_attack_timer >= 1.0 / enemy.attack_speed:
      enemy_attack_timer -= 1.0 / enemy.attack_speed
      damage = calculate_enemy_damage(enemy, player)
      player.hp -= damage

  return {
    winner: player.hp > 0 ? "player" : "enemy",
    time: time,
    player_remaining_hp: max(0, player.hp),
    enemy_remaining_hp: max(0, enemy.hp)
  }
```

### Step 3: Add Randomness

```
function calculate_damage(attacker, defender):
  // Base damage with ±10% variance
  base = attacker.attack * random(0.9, 1.1)

  // Crit check
  if random(0, 1) < attacker.crit_chance:
    base *= attacker.crit_multiplier

  // Defense reduction (divisive formula)
  reduction = defender.defense / (defender.defense + k)
  final_damage = base * (1 - reduction)

  return max(1, floor(final_damage))  // Minimum 1 damage
```

### Step 4: Run It

```
results = []
for i in range(10000):
  player = create_player()  // Fresh copy each run
  enemy = create_enemy()
  result = simulate_combat(player, enemy)
  results.append(result)

// Analyze
win_rate = count(r.winner == "player" for r in results) / 10000
avg_time = mean(r.time for r in results where r.winner == "player")
```

---

## 3. Simulating a Full Roguelike Run

A single combat simulation is useful, but the real power comes from simulating an entire run: upgrade selection, multiple encounters, resource management, and boss fights.

### Run Simulation Architecture

```
function simulate_run(config):
  player = create_base_player()
  floors = config.num_floors

  for floor in range(1, floors + 1):
    // Generate encounters for this floor
    encounters = generate_encounters(floor, config)

    for encounter in encounters:
      result = simulate_combat(player, encounter.enemies)
      if result.winner == "enemy":
        return { outcome: "death", floor: floor, ... }

    // Offer upgrades after each floor
    offerings = generate_offerings(player, floor, config)
    chosen = select_upgrade(player, offerings, strategy)
    apply_upgrade(player, chosen)

    // Boss fight at end of zone
    if floor % config.floors_per_zone == 0:
      boss = generate_boss(floor, config)
      result = simulate_combat(player, boss)
      if result.winner == "enemy":
        return { outcome: "death", floor: floor, ... }

  return { outcome: "win", final_power: calculate_power(player), ... }
```

### Modeling Player Choice

The hardest part of run simulation is modeling how the player chooses upgrades. Three approaches, from simple to complex:

**1. Random selection.** Pick a random upgrade from each offering. This represents a new player or worst-case scenario. Useful as a baseline — if a random-choice player wins 30% of the time, the floor is low enough.

```
function select_upgrade(player, offerings, strategy="random"):
  return random_choice(offerings)
```

**2. Greedy selection.** Always pick the upgrade with the highest immediate DPS or eHP gain. This represents a locally-optimal player who doesn't think about synergies.

```
function select_upgrade(player, offerings, strategy="greedy"):
  best = null
  best_value = -infinity

  for upgrade in offerings:
    // Simulate applying this upgrade and measure the gain
    test_player = copy(player)
    apply_upgrade(test_player, upgrade)
    value = calculate_dps(test_player) - calculate_dps(player)

    if value > best_value:
      best_value = value
      best = upgrade

  return best
```

**3. Archetype-guided selection.** The simulated player has a target build archetype and prioritizes upgrades that match it. This represents an experienced player building intentionally.

```
function select_upgrade(player, offerings, strategy="archetype"):
  archetype = player.target_archetype  // e.g., "fire_crit"
  priorities = archetype.stat_priorities  // e.g., [crit, fire_damage, attack]

  best = null
  best_score = -infinity

  for upgrade in offerings:
    score = 0
    for stat, priority_weight in priorities:
      if upgrade.affects(stat):
        score += upgrade.value(stat) * priority_weight
    // Bonus for synergy with existing upgrades
    score += calculate_synergy_bonus(player, upgrade)

    if score > best_score:
      best_score = score
      best = upgrade

  return best
```

**Run all three** and compare results. The gap between random and archetype tells you how much skill/knowledge matters. The gap between greedy and archetype tells you how much build planning matters.

---

## 4. Interpreting Results

Running 10,000 simulations produces a mountain of data. The skill is knowing which numbers matter and what they mean.

### Essential Metrics

**Win rate:** The percentage of runs that reach the final boss and defeat it.

```
Target win rates by game type:
  Casual roguelike:  60–80% (most runs succeed)
  Standard roguelike: 30–50% (success is satisfying, not expected)
  Hard roguelike:    10–25% (mastery is required)
  Ultra-hard:         5–15% (for the dedicated)
```

**Power distribution at key checkpoints:** What does the player's DPS/eHP look like at floor 5, 10, 15, end?

```
DPS at floor 10 (10,000 runs):
  10th percentile:  85    (weak run — bad upgrades or bad luck)
  25th percentile:  110
  Median:           145
  75th percentile:  190
  90th percentile:  260   (strong run — good synergies)
  Ratio 90th/10th:  3.1×  (spread of outcomes)
```

The 90th/10th ratio tells you how much variance your system produces. Below 2×, runs feel samey. Above 5×, the gap between good and bad runs is too large — bad runs feel hopeless and good runs feel trivially easy.

**Floor of death:** Where do failed runs end?

```
Deaths by floor (of runs that died):
  Floor 1-3:   15%  (insufficient base power — too hard early?)
  Floor 4-6:   25%  (first elite/boss spike)
  Floor 7-9:   20%  (mid-run resource drain)
  Floor 10-12: 30%  (final zone difficulty spike)
  Floor 13-15: 10%  (boss fight)
```

If deaths cluster at a specific floor, that floor is a difficulty spike. If deaths are evenly distributed, difficulty is smooth but perhaps too uniformly punishing.

**Upgrade pick rates:** How often is each upgrade selected (across all strategies)?

```
If one upgrade is picked 40% of the time across 10,000 runs,
it's either overbudget or the only option in its category.

Healthy pick rate for a pool of 30 upgrades: 2–8% each
One upgrade at 15%+: dominant, needs nerf or competition
One upgrade at <0.5%: trap option, needs buff or removal
```

### Confidence Intervals

How many runs do you need?

```
For win rate estimation:
  1,000 runs:   ±3% at 95% confidence (47-53% for a 50% true rate)
  10,000 runs:  ±1% at 95% confidence (49-51%)
  100,000 runs: ±0.3% at 95% confidence

For median DPS estimation:
  1,000 runs:   ±5% relative error
  10,000 runs:  ±1.5% relative error

Rule of thumb: 10,000 runs is enough for most balance decisions.
Use 1,000 for quick iteration, 100,000 for final validation.
```

---

## 5. Win Rate Targeting

The most actionable output of simulation is win rate. Once you can simulate runs, you can tune difficulty by adjusting knobs until the win rate hits your target.

### The Knobs

```
Knobs that increase win rate (make game easier):
  ↑ Player base stats (HP, attack, defense)
  ↑ Upgrade power (higher budget per tier)
  ↑ Upgrade frequency (more offerings per run)
  ↑ Healing availability (rest rooms, lifesteal)
  ↓ Enemy stats (HP, damage, speed)
  ↓ Enemy density (fewer per room)
  ↓ Boss stats

Knobs that decrease win rate (make game harder):
  ↓ Player base stats
  ↓ Upgrade power
  ↓ Upgrade frequency
  ↑ Enemy stats
  ↑ Enemy density
  ↑ Boss stats
  ↑ Environmental hazards
```

### Binary Search for Target Win Rate

```
Goal: 45% win rate

1. Run 10,000 simulations with current settings → 62% win rate (too easy)
2. Increase boss HP by 20% → 51% win rate (closer)
3. Increase boss HP by another 10% → 44% win rate (close enough)
4. Fine-tune: increase boss HP by 2% → 45.3% win rate → ship it

Total simulation time: 4 runs × ~30 seconds each = 2 minutes
vs. playtesting 4 balance iterations × 2 hours each = 8 hours
```

### Multi-Dimensional Tuning

Often you want to change multiple knobs simultaneously. The interaction between knobs makes this non-trivial.

```
Problem: Win rate is 62%. You want 45%.

Option A: Reduce player base HP by 20%
  → Win rate drops to 38% (too much — HP affects everything)

Option B: Increase boss damage by 15% AND reduce healing by 10%
  → Win rate drops to 46% (better — targeted at boss fights)

Option C: Increase enemy density by 1 per room
  → Win rate drops to 44% (smooth — more attrition, same bosses)
```

Run all three and compare side effects. Option A might make early floors too punishing. Option B might make bosses frustrating. Option C might slow the game down. Simulation gives you the win rate, but you need design judgment to pick the right knob.

---

## 6. Spreadsheet vs. Code Simulation

You don't need to be a programmer to run Monte Carlo simulations. Spreadsheets can handle surprisingly complex models.

### Spreadsheet Approach

```
Row = one simulated fight
Columns:
  A: Player attack (=base_attack * (0.9 + RAND()*0.2))
  B: Crit? (=IF(RAND() < crit_chance, crit_multi, 1))
  C: Damage per hit (=A * B)
  D: Effective DPS (=C * attack_speed)
  E: Boss HP
  F: Fight duration (=E / D)
  G: Boss damage to player (=boss_dps * F)
  H: Player survived? (=IF(G < player_hp, "Yes", "No"))

Copy 10,000 rows. Use COUNTIF for win rate. Use PERCENTILE for distributions.
```

**Pros:** No coding required. Immediate visual feedback. Easy to share with non-technical team members.
**Cons:** Hard to model complex logic (multi-phase bosses, conditional abilities). Slow for 100k+ runs. Spreadsheet formulas don't handle loops well.

### Code Approach

Any language works. Python is popular for its simplicity and data libraries.

```python
import random
from statistics import mean, median

def simulate_fight(player, boss):
    time = 0
    while player['hp'] > 0 and boss['hp'] > 0:
        # Player turn
        dmg = player['attack'] * random.uniform(0.9, 1.1)
        if random.random() < player['crit_chance']:
            dmg *= player['crit_multi']
        boss['hp'] -= dmg

        # Boss turn
        boss_dmg = boss['attack'] * random.uniform(0.8, 1.2)
        player['hp'] -= boss_dmg

        time += 1.0 / player['speed']

    return {'won': player['hp'] > 0, 'time': time}

# Run 10,000 simulations
results = []
for _ in range(10000):
    p = {'hp': 500, 'attack': 80, 'speed': 1.5,
         'crit_chance': 0.15, 'crit_multi': 2.0}
    b = {'hp': 5000, 'attack': 30}
    results.append(simulate_fight(p, b))

wins = [r for r in results if r['won']]
print(f"Win rate: {len(wins)/len(results)*100:.1f}%")
print(f"Median fight time: {median(r['time'] for r in wins):.1f}s")
```

**Pros:** Handles any complexity — multi-encounter runs, conditional logic, full upgrade systems. Fast (10,000 runs in seconds). Scriptable — can run parameter sweeps automatically.
**Cons:** Requires programming knowledge. Harder to share with non-technical team.

### Recommendation

Start with a spreadsheet for single-encounter validation. Move to code when you need to simulate full runs, complex interactions, or upgrade systems. The spreadsheet prototype helps you define the model; the code version scales it.

---

## 7. Simulation vs. Playtesting

Simulation and playtesting answer different questions. Knowing which to use when saves enormous time.

### What Simulation Does Well

| Question | Why Simulation Works |
|----------|---------------------|
| Is the win rate in the right range? | Pure math — no player skill needed |
| Which upgrade is overpowered? | Pick rates across 10k runs reveal dominance |
| Is this boss HP too high? | TTK distribution shows if it's achievable |
| Does this build archetype work? | Simulate the archetype's choices and measure viability |
| Is there power creep in the new patch? | Compare pre/post patch median power |

### What Simulation Does Poorly

| Question | Why Playtesting Is Needed |
|----------|--------------------------|
| Is this fun? | Fun is subjective and physical — simulation can't feel it |
| Is the difficulty perceived as fair? | Players have emotions about randomness |
| Does this control well? | Simulation skips input, physics, timing |
| Is there an exploit? | Simulators follow rules; players find loopholes |
| Is the visual feedback clear? | Simulation has no visuals |

### The Workflow

```
1. Design (on paper)
   → Back-of-envelope check (Module 0)
   → "Is this in the right ballpark?"

2. Simulation
   → Build model, run 10,000 times
   → Tune knobs until metrics hit targets
   → "The numbers work."

3. Playtest (internal)
   → Play the actual game with simulation-validated numbers
   → "The numbers work AND it feels right."

4. External playtest
   → Give it to real players
   → "It works for people who aren't us."

5. Ship + telemetry (Module 7)
   → Monitor real player data
   → "It works at scale."
```

Each stage catches different problems. Simulation catches ~80% of numerical balance issues. Playtesting catches feel, clarity, and exploit issues. Telemetry catches population-level patterns that neither simulation nor small playtests reveal.

---

## Exercises

### Exercise 1: Build a Combat Simulator

Implement the combat simulator from Section 2 (spreadsheet or code). Use these stats:

```
Player: HP=500, Attack=60, Speed=1.5/sec, Crit=15%, CritMulti=2×
Boss: HP=4000, Attack=25, Speed=1.0/sec, Defense=15 (k=100)
```

Run 10,000 simulations. Report:
1. Win rate
2. Median fight duration (for wins)
3. 10th and 90th percentile fight duration
4. Median remaining player HP on win
5. What boss HP would achieve a 50% win rate?

### Exercise 2: Run Simulation

Extend your combat simulator to model a 10-floor run:
- 3 regular encounters per floor (enemy HP scales with floor: 200 × floor)
- 1 boss every 3 floors (boss HP = 3000 × zone_number)
- 1 upgrade offered after each floor (random from a pool of 10 upgrades you define)
- Player heals 20% max HP between floors

Run 5,000 simulations. Report:
1. Win rate (defeated final boss)
2. Most common floor of death
3. The upgrade with the highest pick rate (if using greedy strategy)
4. The upgrade with the lowest pick rate — is it a trap option?

### Exercise 3: Parameter Sweep

Using your run simulation, sweep a single parameter:
- Run the simulation with boss HP multiplier = 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0

For each multiplier, run 5,000 simulations and record the win rate. Plot win rate vs. boss HP multiplier. At what multiplier does win rate drop below 50%? Below 25%?

### Exercise 4: Simulation vs. Estimation

For the combat scenario in Exercise 1:
1. Calculate the expected fight duration analytically (back-of-envelope)
2. Compare to your simulation median
3. How far off is the estimate? Why? (What does the simulation capture that the estimate doesn't?)

---

## Further Reading

- **"Monte Carlo Methods in Practice" for game design** — search for game developer blog posts on applying Monte Carlo. The technique is standard in tabletop game design (Magic: The Gathering uses it extensively during set design).
- **SimulationCraft (WoW)** — an open-source combat simulator for World of Warcraft. Inspecting its source reveals how a production-grade game simulator handles complex ability interactions, procs, and gear.
- **"Balancing Slay the Spire with Simulations" (community)** — community members have built Slay the Spire simulators to test deck balance. Search for STS simulation tools and results.
- **Python's `random` module documentation** — covers the random functions you'll use in code-based simulation. Also see `numpy.random` for faster bulk random number generation.
- **[Module 0: The Math of Balance](module-00-the-math-of-balance.md)** — back-of-envelope estimation is the "before simulation" step. Simulation is the "verify the estimate" step.
- **[Module 7: Data-Driven Iteration](module-07-data-driven-iteration-and-live-tuning.md)** — simulation gives you pre-launch data. Module 7 covers post-launch telemetry, which is the real-world equivalent of Monte Carlo.
