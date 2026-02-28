# Module 4: Common ECS Patterns

**Part of:** [ECS Learning Roadmap](ecs-learning-roadmap.md)
**Estimated study time:** 3–4 hours
**Prerequisites:** [Module 3: Events, Communication & System Ordering](module-03-events-communication-system-ordering.md)

---

## Overview

By now you know how to create entities, attach components, write systems that query for them, and wire those systems together with events. The mechanics are in place. What this module covers is the vocabulary — the recurring patterns that show up in nearly every ECS codebase, regardless of language or framework. Once you recognize them, you'll stop reinventing solutions from scratch and start reaching for the right tool immediately.

These patterns are not exotic. Tag components, prefab functions, and singleton entities are straightforward ideas. The reason they're worth learning explicitly is that without names for them, developers tend to rediscover them slowly and inconsistently. You'll see one codebase using global variables for game state, another using a singleton entity, another storing everything in a god-object component. Naming the patterns lets you make deliberate choices and communicate those choices to collaborators.

The final section applies all six patterns to a concrete design problem: a top-down Zelda-like game. Walking through how every entity type in that game gets constructed — what components it uses, what patterns apply — builds the intuition for translating a game design document into an ECS architecture. That translation skill is what separates someone who understands ECS from someone who can actually ship a game with it.

---

## 1. Tag Components

A tag component is a component with no data. Its presence on an entity is the entire message.

`IsPlayer`, `IsEnemy`, `IsPoisoned`, `IsFlying`, `MarkedForDeletion` — these carry no fields. They don't need to. Systems use them as filters: "give me all entities that have `IsEnemy`." The tag is the information.

Why not just store a `type` field on every entity with values like `"player"`, `"flying_enemy"`, `"poisoned_player"`? Because types don't compose. If you add flying behavior, you need `FlyingPlayer`, `FlyingEnemy`, `FlyingBoss`. Add poisoned status and it multiplies again. With tags, you attach any combination of `IsPlayer`, `IsFlying`, `IsPoisoned` independently. The entity has all three properties without requiring a special name for that combination.

**Pseudocode:**
```
// Tags: components with no meaningful fields
component IsPlayer {}
component IsEnemy {}
component IsFlying {}
component IsPoisoned {}
component MarkedForDeletion {}

// Entity with multiple tags — composes freely
entity player {
    Position { x=100, y=200 }
    Velocity { vx=0, vy=0 }
    IsPlayer {}
    IsFlying {}
}

// System filters: only entities with ALL listed components pass
FlyingEnemySystem.filter = requires(Position, Velocity, IsEnemy, IsFlying)
PoisonTickSystem.filter   = requires(Health, IsPoisoned)
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Tags as booleans on entity table (tiny-ecs style)
local player = {}
player.position  = { x = 100, y = 200 }
player.velocity  = { vx = 0, vy = 0 }
player.isPlayer  = true   -- tag: no data, just presence
player.isFlying  = true   -- another tag
player.isPoisoned = true  -- status effect tag

world:addEntity(player)

-- Systems declare filters using tiny.requireAll / tiny.requireAny
local movementSystem = tiny.processingSystem()
movementSystem.filter = tiny.requireAll("position", "velocity")

local poisonSystem = tiny.processingSystem()
poisonSystem.filter = tiny.requireAll("health", "isPoisoned")
-- Only entities with BOTH health AND isPoisoned get processed

function poisonSystem:process(entity, dt)
    entity.health.hp = entity.health.hp - (5 * dt)
    if entity.health.hp <= 0 then
        entity.markedForDeletion = true  -- tag marking entity for cleanup
        world:removeEntity(entity)
    end
end

-- Removing a tag changes which systems process the entity immediately
local function cure(entity)
    entity.isPoisoned = nil  -- remove the tag
    world:removeEntity(entity)
    world:addEntity(entity)  -- re-register so tiny-ecs re-evaluates filters
end
```

**GDScript (Godot):**
```gdscript
# In Godot, node groups ARE tag components
# Groups are strings added to nodes — presence is the data

# Applying tags
func spawn_player() -> Node:
    var player = preload("res://player.tscn").instantiate()
    player.add_to_group("is_player")
    player.add_to_group("is_flying")
    add_child(player)
    return player

# Applying a status effect (adding a tag at runtime)
func apply_poison(entity: Node) -> void:
    entity.add_to_group("is_poisoned")

func cure_poison(entity: Node) -> void:
    entity.remove_from_group("is_poisoned")

# System equivalent: get all nodes with a tag
func _process(delta: float) -> void:
    # Process all poisoned entities
    for entity in get_tree().get_nodes_in_group("is_poisoned"):
        entity.health -= 5.0 * delta
        if entity.health <= 0:
            entity.queue_free()

    # Flying enemies specifically
    for entity in get_tree().get_nodes_in_group("is_flying"):
        if entity.is_in_group("is_enemy"):
            # only flying enemies
            update_flight(entity, delta)
```

