-- enemy.lua
-- Enemy entities for a Vampire-Survivors-style game.
-- Enemies swarm toward the player.  No bullet patterns — they deal contact damage.

local Utils   = require("utils")
local Sprites = require("sprites")

local Enemy = {}
Enemy.__index = Enemy

--------------------------------------------------------------------------------
-- Enemy type definitions
-- Fields: hp, radius, speed, damage, score, xp, sprite, r/g/b (for particles)
--------------------------------------------------------------------------------
local DEFS = {}

DEFS.bat = {
    hp = 8, radius = 10, speed = 110, damage = 5,
    score = 10, xp = 1,
    sprite = "bat",
    r = 0.9, g = 0.3, b = 0.2,
}

DEFS.zombie = {
    hp = 20, radius = 12, speed = 45, damage = 10,
    score = 20, xp = 2,
    sprite = "zombie",
    r = 0.4, g = 0.7, b = 0.3,
}

DEFS.skeleton = {
    hp = 30, radius = 12, speed = 65, damage = 12,
    score = 35, xp = 3,
    sprite = "skeleton",
    r = 0.85, g = 0.85, b = 0.8,
}

DEFS.ghost = {
    hp = 18, radius = 11, speed = 80, damage = 8,
    score = 30, xp = 2,
    sprite = "ghost",
    r = 0.7, g = 0.75, b = 0.95,
}

DEFS.golem = {
    hp = 120, radius = 20, speed = 30, damage = 25,
    score = 100, xp = 10,
    sprite = "golem",
    r = 0.6, g = 0.5, b = 0.35,
}

DEFS.fly = {
    hp = 5, radius = 6, speed = 140, damage = 3,
    score = 5, xp = 1,
    sprite = "fly",
    r = 0.55, g = 0.3, b = 0.65,
}

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Enemy.new(typeName, x, y, diffMult)
    local def = DEFS[typeName]
    assert(def, "Unknown enemy type: " .. tostring(typeName))
    diffMult = diffMult or 1

    local self = setmetatable({}, Enemy)
    self.typeName = typeName
    self.x = x
    self.y = y

    self.hp       = math.floor(def.hp * diffMult)
    self.maxHp    = self.hp
    self.radius   = def.radius
    self.speed    = def.speed * (0.9 + math.random() * 0.2) -- slight variance
    self.damage   = math.floor(def.damage * math.max(1, diffMult * 0.6))
    self.score    = def.score
    self.xp       = def.xp
    self.sprite   = def.sprite
    self.r, self.g, self.b = def.r, def.g, def.b

    self.age       = 0
    self.facing    = 1
    self.dead      = false

    -- Knockback state
    self.kbVx = 0
    self.kbVy = 0
    self.kbTimer = 0

    -- Damage flash
    self.hitFlash = 0

    -- Contact damage cooldown (so the player isn't hit every frame)
    self.contactTimer = 0

    return self
end

--------------------------------------------------------------------------------
-- Update — chase the player
--------------------------------------------------------------------------------
function Enemy:update(dt, playerX, playerY)
    if self.dead then return end
    self.age = self.age + dt
    if self.hitFlash > 0 then self.hitFlash = self.hitFlash - dt end
    if self.contactTimer > 0 then self.contactTimer = self.contactTimer - dt end

    -- Knockback
    if self.kbTimer > 0 then
        self.kbTimer = self.kbTimer - dt
        self.x = self.x + self.kbVx * dt
        self.y = self.y + self.kbVy * dt
        return  -- skip normal movement during knockback
    end

    -- Move toward player
    local angle = Utils.angleTo(self.x, self.y, playerX, playerY)
    self.x = self.x + math.cos(angle) * self.speed * dt
    self.y = self.y + math.sin(angle) * self.speed * dt

    -- Facing
    if playerX < self.x then self.facing = -1
    elseif playerX > self.x then self.facing = 1 end
end

--------------------------------------------------------------------------------
-- Take damage — returns true if killed.
--------------------------------------------------------------------------------
function Enemy:takeDamage(dmg)
    if self.dead then return false end
    self.hp = self.hp - dmg
    self.hitFlash = 0.10
    if self.hp <= 0 then
        self.dead = true
        return true
    end
    return false
end

--- Apply knockback impulse.
function Enemy:applyKnockback(fromX, fromY, force)
    local a = Utils.angleTo(fromX, fromY, self.x, self.y)
    self.kbVx = math.cos(a) * force
    self.kbVy = math.sin(a) * force
    self.kbTimer = 0.15
end

--------------------------------------------------------------------------------
-- Draw (inside camera transform)
--------------------------------------------------------------------------------
function Enemy:draw()
    if self.dead then return end

    local flash = self.hitFlash > 0
    love.graphics.setColor(1, 1, 1, 1)
    Sprites.draw(self.sprite, self.x, self.y, self.age, self.facing, flash)

    -- Health bar (only when damaged)
    if self.hp < self.maxHp then
        local sw, sh = Sprites.getSize(self.sprite)
        local barW = math.max(sw, self.radius * 2)
        local barH = 2
        local bx = self.x - barW / 2
        local by = self.y - sh / 2 - 5
        love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", bx, by, barW, barH)
        love.graphics.setColor(0.15, 0.85, 0.15, 0.9)
        love.graphics.rectangle("fill", bx, by, barW * (self.hp / self.maxHp), barH)
    end
end

--------------------------------------------------------------------------------
-- Expose type list for the spawner
--------------------------------------------------------------------------------
Enemy.TYPES = {}
for k in pairs(DEFS) do table.insert(Enemy.TYPES, k) end
table.sort(Enemy.TYPES)  -- deterministic order

return Enemy
