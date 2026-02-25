-- main.lua
-- ISOBULLET — isometric bullet hell with bullet-time aiming and bullet reflection.
--
-- Controls:
--   WASD / Arrows       Move
--   Left click          Enter bullet-time → aim ricochet → fire prism beam
--   Right click         Cancel bullet-time without firing
--   R                   Restart after game over
--   Escape              Quit
--
-- Combines the isometric grid and wall mechanics of a tactical shooter
-- with bullet-hell patterns and chronobullet's bullet-time system.
-- Bullets bounce off walls. The player's beam reflects too — ricochet shots!

local Map        = require("map")
local Player     = require("player")
local Bullets    = require("bullet")
local Spawner    = require("spawner")
local Particles  = require("particles")
local Camera     = require("camera")
local BulletTime = require("bullettime")
local Background = require("background")
local HUD        = require("hud")
local Utils      = require("utils")
local Buffs      = require("buffs")
local Deck       = require("deck")
local Gem        = require("gem")

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------
local SCREEN_W, SCREEN_H
local player, bullets, spawner, particles, camera, bt, deck
local gameOver = false
local gamePhase = "pick_cards"   -- "pick_cards" | "playing" | "game_over"
local chosenCardIds = {}        -- up to 5 card ids for starter deck

-- Auto-weapon fire state (weapons 2=shotgun, 3=smg, 4=rifle)
local autoFireCooldown = 0
local autoBurstLeft    = 0     -- rifle: shots left in current burst
local autoBurstDelay   = 0     -- rifle: delay until next shot in burst

local function resetGame(selectedIds)
    player    = Player.new()
    bullets   = Bullets.new()
    spawner   = Spawner.new()
    particles = Particles.new()
    bt        = BulletTime.new()
    camera.shakeTimer  = 0
    camera.shakeAmount = 0
    camera.zoom        = 1.0
    camera.targetZoom  = 1.0
    HUD.damageNumbers  = {}
    Buffs.clear()
    deck = Deck.new(selectedIds)
    Gem.list = {}
    gameOver = false
    gamePhase = "playing"
    love.mouse.setVisible(false)
    autoFireCooldown = 0
    autoBurstLeft    = 0
    autoBurstDelay   = 0
end

--------------------------------------------------------------------------------
-- Pick-cards UI layout and draw
--------------------------------------------------------------------------------
local CARD_BUTTON_W, CARD_BUTTON_H, CARD_GAP = 100, 28, 8
local POOL_START_X, POOL_START_Y = 80, 100
local CHOSEN_Y = 200
local START_BUTTON_W, START_BUTTON_H = 100, 36

local function getPoolCardAt(mx, my)
    local pool = Deck.getCardPool()
    for i = 0, #pool - 1 do
        local col = i % 5
        local row = math.floor(i / 5)
        local x = POOL_START_X + col * (CARD_BUTTON_W + CARD_GAP)
        local y = POOL_START_Y + row * (CARD_BUTTON_H + CARD_GAP)
        if mx >= x and mx <= x + CARD_BUTTON_W and my >= y and my <= y + CARD_BUTTON_H then
            return i + 1, pool[i + 1]
        end
    end
    return nil, nil
end

local function getChosenSlotAt(mx, my)
    local n = #chosenCardIds
    local totalW = n * CARD_BUTTON_W + (n - 1) * CARD_GAP
    local startX = (SCREEN_W - totalW) / 2
    for i = 1, n do
        local x = startX + (i - 1) * (CARD_BUTTON_W + CARD_GAP)
        if mx >= x and mx <= x + CARD_BUTTON_W and my >= CHOSEN_Y and my <= CHOSEN_Y + CARD_BUTTON_H then
            return i
        end
    end
    return nil
end

local function getStartButtonAt(mx, my)
    local x = (SCREEN_W - START_BUTTON_W) / 2
    local y = SCREEN_H - 80
    if mx >= x and mx <= x + START_BUTTON_W and my >= y and my <= y + START_BUTTON_H then
        return true
    end
    return false
