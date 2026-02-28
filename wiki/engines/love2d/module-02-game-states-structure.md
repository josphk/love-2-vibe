# Module 2: Game States & Structure

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 4-6 hours
**Prerequisites:** [Module 1: The Game Loop Trinity](module-01-game-loop-trinity.md)

---

## Overview

In Module 1, you built a game loop: `love.load()`, `love.update(dt)`, `love.draw()`. Everything lived in one file. One screen. One mode.

That works for "ball bounces around." It falls apart the second you want a title screen, a pause menu, a game-over screen, or a level select. Without structure, you end up with a growing pile of `if currentScreen == "menu" then` branches scattered across every callback. Every new screen doubles the number of places you can introduce bugs.

This module teaches you how to organize a LOVE game into discrete **states** -- self-contained screens that manage their own logic, rendering, and transitions. You will start with the naive approach (if/else chains), understand why it breaks down, then build proper state tables, and finally see how the `hump.gamestate` library handles it for you.

By the end, you will have a 3-state Pong game (title -> playing -> game over) with clean transitions and a file-per-state structure you can scale to any project.

---

## 1. Why State Management Matters

Imagine your Pong game from Module 1. You want to add:
- A **title screen** ("Press Enter to Play")
- A **game-over screen** ("Player 1 Wins! Press Enter to Restart")

Without any organizational pattern, here is what happens to your `love.update()`:

```lua
function love.update(dt)
    if screen == "title" then
        -- maybe animate the title
    elseif screen == "playing" then
        -- move paddles
        -- move ball
        -- check collisions
        -- check scoring
        if someone_won then
            screen = "gameover"
        end
    elseif screen == "gameover" then
        -- maybe animate something
    end
end
```

And your `love.draw()` gets the same treatment:

```lua
function love.draw()
    if screen == "title" then
        love.graphics.print("PONG", 300, 200)
        love.graphics.print("Press Enter", 280, 300)
    elseif screen == "playing" then
        -- draw paddles, ball, scores...
    elseif screen == "gameover" then
        love.graphics.print("Game Over!", 280, 200)
    end
end
```

And `love.keypressed()` too. And `love.mousepressed()` if you add buttons. Every single callback gets its own copy of the if/else chain. This is the **spaghetti problem**.

Three screens feels manageable. Five screens and you are scrolling through a 400-line `main.lua` hunting for the one draw call that is off by ten pixels. Ten screens and you are debugging state transitions at 2 AM because `love.keypressed` forgot to check for `"settings"`.

The fix is not discipline. The fix is **architecture**.

---

## 2. Approach 1: The If/Else Chain

Let's be honest -- for a 2-state game (playing and paused), the if/else chain is fine. Here it is in full:

```lua
-- main.lua (if/else approach)
local state = "title"
local ball = { x = 400, y = 300, dx = 200, dy = 150 }

function love.load()
    love.graphics.setFont(love.graphics.newFont(24))
end

function love.update(dt)
    if state == "title" then
        -- nothing to update
    elseif state == "playing" then
        ball.x = ball.x + ball.dx * dt
        ball.y = ball.y + ball.dy * dt
        -- bounce off walls
        if ball.y < 0 or ball.y > 600 then
            ball.dy = -ball.dy
        end
        if ball.x < 0 or ball.x > 800 then
            state = "gameover"
        end
    elseif state == "gameover" then
        -- nothing to update
    end
end

function love.draw()
    if state == "title" then
        love.graphics.print("PONG", 370, 200)
        love.graphics.print("Press Enter to Start", 280, 300)
    elseif state == "playing" then
        love.graphics.circle("fill", ball.x, ball.y, 10)
    elseif state == "gameover" then
        love.graphics.print("Game Over!", 330, 200)
        love.graphics.print("Press Enter to Restart", 270, 300)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if state == "title" and key == "return" then
        ball.x, ball.y = 400, 300
        state = "playing"
    elseif state == "gameover" and key == "return" then
        ball.x, ball.y = 400, 300
        ball.dx, ball.dy = 200, 150
        state = "title"
    end
end
```

