# LÖVE Gauntlet: 10-Challenge Series

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Format:** Challenge series (not a tutorial)
**Prerequisites:** [Module 08](module-08-build-first-game.md) completed — at least one shipped game

---

## What This Is

You have built shooters. You understand the core loop: tables of entities, circle collision, data-driven enemy definitions, particles on death. That loop is real knowledge. It is also a rut.

The four LÖVE pillars you have not touched yet — **love.physics (Box2D), GLSL shaders, ECS architecture, and procedural generation** — each unlock a different category of game. Physics opens simulations and puzzle mechanics. Shaders unlock visual fidelity and post-processing. ECS scales to complex games with many interacting entity types. Procedural generation makes games that play differently every time.

This gauntlet covers all four through ten challenges across five new genres. Each challenge is a brief, not a walkthrough. You will get enough context to start, the APIs to look up, and a clear output to aim for. The rest is on you.

The pattern alternates:
- **Quick Fire (1–2 hrs)** — one new API, concept spike, small visible output
- **Weekend Build (4–6 hrs)** — mini-game, 2–3 systems working together

Every Quick Fire challenge introduces a pillar. Every Weekend Build that follows deepens it. By Challenge 10, you will combine three or more pillars in a game you ship.

---

## Prerequisites

Before starting:

- **Built and shipped at least one game** from Module 8. The gauntlet assumes you are comfortable with game loops, state management, entity tables, and basic collision.
- **Played the projects in this repo.** `bullet-hell/`, `vampire-survivors/`, and `tactical-shooter/` represent the patterns the gauntlet builds on. If those feel like home, you are ready.
- **A text editor and LÖVE 11.x installed.** No new tools required to start.

---

## The Challenges

| # | Title | Scope | Genre | New Tech Pillar |
|---|-------|-------|-------|-----------------|
| 01 | Blob Drop | Quick Fire | Physics toy | love.physics basics |
| 02 | Wrecking Yard | Weekend Build | Physics puzzle | Joints + statics |
| 03 | Pixel Weather | Quick Fire | Simulation | love.math.noise + imageData |
| 04 | Dungeon Diver | Weekend Build | Roguelike | BSP gen + A* + FOV |
| 05 | Scanlines | Quick Fire | Effect demo | GLSL shaders + canvas |
| 06 | Neon Crawler | Weekend Build | Lit dungeon | Bloom + normal-map lighting |
| 07 | Boids | Quick Fire | Flocking sim | Roll-your-own ECS |
| 08 | Ant Colony | Weekend Build | Colony sim | Full ECS + pheromone grid |
| 09 | Rhythm Tap | Quick Fire | Rhythm game | love.audio timing |
| 10 | The Whole Package | Weekend Build | Your choice | Synthesis: 3+ pillars |

---

## Challenge 01: Blob Drop 🔥 Quick Fire

**Genre:** Physics toy — new territory

### The Build

Click anywhere on screen to spawn a wobbly circle. It falls, bounces, stacks on the floor and other blobs. Each blob has randomized size and bounciness. The goal is not a game — it is getting comfortable with how Box2D works inside LÖVE before you build anything serious with it.

### New Tech

- `love.physics.newWorld(gx, gy)` — creates a world with gravity
- `world:newBody(x, y, "dynamic")` — a body that moves under forces
- `body:newCircleShape(radius)` — attaches a circle shape to a body
- `love.physics.newFixture(body, shape, density)` — gives the shape physical properties
- `fixture:setRestitution(n)` — bounciness (0 = dead stop, 1 = perfect bounce)
- `fixture:setFriction(n)` — surface friction
- `world:update(dt)` — steps the simulation forward
- `body:getX()`, `body:getY()`, `body:getAngle()` — read position for drawing
- `love.physics.newBody(world, x, y, "static")` — immovable floor and walls
- Contact callbacks: `world:setCallbacks(beginContact, endContact, preSolve, postSolve)`

### Connects To

This is the entry point to `love.physics`. No prior challenge required. The entity table pattern you know from your shooters applies directly — store each blob as a table containing `{body, shape, fixture}`.

### Key APIs

`love.physics.newWorld`, `newBody`, `newCircleShape`, `newRectangleShape`, `newFixture`, `fixture:setRestitution`, `world:update`, `body:getX`, `body:getY`, `body:getAngle`

### Starter Pattern

```lua
-- main.lua — Blob Drop skeleton
local world
local blobs = {}
local floor

function love.load()
    world = love.physics.newWorld(0, 600)  -- gravity pulls down at 600px/s²

    -- Static floor
    local floorBody = love.physics.newBody(world, 400, 580, "static")
    local floorShape = love.physics.newRectangleShape(800, 20)
    floor = love.physics.newFixture(floorBody, floorShape)
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    love.graphics.setColor(0.3, 0.3, 0.3)
    -- Draw floor: get body position from fixture's body
    local fb = floor:getBody()
    love.graphics.rectangle("fill", fb:getX() - 400, fb:getY() - 10, 800, 20)

    love.graphics.setColor(0.2, 0.6, 1.0)
    for _, blob in ipairs(blobs) do
        local bx, by = blob.body:getX(), blob.body:getY()
        love.graphics.circle("fill", bx, by, blob.radius)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local radius = math.random(10, 30)
        local body = love.physics.newBody(world, x, y, "dynamic")
        local shape = love.physics.newCircleShape(radius)
        local fix = love.physics.newFixture(body, shape, 1)
        fix:setRestitution(math.random() * 0.8)
        fix:setFriction(0.3)
        table.insert(blobs, { body = body, shape = shape, fix = fix, radius = radius })
    end
end
```

