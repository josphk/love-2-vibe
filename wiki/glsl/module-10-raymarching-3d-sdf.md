# Module 10: Raymarching & 3D SDF Scenes

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 6–10 hours
**Prerequisites:** Module 2 (SDFs). Benefits from Module 5 (Noise) and Module 7 (2D Lighting).

---

## Overview

This is the peak of fragment shader programming. Raymarching lets you render fully lit 3D scenes — spheres, boxes, organic shapes, entire landscapes — in a single fragment shader with zero geometry. No meshes, no vertices, no engine. Just math.

The idea is deceptively simple. For each pixel, cast a ray from a virtual camera into the scene. March along the ray, evaluating a 3D SDF at each step. The SDF tells you the closest distance to any surface. If that distance is very small, you have hit something — shade it. If it is large, take a step of that size forward (you can safely advance by the SDF value because nothing is closer). If you have marched too far without hitting anything, color the pixel as background.

This is called **sphere tracing**, and it is the engine behind most top-rated ShaderToy creations. The same SDF concepts from Module 2 — primitives, boolean operations, smooth blending — extend directly into 3D. The lighting from Module 7 (normals, diffuse, specular, shadows) works identically. You already know the building blocks. This module assembles them into a complete 3D renderer.

---

## 1. The Ray: Camera Setup

Every raymarched shader starts by constructing a ray for each pixel: an origin (where the camera is) and a direction (which way this pixel looks into the scene).

### Camera Model

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Normalized pixel coordinates (centered, aspect-corrected)
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Camera
    vec3 ro = vec3(0.0, 1.0, -3.0);  // Ray origin (camera position)
    vec3 rd = normalize(vec3(uv, 1.0));  // Ray direction

    // ... march the ray ...
}
```

The ray direction `vec3(uv, 1.0)` creates a simple perspective camera:
- `uv.x` controls left-right (mapped from screen X)
- `uv.y` controls up-down (mapped from screen Y)
- The `1.0` z-component points forward into the scene

The `1.0` acts as a "focal length." Larger values = narrower field of view (telephoto). Smaller values = wider FOV (fisheye).

### Camera with Look-At

For a more flexible camera that can orbit the scene:

```glsl
mat3 lookAt(vec3 eye, vec3 target, vec3 up) {
    vec3 f = normalize(target - eye);    // Forward
    vec3 r = normalize(cross(f, up));    // Right
    vec3 u = cross(r, f);               // Up
    return mat3(r, u, f);               // Rotation matrix
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Orbiting camera
    float angle = iTime * 0.3;
    vec3 ro = vec3(sin(angle) * 3.0, 2.0, cos(angle) * 3.0);
    vec3 target = vec3(0.0, 0.5, 0.0);

    mat3 cam = lookAt(ro, target, vec3(0.0, 1.0, 0.0));
    vec3 rd = cam * normalize(vec3(uv, 1.0));

    // ... march ...
}
```

---

## 2. 3D SDF Primitives

The 2D SDFs from Module 2 extend naturally into 3D.

### Sphere

```glsl
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}
```

### Box

```glsl
float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}
```

### Plane (Infinite Ground)

```glsl
float sdPlane(vec3 p, float h) {
    return p.y - h;  // Horizontal plane at height h
}
```

### Torus

```glsl
float sdTorus(vec3 p, float R, float r) {
    vec2 q = vec2(length(p.xz) - R, p.y);
    return length(q) - r;
}
// R = major radius (ring size), r = minor radius (tube thickness)
```

### Cylinder

```glsl
float sdCylinder(vec3 p, float r, float h) {
    float d = length(p.xz) - r;     // Radial distance
    float d2 = abs(p.y) - h;        // Vertical distance from caps
    return min(max(d, d2), 0.0) + length(max(vec2(d, d2), 0.0));
}
```

### Capsule

```glsl
float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}
```

### Rounded Box

```glsl
float sdRoundBox(vec3 p, vec3 b, float r) {
    return sdBox(p, b - r) - r;
}
```

For the full catalog of 3D SDF primitives (octahedron, cone, pyramid, triangular prism, and many more), see [iquilezles.org/articles/distfunctions](https://iquilezles.org/articles/distfunctions/).

---

## 3. Sphere Tracing (The Raymarching Algorithm)

The core algorithm: march along the ray, evaluating the scene SDF at each step.

```glsl
float sceneSDF(vec3 p) {
    float sphere = sdSphere(p - vec3(0.0, 0.5, 0.0), 0.5);
    float ground = sdPlane(p, 0.0);
    return min(sphere, ground);
}

