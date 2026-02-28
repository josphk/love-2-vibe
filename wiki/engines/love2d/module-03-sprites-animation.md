# Module 3: Sprites & Animation

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 5-7 hours
**Prerequisites:** [Module 2: Game States & Structure](module-02-game-states-structure.md)

---

## Overview

Up until now, everything you have drawn has been a rectangle. Rectangles are great for prototyping, but at some point you want your game to *look* like a game. This module is where that transition happens. You will learn how to load images, cut them into frames from sprite sheets, cycle through those frames to create animation, and manage all of it cleanly so your code does not turn into a swamp.

The mental model shift is straightforward. Instead of `love.graphics.rectangle("fill", x, y, w, h)`, you will call `love.graphics.draw(image, x, y)`. But between those two lines lives a surprisingly deep set of concepts: texture filtering, sprite sheets, quads, animation timing, origin points, draw ordering, and batching. Each one is simple on its own, but they combine to form the visual backbone of every 2D game.

By the end of this module, you will have a walking character that faces the direction it moves, animates when walking, and stands still when idle. You will also understand why professional games pack all their art into sprite sheets, how draw order affects visual correctness, and how the `anim8` library can save you from writing your own animation state machine.

---

## Core Concepts

### 1. Loading and Drawing Images

The simplest thing you can do with a sprite is load it and draw it. Two functions, zero ceremony.

```lua
function love.load()
    player_img = love.graphics.newImage("assets/player.png")
end

function love.draw()
    love.graphics.draw(player_img, 100, 200)
end
```

That puts the image on screen with its top-left corner at `(100, 200)`. Done. But `love.graphics.draw` is far more capable than this. Its full signature looks like this:

```lua
love.graphics.draw(drawable, x, y, rotation, scaleX, scaleY, originX, originY)
```

- **x, y** -- position on screen.
- **rotation** -- in radians. `math.pi` is 180 degrees.
- **scaleX, scaleY** -- 1 is normal size, 2 is double, 0.5 is half. Negative values flip the image.
- **originX, originY** -- the point within the image that sits at `(x, y)`. This is also the point around which rotation and scaling happen. Defaults to `(0, 0)`, meaning the top-left corner.

If you are coming from HTML/CSS, think of `originX, originY` like `transform-origin`. If you are coming from Python/Pygame, it is the equivalent of setting a rect's center or topleft before blitting.

Here is a more realistic example:

```lua
function love.load()
    player_img = love.graphics.newImage("assets/player.png")
    player = {
        x = 400,
        y = 300,
        rotation = 0,
        scale = 2,
    }
end

function love.draw()
    local w = player_img:getWidth()
    local h = player_img:getHeight()

    love.graphics.draw(
        player_img,
        player.x, player.y,
        player.rotation,
        player.scale, player.scale,
        w / 2, h / 2  -- origin at the center of the image
    )
end
```

Setting the origin to the center of the image means `player.x` and `player.y` refer to the character's center, not its top-left corner. This matters a lot once you start doing rotation, collision detection, or aligning sprites to a grid.

---

### 2. Image Filtering: Nearest vs. Linear

Load a 16x16 pixel art sprite. Scale it up 4x. It looks like blurry mush. What happened?

By default, LOVE uses **linear filtering**, which smooths pixels together when scaling. This is great for high-resolution art but absolutely destroys pixel art. You want **nearest-neighbor filtering**, which preserves those hard pixel edges.

You can set it per-image:

```lua
player_img = love.graphics.newImage("assets/player.png")
player_img:setFilter("nearest", "nearest")
```

Or set the default for all future images, which is almost always what you want for a pixel art game:

```lua
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Now every image loaded after this line uses nearest filtering
    player_img = love.graphics.newImage("assets/player.png")
    tileset = love.graphics.newImage("assets/tiles.png")
end
```

The two arguments are for minification and magnification filtering respectively. For pixel art, set both to `"nearest"`. For HD art, leave them as `"linear"` (the default) or do not call this function at all.

**Rule of thumb:** If your source art has visible individual pixels that are part of the aesthetic, use `"nearest"`. If your source art is smooth and high-resolution, use `"linear"`.

Call `setDefaultFilter` at the very top of `love.load()`, before loading any images. Filtering is baked in at load time, so calling it afterward has no effect on images already in memory.

