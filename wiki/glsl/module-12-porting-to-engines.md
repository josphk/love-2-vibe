# Module 12: Porting to Engines

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 4–6 hours per engine
**Prerequisites:** Any modules — port whatever you have built so far

---

## Overview

ShaderToy is a playground. Engines are where shaders ship. The good news: everything you have learned is transferable. The concepts — UV coordinates, SDFs, noise, lighting models, post-processing — are universal. A `smoothstep` is a `smoothstep` everywhere.

What changes between ShaderToy and an engine is the plumbing: how you declare inputs, what the built-in variables are called, where you output color, and how the rendering pipeline handles things like textures and multi-pass effects. This module gives you the translation guide for three engines: **Godot**, **Love2D**, and **React Three Fiber (Three.js)**.

The goal is not to rewrite every shader from scratch. You already have the GLSL knowledge. This module teaches you the mechanical translation: swap `fragCoord` for `UV`, replace `iTime` with `TIME`, change the function signature. Once you do this two or three times, it becomes automatic.

---

## 1. The Universal Porting Checklist

No matter which engine you are targeting, the same six things need to change:

| ShaderToy | What it is | How to replace |
|---|---|---|
| `fragCoord` | Pixel coordinate | Engine's UV or screen coordinate |
| `iResolution` | Viewport size | Engine's resolution uniform or remove (UVs are already 0–1) |
| `iTime` | Elapsed time | Engine's time uniform |
| `iMouse` | Mouse position | Engine-specific input or custom uniform |
| `texture(iChannelN, uv)` | Texture sampling | Engine's texture function |
| `fragColor = vec4(...)` | Color output | Engine's output variable |

Additionally:
- Move helper functions (noise, SDFs, palettes) into the shader file or an include
- Replace `mainImage(out vec4, in vec2)` with the engine's entry point
- Handle coordinate system differences (Y-up vs Y-down, 0–1 vs pixel coords)

---

## 2. Porting to Godot

Godot uses its own shading language, which is GLSL-like but simplified. It compiles to GLSL/Vulkan/Metal behind the scenes. There are two shader types relevant here: **canvas_item** (2D) and **spatial** (3D).

### Canvas Item Shader (2D)

This is the most common for post-processing and 2D effects.

```gdscript
shader_type canvas_item;

uniform float time_scale : hint_range(0.1, 5.0) = 1.0;

void fragment() {
    vec2 uv = UV;  // Already 0–1, no normalization needed

    // Your shader code here, using uv instead of fragCoord/iResolution
    float d = length(uv - 0.5) - 0.3;
    float fill = smoothstep(0.01, 0.0, d);

    COLOR = vec4(vec3(fill), 1.0);
}
```

### Translation Table: ShaderToy → Godot Canvas Item

| ShaderToy | Godot Canvas Item |
|---|---|
| `void mainImage(out vec4 fragColor, in vec2 fragCoord)` | `void fragment()` |
| `fragCoord / iResolution.xy` | `UV` (already 0–1) |
| `fragColor = vec4(...)` | `COLOR = vec4(...)` |
| `iTime` | `TIME` |
| `iResolution` | `1.0 / SCREEN_PIXEL_SIZE` or pass as uniform |
| `iMouse` | Pass as uniform from GDScript |
| `texture(iChannel0, uv)` | `texture(my_texture, uv)` (declare with `uniform sampler2D`) |
| `#define PI 3.14159` | `const float PI = 3.14159;` (no `#define` in Godot) |
| `out`/`in` parameters | Not used — Godot uses built-in variables |

### Sending Uniforms from GDScript

```gdscript
# In your node's script:
@onready var material = $Sprite2D.material as ShaderMaterial

func _process(delta):
    material.set_shader_parameter("mouse_pos", get_viewport().get_mouse_position())
    # TIME is automatic — no need to send it
```

### Screen-Space Post-Processing in Godot

To apply a shader to the entire screen:

1. Add a `CanvasLayer` node
2. Add a `ColorRect` child that covers the full screen
3. Create a `ShaderMaterial` on the `ColorRect`
4. In the shader, sample the screen:

```gdscript
shader_type canvas_item;

void fragment() {
    vec4 screen = texture(TEXTURE, UV);

    // Apply post-processing
    vec3 color = screen.rgb;

    // Vignette
    float vig = 1.0 - length(UV - 0.5) * 1.5;
    color *= clamp(vig, 0.0, 1.0);

    COLOR = vec4(color, 1.0);
}
```

### Spatial Shader (3D)

For 3D objects:

```gdscript
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.8, 0.3, 0.2);
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    ALBEDO = base_color;
    ROUGHNESS = roughness;

    // Custom effects using UV, TIME, etc.
    float pattern = sin(UV.x * 20.0 + TIME * 2.0) * 0.5 + 0.5;
    EMISSION = vec3(pattern * 0.2, 0.0, 0.0);
}
```

### Godot-Specific Features

| Built-in | Description |
|---|---|
| `UV` | Mesh UV coordinates (0–1) |
| `SCREEN_UV` | Pixel position on screen (0–1) |
| `VERTEX` | Vertex position (in vertex shader) |
| `NORMAL` | Surface normal |
| `TIME` | Elapsed time |
| `ALBEDO` | Base color output (spatial) |
| `EMISSION` | Emissive color output (spatial) |
| `ROUGHNESS` | Surface roughness output (spatial) |
| `COLOR` | Final color output (canvas_item) |
| `TEXTURE` | The node's assigned texture (canvas_item) |

### Example: Porting a Cosine Palette Shader

**ShaderToy:**
```glsl
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float d = length(uv);
    vec3 color = palette(d - iTime * 0.3, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.1, 0.2));
    fragColor = vec4(color, 1.0);
}
```

**Godot:**
```gdscript
shader_type canvas_item;

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

void fragment() {
    // Centered, aspect-corrected
    vec2 uv = UV - 0.5;
    float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    uv.x *= aspect;

    float d = length(uv);
    vec3 color = palette(d - TIME * 0.3, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.1, 0.2));
    COLOR = vec4(color, 1.0);
}
```

**Key changes:**
- `mainImage(...)` → `void fragment()`
- `fragCoord / iResolution.xy` → `UV`
- `iTime` → `TIME`
- `fragColor` → `COLOR`
- Aspect ratio correction uses `SCREEN_PIXEL_SIZE` instead of `iResolution`
- No `#define` — use `const` or just inline the value

For more on Godot shaders, see the [Godot Shaders & Stylized Rendering module](../godot/module-06-shaders-stylized-rendering.md).

---

## 3. Porting to Love2D

Love2D uses GLSL directly via `love.graphics.newShader()`. The shader code is a GLSL string with Love2D-specific entry points and built-in variables.

### Basic Fragment Shader

```lua
local shader = love.graphics.newShader([[
    extern float time;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        // texture_coords = UV (0–1)
        // screen_coords = pixel coordinates

        vec2 uv = texture_coords;
        float d = length(uv - 0.5) - 0.3;
        float fill = smoothstep(0.01, 0.0, d);

        return vec4(vec3(fill), 1.0) * color;
    }
]])
```

### Translation Table: ShaderToy → Love2D

| ShaderToy | Love2D |
|---|---|
| `void mainImage(out vec4 fragColor, in vec2 fragCoord)` | `vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)` |
| `fragCoord` | `screen_coords` (pixel coords) |
| `fragCoord / iResolution.xy` | `texture_coords` (already 0–1) |
| `fragColor = vec4(...)` | `return vec4(...)` |
| `iTime` | `extern float time;` (sent from Lua) |
| `iResolution` | `extern vec2 resolution;` or `love_ScreenSize` |
| `iMouse` | `extern vec2 mouse;` (sent from Lua) |
| `texture(iChannel0, uv)` | `Texel(tex, uv)` |
| `uniform` | `extern` |

### Sending Uniforms from Lua

```lua
function love.update(dt)
    shader:send("time", love.timer.getTime())
    shader:send("resolution", {love.graphics.getDimensions()})
    shader:send("mouse", {love.mouse.getPosition()})
end

function love.draw()
    love.graphics.setShader(shader)
    -- Draw something (the shader processes it)
    love.graphics.draw(image, 0, 0)
    love.graphics.setShader()  -- Reset shader
end
```

### Full-Screen Effect (Canvas-Based)

