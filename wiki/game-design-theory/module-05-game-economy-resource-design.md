# Module 5: Game Economy & Resource Design

> *"Every game has an economy. If your game has a number that goes up or down, you have an economy. Design it, or it designs itself."*

---

## Overview

You already think about game economies — you just don't know it yet. Every time you decide whether to use a health potion now or save it for the boss, you're making an economic decision. Every time you choose the sword instead of the shield, you're calculating opportunity cost. Every time you feel that "just one more turn" pull at 2 AM, an economy is working on your brain.

This module reframes how you see resources. **Health is a currency. Time is a currency. Attention is a currency. Information is a currency.** Once you internalize this, you'll start seeing the invisible math behind every design decision — why *Resident Evil* ammo feels precious while *DOOM Eternal* ammo feels plentiful but tactical, why *Civilization* turns are addictive, and why Diablo 3's real-money auction house almost killed the franchise.

You'll learn the formal vocabulary (sources, sinks, converters, traders), study economy archetypes across genres, and develop the intuition to tune an economy that creates meaningful decisions instead of busywork.

**Prerequisites:** Familiarity with systems thinking and feedback loops ([Module 2](module-02-systems-thinking-emergent-gameplay.md)), player psychology basics ([Module 3](module-03-player-psychology-motivation.md)).

---

## Core Concepts

### 1. Everything Is a Currency

Stop thinking of "resources" as gold and gems. **A currency is anything the player earns, spends, or loses that affects their ability to act.** Once you adopt this lens, the economy of any game explodes in scope:

- **Health** — You spend it by taking hits. You earn it through healing. When it runs out, you're dead. That's a currency.
- **Time** — Every second spent doing one thing is a second not spent doing something else. Real-time games tax your literal attention budget. Turn-based games tax your action points. Time is the most universal currency in gaming.
- **Ammo** — You earn it from pickups and drops. You spend it by shooting. Its scarcity defines whether your game is a power fantasy or a survival horror.
- **Attention** — In complex strategy games, your cognitive bandwidth is a finite resource. *Factorio* doesn't kill you with enemies — it kills you with too many systems demanding attention simultaneously.
- **Information** — In *Slay the Spire*, knowing what's coming on the next floor lets you prepare. In *Among Us*, knowing who the impostor is literally wins the game. Information is earned through scouting, deduction, or mechanics — and it's spent when you act on it.
- **Space** — In *Tetris*, board space is the primary currency. In *Darkest Dungeon*, inventory slots force hard choices about what to carry home. In any city builder, land is the resource that constrains everything else.
- **Cards/abilities** — In deckbuilders, your hand is a currency refreshed each turn. In MOBAs, your cooldowns are currencies regenerating in real time.

**The design implication:** When you list a game's resources, don't stop at the inventory screen. Ask: "What can the player run out of that changes how they play?" That's your full currency list. Most games have 5-15 currencies when you count them honestly.

---

### 2. Sources and Sinks

Every currency flows through a system. **Sources** are where resources enter. **Sinks** are where resources leave. The balance between them determines whether your economy is healthy or broken.

```
[SOURCE] ──flows──> [POOL] ──flows──> [SINK]

Example: RPG Gold Economy

  Monster drops ──> Player Gold ──> Shop purchases
  Quest rewards ──>              ──> Repair costs
  Selling loot  ──>              ──> Fast travel fees
                                 ──> Crafting materials
```

**A healthy economy has balanced sources and sinks.** Resources come in at a rate that gives players meaningful amounts to work with, and leave at a rate that keeps them from hoarding infinitely. If sources overwhelm sinks, you get **inflation** — the currency becomes worthless. If sinks overwhelm sources, you get **deflation** — the currency becomes so precious that players hoard it and never engage with the systems that spend it.

There are two additional node types in formal economy models:

- **Converters** transform one resource into another. A blacksmith converts gold + ore into a sword. A healing spell converts mana into health. Converters link separate resource loops together.
- **Traders** allow exchange between players (or between player and NPC). Traders introduce market dynamics — supply, demand, and the conversion problem we'll cover later.

**The bathtub analogy from Module 2 applies perfectly here.** Your resource pool is the water level. Sources are faucets. Sinks are drains. Your job as a designer is to set the faucet and drain rates so the tub stays in the interesting zone — never empty (frustrating), never overflowing (meaningless).