end

local function drawPickCardsUI()
    love.graphics.setColor(0.06, 0.06, 0.1, 0.95)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    local font = love.graphics.getFont()
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.print("Choose 5 cards", (SCREEN_W - font:getWidth("Choose 5 cards")) / 2, 40)
    love.graphics.setColor(0.5, 0.6, 0.8, 0.7)
    love.graphics.print("Mouse: click to add/remove. Keys: 1-0 add pool card, Backspace remove, Enter start", (SCREEN_W - font:getWidth("Mouse: click to add/remove. Keys: 1-0 add pool card, Backspace remove, Enter start")) / 2, 62)

    local pool = Deck.getCardPool()
    for i = 0, #pool - 1 do
        local col = i % 5
        local row = math.floor(i / 5)
        local x = POOL_START_X + col * (CARD_BUTTON_W + CARD_GAP)
        local y = POOL_START_Y + row * (CARD_BUTTON_H + CARD_GAP)
        local c = pool[i + 1]
        love.graphics.setColor(0.15, 0.15, 0.22, 0.95)
        love.graphics.rectangle("fill", x, y, CARD_BUTTON_W, CARD_BUTTON_H, 4, 4)
        love.graphics.setColor(0.7, 0.8, 1.0, 0.9)
        love.graphics.print(c.name or c.id, x + 6, y + 6)
    end

    love.graphics.setColor(0.5, 0.5, 0.6, 0.6)
    love.graphics.print("Chosen (" .. #chosenCardIds .. "/5):", 80, CHOSEN_Y - 22)
    local n = #chosenCardIds
    local totalW = n * CARD_BUTTON_W + (n > 0 and (n - 1) * CARD_GAP or 0)
    local startX = (SCREEN_W - totalW) / 2
    for i = 1, n do
        local id = chosenCardIds[i]
        local c = nil
        for _, card in ipairs(pool) do if card.id == id then c = card break end end
        local x = startX + (i - 1) * (CARD_BUTTON_W + CARD_GAP)
        love.graphics.setColor(0.2, 0.25, 0.4, 0.95)
        love.graphics.rectangle("fill", x, CHOSEN_Y, CARD_BUTTON_W, CARD_BUTTON_H, 4, 4)
        love.graphics.setColor(0.85, 0.9, 1.0, 1)
        love.graphics.print(c and c.name or id, x + 6, CHOSEN_Y + 6)
    end

    if n == 5 then
        local x = (SCREEN_W - START_BUTTON_W) / 2
        local y = SCREEN_H - 80
        love.graphics.setColor(0.2, 0.5, 0.3, 0.95)
        love.graphics.rectangle("fill", x, y, START_BUTTON_W, START_BUTTON_H, 6, 6)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Start", x + (START_BUTTON_W - font:getWidth("Start")) / 2, y + 10)
    end
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
    Map.setScreenSize(SCREEN_W, SCREEN_H)
    Map.build()
    camera = Camera.new(SCREEN_W, SCREEN_H)
    gamePhase = "pick_cards"
    chosenCardIds = {}
    love.mouse.setVisible(true)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" and gameOver then resetGame(chosenCardIds) end

    -- Shift: cycle auto guns (Shotgun → SMG → Rifle → Shotgun); chrono is always LMB/RMB
    if (key == "lshift" or key == "rshift") and gamePhase == "playing" and not gameOver then
        if player.currentWeapon == 1 then
            player.currentWeapon = 2
        else
            -- (current - 1) % 3 + 2 gives 2→3, 3→4, 4→2
            player.currentWeapon = ((player.currentWeapon - 1) % 3) + 2
        end
    end

    if gamePhase == "pick_cards" then
        local pool = Deck.getCardPool()
        local num = (key == "0") and 10 or (tonumber(key) or 0)
        if num >= 1 and num <= 10 and num <= #pool and #chosenCardIds < 5 then
            table.insert(chosenCardIds, pool[num].id)
            return
        end
        if key == "backspace" and #chosenCardIds > 0 then
            table.remove(chosenCardIds)
            return
        end
        if (key == "return" or key == "space") and #chosenCardIds == 5 then
            resetGame(chosenCardIds)
        end
        return
    end
end

function love.mousereleased(x, y, button)
    if button ~= 1 or gamePhase ~= "pick_cards" then return end
    local poolIdx, card = getPoolCardAt(x, y)
    if poolIdx and card and #chosenCardIds < 5 then
        table.insert(chosenCardIds, card.id)
        return
    end
    local chosenSlot = getChosenSlotAt(x, y)
    if chosenSlot then
        table.remove(chosenCardIds, chosenSlot)
        return
    end
    if #chosenCardIds == 5 and getStartButtonAt(x, y) then
        resetGame(chosenCardIds)
    end
end

function love.mousepressed(x, y, button)
    if gamePhase == "pick_cards" then return end
    if gameOver then return end

    -- LMB/RMB always control chrono (bullet-time + beam); auto guns use Space in update
    if button == 1 then
        if bt.active then
            ---- FIRE REFLECTING BEAM ----
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
                    particles:text(player.x, player.y - 1,
                        result.destroyed .. " BULLETS!", 0.5, 0.9, 1.0)
                end
                if result.hit >= 2 then
                    particles:text(player.x, player.y - 2,
                        "MULTI-KILL!", 1.0, 0.9, 0.3)
                end

                -- Ricochet bonus text
                if #result.segments > 1 and result.hit > 0 then
                    particles:text(player.x, player.y - 3,
                        "RICOCHET!", 0.8, 0.6, 1.0)
                    player.score = player.score + #result.segments * 50
                end
            end

            -- Exit bullet-time
            bt:deactivate()
            camera.targetZoom = 1.0
        else
            ---- ENTER BULLET-TIME ----
            if bt:activate() then
                camera.targetZoom = 1.03
            end
        end
    elseif button == 2 then   -- Right click: cancel chrono
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
    if gamePhase ~= "playing" then return end

    -- Bullet-time system (runs on real time)
    bt:update(realDt)
    camera:update(realDt)
    HUD.updateDamageNumbers(realDt)

    -- If BT was forced off (meter empty), reset zoom
    if not bt.active then camera.targetZoom = 1.0 end

    if gameOver then return end

    -- Scaled dt for world simulation
    local dt = bt:worldDt(realDt)

    -- Player (movement blend: slower in BT but responsive)
    local playerDt = bt.active and realDt * 0.35 or dt
    player:update(playerDt, camera)

    -- Enemies
    spawner:update(dt, bullets, player.x, player.y)

    -- Buffs (duration-based; use spawner game time)
    Buffs.update(spawner.gameTime)

    -- Apply buff multipliers to BulletTime
    bt.rechargeRate = bt.baseRechargeRate * Buffs.getMultiplier("chrono_regen")
    bt.drainRate = bt.baseDrainRate * Buffs.getMultiplier("chrono_drain")

    -- Apply buff multipliers to Player (runtime stats)
    player.beamDamage = 40 * Buffs.getMultiplier("damage")
    player.speed = 4 * Buffs.getMultiplier("speed")
    player.maxLives = math.max(5, math.floor(5 * Buffs.getMultiplier("max_lives")))
    player.invulnTime = 2.0 * Buffs.getMultiplier("invuln_time")

    ---------------------------------------------------------------------------
    -- Auto-weapon fire (shotgun / SMG / assault rifle); only when not in BT
    ---------------------------------------------------------------------------
    if not player.dead and not bt.active and player.currentWeapon >= 2 then
        autoFireCooldown = autoFireCooldown - dt
        if player.currentWeapon == 4 then
            autoBurstDelay = autoBurstDelay - dt
        end

        local function spawnPlayerBullet(angle, speed, life, maxBounces, dmg, r, g, b)
            local vx = speed * math.cos(angle)
            local vy = speed * math.sin(angle)
            bullets:spawn({
                x = player.x, y = player.y, vx = vx, vy = vy,
                life = life, maxBounces = maxBounces,
                fromPlayer = true, damage = dmg,
                r = r, g = g, b = b,
            })
        end

        if player.currentWeapon == 2 then
            -- Shotgun: cone of 8 pellets, low range, ricochet
            if autoFireCooldown <= 0 then
                local spread = 0.35
                local speed, life, maxBounces = 6, 1.2, 2
                local dmg = player.beamDamage * 0.15
                local r, g, b = 1, 0.5, 0.2
                for _ = 1, 8 do
                    local angle = player.aimAngle + (math.random() * 2 - 1) * spread
                    spawnPlayerBullet(angle, speed, life, maxBounces, dmg, r, g, b)
                end
                autoFireCooldown = 0.7
            end
        elseif player.currentWeapon == 3 then
            -- SMG: semi-cone, medium range and RoF
            if autoFireCooldown <= 0 then
                local spread = 0.06
                local angle = player.aimAngle + (math.random() * 2 - 1) * spread
                spawnPlayerBullet(angle, 14, 2, 1, player.beamDamage * 0.2, 1, 0.9, 0.2)
                autoFireCooldown = 0.07
            end
        elseif player.currentWeapon == 4 then
            -- Assault rifle: burst of 3, long range, accurate
            if autoBurstLeft == 0 and autoFireCooldown <= 0 then
                autoBurstLeft = 3
                autoBurstDelay = 0
                autoFireCooldown = 0.45
            end
            if autoBurstLeft > 0 and autoBurstDelay <= 0 then
                local spread = 0.02
                local angle = player.aimAngle + (math.random() * 2 - 1) * spread
                spawnPlayerBullet(angle, 18, 2.5, 1, player.beamDamage * 0.25, 0.9, 0.9, 1)
                autoBurstLeft = autoBurstLeft - 1
                autoBurstDelay = 0.05
            end
        end
    end

    -- Deck (3s auto-play top card); onPlay e.g. grant flat shield for shield cards
    deck:update(realDt, spawner.gameTime, function(card)
        if card.stat == "shield" then player.shield = player.shield + 5 end
    end)

    -- Bullets (with bounce spark callback)
    bullets:update(dt, function(gx, gy, r, g, b)
        particles:wallSpark(gx, gy)
    end)

    -- Particles (use realDt so effects play at normal speed)
    particles:update(realDt)

    ---------------------------------------------------------------------------
    -- Graze detection (enemy bullets only)
    ---------------------------------------------------------------------------
    if not player.dead and player.invulnTimer <= 0 then
        for _, b in ipairs(bullets.list) do
            if not b.dead and not b.grazed and not b.fromPlayer then
                if Utils.circlesOverlap(player.x, player.y, player.grazeR,
                                         b.x, b.y, b.radius) then
                    b.grazed = true
                    player.graze = player.graze + 1
                    player.score = player.score + 20
                    bt:addMeter(1.5 * Buffs.getMultiplier("graze_meter"))
                end
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Bullet → player collision (skip player-owned bullets)
    ---------------------------------------------------------------------------
    if not player.dead and player.invulnTimer <= 0 then
        for _, b in ipairs(bullets.list) do
            if not b.dead and not b.fromPlayer then
                if Utils.circlesOverlap(player.x, player.y, player.hitboxR,
                                         b.x, b.y, b.radius) then
                    if player:hit() then
                        particles:burst(player.x, player.y, 1, 0.4, 0.3, 18, 110)
                        camera:shake(8, 0.3)
                        bullets:clearRadius(player.x, player.y, 3)   -- mercy clear (grid units)
                        if player.dead then gameOver = true gamePhase = "game_over" end
                    end
                    break
                end
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Player bullet → enemy collision
    ---------------------------------------------------------------------------
    for _, b in ipairs(bullets.list) do
        if not b.dead and b.fromPlayer and b.damage then
            for _, e in ipairs(spawner.enemies) do
                if not e.dead and Utils.circlesOverlap(b.x, b.y, b.radius, e.x, e.y, e.radius) then
                    local killed = e:takeDamage(b.damage)
                    particles:burst(e.x, e.y, e.cr, e.cg, e.cb, 8, 80)
                    if killed then
                        player.score = player.score + e.score
                        particles:burst(e.x, e.y, 1, 0.9, 0.5, 16, 130)
                        bt:addMeter(12)
                    end
                    b.dead = true
                    break
                end
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Dead enemies → meter refill, chance to spawn gem
    ---------------------------------------------------------------------------
    for _, e in ipairs(spawner.enemies) do
        if e.dead and not e.scored then
            e.scored = true
            bt:addMeter(10)
            if math.random() <= 0.25 then  -- 25% gem drop chance
                local gtype = math.random(2) == 1 and "timer" or "instant"
                Gem.spawn(e.x, e.y, gtype)
            end
        end
    end

    ---------------------------------------------------------------------------
    -- Gem pickup
    ---------------------------------------------------------------------------
    for i = #Gem.list, 1, -1 do
        local g = Gem.list[i]
        if Utils.circlesOverlap(player.x, player.y, 0.5, g.x, g.y, g.radius) then
            if g.type == "timer" then
                deck:reduceTimer(1.0)  -- 1s off card timer
            else
                deck:playTopCard(spawner.gameTime, function(card)
                    if card.stat == "shield" then player.shield = player.shield + 5 end
                end)
            end
            Gem.remove(i)
        end
    end
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------
function love.draw()
    love.graphics.clear(0.04, 0.04, 0.07, 1)
    if gamePhase == "pick_cards" then
        drawPickCardsUI()
        return
    end

    ---- World-space (inside camera transform) ----
    camera:push()

    Background.draw()

    -- Sight line (normal play) or aim line (bullet-time)
    if bt.active and not player.dead then
        player:drawAimLine()
    else
        HUD.drawSightLine(player)
    end

    -- Depth-sort entities for isometric rendering
    local entities = {}
    table.insert(entities, { type = "player", depth = player.x + player.y })
    for _, e in ipairs(spawner.enemies) do
        if not e.dead then
            table.insert(entities, { type = "enemy", depth = e.x + e.y, e = e })
        end
    end
    table.sort(entities, function(a, b) return a.depth < b.depth end)

    for _, ent in ipairs(entities) do
        if ent.type == "player" then
            player:draw()
        else
            ent.e:draw()
        end
    end

    -- Bullets (drawn unsorted for performance)
    bullets:draw(bt.timeScale)

    -- Damage numbers (world-space)
    HUD.drawDamageNumbers()

    -- Gems (world-space)
    Gem.draw()

    -- Particles (world-space)
    particles:draw()

    camera:pop()

    ---- Screen-space overlays ----

    -- Bullet-time tint
    bt:drawOverlay(SCREEN_W, SCREEN_H)

    -- HUD
    HUD.draw(player, spawner, bt, SCREEN_W, SCREEN_H, deck, spawner.gameTime)

    -- Custom crosshair
    HUD.drawCrosshair(bt.active)

    -- Game over
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        local font = love.graphics.getFont()

        love.graphics.setColor(1, 0.2, 0.2, 1)
        local t1 = "GAME OVER"
        love.graphics.print(t1, (SCREEN_W - font:getWidth(t1)) / 2, SCREEN_H / 2 - 40)

        love.graphics.setColor(1, 1, 1, 0.9)
        local t2 = string.format("Score: %d   Waves: %d   Graze: %d",
            player.score, spawner.wave, player.graze)
        love.graphics.print(t2, (SCREEN_W - font:getWidth(t2)) / 2, SCREEN_H / 2 - 10)

        love.graphics.setColor(0.7, 0.7, 0.7, 0.5 + 0.4 * math.sin(love.timer.getTime() * 3))
        local t3 = "Press R to restart"
        love.graphics.print(t3, (SCREEN_W - font:getWidth(t3)) / 2, SCREEN_H / 2 + 25)
    end
end
