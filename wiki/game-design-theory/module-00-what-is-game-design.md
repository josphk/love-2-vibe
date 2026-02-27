# Module 0: What Is Game Design, Actually?

**Part of:** [Game Design Theory Roadmap](game-design-theory-roadmap.md)
**Estimated study time:** 3-5 hours
**Prerequisites:** None

---

## Overview

Most people think game design means making games. It doesn't. Making games involves dozens of disciplines -- programming, art, animation, sound, writing, production, QA, marketing. **Game design** is one specific discipline among those, and it's the one that determines what the player actually *does*, what happens when they do it, and why any of it feels meaningful. You can ship a gorgeous game with flawless code that is utterly boring to play. That's a design failure, not a tech one.

This module draws a hard line between game design and everything else. By the end, you'll be able to watch someone play any game and articulate exactly what design decisions are driving the experience -- separate from the visual polish, the narrative wrapper, or the technical implementation underneath. You'll also understand how designers actually spend their days, what artifacts they produce, and how they collaborate with every other role on a team.

If you're building games solo (especially vibe-coding in LOVE2D or similar), this distinction matters even more. When you're wearing every hat, it's easy to spend six hours tweaking particle effects or refactoring entity systems while the core gameplay loop remains untested and unfun. Knowing what game design *is* lets you prioritize the work that actually makes your game worth playing.

---

## Core Concepts

### 1. The Definition of Game Design

**Game design** is the craft of defining rules, constraints, and goals that produce interesting decisions for a player. That's it. Not the art. Not the code. Not the story. Not the project schedule. The *rules and systems* that create the experience.

**Why it matters:** If you can't separate design from implementation, you'll solve design problems with code and code problems with design. A confusing level isn't fixed by better shaders. A boring combat system isn't fixed by adding more particle effects. Knowing what game design actually is tells you *where to look* when something isn't working.

**Examples:**
- In **Super Mario Bros.**, the game design is: you move right, you jump, enemies move in patterns, pits kill you, mushrooms make you bigger, and the timer creates urgency. The pixel art, the chiptune music, the 6502 assembly code -- those are not game design. They're implementations *of* the design.
- In **Chess**, there is no art, no code, no sound. It's pure game design: a grid, pieces with movement rules, capture mechanics, and a win condition. Chess has survived a thousand years on design alone.
- In **The Sims**, the game design is the need system (hunger, fun, social, hygiene, etc.), the relationship model, the building constraints, and the economic loop of work-earn-buy. The charming animations and Simlish voice acting are window dressing on a deeply mechanical simulation.

**Common mistake:** Saying "I designed a game" when you mean "I had an idea for a game." An idea is not a design. "What if there was a game where you're a ghost who possesses furniture?" is an idea. A design specifies: what does possession *do* mechanically? What can the player interact with? What are the failure states? What makes one choice of furniture better than another? Ideas are free. Design is the hard part.

**Try this now:** Pick a game you played recently. In one sentence, describe its game design without mentioning its art style, story, platform, or technology. If your sentence could describe multiple games equally well, get more specific.

---

### 2. The Designer's Core Question

Every game design problem ultimately reduces to one question: **"What decisions is the player making, and why are those decisions interesting?"**

**Why it matters:** This question is your diagnostic tool. When a playtest goes badly -- when players are bored, confused, or frustrated -- this question tells you where to look. Are they not making enough decisions? Are the decisions too obvious? Too random? Do the decisions lack consequences? This single question can unstick almost any design problem.

**Examples:**
- In **XCOM 2**, every turn asks: which soldier moves where? Do you advance aggressively or hunker down? Do you use your grenade now or save it? Each decision involves incomplete information (fog of war), risk (hit percentages), and trade-offs (using a turn to reload means not shooting). That's why it's compelling.
- In **Cookie Clicker**, the early game has almost no interesting decisions. You click the cookie. You buy the cheapest upgrade. The "decisions" are trivially obvious. Yet it works because the *anticipation system* (watching numbers go up, waiting for thresholds) replaces decision-making with a different psychological hook. Knowing this distinction helps you understand *what kind* of engagement you're designing for.
- In **Celeste**, moment-to-moment decisions are: when to jump, when to dash, when to wall-grab. These are interesting because the timing windows are tight, the level geometry creates multiple possible paths, and your dash is a limited resource that regenerates on landing. Each screen is a tiny decision puzzle wrapped in execution skill.

