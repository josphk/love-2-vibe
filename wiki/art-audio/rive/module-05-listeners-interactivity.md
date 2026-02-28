# Module 5: Listeners & Interactivity

[← Back to Rive Learning Roadmap](rive-learning-roadmap.md)

**Time estimate:** 2–4 hours
**Prerequisites:** Module 4 (state machine fundamentals — inputs, transitions, layers)

---

## Overview

You've built state machines that respond to input values — but so far, you've been toggling those inputs manually in the editor's test panel. Listeners close the gap between state machines and real user interaction. They detect pointer events (hover, click, drag, cursor position) on specific shapes and automatically set state machine inputs in response.

The result: fully interactive animations that respond to the user, entirely designed in the Rive editor. No code. A button that highlights on hover, presses on click, and fires an action — all self-contained in the .riv file. A character whose eyes track the cursor. A menu that responds to mouse position with parallax depth.

Listeners are what make Rive a genuine interactive design tool rather than just an animation tool. In traditional workflows, the designer creates the visual assets and the developer writes the interaction code. In Rive, the designer builds the interaction directly.

### Learning Objectives

By the end of this module, you will be able to:

1. Attach listeners to specific shapes for targeted hit detection
2. Use pointer enter/exit events to drive hover states
3. Use pointer down/up events to drive press states
4. Implement cursor tracking for look-at effects and parallax
5. Chain listeners with state machines for complete interactive behaviors

---

## Core Concepts

### 1. Listener Basics

A listener is an event handler attached to a specific shape (or group of shapes) in your artboard. When the user interacts with that shape, the listener fires and performs an action — typically setting a state machine input.

**The listener pipeline:**

```
User hovers over a shape
        ↓
Listener detects "pointer enter" on that shape
        ↓
Listener sets boolean input `isHovering` to true
        ↓
State machine transition fires (condition: isHovering == true)
        ↓
Hover animation plays
```

Every step in this pipeline is configured visually in the Rive editor. The shape defines the hit area. The listener defines the event and action. The state machine defines the response.

**Adding a listener:**

1. Select a shape (or group) that should be the hit target
2. In the State Machine editor, add a new listener
3. Set the listener's target to your selected shape
4. Choose the event type (pointer enter, exit, down, up, move)
5. Define the action (set a boolean, fire a trigger, set a number)

**Why it matters:** Listeners make interaction a design concern, not a development concern. A designer can build, test, and refine interactive behaviors without waiting for a developer to wire up event handlers. When the runtime loads the .riv file, all interactions just work.

**Common mistake:** Forgetting to set a hit target. A listener without a target shape won't detect anything. The target defines the clickable/hoverable area — it can be invisible (zero opacity) if you want a hit area that doesn't correspond to a visible element.

**Try this now:** Create a circle shape. Add a state machine with a boolean input `isHovering`. Create a listener that targets the circle, listens for "pointer enter," and sets `isHovering` to true. Add another listener for "pointer exit" that sets `isHovering` to false. Create two states (Normal, Hover) with transitions conditioned on `isHovering`. Preview and hover over the circle.

---

### 2. Pointer Enter and Exit (Hover Detection)

Pointer enter fires when the cursor moves onto the target shape. Pointer exit fires when the cursor moves off. Together, they create hover detection.

**Hover pattern (the standard approach):**

| Event | Action |
|-------|--------|
| Pointer enter | Set `isHovering` = true |
| Pointer exit | Set `isHovering` = false |

Your state machine transitions then respond: Normal → Hover when `isHovering == true`, Hover → Normal when `isHovering == false`.

**Hit area design:**

The target shape defines the interactive area. This has design implications:

- **Exact shape hit area:** Use the visible shape as the target. The hover area exactly matches what the user sees. Precise but can feel finicky on small or irregular shapes.
- **Expanded hit area:** Create an invisible rectangle slightly larger than the visible element. Set it to zero opacity. Use it as the listener target. More forgiving for users — follows Fitts's law.
- **Grouped hit area:** Target a group containing multiple shapes. The hover area is the union of all shapes in the group. Useful for composite elements like a button with text and icon.

