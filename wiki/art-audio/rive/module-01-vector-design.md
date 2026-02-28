# Module 1: Vector Design in Rive

**Part of:** [Rive Learning Roadmap](rive-learning-roadmap.md)
**Estimated study time:** 4–6 hours
**Prerequisites:** [Module 0: Orientation & Mental Model](module-00-orientation-mental-model.md)

---

## Overview

Spine requires you to prepare all artwork in an external tool — Photoshop, Aseprite, Illustrator — export it as separate images, import those images into Spine, and then animate them. If you realize mid-animation that you need to change a character's proportions or add a detail, you go back to the external tool, re-export, and re-import. Every visual change is a round trip.

Rive eliminates that round trip entirely. It has a full vector design toolkit built into the editor — pen tools, shape primitives, boolean operations, gradients, clipping, and more. You design your artwork directly in the tool where you'll animate it. When inspiration strikes for a visual change, you switch to Design mode, make the edit, and switch back to Animate mode. No exporting, no importing, no file management.

This matters more than it sounds. The friction of round-tripping between tools isn't just time — it's a creativity killer. Every context switch is an opportunity for your brain to lose the thread. Rive keeps the entire creative loop inside one tool and one mental model.

This module teaches you to create artwork directly in Rive's design tools. You'll learn the drawing primitives, organizational concepts, and design-for-animation principles that make your artwork ready for bones and keyframes. By the end, you'll build a simple character face that serves as your animation subject for the next several modules.

**A word on artistic skill:** You don't need to be a good artist. The exercises in this module use simple geometric shapes. The goal is to learn Rive's design tools, not to create portfolio-quality illustrations. A circle with two dots for eyes and a curved line for a mouth is a perfectly valid animation subject.

---

## Core Concepts

### 1. The Drawing Primitives

Rive provides two categories of drawing tools: **shape tools** (predefined geometric shapes) and the **pen tool** (freeform paths). Everything you draw in Rive is vector-based — resolution-independent, infinitely scalable, and small in file size.

**Shape Tools:**

- **Rectangle (R):** Creates rectangular shapes. You can round corners individually — one corner can be sharp while another has a 20px radius. This flexibility means rectangles serve for buttons, cards, health bar frames, speech bubbles, and dozens of other UI elements.
- **Ellipse (E):** Creates circles and ovals. Hold Shift while drawing for a perfect circle. Ellipses are your go-to for eyes, heads, buttons, icons, and any round element.
- **Polygon:** Creates regular polygons — triangles, pentagons, hexagons. You set the number of sides. Useful for game tokens, gems, shield shapes, and geometric patterns.
- **Star:** Creates star shapes with configurable point count and inner radius. Adjust the inner radius to go from a thin, spiky star to a nearly-circular shape.
- **Triangle:** A dedicated three-sided shape. Less flexible than polygon-with-3-sides but faster to reach.

**Why it matters:** These aren't just convenience tools. Shapes in Rive have semantic properties. A rectangle "knows" it's a rectangle — you can animate its corner radius, and it'll interpolate smoothly from sharp to rounded. A pen-drawn rectangle is just four lines; animating its corners requires moving individual vertices. Use the right primitive for the job.

**Common mistake:** Drawing everything with the pen tool because it feels more "custom." Primitives are faster, semantically richer, and easier to animate. Use the pen tool only for shapes that can't be made from primitives.

**Try this now:** Create a new artboard. Draw one of each primitive: rectangle, ellipse, polygon, star. Change each one's properties in the inspector — corner radius, point count, inner radius. Get a feel for what's adjustable.

---

### 2. The Pen Tool

The pen tool creates freeform bezier paths — the same kind of paths you'd draw in Illustrator, Figma, or any vector editor. If you've used pen tools before, Rive's version works the same way. If you haven't, this concept needs some time.

**How bezier paths work:**
- Click to place a **point** (also called a vertex or anchor)
- Click and drag to place a point with **control handles** (these create curves)
- Each point can be **straight** (sharp corner), **mirrored** (smooth, symmetric curve), **asymmetric** (smooth but with different handle lengths), or **disconnected** (allows a sharp kink in a curve)
- Close the path by clicking on the first point again

