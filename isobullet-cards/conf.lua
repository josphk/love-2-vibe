-- conf.lua
-- ISOBULLET-CARDS — fork of isobullet (isometric bullet hell with bullet-time and bullet reflection)

function love.conf(t)
    t.title = "ISOBULLET-CARDS"
    t.version = "11.4"
    t.window.width = 1024
    t.window.height = 720
    t.window.resizable = false
    t.window.vsync = 1
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
end
