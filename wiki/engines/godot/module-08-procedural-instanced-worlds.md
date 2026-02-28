# Module 8: Procedural & Instanced Worlds

**Part of:** [Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)
**Estimated study time:** 8–12 hours
**Prerequisites:** [Module 7: Post-Processing & VFX](module-07-post-processing-vfx.md)

---

## Overview

Hand-placing every tree, rock, and grass blade in a game world doesn't scale. For stylized open worlds, roguelikes, and exploration games, you need procedural generation — algorithms that create content at runtime. Noise functions give you natural-looking terrain. MultiMeshInstance3D lets you render thousands of objects in a single draw call. Chunk loading streams the world as you move through it.

This module covers Godot's built-in noise system (FastNoiseLite), procedural mesh generation (SurfaceTool and ArrayMesh), mass instancing (MultiMeshInstance3D), LOD (level of detail), and chunked world streaming. You'll also write vertex shaders for wind animation on instanced grass.

By the end, you'll build an infinite procedural landscape — heightmap terrain with biome coloring, thousands of instanced trees and grass swaying in the wind, chunks that load and unload as you move, and fog to hide the draw distance. This is the foundation that open-world games, survival games, and infinite runners are built on.

---

## 1. FastNoiseLite: Godot's Built-in Noise

### What Noise Is and Why It Matters

Noise generates coherent random values — values that are random but smoothly varying. If you call `randf()` at every position in a grid you get pure chaos: no hills, no valleys, no structure. Noise is different. Adjacent positions return similar values, so the output forms natural-looking gradients. Zoom out and you see rolling hills. Zoom in and you see fine surface detail.

Godot ships `FastNoiseLite` as a built-in `Resource`. You can create it in code or in the inspector, configure it, and sample it at any 2D or 3D position.

### Noise Types

FastNoiseLite offers four main noise types:

**Simplex / SimplexSmooth** — The default choice for terrain and clouds. Simplex is a modern improvement on Perlin that has fewer directional artifacts and is faster to compute. SimplexSmooth applies extra smoothing for an even softer result.

**Perlin** — The classic. Slightly different character from Simplex — a bit more "ridge-like." Many game developers learned noise on Perlin, so you'll recognize its look from countless tutorials.

**Cellular (Voronoi)** — Divides space into irregular cells, producing cracked ground, dried-mud patterns, organic cell structures, and alien terrain. Very different from Simplex/Perlin. Excellent when you need a non-grassy landscape.

**Value** — Each grid point gets a random value, and the space between is interpolated. More blocky and angular than Simplex. Use it when you want a Minecraft-ish stepped-terrain feel.

### Key Configuration Parameters

```gdscript
var noise := FastNoiseLite.new()
noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

# Frequency: how "zoomed in" the noise is.
# Low frequency (0.005) = wide, gentle hills.
# High frequency (0.1) = tight, choppy features.
noise.frequency = 0.01

# Fractal type: how multiple "octaves" are layered.
# FRACTAL_NONE: single layer, smooth.
# FRACTAL_FBM: Fractal Brownian Motion — most natural terrain look.
# FRACTAL_RIDGED: inverts some octaves for sharp ridges, good for mountains.
# FRACTAL_PING_PONG: alternating, produces unusual alien-like terrain.
noise.fractal_type = FastNoiseLite.FRACTAL_FBM

# Octaves: how many detail layers to stack.
# 1 = smooth blobs.
# 4-6 = natural terrain with small surface variation.
# 8+ = extremely detailed but expensive.
noise.fractal_octaves = 4

# Lacunarity: how much each octave's frequency multiplies.
# 2.0 is standard: each octave is 2x finer than the last.
noise.fractal_lacunarity = 2.0

# Gain: how much each octave's amplitude multiplies.
# 0.5 is standard: each octave contributes half as much as the last.
noise.fractal_gain = 0.5
```

### Sampling Noise

```gdscript
# Returns a float in the range -1.0 to 1.0.
# x and z are world-space coordinates (use floats, not integers).
var height: float = noise.get_noise_2d(x, z)

# 3D noise for caves, clouds, or animated effects.
# The third coordinate can be TIME for animation.
var density: float = noise.get_noise_3d(x, y, z)

# To map -1..1 to 0..1 for heights:
var height_01: float = (noise.get_noise_2d(x, z) + 1.0) * 0.5
```

### Visualizing Noise in the Inspector

Create a `NoiseTexture2D` resource and assign your `FastNoiseLite` to its `noise` property. You can do this entirely in the inspector without any code. The texture previews the noise in real time as you adjust parameters. It's the fastest way to dial in the look you want before you hook it up to terrain generation.

### Sampling with Integer vs Float Coordinates

This is a common bug. If you sample `get_noise_2d(x, z)` where `x` and `z` are integers (like loop counters), you're only ever hitting integer grid positions. The noise still works, but at high frequencies, integer stepping can create repeating artifacts. Always multiply by a `resolution` float:

```gdscript
# WRONG — integer stepping at high frequencies looks banded:
for x in range(size):
    for z in range(size):
        var h = noise.get_noise_2d(x, z)

# RIGHT — world-space float coordinates:
for x in range(size):
    for z in range(size):
        var world_x := float(x) * resolution
        var world_z := float(z) * resolution
        var h = noise.get_noise_2d(world_x, world_z)
```

### Multiple Noise Layers

For terrain with distinct features at different scales — broad continental shapes plus local hilliness plus rocky surface detail — combine multiple `FastNoiseLite` instances:

```gdscript
var continental_noise := FastNoiseLite.new()
continental_noise.frequency = 0.002
continental_noise.fractal_octaves = 2

var hills_noise := FastNoiseLite.new()
hills_noise.frequency = 0.01
hills_noise.fractal_octaves = 4

var detail_noise := FastNoiseLite.new()
detail_noise.frequency = 0.05
detail_noise.fractal_octaves = 2

func sample_height(x: float, z: float) -> float:
    var continent := continental_noise.get_noise_2d(x, z) * 100.0
    var hills := hills_noise.get_noise_2d(x, z) * 20.0
    var detail := detail_noise.get_noise_2d(x, z) * 3.0
    return continent + hills + detail
```

This multi-layer approach is how real terrain tools work. The continental noise sets the macro shape, hills add mid-scale variation, detail adds surface roughness.

---

## 2. Procedural Mesh Generation with SurfaceTool

### What SurfaceTool Does

`SurfaceTool` is Godot's helper for building meshes at runtime. You call `begin()`, then add vertices one at a time (setting normals, UVs, and colors before each vertex), then add triangle indices, then call `commit()` to get an `ArrayMesh` you can assign to a `MeshInstance3D`.

It's the friendly layer on top of `ArrayMesh`, which stores raw vertex arrays. You can use either. SurfaceTool is easier for procedural generation. ArrayMesh is better if you're loading data from a file.

### Building a Flat Grid

Start with a flat grid — the foundation for all terrain:

```gdscript
func create_flat_grid(size: int, resolution: float) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Add all vertices
    for x in range(size):
        for z in range(size):
            var world_x := float(x) * resolution
            var world_z := float(z) * resolution

            st.set_normal(Vector3.UP)
            st.set_uv(Vector2(float(x) / float(size - 1), float(z) / float(size - 1)))
            st.add_vertex(Vector3(world_x, 0.0, world_z))

    # Add triangle indices
    # Each quad is split into 2 triangles.
    # Vertex index: row * size + col
    for x in range(size - 1):
        for z in range(size - 1):
            var i := x * size + z
            # Triangle 1: bottom-left, top-left, bottom-right
            st.add_index(i)
            st.add_index(i + size)
            st.add_index(i + 1)
            # Triangle 2: bottom-right, top-left, top-right
            st.add_index(i + 1)
            st.add_index(i + size)
            st.add_index(i + size + 1)

    st.generate_normals()
    st.generate_tangents()
    return st.commit()
```

### Vertex Winding Order

The winding order determines which side of a triangle is the "front" (visible). Godot uses counter-clockwise winding for front faces (looking from outside the surface toward it). If your terrain appears invisible from above, your indices are wound clockwise — reverse the order of two vertices in each triangle to fix it.

For a heightmap terrain viewed from above:
- The camera looks down in the -Y direction.
- The "front" face of each triangle must face up (+Y).
- Counter-clockwise when viewed from above: that's the winding above.

### SurfaceTool vs ArrayMesh

**SurfaceTool** — Add vertex attributes one at a time. Easier to write. Has a slight overhead from the helper layer. Best for runtime procedural generation where code clarity matters.

**ArrayMesh** — You fill `Array` objects with all positions, normals, UVs, and indices, then assign them directly. More code but faster for large meshes. Closer to the GPU's actual data format.

```gdscript
# ArrayMesh approach for comparison
func create_grid_arraymesh(size: int, resolution: float) -> ArrayMesh:
    var positions := PackedVector3Array()
    var normals := PackedVector3Array()
    var uvs := PackedVector2Array()
    var indices := PackedInt32Array()

    for x in range(size):
        for z in range(size):
            positions.append(Vector3(x * resolution, 0.0, z * resolution))
            normals.append(Vector3.UP)
            uvs.append(Vector2(float(x) / (size - 1), float(z) / (size - 1)))

    for x in range(size - 1):
        for z in range(size - 1):
            var i := x * size + z
            indices.append_array([i, i + size, i + 1, i + 1, i + size, i + size + 1])

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = positions
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh
```

### ImmediateMesh for Debug Geometry

`ImmediateMesh` is a third option for geometry you need to draw and throw away every frame — debug lines, selection boxes, path visualization. It doesn't use indices, is meant to be rebuilt each frame, and integrates with `MeshInstance3D`:

```gdscript
var im := ImmediateMesh.new()
var mi := MeshInstance3D.new()
mi.mesh = im
add_child(mi)

func _process(_delta: float) -> void:
    im.clear_surfaces()
    im.surface_begin(Mesh.PRIMITIVE_LINES)
    im.surface_add_vertex(Vector3(0, 0, 0))
    im.surface_add_vertex(Vector3(10, 0, 0))
    im.surface_end()
```

