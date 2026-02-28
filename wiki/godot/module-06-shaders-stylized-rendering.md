# Module 6: Shaders & Stylized Rendering

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 8–12 hours
**Prerequisites:** [Module 5: Signals, Resources & Game Architecture](module-05-signals-resources-architecture.md)

---

## Overview

This is where your game stops looking like a tech demo and starts looking like art. Everything so far used `StandardMaterial3D` — Godot's built-in PBR material. It's great for realistic rendering, but for stylized games (cel-shaded, painterly, holographic, retro), you need custom shaders. Godot has its own shading language — similar to GLSL but simpler, with built-in access to lights, cameras, and time.

Godot also has a visual shader editor — a node-based alternative where you drag and connect nodes instead of writing code. Same output, different workflow. Some people prefer visual, some prefer code. You'll learn both.

By the end of this module, you'll build a character showcase with three swappable shader modes: cel/toon-shaded, holographic, and dissolve — and at least one of them built entirely in the visual shader editor.

---

## 1. How Godot Shaders Work

### The Four Shader Types

Godot shaders come in four flavors depending on what you're shading:

| Type | Use Case | Where Applied |
|---|---|---|
| `spatial` | 3D geometry | MeshInstance3D, GPUParticles3D |
| `canvas_item` | 2D sprites, UI | Sprite2D, TextureRect, Control |
| `particles` | Particle simulation | GPUParticles3D (process shader) |
| `sky` | Sky rendering | Sky resource |
| `fog` | Volumetric fog | FogVolume |

For 3D game development, you'll live in `spatial`. This entire module focuses on spatial shaders. `canvas_item` shaders are similar but use 2D built-ins.

### The Three Shader Functions

A spatial shader can define up to three functions, each running at a different stage of the GPU pipeline:

```
Geometry → vertex() → Rasterization → fragment() → Light → light()
```

**`vertex()`** — Runs once per vertex. Use it to move, deform, or transform geometry. Outputs clip-space position.

**`fragment()`** — Runs once per pixel (fragment) that the geometry covers on screen. Use it to compute color, roughness, emission, normals. This is where most stylized rendering happens.

**`light()`** — Runs once per light that affects the surface. Use it to customize how each light contributes to the final color. Optional — omit it to use Godot's default lighting.

You don't have to define all three. Most shaders only define `fragment()`. Vertex deformation needs `vertex()`. Custom lighting needs `light()`. Mix and match.

### ShaderMaterial vs StandardMaterial3D

`StandardMaterial3D` is a high-level material with hundreds of configurable properties. Under the hood it compiles to a shader. It covers 90% of realistic PBR use cases.

`ShaderMaterial` is a material that runs your custom shader code. No automatic properties — you control everything via uniforms. It's what you use when `StandardMaterial3D` can't do what you need.

In the inspector: add a `ShaderMaterial` to a `MeshInstance3D`'s `material_override` property, then attach a `Shader` resource (or `VisualShader` resource) to the material.

### The Minimal Spatial Shader

Every spatial shader starts with a type declaration. The functions are optional — but if you don't define `fragment()`, Godot uses its defaults (which is usually pink/magenta, the missing-shader indicator):

```glsl
shader_type spatial;

void vertex() {
    // Runs for each vertex
    // VERTEX is the vertex position in model space
    // Modify it to deform geometry
}

void fragment() {
    // Runs for each pixel
    ALBEDO = vec3(1.0, 0.0, 0.0); // Solid red
}
```

Save this as a `.gdshader` file (e.g. `red.gdshader`), assign it to a `ShaderMaterial`, apply that material to a mesh. You get a solid red object with no lighting. That last part is key — if you set `ALBEDO` without touching `ROUGHNESS` or `METALLIC`, Godot still runs its default lighting model on the surface, so the object will look lit. To get truly flat colors, add `render_mode unshaded;`.

### How Shaders Are Files

In Godot 4, shaders live in `.gdshader` files in your project. Create them from the FileSystem dock (right-click → New → Shader) or by clicking the shader field in a ShaderMaterial and selecting "New Shader."

The editor has a built-in shader editor with:
- Syntax highlighting
- Error reporting at the bottom
- Live preview (changes update in the viewport instantly)
- A "Shader Globals" section for cross-shader shared uniforms

---

## 2. Godot Shading Language Basics

### Not Raw GLSL

Godot's shading language looks like GLSL but it isn't. You can't copy-paste GLSL from Shadertoy and expect it to work. Key differences:

1. **No `in`/`out` qualifiers** — You read and write built-in names directly (`VERTEX`, `NORMAL`, `ALBEDO`) instead of declaring `in vec3 vertex_pos` yourself.
2. **No `main()` function** — You define named functions (`vertex()`, `fragment()`, `light()`).
3. **Uniforms use hint annotations** — `uniform float x : hint_range(0.0, 1.0)` adds a slider in the inspector automatically.
4. **Types are the same** — `float`, `vec2`, `vec3`, `vec4`, `mat3`, `mat4`, `sampler2D`, `bool`, `int`, `uint`.
5. **Built-in functions** — Most GLSL built-ins work: `sin`, `cos`, `mix`, `smoothstep`, `step`, `clamp`, `pow`, `abs`, `floor`, `ceil`, `fract`, `length`, `normalize`, `dot`, `cross`, `reflect`, `texture`.

### Built-In Variables Reference

**In `vertex():`**

| Variable | Type | Description |
|---|---|---|
| `VERTEX` | `vec3` | Vertex position in model space (read/write) |
| `NORMAL` | `vec3` | Vertex normal in model space (read/write) |
| `TANGENT` | `vec3` | Tangent vector (read/write) |
| `BINORMAL` | `vec3` | Binormal/bitangent (read/write) |
| `UV` | `vec2` | Primary UV coordinates (read/write) |
| `UV2` | `vec2` | Secondary UV coordinates (read/write) |
| `COLOR` | `vec4` | Vertex color (read/write) |
| `MODEL_MATRIX` | `mat4` | Object-to-world transform (read only) |
| `VIEW_MATRIX` | `mat4` | World-to-view transform (read only) |
| `PROJECTION_MATRIX` | `mat4` | View-to-clip transform (read only) |
| `MODEL_VIEW_MATRIX` | `mat4` | Combined model-view (read only) |
| `TIME` | `float` | Seconds since startup (read only) |
| `POINT_SIZE` | `float` | Point primitive size (write) |

**In `fragment():`**

| Variable | Type | Description |
|---|---|---|
| `ALBEDO` | `vec3` | Base color output |
| `ALPHA` | `float` | Transparency (0=transparent, 1=opaque) |
| `METALLIC` | `float` | PBR metallic value 0–1 |
| `ROUGHNESS` | `float` | PBR roughness value 0–1 |
| `EMISSION` | `vec3` | Emissive color (additive, HDR) |
| `NORMAL_MAP` | `vec3` | Normal map sample (tangent space) |
| `NORMAL_MAP_DEPTH` | `float` | Normal map strength |
| `NORMAL` | `vec3` | Surface normal in view space (read/write) |
| `UV` | `vec2` | Interpolated UV (read only) |
| `UV2` | `vec2` | Interpolated UV2 (read only) |
| `COLOR` | `vec4` | Interpolated vertex color (read only) |
| `FRAGCOORD` | `vec4` | Fragment coordinates in screen space |
| `SCREEN_UV` | `vec2` | Screen-space UV (0–1 across screen) |
| `VIEW` | `vec3` | Direction from fragment to camera (normalized) |
| `TIME` | `float` | Seconds since startup |
| `DEPTH` | `float` | Depth value override (write) |

**In `light():`**

| Variable | Type | Description |
|---|---|---|
| `LIGHT` | `vec3` | Direction from fragment to light (normalized) |
| `LIGHT_COLOR` | `vec3` | Light color × intensity |
| `ATTENUATION` | `float` | Distance/shadow attenuation 0–1 |
| `DIFFUSE_LIGHT` | `vec3` | Accumulated diffuse (write to add contribution) |
| `SPECULAR_LIGHT` | `vec3` | Accumulated specular (write to add contribution) |
| `NORMAL` | `vec3` | Surface normal |
| `VIEW` | `vec3` | View direction |

### Types and Swizzling

Godot shading language uses the same swizzle syntax as GLSL. You can access components using `.xyzw`, `.rgba`, or `.stpq` — they're interchangeable:

```glsl
vec4 color = vec4(1.0, 0.5, 0.25, 1.0);
vec3 rgb = color.rgb;     // Same as color.xyz
float r = color.r;        // Same as color.x
vec2 uv = color.st;       // Same as color.xy
vec3 flip = color.bgr;    // Swizzle reorder
vec4 dup = color.rrgg;    // Swizzle duplicate
```

### Essential Math Functions

These show up constantly in shaders:

```glsl
// mix: linear interpolation between a and b by t (0=a, 1=b)
float result = mix(0.0, 1.0, 0.5);       // 0.5
vec3 color = mix(red, blue, fresnel);    // blend colors

// smoothstep: smooth curve from 0→1 between edge0 and edge1
float s = smoothstep(0.3, 0.7, value);  // S-curve
// Returns 0.0 when value <= edge0, 1.0 when value >= edge1

// step: sharp 0/1 threshold
float on = step(0.5, value);  // 0.0 if value < 0.5, else 1.0

// clamp: restrict value to [min, max]
float c = clamp(value, 0.0, 1.0);

// fract: fractional part (value - floor(value))
float f = fract(3.7);  // 0.7 — great for repeating patterns

// pow: raise to power — used for fresnel, specular
float spec = pow(ndoth, shininess);

// length and normalize
float dist = length(vec3(1.0, 2.0, 3.0));
vec3 n = normalize(my_vector);

// dot: dot product — used for lighting (NdotL)
float ndotl = dot(normalize(NORMAL), normalize(LIGHT));
```

### Your First Animated Shader

Here's a complete shader demonstrating uniforms, TIME, and math functions together:

```glsl
shader_type spatial;
render_mode unshaded;

uniform float speed : hint_range(0.0, 10.0) = 2.0;
uniform vec3 tint : source_color = vec3(1.0, 0.5, 0.0);

void fragment() {
    // Animated wave across the UV
    float wave = sin(UV.x * 10.0 + TIME * speed) * 0.5 + 0.5;
    ALBEDO = tint * wave;
    ROUGHNESS = 0.5;
}
```