**Nested hover areas:**

When shapes overlap, the topmost shape in the draw order gets the event first. If a small button sits on top of a larger panel, hovering the button fires the button's listener, not the panel's. This matches web CSS behavior — events propagate based on visual stacking.

**Why it matters:** Hover feedback is the most fundamental interaction affordance. Users need to know "this thing is clickable." Without hover effects, interactive elements feel dead. With them, the interface feels responsive and alive.

**Common mistake:** Creating hover effects with noticeable transition delays. Hover feedback should feel instant — 50–100ms maximum. If the hover animation takes 500ms to ramp up, the interface feels sluggish. Fast in, slightly slower out (100ms in, 200ms out) feels best.

**Try this now:** Build a rectangular button with text. Add two listeners: pointer enter (set `isHovering` = true) and pointer exit (set `isHovering` = false). In the state machine, create Normal and Hover states. The Hover animation should scale the button slightly (1.05x), brighten the fill color, and maybe shift a drop shadow. Set transition duration to 100ms in, 200ms out. Test in preview — the button should feel responsive.

---

### 3. Pointer Down and Up (Click/Press Detection)

Pointer down fires when the user presses the mouse button (or touches on mobile) while over the target shape. Pointer up fires when they release.

**Press pattern:**

| Event | Action |
|-------|--------|
| Pointer down | Set `isPressed` = true |
| Pointer up | Set `isPressed` = false |
| Pointer up | Fire `onClick` trigger |

Notice the dual action on pointer up: reset the press state AND fire the click trigger. The press boolean controls the visual depression (scale down, darken). The click trigger fires the actual action (navigate, submit, toggle).

**Why pointer up for click (not pointer down):**

This follows standard UI convention. Users expect to be able to press a button, drag off it to cancel, and release without triggering the action. If you fire the action on pointer down, there's no opportunity to cancel. The sequence should be:

1. Pointer down → visual press (feedback)
2. If user drags off → pointer exit → cancel visual press
3. If user releases on button → pointer up → fire action

**State machine for a complete button:**

States: Normal, Hover, Pressed
Transitions:
- Normal → Hover (isHovering == true)
- Hover → Normal (isHovering == false)
- Hover → Pressed (isPressed == true)
- Pressed → Hover (isPressed == false)

Separate onClick trigger for the action itself — this can trigger effects, navigation, or be read by runtime code.

**Why it matters:** Press feedback tells users their click registered. Without the visual depression on pointer down, users aren't sure they're clicking in the right place. The tactile metaphor (button pushes in, then pops back) is deeply ingrained in UI expectations.

**Common mistake:** Firing the action on pointer down instead of pointer up. This prevents click cancellation and feels jarring. The visual change goes on pointer down (immediate feedback), but the action goes on pointer up (allow cancellation).

**Try this now:** Extend your button from the previous exercise. Add pointer down (set `isPressed` = true) and pointer up (set `isPressed` = false, fire `onClick`). Add a Pressed state where the button scales to 0.95x and darkens slightly. Add transition Hover → Pressed (isPressed == true) and Pressed → Hover (isPressed == false). Test in preview — you should feel the button depress on click and pop back on release.

---

### 4. Cursor Tracking (Pointer Move)

Pointer move fires continuously as the cursor moves over the target shape (or the artboard). Instead of setting a boolean or firing a trigger, it maps the cursor's X and Y positions to number inputs. This enables real-time cursor-following behavior.

**How it works:**

1. Create two number inputs: `pointerX` and `pointerY`
2. Add a pointer move listener targeting the artboard (or a large invisible hit area)
3. Configure the listener to map cursor position to `pointerX` and `pointerY`
4. Use these number inputs to drive transforms — rotation, position, blend states

**Eye tracking pattern:**

The most iconic cursor tracking use case: eyes that follow the mouse.

Setup:
- Two number inputs: `lookX` and `lookY`
- Pointer move listener maps cursor position to these inputs
- Each eye pupil's position is bound to the inputs via constraints or blend states
- The result: wherever the cursor goes, the character watches

