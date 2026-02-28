# Module 3: Events, Communication & System Ordering

**Part of:** [ECS Learning Roadmap](ecs-learning-roadmap.md)
**Estimated study time:** 3–5 hours
**Prerequisites:** [Module 2: Querying and Iteration](module-02-querying-and-iteration.md)

---

## Overview

ECS makes systems isolated by design — each system minds its own business, queries its own components, and doesn't call other systems directly. This isolation is what makes ECS composable and testable. But isolation creates a problem: when something significant happens, like a bullet hitting an enemy, multiple systems need to react. CollisionSystem needs to detect it, DamageSystem needs to reduce health, AudioSystem needs to play a sound, ParticleSystem needs to spawn sparks. How do they all coordinate if none of them are allowed to talk to each other directly?

The answer is events and shared component state. Instead of CollisionSystem reaching into DamageSystem and saying "hey, apply 3 damage to entity 42," it drops a note into a shared inbox: "a hit happened, here's the data." DamageSystem, AudioSystem, and ParticleSystem each check the inbox independently and react however they want. Add a new system later that reacts to hits? Just subscribe it — no changes to CollisionSystem required.

The second major topic in this module is system ordering. ECS systems run sequentially each frame, and the order matters enormously. If RenderSystem runs before MovementSystem, you're always rendering last frame's positions. If DamageSystem runs before CollisionSystem, damage never lands on the frame the collision happens. You also need to understand deferred commands — a critical gotcha where deleting entities mid-iteration corrupts your query results, and the buffer pattern that solves it.

---

## 1. Why Decoupled Systems Need Communication

Systems are intentionally isolated. CollisionSystem does not call DamageSystem directly. This is a feature, not a limitation. But it creates a coordination problem.

Imagine CollisionSystem directly calling into other systems:

**Pseudocode:**
```
-- Tightly coupled, BAD
system CollisionSystem:
    on update:
        for each (bullet, enemy) pair that overlaps:
            damageSystem.applyDamage(enemy, bullet.damage)
            audioSystem.playSound("hit.wav")
            particleSystem.spawnSparks(bullet.position)
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Tightly coupled, BAD
function CollisionSystem:update(dt)
    for _, bulletId in ipairs(world:query("bullet", "position")) do
        for _, enemyId in ipairs(world:query("enemy", "position")) do
            if overlapping(bulletId, enemyId) then
                self.damageSystem:applyDamage(enemyId, 3)  -- direct call!
                self.audioSystem:playSound("hit.wav")       -- direct call!
                self.particleSystem:spawnSparks(bulletId)   -- direct call!
            end
        end
    end
end
```

**GDScript (Godot):**
```gdscript
# Tightly coupled, BAD
func _process(delta):
    for bullet in get_tree().get_nodes_in_group("bullets"):
        for enemy in get_tree().get_nodes_in_group("enemies"):
            if bullet.overlaps_body(enemy):
                damage_system.apply_damage(enemy, 3)   # direct call!
                audio_system.play_sound("hit.wav")     # direct call!
                particle_system.spawn_sparks(bullet)   # direct call!
```

Now CollisionSystem has references to three other systems. Add a `ScreenShakeSystem` that should also react to hits? Edit CollisionSystem again. Add a `AchievementSystem`? Edit CollisionSystem again. The dependency web grows until CollisionSystem has to know about the entire game.

Events break this dependency chain. CollisionSystem emits one event. Every other system that cares subscribes independently. CollisionSystem never learns their names.

---

## 2. Event Queues: Emit → Buffer → Dispatch

An event queue is a shared buffer. Systems drop events in. Other systems read events out. The buffer clears at the end of each frame. No system needs to know what other systems exist.

Here is a minimal EventBus implementation:

**Pseudocode:**
```
EventBus:
    _queue: list of {type, data}
    _handlers: map of eventType -> list of functions

    emit(eventType, data):
        append {type, data} to _queue

    subscribe(eventType, handler):
        append handler to _handlers[eventType]

    dispatch():
        for each event in _queue:
            for each handler in _handlers[event.type]:
                call handler(event.data)
        clear _queue
```

