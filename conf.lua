-- conf.lua
-- LÖVE2D configuration for Bullet Hell game

function love.conf(t)
    t.title = "Bullet Hell"
    t.version = "11.4"
    t.window.width = 480
    t.window.height = 720
    t.window.resizable = false
    t.window.vsync = 1

    -- Disable unused modules for performance
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
end
