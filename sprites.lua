-- sprites.lua
-- Procedurally generated multi-colour pixel-art sprites.
-- Each grid cell is 0 (transparent) or a 1-based palette index.
-- Two animation frames per entity for a walk/idle wobble.

local Sprites = {}
Sprites.data = {}

--------------------------------------------------------------------------------
-- Helper: build an Image from a palette-indexed grid.
--------------------------------------------------------------------------------
local function buildImage(grid, palette)
    local h = #grid
    local w = #grid[1]
    local imgData = love.image.newImageData(w, h)
    for row = 1, h do
        for col = 1, w do
            local idx = grid[row][col]
            if idx > 0 then
                local c = palette[idx]
                imgData:setPixel(col - 1, row - 1, c[1], c[2], c[3], 1)
            else
                imgData:setPixel(col - 1, row - 1, 0, 0, 0, 0)
            end
        end
    end
    local img = love.graphics.newImage(imgData)
    img:setFilter("nearest", "nearest")
    return img, w, h
end

local function buildWhite(grid)
    local h = #grid
    local w = #grid[1]
    local imgData = love.image.newImageData(w, h)
    for row = 1, h do
        for col = 1, w do
            if grid[row][col] > 0 then
                imgData:setPixel(col - 1, row - 1, 1, 1, 1, 1)
            else
                imgData:setPixel(col - 1, row - 1, 0, 0, 0, 0)
            end
        end
    end
    local img = love.graphics.newImage(imgData)
    img:setFilter("nearest", "nearest")
    return img
end

--------------------------------------------------------------------------------
-- Sprite definitions  (palette + two frames)
--------------------------------------------------------------------------------

-- Shorthand to cut verbosity
local _ = 0

--------------------------------------------------------------------------------
-- PLAYER  (7×10)  — little adventurer with hat and cape
--------------------------------------------------------------------------------
local PLAYER_PAL = {
    { 0.20, 0.20, 0.65 }, -- 1 dark blue  (hat, boots)
    { 0.92, 0.76, 0.60 }, -- 2 skin
    { 0.35, 0.55, 0.95 }, -- 3 blue tunic
    { 0.80, 0.22, 0.22 }, -- 4 red cape accent
}
local PLAYER_F1 = {
    { _,_,1,1,1,_,_ },
    { _,1,1,1,1,1,_ },
    { _,2,2,2,2,2,_ },
    { _,2,1,2,1,2,_ },
    { _,_,2,2,2,_,_ },
    { _,4,3,3,3,4,_ },
    { _,4,3,3,3,4,_ },
    { _,_,3,3,3,_,_ },
    { _,_,1,_,1,_,_ },
    { _,1,1,_,1,1,_ },
}
local PLAYER_F2 = {
    { _,_,1,1,1,_,_ },
    { _,1,1,1,1,1,_ },
    { _,2,2,2,2,2,_ },
    { _,2,1,2,1,2,_ },
    { _,_,2,2,2,_,_ },
    { _,4,3,3,3,4,_ },
    { _,4,3,3,3,4,_ },
    { _,_,3,3,3,_,_ },
    { _,1,_,_,_,1,_ },
    { _,1,_,_,_,1,_ },
}

--------------------------------------------------------------------------------
-- BAT  (9×6)
--------------------------------------------------------------------------------
local BAT_PAL = {
    { 0.75, 0.18, 0.18 }, -- 1 dark red
    { 1.00, 0.35, 0.25 }, -- 2 bright red
    { 1.00, 0.85, 0.20 }, -- 3 yellow eyes
}
local BAT_F1 = {
    { 1,_,_,_,_,_,_,_,1 },
    { 1,1,_,_,_,_,_,1,1 },
    { 1,1,1,2,2,2,1,1,1 },
    { _,1,2,3,2,3,2,1,_ },
    { _,_,2,2,2,2,2,_,_ },
    { _,_,_,2,_,2,_,_,_ },
}
local BAT_F2 = {
    { _,_,_,_,_,_,_,_,_ },
    { 1,1,_,_,_,_,_,1,1 },
    { 1,1,1,2,2,2,1,1,1 },
    { 1,1,2,3,2,3,2,1,1 },
    { _,_,2,2,2,2,2,_,_ },
    { _,_,2,_,_,_,2,_,_ },
}

