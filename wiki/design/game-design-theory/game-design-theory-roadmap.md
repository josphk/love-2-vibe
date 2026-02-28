# Game Design Learning Roadmap

**For:** Aspiring game designer · Reads > watches · ADHD-friendly · No coding required

---

## How This Roadmap Works

This is about **thinking like a game designer**, not programming. It covers the invisible architecture behind games that feel great — why some mechanics click, how systems create emergent stories, and what makes players keep playing (or quit).

Same rules as before: jump around freely, no linear order required. Each module has reading, analysis exercises, and a design exercise you can do with just paper/notes/a whiteboard.

Each module below is a summary. Click the "Deep dive" link on any module to open the full study guide with detailed explanations, case studies, and additional exercises.

---

## Module 0: What Is Game Design, Actually?

> **Deep dive:** [Full study guide](module-00-what-is-game-design.md)

**Goal:** Separate "game design" from game development, art, programming, and production.

Game design is the discipline of defining **rules, systems, and experiences**. A game designer decides what the player can do, what happens when they do it, and why any of it matters. You don't need to code, draw, or compose music to design a game — you need to think clearly about choices and consequences.

**The core question of all game design:** "What decisions is the player making, and why are those decisions interesting?"

If you can answer that about your game, you're 80% of the way there.

**Read:**
- "The Door Problem" by Liz England: https://lizengland.com/blog/2014/04/the-door-problem/ — the best short explanation of what a game designer actually does
- "I Have No Words & I Must Design" by Greg Costikyan (free PDF, searchable) — foundational essay on what makes a game a game

**Exercise:** Pick a game you love. Write down every decision the player makes in the first 5 minutes. Which decisions feel meaningful? Which feel automatic? Why?

**Time:** 1–2 hours

---

## Module 1: The Anatomy of a Mechanic

> **Deep dive:** [Full study guide](module-01-anatomy-of-a-mechanic.md)

**Goal:** Understand what a mechanic is and how to evaluate one.

A **mechanic** is a rule + a verb. "Press A to jump" is a mechanic. "Click to place a tower" is a mechanic. The quality of a game comes from how its mechanics interact, not how many it has.

**Key concepts:**
- **Core mechanic:** The one action the player does most. In Mario, it's jumping. In Slay the Spire, it's playing cards. In Factorio, it's placing machines.
- **Supporting mechanics:** Everything that makes the core mechanic richer. In Mario, that's running, power-ups, enemy patterns.
- **Depth vs. complexity:** Depth is how much emerges from simple rules. Complexity is how many rules there are. Great games maximize depth while minimizing complexity. Chess has few rules but enormous depth. A bad RPG has 47 stats and none of them matter.

**The "one-sentence test":** Can you describe your core mechanic in one sentence? If not, it's probably too complex or unfocused.

**Read:**
- "Water Finds a Crack" by Clint Hocking: https://clicknothing.typepad.com/click_nothing/2007/10/water-finds-a-c.html — on how players exploit mechanics in unexpected ways
- "Mechanics, Dynamics, Aesthetics" (MDA Framework) — the foundational academic paper on game design: https://users.cs.northwestern.edu/~hunicke/MDA.pdf (short, 6 pages)

**Exercise:** Pick 3 games across different genres. For each, identify: the core mechanic (one verb), 3 supporting mechanics, and one moment where the mechanics interact in a surprising way. Write this down in under 100 words per game.

**Time:** 2–3 hours

---

## Module 2: Systems Thinking & Emergent Gameplay

> **Deep dive:** [Full study guide](module-02-systems-thinking-emergent-gameplay.md)

**Goal:** Understand how simple rules create complex, unpredictable experiences.

This is the magic of game design. You don't script every moment — you build systems that generate moments. The player in RimWorld who accidentally started a colony-ending fire because they assigned a pyromaniac to cook near wooden walls — nobody designed that specific event. The systems created it.

**Key concepts:**
- **Emergent gameplay:** Player experiences that arise from system interactions, not scripted events
- **Feedback loops:** When the output of a system feeds back into its input
  - **Positive feedback loops** amplify (the rich get richer — leader in Mario Kart gets further ahead)
  - **Negative feedback loops** stabilize (blue shells in Mario Kart punish the leader)
- **Balancing loops:** Most good games mix both. Pure positive loops end quickly. Pure negative loops feel stagnant.
- **Interconnected systems:** When system A's output is system B's input. Dwarf Fortress: weather → crops → food → mood → productivity → defense → survival.