`sin()` returns -1 to 1 — multiply by 0.5 and add 0.5 to remap to 0–1 for color. `UV.x * 10.0` creates 10 wave cycles across the surface. `TIME * speed` animates it.

---

## 3. Uniforms: Connecting GDScript to Shaders

### Uniform Declarations and Hints

Uniforms are variables your GDScript sets from outside the shader. Declare them at the top level with the `uniform` keyword. Hint annotations control how they appear in the inspector:

```glsl
// Slider from 0 to 1
uniform float health : hint_range(0.0, 1.0) = 1.0;

// Slider with step
uniform float bands : hint_range(1.0, 8.0, 1.0) = 3.0;

// Color picker (source_color applies gamma correction)
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec3 tint : source_color = vec3(1.0, 0.5, 0.0);

// Texture samplers with hints for filtering and defaults
uniform sampler2D noise_texture : hint_default_white;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform sampler2D normal_map : hint_normal;
uniform sampler2D depth_hint_tex : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
```

**Common texture hints:**

| Hint | Behavior |
|---|---|
| `hint_default_white` | White if no texture assigned |
| `hint_default_black` | Black if no texture assigned |
| `hint_normal` | Treats as normal map (no gamma correction) |
| `source_color` | Applies sRGB→linear conversion |
| `filter_linear_mipmap` | Bilinear + mipmap filtering |
| `filter_nearest` | Pixelated/nearest filtering |
| `repeat_enable` | Tiling |
| `repeat_disable` | Clamped to edges |

### Setting Uniforms from GDScript

Use `set_shader_parameter()` on the `ShaderMaterial`:

```gdscript
# Get the ShaderMaterial from a node
var mat: ShaderMaterial = $MeshInstance3D.material_override

# Set individual parameters
mat.set_shader_parameter("health", 0.5)
mat.set_shader_parameter("outline_color", Color.RED)
mat.set_shader_parameter("tint", Color(1.0, 0.5, 0.0))

# For vec2/vec3/vec4, use Vector2/Vector3/Color
mat.set_shader_parameter("offset", Vector2(0.1, 0.0))
mat.set_shader_parameter("light_pos", Vector3(5.0, 10.0, 3.0))

# Read a parameter back
var current_health: float = mat.get_shader_parameter("health")
```

If the mesh has a surface material (not material_override), access it differently:

```gdscript
# For per-surface materials
var mat: ShaderMaterial = $MeshInstance3D.get_active_material(0)
mat.set_shader_parameter("dissolve_amount", 0.5)
```

### Animating Uniforms with Tween

The most common pattern: smoothly animate a uniform over time using a Tween:

```gdscript
extends Node3D

@onready var mesh: MeshInstance3D = $Character/MeshInstance3D
var material: ShaderMaterial

func _ready() -> void:
    material = mesh.material_override as ShaderMaterial

func dissolve_out(duration: float = 1.5) -> void:
    var tween: Tween = create_tween()
    tween.tween_method(
        func(value: float): material.set_shader_parameter("dissolve_amount", value),
        0.0,    # from
        1.0,    # to
        duration
    )
    await tween.finished

func dissolve_in(duration: float = 1.5) -> void:
    var tween: Tween = create_tween()
    tween.tween_method(
        func(value: float): material.set_shader_parameter("dissolve_amount", value),
        1.0,
        0.0,
        duration
    )
    await tween.finished
```

### Using AnimationPlayer for Shader Uniforms

You can also keyframe shader parameters in AnimationPlayer. Select the node, open AnimationPlayer, click the key icon on any ShaderMaterial parameter to add a track. The track path looks like:

```
MeshInstance3D:material_override:shader_parameter/dissolve_amount
```

This is great for synchronized effects where shader animation needs to match other animation tracks.

---

## 4. Vertex Shaders: Deforming Geometry

### Why Vertex Shaders

Vertex shaders run on the GPU, in parallel, for every vertex in your mesh. That means deforming thousands of vertices has near-zero CPU cost. Wind, waves, breathing effects, billboards — all free in terms of CPU.

### Wave Deformation

The classic vertex shader: oscillate Y position using a sine wave based on X position and time:

```glsl
shader_type spatial;
uniform float amplitude : hint_range(0.0, 1.0) = 0.2;
uniform float frequency : hint_range(0.0, 10.0) = 3.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 2.0;

void vertex() {
    VERTEX.y += sin(VERTEX.x * frequency + TIME * wave_speed) * amplitude;
}

void fragment() {
    ALBEDO = vec3(0.2, 0.6, 1.0);
    ROUGHNESS = 0.1;
    METALLIC = 0.0;
}
```

Apply this to a flat plane mesh subdivided into many segments (PlaneMesh with subdivide_width and subdivide_depth set to 50+) for smooth waves.

### Wind Simulation for Foliage

Combine multiple frequencies for organic-looking wind:

```glsl
shader_type spatial;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.3;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform vec2 wind_direction = vec2(1.0, 0.3);

void vertex() {
    // Only sway the upper parts of the mesh (using UV.y as height)
    float height_factor = UV.y;  // 0=bottom (root), 1=top (tip)

    // Multiple frequencies for organic feel
    float sway = sin(TIME * wind_speed + VERTEX.x * 0.5) * 0.6;
    sway += sin(TIME * wind_speed * 2.3 + VERTEX.z * 0.7) * 0.3;
    sway += sin(TIME * wind_speed * 0.7) * 0.1;

    VERTEX.x += normalize(wind_direction).x * sway * wind_strength * height_factor;
    VERTEX.z += normalize(wind_direction).y * sway * wind_strength * height_factor;
}
```

### Inflation / Pulsing Effect

Push vertices along their normals — useful for shields, magic effects, breathing:

```glsl
shader_type spatial;
uniform float inflate_amount : hint_range(-0.5, 0.5) = 0.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
uniform float pulse_strength : hint_range(0.0, 0.2) = 0.05;

void vertex() {
    // Static inflation (set from GDScript for shield hits, etc.)
    VERTEX += NORMAL * inflate_amount;

    // Organic breathing pulse
    float pulse = sin(TIME * pulse_speed) * pulse_strength;
    VERTEX += NORMAL * pulse;
}

void fragment() {
    ALBEDO = vec3(0.4, 0.8, 0.4);
    ROUGHNESS = 0.6;
}
```

### Billboard Shader

Make a mesh always face the camera, regardless of object rotation. Great for health bars, particles, 2D-in-3D elements:

```glsl
shader_type spatial;
render_mode billboard;

void fragment() {
    ALBEDO = vec3(1.0, 1.0, 0.0);
}
```

`render_mode billboard` handles it automatically. For more control (fixed Y axis, particles), use `billboard_keep_scale` or `particles_anim_*` modes.

Manual billboard (useful for understanding):

```glsl
shader_type spatial;

void vertex() {
    // Remove rotation from model-view matrix, keep only translation and scale
    mat4 mv = VIEW_MATRIX * MODEL_MATRIX;
    // Zero out rotation columns while preserving scale
    float scale_x = length(mv[0].xyz);
    float scale_y = length(mv[1].xyz);
    float scale_z = length(mv[2].xyz);
    mv[0] = vec4(scale_x, 0.0, 0.0, 0.0);
    mv[1] = vec4(0.0, scale_y, 0.0, 0.0);
    mv[2] = vec4(0.0, 0.0, scale_z, 0.0);
    POSITION = PROJECTION_MATRIX * mv * vec4(VERTEX, 1.0);
}
```

### Vertex Color Usage

Many 3D modeling tools can bake data into vertex colors — weight maps, gradient information, flags for "this vertex should sway." Access them in the shader:

```glsl
void vertex() {
    // Red channel controls wind sway weight
    float sway_weight = COLOR.r;
    VERTEX.x += sin(TIME * 2.0 + VERTEX.x) * 0.3 * sway_weight;
}

void fragment() {
    // Green channel used as a roughness map
    ROUGHNESS = COLOR.g;
    ALBEDO = vec3(0.6, 0.4, 0.2);
}
```

---

## 5. Cel-Shading / Toon Shader

### What Cel-Shading Is

Cel-shading (also called toon shading) mimics the look of hand-drawn animation. Instead of smooth lighting gradients, light is quantized into discrete bands — typically 2–4 levels. The result is a clean, graphic look.

The core technique: compute the dot product of the surface normal and the light direction (N·L), then snap that continuous 0–1 value to discrete steps.

### Method 1: Unshaded with Manual Lighting

Use `render_mode unshaded` to disable Godot's lighting, then compute your own:

```glsl
shader_type spatial;
render_mode unshaded;

uniform vec3 base_color : source_color = vec3(0.8, 0.2, 0.2);
uniform int bands : hint_range(2, 8) = 3;
uniform float rim_power : hint_range(0.0, 10.0) = 3.0;
uniform vec3 rim_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 light_direction = vec3(0.0, -1.0, -0.5);
uniform vec3 shadow_color : source_color = vec3(0.2, 0.1, 0.3);
uniform vec3 highlight_color : source_color = vec3(1.0, 0.9, 0.8);

void fragment() {
    vec3 normal = normalize(NORMAL);
    vec3 light_dir = normalize(light_direction);

    // Quantized diffuse lighting
    float ndotl = dot(normal, -light_dir);
    float intensity = clamp(ndotl, 0.0, 1.0);
    // floor() snaps to bands
    intensity = floor(intensity * float(bands)) / float(bands);

    // Rim lighting — glow at the silhouette edges
    float rim = 1.0 - dot(normal, VIEW);
    rim = pow(rim, rim_power);
    rim = step(0.4, rim);  // Hard edge on rim

    // Combine: shadow blend + rim highlight
    vec3 shaded = mix(shadow_color, base_color * highlight_color, intensity);
    ALBEDO = shaded + rim_color * rim;
}
```

The limitation of Method 1: you're using a single hardcoded light direction. It doesn't respond to Godot's actual lights in the scene.

### Method 2: Using light() for Multi-Light Support

Override `light()` to intercept each light's contribution and quantize it:

```glsl
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.8, 0.2, 0.2);
uniform float bands : hint_range(2.0, 8.0) = 3.0;
uniform float rim_power : hint_range(0.0, 10.0) = 3.0;
uniform vec3 rim_color : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
    ALBEDO = base_color;
    ROUGHNESS = 0.8;
    METALLIC = 0.0;

    // Rim lighting computed in fragment() using VIEW
    float rim = 1.0 - dot(normalize(NORMAL), VIEW);
    rim = pow(rim, rim_power);
    EMISSION = rim_color * step(0.5, rim) * 0.5;
}

void light() {
    // LIGHT is the direction to the light source
    // NORMAL is the surface normal
    float ndotl = dot(NORMAL, LIGHT);
    float intensity = clamp(ndotl, 0.0, 1.0);

    // Quantize: snap to N discrete bands
    intensity = floor(intensity * bands) / bands;

    // Add this light's contribution
    // ATTENUATION handles distance falloff and shadows
    DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * intensity;
}
```

Method 2 is more correct — it responds to all scene lights, respects shadows, and handles point lights and spotlights properly.

### Hard Edge with smoothstep

For a two-tone look (light / shadow with a crisp boundary), `smoothstep` with very close edges creates a near-hard threshold that avoids aliasing:

```glsl
void light() {
    float ndotl = dot(NORMAL, LIGHT);
    // Shadow threshold at 0.3, with a tiny 0.01 transition to prevent aliasing
    float intensity = smoothstep(0.29, 0.31, ndotl);
    DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * intensity;
}
```

Compare with `step(0.3, ndotl)` — identical result but `smoothstep` avoids pixel-level stairstepping on curved surfaces.

### Adding Specular Highlight

A cel-style specular: compute half-vector, take dot with normal, then hard-threshold it:

```glsl
void light() {
    float ndotl = dot(NORMAL, LIGHT);
    float diffuse_intensity = smoothstep(0.29, 0.31, ndotl);

    // Blinn-Phong specular
    vec3 half_vec = normalize(LIGHT + VIEW);
    float ndoth = dot(NORMAL, half_vec);
    float spec_intensity = pow(max(ndoth, 0.0), 32.0);
    spec_intensity = step(0.8, spec_intensity);  // Hard specular dot

    DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * diffuse_intensity;
    SPECULAR_LIGHT += ATTENUATION * LIGHT_COLOR * spec_intensity;
}
```

---

## 6. Outline Rendering

Outlines are one of the most recognizable elements of cel-shaded art. There are two main approaches in Godot.

### Method 1: Inverted Hull (Recommended for 3D)

The classic technique: render the mesh a second time, scaled outward along normals, showing only the back faces. The main mesh hides the "inflated" interior, and only the scaled-out silhouette is visible.

In Godot, apply this as a `next_pass` material on your main material. The main material renders first, then the outline material renders in a second pass.

**Outline shader** (`outline_shader.gdshader`):

```glsl
shader_type spatial;
render_mode cull_front, unshaded;

uniform float outline_width : hint_range(0.0, 0.1) = 0.02;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
    // Push vertices outward along their normals
    // Works in model space — scale-independent
    VERTEX += NORMAL * outline_width;
}

void fragment() {
    ALBEDO = outline_color.rgb;
}
```

`render_mode cull_front` — render only back faces. For the main mesh, back faces are normally hidden. For the inflated mesh, back faces are what sticks out beyond the silhouette.

`unshaded` — outlines should be flat black (or whatever color), no lighting.

**Applying as next_pass in the Inspector:**
1. Select your MeshInstance3D
2. In the Inspector, open its material
3. Scroll to the bottom of the material properties
4. Find the "Next Pass" slot
5. Create a new ShaderMaterial there
6. Assign the outline shader to that ShaderMaterial

**Applying via code:**

```gdscript
func apply_outline(mesh_instance: MeshInstance3D, width: float = 0.02, color: Color = Color.BLACK) -> void:
    var main_material := mesh_instance.get_active_material(0) as BaseMaterial3D

    var outline_shader := preload("res://shaders/outline.gdshader")
    var outline_material := ShaderMaterial.new()
    outline_material.shader = outline_shader
    outline_material.set_shader_parameter("outline_width", width)
    outline_material.set_shader_parameter("outline_color", color)

    main_material.next_pass = outline_material
```

**Limitation:** The inverted hull method breaks on non-watertight meshes and can produce artifacts near sharp edges or UV seams. For hard-edged models, smooth normals help (in your 3D modeling software, set vertex normals to smooth/averaged before export).

**Variable width based on distance:**

For outlines that scale with camera distance (maintaining consistent screen-space width):

```glsl
void vertex() {
    // Compute clip-space position to get depth
    vec4 clip_pos = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0);
    float depth = clip_pos.z / clip_pos.w;

    // Scale outline width by depth so it's consistent on screen
    VERTEX += NORMAL * outline_width * (1.0 + depth * 0.5);
}
```

### Method 2: Screen-Space Edge Detection (Preview)

A post-processing approach: render the depth and normal buffers, then detect discontinuities (edges) in a full-screen fragment shader. More expensive but produces consistent outlines regardless of mesh topology.

This method uses Godot's `hint_depth_texture` and `hint_normal_roughness_texture` samplers in a full-screen quad. Because it's a post-processing effect, it's covered in depth in Module 7 (Post-Processing & VFX). Here's the basic idea:

```glsl
// This runs as a post-processing pass (CompositorEffect or full-screen quad)
// Sample neighboring pixels' depth to detect edges
float depth_center = texture(depth_texture, SCREEN_UV).r;
float depth_right = texture(depth_texture, SCREEN_UV + vec2(pixel_size, 0.0)).r;
float edge = abs(depth_center - depth_right) > threshold ? 1.0 : 0.0;
// edge == 1.0 where there's a depth discontinuity (an object edge)
```

---

## 7. Dissolve Effect

The dissolve effect makes objects appear or disappear as if they're being burned away — driven by a noise texture. It's one of the most visually satisfying shader effects and is straightforward to implement.

### How It Works

1. Sample a noise texture at the UV coordinates to get a 0–1 noise value per pixel
2. Use `discard` to skip rendering pixels where the noise value is below the dissolve threshold
3. Near the threshold boundary, add a glowing edge using `EMISSION`

### The Dissolve Shader

```glsl
shader_type spatial;

uniform sampler2D noise_texture : hint_default_white;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.04;
uniform vec3 edge_color : source_color = vec3(1.0, 0.5, 0.0);
uniform float edge_emission : hint_range(0.0, 20.0) = 8.0;
uniform vec3 base_color : source_color = vec3(0.6, 0.6, 0.6);

void fragment() {
    float noise = texture(noise_texture, UV).r;

    // Discard pixels that are "dissolved"
    if (noise < dissolve_amount) {
        discard;
    }

    // Compute edge: how close is this pixel to the dissolve boundary?
    float edge_threshold = dissolve_amount + edge_width;
    float edge = 1.0 - smoothstep(dissolve_amount, edge_threshold, noise);
    // edge approaches 1.0 near the dissolve boundary, 0.0 farther away

    // Apply edge glow
    ALBEDO = mix(base_color, edge_color, edge);
    EMISSION = edge_color * edge * edge_emission;
    ROUGHNESS = 0.7;
    METALLIC = 0.0;
}
```

### discard — What It Does

