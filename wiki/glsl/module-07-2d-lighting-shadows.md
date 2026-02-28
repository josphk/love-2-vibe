# Module 7: 2D Lighting & Shadows

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 5–7 hours
**Prerequisites:** Module 2 (SDFs), Module 5 (Noise)

---

## Overview

A flat 2D scene becomes atmospheric the moment you add lighting. A dark room with two colored point lights, shapes casting soft shadows, a specular glint on a surface — these effects transform programmer-art circles and rectangles into something that feels tangible and moody.

The beautiful part: 2D lighting in shaders is a cheat, and a gorgeous one. You are not simulating photons bouncing around a scene. You are computing a few dot products per pixel and multiplying by some falloff curves. The math is simple. The results are stunning. And because SDFs already give you distance information, you get shadow casting almost for free.

This module teaches you the lighting pipeline for 2D SDF scenes: point lights with distance falloff, diffuse shading using surface normals (which you can derive from the SDF gradient), specular highlights for shininess, and shadow computation by marching from each pixel toward the light. By the end, you will be able to build atmospheric 2D scenes with multiple colored lights, soft shadows, and material properties.

---

## 1. Point Lights: The Fundamentals

A point light has a position, a color, and an intensity. Its contribution to a pixel depends on two things: the distance from the pixel to the light, and the angle between the surface and the light direction.

### Basic Attenuation

```glsl
vec3 pointLight(vec2 pixelPos, vec2 lightPos, vec3 lightColor, float intensity) {
    float dist = length(pixelPos - lightPos);
    float attenuation = intensity / (dist * dist + 0.01);
    return lightColor * attenuation;
}
```

The `1 / (dist² + epsilon)` formula is the inverse-square law of light — the same physics that governs real light sources. The `+ 0.01` prevents division by zero when the pixel is exactly at the light position.

### Using It

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Dark background
    vec3 color = vec3(0.02);

    // Point light that follows the mouse
    vec2 lightPos = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;
    color += pointLight(uv, lightPos, vec3(1.0, 0.8, 0.5), 0.01);

    fragColor = vec4(color, 1.0);
}
```

### Multiple Lights

Just add the contributions:

```glsl
// Warm light (upper left)
vec2 light1Pos = vec2(-0.3, 0.2);
vec3 light1Color = vec3(1.0, 0.7, 0.3);
color += pointLight(uv, light1Pos, light1Color, 0.005);

// Cool light (lower right)
vec2 light2Pos = vec2(0.3, -0.2);
vec3 light2Color = vec3(0.3, 0.5, 1.0);
color += pointLight(uv, light2Pos, light2Color, 0.005);

// Green light (orbiting)
vec2 light3Pos = vec2(cos(iTime), sin(iTime)) * 0.25;
vec3 light3Color = vec3(0.2, 1.0, 0.3);
color += pointLight(uv, light3Pos, light3Color, 0.003);
```

Multiple colored lights create rich, atmospheric scenes. Where lights overlap, colors blend additively — warm and cool lights mixing to create white or unexpected hues.

### Custom Attenuation Curves

The `1/d²` falloff is physically correct but sometimes too sharp. You can use softer falloff curves:

```glsl
// Physically correct (sharp falloff)
float atten = intensity / (dist * dist);

// Linear falloff (gentler)
float atten = intensity / (dist + 0.1);

// Smooth radius (light has a defined range)
float atten = intensity * smoothstep(radius, 0.0, dist);

