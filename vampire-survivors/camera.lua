-- camera.lua
-- Smooth-following camera centred on the player.

local Utils = require("utils")

local Camera = {}
Camera.__index = Camera

function Camera.new(screenW, screenH)
    local self = setmetatable({}, Camera)
    self.x = 0              -- world position of camera centre
    self.y = 0
    self.screenW = screenW
    self.screenH = screenH
    self.smoothing = 6      -- higher = snappier follow
    return self
end

--- Call once per frame before drawing.
function Camera:update(dt, targetX, targetY)
    local s = self.smoothing * dt
    self.x = Utils.lerp(self.x, targetX, math.min(s, 1))
    self.y = Utils.lerp(self.y, targetY, math.min(s, 1))
end

--- Push the LÖVE transform so that (camera.x, camera.y) is at screen centre.
function Camera:push()
    love.graphics.push()
    love.graphics.translate(
        math.floor(self.screenW / 2 - self.x),
        math.floor(self.screenH / 2 - self.y)
    )
end

function Camera:pop()
    love.graphics.pop()
end

--- Convert screen coords to world coords.
function Camera:toWorld(sx, sy)
    return sx - self.screenW / 2 + self.x,
           sy - self.screenH / 2 + self.y
end

--- Visible world bounds (for culling / spawning).
function Camera:bounds()
    local hw = self.screenW / 2
    local hh = self.screenH / 2
    return self.x - hw, self.y - hh, self.x + hw, self.y + hh
end

return Camera
