-- patterns.lua
-- Bullet pattern generators.  Each function takes (bulletPool, enemy, playerX, playerY)
-- and spawns bullets via bulletPool:spawnEnemy(...).

local Utils = require("utils")

local Patterns = {}

--------------------------------------------------------------------------------
-- 1. RADIAL BURST – evenly-spaced ring of bullets
--------------------------------------------------------------------------------
function Patterns.radialBurst(pool, e, px, py, opts)
    opts = opts or {}
    local count  = opts.count  or 24
    local speed  = opts.speed  or 160
    local btype  = opts.btype  or "small"
    local offset = opts.offset or 0   -- angular offset in radians

    for i = 1, count do
        local angle = offset + (i / count) * math.pi * 2
        pool:spawnEnemy({
            x = e.x, y = e.y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            btype = btype,
        })
    end
end

--------------------------------------------------------------------------------
-- 2. AIMED BURST – cluster of bullets aimed at the player
--------------------------------------------------------------------------------
function Patterns.aimedBurst(pool, e, px, py, opts)
    opts = opts or {}
    local count  = opts.count  or 5
    local speed  = opts.speed  or 200
    local spread = opts.spread or 0.35  -- radians of total spread
    local btype  = opts.btype  or "medium"

    local baseAngle = Utils.angleTo(e.x, e.y, px, py)
    for i = 1, count do
        local a = baseAngle + (i - (count + 1) / 2) * (spread / count)
        pool:spawnEnemy({
            x = e.x, y = e.y,
            vx = math.cos(a) * speed,
            vy = math.sin(a) * speed,
            btype = btype,
        })
    end
end

--------------------------------------------------------------------------------
-- 3. SPIRAL – continuous rotating stream
--------------------------------------------------------------------------------
function Patterns.spiral(pool, e, px, py, opts)
    opts = opts or {}
    local arms   = opts.arms   or 3
    local speed  = opts.speed  or 140
    local btype  = opts.btype  or "ring"
    local offset = opts.offset or 0

    for i = 1, arms do
        local angle = offset + (i / arms) * math.pi * 2
        pool:spawnEnemy({
            x = e.x, y = e.y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            btype = btype,
        })
    end
end

--------------------------------------------------------------------------------
-- 4. WAVE – sinusoidal curving bullets
--------------------------------------------------------------------------------
function Patterns.wave(pool, e, px, py, opts)
    opts = opts or {}
    local count  = opts.count  or 7
    local speed  = opts.speed  or 150
    local btype  = opts.btype  or "star"
    local freq   = opts.freq   or 5        -- oscillation frequency
    local amp    = opts.amp    or 120       -- oscillation amplitude (px/s)

    local baseAngle = Utils.angleTo(e.x, e.y, px, py)
    local spread = 0.6
    for i = 1, count do
        local a = baseAngle + (i - (count + 1) / 2) * (spread / count)
        local bvx = math.cos(a) * speed
        local bvy = math.sin(a) * speed
        -- perpendicular direction for oscillation
        local perpX = -math.sin(a)
        local perpY =  math.cos(a)
        local phase = i * 0.8  -- phase offset per bullet

        pool:spawnEnemy({
            x = e.x, y = e.y,
            vx = bvx, vy = bvy,
            btype = btype,
            callback = function(b, dt)
                -- Add sinusoidal perpendicular velocity
                local osc = math.sin(b.age * freq + phase) * amp
                b.vx = bvx + perpX * osc
                b.vy = bvy + perpY * osc
            end,
        })
    end
end

--------------------------------------------------------------------------------
-- 5. EXPANDING RING – ring that accelerates outward
--------------------------------------------------------------------------------
function Patterns.expandingRing(pool, e, px, py, opts)
    opts = opts or {}
    local count = opts.count or 36
    local speed = opts.speed or 40
    local accel = opts.accel or 180
    local btype = opts.btype or "large"

    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local dirx = math.cos(angle)
        local diry = math.sin(angle)
        pool:spawnEnemy({
            x = e.x, y = e.y,
            vx = dirx * speed,
            vy = diry * speed,
            ax = dirx * accel,
            ay = diry * accel,
            btype = btype,
            life = 4,
        })
    end
end

--------------------------------------------------------------------------------
-- 6. CROSS – four directional streams
--------------------------------------------------------------------------------
function Patterns.cross(pool, e, px, py, opts)
    opts = opts or {}
    local speed  = opts.speed  or 180
    local btype  = opts.btype  or "medium"
    local offset = opts.offset or 0

    local dirs = { 0, math.pi / 2, math.pi, 3 * math.pi / 2 }
    for _, d in ipairs(dirs) do
        local a = d + offset
        pool:spawnEnemy({
            x = e.x, y = e.y,
            vx = math.cos(a) * speed,
            vy = math.sin(a) * speed,
            btype = btype,
        })
    end
end

--------------------------------------------------------------------------------
-- 7. SPINNING SPIRAL – bullets with angular velocity (curved paths)
--------------------------------------------------------------------------------
function Patterns.spinSpiral(pool, e, px, py, opts)
    opts = opts or {}
    local arms   = opts.arms   or 5
    local speed  = opts.speed  or 110
    local spinRate = opts.spin or 1.5
    local btype  = opts.btype  or "ring"
    local offset = opts.offset or 0

    for i = 1, arms do
        local angle = offset + (i / arms) * math.pi * 2
        pool:spawnEnemy({
            x = e.x, y = e.y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            btype = btype,
            spin = spinRate,
            life = 6,
        })
    end
end

--------------------------------------------------------------------------------
-- 8. SHOTGUN – tight aimed cluster with speed variation
--------------------------------------------------------------------------------
function Patterns.shotgun(pool, e, px, py, opts)
    opts = opts or {}
    local count  = opts.count  or 12
    local speed  = opts.speed  or 220
    local btype  = opts.btype  or "small"

    local baseAngle = Utils.angleTo(e.x, e.y, px, py)
    for i = 1, count do
        local a = baseAngle + (math.random() - 0.5) * 0.5
        local s = speed * (0.7 + math.random() * 0.6)
        pool:spawnEnemy({
            x = e.x, y = e.y,
            vx = math.cos(a) * s,
            vy = math.sin(a) * s,
            btype = btype,
        })
    end
end

return Patterns
