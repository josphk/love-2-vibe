# Game Art Domain Map

A curated vocabulary reference for game art. Use these terms to prompt AI tools with visual precision — each entry includes a plain-language definition and an example prompt showing the term in context.

**How to use this page:** Scan the branch that matches your art problem. Grab the precise term, drop it into your prompt, and get results that match what you actually picture in your head.

---

## 2D Art Foundations

The building blocks of flat visual art in games.

### Pixel Art & Sprites

The craft of making images one pixel at a time, and the formats games use to display them.

- **Pixel Art** — Art created at extremely low resolutions where each pixel is deliberately placed. The constraint forces clarity — every dot carries information about form, light, and color.
  *"Create a 32x32 pixel art treasure chest in a top-down RPG style with a 16-color palette."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=pixel+art+game+sprite+example)

- **Sprite** — A 2D image or animation used as a game object. Characters, enemies, items, projectiles — if it moves or gets drawn independently, it's probably a sprite.
  *"Design a sprite for a slime enemy with idle, hop, and death frames at 48x48 pixels."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+sprite+character+2d)

- **Sprite Sheet** — A single image containing multiple frames of animation or multiple related sprites arranged in a grid. The engine reads coordinates to display the right frame.
  *"Generate a sprite sheet for a player character with 8 frames of walk animation in four directions."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=sprite+sheet+animation+grid+game)

- **Tile** — A small, repeating image unit used to build environments. Grass, stone, water, walls — tiles snap together on a grid to form levels without unique art for every screen.
  *"Create a set of grass and dirt tiles at 16x16 pixels that blend seamlessly when placed side by side."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+tileset+pixel+art+grass+dirt)

- **Tileset** — A collection of tiles designed to work together. Includes base tiles, edge transitions, corners, and variants. A well-made tileset lets you build entire worlds from a single sheet.
  *"Design a dungeon tileset with floor, wall, door, and corner pieces that support auto-tiling rules."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=tileset+rpg+dungeon+game+art)

- **Sub-pixel Animation** — Moving elements by less than one pixel using color blending between adjacent pixels. Creates the illusion of smooth motion at very low resolutions.
  *"Animate a pixel art candle flame using sub-pixel animation to create smooth flickering at 16x16."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=sub-pixel+animation+pixel+art+technique)

- **Dithering** — Using patterns of alternating colored pixels to simulate gradients or additional colors within a limited palette. Checkerboard patterns are the most common form.
  *"Apply dithering to create a smooth shadow gradient on this pixel art building using only 4 shades of grey."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=dithering+pixel+art+technique+gradient)

- **Anti-aliasing** — Placing intermediate-colored pixels along edges to smooth jagged stair-step patterns. In pixel art, this is done manually and selectively — over-smoothing destroys the crisp look.
  *"Add manual anti-aliasing to the curved edges of this pixel art character while keeping the overall style sharp."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=anti-aliasing+pixel+art+before+after)

- **Color Ramp** — A sequence of colors arranged from dark to light (or between hues) that defines how you shade a surface. Good ramps shift hue as they shift value — shadows go cool, highlights go warm.
  *"Create a color ramp for pixel art skin tones that shifts from warm brown shadows to peachy highlights in 5 steps."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=pixel+art+color+ramp+palette+hue+shifting)

- **Palette** — The fixed set of colors used in an artwork or game. A constrained palette forces visual cohesion. Classic consoles had hardware-enforced palettes; modern pixel art uses them by choice.
  *"Design a 16-color palette for a haunted forest game that covers foliage, stone, skin tones, and UI elements."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=pixel+art+color+palette+16+color+game)

### 2D Animation

Making flat images move — from frame-by-frame to bone-driven techniques.

- **Frame Animation** — Playing a sequence of individual images in order to create motion. The flipbook approach. Simple, expressive, and still the backbone of most 2D game animation.
  *"Animate a frame-by-frame explosion in 8 frames at 64x64 pixels for a top-down shooter."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=frame+by+frame+animation+game+sprite)

- **Tweening** — Automatically generating intermediate frames between two keyframes. The computer handles the movement; you define the start and end states.
  *"Set up a tween for a UI panel that slides in from the left with an ease-out curve over 0.3 seconds."*

- **Skeletal Animation** — Attaching a bone hierarchy to a 2D image and rotating/translating bones to animate. Uses far fewer assets than frame animation and allows blending between states.
  *"Rig a 2D character with skeletal animation for idle, walk, and attack using Spine or DragonBones."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=2d+skeletal+animation+spine+dragonbones)

- **Onion Skinning** — Displaying faint overlays of previous and next frames while drawing. Lets the animator see the motion arc and keep spacing consistent between poses.
  *"Enable onion skinning to check the spacing on my character's jump animation — the arc feels uneven."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=onion+skinning+animation+frames+overlay)

- **Easing Curve** — A function that controls how a value changes over time. Linear is robotic. Ease-in starts slow. Ease-out ends slow. Ease-in-out does both. The secret ingredient in polished motion.
  *"Apply an ease-out curve to the projectile's launch so it starts fast and decelerates naturally."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=easing+curve+animation+ease+in+out+graph)

- **Keyframe** — A frame that defines a key pose in an animation. The important positions — the rest is interpolation or in-between frames. Good animation is really good keyframe design.
  *"Block out keyframes for a sword swing: anticipation, swing, and follow-through poses."*

- **Inbetween** — A frame drawn between keyframes to smooth the transition. In traditional animation, senior animators drew keys and juniors drew inbetweens. In games, the engine often generates them.
  *"Add two inbetween frames to my walk cycle to make the leg motion feel less snappy."*

- **Animation State** — A labeled condition (idle, running, attacking, falling) that determines which animation plays. State machines manage transitions between these states based on game logic.
  *"Set up an animation state machine with transitions: idle → run (on input), run → jump (on spacebar), jump → fall (at apex)."*

