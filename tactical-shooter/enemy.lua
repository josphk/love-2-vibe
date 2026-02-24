-- enemy.lua
-- Enemy type definitions, spawn list, AI (patrol / chase / retreat), and draw.

local Map = require("map")
local Utils = require("utils")

local Enemy = {}

Enemy.TYPES = {
    grunt  = { name = "Grunt",  hp = 35,  speed = 2.2, viewDist = 7,  cooldown = 1.4, damage = 10, color = {0.65, 0.25, 0.25}, radius = 10 },
    scout  = { name = "Scout",  hp = 22,  speed = 3.2, viewDist = 9,  cooldown = 1.8, damage = 6,  color = {0.4, 0.5, 0.3},  radius = 9 },
    heavy  = { name = "Heavy",  hp = 65,  speed = 1.4, viewDist = 6,  cooldown = 0.9, damage = 18, color = {0.35, 0.2, 0.2}, radius = 13 },
    sniper = { name = "Sniper", hp = 30,  speed = 1.6, viewDist = 12, cooldown = 2.2, damage = 25, color = {0.5, 0.35, 0.5}, radius = 9 },
}

Enemy.SPAWNS = {
    { x = 20, y = 15, type = "grunt" },
    { x = 12, y = 17, type = "scout" },
    { x = 14, y = 10, type = "heavy" },
    { x = 18, y = 8,  type = "sniper" },
}

function Enemy.spawnAll()
    local list = {}
    for _, s in ipairs(Enemy.SPAWNS) do
        local def = Enemy.TYPES[s.type]
        local e = {
            x = s.x, y = s.y, type = s.type, name = def.name,
            hp = def.hp, maxHp = def.hp, speed = def.speed, viewDist = def.viewDist,
            shootCooldown = def.cooldown, damage = def.damage,
            color = def.color, radius = def.radius,
            state = "patrol", cooldown = 0, patrolT = math.random() * 6,
            faceX = 1, faceY = 0, lastSeenX = nil, lastSeenY = nil, alertTimer = 0,
        }
        table.insert(list, e)
    end
    return list
end

function Enemy.update(enemies, player, dt, spawnBulletFn)
    for _, e in ipairs(enemies) do
        if e.hp <= 0 then goto continue end

        local seePlayer = Utils.distance(e.x, e.y, player.x, player.y) <= e.viewDist and
            Map.lineOfSight(e.x, e.y, player.x, player.y)

        if seePlayer then
            e.state = "chase"
            e.lastSeenX, e.lastSeenY = player.x, player.y
            e.alertTimer = 3
        elseif e.state == "chase" and e.alertTimer > 0 then
            e.alertTimer = e.alertTimer - dt
        elseif e.alertTimer <= 0 then
            e.state = "patrol"
        end

        if e.state == "chase" then
            e.faceX = (e.lastSeenX or e.x) - e.x
            e.faceY = (e.lastSeenY or e.y) - e.y
        else
            e.faceX = math.cos(e.patrolT)
            e.faceY = math.sin(e.patrolT * 0.7)
        end
        local faceLen = math.sqrt(e.faceX * e.faceX + e.faceY * e.faceY)
        if faceLen < 0.01 then e.faceX, e.faceY = 1, 0 end

        if e.state == "chase" then
            e.cooldown = e.cooldown - dt
            local toPlayer = Utils.distance(e.x, e.y, player.x, player.y)
            if toPlayer < 7 and e.cooldown <= 0 and seePlayer then
                local dx, dy = Utils.normalize(player.x - e.x, player.y - e.y)
                spawnBulletFn(e.x, e.y, dx, dy, false, e.damage)
                e.cooldown = e.shootCooldown
            end
            local moveDx, moveDy
            if e.hp < e.maxHp * 0.3 then
                moveDx = e.x - player.x
                moveDy = e.y - player.y
            else
                moveDx = player.x - e.x
                moveDy = player.y - e.y
            end
            local len = math.sqrt(moveDx * moveDx + moveDy * moveDy)
            if len > 0.4 then
                moveDx, moveDy = moveDx / len * e.speed * dt, moveDy / len * e.speed * dt
                local nx, ny = e.x + moveDx, e.y + moveDy
                if not Map.isWall(nx, ny) then e.x, e.y = nx, ny end
            end
        else
            e.patrolT = e.patrolT + dt * 0.25
            local tx = e.x + math.sin(e.patrolT) * 2.5
            local ty = e.y + math.cos(e.patrolT * 0.8) * 2.5
            if not Map.isWall(tx, ty) then e.x, e.y = tx, ty end
        end
        ::continue::
    end
end

function Enemy.draw(e)
    local sx, sy = Map.gridToScreen(e.x, e.y)
    local r = (e.radius or 10) * 1.2
    local c = e.color or {0.6, 0.25, 0.25}
    love.graphics.setColor(c[1], c[2], c[3])
    love.graphics.ellipse("fill", sx, sy - 8, r, r * 0.75)
    love.graphics.setColor(math.min(1, c[1] + 0.2), math.min(1, c[2] + 0.15), math.min(1, c[3] + 0.15))
    love.graphics.ellipse("line", sx, sy - 8, r, r * 0.75)
end

function Enemy.allDead(enemies)
    for _, e in ipairs(enemies) do if e.hp > 0 then return false end end
    return true
end

return Enemy
