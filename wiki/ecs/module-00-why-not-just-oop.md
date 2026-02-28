# Module 0: Why Not Just OOP?

**Part of:** [ECS Learning Roadmap](ecs-learning-roadmap.md)
**Estimated study time:** 2–3 hours
**Prerequisites:** None — just familiarity with OOP concepts

---

## Overview

You already know OOP. You know how to make a `Player` class, give it methods, extend it, and build a nice clean hierarchy. So why are game developers — especially ones working on large, complex games — increasingly moving away from that model? The short answer: OOP hierarchies that look elegant at the start of a project become load-bearing messes by the end. ECS (Entity-Component-System) architecture is a different way of organizing game code that sidesteps most of those messes by design.

In this module you're going to feel the pain of OOP game architecture before you learn the cure. You'll see the diamond problem, the blob anti-pattern, and the data/logic coupling problem — not as abstract theory, but as concrete situations that come up in real game projects. If you've ever added a flag to a base class "just for this one subclass" or copy-pasted behavior between two branches of an inheritance tree, you've already lived these problems. Now you'll have names for them and understand why they happen.

By the end of this module you'll understand *why* ECS was invented — not just "composition is good" as a vague maxim, but the specific mechanical reasons why bundling data and behavior into class hierarchies causes problems at scale. That understanding is the foundation everything else in this roadmap builds on. The architecture will make a lot more sense when you've felt what it's solving.

---

## 1. The Diamond Problem

The diamond problem is what happens when you need a class that inherits from two classes that share a common ancestor. In most game engines you hit this within the first few weeks of a serious project.

Start with a straightforward RPG hierarchy:

```
          Entity
            |
         Character
        /          \
     Player        Enemy
```

Clean. `Character` has health, name, position. `Player` has input handling and a controllable camera. `Enemy` has an AI brain and an aggro radius. You're feeling good.

Then the designer asks for a `FlyingEnemy`. Fine — you add a `Flying` class somewhere:

```
          Entity
            |
         Character
        /          \
     Player        Enemy
       |              |
    FlyingPlayer   FlyingEnemy?
```

Where does `FlyingEnemy` go? It needs `Enemy` behavior (AI, aggro, loot drops) *and* `Flying` behavior (altitude, wing physics, aerial pathfinding). In a single-inheritance language like Lua or GDScript, you have to pick one parent and copy the other. In a language with multiple inheritance like C++, you get the diamond:

```
              Entity
             /      \
          Enemy    Flying
             \      /
           FlyingEnemy
```

Now `FlyingEnemy` inherits from `Entity` twice. Which `Entity`'s `update()` gets called? Which `position` field is the real one? C++ has `virtual` inheritance to handle this, but it's a language feature invented specifically to paper over a problem that shouldn't exist in the first place.

And this is just `FlyingEnemy`. What about `BurrowingEnemy`? `FlyingBurrowingEnemy`? `FlyingPlayerControlledEnemy` (a game mechanic where you possess a flying enemy)? Every new combination requires a new class or a new level of inheritance. The hierarchy that felt clean at the start becomes a taxonomy nightmare.

The real problem is that inheritance is an *is-a* relationship, and real game entities don't fit neatly into taxonomies. A `FlyingEnemy` isn't fundamentally *a* `Flying` thing or *an* `Enemy` thing — it's a thing that *has* flying behavior and *has* enemy behavior. That distinction is the whole game.

---

## 2. Composition Over Inheritance: Has-A vs Is-A

"Composition over inheritance" is one of those maxims that sounds obvious until you really internalize what it means in practice.

**Is-A thinking (OOP):** A `FlyingEnemy` IS A `Character`, IS AN `Enemy`, IS A `Flying` thing. You model the world as a taxonomy. Every entity has a fixed type that determines what it can do.

**Has-A thinking (ECS):** Entity #42 HAS a `Position` component, HAS a `Health` component, HAS an `AIBrain` component, HAS a `FlightController` component. The entity isn't *a* type of thing — it's a collection of data bags. What it *does* is determined entirely by what systems look at it.

This sounds like a minor philosophical shift but it has huge practical consequences. With has-a thinking:

- You want a new combination of behaviors? Add the right components. No new class required.
- You want to remove a behavior at runtime? Remove the component. A `Poisoned` enemy that gradually loses its `AIBrain` component stumbles around helplessly — you didn't have to write any special logic for that.
- You want a player-controlled enemy? Give it `PlayerInput` instead of `AIBrain`. The movement systems don't care which one it has.

