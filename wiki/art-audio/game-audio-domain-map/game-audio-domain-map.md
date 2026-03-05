# Game Audio Domain Map

A curated vocabulary reference for game audio. Use these terms to prompt AI tools with specificity — each entry includes a plain-language definition and an example prompt showing the term in context.

**How to use this page:** Scan the branch that matches your audio problem. Grab the precise term, drop it into your prompt, and get better results than vague descriptions ever produce.

---

## Sound Design

Creating and shaping individual sounds — the craft of making things sound like *something*.

### Source Material & Recording

Where raw sounds come from before processing.

- **Foley** — Sound effects created by performing physical actions in sync with visuals. Footsteps on gravel, cloth rustling, a door creaking. The human side of SFX production.
  *"Record a foley pass for a character walking through a forest: footsteps on leaves, brushing branches, and armor clinks."*

- **Field Recording** — Capturing sounds in real-world environments using portable recorders. Ambiences, machinery, animals, weather. The raw material library for most sound design.
  *"Plan a field recording session to capture urban ambiences: traffic, crowd murmur, distant sirens, and subway rumble."*

- **Library Sound** — Pre-recorded sound effects from commercial or personal collections. Starting points that get layered and processed into final assets.
  *"Pull library sounds for a sword fight: blade rings, whooshes, and body impacts. What processing do I need to make them feel unique?"*

- **Waveform** — The visual representation of an audio signal over time. Reading waveforms tells you about amplitude, duration, and transient shape before you even hit play.
  *"This explosion waveform has a weak transient — how do I reshape the attack to hit harder without clipping?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=audio+waveform+transient+sound+design)

- **Sample Rate** — How many times per second an audio signal is measured. 44.1 kHz is CD quality, 48 kHz is standard for games and film. Higher rates capture more high-frequency detail.
  *"Should I record foley at 96 kHz and downsample to 48 kHz, or just record at 48 kHz? What's the practical difference for game SFX?"*

- **Bit Depth** — The number of bits used to represent each audio sample. 16-bit gives 96 dB of dynamic range, 24-bit gives 144 dB. Record at 24-bit, deliver at 16-bit.
  *"Explain why I should record at 24-bit even though my game ships 16-bit audio assets."*

- **Transient** — The initial burst of energy at the start of a sound. The snap of a snare, the click of a button, the crack of a gunshot. Transients define perceived impact.
  *"My UI click sounds feel mushy — how do I sharpen the transient without making it harsh?"*

- **Room Tone** — The ambient sound of a space with no deliberate activity. Every room has a sonic fingerprint — air conditioning hum, electrical buzz, distant traffic. Essential for seamless edits.
  *"Record 60 seconds of room tone for each location before the foley session starts. Why is this step critical for editing?"*

- **Sound Library** — An organized collection of categorized, tagged audio files ready for use. A well-maintained library is the most valuable asset a sound designer owns.
  *"Design a metadata tagging scheme for a game sound library covering weapons, UI, ambience, and creatures."*

- **Contact Microphone** — A microphone that picks up vibrations through solid surfaces rather than air. Captures sounds impossible to record with standard mics — the voice of objects themselves.
  *"Use a contact mic on a metal fence to capture resonant tones for a sci-fi force field sound effect."*

### Synthesis & Processing

Building and transforming sounds with tools and techniques.

- **Subtractive Synthesis** — Starting with a harmonically rich waveform and filtering frequencies away. The classic analog synth approach — shape sound by removing what you don't want.
  *"Design a laser blaster sound using subtractive synthesis: start with a saw wave, apply a resonant low-pass filter with a fast envelope sweep."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=subtractive+synthesis+filter+envelope+diagram)

- **FM Synthesis** — Frequency modulation — one oscillator modulates the frequency of another, creating complex timbres from simple waveforms. The secret behind metallic, bell-like, and glassy tones.
  *"Create a crystalline UI notification sound using FM synthesis with a high modulation index and fast decay."*

- **Granular Synthesis** — Slicing audio into tiny grains (1-100ms) and reassembling them. Stretch time without changing pitch, create textures from any source, turn a piano into a pad.
  *"Take a thunder recording and use granular synthesis to create a 30-second evolving ambient texture for a storm level."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=granular+synthesis+grains+audio+diagram)

- **Additive Synthesis** — Building sounds by stacking individual sine waves at specific frequencies and amplitudes. The opposite of subtractive — construct exactly what you want from pure tones.
  *"Use additive synthesis to recreate the harmonic spectrum of a church bell for a fantasy game's town square."*

- **Wavetable Synthesis** — Sweeping through a table of stored waveform shapes over time. Combines the simplicity of oscillators with the complexity of sampled timbres.
  *"Design an evolving magic spell charge-up sound using wavetable synthesis — morph from a soft sine to a harsh digital waveform as the spell builds."*

- **Physical Modeling** — Simulating the physics of real instruments and objects mathematically. A vibrating string, a resonating tube, a struck membrane. Sound from equations, not samples.
  *"Use physical modeling to generate procedural footstep sounds that respond to surface material and step force at runtime."*

- **Pitch Shifting** — Changing the pitch of audio without altering its duration. Shift a dog bark down two octaves and it becomes a monster growl. One of the most powerful sound design tools.
  *"Pitch-shift a baby's cry down 12 semitones and layer it with a lion roar for a creature vocalization."*

- **Time Stretching** — Changing the duration of audio without altering its pitch. Slow an explosion down 4x to hear its internal detail. Speed up ambience to create nervous energy.
  *"Time-stretch a glass shatter to 200% length for a slow-motion impact effect. Which algorithm preserves the transients best?"*

