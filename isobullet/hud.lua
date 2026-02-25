-- hud.lua
-- Screen-space HUD: lives, score, wave, graze, bullet-time meter,
-- sight line, damage numbers, custom crosshair.

local Map   = require("map")
local Input = require("input")
local CRT   = require("crt")
local Utils = require("utils")

local HUD = {}

-- Damage numbers
HUD.damageNumbers = {}
local DMG_DURATION = 0.9

-- Score animation (P2)
HUD.displayScore = 0
HUD.scoreFlash = 0

function HUD.addDamageNumber(gx, gy, value)
    local sx, sy = Map.gridToScreen(gx, gy)
    table.insert(HUD.damageNumbers, {
        x = sx, y = sy, value = value, timer = DMG_DURATION,
    })
end

function HUD.updateDamageNumbers(dt, player)
    for i = #HUD.damageNumbers, 1, -1 do
        HUD.damageNumbers[i].timer = HUD.damageNumbers[i].timer - dt
        if HUD.damageNumbers[i].timer <= 0 then
            table.remove(HUD.damageNumbers, i)
        end
    end

    -- Score animation (P2)
    if player then
        local prev = HUD.displayScore
        HUD.displayScore = HUD.displayScore + (player.score - HUD.displayScore) * math.min(dt * 8, 1)
        if math.abs(player.score - HUD.displayScore) < 1 then HUD.displayScore = player.score end
        if HUD.displayScore ~= prev and prev < HUD.displayScore then
            HUD.scoreFlash = 0.3
        end
    end
    if HUD.scoreFlash > 0 then HUD.scoreFlash = HUD.scoreFlash - dt end
end

function HUD.drawDamageNumbers()
    for _, d in ipairs(HUD.damageNumbers) do
        local frac = d.timer / DMG_DURATION
        local sy = d.y - 20 - (1 - frac) * 14
        love.graphics.setColor(1, 0.4, 0.3, frac)
        love.graphics.print(tostring(d.value), d.x - 12, sy - 6)
    end
end

--------------------------------------------------------------------------------
-- Sight line (normal play — single raycast in aim direction)
--------------------------------------------------------------------------------
function HUD.drawSightLine(player)
    if player.dead then return end
    local ax = player.aimGX - player.x
    local ay = player.aimGY - player.y
    local aimLen = math.sqrt(ax * ax + ay * ay)
    if aimLen < 0.01 then return end
    ax, ay = ax / aimLen, ay / aimLen

    local ex, ey = Map.raycast(player.x, player.y, ax, ay, 14)
    local sx0, sy0 = Map.gridToScreen(player.x, player.y)
    local sx1, sy1 = Map.gridToScreen(ex, ey)

    love.graphics.setColor(0.4, 0.7, 1, 0.35)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(sx0, sy0 - 6, sx1, sy1)
    love.graphics.setLineWidth(1)
end