---

### 3. Economy Archetypes

Not all game economies work the same way. Understanding the archetype you're building helps you anticipate problems before they happen.

**Static Economies** have fixed resource pools that don't grow over time. *Chess* is the purest example — you start with 16 pieces and can only lose them. No generation, no income, only attrition. Static economies create tension through loss — every piece sacrificed matters because it's gone forever. *Into the Breach* uses a static economy for its power grid: you start with a set amount and every hit against a building risks permanent loss.

**Dynamic Economies** have sources and sinks that create flow. Resources come in and go out over time. Most RPGs, strategy games, and survival games use dynamic economies. *Stardew Valley* has a seasonal economic loop: you invest gold in seeds (sink), wait for crops to grow (delay), harvest and sell (source). The dynamic is the cycle — invest, wait, return, reinvest. Dynamic economies must manage inflation carefully because sources tend to compound over time.

**Complex Economies** layer multiple dynamic economies on top of each other with converters and cross-connections. *EVE Online* is the extreme case — player-driven markets with thousands of resources, manufacturing chains, regional price variation, and real economic phenomena like speculation and market manipulation. *Factorio* runs a complex economy where dozens of resource chains feed into each other and bottlenecks cascade through the entire system. Complex economies produce the richest emergent behavior but are the hardest to balance.

**Match the archetype to your design goals.** If you want tight tactical decisions, lean static. If you want progression and growth, go dynamic. If you want player-driven emergent stories, build complex — but budget serious time for balancing.

---

### 4. Meaningful Scarcity

Here's the fundamental truth of economy design: **a resource only creates interesting decisions when it can run out.**

*Resident Evil* ammo is terrifying because you might not have enough to survive the next room. Every shot matters. Every miss hurts. The scarcity transforms a simple "press trigger" action into a tense calculation: Is this zombie worth two bullets? Can I dodge it instead? Should I save the shotgun shells for whatever's behind that door?

Now compare that to most shooters where ammo is everywhere. You pick up hundreds of rounds per encounter. The ammo counter might as well not exist. There's no decision to make because the resource is so abundant it's meaningless.

**The sweet spot for scarcity** is genre-dependent:

- **Survival horror** — Resources should feel *dangerously* scarce. Players should regularly be one bad decision from crisis. The anxiety of scarcity is the point.
- **Roguelikes** — Resources should feel *tight but manageable*. You usually have enough if you play well, but not enough to be careless. This creates the satisfying calculus of risk.
- **Strategy games** — Resources should feel *insufficient for everything*. You can afford military OR infrastructure, defense OR expansion — but not all of it. Scarcity forces prioritization.
- **Power fantasy** (DOOM, Dynasty Warriors) — Specific resources can be abundant because the fantasy is excess. But even here, something must be scarce (weapon cooldowns, special meter, positioning) or decisions vanish entirely.

**The designer's question:** For each resource in your game, ask "What happens if the player has infinite amounts of this?" If the answer is "nothing changes," that resource isn't doing design work. Either make it scarce enough to matter or remove it entirely.

---

### 5. Opportunity Cost

Sid Meier famously said that a game is "a series of interesting decisions." But what makes a decision interesting? **Opportunity cost** — the value of what you give up by choosing one option over another.

"Sword or shield?" is only interesting if you can't buy both. The moment you can afford everything, the decision collapses into "buy everything." There's no cost, so there's no choice, so there's no game.

Opportunity cost operates on multiple levels:

- **Direct resource cost** — "This sword costs 500 gold. That shield also costs 500 gold. I have 600 gold." The cost is the item you didn't buy.
- **Time cost** — "I can explore this dungeon OR do this quest before the timer runs out." The cost is the path not taken.
- **Permanent choices** — "Pick one of three skill trees." The cost is the two trees you'll never have. *Dark Souls* builds are interesting precisely because respec options are limited — your choices stick.
- **Risk cost** — "I can fight this elite enemy for great rewards, but I might die." The cost is the potential loss of what you already have.

**Great economy design maximizes opportunity cost at every turn.** Look at *Slay the Spire*: after every combat, you choose one of three card rewards — or skip all of them. Every card you add shapes your deck. Every card you skip is a strategy you didn't pursue. The opportunity cost is constant, layered, and visible.

