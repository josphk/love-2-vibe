# Module 2: Systems Thinking & Emergent Gameplay

> **Goal:** Understand how simple rules create complex, unpredictable experiences — and how to design games that surprise even you.

**Prerequisites:** [Module 1 — The Anatomy of a Mechanic](./module-01-anatomy-of-a-mechanic.md)
**Time Estimate:** 5–7 hours (reading + exercises)
**Difficulty:** Intermediate

---

## Overview

Here's a secret most players never think about: the best moments in games were never designed. Nobody at Ludeon Studios scripted the exact moment your pyromaniac colonist snaps during a raid and sets the kitchen on fire, starving your colony three days later. Nobody at Nintendo planned the specific sequence where you roll a boulder downhill, launch it off a ramp with an explosion, and use it to crush a Lynel. Those moments **emerged** from systems interacting with each other.

This module teaches you to think in systems. You'll learn the vocabulary — **stocks, flows, feedback loops** — and then see how connecting simple systems together produces gameplay that's infinitely more interesting than anything you could hand-script. You'll study games that do this brilliantly, identify the pitfalls that wreck emergent design, and practice mapping systems yourself.

You'll also learn a repeatable methodology for mapping any game's systems, study four case studies in depth, and walk through a gallery of broken designs with diagnosis and fixes. By the end, you'll have the tools to analyze any game as a system of systems and to design your own games that generate stories instead of telling them.

By the end, you'll look at every game differently. You'll see the loops. You'll see the connections. And you'll start designing games that generate stories instead of telling them.

---

## Core Concepts

### 1. What Is a System?

A **system** is a set of interconnected elements organized to achieve something. That's it. Your body is a system. A thermostat is a system. And every game you've ever played is a system (or more accurately, a collection of systems).

To talk about systems precisely, you need three pieces of vocabulary:

- **Stocks** — things that accumulate. Health points, gold, ammunition, population count, territory controlled. Stocks are the nouns of your system. You can measure them at any moment in time.
- **Flows** — the rates at which stocks change. Damage per second, income per turn, ammo consumption rate, birth rate. Flows are the verbs. They increase stocks (**inflows**) or decrease them (**outflows**).
- **Delays** — the time gaps between cause and effect. You plant crops now but harvest later. You invest in research now but unlock technology in three turns. Delays are what make systems unpredictable and interesting.

**Think of it like a bathtub.** The water level is your stock. The faucet is your inflow. The drain is your outflow. The delay is how long it takes to notice the water is rising before you adjust the faucet. Simple, right? Now imagine fifty bathtubs all connected by pipes, where draining one fills two others. That's a game.

In **Civilization VI**, your city's population is a stock. Food surplus is the inflow that grows it. The population generates production (another flow), which builds structures, which generate more food or gold (more flows feeding more stocks). Every decision you make adjusts a faucet somewhere in this web of bathtubs.

One more term worth knowing: a **converter** is a special node that takes one type of stock as input and produces a different type as output. A blacksmith converts gold and ore into a weapon. A research lab converts production into technology. Converters are what link different resource pools together and are covered in detail in [Module 5: Game Economy & Resource Design](./module-05-game-economy-resource-design.md).

Understanding stocks, flows, delays, and converters is the foundation. Every concept that follows builds on this vocabulary.

#### Worked Example: Mapping Hades as Stocks, Flows, and Delays

Let's make this concrete. Take *Hades* (Supergiant Games, 2020) and decompose one escape attempt into stocks, flows, and delays:

```
STOCKS                  FLOWS (IN)                FLOWS (OUT)           DELAYS
─────────────────────  ─────────────────────────  ─────────────────────  ──────────────────────
Player HP              Health drops, food rooms   Damage from enemies    Damage is instant;
                                                                        healing requires
                                                                        reaching the right room

Darkness (currency)    Room rewards, boss drops   Mirror upgrades        Upgrades only between
                                                                        runs (meta-delay)

Boons (active)         Boon rooms, Chaos gates    Death (reset)          Boon offered now,
                                                                        payoff may be 3 rooms
                                                                        later when synergy
                                                                        forms

Gold (per-run)         Room rewards, urns         Charon shop purchases  Must spend before run
                                                                        ends (deadline)

Death Defiances        Mirror purchase, Skelly    Each death in a run    Limited; once gone,
                       keepsake                                          gone until next run

God Gauge (call)       Dealing/taking damage      Using the Call         Builds slowly, spends
                                                                        all at once

Relationship progress  Nectar gifts, dialogue     (doesn't deplete)      Many runs between
                                                                        each unlock
```

Now connect them. Boons increase your damage output (flow), which clears rooms faster, which means you take less total damage (preserving the HP stock), which means you survive longer, which means you encounter more boon rooms (increasing the Boons stock). That's a positive feedback loop — we'll formalize that term next.

But notice the delays. Darkness earned during a run can't be spent until the run is over. Relationship progress takes many runs to pay off. Boon synergies don't fire until you've collected multiple compatible boons. These delays are what make Hades feel like a game of investment rather than a game of instant gratification. Every run plants seeds. Some of them bloom three runs later.

**Pause and try this:** Pick a game you played this week. Identify three stocks, their inflows and outflows, and one delay. Write it down in the table format above. It should take about five minutes. If you can't find a delay, look harder — delays hide in cooldowns, travel time, save/load gaps, crafting timers, and "you'll see the payoff later" progression mechanics.

---

### 2. Emergence Defined

**Emergent gameplay** is player experience that arises from system interactions rather than from authored scripts. Nobody wrote it. The rules wrote it.

Think of emergence on a spectrum:

| Type | Description | Example |
|------|-------------|---------|
| **Scripted** | Designer authors every moment | Walking through a cinematic corridor in Call of Duty |
| **Partially emergent** | Authored content + systemic variation | Enemies in *The Last of Us Part II* flanking differently each encounter |
| **Highly emergent** | Systems generate most of the experience | A *RimWorld* colony story, a *Dwarf Fortress* legend |
| **Purely emergent** | No authored content at all | Conway's Game of Life, cellular automata |

Most great games live in the middle of this spectrum. They combine authored **context** (a world, characters, goals) with systemic **generation** (unpredictable interactions that create unique moments).

The key insight: **emergence is not randomness.** Random events feel arbitrary. Emergent events feel *logical* — you can trace the cause-and-effect chain backward and say "of course that happened." This distinction matters more than it might seem. Random and emergent events can look identical from the outside — both are "things the designer didn't script." But they feel completely different to the player. A random critical hit feels like a coin flip. An emergent chain of consequences feels like a story you participated in. The pyromaniac set the fire because they had the pyromaniac trait, because they were stressed, because a raid killed their friend, because your defenses were weak, because you prioritized research over walls. Every link in that chain is a system doing its job.

That traceability is what makes emergent moments feel like *stories* rather than *noise*.

