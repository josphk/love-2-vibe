# Module 1: The Game Loop Trinity
**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 5-8 hours
**Prerequisites:** [Module 0: Setup & First Pixels](module-00-setup-first-pixels.md)

---

## Overview

Every game ever made -- from Pong to Elden Ring -- runs on the same fundamental loop: **set things up, then update the world and draw it, forever**. The engine calls your code, you respond. That is the contract.

In LOVE2D, this contract is dead simple. Three functions:

```lua
love.load()      -- runs once at startup
love.update(dt)  -- runs every frame, receives elapsed time
love.draw()      -- runs every frame, renders to screen
```

That is the **Game Loop Trinity**. If you understand these three callbacks -- what goes in each, what stays out, and how `dt` ties them together -- you can build any 2D game. This module takes you from zero to a working Pong clone, and by the end you will understand *why* the loop works the way it does, not just *that* it does.

If you are coming from JavaScript or Python, here is the mental model: `love.load()` is your top-level initialization. `love.update(dt)` is `setInterval` or a `while True` loop body that handles logic. `love.draw()` is the render pass -- think React's render function, but called 60 times per second and you are painting pixels directly.

---

## Core Concepts

### 1. The Game Loop

Every game engine hides a `while` loop from you. Here is the pseudocode for what LOVE2D does internally:

```
call love.load()

while game_is_running do
    dt = time_since_last_frame()
    call love.update(dt)
    call love.draw()
    present_screen()
end
```

That is it. Load once, then spin the update-draw cycle until the player quits. LOVE calls your functions at the right time -- you never call them yourself. You just define them and fill them with your game's logic.

**Key insight for JS/Python devs:** There is no event loop to manage, no `requestAnimationFrame` to wire up, no main thread to worry about. LOVE *is* the event loop. You just write the callbacks.

The loop typically runs at 60 frames per second (if vsync is on), which means `love.update` and `love.draw` each get called ~60 times every second. Each pass through the loop is one **frame**. At 60 FPS, you have roughly 16.6 milliseconds per frame to do everything -- update positions, check collisions, draw sprites. That sounds tight, but for 2D games it is more than enough.

---

### 2. love.load() -- Set the Stage

`love.load()` runs exactly once, right when the game starts. This is where you initialize your game state, load assets (images, sounds, fonts), and set up anything that needs to exist before the first frame.

```lua
function love.load()
    -- Game state
    ball = {
        x = 400,
        y = 300,
        vx = 200,   -- pixels per second
        vy = 150,
        radius = 10
    }

    -- Assets
    font = love.graphics.newFont(24)
    love.graphics.setFont(font)

    -- Window config
    love.window.setTitle("My Game")
end
```

**What belongs here:**
- Variable initialization (positions, scores, game state)
- Asset loading (`love.graphics.newImage`, `love.audio.newSource`, `love.graphics.newFont`)
- One-time configuration (window title, background color)

**What does NOT belong here:**
- Drawing commands (those go in `love.draw`)
- Game logic that needs to run every frame (that goes in `love.update`)

**JS/Python translation:** Think of `love.load()` as your constructor, your `__init__`, your module-level setup. It is the code that runs before your app loop starts.

**Lua note:** You are declaring `ball` without `local`, which makes it a global. In small games this is fine. In larger projects you will want to use `local` and pass state around. We will cover that in later modules.

---

### 3. love.update(dt) -- Think, Never Draw

`love.update(dt)` is where your game *thinks*. Move objects, check collisions, update scores, handle input consequences. This function runs every frame, and it receives one argument: `dt`, the **delta time** -- the number of seconds since the last frame.

```lua
function love.update(dt)
    -- Move the ball
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Bounce off top and bottom edges
    if ball.y - ball.radius < 0 then
        ball.y = ball.radius
        ball.vy = -ball.vy
    elseif ball.y + ball.radius > love.graphics.getHeight() then
        ball.y = love.graphics.getHeight() - ball.radius
        ball.vy = -ball.vy
    end
end
```

