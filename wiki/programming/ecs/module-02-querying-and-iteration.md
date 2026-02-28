# Module 2: Querying and Iteration

**Part of:** [ECS Learning Roadmap](ecs-learning-roadmap.md)
**Estimated study time:** 3–5 hours
**Prerequisites:** [Module 1: Entities, Components, Systems](module-01-entities-components-systems.md)

---

## Overview

You know the ECS triad: entities are IDs, components are data, systems are logic. The question this module answers is: how does a system actually find the entities it cares about? You have 10,000 entities. Your MovementSystem only wants the ones with both a Position and a Velocity. How do you get that list without checking every entity, every frame?

There are three main approaches, ranging from dead-simple to blazing-fast. The naive loop checks every entity every frame. Indexed queries maintain lookup tables so intersection is fast. Archetype-based storage goes further, grouping entities by component signature so iteration is a linear scan of packed memory. Most beginner ECS implementations use the naive loop. Production engines like Flecs and Bevy use archetypes. You need to understand all three to know which tool fits your project.

System ordering is the other piece. Once you know how to query, you need to know when each system runs. Get the order wrong and you get subtle one-frame-late bugs that are maddening to debug. This module covers both query strategies and system ordering, then walks you through building a complete `world.query()` from scratch.

---

## 1. Simple Filter Iteration: Loop All, Check Components

The simplest strategy: every frame, loop through every entity in the world and ask "does this entity have all the components I need?" Process the ones that do, skip the ones that don't.

This is O(n) per system per frame, where n is total entity count. For small games — under a few thousand entities — this is completely fine. It's also trivially simple to implement and debug.

**Pseudocode:**
```
for each entity in world.allEntities:
    if entity.has(Position) and entity.has(Velocity):
        pos = entity.get(Position)
        vel = entity.get(Velocity)
        pos.x += vel.vx * dt
        pos.y += vel.vy * dt
```

**Lua (tiny-ecs / Love2D):**
```lua
-- tiny-ecs builds this filter approach into the library.
-- You declare what components a system needs; tiny-ecs handles the loop.

local tiny = require "tiny"

-- Define a filter: only process entities with both position and velocity
local movementSystem = tiny.processingSystem()
movementSystem.filter = tiny.requireAll("position", "velocity")

function movementSystem:process(entity, dt)
    entity.position.x = entity.position.x + entity.velocity.vx * dt
    entity.position.y = entity.position.y + entity.velocity.vy * dt
end

local world = tiny.newWorld(movementSystem)

-- Adding an entity — tiny-ecs internally loops to check filters on insert
local ball = { position = {x=100, y=200}, velocity = {vx=50, vy=0} }
world:addEntity(ball)

-- Each update, tiny-ecs loops matching entities and calls process()
function love.update(dt)
    world:update(dt)
end
```

**GDScript (Godot):**
```gdscript
# Without a dedicated ECS library, the naive loop looks like this.
# Entities are stored in a dictionary; components are nested dictionaries.

var entities = {}        # { id -> { compType -> data } }
var next_id = 0

func new_entity() -> int:
    var id = next_id
    next_id += 1
    entities[id] = {}
    return id

func add_component(id: int, comp_type: String, data: Dictionary):
    entities[id][comp_type] = data

func movement_system(dt: float):
    # Naive loop: check every entity
    for id in entities:
        var comps = entities[id]
        if comps.has("position") and comps.has("velocity"):
            comps["position"]["x"] += comps["velocity"]["vx"] * dt
            comps["position"]["y"] += comps["velocity"]["vy"] * dt

func _process(delta: float):
    movement_system(delta)
```

The naive loop is not wrong. tiny-ecs uses it. For a jam game, a tactics game, or anything under ~1000 active entities, you will never feel the cost. The problems start at scale: if you have 10 systems each scanning 50,000 entities every frame at 60 fps, that math adds up fast.

---

