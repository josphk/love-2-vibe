# Module 2: Bones, Constraints & Rigging

**Part of:** [Rive Learning Roadmap](rive-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** [Module 1: Vector Design](module-01-vector-design.md)

---

## Overview

In Module 1, you created artwork — shapes organized in groups, named, and ready for animation. But if you try to animate that artwork now, you'll quickly hit a wall. Moving individual shapes to simulate a head turn requires independently keyframing the head, each eye, each eyebrow, the mouth, and every other element. If you want the head to tilt and everything to follow, you're manually coordinating dozens of keyframes per pose. That's tedious, error-prone, and produces stiff, mechanical results.

Bones solve this. A bone is an invisible rigid element that you attach to artwork. When the bone moves, the artwork follows. Bones form parent-child hierarchies — rotate a parent bone and all its children rotate with it, just like rotating your shoulder moves your entire arm. This single concept transforms animation from "painstakingly coordinate 30 independent keyframes" to "rotate one bone and everything falls into place."

If you've used Spine, this is familiar territory. Rive's bone system works on the same principles — parent-child hierarchies, binding, constraints, mesh deformation, weight painting. The concepts transfer directly. The differences are in the interface details and the fact that Rive bones feed into Rive's state machine, which is a workflow Spine doesn't have.

This module covers the rigging pipeline from start to finish: creating bones, building hierarchies, binding artwork, adding constraints (IK, distance, transform), and setting up meshes with weights for smooth deformation. By the end, you'll have a rigged character face that moves naturally from a single bone rotation.

---

## Core Concepts

### 1. What Bones Are (and Aren't)

**A bone is an invisible, rigid, transformable element that drives artwork motion.** That's the complete definition. Bones don't render — you'll never see them in your exported animation. They exist purely as control handles that you (the animator) manipulate, and the artwork follows.

**Why bones instead of animating shapes directly:**

Without bones, animating a head turn means:
- Move the head shape
- Move the left eye, preserving its position relative to the head
- Move the right eye, preserving its position relative to the head
- Move each eyebrow, preserving positions
- Move the mouth, preserving position
- Repeat for every keyframe, manually maintaining spatial relationships

With bones:
- Rotate the head bone
- Everything attached to the head bone follows automatically
- One keyframe instead of six (or sixty)

Bones also enable things that direct shape animation can't do:
- **IK (Inverse Kinematics):** Specify where an endpoint should be, and the bone chain automatically orients to reach it
- **Constraints:** Rules that automate bone behavior (one bone always points at another, one bone copies another's rotation)
- **Mesh deformation:** Smooth, organic bending where bones influence nearby vertices differently

**The analogy:** Think of bones as a puppet's wooden frame. The puppet's fabric (artwork) is attached to the frame. You move the frame, the fabric follows. You never manipulate the fabric directly — you manipulate the frame, and the fabric inherits its motion.

**Common mistake:** Treating bones like groups. Groups are for visual organization. Bones are for animation control. They serve different purposes and are often set up differently. A visual group might contain "all face elements." A bone hierarchy would be "neck → head → jaw" — an animation chain, not an organizational container.

---

### 2. Building a Bone Hierarchy

Bone hierarchies follow the same parent-child logic as real skeletons:

- **Root bone:** The foundation. Usually placed at the character's center of mass or the base of the structure. Every other bone descends from this.
- **Parent-child relationships:** When a parent bone transforms, all children transform with it. Rotating the torso bone rotates the arms, head, and everything attached to them.
- **Hierarchy depth:** You can chain bones as deep as needed. `root → spine → chest → shoulder → upper-arm → lower-arm → hand → finger` is a common character chain.

**Building the hierarchy in Rive:**

1. Switch to Design Mode (bones are created in Design mode, not Animate mode)
2. Select the Bone tool (B shortcut)
3. Click to place the root bone's base point
4. Click again to place the root bone's tip (the bone appears as a line between base and tip)
5. With the root bone selected, click to start a child bone from its tip
6. Continue building the chain

**Hierarchy for a character face (your Module 1 exercise):**

```
root (bone, center of face)
├── head (bone, from root to top of head)
│   ├── jaw (bone, from head to chin area — for mouth movement)
│   ├── eye-ctrl-left (bone, short, at left eye — for eye direction)
│   └── eye-ctrl-right (bone, short, at right eye — for eye direction)
└── (optional) neck (bone, below root — for body connection later)
```

This is minimal. A full character body would have dozens of bones. For a face, you need:
- **Root:** The anchor point. Everything hangs off this.
- **Head:** Controls the overall head rotation/position. When the head tilts, everything follows.
- **Jaw:** Controls mouth opening (rotation on the jaw bone = mouth open/close).
- **Eye controllers:** Small bones at each eye position. Moving these controls where the eyes "look."

**Bone placement tips:**
- Place bones at natural joint/pivot points (neck joint, eye center, jaw hinge)
- Bone length matters for IK calculations — make bones proportional to the body part they represent
- The bone's base point is its pivot — rotations happen around the base, not the center or tip

**Common mistake:** Making bones too short or too long. A bone should roughly match the length of the body part it controls. A head bone should span from the neck to the top of the head, not be a tiny stub at the center. Proper lengths make IK work correctly and make the hierarchy visually readable.

---

### 3. Binding Artwork to Bones

Creating bones is step one. Making artwork follow those bones is step two — this is **binding**.

**Direct binding (simple):** The simplest form. You bind a shape to a bone, and the shape follows the bone rigidly. When the bone moves, the shape moves. When the bone rotates, the shape rotates. No deformation — the shape stays exactly the same; it just changes position and orientation.

This is sufficient for rigid elements — a robot's arm segment, an eye that shifts position, a hat that follows a head. Anything that doesn't need to bend or deform.

**How to bind in Rive:**
1. Select the shape you want to bind
2. In the hierarchy, drag the shape to be a child of the target bone
3. The shape now follows the bone's transforms

That's it for simple binding. The shape inherits the bone's position, rotation, and scale.

**When direct binding isn't enough:**

Direct binding moves shapes rigidly. But organic characters don't move rigidly — skin stretches, fabric drapes, joints bend smoothly. A character's arm doesn't teleport between two positions; the skin deforms smoothly around the elbow. For this, you need mesh binding (covered next).

**Common mistake:** Binding to the wrong bone. If you bind the left eye to the right eye's bone, the left eye follows the right eye. Sounds obvious, but in a complex hierarchy with many bones, it's easy to drag a shape to the wrong parent. Always test after binding — rotate the bone and verify the correct artwork follows.

---

### 4. Meshes: From Rigid to Organic

A mesh converts a shape from a solid, rigid element into a deformable surface made of triangulated vertices. Once a shape is a mesh, you can move individual vertices (like pushing and pulling pins in fabric), and the shape deforms smoothly between them.

**Why meshes matter:**

Without meshes, a character's arm is two rigid rectangles (upper arm and lower arm) that rotate at the elbow. The joint looks like a robot — two straight pieces meeting at an angle. With a mesh, the arm is a single shape with vertices weighted to different bones. The elbow area vertices are influenced by both the upper-arm bone and the lower-arm bone, so they interpolate smoothly between the two — creating a natural, organic bend.

**Creating a mesh in Rive:**
1. Select a shape
2. In the inspector, convert it to a mesh (there's a mesh toggle/button)
3. The shape now displays vertices (control points)
4. You can add, move, and delete vertices
5. The mesh auto-triangulates between vertices to form the deformable surface

**Vertex placement strategy:**
- Place more vertices where deformation happens (joints, bends, flexible areas)
- Place fewer vertices where the shape stays rigid (center of a limb, flat surfaces)
- Follow the natural contour of the shape with vertex placement
- Avoid placing vertices too close together — this can cause visual artifacts during deformation

**Important principle:** The mesh's rest position (where you place vertices in Design mode) is the "neutral" pose. All deformation is relative to this rest position. If the mesh looks weird in its rest position, it'll look weird when animated. Get the rest position right before animating.

**Common mistake:** Adding too many vertices. More vertices = more deformation control, but also more complexity to manage. Start with the minimum number of vertices needed for clean deformation, then add more only where needed. For a character face, you might need 10-20 mesh vertices total, not 100.

---

### 5. Weight Painting: Smooth Multi-Bone Influence

When a mesh is bound to multiple bones, each vertex needs to know how much each bone influences it. This is **weight painting** — assigning influence values (weights) from 0.0 (no influence) to 1.0 (full influence) for each bone at each vertex.

**The concept:**

Imagine a vertex at a character's elbow. The upper-arm bone has 50% influence (weight = 0.5) and the lower-arm bone has 50% influence (weight = 0.5). When the lower-arm bone rotates 90°, this vertex moves to a position halfway between "following the upper arm" and "following the lower arm" — creating a smooth bend.

A vertex at the middle of the upper arm would have 100% upper-arm bone influence (weight = 1.0) and 0% lower-arm influence (weight = 0.0). It follows the upper arm rigidly.

**Weight painting in Rive:**
1. Select a mesh that overlaps multiple bones
2. Enter weight painting mode
3. Each bone is a color — the mesh displays which bone influences which area
4. Paint (or manually set) weights for each vertex
5. Weights at each vertex should sum to 1.0 (Rive typically normalizes this automatically)

**Weight distribution patterns:**

For a typical joint (like an elbow or knee):
- Vertices near the middle of bone A: weight = 1.0 for bone A, 0.0 for bone B
- Vertices at the joint between A and B: weight = 0.5 for A, 0.5 for B (smooth blend)
- Vertices near the middle of bone B: weight = 0.0 for bone A, 1.0 for bone B
- Transition zone: weights gradually shift from mostly-A to mostly-B over 3-5 vertices

**Testing weights:**
After weight painting, rotate each bone and watch how the mesh deforms. You're looking for:
- Smooth bending at joints (no pinching, no sharp folds)
- Rigid behavior in the middle of limbs (no wobbling)
- Natural-looking silhouette during motion

**Why it matters:** Weight painting is the difference between a character that bends like a rubber hose (all weights too soft) and one that bends like a robot (all weights too hard). Good weight painting creates the illusion of underlying anatomy — muscles, joints, and bones beneath the surface.

**Common mistake:** Default/automatic weights often look "okay" but produce mushy results. Take the time to manually adjust weights at key joints. The investment pays off in every animation that uses the rig.

---

### 6. Constraints: Automated Bone Behavior

Constraints are rules that automate bone behavior. Instead of manually keyframing every bone on every frame, you define relationships between bones and let the constraints handle the math.

**IK (Inverse Kinematics) — The Most Important Constraint**

IK is the reverse of normal bone animation (called Forward Kinematics or FK):

- **FK (Forward Kinematics):** You rotate each bone in the chain individually. Rotate the shoulder, then rotate the elbow, then rotate the wrist. You specify rotations and the endpoint position is a *result*.
- **IK (Inverse Kinematics):** You specify where the endpoint (hand/foot) should be, and the bone chain automatically rotates to reach it. You specify the *target position* and rotations are calculated automatically.

**When to use IK vs. FK:**
- **IK** is better for: feet planted on the ground (the foot stays put, the leg adjusts), hands reaching for objects (move the target to the object, the arm follows), any situation where the end point is more important than the individual rotations
- **FK** is better for: swinging motions (a character swinging a sword — the rotation propagates from shoulder outward), flowing movements (hair, tails, tentacles), any situation where the rotation is more important than the endpoint position

**Setting up IK in Rive:**
1. Create a bone chain (e.g., upper-arm → lower-arm → hand)
2. Create an IK target (a bone or object that represents where the hand should go)
3. Add an IK constraint to the chain
4. Set the target to your IK target object
5. Now, moving the IK target moves the "hand," and the arm bones automatically orient to reach it

**IK settings to know:**
- **Chain length:** How many bones in the chain are affected by the IK solver (usually 2 for a limb — upper and lower)
- **Flip:** Which way the joint bends. An elbow bends one way; a knee bends the other. The flip setting controls this.
- **Strength:** How much the IK overrides the bone's normal rotation. At 1.0, IK fully controls the bone. At 0.5, IK and FK blend 50/50. At 0.0, IK has no effect. Animating IK strength lets you smoothly transition between IK and FK control.

**Distance Constraint**

Maintains a fixed distance between two objects. If one moves, the other is pushed/pulled to maintain the distance. Use cases:
- A chain link that stays connected to its neighbor
- An orbiting element that stays at a fixed radius
- A character's feet that shouldn't stretch beyond leg length

**Translation/Rotation/Scale Constraints**

Copy or limit transforms between objects:
- **Copy rotation:** One bone always matches another's rotation (a character's eyes both rotate the same amount when looking sideways)
- **Copy translation:** One bone follows another's position
- **Limit rotation:** A bone can only rotate within a specified range (a head can turn 90° left and 90° right, but not 360°)
- **Limit translation:** A bone can only move within a specified area

**Constraint stacking:** Multiple constraints can apply to a single bone, and they evaluate in order. A bone might have an IK constraint (reach toward a target) and a rotation limit (but don't rotate more than 45°). The result is a blend of both constraints.

**Common mistake:** Using too many constraints too early. Constraints are powerful but add complexity. Start with a simple FK rig (just rotating bones directly). Add IK only where it solves a real problem. Add other constraints only when you need automated behavior that manual keyframing can't efficiently achieve.

---

### 7. The Rigging Workflow: Step by Step

Rigging isn't one task — it's a sequence of tasks that build on each other. Here's the complete workflow from artwork to finished rig:

**Step 1: Plan the skeleton**
Before creating any bones, decide what needs to be animated and how. Draw the skeleton on paper or in your head:
- What are the major movable parts? (head, arms, legs, tail)
- Where are the joints? (neck, shoulders, elbows, knees)
- What's the parent-child hierarchy? (root → spine → chest → head)
- What needs IK? (feet planted on ground, hands reaching for objects)

**Step 2: Create bones in Design Mode**
Build the skeleton following your plan. Start from the root and work outward:
1. Place the root bone at the character's center of mass
2. Build the spine/body chain upward
3. Build limb chains from the body outward
4. Build secondary chains (tail, hair, accessories)

**Step 3: Bind artwork to bones**
For each piece of artwork:
- Determine which bone should control it
- Make the artwork a child of that bone in the hierarchy
- Test by rotating the bone — does the right artwork follow?

**Step 4: Convert critical shapes to meshes**
Any shape that needs to deform (not just move rigidly) needs to be a mesh:
- Joint areas (elbows, knees, neck)
- Organic shapes (torso, face)
- Flexible elements (clothing, hair)

**Step 5: Weight paint meshes**
For each mesh that overlaps multiple bones:
- Assign weights to determine how each bone influences each vertex
- Test by rotating bones at joints — deformation should be smooth
- Adjust weights until bending looks natural

**Step 6: Add constraints**
Add IK, distance, and other constraints where needed:
- IK for limbs that need to reach targets
- Rotation limits for joints with natural range limits
- Copy constraints for synchronized elements

**Step 7: Test the complete rig**
Manipulate every bone and verify:
- All artwork follows the correct bones
- Mesh deformation looks smooth at joints
- IK targets move correctly
- Constraints behave as expected
- The hierarchy makes sense for the animations you plan to create

**Step 8: Save a clean rest pose**
The rig should look correct in its rest position (the Design mode state). All bones at their default rotations, all meshes relaxed, everything in its "neutral" pose. This is the reference state that all animations depart from and return to.

---

### 8. Rigging for the State Machine (Rive-Specific)

Here's where Rive's rigging differs from Spine's in practice. In Spine, your rig serves one purpose: animation. In Rive, your rig also serves the **state machine** — the interactive logic layer.

This means:
- **Your rig needs to support all states.** If your character has an idle state, a talking state, and an angry state, the rig must accommodate all three. A jaw bone for talking, eyebrow bones for angry expressions, body bones for idle breathing — all present in one rig.
- **Bone names become part of your state machine's vocabulary.** When the state machine controls which animation plays, and those animations keyframe specific bones, the bone names need to be clear and consistent. `head-tilt`, `jaw-open`, `eye-look-left` are good names that communicate what animating them does.
- **Blend states need compatible rigs.** If you plan to blend between "idle" and "walking" animations, both must use the same bone structure. You can't blend between a walk animation that uses `leg-upper-left` and an idle that uses `thigh-l` — the bone names must match.

**Practical implication:** Plan your rig for the full range of behaviors your character will have, not just the first animation you want to create. Adding bones to a rig later is possible but means updating existing animations to account for the new bones.

---

## Case Studies

### Case Study 1: Face Rig for Reactive Expressions

A face rig that supports a state machine with emotional expressions needs specific bones:

**Bone setup:**
```
root
├── head (rotation: tilt, nod)
│   ├── brow-left (rotation: raise/lower for surprise/anger)
│   ├── brow-right (rotation: raise/lower)
│   ├── eye-left (translation: look direction)
│   ├── eye-right (translation: look direction)
│   ├── eyelid-upper-left (rotation: blink/squint)
│   ├── eyelid-upper-right (rotation: blink/squint)
│   ├── jaw (rotation: open/close mouth)
│   ├── mouth-corner-left (translation: smile/frown)
│   └── mouth-corner-right (translation: smile/frown)
```

**Why each bone:** Every bone maps to a distinct expressive action. `brow-left` raised + `brow-right` raised + `eyelid-upper` wide open = surprise. `brow-left` lowered + `brow-right` lowered + `mouth-corner` down = anger. The state machine can blend between these expressions by controlling which animation plays, and each animation keyframes different subsets of these bones.

**Key insight:** The eye bones control *translation* (position), not rotation. When eyes "look left," the pupils shift left — they don't rotate. The eyebrow and eyelid bones control *rotation* (tilt up/down). Understanding which transform type each bone needs prevents fighting the rig later.

### Case Study 2: Simple Character Body Rig

A basic character body rig for walk/idle/jump animations:

```
root (at hips/center of mass)
├── spine (torso)
│   ├── chest
│   │   ├── head (with face sub-rig)
│   │   ├── arm-upper-left
│   │   │   └── arm-lower-left
│   │   │       └── hand-left
│   │   ├── arm-upper-right
│   │   │   └── arm-lower-right
│   │   │       └── hand-right
├── leg-upper-left
│   └── leg-lower-left
│       └── foot-left
├── leg-upper-right
│   └── leg-lower-right
│       └── foot-right
```

**IK targets for this rig:**
- `ik-hand-left` — for hands reaching, grabbing, gesturing
- `ik-hand-right`
- `ik-foot-left` — for feet planted on ground during walk
- `ik-foot-right`

The IK targets are separate bones/objects that the IK constraints reference. Moving an IK target moves the associated hand/foot, and the arm/leg chain automatically orients to reach it.

### Case Study 3: UI Element "Rig" (Non-Character)

Rigging isn't just for characters. UI elements benefit from simple bone structures:

**Animated toggle switch:**
```
toggle-root
├── track-bone (controls track background)
├── knob-bone (controls knob position — slides left/right)
└── icon-bone (controls the checkmark/X icon)
```

The state machine toggles between "on" and "off" states. The "on" animation moves `knob-bone` right and swaps the icon. The "off" animation reverses it. Simple two-bone rig, but it makes the toggle's animation clean and controllable.

**Why rig a UI element?** Because bones give you precise transform control at specific pivot points. Without bones, animating a toggle means keyframing the knob shape's position, the icon's opacity/position, and the track's color all independently. With bones, you have a clean control hierarchy that's easier to keyframe and produces smoother results.

---

## Common Pitfalls

1. **Not planning the skeleton before creating bones.** Jumping straight into bone creation leads to a messy hierarchy that's hard to animate. Spend 5 minutes thinking about what needs to move, how it connects, and where the joints are. Then build.

2. **Bones at wrong pivot points.** The bone's base point is its rotation pivot. If a head bone's base is at the forehead, the head rotates around the forehead (wrong). If it's at the neck, it rotates around the neck (right). Always place the bone's base at the natural joint/hinge point.

3. **Over-rigging simple elements.** A button doesn't need 10 bones. An eye that just shifts position doesn't need a 5-bone chain. Use bones where they add value — complex motion, joint bending, hierarchy control. Don't use them for simple position/rotation animation on a single shape.

4. **Skipping mesh and weight testing.** Weight painting looks correct until you rotate the bones. Always test by actually rotating every bone through its full range of motion. Deformation artifacts (pinching, stretching, collapsing) only reveal themselves during motion.

5. **Mixing up IK and FK when they're not needed.** IK is powerful but adds complexity. If a limb just swings back and forth (like a simple walk cycle), FK (direct rotation) is simpler and gives you more control. IK is best when the endpoint position is more important than the rotation path — planted feet, reaching hands, following targets.

6. **Inconsistent bone naming.** If one arm's bones are named `arm-upper-left` and `arm-lower-left` but the other arm uses `rightUpperArm` and `rightLowerArm`, you'll confuse yourself constantly. Pick a naming convention and stick with it. Recommended: `part-modifier-side` format (e.g., `arm-upper-left`, `leg-lower-right`, `eye-ctrl-left`).

7. **Forgetting that the rest pose matters.** The Design mode state is your rest pose. All animations are relative to this pose. If the rest pose has the head tilted 10° right, then a "head centered" animation needs to actively rotate it -10° to center it. Start from a clean, neutral rest pose.

8. **Not considering the state machine.** Your rig needs to support every animation the state machine will reference. If you plan to add a "surprised" expression later, you need the eyebrow bones now. Retroactively adding bones to an existing rig means revisiting every animation that uses it.

---

## Exercises

### Exercise 1: Paper Skeleton Planning (Beginner, 15 minutes)

On a piece of paper (or digital drawing), sketch the character face from Module 1. Draw circles at every point where something pivots or rotates. Draw lines connecting them in a hierarchy. Label each connection.

Your sketch should show:
- Where the root bone goes
- Where the head bone connects (root → head)
- Where the eye control bones sit
- Where the jaw bone hinges
- The parent-child hierarchy as a tree

Don't open Rive yet. This exercise is about thinking through the skeleton before touching the tool.

### Exercise 2: First Bones (Beginner, 30 minutes)

Open your character face from Module 1. In Design Mode:

1. Create a root bone at the center/base of the face
2. Create a head bone extending from root to the top of the head
3. Create a jaw bone extending from the head to the chin area
4. Create small control bones at each eye position

Test the rig: rotate the head bone. Does the whole face rotate? Rotate the jaw bone. Does the mouth area move independently of the eyes?

Requirements:
- All bones named clearly (root, head, jaw, eye-ctrl-left, eye-ctrl-right)
- Head bone pivot at the neck/base area
- Jaw bone pivot at the hinge point (roughly between the ears)

### Exercise 3: Binding Artwork (Intermediate, 45 minutes)

Bind your character face artwork to the bones from Exercise 2:

1. Bind the head shape to the head bone (make it a child)
2. Bind the eyeball shapes to the head bone (they move with the head)
3. Bind the pupil shapes to the eye control bones (they move independently for "looking")
4. Bind the mouth to the jaw bone (it moves with the jaw)
5. Bind the eyebrows to the head bone

Test every bone:
- Rotate head: everything follows
- Move eye-ctrl-left: only the left pupil moves
- Rotate jaw: mouth opens, but eyes and eyebrows stay with the head
- The face should look "alive" with just bone manipulation

### Exercise 4: IK Experiment (Intermediate, 30 minutes)

If you have a body character or want to experiment:

1. Create a three-bone arm chain: upper-arm → lower-arm → hand
2. Create a separate IK target object (a small circle or bone)
3. Add an IK constraint to the arm chain targeting the IK target
4. Move the IK target around — the arm should reach for it automatically
5. Try flipping the IK direction — the elbow should bend the other way
6. Set IK strength to 0.5 — the arm should partially reach but not fully follow the target

If you don't have a body character yet, do this experiment with three abstract rectangles connected as an arm. The concepts transfer.

### Exercise 5: Mesh Deformation Test (Advanced, 45 minutes)

This exercise requires a body part that bends at a joint (arm, leg, or torso). If you only have a face, skip to the next module and return when you have a body character.

1. Create a single shape that spans a joint (e.g., one rectangle for an entire arm)
2. Convert it to a mesh
3. Add vertices along the length, with more vertices near the joint (elbow area)
4. Create two bones through the shape (upper and lower)
5. Weight-paint the vertices:
   - Near the upper bone: weight mostly to upper bone
   - Near the joint: weight split between both bones
   - Near the lower bone: weight mostly to lower bone
6. Rotate the lower bone and observe the deformation
7. Adjust weights until the bend looks smooth and natural

---

## Recommended Reading & Resources

**Tier 1 — Do Now:**
- [Rive Bones Documentation](https://help.rive.app/editor/manipulating-shapes/bones) — official bone creation and hierarchy
- [Rive Constraints](https://help.rive.app/editor/constraints) — IK, distance, and transform constraints
- [Rive Meshes](https://help.rive.app/editor/manipulating-shapes/meshes) — mesh creation and weight painting

**Tier 2 — Deeper Understanding:**
- Spine's bone and constraint documentation — same concepts, different interface. Reading both helps solidify the principles.
- Browse community files with rigged characters — study their bone hierarchies in the editor. How many bones do they use? Where are the IK constraints?

**Tier 3 — Animation Principles:**
- Any resource on character rigging principles (the concepts are universal across all 2D and 3D animation tools)
- Weight painting tutorials from any tool (Maya, Blender, Spine) — the visual tool differs but the concept is identical

---

## Key Takeaways

1. **Bones are invisible control handles that drive artwork motion.** They form parent-child hierarchies. Rotate a parent and all children follow.

2. **The rigging workflow is: plan → create bones → bind artwork → add meshes → weight paint → add constraints → test.** Don't skip steps.

3. **Place bone base points at natural pivot/joint points.** The base is where rotation happens. Wrong pivot = wrong motion.

4. **Meshes enable smooth deformation at joints.** Without meshes, everything moves rigidly. With meshes and weight painting, joints bend organically.

5. **IK lets you specify endpoints instead of rotations.** Use IK for planted feet, reaching hands, and target-following. Use FK (direct rotation) for swinging, flowing motions.

6. **Constraints automate bone behavior.** IK, distance limits, rotation copying — constraints reduce the keyframes you need to set manually.

7. **Plan your rig for the state machine.** Your rig needs to support every expression, pose, and behavior the state machine will orchestrate. Add all necessary bones upfront.

8. **Name bones consistently.** Bones are referenced by animations and state machines. Clear, consistent naming prevents confusion across the entire project.

---

## What's Next

**[Module 3: Timeline Animation →](module-03-timeline-animation.md)**

Your character has artwork (Module 1) and a skeleton (Module 2). Now it's time to bring it to life. Module 3 covers keyframe animation — creating blink, idle, and reaction animations on the timeline. This is where your character starts moving.