// Exponential (artistic control)
float atten = intensity * exp(-dist * falloffRate);
```

---

## 2. Surface Normals from SDFs

To compute how light interacts with a surface, you need the **surface normal** — the direction the surface faces at each point. In 3D, normals come from mesh data. In 2D SDF scenes, you can derive them from the SDF gradient.

### The SDF Gradient

The gradient of the SDF at any point tells you the direction of steepest distance increase — which is the direction pointing away from the surface. This is the surface normal.

```glsl
vec2 sdfNormal(vec2 p, float eps) {
    float d = sceneSDF(p);
    float dx = sceneSDF(p + vec2(eps, 0.0)) - d;
    float dy = sceneSDF(p + vec2(0.0, eps)) - d;
    return normalize(vec2(dx, dy));
}
```

This samples the SDF at two nearby points (one shifted in X, one in Y) and computes how fast the distance changes in each direction. The result is a 2D vector pointing away from the nearest surface.

### More Accurate (Central Differences)

```glsl
vec2 sdfNormal(vec2 p, float eps) {
    return normalize(vec2(
        sceneSDF(p + vec2(eps, 0.0)) - sceneSDF(p - vec2(eps, 0.0)),
        sceneSDF(p + vec2(0.0, eps)) - sceneSDF(p - vec2(0.0, eps))
    ));
}
```

Central differences (sampling on both sides) is more accurate but requires twice as many SDF evaluations. For 2D, the performance cost is negligible.

### Choosing Epsilon

`eps` should be small enough to capture surface curvature but large enough to avoid floating-point noise:

```glsl
float eps = 0.001;  // Works for most 2D scenes
```

For resolution-independent precision, you can base it on pixel size:

```glsl
float eps = 1.0 / iResolution.y;
```

---

## 3. Diffuse Lighting

Diffuse lighting simulates matte surfaces that scatter light equally in all directions. The brightness depends on the angle between the surface normal and the light direction.

### The Dot Product Rule

```
         Normal (n)
           ↑
           │  ╱ Light direction (l)
           │╱
    ───────●──────── Surface
```

`dot(n, l)` gives the cosine of the angle between the normal and the light direction:
- `dot = 1.0` → Light hits head-on → maximum brightness
- `dot = 0.0` → Light grazes the surface → no illumination
- `dot < 0.0` → Light hits the back → clamped to 0

### Implementation

```glsl
float sceneSDF(vec2 p) {
    // Your scene SDF (from Module 2)
    float d = sdCircle(p, 0.3);
    // Add more shapes...
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float eps = 0.001;

    float d = sceneSDF(uv);

    // Surface normal
    vec2 normal = normalize(vec2(
        sceneSDF(uv + vec2(eps, 0.0)) - sceneSDF(uv - vec2(eps, 0.0)),
        sceneSDF(uv + vec2(0.0, eps)) - sceneSDF(uv - vec2(0.0, eps))
    ));

    // Light setup
    vec2 lightPos = vec2(0.3, 0.3);
    vec2 lightDir = normalize(lightPos - uv);

    // Diffuse: how directly does the light hit the surface?
    float diffuse = max(dot(normal, lightDir), 0.0);

    // Attenuation
    float dist = length(lightPos - uv);
    float atten = 0.01 / (dist * dist + 0.01);

    // Combine
    vec3 surfaceColor = vec3(0.8, 0.3, 0.2);
    vec3 lightColor = vec3(1.0, 0.9, 0.7);

    vec3 color = surfaceColor * diffuse * lightColor * atten;

    // Ambient light (so shadows aren't pure black)
    vec3 ambient = surfaceColor * 0.05;
    color += ambient;

    // Only show lighting on the surface (inside the SDF)
    float mask = smoothstep(0.01, 0.0, d);
    color *= mask;

    fragColor = vec4(color, 1.0);
}
```

### Ambient Light

Without ambient light, surfaces facing away from the light are pure black, which looks unnatural. A small constant ambient term prevents this:

```glsl
vec3 ambient = surfaceColor * 0.05;  // 5% base brightness
color = ambient + surfaceColor * diffuse * lightColor * atten;
```

---

## 4. Specular Highlights

Specular highlights simulate shiny, reflective surfaces. They create bright spots where the light reflects toward the viewer.

### The Phong Model

```
            Normal
              ↑
     Light ╱  │  ╲ Reflection
          ╱   │   ╲
    ─────●────│────●───── Surface
              │
              │ View direction (toward camera)
              ↓
