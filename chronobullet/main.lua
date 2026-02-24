-- main.lua
-- CHRONOBULLET — a bullet hell with bullet-time aiming.
--
-- Controls:
--   WASD / Arrows       Move
--   Left click          Enter bullet-time → aim → fire beam
--   Right click         Cancel bullet-time without firing
--   R                   Restart after game over
--   Escape              Quit
--
-- Click once to slow time.  A dashed aim-line appears.
-- Click again to fire a devastating beam that pierces bullets and enemies.

local Player     = require("player")
local Bullets    = require("bullet")
local Spawner    = require("spawner")
local Particles  = require("particles")
local Camera     = require("camera")
local BulletTime = require("bullettime")
local Background = require("background")
local HUD        = require("hud")
local Sprites    = require("sprites")
local Utils      = require("utils")

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
    camera.zoom = 1.0
    camera.targetZoom = 1.0
    gameOver = false
end

--------------------------------------------------------------------------------
-- LÖVE callbacks
--------------------------------------------------------------------------------

function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    SCREEN_W = love.graphics.getWidth()
    SCREEN_H = love.graphics.getHeight()
    math.randomseed(os.time())
    love.graphics.setFont(love.graphics.newFont(14))
    love.mouse.setVisible(false)

    Sprites.load()
    camera = Camera.new(SCREEN_W, SCREEN_H)
    resetGame()
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" and gameOver then resetGame() end
end

function love.mousepressed(x, y, button)
    if gameOver then return end

    if button == 1 then  -- Left click
        if bt.active then
            -- FIRE BEAM
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
                    particles:text(player.x, player.y - 30,
                        result.destroyed .. " BULLETS!", 0.5, 0.9, 1.0)
                end
                if result.hit >= 2 then
                    particles:text(player.x, player.y - 50,
                        "MULTI-KILL!", 1.0, 0.9, 0.3)
                end
            end

            -- Exit bullet-time
            bt:deactivate()
            camera.targetZoom = 1.0
        else
            -- ENTER BULLET-TIME
            if bt:activate() then
                camera.targetZoom = 1.04   -- subtle zoom
            end
        end
    elseif button == 2 then  -- Right click: cancel
        if bt.active then
            bt:deactivate()
            camera.targetZoom = 1.0
        end
    end
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function love.update(realDt)
    realDt = math.min(realDt, 1 / 30)

    -- Bullet-time system (runs on real time)
    bt:update(realDt)
    camera:update(realDt)

    -- If BT was forced off (meter empty), reset zoom
    if not bt.active then camera.targetZoom = 1.0 end

    if gameOver then return end

    -- Scaled dt for world simulation
    local dt = bt:worldDt(realDt)

    -- Player (movement uses a blend: slower in BT but not frozen)
    local playerDt = bt.active and realDt * 0.35 or dt
    player:update(playerDt, camera)

    -- Enemy spawner & enemies
    spawner:update(dt, bullets, player.x, player.y)

    -- Bullets
    bullets:update(dt, Background.ARENA)

    -- Particles (use realDt so effects play at normal speed)
    particles:update(realDt)

    ---------------------------------------------------------------------------
    -- Graze detection (near misses refill meter + score)
    ---------------------------------------------------------------------------
    if not player.dead and player.invulnTimer <= 0 then
        for _, b in ipairs(bullets.list) do
            if not b.dead and not b.grazed then
                if Utils.circlesOverlap(player.x, player.y, player.grazeR, b.x, b.y, b.radius) then
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
                if Utils.circlesOverlap(player.x, player.y, player.hitboxR, b.x, b.y, b.radius) then
                    if player:hit() then
                        particles:burst(player.x, player.y, 1, 0.4, 0.3, 20, 120)
                        camera:shake(8, 0.3)
                        bullets:clearRadius(player.x, player.y, 80) -- mercy clear
                        if player.dead then gameOver = true end
                    end
                    break
                end
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Dead enemies → score (already handled in beam, but safety net)
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
    -- Dark void
    love.graphics.clear(0.03, 0.03, 0.06, 1)

    ---- World-space (inside angled camera) ----
    camera:push()

    Background.draw()

    -- Aim line (draw under entities for clarity)
    if bt.active and not player.dead then
        player:drawAimLine()
    end

    -- Enemies
    spawner:draw()

    -- Bullets
    bullets:draw(bt.timeScale)

    -- Player
    player:draw(bt.active)

    -- Particles (world-space)
    particles:draw()

    camera:pop()

    ---- Screen-space overlays ----

    -- Bullet-time tint
    bt:drawOverlay(SCREEN_W, SCREEN_H)

    -- HUD
    HUD.draw(player, spawner, bt, SCREEN_W, SCREEN_H)

    -- Custom crosshair
    HUD.drawCrosshair(bt.active, SCREEN_W, SCREEN_H)

    -- Game over
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        local font = love.graphics.getFont()

        love.graphics.setColor(1, 0.2, 0.2, 1)
        local t1 = "GAME OVER"
        love.graphics.print(t1, (SCREEN_W - font:getWidth(t1)) / 2, SCREEN_H / 2 - 40)

        love.graphics.setColor(1, 1, 1, 0.9)
        local t2 = string.format("Score: %d   Waves: %d   Graze: %d", player.score, spawner.wave, player.graze)
        love.graphics.print(t2, (SCREEN_W - font:getWidth(t2)) / 2, SCREEN_H / 2 - 10)

        love.graphics.setColor(0.7, 0.7, 0.7, 0.5 + 0.4 * math.sin(love.timer.getTime() * 3))
        local t3 = "Press R to restart"
        love.graphics.print(t3, (SCREEN_W - font:getWidth(t3)) / 2, SCREEN_H / 2 + 25)
    end
end
