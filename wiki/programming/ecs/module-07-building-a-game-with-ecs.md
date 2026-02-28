# Module 7: Building a Game with ECS (Capstone)

**Part of:** [ECS Learning Roadmap](ecs-learning-roadmap.md)
**Estimated study time:** 20–40 hours
**Prerequisites:** Module 6 — Events, Messaging, and System Coordination

---

## Overview

This is the module where everything clicks. You've learned components, systems, queries, events, and system ordering. Now you're going to put all of it together and actually ship something.

The capstone is a Vampire Survivors-style arena game. It has enough complexity to exercise every ECS concept you've learned — spawning waves of enemies, auto-firing weapons, collecting XP orbs, leveling up — but it's scoped tightly enough that you can build an MVP in a few weeks without losing your mind.

The most important skill you'll build here isn't code. It's discipline: writing the design doc before a single line of code, using prefabs consistently, cutting scope ruthlessly, and shipping a thing that runs. That discipline is what separates ECS practitioners from ECS hobbyists.

---

## 1. Architecture Planning Before Coding

Jumping straight to code is the fastest way to end up with a tangled mess that's hard to debug and impossible to extend. ECS gives you a clean architecture — but only if you plan it first.

Before writing a single line of code, write a **5-section ECS design doc**. It takes 30–60 minutes and saves days of refactoring.

**The 5-Section ECS Design Doc:**

1. **Genre and concept** — One paragraph. What is the game? What does the player do every second?
2. **Component list** — Every piece of data. Name, type, what it means.
3. **System list + ordering** — Every system, in pipeline order. What each one reads and writes.
4. **Event types** — Every event that crosses system boundaries.
5. **Prefab list** — Every factory function. What each one creates.

If you can't fill out all five sections, you don't understand your game yet. That's valuable information — figure it out on paper, not in code.

**Example: Pong Design Doc (abbreviated)**

| Section | Content |
|---|---|
| Genre/Concept | Two-player paddle game. Players move paddles up/down. Ball bounces. Score on miss. |
| Components | Position, Velocity, Sprite, PaddleInput (player_id), BallTag, ScoreTag (side), CollisionBox |
| Systems | Input → MovePaddles → MoveBall → CollisionDetection → ScoreCheck → Render → HUD |
| Events | `ball_scored {side}`, `game_over {winner}` |
| Prefabs | createBall(), createPaddle(side), createWall(side) |

Pong fits on one index card. That's the goal. If your design doc is 20 pages for a first project, you've scoped too large.

**Pseudocode:**
```
function write_design_doc(game_idea):
    1. describe what player does every second (genre)
    2. list every noun in the game -> components
    3. list every verb in the game -> systems
    4. list every cross-system notification -> events
    5. list every entity template -> prefabs
    if any section is blank -> you need more thinking, not more code
```

**Lua (Love2D with tiny-ecs or Concord):**
```lua
-- design_doc.lua is not code — it's a comment file you write first
-- Example structure (just a Lua table you use as a reference):

local design = {
    concept = "Top-down arena survival. Player auto-fires. Enemies swarm. Collect XP.",

    components = {
        "Position", "Velocity", "Sprite", "Health", "MaxHealth",
        "Damage", "Team", "AutoFire", "Weapon", "PlayerInput",
        "PlayerStats", "EnemyAI", "CollisionRadius", "ExperienceValue",
        "ExperienceOrb", "MarkedForDeletion", "SpawnTimer", "Wave", "Score"
    },

    systems = {
        "InputSystem", "MovementSystem", "EnemyAISystem", "AutoFireSystem",
        "BulletMovementSystem", "CollisionSystem", "DamageSystem",
        "HealthCheckSystem", "DeathSpawnSystem", "EXPOrbSystem",
        "ExperienceCollectionSystem", "LevelUpSystem", "WaveSpawnSystem",
        "AnimationSystem", "CameraSystem", "RenderSystem", "HUDSystem",
        "CleanupSystem"
    },

    events = { "hit", "death", "level_up", "wave_start", "game_over" },

    prefabs = {
        "createPlayer", "createEnemy", "createBullet",
        "createExplosion", "createXPOrb", "createWall", "createPickup"
    }
}

-- Read this table constantly while coding. Update it when things change.
return design
```

**GDScript (Godot):**
```gdscript
# design_doc.gd — a reference resource, not runtime code
# In Godot you might keep this as a comment block at the top of your ECS world script

# CONCEPT: Top-down arena survival. Player auto-fires. Enemies swarm. Collect XP.

# COMPONENTS:
# Position, Velocity, Sprite, Health, MaxHealth, Damage, Team,
# AutoFire, Weapon, PlayerInput, PlayerStats, EnemyAI, CollisionRadius,
# ExperienceValue, ExperienceOrb, MarkedForDeletion, SpawnTimer, Wave, Score

# SYSTEMS (in order):
# InputSystem -> MovementSystem -> EnemyAISystem -> AutoFireSystem ->
# BulletMovementSystem -> CollisionSystem -> DamageSystem ->
# HealthCheckSystem -> DeathSpawnSystem -> EXPOrbSystem ->
# ExperienceCollectionSystem -> LevelUpSystem -> WaveSpawnSystem ->
# AnimationSystem -> CameraSystem -> RenderSystem -> HUDSystem -> CleanupSystem

# EVENTS: hit, death, level_up, wave_start, game_over

# PREFABS: create_player, create_enemy, create_bullet,
#          create_explosion, create_xp_orb, create_wall, create_pickup
```

---

## 2. Genre and Scope Selection

ECS is not the right tool for every game. Picking the right scope for your first ECS project is the difference between shipping and giving up.

**Scope Table:**

| Game Type | Scope | Time Estimate | ECS Fit |
|---|---|---|---|
| Pong | Tiny | 1 day | Overkill, but good practice |
| Space Shooter | Small | 1 week | Excellent first project |
| Bullet Hell | Small-Medium | 2–3 weeks | ECS shines here |
| Vampire Survivors clone | Medium | 1–2 months | Sweet spot for ECS |
| Roguelike (full) | Large | 3–6 months | ECS helps, but scope is dangerous |
| RPG with narrative | Large | 6+ months | ECS for combat only, keep narrative separate |

**ECS shines when:**
- You have many similar entities (100 enemies, 500 bullets)
- Entities need dynamic composition (enemies that pick up weapons, players that mutate)
- Performance matters (archetype ECS can be cache-friendly)
- You want to swap behavior via component add/remove instead of inheritance chains

**ECS adds overhead when:**
- You have fewer than 10 entity types and they never change
- Your game is mostly UI, cutscenes, or narrative scripting
- You're prototyping something throwaway

**For your first ECS game, pick a space shooter or bullet-hell.** The entity types are obvious (player, enemy, bullet, pickup), the systems are clear, and there's no ambiguity about what goes in ECS vs what lives outside it.

**Pseudocode:**
```
function should_i_use_ecs(game):
    if game.entity_count > 50 -> yes
    if game.entity_types_share_behavior -> yes
    if game.entities_mutate_at_runtime -> yes
    if game.is_mostly_menus_and_dialogue -> no
    if game.is_a_prototype -> maybe, keep it simple
```

