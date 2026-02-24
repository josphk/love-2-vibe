-- enemy.lua
-- Enemy entities: multiple types with distinct behaviour and bullet patterns.

local Utils    = require("utils")
local Patterns = require("patterns")
local Sprites  = require("sprites")

local Enemy = {}
Enemy.__index = Enemy

--------------------------------------------------------------------------------
-- Enemy type definitions
-- Each type specifies: hp, radius, speed, color, pattern schedule
--------------------------------------------------------------------------------
local DEFS = {}

-- Type 1: DRONE – drifts down, fires aimed bursts
DEFS.drone = {
    hp = 8, radius = 14,
    r = 0.9, g = 0.3, b = 0.2,
    speed = 60,
    score = 100,
    pattern = function(self, pool, px, py)
        Patterns.aimedBurst(pool, self, px, py, { count = 5, speed = 200 })
    end,
    fireInterval = 1.2,
    moveFunc = function(self, dt)
        self.y = self.y + self.speed * dt
    end,
}

-- Type 2: SPINNER – hovers and fires spirals
DEFS.spinner = {
    hp = 20, radius = 18,
    r = 0.3, g = 0.9, b = 0.4,
    speed = 30,
    score = 250,
    pattern = function(self, pool, px, py)
        Patterns.spiral(pool, self, px, py, {
            arms = 4, speed = 130, offset = self.age * 2.5
        })
    end,
    fireInterval = 0.12,
    moveFunc = function(self, dt)
        -- Drift to a hover-y, then sway side to side
        if self.y < self.targetY then
            self.y = self.y + 80 * dt
        end
        self.x = self.x + math.sin(self.age * 1.2) * 60 * dt
    end,
}

-- Type 3: TURRET – stationary, fires radial bursts and crosses
DEFS.turret = {
    hp = 35, radius = 20,
    r = 0.8, g = 0.8, b = 0.2,
    speed = 0,
    score = 400,
    pattern = function(self, pool, px, py)
        if self.patternPhase % 2 == 0 then
            Patterns.radialBurst(pool, self, px, py, {
                count = 20, speed = 140, offset = self.age * 0.5
            })
        else
            Patterns.cross(pool, self, px, py, {
                speed = 200, offset = self.age * 0.8
            })
        end
        self.patternPhase = (self.patternPhase or 0) + 1
    end,
    fireInterval = 0.8,
    moveFunc = function(self, dt)
        if self.y < self.targetY then
            self.y = self.y + 60 * dt
        end
    end,
}

-- Type 4: WEAVER – fast, fires wave bullets
DEFS.weaver = {
    hp = 12, radius = 12,
    r = 0.4, g = 0.4, b = 1.0,
    speed = 100,
    score = 200,
    pattern = function(self, pool, px, py)
        Patterns.wave(pool, self, px, py, { count = 5, speed = 160, freq = 6, amp = 100 })
    end,
    fireInterval = 1.5,
    moveFunc = function(self, dt)
        self.y = self.y + self.speed * 0.5 * dt
        self.x = self.x + math.cos(self.age * 2.0) * self.speed * dt
    end,
}

-- Type 5: HEAVY – big, lots of HP, fires expanding rings + shotgun
DEFS.heavy = {
    hp = 60, radius = 26,
    r = 0.7, g = 0.2, b = 0.7,
    speed = 25,
    score = 600,
    pattern = function(self, pool, px, py)
        if self.patternPhase % 3 == 0 then
            Patterns.expandingRing(pool, self, px, py, { count = 28, speed = 30, accel = 120 })
        elseif self.patternPhase % 3 == 1 then
            Patterns.shotgun(pool, self, px, py, { count = 14, speed = 200 })
        else
            Patterns.spinSpiral(pool, self, px, py, {
                arms = 6, speed = 100, spin = 2.0, offset = self.age
            })
        end
        self.patternPhase = (self.patternPhase or 0) + 1
    end,
    fireInterval = 1.0,
    moveFunc = function(self, dt)
        if self.y < self.targetY then
            self.y = self.y + 40 * dt
        end
        self.x = self.x + math.sin(self.age * 0.7) * 30 * dt
    end,
}

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Enemy.new(typeName, x, y, screenW, screenH)
    local def = DEFS[typeName]
    assert(def, "Unknown enemy type: " .. tostring(typeName))

    local self = setmetatable({}, Enemy)
    self.typeName = typeName
    self.x = x
    self.y = y
    self.screenW = screenW
    self.screenH = screenH

    self.hp     = def.hp
    self.maxHp  = def.hp
    self.radius = def.radius
    self.speed  = def.speed
    self.score  = def.score
    self.r, self.g, self.b = def.r, def.g, def.b

    self.patternFunc   = def.pattern
    self.fireInterval  = def.fireInterval
    self.moveFunc      = def.moveFunc
    self.fireTimer     = def.fireInterval * 0.5  -- offset initial fire
    self.patternPhase  = 0

    self.age = 0
    self.hitFlash = 0                         -- damage flash timer
    self.targetY = 60 + math.random() * 140   -- hover line for stationary types
    self.dead = false
    self.offscreen = false  -- flagged when below screen (cleanup, no score)

    return self
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function Enemy.update(self, dt, bulletPool, playerX, playerY)
    if self.dead then return end

    self.age = self.age + dt
    if self.hitFlash > 0 then self.hitFlash = self.hitFlash - dt end

    -- Movement
    self.moveFunc(self, dt)

    -- Clamp X to screen
    self.x = Utils.clamp(self.x, self.radius, self.screenW - self.radius)

    -- Fire pattern
    self.fireTimer = self.fireTimer - dt
    if self.fireTimer <= 0 and self.y > 0 and self.y < self.screenH * 0.85 then
        self.fireTimer = self.fireInterval
        self.patternFunc(self, bulletPool, playerX, playerY)
    end

    -- Mark as offscreen if way below
    if self.y > self.screenH + 80 then
        self.dead = true
        self.offscreen = true
    end
end

--------------------------------------------------------------------------------
-- Take damage – returns true if killed
--------------------------------------------------------------------------------
function Enemy.takeDamage(self, dmg)
    if self.dead then return false end
    self.hp = self.hp - dmg
    self.hitFlash = 0.12  -- brief white flash
    if self.hp <= 0 then
        self.dead = true
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------
function Enemy.draw(self)
    if self.dead then return end

    -- Determine if we should show a damage flash (brief white flash on hit)
    local flash = false
    if self.hitFlash and self.hitFlash > 0 then
        flash = math.floor(self.hitFlash * 20) % 2 == 0
    end

    -- Draw the pixel-art sprite
    love.graphics.setColor(1, 1, 1, 1)
    Sprites.draw(self.typeName, self.x, self.y, self.age, flash)

    -- Health bar (if damaged)
    if self.hp < self.maxHp then
        local sw, sh = Sprites.getSize(self.typeName)
        local barW = math.max(sw, self.radius * 2)
        local barH = 3
        local bx = self.x - barW / 2
        local by = self.y - sh / 2 - 6
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        love.graphics.rectangle("fill", bx, by, barW, barH)
        love.graphics.setColor(0.2, 1.0, 0.2, 0.9)
        love.graphics.rectangle("fill", bx, by, barW * (self.hp / self.maxHp), barH)
    end
end

--------------------------------------------------------------------------------
-- Expose type names for spawner
--------------------------------------------------------------------------------
Enemy.TYPES = {}
for k in pairs(DEFS) do
    table.insert(Enemy.TYPES, k)
end

return Enemy
