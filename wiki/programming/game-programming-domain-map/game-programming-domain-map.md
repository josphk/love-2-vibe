# Game Programming Domain Map

A curated vocabulary reference for game programming. Use these terms to prompt AI tools with specificity — each entry includes a plain-language definition and an example prompt showing the term in context.

**How to use this page:** Scan the branch that matches your programming challenge. Grab the precise term, drop it into your prompt, and get better results than vague descriptions ever produce.

---

## Game Architecture

How games are structured at the code level.

### Game Loop & Lifecycle

The heartbeat of every game — how code runs frame after frame.

- **Game Loop** — The central while-loop that drives a game: process input, update state, render. Every frame is one trip through this loop. Everything else hangs off it.
  *"Write a game loop in Lua/LOVE2D that separates update and draw, handles variable frame rates, and caps at 60 FPS."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+loop+diagram+update+draw+cycle)

- **Fixed Timestep** — Running physics and game logic at a constant interval (e.g., 60 times per second) regardless of frame rate. Prevents physics from breaking on fast or slow machines.
  *"Implement a fixed timestep loop with accumulator so my physics runs at 60Hz even when rendering drops to 30 FPS."*

- **Delta Time** — The elapsed time since the last frame, usually in seconds. Multiply movement by delta time so a character moves the same distance per second whether the game runs at 30 or 144 FPS.
  *"My character moves twice as fast on a 120Hz monitor. Show me how to multiply velocity by dt to fix this."*

- **Frame Rate Independence** — Designing game logic so behavior is identical regardless of how many frames per second the hardware produces. Delta time is the primary tool, but not the only concern.
  *"What are the gotchas of frame-rate-independent movement beyond just multiplying by dt? How do I handle jump height consistency?"*

- **Initialization** — The startup phase where a game loads assets, sets up the window, creates initial objects, and prepares state before the loop begins. In LOVE2D, this is `love.load()`.
  *"Structure a love.load() function that initializes the physics world, loads a tilemap, spawns the player, and sets up the camera."*

- **Update/Draw Separation** — Keeping game logic (movement, collision, AI) in an update function and rendering (sprites, UI, effects) in a separate draw function. Mixing them causes bugs and limits optimization.
  *"Refactor my LOVE2D code so that no game state changes happen inside love.draw() — all logic should live in love.update()."*

- **Tick** — A single execution of the game's update logic. In a fixed-timestep game, one tick always represents the same duration (e.g., 1/60th of a second). Decoupled from rendering frames.
  *"My server runs at 20 ticks per second. How do I interpolate entity positions on the client between ticks for smooth visuals?"*

- **Double Buffering** — Drawing to an off-screen buffer while the previous frame is displayed, then swapping them. Prevents the player from seeing a half-drawn frame (screen tearing).
  *"Explain double buffering vs. triple buffering. When would I choose one over the other for a 2D pixel art game?"*

- **VSync** — Synchronizing frame presentation with the monitor's refresh rate. Eliminates tearing but can introduce input lag. A tradeoff every game must decide on.
  *"My game feels laggy with vsync on but tears with it off. What's the best approach for a fast-paced action game?"*

- **Game Clock** — A timer system that tracks elapsed time, can be paused, slowed, or sped up independently of real time. Powers slow-motion effects, pause menus, and timed events.
  *"Implement a game clock that supports pause, slow-motion (0.5x), and fast-forward (2x) without affecting UI animations."*

### State Management

Controlling what the game is doing right now and what it should do next.

- **State Machine** — A programming pattern where an object can be in exactly one state at a time (idle, running, jumping) and transitions between states based on conditions. The workhorse of game logic.
  *"Build a state machine for a platformer character with idle, run, jump, fall, and wall-slide states. Show the transition conditions."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+state+machine+diagram+character+states)

- **Finite State Machine (FSM)** — A state machine with a fixed, enumerated set of states. Simple to implement and debug. Works great until the number of states and transitions explodes.
  *"When should I upgrade from a simple FSM to a behavior tree for my enemy AI? What are the warning signs?"*

- **State Stack** — A stack data structure that holds game states. Pushing a pause menu on top of gameplay preserves the gameplay state underneath. Popping returns to it.
  *"Implement a state stack so I can push a pause screen over gameplay, then push an options menu over that, and pop back through both."*

- **Pushdown Automaton** — A state machine with a stack, allowing states to "remember" what came before. The formal name for a state stack. Useful when you need to return to a previous state cleanly.
  *"Model my game's screen flow (title → level select → gameplay → pause → gameplay) as a pushdown automaton."*

- **Game State** — A distinct mode the game can be in: main menu, playing, paused, cutscene, game over. Each state typically has its own update and draw logic.
  *"Define game states for a roguelike: menu, dungeon, inventory, shop, boss fight, death screen. How should transitions work?"*

- **Transition** — The trigger and process of moving from one state to another. Can be instant (cut to game over) or animated (fade between scenes). Clean transitions prevent state corruption.
  *"Add a fade-to-black transition between my menu and gameplay states. The fade should take 0.5 seconds each way."*

- **State Pattern** — An object-oriented design pattern where each state is its own class/table with enter, exit, update, and draw methods. Cleaner than giant if-else chains.
  *"Refactor my player's movement code from a big if-else block into the state pattern, with each state as a separate table in Lua."*

- **Blackboard** — A shared data store that multiple systems or AI agents can read from and write to. Decouples systems that need to share information without direct references.
  *"Set up a blackboard for my AI system where enemies can post 'player last seen at position X' and other enemies can read it."*

- **Global State** — Game-wide state accessible from anywhere: current level, score, player lives, settings. Convenient but dangerous if overused — makes code harder to test and reason about.
  *"What's the best way to manage global state in LOVE2D? Should I use a global table, a singleton, or dependency injection?"*

- **State Serialization** — Converting the current game state into a saveable format (JSON, binary, etc.) and restoring it later. The foundation of save/load systems and undo/redo.
  *"Serialize my game state to JSON, handling circular references between entities and their inventory items."*

### Entity Systems

How game objects are represented, organized, and composed.

- **Entity** — A game object: a player, an enemy, a bullet, a tree. In ECS, an entity is just an ID — a number that components attach to. In OOP, it's an object with data and behavior.
  *"What's the simplest way to represent entities in a Lua-based game? Tables with type fields vs. ECS vs. class inheritance?"*

- **Component** — A chunk of data attached to an entity. A Position component holds x, y. A Health component holds current and max HP. Components carry data, not behavior.
  *"Design components for a top-down shooter: Position, Velocity, Sprite, Health, Damage, Collider. What data does each hold?"*

- **System** — A function that processes all entities with a specific set of components. A MovementSystem updates all entities with Position and Velocity. Systems carry behavior, not data.
  *"Write a MovementSystem that queries all entities with Position and Velocity components, applying velocity * dt to position each frame."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=entity+component+system+ECS+architecture+diagram)

- **Entity-Component-System (ECS)** — An architecture where entities are IDs, components are data bags, and systems are logic processors. Favors composition over inheritance. Dominates modern game engines.
  *"Implement a minimal ECS in Lua with addEntity, addComponent, getEntitiesWith, and a system runner."*

- **Game Object** — The traditional OOP approach: each entity is an object that inherits from a base class and overrides update/draw. Simpler than ECS but leads to deep inheritance hierarchies.
  *"Compare a GameObject hierarchy (Enemy → FlyingEnemy → Dragon) vs. ECS composition (entity + Flying + Fire + Health). When is each better?"*

