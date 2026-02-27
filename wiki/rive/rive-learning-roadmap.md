# Rive Learning Roadmap

**For:** Game developer learning interactive animation · Reads > watches · ADHD-friendly · Considering Rive alongside or instead of Spine

---

## How This Roadmap Works

Same rules as your other roadmaps: modular, jump-around-friendly, text-first. Module 0 is required, then go wherever your energy takes you.

**But first, an honest comparison with Spine for your use case:**

Rive and Spine overlap but aren't the same tool. Understanding the difference will save you from learning the wrong thing.

| | Spine | Rive |
|---|---|---|
| **Primary strength** | Skeletal character animation for games | Interactive, state-driven animation for apps, UI, and games |
| **Editor** | Desktop app (offline) | Browser-based (cloud) |
| **State machines** | No (you build state logic in game code) | Yes (visual state machine built into the editor) |
| **Vector drawing** | No (import raster images only) | Yes (full vector design tools built in) |
| **LÖVE runtime** | Official Lua/LÖVE runtime exists | No LÖVE runtime — C++ runtime exists but requires custom integration |
| **Game character animation** | Its entire purpose — deep, specialized | Capable but less specialized |
| **UI/HUD animation** | Not designed for this | Excellent — this is a core strength |
| **Pricing** | $69–$379 one-time | Free editor, $9/mo to export |

**The LÖVE integration reality:** Spine has an official LÖVE runtime. Rive does not. Rive has a C++ runtime you could theoretically bind to LÖVE via LuaJIT FFI, but that's an advanced, undocumented path. If you're using LÖVE, Spine is the straightforward choice for character animation.

**Where Rive shines for game dev:** UI, menus, HUD elements, interactive icons, loading screens, cutscene elements, and anywhere you want state-driven animation without writing state machine code. If you're using Unity, Unreal, or a web-based game, Rive has official runtimes and is excellent.

**Recommendation:** Learn both. Use Spine for character animation in LÖVE. Use Rive for UI/HUD elements if you move to an engine with Rive support, or for any web/app projects. The skills transfer — bones, keyframes, easing, and animation principles are universal.

---

## Module 0: Orientation & The Rive Mental Model

**Goal:** Understand what Rive is, how it thinks, and why it's different from traditional animation tools.

### Rive is not just an animation tool

Rive is an **interactive design platform**. The key word is "interactive." Traditional animation tools (After Effects, Spine, even CSS animations) create linear timelines — animation plays from A to B. Rive creates **state-driven animation** — animation responds to inputs, conditions, and events in real-time.

Think of it this way:
- **Traditional animation:** A movie. It plays the same way every time.
- **Rive animation:** A puppet that reacts. Hover over it and it looks at your cursor. Click it and it plays a reaction. Change a variable and its expression changes.

This is why Rive is used by Duolingo (the owl reacts to your answers), Spotify, and Google — anywhere animation needs to respond to user behavior.

### The three pillars of Rive

1. **Design:** Rive has built-in vector drawing tools. You can create your artwork directly in Rive — no Photoshop/Illustrator required (though you can import SVGs and images too).

2. **Animate:** Timeline-based keyframe animation, similar to any animation tool. Bones, meshes, easing curves — the usual suspects.

3. **State Machine:** The killer differentiator. A visual node graph where you connect animations as states, define transitions between them, and set conditions (inputs) that trigger those transitions. The designer builds the logic visually; the developer just feeds in the inputs from code.

### Setup

1. Go to https://rive.app and create a free account
2. The editor runs in your browser — nothing to install
3. Open the Community files to see what others have built
4. Open a simple example and poke around

### The interface

- **Stage** (center): Your canvas — where you design and see your artwork
- **Hierarchy** (left): The tree of all objects, groups, bones, etc.
- **Inspector** (right): Properties of whatever's selected
- **Timeline** (bottom): Keyframes and animation curves
- **State Machine** (separate mode): The visual logic graph

Rive has three modes you'll switch between:
- **Design Mode:** Create and arrange artwork
- **Animate Mode:** Create timeline animations
- **State Machine Mode:** Wire animations together with logic

**Read:**
- Rive Getting Started: https://help.rive.app/getting-started
- Rive Editor Basics: https://help.rive.app/editor/fundamentals
- Rive Community: https://rive.app/community — browse examples, open them in the editor, reverse-engineer how they work

