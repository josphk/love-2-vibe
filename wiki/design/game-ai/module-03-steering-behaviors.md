# Module 3: Steering Behaviors

**Part of:** [Game AI Learning Roadmap](game-ai-learning-roadmap.md)
**Estimated study time:** 5-8 hours
**Prerequisites:** [Module 2: Behavior Trees](module-02-behavior-trees.md)

---

## Overview

Everything you've built so far has a movement problem. Your guard NPC "chases" the player by setting its position toward the target. It works, but it looks robotic — instant direction changes, no momentum, no grace. Real things don't move like that. Cars turn in arcs. Birds bank into curves. Even a person running changes direction gradually, not in sharp right angles.

Steering behaviors, first described by Craig Reynolds in 1987, solve this by treating NPCs as autonomous agents with **velocity** and **acceleration**. Instead of teleporting toward a goal, the NPC applies a **steering force** that adjusts its heading smoothly over time. The result is movement that looks alive — fluid pursuit, graceful evasion, natural wandering, and emergent flocking patterns that nobody explicitly programmed.

The real power comes from combination. Each steering behavior produces a force vector. Seek pushes toward a target. Flee pushes away. Obstacle Avoidance pushes away from walls. You blend these forces with weights — 60% Seek, 30% Obstacle Avoidance, 10% Wander — and the NPC chases the player while dodging obstacles without moving in a robotically straight line. It's vector math dressed up as intelligence, and it's beautiful.

---

## 1. The Steering Model

Every steered agent has three properties: **position**, **velocity**, and a **maximum speed**. Each frame, the agent computes a **desired velocity** (where it wants to go), subtracts its current velocity, and the difference is the **steering force**. The steering force is capped by a **maximum force** to prevent instant direction changes.

```
steering = desired_velocity - current_velocity
steering = truncate(steering, max_force)
acceleration = steering / mass
velocity = velocity + acceleration
velocity = truncate(velocity, max_speed)
position = position + velocity * dt
```

This is the core loop. Every steering behavior in this module produces a different `desired_velocity`. The rest of the math is always the same.

```gdscript
# GDScript — Base steered agent
extends CharacterBody2D

@export var max_speed := 150.0
@export var max_force := 300.0
@export var mass := 1.0

var vel := Vector2.ZERO

func apply_steering(desired: Vector2, delta: float) -> void:
    var steering = desired - vel
    steering = steering.limit_length(max_force)
    var acceleration = steering / mass
    vel += acceleration * delta
    vel = vel.limit_length(max_speed)
    velocity = vel
    move_and_slide()
    if vel.length() > 1.0:
        rotation = vel.angle()
```

```lua
-- Lua — Base steered agent
local Agent = {}
Agent.__index = Agent

function Agent.new(x, y)
    return setmetatable({
        x = x, y = y,
        vx = 0, vy = 0,
        max_speed = 150,
        max_force = 300,
        mass = 1,
    }, Agent)
end

function Agent:apply_steering(desired_x, desired_y, dt)
    local steer_x = desired_x - self.vx
    local steer_y = desired_y - self.vy
    -- Truncate steering to max_force
    local steer_len = math.sqrt(steer_x^2 + steer_y^2)
    if steer_len > self.max_force then
        steer_x = steer_x / steer_len * self.max_force
        steer_y = steer_y / steer_len * self.max_force
    end
    -- Apply acceleration
    self.vx = self.vx + (steer_x / self.mass) * dt
    self.vy = self.vy + (steer_y / self.mass) * dt
    -- Truncate velocity to max_speed
    local speed = math.sqrt(self.vx^2 + self.vy^2)
    if speed > self.max_speed then
        self.vx = self.vx / speed * self.max_speed
        self.vy = self.vy / speed * self.max_speed
    end
    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end
```

The `mass` parameter controls how responsive the agent is. Low mass = quick turns, twitchy movement. High mass = slow turns, heavy movement. A hummingbird has low mass. A freight train has high mass. Same steering math, different feel.

---

## 2. Seek and Flee

**Seek** is the simplest steering behavior: steer toward a target position at maximum speed.

```
desired_velocity = normalize(target - position) * max_speed
```

That's it. The desired velocity points directly at the target at full speed. The steering model takes care of the gradual turn.

