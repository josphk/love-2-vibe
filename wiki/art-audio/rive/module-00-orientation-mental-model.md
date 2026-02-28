# Module 0: Orientation & The Rive Mental Model

**Part of:** [Rive Learning Roadmap](rive-learning-roadmap.md)
**Estimated study time:** 3–5 hours
**Prerequisites:** None — but experience with any animation tool (Spine, After Effects, CSS animations) gives you useful reference points

---

## Overview

Most animation tools answer the question: "How do I make something move?" Rive answers a different question: **"How do I make something that reacts?"**

This distinction is the single most important thing to understand before you touch the editor. If you approach Rive as "another animation tool," you'll learn the timeline, create some keyframe animations, export them, and wonder why people make such a fuss about it. You'll have missed the point entirely. Rive is an **interactive design platform** — a tool for creating animations that respond to inputs, change based on conditions, and manage their own logic through visual state machines. The animation part is table stakes. The interactivity is why Rive exists.

This module builds your mental model of what Rive is, how it thinks, and why it's structured the way it is. You'll learn the three pillars (Design, Animate, State Machine), get oriented in the editor, and — critically — understand how Rive compares to Spine so you can make intelligent decisions about when to use each tool. By the end, you should be able to open any Rive community file and understand its architecture without needing to read a tutorial.

If you're coming from Spine, the comparison section later in this module will save you hours of confusion. Read it carefully.

---

## Core Concepts

### 1. Rive Is Not an Animation Tool — It's an Interactive Design Platform

**The key word is "interactive."** Traditional animation tools — After Effects, Spine, CSS @keyframes, even Flash — create **linear timelines**. You define what happens at frame 1 and frame 60, and the tool interpolates between them. The animation plays from A to B. Maybe it loops. Maybe you trigger different clips from code. But fundamentally, the animation is a passive recording that plays back the same way every time.

Rive creates **state-driven, input-responsive animation**. An animation in Rive doesn't just play — it *reacts*. Hover over it and it looks at your cursor. Click it and it plays a response. Change a variable and its expression shifts. Feed it a number and it blends between poses proportionally. This isn't accomplished by writing code to swap between animation clips — the reactive logic is built into the Rive file itself, as a visual state machine that the designer creates alongside the artwork and animations.

**Think of it this way:**
- **Traditional animation** is a movie. It plays the same way every time. The viewer is passive.
- **Rive animation** is a puppet that reacts. The user is an active participant. The animation's behavior depends on what the user does.

This is why companies like Duolingo, Spotify, Google, and Figma use Rive. Their animations aren't decorative — they're functional UI elements that respond to user behavior in real time. Duolingo's owl doesn't just play a canned celebration when you get an answer right. It reacts differently based on streaks, timing, answer correctness, and other variables — all managed by a Rive state machine, not application code.

**Why this matters for you:** If you approach Rive thinking "I'll just make some animations and export them," you're using maybe 30% of the tool. The remaining 70% — state machines, inputs, listeners, data binding — is what makes Rive worth learning at all. Everything in this roadmap builds toward that interactivity.

**Common mistake:** Creating animations in Rive and then writing state management code in your application to switch between them. That's the Spine workflow. In Rive, you build the switching logic *inside the .riv file*. Your application code just sets inputs ("health = 45", "isHovering = true") and the state machine handles everything else.

