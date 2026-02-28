# Module 3: Timeline Animation

**Part of:** [Rive Learning Roadmap](rive-learning-roadmap.md)
**Estimated study time:** 5–7 hours
**Prerequisites:** [Module 2: Bones, Constraints & Rigging](module-02-bones-constraints-rigging.md)

---

## Overview

Modules 1 and 2 gave you artwork and a skeleton. Both are static — they don't move. This module brings them to life.

Timeline animation is the most familiar territory if you've used any animation tool. The core loop is universal: **pose → keyframe → advance time → new pose → keyframe → the tool interpolates between them.** Spine, After Effects, Flash, CSS animations, Blender — they all work this way. If you've animated anywhere before, Rive's timeline will feel immediately recognizable.

But familiarity is a trap. Knowing *how* to set keyframes isn't the same as knowing *how to animate well*. The difference between amateur animation and professional animation isn't technical skill — it's understanding timing, easing, and the principles that make motion feel alive. A perfectly timed blink with proper easing looks better than a complex rig with linear interpolation. This module teaches both: the mechanical how-to of Rive's timeline *and* the principles that make your animations feel good.

You'll create three animations for your character face: a blink, an idle breathing/pulsing motion, and a reaction expression. These aren't arbitrary exercises — they're the raw material for Module 4 (State Machine), where you'll wire these animations together into an interactive system. Build them well here, and the state machine will bring them to life. Build them sloppily, and no amount of state machine logic will make them look good.

---

## Core Concepts

### 1. Animations: Named Timeline Sequences

In Rive, an **animation** is a named, independent timeline sequence within an artboard. One artboard can have as many animations as you need — "idle," "walk," "blink," "wave," "damage," "celebrate." Each animation has its own timeline with its own keyframes, and they're completely independent of each other.

**Creating an animation:**
1. Switch to Animate mode
2. Click the + button in the animations panel (usually bottom-left)
3. Name the animation (descriptively — "blink," not "Animation 1")
4. A new, empty timeline appears
5. Start posing and keyframing

**Animation properties:**
- **Duration:** How long the animation lasts in seconds. You set this by positioning the end marker on the timeline.
- **Loop mode:** Controls what happens when the animation reaches its end:
  - **One-shot:** Plays once and stops. Good for reactions, attacks, transitions.
  - **Loop:** Repeats from the beginning. Good for idle, walk, breathing.
  - **Ping-pong:** Plays forward then backward, repeating. Good for oscillating motions like breathing or bobbing.
- **FPS:** Frames per second. Higher FPS = smoother animation with more granular keyframe placement. 30 or 60 FPS are typical. You can place keyframes at any point on the timeline, not just at frame boundaries.

**Why separate named animations matter:** In the state machine (Module 4), you'll assign these animations to states. The "idle" state plays the "idle" animation. The "blink" state plays the "blink" animation. The state machine transitions between them. If your animations aren't named clearly and built as self-contained units, the state machine becomes a mess.

**Common mistake:** Making one animation that tries to do everything. A single animation called "character" that includes the idle loop, occasional blinks, and random reactions is unmanageable in the state machine. Break behavior into separate, focused animations. Each animation should do *one thing*.

---

### 2. Keyframes: Snapshots of Property Values

A **keyframe** is a snapshot of a property's value at a specific point in time. Between keyframes, Rive interpolates — calculating the in-between values automatically.

**What can be keyed (animated):**
Almost any property in Rive can be keyframed:
- **Transform properties:** Position (X, Y), rotation, scale (X, Y), skew
- **Visual properties:** Opacity, fill color, stroke color, stroke width
- **Shape properties:** Corner radius, path vertex positions, mesh vertex positions
- **Constraint properties:** IK strength, constraint weight
- **Special properties:** Solo/visibility, draw order, clip state

The ability to key vertex positions is worth highlighting. In most animation tools, a shape's silhouette is fixed — you can move, rotate, and scale it, but you can't change its form. In Rive, if you have a pen path, you can keyframe individual vertex positions. A smile morphs into a frown by moving the mouth path's middle vertex from curved-up to curved-down. No shape swapping needed.

**Keying modes:**
- **Manual keying (recommended for beginners):** You explicitly click the keyframe button to create a key. This gives you full control — only the properties you intentionally key are keyframed. If you change the head rotation and the eye position, you choose whether to key both, one, or neither.
- **Auto-key (faster, less control):** When auto-key is enabled, any change you make to any property automatically creates a keyframe at the current timeline position. Faster for iterative work but easy to accidentally keyframe properties you didn't mean to change.