---

## 2. Singleton Components

Global variables are the path of least resistance in small games and the source of debugging misery in large ones. Singleton components offer a structured alternative: one entity in the world holds a component that represents global state. Systems that need that state query for it.

Score, camera position, current level, input state, paused flag, elapsed time — anything that is truly "one per world" lives on a singleton entity. There is exactly one entity with the `GameState` component. Any system that needs the score queries for it, gets one result, reads it, done.

This keeps global state visible in the same system that manages everything else: your ECS world. It's testable (you can construct a test world with different singleton values), it's inspectable, and it eliminates the implicit coupling of module-level globals.

**Pseudocode:**
```
// One "world entity" holds global state
entity worldEntity {
    GameState {
        score = 0,
        level = 1,
        paused = false,
        camera = { x=0, y=0, zoom=1.0 }
    }
}

// Any system queries for it — exactly one result
ScoreSystem.update():
    gs = query(GameState)[0]   // one result
    gs.score += pointsEarned
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Create the singleton entity in love.load()
local worldEntity = {}
worldEntity.gameState = {
    score   = 0,
    level   = 1,
    paused  = false,
    camera  = { x = 0, y = 0, zoom = 1.0 },
    elapsed = 0,
}
world:addEntity(worldEntity)

-- A system that reads and writes global state
local scoreSystem = tiny.processingSystem()
scoreSystem.filter = tiny.requireAll("gameState")

function scoreSystem:process(entity, dt)
    -- entity here is the world entity
    entity.gameState.elapsed = entity.gameState.elapsed + dt
end

-- Another system queries for the singleton to read score
local hudSystem = tiny.processingSystem()
hudSystem.filter = tiny.requireAll("gameState")

function hudSystem:process(entity, dt)
    local gs = entity.gameState
    love.graphics.print("Score: " .. gs.score, 10, 10)
    love.graphics.print("Level: " .. gs.level, 10, 30)
end

-- Any system can also grab the singleton without a filter,
-- by storing a reference during world:onEntityAdded
local gameStateRef = nil

local stateTrackerSystem = tiny.system()
function stateTrackerSystem:onEntityAdded(entity)
    if entity.gameState then
        gameStateRef = entity.gameState
    end
end
```

**GDScript (Godot):**
```gdscript
# Godot already has this pattern built in: Autoload singletons
# Project Settings > Autoload > add GameState.gd as "GameState"

# res://GameState.gd
extends Node

var score: int = 0
var level: int = 1
var paused: bool = false
var camera_offset: Vector2 = Vector2.ZERO

func add_score(points: int) -> void:
    score += points

func reset() -> void:
    score = 0
    level = 1
    paused = false

# Any node accesses it directly — Godot injects it as a global name
# res://ScoreUI.gd
func _process(_delta: float) -> void:
    $ScoreLabel.text = "Score: %d" % GameState.score
    $LevelLabel.text = "Level: %d" % GameState.level
```

---

## 3. Prefabs / Entity Templates

Every time you construct an entity in three different places, those three places drift apart. One gets the `loot` component, one forgets it. One sets default speed to 60, one to 80. Prefabs solve this: one function per entity type, all defaults in one place.

A prefab is just a constructor function. Call it with position and any customization parameters, it returns a fully assembled entity. Spawning a goblin anywhere in the codebase is a one-liner.

Prefabs also compose. A `BossGoblin` prefab can call the `Goblin` prefab and then add extra components on top. A `FlyingGoblin` adds a `FlightController` component to the standard goblin. You get inheritance-like reuse without actual inheritance.