float rayMarch(vec3 ro, vec3 rd) {
    float t = 0.0;         // Total distance marched
    float tMax = 100.0;    // Maximum distance

    for (int i = 0; i < 128; i++) {
        vec3 p = ro + rd * t;   // Current position along the ray
        float d = sceneSDF(p);  // Distance to nearest surface

        if (d < 0.001) {
            return t;  // Hit! Return the distance
        }

        t += d;  // Advance by the safe distance

        if (t > tMax) {
            return -1.0;  // Missed everything
        }
    }

    return -1.0;  // Ran out of iterations
}
```

### Why It Works

```
Camera     Step 1        Step 2     Step 3   Hit!
  ●────────○─────────────○──────────○────○●
  ro       d=5.0         d=3.2      d=0.8 d=0.001

At each step, d = sceneSDF(p) tells us the MINIMUM distance
to any surface. So we can safely step forward by d — nothing
is closer than that. This is "sphere tracing."
```

The beauty: in open space, steps are large (the SDF returns large values). Near surfaces, steps get tiny (the SDF approaches zero). The algorithm naturally adapts its step size — fast in open areas, precise near geometry.

### Parameters

- **Max iterations (128):** More iterations = more precision for complex scenes. 64 is fine for simple scenes. 256 for detailed ones.
- **Hit threshold (0.001):** How close is "close enough" to count as a hit. Smaller = more precise but more iterations needed.
- **Max distance (100.0):** How far to march before giving up. Set based on your scene size.

---

## 4. Surface Normals in 3D

The normal at a hit point is the gradient of the SDF — exactly as in 2D (Module 7), but with a Z component:

```glsl
vec3 calcNormal(vec3 p) {
    float eps = 0.001;
    return normalize(vec3(
        sceneSDF(p + vec3(eps, 0.0, 0.0)) - sceneSDF(p - vec3(eps, 0.0, 0.0)),
        sceneSDF(p + vec3(0.0, eps, 0.0)) - sceneSDF(p - vec3(0.0, eps, 0.0)),
        sceneSDF(p + vec3(0.0, 0.0, eps)) - sceneSDF(p - vec3(0.0, 0.0, eps))
    ));
}
```

This evaluates the SDF 6 times (central differences in X, Y, Z). The result is a unit vector pointing away from the surface.

### Optimized Version (Tetrahedron Technique)

Uses only 4 SDF evaluations instead of 6:

```glsl
vec3 calcNormal(vec3 p) {
    const vec2 e = vec2(0.001, -0.001);
    return normalize(
        e.xyy * sceneSDF(p + e.xyy) +
        e.yyx * sceneSDF(p + e.yyx) +
        e.yxy * sceneSDF(p + e.yxy) +
        e.xxx * sceneSDF(p + e.xxx)
    );
}
```

---

## 5. Lighting in 3D

The same lighting model from Module 7, now in full 3D:

```glsl
vec3 shade(vec3 p, vec3 rd) {
    vec3 normal = calcNormal(p);
    vec3 lightDir = normalize(vec3(1.0, 1.0, -0.5));
    vec3 lightColor = vec3(1.0, 0.95, 0.8);

    // Ambient
    vec3 ambient = vec3(0.05, 0.05, 0.1);

    // Diffuse
    float diff = max(dot(normal, lightDir), 0.0);

    // Specular (Blinn-Phong)
    vec3 halfDir = normalize(lightDir - rd);  // rd is view direction (negated)
    float spec = pow(max(dot(normal, halfDir), 0.0), 32.0);

    vec3 surfaceColor = vec3(0.8, 0.4, 0.3);
    vec3 color = ambient
               + surfaceColor * diff * lightColor
               + vec3(1.0) * spec * lightColor * 0.5;

    return color;
}
```

### Per-Object Materials

To give different shapes different colors, return a material ID from the scene SDF:

```glsl
vec2 sceneSDF(vec3 p) {
    float sphere = sdSphere(p - vec3(0.0, 0.5, 0.0), 0.5);
    float ground = sdPlane(p, 0.0);

    if (sphere < ground) {
        return vec2(sphere, 1.0);  // Distance, material ID = 1
    } else {
        return vec2(ground, 2.0);  // Distance, material ID = 2
    }
}