**Setting a keyframe:**
1. Move the timeline playhead to the desired time
2. Change a property (rotate a bone, change a fill color, move a shape)
3. Click the keyframe button (or press the key shortcut) to set the key
4. Move the playhead to a new time and repeat

**Removing a keyframe:**
Select the key on the timeline and delete it. The property will now interpolate between the surrounding keys (or snap to the previous key if there's only one).

**Common mistake:** Forgetting to keyframe the starting pose. If you create a keyframe at frame 10 but not at frame 0, the property has no defined starting value. Rive will interpolate from wherever the value happens to be. Always set a key at the beginning of your animation to define the starting state explicitly.

---

### 3. Interpolation: The Soul of Animation

Interpolation is how Rive calculates values between keyframes. This is where the difference between "robotic" and "alive" animation lives. The same two keyframes (head at 0° and head at 30°) can look completely different depending on how the interpolation is set.

**Three interpolation types:**

**Linear:** The value changes at a constant rate. The object moves the same amount every frame. This looks mechanical and robotic — nothing in the real world moves at a constant speed. Objects accelerate, decelerate, overshoot, and settle. Linear interpolation ignores all of this.

**When to use linear:** Almost never for character animation. Occasionally useful for: purely mechanical motion (a clock hand, a scrolling ticker), UI elements that need to feel "digital" (a loading bar filling at constant speed), or as a creative choice for deliberate robotic aesthetics.

**Hold (Stepped):** The value stays at the current key's value until the next keyframe, then snaps instantly to the new value. No in-between values. This creates "frame-by-frame" animation — the property jumps between states.

**When to use hold:** Visibility changes (show/hide), color snaps (instantly change from green to red), sprite-sheet-style frame switching (solo frame 1, then snap to solo frame 2), or any case where a gradual transition would look wrong.

**Cubic Bezier (Curves):** The value follows a bezier curve between keyframes. This is what you'll use 95% of the time. Bezier curves let you control acceleration and deceleration — the object starts slow, speeds up, and slows down again (ease-in-out), or starts fast and decelerates (ease-out), or starts slow and accelerates (ease-in).

**Common easing patterns:**
- **Ease-out:** Starts fast, decelerates to a stop. Use for: things arriving at a destination (a menu sliding into position, a character landing after a jump). The motion feels natural because things in the real world decelerate due to friction.
- **Ease-in:** Starts slow, accelerates. Use for: things leaving (a menu sliding away, a character leaping up). The motion feels like gathering momentum.
- **Ease-in-out:** Starts slow, speeds up in the middle, slows down at the end. Use for: most character motion. A head turning starts from rest (ease-in), reaches full speed mid-turn, and decelerates as it settles into position (ease-out). This is the most natural-looking easing for organic motion.
- **Overshoot (spring):** Passes the target value, bounces back, and settles. Achieved with a bezier curve that extends beyond the target before curving back. Use for: bouncy, energetic motion (a button that bounces into place, a character's head that overshoots when turning quickly).

---

### 4. The Graph Editor: Where You Control Easing

The graph editor is the visual representation of interpolation curves. Instead of seeing keyframes as dots on a timeline, you see them as points on a value-over-time graph, connected by curves.

**Reading the graph editor:**
- **X-axis:** Time (left to right)
- **Y-axis:** Property value (bottom to top)
- **The curve shape** shows exactly how the value changes over time
- **Steep sections** = fast change (the value is changing a lot per unit of time)
- **Flat sections** = slow change or no change
- **Points above the end value** = overshoot (the value goes past the target before settling back)

**Editing curves:**
- Select a keyframe on the graph
- Drag the bezier handles to reshape the curve
- Longer handles = more gradual easing
- Handles pointing up from the left key = ease-out (fast start, slow end)
- Handles pointing up into the right key = ease-in (slow start, fast end)
- Both = ease-in-out

**Copying curves:** Once you find an easing curve you like, you can copy its handle positions to other keyframes. Many animators develop a personal library of favorite curves — a "standard ease-out," a "bouncy overshoot," a "slow settle."

**Why the graph editor matters:** Most beginners never open the graph editor. They set keyframes, see the motion, and think "good enough." But the graph editor is where you turn "good enough" into "professional." Spending 5 minutes adjusting curves after keyframing is the highest-value time you'll spend on any animation.

**Common mistake:** Ignoring the graph editor and using default easing. Rive's default interpolation is fine but generic. Opening the graph editor and adjusting curves for even one or two key properties (the most visible ones) dramatically improves animation quality.

---

### 5. Timing: The Other Half of Animation

Easing controls *how* a value changes. Timing controls *when* and *for how long*. Both matter equally, and beginners tend to focus on easing while neglecting timing.

**Timing principles:**

**Faster = lighter, snappier, more energetic.** A blink that takes 0.1 seconds feels quick and natural. A blink that takes 0.5 seconds feels sleepy or drugged. A button press response in 0.08 seconds feels snappy. The same response in 0.3 seconds feels sluggish.

**Slower = heavier, more deliberate, more dramatic.** A heavy robot arm moving to position over 1.5 seconds feels weighty. A UI panel sliding in over 0.6 seconds feels smooth and deliberate. A slow fade-out over 2 seconds feels dramatic.

**Hold times create rhythm.** Not everything should be in constant motion. A character blinks (0.15 seconds), then holds their expression (2 seconds), then blinks again. The hold time — the stillness between motions — is as important as the motion itself. Without holds, everything feels frenetic. With too much hold, everything feels dead.

**Offsets create natural-looking motion.** If a character's head and body start moving at the exact same frame, it looks mechanical. If the eyes start moving first (frame 0), then the head follows (frame 3), then the body follows (frame 5), it looks natural. This is called **overlapping action** — different parts start and stop at different times, cascading through the body.

**Key timing values for reference:**
- Eye blink: 0.1–0.2 seconds total (fast close, slightly slower open)
- Head turn: 0.2–0.4 seconds (depends on how far)
- UI button response: 0.05–0.15 seconds (must feel instant)
- Menu slide-in: 0.3–0.5 seconds (smooth, not sluggish)
- Idle breathing cycle: 2–4 seconds per breath (slow, rhythmic)
- Surprised reaction: 0.1–0.2 seconds to full expression, then 0.5+ second hold

---

### 6. The 12 Principles Applied to Rive

Disney's 12 Principles of Animation apply to every animation tool. Here's how each one manifests in Rive work:

**1. Squash and Stretch**
Objects compress and stretch during motion to convey weight and elasticity. In Rive, this is achieved by keyframing scale — a bouncing ball squashes (scaleY compressed, scaleX expanded) on impact and stretches (scaleY expanded, scaleX compressed) mid-air. A character's head might squash slightly on a downward nod and stretch slightly when snapping upward in surprise.

**2. Anticipation**
A small motion in the opposite direction before the main action. Before a character jumps up, they crouch down briefly. Before a button flies off-screen to the right, it shifts slightly left. In Rive, this means adding a small preparatory keyframe before the main motion.

**3. Staging**
Directing the viewer's attention. In Rive, this means animating the important elements prominently and keeping secondary elements subdued. An achievement popup should animate boldly (scale up, glow, bounce), while the background game UI dims or holds still.

**4. Straight Ahead vs. Pose to Pose**
Two animation approaches. **Straight ahead** (animating frame by frame sequentially) works for chaotic, unpredictable motion. **Pose to pose** (defining key poses first, then filling in breakdowns) works for controlled, deliberate motion. In Rive, pose-to-pose is the standard workflow — set your key poses, then adjust the interpolation between them.

**5. Follow-Through and Overlapping Action**
Different parts of a character stop at different times. Hair keeps swinging after the head stops. Ears bounce after a landing. In Rive, this means offsetting keyframes — the main body stops at frame 10, the hair settles at frame 14, the ears at frame 16. Everything arrives at the same destination but at different times.

**6. Slow In and Slow Out (Ease In, Ease Out)**
This is the easing section above. Every motion should accelerate out of stillness and decelerate into stillness. In Rive, this means bezier curves on every keyframe. No linear interpolation for organic motion.

**7. Arcs**
Natural motion follows curves, not straight lines. An arm swinging moves in an arc, not a straight line from point A to point B. In Rive, if you're animating position, add intermediate keyframes that pull the path into an arc rather than letting linear interpolation create a straight line.

**8. Secondary Action**
Supporting actions that complement the main action. While a character walks (primary), their arms swing (secondary), their hair bounces (secondary), and their expression shifts (secondary). In Rive, use separate state machine layers for secondary actions so they can run independently of the primary animation.

**9. Timing**
Covered above. The speed and rhythm of the animation.

**10. Exaggeration**
Push beyond realism for clarity and appeal. A surprised face doesn't just open the eyes slightly — the eyes go WIDE, the eyebrows fly UP, the mouth drops OPEN. In Rive, don't be afraid to exaggerate key poses. Subtle, realistic animation often reads as dead on screen.

**11. Solid Drawing**
In traditional animation, this means drawing with volume and weight. In Rive, it means designing shapes that feel three-dimensional through shading, perspective hints, and consistent lighting direction. Covered more in Module 1, but relevant during animation when you're adjusting poses.

**12. Appeal**
The animation should be pleasing to watch. This is subjective but practical: smooth easing, satisfying timing, appropriate exaggeration, clean motion paths. If something looks "off" but you can't explain why, it's often a violation of appeal — check your easing curves and timing.

---

### 7. Building Your First Animations

Here's the practical walkthrough for creating the three animations you need for Module 4.

**Animation 1: Blink**

A blink is the simplest animation that makes a character feel alive. Without it, even a beautifully designed face feels like a painting.

Mechanics:
1. Create a new animation called "blink" (duration: ~0.4 seconds, one-shot)
2. Frame 0: Eyes fully open (key the eye scale at 1.0 on both axes)
3. Frame ~0.08s: Eyes closed (key the eye scaleY at 0.0 or near 0.0 — the eyes become a thin line)
4. Frame ~0.2s: Eyes fully open again (scaleY back to 1.0)

Key details:
- The close is *fast* (0.08s). The open is *slower* (0.12s). Blinks in real life are asymmetric — the close is quicker than the open.
- Use ease-out on the close (fast snap) and ease-in-out on the open (gentle return).
- Both eyes should blink simultaneously (same keyframe times). Asynchronous blinks look creepy — unless that's the effect you want.
- The scaleY animation squashes the eye shape to a line. If your eyes are designed as groups (eyeball + pupil), you might scale the entire eye group.

**Animation 2: Idle**

An idle animation is subtle, continuous motion that makes a character feel alive even when "doing nothing." Think of it as the character breathing.

Mechanics:
1. Create a new animation called "idle" (duration: 3–4 seconds, loop mode)
2. Frame 0: Neutral pose (key the head/body scale and position at default)
3. Mid-point (~1.5-2s): Slightly shifted pose:
   - Head or body scaleY at ~1.02 (subtle "inhale" expansion)
   - Head position shifted up by 1-2 pixels (chest rising during inhale)
4. End: Same as frame 0 (for seamless loop)

Key details:
- **Subtlety is everything.** An idle that's too pronounced looks like the character is hyperventilating. Scale changes of 1-3% and position shifts of 1-3 pixels are typical. If you can notice the idle on first glance, it's too much.
- Use smooth ease-in-out curves. Breathing is the most natural motion — it should feel effortless.
- The last frame should match the first frame exactly (same values) for a seamless loop. Rive can handle this with loop mode, but matching values ensures there's no visible jump.
- Consider adding a very subtle head tilt oscillation (rotation ±0.5°) layered on top of the breathing. This adds "life" without looking like intentional motion.

**Animation 3: Reaction (Surprise)**

A reaction animation demonstrates expression changes — the kind of animation the state machine will trigger in response to user input.

Mechanics:
1. Create a new animation called "surprise" (duration: ~0.8-1.0 seconds, one-shot)
2. Frame 0: Neutral face (keyframe everything at default pose)
3. Frame ~0.1s: Peak surprise expression:
   - Eyebrows raised (rotation or position up)
   - Eyes wide (scaleY at 1.2-1.3, making them larger)
   - Mouth open (jaw bone rotated, or mouth path vertices shifted to an "O" shape)
   - Head tilted back slightly (rotation)
   - Optional: subtle head scale-up (1.03) for a "pop" effect
4. Frame ~0.5s: Hold the surprise expression (same values as peak — this is the "read" time, letting the viewer register the expression)
5. Frame ~0.9s: Return to neutral (all values back to default)

Key details:
- **The snap to surprise is fast** (0.1s). The hold is substantial (0.4s). The return is slow (0.4s). This rhythm — fast in, hold, slow out — is the standard for reaction animations.
- Use aggressive ease-out on the snap (fast, then decelerating). Use gentle ease-in on the return (gradually accelerating back to neutral).
- **Exaggerate the peak.** A subtle surprise reads as "mildly confused." A big surprise — eyebrows high, eyes wide, mouth open — reads clearly as surprise. You can always dial it back, but start big.
- Consider an **overshoot** on the eyebrows: they pop up past their peak position and bounce back down slightly before settling. This one detail adds enormous life to the reaction.

---

### 8. Looping: Seamless Cycles

Many animations need to loop — idle breathing, walk cycles, blinking patterns, pulsing effects. A bad loop has a visible "hitch" where the end snaps back to the beginning. A good loop is invisible — you can't tell where it starts or ends.

**Rules for seamless loops:**

**Rule 1: Match first and last frames.** The last keyframe's values should exactly match the first keyframe's values. If the head is at rotation 0° on frame 0, it should be at rotation 0° on the last frame.

**Rule 2: Match the velocity at the boundary.** Matching values isn't enough — the *rate of change* at the loop point must also match. If the head is decelerating into the last frame, it should be accelerating out of the first frame at the same rate. This is why ease-in-out works well for loops — both ends are at zero velocity.

**Rule 3: Use ping-pong for simple oscillations.** If your animation goes from A to B and back to A, use ping-pong loop mode instead of duplicating the keyframes. The animation plays forward (A → B), then backward (B → A), then forward again. This automatically matches values and velocity at the boundaries.

**Rule 4: Don't key the last frame redundantly in ping-pong mode.** If the animation goes 0 → 1 → 0 in ping-pong, you only need keys at 0 and 1. The tool plays 0 → 1 then reverses to 1 → 0 automatically. If you also put a key at 0 on the last frame, the animation goes 0 → 1 → 0, then ping-pongs back to 0 → 1 → 0 — you'll get a double-length pause at the zero position.

**Common mistake:** Creating a loop by copying the first frame to the last frame position. This can work, but you need to make sure the interpolation curves also match at the boundary. The safest approach for simple loops is ping-pong mode.

---

### 9. Work Keyframes: Non-Exported Control Points

Rive has a concept of **work keyframes** (also called work area or keying helpers in some contexts) — keyframe data that exists for your editing convenience but doesn't export in the final animation.

The main use case: setting a "rest pose" keyframe at frame -1 (or a frame outside the animation's work area) so that you always have a reference point to return to. If you accidentally mess up a pose, you can copy from the rest pose keyframe.

**Practical tip:** Before you start keyframing an animation, set a complete keyframe of the neutral pose at the very beginning. Key every bone at its rest position, every shape at its default state. This gives you an explicit "home" to return to if things get weird.

---

## Case Studies

### Case Study 1: The Perfect Blink

Study any high-quality animated character (Disney, Pixar, or well-made Rive community files) and observe the blink:

**Anatomy of a professional blink:**
- Duration: 0.12-0.2 seconds total
- Close phase: 0.04-0.06 seconds (2-3 frames at 60fps). The upper lid moves down fast. The lower lid barely moves (or moves up slightly).
- Closed hold: 0.02-0.04 seconds (1-2 frames). The eyes are fully closed for a barely perceptible moment.
- Open phase: 0.06-0.1 seconds (3-5 frames). Slightly slower than close. The upper lid moves up with a slight overshoot (opens past neutral, then settles back).
- Easing: The close uses ease-out (fast snap). The open uses ease-in-out with a slight overshoot curve.

**Why this level of detail matters:** A blink is the most frequent animation in any character. It happens every 3-5 seconds in idle mode. If the blink feels wrong — too slow, too mechanical, too symmetrical — the character feels "off" even if the viewer can't articulate why. Spending an extra 10 minutes perfecting your blink is time well spent.

### Case Study 2: Idle Breathing That Doesn't Suck

Bad idle animations are everywhere — characters that bob up and down like buoys, or breathe so aggressively they look like they just ran a marathon. Here's how to avoid that:

**Good idle breathing is invisible until you look for it.** The viewer should feel that the character is alive without consciously noticing the motion. Achieve this with:

- **Tiny values:** Scale oscillation of 1-2%, position shift of 1-3 pixels. If you think "is this even doing anything?" — it's probably the right amount.
- **Long cycle:** 3-4 seconds per breath. Short cycles (1-2 seconds) feel hyperactive.
- **Asymmetric timing:** The inhale (expansion) is slightly slower than the exhale (contraction). In nature, inhaling is active (muscles engage) while exhaling is passive (muscles relax). Mimic this with slightly different easing.
- **Multiple channels:** Don't just scale the whole character. The chest expands slightly, the shoulders rise slightly, the head moves up a tiny amount. Different rates and timings on each create organic-feeling motion.

### Case Study 3: UI Element Transitions

Timeline animation isn't just for characters. UI elements need polished motion too:

**Button hover effect:**
- Duration: 0.15-0.2 seconds
- Scale: 1.0 → 1.05 (5% larger)
- Easing: ease-out (snaps to larger size, feels responsive)
- Optional: subtle brightness/color shift, shadow scale increase

**Menu panel slide-in:**
- Duration: 0.3-0.5 seconds
- Position: starts offscreen, ends at final position
- Easing: ease-out with slight overshoot (slides past position, bounces back)
- Staggered children: each menu item delays by 0.05s, creating a cascade effect

**Notification popup:**
- Enter: scale from 0 → 1.1 → 1.0 (overshoot bounce), 0.2-0.3 seconds
- Hold: visible for 2-3 seconds
- Exit: scale from 1.0 → 0 or slide up with fade, 0.2 seconds
- Easing: enter uses springy ease-out, exit uses ease-in (accelerates away)

---

## Common Pitfalls

1. **Linear interpolation on everything.** The #1 beginner mistake. Linear motion looks robotic. Use bezier curves (ease-in, ease-out, ease-in-out) on every keyframe. The only exception is intentionally mechanical motion.

2. **Animations that are too fast or too slow.** Real blinks are 0.15 seconds. Real head turns are 0.2-0.4 seconds. Real breathing cycles are 3+ seconds. Study real-world timing references. When in doubt, err slightly faster for UI and slightly slower for character motion.

3. **No holds between motions.** If every frame has something moving, the animation feels frenetic. Use hold times (frames with no change) to create rhythm. Blink — hold 2 seconds — blink. Not blink-blink-blink-blink.

4. **Everything starts at the same frame.** When a head turns, the eyes should lead (frame 0), then the head follows (frame 2-3), then secondary elements like hair follow (frame 4-5). This overlapping action is what makes motion feel natural.

5. **Forgetting to keyframe the starting pose.** Always set a keyframe at frame 0 for every property you're animating. Without an explicit starting key, the animation's initial state is undefined.

6. **Identical ease curves on all keyframes.** Different motions need different easing. A quick snap needs aggressive ease-out. A gentle settle needs soft ease-in-out. A bounce needs overshoot. Vary your curves based on the character of each motion.

7. **Not testing the loop.** Play your looping animation for 30+ seconds. Watch for hitches at the loop point, gradual drift, or timing that feels monotonous. A loop that looks fine for one cycle can reveal problems over extended playback.

8. **Animating too many properties at once.** Start by animating the most important property (rotation, position, or scale). Get the timing and easing right for that one property. Then layer on additional properties. Trying to keyframe everything simultaneously leads to a mess of conflicting timing.

---

## Exercises

### Exercise 1: The Blink (Beginner, 30 minutes)

Create a "blink" animation for your character face:

Requirements:
- Duration: 0.3-0.5 seconds, one-shot mode
- Eyes close by scaling Y to near-zero (not to exactly zero — a thin line reads better than invisible)
- Close is faster than open (asymmetric timing)
- Ease-out on the close, ease-in-out on the open
- Both eyes blink simultaneously
- Test by playing the animation — the blink should feel quick, natural, and satisfying

Bonus: Add an eyebrow micro-dip during the blink (eyebrows lower by 1-2 pixels as the eyes close, then return). This subtle detail makes the blink feel connected to the face rather than just an eye animation.

### Exercise 2: The Idle (Beginner-Intermediate, 45 minutes)

Create an "idle" animation for your character:

Requirements:
- Duration: 3-4 seconds, loop or ping-pong mode
- Subtle breathing motion (scale oscillation of 1-3%)
- At least two properties animated (e.g., scaleY + slight position shift + slight rotation)
- Seamless loop (no visible hitch)
- The motion should be nearly invisible — if someone watches your character and doesn't consciously notice the idle, it's working

Test: Play the idle for 30 seconds. Does it feel alive without being distracting? Is the loop seamless?

### Exercise 3: The Reaction (Intermediate, 45 minutes)

Create a "surprise" reaction animation:

Requirements:
- Duration: 0.8-1.2 seconds, one-shot mode
- Fast snap to the surprised expression (0.1-0.15 seconds)
- Hold at peak expression (0.3-0.4 seconds)
- Gradual return to neutral (0.3-0.5 seconds)
- At minimum: eyebrows raised, eyes widened, mouth changed
- Easing: aggressive ease-out on the snap, gentle ease-in on the return
- Exaggerated — the surprise should be clearly readable, not subtle

Bonus: Add overshoot on the eyebrows (they pop past their peak and bounce back before holding).

### Exercise 4: Graph Editor Exploration (Intermediate, 30 minutes)

Take your blink animation and open the graph editor. For the eye scale property:

1. Look at the default curves. What shape are they?
2. Adjust the curves to make the blink feel more "springy" — add overshoot on the open phase (eyes open past 1.0 scale, then settle back to 1.0)
3. Adjust to make the blink feel "lazy" — slow the close, extend the closed hold, slow the open
4. Adjust to make the blink feel "nervous" — make everything faster, shorter hold, maybe asymmetric (one eye slightly leads the other by 1 frame)

The goal: experience how curve shape directly controls the *feel* of animation. Same keyframes, same values, but dramatically different results based on curves alone.

### Exercise 5: Timing Study (Intermediate, 30 minutes)

Create three variations of a simple head turn (head rotates 30° to the right, then back):

1. **Snappy:** Total duration 0.3s, aggressive easing, slight overshoot
2. **Heavy:** Total duration 0.8s, soft easing, slow start, slow end
3. **Mechanical:** Total duration 0.5s, linear interpolation (intentionally robotic)

Play all three side by side (or sequentially). Notice how the same motion — same bone, same start/end values — feels completely different based on timing and easing alone. This is the most important lesson in animation.

---

## Recommended Reading & Resources

**Tier 1 — Do Now:**
- [Rive Animate Mode](https://help.rive.app/editor/animate-mode) — official animation documentation
- [Rive Graph Editor](https://help.rive.app/editor/animate-mode/graph-editor) — curve editing reference
- [Rive Interpolation](https://help.rive.app/editor/animate-mode/interpolation) — interpolation types and settings

**Tier 2 — Deepen Your Understanding:**
- [The Animator's Survival Kit (book)](https://www.amazon.com/Animators-Survival-Kit-Principles-Classical/dp/086547897X) by Richard Williams — the definitive text on animation principles. Dense, thorough, and applicable to every tool.
- [12 Principles of Animation (Wikipedia)](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation) — quick reference for Disney's principles

**Tier 3 — Inspiration:**
- Browse Rive community files with smooth character animation. Open them in the editor and study their keyframe timing and curve shapes. How do the best animators handle blinks? Idle? Reactions?
- Watch any Pixar "making of" content about character animation. The principles translate directly to 2D and to Rive.

---

## Key Takeaways

1. **Animations are named, independent timeline sequences.** One animation per behavior. "blink," "idle," "surprise" — not "do-everything."

2. **Almost any property can be keyframed.** Transforms, colors, opacity, vertex positions, constraint strengths. If it's in the inspector, you can probably animate it.

3. **Easing is non-negotiable.** No linear interpolation for organic motion. Use bezier curves (ease-in, ease-out, ease-in-out) on every keyframe. Open the graph editor and adjust.

4. **Timing is half the animation.** Fast = snappy and light. Slow = heavy and deliberate. Holds create rhythm. Offsets create natural-feeling motion.

5. **The 12 Principles apply everywhere.** Especially: anticipation, follow-through, overlapping action, ease in/out, exaggeration, and appeal. These aren't abstract — they're concrete keyframing decisions.

6. **Test your loops.** Play them for 30+ seconds. Look for hitches, drift, or monotony. Match first/last frame values and velocity.

7. **Build separate, focused animations.** Each animation does one thing. The state machine (Module 4) combines them. This separation is what makes Rive's interactive workflow possible.

---

## What's Next

**[Module 4: The State Machine →](module-04-state-machine.md)**

You now have three animations: blink, idle, and a surprise reaction. They're independent timeline clips — they play when you hit play, and that's it. Module 4 wires them together into an interactive system using Rive's visual state machine. This is where your character stops being an animation and starts being a reactive entity.