---

### 3. Sprite Sheets: Why One Big Image?

Your first instinct might be to save each frame of animation as a separate PNG: `walk_01.png`, `walk_02.png`, `walk_03.png`, and so on. This works, but it is a bad idea for two reasons:

1. **Draw call overhead.** Every time you switch textures, the GPU has to bind a new image. If you have 50 enemies each with their own image file, that is 50 texture binds per frame. Put them all on one sheet and it is 1 bind.
2. **Memory waste.** GPUs like textures whose dimensions are powers of two (128, 256, 512, etc.). A 17x23 pixel sprite gets padded internally to 32x32. If you have 100 separate files, you waste a lot of that padding space. One sprite sheet packs everything tight.

A **sprite sheet** (also called a **texture atlas**) is a single image file containing multiple sprites arranged in a grid or packed layout. You load the whole sheet once and then tell LOVE which rectangle within it to draw.

A typical sprite sheet looks like this: a grid of uniformly-sized cells. Row 0 might be the idle animation, row 1 is walking right, row 2 is walking left, and so on.

```
+------+------+------+------+
| idle | idle | idle | idle |  <- row 0: idle animation (4 frames)
|  0   |  1   |  2   |  3   |
+------+------+------+------+
| walk | walk | walk | walk |  <- row 1: walk animation (4 frames)
|  0   |  1   |  2   |  3   |
+------+------+------+------+
| atk  | atk  | atk  | atk  |  <- row 2: attack animation (4 frames)
|  0   |  1   |  2   |  3   |
+------+------+------+------+
```

To draw just one cell from this grid, you need **quads**.

---

### 4. Quads: Cutting Rectangles from a Larger Image

A **quad** defines a rectangular region within a larger image. Think of it as a cookie cutter: you place it over your sprite sheet and say "draw only this part."

```lua
love.graphics.newQuad(x, y, width, height, sheetWidth, sheetHeight)
```

- **x, y** -- the top-left corner of the region within the sheet (in pixels).
- **width, height** -- the size of the region.
- **sheetWidth, sheetHeight** -- the total dimensions of the sprite sheet. You can use `image:getDimensions()` for this.

Here is how you would set up quads for the sprite sheet described above, assuming each cell is 32x32 pixels:

```lua
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    sheet = love.graphics.newImage("assets/character.png")

    local sw, sh = sheet:getDimensions()
    local frame_w, frame_h = 32, 32

    -- Build a 2D table of quads: quads[row][col]
    quads = {}
    local cols = sw / frame_w
    local rows = sh / frame_h

    for row = 0, rows - 1 do
        quads[row] = {}
        for col = 0, cols - 1 do
            quads[row][col] = love.graphics.newQuad(
                col * frame_w, row * frame_h,
                frame_w, frame_h,
                sw, sh
            )
        end
    end
end

function love.draw()
    -- Draw the first frame of the walk animation (row 1, col 0)
    love.graphics.draw(sheet, quads[1][0], 100, 200, 0, 2, 2)
end
```

Notice that `love.graphics.draw` accepts a quad as the second argument, right after the image. When you pass a quad, LOVE only draws the region defined by that quad. The rest of the function arguments (position, rotation, scale, origin) work exactly the same as before.

**Important:** The last two arguments to `newQuad` are the dimensions of the *entire texture*, not the quad itself. LOVE needs this to calculate UV coordinates internally. If you pass the wrong sheet dimensions, your quads will be misaligned and you will see slices of adjacent frames bleeding through.

---

### 5. Manual Animation: Cycling Quads with a Timer

Animation is just showing a sequence of quads in order, with a timed delay between each one. The pattern is dead simple:

```lua
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    sheet = love.graphics.newImage("assets/character.png")

    local sw, sh = sheet:getDimensions()
    local fw, fh = 32, 32

    -- Walk animation frames (row 1, columns 0-3)
    walk_frames = {}
    for i = 0, 3 do
        walk_frames[i + 1] = love.graphics.newQuad(
            i * fw, 1 * fh,
            fw, fh,
            sw, sh
        )
    end

    anim = {
        frames = walk_frames,
        current = 1,
        timer = 0,
        duration = 0.15,  -- seconds per frame
    }
end

function love.update(dt)
    anim.timer = anim.timer + dt
    if anim.timer >= anim.duration then
        anim.timer = anim.timer - anim.duration
        anim.current = anim.current + 1
        if anim.current > #anim.frames then
            anim.current = 1  -- loop back to start
        end
    end
end

function love.draw()
    love.graphics.draw(sheet, anim.frames[anim.current], 100, 200, 0, 3, 3)
end
```