The enemy of opportunity cost is **abundance**. When players have more than enough of everything, decisions become trivial. The paradox: players *want* abundance (it feels good to be rich) but *need* scarcity (to have interesting decisions). Your job is to make them feel like they're just barely able to afford the things they want — prosperous enough to have options, constrained enough to feel every choice.

---

### 6. Inflation, Deflation, and Scaling

In a 40-hour RPG, the player will earn vastly more resources at hour 30 than at hour 1. If your rewards don't scale with your costs, your economy breaks.

**Inflation** happens when resources accumulate faster than they're spent. Finding 10 gold at level 1 is exciting — it buys a new sword. Finding 10 gold at level 50 is insulting — it buys nothing. If your reward values don't scale, late-game currency becomes meaningless. Players sit on piles of gold with nothing to buy. The economy is dead.

**Deflation** happens when costs outpace income. If that level 50 sword costs 100,000 gold but enemies still drop 10-50 gold, the grind becomes soul-crushing. Players feel like they're running on a treadmill that's getting faster.

**The scaling treadmill** is the core challenge of progression-based economies. You need rewards to feel meaningful at every stage. There are a few approaches:

- **Linear scaling** — Rewards and costs increase at the same rate. Simple but flat. 10 gold buys a sword at level 1; 1000 gold buys a sword at level 50; the ratio is identical and nothing feels different.
- **Exponential scaling** — Big numbers get bigger fast. *Diablo*-style games use this. You deal 100 damage at level 10 and 10,000,000 at level 70. It feels powerful, but eventually numbers lose meaning. "Is 4.2 billion damage good?" becomes an unanswerable question.
- **Soft caps and resets** — Introduce new currencies or reset the scale at intervals. *Prestige* systems in idle games literally reset your progress in exchange for a permanent multiplier. Roguelikes reset the economy every run, solving inflation entirely.
- **Percentage-based rewards** — Instead of flat numbers, reward percentage improvements. "10% more damage" means the same thing at level 1 and level 50.

**The psychological dimension matters.** Players respond to the *feeling* of numbers, not just their mathematical relationships. Going from 100 damage to 200 damage feels incredible — you doubled your power. Going from 10,000 to 10,100 feels like nothing, even though the absolute gain (100) is the same. This is **diminishing sensitivity** — the same absolute change feels smaller as the baseline grows.

Smart designers use number scaling as a **psychological tool**. Big damage numbers in *Diablo* feel great even if they're mathematically equivalent to smaller numbers with smaller enemy health pools. The trick is making sure the big numbers don't outpace your ability to communicate them meaningfully to the player.

---

### 7. Multi-Currency Systems

Most games beyond the simplest use multiple currencies. Each currency is a **separate tuning lever** that lets you control different aspects of the player experience independently.

Common multi-currency patterns:

- **Basic + Premium** — Gold for everyday purchases, gems (often purchased with real money) for premium items. This is the free-to-play standard. The danger: when premium currency buys power, you've created pay-to-win.
- **Activity-specific currencies** — PvP tokens, dungeon tokens, raid tokens. Each currency funnels players toward specific content. *World of Warcraft* and *Destiny 2* use this heavily.
- **Reputation/faction currencies** — Earned through specific faction activities, spent on faction-exclusive rewards. Creates targeted progression: you invest in the faction whose rewards you want most.
- **Crafting material hierarchies** — Common, uncommon, rare materials that serve as parallel progression tracks. *Monster Hunter* turns every monster into a material source with specific drops, making each hunt economically purposeful.
- **Meta-currencies** — Resources that persist across runs or resets. *Hades'* Darkness, Gems, Keys, Nectar, Ambrosia, and Diamonds each control a different meta-progression system.

**When to add a currency:** Add a new currency when you need a tuning lever that existing currencies can't provide. If players are accumulating gold too fast and you can't adjust it without breaking early-game balance, a separate late-game currency solves the problem without touching existing tuning.

**When you have too many:** If players can't remember what each currency does, or if they need a spreadsheet to track exchange rates, you've over-designed. *Destiny 2* at various points in its lifecycle had so many currency types that Bungie had to do currency consolidation passes. A good rule of thumb: if a currency doesn't create a unique decision that no other currency creates, merge it or remove it.

**Each currency should have a clear source, a clear sink, and a clear purpose.** If you can't explain what decision a currency creates in one sentence, it shouldn't exist.

