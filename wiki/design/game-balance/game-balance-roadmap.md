# Game Balance Learning Roadmap

**For:** Game designers and programmers who want to move beyond intuition-driven tuning to principled, math-backed balance work · Focused on PvE and roguelikes (Hades, Slay the Spire, Risk of Rain) · Engine-agnostic · Spreadsheet + code examples · ADHD-friendly

---

## How This Roadmap Works

Game design theory asks "what should this system be?" Game balance asks **"what should the numbers be, and how do you validate them?"** This roadmap teaches the applied math, formulas, and validation techniques that combat designers, systems designers, and economy designers use every day. You don't need a math degree — you need expected value, spreadsheets, and the discipline to simulate before you ship.

Module 0 builds the statistical foundation. Modules 1–3 form a linear core: damage formulas, power budgets, and scaling curves. Module 4 (choice architecture) branches after Module 2 — it doesn't need scaling curves. Module 5 (probability/loot) branches early after Module 0 but benefits from Module 1's DPS framing. Module 6 (Monte Carlo simulation) ties together Modules 1 and 5 with validation techniques. Module 7 (live tuning) is the capstone — it assumes everything.

Each module below is a summary. Click the "Deep dive" link on any module to open the full study guide with detailed explanations, formulas, worked examples, and exercises.

**Dependency graph:**
```
0 → 1 → 2 → 3 (linear core)
              |
       4 (after 2, independent of 3)
       5 (after 0, better after 1)
       6 (after 1 + 5)
       7 (capstone — after all)
```

**Relationship to other topics:**
- [Game Design Theory Module 5: Economy](../game-design-theory/module-05-game-economy-resource-design.md) covers conceptual vocabulary (sources/sinks, opportunity cost). Game Balance applies it with formulas.
- [Game Design Theory Module 6: Difficulty](../game-design-theory/module-06-difficulty-challenge-fairness.md) covers the player experience of difficulty. Game Balance is the math under the hood.
- [GAS Module 1: Attributes](../gas/module-01-attributes-and-modifier-stacking.md) covers implementation of modifier stacking. Game Balance covers stacking as a design choice.
- [GAS Module 3: Effects](../gas/module-03-gameplay-effects.md) covers effect context and scaling. Game Balance covers formula design.
- [Game AI Module 9: Boss AI](../game-ai/module-09-boss-ai-patterns.md) covers boss encounter patterns. Game Balance covers the stat tuning behind them.

---

## Module 0: The Math of Balance

> **Deep dive:** [Full study guide](module-00-the-math-of-balance.md)

**Goal:** Statistical and probability foundations every balance designer needs.

You don't need calculus. You need expected value, variance, and an intuition for distributions. When a player picks between a weapon that deals 50 damage every hit and one that deals 10–90 damage per hit, they have the same expected value — but they feel completely different. The variance changes the experience. Understanding why, and having the math to quantify it, is what separates principled balance from guessing.

This module covers expected value as the universal currency of balance decisions, variance and standard deviation as measures of consistency vs. volatility, common distributions you'll encounter (uniform, normal, weighted), the Weber-Fechner Law (why +10 attack feels huge at level 1 and invisible at level 50), risk-reward framing through EV, and back-of-envelope estimation for quick sanity checks.

**Key concepts:**
- **Expected value (EV):** The average outcome of a random event over many trials. EV is how you compare options with different probabilities and payoffs on equal footing.
- **Variance and standard deviation:** How spread out outcomes are around the EV. High variance = swingy, exciting, frustrating. Low variance = consistent, reliable, potentially boring.
- **Weber-Fechner Law:** Perceived change is proportional to the ratio, not the absolute difference. Going from 10 → 20 attack (+100%) feels massive. Going from 100 → 110 (+10%) feels like nothing. This governs how you scale stat gains across a game.
- **Risk-reward as EV:** A risky option with the same EV as a safe option isn't equally valuable — players are typically risk-averse. You need to give risky options higher EV to compensate.
- **Back-of-envelope estimation:** Quick calculations to check if a number is in the right ballpark before building a spreadsheet. "If the player attacks twice per second for 60 seconds, that's 120 hits. At 50 damage per hit, that's 6,000 damage. Boss has 10,000 HP. Fight lasts ~100 seconds. Is that too long?"