**Common mistake:** Designing choices that are obvious. If one option is always better, it's not a real decision. In many RPGs, choosing between a sword that does 10 damage and a sword that does 15 damage with no trade-off is a fake decision. The player always picks 15. Real decisions require trade-offs, incomplete information, or personal preference.

**Try this now:** Think about the last 60 seconds of gameplay you experienced. List every decision you made. For each one, ask: was there a real trade-off? Could a reasonable player have chosen differently? If most of your answers are "no," the design may have a problem.

---

### 3. Rules, Systems, and Experiences

Game design operates on three layers. **Rules** are the individual constraints ("you can jump 3 tiles high"). **Systems** are rules interacting with each other ("jumping on enemies defeats them, but spiked enemies hurt you, and some enemies move in patterns that require timed jumps"). **Experiences** are what the player *feels* as a result of engaging with those systems ("tense precision," "satisfying mastery," "playful experimentation").

**Why it matters:** Designers don't directly create experiences. You can't write "the player feels tense" into your code. You create rules and systems that *produce* tension as an emergent result. Understanding this indirect relationship is the fundamental skill of game design. You're always working one layer removed from your actual goal.

**Examples:**
- **Dark Souls** creates the experience of dread and triumph through rules (stamina costs, bonfire checkpoints, soul loss on death) and systems (enemies that punish button-mashing, shortcuts that connect back to earlier areas, boss patterns that reward observation). No single rule creates the experience. It's the *interaction* between them.
- **Minecraft** creates the experience of creative freedom through rules (blocks can be placed and destroyed, crafting follows recipes, mobs spawn in darkness) and systems (resource gathering feeds crafting feeds building feeds exploration feeds more resource gathering). The loop *is* the experience.
- **Tetris** creates flow and panic through rules (pieces fall, completed lines clear, the well has fixed width) and a single devastating system: the speed increases over time. Two simple rules interacting create one of the most psychologically compelling experiences in gaming history.

**Common mistake:** Designing rules in isolation without thinking about how they interact as systems. "The player has a dash" is a rule. It becomes a system when dash interacts with combat (dash through bullets), exploration (dash across gaps), and resource management (dash has cooldown). A rule that doesn't interact with other rules is a missed opportunity.

**Try this now:** Pick one rule from a game you know well. List three other rules it interacts with. For each interaction, describe what experience emerges. You've just reverse-engineered a system.

---

### 4. Game Design as Communication

A game is a conversation between the designer and the player. Every mechanic, every level layout, every piece of feedback (screen shake, sound effects, score popups) is the designer *saying something* to the player. "This is dangerous." "You're doing well." "Try going over there." "That strategy won't work here." **Game design is communication through systems.**

**Why it matters:** If you think of design as communication, you start asking the right questions. Not "is this mechanic cool?" but "does the player understand what I'm trying to tell them?" Not "is this level hard enough?" but "does the player know *why* they died and *what* to try differently?" Most frustrating game experiences are communication failures, not design failures.

**Examples:**
- **Portal** teaches you to think with portals by communicating through level design. The first chamber has one wall you can shoot portals on. The second has two. Each chamber says one thing, clearly, and then tests whether you heard it. The game barely uses text tutorials because the *spaces themselves* are the tutorial.
- In **Hollow Knight**, when you enter a new area and the music changes, the enemies get harder, and the color palette shifts, the game is communicating: "You've crossed a boundary. The old rules still apply, but the difficulty has changed. Stay alert." The designer chose to communicate this through atmosphere rather than a popup that says "DIFFICULTY INCREASED."
- **Doom Eternal** communicates through resource drops. Kill an enemy with a glory kill, you get health. Kill with a chainsaw, you get ammo. Kill with a flame belch, you get armor. The game is constantly saying: "You're low on health? Get aggressive. Stop retreating." The design *communicates* the intended playstyle through its reward structure.

