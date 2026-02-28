# Module 8: Prototyping & Playtesting (on Paper)

> *"The first draft of anything is garbage. The advantage of paper is that garbage is free."*

---

## Overview

This is probably the highest-value skill in this entire roadmap. Everything else you learn about mechanics, systems, psychology, balance, narrative — all of it is theoretical until you put something in front of a human being and watch what happens. Prototyping is how you turn ideas into testable artifacts. Playtesting is how you find out if those ideas actually work. Together, they are the engine that separates designers who *think* their game is fun from designers who *know*.

The key insight is that you do not need code to test a game idea. You need **index cards, a pen, and ten minutes**. Paper prototyping strips away every distraction — art, animation, sound, polish — and forces you to confront the naked question: **is this mechanic interesting?** If a card game version of your combat system is boring, no amount of particle effects will save it.

This module teaches you to build fast, test ruthlessly, and iterate without mercy. You will learn to prototype any genre on paper, facilitate playtests that produce real data, ask questions that reveal real problems, and develop the iteration mindset that turns mediocre ideas into great ones.

By the end, you should be able to take any game concept from napkin sketch to validated prototype in an afternoon — without writing a single line of code.

**Prerequisites:** Understanding of core mechanics ([Module 1](module-01-anatomy-of-a-mechanic.md)). Familiarity with systems thinking ([Module 2](module-02-systems-thinking-emergent-gameplay.md)) will help but isn't required.

---

## Core Concepts

### 1. Why Prototype on Paper?

Three reasons: **speed**, **cost**, and **emotional distance**.

**Speed.** You can build a playable paper prototype in ten minutes. You cannot build a playable digital prototype in ten minutes. Even with the fastest game engine and the simplest concept, you are spending hours on boilerplate before you get to the actual design question. Paper lets you test the idea *now*, while the excitement is still fresh and before you've committed to an implementation.

**Cost.** An index card costs nothing. A week of development costs a week of your life. When you prototype on paper, the cost of failure is so low that you can test ten ideas in the time it would take to implement one. This changes your relationship with failure entirely. Bad ideas stop being expensive mistakes and start being useful data.

**Emotional distance.** This is the sneaky one. When you spend forty hours coding a combat system, you are emotionally invested. You have debugged edge cases. You have tweaked animation timings. You have *lived* with this code. And now someone tells you the core mechanic isn't fun? Your brain fights that feedback because admitting the mechanic is broken means admitting you wasted forty hours.

When the same mechanic is scrawled on index cards with a Sharpie? You shrug, toss the cards, and try something else. **Paper prototypes are emotionally disposable.** That disposability is a superpower. It lets you kill bad ideas fast, before they calcify into sunk-cost traps.

Professional studios know this. Board game designers have always known it. The entire board game industry runs on paper prototyping — designers test hundreds of iterations with physical components before a game ever reaches production. Digital game designers who skip this step are working harder, not smarter.

### 2. Paper Prototype Techniques by Genre

You can prototype more genres on paper than you think. The trick is identifying the **core decision** in your game and building a paper version that isolates it.

**Card games.** The most natural paper prototype. Write card names, costs, and effects on index cards. If your game has a deck, shuffle and draw. If it has a hand limit, enforce it. You can prototype *Slay the Spire*-style deckbuilders, *Hearthstone*-style dueling games, and *Inscryption*-style resource-sacrifice systems entirely on paper. Use coins or tokens for health, energy, and resources.

**Board games and tactics.** Graph paper is your best friend. Draw a grid, use coins or tokens for units, and write unit stats on a reference card. *Into the Breach*, *Fire Emblem*, and *XCOM* all reduce to "units on a grid making decisions." Move tokens by hand. Resolve combat with dice or deterministic rules. You lose animation and timing, but you keep the strategic core — which is the part you need to test.

**Resource management.** Use piles of tokens (coins, beads, paper clips — whatever you have). Each pile represents a resource. Write conversion rates on a reference card: "2 wood + 1 stone = 1 house." Players take turns performing actions that consume and produce resources. *Settlers of Catan*, *Factorio*, and *RimWorld* all have resource loops you can model with physical tokens.