Use ImmediateMesh for debug visualization, not for persistent game geometry.

---

## 3. Heightmap Terrain

### From Flat Grid to Hills

Take the flat grid and displace each vertex's Y position by a noise sample at its world X/Z coordinates:

```gdscript
func create_heightmap_terrain(
    size: int,
    resolution: float,
    noise: FastNoiseLite,
    height_scale: float
) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    for x in range(size):
        for z in range(size):
            var world_x := float(x) * resolution
            var world_z := float(z) * resolution
            var height := noise.get_noise_2d(world_x, world_z) * height_scale

            st.set_uv(Vector2(float(x) / float(size - 1), float(z) / float(size - 1)))
            # Don't set normals manually — generate_normals() will do it correctly
            st.add_vertex(Vector3(world_x, height, world_z))

    for x in range(size - 1):
        for z in range(size - 1):
            var i := x * size + z
            st.add_index(i)
            st.add_index(i + size)
            st.add_index(i + 1)
            st.add_index(i + 1)
            st.add_index(i + size)
            st.add_index(i + size + 1)

    st.generate_normals()
    st.generate_tangents()
    return st.commit()
```

### Wiring It Up

```gdscript
extends Node3D

@export var terrain_size: int = 64        # vertices per side
@export var resolution: float = 2.0       # meters between vertices
@export var height_scale: float = 30.0

var noise := FastNoiseLite.new()

func _ready() -> void:
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.005
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 5

    var mesh := create_heightmap_terrain(terrain_size, resolution, noise, height_scale)

    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    add_child(mi)

    # Add collision
    var static_body := StaticBody3D.new()
    var collision_shape := CollisionShape3D.new()
    collision_shape.shape = mesh.create_trimesh_shape()
    static_body.add_child(collision_shape)
    mi.add_child(static_body)
```

### Terrain Resolution Tradeoffs

- **size=32, resolution=4.0** — 128x128m terrain, 1024 vertices, fast, low detail
- **size=64, resolution=2.0** — 128x128m terrain, 4096 vertices, good balance
- **size=128, resolution=1.0** — 128x128m terrain, 16384 vertices, high detail but slow to generate
- **size=256, resolution=0.5** — extremely high detail, use only for close chunks

For chunk-based worlds (section 9), use smaller grids (32-64) per chunk, and vary resolution per chunk based on distance from camera.

### Height Curves

Raw noise gives linear height distribution. To get more dramatic terrain — mostly flat lowlands with sharp mountain peaks — apply a power curve:

```gdscript
var raw := noise.get_noise_2d(world_x, world_z)   # -1 to 1
# Remap to 0..1, apply curve, remap back
var t := (raw + 1.0) * 0.5                         # 0 to 1
t = pow(t, 2.5)                                    # exaggerate peaks
var height := (t * 2.0 - 1.0) * height_scale       # back to -scale..scale
```

Godot's `Curve` resource works great for this if you want an artist-adjustable shape:

```gdscript
@export var height_curve: Curve  # Edit in inspector

func sample_height(x: float, z: float) -> float:
    var raw := (noise.get_noise_2d(x, z) + 1.0) * 0.5  # 0..1
    var curved := height_curve.sample(raw) if height_curve else raw
    return (curved * 2.0 - 1.0) * height_scale
```

---

## 4. Biome Coloring

### Coloring by Height and Slope

Real terrain gets its color from a combination of elevation and slope. Steep slopes shed soil and show bare rock. High elevations get snow. Low areas near water collect sand. You can encode this in a shader so the transitions are smooth and per-pixel rather than per-vertex.

First, pass height as a varying from the vertex shader:

```glsl
shader_type spatial;

// Height thresholds — edit in inspector
uniform float water_level : hint_range(-1.0, 1.0) = -0.2;
uniform float sand_level : hint_range(-1.0, 1.0) = -0.05;
uniform float grass_level : hint_range(-1.0, 1.0) = 0.3;
uniform float rock_level : hint_range(-1.0, 1.0) = 0.65;

// Colors
uniform vec3 water_color : source_color = vec3(0.1, 0.3, 0.6);
uniform vec3 sand_color : source_color = vec3(0.82, 0.72, 0.52);
uniform vec3 grass_color : source_color = vec3(0.22, 0.58, 0.12);
uniform vec3 rock_color : source_color = vec3(0.52, 0.50, 0.48);
uniform vec3 snow_color : source_color = vec3(0.95, 0.96, 1.0);

// Height scale must match GDScript (used to normalize height back to -1..1)
uniform float height_scale : hint_range(1.0, 200.0) = 30.0;

varying float world_height;

void vertex() {
    // Pass world-space Y to fragment
    world_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
    VERTEX = VERTEX; // no modification needed
}

void fragment() {
    // Normalize height to roughly -1..1 for threshold comparisons
    float h = world_height / height_scale;

    // Slope: 0 = perfectly flat, 1 = perfectly vertical
    float slope = 1.0 - NORMAL.y;

    // Blend through biomes based on height
    vec3 color = water_color;
    color = mix(color, sand_color,  smoothstep(water_level, sand_level,  h));
    color = mix(color, grass_color, smoothstep(sand_level,  grass_level, h));
    color = mix(color, rock_color,  smoothstep(grass_level, rock_level,  h));
    color = mix(color, snow_color,  smoothstep(rock_level,  1.0,         h));

    // Override steep areas with rock regardless of height
    color = mix(color, rock_color, smoothstep(0.4, 0.75, slope));

    ALBEDO = color;
    ROUGHNESS = mix(0.9, 0.5, smoothstep(rock_level, 1.0, h)); // snow is shinier
    METALLIC = 0.0;
}
```

### Applying the Shader

```gdscript
func create_terrain_material() -> ShaderMaterial:
    var shader := load("res://shaders/terrain_biome.gdshader")
    var mat := ShaderMaterial.new()
    mat.shader = shader
    mat.set_shader_parameter("water_level", -0.2)
    mat.set_shader_parameter("sand_level", -0.05)
    mat.set_shader_parameter("grass_level", 0.30)
    mat.set_shader_parameter("rock_level", 0.65)
    mat.set_shader_parameter("height_scale", height_scale)
    return mat

# After creating the mesh:
var mi := MeshInstance3D.new()
mi.mesh = terrain_mesh
mi.material_override = create_terrain_material()
add_child(mi)
```

### Vertex Color Approach (Alternative)

For a simpler (but less smooth) result, set colors per vertex during SurfaceTool construction. No shader needed, but transitions are linear and limited by mesh resolution:

```gdscript
func height_to_color(height: float, slope: float, height_scale: float) -> Color:
    var h := height / height_scale  # normalize to -1..1
    if slope > 0.6:
        return Color(0.52, 0.50, 0.48)  # rock
    if h < -0.2:
        return Color(0.1, 0.3, 0.6)    # water
    if h < -0.05:
        return Color(0.82, 0.72, 0.52) # sand
    if h < 0.3:
        return Color(0.22, 0.58, 0.12) # grass
    if h < 0.65:
        return Color(0.52, 0.50, 0.48) # rock
    return Color(0.95, 0.96, 1.0)      # snow

# In the vertex loop:
st.set_color(height_to_color(height, 0.0, height_scale))
st.add_vertex(pos)
```

For vertex colors to work, the material must have `vertex_color_use_as_albedo = true` (on a `StandardMaterial3D`) or you read `COLOR` in a shader.

---

## 5. MultiMeshInstance3D: Thousands in One Draw Call

### Why MultiMesh

Every `MeshInstance3D` in your scene is (at minimum) one draw call. A forest of 5000 trees as individual nodes means 5000 draw calls per frame — a guaranteed performance collapse on all but the most powerful hardware. `MultiMeshInstance3D` renders any number of instances of one mesh in a single draw call, with per-instance transform, color, and custom shader data.

The catch: all instances must share the same mesh and material. That's fine for trees, rocks, grass blades, particles — anything where you want many copies of one thing.

### Setting Up a MultiMesh

```gdscript
func create_multimesh_trees(
    count: int,
    positions: Array[Vector2],  # XZ positions from Poisson sampling
    terrain_noise: FastNoiseLite,
    height_scale: float,
    water_level: float,
    tree_mesh: Mesh
) -> MultiMeshInstance3D:

    var multi_mesh := MultiMesh.new()
    multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
    multi_mesh.use_colors = true
    multi_mesh.use_custom_data = true  # for wind phase
    multi_mesh.mesh = tree_mesh

    # Count valid positions first (skip underwater spots)
    var valid_positions: Array[Vector2] = []
    for pos in positions:
        var height := terrain_noise.get_noise_2d(pos.x, pos.y) * height_scale
        if height > water_level:
            valid_positions.append(pos)

    multi_mesh.instance_count = valid_positions.size()

    for i in valid_positions.size():
        var p := valid_positions[i]
        var height := terrain_noise.get_noise_2d(p.x, p.y) * height_scale

        var t := Transform3D.IDENTITY
        t.origin = Vector3(p.x, height, p.y)

        # Random Y rotation
        t = t.rotated(Vector3.UP, randf() * TAU)

        # Slight random scale
        var s := randf_range(0.75, 1.3)
        t.basis = t.basis.scaled(Vector3(s, s, s))

        multi_mesh.set_instance_transform(i, t)

        # Slight color variation — makes the forest feel alive
        var g := randf_range(0.80, 1.0)
        multi_mesh.set_instance_color(i, Color(randf_range(0.7, 0.9), g, randf_range(0.65, 0.85)))

        # Wind phase offset (x channel of custom data)
        multi_mesh.set_instance_custom_data(i, Color(randf() * TAU, 0.0, 0.0, 0.0))

    var mmi := MultiMeshInstance3D.new()
    mmi.multimesh = multi_mesh
    return mmi
```

### Instance Count vs Visible Instance Count

