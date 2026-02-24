-- conf.lua
-- TACTICAL-SHOOTER — isometric tactical stealth shooter (Intravenous-style)

function love.conf(t)
    t.title = "Tactical Shooter"
    t.version = "11.4"
    t.window.width = 1024
    t.window.height = 720
    t.window.resizable = false
    t.window.vsync = 1
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
end