```lua
local canvas = love.graphics.newCanvas()
local shader = love.graphics.newShader([[
    extern float time;
    extern vec2 resolution;

    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        // Centered, aspect-corrected
        vec2 uv = (sc - resolution * 0.5) / resolution.y;

        float d = length(uv) - 0.3;
        float fill = smoothstep(0.005, 0.0, d);

        return vec4(vec3(fill), 1.0);
    }
]])

function love.draw()
    -- Render scene to canvas
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    -- Draw your game scene here
    love.graphics.setCanvas()

    -- Apply post-processing shader
    love.graphics.setShader(shader)
    love.graphics.draw(canvas)
    love.graphics.setShader()
end

function love.update(dt)
    shader:send("time", love.timer.getTime())
    shader:send("resolution", {love.graphics.getDimensions()})
end
```

### Love2D-Specific Notes

- **`Texel(tex, uv)`** is Love2D's texture sampling function (equivalent to `texture()`).
- **Multiply by `color`:** The `color` parameter in `effect()` carries the Love2D draw color. Multiply your result by it to respect `love.graphics.setColor()`.
- **Y-axis:** Love2D's screen coordinates have Y=0 at the top (opposite of OpenGL/ShaderToy). If your shader relies on Y-up, flip it: `uv.y = 1.0 - uv.y;`.
- **GLSL version:** Love2D uses GLSL ES by default. Some features (like integer attributes or certain built-ins) may not be available.

### Example: Porting a Wavy Distortion

**ShaderToy:**
```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    uv.x += sin(uv.y * 15.0 + iTime * 3.0) * 0.02;
    fragColor = texture(iChannel0, uv);
}
```

**Love2D:**
```lua
local shader = love.graphics.newShader([[
    extern float time;

    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        tc.x += sin(tc.y * 15.0 + time * 3.0) * 0.02;
        return Texel(tex, tc) * color;
    }
]])
```

For more on Love2D shaders, see the [Love2D Learning Roadmap](../love2d/love2d-learning-roadmap.md).

---

## 4. Porting to React Three Fiber (Three.js)

R3F uses raw GLSL via `ShaderMaterial` or Three.js's shader chunks. You write standard GLSL vertex and fragment shaders.

### Basic ShaderMaterial

```jsx
import { useFrame, useThree } from '@react-three/fiber'
import { useRef, useMemo } from 'react'
import * as THREE from 'three'

function CustomShader() {
    const meshRef = useRef()
    const { viewport } = useThree()

    const uniforms = useMemo(() => ({
        uTime: { value: 0 },
        uResolution: { value: new THREE.Vector2(viewport.width, viewport.height) }
    }), [])

    useFrame((state) => {
        uniforms.uTime.value = state.clock.elapsedTime
    })

    return (
        <mesh ref={meshRef}>
            <planeGeometry args={[2, 2]} />
            <shaderMaterial
                vertexShader={`
                    varying vec2 vUv;
                    void main() {
                        vUv = uv;
                        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
                    }
                `}
                fragmentShader={`
                    uniform float uTime;
                    uniform vec2 uResolution;
                    varying vec2 vUv;

                    void main() {
                        vec2 uv = vUv - 0.5;
                        uv.x *= uResolution.x / uResolution.y;

                        float d = length(uv) - 0.3;
                        float fill = smoothstep(0.005, 0.0, d);

                        gl_FragColor = vec4(vec3(fill), 1.0);
                    }
                `}
                uniforms={uniforms}
            />
        </mesh>
    )
}
```

### Translation Table: ShaderToy → Three.js / R3F

| ShaderToy | Three.js / R3F |
|---|---|
| `void mainImage(out vec4 fragColor, in vec2 fragCoord)` | `void main()` (standard GLSL) |
| `fragCoord / iResolution.xy` | `vUv` (passed from vertex shader) |
| `fragColor = vec4(...)` | `gl_FragColor = vec4(...)` |
| `iTime` | `uniform float uTime;` (set from JS) |
| `iResolution` | `uniform vec2 uResolution;` (set from JS) |
| `iMouse` | `uniform vec2 uMouse;` (set from JS) |
| `texture(iChannel0, uv)` | `texture2D(uTexture, uv)` with `uniform sampler2D uTexture;` |
| Vertex shader | Must write your own (or use Three.js built-ins) |