**Lua (Love2D with tiny-ecs or Concord):**
```lua
-- No code needed here — this is a planning decision.
-- But here's a quick gut-check function you can keep in a dev console:

local function scope_check(entity_type_count, max_entities_at_once)
    if entity_type_count < 5 and max_entities_at_once < 20 then
        print("WARNING: ECS may be overkill. Consider plain OOP tables.")
    elseif max_entities_at_once > 200 then
        print("ECS is a good fit. Consider archetype ECS for performance.")
    else
        print("ECS is fine. Standard bitset or sparse-set will work.")
    end
end

scope_check(8, 500) -- "ECS is a good fit."
```

**GDScript (Godot):**
```gdscript
# Same concept — just a planning note. In Godot, you might use this
# as a quick sanity check in your project planning doc.

func scope_check(entity_type_count: int, max_entities: int) -> void:
    if entity_type_count < 5 and max_entities < 20:
        push_warning("ECS may be overkill for this scope.")
    elif max_entities > 200:
        print("ECS is a strong fit. Consider FECS or a custom archetype approach.")
    else:
        print("ECS is fine. Standard approach works.")
```

---

## 3. Prefab-Driven Entity Creation

A prefab is a factory function that creates a fully configured entity. The rule is simple: **all entity creation goes through prefabs, always.**

No `world:entity()` calls scattered across your game logic. No partially-constructed entities. One function, one entity type, one place to change it.

Prefabs take a `world` (and optional config), create the entity, attach components, and return the entity ID. That's it. They do not contain game logic. They do not fire events. They do not call other systems.

**Pseudocode:**
```
function createEnemy(world, config):
    e = world.new_entity()
    attach Position{x=config.x, y=config.y} to e
    attach Velocity{vx=0, vy=0} to e
    attach Health{hp=config.hp or 30} to e
    attach MaxHealth{max=config.hp or 30} to e
    attach Damage{amount=config.damage or 10} to e
    attach Team{id="enemy"} to e
    attach EnemyAI{target=nil, state="chase"} to e
    attach Sprite{image=config.sprite or "enemy_basic"} to e
    attach CollisionRadius{r=12} to e
    return e
```

**Lua (Love2D with tiny-ecs or Concord):**
```lua
-- prefabs.lua

local Prefabs = {}

-- Components (defined elsewhere, imported here)
local Position = require("components.position")
local Velocity = require("components.velocity")
local Health = require("components.health")
local MaxHealth = require("components.max_health")
local Damage = require("components.damage")
local Team = require("components.team")
local AutoFire = require("components.auto_fire")
local Weapon = require("components.weapon")
local PlayerInput = require("components.player_input")
local PlayerStats = require("components.player_stats")
local EnemyAI = require("components.enemy_ai")
local CollisionRadius = require("components.collision_radius")
local ExperienceValue = require("components.experience_value")
local ExperienceOrb = require("components.experience_orb")
local Sprite = require("components.sprite")
local MarkedForDeletion = require("components.marked_for_deletion")

-- Player: one per game, WASD input, auto-fires
function Prefabs.createPlayer(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(Position, config.x or 400, config.y or 300)
    e:give(Velocity, 0, 0)
    e:give(Health, 100)
    e:give(MaxHealth, 100)
    e:give(Team, "player")
    e:give(PlayerInput)
    e:give(PlayerStats, { speed = 120, level = 1, xp = 0, xp_to_next = 100 })
    e:give(AutoFire, { cooldown = 0.4, timer = 0 })
    e:give(Weapon, { damage = 15, bullet_speed = 250, spread = 0 })
    e:give(CollisionRadius, 10)
    e:give(Sprite, "player")
    return e
end

-- Basic enemy: chases player, deals contact damage
function Prefabs.createEnemy(world, config)
    config = config or {}
    local hp = config.hp or 30
    local e = world:createEntity()
    e:give(Position, config.x or 0, config.y or 0)
    e:give(Velocity, 0, 0)
    e:give(Health, hp)
    e:give(MaxHealth, hp)
    e:give(Damage, config.damage or 10)
    e:give(Team, "enemy")
    e:give(EnemyAI, { state = "chase", target = nil, speed = config.speed or 60 })
    e:give(CollisionRadius, config.radius or 12)
    e:give(ExperienceValue, config.xp or 10)
    e:give(Sprite, config.sprite or "enemy_basic")
    return e
end

-- Bullet: short-lived projectile
function Prefabs.createBullet(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(Position, config.x or 0, config.y or 0)
    e:give(Velocity, config.vx or 0, config.vy or 0)
    e:give(Damage, config.damage or 15)
    e:give(Team, config.team or "player")
    e:give(CollisionRadius, 4)
    e:give(Sprite, "bullet")
    -- Bullets die after 2 seconds or on collision (handled by systems)
    e:give(MaxHealth, 1)      -- one hit kills
    e:give(Health, 1)
    return e
end

-- Explosion: visual only, no collision, auto-deletes
function Prefabs.createExplosion(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(Position, config.x or 0, config.y or 0)
    e:give(Sprite, "explosion_01")
    -- AnimationSystem will mark this for deletion when animation ends
    return e
end

-- XP Orb: floats toward player, collected on proximity
function Prefabs.createXPOrb(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(Position, config.x or 0, config.y or 0)
    e:give(Velocity, 0, 0)
    e:give(ExperienceOrb, { value = config.value or 10 })
    e:give(CollisionRadius, 8)
    e:give(Sprite, "xp_orb")
    return e
end

-- Pickup: dropped item (health, weapon upgrade, etc.)
function Prefabs.createPickup(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(Position, config.x or 0, config.y or 0)
    e:give(CollisionRadius, 12)
    e:give(Sprite, config.sprite or "pickup_health")
    -- Pickup type handled by a tag component passed in config
    if config.component then
        e:give(config.component, config.component_data)
    end
    return e
end

return Prefabs
```