**When this breaks:**
- You add a settings screen and now every callback has 4 branches.
- You want a fade transition between states. Where does the fade timer live? Who draws it? Both the outgoing and incoming state?
- You want to pause the game (overlay, not replace). The if/else chain has no concept of "stack." You are either in one state or another.
- Two developers edit `main.lua` at the same time. Merge conflicts everywhere.

The if/else chain teaches you the *concept* of game states. It is not a production pattern.

---

## 3. Approach 2: State Tables

Here is the idea: each state is a **Lua table** with its own `enter()`, `update(dt)`, `draw()`, and `exit()` functions. A small piece of manager code delegates the LOVE callbacks to whichever state is currently active.

This is the pattern you will use most in LOVE games. It is simple enough to write from scratch and powerful enough for a full game.

### The State Template

```lua
-- A state is just a table with known function keys
local PlayState = {}

function PlayState:enter(params)
    -- called once when switching TO this state
    -- params is a table of data from the previous state
    self.ball = { x = 400, y = 300, dx = 200, dy = 150 }
    self.score = params and params.score or 0
end

function PlayState:exit()
    -- called once when switching AWAY from this state
    -- clean up timers, stop music, etc.
end

function PlayState:update(dt)
    self.ball.x = self.ball.x + self.ball.dx * dt
    self.ball.y = self.ball.y + self.ball.dy * dt

    if self.ball.y < 0 or self.ball.y > 600 then
        self.ball.dy = -self.ball.dy
    end
    if self.ball.x < 0 or self.ball.x > 800 then
        switchState(GameOverState, { score = self.score })
    end
end

function PlayState:draw()
    love.graphics.circle("fill", self.ball.x, self.ball.y, 10)
    love.graphics.print("Score: " .. self.score, 10, 10)
end

function PlayState:keypressed(key)
    -- handle state-specific keys
end

return PlayState
```

### The State Manager

The manager is surprisingly small:

```lua
-- statemanager.lua
local StateManager = {}
local currentState = nil

function StateManager.switch(newState, params)
    if currentState and currentState.exit then
        currentState:exit()
    end
    currentState = newState
    if currentState.enter then
        currentState:enter(params)
    end
end

function StateManager.update(dt)
    if currentState and currentState.update then
        currentState:update(dt)
    end
end

function StateManager.draw()
    if currentState and currentState.draw then
        currentState:draw()
    end
end

function StateManager.keypressed(key)
    if currentState and currentState.keypressed then
        currentState:keypressed(key)
    end
end

-- Add more callbacks as needed: mousepressed, keyreleased, etc.

return StateManager
```

### Wiring It Up

```lua
-- main.lua (state table approach)
local StateManager = require("statemanager")
local TitleState = require("states.title")

function love.load()
    love.graphics.setFont(love.graphics.newFont(24))
    StateManager.switch(TitleState)
end

function love.update(dt)
    StateManager.update(dt)
end

function love.draw()
    StateManager.draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    StateManager.keypressed(key)
end
```

Look at that `main.lua`. It does not know or care what a "title screen" looks like. It delegates everything. Adding a new state means creating a new file -- `main.lua` never changes.

### The `switchState` Problem

In the `PlayState` code above, I wrote `switchState(GameOverState, ...)`. But where does `switchState` come from? You have three options:

1. **Make the StateManager global:** `SM = require("statemanager")` in `main.lua`. States call `SM.switch(...)`. Simple, works, slightly dirty.
2. **Pass it into `enter()`:** Each state receives a reference to the switch function. Cleaner, more boilerplate.
3. **Use a library:** This is exactly what `hump.gamestate` does.

For small projects, option 1 is fine. Make the state manager global, move on with your life.

---

## 4. Approach 3: hump.gamestate