**Lua (tiny-ecs / Love2D):**
```lua
local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
    return setmetatable({ _queue = {}, _handlers = {} }, EventBus)
end

function EventBus:emit(eventType, data)
    self._queue[#self._queue + 1] = { type = eventType, data = data }
end

function EventBus:subscribe(eventType, handler)
    self._handlers[eventType] = self._handlers[eventType] or {}
    self._handlers[eventType][#self._handlers[eventType] + 1] = handler
end

function EventBus:dispatch()
    for _, event in ipairs(self._queue) do
        local handlers = self._handlers[event.type] or {}
        for _, handler in ipairs(handlers) do
            handler(event.data)
        end
    end
    self._queue = {}  -- clear after dispatch
end
```

Usage with tiny-ecs — attach the bus to the world and pass it to systems at registration:

```lua
-- main.lua
local bus = EventBus.new()

-- CollisionSystem emits
function CollisionSystem:update(dt)
    -- ... detect overlaps ...
    bus:emit("hit", { target = enemyId, damage = 3, pos = bulletPos })
end

-- DamageSystem subscribes
bus:subscribe("hit", function(data)
    local health = world:get(data.target, "health")
    if health then health.hp = health.hp - data.damage end
end)

-- AudioSystem subscribes independently
bus:subscribe("hit", function(data)
    love.audio.play(hitSound)
end)

-- In your game loop, dispatch after all systems run
function love.update(dt)
    world:update(dt)   -- runs all systems
    bus:dispatch()     -- process all queued events
end
```

**GDScript (Godot):**

Godot's Signal system is a built-in event bus. Use it instead of rolling your own:

```gdscript
# In a CollisionSystem autoload or node:
signal hit_occurred(target, damage, position)

# CollisionSystem emits
func _process(delta):
    # ... detect overlaps ...
    hit_occurred.emit(enemy, 3, bullet.global_position)

# DamageSystem subscribes
func _ready():
    CollisionSystem.hit_occurred.connect(_on_hit)

func _on_hit(target, damage, position):
    if target.has_node("HealthComponent"):
        target.get_node("HealthComponent").hp -= damage

# AudioSystem subscribes independently
func _ready():
    CollisionSystem.hit_occurred.connect(_on_hit_sound)

func _on_hit_sound(target, damage, position):
    hit_sound.play()
```

Signals decouple emitter from receiver exactly as an EventBus does. Neither DamageSystem nor AudioSystem knows the other exists.

---

## 3. Deferred Commands: Why You Can't Delete Mid-Iteration

This is the most important gotcha in ECS. Burn it into memory.

**The problem:** if you destroy an entity while iterating over a query that includes it, you corrupt the iteration.

**Pseudocode:**
```
-- BAD: modifying the list you are iterating
for each entity with Health component:
    if entity.hp <= 0:
        destroyEntity(entity)   -- the query list just changed under you
```

**Lua (tiny-ecs / Love2D):**
```lua
-- BAD: do not do this
for _, id in ipairs(world:query("health")) do
    local health = world:get(id, "health")
    if health.hp <= 0 then
        world:removeEntity(id)  -- modifies the list we're currently walking!
    end
end
-- Result: Lua's ipairs may skip the entity after the deleted one,
-- or you get a nil dereference on the next iteration.
```

**GDScript (Godot):**
```gdscript
# BAD: do not do this
for enemy in get_tree().get_nodes_in_group("enemies"):
    if enemy.hp <= 0:
        enemy.queue_free()  # node is freed, but we're still iterating
        # next iteration may reference a freed node
```

The fix is a deferred buffer: collect what needs to happen, do it after the loop ends.

**Pseudocode:**
```
toDestroy = []
for each entity with Health component:
    if entity.hp <= 0:
        append entity to toDestroy    -- just buffer the intent

for each entity in toDestroy:
    destroyEntity(entity)             -- safe: we are not iterating a query
```

**Lua (tiny-ecs / Love2D):**
```lua
-- GOOD: collect then destroy
local toDestroy = {}

for _, id in ipairs(world:query("health")) do
    local health = world:get(id, "health")
    if health.hp <= 0 then
        toDestroy[#toDestroy + 1] = id  -- buffer the id, don't touch the world
    end
end

for _, id in ipairs(toDestroy) do
    world:removeEntity(id)  -- safe: not iterating anymore
end
```