- **Blend Tree** — A system that blends between multiple animations based on continuous parameters like speed or direction. Smoother than hard-switching between discrete states.
  *"Create a blend tree that interpolates between walk and run animations based on the character's movement speed."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=animation+blend+tree+game+engine)

- **Sprite Atlas** — A large texture containing many smaller sprites packed together efficiently. Reduces draw calls because the GPU can render multiple sprites from one texture in a single batch.
  *"Pack all UI icons and character sprites into a single sprite atlas to reduce draw calls."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=sprite+atlas+texture+packing+game)

### Vector & UI Art

Resolution-independent art built from mathematical curves — ideal for interfaces and scalable assets.

- **Vector Art** — Images defined by mathematical points and curves rather than pixels. Scales to any resolution without blurring. Common for UI elements, logos, and stylized game art.
  *"Create vector art for a set of weapon icons that stay crisp at both 64x64 and 512x512."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=vector+art+game+icons+clean+scalable)

- **Bezier Curve** — A smooth curve defined by control points. The mathematical foundation of all vector art. Two endpoints and one or more handles control the curvature.
  *"Draw a bezier-curved flight path for a homing missile that arcs toward the target smoothly."*

- **9-Slice** — A technique that divides an image into 9 sections so it can stretch without distorting corners or edges. Essential for UI panels, buttons, and speech bubbles that need to resize.
  *"Set up 9-slice scaling on this dialog box sprite so it stretches for any text length without warping the rounded corners."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=9-slice+scaling+ui+game+panel)

- **Icon Design** — Creating small, instantly readable images that communicate meaning at a glance. Game icons must read at tiny sizes and distinguish themselves from dozens of neighbors.
  *"Design a set of 32x32 inventory icons for potion, sword, shield, and key that are distinguishable at a glance."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+icon+design+inventory+items)

- **Glyph** — A single symbol in a font or icon system. In games, glyphs include controller button prompts, currency symbols, and status effect icons rendered inline with text.
  *"Create controller button glyphs (A, B, X, Y) that match our UI style for inline prompt text."*

- **Scalable Asset** — Any art file designed to render cleanly at multiple resolutions. Vector graphics are inherently scalable; raster assets need mipmaps or multiple export sizes.
  *"Export this character portrait as a scalable asset at 1x, 2x, and 4x for different screen densities."*

- **Resolution Independence** — The ability of art to look correct at any screen size or DPI. Achieved through vector graphics, signed distance fields, or responsive layout systems.
  *"Make the HUD resolution-independent so it looks sharp on both 720p phones and 4K monitors."*

- **Stroke vs Fill** — The two fundamental ways to render a shape: stroke draws the outline, fill colors the interior. Combining and varying these creates distinct visual styles.
  *"Use thick strokes with flat fills for a comic book art style on the character outlines."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=stroke+vs+fill+vector+art+illustration)

- **Shape Language** — Using specific geometric forms to communicate character traits. Circles feel friendly, triangles feel dangerous, squares feel stable. The visual shorthand audiences read subconsciously.
  *"Redesign this villain using triangle-heavy shape language to make them feel more threatening."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=shape+language+character+design+circle+triangle+square)

- **Silhouette Readability** — How recognizable a character or object is when reduced to a solid black shape. Good game art passes the silhouette test — you can identify anything from its outline alone.
  *"Test these five enemy designs by filling them solid black — can a player tell them apart instantly in a fast-paced game?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=silhouette+readability+character+design+game)

---

## 3D Art Foundations

Modeling, texturing, and rendering the third dimension.

### Modeling & Topology

Building 3D shapes from vertices, edges, and faces — and making them game-ready.

- **Mesh** — The collection of vertices, edges, and polygons that defines a 3D object's shape. Everything you see in a 3D game is a mesh (or a collection of them).
  *"Create a low-poly mesh for a treasure chest that opens with a hinge animation."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=3d+mesh+wireframe+game+model)

- **Polygon** — A flat face bounded by edges. Triangles (tris) are the simplest; quads (four-sided) are preferred for modeling because they deform predictably. Every mesh is ultimately made of polygons.
  *"Keep the building facade under 500 polygons for a mobile city-builder."*

- **Vertex** — A single point in 3D space. Vertices are the dots; edges connect them; faces fill between them. Moving vertices is the most fundamental modeling operation.
  *"Adjust the vertex positions around the character's mouth to fix the deformation during smile blend shapes."*

- **Edge Loop** — A connected ring of edges that flows around a mesh. Good edge loops follow the natural contours of a form — around eyes, mouths, joints. They're essential for clean deformation.
  *"Add an edge loop around the elbow to prevent the mesh from collapsing when the arm bends."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=edge+loop+3d+modeling+face+topology)

- **Quad vs Tri** — Quads (four-sided faces) subdivide cleanly and deform well. Tris (three-sided) are what the GPU actually renders. Model in quads, let the engine triangulate at export.
  *"Convert any remaining n-gons to quads before rigging — the shoulder area needs clean quad flow for animation."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=quad+vs+tri+3d+topology+modeling)

- **Low-poly** — A modeling style or constraint that uses few polygons. Can be an aesthetic choice (flat-shaded low-poly look) or a performance requirement (mobile games, LOD meshes).
  *"Model a low-poly pine tree under 200 tris with a flat-shaded art style for a cozy farming game."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=low+poly+game+art+style+3d)

- **High-poly** — A mesh with dense polygon detail, often millions of faces. Used for sculpting fine detail that gets baked into normal maps for the game-ready low-poly version.
  *"Sculpt a high-poly version of the armor with surface scratches and dents, then bake the detail to a normal map."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=high+poly+sculpt+zbrush+game+character)

