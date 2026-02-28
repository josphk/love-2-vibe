# Module 2: Behavior Trees

**Part of:** [Game AI Learning Roadmap](game-ai-learning-roadmap.md)
**Estimated study time:** 5-7 hours
**Prerequisites:** [Module 1: Finite State Machines](module-01-finite-state-machines.md)

---

## Overview

Behavior trees are how the game industry solved the state explosion problem. Where FSMs give you a flat web of states and transitions that becomes unmanageable past 7-8 states, behavior trees give you a **tree** — a hierarchical structure that's composable, reusable, and scales to complex AI without turning into spaghetti.

The core idea is elegant. Every node in the tree does one of three things: it **succeeds**, it **fails**, or it's still **running**. The tree is evaluated from the root every tick, and composite nodes (Sequence and Selector) combine their children's results to make decisions. A Sequence runs its children in order and fails if any child fails — it's an AND gate. A Selector tries its children in order and succeeds when any child succeeds — it's an OR gate. That's it. Two composite types, three return values, and you can express remarkably complex AI.

Halo 2 popularized behavior trees in games, and they've since become the default architecture in Unreal Engine, most AAA studios, and Godot (via addons). If you're going to work in game AI professionally, you need to know behavior trees. But even for solo indie work, they're worth learning because they fundamentally change how you think about AI design — instead of asking "what state should this NPC be in?", you ask "what should this NPC try to do, in what priority order?"

---

## 1. The Three Return Values

Every node in a behavior tree returns one of exactly three statuses:

- **Success** — the node accomplished its goal
- **Failure** — the node could not accomplish its goal
- **Running** — the node is still working on it (will continue next tick)

This three-value system is what makes behavior trees tick. A condition node like "is player visible?" returns Success or Failure immediately. An action node like "move to position" returns Running while the NPC is moving and Success when it arrives. A complex behavior like "patrol the area" might return Running for minutes.

```
Node return values:
┌─────────┐
│ SUCCESS │ — "I did it"
├─────────┤
│ FAILURE │ — "I can't do it"
├─────────┤
│ RUNNING │ — "I'm working on it"
└─────────┘
```

The Running status is what gives behavior trees their power over simple decision trees. It allows multi-frame actions — things that take time, like walking somewhere or playing an animation — to coexist with instant checks. An FSM handles this naturally (you stay in a state across frames), but a simple decision tree can't. Running bridges that gap.

---

## 2. Leaf Nodes — Conditions and Actions

Leaf nodes are the bottom of the tree — they don't have children. There are two types:

**Condition nodes** check something about the world and return Success or Failure instantly. They never return Running. Examples:
- "Is player visible?" → Success / Failure
- "Is health below 30%?" → Success / Failure
- "Has ammo?" → Success / Failure
- "Is at destination?" → Success / Failure

**Action nodes** make the NPC do something. They can return any of the three values:
- "Move to player" → Running (still moving) or Success (arrived)
- "Attack" → Running (attack animation playing) or Success (attack complete)
- "Play sound" → Success (instant)
- "Wait 2 seconds" → Running (waiting) or Success (timer expired)

```gdscript
# GDScript — Example leaf nodes
class_name BT_IsPlayerVisible extends BTNode:
    func tick(npc, dt) -> int:
        if npc.can_see_player():
            return SUCCESS
        return FAILURE

class_name BT_MoveToPlayer extends BTNode:
    func tick(npc, dt) -> int:
        var dist = npc.global_position.distance_to(npc.player.global_position)
        if dist < 10.0:
            return SUCCESS
        npc.move_toward(npc.player.global_position, npc.chase_speed, dt)
        return RUNNING
```

```lua
-- Lua — Example leaf nodes
local function is_player_visible(npc)
    if can_see_player(npc) then return "success" end
    return "failure"
end

local function move_to_player(npc, dt)
    local dist = distance(npc.x, npc.y, player.x, player.y)
    if dist < 10 then return "success" end
    move_toward(npc, player.x, player.y, npc.chase_speed, dt)
    return "running"
end
```