--------------------------------------------------------------------------------
-- Main HUD draw (screen-space, outside camera)
--------------------------------------------------------------------------------
function HUD.draw(player, spawner, bt, screenW, screenH)
    local font = love.graphics.getFont()
    local uiScale = math.min(screenW / 1024, screenH / 720)
    local lm = math.floor(12 * uiScale)  -- left margin
    local tm = math.floor(10 * uiScale)  -- top margin

    ---- Lives (top-left) ----
    love.graphics.setColor(1, 0.35, 0.3, 1)
    local livesStr = "LIVES "
    for _ = 1, player.lives do livesStr = livesStr .. "♥ " end
    love.graphics.print(livesStr, lm, tm)

    ---- Score with rolling animation (P2) ----
    local scoreBright = HUD.scoreFlash > 0 and math.min(1, HUD.scoreFlash * 3) or 0
    love.graphics.setColor(1, 1 - scoreBright * 0.3, 1 - scoreBright * 0.5, 0.9)
    local scoreStr = string.format("%08d", math.floor(HUD.displayScore))
    love.graphics.print(scoreStr, screenW - font:getWidth(scoreStr) - lm, tm)

    ---- Wave (top-center) ----
    love.graphics.setColor(1, 1, 0.5, 0.9)
    local waveStr
    if spawner.betweenWaves and spawner.wave > 0 then
        waveStr = string.format("WAVE %d CLEAR", spawner.wave)
    elseif spawner.wave == 0 then
        waveStr = "GET READY"
    else
        waveStr = string.format("WAVE %d", spawner.wave)
    end
    love.graphics.print(waveStr, (screenW - font:getWidth(waveStr)) / 2, tm)

    ---- Graze (below lives) ----
    love.graphics.setColor(0.7, 0.7, 1.0, 0.7)
    love.graphics.print(string.format("GRAZE %d", player.graze), lm, math.floor(28 * uiScale))

    ---- Bullet-time meter (bottom-center) ----
    local meterW = math.floor(200 * uiScale)
    local meterH = math.max(4, math.floor(8 * uiScale))
    local mx = (screenW - meterW) / 2
    local my = screenH - math.floor(28 * uiScale)

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
    love.graphics.rectangle("fill", mx - 1, my - 1, meterW + 2, meterH + 2, 3, 3)

    -- Fill
    local frac = bt.meter / bt.maxMeter
    local mr, mg, mb = 0.3, 0.6, 1.0
    if bt.active then mr, mg, mb = 0.5, 0.8, 1.0 end
    if frac < 0.2 then mr, mg, mb = 1.0, 0.3, 0.2 end
    love.graphics.setColor(mr, mg, mb, 0.85)
    love.graphics.rectangle("fill", mx, my, meterW * frac, meterH, 2, 2)

    -- Label
    love.graphics.setColor(0.7, 0.8, 1.0, 0.6)
    local label = bt.active and "▶ PRISM BEAM" or "CHRONO"
    love.graphics.print(label, mx + (meterW - font:getWidth(label)) / 2, my - math.floor(16 * uiScale))

    -- BT meter pulse when full (P1)
    if frac >= 0.99 and not bt.active then
        local pulse = 0.15 + 0.12 * math.sin(love.timer.getTime() * 5)
        love.graphics.setColor(0.3, 0.6, 1.0, pulse)
        love.graphics.rectangle("fill", mx - 2, my - 2, meterW + 4, meterH + 4, 4, 4)
        love.graphics.setColor(0.5, 0.8, 1.0, 0.5 + 0.3 * math.sin(love.timer.getTime() * 5))
        local readyStr = "READY"
        love.graphics.print(readyStr, mx + (meterW - font:getWidth(readyStr)) / 2, my + meterH + math.floor(4 * uiScale))
    end

    -- Wave splash text (P1)
    if spawner.waveStartFlash > 0 then
        local t = 1 - spawner.waveStartFlash / 1.5
        local scale = 2.5 * Utils.easeOutBack(math.min(t * 3, 1))
        if scale < 0.1 then goto skipWaveStart end
        local alpha = t < 0.6 and 1 or math.max(0, 1 - (t - 0.6) / 0.4)
        local waveText = string.format("WAVE %d", spawner.wave)
        love.graphics.setColor(1, 1, 0.5, alpha)
        love.graphics.push()
        love.graphics.translate(screenW / 2, screenH * 0.35)
        love.graphics.scale(scale, scale)
        love.graphics.print(waveText, -font:getWidth(waveText) / 2, -font:getHeight() / 2)
        love.graphics.pop()
        ::skipWaveStart::
    end
    if spawner.waveClearFlash > 0 then
        local t = 1 - spawner.waveClearFlash / 1.2
        local scale = 2.5 * Utils.easeOutBack(math.min(t * 3, 1))
        if scale < 0.1 then goto skipWaveClear end
        local alpha = t < 0.5 and 1 or math.max(0, 1 - (t - 0.5) / 0.5)
        local clearText = string.format("WAVE %d CLEAR!", spawner.wave)
        love.graphics.setColor(0.3, 1, 0.5, alpha)
        love.graphics.push()
        love.graphics.translate(screenW / 2, screenH * 0.35)
        love.graphics.scale(scale, scale)
        love.graphics.print(clearText, -font:getWidth(clearText) / 2, -font:getHeight() / 2)
        love.graphics.pop()
        ::skipWaveClear::
    end

    ---- Controls hint (fades out) ----
    if spawner.gameTime < 14 then
        local a = math.max(0, 1 - spawner.gameTime / 14)
        love.graphics.setColor(0.6, 0.6, 0.6, a * 0.6)
        if Input.isGamepadAiming() then
            love.graphics.print("L-Stick: move  |  R2: slow time → aim → fire  |  L2: cancel", lm, screenH - math.floor(22 * uiScale))
        else
            love.graphics.print("WASD: move  |  LMB: slow time → aim ricochet → fire  |  RMB: cancel", lm, screenH - math.floor(22 * uiScale))
        end
    end
end

--------------------------------------------------------------------------------
-- Custom crosshair (call last, in screen space)
--------------------------------------------------------------------------------
function HUD.drawCrosshair(btActive, player)
    local mx, my
    local uiScale = math.min(Map.screenW / 1024, Map.screenH / 720)

    if Input.isGamepadAiming() and player then
        -- Project crosshair from player's screen position along stick angle
        local psx, psy = Map.gridToScreen(player.x, player.y)
        local aim = Input.getGamepadAim()
        if aim then
            local dist = (btActive and 120 or 80) * uiScale
            mx = psx + math.cos(aim) * dist
            my = psy - 6 + math.sin(aim) * dist
        else
            -- Stick centered: use last aim angle
            local dist = (btActive and 120 or 80) * uiScale
            mx = psx + math.cos(player._lastAimAngle) * dist
            my = psy - 6 + math.sin(player._lastAimAngle) * dist
        end
    else
        mx, my = CRT.getMousePosition()
    end

    if btActive then
        -- Large crosshair during bullet-time
        local s = math.floor(14 * uiScale)
        local gap = math.floor(5 * uiScale)
        local ring = math.floor(20 * uiScale)
        love.graphics.setColor(0.5, 0.8, 1.0, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.line(mx - s, my, mx - gap, my)
        love.graphics.line(mx + gap, my, mx + s, my)
        love.graphics.line(mx, my - s, mx, my - gap)
        love.graphics.line(mx, my + gap, mx, my + s)
        love.graphics.setLineWidth(1)
        -- Center dot
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", mx, my, 2)
        -- Outer ring
        love.graphics.setColor(0.4, 0.6, 1.0, 0.3)
        love.graphics.circle("line", mx, my, ring)
    else
        -- Small crosshair
        local s = math.floor(7 * uiScale)
        local gap = math.floor(2 * uiScale)
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.setLineWidth(1)
        love.graphics.line(mx - s, my, mx - gap, my)
        love.graphics.line(mx + gap, my, mx + s, my)
        love.graphics.line(mx, my - s, mx, my - gap)
        love.graphics.line(mx, my + gap, mx, my + s)
        love.graphics.circle("fill", mx, my, 1)
    end
end

return HUD