**Exercise:** Open 3 community files. For each, identify: what animations exist, what inputs/interactions trigger them, and how the state machine connects everything. Don't build anything yet — just observe and click around.

**Time:** 1–2 hours

---

## Module 1: Vector Design in Rive

**Goal:** Learn to create artwork directly in Rive's editor.

Unlike Spine (which requires you to import pre-made images), Rive has a full vector design toolkit built in. This means you can design and animate in the same tool — no round-tripping to Illustrator.

### Core drawing tools

- **Pen tool:** Draw bezier paths (similar to Illustrator/Figma)
- **Shape tools:** Rectangles, ellipses, polygons, stars
- **Groups:** Organize objects hierarchically
- **Boolean operations:** Union, subtract, intersect shapes
- **Fills & strokes:** Solid colors, gradients, stroke width/caps

### Key concepts

- **Artboards:** Self-contained canvases. One Rive file can have multiple artboards (think of them as different screens or components).
- **Groups vs. bones:** Groups organize visually. Bones create animation hierarchies. You'll use both.
- **Clipping:** Mask content inside a shape (e.g., a health bar that fills by clipping a colored rectangle).
- **Solos:** Toggle visibility of objects for organization — like Photoshop layer visibility.

### Design tips for animation

- **Keep shapes separate:** Don't merge shapes you'll want to animate independently
- **Name everything:** `left-eye`, `mouth-smile`, `body-torso` — not `Path 47`
- **Think in layers:** Background → body → face → foreground. Draw order is your z-index.
- **Use groups strategically:** A group can be moved/rotated as a unit. Group the head parts so you can rotate the whole head with one transform.

**Read:**
- Rive Shapes & Paths: https://help.rive.app/editor/fundamentals/shapes-and-paths
- Rive Artboards: https://help.rive.app/editor/fundamentals/artboards

**Exercise:** Draw a simple character face in Rive using only the built-in tools. Head (ellipse), two eyes (ellipses), mouth (pen path), maybe some hair (pen paths). Keep it simple but name every part clearly. This will be your animation subject for the next few modules.

**Time:** 2–3 hours

---

## Module 2: Bones, Constraints & Rigging

**Goal:** Build a skeleton for your artwork and learn Rive's rigging tools.

Rive's bone system works similarly to Spine's — you create a hierarchy of bones, bind artwork to them, and animate the bones to move the artwork.

### Core concepts

- **Bones:** Invisible rigid elements in a parent-child hierarchy. Rotate a parent, children follow.
- **Binding:** Connecting artwork to bones so it moves with them.
- **Constraints:** Rules that automate bone behavior:
  - **IK (Inverse Kinematics):** Bones automatically orient to reach a target point
  - **Distance constraint:** Maintains distance between objects
  - **Translation/rotation/scale constraints:** Copy or limit transforms between objects

### Rigging workflow

1. Switch to Design Mode
2. Create bones using the Bone tool (B shortcut)
3. Build the hierarchy: root → torso → head, root → torso → upper-arm → lower-arm
4. Bind artwork to bones
5. Test by rotating bones — artwork should follow

### Meshes & weights

Like Spine, Rive supports mesh deformation:
- Convert an image or shape to a mesh
- Add vertices to control deformation points
- Assign weights so vertices follow multiple bones (smooth bending at joints)

This is essential for organic-looking character animation — a rigid arm that rotates at the elbow looks mechanical, but a weighted mesh bends smoothly.

**Read:**
- Rive Bones: https://help.rive.app/editor/manipulating-shapes/bones
- Rive Constraints: https://help.rive.app/editor/constraints
- Rive Meshes: https://help.rive.app/editor/manipulating-shapes/meshes

**Exercise:** Add bones to your character face. At minimum: a root bone, head bone, and individual bones for each eye and the mouth. Add IK or constraints if you're feeling ambitious. Test that rotating the head moves everything naturally.

**Time:** 2–4 hours

---

## Module 3: Timeline Animation

**Goal:** Create keyframe animations using Rive's timeline.

This is the most familiar territory if you've used any animation tool. The core loop is the same: pose → keyframe → advance time → new pose → keyframe → Rive interpolates.

### Key concepts

- **Animations:** Named timeline sequences. One artboard can have many animations ("idle", "walk", "blink", "wave").
- **Keys:** Snapshots of property values at specific times. Position, rotation, scale, opacity, path points, colors — almost anything can be keyed.
- **Interpolation:** How values transition between keys. Linear, hold (stepped), or cubic bezier.
- **Graph editor:** Visualize and edit interpolation curves. This is where you control easing — the difference between robotic and natural motion.
- **Keying modes:**
  - **Manual keying:** You explicitly set keys (more control)
  - **Auto-key:** Any change you make automatically creates a key (faster iteration, less control)

