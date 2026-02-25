-- hud.lua
-- Screen-space HUD: lives, score, wave, graze, bullet-time meter,
-- deck strip, card timer, shield, active buffs, sight line, damage numbers, custom crosshair.

local Map = require("map")
local Buffs = require("buffs")
local HUD = {}

local STAT_NAMES = {
    chrono_regen = "Chrono Regen",
    chrono_drain = "Efficient Time",
    damage = "Damage",
    max_lives = "Max Lives",
    shield = "Shield",
    speed = "Speed",
    graze_meter = "Graze Charge",
    invuln_time = "Recovery",
}

-- Damage numbers
HUD.damageNumbers = {}
local DMG_DURATION = 0.9

function HUD.addDamageNumber(gx, gy, value)
    local sx, sy = Map.gridToScreen(gx, gy)
    table.insert(HUD.damageNumbers, {
        x = sx, y = sy, value = value, timer = DMG_DURATION,
    })
end

function HUD.updateDamageNumbers(dt)
    for i = #HUD.damageNumbers, 1, -1 do
        HUD.damageNumbers[i].timer = HUD.damageNumbers[i].timer - dt
        if HUD.damageNumbers[i].timer <= 0 then
            table.remove(HUD.damageNumbers, i)
        end
    end
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
function HUD.draw(player, spawner, bt, screenW, screenH, deck, gameTime)
    local font = love.graphics.getFont()
    gameTime = gameTime or 0

    ---- Lives (top-left) ----
    love.graphics.setColor(1, 0.35, 0.3, 1)
    local livesStr = "LIVES "
    for _ = 1, player.lives do livesStr = livesStr .. "♥ " end
    love.graphics.print(livesStr, 12, 10)

    ---- Shield (below lives) ----
    if player.shield and player.shield > 0 then
        love.graphics.setColor(0.4, 0.7, 1.0, 0.9)
        love.graphics.print(string.format("SHIELD %d", player.shield), 12, 26)
    end

    ---- Score (top-right) ----
    love.graphics.setColor(1, 1, 1, 0.9)
    local scoreStr = string.format("%08d", player.score)
    love.graphics.print(scoreStr, screenW - font:getWidth(scoreStr) - 12, 10)

    ---- Weapons (top-right: chrono always LMB/RMB; auto gun + Shift/Space) ----
    love.graphics.setColor(0.6, 0.75, 0.95, 0.9)
    love.graphics.print("Chrono: LMB / RMB", screenW - font:getWidth("Chrono: LMB / RMB") - 12, 26)
    local autoNames = { [2] = "Shotgun", [3] = "SMG", [4] = "Rifle" }
    local autoId = (player.currentWeapon and player.currentWeapon >= 2 and player.currentWeapon <= 4) and player.currentWeapon or 2
    local autoStr = "Auto: " .. (autoNames[autoId] or "Shotgun") .. "  [Shift]"
    love.graphics.setColor(0.7, 0.8, 0.9, 0.85)
    love.graphics.print(autoStr, screenW - font:getWidth(autoStr) - 12, 42)

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
    love.graphics.print(waveStr, (screenW - font:getWidth(waveStr)) / 2, 10)

    ---- Graze (below lives / shield) ----
    local leftY = 28
    if player.shield and player.shield > 0 then leftY = 42 end
    love.graphics.setColor(0.7, 0.7, 1.0, 0.7)
    love.graphics.print(string.format("GRAZE %d", player.graze), 12, leftY)

    ---- Deck strip + card timer (above chrono meter; fixed spacing to avoid overlap) ----
    local deckY
    if deck and #deck.list > 0 then
        deckY = screenH - 72
        local cardW, cardH = 72, 22
        local gap = 4
        local totalW = #deck.list * (cardW + gap) - gap
        local deckX = (screenW - totalW) / 2

        -- Card timer bar (fills over 3s)
        local timerFrac = 1 - deck.cardTimer / deck.baseInterval
        love.graphics.setColor(0.08, 0.08, 0.12, 0.9)
        love.graphics.rectangle("fill", deckX - 2, deckY - 20, totalW + 4, 6, 2, 2)
        love.graphics.setColor(0.5, 0.4, 0.9, 0.8)
        love.graphics.rectangle("fill", deckX, deckY - 18, totalW * timerFrac, 4, 1, 1)
        love.graphics.setColor(0.6, 0.5, 1.0, 0.5)
        love.graphics.print("Next card", deckX, deckY - 32)

        for i, card in ipairs(deck.list) do
            local cx = deckX + (i - 1) * (cardW + gap)
            local isNext = (i == 1)
            love.graphics.setColor(0.12, 0.12, 0.18, 0.95)
            if isNext then love.graphics.setColor(0.2, 0.18, 0.35, 0.95) end
            love.graphics.rectangle("fill", cx, deckY, cardW, cardH, 3, 3)
            love.graphics.setColor(isNext and 0.9 or 0.6, isNext and 0.85 or 0.55, 1.0, isNext and 1 or 0.7)
            local shortName = card.name and string.sub(card.name, 1, 10) or card.stat
            love.graphics.print(shortName, cx + 4, deckY + 4)
        end
        -- Card-play glow on slot 1 (unobtrusive feedback when a card just played)
        if deck.lastPlayedAt and gameTime and (gameTime - deck.lastPlayedAt) < 0.35 then
            local cx = deckX
            local glowAlpha = 1 - (gameTime - deck.lastPlayedAt) / 0.35
            love.graphics.setColor(0.6, 0.8, 1.0, 0.35 * glowAlpha)
            love.graphics.rectangle("fill", cx - 1, deckY - 1, cardW + 2, cardH + 2, 4, 4)
            love.graphics.setColor(0.8, 0.9, 1.0, 0.5 * glowAlpha)
            love.graphics.setLineWidth(1.5)
            love.graphics.rectangle("line", cx - 1, deckY - 1, cardW + 2, cardH + 2, 4, 4)
            love.graphics.setLineWidth(1)
        end
    end

    ---- Bullet-time meter (bottom of screen; below deck to avoid overlap) ----
    local meterW = 200
    local meterH = 8
    local mx = (screenW - meterW) / 2
    local my = screenH - 24

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
    love.graphics.print(label, mx + (meterW - font:getWidth(label)) / 2, my - 14)

    ---- Controls hint (very bottom; includes Space for auto-fire) ----
    if spawner.gameTime < 14 then
        local a = math.max(0, 1 - spawner.gameTime / 14)
        love.graphics.setColor(0.6, 0.6, 0.6, a * 0.6)
        love.graphics.print("WASD move  |  LMB/RMB chrono  |  Shift: cycle auto gun", 12, screenH - 12)
    end

    ---- Active buffs (right side, duration bars; below weapon lines to avoid overlap) ----
    local buffList = Buffs.getActiveList(gameTime)
    if #buffList > 0 then
        local bx = screenW - 12
        local by = 58
        local barW, barH = 80, 6
        love.graphics.setColor(0.5, 0.6, 0.8, 0.5)
        love.graphics.print("BUFFS", bx - font:getWidth("BUFFS"), by - 14)
        for i, b in ipairs(buffList) do
            local name = STAT_NAMES[b.statId] or b.statId
            local frac = (b.duration and b.duration > 0) and (b.remaining / b.duration) or 0
            local barX = bx - barW - 4
            local barY = by + (i - 1) * (barH + 6)
            love.graphics.setColor(0.08, 0.08, 0.12, 0.9)
            love.graphics.rectangle("fill", barX - 1, barY - 1, barW + 2, barH + 2, 2, 2)
            love.graphics.setColor(0.35, 0.55, 0.9, 0.85)
            love.graphics.rectangle("fill", barX, barY, barW * frac, barH, 1, 1)
            local shortName = string.sub(name, 1, 12)
            love.graphics.setColor(0.7, 0.85, 1.0, 0.8)
            love.graphics.print(shortName, barX - font:getWidth(shortName) - 6, barY - 2)
        end
    end

end

--------------------------------------------------------------------------------
-- Custom crosshair (call last, in screen space)
--------------------------------------------------------------------------------
function HUD.drawCrosshair(btActive)
    local mx, my = love.mouse.getPosition()

    if btActive then
        -- Large crosshair during bullet-time
        local s = 14
        love.graphics.setColor(0.5, 0.8, 1.0, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.line(mx - s, my, mx - 5, my)
        love.graphics.line(mx + 5, my, mx + s, my)
        love.graphics.line(mx, my - s, mx, my - 5)
        love.graphics.line(mx, my + 5, mx, my + s)
        love.graphics.setLineWidth(1)
        -- Center dot
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", mx, my, 2)
        -- Outer ring
        love.graphics.setColor(0.4, 0.6, 1.0, 0.3)
        love.graphics.circle("line", mx, my, 20)
    else
        -- Small crosshair
        local s = 7
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.setLineWidth(1)
        love.graphics.line(mx - s, my, mx - 2, my)
        love.graphics.line(mx + 2, my, mx + s, my)
        love.graphics.line(mx, my - s, mx, my - 2)
        love.graphics.line(mx, my + 2, mx, my + s)
        love.graphics.circle("fill", mx, my, 1)
    end
end

return HUD
