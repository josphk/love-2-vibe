-- camera.lua
-- Angled top-down camera.  Applies a Y-axis compression so the arena
-- looks like it's viewed from about 40 degrees above.
-- Also handles screen shake.

local Utils = require("utils")

local Camera = {}
Camera.__index = Camera

local Y_SCALE = 0.75          -- vertical compression factor

function Camera.new(screenW, screenH)
    local self = setmetatable({}, Camera)
    self.screenW = screenW
    self.screenH = screenH
    self.shakeTimer  = 0
    self.shakeAmount = 0
    self.offsetX = 0
    self.offsetY = 0
    self.zoom = 1.0            -- slight zoom during bullet-time
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

--- Push the angled-view transform.
function Camera:push()
    local hw = self.screenW / 2
    local hh = self.screenH / 2
    love.graphics.push()
    love.graphics.translate(hw + self.offsetX, hh + self.offsetY)
    love.graphics.scale(self.zoom, self.zoom * Y_SCALE)
    love.graphics.translate(-hw, -hh)
end

function Camera:pop()
    love.graphics.pop()
end

--- Convert screen (mouse) coordinates to world coordinates.
function Camera:screenToWorld(sx, sy)
    local hw = self.screenW / 2
    local hh = self.screenH / 2
    local wx = hw + (sx - hw - self.offsetX) / self.zoom
    local wy = hh + (sy - hh - self.offsetY) / (self.zoom * Y_SCALE)
    return wx, wy
end

--- Convert world coordinates to screen coordinates (for HUD overlays).
function Camera:worldToScreen(wx, wy)
    local hw = self.screenW / 2
    local hh = self.screenH / 2
    local sx = (wx - hw) * self.zoom + hw + self.offsetX
    local sy = (wy - hh) * (self.zoom * Y_SCALE) + hh + self.offsetY
    return sx, sy
end

Camera.Y_SCALE = Y_SCALE

return Camera
