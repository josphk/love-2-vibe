-- enemy.lua
-- Arena enemies that fire bullet patterns.
-- Each type has a shape (drawn geometrically), movement, and pattern schedule.

local Utils    = require("utils")
local Patterns = require("patterns")

local Enemy = {}
Enemy.__index = Enemy

--------------------------------------------------------------------------------
-- Type definitions
--------------------------------------------------------------------------------
local DEFS = {}

-- TURRET: stationary, aimed bursts
DEFS.turret = {
    hp = 30, radius = 16, score = 200,
    cr = 1.0, cg = 0.55, cb = 0.15,
    fireInterval = 1.8,
    shape = "diamond",
    pattern = function(self, pool, px, py)
        Patterns.aimedBurst(pool, self, px, py, { count = 5, speed = 180, spread = 0.4 })
    end,
    move = function(self, dt) end,  -- stationary
}

-- SPINNER: rotating spiral arms
DEFS.spinner = {
    hp = 50, radius = 18, score = 350,
    cr = 0.3, cg = 0.95, cb = 0.4,
    fireInterval = 0.10,
    shape = "circle",
    pattern = function(self, pool, px, py)
        Patterns.spiral(pool, self, { arms = 3, speed = 110, offset = self.age * 2.8 })
    end,
    move = function(self, dt)
        -- Gentle drift toward target position
        if self.targetX then
            self.x = Utils.lerp(self.x, self.targetX, dt * 0.8)
            self.y = Utils.lerp(self.y, self.targetY, dt * 0.8)
        end
    end,
}

-- ORBITER: moves in a circle, radial bursts
DEFS.orbiter = {
    hp = 25, radius = 14, score = 250,
    cr = 0.3, cg = 0.5, cb = 1.0,
    fireInterval = 1.5,
    shape = "circle",
    pattern = function(self, pool, px, py)
        Patterns.radialBurst(pool, self, { count = 16, speed = 130, offset = self.age })
    end,
    move = function(self, dt)
        local cx = self.orbitCX or 400
        local cy = self.orbitCY or 300
        local r  = self.orbitR  or 120
        self.orbitAngle = (self.orbitAngle or 0) + dt * 1.2
        self.x = cx + math.cos(self.orbitAngle) * r
        self.y = cy + math.sin(self.orbitAngle) * r
    end,
}

-- HEAVY: slow-moving, expanding rings + shotgun
DEFS.heavy = {
    hp = 80, radius = 24, score = 500,
    cr = 0.75, cg = 0.25, cb = 0.85,
    fireInterval = 1.4,
    shape = "hexagon",
    pattern = function(self, pool, px, py)
        if self.phase % 3 == 0 then
            Patterns.expandRing(pool, self, { count = 24, speed = 25, accel = 100 })
        elseif self.phase % 3 == 1 then
            Patterns.shotgun(pool, self, px, py, { count = 12, speed = 190 })
        else
            Patterns.spinSpiral(pool, self, { arms = 5, speed = 90, spin = 2.0, offset = self.age })
        end
        self.phase = self.phase + 1
    end,
    move = function(self, dt)
        if self.targetX then
            self.x = Utils.lerp(self.x, self.targetX, dt * 0.3)
            self.y = Utils.lerp(self.y, self.targetY, dt * 0.3)
        end
    end,
}

