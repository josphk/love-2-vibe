# Module 11: Animation, Motion & Interactive Shaders

**Part of:** [GLSL Learning Roadmap](glsl-learning-roadmap.md)
**Estimated study time:** 5–7 hours
**Prerequisites:** Module 4 (Patterns & Transformations)

---

## Overview

You have used `iTime` since Module 0, but so far it has been mostly `sin(iTime)` plugged into various parameters. This module is about making things move *with intention* — not random oscillation, but choreographed, polished animation that feels designed rather than accidental.

The difference between amateur and professional motion is almost always **easing**. Linear motion (constant speed) looks robotic. Ease-in-out (accelerate then decelerate) looks natural. Bounce, elastic, and overshoot feel playful. These are simple math functions that transform a linear progress value into a curved one, and they change everything.

Beyond easing, this module covers **sequencing** (triggering different animations at different times), **audio reactivity** (driving visuals from music or microphone input), and **buffer feedback** (using the previous frame to create trails, motion blur, and cellular automata). Together, these techniques let you create animated visual pieces that feel alive and responsive.

---

## 1. Easing Functions

An easing function takes a linear progress value `t` (0 to 1) and returns a curved version. The input is "where are we in the animation?" and the output is "how far along should it look?"

### Linear (No Easing)

```glsl
float linear(float t) {
    return t;
}
```

```
1│        ╱
 │      ╱
 │    ╱
 │  ╱
0└────────
 0        1
```

Constant speed. Mechanical. Rarely what you want.

### Ease-In (Accelerate)

```glsl
// Quadratic ease-in
float easeInQuad(float t) {
    return t * t;
}

// Cubic ease-in (stronger)
float easeInCubic(float t) {
    return t * t * t;
}
```

```
1│          ╱
 │        ╱
 │      ╱
 │   ──╱
0└────────
 0        1
```

Starts slow, ends fast. Good for objects falling or accelerating.

### Ease-Out (Decelerate)

```glsl
// Quadratic ease-out
float easeOutQuad(float t) {
    return 1.0 - (1.0 - t) * (1.0 - t);
}

// Cubic ease-out
float easeOutCubic(float t) {
    float u = 1.0 - t;
    return 1.0 - u * u * u;
}
```

```
1│    ╱────
 │  ╱
 │ ╱
 │╱
0└────────
 0        1
```

Starts fast, ends slow. Good for objects coming to rest or landing.

### Ease-In-Out (Smooth Start and End)

```glsl
// Quadratic ease-in-out
float easeInOutQuad(float t) {
    return t < 0.5
        ? 2.0 * t * t
        : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
}

// Smoothstep IS ease-in-out:
float easeInOut(float t) {
    return smoothstep(0.0, 1.0, t);
}
```

```
1│       ╱──
 │     ╱
 │   ╱
 │──╱
0└────────
 0        1
```

The most natural-looking motion. `smoothstep(0.0, 1.0, t)` is exactly this — you have been using it all along.

### Bounce

```glsl
float easeOutBounce(float t) {
    if (t < 1.0 / 2.75) {
        return 7.5625 * t * t;
    } else if (t < 2.0 / 2.75) {
        t -= 1.5 / 2.75;
        return 7.5625 * t * t + 0.75;
    } else if (t < 2.5 / 2.75) {
        t -= 2.25 / 2.75;
        return 7.5625 * t * t + 0.9375;
    } else {
        t -= 2.625 / 2.75;
        return 7.5625 * t * t + 0.984375;
    }
}
```

Overshoots then bounces back. Good for playful UI elements, game icons, or cartoon physics.

### Elastic

```glsl
float easeOutElastic(float t) {
    if (t == 0.0 || t == 1.0) return t;
    return pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * 6.28318 / 3.0) + 1.0;
}
```

Overshoots and oscillates before settling. Spring-like motion.

### Back (Overshoot)

```glsl
float easeOutBack(float t) {
    float c = 1.70158;
    float c3 = c + 1.0;
    float u = t - 1.0;
    return 1.0 + c3 * u * u * u + c * u * u;
}
```

Goes past the target then comes back. Subtle overshoot that feels energetic.

### Using Easing Functions

```glsl
// Animate a circle from left to right with ease-in-out
float duration = 2.0;
float t = fract(iTime / duration);  // 0 to 1 every 2 seconds
t = easeInOutQuad(t);  // Apply easing

float x = mix(-0.5, 0.5, t);  // Map to position
float d = length(uv - vec2(x, 0.0)) - 0.05;
```

