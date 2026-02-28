# Module 6: Advanced Animation Techniques

[← Back to Rive Learning Roadmap](rive-learning-roadmap.md)

**Time estimate:** 3–5 hours
**Prerequisites:** Modules 3–5 (timeline animation, state machine, listeners)

---

## Overview

Modules 3–5 gave you the fundamentals: keyframes, state machines, and interactivity. This module covers the techniques that take your work from functional to polished. Trim paths let you animate strokes drawing themselves on and off. Nested artboards let you build reusable components. Blend states (covered lightly in Module 4) get a deeper treatment here with practical applications. And joystick input opens up 2D cursor-driven blending.

These aren't exotic features — they're daily tools in professional Rive work. A loading spinner uses trim paths. A menu system uses nested artboards. A character controller uses blend states. A look-at system uses joystick input. Mastering these techniques is what separates "I can animate in Rive" from "I can build production content in Rive."

### Learning Objectives

By the end of this module, you will be able to:

1. Create self-drawing path animations using trim paths
2. Build modular, reusable animations with nested artboards
3. Design 1D blend states for smooth speed-based animation mixing
4. Use additive blending for layered animation effects
5. Implement 2D joystick input for directional blending

---

## Core Concepts

### 1. Trim Paths

Trim paths let you animate the visible portion of a stroke. Instead of the full path being visible, you control where the stroke starts and ends — and by animating these values, you create drawing-on and drawing-off effects.

**The three controls:**

- **Start (%):** Where the visible stroke begins along the path. 0% = path start, 100% = path end.
- **End (%):** Where the visible stroke ends along the path. 0% = path start, 100% = path end.
- **Offset (%):** Shifts the entire visible segment along the path without changing its length.

**Drawing-on effect:**

Set Start = 0%, End = 0% at keyframe 0. Set End = 100% at keyframe 60. The stroke draws itself from start to finish over 60 frames.

**Drawing-off effect:**

Set Start = 0%, End = 100% at keyframe 0. Set Start = 100% at keyframe 60. The stroke erases itself from start to finish.

**Chasing effect:**

Animate both Start and End simultaneously with an offset between them. A short visible segment chases along the path. This is how loading spinners work — a partial stroke rotating around a circular path.

**Path direction matters:**

The start-to-end direction follows the path's drawing direction. If your path was drawn left-to-right, the trim animates left-to-right. If you want the opposite direction, reverse the path direction in the editor (or swap which end you animate).

**Why it matters:** Trim paths create effects that are impossible with simple transform animations. Handwriting reveals, progress indicators, loading spinners, circuit-board trace animations, reveal effects — all rely on trim paths.

**Common mistake:** Applying trim paths to fills instead of strokes. Trim paths only affect strokes. If your shape has a fill and a stroke, only the stroke will animate with trim. If you want the fill to appear progressively, use a clipping mask animation instead.

**Try this now:** Draw a wavy line or a circle with a stroke (no fill). Add trim path properties to the shape. In a timeline animation, keyframe the End value from 0% to 100% over 30 frames. Preview — the shape should draw itself on. Then try animating both Start and End with a fixed gap between them to create a chasing segment.

---

### 2. Solo and Visibility Animation

Solo and visibility let you toggle which objects are visible at specific keyframes, creating frame-by-frame animation within a Rive file.

**Solo:**

Solo isolates a single child within a group, hiding all siblings. When you solo object A in a group of [A, B, C], only A is visible. Keyframing which object is solo'd creates a flip-book style animation.

**Visibility keyframing:**

Directly keyframe an object's visibility (visible/hidden). More flexible than solo because you can show multiple objects simultaneously or hide individual objects without affecting siblings.

**Use cases:**

- **Sprite-sheet-style animation:** Place 8 hand-drawn explosion frames as separate shapes in a group. Solo each one sequentially over 8 keyframes. The result is a frame-by-frame explosion animation without traditional tweening.
- **Outfit/appearance changes:** A character has 3 hat options as separate shapes. Visibility toggles between them based on state machine input.
- **UI state indicators:** Show/hide icons, badges, notification dots based on data.
- **Progressive reveal:** Show list items one by one with visibility keyframes staggered over time.

**Why it matters:** Not everything should be tweened. Some effects — explosions, impact flashes, sprite swaps — look better as hard cuts between pre-drawn frames. Solo and visibility give you that control.