**Deck-building and roguelikes.** Start with a small deck of basic cards. Create a "shop" of upgrade cards face-up on the table. After each "encounter" (resolved with dice or card draws), the player chooses a reward from the shop. This models the core loop of *Slay the Spire*, *Monster Train*, and similar games — the escalating power curve and the tension between synergy and flexibility.

**Simplified real-time games.** This takes creativity but it is doable. Use a **timer** to compress real-time action into turn-based decisions under pressure. Set a 10-second timer per turn. The player must decide and execute within the window. This captures the cognitive pressure of real-time gameplay without requiring a computer. You can prototype tower defense (place tokens on a map before the "wave" resolves), survival games (draw event cards each "day"), and even simplified action games (sequence of enemy cards, player picks responses under time pressure).

**Puzzle games.** Draw puzzle states on paper. Have the player physically manipulate pieces or mark solutions. *Tetris* can be prototyped with cut-out shapes on a grid. Match-3 games work with colored tokens on a board. The tactile version is slower, but it tells you whether the puzzle logic is satisfying before you write a single line of rendering code.

### 3. The 10-Minute Prototype

Here is the philosophy: **constraint is creative fuel**. You have ten minutes and whatever is on the table in front of you. Build something playable.

It will be ugly. The handwriting will be illegible. The rules will have holes. The balance will be broken. **Play it anyway.**

The 10-minute prototype exists to answer one question: **is there something here?** Not "is this good" — just "is there a spark?" A broken prototype with an interesting decision is infinitely more valuable than no prototype with a perfect idea in your head.

**How to do it:**

1. **Minute 0-2:** Write down the core mechanic as a single sentence. "Players draft cards and play them to attack each other's towers." "Players place workers on a grid to claim territory." Keep it to one verb and one consequence.
2. **Minute 2-5:** Make the components. Grab index cards, write card names and numbers on them. Tear paper into tokens. Draw a board on scrap paper. Do not make it pretty. Do not think about graphic design.
3. **Minute 5-8:** Write the rules. Three to five bullet points maximum. If you cannot explain the game in five bullets, the idea is too complex for a first prototype. Simplify ruthlessly.
4. **Minute 8-10:** Play a round by yourself or with whoever is nearby. You will immediately discover rules you forgot to write, interactions you did not anticipate, and at least one thing that is completely broken.

That is the point. You just learned more about your game in ten minutes than you would have learned in ten hours of theorizing. Now iterate.

### 4. Materials and Setup

Keep a **prototyping kit** ready. When inspiration hits, you want to build, not shop.

**The essentials:**

- **Blank index cards** (at least 200). These are your universal component. Cards, tiles, reference sheets, tokens — index cards do everything.
- **Permanent markers** in at least 4 colors. Black for text, red/blue/green for categories, factions, or resource types.
- **Standard dice** — a mix of d6, d8, d10, d12, d20 if you have them. Dice model randomness, which many games need.
- **Generic tokens.** Coins, glass beads, poker chips, buttons, paper clips. Anything small and grabbable. You need at least 3 visually distinct types.
- **Graph paper.** For grids, maps, and spatial games.
- **A timer.** Your phone works. Use it for timed turns, real-time pressure simulation, and — critically — for timing your 10-minute prototypes.
- **Sticky notes.** Great for rules that change mid-playtest. Slap a new rule on top of the old one.
- **Sleeves and dry-erase cards** (optional but excellent). Slide index cards into card sleeves, then write on the sleeve with dry-erase marker. Change stats mid-game without remaking cards.
- **Scissors and tape.** For when index cards need to be tiles, standees, or something weird.

Keep it all in a box or bag. The goal is zero friction between "I have an idea" and "I have a prototype."

### 5. Playtest Facilitation

This is where most designers fail. Building a prototype is easy. **Watching someone play it without intervening is excruciating.** But it is the only way to get real data.

**Before the playtest:**

- Decide what you are testing. Not "is the game fun?" — that is too vague. "Does the player understand the card-drafting mechanic without explanation?" or "Does the economy run out of resources too quickly?" Test one thing.
- Print or write the rules clearly enough that someone else can read them. If you have to explain the rules verbally, you are already contaminating the test.