Implementation options:
- **Direct position binding:** Map `lookX`/`lookY` directly to pupil X/Y offset. Simple but can look mechanical.
- **Constraint-based:** Use Rive's transform constraints to point the pupil toward the cursor position. More natural rotation.
- **Blend-state-based:** Create four poses (look left, right, up, down) and use a 2D blend state driven by `lookX`/`lookY`. Most control over the final look.

**Parallax effect:**

Map cursor position to background layer offsets at different rates. Close layers move more, far layers move less. Creates depth illusion.

- Background: `offsetX = pointerX * 0.02`
- Midground: `offsetX = pointerX * 0.05`
- Foreground: `offsetX = pointerX * 0.10`

This can be set up with number inputs driving position offsets on different groups.

**Why it matters:** Cursor tracking creates the most visceral "this thing is alive" reaction in users. Characters that watch the cursor, environments that shift with mouse position, UI elements that respond to proximity — these effects are memorable and create emotional connection.

**Common mistake:** Making cursor tracking too sensitive. If the pupils move 1:1 with the cursor, they'll fly off the face when the cursor is at screen edge. Dampen the range — the pupils should move within a small radius (a few pixels) even when the cursor is far away. Rive's input ranges let you clamp this.

**Try this now:** Create a simple face with two eyes. Add `lookX` and `lookY` number inputs. Set up a pointer move listener on the artboard that maps cursor X to `lookX` and cursor Y to `lookY`. Offset each pupil's position based on these inputs (using keyframes or constraints). Preview and move your mouse around — the eyes should follow.

---

### 5. Listener-State Machine Chains

The real power emerges when you chain multiple listeners and state machine layers together into complex interactive behaviors.

**Chain pattern:**

```
Listener Event → Sets Input → State Machine Transition → Plays Animation
                                                              ↓
                                                   Animation changes shape
                                                              ↓
                                               New shapes are now hover targets
                                                              ↓
                                                 New listeners can fire
```

**Example: Expandable card**

1. Card is in Collapsed state, showing a title
2. User hovers → pointer enter → `isHovering = true` → subtle grow/glow
3. User clicks → pointer up → `onClick` trigger → transition to Expanded state
4. Expanded state reveals more content with animation
5. New "close" button appears (animated in)
6. User clicks close button → pointer up → `onClose` trigger → transition back to Collapsed
7. Collapsed animation plays

**Example: Multi-step interaction**

1. Character stands idle, eyes tracking cursor (pointer move listener)
2. User hovers character body → pointer enter → `isHovering = true` → character perks up
3. User clicks → pointer up → `onClick` trigger → character waves (one-shot animation)
4. Wave animation has an exit time transition back to idle
5. Character returns to idle with eyes still tracking

**Event bubbling and conflicts:**

When interactions get complex, events can conflict. A button inside a panel: does clicking the button also click the panel? In Rive, the topmost target shape consumes the event. Design your hit areas carefully to avoid unintended double-triggers.

**Why it matters:** Chaining is how you build real interactive products in Rive. A menu system, a game UI, a character selection screen — they're all chains of listeners, inputs, transitions, and animations working together.

**Common mistake:** Not accounting for state when adding listeners. A listener fires regardless of what state the state machine is in. If you have a click listener on a button that's currently hidden (opacity 0 but still present), the click still registers. Either move the hidden element off-artboard, or add state machine conditions that prevent the click from having an effect in the current state.

**Try this now:** Build a character face that combines all the interactions from this module: eyes track the cursor (pointer move), the face highlights on hover (pointer enter/exit), and clicking triggers a reaction animation (pointer down/up with trigger). This should use two state machine layers: one for cursor tracking (always active) and one for hover/click reactions.

---

## Case Studies

### Case Study 1: Rive's Own Interactive Logo

**The design:** The Rive logo on their website isn't static — it responds to cursor position and clicks. The diamond shapes shift based on mouse proximity, creating a living, breathing logo.

**How it's built:**
- A pointer move listener on the full artboard tracks cursor position
- Number inputs map cursor X/Y to shape transforms
- Each shape has a different sensitivity (closer shapes react more)
- A click trigger plays a burst animation