### Three.js Built-In Vertex Attributes and Uniforms

Three.js provides these automatically in the vertex shader:

```glsl
// Attributes (per-vertex, from geometry)
attribute vec3 position;   // Vertex position
attribute vec3 normal;     // Vertex normal
attribute vec2 uv;         // Texture coordinates

// Uniforms (Three.js provides these)
uniform mat4 projectionMatrix;    // Camera projection
uniform mat4 modelViewMatrix;     // Model × View
uniform mat4 modelMatrix;         // Model transform
uniform mat4 viewMatrix;          // Camera transform
uniform mat3 normalMatrix;        // For transforming normals
```

### Post-Processing in R3F

Use `@react-three/postprocessing` or write custom passes with `EffectComposer`:

```jsx
import { EffectComposer, ShaderPass } from 'three/examples/jsm/postprocessing'

// Custom post-processing shader
const MyEffect = {
    uniforms: {
        tDiffuse: { value: null },
        uTime: { value: 0 }
    },
    vertexShader: `
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    `,
    fragmentShader: `
        uniform sampler2D tDiffuse;
        uniform float uTime;
        varying vec2 vUv;

        void main() {
            vec2 uv = vUv;
            // Apply effects to the rendered scene
            uv.x += sin(uv.y * 15.0 + uTime * 3.0) * 0.01;
            gl_FragColor = texture2D(tDiffuse, uv);
        }
    `
}
```

### Three Shading Language (TSL)

Three.js r167+ supports TSL — a way to write shaders in JavaScript/TypeScript that compile to GLSL or WGSL:

```javascript
import { Fn, uv, time, sin, mix, vec3, float } from 'three/tsl'

const colorFn = Fn(() => {
    const t = sin(uv().x.mul(10).add(time)).mul(0.5).add(0.5)
    return mix(vec3(0.1, 0.3, 0.8), vec3(0.9, 0.2, 0.1), t)
})
```

TSL is the future direction of Three.js shaders. It abstracts away GLSL/WGSL differences and integrates with the node-based material system.

### Example: Porting a Raymarched Scene

The full ShaderToy raymarcher from Module 10 ports almost directly — you just need to add the vertex shader and update the uniforms:

```jsx
<shaderMaterial
    vertexShader={`
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    `}
    fragmentShader={`
        uniform float uTime;
        uniform vec2 uResolution;
        varying vec2 vUv;

        // Paste your entire ShaderToy shader here, with these changes:
        // 1. Replace mainImage(...) with main()
        // 2. Replace fragCoord with vUv * uResolution
        // 3. Replace iTime with uTime
        // 4. Replace iResolution with uResolution
        // 5. Replace fragColor with gl_FragColor

        void main() {
            vec2 fragCoord = vUv * uResolution;
            // ... rest of shader unchanged ...
            gl_FragColor = vec4(color, 1.0);
        }
    `}
    uniforms={{
        uTime: { value: 0 },
        uResolution: { value: new THREE.Vector2(800, 600) }
    }}
/>
```

For more on R3F shaders, see the [R3F Shaders & Stylized Rendering module](../r3f/module-06-shaders-stylized-rendering.md).

---

## 5. Common Porting Issues

### Coordinate System Differences

```
ShaderToy:    Godot Canvas:   Love2D:         Three.js:
Y-up          Y-down          Y-down          Y-up (3D)
Bottom-left   Top-left        Top-left        Depends on UV setup
origin        origin          origin

Fix: flip Y when porting from ShaderToy to Love2D/Godot:
  uv.y = 1.0 - uv.y;
```

### Precision Qualifiers

Some platforms (mobile, WebGL) require precision qualifiers:

```glsl
// Add at the top of fragment shaders for WebGL:
precision highp float;
```

Godot and ShaderToy handle this automatically. Three.js/WebGL may require it.

### `#define` vs `const`

ShaderToy GLSL supports `#define`. Godot shading language does not:

```glsl
// ShaderToy:
#define PI 3.14159265359

// Godot:
const float PI = 3.14159265359;

// Both work in raw GLSL (Three.js, Love2D):
#define PI 3.14159265359
// or:
const float PI = 3.14159265359;
```

