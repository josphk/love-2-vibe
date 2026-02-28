# Game AI Learning Roadmap

**For:** Game developers who want smarter NPCs · Framework-agnostic (Godot & Love2D examples) · Reads > watches · ADHD-friendly

---

## How This Roadmap Works

This roadmap teaches you how to make game characters that **feel** intelligent. None of this is machine learning or neural networks — game AI is the craft of creating the *illusion* of intelligence through deterministic systems. It's smoke and mirrors, and it's beautiful.

The first four modules are roughly linear — each builds on the last. After that, you can jump around based on what your game needs. Every module is framework-agnostic: the concepts work in Godot, Love2D, Unity, or anything else. Code examples reference Godot and Love2D where helpful, but the focus is on the patterns, not the syntax.

Each module below is a summary. Click the "Deep dive" link on any module to open the full study guide with detailed explanations, implementation walkthroughs, and additional exercises.

**Dependency graph:**
```
0 → 1 → 2 → 3 (linear foundation)
                ↓
         4 (pathfinding — after 3)
         5, 6 (decision making — after 2, independent of each other)
         7 (perception — after 1, better after 2)
         8 (group behavior — after 3 + 4)
         9 (boss AI — after 1 + 7)
         10 (debugging/tuning — capstone)
```

---

## Module 0: What "Game AI" Actually Means

> **Deep dive:** [Full study guide](module-00-what-game-ai-means.md)

**Goal:** Establish that game AI is deterministic illusion-craft, not machine learning.

Here is the most important thing to understand before writing a single line of AI code: **game AI has almost nothing to do with "real" AI.** Academic AI research tries to solve problems optimally. Game AI tries to create an *experience*. An NPC that plays perfectly is a terrible opponent — it's not fun to lose every time. An NPC that plays imperfectly in *believable* ways is what you're after.

Game AI is closer to theater than computer science. You're directing actors who need to appear to think, react, and make decisions — but their "thinking" is a script you wrote. The player's brain does the heavy lifting, filling in the gaps with assumptions about intelligence. A guard who pauses, looks around, then walks toward a noise isn't "hearing" anything. You wrote a timer, a rotation, and a movement vector. The player's mind adds the intelligence.

This reframing matters because it frees you from over-engineering. You don't need a PhD in machine learning. You need a bag of simple, well-understood tricks — state machines, trees, steering math — combined with good game design instincts about what *feels* right.

**Key concepts:**
- **The illusion of intelligence:** Players attribute far more intelligence to NPCs than actually exists. A random patrol path with occasional pauses feels more "aware" than a perfectly optimized one.
- **Satisficing vs. optimizing:** Game AI should find *good enough* solutions, not perfect ones. Perfect play feels robotic.
- **The AI design spectrum:** From fully scripted (cutscenes) to reactive (FSMs) to deliberative (planners) to emergent (flocking). Most games live in the reactive-to-deliberative range.
- **"Fun" is the metric:** The only test for game AI is whether it creates enjoyable gameplay. A brilliant algorithm that makes the game boring is a failure.

**Read:**
- "The Total Beginner's Guide to Game AI" by Bobby Anguelov: https://www.gamedev.net/tutorials/programming/artificial-intelligence/the-total-beginners-guide-to-game-ai-r4942/ — excellent survey of the field with no prerequisites
- *Game AI Pro* (free chapters): https://www.gameaipro.com — the introduction chapters establish the philosophy clearly
- *Game Programming Patterns*, "Component" and "State" chapters: https://gameprogrammingpatterns.com — sets up architectural thinking you'll use throughout

**Exercise:** Play a game with visible NPC behavior (Skyrim, Breath of the Wild, Metal Gear Solid, or any stealth game). Spend 15 minutes observing one NPC without interacting. Write down every behavior you see. Now try to reverse-engineer the rules: what triggers each behavior? What's probably a timer? What's probably a state change? You'll be surprised how simple the underlying systems are.

**Time:** 1-2 hours

---

## Module 1: Finite State Machines

> **Deep dive:** [Full study guide](module-01-finite-state-machines.md)

**Goal:** Build the most fundamental AI pattern — states with transitions.

The finite state machine (FSM) is where game AI begins, and honestly, where it stays for many shipped games. A surprising number of excellent games run entirely on FSMs. The concept is simple: your NPC is always in exactly one **state** (idle, patrol, chase, attack, flee), and **transitions** between states are triggered by conditions (player spotted, health low, timer expired).

FSMs work because they're predictable, debuggable, and easy to reason about. When your guard is in the "patrol" state, you know exactly what it's doing. When the player enters its detection range, the transition to "chase" fires. When the player escapes, it transitions to "search" and eventually back to "patrol." This is the bread and butter of 90% of enemy AI in games.