**GDScript (Godot):**
```gdscript
# prefabs.gd — static factory methods for all entity types

class_name Prefabs
extends RefCounted

static func create_player(world: ECSWorld, config: Dictionary = {}) -> int:
    var e = world.create_entity()
    world.add_component(e, Position.new(config.get("x", 400), config.get("y", 300)))
    world.add_component(e, Velocity.new(0, 0))
    world.add_component(e, Health.new(100))
    world.add_component(e, MaxHealth.new(100))
    world.add_component(e, Team.new("player"))
    world.add_component(e, PlayerInput.new())
    world.add_component(e, PlayerStats.new(120, 1, 0, 100))  # speed, level, xp, xp_to_next
    world.add_component(e, AutoFire.new(0.4))                # cooldown
    world.add_component(e, Weapon.new(15, 250, 0))           # damage, speed, spread
    world.add_component(e, CollisionRadius.new(10))
    world.add_component(e, SpriteRef.new("player"))
    return e

static func create_enemy(world: ECSWorld, config: Dictionary = {}) -> int:
    var hp = config.get("hp", 30)
    var e = world.create_entity()
    world.add_component(e, Position.new(config.get("x", 0), config.get("y", 0)))
    world.add_component(e, Velocity.new(0, 0))
    world.add_component(e, Health.new(hp))
    world.add_component(e, MaxHealth.new(hp))
    world.add_component(e, Damage.new(config.get("damage", 10)))
    world.add_component(e, Team.new("enemy"))
    world.add_component(e, EnemyAI.new("chase", config.get("speed", 60)))
    world.add_component(e, CollisionRadius.new(config.get("radius", 12)))
    world.add_component(e, ExperienceValue.new(config.get("xp", 10)))
    world.add_component(e, SpriteRef.new(config.get("sprite", "enemy_basic")))
    return e

static func create_bullet(world: ECSWorld, config: Dictionary = {}) -> int:
    var e = world.create_entity()
    world.add_component(e, Position.new(config.get("x", 0), config.get("y", 0)))
    world.add_component(e, Velocity.new(config.get("vx", 0), config.get("vy", 0)))
    world.add_component(e, Damage.new(config.get("damage", 15)))
    world.add_component(e, Team.new(config.get("team", "player")))
    world.add_component(e, CollisionRadius.new(4))
    world.add_component(e, SpriteRef.new("bullet"))
    world.add_component(e, Health.new(1))
    world.add_component(e, MaxHealth.new(1))
    return e

static func create_xp_orb(world: ECSWorld, config: Dictionary = {}) -> int:
    var e = world.create_entity()
    world.add_component(e, Position.new(config.get("x", 0), config.get("y", 0)))
    world.add_component(e, Velocity.new(0, 0))
    world.add_component(e, ExperienceOrb.new(config.get("value", 10)))
    world.add_component(e, CollisionRadius.new(8))
    world.add_component(e, SpriteRef.new("xp_orb"))
    return e
```

---

## 4. Where UI Lives in ECS

This is one of the most common architecture questions beginners ask. The answer depends on your engine and preference, but the options are clear.

**Option A: Pure ECS UI (UI components + systems)**
Everything is an entity: health bars, score text, menus. Technically consistent but painful in practice. UI layout is not a systems problem. Not recommended.

**Option B: UI completely separate (recommended for Godot)**
Your ECS world handles game logic. Your Godot scene tree handles UI. UI nodes read from a shared GameState resource or directly query the ECS world at the end of each frame. Clean separation, works naturally with Godot's node system.

**Option C: Hybrid with singleton components (recommended for Love2D)**
A small number of singleton-style components (Score, Wave, PlayerHealth) live in the ECS world. Your HUD reads those components each frame. The ECS world is the source of truth; the HUD just queries it.

**Pseudocode:**
```
-- Option C: Singleton component pattern
function update_hud(world):
    score_entity = world.get_singleton(Score)
    player_entity = world.query_first(PlayerStats, Health)
    
    hud.score = score_entity.Score.value
    hud.health = player_entity.Health.hp
    hud.max_health = player_entity.MaxHealth.max
    hud.level = player_entity.PlayerStats.level
    hud.xp = player_entity.PlayerStats.xp
    hud.xp_to_next = player_entity.PlayerStats.xp_to_next
```

**Lua (Love2D with tiny-ecs or Concord):**
```lua
-- hud.lua — reads from ECS world, draws UI itself

local HUD = {}

function HUD.draw(world)
    -- Find the singleton score entity (created once at game start)
    local score_entity = world:getEntityWithComponent("Score")
    local score = score_entity and score_entity.Score.value or 0

    -- Find the player entity
    local player_entity = world:queryFirst("PlayerStats", "Health", "MaxHealth")
    if not player_entity then return end

    local hp = player_entity.Health.hp
    local max_hp = player_entity.MaxHealth.max
    local level = player_entity.PlayerStats.level
    local xp = player_entity.PlayerStats.xp
    local xp_next = player_entity.PlayerStats.xp_to_next

    -- Draw health bar
    local bar_width = 200
    love.graphics.setColor(0.8, 0.1, 0.1)
    love.graphics.rectangle("fill", 20, 20, bar_width * (hp / max_hp), 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 20, 20, bar_width, 20)
    love.graphics.print(hp .. "/" .. max_hp, 25, 22)

    -- Draw XP bar
    love.graphics.setColor(0.2, 0.6, 1.0)
    love.graphics.rectangle("fill", 20, 48, bar_width * (xp / xp_next), 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level " .. level, 25, 48)

    -- Draw score
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.print("Score: " .. score, love.graphics.getWidth() - 180, 20)
end

return HUD
```

**GDScript (Godot):**
```gdscript
# hud.gd — a CanvasLayer node that reads from the ECS world

extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var xp_bar: ProgressBar = $XPBar
@onready var score_label: Label = $ScoreLabel
@onready var level_label: Label = $LevelLabel

var ecs_world: ECSWorld  # set this reference at game start

func _process(_delta: float) -> void:
    if not ecs_world:
        return

    # Query player entity from ECS world
    var player_entities = ecs_world.query([PlayerStats, Health, MaxHealth])
    if player_entities.is_empty():
        return

    var player_id = player_entities[0]
    var health = ecs_world.get_component(player_id, Health)
    var max_health = ecs_world.get_component(player_id, MaxHealth)
    var stats = ecs_world.get_component(player_id, PlayerStats)

    health_bar.value = float(health.hp) / float(max_health.max) * 100.0
    xp_bar.value = float(stats.xp) / float(stats.xp_to_next) * 100.0
    level_label.text = "Level %d" % stats.level

    # Query score singleton
    var score_entities = ecs_world.query([Score])
    if not score_entities.is_empty():
        var score = ecs_world.get_component(score_entities[0], Score)
        score_label.text = "Score: %d" % score.value
```

---

## 5. Game State Management

Your game has multiple states: a title screen, gameplay, a pause menu, a game-over screen. How do those states interact with ECS?

There are three patterns, each with a clear use case.

**Pattern A: Singleton GameState component**
One entity holds the current state as a string or enum. Systems check it at the top of their update and early-return if they shouldn't run. Simple. Good for small games.

**Pattern B: External state machine that swaps system groups**
A state machine lives outside ECS and activates/deactivates groups of systems. Playing state runs all systems. Paused state runs only RenderSystem and HUDSystem. GameOver state runs only RenderSystem, HUDSystem, and GameOverSystem. This is the cleanest approach for medium-sized games.

**Pattern C: Multiple ECS worlds**
Each game state gets its own ECS world. Title screen is one world. Gameplay is another. Switching states swaps the active world. Complex to set up but gives complete isolation. Useful for games with very different entity sets across states.

**For the Vampire Survivors clone: use Pattern B.**

**Pseudocode:**
```
state_machine:
    playing:
        active_systems = [Input, Movement, AI, AutoFire, Bullet, Collision,
                         Damage, Health, Death, XPOrb, Experience, LevelUp,
                         Wave, Animation, Camera, Render, HUD, Cleanup]
    paused:
        active_systems = [Render, HUD, PauseMenuSystem]
    game_over:
        active_systems = [Render, HUD, GameOverSystem]
    level_up_menu:
        active_systems = [Render, HUD, LevelUpMenuSystem]

function update(dt):
    for system in state_machine.current.active_systems:
        system.update(world, dt)
```