```

Specular brightness depends on how close the reflected light direction is to the view direction:

```glsl
// Reflect the light direction around the normal
vec2 reflectDir = reflect(-lightDir, normal);

// In 2D, the view direction is straight out of the screen: (0, 0, 1)
// For 2D, we can use the normal itself as an approximation
// or project into 3D:
vec3 normal3D = vec3(normal, 0.0);
vec3 lightDir3D = vec3(lightDir, 0.5);  // Light slightly above the surface
vec3 viewDir = vec3(0.0, 0.0, 1.0);     // Camera looking down at the 2D scene

vec3 reflectDir3D = reflect(-normalize(lightDir3D), normalize(normal3D + vec3(0, 0, 1)));
float specular = pow(max(dot(reflectDir3D, viewDir), 0.0), shininess);
```

### Simplified 2D Specular

For 2D work, a simpler approach uses the half-vector:

```glsl
// Half-vector between light dir and view dir
// In 2D with top-down view, this simplifies to:
float specular = pow(max(dot(normal, lightDir), 0.0), shininess);
// This isn't physically accurate but looks convincing in 2D
```

A more correct version treats the light as slightly elevated:

```glsl
float specular2D(vec2 normal, vec2 lightDir, float shininess) {
    // Pretend the light and camera are slightly above the 2D plane
    vec3 n = normalize(vec3(normal, 1.0));
    vec3 l = normalize(vec3(lightDir, 0.5));
    vec3 v = vec3(0.0, 0.0, 1.0);

    vec3 h = normalize(l + v);  // Half-vector (Blinn-Phong)
    return pow(max(dot(n, h), 0.0), shininess);
}
```

### Shininess Parameter

The `shininess` (or `n` in `pow(..., n)`) controls the size of the specular highlight:
- `n = 4` → Large, soft highlight (rubber, skin)
- `n = 16` → Medium highlight (plastic)
- `n = 64` → Small, tight highlight (polished metal)
- `n = 256` → Pinpoint highlight (mirror, chrome)

### Combining Diffuse and Specular

```glsl
vec3 lighting = vec3(0.0);

// Ambient
lighting += surfaceColor * ambientStrength;

// Diffuse
float diff = max(dot(normal, lightDir), 0.0);
lighting += surfaceColor * diff * lightColor * atten;

// Specular
float spec = specular2D(normal, lightDir, 32.0);
lighting += specularColor * spec * lightColor * atten;
```

---

## 5. Normal Maps for 2D

A normal map is a texture where each pixel's RGB values encode a surface normal direction. This is how flat 2D sprites appear to have depth and react to light.

### How Normal Maps Work

```
Normal map encoding:
R channel → X component of normal (-1 to 1, mapped to 0–1)
G channel → Y component of normal (-1 to 1, mapped to 0–1)
B channel → Z component of normal (always positive, usually dominant)

A flat surface facing up: RGB = (0.5, 0.5, 1.0) → Normal = (0, 0, 1)
A surface tilted right:   RGB = (1.0, 0.5, 0.5) → Normal = (1, 0, 0)
```

### Decoding a Normal Map

```glsl
vec3 normalFromMap(sampler2D normalTex, vec2 uv) {
    vec3 n = texture(normalTex, uv).rgb;
    n = n * 2.0 - 1.0;  // Remap from [0,1] to [-1,1]
    return normalize(n);
}
```

### Using Normal Maps in 2D Lighting

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Sample the diffuse texture (the sprite)
    vec3 diffuseTex = texture(iChannel0, uv).rgb;

    // Sample the normal map
    vec3 normal = texture(iChannel1, uv).rgb * 2.0 - 1.0;
    normal = normalize(normal);

    // Light position (in UV space or centered coords)
    vec2 lightPos = iMouse.xy / iResolution.xy;
    vec3 lightDir = normalize(vec3(lightPos - uv, 0.3));  // Light slightly above

    // Diffuse
    float diff = max(dot(normal, lightDir), 0.0);

    // Specular
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 halfDir = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, halfDir), 0.0), 32.0);

    // Attenuation
    float dist = length(lightPos - uv);
    float atten = 0.03 / (dist * dist + 0.01);

    // Combine
    vec3 ambient = diffuseTex * 0.1;
    vec3 color = ambient
               + diffuseTex * diff * atten
               + vec3(1.0) * spec * atten * 0.5;

    fragColor = vec4(color, 1.0);
}
```

