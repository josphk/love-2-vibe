-- Static image scene: draws a loaded image scaled to fill the canvas.

local ImageScene = {}

local img
local sceneW, sceneH

function ImageScene.init(w, h)
    sceneW, sceneH = w, h
    if not img then
        img = love.graphics.newImage("example-img/omni-5b8bb84a-b0af-49fa-9b04-eaca6fa1a8af.png")
        img:setFilter("linear", "linear")
    end
end

function ImageScene.update(dt)
end

function ImageScene.draw()
    if not img then return end

    local iw, ih = img:getDimensions()
    local scale = math.max(sceneW / iw, sceneH / ih)
    local ox = (sceneW - iw * scale) / 2
    local oy = (sceneH - ih * scale) / 2

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, sceneW, sceneH)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, ox, oy, 0, scale, scale)
end

return ImageScene