**During the playtest:**

- **Sit behind the player, not across from them.** Facing them creates social pressure to perform enjoyment.
- **Shut up.** This is the hardest part. When they misunderstand a rule, do not correct them. Write it down. That confusion is data. If your design requires explanation, the design is unclear — and you need to know that.
- **Do not react.** No wincing when they make a bad play. No smiling when they do something clever. No "oh, that's not how that works." Poker face. Every reaction you show biases the player's behavior.
- **Watch their hands and face.** Are they fidgeting? Leaning in or leaning back? Pausing for a long time (confused or thinking deeply)? Reaching for a card and then pulling back (uncertain about a choice)? Body language tells you what words will not.
- **Take notes constantly.** Timestamp them. "2:15 — player read card three times, still confused." "4:30 — player ignored the market entirely, went straight to combat." "7:00 — player audibly sighed." These notes are gold.

**The golden rule: if you have to explain something, the design failed at that point.** Do not fix it verbally. Fix it in the next version.

### 6. What to Ask After a Playtest

The questions you ask determine the quality of data you get. Most designers ask the wrong questions and get useless answers.

**Bad questions:**

- "Did you like it?" (They will say yes to be polite. Useless.)
- "Was it fun?" (Same problem. Nobody tells a designer their game is boring to their face.)
- "What would you change?" (Players are great at identifying problems. They are terrible at proposing solutions. That is your job.)
- "On a scale of 1-10, how was the experience?" (Numbers without context tell you nothing.)

**Good questions:**

- **"What did you think you were supposed to do?"** This reveals whether your goals and mechanics are communicating clearly. If the answer does not match your intention, the design is unclear.
- **"What was the most confusing moment?"** This pinpoints exactly where the design breaks down. Players forget general confusion quickly but remember specific moments.
- **"Was there a moment where you felt stuck?"** Stuck is different from challenged. Challenged means "I know what to do but need to figure out how." Stuck means "I have no idea what to do next." Stuck is a design failure.
- **"What were you thinking when you [specific action]?"** Reference your notes. Ask about the moments that surprised you. "I noticed you avoided the market. What was going on there?" This reveals player reasoning you cannot observe from outside.
- **"If you were playing this again, what would you do differently?"** This tells you whether the player is engaging strategically — whether the system has enough depth to support different approaches.
- **"What felt unfair?"** Players articulate unfairness more honestly than they articulate boredom. Unfairness feedback is almost always actionable.

**The most important rule: ask about behavior, not feelings.** Feelings are socially filtered. Behavior is observable. "What did you do?" produces better data than "How did you feel?"

### 7. Analyzing Playtest Data

You have notes from five playtests. Now what? The challenge is **separating signal from noise**.

**Look for patterns.** If one player was confused by the card cost system, that might be a player-specific issue. If three out of five players were confused by it, that is a design issue. **Recurring problems across multiple playtests are signal. One-off complaints are noise.**

**Separate what players say from what players do.** A player might say "the game was great!" while their body language showed disengagement for the last fifteen minutes. A player might complain about a mechanic they actually engaged with enthusiastically. **Observed behavior trumps stated opinion every time.** Players are unreliable narrators of their own experience.

**Watch for the "polite playtest."** If every playtest produces positive feedback and zero actionable problems, something is wrong. Either you are biasing the session (see facilitation above), your testers are being polite, or you are subconsciously filtering negative data. Push for honest criticism. Tell testers explicitly: "The most helpful thing you can do is find problems."

**Categorize your findings.** Sort issues into buckets:

- **Comprehension problems:** Players did not understand a rule or mechanic.
- **Pacing problems:** The game dragged or felt rushed at specific points.
- **Balance problems:** One strategy dominated, or resources were too scarce/abundant.
- **Engagement problems:** Players disengaged, checked their phone, or went through the motions.
- **Emotional problems:** Players felt frustrated, confused, or bored (as revealed by behavior, not just words).