- **Composition over Inheritance** — The design principle that building behavior by combining small, reusable components is more flexible than inheriting from deep class trees. The philosophy behind ECS.
  *"My enemy class hierarchy is 6 levels deep and I need a flying enemy that can also swim. Show me how composition solves this."*

- **Archetype** — A unique combination of component types. All entities with {Position, Sprite, Health} share an archetype. Some ECS implementations store entities by archetype for cache efficiency.
  *"Explain archetype-based ECS storage and why it's faster than storing components in separate hash maps per entity."*

- **Entity ID** — A unique identifier (usually an integer) that represents an entity. Systems look up components by entity ID. Keeps entities lightweight — just a number, not an object.
  *"Should my entity IDs be sequential integers, UUIDs, or recycled from a pool? What are the tradeoffs for a networked game?"*

- **Component Pool** — A contiguous array that stores all instances of a single component type. Entity ID indexes into the pool. Keeps data cache-friendly and iteration fast.
  *"Implement a component pool in Lua using a dense array with an ID-to-index map for O(1) lookup and cache-friendly iteration."*

- **Prefab** — A predefined template for creating entities with a specific set of components and default values. Spawn a "Goblin" prefab and get an entity with Position, Health(30), Sprite("goblin.png"), and AI.
  *"Create a prefab system where I define entity templates in data files and spawn them with one function call."*

- **Spawning** — Creating a new entity at runtime — instantiating a bullet when the player fires, adding an enemy when a wave starts, dropping a pickup when an enemy dies.
  *"Write a spawn system that creates bullet entities at the player's position with velocity matching the aim direction."*

### Memory & Performance

Making games run fast and use memory wisely.

- **Object Pool** — Pre-allocating a fixed number of objects and recycling them instead of creating and destroying on demand. Eliminates garbage collection pauses for frequently spawned objects like bullets.
  *"Implement a bullet pool of 200 objects in Lua. When a bullet deactivates, return it to the pool instead of letting it get garbage collected."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=object+pool+pattern+game+programming+diagram)

- **Garbage Collection** — Automatic memory reclamation for objects that are no longer referenced. Convenient but causes unpredictable pauses. Lua, JavaScript, and C# all have GC; C and C++ do not.
  *"My LOVE2D game stutters every few seconds. How do I profile Lua's garbage collector and reduce GC pressure?"*

- **Spatial Locality** — Storing data that's accessed together close together in memory. When the CPU loads one piece of data, nearby data comes free via the cache line. Arrays beat linked lists for this reason.
  *"Reorganize my entity data from an array of structs to a struct of arrays for better cache performance during the physics update."*

- **Cache-Friendly** — Code and data layouts that play well with the CPU cache. Iterating over a contiguous array is cache-friendly. Chasing pointers through scattered heap objects is cache-hostile.
  *"Why is iterating a component pool 10x faster than iterating a table of entity objects in Lua? Explain with cache lines."*

- **Profiling** — Measuring where your game spends its time and memory. Profile before optimizing — intuition about bottlenecks is usually wrong. Tools: LOVE2D's built-in profiler, Lua profilers, frame graphs.
  *"Show me how to add a simple frame-time profiler to my LOVE2D game that displays a bar graph of update vs. draw time."*

- **Draw Call Batching** — Combining multiple draw operations into fewer GPU calls. Drawing 1000 sprites with the same texture in one batch is vastly faster than 1000 individual draw calls.
  *"My game drops to 30 FPS when drawing 2000 tiles. How do I use a SpriteBatch in LOVE2D to batch them into a single draw call?"*

- **Lazy Evaluation** — Deferring computation until the result is actually needed. Don't recalculate pathfinding every frame if the target hasn't moved. Don't rebuild the spatial hash until something moves.
  *"Add dirty flags to my tilemap renderer so it only rebuilds the SpriteBatch when tiles actually change."*

- **Flyweight Pattern** — Sharing immutable data between many objects instead of duplicating it. All goblins share the same sprite, animation data, and base stats. Only position and current HP are unique per instance.
  *"Implement the flyweight pattern for my particle system so 10,000 particles share one texture and color table."*

- **Memory Arena** — A large pre-allocated block of memory that objects are allocated from sequentially. Deallocation frees the entire arena at once. Extremely fast and prevents fragmentation.
  *"When would a memory arena make sense in a Lua game? Can I approximate arena allocation patterns even with GC?"*

- **Hot Path** — The code that runs most frequently — typically the inner loops of update, physics, and rendering. Optimize hot paths ruthlessly. Don't bother optimizing code that runs once at startup.
  *"Identify the hot path in my collision detection and show me how to optimize it without changing the algorithm."*

---

## Physics & Collision

Making things move and interact in game space.

### Collision Detection

Figuring out when and where game objects touch.

- **AABB** — Axis-Aligned Bounding Box. A rectangle that doesn't rotate, aligned with the X and Y axes. The fastest collision check: just compare min/max coordinates. Good enough for most 2D games.
  *"Write an AABB vs. AABB overlap test in Lua that returns true/false and the overlap depth on each axis."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=AABB+axis+aligned+bounding+box+collision+detection)

- **Bounding Box** — A simple shape (rectangle, circle, capsule) that approximates an object's area for collision purposes. Cheaper than checking every pixel. Tighter bounding shapes cost more but give better accuracy.
  *"My character sprite is 32x48 but the actual body is only 16x40. How do I set a tighter bounding box for fair collisions?"*

- **Circle Collision** — Testing if two circles overlap by checking if the distance between centers is less than the sum of radii. Rotation-invariant and dirt cheap. Great for bullets, pickups, and explosions.
  *"Implement circle-vs-circle collision for my twin-stick shooter's bullet-enemy interactions."*

- **SAT (Separating Axis Theorem)** — A general collision test for convex polygons. If you can find an axis that separates two shapes, they don't collide. More expensive than AABB but handles rotated shapes.
  *"Implement SAT collision between two rotated rectangles in Lua, returning the minimum translation vector to resolve the overlap."*

- **Broad Phase** — The first pass of collision detection that quickly eliminates pairs that can't possibly collide. Uses spatial structures (grids, quadtrees) to avoid checking every pair against every other pair.
  *"Add a spatial hash broad phase so my game only checks collisions between objects in the same or adjacent cells."*

- **Narrow Phase** — The precise collision check between pairs that survived the broad phase. This is where AABB, SAT, or pixel-perfect tests happen. Expensive but only runs on candidates.
  *"After my broad phase returns 50 candidate pairs from 500 entities, run narrow-phase AABB checks on just those pairs."*

- **Collision Layer/Mask** — A filtering system that controls which types of objects can collide with which. Players collide with enemies and walls but not with their own bullets. Set via bitmasks or named layers.
  *"Set up collision layers so player bullets hit enemies, enemy bullets hit the player, and neither bullet type hits its own team."*

- **Hitbox/Hurtbox** — Separate collision shapes for dealing damage (hitbox — the sword swing) and receiving damage (hurtbox — the character's body). Fundamental to fighting games and action games.
  *"Implement hitbox/hurtbox separation for a melee combat system where the sword hitbox is only active during the attack animation frames."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=hitbox+hurtbox+fighting+game+collision+frames)

- **Overlap vs. Collision** — An overlap detects that two shapes are intersecting. A collision resolves the intersection by pushing objects apart. Some systems need detection only (triggers); others need full resolution (walls).
  *"Make my pickup items use overlap-only detection (trigger a collect event) while walls use full collision resolution (push the player out)."*

