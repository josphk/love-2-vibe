# Module 1: The Anatomy of a Mechanic

**Part of:** [Game Design Theory Roadmap](game-design-theory-roadmap.md)
**Estimated study time:** 4-6 hours
**Prerequisites:** [Module 0: What Is Game Design](module-00-what-is-game-design.md) (recommended)

---

## Overview

Every game you have ever loved is, at its core, a collection of **mechanics** — rules that define what you can do, and what happens when you do it. The difference between a forgettable game and one that consumes your weekend is rarely about graphics, story, or even "content." It is almost always about how well the mechanics are designed.

This module teaches you to see mechanics the way a watchmaker sees gears. You will learn to identify the **core mechanic** that holds a game together, the **supporting mechanics** that give it texture, and the interactions between them that create **emergent depth**. You will also learn to evaluate whether a mechanic is pulling its weight or just adding noise.

These principles apply whether you are building a platformer, a card game, or an open-world RPG. Get this right and everything else — systems, balance, feel, progression — has a foundation. Get it wrong and no amount of polish will save you.

---

## Core Concepts

### 1. What Is a Mechanic?

**Definition:** A **mechanic** is a **verb** (something the player does) combined with a **consequence** (what the game does in response). "Press A to jump" is a mechanic. "Collect three stars to unlock the door" is a mechanic. "Place a card, spend energy" is a mechanic.

**Why it matters:** If you cannot articulate your mechanics as verb-consequence pairs, you do not yet understand your own game. This framing separates what the player *does* from what the player *sees* or *feels* — those come later (see the MDA Framework below).

**Examples:**
- **Celeste:** Dash (verb) in a direction, consuming your one air-dash charge (consequence). Touch the ground to restore it (reset rule).
- **Tetris:** Rotate and place a falling block (verb). Completed rows disappear and award points (consequence).
- **Into the Breach:** Move a mech to a tile (verb). The projected damage and knockback resolve at end of turn (consequence). The consequence is *visible before you act*, which is itself a design choice layered on top of the base mechanic.

**Common mistake:** Confusing a mechanic with a feature. "Crafting system" is not a mechanic — it is a *collection* of mechanics (gather resources, combine resources, receive item). Always drill down to the verb-consequence pair.

**Try this now:** Pick the game you played most recently. Write down three mechanics as verb-consequence pairs. If you struggle to name the verb, you have found a mechanic that might lack clarity.

---

### 2. Core Mechanics vs. Supporting Mechanics

**Definition:** The **core mechanic** is the action the player performs most frequently — the thing that *is* the game. **Supporting mechanics** are everything else: secondary actions and systems that make the core mechanic richer.

**Why it matters:** A weak core mechanic cannot be saved by excellent supporting mechanics. But a strong core with zero supporting mechanics gets boring fast. The relationship between them is where design lives.

**Examples:**

| Game | Core Mechanic | Supporting Mechanics |
|---|---|---|
| **Super Mario Bros.** | Jumping | Running (changes jump arc), stomping enemies, power-ups, scrolling level design |
| **Slay the Spire** | Playing cards from hand (spend energy) | Deck building, relic collection, enemy intent display, map pathing |
| **Factorio** | Placing machines/belts | Resource extraction, research tree, logistics networks, pollution/enemy aggro |
| **Hades** | Attacking enemies (in real-time) | Dash, boon selection, weapon aspects, room rewards, NPC relationships |
| **Baba Is You** | Pushing word-blocks | Rule formation from word sequences, level reset, undo |

Notice that the core mechanic is always something you can describe in under ten words. The supporting mechanics are where complexity creeps in — and that is fine, as long as each one is *earning its place* by creating new interactions with the core.

**Common mistake:** Treating all mechanics as equally important. If you cannot name which one is core, your design lacks focus. Players will feel it even if they cannot articulate it.

**Try this now:** Draw a diagram: core mechanic in the center, supporting mechanics radiating out. Draw lines between any two that interact. The densest web of connections points to the best-designed part of the game.

---

### 3. The MDA Framework

**Definition:** The **MDA Framework** (Mechanics, Dynamics, Aesthetics) is a formal model created by Hunicke, LeBlanc, and Zubek. It describes three layers of a game:

- **Mechanics** — the rules and systems you build (the code, the numbers, the verbs).
- **Dynamics** — the behavior that emerges when players interact with mechanics (what *actually happens* during play).
- **Aesthetics** — the emotional responses the player experiences (fun, tension, discovery, fellowship).