The limitation of FSMs shows up at scale. With 5 states and 10 transitions, everything is clean. With 15 states and 40 transitions, you have a spaghetti mess where adding one new behavior means touching a dozen transitions. This is the "state explosion" problem, and it's why Modules 2 and 5-6 exist. But don't skip ahead — master FSMs first. They're the foundation everything else is built on.

**Key concepts:**
- **States:** Discrete modes of behavior (idle, patrol, chase, attack, flee, search)
- **Transitions:** Conditions that move from one state to another (player_visible, health_low, timer_expired)
- **Enter/exit actions:** Code that runs once when entering or leaving a state (play animation, reset timer, change speed)
- **State explosion:** The combinatorial problem when states multiply — the motivation for behavior trees and utility AI
- **Hierarchical FSMs:** Nesting state machines to manage complexity (a "combat" super-state that contains "melee," "ranged," and "dodge" sub-states)

**Read:**
- *Game Programming Patterns*, "State" chapter: https://gameprogrammingpatterns.com/state.html — the definitive readable explanation with clean code examples
- "Finite-State Machines: Theory and Implementation" from *Game AI Pro*: https://www.gameaipro.com — the FSM chapter covers practical pitfalls
- Red Blob Games (Amit Patel): https://www.redblobgames.com — search for FSM/state machine content; his interactive diagrams make abstract concepts tangible

**Exercise:** Implement a guard NPC with five states: Idle, Patrol, Chase, Attack, and Search. The guard patrols between waypoints. If the player enters its vision range, it transitions to Chase. If the player is within attack range, it transitions to Attack. If the player escapes, the guard enters Search (moves to last known position) for a few seconds, then returns to Patrol. Draw the state diagram on paper first — every state as a circle, every transition as a labeled arrow. Then implement it.

**Time:** 4-6 hours

---

## Module 2: Behavior Trees

> **Deep dive:** [Full study guide](module-02-behavior-trees.md)

**Goal:** Learn the industry-standard composable AI pattern — Sequence, Selector, and decorators.

Behavior trees are how the industry solved the state explosion problem. Instead of a flat web of states and transitions, you organize behavior into a **tree** that is evaluated from the root every tick. Each node returns one of three statuses: **Success**, **Failure**, or **Running**. The tree's structure determines which behaviors execute and in what priority.

The elegance of behavior trees is composability. You build small, reusable behaviors ("move to position," "play animation," "check health") and combine them with two fundamental node types: **Sequences** (do all children in order — if any fails, the sequence fails) and **Selectors** (try children in order — use the first one that succeeds). A Selector with "Attack if in range" then "Chase if player visible" then "Patrol" gives you prioritized fallback behavior in three lines of logic.

**Decorators** add another layer: Inverter (flip success/failure), Repeater (run a child N times), Cooldown (prevent re-execution for N seconds). Combined with **Blackboard** data (a shared key-value store the tree reads from, like "last_known_player_position" or "current_health"), behavior trees can express remarkably complex AI that remains readable and maintainable. Halo 2 popularized this approach, and it's now the default in Unreal Engine, Godot (via addons), and most AAA engines.

If you've already worked through the [Game Design Theory roadmap](../game-design-theory/game-design-theory-roadmap.md), you'll recognize that behavior trees are essentially a *systems design* tool — small, composable pieces that create emergent-feeling behavior from deterministic rules.

**Key concepts:**
- **Composite nodes:** Sequence (AND — all must succeed), Selector/Fallback (OR — first success wins), Parallel (run multiple children simultaneously)
- **Leaf nodes:** Actions (do something) and Conditions (check something)
- **Decorators:** Modify child behavior — Inverter, Repeater, Cooldown, Timeout
- **Blackboard pattern:** Shared data store that decouples tree nodes from each other
- **Tick-based evaluation:** The tree is re-evaluated from the root on every update, allowing dynamic reprioritization

**Read:**
- "Behavior Trees for AI: How They Work" by Chris Simpson: https://www.gamedeveloper.com/programming/behavior-trees-for-ai-how-they-work — the single best introductory article, with clear diagrams
- "Introduction to Behavior Trees" from *Game AI Pro*: https://www.gameaipro.com — the chapter covers practical implementation details and edge cases
- *Game Programming Patterns* by Robert Nystrom: https://gameprogrammingpatterns.com — while it doesn't have a dedicated BT chapter, the architectural patterns (Component, State, Observer) directly support BT implementation

**Exercise:** Redesign the guard NPC from Module 1 as a behavior tree. Your root should be a Selector with three branches: (1) a Sequence for combat (check player in range -> attack -> retreat), (2) a Sequence for pursuit (check player visible -> move to player), and (3) a Sequence for patrol (move to next waypoint -> wait). Draw the tree on paper first. Notice how adding new behaviors — say, "call for backup if health < 30%" — is now a matter of inserting a branch, not rewiring a state diagram.

