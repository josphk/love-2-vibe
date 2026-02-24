-- main.lua
-- Bullet Hell – a classic-style bullet hell game built with LÖVE2D.
--
-- Controls:
--   Arrow keys / WASD    Move
--   Space / Z             Shoot
--   Left Shift            Focus (slow movement, visible hitbox)
--   X                     Bomb (clears all enemy bullets)
--   R                     Restart (after game over)
--   Escape                Quit
--
-- The game features 5 hand-crafted waves followed by an endless procedural mode
-- with steadily increasing difficulty.

local Player     = require("player")
local BulletPool = require("bullet")
local Spawner    = require("spawner")
local Particles  = require("particles")
local Background = require("background")
local HUD        = require("hud")
local Utils      = require("utils")
local Sprites    = require("sprites")

--------------------------------------------------------------------------------
-- Game state
--------------------------------------------------------------------------------
local SCREEN_W, SCREEN_H
local player
local bullets
local spawner
local particles
local background

local gameOver      = false
local bombFlash     = 0        -- screen flash timer for bomb effect
local shakeTimer    = 0        -- screen shake
local shakeAmount   = 0
local powerItems    = {}       -- dropped power-up items

--------------------------------------------------------------------------------
-- Initialise / reset the game
--------------------------------------------------------------------------------
local function resetGame()
    player     = Player.new(SCREEN_W, SCREEN_H)
    bullets    = BulletPool.new(SCREEN_W, SCREEN_H)
    spawner    = Spawner.new(SCREEN_W, SCREEN_H)
    particles  = Particles.new()
    powerItems = {}
    gameOver   = false
    bombFlash  = 0
    shakeTimer = 0
end

--------------------------------------------------------------------------------
-- LÖVE callbacks
--------------------------------------------------------------------------------