`instance_count` is the total allocation — resizing this is expensive because it reallocates GPU memory. Set it once and keep it at the maximum you'll ever need for this `MultiMesh`.

`visible_instance_count` controls how many instances are actually rendered, without touching GPU memory. Set it to `-1` to render all. Set it to any lower number to "hide" the tail of the array without a reallocation. This is useful for LOD: as the player moves away, reduce `visible_instance_count` to render only the nearest instances.

```gdscript
# Allocate for 1000 trees max
multi_mesh.instance_count = 1000

# Only render the first 300 right now
multi_mesh.visible_instance_count = 300

# Later, show more:
multi_mesh.visible_instance_count = 700
```

### Per-Instance Custom Data

`use_custom_data = true` gives each instance a `Color` (4 floats) of arbitrary data. In the shader, read it as `INSTANCE_CUSTOM`. Use this for:
- Wind phase offset (section 7)
- Growth stage (grass growing in/out)
- Damage state
- Any per-instance variation that doesn't fit into the color

```gdscript
# Store wind phase in the red channel
multi_mesh.set_instance_custom_data(i, Color(randf() * TAU, 0.0, 0.0, 0.0))

# In shader:
# float phase = INSTANCE_CUSTOM.x;
```

### Creating a Simple Tree Mesh

You don't need a modeled asset to prototype. Build a quick tree with SurfaceTool:

```gdscript
func create_simple_tree_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()

    # Trunk — a thin box
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # (For brevity, use a BoxMesh merged approach or just prototype with a CapsuleMesh)
    # In production, load: preload("res://assets/meshes/tree_lowpoly.res")

    # Simplest approach: just use a SphereMesh as a placeholder
    return SphereMesh.new()  # Replace with real mesh in production
```

For prototyping, assign a `CapsuleMesh`, `CylinderMesh`, or `SphereMesh` to the `MultiMesh.mesh`. They work identically.

---

## 6. Poisson Disk Sampling

### The Problem with Pure Random

`randf_range()` gives uniform random placement — but "uniform random" doesn't mean "evenly spaced." Statistically, random points clump. You get dense patches and large empty gaps. In a forest, that looks wrong. Real trees are spaced out by competition for light, water, and space.

Poisson disk sampling solves this: it guarantees that no two points are closer than a minimum distance, while still looking random and organic. The result looks like how objects actually appear in nature.

### The Algorithm

```gdscript
## Returns a list of 2D points where no two points are closer than min_dist.
## area: the bounding rectangle (width, height) in world units.
## min_dist: minimum distance between any two points.
func poisson_disk_sample(area: Vector2, min_dist: float, max_attempts: int = 30) -> Array[Vector2]:
    var points: Array[Vector2] = []
    var active: Array[Vector2] = []

    # Spatial grid for fast neighbor lookup.
    # Each cell is min_dist/sqrt(2) wide, so any point within min_dist
    # is in at most 5x5 neighboring cells.
    var cell_size := min_dist / sqrt(2.0)
    var grid_w := ceili(area.x / cell_size)
    var grid_h := ceili(area.y / cell_size)
    var grid: Array = []
    grid.resize(grid_w * grid_h)

    # Seed with a random starting point
    var first := Vector2(randf() * area.x, randf() * area.y)
    points.append(first)
    active.append(first)
    var fi := Vector2i(int(first.x / cell_size), int(first.y / cell_size))
    grid[fi.x + fi.y * grid_w] = first

    while active.size() > 0:
        var idx := randi() % active.size()
        var point := active[idx]
        var found_candidate := false

        for _attempt in max_attempts:
            # Pick a random point in the annulus [min_dist, 2*min_dist] around point
            var angle := randf() * TAU
            var dist := randf_range(min_dist, min_dist * 2.0)
            var candidate := point + Vector2(cos(angle), sin(angle)) * dist

            # Reject if outside area
            if candidate.x < 0.0 or candidate.x >= area.x:
                continue
            if candidate.y < 0.0 or candidate.y >= area.y:
                continue

            # Check nearby grid cells for minimum distance violation
            var cgi := Vector2i(int(candidate.x / cell_size), int(candidate.y / cell_size))
            var too_close := false

            for dx in range(-2, 3):
                if too_close:
                    break
                for dy in range(-2, 3):
                    var ni := cgi + Vector2i(dx, dy)
                    if ni.x < 0 or ni.x >= grid_w or ni.y < 0 or ni.y >= grid_h:
                        continue
                    var neighbor = grid[ni.x + ni.y * grid_w]
                    if neighbor != null and candidate.distance_to(neighbor) < min_dist:
                        too_close = true
                        break

            if not too_close:
                points.append(candidate)
                active.append(candidate)
                grid[cgi.x + cgi.y * grid_w] = candidate
                found_candidate = true
                break

        if not found_candidate:
            active.remove_at(idx)

    return points
```

### Using It for Vegetation

```gdscript
# 15 meters minimum between trees in a 128x128m area
var tree_positions := poisson_disk_sample(Vector2(128.0, 128.0), 15.0)

# 2 meters minimum between grass clumps
var grass_positions := poisson_disk_sample(Vector2(128.0, 128.0), 2.0)

# For chunks: offset positions by chunk world origin before terrain sampling
for i in tree_positions.size():
    tree_positions[i] += chunk_world_origin_xz
```

### Visual Difference

Pure random at 200 trees: you'll see dense clumps and open patches. Poisson disk at 200 trees: even distribution that still looks natural. The difference is immediately obvious and dramatically improves the visual quality of any scattered vegetation system.

### Biome-Aware Placement

Combine noise values with Poisson positions to filter placement by biome:

```gdscript
for pos in candidate_positions:
    var h := terrain_noise.get_noise_2d(pos.x, pos.y) * height_scale
    var n := (h / height_scale + 1.0) * 0.5  # 0..1

    # Only place trees in the grass biome
    if n > 0.15 and n < 0.55:
        tree_transforms.append(build_transform(pos, h))

    # Only place rocks in the rock biome
    if n > 0.55 and n < 0.80:
        rock_transforms.append(build_transform(pos, h))
```

---

## 7. Wind Animation with Vertex Shaders

### The Goal

Grass and trees should move in the wind. Moving them with GDScript (updating thousands of transforms per frame) is catastrophically slow. The right solution: a vertex shader that runs on the GPU, displacing each vertex every frame using `TIME`. Per-instance `INSTANCE_CUSTOM` provides a phase offset so instances don't all sway in sync.

### Grass Shader

Save as `res://shaders/grass_wind.gdshader`:

```glsl
shader_type spatial;
render_mode cull_disabled;  // Grass is double-sided — no backface culling

uniform float wind_strength : hint_range(0.0, 2.0) = 0.4;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.8;
uniform vec2 wind_direction = vec2(1.0, 0.3);  // XZ direction (doesn't need to be normalized)
uniform float turbulence : hint_range(0.0, 1.0) = 0.25;

uniform sampler2D albedo_texture : source_color;
uniform vec3 base_color : source_color = vec3(0.3, 0.7, 0.15);
uniform vec3 tip_color : source_color = vec3(0.5, 0.85, 0.2);

varying float v_height_mask;

void vertex() {
    // UV.y goes from 0 (root of blade) to 1 (tip).
    // We don't want the root to move — anchored to ground.
    // Quadratic mask: no movement at 0, full movement at 1.
    v_height_mask = UV.y * UV.y;

    // Per-instance phase offset stored in custom data red channel
    float phase = INSTANCE_CUSTOM.x;

    // World-space X position creates spatial variation across the field
    float world_x = MODEL_MATRIX[3].x;
    float world_z = MODEL_MATRIX[3].z;

    // Primary sway
    float time_offset = TIME * wind_speed + world_x * 0.3 + world_z * 0.2 + phase;
    float sway_x = sin(time_offset) * wind_strength * v_height_mask;
    float sway_z = cos(time_offset * 0.7) * wind_strength * 0.4 * v_height_mask;

    // Turbulence: faster, smaller noise on top of the sway
    float turb = sin(TIME * wind_speed * 3.1 + world_x * 1.2 + phase * 2.3) * turbulence * v_height_mask;

    VERTEX.x += wind_direction.x * sway_x + turb;
    VERTEX.z += wind_direction.y * sway_z + turb * 0.5;

    // Slight vertical compression when bent forward (physically plausible)
    VERTEX.y -= abs(sway_x) * 0.1;
}

void fragment() {
    // Color gradient from base (root) to tip
    vec3 color = mix(base_color, tip_color, v_height_mask);

    // Apply texture tint if provided
    vec4 tex = texture(albedo_texture, UV);
    color *= tex.rgb;

    ALBEDO = color;
    ALPHA = tex.a;
    ALPHA_SCISSOR_THRESHOLD = 0.5;
    ROUGHNESS = 0.9;
    METALLIC = 0.0;

    // Ambient occlusion at the root
    AO = mix(0.3, 1.0, v_height_mask);
    AO_LIGHT_AFFECT = 0.5;
}
```

### Tree Wind Shader

Trees need subtler movement — a slow sway for the whole trunk and faster flutter on the leaves. Use a separate shader for trees:

```glsl
shader_type spatial;

uniform float trunk_sway : hint_range(0.0, 0.5) = 0.08;
uniform float leaf_flutter : hint_range(0.0, 1.0) = 0.3;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.2;
uniform vec2 wind_direction = vec2(1.0, 0.2);

uniform sampler2D albedo_texture : source_color;
uniform vec4 albedo_color : source_color = vec4(1.0);

void vertex() {
    float phase = INSTANCE_CUSTOM.x;
    float world_x = MODEL_MATRIX[3].x;
    float world_z = MODEL_MATRIX[3].z;

    // Height-based bend mask (same idea as grass — anchored at root)
    float height_mask = max(0.0, VERTEX.y / 4.0);  // assumes tree is ~4 units tall
    height_mask = pow(height_mask, 1.5);

    // Trunk sway: slow, gentle
    float trunk_time = TIME * wind_speed * 0.5 + world_x * 0.1 + phase;
    float sway = sin(trunk_time) * trunk_sway * height_mask;

    VERTEX.x += wind_direction.x * sway;
    VERTEX.z += wind_direction.y * sway;

    // Leaf flutter: faster, higher frequency on top half only
    if (VERTEX.y > 2.0) {
        float flutter_time = TIME * wind_speed * 3.0 + world_x * 0.8 + phase * 1.5;
        float flutter = sin(flutter_time) * leaf_flutter * (height_mask - 0.3);
        VERTEX.x += wind_direction.x * flutter * 0.4;
        VERTEX.z += wind_direction.y * flutter * 0.4;
    }
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb * albedo_color.rgb;
    ALPHA = tex.a;
    ALPHA_SCISSOR_THRESHOLD = 0.4;
    ROUGHNESS = 0.85;
}
```