**Pen tool workflow:**
1. Select the pen tool (P)
2. Click to place points around your shape
3. Click and drag to create curves
4. Close the path by clicking the first point
5. Switch to the select tool (V) to adjust points afterward

**Editing existing paths:**
- Double-click a path to enter edit mode
- Click and drag points to move them
- Click and drag control handles to adjust curves
- Add new points by clicking on the path between existing points
- Delete points by selecting them and pressing Delete/Backspace

**Why it matters for animation:** Every vertex in a pen path can be animated independently. You can keyframe individual point positions to morph shapes — a smile curving into a frown, a blob transforming into a star, a wave undulating across the screen. This is uniquely powerful in Rive because you can key path vertices in the timeline.

**Common mistake:** Too many points. Every unnecessary point is another thing to manage when animating. Draw with the minimum number of points needed to describe the shape. A smooth curve only needs two points with well-placed handles, not ten points approximating the curve. Fewer points = cleaner animation = easier editing.

**Try this now:** Draw a simple mouth shape using the pen tool — a curved line (three points: two endpoints and one midpoint pulled into a curve). Then try reshaping it from a smile to a frown by moving just the middle point. This is exactly how you'll animate facial expressions later.

---

### 3. Fills, Strokes, and Visual Styling

Every shape in Rive can have **fills** (the interior color), **strokes** (the outline), or both. These are more flexible than you might expect.

**Fills:**
- **Solid color:** A single RGBA color. The most common fill type.
- **Linear gradient:** A smooth transition between two or more colors along a line. Drag the gradient handles on the canvas to control direction and spread.
- **Radial gradient:** A smooth transition radiating outward from a center point. Great for circular highlights, glows, and vignettes.

**Strokes:**
- **Width:** Pixel width of the stroke line.
- **Cap style:** How the ends of open paths look — butt (flat), round, or square.
- **Join style:** How corners look — miter (sharp), round, or bevel.
- **Position:** Stroke can be centered on the path, inside the path, or outside the path. This matters more than you'd think — an inside stroke doesn't change the shape's bounding box, while an outside stroke does.

**Multiple fills and strokes:** A single shape can have multiple fills and multiple strokes stacked on top of each other. This is powerful for creating complex visual effects without additional shapes — a shape with a solid fill, a semi-transparent gradient fill, and two strokes of different widths can create a richly styled element in one object.

**Opacity:** Every fill and stroke has its own opacity independent of the shape's overall opacity. A shape at 100% opacity can have a 50%-opacity gradient fill layered on top of a solid fill.

**Why it matters for animation:** Fills, strokes, and their properties are all animatable. You can keyframe a fill color transitioning from green to red (health bar). You can animate stroke width pulsing (selection indicator). You can animate gradient positions (shimmer effect). Styling isn't just visual — it's animation material.

**Common mistake:** Using separate shapes stacked on top of each other when multiple fills on a single shape would accomplish the same thing more cleanly. Fewer shapes = simpler hierarchy = easier animation.

**Try this now:** Create a rectangle. Give it a solid blue fill. Then add a second fill — a linear gradient from transparent white at the top to transparent at the bottom. You've just created a "gloss" effect with one shape and two fills.

---

### 4. Boolean Operations

Boolean operations combine two or more shapes into a new shape using set-theory logic. Rive supports four boolean operations:

- **Union (Add):** Merges shapes into a single outline. Two overlapping circles become a peanut shape.
- **Subtract (Difference):** Removes one shape from another. A circle with a smaller circle subtracted becomes a donut.
- **Intersect:** Keeps only the area where shapes overlap. Two overlapping rectangles become the rectangle of their overlap.
- **XOR (Exclusive Or):** Keeps everything *except* the overlap. The opposite of intersect.

**How they work in Rive:** Boolean operations are non-destructive in Rive. When you apply a boolean operation, the original shapes still exist as children of the boolean group — they're just combined visually. You can still select and move the individual child shapes, which changes the resulting boolean output. This means boolean shapes can be animated — move a child shape and the boolean result updates dynamically.

**Use cases:**
- **Donut/ring shapes:** Circle minus smaller circle. Useful for loading indicators, circular progress bars, halos.
- **Complex silhouettes:** Union multiple shapes into one outline. A character's body from overlapping circles and rectangles.
- **Clipping with dynamic shapes:** Unlike static clipping, boolean subtraction with an animated child creates dynamic holes or reveals.
- **Decorative cutouts:** Subtract geometric patterns from a background shape.

