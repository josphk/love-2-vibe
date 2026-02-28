# Module 5: Game Economy & Resource Design

> *"Every game has an economy. If your game has a number that goes up or down, you have an economy. Design it, or it designs itself."*

---

## Overview

You already think about game economies — you just don't know it yet. Every time you decide whether to use a health potion now or save it for the boss, you're making an economic decision. Every time you choose the sword instead of the shield, you're calculating opportunity cost. Every time you feel that "just one more turn" pull at 2 AM, an economy is working on your brain.

This module reframes how you see resources. **Health is a currency. Time is a currency. Attention is a currency. Information is a currency.** Once you internalize this, you'll start seeing the invisible math behind every design decision — why *Resident Evil* ammo feels precious while *DOOM Eternal* ammo feels plentiful but tactical, why *Civilization* turns are addictive, and why Diablo 3's real-money auction house almost killed the franchise.

You'll learn the formal vocabulary (sources, sinks, converters, traders), study economy archetypes across genres, and develop the intuition to tune an economy that creates meaningful decisions instead of busywork. You'll audit real game economies number by number, diagnose broken ones, and build your own on paper.

This module is structured as a workshop. The Core Concepts section gives you the vocabulary and frameworks — the language of economy design. The "How to Audit Any Game's Economy" section gives you a reusable 8-step methodology you can apply to any game. The Broken Economy Gallery shows you the four most common failure modes so you can recognize them instantly. The Economy Patterns Library gives you eight named, reusable building blocks for constructing economies. The Case Studies show all of these ideas in action across four very different games — from the catastrophic failure of Diablo 3's auction house to the spatial brilliance of Resident Evil 4's inventory grid. And the four Exercises put you in the designer's seat, building and breaking economies with your own hands.

**Time estimate:** 4-6 hours for a thorough pass through all content and exercises. The reading alone takes 60-90 minutes. Each exercise is self-contained — you can spread them across multiple sessions.

**What you'll be able to do after this module:**
- Audit any game's economy using a repeatable 8-step methodology
- Identify and name the 8 most common economy patterns
- Diagnose the 4 most common economy failure modes on sight
- Design a multi-currency economy with clear sources, sinks, and conversion paths
- Tune an economy using both spreadsheet modeling and feel-based iteration

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

Why does this expanded definition matter? Because **hidden currencies are often the most interesting ones.** Health in *Dark Souls* is a more consequential currency than gold — it directly determines risk tolerance, path choice, and whether you spend souls now or push forward. But if you only looked at the inventory screen, you'd think Souls were the primary economy. The game's deepest economic decisions happen in a currency (HP) that most people wouldn't even call a "resource."

Similarly, **information** is a currency that many designers fail to design intentionally. In *FTL: Faster Than Light*, knowing what's at the next beacon (through Long-Range Scanners) fundamentally changes your decision-making. In *Civilization*, fog of war means that unexplored territory is an information deficit — scouting spends military production to earn map knowledge. Every game with incomplete information has an information economy. If you're not designing it deliberately, you're leaving design space on the table.

#### Full Currency Audit: Hades

Let's prove this lens works by auditing *Hades* (Supergiant Games, 2020). If you only look at the menus, you see maybe six currencies. But watch what happens when you count honestly:

**Surface currencies** (visible in the UI):
1. **Darkness** — Permanent upgrade currency. Source: room rewards, boss kills. Sink: Mirror of Night talents.
2. **Chthonic Keys** — Unlock new weapons and mirror talents. Source: room rewards. Sink: weapon unlocks, mirror slot unlocks.
3. **Gemstones** — Cosmetic and functional upgrades to the House of Hades. Source: room rewards. Sink: House Contractor renovations.
4. **Nectar** — Relationship currency. Source: room rewards, fishing. Sink: gifted to NPCs for Keepsakes.
5. **Ambrosia** — Advanced relationship currency. Source: boss rewards (after first clears). Sink: gifted to NPCs for Companion summons.
6. **Diamonds** — Premium renovation currency. Source: boss rewards. Sink: House Contractor upgrades.
7. **Titan Blood** — Weapon aspect upgrades. Source: boss rewards (first clear per heat level). Sink: upgrading weapon aspects.
8. **Obols (gold)** — Per-run spending money. Source: room rewards, Boons. Sink: Charon's shop, Well of Charon.

**Hidden currencies** (real but not on a counter):
9. **HP** — You start each run with a finite pool. Sources: food rooms, healing Boons, Death Defiance. Sinks: taking damage. This is arguably your most important per-run currency.
10. **Death Defiance charges** — Limited extra lives. Source: mirror talent, certain Boons. Sink: dying. Each charge you still hold entering the final boss fight is a massive advantage.
11. **Boon slots** — You can only hold so many Boons, and replacing one means losing it. The limited Boon capacity is an invisible currency.
12. **Dash charges** — Your core defensive tool operates on a regenerating-charge system. Spend them recklessly and you're vulnerable.
13. **Cast ammo (Bloodstones)** — You get three. Each lodged Cast must be recovered from a dead enemy or regenerated. They're a micro-economy of their own.
14. **Room choice information** — When you see two doors, the icons tell you what reward each offers. That foreknowledge is a currency you spend by choosing one and forgoing the other.
15. **Heat (Pact of Punishment)** — A meta-currency that makes runs harder in exchange for access to repeated boss rewards. Heat doesn't spend or earn like traditional currency, but it gates your access to Titan Blood and Diamonds.

That's 15 currencies in a game that *feels* streamlined. The genius is that each one is simple individually. The depth comes from how they interact — spending Darkness on mirror talents that affect how much HP you conserve, which determines whether you can afford to spend Obols on damage upgrades instead of healing at Charon's shop.

> **Pause and try this:** Pick any game you've played in the last week. Set a 5-minute timer and list every currency — surface and hidden. Count information, positioning, cooldowns, inventory space, and anything else that can run out. Try to hit double digits.

#### Currency Classification Quiz

For each of the following, decide: is it a currency? If yes, what are its source and sink?

1. Your character's stamina bar in *Elden Ring*
2. The number of save slots in *Resident Evil* (classic typewriter system)
3. The fog of war in *Age of Empires II*
4. Your deck size in *Slay the Spire*
5. The number of buildings you can place per turn in *Settlers of Catan*

Answers: All five are currencies.

(1) Stamina regenerates over time (source) and is spent on attacks, dodges, and sprinting (sinks). The regeneration rate and maximum pool size are the key tuning knobs — *Elden Ring* gives you more stamina as you level Endurance, gradually shifting it from Crisis scarcity (early game, every dodge counts) to Comfortable (late game, you can swing freely).

(2) Ink ribbons are earned from exploration (source) and spent to save (sink) — a brilliantly cruel currency that turns a standard game feature (saving) into a scarce resource with real opportunity cost.

(3) Map visibility is earned by scouting (source) and "spent" when your opponent moves units into territory you thought was safe, making old information worthless (sink). Information decays — a form of the Spoilage pattern applied to knowledge.

(4) Deck size is increased by taking card rewards (source) and decreased by card removal at shops or events (sink) — and importantly, a smaller deck is usually *better*, inverting the typical "more is more" assumption. This is an economy where the "currency" has negative value when accumulated, making the sink (card removal) more valuable than the source.

(5) Building actions per turn are capped by your resource cards and board state — each building placed is a resource conversion event. Placing a settlement converts a building permit, brick, lumber, wool, and grain into a permanent income-generating asset.

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

- **Converters** transform one resource into another. A blacksmith converts gold + ore into a sword. A healing spell converts mana into health. Converters link separate resource loops together. Most of the "interesting" economic decisions in games happen at converters — they're the points where you choose how to transform what you have into what you need.
- **Traders** allow exchange between players (or between player and NPC). Traders introduce market dynamics — supply, demand, and the conversion problem we'll cover later. In single-player games, NPC shops act as fixed-rate traders. In multiplayer games, player-to-player trading creates dynamic markets with fluctuating rates that the designer can't fully control.

**The bathtub analogy from Module 2 applies perfectly here.** Your resource pool is the water level. Sources are faucets. Sinks are drains. Your job as a designer is to set the faucet and drain rates so the tub stays in the interesting zone — never empty (frustrating), never overflowing (meaningless).

**Three types of sinks** worth distinguishing:

- **Voluntary sinks** are things players choose to spend on: upgrades, items, cosmetics. These feel good because the player gets something in return. The risk: players might skip them entirely, breaking your flow rate assumptions.
- **Mandatory sinks** are costs the player must pay to continue: repair costs, entry fees, upkeep. These reliably drain resources but feel bad if overdone — nobody enjoys mandatory taxes.
- **Risk sinks** are potential losses: death penalties, gamble mechanics, degradation. These create tension and make decisions meaningful, but they trigger loss aversion and can feel punitive.

The healthiest economies use all three types. Voluntary sinks give players agency. Mandatory sinks prevent infinite accumulation. Risk sinks create drama. If your economy only has voluntary sinks, hoarders will never spend. If it only has mandatory sinks, spending feels like a punishment. A mix gives you the most control over the player's emotional experience.

#### Dark Souls Soul Economy Diagram

*Dark Souls* has one of the cleanest economies in games — a single primary currency (Souls) that serves multiple purposes, with a brutal penalty system that keeps it tight. Here's the full flow:

```
                    SOURCES                           SINKS
                ┌──────────────┐               ┌──────────────────┐
                │ Kill enemies │──┐             │ Level up (stats) │
                │ (~50-50,000  │  │         ┌──>│                  │
                │  per kill)   │  │         │   └──────────────────┘
                └──────────────┘  │         │   ┌──────────────────┐
                ┌──────────────┐  │         │   │ Buy items/spells │
                │ Consume soul │  ├──> [SOULS] ─┤                  │
                │ items        │  │         │   └──────────────────┘
                │ (1000-20000) │  │         │   ┌──────────────────┐
                └──────────────┘  │         │   │ Upgrade weapons  │
                ┌──────────────┐  │         │   │ (+materials)     │
                │ Boss kills   │──┘         ├──>│                  │
                │ (10K-70K)    │            │   └──────────────────┘
                └──────────────┘            │   ┌──────────────────┐
                                            │   │ Repair equipment │
                                            ├──>│                  │
                                            │   └──────────────────┘
                                            │   ┌──────────────────┐
                                            └──>│ DEATH (lose all) │
                                                │ [recoverable     │
                                                │  once, then gone]│
                                                └──────────────────┘
```

The critical design move: **death is a sink**. When you die, you drop all your Souls. You get one chance to retrieve them. Die again before reaching your bloodstain and they're gone permanently. This creates a natural drain on the economy — every player loses some percentage of their total Soul income to deaths. The harder the game is for a given player, the more Souls they lose, and the more they need to farm. It's a self-balancing system: struggling players lose more currency to death but also get more practice with each attempt.

Notice how death-as-a-sink creates a beautiful source/sink balance problem. Level-up costs increase with each level (sink scaling). Enemy Soul values increase as you progress to harder areas (source scaling). But death risk also increases in harder areas (sink scaling). The three curves interact: pushing into a dangerous area earns more Souls per kill but risks losing everything. Staying in a safe area earns less per kill but risks nothing. The player is constantly evaluating this risk/reward tradeoff — and the evaluation changes based on how many unspent Souls they're carrying. Holding 50,000 Souls makes you risk-averse. Holding 200 Souls makes you bold. The economy shapes your moment-to-moment psychology.

Also notable: Souls serve as BOTH your leveling currency AND your purchasing currency. This is a deliberate design constraint — every Soul spent on items is a Soul not spent on levels, and vice versa. A single currency with two competing sinks creates more tension than two separate currencies would. This is the Mutual Exclusion pattern operating within a single resource.

#### Flow Rate Worked Example

Let's put actual numbers on a hypothetical action RPG economy to see how source/sink balance works in practice.

**Setup:** Your game has one currency (Gold). A playthrough takes roughly 20 hours. You want the player to feel "tight but comfortable" — always able to afford something but never able to afford everything.

**Sources:**
- Monster kills: average 15 Gold per kill, ~200 kills per hour = **3,000 Gold/hour**
- Quest rewards: average 500 Gold per quest, ~2 quests per hour = **1,000 Gold/hour**
- Selling loot: average 100 Gold per item sold, ~5 items per hour = **500 Gold/hour**
- **Total income: ~4,500 Gold/hour**

**Sinks:**
- Weapon upgrades: ~2,000 Gold every 2 hours = **1,000 Gold/hour**
- Armor upgrades: ~1,500 Gold every 2 hours = **750 Gold/hour**
- Consumables (potions, etc.): ~300 Gold/hour for average player = **300 Gold/hour**
- Fast travel: ~100 Gold per use, ~3 uses per hour = **300 Gold/hour**
- Repair costs: ~200 Gold/hour = **200 Gold/hour**
- **Total spend: ~2,550 Gold/hour**

**The problem is immediately visible.** Income (4,500/hr) dramatically exceeds spending (2,550/hr). The player accumulates ~1,950 Gold/hour of surplus. By hour 10, they're sitting on nearly 20,000 Gold of unspent savings. By hour 20, they have ~39,000 Gold and nothing to spend it on. The economy is dead by the midpoint.

**Fixes:**
- Reduce monster kill Gold to 8 per kill (income drops to ~2,600/hr total)
- Add a new sink: enchanting system that costs 1,000-5,000 Gold per enchantment
- Add scaling repair costs that increase with gear level
- Introduce a Gold-sink vendor who sells expensive cosmetics or permanent stat bonuses

Now your total spend might be ~2,400/hr against ~2,600/hr income — a small surplus that accumulates slowly, giving the player a feeling of progress without creating a worthless currency pile.

> **Pause and try this:** Take the numbers above and calculate what happens if the player dies and loses 25% of their carried Gold (like a Souls-like game). How much does death-as-a-sink change the accumulation curve for a player who dies once per hour versus five times per hour?

---

### 3. Economy Archetypes

Not all game economies work the same way. Understanding the archetype you're building helps you anticipate problems before they happen.

**Static Economies** have fixed resource pools that don't grow over time. *Chess* is the purest example — you start with 16 pieces and can only lose them. No generation, no income, only attrition. Static economies create tension through loss — every piece sacrificed matters because it's gone forever. *Into the Breach* uses a static economy for its power grid: you start with a set amount and every hit against a building risks permanent loss.

What makes *Chess* deeper than "just attrition" is the **conversion dynamics**. A pawn is worth roughly 1 point. A knight or bishop is worth ~3. A rook is worth ~5. A queen is worth ~9. Every capture is a transaction. Trading your bishop (3) for their rook (5) is a +2 trade. Sacrificing your queen (9) for a checkmate is an infinite return on investment.

