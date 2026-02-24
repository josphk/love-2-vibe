# ISOBULLET — Design & Development Log

## Initial Concept

**Goal:** Combine the isometric grid, wall, and visibility mechanics of `tactical-shooter` with the bullet hell and bullet-time mechanics of `chronobullet`. Add a new bullet reflection mechanic where bullets bounce off walls.

---

## Phase 1: Studying the Source Games

### Tactical Shooter — Key Takeaways
- **Isometric grid system**: 24×18 grid, 48×24 pixel tiles. `gridToScreen`/`screenToGrid` handle coordinate conversion. All gameplay happens in grid-space; rendering converts to screen-space.
- **Wall system**: `Map.cells[row][col]` stores 0=floor, 1=wall. `isWall(gx, gy)` rounds to nearest integer cell. Border walls + interior wall structures.
- **Line-of-sight / Raycast**: `lineOfSight` steps along a line checking for walls. `raycast` traces a ray and returns the hit point. Used for shooting validation, enemy vision, FOV cone, and sight lines.
- **Entity rendering**: Entities sorted by `(x + y)` for isometric depth. Player and enemies are ellipses. Bullets are small circles at gridToScreen positions.
- **Combat**: Click-to-shoot with LOS requirement. Bullet speed 14 grid/sec. Collision via grid-space distance checks.

### Chronobullet — Key Takeaways
- **Bullet-time mechanic**: Left-click toggles slow-mo (10% speed). Second click fires a hitscan beam. Meter drains during slow-mo, recharges from grazes/kills.
- **Dual dt system**: `realDt` for UI/camera, `worldDt = realDt * timeScale` for gameplay. Player moves at 35% during BT (responsive but slowed).
- **Hitscan beam**: Not a projectile — uses `pointToSegmentDist()` to check every bullet/enemy against the beam line. Pierces everything. Destroys bullets + damages enemies.
- **Dense bullet patterns**: 7 pattern generators (radial, spiral, aimed, expanding ring, cross, shotgun, spin spiral). Bullets have velocity, acceleration, spin.
- **Enemy types**: 5 types with geometric shapes (diamond, circle, hexagon, triangle). Each fires distinct patterns.
- **Wave spawner**: 7 hand-crafted waves → endless procedural mode.
- **Camera**: Y-compression (0.75×) for angled top-down view, screen shake, zoom during BT.
- **Graze system**: Near-miss bullets refill meter + award points.
- **Particles**: Beam trails (glow + core + fade), burst effects, floating combo text.

### Key Architectural Differences
| Aspect | Tactical Shooter | Chronobullet |
|--------|-----------------|--------------|
| Coordinate space | Grid units (0-24, 0-18) | Screen pixels (0-800, 0-600) |
| Perspective | Isometric diamond tiles | Angled top-down (Y-compressed) |
| Player weapon | Click-to-shoot bullets | Hitscan beam during bullet-time |
| Enemy AI | Patrol/chase/retreat with LOS | Pattern-firing, fixed/orbit movement |
| Bullet interaction with walls | Destroyed on wall contact | No walls (bounded arena) |

---

## Phase 2: Design Decisions

### Decision 1: Coordinate System
**Choice**: Everything in grid-space (like tactical-shooter). Enemies, bullets, player all use grid coordinates. Rendering converts via `gridToScreen()`.

**Rationale**: The isometric projection IS the visual identity. Working in grid-space keeps wall collision, LOS, and reflection math clean. Pixel-space would fight the iso projection.

### Decision 2: Camera Approach
**Choice**: Use tactical-shooter's isometric projection (no Y-compression). Add camera module for shake + zoom only.

**Rationale**: The iso grid already provides the angled perspective. Adding chronobullet's Y-compression on top would double-compress and look wrong. Shake and zoom still enhance bullet-time feel.

### Decision 3: Bullet Reflection Mechanic
**Choice**: When a bullet hits a wall, determine which face was hit (horizontal or vertical) and reflect the appropriate velocity component. Each bullet has a `maxBounces` count; dies when exceeded.

**Implementation approach**:
- Save `prevX, prevY` before moving
- After move, if `isWall(newX, newY)`:
  - Check `isWall(newX, prevY)` → X-movement caused hit → reflect `vx`
  - Check `isWall(prevX, newY)` → Y-movement caused hit → reflect `vy`
  - Both walls → corner hit → reflect both
- Revert to `prevX, prevY`, increment bounce counter

**Insight**: This axis-separation approach is simple and robust. It doesn't need explicit wall normals — the grid structure implicitly provides them. The same technique works for bullet-hell density (hundreds of bullets).

### Decision 4: Reflecting Beam Weapon
**Choice**: The player's hitscan beam reflects off walls up to 3 times, creating a multi-segment ricochet shot.