- **Retopology** — Rebuilding a high-poly mesh into a clean, low-poly version with proper edge flow. The bridge between sculpting freedom and game-engine requirements.
  *"Retopologize this sculpted character head from 2M tris to under 5K tris with animation-ready edge loops."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=retopology+before+after+3d+model)

- **LOD (Level of Detail)** — Multiple versions of a mesh at different polygon counts, swapped based on camera distance. Close-up gets the detailed version; far away gets the simple one.
  *"Create three LOD levels for this tree: 5000 tris at close range, 1000 at mid, 200 at far distance."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=level+of+detail+LOD+3d+game+mesh)

- **Bevel** — Replacing a sharp edge with a small angled surface. Bevels catch light realistically and prevent the "CG look" of perfectly sharp corners that don't exist in nature.
  *"Add a subtle bevel to all hard edges on this crate model so it catches rim lighting naturally."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=bevel+3d+modeling+hard+surface+edge)

### Texturing & Materials

Painting and defining surface properties that make meshes look like real (or stylized) things.

- **Texture Map** — A 2D image wrapped onto a 3D surface. The most basic way to add color and detail to a mesh. Different map types control different surface properties.
  *"Paint a texture map for this medieval house with wood grain on the beams and plaster on the walls."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=texture+map+3d+model+game+asset)

- **UV Mapping** — The process of defining how a 2D texture wraps onto a 3D surface. U and V are the 2D coordinate axes (like X and Y but for texture space).
  *"Lay out the UVs for this weapon model so the blade gets the most texture space and the handle shares a tiling material."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=uv+mapping+3d+model+unwrap+layout)

- **UV Unwrap** — Flattening a 3D mesh's surface into 2D pieces for texturing. Like peeling an orange and laying the skin flat. Seam placement determines where visible stretching or artifacts appear.
  *"Unwrap this character model with seams hidden under the arms, along the inner legs, and behind the ears."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=uv+unwrap+3d+model+seams+layout)

- **Albedo** — The base color of a surface without any lighting or shadow information. Pure diffuse color. In PBR workflows, the albedo map should contain no baked lighting.
  *"Paint an albedo map for this stone wall — just the color variation of the stone, no shadows or ambient occlusion."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=albedo+map+pbr+texture+game+asset)

- **Normal Map** — A texture that fakes surface detail by altering how light bounces off each pixel. Encodes surface direction as RGB colors. Makes a flat surface look bumpy without adding geometry.
  *"Bake a normal map from the high-poly sculpt to add brick detail to the low-poly wall mesh."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=normal+map+3d+texture+before+after)

- **Roughness Map** — A texture that controls how sharp or blurry reflections appear at each point. White is rough (diffuse reflection), black is smooth (mirror-like). Drives the material's shininess.
  *"Paint a roughness map where the metal armor is smooth and the leather straps are rough."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=roughness+map+pbr+texture+game)

- **PBR (Physically-Based Rendering)** — A rendering approach where materials respond to light based on real-world physics. Uses albedo, roughness, metallic, and normal maps. The modern standard for realistic game art.
  *"Set up PBR materials for this sci-fi corridor: brushed metal walls, rubber floor mats, and glass panels."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=pbr+physically+based+rendering+material+spheres)

- **Tiling Texture** — A texture designed to repeat seamlessly across a surface with no visible seams. Essential for large surfaces like floors, walls, and terrain that can't be uniquely textured.
  *"Create a tiling stone floor texture at 512x512 that repeats without visible seam patterns."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=tiling+seamless+texture+game+stone+floor)

- **Texture Atlas** — A single large texture containing multiple smaller textures arranged together. Reduces material swaps — objects sharing an atlas can be rendered in one draw call.
  *"Pack all the prop textures for this room into a single 2048x2048 texture atlas to minimize draw calls."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=texture+atlas+3d+game+props+uv+layout)

- **Substance** — Procedural texture authoring software (now Adobe Substance 3D). Creates textures from node graphs that are resolution-independent, tileable, and infinitely tweakable.
  *"Build a Substance Designer graph for weathered wood that exposes parameters for age, moss coverage, and paint peel."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=substance+designer+node+graph+procedural+texture)

### Rigging & Skinning

Giving 3D meshes the skeleton and deformation systems they need to animate.

- **Rig** — The control system attached to a 3D model that lets animators pose and move it. Includes bones, constraints, and custom controls. A good rig makes animation fast; a bad rig makes it painful.
  *"Build a character rig with IK legs, FK arms, and a simple spine chain for a third-person action game."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=3d+character+rig+controls+game)

- **Bone** — An individual element in a skeleton hierarchy. Bones are connected in parent-child chains — moving a shoulder bone moves the upper arm, forearm, and hand below it.
  *"Add finger bones to the hand rig so the character can grip weapons and make fist poses."*

- **Joint** — The point where two bones connect and rotation occurs. Joints define the pivot points of a skeleton — elbows bend, wrists twist, spines curl, all at their joints.
  *"Place the elbow joint so the forearm rotates naturally without mesh clipping during extreme poses."*

- **Weight Painting** — Assigning how much influence each bone has over each vertex. The painted weights determine how the mesh deforms when bones move. Bad weights cause stretching and clipping.
  *"Fix the weight painting on the shoulder — vertices are pulling toward the neck bone when the arm raises."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=weight+painting+3d+character+rigging)

- **Inverse Kinematics (IK)** — A solving method where you position the end of a bone chain (like a hand or foot) and the system calculates how the parent bones should rotate to reach it. Natural for legs and reaching.
  *"Set up IK on the legs so the feet plant on uneven terrain automatically."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=inverse+kinematics+IK+3d+animation+leg)

- **Forward Kinematics (FK)** — Rotating each bone in a chain from parent to child. You rotate the shoulder, then the upper arm, then the forearm. Gives precise control over arcs — ideal for arms in action animations.
  *"Use FK for the sword swing animation to get a clean arc from shoulder through wrist."*