**Pause and try this:** Think of a memorable moment from a game you played recently. Was it scripted (the same thing happens every time), emergent (it arose from system interactions and wouldn't necessarily happen again), or random (it was a dice roll with no traceable cause)? If you're not sure, ask: "Could I trace a chain of causes backward from this moment?" If yes, it's emergent. If no, it's either scripted (predetermined) or random (no causal chain). This distinction matters because it tells you what the designer built — a story, a system, or a dice roll.

---

### 3. Positive Feedback Loops

A **positive feedback loop** (also called a **reinforcing loop**) amplifies change. Whatever direction things are moving, a positive loop pushes them further in that direction. Rich get richer. Losing gets worse.

**The structure:** A change in stock A increases stock B, which increases stock A further.

```
    ┌──────────────────────────────────────────┐
    │                                          │
    ▼                                          │
 [More Property] ──> [More Rent Income] ──> [More Money]
    ▲                                          │
    │                                          │
    └──────────────────────────────────────────┘
              MONOPOLY: Reinforcing Loop
        (Each cycle amplifies the leader's advantage)
```

**Example 1 — *Monopoly*:** You buy property. Property generates rent. Rent gives you money. Money lets you buy more property. This is why *Monopoly* games feel decided halfway through — the positive feedback loop snowballs the leader so far ahead that catching up becomes impossible. (This is also why *Monopoly* is, frankly, a poorly balanced game.)

**Example 2 — *StarCraft II*:** You expand to a second base early. More bases mean more resource income. More income means a bigger army. A bigger army means you can protect expansions and take more bases. Top players exploit this loop aggressively — the concept of "macro" is fundamentally about engaging the positive feedback loop faster than your opponent. The counterbalance is that expanding makes you temporarily vulnerable (you spent resources on the base, not on units), which is why early aggression strategies exist — they try to punish the positive loop before it kicks in.

**Example 3 — *Slay the Spire*:** You pick up a strong card synergy early in Act 1. That synergy lets you beat elites. Beating elites gives you better relics. Better relics amplify your synergy. By Act 3, you're an unstoppable engine — if the loop kicked in early enough. If it didn't, you're dead. This is a positive feedback loop with a built-in time constraint — the loop needs to reach critical mass before the enemies outscale you. That time pressure is what makes *Slay the Spire* runs feel like a race against the game's own difficulty curve.

**When positive loops work:** They create satisfying power fantasies, reward skillful play, and give games a sense of momentum and escalation. They're the reason "snowballing" feels great *when you're the one snowballing*. Positive loops are also essential for making player skill feel meaningful — if getting better at the game didn't create any advantage, there would be no incentive to improve.

**When positive loops break games:** Unchecked positive feedback creates **runaway leaders** and **death spirals**. If the player who's ahead always gets further ahead, the outcome is decided early and everyone else is just going through the motions. If losing makes you weaker and weakness makes you lose more, players trapped in a death spiral have a miserable time.

#### The 3-Question Detection Checklist

Not sure if you're looking at a positive feedback loop? Ask these three questions:

1. **Does winning make you stronger?** If gaining an advantage makes it easier to gain the next advantage, you've found a positive loop. In *StarCraft II*, more bases = more income = bigger army = easier to take more bases. Yes.
2. **Does losing make you weaker?** If falling behind makes it harder to catch up, the loop runs in both directions. In *Monopoly*, landing on someone's hotel drains your money, which means you can't buy property, which means you earn less rent. Yes.
3. **Does the gap widen over time without intervention?** If you simulated two players with slightly different starting positions, would the gap between them grow every turn? If yes, the positive loop is dominant. If the gap stabilizes, something else (a negative loop) is keeping it in check.

If you answer "yes" to all three, you have a strong positive feedback loop. That's not automatically bad — it depends on how fast it runs and what brakes exist.

#### Tuning Comparison: Mario Kart Wii vs. Mario Kart 8 Deluxe

Both games have positive feedback (leading means you keep the speed advantage of not getting hit) and negative feedback (item distribution favors trailing players). But the *tuning* is dramatically different.

**Mario Kart Wii** had aggressive negative feedback. The Blue Shell was frequent. The POW Block hit everyone. Lightning struck often. Bullet Bills were common for last-place racers. The result: skilled players felt punished. Online races felt chaotic. First place was a liability because you were constantly under bombardment. Many competitive players preferred to ride in second place until the final stretch.

**Mario Kart 8 Deluxe** pulled back on negative feedback. Blue Shells are rarer. The Super Horn provides a counter to them (the first one in the series). Speed differences between kart builds matter more. Item distribution still helps trailing players, but the gap between first and last is narrower. The result: skilled players can maintain leads more consistently, but comebacks still happen. Races feel competitive without feeling arbitrary.

Same franchise. Same core concept. Radically different feel because of feedback loop tuning. The lesson: the *existence* of a feedback loop matters less than its **strength, frequency, and timing**.

**Pause and try this:** Think of the last competitive game you played (multiplayer or against AI). Apply the 3-question checklist. Did you find a positive loop? How strong was it? Write down one sentence describing what brakes, if any, exist to slow it down.

---

### 4. Negative Feedback Loops

A **negative feedback loop** (also called a **balancing loop**) resists change. It pushes systems back toward equilibrium. It's the thermostat — when things get too hot, it kicks in the AC.

**The structure:** A change in stock A triggers a response that reduces stock A back toward a target level.

```
    ┌───────────────────────────────────────────────────┐
    │                                                   │
    ▼                                                   │
 [Player in 1st] ──> [Gets weak items] ──> [Less protection] ──┐
                                                               │
 [Player in last] ──> [Gets Blue Shell] ──> [Hits 1st place] ──┘
                                                   │
                                                   ▼
                                          [Gap narrows]

              MARIO KART: Balancing Loop
        (Each cycle compresses the field)
```

The most famous example in all of gaming: **the Blue Shell in *Mario Kart*.** The player in last place gets the most powerful item. It targets the player in first place. This is a textbook negative feedback loop — it punishes the leader and compresses the field.

**Rubber banding** is the general term for negative feedback mechanics that help trailing players catch up. You'll find it everywhere:

- **Racing games** give speed boosts to trailing cars (sometimes literally through the AI's physics).
- **Mario Party** gives better items to players in last place.
- **Catch-up experience** in MMOs and ARPGs lets underleveled players gain XP faster.
- **Dynamic difficulty adjustment** in games like *Resident Evil 4* secretly makes the game easier when you're struggling.

**When negative loops work:** They keep games competitive, extend tension, and give every player a chance. A close race is more exciting than a blowout. Negative feedback ensures that close races happen more often.

**When negative loops go wrong:** If overdone, they make skill feel irrelevant. Why try hard if the game is going to equalize everyone anyway? Players resent feeling punished for doing well. The Blue Shell is probably the most complained-about item in gaming history for exactly this reason — it feels like the game is punishing success.

The worst case: **stagnation**. If negative feedback is too strong, nobody can ever pull ahead, and the game feels like running on a treadmill. Nothing you do matters because the system always yanks you back to the middle.

**A subtlety about negative loops in single-player games:** In multiplayer, negative feedback prevents one player from ruining the experience for others. In single-player, the math is different. The "losing player" in a single-player game is the player themselves — and helping the losing player is just making the game easier. This is why Dynamic Difficulty Adjustment (DDA) is controversial. Some players want the game to adapt to their skill level. Others feel that invisible assistance robs them of genuine accomplishment. The design question isn't "should negative feedback exist?" but "should the player know about it?" Transparent negative feedback (difficulty sliders, optional assists in *Celeste*) tends to be better received than invisible negative feedback (secret rubber-banding, hidden DDA).

**Pause and try this:** Identify a negative feedback loop in a game you've played recently. Was it visible to you as a player (you could see the catch-up mechanic operating), or was it invisible (you only suspected it was there)? How did visibility (or invisibility) affect your feelings about it? Two minutes of reflection.

---

### 5. Balancing Loops

Great game design is about **mixing positive and negative feedback** so that neither dominates. You want momentum (positive) but also tension (negative). You want snowballing but also comebacks.

Here's the secret formula that many well-designed competitive games use:

> **Positive feedback creates the drama. Negative feedback keeps the game alive long enough for that drama to play out.**

**Example — *League of Legends*:** Killing enemies gives you gold (positive feedback — you're stronger, so you kill more). But death timers increase as the game goes on (negative-ish — losing a fight late game costs more time). Turrets provide safe zones for the losing team (negative — the ahead team can't just chase you forever). The bounty system puts a price on the head of the player who's dominating (negative — killing the fed player gives a massive reward). The result: games have momentum shifts, dramatic comebacks, and tense endgames.

**The design principle:** Let positive feedback loops operate in the **short term** (winning a fight should feel rewarding and create momentum) but introduce negative feedback in the **long term** (preventing any single advantage from becoming permanent). This creates games with **arcs** — rising action, climaxes, reversals — rather than monotone snowballs or flat stalemates.

Think of it as designing a story structure through mechanics rather than scripts.

This principle also explains why many roguelikes feel narratively satisfying despite having no scripted story. A *Slay the Spire* run has rising action (building your deck), a climax (the Act 3 boss), and either triumph or tragedy — all generated by the interplay of positive feedback (your deck getting stronger) and negative feedback (enemies getting harder). The feedback loops *are* the story arc.

#### The Loop Balance Audit Framework

When you're analyzing or designing a game's feedback structure, use this three-step audit:

**Step 1: List every positive (reinforcing) loop.**

Write them as cause-effect chains. For *Hades*:

- P1: Better boons --> more damage --> clear rooms faster --> reach more boon rooms --> better boons
- P2: More Darkness earned --> stronger Mirror upgrades --> survive longer --> earn more Darkness
- P3: Faster clears --> less damage taken --> more HP entering boss fights --> higher survival --> more progress

**Step 2: List every negative (balancing) loop.**

- N1: Progress further --> harder enemies --> more damage taken --> HP drain limits how far you go
- N2: More boons collected --> offered boons are from a shrinking pool --> less synergy guaranteed
- N3: Death resets all per-run progress (the ultimate negative feedback: total wipe)
- N4: Pact of Punishment (optional difficulty scaling) --> harder enemies --> slower progress

**Step 3: Match brakes to accelerators.**

For each positive loop, identify which negative loop counteracts it. If a positive loop has no matching brake, flag it.

```
Positive Loop                     Matched Brake                   Status
──────────────────────────────── ──────────────────────────────── ────────
P1: Boon snowball                N1: Enemy scaling + N2: Pool    Matched
P2: Darkness accumulation        N4: Pact of Punishment          Matched
P3: Speed/HP preservation        N1: Enemy damage scaling        Matched
                                 N3: Death reset                 Catchall
```

In Hades, every positive loop has at least one brake. The death reset (N3) acts as a universal safety valve — no matter how strong the snowball, it ends when you die. This is why the game feels fair even though individual runs can snowball hard. The brakes are per-run, and the accelerators are per-run too.

**The red flag:** If you complete this audit and find a positive loop with no matching brake, your game will eventually have a runaway problem. Either add a brake or accept that the game has a natural endpoint (which is fine for single-player games with defined endings, but lethal for competitive or long-session games).

**Pause and try this:** Pick a competitive game you know — a board game, a card game, an online multiplayer game. List two positive loops and two negative loops. Match them. Can you find an unmatched positive loop? That's where the game might feel unfair. Takes about ten minutes.

---

### 6. Interconnected Systems

This is where emergence really starts cooking. A single feedback loop is interesting. **Ten feedback loops connected together** is a living world.

The principle is simple: **System A's output becomes System B's input.** Chain enough of these connections together and you get behavior that no single system could produce alone.

**The *Dwarf Fortress* chain** is legendary:

Weather --> Crop Growth --> Food Supply --> Dwarf Mood --> Work Productivity --> Construction Speed --> Defense Quality --> Survival During Siege --> Population --> Labor Pool --> Crop Tending --> back to Crop Growth

Every arrow in that chain is a system. Every connection is a place where unexpected things can happen. A volcanic eruption (weather system) destroys crops (food system), which drops mood (psychology system), which causes a dwarf to go berserk (mental break system), which injures other dwarves (combat system), which strains your hospital (medical system), which pulls dwarves away from the walls they were building (labor system), which leaves a gap in your defenses (military system) just as a goblin siege arrives.

Nobody designed that story. Eleven systems, each simple on its own, connected together to create a tragedy.

**The key design lesson:** You don't need each individual system to be complicated. You need the **connections** between systems to be rich. A weather system that only affects visuals is decoration. A weather system that affects crops, movement speed, combat accuracy, and mood is a *generator of stories*.

When you're designing interconnected systems, ask yourself: **"What else should this affect?"** Every time you connect one more system to the web, you multiply the possible emergent outcomes.

There's a mathematical intuition behind this. If you have N systems and each connects to every other, you have roughly N*(N-1)/2 possible connections. Three systems give you 3 connections. Six systems give you 15. Ten systems give you 45. The emergent possibility space grows quadratically with the number of connected systems. This is why adding one more connection to an already-connected web feels so much more impactful than adding the first connection to an isolated system. The marginal value of each connection increases as the web grows.

Of course, you don't need every possible connection — you need the *right* connections. A weather system that connects to farming, travel, and combat is more valuable than a weather system that connects to farming, fishing, and foraging (three systems in the same domain). Cross-domain connections produce more surprising emergence than within-domain connections.

#### Worked Example: Stardew Valley System Map

*Stardew Valley* looks simple. You farm, fish, mine, talk to people. But under the surface, the systems are densely connected. Here's a map:

```
                            ┌─────────┐
                  ┌────────>│ ENERGY  │<────────┐
                  │         └────┬────┘         │
                  │              │               │
                  │         (limits all          │
                  │          actions)            │
                  │              │               │
            ┌─────┴───┐    ┌────▼────┐    ┌─────┴───┐
            │ COOKING  │<───│ FARMING │    │ MINING  │
            │ (food)   │    └────┬────┘    └────┬────┘
            └─────┬───┘         │               │
                  │         (produces           (produces
                  │          crops)              ores)
                  │              │               │
                  │         ┌────▼────┐    ┌────▼────┐
                  │         │ SELLING │    │CRAFTING │
                  │         └────┬────┘    └────┬────┘
                  │              │               │
                  │         (generates     (tools, machines,
                  │          gold)          sprinklers)
                  │              │               │
                  │         ┌────▼────┐         │
                  └────────>│  GOLD   │<────────┘
                            └────┬────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
               ┌────▼────┐ ┌────▼────┐ ┌────▼────┐
               │  SEEDS  │ │UPGRADES │ │  GIFTS  │
               └────┬────┘ └────┬────┘ └────┬────┘
                    │            │            │
                    │       (better tools     │
                    │        = faster)        │
                    ▼            │       ┌────▼────┐
               [FARMING]        │       │RELATION-│
                    ▲            │       │ SHIPS   │
                    └────────────┘       └────┬────┘
                                              │
                                         (unlocks
                                          recipes,
                                          events,
                                          areas)
                                              │
                                         ┌────▼────┐
                                         │  TIME   │
                                         │(seasons,│
                                         │ clock)  │
                                         └─────────┘
                                              │
                                    (constrains everything:
                                     what grows, when shops
                                     open, event schedules)
```

**Connection density analysis:** Count the arrows going in and out of each node.

| System | Connections In | Connections Out | Total |
|--------|---------------|-----------------|-------|
| Gold | 3 | 3 | 6 |
| Energy | 2 | 3 | 5 |
| Farming | 3 | 2 | 5 |
| Time | 0 | 4+ | 4+ |
| Relationships | 1 | 3 | 4 |
| Mining | 1 | 2 | 3 |
| Cooking | 2 | 1 | 3 |

Gold and Energy are the most connected nodes. That tracks with player experience: most decisions in Stardew Valley come down to "what should I spend my gold on?" and "do I have enough energy to do this?" Those two resources are where the game's meaningful choices live.

Time is special — it's a unidirectional constraint. Nothing flows *into* time (you can't create more of it). But time flows *out* to constrain everything else. This is why Stardew Valley feels urgent despite being a chill farming game: the clock and the seasons are always ticking, forcing you to prioritize.

**The design insight:** If you want to know what a game is *really* about, find the most connected node in its system map. That's the resource that drives the most decisions. If that node doesn't feel interesting to manage, the game has a problem.

Notice also that Time in Stardew Valley is what systems thinkers call an **exogenous constraint** — it comes from outside the player's system of control. You can't produce more time, trade for it, or slow it down. Every other resource in the game can be influenced by player action, but time just ticks. This creates a fundamentally different kind of pressure than resource scarcity. Running out of gold is a problem you can solve (earn more). Running out of daylight is a constraint you must accept. The most interesting design tension in Stardew Valley comes from this asymmetry: controllable resources (gold, energy, crops) operating under an uncontrollable constraint (time).

**Pause and try this:** Add one system to the Stardew Valley map above that doesn't currently exist — maybe a weather system that affects crop yield, or a fatigue system that reduces energy max over consecutive days without rest. Draw the connections. What new decisions would this create? What existing balance would it disrupt? Five minutes, pen and paper.

---

### 7. Designing for Emergence

So how do you actually design a game that produces emergence? The core philosophy is **constraint-based design**: give players tools and rules, not scripts and corridors.

**Principle 1 — Design verbs, not events.** Don't design "the player blows up the bridge." Design "the player has explosives" and "bridges are destructible." Let the player figure out the bridge part — and also figure out blowing up walls, floors, enemies, and their own escape route.

#### Worked Example: "Verbs Not Events" in Practice

Imagine you're designing an action game with an ice magic system. Here's the event-driven approach versus the verb-driven approach:

**Event-driven (bad for emergence):**
- Ice spell freezes specific marked enemies
- Frozen enemies shatter when hit (scripted animation)
- Certain puzzle doors require ice spell to open
- Ice bridges appear at predetermined story moments

The player has one verb ("cast ice spell") with four hard-coded consequences. Every interaction is preauthored. No surprise is possible.

**Verb-driven (good for emergence):**
- Ice spell reduces temperature of any surface or entity
- Water freezes below a temperature threshold
- Frozen surfaces are slippery (affects movement physics)
- Frozen entities become brittle (take more physical damage)
- Temperature transfers between adjacent objects over time

Now count the emergent possibilities. The player can: freeze a river to create a crossing, freeze a wet enemy to make them brittle, freeze the floor under enemies to make them slip off a cliff, freeze rain into hail that damages everyone in an area, create an ice wall by freezing a waterfall, chain-freeze a line of puddles to create a slippery escape route. And those are just the obvious ones. Players will find combinations you never imagined.

The key difference: the event-driven approach has **n** outcomes where n equals the number of authored events. The verb-driven approach has **n x m** outcomes where n is the number of things with temperature and m is the number of things affected by temperature states. Emergence scales multiplicatively.

This is the same principle behind *Breath of the Wild*'s chemistry engine, but stated as a design method rather than as an observation. When you're designing an ability, always ask: "Am I designing an event (this button does this one thing) or a verb (this button manipulates a property that many things respond to)?" The verb-driven version almost always produces more emergence for the same development cost. The tradeoff is that verbs are harder to balance because you can't predict every combination — which brings us back to Principle 5 (playtest for degenerate strategies).

**A practical heuristic:** If your ability description includes the words "specific," "designated," "marked," or "only," you're probably designing an event. Rewrite the description without those limiting words and see what you get.

**Principle 2 — Make systems visible.** Players can only engage with emergence if they can see the systems operating. *Breath of the Wild* makes its physics visible — you can see fire spread, see wind blow grass, see lightning strike metal. If your systems are hidden, players can't experiment with them.

**Principle 3 — Reward experimentation.** If there's one optimal path, players will find it and emergence dies. Design systems where multiple approaches work so players are motivated to try weird combinations. *Divinity: Original Sin 2* rewards players who combine elements in creative ways — electrifying water, freezing blood, igniting poison clouds. *Breath of the Wild* rewards experimentation by making physics solutions often faster or more spectacular than straightforward combat, even though combat always works too. The key is that experimental solutions should be *viable*, not necessarily optimal — if they're always better than the standard approach, you've just created a different kind of dominant strategy.

#### Divinity: Original Sin 2 — Surface System Combinatorics

*Divinity: Original Sin 2* is one of the best modern examples of verb-driven emergence. Its surface system works like this:

**Base surfaces:** Water, Oil, Poison, Blood, Fire (placed by spells, abilities, or environmental objects)

**Interaction rules:**
- Fire + Water = Steam (blocks vision)
- Fire + Oil = larger fire
- Fire + Poison = explosion + fire
- Lightning + Water = Electrified water (stuns anyone standing in it)
- Lightning + Steam = Electrified steam (stuns in area)
- Lightning + Blood = Electrified blood (stuns)
- Ice/Cold + Water = Ice surface (slippery, freezes those standing in it)
- Ice/Cold + Blood = Frozen blood (slippery)
- Ice/Cold + Steam = clears steam
- Rain + Fire = extinguished, creates water
- Bless + Fire = Holy fire (heals allies)
- Curse + Fire = Necrofire (can't be extinguished normally)

That's roughly 15 core interactions. But because multiple surfaces can coexist and chain, the combinatorial space explodes:

- Cast Rain to create water puddles. Then Lightning to electrify all of them. Then Teleport an enemy into the middle.
- Throw an Oil barrel. Ignite it. Enemy walks through fire, leaving a Blood trail. Lightning the blood. Stun chain.
- Bless a fire surface to heal your melee fighter standing in it. Enemy tries to extinguish it with water. Now you have blessed steam hiding your rogue.

The beauty of this system is that every spell designed for one purpose has a second life as a surface manipulator. A healing rain spell is also a tactical tool for creating water surfaces. A fire attack is also terrain control. The verbs do double duty, and that doubling is where emergence lives.

**Principle 4 — Accept loss of authorial control.** This is the hardest one. Emergent design means you can't control the player's experience. They'll do things you never imagined. They'll break your systems in hilarious and horrifying ways. That's the *point*. If you need to control every moment, emergence isn't your tool.

This doesn't mean you have *no* control. You control the vocabulary — the verbs and nouns available to the player. You control the constraints — what's forbidden or impossible. You control the incentives — what the game rewards and punishes. You just don't control the sentences the player writes with your vocabulary. Think of yourself as a language designer, not an author. You create the grammar; the player creates the poetry.

**Principle 5 — Playtest for degenerate strategies** (more on this in section 9). Emergence is a double-edged sword — it generates brilliant moments AND broken exploits.

**Pause and try this:** Think of a game with a scripted ability — something that does exactly one thing every time (e.g., a "lock pick" ability that only opens locks). Redesign it as a verb. What's the underlying physical or systemic action? "Lock pick" might become "manipulate small mechanisms," which could also disarm traps, jam enemy weapons, or pick pockets. Write down three new uses that emerge from your redesign. Five minutes.

---

### 8. The Butterfly Effect in Games

In chaos theory, the butterfly effect describes how tiny changes in initial conditions produce wildly different outcomes. Games with interconnected systems exhibit this constantly.

**In *XCOM 2*:** You miss a 95% shot. That miss means the alien survives. The surviving alien flanks your medic. Your medic dies. Without healing, your squad crumbles. The mission fails. You lose a region. Losing a region triggers the Avatar Project progress. The campaign spirals. All from one missed shot.

**In *Crusader Kings III*:** You choose to educate your heir yourself instead of assigning a guardian. Your heir picks up your character's traits. One of those traits makes them cruel. When they inherit the throne, their cruelty triggers a vassal rebellion. The rebellion fractures your kingdom. Three generations later, the dynasty you built is a collection of warring splinter states. All because of one education decision.

**In *Factorio*:** You place your smelting column three tiles to the left. That leaves just enough room for a belt between it and the wall. Twenty hours later, you need that exact gap to route your oil pipeline. If you'd placed it differently, you'd need to tear down half your factory. Small spatial decisions compound into massive structural consequences.

The butterfly effect is what makes emergent games endlessly replayable. The same starting conditions produce different stories every time because tiny variations compound through interconnected systems. It's also what makes them hard to balance — you can't predict every cascade.

**Design implication:** The butterfly effect is strongest when systems have **tight coupling** and **long chains**. If system A affects system B which affects system C which affects system D, a small change in A can produce a large change in D. If system A only affects system B and nothing further, the butterfly effect is limited to one step. When you're designing for replayability, look for ways to lengthen the cause-effect chains in your game. When you're designing for predictability (important in competitive games), look for ways to shorten them or add dampening at each step.

**Pause and try this:** Think of a game you've replayed multiple times. Identify one early decision that led to dramatically different outcomes in different playthroughs. How many systems did the cause-effect chain pass through? Write the chain out. The longer the chain, the stronger the butterfly effect in that game. Five minutes.

---

### 9. Degenerate Strategies

Here's the dark side of emergence: sometimes systems interact to produce a **dominant strategy** that's so effective, there's no reason to do anything else. When that happens, emergence dies — because everyone does the same thing.

A **degenerate strategy** is an approach that exploits system interactions to bypass intended challenges, reducing a complex game to a simple, repetitive action.

**Examples:**

- **"Stealth archer" in *Skyrim*:** The combination of stealth damage multipliers, archery range, and AI detection systems means that crouching and shooting arrows is absurdly more effective than any other playstyle. The systems are working as designed — but their interaction produces a strategy so dominant it collapses build diversity.
- **Tower rushing in early RTS games:** Building offensive structures in the enemy base exploited the gap between construction speed and early-game army production. The systems (building, economy, combat) all worked individually, but their interaction at a specific timing window created an unintended dominant play.
- **Infinite combos in fighting games:** When the stun system, damage system, and move-cancel system interact to allow a single hit to lead to an unavoidable kill combo, one system interaction overrides the entire competitive structure of the game.

#### Optimization vs. Degeneration: Drawing the Line

Not every strong strategy is degenerate. Players *should* optimize — finding efficient approaches is part of the fun. The line between healthy optimization and degenerate strategy is about what happens to the *rest of the game*:

| | Healthy Optimization | Degenerate Strategy |
|---|---|---|
| **Other options** | Viable alternatives exist | One strategy dominates all others |
| **Counterplay** | Opponents can adapt | No effective counter exists |
| **Engagement** | Player still makes interesting decisions | Decisions become trivial or automatic |
| **System usage** | Uses multiple systems | Bypasses or ignores most systems |
| **Feels like** | "I found a smart approach" | "I broke the game" |

In *Slay the Spire*, finding a strong deck archetype is optimization — there are multiple strong archetypes, they require in-run decision-making, and the game varies enough that no single archetype works every time. In *Skyrim*, stealth archer is degeneration — it works against every enemy type, requires no adaptation, and makes all other skill trees irrelevant.

#### Structured Autopsy Format

When you find a degenerate strategy (in your own design or someone else's), diagnose it systematically:

**1. Name the strategy.** Give it a clear label. "Stealth Archer," "Blue Shell Camping," "Infinite Combo Loop."

**2. Trace the system chain.** Which systems interact to make this possible? Write the chain:
- Stealth Archer: Stealth system (detection radius) + Damage system (sneak multiplier) + AI system (loses track after kill) + Archery system (range exceeds detection radius)

**3. Identify the broken link.** Which single interaction is disproportionately strong?
- Stealth Archer: Sneak multiplier stacking. The damage bonus for stealth attacks scales without limit, making one-shot kills routine.

**4. Propose the minimum fix.** What's the smallest change that breaks the degenerate loop without ruining the systems involved?
- Stealth Archer: Cap the sneak damage multiplier at 3x (not 15x). Or: after a kill, nearby enemies enter an alert state with reduced detection radius for 30 seconds, preventing repeated stealth kills in the same area.

**5. Check for collateral damage.** Does your fix break something else?
- Capping the multiplier might make stealth less satisfying for players who aren't exploiting it. The alert-state fix preserves the stealth fantasy for isolated targets while preventing the degenerate loop of standing in one spot and one-shotting an entire dungeon.

**6. Rate the severity.** Not all degenerate strategies need fixing. Ask: does this strategy reduce the game's total decision space by more than 50%? If the degenerate strategy still requires interesting decisions (just fewer of them), it may be healthy optimization rather than true degeneration. Save your design energy for the strategies that truly collapse the game.

**How to fight degenerate strategies:**

- **Introduce counters.** If strategy A dominates, make sure strategy B beats A (and C beats B, and A beats C). Rock-paper-scissors dynamics resist degeneration.
- **Add diminishing returns.** If stacking one stat is too strong, make each additional point worth less. Path of Exile does this with resistance stacking.
- **Playtest adversarially.** Hire players whose explicit job is to break your game. Speedrunners and min-maxers find degenerate strategies within hours.
- **Patch and iterate.** Live games can observe degenerate strategies forming in the wild and rebalance. *Slay the Spire*, *Hades*, and *Balatro* all went through extensive balance iteration during early access.

**Pause and try this:** Think of a game where you found an exploit or dominant strategy. Run it through the autopsy format above. Can you identify the broken link? Can you propose a minimum fix? This exercise trains the diagnostic muscle you'll need when playtesting your own designs. Ten minutes.

---

## How to Map Any Game's Systems

This section gives you a repeatable, structured methodology for analyzing any game as a collection of interconnected systems. Use it for study, for design critiques, or as the first step in designing your own game.

### The 8-Step Method

You can use this method on games you're playing for study, games you're designing, or games you're critiquing. The output is a one-page system map plus a short written analysis. The first time through takes 60-90 minutes. With practice, you can do a rough map in 20-30 minutes.

**Step 1: Play for 30 minutes without analyzing.**

Just play. Let the game wash over you. Notice what you're *doing* most often — that's probably the core mechanic. Notice what you're *managing* — those are probably your primary stocks. Don't write anything down yet. Analyzing too early kills the instinct that tells you what the game is really about.

**Step 2: List your nouns (stocks).**

After playing, write down every *thing* the game tracks. Resources, health, inventory items, territory, relationships, progress bars, unlocks. If it has a number or a state that can change, it's a stock. Aim for 8-15 stocks for a mid-complexity game.

**Step 3: List your verbs (flows).**

For each stock, identify what makes it go up (inflows) and what makes it go down (outflows). Be specific: "gold increases when I sell crops" not just "gold increases." Every flow should be a player action or a system event you can name.

**Step 4: Draw boxes and arrows.**

Put each major system in a box. Draw arrows showing how outputs from one system become inputs to another. Label the arrows with what flows along them. Don't worry about making it pretty — clarity beats aesthetics.

**Step 5: Trace the loops.**

Follow the arrows. Find every path that circles back to where it started. Label each loop as positive (reinforcing) or negative (balancing). Mark the strongest loops — the ones that dominate the game's feel.

**Step 6: Find the most connected node.**

Count arrows in and out for each box. The most connected system is usually the one that generates the most emergence — and the one you need to balance most carefully.

**Step 7: Identify delays.**

Mark every connection where cause and effect are separated by time. These delays are where the game's strategic depth lives — they're what make planning and anticipation possible.

**Step 8: Ask "what's missing?"**

Look for systems that have few connections. These are isolated — they don't participate in emergence. Either connect them to the web or ask whether they're earning their complexity cost. Also look for connections that *should* exist but don't (e.g., "weather exists but doesn't affect anything").

**Common mistakes when mapping:**

- **Mapping too granularly.** If your diagram has 30+ boxes, you're probably mapping individual mechanics instead of systems. Group related mechanics into a single system box. "Sword attack, bow attack, dodge, parry, block" is one system: "Combat."
- **Missing invisible flows.** Some of the most important flows are things the game doesn't show you explicitly — like how enemy difficulty scales with your level, or how the game's DDA (dynamic difficulty adjustment) tracks your performance. If the game feels like it's adapting to you, there's a hidden flow.
- **Forgetting the player.** The player is a system too — their attention, skill, knowledge, and emotional state all interact with the game's systems. In a mapping exercise, you can usually leave the player implicit, but when diagnosing "why does this game feel bad," the player-side systems (especially attention and cognitive load) are often where the problem lives.

### Worked Example: Hades Full System Map

Let's walk through the entire 8-step method with *Hades*.

**Step 1** (play without analyzing): The core experience is combat — fast, responsive, room-to-room fights with escalating difficulty. Between fights, you choose rewards. Between runs, you upgrade and talk to NPCs.

**Step 2** (stocks):
- HP, Death Defiances, Gold (per-run)
- Boons, Daedalus Hammers, Pom levels (per-run power)
- Darkness, Keys, Gems, Nectar, Ambrosia, Titan Blood (persistent currencies)
- Mirror upgrades, Weapon aspects (persistent power)
- NPC relationship levels (persistent progression)
- Heat level / Pact of Punishment (difficulty scaling)

**Step 3** (flows — abbreviated for space):
- HP: +food rooms, +boon healing, -enemy damage, -trap damage
- Gold: +room rewards, +urns, -Charon shop
- Darkness: +room rewards, +boss kills, -Mirror upgrades
- Boons: +boon rooms, +Chaos gates, -death (reset)
- Relationships: +Nectar gifts, +dialogue events, (no outflow)

**Step 4** (system map):

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PER-RUN LOOP                                │
│                                                                     │
│  ┌────────┐   boons    ┌────────┐  damage   ┌────────┐            │
│  │  BOON  │──────────>│ COMBAT │──────────>│   HP   │            │
│  │ SYSTEM │           │ SYSTEM │           │ SYSTEM │            │
│  └───┬────┘           └───┬────┘           └───┬────┘            │
│      │                    │                    │                  │
│      │ choices            │ room clears        │ death            │
│      ▼                    ▼                    ▼                  │
│  ┌────────┐           ┌────────┐           ┌────────┐            │
│  │ REWARD │<──────────│PROGRES-│           │  RUN   │            │
│  │SELECTION│  options  │ SION   │           │  END   │            │
│  └────────┘           │(rooms) │           └───┬────┘            │
│                       └────────┘               │                  │
└────────────────────────────────────────────────┼──────────────────┘
                                                 │
                              currencies earned  │  all per-run
                              persist            │  stocks reset
                                                 │
┌────────────────────────────────────────────────┼──────────────────┐
│                     META-PROGRESSION LOOP      │                  │
│                                                ▼                  │
│  ┌────────┐           ┌────────┐           ┌────────┐            │
│  │CURRENCY│──────────>│ MIRROR │──────────>│ NEXT   │            │
│  │  POOL  │  spend    │UPGRADES│  stronger │  RUN   │            │
│  │(Dark,  │           │& WEAP- │  start    │        │            │
│  │ Keys,  │           │ ASPECTS│           │        │            │
│  │ Gems)  │           └────────┘           └───┬────┘            │
│  └────────┘                                    │                  │
│      ▲               ┌────────┐                │                  │
│      │               │  NPC   │                │                  │
│      │  Nectar       │RELATION│  story, items  │                  │
│      └───────────────│ -SHIPS │<───────────────┘                  │
│                      └────────┘                                   │
│                                                                   │
│  ┌────────┐                                                       │
│  │  PACT  │──── increases difficulty ────> harder enemies,        │
│  │  OF    │     but unlocks more           scaling rewards        │
│  │PUNISH- │     currency rewards                                  │
│  │ MENT   │                                                       │
│  └────────┘                                                       │
└───────────────────────────────────────────────────────────────────┘
```

**Step 5** (loops):
- **Positive loop (per-run):** More boons --> more damage --> faster clears --> more boon rooms --> more boons
- **Positive loop (meta):** More Darkness --> stronger Mirror --> survive longer --> earn more Darkness
- **Negative loop (per-run):** Deeper rooms --> harder enemies --> more damage taken --> eventually die
- **Negative loop (meta):** Pact of Punishment scales difficulty up as you master the game

**Step 6** (most connected node): The Combat System. Everything feeds into it (boons, weapons, HP) and it feeds everything else (room clears, currency generation, HP loss). Combat is where the game lives — which makes sense, since it's an action roguelike.

**Step 7** (delays): Meta-progression has the longest delays — Darkness earned now pays off runs later. Relationship progress takes many runs. Weapon aspects take many Titan Blood drops over many runs. These long delays are why Hades stays engaging for 50+ hours: you're always planting seeds that will bloom later.

**Step 8** (what's missing): The NPC Relationship system is surprisingly disconnected from core gameplay. Talking to NPCs and giving gifts doesn't affect your combat power much (a few keepsakes aside). This is intentional — it keeps story progression from becoming a power-optimization problem — but it also means narrative-focused players and combat-focused players are engaging with largely separate games. Whether that's a feature or a limitation depends on your perspective.

**Using this method on your own designs:**

When you apply the 8-step method to a game you're building rather than analyzing, the process changes slightly:

- **Steps 1-4** happen during design rather than during play. You're drawing the system map *before* the game exists, based on your design document or prototype.
- **Steps 5-6** become diagnostic. If your map has no feedback loops (Step 5), your game probably doesn't have momentum or tension yet. If your most connected node (Step 6) isn't the system you consider most important, your design might have a focus problem.
- **Steps 7-8** become prescriptive. Adding delays (Step 7) is a concrete way to add strategic depth. Identifying missing connections (Step 8) is a concrete way to increase emergence.

The system map becomes a living document that you update as your design evolves. Revisit it after every major playtest.

---

## Case Studies

### Case Study 1: Breath of the Wild's Chemistry Engine

*The Legend of Zelda: Breath of the Wild* (2017) is one of the most celebrated examples of emergent gameplay in a mainstream title. Its secret weapon isn't the open world or the narrative — it's the **chemistry engine**, a unified physics simulation where every material in the game has properties that interact with every other material.

**The systems at play:**

- **Fire** spreads to flammable materials (wood, grass, cloth). It creates updrafts.
- **Wind** carries fire, pushes objects, and affects arrow trajectories.
- **Water** conducts electricity, extinguishes fire, and freezes in cold temperatures.
- **Metal** conducts electricity and attracts lightning during storms.
- **Temperature** affects the player (requiring warm or cool clothing) and the environment (melting ice, freezing water).
- **Gravity** is fully simulated — everything falls, rolls, and slides on slopes.

Each of these systems is relatively simple. Fire burns flammable things. Metal conducts electricity. These are elementary rules that any player can understand within seconds of encountering them. But because **every system connects to every other system**, the combinatorial explosion is enormous. The designers estimated that their chemistry engine creates something on the order of thousands of possible material interactions from just those six core properties.

A player encounters a camp of enemies on a wooden platform over a lake. Here are just some of the possible approaches that emerge from system interactions alone: set the platform on fire with a fire arrow and let it collapse; throw a metal weapon into the water and strike it with lightning; use a wind-creating item to blow explosive barrels into the camp; freeze the lake surface, slide bombs across the ice, and detonate them at the base of the platform; drop metal equipment near enemies during a thunderstorm and wait for lightning to strike.

None of these solutions were hand-authored as puzzle solutions. The designers built the systems, connected them, and let players discover the possibilities. The game's shrines (puzzle rooms) work the same way — each shrine teaches you a system, and the overworld lets you combine everything you've learned.

**Why it works so well:** The systems are **visible and predictable**. You can see fire. You can see wind. You can see rain. Because you understand the individual rules, you can reason about combinations. The moment of emergence feels like *your* discovery, not the game's trick. That sense of creative ownership is what makes players record clips and share them — they feel like inventors, not followers.

**The design lesson:** You don't need dozens of complex systems. You need a handful of simple systems with clear, visible rules and rich connections between them. *Breath of the Wild* proves that elegance of connection matters more than complexity of individual parts.

---

### Case Study 2: Dwarf Fortress — The Emergent Narrative Machine

*Dwarf Fortress* (first released 2006, Steam version 2022, ~$30) is the most ambitious emergent system ever built for a game. It simulates geology, hydrology, weather, ecology, agriculture, economics, combat (down to individual body parts and tissue layers), psychology, social relationships, history, mythology, and more. Each of these is a fully modeled system. And they're all connected.

**The scope of simulation:**

Every dwarf has individual personality traits, preferences, memories, relationships, skills, and moods. The mood system alone tracks dozens of factors: did they eat food they like? Do they have a nice bedroom? Have they seen a dead body recently? Did they talk to a friend? Is their clothing tattered? Each factor nudges mood up or down, and mood determines behavior — content dwarves work efficiently, while miserable dwarves may throw tantrums, start fights, or descend into permanent madness.

This mood system connects to *everything*. A dwarf who's a talented craftsman needs to create things regularly or they get restless (personality --> labor system). If they're not assigned to a workshop, their mood drops (labor --> mood). If their mood drops far enough, they might start a fight (mood --> combat). If they injure another dwarf, that dwarf's friends get upset (combat --> social --> mood). If enough dwarves are upset, productivity drops (mood --> labor --> economy). If the economy falters, food runs short (economy --> food). If food runs short, *everyone's* mood drops (food --> mood). One unhappy craftsman can spiral into a colony-wide collapse.

**The emergent narratives:**

Players don't just play *Dwarf Fortress* — they tell stories about it. The game's community is built on sharing narratives that the systems generated. A fortress where the mayor mandated the production of an item nobody knew how to make, leading to a tantrum spiral, leading to the mayor being locked in a room, leading to a forgotten beast breaking through the floor of that exact room. A dwarf who, driven mad by grief, created a legendary artifact and then walked calmly into a river. These read like authored fiction, but they're system outputs.

**Why it works:** Tarn Adams (the developer) designed each system to be **internally consistent and externally connected**. The combat system doesn't know about the mood system, but the mood system knows about combat. The weather system doesn't know about the food system, but the food system knows about weather. Each system does one job well and exposes its outputs for other systems to consume. This modular-but-connected architecture is what allows dozens of systems to interact without becoming an unmaintainable mess.

**The tradeoff:** *Dwarf Fortress* is famously difficult to learn, partially because the interconnected systems are often **invisible**. You can't always see why a dwarf is upset or why your food production dropped. The Steam version (2022) improved this significantly with visual indicators, tooltips, and a more readable UI, which demonstrates that the same underlying systems become more engaging when their states are surfaced to the player. The game demonstrates that emergence needs visibility — the more transparent your systems, the more players can engage with (and appreciate) the emergent outcomes.

**The practical takeaway for designers:** If you're building a system-heavy game, budget as much time for UI and feedback design as you do for the systems themselves. The best system in the world is worthless if the player can't see it operating.

---

### Case Study 3: Factorio — Depth Through Recursive Composition

*Factorio* (Wube Software, 2020, ~$35 but frequently cited in the "$30 and under" range during sales) answers a question most designers never think to ask: **what happens when you build an entire game from one system type, composed recursively?**

The core system in Factorio is the **converter**: take input A, wait, produce output B. That's it. A furnace takes ore, waits, produces plates. An assembler takes plates, waits, produces gears. Another assembler takes gears plus plates, waits, produces transport belts. A lab takes science packs, waits, produces research progress.

Every machine in the game is a converter. The entire factory is converters feeding converters feeding converters. The depth doesn't come from having many *different* system types — it comes from the same system type composed at increasing scales.

**The recursive composition:**

```
Level 1: Single converter
  [Iron Ore] ──> [Furnace] ──> [Iron Plate]

Level 2: Converter chain
  [Iron Ore] ──> [Furnace] ──> [Iron Plate] ──> [Assembler] ──> [Gear]

Level 3: Converging chains
  [Iron Ore] ──> [Furnace] ──> [Iron Plate] ──┐
                                                ├──> [Assembler] ──> [Belt]
  [Iron Ore] ──> [Furnace] ──> [Iron Plate] ──>│
                              ──> [Gear]  ──────┘

Level 4: Chains feeding chains feeding chains
  (20+ converters with branching, merging, and recycling)

Level 5: Entire factory sections become "black boxes" —
  conceptual converters that take raw inputs and produce
  finished outputs, composed of hundreds of actual converters
```

Each level uses the exact same system (input --> wait --> output) but the emergent complexity grows exponentially because outputs fan into multiple downstream consumers, bottlenecks cascade, and spatial constraints (you have to physically route belts between machines) create layout puzzles.

**Why one system type creates such depth:**

1. **The learning curve is smooth.** You understand the basic converter in five minutes. Every new recipe is just a new configuration of the same concept. You never have to learn a fundamentally new system type.

2. **Bottleneck propagation is the core emergent behavior.** If your iron smelting falls behind, everything downstream starves: gears slow, belts slow, assemblers building inserters slow, new smelting columns can't be built. One under-producing node ripples through the entire factory. This is a butterfly effect created entirely by recursive composition.

3. **The player's mental model scales.** Early game, you think about individual machines. Mid game, you think about production lines. Late game, you think about entire factory wings as single units. The system hasn't changed — your abstraction level has. Factorio teaches you to think in systems by letting you build them from the ground up.

4. **Optimization is infinite.** Because every converter has throughput (items/second), every connection has bandwidth (belt capacity), and every layout has spatial cost, there's always a way to build the same factory more efficiently. The optimization space is continuous, not discrete — you don't hit a wall where "you've solved it."

**The feedback loops in Factorio:**

- **Positive:** More factories --> more science --> more research --> better machines --> more efficient factories
- **Positive (dark):** More pollution --> more enemy attacks --> need more defenses --> need more resources --> more pollution
- **Negative:** Enemy evolution scales with pollution and time --> eventually enemies outpace your defenses unless you invest in military research
- **Negative (spatial):** Larger factories take longer to traverse, build, and debug --> diminishing returns on expansion

The pollution-enemy loop deserves special attention. It's a positive feedback loop *from the enemy's perspective* and a negative loop from the player's. The more you build, the stronger the enemies become. This creates a natural tension: you need to grow to progress, but growing attracts danger. The game never becomes trivially easy because your success breeds opposition.

**Comparison to Dwarf Fortress:** Dwarf Fortress achieves depth through *breadth* — dozens of different system types, each with unique rules, all connected. Factorio achieves comparable depth through *depth* — one system type, composed recursively, with spatial constraints adding a second layer of challenge. Both approaches work. But Factorio's approach is vastly more learnable because the player only needs to internalize one rule (input --> process --> output) and then apply it at increasing scale. If you're designing your first systemic game, the Factorio approach (one system type, composed recursively) is much more achievable than the Dwarf Fortress approach (many system types, all interconnected).

**The design lesson:** You don't always need many system types to create depth. If your core system type supports composition (outputs can become inputs to new instances of the same system type), you can build enormous emergent complexity from a single, well-designed building block. Ask: can my core mechanic feed into itself?

**Pause and try this:** Think of a game mechanic you've designed or enjoyed. Can it compose recursively — can its output serve as input to another instance of the same mechanic? If yes, sketch a three-level composition chain. If no, what would you need to change about the mechanic to make it composable? Five minutes.

---

### Case Study 4: Into the Breach — Minimum Viable Emergence on a Constrained Grid

*Into the Breach* (Subset Games, 2018, ~$15) is proof that emergence doesn't require a massive simulation. It creates genuine emergent gameplay on an 8x8 grid with 3 player units, 3-5 enemies, and turns that take about 60 seconds to resolve.

**The constraint-based design:**

Everything in Into the Breach is visible. Enemy attacks are telegraphed — you see exactly where every enemy will attack *before your turn*. This transforms the game from "react to surprises" into "solve a visible puzzle with systemic tools."

Your tools are your mechs, each with one primary ability. A punch that pushes enemies one tile. A shot that pushes enemies backward. An artillery strike that damages a tile. These are simple verbs. The emergence comes from how those verbs interact with:

- **Enemy positions and attack directions** (pushing an enemy changes what they'll hit)
- **Other enemies** (push enemy A into enemy B, both take damage)
- **Buildings** (push an enemy away from a building to save it)
- **Environmental hazards** (push an enemy into water to drown them, into fire to burn them)
- **Terrain** (push an enemy into a mountain to block them, off the grid to kill them)
- **Timing** (you have 3 moves per turn — order matters because each move changes the board state)

**A typical turn illustrating emergence:**

```
Before your turn (enemy intents shown):

  . . . . . . . .       Legend:
  . . E1→ . . . .       E1, E2, E3 = enemies
  . . . B . . . .       B = building (must protect)
  . . . . . . . .       M1, M2, M3 = your mechs
  . M1 . . E2 . .       → ↓ = enemy attack direction
  . . . . ↓ . . .       W = water
  . . M2 . B . M3       . = empty
  . . . . W . . .

Problem: E1 will destroy the building. E2 will destroy the other building.
You have 3 moves.

Solution using emergence:
  Move 1: M1 punches E1 south. E1 is now next to E2. E1's attack now
          hits empty space instead of the building.
  Move 2: M3 shoots E2, pushing E2 west into E1. Both take collision
          damage. E2's attack now aims at empty ground.
  Move 3: M2 artillery strikes E1's new position. E1 dies from
          combined damage (collision + artillery).

Result: Both buildings saved. One enemy killed. Two enemies damaged.
None of this was scripted — it emerged from position, push physics,
and collision rules.
```

**Why minimal emergence works here:**

1. **Perfect information creates readable emergence.** Because everything is visible, players can trace the full cause-effect chain *before acting*. Each emergent moment is a discovery the player makes through reasoning, not something that happens to them. This gives emergence the feel of solving a puzzle rather than witnessing chaos.

2. **Spatial constraints force creative use of verbs.** On an open field, "push an enemy one tile" isn't very interesting. On a cramped 8x8 grid with buildings, water, mountains, and other enemies, that same push has dozens of meaningful outcomes depending on context. The grid constrains the possibility space just enough that every option matters.

3. **Three moves per turn is a brutally tight action budget.** You can't brute-force solutions. You have to find the one sequence of three moves that addresses every threat simultaneously. This forces the player to think systemically — each move must serve multiple purposes through emergent interaction.

4. **The game teaches combinatorial thinking.** Early islands have simple problems: push enemy A away from building. Later islands layer threats until you're solving 4-5 problems simultaneously with your three moves, exploiting enemy-on-enemy collisions, environmental kills, and chain reactions. The systems don't change — your ability to combine them does.

**Comparing the four case studies:**

| | BotW | Dwarf Fortress | Factorio | Into the Breach |
|---|---|---|---|---|
| **System count** | ~6 material types | 20+ simulation layers | 1 (converter), composed | ~5 interaction rules |
| **Emergence source** | Material interactions | System cascades | Recursive composition | Spatial combinatorics |
| **Visibility** | High (physics are visual) | Low (many hidden states) | Medium (flows are visible, bottlenecks aren't) | Perfect (all info shown) |
| **Player agency** | Freeform experimentation | Management + reaction | Planning + optimization | Puzzle-like tactical |
| **Scale** | Large open world | Large simulation | Grows with player action | Tiny fixed grid |

Notice that these four games represent four fundamentally different approaches to emergence, yet they all share the same core ingredients: simple rules, meaningful connections between systems, and outcomes that the designers didn't explicitly author. The differences are in *which knobs they turn* — visibility, scale, system count, player agency — not in the underlying principles.

**The design lesson:** Emergence is not proportional to simulation size. *Into the Breach* creates more meaningful emergent decisions per minute than many games with a hundred times its systemic complexity. The key ingredients are: visible systems, tight constraints, and verbs that interact with context. If you're building a small game and think you can't have emergence, play Into the Breach. You can.

**Pause and try this:** Of the four case studies, which approach to emergence feels most achievable for a game *you* might make? Write one sentence describing the approach and one sentence explaining why it fits your skills or interests. This helps calibrate your ambition — knowing which model of emergence suits you is more valuable than knowing all four equally.

---

## Broken Design Gallery

Not every systemic game gets it right. This section presents four common failure patterns, diagnosed using the vocabulary from this module. Each one includes a real example, a diagnosis, and a fix. These four failures correspond directly to four of the six pitfalls listed in the Common Pitfalls section below — the gallery provides the deep diagnosis that the pitfalls section summarizes.

### Failure 1: Disconnected Systems

**The symptom:** The game has many systems, but they don't talk to each other. Each system operates in its own silo. Players engage with one system at a time rather than managing interactions between them.

**Example: Many open-world RPGs with crafting systems.** The crafting system exists alongside the combat system, the exploration system, and the quest system — but crafting doesn't affect combat in meaningful ways (crafted items are worse than loot drops), exploration doesn't feed crafting (materials are bought from vendors), and quests don't reference crafting at all. The crafting system is a disconnected island.

**Diagnosis using the system map method:** Draw the game's system map. If you find a box with only 1-2 arrows connecting it to the rest, that system is disconnected. A disconnected system adds complexity without adding emergence. It's dead weight.

```
┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐
│ COMBAT │<->│ QUEST  │<->│ EXPLORE│   │CRAFTING│  <-- island
│        │   │        │   │        │   │        │
└────────┘   └────────┘   └────────┘   └────────┘
     ▲            ▲            ▲
     └────────────┴────────────┘
          (densely connected)
```

**The fix:** Either connect the disconnected system or remove it. To connect crafting: make the best weapons only available through crafting, require exploration-exclusive materials, and tie crafting skill to quest rewards. Now crafting has arrows pointing to and from three other systems, and every crafting decision affects the rest of the game.

**The principle:** Every system should have at least 2-3 meaningful connections to other systems. If it doesn't, it's not participating in emergence.

**How to spot this in your own design:** During development, periodically remove each system one at a time (mentally or in a prototype build) and ask: "Does the rest of the game play differently without this?" If nothing changes, the system is disconnected. This test takes five minutes per system and can save you months of developing features that add nothing to the player experience.

**A subtle variant — one-directional connections:** Sometimes a system has connections, but they only flow in one direction. The quest system sends objectives to the exploration system, but the exploration system never sends anything back. This creates a hierarchy (quest system is the master, exploration system is the servant) rather than a web. Hierarchical connections are weaker generators of emergence than bidirectional ones because they can't create feedback loops.

---

### Failure 2: Unchecked Feedback

**The symptom:** Games that are decided in the first five minutes. Whoever gets the first advantage snowballs to victory. Trailing players have no viable path back.

**Example: *Monopoly*.** The positive feedback loop (property --> rent --> money --> more property) has almost no negative feedback. The "Free Parking" house rule adds a small dose of catch-up, but the official rules have virtually no brakes. The result is a game where the winner is often determined within the first 30 minutes of a 2-3 hour experience, and the remaining time is a slow, joyless grind to the inevitable conclusion.

**Diagnosis using the Loop Balance Audit:**

```
Positive Loops:
  P1: More property --> more rent --> more money --> more property
  P2: Houses/hotels multiply rent income exponentially

Negative Loops:
  N1: ...
  N2: ...

Status: No significant negative loops exist in the base rules.
P1 and P2 are completely unbraked.
```

**The fix:** Add meaningful negative feedback. Options:
- **Wealth tax:** Each turn, pay 5% of total property value. Rich players bleed money proportionally, creating a maintenance cost for large empires.
- **Rent relief:** If a player's total cash drops below a threshold, they pay reduced rent (50%) for three turns. This is the Blue Shell approach — direct aid to trailing players.
- **Property decay:** Unvisited properties lose value over time, requiring reinvestment. This creates a sink that scales with property holdings.

Any of these introduce a negative loop that scales with the leader's advantage, slowing the snowball enough for trailing players to remain engaged.

**Why Monopoly is instructive despite being a bad game:** Monopoly is often dismissed as a poorly designed game, and in many ways it is. But it's also a perfect teaching tool for feedback loop analysis *because* its flaws are so clear. Every aspiring designer should map Monopoly's feedback structure at least once — it's the canonical example of what happens when positive loops run unchecked. When you encounter subtler versions of this problem in better-designed games, you'll recognize the shape because you've seen it in its purest form.

---

### Failure 3: Kitchen Sink

**The symptom:** The game has 15+ systems, but they're so loosely connected that emergent interactions are rare. Each system is individually complex, and the cognitive load of managing them all is overwhelming. The game feels like juggling — keeping many balls in the air — rather than like operating one interconnected machine.

**Example: Overambitious survival games.** Consider a survival game with: hunger, thirst, temperature, stamina, health, sanity, hygiene, disease, radiation, weight limit, tool durability, crafting, building, farming, fishing, hunting, cooking, skill leveling, reputation, and trade. Twenty systems. But hunger and thirst are just timers you periodically reset. Temperature only matters in two biomes. Sanity has no connection to any other system. Hygiene does nothing except display a debuff icon. Half the systems are busywork.

**Diagnosis:** Apply the "what does this system connect to?" test. If a system's only connection is "bar goes down over time, player refills it," that's not a system — it's a chore. Chores add complexity without adding decisions.

**A useful heuristic:** Count the number of *interesting decisions* each system generates per hour of play. Hunger and thirst in most survival games generate roughly one decision per in-game day: "go eat/drink now." Temperature in a well-designed system generates dozens: "Do I take the mountain pass (cold but fast) or the valley (warm but slow)? Do I build a fire (warm but visible to enemies)? Do I craft a fur coat (warm but requires hunting)?" If a system generates fewer than three interesting decisions per play session, it's probably a chore disguised as a system.

**The fix:** **Cut to 4-6 core systems. Connect them deeply.** Kill hygiene, radiation, and sanity if they don't connect to anything. Merge hunger and thirst into a single "sustenance" resource. Make temperature affect stamina recovery and disease risk. Make disease reduce carrying capacity, which affects how much food you can forage, which affects sustenance. Now five systems are densely connected and every decision ripples:

```
Temperature ──> Stamina Recovery ──> Activity Capacity
    │                                      │
    └──> Disease Risk ──> Disease ──> Weight Limit ──> Foraging Yield
                                                            │
                                                            ▼
                                                       Sustenance
                                                            │
                                                            ▼
                                                    (feeds back to
                                                     stamina, disease
                                                     resistance)
```

**The principle:** Depth is not proportional to the number of systems. It's proportional to the density of connections between them. Five deeply connected systems will always generate more emergence than twenty isolated ones.

**The diagnostic question:** For each system in your game, ask: "If I removed this system entirely, would the other systems behave differently?" If the answer is no, the system is disconnected and should be cut or connected. If the answer is "yes, but only in one specific way," the system is weakly connected and should be woven in more deeply.

---

### Failure 4: Overcorrected Brakes

**The symptom:** The game feels flat. You never feel ahead or behind. Wins feel hollow because the game immediately neutralizes your advantage. Losses feel irrelevant because the game immediately compensates. Nothing matters.

**Example: Racing games with aggressive rubber-banding.** Some racing games secretly adjust AI speed so that trailing cars drive faster and leading cars drive slower. When done subtly, this creates exciting close races. When overdone, it creates the feeling that your driving skill is irrelevant — the AI will always be right behind you regardless of how well you drive. Skilled players notice and feel cheated.

**Diagnosis:** Use the Loop Balance Audit. If you find that negative loops are stronger than positive loops at every stage of the game, brakes are too heavy. The pattern:

```
Player gets ahead ──> negative feedback kicks in ──> advantage erased
Player falls behind ──> negative feedback kicks in ──> disadvantage erased
Result: Game oscillates around the mean. No sustained advantage is possible.
```

**The fix:** **Make brakes proportional, not absolute.** Instead of "the AI is always right behind you," try "the AI gets a speed boost that decays as it approaches you." This means the boost helps close large gaps but barely matters for small ones. The player's skill can maintain a small lead, but catastrophic leads are reined in.

Another fix: **delay the brake.** Instead of instant rubber-banding, give it a 3-5 second lag. The player feels the rush of pulling ahead, then gradually feels the pressure increase. The experience has texture — surge and compression — rather than a flat treadmill.

**The principle:** Negative feedback should feel like a rising challenge, not a ceiling. Players should be able to *earn* a lead, even if the game makes *holding* a massive lead progressively harder.

**The diagnostic question:** Play your game twice — once performing well and once performing poorly. If both experiences feel the same, your brakes are too heavy. If performing well feels dramatically different (and better), your brakes are appropriately tuned. The goal is not equal outcomes but equal *engagement* — both the leading player and the trailing player should have interesting decisions to make.

---

## Common Pitfalls

### 1. The Kitchen Sink Problem
You add system after system thinking more connections equals more emergence. But each new system multiplies your testing surface exponentially. **Start with 3-4 systems, connect them deeply, and only add new ones when the existing connections are solid.** *Breath of the Wild* uses maybe six core material properties. That's enough.

### 2. Invisible Systems
Your interconnected systems produce amazing emergent outcomes — but players never notice because they can't see the cause-and-effect chain. If a player doesn't know *why* something happened, it feels random, not emergent. **Surface your systems.** Use visual feedback, tooltips, event logs — whatever it takes to make the chain visible.

### 3. Unchecked Positive Feedback
Your game snowballs every time. Whoever gets ahead wins. Players who fall behind stop having fun. You forgot to add negative feedback to keep things competitive. **Every positive loop needs a brake somewhere in the system.** If you can't find one, add one.

### 4. Overcorrecting With Negative Feedback
You added so much rubber-banding that skill doesn't matter. Leading feels pointless because the game keeps dragging you back. Players feel punished for playing well. **Negative feedback should prevent runaway leaders, not prevent leading entirely.** The goal is tension, not stagnation.

### 5. Ignoring Degenerate Strategies
You shipped the game and players immediately found one dominant strategy that trivializes everything. You didn't playtest adversarially. **Assume players will optimize the fun out of your game and design accordingly.** Add diminishing returns, counters, and variety incentives before launch, not after.

### 6. Over-Authoring on Top of Systems
You built beautiful emergent systems and then layered scripted events on top that override them. The scripted moments feel disconnected from the systemic gameplay, and players learn to ignore the systems because the scripts will do the heavy lifting anyway. **If you commit to emergence, trust your systems.** Use scripts sparingly — for context and framing, not for moment-to-moment gameplay.

The worst version of this pitfall is the **scripted override**: a moment where the game's systems would produce an interesting outcome, but a script intervenes to force a specific result instead. If an NPC is supposed to die in a cutscene, but the player's systems could have saved them, the player feels betrayed. The systems told them one story; the script told them another. When those stories conflict, the player stops trusting the systems — and that's the death of emergent engagement.

---

## Exercises

### Exercise 1: System Map — Full Analysis

**Time:** 60-90 minutes
**Materials:** Large sheet of paper (A3 or larger), colored pens, or a digital diagramming tool (draw.io, Miro, even a slide deck). Optionally, the game itself running for reference.
**Deliverable:** One-page system map diagram + 300-500 word written analysis

Pick a game you know well — *Stardew Valley*, *Civilization VI*, *Hades*, *Slay the Spire*, *RimWorld*, anything with multiple interacting systems. Produce a complete system analysis using the 8-step method from this module.

**Steps:**

1. **Play or recall 30 minutes of gameplay.** Note what you're doing and managing.
2. **List 8-15 stocks.** Write them in a column. Group them by system (combat stocks, economy stocks, progression stocks, etc.).
3. **For each stock, list inflows and outflows.** Write these next to each stock. Be specific — name the player action or system event that causes each flow.
4. **Draw your system map.** Systems as boxes, connections as labeled arrows. Use colors: blue for positive feedback arrows, red for negative feedback arrows, black for neutral flows.
5. **Trace and label all feedback loops.** Give each loop a short name (e.g., "Economy Snowball," "Death Spiral Brake," "Exploration Reward Loop").
6. **Count connections per node.** Write the count inside each box. Identify the most connected system.
7. **Identify delays.** Mark connections with a clock symbol where cause and effect are separated by significant time.
8. **Identify one missing connection.** Propose a new arrow between two currently unconnected systems. Explain what it would do to the game's emergence.

**Written analysis (300-500 words):**

Answer these questions:
- What is the game's most connected system, and how does that affect the player experience?
- Which feedback loops dominate the early game vs. the late game?
- Are there any disconnected systems? If so, why do you think the designers left them disconnected?
- What does the delay structure tell you about the game's pacing?
- If you could add one connection, what would it be and why?

**Suggested games for this exercise (all widely available, under $30):**
- *Hades* — action roguelike with clean per-run and meta-progression loops
- *Slay the Spire* — deckbuilder with visible card economy and relic interactions
- *Stardew Valley* — farming sim with dense resource web and time pressure
- *Civilization VI* — strategy with layered economies and long-term feedback loops
- *Into the Breach* — tactical with minimal systems but dense spatial interactions
- *Balatro* — poker roguelike with multiplicative scoring systems
- Any board game you know well (Settlers of Catan, Wingspan, Terraforming Mars)

---

### Exercise 2: Break It and Fix It — Feedback Surgery

**Time:** 45-60 minutes
**Materials:** Paper for diagrams, notes for writing
**Deliverable:** Diagnosis document with before/after loop diagrams and written analysis

Think about a game where you've experienced a **runaway leader problem**, a **death spiral**, or a **stagnation problem**. You'll diagnose the broken feedback structure and redesign it.

**Steps:**

1. **Name the problem.** Write one sentence describing the experience: "In [game], [problem] happens because [observation]."
   Example: "In Monopoly, the game feels decided after 30 minutes because whoever acquires the first monopoly snowballs to an insurmountable lead."

2. **Diagram the current feedback structure.** Draw the relevant loops using boxes and arrows. Label each loop as positive or negative. Use the Loop Balance Audit format:
   - List all positive loops
   - List all negative loops
   - Note which positive loops have no matching brake

3. **Identify the root cause.** Circle the specific loop or missing loop that causes the problem. Write one sentence: "The root cause is [specific loop issue]."

4. **Design your fix.** Add, remove, or modify one feedback mechanism. Be specific:
   - What triggers it?
   - What stock does it affect?
   - How strong is the effect?
   - Does it apply to all players or only to leading/trailing players?

5. **Diagram the fixed structure.** Redraw the loop diagram with your change. Use a different color for the new/modified element.

6. **Predict second-order effects.** Your fix changes the system. Answer:
   - Does your fix create any new degenerate strategies? (e.g., if you punish leading, do players now try to stay in second place?)
   - Does your fix affect a system you didn't intend to change?
   - Would your fix change the game's identity? (e.g., if you remove Monopoly's snowball, is it still Monopoly?)

7. **Write a 200-300 word summary** explaining your diagnosis and fix. This should be clear enough that someone unfamiliar with the game could follow your reasoning.

**Tips for a strong analysis:**
- Be specific about magnitudes. "Add a catch-up mechanic" is vague. "Trailing players earn 50% bonus resources for 3 turns after falling more than 20% behind" is a concrete, testable proposal.
- The best fixes are the smallest ones. If you need to redesign three systems to fix one problem, you're probably not targeting the root cause. Find the single broken link and fix that.
- Don't be afraid to conclude that the game's design *intentionally* chose this tradeoff. Monopoly's runaway leader problem isn't a bug — the game was designed to illustrate the dangers of monopolistic capitalism. Sometimes a "broken" loop is serving a design purpose you didn't initially see.

---

### Exercise 3: Build a Tiny Emergent Game

**Time:** 90-120 minutes
**Materials:** Index cards (20+), six-sided dice (2-3), tokens or coins (20+), a sheet of paper for the game board, pen/markers. Optionally: a second player for testing.
**Deliverable:** A playable paper prototype with rules document, at least 3 interconnected systems, and a playtest report

Design and build the smallest possible game that produces genuine emergent behavior.

**Steps:**

1. **Choose a theme.** Keep it simple. Examples: a village surviving winter, robots fighting in an arena, ships trading between islands, bacteria spreading in a petri dish. The theme is scaffolding — it helps you name your systems but shouldn't constrain them.

2. **Define exactly 3 systems.** Each system should have 1-2 rules. Write each system on its own index card with a clear title and rule statement.

   Example systems for "village surviving winter":
   - **Food System:** Each villager eats 1 food per turn. If food reaches 0, one villager dies.
   - **Gathering System:** Each living villager can gather 1 food OR 1 wood per turn (not both). Roll a die: 4+ succeeds.
   - **Warmth System:** Each turn without wood fuel, the cold tracker advances by 1. At cold level 3, gathering difficulty increases (need 5+ instead of 4+). At cold level 5, villagers eat 2 food instead of 1.

3. **Connect the systems.** Draw a quick system map showing how each system's outputs feed into the others. Verify that every system connects to at least one other system. Verify at least one feedback loop exists.

   Example connections:
   - Food System --> Gathering System (fewer villagers = less gathering capacity = less food. Positive loop / death spiral.)
   - Warmth System --> Gathering System (cold increases difficulty)
   - Warmth System --> Food System (extreme cold increases food consumption)
   - Gathering System --> both Food and Warmth (wood or food, mutually exclusive — creates a tension)

4. **Build the prototype.** Set up your game board, tokens, and cards. Write a one-page rules sheet. Keep it under 200 words.

5. **Playtest solo for 3-5 rounds.** Play through the game, making decisions each turn. After each round, note:
   - What surprised you?
   - Did any outcome feel emergent (not directly designed)?
   - Was any decision meaningfully difficult?

6. **Iterate once.** Based on your playtest, change one rule. Maybe gathering is too easy (change the dice threshold), or the death spiral is too fast (add a food reserve), or there's no comeback mechanism (add a "lucky find" event on a natural 6). Play 3-5 more rounds with the new rule.

7. **Write a playtest report (200-300 words):**
   - What emergent moments occurred?
   - Which system connection generated the most interesting interactions?
   - What was the dominant strategy? Is it degenerate, or is it healthy optimization?
   - If you iterated further, what would you change next?

**Bonus:** If you have a second player, play 3 rounds against them or cooperatively. Multiplayer introduces a system you didn't design: the other player's strategy. Note what emergence arises from player interaction with your systems.

**What success looks like:** A successful prototype is one where you can point to at least one moment that surprised you — something that happened because the systems interacted in a way you didn't explicitly plan. If everything that happened was exactly what your rules prescribed with no surprises, your systems aren't connected enough. Add another connection and try again.

**What failure looks like (and why it's useful):** If your game immediately devolves into a death spiral (one bad roll and everything collapses), or if there's an obvious dominant strategy (always gather food, never gather wood), you've learned something valuable about feedback loops. Diagnose the failure using the autopsy format from section 9 and iterate.

---

### Exercise 4: Emergence Spotter's Journal

**Time:** 15 minutes per session, ongoing (aim for at least 4 entries over 2 weeks)
**Materials:** A notebook, note-taking app, or shared document
**Deliverable:** A collection of 4+ documented emergent moments with system-chain analysis

This is a habit exercise. Every time you play a game and experience a moment that feels emergent — surprising, unscripted, caused by system interactions — stop and document it.

**For each entry, record:**

1. **The game and the moment.** Describe what happened in 2-3 sentences. Be specific.
   Example: "In Slay the Spire, I played Corruption (all skills cost 0 but exhaust) with Dead Branch (gain a random card whenever a card is exhausted). Every skill I played was free and generated a new random card. My hand refilled faster than I could empty it."

2. **The system chain.** Trace the cause-effect chain that produced this moment. Name each system involved.
   Example: "Card cost system (Corruption makes skills cost 0) --> exhaust system (skills are removed after playing) --> relic system (Dead Branch triggers on exhaust) --> card generation system (new card added to hand) --> hand size system (hand overflows with options). Five systems, one chain."

3. **Was it positive or negative emergence?** Did the moment make the game more interesting (you discovered something new, a memorable story emerged) or did it break the game (you found an exploit, the game became trivially easy)?
   Example: "Positive in the moment — the combo felt incredible and made me feel clever. But it also trivialized the rest of the run. Borderline degenerate."

4. **The design lesson.** What would you take from this moment if you were designing a similar game?
   Example: "Dead Branch is a card-generation engine that scales with cards-played-per-turn. Any other mechanic that increases cards-played-per-turn (like Corruption) will interact multiplicatively. Lesson: watch for mechanics that share a scaling axis — they'll combine explosively."

**After 4+ entries,** review your journal. Do you see patterns? Are certain types of systems more likely to produce emergence? Do you gravitate toward positive emergence or do you tend to spot exploits? This meta-observation tells you about your design instincts.

**Group variation:** If you're studying with others, share entries weekly. Compare: did someone else find an emergent moment in a game you thought was purely scripted? Their observation teaches you to look harder.

**Why this exercise matters:** System mapping and feedback analysis are analytical skills — you learn them by studying. But *noticing* emergence in real-time is a perceptual skill — you learn it by practicing awareness. The Spotter's Journal trains your eye to see system interactions as they happen, which is the single most valuable skill for an emergent-systems designer. After a few weeks of journaling, you'll find yourself seeing system chains automatically, even in non-game contexts. That's when you know the lens has stuck.

---

## Recommended Reading

### Essential

- **"Thinking in Systems: A Primer"** -- Donella Meadows. *The* book on systems thinking. Written for a general audience, not game designers, but every concept maps directly to game design. Short, clear, essential. Read chapters 1-3 at minimum.
- **"Rules of Play: Game Design Fundamentals"** -- Katie Salen & Eric Zimmerman. Chapters 13-15 cover systems and emergence in a game-specific context. Dense but foundational.
- **"A Theory of Fun for Game Design"** -- Raph Koster. Frames games as systems that teach pattern recognition. Short read, deeply relevant to understanding why emergence feels good.

### Go Deeper

- **"Emergent Gameplay" (GDC talk)** -- Harvey Smith & Randy Smith. Classic talk on designing for emergence from the team behind *Deus Ex*. Available on the GDC Vault.
- **"Designing Emergent AI"** -- Alex J. Champandard. Explores how AI systems contribute to emergence, with practical implementation guidance.
- **"Dwarf Fortress Design Lessons"** -- Tarn Adams' various GDC talks and interviews. Primary source on the most ambitious emergent simulation ever built.
- **"Complexity and Game Design"** -- various Game Developer / Gamasutra articles on balancing emergence with playability. Search for articles by Daniel Cook and Joris Dormans.
- **"Machinations: Game Feedback Diagrams"** -- Joris Dormans. A formal framework for diagramming game economies and feedback loops. Pairs directly with the system mapping methodology in this module. Free web tool available at machinations.io.

### Play These (Best-in-Class Emergent Design)

If you haven't played them, these games are the best way to *feel* the concepts in this module. All are under $30 and available on PC.

- **Into the Breach** (~$15) — minimum viable emergence. Perfect information, tiny grid, massive depth.
- **Slay the Spire** (~$25) — emergence through card and relic synergy. Every run tells a different story through the same mechanics.
- **Hades** (~$25) — emergence in an action context. Boon interactions create unique builds every run.
- **Factorio** (~$35, but frequently on sale) — recursive composition of one system type. If you have 20 hours to spare, this game will teach you more about systems thinking than any book.
- **Divinity: Original Sin 2** (~$25 on sale) — surface system combinatorics at their best. Bring friends for maximum chaos.

---

## Key Takeaways

1. **Systems thinking is a vocabulary.** Stocks, flows, delays, feedback loops — learn these terms and you'll see game mechanics in a fundamentally different way. Every game is a collection of bathtubs connected by pipes.

2. **Emergence comes from connections, not complexity.** Six simple systems deeply connected to each other produce more interesting gameplay than twenty complex systems operating in isolation. Design the connections first.

3. **Balance positive and negative feedback.** Positive feedback creates momentum and drama. Negative feedback creates tension and comebacks. You need both. The art is in the ratio and the timing.

4. **Design tools, not scripts.** Give players verbs and let them write their own sentences. The most memorable moments in games are the ones players created themselves through system interactions.

5. **Map it to see it.** The 8-step system mapping method works on any game. Use it to study games you admire, diagnose games that frustrate you, and plan games you're building. If you can't draw the system map, you don't yet understand the design.

6. **Emergence scales across game sizes.** *Dwarf Fortress* and *Into the Breach* both produce emergence. One simulates thousands of interacting entities; the other uses 3 units on an 8x8 grid. What they share is not scope but structure: visible systems, meaningful connections, and verbs that interact with context.

7. **Playtest for degeneration.** Emergence is a double-edged sword. The same interconnected systems that produce brilliant moments also produce broken exploits. Assume your players are smarter than you and test accordingly.

---

## What's Next

- **Missed the foundation?** Go back to [Module 1: The Anatomy of a Mechanic](./module-01-anatomy-of-a-mechanic.md) -- you'll need a solid grasp of what makes a mechanic work and how mechanics interact before systems thinking fully clicks.
- **Ready to move forward?** [Module 3: Player Psychology & Motivation](./module-03-player-psychology-motivation.md) explores *why* players engage with systems — intrinsic vs. extrinsic motivation, flow states, and the psychology of reward.
- **Want to see systems thinking applied to economies?** Jump to [Module 5: Game Economy & Resource Design](./module-05-game-economy-resource-design.md) for the quantitative side — how to tune feedback loops, balance interconnected economies, and keep degenerate strategies in check.
- **Want to see emergence in level design?** [Module 4: Level Design & Pacing](./module-04-level-design-pacing.md) covers how spatial design and systemic design intersect — when to give players authored spaces and when to let systems shape the environment.
- **Interested in the player experience side?** [Module 6: Difficulty, Challenge & Fairness](./module-06-difficulty-challenge-fairness.md) explores how feedback loops interact with difficulty curves — essential reading if you're tuning how hard or forgiving your emergent systems feel.
