# Module 4: Tilemaps & Levels

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 5-7 hours
**Prerequisites:** [Module 3: Sprites & Animation](module-03-sprites-animation.md)

---

## Overview

Every game world you have ever explored -- the overworld in Zelda, the farms in Stardew Valley, the brutal screens in Celeste -- is built from tiles. Small, repeating squares snapped to a grid, painted into a map, and rendered fast enough that you never think about it. This module teaches you how that works.

You will start by building a tilemap by hand in pure Lua -- a 2D table of numbers, drawn with nested loops. This is the "understand it from scratch" step. Then you will graduate to Tiled, a free visual map editor that professionals actually use, and STI (Simple Tiled Implementation), the library that loads those maps into LOVE. You will add a camera so the player can explore a world bigger than the screen, hook up collision so they cannot walk through walls, and wire up door triggers that load a second room.

By the end, you will have a scrolling multi-room world with a walking character, tile-based collision, and camera follow. You will also understand the coordinate math that connects pixels, tiles, and screen positions -- the kind of math that trips people up when they start adding mouse interaction or enemy pathfinding later.

---

## Core Concepts

### 1. What Is a Tilemap?

A **tilemap** is a grid where each cell references a small image (a **tile**). Instead of painting an 800x600 background as one giant image, you break it into a grid of, say, 16x16 pixel tiles and reuse them. A grass tile. A dirt tile. A wall tile. Arrange them on the grid and you have a world.

Why tiles instead of one big image? Three reasons:

1. **Memory.** A 1920x1080 background is ~8MB of VRAM. A 16x16 tileset with 64 tile types is ~64KB. The map itself is just a grid of integers -- virtually free.
2. **Reuse.** One grass tile can fill a thousand cells. One tileset image powers an entire game.
3. **Tooling.** You can build maps visually in an editor, define collision per tile type, and swap tilesets without touching game code.

The fundamental math is straightforward. Given a tile at grid position `(tileX, tileY)` with tiles that are `tileWidth` pixels wide and `tileHeight` pixels tall:

```lua
pixelX = (tileX - 1) * tileWidth
pixelY = (tileY - 1) * tileHeight
```

And going the other direction, from pixel coordinates to tile coordinates:

```lua
tileX = math.floor(pixelX / tileWidth) + 1
tileY = math.floor(pixelY / tileHeight) + 1
```

**Lua gotcha:** That `+ 1` and `- 1` everywhere is because Lua arrays start at 1, not 0. If your map table is `map[1][1]` through `map[20][15]`, then a pixel at `(0, 0)` maps to tile `(1, 1)`. Get this wrong and you will be off by one tile in every direction. You will get this wrong at least once. Everyone does.

**Try this now:** On paper or in your head, work out the pixel position for tile `(3, 5)` on a grid with 32x32 tiles. Then work backwards from pixel `(128, 64)` to tile coordinates. Check: tile `(3, 5)` starts at pixel `(64, 128)`, and pixel `(128, 64)` is tile `(5, 3)`.

---

### 2. Building Tilemaps in Code

Before reaching for any tools, build a map by hand. This is the "no magic" version so you understand exactly what libraries do for you later.

A tilemap in Lua is a 2D table of integers. Each integer is a **tile ID** that maps to a quad on your tileset image.

```lua
-- A simple 10x8 map. 0 = empty/grass, 1 = wall, 2 = floor
local map_data = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 2, 2, 2, 2, 2, 2, 2, 2, 1},
    {1, 2, 2, 2, 2, 2, 2, 2, 2, 1},
    {1, 2, 2, 2, 2, 2, 2, 2, 2, 1},
    {1, 2, 2, 2, 2, 2, 2, 2, 2, 1},
    {1, 2, 2, 2, 2, 2, 2, 2, 2, 1},
    {1, 2, 2, 2, 2, 2, 2, 2, 2, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}
```

Drawing it is two nested loops:

```lua
local TILE_SIZE = 32

-- Quads for each tile type (from a tileset image)
local tile_quads = {}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    tileset = love.graphics.newImage("assets/tileset.png")

    local sw, sh = tileset:getDimensions()
    tile_quads[0] = love.graphics.newQuad(0, 0, 32, 32, sw, sh)    -- grass
    tile_quads[1] = love.graphics.newQuad(32, 0, 32, 32, sw, sh)   -- wall
    tile_quads[2] = love.graphics.newQuad(64, 0, 32, 32, sw, sh)   -- floor
end

function love.draw()
    for row = 1, #map_data do
        for col = 1, #map_data[row] do
            local tile_id = map_data[row][col]
            local quad = tile_quads[tile_id]
            if quad then
                love.graphics.draw(
                    tileset, quad,
                    (col - 1) * TILE_SIZE,
                    (row - 1) * TILE_SIZE
                )
            end
        end
    end
end
```

Notice the indexing: `map_data[row][col]` -- row first, then column. This means `map_data[y][x]` in spatial terms. The visual layout of the table in your code matches what you see on screen: the first sub-table is the top row, the last is the bottom row. This is a convention, not a rule -- some engines do it the other way -- but row-first is what Tiled and STI expect.

**Try this now:** Add a third tile type (water, ID 3). Add a new quad for it. Paint a small pond in the middle of your map by changing some 2s to 3s.

---

### 3. Tiled Map Editor

Hand-editing Lua tables gets old fast. **Tiled** is a free, open-source map editor that lets you paint tilemaps visually, define layers, place objects, and export maps in formats that LOVE can load directly.