The critical insight: **designers work left to right (mechanics -> dynamics -> aesthetics), but players experience right to left (aesthetics -> dynamics -> mechanics).** You build rules. Those rules create behaviors. Those behaviors create feelings. The player feels first, then notices the behavior, and only sometimes understands the rule.

**Why it matters:** MDA gives you a diagnostic tool. When something feels wrong, trace it backward: bad aesthetic -> unwanted dynamic -> fixable mechanic.

**Concrete walkthrough — Slay the Spire:**

1. **Mechanic:** Each turn, you draw 5 cards and get 3 energy. Cards cost 0-3 energy to play. Unplayed cards are discarded. Your discard pile reshuffles into your draw pile when it runs out.
2. **Dynamic:** Because you see enemy intent (another mechanic), you must *plan* each turn — choosing between offense and defense. Because your deck reshuffles, every card you add will come back. This creates a tension between adding powerful cards and keeping your deck lean. Over the course of a run, your decisions compound.
3. **Aesthetic:** The player feels **strategic mastery** when a lean deck fires on all cylinders. They feel **tension** when they see a big attack incoming and must choose between blocking and setting up a kill. They feel **discovery** when a new relic completely reframes their deck's strategy.

Nowhere in the mechanics does it say "create tension." Tension *emerges* from the dynamics, which emerge from the mechanics. Feelings are engineered, not sprinkled on top.

**Common mistake:** Designing aesthetics directly. You cannot decide "my game will feel tense" and make it so. You build mechanics that produce dynamics that produce tension. Skipping layers leads to cutscenes that tell you the stakes are high while the gameplay has no actual risk.

**Try this now:** Pick a moment in a game that made you *feel* something strong. Trace it backward through MDA. What dynamic caused that feeling? What mechanic caused that dynamic?

---

### 4. Depth vs. Complexity

**Definition:** **Depth** is the number of meaningfully different situations, strategies, and decisions that emerge from a game's rules. **Complexity** is the number of rules, exceptions, stats, and systems the player must learn before they can play.

The holy grail of game design is **high depth, low complexity.** Simple rules that create rich, varied play.

**Why it matters:** Players do not want "more stuff." They want more *interesting decisions*. Complexity is a cost (rules to learn). Depth is a benefit (reasons to keep playing). Your job is to maximize the ratio.

**Examples:**

| Game | Complexity | Depth | Ratio |
|---|---|---|---|
| **Go** | ~5 rules | Astronomical (more board states than atoms in the universe) | Extraordinary |
| **Chess** | ~15 rules (piece movements, castling, en passant) | Immense | Excellent |
| **Tetris** | ~4 rules (pieces fall, rotate, complete rows clear, game over at top) | Very high (placement strategy, T-spins, combos, look-ahead) | Excellent |
| **A bad RPG with 47 stats** | Enormous (47 stats, each with scaling formulas, equipment bonuses, buff interactions) | Often low (one optimal build dominates) | Terrible |

Go is the canonical example. You place a stone. You capture groups with no liberties. You score territory. From those near-trivial rules, thousands of years of unsolved strategy emerge. That is depth.

Now picture an RPG with 47 stats where every build funnels into "stack Strength, ignore everything else." Enormous complexity, zero depth. The decision space is tiny — it is just hidden behind a wall of numbers.

**Common mistake:** Believing that "strategic depth" comes from adding more systems. It does not. Depth comes from *interactions between existing systems*. Before adding a new mechanic, ask: "How many new interactions does this create with what already exists?" If the answer is zero, you are adding complexity without depth.

**Try this now:** Think of a game you stopped playing because it felt shallow. Too few rules, or too few *interactions*? Now think of one you found impenetrable. Genuine depth, or complexity masquerading as depth?

---

### 5. Verbs and Nouns in Game Design

**Definition:** In game design vocabulary, a **verb** is an action the player can take (jump, shoot, build, trade, dash). A **noun** is an object the action applies to (enemy, block, card, tile, weapon). The combination of verbs and nouns defines the **possibility space** of your game.

**Why it matters:** You can create enormous variety by combining a small set of verbs with a large set of nouns — or vice versa. You do not need new actions to create new experiences. Sometimes you just need new *targets* for existing actions.

**Examples:**