- **Blend Shape** — A deformation that morphs a mesh from one shape to another by moving vertices. Used for facial animation — each expression (smile, frown, blink) is a separate blend shape.
  *"Create blend shapes for this character's face: smile, frown, blink, and mouth open for dialog."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=blend+shape+facial+animation+3d+character)

- **Morph Target** — Another name for blend shape, more common in game engine contexts. A stored vertex position offset that can be blended in at runtime to deform the mesh.
  *"Set up morph targets for damage states — the car hood crumples progressively on each hit."*

- **Bind Pose** — The default pose a mesh is in when first attached to its skeleton. Usually a T-pose or A-pose. All animations are offsets from this pose, so it must allow clean deformation in all directions.
  *"Model the character in an A-pose bind pose to reduce shoulder deformation artifacts during arm movement."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=bind+pose+t-pose+a-pose+3d+character)

- **Deformation** — How a mesh bends, stretches, and squishes when its skeleton moves. Clean deformation looks natural; bad deformation creates pinching, stretching, or mesh intersection.
  *"Test the deformation on the knee joint through full bend range — add a corrective blend shape if the geometry collapses."*

---

## Visual Design Principles

The art theory that makes game visuals work.

### Color & Light

How color and lighting shape mood, readability, and visual impact.

- **Color Theory** — The framework for understanding how colors relate, combine, and affect perception. Covers the color wheel, harmony rules, temperature, and psychological associations.
  *"Apply color theory to this level's palette — use analogous cool blues for the ice cave with a complementary warm accent for interactable objects."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=color+theory+wheel+harmony+game+art)

- **Hue / Saturation / Value (HSV)** — The three dimensions of color. Hue is the color itself (red, blue). Saturation is how vivid it is. Value is how light or dark. Value does most of the heavy lifting in readability.
  *"Desaturate the background environment and boost the saturation on pickups so they pop against the scene."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=hue+saturation+value+HSV+color+model)

- **Complementary Colors** — Colors opposite each other on the color wheel (red/green, blue/orange, purple/yellow). Create maximum contrast when placed together — great for making elements stand out.
  *"Use a blue-orange complementary scheme: blue for the cold environment, orange for the warm firelight and UI highlights."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=complementary+colors+game+art+palette)

- **Warm vs Cool** — Warm colors (red, orange, yellow) feel energetic, close, and aggressive. Cool colors (blue, green, purple) feel calm, distant, and safe. Temperature guides emotional response.
  *"Shift the color temperature from warm in the village (safety) to cool in the dungeon (danger and isolation)."*

- **Color Palette** — The curated set of colors used across a game or scene. A cohesive palette unifies the visual experience. Typically 8–20 colors for pixel art, more for 3D but still intentionally chosen.
  *"Build a 12-color palette for a desert biome covering sand, rock, sky, shadow, and accent colors for flora."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+color+palette+design+cohesive)

- **Color Grading** — A post-processing step that shifts the overall color balance of the rendered image. Used to set mood — warm golden for nostalgia, desaturated teal for tension, high-contrast for action.
  *"Apply color grading to the horror level: crush the blacks, shift shadows to blue-green, and desaturate everything except red."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=color+grading+game+before+after+mood)

- **Ambient Light** — Non-directional light that fills in shadows so they're not pitch black. Represents light bouncing off every surface. Too much flattens the scene; too little makes it unreadable.
  *"Increase ambient light in the cave to 15% so players can navigate without a torch but shadows still feel deep."*

- **Rim Light** — A light placed behind a subject that creates a bright edge outline. Separates characters from backgrounds and adds visual drama. A staple of character presentation in games.
  *"Add a subtle blue rim light to the player character so they read clearly against dark dungeon backgrounds."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=rim+light+character+game+art+backlighting)

- **Global Illumination (GI)** — A lighting system that simulates how light bounces between surfaces. Red walls bleed red light onto nearby objects. Expensive to compute but dramatically increases realism.
  *"Enable baked global illumination for the indoor scene so the warm wooden walls cast subtle warm light onto the stone floor."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=global+illumination+game+scene+light+bounce)

- **Emissive** — A material property that makes a surface appear to glow by outputting light color without needing an external light source. Neon signs, magic runes, lava, UI elements.
  *"Set the crystal material to emissive blue so it glows in the dark cave without needing a point light on each crystal."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=emissive+material+game+glow+neon)

### Composition & Framing

How elements are arranged to guide the viewer's eye and communicate importance.

- **Rule of Thirds** — Dividing the frame into a 3x3 grid and placing points of interest at the intersections. A starting point for balanced composition that avoids the static feel of dead-center placement.
  *"Position the focal point of this level's vista at the upper-right third intersection for a more dynamic screenshot."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=rule+of+thirds+game+screenshot+composition)

- **Focal Point** — The area where the viewer's eye is drawn first. Created through contrast, color, detail density, or converging lines. Every scene should have a clear focal point.
  *"Make the boss door the focal point of this room using brighter lighting, more detail, and converging floor patterns."*

- **Leading Lines** — Lines within the composition that guide the viewer's eye toward the focal point. Roads, rivers, light beams, architectural edges — anything that creates a visual path.
  *"Use the river and the row of torches as leading lines that draw the player's eye toward the castle in the distance."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=leading+lines+composition+game+level+design)

- **Negative Space** — Empty or undetailed areas that give the eye a rest and make busy elements stand out. Without negative space, everything competes for attention and nothing wins.
  *"Add more negative space around the boss arena so the complex boss design reads clearly against a simple background."*

- **Visual Hierarchy** — The arrangement of elements by importance, making the most critical information read first. Size, color, contrast, and position all control what players see in what order.
  *"Establish visual hierarchy in the HUD: health bar largest and top-left, ammo smaller and bottom-right, minimap secondary."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=visual+hierarchy+game+ui+hud+design)