---

### 8. The Conversion Problem

The moment players can convert between currencies, your carefully separated tuning levers become connected — and one conversion path will always be more efficient than the others.

**Gold farming** is the classic example. If players can convert time into gold (grinding), gold into gear (shopping), and gear into power (equipping), then the most time-efficient gold source becomes the dominant strategy. Players will farm the one enemy or the one activity that produces the most gold per hour and ignore everything else. Your varied content collapses into a single grind.

**The time-to-currency conversion** is the deepest version of this problem. Players implicitly convert real-world time into every in-game currency. If Activity A gives 100 gold per hour and Activity B gives 80 gold per hour, Activity B is dead content — even if it's more fun. Min-maxers will always optimize for the best rate.

**Real-money conversion** makes everything worse. When players can buy currency with cash, every in-game economy decision gets a dollar sign attached. "Should I farm this dungeon for 3 hours or just buy the loot for $5?" This calculation fundamentally changes the player's relationship to the game. It's no longer a world to explore — it's a cost-benefit spreadsheet.

**Mitigation strategies:**

- **Bind currencies to specific sinks** — Make PvP tokens only buyable through PvP and only spendable on PvP gear. If currencies can't convert, the conversion problem can't emerge.
- **Add friction to conversion** — Conversion taxes, time gates, and exchange rate penalties discourage mass conversion. *Path of Exile's* vendor recipes deliberately make conversion inefficient.
- **Randomize conversion rates** — If the gold-per-hour of an activity varies unpredictably, players can't optimize a single path as easily.
- **Cap conversion** — Daily limits, weekly limits, diminishing returns. You can only earn 1000 PvP tokens per week, so grinding beyond that is pointless.

None of these fully solve the problem. Players will always find the optimal path. Your goal is to make multiple paths *close enough* in efficiency that personal preference and enjoyment can tip the scales.

---

### 9. The Psychology of Numbers

The math behind your economy isn't just math — it's psychology. How numbers *feel* to players matters as much as what they *do*.

**Big numbers feel good.** Dealing 9,999 damage is more satisfying than dealing 10 damage, even if the enemy in the first case has 10,000 HP and the enemy in the second case has 11 HP. Games like *Disgaea* lean into this hard, with damage numbers in the trillions. The absolute values are meaningless, but the *experience* of seeing huge numbers pop off the screen is visceral.

**Diminishing returns feel bad (but work well).** Getting your first 10% damage boost feels amazing. Getting your tenth 10% boost (going from 90% to 100%) feels barely noticeable, even though it's the same absolute increase. This is why most stat systems use diminishing returns — the first points in a stat are the most impactful, discouraging players from dumping everything into one attribute. It feels restrictive, but it produces healthier build diversity.

**Percentage bonuses are more intuitive than flat bonuses** at high values. "Deal 50% more damage" is instantly understandable regardless of your current damage number. "Deal 4,736 more damage" requires knowing your base damage to evaluate. Percentages scale automatically with progression.

**Anchoring** shapes perceived value. The first price a player sees becomes their reference point. If the first shop in your game sells a sword for 100 gold, that's the anchor. A sword for 200 gold later feels expensive; one for 50 gold feels like a deal — regardless of whether those prices are "correct." Premium currency stores exploit this ruthlessly: show the $99.99 pack first, and the $9.99 pack looks reasonable.

**Round numbers feel like milestones.** Leveling from 49 to 50 feels more significant than leveling from 48 to 49, even though the mechanical difference might be identical. Use round numbers for important thresholds and milestones in your economy.

---

### 10. Tuning an Economy

You can theorize about economy design forever, but at some point you need to put numbers in and see what happens. There are three complementary approaches.

**Spreadsheet modeling** is the fastest way to check basic math. Build a simple model: starting resources, income per unit of time, costs of items, projected resource curve over time. You'll immediately see if your numbers produce inflation, deflation, or a reasonable progression. The limitation: spreadsheets assume average behavior. Real players are not average.

**Simulation tools** like **Machinations** (machinations.io) let you build visual economy models and run them thousands of times. You define sources, sinks, converters, and random elements, then simulate to see distributions of outcomes. Machinations was purpose-built for game economy design — you can model a complete resource loop in an afternoon and stress-test it with Monte Carlo simulations. If your economy has randomness (loot drops, random rewards), simulation catches edge cases that spreadsheets miss.