**Practical frameworks:** An 8-step systems mapping methodology (with Hades worked example), a Loop Balance Audit framework, and a Broken Design Gallery with four diagnosed failures and fixes. Four case studies: Breath of the Wild, Dwarf Fortress, Factorio (recursive composition), and Into the Breach (minimum viable emergence).

**Read:**
- "Thinking in Systems" by Donella Meadows — not a game design book, but the best book on systems thinking. Read chapters 1–3 at minimum. (Available as ebook/print, well worth buying.)
- "Emergent Gameplay" section of the game design wiki: https://www.gamedeveloper.com — search for emergent design articles

**Exercises (4, all produce artifacts):** Full system map with analysis, feedback loop surgery (diagnosis + redesign with diagrams), paper prototype with 3 interconnected systems, ongoing Emergence Spotter's Journal.

**Time:** 5–7 hours

---

## Module 3: Player Psychology & Motivation

> **Deep dive:** [Full study guide](module-03-player-psychology-motivation.md)

**Goal:** Understand why players play, keep playing, or stop playing.

You're not just designing rules — you're designing an experience for a human brain. Understanding what makes brains engage (and disengage) is a superpower.

**Key concepts:**

- **Flow state (Csikszentmihalyi):** The sweet spot between boredom (too easy) and anxiety (too hard). Great games dynamically keep players in this channel. Difficulty curves are flow management.
- **Intrinsic vs. extrinsic motivation:** Intrinsic = "this is fun." Extrinsic = "I want the reward." Over-relying on extrinsic motivation (loot boxes, daily login rewards) creates engagement without enjoyment. The best games are intrinsically motivating.
- **Self-Determination Theory:** Players need three things — autonomy (meaningful choices), competence (mastery and growth), relatedness (connection to characters/other players).
- **The Bartle Types:** Achievers, Explorers, Socializers, Killers — different players want different things from the same game. Know your audience.
- **Loss aversion:** Losing something hurts ~2x more than gaining the equivalent feels good. This is why permadeath is intense, and why roguelikes that let you keep *some* progress between runs are so popular.

**Practical frameworks:** Flow curve mapping (step-by-step with worked examples), SDT Failure Patterns table for retention diagnosis, reward timing spectrum, combined Player Motivation Mapping template (flow + SDT + operant conditioning), and the Ethics Spectrum with a 5-question designer checklist. Four case studies: Hades, mobile dark pattern anatomy, Outer Wilds (pure intrinsic motivation), and Stardew Valley (SDT in a sandbox).

**Read:**
- "A Theory of Fun for Game Design" by Raph Koster — the classic. Written in an accessible, illustrated style. One of the few game design books that's actually fun to read.
- "Persuasive Games" by Ian Bogost (chapters 1–2) — on how games make arguments through mechanics
- The "Bartle Taxonomy" original paper: https://mud.co.uk/richard/hcds.htm