**Common mistake:** Using opacity animation (0 → 1) when visibility is more appropriate. Opacity animation means the object is still there at 0% opacity, still consuming rendering resources and still receiving pointer events. Visibility truly removes the object from rendering.

**Try this now:** Create a group with 4 simple shapes (different colors or symbols). In a timeline, use solo to cycle through them — one shape visible per frame. Set the animation to loop. Preview — you should see a flip-book style animation.

---

### 3. Nested Artboards

Nested artboards let you embed one artboard inside another. The nested artboard maintains its own animations and state machine, running independently within the parent. This is Rive's component system.

**How nesting works:**

1. Create a standalone artboard (e.g., a "Button" artboard with its own hover/press state machine)
2. In another artboard (e.g., "Menu Screen"), insert the Button artboard as a nested element
3. Position and scale the nested artboard within the parent
4. The nested artboard's state machine runs independently — its listeners work, its animations play, its inputs respond

**Exposing nested inputs:**

The parent artboard can access the nested artboard's inputs. This lets the parent control the child:

- Parent sets `isDisabled = true` on the nested button → button enters Disabled state
- Parent reads `onClick` trigger from nested button → parent knows the button was clicked
- Parent sets `labelText` on nested artboard → button text updates

This input forwarding creates a true component API: the nested artboard defines what inputs it accepts, and the parent sets them.

**Multiple instances:**

You can nest the same artboard multiple times. All instances share the same source artboard (animations, state machine design), but each instance has its own independent state. Button instance 1 can be hovered while instance 2 is pressed. Change the source artboard's design, and all instances update.

**Nesting depth:**

Artboards can nest artboards that nest artboards. A Menu Screen can contain a Button Group that contains individual Buttons. Each level has its own state machine. Keep nesting shallow (2–3 levels) for maintainability.

**Why it matters:** Nested artboards are how you build complex Rive projects without losing your mind. Without them, a menu with 5 buttons means duplicating the button's shapes, animations, and state machine 5 times. With nesting, you design the button once and reuse it. Changes propagate automatically.

**Common mistake:** Not sizing the nested artboard correctly. The nested artboard renders within its defined bounds. If the parent scales it to a different aspect ratio, the content stretches. Design nested artboards at the size they'll be used, or use fit modes to control scaling behavior.

**Try this now:** Create a "Button" artboard with a simple hover/press state machine (from Module 5 exercises). Create a "Menu" artboard. Insert the Button artboard three times. Position them vertically. Preview the Menu artboard — each button should respond to hover/press independently.

---

### 4. Blend States In Depth

Module 4 introduced blend states conceptually. Here we cover the practical details of setting them up and using them effectively.

**1D Blend State setup:**

1. In the state machine, add a Blend State (1D)
2. Assign it a number input (e.g., `speed`)
3. Add animation entries at specific input values:
   - Value 0.0 → Idle animation
   - Value 0.5 → Walk animation
   - Value 1.0 → Run animation
4. Rive automatically interpolates between adjacent animations based on the current input value

**Interpolation detail:**

At `speed = 0.3`, Rive blends:
- 60% Idle (closest lower keypoint: 0.0)
- 40% Walk (closest upper keypoint: 0.5)

The blend is per-property: each bone's position, rotation, and scale is interpolated independently. This means the blend only looks natural if the animations are compatible — same skeleton, same keyframe structure, similar poses at similar points in the cycle.

**Making blend-compatible animations:**

- Use the same loop length for all animations in a blend. If Idle is 30 frames and Walk is 60 frames, the blend will have timing artifacts.
- Start all animations from a neutral pose. Extreme differences between adjacent blend entries create uncanny interpolation.
- Keep the same bones active across all animations. If Walk uses a spine bone that Idle doesn't keyframe, the blend may produce unexpected results.

**Additive blend states:**

Normal blend states replace the current animation. Additive blend states layer on top. The math:

- Normal blend: `result = lerp(animA, animB, t)`
- Additive blend: `result = currentPose + (additiveAnim * t)`

Additive is for overlays: a breathing motion added on top of any pose, a lean applied on top of a walk cycle, a recoil added on top of an aim direction.

**When to use blend states vs transitions:**