**Playtesting** is irreplaceable. Your model might look perfect on paper and still feel terrible in practice. The spreadsheet says players earn enough gold to buy a sword by hour 3, but it doesn't account for the player who spent their gold on potions because they struggled with a boss. Playtesting reveals the gap between mathematical balance and experienced balance.

**The tuning loop:** Model it in a spreadsheet. Simulate it in Machinations if it's complex. Build it in the game. Playtest it. Adjust. Repeat. Economies that feel good are always the result of iteration, not first drafts.

One critical principle: **tune from the experience backward, not from the numbers forward.** Start by asking "How should the player feel at this point in the game?" and then set the numbers to produce that feeling. Don't start with the numbers and hope the feeling follows.

---

## Case Studies

### Case Study 1: Diablo 3's Auction House — When Real Money Breaks Everything

**Studio:** Blizzard Entertainment | **Year:** 2012 (launch), 2014 (Reaper of Souls) | **Genre:** Action RPG

Diablo 3 launched in May 2012 with a bold experiment: a real-money auction house (RMAH) that let players buy and sell loot for actual dollars. Blizzard took a cut of each transaction. The reasoning seemed sound — players traded items for real money in Diablo 2 through shady third-party sites, so why not make it official and safe?

The result was an economic catastrophe that nearly killed the franchise.

**The core problem was a broken source-to-sink ratio.** Diablo 3's loot system generated items constantly — every monster dropped something. With millions of players each generating hundreds of items per session, the total supply of items was astronomical. But sinks were almost nonexistent. Items didn't degrade, weren't consumed, and rarely became obsolete because the stat ranges overlapped across gear tiers. The auction house gave every item a global market. Supply was infinite; demand was finite. Classic hyperinflation.

**Real-money conversion made it worse.** Because items had dollar values, players evaluated drops against what they could *buy* for the equivalent time spent working a real job. Why farm for 10 hours when you could spend $5 and get better gear immediately? The core loop — kill monsters, get loot, get excited — was gutted. Loot stopped being exciting because the auction house always had something better for cheap. The game's fundamental reward mechanism was competing with, and losing to, its own economy.

**The gold economy inflated into meaninglessness.** Gold entered the system constantly (monster drops, vendoring items) but left slowly (repair costs, crafting fees were negligible). Gold values spiraled into the billions. Blizzard tried adding sinks — increased repair costs, a crafting system — but couldn't drain gold fast enough to matter. The economy had runaway positive feedback with no effective brake.

**Reaper of Souls (2014) fixed it by killing the auction house and redesigning loot from the ground up.** The "Loot 2.0" system reduced drop quantity dramatically but increased drop quality. Smart Loot biased drops toward your class. Legendaries became build-defining rather than stat-stick commodities. Most critically, the best gear became **account-bound** — you couldn't trade it. This single change severed the conversion path between time, items, and money. Items regained value because you had to *earn* them yourself.

The lesson: **the moment real-money conversion enters your economy, every design decision gets filtered through dollar-per-hour optimization.** The game stops being a game and becomes a market. Blizzard learned — expensively — that some conversion paths should never be opened.

---

### Case Study 2: Slay the Spire's Multi-Resource Elegance

**Studio:** MegaCrit | **Year:** 2019 | **Genre:** Roguelike deckbuilder

*Slay the Spire* manages at least seven distinct resource systems, and every single one creates meaningful decisions. No currency is wasted. No resource is filler. It's a masterclass in economy design through restraint.

**The resource inventory:** HP is your meta-currency across the entire run — every point of damage you take persists between fights, creating a slow pressure that builds across three acts. Gold buys cards, relics, potions, and card removals at shops — but you never have enough for everything you want. Cards are your primary mechanical resource, earned after combats, and critically, *not taking a card* is often the correct play because deck bloat weakens your draws. Energy (three per turn by default) is your per-turn action budget — you'll always have more cards in hand than energy to play them. Card draws determine your options each turn, making draw manipulation one of the game's deepest strategic layers. Relics are permanent passive modifiers earned from elites and events, and since you can't choose which relics appear, you adapt your strategy to what you find rather than pursuing a predetermined plan. Potions offer one-time-use emergency power with limited carry capacity, creating a constant "save it or use it" tension.