**GDScript (Godot):**
```gdscript
# GOOD: collect then free
var to_destroy = []

for enemy in get_tree().get_nodes_in_group("enemies"):
    if enemy.hp <= 0:
        to_destroy.append(enemy)

for enemy in to_destroy:
    enemy.queue_free()  # safe: iteration is done
```

### The Full CommandBuffer Pattern

Destruction is not the only operation that can break mid-iteration. Adding or removing components can invalidate queries too, and spawning new entities can pollute a query mid-walk. A CommandBuffer generalizes the deferred pattern to all world-mutating operations:

**Lua (tiny-ecs / Love2D):**
```lua
local CommandBuffer = {}
CommandBuffer.__index = CommandBuffer

function CommandBuffer.new(world)
    return setmetatable({
        _world = world,
        _destroy = {},
        _addComponent = {},
        _removeComponent = {},
    }, CommandBuffer)
end

function CommandBuffer:destroyEntity(id)
    self._destroy[#self._destroy + 1] = id
end

function CommandBuffer:addComponent(id, compName, data)
    self._addComponent[#self._addComponent + 1] = { id = id, name = compName, data = data }
end

function CommandBuffer:removeComponent(id, compName)
    self._removeComponent[#self._removeComponent + 1] = { id = id, name = compName }
end

function CommandBuffer:flush()
    -- Add components first (entities need to exist)
    for _, cmd in ipairs(self._addComponent) do
        self._world:add(cmd.id, cmd.name, cmd.data)
    end
    -- Remove components
    for _, cmd in ipairs(self._removeComponent) do
        self._world:remove(cmd.id, cmd.name)
    end
    -- Destroy last
    for _, id in ipairs(self._destroy) do
        self._world:destroyEntity(id)
    end
    -- Clear all buffers
    self._destroy = {}
    self._addComponent = {}
    self._removeComponent = {}
end
```

Systems receive the `cmd` buffer, never the world directly for mutations:

```lua
function DeathSystem:update(dt, cmd)
    for _, id in ipairs(world:query("health")) do
        local h = world:get(id, "health")
        if h.hp <= 0 then
            cmd:destroyEntity(id)
            -- Also spawn a pickup at their position — safe because cmd buffers it
            local pos = world:get(id, "position")
            local newId = world:newEntity()
            cmd:addComponent(newId, "pickup", { value = 5 })
            cmd:addComponent(newId, "position", { x = pos.x, y = pos.y })
        end
    end
end

-- In game loop:
world:update(dt)
cmd:flush()  -- all mutations happen here, after all systems have run
```

**GDScript (Godot):**
```gdscript
# Godot's queue_free() is itself a deferred command — nodes are freed
# at the end of the frame, not immediately. You get this behavior for free.
# For component add/remove, use a similar buffer approach:

var _pending_add_components = []
var _pending_remove_components = []

func defer_add_component(entity, component):
    _pending_add_components.append([entity, component])

func flush():
    for pair in _pending_add_components:
        pair[0].add_child(pair[1])
    for pair in _pending_remove_components:
        pair[0].remove_child(pair[1])
    _pending_add_components.clear()
    _pending_remove_components.clear()
```

---

## 4. System Ordering Pipeline

Every frame, your systems run in a fixed sequence. The order determines what data each system sees. Get it wrong and you get subtle bugs that only appear at specific frame rates or only on the first frame.

**The standard pipeline:**

```
InputSystem
  ↓  (produces: input state components)
AISystem
  ↓  (produces: intent components — where entities want to move)
MovementSystem / PhysicsSystem
  ↓  (produces: updated position components)
CollisionSystem
  ↓  (produces: hit events in the event queue)
DamageSystem
  ↓  (consumes: hit events, reduces health)
DeathSystem
  ↓  (consumes: low-health entities, defers destruction to CommandBuffer)
CommandBuffer.flush()
  ↓  (executes: all entity creation, deletion, component changes)
AnimationSystem
  ↓  (consumes: current state to pick animation frame)
RenderSystem
  ↓  (reads: final positions, draws everything)
EventBus.dispatch()
     (fires all subscribed handlers, clears the queue)
```