### Texture Sampling Function Names

```glsl
// ShaderToy / GLSL 3.3+:
texture(sampler, uv)

// GLSL ES 1.0 / WebGL 1.0 / Love2D:
texture2D(sampler, uv)   // or Texel() in Love2D

// Godot:
texture(sampler, uv)     // same as modern GLSL
```

### Multi-Pass

ShaderToy's Buffer system does not directly translate to engines. Each engine has its own approach:

- **Godot:** Use `SubViewport` nodes or `BackBufferCopy`
- **Love2D:** Use `love.graphics.newCanvas()` and draw between canvases
- **Three.js:** Use `EffectComposer` with `RenderPass` and `ShaderPass`

---

## 6. Porting Workflow

Here is a step-by-step process for porting any ShaderToy shader:

### Step 1: Copy the Shader Code

Copy everything from ShaderToy into your engine's shader file.

### Step 2: Replace Entry Point

```glsl
// FROM:
void mainImage(out vec4 fragColor, in vec2 fragCoord) {

// TO (raw GLSL / Three.js):
void main() {
    vec2 fragCoord = vUv * uResolution;

// TO (Godot):
void fragment() {

// TO (Love2D):
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
```

### Step 3: Replace Uniforms

Find-and-replace:
- `iTime` → engine's time variable
- `iResolution` → engine's resolution or remove (if using UVs directly)
- `iMouse` → engine's mouse input

### Step 4: Replace Output

```glsl
// FROM:
fragColor = vec4(color, 1.0);

// TO (raw GLSL / Three.js):
gl_FragColor = vec4(color, 1.0);

// TO (Godot):
COLOR = vec4(color, 1.0);

// TO (Love2D):
return vec4(color, 1.0);
```

### Step 5: Replace Texture Sampling

```glsl
// FROM:
vec4 tex = texture(iChannel0, uv);

// TO (engine): declare the uniform and use it:
uniform sampler2D myTexture;
vec4 tex = texture(myTexture, uv);  // or texture2D() for WebGL 1
```

### Step 6: Handle #define

Replace with `const` if the engine does not support `#define`.

### Step 7: Test and Debug

Common issues after porting:
- **Black screen:** Check that uniforms are being sent correctly
- **Upside down:** Flip Y coordinate
- **Wrong colors:** Check gamma/linear color space settings
- **Missing textures:** Verify texture binding and sampler names
- **Compile errors:** Check GLSL version compatibility

---

## GLSL Quick Reference

| Concept | ShaderToy | Godot | Love2D | Three.js |
|---|---|---|---|---|
| Entry point | `mainImage(out, in)` | `fragment()` | `effect(c, tex, tc, sc)` | `main()` |
| Pixel coord | `fragCoord` | `FRAGCOORD` | `screen_coords` | `gl_FragCoord` or `vUv * res` |
| UV (0–1) | `fragCoord/iRes.xy` | `UV` | `texture_coords` | `vUv` (from vertex) |
| Output | `fragColor` | `COLOR` | `return vec4(...)` | `gl_FragColor` |
| Time | `iTime` | `TIME` | `extern float time` | `uniform float uTime` |
| Resolution | `iResolution` | `SCREEN_PIXEL_SIZE` | `extern vec2 res` | `uniform vec2 uRes` |
| Texture sample | `texture(iCh0, uv)` | `texture(tex, uv)` | `Texel(tex, uv)` | `texture2D(tex, uv)` |
| Uniform decl | (automatic) | `uniform type name` | `extern type name` | `uniform type name` |
| Constants | `#define PI 3.14` | `const float PI = 3.14` | `#define` or `const` | `#define` or `const` |

---

## Exercises

### Exercise 1: Port a Simple Shader

**Time:** 30–45 minutes

Pick a simple shader from Module 1 or 2 (animated gradient or SDF circle) and port it to at least one engine. Document every change you make in a comment block at the top of the ported shader.

**Concepts practiced:** Mechanical translation, engine-specific conventions

---

### Exercise 2: Port a Palette + SDF Shader

**Time:** 45–60 minutes