### Your first animations

Start with these on your character face:

1. **Blink:** Eyes scale to 0 on Y axis briefly, then back. A 0.2-second blink every few seconds. Teaches: quick keyframing, easing, timing.
2. **Idle breathing:** Subtle scale oscillation on the head/body. Teaches: looping, subtle motion, bezier curves.
3. **Look around:** Eyes and head shift position slightly. Teaches: secondary motion (eyes lead, head follows with delay).

### Animation principles in Rive

Everything from the Spine roadmap's animation principles applies here:
- Ease in/ease out on every key
- Anticipation before big movements
- Follow-through after actions
- Overlapping action (not everything moves at once)
- Arcs (natural motion follows curves)

**Read:**
- Rive Animating: https://help.rive.app/editor/animate-mode
- Rive Graph Editor: https://help.rive.app/editor/animate-mode/graph-editor
- Rive Interpolation: https://help.rive.app/editor/animate-mode/interpolation

**Exercise:** Create three animations for your character: blink, idle, and a reaction (surprise, smile, or frown). Each should loop cleanly. Pay attention to easing — no linear interpolation allowed. Everything should ease in and out.

**Time:** 3–5 hours

---

## Module 4: The State Machine (Rive's Superpower)

**Goal:** Wire your animations together with interactive logic — no code required.

This is what makes Rive unique. In Spine or traditional animation, you create animations and then write code to manage transitions between them. In Rive, you build that logic visually in the State Machine editor.

### Core concepts

- **States:** Each state plays an animation (or blend tree). "Idle", "Walking", "Jumping" are states.
- **Transitions:** Arrows connecting states. Define when/how to move from one state to another.
- **Conditions:** Rules on transitions. "When `isHovering` becomes true, transition from Idle to Hover."
- **Inputs:** Variables that your code (or user interaction) can set:
  - **Boolean:** true/false (e.g., `isPressed`, `isHappy`)
  - **Number:** numeric value (e.g., `health`, `speed`)
  - **Trigger:** A one-shot event (e.g., `onClick`, `onDamage`)
- **Layers:** Run multiple state machines simultaneously (body animation layer + facial expression layer + effects layer).
- **Blend states:** Mix between animations based on a numeric input (e.g., `speed` from 0–1 blends between idle and walk).

### How it works in practice

1. Switch to State Machine mode
2. Create inputs (e.g., a boolean called `isHovering` and a trigger called `onClick`)
3. Add states that reference your animations
4. Draw transitions between states
5. Set conditions on transitions (e.g., "transition from Idle to Hover when `isHovering` == true")
6. Test directly in the editor by toggling inputs

### Why this matters for game dev

In traditional game development, you write code like:

```
if player.isWalking then
    playAnimation("walk")
elseif player.isJumping then
    playAnimation("jump")
else
    playAnimation("idle")
end
```

With Rive, this logic lives in the .riv file. Your code just sets inputs:

```
riveInstance.setBool("isWalking", true)
riveInstance.setNumber("speed", 0.7)
riveInstance.fire("onJump")
```

The state machine handles the rest — including transition timing, blending, and edge cases. Designers can tweak the logic without touching code.

**Read:**
- Rive State Machine: https://help.rive.app/editor/state-machine
- Rive Inputs: https://help.rive.app/editor/state-machine/inputs
- Rive Transitions: https://help.rive.app/editor/state-machine/transitions
- Rive Layers: https://help.rive.app/editor/state-machine/layers

**Exercise:** Build a state machine for your character with these states: Idle (loops), Blink (plays periodically), and a Reaction (triggered by a click). Add a boolean input `isHovering` and a trigger `onClick`. When hovering, the eyes should follow (or some subtle change). When clicked, play the reaction animation then return to idle. Test it all in the editor.

**Time:** 3–5 hours

---

## Module 5: Listeners & Interactivity

**Goal:** Make your animations respond to direct user input — hovers, clicks, and cursor tracking.

Rive's listeners allow your state machine to respond to user interactions without writing any code. This is incredibly powerful for game UI.

### Listener types

