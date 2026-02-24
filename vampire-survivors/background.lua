-- background.lua
-- Infinite tiled ground with subtle colour variation so the player
-- can perceive movement across the world plane.

local Background = {}
Background.__index = Background

local TILE = 64  -- tile size in pixels

-- Pre-compute a small palette of ground colours for variety.
local COLOURS = {
    { 0.12, 0.16, 0.10 },
    { 0.14, 0.18, 0.11 },
    { 0.11, 0.15, 0.09 },
    { 0.13, 0.17, 0.10 },
}

function Background.new()
    return setmetatable({}, Background)
end

function Background:draw(camX, camY, screenW, screenH)
    -- Determine the visible tile range.
    local left   = math.floor((camX - screenW / 2) / TILE) - 1
    local right  = math.floor((camX + screenW / 2) / TILE) + 1
    local top    = math.floor((camY - screenH / 2) / TILE) - 1
    local bottom = math.floor((camY + screenH / 2) / TILE) + 1

    for ty = top, bottom do
        for tx = left, right do
            -- Deterministic colour from tile coords (cheap hash).
            local ci = ((tx * 7 + ty * 13) % #COLOURS) + 1
            local c  = COLOURS[ci]
            love.graphics.setColor(c[1], c[2], c[3], 1)
            love.graphics.rectangle("fill", tx * TILE, ty * TILE, TILE, TILE)
        end
    end

    -- Subtle grid lines
    love.graphics.setColor(0.18, 0.22, 0.15, 0.35)
    for ty = top, bottom do
        for tx = left, right do
            love.graphics.rectangle("line", tx * TILE, ty * TILE, TILE, TILE)
        end
    end
end

return Background