| Scenario | Use blend state | Use transition |
|----------|----------------|----------------|
| Speed affects animation style | ✅ Smooth interpolation | ❌ Jarring switch |
| Binary state change (alive → dead) | ❌ No intermediate makes sense | ✅ Clean switch |
| Directional input (look left/right) | ✅ Continuous positioning | ❌ Only 2 or 4 positions |
| One-shot event (explosion) | ❌ Can't blend an event | ✅ Play and return |

**Why it matters:** Blend states are the tool for smooth, data-driven animation. Character locomotion, facial expressions driven by mood values, UI elements driven by percentages — anywhere a number controls the visual output, blend states deliver the smoothest result.

**Common mistake:** Unequal animation lengths in a blend. A 1-second idle blended with a 2-second walk creates a walk that looks like it's playing at half speed when the blend is near the walk end. Standardize your loop lengths.

**Try this now:** Create three animations for a simple shape: small-slow-pulse (Idle), medium-bounce (Walk), large-fast-bounce (Run). Add a 1D blend state with a `speed` input. Map the three animations to values 0.0, 0.5, and 1.0. Scrub the speed slider in preview — the motion should smoothly intensify from gentle pulse to energetic bounce.

---

### 5. Joystick Input (2D Blend)

Joystick input extends blend states from one dimension (a slider) to two dimensions (a 2D pad). Two number inputs control horizontal and vertical blending simultaneously.

**How it works:**

1. Create a joystick input in the state machine (or use two number inputs)
2. Assign it to a 2D blend state
3. Map animations to positions on a 2D grid:

```
              Up
              |
   Up-Left ---+--- Up-Right
              |
   Left ------+------ Right    ← X axis
              |
  Down-Left --+-- Down-Right
              |
             Down
                                Y axis ↕
```

4. As the X and Y inputs change, Rive blends between the nearest animations in 2D space

**Minimum viable setup:**

You don't need all 9 positions filled. Four corners often suffice:
- Top-Left: Look Up-Left
- Top-Right: Look Up-Right
- Bottom-Left: Look Down-Left
- Bottom-Right: Look Down-Right

Rive interpolates between these four based on X/Y position, creating smooth directional blending.

**Cursor-driven joystick:**

Combine joystick blend states with pointer move listeners (Module 5):

1. Pointer move listener maps cursor X/Y to number inputs
2. Number inputs drive joystick blend state
3. Character smoothly looks toward cursor position

This is more natural than constraint-based cursor tracking because you have full artistic control over every directional pose. You draw exactly what "look top-left" looks like, rather than relying on bone rotation math.

**Use cases:**

- **Head/eye direction:** Character faces toward cursor or target
- **Aim direction:** Weapon points where the cursor aims
- **Wind/environment:** Background elements respond to 2D cursor position
- **Vehicle steering:** Turning visualization driven by 2D input

**Why it matters:** Real interaction happens in 2D. Cursor position, analog stick input, touch position — all have X and Y components. Joystick blend states map 2D input to 2D animation blending naturally.

**Common mistake:** Not centering the joystick range. If your number inputs range from 0–1 but your blend positions expect -1 to 1, the center point is wrong and animations will be offset. Align your input ranges with your blend grid.

**Try this now:** Create a simple face with a head shape and two eyes. Make four poses: Look Left, Look Right, Look Up, Look Down. Set up a 2D blend state with `lookX` and `lookY` inputs. Map the four poses to the four cardinal positions on the blend grid. Connect pointer move listeners to the inputs. Preview — the face should smoothly look toward your cursor from any direction.

---

## Case Studies

### Case Study 1: Self-Drawing Logo Reveal

**The problem:** A game's splash screen needs an animated logo that draws itself on, then holds.

**The approach:**

1. Design the logo as paths with strokes (no fills initially)
2. Each letter/element is a separate path for independent timing
3. Timeline animation sequence:
   - Frame 0–20: First letter draws on (trim End: 0% → 100%)
   - Frame 10–30: Second letter draws on (staggered start)
   - Frame 20–40: Third letter draws on
   - Frame 35–50: Fills fade in (opacity 0% → 100%)
   - Frame 50–60: Subtle glow/pulse begins (loops)
4. State machine: Entry → Draw (one-shot) → Idle (loop)

**Key techniques:** Trim path staggering, opacity for fill reveal, exit time transition from one-shot to loop.