- **Convolution** — Applying the acoustic character of one sound to another using impulse responses. Run a synth through the reverb of a cathedral or the resonance of a metal pipe.
  *"Use convolution with a guitar body impulse response to make a synthesized string sound feel wooden and acoustic."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=convolution+reverb+impulse+response+diagram)

- **Distortion** — Clipping, saturating, or mathematically warping a waveform to add harmonics and aggression. From subtle warmth to total destruction.
  *"Apply tube-style saturation to a clean synth bass to give it analog warmth, then compare with bitcrusher distortion for a retro 8-bit version."*

### Layering & Sound Building

Combining elements into complete, polished sound effects.

- **Layering** — Stacking multiple sounds to create a composite effect. A gunshot might be: a starter pistol crack + a cannon boom + a metallic shell casing + a low-end sub thud.
  *"Layer a punch sound effect from five components: knuckle impact, body thud, cloth movement, vocal grunt, and low-frequency sub hit."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=sound+design+layering+sfx+components+diagram)

- **Sweetener** — A subtle added element that enhances a sound without being consciously noticed. A tiny high-frequency sparkle on a coin pickup. A sub-bass rumble under a door slam.
  *"Add a sweetener to my menu selection sound — a subtle pitched shimmer that makes it feel more polished without being identifiable."*

- **Transient Shaping** — Controlling the attack and sustain portions of a sound independently. Sharpen a dull impact or soften an aggressive click without affecting the tail.
  *"Use transient shaping to add snap to footstep recordings that sound flat, boosting the attack by 6 dB while leaving the sustain unchanged."*

- **Sound Variation** — Creating multiple versions of the same sound to avoid repetitive playback. Pitch randomization, round-robin selection, and layer swapping all help.
  *"Generate 8 variations of a sword swing whoosh using pitch shifting, time stretching, and different layering combinations."*

- **One-Shot** — A sound effect that plays once from start to finish — a gunshot, a UI click, a jump sound. No looping, no sustain phase. Fire and forget.
  *"Export a set of one-shot impact sounds at consistent loudness for a physics system that plays them on collision events."*

- **Loop Point** — The exact sample where a looping sound seamlessly repeats. Bad loop points cause clicks or rhythmic artifacts. Good ones are invisible.
  *"Find a clean loop point in this 10-second engine rumble so it plays indefinitely without audible repetition."*

- **Envelope** — The shape of a sound's amplitude over time, typically described as ADSR: Attack, Decay, Sustain, Release. Controls whether a sound snaps, swells, or fades.
  *"Design an ADSR envelope for a laser beam: instant attack, no decay, full sustain while the trigger is held, and a 200ms release tail."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=ADSR+envelope+attack+decay+sustain+release+diagram)

- **Crossfade** — Overlapping the end of one sound with the beginning of another so the transition is smooth. Essential for seamless loops and state transitions.
  *"Crossfade between idle and running engine loops over 150ms so the transition doesn't pop or stutter."*

- **Normalization** — Adjusting a sound's peak or average level to a target loudness. Peak normalization sets the loudest sample to 0 dBFS. Loudness normalization targets a perceptual level (LUFS).
  *"Normalize all UI sound effects to -14 LUFS so they play at consistent perceived loudness regardless of waveform shape."*

- **Noise Floor** — The baseline level of unwanted noise in a recording or signal chain. Hiss, hum, and room noise that lives under your actual sound. Lower is better.
  *"My foley recordings have a high noise floor from the HVAC system. What's the best way to reduce it without artifacts?"*

---

## Music & Composition

Scoring games — from traditional composition to adaptive systems that respond to play.

### Scoring & Structure

How game music is organized, arranged, and delivered.

- **Diegetic Music** — Music that exists within the game world. A radio playing in a car, a bard strumming in a tavern, a jukebox in a bar. Characters can hear it too.
  *"Design a diegetic music system where the player hears a bard's song that changes lyrics based on their completed quests."*

- **Non-Diegetic Music** — Music that exists outside the game world — the traditional score. The player hears it but the characters don't. Sets mood, pacing, and emotional tone.
  *"Write a non-diegetic combat theme that intensifies as the player's health drops below 25%."*

- **Leitmotif** — A recurring musical theme associated with a character, location, or idea. Darth Vader has one. Link has one. When done well, a few notes trigger instant recognition.
  *"Compose a leitmotif for the villain that first appears as a gentle piano melody in Act 1 and returns as a distorted brass statement in the final battle."*

- **Stinger** — A short musical phrase triggered by a specific event. A victory fanfare, a death jingle, a discovery motif. Punctuates moments with musical exclamation marks.
  *"Create a 3-second stinger for item discovery — bright, ascending, and resolving on a major chord."*

- **Underscore** — Background music that supports the scene without demanding attention. The musical wallpaper that shapes emotion while the player focuses on gameplay.
  *"Write an underscore for a puzzle area: low tension, contemplative, and able to loop for 10+ minutes without becoming annoying."*

- **Stem** — An isolated submix of a music track: just the drums, just the strings, just the bass. Stems allow the audio system to remix music in real time based on game state.
  *"Export the combat theme as four stems — percussion, bass, melody, and pads — so the adaptive music system can layer them independently."*

- **Loop** — A music segment designed to repeat seamlessly. The backbone of game music. A good loop is one you don't notice restarting.
  *"Compose a 90-second exploration loop in 6/8 time that avoids a strong downbeat at the loop point so the restart is imperceptible."*

- **Intro/Outro** — Non-looping segments that bookend a looping track. The intro establishes the theme, the outro provides a graceful exit when transitioning to a different track.
  *"Write a 4-bar intro that establishes the dungeon theme before the main loop begins, and a 2-bar outro that resolves to the hub world key."*

