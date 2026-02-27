# Module 3: Player Psychology & Motivation

> *"You're not just designing rules — you're designing an experience for a human brain."*

---

## Overview

Every game is a conversation between a system and a nervous system. You can have the tightest mechanics in the world, but if they don't land in a player's brain the right way, nobody's going to stick around. This module is about understanding **why players play, keep playing, or stop playing** — and how to design around those psychological realities without crossing into manipulation.

You'll learn the foundational models (flow theory, self-determination theory, operant conditioning) and then examine the messy reality: cognitive biases that warp player perception, dark patterns that exploit psychology for profit, and the ethical line between compelling design and coercive design. By the end, you should be able to look at any game and diagnose *what's keeping people in the loop* — and whether that loop respects the player.

**Prerequisites:** Familiarity with core mechanics and systems thinking ([Module 1](module-01-what-is-game-design.md), [Module 2](module-02-mechanics-dynamics-aesthetics.md)).

---

## Core Concepts

### 1. Flow Theory: The 8-Channel Model

You've probably heard of **flow** — that state where you're so absorbed in an activity that time disappears. Mihaly Csikszentmihalyi identified it in the 1970s, and game designers have been chasing it ever since. But the popular version of flow theory — a simple band between "too easy" and "too hard" — misses most of the picture.

The full model maps **eight mental states** based on the relationship between your perceived skill level and the perceived challenge:

| State | Challenge Level | Skill Level | What It Feels Like |
|-------|----------------|-------------|-------------------|
| **Flow** | High | High | Total absorption, effortless focus |
| **Arousal** | Very High | High | Excited, slightly stretched, learning fast |
| **Anxiety** | Very High | Moderate | Overwhelmed, stressed, fight-or-flight |
| **Worry** | High | Low | Uncertain, struggling, considering quitting |
| **Apathy** | Low | Low | Checked out, bored, no investment |
| **Boredom** | Low | Moderate | Understimulated, going through the motions |
| **Relaxation** | Low | High | Comfortable, pleasant, no tension |
| **Control** | Moderate | High | Confident, competent, possibly coasting |

The designer's job isn't to keep players in flow 100% of the time — that's impossible and actually undesirable. A well-designed difficulty curve **moves players through multiple states deliberately**. You want moments of arousal (a tough boss) followed by relaxation (an exploration segment) leading back toward flow. *Celeste* does this masterfully: each screen spikes you into arousal or anxiety, but the instant restart and short challenge length keep you from tipping into worry.

**Difficulty curves are flow management.** Games like *Dark Souls* keep players in the arousal-to-flow channel by giving them tools to learn patterns. Games like *Animal Crossing* live comfortably in the relaxation-to-control zone. Neither approach is wrong — they're targeting different emotional experiences.

The trap is **apathy**. If both challenge and skill are low — like a tutorial that drags on for 30 minutes, or a mid-game section with no new mechanics — the player's brain disengages entirely. Apathy is harder to recover from than anxiety because an anxious player is at least *invested*.

### 2. Intrinsic vs. Extrinsic Motivation

**Intrinsic motivation** means you do something because the activity itself is rewarding. You explore in *Outer Wilds* because discovery feels amazing. You build in *Minecraft* because creation is satisfying. The action *is* the reward.

**Extrinsic motivation** means you do something to earn a separate reward. You grind in *Diablo IV* for the legendary drop. You complete daily quests for the battle pass XP. The action is a means to an end.

Most games blend both, and that's fine. The spectrum looks roughly like this:

```
Pure Intrinsic ←————————————————————→ Pure Extrinsic

Outer Wilds → Zelda: TotK → Elden Ring → Destiny 2 → Cookie Clicker
(discovery)   (curiosity +   (mastery +   (loot       (numbers
               rewards)       loot)        treadmill)   go up)
```

The danger isn't extrinsic motivation itself — it's **over-reliance on extrinsic motivation**. When your game's primary engagement loop is "do the thing to get the number," you've built a system that creates **engagement without enjoyment**. Players will log hundreds of hours and then describe the experience as "I don't even know why I played that." That's not a compliment. That's an addiction pattern.

The healthiest designs use extrinsic rewards to **guide players toward intrinsically rewarding activities**. *Breath of the Wild* gives you Spirit Orbs for completing shrines, but the shrine puzzles themselves are the real hook. The orb is a breadcrumb, not the meal.