- **Depth Layering** — Separating a scene into distinct depth planes to create the illusion of three-dimensional space in 2D. Achieved through parallax, color, scale, and detail differences between layers.
  *"Set up five depth layers for the forest scene: close leaves, near trees, path, far trees, and distant mountains."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=depth+layering+2d+game+parallax+forest)

- **Foreground / Midground / Background** — The three basic depth zones in a composition. Foreground frames the view, midground holds the action, background sets the context. Separating them creates depth.
  *"Darken and blur the foreground foliage, keep the midground gameplay area crisp, and desaturate the distant background mountains."*

- **Framing** — Using elements within the scene to create a border around the subject. Doorways, arches, tree canopies, cave mouths. Framing draws attention inward and adds depth.
  *"Frame the reveal of the open world by having the player walk through a narrow cave that opens into a wide vista."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=framing+composition+game+vista+reveal)

- **Tangent** — An unintentional alignment where two edges meet or overlap awkwardly, creating visual confusion about which element is in front. A common composition mistake that flattens depth.
  *"Fix the tangent where the tree trunk aligns exactly with the building edge — shift the tree left so the layers read as separate."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=tangent+composition+art+mistake+example)

- **Read** — How quickly and clearly a visual communicates its meaning. "Does it read?" means "Can the viewer understand what they're looking at instantly?" Fast read is critical in games.
  *"This attack animation doesn't read at game speed — exaggerate the windup pose so players can react."*

### Style & Cohesion

Defining and maintaining a unified visual identity across an entire game.

- **Art Style** — The overall visual approach of a game. Realistic, stylized, cel-shaded, pixel art, painterly — the style is the first thing players see and the last thing they remember.
  *"Define the art style for this indie platformer: chunky shapes, limited palette, thick outlines, inspired by Cartoon Network shows."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+art+style+comparison+realistic+stylized+pixel)

- **Art Direction** — The high-level vision that guides all visual decisions in a project. Art direction answers "what should this feel like?" while artists answer "how do I make it?"
  *"Write an art direction brief for a post-apocalyptic game that feels hopeful rather than grimdark — overgrown ruins, warm light, vibrant nature."*

- **Style Guide** — A document defining the visual rules of a project: colors, proportions, line weights, material treatments. Keeps art consistent when multiple people contribute.
  *"Create a style guide page showing correct and incorrect examples of how characters should be shaded in our flat-color style."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+art+style+guide+document+example)

- **Reference Sheet** — A collection of images showing a character, prop, or environment from multiple angles and in various states. The blueprint that keeps art consistent across scenes.
  *"Draw a reference sheet for the main character showing front, side, back views plus expression variants and color callouts."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=character+reference+sheet+turnaround+game+art)

- **Mood Board** — A collage of images, colors, and textures that captures the target feeling of a project. Used early in development to align the team's visual instincts before any art is produced.
  *"Assemble a mood board for the underwater level: bioluminescence, deep blue gradients, coral textures, jellyfish lighting."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+art+mood+board+concept+art)

- **Silhouette Test** — Filling all elements of a scene or character solid black to check if shapes are distinct and readable. If everything blobs together, the design needs clearer shape differentiation.
  *"Run a silhouette test on our five enemy types — the two flying enemies look identical when filled black."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=silhouette+test+character+design+game)

- **Shape Language** — The consistent use of geometric forms to convey meaning. Heroes get circles and curves (approachable). Villains get angles and spikes (threatening). Environments follow the same logic.
  *"Apply aggressive shape language to the enemy fortress: sharp angles, jagged edges, pointed towers. Contrast it with the rounded, soft village."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=shape+language+character+design+hero+villain)

- **Visual Noise** — Excessive detail, pattern, or variation that makes a scene hard to read. When everything is detailed, nothing stands out. Reducing visual noise in low-priority areas directs attention.
  *"Reduce visual noise on the ground texture — the current cobblestone pattern is fighting with the enemy sprites for attention."*

- **Art Bible** — The comprehensive reference document for a game's entire visual identity. Combines style guide, mood boards, reference sheets, color palettes, and technical specs in one place.
  *"Compile an art bible covering character proportions, environment style, color palettes, UI design, and VFX style for onboarding new artists."*

- **Cohesion** — The quality of all visual elements feeling like they belong in the same world. A game with strong cohesion looks intentional; weak cohesion looks like a asset store mashup.
  *"The new weapon models break cohesion with the rest of the game — they're too realistic for our stylized art style. Simplify the geometry and flatten the shading."*

---

## Technical Art & VFX

Where art meets engineering — particles, shaders, and performance.

### Particle Systems & VFX

Creating dynamic visual effects from swarms of tiny elements.

- **Particle System** — An engine feature that spawns, moves, and destroys many small elements (particles) to create effects like fire, smoke, sparks, rain, and magic. The workhorse of real-time VFX.
  *"Create a particle system for campfire flames: orange-yellow sprites that rise, shrink, and fade over 0.8 seconds."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=particle+system+game+fire+effect+vfx)

- **Emitter** — The source point or region that spawns particles. Can be a single point, a line, a circle, a mesh surface, or any shape. The emitter's shape defines the effect's origin.
  *"Set up a ring emitter around the magic circle that spawns glowing particles upward in a cylinder."*

- **Particle Lifetime** — How long each particle exists before it disappears. Short lifetimes (0.1s) make snappy effects like sparks. Long lifetimes (5s+) make lingering effects like fog.
  *"Set particle lifetime to 0.3 seconds for muzzle flash sparks — they should appear and vanish almost instantly."*

- **Velocity Curve** — A curve that controls how fast particles move over their lifetime. Starts fast and slows down for explosions. Starts slow and speeds up for suction effects.
  *"Apply a velocity curve that launches explosion particles fast initially then rapidly decelerates to simulate air resistance."*