**Lua (Love2D with tiny-ecs or Concord):**
```lua
-- game_states.lua

local GameStates = {}

-- System groups
local PLAYING_SYSTEMS = {
    "InputSystem", "MovementSystem", "EnemyAISystem", "AutoFireSystem",
    "BulletMovementSystem", "CollisionSystem", "DamageSystem",
    "HealthCheckSystem", "DeathSpawnSystem", "EXPOrbSystem",
    "ExperienceCollectionSystem", "LevelUpSystem", "WaveSpawnSystem",
    "AnimationSystem", "CameraSystem", "RenderSystem", "HUDSystem",
    "CleanupSystem"
}

local PAUSED_SYSTEMS = { "RenderSystem", "HUDSystem", "PauseMenuSystem" }

local GAME_OVER_SYSTEMS = { "RenderSystem", "HUDSystem", "GameOverSystem" }

local LEVEL_UP_SYSTEMS = { "RenderSystem", "HUDSystem", "LevelUpMenuSystem" }

-- Current state
GameStates.current = "playing"

function GameStates.update(world, systems, dt)
    local active
    if GameStates.current == "playing" then
        active = PLAYING_SYSTEMS
    elseif GameStates.current == "paused" then
        active = PAUSED_SYSTEMS
    elseif GameStates.current == "game_over" then
        active = GAME_OVER_SYSTEMS
    elseif GameStates.current == "level_up" then
        active = LEVEL_UP_SYSTEMS
    end

    for _, name in ipairs(active) do
        if systems[name] then
            systems[name]:update(world, dt)
        end
    end
end

function GameStates.set(new_state)
    print("State: " .. GameStates.current .. " -> " .. new_state)
    GameStates.current = new_state
end

return GameStates
```

**GDScript (Godot):**
```gdscript
# game_state_machine.gd

class_name GameStateMachine
extends RefCounted

enum State { PLAYING, PAUSED, GAME_OVER, LEVEL_UP }

var current_state: State = State.PLAYING
var systems: Dictionary = {}  # name -> system instance

# Define which systems run in each state
const STATE_SYSTEMS: Dictionary = {
    State.PLAYING: [
        "InputSystem", "MovementSystem", "EnemyAISystem", "AutoFireSystem",
        "BulletMovementSystem", "CollisionSystem", "DamageSystem",
        "HealthCheckSystem", "DeathSpawnSystem", "EXPOrbSystem",
        "ExperienceCollectionSystem", "LevelUpSystem", "WaveSpawnSystem",
        "AnimationSystem", "CameraSystem", "RenderSystem", "HUDSystem",
        "CleanupSystem"
    ],
    State.PAUSED: ["RenderSystem", "HUDSystem", "PauseMenuSystem"],
    State.GAME_OVER: ["RenderSystem", "HUDSystem", "GameOverSystem"],
    State.LEVEL_UP: ["RenderSystem", "HUDSystem", "LevelUpMenuSystem"],
}

func update(world: ECSWorld, delta: float) -> void:
    var active_names: Array = STATE_SYSTEMS.get(current_state, [])
    for name in active_names:
        if systems.has(name):
            systems[name].update(world, delta)

func set_state(new_state: State) -> void:
    print("State transition: %s -> %s" % [State.keys()[current_state], State.keys()[new_state]])
    current_state = new_state
```

---

## 6. ECS Serialization (Save/Load)

ECS is just data. Components are plain tables or objects. That makes serialization surprisingly straightforward compared to object-oriented games with deep inheritance chains.

The pattern is: tag entities that should be saved with a `Saveable` component. Iterate those entities, write their components to a table, serialize to JSON or a binary format. On load, recreate each entity from the saved data.

**One important rule: don't save render-only components.** Sprite, AnimationState, and similar components should be reconstructed from prefabs on load, not persisted. Save the game data; let prefabs handle the presentation.

**Pseudocode:**
```
function save(world, filepath):
    data = { entities: [] }
    for entity in world.query(Saveable):
        entry = { components: {} }
        for component_name in SAVEABLE_COMPONENTS:
            if entity has component_name:
                entry.components[component_name] = serialize(entity[component_name])
        data.entities.append(entry)
    write_json(filepath, data)

function load(world, filepath):
    data = read_json(filepath)
    world.clear_all_entities()
    for entry in data.entities:
        e = world.new_entity()
        for component_name, component_data in entry.components:
            e.add_component(component_name, deserialize(component_data))
```

**Lua (Love2D with tiny-ecs or Concord):**
```lua
-- save.lua

local Save = {}

-- Components that should be persisted (exclude render-only components)
local SAVEABLE_COMPONENTS = {
    "Position", "Health", "MaxHealth", "PlayerStats",
    "Team", "EnemyAI", "ExperienceValue", "Score", "Wave"
}

function Save.save(world, filepath)
    local data = { entities = {} }

    -- Iterate all entities tagged as saveable
    world:forEach({"Saveable"}, function(entity)
        local entry = { components = {} }
        for _, comp_name in ipairs(SAVEABLE_COMPONENTS) do
            if entity[comp_name] then
                -- Shallow copy the component data (components are plain tables)
                entry.components[comp_name] = {}
                for k, v in pairs(entity[comp_name]) do
                    entry.components[comp_name][k] = v
                end
            end
        end
        table.insert(data.entities, entry)
    end)

    -- Serialize and write
    local json_str = require("json").encode(data)
    love.filesystem.write(filepath, json_str)
    print("Saved " .. #data.entities .. " entities to " .. filepath)
end

function Save.load(world, filepath, prefabs)
    if not love.filesystem.getInfo(filepath) then
        print("No save file found at " .. filepath)
        return false
    end

    local json_str = love.filesystem.read(filepath)
    local data = require("json").decode(json_str)

    -- Clear game entities (keep singletons or recreate them too)
    world:clear()

    for _, entry in ipairs(data.entities) do
        local e = world:createEntity()
        for comp_name, comp_data in pairs(entry.components) do
            local ComponentClass = require("components." .. comp_name:lower())
            e:give(ComponentClass)
            -- Restore saved values
            for k, v in pairs(comp_data) do
                e[comp_name][k] = v
            end
        end
    end

    -- Re-add player visuals via prefab logic (not stored in save)
    -- Systems will reconstruct Sprite, Animation, etc. on next frame
    print("Loaded " .. #data.entities .. " entities.")
    return true
end

return Save
```