- **Tempo** — The speed of music measured in beats per minute (BPM). 60 BPM feels contemplative. 140 BPM feels urgent. Tempo is the single strongest lever for musical energy.
  *"What BPM range works for a stealth game's ambient music that needs to feel tense but not rushed?"*

- **Meter** — How beats are grouped into measures. 4/4 feels natural and driving. 3/4 feels waltz-like. 7/8 feels unsettling. Meter shapes the rhythmic feel of everything built on top of it.
  *"Use a 5/4 meter for an alien civilization's theme to make it feel subtly wrong to Western ears."*

### Adaptive & Interactive Music

Music that responds to gameplay in real time.

- **Horizontal Re-sequencing** — Rearranging the order of musical segments based on game state. Instead of A→B→C, the system might play A→C→A→B. Same pieces, different sequence.
  *"Design a horizontal re-sequencing system for an open-world game where exploration, combat, and discovery segments chain in any order with valid transitions."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=horizontal+resequencing+adaptive+music+game+audio)

- **Vertical Remixing** — Adding or removing musical layers (stems) in response to game state. Calm exploration gets ambient pads. Combat adds drums and brass. Same harmonic content, different intensity.
  *"Implement vertical remixing for a stealth game: add tension strings when guards are suspicious, full percussion when detected, strip to pads when hidden."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=vertical+remixing+layered+music+game+audio+diagram)

- **Transition** — The musical bridge between two states. A fill, a cymbal swell, a filter sweep, or a hard cut. How music moves between sections without jarring the player.
  *"Design transition rules for moving between exploration and combat music: how long is the crossfade, does it quantize to the bar, and what fill plays?"*

- **Quantization** — Snapping musical transitions to rhythmically meaningful points — beat boundaries, bar lines, or phrase endings. Prevents transitions from landing in musically awkward places.
  *"Quantize all combat music transitions to the nearest bar line so the shift from 4/4 combat to 3/4 exploration always feels intentional."*

- **Musical State Machine** — A system that defines which musical states exist and the rules for transitioning between them. Exploration → Tension → Combat → Victory, with defined entry/exit conditions.
  *"Design a musical state machine with five states: safe, suspicious, combat, boss, and victory. Define transition triggers and crossfade durations for each pair."*

- **Intensity Parameter** — A single variable (often 0-1) that drives musical complexity. At 0.2, only pads play. At 0.5, melody enters. At 1.0, full orchestra with percussion. Maps gameplay tension to musical response.
  *"Create an intensity curve that maps the player's proximity to enemies, health percentage, and ammo count to a 0-1 music intensity parameter."*

- **Branching Music** — Pre-composed segments with multiple possible continuations. At each decision point, the system chooses the next segment based on game state. More composed control than pure layering.
  *"Compose a branching music tree for a boss fight with three phases, each having calm and intense branches based on player performance."*

- **Dynamic Mixing** — Adjusting volume, EQ, and effects on music in real time based on context. Duck the music when dialogue plays, boost low end during explosions, filter the score when underwater.
  *"Set up dynamic mixing rules: duck music by 6 dB during dialogue, apply a low-pass filter when the player enters water, and boost bass during earthquakes."*

- **Procedural Music** — Music generated algorithmically at runtime rather than pre-composed. Rules define scales, chord progressions, rhythmic patterns, and instrumentation. Every playthrough sounds different.
  *"Design a procedural music system for a space exploration game that generates ambient pieces based on the biome type and time of day."*

- **Beat Sync** — Aligning game events to musical beats. A platform appears on the downbeat, enemies attack on the snare, a door opens on the chorus. When gameplay and music lock together.
  *"Implement beat sync so that enemy spawn waves align with the measure boundaries of the combat music."*

### Harmonic & Tonal Language

The emotional vocabulary of pitch, harmony, and key.

- **Key** — The tonal center of a piece — which note feels like home. C major feels bright. A minor feels melancholic. Changing keys shifts the emotional landscape.
  *"What key should the main theme be in if the game starts hopeful but ends in tragedy? How do I modulate between them?"*

- **Mode** — Scales beyond basic major and minor. Dorian sounds noble, Mixolydian sounds heroic, Phrygian sounds ominous, Lydian sounds magical. Modes are instant mood selectors.
  *"Use Lydian mode for the fairy kingdom theme and Phrygian for the dark temple. What makes each mode evoke those feelings?"*

- **Chord Progression** — The sequence of chords that creates harmonic movement. I-IV-V-I feels resolved. i-VI-III-VII feels epic. Progressions are the emotional backbone of any piece.
  *"Write a chord progression for a title screen that feels nostalgic and bittersweet — suggest something beyond the standard I-V-vi-IV."*

- **Consonance/Dissonance** — How stable or tense intervals and chords sound. Perfect fifths are consonant (stable). Tritones are dissonant (tense). The push-pull between them creates musical drama.
  *"Increase dissonance in the horror ambient track as the player approaches the monster's lair — start with open fifths and gradually introduce tritones and minor seconds."*

- **Modulation** — Changing from one key to another within a piece. A smooth modulation can lift the energy (up a half step for the final chorus) or shift the mood entirely.
  *"Modulate the exploration theme from D major to F# minor when the player enters the cursed forest. What pivot chord makes this transition smooth?"*

- **Ostinato** — A short musical pattern that repeats persistently. The cello line in Jaws. The piano figure in Minecraft. Ostinatos create hypnotic momentum and work beautifully with adaptive layering.
  *"Write a two-bar ostinato for the strategy game's planning phase — something rhythmic enough to feel purposeful but repetitive enough to loop indefinitely."*

