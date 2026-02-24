-- hud.lua
-- Damage numbers, HP bar, sight/FOV overlay, game over, controls.

local Map = require("map")

local HUD = {}
HUD.DAMAGE_NUMBER_DURATION = 0.9
HUD.FOV_ANGLE = math.rad(55)
HUD.FOV_RANGE = 10
HUD.SIGHT_LINE_RANGE = 14

HUD.damageNumbers = {}

function HUD.addDamageNumber(wx, wy, value)
    table.insert(HUD.damageNumbers, { x = wx, y = wy, value = value, timer = HUD.DAMAGE_NUMBER_DURATION })
end

function HUD.update(dt)
    for i = #HUD.damageNumbers, 1, -1 do
        HUD.damageNumbers[i].timer = HUD.damageNumbers[i].timer - dt
        if HUD.damageNumbers[i].timer <= 0 then table.remove(HUD.damageNumbers, i) end
    end
end

function HUD.drawDamageNumbers()
    for _, d in ipairs(HUD.damageNumbers) do
        local sx, sy = Map.gridToScreen(d.x, d.y)
        sy = sy - 20 - (1 - d.timer / HUD.DAMAGE_NUMBER_DURATION) * 12
        local alpha = d.timer / HUD.DAMAGE_NUMBER_DURATION
        love.graphics.setColor(1, 0.4, 0.3, alpha)
        love.graphics.print(tostring(d.value), sx - 12, sy - 6)
    end
    love.graphics.setColor(1, 1, 1)
end

function HUD.drawPlayerSight(player)
    local ax = player.aimX - player.x
    local ay = player.aimY - player.y
    local aimLen = math.sqrt(ax * ax + ay * ay)
    if aimLen < 0.01 then aimLen = 1; ax, ay = 1, 0 end
    ax, ay = ax / aimLen, ay / aimLen
    local aimAngle = math.atan2(ay, ax)
    local verts = {}
    local px, py = Map.gridToScreen(player.x, player.y)
    table.insert(verts, px)
    table.insert(verts, py)
    for i = 0, 12 do
        local a = aimAngle - HUD.FOV_ANGLE + (2 * HUD.FOV_ANGLE) * i / 12
        local dx = math.cos(a)
        local dy = math.sin(a)
        local wx, wy = Map.raycast(player.x, player.y, dx, dy, HUD.FOV_RANGE)
        local sx, sy = Map.gridToScreen(wx, wy)
        table.insert(verts, sx)
        table.insert(verts, sy)
    end
    love.graphics.setColor(0.2, 0.4, 0.6, 0.25)
    love.graphics.polygon("fill", verts)
    local ex, ey = Map.raycast(player.x, player.y, ax, ay, HUD.SIGHT_LINE_RANGE)
    local sx1, sy1 = Map.gridToScreen(ex, ey)
    love.graphics.setColor(0.4, 0.7, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(px, py, sx1, sy1)
    love.graphics.setLineWidth(1)
end

function HUD.drawEnemySights(enemies)
    for _, e in ipairs(enemies) do
        if e.hp <= 0 or not e.faceX then goto next end
        local fx, fy = e.faceX, e.faceY
        local flen = math.sqrt(fx * fx + fy * fy)
        if flen < 0.01 then goto next end
        fx, fy = fx / flen, fy / flen
        local ex, ey = Map.raycast(e.x, e.y, fx, fy, e.viewDist or 8)
        local sx0, sy0 = Map.gridToScreen(e.x, e.y)
        local sx1, sy1 = Map.gridToScreen(ex, ey)
        if e.state == "chase" then
            love.graphics.setColor(0.9, 0.2, 0.2)
            love.graphics.setLineWidth(2)
        else
            love.graphics.setColor(0.5, 0.2, 0.2, 0.6)
            love.graphics.setLineWidth(1)
        end
        love.graphics.line(sx0, sy0, sx1, sy1)
        love.graphics.setLineWidth(1)
        ::next::
    end
    love.graphics.setColor(1, 1, 1)
end

function HUD.drawBars(player, screenH)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP " .. math.max(0, player.hp) .. "/" .. player.maxHp, 12, 12)
    love.graphics.setColor(0.5, 0.2, 0.2)
    love.graphics.rectangle("fill", 12, 28, 120, 10)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", 12, 28, 120 * (player.hp / player.maxHp), 10)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("WASD move | Mouse aim, click to shoot", 12, screenH - 24)
end

function HUD.drawGameOver(gameOver, screenW, screenH)
    if not gameOver then return end
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    love.graphics.setColor(1, 1, 1)
    if gameOver == "win" then
        love.graphics.print("Victory!", screenW / 2 - 40, screenH / 2 - 20)
    else
        love.graphics.print("Defeat", screenW / 2 - 30, screenH / 2 - 20)
    end
end

return HUD