**Implementation**: New `Map.raycastWithNormal()` function that returns hit position AND wall normal. New `Map.reflectRaycast()` that chains raycasts, reflecting direction at each wall hit, collecting all segments.

**Insight**: The wall normal determination uses the same axis-separation trick as bullet reflection. For the raycast, I step along the ray in small increments and check which axis caused the wall entry.

**Player impact**: During bullet-time, the player sees the full reflecting path (dashed lines with bounce-color coding). This adds a deep tactical layer — you can line up ricochet shots to hit enemies behind cover. The aim preview makes this skill accessible, not frustrating.

### Decision 5: Enemy Types (6 types)
**Choice**: Adapt chronobullet's 5 types + add a new "Bouncer" type unique to isobullet.

| Type | Role | Unique to Isobullet |
|------|------|-------------------|
| Turret | Stationary, aimed bursts. Only fires with LOS. | LOS-gated firing (from tactical-shooter) |
| Spinner | Rotating spiral arms. Always fires. | Spiral bullets bounce off walls → chaos |
| Orbiter | Circles a point, radial bursts. | Orbit paths avoid walls |
| **Bouncer** | Fires bullets with extra bounces (5 vs default 2). | **NEW** — exploits reflection mechanic |
| Heavy | Slow, multi-pattern (rings, shotgun, spirals). | Expanding rings bounce everywhere |
| Dasher | Fast movement, aimed bursts. | Dashes to floor tiles only |

**Key insight**: The Bouncer is the signature enemy. Its bullets persist much longer due to extra bounces, filling corridors with ricocheting projectiles. Players must track reflected bullet paths.

