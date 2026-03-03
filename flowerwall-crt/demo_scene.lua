-- Procedural flower garden demo scene (no external assets).

local DemoScene = {}

local flowers = {}
local particles = {}
local titleFont
local time = 0
local sceneW, sceneH

local function hsv(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    else return v, p, q end
end

function DemoScene.init(w, h)
    sceneW, sceneH = w, h

    for i = 1, 10 do
        flowers[i] = {
            x = w * (0.06 + 0.88 * (i - 1) / 9),
            baseY = h * (0.35 + 0.15 * math.sin(i * 1.7)),
            petals = 5 + (i % 4),
            petal_r = 8 + (i % 5) * 3,
            orbit_r = 14 + (i % 3) * 5,
            hue = (i - 1) / 10,
            rot_speed = 0.3 + (i % 3) * 0.2,
            stem_h = 60 + (i % 4) * 25,
        }
    end

    for i = 1, 50 do
        particles[i] = {
            x = love.math.random() * w,
            y = love.math.random() * h * 0.75,
            speed = 10 + love.math.random() * 20,
            size = 1 + love.math.random() * 2,
            bright = 0.5 + love.math.random() * 0.5,
            phase = love.math.random() * math.pi * 2,
        }
    end

    titleFont = love.graphics.newFont(32)
end

function DemoScene.update(dt)
    time = time + dt
    for _, p in ipairs(particles) do
        p.y = p.y - p.speed * dt
        if p.y < -10 then
            p.y = sceneH * 0.80
            p.x = love.math.random() * sceneW
        end
    end
end

function DemoScene.draw()
    local w, h = sceneW, sceneH

    -- Background gradient (dark purple-blue)
    for y = 0, h - 1, 4 do
        local t = y / h
        love.graphics.setColor(0.02 + t * 0.03, 0.01, 0.08 - t * 0.04, 1)
        love.graphics.rectangle("fill", 0, y, w, 4)
    end

    -- Flowers
    for _, f in ipairs(flowers) do
        local fy = f.baseY

        -- Stem
        love.graphics.setColor(0.15, 0.45, 0.15, 1)
        love.graphics.setLineWidth(3)
        love.graphics.line(f.x, fy, f.x, fy + f.stem_h)

        -- Leaves (two small triangles on the stem)
        local leafY = fy + f.stem_h * 0.5
        love.graphics.setColor(0.2, 0.55, 0.2, 1)
        love.graphics.polygon("fill",
            f.x, leafY,
            f.x + 12, leafY + 6,
            f.x + 2, leafY + 10)
        love.graphics.polygon("fill",
            f.x, leafY + 12,
            f.x - 11, leafY + 18,
            f.x - 1, leafY + 22)

        -- Petals
        local hue = (f.hue + time * 0.05) % 1
        for p = 1, f.petals do
            local angle = time * f.rot_speed + (p - 1) * (math.pi * 2 / f.petals)
            local px = f.x + math.cos(angle) * f.orbit_r
            local py = fy + math.sin(angle) * f.orbit_r
            local r, g, b = hsv((hue + p / f.petals * 0.3) % 1, 0.7, 0.9)
            love.graphics.setColor(r, g, b, 0.9)
            love.graphics.circle("fill", px, py, f.petal_r)
        end

        -- Center
        love.graphics.setColor(1, 0.85, 0.2, 1)
        love.graphics.circle("fill", f.x, fy, f.petal_r * 0.4)
    end

    -- Particles (pollen / fireflies)
    for _, p in ipairs(particles) do
        local wobble = math.sin(time * 2 + p.phase) * 12
        local alpha = p.bright * (0.5 + 0.5 * math.sin(time * 3 + p.phase))
        love.graphics.setColor(1, 1, 0.8, alpha)
        love.graphics.circle("fill", p.x + wobble, p.y, p.size)
    end

    -- Color test bars (RGBCMY) at the bottom
    local barH = 20
    local barW = w / 6
    local barY = h - barH
    local colors = {
        {1, 0, 0}, {0, 1, 0}, {0, 0, 1},
        {0, 1, 1}, {1, 0, 1}, {1, 1, 0},
    }
    for i, c in ipairs(colors) do
        love.graphics.setColor(c[1], c[2], c[3], 1)
        love.graphics.rectangle("fill", (i - 1) * barW, barY, barW, barH)
    end

    -- Title text (bright white, pulsing — triggers bloom)
    local title = "FLOWERWALL CRT"
    local pulse = 0.7 + 0.3 * math.sin(time * 2)
    love.graphics.setColor(1, 1, 1, pulse)
    love.graphics.setFont(titleFont)
    local tw = titleFont:getWidth(title)
    love.graphics.print(title, math.floor((w - tw) / 2), 16)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return DemoScene
