-- main.lua
-- ISOBULLET — isometric bullet hell with bullet-time aiming and bullet reflection.
--
-- Controls:
--   WASD / Arrows       Move
--   Left click          Enter bullet-time → aim ricochet → fire prism beam
--   Right click         Cancel bullet-time without firing
--   R                   Restart after game over
--   Escape              Quit
--
-- Combines the isometric grid and wall mechanics of a tactical shooter
-- with bullet-hell patterns and chronobullet's bullet-time system.
-- Bullets bounce off walls. The player's beam reflects too — ricochet shots!

local Map        = require("map")
local Player     = require("player")
local Bullets    = require("bullet")
local Spawner    = require("spawner")
local Particles  = require("particles")
local Camera     = require("camera")
local BulletTime = require("bullettime")
local Background = require("background")
local HUD        = require("hud")
local Utils      = require("utils")
local Input      = require("input")
local CRT        = require("crt")

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------
local SCREEN_W, SCREEN_H
local player, bullets, spawner, particles, camera, bt
local gameOver = false

local function resetGame()
    player    = Player.new()
    bullets   = Bullets.new()
    spawner   = Spawner.new()
    particles = Particles.new()
    bt        = BulletTime.new()
    camera.shakeTimer  = 0
    camera.shakeAmount = 0
    camera.zoom        = 1.0
    camera.targetZoom  = 1.0
    HUD.damageNumbers  = {}
    gameOver = false
end

--------------------------------------------------------------------------------
-- LÖVE callbacks
--------------------------------------------------------------------------------

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())
    love.mouse.setVisible(false)

    CRT.init()
    SCREEN_W, SCREEN_H = CRT.getRenderSize()
    love.graphics.setFont(love.graphics.newFont(math.floor(14 * math.min(SCREEN_W / 1024, SCREEN_H / 720))))

    Map.setScreenSize(SCREEN_W, SCREEN_H)
    Map.build()
    Input.init()
    camera = Camera.new(SCREEN_W, SCREEN_H)
    resetGame()
end

--------------------------------------------------------------------------------
-- Extracted action handlers (shared by mouse + gamepad)
--------------------------------------------------------------------------------
local function handleFire()
    if gameOver or player.dead then return end
    if bt.active then
        ---- FIRE REFLECTING BEAM ----
        local result = player:fireBeam(bullets, spawner.enemies, particles)
        if result then
            player.score = player.score + result.score
            camera:shake(6, 0.2)

            -- Hitstop for big kills
            if result.destroyed >= 5 or result.hit >= 1 then
                bt:triggerHitstop(0.06)
            end

            -- Meter refill from kills
            bt:addMeter(result.hit * 12 + result.destroyed * 1.5)

            -- Combo text
            if result.destroyed >= 5 then
                particles:text(player.x, player.y - 1,
                    result.destroyed .. " BULLETS!", 0.5, 0.9, 1.0)
            end
            if result.hit >= 2 then
                particles:text(player.x, player.y - 2,
                    "MULTI-KILL!", 1.0, 0.9, 0.3)
            end

            -- Ricochet bonus text
            if #result.segments > 1 and result.hit > 0 then
                particles:text(player.x, player.y - 3,
                    "RICOCHET!", 0.8, 0.6, 1.0)
                player.score = player.score + #result.segments * 50
            end
        end

        -- Exit bullet-time
        bt:deactivate()
        camera.targetZoom = 1.0
    else
        ---- ENTER BULLET-TIME ----
        if bt:activate() then
            camera.targetZoom = 1.03
        end
    end
end

local function handleCancel()
    if gameOver then return end
    if bt.active then
        bt:deactivate()
        camera.targetZoom = 1.0
    end
end

function love.resize(w, h)
    if CRT.enabled then
        SCREEN_W, SCREEN_H = CRT.INTERNAL_W, CRT.INTERNAL_H
    else
        SCREEN_W, SCREEN_H = w, h
    end
    Map.setScreenSize(SCREEN_W, SCREEN_H)
    camera:resize(SCREEN_W, SCREEN_H)
    love.graphics.setFont(love.graphics.newFont(math.floor(14 * camera.baseScale)))
end

function love.keypressed(key)
    Input.lastDevice = "keyboard"
    if key == "escape" then love.event.quit() end
    if key == "r" and gameOver then resetGame() end
    if key == "f10" then CRT.toggle(); love.resize(love.graphics.getDimensions()) end
    if key == "f11" then love.window.setFullscreen(not love.window.getFullscreen(), "desktop") end
end

function love.mousepressed(x, y, button)
    Input.lastDevice = "keyboard"
    if button == 1 then
        handleFire()
    elseif button == 2 then
        handleCancel()
    end
end

function love.mousemoved()
    Input.lastDevice = "keyboard"
end

function love.joystickadded(joystick)
    Input.joystickadded(joystick)
end

function love.joystickremoved(joystick)
    Input.joystickremoved(joystick)
end