## 2. Indexed Queries: Lookup Tables

The next step: the world maintains an index. When you add a `velocity` component to entity 42, the world updates a set: `velocityIndex[42] = true`. When a system queries for `{position, velocity}`, the world intersects the position set with the velocity set. The result is only the entities that have both.

This is O(1) per lookup and O(k) to collect results, where k is the number of matching entities. You're no longer iterating non-matching entities at all.

The data structure looks like this:

```lua
-- world._index = {
--   ["position"] = { [entity1] = true, [entity2] = true, ... },
--   ["velocity"] = { [entity1] = true, [entity3] = true, ... },
-- }
```

**Pseudocode:**
```
-- On add:
world.index[compType][entityId] = true

-- On remove:
world.index[compType][entityId] = nil

-- On query({A, B, C}):
result = copy of index[A]
for each id in result:
    if not index[B][id] or not index[C][id]:
        remove id from result
return result
```

**Lua (tiny-ecs / Love2D):**
```lua
-- A self-contained indexed world implementation.

local World = {}
World.__index = World

function World.new()
    return setmetatable({
        _entities = {},   -- { id -> { compType -> data } }
        _index = {},      -- { compType -> { id -> true } }
        _nextId = 1,
    }, World)
end

function World:newEntity()
    local id = self._nextId
    self._nextId = self._nextId + 1
    self._entities[id] = {}
    return id
end

function World:add(id, compType, data)
    -- Store the component data
    self._entities[id][compType] = data

    -- Update the index
    if not self._index[compType] then
        self._index[compType] = {}
    end
    self._index[compType][id] = true
end

function World:remove(id, compType)
    self._entities[id][compType] = nil
    if self._index[compType] then
        self._index[compType][id] = nil
    end
end

function World:get(id, compType)
    return self._entities[id] and self._entities[id][compType]
end

function World:query(...)
    local types = {...}
    if #types == 0 then return {} end

    -- Start with the set for the first component type
    local firstType = types[1]
    if not self._index[firstType] then return {} end

    -- Collect candidates from the first index
    local results = {}
    for id, _ in pairs(self._index[firstType]) do
        results[id] = true
    end

    -- Intersect with each remaining component type
    for i = 2, #types do
        local compIndex = self._index[types[i]]
        if not compIndex then return {} end
        for id, _ in pairs(results) do
            if not compIndex[id] then
                results[id] = nil
            end
        end
    end

    -- Convert set to array for easy iteration
    local out = {}
    for id, _ in pairs(results) do
        out[#out + 1] = id
    end
    return out
end

-- Usage
local world = World.new()

local e1 = world:newEntity()
world:add(e1, "position", {x=10, y=20})
world:add(e1, "velocity", {vx=5, vy=0})

local e2 = world:newEntity()
world:add(e2, "position", {x=50, y=80})
-- e2 has no velocity

local e3 = world:newEntity()
world:add(e3, "position", {x=0, y=0})
world:add(e3, "velocity", {vx=-3, vy=2})

-- Query: only returns e1 and e3
local movers = world:query("position", "velocity")
for _, id in ipairs(movers) do
    local pos = world:get(id, "position")
    local vel = world:get(id, "velocity")
    pos.x = pos.x + vel.vx
    pos.y = pos.y + vel.vy
    print(string.format("entity %d moved to (%.1f, %.1f)", id, pos.x, pos.y))
end
-- Output:
-- entity 1 moved to (15.0, 20.0)
-- entity 3 moved to (-3.0, 2.0)
```

