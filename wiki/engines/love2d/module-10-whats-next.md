# Module 10: What's Next

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 2-3 hours (reading and reflection)
**Prerequisites:** [Module 9: Shipping to Steam](module-09-shipping-to-steam.md)

---

## Overview

You shipped a game. That is not a small thing. Most people who decide they want to make games never finish one. You did. You learned Lua, learned LOVE, built game loops, managed state, drew sprites, built tilemaps, handled collision, added juice, designed UI, saved data, built executables, and got your game into the hands of players.

Every skill you built is transferable. Game loops work the same in every engine. State management is state management. Collision detection is math, not a library. The discipline of scoping, finishing, and shipping applies whether you are using LOVE, Godot, Unity, or Unreal.

This module is not a tutorial. It is a map. It shows you where the roads lead from here and helps you decide which one to take.

---

## Core Concepts

### What You Have Learned

Take a moment to inventory your skills. You are no longer a beginner:

- **Game loops and frame-independent movement.** You understand `load`, `update(dt)`, `draw` and why delta time matters. This is universal across every game engine and framework.
- **State management.** You can organize a game into screens, transitions, and overlapping states. React devs call this "state machines." You already know them.
- **2D rendering.** Sprites, sprite sheets, quads, animation, drawing order, camera systems. The API names change between engines; the concepts do not.
- **Tilemaps and level design.** Grid-based worlds, layers, Tiled editor, collision from tile data. This is the foundation of most 2D games.
- **Collision detection.** AABB, spatial hashing, bump.lua, and optionally Box2D physics. You understand when to use simple collision versus full physics simulation.
- **Game feel and juice.** Screen shake, particles, tweening, audio feedback. You know why Vlambeer's games feel good and how to replicate that feeling.
- **UI and persistence.** Menus, buttons, settings, save/load, serialization. The unglamorous but essential infrastructure.
- **Scoping and shipping.** The hardest skill. You know how to cut, how to finish, and how to get a game from your machine to a player's machine.

These are not LOVE skills. These are **game development skills.** They follow you to any engine.

### Path 1: Stay in LOVE

LOVE scales further than most people expect. **Balatro** -- one of the most successful indie games of 2024 -- was built in LOVE. It sold millions of copies. The framework is not a toy.

**Why stay:**
- You already know the ecosystem. No learning curve.
- LOVE is lightweight, fast, and gets out of your way.
- The community is small but knowledgeable and helpful.
- For 2D games, LOVE provides everything you need.
- Full control. No editor, no scene tree, no opinions. Just you and Lua.

**Advanced LOVE topics to explore:**
- **Shaders.** LOVE supports GLSL shaders through `love.graphics.newShader`. You can write post-processing effects (CRT, bloom, color grading), per-sprite effects (outlines, dissolves), and lighting systems. Shaders are the single biggest visual upgrade you can make.
- **Networking.** The `enet` library provides UDP networking for multiplayer. `lua-websockets` works for turn-based or slower-paced multiplayer. Networking is hard, but it is one of the most marketable skills in game development.
- **Entity Component Systems.** Libraries like `tiny-ecs` and `Concord` bring ECS architecture to LOVE. ECS is overkill for small games but scales well for larger projects with many entity types and behaviors.
- **Procedural generation.** Random level generation, wave function collapse, cellular automata. These algorithms are language-agnostic and work beautifully in Lua.

**When LOVE is the wrong choice:** 3D games (LOVE is 2D-only), projects that need a visual editor, teams larger than two to three people (no built-in collaboration tools), and games targeting consoles directly (though third-party porting services exist).

### Path 2: Move to Godot

Godot is the most natural next step from LOVE. It is free, open-source, and gaining momentum rapidly. If you want a proper engine with a visual editor, scene system, and built-in tools, Godot is the answer.