function love.gamepadpressed(joystick, button)
    Input.gamepadpressed(joystick, button)
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function love.update(realDt)
    realDt = math.min(realDt, 1 / 30)

    -- Gamepad trigger edge detection
    Input.updateTriggers()

    -- Process gamepad action flags
    if Input.fireJustPressed    then handleFire() end
    if Input.cancelJustPressed  then handleCancel() end
    if Input.restartJustPressed and gameOver then resetGame() end
    if Input.quitJustPressed    then love.event.quit() end

    -- Bullet-time system (runs on real time)
    bt:update(realDt)
    camera:update(realDt)
    HUD.updateDamageNumbers(realDt)

    -- If BT was forced off (meter empty), reset zoom
    if not bt.active then camera.targetZoom = 1.0 end

    if gameOver then return end

    -- Scaled dt for world simulation
    local dt = bt:worldDt(realDt)

    -- Player (movement blend: slower in BT but responsive)
    local playerDt = bt.active and realDt * 0.35 or dt
    player:update(playerDt, camera)

    -- Enemies
    spawner:update(dt, bullets, player.x, player.y)

    -- Bullets (with bounce spark callback)
    bullets:update(dt, function(gx, gy, r, g, b)
        particles:wallSpark(gx, gy)
    end)

    -- Particles (use realDt so effects play at normal speed)
    particles:update(realDt)

    ---------------------------------------------------------------------------
    -- Graze detection
    ---------------------------------------------------------------------------
    if not player.dead and player.invulnTimer <= 0 then
        for _, b in ipairs(bullets.list) do
            if not b.dead and not b.grazed then
                if Utils.circlesOverlap(player.x, player.y, player.grazeR,
                                         b.x, b.y, b.radius) then
                    b.grazed = true
                    player.graze = player.graze + 1
                    player.score = player.score + 20
                    bt:addMeter(1.5)
                end
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Bullet → player collision
    ---------------------------------------------------------------------------
    if not player.dead and player.invulnTimer <= 0 then
        for _, b in ipairs(bullets.list) do
            if not b.dead then
                if Utils.circlesOverlap(player.x, player.y, player.hitboxR,
                                         b.x, b.y, b.radius) then
                    if player:hit() then
                        particles:burst(player.x, player.y, 1, 0.4, 0.3, 18, 110)
                        camera:shake(8, 0.3)
                        bullets:clearRadius(player.x, player.y, 3)   -- mercy clear (grid units)
                        if player.dead then gameOver = true end
                    end
                    break
                end
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Dead enemies → meter refill
    ---------------------------------------------------------------------------
    for _, e in ipairs(spawner.enemies) do
        if e.dead and not e.scored then
            e.scored = true
            bt:addMeter(10)
        end
    end
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------
function love.draw()
    CRT.beginDraw()
    love.graphics.clear(0.04, 0.04, 0.07, 1)

    ---- World-space (inside camera transform) ----
    camera:push()

    Background.draw()

    -- Sight line (normal play) or aim line (bullet-time)
    if bt.active and not player.dead then
        player:drawAimLine()
    else
        HUD.drawSightLine(player)
    end

    -- Depth-sort entities for isometric rendering
    local entities = {}
    table.insert(entities, { type = "player", depth = player.x + player.y })
    for _, e in ipairs(spawner.enemies) do
        if not e.dead then
            table.insert(entities, { type = "enemy", depth = e.x + e.y, e = e })
        end
    end
    table.sort(entities, function(a, b) return a.depth < b.depth end)

    for _, ent in ipairs(entities) do
        if ent.type == "player" then
            player:draw()
        else
            ent.e:draw()
        end
    end

    -- Bullets (drawn unsorted for performance)
    bullets:draw(bt.timeScale)

    -- Damage numbers (world-space)
    HUD.drawDamageNumbers()

    -- Particles (world-space)
    particles:draw()

    camera:pop()

    ---- Screen-space overlays ----

    -- Bullet-time tint
    bt:drawOverlay(SCREEN_W, SCREEN_H)

    -- HUD
    HUD.draw(player, spawner, bt, SCREEN_W, SCREEN_H)

    -- Custom crosshair
    HUD.drawCrosshair(bt.active, player)

    -- Game over
    if gameOver then
        local uiScale = math.min(SCREEN_W / 1024, SCREEN_H / 720)
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        local font = love.graphics.getFont()

        love.graphics.setColor(1, 0.2, 0.2, 1)
        local t1 = "GAME OVER"
        love.graphics.print(t1, (SCREEN_W - font:getWidth(t1)) / 2, SCREEN_H / 2 - 40 * uiScale)

        love.graphics.setColor(1, 1, 1, 0.9)
        local t2 = string.format("Score: %d   Waves: %d   Graze: %d",
            player.score, spawner.wave, player.graze)
        love.graphics.print(t2, (SCREEN_W - font:getWidth(t2)) / 2, SCREEN_H / 2 - 10 * uiScale)

        love.graphics.setColor(0.7, 0.7, 0.7, 0.5 + 0.4 * math.sin(love.timer.getTime() * 3))
        local t3 = Input.isGamepadAiming() and "Press X to restart" or "Press R to restart"
        love.graphics.print(t3, (SCREEN_W - font:getWidth(t3)) / 2, SCREEN_H / 2 + 25 * uiScale)
    end

    Input.endFrame()

    CRT.endDraw(love.graphics.getWidth(), love.graphics.getHeight())
end