**Pseudocode:**
```
function spawnGoblin(world, x, y):
    e = world.newEntity()
    e.add(Position { x, y })
    e.add(Velocity { vx=0, vy=0, speed=60 })
    e.add(Health   { hp=30, maxHp=30 })
    e.add(Sprite   { sheet="goblin.png", frame=1 })
    e.add(AIBrain  { mode="patrol" })
    e.add(IsEnemy  {})
    e.add(Loot     { table="goblin_drops" })
    return e

function spawnBossGoblin(world, x, y):
    e = spawnGoblin(world, x, y)         // reuse base prefab
    e.add(BossPhase  { phase=1 })
    e.add(ExtraHealth { bonus=200 })
    e.add(PatternAttack { pattern="spin_throw" })
    e.health.hp    = 300
    e.health.maxHp = 300
    return e
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Base goblin prefab
local function spawnGoblin(world, x, y, overrides)
    overrides = overrides or {}
    local e = {}
    e.position = { x = x, y = y }
    e.velocity = { vx = 0, vy = 0, speed = overrides.speed or 60 }
    e.health   = { hp = overrides.hp or 30, maxHp = overrides.hp or 30 }
    e.sprite   = { sheet = "goblin.png", frame = 1, facing = "right" }
    e.aiState  = { mode = "patrol", timer = 0, target = nil }
    e.isEnemy  = true
    e.loot     = { table = "goblin_drops" }
    world:addEntity(e)
    return e
end

-- Boss goblin: builds on base prefab, overrides and adds
local function spawnBossGoblin(world, x, y)
    local e = spawnGoblin(world, x, y, { hp = 300, speed = 40 })
    -- Boss gets extra components
    e.bossPhase    = { phase = 1, phaseThresholds = { 0.6, 0.3 } }
    e.patternAttack = { pattern = "spin_throw", cooldown = 3.0, timer = 0 }
    e.isBoss       = true
    -- Re-register so tiny-ecs picks up new components
    world:removeEntity(e)
    world:addEntity(e)
    return e
end

-- Flying goblin: adds flight on top of base
local function spawnFlyingGoblin(world, x, y)
    local e = spawnGoblin(world, x, y)
    e.isFlying      = true
    e.flightControl = { altitude = 80, hoverVariance = 10, phase = 0 }
    world:removeEntity(e)
    world:addEntity(e)
    return e
end

-- Usage is a one-liner anywhere in the codebase
local g1 = spawnGoblin(world, 300, 200)
local g2 = spawnBossGoblin(world, 500, 300)
local g3 = spawnFlyingGoblin(world, 400, 150)
```

**GDScript (Godot):**
```gdscript
# In Godot, PackedScene is the native prefab system
# Design your Goblin in the editor, save as goblin.tscn — that IS the prefab

# res://entities/Goblin.tscn contains all default values in the inspector
# Spawning uses instantiate()
func spawn_goblin(position: Vector2) -> Node:
    var scene = preload("res://entities/Goblin.tscn")
    var goblin = scene.instantiate()
    goblin.global_position = position
    add_child(goblin)
    return goblin

# For programmatic customization, use a factory function that
# instantiates the scene and then modifies properties
func spawn_boss_goblin(position: Vector2) -> Node:
    var goblin = spawn_goblin(position)
    goblin.max_health = 300
    goblin.health = 300
    goblin.move_speed = 40.0
    # Add child nodes that represent extra components
    var boss_phase = preload("res://components/BossPhase.tscn").instantiate()
    goblin.add_child(boss_phase)
    var pattern_attack = preload("res://components/PatternAttack.tscn").instantiate()
    goblin.add_child(pattern_attack)
    goblin.add_to_group("is_boss")
    return goblin
```

---

## 4. Parent-Child Relationships

Some entities only make sense relative to another entity. A sword belongs to the player. A health bar floats above an enemy. A particle emitter is attached to an explosion. These relationships need a data structure, and ECS offers two approaches.

**Approach A: Parent stores a children list.** Good when you need to traverse downward — find all things attached to an entity.

**Approach B: Child stores a parent reference.** Good when children need to know who owns them, and for transform inheritance.

In practice, use both simultaneously. The parent knows its children; each child knows its parent. The redundancy is intentional — lookups go both directions without searching.