- **Trigger Volume** — An invisible collision shape that detects entry/exit but doesn't physically block movement. Used for area transitions, dialogue triggers, damage zones, and event activation.
  *"Create a trigger volume at the dungeon entrance that starts a cutscene when the player walks into it."*

### Rigid Body Dynamics

The physics of objects that don't bend — how forces make things move.

- **Rigid Body** — A physics object that moves and rotates as a solid unit. Has mass, velocity, and responds to forces. The building block of physics simulations — everything from crates to characters.
  *"Add rigid body physics to my crates so the player can push them and they slide, stack, and topple realistically."*

- **Velocity** — Speed with direction. A vector (vx, vy) that describes how fast and in which direction an object moves. Position changes by velocity * dt each frame.
  *"Implement velocity-based movement where the player accelerates to a max speed and decelerates with friction when no input is pressed."*

- **Acceleration** — The rate of change of velocity. Applying acceleration over time creates smooth speed-up and slow-down instead of instant starts and stops.
  *"Add acceleration and deceleration to my character's horizontal movement so it feels weighty instead of instant."*

- **Force** — Something that changes an object's acceleration based on its mass (F = ma). Gravity is a constant downward force. A rocket applies an upward force. Forces accumulate each frame.
  *"Apply a wind force that pushes all lightweight entities to the right but barely affects heavy ones."*

- **Impulse** — An instantaneous change in velocity, ignoring mass. Used for things that should happen immediately: a jump, an explosion knockback, a bullet hit. Unlike forces, impulses apply in one frame.
  *"Apply a knockback impulse to enemies when hit by the player's sword, scaling with damage dealt."*

- **Torque** — Rotational force. Makes objects spin. A force applied off-center creates torque — kick a ball at its edge and it spins. Relevant for top-down vehicles, spinning obstacles, ragdolls.
  *"Apply torque to my top-down car's rigid body when the player steers, so it rotates realistically through turns."*

- **Mass** — How much an object resists changes in velocity. Heavier objects need more force to move. In collisions, mass determines who pushes whom. Setting mass to infinity makes an object immovable.
  *"Set up mass ratios so the player can push small crates but large crates require two players to move."*

- **Restitution (Bounciness)** — A value (0 to 1) that controls how much energy is preserved in a collision. 0 means no bounce (clay). 1 means perfect bounce (super ball). Controls how "lively" collisions feel.
  *"Make my ball entity bounce off walls with 0.8 restitution so it loses a little energy with each bounce and eventually stops."*

- **Friction** — Resistance to sliding along a surface. High friction stops objects quickly (rubber on concrete). Low friction lets them slide (ice). Applies to both movement and collision contacts.
  *"Implement surface-specific friction so my platformer character slides on ice tiles but grips normally on stone tiles."*

- **Gravity Vector** — The constant acceleration applied to all physics bodies, usually pointing downward. In a platformer it's (0, 980). In a space game it might be (0, 0). Can be changed per-entity or globally.
  *"Let the player flip gravity direction with a button press, changing the gravity vector from (0, 980) to (0, -980)."*

### Movement & Kinematics

How characters and objects move in a game — especially the feel-good tricks that make platformers satisfying.

- **Kinematic Body** — A physics body that moves via code rather than forces. You set its velocity directly instead of applying forces. Ideal for player characters where you want precise control over movement.
  *"Set up my player as a kinematic body that moves via direct velocity control but still collides with static environment tiles."*

- **Platformer Physics** — The customized, unrealistic physics that make platformers feel good. Real physics feels terrible for jumping — game physics uses higher gravity, coyote time, and variable jump height.
  *"Implement platformer physics with fast-fall (3x gravity when falling), variable jump height, and snappy ground acceleration."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=platformer+physics+jump+curve+diagram)

- **Coyote Time** — A short grace period after walking off a ledge where the player can still jump. Named after Wile E. Coyote running off cliffs. Typically 80-150ms. Makes platforming feel forgiving.
  *"Add 100ms of coyote time so the player can still jump for a few frames after leaving a platform edge."*

- **Jump Buffering** — Accepting a jump input slightly before the player lands and executing it the moment they touch ground. Prevents the frustration of pressing jump "one frame too early." Typically 100-150ms.
  *"Implement a 120ms jump buffer so pressing jump while airborne near the ground triggers a jump on landing."*

- **Ground Detection** — Determining whether a character is standing on solid ground. Usually done with a short raycast or overlap check below the character's feet. Gets tricky on slopes and moving platforms.
  *"Implement ground detection using a thin rectangle cast below the player that handles slopes, one-way platforms, and moving platforms."*

- **Raycasting** — Shooting an invisible line through the game world and finding what it hits first. Used for line-of-sight checks, ground detection, bullet trajectories, and laser beams.
  *"Use raycasting to check if the enemy has line of sight to the player, ignoring transparent objects but stopping at walls."*

- **Wall Sliding** — Slowing the player's fall when pressed against a wall, often combined with wall jumping. The player slides down at a reduced gravity rate. Core to many platformers.
  *"Implement wall sliding that reduces fall speed to 25% and enables a wall jump that pushes the player away from the wall."*

- **Dash** — A burst of rapid movement, usually with invincibility frames. The player presses a button and zips in a direction. Requires cooldown management and collision handling during the dash.
  *"Add an 8-directional dash with a 0.15-second duration, invincibility frames during the dash, and a 0.8-second cooldown."*

- **Lerp/Slerp** — Linear interpolation (lerp) blends between two values: `a + (b - a) * t`. Slerp does the same for rotations on a sphere. The foundation of smooth movement, camera following, and animations.
  *"Use lerp to smoothly move my camera toward the player's position each frame instead of snapping instantly."*

- **Easing Functions** — Mathematical curves that control the rate of change over time. Ease-in starts slow, ease-out ends slow, ease-in-out does both. Makes movement and animations feel natural instead of robotic.
  *"Apply an ease-out-quad function to my door opening animation so it decelerates smoothly as it reaches the open position."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=easing+functions+curves+ease+in+out+quad+cubic)

### Spatial Partitioning

Dividing game space into regions so you don't check every object against every other object.

- **Quadtree** — A tree structure that recursively divides 2D space into four quadrants. Objects are stored in the smallest quad that contains them. Efficient for unevenly distributed objects.
  *"Implement a quadtree for my 2D space shooter that subdivides when a cell contains more than 8 entities."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=quadtree+spatial+partitioning+2D+game)

- **Octree** — The 3D version of a quadtree, dividing space into eight octants. Used in 3D games for collision, rendering culling, and lighting. Same principle, one more dimension.
  *"When would I use an octree vs. a spatial hash for my 3D voxel game's collision detection?"*

- **Spatial Hash** — Dividing space into a grid of cells and hashing each object into its cell. O(1) lookup for nearby objects. Simpler than quadtrees and often faster for uniformly distributed objects.
  *"Implement a spatial hash with 64px cells for my bullet hell game's collision detection between hundreds of bullets and enemies."*

- **Grid-Based Collision** — Using the tilemap grid itself as the collision structure. Check which grid cells an object overlaps and test against tiles in those cells. Simple and fast for tile-based games.
  *"Use my existing 32px tilemap grid for collision detection instead of adding a separate spatial structure."*

- **Sweep and Prune** — Sorting objects along an axis and only checking overlaps between objects that are adjacent in the sorted order. Good for scenes with many objects that don't move much.
  *"Explain sweep and prune collision detection and when it outperforms a spatial hash."*