- **Breath of the Wild:** A small verb set (climb, glide, magnesis, stasis, cryonis, bomb) applied to a massive noun set — every object in the world has physical properties. You can magnesis a metal box to build a bridge, use it as a weapon, or block projectiles. Same verb, different emergent dynamics.
- **Doom Eternal:** Each verb is tied to a resource (glory kill = health, chainsaw = ammo, flame belch = armor). Different demon types force you to constantly switch verbs. The intensity comes from verb-switching pressure.
- **Baba Is You:** The *verbs themselves are nouns* — physical word-blocks you push to rewrite the rules. Push words to form "ROCK IS YOU" and now you control the rock. The verb (push) is simple. The nouns (rule-defining words) create the puzzle.

**Common mistake:** Designing verbs in isolation. "You can hack any electronic device" sounds exciting until every hackable device does the same thing. Nouns need to respond differently to make the verb feel alive.

**Try this now:** List your game's verbs. For each, list every noun it can act on. Are there nouns only one verb touches? Could a different verb apply to that noun?

---

### 6. Evaluating a Mechanic

Not all mechanics are created equal. Here are six lenses for evaluating whether a mechanic is earning its place in your game:

**Feel (Game Feel / Juice):** Does the mechanic *feel good* to execute, independent of strategy? Celeste's jump feels precise before you encounter a single challenge. A mechanic with bad feel will never be loved, no matter how deep it is.

**Depth:** How many meaningfully different decisions does this mechanic enable? Blocking in a fighting game is simple, but *when* to block, *how long* to block, and *what to do after* blocking create enormous depth.

**Clarity:** Can the player understand what the mechanic does, what it costs, and what it achieves? Clarity does not mean simplicity — Chess is clear but not simple. If your mechanic regularly surprises the player in *unfair-feeling* ways, you have a clarity problem.

**Elegance:** Does the mechanic accomplish multiple design goals simultaneously? Mario's stomp is an attack, a movement option (bounce extends your jump), a risk-reward proposition, and a teaching tool. One mechanic, four jobs.

**Counterplay:** Can the opponent (or the game) respond meaningfully? A mechanic with no counterplay creates degenerate strategies. If something always works, there is no reason to do anything else.

**Interactivity:** How many other mechanics does this one connect to? A mechanic in isolation contributes complexity without depth. The best mechanics are *hubs* — they interact with many other systems simultaneously.

**Common mistake:** Evaluating on only one axis. A mechanic can feel incredible but have zero depth. A mechanic can be deeply strategic but feel terrible. You need to score well on *multiple* axes.

**Try this now:** Pick a mechanic in a game you love. Rate it from 1-5 on each of the six lenses above. Then pick a mechanic in a game you think is flawed. Rate that one too. Compare.

---

### 7. The One-Sentence Test

**Definition:** The **one-sentence test** asks: can you describe your game's core mechanic in a single, clear sentence? Not the theme, not the story, not the aesthetic — the *mechanic*. What the player *does*.

**Why it matters:** If you cannot pass this test, your design lacks focus. Every legendary game passes it:

- "You jump across platforms." (Mario)
- "You play cards from your hand, spending energy." (Slay the Spire)
- "You place and connect machines to automate production." (Factorio)
- "You rotate and drop falling blocks to complete rows." (Tetris)
- "You place stones on intersections to surround territory." (Go)
- "You shoot demons while managing health, ammo, and armor through combat verbs." (Doom Eternal)

These sentences are *boring*. That is the point. The magic is in the depth that emerges from this foundation. If your one-sentence description sounds exciting, you are probably describing dynamics or aesthetics, not mechanics.

**Common mistake:** Failing the test and justifying it. "My game is too complex to describe in one sentence" is a red flag, not a badge of honor. Dwarf Fortress, Europa Universalis, and Eve Online all have identifiable core mechanics. Complexity lives in *supporting* mechanics, not the core.

**Try this now:** Write the one-sentence description for a game you are working on. If you cannot, you may have a collection of mechanics with no center of gravity. Solve that before you build further.

---

## Case Studies

### Case Study 1: Mario's Jump

The entire Mario empire rests on a single mechanic: **the jump**. But calling it "a jump" understates what Nintendo actually built. Dissecting it reveals what separates a good mechanic from a legendary one.

**Variable height.** Tap the button for a short hop. Hold it to soar. This single parameter — jump height tied to hold duration — means every gap is a question of *how much* to jump, not just *whether* to jump.

**Momentum coupling.** Mario's jump arc changes based on horizontal speed. A standing jump is a vertical pop. A running jump covers huge distance. The jump mechanic and movement mechanic are *intertwined* — your approach speed is part of your jump. One interaction, enormous depth, no new rules.