The key pattern: compute a linear progress `t` (0 to 1), apply easing, then use the eased value to drive your parameter.

---

## 2. Sequencing and Timing

Easing animates one parameter. **Sequencing** chains multiple animations over time.

### Basic Loop

```glsl
float duration = 3.0;
float t = fract(iTime / duration);  // Loops 0→1 every 3 seconds
```

### Beat Counter

```glsl
float duration = 2.0;
float beat = floor(iTime / duration);  // 0, 1, 2, 3, ... (which cycle)
float t = fract(iTime / duration);     // 0→1 within current cycle
```

Use `beat` to change what happens each cycle. Use `t` for the animation within a cycle.

### Multi-Phase Animation

```glsl
float totalDuration = 4.0;
float t = fract(iTime / totalDuration);

if (t < 0.25) {
    // Phase 1: appear (0 to 0.25 → normalized to 0-1)
    float phase = t / 0.25;
    phase = easeOutBack(phase);
    // ... animate appearance ...
} else if (t < 0.5) {
    // Phase 2: hold (0.25 to 0.5)
    // ... static ...
} else if (t < 0.75) {
    // Phase 3: transform (0.5 to 0.75)
    float phase = (t - 0.5) / 0.25;
    phase = easeInOutQuad(phase);
    // ... animate transformation ...
} else {
    // Phase 4: disappear (0.75 to 1.0)
    float phase = (t - 0.75) / 0.25;
    phase = easeInCubic(phase);
    // ... animate disappearance ...
}
```

### Staggered Animation

Offset the timing for each element to create a wave or cascade effect:

```glsl
// Grid of circles that animate in sequence
vec2 id = floor(uv * 5.0);
vec2 cellUV = fract(uv * 5.0) - 0.5;

// Each cell starts at a different time (stagger by distance from corner)
float stagger = (id.x + id.y) * 0.1;
float t = fract(iTime * 0.5 - stagger);
t = clamp(t * 3.0, 0.0, 1.0);  // Speed up the individual animation
t = easeOutBack(t);

float radius = 0.15 * t;
float d = length(cellUV) - radius;
```

This creates a wave of circles appearing from one corner to the other.

### Ping-Pong (Back and Forth)

```glsl
float pingPong(float t) {
    return abs(fract(t) - 0.5) * 2.0;
    // Goes: 0→1→0→1→0 (triangle wave)
}

// Usage: animate position back and forth
float x = mix(-0.3, 0.3, easeInOutQuad(pingPong(iTime * 0.5)));
```

---

## 3. Particle-Like Effects

Shaders cannot create actual particles (no persistent state per entity), but you can fake particle effects by computing positions mathematically.

### Falling Particles (Hash-Based)

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec3 color = vec3(0.0);

    // Many "particles" computed from their column
    for (int i = 0; i < 30; i++) {
        float fi = float(i);

        // Each particle has a fixed X position (pseudo-random)
        float px = fract(sin(fi * 127.1) * 43758.5453);

        // Y position falls over time (looping)
        float speed = 0.1 + fract(sin(fi * 311.7) * 43758.5453) * 0.3;
        float py = fract(-iTime * speed + fract(sin(fi * 78.233) * 43758.5453));

        // Size
        float size = 0.003 + fract(sin(fi * 43.13) * 43758.5) * 0.005;

        // Distance to this particle
        float d = length(uv - vec2(px, py));

        // Glow
        float glow = size / d;
        color += vec3(0.5, 0.7, 1.0) * glow;
    }

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
```

### Expanding Ring

```glsl
float ring(vec2 uv, vec2 center, float time, float delay) {
    float t = max(0.0, time - delay);
    float radius = t * 0.5;  // Expanding radius
    float thickness = 0.01;
    float fade = exp(-t * 2.0);  // Fade out over time

    float d = abs(length(uv - center) - radius) - thickness;
    return smoothstep(0.01, 0.0, d) * fade;
}
```

### Firework Burst

```glsl
float firework(vec2 uv, vec2 center, float time) {
    float burst = 0.0;
    for (int i = 0; i < 20; i++) {
        float fi = float(i);
        float angle = fi * 6.28318 / 20.0;
        float speed = 0.3 + fract(sin(fi * 41.3) * 43758.5) * 0.2;

        vec2 particlePos = center + vec2(cos(angle), sin(angle)) * speed * time;
        // Gravity
        particlePos.y -= 0.5 * time * time;

        float d = length(uv - particlePos);
        float fade = exp(-time * 3.0);
        burst += (0.002 / (d + 0.001)) * fade;
    }
    return burst;
}
```

---

## 4. Audio Reactivity

ShaderToy lets you bind audio (a file or the microphone) to an input channel. The audio data arrives as a texture:

- **Row 0 (y=0):** Frequency spectrum (FFT). X axis = frequency (low to high).
- **Row 1 (y=1):** Waveform. X axis = time (current audio waveform).

### Sampling Audio

```glsl
// Bind audio to iChannel0

