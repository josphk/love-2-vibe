-- patterns.lua
-- Bullet pattern generators for enemies.
-- All positions and velocities are in grid-space units.

local Utils = require("utils")

local Patterns = {}

--- Evenly spaced radial ring.
function Patterns.radialBurst(pool, e, opts)
    opts = opts or {}
    local count  = opts.count  or 16
    local speed  = opts.speed  or 5.5
    local offset = opts.offset or 0
    local r, g, b = opts.r or e.cr, opts.g or e.cg, opts.b or e.cb
    for i = 1, count do
        local a = offset + (i / count) * math.pi * 2
        pool:spawn({
            x = e.x, y = e.y,
            vx = math.cos(a) * speed, vy = math.sin(a) * speed,
            r = r, g = g, b = b,
            radius = opts.radius or 0.12,
            maxBounces = opts.maxBounces or 2,
        })
    end
end

--- Aimed burst toward a target position.
function Patterns.aimedBurst(pool, e, tx, ty, opts)
    opts = opts or {}
    local count  = opts.count  or 5
    local speed  = opts.speed  or 7.5
    local spread = opts.spread or 0.35
    local r, g, b = opts.r or e.cr, opts.g or e.cg, opts.b or e.cb
    local base = Utils.angleTo(e.x, e.y, tx, ty)
    for i = 1, count do
        local a = base + (i - (count + 1) / 2) * (spread / count)
        pool:spawn({
            x = e.x, y = e.y,
            vx = math.cos(a) * speed, vy = math.sin(a) * speed,
            r = r, g = g, b = b,
            radius = opts.radius or 0.12,
            maxBounces = opts.maxBounces or 2,
        })
    end
end

--- Continuous rotating spiral arms.
function Patterns.spiral(pool, e, opts)
    opts = opts or {}
    local arms   = opts.arms   or 3
    local speed  = opts.speed  or 4.5
    local offset = opts.offset or 0
    local r, g, b = opts.r or e.cr, opts.g or e.cg, opts.b or e.cb
    for i = 1, arms do
        local a = offset + (i / arms) * math.pi * 2
        pool:spawn({
            x = e.x, y = e.y,
            vx = math.cos(a) * speed, vy = math.sin(a) * speed,
            r = r, g = g, b = b,
            radius = opts.radius or 0.12,
            maxBounces = opts.maxBounces or 2,
        })
    end
end

--- Expanding ring with acceleration.
function Patterns.expandRing(pool, e, opts)
    opts = opts or {}
    local count = opts.count or 20
    local speed = opts.speed or 1.2
    local accel = opts.accel or 5.0
    local r, g, b = opts.r or e.cr, opts.g or e.cg, opts.b or e.cb
    for i = 1, count do
        local a = (i / count) * math.pi * 2
        pool:spawn({
            x = e.x, y = e.y,
            vx = math.cos(a) * speed, vy = math.sin(a) * speed,
            ax = math.cos(a) * accel, ay = math.sin(a) * accel,
            r = r, g = g, b = b,
            radius = opts.radius or 0.14,
            life = 5,
            maxBounces = opts.maxBounces or 2,
        })
    end
end

--- Shotgun spread aimed at target.
function Patterns.shotgun(pool, e, tx, ty, opts)
    opts = opts or {}
    local count = opts.count or 10
    local speed = opts.speed or 8.0
    local r, g, b = opts.r or e.cr, opts.g or e.cg, opts.b or e.cb
    local base = Utils.angleTo(e.x, e.y, tx, ty)
    for _ = 1, count do
        local a = base + (math.random() - 0.5) * 0.6
        local s = speed * (0.6 + math.random() * 0.5)
        pool:spawn({
            x = e.x, y = e.y,
            vx = math.cos(a) * s, vy = math.sin(a) * s,
            r = r, g = g, b = b,
            radius = opts.radius or 0.12,
            maxBounces = opts.maxBounces or 2,
        })
    end
end

--- Spinning spiral with angular velocity on bullets.
function Patterns.spinSpiral(pool, e, opts)
    opts = opts or {}
    local arms = opts.arms or 4
    local speed = opts.speed or 4.0
    local spinRate = opts.spin or 1.8
    local offset = opts.offset or 0
    local r, g, b = opts.r or e.cr, opts.g or e.cg, opts.b or e.cb
    for i = 1, arms do
        local a = offset + (i / arms) * math.pi * 2
        pool:spawn({
            x = e.x, y = e.y,
            vx = math.cos(a) * speed, vy = math.sin(a) * speed,
            spin = spinRate, life = 6,
            r = r, g = g, b = b,
            radius = opts.radius or 0.12,
            maxBounces = opts.maxBounces or 2,
        })
    end
end

--- Cross pattern (4 directional streams).
function Patterns.cross(pool, e, opts)
    opts = opts or {}
    local speed  = opts.speed  or 6.5
    local offset = opts.offset or 0
    local r, g, b = opts.r or e.cr, opts.g or e.cg, opts.b or e.cb
    for _, d in ipairs({ 0, math.pi / 2, math.pi, 3 * math.pi / 2 }) do
        local a = d + offset
        pool:spawn({
            x = e.x, y = e.y,
            vx = math.cos(a) * speed, vy = math.sin(a) * speed,
            r = r, g = g, b = b,
            radius = opts.radius or 0.12,
            maxBounces = opts.maxBounces or 2,
        })
    end
end

return Patterns