- **Orchestration** — Choosing which instruments play which parts. A melody on solo flute feels intimate. The same melody on full brass feels triumphant. Orchestration is how you paint with sound.
  *"Orchestrate the hero's leitmotif for three contexts: solo oboe for the village, full strings for the overworld, and brass with timpani for the final battle."*

- **Motif** — A short melodic or rhythmic idea that serves as a building block. Shorter than a leitmotif — sometimes just three or four notes. The DNA of thematic composition.
  *"Build a four-note motif for the game's magic system that can be developed into a full theme for the wizard's tower level."*

- **Drone** — A sustained note or chord held continuously beneath other musical activity. Creates a sense of place and groundedness. Common in ambient, horror, and meditation music.
  *"Use a low C drone under the cave exploration music to create a sense of depth and permanence."*

- **Cadence** — A harmonic formula that creates a sense of ending or continuation. A perfect cadence (V-I) feels conclusive. A deceptive cadence (V-vi) subverts expectation. Cadences punctuate musical phrases.
  *"End the victory fanfare on a perfect cadence for satisfaction, but use a half cadence for the 'to be continued' screen to leave tension unresolved."*

---

## Spatial & Interactive Audio

How sound exists in three-dimensional space and responds to player actions.

### 3D Positioning & Propagation

Placing sounds in space and simulating how they travel.

- **Spatialization** — Positioning a sound in 3D space relative to the listener. A footstep behind you sounds different from one ahead. The foundation of immersive game audio.
  *"Set up spatialization for a horror game so the player can locate enemy footsteps by ear alone using headphones."*

- **Attenuation** — How a sound's volume decreases with distance. Linear falloff sounds artificial. Logarithmic falloff mimics real physics. The curve shape determines how large the world feels.
  *"Configure attenuation curves for gunshots: audible at 200m, clearly directional at 50m, and overwhelming at point-blank. Use logarithmic rolloff."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=sound+attenuation+distance+curve+game+audio)

- **HRTF (Head-Related Transfer Function)** — A filter that simulates how your ears and head shape sound from different directions. The magic behind binaural 3D audio on headphones.
  *"Enable HRTF processing for the VR horror game so players can distinguish sounds above, below, and behind them using standard headphones."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=HRTF+head+related+transfer+function+3d+audio+diagram)

- **Panning** — Distributing a sound between left and right channels (stereo) or across multiple speakers (surround). The simplest form of spatial positioning.
  *"Auto-pan the ambient bird calls slowly between left and right channels to create a sense of movement in the forest canopy."*

- **Occlusion** — Reducing high frequencies and volume when a sound source is blocked by a solid object. A voice behind a wall sounds muffled. Occlusion makes walls feel real.
  *"Implement occlusion so gunshots through concrete walls lose high frequencies and drop 12 dB, but gunshots through wooden doors only lose 4 dB."*

- **Obstruction** — Similar to occlusion but the sound can partially diffract around the obstacle. A sound source around a corner isn't fully blocked — some sound bends around.
  *"Differentiate obstruction from occlusion: when a sound source is around a corner, apply a gentler low-pass filter than when it's behind a solid wall."*

- **Propagation** — How sound travels through a space, including reflections, diffraction, and transmission through materials. Full propagation simulation is expensive but dramatically improves immersion.
  *"Simulate sound propagation through a multi-room dungeon so the player hears distant combat echoing through corridors with appropriate delays and filtering."*

- **Distance Delay** — The time gap between seeing an event and hearing it, based on the speed of sound (~343 m/s). Lightning before thunder. Muzzle flash before gunshot.
  *"Add distance delay to explosions so a blast 500m away has a visible flash 1.5 seconds before the sound arrives."*

- **Doppler Effect** — The pitch shift caused by a sound source moving toward or away from the listener. An approaching siren rises in pitch, then drops as it passes. Adds realism to moving sources.
  *"Apply Doppler effect to racing cars so engines pitch up on approach and down on pass-by, matching their velocity."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=doppler+effect+sound+frequency+shift+diagram)

- **Sound Cone** — A directional emission pattern for a sound source. A megaphone has a narrow cone (loud in front, quiet behind). A speaker has a wider cone. Shapes how sound radiates from its source.
  *"Define a narrow sound cone for the NPC's voice so the player must face them to hear dialogue clearly, with 12 dB drop-off outside the cone."*

- **Listener** — The virtual microphone in the game world, usually attached to the camera or player character. All spatialization is calculated relative to the listener's position and orientation.
  *"Should the audio listener be on the camera or the player character? Compare the tradeoffs for a third-person game with a wide camera offset."*

- **Spread** — How wide a sound source appears in the stereo or surround field. A point source has zero spread. A nearby waterfall should have wide spread, filling both ears as you stand next to it.
  *"Increase the spread parameter on the river ambient emitter so it feels like it surrounds the player when they're standing on the bridge."*

- **Near-Field Effect** — Exaggerated low-frequency boost when a sound source is very close to the listener. The proximity effect. Makes nearby sounds feel physically present and intimate.
  *"Apply a near-field bass boost to the companion's whispered lines when the player leans in close during stealth sections."*

- **Ambisonics** — A full-sphere surround sound format that captures or encodes audio from all directions. Used in VR and 360 video. Decoded to whatever speaker or headphone layout the player has.
  *"Record ambisonic room tones at each key location so the VR player gets accurate environmental audio that rotates with their head."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=ambisonics+spherical+audio+format+diagram)

### Environmental Audio

Sounds that define the world itself — spaces, weather, and atmosphere.

- **Ambience** — The continuous background sound of an environment. Forest birds, city traffic, spaceship hum, dungeon drips. Ambience is the first thing players notice when it's missing.
  *"Design a four-layer ambience for a rainy city night: rain on pavement, distant traffic, occasional thunder, and a flickering neon sign buzz."*