- **Sprite Particle** — A particle rendered as a flat 2D image (sprite) that always faces the camera. The most common and cheapest particle type. Used for fire, smoke, sparks, and most 2D effects.
  *"Use soft-edged circular sprite particles for the dust cloud when the character lands from a jump."*

- **Mesh Particle** — A particle rendered as a 3D mesh instead of a flat sprite. More expensive but looks correct from any angle. Used for debris, shrapnel, and chunky effects.
  *"Spawn mesh particles shaped like rock chunks when the wall explodes, with random rotation and gravity."*

- **Trail Renderer** — A component that draws a ribbon or trail behind a moving object. Used for sword swipes, bullet traces, magic projectiles, and speed lines.
  *"Add a trail renderer to the sword that draws a white-to-transparent arc during attack animations."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=trail+renderer+game+effect+sword+swipe)

- **Billboard** — A flat surface that always rotates to face the camera. Used for particles, distant trees, lens flares, and any element that doesn't need to look correct from the side.
  *"Render distant crowd members as billboarded sprites — they only need to look right from the player's perspective."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=billboard+sprite+3d+game+always+facing+camera)

- **Bloom** — A post-processing effect that makes bright areas bleed light into surrounding pixels, simulating how real cameras and eyes perceive intense light. Makes emissive surfaces and lights feel radiant.
  *"Add subtle bloom to the neon signs and magic effects — just enough glow to feel luminous without washing out the scene."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=bloom+effect+game+post+processing+glow)

- **Distortion Shader** — A shader that warps the pixels behind it to create heat haze, shockwave, or underwater ripple effects. Reads from the screen buffer and offsets pixel positions.
  *"Apply a distortion shader to the heat above the lava pool — subtle rippling that warps the background geometry."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=distortion+shader+heat+haze+game+effect)

### Shaders & Rendering

The programs that tell the GPU how to draw every pixel on screen.

- **Shader** — A small program that runs on the GPU to determine how a surface looks. Controls color, lighting, transparency, distortion — anything visual. The paintbrush of real-time rendering.
  *"Write a shader that makes the character flash white for 0.1 seconds when they take damage."*

- **Fragment / Pixel Shader** — The shader stage that determines the final color of each pixel. Runs once per pixel per triangle. This is where textures get sampled, lighting gets calculated, and effects happen.
  *"Write a fragment shader that blends between two textures based on the terrain's slope angle."*

- **Vertex Shader** — The shader stage that processes each vertex position before the triangles are drawn. Used for mesh deformation, wind animation, water waves, and camera transformations.
  *"Write a vertex shader that offsets grass mesh vertices based on a wind noise texture for natural swaying."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=vertex+shader+wind+grass+game+effect)

- **Render Pipeline** — The sequence of stages the GPU follows to turn 3D scene data into a 2D image on screen. Vertex processing → rasterization → fragment processing → output. Modern engines let you customize this.
  *"Switch from the built-in render pipeline to URP for better mobile performance and custom shader support."*

- **Draw Call** — A single instruction from the CPU to the GPU to render a batch of geometry. Each material change or mesh requires at least one draw call. Too many draw calls tank frame rate.
  *"Reduce draw calls from 800 to 200 by batching objects that share the same material and merging static meshes."*

- **Overdraw** — When the GPU draws pixels that are immediately covered by something in front of them. Transparent particles are the biggest offender — each layer redraws the same pixels.
  *"Visualize overdraw in the particle-heavy boss fight — the overlapping fire effects are drawing the same pixels 8 times."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=overdraw+visualization+game+rendering+particles)

- **Alpha Blending** — The process of combining a transparent pixel's color with whatever is behind it. Enables transparency, glass, fog, and particle effects. Expensive because it prevents early depth rejection.
  *"Use alpha blending for the ghost enemy so the environment shows through with a 50% transparent blue tint."*

- **Screen-space Effect** — A post-processing effect applied to the final 2D image rather than individual objects. Bloom, ambient occlusion, motion blur, and color grading are all screen-space effects.
  *"Add screen-space ambient occlusion to darken corners and crevices where light wouldn't naturally reach."*

- **Post-processing** — Effects applied after the scene is rendered, operating on the 2D screen image. The finishing layer that adds bloom, color grading, vignette, film grain, and other cinematic touches.
  *"Stack post-processing effects: subtle bloom, film grain, chromatic aberration at screen edges, and a warm color grade."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=post+processing+game+before+after+effects)

- **Cel Shading** — A rendering technique that mimics hand-drawn animation with flat color bands and hard-edged shadows instead of smooth gradients. Also called toon shading.
  *"Apply cel shading to the character with three value bands (shadow, midtone, highlight) and a dark outline pass."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=cel+shading+toon+shader+game+art)

### Performance & Optimization

Making game art run smoothly within hardware budgets.

- **Texture Compression** — Reducing texture file size and memory usage through GPU-native compression formats (BC, ASTC, ETC2). Lossy but usually imperceptible. Mandatory for shipping games.
  *"Compress all diffuse textures to BC7 format and normal maps to BC5 to cut VRAM usage in half."*

- **Mipmapping** — Storing pre-shrunk versions of a texture at progressively smaller resolutions. The GPU automatically uses the appropriate mip level based on distance, preventing shimmering artifacts on distant surfaces.
  *"Enable mipmapping on all terrain textures to eliminate the shimmering on the distant hillside."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=mipmapping+texture+mip+levels+3d+game)

- **Atlasing** — Packing multiple textures or sprites into a single larger texture to reduce material switches and draw calls. Both 2D sprite atlases and 3D texture atlases serve the same purpose.
  *"Atlas all the dungeon prop textures onto a single 2048 sheet so the entire room renders in one draw call."*