**Flee** is Seek in reverse: steer away from a target position.

```
desired_velocity = normalize(position - target) * max_speed
```

```gdscript
# GDScript — Seek and Flee
func seek(target: Vector2) -> Vector2:
    var desired = (target - global_position).normalized() * max_speed
    return desired

func flee(target: Vector2) -> Vector2:
    var desired = (global_position - target).normalized() * max_speed
    return desired

# Usage in _process:
func _process(delta: float) -> void:
    var desired = seek(player.global_position)
    apply_steering(desired, delta)
```

```lua
-- Lua — Seek and Flee
function Agent:seek(tx, ty)
    local dx, dy = tx - self.x, ty - self.y
    local dist = math.sqrt(dx^2 + dy^2)
    if dist < 1 then return 0, 0 end
    return (dx / dist) * self.max_speed, (dy / dist) * self.max_speed
end

function Agent:flee(tx, ty)
    local dx, dy = self.x - tx, self.y - ty
    local dist = math.sqrt(dx^2 + dy^2)
    if dist < 1 then return 0, 0 end
    return (dx / dist) * self.max_speed, (dy / dist) * self.max_speed
end
```

Seek looks much better than the "set position toward target" approach from earlier modules. The NPC curves toward the target, overshoots slightly on turns, and has visible momentum. But it has one problem: it never stops. The NPC reaches the target and orbits around it endlessly because it's always at max speed. That's what Arrive fixes.

---

## 3. Arrive

**Arrive** is Seek with a deceleration zone. Outside the zone, it behaves identically to Seek. Inside the zone, it scales the desired speed down proportionally, so the NPC smoothly decelerates as it approaches the target.

```
distance = length(target - position)
if distance < slowing_radius:
    desired_speed = max_speed * (distance / slowing_radius)
else:
    desired_speed = max_speed
desired_velocity = normalize(target - position) * desired_speed
```

```gdscript
# GDScript — Arrive
@export var slowing_radius := 100.0

func arrive(target: Vector2) -> Vector2:
    var to_target = target - global_position
    var distance = to_target.length()
    if distance < 2.0:
        return -vel  # Brake to stop
    var desired_speed = max_speed
    if distance < slowing_radius:
        desired_speed = max_speed * (distance / slowing_radius)
    return to_target.normalized() * desired_speed
```

```lua
-- Lua — Arrive
function Agent:arrive(tx, ty, slowing_radius)
    slowing_radius = slowing_radius or 100
    local dx, dy = tx - self.x, ty - self.y
    local dist = math.sqrt(dx^2 + dy^2)
    if dist < 2 then return -self.vx, -self.vy end  -- brake

    local desired_speed = self.max_speed
    if dist < slowing_radius then
        desired_speed = self.max_speed * (dist / slowing_radius)
    end
    return (dx / dist) * desired_speed, (dy / dist) * desired_speed
end
```

Arrive is what you want for almost every "move to position" behavior. NPCs that stop precisely at their destination without overshooting look professional. The slowing radius controls how early the deceleration begins — larger values produce smoother, more graceful stops.

---

## 4. Wander

**Wander** gives an NPC natural-looking random movement. The naive approach — picking a random direction each frame — produces jittery, erratic movement that looks nothing like a creature wandering. Reynolds' Wander is much more elegant.

The idea: project a circle in front of the agent. Pick a random point on the circumference of that circle. Steer toward that point. Each frame, slightly adjust the point's position on the circle (by a random angle offset). The result is smooth, organic meandering.

```
                    ┌───────────────┐
                    │               │
              ──────┤   Wander      │
              │     │   Circle      │
  Agent ──────┘     │       * ← target point on circumference
              ↑     │               │
              │     └───────────────┘
         agent's
         forward
         direction
```

```gdscript
# GDScript — Wander
var wander_angle := 0.0
@export var wander_radius := 40.0
@export var wander_distance := 60.0
@export var wander_jitter := 0.3  # radians per second

func wander(delta: float) -> Vector2:
    wander_angle += randf_range(-wander_jitter, wander_jitter) * delta * 60
    var circle_center = vel.normalized() * wander_distance
    if circle_center.length() < 1.0:
        circle_center = Vector2.RIGHT * wander_distance
    var offset = Vector2(
        cos(wander_angle) * wander_radius,
        sin(wander_angle) * wander_radius
    )
    return (circle_center + offset).normalized() * max_speed
```