The key insight: **Box2D owns the position.** You do not move bodies by setting `x` and `y` directly — you apply forces or let gravity do it. Your job is to read the body's position each frame and draw at that location.

### Stretch Goals

- Add walls on the left and right edges
- Color blobs by their restitution value (stiff = red, bouncy = blue)
- Spawn different shapes: `newPolygonShape` for triangles, `newRectangleShape` for boxes

### What This Unlocks

Once you understand the body/shape/fixture model and the `world:update` → `body:getX/getY` → draw loop, you can build any physics-based mechanic: ragdolls, destructible environments, rope bridges, pressure plates. Challenge 02 puts it to work immediately.

---

## Challenge 02: Wrecking Yard 🏗️ Weekend Build

**Genre:** Physics puzzle — Angry Birds-style destruction

**Builds on:** Challenge 01

### The Build

A tower of stacked objects sits on a platform. You drag and release to aim a projectile and launch it. Different materials behave differently: glass shatters on light impact, wood absorbs hits, metal is dense and heavy. The goal: knock the tower off the platform entirely. Five pre-built tower layouts, increasing in complexity.

### New Tech

- `world:newBody(x, y, "static")` — immovable terrain and platforms
- `love.physics.newDistanceJoint(bodyA, bodyB, ax, ay, bx, by)` — connects two bodies at a fixed distance (for dangling objects or chains)
- `love.physics.newRevoluteJoint(bodyA, bodyB, ax, ay)` — pin joint (things that swing or rotate around a point)
- Compound shapes: attach multiple shapes to one body using `newFixture` twice
- Material tables: define density, restitution, and friction per material type
- Contact callbacks with `postSolve` to read collision impulse (for "glass breaks on hard hits")
- Drag-and-launch input: record mouse-down position, draw an aim indicator, apply impulse on release

### Connects To

Everything from Challenge 01 (bodies, fixtures, `world:update`). The contact callback pattern you learned there is now used practically: `postSolve` gives you the collision impulse magnitude, which determines whether a hit is "hard enough" to break glass.

### Key APIs

`newDistanceJoint`, `newRevoluteJoint`, `newFixture` (density param), `fixture:setDensity`, `body:applyLinearImpulse`, `body:getLinearVelocity`, `body:setType` (switch static to dynamic on break)

### Starter Pattern

```lua
-- Material definitions — data-driven, not hardcoded
local materials = {
    wood  = { density = 0.8,  restitution = 0.1, friction = 0.6, color = {0.7, 0.5, 0.2} },
    glass = { density = 0.4,  restitution = 0.2, friction = 0.1, color = {0.7, 0.9, 1.0},
              breakThreshold = 80 },  -- shatters when impulse exceeds this
    metal = { density = 3.0,  restitution = 0.05, friction = 0.8, color = {0.6, 0.6, 0.7} },
}

-- In postSolve callback, check impulse for breakable materials:
function postSolve(a, b, contact, normalImpulse1, tangentImpulse1)
    local totalImpulse = math.abs(normalImpulse1)
    -- check both fixtures for breakability
end
```

### Stretch Goals

- Add a "shots remaining" counter — player must clear the tower within N shots
- Destructible terrain: parts of the platform can be destroyed by heavy hits
- A chain of objects hanging from a static anchor using multiple `newDistanceJoint` links

### What This Unlocks

Joints, material systems, and compound shapes are the building blocks of physics puzzles, platformers with movable objects, and any simulation with interconnected parts. This challenge proves that `love.physics` is a full game mechanic, not just a demo toy.

---

## Challenge 03: Pixel Weather 🔥 Quick Fire

**Genre:** Simulation — procedural noise and pixel canvases

### The Build

A 160×120 pixel simulation of rain. Noise generates rolling cloud formations. Rain falls from high-noise areas, pooling at the bottom. Over time, pools evaporate back into clouds. No sprites. Just pixels you set each frame using `imageData:setPixel`. The visual output looks like a living weather system.

### New Tech

- `love.math.noise(x, y)` — returns a smooth value between 0 and 1 at coordinate (x, y). Animate it by passing `(x + time * speed, y)` to scroll the noise field.
- `love.image.newImageData(width, height)` — creates a raw pixel buffer you can write to
- `imageData:setPixel(x, y, r, g, b, a)` — sets one pixel's color
- `imageData:getPixel(x, y)` — reads back a pixel's current color (for the evaporation sim)
- `love.graphics.newImage(imageData)` — creates a drawable image from the raw data
- `image:replacePixels(imageData)` — updates the drawable image with new pixel data (faster than recreating the image every frame)
- `love.graphics.draw(image, 0, 0, 0, scaleX, scaleY)` — draw scaled up to fill the window (160×120 → 800×600 = scale 5)