### Decision 6: LOS-Aware Pattern Firing
**Choice**: Turrets only fire when they have line-of-sight to the player. Other enemies always fire (their patterns don't need LOS). This creates a tactical layer where wall positioning matters.

**Rationale**: Borrowed from tactical-shooter's enemy vision system. Adds strategy — hide behind walls to avoid aimed fire, but bouncing bullets from Spinners/Bouncers still reach you. Walls are both cover and danger multipliers.

### Decision 7: Bullet Speeds in Grid-Space
**Choice**: Scale chronobullet's pixel speeds to grid units.

Chronobullet uses 110-210 px/sec in a ~700px arena. Grid is 24 units wide.
- 150 px/sec ≈ 150/700 × 24 ≈ 5.1 grid/sec
- Speed range: 4-10 grid/sec for patterns

This gives bullets ~3 seconds to cross the full map, which feels right for bullet hell density with the smaller iso arena.

### Decision 8: No Normal-Time Weapon
**Choice**: Like chronobullet, the player can ONLY attack during bullet-time (the reflecting beam). No normal-time shooting.

**Rationale**: Forces engagement with the core mechanic. Every kill requires entering bullet-time, aiming the ricochet, and firing. This creates a satisfying risk/reward loop: spending meter for damage.

### Decision 9: Bullet Spawn Immunity
**Choice**: Bullets have a 0.15-second wall-collision immunity when spawned.

**Problem solved**: Enemies might be adjacent to walls. Bullets spawned at the enemy's position could immediately detect a wall and bounce/die before leaving the enemy.

**Solution**: `wallImmuneTimer` counts down before wall collision is checked. Bullets move freely during this window.

### Decision 10: Particle System Coordinates
**Choice**: Particles stored in screen-pixel space (converted from grid at spawn time). Drawn inside camera transform.

**Rationale**: Particle velocities and sizes are natural in pixel space (a burst of 100px/sec looks right). Converting grid→screen at spawn time is cheap. Camera shake/zoom applies correctly since particles are drawn inside the transform.

**Beam trails are the exception**: Stored in grid-space (as segment lists), converted to screen at draw time. This ensures beam segments align perfectly with the iso grid.

---

## Phase 3: Map Design

### Layout Philosophy
- **Open enough for bullet hell**: Large corridors for dodging dense patterns
- **Walls for bouncing**: Interior pillars create interesting ricochet geometry
- **Symmetric**: Fair from any approach angle
- **Cover zones**: Players can hide behind pillars to block aimed fire

### Final Map Layout (24×18 grid)
```
WWWWWWWWWWWWWWWWWWWWWWWW  row 1  (border)
W......................W  row 2
W......................W  row 3
W......................W  row 4
W.....W..........W.....W  row 5  (top pillars)
W.....W..........W.....W  row 6
W.....W..........W.....W  row 7
W......................W  row 8
W.........WWWW.........W  row 9  (center bar)
W......................W  row 10
W.....W..........W.....W  row 11 (bottom pillars)
W.....W..........W.....W  row 12
W.....W..........W.....W  row 13
W......................W  row 14
W......................W  row 15
W......................W  row 16
W......................W  row 17
WWWWWWWWWWWWWWWWWWWWWWWW  row 18 (border)
```

Interior walls:
- **4 pillars**: Columns 7 and 18, rows 5-7 and 11-13
- **Center bar**: Row 9, columns 11-14

This creates:
- Open top zone (rows 2-4): enemy spawn area
- Open bottom zone (rows 14-17): player safe zone
- Corridors between pillars: ricochet alleys
- Center bar: splits the arena, forces bounced shots

Player starts at (12, 16). Enemies spawn in the upper half.

---

## Phase 4: Technical Insights During Implementation

### Wall Normal Detection
The axis-separation method for determining wall normals is elegant but has an edge case: when a bullet hits a corner where both X and Y movement independently enter walls, both components reflect. This creates a "perfect bounce-back" which is physically correct for a corner hit.

### Reflecting Raycast Precision
Using small step increments (maxLen × 8 steps) for raycast-with-normal gives sufficient precision without the complexity of a full DDA algorithm. The trade-off is computational cost, but with max 3-4 bounces and ~25 grid unit total range, performance is fine.

### Beam Collision with Multiple Segments
The reflecting beam checks every bullet and enemy against ALL segments (up to 4). This means a single beam can hit enemies around corners. The `pointToSegmentDist` check is O(bullets × segments), which is acceptable for game-scale counts.

### Isometric Depth Sorting
Only enemies and the player are depth-sorted (by x+y). Bullets are drawn in a single pass without sorting — they're small enough that depth errors are imperceptible. This saves significant CPU with 200+ bullets.

### Wall Rendering with 3D Depth
Walls are drawn as isometric blocks with visible south-west and south-east faces, giving a 3D appearance. The wall height of 10px creates a subtle but effective depth illusion. This is purely cosmetic — collision still uses the flat grid.

### Bounce Visual Feedback
- Bullets dim with each bounce (alpha decreases by 0.2 per bounce)
- A ring indicator appears on bounced bullets
- Spark particles emit at each bounce point
- The Bouncer enemy's bullets are gold-colored to distinguish their higher bounce count

### Aim Line During Bullet-Time
The reflecting aim line uses color-coding per segment:
- Segment 0: Cyan (direct shot)
- Segment 1: Purple (first bounce)
- Segment 2: Red (second bounce)
- Segment 3: Orange (third bounce)

This helps players plan ricochet shots without confusion about which bounce goes where.

---

## Phase 5: Wave Design

### Wave Progression Philosophy
- Waves 1-2: Introduce enemies with no wall interaction (turrets in open areas)
- Wave 3: Introduce orbiting enemies near pillars (bullets start bouncing)
- Wave 4: Introduce Bouncers (core reflection mechanic highlighted)
- Wave 5: Heavy + support (multi-pattern chaos with bouncing)
- Wave 6: Mixed chaos with all types
- Wave 7: Full roster, maximum density
- Endless: Procedural scaling with HP multiplier

### Enemy Placement Rules
- All enemies spawn on verified floor tiles
- Orbit centers are chosen so orbit paths avoid wall interiors
- Dashers target only floor positions
- At least 3 grid units from player spawn for fairness

---

## Summary of What Makes Isobullet Unique

1. **Bullet Reflection**: The defining mechanic. Bullets bounce off isometric walls, creating cascading ricochet patterns. Walls are both cover and danger amplifiers.

2. **Reflecting Beam**: The player's weapon bounces too, enabling skill-shot ricochet kills around corners. The aim preview makes this accessible.

3. **Isometric Bullet Hell**: A genre mashup that hasn't been done. The iso perspective adds visual depth and makes dodging feel three-dimensional.

4. **LOS-Gated Firing**: Tactical-shooter's visibility mechanic applied to bullet patterns. Turrets only fire when they see you. Strategic positioning matters.

5. **Bouncer Enemy**: A unique enemy type designed to exploit the reflection system. Its bullets persist for 5+ bounces, filling corridors with ricocheting projectiles.

6. **Wall Geometry as Gameplay**: The map layout IS the level design. Pillars and barriers create both safe zones (LOS blocking) and danger zones (ricochet alleys). Players must read the geometry.

---

## Phase 6: Implementation Stats

- **14 Lua files**, 2164 lines total
- **Largest files**: enemy.lua (307 lines), main.lua (285 lines), player.lua (262 lines)
- **Zero external dependencies** — all rendering via love.graphics primitives
- **Game confirmed running** with no crashes on initial launch
- Development approach: wrote all 15 files (14 Lua + AGENTS.md) in sequence, dependency order
- Also produced this LOG.md for full decision transparency
