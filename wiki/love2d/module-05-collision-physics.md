# Module 5: Collision & Physics

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 5-7 hours
**Prerequisites:** [Module 4: Tilemaps & Levels](module-04-tilemaps-levels.md)

---

## Overview

Every game needs things to touch other things. A character lands on a platform. A bullet hits an enemy. A crate slides across the floor and stacks on another crate. Without collision detection and response, your game is just sprites passing through each other like ghosts.

This module gives you two paths, and you should understand both before committing to one.

**Path 1: bump.lua** -- A lightweight spatial hash library for grid-based collision. You define rectangles, move them, and bump.lua tells you what they hit and slides them along surfaces. This is what you want for platformers (think Celeste), top-down action games (think Zelda), and anything where you need tight, predictable control. Most 2D games should start here.

**Path 2: love.physics (Box2D)** -- A full rigid body physics simulation built into LOVE. Objects have mass, velocity, friction, and restitution. They bounce, stack, topple, and swing on joints. This is what you want for physics puzzles (think Angry Birds), ragdolls, or anything where realistic physical interaction is the core mechanic.

By the end of this module, you will have built either a platformer character that runs, jumps, and collects items using bump.lua, or a physics sandbox where you spawn shapes that bounce and stack using love.physics. Ideally, build both -- they teach different things and the contrast clarifies when to reach for each tool.

---

## Core Concepts

### 1. AABB Collision Detection

Before you reach for any library, you should understand the most fundamental collision test in 2D games: the **Axis-Aligned Bounding Box**, or **AABB**. This is two rectangles that do not rotate. "Axis-aligned" means their sides are parallel to the X and Y axes.

The overlap test is four comparisons. Two rectangles overlap if and only if they overlap on both axes simultaneously:

```lua
function check_aabb(a, b)
    return a.x < b.x + b.w and
           a.x + a.w > b.x and
           a.y < b.y + b.h and
           a.y + a.h > b.y
end
```

Read that out loud: "A's left edge is left of B's right edge, AND A's right edge is right of B's left edge, AND A's top edge is above B's bottom edge, AND A's bottom edge is below B's top edge." If all four are true, the rectangles overlap.

Here it is in context:

```lua
function love.load()
    box_a = { x = 100, y = 100, w = 50, h = 50 }
    box_b = { x = 300, y = 200, w = 80, h = 60 }
    colliding = false
end

function love.update(dt)
    -- Move box_a with the mouse
    box_a.x = love.mouse.getX() - box_a.w / 2
    box_a.y = love.mouse.getY() - box_a.h / 2

    colliding = check_aabb(box_a, box_b)
end

function love.draw()
    if colliding then
        love.graphics.setColor(1, 0, 0)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.rectangle("fill", box_a.x, box_a.y, box_a.w, box_a.h)

    love.graphics.setColor(0.5, 0.5, 1)
    love.graphics.rectangle("fill", box_b.x, box_b.y, box_b.w, box_b.h)
end
```

**When AABB is enough:** Collecting coins, triggering doors, checking if a bullet is near an enemy, simple top-down games with rectangular entities. Tons of shipped games use nothing fancier than this.

**When it is not enough:** Rotated sprites (AABB only works for axis-aligned rectangles), circular objects where corner overlap feels wrong, complex polygons, or anything that needs sliding collision response (where things push each other instead of just overlapping).

**Try this now:** Add a third box to the example above. Display text showing which pairs are currently colliding ("A-B", "A-C", "B-C"). You will immediately feel why checking N-vs-N collision gets tedious -- and why libraries exist.

---

### 2. Circle Collision

Circles are the second most common collision shape, and their detection is arguably even simpler than AABB. Two circles collide when the **distance between their centers** is less than the **sum of their radii**.

```lua
function check_circle(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dist_sq = dx * dx + dy * dy
    local radii = a.radius + b.radius
    return dist_sq < radii * radii
end
```

Notice we compare squared distance against squared radii sum. This avoids calling `math.sqrt`, which is slower. For collision detection that runs every frame against potentially many pairs, skipping the square root matters.

**Circle vs. Rectangle** is trickier. The idea is to find the closest point on the rectangle to the circle's center, then check if that point is within the circle's radius:

```lua
function check_circle_rect(circle, rect)
    -- Find the closest point on the rectangle to the circle center
    local closest_x = math.max(rect.x, math.min(circle.x, rect.x + rect.w))
    local closest_y = math.max(rect.y, math.min(circle.y, rect.y + rect.h))

    local dx = circle.x - closest_x
    local dy = circle.y - closest_y
    return (dx * dx + dy * dy) < (circle.radius * circle.radius)
end
```

**When to use circles:** Anything round -- balls, bullets, explosions, proximity checks ("is the player near this NPC?"). Circle collision also works well as a rough first pass before doing more expensive polygon checks.

**Try this now:** Make a circle that follows the mouse and a few rectangles scattered on screen. Display a different color when the circle overlaps each rectangle. Then add a couple of circles too and test circle-circle collision. Notice how circle collision "feels" more natural for round objects than wrapping them in a bounding box.

---

### 3. bump.lua Basics

Hand-writing collision checks and responses for every entity in your game gets old fast. **bump.lua** is a library by kikito (the same developer behind anim8) that handles collision detection *and response* for axis-aligned rectangles using a **spatial hash grid**.

The spatial hash concept: bump.lua divides your game world into a grid of cells (default 64x64 pixels). Each entity is registered in the cells it occupies. When you move an entity, bump only checks for collisions against other entities in the same cells -- not every entity in the world. This makes it fast even with hundreds of objects.

**Installation:** Download `bump.lua` from https://github.com/kikito/bump.lua and place it in your project (or a `lib/` folder).

```lua
local bump = require("lib.bump")

function love.load()
    -- Create a bump world (64 is the cell size)
    world = bump.newWorld(64)

    -- Add a player (x, y, width, height)
    player = { x = 100, y = 100, w = 32, h = 32 }
    world:add(player, player.x, player.y, player.w, player.h)

    -- Add a wall
    wall = { x = 200, y = 150, w = 100, h = 20 }
    world:add(wall, wall.x, wall.y, wall.w, wall.h)
end
```

The critical thing to understand: bump.lua uses the **item itself** (the table) as the key. When you call `world:add(player, ...)`, bump stores a reference to the `player` table. Later, when you call `world:move(player, ...)`, bump knows which object you mean because it is the same table reference.

**Moving with collision response** is where bump.lua shines. Instead of setting the position directly, you *request* a move and bump calculates where the object actually ends up:

```lua
function love.update(dt)
    local dx, dy = 0, 0
    local speed = 200

    if love.keyboard.isDown("left")  then dx = -speed * dt end
    if love.keyboard.isDown("right") then dx =  speed * dt end
    if love.keyboard.isDown("up")    then dy = -speed * dt end
    if love.keyboard.isDown("down")  then dy =  speed * dt end

    -- Request a move to a goal position
    local goal_x = player.x + dx
    local goal_y = player.y + dy

    -- world:move returns the ACTUAL position after collision
    local actual_x, actual_y, cols, len = world:move(player, goal_x, goal_y)

    player.x = actual_x
    player.y = actual_y

    -- cols is a table of collision info, len is the count
    for i = 1, len do
        local col = cols[i]
        print("Collided with", col.other, "on", col.normal.x, col.normal.y)
    end
end
```

