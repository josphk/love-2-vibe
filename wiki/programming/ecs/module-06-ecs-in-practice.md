# Module 6: ECS in Practice

**Part of:** [ECS Learning Roadmap](ecs-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** [Module 5: Data-Oriented Design & Performance](module-05-data-oriented-design-performance.md)

---

## Overview

You've learned the theory — entities as IDs, components as data, systems as logic, events for communication, data layout for performance. Now it's time to see how real frameworks implement these ideas in code you can actually run. This module is a survey: tiny-ecs, Concord, Flecs, and Bevy ECS, followed by a clear-eyed look at when Godot's node model is the better choice, and when ECS is not worth using at all.

No two frameworks make identical tradeoffs. tiny-ecs is ~500 lines of Lua and fits in your head. Concord adds lifecycle hooks and assemblages (prefab bundles) for larger projects. Flecs is a production C library with relationships, query caching, and a REST debugging API. Bevy ECS is Rust — you may never ship Rust, but reading its system signatures will crystallize how archetype queries actually feel to write. Each section ends with a clear-eyed list of what the library does well and where it runs out of road.

The most important section is "When NOT to use ECS." ECS is a tool, not a religion. A jam game, a small project, a game where the scene tree maps perfectly to the design — these do not benefit from ECS overhead. Knowing when to reach for something else is as important as knowing how ECS works.

---

## 1. tiny-ecs Overview

tiny-ecs is a filter-based ECS library for Lua, written by Bakpakin, weighing in at roughly 500 lines. That size is a feature. You can read the entire source in an afternoon. Many ECS concepts that feel abstract become obvious after reading the source — do it before you finish this module.

The API is minimal: systems define a `filter`, an `update` or `process` callback, and optionally a `draw` callback. The world routes entities to systems based on filter matches. Adding or removing components requires re-registering the entity so tiny-ecs can re-evaluate which systems should receive it.

**Pseudocode:**
```
// tiny-ecs mental model
world = new World

system.filter = requireAll("position", "velocity")
system.process = function(entity, dt):
    entity.position.x += entity.velocity.vx * dt
    entity.position.y += entity.velocity.vy * dt

world.addSystem(system)

entity = { position={x=100, y=200}, velocity={vx=50, vy=0} }
world.addEntity(entity)

// Each frame:
world.update(dt)   // routes entities to matching system callbacks
world.draw()       // routes entities to draw callbacks
```

**Lua (tiny-ecs / Love2D):**
```lua
-- main.lua — complete tiny-ecs setup with MovementSystem and DrawSystem
local tiny = require "tiny"

local world

-- ----------------------------------------------------------------
-- Systems
-- ----------------------------------------------------------------

-- MovementSystem: processes all entities that have position AND velocity
local movementSystem = tiny.processingSystem()
movementSystem.filter = tiny.requireAll("position", "velocity")

function movementSystem:process(entity, dt)
    entity.position.x = entity.position.x + entity.velocity.vx * dt
    entity.position.y = entity.position.y + entity.velocity.vy * dt

    -- Wrap around screen edges
    local W, H = love.graphics.getDimensions()
    if entity.position.x > W then entity.position.x = 0 end
    if entity.position.x < 0  then entity.position.x = W end
    if entity.position.y > H  then entity.position.y = 0 end
    if entity.position.y < 0  then entity.position.y = H end
end

-- DrawSystem: processes entities with position AND color (skips pure-logic entities)
local drawSystem = tiny.processingSystem()
drawSystem.filter = tiny.requireAll("position", "color")

function drawSystem:process(entity, dt)
    love.graphics.setColor(entity.color)
    local size = entity.size or 8
    love.graphics.rectangle("fill",
        entity.position.x - size/2,
        entity.position.y - size/2,
        size, size)
end

-- ----------------------------------------------------------------
-- Entity prefabs
-- ----------------------------------------------------------------

local function spawnDot(x, y, vx, vy, color)
    return {
        position = { x = x, y = y },
        velocity = { vx = vx, vy = vy },
        color    = color or { 1, 1, 1, 1 },
        size     = 6,
    }
end

-- ----------------------------------------------------------------
-- Love2D lifecycle
-- ----------------------------------------------------------------

function love.load()
    world = tiny.world(movementSystem, drawSystem)

    -- Spawn 5 bouncing dots
    for i = 1, 5 do
        local e = spawnDot(
            math.random(100, 700),
            math.random(100, 500),
            math.random(-120, 120),
            math.random(-120, 120),
            { math.random(), math.random(), math.random(), 1 }
        )
        world:addEntity(e)
    end
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    world:draw()
end
```

**GDScript (Godot):**
```gdscript
# tiny-ecs doesn't have a direct GDScript equivalent,
# but here's the same concept expressed as a manual ECS manager node.
# See Section 5 for the full Godot hybrid approach.

extends Node

var entities: Array[Dictionary] = []

func spawn_dot(x: float, y: float, vx: float, vy: float, color: Color) -> void:
    entities.append({
        "position": Vector2(x, y),
        "velocity": Vector2(vx, vy),
        "color": color,
        "size": 6.0,
    })

func movement_system(dt: float) -> void:
    var size := Vector2(get_viewport().get_visible_rect().size)
    for e in entities:
        if not (e.has("position") and e.has("velocity")):
            continue
        e["position"] += e["velocity"] * dt
        # Wrap
        if e["position"].x > size.x: e["position"].x = 0
        if e["position"].x < 0:      e["position"].x = size.x
        if e["position"].y > size.y: e["position"].y = 0
        if e["position"].y < 0:      e["position"].y = size.y

func _process(delta: float) -> void:
    movement_system(delta)
    queue_redraw()

func _draw() -> void:
    for e in entities:
        if e.has("position") and e.has("color"):
            draw_rect(Rect2(e["position"] - Vector2.ONE * 3, Vector2.ONE * 6), e["color"])
```

**tiny-ecs strengths:**
- Minimal surface area — the whole library fits in your head
- Zero configuration — add systems, add entities, call `world:update(dt)`
- Great for prototypes, jam games, and anything under ~3,000 entities
- The source code is the documentation

**tiny-ecs weaknesses:**
- Filter checks are O(n) per entity on add/remove — no archetype acceleration
- No built-in event system — you wire events yourself
- No lifecycle hooks for system init or teardown
- Doesn't scale gracefully past ~5,000–10,000 entities depending on system count

---

## 2. Concord Overview

Concord is a more structured Lua ECS for Love2D, created by Tjakka5. Where tiny-ecs asks "what's the minimum?" Concord asks "what structure prevents large projects from collapsing?" It adds formal Component definitions, a System class with lifecycle hooks, and assemblages — named bundles of components that work exactly like prefabs.

The World object runs the show: `World:addEntity()`, `World:removeEntity()`, `World:addSystem()`. The event system (`World:emit()`, and `System:onXxx()` callbacks) is first-class. You subscribe to events by defining named callbacks directly on your system.

**Pseudocode:**
```
// Concord: components are defined objects, not loose tables

Component Position { x, y }
Component Velocity { vx, vy }

// Systems declare which components they process
MovementSystem extends System
    filter = { Position, Velocity }
    update(dt):
        for each entity in self.entities:
            p = entity:get(Position)
            v = entity:get(Velocity)
            p.x += v.vx * dt
            p.y += v.vy * dt

// Assemblages bundle components with defaults (prefab equivalent)
Assemblage DotAssemblage
    apply(entity, x, y, vx, vy):
        entity:give(Position, x, y)
        entity:give(Velocity, vx, vy)
        entity:give(Color, 1, 1, 1, 1)

// Usage
world:addSystem(MovementSystem)
entity = world:addEntity()
DotAssemblage:apply(entity, 100, 200, 50, -30)
```

**Lua (tiny-ecs / Concord — Love2D):**
```lua
-- Same dot demo rebuilt in Concord
-- File structure: components/, systems/, assemblages/, main.lua

-- ----------------------------------------------------------------
-- components/Position.lua
-- ----------------------------------------------------------------
local Concord = require "concord"
return Concord.component(function(c, x, y)
    c.x = x or 0  -- default values given here
    c.y = y or 0
end)

-- ----------------------------------------------------------------
-- components/Velocity.lua
-- ----------------------------------------------------------------
local Concord = require "concord"
return Concord.component(function(c, vx, vy)
    c.vx = vx or 0
    c.vy = vy or 0
end)

-- ----------------------------------------------------------------
-- components/DrawColor.lua
-- ----------------------------------------------------------------
local Concord = require "concord"
return Concord.component(function(c, r, g, b, a)
    c.r = r or 1; c.g = g or 1; c.b = b or 1; c.a = a or 1
end)

-- ----------------------------------------------------------------
-- systems/MovementSystem.lua
-- ----------------------------------------------------------------
local Concord  = require "concord"
local Position = require "components.Position"
local Velocity = require "components.Velocity"

local MovementSystem = Concord.system({ pool = { Position, Velocity } })

function MovementSystem:update(dt)
    local W, H = love.graphics.getDimensions()
    for _, entity in ipairs(self.pool) do
        local p = entity[Position]
        local v = entity[Velocity]
        p.x = p.x + v.vx * dt
        p.y = p.y + v.vy * dt
        if p.x > W then p.x = 0 end
        if p.x < 0  then p.x = W end
        if p.y > H  then p.y = 0 end
        if p.y < 0  then p.y = H end
    end
end

return MovementSystem

-- ----------------------------------------------------------------
-- systems/DrawSystem.lua
-- ----------------------------------------------------------------
local Concord   = require "concord"
local Position  = require "components.Position"
local DrawColor = require "components.DrawColor"

local DrawSystem = Concord.system({ pool = { Position, DrawColor } })

function DrawSystem:draw()
    for _, entity in ipairs(self.pool) do
        local p = entity[Position]
        local c = entity[DrawColor]
        love.graphics.setColor(c.r, c.g, c.b, c.a)
        love.graphics.rectangle("fill", p.x - 3, p.y - 3, 6, 6)
    end
end

return DrawSystem

-- ----------------------------------------------------------------
-- assemblages/DotAssemblage.lua
-- ----------------------------------------------------------------
local Concord   = require "concord"
local Position  = require "components.Position"
local Velocity  = require "components.Velocity"
local DrawColor = require "components.DrawColor"

local DotAssemblage = Concord.assemblage()

-- apply() receives entity and any extra args you pass when using it
function DotAssemblage:apply(entity, x, y, vx, vy, r, g, b)
    entity:give(Position,  x, y)
    entity:give(Velocity,  vx, vy)
    entity:give(DrawColor, r or 1, g or 1, b or 1, 1)
end

return DotAssemblage

-- ----------------------------------------------------------------
-- main.lua
-- ----------------------------------------------------------------
local Concord         = require "concord"
local MovementSystem  = require "systems.MovementSystem"
local DrawSystem      = require "systems.DrawSystem"
local DotAssemblage   = require "assemblages.DotAssemblage"

local world

function love.load()
    world = Concord.world()
    world:addSystem(MovementSystem)
    world:addSystem(DrawSystem)

    -- Spawn 5 dots using the assemblage
    for i = 1, 5 do
        local e = Concord.entity(world)
        DotAssemblage:apply(e,
            math.random(100, 700),
            math.random(100, 500),
            math.random(-120, 120),
            math.random(-120, 120),
            math.random(), math.random(), math.random()
        )
    end
end

function love.update(dt)
    world:update(dt)   -- calls update() on all systems
end

function love.draw()
    world:draw()       -- calls draw() on all systems
end

-- ----------------------------------------------------------------
-- Bonus: Concord lifecycle hooks and events
-- ----------------------------------------------------------------

-- System added() hook fires when a system is added to a world
function MovementSystem:init()
    print("MovementSystem initialized in world")
end

-- System onEntityAdded/onEntityRemoved fire when pool membership changes
function MovementSystem:onEntityAdded(entity)
    print("Entity joined movement pool:", entity)
end

-- Emit and subscribe to custom events
-- Anywhere in game: world:emit("enemyDied", enemy, position)
-- In a system: subscribe by defining the method with the event name
function DrawSystem:enemyDied(entity, pos)
    -- spawn particle effect at pos
    print("Enemy died at", pos.x, pos.y)
end
```

**GDScript (Godot):**
```gdscript
# Concord's assemblage concept maps directly to Godot factory functions.
# The World:emit() event system maps to Godot signals.

# res://assemblages/DotAssemblage.gd — factory for dot entities
class_name DotAssemblage
extends RefCounted

static func apply(parent: Node, x: float, y: float, vx: float, vy: float, color: Color) -> Dictionary:
    # In a data-table ECS, return a dict. In node-based Godot, instantiate a scene.
    var dot := {
        "position": Vector2(x, y),
        "velocity": Vector2(vx, vy),
        "color":    color,
    }
    return dot

# Lifecycle hook equivalent: _ready() fires when node enters scene tree
# Entity added to pool equivalent: connect to a "entity_registered" signal
signal entity_registered(entity: Dictionary)

# World:emit() equivalent: use a global EventBus autoload
# res://EventBus.gd (autoload)
extends Node
signal enemy_died(entity: Dictionary, position: Vector2)
```

**Concord strengths:**
- Assemblages eliminate scattered entity construction — one definition per type
- Lifecycle hooks (`init`, `onEntityAdded`, `onEntityRemoved`) let systems react to world changes
- Event system is first-class: define `function System:eventName(...)` and it's subscribed
- Formal component definitions prevent typo-based bugs (no silent `nil` field access)
- Better suited for medium-to-large Love2D projects than tiny-ecs

**Concord weaknesses:**
- More boilerplate — each component is a separate file, each system is a module
- Steeper learning curve for people new to Lua OOP (Concord uses metatables heavily)
- No archetype storage — still O(n) on entity add/remove for filter evaluation
- Active development has slowed; check the GitHub issue tracker before committing to it on a large project

---

## 3. Flecs (Reference)

Flecs, created by Sander Mertens, is the most feature-complete ECS framework available in any language. It is written in C with bindings for C++, Lua, Python, and others. You are not expected to use Flecs directly unless you are working in C/C++ — but reading its API will show you what a production-grade ECS looks like at full maturity.

Flecs supports: relationships between entities (`(ChildOf, parent_entity)`), query caching and match pruning, prefab inheritance, hierarchical transforms, a REST API for live debugging, reflection, and first-class support for multi-threading. The Flecs Explorer (a web UI) connects to a running Flecs game and lets you inspect every entity and component live. No other ECS framework comes close to its tooling.

The key concepts to absorb from Flecs:

- **`ECS_COMPONENT`** declares a component type, registering it with the world
- **`ecs_set()`** attaches a component value to an entity
- **`ECS_SYSTEM`** registers a system with a filter string and callback
- **`ecs_query_t`** is a cached, reusable query — not recomputed every frame
- **Relationships** like `(IsA, Goblin)` and `(ChildOf, Player)` are first-class, not a bolted-on hack

**Pseudocode:**
```
// Flecs C API concepts (not expected to compile)
world = ecs_init()

// Declare components
ECS_COMPONENT(world, Position)   // Position struct registered as component type
ECS_COMPONENT(world, Velocity)

// Create entity and assign component data
ecs_entity_t e = ecs_new(world, 0)
ecs_set(world, e, Position, { .x = 100, .y = 200 })
ecs_set(world, e, Velocity, { .vx = 50,  .vy = 30 })

// Register system: runs on entities with both Position and Velocity
ECS_SYSTEM(world, MoveSystem, EcsOnUpdate, Position, Velocity)

// System implementation
void MoveSystem(ecs_iter_t *it) {
    Position *p = ecs_field(it, Position, 1)
    Velocity *v = ecs_field(it, Velocity, 2)
    for (int i = 0; i < it->count; i++) {
        p[i].x += v[i].vx * it->delta_time
        p[i].y += v[i].vy * it->delta_time
    }
}
// Note: p and v are ARRAYS — Flecs gives you SoA archetype chunks directly
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Lua Flecs binding exists (flecs-lua) but is not widely used.
-- The concepts to take from Flecs into Lua ECS:

-- 1. Cached queries: instead of world:query() every frame, store the query
--    This is what Flecs does internally; you can approximate in tiny-ecs by
--    keeping your system's entity list and only updating it on entity add/remove.

-- 2. Relationships as component data:
--    entity.childOf = { parent = parentEntity }   -- simple version
--    entity.isA     = { archetype = "goblin" }    -- prefab inheritance tag

-- 3. The "REST debug API" concept: in Love2D, you can approximate this with
--    a debug console that prints entity/component data on keypress:
local function debugDumpWorld(world)
    print("=== ECS World Dump ===")
    for _, e in ipairs(world.entities) do
        local fields = {}
        for k, _ in pairs(e) do
            table.insert(fields, k)
        end
        print("  entity: [" .. table.concat(fields, ", ") .. "]")
    end
end
-- Call with: love.keyboard.isDown("f1") and debugDumpWorld(world)
```

**GDScript (Godot):**
```gdscript
# Flecs concepts translated to Godot inspection patterns

# The Flecs REST API idea: Godot has the Remote Debugger (Scene tree inspector)
# For runtime ECS inspection in a hand-rolled Godot ECS, add an DebugOverlay:

class_name ECSDebugOverlay
extends CanvasLayer

var entity_manager: Node  # reference to your EntityManager autoload

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode == KEY_F1 and event.pressed:
        _dump_entities()

func _dump_entities() -> void:
    print("=== ECS Entity Dump ===")
    for entity_id in entity_manager.all_entity_ids():
        var comps := entity_manager.get_component_names(entity_id)
        print("  Entity %d: [%s]" % [entity_id, ", ".join(comps)])
```

**Why study Flecs even if you don't use C:** Its documentation (https://www.flecs.dev/flecs/) explains query design, relationship modeling, and performance tuning at a depth no other ECS resource matches. The ECS FAQ maintained by its author (Sander Mertens) is the canonical reference for ECS theory. Reading Flecs concepts will make every other ECS feel more legible.

---

## 4. Bevy ECS (Reference)

Bevy is a Rust game engine built around an archetype ECS. You are not expected to ship a Rust game to benefit from studying it. Its API design for systems and queries is elegant enough that reading it reshapes how you think about ECS in any language.

Bevy systems are ordinary Rust functions. The ECS scheduler injects query parameters automatically. If a system parameter is `Query<(&mut Position, &Velocity)>`, Bevy gives the function an iterator over all entities that have both components. The type system prevents you from mutating components that other systems are reading in parallel — the borrow checker enforces system scheduling safety at compile time.

**Pseudocode:**
```
// Bevy system: function signature declares what it needs
fn move_system(
    query: Query<(&mut Position, &Velocity)>,
    time:  Res<Time>
) {
    for (mut position, velocity) in &mut query {
        position.x += velocity.vx * time.delta_seconds()
        position.y += velocity.vy * time.delta_seconds()
    }
}

// With<> and Without<> narrow queries
fn move_enemies_only(
    query: Query<(&mut Position, &Velocity), With<IsEnemy>>
) { ... }

// Commands spawn and despawn entities
fn spawn_bullet(mut commands: Commands) {
    commands.spawn((
        Position { x: 100.0, y: 200.0 },
        Velocity { vx: 0.0, vy: -500.0 },
        IsBullet,
    ))
}
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Bevy's With<IsEnemy> filter translates directly to tiny-ecs:
local enemyMoveSystem = tiny.processingSystem()
enemyMoveSystem.filter = tiny.requireAll("position", "velocity", "isEnemy")
-- "With<IsEnemy>" is just requireAll with the tag component included

-- Bevy's Commands.spawn() translates to a prefab + world:addEntity():
local function spawnBullet(world, x, y)
    local e = {
        position = { x = x, y = y },
        velocity = { vx = 0, vy = -500 },
        isBullet = true,
    }
    world:addEntity(e)
    return e
end

-- Bevy's Res<Time> (resource access) translates to a singleton component:
-- world entity holds { gameTime = { dt=0, elapsed=0, frameCount=0 } }
-- Systems query for it and read dt from there
```

**GDScript (Godot):**
```gdscript
# Bevy's Query<(&mut Position, &Velocity), With<IsEnemy>> concept
# in a Godot ECS-style manager:

func move_enemies(dt: float) -> void:
    # "With<IsEnemy>" = filter to only enemies
    for entity_id in entity_manager.query_with_all(["position", "velocity", "is_enemy"]):
        var pos := entity_manager.get_component(entity_id, "position") as PositionComponent
        var vel := entity_manager.get_component(entity_id, "velocity") as VelocityComponent
        pos.x += vel.vx * dt
        pos.y += vel.vy * dt

# Bevy's Commands equivalent: a deferred command buffer
func spawn_bullet(x: float, y: float) -> void:
    entity_manager.defer_spawn({
        "position": PositionComponent.new(x, y),
        "velocity": VelocityComponent.new(0.0, -500.0),
        "is_bullet": true,
    })
```

**Why Bevy ECS is worth studying:**

The `With<>`, `Without<>`, and `Added<>` query filters make query design explicit and readable. The `Commands` API makes deferred entity mutation idiomatic. `Res<T>` and `ResMut<T>` make singleton components a typed first-class concept rather than a convention. These ideas will immediately improve how you design queries in any ECS — even tiny-ecs. Read the Bevy book's ECS chapter (https://bevyengine.org/learn/) regardless of whether you plan to use Rust.

---

## 5. Godot's Node Model vs ECS

Godot's scene tree is a form of composition — nodes are attached to parent nodes, each with their own `_process` and `_physics_process` callbacks. It is not ECS. Nodes bundle data and behavior together. Iteration happens implicitly through the tree traversal Godot performs. There is no explicit "query for all entities with Health" — you use groups, which are closer to tag components but are string-based and untyped.

Neither is strictly better. They solve different problems well.

**When Godot's node model wins:**
- Your entities map cleanly to a scene hierarchy (a Player scene containing a Sprite, a CollisionShape, an AnimationPlayer)
- You rely heavily on Godot's built-in physics, AnimationPlayer, or UI system — these are tightly coupled to nodes
- Entity count is low and the overhead of an ECS world isn't justified
- Your team knows Godot and doesn't know ECS

**When ECS patterns win:**
- You have thousands of similar entities (bullets, particles, enemies) that need bulk updates
- You need flexible runtime component composition (an entity that gains or loses abilities at runtime)
- You want system ordering to be explicit and independent of scene tree structure
- You have complex cross-cutting behavior (damage, buffs, status effects) that doesn't fit the node hierarchy

```
Decision flowchart (text):

Is entity count > 1000 with bulk updates?
├── YES → Favor ECS for that subsystem
└── NO  → Does behavior fit scene hierarchy?
          ├── YES → Use Godot nodes
          └── NO  → Do you need flexible composition?
                    ├── YES → Use ECS
                    └── NO  → Use nodes with groups/signals
```

**The hybrid approach** is common in shipped Godot games: use the scene tree for rendering, physics, UI, and scene management. Use an ECS-like manager (an Autoload) for gameplay entity data that needs bulk processing. Godot nodes act as the "view" — their positions are set by ECS data each frame, but they don't own the simulation.

**Pseudocode:**
```
// Hybrid: Godot node = visual/physics proxy, ECS = simulation data

EntityManager (Autoload)
  entities: { id -> { position, velocity, health, ... } }
  systems:  [ MovementSystem, AISystem, CollisionSystem ]

  update(dt):
    for each system: system.update(world, dt)

  // After ECS update, sync visual nodes
  for each (id, data) in entities:
    node = nodes[id]
    node.position = Vector2(data.position.x, data.position.y)
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Hybrid not applicable in pure Love2D — Love2D has no scene tree.
-- In Love2D, the ECS IS the architecture. tiny-ecs or Concord
-- owns all entity state, and love.draw() calls your DrawSystem.
-- No separation needed.

-- The relevant Love2D caveat: don't update entities in both
-- the ECS world AND a separate non-ECS loop. Pick one.
-- If you have world:update(dt), don't also loop over entities manually.
```

**GDScript (Godot):**
```gdscript
# NodeManager.gd — Autoload implementing ECS-style entity management
# Add to Project > Project Settings > Autoload as "NodeManager"

extends Node

# --- Entity registry ---
var _next_id: int = 0
var _components: Dictionary = {}  # { entity_id: { component_name: data } }
var _node_proxies: Dictionary = {}  # { entity_id: Node2D }

# --- Entity lifecycle ---
func create_entity() -> int:
    var id := _next_id
    _next_id += 1
    _components[id] = {}
    return id

func destroy_entity(id: int) -> void:
    _components.erase(id)
    if _node_proxies.has(id):
        _node_proxies[id].queue_free()
        _node_proxies.erase(id)

# --- Component access ---
func give(entity_id: int, component_name: String, data: Variant) -> void:
    _components[entity_id][component_name] = data

func get_comp(entity_id: int, component_name: String) -> Variant:
    return _components[entity_id].get(component_name)

func has_comp(entity_id: int, component_name: String) -> bool:
    return _components[entity_id].has(component_name)

# --- Query: returns all entity IDs that have ALL listed components ---
func query_all(required: Array[String]) -> Array[int]:
    var result: Array[int] = []
    for id in _components.keys():
        var has_all := true
        for comp in required:
            if not _components[id].has(comp):
                has_all = false
                break
        if has_all:
            result.append(id)
    return result

# --- Sync ECS data → Godot node positions each frame ---
func sync_nodes() -> void:
    for id in _node_proxies.keys():
        if not _components.has(id):
            continue
        var pos: Variant = _components[id].get("position")
        if pos != null and _node_proxies[id] != null:
            _node_proxies[id].global_position = Vector2(pos.x, pos.y)

# --- Attach a Godot node as the visual proxy for an entity ---
func attach_node(entity_id: int, node: Node2D) -> void:
    _node_proxies[entity_id] = node

# --- Systems (called from a GameLoop node's _process) ---
func movement_system(dt: float) -> void:
    for id in query_all(["position", "velocity"]):
        var pos: Dictionary = _components[id]["position"]
        var vel: Dictionary = _components[id]["velocity"]
        pos.x += vel.vx * dt
        pos.y += vel.vy * dt

func _process(delta: float) -> void:
    movement_system(delta)
    sync_nodes()  # push ECS positions to Godot node proxies
```

**The key insight:** `sync_nodes()` runs after all systems finish, copying ECS position data to Godot node positions. The Godot renderer reads node positions, not ECS data. ECS handles simulation; Godot handles presentation. This separation is clean and lets you use Godot's full toolkit (AnimationPlayer, particles, shaders) while keeping game logic in the ECS.

The main trap: do not update entity positions in both `_process` on a node AND in the ECS system. Pick one owner. If the ECS owns position, nodes are read-only display proxies. If nodes own position (e.g., using CharacterBody2D physics), mirror position into ECS components after physics resolves.

---

## 6. When NOT to Use ECS

ECS adds indirection and boilerplate. For large projects with many similar entities, the architectural benefits pay for themselves. For small projects, you're paying costs with no return.

**Do not use ECS when:**

- **Entity count stays low (under ~50 distinct types, under ~500 total entities).** A class hierarchy or plain tables-and-functions will be cleaner and faster to write.
- **Your design fits a scene hierarchy.** If your game is a Godot scene tree of nodes that communicate through signals, forcing ECS on top of it fights the grain of the engine.
- **No performance pressure exists.** If you're running at 60fps with headroom to spare, restructuring for cache efficiency is premature optimization.
- **Your team doesn't know ECS.** Training cost is real. A small team that understands OOP ships a game faster with OOP than they do learning ECS while also trying to finish a game.
- **It's a jam game.** 48–72 hours is not the time to introduce an architectural paradigm. Write the simplest code that works.
- **Your entities all share the same components.** If every entity has position, velocity, health, and sprite — no exceptions — a plain array of structs is simpler and equally fast.

**Decision checklist — ask yourself these before adding an ECS library:**

1. Do I have more than ~500 entities that need bulk updates every frame?
2. Do I have entities that mix and match behaviors from a large set of possible behaviors?
3. Is my inheritance hierarchy causing concrete pain right now (diamond problem, god class)?
4. Am I working on a genre where entity composition flexibility matters (roguelikes, survival games, shooters)?
5. Do I have time to learn the library's API and debug its behavior before the deadline?
6. Am I already comfortable with the OOP or scene-tree approach for this kind of game?

If you answered YES to 1-4 and YES to 5, ECS is worth evaluating. If you answered NO to most of 1-4, or NO to 5, use the simpler approach. Ship the game first. Reach for ECS when the alternative hurts.

**Pseudocode:**
```
// Simple alternative for small games — no ECS needed
entities = []

function spawnEnemy(x, y):
    entities.push({ type="enemy", x=x, y=y, vx=1, vy=0, hp=10 })

function update(dt):
    for each e in entities:
        e.x += e.vx * dt
        e.y += e.vy * dt
        if e.type == "enemy": updateEnemyAI(e, dt)
    entities = filter(entities, e -> e.hp > 0)

// This is fine for 30 enemies. Don't add ECS to fix a problem you don't have.
```

**Lua (tiny-ecs / Love2D):**
```lua
-- For a game with < 200 entities and no complex composition needs:
-- Just use tables and functions. No library required.

local entities = {}

local function spawn(x, y, vx, vy, r, g, b)
    table.insert(entities, { x=x, y=y, vx=vx, vy=vy, r=r, g=g, b=b, alive=true })
end

local function update(dt)
    local W, H = love.graphics.getDimensions()
    for _, e in ipairs(entities) do
        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt
        if e.x > W or e.x < 0 then e.vx = -e.vx end
        if e.y > H or e.y < 0 then e.vy = -e.vy end
    end
end

local function draw()
    for _, e in ipairs(entities) do
        love.graphics.setColor(e.r, e.g, e.b, 1)
        love.graphics.rectangle("fill", e.x - 3, e.y - 3, 6, 6)
    end
end

-- This is valid Love2D code. No ECS needed for this scale.
-- Add ECS when this approach starts causing pain — not before.
```

**GDScript (Godot):**
```gdscript
# For small Godot games: nodes + signals + groups is the right answer.
# This pattern handles 99% of indie game needs cleanly.

# enemy.gd — self-contained node, no ECS manager needed
class_name Enemy
extends CharacterBody2D

@export var speed: float = 60.0
@export var max_health: float = 30.0
var health: float

func _ready() -> void:
    health = max_health
    add_to_group("enemies")

func take_damage(amount: float) -> void:
    health -= amount
    if health <= 0:
        queue_free()

# Spawner spawns enemies, enemies handle themselves.
# No world, no systems, no query. Just nodes.
# This is correct for a game with < 200 enemies.
```

---

## Code Walkthrough: Three-Way Demo

The same mini-game, implemented three ways: a player that moves with arrow keys, spawns bullets on space, and enemies that bounce around the screen. Each enemy that a bullet hits is destroyed.

### a) tiny-ecs (Complete Love2D Game)

```lua
-- tiny_demo/main.lua
local tiny = require "tiny"

local W, H = 800, 600
local world

-- ---- Components (just fields on entity tables) ----
-- position { x, y }
-- velocity { vx, vy }
-- color    { r, g, b }
-- player   { speed }
-- bullet   { damage }
-- enemy    { size }
-- radius   (number, for collision)

-- ---- Systems ----

-- Input + player movement
local playerSystem = tiny.processingSystem()
playerSystem.filter = tiny.requireAll("position", "velocity", "player")

function playerSystem:process(entity, dt)
    local spd = entity.player.speed
    local vx, vy = 0, 0
    if love.keyboard.isDown("left")  then vx = -spd end
    if love.keyboard.isDown("right") then vx =  spd end
    if love.keyboard.isDown("up")    then vy = -spd end
    if love.keyboard.isDown("down")  then vy =  spd end
    entity.velocity.vx = vx
    entity.velocity.vy = vy
end

-- Movement for all moving entities
local movementSystem = tiny.processingSystem()
movementSystem.filter = tiny.requireAll("position", "velocity")

function movementSystem:process(entity, dt)
    entity.position.x = entity.position.x + entity.velocity.vx * dt
    entity.position.y = entity.position.y + entity.velocity.vy * dt
end

-- Enemy bounce off walls
local bounceSystem = tiny.processingSystem()
bounceSystem.filter = tiny.requireAll("position", "velocity", "enemy")

function bounceSystem:process(entity, dt)
    local r = entity.radius or 10
    if entity.position.x - r < 0  or entity.position.x + r > W then
        entity.velocity.vx = -entity.velocity.vx
        entity.position.x = math.max(r, math.min(W - r, entity.position.x))
    end
    if entity.position.y - r < 0  or entity.position.y + r > H then
        entity.velocity.vy = -entity.velocity.vy
        entity.position.y = math.max(r, math.min(H - r, entity.position.y))
    end
end

-- Bullet out-of-bounds cleanup
local bulletCleanupSystem = tiny.processingSystem()
bulletCleanupSystem.filter = tiny.requireAll("bullet", "position")

function bulletCleanupSystem:process(entity, dt)
    if entity.position.x < 0 or entity.position.x > W or
       entity.position.y < 0 or entity.position.y > H then
        world:removeEntity(entity)
    end
end

-- Bullet-enemy collision
local collisionSystem = tiny.processingSystem()
collisionSystem.filter = tiny.requireAll("bullet", "position")
collisionSystem._enemies = {}  -- populated in onEntityAdded

function collisionSystem:onEntityAdded(entity)
    if entity.enemy then
        table.insert(self._enemies, entity)
    end
end

function collisionSystem:onEntityRemoved(entity)
    if entity.enemy then
        for i, e in ipairs(self._enemies) do
            if e == entity then table.remove(self._enemies, i); break end
        end
    end
end

function collisionSystem:process(bullet, dt)
    for _, enemy in ipairs(self._enemies) do
        local dx = bullet.position.x - enemy.position.x
        local dy = bullet.position.y - enemy.position.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < (enemy.radius or 12) + 3 then
            world:removeEntity(bullet)
            world:removeEntity(enemy)
            return  -- bullet is gone, stop checking
        end
    end
end

-- Draw
local drawSystem = tiny.processingSystem()
drawSystem.filter = tiny.requireAll("position", "color")

function drawSystem:process(entity, dt)
    local r = entity.radius or 4
    love.graphics.setColor(entity.color.r, entity.color.g, entity.color.b, 1)
    love.graphics.circle("fill", entity.position.x, entity.position.y, r)
end

-- ---- Prefabs ----

local function spawnPlayer(x, y)
    local e = {
        position = { x=x, y=y }, velocity = { vx=0, vy=0 },
        player   = { speed=200 },
        color    = { r=0.2, g=0.8, b=1.0 },
        radius   = 8,
    }
    world:addEntity(e)
    return e
end

local playerRef  -- store reference to shoot from

local function spawnBullet(x, y)
    world:addEntity({
        position = { x=x, y=y }, velocity = { vx=0, vy=-400 },
        bullet   = { damage=1 },
        color    = { r=1, g=1, b=0.3 },
        radius   = 3,
    })
end

local function spawnEnemy(x, y)
    local angle = math.random() * math.pi * 2
    world:addEntity({
        position = { x=x, y=y },
        velocity = { vx=math.cos(angle)*80, vy=math.sin(angle)*80 },
        enemy    = {},
        color    = { r=1, g=0.3, b=0.3 },
        radius   = 12,
    })
end

-- ---- Love2D lifecycle ----

local shootCooldown = 0

function love.load()
    math.randomseed(os.time())
    world = tiny.world(playerSystem, movementSystem, bounceSystem,
                       bulletCleanupSystem, collisionSystem, drawSystem)
    playerRef = spawnPlayer(W/2, H - 80)
    for i = 1, 8 do
        spawnEnemy(math.random(60, W-60), math.random(60, H/2))
    end
end

function love.update(dt)
    shootCooldown = shootCooldown - dt
    if love.keyboard.isDown("space") and shootCooldown <= 0 then
        spawnBullet(playerRef.position.x, playerRef.position.y - 10)
        shootCooldown = 0.18
    end
    world:update(dt)
end

function love.draw()
    love.graphics.setBackgroundColor(0.08, 0.08, 0.12)
    world:draw()
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print("SPACE: shoot | Arrows: move", 10, 10)
end
```

**tiny-ecs — what felt better:**
- Zero boilerplate to start — the whole game is one file
- Filter syntax is immediate and readable
- Adding a new system is trivially easy

**tiny-ecs — what felt worse:**
- `world:removeEntity / world:addEntity` to update filters is awkward
- No formal collision result — had to maintain `_enemies` list manually on the system
- No built-in events — cross-system communication is DIY

---

### b) Concord (Complete Love2D Game)

```lua
-- concord_demo/main.lua — same game in Concord
-- Assumes components and systems are in separate files per Concord convention
-- Abbreviated here to the main.lua glue for clarity

local Concord = require "concord"

-- ---- Component definitions (normally separate files) ----
local Position  = Concord.component(function(c, x, y)  c.x=x or 0; c.y=y or 0 end)
local Velocity  = Concord.component(function(c, vx, vy) c.vx=vx or 0; c.vy=vy or 0 end)
local Player    = Concord.component(function(c, spd)    c.speed=spd or 200 end)
local Bullet    = Concord.component(function(c)         end)  -- tag-like
local Enemy     = Concord.component(function(c, r)      c.radius=r or 12 end)
local Drawable  = Concord.component(function(c, r,g,b,rad) c.r=r; c.g=g; c.b=b; c.radius=rad or 6 end)

local W, H = 800, 600

-- ---- Systems ----

local PlayerSystem = Concord.system({ pool = {Position, Velocity, Player} })
function PlayerSystem:update(dt)
    for _, e in ipairs(self.pool) do
        local spd = e[Player].speed
        local vx, vy = 0, 0
        if love.keyboard.isDown("left")  then vx=-spd end
        if love.keyboard.isDown("right") then vx= spd end
        if love.keyboard.isDown("up")    then vy=-spd end
        if love.keyboard.isDown("down")  then vy= spd end
        e[Velocity].vx = vx; e[Velocity].vy = vy
    end
end

local MovementSystem = Concord.system({ pool = {Position, Velocity} })
function MovementSystem:update(dt)
    for _, e in ipairs(self.pool) do
        e[Position].x = e[Position].x + e[Velocity].vx * dt
        e[Position].y = e[Position].y + e[Velocity].vy * dt
    end
end

local BounceSystem = Concord.system({ pool = {Position, Velocity, Enemy} })
function BounceSystem:update(dt)
    for _, e in ipairs(self.pool) do
        local p, v, en = e[Position], e[Velocity], e[Enemy]
        if p.x - en.radius < 0 or p.x + en.radius > W then
            v.vx = -v.vx; p.x = math.max(en.radius, math.min(W-en.radius, p.x))
        end
        if p.y - en.radius < 0 or p.y + en.radius > H then
            v.vy = -v.vy; p.y = math.max(en.radius, math.min(H-en.radius, p.y))
        end
    end
end

-- CollisionSystem uses Concord's world:emit() for hit events
local CollisionSystem = Concord.system({
    bullets  = { Bullet, Position },
    enemies  = { Enemy,  Position },
})
function CollisionSystem:update(dt)
    for _, bullet in ipairs(self.bullets) do
        for _, enemy in ipairs(self.enemies) do
            local bp, ep = bullet[Position], enemy[Position]
            local dx = bp.x - ep.x; local dy = bp.y - ep.y
            if math.sqrt(dx*dx+dy*dy) < enemy[Enemy].radius + 3 then
                -- Emit event — other systems can listen for this
                self:getWorld():emit("hit", bullet, enemy)
                return  -- bullet consumed
            end
        end
    end
end

-- Listen for hit events and clean up entities
local CleanupSystem = Concord.system({})
function CleanupSystem:hit(bullet, enemy)
    bullet:destroy()
    enemy:destroy()
end

local DrawSystem = Concord.system({ pool = {Position, Drawable} })
function DrawSystem:draw()
    for _, e in ipairs(self.pool) do
        local p, d = e[Position], e[Drawable]
        love.graphics.setColor(d.r, d.g, d.b, 1)
        love.graphics.circle("fill", p.x, p.y, d.radius)
    end
end

-- ---- Assemblages ----
local PlayerAssemblage = Concord.assemblage()
function PlayerAssemblage:apply(e, x, y)
    e:give(Position, x, y); e:give(Velocity, 0, 0)
    e:give(Player, 200); e:give(Drawable, 0.2, 0.8, 1.0, 8)
end

local BulletAssemblage = Concord.assemblage()
function BulletAssemblage:apply(e, x, y)
    e:give(Position, x, y); e:give(Velocity, 0, -400); e:give(Bullet); e:give(Drawable, 1,1,0.3, 3)
end

local EnemyAssemblage = Concord.assemblage()
function EnemyAssemblage:apply(e, x, y)
    local a = math.random()*math.pi*2
    e:give(Position, x, y); e:give(Velocity, math.cos(a)*80, math.sin(a)*80)
    e:give(Enemy, 12); e:give(Drawable, 1, 0.3, 0.3, 12)
end

-- ---- Main ----
local world
local playerEntity
local shootCooldown = 0

function love.load()
    math.randomseed(os.time())
    world = Concord.world()
    world:addSystem(PlayerSystem):addSystem(MovementSystem):addSystem(BounceSystem)
    world:addSystem(CollisionSystem):addSystem(CleanupSystem):addSystem(DrawSystem)

    playerEntity = Concord.entity(world)
    PlayerAssemblage:apply(playerEntity, W/2, H-80)

    for i = 1, 8 do
        local e = Concord.entity(world)
        EnemyAssemblage:apply(e, math.random(60,W-60), math.random(60,H/2))
    end
end

function love.update(dt)
    shootCooldown = shootCooldown - dt
    if love.keyboard.isDown("space") and shootCooldown <= 0 then
        local px = playerEntity[Position].x
        local py = playerEntity[Position].y
        local bullet = Concord.entity(world)
        BulletAssemblage:apply(bullet, px, py - 10)
        shootCooldown = 0.18
    end
    world:update(dt)
end

function love.draw()
    love.graphics.setBackgroundColor(0.08, 0.08, 0.12)
    world:draw()
    love.graphics.setColor(1,1,1,0.6)
    love.graphics.print("SPACE: shoot | Arrows: move", 10, 10)
end
```

**Concord — what felt better:**
- `world:emit("hit", bullet, enemy)` for collision results was clean — no manual enemy list
- Assemblages made spawn calls one-liners; all defaults in one place
- `e:destroy()` is clear and safe (Concord handles deferred removal)

**Concord — what felt worse:**
- Component access via `e[Position]` feels indirect compared to `e.position.x`
- More files required for a "proper" setup; main.lua monolith defeats the structure
- Figuring out multi-pool systems (`bullets` + `enemies` as separate pools) requires reading the API carefully

---

### c) Godot Nodes (Complete Godot Scene)

```gdscript
# res://Main.gd — attached to a Node2D scene called Main
extends Node2D

const BULLET_SPEED := 500.0
const PLAYER_SPEED := 200.0
const ENEMY_SPEED  := 80.0
const ENEMY_COUNT  := 8

var player: CharacterBody2D
var shoot_cooldown := 0.0

func _ready() -> void:
    _spawn_player()
    for i in ENEMY_COUNT:
        _spawn_enemy(
            Vector2(randf_range(60, 740), randf_range(60, 250))
        )

func _spawn_player() -> void:
    var p := CharacterBody2D.new()
    var col := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 8.0
    col.shape = shape
    p.add_child(col)

    var vis := ColorRect.new()
    vis.color = Color(0.2, 0.8, 1.0)
    vis.size  = Vector2(16, 16)
    vis.position = Vector2(-8, -8)
    p.add_child(vis)

    p.position = Vector2(400, 520)
    p.add_to_group("player")
    add_child(p)
    player = p

func _spawn_bullet(pos: Vector2) -> void:
    var b := Area2D.new()
    var col := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 3.0
    col.shape = shape
    b.add_child(col)

    var vis := ColorRect.new()
    vis.color = Color(1, 1, 0.3)
    vis.size  = Vector2(6, 6)
    vis.position = Vector2(-3, -3)
    b.add_child(vis)

    b.position = pos
    b.set_meta("velocity", Vector2(0, -BULLET_SPEED))
    b.add_to_group("bullets")

    # Connect area_entered to detect enemy collision
    b.body_entered.connect(func(body: Node) -> void:
        if body.is_in_group("enemies"):
            body.queue_free()
            b.queue_free()
    )

    add_child(b)

func _spawn_enemy(pos: Vector2) -> void:
    var e := CharacterBody2D.new()
    var col := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 12.0
    col.shape = shape
    e.add_child(col)

    var vis := ColorRect.new()
    vis.color = Color(1, 0.3, 0.3)
    vis.size  = Vector2(24, 24)
    vis.position = Vector2(-12, -12)
    e.add_child(vis)

    var angle := randf() * TAU
    e.velocity = Vector2(cos(angle), sin(angle)) * ENEMY_SPEED
    e.position = pos
    e.add_to_group("enemies")
    add_child(e)

func _process(delta: float) -> void:
    shoot_cooldown -= delta
    if Input.is_action_pressed("ui_accept") and shoot_cooldown <= 0:
        _spawn_bullet(player.position + Vector2(0, -10))
        shoot_cooldown = 0.18

    # Move player
    var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    player.velocity = dir * PLAYER_SPEED
    player.move_and_slide()

    # Move bullets
    for bullet in get_tree().get_nodes_in_group("bullets"):
        var vel: Vector2 = bullet.get_meta("velocity", Vector2.ZERO)
        bullet.position += vel * delta
        if bullet.position.y < -20:
            bullet.queue_free()

    # Move and bounce enemies
    for enemy in get_tree().get_nodes_in_group("enemies"):
        enemy.move_and_slide()
        # Bounce off walls
        if enemy.position.x < 12 or enemy.position.x > 788:
            enemy.velocity.x = -enemy.velocity.x
        if enemy.position.y < 12 or enemy.position.y > 588:
            enemy.velocity.y = -enemy.velocity.y
```

**Godot nodes — what felt better:**
- Collision detection was handled by `body_entered` signal — no manual distance math
- `move_and_slide()` is built in, no velocity integration to write
- Scene tree visualization in the editor is immediate and inspectable

**Godot nodes — what felt worse:**
- `get_nodes_in_group()` iterates the whole tree — not great at high entity count
- Bullets stored velocity in metadata (`set_meta`) — awkward compared to component data
- No clear system ordering — behavior scattered across `_process`, `body_entered`, and spawner functions

---

## Concept Quick Reference

| Library | Language | Storage | Events | Archetypes | Best For |
|---------|----------|---------|--------|------------|----------|
| tiny-ecs | Lua | Hash table (entity table) | Manual / DIY | No | Small-medium Love2D projects, prototypes, jam games |
| Concord | Lua | Hash table + formal component objects | `world:emit()` / system methods | No | Medium-large Love2D projects needing structure |
| Flecs | C / C++ | Archetype chunks (SoA) | Observers, hooks | Yes | Production C/C++ games, tooling-heavy workflows |
| Bevy ECS | Rust | Archetype chunks (SoA) | Events, Commands | Yes | Production Rust games, archetype ECS reference |
| Godot nodes | GDScript / C# | Scene tree (node graph) | Signals | No | Most Godot games, physics/UI/animation-heavy work |
| Hand-rolled (Godot) | GDScript | Dictionary/Array | Signals / custom | Optional | Hybrid Godot projects needing bulk entity processing |

---

## Common Pitfalls

1. **Using tiny-ecs for a large project and hitting performance walls.** tiny-ecs re-evaluates filters on every `addEntity`/`removeEntity` and does linear iteration. At 5,000+ entities with frequent component swaps, you'll feel it. If you know your project will scale, start with Concord or a hand-rolled SoA approach from Module 5 rather than migrating later.

2. **Not using assemblages/prefabs in Concord.** Without assemblages, entity construction spreads across the codebase. You end up with slightly different component defaults in different spawn sites, mysterious bugs when one site misses a component, and no single source of truth for what a "goblin" is. Use assemblages. One per entity type.

3. **Forcing ECS on a game that doesn't need it.** If you're two days into a jam game and you're debugging why your tiny-ecs filters aren't matching, you've made a mistake. ECS has upfront cost. Don't pay it unless the project is large enough to benefit.

4. **Mixing Godot's node lifecycle with ECS iteration.** If a node's `_process` also moves the entity, and your ECS system also moves it, the entity moves twice per frame. Designate one owner for each piece of state. Nodes are view-only if ECS owns simulation; ECS is read-only if Godot physics owns position.

5. **Not reading the tiny-ecs source code.** It's ~500 lines. Reading it takes 30–60 minutes and will answer every "why does it behave like this" question you'll ever have about the library. The filter evaluation logic, the system iteration order, how `onEntityAdded` fires — it's all there, readable Lua, no magic. Read it before you file a bug report or write a workaround.

6. **Using ECS for UI.** UI state is hierarchical, event-driven, and tightly coupled to user interaction — the opposite of the flat, bulk-iterable data ECS is good at. Godot's Control tree handles it correctly. Love2D's immediate-mode approach (draw calls with state) handles it correctly. Trying to represent a dropdown menu or a button hover state as ECS entities and components produces unnecessary complexity with no benefit.

---

## Exercises

**Exercise 1: Build the three-way demo yourself**
Implement the mini-game from the Code Walkthrough — player moves with arrow keys, shoots bullets with space, enemies bounce and can be destroyed — three times: once in tiny-ecs, once in Concord, and once as a plain Godot scene. Do not copy the code above; write it from the API documentation. After each implementation, write 3 bullet points: what went smoothly, what was annoying, and one thing you'd design differently.

- **Estimated time:** 3–5 hours
- **Stretch goal:** Add a score counter that increments when an enemy is destroyed. Implement it differently in each version (tiny-ecs: singleton entity; Concord: `world:emit("scored")` event; Godot: signal to a HUD node) and note which approach felt most natural.

**Exercise 2: Read the tiny-ecs source in full and annotate it**
Download the tiny-ecs source (`tiny.lua`). Open it in an editor. Read every line. For every function, add a comment in your own words explaining what it does and why. Pay particular attention to: how `world:addEntity()` evaluates filters, how `world:update()` routes to systems, and how `onEntityAdded` / `onEntityRemoved` hooks fire. By the end, you should be able to answer "what happens if I call `world:addEntity()` while a system is currently in `process()`?"

- **Estimated time:** 1–2 hours
- **Stretch goal:** Add archetype optimization to tiny-ecs. When a set of component keys is seen for the first time, cache which systems match it. On subsequent `addEntity()` calls with the same key set, skip re-evaluating all system filters — use the cache. Benchmark the improvement with 10,000 entity adds.

**Exercise 3: Port a previous project to use Concord assemblages**
Take a Love2D project you've already built (from any earlier module or your own work) and refactor entity construction to use Concord assemblages. Every entity type needs exactly one assemblage. No `world:addEntity` calls outside of an assemblage's `apply` function. After the port, count how many separate `entity.something = ...` lines you eliminated.

- **Estimated time:** 2–3 hours
- **Stretch goal:** Add at least two Concord events to the project. One event should cross system boundaries — emitted by one system and consumed by a different system. Verify that the emitting system has no reference to the consuming system.

---

## Key Takeaways

- **Library choice follows project scale.** tiny-ecs is the right default for Love2D until it hurts. Concord is the right default when structure matters more than minimalism. Flecs and Bevy are production references worth reading even if you never use them.
- **Godot's node model and ECS are not opposites.** The hybrid approach — Godot nodes for rendering and physics, an ECS manager for gameplay simulation — combines both tools' strengths. Most shipped Godot indie games that use ECS use it this way.
- **ECS is not a cure-all.** Fewer than 500 entities, a clean scene hierarchy, no composition flexibility needed, a jam deadline — all of these are good reasons to skip ECS and write the simplest thing that works.
- **Reading library source is not optional.** tiny-ecs is ~500 lines. Concord's core is not much larger. The answers to every "why does this behave unexpectedly" question are in the source. Read them early.
- **Cross-system communication is where framework design shows itself.** The difference between tiny-ecs (DIY events), Concord (`world:emit()`), and Bevy (`EventWriter<T>`) is most visible when two systems need to react to the same occurrence. Understanding that difference will help you choose and use the right framework for your project.

---

## What's Next

[Module 7: Building a Game with ECS](module-07-building-a-game-with-ecs.md) — capstone module. Build a complete small game using ECS architecture: title screen, gameplay, game over, sound, and juice. Everything from Modules 1–6 converges here.

Back to [ECS Learning Roadmap](ecs-learning-roadmap.md)