**Common mistake:** Relying on text tutorials or UI popups to communicate what your mechanics should be communicating on their own. If you need a tooltip that says "Press X to dash through enemies," your level design should have already taught the player that dashing through enemies is possible and rewarding. Text is a last resort, not a first tool.

**Try this now:** Open any game and play for two minutes with the sound off and any HUD disabled (if possible). What is the game still communicating to you through its mechanics and spatial design alone? What information is lost without the UI and audio layers?

---

### 5. The Designer's Toolkit

Designers don't (necessarily) write code or create art. So what do they actually *produce*? The core artifacts of game design work are **documents**, **prototypes**, and **playtests**.

**Why it matters:** If you want to practice game design specifically (not just game development), you need to know what design *work* looks like. It's not staring at a blank screen waiting for inspiration. It's writing things down, building quick testable versions, watching people play, and iterating.

**Design documents** range from one-page briefs to massive wikis. The most useful formats include:
- **One-pagers:** A single page that captures the core concept, target audience, key mechanics, and unique selling point. Forces clarity.
- **Mechanic specifications:** Detailed descriptions of how a single mechanic works, including edge cases. "What happens if the player dashes into a wall? Off a cliff? Into an enemy? While carrying an item?"
- **Feature maps:** Visual diagrams showing how systems connect. "Combat feeds into loot, loot feeds into crafting, crafting feeds into exploration."
- **Liz England's "Door Problem"** illustrates this perfectly: a single door in a game requires dozens of design decisions. Can the player open it? Can enemies open it? Does it lock? Can it be destroyed? Does it block sound? Each answer changes the game.

**Prototypes** are quick, ugly, playable versions of a mechanic or system. Paper prototypes (cards, dice, tokens on a table) are underrated. Digital prototypes should be the minimum viable test of a design question. You're not building a game; you're testing whether a mechanic *feels right*.

**Playtests** are where design gets validated or destroyed. You watch real people play your prototype, you shut your mouth, you take notes, and you learn where your design fails to communicate. A design that only works when the designer explains it is a failed design.

**Common mistake:** Writing a 50-page design document before building anything playable. Documents are communication tools, not blueprints. Write enough to build a prototype. Playtest the prototype. Update the document based on what you learned. Repeat.

**Try this now:** Write a one-paragraph design specification for a single mechanic in a game you're working on (or want to make). Include: what the player does, what happens as a result, what the trade-off or risk is, and one edge case. Keep it under 100 words.

---

### 6. Adjacent Roles and Boundaries

Game design doesn't exist in a vacuum. On any team larger than one person, the designer collaborates with specialists who own other aspects of the game. Understanding these boundaries prevents you from stepping on toes -- and helps you communicate your design in terms each discipline can act on.

**Why it matters:** A designer who says "make it feel good" to a programmer has failed. A designer who says "the jump should reach a peak height of 3 tiles in 0.3 seconds with 0.1 seconds of coyote time" has given an implementable specification. Knowing what other roles need from you makes you a better designer.

Here's how the boundaries break down:

| Role | What They Own | What the Designer Gives Them |
|------|--------------|------------------------------|
| **Programmer** | Technical implementation, performance, architecture | Mechanic specs, system diagrams, numerical parameters, edge cases |
| **Artist** | Visual style, character design, environment art, UI art | Mood references, gameplay-driven constraints ("the player needs to distinguish enemies from background at a glance"), silhouette requirements |
| **Animator** | Character movement feel, visual feedback | Timing requirements ("the attack windup must be readable in 0.2s"), priority of which animations matter most for gameplay |
| **Sound Designer** | Audio feedback, music, ambience | What events need audio feedback, relative priority, emotional targets for music by area/moment |
| **Writer/Narrative Designer** | Story, dialogue, lore, world-building | Narrative constraints imposed by mechanics, pacing requirements, what the player needs to know and when |
| **Producer** | Schedule, scope, team coordination, budget | Feature priorities, what can be cut without losing the core, honest time estimates on design iteration |
| **QA** | Finding bugs, testing edge cases, regression | Intended behavior documentation, edge case expectations, "this is a feature not a bug" clarifications |