**What breaks when you get it wrong:**

| Wrong order | What you see |
|---|---|
| RenderSystem before MovementSystem | Entities render at last frame's position — 1-frame lag, noticeable at low FPS |
| DamageSystem before CollisionSystem | CollisionSystem hasn't emitted hit events yet; DamageSystem finds nothing to process; hits land one frame late |
| CommandBuffer.flush() before DeathSystem | DeathSystem tries to mark entities for death that may already be gone |
| EventBus.dispatch() mid-frame | Some systems see events from this frame, others don't; half-processed state |

**Declaring system order in tiny-ecs:**

tiny-ecs runs systems in the order they were added. Registration order is execution order:

```lua
-- Registration order = execution order
world:addSystem(InputSystem)
world:addSystem(AISystem)
world:addSystem(MovementSystem)
world:addSystem(CollisionSystem)
world:addSystem(DamageSystem)
world:addSystem(DeathSystem)
world:addSystem(AnimationSystem)
world:addSystem(RenderSystem)
```

**Priority-based ordering in a hand-rolled world:**

```lua
local World = {}
World.__index = World

function World.new()
    return setmetatable({ _systems = {} }, World)
end

function World:addSystem(system, priority)
    system._priority = priority or 0
    self._systems[#self._systems + 1] = system
    table.sort(self._systems, function(a, b)
        return a._priority < b._priority
    end)
end

-- Usage: lower number = runs first
world:addSystem(InputSystem,     10)
world:addSystem(MovementSystem,  30)
world:addSystem(CollisionSystem, 40)
world:addSystem(DamageSystem,    50)
world:addSystem(RenderSystem,    90)
```

**GDScript (Godot):**
```gdscript
# Godot processes nodes in scene tree order by default.
# Use _process() priority or explicit call ordering in a GameLoop node.

# Option 1: Use process priority (lower = earlier)
func _ready():
    input_system.process_priority = 10
    ai_system.process_priority = 20
    movement_system.process_priority = 30
    collision_system.process_priority = 40
    damage_system.process_priority = 50
    render_system.process_priority = 90

# Option 2: One GameLoop node calls systems explicitly
func _process(delta):
    input_system.tick(delta)
    ai_system.tick(delta)
    movement_system.tick(delta)
    collision_system.tick(delta)
    damage_system.tick(delta)
    command_buffer.flush()
    render_system.tick(delta)
```

---

## 5. Observer Pattern vs. Polling

Two strategies for reacting to changes in game state:

**Polling:** every frame, check the current value. If it crossed a threshold, react.

**Observer/Event:** when a value changes, emit an event. Subscribers react once, immediately.

**Pseudocode:**
```
-- Polling approach
every frame:
    if player.hp < 10:
        show low-health warning

-- Observer approach
when player.hp changes:
    emit "healthChanged" event with new hp
UISystem subscribes:
    if newHp < 10: show low-health warning
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Polling: simple but runs every frame even when health hasn't changed
function UISystem:update(dt)
    for _, id in ipairs(world:query("health", "player")) do
        local h = world:get(id, "health")
        if h.hp < 10 then
            self.lowHealthWarning:show()
        else
            self.lowHealthWarning:hide()
        end
    end
end

-- Observer: only reacts when health actually changes
bus:subscribe("healthChanged", function(data)
    if data.newHp < 10 then
        lowHealthWarning:show()
    else
        lowHealthWarning:hide()
    end
end)

-- HealthSystem must emit the event when health changes:
function HealthSystem:update(dt)
    for _, id in ipairs(world:query("health")) do
        local h = world:get(id, "health")
        local oldHp = h.hp
        -- ... apply pending damage ...
        if h.hp ~= oldHp then
            bus:emit("healthChanged", { entity = id, oldHp = oldHp, newHp = h.hp })
        end
    end
end
```

