# Module 0: Setup & First Pixels

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 3--5 hours
**Prerequisites:** None

---

## Overview

This module has exactly one goal: get pixels on screen and feel something. You will install LOVE, write a `main.lua` file, drag a folder onto an executable, and see shapes and colors appear in a window you control. Along the way, you will pick up enough Lua to be dangerous and enough LOVE API to be delighted.

If you have written JavaScript or Python before, Lua will feel both familiar and mildly irritating. Arrays start at 1. Not-equal is `~=`. There is no `+=`. The only data structure is a table, and it does everything. This module calls out every gotcha so you stop tripping over them early.

By the end, you will have a working development workflow, a hand-built scene made of drawing primitives, and a mental model of how LOVE programs are structured. Nothing here is difficult. Everything here is necessary.

---

## 1. Installing LOVE

LOVE (stylized LOEVE, pronounced "love") is a free, open-source framework for making 2D games in Lua. It is not an engine with an editor -- it is a runtime. You write Lua files, you point the LOVE executable at your project folder, and it runs your code. That simplicity is the point.

### macOS

Download the `.dmg` from [love2d.org](https://love2d.org). Drag `love.app` into `/Applications`.

To run LOVE from the terminal (which you will want to do constantly), add it to your PATH. Open `~/.zshrc` (or `~/.bash_profile` if you are still on bash) and add:

```bash
alias love="/Applications/love.app/Contents/MacOS/love"
```

Reload your shell with `source ~/.zshrc`. Now you can run `love .` from any project directory.

**Test it:** Open a terminal and type `love --version`. You should see something like `LOVE 11.5`.

### Windows

Download the installer or zip from [love2d.org](https://love2d.org). If you use the zip, extract it somewhere permanent like `C:\Program Files\LOVE`.

Add the LOVE directory to your system PATH:
1. Open System Properties, then Environment Variables
2. Under "System variables," find `Path` and click Edit
3. Add the directory containing `love.exe`

Now you can open PowerShell or cmd and type `love --version`.

**Drag-and-drop workflow:** On Windows, you can also drag your project folder directly onto `love.exe`. This is the fastest way to test when you are just starting out.

### Linux

Most distributions have LOVE in their package manager:

```bash
# Ubuntu / Debian
sudo apt install love

# Arch
sudo pacman -S love

# Fedora
sudo dnf install love
```

Run `love --version` to confirm. If your distro packages an older version, grab the AppImage from [love2d.org](https://love2d.org) instead.

### Verifying Your Installation

Create an empty directory somewhere. Open a terminal in that directory and run:

```bash
love .
```

You should see a short error screen with the LOVE logo and a message saying "No code to run." That error screen is itself a LOVE program, which means your installation works. Close the window.

---

## 2. Your First main.lua

LOVE looks for a file called `main.lua` in whatever directory you point it at. That file is your entire program. Create a new folder called `hello-love`, and inside it, create `main.lua`:

```lua
function love.draw()
    love.graphics.print("Hello, pixels!", 100, 100)
end
```

Run it:

```bash
love hello-love
```

A window appears with "Hello, pixels!" drawn at coordinates (100, 100). That is the entire program. No boilerplate, no imports, no build step.

**What just happened:** LOVE calls `love.draw()` every single frame (typically 60 times per second). Whatever drawing commands you put inside that function appear on screen. You did not need to define `love.load()` or `love.update()` -- LOVE only calls the callbacks you define. If a callback does not exist, LOVE skips it.

**The three callbacks you will use most:**

```lua
function love.load()
    -- runs once at startup
    -- use this to load images, sounds, set up initial state
end

function love.update(dt)
    -- runs every frame before drawing
    -- dt = time in seconds since last frame (usually ~0.016)
    -- use this for game logic, movement, physics
end

function love.draw()
    -- runs every frame after update
    -- use this for all rendering
    -- drawing order matters: last drawn = on top
end
```

Here is a slightly more complete first program:

```lua
function love.load()
    x = 400
    y = 300
    speed = 200
end

function love.update(dt)
    if love.keyboard.isDown("right") then
        x = x + speed * dt
    end
    if love.keyboard.isDown("left") then
        x = x - speed * dt
    end
end

function love.draw()
    love.graphics.circle("fill", x, y, 20)
end
```

Run this. You have a white circle that moves left and right with the arrow keys. You just made an interactive program in 17 lines with zero dependencies.

---

## 3. The LOVE Coordinate System

LOVE uses a **screen-space coordinate system** where:

- **(0, 0) is the top-left corner** of the window
- **X increases to the right**
- **Y increases downward**

```
(0,0) ───────────► X (800)
  │
  │
  │     (400, 300) = center of default 800x600 window
  │
  ▼
  Y (600)
```

This is identical to HTML Canvas and most 2D frameworks. If you have done any web canvas work, you already know this. If you are coming from math or physics, the inverted Y-axis will feel wrong for about a day, then it will feel normal forever.

**The default window is 800x600 pixels.** You can change this in `conf.lua` (covered later) or at runtime with `love.window.setMode(width, height)`.

**Key insight:** Every drawing function takes pixel coordinates. `love.graphics.rectangle("fill", 10, 20, 100, 50)` draws a filled rectangle whose **top-left corner** is at (10, 20), with a width of 100 and a height of 50. The position parameter is always the top-left corner for rectangles and the center for circles.

---

## 4. Drawing Primitives

LOVE gives you a small, powerful set of drawing functions. Every one of these goes inside `love.draw()`.

### Rectangles

```lua
-- love.graphics.rectangle(mode, x, y, width, height)
love.graphics.rectangle("fill", 50, 50, 200, 100)   -- solid
love.graphics.rectangle("line", 50, 50, 200, 100)   -- outline only

-- rounded corners (rx, ry = corner radius)
love.graphics.rectangle("fill", 50, 200, 200, 100, 15, 15)
```

The **mode** parameter is either `"fill"` (solid) or `"line"` (outline). This pattern repeats across all shape functions.

### Circles

```lua
-- love.graphics.circle(mode, x, y, radius)
love.graphics.circle("fill", 400, 300, 50)     -- solid circle at center
love.graphics.circle("line", 400, 300, 80)     -- outline circle

-- optional: segments parameter controls smoothness
love.graphics.circle("fill", 400, 300, 50, 6)  -- hexagon!
```

The position (x, y) for circles is the **center**, not the top-left. This catches people who switch between rectangles and circles without thinking.

### Lines

```lua
-- love.graphics.line(x1, y1, x2, y2, ...)
love.graphics.line(0, 0, 800, 600)              -- diagonal across window
love.graphics.line(100, 100, 200, 100, 200, 200) -- two connected segments

-- set line width
love.graphics.setLineWidth(3)
love.graphics.line(50, 50, 750, 50)
```

You can pass as many coordinate pairs as you want to `love.graphics.line` -- it draws connected segments through all of them.

### Polygons

```lua
-- love.graphics.polygon(mode, x1, y1, x2, y2, x3, y3, ...)
-- triangle
love.graphics.polygon("fill", 400, 100, 350, 200, 450, 200)

-- pentagon (you specify each vertex)
love.graphics.polygon("line", 400, 50, 475, 100, 450, 180, 350, 180, 325, 100)
```

Polygons require at least three vertices (six numbers). LOVE automatically closes the polygon by connecting the last vertex back to the first.

### Points

```lua
love.graphics.points(100, 100, 200, 200, 300, 300)
```

Rarely used for gameplay, but handy for debugging and particle-like effects.

---

## 5. Colors

By default, everything draws in white on a black background. You change the drawing color with `love.graphics.setColor()`.

```lua
-- love.graphics.setColor(red, green, blue, alpha)
-- ALL values are 0 to 1, NOT 0 to 255

love.graphics.setColor(1, 0, 0)          -- pure red
love.graphics.setColor(0, 0.5, 1)        -- sky blue
love.graphics.setColor(1, 1, 1, 0.5)     -- white at 50% opacity
```

**Critical gotcha:** LOVE uses **0--1 range**, not 0--255. If you are coming from CSS or most image editors, divide your values by 255. `rgb(255, 128, 0)` in CSS becomes `love.graphics.setColor(1, 0.5, 0)` in LOVE.

**`setColor` is stateful.** Once you set a color, everything after it draws in that color until you set a different one. This is a common source of bugs: you set something to red, forget to reset it, and suddenly your text, your sprites, and your background are all tinted red.

```lua
function love.draw()
    -- red rectangle
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 50, 50, 100, 100)

    -- green circle
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", 300, 100, 50)

    -- reset to white before drawing anything else
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: 0", 10, 10)
end
```

**Pro tip:** Always reset to white `(1, 1, 1, 1)` at the end of your draw function, or before drawing sprites/text. Sprites and text are "tinted" by the current color, so a sprite drawn with `setColor(1, 0, 0)` active will appear entirely red-tinted.

### Background Color

```lua
function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)  -- dark blue background
end
```

This only needs to be called once (usually in `love.load`). LOVE clears the screen to this color every frame before calling `love.draw()`.

---

## 6. Text and Fonts

### Basic Text

```lua
-- love.graphics.print(text, x, y)
love.graphics.print("Score: 42", 10, 10)

-- with rotation, scale, offset
love.graphics.print("Rotated!", 400, 300, math.rad(45))
```

The default font is small (12px). For games, you almost always want a custom font.

### Custom Fonts

```lua
function love.load()
    -- built-in font at a larger size
    bigFont = love.graphics.newFont(32)

    -- or load a .ttf file
    -- pixelFont = love.graphics.newFont("fonts/press-start.ttf", 16)
end

function love.draw()
    love.graphics.setFont(bigFont)
    love.graphics.print("BIG TEXT", 100, 100)
end
```

**`setFont` is stateful**, just like `setColor`. If you set a font and never change it back, everything uses that font. In practice, you will create your fonts in `love.load()` and swap between them as needed in `love.draw()`.

### Formatted / Wrapped Text

```lua
-- love.graphics.printf(text, x, y, wraplimit, align)
love.graphics.printf("This is centered text that wraps.", 0, 200, 800, "center")
love.graphics.printf("Right-aligned.", 0, 250, 800, "right")
```

`printf` wraps text at `wraplimit` pixels and supports `"left"`, `"center"`, and `"right"` alignment. Extremely useful for UI and dialogue.

### Measuring Text

```lua
local font = love.graphics.getFont()
local textWidth = font:getWidth("Hello")
local textHeight = font:getHeight()
```

You will need this when centering text manually or building UI elements.

---

## 7. Lua for JS/Python Developers

Lua is small by design. The entire language specification fits in about 30 pages. If you know JavaScript or Python, you already understand 80% of Lua. This section covers the 20% that will trip you up.

### Tables Are Everything

Lua has **one data structure: the table**. Tables are arrays, dictionaries, objects, modules, and namespaces all at once.

```lua
-- as an array (1-indexed!)
local fruits = {"apple", "banana", "cherry"}
print(fruits[1])   -- "apple" (NOT fruits[0])
print(#fruits)     -- 3 (# is the length operator)

-- as a dictionary / object
local player = {
    name = "Hero",
    x = 100,
    y = 200,
    hp = 100,
}

print(player.name)      -- "Hero"
print(player["name"])   -- also "Hero" (dot notation is sugar)

-- mixed: a table can be both at the same time
local weird = {10, 20, 30, name = "test"}
print(weird[1])     -- 10
print(weird.name)   -- "test"
```

### 1-Indexed Arrays

This is the big one. Lua arrays start at index **1**, not 0. Every standard library function, the `#` length operator, `ipairs` -- everything assumes 1-based indexing.

```lua
local colors = {"red", "green", "blue"}
-- colors[0] is nil (not an error, just empty)
-- colors[1] is "red"
-- colors[3] is "blue"
-- #colors is 3

for i, color in ipairs(colors) do
    print(i, color)   -- 1 red, 2 green, 3 blue
end
```

**You will forget this and write `colors[0]` at least once.** When your loop skips the first element or returns `nil` unexpectedly, check your indexing.

### Operators That Differ

| Concept | JavaScript | Python | Lua |
|---------|-----------|--------|-----|
| Not equal | `!==` | `!=` | `~=` |
| Boolean AND | `&&` | `and` | `and` |
| Boolean OR | `\|\|` | `or` | `or` |
| Boolean NOT | `!` | `not` | `not` |
| String concat | `+` | `+` | `..` |
| Exponent | `**` | `**` | `^` |
| Integer division | `Math.floor(a/b)` | `//` | `math.floor(a/b)` |
| Modulo | `%` | `%` | `%` |
| Increment | `x++` or `x += 1` | `x += 1` | `x = x + 1` |

There is **no `+=`, `-=`, `++`, or `--`** in Lua. You write `x = x + 1` every time. This gets tedious fast, but there is no shortcut.

**String concatenation uses `..`**, not `+`. This matters because `"score: " + 10` is a type error in Lua, while `"score: " .. 10` works and produces `"score: 10"`.

### Local vs. Global

**Variables in Lua are global by default.** If you write `x = 10` at the top of a file without the `local` keyword, `x` is a global that any file can access (and accidentally overwrite).

```lua
x = 10            -- GLOBAL: visible everywhere, dangerous
local x = 10      -- LOCAL: scoped to this block/file, safe

function love.load()
    speed = 200          -- global (bad habit)
    local speed = 200    -- local to love.load (good habit)
end
```

**Rule of thumb: always use `local` unless you have a specific reason not to.** Globals are a breeding ground for subtle bugs, especially in larger projects where two files both define a global called `timer`.

### Truthiness

Lua's truthiness rules are simpler than JavaScript but different from Python:

- **`false` and `nil` are falsy.** Everything else is truthy.
- **`0` is truthy.** (This will get you if you come from C/Python.)
- **`""` (empty string) is truthy.** (Same surprise if you come from Python/JS.)

```lua
if 0 then print("0 is truthy in Lua!") end         -- prints
if "" then print("empty string is truthy!") end     -- prints
if nil then print("this won't print") end           -- does not print
if false then print("this won't print") end         -- does not print
```

### The `and`/`or` Idiom

Lua's `and` and `or` return values (not just booleans), so they work like ternary expressions:

```lua
-- Lua idiom for default values (like ?? in JS or `or` in Python)
local name = username or "Anonymous"

-- Lua idiom for ternary (like condition ? a : b in JS)
local status = (hp > 0) and "alive" or "dead"
```

**Warning:** The ternary idiom `a and b or c` breaks if `b` is `false` or `nil`. In that case, use an `if/else` block.

### Iterating Tables

```lua
-- ipairs: iterate array part in order (1, 2, 3, ...)
local items = {"sword", "shield", "potion"}
for i, item in ipairs(items) do
    print(i, item)
end

-- pairs: iterate all keys (unordered)
local stats = {hp = 100, mp = 50, str = 12}
for key, value in pairs(stats) do
    print(key, value)   -- order not guaranteed
end
```

Use **`ipairs`** for arrays (numeric keys in order). Use **`pairs`** for dictionaries (all keys, no guaranteed order).

### Functions

```lua
-- named function
local function greet(name)
    return "Hello, " .. name
end

-- anonymous function (common for callbacks)
love.keypressed = function(key)
    if key == "escape" then
        love.event.quit()
    end
end

-- multiple return values (a real Lua feature, not a hack)
local function getPosition()
    return 100, 200
end

local x, y = getPosition()
```

### Metatables (Preview)

You do not need metatables yet, but you will see them soon. Metatables let you define custom behavior for tables -- operator overloading, inheritance, custom indexing. They are how Lua implements object-oriented patterns without a class keyword.

```lua
-- you will see patterns like this in LOVE libraries:
local Entity = {}
Entity.__index = Entity

function Entity.new(x, y)
    local self = setmetatable({}, Entity)
    self.x = x
    self.y = y
    return self
end

function Entity:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end
```

The colon syntax `Entity:move(dx, dy)` is sugar for `Entity.move(self, dx, dy)`. It implicitly passes the table as the first argument. You will encounter this everywhere.

Do not worry about mastering metatables now. Just know they exist and that the colon `:` means "method call with implicit self."

---

## 8. Project Structure

### The Minimal Project

```
my-game/
  main.lua          -- your game code
```

That is a valid LOVE project. One file, one folder.

### The Recommended Structure

As your project grows, organize it:

```
my-game/
  main.lua          -- entry point: load, update, draw
  conf.lua          -- window settings, modules to enable
  entities/
    player.lua
    enemy.lua
  lib/
    -- third-party libraries
  assets/
    images/
    sounds/
    fonts/
```

### conf.lua

`conf.lua` runs **before** `main.lua` and lets you configure the window and engine. LOVE looks for it automatically in the same directory.

```lua
function love.conf(t)
    t.window.title = "My First Game"
    t.window.width = 1280
    t.window.height = 720

    -- disable modules you don't need (slightly faster startup)
    t.modules.joystick = false
    t.modules.physics = false
end
```

Common `conf.lua` settings:

| Setting | Default | What It Does |
|---------|---------|-------------|
| `t.window.width` | 800 | Window width in pixels |
| `t.window.height` | 600 | Window height in pixels |
| `t.window.title` | "Untitled" | Window title bar text |
| `t.window.vsync` | 1 | V-sync mode (1 = on, 0 = off) |
| `t.window.resizable` | false | Whether the user can resize the window |
| `t.window.fullscreen` | false | Start in fullscreen |
| `t.console` | false | (Windows) Open a console window for print output |

---

## 9. Development Workflow

### The Edit-Save-Rerun Loop

Your workflow is:

1. **Edit** `main.lua` in your text editor (VS Code, Sublime, Neovim, whatever)
2. **Save** the file
3. **Rerun** LOVE: close the window and run `love .` again (or press Ctrl/Cmd+Q, then up-arrow + Enter in your terminal)

There is no hot-reload by default. You close and reopen. This sounds tedious, but LOVE starts in under a second, so the loop is fast.

**Tip:** Some editors have LOVE extensions that bind a key to relaunch. In VS Code, look for the "Love2D Support" extension. You can also set up a simple script or Makefile:

```bash
# run.sh
#!/bin/bash
love .
```

### The Error Screen

When your code has an error, LOVE shows a **blue error screen** with a stack trace. This screen is your best friend. It tells you:

- The file and line number where the error occurred
- The error message (usually clear and actionable)
- A stack trace showing how the code got there

```
Error: main.lua:12: attempt to index a nil value (global 'player')
```

This means on line 12 of `main.lua`, you tried to access a property of `player`, but `player` is `nil`. Common causes: typo in variable name, forgot to initialize in `love.load()`, or a scoping issue with `local`.

**Read the error screen carefully.** The answer is almost always in the first two lines. If you see "attempt to call a nil value," you are calling a function that does not exist (check your spelling). If you see "attempt to perform arithmetic on a nil value," a variable you expected to be a number is `nil` (check initialization).

### print() Debugging

Lua's `print()` outputs to the terminal (not the game window). Use it liberally:

```lua
function love.update(dt)
    print("x:", player.x, "y:", player.y)
end
```

On macOS/Linux, output appears in the terminal where you ran `love .`. On Windows, you need `t.console = true` in `conf.lua` to see print output, or run LOVE from a command prompt.

---

## Code Walkthrough: Building a Scene

Let's build a complete scene -- a night sky with a moon, stars, ground, and a house. This exercises every drawing concept from this module.

```lua
function love.load()
    love.window.setTitle("Night Scene")
    love.graphics.setBackgroundColor(0.05, 0.05, 0.15)  -- dark night sky

    -- generate random star positions once
    stars = {}
    for i = 1, 80 do
        stars[i] = {
            x = love.math.random(0, 800),
            y = love.math.random(0, 350),
            size = love.math.random() * 2 + 1,  -- 1 to 3
        }
    end
end

function love.update(dt)
    -- nothing to update yet (no interactivity in this scene)
end

function love.draw()
    -- stars
    love.graphics.setColor(1, 1, 0.8, 0.8)
    for _, star in ipairs(stars) do
        love.graphics.circle("fill", star.x, star.y, star.size)
    end

    -- moon
    love.graphics.setColor(1, 1, 0.85)
    love.graphics.circle("fill", 650, 80, 45)
    -- moon shadow (dark circle overlapping to create crescent)
    love.graphics.setColor(0.05, 0.05, 0.15)
    love.graphics.circle("fill", 670, 70, 40)

    -- ground
    love.graphics.setColor(0.1, 0.3, 0.1)
    love.graphics.rectangle("fill", 0, 450, 800, 150)

    -- house body
    love.graphics.setColor(0.6, 0.3, 0.15)
    love.graphics.rectangle("fill", 200, 350, 180, 100)

    -- roof (triangle)
    love.graphics.setColor(0.5, 0.1, 0.1)
    love.graphics.polygon("fill", 190, 350, 290, 270, 390, 350)

    -- door
    love.graphics.setColor(0.35, 0.2, 0.1)
    love.graphics.rectangle("fill", 270, 390, 30, 60)

    -- window (with warm glow)
    love.graphics.setColor(1, 0.9, 0.4, 0.9)
    love.graphics.rectangle("fill", 220, 375, 30, 30)

    -- window panes (cross)
    love.graphics.setColor(0.35, 0.2, 0.1)
    love.graphics.setLineWidth(2)
    love.graphics.line(235, 375, 235, 405)  -- vertical
    love.graphics.line(220, 390, 250, 390)  -- horizontal

    -- ground line (subtle)
    love.graphics.setColor(0.08, 0.25, 0.08)
    love.graphics.setLineWidth(3)
    love.graphics.line(0, 450, 800, 450)

    -- title text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("A Quiet Night", 0, 560, 800, "center")
end
```

**What this demonstrates:**

- `love.load()` for one-time setup and random generation
- `setBackgroundColor` for scene atmosphere
- Tables as arrays of objects (`stars`)
- `ipairs` for iterating an array
- Layered drawing (background to foreground, order matters)
- The crescent moon trick: two overlapping circles
- Polygons for the roof triangle
- `setColor` state management throughout `draw()`
- `printf` for centered text
- `setLineWidth` for thicker lines

Copy this code, run it, then **modify it**. Change the colors. Move the house. Add another window. Add a tree (a brown rectangle trunk with a green circle canopy). The best way to learn drawing primitives is to play with them immediately.

---

## API Quick Reference

| Function | Description | Example |
|----------|-------------|---------|
| `love.graphics.rectangle(mode, x, y, w, h)` | Draw a rectangle | `("fill", 10, 10, 100, 50)` |
| `love.graphics.circle(mode, x, y, r)` | Draw a circle | `("fill", 400, 300, 25)` |
| `love.graphics.line(x1, y1, x2, y2, ...)` | Draw connected line segments | `(0, 0, 100, 100)` |
| `love.graphics.polygon(mode, ...)` | Draw a polygon from vertices | `("fill", 0, 0, 50, 0, 25, 50)` |
| `love.graphics.points(...)` | Draw individual points | `(10, 10, 20, 20)` |
| `love.graphics.print(text, x, y)` | Draw text at position | `("Hello", 10, 10)` |
| `love.graphics.printf(text, x, y, limit, align)` | Draw wrapped/aligned text | `("Hi", 0, 10, 800, "center")` |
| `love.graphics.setColor(r, g, b, a)` | Set draw color (0--1 range) | `(1, 0, 0)` for red |
| `love.graphics.setBackgroundColor(r, g, b)` | Set clear color | `(0.1, 0.1, 0.2)` |
| `love.graphics.setFont(font)` | Set active font | `(myFont)` |
| `love.graphics.newFont(size)` | Create font at pixel size | `(24)` |
| `love.graphics.setLineWidth(w)` | Set line thickness | `(3)` |
| `love.window.setTitle(title)` | Set window title | `("My Game")` |
| `love.window.setMode(w, h, flags)` | Set window size/flags | `(1280, 720, {})` |
| `love.keyboard.isDown(key)` | Check if key is held | `("space")` |

---

## Common Pitfalls

### 1. Color values 0--255 instead of 0--1

```lua
-- WRONG: invisible or white-clamped
love.graphics.setColor(255, 0, 0)

-- RIGHT
love.graphics.setColor(1, 0, 0)
```

LOVE 11+ uses 0--1 floats. Older tutorials and LOVE 0.10.x code use 0--255. If colors look wrong, this is almost certainly the cause.

### 2. Forgetting to reset color

```lua
function love.draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 10, 10, 50, 50)
    -- everything below is now red, including sprites and text
    love.graphics.print("This text is red!", 10, 80)
end
```

Fix: call `love.graphics.setColor(1, 1, 1)` before drawing anything that should not be tinted.

### 3. Lua 1-indexing off-by-one

```lua
local enemies = {"goblin", "orc", "dragon"}
print(enemies[0])  -- nil (not an error, just silently nil)
print(enemies[1])  -- "goblin"
```

If your loop produces `nil` for the first element, you are indexing from 0.

### 4. Missing `local` keyword

```lua
function love.load()
    score = 0  -- global! accessible everywhere, overwritable by accident
end

function love.load()
    local score = 0  -- local to love.load, invisible to love.draw
end
```

The second version creates a new problem: `score` is not accessible in `love.draw()`. For variables shared across callbacks, either use globals deliberately (common in small LOVE projects) or use a module table pattern.

### 5. Drawing outside love.draw()

```lua
function love.update(dt)
    love.graphics.circle("fill", 100, 100, 20)  -- does nothing visible
end
```

Drawing commands only produce visible results inside `love.draw()`. LOVE clears the screen each frame before calling `love.draw()`, so anything drawn during `love.update()` or `love.load()` is immediately erased.

### 6. String concatenation with + instead of ..

```lua
-- WRONG: type error or unexpected arithmetic
local msg = "Score: " + score

-- RIGHT
local msg = "Score: " .. score
```

Lua uses `..` for string concatenation. Using `+` will either error or silently try to convert the string to a number.

---

## Exercises

### Exercise 1: Color Palette Viewer

**Time:** 20--30 minutes

Draw a row of 8 colored rectangles across the screen, each a different color. Below each rectangle, print the RGB values as text. Make the rectangles evenly spaced using a loop.

**Stretch:** Make it two rows -- one row of solid colors, one row of the same colors at 50% opacity. This tests your understanding of `setColor` with alpha.

**Concepts practiced:** loops, setColor, rectangles, print, coordinate math.

---

### Exercise 2: Bullseye Target

**Time:** 20--30 minutes

Draw a bullseye target: 5 concentric circles, alternating between two colors. The outermost circle should be the largest. Draw from largest to smallest (otherwise the larger circles will cover the smaller ones).

**Hint:** A loop with decreasing radius and alternating colors. Remember that drawing order matters -- the last thing drawn is on top.

**Stretch:** Add a score label in the center using `printf` with center alignment. Calculate the position so the text sits exactly in the middle of the innermost circle.

**Concepts practiced:** circles, layered drawing order, loops, color alternation, text centering.

---

### Exercise 3: House Builder

**Time:** 30--45 minutes

Build on the night scene from the walkthrough. Add at least three of the following:

- A tree (rectangle trunk + circle or triangle canopy)
- A fence (repeated rectangles in a loop)
- A chimney with "smoke" (stacked semi-transparent circles rising upward)
- A second house with different proportions
- Stars that twinkle (vary their alpha using `love.timer.getTime()` and `math.sin`)

**Stretch (animated):** Make the smoke circles drift upward slowly using `love.update(dt)`. This previews Module 1's game loop concepts.

**Concepts practiced:** everything from this module, plus creative experimentation with the drawing API.

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [LOVE Wiki: Getting Started](https://love2d.org/wiki/Getting_Started) | Documentation | The official first steps, kept up to date |
| [LOVE Wiki: love.graphics](https://love2d.org/wiki/love.graphics) | Reference | Complete list of drawing functions with examples |
| [Programming in Lua (1st ed)](https://www.lua.org/pil/1.html) | Book (free online) | The Lua bible. Chapters 1--5 cover everything in this module and more |
| [Learn Lua in 15 Minutes](https://learnxinyminutes.com/docs/lua/) | Cheat sheet | Fast syntax overview for experienced programmers |
| [Sheepolution's How to LOVE](https://sheepolution.com/learn/book/bonus/vscode) | Tutorial series | Beginner-friendly LOVE tutorial with good explanations |

---

## Key Takeaways

1. **LOVE is a runtime, not an engine.** You write Lua files, point the executable at a folder, and your code runs. No editor, no IDE, no build step. This simplicity is a feature.

2. **Three callbacks drive everything.** `love.load()` runs once for setup. `love.update(dt)` runs every frame for logic. `love.draw()` runs every frame for rendering. Start with just `love.draw()` and add the others as you need them.

3. **Drawing is stateful.** `setColor`, `setFont`, and `setLineWidth` all change global state that persists until you change it again. Always reset to defaults after drawing styled elements, or you will spend 20 minutes debugging why your sprite is green.

4. **Lua is small but different.** 1-indexed arrays, `~=` for not-equal, `..` for string concatenation, no `+=`, tables for everything, `local` by default is your responsibility. These differences are few but they will bite you repeatedly until they become habit.

5. **The error screen is your ally.** LOVE's blue error screen gives you a file name, line number, and clear error message. Read it. The answer is almost always right there. Do not fear the error screen -- run toward it.

---

## What's Next?

You can draw static scenes. You can put text on screen. You know enough Lua to be productive. Now it is time to make things **move**.

**[Module 1: The Game Loop Trinity](module-01-game-loop-trinity.md)** introduces `love.update(dt)` in depth -- delta time, frame-independent movement, keyboard input, and building your first interactive simulation. You will go from static pixels to a player character you can steer around the screen.

[Back to LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
