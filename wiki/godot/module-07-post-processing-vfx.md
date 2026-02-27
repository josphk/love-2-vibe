# Module 7: Post-Processing & VFX

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 8–12 hours
**Prerequisites:** [Module 6: Shaders & Stylized Rendering](module-06-shaders-stylized-rendering.md)

---

## Overview

Module 6 gave you control over how individual surfaces look. This module gives you control over how the entire screen looks. Post-processing effects — bloom, fog, color grading, screen-space ambient occlusion — transform the mood of your scene without touching a single material. Combined with particle effects, they're what separate "tech demo" from "polished game."

Godot has two post-processing systems: the Environment resource (built-in effects like glow, SSAO, fog, tonemap) and compositor effects (Godot 4.3+, custom render passes for anything the built-in effects can't do). The particle system (GPUParticles3D) runs entirely on the GPU for massive particle counts. You'll also meet FogVolume nodes for localized atmospheric effects, SubViewport tricks for rendering-to-texture techniques, and the full particle shader language for when the built-in material isn't enough.

By the end of this module, you'll build a mood board scene — one 3D environment with four switchable visual presets that radically change the atmosphere just by swapping Environment resources and toggling effects. Cyberpunk, pastoral, horror, and retro — all from the same geometry, just different post-processing stacks.

---

## 1. The Environment Resource

Everything post-processing starts here. The **Environment** resource is a data object that controls the entire visual "atmosphere" of your scene — background, ambient light, tonemap, glow, fog, ambient occlusion, reflections, global illumination, and color corrections. It does not live on a node itself; instead, you assign it to a **WorldEnvironment** node.

### Setting Up a WorldEnvironment

Add a `WorldEnvironment` node to your scene root. You only need one `WorldEnvironment` per scene — multiple WorldEnvironment nodes will log a warning and only the topmost one in the scene tree takes effect. In the Inspector, click the `Environment` property and select "New Environment." This creates an inline Environment resource. To reuse the same environment in multiple scenes (essential for the mood board project), save it as a `.tres` file: click the resource dropdown, then "Save."

```
Scene tree:
├── WorldEnvironment
│   └── [Environment resource assigned here]
├── Camera3D
├── DirectionalLight3D
└── ...your scene content
```

A `Camera3D` can also have its own `Environment` assigned — this overrides the WorldEnvironment for that camera. Useful for split-screen or picture-in-picture cameras.

### Property Groups

The Environment inspector is divided into sections. Here's a map of everything:

### Sky Resources

When `bg_mode` is `Sky`, you need a `Sky` resource with a `SkyMaterial`. Godot ships three sky materials:

- **ProceduralSkyMaterial**: generates a sky from parameters — sun position (driven by a DirectionalLight3D with `sky_mode = Sun`), sky top/horizon/bottom colors, sun color, sun angle size, and ground color. Fast and flexible for outdoor scenes.
- **PhysicalSkyMaterial**: physically-based Rayleigh and Mie scattering. Handles atmosphere, sun disk, and air density. More realistic but more parameters to tune.
- **PanoramaSkyMaterial**: uses an HDR equirectangular image as the sky. Great for accurate reflections and environment lighting from real-world captures. Grab `.hdr` files from sites like Poly Haven.

```gdscript
# Create a procedural sky at runtime
func create_procedural_sky() -> Environment:
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY

    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.18, 0.36, 0.72)       # Deep blue zenith
    sky_mat.sky_horizon_color = Color(0.75, 0.85, 0.95)   # Light blue horizon
    sky_mat.ground_bottom_color = Color(0.12, 0.10, 0.08) # Dark earth
    sky_mat.ground_horizon_color = Color(0.64, 0.60, 0.52) # Dusty ground horizon
    sky_mat.sun_angle_max = 30.0                            # Sun disk size influence
    sky_mat.sun_curve = 0.15                                # Sun glow falloff

    var sky := Sky.new()
    sky.sky_material = sky_mat
    env.sky = sky

    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_sky_contribution = 0.75
    return env
```

**Background**

Controls what renders behind all geometry.

| Setting | Values | Notes |
|---|---|---|
| `bg_mode` | Sky, Color, Canvas, Custom | Sky requires a Sky resource |
| `bg_color` | Color | Only used when bg_mode = Color |
| `bg_energy_multiplier` | float | Multiplies background brightness |
| `sky` | Sky resource | Sky + SkyMaterial (PhysicalSkyMaterial, ProceduralSkyMaterial, etc.) |
| `sky_rotation` | Vector3 | Rotates the sky independently of the scene |
| `canvas_max_layer` | int | When bg_mode = Canvas, renders 2D layers up to this value behind 3D |

**Ambient Light**

Controls the base light that hits all surfaces regardless of light sources.

| Setting | Values | Notes |
|---|---|---|
| `ambient_light_source` | Disabled, Color, Sky, BG | Sky samples the sky hemisphere for ambient |
| `ambient_light_color` | Color | Only used when source = Color |
| `ambient_light_energy` | float | Multiplier; 1.0 is default |
| `ambient_light_sky_contribution` | 0.0–1.0 | How much sky contributes vs. solid color |

### Tonemap Modes

Tonemapping converts HDR (high dynamic range) values to the LDR (low dynamic range) values your screen can display. This is one of the most impactful settings for overall visual character.

| Mode | Look | Use Case |
|---|---|---|
| `Linear` | Flat, no curve. Brights clip to white. | Technical/debug. Not for final art. |
| `Reinhard` | Soft roll-off, colors desaturate at high brightness. | Classic. Good for realistic scenes. |
| `Filmic` | Stronger contrast, warm shadows. More cinematic. | Realistic games wanting a "film" feel. |
| `ACES` | High contrast, rich color, Hollywood-grade curve. | AAA style. Slightly aggressive. |

```gdscript
# Switching tonemap mode at runtime
func set_tonemap_mode(env: Environment, mode: Environment.ToneMapper) -> void:
    env.tonemap_mode = mode
    # mode options:
    # Environment.TONE_MAPPER_LINEAR
    # Environment.TONE_MAPPER_REINHARDT
    # Environment.TONE_MAPPER_FILMIC
    # Environment.TONE_MAPPER_ACES
```

Two additional tonemap controls matter a lot:

- `tonemap_exposure`: overall brightness multiplier before tonemapping. Think of it like a camera aperture. 1.0 is default.
- `tonemap_white`: the white point. Values above this will be pure white after tonemapping. Useful with Reinhard.

### Saving and Swapping Environments

The whole premise of the mood board scene is swapping Environment resources at runtime. Always save each environment to its own `.tres` file, then load and assign:

```gdscript
var environments: Dictionary = {
    "cyberpunk": preload("res://environments/cyberpunk.tres"),
    "pastoral":  preload("res://environments/pastoral.tres"),
    "horror":    preload("res://environments/horror.tres"),
    "retro":     preload("res://environments/retro.tres"),
}

@onready var world_env: WorldEnvironment = $WorldEnvironment

func switch_preset(name: String) -> void:
    if name in environments:
        world_env.environment = environments[name]
```

One line. Instant full-scene mood change. That's the power of Environment resources.

---

## 2. Glow / Bloom

Glow (called "bloom" in most other engines) makes bright things bleed light into the surrounding area. It simulates the way camera lenses and eyes scatter intense light sources. Used well, it communicates heat, magic, neon, and energy. Used badly, it makes your scene look like someone smeared vaseline on the lens.

### Enabling and Configuring

In the Environment resource, expand the **Glow** section:

| Property | Type | Description |
|---|---|---|
| `glow_enabled` | bool | Master toggle |
| `glow_intensity` | float | Overall glow intensity. Start at 0.8, not 5.0. |
| `glow_strength` | float | Blur strength of the glow. Higher = softer spread. |
| `glow_bloom` | float | Amount of "base" bloom on all pixels (regardless of threshold). Keep low. |
| `glow_blend_mode` | enum | How glow composites onto the image |
| `glow_hdr_threshold` | float | Only pixels brighter than this value produce glow |
| `glow_hdr_scale` | float | Scales the HDR luminance before threshold check |
| `glow_map` | Texture | A texture that spatially controls glow intensity |
| `glow_map_strength` | float | How much the glow map overrides default behavior |

**Blend modes:**

| Mode | Effect |
|---|---|
| `Additive` | Glow adds to the image. Brightest result. Good for sci-fi/neon. |
| `Screen` | Softer than additive, never goes above 1.0. Good for natural scenes. |
| `Softlight` | Very subtle. Good for realistic outdoor scenes. |
| `Replace` | Replaces the image with just glow. Mostly for special effects. |

**Glow levels:**

The glow is calculated as a weighted sum of 7 mip-map blur passes. Each level adds larger, softer glow rings. Toggle them in the `glow_levels/1` through `glow_levels/7` booleans. Level 1 is tight, level 7 is huge. Enabling multiple levels gives a layered "corona" effect. A good starting point for neon is levels 1+2+3 enabled. For a soft dreamy bloom, enable 4+5+6.

### Making Objects Glow

For glow to appear on an object, that object's material needs to output brightness above the `glow_hdr_threshold`. The threshold is in HDR units — values above 1.0 (or whatever you set) trigger glow.

**With StandardMaterial3D:**

1. Enable `Emission` in the material.
2. Set `Emission Energy Multiplier` above 1.0 (try 2.0–5.0 for neon).
3. Set `Emission` color to whatever color you want the glow to be.

```gdscript
# Make a MeshInstance3D glow at runtime
func make_glow(mesh_instance: MeshInstance3D, color: Color, energy: float) -> void:
    var mat := StandardMaterial3D.new()
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = energy  # > 1.0 to trigger bloom
    mesh_instance.material_override = mat
```

**With a custom shader:**

In your fragment shader, output to `EMISSION` with a value greater than `vec3(1.0)`:

```glsl
void fragment() {
    ALBEDO = vec3(0.0);  // No base color (it's all emission)
    EMISSION = vec3(0.0, 2.5, 5.0);  // Bright cyan, will bloom
}
```

### Toggling Glow at Runtime

```gdscript
@onready var world_env: WorldEnvironment = $WorldEnvironment

func set_glow(enabled: bool, intensity: float = 1.0) -> void:
    var env := world_env.environment
    env.glow_enabled = enabled
    env.glow_intensity = intensity

func pulse_glow(base_intensity: float) -> void:
    # Call this from _process to make glow pulse
    var t := Time.get_ticks_msec() / 1000.0
    var env := world_env.environment
    env.glow_intensity = base_intensity + sin(t * 4.0) * 0.3
```

A common mistake: setting `glow_intensity` to 5.0 and wondering why everything looks overexposed. The glow intensity multiplies the already-bright pixels. Start at 0.5–1.0. Use `glow_hdr_threshold` (usually 1.0) to control which things glow, not the intensity slider.

---

## 3. Fog

Godot 4 has three different fog systems, each with different characteristics and use cases.

### Depth Fog

A linear fade from a start distance to an end distance. Pixels between those distances blend toward the fog color based on depth. Good for hiding pop-in at the edge of your draw distance, or creating a simple hazy atmosphere.

Enable under **Fog** in the Environment resource:

| Property | Description |
|---|---|
| `fog_enabled` | Master toggle |
| `fog_light_color` | The fog color |
| `fog_light_energy` | Fog brightness multiplier |
| `fog_sun_scatter` | How much light from the sun scatters into fog (forward scattering) |
| `fog_density` | Overall fog density. Very sensitive — start at 0.001–0.01 |
| `fog_aerial_perspective` | Blends distant geometry toward sky color. Useful for outdoor scenes. |
| `fog_sky_affect` | How much fog affects the sky (0 = only affects geometry) |

### Height Fog

Fog density that changes based on Y position — denser at low Y, thinner at high Y. Models ground-level mist, swamp atmosphere, or sea-level haze.

| Property | Description |
|---|---|
| `fog_height` | Y coordinate of the fog band center |
| `fog_height_density` | How dense the height fog layer is |

Combine depth fog and height fog: set `fog_density` for global haze, then add `fog_height_density` for extra ground mist.

### Volumetric Fog

Volumetric fog is 3D fog that scatters light. It's computed in a 3D texture (a froxel grid) and actually responds to lights in the scene. Torches cast shafts of light into the fog. The sun creates god rays. It's far more atmospheric than depth or height fog, and more expensive.

Enable in the **Volumetric Fog** section:

| Property | Description |
|---|---|
| `volumetric_fog_enabled` | Master toggle |
| `volumetric_fog_density` | Base fog density. Start at 0.01–0.05 |
| `volumetric_fog_albedo` | Fog color |
| `volumetric_fog_emission` | Fog self-illumination color |
| `volumetric_fog_emission_energy` | Emission multiplier |
| `volumetric_fog_anisotropy` | Forward/backward scattering. 0 = isotropic, 1 = full forward scatter (brighter looking at light) |
| `volumetric_fog_length` | How far from the camera the volume extends |
| `volumetric_fog_detail_spread` | Higher = more variation in density |
| `volumetric_fog_gi_inject` | How much GI affects the volumetric fog |
| `volumetric_fog_temporal_reprojection_enabled` | Smooths the fog across frames. Reduces flickering. Keep enabled. |
| `volumetric_fog_temporal_reprojection_amount` | Amount of temporal blending (0–1) |

Critical note: volumetric fog only appears if lights in your scene have their `volumetric_fog_energy` property set above 0. Check your `DirectionalLight3D` or `OmniLight3D` properties — there's a "Volumetric Fog Energy" slider under each light. Set it to 1.0 or higher to make the light interact with volumetric fog.

```gdscript
# Enable volumetric fog on a light at runtime
func enable_volumetric_light(light: Light3D, energy: float = 1.0) -> void:
    light.light_volumetric_fog_energy = energy
```

### FogVolume Nodes

A `FogVolume` node places a localized fog region anywhere in your scene. It uses a `FogMaterial` (or a custom fog shader) to define its appearance. This is separate from Environment fog — FogVolumes work with volumetric fog enabled.

Shapes available: Ellipsoid, Cone, Cylinder, Box, World (affects the entire scene).

```gdscript
# Create a localized fog area (swamp, cave entrance, etc.)
func create_fog_zone(position: Vector3) -> FogVolume:
    var fog_volume := FogVolume.new()
    fog_volume.position = position
    fog_volume.size = Vector3(10, 3, 10)

    var mat := FogMaterial.new()
    mat.density = 0.5
    mat.albedo = Color(0.3, 0.35, 0.4)  # cool gray-green
    mat.height_falloff = 2.0            # thins out toward top of volume
    mat.edge_fade = 0.1                 # soft edges

    fog_volume.material = mat
    add_child(fog_volume)
    return fog_volume
```

Custom fog shaders use `shader_type fog;` and output `DENSITY`, `ALBEDO`, `EMISSION`, and `ANISOTROPY`. They're powerful for fog effects that animate, react to game state, or have non-uniform density patterns.

```gdscript
# Animated fog zone with shader
var fog_shader_code := """
shader_type fog;

uniform float speed : hint_range(0.0, 2.0) = 0.3;

void fog() {
    float noise = sin(WORLD_POSITION.x * 0.5 + TIME * speed)
                * cos(WORLD_POSITION.z * 0.5 + TIME * speed * 0.7);
    DENSITY = clamp(0.3 + noise * 0.2, 0.0, 1.0);
    ALBEDO = vec3(0.3, 0.35, 0.4);
}
"""

func create_animated_fog() -> FogVolume:
    var fv := FogVolume.new()
    fv.size = Vector3(20, 4, 20)
    var mat := FogMaterial.new()
    var shader := Shader.new()
    shader.code = fog_shader_code
    mat.density_texture = null  # Using shader instead
    fv.material = mat
    add_child(fv)
    return fv
```

---

## 4. SSAO, SSR, SSIL, and SDFGI

These are the global illumination and reflections systems. They range from cheap screen-space approximations to sophisticated real-time GI. Understanding when to use each — and what the performance cost is — determines whether your game runs at 60 fps or 6 fps.

### SSAO — Screen-Space Ambient Occlusion

SSAO darkens areas where geometry comes close together: crevices, corners, contact shadows, under furniture. It adds massive perceptual depth to scenes for relatively low cost. Without it, objects look like they're floating. With it, they look grounded.

Enable in the **SSAO** section:

| Property | Description |
|---|---|
| `ssao_enabled` | Master toggle |
| `ssao_radius` | World-space radius to sample for occlusion. Larger = bigger soft shadows. |
| `ssao_intensity` | Multiplier on the occlusion effect. |
| `ssao_power` | Gamma correction on the result. Higher = darker creases. |
| `ssao_detail` | Extra detail pass at smaller radius. Expensive. |
| `ssao_horizon` | Reduces occlusion on flat surfaces (self-occlusion artifact reduction). |
| `ssao_sharpness` | Edge sharpness. Higher = crispy. |
| `ssao_light_affect` | How much SSAO affects lit areas (usually keep at 0.0 for realism). |
| `ssao_ao_channel_affect` | How much SSAO uses material AO channel. |

SSAO only sees what's on screen. Walk close to a wall, and the occlusion on the far side of the room disappears. This is the screen-space limitation. For large indoor scenes, VoxelGI handles this better.

### SSR — Screen-Space Reflections

SSR makes glossy surfaces reflect the rest of the scene. It ray-marches through the depth buffer to find what should be reflected. The reflection is limited to what's currently on screen — objects off-screen simply don't get reflected.

Enable in the **SSR** section:

| Property | Description |
|---|---|
| `ssr_enabled` | Master toggle |
| `ssr_max_steps` | Ray march steps. Higher = catches more reflections, more expensive. 64 is good. |
| `ssr_fade_in` | Distance from camera where SSR fades in |
| `ssr_fade_out` | Distance from camera where SSR fades out |
| `ssr_depth_tolerance` | Depth buffer tolerance. Reduce to fix "ghosting" artifacts. |

Materials need low roughness to show SSR clearly. Set `roughness` to 0.0–0.2 on a StandardMaterial3D for a mirror-like surface.

### SSIL — Screen-Space Indirect Lighting

SSIL approximates the light that bounces between nearby surfaces. A red wall next to a white floor will make the floor look slightly pink. Like SSAO, it's screen-space only, but it adds significant realism to indoor scenes.

| Property | Description |
|---|---|
| `ssil_enabled` | Master toggle |
| `ssil_radius` | World-space radius for indirect light gathering |
| `ssil_intensity` | Strength of indirect light contribution |
| `ssil_sharpness` | Edge sharpness |
| `ssil_normal_rejection` | Reduce contributions from surfaces facing away from the receiver |

SSIL is heavier than SSAO. Use it only if you need color bleeding and can afford the cost.

### SDFGI — Signed Distance Field Global Illumination

SDFGI is Godot's real-time global illumination system for large scenes. It builds a signed distance field representation of the scene and uses it to trace indirect light. Unlike baked GI, it works with dynamic scenes — objects can move, lights can change.

| Property | Description |
|---|---|
| `sdfgi_enabled` | Master toggle |
| `sdfgi_use_occlusion` | SDFGI-based ambient occlusion (heavier) |
| `sdfgi_bounce_feedback` | Light bounce energy. Higher = brighter indirect. |
| `sdfgi_cascades` | Number of cascades (detail levels). 4–8. |
| `sdfgi_min_cell_size` | Size of the smallest SDF cell near camera. Smaller = more detail, more memory. |
| `sdfgi_energy` | Overall GI brightness multiplier |
| `sdfgi_normal_bias` | Surface bias to reduce self-illumination artifacts |
| `sdfgi_probe_bias` | Probe-based bias |
| `sdfgi_read_sky_light` | Whether the sky contributes to GI |

SDFGI works best for outdoor scenes or large indoor spaces. It needs time to "settle" — the GI propagates over several frames. Enable `sdfgi_enabled` and wait a second to see the result stabilize.

### VoxelGI — Baked-ish GI for Indoor Scenes

`VoxelGI` is a node (not an Environment setting) that provides baked-style indirect illumination for indoor scenes. It voxelizes the geometry inside its box, bakes lighting, and then updates dynamically.

Setup:
1. Add a `VoxelGI` node to your scene.
2. Scale it to cover your play area.
3. Set `subdiv` (the voxel resolution — higher takes longer to bake and uses more memory).
4. Click **Bake** in the toolbar (or call `VoxelGIData.allocate()` from script).
5. Dynamic objects (players, enemies) get GI from the probe without rebaking.

VoxelGI is heavier than SDFGI but gives higher-quality results in tight indoor spaces with many small surfaces.

```gdscript
# Trigger a VoxelGI rebake at runtime (e.g., after level loads)
@onready var voxel_gi: VoxelGI = $VoxelGI

func bake_lighting() -> void:
    # This takes a moment — call it during a loading screen or level transition
    voxel_gi.bake()
    # The result is stored in voxel_gi.data (a VoxelGIData resource)
    # You can save it: ResourceSaver.save(voxel_gi.data, "res://levels/room_gi.res")
    # And restore it: voxel_gi.data = load("res://levels/room_gi.res")
```

A common workflow: bake VoxelGI in the editor for static geometry, save the baked data as a `.res` file, and load it at runtime. For completely dynamic scenes (procedural level generation), bake at runtime after the level is built.

### Performance Cost Table

| Effect | Relative Cost | Notes |
|---|---|---|
| SSAO | Low–Medium | Almost always worth enabling |
| SSIL | Medium | Use selectively |
| SSR | Medium | Only on key reflective surfaces |
| Volumetric Fog | Medium–High | Scale froxel resolution to manage cost |
| SDFGI | High | Great for outdoor. One-time settle cost. |
| VoxelGI | High (bake) / Low (runtime) | Indoor scenes. Bake offline. |
| Compositor effects | Varies | Depends on your shader |

Use the Godot profiler (Debugger → Profiler) to see per-frame costs. SDFGI and VoxelGI in particular have variable costs depending on camera movement.

---

## 5. Color Adjustments and LUTs

Color adjustments are the final pass before the image hits your screen. They live in the **Adjustments** section of the Environment resource.

### Built-in Adjustments

| Property | Range | Effect |
|---|---|---|
| `adjustment_enabled` | bool | Master toggle for adjustments |
| `adjustment_brightness` | 0.0–2.0 | Overall luminance. 1.0 = unchanged. |
| `adjustment_contrast` | 0.0–2.0 | Contrast. Values above 1 crush blacks and push whites. |
| `adjustment_saturation` | 0.0–2.0 | Color saturation. 0.0 = grayscale. 2.0 = oversaturated. |
| `adjustment_color_correction` | Texture | LUT (look-up table) texture for custom color grading |

These three sliders can create dramatically different looks quickly. Some recipes:

**Horror:**
```
brightness: 0.85
contrast: 1.3
saturation: 0.2
```
Result: dark, drained of color, high contrast. Classic horror palette.

**Warm Pastoral:**
```
brightness: 1.05
contrast: 0.9
saturation: 1.2
```
Result: bright, soft, slightly oversaturated. Golden hour feeling.

**Cyberpunk:**
```
brightness: 0.95
contrast: 1.4
saturation: 1.8
```
Result: punchy colors, deep blacks, vivid highlights. Combine with neon emission materials.

**Vintage/Washed Out:**
```
brightness: 1.1
contrast: 0.7
saturation: 0.6
```
Result: lifted blacks, muted colors, faded film look.

### LUT Color Correction

A LUT (Lookup Table) is a 3D color remapping texture. Every input RGB value maps to an output RGB value through the texture. This lets you apply any color grade you can describe — including the kind of film emulation that takes colorists days to tune in feature films.

Godot accepts LUTs as a special format: a 16x16x16 color cube unwrapped into a 256x16 horizontal strip (or 16x256 vertical). The texture must be set to **repeat: disabled** and **filter: linear** in its import settings.

You can create LUTs in:
- **DaVinci Resolve**: export as .cube, then convert to a PNG strip
- **Photoshop/GIMP**: apply adjustments to a neutral LUT template image
- **Online tools**: search "Godot 4 LUT generator"

```gdscript
# Apply a LUT
func apply_lut(env: Environment, lut_texture: Texture2D) -> void:
    env.adjustment_enabled = true
    env.adjustment_color_correction = lut_texture
```

For the cyberpunk preset: a cool shadows + warm highlights LUT (also called "split toning") is far more accurate than the saturation slider alone. The slider shifts all colors equally; a LUT can make shadows blue and highlights orange, which is what makes that look so distinctive.

### Tweening Color Adjustments for Mood Transitions

Rather than instantly switching between presets, tween the color adjustment properties for cinematic mood transitions:

```gdscript
# Smooth transition between two sets of color adjustment values
func tween_to_preset(env: Environment, target: Dictionary, duration: float) -> void:
    var tween := create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)

    if "brightness" in target:
        tween.tween_property(env, "adjustment_brightness", target.brightness, duration)
    if "contrast" in target:
        tween.tween_property(env, "adjustment_contrast", target.contrast, duration)
    if "saturation" in target:
        tween.tween_property(env, "adjustment_saturation", target.saturation, duration)
    if "glow_intensity" in target:
        tween.tween_property(env, "glow_intensity", target.glow_intensity, duration)
    if "fog_density" in target:
        tween.tween_property(env, "fog_density", target.fog_density, duration)

# Example usage: transition from pastoral to horror over 3 seconds
func transition_to_horror() -> void:
    var horror_params := {
        "brightness": 0.85,
        "contrast": 1.3,
        "saturation": 0.2,
        "glow_intensity": 0.4,
        "fog_density": 0.025,
    }
    tween_to_preset(world_env.environment, horror_params, 3.0)
```

Note that you can't tween a full Environment swap (the resource reference either is or isn't the new one). The pattern here is to keep a single Environment resource and tween its properties, rather than swapping between separate resources. For the mood board project: use swapping for instant hard cuts (keypress), and property tweening for slow cinematic transitions (narrative moments, time-of-day changes).