[hump](https://github.com/vrld/hump) is a collection of small utility libraries for LOVE. `hump.gamestate` gives you a battle-tested state manager with push/pop support, automatic callback delegation, and zero boilerplate.

### Setup

Download hump and put it in your project directory (or a `lib/` subfolder):

```
my-game/
  lib/
    hump/
      gamestate.lua
      ...
  states/
    title.lua
    play.lua
    gameover.lua
  main.lua
  conf.lua
```

### Basic Usage

```lua
-- main.lua
local Gamestate = require("lib.hump.gamestate")
local TitleState = require("states.title")

function love.load()
    Gamestate.registerEvents()  -- hooks into all LOVE callbacks automatically
    Gamestate.switch(TitleState)
end
```

That is it. `Gamestate.registerEvents()` overrides `love.update`, `love.draw`, `love.keypressed`, and every other callback to automatically forward them to the current state. You do not write delegation code. You do not touch `main.lua` again.

### A State with hump

```lua
-- states/title.lua
local Gamestate = require("lib.hump.gamestate")
local PlayState -- forward declaration, required below

local TitleState = {}

function TitleState:init()
    -- called ONCE, ever, the first time this state is entered
    -- use for heavy loading (images, sounds)
    PlayState = require("states.play")
end

function TitleState:enter()
    -- called every time you switch TO this state
end

function TitleState:update(dt)
    -- per-frame logic
end

function TitleState:draw()
    love.graphics.print("PONG", 370, 200)
    love.graphics.print("Press Enter to Start", 280, 300)
end

function TitleState:keypressed(key)
    if key == "return" then
        Gamestate.switch(PlayState)
    end
end

return TitleState
```

### Key Differences from DIY

| Feature | DIY State Tables | hump.gamestate |
|---|---|---|
| Callback delegation | You write it | `registerEvents()` handles it |
| `init()` (one-time setup) | You implement it yourself | Built in |
| Push/Pop (state stacking) | You build it | `Gamestate.push()` / `Gamestate.pop()` |
| Passing data on switch | `enter(params)` | Extra args: `Gamestate.switch(state, score, level)` |

### Passing Data Between States

With `hump.gamestate`, extra arguments to `switch()` are passed directly to the new state's `enter()`:

```lua
-- In PlayState, when the game ends:
Gamestate.switch(GameOverState, self.score, self.winner)

-- In GameOverState:
function GameOverState:enter(previous, score, winner)
    -- 'previous' is the state you came from (hump injects this)
    self.finalScore = score
    self.winnerName = winner
end
```

Note: the first argument to `enter()` is always the **previous state** (injected by hump). Your custom data starts at the second argument. This trips people up -- watch for it.

---

## 5. State Transitions

Switching states instantly feels jarring. A half-second fade makes transitions feel polished.

### Fade Transition Pattern

The trick is a **transition state** that sits between two real states:

```lua
-- states/fade.lua
local Gamestate = require("lib.hump.gamestate")
local FadeState = {}

function FadeState:enter(previous, nextState, duration, ...)
    self.previous = previous
    self.nextState = nextState
    self.duration = duration or 0.5
    self.timer = 0
    self.extraArgs = {...}
end

function FadeState:update(dt)
    self.timer = self.timer + dt
    if self.timer >= self.duration then
        Gamestate.switch(self.nextState, unpack(self.extraArgs))
    end
end

function FadeState:draw()
    -- draw the previous state underneath
    if self.previous and self.previous.draw then
        self.previous:draw()
    end
    -- overlay a black rectangle with increasing alpha
    local alpha = math.min(self.timer / self.duration, 1)
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setColor(1, 1, 1, 1)  -- reset color
end

return FadeState
```

Usage:

```lua
-- instead of: Gamestate.switch(GameOverState, score)
-- do:
Gamestate.switch(FadeState, GameOverState, 0.5, score)
```

For a full fade-in/fade-out, you would extend this to two phases: fade out the old state, then fade in the new one. But even a simple fade-to-black adds surprising polish.

### Enter/Exit Hooks

The `enter()` / `exit()` pair is your setup/teardown contract:

- **`enter()`**: Initialize state-specific data. Start music. Reset timers. Receive data from the previous state.
- **`exit()`**: Stop music. Cancel timers. Release resources you will not need again.

If you start a looping sound in `enter()` and forget to stop it in `exit()`, it plays over the next state. Every `enter()` should have a corresponding `exit()` that undoes anything persistent.

---

## 6. State Stacking (Push/Pop)

Switching states **replaces** the current state. But sometimes you want to **overlay** one state on top of another -- a pause menu drawn over the game, or an inventory screen over the world.

This is where **push** and **pop** come in.

```lua
-- During gameplay, player presses Escape:
function PlayState:keypressed(key)
    if key == "escape" then
        Gamestate.push(PauseState)  -- PlayState stays in memory
    end
end

-- In PauseState:
function PauseState:draw()
    -- the previous state's draw is NOT called automatically
    -- you must draw it yourself if you want it visible underneath
    Gamestate.current() -- this is PauseState, not helpful here

    -- draw a semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("PAUSED", 360, 280)
    love.graphics.print("Press Escape to Resume", 260, 330)
end

function PauseState:keypressed(key)
    if key == "escape" then
        Gamestate.pop()  -- returns to PlayState, which never lost its data
    end
end
```

**Push vs. Switch:**
- `switch(newState)` -- calls `exit()` on old state, `enter()` on new state. Old state is gone.
- `push(newState)` -- calls `pause()` on old state (if it exists), `enter()` on new state. Old state is preserved on a stack.
- `pop()` -- calls `exit()` on current state, `resume()` on the state below it. Back where you were.

The lifecycle callbacks with push/pop:
```
push(PauseState):   PlayState:pause()  -->  PauseState:enter()
pop():              PauseState:exit()   -->  PlayState:resume()
```

If you want the game world visible behind your pause menu, you need to either:
1. Draw it yourself in `PauseState:draw()` (call `PlayState:draw()` manually), or
2. Render the game to a canvas before pushing and draw that canvas as a background.

Option 1 is simpler for pause screens. Option 2 is better if you want to apply a blur effect.

---

## 7. Code Organization

Once you have states, you have a natural file structure:

```
my-game/
  main.lua              -- bootstrap only: load font, register events, switch to first state
  conf.lua              -- window size, title, vsync, etc.
  constants.lua         -- PADDLE_SPEED, BALL_RADIUS, colors, etc.
  statemanager.lua      -- (if not using hump)
  lib/
    hump/               -- external libraries
  states/
    title.lua
    play.lua
    gameover.lua
    pause.lua
  entities/
    ball.lua
    paddle.lua
  assets/
    sounds/
    images/
    fonts/
```

**Rules of thumb:**
- `main.lua` should be under 30 lines. It loads, it delegates, it is done.
- One file per state. Always.
- One file per entity type (ball, paddle, enemy). Always.
- Constants in one place. Never magic numbers in game logic.

---

## 8. The `require()` System

If you are coming from JavaScript or Python, Lua's module system will feel both familiar and slightly off. Here is the mental model.

### How `require()` Works

```lua
local Ball = require("entities.ball")
```

This does:
1. Looks for `entities/ball.lua` (dots become path separators).
2. Runs the file **once**. The return value is cached.
3. Subsequent `require("entities.ball")` calls return the **cached** result -- the file is not re-executed.

### Writing a Module

A Lua module is a file that returns something (usually a table):

```lua
-- entities/ball.lua
local Ball = {}

function Ball.new(x, y)
    return {
        x = x,
        y = y,
        radius = 10,
        dx = 200,
        dy = 150,
    }
end

function Ball.update(ball, dt)
    ball.x = ball.x + ball.dx * dt
    ball.y = ball.y + ball.dy * dt
end

function Ball.draw(ball)
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)
end

return Ball
```

The `return Ball` at the end is critical. Without it, `require()` returns `true` (a truthy value indicating the file loaded), not your table. You will stare at "attempt to index a boolean value" errors until you add the return.

### JS/Python Comparison

| Concept | JavaScript | Python | Lua |
|---|---|---|---|
| Import | `import Ball from './ball'` | `from ball import Ball` | `local Ball = require("ball")` |
| Export | `export default Ball` | just define it | `return Ball` |
| Path separator | `/` | `.` | `.` |
| Cached? | Yes | Yes | Yes |
| Re-run on each import? | No | No | No |

### Circular Dependencies

If `a.lua` requires `b.lua` and `b.lua` requires `a.lua`, you hit a circular dependency. Lua handles this differently from Python -- the second `require()` returns whatever was cached so far (an incomplete table), which usually means `nil` fields and confusing bugs.

**Fix:** Break the cycle. If two modules need each other, introduce a third module they both depend on, or pass references through function arguments instead of requiring at file scope.

```lua
-- BAD: circular dependency
-- states/play.lua
local GameOverState = require("states.gameover")  -- gameover requires play... boom

-- GOOD: lazy require
-- states/play.lua
local GameOverState  -- declare, don't require

function PlayState:init()
    GameOverState = require("states.gameover")  -- safe: called after both files are loaded
end
```

This lazy-require pattern is idiomatic in LOVE games. You will see it everywhere.

---

## 9. Entity Organization

Once your state manages the screen, you need a pattern for managing the *things* on that screen -- balls, paddles, enemies, bullets, particles.

### The Entity List Pattern

```lua
function PlayState:enter()
    self.entities = {}
    table.insert(self.entities, Ball.new(400, 300))
    table.insert(self.entities, Paddle.new(50, 250))
    table.insert(self.entities, Paddle.new(740, 250))
end

function PlayState:update(dt)
    for _, entity in ipairs(self.entities) do
        entity:update(dt)
    end

    -- remove dead entities (iterate backwards to avoid index shifting)
    for i = #self.entities, 1, -1 do
        if self.entities[i].dead then
            table.remove(self.entities, i)
        end
    end
end

function PlayState:draw()
    for _, entity in ipairs(self.entities) do
        entity:draw()
    end
end
```

**Spawning:** `table.insert(self.entities, Enemy.new(x, y))` -- done. The update/draw loops pick it up automatically.

**Destroying:** Set `entity.dead = true`. The cleanup loop handles removal. Never remove from a list while iterating forward -- you will skip elements.

**Why iterate backwards for removal?** When you `table.remove(t, 3)`, element 4 becomes element 3. If you are iterating forward and just processed index 3, you increment to 4 -- but what *was* 4 is now 3, and you skip it. Iterating backwards avoids this: removing index 5 does not affect indices 1-4.

### Entity-as-Table Pattern

If you are not using OOP (and you do not need to in Lua), entities are just tables with an agreed-upon interface:

```lua
-- entities/paddle.lua
local Paddle = {}

function Paddle.new(x, y)
    local self = {
        x = x, y = y,
        width = 10, height = 80,
        speed = 300,
        dead = false,
    }

    function self:update(dt)
        -- movement logic
    end

    function self:draw()
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end

    return self
end

return Paddle
```

This is a closure-based "class." Each call to `Paddle.new()` creates a fresh table with its own `update` and `draw` functions. It is not memory-efficient for thousands of entities, but for Pong paddles it is perfect and dead simple.

---

## 10. Separating Config

### conf.lua

LOVE looks for `conf.lua` before anything else. It configures the window and engine:

```lua
-- conf.lua
function love.conf(t)
    t.window.title = "Pong"
    t.window.width = 800
    t.window.height = 600
    t.window.vsync = 1

    -- disable modules you don't use (faster startup)
    t.modules.joystick = false
    t.modules.physics = false
end
```

This file runs before `love.load()`. You cannot use `love.graphics` here -- the window does not exist yet.

### Constants File

```lua
-- constants.lua
local C = {
    WINDOW_WIDTH = 800,
    WINDOW_HEIGHT = 600,
    PADDLE_SPEED = 300,
    PADDLE_WIDTH = 10,
    PADDLE_HEIGHT = 80,
    BALL_RADIUS = 10,
    BALL_SPEED = 250,
    WINNING_SCORE = 5,

    COLORS = {
        BACKGROUND = {0.1, 0.1, 0.15},
        PADDLE = {1, 1, 1},
        BALL = {1, 0.8, 0},
    },
}

return C
```

Usage:

```lua
local C = require("constants")

function Paddle.new(x, y)
    return {
        x = x, y = y,
        width = C.PADDLE_WIDTH,
        height = C.PADDLE_HEIGHT,
        speed = C.PADDLE_SPEED,
    }
end
```

No magic numbers. Change `PADDLE_SPEED` in one place, it updates everywhere.

---

## Code Walkthrough: 3-State Pong

Let's build a complete Pong game with title, play, and game-over states -- first manually, then with `hump.gamestate`.

### Manual State Tables Version

```lua
-- main.lua
SM = require("statemanager")    -- global so states can access it
local TitleState = require("states.title")

function love.load()
    love.graphics.setFont(love.graphics.newFont(24))
    SM.switch(TitleState)
end

function love.update(dt)
    SM.update(dt)
end

function love.draw()
    SM.draw()
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    SM.keypressed(key)
end
```

```lua
-- statemanager.lua
local SM = {}
local current = nil

function SM.switch(state, ...)
    if current and current.exit then current:exit() end
    current = state
    if current and current.enter then current:enter(...) end
end

function SM.update(dt)
    if current and current.update then current:update(dt) end
end

function SM.draw()
    if current and current.draw then current:draw() end
end

function SM.keypressed(key)
    if current and current.keypressed then current:keypressed(key) end
end

return SM
```

```lua
-- states/title.lua
local TitleState = {}
local PlayState

function TitleState:enter()
    PlayState = require("states.play")
end

function TitleState:draw()
    love.graphics.printf("PONG", 0, 200, 800, "center")
    love.graphics.printf("Press Enter to Play", 0, 300, 800, "center")
end

function TitleState:keypressed(key)
    if key == "return" then
        SM.switch(PlayState)
    end
end

return TitleState
```

```lua
-- states/play.lua
local C = require("constants")
local PlayState = {}
local GameOverState

function PlayState:enter()
    GameOverState = require("states.gameover")

    self.ball = { x = 400, y = 300, dx = C.BALL_SPEED, dy = C.BALL_SPEED * 0.75 }
    self.p1 = { x = 50, y = 260, score = 0 }
    self.p2 = { x = 740, y = 260, score = 0 }
end

function PlayState:update(dt)
    -- ball movement
    self.ball.x = self.ball.x + self.ball.dx * dt
    self.ball.y = self.ball.y + self.ball.dy * dt

    -- wall bounce
    if self.ball.y < 0 or self.ball.y > C.WINDOW_HEIGHT then
        self.ball.dy = -self.ball.dy
    end

    -- paddle movement
    if love.keyboard.isDown("w") then
        self.p1.y = self.p1.y - C.PADDLE_SPEED * dt
    end
    if love.keyboard.isDown("s") then
        self.p1.y = self.p1.y + C.PADDLE_SPEED * dt
    end
    if love.keyboard.isDown("up") then
        self.p2.y = self.p2.y - C.PADDLE_SPEED * dt
    end
    if love.keyboard.isDown("down") then
        self.p2.y = self.p2.y + C.PADDLE_SPEED * dt
    end

    -- scoring
    if self.ball.x < 0 then
        self.p2.score = self.p2.score + 1
        self:resetBall()
    elseif self.ball.x > C.WINDOW_WIDTH then
        self.p1.score = self.p1.score + 1
        self:resetBall()
    end

    -- win condition
    if self.p1.score >= C.WINNING_SCORE then
        SM.switch(GameOverState, "Player 1")
    elseif self.p2.score >= C.WINNING_SCORE then
        SM.switch(GameOverState, "Player 2")
    end
end

function PlayState:resetBall()
    self.ball.x = 400
    self.ball.y = 300
    self.ball.dx = -self.ball.dx
end

function PlayState:draw()
    -- paddles
    love.graphics.rectangle("fill", self.p1.x, self.p1.y, C.PADDLE_WIDTH, C.PADDLE_HEIGHT)
    love.graphics.rectangle("fill", self.p2.x, self.p2.y, C.PADDLE_WIDTH, C.PADDLE_HEIGHT)
    -- ball
    love.graphics.circle("fill", self.ball.x, self.ball.y, C.BALL_RADIUS)
    -- scores
    love.graphics.print(self.p1.score, 350, 20)
    love.graphics.print(self.p2.score, 430, 20)
end

return PlayState
```

```lua
-- states/gameover.lua
local GameOverState = {}
local TitleState

function GameOverState:enter(winner)
    TitleState = require("states.title")
    self.winner = winner or "Nobody"
end

function GameOverState:draw()
    love.graphics.printf(self.winner .. " Wins!", 0, 200, 800, "center")
    love.graphics.printf("Press Enter to Continue", 0, 300, 800, "center")
end

function GameOverState:keypressed(key)
    if key == "return" then
        SM.switch(TitleState)
    end
end

return GameOverState
```

### hump.gamestate Version

The states are almost identical. The differences:

```lua
-- main.lua (hump version)
local Gamestate = require("lib.hump.gamestate")
local TitleState = require("states.title")

function love.load()
    love.graphics.setFont(love.graphics.newFont(24))
    Gamestate.registerEvents()
    Gamestate.switch(TitleState)
end

-- That's it. No love.update, no love.draw, no love.keypressed.
-- registerEvents() handles all delegation.
```

```lua
-- states/title.lua (hump version)
local Gamestate = require("lib.hump.gamestate")
local TitleState = {}
local PlayState

function TitleState:init()
    -- called once, ever
    PlayState = require("states.play")
end

function TitleState:draw()
    love.graphics.printf("PONG", 0, 200, 800, "center")
    love.graphics.printf("Press Enter to Play", 0, 300, 800, "center")
end

function TitleState:keypressed(key)
    if key == "return" then
        Gamestate.switch(PlayState)
    end
end

return TitleState
```

```lua
-- states/gameover.lua (hump version)
local Gamestate = require("lib.hump.gamestate")
local GameOverState = {}
local TitleState

function GameOverState:init()
    TitleState = require("states.title")
end

function GameOverState:enter(previous, winner)
    --                     ^ hump injects the previous state as first arg
    self.winner = winner or "Nobody"
end

function GameOverState:draw()
    love.graphics.printf(self.winner .. " Wins!", 0, 200, 800, "center")
    love.graphics.printf("Press Enter to Continue", 0, 300, 800, "center")
end

function GameOverState:keypressed(key)
    if key == "return" then
        Gamestate.switch(TitleState)
    end
end

return GameOverState
```

The `play.lua` state for hump is the same as the manual version, except you replace `SM.switch(...)` with `Gamestate.switch(...)` and add `previous` as the first param in `enter()`.

---

## API Reference

### DIY State Manager

| Function | Description |
|---|---|
| `SM.switch(state, ...)` | Exit current state, enter new state. Extra args passed to `enter()`. |
| `SM.update(dt)` | Forward `dt` to current state's `update()`. |
| `SM.draw()` | Forward to current state's `draw()`. |
| `SM.keypressed(key)` | Forward to current state's `keypressed()`. |

### hump.gamestate

| Function | Description |
|---|---|
| `Gamestate.registerEvents()` | Hook into all LOVE callbacks automatically. Call once in `love.load()`. |
| `Gamestate.switch(state, ...)` | Replace current state. Calls `exit()` then `enter(previous, ...)`. |
| `Gamestate.push(state, ...)` | Stack new state on top. Calls `pause()` on old, `enter()` on new. |
| `Gamestate.pop(...)` | Remove top state. Calls `exit()` on top, `resume(...)` on state below. |
| `Gamestate.current()` | Returns the currently active state table. |

### State Lifecycle (hump)

| Callback | When Called | Typical Use |
|---|---|---|
| `init()` | Once, first time the state is ever entered | Load assets, lazy-require other states |
| `enter(previous, ...)` | Every time you switch/push to this state | Reset game data, start music |
| `leave()` | Every time you switch/push away from this state | Stop music, save progress |
| `resume(...)` | When a state pushed on top of this one is popped | Unpause, restore input |
| `pause()` | When another state is pushed on top | Pause timers |
| `update(dt)` | Every frame while active | Game logic |
| `draw()` | Every frame while active | Rendering |

---

## Common Pitfalls

**1. Forgetting `return` at the end of a module file.**
You write a beautiful state table, `require()` it, and get `true` instead of your table. Every Lua module must end with `return YourTable`. No return = no table. You will see "attempt to call a boolean value" or "attempt to index a boolean value."

**2. The `previous` parameter in hump's `enter()`.**
`hump.gamestate` injects the previous state as the first argument to `enter()`. If you write `function MyState:enter(score)`, then `score` is actually the previous state object, not the number you passed. Write `function MyState:enter(previous, score)` instead.

**3. Modifying entity lists while iterating forward.**
You loop through your entities with `for i = 1, #entities do` and call `table.remove` inside the loop. This shifts indices and you skip entities. Always iterate backwards for removal, or collect indices to remove and batch-remove after the loop.

**4. Circular requires at file scope.**
`play.lua` requires `gameover.lua` which requires `play.lua`. Lua returns a half-built table and you get `nil` fields. Use the lazy-require pattern: declare the variable at file scope, assign it inside `init()` or `enter()`.

**5. Not resetting state in `enter()`.**
You switch to `PlayState`, play a round, switch to `GameOverState`, then switch back to `PlayState`. If `enter()` does not reinitialize the ball and scores, you resume mid-game with stale data. Every `enter()` should set the state to a known-good starting condition.

**6. Forgetting to clean up in `exit()`.**
You start a looping background track in `enter()`. You switch states. The music keeps playing over the new state. Any persistent side-effect (audio, timers, global event listeners) created in `enter()` must be undone in `exit()` (or `leave()` in hump).

---

## Exercises

### Exercise 1: Three-State Pong
**Time:** 60-90 minutes

Build the 3-state Pong game from the walkthrough above. Use whichever approach you prefer (DIY or hump). Requirements:
1. Title screen with game name and "Press Enter" prompt.
2. Play state with two paddles, a ball, and scoring.
3. Game-over state showing the winner and "Press Enter to Restart."
4. Pressing Enter on the game-over screen returns to the title, not directly to play.

**Stretch:** Add a 3-second countdown state between title and play. The countdown state shows "3... 2... 1... GO!" then switches to the play state.

---

### Exercise 2: Pause with Push/Pop
**Time:** 30-45 minutes

Add a pause screen to your Pong game using `Gamestate.push()` / `Gamestate.pop()` (or build push/pop into your DIY manager). Requirements:
1. Pressing Escape during play pushes a PauseState.
2. PauseState draws a semi-transparent overlay on top of the frozen game.
3. PauseState shows "PAUSED" and "Press Escape to Resume."
4. Pressing Escape in PauseState pops back to PlayState with all game data intact.
5. The ball must NOT move while paused.

**Stretch:** Add a "Quit to Title" option in the pause menu (press Q). This should `switch()` to TitleState, not `pop()` -- because you are abandoning the game, not resuming it.

---

### Exercise 3: Settings State
**Time:** 45-60 minutes

Add a Settings state accessible from the title screen. Requirements:
1. Title screen shows "Press S for Settings."
2. Settings state lets you change ball speed (slow / medium / fast) using arrow keys.
3. The chosen setting is passed to PlayState via the `enter()` params.
4. Pressing Escape in Settings returns to the Title.
5. Settings are stored in a table, not global variables.

**Stretch:** Persist settings to a file using `love.filesystem.write()` and load them back on startup with `love.filesystem.read()`.

---

## Key Takeaways

- **A game state is a self-contained screen** with its own `enter()`, `update(dt)`, `draw()`, and `exit()` lifecycle. States do not know about each other's internals.

- **The if/else chain teaches the concept but does not scale.** Once you have more than 2-3 states, switch to state tables or a library.

- **State tables are just Lua tables with agreed-upon function keys.** The "manager" is 20 lines of delegation code. There is no magic.

- **`hump.gamestate` removes the boilerplate** and adds push/pop for state stacking. Use it unless you have a reason not to.

- **`enter()` is your reset point.** Every time you enter a state, set it to a clean starting condition. Stale data from previous visits is a top-3 bug source.

- **Lazy-require breaks circular dependencies.** Declare the variable at file scope, assign it in `init()` or `enter()`.

- **One file per state, one file per entity, constants in one place.** This is not premature abstraction -- it is the minimum structure that lets you stay sane past 500 lines of code.

- **`require()` caches.** The file runs once. Every subsequent `require()` returns the same table. This is a feature, not a bug.

---

## What's Next

You have screens. You have structure. You have entities that spawn and die.

Next up: [Module 3: Sprites & Animation](module-03-sprites-animation.md) -- where you will handle keyboard, mouse, and gamepad input cleanly, build rebindable controls, and learn why `love.keyboard.isDown()` and `love.keypressed()` serve different purposes.