**Why it matters for animation:** Because boolean operations in Rive are live (non-destructive), you can animate the child shapes and the boolean result updates every frame. A circle being subtracted from a rectangle — animate the circle's position and you get a moving spotlight/reveal effect. This is a powerful technique for transitions, loading states, and dynamic masks.

**Common mistake:** Using booleans when clipping would be simpler. If you just want to crop content inside a shape (like a health bar fill inside a frame), clipping is the right tool. Booleans are for when you need to create a *new shape* from the combination of existing shapes.

**Try this now:** Create two overlapping circles. Select both. Apply Union — they merge into one shape. Undo. Apply Subtract — one is cut from the other. Undo. Try Intersect and XOR. Then move the child shapes and watch the boolean result update.

---

### 5. Groups: Your Organizational Backbone

Groups in Rive are containers that hold multiple objects. They seem simple, but they're the foundation of a well-organized Rive file. A group:

- Has its own position, rotation, scale, and opacity
- Transforms all children relative to itself
- Can be moved, rotated, and scaled as a single unit
- Can be collapsed in the hierarchy for organization

**The critical distinction: Groups vs. Bones**

This is one of the most important conceptual distinctions in Rive:

- **Groups** define **visual organization.** They answer: "What belongs together visually? What do I want to move as a unit?"
- **Bones** define **animation hierarchy.** They answer: "What drives what? When I rotate this, what follows?"

You'll use both. A character's head *group* might contain the skull shape, two eye groups, a mouth group, and hair shapes — all organized for visual clarity. A head *bone* would be connected to a neck bone and would drive the rotation of all head elements for animation.

In simple cases, groups can serve double duty (rotating a group rotates its children, which is animation). But for anything beyond trivial animation, you'll want bones (Module 2). Groups are for organization; bones are for animation.

**Nesting groups:** Groups can contain other groups. A common pattern:

```
character (group)
├── head (group)
│   ├── skull (ellipse)
│   ├── eyes (group)
│   │   ├── eye-left (ellipse)
│   │   └── eye-right (ellipse)
│   ├── mouth (path)
│   └── hair (group)
│       ├── hair-strand-1 (path)
│       └── hair-strand-2 (path)
├── body (group)
│   ├── torso (rectangle)
│   └── ...
└── effects (group)
    └── ...
```

Each level of nesting gives you a transform pivot point. Rotate the "head" group and everything inside rotates together. Rotate the "eyes" group and both eyes rotate together but the mouth stays put.

**Why it matters:** Good group organization makes animation dramatically easier. Poor organization — everything at the same level, generic names, no nesting — makes even simple animation painful.

**Common mistake:** Not grouping enough. If you'll ever want to move, rotate, or scale multiple objects together, group them now. It's much easier to group during the design phase than to reorganize later when bones and animations already reference the objects.

---

### 6. Clipping: Content Masks

Clipping constrains the visibility of objects to the shape of another object. Think of it as a window — the clipping shape defines where you can see through, and clipped content is only visible inside that window.

**Use cases that matter for game dev:**

- **Health bars:** A colored rectangle (the fill) clipped inside a rounded rectangle (the frame). Animate the fill's x-position or width to show health depleting.
- **Progress indicators:** A moving shape clipped inside a track shape.
- **Viewport masks:** Content scrolling inside a defined window.
- **Artistic masks:** Revealing artwork through a shape — clouds passing in front of a moon, water visible inside a porthole.

**How clipping works in Rive:**
1. Create the clipping shape (the "window")
2. Create the content to be clipped
3. In the hierarchy, make the content a child of the clipping shape (or use the clip property in the inspector)
4. The content is now only visible inside the clipping shape's bounds

**Clipping vs. boolean subtract:** Both can hide parts of shapes, but they work differently:
- **Clipping** hides content *outside* the clip shape. The clipped content still exists; it's just invisible outside the bounds.
- **Boolean subtract** creates a *new shape* by removing one shape from another. The result is a single modified shape.

Use clipping when the content moves independently of the mask (health bar fill sliding inside a frame). Use boolean subtract when you want to permanently alter a shape's outline.