---

## 6. GPUParticles3D

Godot's GPU-accelerated particle system runs entirely on the GPU via compute shaders. This means thousands of particles with almost no CPU overhead. The node is `GPUParticles3D` and it works with a `ParticleProcessMaterial` (or a custom particle shader) to define particle behavior.

### Node Setup

Add a `GPUParticles3D` node. Key top-level properties:

| Property | Description |
|---|---|
| `emitting` | Whether particles are currently being emitted |
| `amount` | Number of particles. GPU handles thousands easily. |
| `lifetime` | How long each particle lives (seconds) |
| `one_shot` | If true, emits once and stops (for bursts) |
| `preprocess` | Pre-simulates this many seconds on spawn (avoids empty initial state) |
| `speed_scale` | Multiplier on all particle speeds |
| `explosiveness` | 0 = spread over time, 1 = all emit at once |
| `randomness` | Adds randomness to emission timing |
| `fixed_fps` | Lock particle update to specific framerate (reduce for stylized look) |
| `draw_pass_1–4` | Mesh to render for each particle (usually QuadMesh or a small 3D mesh) |
| `process_material` | The ParticleProcessMaterial or ShaderMaterial |

### ParticleProcessMaterial Properties

`ParticleProcessMaterial` is a resource that defines everything about how particles move and look over their lifetime.