**Pseudocode:**
```
// Both directions stored simultaneously
parent.Children = [child1, child2]
child1.Parent   = parent
child2.Parent   = parent

// Transform inheritance: child world position = parent position + local offset
TransformSystem:
    for each entity with (Position, Parent):
        parentPos = entity.Parent.Position
        entity.worldX = parentPos.x + entity.localX
        entity.worldY = parentPos.y + entity.localY
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Attach a sword to a player
local function attachToParent(world, child, parent, localX, localY)
    child.parent   = { entity = parent }
    child.localPos = { x = localX or 0, y = localY or 0 }

    if not parent.children then
        parent.children = {}
    end
    table.insert(parent.children, child)

    -- Re-register both so filters update
    world:removeEntity(child)
    world:addEntity(child)
end

-- Example: sword attached to player at offset (12, 0)
local sword = spawnSword(world)
attachToParent(world, sword, player, 12, 0)

-- Transform propagation system — runs before rendering
local transformSystem = tiny.processingSystem()
transformSystem.filter = tiny.requireAll("position", "localPos", "parent")

function transformSystem:process(entity, dt)
    local parentEntity = entity.parent.entity
    if parentEntity and parentEntity.position then
        local px = parentEntity.position.x
        local py = parentEntity.position.y
        -- World position = parent position + local offset (respects facing direction)
        local facing = parentEntity.facing or 1  -- 1 = right, -1 = left
        entity.position.x = px + (entity.localPos.x * facing)
        entity.position.y = py + entity.localPos.y
    end
end

-- Cleanup: when parent is removed, queue children for deletion
local function removeWithChildren(world, entity)
    if entity.children then
        for _, child in ipairs(entity.children) do
            removeWithChildren(world, child)  -- recursive
        end
    end
    world:removeEntity(entity)
end
```

**GDScript (Godot):**
```gdscript
# Godot's scene tree IS a parent-child system
# add_child() establishes the relationship natively
# Child transform is automatically relative to parent

func attach_sword_to_player(player: Node2D) -> Node2D:
    var sword = preload("res://entities/Sword.tscn").instantiate()
    player.add_child(sword)
    # Position is now relative to player automatically
    sword.position = Vector2(12, 0)
    return sword

# To traverse children:
func get_equipped_items(player: Node2D) -> Array:
    return player.get_children().filter(func(c): return c.is_in_group("equippable"))

# To find parent from a child:
func get_owner_player(item: Node) -> Node:
    var parent = item.get_parent()
    if parent and parent.is_in_group("is_player"):
        return parent
    return null

# Removing parent removes all children automatically — free() cascades
func kill_entity(entity: Node) -> void:
    entity.queue_free()  # children go with it
```

---

## 5. Ephemeral / One-Frame Components

Some information only matters right now, this frame. "The player just landed." "This enemy just took damage." "Input was pressed this frame." Storing that as persistent state creates bugs — you have to remember to clear it. Making it an event means wiring up dispatch and handlers. The middle path: ephemeral components.

Add the component. Systems process it during this frame's update. A cleanup system at the end of frame removes it. Next frame, it's gone. Clean, automatic, self-documenting.

The rule: ephemeral components are added and removed within one update cycle. The cleanup system must run last, after all systems that consume the ephemeral data.

**Pseudocode:**
```
// Frame N:
GroundCheckSystem adds JustLanded to entity
LandingSoundSystem reads JustLanded, plays sound
LandingAnimSystem reads JustLanded, triggers anim
CleanupSystem removes all JustLanded  // runs last

// Frame N+1:
JustLanded does not exist — no systems fire for it
```

**Lua (tiny-ecs / Love2D):**
```lua
-- Ground check: adds JustLanded when entity first touches ground
local groundCheckSystem = tiny.processingSystem()
groundCheckSystem.filter = tiny.requireAll("position", "velocity")

function groundCheckSystem:process(entity, dt)
    local onGround = entity.position.y >= GROUND_Y and entity.velocity.vy >= 0
    local wasOnGround = entity.wasOnGround

    if onGround and not wasOnGround then
        -- Just landed this frame
        entity.justLanded = { time = love.timer.getTime(), impactVelocity = entity.velocity.vy }
        -- Re-add so tiny-ecs registers the new component
        world:removeEntity(entity)
        world:addEntity(entity)
    end

    entity.wasOnGround = onGround
    if onGround then entity.velocity.vy = 0 end
end

-- Sound system reacts to JustLanded — only processes entities that have it
local landingSoundSystem = tiny.processingSystem()
landingSoundSystem.filter = tiny.requireAll("justLanded")

function landingSoundSystem:process(entity, dt)
    local impact = entity.justLanded.impactVelocity
    if impact > 300 then
        love.audio.play(heavyLandSound)
    else
        love.audio.play(landSound)
    end
end

-- Animation system also reacts
local landingAnimSystem = tiny.processingSystem()
landingAnimSystem.filter = tiny.requireAll("justLanded", "sprite")

function landingAnimSystem:process(entity, dt)
    entity.sprite.animation = "land"
    entity.sprite.frame = 1
end

-- Cleanup system: MUST run after all consumers
-- Register this system last in world:add() order
local ephemeralCleanupSystem = tiny.processingSystem()
ephemeralCleanupSystem.filter = tiny.requireAll("justLanded")

function ephemeralCleanupSystem:process(entity, dt)
    entity.justLanded = nil
    world:removeEntity(entity)
    world:addEntity(entity)
end

-- Other ephemeral components follow the same pattern:
-- JustDamaged { amount, source }  → damage flash, sound, knockback
-- JustSpawned {}                  → spawn animation, invincibility frames
-- JustPickedUp { item }           → pickup sound, inventory update
-- FrameInput { dx, dy, jump, attack }  → this frame's raw input, cleared next frame
```

