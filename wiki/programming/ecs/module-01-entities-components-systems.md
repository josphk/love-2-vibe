# Module 1: Entities, Components, Systems

**Part of:** [ECS Learning Roadmap](ecs-learning-roadmap.md)
**Estimated study time:** 2–4 hours
**Prerequisites:** [Module 0: Why Not Just OOP?](module-00-why-not-just-oop.md)

---

## Overview

Module 0 made the case that inheritance hierarchies become a liability as your game grows. ECS is the alternative — but it's not just a different way to organize the same ideas. It's a fundamentally different mental model. In OOP, a "player" is an object that knows how to move, draw itself, take damage, and play sounds. In ECS, a "player" is just an ID number that happens to have a Position, a Velocity, a Health, and a Sprite attached to it. The player doesn't *do* anything. Systems do things *to* it.

The three parts of ECS are not complex individually. An **entity** is a number. A **component** is a bag of data with no methods. A **system** is a function that loops over entities matching certain components. The complexity people run into isn't understanding the parts — it's internalizing *why* you strip methods off data and move all logic into systems. This module walks through each part carefully, shows you how they connect, and then builds a minimal working ECS from scratch so you can see the machinery directly.

By the end of this module you'll be able to hand-roll a functional ECS in Lua without a library, translate the same structure to GDScript, and reason about what belongs in a component versus what belongs in a system. That foundation makes every library (tiny-ecs, Bevy, Flecs, etc.) immediately legible, because they're all solving the same underlying problem.

---

## 1. Entities as IDs: The Spreadsheet Mental Model

Forget objects for a moment. Imagine a spreadsheet. Rows are entities. Columns are component types. A cell contains data if that entity has that component; the cell is empty if it doesn't.

```
Entity  | Position      | Velocity    | Health | Sprite       | PlayerInput
--------|---------------|-------------|--------|--------------|------------
1       | {x=100,y=200} | {vx=0,vy=0} | {hp=3} | "player.png" | {}
2       | {x=400,y=150} | {vx=-2,vy=0}| {hp=1} | "enemy.png"  |
3       | {x=105,y=210} | {vx=5,vy=-3}|        | "bullet.png" |
4       |               |             |        | "hud.png"    |
```