**Emission:**

| Property | Description |
|---|---|
| `emission_shape` | Point, Sphere, SphereOrSurface, Box, Ring, MeshSurface |
| `emission_sphere_radius` | Radius when shape = Sphere |
| `emission_box_extents` | Half-extents when shape = Box |
| `emission_ring_radius` | Ring radius |
| `emission_ring_height` | Ring height |
| `emission_ring_axis` | Axis the ring faces |

**Velocity:**

| Property | Description |
|---|---|
| `direction` | Initial velocity direction (Vector3) |
| `spread` | Cone spread angle in degrees. 180 = full sphere. |
| `flatness` | Flatten the spread toward a plane |
| `initial_velocity_min/max` | Speed range at spawn |
| `angular_velocity_min/max` | Rotation speed |

**Motion:**

| Property | Description |
|---|---|
| `gravity` | Gravity vector applied to particles |
| `linear_accel_min/max` | Linear acceleration along direction |
| `radial_accel_min/max` | Acceleration toward/away from emission origin |
| `tangential_accel_min/max` | Acceleration perpendicular to radial |
| `damping_min/max` | How quickly particles slow down |

**Scale:**

| Property | Description |
|---|---|
| `scale_min/max` | Size range at spawn |
| `scale_curve` | CurveTexture that scales over lifetime |

**Color:**

| Property | Description |
|---|---|
| `color` | Base color tint |
| `color_ramp` | GradientTexture1D — color over lifetime (0 = birth, 1 = death) |
| `color_initial_ramp` | GradientTexture1D — randomize spawn color from this range |

### Fire, Smoke, Sparks, and Magic — Complete Setups

**Fire:**

```gdscript
func create_fire() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.amount = 200
    particles.lifetime = 1.5
    particles.preprocess = 1.0  # Start looking full immediately

    var mat := ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    mat.emission_sphere_radius = 0.2
    mat.direction = Vector3(0, 1, 0)
    mat.spread = 15.0
    mat.initial_velocity_min = 1.0
    mat.initial_velocity_max = 3.0
    mat.gravity = Vector3(0, 0, 0)  # No gravity — fire rises
    mat.damping_min = 1.0
    mat.damping_max = 2.0
    mat.scale_min = 0.5
    mat.scale_max = 1.5

    # Color ramp: bright yellow → orange → red → transparent
    var gradient := GradientTexture1D.new()
    var g := Gradient.new()
    g.set_color(0, Color(1, 1, 0.8, 1))     # bright yellow-white
    g.add_point(0.3, Color(1, 0.6, 0, 1))    # orange
    g.add_point(0.7, Color(1, 0.2, 0, 0.5))  # red, fading
    g.set_color(1, Color(0.3, 0, 0, 0))      # dark red, transparent
    gradient.gradient = g
    mat.color_ramp = gradient

    particles.process_material = mat

    # Use a quad billboard
    var quad := QuadMesh.new()
    quad.size = Vector2(0.5, 0.5)
    particles.draw_pass_1 = quad

    return particles
```