The key discipline: **condition nodes should be pure checks with no side effects.** They don't change anything — they just look at the world and report. Action nodes are where changes happen.

---

## 3. Composite Nodes — Sequence and Selector

Composite nodes have children and combine their results. The two fundamental composites are Sequence and Selector.

### Sequence (AND logic)

A Sequence runs its children left to right. If a child returns **Success**, it moves to the next child. If a child returns **Failure**, the Sequence immediately returns **Failure** (short-circuit). If a child returns **Running**, the Sequence returns **Running**. If all children succeed, the Sequence returns **Success**.

Think of it as: "Do all of these things in order."

```
Sequence: "Chase and Attack"
├── [Condition] Is player visible?     → Success ✓ (continue)
├── [Action] Move to player            → Running... (Sequence returns Running)
│   ... next tick, move completes ...  → Success ✓ (continue)
└── [Action] Attack player             → Running... → Success ✓
                                        Sequence returns Success ✓
```

If "Is player visible?" fails, the Sequence immediately fails — we never try to move or attack. This is the short-circuit behavior that makes Sequences useful as guarded actions: put a condition first, then the actions that should only happen if the condition is true.

### Selector (OR logic / Fallback)

A Selector runs its children left to right. If a child returns **Failure**, it moves to the next child. If a child returns **Success**, the Selector immediately returns **Success** (short-circuit). If a child returns **Running**, the Selector returns **Running**. If all children fail, the Selector returns **Failure**.

Think of it as: "Try these options in priority order."

```
Selector: "What should I do?"
├── [Sequence] Attack if close        → Failure ✗ (player too far, try next)
├── [Sequence] Chase if visible       → Running... (Selector returns Running)
└── [Sequence] Patrol                 → (not reached, Chase is running)
```

The Selector is your priority system. Children are ordered by priority — the first child that succeeds (or is running) wins. This is how you express "attack if possible, otherwise chase, otherwise patrol" without a single `if/elseif` chain.

### The combination

Here's the magic: Selectors and Sequences nest. A Selector's children can be Sequences, and Sequences can contain Selectors. This creates a tree that expresses complex prioritized behavior:

```
[Selector] Root — "What should I do?"
├── [Sequence] Combat — highest priority
│   ├── [Condition] Is player in attack range?
│   ├── [Action] Attack player
│   └── [Action] Dodge back
├── [Sequence] Pursue — medium priority
│   ├── [Condition] Is player visible?
│   └── [Action] Move to player
└── [Sequence] Patrol — lowest priority (fallback)
    ├── [Action] Move to next waypoint
    └── [Action] Wait at waypoint
```

The root Selector tries Combat first. If the player isn't in range, Combat's Sequence fails at the condition check, and the Selector moves to Pursue. If the player isn't visible either, it falls through to Patrol. This priority-based fallback is the bread and butter of behavior tree design.

---

## 4. Decorators — Modifying Child Behavior

Decorators are nodes with exactly one child. They modify that child's behavior or result. Common decorators:

**Inverter** — Flips Success to Failure and vice versa. "Is player NOT visible?" = Inverter wrapping "Is player visible?"

**Repeater** — Runs the child N times, or forever. Useful for patrol loops.

**Cooldown** — After the child succeeds, prevent it from running again for N seconds. Prevents the NPC from attacking every single tick.

**Timeout** — If the child has been Running for more than N seconds, force it to Failure. Prevents NPCs from chasing forever.

**Succeed Always** — Returns Success regardless of the child's result. Useful when you want to attempt something but don't care if it fails.

```
[Selector] Root
├── [Sequence] Combat
│   ├── [Condition] Is player in range?
│   ├── [Cooldown: 1.5s] Attack cooldown
│   │   └── [Action] Attack player
│   └── ...
├── [Sequence] Pursue
│   ├── [Condition] Is player visible?
│   ├── [Timeout: 10s] Give up after 10 seconds
│   │   └── [Action] Move to player
│   └── ...
```