### Procedural Normal Maps

You can generate normal maps from procedural content. For example, use noise to create a bumpy surface:

```glsl
vec3 proceduralNormal(vec2 uv, float bumpScale) {
    float eps = 0.001;

    // Use noise as a height map
    float h  = fbm(uv * 10.0);
    float hx = fbm((uv + vec2(eps, 0.0)) * 10.0);
    float hy = fbm((uv + vec2(0.0, eps)) * 10.0);

    // Compute gradient (slope in X and Y)
    float dx = (hx - h) / eps;
    float dy = (hy - h) / eps;

    // Normal from gradient
    return normalize(vec3(-dx * bumpScale, -dy * bumpScale, 1.0));
}
```

---

## 6. Shadows from SDFs

One of the greatest advantages of SDF-based scenes: shadow computation is natural. To determine if a point is in shadow, march from the point toward the light and check if you hit anything.

### Hard Shadows (Ray March)

```glsl
float shadow(vec2 point, vec2 lightPos) {
    vec2 dir = normalize(lightPos - point);
    float maxDist = length(lightPos - point);
    float t = 0.02;  // Start slightly away from surface to avoid self-shadowing

    for (int i = 0; i < 64; i++) {
        vec2 p = point + dir * t;
        float d = sceneSDF(p);

        if (d < 0.001) {
            return 0.0;  // Hit something — in shadow
        }

        t += d;  // Sphere tracing: safe to step by the SDF value

        if (t > maxDist) {
            break;  // Reached the light — not in shadow
        }
    }

    return 1.0;  // Fully lit
}
```

This is **sphere tracing** — the same technique used in 3D raymarching (Module 10). Each step advances by the SDF value, which is guaranteed to be safe (nothing is closer than `d`). This makes it very efficient.

### Soft Shadows

Hard shadows have razor-sharp edges, which looks unnatural. Soft shadows have a penumbra — a gradual transition from lit to shadowed. Track the closest approach during the march:

```glsl
float softShadow(vec2 point, vec2 lightPos, float softness) {
    vec2 dir = normalize(lightPos - point);
    float maxDist = length(lightPos - point);
    float t = 0.02;
    float result = 1.0;

    for (int i = 0; i < 64; i++) {
        vec2 p = point + dir * t;
        float d = sceneSDF(p);

        if (d < 0.001) {
            return 0.0;
        }

        // Track how close we got to surfaces
        result = min(result, softness * d / t);

        t += d;

        if (t > maxDist) break;
    }

    return clamp(result, 0.0, 1.0);
}
```

The `softness` parameter controls the penumbra width:
- `softness = 2.0` → Very soft, wide penumbra
- `softness = 8.0` → Moderately soft
- `softness = 32.0` → Nearly hard shadows

The `d / t` ratio is the key insight: a close approach (`d` small) early in the march (`t` small) creates a wider shadow than a close approach far from the surface. This naturally produces realistic penumbra shapes.

### Self-Shadow Prevention

The `t = 0.02` initial offset prevents "shadow acne" — the surface shadowing itself because the starting point is exactly on the surface (SDF ≈ 0).

---

## 7. Putting It All Together: Lit SDF Scene

