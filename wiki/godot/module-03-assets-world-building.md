# Module 3: 3D Assets & World Building

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 5–8 hours
**Prerequisites:** [Module 2: Scene Composition & the Node Tree](module-02-scene-composition-nodes.md)

---

## Overview

You can compose scenes and spawn nodes. But your world is still made of primitive meshes — gray boxes and spheres. This module fixes that. You'll learn to import real 3D assets, set up materials that look good, light your scenes intentionally, and build an environment that has mood and atmosphere.

Godot's import pipeline handles GLTF/GLB files seamlessly — drag them into the file system dock and they're ready. The material system (StandardMaterial3D) gives you full PBR control: albedo, roughness, metallic, emission, normal maps. The lighting system has everything from directional suns to spot lights to global illumination. And WorldEnvironment lets you control the entire atmosphere — sky, fog, tonemap, ambient light.

By the end of this module, you'll build a stylized environment diorama with imported assets, intentional lighting, and a scripted day-night cycle.

---

## 1. The GLTF Pipeline

### Why GLTF/GLB?

GLTF (GL Transmission Format) is the industry standard for 3D assets. It replaced formats like FBX and OBJ as the go-to exchange format because it handles meshes, materials, textures, animations, and skeletons in a single, open spec. GLB is the binary version of GLTF — everything packed into one file, which is what you'll use 99% of the time.

Godot 4 has first-class GLTF support. There is no separate importer to install. Just drag a `.glb` file into the FileSystem dock and Godot handles everything.

### Where to Get Free Assets

Before you can import anything, you need something to import. These sources provide high-quality, game-ready assets for free:

**Kenney (kenney.nl)**
The gold standard for free game assets. Kenney's asset packs are consistently high quality, well-organized, and completely free for commercial use. Start here. Download the "Nature Kit", "City Kit", "Platformer Kit", or whatever matches your project. Kenney assets come as GLB files — perfect for Godot.

**Poly Pizza (poly.pizza)**
Thousands of low-poly 3D models, many free under Creative Commons. Good for characters, props, and environmental detail objects.

**Sketchfab (sketchfab.com)**
Huge library of 3D models. Filter by "Downloadable" and "Free". Quality varies widely but there are gems. Download as GLTF format.

**Mixamo (mixamo.com)**
Adobe's character animation service. Free if you have an Adobe account. Upload a character model or use one of theirs, then download animated characters as FBX (Godot can handle FBX too, though GLB is preferred). Great for humanoid NPCs and player characters.

**Quaternius (quaternius.com)**
Another excellent free source. Fully animated character packs, environment packs, all CC0.

### Importing a GLB File

The workflow is intentionally simple:

1. Download your `.glb` file.
2. Open your Godot project's FileSystem dock (bottom-left panel by default).
3. Drag the `.glb` file from your OS file manager into the FileSystem dock, or copy it into your project folder and let Godot auto-detect it.
4. Godot will show a brief "importing" indicator. When it's done, the file appears in the dock with a 3D mesh icon.

That's it. Godot has imported the asset and created a `.import` file alongside it (you don't touch that file — it's managed by Godot).

### Placing an Imported Asset in Your Scene

Two approaches:

**Drag into the 3D viewport.** Select the `.glb` file in the FileSystem dock and drag it directly into the 3D viewport. Godot creates an instance of the scene at the drop position.

**Drag into the Scene tree.** Drag the `.glb` file onto a node in the Scene tree panel to make it a child of that node. Useful when you want precise parent-child relationships.

**Double-click the GLB.** This opens the imported scene in its own editor tab. You can see its structure — usually a Node3D root with MeshInstance3D children and possibly a Skeleton3D and AnimationPlayer. You can save this as an editable scene (`.tscn`) using "Scene > Save As" if you need to modify it.

### The Import Dock

When you select a `.glb` file in the FileSystem dock, the **Import** dock (usually alongside the Inspector) shows the current import settings. Click "Reimport" after changing settings to apply them.

**Meshes section:**
- **Generate Tangents** — Leave this on. Tangents are required for normal maps to work correctly.
- **Generate LODs** — Enable this for large models. LODs (Level of Detail) automatically show lower-poly versions at distance, saving GPU time.
- **Create Shadow Meshes** — Creates optimized shadow-only geometry. Good for complex models.

**Materials section:**
- **Import As** — The most important setting. Options:
  - `Standard` — Uses StandardMaterial3D. The default. Use this unless you have a reason not to.
  - `Unshaded` — Creates materials that ignore lighting. Good for UI elements or stylized flat shading.
  - `Keep on Reimport` — Keeps materials you've customized after reimport. Use this once you start tweaking materials so your edits aren't overwritten.
- **Storage** — Where to store extracted materials: in the `.glb` itself (default), or as separate `.tres` files in your project. Separate files let you share materials across assets.