**Frequency and severity.** A problem that affects every player mildly is different from a problem that affects one player severely. Prioritize by the combination of how often it occurs and how much it damages the experience when it does.

And remember: **five playtests with one person each are more valuable than one playtest with five people.** Each individual playtest lets you iterate. After each session, you can fix the biggest problem and test again. One big group test gives you data but no iteration between sessions.

### 8. The Iteration Mindset

Iteration is not a phase. It is a permanent state. **Design, prototype, playtest, analyze, redesign.** Forever. Or at least until the game ships.

**Change one thing at a time.** When you have a list of ten problems from playtesting, the temptation is to fix all of them at once. Resist. If you change ten things and the game gets better, you do not know which change helped. If you change ten things and the game gets worse, you do not know which change hurt. **Isolate your variables.** Change one thing, test, observe. Then change the next thing.

**Kill your darlings.** You will have a mechanic you love — the one you think is brilliant, the one that sparked the whole project. And playtesting will reveal that it does not work. It confuses players. It breaks the pacing. It feels bad in practice despite sounding great in theory. **Cut it.** The idea exists in your notebook. You can use it in another game. But this game needs what works, not what you wish worked.

**Know when to pivot vs. when to iterate.** Iteration means refining an idea that has a core of something good. Pivoting means the core idea is not working and you need a fundamentally different approach. Here is the diagnostic: **if players are confused by the execution but engaged by the concept, iterate. If players understand the concept and are simply not interested, pivot.** Confusion is fixable. Apathy is not.

**Version your prototypes.** Label them v1, v2, v3. Keep the old versions (or at least photos of them). When v5 feels worse than v3, you want to go back and understand what you lost. Version history is as valuable for paper prototypes as it is for code.

**Set iteration goals.** Before each playtest, write down what you are trying to learn. After, write down what you learned. This prevents the drift where you playtest out of habit without actually making progress. Each iteration should test a specific hypothesis: "I think reducing hand size from 7 to 5 will speed up decision-making." Test it. Confirm or reject. Move on.

### 9. Digital Lo-Fi Prototyping

Sometimes paper is not enough but code is too much. There is a middle ground: **digital tools that let you prototype without programming**.

**Spreadsheets (Google Sheets, Excel).** Brilliant for testing game math. Build your economy in a spreadsheet: resource generation rates, costs, conversion formulas. Simulate 100 turns in seconds. Does the player run out of gold by turn 20? Does one strategy produce ten times the output of another? Spreadsheets answer balance questions that paper prototypes cannot because they can crunch numbers at scale. Every *Civilization* game has been balanced partly in spreadsheets.

**Machinations.** A free online tool specifically designed for modeling game economies. You build visual diagrams of resource flows — sources, drains, converters, traders — and run simulations. It shows you where resources pool, where they dry up, and how feedback loops behave over time. If your game has any kind of economy (and most games do), Machinations can save you weeks of manual testing.

**Tabletop Simulator.** A digital sandbox that replicates the physical tabletop experience. You can import card images, build boards, roll dice, and playtest remotely with people who are not in your room. It is paper prototyping without the geographic constraint. Especially valuable if your playtesters are online friends rather than local ones.

**Figma / Google Slides.** For UI flow prototyping. Build clickable mockups of menus, inventory screens, and HUD layouts. Test whether players can navigate your interface before you implement it. A surprising number of UX problems are discoverable with a static mockup and a "where would you click?" test.

**When to upgrade from paper to digital lo-fi:** When your game's core decisions depend on math you cannot track by hand (complex economies, large probability spaces) or when you need remote playtesting. Paper is still better for early-stage concept validation because it is faster to modify.

### 10. The One-Page Design Document

Before you prototype, write a **one-page design document**. Not a 50-page GDD. One page. This forces clarity.

**What goes on it:**