The Cooldown decorator means the NPC attacks, then waits 1.5 seconds before it can attack again — without any explicit timer management in the attack code. The Timeout decorator means the NPC will give up chasing after 10 seconds, even if the player is still technically visible. Clean, composable behavior modification.

```gdscript
# GDScript — Decorator examples
class_name BT_Inverter extends BTNode:
    var child: BTNode

    func tick(npc, dt) -> int:
        var result = child.tick(npc, dt)
        if result == SUCCESS:
            return FAILURE
        elif result == FAILURE:
            return SUCCESS
        return RUNNING  # Running is not inverted

class_name BT_Cooldown extends BTNode:
    var child: BTNode
    var cooldown_time: float
    var timer: float = 0.0

    func tick(npc, dt) -> int:
        if timer > 0:
            timer -= dt
            return FAILURE  # Still cooling down
        var result = child.tick(npc, dt)
        if result == SUCCESS:
            timer = cooldown_time
        return result
```

```lua
-- Lua — Decorator examples
local function inverter(child)
    return function(npc, dt)
        local result = child(npc, dt)
        if result == "success" then return "failure" end
        if result == "failure" then return "success" end
        return "running"
    end
end

local function cooldown(seconds, child)
    local timer = 0
    return function(npc, dt)
        if timer > 0 then
            timer = timer - dt
            return "failure"
        end
        local result = child(npc, dt)
        if result == "success" then
            timer = seconds
        end
        return result
    end
end
```

---

## 5. The Blackboard Pattern

Behavior tree nodes need to share data. The "Is player visible?" condition needs to tell the "Move to player" action *where* the player is. But direct coupling between nodes defeats the purpose of composability.

The solution is a **blackboard** — a shared key-value store that all nodes in the tree can read from and write to. Think of it as a shared whiteboard that nodes leave messages on.

```
Blackboard:
┌────────────────────────────────────┐
│  player_position: (300, 200)       │
│  player_visible: true              │
│  last_known_position: (280, 195)   │
│  health: 75                        │
│  current_target: "player"          │
│  ammo_count: 12                    │
│  alert_level: 2                    │
└────────────────────────────────────┘
```

Nodes read from the blackboard to make decisions and write to the blackboard to share information:

```gdscript
# GDScript — Blackboard usage
class_name BT_CheckPlayerVisible extends BTNode:
    func tick(npc, dt) -> int:
        if npc.can_see_player():
            # Write to blackboard so other nodes know
            npc.blackboard["player_visible"] = true
            npc.blackboard["player_position"] = npc.player.global_position
            npc.blackboard["last_known_position"] = npc.player.global_position
            return SUCCESS
        npc.blackboard["player_visible"] = false
        return FAILURE

class_name BT_MoveToLastKnown extends BTNode:
    func tick(npc, dt) -> int:
        # Read from blackboard — doesn't need to know about player directly
        var target = npc.blackboard.get("last_known_position", npc.global_position)
        if npc.global_position.distance_to(target) < 10.0:
            return SUCCESS
        npc.move_toward(target, npc.speed, dt)
        return RUNNING
```

```lua
-- Lua — Blackboard as a simple table
local blackboard = {}

local function check_player_visible(npc, dt)
    if can_see_player(npc) then
        blackboard.player_visible = true
        blackboard.player_x = player.x
        blackboard.player_y = player.y
        blackboard.last_known_x = player.x
        blackboard.last_known_y = player.y
        return "success"
    end
    blackboard.player_visible = false
    return "failure"
end

local function move_to_last_known(npc, dt)
    local tx = blackboard.last_known_x or npc.x
    local ty = blackboard.last_known_y or npc.y
    local dist = distance(npc.x, npc.y, tx, ty)
    if dist < 10 then return "success" end
    move_toward(npc, tx, ty, npc.speed, dt)
    return "running"
end
```

The blackboard decouples nodes from each other. The "Move to last known" node doesn't know or care about the player — it just reads a position from the blackboard. This means you can reuse it for any "move to a stored position" behavior.

---