**The golden rule: never call drawing functions in `love.update`.** No `love.graphics.rectangle`, no `love.graphics.print`, nothing that renders. Update is for math and logic. Draw is for pixels. Mixing them leads to bugs that are miserable to track down -- things drawing at wrong times, flickering, state corruption.

**Why `dt` matters here:** That `* dt` on the movement lines is doing critical work. We will break it down fully in Section 5, but the short version: it makes your game run at the same *speed* regardless of frame rate. Without it, your ball moves faster on a 144Hz monitor than a 60Hz one.

---

### 4. love.draw() -- Paint, Never Think

`love.draw()` is where you render your game to the screen. Every frame, LOVE clears the screen and calls `love.draw()`. You paint everything from scratch, back to front.

```lua
function love.draw()
    -- Draw the ball
    love.graphics.setColor(1, 1, 1)  -- white (RGBA, 0-1 range)
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)

    -- Draw the score
    love.graphics.print("Score: " .. score, 10, 10)
end
```

**The golden rule: never modify game state in `love.draw`.** No `ball.x = ball.x + 1`, no `score = score + 1`, no input handling. Draw is a *read-only snapshot* of your game state. It looks at the current values and paints them. That is all.

**Why?** Because `love.draw` might get called a different number of times than `love.update` in some engine configurations. If you put logic in draw, your game behavior becomes tied to rendering -- and that is a mess.

**The Painter's Algorithm:** LOVE draws things in the order you call them. First call = bottom layer, last call = top layer. If you draw a background, then a character, then a UI element, they stack correctly. If you draw the UI first and the background last, the background covers everything. There is no z-index. Order is everything.

```lua
function love.draw()
    -- Layer 1: Background (drawn first = behind everything)
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0,
        love.graphics.getWidth(), love.graphics.getHeight())

    -- Layer 2: Game objects (drawn on top of background)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)

    -- Layer 3: UI (drawn last = on top of everything)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Score: " .. score, 10, 10)
end
```

**Color state warning:** `love.graphics.setColor` is *sticky*. Once you set it, everything after draws in that color until you change it. This is the number one source of "why is everything yellow" bugs. Get in the habit of setting color before every draw call.

---

### 5. Delta Time Deep Dive

Delta time is the single most important concept in game programming, and it trips up every beginner. Let us break it down with actual math.

**The problem without dt:**

Suppose you move a ball like this:

```lua
function love.update(dt)
    ball.x = ball.x + 5  -- move 5 pixels per frame (BAD)
end
```

On a 60 FPS machine, the ball moves `5 * 60 = 300` pixels per second. On a 144 FPS machine, it moves `5 * 144 = 720` pixels per second. On a laptop that dips to 30 FPS during a heavy scene, it moves `5 * 30 = 150` pixels per second. Same code, wildly different game speeds. Your Pong game is unplayable on a gaming monitor and in slow motion on a struggling laptop.

**The fix with dt:**

```lua
function love.update(dt)
    ball.x = ball.x + 300 * dt  -- move 300 pixels per second (GOOD)
end
```

Now `300` means "300 pixels per second" -- that is the *velocity*. The `* dt` converts it to "how far to move *this frame*."

Here is the math frame by frame:

| Frame Rate | dt (seconds) | Movement per frame | Movement per second |
|---|---|---|---|
| 60 FPS | 0.0167 | 300 * 0.0167 = 5.0 px | ~300 px/s |
| 144 FPS | 0.0069 | 300 * 0.0069 = 2.1 px | ~300 px/s |
| 30 FPS | 0.0333 | 300 * 0.0333 = 10.0 px | ~300 px/s |

Same speed regardless of frame rate. The formula is always:

```
new_position = old_position + velocity * dt
```

This is literally the physics equation `x = x0 + v * t`. You are doing Euler integration every frame. The `dt` is your time step.

**Think in "per second" units.** When you write `velocity = 300`, that means 300 pixels per second. When you write `rotation_speed = math.pi`, that means pi radians per second (half a turn). Every rate-of-change variable in your game should be in "per second" units. The `* dt` handles the conversion to "per frame."