Consider a concrete example: a chest in an RPG. In OOP, is a chest a `StaticObject`? An `Interactable`? Does it extend `DestructibleObject`? What if it's a Mimic — an enemy disguised as a chest? You'd need a `MimicChest` class that somehow inherits from both `Chest` and `Enemy`. In ECS, a chest is just an entity with `Position`, `Sprite`, `Interactable`, and `Inventory` components. A mimic is an entity with those same components *plus* `AIBrain`, `Health`, and a `TriggerBehavior` that swaps out `Interactable` for `AggroRange` when the player gets close. No new class. No special inheritance.

The mental model shift is this: **stop thinking about what something *is* and start thinking about what data it needs and what systems should operate on it.** An entity is just an ID. Everything interesting lives in the components attached to that ID.

---

## 3. The Blob Anti-Pattern

Here's how the blob happens. You start a project with a clean `Entity` base class:

```lua
-- Week 1: looks great
Entity = {}
Entity.x = 0
Entity.y = 0
Entity.sprite = nil
```

Then the game grows. A designer wants enemies to have health. So you add `health` and `maxHealth` to `Entity` — it's faster than making a new class. Then you need collision, so you add `collider`. Then some entities need to be interactable, so you add `interactable` and `onInteract`. Then AI, so you add `aiState` and `patrolPath`. Six months in:

```lua
Entity = {}

-- Position (everyone needs this)
Entity.x = 0
Entity.y = 0
Entity.z = 0  -- added when we went 3D, most entities ignore this

-- Rendering (most entities need this, not all)
Entity.sprite = nil
Entity.animation = nil
Entity.visible = true
Entity.layer = 0
Entity.shader = nil  -- added for the water effect, most things don't have a shader

-- Health (enemies and players need this, props don't)
Entity.health = nil
Entity.maxHealth = nil
Entity.invincible = false
Entity.deathEffect = nil

-- Physics (moving things only)
Entity.velocityX = 0
Entity.velocityY = 0
Entity.mass = 1
Entity.friction = 0.8
Entity.onGround = false

-- AI (enemies only)
Entity.aiState = nil
Entity.target = nil
Entity.patrolPath = nil
Entity.aggroRadius = nil
Entity.aiTimer = 0

-- Player input (player only)
Entity.inputBuffer = nil
Entity.lastDirection = nil
Entity.dashCooldown = 0
Entity.canDash = false

-- Inventory (player and chests)
Entity.inventory = nil
Entity.maxInventorySize = nil
Entity.gold = 0

-- Dialogue (NPCs only)
Entity.dialogueTree = nil
Entity.currentLine = nil
Entity.relationship = nil

-- Status effects (combat entities only)
Entity.poisoned = false
Entity.frozen = false
Entity.burning = false
Entity.stunTimer = 0

-- Network (multiplayer entities only — added in month 8)
Entity.networkId = nil
Entity.ownerId = nil
Entity.interpolatedX = 0
Entity.interpolatedY = 0

-- ... 20 more fields added by 6 different people over 8 months
```

Every entity in your game carries all of this. A wall tile has `dashCooldown` and `dialogueTree` and `networkId`. A chest has `aggroRadius` set to nil. Your `update()` function is a cascade of `if self.health then` and `if self.aiState then`. The `Entity` class is now a "God Object" — it knows about everything and touches everything.

The blob anti-pattern has specific symptoms:
- Most fields are `nil` for any given instance
- Adding a feature requires touching the base class, which means touching everyone
- You can't look at an entity and know what it actually *does* without reading the entire class
- Two systems both read and write the same fields in ways that conflict

This isn't a hypothetical. It's the default trajectory of a solo game project without architectural discipline.

---

## 4. Data/Logic Coupling

In OOP, data and behavior live together. A `Player` class has `x`, `y`, `health` *and* `move()`, `takeDamage()`, `render()`. This feels natural because the player is the one who moves and renders, right?

The problem is that this coupling makes every piece of behavior dependent on every piece of data, even when it shouldn't be. Consider:

**Testing:** You want to test whether your collision detection math is correct. But `collides(other)` is a method on `Entity`, which has a sprite, AI state, animation state — you have to instantiate a whole game entity with all its dependencies just to test a geometric intersection. In ECS, collision detection is a system that operates on `Position` and `Collider` components. To test it, you create two entities with just those two components. No sprites, no AI, no rendering pipeline.

**Reuse:** You have a `Player` and an `Enemy` that both need movement. In OOP, you either copy the movement code, put it in the shared `Character` parent (coupling everything that extends `Character` to movement logic they might not need), or use mixins (which are just composition with extra steps). In ECS, there's one `MovementSystem` that operates on anything with `Position` and `Velocity`. Players, enemies, projectiles, floating pickups — same system, no coupling.

