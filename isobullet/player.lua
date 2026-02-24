-- player.lua
-- Player entity: WASD movement on isometric grid, mouse aim,
-- reflecting hitscan beam weapon fired during bullet-time.

local Map   = require("map")
local Utils = require("utils")

local Player = {}
Player.__index = Player

local SPEED       = 4.0       -- grid units / sec
local HITBOX_R    = 0.15      -- grid units (tiny, bullet-hell style)
local GRAZE_R     = 0.6       -- grid units
local MAX_LIVES   = 5
local INVULN_TIME = 2.0
local BEAM_WIDTH  = 0.5       -- grid units — hitscan corridor half-width
local BEAM_DAMAGE = 40
local BEAM_MAX_BOUNCES = 3
local BEAM_MAX_LEN     = 30   -- grid units total ray length

-- Colors for each bounce segment of the aim line
local BOUNCE_COLORS = {
    { 0.5, 0.8, 1.0 },   -- segment 0: cyan
    { 0.6, 0.5, 1.0 },   -- segment 1: purple
    { 1.0, 0.4, 0.4 },   -- segment 2: red
    { 1.0, 0.7, 0.3 },   -- segment 3: orange
}

function Player.new()
    local self = setmetatable({}, Player)
    self.x = 12
    self.y = 16
    self.hitboxR = HITBOX_R
    self.grazeR  = GRAZE_R

    self.lives = MAX_LIVES
    self.score = 0
    self.graze = 0

    self.aimGX = 12    -- aim target in grid coords
    self.aimGY = 10
    self.aimAngle = -math.pi / 2

    self.invulnTimer = 0
    self.dead = false
    return self
end

function Player:update(dt, camera)
    if self.dead then return end

    -- WASD movement (grid-space)
    local dx, dy = 0, 0
    if love.keyboard.isDown("a", "left")  then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end
    if love.keyboard.isDown("w", "up")    then dy = dy - 1 end
    if love.keyboard.isDown("s", "down")  then dy = dy + 1 end
    if dx ~= 0 and dy ~= 0 then
        local inv = 1 / math.sqrt(2)
        dx, dy = dx * inv, dy * inv
    end
    local nx = self.x + dx * SPEED * dt
    local ny = self.y + dy * SPEED * dt
    -- Wall collision (check each axis separately for wall sliding)
    if not Map.isWall(nx, self.y) then self.x = nx end
    if not Map.isWall(self.x, ny) then self.y = ny end

    -- Clamp within map
    self.x = Utils.clamp(self.x, 1.6, Map.GW - 0.6)
    self.y = Utils.clamp(self.y, 1.6, Map.GH - 0.6)

    -- Aim toward mouse (screen → world → grid)
    local mx, my = love.mouse.getPosition()
    local wx, wy = camera:screenToWorld(mx, my)
    self.aimGX, self.aimGY = Map.screenToGrid(wx, wy)
    self.aimAngle = Utils.angleTo(self.x, self.y, self.aimGX, self.aimGY)

    -- Invulnerability timer
    if self.invulnTimer > 0 then self.invulnTimer = self.invulnTimer - dt end
end