**Try this now:** Go to [rive.app/community](https://rive.app/community) and open any featured file. Click on it, hover over it, drag things around. Notice how it responds to your input. Then open it in the editor and look at the State Machine tab. You'll see a visual graph of states and transitions — that's the logic that drives the interactivity. You don't need to understand it yet. Just see that it exists.

---

### 2. The Three Pillars of Rive

Rive is organized around three modes that correspond to three stages of creating interactive content. Understanding these pillars — and the order in which you use them — is fundamental to working effectively.

**Pillar 1: Design**
Rive has a full vector drawing toolkit built into the editor. You can create artwork directly in Rive using pen tools, shape primitives, boolean operations, gradients, and more. This is a major difference from Spine, which requires you to import pre-made raster images from Photoshop or similar tools.

The design pillar means you can go from blank canvas to finished interactive animation without leaving Rive. No round-tripping between Illustrator and your animation tool. No re-importing when you change a character's proportions. The creative loop stays tight — when inspiration strikes, you draw it right there.

You *can* also import SVGs and raster images into Rive, so you're not forced to design inside the tool. But the built-in tools are good enough for most game UI work, and designing in-tool means your artwork is natively vector (resolution-independent, small file size, and every point is animatable).

**Pillar 2: Animate**
Timeline-based keyframe animation, similar to any animation tool you've used. You pose your artwork, set keyframes, advance time, pose again, and Rive interpolates between them. You get easing curves (cubic bezier), a graph editor, multiple named animation clips per artboard, and all the standard features.

If you've used Spine, this is familiar territory. The concepts transfer directly: bones, keyframes, interpolation, easing, looping, mixing. The timeline is not where Rive differentiates itself — it's competent but not revolutionary. The timeline exists to create the raw material (animation clips) that the state machine will orchestrate.

**Pillar 3: State Machine**
This is Rive's killer differentiator. The state machine is a visual node graph where you:
- Define **states** (each state plays an animation or blend of animations)
- Draw **transitions** between states (arrows from one state to another)
- Set **conditions** on transitions ("transition when `isHovering` becomes true")
- Create **inputs** (booleans, numbers, triggers) that your code — or user interaction — can set

The result is a self-contained interactive system. A Rive file doesn't just contain artwork and animations — it contains the *logic* that determines which animation plays when, how transitions blend, and how the whole thing responds to external input. The developer's job is reduced to: load the file, set inputs, render.

**Why the order matters:** You Design first (create the visual elements), Animate second (create the motion), and wire the State Machine last (create the interactive logic). Each pillar builds on the previous one. Trying to build a state machine before you have animations to put in it is backwards. Trying to animate before you have artwork is impossible.

**Common mistake:** Spending too long in Design mode perfecting artwork before testing any animation. Rive's design tools are good, but animation often reveals that your artwork needs restructuring (shapes need to be separate, groups need different hierarchy, bones need different anchor points). Get a rough design working in animation *first*, then polish the artwork.

**Try this now:** Open the Rive editor ([rive.app](https://rive.app)). Notice the mode switcher at the top. Click between Design, Animate, and State Machine modes. Each mode changes the available tools and panels. Get comfortable switching between them — you'll do it constantly.

---

### 3. The Rive Editor Interface

The editor runs entirely in your browser. No installation, no updates, no license files. Open a tab, start creating. Your work saves automatically to Rive's cloud. This is both a strength (zero friction, instant collaboration, access from any machine) and a consideration (requires internet, your files live on Rive's servers).

**The workspace is divided into five areas:**

**Stage (center):** Your canvas. This is where you see your artwork and interact with it. In Design mode, you draw here. In Animate mode, you pose here. In State Machine mode, you preview here. The stage shows one artboard at a time.

**Hierarchy (left panel):** A tree view of every object in your artboard — shapes, groups, bones, images, nested artboards, everything. This is your structural overview. Objects higher in the hierarchy render on top (like layers). You'll use this constantly to select, reorder, rename, and organize.

**Inspector (right panel):** Properties of whatever's currently selected. Position, rotation, scale, opacity, fill color, stroke width, constraint settings — it all lives here. The inspector changes based on what you've selected and which mode you're in.

**Timeline (bottom panel, Animate mode):** Keyframes and animation curves. This is where you create and edit animations. Each animation is a named sequence with its own timeline. You can have dozens of animations per artboard.

**State Machine Graph (bottom panel, State Machine mode):** The visual logic editor. States are boxes, transitions are arrows, and conditions are labels on those arrows. This replaces the timeline panel when you switch to State Machine mode.

**Keyboard shortcuts worth learning immediately:**
- `V` — Select tool
- `P` — Pen tool
- `B` — Bone tool
- `R` — Rectangle
- `E` — Ellipse
- `Space + drag` — Pan the canvas
- `Scroll` — Zoom
- `Ctrl/Cmd + Z` — Undo (you'll use this a lot)
- `Ctrl/Cmd + D` — Duplicate selection

**Common mistake:** Not using the Hierarchy panel enough. When your artwork gets complex, clicking on the stage to select objects becomes unreliable (you click the wrong thing, or you can't reach objects that are behind other objects). The hierarchy panel gives you direct, unambiguous access to any object. Use it.

**Try this now:** Create a new file in Rive. Draw a simple rectangle. Select it in the hierarchy. Look at its properties in the inspector. Switch to Animate mode and notice how the bottom panel changes to a timeline. Switch to State Machine mode and notice the graph editor. Switch back to Design mode. Do this mode-switching five times until it's muscle memory.

---

### 4. Artboards: Rive's Unit of Organization

An artboard in Rive is a self-contained canvas — think of it as a screen, a component, or an independent scene. A single Rive file can contain multiple artboards, and each artboard has its own:
- Artwork (shapes, images, bones)
- Animations (named timeline clips)
- State machine(s) (interactive logic)

**Why artboards matter:** They're your primary organizational unit. Good artboard design leads to reusable, modular interactive content. Poor artboard design leads to monolithic files that are hard to maintain.

**How to think about artboards:**
- **One artboard = one interactive element.** A button is one artboard. A health bar is one artboard. A character is one artboard. A menu screen is one artboard that *nests* the button and other element artboards inside it.
- **Artboards are like components in UI frameworks.** If you know React, think of artboards as components. Each one is self-contained, has its own state (inputs), and can be composed into larger structures through nesting.
- **Size your artboards intentionally.** The artboard size defines the coordinate space and the rendering bounds. A button artboard should be button-sized, not full-screen. A character artboard should be character-sized.

**Nesting artboards** is how you build complex scenes from simple pieces. A menu screen artboard might contain three nested button artboards and a nested logo artboard. Each nested artboard runs its own state machine independently — the button handles its own hover/press states, the logo handles its own idle animation. The parent artboard orchestrates them.

**Common mistake:** Putting everything in one artboard. If your entire game UI is one giant artboard with all buttons, health bars, and text elements on it, you've created a monolith. Changes to one element risk breaking others. Separate concerns into individual artboards and compose them through nesting.

**Try this now:** In a new Rive file, create three artboards side by side: one small (100x50, for a button), one medium (200x30, for a health bar), and one large (800x600, for a screen layout). Notice how each has its own independent space. Later you'll learn to nest the small ones inside the large one.

---

### 5. The Mental Model: Designer Owns the Logic

This concept is arguably the most important in the entire roadmap, and it's the hardest to internalize if you're used to traditional game development.

**In traditional game development,** the workflow looks like this:
1. Artist creates artwork
2. Animator creates animation clips
3. Programmer writes code to manage which animation plays when, how they transition, what inputs trigger what

The programmer owns the interactive logic. If the designer wants to change how a button animates when hovered, they need a code change. If the animator wants to adjust transition timing between walk and run, they need a code change. Every behavioral tweak flows through the programmer.

**In the Rive workflow,** it looks like this:
1. Designer creates artwork, animations, AND the state machine logic — all inside Rive
2. Programmer loads the .riv file, sets inputs from game code, and renders

The designer owns the logic. If they want to change how a button responds to hover, they open the Rive file and adjust the state machine. No code change needed. If they want different transition timing, they tweak the transition duration in the state machine graph. The programmer's code doesn't change because it only sets inputs — it doesn't manage states or transitions.

**What the programmer's code looks like:**

```
-- Pseudocode for ANY Rive runtime
file = loadRiveFile("menu-button.riv")
artboard = file.artboard("Button")
stateMachine = artboard.stateMachine("ButtonLogic")

-- Get input references
isHovering = stateMachine.getBool("isHovering")
isPressed = stateMachine.getBool("isPressed")
isDisabled = stateMachine.getBool("isDisabled")

-- In the game loop, just set inputs:
isHovering.setValue(mouseOverButton)
isPressed.setValue(mouseDown)
isDisabled.setValue(not canAffordItem)

-- Advance and render — the state machine handles everything else
stateMachine.advance(dt)
renderer.draw(artboard)
```

That's it. The programmer never writes "if hovering, play hover animation." The state machine inside the .riv file handles all of that. The programmer just feeds it the raw facts ("is the mouse over this button? yes/no") and the Rive file does the rest.

**Why this matters:** This separation of concerns is powerful. Designers iterate faster because they don't need code changes. Programmers write less animation management code. The .riv file becomes a single source of truth for both visuals *and* behavior. And if you're a solo developer, you still benefit — you do your visual thinking in the visual tool (Rive's state machine editor) and your logical thinking in code, rather than mixing both in code.

**Common mistake:** Recreating state machine logic in application code. If you find yourself writing `if/else` chains to manage which Rive animation plays when, you're doing Spine-style integration with a Rive file. Stop and move that logic into the Rive state machine where it belongs.

---

### 6. Rive vs. Spine: An Honest Comparison

If you're reading this roadmap, you're probably also learning (or considering) Spine. Both tools handle skeletal animation. Both use bones, keyframes, meshes, and weights. But they solve different problems and excel in different contexts. Understanding the differences now saves you from learning the wrong tool for the wrong job.

**The Core Difference**

Spine is a **specialized skeletal animation tool for games.** It does one thing — 2D character animation — and does it extraordinarily well. It's been the industry standard for 2D game character animation for over a decade. It has deep, mature tooling for mesh deformation, IK, path constraints, and complex skeletal rigs. Its runtimes are battle-tested across thousands of shipped games. It exports to a well-documented JSON/binary format with official runtimes for virtually every game engine and framework, including LÖVE.

Rive is a **general-purpose interactive design platform.** It handles character animation, but also UI animation, interactive graphics, data-bound displays, and anything else that needs to respond to input. It's younger than Spine, less specialized for character work, but far more capable for interactive and state-driven content. Its state machine is something Spine simply doesn't have — in Spine, you manage animation state in code.

**Head-to-Head Comparison**

| Aspect | Spine | Rive |
|--------|-------|------|
| **Primary purpose** | Skeletal character animation for games | Interactive, state-driven animation for apps, UI, and games |
| **Editor** | Desktop app (Java-based, offline) | Browser-based (cloud, no install) |
| **Vector drawing** | No — import raster images only | Yes — full vector design toolkit built in |
| **State machines** | No — you build state logic in your game code | Yes — visual state machine in the editor |
| **Data binding** | No | Yes — text, colors, images, numbers |
| **Listeners/interactivity** | No — all interaction handled in code | Yes — hover, click, cursor tracking built in |
| **Mesh deformation** | Deep, mature, excellent | Capable but less sophisticated |
| **IK constraints** | Extensive (IK, path, transform, physics) | Present but simpler |
| **LÖVE/Lua runtime** | Official runtime, well-maintained | No runtime — C++ runtime exists but no Lua binding |
| **Unity runtime** | Official, excellent | Official, good |
| **Unreal runtime** | Official | Official |
| **Web runtime** | Community, varies in quality | Official, excellent (WASM-based) |
| **File format** | JSON (readable, diffable) + binary | Binary only (.riv) |
| **Pricing** | $69–$379 one-time | Free editor, paid export ($9/month) |
| **Maturity** | 10+ years, thousands of shipped games | Younger, rapidly evolving, growing adoption |

**The LÖVE Integration Reality**

This deserves its own callout because it's a dealbreaker for a common use case.

Spine has an **official LÖVE/Lua runtime** maintained by the Spine team. You load a Spine file, create an animation state, and render it — it works. Character animation in LÖVE with Spine is a solved problem.

Rive has **no LÖVE/Lua runtime.** Period. Rive has a C++ runtime that you could *theoretically* bind to LÖVE via LuaJIT FFI, but:
- It's a significant engineering effort (compiling the C++ runtime, writing C bindings, managing memory)
- It's undocumented for this use case
- Nobody in the community has published a working LÖVE integration
- You'd be maintaining this binding yourself

**If you're building a game in LÖVE and need character animation, use Spine.** This is not a close call.

**Where Rive wins:**
- Anything with a visual state machine (interactive UI, buttons, menus)
- Anything that responds to user input (hover effects, click reactions, cursor tracking)
- Anything with dynamic content (data-bound text, runtime color themes)
- Web-based games and apps (Rive's WASM runtime is excellent)
- Unity and Unreal projects where you want designers to own animation logic
- UI/HUD elements in any engine

**Where Spine wins:**
- Complex skeletal character animation (walk cycles, combat, multi-part characters)
- LÖVE/Lua game projects (native runtime support)
- Projects that need diffable/readable animation data (JSON format)
- Teams with established Spine pipelines
- Maximum control over mesh deformation and weight painting

**The Pragmatic Recommendation**

Learn both. They're complementary, not competing. The foundational skills — bones, keyframes, easing, rigging, weight painting — transfer directly between them. Use Spine for character animation in LÖVE. Use Rive for interactive UI work, for web projects, and for any engine that has official Rive runtime support. Your animation instincts don't care which tool you're holding.

---

### 7. Setting Up: Zero Friction

One of Rive's genuine advantages is that setup is instantaneous.

1. **Go to [rive.app](https://rive.app)** and create a free account (email or Google/GitHub sign-in)
2. **That's it.** The editor runs in your browser. No download, no install, no license key, no Java runtime, no system requirements beyond "a modern web browser."
3. **Your files save automatically** to Rive's cloud. You can access them from any machine.
4. **The free tier has no time limit or feature restrictions for design and animation.** You only need a paid plan ($9/month on annual billing) when you want to export .riv files for production use.

**Worth doing now:**
- Open the [Rive Community](https://rive.app/community) page and browse. Sort by "Most popular" or "Editor's picks."
- Open 3–5 community files in the editor. For each one:
  1. Click/hover/interact with it in the preview. What responds?
  2. Switch to the State Machine tab. How many states? How many inputs?
  3. Switch to Animate mode. How many animation clips exist?
  4. Switch to Design mode. How is the hierarchy organized?
- Don't try to understand everything. Just observe the structure. You're building pattern recognition.

**Common mistake:** Trying to build something on day one. Resist the urge. Spend your first session *only* exploring community files. You'll learn more about how Rive works by reverse-engineering three community files than by following a "draw a circle" tutorial.

---

## Case Studies: How Real Products Use Rive

### Case Study 1: Duolingo's Animated Characters

Duolingo is Rive's most famous customer. Their owl mascot and lesson characters are Rive animations — not pre-rendered GIFs or Lottie files. Here's why that matters:

**The problem:** Duolingo needs characters that react to user behavior in real time. When you answer correctly, the owl celebrates. When you answer wrong, it looks disappointed. When you're on a streak, it gets excited. These aren't three separate animations triggered by `if/else` code — the owl's state machine blends between many emotional states based on multiple inputs simultaneously.

**Why Rive:** A traditional approach would require dozens of pre-made animation clips and complex code to manage transitions between them. With Rive, the animation team builds all the reactive logic into the .riv file. The app code just sets inputs: `correctAnswer = true`, `streakCount = 7`, `lessonProgress = 0.6`. The state machine handles everything — which expression to show, how to transition between emotions, how to blend the streak excitement on top of the base reaction.

**What to learn from this:** Rive excels when a single animated element needs to respond to multiple, simultaneous, continuously-changing inputs. If you can describe your animation's behavior as "when X happens, do Y, but also consider Z and W" — that's a Rive problem.

### Case Study 2: Interactive UI Elements

Consider a "like" button — something every social app has. The traditional implementation:

1. Artist creates a heart icon in three states (empty, filling animation, filled)
2. Developer writes code: on click, play the filling animation, then show the filled state. On un-click, reverse it.
3. Designer wants to add a hover glow effect. Developer adds more code.
4. Designer wants the heart to "bounce" on the fill. Developer modifies animation triggering code.
5. Every visual change requires a code change and a new deploy.

The Rive implementation:

1. Designer creates the heart icon, all animations (fill, unfill, hover glow, bounce), and the state machine in one .riv file
2. Developer writes: `isLiked.setValue(userClickedLike)` and `isHovering.setValue(mouseOver)`
3. Designer iterates on timing, bounce intensity, glow color — all inside Rive, no code changes
4. Updated .riv file is deployed without code changes

This workflow advantage compounds. One button is a small win. A full UI with 30 interactive elements, each with hover/press/disabled/loading states? The code savings and iteration speed are massive.

### Case Study 3: Game Health Bar (Your Future Exercise)

Imagine a health bar built in Rive:

**Inputs:**
- `healthPercent` (number, 0–100)
- `onDamage` (trigger)
- `onHeal` (trigger)
- `isCritical` (boolean, derived from healthPercent < 20)

**States:**
- **Healthy:** Bar is green, subtle pulse animation
- **Damaged:** Bar turns yellow/orange, brief shake on `onDamage` trigger
- **Critical:** Bar turns red, urgent flashing, warning icon appears
- **Healing:** Brief green glow on `onHeal` trigger, bar fills up

**Transitions:**
- Healthy → Damaged: when `healthPercent` drops below 60
- Damaged → Critical: when `healthPercent` drops below 20
- Any → Healing: when `onHeal` fires (plays healing effect, returns to appropriate state based on `healthPercent`)
- Damage shake: plays on any `onDamage` trigger regardless of current state (this uses a separate state machine layer)

The game code just sets `healthPercent` and fires triggers. All the visual complexity — color transitions, shake intensity, glow effects, threshold-based state changes — lives in the .riv file. The designer owns it. The programmer never has to think about what shade of red the health bar should be at 15% health.

---

## Common Pitfalls

1. **Treating Rive as "just an animation tool."** If you're only using the timeline and ignoring the state machine, you're missing the point. The state machine is what makes Rive worth learning. Force yourself to build state machines even for simple projects.

2. **Recreating state machine logic in code.** If your application code has `if/else` chains deciding which Rive animation to play, you've bypassed Rive's core value. Move that logic into the Rive state machine. Your code should only set inputs.

3. **Designing everything in one artboard.** Each interactive element should be its own artboard. Compose them through nesting. Monolithic artboards are hard to maintain and impossible to reuse.

4. **Not naming your objects.** `Path 47`, `Ellipse 12`, `Group 3` are meaningless when you have 50 objects. Name everything: `eye-left`, `mouth-smile`, `bg-gradient`. You'll thank yourself when building the skeleton and state machine.

5. **Starting with a complex project.** Your first Rive project should be a toggle switch or a simple button — something you can finish in 30 minutes. The dopamine hit of a complete, interactive result motivates you to tackle bigger projects. Starting with a full character rig leads to hours of work before anything feels "done."

6. **Ignoring the Community files.** The [Rive Community](https://rive.app/community) is the single best learning resource. Every file can be opened in the editor and fully inspected — artwork, animations, state machines, everything. Reverse-engineering community files teaches you patterns you'd never discover on your own.

7. **Trying to use Rive in LÖVE.** There's no runtime. If you need animation in LÖVE, use Spine. Use Rive for web, Unity, Unreal, Flutter, or native mobile — platforms with official runtime support.

---

## Exercises

### Exercise 1: Community File Autopsy (Beginner)

Open three different community files from [rive.app/community](https://rive.app/community). For each file, document:

1. **What interactions does it support?** (hover, click, drag, cursor tracking, etc.)
2. **How many artboards does it have?** Are any nested?
3. **How many animations exist?** List their names.
4. **How many state machine inputs exist?** List their names and types (boolean, number, trigger).
5. **How is the hierarchy organized?** What naming conventions does the creator use?

Write your observations in a text file. The goal is pattern recognition — after three files, you should start seeing common structures.

### Exercise 2: Editor Navigation Drill (Beginner)

Create a new file and practice mode-switching. Do the following sequence three times, timing yourself:

1. Design mode → draw a rectangle → name it "box"
2. Animate mode → create an animation called "pulse" → add a scale keyframe
3. State Machine mode → create a state that uses the "pulse" animation
4. Design mode → select "box" in the hierarchy → change its fill color
5. Animate mode → select the "pulse" animation → add another keyframe

This drill builds the muscle memory of switching between modes. You should feel comfortable navigating after three rounds.

### Exercise 3: Mental Model Quiz (Intermediate)

Answer these questions without looking back at the module. Then check your answers:

1. What are Rive's three pillars, and in what order do you use them?
2. What is the fundamental difference between Rive and traditional animation tools?
3. In the Rive workflow, who owns the animation logic — the designer or the programmer?
4. What does the programmer's code do in a Rive integration? What does it NOT do?
5. Name two scenarios where Spine is the better choice than Rive.
6. Name two scenarios where Rive is the better choice than Spine.
7. Why should each interactive element be its own artboard?

### Exercise 4: Rive vs. Spine Decision Matrix (Intermediate)

For each of the following scenarios, decide whether you'd use Spine, Rive, or both. Justify your choice in one sentence:

1. A character walk cycle for a LÖVE game
2. An animated main menu for a Unity game
3. A health bar with dynamic fill, color changes, and shake effects
4. A complex boss character with 30+ animation states for an Unreal game
5. An interactive tutorial overlay for a web app
6. A dialogue box with swappable character portraits and expression changes
7. A 2D platformer character for a web-based game (HTML5)

---

## Essential Bookmarks

These are the resources you'll return to throughout the entire roadmap.

| Resource | URL | What It's For |
|----------|-----|---------------|
| **Rive Editor** | [rive.app](https://rive.app) | The editor itself — browser-based, free |
| **Rive Help Center** | [help.rive.app](https://help.rive.app) | Primary text documentation — your main reference |
| **Getting Started** | [help.rive.app/getting-started](https://help.rive.app/getting-started) | Official first-steps guide |
| **Editor Basics** | [help.rive.app/editor/fundamentals](https://help.rive.app/editor/fundamentals) | Core editor concepts |
| **Rive Community** | [rive.app/community](https://rive.app/community) | Browseable example files — open any in the editor |
| **Rive GitHub** | [github.com/rive-app](https://github.com/rive-app) | Open-source runtime code for all platforms |
| **Rive Blog** | [rive.app/blog](https://rive.app/blog) | Feature announcements, case studies, tutorials |
| **12 Principles of Animation** | [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation) | Universal animation foundation — applies to all tools |

**How to use these resources:**
- **Help Center** is your primary reference. It's text-based (not video-heavy), well-organized, and kept up to date. When you encounter a feature you don't understand, check here first.
- **Community files** are your secondary reference. When the docs explain *what* a feature does but you want to see *how* people actually use it, find a community file that demonstrates it.
- **GitHub runtimes** are for when you're ready to integrate Rive into an actual project (Module 8). You won't need these until later.

---

## ADHD-Friendly Tips for Learning Rive

These tips are adapted for Rive specifically. If you have ADHD (or ADHD-like working patterns), these will help you maintain momentum.

**Zero-friction entry.** Rive runs in the browser. No downloads, no installs, no "let me update first" delays. Open a tab, start creating. Close the tab when you need a break. Your work saves automatically. This removes the biggest ADHD barrier: the friction of getting started.

**Community files as passive learning.** When you're not in the mood to create, open community files and study them. It's educational, it's exploratory (your ADHD brain likes novelty), and it doesn't require the executive function of a blank canvas. Reverse-engineering someone else's state machine is half puzzle, half detective work — engaging without being demanding.

**State machines are visual puzzles.** If you think in flowcharts, systems, or "if this then that" logic, Rive's state machines will click with your brain. They're game design logic in visual, manipulable form. Building a state machine feels more like solving a puzzle than doing tedious work.

**Start with UI, not characters.** A toggle switch or animated button takes 30 minutes and gives you a complete, interactive, satisfying result. A full character rig takes hours before it looks "done." ADHD brains need the dopamine hit of completion to maintain motivation. Get quick wins first, then tackle ambitious projects once you've built momentum.

**Everything in one tool.** Rive eliminates the context-switching that kills ADHD productivity. You don't need to open Photoshop to adjust artwork, then switch to your animation tool, then switch to your code editor. Design, animate, and wire the state machine — all in one browser tab. When inspiration for a visual change hits mid-animation, just switch to Design mode. The creative loop stays tight.

**Free tier has no time limit.** There's no subscription ticking, no trial expiring, no pressure to "get your money's worth." Learn at your own pace. You only pay when you're ready to export for production. This removes the guilt of taking breaks.

**The "open three tabs" trick.** Open three community files in three tabs. Whenever your focus drifts from one, switch to another. You're still learning Rive — you're just channel-surfing within the tool. By the time you've cycled through all three, you've internalized three different approaches to interactive animation without forcing sustained attention on any single one.

---

## Recommended Reading & Resources

**Tier 1 — Start Here (do before moving to Module 1):**
- [Rive Getting Started Guide](https://help.rive.app/getting-started) — official walkthrough of the editor
- [Rive Editor Fundamentals](https://help.rive.app/editor/fundamentals) — core concepts in text form
- Browse 5+ community files at [rive.app/community](https://rive.app/community)

**Tier 2 — Deeper Understanding:**
- [Rive Blog](https://rive.app/blog) — read any article about how Rive is used in production
- [12 Principles of Animation (Wikipedia)](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation) — universal animation foundations that apply in every module

**Tier 3 — Context and Comparison:**
- Spine's official documentation — reading Spine's approach helps you appreciate where Rive diverges
- [Lottie vs Rive](https://rive.app/blog/rive-as-a-lottie-alternative) — Rive's own comparison with the other major web animation format

---

## Key Takeaways

1. **Rive is an interactive design platform, not just an animation tool.** The interactivity — state machines, inputs, listeners — is what makes it worth learning. Don't skip these features.

2. **The three pillars are Design, Animate, and State Machine.** Use them in that order. Each builds on the previous one.

3. **The designer owns the logic in Rive.** The state machine lives inside the .riv file. Application code just sets inputs and renders. This is fundamentally different from the Spine/traditional workflow.

4. **Rive and Spine are complementary, not competing.** Use Spine for character animation in LÖVE. Use Rive for interactive UI, web projects, and any platform with official runtime support.

5. **There is no Rive runtime for LÖVE.** Don't plan a project around one. If you're in LÖVE, Spine is your tool.

6. **Artboards are your organizational unit.** One interactive element = one artboard. Compose through nesting.

7. **Community files are your best learning resource.** Open them, inspect them, reverse-engineer them. Learn by studying what others have built.

---

## What's Next

**[Module 1: Vector Design in Rive →](module-01-vector-design.md)**

Now that you understand what Rive is and how it thinks, it's time to create artwork. Module 1 covers Rive's vector design tools — pen paths, shapes, boolean operations, fills, strokes, and the organizational principles that make your artwork animation-ready. You'll build the character face that serves as your test subject for the rest of the roadmap.