**Why it matters for animation:** Clipping shapes can be animated. Animate the clip shape's size and you get a reveal effect. Animate the clipped content's position and you get a sliding/scrolling effect. Animate both and you get sophisticated transitions.

**Try this now:** Create a rectangle (the frame). Create a second, slightly smaller rectangle inside it with a bright fill (the fill). Clip the fill to the frame. Now move the fill left — it should disappear as it slides out of the clipping area. This is the basic mechanic of every health bar, progress bar, and loading indicator.

---

### 7. Solos: Visibility Management

Solos are Rive's visibility toggle system. You can solo an object to make only it (and its children) visible, hiding everything else. This is similar to layer visibility toggles in Photoshop, but in Rive, solos can also be animated.

**Design-time uses:**
- Focus on one part of a complex design without distracting elements
- Compare variations by soloing different options
- Organize alternative states (happy face vs. sad face) in the same artboard

**Animation uses:**
- **Sprite-sheet-style animation:** Create multiple frames (frame1, frame2, frame3) and animate which one is solo'd — effectively cycling through frames like a traditional sprite sheet, but with vector art
- **Outfit/appearance changes:** A character with multiple outfits stacked. Solo toggles which outfit is visible.
- **State-based visibility:** A notification icon that shows different symbols based on state — solo the checkmark for success, solo the X for error, solo the spinner for loading.

**Why it matters for animation:** Solo/visibility keyframing is one of those "simple but powerful" features that solves a lot of practical problems. Anywhere you need to swap between multiple visual variants (expressions, outfits, icons, frames), solos are your tool.

**Common mistake:** Using opacity to show/hide things when solos would be cleaner. Setting opacity to 0 makes an object invisible but it still processes and renders (just transparently). Solos actually skip rendering the hidden objects, which is better for performance and cleaner to manage.

---

### 8. Draw Order: Your Z-Index

Draw order in Rive is determined by position in the hierarchy — objects listed higher in the hierarchy panel render on top of objects listed lower. This is your z-index, and it works the same way regardless of where objects are positioned on the artboard.

**Key principles:**
- **Later (lower) in the hierarchy = drawn first = appears behind**
- **Earlier (higher) in the hierarchy = drawn later = appears in front**
- **Within a group**, the same rule applies — children are ordered within their group
- **Groups themselves** are also ordered relative to their siblings

**Organizational pattern for game elements:**

```
artboard
├── foreground-effects (group) — particles, flashes, overlays
├── character (group) — the main subject
├── midground (group) — platforms, objects
└── background (group) — sky, environment
```

Objects at the top of this list render last (in front). Background at the bottom renders first (behind everything).

**Why it matters for animation:** Draw order can be changed during animation. A character jumping in front of an obstacle and then landing behind it requires a draw order change mid-animation. In Rive, you can keyframe an object's position in the hierarchy to change what's in front of what.

**Common mistake:** Forgetting that draw order is hierarchy order. If your character's arm is rendering behind their body when it should be in front, don't try to fix it with position offsets — just move the arm above the body in the hierarchy.

**Try this now:** Create three overlapping circles with different colors. Drag them up and down in the hierarchy panel and watch how the overlap order changes on the canvas. This is draw order in action.

---

### 9. Designing for Animation: Principles That Save You Hours

Everything you've learned so far is standard vector design knowledge. This section is where Rive-specific wisdom comes in — design principles that make your artwork animation-ready from the start, saving you painful restructuring later.

**Principle 1: Separate anything you'll animate independently.**

If the mouth will move separately from the head, the mouth must be a separate shape (not merged into the head shape). If the eyes blink independently, each eye must be its own shape. If a limb bends at the elbow, the upper arm and lower arm must be separate shapes.

This seems obvious, but it's the #1 mistake beginners make. They draw a beautiful, unified character illustration — one complex path for the whole body — and then realize they can't animate any part independently because it's all one shape. Design with animation in mind from the first stroke.

**Principle 2: Name everything immediately.**

`Path 47`, `Ellipse 12`, `Group 3` — these are the default names Rive assigns. They're meaningless. When you have 50 objects and you're trying to find the left eyebrow in the timeline, `Path 47` is useless.