**GDScript (Godot):**
```gdscript
# save.gd

class_name SaveSystem
extends RefCounted

const SAVE_PATH = "user://savegame.json"

# Components to persist — exclude render/visual components
const SAVEABLE_COMPONENTS: Array = [
    "Position", "Health", "MaxHealth", "PlayerStats",
    "Team", "EnemyAI", "ExperienceValue", "Score", "Wave"
]

static func save_game(world: ECSWorld) -> void:
    var data: Dictionary = { "entities": [] }

    var saveable = world.query([Saveable])
    for entity_id in saveable:
        var entry: Dictionary = { "components": {} }
        for comp_name in SAVEABLE_COMPONENTS:
            var comp = world.get_component_by_name(entity_id, comp_name)
            if comp:
                entry["components"][comp_name] = comp.to_dict()
        data["entities"].append(entry)

    var json_str = JSON.stringify(data)
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(json_str)
    file.close()
    print("Saved %d entities." % data["entities"].size())

static func load_game(world: ECSWorld) -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        print("No save file found.")
        return false

    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var json_str = file.get_as_text()
    file.close()

    var data: Dictionary = JSON.parse_string(json_str)
    world.clear_all_entities()

    for entry in data["entities"]:
        var e = world.create_entity()
        for comp_name in entry["components"]:
            var comp = ComponentFactory.create(comp_name, entry["components"][comp_name])
            world.add_component(e, comp)

    print("Loaded %d entities." % data["entities"].size())
    return true
```

---

## 7. Debugging an ECS Game

Debugging ECS without tools is miserable. With tools, it's straightforward. Build these helpers early — ideally before you write your first system.

**Core debug functions:**

```
print_entity(world, id)       -- list every component on entity id
print_all_with(world, C)      -- list all entity IDs that have component C
system_timer(system, world)   -- measure ms per system per frame
```

**"Why isn't my entity moving?" checklist:**
1. Does it have a Position component?
2. Does it have a Velocity component with non-zero values?
3. Is MovementSystem running? (Check state machine)
4. Is MovementSystem processing this entity? (Add print inside the system filter)
5. Is something zeroing velocity before MovementSystem runs? (Check system order)
6. Is MarkedForDeletion on the entity? (CleanupSystem may have flagged it)

**Pseudocode:**
```
function print_entity(world, id):
    print("Entity " + id + ":")
    for component in world.get_all_components(id):
        print("  " + component.type + ": " + serialize(component))

function system_timer(systems, world, dt):
    for system in systems:
        t0 = clock()
        system.update(world, dt)
        t1 = clock()
        debug_overlay[system.name] = (t1 - t0) * 1000  -- ms
```

**Lua (Love2D with tiny-ecs or Concord):**
```lua
-- debug.lua

local Debug = {}
Debug.enabled = true
Debug.system_times = {}

-- Print all components on an entity
function Debug.print_entity(world, entity)
    if not Debug.enabled then return end
    print("=== Entity: " .. tostring(entity) .. " ===")
    for k, v in pairs(entity) do
        if type(v) == "table" then
            print("  [" .. k .. "]")
            for ck, cv in pairs(v) do
                print("    " .. tostring(ck) .. " = " .. tostring(cv))
            end
        end
    end
end

-- Print all entities that have a given component
function Debug.print_all_with(world, component_name)
    if not Debug.enabled then return end
    print("=== Entities with " .. component_name .. " ===")
    world:forEach({component_name}, function(e)
        print("  Entity: " .. tostring(e))
    end)
end

-- Wrap system update to measure timing
function Debug.timed_update(system_name, system, world, dt)
    local t0 = love.timer.getTime()
    system:update(world, dt)
    local elapsed = (love.timer.getTime() - t0) * 1000
    Debug.system_times[system_name] = elapsed
end

-- Draw timing overlay (call from love.draw)
function Debug.draw_overlay()
    if not Debug.enabled then return end
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, 60, 220, 30 + #Debug.system_times * 18)
    love.graphics.setColor(0.2, 1, 0.2)
    local y = 70
    for name, ms in pairs(Debug.system_times) do
        love.graphics.print(string.format("%-24s %.2f ms", name, ms), 15, y)
        y = y + 18
    end
    love.graphics.setColor(1, 1, 1)
end

return Debug
```

**GDScript (Godot):**
```gdscript
# debug.gd

class_name ECSDebug
extends RefCounted

static var enabled: bool = true
static var system_times: Dictionary = {}

static func print_entity(world: ECSWorld, entity_id: int) -> void:
    if not enabled:
        return
    print("=== Entity %d ===" % entity_id)
    var components = world.get_all_components(entity_id)
    for comp in components:
        print("  [%s]: %s" % [comp.get_class(), str(comp)])

static func print_all_with(world: ECSWorld, component_class) -> void:
    if not enabled:
        return
    print("=== Entities with %s ===" % component_class)
    var entities = world.query([component_class])
    for id in entities:
        print("  Entity %d" % id)

static func timed_update(system_name: String, system: ECSSystem,
                          world: ECSWorld, delta: float) -> void:
    var t0 = Time.get_ticks_usec()
    system.update(world, delta)
    var elapsed_ms = (Time.get_ticks_usec() - t0) / 1000.0
    system_times[system_name] = elapsed_ms

static func draw_overlay(canvas: CanvasItem) -> void:
    if not enabled:
        return
    var y = 80
    for name in system_times:
        canvas.draw_string(ThemeDB.fallback_font,
            Vector2(15, y),
            "%s: %.2f ms" % [name, system_times[name]],
            HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN)
        y += 20
```

---

## 8. Minimum Viable Scope Guide

The single biggest mistake in solo game development is spending three months on a game no one ever plays because it never shipped. The MVP discipline is the cure.

**The MVP loop:**
1. Core gameplay only (no menus, no audio, no high scores, no settings)
2. Get it running and playable in 2 weeks
3. Then and only then, add polish

**Vampire Survivors clone MVP scope checklist:**

```
MVP (2 weeks target):
  [x] Player moves with WASD
  [x] Player auto-fires in nearest-enemy direction
  [x] 1 enemy type spawns on a timer, chases player
  [x] Bullets kill enemies (health, damage, MarkedForDeletion)
  [x] Enemies kill player on contact
  [x] XP orbs drop, player collects them
  [x] Player levels up (just a counter is fine)
  [x] Game over when health reaches 0
  [x] Restart works

Cut for MVP:
  [ ] Multiple enemy types
  [ ] Upgrade menu on level up
  [ ] Multiple weapons
  [ ] Audio
  [ ] Menus and title screen
  [ ] Save/load
  [ ] Score leaderboard
  [ ] Visual polish (particles, screen shake)
  [ ] Multiple maps

Add after MVP ships:
  [ ] 2nd enemy type
  [ ] 1 upgrade choice on level up
  [ ] Simple audio (one shoot SFX, one death SFX)
  [ ] Then more...
```

**Pseudocode:**
```
function is_mvp_done():
    return (
        player_can_move AND
        player_can_shoot AND
        enemies_spawn_and_chase AND
        damage_works AND
        death_works AND
        game_over_works AND
        restart_works
    )
    -- If all true: ship it. Polish later.
```

**Lua (Love2D with tiny-ecs or Concord):**
```lua
-- mvp_checklist.lua — a simple runtime validation you can run in dev mode

local function check_mvp(world)
    local results = {}

    -- Check player exists
    local players = world:queryAll("PlayerInput", "Position")
    results.player_exists = #players > 0

    -- Check movement system is registered
    results.movement_system = world:hasSystem("MovementSystem")

    -- Check collision system is registered
    results.collision_system = world:hasSystem("CollisionSystem")

    -- Check cleanup system is registered (prevents entity leak)
    results.cleanup_system = world:hasSystem("CleanupSystem")

    for check, passed in pairs(results) do
        local status = passed and "OK" or "MISSING"
        print(string.format("  [%s] %s", status, check))
    end
end

-- Call this in love.load() during development
-- check_mvp(world)
```