// In the shader:
vec3 getSurfaceColor(float matID) {
    if (matID < 1.5) return vec3(0.8, 0.3, 0.2);  // Sphere: red
    else             return vec3(0.5, 0.5, 0.5);   // Ground: gray
}
```

---

## 6. Shadows

### Hard Shadows

March a secondary ray from the hit point toward the light:

```glsl
float shadow(vec3 p, vec3 lightDir, float maxDist) {
    float t = 0.02;  // Offset to avoid self-shadowing

    for (int i = 0; i < 64; i++) {
        float d = sceneSDF(p + lightDir * t);
        if (d < 0.001) return 0.0;  // Hit something — in shadow
        t += d;
        if (t > maxDist) break;
    }

    return 1.0;  // Fully lit
}
```

### Soft Shadows

Track the closest approach for penumbra:

```glsl
float softShadow(vec3 p, vec3 lightDir, float maxDist, float k) {
    float t = 0.02;
    float res = 1.0;

    for (int i = 0; i < 64; i++) {
        float d = sceneSDF(p + lightDir * t);
        if (d < 0.001) return 0.0;
        res = min(res, k * d / t);
        t += d;
        if (t > maxDist) break;
    }

    return clamp(res, 0.0, 1.0);
}
```

`k` controls softness: `k = 2.0` for very soft, `k = 32.0` for nearly hard.

---

## 7. Ambient Occlusion

SDF-based AO in 3D (same concept as Module 7):

```glsl
float ambientOcclusion(vec3 p, vec3 n) {
    float ao = 0.0;
    float scale = 1.0;

    for (int i = 1; i <= 5; i++) {
        float dist = 0.02 * float(i);
        float d = sceneSDF(p + n * dist);
        ao += (dist - d) * scale;
        scale *= 0.5;
    }

    return clamp(1.0 - ao * 3.0, 0.0, 1.0);
}
```

---

## 8. Boolean Operations in 3D

All the 2D boolean operations from Module 2 work identically in 3D:

```glsl
// Union
float d = min(d1, d2);

// Intersection
float d = max(d1, d2);

// Subtraction
float d = max(d1, -d2);

// Smooth union
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
```

### Example: Organic Shape

```glsl
float sceneSDF(vec3 p) {
    // Three spheres melted together
    float s1 = sdSphere(p - vec3(0.0, 0.5, 0.0), 0.4);
    float s2 = sdSphere(p - vec3(0.3, 0.7, 0.1), 0.3);
    float s3 = sdSphere(p - vec3(-0.2, 0.3, -0.1), 0.25);

    float d = smin(s1, s2, 0.2);
    d = smin(d, s3, 0.2);

    // Subtract an internal cavity
    float cavity = sdSphere(p - vec3(0.0, 0.6, 0.0), 0.15);
    d = max(d, -cavity);

    // Ground plane
    float ground = p.y;
    d = min(d, ground);

    return d;
}
```

### Repetition (Infinite Grid)

```glsl
float sceneSDF(vec3 p) {
    // Infinite grid of spheres
    vec3 spacing = vec3(2.0);
    vec3 rp = mod(p + spacing * 0.5, spacing) - spacing * 0.5;
    return sdSphere(rp, 0.3);
}
```

### Twist

Rotate the XZ plane based on Y:

```glsl
float twistedBox(vec3 p, float twist) {
    float angle = p.y * twist;
    float c = cos(angle), s = sin(angle);
    p.xz = mat2(c, -s, s, c) * p.xz;
    return sdBox(p, vec3(0.2, 1.0, 0.2));
}
```

### Bend

Curve one axis based on another:

```glsl
float bentBox(vec3 p, float bend) {
    float c = cos(bend * p.y), s = sin(bend * p.y);
    p.xy = mat2(c, -s, s, c) * p.xy;
    return sdBox(p, vec3(0.2, 1.0, 0.2));
}
```

---

## 9. Fog and Atmosphere

Distance-based fog creates depth and atmosphere:

```glsl
// Linear fog
vec3 applyFog(vec3 color, float dist, vec3 fogColor) {
    float fog = clamp(dist / 50.0, 0.0, 1.0);
    return mix(color, fogColor, fog);
}

