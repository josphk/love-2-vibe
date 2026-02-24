-- player.lua
-- Player entity for a Vampire-Survivors-style game.
-- Moves freely on an infinite 2D plane.  Weapons fire automatically (see weapons.lua).

local Utils   = require("utils")
local Sprites = require("sprites")

local Player = {}
Player.__index = Player

--------------------------------------------------------------------------------
-- Defaults
--------------------------------------------------------------------------------
local BASE_SPEED    = 150
local BASE_HP       = 100
local HITBOX_RADIUS = 10
local INVULN_TIME   = 1.0     -- seconds of mercy invulnerability after a hit
local PICKUP_RANGE  = 60      -- base gem attraction radius

function Player.new()
    local self = setmetatable({}, Player)
    self.x = 0
    self.y = 0
    self.hitboxRadius = HITBOX_RADIUS

    -- Core stats
    self.maxHp      = BASE_HP
    self.hp         = BASE_HP
    self.baseSpeed  = BASE_SPEED
    self.pickupRange = PICKUP_RANGE

    -- Multiplier stats (modified by passive upgrades)
    self.mightMult    = 1.0   -- damage multiplier
    self.speedMult    = 1.0
    self.cooldownMult = 1.0   -- lower = faster weapons
    self.areaMult     = 1.0
    self.armor        = 0     -- flat damage reduction
    self.recovery     = 0     -- HP regenerated per second

    -- Progression
    self.xp       = 0
    self.level     = 1
    self.xpToNext  = 5
    self.kills     = 0

    -- Weapons (populated by levelup choices)
    self.weapons = {}          -- list of weapon instances (see weapons.lua)
    self.maxWeapons = 6

    -- State
    self.facing     = 1       -- 1 = right, -1 = left
    self.invulnTimer = 0
    self.age        = 0
    self.dead       = false

    return self
end

--------------------------------------------------------------------------------
-- XP & levelling
--------------------------------------------------------------------------------
function Player:xpNeeded()
    return math.floor(5 + self.level ^ 1.5 * 4)
end

--- Add XP and return true if a level-up occurred.
function Player:addXP(amount)
    if self.dead then return false end
    self.xp = self.xp + amount
    if self.xp >= self.xpToNext then
        self.xp = self.xp - self.xpToNext
        self.level = self.level + 1
        self.xpToNext = self:xpNeeded()
        return true   -- caller should open level-up screen
    end
    return false
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function Player:update(dt)
    if self.dead then return end

    self.age = self.age + dt

    -- Movement input
    local dx, dy = 0, 0
    if love.keyboard.isDown("left",  "a") then dx = dx - 1 end
    if love.keyboard.isDown("right", "d") then dx = dx + 1 end
    if love.keyboard.isDown("up",    "w") then dy = dy - 1 end
    if love.keyboard.isDown("down",  "s") then dy = dy + 1 end

    -- Normalise diagonal
    if dx ~= 0 and dy ~= 0 then
        local inv = 1 / math.sqrt(2)
        dx, dy = dx * inv, dy * inv
    end

    -- Track facing direction (only change when moving horizontally)
    if dx ~= 0 then self.facing = dx > 0 and 1 or -1 end

    local spd = self.baseSpeed * self.speedMult
    self.x = self.x + dx * spd * dt
    self.y = self.y + dy * spd * dt

    -- Invulnerability
    if self.invulnTimer > 0 then
        self.invulnTimer = self.invulnTimer - dt
    end

    -- HP recovery
    if self.recovery > 0 then
        self.hp = math.min(self.maxHp, self.hp + self.recovery * dt)
    end
end

--------------------------------------------------------------------------------
-- Take damage – returns true if the player was actually hurt.
--------------------------------------------------------------------------------
function Player:hit(rawDamage)
    if self.dead then return false end
    if self.invulnTimer > 0 then return false end

    local dmg = math.max(1, rawDamage - self.armor)
    self.hp = self.hp - dmg
    self.invulnTimer = INVULN_TIME
    if self.hp <= 0 then
        self.hp = 0
        self.dead = true
    end
    return true
end

--- Heal the player.
function Player:heal(amount)
    self.hp = math.min(self.maxHp, self.hp + amount)
end

--------------------------------------------------------------------------------
-- Draw  (call inside camera transform)
--------------------------------------------------------------------------------
function Player:draw()
    if self.dead then return end

    -- Flicker during invulnerability
    if self.invulnTimer > 0 and math.floor(self.invulnTimer * 12) % 2 == 0 then
        return
    end

    love.graphics.setColor(1, 1, 1, 1)
    Sprites.draw("player", self.x, self.y, self.age, self.facing, false)

    -- Pickup range ring (subtle)
    local pr = self.pickupRange * self.areaMult
    love.graphics.setColor(0.4, 0.8, 1.0, 0.08)
    love.graphics.circle("line", self.x, self.y, pr)
end

return Player