**Air control.** Once airborne, you can still influence Mario's horizontal trajectory. Physically unrealistic, but absolutely essential to game feel. You can correct mid-jump, making the mechanic feel responsive rather than committal. Two players will jump differently even on the same gap.

**Coyote time.** For a few frames after walking off a ledge, you can still jump. The player never notices. They just feel the game is "fair." Invisible design, purely serving feel.

**The stomp.** Landing on an enemy kills it and gives a bounce. The jump becomes a combat mechanic — one verb, two jobs. Because stomping bounces you, skilled players chain enemy-stomps to reach "unreachable" areas. Emergent depth from two simple rules.

Mario's jump is not one mechanic. It is a *family* of carefully tuned parameters funneled through a single verb. The player presses one button. Underneath, a dozen variables interact. **Depth does not require complexity. It requires craft.**

---

### Case Study 2: Slay the Spire's Card Play

Slay the Spire became one of the most influential games of the 2010s with no multiplayer, no real-time action, and minimalist presentation. The reason is mechanical design.

**The core mechanic** is: each turn, draw 5 cards from your draw pile, get 3 energy, play cards by spending energy, discard the rest, end turn. That is it. Five sentences. A child could learn it in two minutes.

The depth comes entirely from how supporting mechanics interact with this core.

**Deck building as supporting mechanic.** After each combat, you choose a card to add (or skip). Every card dilutes your draw probability. A 15-card deck with 3 great cards draws them often. A 30-card deck with 10 great cards rarely draws the right one at the right time. Every card reward is also a potential curse. The "skip" button is one of the most important strategic tools in the game, and it does *nothing*.

**Relics as supporting mechanic.** Passive items that modify rules. A relic giving +1 energy per turn changes a single *number*, and that number changes every decision you make. With 4 energy, expensive cards become viable. Your entire deck-building strategy shifts. One number, cascading consequences.

**Enemy intent as supporting mechanic.** Enemies show you what they will do next turn. You can see a 32-damage attack coming and *choose*: block it (spend energy on defense) or race to kill first (spend energy on offense). Without intent display, combat is coin-flipping. With it, every turn is a genuine decision.

**The emergent result:** These supporting mechanics combine to create runs the designers never explicitly authored. You discover a combo between two cards and a relic that triples your damage. You realize that skipping every card reward makes your small deck a precision instrument. None of this was hand-scripted. It *emerged* from simple, well-designed mechanical interactions.

---

## Common Pitfalls

- **Adding mechanics instead of deepening existing ones.** When your game feels shallow, the instinct is to bolt on a new system. Resist it. First, ask whether your existing mechanics interact with each other enough. A new interaction between existing mechanics is almost always better than a new mechanic.