--------------------------------------------------------------------------------
-- Fire reflecting beam
-- Returns { segments, destroyed, hit, score } or nil
--------------------------------------------------------------------------------
function Player:fireBeam(bulletPool, enemies, particles)
    if self.dead then return nil end

    local dx = self.aimGX - self.x
    local dy = self.aimGY - self.y
    local segments = Map.reflectRaycast(self.x, self.y, dx, dy,
                                        BEAM_MAX_BOUNCES, BEAM_MAX_LEN)
    if #segments == 0 then return nil end

    local destroyed = 0
    local hit = 0
    local score = 0

    -- Destroy enemy bullets near any beam segment
    for _, b in ipairs(bulletPool.list) do
        if not b.dead then
            for _, seg in ipairs(segments) do
                local d = Utils.pointToSegmentDist(b.x, b.y,
                    seg.x1, seg.y1, seg.x2, seg.y2)
                if d <= BEAM_WIDTH + b.radius then
                    b.dead = true
                    destroyed = destroyed + 1
                    particles:spark(b.x, b.y, b.r, b.g, b.b)
                    break
                end
            end
        end
    end

    -- Damage enemies near any beam segment
    for _, e in ipairs(enemies) do
        if not e.dead then
            for _, seg in ipairs(segments) do
                local d = Utils.pointToSegmentDist(e.x, e.y,
                    seg.x1, seg.y1, seg.x2, seg.y2)
                if d <= BEAM_WIDTH + e.radius then
                    local killed = e:takeDamage(BEAM_DAMAGE)
                    hit = hit + 1
                    particles:burst(e.x, e.y, e.cr, e.cg, e.cb, 8, 80)
                    if killed then
                        score = score + e.score
                        particles:burst(e.x, e.y, 1, 0.9, 0.5, 16, 130)
                    end
                    break   -- don't damage same enemy from multiple segments
                end
            end
        end
    end

    -- Scoring
    score = score + destroyed * 15
    if destroyed >= 5 then score = score + destroyed * 10 end   -- combo

    -- Wall-hit sparks at each bounce point
    for i = 2, #segments do
        particles:wallSpark(segments[i].x1, segments[i].y1)
    end

    -- Visual beam trail
    particles:addBeamTrail(segments)

    return {
        segments = segments,
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
function Player:draw()
    if self.dead then return end

    -- Invulnerability flicker
    if self.invulnTimer > 0 and math.floor(self.invulnTimer * 12) % 2 == 0 then
        return
    end

    local sx, sy = Map.gridToScreen(self.x, self.y)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", sx, sy + 6, 10, 4)

    -- Body (ellipse, raised slightly like tactical-shooter)
    love.graphics.setColor(0.3, 0.5, 0.75)
    love.graphics.ellipse("fill", sx, sy - 6, 12, 9)
    love.graphics.setColor(0.5, 0.7, 0.95)
    love.graphics.ellipse("line", sx, sy - 6, 12, 9)

    -- Weapon direction indicator
    local cosA, sinA = math.cos(self.aimAngle), math.sin(self.aimAngle)
    love.graphics.setColor(0.6, 0.85, 1.0, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.line(
        sx + cosA * 8, sy - 6 + sinA * 8,
        sx + cosA * 18, sy - 6 + sinA * 18)
    love.graphics.setLineWidth(1)

    -- Hitbox dot
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", sx, sy - 6, 2)
end

--- Draw reflecting aim line (call during bullet-time, inside camera transform).
function Player:drawAimLine()
    if self.dead then return end

    local dx = self.aimGX - self.x
    local dy = self.aimGY - self.y
    local segments = Map.reflectRaycast(self.x, self.y, dx, dy,
                                        BEAM_MAX_BOUNCES, BEAM_MAX_LEN)

    for si, seg in ipairs(segments) do
        local sx1, sy1 = Map.gridToScreen(seg.x1, seg.y1)
        local sx2, sy2 = Map.gridToScreen(seg.x2, seg.y2)
        local clr = BOUNCE_COLORS[si] or BOUNCE_COLORS[#BOUNCE_COLORS]
        local baseAlpha = math.max(0.1, 0.5 - (si - 1) * 0.12)

        -- Dashed line
        local totalLen = Utils.distance(sx1, sy1, sx2, sy2)
        if totalLen < 1 then goto nextSeg end
        local dirX, dirY = (sx2 - sx1) / totalLen, (sy2 - sy1) / totalLen
        local dashLen, gapLen = 10, 6

        love.graphics.setLineWidth(1.5)
        local d = (si == 1) and 16 or 0
        while d < totalLen do
            local x1 = sx1 + dirX * d
            local y1 = sy1 + dirY * d
            local dEnd = math.min(d + dashLen, totalLen)
            local x2 = sx1 + dirX * dEnd
            local y2 = sy1 + dirY * dEnd
            local alpha = baseAlpha * math.max(0.05, 1 - d / totalLen * 0.6)
            love.graphics.setColor(clr[1], clr[2], clr[3], alpha)
            love.graphics.line(x1, y1, x2, y2)
            d = d + dashLen + gapLen
        end
        love.graphics.setLineWidth(1)

        -- Beam width corridor preview (faint)
        if si == 1 then
            local beamScreenW = BEAM_WIDTH * Map.TILE_W / 2
            local perpX, perpY = -dirY * beamScreenW, dirX * beamScreenW
            love.graphics.setColor(clr[1], clr[2], clr[3], 0.03)
            love.graphics.polygon("fill",
                sx1 + perpX, sy1 + perpY,
                sx2 + perpX, sy2 + perpY,
                sx2 - perpX, sy2 - perpY,
                sx1 - perpX, sy1 - perpY)
        end

        -- Bounce point indicator (small circle at segment start for bounced segments)
        if si > 1 then
            love.graphics.setColor(clr[1], clr[2], clr[3], 0.6)
            love.graphics.circle("fill", sx1, sy1, 3)
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.circle("line", sx1, sy1, 5)
        end

        ::nextSeg::
    end
end

return Player
