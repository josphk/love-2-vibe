-- Flowerwall CRT shaders ported from Godot 4 GLSL to Love2D GLSL.
-- Original: https://github.com/Art-Michel/Flowerwall-CRT-shader-for-Godot (MIT)
--
-- Translation key:
--   uniform     -> extern
--   sampler2D   -> Image
--   texture()   -> Texel()
--   SCREEN_UV   -> texture_coords
--   FRAGCOORD   -> screen_coords
--   TIME        -> extern float time
--   COLOR =     -> return

local Shaders = {}

----------------------------------------------------------------------------
-- Separable 10-tap Gaussian blur
-- Direction set via step_dir: (1,0) horizontal, (0,1) vertical
----------------------------------------------------------------------------
Shaders.blur = [[
extern vec2 step_dir;
extern float radius;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    const float DEFAULT_RADIUS = 9.0;
    vec2 s = radius / DEFAULT_RADIUS * step_dir / love_ScreenSize.zw;
    vec3 col =
        0.012425302 * Texel(tex, uv - 9.000000000 * s).rgb +
        0.046287410 * Texel(tex, uv - 7.408451530 * s).rgb +
        0.087268415 * Texel(tex, uv - 5.432513128 * s).rgb +
        0.135364297 * Texel(tex, uv - 3.456897372 * s).rgb +
        0.172748950 * Texel(tex, uv - 1.481489944 * s).rgb +
        0.181383322 * Texel(tex, uv + 0.493827474 * s).rgb +
        0.156693587 * Texel(tex, uv + 2.469174944 * s).rgb +
        0.111371271 * Texel(tex, uv + 4.444671945 * s).rgb +
        0.065125981 * Texel(tex, uv + 6.420435068 * s).rgb +
        0.031331465 * Texel(tex, uv + 8.396575836 * s).rgb;
    return vec4(col, 1.0);
}
]]

----------------------------------------------------------------------------
-- CRT shader: mask, scanlines, grain, barrel distortion, VHS smearing/wiggle
----------------------------------------------------------------------------
Shaders.crt = [[
extern Image noise_texture;
extern float time;

extern float enable_slotmask;
extern float enable_gridmask;
extern float mask_strength;
extern float pixel_size;

extern float enable_grain;
extern float grain_strength;

extern float enable_curving;
extern float curve_power;

extern float enable_scanlines;
extern float scanlines_interval;
extern float scanlines_opacity;
extern float scanlines_thickness;

extern float enable_smearing;
extern float smearing_strength;

extern float enable_wiggle;
extern float wiggle;

vec2 distort(vec2 p) {
    float theta = atan(p.y, p.x);
    float r = pow(length(p), curve_power);
    p.x = r * cos(theta);
    p.y = r * sin(theta);
    return 0.5 * (p + vec2(1.0));
}

float filmGrainNoise(float t, vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233) * t)) * 43758.5453);
}

float v2random(vec2 uv) {
    return Texel(noise_texture, mod(uv, vec2(1.0))).x;
}

vec2 Circle(float Start, float Points, float Point) {
    float Rad = (3.141592 * 2.0 * (1.0 / Points)) * (Point + Start);
    return vec2(-(0.3 + Rad), cos(Rad));
}

vec3 rgb2yiq(vec3 c) {
    return vec3(
        0.2989 * c.x + 0.5959 * c.y + 0.2115 * c.z,
        0.5870 * c.x - 0.2744 * c.y - 0.5229 * c.z,
        0.1140 * c.x - 0.3216 * c.y + 0.3114 * c.z
    );
}

vec3 yiq2rgb(vec3 c) {
    return vec3(
        1.0 * c.x + 1.0 * c.y + 1.0 * c.z,
        0.956 * c.x - 0.2720 * c.y - 1.1060 * c.z,
        0.6210 * c.x - 0.6474 * c.y + 1.7046 * c.z
    );
}

#define BLUR_SAMPLES 6