**Iteration speed:** A designer wants to try making every entity with health also regenerate health over time. In OOP you find `Character.update()`, add the regen logic, and hope nothing else in the 2000-line file breaks. In ECS you write a `HealthRegenSystem` that operates on `Health` components, and it works on every entity that has health. Then you decide the player shouldn't have regen — you just remove `HealthRegen` from the player entity. The system itself didn't change.

**Performance:** OOP objects are scattered in memory because each instance is allocated separately, and their methods trigger virtual dispatch. ECS stores all `Position` components together in a contiguous array. The `MovementSystem` iterates that array linearly — extremely cache-friendly. For a game with thousands of entities this isn't academic, it's the difference between 60fps and 20fps.

The core insight: **data and the logic that operates on data evolve for different reasons.** Your position data format might change when you go from 2D to 3D. Your movement logic might change when you add ice physics. These changes don't need to be coupled. Keeping them separate means each can change independently.

---

## Code Walkthrough: Refactoring a Player Class to Components

Let's take a typical OOP player class and decompose it into ECS. The OOP version looks familiar:

**Pseudocode:**
```
class Player:
    x, y, vx, vy       -- position and velocity
    health, maxHealth   -- combat state
    sprite, animation   -- visual state

    update(dt):
        vx = getInput().x * speed
        vy = getInput().y * speed
        x += vx * dt
        y += vy * dt
        animation.update(dt)

    takeDamage(amount):
        health -= amount
        if health <= 0: die()

    render():
        sprite.draw(x, y, animation.frame)
```

**Lua (tiny-ecs / Love2D):**
```lua
-- OOP version: everything bundled
local Player = {}
Player.__index = Player

function Player.new(x, y)
    return setmetatable({
        x = x, y = y,
        vx = 0, vy = 0,
        health = 100, maxHealth = 100,
        sprite = love.graphics.newImage("player.png"),
        anim = Animation.new("player_walk", 8),
        speed = 150,
    }, Player)
end

function Player:update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("left")  then dx = -1 end
    if love.keyboard.isDown("right") then dx =  1 end
    if love.keyboard.isDown("up")    then dy = -1 end
    if love.keyboard.isDown("down")  then dy =  1 end

    self.vx = dx * self.speed
    self.vy = dy * self.speed
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.anim:update(dt)
end

function Player:takeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then self:die() end
end

function Player:draw()
    love.graphics.draw(self.sprite, self.x, self.y, 0, 1, 1,
        self.anim:getFrame())
end
```

Now the ECS decomposition. Components are pure data tables. Systems are functions that operate on entities with specific components.

**Pseudocode:**
```
-- Components: pure data, no methods
Position   = { x, y }
Velocity   = { vx, vy, speed }
Health     = { current, max }
Sprite     = { image, animation }
PlayerInput = {}   -- tag component, no data needed

-- Systems: pure logic, no data ownership
MovementSystem.update(dt):
    world.query(PlayerInput, Velocity).forEach(entity =>
        entity.velocity.vx = getInput().x * entity.velocity.speed
        entity.velocity.vy = getInput().y * entity.velocity.speed
    )

PhysicsSystem.update(dt):
    world.query(Position, Velocity).forEach(entity =>
        entity.position.x += entity.velocity.vx * dt
        entity.position.y += entity.velocity.vy * dt
    )

RenderSystem.draw():
    world.query(Position, Sprite).forEach(entity =>
        entity.sprite.image.draw(entity.position.x, entity.position.y)
    )
```