**GDScript (Godot):**
```gdscript
# Polling approach
func _process(delta):
    if player.hp < 10:
        low_health_warning.show()
    else:
        low_health_warning.hide()

# Observer approach using signals
# HealthComponent emits when value changes:
signal health_changed(old_hp, new_hp)

var _hp: int = 100:
    set(value):
        var old = _hp
        _hp = value
        if _hp != old:
            health_changed.emit(old, _hp)

# UISystem connects once:
func _ready():
    player.get_node("HealthComponent").health_changed.connect(_on_health_changed)

func _on_health_changed(old_hp, new_hp):
    if new_hp < 10:
        low_health_warning.show()
    else:
        low_health_warning.hide()
```

**Rule of thumb:**

- **Poll** things that change every frame anyway: position, velocity, animation timers. You're reading them regardless — no event overhead needed.
- **Use events** for things that happen occasionally: taking damage, dying, picking up an item, opening a door. Events fire once per occurrence; polling fires every frame whether or not anything changed.

The cost of polling is wasted CPU cycles on frames where nothing changed. The cost of events is the infrastructure to emit and subscribe, plus the requirement that the emitter knows when its data changes. For UI that reacts to rare game state, events win. For physics that runs every frame, polling wins.

---

## Code Walkthrough: Collision → Damage → Death with Deferred Delete

Here is a complete working example of the full pipeline. A bullet moves toward an enemy. Over five frames we trace exactly what each system does.

**Pseudocode for each system:**
```
MovementSystem:
    for each entity with (position, velocity):
        position.x += velocity.dx * dt
        position.y += velocity.dy * dt

CollisionSystem:
    for each (bullet, enemy) pair:
        if distance(bullet.pos, enemy.pos) < threshold:
            emit "hit" { target=enemy, damage=bullet.damage }
            cmd.destroyEntity(bullet)   -- bullet is spent

DamageSystem:
    subscribes to "hit":
        target.health.hp -= damage.amount

DeathSystem:
    for each entity with health:
        if health.hp <= 0:
            cmd.destroyEntity(entity)
```

**Lua (tiny-ecs / Love2D):**
```lua
local world   = World.new()  -- from Module 1's hand-rolled implementation
local bus     = EventBus.new()
local cmd     = CommandBuffer.new(world)

-- Create entities
local bulletId = world:newEntity()
world:add(bulletId, "position", { x = 0,  y = 0 })
world:add(bulletId, "velocity", { dx = 10, dy = 0 })
world:add(bulletId, "damage",   { amount = 3 })
world:add(bulletId, "bullet",   {})  -- tag

local enemyId = world:newEntity()
world:add(enemyId, "position", { x = 40, y = 0 })
world:add(enemyId, "health",   { hp = 5 })
world:add(enemyId, "enemy",    {})   -- tag

-- Subscribe DamageSystem to hit events
bus:subscribe("hit", function(data)
    if world:get(data.target, "health") then
        local h = world:get(data.target, "health")
        h.hp = h.hp - data.amount
        print(string.format("  [Damage] Enemy took %d dmg, hp=%d", data.amount, h.hp))
    end
end)

-- Systems as functions
local function movementSystem(dt)
    for _, id in ipairs(world:query("position", "velocity")) do
        local pos = world:get(id, "position")
        local vel = world:get(id, "velocity")
        pos.x = pos.x + vel.dx * dt
        pos.y = pos.y + vel.dy * dt
    end
end

local function collisionSystem()
    local bullets = world:query("bullet", "position", "damage")
    local enemies  = world:query("enemy",  "position", "health")
    for _, bid in ipairs(bullets) do
        local bpos = world:get(bid, "position")
        for _, eid in ipairs(enemies) do
            local epos = world:get(eid, "position")
            local dist = math.abs(bpos.x - epos.x) + math.abs(bpos.y - epos.y)
            if dist < 8 then
                local dmg = world:get(bid, "damage")
                bus:emit("hit", { target = eid, amount = dmg.amount })
                cmd:destroyEntity(bid)
                print(string.format("  [Collision] Bullet hit enemy at dist=%.1f", dist))
            end
        end
    end
end

local function deathSystem()
    for _, id in ipairs(world:query("health")) do
        local h = world:get(id, "health")
        if h and h.hp <= 0 then
            cmd:destroyEntity(id)
            print("  [Death] Entity " .. id .. " queued for death")
        end
    end
end

-- Game loop — 6 frames at dt=1 (bullet moves 10 units per frame)
for frame = 1, 6 do
    print("=== Frame " .. frame .. " ===")
    movementSystem(1)      -- move bullet: x += 10 per frame
    collisionSystem()      -- check bullet vs enemy
    deathSystem()          -- check dead entities
    cmd:flush()            -- execute deletions
    bus:dispatch()         -- fire "hit" handlers (DamageSystem reacts)
end
```