```glsl
#define PI 3.14159265359

// --- SDF primitives ---
float sdCircle(vec2 p, float r) { return length(p) - r; }

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// --- Scene SDF ---
float sceneSDF(vec2 p) {
    float d = sdCircle(p - vec2(-0.2, 0.0), 0.15);
    d = min(d, sdBox(p - vec2(0.2, 0.0), vec2(0.12, 0.12)));
    d = min(d, sdCircle(p - vec2(0.0, -0.25), 0.1));
    // Ground
    d = min(d, p.y + 0.35);
    return d;
}

// --- Normal ---
vec2 normal(vec2 p) {
    float eps = 0.001;
    return normalize(vec2(
        sceneSDF(p + vec2(eps, 0)) - sceneSDF(p - vec2(eps, 0)),
        sceneSDF(p + vec2(0, eps)) - sceneSDF(p - vec2(0, eps))
    ));
}

// --- Soft shadow ---
float softShadow(vec2 p, vec2 lightPos, float k) {
    vec2 dir = normalize(lightPos - p);
    float maxDist = length(lightPos - p);
    float t = 0.02;
    float res = 1.0;
    for (int i = 0; i < 64; i++) {
        float d = sceneSDF(p + dir * t);
        if (d < 0.0005) return 0.0;
        res = min(res, k * d / t);
        t += d;
        if (t > maxDist) break;
    }
    return clamp(res, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    float d = sceneSDF(uv);
    vec2 n = normal(uv);

    // --- Two lights ---
    vec2 light1Pos = vec2(-0.3, 0.3);
    vec3 light1Color = vec3(1.0, 0.7, 0.4);

    vec2 light2Pos = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;
    vec3 light2Color = vec3(0.4, 0.6, 1.0);

    // --- Compute lighting for each light ---
    vec3 color = vec3(0.0);

    for (int li = 0; li < 2; li++) {
        vec2 lPos = (li == 0) ? light1Pos : light2Pos;
        vec3 lCol = (li == 0) ? light1Color : light2Color;

        vec2 lDir = normalize(lPos - uv);
        float lDist = length(lPos - uv);
        float atten = 0.01 / (lDist * lDist + 0.01);

        // Diffuse
        float diff = max(dot(n, lDir), 0.0);

        // Specular (simplified 2D)
        float spec = pow(max(dot(n, lDir), 0.0), 32.0) * 0.5;

        // Shadow
        float shad = softShadow(uv, lPos, 8.0);

        // Accumulate this light's contribution
        color += (diff + spec) * lCol * atten * shad;
    }

    // --- Surface color and rendering ---
    vec3 surfaceColor = vec3(0.6, 0.5, 0.4);
    vec3 ambient = surfaceColor * 0.03;

    // Only apply lighting to the surface
    float mask = smoothstep(0.005, 0.0, d);
    vec3 litSurface = ambient + surfaceColor * color;

    // Background: dark with subtle light glow
    vec3 bgColor = vec3(0.02, 0.02, 0.04);
    for (int li = 0; li < 2; li++) {
        vec2 lPos = (li == 0) ? light1Pos : light2Pos;
        vec3 lCol = (li == 0) ? light1Color : light2Color;
        float glow = 0.003 / (length(uv - lPos) + 0.01);
        bgColor += lCol * glow;
    }

    vec3 finalColor = mix(bgColor, litSurface, mask);

    fragColor = vec4(finalColor, 1.0);
}
```

### What This Demonstrates

- **Scene SDF** — multiple primitives combined with `min`
- **SDF-derived normals** — central difference gradient computation
- **Two lights with different colors** — warm and cool for contrast
- **Diffuse + specular** — matte base with shiny highlights
- **Soft shadows** — sphere-traced with penumbra
- **Ambient term** — prevents pure black in unlit areas
- **Background glow** — lights visible even outside surfaces
- **Mouse interaction** — one light follows the mouse

---

## 8. Ambient Occlusion

Ambient occlusion (AO) darkens areas where surfaces are close together — corners, crevices, the base of objects sitting on a floor. It is a cheap way to add depth and contact shadows.