**Read:**
- "Probability and Statistics for Game Designers" — search for Jesse Schell's or Ian Schreiber's game balance courses. The probability sections are directly applicable.
- "Thinking, Fast and Slow" by Daniel Kahneman (Chapters 26–28) — prospect theory, loss aversion, and how humans evaluate probabilistic outcomes. Explains why players don't behave like EV calculators.
- "Weber-Fechner Law in Game Design" — search for blog posts applying psychophysics to stat progression. The concept appears in GDC talks on RPG design.

**Exercise:** A roguelike offers two weapons: Dagger (25 damage, 100% hit rate) and Greatsword (75 damage, 50% hit rate). Calculate the EV of each per attack. Now add a "crit" mechanic: the Greatsword crits for 2× damage 20% of the time. Recalculate the EV. At what crit chance does the Greatsword match the Dagger's DPS? Now consider: which weapon *feels* better to a risk-averse player, even if the EV is identical? Why?

**Time:** 2–3 hours

---

## Module 1: Damage Formulas & DPS Modeling

> **Deep dive:** [Full study guide](module-01-damage-formulas-and-dps-modeling.md)

**Goal:** Master the design space of damage calculation — how formula architecture shapes combat feel.

The damage formula is the most consequential single equation in your game. It determines how attack and defense interact, whether player power growth feels satisfying or broken, and where breakpoints create interesting build decisions or frustrating cliffs. A flat subtraction formula (`damage = attack - defense`) plays completely differently from a multiplicative reduction formula (`damage = attack * 100/(100 + defense)`). The first creates hard breakpoints where defense can reduce damage to zero. The second creates smooth diminishing returns where defense never fully negates damage. Both are valid — the choice is a design decision, not a math one.

This module covers flat (subtractive) vs. multiplicative (divisive) vs. hybrid formulas, DPS calculation and why it's the standard comparison metric, time-to-kill (TTK) analysis, breakpoints and why they matter for build design, additive vs. multiplicative stacking as a design choice (not just a math property), and effective HP as the unified way to compare durability.

**Key concepts:**
- **Formula architecture:** The shape of the damage formula determines combat feel. Subtractive formulas (`atk - def`) create hard thresholds. Divisive formulas (`atk * k/(k + def)`) create diminishing returns. Hybrid formulas combine both.
- **DPS (damage per second):** The standard currency for comparing damage output. DPS = (damage per hit) × (hits per second) × (crit multiplier). Normalizes across different attack speeds, hit rates, and crit chances.
- **TTK (time to kill):** How long it takes to kill a target. TTK = target HP / attacker DPS. The feel of combat is defined more by TTK than by individual damage numbers.
- **Breakpoints:** Stat thresholds where something qualitatively changes. If defense fully negates damage below a threshold, there's a breakpoint. If attack speed increases don't add extra hits within an animation window, there's a breakpoint. Breakpoints create interesting build decisions — or frustrating dead zones.
- **Effective HP (eHP):** The amount of raw damage an entity can absorb before dying, accounting for all damage reduction. A character with 500 HP and 50% damage reduction has 1,000 eHP. Unifies armor, resistances, shields, and HP into one number.

**Read:**
- "Damage calculation" on game design wikis — compare the formulas used by Dark Souls, Diablo, Pokémon, and Hades. Each makes different tradeoffs.
- "Effective HP and Armor Math" blog posts — search for League of Legends or Dota 2 math posts. The MOBA community has analyzed these formulas exhaustively.
- "Designing Damage Formulas" — search for GDC talks or Gamasutra articles on combat math. Several excellent breakdowns exist.

**Exercise:** Implement three damage formulas in a spreadsheet or code: (1) Flat: `max(0, atk - def)`, (2) Divisive: `atk * 100/(100 + def)`, (3) Hybrid: `atk * 100/(100 + def) - def/4`. For each, chart damage output as attack ranges from 10–200 and defense is fixed at 50. Then chart as defense ranges from 0–200 and attack is fixed at 100. Identify where breakpoints occur. Calculate TTK against a 1,000 HP target for each formula when attack = 80, defense = 40, attack speed = 1.5 hits/sec. Which formula would you choose for a fast-paced roguelike? Why?

**Time:** 3–4 hours

---

## Module 2: Power Budgets & Stat Allocation

> **Deep dive:** [Full study guide](module-02-power-budgets-and-stat-allocation.md)