**Animation section:**
- **Loop Mode** — Set animations to loop or play once. You can also set this per-animation.
- **Import FPS** — Match this to the FPS the animations were authored at (usually 24 or 30).
- **Root Motion** — For character animations, you may want root motion (where the mesh's actual movement drives character position rather than playing in place).

### End-to-End Workflow Example

```
1. Go to kenney.nl/assets/nature-kit
2. Download the pack (ZIP file)
3. Extract the ZIP — find the GLB subfolder, it has individual .glb files
4. In Godot: File > Open Project Folder (or just drag in the FileSystem dock)
5. Copy tree.glb, rock.glb, and grass.glb into res://assets/nature/
6. Godot auto-imports them — look for the spinning indicator
7. In your main scene: drag tree.glb into the viewport
8. It appears in the scene tree as a Node3D instance
9. Use the Move tool (W) to position it
10. Duplicate (Ctrl+D) to place multiple trees
```

---

## 2. StandardMaterial3D

### What It Is

StandardMaterial3D is Godot's built-in PBR (Physically Based Rendering) material. PBR materials simulate how light actually interacts with surfaces — metals shine differently than plastic, rough surfaces scatter light differently than smooth ones. You don't need to understand the physics. You need to understand the knobs.

When you click on a MeshInstance3D and look at its material slot in the Inspector, you either see a StandardMaterial3D already assigned (if the model had materials) or `[empty]`. Click the empty slot and choose "New StandardMaterial3D" to create one.

### Albedo: The Base Color

Albedo is the base color of the surface before lighting is applied. Two sub-properties:

- **Albedo Color** — A solid color tint. White (default) means the texture is used as-is.
- **Albedo Texture** — A 2D texture sampled from the mesh's UV coordinates. Provides the detailed color pattern.

In practice: if you have a texture, set it in "Albedo Texture". Albedo Color multiplies on top — keep it white to show the texture accurately, or tint it to colorize the texture.

### Roughness: Shiny vs. Matte

Controls how rough the surface is at the microscopic level. This directly affects how specular (shiny) highlights look:

- **0.0** — Perfect mirror, sharp specular highlights. Use for polished chrome, perfect glass, still water.
- **0.3-0.4** — Shiny with some spread. Painted metal, lacquered wood, wet stone.
- **0.6-0.7** — Slightly matte. Dry plastic, painted walls, most everyday objects.
- **1.0** — Fully matte, no specular highlights. Raw concrete, dry fabric, chalk.

Roughness can also use a texture — the "Roughness Texture" maps different roughness values across the surface.

### Metallic: Metal vs. Non-Metal

Determines whether the surface behaves like a metal or a dielectric (everything that isn't metal):

- **0.0** — Dielectric. Wood, stone, plastic, skin, cloth — everything non-metallic.
- **1.0** — Metal. Gold, steel, copper, aluminum.

Almost everything in the real world is either fully metal or fully non-metal — avoid values in the middle except for worn/oxidized surfaces. The visual difference is dramatic: metals reflect their color into specular highlights, while dielectrics show white specular highlights.

**Specular** (visible when Metallic is 0) — The Fresnel-based specular response of the surface. Default 0.5 is correct for most materials. Only adjust for special cases like water (0.35), gemstones (higher), or surfaces covered in absorptive material.

### Emission: Glow and Self-Illumination

Makes the surface emit light visually. Note: emission in StandardMaterial3D is a visual effect — the surface looks bright, but it doesn't actually cast light on nearby objects (for that you need an actual Light node). Exception: SDFGI and LightMapper can capture emission as real light.

- **Emission Enabled** — Must be checked to activate emission.
- **Emission Color** — The emitted color.
- **Emission Energy Multiplier** — How bright the emission is. Values above 1.0 for HDR glow effects (requires Glow enabled in Environment).
- **Emission Texture** — Texture that controls which parts of the surface glow and with what color. Useful for screens, indicator lights, neon signs.

### Normal Maps

Normal maps fake surface detail by modifying how light hits the surface at each pixel, without adding actual geometry. A flat surface with a normal map looks like it has bumps, cracks, and texture.

- **Normal Map Enabled** — Check this to activate.
- **Normal Map** — Assign your normal map texture here. Normal maps are typically blue-purple in color — that's correct.
- **Normal Map Depth** — Strength of the effect. 1.0 is normal, lower values reduce the perceived bumpiness.

### Transparency

- **Transparency** — Set to `Alpha` for standard blending. Use for glass, particles, decals.
- **Alpha Scissor Threshold** — Instead of smooth blending, pixels are either fully opaque or fully transparent based on the alpha value. No sorting issues. Good for foliage, fences, masked details.
- **Alpha Hash** — Temporal dithering-based transparency. Avoids sorting issues while maintaining visual smoothness. Good for dense foliage.

### Creating Materials in Code

```gdscript
func create_glowing_material() -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.2, 0.8, 1.0)
    mat.emission_enabled = true
    mat.emission = Color(0.2, 0.8, 1.0)
    mat.emission_energy_multiplier = 3.0
    mat.roughness = 0.3
    mat.metallic = 0.0
    return mat
```

```gdscript
# Assign material to a MeshInstance3D
func setup_mesh_material(mesh_instance: MeshInstance3D) -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.8, 0.6, 0.2)  # Gold-ish
    mat.roughness = 0.2
    mat.metallic = 1.0
    # Surface index 0 is the first (usually only) material slot
    mesh_instance.set_surface_override_material(0, mat)
```

```gdscript
# Create a stone-like material
func create_stone_material(albedo_texture: Texture2D, normal_texture: Texture2D) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = albedo_texture
    mat.roughness = 0.85
    mat.metallic = 0.0
    mat.normal_enabled = true
    mat.normal_map = normal_texture
    mat.normal_scale = 1.2
    return mat
```

### Material Reuse and Local-to-Scene

By default, a material assigned to one mesh is shared — if you change it, all meshes using that material change. This is usually what you want.

Sometimes you want a unique material per instance (e.g., every crate has a different dirtiness). Right-click the material in the Inspector and choose **"Make Unique"** (or enable the "Local to Scene" flag in the material resource). Now that instance has its own copy.

Save materials as `.tres` files to reuse them across scenes: with the material selected, use the "Save" button (disk icon) in the resource header.

```gdscript
# Load a saved material from disk
var mat: StandardMaterial3D = load("res://materials/stone_wall.tres")
mesh_instance.set_surface_override_material(0, mat)
```

---

## 3. ORM Materials and Texture Workflows

### ORMMaterial3D

ORMMaterial3D is a variant of StandardMaterial3D optimized for PBR texture sets. The key difference: it uses a single **ORM texture** that packs three channels into one:
- **R (Red channel)** — Ambient Occlusion
- **G (Green channel)** — Roughness
- **B (Blue channel)** — Metallic

This is the format most 3D asset pipelines produce (Substance Painter, Blender Cycles bakes, etc.). One ORM texture instead of three separate textures = fewer draw calls, less VRAM, simpler setup.

When to use ORMMaterial3D vs StandardMaterial3D:
- Use ORMMaterial3D when you have a proper PBR texture set from an art pipeline.
- Use StandardMaterial3D for procedural/code-driven materials or simple color+roughness setups.

### Assigning a Full PBR Texture Set

A typical PBR texture set for a stone wall might be:
- `stone_wall_albedo.png` — base color
- `stone_wall_normal.png` — surface normal detail
- `stone_wall_orm.png` — packed occlusion/roughness/metallic

In the Inspector, with an ORMMaterial3D selected:
1. **Albedo > Texture** — assign `stone_wall_albedo.png`
2. **Normal Map > Enabled** — check it, then assign `stone_wall_normal.png`
3. **ORM Texture** — assign `stone_wall_orm.png`

Done. Godot reads each channel automatically.

### Texture Import Settings

When you select a texture in the FileSystem dock, the Import dock shows its settings:

**Mode / Color Space:**
- Most textures: `Linear + VRAM Compressed` (fast GPU upload, good quality)
- Normal maps: `Normal Map + VRAM Compressed` — tells Godot this is a normal map so it handles the compression correctly (NormalMap flag in import settings)
- Albedo textures with alpha transparency: `Linear + VRAM Compressed` but also enable "Detect 3D" or set "Compress Mode" correctly

**Filtering:**
- `Linear` (default) — smooth filtering, good for most 3D textures
- `Nearest` — sharp, pixel-perfect filtering. Use for pixel art textures, retro aesthetics

**Mipmaps:**
- Enable "Generate Mipmaps" for any texture used on 3D objects. Mipmaps are pre-scaled versions of the texture used at different distances, preventing aliasing (shimmering) and improving performance.
- Disable mipmaps for UI textures.

**Compression:**
- `VRAM Compressed (S3TC/ETC2)` — Best option for most textures. Compressed on the GPU = faster rendering, less VRAM.
- `Lossless (PNG)` — No compression artifacts, but uses significantly more VRAM. Use only for textures where quality loss is visible (e.g., text, gradients).
- `Lossy (JPEG)` — Lossy but small file size. Generally avoid for game textures.

After changing import settings, click **Reimport** to apply.

### A Note on Texture Resolution

Don't import textures larger than you need. A rock on the ground that's 50cm × 50cm on screen doesn't need a 4096×4096 texture. Guidelines:
- Hero assets (player character, key props) — 1024×1024 or 2048×2048
- Environment details — 512×512 or 1024×1024
- Distant/background assets — 256×256

Oversized textures waste VRAM and don't look better once mipmaps kick in.

---

## 4. Lighting the Scene

### Why Lighting Matters

An unlit scene in Godot is completely black (unless you have WorldEnvironment ambient light). But "add a light and move on" produces flat, uninteresting results. Good lighting is the single biggest factor in how professional a scene looks. It costs relatively little time to set up and the visual payoff is enormous.

### DirectionalLight3D: The Sun

DirectionalLight3D simulates a light source infinitely far away — like the sun. All light rays are parallel, so the position of the node doesn't matter, only its rotation. The entire scene is lit from the same angle.

**Key properties:**
- **Light Color** — The color of sunlight. Pure white (1,1,1) for midday. Warm orange/yellow (1.0, 0.8, 0.5) for golden hour. Blue-ish (0.7, 0.8, 1.0) for overcast.
- **Light Energy** — Brightness multiplier. 1.0 is default. Go to 2.0+ for harsh desert sun, 0.3 for moonlight.
- **Shadow Enabled** — Turn on to cast shadows. DirectionalLight3D shadows cover the entire scene, so shadow map resolution matters.
- **Shadow Bias** — Prevents shadow acne (dark artifacts on surfaces). Default usually works, but bump it slightly if you see acne.
- **Shadow Blur** — Soft vs. hard shadow edges. 0 = hard edges, higher = softer.
- **Sky Contribution** — How much of the sky color bleeds into directional light calculations. Leave at default unless using PanoramaSkyMaterial.

**Rotation setup:**
- Rotation X of `-45` degrees is a roughly 45-degree sun angle — common starting point.
- Rotation Y rotates the sun's azimuth (which direction it comes from).
- For a day-night cycle, animate Rotation X from `-90` (sunrise) through `0` (midday) to `90` (sunset) to `180` (midnight).

```gdscript
# Position the sun at 3pm equivalent
@onready var sun: DirectionalLight3D = $DirectionalLight3D

func _ready() -> void:
    sun.rotation_degrees = Vector3(-35, 45, 0)
    sun.light_color = Color(1.0, 0.9, 0.7)  # Slightly warm
    sun.light_energy = 1.2
    sun.shadow_enabled = true
```

### OmniLight3D: Point Light

OmniLight3D emits light in all directions from a single point — like a lightbulb or torch. Position matters.

**Key properties:**
- **Light Color** — Flame = warm orange (1.0, 0.5, 0.1). Magic orb = blue-white (0.7, 0.9, 1.0).
- **Light Energy** — Brightness. 1.0 is default. Go to 0.3–0.5 for subtle fills, 3.0+ for dramatic effects.
- **Omni Range** — How far the light reaches before falling off to zero. Does not affect how bright the light is at the source, only its reach.
- **Omni Attenuation** — How quickly the light falls off with distance. Higher = faster falloff, more dramatic.
- **Shadow Mode** — Dual Paraboloid (faster, lower quality) or Cube Map (better quality, more expensive). Use Dual Paraboloid unless shadow quality is visually important.

```gdscript
# Create a campfire light effect
func setup_campfire_light(position: Vector3) -> OmniLight3D:
    var light := OmniLight3D.new()
    add_child(light)
    light.position = position + Vector3(0, 0.5, 0)
    light.light_color = Color(1.0, 0.4, 0.05)
    light.light_energy = 2.5
    light.omni_range = 8.0
    light.omni_attenuation = 1.5
    light.shadow_enabled = true
    return light
```

### SpotLight3D: Cone-Shaped Light

SpotLight3D emits light in a cone — flashlights, headlights, stage spotlights, overhead lamps. Both position and rotation matter.

**Key properties:**
- **Spot Range** — How far the cone reaches.
- **Spot Angle** — The angle of the cone in degrees. 10–15 for a tight flashlight beam. 30–45 for a wider floodlight.
- **Spot Angle Attenuation** — Falloff at the edge of the cone. Higher = sharper edge.
- **Spot Attenuation** — Distance falloff along the length of the cone.

```gdscript
# Set up an overhead lamp
func setup_overhead_lamp(position: Vector3) -> SpotLight3D:
    var lamp := SpotLight3D.new()
    add_child(lamp)
    lamp.position = position
    lamp.rotation_degrees = Vector3(-90, 0, 0)  # Point straight down
    lamp.light_color = Color(1.0, 0.95, 0.8)   # Warm white
    lamp.light_energy = 1.5
    lamp.spot_range = 6.0
    lamp.spot_angle = 35.0
    lamp.spot_angle_attenuation = 0.8
    lamp.shadow_enabled = false  # Save perf if not needed
    return lamp
```

### Shadow Settings and Performance

Shadows are expensive. Each shadow-casting light requires an additional render pass per shadow map. Rules:

- **Enable shadows on your main DirectionalLight3D** (the sun/moon). This is almost always worth it.
- **One or two OmniLight3D shadows** for important interactive lights (campfire, lamp the player is near).
- **Disable shadows on fill lights and decoration lights.** Players won't notice.
- **Shadow Map Size** — In Project Settings > Rendering > Lights and Shadows. Larger = sharper shadows, more VRAM.
- **Shadow Bias** — Slightly too low causes shadow acne. Too high causes "Peter Panning" where shadows detach from feet. Default is usually fine.

### Three-Point Lighting

Three-point lighting is the foundational technique from photography and film. It looks professional, is fast to set up, and works for everything from product shots to character showcases.

**Key Light** — The primary, brightest light. Creates the main shadows. Usually a DirectionalLight3D. Positioned to the front-side (45° off-center). This defines the "look" of the scene.

**Fill Light** — A softer light on the opposite side of the key light. Fills in the shadows so they're not completely dark. An OmniLight3D at lower energy (30–50% of key). No shadows needed.

**Rim/Back Light** — Behind and slightly above the subject. Creates a bright edge outline that separates the subject from the background. An OmniLight3D or SpotLight3D. Cool color (blue, cyan) often works well. Moderate energy.

```gdscript
# Three-point lighting setup for a character showcase
func setup_three_point_lighting(target_position: Vector3) -> void:
    # Key light — warm, directional, shadows on
    var key := DirectionalLight3D.new()
    add_child(key)
    key.rotation_degrees = Vector3(-30, 45, 0)
    key.light_color = Color(1.0, 0.95, 0.85)
    key.light_energy = 1.5
    key.shadow_enabled = true

    # Fill light — cooler, softer, no shadows
    var fill := OmniLight3D.new()
    add_child(fill)
    fill.position = target_position + Vector3(-4, 2, 4)
    fill.light_color = Color(0.7, 0.8, 1.0)  # Cool blue fill
    fill.light_energy = 0.6
    fill.omni_range = 12.0
    fill.shadow_enabled = false

    # Rim light — cool accent from behind
    var rim := SpotLight3D.new()
    add_child(rim)
    rim.position = target_position + Vector3(0, 3, -5)
    rim.look_at(target_position)
    rim.light_color = Color(0.6, 0.8, 1.0)
    rim.light_energy = 1.0
    rim.spot_range = 8.0
    rim.spot_angle = 40.0
    rim.shadow_enabled = false
```

---

## 5. WorldEnvironment and Sky

### The WorldEnvironment Node

Add a `WorldEnvironment` node to your scene. It requires an `Environment` resource to be assigned (create one in the Inspector: click the Environment property slot > New Environment). This resource controls every aspect of the scene's atmosphere.

Every scene should have a WorldEnvironment. Without it, you get no sky, no ambient light, no fog, no tone mapping. Your scene will look flat and under-lit.

### Background and Sky

**Background Mode** — What renders behind all geometry:
- `Sky` — Use a Sky resource (procedural or HDRI). The default and most common.
- `Color` — Solid color. Good for minimalist scenes or when the background isn't visible.
- `Canvas` — For 2D backgrounds (rare in 3D scenes).
- `Keep` — Don't clear, use with caution.

**Sky — ProceduralSkyMaterial**

The easiest starting point. Generates a sky from parameters, no texture needed.

Properties to configure:
- **Sky Top Color** — Deep blue for noon, darker blue for night.
- **Sky Horizon Color** — Lighter blue or orange at horizon.
- **Sky Curve** — How quickly the horizon color blends up to the top color.
- **Ground Bottom Color** — The color of the "ground" visible in the sky dome below the horizon. Usually a dark gray.
- **Ground Horizon Color** — Matches the sky horizon for smooth seams.
- **Sun Angle Max / Sun Curve** — Size and sharpness of the sun disk.

**Sky — PanoramaSkyMaterial**

For HDRIs (High Dynamic Range Images) — 360° panoramic sky photographs. These look incredibly realistic and also provide high-quality ambient lighting. Find free HDRIs at Poly Haven (polyhaven.com).

Assign the .hdr or .exr file to the Panorama property. Godot handles the rest.

### Ambient Light

Ambient light is the light that fills shadowed areas. Without it, shadows are completely black.

- **Source** — `Disabled` (no ambient), `Color` (flat color), `Sky` (tints ambient based on the sky color above and below), or `BG` (uses background color).
- **Sky Contribution** — When Source is Sky, how strongly the sky influences ambient. Usually 1.0.
- **Color** — When Source is Color, the fill color. A dark, slightly tinted color is often better than pure gray.
- **Energy** — Brightness of the ambient light.

For outdoor scenes: use `Sky` source with the same sky as your background. The sky contributes warm ambient from above and cooler reflected light from below, which looks natural.

For indoor scenes or night scenes: use `Color` source with a dark blue or dark purple to simulate the night sky's residual ambient.

### Tonemapping

Tone mapping converts HDR (values above 1.0) to the 0–1 range that displays can show. The choice dramatically affects the mood and style of your game.

- **Linear** — No tone mapping. Values above 1.0 clip to white. Raw, sometimes blown out. Good for non-photorealistic styles that want clean, flat colors.
- **Reinhard** — Gentle soft rolloff. Slightly washed out in highlights. Outdated but simple.
- **Filmic** — S-curve response. Warm, cinematic feel. Slightly crushed blacks, desaturated highlights. Popular for mid-fidelity games.
- **ACES (Academy Color Encoding System)** — Industry standard. High contrast, punchy colors, slightly warm. Used in AAA games and film. Recommended starting point.

**Exposure** — Overall brightness multiplier before tonemapping. Keep at 1.0 and adjust your lights instead, but useful for quick tweaks.

**White** — The HDR value that maps to pure white after tonemapping. Default 1.0 means standard range. Higher values let bright objects blow out more before they clip.

```gdscript
# Configure tone mapping for an outdoor scene
func setup_environment_tonemap(env: Environment) -> void:
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 1.0
    env.tonemap_white = 1.0
```

### Fog

Fog adds atmosphere and mystery. In Godot 4, there are two fog systems:

**Depth Fog (fog_enabled):**
- **Fog Color** — Usually a desaturated version of the sky's horizon color.
- **Fog Light Color** — Color of fog when lit (usually brighter than fog color).
- **Fog Density** — Overall density. Very small values (0.001–0.05) for subtle atmospheric haze.
- **Fog Aerial Perspective** — Blends the sky color into distant geometry. Very effective for outdoor scenes.

**Height Fog:**
- **Fog Height Enabled** — Fog that accumulates near the ground.
- **Fog Height Min/Max** — Altitude range of the height fog layer.
- **Fog Height Density** — How dense the ground-level fog is.

```gdscript
# Set up misty morning atmosphere
func setup_morning_fog(env: Environment) -> void:
    env.fog_enabled = true
    env.fog_light_color = Color(0.8, 0.9, 1.0)
    env.fog_density = 0.02
    env.fog_aerial_perspective = 0.3
    env.fog_height_enabled = true
    env.fog_height_min = -5.0
    env.fog_height_max = 3.0
    env.fog_height_density = 0.15
```

### Glow (Bloom)

Glow makes bright areas bleed light, simulating camera lens behavior. Required for emission materials to look like they're actually glowing.

- **Glow Enabled** — Toggle on.
- **Glow Intensity** — How strong the glow effect is.
- **Glow Strength** — How far the glow spreads.
- **Glow Bloom** — How much dimmer areas contribute to glow.
- **Glow Blend Mode** — `Additive` makes glow brighter. `Softlight` is more subtle. `Screen` is a popular middle ground.
- **Glow HDR Threshold** — Only pixels above this brightness level contribute to glow. Set to 1.0 to only apply to HDR-bright (over-exposed) areas.

Emission materials with `emission_energy_multiplier` above 2.0–3.0 will glow visibly when Glow is enabled.

### SSAO (Screen Space Ambient Occlusion)

SSAO darkens areas where surfaces are close together — corners, crevices, under objects. It's a huge visual quality boost for a moderate performance cost.

- **SSAO Enabled** — Toggle on.
- **SSAO Radius** — How large the occlusion radius is.
- **SSAO Intensity** — How dark the AO is.
- **SSAO Power** — Gamma curve for the AO falloff.
- **SSAO Detail** — Higher detail SSAO from SSIL integration.

### SSR (Screen Space Reflections)

Makes reflective surfaces (low roughness) reflect the scene geometry visible on screen.

- **SSR Enabled** — Toggle on.
- **SSR Max Steps** — Ray march steps. More = more accurate, more expensive.
- **SSR Fade In / Fade Out** — Smooth transition at screen edges.
- **SSR Depth Tolerance** — Avoids artifacts on thin geometry.

### SDFGI and VoxelGI

These are global illumination options — light bouncing between surfaces:

**SDFGI (Signed Distance Field Global Illumination)** — Dynamic GI. Updates as objects move. Good for open environments with a DirectionalLight3D sun. No pre-baking required. Enable in Environment > SDFGI.

**VoxelGI** — Baked GI for indoor scenes. Place a VoxelGI node in your scene, configure its bounds, and click "Bake" in the toolbar. Provides high-quality indirect light bouncing for static geometry.

**LightmapGI** — Fully baked lightmaps (stored in textures). Highest quality, zero runtime cost, but static — objects can't move. Best for shipped games that won't need dynamic lighting.

### A Complete Outdoor Environment Setup

```gdscript
# Complete environment resource configuration for a stylized outdoor scene
func create_outdoor_environment() -> Environment:
    var env := Environment.new()

    # Sky
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.1, 0.35, 0.8)
    sky_mat.sky_horizon_color = Color(0.7, 0.8, 1.0)
    sky_mat.sky_curve = 0.15
    sky_mat.ground_bottom_color = Color(0.1, 0.1, 0.1)
    sky_mat.ground_horizon_color = Color(0.4, 0.45, 0.5)
    sky.sky_material = sky_mat
    env.sky = sky
    env.background_mode = Environment.BG_SKY

    # Ambient
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_sky_contribution = 1.0
    env.ambient_light_energy = 0.5

    # Tonemap
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 1.0

    # Fog
    env.fog_enabled = true
    env.fog_light_color = Color(0.8, 0.9, 1.0)
    env.fog_density = 0.01
    env.fog_aerial_perspective = 0.2

    # Glow
    env.glow_enabled = true
    env.glow_intensity = 0.4
    env.glow_strength = 1.0
    env.glow_hdr_threshold = 1.0

    # SSAO
    env.ssao_enabled = true
    env.ssao_radius = 1.0
    env.ssao_intensity = 2.0

    return env
```

---

## 6. CSG for Prototyping

### What CSG Is and Isn't For

CSG (Constructive Solid Geometry) lets you combine primitive shapes using boolean operations. It's for **level blocking and prototyping**. It is not for final shipping geometry — CSG is slow at runtime, can produce non-optimal meshes, and doesn't support custom UVs well. The workflow is:

1. Use CSG to block out your level quickly.
2. Test the design. Move things around. Iterate.
3. When the layout is locked, replace CSG geometry with real modeled assets.

### CSG Node Types

- **CSGBox3D** — Rectangular box. Most used for floors, walls, ceilings.
- **CSGSphere3D** — Sphere primitive. Domes, round surfaces.
- **CSGCylinder3D** — Cylinder or cone. Pillars, towers.
- **CSGTorus3D** — Donut shape.
- **CSGPolygon3D** — Extrudes a 2D polygon along a path. Good for curved corridors and custom shapes.
- **CSGMesh3D** — Use any MeshInstance3D as a CSG shape. For custom boolean operations.
- **CSGCombiner3D** — Parent node that groups CSG children. Lets you apply operations relative to a parent group.

### CSG Operations

Each CSG node has an **Operation** property:

- **Union** — Adds the shape to the result. The default. Shapes fuse together into one solid.
- **Subtraction** — Cuts the shape out of the parent. Use this to make holes, doorways, windows, tunnels.
- **Intersection** — Only keeps the volume where the parent and child overlap.

The operations are hierarchical. A CSGBox3D with Operation = Subtraction cut out of a larger CSGBox3D creates a door-shaped hole.

### Building a Room with CSG

```
Room Layout with CSG:

1. CSGBox3D (floor)
   - Size: Vector3(10, 0.2, 10)
   - Operation: Union
   - Material: stone floor material

2. CSGBox3D (outer walls)
   - Size: Vector3(10, 4, 10)
   - Position: Vector3(0, 2, 0)
   - Operation: Union

3. CSGBox3D (inner hollow)
   - Size: Vector3(9.6, 4.2, 9.6)
   - Position: Vector3(0, 2, 0)
   - Operation: Subtraction  ← cuts interior out of outer walls

4. CSGBox3D (doorway)
   - Size: Vector3(1.5, 2.5, 0.5)
   - Position: Vector3(0, 1.25, -5)  ← in the north wall
   - Operation: Subtraction  ← cuts doorway opening

5. CSGBox3D (window)
   - Size: Vector3(1.2, 0.8, 0.5)
   - Position: Vector3(4, 2.5, 0)  ← in the east wall
   - Operation: Subtraction  ← cuts window opening
```

In the Scene tree, organize CSG nodes under a CSGCombiner3D root:
```
CSGCombiner3D (Room)
├── CSGBox3D (Floor)        [Union]
├── CSGBox3D (OuterWalls)   [Union]
├── CSGBox3D (InnerHollow)  [Subtraction]
├── CSGBox3D (Doorway)      [Subtraction]
└── CSGBox3D (Window)       [Subtraction]
```

### Collision from CSG

CSG nodes have a **Use Collision** property. When enabled, Godot automatically generates a StaticBody3D collision shape from the CSG geometry. This is fine for prototype geometry — you can walk around and test the layout without manually placing CollisionShape3D nodes.

Disable collision on CSG nodes that are purely visual (small details, decorations).

### CSG Materials

Assign materials to individual CSG nodes via their **Material** property. Each CSGBox3D can have its own material. For SubMesh operations, the child that's doing the cutting can have a different material (useful for door frame trim, window frames, etc.).

```gdscript
# Programmatic CSG room creation
func create_csg_room(size: Vector3, door_width: float = 1.5) -> CSGCombiner3D:
    var room := CSGCombiner3D.new()

    var outer := CSGBox3D.new()
    outer.size = size
    outer.position = Vector3(0, size.y / 2.0, 0)
    room.add_child(outer)

    var inner := CSGBox3D.new()
    inner.size = size - Vector3(0.4, 0.0, 0.4)
    inner.position = Vector3(0, size.y / 2.0 + 0.1, 0)
    inner.operation = CSGShape3D.OPERATION_SUBTRACTION
    room.add_child(inner)

    var doorway := CSGBox3D.new()
    doorway.size = Vector3(door_width, size.y * 0.75, 0.6)
    doorway.position = Vector3(0, size.y * 0.375, -size.z / 2.0)
    doorway.operation = CSGShape3D.OPERATION_SUBTRACTION
    room.add_child(doorway)

    room.use_collision = true
    return room
```

---

## 7. MeshLibrary and GridMap

### The Concept

GridMap is Godot's 3D tile editor. You define a MeshLibrary (a collection of tile meshes), then paint those tiles onto a 3D grid in the editor. It's like painting with 3D blocks. This is the fastest way to build modular 3D levels: corridors, dungeons, spaceships, urban environments made from repeating tile pieces.

### Creating Tile Scenes

Each tile is a regular Godot scene. Create one scene per tile type. A tile scene typically has:
- A root node (Node3D or StaticBody3D)
- A MeshInstance3D child (the visual mesh)
- A CollisionShape3D child if the tile needs physics (walls, floors)

For a basic dungeon set, you might create:
- `tile_floor.tscn` — 2m × 2m floor slab
- `tile_wall.tscn` — 2m × 2m × 2m wall section
- `tile_wall_corner.tscn` — corner wall piece
- `tile_door.tscn` — wall with a doorway opening
- `tile_pillar.tscn` — decorative column

The key constraint: **all tiles must be the same grid size** (e.g., 2m × 2m × 2m). If tiles are different sizes, they won't align on the grid.

### Converting to a MeshLibrary

Once you have your tile scenes:

1. Create a new empty scene.
2. Import or place all your tile meshes as children of the root node (each as a MeshInstance3D or a scene instance).
3. Go to **Scene > Convert To > MeshLibrary...**
4. Choose a save path and filename (e.g., `res://assets/dungeon_tiles.meshlib`).
5. Godot exports the MeshLibrary file.

The MeshLibrary captures the meshes, materials, and collision shapes from the tile scenes. You can update it by repeating this process.

### Using GridMap

1. Add a `GridMap` node to your level scene.
2. In the Inspector, assign your MeshLibrary to the **Mesh Library** property.
3. Select the GridMap node — a tile palette appears in the editor toolbar.
4. Click a tile in the palette to select it.
5. Click in the 3D viewport to paint tiles onto the grid.
6. Use the Y-axis handle to paint on different height levels.
7. Right-click to erase tiles.

**GridMap properties:**
- **Cell Size** — Must match your tile sizes. 2m tiles → Cell Size (2, 2, 2).
- **Cell Octant Size** — How many cells are grouped into one octant for culling. Default 8.
- **Center X/Y/Z** — Whether tiles are centered on grid cells or aligned to corners.
- **Collision Layer/Mask** — Physics layers for auto-generated collision.

### GridMap in Code

```gdscript
# Fill a GridMap area procedurally
func generate_corridor(grid_map: GridMap, start: Vector3i, length: int, direction: Vector3i) -> void:
    # Assuming tile ID 0 is floor, 1 is wall
    var floor_tile_id := 0
    var wall_tile_id := 1

    for i in range(length):
        var cell := start + direction * i
        # Place floor
        grid_map.set_cell_item(cell, floor_tile_id)
        # Place walls on sides (assuming direction is along Z axis)
        grid_map.set_cell_item(cell + Vector3i(1, 0, 0), wall_tile_id)
        grid_map.set_cell_item(cell + Vector3i(-1, 0, 0), wall_tile_id)

# Get which tile is at a position
func get_tile_at(grid_map: GridMap, world_pos: Vector3) -> int:
    var cell := grid_map.local_to_map(world_pos)
    return grid_map.get_cell_item(cell)
```

### When to Use GridMap vs Hand-Placed Scenes

**Use GridMap when:**
- Your level design is tile-based by nature (dungeon crawler, grid-based strategy game, Minecraft-style voxels)
- You have a modular tileset and want to paint quickly
- Level designers (not just programmers) need to edit the layout
- You want procedural generation of tile-based levels

**Use hand-placed scenes when:**
- Your world is organic/non-grid (natural landscapes, realistic cities)
- Tiles need more variation than a fixed library provides
- Performance is critical and you need fine-tuned draw call merging

---

## 8. Camera Basics for World Viewing

### Camera3D Essentials

Every scene needs a Camera3D for something to render. Properties that matter:

**FOV (Field of View)** — How wide the camera sees. In degrees, measured vertically.
- 70–75 — Standard first-person shooter range
- 60 — Cinematic, slightly telephoto
- 90+ — Wide angle, fisheye feel at extremes
- 30–40 — Used for isometric/overview cameras to compress depth

**Near/Far Planes** — The clipping range:
- **Near** — Objects closer than this disappear. Default 0.05m. Making this too small causes z-fighting (flickering between surfaces). Only go smaller if you need to.
- **Far** — Objects farther than this disappear. Default 4000m. Make this as small as your scene allows — large far planes reduce depth buffer precision.

**Projection:**
- **Perspective** — Normal 3D perspective (things closer look bigger). Default.
- **Orthogonal** — No perspective distortion. Objects the same size regardless of distance. Good for strategy games, 2.5D games, dioramas.

### Static Camera

The simplest camera — positioned once and aimed at a target.

```gdscript
extends Camera3D

@export var target: Node3D

func _ready() -> void:
    if target:
        look_at(target.global_position)
```

### Orbit Camera

An orbit camera rotates around a target point based on mouse input. Essential for level editing cameras, third-person cameras, product showcases.

```gdscript
extends Camera3D

@export var target: Node3D
@export var distance: float = 10.0
@export var orbit_speed: float = 0.5
var angle: float = 0.0

func _process(delta: float) -> void:
    if not target:
        return
    angle += orbit_speed * delta
    position = target.position + Vector3(
        sin(angle) * distance,
        distance * 0.5,
        cos(angle) * distance
    )
    look_at(target.position)
```

### Interactive Orbit Camera (Mouse-Controlled)

```gdscript
extends Camera3D

@export var target_position: Vector3 = Vector3.ZERO
@export var distance: float = 10.0
@export var mouse_sensitivity: float = 0.3
@export var zoom_speed: float = 1.5
@export var min_distance: float = 2.0
@export var max_distance: float = 50.0

var yaw: float = 0.0    # Horizontal rotation
var pitch: float = -30.0  # Vertical rotation (negative = looking down)
var is_orbiting: bool = false

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_MIDDLE:
            is_orbiting = event.pressed
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            distance = clampf(distance - zoom_speed, min_distance, max_distance)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            distance = clampf(distance + zoom_speed, min_distance, max_distance)

    if event is InputEventMouseMotion and is_orbiting:
        yaw -= event.relative.x * mouse_sensitivity
        pitch -= event.relative.y * mouse_sensitivity
        pitch = clampf(pitch, -89.0, -5.0)  # Prevent flipping

func _process(_delta: float) -> void:
    var yaw_rad := deg_to_rad(yaw)
    var pitch_rad := deg_to_rad(pitch)
    position = target_position + Vector3(
        sin(yaw_rad) * cos(pitch_rad) * distance,
        sin(pitch_rad) * distance,
        cos(yaw_rad) * cos(pitch_rad) * distance
    )
    look_at(target_position)
```

### Follow Camera

A camera that smoothly follows a target, useful for overview and showcase cameras.

```gdscript
extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 5, 8)
@export var follow_speed: float = 5.0
@export var look_speed: float = 10.0

func _process(delta: float) -> void:
    if not target:
        return
    var desired_pos := target.global_position + offset
    global_position = global_position.lerp(desired_pos, follow_speed * delta)
    look_at(target.global_position)
```

---

## 9. Practical Scene Composition

### Building a Complete Environment

A well-organized environment scene has a clear structure. Here's a recommended node organization:

```
World (Node3D)
├── WorldEnvironment
├── DirectionalLight3D (Sun)
├── Ground (StaticBody3D)
│   ├── MeshInstance3D (terrain mesh)
│   └── CollisionShape3D
├── Structures (Node3D)  ← imported buildings, ruins, walls
│   ├── house.glb instance
│   └── wall_section.glb instance
├── Props (Node3D)  ← smaller detail objects
│   ├── rock_01.glb instance
│   ├── tree_01.glb instance
│   └── barrel.glb instance
├── Lighting (Node3D)  ← OmniLights, SpotLights
│   ├── torch_light_01 (OmniLight3D)
│   └── torch_light_02 (OmniLight3D)
├── Particles (Node3D)  ← GPUParticles3D effects
│   └── campfire_smoke
└── Camera3D
```

### Ground Plane

The floor of your scene is almost always a StaticBody3D with a flat MeshInstance3D and a matching CollisionShape3D:

```gdscript
# Creating a ground plane in code
func create_ground(size: float, material: StandardMaterial3D) -> StaticBody3D:
    var ground := StaticBody3D.new()

    var mesh_instance := MeshInstance3D.new()
    var plane_mesh := PlaneMesh.new()
    plane_mesh.size = Vector2(size, size)
    mesh_instance.mesh = plane_mesh
    if material:
        mesh_instance.set_surface_override_material(0, material)
    ground.add_child(mesh_instance)

    var col := CollisionShape3D.new()
    var box_shape := BoxShape3D.new()
    box_shape.size = Vector3(size, 0.1, size)
    col.shape = box_shape
    col.position = Vector3(0, -0.05, 0)
    ground.add_child(col)

    return ground
```

### Prop Scattering

Placing props one by one is tedious. Script it. This is also the foundation for procedural world generation:

```gdscript
@export var prop_scene: PackedScene
@export var count: int = 50
@export var area_size: float = 20.0

func _ready() -> void:
    for i in count:
        var prop := prop_scene.instantiate()
        prop.position = Vector3(
            randf_range(-area_size, area_size),
            0,
            randf_range(-area_size, area_size)
        )
        prop.rotation.y = randf() * TAU
        prop.scale = Vector3.ONE * randf_range(0.8, 1.2)
        add_child(prop)
```

For more sophisticated scattering — avoiding overlaps, placing on terrain, respecting exclusion zones:

```gdscript
@export var prop_scene: PackedScene
@export var count: int = 30
@export var area_size: float = 20.0
@export var min_distance: float = 2.0  # Minimum spacing between props

var placed_positions: Array[Vector3] = []

func _ready() -> void:
    var attempts := 0
    var placed := 0

    while placed < count and attempts < count * 10:
        attempts += 1
        var candidate := Vector3(
            randf_range(-area_size, area_size),
            0,
            randf_range(-area_size, area_size)
        )

        if _is_too_close(candidate):
            continue

        var prop := prop_scene.instantiate()
        prop.position = candidate
        prop.rotation.y = randf() * TAU
        prop.scale = Vector3.ONE * randf_range(0.8, 1.2)
        add_child(prop)
        placed_positions.append(candidate)
        placed += 1

func _is_too_close(pos: Vector3) -> bool:
    for existing in placed_positions:
        if pos.distance_to(existing) < min_distance:
            return true
    return false
```

### Performance Considerations

**Draw calls** — Each unique material + mesh combination is a draw call. Keep materials shared where possible. Duplicate geometry with the same material merges automatically via instancing.

**Mesh merging** — If you have many static props that never move, consider merging their meshes using Godot's MeshMergingPlugin or by baking in Blender. Fewer meshes = fewer draw calls.

**Visibility ranges** — MeshInstance3D has **Visibility Range Begin/End** properties. Set End to, say, 50m for small props. They disappear at distance, saving GPU time. This is manual LOD.

**HLOD (Hierarchical Level of Detail)** — In Godot 4.1+, VisibilityNotifier3D and `use_dynamic_draw_distance` in WorldEnvironment can help manage distant object visibility.

**Occlusion culling** — Godot 4 supports occlusion culling via the OccluderInstance3D node. Place occluder shapes behind large solid objects (buildings, terrain) to prevent rendering geometry hidden behind them.

---

## 10. Code Walkthrough: Stylized Environment Diorama

### Project Overview

You'll build a campsite diorama:
- Ground plane with grass material
- Trees and rocks from Kenney Nature Kit
- A campfire with OmniLight3D and particle smoke
- A tent and log props
- Three-point lighting (sun + campfire fill + rim)
- WorldEnvironment with sky, fog, and glow
- A day-night cycle that rotates the sun and adjusts the atmosphere

### File Structure

```
res://
├── assets/
│   └── nature/
│       ├── tree_oak.glb
│       ├── rock_large.glb
│       ├── tent.glb
│       ├── log.glb
│       └── campfire.glb
├── materials/
│   ├── grass.tres
│   └── campfire_glow.tres
├── scenes/
│   ├── world.tscn          ← main scene
│   └── campfire.tscn       ← campfire prefab
└── scripts/
    ├── world.gd
    ├── day_night_cycle.gd
    └── prop_scatterer.gd
```

### Scene Tree (world.tscn)

```
World (Node3D) [world.gd attached]
├── WorldEnvironment
├── DayNightCycle (Node3D) [day_night_cycle.gd attached]
│   └── Sun (DirectionalLight3D)
├── Ground (StaticBody3D)
│   ├── GroundMesh (MeshInstance3D)
│   └── GroundCollision (CollisionShape3D)
├── Environment (Node3D)
│   ├── tree_oak instance (×5)
│   ├── rock_large instance (×8)
│   └── PropScatterer (Node3D) [prop_scatterer.gd]
├── Campfire (campfire.tscn instance)
├── Tent (tent.glb instance)
├── FillLight (OmniLight3D)  ← rim/back light
└── Camera3D [orbit camera script]
```

### The Campfire Scene (campfire.tscn)

```
Campfire (Node3D)
├── CampfireMesh (MeshInstance3D)  ← campfire.glb
├── FlameLight (OmniLight3D)
│   └── FlameFlicker (script)
└── Smoke (GPUParticles3D)
```

Campfire script — a subtle flicker on the OmniLight3D:

```gdscript
# campfire_flicker.gd
extends OmniLight3D

@export var base_energy: float = 2.5
@export var flicker_amount: float = 0.4
@export var flicker_speed: float = 8.0

var time: float = 0.0

func _process(delta: float) -> void:
    time += delta
    # Layered sine waves for organic flicker
    var flicker := sin(time * flicker_speed) * 0.5
    flicker += sin(time * flicker_speed * 1.7 + 0.5) * 0.3
    flicker += sin(time * flicker_speed * 0.6 + 1.2) * 0.2
    light_energy = base_energy + flicker * flicker_amount
```

### The Day-Night Cycle Script

```gdscript
# day_night_cycle.gd
extends Node3D

@export var sun: DirectionalLight3D
@export var environment: WorldEnvironment
@export var cycle_speed: float = 0.1
var time_of_day: float = 0.3  # 0=midnight, 0.5=noon, 1=midnight

# Sky colors at different times of day
const NOON_SKY_TOP := Color(0.1, 0.35, 0.8)
const NOON_SKY_HORIZON := Color(0.7, 0.8, 1.0)
const SUNSET_SKY_TOP := Color(0.25, 0.15, 0.5)
const SUNSET_SKY_HORIZON := Color(1.0, 0.4, 0.1)
const NIGHT_SKY_TOP := Color(0.02, 0.02, 0.08)
const NIGHT_SKY_HORIZON := Color(0.05, 0.05, 0.15)

func _process(delta: float) -> void:
    time_of_day = fmod(time_of_day + cycle_speed * delta, 1.0)
    update_sun()
    update_environment()

func update_sun() -> void:
    # Rotate sun: 0.5 (noon) = straight up, 0.0/1.0 (midnight) = straight down
    var angle := time_of_day * TAU - PI / 2.0
    sun.rotation.x = angle

    # Energy: full at noon, zero at night (clamped to avoid negative)
    var energy := clampf(sin(time_of_day * PI), 0.0, 1.0)
    sun.light_energy = energy * 1.5

    # Color: warm at golden hour (low energy), white at noon
    if energy > 0.0:
        var warmth := 1.0 - energy  # 1.0 at horizon, 0.0 at noon
        sun.light_color = Color(
            1.0,
            1.0 - warmth * 0.3,  # Slightly less green at horizon
            1.0 - warmth * 0.6   # Much less blue at horizon (warm orange)
        )

func update_environment() -> void:
    if not environment or not environment.environment:
        return

    var env: Environment = environment.environment
    var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
    if not sky_mat:
        return

    # Calculate sun elevation (0 = midnight/horizon, 1 = noon)
    var sun_height := clampf(sin(time_of_day * PI), 0.0, 1.0)
    # Sunset factor: high when sun is low
    var sunset_factor := clampf(1.0 - sun_height * 2.5, 0.0, 1.0)
    var night_factor := clampf(1.0 - sin(time_of_day * PI) * 2.0, 0.0, 1.0)

    # Interpolate sky colors
    var sky_top: Color
    var sky_horizon: Color

    if sun_height > 0.0:
        # Blend from sunset to noon
        sky_top = SUNSET_SKY_TOP.lerp(NOON_SKY_TOP, sun_height)
        sky_horizon = SUNSET_SKY_HORIZON.lerp(NOON_SKY_HORIZON, sun_height)
    else:
        sky_top = NIGHT_SKY_TOP
        sky_horizon = NIGHT_SKY_HORIZON

    sky_mat.sky_top_color = sky_top
    sky_mat.sky_horizon_color = sky_horizon

    # Ambient energy drops at night
    env.ambient_light_energy = 0.1 + sun_height * 0.5

    # Fog thickens slightly at night and becomes bluer
    env.fog_density = 0.008 + (1.0 - sun_height) * 0.015
    env.fog_light_color = Color(
        0.6 + sun_height * 0.2,
        0.7 + sun_height * 0.2,
        0.8 + sun_height * 0.2
    )
```

### The World Script (world.gd)

```gdscript
# world.gd
extends Node3D

@export var tree_scene: PackedScene
@export var rock_scene: PackedScene

@onready var props_parent: Node3D = $Environment
@onready var day_night: Node3D = $DayNightCycle
@onready var world_env: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
    _setup_ground_material()
    _scatter_environment_props()

func _setup_ground_material() -> void:
    var ground_mesh: MeshInstance3D = $Ground/GroundMesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.25, 0.45, 0.15)  # Grass green
    mat.roughness = 0.95
    mat.metallic = 0.0
    ground_mesh.set_surface_override_material(0, mat)

func _scatter_environment_props() -> void:
    # Trees in a ring around the campfire
    if tree_scene:
        var tree_positions := [
            Vector3(-6, 0, -5),
            Vector3(5, 0, -7),
            Vector3(-8, 0, 3),
            Vector3(7, 0, 4),
            Vector3(0, 0, -9),
        ]
        for pos in tree_positions:
            var tree := tree_scene.instantiate()
            tree.position = pos
            tree.rotation.y = randf() * TAU
            tree.scale = Vector3.ONE * randf_range(0.9, 1.3)
            props_parent.add_child(tree)

    # Rocks scattered around
    if rock_scene:
        for i in 8:
            var rock := rock_scene.instantiate()
            rock.position = Vector3(
                randf_range(-10, 10),
                0,
                randf_range(-10, 10)
            )
            rock.rotation.y = randf() * TAU
            rock.scale = Vector3.ONE * randf_range(0.5, 1.5)
            props_parent.add_child(rock)

func _input(event: InputEvent) -> void:
    # Speed up/slow down time of day for testing
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_EQUAL:
            day_night.cycle_speed += 0.05
        elif event.keycode == KEY_MINUS:
            day_night.cycle_speed = maxf(0.0, day_night.cycle_speed - 0.05)
        elif event.keycode == KEY_0:
            day_night.cycle_speed = 0.0  # Pause
```

---

## API Quick Reference

### StandardMaterial3D

| Property | Type | Description |
|---|---|---|
| `albedo_color` | Color | Base color tint |
| `albedo_texture` | Texture2D | Base color texture |
| `roughness` | float | 0=mirror, 1=matte |
| `roughness_texture` | Texture2D | Per-pixel roughness |
| `metallic` | float | 0=dielectric, 1=metal |
| `metallic_texture` | Texture2D | Per-pixel metallic |
| `specular` | float | Non-metal specular (default 0.5) |
| `emission_enabled` | bool | Enable self-illumination |
| `emission` | Color | Emission color |
| `emission_energy_multiplier` | float | Emission brightness |
| `emission_texture` | Texture2D | Per-pixel emission |
| `normal_enabled` | bool | Enable normal mapping |
| `normal_map` | Texture2D | Normal map texture |
| `normal_scale` | float | Normal map strength |
| `transparency` | TransparencyMode | Alpha blending mode |
| `alpha_scissor_threshold` | float | Cutout alpha threshold |

### ORMMaterial3D

| Property | Type | Description |
|---|---|---|
| `albedo_color` | Color | Base color tint |
| `albedo_texture` | Texture2D | Base color texture |
| `orm_texture` | Texture2D | Packed ORM texture (R=AO, G=Roughness, B=Metallic) |
| `normal_enabled` | bool | Enable normal mapping |
| `normal_map` | Texture2D | Normal map texture |

### DirectionalLight3D

| Property | Type | Description |
|---|---|---|
| `light_color` | Color | Light color |
| `light_energy` | float | Brightness multiplier |
| `shadow_enabled` | bool | Cast shadows |
| `shadow_bias` | float | Prevent shadow acne |
| `shadow_blur` | float | Shadow softness |
| `sky_mode` | SkyMode | How sky contributes to light |
| `directional_shadow_mode` | ShadowMode | Orthogonal, PSSM 2-split, PSSM 4-split |
| `directional_shadow_max_distance` | float | Max shadow distance |

### OmniLight3D

| Property | Type | Description |
|---|---|---|
| `light_color` | Color | Light color |
| `light_energy` | float | Brightness multiplier |
| `omni_range` | float | Light radius |
| `omni_attenuation` | float | Distance falloff rate |
| `shadow_enabled` | bool | Cast shadows |
| `omni_shadow_mode` | ShadowMode | Dual Paraboloid or Cube |

### SpotLight3D

| Property | Type | Description |
|---|---|---|
| `light_color` | Color | Light color |
| `light_energy` | float | Brightness multiplier |
| `spot_range` | float | Light cone length |
| `spot_angle` | float | Half-angle of cone (degrees) |
| `spot_angle_attenuation` | float | Cone edge softness |
| `spot_attenuation` | float | Distance falloff |
| `shadow_enabled` | bool | Cast shadows |

### Environment Resource

| Property | Type | Description |
|---|---|---|
| `background_mode` | BGMode | Sky, Color, Canvas, Keep |
| `sky` | Sky | Sky resource |
| `tonemap_mode` | ToneMapper | Linear, Reinhard, Filmic, ACES |
| `tonemap_exposure` | float | Pre-tonemap exposure |
| `ambient_light_source` | AmbientSource | Disabled, Color, Sky, BG |
| `ambient_light_energy` | float | Ambient light brightness |
| `ambient_light_color` | Color | Ambient color (when source=Color) |
| `fog_enabled` | bool | Enable depth fog |
| `fog_density` | float | Fog thickness |
| `fog_light_color` | Color | Lit fog color |
| `fog_aerial_perspective` | float | Sky color blending in fog |
| `fog_height_enabled` | bool | Enable height fog |
| `fog_height_min` | float | Lower bound of height fog |
| `fog_height_max` | float | Upper bound of height fog |
| `glow_enabled` | bool | Enable bloom/glow |
| `glow_intensity` | float | Glow strength |
| `glow_hdr_threshold` | float | Min brightness for glow |
| `ssao_enabled` | bool | Screen space ambient occlusion |
| `ssao_radius` | float | AO sample radius |
| `ssr_enabled` | bool | Screen space reflections |
| `sdfgi_enabled` | bool | SDFGI global illumination |

### WorldEnvironment

| Property | Type | Description |
|---|---|---|
| `environment` | Environment | The Environment resource |
| `camera_attributes` | CameraAttributes | Exposure, DOF settings |

### Camera3D

| Property | Type | Description |
|---|---|---|
| `fov` | float | Vertical field of view |
| `near` | float | Near clipping plane |
| `far` | float | Far clipping plane |
| `projection` | ProjectionType | Perspective or Orthogonal |
| `size` | float | Orthogonal view size |
| `current` | bool | Is this the active camera |

Key methods:
- `look_at(target: Vector3)` — Aim at a world position
- `project_ray_origin(screen_point: Vector2)` — Ray from screen point
- `project_ray_normal(screen_point: Vector2)` — Ray direction

### CSG Nodes

| Node | Description |
|---|---|
| `CSGBox3D` | Box primitive. Properties: size (Vector3) |
| `CSGSphere3D` | Sphere. Properties: radius, radial_segments |
| `CSGCylinder3D` | Cylinder/cone. Properties: radius, height, cone |
| `CSGTorus3D` | Torus. Properties: inner_radius, outer_radius |
| `CSGPolygon3D` | Extruded polygon |
| `CSGMesh3D` | Boolean with custom mesh |
| `CSGCombiner3D` | Groups CSG children |

Common CSG properties:
- `operation`: Union, Subtraction, Intersection
- `use_collision`: Auto-generate StaticBody3D collision
- `material`: Surface material

### GridMap

| Property/Method | Type | Description |
|---|---|---|
| `mesh_library` | MeshLibrary | The tile library |
| `cell_size` | Vector3 | Size of each grid cell |
| `set_cell_item(pos, item, orientation)` | void | Place a tile |
| `get_cell_item(pos)` | int | Get tile at position |
| `local_to_map(pos)` | Vector3i | World pos to grid cell |
| `map_to_local(pos)` | Vector3 | Grid cell to world pos |
| `get_used_cells()` | Array[Vector3i] | All occupied cells |
| `clear()` | void | Remove all tiles |
| `INVALID_CELL_ITEM` | int | Returned for empty cells |

---

## Common Pitfalls

### 1. Black Scene (No Lighting)

**WRONG:** Creating a scene and placing objects without adding any lights or WorldEnvironment, then wondering why everything is black.

```
# Bad: empty scene with no lights
WorldScene
└── tree (MeshInstance3D)  # Completely invisible — black void
```

**RIGHT:** Always start by adding a DirectionalLight3D and a WorldEnvironment. These two nodes give you a functional lit scene to work from.

```
# Good: minimal working lit scene
WorldScene
├── WorldEnvironment  # Sky + ambient light
├── DirectionalLight3D  # Sun
└── tree (MeshInstance3D)  # Visible now
```

### 2. Flat-Looking Materials (Default Roughness)

**WRONG:** Leaving all materials at their defaults (roughness 1.0, no normal maps). Everything looks equally matte and flat. A polished marble floor and a concrete wall look identical.

```gdscript
# Bad: default material on everything
var mat := StandardMaterial3D.new()
mat.albedo_color = Color(0.9, 0.9, 0.9)
# roughness defaults to 1.0 — looks like chalk
```

**RIGHT:** Set roughness deliberately for each material type. Add normal maps to any surface that should have texture detail.

```gdscript
# Good: material properties set intentionally
var marble_mat := StandardMaterial3D.new()
marble_mat.albedo_color = Color(0.95, 0.93, 0.90)
marble_mat.roughness = 0.15        # Shiny, polished
marble_mat.metallic = 0.0
marble_mat.normal_enabled = true
marble_mat.normal_map = marble_normal_texture
marble_mat.normal_scale = 0.5      # Subtle veining detail

var concrete_mat := StandardMaterial3D.new()
concrete_mat.albedo_color = Color(0.6, 0.6, 0.6)
concrete_mat.roughness = 0.9       # Very matte
concrete_mat.metallic = 0.0
```

### 3. Bloated Asset Imports (Embedded Textures)

**WRONG:** Importing a 200MB GLB file that has all its textures embedded in the binary. This creates a slow import, bloats your project, and prevents texture reuse.

```
# Bad workflow:
1. Export from Blender with all textures embedded in .glb
2. Drag 200MB .glb into Godot
3. Every texture change requires re-exporting the entire model
```

**RIGHT:** Keep textures separate. Export GLB with textures as external files (or extract them). Import textures once into Godot and reference them from materials.

```
# Good workflow:
1. Export model as .glb with textures as separate files (in same folder)
2. Drag .glb AND texture files into Godot
3. Godot imports model and textures separately
4. Textures can be shared between multiple models
5. Change a texture once → all models using it update

Import settings: Set Material Storage to "Files" to extract materials
as .tres files that you can then customize without re-exporting.
```

### 4. Too Many Shadow-Casting Lights

**WRONG:** Enabling shadows on every OmniLight3D in the scene. Each shadow-casting OmniLight3D requires a full extra render pass (or two for dual paraboloid shadows). 10 shadow lights = 10x the render cost.

```
# Bad: shadows on every decorative light
torch_01.shadow_enabled = true
torch_02.shadow_enabled = true
torch_03.shadow_enabled = true
# ... 20 more torches, all casting shadows
# GPU is crying
```

**RIGHT:** Only enable shadows on lights that are critical for the visual read. Use non-shadow lights for atmosphere and fill. Bake static lighting where possible.

```
# Good: strategic shadow usage
sun.shadow_enabled = true            # Always — it's the key light
campfire_main.shadow_enabled = true  # One primary interactive light

# All decorative/fill lights: no shadows
for torch in distant_torches:
    torch.shadow_enabled = false     # Still visible, no shadow cost
```

### 5. No WorldEnvironment (Flat, Dead-Looking Scene)

**WRONG:** Building a scene without a WorldEnvironment node. The result: no sky (black void behind everything), no ambient light (shadows are pitch black), no fog, no glow on emission materials — the scene looks like a tech demo from 1995.

```
# Bad: no WorldEnvironment
WorldScene
├── DirectionalLight3D  # Only lit surfaces. Shadows are jet black.
└── geometry...         # No sky visible. No atmosphere. No mood.
```

**RIGHT:** Add WorldEnvironment with a configured Environment resource as one of the first things in every scene. The sky alone adds ambient light, visible background, and atmosphere.

```
# Good: WorldEnvironment as a foundational element
WorldScene
├── WorldEnvironment  # Sky, ambient, tonemap, fog, glow — all configured
│   └── Environment resource:
│       ├── Background: Sky (ProceduralSkyMaterial)
│       ├── Ambient: Source=Sky, Energy=0.6
│       ├── Tonemap: ACES
│       ├── Fog: Enabled, density=0.01
│       └── Glow: Enabled, intensity=0.3
├── DirectionalLight3D
└── geometry...
```

---

## Exercises

### Exercise 1: Asset Import and Emissive Materials (30–45 minutes)

Download 3 free asset packs from Kenney (kenney.nl) — choose any 3 that interest you. Build a small scene with at least 8 imported props and intentional lighting.

Requirements:
- At least one asset must have a custom material you created (not the default imported material)
- Add one emissive object (glowing crystal, neon sign, illuminated panel — your choice)
- Configure WorldEnvironment with a sky, ambient, and glow enabled so the emission actually glows
- Use at least two light types (e.g., DirectionalLight3D + OmniLight3D)

Stretch goal: Add a flicker script to the OmniLight3D near your emissive object.

### Exercise 2: Three Environment Presets (45–60 minutes)

Create 3 distinct Environment resources as `.tres` files:

1. **Sunny Day** — Warm ProceduralSkyMaterial, bright DirectionalLight3D, minimal fog, ACES tonemap
2. **Foggy Dusk** — Orange/purple sky, dim light, heavy fog, FilmicToneMapper
3. **Night** — Dark sky with slight blue ambient, very dim or no directional light, thick height fog, stars (use a PanoramaSkyMaterial with a star panorama from Poly Haven)

Wire up keyboard shortcuts to switch between them:

```gdscript
@export var day_env: Environment
@export var dusk_env: Environment
@export var night_env: Environment

@onready var world_env: WorldEnvironment = $WorldEnvironment

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_1: world_env.environment = day_env
            KEY_2: world_env.environment = dusk_env
            KEY_3: world_env.environment = night_env
```

Document (in a comment in the script) what makes each environment feel like its time of day.

### Exercise 3: GridMap Dungeon (60–90 minutes)

Build a modular dungeon layout using GridMap.

**Step 1 — Create 4 tile scenes:**
- `tile_floor.tscn` — 2m × 0.2m × 2m floor slab with stone material
- `tile_wall.tscn` — 2m × 2m × 0.3m wall with stone material
- `tile_corner.tscn` — L-shaped corner piece
- `tile_doorway.tscn` — Wall with a 1m × 2m opening (use CSG subtraction)

Each tile should have a StaticBody3D root, MeshInstance3D child, and CollisionShape3D child.

**Step 2 — Build the MeshLibrary:**
- Create a scene with all 4 tiles as children
- Use Scene > Convert To > MeshLibrary
- Save as `res://assets/dungeon_tiles.meshlib`

**Step 3 — Paint the dungeon:**
- Add a GridMap node to a new scene
- Assign the MeshLibrary
- Paint at least 3 connected rooms with corridors between them

**Step 4 — Light it:**
- Add SpotLight3D nodes (torches on walls) with warm orange color
- Disable shadows on most torches, enable on one or two key ones
- Add WorldEnvironment with a dark ambient (near-black with slight blue tint) and glow enabled
- Add OmniLight3D at the entrance that's slightly brighter — a sense of "you are here"

Stretch goal: Write a script that iterates over all GridMap cells and places a torch OmniLight3D at every wall tile position.

---

## Key Takeaways

1. **GLTF is the standard.** Drag `.glb` files into Godot and they just work. Use separate textures rather than embedding them. Import settings that matter most: generate tangents, enable mipmaps, set material storage to "Files" for customizable materials.

2. **StandardMaterial3D is your workhorse.** Albedo, roughness, metallic, emission, and normal maps cover 90% of material needs. Set roughness deliberately — don't leave it at 1.0 for everything. Add normal maps to any surface that should look textured.

3. **Lighting makes or breaks your scene.** Three-point lighting (key + fill + rim) is the foundation. DirectionalLight3D for sun, OmniLight3D for point sources, SpotLight3D for cones. Only enable shadows on lights that need them — shadow cost adds up fast.

4. **WorldEnvironment + Environment resource controls the atmosphere.** Sky, fog, tonemap, ambient light, glow, SSAO — all here. Every scene needs one. ACES tonemapping is a reliable default. Enable glow if you're using emission materials.

5. **CSG is for prototyping, not shipping.** Block out your level fast with CSGBox3D and boolean subtraction. Test the layout. When the design is locked, replace with real assets.

6. **GridMap + MeshLibrary is powerful for modular tile-based level building.** Build your tileset as individual scenes, convert to MeshLibrary, paint in the editor. Handles collision automatically. Good for dungeons, cities, spaceships — anything modular.

7. **A day-night cycle is just rotating DirectionalLight3D and tweaking Environment properties over time.** `time_of_day * TAU` gives you the full rotation. `sin(time_of_day * PI)` gives you 0 at night and 1 at noon — use it to drive light energy, sky color, fog density, and ambient.

---

## What's Next

Your world looks good. Intentionally lit, atmospheric, and populated with real assets. Now it's time to make things move and collide.

**[Module 4: Physics & Character Controllers](module-04-physics-character-controllers.md)** covers:
- RigidBody3D, StaticBody3D, CharacterBody3D — which to use and when
- CollisionShape3D and the right shape for each object
- PhysicsBody layers and masks
- Writing a character controller with `move_and_slide()`
- Jumping, gravity, slopes, and friction
- Projectile physics and forces

Your environment is the stage. Module 4 gives you actors.

---

**[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)**