### SDF-Based AO

With an SDF, AO is elegantly simple: march a short distance along the normal and check how much the SDF "should have" grown versus how much it actually grew. If the SDF grew less than expected, something is nearby and occluding.

```glsl
float ambientOcclusion(vec2 p, vec2 n) {
    float ao = 0.0;
    float scale = 1.0;

    for (int i = 1; i <= 5; i++) {
        float dist = 0.01 * float(i);
        float d = sceneSDF(p + n * dist);
        ao += (dist - d) * scale;  // How much closer is the SDF than expected?
        scale *= 0.5;  // Closer samples matter more
    }

    return 1.0 - clamp(ao * 5.0, 0.0, 1.0);
}
```

Use it as a multiplier on your lighting:

```glsl
float ao = ambientOcclusion(uv, n);
color *= ao;
```

---

## GLSL Quick Reference

| Function/Concept | Description | Example |
|---|---|---|
| Point light | `intensity / (dist² + eps)` | `0.01 / (d*d + 0.01)` |
| SDF normal | Gradient of the SDF via finite differences | `(SDF(p+ε) - SDF(p-ε))` in X and Y |
| Diffuse | `max(dot(normal, lightDir), 0.0)` | Matte surface illumination |
| Specular | `pow(max(dot(n, l), 0.0), shininess)` | Shiny highlight |
| Shininess | Exponent in specular pow | 4=soft, 32=medium, 256=mirror |
| Ambient | Constant base brightness | `surfaceColor * 0.05` |
| Hard shadow | March from point to light, check SDF | Returns 0 (shadow) or 1 (lit) |
| Soft shadow | Track closest approach: `k * d / t` | `k` controls penumbra width |
| Normal map | RGB texture encoding surface normal | `n = tex.rgb * 2.0 - 1.0` |
| Ambient occlusion | Sample SDF along normal at increasing dist | Darkens crevices and corners |

---

## Common Pitfalls

### 1. Shadow Acne (Self-Shadowing)

Starting the shadow march at exactly the surface causes the SDF to immediately read near-zero and declare shadow.

```glsl
// WRONG — starts ON the surface:
float t = 0.0;

// RIGHT — offset slightly along the light direction:
float t = 0.02;
```

### 2. Forgetting to Normalize Light Direction

```glsl
// WRONG — unnormalized, dot product results are wrong:
vec2 lightDir = lightPos - uv;
float diff = dot(normal, lightDir);

// RIGHT — normalize first:
vec2 lightDir = normalize(lightPos - uv);
float diff = max(dot(normal, lightDir), 0.0);
```

### 3. Negative Diffuse Values

`dot(n, l)` can be negative when the surface faces away from the light. Without clamping, you get negative light (subtracting from color):

```glsl
// WRONG — can go negative:
float diff = dot(normal, lightDir);

// RIGHT — clamp to zero:
float diff = max(dot(normal, lightDir), 0.0);
```

### 4. Blown-Out Highlights

Multiple lights or high-intensity specular can push colors above 1.0. Either clamp at the end or use tone mapping:

```glsl
// Simple clamp:
color = clamp(color, 0.0, 1.0);

// Simple tone mapping (Reinhard):
color = color / (color + 1.0);
```

---

## Exercises

### Exercise 1: Mood Lighting

**Time:** 30–40 minutes

Create a dark scene with 3 colored point lights:

1. Place three lights with different colors (warm, cool, green/magenta)
2. At least one light orbits using `sin(iTime)` / `cos(iTime)`
3. One light follows the mouse
4. No shapes yet — just lights on a dark background with additive glow
5. Observe how colors mix where lights overlap

**Concepts practiced:** Point lights, attenuation, additive color mixing, mouse input

---

### Exercise 2: Lit SDF Scene

**Time:** 45–60 minutes

Build a scene with 3+ SDF shapes and full lighting:

1. Create a scene SDF with at least a circle, box, and ground plane
2. Compute normals from the SDF gradient
3. Add a warm point light and a cool point light
4. Implement diffuse shading (dot product with normal)
5. Add specular highlights to at least one shape
6. Add ambient light to prevent pure black areas

**Stretch:** Give different shapes different colors/shininess. Implement a material system where each shape has its own `surfaceColor` and `shininess` (use the SDF values to determine which shape the pixel is on).

**Concepts practiced:** SDF normals, diffuse, specular, multiple lights, material properties

---

### Exercise 3: Shadow Scene

**Time:** 45–60 minutes

Extend Exercise 2 with shadows:

1. Implement hard shadows using sphere tracing
2. Upgrade to soft shadows with a `softness` parameter
3. Add ambient occlusion for contact shadows
4. Make one light orbit so shadows sweep across the scene
5. Experiment with shadow softness values (2, 8, 32)

**Stretch:** Add a second shadow-casting light. Shadows from multiple lights should interact correctly (a point is only fully lit if it is unoccluded from ALL lights).

**Concepts practiced:** Sphere tracing, soft shadows, ambient occlusion, shadow interaction

---

## Key Takeaways

1. **2D lighting is cheap and effective.** A point light is just `intensity / (distance² + epsilon)`. Diffuse shading is `max(dot(normal, lightDir), 0.0)`. These simple formulas create convincing atmospheric scenes.

2. **SDF normals come from the gradient.** Sample the SDF at small offsets in X and Y, take the difference, normalize. This gives you a surface normal at any point, which enables lighting calculations.

3. **Specular adds shininess.** `pow(max(dot(n, l), 0.0), shininess)` creates a bright highlight. Higher exponents = tighter, shinier highlights. Combine diffuse + specular + ambient for a complete lighting model.

4. **SDF shadows use sphere tracing.** March from the point toward the light, stepping by the SDF value at each point. If the SDF goes near zero, you hit something — the point is in shadow. Track the closest approach for soft shadows.

5. **Multiple colored lights create atmosphere.** Warm + cool light contrast is the easiest way to make a scene look professional. The additive color mixing where lights overlap creates rich, unexpected hues.

6. **Ambient light and AO prevent flat looks.** A small ambient term ensures nothing is pure black. Ambient occlusion darkens corners and crevices, adding subtle depth that makes 2D scenes feel three-dimensional.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [LearnOpenGL: Basic Lighting](https://learnopengl.com/Lighting/Basic-Lighting) | Tutorial | Clear explanation of the Phong model (ambient + diffuse + specular). Written for 3D but the concepts apply directly to 2D. |
| [LearnOpenGL: Lighting Maps](https://learnopengl.com/Lighting/Lighting-maps) | Tutorial | How normal maps, diffuse maps, and specular maps work together. Essential context for 2D normal-mapped sprites. |
| [Ronja: 2D SDF Shadows](https://www.ronja-tutorials.com/post/037-2d-sdf-shadows/) | Tutorial | Practical 2D shadow technique using SDFs. Unity-flavored but the GLSL translates directly. |
| [Inigo Quilez: Soft Shadows](https://iquilezles.org/articles/rmshadows/) | Article | The definitive explanation of soft shadow computation via sphere tracing. Written for 3D but applies identically to 2D. |

---

## What's Next?

Your 2D shader toolkit is now feature-complete: shapes, color, patterns, noise, textures, and lighting. From here, you can continue to:

- **[Module 9: Post-Processing Effects](module-09-post-processing.md)** — Apply bloom, CRT effects, color grading, and film grain to entire rendered scenes.
- **[Module 10: Raymarching & 3D SDF Scenes](module-10-raymarching-3d-sdf.md)** — Extend everything you learned about SDFs, normals, and lighting into full 3D.
- **[Module 12: Porting to Engines](module-12-porting-to-engines.md)** — Bring your 2D lighting shaders into Godot, Love2D, or React Three Fiber.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