## 6. Tick-Based Evaluation and the Running Problem

Behavior trees are re-evaluated from the root on every tick (every frame or every AI update). This is both their strength and their trickiest aspect.

**The strength:** Re-evaluating from the root means the tree can dynamically reprioritize. If the NPC is patrolling and the player suddenly appears, the next tick's evaluation will route through the Combat branch instead of the Patrol branch. No explicit transition needed — the tree's structure handles it.

**The problem:** What about Running nodes? If "Move to player" returned Running last tick, should we resume it or re-evaluate from the root? This is where behavior tree implementations diverge.

**Option A: Always restart from root.** Every tick, evaluate from the root. If a higher-priority branch now succeeds, it preempts the running node. This is responsive but can cause stuttering — an NPC might repeatedly start and abort actions if conditions flicker.

**Option B: Resume Running nodes.** Remember which node returned Running and resume it directly, only re-evaluating from the root when the running node completes. This is smooth but less responsive — the NPC might continue an outdated action when the situation has changed.

**Option C: Reactive trees (the common compromise).** Re-evaluate from the root, but when the evaluation reaches the previously Running node, resume it. If the evaluation takes a different path (a higher-priority branch now succeeds), the Running node is aborted. This gives you responsiveness for priority changes and smoothness for ongoing actions.

```
Tick 1: Root → Selector → Pursue (Running)
Tick 2: Root → Selector → Combat (Success!) → Pursue aborted
Tick 3: Root → Selector → Combat (Failure) → Pursue resumes
```

For your first implementation, start with Option A (always restart from root). It's the simplest to implement and debug. Upgrade to Option C when you notice stuttering issues.

---

## 7. Building a Behavior Tree — The Guard Revisited

Let's redesign the guard NPC from Module 1 as a behavior tree. Here's the tree structure:

```
[Selector] Root
├── [Sequence] Combat
│   ├── [Condition] Is player in attack range?
│   └── [Cooldown: 1.0s]
│       └── [Action] Attack
├── [Sequence] Pursue
│   ├── [Condition] Is player visible?
│   └── [Action] Move to player
├── [Sequence] Search
│   ├── [Condition] Has last known position?
│   ├── [Condition] Search timer active?
│   ├── [Action] Move to last known position
│   └── [Action] Look around
└── [Sequence] Patrol
    ├── [Action] Move to next waypoint
    └── [Action] Pause at waypoint
```

Now here's the key insight: **adding new behaviors is trivial.** Want the guard to call for backup? Insert a new branch:

```
[Selector] Root
├── [Sequence] Call Backup
│   ├── [Condition] Is player visible?
│   ├── [Condition] Not already called backup?
│   └── [Action] Send alert to nearby guards
├── [Sequence] Combat
│   ...
```

In an FSM, this would require adding transitions from multiple states. In a behavior tree, it's a single branch insertion. This composability is why behavior trees scale where FSMs don't.

---

## Code Walkthrough: A Complete Behavior Tree Engine

Here's a minimal but functional behavior tree implementation. This engine supports Sequence, Selector, Inverter, Cooldown, and leaf nodes.

```gdscript
# GDScript — Minimal BT engine
const SUCCESS = 0
const FAILURE = 1
const RUNNING = 2

class BTNode:
    func tick(_npc, _dt) -> int:
        return FAILURE

class BTSequence extends BTNode:
    var children: Array[BTNode] = []
    var current_child := 0

    func tick(npc, dt) -> int:
        while current_child < children.size():
            var result = children[current_child].tick(npc, dt)
            if result == RUNNING:
                return RUNNING
            if result == FAILURE:
                current_child = 0  # reset for next evaluation
                return FAILURE
            current_child += 1
        current_child = 0
        return SUCCESS

class BTSelector extends BTNode:
    var children: Array[BTNode] = []
    var current_child := 0

    func tick(npc, dt) -> int:
        while current_child < children.size():
            var result = children[current_child].tick(npc, dt)
            if result == RUNNING:
                return RUNNING
            if result == SUCCESS:
                current_child = 0
                return SUCCESS
            current_child += 1
        current_child = 0
        return FAILURE

class BTInverter extends BTNode:
    var child: BTNode

    func tick(npc, dt) -> int:
        var result = child.tick(npc, dt)
        if result == SUCCESS: return FAILURE
        if result == FAILURE: return SUCCESS
        return RUNNING
```