- **Bounding Volume Hierarchy (BVH)** — A tree of nested bounding shapes. The root contains everything; each child is a tighter bound on a subset. Queries walk the tree, pruning branches that don't intersect.
  *"When would I choose a BVH over a quadtree for my 2D game with lots of dynamic objects?"*

- **Cell** — A single unit in a spatial grid or hash. Objects register in their cell(s). Collision queries check the target cell and its neighbors. Cell size should roughly match the largest object.
  *"What cell size should I use for my spatial hash if most entities are 16-32px but some bosses are 128px?"*

- **Neighbor Query** — Finding all objects within a certain distance of a point. The spatial structure lets you check only nearby cells instead of every object in the world.
  *"Query my spatial hash for all enemies within 200px of the player to update only nearby AI, ignoring distant entities."*

- **Frustum Culling** — Not drawing objects that are outside the camera's visible area. In 2D, this means skipping sprites outside the viewport rectangle. Can cut draw calls dramatically in large levels.
  *"Add frustum culling to my tilemap renderer so it only draws tiles visible in the current camera viewport."*

- **Level of Detail (LOD)** — Using simpler representations for distant objects. A faraway tree might be a billboard instead of a 3D model. In 2D, distant parallax layers might skip animation frames.
  *"Implement LOD for my large-scale 2D RTS so units far from the camera render as simple colored dots instead of full sprites."*

---

## Rendering & Graphics

Drawing things on screen.

### 2D Rendering

Getting pixels onto the screen — the visual core of 2D games.

- **Sprite** — A 2D image drawn at a position in the game world. The basic visual building block. A character, a tree, a bullet — if you can see it, it's probably a sprite.
  *"Load a sprite from a PNG file in LOVE2D and draw it centered at the player's position, accounting for the sprite's origin."*

- **Sprite Sheet** — A single image containing multiple sprite frames arranged in a grid or packed layout. Loading one large image is faster than loading hundreds of small ones.
  *"Load a 512x512 sprite sheet and define quads for a 16-frame walk animation with 32x32 frames."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=sprite+sheet+game+animation+grid+frames)

- **Texture Atlas** — A sprite sheet optimized by a packing tool that arranges sprites of varying sizes as tightly as possible. Comes with a data file mapping sprite names to positions and dimensions.
  *"Generate a texture atlas from my 200 individual sprite PNGs using TexturePacker and load it in LOVE2D with the accompanying data file."*

- **Draw Order / Z-Sorting** — Controlling which sprites appear in front of others. In a top-down game, characters lower on screen should draw on top of characters higher on screen. In a platformer, layers handle depth.
  *"Implement y-sorting for my top-down RPG so characters and objects with higher y-positions draw in front of those behind them."*

- **Blending Mode** — How a sprite's pixels combine with what's already on screen. Normal replaces pixels. Additive adds brightness (great for fire, lasers). Multiply darkens (shadows). Alpha blends transparency.
  *"Draw my particle effects with additive blending so overlapping fire particles glow brighter instead of looking opaque."*

- **Render Target** — An off-screen canvas you can draw to instead of the screen. Draw your game to a render target, then apply post-processing effects (blur, CRT filter) before drawing the result to screen.
  *"Render my game at 320x180 to a canvas, then scale it up to the window size with nearest-neighbor filtering for crisp pixel art."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=render+target+offscreen+buffer+post+processing+pipeline)

- **Batch Rendering** — Combining many sprites that share the same texture into a single draw call. LOVE2D's SpriteBatch does this. The difference between 60 FPS and 10 FPS when drawing thousands of tiles.
  *"Convert my tilemap rendering from individual love.graphics.draw() calls to a SpriteBatch for a 10x performance boost."*

- **Pixel-Perfect Rendering** — Ensuring that pixel art renders without sub-pixel blurring, scaling artifacts, or shimmer during movement. Requires integer scaling, snapping to pixel boundaries, and nearest-neighbor filtering.
  *"Set up pixel-perfect rendering in LOVE2D: nearest-neighbor filter, integer camera coordinates, and a low-res canvas scaled up."*

- **Resolution Scaling** — Rendering the game at a base resolution (e.g., 320x180) and scaling up to the display resolution. Keeps pixel art consistent across different monitor sizes.
  *"Handle resolution scaling so my 320x180 pixel art game fills a 1920x1080 window with letterboxing and integer scaling."*

- **Viewport** — The rectangular region of the game world currently visible on screen. Defined by position, size, and optionally rotation and zoom. Moving the viewport is how cameras and scrolling work.
  *"Calculate the viewport rectangle from my camera's position and zoom level, then only draw entities within it."*

### Animation

Making things move within a frame and across time.

- **Sprite Animation** — Playing through a sequence of sprite frames over time. Frame 1 for 0.1s, frame 2 for 0.1s, etc. The simplest and most common animation in 2D games.
  *"Implement a sprite animation system that plays a sequence of quads from a sprite sheet with configurable frame duration and looping."*

- **Frame** — A single image in an animation sequence. A walk cycle might have 6 frames. A sword swing might have 4. More frames = smoother animation but more memory and art work.
  *"How many frames should a walk cycle have for a 32x32 pixel art character? What about an idle animation?"*

- **Keyframe** — A frame that defines a specific pose or value. Other frames are interpolated between keyframes. In code, a keyframe might set position, rotation, or scale at a specific time.
  *"Define keyframes for a UI panel that slides in from the right: start off-screen at t=0, ease to center at t=0.3s."*

- **Tweening** — Automatically generating intermediate values between two keyframes. Short for "in-betweening." Move a health bar smoothly from 80 to 50 instead of jumping instantly.
  *"Tween my damage number text from scale 2.0 to 1.0 with ease-out over 0.3 seconds while moving it upward."*

- **Skeletal Animation** — Defining a skeleton of connected bones and moving sprites by rotating bones rather than swapping frames. Uses far fewer images and allows blending between animations.
  *"Compare skeletal animation vs. frame-by-frame for my fighting game character. What are the tradeoffs in file size, quality, and implementation?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=skeletal+animation+2D+spine+bones+game)

- **Animation State Machine** — A state machine specifically for animation — idle plays the idle anim, running plays the run anim, transitions can blend between them. Separate from gameplay state machines.
  *"Build an animation state machine for my character: idle → run (when moving), run → jump (when jump pressed), jump → fall (when vy > 0), fall → idle (when grounded)."*

- **Animation Blend** — Smoothly transitioning between two animations over a short duration instead of snapping instantly. The run animation fades out while the idle animation fades in over 100ms.
  *"Blend between my character's run and idle animations over 150ms so the transition doesn't pop."*

- **Easing** — Applying an easing function to animation timing. A linear tween looks robotic. An ease-out tween decelerates naturally. Easing is the difference between "functional" and "polished" animation.
  *"Apply ease-in-out-cubic to my menu panel sliding animation for a satisfying, polished feel."*

- **Spine / DragonBones** — Popular 2D skeletal animation tools. Artists create bone rigs and animate in the tool, then export data that a runtime library reads. Professional-quality animation with efficient file sizes.
  *"Integrate Spine animations into my LOVE2D project using the spine-love runtime. How do I trigger animation changes from gameplay code?"*

- **Flip / Mirror** — Rendering a sprite horizontally or vertically flipped. Draw the right-facing sprite with scaleX = -1 when facing left. Halves the number of animation frames needed.
  *"Flip my character sprite based on movement direction using negative scaleX instead of maintaining separate left-facing animations."*

### Tilemaps & Levels