**Examples:**
- In **Celeste**, the *design* decision was that the dash should feel snappy and committed. The *programming* task was implementing momentum, input buffering, and coyote time to make that design work. The *art* task was creating a clear visual trail. The *sound* task was the satisfying dash audio cue. One design decision created work across four disciplines.
- In **Hades**, the *design* decision was a roguelike structure with persistent narrative progression. The *writing* task was creating thousands of contextual voice lines that respond to your run history. The *programming* task was the state tracking system. The design decision *constrained and directed* the work of other roles.

**Common mistake:** As a solo developer, thinking you don't need to separate these concerns. You do. When you're playtesting your game and something feels off, you need to diagnose: is this a design problem (wrong rules), an implementation problem (buggy code), a communication problem (unclear visuals), or a feel problem (wrong animation timing)? Conflating all of these into "the game feels bad" leaves you no path to fix it.

**Try this now:** Think of a feature you've built (or want to build). Write down what the *design* decision is, then list one specific task it creates for each of these roles: programmer, artist, and sound designer. Even if you're filling all those roles yourself, practice the separation.

---

## Case Studies

### Case Study 1: Portal -- Design as the Invisible Engine

Portal is often praised for its humor, its writing, its visual style, and GLaDOS. But strip all of that away and you still have one of the best-designed games ever made. The *game design* is what makes Portal work. Everything else elevates it.

The core design is elegant: you have a gun that creates two linked portals on valid surfaces. Enter one, exit the other, preserving your momentum. That's one mechanic. From this single rule, the design team at Valve extracted dozens of systems: redirecting lasers, launching yourself across gaps using momentum, transporting objects, creating infinite falls, bypassing obstacles. Every puzzle in Portal is a different *implication* of the same core mechanic.

What makes this brilliant design (not just a clever idea) is the **pacing and sequencing of the puzzle chambers**. Each chamber isolates one concept. Chamber 00 teaches you that portals exist. Chamber 01 teaches you to place one portal. Chamber 02 introduces the companion cube (objects can go through portals). The difficulty curve isn't arbitrary -- it follows a deliberate communication strategy. The design *teaches* through play.

Notice what the game design is NOT doing here. The design didn't specify that the portal gun should be white-and-black, or that the test chambers should have a sterile aesthetic, or that there should be a malevolent AI narrator. Those were art, audio, and writing decisions that amplified the design. A paper prototype of Portal's puzzles (draw rooms on graph paper, mark valid portal surfaces, trace paths) would still be a satisfying puzzle experience. That's how you know the *design* works independently.

The design also made a crucial scope decision: you only place *two* portals (not three, not ten), and only on certain surfaces. These constraints aren't limitations -- they're what make the puzzles solvable. Without the white-surface constraint, every room would have infinite solutions and none of them would feel clever. **Good game design is as much about what you prevent the player from doing as what you allow.** Portal's constraints are where its brilliance lives.

---

### Case Study 2: Stardew Valley -- Design Decisions That Defined a Genre Hit

Stardew Valley was created by one person, Eric Barone (ConcernedApe), who did the programming, art, music, writing, and design. Because he wore every hat, it's tempting to view the game as a singular creative output. But isolating the *design decisions* reveals why Stardew Valley became a phenomenon while dozens of similar farming games didn't.

The foundational design decision is the **day-and-energy system**. Each in-game day is roughly 13 real-time minutes. You have a limited energy bar. Every action (watering, mining, fishing) costs energy. When the day ends, it ends -- you can't keep working. This single system creates scarcity, forces prioritization, and generates the core decision loop: "What do I spend my limited time and energy on today?" Without this constraint, the game would be a mindless clicking simulator. With it, every day is a series of meaningful trade-offs.

The second critical design decision is **systemic interconnection**. Farming feeds into cooking. Cooking gives buffs for mining. Mining yields resources for crafting. Crafting produces sprinklers that automate farming. Fishing provides income and ingredients. Foraging fills the community center bundles. Relationships unlock recipes and story. No system exists in isolation. Every activity feeds back into at least two others. This web of systems is why players can sink hundreds of hours in -- there's always a reason to do something, always a next goal that connects to three other goals.