-- DASHER: fast, stops briefly to fire, then dashes again
DEFS.dasher = {
    hp = 20, radius = 12, score = 300,
    cr = 0.2, cg = 0.9, cb = 0.95,
    fireInterval = 0.7,
    shape = "triangle",
    pattern = function(self, pool, px, py)
        Patterns.aimedBurst(pool, self, px, py, { count = 7, speed = 210, spread = 0.5 })
    end,
    move = function(self, dt)
        self.dashTimer = (self.dashTimer or 0) - dt
        if self.dashTimer <= 0 then
            -- Pick new dash target
            local A = require("background").ARENA
            self.targetX = A.x + 60 + math.random() * (A.w - 120)
            self.targetY = A.y + 60 + math.random() * (A.h - 120)
            self.dashTimer = 1.5 + math.random() * 1.0
        end
        if self.targetX then
            local dx = self.targetX - self.x
            local dy = self.targetY - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 5 then
                local speed = 250
                self.x = self.x + (dx / dist) * speed * dt
                self.y = self.y + (dy / dist) * speed * dt
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Enemy.new(typeName, x, y)
    local def = DEFS[typeName]
    assert(def, "Unknown enemy: " .. tostring(typeName))
    local self = setmetatable({}, Enemy)
    self.typeName = typeName
    self.x, self.y = x, y
    self.hp = def.hp
    self.maxHp = def.hp
    self.radius = def.radius
    self.score = def.score
    self.cr, self.cg, self.cb = def.cr, def.cg, def.cb
    self.shape = def.shape
    self.patternFunc = def.pattern
    self.moveFunc = def.move
    self.fireInterval = def.fireInterval
    self.fireTimer = def.fireInterval * (0.3 + math.random() * 0.5)
    self.phase = 0
    self.age = 0
    self.dead = false
    self.hitFlash = 0

    -- Movement state
    self.targetX, self.targetY = nil, nil
    self.orbitCX, self.orbitCY = nil, nil
    self.orbitR = nil
    self.orbitAngle = math.random() * math.pi * 2
    self.dashTimer = 0

    return self
end

function Enemy:update(dt, bulletPool, playerX, playerY, arena)
    if self.dead then return end
    self.age = self.age + dt
    if self.hitFlash > 0 then self.hitFlash = self.hitFlash - dt end

    -- Movement
    self.moveFunc(self, dt)

    -- Clamp to arena
    self.x = Utils.clamp(self.x, arena.x + self.radius, arena.x + arena.w - self.radius)
    self.y = Utils.clamp(self.y, arena.y + self.radius, arena.y + arena.h - self.radius)

    -- Fire pattern
    self.fireTimer = self.fireTimer - dt
    if self.fireTimer <= 0 then
        self.fireTimer = self.fireInterval
        self.patternFunc(self, bulletPool, playerX, playerY)
    end
end

function Enemy:takeDamage(dmg)
    if self.dead then return false end
    self.hp = self.hp - dmg
    self.hitFlash = 0.12
    if self.hp <= 0 then self.dead = true; return true end
    return false
end

function Enemy:draw()
    if self.dead then return end

    local flash = self.hitFlash > 0
    local r, g, b = self.cr, self.cg, self.cb
    if flash then r, g, b = 1, 1, 1 end

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", self.x, self.y + self.radius * 0.6, self.radius * 0.9, self.radius * 0.35)

    -- Shape
    local rad = self.radius
    if self.shape == "diamond" then
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.polygon("fill",
            self.x, self.y - rad,
            self.x + rad, self.y,
            self.x, self.y + rad,
            self.x - rad, self.y)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.polygon("line",
            self.x, self.y - rad,
            self.x + rad, self.y,
            self.x, self.y + rad,
            self.x - rad, self.y)
    elseif self.shape == "circle" then
        love.graphics.setColor(r, g, b, 0.85)
        love.graphics.circle("fill", self.x, self.y, rad)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.circle("line", self.x, self.y, rad)
    elseif self.shape == "hexagon" then
        local pts = {}
        for i = 0, 5 do
            local a = (i / 6) * math.pi * 2 - math.pi / 6
            table.insert(pts, self.x + math.cos(a) * rad)
            table.insert(pts, self.y + math.sin(a) * rad)
        end
        love.graphics.setColor(r, g, b, 0.85)
        love.graphics.polygon("fill", pts)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.polygon("line", pts)
    elseif self.shape == "triangle" then
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.polygon("fill",
            self.x, self.y - rad,
            self.x + rad * 0.86, self.y + rad * 0.5,
            self.x - rad * 0.86, self.y + rad * 0.5)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.polygon("line",
            self.x, self.y - rad,
            self.x + rad * 0.86, self.y + rad * 0.5,
            self.x - rad * 0.86, self.y + rad * 0.5)
    end

    -- Inner glow
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.circle("fill", self.x, self.y, rad * 0.25)

    -- HP bar
    if self.hp < self.maxHp then
        local bw = rad * 2
        local bx = self.x - bw / 2
        local by = self.y - rad - 8
        love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", bx, by, bw, 3)
        love.graphics.setColor(0.2, 1, 0.2, 0.9)
        love.graphics.rectangle("fill", bx, by, bw * (self.hp / self.maxHp), 3)
    end
end

Enemy.TYPES = {}
for k in pairs(DEFS) do table.insert(Enemy.TYPES, k) end
table.sort(Enemy.TYPES)

return Enemy
