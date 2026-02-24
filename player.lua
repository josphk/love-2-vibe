-- player.lua
-- Player entity: movement, shooting, invincibility frames, drawing

local Utils = require("utils")

local Player = {}
Player.__index = Player

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
local SPEED           = 280   -- pixels / sec (normal)
local FOCUS_SPEED     = 130   -- pixels / sec (focus / slow)
local SHOOT_INTERVAL  = 0.08  -- seconds between shots
local HITBOX_RADIUS   = 3     -- tiny hitbox (bullet hell tradition)
local GRAZE_RADIUS    = 18    -- graze detection ring
local SPRITE_RADIUS   = 12    -- visual size
local INVULN_TIME     = 2.0   -- seconds of invulnerability after a hit
local MAX_LIVES       = 3
local BOMB_COUNT      = 3     -- screen-clearing bombs

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Player.new(screenW, screenH)
    local self = setmetatable({}, Player)
    self.x = screenW / 2
    self.y = screenH * 0.85
    self.screenW = screenW
    self.screenH = screenH
    self.speed = SPEED
    self.focusSpeed = FOCUS_SPEED
    self.hitboxRadius = HITBOX_RADIUS
    self.grazeRadius = GRAZE_RADIUS
    self.spriteRadius = SPRITE_RADIUS

    self.lives = MAX_LIVES
    self.bombs = BOMB_COUNT
    self.score = 0
    self.graze = 0               -- graze counter (near misses)
    self.power = 1               -- power level 1-4 (affects shot spread)

    self.shootTimer = 0
    self.invulnTimer = 0         -- >0 means invulnerable
    self.dead = false
    self.focused = false         -- shift held = focused (slow + visible hitbox)

    -- Visual flash timer
    self.flashTimer = 0

    return self
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function Player.update(self, dt)
    if self.dead then return end

    -- Movement input
    local dx, dy = 0, 0
    if love.keyboard.isDown("left", "a")  then dx = dx - 1 end
    if love.keyboard.isDown("right", "d") then dx = dx + 1 end
    if love.keyboard.isDown("up", "w")    then dy = dy - 1 end
    if love.keyboard.isDown("down", "s")  then dy = dy + 1 end

    -- Normalize diagonal
    if dx ~= 0 and dy ~= 0 then
        local inv = 1 / math.sqrt(2)
        dx = dx * inv
        dy = dy * inv
    end

    -- Focus mode (hold left shift)
    self.focused = love.keyboard.isDown("lshift", "rshift")
    local spd = self.focused and self.focusSpeed or self.speed

    self.x = self.x + dx * spd * dt
    self.y = self.y + dy * spd * dt

    -- Keep inside screen with small margin
    local margin = self.spriteRadius
    self.x = Utils.clamp(self.x, margin, self.screenW - margin)
    self.y = Utils.clamp(self.y, margin, self.screenH - margin)

    -- Timers
    if self.invulnTimer > 0 then
        self.invulnTimer = self.invulnTimer - dt
    end
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
    end
    self.shootTimer = self.shootTimer - dt
end

--------------------------------------------------------------------------------
-- Shooting – returns a table of bullet descriptors (or nil)
--------------------------------------------------------------------------------
function Player.shoot(self)
    if self.dead then return nil end
    if not love.keyboard.isDown("space", "z") then return nil end
    if self.shootTimer > 0 then return nil end

    self.shootTimer = SHOOT_INTERVAL
    local bullets = {}

    -- Base shot: two parallel bullets
    local bspeed = 800
    table.insert(bullets, { x = self.x - 8, y = self.y - 10, vx = 0, vy = -bspeed })
    table.insert(bullets, { x = self.x + 8, y = self.y - 10, vx = 0, vy = -bspeed })

    -- Power >= 2: add angled side shots
    if self.power >= 2 then
        local ang = 0.12
        table.insert(bullets, { x = self.x - 14, y = self.y - 6,
            vx = -math.sin(ang) * bspeed, vy = -math.cos(ang) * bspeed })
        table.insert(bullets, { x = self.x + 14, y = self.y - 6,
            vx =  math.sin(ang) * bspeed, vy = -math.cos(ang) * bspeed })
    end

    -- Power >= 3: wider spread
    if self.power >= 3 then
        local ang = 0.25
        table.insert(bullets, { x = self.x - 20, y = self.y - 2,
            vx = -math.sin(ang) * bspeed, vy = -math.cos(ang) * bspeed })
        table.insert(bullets, { x = self.x + 20, y = self.y - 2,
            vx =  math.sin(ang) * bspeed, vy = -math.cos(ang) * bspeed })
    end

    -- Power 4: homing side missiles (approximated with angled shots)
    if self.power >= 4 then
        local ang = 0.40
        table.insert(bullets, { x = self.x - 26, y = self.y,
            vx = -math.sin(ang) * bspeed * 0.9, vy = -math.cos(ang) * bspeed * 0.9 })
        table.insert(bullets, { x = self.x + 26, y = self.y,
            vx =  math.sin(ang) * bspeed * 0.9, vy = -math.cos(ang) * bspeed * 0.9 })
    end

    return bullets
end

--------------------------------------------------------------------------------
-- Take damage – returns true if the player actually got hit
--------------------------------------------------------------------------------
function Player.hit(self)
    if self.dead then return false end
    if self.invulnTimer > 0 then return false end

    self.lives = self.lives - 1
    self.invulnTimer = INVULN_TIME
    self.flashTimer = INVULN_TIME

    if self.lives <= 0 then
        self.dead = true
    end

    -- Reset position on hit
    self.x = self.screenW / 2
    self.y = self.screenH * 0.85

    return true
end

--------------------------------------------------------------------------------
-- Bomb – clears screen, returns true if a bomb was used
--------------------------------------------------------------------------------
function Player.bomb(self)
    if self.dead then return false end
    if self.bombs <= 0 then return false end
    self.bombs = self.bombs - 1
    self.invulnTimer = math.max(self.invulnTimer, 1.5) -- brief invuln with bomb
    return true
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------
function Player.draw(self)
    if self.dead then return end

    -- Flicker during invulnerability
    if self.invulnTimer > 0 then
        if math.floor(self.invulnTimer * 15) % 2 == 0 then
            return -- skip frame for flicker effect
        end
    end

    -- Ship body (triangle)
    love.graphics.setColor(0.3, 0.7, 1.0, 1)
    local r = self.spriteRadius
    love.graphics.polygon("fill",
        self.x, self.y - r * 1.4,
        self.x - r, self.y + r,
        self.x + r, self.y + r
    )

    -- Ship highlight
    love.graphics.setColor(0.6, 0.9, 1.0, 1)
    love.graphics.polygon("line",
        self.x, self.y - r * 1.4,
        self.x - r, self.y + r,
        self.x + r, self.y + r
    )

    -- Engine glow
    love.graphics.setColor(1, 0.6, 0.2, 0.8)
    love.graphics.circle("fill", self.x, self.y + r + 2, 4 + math.random() * 2)

    -- Hitbox indicator (visible in focus mode)
    if self.focused then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", self.x, self.y, self.hitboxRadius)
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.circle("line", self.x, self.y, self.grazeRadius)
    end
end

return Player