- **Pointer enter / exit:** Detect hover on specific shapes (great for buttons, interactive elements)
- **Pointer down / up:** Detect clicks/taps
- **Pointer move:** Track cursor position (for look-at effects, parallax, etc.)

### What listeners can do

- Set inputs (toggle a boolean, fire a trigger, set a number)
- Target specific shapes (only react when hovering *this* button, not the whole artboard)
- Chain with the state machine (listener sets input → input triggers transition → new animation plays)

### Cursor tracking

One of Rive's most impressive capabilities: you can bind object transforms to cursor position. A character's eyes can follow the mouse. A light source can track cursor movement. A parallax background can shift based on pointer position. All without code.

**Read:**
- Rive Listeners: https://help.rive.app/editor/state-machine/listeners
- Rive Data Binding: https://help.rive.app/editor/data-binding (newer feature for dynamic data)

**Exercise:** Add cursor tracking to your character's eyes — they should follow the mouse position. Add a hover effect to the character (subtle glow, scale change, or expression change). Add a click reaction. All of this should work in the editor preview without any code.

**Time:** 2–4 hours

---

## Module 6: Advanced Animation Techniques

**Goal:** Level up from basic keyframes to polished, professional animation.

### Trim paths

Animate the stroke of a path drawing itself on or off. Use cases: loading indicators, handwriting effects, progress bars, reveal animations.

### Solo / visibility animation

Toggle which objects are visible over time. Use cases: sprite-sheet-style frame animation within a Rive file, showing/hiding UI elements, outfit changes.

### Nested artboards

Embed one artboard inside another. The inner artboard runs its own animations and state machine independently. Use cases: a character artboard nested inside a scene artboard, reusable animated components (a button component used in multiple screens).

### Blend states (1D and 2D)

Instead of hard-switching between animations, blend between them based on a numeric value:
- **1D blend:** A single number controls the mix. `speed` = 0 plays idle, `speed` = 0.5 plays walk, `speed` = 1 plays run, with smooth interpolation between.
- **Additive blending:** Layer an animation on top of another (e.g., add a "leaning" animation on top of the walk cycle).

### Joystick input

Rive supports 2D input mapping — a virtual joystick can control blend states in two dimensions simultaneously. A character can look left/right and up/down based on cursor position, blending between four directional poses.

**Read:**
- Rive Trim Paths: https://help.rive.app/editor/fundamentals/trim-paths
- Rive Nested Artboards: https://help.rive.app/editor/nested-artboards
- Rive Blend States: https://help.rive.app/editor/state-machine/blend-states
- Rive Joystick: https://help.rive.app/editor/state-machine/joystick

**Exercise:** Create a character with a 1D blend state between idle and an excited pose, controlled by a number input. Then add a nested artboard — maybe a speech bubble that has its own internal animation. Wire the speech bubble to appear when the character is clicked.

**Time:** 3–5 hours

---

## Module 7: Data Binding & Dynamic Content

**Goal:** Connect your animations to live data — text, colors, images that change at runtime.

Data binding is one of Rive's newer and most powerful features. It lets you create animations where the content is dynamic — defined at runtime, not baked into the file.

### What you can bind

- **Text:** Display player names, scores, messages — all styled and animated
- **Colors:** Theme your animations dynamically (dark mode, team colors)
- **Images:** Swap character portraits, item icons, profile pictures at runtime
- **Numbers:** Health bars, progress indicators, stat displays

### Why this matters for games

Imagine a health bar that:
- Fills/depletes based on a bound number
- Changes color from green → yellow → red as health drops
- Shakes when damage is taken (state machine triggered by a "damage" event)
- All defined in Rive with no game code needed for the visual behavior

Or a dialogue box where:
- The text content is set from your game
- The box animates in/out via state machine
- Character portraits swap based on who's speaking
- Expression changes based on the dialogue's mood

**Read:**
- Rive Data Binding: https://help.rive.app/editor/data-binding

**Exercise:** Create an animated score display: a number that counts up with a satisfying animation, changes color at thresholds, and has a celebration effect when hitting certain milestones. All controlled by a single number input.

**Time:** 2–4 hours

---

## Module 8: Exporting & Runtime Integration

**Goal:** Get your Rive animations into actual apps and games.

### Export

Rive exports a single `.riv` file — a compact binary that contains all your artwork, animations, and state machine logic. No separate atlas files, no JSON, no image folders. One file.

**Note:** As of 2025, exporting requires a paid plan (Cadet at $9/month annually). The free tier lets you design and animate without limits, but you need a subscription to export .riv files for production use.