Download it from [mapeditor.org](https://www.mapeditor.org). It runs on Windows, macOS, and Linux.

#### Creating Your First Map

1. **New Map:** File > New Map. Set orientation to "Orthogonal," tile size to match your tileset (e.g., 16x16 or 32x32), and map size in tiles (e.g., 30x20 for a small room).

2. **Add a Tileset:** Map > New Tileset. Point it at your tileset PNG. Set the tile width/height. "Embed in map" is fine for small projects; "external tileset" is better when multiple maps share the same tiles.

3. **Paint tiles:** Select a tile from the tileset panel, click on the map to place it. Use the bucket fill for large areas. Hold Shift to draw lines.

4. **Add layers:** In the Layers panel, create multiple tile layers. A typical setup:
   - `background` -- ground, grass, water (drawn first, behind everything)
   - `collision` -- walls and obstacles (used for collision detection, optionally hidden)
   - `foreground` -- tree tops, roof overhangs (drawn last, in front of the player)

5. **Object layers:** For spawn points, triggers, and doors, add an Object Layer. Place rectangle or point objects and give them custom properties (name: "player_spawn", type: "door", destination: "room2").

#### Exporting for LOVE

Tiled can export as Lua directly: File > Export As > Lua files (*.lua). STI loads this format natively. You can also export as JSON, but the Lua export is more convenient since STI can `require()` it directly.

Save your map as `.tmx` (Tiled's native format) for editing, and export as `.lua` for your game to load. Keep both files. The `.tmx` is your editable source; the `.lua` is the compiled output.

**Try this now:** Download Tiled. Create a 20x15 map with 32x32 tiles using any free tileset from kenney.nl. Paint two layers: a ground layer and a walls layer. Export as Lua.

---

### 4. STI (Simple Tiled Implementation)

**STI** is the standard library for loading Tiled maps into LOVE. It handles parsing the exported Lua file, setting up sprite batches for efficient rendering, and giving you access to layers, objects, and tile properties.

#### Installation

Download `sti` from [GitHub](https://github.com/karai17/Simple-Tiled-Implementation) and place the `sti` folder in your project's `lib/` directory. The folder structure should look like:

```
my_game/
  lib/
    sti/
      init.lua
      ...
  maps/
    room1.lua    -- exported from Tiled
  main.lua
```

#### Loading and Drawing a Map

```lua
local sti = require("lib.sti")

local map

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    map = sti("maps/room1.lua")
end

function love.update(dt)
    map:update(dt)  -- updates animated tiles, if any
end

function love.draw()
    map:draw()
end
```

That is it. Three lines of meaningful code and your entire Tiled map renders on screen, complete with all layers, using optimized sprite batches under the hood.

#### Accessing Map Properties

STI exposes everything about the map:

```lua
-- Map dimensions in tiles
local width_in_tiles = map.width
local height_in_tiles = map.height

-- Tile dimensions in pixels
local tw = map.tilewidth
local th = map.tileheight

-- Total map size in pixels
local map_pixel_width = map.width * map.tilewidth
local map_pixel_height = map.height * map.tileheight

-- Access a specific layer
local bg_layer = map.layers["background"]

-- Access objects from an object layer
local objects_layer = map.layers["objects"]
for _, obj in ipairs(objects_layer.objects) do
    print(obj.name, obj.x, obj.y, obj.width, obj.height)
    -- Custom properties are in obj.properties
    if obj.properties.type == "door" then
        print("Door to: " .. obj.properties.destination)
    end
end
```

#### Drawing Specific Layers

If you need to draw the player between background and foreground layers (and you almost always do), draw layers individually instead of calling `map:draw()`:

```lua
function love.draw()
    map:drawLayer(map.layers["background"])
    map:drawLayer(map.layers["collision"])  -- if visible

    -- Draw the player here, between layers
    drawPlayer()

    map:drawLayer(map.layers["foreground"])
end
```

This is the standard pattern for top-down games. Background tiles go behind the player, foreground tiles (tree canopies, roof edges, bridge railings) go in front.

**Try this now:** Load the map you created in the Tiled section using STI. Verify it draws correctly. Then split the drawing into per-layer calls and add a colored rectangle "player" between the background and foreground layers.

---

### 5. Map Layers

Layers are how you create visual depth in a flat 2D world. Think of them as transparent sheets stacked on top of each other, like old-school cel animation.

A typical layer setup for a top-down RPG:

| Draw Order | Layer Name | Purpose | Example |
|---|---|---|---|
| 1 (bottom) | ground | Base terrain | Grass, dirt, water |
| 2 | decoration | Non-blocking details | Flowers, cracks, puddles |
| 3 | collision | Walkable/blocked tiles | Walls, rocks (often invisible in final game) |
| -- | *player drawn here* | -- | -- |
| 4 | foreground | Overlaps the player | Tree tops, archways, rooftops |
| 5 | overlay | Full-screen effects | Weather, fog, darkness |

The key insight is that the **player's draw position** sits between layers. Everything below the player in the table is drawn first (behind the player). Everything above is drawn after (in front of the player). This is how a character can walk "behind" a tree -- the tree trunk is on the collision layer (behind/at the player), but the tree's canopy is on the foreground layer (in front of the player).

#### Parallax Basics

For side-scrollers, you can simulate depth by scrolling layers at different speeds. The background moves slower than the foreground, creating a **parallax** effect. The mountains in Celeste appear far away because they scroll at maybe 20% of the camera speed, while the platforms scroll at 100%.

```lua
function love.draw()
    -- Far background: moves at 20% of camera speed
    map:drawLayer(map.layers["sky"],
        -camera_x * 0.2, -camera_y * 0.2)

    -- Mid background: moves at 50% of camera speed
    map:drawLayer(map.layers["mountains"],
        -camera_x * 0.5, -camera_y * 0.5)

    -- Gameplay layer: moves at full camera speed
    love.graphics.push()
    love.graphics.translate(-camera_x, -camera_y)
    map:drawLayer(map.layers["ground"])
    drawPlayer()
    love.graphics.pop()
end
```

Parallax is a cheap trick with a huge payoff. Even two layers at different scroll speeds makes a world feel dramatically more alive.

**Try this now:** In your Tiled map, add a foreground layer. Place some tile objects (tree canopies, awnings) that should overlap the player. Draw the layers in the correct order in your code and verify the player walks behind them.

---

### 6. Collision from Tile Data

The whole point of marking tiles as "wall" or "solid" is so the player cannot walk through them. There are two main approaches to tile collision, and which one you use depends on how far you want to go.

#### Approach 1: Check the Map Table Directly

The simplest collision: before moving the player, check whether the destination tile is solid.

```lua
local SOLID_TILES = { [1] = true }  -- tile ID 1 is a wall

function isSolid(px, py)
    local tx = math.floor(px / TILE_SIZE) + 1
    local ty = math.floor(py / TILE_SIZE) + 1

    -- Out of bounds is solid (prevent walking off the map)
    if tx < 1 or tx > MAP_WIDTH or ty < 1 or ty > MAP_HEIGHT then
        return true
    end

    local tile_id = map_data[ty][tx]
    return SOLID_TILES[tile_id] == true
end

function love.update(dt)
    local nx = player.x + dx * player.speed * dt
    local ny = player.y + dy * player.speed * dt

    -- Check the four corners of the player's bounding box
    if not isSolid(nx, player.y) and
       not isSolid(nx + player.w, player.y) and
       not isSolid(nx, player.y + player.h) and
       not isSolid(nx + player.w, player.y + player.h) then
        player.x = nx
    end

    if not isSolid(player.x, ny) and
       not isSolid(player.x + player.w, ny) and
       not isSolid(player.x, ny + player.h) and
       not isSolid(player.x + player.w, ny + player.h) then
        player.y = ny
    end
end
```

This works but has limitations. The player can only collide with full tile-sized rectangles. Diagonal movement resolution is crude. And it does not handle slopes, one-way platforms, or oddly-shaped obstacles.

#### Approach 2: bump.lua for Tile Collision

**bump.lua** is an AABB collision library that handles sliding, cross, and touch responses. You can feed it your tile collision data and let it handle the rest.

```lua
local bump = require("lib.bump")
local sti = require("lib.sti")

local world  -- bump world
local map
local player

function love.load()
    map = sti("maps/room1.lua")
    world = bump.newWorld(32)  -- cell size = tile size for best performance

    -- Add solid tiles from the collision layer to the bump world
    local collision_layer = map.layers["collision"]
    for y = 1, map.height do
        for x = 1, map.width do
            local tile = collision_layer.data[y][x]
            if tile then
                -- tile exists on this layer = it's solid
                local px = (x - 1) * map.tilewidth
                local py = (y - 1) * map.tileheight
                local block = { type = "wall" }
                world:add(block, px, py, map.tilewidth, map.tileheight)
            end
        end
    end

    -- Add the player to the bump world
    player = { x = 64, y = 64, w = 24, h = 24, speed = 150 }
    world:add(player, player.x, player.y, player.w, player.h)
end

function love.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("w", "up")    then dy = -1 end
    if love.keyboard.isDown("s", "down")  then dy =  1 end
    if love.keyboard.isDown("a", "left")  then dx = -1 end
    if love.keyboard.isDown("d", "right") then dx =  1 end

    -- Normalize diagonal
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / len, dy / len
    end

    local goalX = player.x + dx * player.speed * dt
    local goalY = player.y + dy * player.speed * dt

    -- bump resolves collisions and returns the actual position
    local actualX, actualY, cols, len = world:move(player, goalX, goalY)
    player.x = actualX
    player.y = actualY
end
```

The beauty of bump.lua here is the `world:move()` call. You tell it where you *want* to go, and it tells you where you *actually end up* after sliding along walls. No manual corner-checking. No penetration bugs. It just works.

#### Approach 3: Object Layer Collision Shapes

Instead of using a tile layer for collision, you can draw collision rectangles on a Tiled Object Layer. This lets you define collision shapes that do not align to the tile grid -- useful for diagonal walls, oddly-shaped furniture, or collision boxes that are smaller than a full tile.

```lua
-- Load collision rectangles from an object layer
local collision_objects = map.layers["collision_objects"]
for _, obj in ipairs(collision_objects.objects) do
    local block = { type = "wall", name = obj.name }
    world:add(block, obj.x, obj.y, obj.width, obj.height)
end
```

**Try this now:** Add bump.lua to your project. Loop through your collision layer's tiles and add each solid tile to a bump world. Move the player with `world:move()` and verify you slide along walls instead of stopping dead.

---

### 7. Camera Systems

Your map is 60 tiles wide. Your screen shows 25 tiles. You need a **camera** -- a viewport that shows a portion of the world and follows the player.

A camera is conceptually simple: it is an offset. If the camera is at world position `(200, 100)`, you draw everything shifted left by 200 and up by 100. The player at world position `(250, 150)` appears at screen position `(50, 50)`.

You can do this manually with `love.graphics.translate()`:

```lua
function love.draw()
    love.graphics.push()
    love.graphics.translate(-camera_x, -camera_y)

    -- Everything drawn here is in world coordinates
    map:draw()
    drawPlayer()

    love.graphics.pop()
    -- Everything drawn here is in screen coordinates (UI)
    drawHUD()
end
```

This works, but managing the transform stack yourself gets tedious once you add scaling, rotation, or screen shake. Libraries handle this cleanly.

#### hump.camera

**hump.camera** is part of the hump library you may already have from Module 2. It wraps the transform stack into a simple object.

```lua
local Camera = require("lib.hump.camera")

local cam

function love.load()
    cam = Camera(400, 300)  -- initial position (center of view)
end

function love.update(dt)
    -- ... move the player ...

    -- Camera follows the player
    cam:lookAt(player.x, player.y)
end

function love.draw()
    cam:attach()
        -- Everything between attach/detach is in world coordinates
        map:draw()
        drawPlayer()
    cam:detach()

    -- HUD and UI (screen coordinates)
    love.graphics.print("HP: 100", 10, 10)
end
```

`cam:attach()` pushes a transform that centers the camera position on screen. `cam:detach()` pops it. Everything between those calls is drawn in world coordinates. Everything outside is in screen coordinates.

#### Smooth Follow with Lerp

Snapping the camera directly to the player feels rigid. A **lerp** (linear interpolation) makes the camera drift smoothly toward the player, creating a satisfying lag that gives a sense of momentum. Celeste, Hollow Knight, and most modern platformers use some form of this.

```lua
function love.update(dt)
    -- ... move the player ...

    -- Smooth follow: camera drifts toward player
    local lerp_speed = 5  -- higher = faster catch-up
    local cx, cy = cam:position()
    local target_x, target_y = player.x, player.y

    cam:lookAt(
        cx + (target_x - cx) * lerp_speed * dt,
        cy + (target_y - cy) * lerp_speed * dt
    )
end
```

The `lerp_speed * dt` term controls how quickly the camera catches up. A value of 5 means the camera closes about 5/60 of the remaining distance each frame at 60 FPS. Lower values give a lazier, more cinematic feel. Higher values feel snappier.

#### Clamping to Map Bounds

Without clamping, the camera can scroll past the edge of the map, showing empty void. You need to restrict the camera position so it never shows pixels outside the map boundaries.

```lua
function clampCamera()
    local map_w = map.width * map.tilewidth
    local map_h = map.height * map.tileheight
    local screen_w = love.graphics.getWidth()
    local screen_h = love.graphics.getHeight()

    -- hump.camera:lookAt targets the CENTER of the screen
    local half_w = screen_w / 2
    local half_h = screen_h / 2

    local cx, cy = cam:position()

    cx = math.max(half_w, math.min(cx, map_w - half_w))
    cy = math.max(half_h, math.min(cy, map_h - half_h))

    cam:lookAt(cx, cy)
end
```

Call `clampCamera()` at the end of `love.update()`, after the lerp. If the map is smaller than the screen in either dimension, the clamping math breaks (the min and max cross over). In that case, just center the map on screen -- you do not need a camera for a map that fits on one screen.

**Try this now:** Add hump.camera to your project. Make the camera follow the player with lerp. Walk to the edge of the map and verify the camera does not scroll past the boundary.

---

### 8. gamera Alternative

**gamera** is a camera library by the same author as bump.lua (kikito). It takes a different design approach: instead of wrapping LOVE's transform stack, it gives you a viewport with explicit bounds.

```lua
local gamera = require("lib.gamera")

local cam

function love.load()
    -- gamera.new(world_x, world_y, world_w, world_h)
    local map_w = map.width * map.tilewidth
    local map_h = map.height * map.tileheight
    cam = gamera.new(0, 0, map_w, map_h)
end

function love.update(dt)
    cam:setPosition(player.x, player.y)
end

function love.draw()
    cam:draw(function(l, t, w, h)
        -- l, t, w, h = visible area in world coordinates
        -- Only draw what's visible (optimization opportunity)
        map:draw()
        drawPlayer()
    end)

    -- HUD outside the camera callback
    love.graphics.print("HP: 100", 10, 10)
end
```

#### When to Use Which

| Feature | hump.camera | gamera |
|---|---|---|
| Bounds clamping | Manual (you write it) | Built in (set in constructor) |
| Rotation and zoom | Built in | Built in |
| Visible area query | Not provided | Passed to draw callback |
| API style | attach/detach (imperative) | draw callback (functional) |
| Part of larger library | Yes (hump has gamestate, timer, etc.) | Standalone |
| Screen shake | Trivial with `cam:move(dx, dy)` | `cam:setPosition` with offset |

**Rule of thumb:** If you are already using hump for gamestate or timer, use `hump.camera` for consistency. If you want built-in bounds clamping and visible-area culling without writing it yourself, use gamera. Both are mature, well-documented, and widely used. You cannot go wrong with either.

---

### 9. World-to-Screen Coordinates

Once you have a camera, the question "where did the player click?" becomes surprisingly tricky. The mouse position from `love.mouse.getPosition()` is in **screen coordinates**. Your game entities exist in **world coordinates**. The camera transform maps between the two, and you need to be able to go both directions.

#### Mouse Click to World Position

```lua
-- With hump.camera
function love.mousepressed(x, y, button)
    -- x, y are screen coordinates
    local world_x, world_y = cam:worldCoords(x, y)
    print("Clicked at world position:", world_x, world_y)
end
```

#### World Position to Screen Position

```lua
-- Where on screen is this world object?
local screen_x, screen_y = cam:cameraCoords(enemy.x, enemy.y)
```

This is useful for drawing UI elements that point at world objects (health bars over enemies, speech bubbles, arrow indicators for off-screen objectives).

#### World Position to Tile Coordinates

The third conversion you will need constantly:

```lua
function worldToTile(wx, wy)
    local tx = math.floor(wx / map.tilewidth) + 1
    local ty = math.floor(wy / map.tileheight) + 1
    return tx, ty
end

function tileToWorld(tx, ty)
    local wx = (tx - 1) * map.tilewidth
    local wy = (ty - 1) * map.tileheight
    return wx, wy
end
```

#### The Full Chain: Screen to Tile

Clicking on a tile in a scrolling world requires two conversions chained together:

```lua
function love.mousepressed(x, y, button)
    -- Step 1: screen coords -> world coords
    local wx, wy = cam:worldCoords(x, y)

    -- Step 2: world coords -> tile coords
    local tx, ty = worldToTile(wx, wy)

    -- Now you know which tile was clicked
    print("Clicked tile:", tx, ty)
end
```

This chain is essential for any game with mouse interaction -- placing buildings in a strategy game, selecting tiles in a puzzle, clicking on enemies in an RPG.

**With gamera**, the conversion is slightly different. gamera does not expose `worldCoords` directly, so you compute it from the camera position and viewport offset:

```lua
function love.mousepressed(x, y, button)
    local cx, cy = cam:getPosition()
    local sw, sh = love.graphics.getDimensions()
    local wx = cx - sw / 2 + x
    local wy = cy - sh / 2 + y
    -- ... then world to tile as before
end
```

**Try this now:** Add a `love.mousepressed` handler that prints the tile coordinates of the clicked tile. Verify it works correctly when the camera has scrolled away from the origin.

---

### 10. Level Transitions

A single room gets boring. Real games have multiple areas connected by doors, stairs, portals, or screen edges. The design question is: how do you load a new map and place the player at the right spot?

#### Setting Up Door Objects in Tiled

In Tiled, create an object layer called "doors." Place rectangle objects where your doors are. Give each one custom properties:

- `destination` -- the filename of the target map (e.g., "room2.lua")
- `spawn_name` -- the name of the spawn point in the target map (e.g., "from_room1")

In the target map, create an object layer with point objects named to match the `spawn_name` values. These are your **spawn points**.

#### Detecting Door Collisions

Check if the player overlaps any door object each frame:

```lua
function checkDoors()
    local doors_layer = map.layers["doors"]
    if not doors_layer then return end

    for _, door in ipairs(doors_layer.objects) do
        if playerOverlaps(door) then
            loadMap(door.properties.destination, door.properties.spawn_name)
            return  -- stop checking, we're switching maps
        end
    end
end

function playerOverlaps(rect)
    return player.x < rect.x + rect.width and
           player.x + player.w > rect.x and
           player.y < rect.y + rect.height and
           player.y + player.h > rect.y
end
```

#### Loading a New Map

```lua
function loadMap(map_file, spawn_name)
    -- Remove old tile collision from bump world
    -- (you need to track what you added)
    for _, block in ipairs(tile_blocks) do
        world:remove(block)
    end
    tile_blocks = {}

    -- Load the new map
    map = sti("maps/" .. map_file)

    -- Add new collision tiles to bump world
    addCollisionTiles()

    -- Find the spawn point and place the player
    local spawn_layer = map.layers["spawns"]
    if spawn_layer then
        for _, obj in ipairs(spawn_layer.objects) do
            if obj.name == spawn_name then
                player.x = obj.x
                player.y = obj.y
                world:update(player, player.x, player.y, player.w, player.h)
                break
            end
        end
    end

    -- Reset camera to player
    cam:lookAt(player.x, player.y)
    clampCamera()
end
```

#### Preserving Player State

When the player walks through a door, their health, inventory, and quest progress should survive the transition. The pattern is simple: keep player state separate from map state. The `player` table persists across `loadMap()` calls. Only the map, the bump collision world, and the camera reset. Everything on the player (HP, items, stats) stays.

```lua
-- Player state that persists across rooms
player = {
    x = 0, y = 0,        -- these get overwritten by spawn point
    w = 24, h = 24,
    speed = 150,
    hp = 100,             -- persists
    inventory = {},       -- persists
    current_quest = nil,  -- persists
}
```

If you need to preserve per-room state (enemies killed, chests opened), keep a table keyed by map filename:

```lua
local room_state = {}

function saveRoomState(map_file)
    room_state[map_file] = {
        enemies_dead = getDeadEnemyIds(),
        chests_opened = getOpenedChestIds(),
    }
end

function loadRoomState(map_file)
    local state = room_state[map_file]
    if state then
        -- Remove dead enemies, open opened chests, etc.
    end
end
```

This is how Zelda dungeons remember which rooms you have cleared. The data is lightweight (just IDs and booleans), so keeping it all in memory is fine for small-to-medium games.

**Try this now:** Create two maps in Tiled, each with a door object and a spawn point. Wire up the transition code so walking into the door loads the other map and places the player at the spawn point.

---

## Code Walkthrough

This walkthrough builds a complete scrolling world in two stages: first a hand-coded tilemap with manual collision, then the full STI + hump.camera + bump.lua version with a door transition to a second room.

### Stage 1: Hand-Coded Tilemap

No external libraries. Pure LOVE. This is so you understand what STI does for you.

```lua
-- main.lua (hand-coded tilemap, no libraries)

local TILE_SIZE = 32
local MAP_W = 20  -- tiles wide
local MAP_H = 15  -- tiles tall

local player
local camera = { x = 0, y = 0 }
local tileset
local tile_quads = {}

-- 0 = floor, 1 = wall
local map_data = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0,0,1},
    {1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1},
    {1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,1,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,1},
    {1,0,0,1,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,1},
    {1,0,0,1,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

local SOLID = { [1] = true }

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setMode(640, 480)

    -- In a real project you'd load a tileset image.
    -- For this demo we'll draw colored rectangles.
    player = { x = 64, y = 64, w = 20, h = 20, speed = 150 }
end

function isSolid(px, py)
    local tx = math.floor(px / TILE_SIZE) + 1
    local ty = math.floor(py / TILE_SIZE) + 1
    if tx < 1 or tx > MAP_W or ty < 1 or ty > MAP_H then
        return true
    end
    return SOLID[map_data[ty][tx]] == true
end

function canMoveTo(x, y, w, h)
    return not isSolid(x, y) and
           not isSolid(x + w - 1, y) and
           not isSolid(x, y + h - 1) and
           not isSolid(x + w - 1, y + h - 1)
end

function love.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("w", "up")    then dy = -1 end
    if love.keyboard.isDown("s", "down")  then dy =  1 end
    if love.keyboard.isDown("a", "left")  then dx = -1 end
    if love.keyboard.isDown("d", "right") then dx =  1 end

    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(2)
        dx, dy = dx / len, dy / len
    end

    local nx = player.x + dx * player.speed * dt
    local ny = player.y + dy * player.speed * dt

    -- Resolve X and Y independently for wall sliding
    if canMoveTo(nx, player.y, player.w, player.h) then
        player.x = nx
    end
    if canMoveTo(player.x, ny, player.w, player.h) then
        player.y = ny
    end

    -- Camera follows player (centered)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    camera.x = player.x + player.w / 2 - sw / 2
    camera.y = player.y + player.h / 2 - sh / 2

    -- Clamp camera to map bounds
    local map_pw = MAP_W * TILE_SIZE
    local map_ph = MAP_H * TILE_SIZE
    camera.x = math.max(0, math.min(camera.x, map_pw - sw))
    camera.y = math.max(0, math.min(camera.y, map_ph - sh))
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- Draw tiles
    for row = 1, MAP_H do
        for col = 1, MAP_W do
            local tile = map_data[row][col]
            local px = (col - 1) * TILE_SIZE
            local py = (row - 1) * TILE_SIZE

            if tile == 1 then
                love.graphics.setColor(0.4, 0.4, 0.5)
            else
                love.graphics.setColor(0.2, 0.5, 0.2)
            end
            love.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)

            -- Grid lines
            love.graphics.setColor(0, 0, 0, 0.1)
            love.graphics.rectangle("line", px, py, TILE_SIZE, TILE_SIZE)
        end
    end

    -- Draw player
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()

    -- HUD (screen coordinates)
    local tx = math.floor(player.x / TILE_SIZE) + 1
    local ty = math.floor(player.y / TILE_SIZE) + 1
    love.graphics.print("Tile: " .. tx .. ", " .. ty, 10, 10)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end
```

This is about 100 lines and it gives you a walking character, tile collision with wall sliding, a camera with bounds clamping, and a HUD showing the current tile coordinate. No libraries. No magic.

### Stage 2: STI + hump.camera + bump.lua

Now the real version. This loads maps from Tiled, uses bump.lua for collision, hump.camera for viewport management, and supports door transitions between two rooms.

```lua
-- main.lua (STI + hump.camera + bump.lua)
local sti = require("lib.sti")
local bump = require("lib.bump")
local Camera = require("lib.hump.camera")

local map, world, cam
local player
local tile_blocks = {}  -- track collision blocks for cleanup

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setMode(800, 600)

    player = {
        x = 0, y = 0,
        w = 24, h = 24,
        speed = 150,
        hp = 100,
        inventory = {},
    }

    cam = Camera(400, 300)

    loadMap("room1.lua", "default_spawn")
end

function loadMap(map_file, spawn_name)
    -- Clean up old collision data
    if world then
        for _, block in ipairs(tile_blocks) do
            if world:hasItem(block) then
                world:remove(block)
            end
        end
        if world:hasItem(player) then
            world:remove(player)
        end
    end
    tile_blocks = {}

    -- Load the new map
    map = sti("maps/" .. map_file)
    world = bump.newWorld(map.tilewidth)

    -- Add collision tiles to bump world
    local collision_layer = map.layers["collision"]
    if collision_layer then
        for y = 1, map.height do
            for x = 1, map.width do
                local tile = collision_layer.data[y][x]
                if tile then
                    local block = {
                        type = "wall",
                        tx = x, ty = y,
                    }
                    local px = (x - 1) * map.tilewidth
                    local py = (y - 1) * map.tileheight
                    world:add(block, px, py, map.tilewidth, map.tileheight)
                    table.insert(tile_blocks, block)
                end
            end
        end
    end

    -- Find spawn point and place the player
    local spawns = map.layers["spawns"]
    if spawns then
        for _, obj in ipairs(spawns.objects) do
            if obj.name == spawn_name then
                player.x = obj.x
                player.y = obj.y
                break
            end
        end
    end

    -- Add player to bump world
    world:add(player, player.x, player.y, player.w, player.h)

    -- Snap camera to player
    cam:lookAt(player.x + player.w / 2, player.y + player.h / 2)
    clampCamera()
end

function clampCamera()
    local map_pw = map.width * map.tilewidth
    local map_ph = map.height * map.tileheight
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local half_w, half_h = sw / 2, sh / 2

    local cx, cy = cam:position()
    cx = math.max(half_w, math.min(cx, map_pw - half_w))
    cy = math.max(half_h, math.min(cy, map_ph - half_h))
    cam:lookAt(cx, cy)
end

function checkDoors()
    local doors_layer = map.layers["doors"]
    if not doors_layer then return end

    for _, door in ipairs(doors_layer.objects) do
        if player.x < door.x + door.width and
           player.x + player.w > door.x and
           player.y < door.y + door.height and
           player.y + player.h > door.y then
            local dest = door.properties.destination
            local spawn = door.properties.spawn_name
            if dest and spawn then
                loadMap(dest, spawn)
                return
            end
        end
    end
end

function love.update(dt)
    -- Movement
    local dx, dy = 0, 0
    if love.keyboard.isDown("w", "up")    then dy = -1 end
    if love.keyboard.isDown("s", "down")  then dy =  1 end
    if love.keyboard.isDown("a", "left")  then dx = -1 end
    if love.keyboard.isDown("d", "right") then dx =  1 end

    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / len, dy / len
    end

    local goalX = player.x + dx * player.speed * dt
    local goalY = player.y + dy * player.speed * dt

    local actualX, actualY = world:move(player, goalX, goalY)
    player.x = actualX
    player.y = actualY

    -- Check for door transitions
    checkDoors()

    -- Smooth camera follow
    local lerp_speed = 6
    local cx, cy = cam:position()
    local tx = player.x + player.w / 2
    local ty = player.y + player.h / 2
    cam:lookAt(
        cx + (tx - cx) * lerp_speed * dt,
        cy + (ty - cy) * lerp_speed * dt
    )
    clampCamera()

    -- Update map (animated tiles)
    map:update(dt)
end

function love.draw()
    cam:attach()

    -- Draw layers in order with player in between
    if map.layers["background"] then
        map:drawLayer(map.layers["background"])
    end
    if map.layers["collision"] then
        map:drawLayer(map.layers["collision"])
    end

    -- Player
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
    love.graphics.setColor(1, 1, 1)

    -- Foreground layer (tree tops, etc.)
    if map.layers["foreground"] then
        map:drawLayer(map.layers["foreground"])
    end

    cam:detach()

    -- HUD
    love.graphics.print("HP: " .. player.hp, 10, 10)
    love.graphics.print(string.format("Pos: %.0f, %.0f", player.x, player.y), 10, 30)
end

function love.mousepressed(x, y, button)
    -- Convert screen click to tile coordinates
    local wx, wy = cam:worldCoords(x, y)
    local tx = math.floor(wx / map.tilewidth) + 1
    local ty = math.floor(wy / map.tileheight) + 1
    print("Clicked tile:", tx, ty)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end
```

This is the real thing. A Tiled-authored map loaded by STI, collision handled by bump.lua, camera managed by hump.camera, with door transitions and persistent player state. Everything is under 200 lines. The libraries are doing the heavy lifting, and you understand what they are doing because you built the manual version first.

---

## API Reference

### STI (Simple Tiled Implementation)

| Function | Description |
|---|---|
| `sti(path)` | Load a Tiled map (exported as Lua). Returns a map object. |
| `map:update(dt)` | Update animated tiles. Call in `love.update`. |
| `map:draw()` | Draw all visible layers. |
| `map:drawLayer(layer)` | Draw a single layer. Use for controlling draw order. |
| `map.width` | Map width in tiles. |
| `map.height` | Map height in tiles. |
| `map.tilewidth` | Width of one tile in pixels. |
| `map.tileheight` | Height of one tile in pixels. |
| `map.layers` | Table of layers, accessible by name or index. |
| `map.layers["name"].data` | 2D array of tile data for a tile layer. `nil` entries = empty. |
| `map.layers["name"].objects` | Array of objects for an object layer. |
| `map:addCustomLayer(name, index)` | Add a custom draw layer (for drawing entities between map layers). |
| `map:convertToCustomLayer(name)` | Convert an existing layer to a custom layer with a `draw` function. |

### hump.camera

| Function | Description |
|---|---|
| `Camera(x, y, zoom, rotation)` | Create a camera centered at `(x, y)`. Zoom defaults to 1. |
| `cam:lookAt(x, y)` | Center the camera on world position `(x, y)`. |
| `cam:position()` | Returns the camera's current `x, y` in world coordinates. |
| `cam:move(dx, dy)` | Move the camera by an offset. Useful for screen shake. |
| `cam:attach()` | Push the camera transform. Everything drawn after this is in world coords. |
| `cam:detach()` | Pop the camera transform. Everything drawn after this is in screen coords. |
| `cam:worldCoords(sx, sy)` | Convert screen coordinates to world coordinates. |
| `cam:cameraCoords(wx, wy)` | Convert world coordinates to screen coordinates. |
| `cam:zoomTo(zoom)` | Set the zoom level (1 = normal, 2 = zoomed in 2x). |
| `cam:rotate(angle)` | Rotate the camera by angle (radians). |

### gamera

| Function | Description |
|---|---|
| `gamera.new(x, y, w, h)` | Create a camera with world bounds `(x, y, w, h)`. Clamping is automatic. |
| `cam:setPosition(x, y)` | Center the camera on world position `(x, y)`. |
| `cam:getPosition()` | Returns current `x, y`. |
| `cam:setWindow(x, y, w, h)` | Set the viewport rectangle on screen. |
| `cam:getWindow()` | Returns viewport rectangle. |
| `cam:setScale(scale)` | Set zoom level. |
| `cam:draw(fn)` | Execute `fn(l, t, w, h)` with the camera transform applied. `l, t, w, h` are the visible world rect. |
| `cam:toWorld(sx, sy)` | Convert screen coordinates to world coordinates. |
| `cam:toScreen(wx, wy)` | Convert world coordinates to screen coordinates. |

---

## Libraries & Tools

### Tiled (Map Editor)

- **What:** Free, open-source 2D map editor. The industry standard for indie games.
- **Download:** [mapeditor.org](https://www.mapeditor.org)
- **Setup:** Install it, point it at your tileset PNGs, and paint maps. Export as Lua for LOVE.
- **Why not just code maps by hand?** You can, for tiny maps. But Tiled gives you visual editing, undo, copy-paste, tile stamps, terrain brushes, auto-tiling, and object layers. Once your map is bigger than 10x10, hand-editing a Lua table is painful.

### STI (Simple Tiled Implementation)

- **What:** Loads Tiled maps (Lua export) into LOVE. Handles sprite batches, animated tiles, layers, and object data.
- **Repo:** [github.com/karai17/Simple-Tiled-Implementation](https://github.com/karai17/Simple-Tiled-Implementation)
- **Install:** Download the `sti` folder, place in `lib/sti/`. Require as `local sti = require("lib.sti")`.
- **When to use:** Whenever you use Tiled. STI is the standard bridge between Tiled and LOVE. Writing your own Tiled parser is a waste of time.

### hump.camera

- **What:** A simple camera module for LOVE. Handles transforms, coordinate conversion, zoom, and rotation.
- **Repo:** [github.com/vrld/hump](https://github.com/vrld/hump) (camera is one module among several)
- **When to use:** When you already use hump for gamestate/timer, or when you want a minimal camera with an imperative attach/detach API.

### gamera

- **What:** A standalone camera library with built-in bounds clamping and viewport management.
- **Repo:** [github.com/kikito/gamera](https://github.com/kikito/gamera)
- **When to use:** When you want automatic bounds clamping without writing it yourself, or when you prefer a callback-based draw API that gives you the visible world rectangle.

### Rolling Your Own vs. Using Libraries

There is a real case for writing your own tilemap renderer. It is about 50 lines of code (you built it in Core Concepts section 2), you understand every line, and you can customize it however you want. The same is true for a basic camera -- it is just `love.graphics.translate()`.

The case for libraries: STI handles animated tiles, multiple tileset images, layer ordering, object parsing, and sprite batch optimization. hump.camera and gamera handle coordinate conversion, zoom, rotation, and bounds clamping. Writing all of that yourself is 500+ lines of code that already exists, is tested, and is documented.

**Recommendation:** Build the manual version once (you just did) to understand the concepts. Then use the libraries for real projects. This is not a shortcut; it is engineering judgment.

---

## Common Pitfalls

### 1. Off-by-One Errors with 1-Indexed Tile Coordinates

Lua tables start at index 1. Pixel coordinates start at 0. This mismatch causes off-by-one errors that are maddening to debug because everything looks almost right -- just shifted one tile.

```lua
-- WRONG: forgets the 1-index offset
local tx = math.floor(px / TILE_SIZE)
local ty = math.floor(py / TILE_SIZE)
local tile = map_data[ty][tx]  -- tx=0 at the left edge -> nil!

-- RIGHT: add 1 for Lua's 1-based indexing
local tx = math.floor(px / TILE_SIZE) + 1
local ty = math.floor(py / TILE_SIZE) + 1
local tile = map_data[ty][tx]  -- tx=1 at the left edge -> correct
```

And going the other way:

```lua
-- WRONG: forgets to subtract 1
local px = tx * TILE_SIZE  -- tile 1 draws at pixel 32, not 0!

-- RIGHT: subtract 1 before multiplying
local px = (tx - 1) * TILE_SIZE  -- tile 1 draws at pixel 0
```

Write a `worldToTile` and `tileToWorld` function pair early and use them everywhere. Do not inline the math. You will get it wrong inline.

### 2. Forgetting camera:detach() (Everything Shifts)

If you call `cam:attach()` but forget `cam:detach()`, every draw call for the rest of the frame (including the next frame's draws) is offset by the camera transform. Your HUD scrolls with the world, your debug text is in the wrong place, and things get weird.

```lua
function love.draw()
    cam:attach()
    map:draw()
    drawPlayer()
    -- Forgot cam:detach() here!

    -- This HUD text now scrolls with the world
    love.graphics.print("HP: 100", 10, 10)
end
```

Always pair `attach()` and `detach()`. If you are paranoid, wrap them in a pcall or use gamera's callback-based API which makes this impossible to get wrong.

### 3. Drawing Order Mistakes (Foreground Behind Player)

If you call `map:draw()` (which draws all layers at once) and then draw the player, the player always appears on top of everything -- including tree canopies and bridge railings that should overlap the player.

```lua
-- WRONG: player is always on top
function love.draw()
    map:draw()        -- all layers, including foreground
    drawPlayer()      -- player draws on top of everything
end

-- RIGHT: draw layers individually with player in between
function love.draw()
    map:drawLayer(map.layers["background"])
    map:drawLayer(map.layers["collision"])
    drawPlayer()
    map:drawLayer(map.layers["foreground"])
end
```

If your trees never overlap the player, check your draw order first.

### 4. Loading Maps Every Frame Instead of Once

This is the tilemap equivalent of calling `newImage()` in `love.draw()`. STI parses the Lua file, builds sprite batches, and allocates memory. Doing this 60 times per second will destroy your framerate.

```lua
-- CATASTROPHICALLY WRONG
function love.update(dt)
    map = sti("maps/room1.lua")  -- re-parses the entire map every frame
end

-- RIGHT: load once in love.load or in a loadMap function
function love.load()
    map = sti("maps/room1.lua")  -- once
end
```

### 5. Mouse Position in World vs. Screen Coordinates

You click at screen position `(400, 300)`. The camera is at world position `(1200, 800)`. If you use the raw mouse coordinates as world coordinates, you are clicking 800 pixels away from where you think you are.

```lua
-- WRONG: treats screen coords as world coords
function love.mousepressed(x, y, button)
    local tx = math.floor(x / TILE_SIZE) + 1  -- wrong tile!
end

-- RIGHT: convert through the camera first
function love.mousepressed(x, y, button)
    local wx, wy = cam:worldCoords(x, y)
    local tx = math.floor(wx / TILE_SIZE) + 1  -- correct tile
end
```

This will trip you up every single time you add mouse interaction to a camera-based game. Build the habit of always converting mouse coordinates through the camera before using them.

### 6. Tile Bleeding/Gaps from Floating Point Camera Positions

When the camera position is a non-integer (e.g., 100.3, 200.7), tiles can render with sub-pixel offsets. This causes thin lines of the background color to "bleed" through between tiles -- visible as flickering gaps in the grid.

The fix is to round the camera position to integer pixels before rendering:

```lua
function love.draw()
    -- Round camera position to prevent tile bleeding
    local cx, cy = cam:position()
    cam:lookAt(math.floor(cx + 0.5), math.floor(cy + 0.5))

    cam:attach()
    map:draw()
    -- ... etc
    cam:detach()
end
```

Alternatively, add a 1-pixel overlap (extrusion/padding) around each tile in your tileset image. Tiled has a "margin" and "spacing" setting for this. Professional tilesets include this padding specifically to prevent bleeding.

---

## Exercises

### Exercise 1: Hand-Coded Tilemap Explorer

**Time:** 1-2 hours

Build a tilemap from scratch with no external libraries.

1. Define a 25x20 map using a 2D Lua table with at least 3 tile types: ground (walkable), wall (solid), and water (impassable but visually distinct).
2. Draw the map using nested loops and colored rectangles (no tileset image needed).
3. Add a player rectangle that moves with arrow keys.
4. Implement collision checking against the solid tile types using the corner-checking approach from Core Concepts section 6.
5. Add a camera that follows the player and clamps to the map edges.
6. Display the player's current tile coordinate on the HUD.

**Success criteria:** The player walks around, slides along walls, cannot walk through walls or off the map, and the camera follows smoothly.

---

### Exercise 2: Tiled + STI Map with Camera Follow

**Time:** 2-3 hours

Graduate to proper tools.

1. Create a map in Tiled (at least 40x30 tiles) with three layers: background, collision, and foreground.
2. Add a tileset from kenney.nl (the 1-bit pack or RPG pack works well).
3. Paint a world with rooms, corridors, and decorative foreground elements.
4. Load the map with STI. Draw layers individually so the player appears between background and foreground.
5. Add bump.lua collision by iterating the collision layer's tiles and adding them to a bump world.
6. Use hump.camera (or gamera) for camera follow with lerp smoothing and bounds clamping.
7. Add `love.mousepressed` to print the clicked tile coordinate (with proper screen-to-world conversion).

**Success criteria:** The player navigates a visually rich world, cannot walk through walls, the camera follows smoothly without showing off-map areas, and mouse clicks report the correct tile.

---

### Exercise 3: Multi-Room Dungeon with Doors

**Time:** 2-3 hours

Build a connected world.

1. Create at least 3 maps in Tiled, each representing a room in a dungeon.
2. Place door objects (rectangles on an object layer) with `destination` and `spawn_name` custom properties.
3. Place spawn point objects (points on an object layer) named to match the doors' `spawn_name` values.
4. Implement the `loadMap()` function that tears down old collision, loads the new map, rebuilds collision, and places the player at the correct spawn.
5. Add a simple inventory: the player can pick up "key" objects (Tiled point objects with a `type = "key"` property). Keys persist across room transitions.
6. **Stretch:** Add a locked door that only opens if the player has collected the key. Display the inventory on the HUD.

**Success criteria:** Walking into a door loads a new room with the player at the correct position. Keys picked up in one room persist when entering another. The locked door checks the inventory before allowing passage.

---

## Recommended Reading & Resources

### Essential

| Resource | URL | What You Get |
|---|---|---|
| STI GitHub + README | [github.com/karai17/Simple-Tiled-Implementation](https://github.com/karai17/Simple-Tiled-Implementation) | API reference, usage examples, plugin system |
| Tiled documentation | [doc.mapeditor.org](https://doc.mapeditor.org) | Complete editor reference, export formats, custom properties |
| hump documentation | [hump.readthedocs.io](https://hump.readthedocs.io) | camera, gamestate, timer, vector docs |
| bump.lua README | [github.com/kikito/bump.lua](https://github.com/kikito/bump.lua) | AABB collision API, response types, spatial hashing |
| Kenney assets | [kenney.nl](https://kenney.nl) | Free CC0 tilesets ready for Tiled |

### Go Deeper

| Resource | URL | What You Get |
|---|---|---|
| gamera GitHub | [github.com/kikito/gamera](https://github.com/kikito/gamera) | Alternative camera with built-in bounds |
| Tiled Lua export format | [doc.mapeditor.org/en/stable/reference/lua-map-format](https://doc.mapeditor.org/en/stable/reference/lua-map-format/) | Understanding the raw data STI consumes |
| Sheepolution LOVE book, Ch. 18-19 | [sheepolution.com/learn/book/18](https://sheepolution.com/learn/book/18) | Text-based tilemap and camera tutorial |
| LOVE wiki: SpriteBatch | [love2d.org/wiki/SpriteBatch](https://love2d.org/wiki/SpriteBatch) | The optimization STI uses under the hood |
| OpenGameArt tilesets | [opengameart.org](https://opengameart.org) | More free tileset art (check licenses) |

---

## Key Takeaways

- **A tilemap is a grid of integers that index into a tileset image.** The core math is `pixel = (tile - 1) * tileSize` and `tile = floor(pixel / tileSize) + 1`. Get those two conversions right and everything else follows.

- **Build the manual version first, then use libraries.** Understanding the nested loop renderer and manual collision makes you a better debugger when STI or bump.lua does something unexpected.

- **Tiled + STI is the standard workflow.** Paint maps visually in Tiled, export as Lua, load with STI. This is how most LOVE games build their worlds. Fighting this workflow gains you nothing.

- **Draw layers individually to control draw order.** Call `map:drawLayer()` for each layer, inserting your player draw call between the background and foreground layers. Calling `map:draw()` all at once forces the player to be either behind or in front of everything.

- **Every camera-based game needs coordinate conversion.** Mouse clicks are in screen space, entities are in world space, and tiles are in grid space. Write `worldToTile`, `tileToWorld`, and use `cam:worldCoords()` / `cam:cameraCoords()` for screen-world conversion. Do this once, correctly, and reuse it everywhere.

- **Level transitions are map reloads with spawn point lookups.** Tear down old collision, load the new map, rebuild collision, find the spawn point, place the player. Player state (HP, inventory) lives outside the map data and survives the transition.

- **Round your camera position to avoid tile bleeding.** Floating-point camera offsets cause sub-pixel rendering gaps between tiles. Snap to integers before drawing, or use extruded tilesets with 1-pixel padding.

---

## What's Next?

You have a scrolling world, tile collision, and room transitions. The player can walk around but cannot interact with anything more complex than a wall or a door. [Module 5: Collision & Physics](module-05-collision-physics.md) takes collision further -- AABB tests beyond tiles, circle collision, response types (slide, bounce, push), and when to use LOVE's built-in Box2D physics (`love.physics`) versus bump.lua. Your character is about to jump on platforms, fight enemies, and pick up items.

[Back to the roadmap.](love2d-learning-roadmap.md)
