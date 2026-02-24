-- sprites.lua
-- Procedurally generated pixel-art alien sprites in the style of Space Invaders.
-- Each enemy type gets two animation frames (classic leg-swap wobble).
-- Sprites are built at load time via ImageData — no external assets needed.

local Sprites = {}

--------------------------------------------------------------------------------
-- Pixel grids for each enemy type (two frames each).
-- 1 = filled pixel, 0 = empty.  Drawn with the enemy's own color.
--------------------------------------------------------------------------------

-- DRONE (11×8) — classic crab invader
local DRONE_F1 = {
    { 0,0,1,0,0,0,0,0,1,0,0 },
    { 0,0,0,1,0,0,0,1,0,0,0 },
    { 0,0,1,1,1,1,1,1,1,0,0 },
    { 0,1,1,0,1,1,1,0,1,1,0 },
    { 1,1,1,1,1,1,1,1,1,1,1 },
    { 1,0,1,1,1,1,1,1,1,0,1 },
    { 1,0,1,0,0,0,0,0,1,0,1 },
    { 0,0,0,1,1,0,1,1,0,0,0 },
}
local DRONE_F2 = {
    { 0,0,1,0,0,0,0,0,1,0,0 },
    { 1,0,0,1,0,0,0,1,0,0,1 },
    { 1,0,1,1,1,1,1,1,1,0,1 },
    { 1,1,1,0,1,1,1,0,1,1,1 },
    { 1,1,1,1,1,1,1,1,1,1,1 },
    { 0,1,1,1,1,1,1,1,1,1,0 },
    { 0,0,1,0,0,0,0,0,1,0,0 },
    { 0,1,0,0,0,0,0,0,0,1,0 },
}

-- SPINNER (8×8) — squid / jellyfish invader
local SPINNER_F1 = {
    { 0,0,0,1,1,0,0,0 },
    { 0,0,1,1,1,1,0,0 },
    { 0,1,1,1,1,1,1,0 },
    { 1,1,0,1,1,0,1,1 },
    { 1,1,1,1,1,1,1,1 },
    { 0,0,1,0,0,1,0,0 },
    { 0,1,0,1,1,0,1,0 },
    { 1,0,1,0,0,1,0,1 },
}
local SPINNER_F2 = {
    { 0,0,0,1,1,0,0,0 },
    { 0,0,1,1,1,1,0,0 },
    { 0,1,1,1,1,1,1,0 },
    { 1,1,0,1,1,0,1,1 },
    { 1,1,1,1,1,1,1,1 },
    { 0,1,0,1,1,0,1,0 },
    { 1,0,0,0,0,0,0,1 },
    { 0,1,0,0,0,0,1,0 },
}

-- TURRET (11×8) — UFO / shield type
local TURRET_F1 = {
    { 0,0,0,0,1,1,1,0,0,0,0 },
    { 0,1,1,1,1,1,1,1,1,1,0 },
    { 1,1,1,1,1,1,1,1,1,1,1 },
    { 1,1,1,0,1,1,1,0,1,1,1 },
    { 1,1,1,1,1,1,1,1,1,1,1 },
    { 0,0,0,1,0,1,0,1,0,0,0 },
    { 0,0,1,0,1,0,1,0,1,0,0 },
    { 0,1,0,1,0,0,0,1,0,1,0 },
}
local TURRET_F2 = {
    { 0,0,0,0,1,1,1,0,0,0,0 },
    { 0,1,1,1,1,1,1,1,1,1,0 },
    { 1,1,1,1,1,1,1,1,1,1,1 },
    { 1,1,1,0,1,1,1,0,1,1,1 },
    { 1,1,1,1,1,1,1,1,1,1,1 },
    { 0,0,1,0,1,0,1,0,1,0,0 },
    { 0,1,0,1,0,0,0,1,0,1,0 },
    { 1,0,1,0,0,0,0,0,1,0,1 },
}

-- WEAVER (11×8) — angular / spiky invader
local WEAVER_F1 = {
    { 0,0,0,0,1,0,1,0,0,0,0 },
    { 0,0,0,0,0,1,0,0,0,0,0 },
    { 0,0,0,1,1,1,1,1,0,0,0 },
    { 0,0,1,1,0,1,0,1,1,0,0 },
    { 0,1,1,1,1,1,1,1,1,1,0 },
    { 1,0,1,1,1,1,1,1,1,0,1 },
    { 1,0,1,0,0,0,0,0,1,0,1 },
    { 0,0,0,1,0,0,0,1,0,0,0 },
}
local WEAVER_F2 = {
    { 0,0,0,0,1,0,1,0,0,0,0 },
    { 0,0,0,0,0,1,0,0,0,0,0 },
    { 0,0,0,1,1,1,1,1,0,0,0 },
    { 0,0,1,1,0,1,0,1,1,0,0 },
    { 0,1,1,1,1,1,1,1,1,1,0 },
    { 1,0,1,1,1,1,1,1,1,0,1 },
    { 1,0,0,1,0,0,0,1,0,0,1 },
    { 0,0,1,0,0,0,0,0,1,0,0 },
}