// Bass (low frequency)
float bass = texture(iChannel0, vec2(0.05, 0.0)).r;

// Mids
float mids = texture(iChannel0, vec2(0.3, 0.0)).r;

// Highs (treble)
float highs = texture(iChannel0, vec2(0.7, 0.0)).r;

// Full waveform at current position
float wave = texture(iChannel0, vec2(uv.x, 1.0)).r;
```

### Bass-Reactive Pulsing

```glsl
float bass = texture(iChannel0, vec2(0.05, 0.0)).r;

// Pulse size with bass
float radius = 0.2 + bass * 0.15;
float d = sdCircle(uv, radius);
float glow = 0.01 / abs(d);

vec3 color = vec3(glow) * vec3(1.0, 0.3, 0.5);
```

### Frequency Visualization

```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Sample the spectrum at this X position
    float freq = texture(iChannel0, vec2(uv.x, 0.0)).r;

    // Draw a bar
    float bar = step(uv.y, freq);

    // Color by frequency
    vec3 color = vec3(uv.x, 1.0 - uv.x, 0.5) * bar;

    fragColor = vec4(color, 1.0);
}
```

### Driving Palette Colors with Audio

```glsl
float bass = texture(iChannel0, vec2(0.05, 0.0)).r;
float mids = texture(iChannel0, vec2(0.3, 0.0)).r;

