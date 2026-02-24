-- main.lua
-- Survivor — a Vampire Survivors-style roguelite built with LÖVE2D.
--
-- Controls:
--   Arrow keys / WASD   Move
--   1 / 2 / 3           Choose upgrade on level-up
--   R                    Restart after game over
--   Escape               Quit
--
-- Weapons fire automatically.  Kill enemies to collect XP gems, level up,
-- and choose new weapons or upgrades.  Survive as long as you can!

local Player     = require("player")
local Spawner    = require("spawner")
local Weapons    = require("weapons")
local Gems       = require("gems")
local LevelUp    = require("levelup")
local Camera     = require("camera")
local Particles  = require("particles")
local Background = require("background")
local HUD        = require("hud")
local Sprites    = require("sprites")
local Utils      = require("utils")

--------------------------------------------------------------------------------
-- Game state
--------------------------------------------------------------------------------
local SCREEN_W, SCREEN_H
local player, spawner, gems, particles, camera, background, levelUp
local gameOver = false
local shakeTimer, shakeAmount = 0, 0

--------------------------------------------------------------------------------
-- Init / reset
--------------------------------------------------------------------------------
local function resetGame()
    player     = Player.new()
    spawner    = Spawner.new()
    gems       = Gems.new()
    particles  = Particles.new()
    camera     = Camera.new(SCREEN_W, SCREEN_H)
    levelUp    = LevelUp.new()
    Weapons.projectiles = {}
    gameOver   = false
    shakeTimer = 0

    -- Player starts with the Magic Wand
    table.insert(player.weapons, Weapons.create("wand"))
end

function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    SCREEN_W = love.graphics.getWidth()
    SCREEN_H = love.graphics.getHeight()
    math.randomseed(os.time())
    love.graphics.setFont(love.graphics.newFont(14))
    background = Background.new()
    Sprites.load()
    resetGame()
end

--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------
function love.keypressed(key)
    if key == "escape" then love.event.quit() end

    -- Level-up choice
    if levelUp.active then
        levelUp:keypressed(key, player)
        return
    end

    -- Restart
    if key == "r" and gameOver then resetGame() end
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function love.update(dt)
    dt = math.min(dt, 1 / 30)

    -- Camera always updates (smooth follow even during pause)
    camera:update(dt, player.x, player.y)

    -- Paused states
    if gameOver then return end
    if levelUp.active then return end

    -- Player movement
    player:update(dt)

    -- Weapon auto-fire
    Weapons.updatePlayer(player, spawner.enemies, dt)

    -- Weapon projectiles vs enemies
    Weapons.updateProjectiles(dt, player, spawner.enemies, particles)

    -- Enemy spawner
    spawner:update(dt, player.x, player.y, camera.x, camera.y, SCREEN_W, SCREEN_H)

    -- Gems
    local xpGained, healed = gems:update(dt, player)
    if healed > 0 then
        player:heal(healed)
        particles:floatingText(player.x, player.y - 20, "+" .. healed .. " HP", 0.2, 1, 0.4)
    end
    if xpGained > 0 then
        if player:addXP(xpGained) then
            levelUp:open(player)
        end
    end

    -- Particles
    particles:update(dt)

    -- Timers
    if shakeTimer > 0 then shakeTimer = shakeTimer - dt end

    ---------------------------------------------------------------------------
    -- Enemy contact damage vs player
    ---------------------------------------------------------------------------
    if not player.dead and player.invulnTimer <= 0 then
        for _, e in ipairs(spawner.enemies) do
            if not e.dead and e.contactTimer <= 0 then
                if Utils.circlesOverlap(player.x, player.y, player.hitboxRadius,
                                        e.x, e.y, e.radius) then
                    if player:hit(e.damage) then
                        particles:explode(player.x, player.y, 1, 0.4, 0.3, 15, 100)
                        particles:damageNumber(player.x, player.y - 16, e.damage, 1, 0.3, 0.2)
                        shakeTimer = 0.2
                        shakeAmount = 5
                        e.contactTimer = 0.5   -- cooldown before this enemy can hit again
                        if player.dead then
                            gameOver = true
                        end
                    end
                    break
                end
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Check killed enemies → spawn gems
    ---------------------------------------------------------------------------
    for _, e in ipairs(spawner.enemies) do
        if e.dead and not e.looted then
            e.looted = true
            player.kills = player.kills + 1
            gems:spawn(e.x, e.y, e.xp)
            -- Small chance to drop health
            if math.random() < 0.05 then
                gems:spawnHealth(e.x, e.y, 15)
            end
            particles:explode(e.x, e.y, e.r, e.g, e.b, 10, 80)
        end
    end
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------
function love.draw()
    -- Screen shake
    local sx, sy = 0, 0
    if shakeTimer > 0 then
        sx = (math.random() - 0.5) * shakeAmount * 2
        sy = (math.random() - 0.5) * shakeAmount * 2
    end

    love.graphics.push()
    love.graphics.translate(sx, sy)

    ---- World-space drawing (inside camera) ----
    love.graphics.clear(0.05, 0.06, 0.04, 1)
    background:draw(camera.x, camera.y, SCREEN_W, SCREEN_H)

    camera:push()

    -- Gems (under entities)
    gems:draw()

    -- Enemies
    spawner:draw()

    -- Weapon projectiles
    Weapons.drawProjectiles()

    -- Player
    player:draw()

    -- Particles (world-space)
    particles:draw()

    camera:pop()

    love.graphics.pop()

    ---- Screen-space UI ----
    HUD.draw(player, spawner, SCREEN_W, SCREEN_H)
    levelUp:draw(SCREEN_W, SCREEN_H)

    -- Game over overlay
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        local font = love.graphics.getFont()
        love.graphics.setColor(1, 0.2, 0.2, 1)
        local t1 = "YOU DIED"
        love.graphics.print(t1, (SCREEN_W - font:getWidth(t1)) / 2, SCREEN_H / 2 - 50)

        love.graphics.setColor(1, 1, 1, 0.9)
        local t2 = string.format("Survived  %02d:%02d", math.floor(spawner.gameTime / 60), math.floor(spawner.gameTime % 60))
        love.graphics.print(t2, (SCREEN_W - font:getWidth(t2)) / 2, SCREEN_H / 2 - 20)

        local t3 = string.format("Level %d  —  Kills %d", player.level, player.kills)
        love.graphics.print(t3, (SCREEN_W - font:getWidth(t3)) / 2, SCREEN_H / 2 + 5)

        love.graphics.setColor(0.7, 0.7, 0.7, 0.5 + 0.4 * math.sin(love.timer.getTime() * 3))
        local t4 = "Press R to restart"
        love.graphics.print(t4, (SCREEN_W - font:getWidth(t4)) / 2, SCREEN_H / 2 + 40)
    end
end