### Official runtimes

Rive has runtimes for:
- **Web** (JS/WASM) — most mature, excellent performance
- **Flutter** — first-class support, used by Duolingo
- **iOS** (Swift/SwiftUI)
- **Android** (Kotlin)
- **Unity** — official runtime for game dev
- **Unreal Engine** — official plugin
- **C++** — low-level runtime for custom engines
- **React / React Native**
- **Framer**

### The LÖVE situation (honest assessment)

There is **no official or community LÖVE/Lua runtime for Rive.** Your options:

1. **Use Rive for UI + Spine for characters in LÖVE** — The pragmatic split. Render Rive UI elements as sprite sheets exported from Rive, use Spine for in-game character animation with its native LÖVE runtime.

2. **Use Rive's C++ runtime via LuaJIT FFI** — Technically possible but a significant engineering effort. You'd be writing C bindings and rendering integration yourself. Not recommended for a first project.

3. **Use Rive in a supported engine** — If you move to Unity, Unreal, or a web framework, Rive integrates beautifully. The web runtime in particular is excellent for browser-based games.

4. **Export sprite sheets** — Design and animate in Rive, export as image sequences/sprite sheets, load those in LÖVE as traditional frame-based animation. You lose the state machine interactivity but keep the design workflow.

### Runtime basics (for supported platforms)

The pattern is the same across all runtimes:

```
// Pseudocode — applies to any Rive runtime
file = loadRiveFile("character.riv")
artboard = file.artboard("MainCharacter")
stateMachine = artboard.stateMachine("GameLogic")

// Get input references
healthInput = stateMachine.getNumber("health")
isWalkingInput = stateMachine.getBool("isWalking")
damageInput = stateMachine.getTrigger("onDamage")

// In your game loop:
healthInput.setValue(player.health)
isWalkingInput.setValue(player.velocity > 0)
if (player.tookDamage) damageInput.fire()

stateMachine.advance(deltaTime)
renderer.draw(artboard)
```

**Read:**
- Rive Runtimes overview: https://help.rive.app/runtimes/overview
- Rive Web runtime: https://help.rive.app/runtimes/overview/web-js
- Rive Unity runtime: https://help.rive.app/game-runtimes/unity
- Rive C++ runtime: https://help.rive.app/runtimes/overview/cpp

**Exercise:** Pick the platform most relevant to you. If you're web-curious, build a simple HTML page that loads a .riv file and responds to mouse input. If you're Unity-curious, create a minimal Unity project. The goal is to see your Rive animation running outside the editor for the first time.

**Time:** 3–5 hours

---

## Module 9: Game-Specific Applications

**Goal:** Apply Rive to common game UI patterns.

Even if Rive isn't your primary character animation tool, it excels at game UI. Here are concrete applications:

### Animated menus & buttons

- Buttons with hover, press, and disabled states — all in one .riv file
- Menu transitions (slide in, fade, scale with spring physics)
- Navigation elements that react to selection

### HUD elements

- Health bars with animated fill, color transitions, and damage shake
- Ammo counters with reload animations
- Minimap frames with animated borders
- Score displays with increment animations

### Loading & transition screens

- Animated loading indicators (far beyond a spinning circle)
- Level transition animations
- Splash screens with interactive elements

### Dialogue systems

- Animated text boxes with character portraits
- Expression changes driven by dialogue mood
- Animated speech indicators
- Choice buttons with hover effects

### In-game notifications

- Achievement popups with animated icons
- Damage numbers with style
- Quest updates with animated flourishes

**Exercise:** Build one complete game UI component as a .riv file. Recommendation: an animated health bar with these states: full (idle pulse), taking damage (shake + deplete), healing (fill + glow), critical (red flash + warning). All driven by a single number input for health percentage and triggers for damage/heal events.

**Time:** 4–6 hours

---

## Module 10: Workflow, Optimization & Production Tips

**Goal:** Ship polished Rive content efficiently.

### Design workflow tips

- **Components & nesting:** Build reusable pieces. A button component can be reused across all your menus. Change it once, it updates everywhere.
- **Artboard organization:** One artboard per interactive element (button, health bar, dialogue box). Nest them together in a parent artboard for the full screen.
- **Naming conventions:** Use consistent prefixes: `btn-`, `icon-`, `fx-` for buttons, icons, effects.
- **State machine hygiene:** Keep state machines focused. One state machine per behavior (locomotion, facial expression, UI state). Use layers for parallel behaviors.