`discard` in a fragment shader completely skips writing that pixel — no color, no depth. It's like the pixel doesn't exist. Important caveats:
- `discard` breaks early depth test optimizations (the GPU can't use depth pre-pass for these fragments)
- For many dissolving objects at once, this can be a performance concern
- For most game use cases (single character dissolving in a cutscene) it's fine

### Setting Up NoiseTexture2D

The dissolve effect needs a noise texture. Godot's built-in `NoiseTexture2D` resource is perfect:

1. In the ShaderMaterial properties, click the `noise_texture` slot
2. Choose "New NoiseTexture2D"
3. Click it to expand, then set Noise → "New FastNoiseLite"
4. Adjust: Width/Height = 256 or 512, Seamless = true (for tiling without seams)
5. Under FastNoiseLite: Type = "Cellular" or "Simplex" for different looks

Seamless textures tile without visible edges, which is important when UV wraps across a character mesh.

### Animated Dissolve Controller

```gdscript
extends Node3D

@onready var mesh: MeshInstance3D = $Character/Body
var shader_material: ShaderMaterial

enum DissolveState { VISIBLE, DISSOLVED, TRANSITIONING }
var state: DissolveState = DissolveState.VISIBLE

func _ready() -> void:
    shader_material = mesh.material_override as ShaderMaterial

func appear(duration: float = 1.2) -> void:
    if state == DissolveState.VISIBLE:
        return
    state = DissolveState.TRANSITIONING
    mesh.visible = true

    var tween := create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_method(
        func(v: float): shader_material.set_shader_parameter("dissolve_amount", v),
        1.0, 0.0, duration
    )
    await tween.finished
    state = DissolveState.VISIBLE

func disappear(duration: float = 1.2) -> void:
    if state == DissolveState.DISSOLVED:
        return
    state = DissolveState.TRANSITIONING

    var tween := create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_method(
        func(v: float): shader_material.set_shader_parameter("dissolve_amount", v),
        0.0, 1.0, duration
    )
    await tween.finished
    mesh.visible = false
    state = DissolveState.DISSOLVED
```

### Enhancing the Dissolve: UV Tiling

For more detail on large meshes, tile the noise texture:

```glsl
// In fragment():
// Tile the noise 3x3 for finer detail
float noise = texture(noise_texture, UV * 3.0).r;
```

Or blend two noise scales for more organic variation:

```glsl
float noise_coarse = texture(noise_texture, UV).r;
float noise_fine = texture(noise_texture, UV * 5.0).r;
float noise = noise_coarse * 0.7 + noise_fine * 0.3;
```

---

## 8. Holographic / Fresnel Shader

The holographic effect combines several techniques: Fresnel (edge glow), scanlines (animated horizontal bands), and flicker (random brightness variation). It reads as "science fiction display" immediately.

### Fresnel Effect

Fresnel: surfaces that face the camera directly appear transparent; surfaces at glancing angles appear bright. This is physically accurate for glass and water, but the shader version exaggerates it for style.

The formula: `fresnel = pow(1.0 - dot(NORMAL, VIEW), power)`. Higher power = narrower rim.

### The Holographic Shader

```glsl
shader_type spatial;
render_mode blend_add, cull_disabled, unshaded;

uniform vec3 holo_color : source_color = vec3(0.0, 0.8, 1.0);
uniform float fresnel_power : hint_range(0.0, 10.0) = 3.0;
uniform float fresnel_strength : hint_range(0.0, 2.0) = 1.0;
uniform float scanline_count : hint_range(10.0, 200.0) = 80.0;
uniform float scanline_contrast : hint_range(0.0, 1.0) = 0.3;
uniform float scanline_speed : hint_range(0.0, 5.0) = 1.0;
uniform float flicker_speed : hint_range(0.0, 20.0) = 5.0;
uniform float flicker_strength : hint_range(0.0, 0.5) = 0.1;
uniform float base_alpha : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec3 normal = normalize(NORMAL);

    // Fresnel: bright at edges, transparent in center
    float fresnel = pow(1.0 - dot(normal, VIEW), fresnel_power) * fresnel_strength;

    // Scanlines: horizontal bands using screen UV (moves independently of mesh)
    float scanlines = sin(SCREEN_UV.y * scanline_count + TIME * scanline_speed);
    scanlines = scanlines * scanline_contrast + (1.0 - scanline_contrast);
    // Remap from [-1, 1] → dim to bright

    // Flicker: slow global brightness oscillation + fast noise-like modulation
    float flicker_slow = sin(TIME * flicker_speed * 0.7) * 0.05;
    float flicker_fast = sin(TIME * flicker_speed * 13.0) * 0.03;
    float flicker = 1.0 + flicker_slow + flicker_fast;
    flicker = clamp(flicker, 1.0 - flicker_strength, 1.0 + flicker_strength);

    // Combine
    float alpha = (fresnel + base_alpha) * scanlines * flicker;
    alpha = clamp(alpha, 0.0, 1.0);

    ALBEDO = holo_color;
    ALPHA = alpha;
    EMISSION = holo_color * fresnel * 2.0;
}
```

**`render_mode blend_add`** — additive blending. Pixels add their color on top of what's behind them instead of replacing it. Perfect for glowing/holographic effects — black is transparent, bright is bright.

**`render_mode cull_disabled`** — render both front and back faces, so the hologram looks solid from all angles (the back face renders the interior).

**`render_mode unshaded`** — holograms don't receive scene lighting; they glow independently.

### Handling Transparency Sorting

Transparent objects in Godot need correct depth sorting to look right. Additive blend (`blend_add`) is self-sorting by nature (order doesn't matter with addition), but regular blend_mix transparency requires care.

For holographic objects that use blend_add, you generally don't need to worry about sorting. For dissolve effects using `discard`, the object writes to the depth buffer normally.

### Scan Line Variant: World-Space Scanlines

Instead of screen-space scanlines (which slide as the camera moves), you can use world-space scanlines that feel "attached" to the object:

```glsl
// In fragment():
// World-space position for scanlines that move with the object
vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
float scanlines = sin(world_pos.y * scanline_count + TIME * scanline_speed) * 0.5 + 0.5;
```

In `fragment()`, `VERTEX` is not available directly as world position — you need to pass it from `vertex()`:

```glsl
varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float scanlines = sin(world_position.y * 80.0 + TIME * 1.5) * 0.5 + 0.5;
    // ...
}
```

`varying` variables are interpolated from `vertex()` to `fragment()` — the bridge between the two stages.

---

## 9. Procedural Textures

Procedural textures are generated entirely in the shader — no image files needed. They're infinitely scalable, resolution-independent, and trivially animatable.

### Basic Patterns

**Stripes:**
```glsl
void fragment() {
    float stripe = step(0.5, fract(UV.y * 10.0));
    ALBEDO = mix(vec3(1.0), vec3(0.0), stripe);
}
```
`fract()` extracts the fractional part, creating a 0→1 sawtooth wave repeated 10 times. `step(0.5, ...)` thresholds it to a stripe.

**Checkerboard:**
```glsl
void fragment() {
    float cx = step(0.5, fract(UV.x * 8.0));
    float cy = step(0.5, fract(UV.y * 8.0));
    float check = abs(cx - cy);  // XOR: 1.0 where exactly one is 1
    ALBEDO = mix(vec3(0.9), vec3(0.1), check);
}
```

**Polka Dots:**
```glsl
void fragment() {
    // Tile UV into a grid
    vec2 tiled = fract(UV * 8.0) - 0.5;  // -0.5 to 0.5 within each cell
    float dist = length(tiled);           // Distance from cell center
    float dot_mask = step(dist, 0.3);     // Circle with radius 0.3
    ALBEDO = mix(vec3(0.9), vec3(0.2, 0.4, 1.0), dot_mask);
}
```

**Radial gradient:**
```glsl
void fragment() {
    vec2 centered = UV - 0.5;  // -0.5 to 0.5
    float dist = length(centered);
    float circle = 1.0 - smoothstep(0.3, 0.5, dist);
    ALBEDO = mix(vec3(0.1, 0.1, 0.5), vec3(1.0, 0.8, 0.0), circle);
}
```

### Animated Patterns

Everything becomes dynamic with TIME:

```glsl
// Scrolling stripes
float stripe = step(0.5, fract(UV.y * 10.0 - TIME * 0.5));

// Rotating pattern
vec2 centered = UV - 0.5;
float angle = atan(centered.y, centered.x) + TIME;
float radial_stripe = step(0.5, fract(angle / (2.0 * PI) * 6.0));

// Expanding circles
float pulse = fract(length(UV - 0.5) * 5.0 - TIME);
float ring = step(0.8, pulse);
```

### Using Noise for Organic Patterns

Pure math patterns feel mechanical. Noise adds organic irregularity. Use a `NoiseTexture2D` sampler:

```glsl
shader_type spatial;
render_mode unshaded;

uniform sampler2D noise_tex : hint_default_white, repeat_enable;
uniform vec3 color_a : source_color = vec3(0.2, 0.5, 0.8);
uniform vec3 color_b : source_color = vec3(0.8, 0.4, 0.1);
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;
uniform float noise_speed : hint_range(0.0, 2.0) = 0.3;
uniform float stripe_count : hint_range(1.0, 20.0) = 8.0;
uniform float stripe_sharpness : hint_range(1.0, 50.0) = 10.0;

void fragment() {
    // Noise-warped UV
    float noise_val = texture(noise_tex, UV * noise_scale + TIME * noise_speed).r;

    // Use noise to distort stripe position
    float warp = noise_val * 0.3;
    float stripe = sin((UV.y + warp) * stripe_count * 3.14159);

    // Sharpen the stripe edges
    stripe = clamp(stripe * stripe_sharpness, -1.0, 1.0) * 0.5 + 0.5;

    // Second noise layer for color variation
    float color_noise = texture(noise_tex, UV * noise_scale * 0.5 + 0.37).r;

    ALBEDO = mix(color_a, color_b, mix(stripe, color_noise, 0.3));
    EMISSION = ALBEDO * 0.2;
}
```

### Triplanar Texture Mapping (Preview)

Triplanar mapping avoids UV stretching on curved or complex surfaces by blending three projections (X, Y, Z axes). It's particularly useful for terrain shaders. Full implementation is in the Exercise section, but the concept:

```glsl
// Sample texture three times, once per axis
vec3 triplanar_sample(sampler2D tex, vec3 world_pos, vec3 world_normal, float scale) {
    vec3 blend = abs(world_normal);
    blend = normalize(max(blend, 0.0001));
    blend /= (blend.x + blend.y + blend.z);  // Weights sum to 1

    vec3 x_proj = texture(tex, world_pos.yz * scale).rgb;
    vec3 y_proj = texture(tex, world_pos.xz * scale).rgb;
    vec3 z_proj = texture(tex, world_pos.xy * scale).rgb;

    return x_proj * blend.x + y_proj * blend.y + z_proj * blend.z;
}
```

---

## 10. The Visual Shader Editor

### What It Is

The Visual Shader editor is a node-based alternative to writing shader code. Instead of typing GLSL-like code, you create nodes and connect them with wires. The output is identical — Godot compiles the node graph to the same GPU code as a text shader.

### Creating a Visual Shader

1. Create a `ShaderMaterial` on your mesh
2. In the material's Shader slot, choose "New VisualShader" instead of "New Shader"
3. Double-click the VisualShader resource to open the Visual Shader editor
4. The editor opens with an "Output" node already placed

### Node Categories

The node palette is organized by category:

| Category | Examples |
|---|---|
| **Input** | UV, Normal, View, Time, Vertex, FragCoord |
| **Output** | Fragment Output, Vertex Output, Light Output |
| **Scalar** | Float Constant, Float Op, Clamp, Smoothstep, Step |
| **Vector** | Vec3 Constant, Dot Product, Cross Product, Normalize |
| **Color** | Color Constant, Mix, Blend |
| **Texture** | Texture2D (for sampling), NoiseTexture |
| **Transform** | TransformMult, World Matrix |
| **Utility** | If, Compare, Switch |
| **Functions** | Sin, Cos, Pow, Fract, Floor |

### Building a Cel Shader Visually

Here's how to replicate the cel-shader's light() function in the visual editor:

**Step 1: Normal and Light input**
- Add: Input → Fragment → Normal (outputs vec3)
- Add: Input → Light → Light (outputs vec3)

**Step 2: Dot product**
- Add: Vector → Dot Product
- Connect Normal → A input
- Connect Light → B input
- Output: scalar 0–1 (the N·L value)

**Step 3: Quantize**
- Add: Scalar → Float Op (set to Multiply)
  - Input A: DotProduct output
  - Input B: Float Constant = 3.0 (number of bands)
- Add: Scalar → Floor
  - Input: Float Op output
- Add: Scalar → Float Op (set to Divide)
  - Input A: Floor output
  - Input B: Float Constant = 3.0

**Step 4: Apply to color**
- Add: Color → Mix
  - A: shadow color (Vec3 Constant)
  - B: base color (Vec3 Constant)
  - Weight: Quantize output (from Step 3)
- Connect Mix output → Output → Albedo

**Step 5: Add Rim Lighting**
- Add: Input → Fragment → Normal
- Add: Input → Fragment → View
- Add: Vector → Dot Product (Normal · View)
- Add: Scalar → Float Op: 1.0 - DotProduct (subtract from Float Constant 1.0)
- Add: Scalar → Pow (base = above, exponent = 3.0)
- Add: Color → Mix (blend rim_color based on Pow output)
- Add the rim result into the Albedo (use Vector → Float Op Add or a second Mix)

### Visual Shader Uniforms

Right-click in the graph → Add Node → Input → Uniform. Name it, set the type, and it appears in the inspector just like a `uniform` in code.

### Code vs Visual: When to Use Each

| Situation | Prefer |
|---|---|
| Math-heavy shaders (many formulas) | Code — faster to write, easier to read |
| Artist-friendly iteration | Visual — drag nodes, no syntax errors |
| Teaching shader concepts | Visual — makes data flow visible |
| Noise and texture combinations | Visual — easy to preview each node |
| Porting GLSL examples from the web | Code — direct translation |
| Sharing with non-programmers | Visual — no code knowledge needed |

Both compile to identical GPU output. You can mix: write a code shader, then convert it to Visual (or vice versa). Godot doesn't support this conversion automatically, but you can manually re-create any code shader in the visual editor.

---

## 11. render_mode and Advanced Settings

### What render_mode Controls

`render_mode` is a semicolon-separated list of flags at the top of your shader. They affect how Godot processes and renders the material before your shader code even runs.

```glsl
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;
```

Multiple flags are comma-separated.

### Lighting Modes

| Mode | Effect |
|---|---|
| *(none)* | Full PBR lighting applied. ALBEDO, ROUGHNESS, METALLIC used by Godot's lighting. |
| `unshaded` | No lighting applied. ALBEDO becomes the final color. Use for UI-like 3D, glows, cel shaders with manual lighting. |
| `shadows_disabled` | Disables shadow casting and receiving on this material. Cheaper, useful for distant objects. |
| `ambient_light_disabled` | Ignores environment ambient light. |
| `specular_disabled` | Skips specular lighting computation. Cheaper for rough/matte surfaces. |

### Blend Modes

| Mode | Behavior | Use For |
|---|---|---|
| `blend_mix` | Standard alpha blend: lerp between surface and background | Windows, glass, dissolve with alpha |
| `blend_add` | Add surface color to background | Glows, fire, holograms, laser beams |
| `blend_sub` | Subtract surface color from background | Dark energy, shadow effects, rare |
| `blend_mul` | Multiply surface with background | Tinted glass, darkening overlays |

Alpha blending requires transparent objects to be sorted back-to-front. Additive blending is order-independent (can render in any order and looks correct). Subtractive and multiplicative are also order-independent.

### Culling Modes

| Mode | Renders | Use For |
|---|---|---|
| `cull_back` | Front faces only (default) | Standard opaque geometry |
| `cull_front` | Back faces only | Inverted hull outlines |
| `cull_disabled` | Both faces | Transparent objects, holograms, thin geometry |

### Depth Modes

| Mode | Behavior |
|---|---|
| `depth_draw_opaque` | Write to depth buffer for opaque pixels (default) |
| `depth_draw_always` | Always write to depth, even transparent pixels |
| `depth_draw_never` | Never write to depth (object won't occlude others) |
| `depth_test_disabled` | Ignore depth — always render on top |

`depth_test_disabled` is useful for overlays, highlights, and outlines that should always be visible.

### Vertex Modes

| Mode | Behavior |
|---|---|
| `vertex_lighting` | Compute lighting per-vertex instead of per-pixel. Faster, lower quality |
| `billboard` | Automatically face camera |
| `billboard_keep_scale` | Billboard but preserve object scale |
| `skip_vertex_transform` | Don't apply model/view/projection (you handle it manually) |

### Alpha Scissor (Cutout)

For foliage, fences, or any texture with transparency but no smooth blending:

```glsl
shader_type spatial;
render_mode alpha_scissor;

uniform sampler2D albedo_tex : source_color;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 color = texture(albedo_tex, UV);
    ALBEDO = color.rgb;
    ALPHA = color.a;
    ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}
```

`alpha_scissor` discards pixels below the threshold (like `discard`) but integrates with the depth pre-pass properly, avoiding transparency sorting issues.

---

## 12. Code Walkthrough: Character Showcase

### Scene Structure

```
CharacterShowcase (Node3D)
├── World (Node3D)
│   ├── DirectionalLight3D
│   ├── OmniLight3D        (fill light)
│   └── WorldEnvironment
├── Stage (Node3D)
│   └── CSGCylinder3D      (simple stage/pedestal)
├── Character (Node3D)
│   └── MeshInstance3D     (Capsule or imported Kenney mesh)
├── TurntableCamera (Node3D)  — rotates around character
│   └── Camera3D
└── UI (CanvasLayer)
    ├── ShaderLabel (Label)
    └── Instructions (Label)
```

### Shader Files

Create three shader files in `res://shaders/`:

**`cel_shader.gdshader`:**

```glsl
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.7, 0.3, 0.8);
uniform vec3 shadow_color : source_color = vec3(0.2, 0.1, 0.35);
uniform float bands : hint_range(2.0, 8.0, 1.0) = 3.0;
uniform float specular_sharpness : hint_range(8.0, 128.0) = 48.0;
uniform float rim_power : hint_range(0.5, 8.0) = 4.0;
uniform vec3 rim_color : source_color = vec3(1.0, 0.9, 0.6);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.6;
uniform vec4 outline_color : source_color = vec4(0.05, 0.0, 0.1, 1.0);

void fragment() {
    ALBEDO = base_color;
    ROUGHNESS = 0.9;
    METALLIC = 0.0;

    // Rim in fragment using VIEW
    float rim = 1.0 - clamp(dot(normalize(NORMAL), VIEW), 0.0, 1.0);
    rim = pow(rim, rim_power);
    rim = step(0.4, rim) * rim_strength;
    EMISSION = rim_color * rim;
}

void light() {
    // Quantized diffuse
    float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
    float quantized = floor(ndotl * bands) / bands;
    vec3 diffuse = mix(shadow_color, base_color, quantized) * LIGHT_COLOR * ATTENUATION;
    DIFFUSE_LIGHT += diffuse;

    // Hard specular highlight
    vec3 half_vec = normalize(LIGHT + VIEW);
    float ndoth = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
    float spec = step(0.95, pow(ndoth, specular_sharpness));
    SPECULAR_LIGHT += spec * LIGHT_COLOR * ATTENUATION;
}
```

**`holographic.gdshader`:**

```glsl
shader_type spatial;
render_mode blend_add, cull_disabled, unshaded;

uniform vec3 holo_color : source_color = vec3(0.0, 0.8, 1.0);
uniform float fresnel_power : hint_range(0.5, 10.0) = 3.5;
uniform float scanline_count : hint_range(10.0, 200.0) = 60.0;
uniform float scanline_speed : hint_range(0.0, 5.0) = 1.2;
uniform float scanline_contrast : hint_range(0.0, 0.5) = 0.25;
uniform float flicker_speed : hint_range(0.0, 20.0) = 4.0;
uniform float base_alpha : hint_range(0.0, 0.5) = 0.2;

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec3 normal = normalize(NORMAL);
    float fresnel = pow(1.0 - clamp(dot(normal, VIEW), 0.0, 1.0), fresnel_power);

    float scanlines = sin(world_pos.y * scanline_count + TIME * scanline_speed);
    scanlines = scanlines * scanline_contrast + (1.0 - scanline_contrast);

    float flicker = sin(TIME * flicker_speed) * 0.07 + sin(TIME * flicker_speed * 7.3) * 0.03 + 0.9;
    flicker = clamp(flicker, 0.7, 1.1);

    float alpha = (fresnel + base_alpha) * scanlines * flicker;

    ALBEDO = holo_color;
    ALPHA = clamp(alpha, 0.0, 1.0);
    EMISSION = holo_color * fresnel * 2.5;
}
```

**`dissolve.gdshader`:**

```glsl
shader_type spatial;

uniform sampler2D noise_texture : hint_default_white, repeat_enable;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.01, 0.2) = 0.05;
uniform vec3 edge_color : source_color = vec3(1.0, 0.4, 0.0);
uniform float edge_emission : hint_range(0.0, 20.0) = 10.0;
uniform vec3 base_color : source_color = vec3(0.7, 0.3, 0.8);
uniform float noise_scale : hint_range(0.5, 5.0) = 1.5;

void fragment() {
    // Blend two noise scales for organic look
    float n1 = texture(noise_texture, UV * noise_scale).r;
    float n2 = texture(noise_texture, UV * noise_scale * 3.5 + vec2(0.37, 0.71)).r;
    float noise = n1 * 0.65 + n2 * 0.35;

    if (noise < dissolve_amount) {
        discard;
    }

    float edge = 1.0 - smoothstep(dissolve_amount, dissolve_amount + edge_width, noise);

    ALBEDO = mix(base_color, edge_color, edge);
    EMISSION = edge_color * edge * edge_emission;
    ROUGHNESS = 0.8;
    METALLIC = 0.0;
}
```

**`outline.gdshader`** (applied as next_pass on cel_shader material):

```glsl
shader_type spatial;
render_mode cull_front, unshaded;

uniform float outline_width : hint_range(0.0, 0.05) = 0.015;
uniform vec4 outline_color : source_color = vec4(0.05, 0.0, 0.1, 1.0);

void vertex() {
    VERTEX += NORMAL * outline_width;
}

void fragment() {
    ALBEDO = outline_color.rgb;
}
```

### GDScript Controller

`res://scripts/character_showcase.gd`:

```gdscript
extends Node3D

# Shader materials — assign in inspector or load here
@export var cel_shader_material: ShaderMaterial
@export var holo_shader_material: ShaderMaterial
@export var dissolve_shader_material: ShaderMaterial

@onready var mesh: MeshInstance3D = $Character/MeshInstance3D
@onready var turntable: Node3D = $TurntableCamera
@onready var shader_label: Label = $UI/ShaderLabel
@onready var instructions: Label = $UI/Instructions

enum ShaderMode { CEL, HOLO, DISSOLVE }
var current_mode: ShaderMode = ShaderMode.CEL

const TURNTABLE_SPEED := 30.0  # degrees per second
var is_dissolving: bool = false

func _ready() -> void:
    # Set up noise texture for dissolve if not set
    if dissolve_shader_material:
        var noise_tex := NoiseTexture2D.new()
        var noise := FastNoiseLite.new()
        noise.noise_type = FastNoiseLite.TYPE_CELLULAR
        noise.frequency = 0.05
        noise_tex.noise = noise
        noise_tex.width = 256
        noise_tex.height = 256
        noise_tex.seamless = true
        dissolve_shader_material.set_shader_parameter("noise_texture", noise_tex)

    apply_shader(ShaderMode.CEL)
    update_ui()

    instructions.text = "1 — Cel Shaded\n2 — Holographic\n3 — Dissolve (press again to reappear)"

func _process(delta: float) -> void:
    turntable.rotation_degrees.y += TURNTABLE_SPEED * delta

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_1:
                apply_shader(ShaderMode.CEL)
            KEY_2:
                apply_shader(ShaderMode.HOLO)
            KEY_3:
                if current_mode == ShaderMode.DISSOLVE and not is_dissolving:
                    dissolve_in()
                else:
                    apply_shader(ShaderMode.DISSOLVE)
                    dissolve_out()

func apply_shader(mode: ShaderMode) -> void:
    current_mode = mode
    match mode:
        ShaderMode.CEL:
            mesh.material_override = cel_shader_material
        ShaderMode.HOLO:
            mesh.material_override = holo_shader_material
        ShaderMode.DISSOLVE:
            dissolve_shader_material.set_shader_parameter("dissolve_amount", 0.0)
            mesh.material_override = dissolve_shader_material
            mesh.visible = true
    update_ui()

func dissolve_out() -> void:
    if is_dissolving:
        return
    is_dissolving = true
    var tween := create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_method(
        func(v: float): dissolve_shader_material.set_shader_parameter("dissolve_amount", v),
        0.0, 1.0, 1.5
    )
    await tween.finished
    mesh.visible = false
    is_dissolving = false

func dissolve_in() -> void:
    if is_dissolving:
        return
    is_dissolving = true
    mesh.visible = true
    var tween := create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_method(
        func(v: float): dissolve_shader_material.set_shader_parameter("dissolve_amount", v),
        1.0, 0.0, 1.5
    )
    await tween.finished
    apply_shader(ShaderMode.CEL)
    is_dissolving = false

func update_ui() -> void:
    var names := {
        ShaderMode.CEL: "Cel Shaded (with outline)",
        ShaderMode.HOLO: "Holographic",
        ShaderMode.DISSOLVE: "Dissolve"
    }
    shader_label.text = "Current: %s" % names[current_mode]
```

### Turntable Camera Setup

The turntable works by rotating a parent `Node3D` while keeping the camera at a fixed offset:

In the scene:
- `TurntableCamera` (Node3D) — positioned at the character's center (0, 1.2, 0)
- `Camera3D` — child of TurntableCamera, positioned at (0, 0, 4) looking at origin

The `_process` in the controller rotates `TurntableCamera.rotation_degrees.y` each frame. The camera orbits automatically.

### Applying the Outline

For the cel-shader material, add the outline as a next_pass. In code during `_ready()`:

```gdscript
func _ready() -> void:
    # ... other setup ...

    # Add outline as next_pass to cel material
    var outline_shader := preload("res://shaders/outline.gdshader")
    var outline_mat := ShaderMaterial.new()
    outline_mat.shader = outline_shader
    outline_mat.set_shader_parameter("outline_width", 0.015)
    outline_mat.set_shader_parameter("outline_color", Color(0.05, 0.0, 0.1))
    cel_shader_material.next_pass = outline_mat
```

### Cel Shader as Visual Shader (Bonus)

As a bonus exercise, rebuild the cel-shader's `fragment()` in the Visual Shader editor:

1. Open the VisualShader editor
2. Add: Input > Fragment > Normal → Normalize node
3. Add: Input > Fragment > View
4. Add: Vector > DotProduct (Normal · View) → outputs float for rim
5. Add: Scalar > FloatOp (1.0 - DotProduct) → rim base
6. Add: Scalar > Pow (rim_base, 4.0) → rim falloff
7. Add: Scalar > Step (0.4, Pow output) → hard rim edge
8. Add: VectorOp (Multiply): rim_color * Step output → rim contribution
9. Add that to the Emission output

For the diffuse (requires light() — note that Visual Shaders also support light functions via the "Light" output node type).

---

## 2D Bridge: Canvas Item Shaders and Stylized 2D Art

> **Context shift.** The 3D section covers `shader_type spatial` — shaders that run on 3D geometry. In 2D, the equivalent is `shader_type canvas_item`. It's a simpler model (sprites instead of meshes, one `COLOR` output instead of PBR channels) but all the concepts — uniforms, UV manipulation, noise, TIME — transfer directly. This is the highest-leverage module for a graphic designer: canvas_item shaders let you apply professional visual effects to any sprite in the dungeon.

### canvas_item vs spatial: What Changes

| Concept | `spatial` | `canvas_item` |
|---|---|---|
| Shader type declaration | `shader_type spatial;` | `shader_type canvas_item;` |
| Output | `ALBEDO`, `ROUGHNESS`, `EMISSION` | `COLOR` (vec4 including alpha) |
| Vertex position | `VERTEX` (vec3) | `VERTEX` (vec2) |
| UV | `UV` | `UV` (same) |
| Texture access | Declare `uniform sampler2D` | `TEXTURE` built-in (the sprite's own texture) |
| Texture pixel size | `1.0 / textureSize(...)` | `TEXTURE_PIXEL_SIZE` built-in |
| Screen UV | `SCREEN_UV` | `SCREEN_UV` (same) |
| Time | `TIME` | `TIME` (same) |
| Lighting | `light()` function | `light()` function (uses 2D lights) |
| Normal output | `NORMAL` | `NORMAL_MAP` + `NORMAL_MAP_DEPTH` |

The biggest practical difference: `COLOR` is a `vec4` where the alpha channel controls transparency. In `spatial`, transparency requires setting `ALPHA` explicitly. In `canvas_item`, any pixel with `COLOR.a = 0.0` is fully transparent.

**`TEXTURE` is free.** You don't declare it — it's automatically the sprite's texture. This is the most common source of confusion when coming from spatial shaders.

### The Minimal canvas_item Shader

Every canvas_item shader starts here:

```glsl
shader_type canvas_item;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = tex;  // identity shader — passes the sprite through unchanged
}
```

Assign this to a Sprite2D via `ShaderMaterial` (same workflow as spatial: create a `ShaderMaterial` resource, assign a `Shader` to it, assign the `ShaderMaterial` to the Sprite2D).

### Sprite Outline Shader

One of the most commonly needed 2D effects. Samples neighboring pixels — where neighbors exist but the current pixel is transparent, draw the outline color.

```glsl
shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0, 1.0) = 1.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    vec4 tex = texture(TEXTURE, UV);

    // Sample 4 neighbors
    float neighbor_alpha = 0.0;
    neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2( size.x,  0.0   )).a);
    neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(-size.x,  0.0   )).a);
    neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2( 0.0,     size.y)).a);
    neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2( 0.0,    -size.y)).a);

    // Draw outline where neighbors are opaque but this pixel is not
    float outline = neighbor_alpha * (1.0 - tex.a);
    COLOR = mix(tex, vec4(outline_color.rgb, outline), outline);
}
```

`TEXTURE_PIXEL_SIZE` is `1.0 / texture_resolution` — it ensures the outline width is consistent regardless of sprite resolution. An `outline_width` of `1.0` means exactly 1 pixel.

Compare to the 3D inverted hull outline from Section 6 above: that technique requires geometry to inflate. Sprites have no geometry, so the neighbor-sampling approach is used instead — completely different implementation, same visual result.

### Palette Swap Shader

A defining technique for top-down RPGs — recolor enemy variants, color equipment, or tint characters by team without creating separate sprite assets.

**Gradient remap approach** (most flexible for a designer):

```glsl
shader_type canvas_item;

uniform sampler2D palette : filter_nearest;
uniform float mix_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    // Convert sprite pixel to luminance (grayscale)
    float luminance = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    // Sample the palette texture at that luminance position
    vec4 palette_color = texture(palette, vec2(luminance, 0.0));
    // Blend between original and remapped color
    COLOR = vec4(mix(tex.rgb, palette_color.rgb, mix_amount * tex.a), tex.a);
}
```

**Create palette textures as 1-pixel-tall gradient PNGs:**
- In Photoshop/Affinity: create a 256×1 canvas, fill with a gradient from dark→mid→light in your target color
- Export as PNG
- In Godot: import with Filter = Nearest (critical — prevents interpolation between palette colors)
- Assign to the `palette` uniform

Design variants: the sprite stays grayscale in the source art. The palette texture defines the coloring. Enemy goblins can all share one sprite sheet but use different `palette` textures for green goblins, blue ice goblins, red fire goblins — all from a single shader uniform change.

### Dissolve Effect on Sprites

Direct port of the 3D dissolve shader from Section 7 above. The structure is nearly identical:

```glsl
shader_type canvas_item;

uniform sampler2D noise_texture : hint_default_white;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;
uniform vec3 edge_color : source_color = vec3(1.0, 0.4, 0.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float noise = texture(noise_texture, UV).r;

    if (noise < dissolve_amount) {
        discard;  // discard works in canvas_item exactly like in spatial
    }

    float edge = 1.0 - smoothstep(dissolve_amount, dissolve_amount + edge_width, noise);
    COLOR = vec4(mix(tex.rgb, edge_color, edge * tex.a), tex.a);
}
```

The only changes from the spatial version: `COLOR` instead of `ALBEDO`/`EMISSION`, and the alpha is carried through manually. `discard` works identically.

Animate `dissolve_amount` from `0.0` to `1.0` in an AnimationPlayer track to create an enemy death effect. Wire it to the `hurt` or `die` state in your AnimationTree state machine.

### Water and Distortion Shader

Animate UV coordinates with `TIME` to create water surface ripple:

```glsl
shader_type canvas_item;

uniform float wave_strength : hint_range(0.0, 0.05) = 0.015;
uniform float wave_speed : hint_range(0.0, 10.0) = 2.5;
uniform float wave_frequency : hint_range(0.0, 50.0) = 12.0;

void fragment() {
    vec2 distorted_uv = UV;
    distorted_uv.x += sin(UV.y * wave_frequency + TIME * wave_speed) * wave_strength;
    distorted_uv.y += cos(UV.x * wave_frequency + TIME * wave_speed) * wave_strength;
    COLOR = texture(TEXTURE, distorted_uv);
}
```

Apply this to a Sprite2D or a dedicated TileMapLayer sitting on top of the ground layer with a semi-transparent water texture. In the dungeon, use it for a small pond or puddle layer.

For a more convincing effect, extend the shader to output a `NORMAL_MAP` so the pond catches PointLight2D torchlight. Add a `uniform sampler2D normal_texture;` and set `NORMAL_MAP = texture(normal_texture, distorted_uv).rgb;` after the `COLOR` line. Without that output, PointLight2D treats the surface as flat regardless of any normal map on the texture.

### Sprite Normal Maps and 2D Lighting Interaction

This is where your graphic design skills create direct visual value. A normal map tells `PointLight2D` how to shade each pixel of a sprite — without one, lighting is flat. With one, stone walls have depth, wooden crates have grain, and characters have volume.

**Workflow:**

1. Select your Sprite2D
2. Change the **Texture** property to `New CanvasTexture`
3. In the CanvasTexture: set **Diffuse Texture** to your sprite PNG, **Normal Texture** to your normal map PNG
4. Place `PointLight2D` torches in the scene — they'll now shade the sprite using the normal map

**Generating normal maps:**

| Tool | Best For | Notes |
|---|---|---|
| Laigter (free) | Pixel art sprites | Drag and drop, real-time preview, exports normal + specular |
| SpriteIlluminator (paid) | Any 2D art | Fast, high quality, batch processing |
| Photoshop | Painted / HD art | Filter > 3D > Generate Normal Map |
| Hand-painted | Stylized pixel art | Full control, paint in any 3-channel PNG editor |

**Design note:** For pixel art, Laigter's results look excellent with minimal effort. For painted characters, Photoshop's normal map generator plus manual touch-up gives professional results. The CanvasTexture normal map slot is the same `Texture2D` type as everything else — import it with Filter = Nearest for pixel art.

### The Visual Shader Editor for canvas_item

The visual shader editor works for canvas_item shaders too. In the Shader editor, create a new `VisualShader` and set its mode to `CanvasItem`. All the same node categories are available (Texture, Math, Vector, Color, etc.) with the built-in `TEXTURE` node available automatically for canvas_item mode.

For a graphic designer who prefers visual workflows over code, this is often the faster path. The outline and dissolve shaders above can be recreated node-by-node in the visual editor.

### Try It: Stylize the Dungeon

With the dungeon from Modules 3 and 4:

1. Add the **outline shader** to the player `Sprite2D` — black outline at width 1.0
2. Add the **palette swap shader** to a goblin enemy sprite — create a second palette texture in a different hue for a variant
3. Add the **dissolve shader** to a destructible barrel — animate `dissolve_amount` from 0 to 1 when the barrel is destroyed
4. Add the **water shader** to a small pond Sprite2D placed over the ground tilemap
5. Add a **CanvasTexture** with a normal map to the wall tiles' Sprite2D — place a PointLight2D torch nearby and observe the depth

The dungeon should now look visually styled: outlined protagonist, color-variant enemies, dissolving destructibles, rippling water, depth-lit walls.

---

## API Quick Reference

### Built-In Shader Variables

**Vertex Function:**

| Variable | Type | R/W | Description |
|---|---|---|---|
| `VERTEX` | vec3 | R/W | Position in model space |
| `NORMAL` | vec3 | R/W | Normal in model space |
| `TANGENT` | vec3 | R/W | Tangent vector |
| `UV` | vec2 | R/W | Primary UVs |
| `UV2` | vec2 | R/W | Secondary UVs |
| `COLOR` | vec4 | R | Vertex color |
| `MODEL_MATRIX` | mat4 | R | Object-to-world |
| `VIEW_MATRIX` | mat4 | R | World-to-view |
| `PROJECTION_MATRIX` | mat4 | R | View-to-clip |
| `TIME` | float | R | Seconds elapsed |
| `POINT_SIZE` | float | W | Point primitive size |

**Fragment Function:**

| Variable | Type | R/W | Description |
|---|---|---|---|
| `ALBEDO` | vec3 | W | Base color |
| `ALPHA` | float | W | Transparency (0–1) |
| `METALLIC` | float | W | PBR metallic (0–1) |
| `ROUGHNESS` | float | W | PBR roughness (0–1) |
| `EMISSION` | vec3 | W | Additive emission color |
| `NORMAL_MAP` | vec3 | W | Tangent-space normal map |
| `NORMAL` | vec3 | R/W | View-space normal |
| `UV` | vec2 | R | Interpolated UV |
| `COLOR` | vec4 | R | Interpolated vertex color |
| `FRAGCOORD` | vec4 | R | Screen-space fragment coordinates |
| `SCREEN_UV` | vec2 | R | 0–1 screen coordinates |
| `VIEW` | vec3 | R | Direction to camera |
| `TIME` | float | R | Seconds elapsed |
| `DEPTH` | float | W | Depth buffer override |
| `ALPHA_SCISSOR_THRESHOLD` | float | W | Alpha cutout threshold |

**Light Function:**

| Variable | Type | R/W | Description |
|---|---|---|---|
| `LIGHT` | vec3 | R | Direction to light |
| `LIGHT_COLOR` | vec3 | R | Light color × intensity |
| `ATTENUATION` | float | R | Distance + shadow factor |
| `NORMAL` | vec3 | R | Surface normal |
| `VIEW` | vec3 | R | View direction |
| `DIFFUSE_LIGHT` | vec3 | R/W | Accumulated diffuse |
| `SPECULAR_LIGHT` | vec3 | R/W | Accumulated specular |

### Uniform Hint Annotations

| Hint | Effect |
|---|---|
| `hint_range(min, max)` | Slider in inspector |
| `hint_range(min, max, step)` | Slider with increment |
| `source_color` | sRGB→linear on color uniforms |
| `hint_default_white` | Default white texture |
| `hint_default_black` | Default black texture |
| `hint_normal` | Normal map (no gamma correction) |
| `hint_depth_texture` | Bind to scene depth buffer |
| `hint_screen_texture` | Bind to current screen |
| `hint_normal_roughness_texture` | Bind to normal+roughness buffer |
| `filter_nearest` | Nearest/pixelated filtering |
| `filter_linear` | Bilinear filtering |
| `filter_linear_mipmap` | Bilinear + mipmaps |
| `repeat_enable` | Texture wraps/tiles |
| `repeat_disable` | Texture clamps at edges |

### Math Functions Reference

| Function | Signature | Description |
|---|---|---|
| `mix` | `mix(a, b, t)` | Linear interpolation |
| `smoothstep` | `smoothstep(edge0, edge1, x)` | S-curve interpolation |
| `step` | `step(edge, x)` | Hard threshold (0 or 1) |
| `clamp` | `clamp(x, min, max)` | Restrict to range |
| `fract` | `fract(x)` | Fractional part |
| `floor` | `floor(x)` | Round down |
| `ceil` | `ceil(x)` | Round up |
| `abs` | `abs(x)` | Absolute value |
| `pow` | `pow(base, exp)` | Exponentiation |
| `sqrt` | `sqrt(x)` | Square root |
| `sin` / `cos` | `sin(x)` | Trigonometry (radians) |
| `atan` | `atan(y, x)` | Arc tangent (two-arg form) |
| `length` | `length(v)` | Vector magnitude |
| `normalize` | `normalize(v)` | Unit vector |
| `dot` | `dot(a, b)` | Dot product |
| `cross` | `cross(a, b)` | Cross product |
| `reflect` | `reflect(I, N)` | Reflection vector |
| `texture` | `texture(sampler, uv)` | Sample texture |
| `textureLod` | `textureLod(sampler, uv, lod)` | Sample at specific mip level |

---

## Common Pitfalls

### 1. WRONG: Manual lighting in fragment() without `render_mode unshaded` causes double lighting

The problem: you compute your own lighting in `fragment()`, but Godot's lighting system also runs, so lights are applied twice — your object appears overbright.

```glsl
// WRONG — double lighting
shader_type spatial;  // No render_mode

void fragment() {
    float ndotl = dot(NORMAL, normalize(vec3(1.0, -1.0, 0.0)));
    ALBEDO = vec3(0.8, 0.3, 0.2) * ndotl;  // Your lighting applied
    // Godot then applies its OWN lighting on top — double-lit!
}
```

```glsl
// RIGHT — use render_mode unshaded for fully manual lighting
shader_type spatial;
render_mode unshaded;  // Disable Godot's lighting

void fragment() {
    float ndotl = dot(NORMAL, normalize(vec3(1.0, -1.0, 0.0)));
    ALBEDO = vec3(0.8, 0.3, 0.2) * max(ndotl, 0.1);  // Your lighting, full control
}

// ALSO RIGHT — use light() to customize Godot's lighting
// (don't add manual lighting in fragment(), let light() handle it)
void light() {
    float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
    DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * ndotl;
}
```

### 2. WRONG: Normalizing NORMAL in vertex() expecting it to be normalized in fragment()

The problem: normals written to vertex output are interpolated across the triangle during rasterization. Interpolated vectors lose their unit length. Normalizing in `vertex()` doesn't help — the interpolated result in `fragment()` isn't normalized.

```glsl
// WRONG
void vertex() {
    NORMAL = normalize(NORMAL);  // This does nothing useful
}

void fragment() {
    // NORMAL here is interpolated and NOT normalized
    float ndotl = dot(NORMAL, LIGHT);  // Wrong length, wrong result
}
```

```glsl
// RIGHT — normalize in fragment() where it matters
void fragment() {
    vec3 normal = normalize(NORMAL);  // Now it's unit length
    float ndotl = dot(normal, LIGHT);
    ALBEDO = vec3(ndotl);
}
```

### 3. WRONG: Setting ALPHA without proper render_mode (z-sorting issues)

The problem: by default, transparent objects in Godot 4 require special handling for correct depth sorting. Writing to `ALPHA` without `blend_mix` (or another blend mode) produces artifacts — objects appear through each other incorrectly.

```glsl
// WRONG — alpha without blend mode
shader_type spatial;

void fragment() {
    ALBEDO = vec3(0.5, 0.8, 1.0);
    ALPHA = 0.5;  // Writes alpha but no blend mode specified — artifacts!
}
```

```glsl
// RIGHT — explicit blend mode
shader_type spatial;
render_mode blend_mix;  // or blend_add for additive effects

void fragment() {
    ALBEDO = vec3(0.5, 0.8, 1.0);
    ALPHA = 0.5;
}

// ALSO RIGHT for cutout (sharp edges, no blending) — better performance
shader_type spatial;
render_mode alpha_scissor;

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb;
    ALPHA = tex.a;
    ALPHA_SCISSOR_THRESHOLD = 0.5;
}
```

### 4. WRONG: Computing noise in fragment() per pixel — very expensive

The problem: procedural noise algorithms (value noise, Perlin noise, etc.) involve many math operations. Running them per-pixel in `fragment()` for every frame hammers the GPU.

```glsl
// WRONG — expensive procedural noise in fragment()
void fragment() {
    // Manually implementing value noise here with 20+ operations
    // Times 1920x1080 pixels = tens of millions of operations per frame
    float n = expensive_noise_function(UV * 5.0 + TIME);
    ALBEDO = vec3(n);
}
```

```glsl
// RIGHT — use a NoiseTexture2D, a texture lookup is a single GPU instruction
uniform sampler2D noise_tex : hint_default_white;

void fragment() {
    float n = texture(noise_tex, UV * 5.0 + TIME * 0.1).r;
    // One texture sample vs. 20+ math ops — massively faster
    ALBEDO = vec3(n);
}
```

GPU texture sampling uses dedicated hardware (texture units, TMUs) and is extremely fast — one texture sample is cheaper than a single division operation in many cases.

### 5. WRONG: Modifying VERTEX in fragment() — it's read-only there

The problem: `VERTEX` in `fragment()` is the interpolated vertex position (read-only). You can read it, but writing to it does nothing — geometry modification must happen in `vertex()`.

```glsl
// WRONG — VERTEX is read-only in fragment()
void fragment() {
    VERTEX.y += sin(TIME);  // Does nothing — silently ignored (or a compile error)
    ALBEDO = vec3(1.0, 0.0, 0.0);
}
```

```glsl
// RIGHT — geometry modification in vertex()
void vertex() {
    VERTEX.y += sin(VERTEX.x * 3.0 + TIME * 2.0) * 0.2;
}

void fragment() {
    ALBEDO = vec3(1.0, 0.0, 0.0);
    // Reading VERTEX here gives the position AFTER vertex() modification — that's fine
}
```

---

## Exercises

### Exercise 1: Shield Shader (30–45 minutes)

Build a "sci-fi shield" shader for a sphere. Requirements:

- Fresnel-based glow: bright at edges, transparent in center
- Animated hex/grid pattern overlay (procedural, no texture needed)
- An `impact_point` uniform (vec3 world position) that, when set, creates a ripple/distortion effect radiating outward from that point
- The ripple fades over time — animate the impact and fade from GDScript using a Tween

**Getting started:**

The hex pattern can be approximated with a UV-based grid. For the hex geometry:
```glsl
// Approximate hexagonal grid using offset rows
vec2 hex_uv = UV * 20.0;
hex_uv.x += step(1.0, mod(floor(hex_uv.y), 2.0)) * 0.5;  // Offset alternate rows
vec2 local = fract(hex_uv) - 0.5;
float hex_dist = max(abs(local.x), abs(local.y * 1.15 + local.x * 0.5));
float hex_line = step(0.45, hex_dist);  // Hex cell edge
```

For the impact ripple: compute distance from the fragment world position to `impact_point`, then use `sin()` at that distance with a fading amplitude to create a ripple wave. Animate `impact_time` with a Tween from 0→1 and multiply the ripple amplitude by `1.0 - impact_time` to fade out.

### Exercise 2: Water Shader (60–90 minutes)

Build a water surface for a flat `PlaneMesh`. Requirements:

- Two-layer animated normal map scrolling at different speeds and directions for realistic wave detail
- Semi-transparent with depth-based color: shallow areas are lighter/more transparent, deep areas are darker blue
- Foam at shallow edges (use `hint_depth_texture` to read scene depth and compare against fragment depth)
- Specular highlights from the sun using the modified normal

**Approach for depth-based color:**

```glsl
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

void fragment() {
    // Scene depth at this screen position
    float depth_raw = texture(depth_texture, SCREEN_UV).r;
    // Convert to linear depth
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw * 2.0 - 1.0);
    vec4 view_coords = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    float scene_depth = -view_coords.z / view_coords.w;

    // Current fragment depth
    float water_depth = -VERTEX.z;  // In view space (negative Z is forward)

    float depth_diff = scene_depth - water_depth;
    float shallow = 1.0 - clamp(depth_diff / 3.0, 0.0, 1.0);

    vec3 shallow_color = vec3(0.4, 0.9, 0.8);
    vec3 deep_color = vec3(0.0, 0.15, 0.4);
    ALBEDO = mix(deep_color, shallow_color, shallow);
    ALPHA = mix(0.9, 0.5, shallow);
}
```

For normal map scrolling:
```glsl
uniform sampler2D wave_normal_map : hint_normal;
uniform float wave_speed : hint_range(0.0, 2.0) = 0.5;

void fragment() {
    vec2 uv1 = UV + vec2(TIME * wave_speed * 0.4, TIME * wave_speed * 0.2);
    vec2 uv2 = UV * 1.5 + vec2(-TIME * wave_speed * 0.3, TIME * wave_speed * 0.5);
    vec3 n1 = texture(wave_normal_map, uv1).rgb * 2.0 - 1.0;
    vec3 n2 = texture(wave_normal_map, uv2).rgb * 2.0 - 1.0;
    NORMAL_MAP = normalize(n1 + n2) * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = 2.0;
}
```

### Exercise 3: Terrain Shader with Triplanar Mapping (90–120 minutes)

Build a terrain shader that blends three surface textures based on surface properties, with triplanar mapping to eliminate UV stretching.

Requirements:
- Three textures: grass (flat tops), rock (steep slopes), snow/dirt (high elevation)
- Blend between them based on `NORMAL.y` (slope) and `VERTEX.y` (height)
- Triplanar mapping: sample each texture three ways (XY, XZ, YZ planes) and blend by normal direction — eliminates UV stretching on cliffs
- Normal maps for all three textures

**Triplanar sampling function:**

```glsl
varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// In fragment():
vec3 triplanar(sampler2D tex, float scale) {
    // Blend weights from absolute normal
    vec3 blend = abs(world_normal);
    blend = max(blend - 0.2, 0.0);  // Sharper blending
    blend /= (blend.x + blend.y + blend.z + 0.001);

    vec3 x = texture(tex, world_pos.yz * scale).rgb;
    vec3 y = texture(tex, world_pos.xz * scale).rgb;
    vec3 z = texture(tex, world_pos.xy * scale).rgb;
    return x * blend.x + y * blend.y + z * blend.z;
}
```

**Blending between materials:**

```glsl
void fragment() {
    // Sample all three textures triplanarly
    vec3 grass = triplanar(grass_texture, 0.5);
    vec3 rock  = triplanar(rock_texture, 0.4);
    vec3 snow  = triplanar(snow_texture, 0.6);

    // Slope-based blend: flat (NORMAL.y near 1.0) → grass, steep → rock
    float slope = clamp(1.0 - world_normal.y, 0.0, 1.0);
    float rock_blend = smoothstep(0.3, 0.6, slope);

    // Height-based blend: high → snow
    float height = clamp((world_pos.y - snow_height_min) / snow_height_range, 0.0, 1.0);
    float snow_blend = smoothstep(0.3, 0.7, height) * (1.0 - rock_blend);

    // Combine
    vec3 terrain_color = grass;
    terrain_color = mix(terrain_color, rock, rock_blend);
    terrain_color = mix(terrain_color, snow, snow_blend);
    ALBEDO = terrain_color;
    ROUGHNESS = mix(mix(0.8, 0.7, rock_blend), 0.4, snow_blend);
}
```

---

## Key Takeaways

1. **Godot shading language is similar to GLSL but simpler** — use built-in names (`ALBEDO`, `NORMAL`, `VERTEX`) instead of declaring `in`/`out` qualifiers. The language compiles to GLSL internally.

2. **Three shader functions serve three purposes** — `vertex()` modifies geometry on the GPU (waves, wind, inflation), `fragment()` computes per-pixel color (toon, dissolve, holographic), `light()` customizes per-light contribution (quantized diffuse, custom specular).

3. **Uniforms connect GDScript to shaders** — declare them with hint annotations for inspector integration. Animate them with Tween or AnimationPlayer for dynamic effects. `set_shader_parameter()` is the bridge between game logic and GPU.

4. **Cel-shading is quantized lighting** — `floor(intensity * bands) / bands` snaps smooth lighting to discrete steps. `smoothstep()` with very close edges creates hard boundaries without pixel aliasing. Use `light()` for multi-light support.

5. **The inverted hull method creates outlines** — apply a second material as `next_pass`, use `render_mode cull_front` to show only back faces, push vertices outward in `vertex()`. Simple, efficient, widely used.

6. **Dissolve = noise texture + discard + edge glow** — sample noise, `discard` pixels below the threshold, add `EMISSION` near the boundary. Animate `dissolve_amount` with a Tween for appear/disappear transitions. Use `NoiseTexture2D` instead of computing noise per-pixel.

7. **Visual shaders and code shaders produce identical GPU output** — use whichever fits your workflow. Code is faster for math-heavy shaders; visual is better for artists, experimentation, and making data flow visible. You can use both in the same project.

---

## What's Next

Your shaders define the surface. In [Module 7: Post-Processing & VFX](module-07-post-processing-vfx.md), you'll define the atmosphere. Post-processing effects operate on the final rendered image: screen-space glow (bloom), color correction, depth of field, screen-space outlines, custom camera effects. You'll use Godot's `CompositorEffect` system to write full-screen shaders that transform the entire scene — your cell-shaded characters with the world-space distortion of a heat haze, your holographic UI with chromatic aberration, a horror scene that drains color as the player's health drops.

Everything you learned here transfers directly: the same Godot shading language, the same `SCREEN_UV` and depth texture tricks, the same approach of uniforms driven from GDScript. The only difference is scale — instead of affecting one mesh, you affect every pixel on screen.

---

[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