**Smoke:**

```gdscript
func create_smoke() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.amount = 80
    particles.lifetime = 4.0
    particles.preprocess = 2.0

    var mat := ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    mat.emission_sphere_radius = 0.3
    mat.direction = Vector3(0, 1, 0)
    mat.spread = 30.0
    mat.initial_velocity_min = 0.3
    mat.initial_velocity_max = 0.8
    mat.gravity = Vector3(0, 0.5, 0)  # Slight upward drift
    mat.damping_min = 0.2
    mat.damping_max = 0.5
    mat.scale_min = 0.5
    mat.scale_max = 2.0

    # Scale curve: grow as it rises
    var scale_curve := CurveTexture.new()
    var curve := Curve.new()
    curve.add_point(Vector2(0, 0.3))
    curve.add_point(Vector2(0.5, 1.0))
    curve.add_point(Vector2(1, 1.5))
    scale_curve.curve = curve
    mat.scale_curve = scale_curve

    # Color ramp: dark gray → medium gray → transparent
    var gradient := GradientTexture1D.new()
    var g := Gradient.new()
    g.set_color(0, Color(0.2, 0.2, 0.2, 0.8))
    g.add_point(0.5, Color(0.4, 0.4, 0.4, 0.4))
    g.set_color(1, Color(0.6, 0.6, 0.6, 0.0))
    gradient.gradient = g
    mat.color_ramp = gradient

    particles.process_material = mat
    var quad := QuadMesh.new()
    quad.size = Vector2(1.0, 1.0)
    particles.draw_pass_1 = quad

    return particles
```

**Sparks / Embers:**

```gdscript
func create_sparks() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.amount = 150
    particles.lifetime = 2.0
    particles.explosiveness = 0.0  # Continuous stream

    var mat := ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
    mat.direction = Vector3(0, 1, 0)
    mat.spread = 90.0  # Wide spread
    mat.initial_velocity_min = 2.0
    mat.initial_velocity_max = 6.0
    mat.gravity = Vector3(0, -9.8, 0)  # Real gravity — sparks arc up then fall
    mat.damping_min = 0.5
    mat.damping_max = 1.5
    mat.scale_min = 0.05
    mat.scale_max = 0.15

    # Color ramp: bright white → yellow → orange → transparent
    var gradient := GradientTexture1D.new()
    var g := Gradient.new()
    g.set_color(0, Color(1.5, 1.5, 1.0, 1))   # Overbright white (blooms)
    g.add_point(0.3, Color(1.5, 0.8, 0.0, 1)) # Yellow (blooms)
    g.add_point(0.7, Color(1.0, 0.3, 0.0, 1)) # Orange
    g.set_color(1, Color(0.5, 0.0, 0.0, 0))   # Fade out
    gradient.gradient = g
    mat.color_ramp = gradient

    particles.process_material = mat
    # Sparks can be tiny quads or even SphereMesh
    var sphere := SphereMesh.new()
    sphere.radius = 0.02
    sphere.height = 0.04
    particles.draw_pass_1 = sphere

    return particles
```

**Magic Trail:**

```gdscript
func create_magic_trail() -> GPUParticles3D:
    var particles := GPUParticles3D.new()
    particles.amount = 300
    particles.lifetime = 0.8
    particles.speed_scale = 1.0

    var mat := ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
    mat.emission_ring_radius = 0.1
    mat.emission_ring_height = 0.05
    mat.emission_ring_axis = Vector3(0, 1, 0)
    mat.direction = Vector3(0, 1, 0)
    mat.spread = 60.0
    mat.initial_velocity_min = 0.5
    mat.initial_velocity_max = 2.0
    mat.gravity = Vector3(0, 0.3, 0)  # Slight upward drift
    mat.radial_accel_min = -0.5  # Pull toward center
    mat.radial_accel_max = 0.0
    mat.scale_min = 0.05
    mat.scale_max = 0.2

    # Color ramp: bright blue-white → purple → transparent
    var gradient := GradientTexture1D.new()
    var g := Gradient.new()
    g.set_color(0, Color(0.8, 0.9, 2.0, 1))    # Overbright blue-white
    g.add_point(0.4, Color(0.6, 0.2, 1.5, 0.8)) # Purple
    g.set_color(1, Color(0.2, 0.0, 0.5, 0))     # Deep purple, transparent
    gradient.gradient = g
    mat.color_ramp = gradient

    particles.process_material = mat
    var quad := QuadMesh.new()
    quad.size = Vector2(0.15, 0.15)
    particles.draw_pass_1 = quad

    return particles
```

---

## 7. Particle Shaders

When `ParticleProcessMaterial` isn't flexible enough — you need custom motion equations, interaction with uniforms from game code, or effects that can't be expressed through the material's property set — write a custom particle shader.

### shader_type particles

Particle shaders use `shader_type particles;` and have two entry points: `start()` and `process()`.

```glsl
shader_type particles;

uniform float spread : hint_range(0.0, 1.0) = 0.5;
uniform float speed : hint_range(0.0, 10.0) = 3.0;
uniform vec4 start_color : source_color = vec4(1.0);
uniform vec4 end_color : source_color = vec4(1.0, 0.5, 0.0, 0.0);

void start() {
    // Called exactly ONCE when a particle spawns.
    // This is where you set initial velocity, position, color.

    // INDEX = particle index (0 to AMOUNT-1)
    // AMOUNT = total particle count
    float angle = float(INDEX) / float(AMOUNT) * TAU;
    float radius = spread;

    // Distribute particles around a ring
    VELOCITY = vec3(cos(angle) * radius, 1.0, sin(angle) * radius) * speed;

    // Color at birth based on position in the ring
    COLOR = mix(start_color, vec4(cos(angle) * 0.5 + 0.5,
                                  sin(angle) * 0.5 + 0.5,
                                  0.5, 1.0), 0.5);

    // TRANSFORM sets particle position/orientation
    TRANSFORM = mat4(1.0);  // Identity = spawn at emitter position
}

void process() {
    // Called EVERY FRAME per particle while it's alive.
    // VELOCITY, TRANSFORM, COLOR are carried over from last frame.
    // DELTA = frame delta time (seconds)
    // TIME = elapsed time since scene start
    // CUSTOM.y / LIFETIME = normalized lifetime (0.0 = birth, 1.0 = death)

    float t = CUSTOM.y / LIFETIME;

    // Apply gravity manually
    VELOCITY.y -= 9.8 * DELTA;

    // Fade out over lifetime
    COLOR.a = 1.0 - t;

    // Shrink over lifetime
    float scale = 1.0 - t * 0.8;
    TRANSFORM[0][0] = scale;
    TRANSFORM[1][1] = scale;
    TRANSFORM[2][2] = scale;
}
```

### Built-in Particle Shader Variables

| Variable | Access | Description |
|---|---|---|
| `INDEX` | read | This particle's index (0..AMOUNT-1) |
| `AMOUNT` | read | Total particle count |
| `LIFETIME` | read | Particle lifetime in seconds |
| `DELTA` | read | Frame delta time |
| `TIME` | read | Scene elapsed time |
| `VELOCITY` | read/write | Particle velocity vector |
| `TRANSFORM` | read/write | Particle world transform (mat4) |
| `COLOR` | read/write | Particle color and alpha |
| `CUSTOM` | read/write | CUSTOM.y = elapsed time since spawn (use CUSTOM.y / LIFETIME for 0–1 progress) |
| `ACTIVE` | write | Set to false to kill the particle early |
| `RESTART` | read | True on the frame the particle restarts |
| `EMIT_POSITION` | read | Position of the emitter at spawn |

### start() vs process()

This distinction is critical:

- `start()` — runs once, on the frame the particle spawns. Use it for initial conditions: position offset, spawn velocity, spawn color, randomized properties. Reading `VELOCITY` here gives you the previous particle's velocity (or zero for the first spawn) — set it, don't read it.
- `process()` — runs every frame for every living particle. Modifies state frame by frame. Access `CUSTOM.y / LIFETIME` to get 0.0→1.0 over the particle's life.

```glsl
// Spiral particle shader
shader_type particles;

uniform float spiral_speed : hint_range(0.0, 10.0) = 3.0;
uniform float rise_speed : hint_range(0.0, 5.0) = 1.5;

void start() {
    float angle = float(INDEX) / float(AMOUNT) * TAU * 3.0;
    VELOCITY = vec3(cos(angle), rise_speed, sin(angle)) * spiral_speed;
    COLOR = vec4(cos(angle) * 0.5 + 0.5,
                 sin(angle * 2.0) * 0.5 + 0.5,
                 1.0, 1.0);
    TRANSFORM = mat4(1.0);
}

void process() {
    float t = CUSTOM.y / LIFETIME;
    // Spiral inward over time
    VELOCITY.x *= 0.99;
    VELOCITY.z *= 0.99;
    COLOR.a = 1.0 - t;
}
```

---

## 8. One-Shot Particles and Burst Effects

For impact hits, explosions, collectible pickups, and other moment-specific effects, you want particles that emit once and then stop. Set `one_shot = true` on the `GPUParticles3D` node.

### Basic One-Shot Setup

```gdscript
@onready var impact_particles: GPUParticles3D = $ImpactParticles

func _ready() -> void:
    impact_particles.one_shot = true
    impact_particles.emitting = false  # Don't emit at start

func on_hit(hit_position: Vector3) -> void:
    impact_particles.global_position = hit_position
    impact_particles.restart()    # Reset the emission timer
    impact_particles.emitting = true
    # One-shot particles automatically stop after one full lifetime cycle
```