**Key takeaway:** Even branding can be interactive. The interaction doesn't just look nice — it communicates Rive's core value proposition: "animation that responds to you."

---

### Case Study 2: Interactive Character Picker

**The problem:** A game needs a character selection screen where players preview characters before choosing.

**The design:**

Three character artboards nested in a selection screen artboard.

Each character (nested artboard):
- Eyes follow cursor (pointer move → `lookX`, `lookY`)
- Hover state: character brightens, does a small wave or bounce (pointer enter → `isHovering`)
- Click state: character does a celebration animation (pointer up → `onSelect` trigger)
- Not-selected state: character dims and idles (set by parent state machine)

Parent artboard:
- Manages which character is "active" via number input `selectedCharacter`
- Routes click events: when character 1 is clicked, set `selectedCharacter = 1`
- Confirm button appears after selection, with its own hover/press states

**Key takeaway:** Nested artboards with their own listeners create reusable interactive components. The character artboard knows how to respond to hover/click internally. The parent just manages selection state.

---

### Case Study 3: Cursor-Responsive Game Menu

**The problem:** A game menu should feel alive, not static. Background elements should respond to cursor position.

**The design:**

Three parallax layers + interactive buttons:

1. **Background layer:** Mountain landscape. Pointer move shifts mountains slowly (`offsetX * 0.02`). Creates subtle depth.
2. **Midground layer:** Floating particles/motes. Pointer move affects drift direction (`offsetX * 0.05`). Particles cluster loosely toward the cursor.
3. **Foreground layer:** Menu buttons. Each button has its own hover/press listeners and state machine. Buttons are close enough to the cursor that they have the strongest parallax response.

**Additional touch:** A character in the background whose head tracks the cursor. The character doesn't interact with clicks — it just watches. This subtle detail makes the menu feel inhabited.

**Key takeaway:** Layered pointer move listeners at different sensitivities create depth and life. The menu is technically functional (buttons work), but the ambient interactivity makes it memorable.

---

## Common Pitfalls

1. **Invisible shapes blocking events:** A transparent shape with opacity 0 still receives pointer events if it's a listener target. If you have an invisible shape on top of your buttons, it will intercept clicks. Either remove it from the render hierarchy or ensure it's not a listener target.

2. **Listener targets on groups vs shapes:** Targeting a group makes the entire group's bounding box interactive. This can be larger than the visible shapes. If your button group includes a text label with extra whitespace, the hit area extends into that whitespace. Target the specific background shape of the button instead.

3. **Cursor tracking without clamping:** If pointer move maps cursor position directly to a number input without range limits, extreme cursor positions create extreme animations. Eyes roll off the face, parallax layers scroll off screen. Always clamp your number inputs to a reasonable range.

4. **Missing pointer exit handling:** If you set `isHovering = true` on pointer enter but forget to set `isHovering = false` on pointer exit, the element stays in hover state permanently once triggered. Always pair enter with exit.

5. **Pointer move performance:** Pointer move fires on every frame the cursor moves. If the handler drives complex blend states or many transforms, performance can dip. Keep pointer-move-driven calculations simple — offset a few transforms, don't recalculate an entire scene.

6. **Touch vs mouse differences:** On mobile, there's no hover. Pointer enter fires on touch-down, and pointer exit fires on touch-up. Design your interactions to work without hover as a separate state — hover enhancement is fine, hover requirement is not.

7. **Click-through on overlapping elements:** When multiple listener targets overlap, only the topmost one receives the event. If your close button overlaps with the card background, make sure the close button is drawn on top. Rive uses draw order, not z-index.

---

## Exercises

### Exercise 1: Interactive Toggle (Beginner)

Build a toggle switch that responds to clicks.

**Requirements:**
- A pill-shaped background with a circular knob
- Click listener on the entire toggle area
- Each click fires a trigger that toggles between On and Off states
- On state: knob slides right, background turns green
- Off state: knob slides left, background turns gray
- Transition duration: 200ms

**Success criteria:** Clicking the toggle switches between On and Off smoothly in both directions.