- **Batching** — Combining multiple draw calls into one by grouping objects that share the same material. Static batching merges meshes at build time; dynamic batching groups them at runtime.
  *"Enable static batching for all non-moving environment props to cut the scene's draw calls from 400 to 60."*

- **Culling** — Not rendering objects the player can't see. Frustum culling skips objects outside the camera view. Occlusion culling skips objects hidden behind other objects. Free performance.
  *"Set up occlusion culling for the indoor level — rooms behind walls shouldn't consume any rendering budget."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=frustum+culling+occlusion+culling+game+rendering)

- **LOD Switching** — Automatically replacing high-detail meshes with simpler versions as the camera moves away. Aggressive LOD switching is the single biggest polygon saver in open-world games.
  *"Configure LOD switching distances: full detail within 20m, medium at 50m, low-poly at 100m, billboard at 200m."*

- **Overdraw Budget** — The maximum acceptable amount of pixel overdraw in a scene, usually measured as a multiplier (2x means each pixel is drawn twice on average). Particle-heavy effects are the main threat.
  *"Keep the overdraw budget under 3x for mobile — limit simultaneous particle effects and use opaque particles where possible."*

- **Fill Rate** — The number of pixels the GPU can render per second. Fill rate becomes the bottleneck when lots of transparent effects, high-resolution rendering, or complex fragment shaders are in play.
  *"The fill rate is maxed out on the water shader — reduce the reflection resolution from full to half to recover frame budget."*

- **Polycount Budget** — The maximum number of polygons a scene, character, or prop can use. Budgets vary by platform: a mobile character might get 5K tris, a console character 100K.
  *"Set the polycount budget for mobile: 5K tris per character, 50K total for visible environment, 10K for props."*

- **Instancing** — Rendering many copies of the same mesh in one draw call by sending per-instance data (position, color, scale) to the GPU. Essential for grass, trees, crowds, and repeated props.
  *"Use GPU instancing to render 10,000 grass blades in a single draw call with per-instance color variation."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=gpu+instancing+game+rendering+grass+trees)

---

## Game-Specific Art

Art disciplines and formats unique to games.

### Environment Art

Building the worlds players explore — from tile grids to open landscapes.

- **Tilemap** — A grid-based system for building 2D levels from small, reusable tiles. The map is an array of tile indices. Efficient, easy to edit, and the backbone of 2D level construction.
  *"Build a tilemap-based level editor that lets designers paint terrain, place props, and set collision per tile."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=tilemap+2d+game+level+editor+grid)

- **Auto-tiling** — An algorithm that automatically selects the correct tile variant based on neighboring tiles. Draws the right wall corners, cliff edges, and water borders without manual placement.
  *"Implement auto-tiling rules for the cliff tileset so edges, corners, and inner corners select automatically."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=auto+tiling+game+algorithm+bitmask)

- **Parallax Scrolling** — Moving background layers at different speeds to create depth illusion. Distant layers move slowly; near layers move quickly. The classic trick for 2D depth.
  *"Set up five parallax scrolling layers for the forest level: sky (0.1x), far mountains (0.3x), mid trees (0.5x), near trees (0.8x), foreground bushes (1.2x)."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=parallax+scrolling+2d+game+depth+layers)

- **Skybox** — A large cube or sphere textured with sky imagery that surrounds the entire 3D scene. Creates the illusion of a distant environment — sky, clouds, stars, distant mountains.
  *"Paint a stylized skybox with warm sunset gradients, scattered clouds, and distant mountain silhouettes."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=skybox+game+3d+environment+sky)

- **Terrain** — A large-scale mesh (usually heightmap-based) representing the ground surface of an outdoor scene. Terrain systems handle LOD, texture blending, and vegetation placement.
  *"Sculpt the terrain with rolling hills, a river valley, and cliff faces, then blend grass, dirt, and rock textures by slope."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=terrain+game+3d+heightmap+texture+blending)

- **Prop** — A discrete placeable object in a game environment. Barrels, crates, lamps, books, chairs. Props add detail and life to environments built from modular pieces.
  *"Model a set of medieval tavern props: tankard, candle, plate, stool, barrel, and hanging lantern."*

- **Modular Kit** — A set of standardized, interlocking pieces designed to snap together and build large environments from reusable parts. Walls, floors, columns, and trim that combine in many configurations.
  *"Design a modular dungeon kit with straight walls, corners, T-junctions, doorways, and floor pieces on a 2m grid."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=modular+kit+3d+game+environment+level+pieces)

- **Level Art Pass** — A stage of level development focused on visual quality. Block-out (grey boxes) → first art pass (basic materials) → final art pass (polished, lit, detailed). Each pass increases fidelity.
  *"The gameplay is locked in — start the first art pass replacing all greybox geometry with textured modular pieces."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=level+art+pass+greybox+to+final+game+development)

- **Biome** — A visually and thematically distinct region of a game world. Desert, forest, tundra, volcanic — each biome has its own palette, props, terrain, lighting, and audio.
  *"Define four biomes for the open world: temperate forest, coastal cliffs, swamp, and volcanic highlands — each with a unique palette and prop set."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+biome+environment+art+different+regions)

- **Environmental Palette** — The specific set of colors assigned to a particular environment or biome. Distinct from the game's overall palette — each area gets its own color identity.
  *"Create an environmental palette for the mushroom forest: deep purples, bioluminescent cyan, warm amber from spore particles."*

### Character Art

Designing and animating the characters players see, control, and fight.

- **Character Sheet** — A reference document showing a character's design from multiple angles with color callouts, proportion notes, and key details. The blueprint artists follow to keep the character consistent.
  *"Draw a character sheet for the knight protagonist showing front, side, and back views with armor detail callouts."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=character+sheet+game+art+reference+turnaround)