// Exponential fog (more natural)
vec3 applyFog(vec3 color, float dist, vec3 fogColor) {
    float fog = 1.0 - exp(-dist * 0.05);
    return mix(color, fogColor, fog);
}
```

### Sky Color

For rays that miss all geometry:

```glsl
vec3 skyColor(vec3 rd) {
    // Simple gradient sky
    float t = rd.y * 0.5 + 0.5;  // 0 at horizon, 1 at zenith
    return mix(vec3(0.7, 0.8, 0.9), vec3(0.2, 0.4, 0.8), t);
}
```

---

## Code Walkthrough: Complete Raymarched Scene

```glsl
// --- SDF Primitives ---
float sdSphere(vec3 p, float r) { return length(p) - r; }
float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}

// --- Scene ---
float sceneSDF(vec3 p) {
    // Sphere
    float sphere = sdSphere(p - vec3(0.0, 0.6, 0.0), 0.5);
    // Box
    float box = sdBox(p - vec3(1.2, 0.35, 0.5), vec3(0.35));
    // Torus
    vec3 tp = p - vec3(-1.0, 0.4, 0.3);
    float torus = length(vec2(length(tp.xz) - 0.4, tp.y)) - 0.15;
    // Ground
    float ground = p.y;

    float d = min(sphere, box);
    d = min(d, torus);
    d = min(d, ground);
    return d;
}

// --- Normal ---
vec3 calcNormal(vec3 p) {
    const vec2 e = vec2(0.001, -0.001);
    return normalize(
        e.xyy * sceneSDF(p + e.xyy) + e.yyx * sceneSDF(p + e.yyx) +
        e.yxy * sceneSDF(p + e.yxy) + e.xxx * sceneSDF(p + e.xxx)
    );
}

// --- Shadow ---
float softShadow(vec3 ro, vec3 rd, float tMax, float k) {
    float t = 0.02, res = 1.0;
    for (int i = 0; i < 64; i++) {
        float d = sceneSDF(ro + rd * t);
        if (d < 0.001) return 0.0;
        res = min(res, k * d / t);
        t += d;
        if (t > tMax) break;
    }
    return clamp(res, 0.0, 1.0);
}

// --- AO ---
float ao(vec3 p, vec3 n) {
    float occ = 0.0, s = 1.0;
    for (int i = 1; i <= 5; i++) {
        float dist = 0.02 * float(i);
        occ += (dist - sceneSDF(p + n * dist)) * s;
        s *= 0.5;
    }
    return clamp(1.0 - occ * 3.0, 0.0, 1.0);
}

// --- Raymarch ---
float rayMarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 128; i++) {
        float d = sceneSDF(ro + rd * t);
        if (d < 0.001) return t;
        t += d;
        if (t > 50.0) return -1.0;
    }
    return -1.0;
}

