-- gem.lua
-- Pickups on ground. Types: "timer" (speed up card timer), "instant" (instantly play top card).
-- Spawn from enemy deaths; collect by player overlap. Draw in world space (code-drawn).

local Map = require("map")

local Gem = {}
Gem.list = {}

local PICKUP_R = 0.35   -- grid units (player overlap to collect)

-- Tuning: drop chance is applied in main when enemy dies (e.g. 0.25 = 25%)

--- Spawn a gem at grid position. gemType is "timer" or "instant".
function Gem.spawn(x, y, gemType)
    table.insert(Gem.list, {
        x = x,
        y = y,
        type = gemType or (math.random(2) == 1 and "timer" or "instant"),
        radius = PICKUP_R,
    })
end

--- Draw all gems (call inside camera transform, after entities).
function Gem.draw()
    for _, g in ipairs(Gem.list) do
        local sx, sy = Map.gridToScreen(g.x, g.y)
        if g.type == "timer" then
            -- Diamond (speed-up timer)
            local size = 8
            love.graphics.setColor(0.4, 0.9, 1.0, 0.95)
            love.graphics.polygon("fill",
                sx, sy - size,
                sx + size, sy,
                sx, sy + size,
                sx - size, sy)
            love.graphics.setColor(0.6, 1.0, 1.0, 1)
            love.graphics.polygon("line",
                sx, sy - size,
                sx + size, sy,
                sx, sy + size,
                sx - size, sy)
        else
            -- Circle (instant play)
            love.graphics.setColor(1.0, 0.85, 0.2, 0.95)
            love.graphics.circle("fill", sx, sy, 10)
            love.graphics.setColor(1.0, 0.95, 0.5, 1)
            love.graphics.circle("line", sx, sy, 10)
        end
    end
end

--- Remove gem at index (call from main when collected).
function Gem.remove(i)
    table.remove(Gem.list, i)
end

return Gem