**GDScript (Godot):**
```gdscript
class_name IndexedWorld

var _entities: Dictionary = {}   # { id -> { compType -> data } }
var _index: Dictionary = {}      # { compType -> { id -> true } }
var _next_id: int = 0

func new_entity() -> int:
    var id = _next_id
    _next_id += 1
    _entities[id] = {}
    return id

func add(id: int, comp_type: String, data: Dictionary):
    _entities[id][comp_type] = data
    if not _index.has(comp_type):
        _index[comp_type] = {}
    _index[comp_type][id] = true

func remove_component(id: int, comp_type: String):
    if _entities.has(id):
        _entities[id].erase(comp_type)
    if _index.has(comp_type):
        _index[comp_type].erase(id)

func get_component(id: int, comp_type: String):
    if _entities.has(id) and _entities[id].has(comp_type):
        return _entities[id][comp_type]
    return null

func query(comp_types: Array) -> Array:
    if comp_types.is_empty():
        return []

    var first_type = comp_types[0]
    if not _index.has(first_type):
        return []

    # Start with a copy of the first component's entity set
    var candidates: Dictionary = _index[first_type].duplicate()

    # Intersect with remaining types
    for i in range(1, comp_types.size()):
        var comp_index = _index.get(comp_types[i], {})
        for id in candidates.keys():
            if not comp_index.has(id):
                candidates.erase(id)

    return candidates.keys()

# Usage
func _ready():
    var world = IndexedWorld.new()

    var e1 = world.new_entity()
    world.add(e1, "position", {"x": 10.0, "y": 20.0})
    world.add(e1, "velocity", {"vx": 5.0, "vy": 0.0})

    var e2 = world.new_entity()
    world.add(e2, "position", {"x": 50.0, "y": 80.0})
    # e2 has no velocity

    var movers = world.query(["position", "velocity"])
    for id in movers:
        var pos = world.get_component(id, "position")
        var vel = world.get_component(id, "velocity")
        pos["x"] += vel["vx"]
        pos["y"] += vel["vy"]
        print("entity %d at (%.1f, %.1f)" % [id, pos["x"], pos["y"]])
```

The tradeoff: maintaining the index has a small cost on every `add` and `remove`. The payoff is faster queries when most entities don't match. At 10,000 entities where only 200 have velocity, the indexed query touches 200 entities, not 10,000.

---

## 3. Archetype-Based Storage: The Concept

Indexed queries are faster than naive loops, but they still scatter data across dictionaries. Cache misses happen constantly. The CPU fetches a position for entity 1, then jumps to a completely different memory location for entity 2's position, and so on. Modern CPUs hate this.

Archetypes solve it. An archetype is a unique signature — a specific combination of component types. Every entity has exactly one archetype. Entities with the same archetype are stored together in contiguous arrays.

```
Archetype A: {Position, Velocity}         → [entity3, entity7, entity11, ...]
Archetype B: {Position, Velocity, Sprite} → [entity1, entity2, entity5, ...]
Archetype C: {Position, Sprite}           → [entity4, entity9, ...]
```

When your MovementSystem queries for `{Position, Velocity}`, the world identifies which archetypes contain both components — Archetype A and Archetype B — and skips Archetype C entirely. Then it iterates over packed arrays. All positions for Archetype A are stored contiguously in memory. All velocities for Archetype A are stored contiguously. The CPU prefetcher can predict the access pattern and load data before the code asks for it. This is why Flecs and Bevy benchmark at hundreds of millions of entity-component operations per second.

Query for `{Position, Velocity}` — touches Archetype A and B.
Query for `{Position}` — touches all three archetypes.
Query for `{Position, Velocity, Sprite}` — touches only Archetype B.

The catch: when you add or remove a component from an entity, it changes archetypes. The entity's data must be moved from the old archetype's arrays to the new archetype's arrays. This is an O(1) operation but with real overhead. Archetype-based ECS discourages frequent component add/remove at runtime. If your game constantly attaches and detaches components as a core pattern, you might prefer indexed queries instead.

You don't need to implement archetypes right now. Understanding the concept tells you why Bevy and Flecs behave the way they do, why adding/removing components has a cost warning in their docs, and how to reason about performance when you eventually need it.

---

## 4. System Ordering: Why Order Matters