A few things to note:

- **Subtract, do not reset.** We use `anim.timer - anim.duration` instead of `anim.timer = 0`. This preserves leftover time so that animation speed stays accurate even when `dt` varies. If a frame takes slightly longer than expected, the remainder carries over.
- **Loop vs. one-shot.** The code above loops forever. For a one-shot animation (like an explosion or a death), replace the wrapping logic with a clamp:

```lua
if anim.current > #anim.frames then
    anim.current = #anim.frames  -- freeze on last frame
    anim.finished = true
end
```

- **Variable frame durations.** Some animations want certain frames held longer than others (a big windup before a punch, then fast follow-through). Instead of a single `duration`, use a table: `durations = {0.1, 0.1, 0.3, 0.05}` and index it with `anim.current`.

This manual approach works fine for small projects. But once you have a character with idle, walk, run, jump, attack, hurt, and death animations -- each in four directions -- managing all those frame tables and timer resets by hand gets tedious. That is where `anim8` comes in.

---

### 6. The anim8 Library

[anim8](https://github.com/kikito/anim8) is a small, widely-used LOVE library that handles sprite sheet animation with far less boilerplate. It gives you two key abstractions: **grids** and **animations**.

**Installation:** Download `anim8.lua` and drop it into your project folder (or a `lib/` subfolder). Then require it:

```lua
local anim8 = require("lib.anim8")
```

#### Grids

A grid tells anim8 the cell layout of your sprite sheet:

```lua
local grid = anim8.newGrid(
    32, 32,          -- frame width, frame height
    sheet:getWidth(), sheet:getHeight()
)
```

You can then reference frames using a concise syntax: `grid("1-4", 1)` means "columns 1 through 4 of row 1." Note that anim8 uses **1-based indexing** -- row 1 is the first row, not row 0.

#### Defining Animations

```lua
local idle_anim = anim8.newAnimation(grid("1-4", 1), 0.2)
local walk_anim = anim8.newAnimation(grid("1-6", 2), 0.12)
local attack_anim = anim8.newAnimation(grid("1-3", 3), {0.1, 0.1, 0.3})
```

The second argument is the frame duration. Pass a single number for uniform timing, or a table for per-frame durations. For one-shot animations, chain `:setMode("once")`:

```lua
local death_anim = anim8.newAnimation(grid("1-5", 4), 0.15):setMode("once")
```

Available modes: `"loop"` (default), `"once"` (plays once, stops on last frame), `"bounce"` (plays forward then backward).

#### Update and Draw

In your game loop:

```lua
function love.update(dt)
    current_animation:update(dt)
end

function love.draw()
    current_animation:draw(sheet, player.x, player.y, 0, 2, 2, 16, 16)
end
```

The `draw` call mirrors `love.graphics.draw` -- the arguments after the sheet and position are rotation, scaleX, scaleY, originX, originY.

#### Switching Animations

When the player changes state, swap the active animation:

```lua
function setAnimation(new_anim)
    if current_animation ~= new_anim then
        current_animation = new_anim
        current_animation:gotoFrame(1)  -- reset to first frame
    end
end
```

The `if` check prevents resetting the animation every frame while the state is held. Without it, you would see the first frame flickering endlessly because `gotoFrame(1)` fires 60 times per second.

---

### 7. Sprite Transforms: Rotation, Scaling, Origin, Flipping

You already know the draw signature. Here is how each transform applies in practice.

**Origin point.** Set this to the center of your sprite (or the character's feet for top-down games) so that position, rotation, and scaling all behave intuitively:

```lua
local ox = frame_w / 2
local oy = frame_h / 2
love.graphics.draw(sheet, quad, x, y, rotation, sx, sy, ox, oy)
```

**Flipping with negative scale.** LOVE does not have a flip function. Instead, you negate the scale axis. To face a character left instead of right, use a negative `scaleX`:

```lua
local direction = 1  -- 1 = facing right, -1 = facing left

function love.draw()
    love.graphics.draw(
        sheet, quad,
        player.x, player.y,
        0,                     -- no rotation
        direction * scale, scale,  -- flip horizontally if direction is -1
        ox, oy                 -- origin at center
    )
end
```

This is the standard technique. You do not need separate left-facing and right-facing sprite rows. Draw the right-facing sprite and flip it with `scaleX = -1`.

**Rotation.** LOVE uses radians. Quick reference: `math.pi / 2` is 90 degrees, `math.pi` is 180, `math.pi * 2` is 360. If you prefer degrees, convert: `local rad = math.rad(degrees)`.

Rotation happens around the origin point. If your origin is the top-left corner (the default), rotating 90 degrees will swing the entire image around that corner, which is almost never what you want. Set the origin to the center first.

---

### 8. Drawing Order: Painter's Algorithm and Y-Sorting

LOVE draws things in the order you call `love.graphics.draw`. Whatever you draw last ends up on top. This is the **painter's algorithm** -- earlier draws are "underneath" later ones, like a painter layering paint on a canvas.

For a simple side-scroller, this is straightforward: draw the background, then the platforms, then the enemies, then the player, then the UI.

For a **top-down game**, you need **Y-sorting**. A character standing lower on the screen (higher Y value) should appear *in front of* characters higher on screen (lower Y value). The simplest approach is to sort your entity list by Y position each frame:

```lua
function love.draw()
    -- Draw the ground/tiles first
    drawMap()

    -- Sort entities by Y position (feet position)
    table.sort(entities, function(a, b)
        return a.y < b.y
    end)

    -- Draw entities in sorted order
    for _, entity in ipairs(entities) do
        entity:draw()
    end

    -- Draw UI last (always on top)
    drawUI()
end
```

This is correct but involves sorting every frame. For small entity counts (under a few hundred), `table.sort` is fast enough that you will never notice. For very large counts, you can get more sophisticated with bucketed draw layers or spatial partitioning, but that is an optimization concern for much later.

**Z-ordering** is a generalization: assign each drawable a `z` value and sort by it. You can use fractional values (`z = 1.5` draws between `z = 1` and `z = 2`) to layer things precisely. Some developers use Y position as a default z-order with explicit overrides for objects that need special layering (bridges, flying enemies, shadows).

---

### 9. SpriteBatch: When You Have Hundreds of the Same Sprite

If you are drawing a tilemap with 1000 tiles from the same tileset image, making 1000 individual `love.graphics.draw` calls works but is wasteful. Each call has overhead. A **SpriteBatch** lets you queue up all those draws and submit them to the GPU in a single call.

```lua
function love.load()
    tileset = love.graphics.newImage("assets/tiles.png")
    batch = love.graphics.newSpriteBatch(tileset, 1000)  -- max 1000 sprites

    -- Add tiles to the batch (typically in your map loading code)
    for y = 0, map_height - 1 do
        for x = 0, map_width - 1 do
            local tile_quad = getTileQuad(x, y)  -- your quad lookup function
            batch:add(tile_quad, x * tile_size, y * tile_size)
        end
    end
end

function love.draw()
    love.graphics.draw(batch)  -- one draw call for the entire map
end
```

The SpriteBatch is best for **static or rarely-changing content** like tilemaps. For dynamic content that changes every frame, you need to call `batch:clear()` and re-add everything, which reduces the benefit.

**When to use it:** You have dozens or hundreds of sprites using the same texture. Tilemaps are the classic use case. Particle effects and bullet hell patterns are another. If you are drawing fewer than ~50 sprites from the same sheet, individual draw calls are fine and the added complexity of a SpriteBatch is not worth it.

---

### 10. Asset Management: Keeping Things Organized

A common beginner pattern is loading images wherever you happen to need them. Do not do this. Load everything in `love.load()`, store references in an organized table, and access them by name throughout the rest of your code.

```lua
local assets = {}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    assets.images = {
        player = love.graphics.newImage("assets/sprites/player.png"),
        enemy  = love.graphics.newImage("assets/sprites/enemy.png"),
        tiles  = love.graphics.newImage("assets/sprites/tiles.png"),
        bullet = love.graphics.newImage("assets/sprites/bullet.png"),
    }

    assets.sounds = {
        jump = love.audio.newSource("assets/audio/jump.wav", "static"),
        hit  = love.audio.newSource("assets/audio/hit.wav", "static"),
    }
end
```

**Directory structure** convention:

```
my_game/
  main.lua
  conf.lua
  assets/
    sprites/
      player.png
      enemy.png
      tiles.png
    audio/
      jump.wav
      hit.wav
  lib/
    anim8.lua
```

A few guidelines:

- **Never call `newImage` inside `love.update` or `love.draw`.** Loading an image parses the file and uploads it to the GPU. Doing this every frame tanks your framerate and leaks memory.
- **Use a consistent naming scheme.** If you call the image `player.png` in the filesystem, call it `assets.images.player` in code. Future-you will thank you.
- **Group by type, then by entity.** `assets/sprites/`, `assets/audio/`, `assets/fonts/`. Within sprites, you might further organize by entity if you have a lot of art: `assets/sprites/player/`, `assets/sprites/enemies/`.

---

## Code Walkthrough: Animated Walking Character

Let's put everything together. This walkthrough builds a character that walks in four directions, animates while moving, and idles when standing still. We will use `anim8` to keep the animation code tight.

Assume you have a sprite sheet `assets/character.png` with the following layout (each cell is 32x32):

- **Row 1:** Idle down (4 frames)
- **Row 2:** Walk down (6 frames)
- **Row 3:** Walk right (6 frames)
- **Row 4:** Walk up (6 frames)

Walking left uses the walk-right frames flipped horizontally.

```lua
local anim8 = require("lib.anim8")

local assets = {}
local player = {}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load sprite sheet
    assets.character = love.graphics.newImage("assets/character.png")

    -- Create anim8 grid (32x32 cells)
    local g = anim8.newGrid(
        32, 32,
        assets.character:getWidth(),
        assets.character:getHeight()
    )

    -- Define animations
    player.animations = {
        idle_down  = anim8.newAnimation(g("1-4", 1), 0.25),
        walk_down  = anim8.newAnimation(g("1-6", 2), 0.12),
        walk_right = anim8.newAnimation(g("1-6", 3), 0.12),
        walk_up    = anim8.newAnimation(g("1-6", 4), 0.12),
    }

    -- Player state
    player.x = 400
    player.y = 300
    player.speed = 150
    player.scale = 3
    player.direction = 1   -- 1 = right, -1 = left (for flipping)
    player.anim = player.animations.idle_down
end

function love.update(dt)
    local dx, dy = 0, 0
    local moving = false

    if love.keyboard.isDown("w", "up") then
        dy = -1
        player.anim = player.animations.walk_up
        moving = true
    elseif love.keyboard.isDown("s", "down") then
        dy = 1
        player.anim = player.animations.walk_down
        moving = true
    end

    if love.keyboard.isDown("a", "left") then
        dx = -1
        player.anim = player.animations.walk_right
        player.direction = -1  -- flip sprite to face left
        moving = true
    elseif love.keyboard.isDown("d", "right") then
        dx = 1
        player.anim = player.animations.walk_right
        player.direction = 1   -- face right normally
        moving = true
    end

    if not moving then
        player.anim = player.animations.idle_down
    end

    -- Normalize diagonal movement
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx = dx / len
        dy = dy / len
    end

    player.x = player.x + dx * player.speed * dt
    player.y = player.y + dy * player.speed * dt

    -- Update the active animation
    player.anim:update(dt)
end

function love.draw()
    love.graphics.draw(
        assets.character,
        player.anim:getFrameInfo(
            assets.character,
            player.x, player.y,
            0,
            player.direction * player.scale, player.scale,
            16, 16   -- origin at center of 32x32 frame
        )
    )

    -- Alternative: use anim8's built-in draw method
    -- player.anim:draw(
    --     assets.character,
    --     player.x, player.y,
    --     0,
    --     player.direction * player.scale, player.scale,
    --     16, 16
    -- )
end
```

**What is happening here:**

1. In `love.load`, we create an anim8 grid matching our sprite sheet layout, then define named animations from rows of the grid.
2. In `love.update`, we check which keys are held, pick the right animation, set the flip direction, and move the player. We also normalize diagonal movement so you do not go 41% faster diagonally (the classic `sqrt(2)` bug).
3. In `love.draw`, we pass `player.direction * player.scale` as scaleX. When the player presses left, `direction` becomes `-1`, flipping the right-facing walk animation horizontally. No separate left-facing art needed.

The idle/walk transition is handled by swapping `player.anim` each frame. Because anim8 animations maintain their own internal timer, switching back to the same animation object preserves its playback position -- the walk cycle does not stutter when you briefly release and re-press a key in the same direction.

---

## API Reference

| Function | Description |
|---|---|
| `love.graphics.newImage(path)` | Load an image from disk. Returns an Image object. |
| `love.graphics.draw(image, x, y, r, sx, sy, ox, oy)` | Draw an image (or drawable) at position, with optional rotation, scale, and origin. |
| `love.graphics.draw(image, quad, x, y, r, sx, sy, ox, oy)` | Draw a region of an image defined by a quad. |
| `love.graphics.newQuad(x, y, w, h, sw, sh)` | Create a quad (rectangular sub-region) within a texture of size `sw x sh`. |
| `image:getWidth()` / `image:getHeight()` | Get image dimensions. |
| `image:getDimensions()` | Returns width and height as two values. |
| `image:setFilter(min, mag)` | Set filtering mode: `"nearest"` or `"linear"`. |
| `love.graphics.setDefaultFilter(min, mag)` | Set default filter for all future `newImage` calls. |
| `love.graphics.newSpriteBatch(image, maxSprites)` | Create a SpriteBatch for batched drawing. |
| `batch:add(quad, x, y, r, sx, sy, ox, oy)` | Add a sprite to the batch. |
| `batch:clear()` | Remove all sprites from the batch. |

**anim8 API (most-used):**

| Function | Description |
|---|---|
| `anim8.newGrid(fw, fh, sw, sh, ox, oy)` | Create a grid for a sprite sheet with frame size `fw x fh`. |
| `grid("1-4", 2)` | Select columns 1-4 from row 2 (1-indexed). |
| `anim8.newAnimation(frames, durations, onLoop)` | Create an animation from grid frames. |
| `animation:update(dt)` | Advance the animation timer. Call in `love.update`. |
| `animation:draw(image, x, y, r, sx, sy, ox, oy)` | Draw the current frame. Call in `love.draw`. |
| `animation:gotoFrame(n)` | Jump to frame `n`. |
| `animation:setMode(mode)` | `"loop"`, `"once"`, or `"bounce"`. Returns the animation (chainable). |
| `animation:resume()` / `animation:pause()` | Control playback. |

---

## Free Asset Sources

You do not need to be an artist to make a game look good. These sites offer free (or pay-what-you-want) 2D game art:

- **[kenney.nl](https://kenney.nl/assets)** -- Massive library of free CC0 assets. Tilesets, characters, UI elements. Everything is consistent in style, which is rare and valuable. Start here.
- **[OpenGameArt.org](https://opengameart.org)** -- Community-contributed art in various licenses. Check the license on each asset (CC0, CC-BY, GPL, etc.).
- **[itch.io (game assets)](https://itch.io/game-assets/free)** -- Huge collection of free and paid sprite packs. Filter by "free" and sort by popularity. Many come with animation frames already laid out in sprite sheets.
- **[Lospec](https://lospec.com/palette-list)** -- Not art, but curated pixel art palettes. Useful if you are making your own sprites and want color harmony.

**License reminder:** CC0 means "do whatever you want, no credit required." CC-BY means "use freely, but credit the author." Read the license before shipping.

---

## Common Pitfalls

1. **Loading images every frame.** Calling `love.graphics.newImage()` inside `love.update` or `love.draw` is a performance disaster. Load once in `love.load`, store the reference, reuse it forever. This is the single most common beginner mistake.

2. **Forgetting `setDefaultFilter("nearest", "nearest")` for pixel art.** Your crisp 16x16 sprites become a blurry smear when scaled up. Call `setDefaultFilter` before any `newImage` call. If some of your sprites look fine but others are blurry, you probably loaded some images before setting the filter.

3. **Wrong sheet dimensions in `newQuad`.** The last two arguments to `newQuad` are the full sprite sheet dimensions, not the quad dimensions. Passing frame width/height here instead of sheet width/height produces silently wrong UV coordinates -- your sprites will display garbage from wrong parts of the sheet.

4. **Not normalizing diagonal movement.** Moving `speed` pixels per second on both X and Y simultaneously means you move `speed * sqrt(2)` pixels per second diagonally (about 41% faster). Always normalize: divide `dx` and `dy` by the length of the direction vector when both are nonzero. This is technically not a sprite issue, but it shows up the moment you have a visible character.

5. **Resetting animation timer to zero instead of subtracting.** Writing `anim.timer = 0` when advancing a frame throws away accumulated time. If your frame duration is 0.1 seconds and `dt` delivers 0.12 seconds, you lose 0.02 seconds every frame. Use `anim.timer = anim.timer - anim.duration` to carry the remainder forward. Over time, the zero-reset approach makes animations visibly stutter.

6. **Forgetting the origin point offset when flipping.** If your origin is `(0, 0)` (the default) and you negate scaleX to flip a sprite, the sprite flips around its top-left corner and ends up drawn in the opposite direction from where you expect. Always set the origin to the center of the frame when using negative scale for flipping.

---

## Exercises

### Exercise 1: Static Sprite Replacement

**Time:** 30-45 minutes

Take any project from Module 2 (or create a simple one) where you drew entities as colored rectangles. Replace every `love.graphics.rectangle` call with a sprite:

1. Find a free sprite pack on kenney.nl or itch.io.
2. Load the images in `love.load` into an assets table.
3. Replace each rectangle draw with `love.graphics.draw`, using the center of the sprite as the origin point.
4. Make sure filtering is set correctly for the art style.

**Success criteria:** The game plays identically to before, but with sprites instead of rectangles. No gameplay changes -- this is a visual-only swap.

---

### Exercise 2: Animated Walking Character

**Time:** 1-2 hours

Build the walking character from the Code Walkthrough section above, with these additions:

1. Find a character sprite sheet with at least idle and walk animations (kenney.nl has several, or search itch.io for "top-down character sprite sheet").
2. Use `anim8` to define idle and walk animations.
3. The character should face the direction of movement (use negative scaleX for left-facing).
4. The character should play the idle animation when not moving and the walk animation when moving.
5. **Stretch goal:** Add a simple attack animation triggered by spacebar, using `setMode("once")`. Return to idle when the attack animation finishes.

---

### Exercise 3: Sprite-Based Tilemap

**Time:** 1.5-2 hours

Create a simple tilemap renderer:

1. Download a tileset (kenney.nl's 1-bit pack is great for this).
2. Define a 2D table in Lua representing a map (use numbers for tile IDs).
3. Create quads for each tile type from the tileset.
4. Draw the map using nested loops, drawing the correct quad at each grid position.
5. **Stretch goal:** Use a SpriteBatch instead of individual draw calls. Measure the difference with `love.timer.getFPS()` by scaling up to a very large map (200x200 tiles).

---

## Key Takeaways

- **`love.graphics.draw` is your workhorse.** It handles position, rotation, scale, origin, and quad-based sub-images all in one call. Learn its full signature and you can draw anything.

- **Set `"nearest"` filtering before loading pixel art.** This is a one-line fix that prevents the most common visual mistake. Put `love.graphics.setDefaultFilter("nearest", "nearest")` at the top of `love.load`.

- **Sprite sheets exist for performance.** One texture with many frames beats many individual image files. The GPU prefers it, your loading code prefers it, and your file system prefers it.

- **Quads are windows into a sprite sheet.** `newQuad` defines which rectangle within a larger image to draw. Getting the sheet dimensions right in the last two arguments is critical.

- **Animation is just cycling quads on a timer.** The core loop is: accumulate `dt`, advance frame when the timer exceeds the frame duration, subtract (not reset) the timer. Libraries like anim8 automate this.

- **Flip sprites with negative scale, not separate art.** Set the origin to the sprite's center, then negate `scaleX` to face left. This halves your art requirements for side-facing characters.

- **Draw order is your responsibility.** LOVE draws back-to-front in call order. For top-down games, sort entities by Y position each frame. For layered scenes, use explicit z-values.

---

## What's Next?

You have sprites on screen and they animate. The next step is making them interact with the world. [Module 4: Tilemaps & Levels](module-04-tilemaps-levels.md) covers bounding box checks, circle-vs-circle collision, separating axis theorem, and when to use LOVE's built-in Box2D physics versus rolling your own simple collision. Your animated character is about to bump into things.