**Time:** 5-7 hours

---

## Module 3: Steering Behaviors

> **Deep dive:** [Full study guide](module-03-steering-behaviors.md)

**Goal:** Make NPCs move through the world in natural, organic ways — Seek, Flee, Arrive, Wander, and flocking.

Up to this point, your AI "movement" has probably been "set position toward target." That works, but it looks robotic. Steering behaviors, first described by Craig Reynolds in 1987, give NPCs fluid, believable movement by treating them as autonomous agents with velocity and acceleration. Instead of teleporting toward a goal, they **steer** — adjusting their heading smoothly over time.

The genius of steering behaviors is that they combine. Each behavior produces a **steering force** — a vector. Seek produces a force toward a target. Flee produces a force away. Arrive is like Seek but decelerates as it approaches. Wander adds gentle randomness. Obstacle Avoidance pushes away from walls. You can blend these forces together: 60% Seek toward the player, 30% Obstacle Avoidance, 10% Wander. The result is an NPC that chases the player while dodging obstacles and not moving in a perfectly straight line. It looks alive.

The crown jewel is **flocking** (also called boids): three simple rules — Separation (don't crowd neighbors), Alignment (steer toward the average heading of neighbors), and Cohesion (steer toward the average position of neighbors) — produce the mesmerizing emergent behavior of birds in flight, fish in schools, or zombies in hordes. This is a perfect example of the emergent gameplay concepts from the [Game Design Theory roadmap](../game-design-theory/game-design-theory-roadmap.md) — simple rules creating complex, unscripted behavior.

**Key concepts:**
- **Seek & Flee:** Accelerate toward/away from a target position
- **Arrive:** Seek with deceleration radius — the NPC slows smoothly as it reaches its goal
- **Wander:** A gentle, continuous randomized steering that looks natural (not random jerking)
- **Obstacle Avoidance:** Raycast or feeler-based detection to steer around walls and objects
- **Flocking (Boids):** Separation + Alignment + Cohesion = emergent group movement
- **Force blending:** Weighted combination of multiple steering forces per frame
- **Pursuit & Evade:** Predict where a moving target will be, steer toward/away from that future position

**Read:**
- Craig Reynolds' original steering behaviors page: https://www.red3d.com/cwr/steer/ — the primary source, with clear descriptions and diagrams for every behavior
- "Steering Behaviors for Autonomous Characters" by Craig Reynolds (GDC paper): https://www.red3d.com/cwr/steer/gdc99/ — the seminal paper, surprisingly readable
- *Nature of Code*, Chapter 6 "Autonomous Agents": https://natureofcode.com/autonomous-agents/ — interactive examples with beautiful explanations, covers steering and flocking in depth
- Red Blob Games on movement: https://www.redblobgames.com — Amit Patel's interactive guides on vectors and movement are essential background

**Exercise:** Build a scene with three behaviors visible simultaneously: (1) a predator that uses Pursuit to chase the player, (2) a group of 15-20 "boid" creatures that flock together using Separation/Alignment/Cohesion, and (3) the boids should also Flee from the predator when it gets close. Experiment with the weight values — what happens when Separation is too high? When Cohesion dominates? When you add Wander to the flock?

**Time:** 5-8 hours

---

## Module 4: Pathfinding — A* & Navigation

> **Deep dive:** [Full study guide](module-04-pathfinding-astar-navigation.md)

**Goal:** Teach NPCs to navigate complex environments — A* algorithm, navmeshes, terrain costs, and flow fields.

Steering behaviors handle *how* an NPC moves. Pathfinding handles *where* it should go. An NPC that can Seek toward the player is useless if there's a wall between them — it'll just press into the wall forever. Pathfinding algorithms find the route around obstacles, and A* (pronounced "A-star") is the workhorse of the industry.

A* is a graph search algorithm that finds the shortest path between two points. It works on grids, waypoint networks, or navmeshes. The key insight is the **heuristic** — A* estimates the remaining distance to the goal and uses that estimate to prioritize which nodes to explore first. This makes it dramatically faster than brute-force search. On a grid, you typically use Manhattan distance (for 4-directional movement) or Euclidean distance (for 8-directional) as the heuristic.

For production games, you'll usually combine pathfinding with steering. A* gives you a list of waypoints, and steering behaviors handle the smooth movement between them. Godot has built-in NavigationServer with navmesh support. In Love2D, you'll implement A* yourself (it's an excellent learning exercise) or use a library like `jumper`. Understanding A* deeply — not just using an engine's built-in pathfinding — will make you a better game developer because it teaches you to reason about computational cost, heuristics, and the tradeoffs between precision and performance.

**Key concepts:**
- **A* algorithm:** The standard pathfinding algorithm — open set, closed set, g-cost (distance from start), h-cost (heuristic to goal), f-cost (g + h)
- **Heuristics:** Manhattan, Euclidean, Chebyshev — choosing the right one for your movement model
- **Terrain costs:** Making some tiles more expensive to traverse (mud, hills, lava) creates tactical navigation
- **Navmeshes:** Navigation meshes define walkable areas as polygons instead of grids — more efficient and natural for complex environments
- **Flow fields:** Pre-computed vector fields that guide many agents simultaneously toward a goal — efficient for RTS games with hundreds of units
- **Path smoothing:** Raw A* paths are jagged; smoothing techniques (funnel algorithm, string-pulling) make movement look natural
- **Dynamic obstacles:** Handling objects that move or appear after the path was computed

**Read:**
- Red Blob Games "Introduction to A*": https://www.redblobgames.com/pathfinding/a-star/introduction.html — the single best A* tutorial on the internet, with interactive diagrams you can play with
- Red Blob Games "Implementation of A*": https://www.redblobgames.com/pathfinding/a-star/implementation.html — companion article with clean, practical code
- "Navigation Mesh Generation" from *Game AI Pro*: https://www.gameaipro.com — covers navmesh construction and query
- Red Blob Games on hex grids and grids: https://www.redblobgames.com/grids/hexagons/ — essential if your game uses hex or grid-based maps

**Exercise:** Implement A* pathfinding on a grid with obstacles. Start with a simple grid where the player clicks a destination and an NPC navigates there. Then add terrain costs — make some tiles "mud" (cost 3x) and watch how the path avoids them when a clear route exists but cuts through when necessary. Finally, connect your A* output to the steering behaviors from Module 3: the NPC should follow the A* waypoints using Seek/Arrive, with Obstacle Avoidance as a fallback for dynamic objects.

**Time:** 6-10 hours

---

## Module 5: Decision Making — Utility AI

> **Deep dive:** [Full study guide](module-05-utility-ai.md)

**Goal:** Build AI that scores and compares options using response curves, creating NPCs with emergent "personality."

FSMs and behavior trees choose actions based on binary conditions: is the player visible? Is health below 50%? Utility AI replaces boolean checks with **scored evaluations**. Every possible action gets a score based on continuous input values, and the NPC picks the highest-scoring action. This creates nuanced, context-sensitive decisions that feel remarkably alive.

Imagine an NPC deciding what to do. A behavior tree might check: "Am I hungry? Then eat." Utility AI asks: "How hungry am I? How much food is nearby? How dangerous is the area? How tired am I?" It scores each possible action — eat, fight, flee, sleep — and picks the best one given the current context. An NPC that's slightly hungry but near enemies will fight first and eat later. One that's starving will risk the danger to eat. This falls out naturally from the scoring, with no explicit rules for these cases.

The magic ingredient is **response curves** — functions that map an input range (0-1) to a score. A linear curve for hunger means the NPC cares equally about going from 10% to 20% hungry as from 80% to 90%. An exponential curve means it barely cares at low hunger but becomes desperate at high hunger. By shaping these curves, you give each NPC type a distinct "personality" without writing separate behavior logic. An aggressive NPC simply has a steeper combat score curve. A cautious one has a steeper flee curve. Same system, different tuning.

**Key concepts:**
- **Utility scoring:** Every action gets a numerical score based on the current world state
- **Response curves:** Linear, exponential, logistic, sine — functions that shape how inputs map to scores
- **Action sets:** The menu of possible actions the NPC evaluates each tick
- **Considerations:** Individual factors (hunger, danger, distance) that contribute to an action's score
- **Personality through tuning:** Different curve shapes and weights create distinct NPC archetypes without separate code
- **Score normalization:** Keeping scores comparable across different actions with different input ranges
- **Dual utility:** Scoring both the action and the target (which enemy to attack, which resource to gather)

**Read:**
- "An Introduction to Utility Theory" by Dave Mark, *Game AI Pro*: https://www.gameaipro.com — Dave Mark is the foremost advocate of utility AI in games; his chapters are the essential reference
- "Building a Better Centaur: AI Architecture for Games" by Dave Mark (GDC notes): search for the text transcript — covers practical utility AI architecture with real game examples
- *Game Programming Patterns* by Robert Nystrom: https://gameprogrammingpatterns.com — the architectural patterns (especially Command and Observer) support utility system implementation

**Exercise:** Build a simple survival NPC with four actions: Eat, Drink, Sleep, and Explore. Give it three needs (hunger, thirst, energy) that deplete over time at different rates. Score each action using response curves — Eat's score is driven by hunger, Drink's by thirst, Sleep's by energy. Experiment with curve shapes: make one NPC "lazy" (steep energy curve) and another "adventurous" (high baseline Explore score). Watch them diverge in behavior over a few minutes with no explicit personality code — just different curve parameters.

**Time:** 5-8 hours

---

## Module 6: Decision Making — GOAP

> **Deep dive:** [Full study guide](module-06-goap.md)

**Goal:** Understand goal-oriented action planning — NPCs that construct multi-step plans to achieve goals.

GOAP (Goal-Oriented Action Planning) is the most ambitious decision-making pattern in this roadmap. Instead of you scripting behavioral priorities, the NPC is given **goals** ("kill the player," "stay healthy," "get ammunition") and a set of **actions** with preconditions and effects. The GOAP planner searches for a sequence of actions that transforms the current world state into one where a goal is satisfied. The NPC *figures out its own plan*.

The landmark implementation was Monolith's **F.E.A.R.** (2005), and it's still the best case study. In F.E.A.R., an AI soldier with the goal "kill the player" and low ammo might plan: find ammo crate -> move to ammo crate -> pick up ammo -> find cover near player -> move to cover -> attack player. If the ammo crate is destroyed, the planner re-evaluates and might plan: find melee range -> move to player -> melee attack. No designer scripted these sequences — they emerge from the action/precondition/effect definitions.

GOAP is powerful but expensive — both computationally and in design effort. You need to carefully define your action space, and debugging a planner can be opaque compared to stepping through an FSM. For most games, behavior trees or utility AI are sufficient and more maintainable. GOAP shines when you want NPCs that handle novel situations with multi-step plans, particularly in simulation-heavy games or immersive sims. Understanding GOAP even if you don't use it will make you a better AI designer, because it forces you to think about actions in terms of preconditions and effects — a discipline that improves any AI architecture.

**Key concepts:**
- **Goals:** Desired world states ("player_dead = true," "has_ammo = true")
- **Actions:** Operations with preconditions (what must be true) and effects (what becomes true). "Shoot" requires "has_ammo" and "player_visible," and its effect is "player_damaged."
- **World state:** A set of key-value pairs representing the current situation
- **Planning:** A* search (yes, the same algorithm from Module 4) through action space to find a sequence connecting current state to goal state
- **Re-planning:** When the world changes and the current plan becomes invalid, the NPC re-plans
- **Action cost:** Each action has a cost; the planner finds the cheapest plan, not just any plan
- **F.E.A.R. case study:** The gold standard implementation — study it even if you use a different architecture

**Read:**
- "Three States and a Plan: The AI of F.E.A.R." by Jeff Orkin: https://alumni.media.mit.edu/~jorkin/gdc2006_orkin_jeff_fear.pdf — the essential paper, clearly written by the engineer who built it
- "Goal-Oriented Action Planning" from *Game AI Pro*: https://www.gameaipro.com — updated treatment of GOAP with practical implementation guidance
- Jeff Orkin's AI page at MIT: https://alumni.media.mit.edu/~jorkin/ — additional papers and talks on the F.E.A.R. AI system

**Exercise:** Design (on paper) a GOAP action set for a survival game NPC. Define 5 goals (stay fed, stay hydrated, stay safe, build shelter, stockpile resources) and 10-12 actions with preconditions and effects (gather wood, build fire, cook food, find water, build wall, craft weapon, etc.). For each action, write the preconditions, effects, and cost. Then manually trace the planner: if the NPC is hungry and has raw meat but no fire, what plan does it construct? What if it has no food at all? Walk through the A* search by hand.

**Time:** 5-8 hours

---

## Module 7: Spatial Awareness & Perception

> **Deep dive:** [Full study guide](module-07-spatial-awareness-perception.md)

**Goal:** Give NPCs senses — vision cones, hearing, memory, alert states, and stealth game patterns.

Everything up to this point has assumed that NPCs magically know where the player is. In most games, that's fine — simple distance checks and line-of-sight raycasts are sufficient. But when you're building stealth games, horror games, or any game where **awareness** is a mechanic, you need a proper perception system.

A perception system gives NPCs simulated senses. **Vision** is typically a cone (angle + distance) with raycast occlusion checks — the NPC can only "see" targets within its field of view that aren't behind walls. **Hearing** is a radius check triggered by events (footsteps, gunshots, breaking glass), with sound propagation rules (attenuated by distance, blocked by thick walls, travels through open doors). The crucial addition is **memory** — when the NPC loses sight of the player, it doesn't instantly forget. It remembers the last known position and investigates. This is what makes stealth games work: the gap between "fully aware" and "completely oblivious" is filled with tension.

Alert states tie perception to the FSM or behavior tree from earlier modules. A typical stealth game uses a multi-level alert system: Unaware -> Suspicious (heard something) -> Searching (investigating stimulus) -> Alert (confirmed threat) -> Combat. Each level changes NPC behavior, movement speed, detection sensitivity, and often triggers UI feedback (the classic "awareness meter" filling up). If you've played Metal Gear Solid, Hitman, or Dishonored, you've experienced carefully tuned perception systems. The player psychology concepts from the [Game Design Theory roadmap](../game-design-theory/game-design-theory-roadmap.md) — particularly flow state and readable challenge — are directly relevant here: the perception system must be fair, learnable, and communicative.

**Key concepts:**
- **Vision cones:** Field-of-view angle, view distance, and occlusion raycasts
- **Hearing radius:** Event-driven sound propagation, distance attenuation, obstruction by geometry
- **NPC memory:** Last known position, decay over time, investigation behavior
- **Alert levels:** Unaware -> Suspicious -> Searching -> Alert -> Combat (with decay back down)
- **Detection meters:** Gradual awareness buildup — being partially visible fills a meter; fully hidden drains it
- **Stimulus system:** A unified event queue for all perception inputs (visual, auditory, damage, allied alerts)
- **Communication between NPCs:** One NPC spots the player and alerts nearby allies, propagating awareness through the group

**Read:**
- "Perception and Awareness in Game AI" from *Game AI Pro*: https://www.gameaipro.com — covers vision, hearing, and memory systems in production games
- "How Does the AI See the World?" on Red Blob Games: https://www.redblobgames.com/articles/visibility/ — interactive exploration of line-of-sight and visibility algorithms
- "Stealth Game AI" from *Game AI Pro*: https://www.gameaipro.com — practical architecture for stealth game perception

**Exercise:** Build a stealth prototype with a guard that has a visible vision cone (draw it so the player can see it). The guard patrols on a path. When the player enters the vision cone and line-of-sight is clear, an awareness meter fills up based on distance (closer = faster). If the meter fills completely, the guard enters Chase mode. If the player breaks line-of-sight, the guard investigates the last known position. Add a hearing radius — the player's footsteps are "loud" when running and "quiet" when walking. The guard should turn toward sounds. This exercise integrates Module 1 (FSM for states), Module 3 (steering for movement), and this module's perception system.

**Time:** 5-8 hours

---

## Module 8: Group & Crowd Behavior

> **Deep dive:** [Full study guide](module-08-group-crowd-behavior.md)

**Goal:** Coordinate multiple NPCs — formations, squad tactics, influence maps, and leader-follower patterns.

A single smart NPC is impressive. A group of NPCs that coordinate is a different challenge entirely. Group AI isn't just "run the individual AI for each NPC" — that produces a mob of individuals, not a squad. True group behavior requires NPCs to share information, assign roles, and act as a unit.

**Formations** are the simplest group behavior: NPCs maintain positions relative to a leader or formation center. A V-formation, a line, a circle — each has a set of offset positions that NPCs steer toward using Arrive (from Module 3). When the leader moves, the formation moves. When an NPC dies, the formation closes the gap. This is used in RTS games, squad shooters, and even enemy wave patterns in shmups.

**Squad tactics** go further. A tactical AI needs to answer: who flanks? Who provides cover fire? Who retreats to heal? This is typically managed by a **squad coordinator** — a meta-AI that doesn't control any individual NPC but assigns roles and objectives. The coordinator might use an **influence map** — a grid overlaid on the level where each cell stores values like "danger level," "enemy visibility," "tactical advantage." NPCs query the influence map to find good positions: "find a cell that has high cover value, low danger, and line-of-sight to the target." This is how F.E.A.R.'s soldiers coordinate flanking maneuvers and how RTS games compute base placement.

**Key concepts:**
- **Formations:** Offset-based positioning relative to a leader or center point, with slot assignment and gap-closing
- **Squad coordinator:** A meta-AI that assigns roles (assault, support, flank, reserve) to individual NPCs
- **Influence maps:** Grid-based spatial data representing threat, territory, resources, or tactical value
- **Leader-follower:** One NPC makes pathfinding decisions; others follow using steering with formation offsets
- **Crowd simulation:** Steering-based movement for large numbers of agents — uses flow fields (Module 4) and local avoidance
- **Role assignment:** Dynamic allocation of squad roles based on NPC capabilities, health, position, and current needs
- **Tactical position evaluation:** Scoring positions based on cover, line-of-sight, distance to objective, and danger level

**Read:**
- "Coordinating Agents with Behavior Trees" from *Game AI Pro*: https://www.gameaipro.com — covers squad coordination patterns with behavior trees
- "Influence Maps" by Dave Mark, *Game AI Pro*: https://www.gameaipro.com — the definitive practical guide to building and using influence maps
- Craig Reynolds' original boids page (revisit): https://www.red3d.com/cwr/boids/ — flocking is the foundation of crowd behavior
- *Nature of Code*, Chapter 6: https://natureofcode.com/autonomous-agents/ — extended treatment of group behaviors and emergent flocking patterns

**Exercise:** Build a squad of 4 NPCs that coordinate to engage the player. Assign roles: one "leader" that pathfinds toward the player, two "flankers" that try to approach from the sides (offset 90 degrees from the leader's approach angle), and one "support" that hangs back. Use an influence map to determine flanking positions — cells with line-of-sight to the player but not along the leader's direct path. When one NPC is "killed," the coordinator should reassign roles. If you've completed Modules 3 and 4, you have all the movement tools you need. This exercise is about the coordination layer on top.

**Time:** 6-10 hours

---

## Module 9: Boss AI Patterns

> **Deep dive:** [Full study guide](module-09-boss-ai-patterns.md)

**Goal:** Design boss encounters that are memorable — phase systems, attack telegraphs, pattern choreography, and arena design.

Boss AI is a different discipline from regular NPC AI. A regular enemy needs to be a credible threat in quantity. A boss needs to be a *performance* — a solo encounter that tests the player's mastery of everything the game has taught them. Boss AI is closer to choreography than intelligence. The boss isn't trying to win; it's trying to create a dramatic, learnable, escalating challenge.

**Phase systems** are the backbone. A boss that does the same thing from 100% health to 0% is boring. Phases — typically triggered at health thresholds (75%, 50%, 25%) — introduce new attacks, increase speed, change the arena, or shift the boss's strategy entirely. Each phase should feel like a new puzzle that builds on the previous one. Phase 1 teaches the player to dodge sweeping attacks. Phase 2 adds projectiles between sweeps. Phase 3 makes the floor dangerous so dodging requires vertical awareness. The player's mastery from earlier phases carries forward, but the challenge deepens.

**Attack telegraphs** are where the difficulty design concepts from the [Game Design Theory roadmap](../game-design-theory/game-design-theory-roadmap.md) become directly actionable. Every boss attack must be **readable** — the player must be able to see it coming and know what to do. A wind-up animation, a glowing indicator on the floor, a sound cue, a brief pause before the strike. The telegraph duration *is* the difficulty tuning knob. Longer telegraph = easier to dodge = more accessible. Shorter telegraph = demands faster reaction = harder. The telegraph must be fair: if the player dies and doesn't understand why, the telegraph failed.

**Key concepts:**
- **Phase systems:** Health-threshold triggers that change the boss's behavior set, introducing escalating complexity
- **Attack telegraphs:** Visual and audio cues that communicate incoming attacks — the fairness contract with the player
- **Pattern choreography:** Designing attack sequences that create rhythm (attack, dodge, punish window, attack)
- **Vulnerability windows:** Moments where the boss is exposed to damage, rewarding the player for correct reads
- **Arena design:** The boss room itself is part of the fight — cover, hazards, phase-triggered terrain changes
- **Difficulty ratcheting:** Phases should get harder, but each phase individually should be learnable within a few attempts
- **The "No Cheap Deaths" rule:** Every death should feel fair. The player should always be able to articulate what they should have done differently.

**Read:**
- "Boss Battle Design and Structure" from *Game AI Pro*: https://www.gameaipro.com — practical patterns for phase-based boss design
- "What Makes a Good Boss Fight" on Game Developer: https://www.gamedeveloper.com — search for boss design articles; multiple excellent postmortems exist
- *Game Feel* by Steve Swink — attack impact, hit pause, and screen shake are critical for boss fights feeling powerful

**Exercise:** Design a boss encounter on paper. Define 3 phases with health thresholds. For each phase, list 3-4 attacks with: telegraph description (what the player sees), timing (wind-up duration, active frames, recovery), dodge strategy (what the player should do), and punishment window (when the player can counter-attack). Draw the arena and annotate safe zones, hazard zones, and how they change per phase. Then implement at least Phase 1 — a boss that cycles through its attack pattern, telegraphs each attack, and has vulnerability windows between attacks.

**Time:** 6-10 hours

---

## Module 10: Debugging, Tuning & The Craft

> **Deep dive:** [Full study guide](module-10-debugging-tuning-craft.md)

**Goal:** Learn the meta-skills that separate functional AI from *great* AI — debug visualization, the "fun first" philosophy, and intentional imperfection.

This is the capstone module, and it's about something that can't be captured in an algorithm: the *craft* of game AI. You now know FSMs, behavior trees, steering, pathfinding, utility scoring, perception, group coordination, and boss patterns. The question is no longer "how do I make the NPC do X?" but "how do I make the NPC *feel right*?"

**Debug visualization** is your most important tool. If you can't see what the AI is thinking, you can't tune it. Draw the vision cones. Draw the pathfinding routes. Draw the current state name above each NPC's head. Draw the steering force vectors. Color-code alert states. Render the influence map as a heat overlay. Build a debug HUD that shows the utility scores for every action in real-time. This isn't optional polish — it's how you'll spend most of your AI development time. The best AI programmers in the industry all say the same thing: **invest in debug tools first.**

**Intentional imperfection** is the counterintuitive truth of game AI. An AI that plays perfectly is an AI that isn't fun. NPCs should miss occasionally. They should hesitate. They should pick a suboptimal route sometimes. They should have a reaction delay between seeing the player and responding. This isn't laziness — it's design. The player needs windows of opportunity to exploit, patterns to learn, and moments where they feel clever. A perfect AI denies all of those. The craft is in making the imperfections feel natural rather than stupid — the NPC should feel like it's making a *mistake*, not executing a random failure chance.

**Key concepts:**
- **Debug visualization:** Draw states, paths, perception, steering vectors, scores — everything the AI "thinks" should be visible on-screen during development
- **Reaction time & input delay:** Adding human-like delays between perception and action to create exploitable windows
- **Intentional inaccuracy:** NPCs that miss shots, lose track of the player, or choose suboptimal paths — on purpose
- **Difficulty via tuning, not code:** The same AI architecture should support easy and hard modes through parameter changes (detection range, reaction time, accuracy, aggression scores), not different code paths
- **Performance budgets:** AI is expensive. Profile your AI tick. Budget milliseconds per frame. Use LOD (level of detail) for AI — faraway NPCs run simplified behavior
- **The "watch someone play" test:** The ultimate AI validation is watching a player who doesn't know the rules engage with your NPCs. Do they feel alive? Do fights feel fair? Does the player ever say "whoa, that was smart"?
- **"Fun first" philosophy:** If a technically correct AI behavior makes the game less fun, the behavior is wrong. Fun overrides correctness, always.

**Read:**
- "Debugging AI: Tools and Techniques" from *Game AI Pro*: https://www.gameaipro.com — practical debug visualization and logging techniques
- "The Art of Imperfection in Game AI" on Game Developer: https://www.gamedeveloper.com — search for articles on AI difficulty tuning and intentional imperfection
- *Game Programming Patterns* by Robert Nystrom: https://gameprogrammingpatterns.com — the "Game Loop" and "Update Method" chapters are relevant for AI performance budgeting

**Exercise:** Take any NPC you built in a previous module and add a full debug visualization overlay. Show: the current state/behavior tree node (as text above the NPC), the vision cone (filled when the player is visible), the pathfinding route (as a line), steering force vectors (as colored arrows), and perception stimuli (as icons or circles). Toggle the overlay with a key press. Then, with the debug view on, add intentional imperfection: a 0.3-second reaction delay before state transitions, a 15% chance to "lose track" of the player during chase, and a slight accuracy variance on ranged attacks. Watch how the NPC feels more alive with these "flaws." Tune the values until the NPC feels challenging but fair.

**Time:** 4-6 hours

---

## Essential Bookmarks

| Resource | URL | Notes |
|----------|-----|-------|
| Red Blob Games | https://www.redblobgames.com | Interactive guides on pathfinding, grids, and movement — the best visual learning resource for game AI math |
| Game AI Pro | https://www.gameaipro.com | Free chapters from three volumes — industry professionals sharing production-tested techniques |
| Game Programming Patterns | https://gameprogrammingpatterns.com | Free online book — the State, Observer, and Component patterns are AI essentials |
| Craig Reynolds' Steering | https://www.red3d.com/cwr/steer/ | The original source for steering behaviors and boids |
| Nature of Code | https://natureofcode.com | Beautiful interactive book covering autonomous agents, flocking, and emergent systems |
| Game Developer | https://www.gamedeveloper.com | Thousands of free articles and postmortems — search for specific AI topics |
| Jeff Orkin's AI Page | https://alumni.media.mit.edu/~jorkin/ | Papers and resources from the creator of F.E.A.R.'s GOAP system |

---

## ADHD-Friendly Tips

- **Start with FSMs.** Seriously. Don't skip to GOAP because it sounds cooler. A well-tuned FSM will carry you further than a half-understood planner. You can always upgrade later.
- **Build one NPC, not ten.** Get a single enemy feeling right before you build a bestiary. One smart guard is more impressive (and more educational) than ten dumb ones.
- **Debug visuals are dopamine.** Drawing vision cones and path lines is oddly satisfying. Do this early — it makes every subsequent module more fun because you can *see* the AI thinking.
- **Steal from games you love.** Play Metal Gear Solid and write down every guard behavior you see. Reverse-engineer it as an FSM. Congratulations, you now have a design document for your own stealth AI.
- **One module per session.** Don't try to learn behavior trees, steering, and pathfinding in one sitting. Each module is a complete meal. Eat one, digest it, come back for the next.
- **The Red Blob Games rabbit hole is productive.** If you end up spending two hours playing with Amit Patel's interactive A* demo, that counts as studying. His site is the rare resource where procrastination-browsing is actual learning.
- **Paper-design first.** Before coding any AI system, draw the state diagram / behavior tree / influence map on paper. Five minutes of drawing saves an hour of confused debugging. Keep scratch paper next to your keyboard.