**What is dt, exactly?** At 60 FPS, `dt` is approximately `1/60 = 0.01667` seconds. It is the elapsed wall-clock time since the previous call to `love.update`. LOVE measures this for you. If a frame takes longer (maybe the garbage collector ran, or the OS stalled), `dt` will be larger, and your objects will take a bigger step to compensate. The game stays smooth in perceived time.

**One gotcha:** If `dt` spikes dramatically (you tabbed away for 5 seconds and came back), your ball might teleport across the screen in one frame. A common safety net:

```lua
function love.update(dt)
    dt = math.min(dt, 1/30)  -- clamp to max 1/30th of a second
    -- rest of your update logic
end
```

This caps `dt` so the game never tries to simulate more than 1/30th of a second in a single frame. Objects might briefly freeze instead of teleporting, which is almost always the better failure mode.

---

### 6. Game State as Data

Your entire game is just variables. Positions, velocities, scores, flags -- all data. The update function changes the data, the draw function reads it. This separation is the backbone of every game architecture.

```lua
function love.load()
    -- All game state lives in tables
    paddle1 = { x = 30,  y = 250, width = 10, height = 80, speed = 400, score = 0 }
    paddle2 = { x = 760, y = 250, width = 10, height = 80, speed = 400, score = 0 }
    ball = { x = 400, y = 300, vx = 250, vy = 200, radius = 8 }

    -- Game flags
    game_state = "playing"  -- "playing", "paused", "game_over"
    winning_score = 5
end
```

**Why tables?** In Lua, tables are the only compound data structure. They serve as arrays, dictionaries, objects, and structs. If you are coming from Python, think `dict`. From JavaScript, think plain object. Grouping related data into tables (`paddle1.x` instead of `paddle1_x`) keeps your code organized and makes it easy to pass entities around.

**State drives everything.** Your `love.update` reads and writes this state. Your `love.draw` reads it. Input changes it. Collisions change it. The game *is* this data -- the visual output is just a side effect of rendering it.

```lua
function love.update(dt)
    if game_state == "paused" then
        return  -- skip all logic when paused
    end

    -- Move ball
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt
end
```

See how `game_state` controls the entire update? One variable, one `if` check, and your game has a pause feature. That is the power of state-driven design.

---

### 7. Input Handling

LOVE gives you two ways to handle keyboard input, and they solve different problems.

#### Continuous Input: `love.keyboard.isDown()`

Use this when you want to know if a key is *currently held down*. This is what you want for movement -- the paddle should move as long as the player holds the key.

```lua
function love.update(dt)
    -- Player 1 controls (W/S)
    if love.keyboard.isDown("w") then
        paddle1.y = paddle1.y - paddle1.speed * dt
    end
    if love.keyboard.isDown("s") then
        paddle1.y = paddle1.y + paddle1.speed * dt
    end

    -- Player 2 controls (Up/Down arrows)
    if love.keyboard.isDown("up") then
        paddle2.y = paddle2.y - paddle2.speed * dt
    end
    if love.keyboard.isDown("down") then
        paddle2.y = paddle2.y + paddle2.speed * dt
    end
end
```

Notice: these are `if`, not `elseif`. The player can press W and S simultaneously (nothing moves, which is correct). And we use `* dt` on the movement because this is velocity-based.

#### One-Shot Input: `love.keypressed()`

Use this when you want to respond to a key being *pressed once* -- like pausing, starting the game, or firing a projectile. This is a callback, not a polling function. LOVE calls it for you when a key goes down.

```lua
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if key == "space" then
        if game_state == "paused" then
            game_state = "playing"
        elseif game_state == "playing" then
            game_state = "paused"
        end
    end
end
```

**When to use which:**

| Situation | Use | Why |
|---|---|---|
| Move paddle while holding key | `love.keyboard.isDown` | Continuous, frame-by-frame |
| Pause/unpause on press | `love.keypressed` | One-shot, fires once per press |
| Shoot a bullet | `love.keypressed` | One bullet per press, not 60 per second |
| Sprint while holding shift | `love.keyboard.isDown` | Continuous modifier |
| Open menu | `love.keypressed` | One-shot toggle |