**GDScript (Godot):**
```gdscript
# Ephemeral behavior in Godot: use signals or a one-frame flag pattern

# Option A: Groups as ephemeral tags (cleared at end of frame)
func _physics_process(delta: float) -> void:
    # Phase 1: detect and apply ephemeral tags
    for entity in get_tree().get_nodes_in_group("has_velocity"):
        if is_just_landing(entity):
            entity.add_to_group("just_landed")

    # Phase 2: consume ephemeral tags
    for entity in get_tree().get_nodes_in_group("just_landed"):
        $AudioPlayer.play()
        entity.get_node("AnimationPlayer").play("land")

    # Phase 3: clean up ephemeral tags (end of frame)
    for entity in get_tree().get_nodes_in_group("just_landed"):
        entity.remove_from_group("just_landed")

# Option B (more Godot-idiomatic): use call_deferred to schedule cleanup
func mark_just_landed(entity: Node) -> void:
    entity.add_to_group("just_landed")
    # Automatically remove at end of this frame
    entity.call_deferred("remove_from_group", "just_landed")
```

---

## 6. State Components: Behavior via Component Swap

Traditional state machines encode state as an enum: `state = WALKING`, then a switch-case in every system to branch on the current state. As states multiply, switch-cases grow, and every system has to know about every state even if it only cares about one.

State components flip this around. Each state is a component. Walking is represented by having a `Walking` component. Jumping means having a `Jumping` component. Systems filter for the state they care about and are simply not called for entities in other states.

Transitioning states is an explicit operation: remove the current state component, add the new one. Systems that filter for the old state stop processing that entity immediately. Systems that filter for the new state start immediately.

**Pseudocode:**
```
// States as components — mutually exclusive by convention
Walking  { speed }
Jumping  { verticalVel, hangTime }
Falling  { fallAccel }
Attacking { damageFrame, duration, comboCount }
Stunned  { duration, remaining }

// WalkSystem only processes walking entities
WalkSystem.filter = requires(Position, Velocity, Walking)

// Transition: player presses jump while walking
if entity has Walking and jumpPressed:
    speed = entity.Walking.speed
    remove Walking from entity
    add Jumping { verticalVel=-400, speed=speed } to entity
    // JumpSystem now picks up this entity; WalkSystem drops it
```

