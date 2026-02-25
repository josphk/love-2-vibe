-- crt.lua
-- Low-res canvas + CRT post-processing shader with bloom.
-- Renders the game at half resolution (512x360) then upscales through a GLSL
-- shader with scanlines, barrel distortion, chromatic aberration, and vignette.
-- Bloom extracts bright pixels, blurs them, and composites additively for neon glow.
-- F10 toggles the effect on/off.

local CRT = {}

CRT.INTERNAL_W = 512
CRT.INTERNAL_H = 360
CRT.enabled = true

local canvas, crtShader
local bloomA, bloomB, thresholdShader, blurShader
local BLOOM_W, BLOOM_H

local BLOOM_THRESHOLD = 0.28
local BLOOM_INTENSITY = 0.8
local BLOOM_PASSES = 3

--------------------------------------------------------------------------------
-- Shaders
--------------------------------------------------------------------------------

local crtShaderCode = [[
extern vec2 inputSize;

vec2 barrel(vec2 uv, float strength) {
    vec2 c = uv - 0.5;
    float r2 = dot(c, c);
    return uv + c * r2 * strength;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    float distortion = 0.1;
    vec2 buv = barrel(uv, distortion);

    if (buv.x < 0.0 || buv.x > 1.0 || buv.y < 0.0 || buv.y > 1.0)
        return vec4(0.0, 0.0, 0.0, 1.0);

    // Chromatic aberration
    float caOffset = 0.0012;
    float r = Texel(tex, vec2(buv.x + caOffset, buv.y)).r;
    float g = Texel(tex, buv).g;
    float b = Texel(tex, vec2(buv.x - caOffset, buv.y)).b;
    vec3 col = vec3(r, g, b);

    // Scanlines
    float scanY = buv.y * inputSize.y;
    float scanline = 1.0 - 0.18 * (0.5 + 0.5 * sin(scanY * 3.14159265));

    // Vignette
    vec2 vc = buv - 0.5;
    float vignette = 1.0 - dot(vc, vc) * 1.1;
    vignette = clamp(vignette, 0.0, 1.0);

    // Saturation and contrast boost
    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(luma), col, 1.4);
    col = (col - 0.5) * 1.15 + 0.5;
    col = clamp(col, 0.0, 1.0);

    col *= scanline * vignette;
    return vec4(col, 1.0) * color;
}
]]

local thresholdShaderCode = [[
extern float threshold;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec4 c = Texel(tex, uv);
    float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    float contrib = max(0.0, luma - threshold) / max(1.0 - threshold, 0.001);
    return vec4(c.rgb * contrib, 1.0);
}
]]

local blurShaderCode = [[
extern vec2 direction;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec4 r = Texel(tex, uv) * 0.227027;
    r += (Texel(tex, uv + direction) + Texel(tex, uv - direction)) * 0.1945946;
    r += (Texel(tex, uv + direction * 2.0) + Texel(tex, uv - direction * 2.0)) * 0.1216216;
    r += (Texel(tex, uv + direction * 3.0) + Texel(tex, uv - direction * 3.0)) * 0.054054;
    r += (Texel(tex, uv + direction * 4.0) + Texel(tex, uv - direction * 4.0)) * 0.016216;
    return r;
}
]]

--------------------------------------------------------------------------------
-- Init / lifecycle
--------------------------------------------------------------------------------

function CRT.init()
    canvas = love.graphics.newCanvas(CRT.INTERNAL_W, CRT.INTERNAL_H)
    canvas:setFilter("nearest", "nearest")

    BLOOM_W = math.floor(CRT.INTERNAL_W * 0.5)
    BLOOM_H = math.floor(CRT.INTERNAL_H * 0.5)
    bloomA = love.graphics.newCanvas(BLOOM_W, BLOOM_H)
    bloomB = love.graphics.newCanvas(BLOOM_W, BLOOM_H)
    bloomA:setFilter("linear", "linear")
    bloomB:setFilter("linear", "linear")

    crtShader = love.graphics.newShader(crtShaderCode)
    crtShader:send("inputSize", {CRT.INTERNAL_W, CRT.INTERNAL_H})

    thresholdShader = love.graphics.newShader(thresholdShaderCode)
    thresholdShader:send("threshold", BLOOM_THRESHOLD)

    blurShader = love.graphics.newShader(blurShaderCode)
end

function CRT.beginDraw()
    if not CRT.enabled then return end
    love.graphics.setCanvas(canvas)
end

function CRT.endDraw(screenW, screenH)
    if not CRT.enabled then return end
    love.graphics.setCanvas()

    -- 1. Extract bright pixels into bloom canvas (downscaled)
    love.graphics.setCanvas(bloomA)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setShader(thresholdShader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, 0, 0, 0, BLOOM_W / CRT.INTERNAL_W, BLOOM_H / CRT.INTERNAL_H)
    love.graphics.setShader()

    -- 2. Multi-pass Gaussian blur (ping-pong between bloomA and bloomB)
    love.graphics.setShader(blurShader)
    for _ = 1, BLOOM_PASSES do
        -- Horizontal
        love.graphics.setCanvas(bloomB)
        love.graphics.clear(0, 0, 0, 1)
        blurShader:send("direction", {1.0 / BLOOM_W, 0.0})
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bloomA)

        -- Vertical
        love.graphics.setCanvas(bloomA)
        love.graphics.clear(0, 0, 0, 1)
        blurShader:send("direction", {0.0, 1.0 / BLOOM_H})
        love.graphics.draw(bloomB)
    end
    love.graphics.setShader()

    -- 3. Composite bloom onto main canvas (additive)
    love.graphics.setCanvas(canvas)
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, BLOOM_INTENSITY)
    love.graphics.draw(bloomA, 0, 0, 0, CRT.INTERNAL_W / BLOOM_W, CRT.INTERNAL_H / BLOOM_H)
    love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()

    -- 4. Draw canvas to screen through CRT shader
    local scaleX = screenW / CRT.INTERNAL_W
    local scaleY = screenH / CRT.INTERNAL_H
    local scale = math.min(scaleX, scaleY)
    local ox = (screenW - CRT.INTERNAL_W * scale) / 2
    local oy = (screenH - CRT.INTERNAL_H * scale) / 2

    love.graphics.setShader(crtShader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
    love.graphics.setShader()
end

function CRT.screenToCanvas(sx, sy, screenW, screenH)
    local scaleX = screenW / CRT.INTERNAL_W
    local scaleY = screenH / CRT.INTERNAL_H
    local scale = math.min(scaleX, scaleY)
    local ox = (screenW - CRT.INTERNAL_W * scale) / 2
    local oy = (screenH - CRT.INTERNAL_H * scale) / 2
    return (sx - ox) / scale, (sy - oy) / scale
end

function CRT.getMousePosition()
    local mx, my = love.mouse.getPosition()
    if not CRT.enabled then return mx, my end
    local sw, sh = love.graphics.getDimensions()
    return CRT.screenToCanvas(mx, my, sw, sh)
end

function CRT.toggle()
    CRT.enabled = not CRT.enabled
end

function CRT.getRenderSize()
    if CRT.enabled then
        return CRT.INTERNAL_W, CRT.INTERNAL_H
    else
        return love.graphics.getDimensions()
    end
end

return CRT