Building game worlds from reusable pieces.

- **Tilemap** — A grid-based level layout where each cell references a tile type. Memory-efficient (store indices, not images) and tooling-friendly (Tiled editor). The backbone of 2D level design.
  *"Load a Tiled JSON tilemap in LOVE2D, create a SpriteBatch from the tile layer, and render it with camera scrolling."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=tilemap+game+level+tiled+editor+grid)

- **Tile** — A single cell in a tilemap, typically 16x16, 32x32, or similar. Contains a reference to a tile image/ID and optionally properties like "solid," "slippery," or "damaging."
  *"Define tile properties in my tilemap data so I can check if a tile is solid, climbable, or a one-way platform."*

- **Tileset** — The palette of tile images available for painting a tilemap. A single tileset image with IDs mapping to positions. Often includes terrain, decorations, and interactive elements.
  *"Create a tileset with 16x16 grass, dirt, stone, and water tiles that can auto-tile naturally against each other."*

- **Auto-Tiling** — Automatically selecting the correct tile variant based on neighboring tiles. A wall tile surrounded by other walls uses an interior texture; one next to open space uses an edge texture.
  *"Implement 4-bit auto-tiling (checking cardinal neighbors) for my cave walls so they automatically pick correct edge sprites."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=autotiling+bitmask+tilemap+game+development)

- **Tile Layers** — Multiple tilemap layers stacked on top of each other. Background layer for terrain, foreground layer for decorations, collision layer for physics. Each renders at different z-depths.
  *"Set up three tilemap layers in Tiled — background terrain, midground objects, and foreground decoration — and render them with correct draw order."*

- **Isometric Tiles** — Diamond-shaped tiles that create a 3/4 perspective illusion. Requires different coordinate math than square tiles — screen coordinates map to iso-coordinates via a transformation matrix.
  *"Convert mouse click screen coordinates to isometric tile coordinates in my city builder game."*

- **Chunk Loading** — Dividing large tilemaps into chunks (e.g., 16x16 tiles each) and only loading/rendering chunks near the camera. Essential for large worlds that won't fit in memory all at once.
  *"Implement chunk-based tilemap loading that loads a 3x3 grid of chunks around the player and unloads distant chunks."*

- **Parallax Scrolling** — Multiple background layers scrolling at different speeds to create depth illusion. Distant mountains scroll slowly, nearby trees scroll faster. A cheap but effective depth cue.
  *"Add three parallax background layers to my platformer: sky (0.1x scroll speed), mountains (0.3x), and trees (0.7x)."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=parallax+scrolling+2D+game+layers+depth)

- **Scrolling Camera** — A camera that follows the player or target through a level larger than the screen. The tilemap stays fixed; the viewport moves. What you see is a window into a larger world.
  *"Implement a scrolling camera that follows the player horizontally, stays centered vertically, and stops at level boundaries."*

- **Tile Collision** — Using tilemap data for collision detection instead of placing separate collision shapes. Check which tiles the player overlaps and resolve against solid tiles. Fast and simple for grid-based levels.
  *"Implement tile collision that checks the player's bounding box against solid tiles in the grid and resolves by pushing out on the shallowest axis."*

### Camera Systems

How the game's viewpoint follows the action and creates drama.

- **Camera Follow** — The camera tracking a target (usually the player) so they stay visible on screen. Can be instant (locked), smooth (lerp), or predictive (looking ahead of movement).
  *"Implement three camera follow modes — locked, smooth lerp, and look-ahead — and let me toggle between them for testing."*

- **Camera Smoothing (Lerp)** — Moving the camera toward its target at a fraction of the distance each frame instead of snapping. Creates a fluid, natural feel. `camera.x = lerp(camera.x, target.x, 0.1)`.
  *"Add lerp-based camera smoothing with a 0.08 factor. Make it framerate-independent using an exponential decay formula."*

- **Screen Shake** — Rapidly offsetting the camera position by random amounts to convey impact, explosions, or damage. Duration, intensity, and decay control how it feels.
  *"Implement screen shake with configurable duration, intensity, and exponential decay. Trigger it on player damage and explosions."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=screen+shake+camera+effect+game+juice)

- **Dead Zone** — A region around the screen center where the target can move without the camera following. The camera only starts moving when the target exits this zone. Reduces jittery movement during small adjustments.
  *"Add a dead zone to my camera that's 40% of the screen width and 30% of the height, so small movements don't cause scrolling."*

- **Camera Bounds / Clamping** — Preventing the camera from showing areas outside the level boundaries. Clamp the camera position so it never scrolls past the tilemap edges into empty space.
  *"Clamp my camera so it never reveals space beyond the tilemap boundaries, accounting for zoom level and viewport size."*

- **Split Screen** — Rendering multiple viewports simultaneously, each following a different player. Divides the screen into regions (halves, quarters) with independent cameras.
  *"Implement 2-player split screen in LOVE2D using scissors and separate camera transforms for left and right halves."*

- **Viewport** — The camera's visible rectangle in world coordinates. Defined by position, width, height, and zoom. Everything inside the viewport gets drawn; everything outside gets culled.
  *"Calculate the world-space viewport rectangle from camera position, zoom, and screen dimensions for culling off-screen entities."*

- **Zoom** — Changing the camera's scale factor to show more or less of the world. Zoom out to see the whole battlefield, zoom in for detail. Requires adjusting all rendering to account for the scale.
  *"Add smooth zoom in/out with the mouse wheel, clamped between 0.5x and 3x, zooming toward the cursor position."*

- **Camera Target** — The world position the camera tries to center on. Often the player's position, but can be overridden for cutscenes, boss introductions, or the average position of multiple players.
  *"Set the camera target to the midpoint between the player and the boss during the fight, with min/max zoom to keep both visible."*

- **Cinematic Camera** — Scripted camera movement for storytelling moments: pan to a new area, zoom in on a key item, shake during an earthquake. Temporarily overrides the normal follow behavior.
  *"Script a cinematic camera sequence: pan from the player to the locked door (1s), zoom in on the keyhole (0.5s), pan back (1s)."*

### Shaders & Effects

GPU programs and visual tricks that elevate the look of a game.

- **Shader** — A program that runs on the GPU, processing vertices and pixels in parallel. In 2D games, shaders power visual effects like color grading, outlines, dissolves, and CRT filters.
  *"Explain the difference between vertex and fragment shaders for a 2D game developer who has never written GPU code."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=shader+pipeline+vertex+fragment+GPU+diagram)

- **Vertex Shader** — Processes each vertex (corner point) of geometry. In 2D, transforms sprite corners from world space to screen space. Can also distort geometry for wave effects or perspective tricks.
  *"Write a vertex shader that creates a wavy water distortion by offsetting vertex y-positions with a sine wave."*

- **Fragment / Pixel Shader** — Runs once per pixel, determining its final color. This is where most 2D visual effects happen: color swaps, outlines, dissolves, lighting. The creative powerhouse of shaders.
  *"Write a fragment shader that converts a sprite to grayscale and tints it red when the entity takes damage."*

- **Uniform** — A variable passed from your game code to the shader, constant for all pixels in one draw call. Time, player position, flash color, effect intensity — anything the shader needs from the CPU side.
  *"Pass a 'flash_amount' uniform to my hit-flash shader and animate it from 1.0 to 0.0 over 0.2 seconds when the enemy takes damage."*

- **Texture Sampling** — Reading pixel colors from a texture (image) inside a shader. The `texture2D()` or `Texel()` function. Controls how sprites look when scaled, rotated, or filtered.
  *"Explain nearest-neighbor vs. bilinear texture sampling and why pixel art games must use nearest-neighbor."*