The `restart()` call is important. Without it, if the particles are already done, setting `emitting = true` may not trigger a new burst if the internal timer hasn't been reset.

Also set `explosiveness` to 1.0 on one-shot particles if you want all particles to emit instantly (explosion burst). Lower values spread emission over the lifetime window.

For a quick impact explosion with immediate visual feedback:

```gdscript
# Full one-shot impact setup with correct settings
func setup_impact_particles(particles: GPUParticles3D) -> void:
    particles.one_shot = true
    particles.emitting = false
    particles.explosiveness = 0.95    # Almost all emit at once
    particles.randomness = 0.2        # Slight timing variation
    particles.lifetime = 0.6          # Short-lived impact
    particles.preprocess = 0.0        # Don't pre-simulate (instant on demand)

    var mat := ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    mat.emission_sphere_radius = 0.05
    mat.direction = Vector3(0, 1, 0)
    mat.spread = 180.0                # Full sphere burst
    mat.initial_velocity_min = 2.0
    mat.initial_velocity_max = 6.0
    mat.gravity = Vector3(0, -12.0, 0)
    mat.damping_min = 3.0
    mat.damping_max = 6.0
    mat.scale_min = 0.05
    mat.scale_max = 0.2

    var g := GradientTexture1D.new()
    var grad := Gradient.new()
    grad.set_color(0, Color(1.5, 1.2, 0.5, 1))   # Hot yellow-white
    grad.add_point(0.4, Color(1.0, 0.4, 0.1, 1))  # Orange
    grad.set_color(1, Color(0.3, 0.1, 0.0, 0))    # Fade out
    g.gradient = grad
    mat.color_ramp = g
    particles.process_material = mat
```

### Particle Pooling

Spawning new nodes at runtime causes allocation stutters, especially on mobile. Pool your one-shot particles: create a fixed set at startup, reuse them in round-robin order.

```gdscript
class_name ParticlePool
extends Node

var particle_pool: Array[GPUParticles3D] = []
var pool_index: int = 0

func _ready() -> void:
    # Pre-instantiate the pool
    for i in 10:
        var p: GPUParticles3D = preload("res://vfx/impact.tscn").instantiate()
        p.emitting = false
        p.one_shot = true
        add_child(p)
        particle_pool.append(p)

func spawn_impact(pos: Vector3) -> GPUParticles3D:
    var p := particle_pool[pool_index]
    p.global_position = pos
    p.restart()
    p.emitting = true
    pool_index = (pool_index + 1) % particle_pool.size()
    return p

func spawn_at_node(node: Node3D) -> GPUParticles3D:
    return spawn_impact(node.global_position)
```

The pool size depends on how many simultaneous impacts can happen. A bullet hell shooter might need 50+; a slow-paced RPG might need only 5. Profile and tune.

### Signals for Cleanup

If you need to know when a one-shot effect finishes (to trigger something else, like a sound), `GPUParticles3D` emits `finished` when `one_shot = true` and all particles have died:

```gdscript
func spawn_and_notify(pos: Vector3) -> void:
    var p := impact_particles
    p.global_position = pos
    p.restart()
    p.emitting = true
    # Connect to finished — disconnect after to avoid memory leaks
    p.finished.connect(_on_particles_finished, CONNECT_ONE_SHOT)

func _on_particles_finished() -> void:
    # Trigger a followup effect, play a sound, etc.
    $AudioStreamPlayer3D.play()
```

---

## 9. SubViewport Tricks

`SubViewport` renders a camera view into a texture that you can use anywhere — as a material texture, displayed in a `SubViewportContainer`, or read by a shader. This enables several post-processing techniques that the Environment resource can't do.

### Pixelation Effect

Render your 3D scene at low resolution, then display it stretched to full screen. This creates crisp, chunky pixels without any per-object changes.

Scene structure:

```
Main Scene:
├── SubViewportContainer  (fill entire window, stretch_shrink = 6)
│   └── SubViewport  (size: 320x180, handle_input_locally = true)
│       ├── Camera3D  (your main camera)
│       ├── WorldEnvironment
│       ├── DirectionalLight3D
│       └── ... your 3D scene ...
└── CanvasLayer  (for UI, NOT inside SubViewport)
    └── ... UI nodes ...
```

In code:

```gdscript
# Resize SubViewport for different pixelation levels
@onready var sub_vp: SubViewport = $SubViewportContainer/SubViewport

func set_pixel_size(width: int, height: int) -> void:
    sub_vp.size = Vector2i(width, height)

func _ready() -> void:
    set_pixel_size(320, 180)  # Chunky retro pixels

# Toggle between pixelated and full-res
var pixelated := true

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_pixelation"):
        pixelated = !pixelated
        if pixelated:
            set_pixel_size(320, 180)
        else:
            set_pixel_size(
                DisplayServer.window_get_size().x,
                DisplayServer.window_get_size().y
            )
```

Set the `SubViewportContainer`'s `stretch` to true and `stretch_shrink` to 1 — the viewport's own resolution controls the chunky look without any extra settings.

### Depth/Normal Rendering for Edge Detection

Render scene normals and depth to a SubViewport, then apply an edge detection shader to create outlines:

```gdscript
# Shader on the SubViewportContainer (or a CanvasItem above it)
# reads the depth/normal texture and outputs edges

# In the SubViewport, use a WorldEnvironment with a custom
# Environment that renders in a special way — or use a shader
# on each mesh that outputs NORMAL as COLOR:

var normal_shader_code := """
shader_type spatial;
render_mode unshaded;
void fragment() {
    // Output view-space normal as color
    vec3 normal = NORMAL * 0.5 + 0.5;
    ALBEDO = normal;
    ALPHA = 1.0;
}
"""
```

Edge detection fragment shader on a CanvasItem overlay:

```glsl
// edge_detect.gdshader — applied to a ColorRect over the screen
shader_type canvas_item;

uniform sampler2D scene_texture : hint_screen_texture, filter_linear_mipmap;
uniform float edge_threshold : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 texel = vec2(1.0) / vec2(textureSize(scene_texture, 0));

    // Sobel kernel
    vec4 tl = texture(scene_texture, uv + vec2(-texel.x, -texel.y));
    vec4 tr = texture(scene_texture, uv + vec2( texel.x, -texel.y));
    vec4 bl = texture(scene_texture, uv + vec2(-texel.x,  texel.y));
    vec4 br = texture(scene_texture, uv + vec2( texel.x,  texel.y));
    vec4 l  = texture(scene_texture, uv + vec2(-texel.x,  0.0));
    vec4 r  = texture(scene_texture, uv + vec2( texel.x,  0.0));
    vec4 t  = texture(scene_texture, uv + vec2( 0.0, -texel.y));
    vec4 b  = texture(scene_texture, uv + vec2( 0.0,  texel.y));

    vec4 gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
    vec4 gy = -tl - 2.0*t - tr + bl + 2.0*b + br;
    float edge = length(sqrt(gx*gx + gy*gy).rgb);

    COLOR = vec4(0.0, 0.0, 0.0, step(edge_threshold, edge));
}
```

### Security Camera / Picture-in-Picture

A SubViewport with its own Camera3D renders from a different angle. Display it as a texture on a mesh (a TV, security monitor, magic mirror):

```gdscript
@onready var security_cam_vp: SubViewport = $SecurityCameraSubViewport
@onready var monitor_mesh: MeshInstance3D = $MonitorMesh

func _ready() -> void:
    # Get the viewport texture and apply it to the monitor mesh material
    var vp_texture := security_cam_vp.get_texture()
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = vp_texture
    mat.emission_enabled = true
    mat.emission_texture = vp_texture
    mat.emission_energy_multiplier = 0.5  # Slight self-illumination
    monitor_mesh.material_override = mat
```

---

## 10. Compositor Effects (Godot 4.3+)

The **Compositor** system lets you inject custom render passes directly into Godot's rendering pipeline. This is for effects that can't be done with Environment settings or canvas shaders — effects that need depth buffer access, operate in render space, or must run before tonemapping.

### How It Works

1. Create a `Compositor` resource on your `Camera3D` (or `WorldEnvironment`).
2. Add `CompositorEffect` resources to the compositor's `effects` array.
3. Each `CompositorEffect` specifies when in the pipeline it runs and which shader to use.

Effect stages:

| Stage | When It Runs |
|---|---|
| `POST_TRANSPARENT` | After transparent objects render |
| `PRE_GLOW` | Before glow/bloom |
| `POST_GLOW` | After glow/bloom |
| `TONEMAP` | During tonemap |
| `POST_TONEMAP` | After tonemap, before TAA |

### Grayscale Compositor Effect

```gdscript
# compositor_grayscale.gd
@tool
extends CompositorEffect

func _init() -> void:
    effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT

func _render_callback(effect_callback_type: int, render_data: RenderData) -> void:
    var render_scene_buffers := render_data.get_render_scene_buffers()
    if not render_scene_buffers:
        return

    var size := render_scene_buffers.get_internal_size()
    if size.x == 0 or size.y == 0:
        return

    # Use RenderingServer compute to apply grayscale
    # This is a simplified example — full implementation uses RD (RenderingDevice)
    var rd := RenderingServer.get_rendering_device()
    # ... bind shader, dispatch compute, etc.
```

### A More Complete Compositor Effect

Here is a fuller (though still simplified) example of a compositor effect using the RenderingDevice API to apply a desaturation pass:

```gdscript
# desaturate_effect.gd
@tool
class_name DesaturateEffect
extends CompositorEffect

var rd: RenderingDevice
var shader: RID
var pipeline: RID

func _init() -> void:
    effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
    rd = RenderingServer.get_rendering_device()
    _create_shader()

func _create_shader() -> void:
    # GLSL compute shader source — desaturates the color image
    var shader_source := RDShaderSource.new()
    shader_source.source_compute = """
#version 450
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba16f) uniform image2D color_image;
layout(push_constant) uniform PushConstants {
    float strength;
} pc;

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    vec4 color = imageLoad(color_image, coord);
    float lum = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    color.rgb = mix(color.rgb, vec3(lum), pc.strength);
    imageStore(color_image, coord, color);
}
"""
    var shader_spirv := rd.shader_compile_spirv_from_source(shader_source)
    shader = rd.shader_create_from_spirv(shader_spirv)
    pipeline = rd.compute_pipeline_create(shader)

func _render_callback(effect_callback_type: int, render_data: RenderData) -> void:
    var buffers := render_data.get_render_scene_buffers()
    if not buffers:
        return

    var size := buffers.get_internal_size()
    if size.x == 0 or size.y == 0:
        return

    # Get the internal color image for writing
    # (Exact API varies by Godot version — check godot docs for current RenderSceneBuffersRD)
    # rd.compute_list_begin() → bind pipeline → bind uniforms → dispatch → end
```