Entity 1 is the player: it has Position, Velocity, Health, Sprite, and PlayerInput (the flag that says "this entity is controlled by the player"). Entity 2 is an enemy: same columns except no PlayerInput. Entity 3 is a bullet: it has Position and Velocity but no Health (bullets don't take damage). Entity 4 is the HUD sprite: no Position in world space, no Velocity, no Health — just a Sprite.

Notice what the entity itself is: nothing. It's just the row number. Entity 1 is not a class. It has no constructor, no methods, no identity beyond being a key that lets you look up which cells in which columns have data.

**Pseudocode:**
```
entity = world.createEntity()         // returns an integer ID, e.g. 42
world.addComponent(entity, Position, {x=0, y=0})
world.addComponent(entity, Velocity, {vx=1, vy=0})
// entity 42 now "has" Position and Velocity
// entity 42 itself is still just the number 42
```

**Lua (tiny-ecs / Love2D):**
```lua
local tiny = require "tiny"

local world = tiny.world()

-- An entity in tiny-ecs is just a plain table.
-- tiny-ecs uses the table itself as the ID (Lua tables are references).
local player = {
  position = { x = 100, y = 200 },
  velocity = { vx = 0, vy = 0 },
  health   = { hp = 3 },
  sprite   = "player.png",
  playerInput = true,   -- flag component: presence is the signal
}

world:addEntity(player)

-- An entity with fewer components:
local bullet = {
  position = { x = 105, y = 210 },
  velocity = { vx = 5, vy = -3 },
  sprite   = "bullet.png",
  -- no health, no playerInput
}

world:addEntity(bullet)
```

**GDScript (Godot):**
```gdscript
# In a hand-rolled or library-based ECS in Godot,
# entities are typically integer IDs managed by a World singleton.

var world := ECSWorld.new()

var player_id: int = world.create_entity()
world.add_component(player_id, "position", {"x": 100.0, "y": 200.0})
world.add_component(player_id, "velocity", {"vx": 0.0, "vy": 0.0})
world.add_component(player_id, "health",   {"hp": 3})
world.add_component(player_id, "sprite",   {"path": "player.png"})
world.add_component(player_id, "player_input", {})  # flag component

var bullet_id: int = world.create_entity()
world.add_component(bullet_id, "position", {"x": 105.0, "y": 210.0})
world.add_component(bullet_id, "velocity", {"vx": 5.0, "vy": -3.0})
world.add_component(bullet_id, "sprite",   {"path": "bullet.png"})
# No health component — bullets don't take damage.
```

The key insight: **entity identity is defined entirely by which components it has, not by what class it is.** There is no `Bullet` class. There is no `Player` class. There's just an entity that happens to have (or not have) certain data attached to it. This is what lets you compose behaviors freely — want an enemy that also responds to player input? Add the PlayerInput component. Want the player to temporarily become invincible? Remove the Health component (or add an Invincible flag). No inheritance needed.

---

## 2. Components as Pure Data: No Methods Allowed

A component is a struct — a plain container for data fields. No methods. No behavior. No references to other components. Just data.

This is the rule that feels most wrong coming from OOP. In OOP, you'd give your `Position` class a `distanceTo(other)` method, a `normalize()` method, a `translate(dx, dy)` method. In ECS, you don't. Position is:

```lua
{ x = 0, y = 0 }
```

That's it. The logic that *uses* position lives in systems. Here's a set of typical components:

**Pseudocode:**
```
Position  { x, y }
Velocity  { vx, vy }
Health    { hp, maxHp }
Sprite    { path, width, height, scaleX, scaleY }
PlayerInput  {}                      // flag — no data needed
Damage    { amount }
Collider  { radius }                 // circle collider
Lifetime  { remaining }              // seconds until this entity dies
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Components are just tables. Define them wherever makes sense.
-- Convention: a function that returns a fresh component table.

local function Position(x, y)
  return { x = x or 0, y = y or 0 }
end

local function Velocity(vx, vy)
  return { vx = vx or 0, vy = vy or 0 }
end

local function Health(hp)
  return { hp = hp, maxHp = hp }
end

local function Sprite(path, w, h)
  return { path = path, width = w, height = h, scaleX = 1, scaleY = 1 }
end

local function Damage(amount)
  return { amount = amount }
end

local function Lifetime(seconds)
  return { remaining = seconds }
end

-- PlayerInput has no data — its presence on an entity is the signal.
local function PlayerInput()
  return {}
end

-- Usage:
local bullet = {
  position = Position(100, 200),
  velocity = Velocity(0, -10),
  sprite   = Sprite("bullet.png", 4, 8),
  damage   = Damage(1),
  lifetime = Lifetime(3.0),
}
```

**GDScript (Godot):**
```gdscript
# Option 1: inner classes (more structured, autocompletion)
class Position:
    var x: float
    var y: float
    func _init(px: float = 0.0, py: float = 0.0):
        x = px
        y = py

class Velocity:
    var vx: float
    var vy: float
    func _init(pvx: float = 0.0, pvy: float = 0.0):
        vx = pvx
        vy = pvy

class Health:
    var hp: int
    var max_hp: int
    func _init(h: int):
        hp = h
        max_hp = h

class Damage:
    var amount: int
    func _init(a: int):
        amount = a

class Lifetime:
    var remaining: float
    func _init(seconds: float):
        remaining = seconds

# Option 2: plain Dictionaries (less structured, but simpler to start)
var pos_component  = {"x": 100.0, "y": 200.0}
var vel_component  = {"vx": 0.0, "vy": -10.0}
var dmg_component  = {"amount": 1}
var life_component = {"remaining": 3.0}

# Either approach works. The rule is the same:
# NO methods. NO logic. Just data.
```

Why no methods on components? Two reasons. First, if components have methods, you end up with distributed logic — some behavior lives in the component, some in the system, and you're debugging both. Second, components need to be simple enough that the World can store, copy, serialize, and inspect them without knowing what they are. A bag of plain data is trivially serializable, network-syncable, and inspectable. An object with embedded logic is not.

The moment you're tempted to add a method to a component, ask: "which system should own this logic?" That's where it belongs.

---

## 3. Systems as Query + Loop + Logic

A system is a function — usually called once per frame — that:
1. Queries the world for all entities matching a component signature
2. Loops over those entities
3. Applies some logic using their component data

That's the entire pattern. Every system follows this structure. Here are three systems that cover most of a basic game:

**Pseudocode:**
```
MovementSystem:
  query: entities with [Position, Velocity]
  for each entity:
    position.x += velocity.vx * dt
    position.y += velocity.vy * dt

RenderSystem:
  query: entities with [Position, Sprite]
  for each entity:
    draw(sprite.path, position.x, position.y)

HealthSystem:
  query: entities with [Health]
  for each entity:
    if health.hp <= 0:
      world.destroyEntity(entity)
```

**Lua (tiny-ecs / Love2D):**
```lua
local tiny = require "tiny"

-- MovementSystem
local MovementSystem = tiny.processingSystem()
MovementSystem.filter = tiny.requireAll("position", "velocity")

function MovementSystem:process(entity, dt)
  entity.position.x = entity.position.x + entity.velocity.vx * dt
  entity.position.y = entity.position.y + entity.velocity.vy * dt
end

-- RenderSystem
local RenderSystem = tiny.processingSystem()
RenderSystem.filter = tiny.requireAll("position", "sprite")

function RenderSystem:process(entity, dt)
  -- In real Love2D you'd use love.graphics.draw with an Image object.
  -- This shows the structure:
  love.graphics.print(
    entity.sprite.path .. " @ " ..
    entity.position.x .. "," .. entity.position.y,
    entity.position.x, entity.position.y
  )
end

-- HealthSystem: removes dead entities
local HealthSystem = tiny.processingSystem()
HealthSystem.filter = tiny.requireAll("health")

function HealthSystem:process(entity, dt)
  if entity.health.hp <= 0 then
    self.world:removeEntity(entity)
  end
end

-- LifetimeSystem: entities that expire
local LifetimeSystem = tiny.processingSystem()
LifetimeSystem.filter = tiny.requireAll("lifetime")

function LifetimeSystem:process(entity, dt)
  entity.lifetime.remaining = entity.lifetime.remaining - dt
  if entity.lifetime.remaining <= 0 then
    self.world:removeEntity(entity)
  end
end
```

**GDScript (Godot):**
```gdscript
# Systems in GDScript are typically autoloads or nodes with _process().
# They hold a reference to the ECS World.

class_name MovementSystem

var world: ECSWorld

func update(delta: float) -> void:
    var entities = world.query(["position", "velocity"])
    for entity_id in entities:
        var pos = world.get_component(entity_id, "position")
        var vel = world.get_component(entity_id, "velocity")
        pos["x"] += vel["vx"] * delta
        pos["y"] += vel["vy"] * delta

# ---

class_name HealthSystem

var world: ECSWorld

func update(_delta: float) -> void:
    var entities = world.query(["health"])
    var to_destroy := []
    for entity_id in entities:
        var health = world.get_component(entity_id, "health")
        if health["hp"] <= 0:
            to_destroy.append(entity_id)
    # Destroy after iteration — never modify a collection mid-loop.
    for entity_id in to_destroy:
        world.destroy_entity(entity_id)

# ---

class_name LifetimeSystem

var world: ECSWorld

func update(delta: float) -> void:
    var entities = world.query(["lifetime"])
    var to_destroy := []
    for entity_id in entities:
        var life = world.get_component(entity_id, "lifetime")
        life["remaining"] -= delta
        if life["remaining"] <= 0.0:
            to_destroy.append(entity_id)
    for entity_id in to_destroy:
        world.destroy_entity(entity_id)
```

**Each system owns one responsibility.** This is the ECS equivalent of the Single Responsibility Principle, but with teeth — because systems are physically separate functions, the boundary is enforced structurally. MovementSystem doesn't know rendering exists. RenderSystem doesn't know about health. They compose by both operating on the same entity data independently.

Systems also don't call each other. They share data through components. If DamageSystem wants to tell HealthSystem that an entity took 3 damage, it doesn't call `healthSystem.applyDamage(entity, 3)`. It modifies `entity.health.hp` directly (or better, adds a `PendingDamage` component that HealthSystem reads next frame).

---

## 4. The World Container

The World is the database. It owns all entities and all component data. Systems are the queries that run against it. You never create entities directly — you ask the World to create them. You never store component data yourself — you give it to the World.

A minimal World API looks like this:

**Pseudocode:**
```
World:
  createEntity()              → entityId
  destroyEntity(entityId)
  addComponent(entityId, compType, data)
  removeComponent(entityId, compType)
  getComponent(entityId, compType) → data or nil
  query(compTypes...)         → [entityId, ...]
  update(dt)                  → run all systems
```

**Lua (hand-rolled, no library):**
```lua
local World = {}
World.__index = World

function World.new()
  return setmetatable({
    _entities = {},   -- [entityId] = { [compType] = data }
    _nextId   = 1,
    _systems  = {},
  }, World)
end

function World:newEntity()
  local id = self._nextId
  self._nextId = self._nextId + 1
  self._entities[id] = {}
  return id
end

function World:destroyEntity(id)
  self._entities[id] = nil
end

function World:add(id, compType, data)
  if self._entities[id] then
    self._entities[id][compType] = data
  end
end

function World:remove(id, compType)
  if self._entities[id] then
    self._entities[id][compType] = nil
  end
end

function World:get(id, compType)
  return self._entities[id] and self._entities[id][compType]
end

function World:query(...)
  local required = {...}
  local results = {}
  for id, comps in pairs(self._entities) do
    local match = true
    for _, t in ipairs(required) do
      if not comps[t] then
        match = false
        break
      end
    end
    if match then
      results[#results + 1] = id
    end
  end
  return results
end

function World:addSystem(system)
  self._systems[#self._systems + 1] = system
  system.world = self
end

function World:update(dt)
  for _, system in ipairs(self._systems) do
    system:update(dt)
  end
end
```

**GDScript (Godot):**
```gdscript
class_name ECSWorld

var _entities: Dictionary = {}  # {int -> {String -> Dictionary}}
var _next_id: int = 1
var _systems: Array = []

func create_entity() -> int:
    var id := _next_id
    _next_id += 1
    _entities[id] = {}
    return id

func destroy_entity(id: int) -> void:
    _entities.erase(id)

func add_component(id: int, comp_type: String, data: Dictionary) -> void:
    if _entities.has(id):
        _entities[id][comp_type] = data

func remove_component(id: int, comp_type: String) -> void:
    if _entities.has(id):
        _entities[id].erase(comp_type)

func get_component(id: int, comp_type: String):
    if _entities.has(id):
        return _entities[id].get(comp_type, null)
    return null

func query(comp_types: Array) -> Array:
    var results := []
    for id in _entities:
        var comps: Dictionary = _entities[id]
        var match := true
        for t in comp_types:
            if not comps.has(t):
                match = false
                break
        if match:
            results.append(id)
    return results

func add_system(system) -> void:
    system.world = self
    _systems.append(system)

func update(delta: float) -> void:
    for system in _systems:
        system.update(delta)
```

The World is intentionally dumb. It's a data store with a query interface. It doesn't know what components mean. It doesn't know what systems do. It just holds data and hands it out when asked. This separation is what makes ECS composable — you can add a new component type and a new system without touching any existing code.

---

## Code Walkthrough: Hand-Rolling a Minimal ECS from Scratch

Here's a complete, runnable Lua program — no libraries, no Love2D — that demonstrates ECS with two entities, a MovementSystem, a GravitySystem, and three "frames" of simulation printed to the console.

```lua
-- ecs_demo.lua
-- Run with: lua ecs_demo.lua

--------------------------------------------------------------------------------
-- World
--------------------------------------------------------------------------------
local World = {}
World.__index = World

function World.new()
  return setmetatable({ _entities = {}, _nextId = 1, _systems = {} }, World)
end

function World:newEntity()
  local id = self._nextId
  self._nextId = self._nextId + 1
  self._entities[id] = {}
  return id
end

function World:add(id, compType, data)
  self._entities[id][compType] = data
end

function World:get(id, compType)
  return self._entities[id] and self._entities[id][compType]
end

function World:query(...)
  local required, results = {...}, {}
  for id, comps in pairs(self._entities) do
    local ok = true
    for _, t in ipairs(required) do
      if not comps[t] then ok = false; break end
    end
    if ok then results[#results + 1] = id end
  end
  return results
end

function World:addSystem(sys)
  sys.world = self
  self._systems[#self._systems + 1] = sys
end

function World:update(dt)
  for _, sys in ipairs(self._systems) do sys:update(dt) end
end

--------------------------------------------------------------------------------
-- Systems
--------------------------------------------------------------------------------
local GravitySystem = {}
GravitySystem.__index = GravitySystem

function GravitySystem:update(dt)
  for _, id in ipairs(self.world:query("velocity")) do
    local vel = self.world:get(id, "velocity")
    vel.vy = vel.vy + 200 * dt   -- 200 px/s^2 downward gravity
  end
end

local MovementSystem = {}
MovementSystem.__index = MovementSystem

function MovementSystem:update(dt)
  for _, id in ipairs(self.world:query("position", "velocity")) do
    local pos = self.world:get(id, "position")
    local vel = self.world:get(id, "velocity")
    pos.x = pos.x + vel.vx * dt
    pos.y = pos.y + vel.vy * dt
  end
end

local PrintSystem = {}
PrintSystem.__index = PrintSystem

function PrintSystem:update(dt)
  for _, id in ipairs(self.world:query("position")) do
    local pos  = self.world:get(id, "position")
    local name = self.world:get(id, "name")
    local tag  = name and name.value or ("entity_" .. id)
    print(string.format("  %s: x=%.1f  y=%.1f", tag, pos.x, pos.y))
  end
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------
local world = World.new()

world:addSystem(setmetatable({}, GravitySystem))
world:addSystem(setmetatable({}, MovementSystem))
world:addSystem(setmetatable({}, PrintSystem))

local player = world:newEntity()
world:add(player, "position", { x = 0,   y = 0 })
world:add(player, "velocity", { vx = 50, vy = 0 })
world:add(player, "name",     { value = "player" })

local rock = world:newEntity()
world:add(rock, "position", { x = 200, y = 50 })
world:add(rock, "velocity", { vx = -10, vy = 0 })
world:add(rock, "name",     { value = "rock" })

-- HUD has position but no velocity — gravity and movement ignore it.
local hud = world:newEntity()
world:add(hud, "position", { x = 0, y = 0 })
world:add(hud, "name",     { value = "hud" })

--------------------------------------------------------------------------------
-- "Game loop" — three frames at 60fps
--------------------------------------------------------------------------------
local dt = 1 / 60

for frame = 1, 3 do
  print("--- Frame " .. frame .. " ---")
  world:update(dt)
end

--[[
Output (approximately):
--- Frame 1 ---
  player: x=0.8  y=0.1
  rock:   x=199.8  y=0.1
  hud:    x=0.0  y=0.0
--- Frame 2 ---
  player: x=1.7  y=0.3
  rock:   x=199.6  y=0.3
  hud:    x=0.0  y=0.0
--- Frame 3 ---
  player: x=2.5  y=0.6
  rock:   x=199.4  y=0.6
  hud:    x=0.0  y=0.0
]]--
```

Notice that `hud` is completely unaffected by GravitySystem and MovementSystem — it has no `velocity` component, so those systems' queries skip it. That's the power of the component-as-filter model. You don't write `if entity.isHUD then return end`. You just don't give it the components that trigger those systems.

Now the same logic in tiny-ecs for comparison:

```lua
-- tiny-ecs version (more idiomatic for Love2D projects)
local tiny = require "tiny"

local GravitySystem = tiny.processingSystem()
GravitySystem.filter = tiny.requireAll("velocity")
function GravitySystem:process(e, dt)
  e.velocity.vy = e.velocity.vy + 200 * dt
end

local MovementSystem = tiny.processingSystem()
MovementSystem.filter = tiny.requireAll("position", "velocity")
function MovementSystem:process(e, dt)
  e.position.x = e.position.x + e.velocity.vx * dt
  e.position.y = e.position.y + e.velocity.vy * dt
end

local world = tiny.world(GravitySystem, MovementSystem)

local player = { position = {x=0, y=0}, velocity = {vx=50, vy=0}, name = "player" }
local hud    = { position = {x=0, y=0}, name = "hud" }

world:addEntity(player)
world:addEntity(hud)

for frame = 1, 3 do
  world:update(1/60)
  print(string.format("Frame %d | player: %.1f, %.1f", frame, player.position.x, player.position.y))
end
```

tiny-ecs uses the entity table itself as the ID (Lua tables are references, so they work as unique keys). The filter system is the main difference — tiny-ecs compiles filters to bitsets for performance. Your hand-rolled version uses the same logic, just with a linear scan.

---

## Concept Quick Reference

| Term | What it is | What it is NOT |
|---|---|---|
| Entity | An integer ID / unique key | An object with behavior |
| Component | A plain data table/struct | A class with methods |
| System | A function: query + loop + logic | A manager or controller object |
| World | The database of entities + components | A God object that knows everything |
| Filter / Query | "Give me all entities with Position AND Velocity" | A search through class hierarchies |

---

## Common Pitfalls

**Putting logic in components.** The instant you write `function Position:moveTo(x, y)`, you've broken the model. Now logic is split between the component and the system, and you'll spend time deciding which one to change. Move it to a system.

**Making systems that know about other systems.** Systems communicate through components, not through direct calls. If CollisionSystem needs to tell DamageSystem that a hit occurred, it writes a `Hit { damage=3, target=entityId }` component onto an entity. DamageSystem reads it next frame. This keeps systems decoupled and makes the data flow visible and debuggable.

**Destroying entities mid-iteration.** If you call `world:destroyEntity(id)` inside the loop that `world:query()` is iterating, you'll corrupt the iteration. Collect IDs to destroy in a list, then destroy them after the loop finishes.

**One giant system.** If you find yourself writing a system that queries eight component types and has 200 lines of logic, split it. The right system size is "one responsibility" — usually 10–40 lines of process logic.

**Forgetting that query order matters.** If GravitySystem runs after MovementSystem in the same frame, gravity applies one frame late. Think about your system execution order explicitly. Most ECS libraries let you specify priority or ordering.

**Using components as message queues without cleaning up.** If you add a `PendingDamage` component to communicate between systems, make sure a system removes it after it's been processed. Otherwise entities accumulate stale data.

---

## Exercises

**Exercise 1 — Paper design (no code required)**

Design a space shooter using components. For each entity type listed below, write out which components it has:

- Player ship
- Enemy ship
- Player bullet
- Enemy bullet
- Explosion (visual effect only, no collision)
- Score HUD element
- Shield power-up

Then write pseudocode for three systems: MovementSystem, CollisionSystem (how does it detect hits? what components does it need?), and RenderSystem. Pay attention to which systems each entity type participates in.

**Exercise 2 — Implement and extend the hand-rolled ECS**

Copy the hand-rolled Lua ECS from the walkthrough above and run it with `lua ecs_demo.lua`. Then:

1. Add a GravitySystem (if you haven't already) that increases `velocity.vy` by 9.8 * dt each frame.
2. Add a `lifetime` component to bullets: `{ remaining = 3.0 }`.
3. Add a LifetimeSystem that decrements `remaining` each frame and removes the entity when it hits zero. (For the hand-rolled version, set `world._entities[id] = nil` directly, or add a `destroy` method.)
4. Run 300 "frames" at dt=1/60 and print entity positions every 60 frames.

You do not need Love2D for this. Plain `lua script.lua` is sufficient.

**Exercise 3 — Stretch: component removal and entity lifecycle**

Add a `World:remove(entityId, compType)` method to your hand-rolled ECS. Then:

1. Create an entity with Position, Velocity, and Health.
2. After 5 frames, remove the Health component. Verify that HealthSystem (if you wrote one) no longer processes it.
3. After 10 frames, remove Position and Velocity. What does `world:query("position", "velocity")` return for that entity? What does `world:query()` (no arguments — all entities) return?
4. Think about: should an entity with no components still exist in the World? What are the tradeoffs of cleaning it up automatically versus leaving it?

---

## Key Takeaways

- An entity is just an ID — a number that lets you look up which components it has. It has no behavior, no data of its own.
- Components are pure data structs with no methods. Logic belongs in systems, not in components.
- A system is a query, a loop, and some logic. It processes all entities matching its component filter, nothing else.
- The World is the database. Systems are the queries. You never store entity data outside the World.
- Entities opt into system behavior by having the right components. Remove a component, and the entity is invisible to systems that filter for it — no conditionals needed.

---

## What's Next

[Module 2: Querying and Iteration](module-02-querying-and-iteration.md) — now that you have the triad, learn how systems efficiently find the entities they care about: filter queries, indexed lookups, and archetype storage concepts.

Back to [ECS Learning Roadmap](ecs-learning-roadmap.md)