### 3. The Overjustification Effect

Here's one of the most counterintuitive findings in psychology: **adding external rewards to an already enjoyable activity can make it less enjoyable.**

The classic study (Lepper, Greene, & Nisbett, 1973) gave kids who loved drawing a choice: draw for fun, or draw to earn a "Good Player" certificate. Kids who drew for the certificate **drew less in future free-play sessions** than kids who were never rewarded. The external reward replaced their internal motivation.

This is the **overjustification effect**, and it shows up in games constantly:

- **Achievements that reframe exploration as checklists.** You were enjoying wandering through *Skyrim*, and then you noticed the achievement for visiting every location. Now you're not exploring — you're completing a task. The felt experience shifts from curiosity to obligation.
- **Leaderboards that poison casual fun.** A relaxed *Tetris* session becomes stressful once you're ranked. The intrinsic joy of pattern-matching gets overwritten by competitive anxiety.
- **Daily login rewards that turn play into work.** You boot up *Genshin Impact* not because you want to play, but because you'll lose your streak. The reward system has hijacked the activity.

The antidote is to **reward players for things they're already doing naturally**, rather than creating reward structures that redirect behavior. *Hollow Knight* doesn't give you an achievement for exploring every corner — it hides charm notches and lore tablets that make the exploration itself richer.

### 4. Self-Determination Theory Applied to Games

**Self-Determination Theory (SDT)**, developed by Deci and Ryan, identifies three core psychological needs that drive human motivation. When a game satisfies all three, players experience deep, sustainable engagement. When it fails on any pillar, engagement becomes fragile.

#### Autonomy: Meaningful Choice

Autonomy isn't about having *lots* of choices — it's about having choices that **feel meaningful and self-directed**. The player needs to feel like they're steering, not being steered.

- ***Disco Elysium*** is a masterclass in autonomy. You can build your character around intellect, empathy, physicality, or pure chaos. The game acknowledges and adapts to your choices so thoroughly that playthroughs feel genuinely personal. You're not picking from a menu — you're defining who this detective is.
- ***Hitman 3*** gives you a target and a sandbox. How you approach the assassination — disguise, poison, "accident," sniper rifle from across the map — is entirely yours. The autonomy comes from the expressive possibility space, not from branching narratives.
- ***Undertale*** weaponizes autonomy by making your choice to fight or show mercy the entire emotional core of the game. The game *judges* your autonomy, which makes it feel even more real.

The failure mode is **false autonomy** — dialogue wheels where every option leads to the same outcome, or "open worlds" where you can go anywhere but there's nothing meaningful to find. Players detect fake choices fast, and it breeds resentment.

#### Competence: Mastery and Growth

Competence means the player can see themselves getting better, and the game provides clear feedback on that growth. This is the "just one more try" fuel.

- ***Hades*** (explored in detail in the case study below) makes you feel competent through layered progression: your mechanical skill improves, your build knowledge deepens, and the meta-progression systems give you tangible power gains. Even a failed run teaches you something.
- ***Rocket League*** has one of the purest competence loops in gaming. You go from whiffing every aerial to pulling off ceiling shots over hundreds of hours, and the improvement is visible and visceral. The ranking system provides external validation, but the core satisfaction is feeling your own hands get better.
- ***Spelunky 2*** refuses to lower the bar for you. There's no leveling, no permanent upgrades — competence is entirely in your head. When you finally reach the Cosmic Ocean, you know it's because *you* got better, not your character. That hits differently.

The failure mode is **competence denial** — unclear feedback, unfair difficulty, or systems so opaque that the player can't identify what they did wrong. If you die and don't know why, competence is impossible.

#### Relatedness: Connection to Others

Relatedness is the need to feel connected — to other players, to NPCs, or to a community. Humans are social animals, and games that tap into this create powerful bonds.

- ***Journey*** builds relatedness with a complete stranger through shared experience. You can't talk, can't grief, can barely communicate — and yet the moment when your companion sits down next to you in the snow is one of gaming's most emotional experiences.
- ***Final Fantasy XIV*** has one of the most welcoming online communities in gaming, and that's by design. The mentor system, the "commendation" mechanic for helpful players, and the narrative emphasis on cooperation all reinforce prosocial behavior.
- ***Stardew Valley*** creates relatedness with NPCs through a slow-burn gifting and dialogue system. These are fictional characters, but the relationships feel earned because you invested time learning their preferences and participating in their stories.

