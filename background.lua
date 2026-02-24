-- background.lua
-- Scrolling starfield background for visual depth.

local Background = {}
Background.__index = Background

function Background.new(screenW, screenH)
    local self = setmetatable({}, Background)
    self.screenW = screenW
    self.screenH = screenH
    self.stars = {}

    -- Create several layers of stars with different speeds (parallax)
    local layers = { { count = 40, speed = 30, size = 1, alpha = 0.3 },
                     { count = 25, speed = 60, size = 1.5, alpha = 0.5 },
                     { count = 15, speed = 100, size = 2, alpha = 0.7 } }

    for _, layer in ipairs(layers) do
        for i = 1, layer.count do
            table.insert(self.stars, {
                x = math.random() * screenW,
                y = math.random() * screenH,
                speed = layer.speed + math.random() * 10,
                size = layer.size,
                alpha = layer.alpha,
            })
        end
    end
    return self
end

function Background.update(self, dt)
    for _, s in ipairs(self.stars) do
        s.y = s.y + s.speed * dt
        if s.y > self.screenH then
            s.y = s.y - self.screenH - 4
            s.x = math.random() * self.screenW
        end
    end
end

function Background.draw(self)
    for _, s in ipairs(self.stars) do
        love.graphics.setColor(0.7, 0.75, 1.0, s.alpha)
        love.graphics.circle("fill", s.x, s.y, s.size)
    end
end

return Background
