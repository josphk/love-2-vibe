# Module 10: Scoping & the Discipline of Finishing

> *"The single most impressive thing a game developer can say is 'I shipped it.'"*

---

## Overview

Here's the unsexy truth that nobody wants to hear at the end of a game design curriculum: **most games are never finished.** Not because the developers lacked talent. Not because the ideas were bad. Because the scope was wrong and nobody had the discipline to fix it.

You've spent nine modules learning how to design mechanics, build systems, craft narratives, balance economies, and test your work. All of that knowledge is useless if you can't ship. And shipping is a skill — maybe the hardest one — because it requires you to do something that feels deeply wrong: **stop adding things to your game.**

This module is about the craft of scoping — deciding what your game *is* and, more importantly, what it *isn't*. You'll learn practical frameworks for cutting your vision down to a buildable size, techniques for estimating how long things actually take, and the mental discipline required to declare something finished and release it into the world. Scoping isn't the enemy of creativity. It's the container that makes creativity productive.

By the end of this module, you should be able to take any game concept — including your wildest dream project — and carve it down to something you can actually build, finish, and ship. That's not a compromise. That's a superpower.

**Prerequisites:** This is the capstone. You should be familiar with core mechanics ([Module 1](module-01-anatomy-of-a-mechanic.md)), playtesting ([Module 8](module-08-prototyping-playtesting.md)), and ideally every module that came before this one. You've learned to design. Now you learn to finish.

---

## Core Concepts

### 1. Why Games Don't Get Finished

Before you can solve the problem, you need to understand why it's so pervasive. Games die in development for predictable, repeatable reasons — and almost none of them are "the developer wasn't good enough."

**Scope creep** is the obvious killer. Your game starts as a tight platformer and slowly accumulates a crafting system, a skill tree, a day-night cycle, companion AI, and a dialogue system. Each addition felt justified in isolation. Together, they're a five-year project for a team of twenty, and you're one person with a day job.

**Feature addiction** is scope creep's psychological engine. Adding a new feature feels like progress. It's exciting. It scratches the creative itch. Polishing an existing feature feels like drudgery. So you keep bolting on new ideas instead of finishing what you have. **The dopamine is in the new, not the done.**

**Perfectionism** kills more games than incompetence. You won't release the game because the animations aren't good enough, the UI isn't clean enough, the balance isn't tight enough. You keep polishing a level that's already better than most shipped games. Meanwhile, the game never ships. Perfect is the enemy of done — and in game development, done is everything.

**"Just one more thing"** is the phrase that murders timelines. You're two weeks from shipping. Then you think: wouldn't it be cool if... And now you're three months from shipping. Then you think it again. This loop can continue indefinitely.

**Losing motivation after the novelty phase** is the silent killer. Starting a new project is thrilling. The first two weeks are pure creative energy. Then the grind starts — bug fixing, edge cases, content creation, the tedious parts. The novelty is gone, and a shiny new game idea is whispering in your ear. So you start a new project. And then another. And another. Your hard drive is a graveyard of prototypes that never became games.

Recognize these patterns. You will encounter every single one of them. The frameworks in this module are your defense.

### 2. The 10% Rule

Here's a calibration tool that will save you months of wasted effort: **your first idea for a game's scope is approximately 10x too big.**

Not 2x. Not 3x. **10x.** This isn't pessimism — it's empirical. Talk to any developer who's shipped a game and ask them how the final product compared to their initial vision. The answer is always some version of "we cut 90% of what we planned."

The 10% Rule works like this:

1. **Write down everything you imagine your game having.** Every feature, every system, every piece of content.
2. **Cut 90% of it.** Not 50%. Not 70%. Ninety percent.
3. **Look at what's left.** That's probably still too big. But it's closer to reality.

This feels brutal. It feels like you're gutting your vision. But here's the truth: the game you can actually build and finish will teach you more and bring more satisfaction than the game you imagined but never completed. **A shipped game with 10% of your features is infinitely more valuable than an unshipped game with 100% of them.**