- **Title and concept** (1-2 sentences). What is the game? "A deckbuilding roguelike where you build a robot from scavenged parts."
- **Core mechanic** (1 sentence). The primary verb-consequence pair. "Play cards from your hand to move, attack, and scavenge."
- **Core fantasy** (1 sentence). What does the player want to feel like? "A resourceful survivor making the best of what you find."
- **Win/lose conditions.** How does the game end? What constitutes success and failure?
- **Player actions.** List the 3-5 things the player can do on their turn or in a given moment.
- **Key resources.** What does the player manage? Energy, health, cards, currency, time?
- **Progression.** How does the game change over time? Does difficulty escalate? Do the player's options expand?
- **Target experience.** What should a play session feel like minute by minute? Tense? Relaxing? Frantic? Strategic?

**What does NOT go on it:** Lore. Art direction. Monetization. Platform specifics. Marketing strategy. All of that matters eventually. None of it matters when you are figuring out if the core loop works.

**Why it matters:** The one-page doc is a communication tool. When you hand someone your prototype, the doc tells them what you are going for. When you playtest and something feels wrong, the doc reminds you what you were trying to achieve. It is your compass. Without it, iteration becomes wandering.

---

## Case Studies

### Case Study 1: Slay the Spire — A Card Game Born on Paper

**Studio:** MegaCrit | **Year:** 2019 | **Genre:** Deckbuilding roguelike

Before *Slay the Spire* became one of the most successful indie games ever made and spawned an entire genre of imitators, it was a physical card game played on a table with hand-drawn cards.

The developers at MegaCrit prototyped their core loop entirely on paper before writing any code. The fundamental question they needed to answer was deceptively simple: **is it fun to build a deck during a run and fight enemies with it?** Deckbuilding games existed (*Dominion*). Roguelikes existed (*Spelunky*). But the combination — building your deck as you go, with permanent death resetting everything — was untested. Paper prototyping let them validate that combination without months of engineering.

The paper version worked like this: a deck of basic cards (Strikes and Defends, hand-drawn on index cards), enemy encounters represented by cards with health and attack patterns, and a "shop" of upgrade cards laid out on the table after each fight. The player drew a hand, played cards against an enemy card, tracked health with tokens, and chose rewards from the shop. Crude, slow, and completely functional for testing the core question.

What they discovered through paper playtesting was critical. First, the tension between offensive and defensive cards was immediately compelling — even with ugly hand-drawn index cards, the decision of "do I block or do I attack?" created genuine engagement. Second, the reward selection after combat was where the real strategic depth lived. Choosing between a powerful attack card that didn't synergize with your deck and a weaker utility card that enabled a combo — that decision was agonizing in the best way. Paper testing confirmed that the post-combat reward screen, not the combat itself, was the emotional centerpiece of the loop.

Paper testing also revealed problems early. Initial versions had too many cards in the reward pool, making choices feel random rather than strategic. The energy system went through several iterations on paper — early versions gave unlimited plays per turn, which eliminated the hand-management tension entirely. These are problems that would have taken weeks to discover and fix in code. On paper, they took an afternoon.

The lesson for digital designers: *Slay the Spire*'s core loop works because it is fundamentally a card game. The digital version adds animation, music, and visual polish, but the decision architecture — draw, play, choose rewards — is identical to the paper version. **If your game's core decisions can be modeled with cards and tokens, prototype them that way first.** You will find your design problems in hours instead of months.

### Case Study 2: A Board Game Designer's Discipline

**Designer archetype: iterative board game development** | **Genre:** Board games (tabletop)

The board game industry runs on a prototyping discipline that digital game designers would benefit enormously from adopting. A typical published board game has been through **30 to 100 iterations** before it reaches a shelf. That number is not an exaggeration — it is standard practice.

Consider the development arc. A designer has an idea for a worker-placement game about running a bakery. Day one: hand-drawn cards, tokens made from cut paper, a board sketched on cardboard. The rules fit on a single sheet. The first playtest happens that evening with family or a local game group. It is bad. The economy is broken — players accumulate too much flour and have nothing to spend it on. The "bake" action is boring compared to "buy ingredients." One player found a dominant strategy by turn three and coasted to victory.

The designer does not despair. This is expected. They go home and change one thing: the flour-to-bread conversion now costs an action *and* requires a specific oven card, creating scarcity and timing decisions. Version two gets tested two days later. The economy is better. The oven requirement created a new problem — players who do not draw an oven card early are locked out of scoring entirely. Version three adds a communal oven anyone can use, but at reduced efficiency. Now there is a meaningful choice: invest in your own oven for better returns, or use the communal one and spend your resources elsewhere?