Systems run in a defined sequence each frame. The sequence is not automatic — you declare it. Get it wrong and you get one-frame-late bugs: entities rendering at last frame's position, damage resolving before collision is detected, AI acting on stale input.

A typical game frame pipeline looks like this:

```
InputSystem → AISystem → PhysicsSystem → CollisionSystem → DamageSystem → DeathSystem → RenderSystem
```

Here is what goes wrong when order breaks down:

- **RenderSystem before MovementSystem**: entities are drawn at their position from the previous frame. At 60fps this is usually invisible, but it causes input lag and is simply wrong.
- **DamageSystem before CollisionSystem**: no collisions have been resolved yet this frame, so DamageSystem is always working on last frame's collision data. Enemies die a frame late. Fast-moving projectiles can skip through targets.
- **DeathSystem before DamageSystem**: entities that should have died this frame survive until the next frame because death hasn't been processed when damage runs.

**Pseudocode:**
```
-- Declare systems in execution order
world.registerSystem(InputSystem,     priority=1)
world.registerSystem(AISystem,        priority=2)
world.registerSystem(PhysicsSystem,   priority=3)
world.registerSystem(CollisionSystem, priority=4)
world.registerSystem(DamageSystem,    priority=5)
world.registerSystem(DeathSystem,     priority=6)
world.registerSystem(RenderSystem,    priority=7)

-- Each frame:
for each system in order:
    system.update(dt)
```

**Lua (tiny-ecs / Love2D):**
```lua
local tiny = require "tiny"

-- Systems are added to the world in the order they should execute.
-- tiny-ecs processes them in insertion order by default.

local inputSystem     = tiny.processingSystem()
local gravitySystem   = tiny.processingSystem()
local movementSystem  = tiny.processingSystem()
local collisionSystem = tiny.processingSystem()
local renderSystem    = tiny.processingSystem()

inputSystem.filter    = tiny.requireAll("input", "velocity")
movementSystem.filter = tiny.requireAll("position", "velocity")
renderSystem.filter   = tiny.requireAll("position", "sprite")

function gravitySystem:process(entity, dt)
    entity.velocity.vy = entity.velocity.vy + 980 * dt  -- pixels/s²
end
gravitySystem.filter = tiny.requireAll("velocity", "gravity")

function movementSystem:process(entity, dt)
    entity.position.x = entity.position.x + entity.velocity.vx * dt
    entity.position.y = entity.position.y + entity.velocity.vy * dt
end

-- Order is determined by the sequence passed to newWorld
-- Input → Gravity → Movement → Collision → Render
local world = tiny.newWorld(
    inputSystem,
    gravitySystem,
    movementSystem,
    collisionSystem,
    renderSystem
)

function love.update(dt)
    world:update(dt)  -- runs all systems in registered order
end
```

**GDScript (Godot):**
```gdscript
# In Godot, node order in the scene tree determines _process() call order.
# For explicit ECS-style ordering, manage systems manually in a single node.

class_name GameWorld
extends Node

var world: IndexedWorld
var systems: Array = []  # ordered array of callables

func _ready():
    world = IndexedWorld.new()

    # Register systems in execution order — explicit, not magic
    systems = [
        input_system,
        gravity_system,
        movement_system,
        collision_system,
        render_system,
    ]

    _spawn_entities()

func _process(delta: float):
    for system in systems:
        system.call(delta)

func gravity_system(dt: float):
    for id in world.query(["velocity", "gravity"]):
        var vel = world.get_component(id, "velocity")
        vel["vy"] += 980.0 * dt

func movement_system(dt: float):
    for id in world.query(["position", "velocity"]):
        var pos = world.get_component(id, "position")
        var vel = world.get_component(id, "velocity")
        pos["x"] += vel["vx"] * dt
        pos["y"] += vel["vy"] * dt
```