--------------------------------------------------------------------------------
-- ZOMBIE  (7×9)
--------------------------------------------------------------------------------
local ZOMBIE_PAL = {
    { 0.25, 0.50, 0.20 }, -- 1 dark green
    { 0.45, 0.72, 0.30 }, -- 2 green skin
    { 0.85, 0.20, 0.15 }, -- 3 red (eyes / blood)
    { 0.35, 0.30, 0.25 }, -- 4 brown rags
}
local ZOMBIE_F1 = {
    { _,_,1,1,1,_,_ },
    { _,1,2,2,2,1,_ },
    { _,2,3,2,3,2,_ },
    { _,_,2,2,2,_,_ },
    { 2,2,4,4,4,_,_ },
    { _,_,4,4,4,_,_ },
    { _,_,4,4,4,_,_ },
    { _,_,1,_,1,_,_ },
    { _,_,1,_,1,_,_ },
}
local ZOMBIE_F2 = {
    { _,_,1,1,1,_,_ },
    { _,1,2,2,2,1,_ },
    { _,2,3,2,3,2,_ },
    { _,_,2,2,2,_,_ },
    { _,_,4,4,4,2,2 },
    { _,_,4,4,4,_,_ },
    { _,_,4,4,4,_,_ },
    { _,1,_,_,_,1,_ },
    { _,1,_,_,_,1,_ },
}

--------------------------------------------------------------------------------
-- SKELETON  (7×10)
--------------------------------------------------------------------------------
local SKEL_PAL = {
    { 0.85, 0.85, 0.80 }, -- 1 bone white
    { 0.55, 0.55, 0.50 }, -- 2 dark bone / outline
    { 0.20, 0.20, 0.20 }, -- 3 eye sockets
}
local SKEL_F1 = {
    { _,1,1,1,1,1,_ },
    { 1,1,1,1,1,1,1 },
    { 1,3,1,1,1,3,1 },
    { _,1,1,2,1,1,_ },
    { _,_,2,1,2,_,_ },
    { _,1,1,1,1,1,_ },
    { _,_,1,1,1,_,_ },
    { _,_,_,1,_,_,_ },
    { _,_,1,_,1,_,_ },
    { _,1,_,_,_,1,_ },
}
local SKEL_F2 = {
    { _,1,1,1,1,1,_ },
    { 1,1,1,1,1,1,1 },
    { 1,3,1,1,1,3,1 },
    { _,1,1,2,1,1,_ },
    { _,_,2,1,2,_,_ },
    { _,1,1,1,1,1,_ },
    { _,_,1,1,1,_,_ },
    { _,_,_,1,_,_,_ },
    { _,1,_,_,_,1,_ },
    { _,_,1,_,1,_,_ },
}

--------------------------------------------------------------------------------
-- GHOST  (7×8)
--------------------------------------------------------------------------------
local GHOST_PAL = {
    { 0.70, 0.75, 0.95 }, -- 1 pale blue body
    { 0.40, 0.45, 0.80 }, -- 2 darker blue
    { 0.15, 0.10, 0.35 }, -- 3 dark eyes
}
local GHOST_F1 = {
    { _,_,1,1,1,_,_ },
    { _,1,1,1,1,1,_ },
    { 1,1,1,1,1,1,1 },
    { 1,3,3,1,3,3,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,2,1,2,1,2,1 },
    { _,1,_,1,_,1,_ },
}
local GHOST_F2 = {
    { _,_,1,1,1,_,_ },
    { _,1,1,1,1,1,_ },
    { 1,1,1,1,1,1,1 },
    { 1,3,3,1,3,3,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,_,1,_,1,_,1 },
    { 1,_,1,_,1,_,1 },
}