**Goal:** Assign numerical power to every game element using a unified budget system.

A power budget is the idea that every item, upgrade, ability, and enemy has a quantifiable power level, and that these levels should be internally consistent. If a common weapon has a power budget of 100 points, and each point of attack is worth 3 budget points, then a common weapon with 30 attack and 10 armor (at 1 budget point each) adds up to 100. A rare weapon might have a budget of 150. A legendary, 250. The actual numbers are arbitrary — what matters is that the ratios are consistent.

This module covers deriving a power budget from your game's DPS model, stat weighting (how much is 1 point of each stat worth relative to the others?), slot and tier budgets for equipment, detecting and controlling power creep, and intentional budget violations for chase items and build-defining moments.

**Key concepts:**
- **Power budget:** A numeric cap on how much total power a game element provides. Ensures items of the same tier are comparably powerful even when they allocate stats differently.
- **Stat weighting:** Converting different stats to a common currency. If 1 attack = 2 DPS and 1 crit% = 1.5 DPS, then attack is worth 1.33× crit in budget terms. Derived from your damage formula.
- **Tier budgets:** Items/upgrades grouped by rarity or tier, each tier with a defined budget range. Common: 80–120. Rare: 130–170. Legendary: 220–280. The overlap between tiers is a design knob.
- **Power creep detection:** Comparing new content's effective power against the existing budget curve. If a new common item has 140 budget points, it's power-crept.
- **Intentional violations:** Legendaries, set bonuses, and build-defining items can exceed the budget — that's what makes them exciting. The violation should be deliberate and bounded, not accidental.

**Read:**
- "Item Budget Systems" — search for blog posts on RPG item generation and budget-based loot. Diablo-style games have extensive community analysis.
- "The Power Budget" (GDC / game design blog posts) — the concept appears under different names across studios, but the principle is universal.
- "Stat Weights" from WoW/FFXIV theorycrafting communities — these communities have refined stat weighting to a science. The methodology transfers to any RPG.

**Exercise:** Design a power budget for a roguelike with 4 stats: Attack, Speed (attacks/sec), Crit%, and Max HP. Using the DPS formula from Module 1, derive the DPS value of +1 of each stat at a baseline of Attack=20, Speed=1.0, Crit%=5%, CritMulti=2×, HP=100. Set the stat with the lowest DPS-per-point as your budget unit (1 budget point). Express all other stats relative to it. Now create 3 items at each of 3 tiers (Common: 10 budget, Rare: 18 budget, Legendary: 30 budget). Verify each item's total budget falls within its tier range. Create one intentional violation — a legendary that exceeds its budget by 40% — and explain why the design justifies it.

**Time:** 3–4 hours

---

## Module 3: Scaling Curves & Progression Math

> **Deep dive:** [Full study guide](module-03-scaling-curves-and-progression-math.md)

**Goal:** Design the curves governing how player power and enemy difficulty change over a game.

A roguelike run might last 30 minutes or 30 hours. Over that time, the player gets stronger and enemies get harder. The relationship between those two curves — player power vs. enemy difficulty — is the emotional arc of your game. If the player scales faster, they feel powerful and eventually trivialize content. If enemies scale faster, the game becomes a war of attrition. If they scale at the same rate, nothing changes and progression feels pointless. The art is designing curves that create rising tension with moments of satisfying power spikes.

This module covers linear, polynomial, exponential, and logarithmic scaling, XP curves and level progression, enemy scaling strategies, rubber banding math (catch-up and pull-ahead mechanics), diminishing returns as a design tool, and prestige/reset curves for roguelikes and incremental games.