The return values of `world:move()` are essential:
- **actualX, actualY** -- where the object ended up after collision response
- **cols** -- a table of collision objects, each containing `col.other` (what you hit), `col.normal` (the collision surface direction), `col.touch` (the contact point), and more
- **len** -- the number of collisions (use this instead of `#cols` because bump reuses the table)

**Lua gotcha:** bump.lua returns `len` separately instead of relying on `#cols` because the internal collision table is reused between calls for performance. Always iterate with `for i = 1, len` and never `for i = 1, #cols`.

**Try this now:** Create a player and five wall rectangles arranged to form a room. Move the player with arrow keys. Notice how the player slides along walls instead of stopping dead -- that is bump.lua's default "slide" response doing the work for you.

---

### 4. bump.lua Response Types

When an object collides with something during `world:move()`, bump.lua needs to know *how* to respond. Should it slide along the surface? Pass through? Stop dead? Bounce off? You control this with a **filter function**.

The filter function receives the item being moved and the other item it would collide with. It returns a string indicating the response type:

```lua
local function collision_filter(item, other)
    if other.is_coin then return "cross" end    -- pass through, but register the hit
    if other.is_wall then return "slide" end     -- slide along the surface
    if other.is_bumper then return "bounce" end  -- reflect off
    return "slide"                               -- default
end

local actual_x, actual_y, cols, len = world:move(player, goal_x, goal_y, collision_filter)
```

The four built-in response types:

**"slide" (default)** -- The object moves as far as it can toward the goal, then slides along the surface of whatever it hit. This is what you want for walls, floors, and solid obstacles. Think of pushing a box along a wall -- you keep moving parallel to the wall.

**"cross"** -- The object passes through the other object completely, reaching its goal position, but the collision is still reported in the `cols` table. Perfect for collectibles, trigger zones, damage areas, and any object you want to detect but not block movement.

**"touch"** -- The object moves to the point of contact and stops. No sliding. This is useful for bullets (they stop when they hit something) or for "sticky" surfaces.

**"bounce"** -- The object reflects off the surface. The angle of incidence equals the angle of reflection. Think of a Breakout ball hitting a paddle.

Here is a practical filter for a platformer:

```lua
local function platformer_filter(item, other)
    if other.type == "coin"     then return "cross" end
    if other.type == "spike"    then return "cross" end
    if other.type == "platform" then return "slide" end
    if other.type == "wall"     then return "slide" end
    if other.type == "spring"   then return "touch" end
    return "slide"
end
```

You can also return `nil` or `false` from the filter to **ignore** the collision entirely. The object will pass through as if the other item does not exist, and no collision will be reported:

```lua
local function filter(item, other)
    if other.type == "ghost_wall" and item.has_ghost_power then
        return nil  -- player phases through ghost walls when powered up
    end
    return "slide"
end
```

**Try this now:** Set up a scene with three types of objects -- solid walls (slide), coins (cross), and bumpers (bounce). Move the player through them. When you cross through a coin, remove it from the world with `world:remove(coin)` and increment a score counter.

---

### 5. Building a Platformer with bump.lua

Platformers need gravity, grounded detection, jumping, and usually some form of coyote time or jump buffering to feel good. Here is how each of those works with bump.lua.

**Gravity** is just a constant downward acceleration applied every frame:

```lua
local GRAVITY = 800        -- pixels per second squared
local JUMP_VELOCITY = -350 -- negative = upward
local MOVE_SPEED = 200

function love.load()
    local bump = require("lib.bump")
    world = bump.newWorld(64)

    player = {
        x = 100, y = 100, w = 16, h = 24,
        vx = 0, vy = 0,
        grounded = false,
        jump_timer = 0,      -- coyote time
        jump_buffer = 0,     -- jump buffering
    }
    world:add(player, player.x, player.y, player.w, player.h)

    -- Add some platforms
    local platforms = {
        { x = 0,   y = 400, w = 800, h = 32, type = "platform" },  -- ground
        { x = 200, y = 300, w = 120, h = 16, type = "platform" },
        { x = 400, y = 220, w = 120, h = 16, type = "platform" },
        { x = 50,  y = 250, w = 80,  h = 16, type = "platform" },
    }
    for _, p in ipairs(platforms) do
        world:add(p, p.x, p.y, p.w, p.h)
    end
end
```

**The update loop** applies gravity, handles input, and uses bump.lua for movement:

```lua
local function player_filter(item, other)
    if other.type == "coin" then return "cross" end
    return "slide"
end

function love.update(dt)
    -- Horizontal input
    player.vx = 0
    if love.keyboard.isDown("left")  then player.vx = -MOVE_SPEED end
    if love.keyboard.isDown("right") then player.vx =  MOVE_SPEED end

    -- Apply gravity
    player.vy = player.vy + GRAVITY * dt

    -- Coyote time: allow jumping briefly after walking off a ledge
    if player.grounded then
        player.jump_timer = 0.1  -- 100ms of grace
    else
        player.jump_timer = player.jump_timer - dt
    end

    -- Jump buffering: remember jump press briefly before landing
    player.jump_buffer = player.jump_buffer - dt

    -- Attempt jump if buffer is active and coyote time remains
    if player.jump_buffer > 0 and player.jump_timer > 0 then
        player.vy = JUMP_VELOCITY
        player.jump_timer = 0
        player.jump_buffer = 0
    end

    -- Variable jump height: cut velocity short on key release
    if not love.keyboard.isDown("space") and player.vy < 0 then
        player.vy = player.vy * 0.5  -- dampen upward velocity
    end

    -- Move with bump.lua
    local goal_x = player.x + player.vx * dt
    local goal_y = player.y + player.vy * dt
    local ax, ay, cols, len = world:move(player, goal_x, goal_y, player_filter)

    player.x = ax
    player.y = ay

    -- Check collision normals to determine grounded state
    player.grounded = false
    for i = 1, len do
        local col = cols[i]
        if col.normal.y == -1 then
            -- Hit something below us (floor/platform)
            player.grounded = true
            player.vy = 0
        elseif col.normal.y == 1 then
            -- Hit something above us (ceiling)
            player.vy = 0
        end

        -- Handle collectibles
        if col.other.type == "coin" then
            world:remove(col.other)
            -- increment score, play sound, etc.
        end
    end
end

function love.keypressed(key)
    if key == "space" then
        player.jump_buffer = 0.15  -- 150ms buffer window
    end
end
```

A few things worth calling out:

**Grounded detection** uses collision normals. When `col.normal.y == -1`, it means the player hit something below them -- that is a floor. A normal of `(0, -1)` points upward, meaning the surface the player landed on faces upward. This is more reliable than checking `player.vy == 0` because the player's velocity might be zero for other reasons.

**Coyote time** gives the player a brief window (about 100ms) to jump after walking off a ledge. Without it, players feel like the game "eats" their inputs. Celeste uses coyote time extensively, and it is one of the reasons the game feels so responsive despite being brutally difficult.