Name every object as you create it:
- `head`, `body`, `arm-left`, `arm-right`
- `eye-left`, `eye-right`, `pupil-left`, `pupil-right`
- `mouth-smile`, `mouth-frown`, `mouth-neutral`
- `bg-gradient`, `frame-outer`, `fill-health`

Use consistent prefixes for categories: `btn-` for buttons, `icon-` for icons, `fx-` for effects. Your future self will thank you when the hierarchy has 80 objects and you need to find `fx-glow-pulse` at a glance.

**Principle 3: Think in layers (draw order).**

Before you start drawing, decide on your layering:
1. **Background** — sky, ground, environment (drawn first, behind everything)
2. **Character body** — torso, limbs (middle layer)
3. **Character face** — eyes, mouth, details (in front of body)
4. **Foreground effects** — particles, glows, overlays (drawn last, in front of everything)

Set up these groups in the hierarchy *before* you start drawing. It's much easier to draw into the right group than to reorganize later.

**Principle 4: Use groups strategically for transform pivots.**

A group is a transform point. When you rotate a group, all children rotate around the group's origin. This means:

- Group the head parts so you can nod/shake the head with one rotation
- Group each arm's parts so you can swing the whole arm
- Group the eyes so you can shift eye direction by moving the eye group

Place the group's origin point at the natural pivot point — the head group's origin at the neck, the arm group's origin at the shoulder, the eye group's origin at the center between the eyes.

**Principle 5: Keep shapes simple — you can always add detail later.**

Start with the simplest shapes that convey the form. A head is an ellipse. An eye is an ellipse inside an ellipse. A body is a rectangle. You can refine shapes later — add pen-tool details, adjust curves, embellish. But start simple so you can test animation quickly. The fastest path to a satisfying result is: simple shapes → basic animation → then polish artwork.

**Principle 6: Import strategically if needed.**

Rive supports SVG import and raster image import. Use these when:
- You have existing artwork you want to animate (import SVG for editable paths)
- You need photographic textures (import raster images)
- You're migrating from another tool

Don't use import as a crutch to avoid learning Rive's design tools. For most game UI work, Rive's built-in tools are sufficient and create cleaner, more animation-friendly results than imported artwork.

---

## Case Studies

### Case Study 1: Building a Button (Design Decisions)

A seemingly simple button requires several design decisions that affect animation:

**Structure:**
```
btn-primary (group)
├── btn-bg (rectangle, rounded corners)
├── btn-shadow (rectangle, slightly offset, darker color, lower opacity)
├── btn-highlight (rectangle, clipped to btn-bg, gradient fill for gloss)
├── btn-icon (group or imported SVG)
└── btn-label (text, if using Rive text)
```

**Why this structure:** Each element can animate independently. On hover, `btn-bg` can change color while `btn-highlight` shifts its gradient. On press, `btn-shadow` can shrink (simulating depth) while the whole `btn-primary` group scales down slightly. On disabled, everything can desaturate. None of this is possible if the button is a single merged shape.

**Design decisions that matter:**
- The shadow is a separate shape, not a drop-shadow effect — because you need to animate it independently
- The highlight is clipped to the background shape — so it stays inside the button bounds during animation
- The icon is in its own group — so it can animate independently (spin, bounce, swap)
- The group origin is at the center — so scale animations expand/contract symmetrically

### Case Study 2: Building a Character Face (Your Exercise Subject)

The character face you'll build in this module's exercise follows specific design patterns:

**Structure:**
```
face (group, origin at center of head)
├── head (ellipse)
├── eyes (group, origin between the eyes)
│   ├── eye-left (group, origin at pupil center)
│   │   ├── eyeball-left (ellipse, white)
│   │   └── pupil-left (ellipse, dark, smaller)
│   ├── eye-right (group, origin at pupil center)
│   │   ├── eyeball-right (ellipse, white)
│   │   └── pupil-right (ellipse, dark, smaller)
├── mouth (path, pen-drawn curve)
├── brow-left (path or ellipse, thin)
├── brow-right (path or ellipse, thin)
└── extras (group)
    ├── nose (ellipse or path)
    └── blush (two ellipses, low opacity pink)
```