This cycle repeats dozens of times. Each version addresses one or two problems while occasionally introducing new ones. The designer tracks every change in a notebook. By version fifteen, the core systems are stable. By version thirty, the balance is tight. By version fifty, the designer is polishing edge cases and fine-tuning the experience curve.

**What digital designers can learn from this:**

First, **expect iteration counts in the dozens, not single digits**. If you have playtested your game three times and think it is done, you are probably wrong. Board game designers budget for fifty iterations because they know from experience that is what good design requires.

Second, **fast iteration cycles matter more than long development sessions**. A board game designer can playtest, analyze, revise, and playtest again in a single day. That velocity is only possible because the prototype is physical and cheap to modify. Digital developers who spend weeks between playtests are learning at a fraction of the speed.

Third, **the designer plays their own game constantly, but they do not trust their own experience**. Board game designers play solo to check math and flow, but they never confuse their own familiarity with a new player's confusion. They maintain separate mental models: "how I experience this game" and "how a first-time player experiences this game." That separation is a trained skill and an essential one.

The board game world proves that great games are not designed — they are iterated into existence. The first version is always bad. The fiftieth version might be good. The discipline is showing up for every version in between.

---

## Common Pitfalls

1. **Prototyping too late.** You spend weeks designing in a document, refining mechanics on paper, planning systems — and only then build a prototype. By that point, you are emotionally married to the design. **Prototype on day one.** The uglier and faster, the better. You do not need a complete design to test a core mechanic.

2. **Explaining during playtests.** A player picks up your card and looks confused. You immediately say, "Oh, that means you discard two cards and draw three." You just destroyed your most valuable data point. That confusion was telling you the card design is unclear. **Write it down. Fix it in the next version. Do not fix it with your voice.**

3. **Asking "did you like it?" instead of "what did you do?"** Politeness bias is universal. People will tell you your prototype is interesting because they are kind humans who do not want to hurt your feelings. Ask behavioral questions. Watch what they actually do. The truth lives in actions, not compliments.

4. **Changing too many things between playtests.** You identified six problems. You fixed all six. Now the game feels different but you have no idea which fix helped and which one introduced a new problem. **Change one variable. Test. Repeat.** Controlled experiments produce useful data. Chaotic rewrites produce confusion.

5. **Skipping paper and going straight to code.** "I'm a programmer, I'll just build it." You will spend three days on input handling, rendering, and UI before you get to test the actual design question. And then when the design does not work, you will resist throwing away the code. **Paper first. Always.** The exception is when your core mechanic is inherently about real-time interaction that paper genuinely cannot model — and even then, paper can usually test the decision structure underneath.

6. **Treating the first playtest as the verdict.** Your first playtest will be humbling. The game will be confusing, broken, and probably not fun. This is normal. This is expected. **The first playtest is not a judgment — it is a baseline.** Every subsequent playtest should be better. If you quit after the first bad session, you have abandoned a process that was working exactly as intended.

---

## Exercises

### Exercise 1: The 30-Minute Card Game

**Time:** 30 minutes to design, 20 minutes to playtest | **Materials:** 40+ blank index cards, pen, tokens (coins/beads)

Design a two-player card game from scratch in 30 minutes. Your game must have: (1) a win condition, (2) at least two types of cards, (3) a resource the player spends to play cards, and (4) a choice each turn that is not obvious. Write the rules on a single index card. Create 20-30 game cards with names, costs, and effects. Then play it — with a friend if possible, solo controlling both hands if not. After one full game, write down three things that did not work and one thing that did. Change the single biggest problem. Play again.

### Exercise 2: Genre Translation

**Time:** 45-60 minutes | **Materials:** Index cards, graph paper, tokens, dice, timer