// Use audio to drive palette parameters
float t = length(uv) + bass * 0.5 - iTime * 0.2;
vec3 color = palette(t,
    vec3(0.5), vec3(0.5),
    vec3(1.0 + mids, 1.0, 1.0),  // Frequency shifts with mids
    vec3(0.0, 0.33, 0.67)
);
```

---

## 5. Buffer Feedback

Buffer feedback is when a buffer reads its own previous frame as input. This creates temporal effects: trails, motion blur, reaction-diffusion patterns, and cellular automata.

### Setting Up in ShaderToy

1. Add Buffer A
2. In Buffer A's channel settings, bind iChannel0 to "Buffer A" (itself)
3. Now `texture(iChannel0, uv)` reads the previous frame

### Fading Trails

```glsl
// Buffer A:
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Read previous frame, slightly faded
    vec3 prev = texture(iChannel0, uv).rgb * 0.97;

    // Draw something new
    vec2 center = vec2(0.5 + 0.3 * cos(iTime), 0.5 + 0.3 * sin(iTime * 1.3));
    float d = length(uv - center) - 0.02;
    float dot = smoothstep(0.01, 0.0, d);

    vec3 color = max(prev, vec3(dot) * vec3(1.0, 0.5, 0.2));

    fragColor = vec4(color, 1.0);
}
```

The `* 0.97` makes previous pixels fade by 3% per frame, creating smooth trails that gradually disappear.

### Motion Blur

Read the previous frame with a slight UV offset in the motion direction:

```glsl
vec2 motionDir = vec2(0.002, 0.0);  // Or compute from mouse delta
vec3 prev = texture(iChannel0, uv - motionDir).rgb * 0.95;
vec3 color = max(prev, newContent);
```

### Conway's Game of Life

A cellular automaton implemented as buffer feedback:

```glsl
// Buffer A: Game of Life simulation
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 texel = 1.0 / iResolution.xy;

    // Count live neighbors
    int neighbors = 0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            if (x == 0 && y == 0) continue;
            vec2 offset = vec2(float(x), float(y)) * texel;
            float cell = texture(iChannel0, uv + offset).r;
            neighbors += (cell > 0.5) ? 1 : 0;
        }
    }

    float current = texture(iChannel0, uv).r;
    bool alive = current > 0.5;

    // Rules
    bool nextAlive = false;
    if (alive && (neighbors == 2 || neighbors == 3)) nextAlive = true;
    if (!alive && neighbors == 3) nextAlive = true;

    // Seed: on first frame or when mouse is pressed
    if (iFrame < 1) {
        float rand = fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453);
        nextAlive = rand > 0.7;
    }

    // Mouse drawing
    if (iMouse.z > 0.0) {
        float d = length(fragCoord - iMouse.xy);
        if (d < 5.0) nextAlive = true;
    }

    fragColor = vec4(vec3(nextAlive ? 1.0 : 0.0), 1.0);
}
```

### Reaction-Diffusion

A more organic pattern that creates coral-like structures:

```glsl
// Buffer A: Gray-Scott reaction-diffusion
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 texel = 1.0 / iResolution.xy;

    // Current state: R in .r, G in .g
    vec2 state = texture(iChannel0, uv).rg;
    float a = state.r;  // Chemical A
    float b = state.g;  // Chemical B

    // Laplacian (diffusion)
    float lapA = 0.0, lapB = 0.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 s = texture(iChannel0, uv + vec2(x, y) * texel).rg;
            float w = (x == 0 && y == 0) ? -1.0 : (abs(x) + abs(y) == 1 ? 0.2 : 0.05);
            lapA += s.r * w;
            lapB += s.g * w;
        }
    }

    // Gray-Scott parameters
    float feed = 0.055;
    float kill = 0.062;
    float dA = 1.0;
    float dB = 0.5;
    float dt = 1.0;

    float reaction = a * b * b;
    a += (dA * lapA - reaction + feed * (1.0 - a)) * dt;
    b += (dB * lapB + reaction - (kill + feed) * b) * dt;

    // Initialize
    if (iFrame < 1) {
        a = 1.0;
        b = 0.0;
    }

    // Seed pattern on mouse click
    if (iMouse.z > 0.0 && length(fragCoord - iMouse.xy) < 10.0) {
        b = 1.0;
    }

    fragColor = vec4(a, b, 0.0, 1.0);
}
```

The Image pass reads Buffer A and visualizes it:

```glsl
// Image pass
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 state = texture(iChannel0, uv).rg;
    vec3 color = palette(state.g * 3.0, ...);
    fragColor = vec4(color, 1.0);
}
```

---

## 6. Advanced Timing Techniques

### Smooth Random Motion

Create natural-looking random motion using multiple sine waves with irrational frequency ratios:

```glsl
vec2 randomMotion(float t, float seed) {
    return vec2(
        sin(t * 1.0 + seed) * 0.3 + sin(t * 2.3 + seed * 2.0) * 0.15 + sin(t * 0.7 + seed * 3.0) * 0.1,
        cos(t * 1.3 + seed) * 0.3 + cos(t * 1.7 + seed * 2.0) * 0.15 + cos(t * 0.5 + seed * 3.0) * 0.1
    );
}
```

Irrational ratios (1.0, 2.3, 0.7, 1.3, 1.7, 0.5) ensure the motion never exactly repeats — it looks organic and unpredictable.

### Delayed Response

Create animations that respond to changes with a smooth delay:

```glsl
// In buffer feedback: smooth toward target value
float target = /* some value */;
float current = texture(iChannel0, uv).r;  // Previous value
float smoothed = mix(current, target, 0.1);  // 10% per frame toward target
```

This is an exponential smoothing filter — the value chases the target at a speed proportional to the distance. It creates natural, springy responses.

### Tempo Sync

Sync animations to a specific BPM:

```glsl
float bpm = 120.0;
float beatDuration = 60.0 / bpm;          // 0.5 seconds per beat
float beat = iTime / beatDuration;         // Total beats elapsed
float beatFrac = fract(beat);              // Position within current beat
float beatNum = floor(beat);               // Which beat number