```lua
-- Lua — Wander
function Agent:wander(dt)
    self.wander_angle = (self.wander_angle or 0) +
        (love.math.random() * 2 - 1) * 0.3 * dt * 60

    local wander_dist = 60
    local wander_rad = 40

    -- Circle center is ahead of the agent
    local speed = math.sqrt(self.vx^2 + self.vy^2)
    local fx, fy = self.vx, self.vy
    if speed < 1 then fx, fy = 1, 0 end
    fx, fy = fx / math.max(speed, 1) * wander_dist, fy / math.max(speed, 1) * wander_dist

    local ox = math.cos(self.wander_angle) * wander_rad
    local oy = math.sin(self.wander_angle) * wander_rad

    local dx, dy = fx + ox, fy + oy
    local dist = math.sqrt(dx^2 + dy^2)
    if dist < 1 then return 0, 0 end
    return (dx / dist) * self.max_speed, (dy / dist) * self.max_speed
end
```

The `wander_jitter` parameter controls how erratic the movement is. Low jitter = smooth, lazy curves (great for fish or butterflies). High jitter = sharper turns (good for a confused or panicked creature). Wander is often blended with other behaviors — a patrolling NPC might use 80% Seek-to-waypoint + 20% Wander, making its patrol path slightly different each time.

---

## 5. Pursuit and Evade

**Seek** targets the current position. **Pursuit** targets where the quarry *will be*. The difference is dramatic — a pursuing agent intercepts instead of chasing tail.

The prediction is simple: estimate where the target will be in T seconds based on its current velocity, and Seek that future position. T is typically the distance divided by the agent's speed (closer = less prediction, farther = more).

```gdscript
# GDScript — Pursuit and Evade
func pursuit(target: Node2D) -> Vector2:
    var to_target = target.global_position - global_position
    var distance = to_target.length()
    var look_ahead = distance / max_speed  # prediction time
    var future_pos = target.global_position + target.velocity * look_ahead
    return seek(future_pos)

func evade(target: Node2D) -> Vector2:
    var to_target = target.global_position - global_position
    var distance = to_target.length()
    var look_ahead = distance / max_speed
    var future_pos = target.global_position + target.velocity * look_ahead
    return flee(future_pos)
```

```lua
-- Lua — Pursuit and Evade
function Agent:pursuit(target)
    local dx, dy = target.x - self.x, target.y - self.y
    local dist = math.sqrt(dx^2 + dy^2)
    local look_ahead = dist / self.max_speed
    local future_x = target.x + (target.vx or 0) * look_ahead
    local future_y = target.y + (target.vy or 0) * look_ahead
    return self:seek(future_x, future_y)
end

function Agent:evade(target)
    local dx, dy = target.x - self.x, target.y - self.y
    local dist = math.sqrt(dx^2 + dy^2)
    local look_ahead = dist / self.max_speed
    local future_x = target.x + (target.vx or 0) * look_ahead
    local future_y = target.y + (target.vy or 0) * look_ahead
    return self:flee(future_x, future_y)
end
```

Pursuit makes predators feel smart. A wolf using Pursuit cuts off a fleeing rabbit instead of following its trail. This creates tension for the player — the enemy is anticipating, not just reacting.

---

## 6. Obstacle Avoidance

An NPC that Seeks through walls is useless. Obstacle Avoidance casts "feelers" ahead of the agent and generates steering force away from obstacles.

The simplest approach: cast a ray in the agent's forward direction. If it hits an obstacle within a threshold distance, generate a force perpendicular to the ray that pushes the agent away from the obstacle.

```gdscript
# GDScript — Simple obstacle avoidance with raycasts
@export var avoid_distance := 80.0
@export var avoid_force := 200.0

func obstacle_avoidance() -> Vector2:
    var forward = vel.normalized()
    if forward.length() < 0.5:
        return Vector2.ZERO

    # Cast three feelers: forward, left 30°, right 30°
    var force = Vector2.ZERO
    var angles = [0, -0.5, 0.5]  # radians offset

    for angle_offset in angles:
        var direction = forward.rotated(angle_offset)
        var space_state = get_world_2d().direct_space_state
        var query = PhysicsRayQueryParameters2D.create(
            global_position,
            global_position + direction * avoid_distance
        )
        var result = space_state.intersect_ray(query)
        if result:
            var away = (global_position - result.position).normalized()
            var closeness = 1.0 - (result.position.distance_to(global_position) / avoid_distance)
            force += away * avoid_force * closeness

    return force
```