**GDScript (Godot):**
```gdscript
# mvp_checklist.gd — dev-mode runtime validation

class_name MVPChecklist
extends RefCounted

static func check(world: ECSWorld, state_machine: GameStateMachine) -> void:
    var results: Dictionary = {}

    # Player exists
    var players = world.query([PlayerInput, Position])
    results["player_exists"] = not players.is_empty()

    # Key systems registered
    results["movement_system"] = state_machine.systems.has("MovementSystem")
    results["collision_system"] = state_machine.systems.has("CollisionSystem")
    results["cleanup_system"] = state_machine.systems.has("CleanupSystem")
    results["wave_spawn_system"] = state_machine.systems.has("WaveSpawnSystem")

    for check in results:
        var status = "OK" if results[check] else "MISSING"
        print("[%s] %s" % [status, check])
```

---

## Code Walkthrough: Vampire Survivors-Style Arena Game Architecture

This is the full architecture for the capstone project. Read it through completely before writing a single line of code.

### Design Document

**Genre:** Top-down arena survival
**Concept:** Player moves with WASD. Weapons fire automatically toward the nearest enemy. Enemies spawn in waves and chase the player. On death, enemies drop XP orbs. Collecting XP levels up the player. Survive as long as possible.

---

### Component List (17 components)

| Component | Type | Purpose |
|---|---|---|
| Position | `{x, y}` | World position |
| Velocity | `{vx, vy}` | Per-frame movement delta |
| Rotation | `{angle}` | Facing direction in radians |
| Sprite | `{image, scale, color}` | Render reference |
| Health | `{hp}` | Current hit points |
| MaxHealth | `{max}` | Maximum hit points |
| Damage | `{amount}` | Damage dealt on hit |
| Team | `{id}` | "player", "enemy", "neutral" |
| AutoFire | `{cooldown, timer}` | Fires on cooldown |
| Weapon | `{damage, bullet_speed, spread}` | Weapon configuration |
| ExperienceValue | `{value}` | XP dropped on death |
| ExperienceOrb | `{value}` | Floating XP orb data |
| PlayerInput | `{}` | Tag: receives keyboard input |
| PlayerStats | `{speed, level, xp, xp_to_next}` | Player progression |
| EnemyAI | `{state, target, speed}` | AI behavior data |
| CollisionRadius | `{r}` | Circle collider radius |
| MarkedForDeletion | `{}` | Tag: queued for removal |
| SpawnTimer *(singleton)* | `{timer, interval}` | Wave spawn timing |
| Wave *(singleton)* | `{number, enemies_remaining}` | Current wave state |
| Score *(singleton)* | `{value}` | Current score |

---

### System Pipeline (22 steps)

```
FRAME START
    │
    ├─ 01. InputSystem
    │       Reads keyboard, sets Velocity on player entity
    │
    ├─ 02. MovementSystem
    │       Applies Velocity to Position for all moving entities
    │
    ├─ 03. EnemyAISystem
    │       For each EnemyAI: find player Position, set Velocity toward player
    │
    ├─ 04. AutoFireSystem
    │       Ticks AutoFire.timer; on cooldown, fires bullet via Prefabs.createBullet()
    │
    ├─ 05. BulletMovementSystem
    │       Applies Velocity to Position for bullets (could reuse MovementSystem)
    │
    ├─ 06. CollisionDetectionSystem
    │       Circle-circle check for all pairs: (player vs enemy), (bullet vs enemy)
    │       Emits "hit" events with entity IDs and damage amount
    │
    ├─ 07. DamageResolutionSystem
    │       Reads "hit" events, applies damage to Health components
    │
    ├─ 08. HealthCheckSystem
    │       If Health.hp <= 0: emit "death" event, add MarkedForDeletion
    │
    ├─ 09. DeathSpawnSystem
    │       Reads "death" events; for enemies: call Prefabs.createXPOrb() at position
    │
    ├─ 10. EXPOrbMovementSystem
    │       If player is within magnet range, set orb Velocity toward player
    │
    ├─ 11. ExperienceCollectionSystem
    │       If orb overlaps player: add ExperienceOrb.value to PlayerStats.xp,
    │       add MarkedForDeletion to orb
    │
    ├─ 12. LevelUpSystem
    │       If PlayerStats.xp >= xp_to_next: increment level, reset xp,
    │       scale xp_to_next, emit "level_up" event
    │
    ├─ 13. WaveSpawnSystem
    │       Ticks SpawnTimer; when ready, spawn enemy wave, update Wave singleton
    │
    ├─ 14. AnimationSystem
    │       Updates sprite animation frames; marks expired animations for deletion
    │
    ├─ 15. CameraSystem
    │       Updates camera offset to follow player Position
    │
    ├─ 16. RenderSystem
    │       Draws all entities with Sprite + Position (offset by camera)
    │
    ├─ 17. HUDSystem
    │       Reads Score, PlayerStats, Health — draws health bar, XP bar, score
    │
    ├─ 18. CleanupSystem
    │       Removes all entities with MarkedForDeletion
    │
FRAME END
```

---

### Event Types

| Event | Payload | Fired By | Consumed By |
|---|---|---|---|
| `hit` | `{source, target, damage}` | CollisionSystem | DamageResolutionSystem |
| `death` | `{entity, team, position}` | HealthCheckSystem | DeathSpawnSystem, ScoreSystem |
| `level_up` | `{new_level}` | LevelUpSystem | State machine (show upgrade menu) |
| `wave_start` | `{wave_number}` | WaveSpawnSystem | HUDSystem |
| `game_over` | `{final_score}` | HealthCheckSystem (on player death) | State machine |

---

### Prefab List

| Prefab | Parameters | Creates |
|---|---|---|
| `createPlayer(world, config)` | `{x, y}` | Player entity with input, stats, weapon |
| `createEnemy(world, config)` | `{x, y, hp, damage, speed, sprite, xp}` | Enemy entity |
| `createBullet(world, config)` | `{x, y, vx, vy, damage, team}` | Bullet entity |
| `createExplosion(world, config)` | `{x, y}` | Visual-only explosion entity |
| `createXPOrb(world, config)` | `{x, y, value}` | XP orb entity |
| `createPickup(world, config)` | `{x, y, type, component}` | Item pickup entity |
| `createWall(world, config)` | `{x, y, w, h}` | Static wall entity |

---

### Implementation Order

Build in this order. Do not skip ahead. Each step should produce a runnable game.