- **Post-Processing** — Effects applied to the entire rendered frame after all sprites are drawn. Render the game to a canvas, then draw that canvas through a shader. Bloom, blur, vignette, color grading.
  *"Set up a post-processing pipeline in LOVE2D: render game to canvas → apply bloom shader → apply CRT shader → draw to screen."*

- **Bloom** — A glow effect where bright areas bleed light into surrounding pixels. Makes neon, fire, and magic effects pop. Typically implemented as a blur pass on bright pixels composited back onto the scene.
  *"Implement bloom in LOVE2D by extracting pixels above a brightness threshold, blurring them, and adding the result back."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=bloom+shader+effect+game+glow+post+processing)

- **CRT Effect** — A shader that mimics the look of old cathode-ray tube monitors: scanlines, curvature, color fringing, vignette. Popular for retro-styled games.
  *"Apply a CRT shader to my pixel art game with scanlines, slight barrel distortion, and RGB color separation."*

- **Color Grading** — Shifting the overall color palette of the rendered image. Can use a lookup table (LUT) texture or math in a shader. Cool tones for ice levels, warm tones for deserts, desaturated for flashbacks.
  *"Implement color grading using a 3D LUT texture so I can author color grades in Photoshop and apply them as a post-process."*

- **Dissolve Effect** — Making a sprite appear or disappear by using a noise texture as a threshold. Pixels above the threshold are visible; below are transparent. Animating the threshold creates a burn-away effect.
  *"Write a dissolve shader that uses a Perlin noise texture to make enemies burn away when defeated, with a glowing edge at the dissolve boundary."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=dissolve+shader+effect+noise+threshold+game)

---

## AI & Behavior

Making NPCs think and navigate.

### Pathfinding

Getting from A to B through complex environments.

- **A\* Algorithm** — The gold standard pathfinding algorithm. Combines Dijkstra's shortest-path guarantee with a heuristic that guides search toward the goal. Fast, optimal, and well-understood.
  *"Implement A* pathfinding on my tilemap grid with diagonal movement and variable terrain costs (roads = 1, grass = 2, swamp = 4)."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=A+star+pathfinding+algorithm+visualization+grid)

- **Navigation Mesh (Navmesh)** — A mesh of walkable polygons that defines where entities can move. More flexible than grid-based pathfinding for open or irregularly-shaped areas. Common in 3D games, useful in 2D too.
  *"Generate a navmesh from my tilemap's walkable areas so enemies can path around obstacles smoothly instead of moving on a grid."*

- **Waypoint** — A predefined point in the level that AI entities can navigate between. Simpler than a full navmesh — just a graph of connected points. Good for patrol routes and scripted movement.
  *"Set up patrol waypoints for my guard enemy: walk to point A, wait 2 seconds, walk to point B, wait 3 seconds, repeat."*

- **Heuristic** — An estimate of the remaining distance to the goal, used by A* to prioritize which nodes to explore first. Manhattan distance for grid movement, Euclidean for free movement. Must never overestimate.
  *"Compare Manhattan, Euclidean, and Chebyshev heuristics for A* on my grid that allows 8-directional movement."*

- **Graph** — A data structure of nodes connected by edges. The abstract representation that pathfinding algorithms operate on. A tilemap grid is a graph. A network of waypoints is a graph.
  *"Convert my tilemap into a graph representation where each walkable tile is a node and edges connect to walkable neighbors."*

- **Node** — A single point in a pathfinding graph. In a grid, each walkable cell is a node. Has a position and connections to neighboring nodes. A* tracks each node's cost and parent.
  *"What data should each node in my A* implementation store? Position, g-cost, h-cost, f-cost, parent, and walkable flag."*

- **Shortest Path** — The path between two points with the minimum total cost. A* finds it. But "shortest" doesn't always mean "best" — sometimes you want enemies to take varied or realistic paths.
  *"After finding the shortest path, add slight random variation so multiple enemies don't all take the exact same route."*

- **Path Smoothing** — Removing unnecessary waypoints from a computed path to create more natural movement. A zigzag through grid cells becomes a series of straight-line segments with corners.
  *"Apply path smoothing to my A* result using line-of-sight checks to remove redundant intermediate nodes."*

- **Dynamic Obstacles** — Obstacles that move or appear at runtime, requiring paths to be recalculated. A door closing, a bridge collapsing, another character blocking the way.
  *"Handle dynamic obstacles in my pathfinding so enemies recalculate their path when a door closes or another entity blocks their route."*

- **Flow Field** — A grid where each cell stores a direction vector pointing toward the goal. Every entity in the field just follows its cell's arrow. Scales to thousands of entities with one calculation.
  *"Implement a flow field for my RTS so 500 units can navigate to a clicked position without running 500 individual A* searches."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=flow+field+pathfinding+direction+vectors+game)

### Decision Making

How AI entities choose what to do.

- **Behavior Tree** — A tree structure that evaluates conditions and actions top-to-bottom, left-to-right. Selectors try alternatives, sequences execute steps. More scalable and debuggable than state machines for complex AI.
  *"Build a behavior tree for a guard enemy: patrol (sequence: move to waypoint, wait) → chase player if seen (selector) → attack if in range."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=behavior+tree+game+AI+selector+sequence+diagram)

- **Decision Tree** — A simple branching structure: if condition A, do X; else if condition B, do Y. Easy to understand and implement but grows unwieldy for complex decisions.
  *"Implement a decision tree for my shopkeeper NPC: if player is hostile → flee; if player has gold → offer trade; else → give quest hint."*

- **Utility AI** — Scoring every possible action by how "useful" it is right now, then choosing the highest-scoring one. "How hungry am I? How threatened? How bored?" The most flexible AI approach for complex behaviors.
  *"Implement utility AI for a survival NPC that scores eat, sleep, flee, explore, and socialize actions based on current needs."*

- **Goal-Oriented Action Planning (GOAP)** — The AI defines a desired world state and searches for a sequence of actions to achieve it. Flexible and emergent — the planner can find creative solutions the designer didn't script.
  *"Set up GOAP for an enemy that wants to 'kill player': it might pick up a weapon, approach, then attack — or find a bow and attack from range."*

- **Selector / Sequence Node** — Core behavior tree nodes. A selector tries children until one succeeds (like an OR gate). A sequence runs children until one fails (like an AND gate).
  *"Explain selector vs. sequence with a concrete example: an enemy that tries melee attack, then ranged attack, then flee."*

- **Condition Node** — A behavior tree leaf that checks a condition and returns success or failure. "Is player visible?" "Is health below 30%?" "Do I have ammo?" Gates the execution of action nodes.
  *"Create condition nodes for: player_in_range(distance), health_below(percent), has_item(item_name) for my behavior tree."*

- **Action Node** — A behavior tree leaf that performs a game action: move to target, play animation, fire weapon, wait. Returns running while in progress, success when done, failure if interrupted.
  *"Implement a MoveTo action node that returns 'running' while the entity moves and 'success' when it reaches the destination."*

- **Finite State Machine (AI)** — Using an FSM for enemy behavior: idle → patrol → chase → attack → flee. Each state has its own update logic and transition conditions. Simple and effective for straightforward AI.
  *"Build an enemy FSM with idle, patrol, alert, chase, and attack states. Alert gives 2 seconds of 'did I see something?' before chase."*