**Exercises (4, all produce artifacts):** Flow state mapping with annotated timeline, F2P motivation autopsy (classify every action's mechanism), SDT diagnosis and prescription with thermometer diagrams, and Skinner Box dissection with reward map.

**Time:** 5–7 hours

---

## Module 4: Level Design & Pacing

> **Deep dive:** [Full study guide](module-04-level-design-pacing.md)

**Goal:** Learn how to structure a player's journey through space and time.

Level design isn't just placing platforms — it's controlling information, teaching without tutorials, and managing emotional rhythm.

**Key concepts:**

- **Nintendo's "Kishōtenketsu" (4-act structure for levels):**
  1. Introduce a mechanic safely
  2. Let the player practice it
  3. Twist — combine it with something unexpected
  4. Conclude with a satisfying challenge using everything learned
  - Mario games do this within every single level. World 1-1 is the masterclass.

- **Gating:** Controlling what the player can access and when. Hard gates (locked doors) vs. soft gates (enemy difficulty, puzzle knowledge). Metroidvanias are built on gating.

- **Pacing curves:** Tension → release → tension → release. Action sequences need quiet moments between them. Horror games understand this — the hallway before the scare is doing the real work.

- **Environmental storytelling:** What a room tells you without words. A knocked-over chair, a half-eaten meal, a bloodstain. The environment *is* the narrative.

- **Teaching through design:** The best games never need a tutorial popup. They place obstacles that can only be overcome by discovering the mechanic. Mega Man gives you a safe room to test each new weapon. Dark Souls puts a weak enemy in a narrow hallway so you *must* learn to block.

**Read:**
- "Level Design for Games" by Phil Co — practical, example-heavy
- "World 1-1: How Nintendo Made Mario's Most Iconic Level" — search for this widely-shared analysis. Multiple excellent text breakdowns exist.
- Boss Keys series by Mark Brown (this one is video, BUT the Game Maker's Toolkit website has text companion articles and the dungeon diagrams are worth studying as images)

**Exercise:** Sketch a 5-room dungeon on paper. For each room, write: what the player learns, what the challenge is, and what the emotional beat is (tension/relief/surprise/mastery). Room 1 should teach. Room 5 should test everything. Rooms 2–4 should build.

**Time:** 3–5 hours

---

## Module 5: Game Economy & Resource Design

> **Deep dive:** [Full study guide](module-05-game-economy-resource-design.md)

**Goal:** Understand currencies, scarcity, and the invisible math behind "one more turn."

Every game has an economy, even if there's no gold. Health is a currency. Time is a currency. Ammo is a currency. Attention is a currency.

**Key concepts:**

- **Sources and sinks:** Where resources come from (sources) and where they go (sinks). A healthy economy needs balanced sources and sinks. If gold only comes in but never goes out, inflation destroys your economy (Diablo 3 at launch).

- **Meaningful scarcity:** Resources only matter if they can run out. Ammo in Resident Evil is scary because it's scarce. Ammo in most shooters is meaningless because it's abundant. Scarcity creates decisions.

- **Opportunity cost:** The real cost of a choice is what you gave up. "Do I buy the sword or the shield?" is only interesting if you can't buy both. Every meaningful decision in a game is an opportunity cost.

- **Inflation and deflation:** As players progress, do rewards scale? If enemies drop 10 gold at level 1 and 10 gold at level 50, gold becomes meaningless. If they drop 10,000 gold at level 50 but everything costs 100,000 gold, the player feels poor despite big numbers.

- **Multi-currency systems:** Many games use multiple currencies to gate different content. Gold for basic items, gems for premium, reputation for faction gear. Each currency is a separate lever you can tune.

- **The "conversion problem":** When players can convert between currencies (trade time for gold, gold for power), one path will always be optimal, and players will find it.

**Practical frameworks:** An 8-step economy audit methodology (with Balatro worked example), a Broken Economy Gallery (four diagnosed failures with fixes), an Economy Patterns Library (8 named patterns: drip feed, boom/bust, prestige reset, mutual exclusion, etc.), and concrete spreadsheet column structure for tuning. Four case studies: Diablo 3's auction house, Slay the Spire's multi-resource elegance, Balatro (exponential scaling done right), and Resident Evil 4 (spatial economy).

**Read:**
- "Machinations" tool and theory: https://machinations.io — a visual language for designing game economies. The free tier lets you model and simulate. Reading the documentation alone teaches you economy design.
- "Game Mechanics: Advanced Game Design" by Joris Dormans and Ernest Adams — the best book on internal game economies and system modeling

**Exercises (4, all produce artifacts):** Full economy audit (two-page economy map), economy sandbox paper prototype (build, break, fix with dice), multi-currency design challenge (one-page economy design doc), and economy autopsy (500-word diagnosis of a flawed economy).

**Time:** 5–8 hours

---

## Module 6: Difficulty, Challenge & Fairness

> **Deep dive:** [Full study guide](module-06-difficulty-challenge-fairness.md)

**Goal:** Learn to make games that are hard but never cheap.

The difference between "hard" and "unfair" is the difference between Dark Souls and a game nobody plays. Players will tolerate incredible difficulty *if* they believe every failure was their fault.

**Key concepts:**

- **Readable challenge:** The player must be able to understand *why* they failed and *what* to do differently. If they die and don't know why, that's bad design, not difficulty.

- **Mastery curves:** Skill should improve faster than difficulty increases (at first). This creates the "click" moment where the player suddenly feels powerful. Then you ramp difficulty again.

- **Difficulty as knobs, not switches:** Instead of Easy/Medium/Hard, think about which individual parameters you can tune: enemy health, player damage, resource availability, time pressure, information visibility. Celeste's assist mode is the gold standard — granular, judgment-free, player-controlled.

- **Rubber banding:** Invisible systems that help struggling players and challenge dominant ones. Mario Kart's item distribution. Racing game AI that slows down when you're behind.

- **The "Could I have won?" test:** After every failure state, the player should be able to answer "yes, if I had done X differently." If the answer is "no, it was random/unavoidable," your difficulty is unfair.

- **Punishment proportional to mistake:** Losing 30 seconds of progress for a small mistake feels right. Losing 30 minutes feels devastating. Save points, checkpoints, and respawn systems are difficulty design.

**Practical frameworks:** A 6-point Readability Checklist, difficulty mix profiling (execution/knowledge/decision), Skill Floor/Ceiling 2x2 matrix, a 20-parameter difficulty knob inventory with step-by-step Assist Mode design guide, five named failure scenarios for the "Could I Have Won?" test, a punishment calibration scale (Level 0–5), and "The Difficulty Contract" framework for managing player expectations. Four case studies: Celeste, Elden Ring, Slay the Spire (decision complexity), and Into the Breach (perfect information fairness).

**Read:**
- "What Makes Celeste's Assist Mode Special" — search for text analyses of Celeste's accessibility design
- "Difficulty in Game Design" by Game Developer (formerly Gamasutra) — multiple excellent articles under this topic

**Exercises (4, all produce artifacts):** 10-death failure autopsy with readability scores and redesign, difficulty knob inventory + Assist Mode design (parameter inventory + 5-toggle spec), difficulty contract analysis (three games compared), and Skill Floor/Ceiling matrix mapping (10 games placed).

**Time:** 5–7 hours

---

## Module 7: Narrative Design & Player Agency

> **Deep dive:** [Full study guide](module-07-narrative-design-player-agency.md)

**Goal:** Understand how story works when the audience has a controller.

Game narrative is fundamentally different from film or books because the player has agency. The story must accommodate player action without breaking.

**Key concepts:**

- **Ludonarrative consonance/dissonance:** When gameplay and story agree (consonance) or contradict (dissonance). Uncharted: Nathan Drake is a "nice guy" in cutscenes but murders 400 people in gameplay. That's dissonance. Undertale makes the kill count *the story*. That's consonance.

- **Environmental storytelling:** Already covered in Module 4, but worth revisiting. Gone Home, Outer Wilds, and Dark Souls tell stories almost entirely through environment.

- **Branching vs. foldback narrative:** True branching (every choice leads to different content) is exponentially expensive. Foldback (choices diverge then reconverge) is how most games actually work. The Witcher 3 is a masterclass in making foldback feel like true branching.

- **Player fantasy:** What does the player *want to feel like*? A cunning thief? A powerful wizard? A kind farmer? Your mechanics, narrative, and aesthetics should all reinforce the same fantasy.

- **Show, don't tell; do, don't show:** In film, "show don't tell" is the rule. In games, go one further — let the player *do* it instead of showing them. Don't show a cutscene of the bridge collapsing; let the player be on the bridge when it collapses.

**Read:**
- "Stories for Interactive Entertainment" on the IIID (search for interactive narrative design resources)
- "The Craft and Science of Game Design" by Phil O'Connor — good on narrative integration
- "What Games Are" by Tadhg Kelly — on the relationship between story and systems

**Exercise:** Take a non-interactive story you love (book, film, whatever). Redesign one key scene as a gameplay moment. What does the player do? What choices do they have? How does the outcome change based on player action? Write it up in under 200 words.

**Time:** 3–4 hours

---

## Module 8: Prototyping & Playtesting (on Paper)

> **Deep dive:** [Full study guide](module-08-prototyping-playtesting.md)

**Goal:** Learn to test game ideas before writing a single line of code.

This is probably the highest-value skill in this entire roadmap. Paper prototyping lets you iterate on game mechanics in minutes instead of days.

**Key concepts:**

- **Paper prototyping:** Use index cards, dice, tokens, a grid drawn on paper. You can prototype card games, board games, turn-based tactics, resource management systems, and even simplified versions of real-time games.

- **The 10-minute prototype:** Challenge yourself to make a playable prototype of a mechanic in 10 minutes with whatever's nearby. It will be ugly. Play it anyway.

- **Playtesting rules:**
  - Watch. Don't explain. If you have to explain, your design isn't clear enough.
  - Write down every moment the player is confused, frustrated, or disengaged.
  - Ask "what did you think you were supposed to do?" not "did you like it?"
  - Your first playtest will be humbling. That's the point.
  - 5 playtests with 1 person each teach more than 1 playtest with 5 people.

- **Iteration:** Change one thing at a time. Playtest again. Did it improve? The cycle is: design → prototype → playtest → analyze → redesign. Forever.

**Exercise:** Design a card game in 30 minutes using only index cards and a pen. The game must have: a win condition, at least 2 meaningful decisions per turn, and some element of hidden information. Play it solo (playing both sides) or grab anyone willing. Write down 3 things that didn't work and redesign them.

**Time:** 3–5 hours (and then you'll keep doing this forever because it's addictive)

---

## Module 9: Aesthetics, Feel & "Juice"

> **Deep dive:** [Full study guide](module-09-aesthetics-feel-juice.md)

**Goal:** Understand the non-mechanical elements that make games feel incredible.

Game feel is the invisible difference between a game that's "fine" and one that's "incredible." It's why the same mechanic — jumping — feels lifeless in one game and transcendent in Celeste.

**Key concepts:**

- **Game feel / "juice":** Screen shake, particles, hit pause (freezing for 1–3 frames on impact), squash and stretch, camera effects, sound design. None of these change the mechanics, but they transform the experience.

- **The 12 Principles of Animation (applied to games):** Disney's animation principles (squash & stretch, anticipation, follow-through, etc.) apply directly to game animation and feedback. Characters that obey these principles feel alive.

- **Audio as design:** Sound is 50% of game feel. A punch without a sound effect is a visual. A punch with bass-heavy impact SFX is *felt*. Music sets emotional context. Silence is a tool.

- **Color theory and readability:** The player needs to instantly parse what's dangerous, what's interactive, what's background. Good visual hierarchy makes a game readable at a glance. Bullet hell games are a masterclass — you track hundreds of projectiles because the visual design makes threats readable.

- **The "mute test":** Play your favorite action game on mute. Notice how much less satisfying everything feels. That gap is the audio design doing its job.

**Practical frameworks:** Six-Component Scorecard for diagnosing feel, Juice Layering Order (7 layers, implemented in sequence), Weight Design Spec template with Monster Hunter worked example, sound anatomy (transient/body/tail), Synesthesia Intensity Scale, five Feel Archetypes (Precision Dasher, Deliberate Warrior, Flowing Explorer, Kinetic Brawler, Atmospheric Wanderer), genre-appropriate juice levels, a Juice Budget allocation model, a step-by-step Feel Design Process, and a comprehensive Feel Implementation Checklist. Four case studies: Nuclear Throne (the masters of screenshake), Celeste (transcendent movement), Hollow Knight (precision feel on an indie budget), and DOOM 2016 (first-person feel and the Glory Kill loop).

**Read:**
- "Game Feel" by Steve Swink — THE book on this topic. Dense but excellent.
- "Juice It or Lose It" — search for the talk transcript/write-up by Martin Jonasson & Petri Purho. (Originally a GDC talk, but text summaries exist and the concepts are clearly explained.)
- "The Art of Screen Shake" — Vlambeer (Nuclear Throne devs) write-up on why their games feel so impactful. Search for text summaries.

**Exercises (5, all produce artifacts):** Mute test + Six-Component Scorecard comparison (two games scored), juice layering from zero (7-stage recording sequence), weight spec design (two attack specs + blind test), feel archetype reverse-engineering (two games profiled + hybrid spec), and a diagnostic gauntlet (5 tests on one game).

**Time:** 5–8 hours

---

## Module 10: Scoping & the Discipline of Finishing

> **Deep dive:** [Full study guide](module-10-scoping-discipline-of-finishing.md)

**Goal:** The unsexy truth — most games are never finished. Scoping is a design skill.

This isn't about inspiration. It's about the brutal, practical craft of deciding what to cut so you can actually ship something.

**Key concepts:**

- **The "10% rule":** Your first idea is about 10x too big. Cut it. Then cut it again. The game you think is "small" is still probably too big for a first project.

- **Core loop first:** Build and validate the 30-second loop before anything else. If the core loop isn't fun, more content won't save it. If it IS fun, you need less content than you think.

- **The feature priority matrix:**
  - **Must have:** The game literally doesn't work without this
  - **Should have:** Would noticeably improve the game
  - **Nice to have:** Would be cool but the game ships without it
  - **Cut:** Remove from scope entirely
  
  Be ruthless. 90% of your ideas are "nice to have" at best.

- **Vertical slice:** Build one complete level/run/match with full polish before building more content. A polished 15-minute experience is worth more than a rough 5-hour one.

- **"Done" is a feature:** The single most impressive thing a game developer can say is "I shipped it." A finished small game teaches infinitely more than an unfinished ambitious one.

**Read:**
- "How to Finish Your Game" by Derek Yu (Spelunky creator): https://makegames.tumblr.com/post/1136623767/finishing-a-game — essential reading, short, and honest
- "Blood, Sweat, and Pixels" by Jason Schreier — behind-the-scenes of game development that shows how even AAA studios struggle with scope

**Exercise:** Take your dream game idea. Write down every feature. Now categorize each into must/should/nice/cut. Be honest. What's left in "must have"? That's your actual first game. Is it small enough to build in 3 months part-time? If not, cut more.

**Time:** 2–3 hours

---

## Essential Reading List (Ranked)

These are books/resources, not videos. Ranked by impact-per-hour.

### Tier 1: Start Here
| Title | Author | Why |
|-------|--------|-----|
| "A Theory of Fun" | Raph Koster | The most accessible game design book. Illustrated, short, foundational. |
| "The Door Problem" | Liz England | One blog post that explains game design better than most books. Free. |
| "Finishing a Game" | Derek Yu | Short blog post. Will save you from your own ambition. Free. |

### Tier 2: Go Deeper
| Title | Author | Why |
|-------|--------|-----|
| "Game Feel" | Steve Swink | The definitive text on why games feel good. |
| "Thinking in Systems" | Donella Meadows | Not about games, but will transform how you design them. |
| "Game Mechanics: Advanced Game Design" | Dormans & Adams | Best resource on internal economies and system modeling. |
| "Rules of Play" | Salen & Zimmerman | The textbook. Heavy but comprehensive. Use as reference, don't read cover to cover. |

### Tier 3: Broaden Your Perspective
| Title | Author | Why |
|-------|--------|-----|
| "Blood, Sweat, and Pixels" | Jason Schreier | Shows the human reality of game development. Motivating and sobering. |
| "A Game Design Vocabulary" | Anthropy & Clark | Challenges mainstream design assumptions. Short, opinionated, valuable. |
| "The Design of Everyday Things" | Don Norman | Not about games. About how humans interact with designed objects. Applies to everything. |

---

## Online Resources (Text-First)

| Resource | URL | Notes |
|----------|-----|-------|
| Game Developer (formerly Gamasutra) | https://www.gamedeveloper.com | Thousands of free design articles and postmortems |
| Lost Garden (Daniel Cook) | https://lostgarden.home.blog | Deep essays on game design systems |
| Machinations | https://machinations.io | Visual game economy modeling tool + documentation |
| Board Game Design Lab | (blog/articles section) | Card/board game design translates directly to digital |
| Itch.io game jams | https://itch.io/jams | Study small games. Most are free. Play them critically. |

---

## The Analysis Habit

The fastest way to become a better game designer is to play games critically. Every time you play, ask yourself:

1. **What decision did I just make?** Was it interesting?
2. **What information do I have?** What's hidden? Why?
3. **What's the core loop?** How long before it repeats?
4. **Why am I still playing?** What's the hook right now?
5. **What would I change?** Just one thing. What and why?

Write these down. Even just a few sentences after each play session. Over weeks, you'll build a personal library of design observations that's more valuable than any textbook.

---

## ADHD-Friendly Tips (Reprise)

- **Analysis is playing.** Give yourself permission to count "critically playing a game for 30 minutes and writing notes" as productive design study. It is.
- **Carry index cards.** When a game design idea strikes — at the grocery store, in the shower, at 2am — write it on a card. Don't open your phone, you'll get distracted. Physical cards go in a pile you can sort later.
- **One concept per session.** Don't try to study systems thinking AND narrative design AND economy design in one sitting. Pick one module, do the exercise, stop.
- **The 2-minute rule:** If an exercise feels overwhelming, commit to just 2 minutes. You'll almost always keep going once you start.
- **Design games you want to play.** If you're not excited about it, you won't finish it. This isn't a job yet — follow the spark.