### Attaching the Shader and Setting Custom Data

```gdscript
# Grass material
var grass_mat := ShaderMaterial.new()
grass_mat.shader = load("res://shaders/grass_wind.gdshader")
grass_mat.set_shader_parameter("wind_strength", 0.4)
grass_mat.set_shader_parameter("wind_speed", 1.8)
grass_mat.set_shader_parameter("wind_direction", Vector2(1.0, 0.3))

# Assign to the grass MultiMesh
grass_mmi.material_override = grass_mat

# Per-instance phase (during MultiMesh construction)
for i in multi_mesh.instance_count:
    # Red channel = wind phase offset (0 to 2*PI)
    multi_mesh.set_instance_custom_data(i, Color(randf() * TAU, 0.0, 0.0, 0.0))
```

### Why INSTANCE_CUSTOM Works for Wind

Without phase offsets, every grass blade is at the same point in its sway cycle. The whole field moves as one rigid object — immediately obvious and deeply uncanny. With random phase offsets, each blade is at a different point in its cycle. The field ripples organically. This one change transforms the visual quality dramatically.

---

## 8. LOD (Level of Detail)

### What LOD Solves

Rendering high-detail meshes for objects 500 meters away wastes GPU time — they're only a few pixels on screen anyway. LOD swaps in progressively simpler meshes as distance increases, keeping the frame budget focused on what's actually visible.

### Godot's Visibility Range System

Every `GeometryInstance3D` (which includes `MeshInstance3D`) has these properties:

- `visibility_range_begin` — the distance at which this node **starts** being visible
- `visibility_range_end` — the distance at which this node **stops** being visible (0 = no limit)
- `visibility_range_begin_margin` and `visibility_range_end_margin` — overlap zones for crossfade
- `visibility_range_fade_mode` — `VISIBILITY_RANGE_FADE_DISABLED` (instant pop), `VISIBILITY_RANGE_FADE_SELF` (this mesh fades), or `VISIBILITY_RANGE_FADE_DEPENDENCIES` (dependencies fade)

### Setting Up LOD for a Tree

Create a scene with multiple `MeshInstance3D` children, each representing a different detail level:

```
TreeLOD (Node3D)
├── HighDetail (MeshInstance3D)      — ~800 triangles, full foliage detail
├── MediumDetail (MeshInstance3D)    — ~200 triangles, simplified
├── LowDetail (MeshInstance3D)       — ~50 triangles, very simple
└── Billboard (MeshInstance3D)       — flat quad with texture, facing camera
```

```gdscript
# Called in _ready() of the TreeLOD scene
func setup_lod() -> void:
    # High detail: shows up close, fades out at 30m
    $HighDetail.visibility_range_begin = 0.0
    $HighDetail.visibility_range_end = 32.0
    $HighDetail.visibility_range_end_margin = 4.0
    $HighDetail.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

    # Medium detail: overlaps high at 28m, fades out at 85m
    $MediumDetail.visibility_range_begin = 28.0
    $MediumDetail.visibility_range_begin_margin = 4.0
    $MediumDetail.visibility_range_end = 90.0
    $MediumDetail.visibility_range_end_margin = 5.0
    $MediumDetail.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

    # Low detail: 85m to 200m
    $LowDetail.visibility_range_begin = 85.0
    $LowDetail.visibility_range_begin_margin = 5.0
    $LowDetail.visibility_range_end = 210.0
    $LowDetail.visibility_range_end_margin = 10.0
    $LowDetail.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

    # Billboard: 200m to 500m — just a textured quad
    $Billboard.visibility_range_begin = 200.0
    $Billboard.visibility_range_begin_margin = 10.0
    $Billboard.visibility_range_end = 500.0
    $Billboard.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
```

### LOD for MultiMesh

`MultiMeshInstance3D` also inherits visibility range properties, so you can have multiple `MultiMeshInstance3D` nodes (one per LOD level) and set their ranges. Combined with `visible_instance_count`, this gives good distance-based culling:

```gdscript
# Two MultiMeshes for trees: high detail close, low detail far
$TreesHighLOD.visibility_range_begin = 0.0
$TreesHighLOD.visibility_range_end = 100.0
$TreesHighLOD.visibility_range_end_margin = 10.0

$TreesLowLOD.visibility_range_begin = 90.0
$TreesLowLOD.visibility_range_begin_margin = 10.0
$TreesLowLOD.visibility_range_end = 400.0
```

### HLOD (Hierarchical LOD)

For very large scenes, distant clusters of trees should become a single combined mesh (or even a billboard billboard of the whole cluster). This is Hierarchical LOD. Godot doesn't do this automatically, but you can implement it manually:

1. At generation time, build cluster meshes that combine all vegetation in a region into one mesh.
2. Show individual MultiMesh trees up to 300m; show the cluster mesh from 300-800m; beyond that, the fog hides everything anyway.

---

## 9. Chunk-Based World Streaming

### The Concept

One giant terrain mesh for an infinite world is impossible — it would require infinite memory and infinite generation time. Instead, divide the world into a grid of fixed-size chunks. Keep only the chunks near the camera loaded and rendered. As the camera moves, load new chunks ahead and unload chunks behind.

### WorldGenerator Node

```gdscript
class_name WorldGenerator
extends Node3D

@export var chunk_size: float = 64.0         # world units per chunk
@export var terrain_resolution: float = 2.0  # meters between terrain vertices
@export var terrain_height: float = 40.0
@export var view_distance: int = 4           # chunks in each direction from camera

var chunks: Dictionary = {}                  # Vector2i -> ChunkData
var noise := FastNoiseLite.new()
var _camera: Camera3D

class ChunkData:
    var node: Node3D
    var is_ready: bool = false

func _ready() -> void:
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.004
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 5
    noise.fractal_lacunarity = 2.0
    noise.fractal_gain = 0.5

func _process(_delta: float) -> void:
    if not _camera:
        _camera = get_viewport().get_camera_3d()
        return
    var cam_pos := _camera.global_position
    var camera_chunk := Vector2i(
        floori(cam_pos.x / chunk_size),
        floori(cam_pos.z / chunk_size)
    )
    update_chunks(camera_chunk)

func update_chunks(center: Vector2i) -> void:
    # Queue loading of all needed chunks
    for x in range(center.x - view_distance, center.x + view_distance + 1):
        for z in range(center.y - view_distance, center.y + view_distance + 1):
            var key := Vector2i(x, z)
            if not chunks.has(key):
                load_chunk(key)

    # Find and unload distant chunks
    var to_remove: Array[Vector2i] = []
    for key in chunks:
        var dx := abs(key.x - center.x)
        var dz := abs(key.y - center.y)
        if dx > view_distance + 1 or dz > view_distance + 1:
            to_remove.append(key)
    for key in to_remove:
        unload_chunk(key)

func load_chunk(key: Vector2i) -> void:
    var data := ChunkData.new()
    var chunk_node := create_terrain_chunk(key)
    chunk_node.position = Vector3(
        key.x * chunk_size,
        0.0,
        key.y * chunk_size
    )
    add_child(chunk_node)
    data.node = chunk_node
    data.is_ready = true
    chunks[key] = data

func unload_chunk(key: Vector2i) -> void:
    if chunks.has(key):
        chunks[key].node.queue_free()
        chunks.erase(key)
```

### Creating Terrain Chunks

Each chunk samples noise at its world-space offset. The critical thing: pass `chunk_world_origin` into the noise sampler so adjacent chunks line up perfectly:

```gdscript
func create_terrain_chunk(key: Vector2i) -> Node3D:
    var root := Node3D.new()
    root.name = "Chunk_%d_%d" % [key.x, key.y]

    var chunk_origin_x := key.x * chunk_size
    var chunk_origin_z := key.y * chunk_size

    # Calculate vertex count from chunk_size and resolution
    var verts_per_side := int(chunk_size / terrain_resolution) + 1

    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    for x in range(verts_per_side):
        for z in range(verts_per_side):
            var local_x := float(x) * terrain_resolution
            var local_z := float(z) * terrain_resolution
            var world_x := chunk_origin_x + local_x
            var world_z := chunk_origin_z + local_z
            var height := noise.get_noise_2d(world_x, world_z) * terrain_height

            st.set_uv(Vector2(float(x) / (verts_per_side - 1), float(z) / (verts_per_side - 1)))
            st.add_vertex(Vector3(local_x, height, local_z))

    for x in range(verts_per_side - 1):
        for z in range(verts_per_side - 1):
            var i := x * verts_per_side + z
            st.add_index(i)
            st.add_index(i + verts_per_side)
            st.add_index(i + 1)
            st.add_index(i + 1)
            st.add_index(i + verts_per_side)
            st.add_index(i + verts_per_side + 1)

    st.generate_normals()
    var mesh := st.commit()

    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = create_terrain_material()
    root.add_child(mi)

    # Collision
    var sb := StaticBody3D.new()
    var cs := CollisionShape3D.new()
    cs.shape = mesh.create_trimesh_shape()
    sb.add_child(cs)
    mi.add_child(sb)

    # Vegetation
    root.add_child(create_chunk_vegetation(chunk_origin_x, chunk_origin_z))

    return root
```

### Per-Chunk Vegetation