- **Fuzzy Logic** — Using degrees of truth instead of binary true/false. An enemy isn't just "near" or "far" — they're 0.7 near. Enables smoother, more natural-feeling AI decisions.
  *"Use fuzzy logic for my enemy's aggression: blend between cautious and aggressive based on health (0-1), ally count, and player threat level."*

- **Priority System** — Ranking possible actions by priority and executing the highest-priority valid action. Simpler than utility AI — priorities are fixed rather than dynamically scored.
  *"Implement a priority-based AI where flee (priority 1) overrides attack (priority 2) which overrides patrol (priority 3)."*

### Steering & Flocking

Low-level movement behaviors that make entities navigate smoothly and act as groups.

- **Steering Behavior** — A family of algorithms that calculate velocity adjustments to achieve movement goals. Each behavior produces a force vector. Combine multiple behaviors for complex movement.
  *"Implement a steering behavior system where entities combine seek, avoid, and wander forces with configurable weights."*

- **Seek** — A steering behavior that accelerates toward a target position. The simplest behavior — just steer toward where you want to go. Results in a straight-line approach that overshoots at high speeds.
  *"Implement seek steering that accelerates an enemy toward the player's position at a configurable maximum speed."*

- **Flee** — The opposite of seek — accelerate away from a target. Used for enemies retreating, civilians running from danger, or prey escaping predators.
  *"Add a flee behavior that activates when an enemy's health drops below 20%, steering them away from the player."*

- **Arrive** — Seek with deceleration — the entity slows down as it approaches the target instead of overshooting. Uses a "slowing radius" where deceleration begins.
  *"Replace my seek behavior with arrive so the enemy decelerates smoothly in the last 100px instead of overshooting the player."*

- **Wander** — A steering behavior that creates natural-looking random movement. Projects a circle ahead of the entity and picks a random point on it each frame. Smoother than random direction changes.
  *"Implement wander steering for idle NPCs so they meander naturally around town instead of standing still or moving randomly."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=steering+behavior+wander+algorithm+circle+diagram)

- **Obstacle Avoidance** — Casting feelers (rays) ahead of the entity and steering away from detected obstacles. The entity navigates around walls and objects without needing a pathfinding graph.
  *"Add obstacle avoidance with three forward-facing raycasts (left, center, right) so enemies steer around walls smoothly."*

- **Flocking** — Simulating group movement (birds, fish, crowds) by combining three simple rules: separation, alignment, and cohesion. Each entity follows only local rules but the group behaves naturally.
  *"Implement flocking for a school of fish with 50 entities. Each fish should react only to neighbors within a 60px radius."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=flocking+boids+simulation+separation+alignment+cohesion)

- **Separation / Alignment / Cohesion** — The three flocking rules. Separation: steer away from nearby neighbors. Alignment: match the average heading of nearby neighbors. Cohesion: steer toward the center of nearby neighbors.
  *"Tune my flocking parameters: separation weight 1.5, alignment 1.0, cohesion 1.0, neighbor radius 80px. The flock clumps too tightly."*

- **Pursuit / Evasion** — Predicting where a moving target will be and steering toward (pursuit) or away from (evasion) that predicted position. Smarter than seek/flee because it leads the target.
  *"Implement pursuit so my homing missile steers toward where the player will be in 0.5 seconds, not where they are now."*

- **Path Following** — A steering behavior that follows a precomputed path by seeking toward the nearest point on the path, then advancing along it. Combines pathfinding output with smooth steering movement.
  *"After A* computes a path, use path-following steering to move my enemy along it with smooth cornering instead of grid-snapping."*

---

## Systems & Infrastructure

The connective tissue that makes a game work end-to-end.

### Input Handling

Reading and processing player actions.

- **Input Mapping** — Translating raw device inputs (key codes, button IDs) into game actions ("jump," "attack," "move_left"). Decouples game logic from specific hardware, enabling remapping and multiple input devices.
  *"Build an input mapping system where 'jump' maps to spacebar, gamepad A, and touchscreen tap, all triggering the same action."*

- **Action Binding** — Connecting a named game action to one or more physical inputs. The player binds "fire" to left-click and right trigger. The game code only checks `isActionPressed("fire")`.
  *"Implement an action binding system with default bindings and a rebinding UI that saves custom bindings to a config file."*

- **Input Buffer** — Storing recent inputs so they can be processed even if they arrive slightly before or after the exact valid frame. Essential for responsive combo systems and forgiving jump inputs.
  *"Add a 6-frame input buffer for attack inputs so the player can queue the next attack slightly before the current animation finishes."*

- **Analog Stick Dead Zone** — Ignoring small analog stick deflections caused by manufacturing imprecision. Without a dead zone, the character drifts when the stick is "centered." Typically 0.1-0.2 radius.
  *"Implement a circular dead zone of radius 0.15 for the left analog stick, with rescaling so the usable range still goes from 0 to 1."*

- **Input Polling vs. Events** — Polling checks input state every frame ("is A pressed right now?"). Events fire once on press/release ("A was just pressed"). Different use cases: movement uses polling, jump uses events.
  *"Should I use polling or events for my fighting game inputs? Explain the tradeoffs for buffered combo detection."*

- **Rebindable Controls** — Letting the player change which physical inputs map to game actions. An accessibility and preference feature. Store bindings in a save file; apply them at startup.
  *"Add a key rebinding screen where the player selects an action, presses the desired key, and the new binding is saved to disk."*

- **Combo Detection** — Recognizing sequences of inputs performed within timing windows. Down, down-forward, forward + punch = fireball. Requires input history tracking and pattern matching.
  *"Implement a combo detection system that recognizes directional input sequences (like quarter-circle-forward + attack) with a 300ms window."*

- **Gesture Recognition** — Detecting touch-screen gestures: tap, swipe, pinch, long press. Maps physical touch patterns to game actions. More complex than button input due to timing and position thresholds.
  *"Implement swipe detection that distinguishes between up/down/left/right swipes with a minimum distance threshold of 50px."*

- **Input Replay** — Recording input sequences and playing them back to reproduce gameplay exactly. Powers replays, automated testing, and demo modes. Requires deterministic game logic.
  *"Record all player inputs with timestamps and implement a replay system that reproduces the exact same gameplay."*

- **Controller Rumble / Haptics** — Vibrating the controller to provide physical feedback. Short burst on hit, sustained rumble on engine revving, gentle pulse on heartbeat. Adds a tactile dimension to game feel.
  *"Trigger controller rumble: 200ms strong vibration on taking damage, continuous gentle vibration when the engine is running."*

### Audio Programming

Making games sound good through code.

- **Sound Effect (SFX)** — A short audio clip triggered by a game event: a jump sound, a sword swing, an explosion. Usually played once and forgotten. Keep them short and punchy.
  *"Play a jump SFX when the player leaves the ground, with slight random pitch variation (0.9-1.1x) to prevent repetitiveness."*

- **Music Track (BGM)** — Background music that loops during gameplay. Often crossfaded between tracks when changing areas or moods. Longer files, typically streamed rather than loaded into memory.
  *"Stream a background music track that loops seamlessly, and crossfade to a boss music track over 2 seconds when the boss spawns."*

- **Audio Source** — An object in the game world that emits sound. Has a position (for spatial audio), volume, pitch, and a reference to the audio data. Multiple sources can play the same sound simultaneously.
  *"Create audio sources for each torch in my dungeon that emit a fire-crackling sound attenuated by distance from the listener."*

