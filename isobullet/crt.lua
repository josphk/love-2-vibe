-- crt.lua
-- Low-res canvas + CRT post-processing shader with bloom.
-- Renders the game at half resolution (512x360) then upscales through a GLSL
-- shader with ordered dithering, RGB subpixel mask, screen curvature, and scanlines.
-- Bloom extracts bright pixels, blurs them, and composites additively for neon glow.
-- F10 toggles the effect on/off. F5/F6/F7 cycle CRT parameters.

local CRT = {}

CRT.INTERNAL_W = 512
CRT.INTERNAL_H = 360
CRT.enabled = true

local canvas, crtShader
local bloomA, bloomB, thresholdShader, blurShader
local BLOOM_W, BLOOM_H
local bayerTex

local BLOOM_THRESHOLD = 0.28
local BLOOM_INTENSITY = 0.8
local BLOOM_PASSES = 3

-- Configurable CRT parameters
local crtColorNum = 8.0
local crtPixelSize = 1.0
local crtBlending = true
local crtCurve = 0.12

local colorNumOptions = {2, 4, 8, 16}
local colorNumIndex = 3
local pixelSizeOptions = {1, 2, 3, 4}
local pixelSizeIndex = 1

--------------------------------------------------------------------------------
-- Shaders
--------------------------------------------------------------------------------

local crtShaderCode = [[
extern vec2 resolution;
extern float time;
extern float colorNum;
extern float pixelSize;
extern float blending;
extern float curve;
extern Image bayerTex;

float noise2d(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    // Horizontal noise shake (very subtle, updates once per second)
    float shake = noise2d(vec2(floor(uv.y * resolution.y), floor(time)));
    uv.x += (shake - 0.5) * 0.0005;

    // Screen curvature
    vec2 curveUV = uv * 2.0 - 1.0;
    vec2 offset = curveUV.yx * curve;
    curveUV += curveUV * offset * offset;
    uv = (curveUV + 1.0) * 0.5;

    // Edge smoothstep for curved screen borders
    float edgeX = smoothstep(0.0, 0.02, uv.x) * (1.0 - smoothstep(0.98, 1.0, uv.x));
    float edgeY = smoothstep(0.0, 0.02, uv.y) * (1.0 - smoothstep(0.98, 1.0, uv.y));
    float edge = edgeX * edgeY;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return vec4(0.0, 0.0, 0.0, 1.0);

    // CRT RGB subpixel mask
    vec2 pixelCoord = uv * resolution;
    vec2 cellCoord = floor(pixelCoord / pixelSize);
    vec2 cellCenter = (cellCoord + 0.5) * pixelSize / resolution;

    // Subpixel column within cell (0, 1, or 2)
    float subX = mod(pixelCoord.x, pixelSize);
    float subCol = floor(subX / (pixelSize / 3.0));

    // RGB mask using step() for GLSL 1.20 compatibility
    vec3 mask = vec3(
        step(subCol, 0.5),
        step(0.5, subCol) * step(subCol, 1.5),
        step(1.5, subCol)
    );

    // Border falloff within cell (width scales with cell size)
    float bw = clamp(pixelSize * 0.3, 0.01, 1.0);
    float subY = mod(pixelCoord.y, pixelSize);
    float borderX = smoothstep(0.0, bw, subX) * smoothstep(pixelSize, pixelSize - bw, subX);
    float borderY = smoothstep(0.0, bw, subY) * smoothstep(pixelSize, pixelSize - bw, subY);
    float border = borderX * borderY;

    // Cell-based chromatic aberration
    float SPREAD = 0.0025;
    float r = Texel(tex, vec2(cellCenter.x + SPREAD, cellCenter.y)).r;
    float g = Texel(tex, cellCenter).g;
    float b = Texel(tex, vec2(cellCenter.x - SPREAD, cellCenter.y)).b;
    vec3 col = vec3(r, g, b);

    // Saturation + brightness boost
    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(luma), col, 1.4);
    col *= 1.15;
    col = clamp(col, 0.0, 1.0);

    // 8x8 Bayer ordered dithering
    vec2 bayerCoord = (mod(pixelCoord, 8.0) + 0.5) / 8.0;
    float bayerValue = Texel(bayerTex, bayerCoord).r;
    float ditherAmount = 1.0 / colorNum;
    col += (bayerValue - 0.5) * ditherAmount;

    // Color quantization
    col = floor(col * (colorNum - 1.0) + 0.5) / (colorNum - 1.0);
    col = clamp(col, 0.0, 1.0);

    // Mask application
    if (blending > 0.5) {
        // Subtle intensity blend
        col *= mix(vec3(1.0), mask * 3.0, 0.15) * border;
    } else {
        // Hard RGB multiply
        col *= mask * 3.0 * border;
    }

    // Scanlines (aligned to pixel grid, nearly static)
    float scanline = 1.0 - 0.25 * (0.5 + 0.5 * sin(pixelCoord.y * 3.14159 + time * 0.15));
    col *= scanline;

    // Edge fade
    col *= edge;

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

    -- Create 8x8 Bayer dithering texture
    local bayerMatrix = {
        { 0, 32,  8, 40,  2, 34, 10, 42},
        {48, 16, 56, 24, 50, 18, 58, 26},
        {12, 44,  4, 36, 14, 46,  6, 38},
        {60, 28, 52, 20, 62, 30, 54, 22},
        { 3, 35, 11, 43,  1, 33,  9, 41},
        {51, 19, 59, 27, 49, 17, 57, 25},
        {15, 47,  7, 39, 13, 45,  5, 37},
        {63, 31, 55, 23, 61, 29, 53, 21},
    }
    local bayerData = love.image.newImageData(8, 8)
    for y = 0, 7 do
        for x = 0, 7 do
            local val = bayerMatrix[y + 1][x + 1] / 64.0
            bayerData:setPixel(x, y, val, 0, 0, 1)
        end
    end
    bayerTex = love.graphics.newImage(bayerData)
    bayerTex:setFilter("nearest", "nearest")
    bayerTex:setWrap("repeat", "repeat")

    crtShader = love.graphics.newShader(crtShaderCode)
    crtShader:send("resolution", {CRT.INTERNAL_W, CRT.INTERNAL_H})
    crtShader:send("bayerTex", bayerTex)
    crtShader:send("colorNum", crtColorNum)
    crtShader:send("pixelSize", crtPixelSize)
    crtShader:send("blending", crtBlending and 1.0 or 0.0)
    crtShader:send("curve", crtCurve)
    crtShader:send("time", 0.0)

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

    crtShader:send("time", love.timer.getTime())
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

function CRT.cycleColorNum(direction)
    colorNumIndex = colorNumIndex + direction
    if colorNumIndex > #colorNumOptions then colorNumIndex = 1 end
    if colorNumIndex < 1 then colorNumIndex = #colorNumOptions end
    crtColorNum = colorNumOptions[colorNumIndex]
    crtShader:send("colorNum", crtColorNum)
end

function CRT.cyclePixelSize(direction)
    pixelSizeIndex = pixelSizeIndex + direction
    if pixelSizeIndex > #pixelSizeOptions then pixelSizeIndex = 1 end
    if pixelSizeIndex < 1 then pixelSizeIndex = #pixelSizeOptions end
    crtPixelSize = pixelSizeOptions[pixelSizeIndex]
    crtShader:send("pixelSize", crtPixelSize)
end

function CRT.toggleBlending()
    crtBlending = not crtBlending
    crtShader:send("blending", crtBlending and 1.0 or 0.0)
end

return CRT