**Lua (tiny-ecs / Love2D):**
```lua
-- State components: plain tables on the entity
-- Convention: only one state component active at a time

-- Walking state system
local walkSystem = tiny.processingSystem()
walkSystem.filter = tiny.requireAll("position", "velocity", "walking")

function walkSystem:process(entity, dt)
    local dx = 0
    if love.keyboard.isDown("left")  then dx = -1 end
    if love.keyboard.isDown("right") then dx =  1 end
    entity.velocity.vx = dx * entity.walking.speed
    entity.velocity.vy = 0  -- grounded

    -- Transition to jumping
    if love.keyboard.isDown("space") then
        local speed = entity.walking.speed
        entity.walking = nil                           -- remove walk state
        entity.jumping = {                             -- add jump state
            verticalVel = -400,
            speed       = speed,
            hangTime    = 0.15,
            hangTimer   = 0,
        }
        world:removeEntity(entity)
        world:addEntity(entity)  -- re-register filters
    end

    -- Transition to attacking
    if love.keyboard.isDown("z") then
        local speed = entity.walking.speed
        entity.walking = nil
        entity.attacking = { duration = 0.4, elapsed = 0, damageDealt = false }
        world:removeEntity(entity)
        world:addEntity(entity)
    end
end

-- Jumping state system
local jumpSystem = tiny.processingSystem()
jumpSystem.filter = tiny.requireAll("position", "velocity", "jumping")

function jumpSystem:process(entity, dt)
    local j = entity.jumping

    -- Horizontal movement preserved from walk speed
    local dx = 0
    if love.keyboard.isDown("left")  then dx = -1 end
    if love.keyboard.isDown("right") then dx =  1 end
    entity.velocity.vx = dx * j.speed

    -- Apply vertical velocity
    entity.velocity.vy = entity.velocity.vy + (GRAVITY * dt)

    -- Hang time at apex: slow fall briefly at top of arc
    if math.abs(entity.velocity.vy) < 50 then
        j.hangTimer = j.hangTimer + dt
        if j.hangTimer < j.hangTime then
            entity.velocity.vy = entity.velocity.vy * 0.85
        end
    end

    -- Transition to falling when moving downward
    if entity.velocity.vy > 100 then
        entity.jumping = nil
        entity.falling = { fallAccel = 900 }
        world:removeEntity(entity)
        world:addEntity(entity)
    end

    -- Transition to landed (walking) when hitting ground
    if entity.position.y >= GROUND_Y then
        entity.position.y = GROUND_Y
        entity.velocity.vy = 0
        entity.jumping = nil
        entity.walking = { speed = 150 }
        entity.justLanded = { time = love.timer.getTime() }
        world:removeEntity(entity)
        world:addEntity(entity)
    end
end

-- Attacking state system
local attackSystem = tiny.processingSystem()
attackSystem.filter = tiny.requireAll("position", "attacking")

function attackSystem:process(entity, dt)
    local a = entity.attacking
    a.elapsed = a.elapsed + dt

    -- Lock velocity during attack
    entity.velocity.vx = 0
    entity.velocity.vy = 0

    -- Deal damage at the damage frame
    if a.elapsed >= 0.1 and not a.damageDealt then
        a.damageDealt = true
        checkMeleeHit(entity)
    end

    -- Transition back to walking when attack ends
    if a.elapsed >= a.duration then
        entity.attacking = nil
        entity.walking   = { speed = 150 }
        world:removeEntity(entity)
        world:addEntity(entity)
    end
end
```

**GDScript (Godot):**
```gdscript
# State components in Godot: child nodes as state components
# Each state is a Node that gets added/removed from the entity

# res://states/Walking.gd
class_name WalkingState
extends Node

var speed: float = 150.0

func _physics_process(delta: float) -> void:
    var entity = get_parent()
    var dx = Input.get_axis("move_left", "move_right")
    entity.velocity.x = dx * speed
    entity.velocity.y = 0

    if Input.is_action_just_pressed("jump"):
        # Transition to jumping
        var jump_state = preload("res://states/Jumping.tscn").instantiate()
        jump_state.speed = speed
        queue_free()                     # remove this state
        entity.add_child(jump_state)     # add new state

    entity.move_and_slide()

# Transition function (can live on entity or in a StateMachine helper)
func transition_to(entity: CharacterBody2D, new_state_scene: PackedScene) -> void:
    # Remove all current state nodes
    for child in entity.get_children():
        if child.is_in_group("state_component"):
            child.queue_free()
    # Add the new state
    var new_state = new_state_scene.instantiate()
    new_state.add_to_group("state_component")
    entity.add_child(new_state)
```

---

## Code Walkthrough: Zelda-Like Entity Design

Let's design a top-down Zelda-like with: a player, melee enemy, ranged enemy, boss, heart pickups, keys, locked doors, destructible pots, and a HUD. Every entity gets mapped to components, and we identify which patterns apply.

### Component Map

| Entity | Components | Patterns Used |
|---|---|---|
| Player | Position, Velocity, Health, Sprite, Walking/Jumping (state), Inventory, Interactable, Children | State swap, Parent-child, Tag |
| MeleeEnemy | Position, Velocity, Health, Sprite, AIBrain{patrol}, IsEnemy, Loot | Tag, Prefab |
| RangedEnemy | + ProjectileSpawner{cooldown, range} | Prefab composition |
| Boss | + BossPhase, PatternAttack, IsBoss | Prefab composition, Tag |
| Heart | Position, Sprite, Pickup{type=heart,value=1}, Interactable | Tag, Ephemeral (JustPickedUp) |
| Key | Position, Sprite, Pickup{type=key}, Interactable | Tag |
| Door | Position, Sprite, DoorState{locked=true}, Interactable, RequiresKey | State component (locked/unlocked) |
| Pot | Position, Sprite, Health{hp=1}, Destructible, Loot{table=pot_drops} | Tag (no IsEnemy!), Prefab |
| HUD | Singleton GameState{hearts, keys, rupees} | Singleton |