The entire strategic layer of chess is built on evaluating these conversions: Is this pawn sacrifice worth the positional advantage? Is losing the exchange (giving up a rook for a minor piece) worth disrupting their king safety? The piece values themselves are an economy — they create a shared framework for evaluating trades, even though no actual "currency" is spent. Chess masters are, at their core, economy experts operating in a static market. They've internalized the conversion rates so deeply that they can evaluate complex multi-piece exchanges in seconds.

*Into the Breach* pushes this further: your power grid starts at a set level and can be lost permanently when buildings are destroyed. The entire game is about preventing loss to a static resource. You can sometimes gain +1 grid power as a reward, but these are rare and precious — you might earn 2-3 grid power across an entire run while risking losing it in every battle. The scarcity is at Crisis level the entire game, which makes every tactical decision feel weighty.

**Dynamic Economies** have sources and sinks that create flow. Resources come in and go out over time. Most RPGs, strategy games, and survival games use dynamic economies. *Stardew Valley* has a seasonal economic loop: you invest gold in seeds (sink), wait for crops to grow (delay), harvest and sell (source). The dynamic is the cycle — invest, wait, return, reinvest. Dynamic economies must manage inflation carefully because sources tend to compound over time.

Here's what *Stardew Valley's* numbers actually look like across the first year:

```
Spring Year 1:  Parsnip seeds cost 20g. Sell for 35g. Profit: 15g per crop.
                With 15 crops: ~225g profit per harvest. ~3 harvests = ~675g.

Summer Year 1:  Blueberries cost 80g. Sell for ~240g per plant (3 berries).
                With 30 plants: ~4,800g profit per season.

Fall Year 1:    Cranberries cost 240g. Sell for ~600g per plant (multiple harvests).
                With 50 plants: ~18,000g profit per season.

Winter Year 1:  No farming income. Sinks continue (upgrades, animals, buildings).
                This is a designed deflation period — drain without faucet.
```

Notice the exponential growth: 675g in Spring, 4,800g in Summer, 18,000g in Fall. The game handles this by introducing proportionally larger sinks — barn upgrades (6,000g+), house renovations (10,000g+), and late-game items costing 100,000g+. Winter is the critical design choice: a full season with no farming income forces players to spend down savings, preventing infinite accumulation. It's a designed recession — the economy contracts by removing the primary source while keeping sinks active (tool upgrades, animal feed, building projects). By the time Spring Year 2 arrives, most players have spent down their reserves and are hungry for a new planting season. The boom/bust cycle restarts with bigger numbers but the same emotional arc: poverty, investment, patience, harvest, wealth, spending, repeat.

**Complex Economies** layer multiple dynamic economies on top of each other with converters and cross-connections. *EVE Online* is the extreme case — player-driven markets with thousands of resources, manufacturing chains, regional price variation, and real economic phenomena like speculation and market manipulation.

*Factorio* runs a complex economy where dozens of resource chains feed into each other and bottlenecks cascade through the entire system. Iron ore converts to iron plates. Iron plates plus copper plates convert to electronic circuits. Electronic circuits plus iron plates convert to inserters. Every item you build requires items that require items that require raw materials — and if any link in the chain bottlenecks, everything downstream starves. The game is essentially one giant converter puzzle. The "currency" you're really managing is *throughput* — not "how much iron do I have?" but "how many iron plates per minute can my system produce?" This shifts the economy from a stockpile model (accumulate resources) to a flow model (maintain production rates). It's a fundamentally different economic paradigm and produces gameplay unlike anything in the RPG or roguelike tradition.

Complex economies produce the richest emergent behavior but are the hardest to balance.

*Path of Exile* deserves special mention here. Its currency system is uniquely complex: there are no gold coins. Instead, **every currency item is also a crafting material.** Chaos Orbs reroll item stats and serve as the baseline "gold" for player trading. Exalted Orbs add a random modifier to rare items and are the "dollar" to Chaos Orbs' "cent." Divine Orbs reroll existing modifier values. Mirror of Kalandra duplicates an item and is so rare that finding one is a once-in-a-lifetime event. Because every currency has a use-value (you can consume it for crafting) and an exchange-value (you can trade it to players), the economy self-regulates in ways that a designer-set gold price never could. If Chaos Orbs become too cheap relative to their crafting utility, players start using them for crafting instead of trading, reducing supply and pushing the price back up.

**Match the archetype to your design goals.** If you want tight tactical decisions, lean static. If you want progression and growth, go dynamic. If you want player-driven emergent stories, build complex — but budget serious time for balancing.

**Hybrid economies** are common and often the best approach. *Slay the Spire* is primarily dynamic (gold flows in and out over the run) but uses static elements (relics are permanently gained and never lost, creating an ever-growing static collection) and complex elements (card synergies interact with relics to create emergent build archetypes). The archetype labels describe tendencies, not rigid categories. Most shipped games are hybrids. The labels help you identify which tendency dominates and whether it matches your goals.

> **Pause and try this:** Classify the last three games you played by archetype (Static, Dynamic, or Complex). Then ask: does the archetype match the game's design goals? If a game has tight tactical combat (suggesting Static) but a Dynamic economy with gold inflation, there's a mismatch. These mismatches are often the source of the game's worst economic problems.

---

### 4. Meaningful Scarcity

Here's the fundamental truth of economy design: **a resource only creates interesting decisions when it can run out.**

*Resident Evil* ammo is terrifying because you might not have enough to survive the next room. Every shot matters. Every miss hurts. The scarcity transforms a simple "press trigger" action into a tense calculation: Is this zombie worth two bullets? Can I dodge it instead? Should I save the shotgun shells for whatever's behind that door?

Now compare that to most shooters where ammo is everywhere. You pick up hundreds of rounds per encounter. The ammo counter might as well not exist. There's no decision to make because the resource is so abundant it's meaningless.

#### The Five-Point Scarcity Spectrum

Not all scarcity is created equal. Here's a spectrum from most to least scarce, with the design feeling each creates:

| Level | Name | Design Feeling | Example |
|-------|------|---------------|---------|
| 1 | **Crisis** | Desperation, panic, survival | *Resident Evil* ink ribbons (classic), ammo in *Amnesia: The Dark Descent* |
| 2 | **Tight** | Careful calculation, every unit matters | *Slay the Spire* energy per turn, *XCOM* action points |
| 3 | **Comfortable** | Options exist, but choosing costs something | *Stardew Valley* gold in mid-game, *Civilization VI* production |
| 4 | **Surplus** | Abundance in one area forces scarcity elsewhere | *Factorio* iron plates (plentiful, but using them here means not using them there) |
| 5 | **Infinite** | The resource doesn't constrain play | Basic ammo in *Destiny 2*, gold in late-game Skyrim |

Most games should aim for levels 2-3 for their core currencies. Level 1 is appropriate for horror and survival. Level 4 works when the real decision isn't "do I have enough?" but "where do I allocate what I have?" Level 5 means the resource has stopped doing design work — either add sinks or remove it.

#### DOOM Eternal: Scarcity Through Flow

*DOOM Eternal* (id Software, 2020) offers a masterclass in creating scarcity not through low supply but through **high-speed cycling**. The Doom Slayer has ammo, health, and armor — and all three are constantly running out. But here's the trick: they're also constantly being replenished, just through different actions.

- **Ammo** is scarce moment-to-moment (you run dry in 10-15 seconds of continuous fire) but abundant over time because **Chainsaw kills refill ammo**.
- **Health** drops when you take hits but refills from **Glory Kill** melee finishers.
- **Armor** drops from **Flame Belch** setting enemies on fire.

The result: you always have "enough" ammo, health, and armor — but only if you're constantly cycling through all three replenishment mechanics. Stop using the Chainsaw and you're out of ammo. Stop Glory Killing and you're out of health. Stop Flame Belching and you have no armor. The scarcity isn't about *total supply* — it's about *flow rate*. The resources are scarce in any given 10-second window, forcing constant tactical switching. You feel powerful and desperate at the same time.

This is a fundamentally different scarcity model from *Resident Evil*. RE scarcity is **stockpile scarcity** (you have a limited total supply, spend carefully). DOOM Eternal scarcity is **throughput scarcity** (supply is renewable but the pipe is narrow, so you must keep the tap running). Both create meaningful decisions, but they feel completely different to play.

**The design insight:** When designing scarcity, don't just ask "how much?" Also ask "how does it flow?" A resource that's scarce in total but arrives in steady drips (stockpile scarcity) creates careful conservation play. A resource that's abundant in total but scarce in any given moment (throughput scarcity) creates frantic action play. Same underlying principle — scarcity drives decisions — but radically different player experiences. Choose the flow pattern that matches the experience you want to create.

There's also a third model worth noting: **situational scarcity**, where a resource is abundant in some contexts and scarce in others. *Monster Hunter* ammo is plentiful in town (you can buy hundreds) but scarce during a hunt (you can only carry a limited amount and crafting mid-hunt takes precious time). The scarcity shifts based on context, which means the player's relationship to the resource changes depending on where they are. In town, ammo management is a trivial shopping trip. Mid-hunt, every shot counts. The same currency creates two completely different experiences based on context.

**The designer's question:** For each resource in your game, ask "What happens if the player has infinite amounts of this?" If the answer is "nothing changes," that resource isn't doing design work. Either make it scarce enough to matter or remove it entirely.

> **Pause and try this:** Pick a game you're playing right now. For its core resource (ammo, gold, mana, whatever), decide where it falls on the 5-point spectrum above. Then ask: would the game be more interesting if you moved it one level in either direction?

---

### 5. Opportunity Cost

Sid Meier famously said that a game is "a series of interesting decisions." But what makes a decision interesting? **Opportunity cost** — the value of what you give up by choosing one option over another.

"Sword or shield?" is only interesting if you can't buy both. The moment you can afford everything, the decision collapses into "buy everything." There's no cost, so there's no choice, so there's no game.

Opportunity cost operates on multiple levels:

- **Direct resource cost** — "This sword costs 500 gold. That shield also costs 500 gold. I have 600 gold." The cost is the item you didn't buy.
- **Time cost** — "I can explore this dungeon OR do this quest before the timer runs out." The cost is the path not taken.
- **Permanent choices** — "Pick one of three skill trees." The cost is the two trees you'll never have. *Dark Souls* builds are interesting precisely because respec options are limited — your choices stick.
- **Risk cost** — "I can fight this elite enemy for great rewards, but I might die." The cost is the potential loss of what you already have.

#### Multi-Layered Analysis: One Slay the Spire Decision

To see how opportunity cost stacks, let's dissect a single moment in *Slay the Spire*. You're playing Ironclad in Act 2. You've just beaten an Elite. You're offered three card rewards: **Immolate** (deal 21 damage to ALL enemies, costs 2 energy), **Reaper** (deal 4 damage to ALL enemies, heal for unblocked damage, costs 2 energy), and **Offering** (lose 6 HP, gain 2 energy and draw 3 cards, costs 0).

Here are four layers of opportunity cost happening simultaneously:

**Layer 1 — Direct card choice:** You can only pick one (or skip). Taking Immolate means not taking Reaper and not taking Offering. The surface cost is the two cards you didn't take.

**Layer 2 — Deck composition cost:** Adding any card makes your deck larger, which means you'll draw your other good cards less often. If your deck is already 25 cards, adding a 26th dilutes every existing card's appearance rate by ~4%. The cost of taking a card is reduced reliability of your current strategy. Sometimes the correct play is to skip all three rewards — the cost of a bigger deck outweighs the benefit of any individual card.

