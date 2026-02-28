# Sound Design for Games Learning Roadmap

**For:** Game developer who wants to create their own audio · The creative discipline, not engine code · Reads > watches · ADHD-friendly

---

## How This Roadmap Works

This roadmap is about **making sounds**, not wiring them into an engine. It covers the creative and technical craft of game audio: designing sound effects from scratch, recording and manipulating real-world sounds, composing music that responds to gameplay, and mixing everything so it sounds professional on laptop speakers and headphones alike.

You don't need musical training or an expensive studio. You need a computer, a pair of headphones, free software, and a willingness to listen carefully. Most modules have no prerequisites beyond Module 0 — check the dependency notes and jump to whatever interests you.

Each module below is a summary. Click the "Deep dive" link on any module to open the full study guide with detailed techniques, tool walkthroughs, and additional exercises.

**Dependency graph:**
```
0 → 1 (linear start)
     ↓
     2, 3 (synthesis & recording — independent parallel tracks)
     4 (music composition — after 0, better after 1)
     5 (adaptive audio — after 4)
     6 (mixing — after creating sounds in 1-3)
     7 (tools/workflow — anytime after 0)
     8 (implementation/middleware — anytime, better after 5)
```

---

## Module 0: How Sound Shapes Games

> **Deep dive:** [Full study guide](module-00-how-sound-shapes-games.md)

**Goal:** Understand why sound is half the experience; listen critically.

Close your eyes and think about the last game that truly immersed you. Chances are, sound was doing enormous invisible work. The crunch of footsteps told you what surface you were walking on. A low rumble warned you something was about to go wrong. A rising musical phrase made a simple victory screen feel triumphant. Sound is the only sense in games that doesn't require the player to look in the right direction — it's omnidirectional, instant, and emotional in a way visuals can't match.

Game audio serves three functions simultaneously: **information** (that click means your gun is empty), **emotion** (the music tells you this is sad), and **space** (the reverb tells you you're in a cave). Great sound design nails all three without the player ever consciously noticing. Bad sound design — or silence — makes even beautiful games feel flat and lifeless.

The "mute test" is your first tool: play any polished game on mute for two minutes, then unmute. The gap between those two experiences is the entire value of sound design. That gap is what this roadmap teaches you to create. If you've worked through the [Game Design Theory roadmap's Module 9 on aesthetics and juice](../../design/game-design-theory/module-09-aesthetics-feel-juice.md), you already know that audio is the single highest-impact layer of game feel. This roadmap is where you learn to build that layer yourself.

**Read:**
- "A Beginner's Guide to Game Audio" by Michael Theiler: https://www.asoundeffect.com/game-audio-guide/ — comprehensive overview of the discipline from a working professional
- "The Role of Audio in Games" from the FMOD Learning Resources: https://www.fmod.com/docs/2.03/unity/welcome.html — the introduction sections explain why middleware exists and what problems game audio solves
- "Designing Sound" by Andy Farnell (introductory chapters available as preview) — the foundational text on procedural audio thinking

**Exercise:** Pick three games you've played recently. For each, play five minutes on mute, then five minutes with sound. Write down every moment that felt different. Categorize each sound you notice into information, emotion, or space. Which game used audio most effectively? Why?

**Time:** 2-3 hours

---

## Module 1: SFX Fundamentals

> **Deep dive:** [Full study guide](module-01-sfx-fundamentals.md)

**Goal:** Understand the anatomy of a sound effect — layering, variations, and basic editing.

A single sword swing in a professional game isn't one sound. It's three or four sounds layered together: a "whoosh" for the swing, a transient "click" for weight, maybe a subtle metallic ring, all mixed to hit in under 200 milliseconds. Understanding this layering principle is the foundation of all sound effect design. You build complex, convincing sounds by combining simple elements.