**JS/Python parallel:** `love.keyboard.isDown` is like checking a `keyState` map every frame. `love.keypressed` is like `addEventListener("keydown", ...)` -- it fires once per key press.

There is also `love.keyreleased(key)` which fires when a key is let go. Useful for charge-and-release mechanics.

---

### 8. Basic Collision Detection

Games need to know when things touch. At this stage, you need two types of collision: edge collision (keeping things on screen) and box collision (paddle meets ball).

#### Screen Edge Collision

The screen runs from `(0, 0)` at the top-left to `(width, height)` at the bottom-right. To keep a paddle on screen:

```lua
-- Clamp paddle to screen bounds
if paddle1.y < 0 then
    paddle1.y = 0
end
if paddle1.y + paddle1.height > love.graphics.getHeight() then
    paddle1.y = love.graphics.getHeight() - paddle1.height
end
```

For the ball, you *bounce* instead of clamping -- reverse the velocity component:

```lua
-- Bounce off top/bottom
if ball.y - ball.radius < 0 then
    ball.y = ball.radius
    ball.vy = -ball.vy
end
if ball.y + ball.radius > love.graphics.getHeight() then
    ball.y = love.graphics.getHeight() - ball.radius
    ball.vy = -ball.vy
end
```

Note the position correction (`ball.y = ball.radius`). Without it, the ball can get "stuck" inside the wall -- the velocity flips, but the ball is still past the edge, so next frame it flips again, creating a vibrating mess. Always push the object back to a valid position when you reverse its velocity.

#### AABB Collision (Axis-Aligned Bounding Box)

This is the workhorse of 2D collision. Two rectangles overlap if and only if they overlap on *both* axes. If there is a gap on either axis, they are not colliding.

```lua
function check_collision(a, b)
    return a.x < b.x + b.width  and
           a.x + a.width > b.x  and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end
```

For a circle-vs-rectangle check (ball vs paddle), you can approximate the ball as a square bounding box:

```lua
-- Create a bounding box for the ball
local ball_box = {
    x = ball.x - ball.radius,
    y = ball.y - ball.radius,
    width = ball.radius * 2,
    height = ball.radius * 2
}

if check_collision(ball_box, paddle1) then
    ball.vx = math.abs(ball.vx)  -- force rightward
    ball.x = paddle1.x + paddle1.width + ball.radius  -- push out
end
```

The `math.abs` trick ensures the ball always moves *away* from the paddle after a hit, preventing the ball from getting stuck inside the paddle on rapid collisions. We will cover fancier collision (circle-rect, SAT) in later modules.

---

### 9. The Full Callback List

The Trinity (`load`, `update`, `draw`) are the callbacks you will use in every game. But LOVE has many more. Here are the ones worth knowing about now:

| Callback | When It Fires | Common Use |
|---|---|---|
| `love.load()` | Once, at startup | Initialize state, load assets |
| `love.update(dt)` | Every frame | Game logic, physics, AI |
| `love.draw()` | Every frame, after update | Render everything |
| `love.keypressed(key)` | Key goes down | One-shot actions (pause, fire) |
| `love.keyreleased(key)` | Key goes up | Charge-release mechanics |
| `love.mousepressed(x, y, button)` | Mouse button goes down | UI clicks, aiming |
| `love.mousereleased(x, y, button)` | Mouse button goes up | Drag-and-drop release |
| `love.mousemoved(x, y, dx, dy)` | Mouse moves | Cursor tracking, camera |
| `love.wheelmoved(x, y)` | Scroll wheel moves | Zoom, scroll UI |
| `love.focus(focused)` | Window gains/loses focus | Auto-pause when tabbed out |
| `love.resize(w, h)` | Window is resized | Recalculate layout |
| `love.quit()` | Player tries to close | Save game, confirm quit |
| `love.textinput(text)` | Character typed | Text fields, chat input |
| `love.errhand(msg)` | Unhandled error | Custom error screens |

A useful pattern -- auto-pause when the window loses focus:

```lua
function love.focus(focused)
    if not focused then
        game_state = "paused"
    end
end
```

And confirming quit:

```lua
function love.quit()
    -- Return true to abort the quit
    -- Return false (or nil) to allow it
    print("Thanks for playing!")
    return false
end
```

---

### 10. conf.lua -- Configuring Your Game

Before any of your game code runs, LOVE looks for a file called `conf.lua` in your project folder. This file configures the window, enables/disables modules, and sets metadata.

```lua
-- conf.lua (separate file, same directory as main.lua)
function love.conf(t)
    t.window.title = "Pong"
    t.window.width = 800
    t.window.height = 600
    t.window.vsync = 1           -- 1 = on, 0 = off
    t.window.resizable = false

    -- Disable modules you don't need (faster startup)
    t.modules.joystick = false
    t.modules.physics = false
end
```

**Why a separate file?** `conf.lua` runs *before* `love.load`. The window is created based on these settings, then your game code starts. If you set the window size in `love.load` instead, there is a brief flash of the default window resizing. `conf.lua` avoids that.

**vsync:** Vertical sync locks your frame rate to your monitor's refresh rate (usually 60 Hz). With vsync on, `dt` is a steady ~0.0167. With vsync off, the game runs as fast as possible, and `dt` varies. Keep vsync on for now. You can turn it off later when you want to stress-test or need higher frame rates.

**Common conf.lua settings:**

| Setting | Default | What It Does |
|---|---|---|
| `t.window.width` | 800 | Window width in pixels |
| `t.window.height` | 600 | Window height in pixels |
| `t.window.title` | "Untitled" | Title bar text |
| `t.window.vsync` | 1 | Lock to monitor refresh rate |
| `t.window.resizable` | false | Allow window resizing |
| `t.window.fullscreen` | false | Start in fullscreen |
| `t.console` | false | Open debug console (Windows) |
| `t.identity` | nil | Save directory name |
| `t.version` | "11.4" | LOVE version compatibility |

---

## Code Walkthrough: Building Pong

Time to put it all together. We will build Pong step by step, and every step maps directly to concepts you just learned.

### Step 1: conf.lua

```lua
-- conf.lua
function love.conf(t)
    t.window.title = "Pong"
    t.window.width = 800
    t.window.height = 600
    t.window.vsync = 1
end
```

### Step 2: Game State in love.load

```lua
-- main.lua
function love.load()
    -- Paddles
    paddle_w = 12
    paddle_h = 80
    paddle_speed = 400

    player1 = {
        x = 30,
        y = 300 - paddle_h / 2,
        score = 0
    }

    player2 = {
        x = 800 - 30 - paddle_w,
        y = 300 - paddle_h / 2,
        score = 0
    }

    -- Ball
    ball = {
        x = 400,
        y = 300,
        radius = 8,
        speed = 300
    }
    reset_ball()

    -- Game config
    winning_score = 5
    game_state = "start"  -- "start", "playing", "scored", "game_over"

    -- Font
    small_font = love.graphics.newFont(16)
    large_font = love.graphics.newFont(48)
    love.graphics.setFont(small_font)
end

function reset_ball()
    ball.x = 400
    ball.y = 300
    -- Random direction, always moving toward a player
    local angle = love.math.random() * math.pi / 3 - math.pi / 6
    local direction = love.math.random(2) == 1 and 1 or -1
    ball.vx = math.cos(angle) * ball.speed * direction
    ball.vy = math.sin(angle) * ball.speed
end
```

**What is happening:** All game state is set up as simple variables and tables. The `reset_ball` function gives the ball a random-ish direction using basic trig. `love.math.random` is LOVE's built-in RNG (better than Lua's `math.random`).

### Step 3: Input and Movement in love.update