The failure mode is **forced sociality** — requiring multiplayer for content that could be solo, or social features that expose players to toxicity without moderation tools. *Destiny 2's* lack of in-game LFG for years was a relatedness failure despite being a social game.

### 5. Operant Conditioning in Games

Let's talk about the Skinner box in the room. **Operant conditioning** — reinforcing behavior through rewards and punishments — is the engine under the hood of most engagement loops. There are four reinforcement schedules, and game designers use all of them:

| Schedule | Definition | Game Example |
|----------|-----------|--------------|
| **Fixed Ratio** | Reward after X actions | Collect 10 coins, get a life |
| **Variable Ratio** | Reward after random number of actions | Loot drops, gacha pulls |
| **Fixed Interval** | Reward after X time | Daily login bonus |
| **Variable Interval** | Reward at random time intervals | Random world events in MMOs |

**Variable ratio schedules** are the most powerful — and the most dangerous. They're why slot machines work, why loot boxes work, and why you'll kill 200 more enemies in *Diablo* hoping for that one legendary drop. The unpredictability creates a dopamine anticipation loop that's incredibly hard to disengage from.

This isn't inherently evil. *Binding of Isaac* uses variable ratio rewards (random item rooms) to create replayability and surprise. The difference is that Isaac asks for your time, while a gacha game asks for your money. The psychological mechanism is identical; the ethical stakes are very different.

**The Skinner box test:** If you removed the variable reward schedule from your game, would anything fun remain? If yes, you're using operant conditioning as seasoning. If no, you've built a slot machine with graphics.

### 6. Bartle Types (and Their Limits)

Richard Bartle's 1996 taxonomy categorizes multiplayer game players into four types based on two axes: acting vs. interacting, and players vs. world.

- **Achievers** (acting on the world): Want to accumulate points, levels, gear. They need measurable progress.
- **Explorers** (interacting with the world): Want to discover secrets, map edges, find hidden mechanics. They need mystery.
- **Socializers** (interacting with players): Want to build relationships, chat, roleplay. They need social infrastructure.
- **Killers** (acting on players): Want to dominate, compete, impose themselves. They need targets and stakes.

This model is useful as a **starting vocabulary**, but it has real limitations:

- **It was designed for MUDs** (text-based multiplayer games). Applying it to single-player games or modern multiplayer is a stretch.
- **Players shift types based on context.** The same person might be an Explorer in *Elden Ring* and an Achiever in *Destiny 2*.
- **It's too coarse.** Four buckets can't capture the full range of player motivation.

**Modern alternatives** like the **Quantic Foundry Motivation Model** (developed by Nick Yee) use empirical data from 400,000+ gamers to identify six primary motivation clusters: Action, Social, Mastery, Achievement, Immersion, and Creativity — each with two sub-components. This gives you a 12-dimensional motivation profile that's far more useful for actual design decisions.

Use Bartle types as shorthand in conversations. Use Quantic Foundry when you're actually designing.

### 7. Cognitive Biases in Game Design

Your players' brains are running on heuristics — mental shortcuts that are usually helpful but systematically exploitable. Here are the big ones for game design:

**Loss Aversion.** Losing something feels roughly **twice as painful** as gaining the same thing feels good (Kahneman & Tversky, 1979). This is why permadeath in *XCOM* is gut-wrenching, why losing a *Minecraft* hardcore world stings for days, and why roguelikes with **meta-progression** (*Hades*, *Dead Cells*, *Rogue Legacy*) dominate the genre — they soften loss without eliminating it.

**Sunk Cost Fallacy.** Players overvalue what they've already invested. You'll keep grinding a game you're not enjoying because you've already put 200 hours in. MMOs exploit this ruthlessly — your character *is* your sunk cost. *World of Warcraft* knows you won't leave because your Paladin represents years of investment.

**Anchoring.** The first number you see sets your reference point. When a premium currency shop shows you a $99.99 pack first, the $19.99 pack looks reasonable by comparison. When a damage number flashes "9,999" on screen, doing "500" later feels pathetic — even if 500 is contextually fine.

**The IKEA Effect.** People value things more when they've helped create them. This is why *Minecraft* builds feel precious, why *Animal Crossing* islands matter, and why character creators generate attachment before the game even starts. Giving players creative input makes them value the result disproportionately.