// --- Camera ---
mat3 lookAt(vec3 eye, vec3 target, vec3 up) {
    vec3 f = normalize(target - eye);
    vec3 r = normalize(cross(f, up));
    vec3 u = cross(r, f);
    return mat3(r, u, f);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // --- Camera ---
    float angle = iTime * 0.3;
    vec3 ro = vec3(sin(angle) * 4.0, 2.0, cos(angle) * 4.0);
    vec3 target = vec3(0.0, 0.3, 0.0);
    mat3 cam = lookAt(ro, target, vec3(0.0, 1.0, 0.0));
    vec3 rd = cam * normalize(vec3(uv, 1.2));

    // --- March ---
    float t = rayMarch(ro, rd);

    // --- Shade ---
    vec3 color;

    if (t > 0.0) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        vec3 lightDir = normalize(vec3(0.8, 0.6, -0.5));

        // Diffuse
        float diff = max(dot(n, lightDir), 0.0);

        // Specular
        vec3 h = normalize(lightDir - rd);
        float spec = pow(max(dot(n, h), 0.0), 32.0);

        // Shadow
        float shad = softShadow(p + n * 0.01, lightDir, 10.0, 8.0);

        // AO
        float occ = ao(p, n);

        // Surface color (checkerboard ground)
        vec3 surfColor = vec3(0.6, 0.5, 0.4);
        if (p.y < 0.01) {
            // Ground: checkerboard
            float check = mod(floor(p.x) + floor(p.z), 2.0);
            surfColor = mix(vec3(0.4), vec3(0.8), check);
        }

        // Combine
        vec3 ambient = surfColor * 0.1;
        color = ambient
              + surfColor * diff * shad * occ
              + vec3(1.0) * spec * shad * 0.3;

        // Fog
        float fog = 1.0 - exp(-t * 0.04);
        color = mix(color, vec3(0.7, 0.8, 0.9), fog);
    } else {
        // Sky
        float skyGrad = rd.y * 0.5 + 0.5;
        color = mix(vec3(0.7, 0.8, 0.9), vec3(0.3, 0.5, 0.9), skyGrad);
    }

    // Gamma
    color = pow(color, vec3(0.4545));

    fragColor = vec4(color, 1.0);
}
```

### What This Demonstrates

- **Complete raymarching pipeline** — camera → ray → march → shade → output
- **Multiple 3D primitives** — sphere, box, torus, ground plane
- **Look-at camera** — orbits the scene over time
- **Full lighting** — diffuse + specular + soft shadows + ambient occlusion
- **Checkerboard ground** — per-object material using world position
- **Distance fog** — exponential fog for depth
- **Sky gradient** — based on ray direction for missed rays
- **Gamma correction** — `pow(color, 0.4545)` for correct brightness

---

## GLSL Quick Reference

| Function/Concept | Description | Example |
|---|---|---|
| Ray origin/direction | Camera position + per-pixel direction | `ro = vec3(0,1,-3); rd = normalize(vec3(uv,1))` |
| `lookAt(eye, target, up)` | Camera rotation matrix | Orbiting camera |
| `sdSphere(p, r)` | 3D sphere SDF | `length(p) - r` |
| `sdBox(p, b)` | 3D box SDF | Half-dimensions `b` |
| `sdPlane(p, h)` | Ground plane at height h | `p.y - h` |
| `sdTorus(p, R, r)` | Torus SDF | Major radius R, tube radius r |
| Sphere tracing | March along ray by SDF value | `t += sceneSDF(ro + rd * t)` |
| `calcNormal(p)` | SDF gradient (6 or 4 samples) | Central or tetrahedral differences |
| Soft shadow | Secondary ray, track closest approach | `min(res, k * d / t)` |
| Ambient occlusion | Sample SDF along normal | Darkens concavities |
| `min(d1, d2)` | Union | Merge shapes |
| `max(d1, -d2)` | Subtraction | Cut d2 from d1 |
| `smin(d1, d2, k)` | Smooth union | Organic blending |
| `mod(p, spacing)` | Infinite repetition | Tiled shapes |
| Twist/Bend | Rotate/curve coords along an axis | Domain deformation |
| Fog | `mix(color, fogColor, 1-exp(-t*k))` | Distance-based atmosphere |

---

## Common Pitfalls

### 1. Insufficient March Iterations

If shapes have holes or missing faces, increase the iteration count:

```glsl
// 64 may not be enough for complex scenes:
for (int i = 0; i < 64; i++) { ... }

// Try 128 or 256:
for (int i = 0; i < 128; i++) { ... }
```

### 2. Hit Threshold Too Large

A threshold of `0.01` causes visible surface bumps. Use `0.001` or smaller:

```glsl
if (d < 0.001) return t;  // Good precision
```

### 3. Shadow Acne

Start shadow rays slightly off the surface:

```glsl
// WRONG — starts on the surface:
float shad = softShadow(p, lightDir, ...);

