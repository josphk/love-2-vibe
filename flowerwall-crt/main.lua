-- Flowerwall CRT — Love2D port
-- Original: https://github.com/Art-Michel/Flowerwall-CRT-shader-for-Godot (MIT)

local pipeline    = require("pipeline")
local demo        = require("demo_scene")
local image_scene = require("image_scene")
local debug_ui    = require("debug_ui")
local shaders     = require("shaders")
local presets     = require("presets")
local noise       = require("noise")

local scenes = { demo, image_scene }
local sceneIdx = 1

function love.load()
    local noiseTex = noise.generate(256)
    pipeline.init(shaders, noiseTex, presets)
    local w, h = love.graphics.getDimensions()
    demo.init(w, h)
    image_scene.init(w, h)
    debug_ui.init(pipeline, presets)
end

function love.update(dt)
    scenes[sceneIdx].update(dt)
end

function love.draw()
    pipeline.beginDraw()
    scenes[sceneIdx].draw()
    pipeline.endDraw()
    debug_ui.draw()
end

function love.resize(w, h)
    pipeline.resize(w, h)
    demo.init(w, h)
    image_scene.init(w, h)
end

function love.keypressed(key)
    if key == "f1" then
        debug_ui.toggle()
    elseif key == "f2" then
        pipeline.toggle()
    elseif key == "f3" then
        sceneIdx = (sceneIdx % #scenes) + 1
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