- **Reverb** — The collection of reflections that define a space's acoustic character. A cathedral has long reverb. A closet has short reverb. Reverb tells your ears the size and material of a room without looking.
  *"Set up reverb zones: tight 0.3s plate reverb for indoor corridors, expansive 3.5s hall reverb for the cathedral, and no reverb for outdoor cliffs."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=reverb+types+room+hall+plate+comparison+audio)

- **Early Reflections** — The first sound reflections that reach the listener, arriving within 50ms of the direct sound. They tell your brain the size and shape of the room faster than late reverb does.
  *"Boost early reflections in small rooms to emphasize claustrophobia, and reduce them in open outdoor areas to create a sense of space."*

- **Reverb Zone** — A defined area in the game world with specific reverb settings. Crossing from a tunnel into a cavern should change the reverb. Smooth transitions between zones prevent jarring shifts.
  *"Create reverb zones for the dungeon: tight stone corridor, large echoing cavern, and flooded chamber with bright, splashy reflections."*

- **Ambient Bed** — A continuous, looping background layer that establishes the baseline sound of an environment. Wind, room hum, forest insects. Always playing, rarely noticed.
  *"Mix a three-layer ambient bed for the space station: air circulation hum, distant machinery, and occasional hull creaks."*

- **Ambient Detail** — Occasional, randomly triggered sounds layered on top of the ambient bed. A bird call, a distant door slam, a dripping faucet. Adds life and prevents the environment from feeling static.
  *"Set up ambient detail emitters for the swamp: frog croaks every 8-15 seconds, insect buzzes every 3-7 seconds, and a distant splash every 30-60 seconds."*

- **Weather Audio** — Dynamic sound layers that represent weather conditions: rain intensity, wind strength, thunder timing. Often driven by a weather system that controls volume and layering.
  *"Build a rain audio system with four intensity levels: drizzle, steady rain, downpour, and storm. Crossfade between them over 5 seconds as weather state changes."*

- **Acoustic Material** — The sonic properties assigned to a surface type — wood, metal, stone, carpet. Determines how footsteps, impacts, and reflections sound when interacting with that surface.
  *"Define acoustic materials for the castle: stone floors with sharp footsteps, wooden bridges with hollow thuds, and carpeted throne room with muted steps."*

- **Soundscape** — The complete sonic picture of an environment — ambience, music, interactive sounds, and spatial properties combined. A well-designed soundscape tells you where you are with your eyes closed.
  *"Design the soundscape for a marketplace: vendor shouts, crowd murmur, clinking coins, sizzling food, a distant musician, all with appropriate spatialization."*

- **Impulse Response (IR)** — A recording of a space's acoustic character captured by playing a known signal (like a starter pistol or sine sweep) and recording the result. Used in convolution reverb to clone real spaces.
  *"Capture impulse responses from a parking garage, a church, and a tiled bathroom to use as reverb presets for different game environments."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=impulse+response+recording+convolution+reverb)

- **Audio Zone** — A trigger volume in the game world that changes audio behavior when the player enters. Switches reverb presets, ambient beds, music states, or mix snapshots.
  *"Place audio zones at each doorway in the dungeon so reverb, ambience, and music shift as the player moves between rooms."*

- **Emitter** — A point in the game world that produces sound. Attached to objects, characters, or fixed positions. The emitter's location drives spatialization, attenuation, and occlusion calculations.
  *"Attach audio emitters to each torch in the dungeon so the player hears crackling fire positioned accurately in 3D space."*

- **Underwater Audio** — The distinctive sound filtering that occurs when the listener or source is submerged. Heavy low-pass filtering, reduced high frequencies, muffled quality, and altered propagation speed.
  *"Apply a low-pass filter at 800 Hz and reduce reverb pre-delay when the player dives underwater, then crossfade back to normal over 200ms on surfacing."*

- **Wind Audio** — Dynamic sound layers driven by wind speed and direction. Interacts with environment geometry — whistling through gaps, howling over ridges, rustling foliage.
  *"Build a wind system with three layers: constant base drone, gusting mid-frequency layer, and high-frequency whistling tied to narrow geometry like window frames."*

- **Foliage Audio** — Sounds triggered by movement through vegetation. Grass rustling, branches snapping, leaves crunching. Often driven by the player's speed and the vegetation type.
  *"Trigger foliage audio based on player speed: gentle swishing at walking pace, loud rustling when running, and branch snaps when sprinting through dense brush."*

---

## Audio Systems & Implementation

The technical infrastructure that plays, mixes, and manages sounds in a game engine.

### Middleware & Tools

The software layer between raw audio assets and the game engine.

- **Audio Middleware** — Software that sits between the game engine and the audio output, handling playback, mixing, and real-time effects. Wwise, FMOD, and Fabric are the major players.
  *"Compare Wwise vs. FMOD for a small indie team: licensing costs, learning curve, and integration with Unity."*

- **Wwise** — Audiokinetic's professional audio middleware. Event-driven, deeply customizable, steep learning curve. The industry standard for AAA game audio.
  *"Set up a Wwise project structure for an RPG with combat, dialogue, music, and ambient sound banks."*

- **FMOD** — A widely-used audio middleware with a visual event editor. More approachable than Wwise for small teams. Strong Unity and Unreal integration.
  *"Build an FMOD event for a thunderstorm with randomized thunder timing, rain intensity parameter, and distance-based attenuation on lightning strikes."*

