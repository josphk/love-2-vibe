-- hud.lua
-- Heads-up display: HP bar, XP bar, timer, level, kills, weapon icons.

local HUD = {}

local function formatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

function HUD.draw(player, spawner, screenW, screenH)
    local font = love.graphics.getFont()

    ---------------------------------------------------------------------------
    -- HP bar (bottom centre)
    ---------------------------------------------------------------------------
    local hpBarW = 200
    local hpBarH = 12
    local hpX = (screenW - hpBarW) / 2
    local hpY = screenH - 28

    -- Background
    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", hpX - 1, hpY - 1, hpBarW + 2, hpBarH + 2, 3, 3)
    -- Red fill
    local hpFrac = math.max(0, player.hp / player.maxHp)
    local hr, hg = 0.85, 0.2
    if hpFrac > 0.5 then hr, hg = 0.2, 0.8 end
    love.graphics.setColor(hr, hg, 0.15, 0.9)
    love.graphics.rectangle("fill", hpX, hpY, hpBarW * hpFrac, hpBarH, 2, 2)
    -- Text
    love.graphics.setColor(1, 1, 1, 0.9)
    local hpText = string.format("%d / %d", math.ceil(player.hp), player.maxHp)
    love.graphics.print(hpText, hpX + (hpBarW - font:getWidth(hpText)) / 2, hpY - 1)

    ---------------------------------------------------------------------------
    -- XP bar (top, full width)
    ---------------------------------------------------------------------------
    local xpBarH = 6
    love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, xpBarH)
    local xpFrac = player.xp / math.max(1, player.xpToNext)
    love.graphics.setColor(0.3, 0.5, 1.0, 0.9)
    love.graphics.rectangle("fill", 0, 0, screenW * xpFrac, xpBarH)

    ---------------------------------------------------------------------------
    -- Level (top-left)
    ---------------------------------------------------------------------------
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Lv." .. player.level, 8, xpBarH + 4)

    ---------------------------------------------------------------------------
    -- Timer (top-centre)
    ---------------------------------------------------------------------------
    local timeStr = formatTime(spawner.gameTime)
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.print(timeStr, (screenW - font:getWidth(timeStr)) / 2, xpBarH + 4)

    ---------------------------------------------------------------------------
    -- Kills (top-right)
    ---------------------------------------------------------------------------
    local killStr = "Kills: " .. player.kills
    love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
    love.graphics.print(killStr, screenW - font:getWidth(killStr) - 8, xpBarH + 4)

    ---------------------------------------------------------------------------
    -- Weapon slots (bottom-left)
    ---------------------------------------------------------------------------
    local wx, wy = 8, screenH - 60
    for i, w in ipairs(player.weapons) do
        -- Slot background
        love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
        love.graphics.rectangle("fill", wx, wy, 36, 36, 3, 3)
        love.graphics.setColor(0.4, 0.4, 0.6, 0.6)
        love.graphics.rectangle("line", wx, wy, 36, 36, 3, 3)
        -- Icon
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(w.def.icon, wx + 10, wy + 4)
        -- Level
        love.graphics.setColor(1, 1, 0.4, 0.8)
        love.graphics.print(w.level, wx + 24, wy + 20)
        wx = wx + 40
    end

    ---------------------------------------------------------------------------
    -- Stat summary (bottom-right, small)
    ---------------------------------------------------------------------------
    local stats = {}
    if player.mightMult > 1.0 then table.insert(stats, string.format("DMG x%.2f", player.mightMult)) end
    if player.speedMult > 1.0 then table.insert(stats, string.format("SPD x%.2f", player.speedMult)) end
    if player.cooldownMult < 1.0 then table.insert(stats, string.format("CD  x%.2f", player.cooldownMult)) end
    if player.armor > 0 then table.insert(stats, "ARM " .. player.armor) end
    if player.recovery > 0 then table.insert(stats, string.format("REC +%.1f/s", player.recovery)) end

    love.graphics.setColor(0.7, 0.7, 0.7, 0.55)
    local sy = screenH - 14 * #stats - 32
    for _, s in ipairs(stats) do
        love.graphics.print(s, screenW - font:getWidth(s) - 8, sy)
        sy = sy + 14
    end
end

return HUD