```gdscript
func create_chunk_vegetation(origin_x: float, origin_z: float) -> Node3D:
    var veg_root := Node3D.new()
    veg_root.name = "Vegetation"

    # Poisson sample in local chunk space, then offset to world
    var area := Vector2(chunk_size, chunk_size)
    var tree_candidates := poisson_disk_sample(area, 12.0)
    var grass_candidates := poisson_disk_sample(area, 1.5)

    # Build tree MultiMesh
    var tree_positions: Array[Vector3] = []
    for c in tree_candidates:
        var wx := origin_x + c.x
        var wz := origin_z + c.y
        var h := noise.get_noise_2d(wx, wz) * terrain_height
        var normalized_h := (h / terrain_height + 1.0) * 0.5
        if normalized_h > 0.12 and normalized_h < 0.6:  # grass biome
            tree_positions.append(Vector3(c.x, h, c.y))

    if tree_positions.size() > 0:
        veg_root.add_child(build_tree_multimesh(tree_positions))

    # Build grass MultiMesh
    var grass_positions: Array[Vector3] = []
    for c in grass_candidates:
        var wx := origin_x + c.x
        var wz := origin_z + c.y
        var h := noise.get_noise_2d(wx, wz) * terrain_height
        var normalized_h := (h / terrain_height + 1.0) * 0.5
        if normalized_h > 0.10 and normalized_h < 0.55:
            grass_positions.append(Vector3(c.x, h, c.y))

    if grass_positions.size() > 0:
        veg_root.add_child(build_grass_multimesh(grass_positions))

    return veg_root
```

### Background Thread Generation

Generating chunks on the main thread causes frame stutters. Use `WorkerThreadPool` to generate the mesh data in the background, then apply it on the main thread:

```gdscript
var _pending_chunks: Dictionary = {}  # Vector2i -> bool

func load_chunk_async(key: Vector2i) -> void:
    if chunks.has(key) or _pending_chunks.has(key):
        return
    _pending_chunks[key] = true

    WorkerThreadPool.add_task(func():
        # This runs on a worker thread — only compute data, don't touch nodes
        var chunk_data := _generate_chunk_data_threaded(key)

        # Hand off to main thread via call_deferred
        call_deferred("_apply_chunk_on_main_thread", key, chunk_data)
    )

# Runs on worker thread — returns raw ArrayMesh (safe to create off main thread)
func _generate_chunk_data_threaded(key: Vector2i) -> ArrayMesh:
    var origin_x := key.x * chunk_size
    var origin_z := key.y * chunk_size
    var verts_per_side := int(chunk_size / terrain_resolution) + 1

    var positions := PackedVector3Array()
    var uvs := PackedVector2Array()
    var indices := PackedInt32Array()

    for x in range(verts_per_side):
        for z in range(verts_per_side):
            var wx := origin_x + float(x) * terrain_resolution
            var wz := origin_z + float(z) * terrain_resolution
            var h := noise.get_noise_2d(wx, wz) * terrain_height
            positions.append(Vector3(float(x) * terrain_resolution, h, float(z) * terrain_resolution))
            uvs.append(Vector2(float(x) / (verts_per_side - 1), float(z) / (verts_per_side - 1)))

    for x in range(verts_per_side - 1):
        for z in range(verts_per_side - 1):
            var i := x * verts_per_side + z
            indices.append_array([i, i + verts_per_side, i + 1, i + 1, i + verts_per_side, i + verts_per_side + 1])

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = positions
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh

# Called on main thread via call_deferred
func _apply_chunk_on_main_thread(key: Vector2i, mesh: ArrayMesh) -> void:
    _pending_chunks.erase(key)
    if not chunks.has(key):  # might have been unloaded while generating
        var chunk_node := _build_chunk_node_from_mesh(key, mesh)
        chunk_node.position = Vector3(key.x * chunk_size, 0.0, key.y * chunk_size)
        add_child(chunk_node)
        var data := ChunkData.new()
        data.node = chunk_node
        data.is_ready = true
        chunks[key] = data

func _build_chunk_node_from_mesh(key: Vector2i, mesh: ArrayMesh) -> Node3D:
    var root := Node3D.new()
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = create_terrain_material()
    root.add_child(mi)
    var sb := StaticBody3D.new()
    var cs := CollisionShape3D.new()
    cs.shape = mesh.create_trimesh_shape()
    sb.add_child(cs)
    mi.add_child(sb)
    root.add_child(create_chunk_vegetation(key.x * chunk_size, key.y * chunk_size))
    return root
```

**Important threading rule**: never create `Node` objects or call scene tree methods on a worker thread. Only compute raw data (arrays, meshes). Use `call_deferred` to move back to the main thread before touching the scene tree.

---

## 10. Navigation on Procedural Terrain

### The Challenge

`NavigationMesh` must be baked — it can't be built ahead of time for procedural terrain. You need to rebake after generating terrain, and the bake must happen after the collision shapes are in the scene tree.

### Setting Up NavigationRegion3D

Add a `NavigationRegion3D` as a child of the terrain node. It will automatically collect all `StaticBody3D` collision geometry within its `NavigationMesh.geometry_source` setting.

```gdscript
func add_navigation_to_chunk(chunk_root: Node3D) -> void:
    var nav_region := NavigationRegion3D.new()

    var nav_mesh := NavigationMesh.new()
    nav_mesh.agent_height = 1.8
    nav_mesh.agent_radius = 0.4
    nav_mesh.agent_max_climb = 0.5
    nav_mesh.agent_max_slope = 45.0

    # Use physics geometry as source (picks up StaticBody3D collision)
    nav_mesh.geometry_source = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN

    nav_region.navigation_mesh = nav_mesh
    chunk_root.add_child(nav_region)

    # Bake after adding to the tree (needs the scene tree to collect geometry)
    await get_tree().process_frame
    nav_region.bake_navigation_mesh(false)  # false = synchronous bake
```

### Async Navigation Baking

For large areas, use the async bake to avoid frame stutter:

```gdscript
func bake_navigation_async(nav_region: NavigationRegion3D) -> void:
    nav_region.bake_finished.connect(func():
        print("Navigation baked for region at ", nav_region.global_position)
    , CONNECT_ONE_SHOT)
    nav_region.bake_navigation_mesh(true)  # true = async
```

### NPC Pathfinding on Procedural Terrain

Once the navigation mesh is baked, NPCs can use `NavigationAgent3D` exactly as in any handcrafted scene:

```gdscript
class_name TerrainNPC
extends CharacterBody3D

@export var move_speed: float = 4.0
@onready var nav_agent := $NavigationAgent3D

func navigate_to(target: Vector3) -> void:
    nav_agent.target_position = target

func _physics_process(delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return

    var next_pos := nav_agent.get_next_path_position()
    var dir := (next_pos - global_position).normalized()

    velocity = dir * move_speed
    velocity.y -= 9.8 * delta  # gravity
    move_and_slide()
```

---

## 11. Performance Optimization

### The Core Insight

Procedural worlds can be extremely fast or extremely slow depending on a handful of architectural decisions. The tools are all there in Godot — you just need to use them.

### Use MultiMesh, Not Individual Nodes

This cannot be overstated. 1000 `MeshInstance3D` nodes for trees = 1000 draw calls minimum. One `MultiMeshInstance3D` with 1000 instances = 1 draw call. For any repeated object (trees, rocks, grass, bushes, fence posts), MultiMesh is mandatory.

```gdscript
# WRONG — kills performance at any meaningful scale:
for pos in tree_positions:
    var mi := MeshInstance3D.new()
    mi.mesh = tree_mesh
    mi.global_position = pos
    add_child(mi)

# RIGHT — one draw call regardless of count:
var mm := MultiMesh.new()
mm.mesh = tree_mesh
mm.instance_count = tree_positions.size()
for i in tree_positions.size():
    mm.set_instance_transform(i, build_transform(tree_positions[i]))
var mmi := MultiMeshInstance3D.new()
mmi.multimesh = mm
add_child(mmi)
```

### Reduce Distant Chunk Resolution

Don't use the same vertex density for all chunks. Chunks far from the camera can use a much coarser grid:

```gdscript
func get_chunk_resolution(dist_from_camera: float) -> float:
    if dist_from_camera < 2:
        return terrain_resolution          # e.g., 2.0m
    elif dist_from_camera < 4:
        return terrain_resolution * 2.0    # e.g., 4.0m
    else:
        return terrain_resolution * 4.0    # e.g., 8.0m
```

Pass `dist_from_camera` as the Manhattan distance in chunks from the camera chunk.

### Visibility Ranges on Everything

Set `visibility_range_end` on every `MeshInstance3D` and `MultiMeshInstance3D`. If something is 600 meters away and behind fog, it should not be rendered. Even with frustum culling, Godot still processes out-of-view objects if they have no range limit.

```gdscript
mi.visibility_range_end = 400.0
mi.visibility_range_end_margin = 20.0
```

### Occlusion Culling

Add `OccluderInstance3D` nodes to large terrain chunks. Godot's rasterization-based occlusion culler will skip rendering anything hidden behind them. For rolling hills, the hills themselves block the valleys — add occluders to the major terrain features.

```gdscript
var occluder := OccluderInstance3D.new()
var box_occ := BoxOccluder3D.new()
box_occ.size = Vector3(chunk_size, terrain_height * 2.0, chunk_size)
occluder.occluder = box_occ
chunk_root.add_child(occluder)
```

### Fog to Hide the Draw Distance

World environment fog is not a workaround — it's a design choice. Every open-world game uses distance fog. It hides chunk loading seams, reduces the number of objects that need to be rendered at full quality, and adds atmosphere:

```gdscript
var env := WorldEnvironment.new()
var environment := Environment.new()
environment.fog_enabled = true
environment.fog_density = 0.008
environment.fog_aerial_perspective = 0.5
environment.volumetric_fog_enabled = true
env.environment = environment
add_child(env)
```

Set `visibility_range_end` to match the fog's effective visibility distance. Objects at the fog boundary are already invisible — no need to render them.

