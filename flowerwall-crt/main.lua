-- Flowerwall CRT — Love2D port
-- Original: https://github.com/Art-Michel/Flowerwall-CRT-shader-for-Godot (MIT)

local pipeline  = require("pipeline")
local demo      = require("demo_scene")
local debug_ui  = require("debug_ui")
local shaders   = require("shaders")
local presets   = require("presets")
local noise     = require("noise")

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    local noiseTex = noise.generate(256)
    pipeline.init(shaders, noiseTex, presets)
    demo.init(pipeline.INTERNAL_W, pipeline.INTERNAL_H)
    debug_ui.init(pipeline, presets)
end

function love.update(dt)
    demo.update(dt)
end

function love.draw()
    pipeline.beginDraw()
    demo.draw()
    pipeline.endDraw()
    debug_ui.draw()
end

function love.keypressed(key)
    if key == "f1" then
        debug_ui.toggle()
    elseif key == "f2" then
        pipeline.toggle()
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button)
    debug_ui.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    debug_ui.mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    debug_ui.mousemoved(x, y, dx, dy)
end