```lua
function love.update(dt)
    if game_state ~= "playing" then
        return
    end

    -- Player 1 input (W/S)
    if love.keyboard.isDown("w") then
        player1.y = player1.y - paddle_speed * dt
    end
    if love.keyboard.isDown("s") then
        player1.y = player1.y + paddle_speed * dt
    end

    -- Player 2 input (Up/Down)
    if love.keyboard.isDown("up") then
        player2.y = player2.y - paddle_speed * dt
    end
    if love.keyboard.isDown("down") then
        player2.y = player2.y + paddle_speed * dt
    end

    -- Clamp paddles to screen
    player1.y = math.max(0, math.min(player1.y,
        love.graphics.getHeight() - paddle_h))
    player2.y = math.max(0, math.min(player2.y,
        love.graphics.getHeight() - paddle_h))

    -- Move ball
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Ball: bounce off top/bottom
    if ball.y - ball.radius < 0 then
        ball.y = ball.radius
        ball.vy = -ball.vy
    end
    if ball.y + ball.radius > love.graphics.getHeight() then
        ball.y = love.graphics.getHeight() - ball.radius
        ball.vy = -ball.vy
    end

    -- Ball: collide with paddles
    if hits_paddle(player1) then
        ball.vx = math.abs(ball.vx)  -- force rightward
        ball.x = player1.x + paddle_w + ball.radius
        add_spin(player1)
    end

    if hits_paddle(player2) then
        ball.vx = -math.abs(ball.vx)  -- force leftward
        ball.x = player2.x - ball.radius
        add_spin(player2)
    end

    -- Ball: score when going off left/right edges
    if ball.x < 0 then
        player2.score = player2.score + 1
        check_winner()
    elseif ball.x > love.graphics.getWidth() then
        player1.score = player1.score + 1
        check_winner()
    end
end
```

### Step 4: Helper Functions

```lua
function hits_paddle(player)
    return ball.x - ball.radius < player.x + paddle_w and
           ball.x + ball.radius > player.x and
           ball.y - ball.radius < player.y + paddle_h and
           ball.y + ball.radius > player.y
end

function add_spin(player)
    -- Where on the paddle did the ball hit? (-1 to 1)
    local hit_pos = (ball.y - (player.y + paddle_h / 2)) / (paddle_h / 2)
    ball.vy = hit_pos * ball.speed * 0.75

    -- Speed up slightly with each hit
    ball.speed = ball.speed + 15
    local angle = math.atan2(ball.vy, ball.vx)
    ball.vx = math.cos(angle) * ball.speed
    ball.vy = math.sin(angle) * ball.speed
end

function check_winner()
    if player1.score >= winning_score or player2.score >= winning_score then
        game_state = "game_over"
    else
        game_state = "scored"
        reset_ball()
    end
end
```

**The `add_spin` function** is what makes Pong feel like Pong. If the ball hits the center of the paddle, it bounces flat. If it hits the edge, it bounces at a steep angle. The player can *aim* by positioning the paddle. One function, and suddenly the game has skill expression.

### Step 5: One-Shot Input

```lua
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if key == "space" or key == "return" then
        if game_state == "start" then
            game_state = "playing"
        elseif game_state == "scored" then
            game_state = "playing"
        elseif game_state == "game_over" then
            -- Reset everything
            player1.score = 0
            player2.score = 0
            ball.speed = 300
            reset_ball()
            game_state = "playing"
        end
    end
end
```

### Step 6: Drawing

```lua
function love.draw()
    -- Background
    love.graphics.clear(0.05, 0.05, 0.1)

    -- Center line
    love.graphics.setColor(0.3, 0.3, 0.4)
    for y = 0, love.graphics.getHeight(), 20 do
        love.graphics.rectangle("fill", 400 - 1, y, 2, 10)
    end

    -- Paddles
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", player1.x, player1.y, paddle_w, paddle_h)
    love.graphics.rectangle("fill", player2.x, player2.y, paddle_w, paddle_h)

    -- Ball
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)

    -- Scores
    love.graphics.setFont(large_font)
    love.graphics.printf(tostring(player1.score), 0, 30, 380, "right")
    love.graphics.printf(tostring(player2.score), 420, 30, 380, "left")

    -- State messages
    love.graphics.setFont(small_font)
    if game_state == "start" then
        love.graphics.printf("Press SPACE to start",
            0, 400, 800, "center")
    elseif game_state == "scored" then
        love.graphics.printf("Press SPACE to serve",
            0, 400, 800, "center")
    elseif game_state == "game_over" then
        love.graphics.setFont(large_font)
        local winner = player1.score >= winning_score and "Player 1" or "Player 2"
        love.graphics.printf(winner .. " Wins!",
            0, 200, 800, "center")
        love.graphics.setFont(small_font)
        love.graphics.printf("Press SPACE to play again",
            0, 400, 800, "center")
    end
end
```