**Endowment Effect.** People value what they own more than equivalent things they don't. Once a player *has* an item, taking it away (or threatening to) feels like theft. This is why inventory management creates so much anxiety — every discard is a micro-loss. It's also why limited-time items create FOMO: you might not want the skin, but once you own it, you'd hate to lose the *chance* to own it.

### 8. Dark Patterns vs. Ethical Engagement

Every psychological principle in this module can be used to respect players or exploit them. The line between compelling design and coercive design is:

**Does the player feel good about their time *after* they stop playing?**

Dark patterns are design choices that prioritize extraction (money, time, attention) over player wellbeing. They include:

- **Artificial energy systems** that gate play behind timers or payments. You're not designing difficulty — you're manufacturing impatience.
- **Daily login streaks** with escalating rewards that punish missing a day. This converts play from a choice into an obligation.
- **Premium currency obfuscation** — converting real money into gems/crystals/V-Bucks so players lose track of actual spending. The abstraction is the point.
- **Gacha mechanics** with opaque or misleading probability disclosures. When a 0.6% drop rate is presented with flashy animations suggesting near-misses, you're designing a deception.
- **Artificial scarcity and FOMO** — "limited time only!" events that pressure immediate spending. The scarcity is manufactured; digital goods have zero marginal cost.
- **Pay-to-skip-the-grind** where the grind was intentionally made tedious to sell the skip. You created a problem to sell the solution.

**Ethical engagement** uses the same psychological understanding to create genuinely satisfying experiences. *FromSoftware* uses loss aversion to make victories meaningful. *Nintendo* uses operant conditioning to pace discovery. *Supergiant* uses relatedness to make failure feel like progress. In each case, the psychology serves the player's experience, not the revenue model.

The practical test: **Would your game be worse if the player had infinite money?** If yes, your monetization is integrated with the experience. If your game would be *better* with infinite money, you've designed a toll booth, not a game.

---

## Case Studies

### Case Study 1: Hades — Making Death Motivating

**Studio:** Supergiant Games | **Year:** 2020 | **Genre:** Roguelike action

The central design problem of any roguelike is death. When you lose all progress, the natural emotional response is frustration and disengagement. *Hades* doesn't just solve this problem — it turns death into the primary engagement driver. Every failed run makes you *more* invested, not less.

**Meta-progression as competence scaffolding.** When you die in *Hades*, you keep currencies that unlock permanent upgrades (the Mirror of Night), new weapon aspects, and structural changes to runs. This means even a terrible run yields tangible progress. The brilliance is calibration: upgrades make you stronger, but not strong enough to skip learning enemy patterns. Your mechanical skill still matters — the meta-progression just keeps you in the flow channel instead of falling into worry.

**Narrative hooks that reframe failure.** This is where *Hades* becomes special. Death returns you to the House of Hades, where every NPC has new dialogue based on how you died, what you encountered, and how many attempts you've made. Dying to a boss unlocks a conversation with your father about that boss. Reaching a new area triggers character development with Achilles. **The story literally requires you to die.** This reframes death from "I failed" to "I progressed the narrative" — a profound psychological shift.

**Relationship building as relatedness fuel.** The gifting system with NPCs gives you a reason to return beyond mechanical challenge. You want to see where things go with Megaera. You want to give Dusa another bottle of ambrosia. These relationships exploit the IKEA effect (you built them) and provide relatedness satisfaction that roguelike mechanics alone cannot.

**The "one more run" loop architecture.** A single *Hades* run takes 20-40 minutes — short enough that starting another never feels like a major commitment. The boon system provides variable-ratio excitement (what will Hermes offer this time?). And the build diversity means each run *feels* different even in the same environments. You're not repeating content — you're remixing it.

The result: *Hades* scored a 93 on Metacritic, sold millions of copies, and players report hundreds of hours with minimal burnout. It demonstrates that understanding player psychology isn't about manipulation — it's about crafting an experience that respects the player's time and emotions at every turn.

### Case Study 2: Anatomy of a Mobile Dark Pattern

**Composite example drawn from common free-to-play mobile designs.**

Consider a typical mobile RPG. On the surface, it looks like a game. Under the hood, it's an extraction machine assembled from psychological exploits. Let's dissect how each system works.

**Energy systems and manufactured impatience.** You get 5 energy per hour, each level costs 8 energy. This means you can play for roughly 30 minutes before hitting a wall. The game then offers to sell you an energy refill for 100 gems. The game isn't gating content for design reasons — there's no difficulty curve justification for this timer. It exists to create a friction point calibrated to your frustration threshold. The variable-interval schedule of energy regeneration keeps you checking back, training habitual app-opens.