For a first project, the correct scope is almost embarrassingly small. One mechanic. A few levels. No cutscenes. Minimal art. Ship it. *Then* make something bigger. The skill of scoping improves with each shipped project, because you develop an intuition for how long things actually take versus how long you think they'll take — and those two numbers are never, ever the same.

### 3. Core Loop First

The **core loop** is the 30-second cycle the player repeats throughout your entire game. In *Spelunky*, it's explore-dodge-collect-advance. In *Slay the Spire*, it's draw-plan-play cards-see results. In *Mario*, it's run-jump-land. Everything else in these games — content, progression, narrative, polish — is built on top of a core loop that's fun in its most stripped-down form.

**Build and validate your core loop before you build anything else.** This is non-negotiable.

If the core loop isn't fun, more content won't save it. No amount of art, story, music, or progression systems will make a boring 30-second loop engaging for ten hours. You can't decorate your way out of a mechanical problem.

If the core loop IS fun, you need less content than you think. *Downwell* has one mechanic — falling and shooting downward — and it's brilliant. *Vampire Survivors* is essentially one input and a handful of upgrades. *Flappy Bird* is one button. When the loop works, simplicity is a feature.

**The validation test:** Build your core loop with placeholder art — rectangles, circles, solid colors. No menus, no progression, no polish. Hand it to someone and watch them play for five minutes. Are they engaged? Do they want to keep going? Do they ask "can I try again?" If yes, you have a game. Everything else is amplification. If no, iterate on the loop until you do.

This is the single most efficient use of development time. One week on a core loop prototype will tell you more about your game's viability than three months of building content for a loop you haven't validated.

### 4. The MVP Concept Applied to Games

**Minimum Viable Product** comes from the startup world, but it maps perfectly onto game development. Your MVP is the smallest possible version of your game that proves the core idea is fun.

Not "smallest version that's ready for sale." Not "smallest version I'm not embarrassed by." The smallest version that answers the question: **is this fun?**

For a platformer, the MVP might be ten screens with one mechanic and no progression. For a roguelike, one biome with five enemies and three weapons. For a puzzle game, twenty puzzles with a single rule set. Strip everything back to the kernel of your idea.

The MVP serves two purposes. First, it validates your concept early, before you've invested months of work. If the core isn't fun at the MVP stage, you can pivot or abandon the project while the cost is low. Second, it gives you something *finished* — a complete, playable thing — which builds the psychological momentum you need to keep going.

**Think of your MVP as a complete game, not a demo.** It has a beginning, a middle, and an end. It has a title screen and a win state. It's rough around the edges, sure. But it's *done*. That distinction matters enormously for your motivation and your ability to evaluate the project honestly.

### 5. Feature Priority Matrix

The **Feature Priority Matrix** is your scoping scalpel. Take every feature you want in your game and sort it into one of four categories:

**Must Have** — The game literally doesn't function without this. The core mechanic. Basic player controls. A win/loss condition. If you removed this feature, there is no game. This list should be *short*. Three to five items for most projects.

**Should Have** — The game works without this, but it would be noticeably worse. Sound effects. A basic progression system. A tutorial. Important, but the game can ship and be fun without it if you run out of time.

**Nice to Have** — Cool but not essential. Multiple characters. A leaderboard. Particle effects on every action. An extra biome. These are the features that make your game *polished*, but their absence doesn't make it *bad*.

**Cut** — Not happening. That multiplayer mode you dreamed about. The procedurally generated open world. The branching narrative with voice acting. Kill them. Kill them now, while cutting is cheap.

Here's the uncomfortable reality: **90% of your ideas are Nice to Have at best.** That amazing feature you can't imagine your game without? It's probably a Should Have. That system you think defines your entire project? Test whether the game is fun without it. You might be surprised.

**Worked example — a roguelike shooter:**

| Must Have | Should Have | Nice to Have | Cut |
|---|---|---|---|
| Player movement & shooting | Sound effects | Screen shake & particles | Online co-op |
| Enemy AI (basic) | 3 weapon types | Unlockable characters | Story cutscenes |
| One biome with rooms | Health pickups | Leaderboards | Procedural biome generation |
| Permadeath & restart | Boss encounter | Music | Achievement system |
| Win condition (clear X rooms) | Basic UI (health, score) | Settings menu | Mod support |