- **Spatial Audio / 3D Sound** — Audio that changes based on the listener's position and orientation relative to the source. Sound from the left plays louder in the left speaker. Creates sonic immersion.
  *"Implement spatial audio for my top-down game so footsteps from off-screen enemies get louder as they approach and pan left/right."*

- **Audio Bus / Mixer** — A routing system that groups sounds into channels (master, music, SFX, ambient, voice) with independent volume controls. The player adjusts "music volume" and it affects all music sources.
  *"Set up audio buses for master, music, SFX, and UI sounds, each with an independent volume slider in the options menu."*

- **Ducking** — Temporarily reducing the volume of one audio bus when another plays. Lower the music volume when a voice line plays, then bring it back up smoothly. Keeps important audio audible.
  *"Duck the music bus to 30% volume when dialogue plays, then fade it back up over 1 second when dialogue finishes."*

- **Crossfade** — Smoothly transitioning between two audio tracks by fading one out while fading the other in. Prevents jarring cuts between music tracks when changing game areas or moods.
  *"Crossfade from the overworld theme to the dungeon theme over 3 seconds when the player enters the dungeon entrance."*

- **Sound Pool** — A collection of similar sound variations for the same event. Instead of playing the same footstep sound 1000 times, randomly pick from 4-5 variations. Prevents listener fatigue.
  *"Create a sound pool of 5 footstep variations and randomly select one each step, ensuring no immediate repeats."*

- **FMOD / Wwise** — Professional audio middleware tools used in game development. Handle complex audio behaviors, adaptive music, and sound design with visual tools. Overkill for small games, essential for large ones.
  *"Compare FMOD vs. Wwise for a mid-size indie game. What does audio middleware give me that raw audio APIs don't?"*

- **Audio Occlusion** — Muffling sounds that pass through walls or obstacles. An explosion behind a wall sounds different than one in open air. Simulates how sound travels through environments.
  *"Implement simple audio occlusion: if a raycast from the audio source to the listener hits a wall, apply a low-pass filter."*

### Networking & Multiplayer

Connecting players across machines.

- **Client-Server** — One machine (server) is the authority on game state. Clients send inputs and receive state updates. The dominant architecture for online multiplayer. Prevents most cheating.
  *"Set up a basic client-server architecture where the server runs the physics simulation and clients send input packets at 30Hz."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=client+server+architecture+multiplayer+game+networking)

- **Peer-to-Peer** — Each player's machine communicates directly with every other player. No central server needed. Simpler to set up but harder to prevent cheating and scales poorly past 4-8 players.
  *"Compare client-server vs. peer-to-peer for a 4-player co-op game. When does peer-to-peer make sense?"*

- **Authoritative Server** — The server's version of the game state is always correct. If the client says "I'm at position X" but the server says "no, you're at position Y," the server wins. Anti-cheat foundation.
  *"Make my server authoritative for player position: accept movement inputs from clients but validate them against max speed and collision."*

- **Lag Compensation** — Techniques to make networked games feel responsive despite latency. Client-side prediction, server reconciliation, entity interpolation. The art of hiding 50-200ms of delay.
  *"Implement client-side prediction with server reconciliation so the player's movement feels instant despite 80ms round-trip latency."*

- **Tick Rate** — How many times per second the server updates the simulation. A 60-tick server processes game logic 60 times per second. Higher tick rates are more responsive but use more bandwidth and CPU.
  *"My server runs at 20 ticks/second but my client renders at 60 FPS. How do I interpolate between server updates for smooth visuals?"*

- **Netcode** — The umbrella term for all networking code in a game: packet handling, state synchronization, lag compensation, prediction, and reconciliation. "Good netcode" means the game feels smooth online.
  *"What does 'good netcode' actually mean technically? Break down the specific techniques that make an online game feel responsive."*

- **Rollback** — A netcode strategy where the game predicts remote player inputs, simulates forward, and rolls back to correct when actual inputs arrive. Used in fighting games for zero-input-delay feel.
  *"Explain rollback netcode for a 2-player fighting game: how does the game predict, detect mispredictions, and resimulate?"*

- **State Sync vs. Input Sync** — Two multiplayer synchronization approaches. State sync sends full game state (simple but bandwidth-heavy). Input sync sends only inputs and each machine simulates (efficient but requires determinism).
  *"Should my RTS use state sync or input sync? I have 200 units but only a few inputs per frame."*

- **Interpolation / Extrapolation** — Smoothing entity movement between network updates. Interpolation renders between two known states (smooth but adds latency). Extrapolation predicts the next state (responsive but can be wrong).
  *"Implement entity interpolation that renders remote players at a position between the two most recent server snapshots."*

- **Lobby** — A pre-game waiting area where players gather, choose settings, and ready up before the match starts. Handles matchmaking, player listing, and game configuration.
  *"Build a lobby system where up to 4 players can join, choose characters, toggle ready status, and the host can start the game."*

### Save & Serialization

Preserving and restoring game state.

- **Serialization** — Converting in-memory game objects into a storable format (JSON string, binary data, XML). The translation step between "running game" and "saved file."
  *"Serialize my game state to JSON, including player position, inventory items, quest progress, and world state flags."*

- **Deserialization** — The reverse of serialization — reading saved data and reconstructing game objects from it. Must handle missing fields gracefully when save formats change between versions.
  *"Deserialize a save file and rebuild game state, using default values for any fields that don't exist in older save files."*

- **Save File** — A file on disk containing serialized game state. Can be JSON (human-readable, debugging-friendly), binary (smaller, harder to tamper with), or a database (SQLite for complex data).
  *"What format should my save file use? Compare JSON vs. binary vs. SQLite for a roguelike with procedurally generated maps."*

- **JSON / Binary Format** — JSON is text-based and human-readable — great for debugging saves. Binary is compact and fast to read/write — good for large saves. Choose based on save size and debug needs.
  *"My JSON save file is 2MB. Should I switch to binary serialization, or compress the JSON with zlib?"*

- **Checkpoint** — A specific point in the game where progress is automatically saved. The player respawns at the last checkpoint on death. Placement is a game design decision as much as a technical one.
  *"Implement an auto-save checkpoint system that saves when the player enters a new room, and respawns them at the last checkpoint on death."*

- **Autosave** — Saving the game automatically at regular intervals or triggered events without player input. Protects against crashes and rage-quits. Should be fast enough to not cause frame hitches.
  *"Add autosave that triggers every 5 minutes and at key events (level transitions, boss defeats). Run the save on a background thread to avoid stutters."*

- **Save Slot** — A named save location that holds one save file. "Slot 1: Level 5, 2h30m played." Multiple slots let players maintain separate playthroughs or experiment without losing progress.
  *"Implement a 3-slot save system with preview info (level, playtime, screenshot thumbnail) shown in the load game menu."*

- **Migration / Versioning** — Handling save files from older versions of the game when the data format changes. Version-stamp each save and write migration functions that upgrade old saves to the new format.
  *"My save format changed between v1.2 and v1.3 (added crafting data). Write a migration that upgrades v1.2 saves by adding default crafting state."*

- **Persistent State** — Game state that survives beyond a single session: unlocked characters, best scores, settings preferences. Often stored separately from per-playthrough save files.
  *"Separate persistent state (unlocked characters, settings, achievements) from playthrough saves so a 'new game' doesn't erase unlocks."*

- **Cloud Save** — Synchronizing save files to a cloud service so players can continue on a different device. Requires conflict resolution when local and cloud saves diverge.
  *"Implement cloud save sync: upload on save, download on launch, and show a conflict dialog when local and cloud timestamps differ."*
