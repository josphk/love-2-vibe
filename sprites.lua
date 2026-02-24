-- sprites.lua
-- Procedural pixel-art sprites for the player character.
-- Enemies use geometric shapes (drawn in enemy.lua) for a clean look.

local Sprites = {}
Sprites.data = {}

local _ = 0

local function buildImage(grid, palette)
    local h, w = #grid, #grid[1]
    local img = love.image.newImageData(w, h)
    for r = 1, h do
        for c = 1, w do
            local idx = grid[r][c]
            if idx > 0 then
                local cl = palette[idx]
                img:setPixel(c - 1, r - 1, cl[1], cl[2], cl[3], 1)
            else
                img:setPixel(c - 1, r - 1, 0, 0, 0, 0)
            end
        end
    end
    local i = love.graphics.newImage(img)
    i:setFilter("nearest", "nearest")
    return i, w, h
end

--------------------------------------------------------------------------------
-- Player  (9×9 top-down character)
--------------------------------------------------------------------------------
local P_PAL = {
    { 0.15, 0.15, 0.20 },  -- 1 dark outline / boots
    { 0.85, 0.72, 0.55 },  -- 2 skin
    { 0.25, 0.35, 0.70 },  -- 3 dark blue armor
    { 0.40, 0.55, 0.90 },  -- 4 light blue armor
    { 0.90, 0.30, 0.20 },  -- 5 red accent (cape/scarf)
}
local P_F1 = {
    { _,_,_,1,1,1,_,_,_ },
    { _,_,1,2,2,2,1,_,_ },
    { _,_,1,2,2,2,1,_,_ },
    { _,5,3,4,4,4,3,5,_ },
    { _,5,3,4,4,4,3,5,_ },
    { _,_,3,4,4,4,3,_,_ },
    { _,_,_,3,3,3,_,_,_ },
    { _,_,1,_,_,_,1,_,_ },
    { _,1,1,_,_,_,1,1,_ },
}
local P_F2 = {
    { _,_,_,1,1,1,_,_,_ },
    { _,_,1,2,2,2,1,_,_ },
    { _,_,1,2,2,2,1,_,_ },
    { _,5,3,4,4,4,3,5,_ },
    { _,5,3,4,4,4,3,5,_ },
    { _,_,3,4,4,4,3,_,_ },
    { _,_,_,3,3,3,_,_,_ },
    { _,1,_,_,_,_,_,1,_ },
    { _,1,_,_,_,_,_,1,_ },
}

function Sprites.load()
    local function reg(name, f1, f2, pal, targetPx)
        local img1, w, h = buildImage(f1, pal)
        local img2 = buildImage(f2, pal)
        local sc = targetPx / math.max(w, h)
        Sprites.data[name] = { frames = {img1, img2}, w = w, h = h, scale = sc }
    end
    reg("player", P_F1, P_F2, P_PAL, 32)
end

function Sprites.draw(name, x, y, age, facing)
    local s = Sprites.data[name]; if not s then return end
    local fi = (math.floor((age or 0) * 4) % 2) + 1
    local sc = s.scale
    facing = facing or 1
    love.graphics.draw(s.frames[fi], x, y, 0, sc * facing, sc, s.w / 2, s.h / 2)
end

return Sprites