- **Turnaround** — A series of drawings showing a character from evenly spaced angles (typically front, three-quarter, side, back). Used by 3D modelers to build an accurate mesh from 2D designs.
  *"Provide a full turnaround of the character design so the 3D modeler can match proportions from every angle."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=character+turnaround+sheet+360+game+design)

- **Idle Animation** — The animation that plays when the character is standing still. Breathing, shifting weight, blinking. A good idle animation makes a character feel alive even when the player isn't touching the controller.
  *"Animate an idle for the warrior: subtle chest breathing, slight weight shift, occasional look around — loop at 3 seconds."*

- **Walk Cycle** — A looping animation of a character walking. The foundation of character animation — getting it right means correct weight, timing, and personality. A bad walk cycle undermines everything else.
  *"Create a walk cycle for the merchant NPC with a heavy, plodding gait that conveys their armored backpack."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=walk+cycle+animation+game+character+frames)

- **Run Cycle** — A looping animation of a character running. More dynamic than a walk cycle — the body leans forward, arms pump harder, and there's a flight phase where both feet leave the ground.
  *"Animate a run cycle for the nimble rogue with exaggerated forward lean and wide arm swings."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=run+cycle+animation+game+character+frames)

- **Attack Animation** — The animation for a character performing an offensive action. Must communicate the attack's reach, timing, and power. Anticipation → swing → follow-through is the classic structure.
  *"Animate a two-handed sword overhead slam with a clear 6-frame windup so players can read the attack and dodge."*

- **Hit Reaction** — The animation that plays when a character takes damage. Flinches, staggers, knockbacks. Sell the impact of combat — without hit reactions, attacks feel like they pass through targets.
  *"Create hit reaction animations for light hits (head snap) and heavy hits (full stagger back two steps)."*

- **Expression Sheet** — A reference showing a character's face in various emotional states. Happy, angry, sad, surprised, determined. Essential for characters that appear in dialogue or cutscenes.
  *"Draw an expression sheet for the companion character showing 8 emotions for use in the dialogue portrait system."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=expression+sheet+character+emotions+game+art)

- **Costume Design** — The clothing, armor, and accessories that define a character's visual identity and communicate their role. A healer looks different from a tank looks different from a rogue — costume tells the player.
  *"Design three costume tiers for the mage class: starter robes, mid-game enchanted vestments, and endgame arcane regalia."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=costume+design+game+character+tiers+progression)

- **Proportions** — The relative size relationships between body parts. Realistic games use 7-8 heads tall. Chibi styles use 2-3 heads. Heroic styles exaggerate shoulders and hands. Proportions define the art style's personality.
  *"Set character proportions at 5 heads tall with oversized hands and feet for a cartoony action game feel."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=character+proportions+game+art+chibi+realistic+heroic)

### UI & HUD Art

The visual layer that communicates game state, menus, and feedback to the player.

- **HUD Skin** — The visual design applied to the heads-up display elements. Frames, backgrounds, decorative borders that match the game's art style. A sci-fi HUD looks different from a fantasy one.
  *"Design a HUD skin for the steampunk game: brass-framed health meters, gear-shaped icons, and riveted panel backgrounds."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+hud+skin+design+fantasy+scifi)

- **Health Bar** — A visual representation of a character's remaining hit points. Bars, hearts, segmented pips, radial gauges — the format communicates how health works mechanically.
  *"Design a segmented health bar with 10 pips that crack individually as damage is taken and pulse red at low health."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=health+bar+game+ui+design+styles)

- **Icon Set** — A collection of icons designed with consistent style, size, and visual language. Status effects, inventory items, abilities, map markers — all need to work as a unified family.
  *"Create a 24-icon set for status effects (poison, burn, freeze, stun, etc.) in a consistent 32x32 flat style with distinct color coding."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+icon+set+status+effects+inventory)

- **Tooltip** — A small popup that displays information when the player hovers over or selects an element. Must be readable, correctly positioned, and styled to match the UI without blocking gameplay.
  *"Design a tooltip template for inventory items showing name, icon, stats, rarity border color, and flavor text."*

- **Radial Menu** — A circular menu where options are arranged around a center point, selected by moving the stick or cursor in a direction. Fast for controller input and feels natural for directional selection.
  *"Design an 8-slot radial menu for weapon switching that shows weapon icons, ammo counts, and highlights the selected slot."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=radial+menu+game+ui+weapon+wheel)

- **Inventory Grid** — A grid layout for managing items, where each item occupies one or more grid cells. The spatial element adds a light puzzle to inventory management (see: Resident Evil 4's attache case).
  *"Design an inventory grid that supports 1x1, 1x2, and 2x2 item sizes with drag-and-drop rearrangement."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=inventory+grid+game+ui+resident+evil+tetris)

- **Minimap** — A small map overlay showing the player's immediate surroundings, typically in a corner of the screen. Shows terrain, objectives, enemies, and points of interest at a glance.
  *"Design a circular minimap with fog of war, objective markers, enemy dots, and a north indicator that rotates with the camera."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=minimap+game+ui+design+circular+overlay)

- **Screen-space UI** — Interface elements fixed to screen coordinates. Health bars, menus, minimaps, score counters — they stay in the same screen position regardless of camera movement.
  *"Lay out the screen-space UI: health top-left, minimap top-right, ability bar bottom-center, inventory bottom-right."*

- **World-space UI** — Interface elements positioned in the 3D game world. Name plates above characters, interaction prompts on objects, floating damage numbers. They move with the scene and exist "in" the world.
  *"Add world-space UI name plates above NPC heads that fade in within 10 meters and always face the camera."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=world+space+ui+game+nameplates+floating+text)

- **Visual Feedback** — Any visual response that confirms a player's action or communicates game state. Screen shake on hit, flash on pickup, color change on selection. Without visual feedback, games feel dead.
  *"Add visual feedback for every combat hit: enemy flash white, screen shake for 2 frames, particle burst at contact point, damage number popup."*
