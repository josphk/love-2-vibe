-- player.lua
-- Player entity: WASD movement, mouse aiming, hitscan beam weapon.
-- Click to enter bullet-time, click again to fire.

local Utils      = require("utils")
local Sprites    = require("sprites")
local Background = require("background")

local Player = {}
Player.__index = Player

local SPEED       = 210
local HITBOX_R    = 3
local SPRITE_R    = 14
local GRAZE_R     = 20
local MAX_LIVES   = 5
local INVULN_TIME = 2.0
local BEAM_WIDTH  = 14      -- hitscan corridor half-width
local BEAM_DAMAGE = 40
local BEAM_LENGTH = 1200

function Player.new()
    local A = Background.ARENA
    local self = setmetatable({}, Player)
    self.x = A.x + A.w / 2
    self.y = A.y + A.h * 0.75
    self.hitboxR = HITBOX_R
    self.spriteR = SPRITE_R
    self.grazeR  = GRAZE_R

    self.lives = MAX_LIVES
    self.score = 0
    self.graze = 0

    self.aimAngle = -math.pi / 2    -- default: aim up
    self.aimWorldX = self.x
    self.aimWorldY = self.y - 100
    self.facing = 1

    self.invulnTimer = 0
    self.age = 0
    self.dead = false
    return self
end

function Player:update(dt, camera)
    if self.dead then return end
    self.age = self.age + dt

    -- WASD movement
    local dx, dy = 0, 0
    if love.keyboard.isDown("a", "left")  then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end
    if love.keyboard.isDown("w", "up")    then dy = dy - 1 end
    if love.keyboard.isDown("s", "down")  then dy = dy + 1 end
    if dx ~= 0 and dy ~= 0 then
        local inv = 1 / math.sqrt(2); dx, dy = dx * inv, dy * inv
    end

    self.x = self.x + dx * SPEED * dt
    self.y = self.y + dy * SPEED * dt

    -- Clamp to arena
    local A = Background.ARENA
    self.x = Utils.clamp(self.x, A.x + SPRITE_R, A.x + A.w - SPRITE_R)
    self.y = Utils.clamp(self.y, A.y + SPRITE_R, A.y + A.h - SPRITE_R)

    -- Aim toward mouse (convert screen→world)
    local mx, my = love.mouse.getPosition()
    self.aimWorldX, self.aimWorldY = camera:screenToWorld(mx, my)
    self.aimAngle = Utils.angleTo(self.x, self.y, self.aimWorldX, self.aimWorldY)

    -- Facing
    if self.aimWorldX < self.x then self.facing = -1 else self.facing = 1 end

    -- Invuln timer
    if self.invulnTimer > 0 then self.invulnTimer = self.invulnTimer - dt end
end

--------------------------------------------------------------------------------
-- Fire beam — returns { x1,y1, x2,y2, bulletsDestroyed, enemiesHit, score }
--------------------------------------------------------------------------------
function Player:fireBeam(bulletPool, enemies, particles)
    if self.dead then return nil end

    local angle = self.aimAngle
    local cosA, sinA = math.cos(angle), math.sin(angle)
    local x2 = self.x + cosA * BEAM_LENGTH
    local y2 = self.y + sinA * BEAM_LENGTH

    local destroyed = 0
    local hit = 0
    local score = 0

    -- Destroy enemy bullets in beam path
    for _, b in ipairs(bulletPool.list) do
        if not b.dead then
            local d = Utils.pointToSegmentDist(b.x, b.y, self.x, self.y, x2, y2)
            if d <= BEAM_WIDTH + b.radius then
                b.dead = true
                destroyed = destroyed + 1
                particles:spark(b.x, b.y, b.r, b.g, b.b)
            end
        end
    end

    -- Damage enemies in beam path
    for _, e in ipairs(enemies) do
        if not e.dead then
            local d = Utils.pointToSegmentDist(e.x, e.y, self.x, self.y, x2, y2)
            if d <= BEAM_WIDTH + e.radius then
                local killed = e:takeDamage(BEAM_DAMAGE)
                hit = hit + 1
                particles:burst(e.x, e.y, e.cr, e.cg, e.cb, 8, 80)
                if killed then
                    score = score + e.score
                    particles:burst(e.x, e.y, 1, 0.9, 0.5, 18, 140)
                end
            end
        end
    end

    -- Scoring for bullet destruction
    score = score + destroyed * 15
    if destroyed >= 5 then
        score = score + destroyed * 10  -- combo bonus
    end

    -- Visual beam
    particles:beam(self.x, self.y, x2, y2, destroyed)

    return {
        x1 = self.x, y1 = self.y, x2 = x2, y2 = y2,
        destroyed = destroyed, hit = hit, score = score,
    }
end

--------------------------------------------------------------------------------
-- Take a hit
--------------------------------------------------------------------------------
function Player:hit()
    if self.dead then return false end
    if self.invulnTimer > 0 then return false end
    self.lives = self.lives - 1
    self.invulnTimer = INVULN_TIME
    if self.lives <= 0 then self.dead = true end
    return true
end

--------------------------------------------------------------------------------
-- Draw (inside camera transform)
--------------------------------------------------------------------------------
function Player:draw(btActive)
    if self.dead then return end

    -- Flicker during invuln
    if self.invulnTimer > 0 and math.floor(self.invulnTimer * 12) % 2 == 0 then
        return
    end

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", self.x, self.y + SPRITE_R * 0.5, SPRITE_R * 0.7, SPRITE_R * 0.25)

    -- Sprite
    love.graphics.setColor(1, 1, 1, 1)
    Sprites.draw("player", self.x, self.y, self.age, self.facing)

    -- Weapon direction indicator (short line)
    local cosA, sinA = math.cos(self.aimAngle), math.sin(self.aimAngle)
    love.graphics.setColor(0.7, 0.85, 1.0, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.line(
        self.x + cosA * 10, self.y + sinA * 10,
        self.x + cosA * 22, self.y + sinA * 22)
    love.graphics.setLineWidth(1)

    -- Hitbox (always visible as a tiny dot)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", self.x, self.y, HITBOX_R)
end

--- Draw aim line (call during bullet time, inside camera transform).
function Player:drawAimLine()
    if self.dead then return end

    local cosA, sinA = math.cos(self.aimAngle), math.sin(self.aimAngle)
    local ex = self.x + cosA * BEAM_LENGTH
    local ey = self.y + sinA * BEAM_LENGTH

    -- Dashed line
    local dashLen, gapLen = 12, 8
    local totalDist = BEAM_LENGTH
    love.graphics.setLineWidth(1.5)
    for d = 20, totalDist, dashLen + gapLen do
        local x1 = self.x + cosA * d
        local y1 = self.y + sinA * d
        local dEnd = math.min(d + dashLen, totalDist)
        local x2 = self.x + cosA * dEnd
        local y2 = self.y + sinA * dEnd
        local alpha = math.max(0.05, 0.5 - d / totalDist * 0.5)
        love.graphics.setColor(0.6, 0.8, 1.0, alpha)
        love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)

    -- Beam width preview (faint corridor)
    love.graphics.setColor(0.4, 0.6, 1.0, 0.04)
    local perpX, perpY = -sinA * BEAM_WIDTH, cosA * BEAM_WIDTH
    love.graphics.polygon("fill",
        self.x + perpX, self.y + perpY,
        ex + perpX, ey + perpY,
        ex - perpX, ey - perpY,
        self.x - perpX, self.y - perpY)
end

return Player