Note the pot: it has `Health` and `Destructible` but **not** `IsEnemy`. The `DamageSystem` checks for `Health`, not `IsEnemy`. The `LootSystem` checks for `Loot` on death. Neither system needs to know what type of entity it's processing. This is the compositional payoff.

### Prefab Functions

```lua
-- Player prefab
local function spawnPlayer(world, x, y)
    local e = {}
    e.position    = { x = x, y = y }
    e.velocity    = { vx = 0, vy = 0 }
    e.health      = { hp = 6, maxHp = 6 }   -- 3 hearts = 6 half-hearts
    e.sprite      = { sheet = "link.png", frame = 1, facing = "down" }
    e.walking     = { speed = 120 }          -- initial state component
    e.inventory   = { keys = 0, rupees = 0, items = {} }
    e.interactable = true                    -- can interact with doors/pickups
    e.isPlayer    = true                     -- tag
    e.children    = {}                       -- will hold sword, shield

    world:addEntity(e)

    -- Attach sword as child entity
    local sword = spawnSword(world, e)
    attachToParent(world, sword, e, 14, 0)

    return e
end

-- Melee enemy prefab
local function spawnMeleeEnemy(world, x, y, overrides)
    overrides = overrides or {}
    local e = {}
    e.position = { x = x, y = y }
    e.velocity = { vx = 0, vy = 0 }
    e.health   = { hp = overrides.hp or 2, maxHp = overrides.hp or 2 }
    e.sprite   = { sheet = overrides.sheet or "moblin.png", frame = 1, facing = "down" }
    e.aiState  = { mode = "patrol", target = nil, timer = 0, detectionRange = overrides.detection or 100 }
    e.isEnemy  = true                        -- tag: combat systems recognize this
    e.loot     = { table = overrides.lootTable or "enemy_drops" }
    world:addEntity(e)
    return e
end

-- Ranged enemy: composes on melee base
local function spawnRangedEnemy(world, x, y)
    local e = spawnMeleeEnemy(world, x, y, {
        hp = 3,
        sheet = "archer.png",
        detection = 150,
        lootTable = "ranged_drops",
    })
    -- Extra component: can spawn projectiles
    e.projectileSpawner = {
        cooldown   = 2.0,
        timer      = 0,
        range      = 140,
        projectile = "arrow",
    }
    world:removeEntity(e)
    world:addEntity(e)
    return e
end

-- Destructible pot: has health, no IsEnemy tag
local function spawnPot(world, x, y)
    local e = {}
    e.position     = { x = x, y = y }
    e.sprite       = { sheet = "objects.png", frame = 3 }
    e.health       = { hp = 1, maxHp = 1 }
    e.destructible = true   -- tag: plays shatter effect on death instead of death animation
    e.loot         = { table = "pot_drops" }
    world:addEntity(e)
    return e
end

-- HUD / Singleton: created once in game init
local function createWorldState(world)
    local e = {}
    e.gameState = {
        hearts      = 3,
        maxHearts   = 3,
        keys        = 0,
        rupees      = 0,
        currentRoom = "room_01",
        bossDefeated = false,
    }
    world:addEntity(e)
    return e
end
```

### The Interaction System

The `Interactable` tag enables a single system to handle player contact with hearts, keys, and doors without special-casing each type:

```lua
local interactSystem = tiny.processingSystem()
interactSystem.filter = tiny.requireAll("position", "interactable", "pickup")

function interactSystem:process(entity, dt)
    -- Check if player overlaps this pickup
    if not player or not player.position then return end
    local dx = player.position.x - entity.position.x
    local dy = player.position.y - entity.position.y
    if (dx*dx + dy*dy) < 400 then  -- within 20px
        if entity.pickup.type == "heart" then
            local gs = getGameState(world)
            gs.hearts = math.min(gs.hearts + entity.pickup.value, gs.maxHearts)
        elseif entity.pickup.type == "key" then
            local gs = getGameState(world)
            gs.keys = gs.keys + 1
        end
        -- Ephemeral: mark as just picked up, then remove
        entity.justPickedUp = { type = entity.pickup.type }
        world:removeEntity(entity)
        world:addEntity(entity)
    end
end
```

---

## Concept Quick Reference

| Pattern | What It Is | When To Use |
|---|---|---|
| Tag component | Component with no data; presence is the signal | Categorizing entities, status effects, filter flags |
| Singleton component | One entity holds world-global state | Score, camera, level state, settings |
| Prefab | Constructor function for a complete entity | Any entity type created more than once |
| Parent-child | Entity links to owner/children | Equipped items, UI attached to entities, transform hierarchy |
| Ephemeral component | Lives exactly one frame, then cleaned up | One-time events, per-frame input, landing/spawn reactions |
| State component | State represented by which component is present | Player state machine, AI behavior modes, door locked/unlocked |