**Notice the draw order:** background, then center line, then paddles, then ball, then UI text. Painter's algorithm in action -- each layer paints over the last.

---

## API Quick Reference

### Graphics

| Function | What It Does |
|---|---|
| `love.graphics.rectangle(mode, x, y, w, h)` | Draw rectangle. `mode` is `"fill"` or `"line"` |
| `love.graphics.circle(mode, x, y, radius)` | Draw circle |
| `love.graphics.line(x1, y1, x2, y2)` | Draw line |
| `love.graphics.print(text, x, y)` | Draw text at position |
| `love.graphics.printf(text, x, y, limit, align)` | Draw text with wrapping and alignment |
| `love.graphics.setColor(r, g, b, a)` | Set draw color (0-1 range). Sticky! |
| `love.graphics.clear(r, g, b)` | Clear screen to a color |
| `love.graphics.getWidth()` | Window width in pixels |
| `love.graphics.getHeight()` | Window height in pixels |
| `love.graphics.newFont(size)` | Create font object |
| `love.graphics.setFont(font)` | Set active font |

### Input

| Function | What It Does |
|---|---|
| `love.keyboard.isDown(key)` | Is key currently held? (poll in update) |
| `love.keypressed(key)` | Callback: key was just pressed (define as function) |
| `love.keyreleased(key)` | Callback: key was just released |
| `love.mouse.getPosition()` | Returns `x, y` of mouse cursor |
| `love.mouse.isDown(button)` | Is mouse button held? (`1` = left, `2` = right) |

### System

| Function | What It Does |
|---|---|
| `love.event.quit()` | Close the game |
| `love.timer.getFPS()` | Current frames per second |
| `love.timer.getDelta()` | Same as `dt` argument to update |
| `love.math.random(min, max)` | Random integer in range |
| `love.math.random()` | Random float 0-1 |
| `love.window.setTitle(title)` | Change window title |

---

## Common Pitfalls

### 1. Drawing in update, logic in draw

The most common beginner mistake. You call `love.graphics.rectangle` inside `love.update` and wonder why nothing appears (it gets cleared before `love.draw` runs). Or you do `ball.x = ball.x + 1` inside `love.draw` and your ball speed becomes tied to frame rate. Hard rule: update thinks, draw paints.

### 2. Forgetting dt

```lua
-- BAD: speed depends on frame rate
ball.x = ball.x + 5

-- GOOD: speed is frame-rate independent
ball.x = ball.x + 300 * dt
```

Without `dt`, your game runs at different speeds on different hardware. Always multiply rates of change by `dt`. If something moves, rotates, fades, grows, or shrinks over time, it needs `dt`.

### 3. Color bleed

`love.graphics.setColor` is global and sticky. If you set color to red for an enemy and forget to reset it, your score text, background, and everything else turns red too. Always set color immediately before each draw call. A `love.graphics.setColor(1, 1, 1)` at the top of `love.draw` is a good safety net.

### 4. Objects stuck in walls

When a ball bounces off a wall, you reverse the velocity -- but if the ball is already *past* the wall, the reversed velocity pushes it further past. Next frame it reverses again, and the ball vibrates on the edge forever. Always correct the position when you reverse velocity:

```lua
-- BAD: might get stuck
if ball.y < 0 then
    ball.vy = -ball.vy
end

-- GOOD: push back to valid position
if ball.y - ball.radius < 0 then
    ball.y = ball.radius          -- correct position
    ball.vy = -ball.vy            -- then reverse
end
```

### 5. Using `math.random` instead of `love.math.random`

Lua's built-in `math.random` uses a weak RNG and requires you to seed it manually with `math.randomseed(os.time())`. LOVE's `love.math.random` uses a better algorithm and is pre-seeded. Use LOVE's version.