**Frame-by-frame trace:**

```
=== Frame 1 ===  bullet x=10  enemy x=40  dist=30  no collision
=== Frame 2 ===  bullet x=20  enemy x=40  dist=20  no collision
=== Frame 3 ===  bullet x=30  enemy x=40  dist=10  no collision
=== Frame 4 ===  bullet x=40  enemy x=40  dist=0   COLLISION
  [Collision] Bullet hit enemy at dist=0
  (cmd buffers: destroyEntity(bulletId))
  (bus buffers: "hit" event)
  DeathSystem: enemy hp=5, no death yet
  cmd:flush() → bullet destroyed
  bus:dispatch() → [Damage] Enemy took 3 dmg, hp=2
=== Frame 5 ===  bullet gone  enemy hp=2  no collision
=== Frame 6 ===  bullet gone  enemy hp=2  no collision
```

The trace makes ordering concrete: damage lands when `bus:dispatch()` runs — after `cmd:flush()`. If the bullet dealt 5+ damage in one hit, DeathSystem wouldn't catch it until frame 5 (since DamageSystem runs via bus dispatch after DeathSystem checked health). To fix: dispatch the bus before DeathSystem, or have DamageSystem write directly to health and DeathSystem run after in the same frame.

**GDScript (Godot):**
```gdscript
# GameLoop.gd
extends Node

signal hit_occurred(target_id, damage)

var world: IndexedWorld
var cmd_buffer = []
var event_queue = []

func _ready():
    world = IndexedWorld.new()

    # Subscribe DamageSystem to hit events
    hit_occurred.connect(_on_hit)

    # Create bullet
    var bullet = world.new_entity()
    world.add(bullet, "position", {"x": 0.0, "y": 0.0})
    world.add(bullet, "velocity", {"dx": 10.0, "dy": 0.0})
    world.add(bullet, "damage",   {"amount": 3})
    world.add(bullet, "bullet",   {})

    # Create enemy
    var enemy = world.new_entity()
    world.add(enemy, "position", {"x": 40.0, "y": 0.0})
    world.add(enemy, "health",   {"hp": 5})
    world.add(enemy, "enemy",    {})

func _process(delta):
    _movement_system(delta)
    _collision_system()
    _death_system()
    _flush_commands()
    _dispatch_events()

func _movement_system(dt: float):
    for id in world.query(["position", "velocity"]):
        var pos = world.get_component(id, "position")
        var vel = world.get_component(id, "velocity")
        pos["x"] += vel["dx"] * dt
        pos["y"] += vel["dy"] * dt

func _collision_system():
    var bullets = world.query(["bullet", "position", "damage"])
    var enemies  = world.query(["enemy",  "position", "health"])
    for bid in bullets:
        var bpos = world.get_component(bid, "position")
        var dmg  = world.get_component(bid, "damage")
        for eid in enemies:
            var epos = world.get_component(eid, "position")
            var dist = abs(bpos["x"] - epos["x"]) + abs(bpos["y"] - epos["y"])
            if dist < 8.0:
                event_queue.append({"type": "hit", "target": eid, "amount": dmg["amount"]})
                cmd_buffer.append(["destroy", bid])

func _death_system():
    for id in world.query(["health"]):
        var h = world.get_component(id, "health")
        if h and h["hp"] <= 0:
            cmd_buffer.append(["destroy", id])

func _flush_commands():
    for cmd in cmd_buffer:
        if cmd[0] == "destroy":
            world.destroy_entity(cmd[1])
    cmd_buffer.clear()

func _dispatch_events():
    for event in event_queue:
        if event["type"] == "hit":
            hit_occurred.emit(event["target"], event["amount"])
    event_queue.clear()

func _on_hit(target_id: int, damage: int):
    var h = world.get_component(target_id, "health")
    if h:
        h["hp"] -= damage
        print("Enemy took %d damage, hp=%d" % [damage, h["hp"]])
```