Third, consider the **social/relationship design**. NPCs have schedules, preferences, birthdays, and multi-stage relationship arcs. The design decision here wasn't "add romance" -- it was "make gift-giving a resource allocation problem." Each NPC likes different items. The best gifts are often items you could sell for profit or use in crafting. Giving a diamond to your favorite villager means you're not selling that diamond or using it for a ring. The social system creates *economic tension*, which makes it a real decision rather than a trivial side activity.

None of these design decisions required professional-grade art or AAA-budget production. The early Stardew Valley prototypes looked rough. The music was simple. What made the game magnetic was the *design* -- the interlocking systems that made each day feel like a fresh set of meaningful choices. If you're a solo developer, this is the lesson: invest your time in design iteration before visual polish. A beautiful game with no interesting decisions won't hold players. A rough-looking game with deeply interconnected systems will.

---

## Common Pitfalls

- **Confusing an idea with a design.** "A game where you're a time-traveling cat" is a premise, not a design. Until you've specified what the player *does*, what decisions they face, and what systems interact, you haven't designed anything. Ideas are the starting point, not the finish line.

- **Thinking design is done when the document is written.** A design document is a hypothesis. It becomes a design when it's been prototyped, playtested, and iterated on. The document you start with and the game you ship will be substantially different if you're doing design right.

- **Equating game design with programming.** Writing code is implementing design, not creating it. You can design a game with index cards and a Sharpie. You can also write beautiful code that implements a terrible design. The skills are separate, even when the same person does both.

- **Designing by accumulation.** Adding more features, more mechanics, more systems doesn't make a game better-designed. Often it makes it worse. Good design asks "what can I remove?" as often as "what should I add?" The tightest designs have the fewest unnecessary rules. Tetris has maybe five rules. It's one of the best-designed games ever.

- **Ignoring the player's perspective.** You know how your systems work because you built them. The player doesn't. If your playtesters are confused, the design is failing at communication. "They just need to read the tutorial" is a red flag. The game should teach through play whenever possible.

- **Skipping playtesting because "I know it's fun."** You don't. You know your *intention*. Only watching someone else play reveals whether your design communicates what you think it does. Every designer who skips playtesting is wrong about their game in ways they can't detect alone.

---

## Exercises

### Exercise 1: Decision Autopsy (Analysis)

**Time:** 30-45 minutes
**Materials:** Any game you can play right now, a notebook or text file

Play the first 5 minutes of any game. (A new save is ideal, but any game works.) As you play, write down every decision the game asks you to make. For each decision, note:

1. What the options were
2. What information you had to make the decision
3. What the trade-off or risk was
4. Whether a "correct" answer was obvious or if reasonable players might choose differently