**Result:** A logo that writes itself letter by letter, fills in with color, then settles into a subtle idle animation. Total .riv file size: ~15KB.

---

### Case Study 2: Reusable Button Component System

**The problem:** A game UI needs consistent buttons across multiple screens (main menu, settings, pause, shop) with different labels and sizes.

**The approach:**

1. Create a "Button" artboard:
   - Rounded rectangle background
   - Text element (bound to text input for dynamic labels)
   - State machine: Normal, Hover, Pressed, Disabled
   - Listeners: pointer enter/exit/down/up on the background shape
   - Inputs: `isHovering` (bool), `isPressed` (bool), `isDisabled` (bool), `onClick` (trigger)

2. Create screen artboards that nest the Button:
   - Main Menu: 3 button instances (Play, Settings, Quit)
   - Settings: 4 button instances (Audio, Video, Controls, Back)
   - Each instance gets its own label via exposed text input

3. Parent screen state machine:
   - Routes button clicks to screen navigation
   - Manages button disabled states based on game state

**Key techniques:** Nested artboards for reuse, exposed inputs for customization, parent state machine for coordination.

**Result:** 7 buttons across 2 screens, all sharing one Button artboard definition. Changing the hover animation updates all 7 buttons simultaneously.

---

### Case Study 3: Character with Directional Look

**The problem:** A game character on a menu screen should smoothly look toward the player's cursor.

**The approach:**

1. Create five head poses:
   - Center (neutral forward)
   - Left (head turned 15° left, left eye wider, right eye narrower)
   - Right (head turned 15° right, reverse of Left)
   - Up (head tilted back slightly, eyes looking up)
   - Down (head tilted forward slightly, eyes looking down)

2. Set up a 2D blend state:
   - Input: `lookX` (-1 to 1), `lookY` (-1 to 1)
   - Center at (0, 0), Left at (-1, 0), Right at (1, 0), Up at (0, 1), Down at (0, -1)

3. Pointer move listener:
   - Map artboard-relative cursor X to `lookX` (clamped -1 to 1)
   - Map artboard-relative cursor Y to `lookY` (clamped -1 to 1)

4. Second layer: Autonomous blink (Loop with random-ish timing via ping-pong animation)

5. Third layer: Idle breathing (Additive blend, always active)

**Key techniques:** 2D blend state for directional control, pointer move for cursor tracking, additive blending for breathing overlay, independent blink layer.

**Result:** A character that watches the cursor, blinks naturally, and breathes gently — all in ~30KB.

---

## Common Pitfalls

1. **Trim path on closed paths:** When trim is applied to a closed shape (circle, rectangle), the draw-on effect wraps around the shape. The start point depends on where the path's anchor point is. If the draw starts at an awkward position, adjust the path's starting vertex.

2. **Nested artboard input name collisions:** If your parent and nested artboard both have an input called `isHovering`, they're independent. But it can be confusing when debugging. Use prefixed naming: `btn_isHovering` for the button, `card_isHovering` for the card.

3. **Blend state animation sync:** When blending between two looping animations of different tempos, the blend can look floaty or disconnected. Sync the loop points: if Walk takes 1 second and Run takes 0.5 seconds, the blend will have Walk playing at half the visual speed it should. Match loop durations.

4. **Joystick dead zones:** Without a dead zone, tiny cursor movements near the center create jittery micro-movements. Apply a small dead zone (values within ±0.05 of center snap to center) in your state machine or runtime code.

5. **Nested artboard performance:** Each nested artboard instance runs its own state machine and render pass. 50 nested artboards on one screen will be slow. Keep nesting reasonable — 5–15 instances is fine, 50+ needs profiling.

6. **Additive blend accumulation:** If two additive layers both affect the same property, they stack. A breathing additive + a recoil additive can push a bone beyond its reasonable range. Ensure additive animations use small deltas that compose safely.

---

## Exercises

### Exercise 1: Loading Spinner (Beginner)

Create an animated loading indicator using trim paths.

**Requirements:**
- A circle with a thick stroke (no fill)
- Trim path creates a partial arc (about 90° visible)
- The arc rotates continuously around the circle (animate offset or rotate the entire shape)
- The arc length subtly oscillates (grows and shrinks slightly for organic feel)
- Loop seamlessly