**Why each element is separate:**
- **Pupils separate from eyeballs:** Pupils will move to create "look direction." Eyeballs stay put. They must be independent.
- **Eyes grouped together:** When the whole face looks left, the eye group shifts — moving both eyes simultaneously without affecting the mouth.
- **Mouth as a pen path:** Mouth shapes morph between expressions (smile, frown, surprise) by animating individual vertex positions. This requires a pen path, not a primitive.
- **Eyebrows separate:** Eyebrows convey emotion. They'll animate independently — raised for surprise, furrowed for anger, neutral for idle.
- **Extras in their own group:** Nose and blush are subtle details that can be toggled or animated for different expressions.

### Case Study 3: Health Bar Design Anatomy

A health bar is one of the most common game UI elements and an excellent test of Rive design skills:

**Structure:**
```
health-bar (group)
├── frame (rectangle, rounded corners, dark stroke, slight glow)
├── fill-area (clipping group, matches frame interior)
│   ├── fill-bg (rectangle, dark — visible when health is low)
│   ├── fill-main (rectangle, green — this is the "health")
│   └── fill-highlight (rectangle, gradient — gloss on top of fill)
├── markers (group)
│   ├── marker-25 (line, subtle tick at 25%)
│   ├── marker-50 (line, subtle tick at 50%)
│   └── marker-75 (line, subtle tick at 75%)
├── icon-health (group, heart icon or cross)
└── label (text, "HP" or health number)
```

**Why this structure:** The `fill-main` rectangle's width (or x-position) will be animated to represent health. It's clipped inside `fill-area` so it doesn't overflow the frame. The `fill-bg` is always visible behind it, showing the "empty" part of the bar. Markers give visual reference points. The icon and label are independent elements that can animate separately (icon pulses when critical, label updates with data binding).

---

## Common Pitfalls

1. **Merging shapes you'll want to animate separately.** The #1 design mistake. If two shapes will ever need to move independently, keep them separate. You can always group them for organizational clarity without merging their geometry.

2. **Not naming objects.** You will regret `Path 47` when you're debugging a state machine with 30 objects. Name everything as you create it. The 2 seconds it takes to type `eye-left` saves 20 seconds of hunting through the hierarchy later, hundreds of times.

3. **Ignoring group origins.** A group's origin determines where it rotates and scales from. If you don't set it intentionally, animations will pivot from unexpected points. Set origins during design, not during animation.

4. **Over-detailing before animating.** Spend 20 minutes on a rough design, test the animation, then polish. Many artists spend hours perfecting artwork only to discover it needs restructuring for animation. Rough first, animate, then refine.

5. **Using raster images when vectors would work.** Raster images don't scale cleanly and increase file size. For game UI elements (buttons, bars, icons, frames), vector shapes are almost always the better choice. Reserve raster imports for photographic content or pre-existing artwork you don't want to redraw.

6. **Too many vertices on pen paths.** Every extra point on a path is a potential animation keyframe and a source of visual artifacts if misaligned. Draw with the minimum points needed. A smooth curve needs two endpoints and well-placed handles, not ten approximation points.

7. **Flat hierarchy (everything at root level).** If your hierarchy panel is a flat list of 40 objects with no groups, you've lost control. Group related objects. Nest groups inside groups. The hierarchy should reflect the logical structure of your artwork.

---

## Exercises

### Exercise 1: Shape Exploration (Beginner, 30 minutes)

Create a new artboard (400x400). Using only shape primitives (no pen tool), build a simple scene:
- A house (rectangles for walls and door, triangle for roof)
- A sun (ellipse with a radial gradient from yellow to orange)
- A tree (rectangle trunk, ellipse canopy)
- A ground line (rectangle spanning the bottom)

Requirements:
- Every object must be named descriptively
- Objects must be organized in groups: `sky`, `ground`, `house`, `tree`
- Use at least one gradient fill
- Use draw order to layer objects correctly (sun behind house, tree in front)

This exercise tests: shape tools, naming, grouping, fills, draw order.

### Exercise 2: Pen Tool Practice (Beginner, 30 minutes)

On a new artboard, draw these shapes using only the pen tool:
1. A five-pointed star (using straight segments)
2. A smooth S-curve (using curved handles)
3. A cloud shape (using a mix of curves and bumps)
4. A crescent moon (using curves — or try boolean subtract with two ellipses)