**Lua (tiny-ecs / Love2D):**
```lua
local tiny = require "tiny"

-- Components are just plain tables attached to an entity table
local function makePlayer(x, y)
    return {
        position = { x = x, y = y },
        velocity = { vx = 0, vy = 0, speed = 150 },
        health   = { current = 100, max = 100 },
        sprite   = {
            image = love.graphics.newImage("player.png"),
            anim  = Animation.new("player_walk", 8),
        },
        playerInput = true,  -- tag: this entity is player-controlled
    }
end

-- Movement system: reads PlayerInput tag + Velocity, writes Velocity
local movementSystem = tiny.processingSystem()
movementSystem.filter = tiny.requireAll("playerInput", "velocity")
function movementSystem:process(entity, dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("left")  then dx = -1 end
    if love.keyboard.isDown("right") then dx =  1 end
    if love.keyboard.isDown("up")    then dy = -1 end
    if love.keyboard.isDown("down")  then dy =  1 end
    entity.velocity.vx = dx * entity.velocity.speed
    entity.velocity.vy = dy * entity.velocity.speed
end

-- Physics system: reads Velocity, writes Position — works on ANYTHING with both
local physicsSystem = tiny.processingSystem()
physicsSystem.filter = tiny.requireAll("position", "velocity")
function physicsSystem:process(entity, dt)
    entity.position.x = entity.position.x + entity.velocity.vx * dt
    entity.position.y = entity.position.y + entity.velocity.vy * dt
end

-- Render system: reads Position + Sprite — works on ANYTHING with both
local renderSystem = tiny.system()
renderSystem.filter = tiny.requireAll("position", "sprite")
function renderSystem:draw()
    for _, entity in ipairs(self.entities) do
        entity.sprite.anim:update(love.timer.getDelta())
        love.graphics.draw(
            entity.sprite.image,
            entity.position.x,
            entity.position.y
        )
    end
end

-- World setup
local world = tiny.world(movementSystem, physicsSystem, renderSystem)
local player = makePlayer(100, 100)
tiny.addEntity(world, player)

-- Now add an enemy with the same physics — no new class needed
local enemy = {
    position = { x = 300, y = 200 },
    velocity = { vx = -30, vy = 0, speed = 30 },
    health   = { current = 50, max = 50 },
    sprite   = { image = love.graphics.newImage("enemy.png"), anim = Animation.new("enemy_walk", 6) },
    -- no playerInput: the movement system ignores this entity
    -- but physicsSystem and renderSystem will process it automatically
}
tiny.addEntity(world, enemy)
```

**GDScript (Godot):**
```gdscript
# Approach 1: Traditional Godot — node hierarchy (analogous to OOP)
# This is how most Godot beginners do it.

# Player.gd attached to a CharacterBody2D node
extends CharacterBody2D

@export var speed: float = 150.0
@export var max_health: int = 100

var health: int = max_health

func _physics_process(delta: float) -> void:
    var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = direction * speed
    move_and_slide()

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        die()

func die() -> void:
    queue_free()

# Everything is bundled into one node. Familiar, but you get the blob
# problem as the player node grows over time.

# ---

# Approach 2: Composition with child nodes — approximating ECS thinking in Godot
# Instead of one fat node, break responsibilities into child nodes.

# Scene tree:
# Player (Node2D)
# ├── HealthComponent (Node) — health.gd
# ├── MovementComponent (Node) — movement.gd
# ├── SpriteComponent (AnimatedSprite2D) — handles rendering
# └── InputComponent (Node) — input.gd

# health.gd
extends Node
class_name HealthComponent

signal died
signal health_changed(new_health: int, max_health: int)

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int) -> void:
    current_health -= amount
    health_changed.emit(current_health, max_health)
    if current_health <= 0:
        died.emit()

# movement.gd
extends Node
class_name MovementComponent

@export var speed: float = 150.0
# Gets the parent body and moves it — doesn't own position data
func move(direction: Vector2, delta: float) -> void:
    var body := get_parent() as CharacterBody2D
    if body:
        body.velocity = direction * speed
        body.move_and_slide()

# input.gd — reads input, delegates to movement component
extends Node
class_name InputComponent

@onready var movement: MovementComponent = $"../MovementComponent"

func _physics_process(delta: float) -> void:
    var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    movement.move(direction, delta)

# Player.gd — now just wires things together
extends CharacterBody2D

@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
    health.died.connect(_on_died)

func _on_died() -> void:
    queue_free()

# Key insight: HealthComponent works on ANY parent node — enemy, boss, barrel.
# You're not getting true ECS (no archetype storage, no query iteration),
# but you get the composition benefit: mix and match components per scene.
```

---

## Concept Quick Reference

| Term | OOP meaning | ECS meaning |
|---|---|---|
| **Entity** | An instance of a class | A unique integer ID with no behavior of its own |
| **Component** | Member variables on an object | A plain data struct attached to an entity ID |
| **System** | Methods on a class | A function that queries for entities with specific components and operates on them |
| **Inheritance** | Child class IS-A parent class | Not used — behavior comes from component composition |
| **Composition** | One object owns another object | An entity HAS a component; the combination determines behavior |
| **God Object / Blob** | A base class with every possible field | An anti-pattern; what you get when you avoid proper decomposition |
| **Diamond problem** | Ambiguous multiple inheritance | Doesn't arise in ECS — entities don't have types |
| **Tag component** | n/a | A zero-data component used as a boolean flag for system filtering |
| **World** | n/a | The ECS container that holds all entities, components, and systems |
| **Query** | n/a | Asking the world for all entities that have a specific set of components |

---

## Common Pitfalls

1. **Putting methods on components.** Components should be pure data structs. If you write `health:takeDamage(amount)` you're doing OOP inside ECS. Move that logic to a `DamageSystem`. The rule: components have fields, not functions.