- **Sound Bank** — A packaged collection of audio assets loaded into memory as a group. Organized by level, category, or usage frequency. Loading the right banks at the right time manages memory.
  *"Organize sound banks by level: always-loaded core UI sounds, per-level ambient banks, and on-demand weapon banks loaded when the player equips a new weapon type."*

- **Audio Event** — A trigger point in the game that tells the audio system to do something: play a sound, stop a sound, set a parameter. The bridge between game logic and audio behavior.
  *"Define audio events for a door interaction: Door_Open, Door_Close, Door_Locked, and Door_Break, each with appropriate sound variations."*

- **RTPC (Real-Time Parameter Control)** — A game variable mapped to audio parameters. Player speed controls engine pitch. Health percentage controls heartbeat tempo. The link between game state and sound.
  *"Map an RTPC from player altitude (0-1000m) to wind intensity, reverb size, and music stem volume so the soundscape changes as the player climbs."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=RTPC+real+time+parameter+control+Wwise+game+audio)

- **Switch/State** — A game-driven variable that selects between different sound variations. Surface type switches between wood, metal, and stone footsteps. Weather state selects the appropriate ambient bed.
  *"Create a surface material switch for footsteps: grass, gravel, wood, metal, and water, each with 5 round-robin variations."*

- **Audio Profiler** — A debugging tool that shows what sounds are playing, their CPU cost, memory usage, and channel count in real time. Essential for finding performance problems.
  *"Use the audio profiler to find which sounds are eating the most CPU during combat — I suspect it's too many simultaneous impact sounds."*

- **DSP (Digital Signal Processing)** — Real-time mathematical processing of audio signals: filters, delays, reverbs, pitch shifts. The computational backbone of all audio effects.
  *"What's the DSP cost of running convolution reverb on every sound source vs. using a send bus with a single convolution instance?"*

- **Audio Codec** — The format used to compress audio files. Vorbis (OGG) and Opus for general audio, ADPCM for low-latency SFX, PCM (WAV) for uncompressed quality. Each trades size against quality and decode speed.
  *"Choose codecs for different asset types: WAV for short UI clicks (low latency), Vorbis for music (good compression), and ADPCM for frequently triggered SFX."*

- **Streaming** — Loading and decoding audio from disk in real time rather than holding the entire file in memory. Essential for music and long ambiences. Short SFX are better pre-loaded.
  *"Stream music and ambient loops from disk to save RAM, but pre-load all weapon and UI sounds into memory for zero-latency playback."*

- **Memory Budget** — The RAM allocation reserved for audio assets. On consoles it's tight — a 2 GB title might budget 100-200 MB for audio. Every loaded sound bank counts against it.
  *"Calculate the audio memory budget: 50 MB for always-loaded sounds, 30 MB per level bank, and 20 MB reserved for streaming buffers."*

- **Audio Thread** — A dedicated CPU thread that handles audio mixing and processing, separate from the game logic thread. Keeps audio smooth even when gameplay hitches.
  *"Profile the audio thread — it's spiking to 4ms during combat. Which sounds are the most expensive to process?"*

- **Latency** — The delay between a game event and the sound reaching the player's ears. Input latency for player actions should be under 20ms. High latency makes controls feel disconnected.
  *"Measure audio latency from button press to sound output — target under 15ms for player weapon sounds to maintain responsive feel."*

- **Object Pool** — A pre-allocated set of audio voice objects that get reused rather than created and destroyed per sound. Avoids memory allocation during gameplay, which can cause hitches.
  *"Pre-allocate a pool of 64 audio voices at level load. When a sound triggers, grab a free voice from the pool instead of allocating one."*

### Mixing & Routing

Controlling how sounds combine, compete, and reach the speakers.

- **Bus** — An audio routing channel that groups sounds for collective processing. An "SFX" bus, a "Music" bus, a "Dialogue" bus. Apply volume, EQ, and effects to entire categories at once.
  *"Set up a bus hierarchy: Master → Music, SFX (sub-buses: Weapons, Footsteps, UI), Dialogue, Ambience. Apply a limiter on the master bus."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=audio+bus+routing+mixer+hierarchy+game+audio)

- **Ducking** — Automatically reducing the volume of one bus when another plays. Music ducks when dialogue starts. Ambience ducks during cinematics. Keeps the most important sound on top.
  *"Duck the music bus by 8 dB with a 200ms attack and 500ms release whenever a dialogue event fires."*

- **Sidechain** — Using the signal from one source to control the processing on another. The kick drum's signal triggers compression on the bass. In games, gunshots can pump the music for dramatic effect.
  *"Sidechain the explosion bus to a compressor on the music bus so every big explosion creates a momentary dip in the music, emphasizing the impact."*

- **Priority System** — Rules that determine which sounds play when the system hits its voice limit. High-priority sounds (dialogue, critical alerts) always play. Low-priority sounds (distant ambience) get stolen first.
  *"Set priority rules: dialogue = 100 (never stolen), player weapons = 80, enemy weapons = 60, footsteps = 40, ambient details = 20."*

- **Voice Limiting** — Capping the number of simultaneous instances of a sound. Without limits, 50 overlapping footsteps or gunshots will clip and eat CPU. Limits keep things clean.
  *"Limit footstep sounds to 4 simultaneous voices, stealing the oldest instance when a new one triggers."*

- **Voice Stealing** — Replacing a currently playing sound with a higher-priority one when voice limits are reached. The stolen voice fades out quickly so the new one can play.
  *"Configure voice stealing so that when the combat bus exceeds 16 voices, the quietest and most distant sounds get stolen first with a 50ms fade-out."*

- **Snapshot** — A saved state of the entire mix that can be recalled instantly. A "combat" snapshot boosts SFX and ducks ambience. A "cutscene" snapshot boosts dialogue and ducks everything else.
  *"Create mix snapshots for gameplay, combat, cutscene, and pause menu, each with different bus volumes and effect settings."*