### Object Pooling for Chunks

Creating and destroying `Node3D` trees repeatedly is expensive (GC pressure, `_ready()` overhead). Instead, keep a pool of inactive chunk nodes and recycle them:

```gdscript
var _chunk_pool: Array[Node3D] = []

func get_pooled_chunk() -> Node3D:
    if _chunk_pool.size() > 0:
        var node := _chunk_pool.pop_back()
        node.visible = true
        return node
    return Node3D.new()

func return_to_pool(node: Node3D) -> void:
    node.visible = false
    _chunk_pool.append(node)
    # Update mesh/material in-place when reusing for a different chunk position
```

### Monitoring Performance

Use Godot's built-in profiler (Debugger > Profiler) and monitor:
- **Draw calls**: should be low (MultiMesh collapses many into one)
- **Vertices rendered**: watch for spikes when new chunks load
- **Script time**: heavy if chunk generation is on main thread
- **GPU time**: high if too much visible geometry or expensive shaders

---

## 12. Code Walkthrough: Infinite Procedural Landscape

### Project Structure

```
res://
├── scenes/
│   ├── main.tscn          — Root scene, entry point
│   ├── player.tscn        — CharacterBody3D with camera
│   └── world_generator.tscn
├── scripts/
│   ├── world_generator.gd
│   ├── terrain_chunk.gd
│   ├── vegetation_scatterer.gd
│   └── player.gd
├── shaders/
│   ├── terrain_biome.gdshader
│   └── grass_wind.gdshader
└── assets/
    └── meshes/
        ├── tree_high.res
        ├── tree_low.res
        └── grass_blade.res
```

### main.tscn

The root scene is minimal:

```
Main (Node3D)
├── WorldEnvironment
├── DirectionalLight3D
├── WorldGenerator
└── Player
```

```gdscript
# main.gd
extends Node3D

func _ready() -> void:
    # Setup nice sky + fog
    var env := $WorldEnvironment.environment
    env.background_mode = Environment.BG_SKY
    env.fog_enabled = true
    env.fog_density = 0.006
    env.fog_light_color = Color(0.65, 0.75, 0.88)
    env.fog_aerial_perspective = 0.4

    # Sun direction
    $DirectionalLight3D.rotation_degrees = Vector3(-45, -30, 0)
    $DirectionalLight3D.light_energy = 1.2
    $DirectionalLight3D.shadow_enabled = true
```

### world_generator.gd (Complete)

```gdscript
# world_generator.gd
class_name WorldGenerator
extends Node3D

@export var chunk_size: float = 64.0
@export var terrain_resolution: float = 2.0
@export var terrain_height: float = 40.0
@export var view_distance: int = 4
@export var tree_min_spacing: float = 12.0
@export var grass_min_spacing: float = 1.8
@export var water_level_normalized: float = 0.12  # 0..1

var chunks: Dictionary = {}
var _pending: Dictionary = {}
var noise := FastNoiseLite.new()
var _terrain_mat: ShaderMaterial
var _tree_mesh: Mesh
var _grass_mesh: Mesh
var _grass_mat: ShaderMaterial

func _ready() -> void:
    _setup_noise()
    _terrain_mat = _create_terrain_material()
    _tree_mesh = _create_placeholder_tree_mesh()
    _grass_mesh = _create_grass_blade_mesh()
    _grass_mat = _create_grass_material()

func _setup_noise() -> void:
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.seed = randi()
    noise.frequency = 0.004
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 5
    noise.fractal_lacunarity = 2.0
    noise.fractal_gain = 0.5

func _process(_delta: float) -> void:
    var cam := get_viewport().get_camera_3d()
    if not cam:
        return
    var cp := Vector2i(floori(cam.global_position.x / chunk_size),
                       floori(cam.global_position.z / chunk_size))
    _update_chunks(cp)

func _update_chunks(center: Vector2i) -> void:
    for x in range(center.x - view_distance, center.x + view_distance + 1):
        for z in range(center.y - view_distance, center.y + view_distance + 1):
            var key := Vector2i(x, z)
            if not chunks.has(key) and not _pending.has(key):
                _load_chunk(key)
    var to_remove: Array[Vector2i] = []
    for key: Vector2i in chunks:
        if abs(key.x - center.x) > view_distance + 1 or abs(key.y - center.y) > view_distance + 1:
            to_remove.append(key)
    for key in to_remove:
        _unload_chunk(key)

func _load_chunk(key: Vector2i) -> void:
    _pending[key] = true
    WorkerThreadPool.add_task(func():
        var mesh := _generate_terrain_mesh_threaded(key)
        call_deferred("_finish_chunk", key, mesh)
    )

func _finish_chunk(key: Vector2i, terrain_mesh: ArrayMesh) -> void:
    _pending.erase(key)
    if chunks.has(key):
        return  # race condition guard

    var root := Node3D.new()
    root.name = "Chunk_%d_%d" % [key.x, key.y]
    root.position = Vector3(key.x * chunk_size, 0.0, key.y * chunk_size)

    # Terrain mesh
    var mi := MeshInstance3D.new()
    mi.mesh = terrain_mesh
    mi.material_override = _terrain_mat
    mi.visibility_range_end = (view_distance + 1) * chunk_size
    mi.visibility_range_end_margin = chunk_size * 0.5
    root.add_child(mi)

    # Collision
    var sb := StaticBody3D.new()
    var cs := CollisionShape3D.new()
    cs.shape = terrain_mesh.create_trimesh_shape()
    sb.add_child(cs)
    mi.add_child(sb)

    # Vegetation
    var origin := Vector2(key.x * chunk_size, key.y * chunk_size)
    var veg := _create_vegetation(origin)
    root.add_child(veg)

    add_child(root)
    chunks[key] = root

func _unload_chunk(key: Vector2i) -> void:
    if chunks.has(key):
        chunks[key].queue_free()
        chunks.erase(key)

func _generate_terrain_mesh_threaded(key: Vector2i) -> ArrayMesh:
    var ox := key.x * chunk_size
    var oz := key.y * chunk_size
    var n := int(chunk_size / terrain_resolution) + 1
    var positions := PackedVector3Array()
    var uvs := PackedVector2Array()
    var indices := PackedInt32Array()

    for x in range(n):
        for z in range(n):
            var wx := ox + float(x) * terrain_resolution
            var wz := oz + float(z) * terrain_resolution
            var h := noise.get_noise_2d(wx, wz) * terrain_height
            positions.append(Vector3(float(x) * terrain_resolution, h, float(z) * terrain_resolution))
            uvs.append(Vector2(float(x) / (n - 1), float(z) / (n - 1)))

    for x in range(n - 1):
        for z in range(n - 1):
            var i := x * n + z
            indices.append_array([i, i + n, i + 1, i + 1, i + n, i + n + 1])

    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = positions
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh

func _create_vegetation(origin: Vector2) -> Node3D:
    var root := Node3D.new()
    root.name = "Vegetation"

    var area := Vector2(chunk_size, chunk_size)

    # Trees
    var tree_pts := _poisson_sample(area, tree_min_spacing)
    var tree_transforms: Array[Transform3D] = []
    for pt in tree_pts:
        var wx := origin.x + pt.x
        var wz := origin.y + pt.y
        var h := noise.get_noise_2d(wx, wz) * terrain_height
        var hn := (h / terrain_height + 1.0) * 0.5
        if hn > water_level_normalized + 0.04 and hn < 0.60:
            var t := Transform3D.IDENTITY
            t.origin = Vector3(pt.x, h, pt.y)
            t = t.rotated(Vector3.UP, randf() * TAU)
            var s := randf_range(0.7, 1.35)
            t.basis = t.basis.scaled(Vector3(s, s, s))
            tree_transforms.append(t)

    if tree_transforms.size() > 0:
        root.add_child(_build_multimesh(tree_transforms, _tree_mesh, null))

    # Grass
    var grass_pts := _poisson_sample(area, grass_min_spacing)
    var grass_transforms: Array[Transform3D] = []
    var grass_custom: Array[Color] = []
    for pt in grass_pts:
        var wx := origin.x + pt.x
        var wz := origin.y + pt.y
        var h := noise.get_noise_2d(wx, wz) * terrain_height
        var hn := (h / terrain_height + 1.0) * 0.5
        if hn > water_level_normalized and hn < 0.52:
            var t := Transform3D.IDENTITY
            t.origin = Vector3(pt.x, h, pt.y)
            t = t.rotated(Vector3.UP, randf() * TAU)
            var s := randf_range(0.6, 1.2)
            t.basis = t.basis.scaled(Vector3(s, s * randf_range(0.8, 1.4), s))
            grass_transforms.append(t)
            grass_custom.append(Color(randf() * TAU, 0.0, 0.0, 0.0))

    if grass_transforms.size() > 0:
        var grass_mmi := _build_multimesh(grass_transforms, _grass_mesh, grass_custom)
        grass_mmi.material_override = _grass_mat
        grass_mmi.visibility_range_end = 80.0
        grass_mmi.visibility_range_end_margin = 10.0
        root.add_child(grass_mmi)

    return root

func _build_multimesh(
    transforms: Array[Transform3D],
    mesh: Mesh,
    custom_data: Array[Color]
) -> MultiMeshInstance3D:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_colors = true
    mm.use_custom_data = custom_data != null and custom_data.size() > 0
    mm.mesh = mesh
    mm.instance_count = transforms.size()
    for i in transforms.size():
        mm.set_instance_transform(i, transforms[i])
        mm.set_instance_color(i, Color(randf_range(0.85, 1.0), randf_range(0.85, 1.0), randf_range(0.85, 1.0)))
        if mm.use_custom_data and i < custom_data.size():
            mm.set_instance_custom_data(i, custom_data[i])
    var mmi := MultiMeshInstance3D.new()
    mmi.multimesh = mm
    return mmi

func _create_terrain_material() -> ShaderMaterial:
    var mat := ShaderMaterial.new()
    var src := """
shader_type spatial;
uniform float water_level : hint_range(-1.0, 1.0) = -0.2;
uniform float sand_level : hint_range(-1.0, 1.0) = -0.05;
uniform float grass_level : hint_range(-1.0, 1.0) = 0.30;
uniform float rock_level : hint_range(-1.0, 1.0) = 0.65;
uniform float height_scale : hint_range(1.0, 200.0) = 40.0;
uniform vec3 water_color : source_color = vec3(0.1, 0.3, 0.6);
uniform vec3 sand_color : source_color = vec3(0.82, 0.72, 0.52);
uniform vec3 grass_color : source_color = vec3(0.22, 0.58, 0.12);
uniform vec3 rock_color : source_color = vec3(0.52, 0.50, 0.48);
uniform vec3 snow_color : source_color = vec3(0.95, 0.96, 1.0);
varying float v_world_y;
void vertex() {
    v_world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}
void fragment() {
    float h = v_world_y / height_scale;
    float slope = 1.0 - NORMAL.y;
    vec3 c = water_color;
    c = mix(c, sand_color,  smoothstep(water_level, sand_level,  h));
    c = mix(c, grass_color, smoothstep(sand_level,  grass_level, h));
    c = mix(c, rock_color,  smoothstep(grass_level, rock_level,  h));
    c = mix(c, snow_color,  smoothstep(rock_level,  1.0,         h));
    c = mix(c, rock_color,  smoothstep(0.4, 0.75, slope));
    ALBEDO = c;
    ROUGHNESS = 0.85;
    METALLIC = 0.0;
}
"""
    var shader := Shader.new()
    shader.code = src
    mat.shader = shader
    mat.set_shader_parameter("height_scale", terrain_height)
    return mat

func _create_grass_material() -> ShaderMaterial:
    var mat := ShaderMaterial.new()
    var src := """
shader_type spatial;
render_mode cull_disabled;
uniform float wind_strength : hint_range(0.0, 2.0) = 0.35;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.8;
uniform vec2 wind_direction = vec2(1.0, 0.3);
uniform vec3 base_color : source_color = vec3(0.25, 0.65, 0.12);
uniform vec3 tip_color : source_color = vec3(0.45, 0.82, 0.20);
varying float v_height;
void vertex() {
    v_height = UV.y * UV.y;
    float phase = INSTANCE_CUSTOM.x;
    float wx = MODEL_MATRIX[3].x;
    float wz = MODEL_MATRIX[3].z;
    float t = TIME * wind_speed + wx * 0.3 + wz * 0.2 + phase;
    float sway = sin(t) * wind_strength * v_height;
    VERTEX.x += wind_direction.x * sway;
    VERTEX.z += wind_direction.y * sway * 0.5;
    VERTEX.y -= abs(sway) * 0.08;
}
void fragment() {
    ALBEDO = mix(base_color, tip_color, v_height);
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
    AO = mix(0.25, 1.0, v_height);
    AO_LIGHT_AFFECT = 0.5;
}
"""
    var shader := Shader.new()
    shader.code = src
    mat.shader = shader
    return mat

func _create_placeholder_tree_mesh() -> Mesh:
    # In production: return preload("res://assets/meshes/tree.tres")
    var cm := CylinderMesh.new()
    cm.top_radius = 0.0
    cm.bottom_radius = 2.0
    cm.height = 5.0
    return cm

func _create_grass_blade_mesh() -> Mesh:
    # A simple quad, tall and narrow, UV.y goes 0..1 from root to tip
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var w := 0.12
    var h := 0.8
    # Front face
    st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(Vector3(-w, h, 0.0))
    st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(Vector3(0.0, 0.0, 0.0))
    st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(Vector3(w,  h, 0.0))
    st.add_index(0); st.add_index(1); st.add_index(2)
    # Back face (render_mode cull_disabled handles this but explicit is fine too)
    st.add_index(2); st.add_index(1); st.add_index(0)
    st.generate_normals()
    return st.commit()

# Poisson disk sampling (inline for self-containment)
func _poisson_sample(area: Vector2, min_dist: float, max_attempts: int = 30) -> Array[Vector2]:
    var points: Array[Vector2] = []
    var active: Array[Vector2] = []
    var cell := min_dist / sqrt(2.0)
    var gw := ceili(area.x / cell)
    var gh := ceili(area.y / cell)
    var grid: Array = []
    grid.resize(gw * gh)

    var first := Vector2(randf() * area.x, randf() * area.y)
    points.append(first)
    active.append(first)
    grid[int(first.x / cell) + int(first.y / cell) * gw] = first

    while active.size() > 0:
        var idx := randi() % active.size()
        var pt := active[idx]
        var found := false
        for _a in max_attempts:
            var ang := randf() * TAU
            var d := randf_range(min_dist, min_dist * 2.0)
            var c := pt + Vector2(cos(ang), sin(ang)) * d
            if c.x < 0.0 or c.x >= area.x or c.y < 0.0 or c.y >= area.y:
                continue
            var ci := Vector2i(int(c.x / cell), int(c.y / cell))
            var bad := false
            for dx in range(-2, 3):
                if bad: break
                for dy in range(-2, 3):
                    var ni := ci + Vector2i(dx, dy)
                    if ni.x < 0 or ni.x >= gw or ni.y < 0 or ni.y >= gh:
                        continue
                    var nb = grid[ni.x + ni.y * gw]
                    if nb != null and c.distance_to(nb) < min_dist:
                        bad = true
                        break
            if not bad:
                points.append(c)
                active.append(c)
                grid[ci.x + ci.y * gw] = c
                found = true
                break
        if not found:
            active.remove_at(idx)
    return points
```

