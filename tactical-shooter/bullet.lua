-- bullet.lua
-- Bullet pool: add, update (move + wall collision), draw.

local Map = require("map")
local Utils = require("utils")

local Bullet = {}
Bullet.SPEED = 14
Bullet.list = {}

function Bullet.add(x, y, dx, dy, fromPlayer, damage)
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.01 then return end
    dx, dy = dx / len * Bullet.SPEED, dy / len * Bullet.SPEED
    table.insert(Bullet.list, {
        x = x, y = y, vx = dx, vy = dy,
        fromPlayer = fromPlayer,
        damage = damage or (fromPlayer and 28 or 12),
    })
end

function Bullet.update(dt)
    for i = #Bullet.list, 1, -1 do
        local b = Bullet.list[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if Map.isWall(b.x, b.y) then table.remove(Bullet.list, i) end
    end
end

function Bullet.draw()
    love.graphics.setColor(1, 0.9, 0.3)
    for _, b in ipairs(Bullet.list) do
        local sx, sy = Map.gridToScreen(b.x, b.y)
        love.graphics.circle("fill", sx, sy, 3)
    end
end

return Bullet