---

## Concept Quick Reference

| Concept | What it solves | Key rule |
|---|---|---|
| EventBus | System coupling | Emit into queue, dispatch after all systems run |
| CommandBuffer | Mid-iteration mutation | Never mutate the world during a query loop |
| System ordering | Stale data bugs | Data producers run before consumers |
| Deferred delete | Iterator invalidation | Collect, then destroy after the loop |
| Polling | Simple state checks | Use for things that change every frame |
| Observer/Event | Rare state changes | Use for things that happen occasionally |

---

## Common Pitfalls

**Dispatching the event bus mid-frame.** If you call `bus:dispatch()` between CollisionSystem and DamageSystem, DamageSystem misses hits from this frame. Dispatch once, at the end of the frame.

**Forgetting to clear the event queue.** Without clearing, events accumulate forever. Each hit gets processed an additional time every subsequent frame. Clear in `dispatch()`.

**Destroying entities without a CommandBuffer.** Works fine until you have a system that iterates 100 entities and deletes half of them — then you see random skips and nil errors. Always buffer.

**CommandBuffer.flush() order.** Flush after all systems have run their queries. If you flush mid-pipeline, a later system might query for an entity the CommandBuffer already deleted.

**System ordering by feel, not by data dependency.** Trace what data each system reads and writes. The system that writes a piece of data must run before the system that reads it. Draw the dependency graph if your pipeline is complex.

**Events that reference deleted entities.** CollisionSystem emits a hit event for entity 42. Before `bus:dispatch()` runs, DeathSystem marks entity 42 for deletion and `cmd:flush()` destroys it. DamageSystem then tries to get entity 42's health — it's gone. Guard with an existence check: `if world:get(data.target, "health") then`.

---

## Exercises

1. **Implement the EventBus** from scratch in Lua. Add a method `unsubscribe(eventType, handler)` that removes a specific handler. Test it by subscribing twice and unsubscribing once.

2. **Break the deferred delete intentionally.** Write a loop that calls `world:destroyEntity()` mid-iteration and observe what happens. Then fix it with the buffer pattern.

3. **Add a spawn-on-death command.** Extend the CommandBuffer with a `createEntity(components)` method. Modify the death pipeline so that when an enemy dies, a pickup entity is spawned at its position using the CommandBuffer.

4. **Trace a 3-system event chain.** Set up CollisionSystem → DamageSystem → UISystem (updates health bar on "healthChanged" event). Draw the exact sequence of emit/subscribe/dispatch calls across one frame where a collision happens.

5. **Break system ordering intentionally.** Swap RenderSystem and MovementSystem in the pipeline. Print positions each frame to observe the 1-frame lag. Restore correct order and verify it's fixed.

6. **Polling vs. events benchmark.** Implement a "low health warning" using polling. Then reimplement it using events. Add a frame counter to each approach and measure how many times the warning logic runs over 60 frames when the player takes damage only once.

---

## Key Takeaways

- **Events decouple systems.** CollisionSystem emits "hit." Everything else subscribes. No direct references between systems.
- **Never mutate the world mid-iteration.** Collect entities to destroy/modify in a buffer. Flush the buffer after all queries are done.
- **The CommandBuffer is your safety net** for all world mutations: destroy, addComponent, removeComponent, createEntity. Run `flush()` once per frame, after all systems.
- **System ordering is data flow.** Every system reads the output of the systems before it. Producers run before consumers. Draw it out when bugs appear.
- **Poll for continuous data, use events for discrete occurrences.** Velocity is continuous. Taking damage is discrete. Polling velocity is fine. Polling for damage is wasteful.
- **Dispatch the event bus once, at the end of the frame.** Dispatching mid-frame means some systems react this frame, others next frame — split-brain state.

---

## What's Next

[Module 4: Common ECS Patterns](module-04-common-ecs-patterns.md) — now that you understand communication between systems, learn the recurring design patterns every ECS project uses: tag components, singleton components, prefabs, parent-child relationships, and state machines via component swap.

Back to [ECS Learning Roadmap](ecs-learning-roadmap.md)
