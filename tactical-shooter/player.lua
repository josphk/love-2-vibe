-- player.lua
-- Player state, movement, aim, and shoot cooldown.

local Map = require("map")
local Utils = require("utils")

local Player = {}
Player.SPEED = 3.5
Player.MAX_HP = 100
Player.DAMAGE = 28
Player.SHOOT_COOLDOWN = 0.35

function Player.new()
    return {
        x = 4, y = 4,
        hp = Player.MAX_HP, maxHp = Player.MAX_HP,
        aimX = 5, aimY = 4,
        shootCooldown = 0,
    }
end

function Player.update(p, dt)
    local mx, my = love.mouse.getPosition()
    p.aimX, p.aimY = Map.screenToGrid(mx, my)

    local vx, vy = 0, 0
    if love.keyboard.isDown("w") then vy = vy - 1 end
    if love.keyboard.isDown("s") then vy = vy + 1 end
    if love.keyboard.isDown("a") then vx = vx - 1 end
    if love.keyboard.isDown("d") then vx = vx + 1 end
    if vx ~= 0 or vy ~= 0 then
        vx, vy = Utils.normalize(vx, vy)
        vx, vy = vx * Player.SPEED * dt, vy * Player.SPEED * dt
        local nx, ny = p.x + vx, p.y + vy
        if not Map.isWall(nx, ny) then p.x, p.y = nx, ny end
    end

    if p.shootCooldown > 0 then p.shootCooldown = p.shootCooldown - dt end
end

function Player.draw(p)
    local sx, sy = Map.gridToScreen(p.x, p.y)
    love.graphics.setColor(0.3, 0.5, 0.7)
    love.graphics.ellipse("fill", sx, sy - 8, 14, 10)
    love.graphics.setColor(0.5, 0.6, 0.8)
    love.graphics.ellipse("line", sx, sy - 8, 14, 10)
end

return Player