**Why it works: every resource has clear sources and sinks.** Gold comes from combats and events (sources) and leaves at shops (sink). HP comes from rest sites and certain cards (sources) and leaves from combat damage and certain events (sinks). Cards come from combat rewards (source) and can be removed at shops or certain events (sink). The loops are tight, visible, and comprehensible.

**Opportunity cost is everywhere.** After beating an elite, you choose one of three relics — and the two you didn't pick are gone forever. At a rest site, you can heal OR upgrade a card, not both. On the map, branching paths force you toward elites (risk for reward), events (unpredictable), shops (spend gold), or easy fights (safe but low payoff). Every single node on the map is an economic decision.

**Scarcity is precisely calibrated.** You almost always have *just* not enough of something. Not quite enough gold to buy the perfect card AND remove the bad one. Not quite enough HP to take the risky elite path comfortably. Not quite enough energy to play your whole hand. This persistent "almost-but-not-quite" feeling is what drives strategic thinking. If any resource were abundant, the decisions it creates would collapse.

The genius of *Slay the Spire's* economy is that it achieves complexity through the *interaction* of simple, individually comprehensible resources rather than through any single resource being complicated. Each currency is easy to understand in isolation. The depth comes from how they trade off against each other — and those tradeoffs create the game's famous "one more run" pull.

---

## Common Pitfalls

1. **Sources without sinks.** This is the most common economy-killing mistake. You give players gold for killing monsters but forget to give them enough things to spend it on. Gold piles up, becomes meaningless, and every gold-related reward stops mattering. **Every source needs a proportional sink. Audit your flow rates.**

2. **Too many currencies with no clear purpose.** You keep adding new token types to solve local problems — a PvP currency here, a seasonal currency there, a reputation currency for this faction. Soon players need a wiki to track what buys what. **Each currency must create a unique decision. If it doesn't, merge it into an existing one.**

3. **Ignoring the conversion problem.** You built five separate currencies but players discovered they can convert Activity A's currency into Activity B's rewards through a trading chain you didn't anticipate. Now Activity B is dead content. **Map every possible conversion path before launch. If two currencies can be converted, players will optimize the path.**

4. **Rewards that don't scale with progression.** Your early game feels perfectly tuned, but by mid-game the same 10-gold drops that felt exciting at hour 1 are laughable at hour 20. **Plan your reward curve across the entire experience. Playtest the late game, not just the early game.**

5. **Scarcity so extreme it becomes frustrating.** There's a difference between "I have to make a tough choice" and "I literally cannot progress." Overly tight economies punish average players while only satisfying optimization experts. **Tune for the median player, then add optional challenges for min-maxers.**

6. **Confusing the player about resource values.** If the player can't intuitively gauge whether 500 gold is a lot or a little, your economy is opaque. This happens when number ranges are too large, when costs vary wildly, or when there are too many places to spend a currency. **Anchor values early and keep the scale readable throughout.**

---

## Exercises

### Exercise 1: Resource Audit

**Time:** 30-45 minutes | **Materials:** A roguelike you know well (Slay the Spire, Hades, Dead Cells, Enter the Gungeon, Balatro — anything works), pen and paper or a spreadsheet

Pick your roguelike. List **every** resource in the game — not just the ones on the HUD. Include health, currency, abilities, cooldowns, inventory space, information (map knowledge), positional advantage, and anything else the player can "have more or less of." For each resource, identify:

1. Every **source** (where does it come from?)
2. Every **sink** (where does it go?)
3. The **scarcity level** (abundant, moderate, tight, critical)
4. One **decision it creates** (what choice does this resource force?)

You should find at least 8-10 resources in any well-designed roguelike. If you found fewer than 6, you missed some — think about hidden currencies like information or positioning.

### Exercise 2: Break an Economy

**Time:** 45-60 minutes | **Materials:** Paper and pen, a game you've played with a flawed economy (or use a hypothetical RPG)

Design a simple RPG economy on paper: one currency (gold), three sources (quest rewards, monster drops, selling loot), and three sinks (weapons, armor, consumables). Set specific numbers for each.

Now **break it** three different ways:

1. Create inflation (make sources overwhelm sinks)
2. Create a dead currency (make the sinks unappealing)
3. Create a degenerate strategy (make one source dramatically more efficient)