The key insight: system ordering is explicit and yours to own. There is no magic. If you add a new system, you have to think about where it belongs in the pipeline. This is a feature — it makes temporal dependencies visible rather than hidden in callback chains.

---

## Code Walkthrough: Implementing world.query() from Scratch

Let's build this end to end: a complete world with both naive and indexed query implementations, a performance comparison, and two real systems using the query.

```lua
-- world.lua — complete implementation with both query strategies

local World = {}
World.__index = World

function World.new()
    return setmetatable({
        _entities = {},
        _index    = {},
        _nextId   = 1,
    }, World)
end

function World:newEntity()
    local id = self._nextId
    self._nextId = self._nextId + 1
    self._entities[id] = {}
    return id
end

function World:add(id, compType, data)
    self._entities[id][compType] = data
    if not self._index[compType] then
        self._index[compType] = {}
    end
    self._index[compType][id] = true
end

function World:get(id, compType)
    return self._entities[id] and self._entities[id][compType]
end

-- Naive query: scan every entity
function World:queryNaive(...)
    local types = {...}
    local out = {}
    for id, comps in pairs(self._entities) do
        local match = true
        for _, t in ipairs(types) do
            if not comps[t] then match = false; break end
        end
        if match then out[#out + 1] = id end
    end
    return out
end

-- Indexed query: intersect component sets
function World:query(...)
    local types = {...}
    if #types == 0 then return {} end

    local firstIndex = self._index[types[1]]
    if not firstIndex then return {} end

    local candidates = {}
    for id in pairs(firstIndex) do candidates[id] = true end

    for i = 2, #types do
        local idx = self._index[types[i]]
        if not idx then return {} end
        for id in pairs(candidates) do
            if not idx[id] then candidates[id] = nil end
        end
    end

    local out = {}
    for id in pairs(candidates) do out[#out + 1] = id end
    return out
end

return World
```

Now two systems and a complete runnable example:

```lua
-- main.lua (Love2D) or run standalone with luajit

local World = require "world"

-- Systems defined as plain functions that accept world + dt
local function gravitySystem(world, dt)
    for _, id in ipairs(world:query("velocity", "gravity")) do
        local vel = world:get(id, "velocity")
        vel.vy = vel.vy + 980 * dt   -- gravity: 980 px/s²
    end
end

local function movementSystem(world, dt)
    for _, id in ipairs(world:query("position", "velocity")) do
        local pos = world:get(id, "position")
        local vel = world:get(id, "velocity")
        pos.x = pos.x + vel.vx * dt
        pos.y = pos.y + vel.vy * dt
    end
end

-- Setup
local world = World.new()

local function spawnBall(x, y, vx, vy)
    local e = world:newEntity()
    world:add(e, "position", {x=x,   y=y})
    world:add(e, "velocity", {vx=vx, vy=vy})
    world:add(e, "gravity",  {})     -- tag component: no data needed
    return e
end

-- Spawn 5 balls
math.randomseed(42)
for i = 1, 5 do
    spawnBall(
        i * 50,
        100,
        math.random(-100, 100),
        math.random(-50, 50)
    )
end

-- Simulate 3 frames at 60fps
local dt = 1 / 60
for frame = 1, 3 do
    -- Systems run in order: gravity first, then movement
    gravitySystem(world, dt)
    movementSystem(world, dt)

    print(string.format("--- Frame %d ---", frame))
    for _, id in ipairs(world:query("position", "velocity")) do
        local pos = world:get(id, "position")
        local vel = world:get(id, "velocity")
        print(string.format(
            "  entity %d: pos=(%.1f, %.1f)  vel=(%.1f, %.1f)",
            id, pos.x, pos.y, vel.vx, vel.vy
        ))
    end
end
```

Gravity accumulates in `vy` each frame. Movement applies the updated velocity. Because gravity runs before movement, each frame uses the freshly accelerated velocity — correct behavior. If you reversed the order, movement would use last frame's velocity for that frame before gravity updated it.