### Performance considerations

- **Vector complexity:** More path points = more rendering work. Simplify paths where possible.
- **Artboard size:** Larger artboards render more pixels. Size artboards to what you need, not bigger.
- **Animation count:** Many simultaneous animations have a CPU cost. Be intentional about what's animating.
- **Runtime file size:** .riv files are very compact (usually <100KB for a character), but complex files with many embedded images can grow. Vector art keeps files small.

### Collaboration with developers

Rive's biggest workflow advantage: designers own the state machine logic. Developers need to:
1. Know what inputs exist (names and types)
2. Set those inputs from game code
3. Render the artboard

That's it. All transition timing, animation blending, and visual logic lives in the .riv file. Designers can iterate without code changes.

### Version control

Rive files are binary, so they don't diff well in Git. Rive's cloud editor handles versioning internally (with revision history on paid plans). For team workflows, use Rive's built-in collaboration rather than trying to Git-manage .riv files.

**Time:** Ongoing

---

## Rive vs. Spine: When to Use Which

| Scenario | Use Spine | Use Rive |
|----------|-----------|----------|
| Character walk/run/attack cycles | ✅ | Possible but Spine is better |
| Complex skeletal character with many animations | ✅ | ✅ |
| In-LÖVE game character animation | ✅ (official runtime) | ❌ (no runtime) |
| Animated game UI (menus, HUD, buttons) | ❌ | ✅ |
| Interactive elements that respond to hover/click | ❌ | ✅ |
| State-driven animation (no code logic needed) | ❌ | ✅ |
| Unity/Unreal game project | Either | ✅ (state machine advantage) |
| Web-based game | ❌ | ✅ |
| Data-bound dynamic content | ❌ | ✅ |

**The pragmatic approach for your journey:** Learn both. Use Spine for LÖVE character animation (it integrates natively). Learn Rive for UI/interactive work and for when you eventually move to Unity/Unreal/web. The animation fundamentals (bones, keyframes, easing, weight painting) transfer directly between them.

---

## Essential Bookmarks

| Resource | URL | Notes |
|----------|-----|-------|
| Rive Editor | https://rive.app | Browser-based, free to use |
| Rive Help Center | https://help.rive.app | Primary documentation — text-based |
| Rive Community | https://rive.app/community | Browseable example files |
| Rive Runtimes (GitHub) | https://github.com/rive-app | Open-source runtime code |
| Rive Blog | https://rive.app/blog | Feature announcements, tutorials |
| Rive Unity Docs | https://help.rive.app/game-runtimes/unity | Unity-specific integration |
| 12 Principles of Animation | https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation | Universal animation foundation |

---

## Suggested Practice Progression

| # | Project | What you learn |
|---|---------|---------------|
| 1 | Animated toggle switch | Basic shapes, keyframes, state machine with boolean input |
| 2 | Interactive button (hover/press/disabled) | Listeners, transitions, multiple states |
| 3 | Character face with eye tracking | Bones, constraints, cursor tracking, blend states |
| 4 | Animated health bar | Data binding, number inputs, color transitions, triggers |
| 5 | Loading spinner | Trim paths, looping, easing |
| 6 | Full character with walk/idle/jump | Skeletal rigging, meshes, weights, 1D blend state |
| 7 | Dialogue box system | Nested artboards, text binding, state machine layers |
| 8 | Complete game menu screen | Composition of all skills, nested components |
| 9 | Export and integrate into a real project | Runtime setup, input wiring, rendering |

---

## ADHD-Friendly Tips (Rive Edition)

- **Rive runs in the browser.** No install friction. Open a tab, start creating. Close the tab when you need a break. Your work saves automatically.
- **The community files are gold.** When you're not in the mood to create, open community files and study them. Reverse-engineering someone else's state machine is incredibly educational.
- **State machines are visual puzzles.** If you like flowcharts, graph-thinking, or systems design, state machines will click with your brain. They're game design logic in visual form.
- **Start with UI, not characters.** A toggle switch or animated button takes 30 minutes and gives you a complete, satisfying result. A full character rig takes hours before it looks good. Get the quick wins first.
- **Design and animation in one tool.** No context-switching between Photoshop and your animation tool. When inspiration strikes for a new look, just draw it. The creative loop stays tight.
- **Free tier has no time limit.** Learn at your own pace. You only pay when you're ready to ship.
