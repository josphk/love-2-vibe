-- camera.lua
-- Camera wrapper for screen shake and zoom.
-- The isometric projection handles perspective; this only adds
-- shake offsets and zoom-around-center during bullet-time.

local Utils = require("utils")
local Map   = require("map")

local Camera = {}
Camera.__index = Camera

function Camera.new(screenW, screenH)
    local self = setmetatable({}, Camera)
    self.screenW = screenW
    self.screenH = screenH
    self.shakeTimer  = 0
    self.shakeAmount = 0
    self.offsetX = 0
    self.offsetY = 0
    self.zoom = 1.0
    self.targetZoom = 1.0
    return self
end

function Camera:update(dt)
    -- Shake decay
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
        self.offsetX = (math.random() - 0.5) * self.shakeAmount * 2
        self.offsetY = (math.random() - 0.5) * self.shakeAmount * 2
    else
        self.offsetX, self.offsetY = 0, 0
    end
    -- Zoom interpolation
    self.zoom = Utils.lerp(self.zoom, self.targetZoom, math.min(dt * 6, 1))
end

function Camera:shake(amount, duration)
    self.shakeAmount = math.max(self.shakeAmount, amount)
    self.shakeTimer  = math.max(self.shakeTimer, duration)
end

--- Push camera transform (zoom around screen center + shake).
function Camera:push()
    local hw = self.screenW / 2
    local hh = self.screenH / 2
    love.graphics.push()
    love.graphics.translate(hw + self.offsetX, hh + self.offsetY)
    love.graphics.scale(self.zoom, self.zoom)
    love.graphics.translate(-hw, -hh)
end

function Camera:pop()
    love.graphics.pop()
end

--- Convert screen (mouse) coords to world screen coords (undo zoom+shake).
function Camera:screenToWorld(sx, sy)
    local hw = self.screenW / 2
    local hh = self.screenH / 2
    local wx = hw + (sx - hw - self.offsetX) / self.zoom
    local wy = hh + (sy - hh - self.offsetY) / self.zoom
    return wx, wy
end

return Camera