Pick a digital game you love that is *not* a card or board game — a platformer, a shooter, an action RPG, a tower defense game. Identify its **core decision** (not its core action — the decision underneath the action). Prototype that decision as a tabletop game. A platformer's core decision might be "risk vs. reward in path selection." A tower defense game's core decision might be "resource allocation under escalating pressure." Build the paper version, play it twice, and write 200 words on what the paper version preserved from the original and what it lost.

### Exercise 3: Silent Playtest

**Time:** 30-45 minutes | **Materials:** A prototype from Exercise 1 or 2, a willing playtester, notepad

Hand your prototype to someone who has never seen it. Give them the rules card. Say nothing else. Set a timer for 15 minutes and observe silently. Take timestamped notes on: moments of confusion, moments of engagement, rules they misread, strategies they attempted, and any verbal reactions. After the session, ask three questions from the "good questions" list in Section 6 above. Then write a one-paragraph analysis: what is the single biggest problem the playtest revealed, and how will you fix it in the next version?

---

## Recommended Reading

### Essential

- **"The Art of Game Design: A Book of Lenses"** by Jesse Schell — Chapter on prototyping is one of the best practical guides to building and testing game ideas. The "lens" framework applies directly to analyzing playtest results.
- **"Challenges for Game Designers"** by Brenda Brathwaite and Ian Schreiber — Packed with paper prototype exercises. If you want structured practice, start here.
- **"Kobold Guide to Board Game Design"** edited by Mike Selinker — Board game designers are the masters of paper prototyping. This collection of essays from professional designers covers iteration, playtesting, and the psychology of development.

### Go Deeper

- **"Game Design Workshop"** by Tracy Fullerton — Comprehensive textbook with detailed playtest methodologies and prototype documentation templates. Academic but practical.
- **"Prototyping and Playtesting"** GDC talks (GDC Vault) — Search for talks by Stone Librande (one-page designs at Riot and EA), Slay the Spire's postmortem, and various board-game-to-digital pipeline talks.
- **"Machinations"** by Joris Dormans (machinations.io) — Both a tool and a book. The tool models game economies visually. The book explains the theory behind resource flow modeling. Essential for any game with an economy.
- **"Designing Games"** by Tynan Sylvester — The *RimWorld* creator's book on game design process, including extensive discussion of prototyping, iteration, and the emotional dynamics of killing ideas.

---

## Key Takeaways

1. **Paper prototyping is the fastest path from idea to answer.** Ten minutes with index cards will tell you more about your game than ten hours of theorizing. The speed and disposability of paper prototypes let you test more ideas, fail faster, and converge on what works.

2. **Shut up during playtests.** The most valuable data comes from watching players struggle with your design in silence. Every time you explain something, you are hiding a design problem from yourself. If the prototype cannot speak for itself, fix the prototype.

3. **Ask about behavior, not feelings.** "What did you think you were supposed to do?" reveals design clarity. "Did you like it?" reveals social politeness. Playtest questions should target observable actions and player reasoning, not subjective ratings.

4. **Change one thing at a time.** Iteration is a scientific process. Isolate your variables, test your hypotheses, and track your versions. Changing everything at once produces noise, not signal.

5. **The first playtest is supposed to be bad.** If your first prototype works perfectly, you either got extraordinarily lucky or you are not being honest with yourself. Expect failure. Plan for iteration. The prototype that ships is version 30, not version 1.

---

## What's Next

Prototyping and playtesting connect directly to every other design skill. Continue building on this foundation:

- **[Module 1: The Anatomy of a Mechanic](module-01-anatomy-of-a-mechanic.md)** — You cannot prototype effectively if you cannot identify your core mechanic. Module 1 teaches you to decompose games into testable verb-consequence pairs — the building blocks of every paper prototype.
- **[Module 10: Scoping & The Discipline of Finishing](module-10-scoping-discipline-of-finishing.md)** — The one-page design document introduced here is just the beginning. Module 10 covers comprehensive design documentation, communication frameworks, and how to structure your design thinking for larger projects.
- **[Module 9: Aesthetics, Feel & Juice](module-09-aesthetics-feel-juice.md)** — Playtesting reveals UX problems before they reach code. Module 9 teaches you to think about player experience systematically, including how aesthetics and game feel shape the player's experience.