2. **Making one component per entity.** If your `PlayerComponent` has everything the player needs, you've just renamed your God Object. Components should be small and single-purpose. `Position` is one component. `Health` is another. Split by responsibility, not by entity type.

3. **Systems that reach into other systems' data directly.** If your `RenderSystem` is querying `AIBrain` components to decide how to draw something, you've created coupling between unrelated systems. Use intermediate components (like `RenderState` or `VisualFlags`) to communicate between systems.

4. **Forgetting that ECS is overkill for small projects.** If your game has 20 entities and a three-week timeline, plain OOP or Godot's node system is fine. ECS pays off at scale — hundreds of entity types, thousands of instances, complex combinations of behaviors. Don't add architectural complexity to a game jam project.

5. **Confusing the ECS pattern with a specific library.** ECS is an architecture pattern. `tiny-ecs`, `bevy`, `flecs`, `EnTT` are implementations. You can do ECS with plain Lua tables and no library. Understanding the pattern first lets you evaluate and use any library effectively.

6. **Over-splitting components.** You don't need separate `XPosition` and `YPosition` components. Group data that always moves together. `Position` with `x` and `y` is correct. The split should be at logical responsibility boundaries, not field boundaries.

7. **Mixing system concerns in `update()` order without thinking about it.** Systems run in a specific order, and that order matters. Physics before collision, collision before damage, damage before death — get it wrong and you get one-frame bugs that are brutal to debug. Plan your system execution order deliberately.

---

## Exercises

**Exercise 1: Inheritance Archaeology (30–45 min)**

Take any OOP game project you've worked on (your own or an open-source one). Draw the inheritance hierarchy. Find at least one place where you'd need multiple inheritance to add a natural feature. Write down what you'd do instead with composition: what components would you create, and what systems would operate on them? You don't need to code it — just the design on paper.

*Stretch goal:* Find a God Object in the project. List every field on it and categorize them: which ones naturally cluster together into components? How many components would you end up with?

**Exercise 2: Blob Decomposition (45–60 min)**

Take this bloated entity class and decompose it into ECS components:

```lua
Entity = {
    x=0, y=0, vx=0, vy=0,
    health=100, maxHealth=100, invincible=false,
    sprite=nil, animation=nil, visible=true,
    aiState=nil, patrolPath=nil, aggroRadius=50,
    inputEnabled=false, dashCooldown=0,
    inventory=nil, gold=0,
    dialogueTree=nil,
}
```

List each component (name it, list its fields). Then decide: which systems would exist, and which components does each system require? Write it out as pseudocode — just component definitions and system filter lines, no full implementation needed.

*Stretch goal:* Implement one of the systems in actual Lua or GDScript. Pick the simplest one (position/velocity physics is a good start).

**Exercise 3: The Mimic Problem (60–90 min)**

Design an ECS architecture for a game that has:
- Chests (static, interactable, have inventory)
- Mimics (look like chests until the player gets close, then become enemies)
- Flying Mimics (mimic behavior + can move vertically)
- Player (controllable, has health and inventory)
- Bats (flying enemies, no inventory)

List all the components you'd need. Show which components each entity type starts with. Show what components change when a Mimic transforms. Write the system definitions (filter conditions only).

*Stretch goal:* Implement the transformation in Lua using tiny-ecs. When the player entity gets within 100 units of a mimic entity, remove `Interactable` and add `AIBrain` and `Velocity` to the mimic entity.

---

## Key Takeaways

- **Inheritance hierarchies break down** when you need entities that combine behaviors from different branches of the tree — the diamond problem is a symptom of forcing real game entities into taxonomies they don't fit.
- **ECS replaces IS-A with HAS-A**: an entity is just an ID, and its behavior is entirely determined by which components are attached to it and which systems process those components.
- **The blob anti-pattern is the default trajectory** of OOP game code — base classes accumulate fields over time until every entity carries data it doesn't use, and every change risks breaking everything.
- **Separating data from logic** enables independent testing, reuse across entity types, faster iteration when requirements change, and better runtime performance through cache-friendly data layout.
- **ECS is an architecture pattern, not a library** — you can implement it with plain tables, and understanding the pattern is more valuable than knowing any specific framework. The pattern is: entities are IDs, components are data, systems are logic that queries for components.

---

## What's Next

[Module 1: Entities, Components, Systems](module-01-entities-components-systems.md) — now that you understand *why* ECS exists, learn the actual triad: entities as IDs, components as pure data, systems as logic.

Back to [ECS Learning Roadmap](ecs-learning-roadmap.md)