For each shape: use the minimum number of points possible. After drawing, count your vertices. Could you have done it with fewer points?

### Exercise 3: Boolean Experiments (Beginner, 20 minutes)

Create these shapes using boolean operations:
1. A donut (circle subtract smaller circle)
2. A Pac-Man shape (circle subtract triangle)
3. A cross/plus sign (union of two rectangles)
4. A keyhole shape (union of circle and rectangle, then subtract smaller circle)

After creating each, try moving the child shapes and watch the boolean result update. This previews how boolean operations can be animated.

### Exercise 4: Build Your Character Face (Intermediate, 1–2 hours)

Build the character face described in Case Study 2. Requirements:

1. **Head:** Ellipse, soft color (not pure white — try a light blue, peach, or yellow)
2. **Eyes:** Each eye is a group containing an eyeball (white ellipse) and a pupil (dark ellipse). Pupils must be separate and independently movable.
3. **Mouth:** A pen path with 3–5 vertices. Should be reshapeable from a smile to a frown by moving vertices.
4. **Eyebrows:** Two paths or thin ellipses above the eyes.
5. **At least one extra detail:** Nose, blush marks, hair, ears, hat — your choice.

Structural requirements:
- Every object named (no default names)
- Organized in groups as shown in the case study
- Group origins set at natural pivot points (head origin at the "neck," eye-group origin between the eyes)
- Draw order correct (pupils in front of eyeballs, eyebrows in front of head)

This face is your animation subject for Modules 2–6. Take care with the structure — poor organization now means painful restructuring later.

### Exercise 5: Health Bar Foundation (Intermediate, 45 minutes)

Build the health bar structure from Case Study 3. Don't worry about animation yet — just build the design.

1. Frame with rounded corners
2. Fill rectangle clipped inside the frame
3. At least a basic color scheme (green fill, dark frame)
4. All objects named and organized in groups
5. Test the clipping: manually drag the fill rectangle to the left — does it "deplete" cleanly inside the frame?

You'll return to this health bar in later modules to add animation and a state machine.

---

## Recommended Reading & Resources

**Tier 1 — Do Now:**
- [Rive Shapes & Paths](https://help.rive.app/editor/fundamentals/shapes-and-paths) — official docs on drawing tools
- [Rive Artboards](https://help.rive.app/editor/fundamentals/artboards) — artboard concepts and management

**Tier 2 — Reference as Needed:**
- [Rive Constraints](https://help.rive.app/editor/constraints) — preview for Module 2, but understanding constraint points helps design decisions
- Browse community files tagged with "character" or "UI" and study their hierarchy organization

**Tier 3 — Background:**
- Any vector design tutorial (Figma, Illustrator, Inkscape) — the pen tool concepts are universal
- [The Bézier Game](https://bezier.method.ac/) — a web game that teaches bezier curve drawing through puzzles. Excellent if pen tools are new to you.

---

## Key Takeaways

1. **Rive has a full vector design toolkit built in.** No external tools needed for most game UI artwork. Design and animate in the same tool.

2. **Use shape primitives when possible, pen tool when necessary.** Primitives are faster, semantically richer, and easier to animate. The pen tool is for custom shapes that primitives can't express.

3. **Separate anything you'll animate independently.** This is the #1 design-for-animation principle. If it moves on its own, it must be its own shape.

4. **Name everything, group everything, set group origins intentionally.** Good hierarchy organization makes animation dramatically easier. Poor organization makes it painful.

5. **Design rough, animate early, polish later.** Don't perfect artwork before testing animation. You'll often discover that the design needs restructuring for animation purposes.

6. **Clipping is your friend for health bars, progress bars, and masked content.** Content clipped inside a shape can be animated to create fill/deplete effects.

7. **Boolean operations are non-destructive and animatable.** Use them for complex shapes that need to change dynamically.

---

## What's Next

**[Module 2: Bones, Constraints & Rigging →](module-02-bones-constraints-rigging.md)**

With your artwork designed and organized, it's time to give it a skeleton. Module 2 covers Rive's bone system — building hierarchies, binding artwork to bones, adding constraints like IK, and preparing your character for animation. You'll add bones to the character face you built in this module.