// RIGHT — offset along the normal:
float shad = softShadow(p + n * 0.01, lightDir, ...);
```

### 4. Normals Pointing Inward

If lighting looks inverted, the normal might be pointing the wrong way. Check by visualizing normals as color:

```glsl
// Debug: show normals as RGB
color = n * 0.5 + 0.5;
```

### 5. Performance

Each pixel runs the full ray march loop. Complex scenes with many SDF evaluations per step can be slow. Optimizations:
- Reduce max iterations for distant rays
- Use bounding volumes (skip SDF if outside a bounding sphere)
- Lower the resolution (`iResolution / 2.0`)
- Simplify the scene SDF

---

## Exercises

### Exercise 1: Primitive Gallery

**Time:** 30–45 minutes

Create a raymarched scene displaying at least 5 different 3D primitives:

1. Sphere, box, torus, cylinder, capsule
2. Arrange them in a line or circle so all are visible
3. Add a ground plane with a checkerboard pattern
4. Light with a single directional light (diffuse + specular)
5. Add a slowly orbiting camera

**Concepts practiced:** 3D SDF primitives, raymarching, camera, basic lighting

---

### Exercise 2: Organic Sculpture

**Time:** 45–60 minutes

Build an organic-looking sculpture using smooth boolean operations:

1. Start with 3+ spheres at different positions
2. Use `smin` (smooth union) to melt them together
3. Subtract an internal cavity using `max(d, -cavity)`
4. Add a twist or bend deformation
5. Light with two colored lights + soft shadows
6. Animate some element (pulsing radius, rotating twist)

**Concepts practiced:** Smooth boolean operations, domain deformation, multiple lights, animation

---

### Exercise 3: Raymarched Landscape

**Time:** 60–90 minutes

Create a terrain landscape:

1. Use a ground plane displaced by fBM noise from Module 5: `p.y - fbm(p.xz * 0.5) * 2.0`
2. Add a sky gradient based on ray direction
3. Light with a directional "sun" light
4. Add soft shadows (the terrain shadows itself)
5. Add exponential fog for depth
6. Color the terrain based on height (water/grass/rock/snow)

**Stretch:** Add a sun in the sky (bright spot in the background), animate the sun position, and add specular highlights on the water.

**Concepts practiced:** Noise-based terrain, full lighting pipeline, fog, height-based coloring

---

## Key Takeaways

1. **Raymarching renders 3D scenes from a single fragment shader.** No meshes, no vertices — just an SDF function evaluated at points along each pixel's ray. The sphere tracing algorithm steps by the SDF value, making it both efficient and elegant.

2. **3D SDFs are natural extensions of 2D.** Sphere is `length(p) - r`. Box uses `abs(p) - b`. Boolean operations (`min`, `max`, `smin`) work identically. If you mastered 2D SDFs in Module 2, you already understand 3D SDFs.

3. **Normals come from the SDF gradient.** Sample the SDF at small offsets in X, Y, Z and normalize the differences. Four samples (tetrahedron method) are sufficient and efficient.

4. **Lighting reuses Module 7 concepts in 3D.** Diffuse (`dot(n, l)`), specular (`pow(dot(n, h), shininess)`), shadows (secondary ray march), and AO (sample along normal) — all identical to 2D, just with a Z component.

5. **Domain operations create complex geometry.** Repetition (`mod`), twist (rotate XZ by Y), bend (rotate XY by Y), and smooth union let you build organic, impossible shapes from simple primitives.

6. **Fog and sky complete the scene.** Distance-based fog adds depth. A sky gradient based on ray direction provides a background. Together, they make the difference between a demo and a scene.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [Inigo Quilez: 3D Distance Functions](https://iquilezles.org/articles/distfunctions/) | Reference | The definitive catalog of 3D SDF primitives with code and interactive demos. Bookmark this. |
| [Inigo Quilez: Raymarching SDFs](https://iquilezles.org/articles/raymarchingdf/) | Article | The sphere tracing algorithm explained by its modern popularizer. |
| [Inigo Quilez: Soft Shadows](https://iquilezles.org/articles/rmshadows/) | Article | Soft shadow technique with penumbra. The `k * d / t` formula explained in depth. |
| [Jamie Wong: Ray Marching and SDFs](https://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/) | Blog | Excellent illustrated walkthrough with interactive demos. Great for visual learners. |
| [The Art of Code: Raymarching (YouTube)](https://www.youtube.com/watch?v=PGtv-dBi2wE) | Video | Step-by-step video tutorial building a raymarched scene from scratch in ShaderToy. |

---

## What's Next?

You have built a complete 3D renderer in a fragment shader. Combined with noise (Module 5 for terrain), lighting (Module 7 concepts), and post-processing (Module 9 for bloom and color grading), you can create cinematic 3D scenes entirely from math.

- **[Module 11: Animation, Motion & Interactive](module-11-animation-motion-interactive.md)** — Add easing, sequencing, audio reactivity, and buffer feedback to your scenes.
- **[Module 12: Porting to Engines](module-12-porting-to-engines.md)** — Bring your shaders into Godot, Love2D, or React Three Fiber.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