// Pulse on each beat
float pulse = exp(-beatFrac * 8.0);  // Sharp attack, exponential decay
```

---

## Code Walkthrough: Audio-Reactive Visualizer

```glsl
#define TAU 6.28318530718

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    // --- Audio sampling ---
    float bass = texture(iChannel0, vec2(0.05, 0.0)).r;
    float mids = texture(iChannel0, vec2(0.3, 0.0)).r;
    float highs = texture(iChannel0, vec2(0.7, 0.0)).r;

    // --- Radial spectrum visualization ---
    // Map angle to frequency
    float freqPos = (angle + 3.14159) / TAU;
    float freq = texture(iChannel0, vec2(freqPos, 0.0)).r;

    // --- Animated ring ---
    float baseRadius = 0.15 + bass * 0.1;
    float ringRadius = baseRadius + freq * 0.15;
    float ring = abs(radius - ringRadius) - 0.005;
    float ringGlow = 0.003 / max(abs(ring), 0.001);

    // --- Color ---
    vec3 color = palette(freqPos + iTime * 0.1) * ringGlow;

    // --- Center pulse ---
    float pulse = 0.02 / (radius + 0.01) * bass;
    color += vec3(1.0, 0.5, 0.2) * pulse * 0.3;

    // --- Background particles ---
    for (int i = 0; i < 12; i++) {
        float fi = float(i);
        float a = fi * TAU / 12.0 + iTime * 0.2;
        float r = 0.3 + mids * 0.1;
        vec2 particlePos = vec2(cos(a), sin(a)) * r;
        float d = length(uv - particlePos);
        float glow = 0.003 / (d + 0.001);
        color += palette(fi / 12.0 + iTime * 0.05) * glow;
    }

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
```

---

## GLSL Quick Reference

| Function/Concept | Description | Example |
|---|---|---|
| Ease-in | `t * t` (or `t³`) | Accelerating start |
| Ease-out | `1-(1-t)²` | Decelerating end |
| Ease-in-out | `smoothstep(0.0, 1.0, t)` | Smooth start and end |
| Bounce | Multi-branch quadratic | Cartoon physics |
| Elastic | `pow(2,-10t) * sin(...)` | Spring overshoot |
| `fract(iTime/dur)` | Looping 0→1 progress | Animation cycle |
| `floor(iTime/dur)` | Beat/cycle counter | Which iteration |
| Stagger | `t - id * delay` | Wave/cascade timing |
| Ping-pong | `abs(fract(t) - 0.5) * 2` | Back-and-forth |
| Audio spectrum | `texture(ch, vec2(freq, 0.0))` | FFT frequency data |
| Audio waveform | `texture(ch, vec2(pos, 1.0))` | Time-domain wave |
| Buffer feedback | Buffer reads own prev frame | `texture(self, uv) * 0.97` |
| Trails | `max(prev * fade, new)` | Fading motion trails |
| Game of Life | Neighbor count → rules | Cellular automaton |
| Reaction-diffusion | Laplacian + reaction | Organic coral patterns |
| BPM sync | `fract(time * bpm / 60)` | Musical tempo |
| Exp decay | `exp(-t * rate)` | Sharp attack, smooth release |

---

## Common Pitfalls

### 1. Easing Applied to Wrong Range

Easing functions expect input 0 to 1. If your `t` goes outside this range, results are unpredictable:

```glsl
// WRONG — t can be negative or > 1:
float t = (iTime - startTime) / duration;
float eased = easeInOutQuad(t);  // Undefined outside 0–1