Port a shader that uses cosine palettes (Module 3) and SDFs (Module 2) to your engine of choice. This tests:

1. Helper function porting (palette function, SDF functions)
2. Time-based animation
3. Multiple coordinate transforms

Compare the ShaderToy and engine versions side by side.

**Concepts practiced:** Complex shader porting, helper functions, visual comparison

---

### Exercise 3: Engine-Native Post-Processing

**Time:** 60–90 minutes

Create a post-processing effect (vignette + chromatic aberration + film grain from Module 9) that runs on your game's actual rendered output:

1. **Godot:** Apply to a `ColorRect` on a `CanvasLayer` using `TEXTURE`
2. **Love2D:** Render to a canvas, then draw the canvas with the shader
3. **Three.js:** Use `EffectComposer` with a custom `ShaderPass`

This tests the full pipeline: rendering a scene, capturing it as a texture, and post-processing it with your shader.

**Concepts practiced:** Engine-specific post-processing pipeline, render-to-texture, shader integration

---

## Key Takeaways

1. **The concepts are universal.** SDFs, noise, lighting, post-processing — these work identically in every engine. Only the syntax for declaring inputs and outputs changes.

2. **The porting process is mechanical.** Replace the entry point, swap uniform names, change the output variable, and handle texture sampling. After doing it twice, you can port any shader in 10 minutes.

3. **Coordinate systems vary.** ShaderToy is Y-up with pixel coordinates. Godot and Love2D canvases are Y-down with 0–1 UVs. Three.js varies by context. When things look wrong, flip Y first.

4. **Engines provide what ShaderToy makes you declare.** Engines give you UV, TIME, projection matrices, and texture access automatically. You actually write *less* code than in ShaderToy.

5. **Multi-pass rendering works differently in every engine.** ShaderToy's Buffer system is unique. Each engine has its own render-to-texture mechanism. Learn your engine's approach.

6. **Start simple, port incrementally.** Do not try to port a 200-line raymarcher as your first shader in a new engine. Start with a solid-color shader. Then a gradient. Then add SDFs. Build confidence with the engine's pipeline before tackling complex effects.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [Godot Shading Language Reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html) | Docs | Complete reference for Godot's shader syntax, built-ins, and types. |
| [Love2D Shader Documentation](https://love2d.org/wiki/love.graphics.newShader) | Docs | Love2D shader API with examples. Covers `effect()`, `position()`, and `extern`. |
| [Three.js ShaderMaterial Docs](https://threejs.org/docs/#api/en/materials/ShaderMaterial) | Docs | Three.js shader material API, including built-in uniforms and attributes. |
| [From ShaderToy to Three.js](https://blog.maximeheckel.com/posts/the-study-of-shaders-with-react-three-fiber/) | Blog | Step-by-step guide to porting ShaderToy effects to React Three Fiber. Practical and visual. |
| [Godot Shaders Wiki](../godot/module-06-shaders-stylized-rendering.md) | Wiki | This roadmap's deep dive on Godot-specific shader techniques. |

---

## Congratulations

You have completed the GLSL Learning Roadmap. Here is what you now know:

- **Module 0:** GPU pipeline, fragment shader basics, ShaderToy
- **Module 1:** Coordinate systems, uniforms, math toolbox
- **Module 2:** Signed distance functions for 2D shapes
- **Module 3:** Color spaces, cosine palettes, blend modes
- **Module 4:** Tiling, rotation, polar coordinates, domain warping
- **Module 5:** Value/Perlin/simplex noise, fBM, domain warping
- **Module 6:** Texture sampling, convolution, UV distortion
- **Module 7:** 2D lighting, shadows, normals, ambient occlusion
- **Module 8:** Vertex shaders, MVP transforms, displacement
- **Module 9:** Post-processing pipelines, bloom, CRT, color grading
- **Module 10:** 3D raymarching with SDFs
- **Module 11:** Easing, sequencing, audio reactivity, buffer feedback
- **Module 12:** Porting to Godot, Love2D, and React Three Fiber

That is a complete shader programming education. You can write procedural textures, create animated visual effects, build 3D scenes from pure math, and deploy it all in game engines. Keep experimenting on ShaderToy, keep porting to your engine of choice, and keep making things that surprise you.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