function love.load()
    -- Smooth rendering
    love.graphics.setDefaultFilter("linear", "linear")

    SCREEN_W = love.graphics.getWidth()
    SCREEN_H = love.graphics.getHeight()

    -- Seed RNG
    math.randomseed(os.time())

    -- Use a clean default font at a readable size
    love.graphics.setFont(love.graphics.newFont(14))

    -- Build pixel-art alien sprites
    Sprites.load()

    background = Background.new(SCREEN_W, SCREEN_H)
    resetGame()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    -- Bomb
    if (key == "x") and not gameOver then
        if player:bomb() then
            -- Clear all enemy bullets, grant brief invuln
            bullets:clearEnemy()
            bombFlash = 0.5
            shakeTimer = 0.3
            shakeAmount = 6
            -- Award score for grazed bullets
            player.score = player.score + bullets:countEnemy() * 10
        end
    end

    -- Restart
    if key == "r" and gameOver then
        resetGame()
    end
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------
function love.update(dt)
    -- Cap dt to prevent spiral of death
    dt = math.min(dt, 1 / 30)

    background:update(dt)

    if gameOver then return end

    -- Player
    player:update(dt)

    -- Player shooting
    local newBullets = player:shoot()
    if newBullets then
        for _, b in ipairs(newBullets) do
            bullets:spawnPlayer(b)
        end
    end

    -- Enemies
    spawner:update(dt, bullets, player.x, player.y)

    -- Bullets
    bullets:update(dt)

    -- Particles
    particles:update(dt)

    -- Power items
    for i = #powerItems, 1, -1 do
        local item = powerItems[i]
        item.y = item.y + 80 * dt
        item.age = item.age + dt
        -- Attract to player when close
        local dist = Utils.distance(item.x, item.y, player.x, player.y)
        if dist < 60 or player.focused and dist < 120 then
            local angle = Utils.angleTo(item.x, item.y, player.x, player.y)
            item.x = item.x + math.cos(angle) * 300 * dt
            item.y = item.y + math.sin(angle) * 300 * dt
        end
        -- Collect
        if dist < 20 then
            player.power = math.min(4, player.power + 1)
            player.score = player.score + 50
            table.remove(powerItems, i)
        elseif item.y > SCREEN_H + 30 then
            table.remove(powerItems, i)
        end
    end

    -- Timers
    if bombFlash > 0 then bombFlash = bombFlash - dt end
    if shakeTimer > 0 then shakeTimer = shakeTimer - dt end

    ---------------------------------------------------------------------------
    -- COLLISION DETECTION
    ---------------------------------------------------------------------------

    -- Player bullets vs enemies
    for _, b in ipairs(bullets.player) do
        if not b.dead then
            for _, e in ipairs(spawner.enemies) do
                if not e.dead and Utils.circlesOverlap(b.x, b.y, b.radius, e.x, e.y, e.radius) then
                    b.dead = true
                    particles:spark(b.x, b.y, 0.5, 0.8, 1.0)
                    local killed = e:takeDamage(b.damage or 1)
                    if killed then
                        player.score = player.score + e.score
                        particles:explode(e.x, e.y, e.r, e.g, e.b, 20, 150)
                        shakeTimer = 0.15
                        shakeAmount = 4
                        -- Chance to drop power item
                        if math.random() < 0.3 and player.power < 4 then
                            table.insert(powerItems, {
                                x = e.x, y = e.y, age = 0
                            })
                        end
                    end
                    break
                end
            end
        end
    end

    -- Enemy bullets vs player
    if not player.dead and player.invulnTimer <= 0 then
        for _, b in ipairs(bullets.enemy) do
            if not b.dead then
                -- Graze detection (near miss)
                if not b.grazed and Utils.circlesOverlap(player.x, player.y, player.grazeRadius, b.x, b.y, b.radius) then
                    b.grazed = true
                    player.graze = player.graze + 1
                    player.score = player.score + 25
                end

                -- Actual hit (tiny hitbox)
                if Utils.circlesOverlap(player.x, player.y, player.hitboxRadius, b.x, b.y, b.radius) then
                    if player:hit() then
                        particles:explode(player.x, player.y, 0.3, 0.7, 1.0, 30, 200)
                        shakeTimer = 0.3
                        shakeAmount = 8
                        bullets:clearEnemy()  -- mercy clear on death
                        if player.dead then
                            gameOver = true
                        end
                    end
                    break
                end
            end
        end
    end

    -- Enemy bodies vs player (contact damage)
    if not player.dead and player.invulnTimer <= 0 then
        for _, e in ipairs(spawner.enemies) do
            if not e.dead and Utils.circlesOverlap(player.x, player.y, player.hitboxRadius, e.x, e.y, e.radius) then
                if player:hit() then
                    particles:explode(player.x, player.y, 1, 0.5, 0.2, 25, 180)
                    shakeTimer = 0.3
                    shakeAmount = 8
                    bullets:clearEnemy()
                    if player.dead then
                        gameOver = true
                    end
                end
                break
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------
function love.draw()
    -- Screen shake offset
    local sx, sy = 0, 0
    if shakeTimer > 0 then
        sx = (math.random() - 0.5) * shakeAmount * 2
        sy = (math.random() - 0.5) * shakeAmount * 2
    end
    love.graphics.push()
    love.graphics.translate(sx, sy)

    -- Dark background
    love.graphics.clear(0.02, 0.02, 0.08, 1)
    background:draw()

    -- Play-field border
    love.graphics.setColor(0.15, 0.15, 0.3, 0.8)
    love.graphics.rectangle("line", 0, 0, SCREEN_W, SCREEN_H)

    -- Power items
    for _, item in ipairs(powerItems) do
        local pulse = 0.7 + 0.3 * math.sin(item.age * 8)
        love.graphics.setColor(1, 0.4, 0.2, pulse)
        love.graphics.circle("fill", item.x, item.y, 6)
        love.graphics.setColor(1, 0.9, 0.5, pulse)
        love.graphics.circle("fill", item.x, item.y, 3)
    end

    -- Enemies
    spawner:draw()

    -- Bullets
    bullets:draw()

    -- Player
    player:draw()

    -- Particles (on top)
    particles:draw()

    love.graphics.pop()

    -- Bomb flash overlay
    if bombFlash > 0 then
        love.graphics.setColor(1, 1, 1, bombFlash * 0.6)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    end

    -- HUD (not affected by shake)
    HUD.draw(player, spawner, bullets, SCREEN_W, SCREEN_H)

    -- Game over overlay
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        love.graphics.setColor(1, 0.2, 0.2, 1)
        local goText = "GAME OVER"
        local font = love.graphics.getFont()
        love.graphics.print(goText, (SCREEN_W - font:getWidth(goText)) / 2, SCREEN_H / 2 - 30)

        love.graphics.setColor(1, 1, 1, 0.8)
        local scoreText = string.format("Final Score: %d", player.score)
        love.graphics.print(scoreText, (SCREEN_W - font:getWidth(scoreText)) / 2, SCREEN_H / 2)

        love.graphics.setColor(0.7, 0.7, 0.7, 0.6 + 0.4 * math.sin(love.timer.getTime() * 3))
        local restartText = "Press R to restart"
        love.graphics.print(restartText, (SCREEN_W - font:getWidth(restartText)) / 2, SCREEN_H / 2 + 30)
    end
end