```lua
-- Lua (LÖVE) — Minimal BT engine using functions and tables

local BT = {}

function BT.sequence(children)
    local current = 1
    return function(npc, dt)
        while current <= #children do
            local result = children[current](npc, dt)
            if result == "running" then return "running" end
            if result == "failure" then
                current = 1
                return "failure"
            end
            current = current + 1
        end
        current = 1
        return "success"
    end
end

function BT.selector(children)
    local current = 1
    return function(npc, dt)
        while current <= #children do
            local result = children[current](npc, dt)
            if result == "running" then return "running" end
            if result == "success" then
                current = 1
                return "success"
            end
            current = current + 1
        end
        current = 1
        return "failure"
    end
end

function BT.inverter(child)
    return function(npc, dt)
        local result = child(npc, dt)
        if result == "success" then return "failure" end
        if result == "failure" then return "success" end
        return "running"
    end
end

function BT.cooldown(seconds, child)
    local timer = 0
    return function(npc, dt)
        if timer > 0 then
            timer = timer - dt
            return "failure"
        end
        local result = child(npc, dt)
        if result == "success" then timer = seconds end
        return result
    end
end

-- Leaf node helpers
function BT.condition(fn)
    return function(npc, dt)
        if fn(npc) then return "success" end
        return "failure"
    end
end

function BT.action(fn)
    return function(npc, dt)
        return fn(npc, dt)
    end
end

-- Construct the guard behavior tree
local guard_tree = BT.selector({
    -- Priority 1: Attack if in range
    BT.sequence({
        BT.condition(function(npc) return npc.dist_to_player < npc.attack_range end),
        BT.cooldown(1.0, BT.action(function(npc, dt)
            -- Attack logic here
            npc.is_attacking = true
            return "success"
        end)),
    }),

    -- Priority 2: Chase if visible
    BT.sequence({
        BT.condition(function(npc) return npc.can_see_player end),
        BT.action(function(npc, dt)
            move_toward(npc, player.x, player.y, npc.chase_speed, dt)
            npc.blackboard.last_x = player.x
            npc.blackboard.last_y = player.y
            if npc.dist_to_player < npc.attack_range then
                return "success"
            end
            return "running"
        end),
    }),

    -- Priority 3: Search last known position
    BT.sequence({
        BT.condition(function(npc) return npc.blackboard.last_x ~= nil end),
        BT.condition(function(npc) return npc.search_timer > 0 end),
        BT.action(function(npc, dt)
            npc.search_timer = npc.search_timer - dt
            local dist = distance(npc.x, npc.y, npc.blackboard.last_x, npc.blackboard.last_y)
            if dist < 10 or npc.search_timer <= 0 then
                npc.search_timer = 0
                npc.blackboard.last_x = nil
                return "failure"  -- done searching, fall through to patrol
            end
            move_toward(npc, npc.blackboard.last_x, npc.blackboard.last_y, npc.speed * 0.7, dt)
            return "running"
        end),
    }),

    -- Priority 4: Patrol (fallback)
    BT.action(function(npc, dt)
        local t = npc.patrol[npc.patrol_index]
        local dist = distance(npc.x, npc.y, t[1], t[2])
        if dist < 8 then
            npc.patrol_index = npc.patrol_index % #npc.patrol + 1
        end
        move_toward(npc, t[1], t[2], npc.speed, dt)
        return "running"  -- always patrolling
    end),
})

-- In update loop:
-- guard_tree(npc, dt)
```

This functional approach (in Lua) is concise and readable. The tree structure is visible in the code itself — you can see the priorities by reading top to bottom. The GDScript version is more object-oriented but follows the same pattern.

---

