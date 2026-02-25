-- bullettime.lua
-- Global time-scale manager with meter, hitstop, and visual overlay.
-- Click once → enter slow-mo (meter drains).
-- Click again → fire beam, exit slow-mo.
-- Right-click or meter empty → cancel without firing.

local Utils = require("utils")

local BulletTime = {}
BulletTime.__index = BulletTime

function BulletTime.new()
    local self = setmetatable({}, BulletTime)
    self.active      = false
    self.meter       = 100
    self.maxMeter    = 100
    self.drainRate   = 28      -- per real second while active
    self.rechargeRate = 16     -- per real second while inactive
    self.timeScale   = 1.0     -- current (smoothly interpolated)
    self.targetScale = 1.0
    self.slowScale   = 0.10    -- world speed during bullet-time
    self.lerpSpeed   = 10
    self.cooldown    = 0       -- lockout after meter empties
    self.hitstop     = 0       -- brief total freeze on beam hit

    -- Screen flash (P1)
    self.screenFlash = 0
    self.flashR, self.flashG, self.flashB = 1, 1, 1
    return self
end

--- Call every real-time frame (dt is unscaled).
function BulletTime:update(realDt)
    -- Hitstop (complete freeze)
    if self.hitstop > 0 then
        self.hitstop = self.hitstop - realDt
        self.timeScale = 0
        return
    end

    -- Cooldown after forced exit
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - realDt
    end

    -- Meter management
    if self.active then
        self.meter = self.meter - self.drainRate * realDt
        if self.meter <= 0 then
            self.meter = 0
            self:deactivate()
            self.cooldown = 0.6
        end
    else
        self.meter = math.min(self.maxMeter, self.meter + self.rechargeRate * realDt)
    end

    -- Smooth time-scale transition
    self.timeScale = Utils.lerp(self.timeScale, self.targetScale,
                                math.min(self.lerpSpeed * realDt, 1))

    -- Screen flash decay (P1)
    if self.screenFlash > 0 then self.screenFlash = self.screenFlash - realDt end
end

function BulletTime:activate()
    if self.cooldown > 0 then return false end
    if self.meter < 8 then return false end
    self.active = true
    self.targetScale = self.slowScale
    return true
end

function BulletTime:deactivate()
    self.active = false
    self.targetScale = 1.0
end

function BulletTime:triggerHitstop(duration)
    self.hitstop = math.max(self.hitstop, duration)
end

--- Trigger a screen flash (P1).
function BulletTime:flash(r, g, b, dur)
    self.flashR, self.flashG, self.flashB = r, g, b
    self.screenFlash = dur
end

--- Add meter (from kills, grazes, etc.).
function BulletTime:addMeter(amount)
    self.meter = math.min(self.maxMeter, self.meter + amount)
end

--- Scaled dt for world simulation.
function BulletTime:worldDt(realDt)
    return realDt * self.timeScale
end

--- Screen-space blue tint + vignette overlay + screen flash.
function BulletTime:drawOverlay(screenW, screenH)
    -- Screen flash (P1) — drawn regardless of BT state
    if self.screenFlash > 0 then
        love.graphics.setColor(self.flashR, self.flashG, self.flashB, self.screenFlash * 8)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    end

    if self.timeScale >= 0.95 then return end

    local intensity = 1.0 - self.timeScale   -- 0..1, stronger when slower

    -- Blue tint
    love.graphics.setColor(0.05, 0.08, 0.22, 0.45 * intensity)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Vignette (dark edges)
    local vig = 0.35 * intensity
    love.graphics.setColor(0, 0, 0, vig)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH * 0.10)
    love.graphics.rectangle("fill", 0, screenH * 0.90, screenW, screenH * 0.10)
    love.graphics.rectangle("fill", 0, 0, screenW * 0.07, screenH)
    love.graphics.rectangle("fill", screenW * 0.93, 0, screenW * 0.07, screenH)
end

return BulletTime