**Layer 3 — Build trajectory cost:** Immolate pushes you toward AoE damage (strong against Act 2's multi-enemy fights). Reaper pushes you toward a sustain strategy (strong in long fights). Offering pushes you toward engine/combo play (strong if you have cards that benefit from big draw turns). Each choice makes certain future cards and relics more valuable and others less valuable. You're not just choosing a card — you're choosing which *future version of your deck* you're building toward.

**Layer 4 — HP as opportunity cost:** You're at 52/80 HP. Taking Offering means paying 6 HP every time you play it. Those HP might be the difference between surviving the Act 2 boss. But if Offering lets you draw into your key cards faster, it might *save* you more HP by ending fights sooner. The HP cost is paid in one currency (health) but the benefit is received in another (tempo and card access). You're calculating a cross-currency exchange rate in your head.

All four layers interact. A min-maxing player processes all of them — consciously or instinctively — in about five seconds. This is why *Slay the Spire* card reward screens feel so consequential even though mechanically all you're doing is clicking one of four options. The opportunity cost is deep, visible, and irreversible.

Notice that the best opportunity cost decisions are ones where **reasonable players can disagree.** If one option is clearly superior, there's no real decision — the cost is illusory. But if two experienced *Slay the Spire* players would choose differently in the scenario above (one takes Immolate, the other takes Offering), the decision is doing its job. The opportunity cost is genuine because both options are defensible. When you design economic decisions, ask: "Would two skilled players choose differently here?" If yes, you've created meaningful opportunity cost.

**Great economy design maximizes opportunity cost at every turn.** The enemy of opportunity cost is **abundance**. When players have more than enough of everything, decisions become trivial. The paradox: players *want* abundance (it feels good to be rich) but *need* scarcity (to have interesting decisions). Your job is to make them feel like they're just barely able to afford the things they want — prosperous enough to have options, constrained enough to feel every choice.

> **Pause and try this:** Think of the last time you agonized over a decision in a game. What was the opportunity cost? Write down all the layers you can identify — direct cost, time cost, build trajectory, risk. If you can only identify one layer, the decision probably wasn't that interesting. Great decisions stack 3+ layers of opportunity cost.

---

### 6. Inflation, Deflation, and Scaling

In a 40-hour RPG, the player will earn vastly more resources at hour 30 than at hour 1. If your rewards don't scale with your costs, your economy breaks.

**Inflation** happens when resources accumulate faster than they're spent. Finding 10 gold at level 1 is exciting — it buys a new sword. Finding 10 gold at level 50 is insulting — it buys nothing. If your reward values don't scale, late-game currency becomes meaningless. Players sit on piles of gold with nothing to buy. The economy is dead.

**Deflation** happens when costs outpace income. If that level 50 sword costs 100,000 gold but enemies still drop 10-50 gold, the grind becomes soul-crushing. Players feel like they're running on a treadmill that's getting faster.

#### Worked Numerical Inflation Example

Let's trace how inflation kills an economy with actual numbers. Imagine a fantasy RPG with linear reward scaling but exponential cost scaling:

```
Level  | Gold per kill | Kills/hour | Gold/hour | Best weapon cost | Hours to buy
-------|---------------|------------|-----------|------------------|-------------
  1    |      5        |    30      |    150    |       200        |    1.3 hrs
  5    |     15        |    30      |    450    |       800        |    1.8 hrs
 10    |     30        |    30      |    900    |     3,000        |    3.3 hrs
 20    |     60        |    30      |  1,800    |    15,000        |    8.3 hrs
 30    |     90        |    30      |  2,700    |    50,000        |   18.5 hrs
 40    |    120        |    30      |  3,600    |   150,000        |   41.7 hrs
 50    |    150        |    30      |  4,500    |   500,000        |  111.1 hrs
```

The problem: Gold income scales linearly (+30 Gold/kill every 10 levels) but weapon costs scale exponentially. By level 50, the grind is 85x longer than it was at level 1. This is deflation by design mistake — the designer wanted big impressive numbers for late-game items but didn't scale income to match. The player experience at level 50 is miserable.

**The fix is to match scaling curves.** If costs scale exponentially, income must also scale exponentially. Or better: use one of the strategies below.

#### Comparison of Three Scaling Strategies

**Linear scaling** — Rewards and costs increase at the same rate. Simple but flat. 10 gold buys a sword at level 1; 1,000 gold buys a sword at level 50; the ratio is identical and nothing feels different. The numbers are bigger but the experience is unchanged. Good for short games. Boring for long ones.

Example: *Final Fantasy Tactics*. Weapon costs and mission rewards both scale roughly linearly. It works because the game is ~40 hours and the real progression comes from job abilities, not gear. The gold economy is nearly irrelevant — nobody remembers FFT for its shopping. The real "economy" is the Job Point system, where hours invested in one job class are hours not invested in another (opportunity cost of time).

**Exponential scaling** — Big numbers get bigger fast. *Diablo*-style games use this. You deal 100 damage at level 10 and 10,000,000 at level 70. It feels powerful, but eventually numbers lose meaning. "Is 4.2 billion damage good?" becomes an unanswerable question. Exponential scaling creates the thrill of explosive growth but requires careful UI work to keep numbers readable.

Example: *Diablo III* post-Reaper of Souls. Damage numbers in the trillions. Blizzard eventually had to add damage abbreviations (K, M, B) to the UI because the raw numbers couldn't fit on screen. The lesson: if your numbers outgrow your UI, you've probably gone too far. But there's a counterargument — *Vampire Survivors* uses absurdly large numbers and damage fountains as part of its core appeal. The key difference is that *Vampire Survivors* doesn't expect you to make precise calculations with those numbers. If your game requires the player to evaluate and compare numbers for decision-making, keep them small enough to parse. If numbers are just spectacle, let them go wild.

**Soft caps and resets** — Introduce new currencies or reset the scale at intervals. *Prestige* systems in idle games literally reset your progress in exchange for a permanent multiplier. Roguelikes reset the economy every run, solving inflation entirely. Percentage-based rewards ("10% more damage") scale automatically regardless of your current numbers.

Example: *Cookie Clicker* and other idle games use prestige resets — you sacrifice all current progress for "Heavenly Chips" that permanently boost future runs. Each reset lets you reach 10-100x further before hitting diminishing returns. The economy never inflates into meaninglessness because the scale keeps resetting. Roguelikes use the most elegant version of this: every run is a complete prestige reset with the permanent bonus being player skill and game knowledge rather than numerical multipliers.

#### The Number Feel Principle

**Players respond to the *feeling* of numbers, not just their mathematical relationships.** Going from 100 damage to 200 damage feels incredible — you doubled your power. Going from 10,000 to 10,100 feels like nothing, even though the absolute gain (100) is the same. This is **diminishing sensitivity** — the same absolute change feels smaller as the baseline grows.

Smart designers use number scaling as a **psychological tool**. Big damage numbers in *Diablo* feel great even if they're mathematically equivalent to smaller numbers with smaller enemy health pools. The trick is making sure the big numbers don't outpace your ability to communicate them meaningfully to the player.

The rule of thumb: **players feel ratios, not differences.** A 50% increase always feels significant. A +100 increase only feels significant when the base is small. Design your reward messaging around ratios when possible ("deal double damage!") rather than flat values ("deal 847 more damage!").

> **Pause and try this:** Open any game's upgrade screen. Look at the numbers for each upgrade tier. Calculate the percentage improvement at each tier. In a well-designed system, the percentage should stay roughly constant (each upgrade feels equally impactful) or decrease gradually (early upgrades feel amazing, later ones feel like refinement). If the percentage drops sharply, later upgrades will feel pointless. If it increases, later upgrades will overshadow early ones and the early game won't feel rewarding.

---

### 7. Multi-Currency Systems

Most games beyond the simplest use multiple currencies. Each currency is a **separate tuning lever** that lets you control different aspects of the player experience independently.

Common multi-currency patterns:

- **Basic + Premium** — Gold for everyday purchases, gems (often purchased with real money) for premium items. This is the free-to-play standard. The danger: when premium currency buys power, you've created pay-to-win.
- **Activity-specific currencies** — PvP tokens, dungeon tokens, raid tokens. Each currency funnels players toward specific content. *World of Warcraft* and *Destiny 2* use this heavily.
- **Reputation/faction currencies** — Earned through specific faction activities, spent on faction-exclusive rewards. Creates targeted progression: you invest in the faction whose rewards you want most.
- **Crafting material hierarchies** — Common, uncommon, rare materials that serve as parallel progression tracks. *Monster Hunter* turns every monster into a material source with specific drops, making each hunt economically purposeful.
- **Meta-currencies** — Resources that persist across runs or resets. *Hades'* Darkness, Gems, Keys, Nectar, Ambrosia, and Diamonds each control a different meta-progression system.

#### Hades Multi-Currency Breakdown

*Hades* is the best case study for multi-currency design because every single currency maps cleanly to a progression axis. Here's the full mapping:

| Currency | Progression Axis | Source Rate | Purpose |
|----------|-----------------|-------------|---------|
| Darkness | Character power | ~100-300/run | Mirror of Night stat upgrades. Core power progression. |
| Keys | Breadth of options | ~2-4/run | Unlock new weapons and mirror talent slots. Gives you more tools. |
| Gemstones | Quality of life | ~50-150/run | House Contractor cosmetic/functional upgrades. Makes the hub nicer. |
| Nectar | Relationship depth | ~1-2/run | Gift to NPCs for Keepsakes. Emotional and mechanical reward. |
| Ambrosia | Relationship mastery | ~0-1/run | Gift to NPCs for Companions. Gated behind boss clears. |
| Diamonds | Major upgrades | ~0-1/run | Expensive House Contractor items. Feeling of "big purchase." |
| Titan Blood | Weapon mastery | ~0-2/run | Upgrade weapon aspects. Deep specialization in specific playstyles. |
| Obols | Per-run tactics | ~100-300/run | Charon's shop. Resets every run. No long-term accumulation. |

The design brilliance: each currency controls an independent axis of progression. Darkness makes you stronger. Keys give you more options. Nectar deepens story. Titan Blood specializes your weapons. No single currency does what another currency does. And because they come from different sources (regular rooms, boss kills, fishing, etc.), the player engages with different content to earn each one.

Notice that the rarest currencies (Ambrosia, Diamonds, Titan Blood) are gated behind boss kills at increasing Heat levels. This creates a natural progression: early runs earn abundant Darkness and Keys (broad power growth), mid-game runs earn Nectar and Gemstones (relationship and QoL), and late-game runs earn Ambrosia, Diamonds, and Titan Blood (deep mastery and specialization). The currency rarity curve mirrors the player's journey from beginner to expert.

This tiered rarity also solves a common problem: **what do veteran players work toward?** In many games, late-game players have maxed out every currency and have nothing to pursue. Hades avoids this by ensuring that the rarest currencies (Titan Blood especially) require dozens of runs at escalating difficulty to fully max out. A player who has completed every weapon aspect upgrade has invested hundreds of hours — at which point they've gotten their money's worth many times over. The economy's longevity matches the game's intended lifespan.

The Obols (per-run gold) are worth special attention. Obols reset every run — you start with zero and build up through room rewards and Boon effects. This means Obols can never inflate across sessions. The Decay pattern (reset on death) solves the inflation problem that plagues persistent gold currencies. Within a single run, Obols are carefully calibrated: shops appear at specific points in each biome, and prices are set so that you can afford 1-2 items per shop visit but never everything. The per-run economy is tight and satisfying precisely because it resets constantly.

#### The One-Sentence Currency Test

**When to add a currency:** Add a new currency when you need a tuning lever that existing currencies can't provide. If players are accumulating gold too fast and you can't adjust it without breaking early-game balance, a separate late-game currency solves the problem without touching existing tuning.

**When you have too many:** If players can't remember what each currency does, or if they need a spreadsheet to track exchange rates, you've over-designed. *Destiny 2* at various points in its lifecycle had so many currency types that Bungie had to do currency consolidation passes. A good rule of thumb: if a currency doesn't create a unique decision that no other currency creates, merge it or remove it.

**The one-sentence test:** For every currency in your game, complete this sentence: "[Currency name] creates the decision of _____ vs _____." If you can't fill in the blanks with two meaningfully different options, the currency isn't pulling its weight.

Examples:
- "Darkness creates the decision of upgrading *this* mirror talent vs *that* mirror talent." (Pass — each mirror talent changes your playstyle differently.)
- "Gold coins create the decision of buying a sword vs buying a shield." (Pass — if both are useful and you can't afford both.)
- "Prestige tokens create the decision of... uh... buying the prestige reward?" (Fail — if there's only one sink, there's no decision.)

**Each currency should have a clear source, a clear sink, and a clear purpose.** If you can't explain what decision a currency creates in one sentence, it shouldn't exist.

> **Pause and try this:** Apply the one-sentence test to a game you're playing right now. For every currency, complete: "[Currency] creates the decision of _____ vs _____." If any currency fails the test, think about what would happen if that currency were removed or merged into another one. Would the game lose anything?

---

### 8. The Conversion Problem

The moment players can convert between currencies, your carefully separated tuning levers become connected — and one conversion path will always be more efficient than the others.

**Gold farming** is the classic example. If players can convert time into gold (grinding), gold into gear (shopping), and gear into power (equipping), then the most time-efficient gold source becomes the dominant strategy. Players will farm the one enemy or the one activity that produces the most gold per hour and ignore everything else. Your varied content collapses into a single grind.

**The time-to-currency conversion** is the deepest version of this problem. Players implicitly convert real-world time into every in-game currency. If Activity A gives 100 gold per hour and Activity B gives 80 gold per hour, Activity B is dead content — even if it's more fun. Min-maxers will always optimize for the best rate.

**Real-money conversion** makes everything worse. When players can buy currency with cash, every in-game economy decision gets a dollar sign attached. "Should I farm this dungeon for 3 hours or just buy the loot for $5?" This calculation fundamentally changes the player's relationship to the game. It's no longer a world to explore — it's a cost-benefit spreadsheet.

#### WoW Token Conversion Chain Analysis

The *World of Warcraft* Token is a fascinating example of designer-sanctioned conversion that created unexpected economic chains. Here's how it works:

A player buys a WoW Token from Blizzard for real money (~$20 USD). They list it on the in-game Auction House. Another player buys it with in-game gold (price fluctuates, historically 100K-300K gold). The buyer gets 30 days of game time (worth $15).

This creates a clear conversion path:

```
$20 USD ──> WoW Token ──> 200,000 Gold (approximate)

Therefore: $1 USD = ~10,000 Gold
Therefore: 1 hour of farming (~30,000 Gold) = ~$3 USD equivalent
```

Now every activity in the game has a dollar value. Running a dungeon that earns 5,000 gold? That's worth $0.50 of your time. Spending 3 hours farming herbs? That's ~$9 worth of gold. Suddenly players are making labor-economics calculations about virtual herb picking.

The deeper effect: **the Token created a conversion path between every currency in the game.** Gold buys Tokens. Tokens buy game time. Game time means more hours to earn every other currency. So Honor Points, Conquest Points, reputation, achievement progress — everything implicitly converts to gold converts to dollars. The entire economy collapsed into a single dimension: time-is-money-is-gold-is-everything.

**Mitigation strategies:**

- **Bind currencies to specific sinks** — Make PvP tokens only buyable through PvP and only spendable on PvP gear. If currencies can't convert, the conversion problem can't emerge.
- **Add friction to conversion** — Conversion taxes, time gates, and exchange rate penalties discourage mass conversion. *Path of Exile's* vendor recipes deliberately make conversion inefficient.
- **Randomize conversion rates** — If the gold-per-hour of an activity varies unpredictably, players can't optimize a single path as easily.
- **Cap conversion** — Daily limits, weekly limits, diminishing returns. You can only earn 1000 PvP tokens per week, so grinding beyond that is pointless.

None of these fully solve the problem. Players will always find the optimal path. Your goal is to make multiple paths *close enough* in efficiency that personal preference and enjoyment can tip the scales.

**A philosophical point about the conversion problem:** Some designers see optimal paths as a failure to be prevented. Others see them as an inevitability to be managed. The latter view is more productive. Players *will* optimize. The question isn't "how do I prevent optimization?" but "how do I make the optimized experience still fun?" If your most efficient farming route is also your most enjoyable content, the conversion problem becomes a non-issue. The problem only arises when the optimal path is *boring* — when efficiency and enjoyment diverge.

*Path of Exile* tackles this head-on by making its most rewarding content (endgame maps, league mechanics) also its most engaging gameplay. The "optimal path" is also the "fun path." Not every game can achieve this alignment, but it's worth striving for.

> **Pause and try this:** Pick a game with multiple currencies. Map every conversion path between them — including indirect ones through trading or shared sinks. Can you find a chain that converts Currency A into Currency D through B and C? How efficient is it compared to earning D directly?

#### Conversion Path Mapping Exercise

Here's a quick technique for auditing conversion problems in your own designs:

1. List every currency in your game across the top of a grid.
2. For each pair, ask: "Can Currency A become Currency B?" Mark Yes, No, or Indirect.
3. For every Yes or Indirect, calculate the conversion rate (how much A for how much B).
4. Find the cheapest path between any two currencies. That path will become the dominant strategy.
5. If any path is more than 20% more efficient than alternatives, it will warp player behavior.

**Example grid for a hypothetical RPG with four currencies:**

```
           Gold    XP     Rep    Mats
Gold        -     No     Yes*    Yes
XP         No      -     No      No
Rep        No     No      -     Yes*
Mats       Yes    No     No       -

* = indirect conversion (e.g., Gold -> buy faction items -> earn Rep)
```

In this grid, Gold converts to Rep through buying faction items, and Rep converts to Mats through faction vendors. This means Gold indirectly converts to Mats through two steps: Gold -> Rep -> Mats. If that indirect path is cheaper than earning Mats directly (by gathering), you've created an optimal path where rich players skip gathering entirely. The fix might be to make faction vendor prices high enough that buying your way to Rep is less efficient than earning it through faction activities.

The grid also reveals that XP converts to nothing — it's a dead-end currency. This is actually fine for XP (leveling up IS the reward), but if any other currency is a dead end with no outbound conversions, ask whether it's actually creating decisions or just accumulating.

**Time investment for this exercise:** Building the grid takes 15-20 minutes. Filling in conversion rates takes another 15-20 minutes. Finding the cheapest paths takes 10 minutes. Total: under an hour, and it will reveal more about your economy's health than weeks of informal playtesting.

---

### 9. The Psychology of Numbers

The math behind your economy isn't just math — it's psychology. How numbers *feel* to players matters as much as what they *do*.

**Big numbers feel good.** Dealing 9,999 damage is more satisfying than dealing 10 damage, even if the enemy in the first case has 10,000 HP and the enemy in the second case has 11 HP. Games like *Disgaea* lean into this hard, with damage numbers in the trillions. The absolute values are meaningless, but the *experience* of seeing huge numbers pop off the screen is visceral.

**Diminishing returns feel bad (but work well).** Getting your first 10% damage boost feels amazing. Getting your tenth 10% boost (going from 90% to 100%) feels barely noticeable, even though it's the same absolute increase. This is why most stat systems use diminishing returns — the first points in a stat are the most impactful, discouraging players from dumping everything into one attribute. It feels restrictive, but it produces healthier build diversity.

**Percentage bonuses are more intuitive than flat bonuses** at high values. "Deal 50% more damage" is instantly understandable regardless of your current damage number. "Deal 4,736 more damage" requires knowing your base damage to evaluate. Percentages scale automatically with progression.

#### Weber-Fechner Law

There's a formal principle behind why number scaling matters. The **Weber-Fechner Law** from psychophysics states that the *perceived* change in a stimulus is proportional to the *ratio* of the change, not its absolute value.

In plain terms: **humans perceive differences as percentages, not amounts.**

- Going from 10 to 20 damage feels like a massive improvement (100% increase).
- Going from 100 to 110 damage feels small (10% increase).
- Going from 1,000 to 1,010 damage feels like nothing (1% increase).

All three involve a +10 absolute increase. But the *felt* increase is completely different because our brains process the ratio.

This has concrete design implications:

- **Early-game rewards should be small in absolute terms** because the base is small, making the ratio feel large. Give 5 gold when the player has 10 and they feel rich (50% boost).
- **Late-game rewards must be large in absolute terms** to maintain the same felt impact. Give 5 gold when the player has 10,000 and they feel insulted (0.05% boost). You'd need to give 5,000 gold to match the same 50% feeling.
- **Scaling reward values is not "inflation"** — it's maintaining perceptual consistency. The player should feel the same excitement about a reward at hour 20 as they did at hour 2. That requires the ratio to stay constant even as the absolute values grow.

**Practical application:** If you want every reward to feel like a 20% boost, you need to scale reward values proportionally to the player's current holdings. A player with 100 gold should get rewards of ~20 gold. A player with 10,000 gold should get rewards of ~2,000 gold. Many games fail this by using flat reward tables — the same dungeon always drops 50 gold regardless of player level or wealth. By hour 20, that 50 gold is noise. The fix is either zone-based reward scaling (harder areas drop proportionally more) or level-based scaling (rewards multiply with player level).

#### Anchoring

**Anchoring** shapes perceived value. The first price a player sees becomes their reference point. If the first shop in your game sells a sword for 100 gold, that's the anchor. A sword for 200 gold later feels expensive; one for 50 gold feels like a deal — regardless of whether those prices are "correct." Premium currency stores exploit this ruthlessly: show the $99.99 pack first, and the $9.99 pack looks reasonable.

Practical anchoring techniques:
- **Set your first shop prices carefully.** They define the player's internal price scale for the entire game.
- **Show expensive options before affordable ones.** The expensive option anchors expectations upward, making the affordable one feel like a bargain.
- **Use "was/now" framing.** A sale sign showing "Was 500g, now 300g!" triggers anchoring — the 500g sets the reference, making 300g feel like a steal even if 300g is the "real" price.
- **Anchor with free.** If the player's first experience with a resource is getting it free (quest reward, tutorial gift), they'll anchor the value of that resource at "low." If their first experience is paying for it, they'll anchor it at "precious."

**Anchoring gone wrong:** In free-to-play games, premium currency is often introduced through a generous tutorial grant — "Here's 500 gems to get started!" The player spends them freely because they feel abundant. Then they run out and discover that 500 gems costs $4.99. The anchor was set at "free and plentiful," making the real price feel outrageously expensive by comparison. Some games handle this by being explicit about premium currency value from the start. Others use the mismatch deliberately to create a "taste" of premium spending that drives purchases. Both approaches involve anchoring — the difference is whether you're being honest about it.

#### Small Numbers vs. Large Numbers

A design choice that gets less attention than it deserves: **what number scale do you build your economy on?**

**Small number scales** (1-100): *Into the Breach* deals 1-4 damage per attack. *Slay the Spire* rarely exceeds triple digits. Small numbers are readable, every point matters, and players can do the math in their heads. The downside: there's no room for granularity. The difference between 3 damage and 4 damage is a 33% increase — there's no way to give a 5% boost. Small scales are precise but coarse.

**Large number scales** (1,000-1,000,000+): *Diablo*, *Disgaea*, idle games. Large numbers feel exciting and allow fine-grained tuning — the difference between 10,000 and 10,500 damage is a 5% increase you can meaningfully balance around. The downside: players stop processing the actual values. "Is 847,293 damage good?" requires context. Large scales are granular but opaque.

The right choice depends on your game. For tactical games where every point matters (*XCOM*, *Into the Breach*, *Fire Emblem*), use small numbers. For power-fantasy games where escalation IS the fun (*Diablo*, *Disgaea*, *Vampire Survivors*), use large numbers. For most games, stay in the hundreds — granular enough for tuning, small enough for mental math.

> **Pause and try this:** Look at the numbers in the last game you played. What scale does it use — small (1-100), medium (100-10,000), or large (10,000+)? Does the scale match the game's genre and tone? Would the game feel different if the numbers were 10x larger or 10x smaller? For most tactical games, the answer is yes — bigger numbers would dilute the feeling that each point matters.

#### Milestone Numbers and Loss Aversion

**Round numbers feel like milestones.** Leveling from 49 to 50 feels more significant than leveling from 48 to 49, even though the mechanical difference might be identical. Reaching 1,000 gold feels like an achievement; reaching 987 gold does not. This is partly cultural (we're trained to treat round numbers as significant) and partly perceptual (round numbers are easier to remember and compare). Use this to your advantage: place your best rewards, most important unlocks, and biggest power spikes at round numbers. Players expect them there — meeting that expectation feels satisfying, while placing a major milestone at level 47 feels arbitrary and confusing.

**Loss aversion amplifies economic decisions.** Behavioral economics tells us that losing something feels roughly twice as bad as gaining the same thing feels good (see [Module 3](module-03-player-psychology-motivation.md) for more on loss aversion). This means a -100 gold penalty creates a stronger emotional reaction than a +100 gold reward. Designers who understand this can calibrate their sinks: if you want a penalty to feel significant, it can be numerically smaller than an equivalent reward. If you want a risk to feel scary, the potential loss doesn't need to be as large as the potential gain — the emotional asymmetry does the work for you. *Dark Souls* leverages loss aversion brilliantly: the fear of losing your carried Souls makes every death feel devastating, even when the actual Soul count is modest.

**The sunk cost trap:** Players who have invested significant resources into a strategy resist abandoning it, even when a better option is available. "I've already spent 5,000 gold upgrading this sword — I can't switch to the axe now." This is irrational (the 5,000 gold is gone regardless of whether you switch), but it's psychologically powerful.

As a designer, you can use this to encourage commitment to builds and playstyles. *Dark Souls* leans into sunk cost: upgrading a weapon to +10 costs significant Souls and rare materials, making players deeply attached to their upgraded weapon even if a different weapon might suit an upcoming boss better. This attachment is a feature, not a bug — it creates a personal relationship between the player and their gear.

But beware: if you *require* players to abandon sunk costs frequently (frequent meta shifts, constant nerfs to popular builds), you'll generate intense frustration. The sunk cost fallacy only works as a design tool when players feel their investments are respected. MMOs that frequently rebalance and invalidate player gear choices erode trust in the economy — "Why invest in this build if it'll be nerfed next patch?"

---

### 10. Tuning an Economy

You can theorize about economy design forever, but at some point you need to put numbers in and see what happens. There are three complementary approaches.

**Spreadsheet modeling** is the fastest way to check basic math. Build a simple model: starting resources, income per unit of time, costs of items, projected resource curve over time. You'll immediately see if your numbers produce inflation, deflation, or a reasonable progression. The limitation: spreadsheets assume average behavior. Real players are not average.

#### Concrete Spreadsheet Structure

Here's a column layout that works for most game economies. Build this and you'll catch 80% of balance problems before anyone plays:

```
Column A: Game Stage (hour 1, hour 5, hour 10, hour 20...)
Column B: Expected Player Level / Power
Column C: Source 1 income rate (e.g., monster kills/hr * gold/kill)
Column D: Source 2 income rate (e.g., quest rewards/hr)
Column E: Source 3 income rate (e.g., loot sales/hr)
Column F: TOTAL INCOME (sum of C-E)
Column G: Sink 1 spend rate (e.g., equipment upgrades)
Column H: Sink 2 spend rate (e.g., consumables)
Column I: Sink 3 spend rate (e.g., services/fees)
Column J: TOTAL SPEND (sum of G-I)
Column K: NET FLOW (F minus J — positive = accumulation)
Column L: CUMULATIVE BALANCE (running total of K)
Column M: BEST AVAILABLE PURCHASE (most expensive useful item)
Column N: CAN AFFORD? (L >= M)
Column O: HOURS TO AFFORD (M / F at current income)
```

**The key diagnostic:** Column O — Hours to Afford. This tells you how long the player grinds for the next meaningful upgrade. If it's under 30 minutes, rewards are too frequent (no tension). If it's over 3 hours, the grind is punishing. The sweet spot for most games is 45-90 minutes between major purchases, with smaller purchases (consumables, minor upgrades) available every 10-15 minutes.

A common mistake is setting Hours to Afford as a constant. It should actually follow a curve: short at the beginning (to give new players frequent rewards and positive reinforcement), medium in the mid-game (to create a sense of earned progression), and variable in the late-game (some purchases come quickly, others are aspirational long-term goals). This creates a reward rhythm that matches the player's growing investment in the game.

**Column L — Cumulative Balance** is your inflation detector. If this number grows without bound, you have sources without sinks. If it regularly hits zero, you might be too tight. The ideal curve rises gradually with periodic drops (large purchases) and never goes exponential. Graph it visually — a healthy economy balance looks like a sawtooth wave (gradual rise, sharp drop on purchase, gradual rise again). An unhealthy economy balance looks like a hockey stick (slow start, then exponential growth into infinity).

**Simulation tools** like **Machinations** (machinations.io) let you build visual economy models and run them thousands of times. You define sources, sinks, converters, and random elements, then simulate to see distributions of outcomes. Machinations was purpose-built for game economy design — you can model a complete resource loop in an afternoon and stress-test it with Monte Carlo simulations. If your economy has randomness (loot drops, random rewards), simulation catches edge cases that spreadsheets miss.

Even without Machinations, you can do basic simulation in a spreadsheet. Add a random element to your income column (use RANDBETWEEN for drops), copy the row 1000 times, and look at the distribution of outcomes. What does the player's gold balance look like after 10 hours for the luckiest 10% of players versus the unluckiest 10%? If the gap is enormous, your random elements have too much variance. If the gap is tiny, your economy might feel deterministic and unexciting.

**Playtesting** is irreplaceable. Your model might look perfect on paper and still feel terrible in practice. The spreadsheet says players earn enough gold to buy a sword by hour 3, but it doesn't account for the player who spent their gold on potions because they struggled with a boss. Playtesting reveals the gap between mathematical balance and experienced balance.

Critically, **observe playtesters rather than just asking them.** Players often can't articulate why an economy feels wrong. They'll say "the game is too hard" when the real issue is that gold income is 20% too low and they can't afford the weapons that would make combat manageable. Watch their behavior: are they hoarding resources? That suggests sinks are unappealing. Are they constantly broke? Sources might be too tight. Are they ignoring a currency entirely? That currency might fail the one-sentence test. Behavior reveals truth that surveys miss.

#### Tuning by Feel vs. Tuning by Math

Both approaches have zealous advocates. Both are necessary. Neither alone is sufficient.

**Tuning by math** means setting values based on calculated curves, ratios, and simulation outputs. Strengths: consistent, reproducible, catches systemic problems. Weaknesses: can produce economies that are "balanced" but feel sterile. A spreadsheet-perfect economy where every item costs exactly the right amount can feel like the designer removed all surprise and generosity.

**Tuning by feel** means adjusting values based on playtest gut reactions. "This weapon feels too cheap." "That upgrade doesn't feel worth it." "The grind between levels 15-20 feels too long." Strengths: directly targets player experience, catches problems that math misses. Weaknesses: inconsistent, hard to reproduce, vulnerable to designer bias (you're not your player).

**The right process:** Start with math to get in the ballpark. Then tune by feel to make it sing. Use the spreadsheet to ensure your feel-based adjustments don't break systemic balance. Never let the spreadsheet override a clear playtest signal ("this feels wrong"), but always check that a feel-based adjustment doesn't cascade into unintended consequences elsewhere in the economy. One common workflow:

1. Build the spreadsheet model. Set initial values.
2. Play through the game yourself. Note every moment that feels wrong.
3. Adjust the spreadsheet values to fix those feelings.
4. Have 3-5 other people playtest. Note where their experience diverges from yours.
5. Adjust again. Repeat steps 4-5 until the economy feels right to people who aren't you.

**The tuning loop:** Model it in a spreadsheet. Simulate it in Machinations if it's complex. Build it in the game. Playtest it. Adjust. Repeat. Economies that feel good are always the result of iteration, not first drafts.

One critical principle: **tune from the experience backward, not from the numbers forward.** Start by asking "How should the player feel at this point in the game?" and then set the numbers to produce that feeling. Don't start with the numbers and hope the feeling follows.

#### Example: Experience-Backward Tuning

Suppose you're making a survival horror game and you want the player to feel "anxious about ammo" throughout. Here's how you'd tune backward:

1. **Define the target feeling:** "The player should always feel like they have *just barely* enough ammo if they play carefully, and not enough if they waste shots."
2. **Define the play pattern:** Average player accuracy is ~60%. They encounter ~20 enemies per area. Each enemy takes 2-4 shots to kill. So they need ~45-65 rounds per area.
3. **Set the supply:** Place 40-50 rounds per area. A careful player (70% accuracy) has enough. A sloppy player (50% accuracy) runs short by 10-15 rounds and must use the knife or avoid enemies. A perfect player has 5-10 surplus rounds — enough to feel competent but not rich.
4. **Test the feeling:** Playtest with 5 people. If 3+ say "I always had plenty of ammo," reduce supply by 10-15%. If 3+ say "I literally couldn't progress," increase supply by 10-15%. The numbers serve the feeling, not the other way around.

This approach is the opposite of "I'll put 50 ammo pickups per area and see what happens." Starting with the desired emotional state and reverse-engineering the numbers produces better results in fewer iterations.

**A final note on iteration:** No economy ships perfectly on the first pass. Even studios with dedicated economy designers expect 3-5 major tuning passes before the numbers feel right. The value of spreadsheets and simulations isn't that they produce the final numbers — it's that they get you close enough that playtesting can refine the last 20%. Without a model, your first playtest is guesswork. With a model, your first playtest is calibration.

---

## How to Audit Any Game's Economy

Economy auditing is the most practical skill in this module. Whether you're studying a competitor, learning from a masterpiece, or diagnosing your own game, this 8-step methodology produces a complete economy map. It works for any genre — from puzzle games to MMOs, from board games to mobile free-to-play.

The methodology is sequential: each step builds on the previous one. Resist the urge to skip ahead. The early steps (listing currencies, classifying them) seem simple but they lay the foundation for the analytical steps that follow. Budget 60-90 minutes for a thorough audit of a game you know well. Your first audit will take longer as you learn the process; by your third or fourth, you'll move through the steps quickly.

### Step 1: List Every Currency

Write down everything the player can have more or less of. Start with the obvious (gold, XP, items) and push into the hidden (HP, time, information, cooldowns, deck composition, board position). Use the "what can the player run out of?" test from Concept 1. Aim for 10+ currencies.

**Checklist to help you find hidden currencies:** Do you have a limited number of actions per turn? That's a currency. Do enemies get harder as you progress? Then time/progression is a currency working against you. Can you see what's ahead on the map? Information is a currency. Do you have limited inventory space? Space is a currency. Can you only equip one weapon at a time? Equipment slots are a currency.

### Step 2: Classify Each Currency

For each currency, record:
- **Type:** Consumable (spent once), renewable (regenerates), persistent (carries between sessions/runs), ephemeral (lost on death/failure)
- **Visibility:** Displayed on HUD, visible in menu, or invisible/implied
- **Player control:** Can the player choose when to earn/spend it, or is it automatic?

### Step 3: Map Sources

For each currency, list every way it enters the player's possession. Be specific: "enemies drop gold" is less useful than "regular enemies drop 10-30 gold, elites drop 100-500, bosses drop 1000-5000." Try to estimate actual numbers. Play for 30 minutes and track income, or check a wiki for drop rates.

### Step 4: Map Sinks

For each currency, list every way it leaves the player's possession. Again, be specific about costs and frequencies. Pay special attention to **optional** sinks (things the player could skip) versus **mandatory** sinks (things they must pay to progress). A healthy economy has both — mandatory sinks prevent infinite accumulation, optional sinks create decisions.

### Step 5: Identify Converters

Find every mechanic that transforms one currency into another. Blacksmith: gold + ore = weapon. Rest site: time = HP. Shop: gold = cards. Each converter is a link between two otherwise separate resource loops. Pay attention to **conversion ratios** — how much of Currency A converts to how much of Currency B? If the ratio is fixed, the conversion is predictable and players will optimize around it. If the ratio varies (random loot, fluctuating markets), the conversion introduces uncertainty that can create interesting decisions or frustrating variance, depending on implementation.

### Step 6: Calculate Flow Rates

For the 3-4 most important currencies, estimate: how much enters per hour of play? How much leaves per hour? What's the net accumulation rate? Does this rate change over the course of the game? If the net rate is positive and growing, the currency will eventually become worthless (inflation). If it's negative, the player will eventually run out (deflation). If it oscillates around zero, the economy is balanced.

**Quick test:** Divide the cost of the most expensive useful item by the hourly income rate. If the result is under 30 minutes, the economy is too loose. If it's over 5 hours, the economy is too tight for casual players.

### Step 7: Find the Scarcity Profile

For each currency, place it on the 5-point scarcity spectrum (Crisis / Tight / Comfortable / Surplus / Infinite). Note where scarcity changes across the game — a currency might be Tight in the early game and Surplus in the late game. A currency that shifts from Tight to Infinite over the course of the game has an inflation problem. A currency that stays at Tight throughout is probably well-tuned. A currency that fluctuates between Comfortable and Crisis (depending on player decisions) is often the sign of excellent economy design — the player's choices determine whether they're comfortable or in crisis.

### Step 8: Identify the Core Tension

What's the central economic question the game asks the player to answer? In *Slay the Spire*: "Which cards and relics do you commit to, knowing you can't have them all?" In *Dark Souls*: "Do you spend your souls now for safety or push forward for bigger rewards at the risk of losing everything?" In *Civilization*: "Which resource do you prioritize when you can't afford everything?" The core tension is the economy's reason for existing.

### Worked Example: Balatro Economy Audit

**Game:** *Balatro* (LocalThunk, 2024) | **Genre:** Roguelike poker deckbuilder

**Step 1 — Currencies:**
1. Chips (scoring currency, per-hand)
2. Mult (multiplier, per-hand)
3. Money (dollars, persistent across rounds)
4. Hands (plays per round)
5. Discards (per round)
6. Joker slots (capacity for passive effects)
7. Hand size (cards held)
8. Deck composition (which cards are in your deck)
9. Consumable slots (Tarot, Planet, Spectral cards)
10. Boss blind information (knowledge of upcoming challenge)
11. Skip value (money earned for skipping blind)

**Step 2 — Classification:**
- Chips/Mult: Ephemeral, rebuilt every hand, player-controlled through card play
- Money: Persistent within a run, carries between rounds, visible on HUD
- Hands/Discards: Renewable per round, visible, spent by playing/discarding
- Joker slots: Persistent capacity, visible, changed by buying/selling Jokers

**Step 3 — Sources:**
- Money: Earned from beating blinds ($3-5 base + bonuses), from interest on holdings (up to $5/round for every $5 held, max $25), from selling Jokers, from specific Joker effects
- Chips/Mult: Generated by played cards (chip values), enhanced by Planet cards (level up poker hands), amplified by Jokers
- Hands/Discards: Reset each round (base 4 hands, 3 discards), modified by Jokers and vouchers

**Step 4 — Sinks:**
- Money: Spent at shop (Jokers cost $2-8, Booster packs $4-8, Vouchers $10+, Planet/Tarot cards $3-4), spent rerolling shop ($5 base, increases)
- Chips/Mult: "Spent" by reaching the blind's target score (you need X chips to survive)
- Joker slots: "Spent" when you add a Joker and have to decide what to cut

**Step 5 — Converters:**
- Money -> Jokers -> Mult/Chips (buying Jokers increases scoring power)
- Money -> Planet cards -> Hand levels -> Chips/Mult (leveling up hand types)
- Money -> Tarot cards -> Deck composition (enhancing/destroying cards)
- Discards -> Information (discarding reveals new cards, giving you draw knowledge)

**Step 6 — Flow Rates:**
- Early game: Earn ~$4-6 per blind, spend ~$4-8 at shop. Net: roughly break-even.
- Mid-game (Ante 4-5): Earn ~$6-10 per blind plus $3-5 interest. Spend more selectively.
- Late game (Ante 7-8): Interest income can reach $25/round if you hold $25+. The economy pivots from "spend everything" to "hold cash for interest."

**Step 7 — Scarcity Profile:**
- Money: Tight (early), Comfortable (mid), Comfortable-to-Surplus (late if banking interest)
- Hands: Tight throughout (4 hands is always barely enough)
- Joker slots: Crisis (5 slots for an entire build — agonizing cuts)
- Mult: Tight-to-Crisis (scaling blind scores grow exponentially, your Mult must keep pace or you die)

**Step 8 — Core Tension:**
"Can your scoring engine scale exponentially fast enough to match the exponentially growing blind targets — and if not, where do you invest your limited money to fix the bottleneck?" The game is fundamentally about building a Mult/Chips engine that outpaces a designed inflation curve. Every dollar spent is a bet on which part of your engine needs the most improvement right now.

**What the audit reveals:** *Balatro's* economy is almost entirely about the money-to-scoring-power conversion chain. Money converts to Jokers (mult/chip engines), Planet cards (base hand improvements), and Tarot cards (deck composition changes). These three conversion paths compete for the same limited resource (dollars). The game's depth comes from evaluating which conversion path produces the most scoring improvement per dollar at any given moment — and that calculation changes based on your current Jokers, hand levels, and deck state. The economy is elegant precisely because one currency (money) feeds into multiple competing conversion paths, each of which multiplicatively affects the same output (score).

---

## Broken Economy Gallery

Studying failures teaches faster than studying successes. Here are four common economy failures, diagnosed with the vocabulary from this module. Every shipped game exhibits at least one of these to some degree. The goal isn't to eliminate them entirely (that's likely impossible in a complex system) but to recognize them early enough that you can mitigate them before they ruin the player experience. Learn these four failure modes and you'll be able to diagnose most economy problems on sight.

### Failure 1: The Faucet Without a Drain

**Symptom:** Players accumulate a resource without limit. Late-game rewards of that resource feel meaningless. The currency counter keeps growing but stops mattering.

**Diagnosis:** Sources exist but sinks are insufficient or unappealing. The bathtub is overflowing.

**Classic example:** Gold in *The Elder Scrolls V: Skyrim*. By mid-game, most players have tens of thousands of gold with nothing meaningful to spend it on. Shops have low gold reserves (they can't buy your expensive loot). Trainers are capped at 5 sessions per level. Housing costs are one-time purchases. The result: gold becomes junk. Finding 500 gold in a dungeon chest elicits zero excitement because the player is already drowning in it.

**The numbers tell the story.** A player who clears dungeons and sells loot earns roughly 5,000-10,000 gold per hour by level 30. The most expensive house (Proudspire Manor in Solitude) costs 25,000 gold — about 3-5 hours of play. Once purchased, there's nothing in that price range left. Shops restock their gold reserves (typically 500-750 gold) every 48 in-game hours, meaning you can't even sell your most valuable loot without waiting. The economy effectively ends at hour 30 of a 100+ hour game.

**The fix:** Add gold sinks that scale with progression. Expensive late-game services, consumable luxury items, gold-based crafting, or money sinks tied to convenience (fast travel fees that increase with distance). Skyrim needed repeatable gold sinks at the 10,000g+ range — enchanting services, property upgrades, or prestige purchases that remain meaningful throughout the game. The modding community eventually built these fixes (*Trade and Barter*, *Taxes of the Nine Holds*), confirming the base game's economy was incomplete.

### Failure 2: The Death Spiral

**Symptom:** When a player falls behind, the economy punishes them further, making recovery increasingly difficult. Losing begets more losing.

**Diagnosis:** A positive feedback loop (as defined in [Module 2](module-02-systems-thinking-emergent-gameplay.md)) operates on the resource system. Losing resources reduces the player's ability to earn resources.

**Classic example:** *Monopoly*. When you can't afford to buy properties, you land on opponents' properties and pay rent, draining your cash further. With less cash, you can't buy properties or upgrade. Your opponents invest their rent income into houses and hotels, increasing the rent you owe. The spiral accelerates until bankruptcy — and the game continues for another miserable hour because elimination doesn't end the game for everyone.

**Why it's pernicious:** Death spirals feel unfair because the player is punished for *being behind*, not for making bad decisions. By the time you notice you're in a spiral, it's too late to recover. The game has already decided the outcome — it just hasn't told you yet. This is especially damaging in multiplayer, where trailing players must sit through an experience they've already lost.

**The fix:** Add negative feedback (rubber-banding). Give struggling players catch-up mechanics — cheaper purchases, bonus income, reduced penalties. *Mario Kart's* item distribution is the classic solution: players in last place get better items, compressing the field. In economic terms, add a faucet that opens wider when the tub is low. Another approach: cap how far ahead the leader can get by introducing soft ceilings on accumulation (diminishing returns on income past a threshold).

### Failure 3: The Currency Graveyard

**Symptom:** The game has 12 currencies but 8 of them are confusing, redundant, or forgettable. Players constantly check wikis to remember what each currency does.

**Diagnosis:** Currencies were added to solve local problems without evaluating the global system. Each new currency made sense in isolation but the total is incoherent.

**Classic example:** *Destiny 2* (various points in its lifecycle). Players tracked Glimmer, Legendary Shards, Enhancement Cores, Enhancement Prisms, Ascendant Shards, Bright Dust, Silver, Mod Components, Upgrade Modules, Exotic Ciphers, Spoils of Conquest, seasonal currencies (Parallax Trajectory, Opulent Umbral Energy, Plundered Umbral Energy...), and more. Many currencies served overlapping functions. Several were introduced for one season and abandoned. Bungie eventually did multiple "currency consolidation" passes, merging or removing redundant currencies.

**How it happens:** Each currency was added by a different team or for a different content release. The PvP team needed a PvP currency. The seasonal content team needed a seasonal currency. The endgame team needed upgrade materials. Nobody stepped back to ask "do all of these need to be separate?" The result is a graveyard of single-purpose currencies that clutter the UI and overwhelm new players.

**The fix:** Apply the one-sentence test to every currency. If two currencies create the same decision, merge them. If a currency exists only because of a single piece of content, fold it into an existing currency. Cap your game at 5-8 currencies unless you're building an MMO — and even then, think hard. Run a currency audit every time you add a new currency: does it create a decision that no existing currency creates? If not, use an existing one.

### Failure 4: The Optimal Path

**Symptom:** One strategy for earning resources is dramatically more efficient than all others. Players who discover it skip most of the game's content and grind the optimal path exclusively.

**Diagnosis:** A conversion chain exists where one activity dominates all others in resource-per-hour efficiency. The conversion problem (Concept 8) has been left unaddressed.

**Classic example:** Gold farming in many MMOs. In *World of Warcraft* at various points, specific farming routes (Herbalism in certain zones, specific dungeon runs, Auction House flipping) produced so much more gold per hour than questing or PvP that economically motivated players ignored 90% of the game's content. The game has hundreds of activities, but the economy rewarded only a handful.

**How to detect it:** Calculate the resource-per-hour rate for every significant activity in your game. If the best activity is more than ~30% above the second-best, you have an optimal path problem. Players will find it within days of launch. In the age of social media and content creators, the optimal path will be documented and publicized within hours of release. Plan accordingly.

**The fix:** Equalize the time-to-reward ratio across activities within 20%. Add diminishing returns to repeated activities (halved rewards after the 5th dungeon run per day). Gate the highest rewards behind varied activities (weekly bonuses that require doing 3 different activity types). Make the optimal path shift regularly so no single grind becomes dominant forever. *Path of Exile* rotates its league mechanics precisely to prevent any one farming strategy from calcifying.

---

## Economy Patterns Library

These are named, reusable patterns you can apply to your own designs. Think of them as design building blocks — modular components you can combine and adapt for your specific game. Each pattern describes a relationship between a player and a resource: how it arrives, how it leaves, and what decisions that creates.

Naming patterns matters because it gives you a shared vocabulary for design conversations. Instead of "maybe we should make it so that your gold grows if you don't spend it," you can say "let's add an Interest pattern to the gold economy." This precision speeds up design discussions and helps teams evaluate tradeoffs more clearly.

### Pattern 1: Drip Feed

**Definition:** Resources arrive in small, steady increments rather than large windfalls.

**How it works:** The player earns a little bit with every action — every kill, every room cleared, every turn completed. No single drop is exciting, but the accumulation feels satisfying over time.

**Example:** *Hades* Darkness. You get 5-25 Darkness per room. No single room reward feels amazing, but after a full run you've earned 200-400 Darkness, enough for a meaningful mirror upgrade.

**When to use it:** When you want consistent pacing and don't want single lucky drops to distort progression. Good for persistence currencies that carry across sessions or runs.

**Danger:** Pure drip feeds can feel monotonous. Combine with occasional windfall bonuses (a rare room that drops 10x the normal amount) to break the monotony without wrecking the accumulation curve. The drip establishes the baseline; the windfall creates memorable spikes.

### Pattern 2: Boom/Bust

**Definition:** Resources arrive in large, infrequent bursts followed by periods of spending or scarcity.

**How it works:** The player experiences cycles: a "boom" where resources flood in (boss rewards, quest completion, selling a big haul), then a "bust" where they spend it down and operate lean until the next boom.

**Example:** *Stardew Valley* harvest days. You spend weeks tending crops with no income, then sell the entire harvest at once for a massive gold infusion. That gold gets reinvested in seeds, upgrades, and animals, draining your reserves until the next harvest.

**When to use it:** When you want rhythmic pacing with clear "payday" moments. Creates natural milestones and spending sprees that feel great.

**Danger:** If the "bust" period lasts too long, players feel stuck and frustrated. The bust should always have a visible end — the player should know when the next boom is coming. *Stardew Valley* succeeds because you can see crops growing day by day. A boom/bust where the next payoff timing is unknown creates anxiety, not anticipation.

### Pattern 3: Prestige Reset

**Definition:** The player voluntarily sacrifices accumulated resources to restart with a permanent bonus.

**How it works:** After reaching a certain threshold, the player can "prestige" — reset their primary resources to zero in exchange for a permanent multiplier, new ability, or other irreversible advantage. Each reset lets them reach further faster.

**Example:** *Cookie Clicker* Heavenly Chips. *Rogue Legacy* gold spent on permanent manor upgrades between runs. *Hades* meta-progression (each run resets Obols and Boons, but Darkness and Keys persist).

**When to use it:** When your economy would otherwise inflate beyond control. Prestige resets solve inflation by periodically draining the tub. Also creates a satisfying "fresh start with wisdom" feeling.

**Danger:** If the permanent bonus from resetting is too weak, nobody will prestige (why sacrifice everything for a 5% boost?). If it's too strong, the pre-prestige game becomes a tedious mandatory prologue. The first prestige should feel like a revelation — "Oh, THIS is how the game really works." Subsequent prestiges should each feel roughly 30-50% faster than the previous one to maintain momentum.

### Pattern 4: Mutual Exclusion

**Definition:** Two or more options are explicitly locked against each other — choosing one permanently removes the other.

**How it works:** The player is presented with a fork: take path A or path B, never both. This isn't about cost (you could afford either) — it's about exclusivity. The game won't let you have both.

**Example:** *Dark Souls* boss soul weapons. Each boss soul can be crafted into one of 2-3 weapons. Once crafted, the soul is consumed. You'd need NG+ to try the other options. *Slay the Spire* card rewards (pick 1 of 3 or skip). *Undertale's* Pacifist vs. Genocide routes.

**When to use it:** When you want decisions to feel permanent and identity-defining. Forces commitment and creates replay value ("next time I'll try the other option").

**Danger:** Mutual exclusion only works when both options are viable and appealing. If one choice is clearly superior, the exclusion creates frustration rather than tension ("I'm forced to pick A because B is terrible, but I wish I could have both"). Balance the options so that the choice is genuinely painful — that pain is the design doing its job.

### Pattern 5: Interest / Investment

**Definition:** Holding a resource grows it passively, rewarding patience over spending.

**How it works:** Unspent resources generate additional resources over time. Saving is rewarded, creating tension between spending now and investing for the future.

**Example:** *Balatro's* interest mechanic — every $5 held generates $1 at end of round, up to $25. Do you spend $8 on a Joker, or hold $25 to earn $5/round in interest? *Civilization* city growth — population (a resource) grows faster when you invest food into it rather than diverting food to production.

**When to use it:** When you want to reward strategic patience and create a saving-vs-spending tension. Dangerous if over-tuned — if hoarding is always better than spending, the game becomes "never buy anything."

**Danger:** Interest can create an anti-fun "banking" strategy. In *Balatro*, very disciplined players sometimes hoard $25 from early rounds and skip buying anything, relying on their starting Jokers to survive. If interest income overwhelms the value of spending, the optimal strategy becomes "never buy anything." Counter this with escalating threats that punish under-investment (the way *Balatro's* exponential blind scaling does).

### Pattern 6: Decay / Spoilage

**Definition:** Held resources lose value or disappear over time, punishing hoarding.

**How it works:** Resources degrade if not used. This forces spending and prevents infinite accumulation without designer-imposed caps.

**Example:** *Darkest Dungeon* stress buildup (heroes accumulate stress that must be "spent" at the Hamlet's Abbey or Tavern). Food in survival games spoiling over time. Equipment durability in *Breath of the Wild* (weapons break, forcing constant replacement from the environment).

**When to use it:** When you want to prevent hoarding and keep resources flowing. The opposite of the Interest pattern — decay pushes spending, interest pushes saving. Some games use both simultaneously on different currencies for maximum tension.

**Danger:** Decay frustrates players who feel punished for playing cautiously. *Breath of the Wild's* weapon durability is one of the most divisive design decisions in modern gaming — some players love the forced improvisation, others hate losing a weapon they're attached to. If you use decay, make sure the replacement cycle is frequent enough that losing a resource doesn't feel devastating. The player should think "time to grab something new," not "there goes my favorite sword."

### Pattern 7: Sacrifice for Information

**Definition:** Spending a tangible resource to gain knowledge that enables better future decisions.

**How it works:** The player trades something concrete (gold, HP, items) for information (map reveals, enemy stats, future event previews). The value of the trade depends on how well the player uses the information.

**Example:** *Slay the Spire* boss relic choices (you see three options and must evaluate which is best for your build — the information about all three makes the choice meaningful). Scouting units in strategy games (spending production on scouts that could have been soldiers). *FTL* long-range scanners (spending a system slot on previewing beacon contents).

**When to use it:** When you want players to value planning and foresight. Information currencies reward system mastery because experienced players extract more value from the same information.

**Danger:** Information is only valuable if the player can act on it. If you reveal that the next room has a fire-breathing dragon but the player has no way to prepare for fire damage, the information is useless — it's anxiety without agency. Make sure the information you sell enables actual decision-making: "I know the boss is weak to ice, so I'll equip my ice sword" is meaningful. "I know the boss is hard" is not.

### Pattern 8: Overflow / Spillover

**Definition:** When one resource is maxed, excess converts into a different resource.

**How it works:** Rather than wasting excess when a resource hits its cap, the overflow feeds into another pool. This keeps earning feeling productive even at capacity.

**Example:** *Civilization VI* overflow production — if your city finishes a building and has leftover production points, they apply to the next item in the build queue. *Diablo* experience at max level converting into Paragon points. *Hades* Darkness earning after maxing the Mirror of Night (excess Darkness still counts for achievement thresholds).

**When to use it:** When players hit resource caps and you want to avoid the frustrating feeling of "wasted" earnings. Spillover keeps the earning loop satisfying even when the primary pool is full.

**Danger:** If the spillover target is too weak, it still feels like waste ("great, my overflow production built this building 3 seconds faster — who cares?"). The spillover destination should be visibly valuable. *Civilization VI* handles this well because overflow production goes directly into whatever you're building next, which is always something you actively chose.

#### Combining Patterns

The best economies mix multiple patterns across different currencies. *Hades* uses Drip Feed for Darkness, Boom/Bust for boss-reward currencies (Titan Blood, Diamonds), Mutual Exclusion for Boon choices within a run, and Prestige Reset at the run level (Obols and Boons reset, meta-currencies persist). Each currency uses the pattern that best fits its design purpose.

*Slay the Spire* combines patterns differently: Drip Feed for gold (steady income from combats), Mutual Exclusion for card rewards (pick 1 of 3 or skip), Decay for HP (it only goes down unless you actively heal — a slow drain), and Sacrifice for Information (paying for map reveals, evaluating relic choices). The mix means no two decision types feel the same — choosing a card (exclusive) feels different from spending gold at a shop (investment) feels different from managing HP (decay management).

Here's a quick reference for pattern combinations that work well together:

- **Drip Feed + Boom/Bust** on different currencies gives steady baseline income with occasional exciting windfalls
- **Interest + Decay** on different currencies creates a push-pull between saving one resource and spending down another
- **Mutual Exclusion + Overflow** lets players commit to a path while ensuring rejected options aren't completely wasted
- **Prestige Reset + Drip Feed** makes each reset feel like a fresh start while the persistent currency provides a sense of permanent progress

When you design your own economy, assign a pattern to each currency and check that the mix creates variety — if every currency uses the same pattern, the economy will feel monotone.

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

The fix also introduced a critical sink that the original game lacked: **the Kanai's Cube** system let you destroy a Legendary item to extract its special power as a passive effect. This meant that finding a duplicate Legendary wasn't useless — you could cube it. Items that would have been vendor trash became valuable extraction targets. The economy finally had meaningful sinks that scaled with progression: the better your gear, the more valuable the items you'd destroy for their powers.

**The key economic concepts at play:** Faucet without drain (items generated constantly with no degradation sink). Conversion problem (real money converted to items, collapsing the loot loop). Death spiral (players who couldn't afford AH gear fell further behind). The Diablo 3 launch economy exhibited three of the four Broken Economy Gallery failures simultaneously — only the Currency Graveyard was absent, because the game had too few currencies rather than too many.

The lesson: **the moment real-money conversion enters your economy, every design decision gets filtered through dollar-per-hour optimization.** The game stops being a game and becomes a market. Blizzard learned — expensively — that some conversion paths should never be opened.

---

### Case Study 2: Slay the Spire's Multi-Resource Elegance

**Studio:** MegaCrit | **Year:** 2019 | **Genre:** Roguelike deckbuilder

*Slay the Spire* manages at least seven distinct resource systems, and every single one creates meaningful decisions. No currency is wasted. No resource is filler. It's a masterclass in economy design through restraint.

**The resource inventory:** HP is your meta-currency across the entire run — every point of damage you take persists between fights, creating a slow pressure that builds across three acts. Gold buys cards, relics, potions, and card removals at shops — but you never have enough for everything you want. Cards are your primary mechanical resource, earned after combats, and critically, *not taking a card* is often the correct play because deck bloat weakens your draws. Energy (three per turn by default) is your per-turn action budget — you'll always have more cards in hand than energy to play them. Card draws determine your options each turn, making draw manipulation one of the game's deepest strategic layers. Relics are permanent passive modifiers earned from elites and events, and since you can't choose which relics appear, you adapt your strategy to what you find rather than pursuing a predetermined plan. Potions offer one-time-use emergency power with limited carry capacity, creating a constant "save it or use it" tension.

**Why it works: every resource has clear sources and sinks.** Gold comes from combats and events (sources) and leaves at shops (sink). HP comes from rest sites and certain cards (sources) and leaves from combat damage and certain events (sinks). Cards come from combat rewards (source) and can be removed at shops or certain events (sink). The loops are tight, visible, and comprehensible.

**Opportunity cost is everywhere.** After beating an elite, you choose one of three relics — and the two you didn't pick are gone forever. At a rest site, you can heal OR upgrade a card, not both. On the map, branching paths force you toward elites (risk for reward), events (unpredictable), shops (spend gold), or easy fights (safe but low payoff). Every single node on the map is an economic decision.

**Scarcity is precisely calibrated.** You almost always have *just* not enough of something. Not quite enough gold to buy the perfect card AND remove the bad one. Not quite enough HP to take the risky elite path comfortably. Not quite enough energy to play your whole hand. This persistent "almost-but-not-quite" feeling is what drives strategic thinking. If any resource were abundant, the decisions it creates would collapse.

**The economy also solves the scaling problem elegantly.** Because each run takes 45-60 minutes and resets completely on death, inflation is impossible. You never reach a point where gold is worthless because you never accumulate gold for more than one run. The roguelike structure is itself an economy pattern (Prestige Reset, Pattern 3) applied at the architectural level. Every run starts fresh, with meta-progression happening through player *knowledge* — you learn which cards are good, which relics synergize, which paths are optimal. Knowledge is the true persistence currency, and it can never inflate because the game's randomness ensures you always face novel decisions.

**What you should steal from Slay the Spire:** The principle that simple, comprehensible currencies create depth through interaction, not through individual complexity. If you're designing a multi-resource system, make each resource easy to explain in one sentence. Then design the *connections* between resources to create layered decisions. The depth emerges from the web, not from any single strand.

The genius of *Slay the Spire's* economy is that it achieves complexity through the *interaction* of simple, individually comprehensible resources rather than through any single resource being complicated. Each currency is easy to understand in isolation. The depth comes from how they trade off against each other — and those tradeoffs create the game's famous "one more run" pull.

---

### Case Study 3: Balatro — Exponential Scaling Done Right

**Studio:** LocalThunk | **Year:** 2024 | **Genre:** Roguelike poker deckbuilder | **Price:** ~$15

*Balatro* has one of the most aggressive scaling curves in modern gaming — blind targets grow exponentially, requiring your scoring engine to grow exponentially to match. Most games with exponential scaling collapse into either "meaningless big numbers" or "impossible difficulty walls." *Balatro* threads the needle.

**The core economy loop:** Each blind has a target chip score. You get 4 hands (plays) and 3 discards per round. Your poker hands generate chips and multipliers. Chips x Mult = score. If your score beats the target, you survive and earn money. If you fail, the run ends — total loss, no partial credit. The targets start at ~300 and grow to 300,000+ by the final Ante.

That's roughly a 1000x increase in required score across 8 Antes. How does the player keep up?

**Multi-resource interaction is the engine.** Your score isn't determined by a single resource — it's the product of several:

- **Base chips** from the poker hand played (Pair = 10, Flush = 35, etc.)
- **Planet card levels** that increase base chips and mult for specific hand types
- **Joker multipliers** — some add flat mult (+4), others multiply mult (x2), others add chips
- **Enhanced cards** — Steel cards give x1.5 mult, Glass cards give x2 mult but may break
- **Played card chip values** — each card contributes its face value in chips

Because the final score is a *product* (chips times mult), improving any single component has a multiplicative effect on the total. Going from 100 chips x 10 mult to 100 chips x 20 mult doubles your score. Going from 100 x 20 to 200 x 20 also doubles your score. The player is constantly asking: "Which component of my engine is the weakest link? Where does the next dollar of investment produce the biggest multiplicative gain?"

**The money economy creates the real decisions.** You earn $3-5 per blind beaten, plus interest ($1 per $5 held, up to $5). Shops sell Jokers ($2-8), Planet cards ($3), Tarot cards ($3), consumable packs ($4-8), and Vouchers ($10+). You never have enough money for everything. The constant tension: spend money to improve your scoring engine NOW, or save money to earn interest that funds bigger purchases LATER.

This is the Interest pattern (Pattern 5) in action, and it works beautifully. A player holding $25 earns $5/round in interest — substantial free income. But to hold $25, you must skip buying Jokers and upgrades for several rounds. If your scoring engine can't keep up with the rising blind targets during those rounds, you die. The optimal strategy is a knife-edge balance between investment and accumulation that shifts based on your current engine state.

**Why the exponential scaling doesn't collapse:** Three reasons.

First, **multiplicative scoring makes every upgrade feel impactful.** Because score = chips x mult, even a small addition to either side creates a visible jump. Adding a +4 mult Joker when you have 20 mult is a 20% increase. The Weber-Fechner ratio stays high because multiplicative systems grow faster than additive ones.

Second, **the game is short.** A full *Balatro* run takes 30-45 minutes. There's not enough time for the economy to inflate into meaninglessness. You're always in the "growth phase" — never in the "sitting on piles of useless currency" phase.

Third, **every Joker is a build-defining decision.** With only 5 Joker slots, each Joker is roughly 20% of your entire strategy. Buying a Joker isn't a minor incremental upgrade — it reshapes your scoring engine. This keeps the economy feeling like every purchase matters, even in the late game.

**A concrete scoring example:** Say you're in Ante 5. You play a Flush (base: 35 chips, 4 mult). Your five cards contribute ~50 chips each (250 total). You have three Jokers: one adds +30 chips, one adds +8 mult, one multiplies mult by x3. The calculation: (35 + 250 + 30) chips = 315 chips. (4 + 8) mult = 12. Then x3 = 36 final mult. Score: 315 x 36 = 11,340. The blind target might be 10,000. You barely clear it.

Now imagine you spend $6 to buy a Planet card and level up Flush once (adding +15 chips and +2 mult to the base). Same hand, same Jokers: (50 + 250 + 30) = 330 chips. (6 + 8) = 14 mult. x3 = 42. Score: 330 x 42 = 13,860. That $6 purchase increased your score by 22%. The multiplicative structure means even a modest investment creates visible gains — which is why spending feels impactful and hoarding feels risky.

The lesson: **exponential scaling works when the growth mechanism is multiplicative across multiple interacting resources, the game is short enough to avoid saturation, and each upgrade is proportionally significant.** *Balatro* achieves all three.

---

### Case Study 4: Resident Evil 4 — The Attache Case as Spatial Economy

**Studio:** Capcom | **Year:** 2005 (original), 2023 (remake) | **Genre:** Survival horror / action | **Price:** ~$20-40

Most inventory systems are lists. *Resident Evil 4* made its inventory a **spatial puzzle** — and in doing so, turned inventory management into a currency system that creates decisions every few minutes.

**The Attache Case** is a grid-based inventory. Each item occupies a specific rectangular shape on the grid: handgun ammo is 1x2, the shotgun is 2x8, a first aid spray is 1x2, the rocket launcher is 2x8, herbs are 1x1. The case has a fixed number of squares (expandable with upgrades). You physically rotate and arrange items to fit them — like a Tetris puzzle where each piece is a resource you might need to survive.

**Space is the currency.** Every item in the case costs grid squares to hold. A rocket launcher is immensely powerful but takes 16 squares — the same space as 8 handgun ammo stacks. Carrying a sniper rifle means not carrying grenades. Every item competes for the same finite pool of space, and unlike gold, you can't earn more space incrementally. Case upgrades exist but are rare and expensive.

This creates a unique form of opportunity cost: **spatial opportunity cost.** It's not "can I afford this?" (gold) or "is this worth my time?" (hours). It's "where does this physically fit, and what do I have to give up to make room?" The decision is tangible, visual, and immediate. You can *see* the tradeoff on the grid.

**The economy flow looks like this:**

```
SOURCES                         THE CASE (limited grid)              SINKS
┌─────────────┐                ┌──────────────────────┐
│ Enemy drops  │──> Ammo  ──>  │ ████░░████░░██████░░ │  ──> Shooting (ammo consumed)
│ Crate loot   │──> Herbs ──>  │ ██░░░░████░░░░░░░░██ │  ──> Healing (herbs consumed)
│ Shop purchase│──> Guns  ──>  │ ████████████████░░░░ │  ──> Selling to merchant
│ Treasure find│──> Gems  ──>  │ ██░░░░██████░░██████ │  ──> Selling for gold
└─────────────┘                └──────────────────────┘
                                     ↑
                               GRID SPACE = CURRENCY
```

**The Merchant adds a second economy layer.** Treasures (gemstones, antiques, golden items) have no combat use — their only purpose is to be sold to the Merchant for gold (pesetas). But they take up case space while you carry them. Every treasure in your case is space NOT available for ammo, health, or weapons. The decision: sell now at the next Merchant for gold to buy upgrades? Or hold onto the Elegant Mask because you found an insert that combines with it for triple the sell value — but carrying both costs 6 grid squares?

**Gun upgrades create a meta-economy.** The Merchant sells firepower, reload speed, and capacity upgrades for each weapon. These cost gold but provide permanent improvements. Since you earn gold by selling treasures (which cost space) and by selling weapons (which are also useful), the entire economy is a web of conversions: space converts to treasure-carrying-capacity converts to gold converts to weapon power.

**Why the spatial economy works:**

- **Visceral.** You can see the tradeoff. Moving items around the grid makes the economy tangible in a way that numbers on a screen never can. Rotating a rifle to fit alongside grenades is a physical act of economy management.
- **Frequent.** Every enemy encounter produces loot that forces an inventory decision. The economy is always active — you're never more than a few minutes from the next spatial decision.
- **Non-fungible.** A 1x2 space in the top-right isn't the same as a 1x2 space in the bottom-left if there's a 2x8 rifle blocking the path. Grid geometry adds a puzzle dimension that flat currencies don't have. Two players with identical items might have different effective capacities based purely on how they've arranged their cases.
- **Emotionally charged.** Deciding to drop handgun ammo to make room for a healing item creates genuine tension. You're choosing between "I might need this later" and "I need this now." The physicality of dragging an item out of the case and onto the ground makes the loss feel real.

**The 2023 remake refined the spatial economy further.** The remake added craftable ammo (spend gunpowder + resources to create specific ammo types — a converter mechanic), weapon charms that take case space but provide passive bonuses, and a more generous case size that shifts the feel from "survival horror tight" to "action game comfortable." The shift is instructive: the same spatial economy mechanic produces survival tension or action empowerment depending solely on how much grid space you give the player. The case size IS the difficulty lever.

**How the spatial economy changes across the game:** Early in RE4, the case is small and nearly every item competes for space. You're making hard choices constantly: keep the shotgun ammo or pick up the green herb? By mid-game, you've purchased case upgrades and the pressure eases slightly — you have room for 2-3 weapons and reasonable ammo supplies. By late-game, you may have a large case with comfortable space, but the game introduces more weapon types and more consumable varieties to fill it. The spatial economy scales not by changing the rules but by changing the ratio of case size to item diversity. More items to choose between, even with more space, keeps decisions active.

This progression mirrors the Dynamic Economy archetype: early scarcity, mid-game comfort, late-game complexity. But it achieves this through spatial geometry rather than numerical accumulation. It's the same economic arc, expressed through a completely different medium.

**Design takeaway for your own games:** If you have an inventory system, ask whether it could do more design work. Even a simple "you can only carry 4 weapons" limitation creates spatial economy decisions. *RE4* shows that the more tangible and visible you make the constraint, the more engaging the decisions become. A grid you can see and manipulate beats a list you scroll through.

The lesson: **currency doesn't have to be a number.** Physical space, grid layout, and geometric constraints can function as economic systems. If your game has an inventory, it has a spatial economy. *RE4* is the game that proved inventory management could be a game mechanic in its own right, not just bookkeeping.

---

## Common Pitfalls

1. **Sources without sinks.** This is the most common economy-killing mistake. You give players gold for killing monsters but forget to give them enough things to spend it on. Gold piles up, becomes meaningless, and every gold-related reward stops mattering. **Every source needs a proportional sink. Audit your flow rates.**

2. **Too many currencies with no clear purpose.** You keep adding new token types to solve local problems — a PvP currency here, a seasonal currency there, a reputation currency for this faction. Soon players need a wiki to track what buys what. **Each currency must create a unique decision. If it doesn't, merge it into an existing one.**

3. **Ignoring the conversion problem.** You built five separate currencies but players discovered they can convert Activity A's currency into Activity B's rewards through a trading chain you didn't anticipate. Now Activity B is dead content. **Map every possible conversion path before launch. If two currencies can be converted, players will optimize the path.**

4. **Rewards that don't scale with progression.** Your early game feels perfectly tuned, but by mid-game the same 10-gold drops that felt exciting at hour 1 are laughable at hour 20. **Plan your reward curve across the entire experience. Playtest the late game, not just the early game.**

5. **Scarcity so extreme it becomes frustrating.** There's a difference between "I have to make a tough choice" and "I literally cannot progress." Overly tight economies punish average players while only satisfying optimization experts. **Tune for the median player, then add optional challenges for min-maxers.**

6. **Confusing the player about resource values.** If the player can't intuitively gauge whether 500 gold is a lot or a little, your economy is opaque. This happens when number ranges are too large, when costs vary wildly, or when there are too many places to spend a currency. **Anchor values early and keep the scale readable throughout.**

7. **Forgetting that time is always a currency.** Even if your game has no explicit timer, real-world play time is a resource players spend. If your economy asks players to grind for 4 hours to earn what feels like 20 minutes of progress, you're taxing their time budget unfairly. **Respect the player's time. Every hour they spend in your game should feel like meaningful progress, not a treadmill.** Calculate the time-to-meaningful-reward ratio for every activity in your game and make sure it stays in a range that respects player investment.

8. **Testing only with designer-skill players.** You know every optimal path, every efficient conversion, every correct build. Your playtesters might not. An economy that feels "tight but fair" to you might feel punishing to a casual player or trivially easy to a min-maxer. **Test across skill levels. Watch someone who has never played your game struggle with your economy — those moments reveal problems your personal playtesting never will.**

---

## Exercises

### Exercise 1: Full Economy Audit

**Time:** 60-90 minutes | **Materials:** A game you've played for 10+ hours, pen and paper or spreadsheet, the 8-step methodology from the "How to Audit Any Game's Economy" section above

**Objective:** Produce a two-page economy map of a real game.

**Steps:**

1. Choose your game. It works best if you've played enough to see mid-game and late-game economies, not just the tutorial. Good candidates: *Hades*, *Slay the Spire*, *Stardew Valley*, *Dark Souls*, *Balatro*, *Monster Hunter*, *Civilization VI*, *Dead Cells*, *Hollow Knight*.

2. Follow the 8-step methodology from start to finish. Write your answers as you go. Don't skip steps — each one builds on the previous.

3. After completing all 8 steps, create a visual economy map. Draw each currency as a box. Draw arrows from sources into each box and from each box to its sinks. Draw conversion arrows between currencies that can be exchanged. Label each arrow with approximate flow rates where you can estimate them. Use different arrow styles for different flow types: solid lines for reliable flows, dashed lines for random/variable flows, thick lines for high-volume flows, thin lines for trickle flows.

4. Identify the weakest point in the economy — the currency, source, or sink that feels most underdesigned or problematic. Write 3-4 sentences explaining why it's weak and how you'd fix it.

**Deliverable:** A two-page document containing (1) the 8-step audit answers and (2) a visual economy flow map with annotated arrows. Optional: a short paragraph diagnosing the economy's biggest weakness.

**Assessment criteria:** Did you find at least 10 currencies including hidden ones? Does every currency in your map have at least one source and one sink? Can you trace a conversion chain between at least two currencies?

**Stretch goal:** After completing the audit, compare your findings against online resources (wikis, economy guides, Reddit discussions). Did the community identify currencies or conversion paths you missed? Community knowledge often reveals edge cases and exploits that solo analysis overlooks.

**Why this exercise matters:** Economy auditing is the single most transferable economy design skill. You can practice it on any game, anytime. Professional economy designers audit competitor products regularly — not to copy them, but to build pattern recognition. After auditing 5-10 different games, you'll start recognizing common economy structures instantly, like a musician who can hear chord progressions after enough practice.

---

### Exercise 2: Economy Sandbox — Build, Break, Fix

**Time:** 60-90 minutes | **Materials:** Index cards or paper, pen, a six-sided die, a friend (optional but recommended)

**Objective:** Paper prototype a simple economy and stress-test it through three scenarios.

**Steps:**

1. **Build the economy (15 min).** Design a small RPG economy on paper:
   - One currency: Gold
   - Your character starts with 50 Gold and 10 HP (max 10)
   - Three sources: Monster kills (roll 1d6 for Gold earned), Quest completion (flat 15 Gold), Selling loot (roll 1d6 + 2)
   - Four sinks: Health potion (8 Gold, restores 3 HP), Weapon upgrade (25 Gold, +1 damage permanently), Armor upgrade (20 Gold, -1 damage taken permanently), Inn rest (5 Gold, full HP restore)
   - Combat: Each fight costs 1-3 HP (roll 1d6: 1-2 = lose 1 HP, 3-4 = lose 2 HP, 5-6 = lose 3 HP)
   - You can do 1 action per turn: fight a monster, complete a quest (takes 2 turns), visit town (buy/sell/rest)
   - Goal: survive 20 turns with the highest Gold total

2. **Play through Scenario A: Normal (10 min).** Play 20 turns making "reasonable" decisions — buy healing when low, upgrade when affordable, fight regularly. Track your Gold and HP on a sheet after every turn. At the end, note your final Gold total and how many times you almost died.

3. **Play through Scenario B: Breaking the Economy (10 min).** Deliberately find and exploit the most efficient strategy. Can you maximize Gold by ignoring certain sinks? Can you find a degenerate loop? Play 20 turns with pure optimization. Note how different the experience feels.

4. **Play through Scenario C: Fixing the Break (10 min).** Based on what you exploited in Scenario B, add or adjust ONE rule to close the exploit. Maybe add a food cost (2 Gold/turn upkeep), or make monsters hit harder after turn 10, or add diminishing returns on quest rewards. Play 20 turns with the fix. Did it work? Did it create a new problem?

5. **Write up (15-20 min).** Write a half-page analysis comparing the three scenarios. What broke? How did you fix it? Did the fix create unintended consequences?

**Deliverable:** The turn-by-turn tracking sheets for all three scenarios, plus the half-page comparison analysis.

**Assessment criteria:** Did you successfully identify an exploit? Does your fix address the exploit without making the game too tight or too loose? Does your analysis demonstrate understanding of source/sink balance?

**Hint for Scenario B:** The most common exploit in this system is ignoring armor upgrades and potions entirely, fighting every turn for maximum Gold income, and relying on Inn rests (5 Gold for full heal) as the only sink. The Inn rest is dramatically more cost-efficient than potions (8 Gold for 3 HP vs 5 Gold for full 10 HP). This makes potions dead content. One fix: make Inn rests take 2 turns (time cost) or make them unavailable during quests. Another: make the Inn cost scale with your total Gold (5 Gold + 10% of holdings).

**What you should learn:** Economy exploits almost always emerge from one sink being dramatically more efficient than others, collapsing multiple decision points into a single "always do this" strategy. The fix is usually to equalize the efficiency of competing sinks, not to nerf the dominant one into uselessness.

---

### Exercise 3: Multi-Currency Design Challenge

**Time:** 75-90 minutes | **Materials:** Design notebook or document

**Objective:** Design a multi-currency economy from scratch for a hypothetical game and produce a one-page economy design document.

**Steps:**

1. **Choose a game concept (5 min).** Pick one of these prompts or invent your own:
   - A roguelike where you explore a haunted mansion (30-minute runs)
   - A farming sim set on a space station (seasonal loop)
   - A deckbuilder where you're a defense attorney (trial-based progression)
   - A strategy game about running a medieval tavern (real-time management)

2. **Design 4-5 currencies (20 min).** For each currency, define:
   - Name and thematic justification (why does this currency exist in the fiction?)
   - 2-3 sources with approximate income rates
   - 2-3 sinks with approximate costs
   - The unique decision it creates (use the one-sentence test)
   - Scarcity level on the 5-point spectrum
   - Whether it persists across sessions/runs or resets

3. **Map conversions (10 min).** Draw a grid showing which currencies can convert to which others. For each conversion, note: is it direct or indirect? What's the friction? Is there a rate imbalance that could create an optimal path?

4. **Stress-test on paper (15 min).** Walk through a hypothetical play session in your head (or on paper). Hour 1: what does the player earn and spend? Hour 5: has anything inflated or deflated? Hour 10: are all currencies still doing design work, or has one become irrelevant? Adjust values as needed.

5. **Write the economy design document (20-25 min).** One page, covering:
   - Currency summary table (name, source, sink, purpose — one row per currency)
   - Economy flow diagram (boxes and arrows)
   - Scarcity profile (where each currency sits on the spectrum, and how it shifts over time)
   - Conversion map and identified risk points
   - One paragraph on your tuning philosophy: how should the player *feel* about money at early, mid, and late game?

**Deliverable:** A one-page economy design document with the five sections listed above.

**Assessment criteria:** Does each currency pass the one-sentence test? Is there a conversion path that could create an optimal strategy? Did you identify that risk and address it? Does the economy have both short-loop currencies (per-fight, per-turn) and long-loop currencies (per-session, per-run)?

**Common pitfall in this exercise:** Designers tend to make all their currencies function identically — "Currency A buys stuff from Shop A, Currency B buys stuff from Shop B." This creates parallel economies that never interact. The interesting designs have currencies that *cross-pollinate* — spending Currency A opens up new earning opportunities for Currency B, or running out of Currency C forces you to consume Currency D instead. Look for those cross-currency tensions in your design. If every currency lives in its own silo, the multi-currency system is doing less work than a single currency could.

**Stretch goal:** Present your economy design document to someone who hasn't read this module. Can they understand what each currency does and why it exists from your document alone? If they're confused, your economy might be too complex, or your documentation might not clearly communicate the "why" behind each currency.

---

### Exercise 4: Economy Autopsy

**Time:** 45-60 minutes | **Materials:** A game with a flawed economy that you've personally played, writing tools

**Objective:** Write a 500-word analysis diagnosing a specific economy failure in a real game using the vocabulary from this module.

**Steps:**

1. **Choose your patient (5 min).** Pick a game where the economy felt broken, boring, or frustrating at some point. This could be a great game with one economy flaw or a bad game with systemic problems. Suggestions if you're stuck: late-game Skyrim gold, any free-to-play game's premium currency, Diablo 3 at launch (pre-Reaper of Souls), an MMO with runaway inflation, a mobile game with too many currencies.

2. **Identify the symptom (5 min).** What was the player-facing experience? "Gold felt meaningless by hour 20." "I could buy everything and nothing mattered." "The grind between levels 30-40 was unbearable." "I had 12 currencies and couldn't remember what half of them did." Be specific about when in the game the problem appeared and how it felt.

3. **Diagnose the cause (15 min).** Using the vocabulary from this module, trace the symptom to its root cause. Is it a source/sink imbalance? An unchecked conversion path? A scarcity miscalibration? A currency that fails the one-sentence test? An inflation curve that outpaces sink scaling? Reference the Broken Economy Gallery failures if applicable.

4. **Prescribe a fix (10 min).** Propose a specific change that would address the root cause. Be concrete: "Add a gold sink at the 10,000g price point that offers permanent stat bonuses" is better than "add more things to buy." Explain why your fix targets the cause, not just the symptom.

5. **Write it up (15-20 min).** Structure your 500-word analysis as:
   - Paragraph 1: The game and the symptom (what went wrong, when it appeared)
   - Paragraph 2: The diagnosis (root cause using economy vocabulary)
   - Paragraph 3: The proposed fix and why it would work
   - Paragraph 4: One potential risk of your fix (could it create a new problem?)

**Deliverable:** A 500-word written analysis following the four-paragraph structure above.

**Assessment criteria:** Does the diagnosis use specific economy vocabulary (source/sink, inflation, conversion problem, scarcity spectrum, etc.)? Is the proposed fix concrete and targeted at the root cause? Does the risk assessment show understanding that economy changes ripple through connected systems?

**Example opening paragraph** (to calibrate the expected depth): "In *The Elder Scrolls V: Skyrim*, gold becomes functionally worthless by approximately hour 20 of a typical playthrough. The symptom manifests as a total absence of excitement when finding gold in dungeon chests — a 500-gold reward that would have funded an entire armor upgrade at hour 5 now represents less than 1% of the player's holdings. Shop interactions become perfunctory: the player walks in, dumps their inventory, and walks out with more gold they don't need. The economy is dead, but the game continues for another 80+ hours."

**Why this exercise matters:** Diagnosis is a different skill from design. Many designers can build economies but struggle to articulate *why* an economy feels wrong. Forcing yourself to put a diagnosis in writing — using precise vocabulary — builds the analytical muscle you'll need when playtesting reveals that your own economy has problems. And it always will. Every economy ships with flaws. The designers who fix them fastest are the ones who can diagnose accurately.

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

### Play These Games as Economy Studies

If you want hands-on understanding of economy design, play these games with an analytical eye. Each one excels at a different aspect of economy design:

- **Slay the Spire** (~$25) — Multi-resource elegance, opportunity cost at every decision point, per-run economy that resets cleanly.
- **Balatro** (~$15) — Exponential scaling done right, multiplicative resource interaction, interest-vs-spending tension.
- **Hades** (~$25) — Multi-currency meta-progression, each currency with a distinct purpose, brilliant scarcity calibration.
- **Resident Evil 4 Remake** (~$40) — Spatial economy, inventory as a resource system, merchant/upgrade conversion chains.
- **Dark Souls** (~$20-40) — Single-currency dual-sink design, death-as-economy-mechanic, risk/reward through resource vulnerability.
- **Stardew Valley** (~$15) — Seasonal boom/bust cycle, investment-return loops, scaling sinks that match growing income.
- **Into the Breach** (~$15) — Static economy, every resource loss is permanent, scarcity at the Crisis level.
- **Civilization VI** (~$10-60) — Complex multi-resource economy, converter chains, attention as implicit currency.
- **Path of Exile** (Free) — Currency-as-crafting-material, player-driven economy, vendor recipe conversion chains.
- **FTL: Faster Than Light** (~$10) — Scrap as unified currency, fuel/missiles/drones as specialized resources, tight scarcity throughout.

---

## Key Takeaways

1. **Everything is a currency.** Health, time, ammo, attention, information, space — if the player can have more or less of it and that changes their decisions, it's a currency. Design it intentionally or it'll design itself badly. A full audit of *Hades* reveals 15+ currencies in a game that feels elegant and streamlined.

2. **Sources and sinks must balance.** If resources only flow in, you get inflation and meaningless rewards. If resources only flow out, you get deflation and frustrated players. Audit your flow rates continuously — build the spreadsheet, calculate net accumulation, and check that no currency grows without bound.

3. **Scarcity creates decisions; abundance kills them.** The sweet spot is "just not quite enough" — players should feel prosperous enough to have options but constrained enough that every choice costs something. Use the five-point scarcity spectrum to calibrate each currency independently. Remember that scarcity can come from stockpile limits (*Resident Evil*) or throughput constraints (*DOOM Eternal*).

4. **Every currency must justify its existence.** Apply the one-sentence test: "[Currency] creates the decision of X vs Y." If a currency doesn't create a unique decision, merge it or remove it. Multi-currency systems are powerful tuning tools but only when each currency has a clear purpose, a clear source, and a clear sink.

5. **Numbers are psychology, not just math.** Weber-Fechner Law means players feel ratios, not differences. Anchoring sets their reference prices. Big numbers feel exciting. Round numbers feel like milestones. Tune your number scale to the experience you want, then make sure your UI can communicate those numbers clearly.

6. **Tune from the feeling backward, not the numbers forward.** Decide how the player should feel at each point in the game, then set the numbers to produce that feeling. Spreadsheets and simulations are tools, not destinations — playtesting is what reveals whether your economy actually works. The tuning loop is: model, simulate, build, playtest, adjust, repeat.

7. **Study broken economies.** Faucets without drains, death spirals, currency graveyards, and optimal paths are the four horsemen of economy failure. Learn to diagnose them on sight and you'll avoid building them yourself.

8. **Use the pattern library.** Drip Feed, Boom/Bust, Prestige Reset, Mutual Exclusion, Interest, Decay, Sacrifice for Information, and Overflow are reusable building blocks. Assign a pattern to each currency in your game and verify that the mix creates variety. Combine patterns across currencies to create layered economic experiences.

9. **Currency doesn't have to be a number.** *Resident Evil 4's* inventory grid proves that physical space, geometric constraints, and spatial arrangement can function as currencies. If your game has an inventory, a limited skill bar, or a map with branching paths, it has an economy — even if no numbers are involved.

---

## What's Next

You now understand the invisible math behind game economies. The concepts, patterns, and diagnostic tools in this module give you a vocabulary for seeing resource systems clearly — and a methodology for building, auditing, and fixing them.

The most important thing you can do now is **practice auditing.** Every game you play from this point forward is an economy waiting to be dissected. Start noticing the currencies. Trace the sources and sinks. Identify the scarcity profile. Name the patterns. After you've audited 5-10 games, you'll see economies the way a musician hears chord progressions — automatically, instinctively, and with an ear for what's working and what's not.

Connect this knowledge to related design domains:

- **[Module 2: Systems Thinking & Emergent Gameplay](module-02-systems-thinking-emergent-gameplay.md)** — Economy systems are feedback loops. Revisit positive and negative feedback with fresh eyes, specifically looking at how economic feedback creates snowballing or rubber-banding. The death spiral and inflation problems in this module are directly caused by unchecked positive feedback loops.
- **[Module 3: Player Psychology & Motivation](module-03-player-psychology-motivation.md)** — The psychology of numbers, loss aversion around resources, and the sunk cost fallacy all connect directly to how players *feel* about your economy, not just how it functions mathematically. Weber-Fechner, anchoring, and loss aversion are psychological lenses on economic phenomena.
- **[Module 6: Difficulty, Challenge & Fairness](module-06-difficulty-challenge-fairness.md)** — Economy tuning and difficulty tuning are deeply intertwined. A resource-scarce economy IS a difficulty lever. Understanding how to calibrate challenge will make your economy tuning more precise. The scarcity spectrum from this module maps directly onto the difficulty spectrum in Module 6.
- **[Module 7: Narrative Design & Player Agency](module-07-narrative-design-player-agency.md)** — Economy and narrative intertwine more than you'd expect. Resource scarcity creates narrative tension (survival horror), economic growth tells a power fantasy story (RPGs), and resource loss creates emotional stakes (roguelikes). The *feeling* of your economy IS part of your narrative.