### Connects To

No prior game project required. This is a standalone concept spike. The `love.math.noise` function is the same Perlin noise used in Challenge 04's dungeon generation — this challenge gives you hands-on intuition for what noise actually produces before using it structurally.

### Key APIs

`love.math.noise`, `love.image.newImageData`, `imageData:setPixel`, `imageData:getPixel`, `love.graphics.newImage`, `image:replacePixels`

### Starter Pattern

```lua
local W, H = 160, 120
local SCALE = 5
local imageData, canvas
local time = 0

function love.load()
    imageData = love.image.newImageData(W, H)
    canvas = love.graphics.newImage(imageData)
end

function love.update(dt)
    time = time + dt
    for y = 0, H - 1 do
        for x = 0, W - 1 do
            -- Sample noise scrolling leftward over time
            local n = love.math.noise(x * 0.05 + time * 0.1, y * 0.05)
            -- Cloud layer: high noise = bright
            local cloud = n > 0.6 and 1 or 0
            imageData:setPixel(x, y, cloud * 0.8, cloud * 0.85, cloud * 0.9, 1)
        end
    end
    canvas:replacePixels(imageData)
end

function love.draw()
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, 0, 0, 0, SCALE, SCALE)
end
```

Start here, then layer in the rain: if a pixel is in a "cloud" region, occasionally spawn a rain particle that falls one pixel per frame. When it hits the bottom, increment a pool level. Pool pixels evaporate slowly, tinting the noise input slightly upward over that column.

### Stretch Goals

- Add a day/night cycle: multiply pixel colors by a brightness value that oscillates with `sin(time * 0.1)`
- Use 3D noise (`love.math.noise(x, y, time)`) for a more natural animated cloud pattern
- Visualize the raw noise field alongside the weather sim for comparison

### What This Unlocks

The `imageData`/pixel canvas pattern is the foundation for any pixel-level simulation: fluid dynamics, cellular automata, terrain height maps, fire effects. It is also how you generate textures procedurally — including the normal maps used in Challenge 06's lighting system.

---

## Challenge 04: Dungeon Diver 🏗️ Weekend Build

**Genre:** Roguelike — top-down procedural dungeon crawler

**Builds on:** Challenge 03 (noise intuition), tactical-shooter grid concepts

### The Build

Every run generates a different dungeon using BSP (Binary Space Partitioning). The player navigates rooms, fights enemies that pathfind via A*, and sees only tiles within their field of view (shadowcasting FOV). Rooms are connected by corridors. A key unlocks the exit. Die and the dungeon regenerates. The emphasis is on three algorithms working together, not content volume — two enemy types and one key item are enough.

### New Tech

**BSP Dungeon Generation:**
- Recursively split a rectangle into two sub-rectangles until rooms are small enough
- Place a room inside each leaf node, slightly inset from the split boundary
- Connect sibling rooms with L-shaped corridors
- Output: a 2D tile grid (`1` = wall, `0` = floor)

**A* Pathfinding:**
- Open/closed sets, `g` (cost from start), `h` (heuristic distance to goal), `f = g + h`
- Manhattan distance heuristic works well on grid maps
- Recalculate enemy paths every 0.5–1 second (not every frame)

**Shadowcasting FOV:**
- The classic recursive shadowcasting algorithm by Björn Björk
- Tiles outside the player's radius are hidden; tiles seen are added to a "revealed" set
- Draw unrevealed tiles darker, draw hidden-but-revealed tiles dim, draw visible tiles full brightness

### Connects To

The grid-based level structure connects directly to the tactical-shooter's tile handling. The enemy "walks toward player" logic you have used before is now replaced with proper A* pathfinding. The noise familiarity from Challenge 03 helps when you want noise-based room decoration (scatter debris, vary wall types).

### Key APIs

`love.math.random`, `love.keyboard.isDown`, standard Lua tables for the grid. No new LÖVE APIs — this challenge is almost entirely algorithms.

### Architecture Sketch

```lua
-- Generator output: a flat tile grid
-- gen/bsp.lua returns { grid = 2D array, rooms = list of {x,y,w,h}, startRoom, exitRoom }

-- Pathfinding: enemies hold a path table, recalculate on a timer
-- enemy.pathTimer counts up; when > 0.8, call astar(grid, enemy.tile, player.tile)

-- FOV: called once per player move (not every frame)
-- fov.compute(grid, player.tx, player.ty, radius) → sets tile.visible = true/false

-- Rendering: three passes
-- 1. Revealed but not visible: draw at 30% brightness
-- 2. Visible: draw at full brightness
-- 3. Never seen: skip entirely (draw darkness)
```

### Stretch Goals