Look at that Must Have column. That's your first two weeks. Build that. Play it. Is it fun? If yes, start on Should Have. If not, fix the Must Have first — don't flee into Nice to Have territory because it's more exciting.

### 6. The Vertical Slice

A **vertical slice** is one complete, fully polished section of your game. Not a horizontal prototype with lots of rough content — a narrow, deep slice with the finish quality you want the final product to have.

If you're making a platformer, the vertical slice is one world with five polished levels, complete with final art, sound, music, and tuned difficulty. If you're making a roguelike, it's one complete run with polished enemies, items, and feedback. If you're making a puzzle game, it's one chapter with fully realized puzzles and progression.

**Why vertical over horizontal?** Because a polished 15-minute experience is more valuable than a rough 5-hour one, in almost every way:

- **It proves your game can reach quality.** A horizontal prototype proves your game has *breadth*. A vertical slice proves it has *depth*. Breadth without depth is a skeleton.
- **It exposes real production costs.** You don't know how long it takes to make a level until you've actually finished one — art, sound, testing, polish, everything. The vertical slice gives you real data for estimating the rest.
- **It's playable and evaluable.** You can show it to people. They can judge it fairly. A rough prototype with placeholder art asks people to imagine the final product. A vertical slice shows it to them.
- **It creates momentum.** Having one piece of your game at final quality is enormously motivating. You can see the finish line.

Build one complete slice before you build the rest of your content. This is the discipline that separates shipped games from abandoned ones.

### 7. Scope Estimation Techniques

You're bad at estimating how long things take. Everyone is. Here are techniques that make you less bad.

**T-Shirt Sizing** assigns rough effort categories to tasks: S (hours), M (days), L (weeks), XL (months). Don't pretend you know how many hours something will take — you don't. But you can usually tell whether something is a day or a week. Sort your task list by size and attack the unknowns (L and XL items) first, because those are where your estimates are most likely to be wrong.

**The 3x Rule** takes your honest estimate and multiplies it by three. Think a feature will take two days? Budget six. Think the art will take a week? Budget three weeks. This sounds cynical, but seasoned developers will tell you 3x is *optimistic*. You're not accounting for bugs, iteration, testing, the time you lose to motivation dips, or the fact that every feature touches three other features you didn't think about.

**Timeboxing** sets a fixed time limit and builds what you can within it. Instead of "I'll ship when it's done," say "I'll ship in three months. What can I build in three months?" This flips the relationship between scope and time. Time is fixed; scope is flexible. This is how most successful indie developers work — they don't scope a project and then estimate time. They fix the time and scope the project to fit.

**Story mapping** lays out the player's journey from start to finish as a horizontal timeline, then lists the features needed for each phase vertically. The top row is Must Have for each phase. Lower rows are Should Have and Nice to Have. You can draw a horizontal line at any point and everything above the line is your minimum scope. Move the line up to cut, down to add.

For solo developers, **timeboxing is king.** Set a deadline. Mean it. Ship whatever you have at that deadline. The discipline of a fixed end date is the single most effective tool against scope creep.

### 8. Feature Creep

Feature creep is scope creep's sneakier cousin. Scope creep is adding new systems. Feature creep is making existing systems bigger. Your combat system was supposed to have three weapons. Now it has twelve. Your map was three biomes. Now it's seven. Each weapon and each biome "only" takes a few extra days, but they compound.

**Why it happens:**

- **The "cool idea" trap.** You're mid-development and you have an idea that's genuinely good. It would make the game better. So you add it. And then another idea. And another. Each one is good in isolation. Together, they push your ship date back by months.
- **Sunk cost.** You've spent three weeks on a feature that isn't working. You can't cut it — that would mean those three weeks were wasted. So you spend three more weeks trying to salvage it. Now you're six weeks behind.
- **Competition anxiety.** A game similar to yours just released with feature X. You don't have feature X. Panic. You start building feature X. This is almost always a mistake. Your game doesn't need to have everything the competition has. It needs to have its *own* thing, done well.
- **Fear of "too small."** You worry the game is too short, too simple, not enough. So you pad it. But padding isn't content — it's filler. **A tight three-hour game is better than a bloated ten-hour game.**

