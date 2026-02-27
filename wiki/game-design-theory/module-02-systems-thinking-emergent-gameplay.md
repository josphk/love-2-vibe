# Module 2: Systems Thinking & Emergent Gameplay

> **Goal:** Understand how simple rules create complex, unpredictable experiences — and how to design games that surprise even you.

**Prerequisites:** [Module 1 — Core Design Principles](./module-01-core-design-principles.md)
**Time Estimate:** 3–4 hours (reading + exercises)
**Difficulty:** Intermediate

---

## Overview

Here's a secret most players never think about: the best moments in games were never designed. Nobody at Ludeon Studios scripted the exact moment your pyromaniac colonist snaps during a raid and sets the kitchen on fire, starving your colony three days later. Nobody at Nintendo planned the specific sequence where you roll a boulder downhill, launch it off a ramp with an explosion, and use it to crush a Lynel. Those moments **emerged** from systems interacting with each other.

This module teaches you to think in systems. You'll learn the vocabulary — **stocks, flows, feedback loops** — and then see how connecting simple systems together produces gameplay that's infinitely more interesting than anything you could hand-script. You'll study games that do this brilliantly, identify the pitfalls that wreck emergent design, and practice mapping systems yourself.

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

Understanding stocks, flows, and delays is the foundation. Every concept that follows builds on this vocabulary.

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

The key insight: **emergence is not randomness.** Random events feel arbitrary. Emergent events feel *logical* — you can trace the cause-and-effect chain backward and say "of course that happened." The pyromaniac set the fire because they had the pyromaniac trait, because they were stressed, because a raid killed their friend, because your defenses were weak, because you prioritized research over walls. Every link in that chain is a system doing its job.

That traceability is what makes emergent moments feel like *stories* rather than *noise*.

---

### 3. Positive Feedback Loops

A **positive feedback loop** (also called a **reinforcing loop**) amplifies change. Whatever direction things are moving, a positive loop pushes them further in that direction. Rich get richer. Losing gets worse.

**The structure:** A change in stock A increases stock B, which increases stock A further.

**Example 1 — *Monopoly*:** You buy property. Property generates rent. Rent gives you money. Money lets you buy more property. This is why *Monopoly* games feel decided halfway through — the positive feedback loop snowballs the leader so far ahead that catching up becomes impossible. (This is also why *Monopoly* is, frankly, a poorly balanced game.)

**Example 2 — *StarCraft II*:** You expand to a second base early. More bases mean more resource income. More income means a bigger army. A bigger army means you can protect expansions and take more bases. Top players exploit this loop aggressively — the concept of "macro" is fundamentally about engaging the positive feedback loop faster than your opponent.

**Example 3 — *Slay the Spire*:** You pick up a strong card synergy early in Act 1. That synergy lets you beat elites. Beating elites gives you better relics. Better relics amplify your synergy. By Act 3, you're an unstoppable engine — if the loop kicked in early enough. If it didn't, you're dead.

**When positive loops work:** They create satisfying power fantasies, reward skillful play, and give games a sense of momentum and escalation. They're the reason "snowballing" feels great *when you're the one snowballing*.

**When positive loops break games:** Unchecked positive feedback creates **runaway leaders** and **death spirals**. If the player who's ahead always gets further ahead, the outcome is decided early and everyone else is just going through the motions. If losing makes you weaker and weakness makes you lose more, players trapped in a death spiral have a miserable time.

---

### 4. Negative Feedback Loops

A **negative feedback loop** (also called a **balancing loop**) resists change. It pushes systems back toward equilibrium. It's the thermostat — when things get too hot, it kicks in the AC.

**The structure:** A change in stock A triggers a response that reduces stock A back toward a target level.

The most famous example in all of gaming: **the Blue Shell in *Mario Kart*.** The player in last place gets the most powerful item. It targets the player in first place. This is a textbook negative feedback loop — it punishes the leader and compresses the field.

**Rubber banding** is the general term for negative feedback mechanics that help trailing players catch up. You'll find it everywhere:

- **Racing games** give speed boosts to trailing cars (sometimes literally through the AI's physics).
- **Mario Party** gives better items to players in last place.
- **Catch-up experience** in MMOs and ARPGs lets underleveled players gain XP faster.
- **Dynamic difficulty adjustment** in games like *Resident Evil 4* secretly makes the game easier when you're struggling.

**When negative loops work:** They keep games competitive, extend tension, and give every player a chance. A close race is more exciting than a blowout. Negative feedback ensures that close races happen more often.

**When negative loops go wrong:** If overdone, they make skill feel irrelevant. Why try hard if the game is going to equalize everyone anyway? Players resent feeling punished for doing well. The Blue Shell is probably the most complained-about item in gaming history for exactly this reason — it feels like the game is punishing success.

The worst case: **stagnation**. If negative feedback is too strong, nobody can ever pull ahead, and the game feels like running on a treadmill. Nothing you do matters because the system always yanks you back to the middle.

---

### 5. Balancing Loops

Great game design is about **mixing positive and negative feedback** so that neither dominates. You want momentum (positive) but also tension (negative). You want snowballing but also comebacks.

Here's the secret formula that many well-designed competitive games use:

> **Positive feedback creates the drama. Negative feedback keeps the game alive long enough for that drama to play out.**

**Example — *League of Legends*:** Killing enemies gives you gold (positive feedback — you're stronger, so you kill more). But death timers increase as the game goes on (negative-ish — losing a fight late game costs more time). Turrets provide safe zones for the losing team (negative — the ahead team can't just chase you forever). The bounty system puts a price on the head of the player who's dominating (negative — killing the fed player gives a massive reward). The result: games have momentum shifts, dramatic comebacks, and tense endgames.

**The design principle:** Let positive feedback loops operate in the **short term** (winning a fight should feel rewarding and create momentum) but introduce negative feedback in the **long term** (preventing any single advantage from becoming permanent). This creates games with **arcs** — rising action, climaxes, reversals — rather than monotone snowballs or flat stalemates.

Think of it as designing a story structure through mechanics rather than scripts.

---

### 6. Interconnected Systems

This is where emergence really starts cooking. A single feedback loop is interesting. **Ten feedback loops connected together** is a living world.

The principle is simple: **System A's output becomes System B's input.** Chain enough of these connections together and you get behavior that no single system could produce alone.

**The *Dwarf Fortress* chain** is legendary:

Weather → Crop Growth → Food Supply → Dwarf Mood → Work Productivity → Construction Speed → Defense Quality → Survival During Siege → Population → Labor Pool → Crop Tending → back to Crop Growth

Every arrow in that chain is a system. Every connection is a place where unexpected things can happen. A volcanic eruption (weather system) destroys crops (food system), which drops mood (psychology system), which causes a dwarf to go berserk (mental break system), which injures other dwarves (combat system), which strains your hospital (medical system), which pulls dwarves away from the walls they were building (labor system), which leaves a gap in your defenses (military system) just as a goblin siege arrives.

Nobody designed that story. Eleven systems, each simple on its own, connected together to create a tragedy.

**The key design lesson:** You don't need each individual system to be complicated. You need the **connections** between systems to be rich. A weather system that only affects visuals is decoration. A weather system that affects crops, movement speed, combat accuracy, and mood is a *generator of stories*.

When you're designing interconnected systems, ask yourself: **"What else should this affect?"** Every time you connect one more system to the web, you multiply the possible emergent outcomes.

---

### 7. Designing for Emergence

So how do you actually design a game that produces emergence? The core philosophy is **constraint-based design**: give players tools and rules, not scripts and corridors.

**Principle 1 — Design verbs, not events.** Don't design "the player blows up the bridge." Design "the player has explosives" and "bridges are destructible." Let the player figure out the bridge part — and also figure out blowing up walls, floors, enemies, and their own escape route.

**Principle 2 — Make systems visible.** Players can only engage with emergence if they can see the systems operating. *Breath of the Wild* makes its physics visible — you can see fire spread, see wind blow grass, see lightning strike metal. If your systems are hidden, players can't experiment with them.

**Principle 3 — Reward experimentation.** If there's one optimal path, players will find it and emergence dies. Design systems where multiple approaches work so players are motivated to try weird combinations. *Divinity: Original Sin 2* rewards players who combine elements in creative ways — electrifying water, freezing blood, igniting poison clouds.

**Principle 4 — Accept loss of authorial control.** This is the hardest one. Emergent design means you can't control the player's experience. They'll do things you never imagined. They'll break your systems in hilarious and horrifying ways. That's the *point*. If you need to control every moment, emergence isn't your tool.

**Principle 5 — Playtest for degenerate strategies** (more on this in section 9). Emergence is a double-edged sword — it generates brilliant moments AND broken exploits.

---

### 8. The Butterfly Effect in Games

In chaos theory, the butterfly effect describes how tiny changes in initial conditions produce wildly different outcomes. Games with interconnected systems exhibit this constantly.

**In *XCOM 2*:** You miss a 95% shot. That miss means the alien survives. The surviving alien flanks your medic. Your medic dies. Without healing, your squad crumbles. The mission fails. You lose a region. Losing a region triggers the Avatar Project progress. The campaign spirals. All from one missed shot.

**In *Crusader Kings III*:** You choose to educate your heir yourself instead of assigning a guardian. Your heir picks up your character's traits. One of those traits makes them cruel. When they inherit the throne, their cruelty triggers a vassal rebellion. The rebellion fractures your kingdom. Three generations later, the dynasty you built is a collection of warring splinter states. All because of one education decision.

**In *Factorio*:** You place your smelting column three tiles to the left. That leaves just enough room for a belt between it and the wall. Twenty hours later, you need that exact gap to route your oil pipeline. If you'd placed it differently, you'd need to tear down half your factory. Small spatial decisions compound into massive structural consequences.

The butterfly effect is what makes emergent games endlessly replayable. The same starting conditions produce different stories every time because tiny variations compound through interconnected systems. It's also what makes them hard to balance — you can't predict every cascade.

---

### 9. Degenerate Strategies

Here's the dark side of emergence: sometimes systems interact to produce a **dominant strategy** that's so effective, there's no reason to do anything else. When that happens, emergence dies — because everyone does the same thing.

A **degenerate strategy** is an approach that exploits system interactions to bypass intended challenges, reducing a complex game to a simple, repetitive action.

**Examples:**

- **"Stealth archer" in *Skyrim*:** The combination of stealth damage multipliers, archery range, and AI detection systems means that crouching and shooting arrows is absurdly more effective than any other playstyle. The systems are working as designed — but their interaction produces a strategy so dominant it collapses build diversity.
- **Tower rushing in early RTS games:** Building offensive structures in the enemy base exploited the gap between construction speed and early-game army production. The systems (building, economy, combat) all worked individually, but their interaction at a specific timing window created an unintended dominant play.
- **Infinite combos in fighting games:** When the stun system, damage system, and move-cancel system interact to allow a single hit to lead to an unavoidable kill combo, one system interaction overrides the entire competitive structure of the game.

**How to fight degenerate strategies:**

- **Introduce counters.** If strategy A dominates, make sure strategy B beats A (and C beats B, and A beats C). Rock-paper-scissors dynamics resist degeneration.
- **Add diminishing returns.** If stacking one stat is too strong, make each additional point worth less. Path of Exile does this with resistance stacking.
- **Playtest adversarially.** Hire players whose explicit job is to break your game. Speedrunners and min-maxers find degenerate strategies within hours.
- **Patch and iterate.** Live games can observe degenerate strategies forming in the wild and rebalance. *Slay the Spire*, *Hades*, and *Balatro* all went through extensive balance iteration during early access.

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

Each of these systems is relatively simple. Fire burns flammable things. Metal conducts electricity. These are elementary rules. But because **every system connects to every other system**, the combinatorial explosion is enormous.

A player encounters a camp of enemies on a wooden platform over a lake. Here are just some of the possible approaches that emerge from system interactions alone: set the platform on fire with a fire arrow and let it collapse; throw a metal weapon into the water and strike it with lightning; use a wind-creating item to blow explosive barrels into the camp; freeze the lake surface, slide bombs across the ice, and detonate them at the base of the platform; drop metal equipment near enemies during a thunderstorm and wait for lightning to strike.

None of these solutions were hand-authored as puzzle solutions. The designers built the systems, connected them, and let players discover the possibilities. The game's shrines (puzzle rooms) work the same way — each shrine teaches you a system, and the overworld lets you combine everything you've learned.

**Why it works so well:** The systems are **visible and predictable**. You can see fire. You can see wind. You can see rain. Because you understand the individual rules, you can reason about combinations. The moment of emergence feels like *your* discovery, not the game's trick. That sense of creative ownership is what makes players record clips and share them — they feel like inventors, not followers.

**The design lesson:** You don't need dozens of complex systems. You need a handful of simple systems with clear, visible rules and rich connections between them. *Breath of the Wild* proves that elegance of connection matters more than complexity of individual parts.

---

### Case Study 2: Dwarf Fortress — The Emergent Narrative Machine

*Dwarf Fortress* (first released 2006, Steam version 2022) is the most ambitious emergent system ever built for a game. It simulates geology, hydrology, weather, ecology, agriculture, economics, combat (down to individual body parts and tissue layers), psychology, social relationships, history, mythology, and more. Each of these is a fully modeled system. And they're all connected.

**The scope of simulation:**

Every dwarf has individual personality traits, preferences, memories, relationships, skills, and moods. The mood system alone tracks dozens of factors: did they eat food they like? Do they have a nice bedroom? Have they seen a dead body recently? Did they talk to a friend? Is their clothing tattered? Each factor nudges mood up or down, and mood determines behavior — content dwarves work efficiently, while miserable dwarves may throw tantrums, start fights, or descend into permanent madness.

This mood system connects to *everything*. A dwarf who's a talented craftsman needs to create things regularly or they get restless (personality → labor system). If they're not assigned to a workshop, their mood drops (labor → mood). If their mood drops far enough, they might start a fight (mood → combat). If they injure another dwarf, that dwarf's friends get upset (combat → social → mood). If enough dwarves are upset, productivity drops (mood → labor → economy). If the economy falters, food runs short (economy → food). If food runs short, *everyone's* mood drops (food → mood). One unhappy craftsman can spiral into a colony-wide collapse.

**The emergent narratives:**

Players don't just play *Dwarf Fortress* — they tell stories about it. The game's community is built on sharing narratives that the systems generated. A fortress where the mayor mandated the production of an item nobody knew how to make, leading to a tantrum spiral, leading to the mayor being locked in a room, leading to a forgotten beast breaking through the floor of that exact room. A dwarf who, driven mad by grief, created a legendary artifact and then walked calmly into a river. These read like authored fiction, but they're system outputs.

**Why it works:** Tarn Adams (the developer) designed each system to be **internally consistent and externally connected**. The combat system doesn't know about the mood system, but the mood system knows about combat. The weather system doesn't know about the food system, but the food system knows about weather. Each system does one job well and exposes its outputs for other systems to consume. This modular-but-connected architecture is what allows dozens of systems to interact without becoming an unmaintainable mess.

**The tradeoff:** *Dwarf Fortress* is famously difficult to learn, partially because the interconnected systems are often **invisible**. You can't always see why a dwarf is upset or why your food production dropped. The game demonstrates that emergence needs visibility — the more transparent your systems, the more players can engage with (and appreciate) the emergent outcomes.

---

## Common Pitfalls

### 1. The Kitchen Sink Problem
You add system after system thinking more connections equals more emergence. But each new system multiplies your testing surface exponentially. **Start with 3–4 systems, connect them deeply, and only add new ones when the existing connections are solid.** *Breath of the Wild* uses maybe six core material properties. That's enough.

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

---

## Exercises

### Exercise 1: System Mapping

**Time:** 45–60 minutes
**Materials:** Paper and pen (or a whiteboard/diagramming tool)

Pick a game you know well — *Stardew Valley*, *Civilization*, *Hades*, *RimWorld*, anything with multiple interacting systems. Map it:

1. **Identify 5–8 major systems** (combat, economy, mood, weather, crafting, etc.). Draw each as a labeled box.
2. **Draw arrows** showing how each system's outputs feed into other systems' inputs. Label each arrow with what flows along it (gold, damage, mood modifier, etc.).
3. **Identify feedback loops.** Trace paths that circle back to their origin. Label each as positive (reinforcing) or negative (balancing).
4. **Find the most connected node.** Which system has the most arrows going in and out? That's probably the system that generates the most emergence.
5. **Identify one missing connection.** Where could you add an arrow to create new emergent possibilities?

Share your diagram with someone who knows the game and see if they spot connections you missed.

---

### Exercise 2: Feedback Loop Redesign

**Time:** 30–40 minutes
**Materials:** Notes or a document

Think about a game where you've experienced a runaway leader problem or a stagnation problem.

1. **Describe the broken loop.** Is it positive feedback running unchecked? Negative feedback that's too aggressive?
2. **Diagram the current loop** with stocks and flows.
3. **Design a fix.** Add, remove, or modify one feedback mechanism to improve the dynamic. Be specific — what triggers it, what does it affect, how strong is it?
4. **Predict the second-order effects.** Your fix changes the system. What else changes as a result? Does your fix create any new problems?

Write up your analysis in 300–500 words. The goal is to practice thinking about systems as interconnected wholes, not isolated parts.

---

### Exercise 3: Minimum Viable Emergence

**Time:** 60–90 minutes
**Materials:** Paper prototype materials (index cards, dice, tokens) OR a simple game engine

Design the smallest possible game that produces emergent behavior:

1. **Create exactly 3 systems.** Each system should have 1–2 rules. Keep them dead simple.
2. **Connect the systems** so that each one's output affects at least one other.
3. **Include at least one feedback loop** (positive or negative).
4. **Playtest it** (solo or with someone). Play at least 3 rounds.
5. **Document** what surprised you. Did any outcome occur that you didn't design? That's emergence.

Example starting point: a grid-based game where (1) fire spreads to adjacent tiles each turn, (2) wind pushes fire in one direction, and (3) water tiles block fire but evaporate if adjacent to fire for two turns. Three systems, interconnected, with feedback. What stories does it tell?

---

## Recommended Reading

### Essential

- **"Thinking in Systems: A Primer"** — Donella Meadows. *The* book on systems thinking. Written for a general audience, not game designers, but every concept maps directly to game design. Short, clear, essential. Read chapters 1–3 at minimum.
- **"Rules of Play: Game Design Fundamentals"** — Katie Salen & Eric Zimmerman. Chapters 13–15 cover systems and emergence in a game-specific context. Dense but foundational.
- **"A Theory of Fun for Game Design"** — Raph Koster. Frames games as systems that teach pattern recognition. Short read, deeply relevant to understanding why emergence feels good.

### Go Deeper

- **"Emergent Gameplay" (GDC talk)** — Harvey Smith & Randy Smith. Classic talk on designing for emergence from the team behind *Deus Ex*. Available on the GDC Vault.
- **"Designing Emergent AI"** — Alex J. Champandard. Explores how AI systems contribute to emergence, with practical implementation guidance.
- **"Dwarf Fortress Design Lessons"** — Tarn Adams' various GDC talks and interviews. Primary source on the most ambitious emergent simulation ever built.
- **"Complexity and Game Design"** — various Game Developer / Gamasutra articles on balancing emergence with playability. Search for articles by Daniel Cook and Joris Dormans.

---

## Key Takeaways

1. **Systems thinking is a vocabulary.** Stocks, flows, delays, feedback loops — learn these terms and you'll see game mechanics in a fundamentally different way. Every game is a collection of bathtubs connected by pipes.

2. **Emergence comes from connections, not complexity.** Six simple systems deeply connected to each other produce more interesting gameplay than twenty complex systems operating in isolation. Design the connections first.

3. **Balance positive and negative feedback.** Positive feedback creates momentum and drama. Negative feedback creates tension and comebacks. You need both. The art is in the ratio and the timing.

4. **Design tools, not scripts.** Give players verbs and let them write their own sentences. The most memorable moments in games are the ones players created themselves through system interactions.

5. **Playtest for degeneration.** Emergence is a double-edged sword. The same interconnected systems that produce brilliant moments also produce broken exploits. Assume your players are smarter than you and test accordingly.

---

## What's Next

- **Missed the foundation?** Go back to [Module 1: Core Design Principles](./module-01-core-design-principles.md) — you'll need a solid grasp of feedback, game feel, and player motivation before systems thinking fully clicks.
- **Ready to move forward?** [Module 3: Player Psychology & Motivation](./module-03-player-psychology-motivation.md) explores *why* players engage with systems — intrinsic vs. extrinsic motivation, flow states, and the psychology of reward.
- **Want to see systems thinking applied to balance?** Jump to [Module 5: Game Balance & Economy Design](./module-05-game-balance-economy-design.md) for the quantitative side — how to tune feedback loops, balance interconnected economies, and keep degenerate strategies in check.