Start with SFXR (https://sfxr.me), a free browser tool that generates retro-style sound effects from randomized parameters. It's not a professional tool, but it teaches you the core parameters that shape any sound: waveform, attack, sustain, decay, frequency sweeps, and modulation. Twist the knobs. Generate hundreds of sounds. Start hearing what each parameter does.

Then move into Audacity (free, cross-platform) for editing. Import sounds, trim silence, normalize volume, layer two sounds together, add a fade-out. These operations are the bread and butter of SFX work. The key concept is **variations** — you never want the same exact sound to play twice in a row. A footstep that repeats identically sounds robotic. Three slightly different footstep recordings, randomly selected, sound natural. Even pitch-shifting a single sound by +/- 5% between plays breaks the repetition.

**Key concepts:**
- **Transient:** The sharp initial attack of a sound. Punchy transients make effects feel impactful.
- **Body:** The sustained middle portion. Gives the sound character and fullness.
- **Tail:** The decay and release. Reverb tails tell the player about the space.
- **Layering:** Combining multiple simple sounds to create one complex one.
- **Variations:** Multiple versions of the same effect to avoid repetition.

**Read:**
- SFXR documentation / parameter guide: https://sfxr.me — experiment directly in the browser
- Audacity manual (Getting Started sections): https://manual.audacityteam.org/man/getting_started.html — covers all the basic editing operations
- "Practical Game Audio" section on A Sound Effect blog: https://www.asoundeffect.com/category/game-audio/ — articles from working sound designers on real-world SFX workflows

**Exercise:** Create a complete SFX set for a simple game: a jump, a landing, a coin pickup, an enemy hit, a player death, and a menu select. Use SFXR for raw generation, then import into Audacity and edit: trim, normalize, layer two sounds together for the enemy hit, and create three pitch-shifted variations of the footstep/landing sound. Export as .ogg files.

**Time:** 3-5 hours

---

## Module 2: Synthesis for Game Audio

> **Deep dive:** [Full study guide](module-02-synthesis-for-game-audio.md)

**Goal:** Create sounds from waveforms — subtractive synthesis, FM, LFOs, and envelopes.

Synthesis is the art of building sounds from nothing but math. Instead of recording a laser gun (they don't exist), you synthesize one: start with a saw wave, sweep the frequency downward, add a fast envelope so it's punchy, layer in some noise for grit. Synthesis gives you total control and infinite variation — no microphone, no sample library, no licensing concerns.

**Subtractive synthesis** is the most intuitive starting point. You begin with a harmonically rich waveform (saw, square, or noise) and sculpt it by removing frequencies with a filter. A low-pass filter that sweeps from open to closed creates the classic "wah" effect. The filter's cutoff frequency and resonance are your primary sculpting tools. This is how most classic synth sounds work — and it's how you'll build the majority of UI sounds, power-ups, and sci-fi effects.

**FM (frequency modulation) synthesis** creates more complex, metallic, bell-like, or harsh textures. One oscillator (the modulator) changes the frequency of another (the carrier) very rapidly, generating new harmonics that neither oscillator would produce alone. FM is excellent for impacts, alarms, and otherworldly textures. It's harder to predict than subtractive synthesis, but that unpredictability is a creative advantage.

**Envelopes** (ADSR: Attack, Decay, Sustain, Release) control how a parameter changes over time. A fast attack and no sustain creates a percussive hit. A slow attack and long release creates a pad. Envelopes can control volume, filter cutoff, pitch — anything. **LFOs** (Low Frequency Oscillators) do the same thing but cyclically — a sine wave LFO on pitch creates vibrato; on volume, tremolo; on a filter, a rhythmic wah.

**Read:**
- Synth Secrets by Sound On Sound — the definitive free series on synthesis fundamentals: https://www.soundonsound.com/series/synth-secrets-sound-sound (start with parts 1-5 for core concepts; the full series is 63 parts and covers everything)
- Learning Synths by Ableton — interactive browser-based synthesis tutorial: https://learningsynths.ableton.com (hands-on, no install required, excellent for building intuition)
- Vital synth documentation: https://vital.audio — Vital is a free, professional-quality wavetable synth. Download it as your primary synthesis tool.

**Exercise:** Using Vital (free) or any synth plugin, create four game sounds purely from synthesis — no samples: (1) a laser shot using a downward frequency sweep, (2) a UI confirm sound using FM synthesis with a quick envelope, (3) a powerup using a rising arpeggio with filter modulation, (4) an ambient drone using detuned oscillators with a slow LFO on the filter. Export each as a .wav file.

**Time:** 4-6 hours

---

## Module 3: Recording & Foley

> **Deep dive:** [Full study guide](module-03-recording-foley.md)

**Goal:** Capture and transform real-world sounds into game audio.

Foley is the art of creating sound effects by recording physical actions — crunching celery for bone breaks, crumpling leather for creature movements, slapping a watermelon for impacts. It's older than video games (it was invented for film), and it remains one of the most effective ways to create sounds that feel organic and physical in a way synthesis can't replicate.

You don't need expensive gear to start. A smartphone's built-in microphone can capture surprisingly usable recordings if you're in a quiet room and get close to the source. A $30-60 USB lavalier or desktop microphone is a significant upgrade. The key is **recording environment** — background noise (HVAC, traffic, refrigerator hum) is the enemy. Record in the quietest space you can find, at the quietest time of day. A closet full of clothes is a surprisingly good recording booth because the fabric absorbs reflections.

The real magic happens in post-processing. A raw recording of crumpling paper sounds like crumpling paper. But pitch it down two octaves, layer it with a low rumble, add some compression and EQ, and it becomes the footsteps of a stone golem. Sound design is transformation. The source material is just a starting point. Professional foley artists think in terms of **texture and transient** — they're not trying to record a "thing," they're trying to capture a specific quality (crunch, scrape, whoosh, thud) that can be shaped into something else entirely.

**Read:**
- Freesound: https://freesound.org — massive Creative Commons sound library. Study how sounds are tagged and described; download raw material to practice editing and layering.
- "A Guide to Foley & Sound Design for Games" on A Sound Effect: https://www.asoundeffect.com/game-audio-foley/ — practical advice from professionals on recording techniques
- Sonniss GDC Game Audio Bundles: https://sonniss.com/gameaudiogdc — free, royalty-free, high-quality sample packs released each year (tens of gigabytes of professional recordings)

**Exercise:** Record 10 sounds using only items in your kitchen: knife on cutting board, tap water running, crumpling tin foil, shaking a jar of rice, ice cubes in a glass, etc. Import all into Audacity. For each, create a "transformed" version that sounds nothing like the original — pitch shift, reverse, layer, add effects. Goal: turn kitchen sounds into five usable game SFX (footsteps, a magic spell, a menu transition, an explosion, and an ambient background).

**Time:** 3-5 hours

---

## Module 4: Music Composition for Games

> **Deep dive:** [Full study guide](module-04-music-composition-for-games.md)

**Goal:** Compose loops, understand melody, harmony, rhythm, and emotional palettes using free tools.

Game music operates under a constraint that film and concert music don't: it must **loop**. A player might hear your 30-second combat theme 200 times in a session. If the loop point is jarring, or the melody is too distinctive, it becomes maddening. Great game music is interesting enough to enhance the experience but unobtrusive enough to survive repetition. This is a genuinely difficult balance, and it's a skill separate from "being a good musician."

You don't need to be a trained musician to compose for games. You need to understand a handful of foundational concepts. **Melody** is a sequence of notes that forms a recognizable phrase — it's what you hum after the game is off. **Harmony** is the chords underneath that give the melody its emotional color. A major chord feels bright and resolved; a minor chord feels dark and tense; a suspended chord feels unresolved and mysterious. **Rhythm** is when notes happen in time — a driving quarter-note pulse feels urgent; a sparse, irregular rhythm feels contemplative.

**Emotional palettes** are how you match music to game states. Action sequences need high energy: fast tempo, driving rhythm, strong percussion. Exploration might need curiosity: major-key melody, moderate tempo, space between notes. Horror needs tension: dissonance, unpredictable rhythm, low drones, silence. You're not composing a song — you're composing a *mood* that supports gameplay.

Start with free DAWs: LMMS (https://lmms.io) is fully free and cross-platform, or Bandlab's online DAW (https://www.bandlab.com) requires nothing but a browser. For music theory fundamentals, musictheory.net (https://www.musictheory.net) is the gold standard free resource — work through the "Lessons" section on intervals, scales, and chords.

**Read:**
- musictheory.net Lessons (intervals through chords): https://www.musictheory.net/lessons — interactive, free, and explains concepts with playable examples
- "A Composer's Guide to Game Music" by Winifred Phillips — the standard reference text on the discipline (book; check library availability)
- "Writing Video Game Music" on Hooktheory: https://www.hooktheory.com/blog — analysis of chord progressions and melody writing with interactive tools

**Exercise:** Compose three 16-bar loops in any free DAW: (1) a peaceful village theme in C major, 90 BPM, using mostly piano or acoustic guitar sounds; (2) a tense dungeon theme in A minor, 70 BPM, emphasizing low strings and sparse percussion; (3) a boss battle theme in D minor, 140 BPM, with heavy drums and staccato brass. Each must loop seamlessly — the last bar should connect smoothly back to the first. Export as .ogg files.

**Time:** 5-8 hours

---

## Module 5: Adaptive & Interactive Audio

> **Deep dive:** [Full study guide](module-05-adaptive-interactive-audio.md)

**Goal:** Design audio that responds to gameplay — horizontal re-sequencing, vertical layering, stems, and stingers.

Static audio plays the same regardless of what the player does. **Adaptive audio** changes based on game state — the music intensifies when enemies appear, shifts key when you enter a new area, strips down to ambient pads when you're exploring peacefully. This is what separates game audio from simply putting a soundtrack over gameplay.

**Vertical layering** (also called vertical remixing) is the most common technique. You compose a piece of music as separate stems — drums, bass, melody, pads, strings — that all play simultaneously but can be individually muted or faded. In a calm state, only pads and a light melody play. When combat starts, drums and bass fade in. When a boss appears, everything plays at full intensity. The player experiences a seamless musical transition because all the stems were composed together and stay in sync.

**Horizontal re-sequencing** controls which musical section plays next. Instead of one continuous loop, you compose short segments (typically 2-8 bars each) that can transition between each other at musically valid points. The game's audio system chooses the next segment based on gameplay — exploration leads to segment A, approaching danger leads to segment B, combat leads to segment C. Each transition happens on a bar boundary so the music never sounds broken.

**Stingers** are short one-shot musical phrases triggered by specific events: a fanfare when you level up, a dark chord when a character dies, a triumphant phrase when you defeat a boss. They're layered on top of the current music and must be composed in a compatible key and tempo.

**Read:**
- "A Composer's Guide to Game Music" by Winifred Phillips (chapters on adaptive scoring) — the most detailed text treatment of interactive music techniques
- FMOD documentation on adaptive music: https://www.fmod.com/docs/2.03/studio/music.html — even if you don't use FMOD, the documentation explains the concepts clearly with diagrams
- "Horizontal and Vertical Techniques in Game Music" by Game Developer: https://www.gamedeveloper.com — search for adaptive audio articles; several excellent breakdowns exist

**Exercise:** Take one of your loops from Module 4 and split it into four stems (drums, bass, harmony, melody). In your DAW, practice manually muting and unmuting stems to simulate a transition from exploration (melody + pads only) to combat (all stems). Then compose a 2-bar stinger in the same key and tempo. Document the "rules" for when each stem should play based on a simple game scenario (exploring → enemy spotted → combat → victory).

**Time:** 4-6 hours

---

## Module 6: Mixing, Mastering & Technical Audio

> **Deep dive:** [Full study guide](module-06-mixing-mastering-technical-audio.md)

**Goal:** EQ, compression, reverb, loudness standards, and file format choices.

You've created sounds. Now they need to coexist. **Mixing** is the process of making all your audio elements — SFX, music, ambience, dialogue — play together without clashing, masking each other, or blowing out the player's speakers. This is where sound design becomes technical craft.

**EQ (equalization)** is frequency sculpting. Every sound occupies a frequency range. A bass drum lives in the low end (60-100 Hz). A sword clang lives in the upper mids (2-5 kHz). A hi-hat lives in the highs (8-16 kHz). When two sounds occupy the same frequency range, they mask each other and neither sounds clear. The fix: use EQ to carve space. Cut the low frequencies from your sword clang so it doesn't compete with the bass drum. Boost the presence range (3-5 kHz) on dialogue so it cuts through music. The goal isn't to make each sound "good" in isolation — it's to make the mix clear when everything plays simultaneously.

**Compression** reduces the dynamic range — it makes quiet parts louder and loud parts quieter. Game audio needs compression because players are in unpredictable environments (laptop speakers, headphones, living room TV). A gunshot that's vastly louder than dialogue will make players constantly adjust volume. Light compression on your master bus keeps everything in a playable range. Heavy compression on individual SFX makes them punchy and consistent.

**Reverb** creates a sense of space. A dry (no reverb) sound feels close and intimate. A wet (heavy reverb) sound feels distant and cavernous. In-game, you might apply different reverb amounts based on environment — dry in a tight corridor, wet in a cathedral. Reverb is also a mixing tool: pushing background elements "further back" with reverb creates depth without changing volume.

**Loudness and file formats:** Export SFX as .ogg (Vorbis) or .wav. Music as .ogg for streaming. Target -16 to -14 LUFS for overall loudness. Leave headroom — clipping (distortion from audio exceeding 0 dB) is the most common amateur mistake. Always listen on at least two different output devices (headphones and speakers) before finalizing.

**Read:**
- Audacity effects documentation: https://manual.audacityteam.org/man/effect_menu.html — covers EQ, compression, reverb, and normalization with examples
- "Mixing Secrets for the Small Studio" by Mike Senior — not game-specific, but the clearest book on mixing fundamentals for people without professional studios (check library)
- "Loudness Standards for Game Audio" — FMOD technical documentation covers loudness metering: https://www.fmod.com/docs/2.03/studio/mixing.html

**Exercise:** Take all the SFX from Modules 1-3 and the music from Module 4. Create a mock "game mix" in Audacity or your DAW: layer music, two ambient sounds, and three SFX triggers. Use EQ to prevent masking. Apply light compression. Add reverb to the ambient sounds but keep SFX dry. Export the final mix and listen on headphones, then on phone speakers. Write down what sounds different and what you'd adjust.

**Time:** 4-6 hours

---

## Module 7: Audio Tools, Workflow & Asset Management

> **Deep dive:** [Full study guide](module-07-audio-tools-workflow.md)

**Goal:** Set up your DAW, plugins, sample libraries, and folder structure for efficient production.

The creative side of sound design suffers when your tools are disorganized. You don't need expensive software — the free tool ecosystem for game audio is excellent — but you do need a workflow that lets you go from idea to exported asset quickly. This module is about building that pipeline.

**Your core toolkit (all free):**
- **DAW:** Audacity for editing and processing, LMMS or Bandlab for composition. If you're willing to invest, Reaper (https://www.reaper.fm) has an unlimited free evaluation and is the industry standard for indie game audio work.
- **Synth:** Vital (https://vital.audio) — free, professional-quality wavetable synth with a visual interface.
- **SFX generator:** SFXR (https://sfxr.me) for quick retro sounds; ChipTone (https://sfbgames.itch.io/chiptone) for more control.
- **Sample libraries:** Freesound (https://freesound.org), Sonniss GDC packs (https://sonniss.com/gameaudiogdc), Kenney audio assets (https://kenney.nl).
- **Plugins:** The built-in effects in Audacity and your DAW cover EQ, compression, reverb, and delay. TAL-Reverb and OrilRiver are excellent free reverb VSTs.

**Folder structure matters.** A professional game audio folder looks something like: `audio/sfx/player/`, `audio/sfx/enemies/`, `audio/sfx/ui/`, `audio/music/exploration/`, `audio/music/combat/`, `audio/ambience/`. Name files descriptively and consistently: `player_jump_01.ogg`, `player_jump_02.ogg`, `player_jump_03.ogg`. Include variation numbers. Never name a file `final_v2_REAL_final.wav`.

**Non-destructive workflow:** Always keep your original source files (raw recordings, synth patches, DAW project files) separate from your exported game-ready assets. Edit non-destructively in your DAW — use effect chains rather than baking effects into the source file. This lets you re-export at different quality levels or re-mix later without starting over.

**Read:**
- Reaper user guide (Getting Started section): https://www.reaper.fm/userguide.php — even if you use another DAW, the organizational principles apply
- "Organizing Game Audio Assets" — FMOD best practices: https://www.fmod.com/docs/2.03/studio/organizing-your-project.html
- Vital synth manual and preset design: https://vital.audio — browse the preset library to learn how complex sounds are constructed

**Exercise:** Set up your complete audio production environment. Install a DAW (or set up Bandlab in your browser), install Vital, bookmark Freesound and SFXR. Create a project folder structure for a hypothetical game with the categories above. Download one sample pack from Sonniss or Freesound, organize it into your folder structure, and create three new SFX by combining and processing samples from the pack. Time yourself from "I need a sound" to "exported .ogg file" — aim for under 15 minutes per effect.

**Time:** 2-4 hours

---

## Module 8: Implementation Patterns

> **Deep dive:** [Full study guide](module-08-implementation-patterns.md)

**Goal:** Understand FMOD, Wwise, and when you need middleware versus built-in engine audio.

You've designed the sounds. Now they need to play in a game engine at the right time, with the right parameters, responding to gameplay. This is where sound design meets implementation, and where you decide whether your engine's built-in audio system is enough or you need middleware.

**Built-in engine audio** (Godot's AudioStreamPlayer, Love2D's love.audio, Unity's AudioSource) handles the basics: play a sound, set volume, maybe adjust pitch. For simple games with static SFX and looping music, this is sufficient and adding middleware is unnecessary complexity. If you've worked through the [Godot roadmap's audio and game feel module](../../engines/godot/module-09-audio-game-feel.md) or the [Love2D roadmap](../../engines/love2d/love2d-learning-roadmap.md), you've already used built-in engine audio effectively.

**FMOD** (https://www.fmod.com) and **Wwise** (https://www.audiokinetic.com/en/wwise/overview/) are the two dominant audio middleware tools. They sit between your sound assets and the game engine, providing a visual environment for designing complex audio behaviors: parameter-driven music systems, randomized SFX containers, real-time mixing based on game state, spatial audio with occlusion and diffraction. The sound designer works in the middleware tool; the programmer calls events from engine code.

**When to use middleware:**
- Your game has adaptive music with multiple stems and transitions
- You need complex SFX randomization (random pitch, volume, and sample selection per play)
- You want real-time mixing that responds to game parameters (health, distance, intensity)
- Your audio designer and programmer are different people (middleware lets them work independently)

**When built-in audio is enough:**
- Your game has fewer than ~50 unique sound events
- Music is simple loops without adaptive behavior
- You're a solo developer and the middleware learning curve isn't worth the benefit

FMOD is free for indie projects under $200k revenue. Wwise is free for projects under 200 sound assets. Both have excellent documentation and integrate with all major engines.

**Read:**
- FMOD Studio documentation (start with "Getting Started"): https://www.fmod.com/docs/2.03/studio/ — clear, well-structured, with screenshots
- Wwise 101 Certification course (free): https://www.audiokinetic.com/en/learning/certifications/ — a full structured course on Wwise fundamentals
- "Choosing Between FMOD and Wwise" on A Sound Effect: https://www.asoundeffect.com — search for middleware comparison articles; several balanced analyses exist from working professionals

**Exercise:** Download FMOD Studio (free). Create a simple project with: (1) an SFX event that randomly selects from three sound variations with random pitch, (2) a music event with two layers (drums and melody) controlled by a game parameter called "intensity," and (3) a stinger that plays on top of the music. Preview everything inside FMOD Studio — you don't need to integrate with an engine for this exercise. Document what FMOD gives you that a simple `play_sound()` call in your engine doesn't.

**Time:** 4-6 hours

---

## Essential Bookmarks

| Resource | URL | Notes |
|----------|-----|-------|
| Freesound | https://freesound.org | Massive CC-licensed sound library; raw material for everything |
| SFXR | https://sfxr.me | Browser-based retro SFX generator; great for prototyping |
| Sonniss GDC Packs | https://sonniss.com/gameaudiogdc | Free professional sample packs, released annually |
| Vital Synth | https://vital.audio | Free wavetable synth; your primary synthesis tool |
| Learning Synths (Ableton) | https://learningsynths.ableton.com | Interactive synthesis tutorial in the browser |
| Synth Secrets (Sound On Sound) | https://www.soundonsound.com/series/synth-secrets-sound-sound | The definitive text series on synthesis (63 parts) |
| musictheory.net | https://www.musictheory.net | Free interactive music theory lessons |
| FMOD Documentation | https://www.fmod.com/docs | Middleware docs; also teaches adaptive audio concepts |
| Wwise 101 Certification | https://www.audiokinetic.com/en/learning/certifications/ | Free structured middleware course |
| Audacity Manual | https://manual.audacityteam.org | Reference for your primary editing tool |
| A Sound Effect Blog | https://www.asoundeffect.com | Articles from working game audio professionals |
| Reaper | https://www.reaper.fm | Industry-standard DAW with unlimited free evaluation |
| LMMS | https://lmms.io | Fully free, cross-platform DAW for composition |
| Kenney Audio Assets | https://kenney.nl | Free, high-quality game audio packs |

---

## ADHD-Friendly Tips

- **Sound design is playing.** Twisting knobs on a synth, smashing things in your kitchen and recording it, generating random sounds in SFXR — this is productive work. It doesn't feel like studying because it's genuinely fun. Lean into that.
- **One module per session.** Don't try to learn synthesis AND composition AND mixing in one sitting. Pick one thing, do the exercise, export something, stop.
- **Export something every session.** Even if it's rough, bouncing a .ogg file to your project folder makes the session feel complete. You built a tangible thing.
- **The 5-minute noodle rule.** If you can't bring yourself to start a full exercise, open your synth or SFXR and just make sounds for 5 minutes with no goal. You'll either get bored and stop (fine) or get hooked and keep going (great).
- **Listen actively during games.** Next time you play anything, close your eyes for 30 seconds and just listen. Count the layers. Notice the reverb. Hear the variation in footsteps. This trains your ear faster than any textbook.
- **Rotate between creation and analysis.** Module 2 burning you out? Switch to Module 7 and organize your toolkit. Tired of technical mixing in Module 6? Go record weird sounds for Module 3. The roadmap is non-linear on purpose.
- **Steal from your sample library.** There's no shame in starting with existing sounds and transforming them. Every professional sound designer uses sample libraries as raw material. Original creation and sample manipulation are both real skills.