```
Step 1:  Components only — no systems yet. Verify they instantiate.
Step 2:  Position + Velocity + MovementSystem. Entities move.
Step 3:  PlayerInput + InputSystem. Player moves with WASD.
Step 4:  Sprite + RenderSystem. Player is visible.
Step 5:  createPlayer() prefab. Player spawns from prefab.
Step 6:  createEnemy() prefab + EnemyAISystem. Enemies spawn and chase.
Step 7:  CollisionRadius + CollisionSystem (detection only, no damage yet).
Step 8:  Health + Damage + DamageResolutionSystem + HealthCheckSystem. Entities die.
Step 9:  MarkedForDeletion + CleanupSystem. Dead entities are removed.
Step 10: createBullet() + AutoFireSystem. Player shoots automatically.
Step 11: Bullet vs enemy collision. Bullets kill enemies.
Step 12: Enemy vs player collision. Enemies damage player.
Step 13: Player death -> game_over event -> state change.
Step 14: createXPOrb() + ExperienceCollectionSystem. XP collection works.
Step 15: LevelUpSystem. Player levels up.
Step 16: WaveSpawnSystem + SpawnTimer singleton. Waves spawn.
Step 17: Score singleton + scoring on enemy death.
Step 18: HUDSystem. Health bar, XP bar, score visible.
Step 19: CameraSystem. Camera follows player.
Step 20: AnimationSystem. Explosion animations play.
Step 21: Save/Load (optional for MVP, add after core loop works).
Step 22: Polish (audio, particle effects, multiple enemy types, upgrades).
```

---

### Complete `prefabs.lua`

```lua
-- prefabs.lua — all entity factory functions for the arena game

local Prefabs = {}

-- Import component constructors
local C = require("components")

function Prefabs.createPlayer(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(C.Position, config.x or 400, config.y or 300)
    e:give(C.Velocity, 0, 0)
    e:give(C.Health, 100)
    e:give(C.MaxHealth, 100)
    e:give(C.Team, "player")
    e:give(C.PlayerInput)
    e:give(C.PlayerStats, 120, 1, 0, 100)  -- speed, level, xp, xp_to_next
    e:give(C.AutoFire, 0.4, 0)             -- cooldown, timer
    e:give(C.Weapon, 15, 250, 0)           -- damage, bullet_speed, spread
    e:give(C.CollisionRadius, 10)
    e:give(C.Sprite, "player", 1, {1,1,1,1})
    return e
end

function Prefabs.createEnemy(world, config)
    config = config or {}
    local hp = config.hp or 30
    local e = world:createEntity()
    e:give(C.Position, config.x or 0, config.y or 0)
    e:give(C.Velocity, 0, 0)
    e:give(C.Health, hp)
    e:give(C.MaxHealth, hp)
    e:give(C.Damage, config.damage or 10)
    e:give(C.Team, "enemy")
    e:give(C.EnemyAI, "chase", nil, config.speed or 60)
    e:give(C.CollisionRadius, config.radius or 12)
    e:give(C.ExperienceValue, config.xp or 10)
    e:give(C.Sprite, config.sprite or "enemy_basic", 1, {1,1,1,1})
    return e
end

function Prefabs.createBullet(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(C.Position, config.x or 0, config.y or 0)
    e:give(C.Velocity, config.vx or 0, config.vy or 0)
    e:give(C.Damage, config.damage or 15)
    e:give(C.Team, config.team or "player")
    e:give(C.Health, 1)
    e:give(C.MaxHealth, 1)
    e:give(C.CollisionRadius, 4)
    e:give(C.Sprite, "bullet", 1, {1, 1, 0.5, 1})
    return e
end

function Prefabs.createExplosion(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(C.Position, config.x or 0, config.y or 0)
    e:give(C.Sprite, "explosion_01", 1, {1, 0.6, 0.1, 1})
    -- AnimationSystem marks this for deletion when animation ends
    return e
end

function Prefabs.createXPOrb(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(C.Position, config.x or 0, config.y or 0)
    e:give(C.Velocity, 0, 0)
    e:give(C.ExperienceOrb, config.value or 10)
    e:give(C.CollisionRadius, 8)
    e:give(C.Sprite, "xp_orb", 1, {0.3, 0.8, 1, 1})
    return e
end

function Prefabs.createPickup(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(C.Position, config.x or 0, config.y or 0)
    e:give(C.CollisionRadius, 12)
    e:give(C.Sprite, config.sprite or "pickup_health", 1, {1,1,1,1})
    return e
end

function Prefabs.createWall(world, config)
    config = config or {}
    local e = world:createEntity()
    e:give(C.Position, config.x or 0, config.y or 0)
    e:give(C.CollisionRadius, math.max(config.w or 32, config.h or 32) / 2)
    e:give(C.Sprite, "wall", 1, {0.4, 0.4, 0.4, 1})
    return e
end

return Prefabs
```

---

### Complete `main.lua`

```lua
-- main.lua — entry point for the arena game

local World = require("concord").world      -- or require("tiny") for tiny-ecs
local Prefabs = require("prefabs")
local GameStates = require("game_states")
local Debug = require("debug")
local HUD = require("hud")

-- Import all systems
local InputSystem            = require("systems.input")
local MovementSystem         = require("systems.movement")
local EnemyAISystem          = require("systems.enemy_ai")
local AutoFireSystem         = require("systems.auto_fire")
local BulletMovementSystem   = require("systems.bullet_movement")
local CollisionSystem        = require("systems.collision")
local DamageSystem           = require("systems.damage")
local HealthCheckSystem      = require("systems.health_check")
local DeathSpawnSystem       = require("systems.death_spawn")
local EXPOrbSystem           = require("systems.exp_orb")
local ExperienceSystem       = require("systems.experience")
local LevelUpSystem          = require("systems.level_up")
local WaveSpawnSystem        = require("systems.wave_spawn")
local AnimationSystem        = require("systems.animation")
local CameraSystem           = require("systems.camera")
local RenderSystem           = require("systems.render")
local HUDSystem              = require("systems.hud")
local CleanupSystem          = require("systems.cleanup")

local world
local systems

function love.load()
    -- Create ECS world
    world = World()

    -- Register systems in pipeline order
    systems = {
        InputSystem            = InputSystem(world),
        MovementSystem         = MovementSystem(world),
        EnemyAISystem          = EnemyAISystem(world),
        AutoFireSystem         = AutoFireSystem(world, Prefabs),
        BulletMovementSystem   = BulletMovementSystem(world),
        CollisionSystem        = CollisionSystem(world),
        DamageSystem           = DamageSystem(world),
        HealthCheckSystem      = HealthCheckSystem(world),
        DeathSpawnSystem       = DeathSpawnSystem(world, Prefabs),
        EXPOrbSystem           = EXPOrbSystem(world),
        ExperienceSystem       = ExperienceSystem(world),
        LevelUpSystem          = LevelUpSystem(world),
        WaveSpawnSystem        = WaveSpawnSystem(world, Prefabs),
        AnimationSystem        = AnimationSystem(world),
        CameraSystem           = CameraSystem(world),
        RenderSystem           = RenderSystem(world),
        HUDSystem              = HUDSystem(world),
        CleanupSystem          = CleanupSystem(world),
    }

    GameStates.set_systems(systems)

    -- Spawn player
    Prefabs.createPlayer(world, { x = 400, y = 300 })

    -- Spawn singleton components (one entity, holds global state)
    local singletons = world:createEntity()
    singletons:give(require("components").Score, 0)
    singletons:give(require("components").Wave, 1, 0)
    singletons:give(require("components").SpawnTimer, 5.0, 0)

    print("Arena game loaded. Good luck.")
end

function love.update(dt)
    -- Clamp dt to avoid spiral of death on lag spikes
    dt = math.min(dt, 0.05)
    GameStates.update(world, systems, dt)
end

function love.draw()
    -- RenderSystem and HUDSystem are called inside GameStates.update
    -- Debug overlay is drawn on top
    if love.keyboard.isDown("tab") then
        Debug.draw_overlay()
    end
end

function love.keypressed(key)
    if key == "escape" then
        if GameStates.current == "playing" then
            GameStates.set("paused")
        elseif GameStates.current == "paused" then
            GameStates.set("playing")
        end
    end
    if key == "r" and GameStates.current == "game_over" then
        love.load()  -- full restart
    end
end
```

