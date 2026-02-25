-- camera.lua
-- Camera wrapper for screen shake and zoom.
-- The isometric projection handles perspective; this only adds
-- shake offsets and zoom-around-center during bullet-time.

local Utils = require("utils")
local Map   = require("map")

local Camera = {}
Camera.__index = Camera

Camera.BASE_W = 1024
Camera.BASE_H = 720

function Camera.new(screenW, screenH)
    local self = setmetatable({}, Camera)
    self.screenW = screenW
    self.screenH = screenH
    self.baseScale = math.min(screenW / Camera.BASE_W, screenH / Camera.BASE_H)
    self.shakeTimer  = 0
    self.shakeAmount = 0
    self.offsetX = 0
    self.offsetY = 0
    self.zoom = 1.0
    self.targetZoom = 1.0
    return self
end

function Camera:resize(w, h)
    self.screenW = w
    self.screenH = h
    self.baseScale = math.min(w / Camera.BASE_W, h / Camera.BASE_H)
end

function Camera:update(dt)
    -- Shake decay
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
        self.offsetX = (math.random() - 0.5) * self.shakeAmount * 2 * self.baseScale
        self.offsetY = (math.random() - 0.5) * self.shakeAmount * 2 * self.baseScale
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
    local effectiveZoom = self.baseScale * self.zoom
    love.graphics.push()
    love.graphics.translate(hw + self.offsetX, hh + self.offsetY)
    love.graphics.scale(effectiveZoom, effectiveZoom)
    love.graphics.translate(-hw, -hh)
end

function Camera:pop()
    love.graphics.pop()
end

--- Convert screen (mouse) coords to world screen coords (undo zoom+shake).
function Camera:screenToWorld(sx, sy)
    local hw = self.screenW / 2
    local hh = self.screenH / 2
    local effectiveZoom = self.baseScale * self.zoom
    local wx = hw + (sx - hw - self.offsetX) / effectiveZoom
    local wy = hh + (sy - hh - self.offsetY) / effectiveZoom
    return wx, wy
end

return Camera