**What transfers directly from LOVE to Godot:**
- Game loop thinking (Godot's `_process(delta)` is `love.update(dt)`)
- State management (Godot has scene transitions and state machines)
- 2D rendering concepts (sprites, animation, tilemaps are all built-in)
- Collision detection (Godot has Area2D, KinematicBody2D, RigidBody2D)
- Audio and particles (built-in, more featured than LOVE)
- UI (Godot's Control nodes are more powerful than hand-rolled LOVE UI)

**What is new:**
- **GDScript** instead of Lua. GDScript looks like Python. If you know Python already, you will feel at home. The language difference is minor.
- **The scene tree.** Godot organizes everything into a tree of nodes. This is a fundamentally different architecture from LOVE's "flat entity list" approach. It takes getting used to, but it scales well.
- **The editor.** Godot has a full visual editor for placing objects, designing levels, editing animations, and configuring physics. Coming from LOVE (text editor only), this feels like a superpower.
- **Signals.** Godot's event system. Similar to callbacks but more structured.

**The learning curve with LOVE experience:** Expect one to two weeks to feel comfortable. The concepts are familiar; the implementation details differ. You will spend most of your time learning the editor and scene tree, not game development fundamentals.

### Path 3: Move to Unity or Unreal

These are the industry-standard engines. They make sense in specific situations.

**Unity** (C#) is the workhorse of the indie and mobile industry. It has the largest ecosystem of tutorials, assets, and tools. If you want to work in the game industry, Unity experience is broadly useful. The 2D tooling has improved significantly. The downside: Unity is large, complex, and has a licensing model that generated significant controversy in 2023.

**Unreal Engine** (C++/Blueprints) is primarily a 3D engine. It excels at high-fidelity graphics and is the standard for AAA-adjacent projects. For 2D games, it is overkill. If you want to make 3D games or work in the AAA space, Unreal is the path.

**What transfers:** Everything conceptual. Game loops, state management, collision, UI, audio, scoping, shipping. The engine-specific knowledge (APIs, editors, workflows) is new, but the thinking is the same.

**Honest assessment:** If you are making 2D indie games, you do not need Unity or Unreal. LOVE or Godot will serve you better with less overhead. If you want to go 3D, Godot 4 is the easiest transition. Unity and Unreal are for when you need their specific capabilities or want industry credentials.

### Advanced LOVE Topics

If you choose to stay in LOVE, here are the next areas to explore:

**Shaders (GLSL):**

```lua
-- A simple CRT scanline shader
local shader = love.graphics.newShader([[
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 pixel = Texel(tex, tc);
        // Darken every other line for a scanline effect
        float scanline = sin(sc.y * 3.14159 * 0.5) * 0.1;
        pixel.rgb -= scanline;
        return pixel * color;
    }
]])

function love.draw()
    love.graphics.setShader(shader)
    -- draw your game
    love.graphics.setShader()  -- reset
end
```

Shaders open up an entire world of visual effects: lighting, shadows, water, distortion, color grading, outlines, dissolves. The GLSL syntax is C-like, which is different from Lua, but the concepts are straightforward once you start.

**Entity Component Systems:**

```lua
-- Using tiny-ecs
local tiny = require("tiny-ecs")

local world = tiny.world()

-- Components are just table fields
local player = {
    position = { x = 100, y = 100 },
    velocity = { x = 0, y = 0 },
    sprite = { image = love.graphics.newImage("player.png") },
    health = { current = 100, max = 100 },
}

-- Systems process entities with matching components
local movementSystem = tiny.processingSystem()
movementSystem.filter = tiny.requireAll("position", "velocity")
function movementSystem:process(e, dt)
    e.position.x = e.position.x + e.velocity.x * dt
    e.position.y = e.position.y + e.velocity.y * dt
end

world:addEntity(player)
world:addSystem(movementSystem)

function love.update(dt)
    world:update(dt)
end
```

ECS separates data (components) from behavior (systems). It scales better than inheritance for games with many entity types that share overlapping behaviors. For your first few games, the entity list pattern from earlier modules is fine. ECS becomes valuable when you have dozens of entity types with complex interactions.

**LOVE-to-Godot side-by-side:**

```lua
-- LOVE: Player movement
function love.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("right") then dx = 1 end
    if love.keyboard.isDown("left")  then dx = -1 end
    player.x = player.x + dx * speed * dt
end
```

```gdscript
# Godot GDScript: Player movement
func _process(delta):
    var dx = 0
    if Input.is_action_pressed("ui_right"):
        dx = 1
    if Input.is_action_pressed("ui_left"):
        dx = -1
    position.x += dx * speed * delta
```

The logic is identical. The syntax is slightly different. That is the theme of switching engines: same concepts, different spelling.

### Console Porting

Shipping a LOVE game on consoles (Nintendo Switch, PlayStation, Xbox) is possible but not straightforward.

The path involves third-party porting services. The LOVE community has successfully ported games to Switch through services that recompile the LOVE runtime for console hardware. The game code (Lua) stays mostly the same; the porting work is in the runtime layer.

**Realistic expectations:** Console porting costs money (typically $5,000-$20,000 depending on complexity and platform). It only makes sense if your game has enough traction (sales, wishlist numbers, critical reception) to justify the investment. For a first game, this is a "maybe someday" item, not an immediate goal.

### Monetization Beyond Steam

**Web (love.js).** There is a port of LOVE that compiles to JavaScript using Emscripten, allowing your game to run in a browser. Performance is decent for simple games. This opens up web portals and itch.io's browser play feature.

**Mobile.** LOVE has Android support. iOS support is more limited. Mobile is a different market with different design expectations (touch controls, free-to-play, short sessions). Porting a desktop game to mobile usually requires significant design changes.

**Bundles.** Sites like Humble Bundle and itch.io bundle pages let you participate in curated collections. Low individual revenue but good for visibility.

**Publisher relationships.** As you build a track record, publishers may approach you (or you can approach them). Publishers handle marketing, funding, and sometimes porting in exchange for a revenue share. This is a later-career consideration.

### Building a Portfolio

**Game jams** are the fastest way to build both skills and portfolio pieces. **Ludum Dare** (48/72 hours, runs twice a year) and **GMTK Game Jam** (48 hours, once a year) are the most popular. LOVE is an excellent jam tool -- fast iteration, no editor startup time, and you can prototype rapidly.

**itch.io presence.** Every game you finish goes on your itch.io page. Over time, this becomes a portfolio. Three to five finished games on itch.io demonstrates more skill than one ambitious unfinished project on GitHub.

**Devlogs.** Writing about your development process (on itch.io, a blog, or social media) builds an audience and helps you reflect on what you have learned. It does not need to be polished. "Here is what I built this week and what broke" is compelling content.

### The Indie Dev Community

Game development is more fun and more sustainable with a community.

**LOVE-specific:**
- [LOVE Forums](https://love2d.org/forums) -- the official community. Friendly, responsive, knowledgeable.
- [LOVE Discord](https://discord.gg/rhUets9) -- real-time help and conversation.
- [Awesome LOVE2D](https://github.com/love2d-community/awesome-love2d) -- curated library and resource list.

**General gamedev:**
- [r/gamedev](https://reddit.com/r/gamedev) and [r/IndieDev](https://reddit.com/r/IndieDev) on Reddit
- [Gamedev Twitter/Mastodon](https://mastodon.gamedev.place) -- follow other indie devs, share your work
- Local meetups and game dev groups (search Meetup.com for your city)

**Why community matters:** Accountability (someone asks "how's the game going?"), feedback (playtesters, design advice), motivation (seeing others ship games), and opportunities (collaborations, jam teams, publisher introductions).

### Setting Your Next Goal

**The "second game" problem:** Your second game will be better than your first. That is the point. But there is a trap: you might scope your second game too ambitiously because you feel more confident. Remember: your first game taught you that scoping small works. Apply that lesson again.

**Genre exploration.** You made one type of game. Try a different type. If your first game was an arena survival, try a puzzle game. Different genres teach different skills: puzzle games teach level design, narrative games teach writing and pacing, roguelikes teach systems design.

**Game jams as experimentation.** A 48-hour jam is the lowest-risk way to try a new genre or mechanic. You cannot over-scope in 48 hours (well, you can, but you learn that lesson fast). Jam games are not expected to be polished. They are expected to be interesting.

**The 10-year overnight success.** Every successful indie dev you admire has years of work behind them that you did not see. ConcernedApe (Stardew Valley) worked on that game for four years. Toby Fox (Undertale) had years of ROM hacking and music composition experience. The visible success is the tip of the iceberg. Your first game is the start of that iceberg. Keep building.

---

## Code Walkthrough

### Shader Hello World

A simple color-shifting shader to preview what GLSL in LOVE looks like:

```lua
-- shader_demo/main.lua
local shader = love.graphics.newShader([[
    extern number time;

    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 pixel = Texel(tex, tc);

        // Shift hue over time
        float r = pixel.r * (0.5 + 0.5 * sin(time));
        float g = pixel.g * (0.5 + 0.5 * sin(time + 2.094));
        float b = pixel.b * (0.5 + 0.5 * sin(time + 4.189));

        return vec4(r, g, b, pixel.a) * color;
    }
]])

local image
local elapsed = 0

function love.load()
    image = love.graphics.newImage("sprite.png")
    love.graphics.setDefaultFilter("nearest", "nearest")
end

function love.update(dt)
    elapsed = elapsed + dt
    shader:send("time", elapsed)
end

function love.draw()
    -- Draw with shader
    love.graphics.setShader(shader)
    love.graphics.draw(image, 200, 150, 0, 4, 4)
    love.graphics.setShader()

    -- Draw without shader for comparison
    love.graphics.draw(image, 400, 150, 0, 4, 4)

    love.graphics.print("Left: shader | Right: original", 10, 10)
end
```

The key insight: `effect()` runs for every pixel of every draw call while the shader is active. The `extern` keyword declares variables you can send from Lua. This is how you animate shaders -- send time, player position, or any other value from your game logic.

### ECS Preview with tiny-ecs

```lua
-- ecs_demo/main.lua
local tiny = require("tiny-ecs")

local world = tiny.world()

-- Movement system: processes entities with position + velocity
local moveSystem = tiny.processingSystem()
moveSystem.filter = tiny.requireAll("position", "velocity")
function moveSystem:process(e, dt)
    e.position.x = e.position.x + e.velocity.dx * dt
    e.position.y = e.position.y + e.velocity.dy * dt

    -- Bounce off edges
    if e.position.x < 0 or e.position.x > 780 then
        e.velocity.dx = -e.velocity.dx
    end
    if e.position.y < 0 or e.position.y > 580 then
        e.velocity.dy = -e.velocity.dy
    end
end

-- Draw system: processes entities with position + visual
local drawSystem = tiny.sortedProcessingSystem()
drawSystem.filter = tiny.requireAll("position", "visual")
function drawSystem:process(e, dt)
    love.graphics.setColor(e.visual.color)
    love.graphics.circle("fill", e.position.x, e.position.y, e.visual.radius)
end
function drawSystem:compare(a, b)
    return a.visual.radius < b.visual.radius
end

world:addSystem(moveSystem)
world:addSystem(drawSystem)

function love.load()
    for i = 1, 50 do
        world:addEntity({
            position = { x = math.random(800), y = math.random(600) },
            velocity = { dx = math.random(-100, 100), dy = math.random(-100, 100) },
            visual = {
                radius = math.random(5, 20),
                color = { math.random(), math.random(), math.random(), 0.8 },
            },
        })
    end
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    world:update(dt, tiny.requireAll("position", "visual"))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("50 bouncing entities via tiny-ecs", 10, 10)
end
```

Notice how there is no `Ball` class. Entities are just tables with data. Systems define behavior based on which components an entity has. An entity with `position` and `velocity` but no `visual` would still move -- it just would not be drawn.

---

## Resources by Path

### LOVE Advanced

| Resource | URL | What You Get |
|---|---|---|
| LOVE Shader Tutorial | [love2d.org/wiki/Shader](https://love2d.org/wiki/Shader) | Official shader documentation |
| GLSL Sandbox | [glslsandbox.com](http://glslsandbox.com) | Live shader editor for experimentation |
| tiny-ecs | [github.com/bakpakin/tiny-ecs](https://github.com/bakpakin/tiny-ecs) | ECS library for LOVE |
| moonshine | [github.com/vrld/moonshine](https://github.com/vrld/moonshine) | Post-processing shader library |
| enet for LOVE | [love2d.org/wiki/lua-enet](https://love2d.org/wiki/lua-enet) | UDP networking |

### Godot Transition

| Resource | URL | What You Get |
|---|---|---|
| Godot Getting Started | [docs.godotengine.org](https://docs.godotengine.org/en/stable/getting_started/introduction/index.html) | Official beginner guide |
| GDQuest | [gdquest.com](https://www.gdquest.com) | High-quality Godot tutorials |
| Kids Can Code | [kidscancode.org/godot_recipes](https://kidscancode.org/godot_recipes/) | Practical Godot recipes |

### General Gamedev

| Resource | URL | What You Get |
|---|---|---|
| Blood, Sweat, and Pixels (Jason Schreier) | Book | Stories behind the development of famous games |
| GDC Vault | [gdcvault.com](https://gdcvault.com) | Free talks from the Game Developers Conference |
| Game Programming Patterns (Robert Nystrom) | [gameprogrammingpatterns.com](https://gameprogrammingpatterns.com) | Free online book on patterns used in real games |
| Game Jams | [itch.io/jams](https://itch.io/jams) | Find game jams to participate in |

---

## Libraries & Tools (Advanced LOVE)

| Library | Purpose | URL |
|---|---|---|
| **moonshine** | Post-processing shader chain (bloom, CRT, vignette, etc.) | [github.com/vrld/moonshine](https://github.com/vrld/moonshine) |
| **enet** | UDP networking for multiplayer | [love2d.org/wiki/lua-enet](https://love2d.org/wiki/lua-enet) |
| **tiny-ecs** | Entity Component System | [github.com/bakpakin/tiny-ecs](https://github.com/bakpakin/tiny-ecs) |
| **Concord** | Alternative ECS with more features | [github.com/Tjakka5/Concord](https://github.com/Tjakka5/Concord) |
| **sock** | TCP/UDP networking wrapper | [github.com/camchenry/sock.lua](https://github.com/camchenry/sock.lua) |
| **love.js** | Run LOVE games in the browser | [github.com/Davidobot/love.js](https://github.com/Davidobot/love.js) |

---

## Common Pitfalls

**1. Second system syndrome.** Your first game was small and you shipped it. Now you want to make something "real" -- a ten-hour RPG with procedural generation, crafting, and multiplayer. You are repeating every scoping mistake from Module 8, but with more confidence. Your second game should be slightly bigger than your first, not ten times bigger.

**2. Engine-hopping without finishing anything.** You try Godot for a week, Unity for a week, Unreal for a week. You never finish anything because you are always learning a new engine instead of making a game. Pick one and commit. If LOVE works, keep using LOVE.

**3. Comparing yourself to studios.** Hollow Knight was made by a three-person team with years of experience. Celeste was made by experienced developers with previous shipped titles. Comparing your first game to their polished productions is a recipe for discouragement. Compare yourself to where you were six months ago.

**4. Thinking you need to go 3D to be "real."** The 2D indie market is thriving. Balatro, Vampire Survivors, Slay the Spire, Celeste, Hollow Knight, Stardew Valley, Undertale -- all 2D. Going 3D adds massive complexity for questionable benefit unless your game concept specifically requires it.

**5. Ignoring the business side.** Making a game and selling a game are different skills. Wishlists, store pages, capsule art, marketing, community building -- these matter if you want people to actually play your game. Chris Zukowski's blog (howtomarketagame.com) is the best resource for indie game marketing.

**6. Burnout from treating a hobby like a job.** If game development is a hobby, protect it as one. Do not force yourself to work on your game when you do not feel like it. Take breaks. Play other games. The spark comes back. If game development is a career goal, burnout prevention is even more important -- pace yourself for the marathon, not the sprint.

---

## Exercises

### Exercise 1: Retrospective

**Time:** 1-2 hours

Write a retrospective on your first game. Answer these questions honestly:

1. What went well? What are you proud of?
2. What would you do differently?
3. What was harder than expected?
4. What was easier than expected?
5. What do you want to learn next?
6. If you had to make this game again from scratch, how long would it take?

This exercise is valuable because it converts experience into knowledge. You will reference this document before starting your next project.

### Exercise 2: Game Jam

**Time:** 48-72 hours (one weekend)

Enter a game jam using LOVE. Find one at [itch.io/jams](https://itch.io/jams) or wait for Ludum Dare.

Rules:
1. Use LOVE. Reuse your library setup from previous projects.
2. Follow the jam's theme and constraints.
3. Scope for something finishable in the time limit.
4. Submit before the deadline, even if it is unpolished.
5. Play and rate other jam entries.

Game jams teach rapid prototyping, creative constraint, and ruthless scoping. They are also fun.

### Exercise 3: Three-Month Plan

**Time:** 1-2 hours

Pick your next path (stay in LOVE, move to Godot, or something else). Create a concrete plan:

1. **Goal:** What do you want to have accomplished in three months?
2. **Weekly milestones:** What will you do each week to get there?
3. **First action:** What will you do tomorrow to start?

Write this down. Put it somewhere you will see it. A goal without a plan is a wish.

---

## Recommended Reading & Resources

### Essential

| Resource | Type | What You Get |
|---|---|---|
| [Awesome LOVE2D](https://github.com/love2d-community/awesome-love2d) | GitHub | Curated list of LOVE libraries and resources |
| [Game Programming Patterns](https://gameprogrammingpatterns.com) | Free book | Design patterns used in real games |
| [itch.io Game Jams](https://itch.io/jams) | Platform | Find jams to participate in |
| [howtomarketagame.com](https://howtomarketagame.com) | Blog | Data-driven indie game marketing |

### Go Deeper

| Resource | Type | What You Get |
|---|---|---|
| [Blood, Sweat, and Pixels](https://www.harpercollins.com/products/blood-sweat-and-pixels-jason-schreier) | Book | Behind-the-scenes stories of game development |
| [The Art of Game Design (Schell)](https://www.schellgames.com/art-of-game-design/) | Book | Comprehensive game design framework with 100+ "lenses" |
| [Handmade Hero](https://handmadehero.org) | Video series | Building a game from scratch in C (deep understanding) |
| [GDC Vault](https://gdcvault.com) | Talks | Free conference talks from industry professionals |
| [Sheepolution LOVE Tutorial](https://sheepolution.com/learn/book/contents) | Tutorial | Text-based LOVE guide (good for review and deepening) |

---

## Key Takeaways

- **You have game development skills, not just LOVE skills.** Game loops, state management, collision, audio, UI, shipping -- these are universal. They transfer to any engine.

- **LOVE scales further than you think.** Balatro shipped on LOVE and sold millions. If 2D is your focus, you do not need to switch engines.

- **Godot is the natural next step if you want an editor.** The transition from LOVE is smooth. Most of your knowledge transfers directly.

- **Ship small, ship often.** Your second game should be slightly bigger than your first, not ten times bigger. Game jams are the best way to practice rapid shipping.

- **The business side matters.** Making a great game is necessary but not sufficient. Marketing, wishlists, community, and store presence determine whether people actually find your game.

- **Community sustains motivation.** Join the LOVE forums, participate in jams, follow other indie devs. Game development is more fun when you are not doing it alone.

- **You are a game developer now.** Not "aspiring." Not "learning." You made a game and shipped it. Everything from here is building on a real foundation.

---

## What's Next?

This is the last module in the roadmap. There is no Module 11. The roadmap has done its job: it gave you structure when you needed it.

From here, the path is yours. Make another game. Enter a jam. Try shaders. Learn Godot. Build something weird. The most important thing is to keep making things and keep shipping them. Every game you finish makes the next one better.

You know how to make games. Go make one.

Back to the [LOVE2D Learning Roadmap](love2d-learning-roadmap.md).