```lua
-- Lua — Simple obstacle avoidance (grid-based)
function Agent:obstacle_avoidance(walls)
    local force_x, force_y = 0, 0
    local speed = math.sqrt(self.vx^2 + self.vy^2)
    if speed < 1 then return 0, 0 end

    local fx, fy = self.vx / speed, self.vy / speed  -- forward direction
    local check_dist = 80

    -- Check point ahead
    local ahead_x = self.x + fx * check_dist
    local ahead_y = self.y + fy * check_dist

    for _, wall in ipairs(walls) do
        local dx = ahead_x - wall.x
        local dy = ahead_y - wall.y
        local dist = math.sqrt(dx^2 + dy^2)
        if dist < wall.radius + 15 then
            -- Push away from wall
            local away_x = self.x - wall.x
            local away_y = self.y - wall.y
            local away_dist = math.sqrt(away_x^2 + away_y^2)
            if away_dist > 0 then
                force_x = force_x + (away_x / away_dist) * 200
                force_y = force_y + (away_y / away_dist) * 200
            end
        end
    end
    return force_x, force_y
end
```

---

## 7. Flocking (Boids)

Flocking is the crown jewel of steering behaviors. Three simple rules — Separation, Alignment, and Cohesion — produce the mesmerizing emergent behavior of birds in flight, fish in schools, or zombies in a horde. Craig Reynolds coined the term "boids" (bird-oids) in his 1987 paper.

**Separation:** Steer away from neighbors that are too close. Prevents crowding.

**Alignment:** Steer toward the average heading of nearby neighbors. Keeps the flock moving in roughly the same direction.

**Cohesion:** Steer toward the average position of nearby neighbors. Keeps the flock together.

```
Separation:  ←○→  Push apart if too close
Alignment:   →→→  Match neighbors' heading
Cohesion:    →○←  Pull toward group center
```

```gdscript
# GDScript — Boid flocking
@export var separation_radius := 30.0
@export var neighbor_radius := 80.0
@export var separation_weight := 1.5
@export var alignment_weight := 1.0
@export var cohesion_weight := 1.0

func flock(boids: Array) -> Vector2:
    var separation = Vector2.ZERO
    var alignment = Vector2.ZERO
    var cohesion = Vector2.ZERO
    var sep_count := 0
    var neighbor_count := 0

    for other in boids:
        if other == self:
            continue
        var dist = global_position.distance_to(other.global_position)

        if dist < separation_radius:
            var away = (global_position - other.global_position).normalized()
            separation += away / max(dist, 0.1)
            sep_count += 1

        if dist < neighbor_radius:
            alignment += other.vel
            cohesion += other.global_position
            neighbor_count += 1

    if sep_count > 0:
        separation /= sep_count
        separation = separation.normalized() * max_speed

    if neighbor_count > 0:
        alignment /= neighbor_count
        alignment = alignment.normalized() * max_speed

        cohesion /= neighbor_count
        cohesion = seek(cohesion)  # Steer toward average position

    return (separation * separation_weight +
            alignment * alignment_weight +
            cohesion * cohesion_weight)
```