**Jump buffering** remembers a jump press for a short window before landing. If the player hits jump 100ms before touching the ground, the jump triggers the instant they land. Again, this is standard in modern platformers.

**Variable jump height** works by reducing upward velocity when the player releases the jump button early. Hold for a high jump, tap for a low jump. This is the technique used in virtually every Mario game.

**One-way platforms** (platforms you can jump through from below but stand on from above) require a filter tweak:

```lua
local function player_filter(item, other)
    if other.type == "one_way" then
        -- Only collide if player is moving downward
        -- and player's feet are above the platform
        if item.vy > 0 and item.y + item.h <= other.y + 4 then
            return "slide"
        end
        return nil  -- pass through
    end
    return "slide"
end
```

**A note on slopes:** bump.lua does not natively support slopes. It is an axis-aligned rectangle library. If you need slopes, you have a few options: fake them with staircase-like stacks of thin rectangles, use a different library (like HC), or switch to love.physics for that section of your game. Many successful platformers simply avoid slopes entirely -- Celeste's levels are almost entirely grid-aligned.

**Try this now:** Build the platformer above. Then add three coins using the "cross" filter that disappear when collected. Add a simple score counter displayed on screen.

---

### 6. Top-Down Collision with bump.lua

Top-down games (think classic Zelda, Stardew Valley, or Undertale's overworld) use bump.lua differently from platformers. The big difference: **no gravity**. The player moves freely in all four (or eight) directions, and walls simply block movement.

```lua
function love.load()
    local bump = require("lib.bump")
    world = bump.newWorld(64)

    player = { x = 200, y = 200, w = 16, h = 16, speed = 150 }
    world:add(player, player.x, player.y, player.w, player.h)

    -- Room walls
    local walls = {
        { x = 0,   y = 0,   w = 400, h = 16 },   -- top
        { x = 0,   y = 284, w = 400, h = 16 },   -- bottom
        { x = 0,   y = 0,   w = 16,  h = 300 },   -- left
        { x = 384, y = 0,   w = 16,  h = 300 },   -- right
        -- Interior obstacle
        { x = 150, y = 100, w = 64,  h = 64 },
    }
    for _, w in ipairs(walls) do
        w.type = "wall"
        world:add(w, w.x, w.y, w.w, w.h)
    end

    -- An NPC
    npc = { x = 300, y = 150, w = 16, h = 16, type = "npc" }
    world:add(npc, npc.x, npc.y, npc.w, npc.h)
end

function love.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("w", "up")    then dy = -1 end
    if love.keyboard.isDown("s", "down")  then dy =  1 end
    if love.keyboard.isDown("a", "left")  then dx = -1 end
    if love.keyboard.isDown("d", "right") then dx =  1 end

    -- Normalize diagonal movement (prevent going 41% faster diagonally)
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx = dx / len
        dy = dy / len
    end

    local goal_x = player.x + dx * player.speed * dt
    local goal_y = player.y + dy * player.speed * dt

    local filter = function(item, other)
        if other.type == "npc" then return "cross" end
        return "slide"
    end

    local ax, ay, cols, len = world:move(player, goal_x, goal_y, filter)
    player.x = ax
    player.y = ay

    -- Check for NPC interaction
    for i = 1, len do
        if cols[i].other.type == "npc" then
            -- Player is overlapping the NPC -- show interaction prompt
        end
    end
end
```

The key difference from platformer code is the movement model. In a platformer, horizontal movement is direct (set `vx` to speed or zero) while vertical movement is governed by gravity. In top-down, both axes behave identically -- direct input control, no acceleration, no gravity.

**Sliding along walls** is bump.lua's best feature in top-down games. When the player walks diagonally into a wall, they do not stop dead -- they slide along the wall in whichever axis is not blocked. This feels natural and responsive. Without it (if you just stopped all movement on collision), diagonal movement near walls would feel sticky and frustrating.

**NPC collision** can be handled with "slide" (NPCs are solid obstacles the player pushes against) or "cross" (the player walks through NPCs but can detect overlap for interaction prompts). The choice depends on your game's feel.

**Try this now:** Build the room above. Add a second NPC. When the player overlaps an NPC, display that NPC's name above them. Add a locked door (a wall segment) that disappears when the player presses a button while overlapping a specific NPC.

---

### 7. love.physics (Box2D) Basics

LOVE ships with a full Box2D physics engine accessible through `love.physics`. This is a completely different paradigm from bump.lua. Instead of moving objects yourself and checking for collisions, you describe objects with physical properties (mass, shape, bounciness) and let the simulation handle everything.

Box2D has a four-part architecture. Understanding this hierarchy is critical:

1. **World** -- The simulation container. Holds all bodies. Has gravity settings. You step it forward each frame.
2. **Body** -- A point in space with position, rotation, velocity, and mass. Think of it as the "skeleton" of a physics object. A body on its own has no shape.
3. **Shape** -- Defines the collision geometry: circle, rectangle, polygon, edge, chain. A shape on its own has no physics properties.
4. **Fixture** -- Connects a shape to a body. Adds physical material properties: density, friction, restitution (bounciness). One body can have multiple fixtures (a character might have a circle body and a rectangle sensor).

```lua
function love.load()
    love.physics.setMeter(64)  -- 64 pixels = 1 meter
    world = love.physics.newWorld(0, 9.81 * 64, true)  -- gravity x, y, sleep

    -- Ground: static body (does not move)
    ground = {}
    ground.body = love.physics.newBody(world, 400, 550, "static")
    ground.shape = love.physics.newRectangleShape(800, 50)
    ground.fixture = love.physics.newFixture(ground.body, ground.shape)

    -- A dynamic box that will fall
    box = {}
    box.body = love.physics.newBody(world, 400, 100, "dynamic")
    box.shape = love.physics.newRectangleShape(50, 50)
    box.fixture = love.physics.newFixture(box.body, box.shape, 1)  -- density = 1
    box.fixture:setRestitution(0.5)  -- bouncy
end

function love.update(dt)
    world:update(dt)  -- step the simulation
end

function love.draw()
    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.polygon("fill", ground.body:getWorldPoints(
        ground.shape:getPoints()))

    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.polygon("fill", box.body:getWorldPoints(
        box.shape:getPoints()))
end
```

**The meter scale factor** is the single most confusing part of love.physics. Box2D was designed for objects measured in meters (0.1 to 10 meters). Your game world is in pixels (maybe 32 to 800 pixels). If you create a Box2D body at pixel coordinates without setting the meter scale, Box2D thinks your objects are enormous -- hundreds of meters across -- and the physics will look wrong. Objects will move like they are in slow-motion space.

`love.physics.setMeter(64)` tells LOVE that 64 pixels equals 1 meter. A 64x64 pixel box is then 1x1 meter in physics space -- a reasonable size. Gravity of `9.81 * 64` means 9.81 meters/second-squared, scaled to pixel coordinates. **Call `setMeter` before creating the world.**

**Drawing physics objects** uses `body:getWorldPoints(shape:getPoints())`. The shape stores its vertices in local space (relative to the body). `getWorldPoints` transforms them to world space (accounting for position and rotation). Then `love.graphics.polygon` draws the result.

**The `true` in `newWorld`** enables sleeping. Bodies that come to rest "sleep" and stop being simulated until something disturbs them. This is a performance optimization -- leave it on.

**Try this now:** Run the example above. Then change the restitution to 1.0 (perfectly bouncy) and 0.0 (no bounce). Change the gravity to 0 and give the box an initial velocity with `box.body:setLinearVelocity(200, -300)`. Get a feel for how these parameters interact.

---

### 8. love.physics Body Types

Box2D has three body types, and choosing correctly is essential:

**"static"** -- Does not move, ever. Not affected by gravity, collisions, or forces. Use for: ground, walls, platforms, level geometry. Static bodies are optimized internally -- the engine knows they never move, so it does not waste time simulating them.

**"dynamic"** -- Fully simulated. Affected by gravity, forces, impulses, and collisions. Use for: the player, enemies, projectiles, crates, anything that should move and react to physics.

**"kinematic"** -- Moves, but is not affected by forces or collisions from dynamic bodies. You control its velocity directly. Use for: moving platforms, elevators, conveyor belts -- things that move on a predefined path and push dynamic bodies around but are not themselves pushed.

```lua
-- Static: the ground
ground.body = love.physics.newBody(world, 400, 550, "static")

-- Dynamic: a crate that falls and bounces
crate.body = love.physics.newBody(world, 200, 100, "dynamic")

-- Kinematic: a moving platform
platform.body = love.physics.newBody(world, 300, 400, "kinematic")
platform.body:setLinearVelocity(50, 0)  -- moves right at 50 px/s
```

A common beginner mistake is making walls "dynamic" and wondering why they get pushed away when the player bumps them. Walls are static. If you want a wall the player can destroy, make it dynamic but give it enormous mass, or start it as static and switch it to dynamic when it should break.

Here is a practical example with all three types:

```lua
function love.load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 9.81 * 64, true)

    objects = {}

    -- Static ground
    local ground = make_box(400, 580, 800, 40, "static")
    ground.fixture:setFriction(0.8)
    table.insert(objects, ground)

    -- Static walls
    table.insert(objects, make_box(0, 300, 20, 600, "static"))
    table.insert(objects, make_box(800, 300, 20, 600, "static"))

    -- Dynamic crates
    for i = 1, 5 do
        local crate = make_box(300 + i * 30, 50 * i, 40, 40, "dynamic")
        crate.fixture:setRestitution(0.3)
        crate.fixture:setFriction(0.5)
        table.insert(objects, crate)
    end

    -- Kinematic moving platform
    moving_platform = make_box(400, 450, 120, 16, "kinematic")
    moving_platform.body:setLinearVelocity(80, 0)
    moving_platform.direction = 1
    table.insert(objects, moving_platform)
end

function make_box(x, y, w, h, body_type)
    local obj = {}
    obj.body = love.physics.newBody(world, x, y, body_type)
    obj.shape = love.physics.newRectangleShape(w, h)
    obj.fixture = love.physics.newFixture(obj.body, obj.shape, 1)
    return obj
end

function love.update(dt)
    -- Reverse the moving platform at screen edges
    local px = moving_platform.body:getX()
    if px > 600 or px < 200 then
        moving_platform.direction = -moving_platform.direction
        moving_platform.body:setLinearVelocity(
            80 * moving_platform.direction, 0)
    end

    world:update(dt)
end
```

**Try this now:** Run the example with crates falling onto the moving platform. Then change the platform to dynamic and watch how the crates push it around instead. That is the difference between kinematic and dynamic in action.

---

### 9. love.physics Contacts & Callbacks

Box2D fires callbacks when fixtures begin touching, stop touching, and during the contact resolution. These are how you detect collisions and respond to them.

```lua
function love.load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 9.81 * 64, true)

    -- Set up collision callbacks on the world
    world:setCallbacks(begin_contact, end_contact, pre_solve, post_solve)

    -- ... create bodies and fixtures ...
end

function begin_contact(a, b, contact)
    -- a and b are Fixtures
    local obj_a = a:getUserData()
    local obj_b = b:getUserData()

    if obj_a and obj_b then
        print(obj_a.name .. " hit " .. obj_b.name)
    end
end

function end_contact(a, b, contact)
    -- Fixtures a and b stopped touching
end

function pre_solve(a, b, contact)
    -- Called before the collision is resolved
    -- You can disable the contact here:
    -- contact:setEnabled(false)
end

function post_solve(a, b, contact, normal_impulse, tangent_impulse)
    -- Called after resolution. normal_impulse tells you how hard the impact was.
    if normal_impulse > 100 then
        -- Big impact -- play crash sound, spawn particles
    end
end
```

**User data** is how you attach game information to physics objects. Without it, you just have anonymous fixtures bumping into each other:

```lua
local crate = make_box(200, 100, 40, 40, "dynamic")
crate.fixture:setUserData({ name = "crate", type = "destructible", health = 3 })

local spike = make_box(400, 550, 20, 20, "static")
spike.fixture:setUserData({ name = "spike", type = "hazard", damage = 1 })
```

**Collision categories and masks** let you control which types of objects can collide with each other without needing filter functions. Each fixture has a category (a bit flag) and a mask (which categories it collides with):

```lua
-- Categories (powers of 2)
local CAT_PLAYER = 1
local CAT_ENEMY  = 2
local CAT_BULLET = 4
local CAT_WALL   = 8

-- Player collides with enemies, walls, but not own bullets
player.fixture:setCategory(CAT_PLAYER)
player.fixture:setMask(CAT_BULLET)  -- ignore bullets

-- Enemy collides with everything
enemy.fixture:setCategory(CAT_ENEMY)

-- Bullet collides with enemies and walls, not player
bullet.fixture:setCategory(CAT_BULLET)
bullet.fixture:setMask(CAT_PLAYER)  -- ignore player
```

This is efficient because the filtering happens inside Box2D before contacts are even generated -- no Lua callback overhead for ignored collisions.

**Try this now:** Create a scene with a ball that drops onto a platform. Use `beginContact` to print a message when they collide. Then use `postSolve` to check the impact force and change the ball's color when it hits hard enough.

---

### 10. Choosing Your Approach

This is the decision that matters most, and getting it wrong early costs you time. Here is a practical decision matrix:

| Criterion | bump.lua | love.physics (Box2D) |
|---|---|---|
| **Setup complexity** | Low -- one file, no configuration | High -- world, body, shape, fixture per object |
| **Movement control** | You control position directly | Physics controls position; you apply forces |
| **Collision response** | Slide, cross, touch, bounce | Full rigid body: friction, restitution, torque |
| **Rotation** | Not supported (axis-aligned only) | Full rotation simulation |
| **Stacking/piling** | Not built-in | Automatic and realistic |
| **Performance** | Excellent for hundreds of rectangles | Good, but heavier per-object overhead |
| **Determinism** | Predictable, same input = same output | Mostly deterministic, but floating point edge cases exist |
| **Learning curve** | Low | Moderate to high |
| **Good for** | Platformers, top-down, puzzle, most 2D games | Physics puzzles, destruction, vehicles, ragdolls |

**Use bump.lua when:**
- You want tight, predictable control over player movement (platformers, top-down action)
- Your collision shapes are rectangles
- You do not need realistic physics (stacking, tumbling, swinging)
- You are making your first few games and want simplicity
- You are building something like Celeste, Spelunky, Stardew Valley, or Undertale

**Use love.physics when:**
- Physics interaction IS the gameplay (Angry Birds, Cut the Rope, World of Goo)
- You need objects to stack, topple, roll, or swing
- You want joints (ropes, springs, hinges, motors)
- You are building a vehicle or ragdoll system
- You want realistic projectile trajectories with gravity and air resistance

**Hybrid approaches** are possible but tricky. Some games use bump.lua for the player and level collision, then spawn love.physics objects for specific destruction or particle effects. The key rule: do not have the same object managed by both systems simultaneously. One system owns the position, the other is just visual.

**When Box2D is overkill:** If you catch yourself fighting Box2D to make a character move predictably -- disabling rotation, setting linear damping, manually zeroing velocity -- you probably want bump.lua. Box2D is not designed for tightly controlled character movement. It is designed for simulating physical objects. Using it as a character controller is like using a bulldozer to plant flowers -- technically possible, but the wrong tool.

---

## Code Walkthrough

### Walkthrough 1: Platformer with bump.lua

A complete, runnable platformer with running, jumping, coin collection, coyote time, and variable jump height.

```lua
-- main.lua: Platformer with bump.lua
local bump = require("lib.bump")

-- Constants
local GRAVITY = 900
local JUMP_VEL = -380
local MOVE_SPEED = 200
local COYOTE_TIME = 0.08
local JUMP_BUFFER_TIME = 0.12

local world, player, coins, score

local function player_filter(item, other)
    if other.type == "coin" then return "cross" end
    return "slide"
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    world = bump.newWorld(64)
    score = 0

    -- Player
    player = {
        x = 50, y = 300, w = 14, h = 24,
        vx = 0, vy = 0,
        grounded = false,
        coyote = 0,
        jump_buffer = 0,
        facing = 1,
        type = "player",
    }
    world:add(player, player.x, player.y, player.w, player.h)

    -- Level geometry
    local walls = {
        -- Ground
        { x = 0,   y = 432, w = 800, h = 48, type = "wall" },
        -- Platforms
        { x = 100, y = 350, w = 100, h = 16, type = "wall" },
        { x = 280, y = 280, w = 120, h = 16, type = "wall" },
        { x = 450, y = 330, w = 80,  h = 16, type = "wall" },
        { x = 580, y = 260, w = 100, h = 16, type = "wall" },
        { x = 350, y = 180, w = 100, h = 16, type = "wall" },
        -- Walls
        { x = 0,   y = 0,   w = 16,  h = 480, type = "wall" },
        { x = 784, y = 0,   w = 16,  h = 480, type = "wall" },
        -- Ceiling
        { x = 0,   y = 0,   w = 800, h = 16,  type = "wall" },
    }
    for _, w in ipairs(walls) do
        world:add(w, w.x, w.y, w.w, w.h)
    end

    -- Coins
    coins = {
        { x = 130, y = 326, w = 12, h = 12, type = "coin", alive = true },
        { x = 320, y = 256, w = 12, h = 12, type = "coin", alive = true },
        { x = 480, y = 306, w = 12, h = 12, type = "coin", alive = true },
        { x = 610, y = 236, w = 12, h = 12, type = "coin", alive = true },
        { x = 380, y = 156, w = 12, h = 12, type = "coin", alive = true },
    }
    for _, c in ipairs(coins) do
        world:add(c, c.x, c.y, c.w, c.h)
    end
end

function love.update(dt)
    -- Horizontal movement
    player.vx = 0
    if love.keyboard.isDown("a", "left") then
        player.vx = -MOVE_SPEED
        player.facing = -1
    end
    if love.keyboard.isDown("d", "right") then
        player.vx = MOVE_SPEED
        player.facing = 1
    end

    -- Gravity
    player.vy = player.vy + GRAVITY * dt

    -- Cap fall speed to prevent tunneling through thin platforms
    if player.vy > 600 then player.vy = 600 end

    -- Coyote time
    if player.grounded then
        player.coyote = COYOTE_TIME
    else
        player.coyote = player.coyote - dt
    end

    -- Jump buffer
    player.jump_buffer = player.jump_buffer - dt

    -- Execute jump
    if player.jump_buffer > 0 and player.coyote > 0 then
        player.vy = JUMP_VEL
        player.coyote = 0
        player.jump_buffer = 0
    end

    -- Variable jump height: release early for short hop
    if not love.keyboard.isDown("space", "w", "up") and player.vy < JUMP_VEL * 0.5 then
        player.vy = JUMP_VEL * 0.5
    end

    -- Move with collision
    local goal_x = player.x + player.vx * dt
    local goal_y = player.y + player.vy * dt
    local ax, ay, cols, len = world:move(player, goal_x, goal_y, player_filter)

    player.x = ax
    player.y = ay

    -- Process collisions
    player.grounded = false
    for i = 1, len do
        local col = cols[i]

        if col.normal.y == -1 then
            player.grounded = true
            player.vy = 0
        elseif col.normal.y == 1 then
            player.vy = 0  -- bonk head on ceiling
        end

        -- Coin collection
        if col.other.type == "coin" and col.other.alive then
            col.other.alive = false
            world:remove(col.other)
            score = score + 1
        end
    end
end

function love.keypressed(key)
    if key == "space" or key == "w" or key == "up" then
        player.jump_buffer = JUMP_BUFFER_TIME
    end
    if key == "escape" then
        love.event.quit()
    end
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.15)

    -- Draw walls
    love.graphics.setColor(0.4, 0.4, 0.5)
    local items, item_len = world:getItems()
    for i = 1, item_len do
        local item = items[i]
        if item.type == "wall" then
            local x, y, w, h = world:getRect(item)
            love.graphics.rectangle("fill", x, y, w, h)
        end
    end

    -- Draw coins
    love.graphics.setColor(1, 0.85, 0)
    for _, c in ipairs(coins) do
        if c.alive then
            love.graphics.rectangle("fill", c.x, c.y, c.w, c.h)
        end
    end

    -- Draw player
    love.graphics.setColor(0.3, 0.8, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    -- Draw HUD
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Coins: " .. score .. " / " .. #coins, 20, 20)

    if player.grounded then
        love.graphics.print("GROUNDED", 20, 40)
    end
end
```

This is a complete, self-contained platformer. Drop in `bump.lua` and run it. The player runs, jumps with variable height, has coyote time and jump buffering, collects coins, and slides along all surfaces. From here, you would add sprites, animation, enemies, and level design -- but the physics and collision foundation is solid.

---

### Walkthrough 2: Physics Sandbox with love.physics

A sandbox where you click to spawn shapes that fall, bounce, and stack.

```lua
-- main.lua: Physics sandbox with love.physics

local objects = {}
local ground, wall_left, wall_right

function love.load()
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 9.81 * 64, true)

    -- Ground
    ground = make_static_box(400, 580, 800, 40)

    -- Walls
    wall_left = make_static_box(10, 300, 20, 600)
    wall_right = make_static_box(790, 300, 20, 600)

    -- Spawn mode
    spawn_mode = "box"  -- "box", "circle", "triangle"
end

function make_static_box(x, y, w, h)
    local obj = {}
    obj.body = love.physics.newBody(world, x, y, "static")
    obj.shape = love.physics.newRectangleShape(w, h)
    obj.fixture = love.physics.newFixture(obj.body, obj.shape)
    obj.fixture:setFriction(0.6)
    obj.kind = "box"
    obj.w = w
    obj.h = h
    return obj
end

function spawn_box(x, y)
    local size = 20 + love.math.random() * 40
    local obj = {}
    obj.body = love.physics.newBody(world, x, y, "dynamic")
    obj.shape = love.physics.newRectangleShape(size, size)
    obj.fixture = love.physics.newFixture(obj.body, obj.shape, 1)
    obj.fixture:setRestitution(0.3 + love.math.random() * 0.4)
    obj.fixture:setFriction(0.5)
    obj.body:setAngularVelocity((love.math.random() - 0.5) * 5)
    obj.kind = "box"
    obj.color = { 0.3 + love.math.random() * 0.7,
                  0.3 + love.math.random() * 0.7,
                  0.3 + love.math.random() * 0.7 }
    table.insert(objects, obj)
end

function spawn_circle(x, y)
    local radius = 10 + love.math.random() * 25
    local obj = {}
    obj.body = love.physics.newBody(world, x, y, "dynamic")
    obj.shape = love.physics.newCircleShape(radius)
    obj.fixture = love.physics.newFixture(obj.body, obj.shape, 1)
    obj.fixture:setRestitution(0.5 + love.math.random() * 0.5)
    obj.fixture:setFriction(0.3)
    obj.kind = "circle"
    obj.radius = radius
    obj.color = { 0.3 + love.math.random() * 0.7,
                  0.3 + love.math.random() * 0.7,
                  0.3 + love.math.random() * 0.7 }
    table.insert(objects, obj)
end

function spawn_triangle(x, y)
    local size = 20 + love.math.random() * 30
    local obj = {}
    obj.body = love.physics.newBody(world, x, y, "dynamic")
    obj.shape = love.physics.newPolygonShape(
        0, -size,
        -size * 0.866, size * 0.5,
        size * 0.866, size * 0.5
    )
    obj.fixture = love.physics.newFixture(obj.body, obj.shape, 1)
    obj.fixture:setRestitution(0.4)
    obj.fixture:setFriction(0.5)
    obj.kind = "triangle"
    obj.color = { 0.3 + love.math.random() * 0.7,
                  0.3 + love.math.random() * 0.7,
                  0.3 + love.math.random() * 0.7 }
    table.insert(objects, obj)
end

function love.update(dt)
    world:update(dt)

    -- Remove objects that fell off screen
    for i = #objects, 1, -1 do
        if objects[i].body:getY() > 700 then
            objects[i].body:destroy()
            table.remove(objects, i)
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if spawn_mode == "box" then
            spawn_box(x, y)
        elseif spawn_mode == "circle" then
            spawn_circle(x, y)
        elseif spawn_mode == "triangle" then
            spawn_triangle(x, y)
        end
    end
end

function love.keypressed(key)
    if key == "1" then spawn_mode = "box" end
    if key == "2" then spawn_mode = "circle" end
    if key == "3" then spawn_mode = "triangle" end
    if key == "r" then
        -- Clear all dynamic objects
        for _, obj in ipairs(objects) do
            obj.body:destroy()
        end
        objects = {}
    end
    if key == "escape" then love.event.quit() end
end

function love.draw()
    love.graphics.clear(0.08, 0.08, 0.12)

    -- Draw static geometry
    love.graphics.setColor(0.35, 0.35, 0.4)
    love.graphics.polygon("fill", ground.body:getWorldPoints(
        ground.shape:getPoints()))
    love.graphics.polygon("fill", wall_left.body:getWorldPoints(
        wall_left.shape:getPoints()))
    love.graphics.polygon("fill", wall_right.body:getWorldPoints(
        wall_right.shape:getPoints()))

    -- Draw dynamic objects
    for _, obj in ipairs(objects) do
        love.graphics.setColor(obj.color)
        if obj.kind == "circle" then
            local x, y = obj.body:getPosition()
            love.graphics.circle("fill", x, y, obj.radius)
            -- Draw a line to show rotation
            local angle = obj.body:getAngle()
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.line(x, y,
                x + math.cos(angle) * obj.radius,
                y + math.sin(angle) * obj.radius)
        else
            love.graphics.polygon("fill", obj.body:getWorldPoints(
                obj.shape:getPoints()))
        end
    end

    -- HUD
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Mode: " .. spawn_mode .. "  [1] Box  [2] Circle  [3] Triangle", 20, 20)
    love.graphics.print("Click to spawn  |  [R] Clear  |  Objects: " .. #objects, 20, 40)
end
```

Click anywhere to spawn shapes. Press 1/2/3 to switch types. Press R to clear. Watch them fall, bounce, stack, and interact. The restitution and friction values create variety -- some objects bounce high, others stick. Triangles topple over realistically. This is what Box2D gives you for free.

---

## API Reference

### bump.lua

| Function | Description |
|---|---|
| `bump.newWorld(cellSize)` | Create a new collision world. Default cell size is 64. |
| `world:add(item, x, y, w, h)` | Register an item with a bounding rectangle. `item` must be a unique table reference. |
| `world:remove(item)` | Remove an item from the world. Always do this before discarding an object. |
| `world:move(item, goalX, goalY, filter)` | Move an item toward goal, resolving collisions. Returns `actualX, actualY, cols, len`. |
| `world:check(item, goalX, goalY, filter)` | Like `move` but does not update the item's position. Returns `actualX, actualY, cols, len`. Use for "what if" queries. |
| `world:update(item, x, y, w, h)` | Teleport an item to a new position/size without triggering collision. Use for resizing or warping. |
| `world:queryRect(x, y, w, h, filter)` | Returns all items overlapping the given rectangle. Useful for area-of-effect, screen culling. |
| `world:queryPoint(x, y, filter)` | Returns all items containing the point. Useful for mouse picking. |
| `world:querySegment(x1, y1, x2, y2, filter)` | Returns all items intersecting a line segment. Useful for raycasting, line-of-sight. |
| `world:getRect(item)` | Returns `x, y, w, h` for an item. |
| `world:getItems()` | Returns `items, len` -- all registered items. |
| `world:hasItem(item)` | Returns `true` if the item exists in the world. |
| `world:countItems()` | Returns the total number of items in the world. |

### love.physics

| Function | Description |
|---|---|
| `love.physics.setMeter(n)` | Set the pixels-per-meter scale. Call before `newWorld`. |
| `love.physics.newWorld(gx, gy, sleep)` | Create a physics world with gravity vector and optional sleeping. |
| `world:update(dt)` | Step the simulation forward by `dt` seconds. |
| `world:setCallbacks(begin, end, pre, post)` | Set contact callback functions. |
| `love.physics.newBody(world, x, y, type)` | Create a body. Type: `"static"`, `"dynamic"`, `"kinematic"`. |
| `love.physics.newRectangleShape(w, h)` | Create a rectangle shape centered on the body. |
| `love.physics.newCircleShape(radius)` | Create a circle shape centered on the body. |
| `love.physics.newPolygonShape(x1,y1, ...)` | Create a convex polygon shape from vertex pairs. |
| `love.physics.newEdgeShape(x1,y1, x2,y2)` | Create a line segment shape. Good for boundaries. |
| `love.physics.newFixture(body, shape, density)` | Attach a shape to a body. Density affects mass. |
| `body:getPosition()` | Returns `x, y`. |
| `body:setPosition(x, y)` | Teleport the body. |
| `body:getAngle()` | Returns rotation in radians. |
| `body:getLinearVelocity()` | Returns `vx, vy`. |
| `body:setLinearVelocity(vx, vy)` | Set velocity directly. |
| `body:applyForce(fx, fy)` | Apply a continuous force (acceleration). |
| `body:applyLinearImpulse(ix, iy)` | Apply an instant impulse (velocity change). |
| `body:getWorldPoints(...)` | Transform local-space points to world-space. |
| `body:destroy()` | Remove the body and all attached fixtures. |
| `fixture:setRestitution(n)` | Set bounciness (0 = no bounce, 1 = perfect bounce). |
| `fixture:setFriction(n)` | Set friction (0 = ice, 1 = rubber). |
| `fixture:setUserData(data)` | Attach arbitrary data (table, string) for identification in callbacks. |
| `fixture:getUserData()` | Retrieve the attached data. |
| `fixture:setCategory(n)` | Set collision category (bit flag). |
| `fixture:setMask(n, ...)` | Set which categories this fixture ignores. |
| `fixture:setSensor(bool)` | Make the fixture a sensor (detects overlap but does not generate collision response). |

---

## Libraries & Tools

### bump.lua

**When:** You want predictable, grid-based collision for platformers, top-down games, or any game where you control movement directly.

**Why:** It is tiny (one file), fast, well-documented, and solves the exact problem that 80% of 2D games face: "I have rectangles and I want them to not overlap." The filter system is flexible enough to handle collectibles, triggers, one-way platforms, and projectiles.

**The spatial hash concept:** bump.lua divides the world into a grid of cells. Each rectangle is registered in every cell it overlaps. When you move a rectangle, bump only checks it against other rectangles in the same cells. This means collision checking is roughly O(n) where n is the number of nearby objects, not the total number of objects in the world. A game with 1000 walls but only 5 near the player does 5 checks, not 1000.

**Installation:** Download `bump.lua` from https://github.com/kikito/bump.lua and place it in your project folder or `lib/` directory.

**Honest tradeoff:** bump.lua only does axis-aligned rectangles. No circles, no polygons, no rotation. If you need those, look elsewhere.

---

### HC (HardenedClay)

**When:** You need collision detection for polygons, circles, and rotated shapes, but do not want full physics simulation.

**Why:** HC supports arbitrary convex polygons, circles, and points. It uses the Separating Axis Theorem (SAT) and GJK algorithm for detection and provides collision resolution vectors (how far to push objects apart). It sits between bump.lua (rectangles only) and love.physics (full simulation).

**Honest tradeoff:** Less battle-tested than bump.lua, less commonly used in the LOVE community, and more complex to set up. The API is also less intuitive for beginners. If your shapes are rectangles, bump.lua is simpler. If you need full physics, love.physics is more capable.

**Source:** https://github.com/vrld/HC

---

### windfield

**When:** You want love.physics (Box2D) but the body-shape-fixture ceremony is driving you crazy.

**Why:** windfield wraps love.physics with a friendlier API. Instead of creating a body, then a shape, then a fixture, you call `world:newRectangleCollider(x, y, w, h)` and get a working physics object in one line. It also adds collision classes (like bump.lua's filter system) so you can say "players collide with walls but not with other players" declaratively.

```lua
-- Without windfield (love.physics raw)
local body = love.physics.newBody(world, 200, 100, "dynamic")
local shape = love.physics.newRectangleShape(40, 40)
local fixture = love.physics.newFixture(body, shape, 1)
fixture:setRestitution(0.5)

-- With windfield
local box = world:newRectangleCollider(180, 80, 40, 40)
box:setRestitution(0.5)
```

**Honest tradeoff:** It is an abstraction over love.physics, so you are still using Box2D under the hood with all its quirks (meter scale, body types, etc.). If you need fine control over fixtures and joints, you may find windfield's abstractions getting in the way. For most use cases, though, it is a strict improvement in developer experience.

**Source:** https://github.com/a327ex/windfield

---

## Common Pitfalls

### 1. Checking collision every frame but only moving once (or vice versa)

A subtle timing bug. If you check for collision in `love.update` but move the object in a separate function that runs at a different time, the collision check and the movement are out of sync. With bump.lua, this is handled for you because `world:move()` does both simultaneously. But if you are writing manual AABB checks, always check collision *after* moving, against the *new* position, in the *same* function call. Never move in one place and check in another.

### 2. Forgetting bump.lua uses top-left coordinates, not center

bump.lua treats `x, y` as the **top-left corner** of the rectangle. If your player sprite is drawn from its center (which is common with origin-based drawing), your collision box will be offset from the visual. Either draw from the top-left to match bump.lua, or offset your draw calls:

```lua
-- Drawing with center origin but bump.lua uses top-left
love.graphics.draw(sprite, player.x + player.w / 2, player.y + player.h / 2,
    0, 1, 1, sprite_w / 2, sprite_h / 2)
```

This is the most common source of "my collision is off by half the sprite size" bugs.

### 3. Box2D meter scale confusion

If your objects look like they are moving through molasses, or they fly off the screen on the slightest touch, you probably have a scale mismatch. Box2D expects objects between 0.1 and 10 meters. If you are creating a 400-pixel-wide platform and `setMeter` is at the default 30, Box2D thinks that platform is 13 meters wide -- about the length of a city bus. Set `love.physics.setMeter(64)` (or whatever matches your art scale) **before** creating the world.

### 4. Not removing destroyed objects from the bump world

When an enemy dies or a coin is collected, you need to call `world:remove(item)` before discarding the reference. If you forget, bump.lua still has the item in its spatial hash. Moving other objects near that location will still check against the ghost item, and `world:move` may report collisions with an object that no longer exists in your game logic. In love.physics, call `body:destroy()` -- failing to do so leaks memory and causes crashes.

### 5. Tunneling (fast objects passing through thin walls)

If a bullet moves 500 pixels per frame and a wall is 16 pixels thick, the bullet can skip right through the wall in a single step. This is called **tunneling**. Solutions:

- **Cap velocity.** Set a maximum speed lower than your thinnest wall divided by `dt`.
- **Make walls thicker.** A 64-pixel wall is much harder to tunnel through than a 16-pixel one.
- **Subdivide movement.** Move in smaller steps within a single frame.
- **Use raycasting.** bump.lua's `world:querySegment()` can check a line from the old position to the new position for any intersections.

With love.physics, enable **continuous collision detection** on fast-moving bodies: `body:setBullet(true)`. This tells Box2D to use swept collision for that body, preventing tunneling at a small performance cost.

### 6. Mixing bump.lua and love.physics in the same project incorrectly

If the player is managed by bump.lua and an explosion is managed by love.physics, they cannot interact directly. The two systems do not know about each other. You can make it work by using one system as the authoritative source of truth and manually syncing the other, but this is error-prone. The common approach is to pick one system for your core gameplay and use the other only for visual effects (love.physics particles that do not affect gameplay, for example).

---

## Exercises

### Exercise 1: AABB Collision by Hand

**Time:** 45-60 minutes

Build a simple collision demo from scratch with no libraries:

1. Create two rectangles on screen. One follows the mouse, the other is stationary.
2. Implement `check_aabb()` and change both rectangles' colors when they overlap.
3. Add collision *response* -- when the mouse rectangle overlaps the stationary one, push it so they no longer overlap. The push direction should be the axis of least overlap (if the mouse box is mostly overlapping from the left, push it left).
4. Add a third and fourth rectangle. Display a list of all currently colliding pairs.
5. **Stretch goal:** Calculate and display the **overlap rectangle** (the intersection of two overlapping AABBs). Draw it in a semi-transparent color.

**Success criteria:** You understand the overlap formula, you can separate overlapping rectangles, and you feel the pain of doing this manually for more than two objects -- which motivates learning bump.lua.

---

### Exercise 2: Platformer with bump.lua

**Time:** 2-3 hours

Build a platformer level using the Code Walkthrough as a starting point, then extend it:

1. Create at least 10 platforms at different heights forming a navigable level.
2. Add a player that runs and jumps with gravity, coyote time, and variable jump height.
3. Add 8 coins scattered around the level using the "cross" filter. Display a coin counter.
4. Add a "spike" hazard (at least 2) that resets the player to the starting position on contact (using "cross" filter, check for `col.other.type == "spike"` in the collision loop).
5. Add a "goal" zone at the end of the level that displays "YOU WIN" when the player reaches it.
6. **Stretch goal:** Add a one-way platform that the player can jump through from below but stand on from above.

**Success criteria:** The player can navigate the level, collect all coins, avoid spikes, and reach the goal. The collision feels tight and responsive -- no sticking to walls, no missing jumps that should have worked.

---

### Exercise 3: Physics Puzzle

**Time:** 2-3 hours

Use love.physics to create an Angry Birds-style or Rube Goldberg machine level:

1. Build a structure from dynamic box-shaped "blocks" stacked on a static ground.
2. Give the player a way to launch a "projectile" at the structure (click to set launch position, drag to set velocity, release to fire).
3. Use `beginContact` callbacks to detect when the projectile hits a block. Track how many blocks have been knocked off the structure (below a Y threshold = "fallen").
4. Display a score based on blocks knocked down.
5. Give the player 3 projectiles. Display remaining shots.
6. **Stretch goal:** Add different block materials. "Wood" blocks have low density and break easily (destroy them if impact force in `postSolve` exceeds a threshold). "Stone" blocks have high density and are harder to move. Color them differently.

**Success criteria:** You understand the body-shape-fixture hierarchy, can apply impulses to launch projectiles, and can use contact callbacks to detect and respond to collisions.

---

## Recommended Reading & Resources

### Essential

| Resource | URL | Why |
|---|---|---|
| bump.lua README | https://github.com/kikito/bump.lua | The best-documented Lua library. Read the whole thing -- it is a tutorial in itself. |
| LOVE Physics Tutorial | https://love2d.org/wiki/Tutorial:Physics | Official Box2D walkthrough with LOVE. Covers world setup through joints. |
| LOVE Physics Module Docs | https://love2d.org/wiki/love.physics | Full API reference for every physics function. |
| Sheepolution Ch. 21-22 | https://sheepolution.com/learn/book/contents | Collision and physics chapters from the best text-based LOVE tutorial. |

### Go Deeper

| Resource | URL | Why |
|---|---|---|
| Box2D Manual | https://box2d.org/documentation/ | The original Box2D documentation. LOVE's love.physics is a direct wrapper, so everything here applies. |
| windfield Library | https://github.com/a327ex/windfield | Simplified love.physics wrapper. Read the README for a friendlier Box2D API. |
| HC Library | https://github.com/vrld/HC | Polygon collision detection if you outgrow bump.lua but do not need full physics. |
| 2D Collision Detection (MDN) | https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection | Mozilla's guide to AABB, circle, and SAT collision. Language-agnostic theory. |
| Celeste Movement & Physics (GDC) | https://www.youtube.com/watch?v=yorTG9at90g | Matt Thorson and Noel Berry on how Celeste handles collision, coyote time, and input buffering. Worth watching even if you do not normally watch videos. |

---

## Key Takeaways

- **AABB is the foundation of 2D collision.** Four comparisons tell you if two axis-aligned rectangles overlap. Understand this formula cold -- everything else builds on it.

- **bump.lua is the right choice for most 2D games.** Platformers, top-down, puzzle -- if you control character movement directly, bump.lua gives you fast collision detection and sliding response with minimal setup. Start here unless you specifically need physics simulation.

- **love.physics (Box2D) is for physics-driven gameplay.** If stacking, tumbling, swinging, or launching objects IS the game, use Box2D. If physics is just set dressing, bump.lua is simpler and more predictable.

- **The filter function is bump.lua's secret weapon.** By returning "slide", "cross", "touch", "bounce", or nil from a filter, you control exactly how each collision pair behaves. Coins pass through, walls slide, springs touch, bumpers bounce -- one function handles everything.

- **Set the meter scale before creating a Box2D world.** `love.physics.setMeter(64)` prevents the most common Box2D confusion. Without it, your objects are the wrong size in physics space and everything looks wrong.

- **Coyote time and jump buffering are not optional for platformers.** These two techniques (a few lines of code each) are the difference between a platformer that feels broken and one that feels great. Celeste, Hollow Knight, and every modern platformer uses them.

- **Always clean up.** Remove destroyed objects from bump.lua with `world:remove()` and from love.physics with `body:destroy()`. Ghost objects cause phantom collisions and memory leaks.

---

## What's Next?

Your game objects can now collide with each other, stand on platforms, and interact physically. The mechanics work. But they do not *feel* good yet -- there is no sound when you land, no particles when you collect a coin, no screen shake when you hit a wall. That is the domain of **juice**.

[Module 6: Audio & Juice](module-06-audio-juice.md) covers sound effects, particle systems, screen shake, tweening, and the dozens of small polish effects that transform a working prototype into a game people enjoy playing. Your platformer is about to get a lot more satisfying.

Back to the [LOVE2D Learning Roadmap](love2d-learning-roadmap.md).