**Daily login streaks and loss aversion.** Log in 7 consecutive days and get a premium character on day 7. Miss a day and the streak resets. This exploits loss aversion — after 5 days, you're not logging in because you want to play; you're logging in because losing 5 days of progress feels worse than the minor inconvenience of opening the app. The game has converted voluntary play into an obligation backed by psychological punishment.

**Premium currency as cognitive fog.** The game sells Crystals in packs: 100 for $0.99, 550 for $4.99, 1200 for $9.99, 3500 for $24.99, 8000 for $49.99. A 10-pull gacha costs 3000 Crystals. Quick: how much does one gacha session cost in real money? The answer ($21.40 at the best rate, or roughly $29.70 at the worst) is deliberately hard to calculate. The abstraction layer exists to break the mental link between spending and money.

**Gacha with manufactured near-misses.** The banner character has a 0.6% drop rate. The pity system guarantees one at 90 pulls ($257 worth of currency at the best bulk rate). The pull animation shows silhouettes and rainbow effects for rare pulls — even when you get a common duplicate. These animations mimic slot machine near-miss psychology, creating the *feeling* of almost winning even when the outcome was statistically predetermined.

**FOMO-driven limited events.** A character is available for two weeks only. Community discourse centers on "must pull" or "skip." The artificial scarcity creates urgency that overrides deliberate spending decisions. Remember: the character is a digital asset with zero production cost per unit. The scarcity is entirely manufactured.

Each system alone might seem minor. Together, they create an environment where a player can spend hundreds of dollars and hundreds of hours while reporting low satisfaction. That's the hallmark of exploitative design: **high engagement, low enjoyment**. The player's psychology is being used against them rather than in service of their experience.

---

## Common Pitfalls

1. **Designing for flow without playtesting for it.** Flow is subjective — what feels perfectly challenging to you as the developer will feel trivial or impossible to different players. Playtest with people outside your skill bracket. Watch them play silently. Their body language tells you more than their words.

2. **Using extrinsic rewards as a crutch for weak core mechanics.** If your game needs a battle pass to keep players engaged, your core loop might not be fun enough on its own. Rewards should amplify intrinsic enjoyment, not replace it. Ask yourself: would players do this activity with no reward? If not, fix the activity.

3. **Mistaking engagement metrics for player satisfaction.** "Daily active users" and "session length" don't measure enjoyment. A player who logs in for 5 minutes out of obligation (daily streak) and a player who logs in for 5 minutes because they love the game look identical in your analytics. Survey your players. Read your reviews. The numbers lie.

4. **Assuming one player motivation fits all.** Your game will attract different Bartle types, different Quantic Foundry profiles. If you only design for Achievers, your Explorers will leave. Build multiple engagement paths — even if one is clearly the "main" path.

5. **Confusing challenge with punishment.** *Dark Souls* is challenging but fair — you can always identify why you died and how to improve. A game with random instant-death mechanics, unclear hitboxes, or misleading feedback isn't difficult; it's hostile. Challenge supports competence. Punishment undermines it.

6. **Rationalizing dark patterns as "industry standard."** Just because every other mobile game uses energy timers and gacha doesn't mean you should. "Everyone does it" is not a design philosophy — it's a surrender of design judgment. Players notice when you respect their time, and they reward you with loyalty.

---

## Exercises

### Exercise 1: Flow State Mapping
**Time:** 45-60 minutes | **Materials:** A game you know well, pen and paper or a drawing tool

Play through (or mentally walk through) 30-60 minutes of a game you've completed. Map the experience onto the 8-channel flow model. For each major segment (level, encounter, puzzle, cutscene), identify which emotional state the designer is targeting. Draw a line graph with time on the X-axis and the 8 states on the Y-axis. Look for the pattern: where does the game ramp you into arousal? Where does it give you relaxation? Is there a section that drops into apathy? Write 200 words on what you'd change to improve the emotional pacing.

### Exercise 2: Motivation Audit
**Time:** 30-45 minutes | **Materials:** Access to a free-to-play game with monetization