## 8. Behavior Trees vs. FSMs — When to Use Which

The two systems aren't competitors — they're complementary tools for different scales of complexity.

| Aspect | FSM | Behavior Tree |
|--------|-----|---------------|
| **Best for** | Simple NPCs (3-7 behaviors) | Complex NPCs (8+ behaviors) |
| **Adding behaviors** | Hard (new transitions to many states) | Easy (insert a branch) |
| **Debuggability** | Excellent (print current state) | Good (print active branch) |
| **Reusability** | Low (states are tightly coupled) | High (subtrees are reusable) |
| **Implementation effort** | Very low | Moderate (need a BT engine) |
| **Runtime cost** | Minimal | Slightly higher (tree traversal) |
| **State persistence** | Natural (you're in a state) | Requires Running + blackboard |
| **Learning curve** | Trivial | Moderate |

**Use an FSM when:**
- The NPC has fewer than 7 distinct behaviors
- The state diagram fits on a single page
- You want the simplest possible implementation
- You're prototyping and need something working in 10 minutes

**Use a behavior tree when:**
- The NPC has many behaviors that need priority ordering
- You want to share behavior subtrees between NPC types
- The designer needs to tweak behavior without touching code
- You anticipate adding behaviors over time during development

**Combine them:** Many production games use FSMs inside behavior tree leaf nodes. The behavior tree handles high-level decision making ("should I fight, flee, or patrol?") and delegates to FSMs for the details ("while fighting, cycle through melee/dodge/ranged sub-states"). This hybrid approach gives you the best of both worlds.

---

## Common Pitfalls

### 1. Forgetting to reset Sequence/Selector state

If a Sequence is interrupted (the tree takes a different path on the next tick), you need to reset its `current_child` index. Otherwise, when the Sequence runs again later, it starts from the middle instead of the beginning. This causes bizarre behavior where NPCs skip steps.

### 2. Infinite Running loops

An action node returns Running forever because its completion condition is never met. The NPC walks toward a position it can never reach (blocked by a wall), and the tree never falls through to a lower-priority branch. Always add Timeout decorators to actions that could get stuck.

### 3. Too many conditions in Sequences

A Sequence with five condition checks before one action means five checks every tick even when nothing has changed. For conditions that rarely change (like "has ammo"), consider caching results in the blackboard and only rechecking periodically.

### 4. Overcomplicating the tree structure

Your first behavior tree should have one Selector with 3-4 Sequence children. That's it. Don't start with 5 levels of nesting, parallel nodes, and 8 decorators. Build the simplest tree that works, then refine.

### 5. Not visualizing the tree during development

Behavior trees are hard to debug by reading logs. Build a debug visualization that highlights the currently active path in the tree. Color-code nodes by their last return value (green = Success, red = Failure, yellow = Running). This is non-optional for any serious behavior tree work.

### 6. Building a behavior tree when an FSM would suffice

Behavior trees have real implementation overhead — you need a BT engine, a blackboard, possibly a visual editor. If your NPC has 4 states and clear transitions, an FSM is faster to build, easier to debug, and runs more efficiently. Don't use the fancy tool when the simple one works.

---

## Exercises

### Exercise 1: Redesign the Guard as a Behavior Tree
**Time:** 1.5-2 hours

Take the five-state guard from Module 1's exercises and reimplement it as a behavior tree. The tree should have a root Selector with branches for: Combat (attack if in range), Pursue (chase if visible), Search (investigate last known position), and Patrol (fallback).

Requirements:
1. The behavior should be identical to the FSM version
2. Use a blackboard for shared data (player position, last known position, search timer)
3. Add a debug display showing which branch is currently active

**Concepts practiced:** BT implementation, FSM-to-BT translation, blackboard pattern

**Stretch goal:** Add a "Call for Backup" branch at the highest priority — if the player is visible and no backup has been called, alert nearby guards. Notice how this is a single branch insertion, not a rewrite.

---

### Exercise 2: Composable Behavior Library
**Time:** 2-3 hours

Build a library of reusable behavior tree nodes and compose them to create three different NPC types:

Node library:
- Conditions: IsPlayerVisible, IsPlayerInRange, IsHealthLow, HasAmmo
- Actions: MoveToPlayer, MoveToPosition, Attack, Flee, Reload, Patrol, Wait
- Decorators: Cooldown, Timeout, Inverter

NPC types (same nodes, different tree structures):
1. **Soldier:** Attack > Chase > Patrol. Reloads when out of ammo.
2. **Scout:** Chase > Report position (write to blackboard) > Flee. Never attacks.
3. **Berserker:** Attack (no cooldown!) > Chase. Never patrols, never flees. Just aggression.

**Concepts practiced:** Composability, reusable nodes, tree design as NPC personality

**Stretch goal:** Add a "Medic" NPC that uses a Selector: (Heal ally if ally health low) > (Follow leader) > (Patrol). The medic's tree reuses the MoveToPosition action with a different target.

---

### Exercise 3: Visual Behavior Tree Debugger
**Time:** 2-3 hours

Implement a visual debug overlay that draws the behavior tree on screen during gameplay. Requirements:

1. Draw each node as a box with its name
2. Draw connections between parent and child nodes
3. Color-code by last return value: green (Success), red (Failure), yellow (Running), gray (not evaluated this tick)
4. Highlight the currently active path
5. Toggle the display with a key press

This is a tool-building exercise. The debugger will be useful for every behavior tree you build from now on.

**Concepts practiced:** Debug visualization, tree traversal, tool-building

**Stretch goal:** Show blackboard contents next to the tree. Update in real-time.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| "Behavior Trees for AI: How They Work" by Chris Simpson | Article | The single best introductory article — clear diagrams, no prerequisites, covers all node types |
| "Introduction to Behavior Trees" from *Game AI Pro* | Book chapter (free) | Production-focused coverage with edge cases and performance considerations |
| *Artificial Intelligence for Games* by Millington & Funge, Ch. 5 | Book | Academic but thorough treatment of behavior trees with formal definitions |
| "Halo 2 AI" GDC presentation by Damian Isla | GDC talk | The presentation that popularized behavior trees in games — shows the design process |
| *Game Programming Patterns* by Robert Nystrom | Book (free) | The Component, State, and Observer patterns directly support BT implementation |

---

## Key Takeaways

1. **Three return values drive everything.** Success, Failure, Running. Every node returns one of these, and composite nodes combine them. This simple protocol enables complex behavior.

2. **Sequence = AND, Selector = OR.** A Sequence succeeds if all children succeed (do these things in order). A Selector succeeds if any child succeeds (try these options by priority). These two composites handle 90% of behavior tree design.

3. **The blackboard decouples nodes.** Nodes communicate through a shared key-value store, not through direct references. This is what makes nodes reusable across different trees and NPC types.

4. **Adding behaviors = inserting branches.** The fundamental advantage over FSMs. New behavior is a new branch in the tree, not a rewiring of the state diagram. This scales to complex AI without spaghetti.

5. **Start simple.** One Selector, 3-4 Sequences, a handful of leaf nodes. Build the minimal tree that works. Add complexity only when you need it.

6. **FSMs and behavior trees are complementary.** Use FSMs for simple NPCs, behavior trees for complex ones, and combine them when it makes sense. Neither is universally better.

---

## What's Next?

You now have the two most important decision-making patterns in game AI. FSMs handle simple behavioral modes. Behavior trees handle complex, prioritized decisions. But both of them need one thing they can't provide on their own: **natural movement.**

In [Module 3: Steering Behaviors](module-03-steering-behaviors.md), you'll learn how to make NPCs move through the world in fluid, organic ways. Instead of "set position toward target," your NPCs will have velocity, acceleration, and forces. They'll seek, flee, arrive smoothly, wander naturally, and flock in mesmerizing formations. Steering behaviors are the physics of game AI — the math that turns decisions into believable motion.

---

[Back to Game AI Learning Roadmap](game-ai-learning-roadmap.md)