The RenderingDevice API changes across Godot 4 minor versions. Always check the [Godot class reference for CompositorEffect](https://docs.godotengine.org/en/stable/classes/class_compositoreffect.html) for the current API. For production use, canvas item shaders (section 10) are more stable and easier to maintain.

The full compositor effect API uses the low-level `RenderingDevice` (RD) API — compute shaders, buffer bindings, and barriers. It's powerful but verbose. For most post-processing, the canvas shader approach (section 9) is simpler and sufficient.

### Chromatic Aberration via Canvas Shader

For the cyberpunk preset, chromatic aberration (color fringing) is most practical as a canvas item shader on a fullscreen ColorRect:

```glsl
// chromatic_aberration.gdshader
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float aberration_strength : hint_range(0.0, 0.02) = 0.005;
uniform vec2 center = vec2(0.5, 0.5);

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 offset = (uv - center) * aberration_strength;

    float r = texture(screen_texture, uv - offset).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv + offset).b;
    float a = texture(screen_texture, uv).a;

    COLOR = vec4(r, g, b, a);
}
```

Place a `ColorRect` covering the viewport in a `CanvasLayer` with layer 100, apply this shader. Toggle visibility to toggle the effect.

### Vignette via Canvas Shader

A dark vignette around the screen edges increases focus and tension. Common in horror, noir, and cinematic sequences:

```glsl
// vignette.gdshader
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.8;
uniform float vignette_size : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 scene = texture(screen_texture, uv);

    // Distance from center
    vec2 centered = uv - vec2(0.5);
    float dist = length(centered);

    // Smooth vignette falloff
    float vignette = smoothstep(vignette_size, vignette_size + 0.4, dist);
    vignette *= vignette_strength;

    COLOR = vec4(scene.rgb * (1.0 - vignette), scene.a);
}
```

### Film Grain via Canvas Shader

```glsl
// film_grain.gdshader
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.05;
uniform float grain_size : hint_range(1.0, 4.0) = 1.5;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 scene = texture(screen_texture, uv);

    // Animated grain — TIME makes it change every frame
    float noise = rand(uv / grain_size + vec2(TIME * 0.5, TIME * 0.3));
    noise = noise * 2.0 - 1.0;  // -1 to 1

    COLOR = scene + vec4(vec3(noise * grain_strength), 0.0);
}
```

---

## 11. CPUParticles3D

`CPUParticles3D` is the CPU-based particle system. It has nearly identical properties to `GPUParticles3D` but runs on the CPU instead of the GPU.

### CPUParticles3D and Per-Particle Game Logic

One genuine advantage of CPU particles over GPU particles: the CPU can read particle state and use it in game logic. GPU particles run entirely on the GPU — you can't (efficiently) read per-particle position back to the CPU. For game effects where particles need to interact with gameplay — collecting particles, particles that trigger events on landing, particles that avoid obstacles — `CPUParticles3D` is the right tool.

```gdscript
# CPUParticles3D setup example
func create_cpu_fire() -> CPUParticles3D:
    var particles := CPUParticles3D.new()
    particles.amount = 80
    particles.lifetime = 1.5
    particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
    particles.emission_sphere_radius = 0.2
    particles.direction = Vector3(0, 1, 0)
    particles.spread = 15.0
    particles.initial_velocity_min = 1.0
    particles.initial_velocity_max = 3.0
    particles.gravity = Vector3(0, 0, 0)
    particles.damping_min = 1.0
    particles.damping_max = 2.0
    particles.scale_amount_min = 0.5
    particles.scale_amount_max = 1.5
    particles.color = Color(1, 0.5, 0, 1)
    # Note: CPUParticles3D uses draw_mesh (a Mesh), not draw_pass_1
    particles.mesh = QuadMesh.new()
    return particles
```

### When to Use CPUParticles3D

| Situation | Use |
|---|---|
| Web export (HTML5) | CPUParticles3D — GPUParticles3D doesn't work on WebGL compatibility renderer |
| Compatibility renderer | CPUParticles3D |
| Old hardware without compute shaders | CPUParticles3D |
| Particles that need to read/write game state each frame | CPUParticles3D |
| < 500 particles on modern desktop | Either — CPU cost is negligible |
| > 1000 particles on modern desktop | GPUParticles3D — CPU can't keep up |

### API Compatibility

The APIs are nearly identical by design. If you build with `GPUParticles3D` and need to fall back, you can often just swap the node type. A few things are different:

- `CPUParticles3D` uses `draw_mesh` (a `Mesh` resource) instead of `draw_pass_1–4`
- `CPUParticles3D` doesn't support particle shaders — all behavior is controlled by the properties
- `CPUParticles3D` has slightly different emission shape names

```gdscript
# Detect and use the right particle type
func create_particles_for_platform() -> Node3D:
    if OS.has_feature("web"):
        var cpu_particles := CPUParticles3D.new()
        cpu_particles.amount = 100
        cpu_particles.lifetime = 2.0
        cpu_particles.direction = Vector3(0, 1, 0)
        cpu_particles.spread = 45.0
        cpu_particles.gravity = Vector3(0, -9.8, 0)
        return cpu_particles
    else:
        return create_fire()  # Returns GPUParticles3D
```

You can also convert a `GPUParticles3D` to `CPUParticles3D` in the editor: right-click the node in the scene tree and select "Convert to CPUParticles3D."

---

## 12. Code Walkthrough: Mood Board Scene

This is the full mini-project for the module: one 3D scene, four radically different visual presets, switchable at runtime.

### Scene Structure

```
MoodBoard (Node3D)
├── WorldEnvironment                    # Swapped on preset change
├── DirectionalLight3D                  # "Sun" — intensity/color per preset
├── MoodController (Node — script)
├── Room (MeshInstance3D or CSGBox3D)   # Simple room geometry
├── Props (Node3D)                      # Furniture, objects to show reflections
│   ├── TableMesh (MeshInstance3D)
│   ├── ChairMesh (MeshInstance3D)
│   └── GlowyObject (MeshInstance3D)   # Emission material for bloom demo
├── Camera3D
├── ParticleEffects (Node3D)
│   ├── FireParticles (GPUParticles3D)  # Pastoral
│   ├── SparkParticles (GPUParticles3D) # Cyberpunk
│   ├── DustParticles (GPUParticles3D)  # Horror
│   └── PixelParticles (GPUParticles3D) # Retro
└── CanvasLayer (layer 100)
    ├── ChromaticAberration (ColorRect) # Cyberpunk only
    ├── FilmGrain (ColorRect)           # Horror only
    └── ScanlinesOverlay (ColorRect)    # Retro only
```

### Environment Resource Configs

**Cyberpunk (`environments/cyberpunk.tres`):**

```
Background: Sky (dark city sky, blue-purple)
Ambient Light: Color (0.05, 0.05, 0.1) energy 0.3
Tonemap: ACES, exposure 1.2
Glow: enabled, intensity 1.5, hdr_threshold 0.8, levels 1+2+3
  blend_mode: Additive
SSAO: enabled, intensity 1.0, radius 1.0
SSR: enabled, max_steps 64
Fog: enabled, color (0.05, 0.0, 0.15), density 0.01
Volumetric Fog: enabled, albedo (0.05, 0.0, 0.2), density 0.02
Adjustments: brightness 0.9, contrast 1.4, saturation 1.8
```

```gdscript
# Configure cyberpunk environment
func configure_cyberpunk(env: Environment) -> void:
    # Tonemap
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 1.2
    # Glow
    env.glow_enabled = true
    env.glow_intensity = 1.5
    env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
    env.glow_hdr_threshold = 0.8
    env.set_glow_level(1, true)
    env.set_glow_level(2, true)
    env.set_glow_level(3, true)
    # Fog
    env.fog_enabled = true
    env.fog_light_color = Color(0.05, 0.0, 0.15)
    env.fog_density = 0.01
    # SSAO
    env.ssao_enabled = true
    env.ssao_intensity = 1.0
    # SSR
    env.ssr_enabled = true
    env.ssr_max_steps = 64
    # Adjustments
    env.adjustment_enabled = true
    env.adjustment_brightness = 0.9
    env.adjustment_contrast = 1.4
    env.adjustment_saturation = 1.8
```

**Pastoral (`environments/pastoral.tres`):**

```
Background: ProceduralSky (warm noon)
Ambient Light: Sky, energy 0.7
Tonemap: Filmic, exposure 1.0, white 1.5
Glow: enabled, intensity 0.6, hdr_threshold 1.2, levels 4+5+6
  blend_mode: Screen
SSAO: enabled, intensity 0.5 (subtle)
Volumetric Fog: enabled, albedo (0.9, 0.85, 0.7), density 0.008, anisotropy 0.5
Adjustments: brightness 1.05, contrast 0.9, saturation 1.2
```

**Horror (`environments/horror.tres`):**

```
Background: Color (0.02, 0.01, 0.01)
Ambient Light: Color (0.1, 0.08, 0.08) energy 0.15
Tonemap: Reinhard, exposure 0.8
Glow: enabled, intensity 0.4, hdr_threshold 1.5 (minimal glow)
Fog: enabled, color (0.12, 0.1, 0.1), density 0.025
SSAO: enabled, intensity 2.0, power 2.0 (heavy)
Adjustments: brightness 0.85, contrast 1.3, saturation 0.2
```

**Retro (`environments/retro.tres`):**

```
Background: Color (0.05, 0.05, 0.1)
Ambient Light: Color (0.3, 0.3, 0.3) energy 0.5
Tonemap: Linear (flat, for dithering to control)
Glow: disabled
Adjustments: brightness 1.0, contrast 1.0, saturation 0.8
(Pixelation handled by SubViewport)
```

### The Controller Script

```gdscript
# mood_controller.gd
extends Node

enum Preset { CYBERPUNK, PASTORAL, HORROR, RETRO }

@export var world_env: WorldEnvironment
@export var sun_light: DirectionalLight3D
@export var fire_particles: GPUParticles3D
@export var spark_particles: GPUParticles3D
@export var dust_particles: GPUParticles3D
@export var pixel_particles: GPUParticles3D
@export var chromatic_aberration: ColorRect
@export var film_grain: ColorRect
@export var scanlines: ColorRect
@export var sub_viewport: SubViewport  # For retro pixelation

var environments: Dictionary = {
    Preset.CYBERPUNK: preload("res://environments/cyberpunk.tres"),
    Preset.PASTORAL:  preload("res://environments/pastoral.tres"),
    Preset.HORROR:    preload("res://environments/horror.tres"),
    Preset.RETRO:     preload("res://environments/retro.tres"),
}

var current_preset: Preset = Preset.PASTORAL

func _ready() -> void:
    apply_preset(current_preset)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_1"):
        apply_preset(Preset.CYBERPUNK)
    elif event.is_action_pressed("ui_2"):
        apply_preset(Preset.PASTORAL)
    elif event.is_action_pressed("ui_3"):
        apply_preset(Preset.HORROR)
    elif event.is_action_pressed("ui_4"):
        apply_preset(Preset.RETRO)

func apply_preset(preset: Preset) -> void:
    current_preset = preset
    world_env.environment = environments[preset]

    # Particles: disable all, enable the relevant one
    fire_particles.emitting   = (preset == Preset.PASTORAL)
    spark_particles.emitting  = (preset == Preset.CYBERPUNK)
    dust_particles.emitting   = (preset == Preset.HORROR)
    pixel_particles.emitting  = (preset == Preset.RETRO)

    # Canvas overlays
    chromatic_aberration.visible = (preset == Preset.CYBERPUNK)
    film_grain.visible           = (preset == Preset.HORROR)
    scanlines.visible            = (preset == Preset.RETRO)

    # Pixelation: swap SubViewport resolution
    if sub_viewport:
        if preset == Preset.RETRO:
            sub_viewport.size = Vector2i(320, 180)
        else:
            var win_size := DisplayServer.window_get_size()
            sub_viewport.size = Vector2i(win_size.x, win_size.y)

    # Lighting adjustments per preset
    match preset:
        Preset.CYBERPUNK:
            sun_light.light_color = Color(0.4, 0.4, 1.0)
            sun_light.light_energy = 0.5
        Preset.PASTORAL:
            sun_light.light_color = Color(1.0, 0.9, 0.7)
            sun_light.light_energy = 2.0
        Preset.HORROR:
            sun_light.light_color = Color(0.6, 0.5, 0.4)
            sun_light.light_energy = 0.3
        Preset.RETRO:
            sun_light.light_color = Color(1.0, 1.0, 1.0)
            sun_light.light_energy = 1.0

    print("Switched to preset: ", Preset.keys()[preset])
```

### CRT Scanlines Shader (Retro Preset)

```glsl
// scanlines.gdshader
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float line_count : hint_range(100.0, 600.0) = 180.0;
uniform float line_darkness : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec4 scene = texture(screen_texture, SCREEN_UV);

    // Scanline based on pixel Y position
    float line = mod(FRAGCOORD.y, 2.0);
    float scanline = mix(1.0 - line_darkness, 1.0, step(1.0, line));

    COLOR = vec4(scene.rgb * scanline, scene.a);
}
```

### Dithering Shader (Retro Preset)

```glsl
// dithering.gdshader
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform int color_levels : hint_range(2, 16) = 4;

// 4x4 Bayer matrix
const mat4 bayer = mat4(
    vec4( 0.0,  8.0,  2.0, 10.0),
    vec4(12.0,  4.0, 14.0,  6.0),
    vec4( 3.0, 11.0,  1.0,  9.0),
    vec4(15.0,  7.0, 13.0,  5.0)
) / 16.0;

void fragment() {
    vec4 scene = texture(screen_texture, SCREEN_UV);

    // Get dither threshold from Bayer matrix
    int x = int(FRAGCOORD.x) % 4;
    int y = int(FRAGCOORD.y) % 4;
    float threshold = bayer[y][x];

    // Quantize with dithering
    float levels = float(color_levels);
    vec3 quantized = floor(scene.rgb * levels + threshold) / levels;

    COLOR = vec4(quantized, scene.a);
}
```

---

## API Quick Reference

### Environment Properties (Key Subsets)

**Glow:**

| Property | Type | Default |
|---|---|---|
| `glow_enabled` | bool | false |
| `glow_intensity` | float | 0.8 |
| `glow_strength` | float | 1.0 |
| `glow_bloom` | float | 0.0 |
| `glow_blend_mode` | GlowBlendMode | Softlight |
| `glow_hdr_threshold` | float | 1.0 |
| `glow_hdr_scale` | float | 2.0 |
| `set_glow_level(idx, enabled)` | method | — |

**Fog:**

| Property | Type | Default |
|---|---|---|
| `fog_enabled` | bool | false |
| `fog_light_color` | Color | white |
| `fog_light_energy` | float | 1.0 |
| `fog_density` | float | 0.01 |
| `fog_sky_affect` | float | 1.0 |
| `fog_height` | float | 0.0 |
| `fog_height_density` | float | 0.0 |
| `volumetric_fog_enabled` | bool | false |
| `volumetric_fog_density` | float | 0.05 |
| `volumetric_fog_albedo` | Color | white |
| `volumetric_fog_anisotropy` | float | 0.2 |
| `volumetric_fog_length` | float | 64.0 |

**SSAO / SSR / SSIL:**

| Property | Type | Default |
|---|---|---|
| `ssao_enabled` | bool | false |
| `ssao_radius` | float | 1.0 |
| `ssao_intensity` | float | 2.0 |
| `ssao_power` | float | 1.5 |
| `ssr_enabled` | bool | false |
| `ssr_max_steps` | int | 64 |
| `ssr_fade_in` | float | 0.15 |
| `ssr_fade_out` | float | 2.0 |
| `ssil_enabled` | bool | false |
| `ssil_radius` | float | 5.0 |
| `ssil_intensity` | float | 1.0 |

**Tonemap:**

| Property | Type | Default |
|---|---|---|
| `tonemap_mode` | ToneMapper | Filmic |
| `tonemap_exposure` | float | 1.0 |
| `tonemap_white` | float | 1.0 |

**Adjustments:**

| Property | Type | Default |
|---|---|---|
| `adjustment_enabled` | bool | false |
| `adjustment_brightness` | float | 1.0 |
| `adjustment_contrast` | float | 1.0 |
| `adjustment_saturation` | float | 1.0 |
| `adjustment_color_correction` | Texture | null |

### GPUParticles3D Properties

| Property | Type | Notes |
|---|---|---|
| `emitting` | bool | Start/stop emission |
| `amount` | int | Particle count |
| `lifetime` | float | Seconds per particle |
| `one_shot` | bool | Emit once and stop |
| `preprocess` | float | Pre-simulate time on spawn |
| `speed_scale` | float | Overall speed multiplier |
| `explosiveness` | float | 0 = spread out, 1 = all at once |
| `randomness` | float | Timing randomization |
| `fixed_fps` | int | Lock to specific FPS (0 = uncapped) |
| `process_material` | Material | ParticleProcessMaterial or ShaderMaterial |
| `draw_pass_1` | Mesh | Mesh rendered per particle |
| `restart()` | method | Reset and restart emission |

### ParticleProcessMaterial Properties (Key Subset)

| Property | Type | Notes |
|---|---|---|
| `emission_shape` | EmissionShape | Point, Sphere, Box, Ring, etc. |
| `direction` | Vector3 | Initial emission direction |
| `spread` | float | Cone spread in degrees |
| `initial_velocity_min/max` | float | Speed range at spawn |
| `gravity` | Vector3 | Gravity force on particles |
| `damping_min/max` | float | Deceleration rate |
| `scale_min/max` | float | Size range |
| `scale_curve` | CurveTexture | Size over lifetime |
| `color` | Color | Base color tint |
| `color_ramp` | GradientTexture1D | Color over lifetime |
| `radial_accel_min/max` | float | Acceleration toward/away from origin |

### FogVolume Properties

| Property | Type | Notes |
|---|---|---|
| `size` | Vector3 | Box dimensions (for box shape) |
| `shape` | FogVolumeShape | Ellipsoid, Cone, Cylinder, Box, World |
| `material` | FogMaterial | Density, albedo, emission |
| `FogMaterial.density` | float | Base density |
| `FogMaterial.albedo` | Color | Fog color |
| `FogMaterial.emission` | Color | Self-illumination |
| `FogMaterial.height_falloff` | float | Density falloff at top of volume |
| `FogMaterial.edge_fade` | float | Soft edges |

### SubViewport Settings

| Property | Type | Notes |
|---|---|---|
| `size` | Vector2i | Resolution of the viewport |
| `render_target_update_mode` | enum | When to update: Always, Once, When Visible |
| `own_world_3d` | bool | Use own 3D world (for separate scenes) |
| `handle_input_locally` | bool | Whether this viewport processes input |
| `msaa_3d` | MSAA | Anti-aliasing within the viewport |
| `get_texture()` | method | Returns ViewportTexture for materials |

---

## Common Pitfalls

### 1. Glow Looks Blown Out

**WRONG:** Set `glow_intensity` to 5.0 hoping for dramatic results, and the entire scene becomes a white blob.

**RIGHT:** Start with `glow_intensity` at 0.5–1.0. Use `glow_hdr_threshold` (default 1.0) to control *what* glows. Only pixels brighter than the threshold bloom. Make objects glow by setting their `emission_energy_multiplier` above 1.0, not by cranking the global intensity.

```gdscript
# Good starting point for glow configuration
env.glow_enabled = true
env.glow_intensity = 0.8
env.glow_hdr_threshold = 1.0   # Only overbright pixels bloom
env.glow_hdr_scale = 2.0
```

### 2. Everything Glows (No Threshold)

**WRONG:** `glow_hdr_threshold` left at 0.0 — every surface produces bloom. The scene looks vaseline-smeared.

**RIGHT:** The threshold determines the brightness cutoff. With threshold at 1.0, only pixels with HDR values above 1.0 produce glow — that's materials with `emission_energy_multiplier > 1.0` or overbright lights. Non-emissive surfaces stay sharp.

```gdscript
# Wrong — everything blooms:
env.glow_hdr_threshold = 0.0

# Right — only bright emitters bloom:
env.glow_hdr_threshold = 1.0
```

### 3. Volumetric Fog Is Invisible

**WRONG:** Enable `volumetric_fog_enabled` and set `volumetric_fog_density`, but the scene looks exactly the same. Frustrating.

**RIGHT:** Volumetric fog only appears where lights contribute to it. Each `Light3D` node has a `light_volumetric_fog_energy` property (default 0). Set it above 0 on at least one light in your scene. Without lights, the fog has nothing to scatter.

```gdscript
# Make the sun interact with volumetric fog
@onready var sun: DirectionalLight3D = $DirectionalLight3D
sun.light_volumetric_fog_energy = 0.5  # Adjust to taste
```

### 4. GPUParticles3D on Web Export Doesn't Work

**WRONG:** Build with GPUParticles3D everywhere, export to HTML5, and find all particle effects are missing or broken. Web (WebGL) uses the Compatibility renderer, which doesn't support compute shaders — which is how GPUParticles3D works.

**RIGHT:** Use `CPUParticles3D` for web exports, or detect the renderer at runtime and use the appropriate type. You can also convert GPUParticles3D to CPUParticles3D nodes before a web-specific build.

```gdscript
# Runtime detection
func make_particles() -> Node3D:
    if OS.has_feature("web"):
        var p := CPUParticles3D.new()
        # ... configure ...
        return p
    else:
        return create_fire()  # GPUParticles3D version
```

### 5. One-Shot Particles Fire Once and Never Again

**WRONG:** Set `one_shot = true`, trigger `emitting = true` for the first impact — works great. Try again on a second impact — nothing happens.

**RIGHT:** Call `restart()` before setting `emitting = true`. Without `restart()`, the particle system thinks it's done and won't start a new cycle. The sequence must be: `restart()` then `emitting = true`.

```gdscript
# Wrong — second hit does nothing:
impact_particles.emitting = true

# Right — always works:
impact_particles.restart()
impact_particles.emitting = true
```

---

## Exercises

### Exercise 1: Campfire Scene (30–45 min)

Build a campfire with layered particle effects and animated lighting.

**Requirements:**
- Three stacked `GPUParticles3D` for fire, smoke, and embers — each with distinct settings
- An `OmniLight3D` as the fire light, positioned at the base of the flame
- Script that animates the light's `light_energy` with a sin wave plus random noise to simulate flickering
- `Environment` with glow enabled (intensity 1.2, HDR threshold 0.8) so the flame and embers bloom
- The fire should feel alive — vary particle spread, speed, and the noise pattern in the flicker script

**Starting point for flicker:**

```gdscript
@export var base_energy: float = 2.0
@export var flicker_speed: float = 8.0
@export var flicker_amount: float = 0.4

@onready var fire_light: OmniLight3D = $OmniLight3D

func _process(delta: float) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    var noise := sin(t * flicker_speed) * 0.5
    noise += sin(t * flicker_speed * 1.7 + 0.3) * 0.3
    noise += sin(t * flicker_speed * 0.5 + 1.1) * 0.2
    fire_light.light_energy = base_energy + noise * flicker_amount
```

**Extension:** Add a `FogVolume` at campfire position — low, wide, dense fog that represents smoke settling at ground level.

---

### Exercise 2: Portal Effect (60–90 min)

Build an activated portal: a ring of particles, a distortion plane, and a glow halo.

**Requirements:**
- `GPUParticles3D` with ring emission shape around the portal frame
- A `MeshInstance3D` (plane/quad) inside the ring with a distortion shader using `SCREEN_TEXTURE`:
  ```glsl
  shader_type spatial;
  render_mode unshaded, cull_disabled;
  uniform sampler2D screen_texture : hint_screen_texture;
  uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
  uniform float time_scale = 1.0;
  void fragment() {
      vec2 uv = SCREEN_UV;
      vec2 distort = vec2(
          sin(uv.y * 10.0 + TIME * time_scale) * distortion_strength,
          cos(uv.x * 10.0 + TIME * time_scale * 0.7) * distortion_strength
      );
      ALBEDO = texture(screen_texture, uv + distort).rgb;
      ALPHA = 0.9;
  }
  ```
- Environment glow enabled with high intensity so the particle ring glows brightly
- Dissolve animation: when activated, particles fade in over 1 second, distortion strength tweens from 0 to 0.02 using a `Tween`
- Deactivation: reverse — tween distortion to 0, stop particles

**Stretch goal:** Add a `AudioStreamPlayer3D` with a humming sound that starts when activated and stops when deactivated.

---

### Exercise 3: Weather System (90–120 min)

Build a dynamic weather system with rain, fog, and lightning.

**Requirements:**

**Rain:**
- `GPUParticles3D` with large amount (500+), box emission high above camera, direction straight down, high velocity, minimal spread
- Rain particles should be long thin quads (use a `QuadMesh` rotated to face direction of travel)
- A second particle system for ground splash (one_shot burst triggered when rain hits a surface — use raycasting or just emit at floor level)

**Fog:**
- Environment fog that thickens over time using a tween or lerp in `_process`
- Start fog density at 0.005, ramp to 0.03 during heavy rain, ramp back during clearing

**Lightning:**
- A brief (0.1 second) burst of `DirectionalLight3D` brightness — sets `light_energy` to 5.0, then back to normal
- Camera shake via small random offset to Camera3D position during the flash
- Randomized timing — lightning strikes every 8–20 seconds, randomly

**Thunder:**
- Play a sound effect 1–3 seconds after each lightning flash (simulating distance)
- This previews Module 9 (audio) — use `AudioStreamPlayer` and `await get_tree().create_timer(delay).timeout`

```gdscript
func trigger_lightning() -> void:
    # Visual flash
    sun_light.light_energy = 5.0
    shake_camera(0.3)
    await get_tree().create_timer(0.1).timeout
    sun_light.light_energy = original_energy

    # Delayed thunder
    var thunder_delay := randf_range(1.0, 3.0)
    await get_tree().create_timer(thunder_delay).timeout
    $ThunderSound.play()

func shake_camera(duration: float) -> void:
    var original_pos := camera.position
    var shake_timer := 0.0
    while shake_timer < duration:
        camera.position = original_pos + Vector3(
            randf_range(-0.1, 0.1),
            randf_range(-0.05, 0.05),
            0
        )
        await get_tree().process_frame
        shake_timer += get_process_delta_time()
    camera.position = original_pos
```

---

## Key Takeaways

1. **The Environment resource is your one-stop shop for post-processing.** Glow, fog, SSAO, tonemap, color adjustments — all in one resource. Save environments as `.tres` files and swap them at runtime for instant mood changes.

2. **Swapping Environment resources is the most powerful scene-building technique in this module.** One line of code changes everything: `world_env.environment = preloaded_environment`. The mood board project demonstrates this — same geometry, four radically different atmospheres.

3. **GPUParticles3D + ParticleProcessMaterial handles fire, smoke, sparks, and most effects without custom shaders.** The color ramp and scale curve cover 90% of what you need. Reach for particle shaders only when the material can't express your effect.

4. **Particle shaders (`shader_type particles`) give you full per-particle control.** Use `start()` for spawn conditions, `process()` for frame-by-frame behavior. The `CUSTOM.y / LIFETIME` ratio gives you 0→1 progress over a particle's life — use it for fade, scale, and color transitions.

5. **One-shot particles with `restart()` handle impact bursts. Pool them to avoid allocation stutters.** The pool pattern is simple: create 10 instances at startup, cycle through them round-robin. Never instantiate particle nodes during gameplay.

6. **SubViewport renders to texture — use it for pixelation, outlines, minimap, and picture-in-picture.** Rendering your full scene into a 320x180 viewport and stretching it gives you chunky retro pixels with zero per-object changes. Combine with canvas shaders for dithering and scanlines.

7. **Volumetric fog + FogVolume creates localized atmospheric effects that interact with lights.** Remember: volumetric fog is invisible without lights that have `light_volumetric_fog_energy > 0`. Set that property on your lights and suddenly the fog scatters beautifully around them.

---

## What's Next

The world looks beautiful. Now let's make it infinite.

**[Module 8: Procedural Generation & Instancing](module-08-procedural-generation-instancing.md)** covers terrain generation with noise, multimesh instancing for dense foliage, runtime mesh construction, and the tools that let you build worlds that are different every time the player loads in. All those post-processing tricks you just learned work directly on procedurally generated worlds — the Environment resource doesn't care whether your geometry was hand-placed or generated at runtime.

---

*[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)*