- **Loudness Metering** — Measuring perceived loudness in LUFS (Loudness Units Full Scale) rather than just peak levels. Ensures the game sounds consistent across different content and player hardware.
  *"Target -16 LUFS for dialogue, -20 LUFS for music, and -14 LUFS for critical SFX. Use loudness metering to verify the mix."*

- **Limiter** — A dynamics processor that prevents audio from exceeding a ceiling level. Catches peaks that would cause digital clipping. The safety net at the end of the signal chain.
  *"Place a limiter on the master bus with a ceiling of -0.3 dBFS to prevent clipping during intense combat with dozens of overlapping sounds."*

- **Compression** — Reducing the dynamic range of audio by attenuating loud parts and/or boosting quiet parts. Makes sounds more consistent in volume and helps them cut through a busy mix.
  *"Apply gentle compression to the dialogue bus (4:1 ratio, -18 dB threshold) so whispered and shouted lines sit at similar perceived volumes."*

- **Send/Return** — Routing a copy of a signal to a shared effects bus (send) and blending the processed result back (return). Lets multiple sounds share one reverb instance instead of each running their own.
  *"Route all footstep sounds to a shared reverb send bus so they use one reverb instance, saving DSP. Adjust send levels per surface material."*

- **EQ (Equalization)** — Boosting or cutting specific frequency ranges. High-pass to remove rumble, notch to kill resonances, shelf to add brightness. The most fundamental mixing tool.
  *"Apply a high-pass filter at 80 Hz on the dialogue bus to remove low-frequency rumble, and a gentle 3 kHz boost for intelligibility."*

- **Aux Bus** — An auxiliary mixing bus used for effects processing, sub-grouping, or parallel routing. Send signals to aux buses for shared reverb, delay, or group compression.
  *"Create an aux bus for 'outdoor reverb' and route all exterior sound emitters to it, so switching from indoors to outdoors only requires changing the aux bus effect."*

- **Fade Curve** — The shape of a volume fade (linear, logarithmic, exponential, S-curve). Linear fades sound unnatural. Logarithmic fades match human perception. The curve shape matters more than the duration.
  *"Use a logarithmic fade curve for music crossfades — linear fades have an audible dip in the middle where both tracks are at 50%."*

---

## Voice & Dialogue

Everything related to recorded speech, from production to in-engine playback.

### VO Production

Recording, directing, and processing voice performances.

- **Voice Direction** — Guiding voice actors to deliver the right performance. Providing context, motivation, emotional beats, and technical constraints (timing, intensity, consistency).
  *"Write voice direction notes for the villain's monologue: cold, controlled, with a crack of emotion on the final line. Avoid melodrama."*

- **Voice Casting** — Selecting voice actors whose vocal qualities match the character. Pitch, timbre, accent, age, and emotional range all factor into casting decisions.
  *"Write a casting call for a grizzled dwarven blacksmith: deep register, slight rasp, warmth underneath the gruffness, comfortable with archaic language."*

- **ADR (Automated Dialogue Replacement)** — Re-recording dialogue in a studio to replace on-set or initial recordings. In games, often used to record alternate takes or fix performance issues.
  *"Schedule an ADR session to re-record the protagonist's combat barks — the originals were too calm for the intensity of late-game encounters."*

- **Walla** — Background crowd noise — indistinct murmuring voices that create the sense of populated spaces. Not individual words, but the texture of many people talking at once.
  *"Record a walla track for the tavern scene: 8-10 voices murmuring, occasional laughter, the cadence of conversation without intelligible words."*

- **Vocal Processing** — Effects applied to voice recordings: EQ, compression, de-essing, pitch shifting, distortion. Can clean up raw recordings or transform a human voice into a monster, robot, or spirit.
  *"Process the ghost character's voice: gentle pitch shift down 3 semitones, heavy reverb, subtle chorus, and a high-pass filter to remove body."*

- **Breath Control** — Managing audible breathing in voice recordings. Inhales and exhales can add realism or distract. Removing all breaths sounds robotic; reducing their volume sounds natural.
  *"Reduce breath loudness in the narrator's VO by 10 dB rather than removing breaths entirely — keep the natural cadence without the distraction."*

- **Effort Sounds** — Non-verbal vocalizations: grunts, sighs, gasps, screams, exertion noises. The sounds a character makes during physical action. Often underestimated in importance.
  *"Record a set of effort sounds for the player character: light jump, heavy landing, taking damage (3 intensities), death, and exhausted breathing."*

- **Wild Lines** — Unscripted, improvisational dialogue recorded outside the main script. Actors ad-lib reactions, exclamations, and one-liners that might fit various in-game situations.
  *"At the end of the session, record 20 minutes of wild lines: surprised reactions, frustrated outbursts, and sarcastic comments the player might trigger during exploration."*

- **Pickup Session** — A supplementary recording session to capture lines that were missed, changed, or added after the main session. Common during iteration and localization.
  *"Schedule a pickup session to record 15 new quest-giver lines added after the last sprint and re-record 3 lines where pronunciation was incorrect."*

- **Mouth Noise** — Unwanted clicks, pops, and saliva sounds in voice recordings. Common on close-mic'd sessions. Removed manually or with specialized de-click plugins.
  *"The VO has excessive mouth noise on sibilant consonants — use a de-click plugin with conservative settings, then manually edit what remains."*

- **De-esser** — A frequency-specific compressor that tames harsh sibilance (s, sh, ch sounds) in voice recordings. Prevents piercing high frequencies without dulling the overall vocal tone.
  *"Apply a de-esser targeting 5-8 kHz on the narrator's VO — the sibilance is harsh on headphones but the voice should stay bright and present."*

