-- bullet.lua
-- Enemy bullet pool.  Simple flat table for performance.
-- Player weapon is a hitscan beam (handled in player.lua), not a bullet.

local Utils = require("utils")

local Bullets = {}
Bullets.__index = Bullets

function Bullets.new()
    local self = setmetatable({}, Bullets)
    self.list = {}
    return self
end

function Bullets:spawn(opts)
    table.insert(self.list, {
        x    = opts.x,
        y    = opts.y,
        vx   = opts.vx or 0,
        vy   = opts.vy or 0,
        ax   = opts.ax or 0,
        ay   = opts.ay or 0,
        spin = opts.spin or 0,
        radius = opts.radius or 3,
        r    = opts.r or 1,
        g    = opts.g or 0.3,
        b    = opts.b or 0.3,
        life = opts.life or 12,
        age  = 0,
        grazed = false,
        dead = false,
    })
end

function Bullets:update(dt, arena)
    for _, b in ipairs(self.list) do
        if not b.dead then
            -- Spin
            if b.spin ~= 0 then
                local a = b.spin * dt
                local c, s = math.cos(a), math.sin(a)
                b.vx, b.vy = b.vx * c - b.vy * s, b.vx * s + b.vy * c
            end
            -- Acceleration
            b.vx = b.vx + b.ax * dt
            b.vy = b.vy + b.ay * dt
            -- Position
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            b.age = b.age + dt
            -- Remove if off-arena (generous margin) or expired
            local m = 80
            if b.x < arena.x - m or b.x > arena.x + arena.w + m
            or b.y < arena.y - m or b.y > arena.y + arena.h + m
            or b.age > b.life then
                b.dead = true
            end
        end
    end
    if #self.list > 600 then Utils.sweep(self.list) end
end

function Bullets:draw(timeScale)
    local slow = timeScale < 0.5
    for _, b in ipairs(self.list) do
        if not b.dead then
            -- Glow
            love.graphics.setColor(b.r, b.g, b.b, 0.25)
            love.graphics.circle("fill", b.x, b.y, b.radius * 2.2)
            -- Motion trail during slow-mo
            if slow then
                local speed = math.sqrt(b.vx * b.vx + b.vy * b.vy)
                if speed > 10 then
                    local nx, ny = b.vx / speed, b.vy / speed
                    local tailLen = math.min(speed * 0.04, 14)
                    love.graphics.setColor(b.r, b.g, b.b, 0.18)
                    love.graphics.setLineWidth(b.radius * 1.5)
                    love.graphics.line(b.x, b.y, b.x - nx * tailLen, b.y - ny * tailLen)
                    love.graphics.setLineWidth(1)
                end
            end
            -- Core
            love.graphics.setColor(b.r, b.g, b.b, 0.9)
            love.graphics.circle("fill", b.x, b.y, b.radius)
            -- Bright center
            love.graphics.setColor(1, 1, 1, 0.55)
            love.graphics.circle("fill", b.x, b.y, b.radius * 0.4)
        end
    end
end

function Bullets:count()
    local n = 0
    for _, b in ipairs(self.list) do if not b.dead then n = n + 1 end end
    return n
end

--- Clear all bullets (mercy clear).
function Bullets:clear()
    for _, b in ipairs(self.list) do b.dead = true end
end

--- Clear bullets within radius of a point.
function Bullets:clearRadius(cx, cy, radius)
    local r2 = radius * radius
    for _, b in ipairs(self.list) do
        if not b.dead then
            local dx, dy = b.x - cx, b.y - cy
            if dx * dx + dy * dy <= r2 then b.dead = true end
        end
    end
end

return Bullets