Download a free-to-play game you haven't played before. Play for 30 minutes. Then make two columns: "Things I did because they were fun" and "Things I did because the game told me to." For the second column, identify which psychological mechanism is at work (loss aversion, variable ratio reinforcement, FOMO, sunk cost, etc.). Write a short assessment: Is this game using psychology *for* the player or *against* them? What would you change to shift it toward ethical engagement while maintaining business viability?

### Exercise 3: SDT Redesign Challenge
**Time:** 60-90 minutes | **Materials:** Design notebook or document

Pick a game you think has weak player retention. Diagnose which of the three SDT pillars (autonomy, competence, relatedness) it fails on — it might be more than one. Then redesign one system in the game to strengthen the weakest pillar. Be specific: don't just say "add more choices." Describe the exact mechanic, how the player interacts with it, what feedback they receive, and why it satisfies the psychological need. Write it up as a one-page design proposal with a before/after comparison.

---

## Recommended Reading

### Essential
- **"A Theory of Fun for Game Design"** by Raph Koster — The foundational text on why fun works. Short, illustrated, and deeply insightful. Koster frames fun as the brain's response to learning patterns, which connects directly to flow theory and competence.
- **"Bartle Taxonomy of Player Types"** by Richard Bartle (1996, original paper) — Read the primary source, not summaries. Bartle's own nuances and caveats are more interesting than the simplified version that circulated.
- **Quantic Foundry Gamer Motivation Model** (quanticfoundry.com) — Take the free survey, read the research blog. Nick Yee's data-driven approach to player motivation is the modern successor to Bartle's taxonomy.

### Go Deeper
- **"Persuasive Games: The Expressive Power of Videogames"** by Ian Bogost — How games make arguments through their mechanics. Essential reading for understanding how design choices communicate values.
- **"Glued to Games: How Video Games Draw Us In and Hold Us There"** by Rigby & Ryan — The definitive application of Self-Determination Theory to games. Academic rigor with practical design implications.
- **"Hooked: How to Build Habit-Forming Products"** by Nir Eyal — Read this to understand how engagement loops are engineered. Then read it again critically to identify which techniques cross ethical lines. Eyal himself wrote a follow-up ("Indistractable") grappling with the consequences.
- **"Flow: The Psychology of Optimal Experience"** by Mihaly Csikszentmihalyi — The original source on flow theory. Dense but worth it. Focus on chapters about the conditions for flow and the autotelic personality.
- **"Thinking, Fast and Slow"** by Daniel Kahneman — The bible of cognitive biases. Not game-specific, but every bias Kahneman describes shows up in game design. Loss aversion, anchoring, the endowment effect — they all originate here.

---

## Key Takeaways

1. **Flow is a moving target, not a fixed state.** Great games don't maintain constant flow — they orchestrate emotional arcs through multiple states (arousal, relaxation, control) and use pacing to avoid apathy. Design your difficulty curves as emotional journeys, not flat lines.

2. **Intrinsic motivation is fragile and powerful.** External rewards can amplify intrinsic fun or destroy it. Always ask: "If I removed this reward, would the activity still be worth doing?" If not, you're papering over a core design problem.

3. **Self-Determination Theory is your diagnostic tool.** When a game's retention is failing, check autonomy, competence, and relatedness. At least one is usually broken. SDT gives you a framework for identifying *what's wrong* and *what kind of fix* is needed.

4. **Understanding psychology creates ethical responsibility.** Every technique in this module can be used to help or exploit players. Variable ratio schedules can create delightful surprise or gambling addiction. Loss aversion can create meaningful stakes or predatory FOMO. Your design choices reflect your values.

5. **Players are smarter than you think.** Dark patterns work in the short term, but players recognize exploitation over time. Games that respect player psychology build communities that last decades. Games that exploit it burn through audiences and leave resentment in their wake.

---

## What's Next

You now understand the brain you're designing for. Next, explore how these psychological principles connect to other design domains:

- **[Module 5: Level Design & Environment](module-05-level-design-environment.md)** — How spatial design creates flow states, guides player autonomy, and communicates challenge through environmental storytelling.
- **[Module 6: Narrative Design & Storytelling](module-06-narrative-design-storytelling.md)** — How narrative creates relatedness, how branching stories serve autonomy, and how pacing intersects with the 8-channel flow model.
- **[Module 7: Game Balance & Economy](module-07-game-balance-economy.md)** — How economy design intersects with loss aversion, sunk cost, and the ethics of monetization. Where the rubber meets the road for dark patterns vs. ethical design.