---

## Concept Quick Reference

| Concept | Pattern | Common Mistake |
|---|---|---|
| Entity creation | Always via prefab functions | Calling `world:createEntity()` directly in system code |
| Entity deletion | Add `MarkedForDeletion`, let CleanupSystem remove | Deleting mid-iteration (corrupts query results) |
| Game state | External state machine activates/deactivates system groups | Running all systems in every state |
| UI | Separate from ECS; reads ECS world at end of frame | Putting buttons and text into ECS entities |
| Global state | Singleton entity with Score/Wave/Timer components | Using global Lua variables or static class fields |
| System ordering | Explicit list in `main.lua`, documented in design doc | Relying on ECS framework to order correctly |
| Events | Queued per frame, consumed by one downstream system | Reading events in the same system that fires them |
| Serialization | Save data components only; reconstruct visuals from prefabs | Saving Sprite, Animation, and other render state |
| Debugging | `print_entity()`, `print_all_with()`, system timer overlay | Adding `print()` calls inside tight loops forever |
| Scope | MVP first, polish after | Adding upgrade menus before core loop works |

---

## Common Pitfalls

1. **Starting to code before writing the design doc.** You will refactor your component list three times in the first week. Write the doc. It takes an hour and saves three days.

2. **Scope creep before the core loop works.** Upgrade menus, multiple weapons, and achievement systems are satisfying to design. They are also the reason most solo games never ship. Get the player moving, shooting, and dying first. Everything else is bonus.

3. **Putting game logic in prefab functions.** Prefabs create entities. They do not fire events, check game state, or call other systems. If your `createEnemy()` function increments the wave counter, that logic belongs in WaveSpawnSystem.

4. **Not handling MarkedForDeletion.** If CleanupSystem doesn't run (or runs before everything else), your entity count grows every frame. Bullets that never die. Enemies that stack. Your game will slow to a crawl and you will spend hours debugging the wrong thing. Put CleanupSystem last.

5. **Serializing the wrong things.** Saving Sprite names, animation frames, or render state is wasteful and fragile. Save data: positions, health values, player stats, score. Let prefabs reconstruct the presentation layer on load.

6. **Debugger-less development.** If you don't have `print_entity()` and a system timer overlay, you are flying blind. Build the debug tools in the first hour. You will use them constantly. The five minutes it takes is repaid the first time an entity mysteriously stops moving.

7. **Quitting before shipping.** "I'll clean up the code first." "I need one more feature." "It's not good enough yet." None of that matters. A shipped game you're embarrassed by teaches you more than a perfect game that lives in a `dev` branch forever. Ship it, then improve it.

---

## Exercises

### Exercise 1: Write Your ECS Design Doc
**Estimated time:** 2–3 hours

Pick a game you actually want to build — not the Vampire Survivors clone if that doesn't excite you. Write the full 5-section design doc for it: genre/concept, component list, system list with ordering, events, and prefabs.

Don't open a code editor until you can answer these without looking at notes:
- What are your five most important components?
- What order do your systems run in?
- What event crosses the most system boundaries?

**Stretch goal:** Share the design doc with a friend or post it in a game dev community for feedback. Other eyes catch scope creep and missing components that you don't see.

---

### Exercise 2: Build the Vampire Survivors MVP
**Estimated time:** 20–40 hours

Follow the 22-step implementation order in the code walkthrough. Build only the MVP checklist items. Resist adding the upgrade menu until steps 1–19 are working and fun.

Concrete milestones to hit:
- End of day 1: Player moves and is rendered
- End of day 3: Enemies spawn and chase
- End of day 5: Shooting and death work
- End of week 2: Full MVP loop (move, shoot, collect XP, level up, die, restart)

**Stretch goal:** After MVP ships, add one new enemy type (a fast but fragile enemy) and one upgrade (speed boost on level up). Do not add both at the same time.

---

### Exercise 3: Add Save/Load to Your ECS Game
**Estimated time:** 3–5 hours

Using the save/load patterns from Section 6, add serialization to your game. Mark entities with a `Saveable` component. Write `save()` and `load()` functions. Test that loading a saved game produces a valid, playable state.

Verify these edge cases:
- Saving with zero enemies alive (only player + singletons)
- Saving mid-wave with 20+ entities
- Loading and immediately saving again (round-trip fidelity)

**Stretch goal:** Add a high score leaderboard. Store the top 5 scores with timestamps in `love.filesystem`. Display them on the game-over screen.

---

## Key Takeaways

- **Write the design doc before any code.** If you can't list your components and system order in advance, you don't understand your game yet. The document takes an hour; skipping it costs days.

- **Prefab discipline keeps the codebase maintainable.** All entity creation through named factory functions means one place to change every entity type, and no half-constructed entities floating around game logic.

- **Shipping is the skill.** MVP discipline — core loop only, get it running in two weeks, polish after — is the difference between a game that exists and a game that lives in a private repo forever.

- **Scope management is a technical decision, not a creative one.** Cutting the upgrade menu from the MVP isn't giving up on your vision; it's the fastest path to a game other people can play and give you feedback on.

- **You now have the full ECS toolkit.** Components, systems, queries, events, prefabs, system ordering, game state management, serialization, and debugging. You've gone from "what is ECS" to "here is the full architecture for a real game." The only thing left is to build it.

---

## What's Next

You've completed the ECS Learning Roadmap. Every module, from the basics of components through to shipping a full game — you've covered it all.

Return to the [ECS Learning Roadmap](ecs-learning-roadmap.md) to review any module, or to use the roadmap as a reference while building.

**Suggested next steps:**

- **Try a production ECS framework.** [Flecs](https://github.com/SanderMertens/flecs) is a C/C++ archetype ECS used in commercial games. Playing with it will expose you to performance-oriented ECS concepts (archetypes, sparse sets, relationship queries) that go beyond what tiny-ecs or Concord offer.

- **Contribute to an open source ECS project.** Concord, tiny-ecs, and similar libraries always need documentation, tests, and example projects. Contributing is one of the fastest ways to deepen understanding and meet other ECS practitioners.

- **Build a game jam entry.** A 48-hour jam forces MVP discipline by definition. Use everything you've learned here: design doc first, prefabs only, system order documented, debug overlay on from hour one. Ship something by the deadline.

The architecture is in your head now. Go build something.
