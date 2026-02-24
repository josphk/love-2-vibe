-- conf.lua
-- LÖVE2D configuration for Vampire Survivors-style roguelite

function love.conf(t)
    t.title = "Survivor"
    t.version = "11.4"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    t.window.vsync = 1

    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
end
