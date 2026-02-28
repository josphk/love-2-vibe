# Module 10: Workflow, Optimization & Production Tips

[← Back to Rive Learning Roadmap](rive-learning-roadmap.md)

**Time Estimate:** Ongoing (reference module — revisit as your projects grow)
**Prerequisites:** All previous modules (this module synthesizes everything)

---

## Overview

This is the "glue" module. You know how to draw vectors, rig bones, animate timelines, build state machines, wire listeners, bind data, and export to runtimes. Now the question is: how do you do all of that *well* across a real project?

Production Rive work introduces problems that don't appear in tutorials: naming 200 layers so you can find them six months later, keeping file sizes small enough for mobile, organizing artboards so designers and developers don't step on each other, version-controlling binary files that don't diff. These are the problems this module addresses.

It also includes a suggested practice progression — a sequence of nine projects that builds from basic to advanced, giving you a roadmap for deliberate skill development.

### Learning Objectives

By the end of this module, you should be able to:

1. Organize Rive files for maintainability across a multi-screen game
2. Apply naming conventions that make collaboration painless
3. Identify and fix performance bottlenecks in Rive content
4. Manage binary .riv files in a team version control workflow
5. Structure the designer-developer handoff for minimal friction
6. Follow a practice progression that builds skills systematically

---

## 1. Design Workflow

### Components & Nesting

The single most impactful workflow decision: **build reusable components from the start.**

A button in your game shouldn't be drawn fresh in every menu screen. It should be a single artboard — `btn-primary` — that gets nested into every screen that needs it. Change the button's hover animation once, and every instance updates.

**Component hierarchy for a typical game UI:**

```
Atomic components (smallest reusable pieces):
  btn-primary        — standard button with hover/press/disabled
  btn-secondary      — alternate style button
  icon-health        — health icon
  icon-ammo          — ammo icon
  text-label         — styled text element

Molecular components (composed from atoms):
  health-bar         — icon + fill bar + text
  ammo-counter       — icon + count display
  menu-item          — button + label + optional icon
  dialogue-portrait  — character art + expression states

Organism components (composed from molecules):
  hud-panel          — health bar + ammo counter + score
  main-menu          — title + menu items + background
  dialogue-box       — portrait + text + choice buttons
  inventory-screen   — grid of item slots + detail panel
```

This mirrors atomic design in web development — and for the same reasons. When you need to change your button style, you change one artboard, not forty.