### 6. Hardcoding window dimensions

```lua
-- BAD: breaks if you change conf.lua
if ball.x > 800 then ...

-- GOOD: adapts to any window size
if ball.x > love.graphics.getWidth() then ...
```

Always use `love.graphics.getWidth()` and `love.graphics.getHeight()`. If you decide to change your window size later (or add resizing), hardcoded values break silently -- things go off-screen or collide with invisible walls.

---

## Exercises

### Exercise 1: Bouncing Ball Sandbox
**Time:** 30-45 minutes

Start from scratch (no Pong code). Create a ball that bounces around the screen, changing color every time it hits a wall.

Requirements:
1. Ball starts at the center of the screen with a random velocity.
2. Ball bounces off all four edges (top, bottom, left, right).
3. Each bounce changes the ball's color to a new random color.
4. Display the current FPS in the top-left corner using `love.timer.getFPS()`.
5. Press `R` to reset the ball to the center with a new random velocity.

**Stretch:** Add a trail effect by drawing the ball at 20% opacity at its last 10 positions.

---

### Exercise 2: Pong Enhancements
**Time:** 45-60 minutes

Take the Pong code from the walkthrough and add the following:

1. **Speed increase**: Ball gets 10% faster every 5 paddle hits.
2. **Serve direction**: After a point, the ball always serves toward the player who *lost* the point.
3. **Pause**: Press `P` to pause/unpause. Show "PAUSED" text in the center when paused.
4. **Ball trail**: Draw a fading trail behind the ball (hint: store the last N positions in a table, draw them with decreasing opacity).
5. **Sound effects**: Add a blip sound on paddle hit and a buzz on score. Use `love.audio.newSource("blip.wav", "static")` in `love.load` and `:play()` on collision. (You will need to create or download short `.wav` files.)

---

### Exercise 3: Solo Breakout Prototype
**Time:** 60-90 minutes

Using only the concepts from this module, build a single-screen Breakout prototype:

1. One paddle at the bottom, controlled with left/right arrow keys.
2. A ball that bounces off the paddle, walls, and bricks.
3. A grid of bricks (3 rows of 10) at the top of the screen.
4. Bricks disappear when the ball hits them. Track bricks in a 2D table.
5. Score display: +10 points per brick. Show score in the corner.
6. Lose condition: ball goes off the bottom of the screen.
7. Win condition: all bricks destroyed.

**Hints:**
- Bricks can be stored as `bricks[row][col] = { x, y, width, height, alive }`.
- In `love.update`, loop through all bricks and check AABB collision with the ball.
- When a brick is hit, set `alive = false` and reverse `ball.vy`.
- In `love.draw`, only draw bricks where `alive == true`.

---

## Key Takeaways

- **The game loop is load-once, then update-draw forever.** `love.load` initializes, `love.update(dt)` handles logic, `love.draw` renders. Never cross the streams.

- **Delta time makes your game frame-rate independent.** Every velocity, rotation, or timed change must multiply by `dt`. Think in "per second" units. The formula is always `new = old + rate * dt`.

- **Game state is just data.** Your entire game is variables in tables. Update writes them, draw reads them. This separation is not a suggestion -- it is architecture.

- **Drawing order is your z-index.** LOVE uses the painter's algorithm. First drawn = back layer, last drawn = front layer. Set color before every draw call.

- **Use the right input method.** `love.keyboard.isDown` for continuous actions (movement), `love.keypressed` for one-shot events (pause, fire, menu select).

- **Always correct position on collision.** Reverse velocity *and* push the object back to a valid position. Otherwise things get stuck in walls.

---

## What's Next?

You now have a working game loop, input handling, basic collision, and a playable Pong. That is a real game. You built it from scratch.

In [Module 2: Graphics & the Coordinate System](module-02-graphics-coordinate-system.md), you will learn how LOVE's coordinate system works in depth -- transforms (translate, rotate, scale), the graphics state stack (`push`/`pop`), sprite sheets, and how to build a camera system. The static rectangles of Pong are about to start spinning, scaling, and scrolling.