### player.gd

```gdscript
# player.gd
class_name Player
extends CharacterBody3D

@export var move_speed: float = 8.0
@export var jump_velocity: float = 6.0
@export var mouse_sensitivity: float = 0.003

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

const GRAVITY := 20.0

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
        camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 3.0, PI / 3.0)

    if event.is_action_pressed("ui_cancel"):
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    # Gravity
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = 0.0

    # Jump
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = jump_velocity

    # Movement input
    var dir := Vector3.ZERO
    dir.x = Input.get_axis("ui_left", "ui_right")
    dir.z = Input.get_axis("ui_up", "ui_down")
    dir = dir.normalized()
    dir = transform.basis * dir  # rotate with player orientation

    velocity.x = dir.x * move_speed
    velocity.z = dir.z * move_speed

    move_and_slide()
```

Player scene structure:
```
Player (CharacterBody3D) — player.gd
├── CollisionShape3D (CapsuleShape3D: radius=0.4, height=1.8)
└── CameraPivot (Node3D — position: 0, 1.6, 0)
    └── Camera3D (position: 0, 0, -5 for third person, or 0,0,0 for first person)
```

---

## API Quick Reference

| Class / Property | Description |
|---|---|
| `FastNoiseLite` | Noise generator Resource |
| `.noise_type` | `TYPE_SIMPLEX_SMOOTH`, `TYPE_SIMPLEX`, `TYPE_PERLIN`, `TYPE_CELLULAR`, `TYPE_VALUE` |
| `.frequency` | Scale of features (low = wide hills) |
| `.fractal_type` | `FRACTAL_NONE`, `FRACTAL_FBM`, `FRACTAL_RIDGED`, `FRACTAL_PING_PONG` |
| `.fractal_octaves` | Number of detail layers (1–8) |
| `.fractal_lacunarity` | Frequency multiplier per octave (typically 2.0) |
| `.fractal_gain` | Amplitude multiplier per octave (typically 0.5) |
| `.get_noise_2d(x, z)` | Sample 2D noise, returns -1.0 to 1.0 |
| `.get_noise_3d(x, y, z)` | Sample 3D noise, returns -1.0 to 1.0 |
| `SurfaceTool` | Procedural mesh builder |
| `.begin(primitive)` | Start building: `Mesh.PRIMITIVE_TRIANGLES` |
| `.set_normal(v)` | Set normal for next vertex |
| `.set_uv(v)` | Set UV for next vertex |
| `.set_color(c)` | Set vertex color |
| `.add_vertex(v)` | Add a vertex |
| `.add_index(i)` | Add an index |
| `.generate_normals()` | Auto-compute normals from triangles |
| `.generate_tangents()` | Auto-compute tangents (needed for normal maps) |
| `.commit()` | Returns the `ArrayMesh` |
| `ArrayMesh` | Raw mesh format, use `add_surface_from_arrays()` |
| `ImmediateMesh` | Per-frame geometry, no indices |
| `MultiMesh` | Holds all instance data |
| `.transform_format` | `TRANSFORM_3D` or `TRANSFORM_2D` |
| `.use_colors` | Enable per-instance color |
| `.use_custom_data` | Enable per-instance `Color` (4 floats) for shaders |
| `.instance_count` | Total allocation (expensive to change) |
| `.visible_instance_count` | How many to render (-1 = all) |
| `.set_instance_transform(i, t)` | Set Transform3D for instance i |
| `.set_instance_color(i, c)` | Set Color for instance i |
| `.set_instance_custom_data(i, c)` | Set custom Color (INSTANCE_CUSTOM in shader) |
| `MultiMeshInstance3D` | Renders a MultiMesh in the scene |
| `GeometryInstance3D` | Base class with visibility range properties |
| `.visibility_range_begin` | Distance at which node starts showing |
| `.visibility_range_end` | Distance at which node stops showing (0 = off) |
| `.visibility_range_begin_margin` | Fade-in overlap zone |
| `.visibility_range_end_margin` | Fade-out overlap zone |
| `.visibility_range_fade_mode` | `DISABLED`, `SELF`, or `DEPENDENCIES` |
| `NavigationRegion3D` | Defines a walkable area |
| `.bake_navigation_mesh(async)` | Bakes the NavigationMesh (true = async) |
| `.bake_finished` | Signal emitted when async bake completes |
| `WorkerThreadPool.add_task(fn)` | Run a callable on a background thread |

---

## Common Pitfalls

