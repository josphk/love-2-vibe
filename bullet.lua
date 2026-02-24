-- bullet.lua
-- Bullet pool: handles creation, update, drawing, and removal of all bullets.
-- Bullets are simple tables stored in flat arrays for performance.

local Utils = require("utils")

local BulletPool = {}
BulletPool.__index = BulletPool

--------------------------------------------------------------------------------
-- Bullet types – visual style & radius
--------------------------------------------------------------------------------
local TYPES = {
    small   = { radius = 3,  r = 1.0, g = 0.3, b = 0.3 },
    medium  = { radius = 5,  r = 1.0, g = 0.6, b = 0.1 },
    large   = { radius = 8,  r = 0.9, g = 0.2, b = 0.9 },
    ring    = { radius = 6,  r = 0.3, g = 1.0, b = 0.5 },
    star    = { radius = 5,  r = 1.0, g = 1.0, b = 0.3 },
    player  = { radius = 4,  r = 0.4, g = 0.8, b = 1.0 },
}

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function BulletPool.new(screenW, screenH)
    local self = setmetatable({}, BulletPool)
    self.enemy  = {}   -- bullets fired by enemies
    self.player = {}   -- bullets fired by the player
    self.screenW = screenW
    self.screenH = screenH
    return self
end

--------------------------------------------------------------------------------
-- Spawn helpers
--------------------------------------------------------------------------------

--- Spawn a single enemy bullet.
-- @param opts table { x, y, vx, vy, btype, ax, ay, life, spin, callback }
function BulletPool.spawnEnemy(self, opts)
    local btype = TYPES[opts.btype or "small"]
    table.insert(self.enemy, {
        x      = opts.x,
        y      = opts.y,
        vx     = opts.vx or 0,
        vy     = opts.vy or 0,
        ax     = opts.ax or 0,       -- acceleration x
        ay     = opts.ay or 0,       -- acceleration y
        radius = btype.radius,
        r      = opts.r or btype.r,
        g      = opts.g or btype.g,
        b      = opts.b or btype.b,
        life   = opts.life or 999,   -- auto-remove after N seconds
        age    = 0,
        spin   = opts.spin or 0,     -- angular velocity (rad/s) applied to direction
        callback = opts.callback,    -- optional per-frame function(bullet, dt)
        grazed = false,              -- has this bullet been grazed already?
        dead   = false,
    })
end

--- Spawn a player bullet.
function BulletPool.spawnPlayer(self, opts)
    local btype = TYPES["player"]
    table.insert(self.player, {
        x      = opts.x,
        y      = opts.y,
        vx     = opts.vx or 0,
        vy     = opts.vy or 0,
        radius = btype.radius,
        r      = btype.r,
        g      = btype.g,
        b      = btype.b,
        damage = opts.damage or 1,
        dead   = false,
    })
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function BulletPool.update(self, dt)
    -- Update enemy bullets
    for _, b in ipairs(self.enemy) do
        if not b.dead then
            -- Custom behaviour callback
            if b.callback then
                b.callback(b, dt)
            end

            -- Spin: rotate velocity vector
            if b.spin ~= 0 then
                local angle = b.spin * dt
                local cos, sin = math.cos(angle), math.sin(angle)
                local nvx = b.vx * cos - b.vy * sin
                local nvy = b.vx * sin + b.vy * cos
                b.vx = nvx
                b.vy = nvy
            end

            -- Acceleration
            b.vx = b.vx + b.ax * dt
            b.vy = b.vy + b.ay * dt

            -- Position
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            b.age = b.age + dt

            -- Remove if off-screen (generous margin) or expired
            local margin = 60
            if b.x < -margin or b.x > self.screenW + margin
            or b.y < -margin or b.y > self.screenH + margin
            or b.age > b.life then
                b.dead = true
            end
        end
    end

    -- Update player bullets
    for _, b in ipairs(self.player) do
        if not b.dead then
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            if b.y < -20 or b.y > self.screenH + 20
            or b.x < -20 or b.x > self.screenW + 20 then
                b.dead = true
            end
        end
    end

    -- Sweep dead bullets periodically to keep arrays compact
    if #self.enemy > 500 then Utils.sweep(self.enemy) end
    if #self.player > 200 then Utils.sweep(self.player) end
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------
function BulletPool.draw(self)
    -- Enemy bullets
    for _, b in ipairs(self.enemy) do
        if not b.dead then
            -- Outer glow
            love.graphics.setColor(b.r, b.g, b.b, 0.35)
            love.graphics.circle("fill", b.x, b.y, b.radius * 1.8)
            -- Core
            love.graphics.setColor(b.r, b.g, b.b, 0.95)
            love.graphics.circle("fill", b.x, b.y, b.radius)
            -- Bright center
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.circle("fill", b.x, b.y, b.radius * 0.45)
        end
    end

    -- Player bullets
    for _, b in ipairs(self.player) do
        if not b.dead then
            love.graphics.setColor(b.r, b.g, b.b, 0.9)
            love.graphics.rectangle("fill", b.x - 2, b.y - 6, 4, 12, 1, 1)
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.rectangle("fill", b.x - 1, b.y - 6, 2, 12, 1, 1)
        end
    end
end

--------------------------------------------------------------------------------
-- Clear all enemy bullets (bomb effect)
--------------------------------------------------------------------------------
function BulletPool.clearEnemy(self)
    for _, b in ipairs(self.enemy) do
        b.dead = true
    end
end

--------------------------------------------------------------------------------
-- Count active bullets (for HUD / debug)
--------------------------------------------------------------------------------
function BulletPool.countEnemy(self)
    local n = 0
    for _, b in ipairs(self.enemy) do
        if not b.dead then n = n + 1 end
    end
    return n
end

return BulletPool