vec3 VHSBlur(Image source, vec2 uv, float d) {
    vec3 sum = vec3(0.0);
    float W = 1.0 / float(BLUR_SAMPLES);
    for (int i = 0; i < BLUR_SAMPLES; ++i) {
        vec2 PixelOffset = vec2(d, 0.0);
        float Start = 2.0 / float(BLUR_SAMPLES);
        vec2 Scale = 0.66 * 4.0 * 2.0 * PixelOffset.xy;
        vec3 N = Texel(source, uv + Circle(Start, float(BLUR_SAMPLES), float(i)) * Scale).rgb;
        sum += N * W;
    }
    return sum;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 xy = texture_coords;

    // --- VHS wiggle ---
    if (enable_wiggle > 0.5) {
        xy.x += (v2random(vec2(xy.y / 10.0, time / 100.0)) - 0.5) * wiggle * 0.1;
        xy.x += (v2random(vec2(xy.y, time * 10.0)) - 0.5) * wiggle * 0.1;
    }

    // --- Barrel distortion ---
    if (enable_curving > 0.5) {
        xy = xy * 2.0 - vec2(1.0);
        xy = distort(xy);
    }

    vec4 col = Texel(tex, xy);

    // --- VHS color smearing (YIQ) ---
    if (enable_smearing > 0.5) {
        float s = 0.0001 * 0.0001;
        float e = min(0.30, pow(max(0.0, cos(xy.y * 4.0 + 0.3) - 0.75) * (s + 0.5), 3.0)) * 25.0;
        float d = 0.051 + abs(sin(s / 4.0));
        float c = max(0.0001, 0.002 * d) * smearing_strength;

        vec3 blurred;
        blurred = VHSBlur(tex, xy, c + c * xy.x);
        float luma = rgb2yiq(blurred).r;

        xy.x += 0.01 * d;
        c *= 4.0;
        blurred = VHSBlur(tex, xy, c);
        float i_val = rgb2yiq(blurred).g;

        xy.x += 0.005 * d;
        c *= 2.50;
        blurred = VHSBlur(tex, xy, c);
        float q_val = rgb2yiq(blurred).b;

        col.rgb = yiq2rgb(vec3(luma, i_val, q_val)) - pow(s + e * 2.0, 3.0);
    }

    // --- Film grain ---
    if (enable_grain > 0.5) {
        col.rgb = mix(col.rgb, vec3(0.0), filmGrainNoise(time, texture_coords) * grain_strength);
    }

    // --- Grid mask + scanlines ---
    if (enable_gridmask > 0.5) {
        float rgbIdx = mod(floor(screen_coords.x), pixel_size);
        if (rgbIdx < 0.5) {
            col.gb *= 1.0 - mask_strength;
        } else if (rgbIdx < 1.5) {
            col.rb *= 1.0 - mask_strength;
        } else if (rgbIdx < 2.5) {
            col.rg *= 1.0 - mask_strength;
        } else {
            col.rgb *= 1.0 - (mask_strength * 1.33);
        }

        if (enable_scanlines > 0.5) {
            float sl = mod(screen_coords.y, pixel_size);
            sl = 1.0 - step(scanlines_thickness, sl);
            col.rgb *= 1.0 - sl * scanlines_opacity;
        }

    // --- Slot mask + scanlines ---
    } else if (enable_slotmask > 0.5) {
        float lineIdx = mod(floor(screen_coords.y / pixel_size), 4.0);
        float rgbIdx = mod(floor(screen_coords.x) + lineIdx * 2.0, 4.0);

        if (rgbIdx < 0.5) {
            col.gb *= 1.0 - mask_strength;
        } else if (rgbIdx < 1.5) {
            col.rb *= 1.0 - mask_strength;
        } else if (rgbIdx < 2.5) {
            col.rg *= 1.0 - mask_strength;
        } else {
            col.rgb *= 1.0 - (mask_strength * 0.666);
        }

        if (enable_scanlines > 0.5) {
            float sl = mod(screen_coords.y, pixel_size);
            sl = 1.0 - step(scanlines_thickness, sl);
            col.rgb *= 1.0 - sl * scanlines_opacity;
        }

    // --- Scanlines only (no mask) ---
    } else if (enable_scanlines > 0.5) {
        float sl = mod(screen_coords.y, scanlines_interval);
        sl = 1.0 - step(scanlines_thickness, sl);
        col.rgb *= 1.0 - sl * scanlines_opacity;
    }

    // --- Vignette (only with barrel distortion) ---
    if (enable_curving > 0.5) {
        vec2 vig_uv = texture_coords;
        vig_uv *= 1.0 - vig_uv.yx;
        float vig = vig_uv.x * vig_uv.y / max(curve_power - 1.0, 0.001) * 120.0;
        col.rgb -= 1.0 - clamp(vig, 0.0, 1.0);
    }

    return col;
}
]]

----------------------------------------------------------------------------
-- Bloom threshold extraction
----------------------------------------------------------------------------
Shaders.threshold = [[
extern float threshold;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec4 c = Texel(tex, uv);
    float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    float contrib = max(0.0, luma - threshold) / max(1.0 - threshold, 0.001);
    return vec4(c.rgb * contrib, 1.0);
}
]]

----------------------------------------------------------------------------
-- Bloom blur (golden-angle spiral, 32 taps)
----------------------------------------------------------------------------
Shaders.bloom = [[
extern vec2 bloom_resolution;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    vec2 texel = 1.0 / bloom_resolution;
    vec4 bloom = vec4(0.0);
    vec2 point = vec2(16.0, 0.0) * inversesqrt(32.0);

    for (float i = 0.0; i < 32.0; i += 1.0) {
        point *= -mat2(0.7374, 0.6755, -0.6755, 0.7374);
        bloom += Texel(tex, uv + point * sqrt(i) * texel) * (1.0 - i / 32.0);
    }
    bloom *= 3.0 / 32.0;
    bloom += Texel(tex, uv) * 0.5;
    return bloom;
}
]]

return Shaders