### 1. Individual MeshInstance3D for Each Tree

**WRONG:**
```gdscript
# 2000 trees = 2000+ draw calls. Game runs at 4fps.
for pos in tree_positions:
    var mi := MeshInstance3D.new()
    mi.mesh = preload("res://assets/tree.tres")
    mi.global_position = pos
    add_child(mi)
```

**RIGHT:**
```gdscript
# 2000 trees = 1 draw call. Game runs fine.
var mm := MultiMesh.new()
mm.mesh = preload("res://assets/tree.tres")
mm.instance_count = tree_positions.size()
for i in tree_positions.size():
    mm.set_instance_transform(i, Transform3D(Basis(), tree_positions[i]))
var mmi := MultiMeshInstance3D.new()
mmi.multimesh = mm
add_child(mmi)
```

Use `MultiMeshInstance3D` for any repeated object. Individual `MeshInstance3D` is for unique, one-off objects.

---

### 2. Generating Chunks on the Main Thread

**WRONG:**
```gdscript
# Called every frame — causes a visible hitch every time a new chunk loads
func _process(_delta):
    var needed_key := get_nearest_unloaded_chunk()
    if needed_key:
        var mesh := generate_terrain(needed_key)  # takes 50-200ms
        spawn_chunk(needed_key, mesh)              # frame stutters here
```

**RIGHT:**
```gdscript
# Generation happens on a worker thread, applied via call_deferred
func load_chunk_async(key: Vector2i) -> void:
    WorkerThreadPool.add_task(func():
        var mesh := generate_terrain_threaded(key)   # off main thread
        call_deferred("apply_chunk", key, mesh)       # back on main thread
    )
```

Background generation keeps the main thread smooth. The chunk appears a fraction of a second later — acceptable. A frame hitch is not.

---

### 3. Sampling Noise with Integer Coordinates

**WRONG:**
```gdscript
# At high noise.frequency, this creates striped/repeating patterns
for x in range(size):
    for z in range(size):
        var h = noise.get_noise_2d(x, z)  # x and z are ints 0, 1, 2, 3...
```

**RIGHT:**
```gdscript
# World-space floats give continuous coverage across chunks
for x in range(size):
    for z in range(size):
        var world_x := chunk_origin_x + float(x) * resolution
        var world_z := chunk_origin_z + float(z) * resolution
        var h = noise.get_noise_2d(world_x, world_z)
```

Integer inputs are fine at low frequencies but break at the scales needed for realistic terrain. Always convert to world-space floats.

---

### 4. All Grass Swaying in Sync

**WRONG:**
```gdscript
# No phase offset — every blade hits the same point in the sine cycle.
# The field looks like a rigid sheet waving, not real grass.

# In vertex shader:
# float wind = sin(TIME * wind_speed) * wind_strength * UV.y * UV.y;
# VERTEX.x += wind;
```

**RIGHT:**
```gdscript
# Store random phase in custom data
for i in multi_mesh.instance_count:
    multi_mesh.set_instance_custom_data(i, Color(randf() * TAU, 0.0, 0.0, 0.0))

# In vertex shader:
# float phase = INSTANCE_CUSTOM.x;
# float wind = sin(TIME * wind_speed + MODEL_MATRIX[3].x * 0.3 + phase) * wind_strength;
# VERTEX.x += wind * UV.y * UV.y;
```

Per-instance phase offsets are the single most important visual improvement for wind animation. Cost is zero — the data is already stored in the MultiMesh.

---

### 5. Forgetting generate_normals() on Procedural Meshes

**WRONG:**
```gdscript
# No normals = flat, black shading.
# The mesh renders but lighting is completely wrong.
func create_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # ... add vertices and indices ...
    return st.commit()  # normals are all Vector3.ZERO — lighting broken
```

**RIGHT:**
```gdscript
func create_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # ... add vertices and indices ...
    st.generate_normals()    # compute normals from triangle geometry
    st.generate_tangents()   # compute tangents for normal mapping
    return st.commit()
```

`generate_normals()` must be called after all vertices and indices are added but before `commit()`. It reads the triangle geometry and computes correct smooth normals automatically.

---

## Exercises

### Exercise 1: Island Generator (30–45 minutes)

Generate a small island using a circular falloff multiplied onto the noise. The falloff ensures the edges of the terrain taper to sea level regardless of noise values, creating a natural island shape.

```gdscript
func island_height(x: float, z: float, island_radius: float) -> float:
    var noise_h := noise.get_noise_2d(x, z)  # -1..1

    # Distance from center, normalized to 0..1
    var dist := Vector2(x, z).length() / island_radius
    dist = clamp(dist, 0.0, 1.0)

    # Falloff: 1.0 at center, 0.0 at edge (smooth curve)
    var falloff := 1.0 - smoothstep(0.4, 1.0, dist)

    # Combine: multiply noise by falloff, then scale
    return noise_h * falloff * height_scale
```

Steps:
1. Create a single terrain mesh (not chunked) using `island_height()` instead of raw noise.
2. Add a flat water plane at Y=0 using a `PlaneMesh` with a semi-transparent blue `StandardMaterial3D`.
3. Adjust `island_radius` and `height_scale` until you like the shape.
4. Stretch goal: add a beach using the biome shader from section 4.

---

### Exercise 2: Biome-Specific Vegetation (60–90 minutes)

Add three vegetation types that spawn only in their appropriate biome zone. Use separate `MultiMesh` instances per type.

```gdscript
# Biome classification based on normalized height (0..1)
enum Biome { WATER, BEACH, GRASSLAND, HIGHLAND, ROCK, SNOW }

func classify_biome(normalized_height: float, slope: float) -> Biome:
    if normalized_height < 0.12:
        return Biome.WATER
    if normalized_height < 0.18:
        return Biome.BEACH
    if slope > 0.5:
        return Biome.ROCK
    if normalized_height < 0.55:
        return Biome.GRASSLAND
    if normalized_height < 0.75:
        return Biome.HIGHLAND
    if normalized_height < 0.88:
        return Biome.ROCK
    return Biome.SNOW
```

Place:
- **Flowers** (flat quads, small, dense) in `GRASSLAND` only — `grass_min_spacing = 0.8`
- **Desert bushes / rocks** in `BEACH` and `ROCK` — `min_spacing = 3.0`
- **Pine trees** in `HIGHLAND` only — `min_spacing = 8.0`

Each vegetation type gets its own `MultiMesh` with a different mesh and material. The filtering step happens when converting Poisson candidates to actual transforms — discard any candidate whose biome doesn't match the current vegetation type.

---

### Exercise 3: Cave System with 3D Noise (90–120 minutes)

Use `get_noise_3d(x, y, z)` to carve tunnels through terrain. This requires switching from a heightmap approach (one height per XZ position) to a density-based approach (solid if density > threshold, empty if below).

```gdscript
# Instead of: height = noise_2d(x, z) * scale
# Use: solid = noise_3d(x, y, z) > 0.0

func is_solid(x: float, y: float, z: float) -> bool:
    # Base terrain: positive density below ground level, negative above
    var base_density := -y / terrain_height  # positive underground, negative above
    var cave_noise := noise_3d.get_noise_3d(x, y, z)
    # Combine: underground is solid by default, caves carve it out
    return (base_density + cave_noise) > 0.0
```

To generate a mesh from 3D density:
- Use the **marching cubes** algorithm (research it — it's the standard approach).
- Simpler alternative: generate the terrain surface normally, then subtract cave regions using CSG nodes or by masking collision.

Steps:
1. Create a separate `FastNoiseLite` with `frequency = 0.03` for caves.
2. Modify `island_height()` or chunk generation to zero out any cell where `is_solid()` returns `false` at multiple Y levels.
3. Add collision to the cave ceilings and walls.
4. Stretch: place a `SpotLight3D` and some glowing crystal `MultiMesh` instances inside the caves.

---

## Key Takeaways

1. **FastNoiseLite is built in** — no packages, no setup. Pick a noise type (simplex for terrain, cellular for organic patterns), set frequency and octaves, and sample with `get_noise_2d(world_x, world_z)`.

2. **SurfaceTool builds meshes vertex by vertex.** Call `generate_normals()` and `generate_tangents()` before `commit()` or your lighting will be broken. For performance-critical generation, use `ArrayMesh` directly.

3. **MultiMeshInstance3D renders thousands of objects in one draw call.** It is the only practical approach for forests, grass fields, rock scatters, or any repeated object at scale. Never use individual `MeshInstance3D` for scattered objects.

4. **Poisson disk sampling gives natural-looking even spacing**, far better than pure random placement. The algorithm is O(n) and fast enough to run per-chunk at generation time. Use it for trees, rocks, and any object where clumping looks wrong.

5. **Wind shader + per-instance INSTANCE_CUSTOM phase offset** makes vegetation feel alive at zero per-frame CPU cost. The GPU handles all the math. The phase offsets prevent synchronized swaying, which is the visual difference between believable and uncanny.

6. **Chunk-based streaming** divides the world into tiles, loads tiles near the camera, and unloads distant ones. Use `WorkerThreadPool.add_task()` to generate mesh data off the main thread. Only touch the scene tree on the main thread via `call_deferred()`.

7. **Use fog to hide the draw distance boundary** — it's not a hack, it's standard practice in every open-world game ever shipped. Match your `visibility_range_end` to the distance where fog makes objects invisible and you'll never see chunks popping in.

---

## What's Next

**[Module 9: Audio & Game Feel](module-09-audio-game-feel.md)**

The world is infinite and beautiful. Now let's make it sound great and feel satisfying. Module 9 covers Godot's AudioStreamPlayer system, 3D spatial audio, ambient soundscapes that change by biome, procedural sound effects, screen shake, hitpause, controller rumble, and all the "juice" that separates a prototype from a polished game. We'll add footstep sounds that vary by terrain type and a dynamic music system that responds to what the player is doing.

---

**[Back to Godot 4 Game Dev Learning Roadmap](godot4-gamedev-learning-roadmap.md)**
