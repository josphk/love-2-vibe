-- main.lua
-- TACTICAL-SHOOTER — isometric tactical stealth shooter (Intravenous-style).
--
-- Controls:
--   WASD              Move
--   Mouse             Aim
--   Left click        Shoot (line of sight required)
--   Escape            Quit
--
-- Enemies patrol, chase when they see you, and retreat when low HP.
-- Four enemy types: Grunt, Scout, Heavy, Sniper.

local Map = require("map")
local Player = require("player")
local Enemy = require("enemy")
local Bullet = require("bullet")
local Background = require("background")
local HUD = require("hud")
local Utils = require("utils")

local player
local enemies
local gameOver = false

local function resetGame()
    player = Player.new()
    enemies = Enemy.spawnAll()
    Bullet.list = {}
    HUD.damageNumbers = {}
    gameOver = false
end

function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    math.randomseed(os.time())
    love.graphics.setFont(love.graphics.newFont(14))

    Map.setScreenSize(love.graphics.getDimensions())
    Map.build()
    resetGame()
end

function love.update(dt)
    if gameOver then return end

    local screenW, screenH = love.graphics.getDimensions()
    Map.setScreenSize(screenW, screenH)

    Player.update(player, dt)
    HUD.update(dt)

    local function spawnBullet(x, y, dx, dy, fromPlayer, damage)
        Bullet.add(x, y, dx, dy, fromPlayer, damage)
    end
    Enemy.update(enemies, player, dt, spawnBullet)
    Bullet.update(dt)

    -- Bullet vs enemy / player collision
    for i = #Bullet.list, 1, -1 do
        local b = Bullet.list[i]
        if b.fromPlayer then
            for _, e in ipairs(enemies) do
                if e.hp > 0 and Utils.distance(b.x, b.y, e.x, e.y) < 0.85 then
                    e.hp = e.hp - b.damage
                    HUD.addDamageNumber(e.x, e.y - 0.5, -b.damage)
                    table.remove(Bullet.list, i)
                    goto next_bullet
                end
            end
        else
            if Utils.distance(b.x, b.y, player.x, player.y) < 0.8 then
                player.hp = player.hp - b.damage
                HUD.addDamageNumber(player.x, player.y - 0.5, -b.damage)
                table.remove(Bullet.list, i)
                if player.hp <= 0 then gameOver = "lose" end
                goto next_bullet
            end
        end
        ::next_bullet::
    end

    if Enemy.allDead(enemies) then gameOver = "win" end
end

function love.draw()
    local screenW, screenH = love.graphics.getDimensions()

    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    Background.draw()

    -- Draw order by depth (x + y)
    local entities = {}
    table.insert(entities, { type = "player", x = player.x, y = player.y })
    for _, e in ipairs(enemies) do
        if e.hp > 0 then table.insert(entities, { type = "enemy", x = e.x, y = e.y, e = e }) end
    end
    table.sort(entities, function(a, b) return (a.x + a.y) < (b.x + b.y) end)

    for _, ent in ipairs(entities) do
        if ent.type == "player" then
            Player.draw(player)
        else
            Enemy.draw(ent.e)
        end
    end

    HUD.drawDamageNumbers()
    Bullet.draw()
    HUD.drawPlayerSight(player)
    HUD.drawEnemySights(enemies)
    HUD.drawBars(player, screenH)
    HUD.drawGameOver(gameOver, screenW, screenH)
end

function love.mousereleased(x, y)
    if gameOver or player.hp <= 0 then return end
    if player.shootCooldown > 0 then return end

    local gx, gy = Map.screenToGrid(x, y)
    local dx = gx - player.x
    local dy = gy - player.y
    if Map.lineOfSight(player.x, player.y, gx, gy) then
        Bullet.add(player.x, player.y, dx, dy, true, Player.DAMAGE)
        player.shootCooldown = Player.SHOOT_COOLDOWN
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" and gameOver then resetGame() end
end