- **Noise Gate** — A processor that silences audio below a set threshold. Cuts room noise and bleed between spoken lines. Must be set carefully — too aggressive and it clips the start of quiet words.
  *"Set a noise gate on the VO channel at -40 dB with a 5ms attack to eliminate room noise between lines without cutting off soft word beginnings."*

- **Session Script** — The formatted document actors read from during recording, including line IDs, character names, emotional direction, pronunciation guides, and context notes.
  *"Format the session script with line ID, character, emotional beat, and context for each line. Group by scene so the actor can stay in character."*

- **Reference Track** — A previously recorded line or existing audio used as a benchmark for performance matching. Ensures consistency when recording across multiple sessions or with replacement actors.
  *"Provide the reference track from Session 1 so the actor can match the energy and pacing for the pickup lines recorded three months later."*

- **Scratch VO** — Temporary voice recordings used during development before final VO is recorded. Often performed by team members. Placeholders that establish timing, tone, and pacing.
  *"Record scratch VO for the tutorial dialogue so the team can test timing and triggers while waiting for the professional recording session."*

### Dialogue Systems

How spoken lines are triggered, managed, and played in-engine.

- **Dialogue Tree** — A branching conversation structure where player choices determine which lines play next. Nodes contain NPC lines, edges represent player responses.
  *"Build a dialogue tree for the merchant: greeting → browse/sell/quest → each with 2-3 follow-up options → farewell. Include bark fallbacks for revisits."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=dialogue+tree+branching+conversation+game+design)

- **Bark** — A short, contextual voice line triggered by gameplay events rather than conversation. "Reloading!" "Enemy spotted!" "I'm hit!" Barks bring characters to life during action.
  *"Write a bark sheet for a companion character: 5 combat barks, 3 idle barks, 3 discovery barks, and 2 low-health warnings."*

- **Lip Sync** — Matching character mouth animation to recorded dialogue. Can be hand-animated, driven by phoneme analysis, or generated procedurally. Bad lip sync is worse than no lip sync.
  *"Set up automatic phoneme-based lip sync for dialogue using Oculus LipSync — what visemes need mapping and how do I handle blending?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=lip+sync+visemes+phoneme+mapping+game)

- **Subtitle System** — Displaying text synchronized with spoken dialogue. Must handle timing, speaker identification, and accessibility features like font size and background contrast.
  *"Implement a subtitle system that shows speaker name in color, supports variable reading speeds, and handles overlapping dialogue from multiple NPCs."*

- **Dialogue Priority** — Rules for which voice line wins when multiple could play simultaneously. Story-critical dialogue beats barks. Player lines beat NPC ambient chatter. Prevents vocal collisions.
  *"Set dialogue priority: cinematics = 100, story NPC = 80, player barks = 60, companion barks = 50, ambient NPC chatter = 20."*

- **Cooldown** — The minimum time between repeat plays of the same line or bark category. Prevents "I used to be an adventurer" syndrome — hearing the same line every 10 seconds.
  *"Set cooldown timers: combat barks = 8 seconds minimum between same line, idle barks = 45 seconds, ambient NPC chatter = 120 seconds."*

- **Localization Audio** — Recording dialogue in multiple languages. Each language needs casting, direction, recording, and integration. Audio file counts multiply by the number of supported languages.
  *"Plan localization for 5 languages: estimate session count, file naming convention, and memory budget impact of adding French, German, Spanish, Japanese, and Mandarin VO."*

- **Procedural Dialogue** — Generating speech at runtime using text-to-speech or concatenative synthesis. No pre-recorded lines needed, but quality tradeoffs are significant.
  *"Evaluate using neural TTS for generic NPC shopkeeper lines — is the quality good enough in 2024, and what's the runtime CPU/latency cost?"*

- **Conversation Manager** — The system that orchestrates dialogue flow: tracking conversation state, managing interruptions, queueing lines, and handling player walk-aways mid-conversation.
  *"Design a conversation manager that pauses dialogue when combat starts, resumes where it left off, and can handle the player walking away and returning."*

- **Voice Line Database** — A structured catalog of all recorded lines with metadata: character, emotion, context, duration, file path, and localization status. The organizational backbone of VO production.
  *"Design a voice line database schema with fields for character ID, emotion tag, script line, audio file path, duration, approval status, and localization keys."*

- **Interrupt Behavior** — How the system handles a new voice line when one is already playing. Options: queue it, cut the current line, blend between them, or drop the new one. Different situations need different rules.
  *"Set interrupt rules: story dialogue queues behind active lines, combat barks cut ambient chatter immediately, and the player's own barks never get interrupted."*

- **Contextual Dialogue** — Lines that change based on game state, history, or environment. The NPC greets you differently if you've completed their quest, if it's raining, or if you're wearing their faction's armor.
  *"Implement contextual dialogue for the innkeeper: different greetings based on time of day, player reputation, and whether they've rented a room before."*

- **Chatter System** — Ambient NPC conversations that play in the background to make the world feel alive. Guards discussing rumors, merchants haggling, children playing. Triggered by proximity and randomized.
  *"Build a chatter system for the town square: pairs of NPCs play randomized 2-3 line conversations when the player passes within earshot, with 30-second cooldowns."*

- **Phoneme** — The smallest unit of speech sound. Each spoken word is a sequence of phonemes. Lip sync systems map audio to phonemes to drive mouth animation.
  *"Extract phoneme data from the recorded dialogue using forced alignment so the lip sync system can map each sound to the correct mouth shape."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=phoneme+chart+speech+sounds+IPA)