After your list is complete, categorize each decision: **meaningful** (real trade-off, could go either way), **trivial** (obvious best choice), or **false** (feels like a choice but isn't). Count how many fell into each category. A well-designed opening should be weighted heavily toward meaningful decisions.

**Stretch variant:** Do this for two different games and compare the ratio of meaningful to trivial decisions in their openings.

---

### Exercise 2: The Paper Prototype (Design)

**Time:** 45-60 minutes
**Materials:** Index cards or paper, pen, one other person (or a willing imaginary player)

Design a game using only paper. No screen, no code. Your game must have:

- A goal the player is trying to achieve
- At least two resources the player manages
- A core decision that involves a trade-off between those resources
- A lose condition or escalating difficulty

Write the rules on one index card (front and back). If your rules don't fit on one card, simplify. Playtest it with someone (or play both sides yourself). After one playthrough, write down what worked and what didn't. Change one rule and playtest again.

The point isn't to make a great game. It's to practice the cycle: **design, test, observe, revise**. That cycle *is* game design work.

---

### Exercise 3: The Reverse Engineering Challenge (Stretch)

**Time:** 60-90 minutes
**Materials:** A game you know well, a document editor, optionally a diagramming tool (even pen and paper works)

Choose a game you've played extensively. Create a **systems map**: a diagram showing every major system in the game and how they connect to each other. For each system, write:

1. What rules define it
2. What player decisions it involves
3. What other systems it feeds into or receives from
4. What experience it creates (tension, mastery, discovery, relaxation, etc.)

Then identify the **load-bearing systems** -- the ones that, if removed, would collapse the entire game. Compare those to the **decorative systems** -- ones that could be cut without losing the core experience. This tells you what the designers considered essential versus nice-to-have.

**Example starting point:** In Dark Souls, the stamina system is load-bearing (removing it would fundamentally change combat, exploration, and difficulty). The weapon upgrade system is important but not load-bearing (you could simplify it significantly without losing the core experience).

---

## Recommended Reading & Resources

### Essential (Do These)

| Resource | Author/Source | Type | Why |
|----------|--------------|------|-----|
| "The Door Problem" | Liz England | Blog post (5 min read) | The single best explanation of what game designers do day-to-day, told through one deceptively simple question: who can open this door? |
| "I Have No Words & I Must Design" | Greg Costikyan | Essay (30 min read) | A foundational essay defining what games *are* at a structural level. Dense but essential. Read it slowly. |
| *The Art of Game Design: A Book of Lenses* (Ch. 1-3) | Jesse Schell | Book | The best beginner-friendly game design textbook. The "lenses" framework gives you concrete tools for analyzing any design decision. |

### Go Deeper (If You're Hooked)

| Resource | Author/Source | Type | Why |
|----------|--------------|------|-----|
| *A Theory of Fun for Game Design* | Raph Koster | Book | Explains *why* games are fun at a cognitive level. Short, illustrated, and surprisingly deep. Changes how you think about learning curves. |
| *Rules of Play* (Introduction and Part 1) | Katie Salen & Eric Zimmerman | Book | Academic but rigorous. Defines games, play, and design with a precision that will sharpen your thinking. Heavy reading -- skim if needed. |
| "What Makes a Good Game?" (GDC Talk) | Mark Rosewater (Magic: The Gathering) | Video (60 min) | Twenty years of game design lessons from the lead designer of the most successful card game ever. Packed with practical heuristics. |
| *Game Design Workshop* (Ch. 1-2) | Tracy Fullerton | Book | Step-by-step approach to game design as a practice. Excellent exercises and frameworks. More structured than Schell, less academic than Salen/Zimmerman. |
| "Clockwork Game Design" | Keith Burgun | Blog/Book | A more opinionated, systems-focused take on what game design should strive for. Challenges some common assumptions. Useful for sharpening your own design philosophy. |

---

## Key Takeaways

- **Game design is the craft of creating rules and systems that produce interesting decisions for the player -- it is not programming, art, writing, or production.**

- **The single most useful question in game design is: "What decisions is the player making, and why are those decisions interesting?"**

- **Designers don't create experiences directly; they create rules and systems that produce experiences as emergent results.**

- **Design work produces three artifacts: documents (to communicate intent), prototypes (to test ideas), and playtests (to validate assumptions).**

- **A game that needs extensive explanation to be fun has a design communication problem -- the mechanics should teach the player through play.**

---

## What's Next?

Now that you can identify what game design *is* and separate it from adjacent disciplines, you're ready to go deeper into the building blocks.

**[Module 1: Anatomy of a Mechanic](module-01-anatomy-of-a-mechanic.md)** breaks down how individual mechanics work -- inputs, outputs, feedback loops, and how a single mechanic can be tuned to create wildly different player experiences. You'll take the vocabulary from this module and apply it at a granular level.

Also relevant as you progress:
- **[Module 2: Feedback Loops and Pacing](module-02-feedback-loops-and-pacing.md)** -- How systems interact over time to create difficulty curves, snowball effects, and rubber-banding.
- **[Module 3: Player Psychology and Motivation](module-03-player-psychology-and-motivation.md)** -- Why players *want* to make decisions in the first place. Intrinsic vs. extrinsic motivation, flow theory, and engagement.

[Back to Game Design Theory Roadmap](game-design-theory-roadmap.md)