```lua
-- Lua — Boid flocking
function Agent:flock(boids)
    local sep_x, sep_y, sep_count = 0, 0, 0
    local ali_x, ali_y = 0, 0
    local coh_x, coh_y = 0, 0
    local neighbor_count = 0

    local sep_radius = 30
    local neighbor_radius = 80

    for _, other in ipairs(boids) do
        if other ~= self then
            local dx, dy = self.x - other.x, self.y - other.y
            local dist = math.sqrt(dx^2 + dy^2)

            if dist < sep_radius and dist > 0 then
                sep_x = sep_x + dx / dist / dist  -- weight by inverse distance
                sep_y = sep_y + dy / dist / dist
                sep_count = sep_count + 1
            end

            if dist < neighbor_radius then
                ali_x = ali_x + other.vx
                ali_y = ali_y + other.vy
                coh_x = coh_x + other.x
                coh_y = coh_y + other.y
                neighbor_count = neighbor_count + 1
            end
        end
    end

    local desired_x, desired_y = 0, 0

    if sep_count > 0 then
        local len = math.sqrt(sep_x^2 + sep_y^2)
        if len > 0 then
            desired_x = desired_x + (sep_x / len) * self.max_speed * 1.5
            desired_y = desired_y + (sep_y / len) * self.max_speed * 1.5
        end
    end

    if neighbor_count > 0 then
        -- Alignment: steer toward average heading
        ali_x, ali_y = ali_x / neighbor_count, ali_y / neighbor_count
        local alen = math.sqrt(ali_x^2 + ali_y^2)
        if alen > 0 then
            desired_x = desired_x + (ali_x / alen) * self.max_speed
            desired_y = desired_y + (ali_y / alen) * self.max_speed
        end

        -- Cohesion: steer toward average position
        coh_x, coh_y = coh_x / neighbor_count, coh_y / neighbor_count
        local cx, cy = self:seek(coh_x, coh_y)
        desired_x = desired_x + cx
        desired_y = desired_y + cy
    end

    return desired_x, desired_y
end
```

The weights are everything. High Separation creates a spread-out flock. High Cohesion creates a tight cluster. High Alignment creates a river of motion. Experiment with the ratios — the emergent patterns are endlessly fascinating.

---

## 8. Force Blending — Combining Behaviors

The real power of steering behaviors is that they combine. Each behavior produces a force vector, and you blend them with weights to create complex movement from simple components.

```gdscript
# GDScript — Weighted force blending
func _process(delta: float) -> void:
    var force = Vector2.ZERO

    if can_see_player():
        force += seek(player.global_position) * 0.6
    else:
        force += wander(delta) * 0.4

    force += obstacle_avoidance() * 1.0  # high weight — safety first
    force += flock(nearby_boids) * 0.3

    apply_steering(force.normalized() * max_speed, delta)
```

```lua
-- Lua — Weighted force blending
function Agent:update(dt)
    local fx, fy = 0, 0

    if self.can_see_player then
        local sx, sy = self:seek(player.x, player.y)
        fx = fx + sx * 0.6
        fy = fy + sy * 0.6
    else
        local wx, wy = self:wander(dt)
        fx = fx + wx * 0.4
        fy = fy + wy * 0.4
    end

    local ox, oy = self:obstacle_avoidance(walls)
    fx = fx + ox * 1.0  -- safety first
    fy = fy + oy * 1.0

    local bx, by = self:flock(boids)
    fx = fx + bx * 0.3
    fy = fy + by * 0.3

    -- Normalize to desired velocity
    local len = math.sqrt(fx^2 + fy^2)
    if len > 0 then
        self:apply_steering(fx / len * self.max_speed, fy / len * self.max_speed, dt)
    end
end
```

**Weight guidelines:**
- Obstacle Avoidance should always have the highest weight (safety overrides desire)
- Separation should be high enough to prevent overlapping
- The "goal" behavior (Seek, Arrive, Pursuit) drives the main movement
- Wander and Alignment are flavor — keep them moderate

A common pattern is **priority-based blending**: compute the highest-priority force first. If it's above a threshold, skip the rest. This prevents low-priority behaviors from interfering with urgent ones (obstacle avoidance shouldn't be diluted by wander).

---

## Code Walkthrough: Predator and Prey Scene

Let's build a scene that demonstrates steering behaviors in combination: a predator using Pursuit to chase boids, and boids that flock together while fleeing from the predator.