---

### Exercise 2: Button with Full Interaction (Intermediate)

Build a polished button with hover, press, and click feedback.

**Requirements:**
- Rounded rectangle button with centered text label
- Expanded invisible hit area (10px padding around the visible button)
- Pointer enter/exit for hover (scale to 1.05x, brighten)
- Pointer down/up for press (scale to 0.95x, darken)
- Click trigger (fires on pointer up) plays a ripple/burst effect
- The ripple effect plays once and returns to idle
- All transitions should feel snappy (100–150ms)

**Success criteria:** The button feels genuinely clickable — responsive hover, satisfying press, and a celebratory click effect.

---

### Exercise 3: Character with Eye Tracking (Intermediate)

Build a character face with cursor-following eyes.

**Requirements:**
- Simple character face (head, two eyes with pupils, eyebrows, mouth)
- Pointer move listener on the full artboard
- Pupils follow cursor position with dampened range (pupils move max 5px in any direction)
- Hover over the face: slight expression change (eyebrows raise, subtle smile)
- Click on the face: play a reaction animation (surprise, wink, or wave)

**Bonus:** Add eyelid blink on an autonomous timer (separate state machine layer) that works independently of tracking and reactions.

**Success criteria:** The character feels alive — watching you, reacting to your proximity, and responding to clicks.

---

### Exercise 4: Interactive Card Gallery (Advanced)

Build a horizontal row of three cards that expand on click.

**Requirements:**
- Three card shapes, each with a title and thumbnail
- Hover: card lifts (shadow grows, slight scale up)
- Click: card expands to show full content (description text, larger image area), other cards shrink/dim
- Expanded card has a close button (with its own hover/press states)
- Clicking close returns to the gallery view
- Only one card can be expanded at a time

**Success criteria:** The gallery feels like a real UI component — responsive hover, smooth expand/collapse, and clear state management.

---

## Recommended Reading & Resources

### Essential (Read First)

- [Rive Listeners Documentation](https://help.rive.app/editor/state-machine/listeners) — Complete reference for listener types and configuration
- [Rive State Machine](https://help.rive.app/editor/state-machine) — Review state machine fundamentals (listeners build on this)

### Deepening

- [Rive Community Interactive Examples](https://rive.app/community) — Browse files tagged with "interactive" to see listener patterns in practice
- [Rive Data Binding](https://help.rive.app/editor/data-binding) — Preview of how dynamic data feeds into the same input system listeners use

### Broader Context

- [Designing for Interaction (Nielsen Norman Group)](https://www.nngroup.com/) — Interaction design principles that inform how you design hover, click, and feedback states
- [Fitts's Law](https://en.wikipedia.org/wiki/Fitts%27s_law) — The fundamental law of target acquisition that explains why hit area size matters

---

## Key Takeaways

1. **Listeners are the bridge between user input and state machines.** They detect pointer events on specific shapes and translate them into input changes that drive transitions.

2. **Always pair enter with exit.** Every pointer enter listener needs a corresponding pointer exit listener to reset the state. Forgetting this creates stuck states.

3. **Hit area design matters.** The target shape defines what's interactive. Use expanded invisible hit areas for better usability, especially on small elements.

4. **Visual feedback should be immediate.** Hover and press states should respond in under 150ms. Sluggish interaction feedback makes the entire experience feel broken.

5. **Cursor tracking creates life.** Pointer move listeners driving number inputs can make characters watch, environments breathe, and interfaces feel spatial.

6. **Design for touch, too.** Mobile has no hover state. Ensure your interactions work with just press/release — hover should enhance, not gate, the experience.

7. **Chain listeners with layers for complex behavior.** One layer handles cursor tracking (always active), another handles hover/press states, another handles action results. Layers keep complex interactions manageable.

---

## What's Next

In **[Module 6: Advanced Animation Techniques](module-06-advanced-animation.md)**, you'll expand your animation toolkit with trim paths, nested artboards, blend states, and joystick inputs. These techniques let you create effects that go beyond basic keyframes — self-drawing paths, reusable component systems, and smooth multi-dimensional blending.