---

## Concept Quick Reference

| Strategy | Data Structure | Query Cost | Add/Remove Cost | Best For |
|---|---|---|---|---|
| Naive loop | Array of all entities | O(n) | O(1) | < 1000 entities, prototypes |
| Indexed query | Hash sets per component | O(k) results | O(1) index update | Mid-scale games |
| Archetype | Packed arrays per signature | O(k) with cache hits | O(1) but moves data | High-performance, large entity counts |

| Term | Meaning |
|---|---|
| Filter | The set of required component types for a query |
| Intersection | Finding entities present in multiple component sets |
| Archetype | A unique combination of component types |
| System pipeline | The ordered sequence of systems per frame |
| One-frame-late bug | A system operating on stale data from the previous frame |

---

## Common Pitfalls

**Modifying the entity list while iterating it.** If your DeathSystem destroys entities inside the query loop, you may skip or double-process entries. Collect entities to destroy in a list, then destroy them after the loop completes.

**Querying too broadly.** A system that queries for just `{position}` to update a single thing is checking far more entities than necessary. Always specify the minimal set of components that uniquely identifies what a system needs.

**System order drift.** You add a new system and append it to the list without thinking. Two months later you have a subtle collision bug because your new BounceSystem runs after RenderSystem. Treat system order as load-bearing architecture. Document it.

**Assuming index removal is automatic.** In the implementation above, removing a component requires calling `world:remove(id, compType)`. If you forget and just nil out the component data directly, the index stays stale. Stale indexes return dead entities in queries. Add assertions in debug builds.

**Holding references instead of re-querying.** Caching the result of `world:query(...)` across frames is tempting. It's also wrong if any entity gains or loses those components between frames. Re-query each frame or build explicit dirty tracking.

---

## Exercises

1. **Extend the indexed world** to support a `world:destroyEntity(id)` function. It should remove the entity from every component index and the entity table. Test that destroyed entities no longer appear in queries.

2. **Add a tag component system.** Tags are components with no data — just presence or absence. The `gravity` component in the walkthrough is a tag. Add a `frozen` tag that, when present, causes the movement system to skip that entity. Implement it using the indexed query so the check is free.

3. **Benchmark naive vs indexed.** Spawn 5000 entities. Give half of them `velocity`. Measure how long 1000 consecutive `world:query("position", "velocity")` calls take with the naive loop versus the indexed approach. Print the results.

4. **System ordering experiment.** In the walkthrough code, swap gravitySystem and movementSystem so movement runs before gravity. Run 10 frames. Compare the final positions to the original order. Document the difference and explain why it happens.

5. **Build a minimal archetype tracker** (concept exercise, not full implementation). Given a series of add/remove operations, track which archetype each entity belongs to. Print the archetype table after each operation. You don't need to store component data by archetype — just track signatures.

---

## Key Takeaways

- The naive loop (check every entity every frame) is O(n) per system but perfectly acceptable for small entity counts. tiny-ecs uses this approach and handles thousands of entities without issue.
- Indexed queries maintain per-component hash sets. Querying intersects those sets. Result collection is O(k) where k is the number of matching entities, regardless of total entity count.
- Archetype storage groups entities by component signature in contiguous memory, enabling cache-friendly linear scans. Bevy and Flecs use this. Component add/remove is more expensive because it moves entity data between archetype tables.
- System ordering is explicit and yours to own. Declare the pipeline deliberately. Wrong order produces one-frame-late bugs.
- When removing entities or components mid-loop, collect then destroy — never modify the collection you're iterating.

---

## What's Next

[Module 3: Events, Communication & System Ordering](module-03-events-communication-system-ordering.md) — now that systems can efficiently find entities, learn how decoupled systems communicate: event queues, deferred commands, and why system ordering goes beyond registration order.

Back to [ECS Learning Roadmap](ecs-learning-roadmap.md)