---

## Common Pitfalls

**Forgetting to re-register after mutation.** In tiny-ecs and many ECS libraries, the filter is evaluated when an entity is added. If you add or remove a component directly on the table without calling `removeEntity`/`addEntity`, the system's filter cache is stale. The entity keeps showing up in the wrong systems.

**Multiple state components active simultaneously.** If your transition logic has a bug that adds `Jumping` without removing `Walking`, both systems process the entity. The result is usually nonsensical: walking speed overrides jump velocity on the same frame. Add assertions in development: `assert(not entity.jumping, "Transition error: walking state added to already-jumping entity")`.

**Prefabs that copy references instead of cloning.** If your prefab does `e.health = GOBLIN_DEFAULTS.health`, every goblin shares the same health table. Damage to one damages all of them. Always construct fresh tables in prefabs: `e.health = { hp = 30, maxHp = 30 }`.

**Ephemeral components not cleaned up.** If the cleanup system crashes, skips, or runs before consumers instead of after, ephemeral components accumulate or go unread. Make cleanup the last registered system and add a safeguard: log a warning if an ephemeral component is more than two frames old.

**Overusing singleton components.** Not every shared value needs a singleton entity. Constants and config that never change at runtime are fine as module-level variables. Reserve singleton components for mutable runtime state that systems need to read and write.

**Parent-child cycles.** If entity A lists B as a child and B lists A as a child, your transform system will recurse infinitely. Use depth-limited traversal or track visited entities when walking the hierarchy.

---

## Exercises

1. **Tag composition drill.** Design the full tag set for a game with: player, enemy soldier, flying enemy, poisoned enemy, invisible enemy, boss, NPC, destructible crate, and collectible coin. Use only tags (no type fields). Verify that any query you'd want to write can be expressed as a combination of tags.

2. **Prefab with inheritance.** Write a `spawnZombie` prefab. Then write `spawnFastZombie` (calls `spawnZombie`, doubles speed), `spawnArmoredZombie` (doubles health, adds `isArmored` tag), and `spawnBossZombie` (armored + fast + adds a `BossPhase` component). All three call `spawnZombie` at their base.

3. **Ephemeral chain.** Implement a complete `JustDamaged` ephemeral system: one system adds it when an entity takes a hit, a second system triggers a red flash on `Sprite`, a third triggers a knockback impulse on `Velocity`, and a fourth plays a hurt sound. A fifth system cleans up at end of frame. Make sure system order is correct.

4. **State machine conversion.** Take a simple three-state machine (Idle/Walking/Running) implemented as an enum with a switch-case. Rewrite it using state components. Measure how many lines each system is versus the original monolithic switch.

5. **Zelda extension.** Add a `Boomerang` entity to the Zelda-like design. It's thrown by the player, travels in a straight line, reverses direction after a maximum range, returns to the player, and gets picked up when it reaches the player. Identify which patterns apply and what components it needs. Bonus: it can stun enemies it hits — how does that interact with the state component pattern?

---

## Key Takeaways

- **Tags** express presence as information. Use them to categorize entities and compose behaviors without combinatorial type explosion.
- **Singleton components** are the ECS equivalent of well-structured global state — visible to the system, not a hidden module variable.
- **Prefabs** centralize entity construction. Complex entity types compose simpler prefabs. One function per entity type.
- **Parent-child** relationships work best bidirectional. Parents know their children; children know their parent. Transform inheritance is a natural consequence.
- **Ephemeral components** are a lightweight alternative to events for one-frame reactions. They require a cleanup system that runs last.
- **State components** beat enum state machines at scale. Each state is self-contained, transitions are explicit, and systems are smaller and focused.

The patterns in this module are not framework-specific. You'll recognize them in Unity ECS, Bevy, Flecs, and hand-rolled systems. The names and exact API calls differ; the structure is the same.

---

## What's Next

[Module 5: Data-Oriented Design & Performance](module-05-data-oriented-design-performance.md) — understand cache lines, SoA vs AoS, and why ECS is inherently fast. Optional if you're more interested in building games than optimizing them — skip to Module 6 if you want to see real frameworks now.

Back to [ECS Learning Roadmap](ecs-learning-roadmap.md)