**Key concepts:**
- **Scaling shapes:** Linear (steady, predictable), polynomial (accelerating or decelerating), exponential (explosive growth), logarithmic (front-loaded gains that taper). Each creates a different feel.
- **XP curves:** How much XP each level requires. `xp = base * level^exponent` is the standard formula. Exponent = 1 is linear, 2 is quadratic, 1.5 is a common sweet spot.
- **Enemy scaling:** How enemy stats grow across the game. Common strategies: level-matched (enemies scale with player), zone-based (fixed per area), hybrid (base + player-scaled component).
- **Rubber banding:** Math that pulls underpowered players up and overpowered players back. XP bonuses for being underleveled, reduced gains for being overleveled. Keeps the difficulty curve consistent without hard gates.
- **Diminishing returns:** Making each additional point of a stat worth less than the previous one. Prevents any single stat from dominating and encourages build diversity. Can be explicit (formula-based) or implicit (via the damage formula's structure).
- **Prestige/reset curves:** In roguelikes, meta-progression between runs. Each run gives permanent upgrades that make the next run easier — but the cost of upgrades scales so that power growth is logarithmic across runs, not linear.

**Read:**
- "Math for Game Programmers: Building Procedural Curves" — search for the GDC talk by Squirrel Eiserloh. The best single resource on designing curves for games.
- "XP and Level Design" blog posts — search for RPG leveling curve analysis. The WoW and FFXIV communities have dissected these curves extensively.
- "Roguelike Meta-Progression Math" — search for Hades, Risk of Rain 2, and Slay the Spire meta-progression analysis. Each handles prestige differently.

**Exercise:** Design the scaling for a 10-zone roguelike run. Player starts at power level 1.0 and should reach ~10.0 by zone 10. Enemies start at difficulty 0.8 and should reach ~12.0 by zone 10 (so the final zone is harder than the player). Plot three player scaling curves (linear, polynomial with exponent 1.5, and exponential with base 1.28) alongside the enemy curve. At which zones does each player curve overtake the enemy curve? Where does it fall behind? Which curve creates the most interesting tension arc? Now add 3 power spike events (major upgrades at zones 3, 6, 9) and redraw. How do the spikes change the feel?

**Time:** 3–4 hours

---

## Module 4: Choice Architecture & Build Diversity

> **Deep dive:** [Full study guide](module-04-choice-architecture-and-build-diversity.md)

**Goal:** Design upgrade systems where multiple viable strategies coexist.

The worst outcome for a roguelike's upgrade system is a solved game — one dominant strategy that players converge on every run. The second worst is false choice — upgrades that look different but are mathematically identical. The goal is **meaningful diversity**: multiple distinct strategies that are all viable, creating replayability and personal expression. This is harder than it sounds. Without careful design, one build will dominate and the rest will be trap options that punish uninformed players.

This module covers the build diversity problem (why a single dominant strategy emerges), mutual exclusion as a tool (forcing tradeoffs), synergy design and the difference between linear and exponential synergies, the "8-build test" for validating diversity, trap options and how to avoid them, and roguelike offering algorithms (weighted random, pity timers, rarity gating).

**Key concepts:**
- **Dominant strategy:** A build that's strictly better than alternatives in all scenarios. Emerges when synergies are too strong, when one stat scales better than others, or when there's no meaningful tradeoff. Kills replayability.
- **Mutual exclusion:** Forcing players to choose between powerful options. If you take the fire path, you can't take the ice path. Creates meaningful decisions because every choice has an opportunity cost.
- **Synergy design:** How upgrades interact. Linear synergy: each upgrade adds a flat amount. Exponential synergy: each upgrade multiplies with previous ones. Exponential synergies feel amazing but are hard to balance — they create dominant strategies if unchecked.
- **The "8-build test":** Can you describe 8 distinct, viable build strategies for your game? If you can't, your upgrade system doesn't have enough diversity. If you can but 2 are clearly dominant, you have a balance problem, not a content problem.
- **Trap options:** Upgrades that are strictly worse than alternatives. Players who pick them are punished for not reading a wiki. Remove trap options or buff them — don't leave them in as noob traps.
- **Offering algorithms:** How roguelikes present upgrade choices. Pure random, weighted by rarity, weighted by build synergy, pity timers for rare options, duplicate protection. The algorithm shapes the player experience as much as the upgrades themselves.

**Read:**
- "Practical Creativity" by Raph Koster — covers choice design and meaningful decisions at a systems level.
- "The Design of Hades' Boon System" — search for GDC talks or analyses of Hades' upgrade system. Supergiant's approach to synergies, exclusion, and offering is a masterclass.
- "Balancing Build Diversity in Roguelikes" — search for Slay the Spire and Risk of Rain 2 balance analyses. These communities produce detailed viability tier lists that reveal balance problems.

**Exercise:** Design an upgrade system for a roguelike with 4 archetypes: Brawler (high damage, close range), Sniper (high damage, long range, slow), Speedster (low damage, fast, evasion), and Tank (low damage, high HP, sustain). Each archetype has 6 upgrades. (1) First, design upgrades where each archetype has purely linear synergies — each upgrade adds a flat bonus. Test: is any archetype clearly dominant in DPS or survivability? (2) Now add 2 cross-archetype synergies that create exponential scaling when combined. Test: do the cross-archetype synergies create a new dominant strategy that invalidates the pure archetypes? (3) Apply mutual exclusion: the two strongest cross-archetype synergies require giving up your archetype's best upgrade. Does this restore balance? Apply the 8-build test to your final system.

**Time:** 3–4 hours

---

## Module 5: Probability Design & Loot Systems

> **Deep dive:** [Full study guide](module-05-probability-design-and-loot-systems.md)

**Goal:** Design loot tables and randomized rewards that feel fair.

Players are terrible at estimating probability. A 1% drop rate sounds rare, but over 100 kills, there's a 63% chance of seeing it at least once. Over 300 kills, 95%. A 30% proc chance sounds unreliable, but it triggers roughly every third hit. The gap between mathematical probability and player perception is where loot system design lives. Your job is to design systems where the math works and the experience feels right — and those aren't always the same thing.

This module covers loot table architecture (nested tables, weighted pools, tiered drops), rarity tier design, pseudo-random distribution (the algorithm that makes randomness feel fair), pity timers (guaranteed drops after bad luck), offering algorithms for roguelikes, duplicate protection, and the distinction between frequency of opportunity and probability per opportunity.

**Key concepts:**
- **Loot table architecture:** Nested probability tables. Roll which tier → roll which item within that tier → roll affixes/stats. Separating the rolls makes balancing manageable and lets you tune rarity independently from item variety.
- **Rarity tiers:** Common/Uncommon/Rare/Epic/Legendary isn't just labeling — each tier has a budget range (Module 2), a drop probability, and a power range. The gap between tiers creates the excitement of finding rare items.
- **Pseudo-random distribution (PRD):** An algorithm where the proc chance increases each time the event *doesn't* happen, then resets when it does. A 25% PRD chance rarely goes more than 6 tries without proccing, while true 25% can go 20+. Used in Dota 2, Hearthstone, and most modern action-RPGs.
- **Pity timers:** Guaranteed drop after N failed attempts. Gacha games use them heavily. In roguelikes, pity timers on rare upgrades prevent frustrating droughts without changing the average drop rate much.
- **Frequency vs. probability:** A 1% chance from 100 enemies-per-minute feels generous. A 10% chance from 1 enemy-per-minute feels stingy. Same expected drops per minute (1), completely different experience. Design for frequency of opportunity, not just probability per roll.

**Read:**
- "Pseudo-random Distribution" on Dota 2 wiki — the canonical implementation. Shows the math and the C values for each probability.
- "Designing Loot Systems" (GDC / game design blogs) — search for talks on loot table design in Diablo, Borderlands, and Destiny. Each takes a different approach.
- "Loot Boxes and Drop Rates" — academic and industry analyses of reward schedules. The behavioral psychology behind variable-ratio reinforcement explains why loot systems are compelling.

**Exercise:** Build a loot table for a roguelike with 4 rarity tiers: Common (60%), Uncommon (25%), Rare (12%), Legendary (3%). Each tier has 5 items with equal within-tier probability. (1) Simulate 1,000 drops — do the actual frequencies match the target? (2) Implement pseudo-random distribution for the Legendary tier. Compare: over 1,000 simulated drops, what's the longest drought between Legendaries with true random vs. PRD? (3) Add a pity timer: guaranteed Legendary after 50 drops without one. How does this change the effective Legendary rate? (4) Add duplicate protection: if the player already has an item, halve its weight and redistribute. After the player owns 3 of 5 items in a tier, how does this affect the probability of getting the remaining 2?

**Time:** 3–4 hours

---

## Module 6: Monte Carlo Simulation & Validation

> **Deep dive:** [Full study guide](module-06-monte-carlo-simulation-and-validation.md)

**Goal:** Build simulations that validate balance faster than manual playtesting.

You can't playtest every build combination. A roguelike with 40 upgrades where you pick 10 per run has 847 million possible builds. Even a modest game with 20 upgrades and 6 picks has 38,760 combinations. Manual testing covers a tiny fraction. Monte Carlo simulation lets you test thousands of builds, runs, and scenarios by simulating them computationally — random inputs, deterministic rules, statistical analysis of the outcomes.

This module covers step-by-step Monte Carlo tutorial (spreadsheet first, then code), simulating full roguelike runs, interpreting results (percentiles, confidence intervals, histograms), win-rate targeting, the tradeoffs between simulation and playtesting, and when to trust simulation vs. when to trust player data.

**Key concepts:**
- **Monte Carlo method:** Run the same scenario thousands of times with randomized inputs. Analyze the distribution of outcomes. If 90% of random builds can beat the boss, it's too easy. If 5% can, it's either too hard or well-balanced with skill as the differentiator.
- **Run simulation:** Model a full roguelike run: start stats → random upgrades → fight sequence → boss. Each simulated run makes random choices and records the outcome (win/loss, completion time, health remaining).
- **Percentile analysis:** Don't just look at the average. The 10th percentile shows the worst reasonable luck. The 90th shows the best. If the 10th percentile run can't beat zone 5, unlucky players will have a miserable experience.
- **Confidence intervals:** How many simulations do you need? Rule of thumb: 1,000 runs give ±3% accuracy on a 50% win rate at 95% confidence. 10,000 runs give ±1%. Diminishing returns beyond that.
- **Win-rate targeting:** Choose a target win rate (e.g., 60% for a normal-difficulty roguelike) and tune enemy stats until simulation hits the target. This is faster than hand-tuning and catches edge cases.
- **Simulation vs. playtesting:** Simulation finds mathematical problems (impossible builds, broken synergies, impossible bosses). Playtesting finds feel problems (too slow, too confusing, not satisfying). You need both. Simulation first, playtest second.

**Read:**
- "Monte Carlo Simulation for Game Balance" — search for game design blog posts and GDC talks on using simulation for balance. Several indie developers have shared their approaches.
- "Thinking Statistically" by Uri Bram — short, accessible introduction to statistical thinking. Covers the concepts you need for interpreting simulation results.
- "Testing Games with Monte Carlo" — search for roguelike developer blogs. The Slay the Spire and Balatro communities have produced simulation-based balance analyses.

**Exercise:** Build a Monte Carlo simulator for a simplified roguelike: 10-zone run, player starts with 100 HP and 10 attack, each zone offers a random upgrade (+5 attack, +20 HP, or +10% crit — equal probability). Each zone has an enemy with HP = 50 + 20 × zone and attack = 5 + 3 × zone. Combat: alternating hits until one dies. (1) Simulate 1,000 runs. What's the win rate (clearing all 10 zones)? (2) Plot a histogram of "furthest zone reached." (3) The boss in zone 10 has 3× normal HP. What's the boss kill rate? (4) Tune enemy scaling until the win rate is approximately 50%. What did you change? (5) Find the best and worst builds in your simulation — what upgrades did they take?

**Time:** 4–6 hours

---

## Module 7: Data-Driven Iteration & Live Tuning

> **Deep dive:** [Full study guide](module-07-data-driven-iteration-and-live-tuning.md)

**Goal:** Continuously improve balance using telemetry, structured iteration, and patch discipline.

Simulation tells you what *should* happen. Telemetry tells you what *actually* happens. The gap between the two is where players are smarter, dumber, more creative, or more stubborn than your model predicted. Data-driven iteration closes that gap — you instrument your game, collect data from real players, build dashboards that surface problems, and make targeted changes with disciplined patch cadence.

This module covers telemetry design (what to log and why), the five essential balance dashboards, knob-based tuning (parameters designed for easy adjustment), archetype testing, edge case hunting, patch cadence and the "10% rule" for changes, and A/B testing for balance changes.

**Key concepts:**
- **Telemetry design:** Log the right events: run outcome (win/loss/zone reached), build path (every upgrade chosen in order), DPS at each zone, death cause, run duration. Too little data and you can't diagnose. Too much and you drown. Design your telemetry before launch.
- **Five essential dashboards:** (1) Win rate by zone/level, (2) Upgrade pick rate and win rate per upgrade, (3) Build archetype distribution, (4) DPS/survivability curves over a run, (5) Session length and quit points. These five surfaces cover 80% of balance problems.
- **Knob-based tuning:** Design your game with easily adjustable parameters — enemy health scaling factor, upgrade drop rate, boss damage multiplier. When data shows a problem, you turn a knob rather than rewriting a system. Knobs should be in config files, not buried in code.
- **The "10% rule":** Never change a balance parameter by more than 10–15% in a single patch. Larger changes overshoot and create oscillation. Small, consistent changes converge on the right value and don't shock players.
- **Archetype testing:** Group players by the build archetype they're using. Compare win rates across archetypes. If Fire builds win 70% and Ice builds win 30%, that's a balance problem — tune until archetypes converge within a reasonable band (e.g., all within 45–55%).
- **A/B testing:** Show different balance parameters to different player groups. Compare outcomes. Useful for controversial changes — "should boss HP be 5,000 or 6,000?" Test both, measure win rate and player satisfaction.

**Read:**
- "Game Analytics" by Magy Seif El-Nasr et al. — academic but practical book on game telemetry and analytics. Covers event design, dashboard construction, and statistical analysis.
- "Live Ops and Game Balance" GDC talks — search for talks by Riot, Supercell, or Blizzard on live balance processes. The workflow and cadence insights transfer to indie scale.
- "Data-Informed Design" blog posts — search for indie developers sharing their telemetry approaches. Smaller-scale implementations are more relevant than AAA infrastructure.

**Exercise:** Design the telemetry schema for a roguelike. Define: (1) The exact events you'd log (event name, fields, when it fires). Aim for 8–12 event types. (2) Design the 5 essential dashboards — sketch each one (what's on x-axis, y-axis, how it's filtered). (3) Your data shows Fire builds have a 68% win rate and Ice builds have 35%. Using the 10% rule, plan 3 patches that converge them. What specific knobs do you turn? What's your expected win rate after each patch? (4) Design an A/B test: you want to know if reducing boss HP by 15% improves session completion without making the game feel too easy. What's your sample size, metric, and success criterion?

**Time:** 3–4 hours

---

## Essential Bookmarks

| Resource | URL | Notes |
|----------|-----|-------|
| Squirrel Eiserloh: Math for Game Devs | Search: "Math for Game Programmers GDC" | Series of GDC talks covering curves, randomness, and probability for game designers. |
| Dota 2 PRD Documentation | Search: "Dota 2 pseudo random distribution" | The canonical reference for pseudo-random distribution implementation. |
| GASDocumentation (tranek) | https://github.com/tranek/GASDocumentation | Modifier stacking and effect systems — the implementation side of damage formulas. |
| Ian Schreiber: Game Balance Concepts | Search: "Game Balance Concepts blog" | Free online course covering game balance from a designer's perspective. |
| "Thinking, Fast and Slow" | Book by Daniel Kahneman | Prospect theory and loss aversion — why players don't behave like EV calculators. |
| Hades GDC Talks | Search: "Hades GDC Supergiant" | Supergiant's talks on boon design, synergy systems, and player-driven balance. |
| Balatro Balance Analysis | Search: "Balatro probability analysis" | Community math breakdowns of a modern roguelike's balance system. |

---

## ADHD-Friendly Tips

- **Module 1 is the unlock.** If you only finish one module, make it Module 1 (Damage Formulas). The DPS model gives you a framework for evaluating every combat number in your game. You'll never "just pick a number" again.
- **Spreadsheets are your best tool.** You don't need code for most balance work. A spreadsheet with your damage formula, a stat table, and a few charts will catch 80% of balance problems. Code comes later for simulation (Module 6).
- **One formula, one session.** Each module introduces formulas you can test immediately. Implement the damage formula from Module 1 in a spreadsheet in one session. Plot the curves from Module 3 in the next. Each session produces a tangible artifact.
- **The "5-minute sanity check."** Before any balance session, do back-of-envelope math (Module 0). "Player DPS is ~100. Boss has 5,000 HP. Fight takes ~50 seconds. Is that too long?" Five minutes of estimation saves hours of testing.
- **Balance is iteration, not perfection.** Module 7 exists because you will get the numbers wrong on the first try. The skill isn't getting it right — it's building systems that let you converge efficiently. Ship it, measure, adjust.
- **Start with the damage formula.** Modules 0 and 1 give you the highest ROI. From there, pick what matters most for your game: if you have items, do Module 2 (power budgets). If you have progression, do Module 3 (scaling). If you have loot, do Module 5 (probability). You don't have to go in order after Module 1.