**Success criteria:** A polished, smooth loading spinner that wouldn't look out of place in a shipping product.

---

### Exercise 2: Animated Progress Bar (Intermediate)

Build a progress bar with trim paths and blend states.

**Requirements:**
- A horizontal bar shape with rounded caps
- Trim End animates from 0% to 100% based on a `progress` number input (0–1)
- Color transitions: green at 100%, yellow at 50%, red below 20%
- At `progress == 1.0`: play a completion celebration (sparkle, glow, or bounce)
- The bar fill should have a subtle shimmer animation that plays continuously

**Success criteria:** Scrubbing the `progress` input produces a smooth, color-shifting fill with a rewarding completion effect.

---

### Exercise 3: Nested Component Menu (Intermediate)

Build a menu using nested artboards.

**Requirements:**
- Create a "MenuItem" artboard with hover/press states and a text input for the label
- Create a "Menu" artboard that nests 4 MenuItem instances
- Each MenuItem has a different label (set via exposed text inputs)
- Hovering one MenuItem doesn't affect the others
- Clicking a MenuItem fires a trigger that the parent can read
- The parent state machine tracks which item was last clicked (via a number input)

**Success criteria:** Four independently interactive menu items, all using the same reusable component, with the parent tracking selection state.

---

### Exercise 4: Character Head with Joystick Look (Advanced)

Build a character head with 2D cursor tracking.

**Requirements:**
- Draw a character head with distinct left/right/up/down poses
- 2D blend state with `lookX` and `lookY` inputs
- Pointer move listener maps cursor to inputs (with dampening)
- Additive breathing animation on a separate layer
- Autonomous blink animation on a third layer
- The head should also have hover (slight brightness increase) and click (surprised expression) via listeners

**Success criteria:** A character head that watches the cursor, breathes, blinks, highlights on hover, and reacts to clicks — all running simultaneously.

---

## Recommended Reading & Resources

### Essential (Read First)

- [Rive Trim Paths](https://help.rive.app/editor/fundamentals/trim-paths) — Complete guide to trim path properties and animation
- [Rive Nested Artboards](https://help.rive.app/editor/nested-artboards) — Nesting, input exposure, and multi-instance patterns
- [Rive Blend States](https://help.rive.app/editor/state-machine/blend-states) — 1D and 2D blend state configuration

### Deepening

- [Rive Joystick](https://help.rive.app/editor/state-machine/joystick) — 2D input mapping for directional blending
- [Rive Community Files](https://rive.app/community) — Find examples of trim paths, nested artboards, and blend states in real projects

### Broader Context

- [The Animator's Survival Kit](https://www.amazon.com/Animators-Survival-Kit-Richard-Williams/dp/0571238343) — Richard Williams' masterwork on animation principles. Blend states embody his philosophy of smooth motion.
- [Component-Based Design (Web Parallels)](https://react.dev/learn/thinking-in-react) — React's component model mirrors Rive's nested artboard pattern: reusable, self-contained, composable.

---

## Key Takeaways

1. **Trim paths unlock stroke animation.** Drawing-on effects, loading spinners, progress indicators — all come from animating where a stroke starts and ends.

2. **Nested artboards are components.** Design once, use many times. Each instance has independent state. Changes to the source update all instances.

3. **Blend states eliminate hard cuts.** Wherever a number drives animation — speed, health, direction — blend states create smooth transitions that transitions alone can't match.

4. **Additive blending is for overlays.** Breathing, lean, recoil — small animations that layer on top of whatever's playing. They don't replace the base animation; they modify it.

5. **Joystick input maps 2D space to 2D blending.** Cursor position, analog stick, touch coordinates — all naturally fit the joystick model.

6. **Match animation lengths in blends.** Blending between a 30-frame idle and a 60-frame walk creates timing artifacts. Standardize loop durations across blend entries.

7. **Keep nesting shallow.** Two or three levels of nesting is manageable. Deeper nesting creates debugging headaches and performance overhead.

---

## What's Next

In **[Module 7: Data Binding & Dynamic Content](module-07-data-binding.md)**, you'll connect your animations to runtime data. Text, colors, images, and numbers that change dynamically — all styled and animated within Rive. This is how you build health bars that respond to actual game data, dialogue boxes with live text, and themed interfaces that adapt at runtime.
