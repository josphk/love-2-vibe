# ECS (Entity-Component-System) Learning Roadmap

**For:** Programmers who've used OOP and want to understand when/why ECS is better · Framework-agnostic (Godot & Love2D examples) · Reads > watches · ADHD-friendly

---

## How This Roadmap Works

This roadmap teaches you a **different way to architect games** — one that separates data from logic, favors composition over inheritance, and scales gracefully from toy projects to thousands of entities. It's not about replacing everything you know about OOP. It's about understanding when OOP's assumptions hurt you and what ECS does instead.

Modules 0 through 4 are roughly linear — each builds on the last. After that, Modules 5, 6, and 7 can be tackled in any order based on interest. Module 5 (performance) is useful anytime after Module 2. Module 7 (capstone) is best saved for last, but you could start it after Module 4 if you're eager to build.

Each module below is a summary. Click the "Deep dive" link on any module to open the full study guide with detailed explanations, code examples, and additional exercises.

**Dependency graph:**
```
0 → 1 → 2 → 3 → 4 (linear foundation)
                    ↓
     5 (performance — anytime after 2)
     6 (real architectures — after 4)
     7 (capstone game — after 4, ideally after all)
```

---

## Module 0: Why Not Just OOP?

> **Deep dive:** [Full study guide](module-00-why-not-just-oop.md)

**Goal:** Understand the specific problems ECS solves, starting from OOP pain points.

You already know OOP. You've built class hierarchies — `Entity` → `Character` → `Player`, `Entity` → `Character` → `Enemy`. It works fine until it doesn't. The problems start when your designs don't fit a tree. What happens when you need a `FlyingEnemy` that shares behavior with `FlyingPlayer`? You either duplicate code, create fragile multiple-inheritance chains, or resort to mixins that feel like duct tape. This is the **diamond problem** in practice, and every OOP game developer hits it eventually.

The deeper issue is that OOP encourages you to bundle data and behavior together into objects. An `Enemy` class owns its position, its health, its AI logic, its rendering code, its collision shape. That feels natural — until you need to iterate over every entity with a position and a health bar, regardless of whether it's an enemy, a player, or a destructible crate. In OOP, that query is awkward. In ECS, it's the fundamental operation.

ECS isn't always better than OOP. For a small game with a clear hierarchy and no performance concerns, OOP is fine. But once you have dozens of entity types sharing overlapping sets of behavior — things that move, things that take damage, things that render, things that have AI, in various combinations — ECS eliminates entire categories of architectural pain.

