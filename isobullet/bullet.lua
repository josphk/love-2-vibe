-- bullet.lua
-- Enemy bullet pool with wall reflection.
-- Bullets move in grid-space and bounce off walls up to maxBounces times.
-- A brief wall-immunity timer prevents bullets from reflecting on spawn.

local Map   = require("map")
local Utils = require("utils")

local Bullets = {}
Bullets.__index = Bullets

local PIXEL_SCALE = Map.TILE_W / 2   -- grid-unit → pixel conversion for draw

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
        radius     = opts.radius or 0.12,      -- grid units (collision)
        r    = opts.r or 1,
        g    = opts.g or 0.3,
        b    = opts.b or 0.3,
        life = opts.life or 15,
        age  = 0,
        maxBounces       = opts.maxBounces or 2,
        bounces          = 0,
        wallImmuneTimer  = opts.wallImmune or 0.15,   -- ignore walls briefly
        grazed = false,
        dead   = false,
    })
end

--- Update all bullets.  onBounce(gx, gy, r, g, b) callback fires on each reflection.
function Bullets:update(dt, onBounce)
    for _, b in ipairs(self.list) do
        if not b.dead then
            -- Spin (rotate velocity)
            if b.spin ~= 0 then
                local a = b.spin * dt
                local c, s = math.cos(a), math.sin(a)
                b.vx, b.vy = b.vx * c - b.vy * s, b.vx * s + b.vy * c
            end
            -- Acceleration
            b.vx = b.vx + b.ax * dt
            b.vy = b.vy + b.ay * dt
            -- Save previous position
            local prevX, prevY = b.x, b.y
            -- Move
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            b.age = b.age + dt

            -- Wall-immunity countdown
            if b.wallImmuneTimer > 0 then
                b.wallImmuneTimer = b.wallImmuneTimer - dt
            elseif Map.isWall(b.x, b.y) then
                -- REFLECT or die
                if b.bounces >= b.maxBounces then
                    b.dead = true
                else
                    -- Axis-separation: determine which component(s) hit a wall
                    local wallInX = Map.isWall(b.x, prevY)
                    local wallInY = Map.isWall(prevX, b.y)
                    if wallInX and not wallInY then
                        b.vx = -b.vx
                    elseif wallInY and not wallInX then
                        b.vy = -b.vy
                    else
                        b.vx = -b.vx
                        b.vy = -b.vy
                    end
                    -- Revert to safe position
                    b.x = prevX
                    b.y = prevY
                    b.bounces = b.bounces + 1
                    if onBounce then onBounce(b.x, b.y, b.r, b.g, b.b) end
                end
            end

            -- Out-of-bounds or expired
            if b.x < 0 or b.x > Map.GW + 1
            or b.y < 0 or b.y > Map.GH + 1
            or b.age > b.life then
                b.dead = true
            end
        end
    end
    -- Sweep dead bullets periodically
    if #self.list > 800 then Utils.sweep(self.list) end
end

function Bullets:draw(timeScale)
    local slow = timeScale < 0.5
    for _, b in ipairs(self.list) do
        if not b.dead then
            local sx, sy = Map.gridToScreen(b.x, b.y)
            local pr = math.max(2, b.radius * PIXEL_SCALE)   -- pixel radius

            -- Dim with bounces
            local alpha = 1.0 - b.bounces * 0.15

            -- Glow halo
            love.graphics.setColor(b.r, b.g, b.b, 0.2 * alpha)
            love.graphics.circle("fill", sx, sy, pr * 2.5)

            -- Motion trail during slow-mo
            if slow then
                local speed = math.sqrt(b.vx * b.vx + b.vy * b.vy)
                if speed > 1 then
                    local nx, ny = b.vx / speed, b.vy / speed
                    local tailLen = math.min(speed * 0.06, 0.5)
                    local tx, ty = b.x - nx * tailLen, b.y - ny * tailLen
                    local tsx, tsy = Map.gridToScreen(tx, ty)
                    love.graphics.setColor(b.r, b.g, b.b, 0.15 * alpha)
                    love.graphics.setLineWidth(pr * 1.8)
                    love.graphics.line(sx, sy, tsx, tsy)
                    love.graphics.setLineWidth(1)
                end
            end

            -- Core
            love.graphics.setColor(b.r, b.g, b.b, 0.85 * alpha)
            love.graphics.circle("fill", sx, sy, pr)

            -- Bright center
            love.graphics.setColor(1, 1, 1, 0.5 * alpha)
            love.graphics.circle("fill", sx, sy, pr * 0.4)

            -- Bounce indicator ring
            if b.bounces > 0 then
                love.graphics.setColor(1, 1, 0.5, 0.25)
                love.graphics.circle("line", sx, sy, pr * 1.6)
            end
        end
    end
end

function Bullets:count()
    local n = 0
    for _, b in ipairs(self.list) do if not b.dead then n = n + 1 end end
    return n
end

function Bullets:clear()
    for _, b in ipairs(self.list) do b.dead = true end
end

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