For each break, write 2-3 sentences explaining how you'd fix it without breaking something else. This exercise trains your instinct for spotting economy problems before they ship.

### Exercise 3: Multi-Currency Redesign

**Time:** 60-90 minutes | **Materials:** Design notebook or document, reference to a game with a single dominant currency

Pick a game that uses mostly one currency (many indie RPGs default to "gold does everything"). Redesign its economy with 3-4 currencies. For each new currency, define:

1. Its **name** and **thematic purpose**
2. Its **sources** (2-3 per currency)
3. Its **sinks** (2-3 per currency)
4. The **unique decision** it creates that gold alone couldn't
5. Whether it can **convert** to other currencies, and at what cost

Write a one-page economy design document. Then review it: Did you create a conversion problem? Is any currency redundant? Does each one justify its existence?

---

## Recommended Reading

### Essential

- **"Game Mechanics: Advanced Game Design"** by Ernest Adams & Joris Dormans — The definitive text on formal game economy modeling. Covers Machinations notation, economy patterns, and simulation-based balancing. Dense but essential if you're serious about economy design.
- **Machinations** (machinations.io) — The diagramming and simulation tool purpose-built for game economies. Free tier available. Spend an afternoon building a simple economy model and running simulations. Seeing the flows animate is worth a thousand spreadsheet cells.
- **"Thinking in Systems: A Primer"** by Donella Meadows — You read this for Module 2. Reread chapters on stocks, flows, and feedback loops with economy design specifically in mind. The bathtub metaphor is literally how game economies work.

### Go Deeper

- **"Virtual Economies: Design and Analysis"** by Vili Lehdonvirta & Edward Castronova — Academic deep-dive into economies in virtual worlds and MMOs. Covers real-money trading, inflation dynamics, and the behavioral economics of virtual goods.
- **"The Art of Game Design: A Book of Lenses"** by Jesse Schell — Lens #34 (Skill vs. Chance), Lens #38 (Challenge), and Lens #42 (Simplicity/Complexity) all directly apply to economy tuning.
- **Lost Garden blog** by Daniel Cook — His essays on "game design patterns" and "arrow diagrams" are foundational for thinking about resource flows visually.
- **GDC talks on game economy** — Search for presentations from the *Diablo III* and *Path of Exile* teams. The postmortem talks about Diablo 3's auction house are remarkably candid about what went wrong.

---

## Key Takeaways

1. **Everything is a currency.** Health, time, ammo, attention, information, space — if the player can have more or less of it and that changes their decisions, it's a currency. Design it intentionally or it'll design itself badly.

2. **Sources and sinks must balance.** If resources only flow in, you get inflation and meaningless rewards. If resources only flow out, you get deflation and frustrated players. Audit your flow rates continuously.

3. **Scarcity creates decisions; abundance kills them.** The sweet spot is "just not quite enough" — players should feel prosperous enough to have options but constrained enough that every choice costs something. Opportunity cost is the engine of interesting gameplay.

4. **Every currency must justify its existence.** If a currency doesn't create a unique decision, merge it or remove it. Multi-currency systems are powerful tuning tools but only when each currency has a clear purpose.

5. **Tune from the feeling backward, not the numbers forward.** Decide how the player should feel at each point in the game, then set the numbers to produce that feeling. Spreadsheets and simulations are tools, not destinations — playtesting is what reveals whether your economy actually works.

---

## What's Next

You now understand the invisible math behind game economies. Connect this knowledge to related design domains:

- **[Module 2: Systems Thinking & Emergent Gameplay](module-02-systems-thinking-emergent-gameplay.md)** — Economy systems are feedback loops. Revisit positive and negative feedback with fresh eyes, specifically looking at how economic feedback creates snowballing or rubber-banding.
- **[Module 3: Player Psychology & Motivation](module-03-player-psychology-motivation.md)** — The psychology of numbers, loss aversion around resources, and the sunk cost fallacy all connect directly to how players *feel* about your economy, not just how it functions mathematically.
- **[Module 6: Narrative Design & Storytelling](module-06-narrative-design-storytelling.md)** — Economy and narrative intertwine more than you'd expect. Resource scarcity creates narrative tension (survival horror), economic growth tells a power fantasy story (RPGs), and resource loss creates emotional stakes (roguelikes).