**Key concepts:**
- **The diamond problem:** When two parent classes share a common ancestor and a child inherits from both, behavior becomes ambiguous. Real game entities rarely fit clean hierarchies.
- **Composition over inheritance:** Instead of `is-a` relationships (Player *is a* Character), use `has-a` relationships (Entity #42 *has* Position, Health, PlayerInput). This is the core philosophical shift.
- **The "blob anti-pattern":** In OOP game code, base classes tend to accumulate fields and methods over time. A `GameObject` with 30 optional fields — most of which are `nil` for any given instance — is a sign the architecture is fighting you.
- **Data/logic coupling:** OOP puts methods on the data they modify. ECS separates them entirely — components are pure data, systems are pure logic. This turns out to make code easier to reason about, test, and reuse.

**Read:**
- ECS FAQ by Sander Mertens — "Why use ECS?" section: https://github.com/SanderMertens/ecs-faq#why-use-ecs — the single best overview of ECS motivations, written by the creator of Flecs
- "Component" chapter from Game Programming Patterns by Robert Nystrom: https://gameprogrammingpatterns.com/component.html — walks through exactly the OOP-to-composition evolution, with clear code examples
- "Evolve Your Hierarchy" by Mick West: https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/ — classic article on migrating from deep inheritance to components in a real game engine

**Exercise:** Take a game you've built (or imagined) using OOP. Draw the class hierarchy. Now list every case where two unrelated classes need the same behavior (e.g., both Player and Fireball need Position and Velocity). How many of those shared behaviors exist? Could you express each entity as a bag of data components instead of a class? Write out what components each entity type would have.

**Time:** 2–3 hours

---

## Module 1: Entities, Components, Systems

> **Deep dive:** [Full study guide](module-01-entities-components-systems.md)

**Goal:** Learn the core triad: entities as IDs, components as data, systems as logic.

This is the vocabulary you need before anything else. In ECS, **entities** are just identifiers — a number, an index, a UUID. An entity has no data and no behavior on its own. It's a label that says "this thing exists." **Components** are plain data containers attached to entities — `Position { x, y }`, `Velocity { dx, dy }`, `Health { current, max }`, `Sprite { image, quad }`. No methods, no logic, just fields. **Systems** are functions that operate on entities that have specific sets of components. A `MovementSystem` queries for every entity that has both `Position` and `Velocity`, and updates position based on velocity each frame.

The elegance is in the separation. Because components are just data, you can mix and match them freely. Need a particle that moves but has no health? Give it `Position` and `Velocity`, skip `Health`. Need an invisible trigger zone? Give it `Position` and `TriggerArea`, skip `Sprite`. You never modify a class hierarchy — you just attach different data to different entity IDs.

In Lua (for Love2D), components can be as simple as tables. In Godot, you might use nodes or resources as components, or adopt a dedicated ECS addon. The concept is identical regardless of implementation: entities are IDs, components are data, systems are logic.

**Key concepts:**
- **Entity:** An identifier. Nothing more. Think of it as a row number in a spreadsheet where each column is a component type.
- **Component:** A struct/table of data with no methods. `Position = { x = 0, y = 0 }`. Keep them small and focused — one responsibility per component.
- **System:** A function that runs every frame (or on an event) and processes all entities matching a certain component signature. `MovementSystem` runs on entities with `{Position, Velocity}`. `RenderSystem` runs on entities with `{Position, Sprite}`.
- **World:** The container that holds all entities and their components. You ask the world "give me every entity with Position and Velocity" and it returns them.

**Read:**
- ECS FAQ — core concepts section: https://github.com/SanderMertens/ecs-faq#what-is-ecs — concise definitions with examples
- "Data Locality" chapter from Game Programming Patterns: https://gameprogrammingpatterns.com/data-locality.html — explains why separating data from logic also has performance implications
- tiny-ecs README and source (Lua): https://github.com/bakpakin/tiny-ecs — a minimal ECS in ~500 lines of Lua. Reading the source is a tutorial in itself.

**Exercise:** On paper (or in pseudocode), design the components for a simple space shooter. You need: a player ship, enemy ships, bullets, explosions, and a score display. List every component type you'd create and which entities get which components. Then write pseudocode for three systems: `MovementSystem`, `CollisionSystem`, and `RenderSystem`. What component signature does each system query for?

**Time:** 2–4 hours

---

## Module 2: Querying and Iteration

> **Deep dive:** [Full study guide](module-02-querying-and-iteration.md)

**Goal:** Learn how systems find entities — queries, archetypes, the "world" container.

You know the triad now: entities, components, systems. But how does a system actually *find* the entities it cares about? This is the practical heart of any ECS implementation, and different frameworks do it differently.

The simplest approach — the one tiny-ecs uses — is **iterating over all entities and filtering.** Every frame, the system loops through every entity in the world and checks "does this entity have the components I need?" This is straightforward but slow at scale. The next step up is **indexed queries:** the world maintains lookup tables so that when you ask "give me all entities with Position and Velocity," it can answer immediately without scanning everything. The most sophisticated approach is **archetype-based storage,** where entities with the same set of components are stored together in contiguous memory. Flecs and Bevy use this model — it's fast because iterating over matching entities is just walking an array.

For learning purposes, start with the simple filter approach. It's easy to understand and easy to implement. You can always optimize later — and Module 5 covers exactly when and why you'd want to.

The **world** (sometimes called a registry or scene) is the central object that owns all entity and component data. Systems don't own entities; the world does. Systems just borrow references for the duration of their update. This centralization is what makes querying possible — there's one place to ask "who has what."

**Key concepts:**
- **Query / filter:** A description of which component combination a system needs. "Give me all entities with `Position` and `Velocity` but NOT `Frozen`." Some frameworks express this declaratively; others use callback-style iteration.
- **Archetype:** A unique combination of component types. All entities with exactly `{Position, Velocity, Sprite}` share an archetype. Archetype-based storage groups them in memory for fast iteration.
- **World / registry:** The container holding all ECS data. You create entities through the world, attach components through the world, and query through the world.
- **System ordering:** Systems run in a defined order each frame. `InputSystem` before `MovementSystem` before `CollisionSystem` before `RenderSystem`. Getting this order wrong causes subtle bugs (entities render at last frame's position, collisions miss, etc.).

**Read:**
- ECS FAQ — "How does querying work?" section: https://github.com/SanderMertens/ecs-faq#how-does-querying-work
- Concord documentation (Lua ECS for Love2D): https://github.com/Tjakka5/Concord — read the README and examples. Concord uses a clean system/component/world API that maps directly to the concepts here.
- "Building an ECS" series by Sander Mertens: https://ajmmertens.medium.com — his blog posts walk through archetype storage design decisions

**Exercise:** Implement a minimal ECS world in Lua (or your preferred language). You need: `world:addEntity()`, `world:addComponent(entity, componentType, data)`, `world:query(componentType1, componentType2, ...)` that returns matching entities. Use simple tables and iteration — no optimization needed. Then write a `MovementSystem` and a `GravitySystem` that use your world's query function. Run them in a loop and print entity positions.

**Time:** 3–5 hours

---

## Module 3: Events, Communication & System Ordering

> **Deep dive:** [Full study guide](module-03-events-communication-system-ordering.md)

**Goal:** How decoupled systems talk to each other, event queues, deferred commands.

Systems in ECS are intentionally decoupled — `MovementSystem` doesn't know `CollisionSystem` exists. That's the whole point. But decoupled systems still need to communicate. When a bullet hits an enemy, the `CollisionSystem` detects the overlap, but the `DamageSystem` needs to apply the damage, the `AudioSystem` needs to play a sound, and the `ParticleSystem` needs to spawn an explosion. How do they coordinate?

The most common answer is **events** (also called signals or messages). When a collision happens, the collision system emits an event — `{ type = "collision", entityA = bullet, entityB = enemy }` — into a shared event queue. Other systems subscribe to events they care about and process them on their next update. This keeps systems decoupled while allowing complex multi-system interactions.

A related problem is **deferred commands.** If a system is iterating over entities and decides to destroy one, doing so immediately would corrupt the iteration. The solution: queue the destruction and process it after the system finishes. Most ECS frameworks handle this automatically, but understanding why it's necessary prevents a whole class of bugs.

System ordering matters more than you might expect. If `RenderSystem` runs before `MovementSystem`, entities appear one frame behind their actual position. If `DamageSystem` runs before `CollisionSystem`, damage is always one frame late. The order usually follows the logical pipeline: input → logic → physics → collision → damage → effects → render. Some frameworks let you declare ordering explicitly; others require you to register systems in the right sequence.

**Key concepts:**
- **Event / signal / message:** A data packet emitted by one system and consumed by others. Keeps systems decoupled. Events can be processed immediately (synchronous) or queued for later (asynchronous).
- **Event queue:** A buffer that collects events during a frame and dispatches them to subscribers. Prevents order-of-operations bugs and allows batch processing.
- **Deferred commands / command buffer:** A queue of structural changes (create entity, destroy entity, add/remove component) that execute after the current system finishes iterating. Prevents iterator invalidation.
- **System ordering / scheduling:** The sequence in which systems run each frame. Incorrect ordering causes one-frame-late bugs, missed collisions, and render artifacts. Explicit ordering is preferable to implicit.
- **Observer pattern vs. polling:** Events (observers) vs. checking a flag every frame (polling). Events are cleaner for rare occurrences; polling is simpler for per-frame state.

**Read:**
- "Observer" and "Event Queue" chapters from Game Programming Patterns: https://gameprogrammingpatterns.com/observer.html and https://gameprogrammingpatterns.com/event-queue.html — Robert Nystrom explains both patterns with game-specific examples
- ECS FAQ — relationships and communication: https://github.com/SanderMertens/ecs-faq#how-do-systems-communicate
- Concord system ordering and world API: https://github.com/Tjakka5/Concord — look at how systems are registered and ordered in the examples

**Exercise:** Extend your Module 2 ECS implementation (or use Concord/tiny-ecs) with an event system. Add a `CollisionSystem` that emits `"hit"` events when two entities overlap. Add a `DamageSystem` that listens for `"hit"` events and reduces health. Add a `DeathSystem` that destroys entities with health <= 0 using deferred commands. Verify that destroying an entity mid-frame doesn't crash iteration.

**Time:** 3–5 hours

---

## Module 4: Common ECS Patterns

> **Deep dive:** [Full study guide](module-04-common-ecs-patterns.md)

**Goal:** Learn the recurring patterns that experienced ECS developers reach for.

Once you understand the triad, querying, and events, you'll start running into design questions that every ECS project faces. How do you represent a "player" entity differently from an "enemy" entity if they have the same components? How do you store global game state? How do you express parent-child relationships? These are solved problems — you just need to know the patterns.

**Tag components** are the simplest pattern and the one you'll use most. A tag is a component with no data — it exists purely to mark an entity. `IsPlayer {}`, `IsEnemy {}`, `IsPoisoned {}`. Your `PlayerInputSystem` queries for entities with `{Position, Velocity, IsPlayer}` — the tag narrows the query. Tags are cheap, expressive, and replace the role that class types play in OOP.

**Singleton components** solve the global state problem. Game-wide data — current score, camera position, elapsed time, input state — doesn't belong on any specific entity. A singleton is a component type that exists on exactly one entity (or is stored directly on the world). Instead of a global variable, you query for the one entity with `GameState { score, level, paused }`.

**Prefabs** (or archetypes in the design sense, not the storage sense) are templates for creating entities. A "Goblin" prefab says: create an entity with `Position`, `Velocity`, `Health { max = 30 }`, `Sprite { image = "goblin.png" }`, `IsEnemy`. Instead of a constructor in a class, you have a function that assembles the right components. This is where ECS and data-driven design meet.

**Key concepts:**
- **Tag components:** Empty components used as markers. `IsPlayer {}`, `Invincible {}`, `MarkedForDeletion {}`. Query filters, not data carriers.
- **Singleton components:** One-per-world components for global state. Score, camera, input config, game settings. Access them by querying for their type.
- **Prefabs / entity templates:** Functions or data tables that define which components (and default values) an entity type gets. The ECS equivalent of a constructor.
- **Parent-child relationships:** Store a `Parent { entity }` or `Children { list }` component. Systems can traverse hierarchies for transforms, UI layout, or inventory.
- **Ephemeral / one-frame components:** Components that exist for a single frame to trigger behavior. `JustLanded {}` is added on the frame an entity touches ground, processed by systems that care, and removed at end of frame. Powerful for event-like behavior without a separate event system.
- **State components:** Instead of a state machine class, swap components. An entity with `Walking {}` that transitions to `Jumping {}` — remove one tag, add the other. Systems only process the state they care about.

**Read:**
- ECS FAQ — relationships, tags, prefabs: https://github.com/SanderMertens/ecs-faq#what-are-tag-components — covers all these patterns
- Flecs documentation on prefabs and relationships: https://www.flecs.dev/flecs/md_docs_2Relationships.html — Flecs has first-class support for many of these patterns, and the docs explain the *why* not just the *how*
- "Overwatch Gameplay Architecture and Netcode" GDC talk notes — search for Timothy Ford's ECS architecture writeup. Overwatch is built on ECS and the talk covers singleton components, system ordering, and prediction.

**Exercise:** Design the ECS architecture for a Zelda-like top-down game on paper. You need: a player, multiple enemy types (melee, ranged, boss), collectible items (hearts, keys, rupees), doors that open with keys, destructible pots, and a HUD showing health and inventory. List every component type you'd create. Identify which ones are tags, which are singletons, which form parent-child relationships. Write prefab definitions for at least 4 entity types.

**Time:** 3–4 hours

---

## Module 5: Data-Oriented Design & Performance

> **Deep dive:** [Full study guide](module-05-data-oriented-design-performance.md)

**Goal:** Understand cache lines, SoA vs AoS, and why ECS is fast at scale.

You can skip this module and still build great games with ECS. But if you want to understand *why* ECS became popular in engine development — why Unity rewrote their architecture around it, why Blizzard used it for Overwatch, why the Rust game development community embraced Bevy — the answer is performance, and the reason is hardware.

Modern CPUs are fast at computation but bottlenecked by memory access. When the CPU needs data that isn't in cache, it stalls for hundreds of cycles while fetching from RAM. A **cache line** is typically 64 bytes — when the CPU loads one byte, it loads the surrounding 64 bytes for free. If the next piece of data you need is in those 64 bytes, it's essentially instant. If it's somewhere else in memory, you pay the full RAM latency.

This is where **Array of Structs (AoS) vs. Struct of Arrays (SoA)** matters. OOP naturally produces AoS — each object is a struct containing all its fields, and objects are scattered across heap memory. When a system needs to read just the `position` field of 10,000 entities, it has to hop between 10,000 different memory locations, blowing the cache on every access. SoA stores all positions together in one contiguous array, all velocities in another, all health values in another. Now iterating over all positions is a linear memory scan — cache-line friendly, branch-predictor friendly, and potentially SIMD-vectorizable.

Archetype-based ECS frameworks store components in SoA layout automatically. That's the performance secret: the *architecture* that makes your code cleaner also makes it faster. You don't optimize individual functions — the data layout does the work.

**Key concepts:**
- **Cache line:** 64 bytes of contiguous memory loaded together. Sequential memory access is 10-100x faster than random access. This single fact drives all of data-oriented design.
- **AoS (Array of Structs):** `[{x,y,vx,vy,hp}, {x,y,vx,vy,hp}, ...]` — what OOP gives you. Bad cache utilization when systems only need some fields.
- **SoA (Struct of Arrays):** `{xs: [...], ys: [...], vxs: [...], vys: [...], hps: [...]}` — what ECS gives you. Excellent cache utilization for systems that touch specific component types.
- **Hot/cold splitting:** Components accessed every frame (Position, Velocity) are "hot." Components accessed rarely (Description, Lore) are "cold." Keeping them in separate storage means hot paths don't waste cache on cold data.
- **Batch processing:** Systems process all matching entities in a tight loop. This is inherently SIMD-friendly and branch-predictor-friendly compared to virtual dispatch through a class hierarchy.

**Read:**
- Data-Oriented Design book by Richard Fabian — free online: https://www.dataorienteddesign.com/dodbook/ — the definitive resource. Read chapters 1-4 for the core mental model.
- "Data Locality" from Game Programming Patterns: https://gameprogrammingpatterns.com/data-locality.html — a gentler introduction with game-specific examples
- Mike Acton's "Data-Oriented Design and C++" — search for the transcript/notes from his CppCon talk. The core message: "Where there is one, there are many. Loaded means *processed*."
- ECS FAQ — performance section: https://github.com/SanderMertens/ecs-faq#how-is-ecs-different-from-oop

**Exercise:** Take a simple simulation — 10,000 particles, each with position and velocity, updating every frame. Implement it twice: once as an array of particle objects (AoS style) and once as separate arrays for x, y, vx, vy (SoA style). Benchmark both. In Lua the difference may be subtle due to table overhead, but in C/C++/Rust the difference is dramatic. Even in Lua, measure and compare. Write down what you observe and why.

**Time:** 3–5 hours

---

## Module 6: ECS in Practice

> **Deep dive:** [Full study guide](module-06-ecs-in-practice.md)

**Goal:** Survey real frameworks, understand Godot's node model vs. ECS, and learn when NOT to use ECS.

You've learned the theory. Now it's time to see how real frameworks implement these ideas — and where they diverge. No two ECS frameworks are identical, and the design tradeoffs they make reveal what matters in practice.

**Lua ECS (for Love2D):** If you're building with Love2D, your main options are **Concord** and **tiny-ecs**. Concord is more opinionated — it gives you a formal World/System/Component structure with proper lifecycle hooks. tiny-ecs is more minimalist — systems are just filter functions that run on matching entities. Both work well. Concord is better for larger projects where structure prevents chaos; tiny-ecs is better when you want minimal overhead and maximum control. See the [Love2D Learning Roadmap](../../engines/love2d/love2d-learning-roadmap.md) for more on the Love2D ecosystem.

**Flecs (C/C++):** Flecs by Sander Mertens is arguably the most feature-complete ECS framework available. It supports relationships, query caching, hierarchies, prefabs, reflection, and a REST API for live debugging. If you want to see what a "batteries included" ECS looks like, study Flecs.

**Godot's node model:** Godot uses a scene tree of nodes, which is a form of composition — but it's not ECS. Nodes bundle data and behavior together (like OOP objects). Godot's model works beautifully for many games, especially when the scene tree maps naturally to your game's structure. ECS shines when you have many entities with overlapping component sets and need to process them in bulk. Some Godot developers use ECS addons for specific subsystems (AI, physics simulation) while keeping the rest in the node tree.

**When NOT to use ECS:** ECS adds indirection. For small games, simple OOP or even just tables and functions can be clearer and faster to develop. If your game has fewer than ~50 entity types and no performance-critical entity iteration, ECS may be overengineering. Use ECS when you need flexible entity composition, when you're processing many similar entities per frame, or when your inheritance hierarchy is becoming a maintenance burden.

**Key concepts:**
- **Concord (Lua):** Structured ECS for Love2D with worlds, systems, components, and assemblages (prefabs). Good for medium-to-large Love2D projects. https://github.com/Tjakka5/Concord
- **tiny-ecs (Lua):** Minimal ECS for Love2D. Systems are filter functions. Low overhead, flexible, good for small-to-medium projects. https://github.com/bakpakin/tiny-ecs
- **Flecs (C):** Feature-rich ECS with relationships, hierarchies, and a query DSL. https://www.flecs.dev
- **Bevy ECS (Rust):** The ECS framework inside the Bevy game engine. Archetype-based, heavily parallel, and well-documented. Worth reading even if you don't use Rust.
- **Node tree vs. ECS:** Not mutually exclusive. You can use a scene tree for structure (UI, levels, scene management) and ECS for gameplay entities (bullets, enemies, particles).
- **Hybrid approaches:** Many shipped games use ECS for gameplay systems and traditional OOP/scene trees for everything else. Purity is less important than shipping.

**Read:**
- Concord examples and API: https://github.com/Tjakka5/Concord
- tiny-ecs README: https://github.com/bakpakin/tiny-ecs
- Flecs documentation: https://www.flecs.dev/flecs/ — the "Getting Started" and "Query" sections are especially good
- "ECS vs. OOP" discussions in the Godot community — search the Godot forums and GitHub discussions for real-world experience reports
- ECS FAQ — "When should I use ECS?": https://github.com/SanderMertens/ecs-faq#when-should-i-use-ecs

**Exercise:** Pick one Lua ECS library (Concord or tiny-ecs) and build a minimal Love2D demo: a player that moves with arrow keys, enemies that chase the player, and bullets the player can shoot. Use the library's actual API, not your own hand-rolled ECS from earlier modules. Compare the experience to how you'd structure the same thing with plain Love2D (tables and if-statements). Write down: what felt better? What felt worse? When would you choose each approach?

**Time:** 4–6 hours

---

## Module 7: Building a Game with ECS

> **Deep dive:** [Full study guide](module-07-building-a-game-with-ecs.md)

**Goal:** Capstone — build a complete small game using ECS architecture.

This is where everything comes together. You're going to build a small but complete game — title screen, gameplay, game over, sound, juice — using ECS for the gameplay architecture. The goal isn't to build something impressive. The goal is to confront every practical decision that ECS forces you to make and come out the other side with a shipped thing.

Pick a genre that exercises ECS well. **Space shooters** (Galaga, Ikaruga) are ideal — you'll have hundreds of entities (bullets, enemies, particles, pickups) with overlapping component sets, exactly the scenario ECS was designed for. **Arena survival games** (Vampire Survivors style) work similarly well. **Top-down action games** (Zelda-like) test parent-child relationships, inventory, and state management. Avoid puzzle games and visual novels — they don't need ECS and you'll be fighting the architecture instead of learning from it. See the [Game Design Theory Roadmap](../../design/game-design-theory/game-design-theory-roadmap.md) for scoping advice (Module 10 on finishing is especially relevant).

Your architecture should include: entity prefabs for every game object, systems for input, movement, collision, damage, AI, rendering, audio, and UI. Use events for cross-system communication. Use tag components for entity classification. Use singleton components for game state. If you're in Love2D, use Concord or tiny-ecs. If you're in Godot, use the node tree for scenes/UI and an ECS addon or hand-rolled ECS for gameplay entities.

**The hard parts you'll encounter:** Where does UI live? (Usually outside ECS, or with specialized UI components.) How do you handle game states like pause menus? (A singleton component `GameState { paused = true }` that systems check, or a state machine outside the ECS world.) How do you save/load? (Serialize all components for all entities — one of ECS's superpowers, since it's just data.) Struggle with these questions. The answers you find will be more valuable than any tutorial.

**Key concepts:**
- **Architecture plan first:** Before writing code, list your components, systems, and the order systems run. Sketch the entity types and their component compositions. This plan is your blueprint.
- **Prefab-driven entity creation:** Every entity type (player, enemy, bullet, pickup, particle) should be created through a prefab function or data table. No ad-hoc entity assembly scattered across the codebase.
- **Separation of concerns in practice:** Input system reads keys and writes intent components. Movement system reads intent and updates position. Collision system reads positions and emits events. Each system touches only its own concerns.
- **ECS serialization:** Because entities are just IDs and components are just data, saving the game is "serialize all component tables." Loading is "deserialize and recreate." This is dramatically simpler than serializing an object graph.
- **Debugging ECS:** Print entity component lists. Visualize system execution order. Draw collision shapes. ECS makes this easy because all data is centralized and queryable.

**Read:**
- "How to Finish Your Game" by Derek Yu: https://makegames.tumblr.com/post/1136623767/finishing-a-game — revisit this before you start. Scope small.
- ECS FAQ — real-world examples section: https://github.com/SanderMertens/ecs-faq#examples — links to open-source ECS games you can study
- Concord examples: https://github.com/Tjakka5/Concord — the example projects show complete game structures

**Exercise:** Build and finish the game. Minimum viable scope: a title screen, one gameplay mode with at least two entity types interacting through ECS, a score or win condition, a game over state, and at least one "juice" effect (screen shake, particles, or sound). Ship it — even if it's just a .love file you share with a friend or post on itch.io. Finished is finished.

**Time:** 20–40 hours

---

## Essential Bookmarks

| Resource | URL | Notes |
|----------|-----|-------|
| ECS FAQ (Sander Mertens) | https://github.com/SanderMertens/ecs-faq | The single best ECS reference. Start here for any question. |
| Game Programming Patterns | https://gameprogrammingpatterns.com | Free online. Component, Observer, Event Queue chapters are directly relevant. |
| Data-Oriented Design (Richard Fabian) | https://www.dataorienteddesign.com/dodbook/ | Free online. The "why" behind ECS performance. |
| Concord (Lua ECS) | https://github.com/Tjakka5/Concord | Structured ECS for Love2D. |
| tiny-ecs (Lua ECS) | https://github.com/bakpakin/tiny-ecs | Minimal ECS for Love2D. |
| Flecs | https://www.flecs.dev | Feature-rich C ECS. Excellent docs even if you don't use C. |
| Bevy ECS docs | https://bevyengine.org/learn/ | Rust ECS. Well-documented, good for understanding archetype storage. |
| Sander Mertens' blog | https://ajmmertens.medium.com | Deep dives on ECS internals and design decisions. |

---

## ADHD-Friendly Tips

- **Module 1 is the unlock.** If you only finish one module, make it Module 1. Once you see entities as IDs and components as data, the entire paradigm clicks. Everything else is refinement.
- **Build tiny, build often.** Don't read all 7 modules then build. Build something after Module 1. Rebuild it better after Module 2. The feedback loop keeps your brain engaged.
- **Use a real library early.** Hand-rolling an ECS is educational (Module 2 exercise), but switch to Concord or tiny-ecs by Module 4. Fighting infrastructure isn't learning ECS — it's learning infrastructure.
- **Draw the architecture.** Boxes for components, arrows for systems, sticky notes for entities. Physical diagrams engage a different part of your brain than code does. When you're stuck, draw instead of typing.
- **The "one system" rule.** Each coding session, implement one system. `MovementSystem` today. `CollisionSystem` tomorrow. Each system is a complete, satisfying unit of progress.
- **Compare to what you know.** When a concept feels abstract, rewrite it in OOP in your head. "How would I do this with classes?" Then look at the ECS version. The contrast makes both approaches concrete.
- **Play ECS-heavy open-source games.** When you need a break from building, read someone else's ECS code. Seeing real decisions in context is worth more than another tutorial.