- Add a minimap in the corner showing explored tiles only
- Vary room themes: treasure rooms have gold-colored floor tiles, boss rooms are larger
- Replace BSP with cellular automata for a more organic cave feel (Challenge 03's noise knowledge applies here)

### What This Unlocks

BSP generation, A* pathfinding, and shadowcasting FOV are three of the most reusable algorithms in game development. Every traditional roguelike uses some variant of all three. Once you implement them from scratch, you understand the tradeoffs well enough to use or replace them in any future project. Challenge 06 takes this dungeon and makes it visually stunning.

---

## Challenge 05: Scanlines 🔥 Quick Fire

**Genre:** Effect demo — shader introduction

### The Build

A shader tester: your game (or any canvas) renders to a texture, and a GLSL shader processes every pixel before it reaches the screen. You implement three effects and cycle through them with the spacebar. The three effects: CRT scanlines with a slight screen curve, chromatic aberration (color channel offset on the edges), and a pixelate/dissolve transition. The goal is not the effects themselves — it is learning how to write, load, pass data to, and apply GLSL shaders in LÖVE.

### New Tech

- `love.graphics.newCanvas(w, h)` — an offscreen render target
- `love.graphics.setCanvas(canvas)` / `love.graphics.setCanvas()` — redirect drawing to the canvas, then restore
- `love.graphics.newShader(glsl_string)` — compile a GLSL shader at runtime
- `love.graphics.setShader(shader)` / `love.graphics.setShader()` — apply and remove a shader
- `shader:send(name, value)` — pass a number, vec2, or texture to a shader uniform
- The GLSL `effect()` function signature LÖVE expects:
  ```glsl
  vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
  ```
- `Texel(tex, tc)` — sample the texture at given coordinates (LÖVE's built-in)
- `extern` keyword — declares a Lua-settable uniform in LÖVE's GLSL dialect

### Connects To

No prior challenges required. This is the entry point to all visual effects work. Challenges 06 and 08 both use shaders — you need this foundation first.

### Key APIs

`love.graphics.newCanvas`, `love.graphics.setCanvas`, `love.graphics.newShader`, `love.graphics.setShader`, `shader:send`, `canvas:getWidth`, `canvas:getHeight`

### The Three Shaders

```lua
-- 1. CRT Scanlines
local scanlines = love.graphics.newShader([[
    extern number time;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 pixel = Texel(tex, tc);
        // Darken every other pixel row
        float line = sin(sc.y * 3.14159) * 0.07;
        pixel.rgb -= line;
        // Slight vignette: darken corners
        vec2 uv = tc * 2.0 - 1.0;
        float vign = 1.0 - dot(uv, uv) * 0.3;
        pixel.rgb *= vign;
        return pixel * color;
    }
]])

-- 2. Chromatic Aberration
local chromatic = love.graphics.newShader([[
    extern vec2 resolution;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec2 center = vec2(0.5, 0.5);
        vec2 offset = (tc - center) * 0.006;
        float r = Texel(tex, tc - offset).r;
        float g = Texel(tex, tc).g;
        float b = Texel(tex, tc + offset).b;
        return vec4(r, g, b, Texel(tex, tc).a) * color;
    }
]])

-- 3. Pixelate (quantize UV coordinates)
local pixelate = love.graphics.newShader([[
    extern number blockSize;  -- e.g. 4.0 for 4-pixel blocks
    extern vec2 resolution;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec2 blocks = resolution / blockSize;
        vec2 quantized = floor(tc * blocks) / blocks;
        return Texel(tex, quantized) * color;
    }
]])
```

The render loop pattern:

```lua
function love.draw()
    -- 1. Draw game to offscreen canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear()
    drawGame()
    love.graphics.setCanvas()

    -- 2. Apply active shader and draw canvas to screen
    love.graphics.setShader(activeShader)
    activeShader:send("time", elapsed)
    love.graphics.draw(gameCanvas, 0, 0)
    love.graphics.setShader()
end
```

### Stretch Goals

- Implement a `dissolve` effect: lerp between the quantized and normal texture based on a `progress` uniform (0 → 1), creating a transition effect
- Chain two shaders using a ping-pong technique: draw through shader A into canvas B, then shader B into the screen
- Write a GLSL `vertex` shader that wobbles the geometry like a CRT monitor with magnetic interference

### What This Unlocks

Once you can write a shader, send uniforms, and apply it to a canvas, the entire world of GLSL is open. Post-processing effects, per-sprite outlines, water distortion, heat shimmer, screen-space lighting — these are all variations on the same pipeline. Challenge 06 takes that directly into a full lighting system.

---

## Challenge 06: Neon Crawler 🏗️ Weekend Build

**Genre:** Lit dungeon — top-down dungeon with real-time lighting

**Builds on:** Challenge 04 (dungeon), Challenge 05 (shaders)

### The Build

Take the dungeon from Challenge 04 — or a simplified version — and add a proper lighting system. The dungeon is dark except within torch range. Two or three dynamic light sources (the player's torch plus fixed torches in rooms) illuminate the walls with a physically-motivated glow. Exposed wall edges pick up soft highlights. The effect: a dark, atmospheric dungeon that looks hand-lit rather than uniformly drawn.

### New Tech

**Bloom (canvas ping-pong):**
- Draw the bright/emissive layer (torch flames, lit surfaces) to a separate canvas
- Run a horizontal Gaussian blur shader on it into a second canvas
- Run a vertical Gaussian blur shader on that result into a third canvas
- Additively blend the blurred result over the main scene

**Normal-map lighting:**
- A normal map encodes surface orientation per pixel (R = X axis tilt, G = Y axis tilt)
- The lighting shader samples the normal map, computes the angle between the surface normal and the light direction, and scales brightness using `max(0, dot(normal, lightDir))`
- You can generate a simple normal map procedurally (walls point outward, floors point straight up)

**Multi-pass rendering in LÖVE:**
- `love.graphics.setBlendMode("add")` — additive blending for glow accumulation
- Multiple canvases: `sceneCanvas`, `bloomCanvas`, `blurTempCanvas`
- `love.graphics.setShader()` between each pass

### Connects To

The dungeon grid from Challenge 04 provides the tile data — you generate normal maps from the same tileset. The shader pipeline from Challenge 05 (canvas → shader → canvas → screen) is exactly the bloom technique here. Challenge 05 is a hard prerequisite.

### Key APIs

`love.graphics.newCanvas`, `love.graphics.setBlendMode`, `love.graphics.setShader`, `shader:send` (for light position, color, radius), `love.graphics.setColor`

### Lighting Shader Sketch

```glsl
// point_light.glsl — Phong-style 2D point light
extern vec2 lightPos;     // light position in screen space
extern vec4 lightColor;   // RGBA
extern float lightRadius; // falloff radius in pixels
extern Image normalMap;   // normal map texture

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 pixel = Texel(tex, tc);

    // Distance-based attenuation
    float dist = length(sc - lightPos);
    float attenuation = clamp(1.0 - dist / lightRadius, 0.0, 1.0);
    attenuation = attenuation * attenuation;  // quadratic falloff

    // Normal-map lighting
    vec4 normalSample = Texel(normalMap, tc);
    vec3 normal = normalize(normalSample.rgb * 2.0 - 1.0);
    vec3 lightDir = normalize(vec3(lightPos - sc, 50.0));
    float diffuse = max(0.0, dot(normal, lightDir));

    vec3 lit = pixel.rgb * lightColor.rgb * attenuation * (0.2 + 0.8 * diffuse);
    return vec4(lit, pixel.a) * color;
}
```

Render each light source separately: set the shader, `send` the light's position and color, draw the scene canvas. Additively blend each light pass onto the accumulation canvas. Add ambient light last (very dim, non-additive) to ensure walls are never completely black.

### Stretch Goals

- Animated torch flicker: send `lightRadius + sin(time * 13) * 8` to add random shimmer
- Colored light: player torch is warm amber, trap rooms are cold blue
- Screen-space occlusion: walls between the player and a torch correctly block its light (requires a shadow-casting pass, which is a significant addition)

### What This Unlocks

Real-time 2D lighting via normal maps is the single biggest visual upgrade available to a LÖVE game. Combine it with Challenge 04's dungeon generation and you have a complete roguelike visual template. The multi-canvas rendering pipeline you build here applies to any game requiring layered post-processing: depth of field, motion blur, screen-space reflections.

---

## Challenge 07: Boids 🔥 Quick Fire

**Genre:** Flocking simulation — ECS introduction

### The Build

200 triangle-shaped boids flock across the screen: they separate from nearby neighbors, align their direction with the local average, and cohere toward the local center of mass. The visual output is mesmerizing emergent behavior. But the point of this challenge is not the boids — it is building a minimal 50-line ECS from scratch, with no library, before using a real one in Challenge 08.

### New Tech

The minimal ECS pattern:

```lua
-- No library. Entities are integer IDs.
-- Components are tables keyed by entity ID.
-- Systems are plain functions.

local nextId = 0
local function newEntity()
    nextId = nextId + 1
    return nextId
end

-- Component tables
local components = {
    pos  = {},   -- components.pos[id] = {x, y}
    vel  = {},   -- components.vel[id] = {x, y}
    boid = {},   -- components.boid[id] = {separation, cohesion, alignment}
}

-- System: steer boids according to flocking rules
local function systemSteer(dt)
    for id, boid in pairs(components.boid) do
        local pos = components.pos[id]
        local vel = components.vel[id]
        -- compute neighbors, accumulate forces, clamp speed
        -- ...
    end
end

-- System: integrate velocity into position
local function systemMove(dt)
    for id in pairs(components.pos) do
        if components.vel[id] then
            components.pos[id].x = components.pos[id].x + components.vel[id].x * dt
            components.pos[id].y = components.pos[id].y + components.vel[id].y * dt
        end
    end
end
```

Key concepts to experience firsthand:
- Entities have no behavior — they are just IDs
- Components have no behavior — they are just data
- Systems iterate over entities that have the required components
- Adding a new behavior means adding a new system, not modifying existing code

### Connects To

No prior challenge required. After this, Challenge 08 scales the same pattern into a real simulation with 6+ component types and multiple behavioral states. The contrast between "50-line ECS" and "full ECS" is the lesson.

### Key APIs

No new LÖVE APIs. This challenge is pure Lua and data structure design. `love.graphics.polygon` for drawing the boid triangles, `math.atan2` for orientation.

### Boid Rules (Quick Reference)

```
Separation: steer away from neighbors closer than minDist
Cohesion:   steer toward the average position of neighbors within radius
Alignment:  steer toward the average velocity of neighbors within radius

Weights: separation = 1.5, cohesion = 0.8, alignment = 1.0 (tune these)
Max speed: 120 px/s. Clamp velocity magnitude after accumulating forces.
Neighbor radius: 60px. Use squared distance to avoid sqrt in the inner loop.
```

### Stretch Goals

- Add a "predator" entity: boids within range flee it; the predator chases the flock centroid
- Add an `obstacle` component: boids steer around circular obstacles placed on screen
- Profile your implementation: how many boids can you simulate before dropping below 60fps? Spatial hashing (grid-based neighbor lookup) can push this to 2000+

### What This Unlocks

Writing a minimal ECS by hand gives you intuition for what ECS libraries actually do internally. When you use `tiny-ecs` or a similar library, you will understand what "filter" means, why systems are separate from components, and when ECS is worth the overhead. Challenge 08 uses this understanding to build something that would be very difficult with the entity-list pattern.

---

## Challenge 08: Ant Colony 🏗️ Weekend Build

**Genre:** Colony simulation — emergent behavior through ECS and pheromones

**Builds on:** Challenge 07 (ECS pattern)

### The Build

Ants spawn from a colony nest and wander randomly until they find food. When an ant finds food, it picks it up and returns to the nest, laying a pheromone trail as it goes. Other ants follow strong pheromone trails, creating emergent pathfinding. Pheromones fade over time and diffuse slightly into neighboring cells. Multiple food sources compete for trail strength. The colony develops efficient routes without any global coordination.

### New Tech

**Expanded ECS component types:**

| Component | Data | Used by |
|---|---|---|
| `transform` | `{x, y, angle}` | All physical entities |
| `velocity` | `{x, y, speed}` | Moving entities |
| `antBrain` | `{state, targetX, targetY, trail}` | Ants |
| `pheromoneEmitter` | `{strength, type}` | Ants when carrying food |
| `food` | `{amount, carried}` | Food piles |
| `colony` | `{x, y, stored}` | The nest |

**Behavioral states for `antBrain`:**
1. `searching` — random walk with slight pheromone-biased steering
2. `carrying` — move toward nest, emit trail pheromone each step
3. `returning` — after depositing food, move toward strongest pheromone gradient

**Pheromone grid:**
- A 2D array (one cell per 8 game pixels) storing pheromone intensity per cell
- Each tick: multiply every cell by `0.995` (decay) and add a fraction of neighbor values (diffusion)
- Draw the pheromone grid as a colored overlay (faint cyan): one `love.graphics.rectangle` per cell, alpha proportional to intensity

### Connects To

The ECS pattern from Challenge 07 scales directly. The grid-based pheromone system is the same kind of `imageData` pixel buffer from Challenge 03 — but instead of weather, you are tracking chemical concentrations. If you want to visualize the pheromone grid as a shader overlay (recommended stretch goal), it connects to Challenge 05.

### Key APIs

No new LÖVE APIs beyond what you have used. `love.graphics.newCanvas` for the pheromone overlay if using shader visualization.

### Simulation Parameters (Tuning Starting Points)

```lua
local config = {
    antCount        = 80,
    pheromoneDecay  = 0.995,   -- per tick (lower = faster fade)
    pheromoneDiffuse = 0.02,   -- fraction leaked to neighbors per tick
    emitStrength    = 1.0,     -- pheromone deposited per step
    senseAngle      = 45,      -- degrees either side of heading to sample
    senseRadius     = 20,      -- px ahead to sample pheromone
    randomTurnMax   = 30,      -- degrees of random wandering
}
```

### Stretch Goals

- Visualize the pheromone grid as a shader overlay — sample the pheromone grid texture in GLSL, output cyan tint proportional to concentration (connects to Challenge 05)
- Multiple pheromone types: "food found" trail and "explored" trail behave differently
- Obstacles: ants navigate around walls using the same pheromone-bias logic

### What This Unlocks

The colony sim demonstrates that ECS is not about performance — it is about managing complexity when entities have overlapping, evolving behaviors. An ant that is `searching` behaves differently from an ant that is `carrying`, but both share `transform` and `velocity` components. Behavioral states combined with ECS is the pattern behind most character AI in larger games.

---

## Challenge 09: Rhythm Tap 🔥 Quick Fire

**Genre:** Rhythm game — audio timing precision

### The Build

A 4-lane rhythm game: notes fall from the top of screen, and the player taps the corresponding key when each note crosses the hit line at the bottom. Combo and accuracy scoring (Perfect / Good / Miss). One 30-second song built from generated tones — no audio file dependency. The core challenge is scheduling when notes should appear based on the audio source's playback position, not wall-clock time.

### New Tech

- `love.audio.newSource(data, "static")` — load audio
- `source:play()` — start playback
- `source:tell(0)` — rewind to the beginning
- `source:getTime()` — current playback position in seconds (this is your clock)
- `love.sound.newSoundData(samples, sampleRate, bitDepth, channels)` — generate audio programmatically, no file needed
- `soundData:setSample(i, value)` — write raw sample values (sine waves for generated tones)

**Why `getTime()` and not `love.timer.getTime()`:**
OS-level timing and audio timing drift apart over a 30-second song. Within a few seconds, visual events synchronized to wall clock will visibly lag or lead the audio. `source:getTime()` gives you the audio clock, which is what the player hears. Schedule everything off of this.

**Visual latency compensation:**
Display lag means what you see is slightly behind what you hear. Offset note appearance time by a small `VISUAL_OFFSET` constant (typically 0–80ms depending on the system). Let the player calibrate this.

### Connects To

No prior challenge required. The generated-tone approach means no audio files — you can build and run this anywhere.

### Key APIs

`love.audio.newSource`, `source:play`, `source:getTime`, `love.sound.newSoundData`, `soundData:setSample`

### Song Generation Pattern

```lua
-- Generate a 30-second drum-machine-style track as raw samples
local SAMPLE_RATE = 44100
local DURATION    = 30
local data = love.sound.newSoundData(SAMPLE_RATE * DURATION, SAMPLE_RATE, 16, 1)

-- Sine wave tone burst: frequency, start_second, duration_seconds, amplitude
local function writeTone(freq, startSec, durSec, amp)
    local startSample = math.floor(startSec * SAMPLE_RATE)
    local numSamples  = math.floor(durSec * SAMPLE_RATE)
    for i = 0, numSamples - 1 do
        local t = i / SAMPLE_RATE
        local env = math.max(0, 1 - t / durSec)  -- simple decay envelope
        local sample = data:getSample(startSample + i)
        data:setSample(startSample + i, sample + math.sin(2 * math.pi * freq * t) * amp * env)
    end
end

-- Quarter-note kicks at BPM = 120 (beat every 0.5 seconds)
local BPM = 120
local beat = 60 / BPM
for b = 0, DURATION / beat - 1 do
    writeTone(80,  b * beat, 0.15, 0.8)  -- kick drum (low sine)
    if b % 2 == 1 then
        writeTone(400, b * beat, 0.05, 0.4)  -- snare (higher, shorter)
    end
end
```

### Note Chart Format

```lua
-- A note chart: {time, lane} pairs sorted by time
-- time is in seconds, matched against source:getTime()
-- lane is 1-4
local chart = {
    { time = 0.5,  lane = 1 },
    { time = 1.0,  lane = 3 },
    { time = 1.25, lane = 2 },
    -- ...
}
```

### Stretch Goals

- Add a BPM-based chart generator: given a BPM and difficulty, procedurally fill the chart with note patterns
- Visual latency calibration screen: play a metronome click, player taps on beat, measure offset, store it
- Graded accuracy windows: Perfect (±30ms), Good (±80ms), Miss (anything beyond)

### What This Unlocks

Audio-synchronized gameplay is in every rhythm game, DDR-style game, bullet-hell with music patterns, and any game where mechanics pulse to a beat. The generated-tone technique means you can ship the rhythm system without worrying about audio licensing or file formats. `source:getTime()` as the master clock is the insight that makes everything else work.

---

## Challenge 10: The Whole Package 🏗️ Weekend Build

**Genre:** Your choice — one complete shippable game

**Builds on:** Every prior challenge

### The Build

Make one complete, shippable game. Not a prototype. Not a tech demo. A game with a title screen, a game over condition, working controls, and something a stranger could download and play for ten minutes without you explaining anything.

The constraint: **your game must incorporate at least three of the four pillars introduced in this gauntlet.**

Suggested combinations by genre:

| Genre | Pillars to combine |
|---|---|
| Roguelike | Procgen (Challenge 04) + Shaders (Challenge 06) + ECS (Challenge 08) |
| Physics Platformer | Physics (Challenge 02) + Shaders (Challenge 05) + Procgen (level variation) |
| Colony Strategy | ECS (Challenge 08) + Procgen (map gen) + Shaders (pheromone visualization) |
| Rhythm Rogue | Rhythm (Challenge 09) + Procgen (chart gen) + ECS (entity management) |

### The Shippable Checklist

This is the same discipline as Module 08, but now with four new technical pillars in play. Scope accordingly.

**Required to call it shipped:**
- [ ] Title screen with Play button
- [ ] Game over / win condition the player can reach
- [ ] Restart without relaunching the executable
- [ ] Sound effects on at least three actions
- [ ] Stable 60fps on typical hardware (profile your ECS and physics costs)
- [ ] Builds on macOS and Windows (use `makelove`)
- [ ] Uploaded to itch.io with a cover image and description

**Common scope traps:**
- Physics + procedural level gen = physics interactions depend on level shape. Lock the level shape first, tune physics, then make the level procedural.
- Shader + ECS = the ECS draws entities; the shader applies to the canvas. Keep them separate layers.
- "Just one more system" is how this weekend becomes a three-month project.

### Architecture Advice

One thing the prior nine challenges may not have made explicit: as systems multiply, a **central game context table** prevents callback spaghetti.

```lua
-- game.lua — the context passed everywhere
local game = {
    world    = nil,   -- love.physics world (if using physics)
    ecs      = nil,   -- ECS world
    dungeon  = nil,   -- dungeon grid and rooms
    shader   = nil,   -- active post-process shader
    canvas   = nil,   -- main render canvas
    state    = "title",
    time     = 0,
}

-- Each system receives `game` as its first argument:
-- physics.update(game, dt)
-- ecs.update(game, dt)
-- dungeon.render(game)
```

Passing a single `game` table means systems can read each other's state without global variables or event buses. It is not ECS — it is just a clean way to share context.

### What This Unlocks

You have now built something with real technical depth: physics, shaders, ECS, and procedural generation working together in a single game. That puts you in a small category. Most indie devs know one or two of these pillars. You know all four.

More importantly, you know how they interact. Physics and shaders need careful canvas management. ECS and procedural generation pair naturally. Shaders and ECS have no coupling at all. These interaction patterns are what you cannot get from reading documentation — only from building.

---

## After the Gauntlet

### Your Next Game Jam

**Ludum Dare** and **GMTK Game Jam** are the highest-signal jams for LÖVE developers. You now have four technical pillars to deploy in 48 hours. The gauntlet was training. A jam is the first real fight.

Ludum Dare runs twice a year (April and October). GMTK runs once (typically August). Find upcoming jams at [itch.io/jams](https://itch.io/jams).

### Advanced LÖVE Topics Not in the Gauntlet

**Networking.** The `enet` library provides UDP networking for real-time multiplayer. `lua-websockets` works for turn-based games. Networking is hard and was intentionally left out — it deserves its own series.

**3D in LÖVE.** LÖVE is a 2D framework, but with shaders and some creativity you can fake 3D: perspective projection, depth sorting, and Mode7-style floor rendering are all possible. True 3D requires switching to a different framework.

**Performance.** `love.graphics.newSpriteBatch` for drawing thousands of identical sprites. Spatial hashing for physics or neighbor queries. `love.timer.sleep` to cap frame rate and reduce CPU usage when idle. LÖVE is fast for 2D but you will find the ceilings if you push hard.

**The Moonshine library.** Pre-built shader chain for common effects (bloom, CRT, vignette, desaturate). If you do not want to write GLSL yourself, Moonshine wraps it. But writing it yourself (Challenges 05 and 06) means you understand what Moonshine is doing and can extend it.

### The Godot Path

If you want to keep the procedural generation and ECS patterns but get a visual editor, Godot 4 is the natural next step. Your LÖVE experience means you will breeze through the basics. The new territory is the scene tree and the editor. See [wiki/godot](../godot/godot4-gamedev-learning-roadmap) for the parallel wiki series.

### Resources

| Resource | URL | What You Get |
|---|---|---|
| LÖVE Physics Tutorial | [love2d.org/wiki/Tutorial:Physics](https://love2d.org/wiki/Tutorial:Physics) | Official Box2D walkthrough |
| The Book of Shaders | [thebookofshaders.com](https://thebookofshaders.com) | Visual, interactive GLSL fundamentals |
| Awesome LÖVE2D | [github.com/love2d-community/awesome-love2d](https://github.com/love2d-community/awesome-love2d) | Curated libraries and resources |
| tiny-ecs | [github.com/bakpakin/tiny-ecs](https://github.com/bakpakin/tiny-ecs) | ECS library when you outgrow the DIY version |
| Roguelike Tutorial (Python, but the algorithms are universal) | [rogueliketutorials.com](https://rogueliketutorials.com) | Step-by-step BSP, A*, FOV |
| GLSL Sandbox | [glslsandbox.com](http://glslsandbox.com) | Live browser GLSL editor for experimentation |
| Amit's A* Pages | [redblobgames.com/pathfinding/a-star/introduction.html](https://www.redblobgames.com/pathfinding/a-star/introduction.html) | The clearest A* explanation in existence |
| Moonshine | [github.com/vrld/moonshine](https://github.com/vrld/moonshine) | Pre-built LÖVE shader chain library |

---

## Key Takeaways

- **Each Quick Fire challenge is a concept spike, not a game.** Getting comfortable with an API is different from shipping a feature. The Quick Fires get you comfortable. The Weekend Builds make you capable.

- **Implement algorithms from scratch once.** BSP generation, A*, shadowcasting, pheromone diffusion — you should write each one yourself at least once before reaching for a library. Libraries abstract away the decisions. Implementing reveals why those decisions were made.

- **Shaders are a different programming model.** GLSL runs per-pixel on the GPU in parallel. You cannot loop or branch the way you do in Lua. Once you accept this constraint, shaders become intuitive.

- **ECS is not a performance optimization.** It is an organizational pattern for games where entities have many overlapping, evolving behaviors. For small games with a fixed set of entity types, your existing entity table pattern is better. For games where a single entity might be a soldier, a physics body, a pheromone emitter, and a sound source simultaneously — ECS wins.

- **Procedural generation is a force multiplier.** One dungeon generator produces infinite content. One noise field produces infinite terrain. The investment in the algorithm pays every time the game runs.

- **You now have a complete technical palette.** Physics, shaders, ECS, procedural generation, audio timing — combined with everything from the roadmap (collision, tilemaps, state management, particles, UI, save data, distribution). The constraints on what you can build are creative, not technical.

Back to the [LOVE2D Learning Roadmap](love2d-learning-roadmap.md).
