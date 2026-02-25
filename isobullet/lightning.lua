-- lightning.lua
-- Per-segment quad mesh rendered through a GLSL lightning shader.
-- Produces 4 layered electric arcs (core + 3 glow layers) with animated
-- crackling. Additive blending lets the CRT bloom pipeline pick up the
-- hot core for free.

local Map = require("map")

local Lightning = {}

local shader, dummyTex

--------------------------------------------------------------------------------
-- GLSL shader (LÖVE / OpenGL ES compatible — no tanh)
--------------------------------------------------------------------------------
local shaderCode = [[
extern float time;
extern float alpha;
extern float segIndex;

// Pseudo-random hash based on sin
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

// 4-octave jagged displacement for one arc layer
float arcDisplace(float u, float seed, float t) {
    float d = 0.0;
    d += sin(u * 6.2831  * 2.0 + t * 12.0 + seed) * 0.50;
    d += sin(u * 6.2831  * 5.0 + t * 19.0 + seed * 1.3) * 0.25;
    d += sin(u * 6.2831  * 11.0 + t * 31.0 + seed * 2.1) * 0.125;
    d += sin(u * 6.2831  * 23.0 + t * 53.0 + seed * 3.7) * 0.0625;
    return d;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    float u = uv.x;           // 0→1 along segment
    float v = uv.y - 0.5;     // -0.5→+0.5 across width (0 = center)

    // Taper at endpoints so arcs converge at bounce points
    float taper = smoothstep(0.0, 0.08, u) * smoothstep(1.0, 0.92, u);

    // Flicker — rapid pulsing
    float flicker = 0.85 + 0.15 * sin(time * 47.0 + segIndex * 7.0);

    vec3 total = vec3(0.0);

    // 4 arc layers: {displacement scale, width, color}
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float seed = segIndex * 13.0 + fi * 37.0;

        // Displacement from center
        float dispScale = 0.03 + fi * 0.06;  // core tight, outer layers wide
        float disp = arcDisplace(u, seed, time) * dispScale * taper;

        // Distance from this arc to current pixel
        float dist = abs(v - disp);

        // Width of glow falloff
        float w = (0.012 + fi * 0.008) * (0.7 + 0.3 * taper);

        // Inverse-distance brightness
        float brightness = w / (dist + w);
        brightness *= brightness;  // sharpen falloff
        brightness *= taper * flicker;

        // Per-layer color
        vec3 layerColor;
        if (i == 0) {
            layerColor = vec3(1.0, 1.0, 0.97);          // white-hot core
        } else if (i == 1) {
            layerColor = vec3(0.5, 0.85, 1.0);           // cyan
        } else if (i == 2) {
            layerColor = vec3(0.6, 0.4, 1.0);            // purple
        } else {
            layerColor = vec3(0.25, 0.3, 0.8);           // deep blue wash
        }

        // Fade outer layers faster
        float layerFade = 1.0 - fi * 0.15;

        total += layerColor * brightness * layerFade;
    }

    // Clamp to 2.0 so bloom threshold (0.28) catches the hot core
    total = min(total, vec3(2.0));

    return vec4(total * alpha, 1.0);
}
]]

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
function Lightning.init()
    shader = love.graphics.newShader(shaderCode)
    -- 1x1 white pixel — LÖVE requires a texture for mesh drawing with shaders
    local imgData = love.image.newImageData(1, 1)
    imgData:setPixel(0, 0, 1, 1, 1, 1)
    dummyTex = love.graphics.newImage(imgData)
end

--------------------------------------------------------------------------------
-- Draw all beam segments as lightning quads
-- segments: table of {x1,y1,x2,y2} in grid space
-- age:      seconds since beam fired
-- lifetime: total beam duration (0.45)
--------------------------------------------------------------------------------
local HALF_WIDTH = 36  -- pixels of glow room on each side

function Lightning.drawBeam(segments, age, lifetime)
    if not shader then return end

    local t = age / lifetime
    local fadeAlpha = 1.0 - t

    love.graphics.setShader(shader)
    shader:send("time", love.timer.getTime())
    shader:send("alpha", fadeAlpha)

    local prevBlendMode, prevAlphaMode = love.graphics.getBlendMode()
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, 1)

    for si, seg in ipairs(segments) do
        local sx1, sy1 = Map.gridToScreen(seg.x1, seg.y1)
        local sx2, sy2 = Map.gridToScreen(seg.x2, seg.y2)

        local dx = sx2 - sx1
        local dy = sy2 - sy1
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 1 then goto continue end

        -- Perpendicular normal
        local nx = -dy / len * HALF_WIDTH
        local ny =  dx / len * HALF_WIDTH

        shader:send("segIndex", si - 1)

        -- Build 4-vertex quad mesh
        -- Vertices: {x, y, u, v}
        local vertices = {
            { sx1 + nx, sy1 + ny, 0, 0 },   -- top-left
            { sx2 + nx, sy2 + ny, 1, 0 },   -- top-right
            { sx2 - nx, sy2 - ny, 1, 1 },   -- bottom-right
            { sx1 - nx, sy1 - ny, 0, 1 },   -- bottom-left
        }

        local mesh = love.graphics.newMesh(vertices, "fan")
        mesh:setTexture(dummyTex)
        love.graphics.draw(mesh)

        ::continue::
    end

    love.graphics.setShader()
    love.graphics.setBlendMode(prevBlendMode, prevAlphaMode)
end

return Lightning