-- HEAVY (13×10) — big boss invader
local HEAVY_F1 = {
    { 0,0,0,0,0,1,1,1,0,0,0,0,0 },
    { 0,0,0,1,1,1,1,1,1,1,0,0,0 },
    { 0,0,1,1,1,1,1,1,1,1,1,0,0 },
    { 0,1,1,0,0,1,1,1,0,0,1,1,0 },
    { 1,1,1,1,1,1,1,1,1,1,1,1,1 },
    { 1,0,0,1,1,0,1,0,1,1,0,0,1 },
    { 1,0,1,1,1,1,1,1,1,1,1,0,1 },
    { 0,0,0,1,0,0,0,0,0,1,0,0,0 },
    { 0,0,1,0,1,0,0,0,1,0,1,0,0 },
    { 0,1,0,1,0,0,0,0,0,1,0,1,0 },
}
local HEAVY_F2 = {
    { 0,0,0,0,0,1,1,1,0,0,0,0,0 },
    { 0,0,0,1,1,1,1,1,1,1,0,0,0 },
    { 0,0,1,1,1,1,1,1,1,1,1,0,0 },
    { 0,1,1,0,0,1,1,1,0,0,1,1,0 },
    { 1,1,1,1,1,1,1,1,1,1,1,1,1 },
    { 1,0,0,1,1,0,1,0,1,1,0,0,1 },
    { 1,0,1,1,1,1,1,1,1,1,1,0,1 },
    { 0,0,1,0,1,0,0,0,1,0,1,0,0 },
    { 0,1,0,1,0,0,0,0,0,1,0,1,0 },
    { 1,0,0,0,0,0,0,0,0,0,0,0,1 },
}

--------------------------------------------------------------------------------
-- Build an Image from a pixel grid and base color.
-- Each filled pixel becomes the given color; empty pixels are transparent.
-- Returns the Image plus its pixel dimensions (w, h).
--------------------------------------------------------------------------------
local function buildImage(grid, cr, cg, cb)
    local h = #grid
    local w = #grid[1]
    local imgData = love.image.newImageData(w, h)

    for row = 1, h do
        for col = 1, w do
            if grid[row][col] == 1 then
                imgData:setPixel(col - 1, row - 1, cr, cg, cb, 1)
            else
                imgData:setPixel(col - 1, row - 1, 0, 0, 0, 0)
            end
        end
    end

    local img = love.graphics.newImage(imgData)
    img:setFilter("nearest", "nearest")  -- crisp pixel art scaling
    return img, w, h
end

--------------------------------------------------------------------------------
-- Build a "white" silhouette version for damage flash
--------------------------------------------------------------------------------
local function buildFlashImage(grid)
    return buildImage(grid, 1, 1, 1)
end

--------------------------------------------------------------------------------
-- Sprite definition table:  sprites[typeName] = { frames, flashFrames, w, h, scale }
-- `scale` is chosen so the rendered size roughly matches the enemy's radius × 2.
--------------------------------------------------------------------------------

function Sprites.load()
    local data = {}

    local function register(name, f1Grid, f2Grid, cr, cg, cb, targetSize)
        local img1, w, h = buildImage(f1Grid, cr, cg, cb)
        local img2       = buildImage(f2Grid, cr, cg, cb)
        local flash1     = buildFlashImage(f1Grid)
        local flash2     = buildFlashImage(f2Grid)
        local scale      = targetSize / math.max(w, h)

        data[name] = {
            frames      = { img1, img2 },
            flashFrames = { flash1, flash2 },
            w = w, h = h,
            scale = scale,
        }
    end

    --                name       frame1       frame2       R    G    B    target px
    register("drone",   DRONE_F1,   DRONE_F2,   0.9, 0.35, 0.25,  28)
    register("spinner", SPINNER_F1, SPINNER_F2, 0.35, 0.9,  0.45,  36)
    register("turret",  TURRET_F1,  TURRET_F2,  0.85, 0.85, 0.25,  40)
    register("weaver",  WEAVER_F1,  WEAVER_F2,  0.45, 0.45, 1.0,   28)
    register("heavy",   HEAVY_F1,   HEAVY_F2,   0.75, 0.25, 0.75,  52)

    Sprites.data = data
end

--------------------------------------------------------------------------------
-- Draw a sprite centered at (x, y).
--   typeName : enemy type key
--   age      : elapsed time (used to pick animation frame)
--   flash    : if true, draw the white silhouette (damage flash)
--------------------------------------------------------------------------------
function Sprites.draw(typeName, x, y, age, flash)
    local s = Sprites.data[typeName]
    if not s then return end

    -- Alternate frames ~3× per second for the classic wobble
    local frameIdx = (math.floor((age or 0) * 3) % 2) + 1
    local img
    if flash then
        img = s.flashFrames[frameIdx]
    else
        img = s.frames[frameIdx]
    end

    local sc = s.scale
    local drawW = s.w * sc
    local drawH = s.h * sc
    love.graphics.draw(img, x - drawW / 2, y - drawH / 2, 0, sc, sc)
end

--- Return the drawn size for a type (useful for health bar positioning)
function Sprites.getSize(typeName)
    local s = Sprites.data[typeName]
    if not s then return 0, 0 end
    return s.w * s.scale, s.h * s.scale
end

return Sprites