**How to fight it:**

Keep a **"cool ideas" document** separate from your task list. When you have an idea mid-development, write it down in the document. Don't implement it. At each milestone, review the document. If an idea still seems essential after two weeks of not thinking about it, evaluate it against the priority matrix. Most of them won't survive the review.

Set a **feature freeze date** — a point in development after which you add nothing new, only polish and fix what exists. Professional studios do this. You should too. After feature freeze, the only acceptable work is bug fixes, balance tweaks, and polish. No new features. None.

### 9. Production Timelines for Solo/Small Teams

Here's what realistic production looks like for solo and small-team developers. These are rough guidelines, not gospel — but they're grounded in the actual shipping history of indie games.

**Solo developer, first game:** 1-3 months for a jam-sized game. Think one mechanic, ten levels, minimal art. *Flappy Bird* scale, not *Stardew Valley* scale. Your first game's job is to teach you how to ship. It's not your magnum opus.

**Solo developer, experienced:** 6-12 months for a small commercial game. Think *Downwell*, *Baba Is You* (though *Baba* took longer due to puzzle design complexity). This assumes you're working part-time or dedicating concentrated months.

**Small team (2-5), experienced:** 1-3 years for a mid-scope indie game. Think *Celeste*, *Hollow Knight*, *Hades*. Note that even these relatively small games took years with dedicated teams — and every one of them shipped with less than originally planned.

**Common milestone cadence:**

- **Week 1-2:** Core loop prototype. Placeholder everything. Is this fun?
- **Month 1:** MVP. Playable start-to-finish, rough but complete.
- **Month 2-3:** Vertical slice. One section at final quality.
- **Month 3-6:** Content production. Building the rest to vertical slice quality.
- **Final month:** Feature freeze. Polish, bugs, testing, preparing for release.

**The part nobody talks about:** the last 10% of the game takes 50% of the time. Polish, edge cases, platform testing, store pages, trailers, marketing materials — the stuff that doesn't feel like game development but is absolutely required for a shipped product. Budget for it or you'll be "almost done" for six months.

### 10. "Done" Is a Feature

This is the most important concept in this entire module, and maybe the entire curriculum.

**A finished, shipped game — any game, no matter how small — is worth more than an unfinished ambitious one.** Not as a product. As a *learning experience*, as a *credential*, and as a *psychological foundation* for everything you build next.

When you ship a game, you learn things you cannot learn any other way:

- What "done" actually means (it's a lot more than "the code works")
- How to make decisions under constraint instead of in the abstract
- What it feels like to let go of something imperfect and release it
- How players actually interact with your game versus how you imagined they would
- The entire pipeline: building, testing, packaging, distributing, promoting

None of this happens if you don't ship. You can study game design for a decade, but until you've pushed something out the door and watched strangers play it, you're operating on theory.

**The fear of shipping is real.** The moment you release your game, it stops being pure potential and becomes a concrete thing that people can judge. That's terrifying. It's also necessary. The gap between "I'm working on a game" and "I shipped a game" is the most important gap in a developer's career. Cross it as early and as often as possible.

Treat "done" as a feature on your priority list — the most important one. Ship ugly. Ship small. Ship something you're not fully satisfied with. Ship it and start the next one. The version of you that has shipped three small games will make a better fourth game than the version of you that has spent three years on one unfinished masterpiece.

### 11. Post-Mortems

A **post-mortem** is a structured reflection on a completed project — what went right, what went wrong, and what you'd do differently. It's the closing ritual that turns shipping a game from an isolated event into a learning cycle.

**What went right** identifies your strengths and successful decisions. What processes worked? Which tools saved time? Where did your instincts prove correct? This isn't just back-patting — it's building a playbook for future projects. If weekly playtesting sessions caught problems early, write that down. If choosing a simple art style saved months, note it.

**What went wrong** is the painful part, and the most valuable. Where did you waste time? Which features should have been cut sooner? When did you ignore warning signs? Where did estimates fail? Be specific. "Scope was too big" isn't useful. "The crafting system took six weeks and added nothing to the core loop — I should have cut it after the first week when playtesting showed players ignoring it" is useful.

**What to do differently** converts analysis into action. Concrete commitments for the next project. "Set a hard feature freeze date one month before release." "Playtest every two weeks instead of every month." "Limit the project to one core mechanic." These become your personal development principles, refined by experience.

Write the post-mortem within a week of shipping, while the experience is fresh. It doesn't need to be public, but it does need to be honest. Your future self will thank you.

---

## Case Studies

### Case Study 1: Hollow Knight — A Small Team's Battle with Scope

**Studio:** Team Cherry (3 people) | **Year:** 2017 | **Genre:** Metroidvania

*Hollow Knight* is a paradox in any discussion about scoping: it's a massive game made by three people. Over forty hours of content, 150+ enemies, dozens of bosses, an enormous interconnected map. How did a team of three build something that rivals the output of studios ten times their size? The answer is more complicated than "they just worked really hard" — and it contains crucial lessons about the relationship between scope and quality.

Team Cherry initially planned a much smaller game. The original pitch was tighter, more contained — a focused Metroidvania with a single clear throughline. But *Hollow Knight* grew. It grew during development, during Early Access, and during the period between launch and the free content updates that followed. By any traditional scoping measure, the game is "too big" for a three-person team.

What makes *Hollow Knight* a useful case study is understanding *what* they chose to expand and what they held constant. The art style is hand-drawn 2D — beautiful but not technically complex to produce compared to 3D. The engine is Unity, a well-documented, accessible platform. The enemy AI patterns, while varied, share underlying behavioral frameworks that were reused and remixed across enemy types. The map is enormous, but individual rooms are composed from modular environmental pieces. Team Cherry built *systems* that scaled, not bespoke content that didn't.

They also cut ruthlessly in areas players never noticed. Early builds had features that didn't ship. Planned content was restructured. The team made hard decisions about what stayed and what went — the difference is that those decisions were informed by playtesting and iteration rather than an upfront scoping document. The game grew organically, but the growth was curated.

The critical lesson from *Hollow Knight* isn't "scope doesn't matter." It's that scope management looks different for every project. Team Cherry could build a massive game because their core systems were modular, their art pipeline was efficient, and their core loop was validated early. They didn't expand scope by adding new systems — they expanded by creating more content *within* proven systems. That's a fundamentally different (and more sustainable) kind of growth. For your first project, the takeaway is clear: build systems that scale, validate early, and grow from a foundation of proven fun rather than speculative ambition.

### Case Study 2: Spelunky — The Discipline of Finishing as a Design Philosophy

**Studio:** Derek Yu (solo, then small team) | **Year:** 2008 (original), 2012 (HD) | **Genre:** Roguelike platformer

Derek Yu might be the most important voice in indie development on the topic of finishing, and *Spelunky* is the embodiment of his philosophy. Before *Spelunky* made him famous, Yu wrote an essay titled "Finish Your Game" that became required reading for indie developers. Its central argument is devastatingly simple: the difference between amateur and professional is not talent but the ability to finish.

The original *Spelunky* was a freeware Game Maker project released in 2008. Yu deliberately chose a small scope: procedurally generated levels (reducing hand-designed content needs), a simple tileset, and a core loop that was fun within thirty seconds of play. The procedural generation wasn't just a design choice — it was a scoping choice. Instead of building hundreds of handcrafted levels, Yu built a system that generated infinite levels from a set of rules and prefabs. **The scope-conscious decision amplified the game's content without multiplying the work.**

Yu's development process was rigorous about sequencing. Core loop first — always. He validated that running, jumping, whipping, and collecting treasure was intrinsically satisfying before building anything on top of it. Only after the loop proved fun did he layer on shopkeepers, traps, secrets, and the elaborate chain of interactions that make *Spelunky* a systems-design masterpiece.

When *Spelunky HD* came to XBLA in 2012, the scope expanded — new art, new enemies, new areas — but the core philosophy remained. Yu has spoken about the features he considered and rejected, the ideas that seemed great but would have delayed or compromised the final product. He kept a relentless focus on the core experience and said no to everything that didn't serve it.

The lesson from *Spelunky* is that finishing isn't a compromise with your creative vision — it *is* your creative vision. Yu's philosophy is that a creator's taste and ambition will always outpace their capacity. The discipline is in choosing what matters most and executing it at the highest level you can, then shipping. The features you cut don't diminish the game. The act of finishing *is* the game's most important feature.

---

## Common Pitfalls

1. **Treating scope as fixed and time as flexible.** You estimated three months, you're at month six, and you refuse to cut features — you just keep extending the deadline. Flip this. Fix the time. Cut the scope. A shipped game in three months beats an unshipped game in "however long it takes."

2. **Confusing "busy" with "productive."** You spent six hours fine-tuning a particle effect that plays for 0.3 seconds. You spent a week building a settings menu instead of making levels. Activity isn't progress. Ask yourself constantly: **does this task move me closer to shipping?** If not, it goes to the bottom of the list.

3. **Building content before validating the loop.** You have fifty levels designed on paper for a core mechanic you haven't playtested. If the mechanic doesn't work, those fifty levels are worthless. **Validate first, produce later.** One great level on a proven loop beats fifty levels on a theoretical one.

4. **Solo developer acting like a AAA studio.** You're one person. You don't need a Jira board with six swimlanes, a branching git strategy, daily standups with yourself, and a 40-page design document. Keep your process proportional to your team size. A notebook and a deadline are usually enough.

5. **The "almost done" plateau.** The game has been "90% done" for four months. The last 10% is polish, bugs, menus, platform compliance, packaging, store pages, and a hundred other things that aren't fun to work on. This is where games go to die. **Budget explicitly for the boring parts.** They take longer than you think and they're not optional.

6. **Comparing your scope to shipped commercial games.** *Stardew Valley* was one developer, so you should be able to make something that big, right? *Stardew Valley* took four and a half years of full-time work by someone with significant prior experience. Comparing your first project's scope to a shipped commercial hit is a recipe for paralysis. Compare your scope to game jam winners instead — that's the right calibration for where you are.

---

## Exercises

### Exercise 1: The Dream Game Autopsy

**Time:** 60-90 minutes | **Materials:** Notebook or spreadsheet, timer

Think of your dream game — the one you'd build if you had unlimited time and resources. Write down every feature, system, and piece of content you imagine it having. Be exhaustive. Spend 20 minutes on this list and don't censor yourself.

Now categorize every item using the Feature Priority Matrix: Must Have, Should Have, Nice to Have, Cut. Be honest — if the game is playable and fun without it, it's not Must Have.

Look at your Must Have column. Could you build everything in it in three months of part-time work (roughly 200 hours)? If not, you're still too big. Move items from Must Have to Should Have until the list is buildable. What's left? That's your real first project. Write a one-paragraph description of this scoped-down version and notice how it feels. It should feel uncomfortably small. That means you're in the right ballpark.

### Exercise 2: Core Loop Speed Run

**Time:** 2-4 hours | **Materials:** Any game engine or prototyping tool (LOVE2D, Godot, Unity, GameMaker, even pen-and-paper)

Pick a game concept — yours or something classic. Build only the core loop in under four hours. Player moves, player acts, something responds. Use rectangles and circles for art. No menus, no score, no progression, no title screen. Just the 30-second loop.

When the timer runs out, hand the prototype to someone and watch them play for five minutes without explaining anything. Take notes: Did they understand what to do? Did they keep playing voluntarily? Did they express any positive reaction? Write 200 words on what the playtest told you about the loop's viability. Would you keep building this game? Why or why not?

### Exercise 3: Post-Mortem Practice

**Time:** 45-60 minutes | **Materials:** A game project you've abandoned (or a game jam project you completed), notepad

Pick a project from your past — ideally one you didn't finish, but a completed jam game works too. Write a post-mortem with three sections: What Went Right (3-5 items), What Went Wrong (3-5 items), and What I'd Do Differently (3-5 concrete actions). For each item in "What Went Wrong," identify which pattern from this module applies: scope creep, feature addiction, perfectionism, no core loop validation, no deadline, or something else.

If you don't have a past project, interview a friend who's tried making a game and write a post-mortem of their experience. The patterns are universal.

---

## Recommended Reading

### Essential
- **"How to Finish Your Game"** by Derek Yu — The definitive essay on the discipline of shipping. Short, direct, and brutally honest. Available free online. Read it before you start your next project, and again when you're halfway through and thinking about quitting.
- **"Blood, Sweat, and Pixels"** by Jason Schreier — Behind-the-scenes stories of game development from *Stardew Valley* to *Destiny*. Every chapter is a case study in scoping, crunch, cutting features, and the messy reality of shipping. Readable in a weekend.

### Go Deeper
- **"The Art of Game Design: A Book of Lenses"** by Jesse Schell — Lens #2 is "The Lens of Essential Experience." Schell's frameworks for identifying the core of your game and building outward from it are directly applicable to scoping.
- **"Spelunky"** by Derek Yu (Boss Fight Books) — A full-length book on the development of *Spelunky*, covering design decisions, scoping choices, and the philosophy behind finishing. Personal and practical.
- **"Making It in Indie Games"** by Don Daglow — Focused on the business and production realities of indie development, including realistic timelines, scope management, and the economic side of shipping.
- **"Finish Your Game"** GDC talks and post-mortems — Search the GDC Vault for post-mortems from small teams. The pattern of "we planned X, cut 70% of it, and shipped Y" appears in almost every single one.

---

## Key Takeaways

1. **Your idea is too big. Cut it. Cut it again.** The 10% Rule exists because every developer overestimates what they can build and underestimates how long it takes. Scope to 10% of your vision, and you'll still probably need to cut from there. Small is a feature, not a flaw.

2. **Validate the loop before building the game.** If the 30-second core loop isn't fun with placeholder art and no content, more content won't fix it. If it IS fun, you need less content than you think. The loop is the foundation. Build on solid ground.

3. **Fix the time, flex the scope.** Set a deadline and ship whatever you have when it arrives. The alternative — fixing scope and flexing time — is how projects stretch from months to years to never. Deadlines are your friend. Mean them.

4. **Shipped beats ambitious. Every time.** A finished, released game — however small, however rough — teaches you more, builds more credibility, and creates more momentum than any number of unfinished dream projects. "I shipped it" is the most powerful sentence in game development.

5. **Post-mortems close the loop.** Don't just ship and move on. Reflect. Write down what worked, what didn't, and what you'll do differently. Each shipped game makes the next one better — but only if you take the time to learn from it.

---

## What's Next

You've completed the game design theory curriculum. Ten modules covering mechanics, systems, psychology, level design, economy, difficulty, narrative, prototyping, playtesting, and now scoping. You have the vocabulary, the frameworks, and the analytical tools.

**Now go make something.**

Start small. Validate your loop. Use the priority matrix. Set a deadline. Ship it. Write a post-mortem. Then make another one. The theory supports the practice, and the practice is where everything actually matters.

If you need to revisit fundamentals, these modules connect directly to the work ahead:

- **[Module 8: Prototyping & Playtesting](module-08-prototyping-playtesting.md)** — The practical methodology for building and testing the prototypes this module tells you to create. Scoping tells you *what* to build; prototyping tells you *how* to validate it.
- **[Module 1: Anatomy of a Mechanic](module-01-anatomy-of-a-mechanic.md)** — Return to the foundation. Your Must Have features should center on mechanics you understand deeply. Revisit this module to sharpen your ability to design the core loop that everything else depends on.
- **[Module 0: What Is Game Design?](module-00-what-is-game-design.md)** — Go back to the beginning with fresh eyes. The question "what is game design?" hits differently after you've studied the entire curriculum. You'll see connections and nuances you missed the first time.

You've learned to design. You've learned to scope. Now go finish something. The world has enough abandoned prototypes. It needs your shipped game.