```lua
-- Lua (LÖVE) — Complete predator/prey scene
local boids = {}
local predator = nil

function love.load()
    -- Create 20 boids
    for i = 1, 20 do
        boids[i] = Agent.new(
            love.math.random(100, 700),
            love.math.random(100, 500)
        )
        boids[i].max_speed = 120
        boids[i].vx = love.math.random() * 100 - 50
        boids[i].vy = love.math.random() * 100 - 50
    end

    -- Create predator
    predator = Agent.new(400, 300)
    predator.max_speed = 100  -- slower than boids individually
    predator.max_force = 200
end

function love.update(dt)
    -- Update predator: pursuit nearest boid
    local nearest = nil
    local nearest_dist = math.huge
    for _, boid in ipairs(boids) do
        local d = distance(predator.x, predator.y, boid.x, boid.y)
        if d < nearest_dist then
            nearest = boid
            nearest_dist = d
        end
    end

    if nearest then
        local px, py = predator:pursuit(nearest)
        predator:apply_steering(px, py, dt)
    end

    -- Update boids: flock + flee from predator
    for _, boid in ipairs(boids) do
        local fx, fy = boid:flock(boids)

        -- Flee from predator if close
        local pred_dist = distance(boid.x, boid.y, predator.x, predator.y)
        if pred_dist < 150 then
            local flee_x, flee_y = boid:flee(predator.x, predator.y)
            local urgency = 1.0 - (pred_dist / 150)  -- stronger when closer
            fx = fx + flee_x * urgency * 2.0
            fy = fy + flee_y * urgency * 2.0
        end

        local len = math.sqrt(fx^2 + fy^2)
        if len > 0 then
            boid:apply_steering(fx / len * boid.max_speed, fy / len * boid.max_speed, dt)
        end

        -- Wrap around screen edges
        if boid.x < 0 then boid.x = 800 end
        if boid.x > 800 then boid.x = 0 end
        if boid.y < 0 then boid.y = 600 end
        if boid.y > 600 then boid.y = 0 end
    end

    -- Wrap predator
    if predator.x < 0 then predator.x = 800 end
    if predator.x > 800 then predator.x = 0 end
    if predator.y < 0 then predator.y = 600 end
    if predator.y > 600 then predator.y = 0 end
end

function love.draw()
    -- Draw boids as small triangles
    love.graphics.setColor(0.3, 0.8, 0.3)
    for _, boid in ipairs(boids) do
        local angle = math.atan2(boid.vy, boid.vx)
        love.graphics.push()
        love.graphics.translate(boid.x, boid.y)
        love.graphics.rotate(angle)
        love.graphics.polygon("fill", 8, 0, -5, -4, -5, 4)
        love.graphics.pop()
    end

    -- Draw predator as a larger red triangle
    love.graphics.setColor(1, 0.2, 0.2)
    local angle = math.atan2(predator.vy, predator.vx)
    love.graphics.push()
    love.graphics.translate(predator.x, predator.y)
    love.graphics.rotate(angle)
    love.graphics.polygon("fill", 14, 0, -8, -6, -8, 6)
    love.graphics.pop()
end
```

Watch this scene and you'll see emergent behavior that nobody programmed: the flock splits when the predator charges through. Boids on the edges flee first, creating a wave. The flock reforms after the predator passes. The predator pursues the nearest boid, creating a dynamic chase. All from simple vector math.

---

## Common Pitfalls

### 1. Agents vibrating or jittering at their destination

Arrive with too-small slowing radius or too-high max force causes the agent to overshoot, correct, overshoot, correct. Increase the slowing radius and decrease max force. Also add a dead zone — if distance to target is under 2 pixels, just stop.

### 2. Flocking boids clumping into a single point

Separation weight is too low relative to Cohesion. Increase Separation or decrease Cohesion. Also ensure Separation uses inverse-distance weighting (closer = stronger push).

### 3. Obstacle avoidance not working at high speeds

The avoidance feelers are too short for the agent's speed. Scale feeler length with velocity: `feeler_length = base_length + speed * 0.5`. Faster agents need to see further ahead.

### 4. Force weights that don't balance

When you add a new behavior, it can overwhelm everything else. Always normalize the combined force before applying it to the steering model. And remember: Obstacle Avoidance should always have the highest effective priority.

### 5. Not using delta time

Steering forces are rates of change. They must be multiplied by `dt` in the velocity update. Without `dt`, your steering looks different at 60 FPS vs 144 FPS.

### 6. Wander using random direction each frame

This produces erratic jittering, not wandering. True Wander uses a projected circle with small angular adjustments per frame, creating smooth curves. The randomness is in the *change of direction*, not the direction itself.

---

## Exercises

### Exercise 1: Steering Behavior Sandbox
**Time:** 1.5-2 hours

Build a sandbox where you can toggle different steering behaviors on and off for a single agent using keyboard keys:

- `1` = Seek (toward mouse cursor)
- `2` = Flee (away from mouse cursor)
- `3` = Arrive (toward mouse cursor with smooth deceleration)
- `4` = Wander
- `5` = Pursuit (toward a second, AI-controlled agent)

Display the current active behavior and draw the steering force vector as an arrow from the agent.

**Concepts practiced:** All five basic steering behaviors, visual debugging, force vectors

**Stretch goal:** Allow multiple behaviors simultaneously (toggle each on/off). Show the individual force vectors for each active behavior and the combined result.

---

### Exercise 2: Boids Playground
**Time:** 2-3 hours

Create a flock of 20-30 boids with adjustable weights. Requirements:

1. Boids flock using Separation, Alignment, and Cohesion
2. Sliders or keyboard controls adjust the three weights in real-time
3. Boids avoid screen edges (border avoidance zone)
4. Display current weight values on screen

Experiment and document: What happens when Separation is maxed and others are zero? When Cohesion dominates? When Alignment is the only force? What weight ratios produce the most natural-looking flocking?

**Concepts practiced:** Flocking, weight tuning, emergent behavior, parameter experimentation

**Stretch goal:** Add obstacles (circles on the screen) that boids avoid using Obstacle Avoidance blended with flocking forces.

---

### Exercise 3: Predator-Prey Ecosystem
**Time:** 2-3 hours

Build the predator/prey scene from the code walkthrough with these additions:

1. One predator using Pursuit to chase the nearest boid
2. 20 boids that flock together and Flee from the predator
3. When the predator gets within 15 pixels of a boid, the boid is "caught" (removed)
4. Every 10 seconds, a new boid spawns at a random location
5. If all boids are caught, the predator Wanders until new boids spawn

**Concepts practiced:** Pursuit, Flee, Flocking, behavior combination, dynamic population

**Stretch goal:** Add a second predator. Do the two predators coordinate (emergently) or compete? What happens if you make the predators also Separate from each other?

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| Craig Reynolds' steering behaviors page | Web (primary source) | The original descriptions and diagrams for every behavior — still the best reference |
| "Steering Behaviors for Autonomous Characters" (Reynolds, GDC 1999) | Paper | The seminal paper, surprisingly readable, with practical implementation guidance |
| *Nature of Code* Chapter 6: Autonomous Agents | Book (free, interactive) | Beautiful interactive examples of steering and flocking — the best visual learning resource |
| Red Blob Games on vectors and movement | Interactive guides | Essential background math for understanding steering forces and velocity |
| *Programming Game AI by Example* by Mat Buckland, Ch. 3 | Book | Thorough treatment of all steering behaviors with C++ code and clear diagrams |

---

## Key Takeaways

1. **Steering = desired velocity minus current velocity.** Every behavior computes a desired velocity. The difference from the current velocity is the steering force. Cap it, apply it, update position. That's the whole model.

2. **Arrive, not Seek, is what you usually want.** Seek reaches the target and orbits forever. Arrive decelerates smoothly. Use Arrive for any "go to position" behavior.

3. **Wander uses a projected circle, not random directions.** Small angular changes to a point on a circle ahead of the agent. This creates smooth, natural curves instead of jittery noise.

4. **Flocking is three rules combined.** Separation (don't crowd), Alignment (match heading), Cohesion (stay together). Weights control the character of the flock.

5. **Force blending creates complex movement from simple components.** 60% Seek + 30% Avoid + 10% Wander = an NPC that chases while dodging obstacles with natural variation. The weights are the design knobs.

6. **Obstacle Avoidance always gets highest priority.** Safety overrides desire. An NPC that walks into a wall while chasing looks broken, not smart.

---

## What's Next?

Your NPCs now know *how* to move — smoothly, organically, with fluid steering. But they don't know *where* to go when there's a wall between them and their target. Seek steers toward the player, but it can't navigate a maze.

In [Module 4: Pathfinding — A* & Navigation](module-04-pathfinding-astar-navigation.md), you'll learn the A* algorithm — the industry-standard pathfinding solution. A* finds a route around obstacles, and then your steering behaviors handle the smooth movement along that route. Together, pathfinding and steering give NPCs the complete package: intelligent navigation with natural motion.

---

[Back to Game AI Learning Roadmap](game-ai-learning-roadmap.md)