--------------------------------------------------------------------------------
-- GOLEM  (9×10)
--------------------------------------------------------------------------------
local GOLEM_PAL = {
    { 0.45, 0.35, 0.28 }, -- 1 dark brown / stone
    { 0.65, 0.52, 0.38 }, -- 2 lighter stone
    { 0.90, 0.40, 0.15 }, -- 3 glowing orange eyes
    { 0.30, 0.25, 0.20 }, -- 4 dark cracks
}
local GOLEM_F1 = {
    { _,_,1,1,1,1,1,_,_ },
    { _,1,2,2,2,2,2,1,_ },
    { _,1,3,2,4,2,3,1,_ },
    { _,1,2,2,2,2,2,1,_ },
    { 1,1,2,2,2,2,2,1,1 },
    { 1,4,1,2,2,2,1,4,1 },
    { _,_,1,2,2,2,1,_,_ },
    { _,_,1,2,4,2,1,_,_ },
    { _,_,1,1,_,1,1,_,_ },
    { _,1,1,_,_,_,1,1,_ },
}
local GOLEM_F2 = {
    { _,_,1,1,1,1,1,_,_ },
    { _,1,2,2,2,2,2,1,_ },
    { _,1,3,2,4,2,3,1,_ },
    { _,1,2,2,2,2,2,1,_ },
    { 1,1,2,2,2,2,2,1,1 },
    { 1,4,1,2,2,2,1,4,1 },
    { _,_,1,2,2,2,1,_,_ },
    { _,_,1,2,4,2,1,_,_ },
    { _,1,_,_,_,_,_,1,_ },
    { _,1,_,_,_,_,_,1,_ },
}

--------------------------------------------------------------------------------
-- SWARM FLY  (5×5)  — tiny, appears in clusters
--------------------------------------------------------------------------------
local FLY_PAL = {
    { 0.30, 0.20, 0.35 }, -- 1 dark purple
    { 0.55, 0.30, 0.65 }, -- 2 light purple
    { 0.90, 0.70, 0.20 }, -- 3 yellow eye
}
local FLY_F1 = {
    { 1,_,_,_,1 },
    { 1,1,2,1,1 },
    { _,2,3,2,_ },
    { _,1,2,1,_ },
    { _,_,1,_,_ },
}
local FLY_F2 = {
    { _,1,_,1,_ },
    { 1,1,2,1,1 },
    { _,2,3,2,_ },
    { _,1,2,1,_ },
    { _,1,_,1,_ },
}

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

function Sprites.load()
    local data = {}

    local function register(name, f1, f2, palette, targetPx)
        local img1, w, h = buildImage(f1, palette)
        local img2        = buildImage(f2, palette)
        local flash1      = buildWhite(f1)
        local flash2      = buildWhite(f2)
        local scale       = targetPx / math.max(w, h)
        data[name] = {
            frames      = { img1, img2 },
            flashFrames = { flash1, flash2 },
            w = w, h = h,
            scale = scale,
        }
    end

    --                 name        f1          f2          palette       target size (px)
    register("player",  PLAYER_F1,  PLAYER_F2,  PLAYER_PAL,  36)
    register("bat",     BAT_F1,     BAT_F2,     BAT_PAL,     26)
    register("zombie",  ZOMBIE_F1,  ZOMBIE_F2,  ZOMBIE_PAL,  30)
    register("skeleton",SKEL_F1,    SKEL_F2,    SKEL_PAL,    32)
    register("ghost",   GHOST_F1,   GHOST_F2,   GHOST_PAL,   28)
    register("golem",   GOLEM_F1,   GOLEM_F2,   GOLEM_PAL,   44)
    register("fly",     FLY_F1,     FLY_F2,     FLY_PAL,     16)

    Sprites.data = data
end

--------------------------------------------------------------------------------
-- Draw a sprite centred at (x, y).
--   facing: 1 = right, -1 = left  (flips horizontally)
--   flash:  true to draw the white silhouette
--------------------------------------------------------------------------------
function Sprites.draw(name, x, y, age, facing, flash)
    local s = Sprites.data[name]
    if not s then return end
    local fi = (math.floor((age or 0) * 4) % 2) + 1
    local img = flash and s.flashFrames[fi] or s.frames[fi]
    local sc  = s.scale
    facing = facing or 1
    love.graphics.draw(img,
        x, y,                       -- position (will be the centre)
        0,                          -- rotation
        sc * facing, sc,            -- scaleX (flip if -1), scaleY
        s.w / 2, s.h / 2           -- origin at sprite centre
    )
end

function Sprites.getSize(name)
    local s = Sprites.data[name]
    if not s then return 0, 0 end
    return s.w * s.scale, s.h * s.scale
end

return Sprites