// RIGHT — clamp first:
float t = clamp((iTime - startTime) / duration, 0.0, 1.0);
float eased = easeInOutQuad(t);
```

### 2. Buffer Feedback Without Initialization

On the first frame, the buffer is empty (usually black or undefined). Seed it:

```glsl
if (iFrame < 1) {
    // Initialize the buffer
    fragColor = vec4(initialState, 1.0);
    return;
}
```

### 3. Feedback Decay Rate

`prev * 0.99` looks nearly static (1% fade per frame at 60fps takes forever to disappear). `prev * 0.9` fades very quickly (10% per frame):

```
0.99 per frame: ~7 seconds to reach 1% brightness
0.97 per frame: ~2 seconds
0.95 per frame: ~1 second
0.90 per frame: ~0.4 seconds
```

### 4. Audio Not Bound

If no audio is bound to the channel, `texture(iChannel0, ...)` returns zero or garbage. Guard against it:

```glsl
float bass = texture(iChannel0, vec2(0.05, 0.0)).r;
// If bass is always 0, audio might not be bound
float fallback = sin(iTime * 2.0) * 0.5 + 0.5;
bass = max(bass, fallback * 0.3);  // Use fallback when no audio
```

---

## Exercises

### Exercise 1: Easing Showcase

**Time:** 30–45 minutes

Create a shader that demonstrates easing functions visually:

1. Draw 6 horizontal rows, each containing a small circle
2. All circles move left-to-right simultaneously, but each uses a different easing function: linear, ease-in, ease-out, ease-in-out, bounce, elastic
3. Loop every 3 seconds
4. Add a progress bar at the bottom showing the raw `t` value

**Concepts practiced:** Easing functions, timing, visual comparison

---

### Exercise 2: Sequenced Animation

**Time:** 45–60 minutes

Create a looping animation with at least 4 distinct phases:

1. **Appear:** Shapes scale up from zero (ease-out-back for overshoot)
2. **Dance:** Shapes orbit or rotate (smooth sine motion)
3. **Transform:** Shapes morph into different shapes (mix between two SDFs)
4. **Disappear:** Shapes shrink and fade (ease-in)

Use `fract(iTime / totalDuration)` to loop. Use conditionals or `smoothstep` to transition between phases. Add staggered timing for multiple elements.

**Concepts practiced:** Sequencing, easing, morphing, stagger, composition

---

### Exercise 3: Feedback Art

**Time:** 45–60 minutes

Create a buffer feedback shader:

1. **Buffer A:** Read previous frame with `* 0.97` decay. Add a new animated element (orbiting point, expanding ring, etc.)
2. **Image:** Read Buffer A and apply color (cosine palette based on brightness)
3. Experiment with different decay rates and see how they affect the trail length
4. Try adding a UV offset to the previous frame read (`texture(ch, uv + offset)`) for swirling trails

**Stretch:** Implement Conway's Game of Life or a reaction-diffusion system. Add mouse interaction to draw new cells/seeds.

**Concepts practiced:** Buffer feedback, temporal effects, cellular automata, mouse interaction

---

## Key Takeaways

1. **Easing functions transform motion from mechanical to natural.** `t * t` for ease-in, `1-(1-t)²` for ease-out, `smoothstep` for ease-in-out. Apply them to any animated parameter — position, scale, opacity, color — and the result immediately looks more polished.

2. **Sequencing uses `fract` and `floor` on time.** `fract(iTime/duration)` gives you a looping 0-to-1 progress. `floor(iTime/duration)` counts which cycle you are in. Divide the progress into phases with conditionals or `smoothstep`.

3. **Staggered timing creates cascades.** Offset each element's start time by a function of its position or index. Simple stagger (`id * delay`) creates linear waves. Distance-based stagger (`length(id) * delay`) creates radial waves.

4. **Audio reactivity maps sound to visuals.** Sample the frequency spectrum as a texture: x-position = frequency, value = amplitude. Bass drives scale/pulse, mids drive color, highs drive detail. The mapping is creative — there are no wrong answers.

5. **Buffer feedback enables temporal effects.** A buffer reading its own previous frame with fade creates trails. With rules applied to the neighborhood, it creates cellular automata. With reaction-diffusion equations, it creates organic growth patterns.

6. **The BPM formula syncs to music.** `fract(iTime * bpm / 60.0)` gives you a per-beat progress value. `exp(-t * k)` creates a punchy attack-decay envelope. Together, they sync visuals to musical tempo.

---

## Recommended Reading

| Resource | Type | Why |
|---|---|---|
| [Easings.net](https://easings.net) | Visual reference | Every standard easing curve visualized with formulas. The definitive easing reference. |
| [Book of Shaders, Ch. 10 (Generative)](https://thebookofshaders.com/10/) | Interactive tutorial | Randomness and motion principles for shader animation. |
| [Inigo Quilez: Palettes](https://iquilezles.org/articles/palettes/) | Article | Using time-driven cosine palettes as animation tools — color that moves. |
| [ShaderToy: Sound Input](https://shadertoyunofficial.wordpress.com/2015/07/22/sound/) | Tutorial | How to use audio input in ShaderToy — frequency spectrum and waveform access. |
| [Reaction-Diffusion Tutorial (Karl Sims)](https://www.karlsims.com/rd.html) | Article | Explains the Gray-Scott reaction-diffusion model with visual examples. |

---

## What's Next?

You now have a complete animation and interactivity toolkit. Combined with everything from Modules 0–10, you can create polished, animated, interactive, audio-reactive shader art.

The final module takes everything you have learned and makes it practical:

In [Module 12: Porting to Engines](module-12-porting-to-engines.md), you will learn to translate your ShaderToy shaders into Godot, Love2D, and React Three Fiber. The concepts are universal — the syntax and conventions change slightly for each engine. This is where shader programming becomes a production skill.

[Back to GLSL Learning Roadmap](glsl-learning-roadmap.md)