**Rules for effective nesting:**
- Each nested artboard should be independently testable. Open it in isolation and it should make sense.
- Expose only the inputs the parent needs. A button might have 10 internal states, but the parent menu only needs `isDisabled` and `buttonText`.
- Limit nesting depth to 3 levels. Beyond that, debugging state machines becomes painful (you're tracing inputs through three layers of indirection).
- Name nested instances descriptively: `btn-play`, `btn-options` — not `artboard-1`, `artboard-2`.

### Artboard Organization

**One artboard per interactive element.** This is the most important organizational rule.

Don't put your health bar, ammo counter, and score display in one artboard. Make them separate artboards. The game engine composites them (positions them on screen). This separation means:

- Each element's state machine stays focused and debuggable
- Elements can be updated independently (redesign the health bar without touching the score)
- Different team members can work on different elements simultaneously
- Runtime performance can be profiled per-element

**When to combine artboards:**
- When elements are tightly coupled (a dialogue box with its portrait — they always appear together)
- When the composition itself is animated (a menu entrance that staggers three buttons — the stagger timing is the parent's job)
- When the artboard count would exceed reasonable management (30+ tiny artboards for one screen is probably too many)

**Artboard sizing:**
- Size artboards to their content, not to the screen. A button artboard is button-sized, not 1920×1080.
- The exception is full-screen compositions (main menu, loading screen) which should match your target resolution.
- Document the intended size and scale behavior (fixed size? stretches? anchored to corner?).

### Naming Conventions

Naming seems trivial until you have 50 artboards and 200 layers. Establish conventions early:

**Artboard names (kebab-case with prefix):**
```
btn-primary          — button component
btn-secondary
icon-health          — icon/graphic element
icon-ammo
hud-health-bar       — HUD element
hud-ammo-counter
screen-main-menu     — full-screen composition
screen-loading
dlg-dialogue-box     — dialogue system element
dlg-portrait-hero
fx-damage-numbers    — visual effects
fx-achievement-popup
```

**Layer names within artboards:**
```
bg-base              — background layers
bg-overlay
shape-fill           — primary shapes
shape-border
txt-label            — text elements
txt-value
grp-buttons          — grouped elements
grp-decorations
ctrl-hit-area        — invisible interaction targets
ctrl-listener-zone
```

**State machine names:**
```
sm-interaction       — handles hover/press/click
sm-data-display      — handles data-driven visuals
sm-entrance-exit     — handles show/hide lifecycle
sm-ambient           — handles idle/ambient animations
```

**Input names (camelCase, descriptive):**
```
isHovered            — boolean: cursor is over element
isPressed            — boolean: element is being clicked
isDisabled           — boolean: element is non-interactive
healthPercent        — number: 0-100 health value
selectedIndex        — number: which item is selected
playerName           — text: bound to display
takeDamage           — trigger: fires damage feedback
showElement          — trigger: fires entrance animation
```

The key principle: **names should be self-documenting.** When a developer integrates your .riv file, they should understand what each input does without reading documentation.

### State Machine Hygiene

**One state machine per behavior.** Use layers for parallel behaviors within a single state machine.

Bad:
```
sm-everything
  Layer 1: Entrance/exit, hover states, data display, ambient animation
  (50 states, impossible to debug)
```

Good:
```
sm-button
  Layer 1: Interaction (idle, hover, pressed, disabled)
  Layer 2: Data (text and color driven by inputs)
  Layer 3: Ambient (idle glow animation)
```

Or even:
```
sm-interaction  — handles user input responses
sm-data         — handles data-driven visual changes
```

**When to use multiple state machines vs. layers:**
- Use **layers** when behaviors run simultaneously and don't interfere (a button's hover state + its idle glow)
- Use **separate state machines** when behaviors are conceptually independent and might need to be controlled separately at runtime
- Most elements need only one state machine with 2–3 layers

**Transition cleanup:**
- Delete transitions you created for testing but aren't part of the final design
- Every transition should have an explicit condition — no "I'll add the condition later" orphans
- Test that every state is reachable and every exit path works

---

## 2. Performance Optimization

### Vector Complexity

Every path point costs rendering time. Rive renders vectors in real-time (unlike sprite-based systems where complexity is "baked in"), so vector complexity directly impacts frame rate.

**Measurement:**
- Path point count is the primary metric. Each path in your artboard has a point count visible in the editor.
- As a rough guide: under 500 total path points per artboard is lightweight; 500–2,000 is moderate; 2,000+ should be profiled.

**Reduction strategies:**
- **Simplify paths.** After drawing, select paths and reduce point count. Smooth curves usually need fewer points than you think — a circle needs 4 points, not 12.
- **Remove hidden geometry.** Shapes behind other opaque shapes still render. Delete or hide shapes that are fully occluded.
- **Use fills instead of strokes where possible.** Strokes with varying width, caps, and joins are more expensive than simple fills.
- **Avoid clipping when you can mask.** Clipping complex shapes against complex shapes is expensive. Simple rectangular clips are cheap.

**Specific patterns to watch:**
- Detailed illustrations with hundreds of anchor points — consider simplifying or rasterizing (export as image, import as fill)
- Text with many characters (each character is a set of paths if using embedded fonts)
- Complex gradients on complex shapes

### Artboard Size

Larger artboards render more pixels. A 1920×1080 artboard that only contains a 200×50 button is wasting rendering budget.

**Rules:**
- Size artboards to their content with minimal padding
- For full-screen compositions, match your target resolution — don't use 4K artboard for a 1080p game
- On mobile, consider whether you need @2x or @3x resolution, or if @1x with vector scaling is sufficient (usually it is — that's the point of vectors)

### Animation Count

Every active animation has a CPU cost for the `advance()` step each frame:

- **Idle animations** that loop continuously (ambient glow, breathing) add constant overhead
- **Triggered animations** (damage shake, entrance) only cost during playback
- **Blend states** cost based on how many animations they're blending (a 1D blend with 3 keyframes blends 2 animations at any given time)

**Optimization strategies:**
- Simplify or remove idle animations on elements that are frequently off-screen or not the focus of attention
- For mobile, consider whether you really need that subtle glow pulse on every button
- Group animations that can share timing — rather than 5 independent shimmer animations, use one parent animation that affects all children
- Use Rive events to pause/resume artboard advancing when elements are off-screen

### Runtime File Size

.riv files are binary and generally compact:

| Content Type | Typical Size |
|-------------|-------------|
| Simple icon/button | 5–20 KB |
| Complex character with animations | 30–100 KB |
| Full-screen composition with nesting | 50–200 KB |
| File with embedded raster images | 200 KB–2 MB+ |

**What makes files large:**
- **Embedded raster images** — the dominant factor. A single embedded PNG can dwarf all the vector data. Use vector art wherever possible.
- **Many animations with many keyframes** — more animation data = larger file, but this rarely matters unless you have dozens of complex animations
- **Unused artboards** — if your file has experimental artboards you're not shipping, delete them before export

**Reduction strategies:**
- Replace raster fills with vector approximations where visually acceptable
- Compress embedded images before importing (use WebP or optimized PNG)
- Delete unused artboards, animations, and assets before final export
- On paid plans, Rive's export can strip unused elements — use this feature

### Profiling in Practice

Every Rive runtime has some form of performance measurement:

- **Web:** Browser DevTools performance tab shows Rive's `advance()` and render time per frame
- **Unity:** Unity Profiler shows the Rive rendering cost
- **General:** Measure time spent in `advance()` (state machine logic) vs. `draw()` (rendering). If advance is slow, simplify state machines. If draw is slow, simplify vectors or reduce artboard size.

**Performance budget suggestion:**
- All Rive content combined should take less than 2ms per frame (at 60fps you have 16.6ms total)
- A single complex artboard should take less than 0.5ms to advance and render
- If you're exceeding these, profile individual artboards to find the bottleneck

---

## 3. Collaboration: Designer-Developer Handoff

### The Core Principle

Rive's biggest workflow advantage: **designers own the animation logic.** The state machine, transitions, blending, timing — all of it lives in the .riv file. Developers don't need to write animation code.

**What developers need from designers:**

1. **Input manifest** — a list of every input (name, type, valid range, description):
   ```
   healthPercent  (number, 0–100)    — current health as percentage
   takeDamage     (trigger)          — fire when player takes damage
   isCritical     (boolean)          — true when health < 20%
   ```

2. **Artboard name** — which artboard to instantiate

3. **Expected behavior description** — what the element does in response to inputs, so the developer can verify integration is working

4. **Asset dimensions** — the artboard size, so the developer knows how to position and scale it in the game

That's the complete handoff. Developers write:
```
// Load the .riv file
// Instantiate the artboard by name
// Get references to inputs by name
// In game loop: set input values, call advance(), render
```

### Input Contract

The input manifest is a contract between designer and developer. Treat it like an API:

- **Don't rename inputs after handoff** without communicating the change. The developer's code references inputs by string name — renaming breaks integration silently.
- **Don't change input types.** Switching from a boolean to a trigger changes the developer's calling code.
- **Do version your input contracts.** A simple changelog works:
  ```
  v1.0: healthPercent (number), takeDamage (trigger)
  v1.1: added isCritical (boolean), added heal (trigger)
  v1.2: renamed takeDamage → onDamage (BREAKING)
  ```
- **Do provide default values.** What should each input be when the element first appears? This lets the developer set initial state correctly.

### Iteration Workflow

The power of Rive's model is fast iteration:

1. Designer changes animation timing in Rive editor
2. Designer exports new .riv file
3. Developer drops the new file into the project (replacing the old one)
4. No code changes needed (as long as inputs haven't changed)

This means designers can polish animations without waiting for a code review cycle. The .riv file is a "binary asset" from the developer's perspective — like a texture or sound file.

**When code changes are needed:**
- New inputs added → developer adds `setInput` calls
- Inputs removed → developer removes `setInput` calls
- New artboards added → developer adds instantiation
- Behavioral changes that affect game logic → designer and developer coordinate

---

## 4. Version Control for Binary Files

### The Problem

.riv files are binary. Git can store them, but:
- `git diff` shows nothing useful ("Binary files differ")
- Merging is impossible — binary merge conflicts require one person's version to win entirely
- Large .riv files with embedded images can bloat the repo over time

### Recommended Approach: Rive Cloud + Git for Exports

**Use Rive's cloud editor for .riv source files:**
- Rive's editor has built-in revision history (paid plans)
- Multiple designers can collaborate through Rive's sharing
- This is the "source of truth" for design files

**Use Git for exported .riv files (the runtime assets):**
- The exported .riv file is what the game loads at runtime
- Treat it like any other game asset (textures, audio)
- Commit it to your game project's asset directory

**Workflow:**
1. Design in Rive's cloud editor
2. Export .riv when ready for integration
3. Commit the exported .riv to the game project
4. Developer integrates (or existing integration picks up the new file)

### Git LFS

If your .riv files are large (100KB+, especially with embedded images), consider Git LFS:

```bash
# One-time setup
git lfs install
git lfs track "*.riv"
git add .gitattributes
```

This stores the binary file content in LFS storage rather than the Git object database, keeping your repo clone fast. Git LFS is especially important if you have many .riv files or files that change frequently (each change stores a new copy in Git's history).

### Naming Exported Files

Include version information in the filename or commit message:

```
assets/rive/
  hud-health-bar.riv
  screen-main-menu.riv
  dlg-dialogue-box.riv
```

Don't version-number the filename (`hud-health-bar-v3.riv`) — Git handles versioning. Use descriptive commit messages:

```
Update health bar: add critical warning state

Adds isCritical boolean input and pulsing red overlay
when health drops below 20%. No changes to existing inputs.
```

---

## 5. File & Project Organization

### Directory Structure for a Game Project

```
my-game/
├── assets/
│   ├── rive/
│   │   ├── hud/
│   │   │   ├── health-bar.riv
│   │   │   ├── ammo-counter.riv
│   │   │   └── score-display.riv
│   │   ├── menus/
│   │   │   ├── main-menu.riv
│   │   │   ├── pause-menu.riv
│   │   │   └── settings-screen.riv
│   │   ├── dialogue/
│   │   │   ├── dialogue-box.riv
│   │   │   └── portraits/
│   │   │       ├── hero.riv
│   │   │       ├── merchant.riv
│   │   │       └── villain.riv
│   │   ├── effects/
│   │   │   ├── damage-numbers.riv
│   │   │   ├── achievement-popup.riv
│   │   │   └── loading-spinner.riv
│   │   └── components/
│   │       ├── btn-primary.riv
│   │       └── btn-secondary.riv
│   ├── sprites/
│   ├── audio/
│   └── ...
├── src/
│   ├── ui/
│   │   ├── rive_manager.lua   -- or .cs, .ts, etc.
│   │   ├── health_bar.lua
│   │   └── dialogue.lua
│   └── ...
└── ...
```

**Principles:**
- Group .riv files by function (HUD, menus, dialogue, effects) not by technical category
- Keep components separate — they're shared across categories
- Mirror the .riv directory structure in your code directory (if `rive/hud/health-bar.riv` exists, `ui/health_bar.lua` wraps it)
- Portraits get their own subdirectory when you have more than 3–4

### Single-File vs. Multi-File

**When to use one .riv file per element (recommended default):**
- Each element is independently loadable
- Runtime only loads what's needed (loading screen doesn't load dialogue box assets)
- Designers can work on different elements simultaneously
- Easier to profile individual elements

**When to combine elements into one .riv file:**
- Elements share significant visual assets (same character art used in portrait and menu)
- The combination is always loaded together (a HUD with health + ammo + score that always appears as a unit)
- You're exporting a complete screen as one unit

**Don't:**
- Put your entire game's UI in one .riv file (makes everything load even when only part is needed)
- Make 100 tiny .riv files for every icon (file I/O overhead becomes a problem)

---

## 6. Production Checklist

Use this checklist before shipping a .riv file:

### Visual Quality
- [ ] All animations loop smoothly (no hitches at loop points)
- [ ] Transitions between states are smooth (no visual pops)
- [ ] Element looks correct at the target rendering size
- [ ] Tested against representative game backgrounds (not just white)
- [ ] Colors are within your game's palette

### State Machine
- [ ] Every state is reachable
- [ ] Every state has an exit path (no dead ends unless intentional)
- [ ] Default/entry state is correct
- [ ] No orphan transitions (transitions without conditions)
- [ ] Trigger inputs reset properly (don't fire continuously)
- [ ] Boolean inputs have correct initial values

### Interactivity
- [ ] All listeners fire correctly
- [ ] Hit areas are appropriately sized (not too small on mobile)
- [ ] Hover states work on desktop, focus states work on gamepad
- [ ] Disabled states block all interaction
- [ ] Rapid input (fast clicking, mouse swiping) doesn't break states

### Performance
- [ ] File size is within budget (check for unnecessary embedded images)
- [ ] Vector complexity is reasonable (path point count reviewed)
- [ ] Artboard is sized to content (not oversized)
- [ ] Advance + render time profiled in target runtime

### Handoff
- [ ] Input manifest documented (name, type, range, description)
- [ ] Artboard name matches integration code
- [ ] Default input values documented
- [ ] Behavioral description provided for developer verification

---

## 7. Suggested Practice Progression

This sequence builds skills incrementally. Each project introduces new concepts while reinforcing previous ones. Complete them in order.

| # | Project | What You Learn | Est. Time |
|---|---------|---------------|-----------|
| 1 | **Animated toggle switch** | Basic shapes, keyframes, state machine with boolean input | 1–2 hours |
| 2 | **Interactive button (hover/press/disabled)** | Listeners, transitions, multiple states, timing | 2–3 hours |
| 3 | **Character face with eye tracking** | Bones, constraints, cursor tracking, blend states | 3–4 hours |
| 4 | **Animated health bar** | Data binding, number inputs, color transitions, triggers | 3–4 hours |
| 5 | **Loading spinner** | Trim paths, looping, easing | 2–3 hours |
| 6 | **Full character with walk/idle/jump** | Skeletal rigging, meshes, weights, 1D blend state | 6–8 hours |
| 7 | **Dialogue box system** | Nested artboards, text binding, state machine layers | 4–6 hours |
| 8 | **Complete game menu screen** | Composition of all skills, nested components | 6–8 hours |
| 9 | **Export and integrate into a real project** | Runtime setup, input wiring, rendering | 4–6 hours |

### Project Details

**Project 1: Animated Toggle Switch**
Your first complete Rive piece. Draw a rounded rectangle track and a circular thumb. Create two animation states (off and on) where the thumb slides left/right and the track changes color. Wire a boolean input to switch between them. Focus on smooth easing — this simple project teaches the state machine fundamentals without visual complexity getting in the way.

**Project 2: Interactive Button**
Build on Project 1 by adding listener-driven interaction. This is where you learn the hover/press/disabled pattern that you'll reuse in every future project. Pay attention to transition timing — the difference between a sluggish button and a snappy one is 100ms vs. 300ms. Test by moving your mouse rapidly across the button.

**Project 3: Character Face with Eye Tracking**
Your first bone-based project. Draw a simple face, rig the eyes with bones, add constraints so the eyes follow the cursor. Use a blend state for expressions (happy/neutral/sad driven by a number input). This project teaches bones, constraints, and pointer-move interaction in a contained scope.

**Project 4: Animated Health Bar**
Your first data-driven element. The fill bar responds to a number input, colors change based on value, triggers fire visual effects. This is the pattern for most game HUD elements — number inputs driving visual state. Covered in detail in [Module 9](module-09-game-applications.md).

**Project 5: Loading Spinner**
A trim path exercise. Create a circular path and animate the trim start/end/offset to create a drawing-on effect. Make it loop seamlessly. Then try variations: a path that draws itself, a spinner that speeds up and slows down, a progress indicator driven by a number input. Short project, but trim paths are uniquely satisfying.

**Project 6: Full Character**
The big one. Rig a character with a skeleton (spine, limbs, head), add mesh deformation for smooth bending, weight-paint the meshes. Create walk, idle, and jump animations. Use a 1D blend state to transition between walk speeds. This project takes the longest but teaches the skills needed for any character animation. Even if you use Spine for production characters, understanding the process in Rive gives you cross-tool fluency.

**Project 7: Dialogue Box System**
Your first multi-component project. The dialogue box is a parent artboard containing a portrait (nested artboard), text elements (data-bound), and choice buttons (nested artboards). Multiple state machine layers handle visibility, text transitions, and expression changes independently. This is where nesting and component architecture pay off.

**Project 8: Complete Game Menu**
Composition of everything. A main menu screen with animated background, title logo, staggered button entrance, character mascot with eye tracking, and transitions. Uses components from Projects 2, 3, and 7. The challenge is orchestrating multiple systems smoothly — the entrance sequence, the idle state, and the exit all need to feel cohesive.

**Project 9: Export and Integrate**
Take one of your projects (the health bar or dialogue box are good choices) and integrate it into a real game project. This means: exporting the .riv file, loading it with a runtime (Web, Unity, or Flutter are easiest to start), wiring game code to the inputs, and rendering it in your game loop. The Rive side is done — this project is about the runtime side. Covered in detail in [Module 8](module-08-exporting-runtime.md).

### Pace Yourself

These 9 projects represent roughly 30–45 hours of focused work. That's not meant to be done in a week. A sustainable pace:

- **Weeks 1–2:** Projects 1–2 (fundamentals)
- **Weeks 3–4:** Projects 3–4 (bones and data)
- **Week 5:** Project 5 (trim paths, lighter week)
- **Weeks 6–8:** Project 6 (character rigging — the longest single project)
- **Weeks 9–10:** Project 7 (component architecture)
- **Weeks 11–12:** Projects 8–9 (synthesis and integration)

Three months of weeknight/weekend work to go from zero to production-capable. Each project produces a portfolio piece you can share.

---

## Common Pitfalls

1. **Premature optimization.** Don't optimize until you have a performance problem. Build the thing, profile it, then optimize the specific bottleneck. Premature vector simplification often sacrifices visual quality for savings you didn't need.

2. **Inconsistent naming.** Renaming 50 artboards mid-project is painful. Establish naming conventions before your first artboard. The 10 minutes spent on conventions saves hours of confusion.

3. **Monolithic .riv files.** A single file with 15 artboards, 8 state machines, and embedded images is hard to maintain, slow to load, and impossible to collaborate on. Break it up.

4. **No input documentation.** The developer stares at `input1`, `flag2`, `val` and has no idea what to wire. Name inputs descriptively and provide a manifest. Costs you 5 minutes, saves the developer an hour.

5. **Skipping the checklist.** "It works on my machine" isn't shipping quality. Run through the production checklist (Section 6) before every handoff. It catches the things you stop seeing after hours in the editor.

6. **Fighting Git with binary files.** Don't try to make Git work like a .riv version control system. Use Rive's cloud editor for design versioning. Use Git for exported assets. Accept that binary files don't merge.

---

## Exercises

### Exercise 1: Organize an Existing File (Beginner)
Take the health bar from Module 9's exercises and apply the naming conventions from Section 1. Rename every layer, every input, and the artboard itself to follow the conventions. Document the input manifest (name, type, range, description) in a text file. Time yourself — this should take under 20 minutes for a single artboard.

### Exercise 2: Performance Audit (Intermediate)
Open the most complex Rive community file you can find (search the community for "character" or "dashboard"). Audit it: count total path points across all visible shapes, measure the artboard dimensions vs. visible content, identify any embedded raster images, check for hidden/occluded shapes that could be removed. Write a brief "optimization report" listing 3–5 specific changes that would improve performance.

### Exercise 3: Component Architecture Plan (Intermediate)
Plan (don't build yet) the component architecture for a game's complete UI. Choose a game you've played and identify all the UI elements: menus, HUD, dialogue, notifications, loading screens. Create a component hierarchy diagram (atomic → molecular → organism, as in Section 1). Identify which components are shared across screens and which are unique. List the .riv files you'd create and the directory structure.

### Exercise 4: Full Production Handoff (Advanced)
Build one HUD element of your choice from scratch, following every production practice in this module: naming conventions, state machine hygiene, performance optimization, input documentation. Then write the developer handoff document: input manifest, behavioral description, integration pseudocode, performance budget. Hand it to a friend or post it in a community — can they understand how to integrate it from your documentation alone?

---

## Recommended Reading & Resources

### Essential
- [Rive Help Center](https://help.rive.app) — Primary documentation for all editor features and runtime integration
- [Rive Community](https://rive.app/community) — Browseable example files, invaluable for studying real-world organization
- [Rive Blog](https://rive.app/blog) — Feature announcements, workflow tips, case studies

### Workflow & Organization
- [Atomic Design (Brad Frost)](https://bradfrost.com/blog/post/atomic-web-design/) — The component hierarchy model adapted in Section 1. Written for web, but the principles apply perfectly to Rive components.
- [Game UI Patterns](https://www.gameuidatabase.com/) — Screenshot database of professional game UI. Use for reference when planning your component architecture.

### Performance
- [Rive Runtime Performance Guide](https://help.rive.app/runtimes) — Official guidance on optimizing runtime performance per platform
- [Browser DevTools Performance Tab](https://developer.chrome.com/docs/devtools/performance/) — For profiling Rive on web

### Supplementary
- [Rive Unity Docs](https://help.rive.app/game-runtimes/unity) — Unity-specific integration and optimization
- [Git LFS Documentation](https://git-lfs.com/) — For managing binary assets in Git

---

## Key Takeaways

1. **Build components, not screens.** The investment in reusable nested artboards pays dividends across every screen in your game. Change a button once, update everywhere.

2. **Name things for your future self.** Six months from now, `btn-primary` with input `isDisabled` is instantly understandable. `artboard-7` with input `flag2` is a debugging nightmare.

3. **Optimize when measured, not when guessed.** Profile first, then fix the actual bottleneck. Usually it's an embedded raster image or an oversized artboard, not the animation complexity you suspected.

4. **Designers own the animation, developers own the integration.** The input manifest is the contract between them. Keep it documented, versioned, and stable.

5. **Use Rive's cloud for design versioning, Git for exports.** Don't fight binary files in Git. Use each tool for what it's good at.

6. **Follow the practice progression.** Nine projects, beginner to advanced, each building on the last. Thirty to forty-five hours of focused practice to go from zero to production-capable.

---

## What's Next

You've completed the Rive learning roadmap. From here:

- **Build your practice projects** following the progression in Section 7
- **Revisit specific modules** when you need deeper reference on a topic
- **Explore the [Rive Community](https://rive.app/community)** — reverse-engineering community files is one of the best ways to learn new techniques
- **Integrate with your game project** — start with a single HUD element or menu screen, prove the pipeline, then expand

For character animation in LÖVE specifically, pair Rive (for UI) with [Spine](https://esotericsoftware.com/) (for game characters). The animation fundamentals you've learned here — bones, keyframes, easing, state machines — transfer directly between tools.

[← Back to Rive Learning Roadmap](rive-learning-roadmap.md)