- **Confusing novelty with depth.** Novelty wears off in minutes. Depth sustains play for hundreds of hours. A well-executed proven mechanic (Hades' combat) outlasts a novel but shallow gimmick every time.

- **Designing the wrapper before the core.** Building progression, unlocks, and UI before your core mechanic is fun in isolation. If the raw action-consequence cycle is not satisfying with zero rewards, no meta-game will save it. Prototype the core first.

- **Ignoring feel.** A mechanic can be strategically perfect and feel terrible. If there is input delay, unclear animation, or no feedback — the player will not engage long enough to discover the depth. Feel is a prerequisite, not a luxury.

- **Complexity creep through "just one more rule."** Complexity is cumulative and nonlinear. Ten rules means 45 potential interaction pairs. Twenty rules means 190. The cognitive cost grows much faster than the mechanic count. Be ruthless about cutting.

- **Making the core mechanic too complex.** Your core mechanic must be learnable in seconds and masterable over the lifetime of the game. If your core mechanic requires a tutorial, it is too complex. The tutorial is for supporting mechanics. The core should be obvious.

---

## Exercises

### Exercise 1: The Mechanic Autopsy
**Time:** 30-45 minutes
**Materials:** Paper/doc, 3 games you know well (ideally across different genres)

For each of the 3 games:
1. Identify the **core mechanic** in one sentence.
2. List **3 supporting mechanics**.
3. For each supporting mechanic, describe how it *interacts with* the core mechanic (not just how it exists alongside it).
4. Identify one **surprising interaction** — a moment where two mechanics combine to create something neither does alone.
5. Rate the game's depth-to-complexity ratio on a scale of 1-10, and justify your rating in two sentences.

**Stretch goal:** Do one of the three games in a genre you do not normally play. This forces you to see mechanics without the comfort of familiarity.

---

### Exercise 2: The Reduction Challenge
**Time:** 20-30 minutes
**Materials:** A game you are designing or a game concept you have been thinking about

1. Write down every mechanic in the game (aim for exhaustive — even small ones).
2. Remove one mechanic. Ask: "Does the game still work? Is it still fun?"
3. Repeat until you cannot remove anything without the game collapsing.
4. Whatever remains is your mechanical core. Count the mechanics. If you have more than 5-7 after this process, you may still have too many.
5. For each mechanic you removed, ask: "Could I achieve the same effect by deepening an interaction between two remaining mechanics instead?"

This exercise trains the instinct that **subtraction is a design tool**, not just addition.

---

### Exercise 3: The Verb-Noun Matrix
**Time:** 30-40 minutes
**Materials:** Paper/spreadsheet, a game you are designing or want to analyze

1. List every **verb** in the game (player actions) across the top of a grid.
2. List every **noun** (objects, enemies, items, terrain types) down the side.
3. Fill in each cell: what happens when this verb meets this noun? Write "N/A" for impossible combinations.
4. Look for **empty cells** that *could* be filled. Would allowing that verb-noun combination create an interesting interaction? (Breath of the Wild's designers famously did this exercise and then tried to fill every cell.)
5. Look for **nouns that only interact with one verb**. These are candidates for either removal or enrichment.
6. Look for **verbs that interact with everything**. These are probably your strongest mechanics. Consider making one of them your core.

---

## Recommended Reading & Resources

### Essential (Do These)

- **"MDA: A Formal Approach to Game Design and Game Research"** by Hunicke, LeBlanc, and Zubek — The original paper. It is 8 pages long and freely available. Read it. The MDA framework is foundational vocabulary you will use for the rest of this roadmap.
- **"Water Finds a Crack"** by Clint Hocking — A blog post about how players exploit the cracks in your systems, and why that is a feature, not a bug. Essential reading for understanding emergent depth.
- **"Designing Games"** by Tynan Sylvester (Chapters 1-3) — The RimWorld designer breaks down mechanics, dynamics, and elegance with practical examples.

### Go Deeper (If You're Hooked)

- **"A Game Design Vocabulary"** by Anna Anthropy and Naomi Clark — Built around verbs, objects, and contexts in game design. Dense but rewarding.
- **"The Art of Game Design: A Book of Lenses"** by Jesse Schell (Lenses #1-30) — Dozens of angles for evaluating mechanics.
- **"Characteristics of Games"** by Elias, Garfield, and Gutschera — Academic treatment of depth vs. complexity with rigorous analysis.
- **Game Maker's Toolkit (YouTube): "What Makes a Good Mechanic?"** — Excellent visual explanations of mechanical design.
- **Play Go** (online at OGS or similar). Seriously. Five rules, thousands of years of unsolved strategy. The fastest way to internalize depth vs. complexity.

---

## Key Takeaways

- **A mechanic is a verb plus a consequence.** If you cannot state the verb and the consequence, you do not yet have a mechanic — you have a vague feature.

- **Your core mechanic must be simple to learn, deep to master, and good to execute.** It is the thing the player does most. Everything else supports it.

- **Depth comes from interactions between mechanics, not from the number of mechanics.** Before adding a new system, ask how many new *interactions* it creates with existing systems. If the answer is zero, cut it.

- **The MDA Framework is your diagnostic tool.** When something feels wrong, trace it backward: bad aesthetic -> unwanted dynamic -> fixable mechanic. Design left to right, diagnose right to left.

- **Subtraction is the most underrated design skill.** The game you ship should have fewer mechanics than the game you prototyped. Every mechanic that survives should be earning its place through interactions, feel, and depth.

---

## What's Next?

Now that you can identify and evaluate individual mechanics, the next step is understanding how they form **systems**. Head to [Module 2: Systems Thinking & Emergent Gameplay](module-02-systems-thinking-emergent-gameplay.md) for positive/negative feedback loops, balancing mechanics, and how small interactions scale into economies and ecologies.

If the "feel" discussion resonated, jump to [Module 9: Aesthetics, Feel & Juice](module-09-aesthetics-feel-juice.md) for a deep dive on game feel, feedback, and making mechanics *feel* as good as they play.
