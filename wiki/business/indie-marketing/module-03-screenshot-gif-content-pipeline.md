# Module 3: Screenshot & GIF Content Pipeline

> *"Consistency beats virality. The developer who posts one good GIF a week for a year will build a bigger audience than the one who posts once and gets lucky."*

**Part of:** [Indie Game Marketing Roadmap](indie-marketing-learning-roadmap.md)
**Estimated study time:** 3–5 hours
**Prerequisites:** [Module 2: Your Steam Page Is Your Landing Page](module-02-steam-page-is-your-landing-page.md)

---

## Overview

You have a Steam page. You know who your player is. Now you need content — the raw material that drives people to your page, keeps your community engaged, and builds the slow, compounding visibility that leads to a successful launch. The most effective content for indie game marketing is visual: screenshots and GIFs (or short video clips that function like GIFs). They're fast to consume, shareable, platform-native on every social media site, and they show your game doing the one thing that no description can fully capture — *being a game*.

The problem isn't knowing you should post content. The problem is doing it consistently without burning out. Most indie developers post a flurry of screenshots when they feel inspired, go silent for three weeks, post another flurry, go silent for two months, and then wonder why they don't have an audience. The solution isn't more inspiration — it's a pipeline. A repeatable system that turns your daily development work into a steady stream of marketing content with minimal additional effort.

This module gives you that pipeline. By the end, you'll have a capture setup that runs in the background, an editing workflow that takes minutes instead of hours, a content calendar that removes decision fatigue, and platform-specific formatting knowledge that ensures your content performs on every channel.

---

## Learning Outcomes

By the end of this module, you will be able to:

- Set up a zero-friction capture pipeline for screenshots and screen recordings
- Convert screen recordings into optimized GIFs and short video clips
- Compose screenshots that communicate gameplay clearly and attractively
- Create and maintain a weekly content calendar
- Format content correctly for Twitter/X, Reddit, Discord, TikTok, and Steam
- Build a content library that compounds over months
- Maintain a sustainable posting cadence without burning out

---

## Core Concepts

### 1. The Capture Habit

**The single most important thing you can do for your content pipeline is capture everything, automatically, always.** Every playtest session, every new feature you implement, every cool moment that happens on screen — capture it. You're not trying to create polished marketing content in the moment. You're building a library of raw material that you can mine later.

**Your capture toolbox:**

| Tool | Platform | What It Does | Cost |
|------|----------|-------------|------|
| OBS Studio | Windows, Mac, Linux | Records screen continuously, replay buffer captures last X seconds | Free |
| ShareX | Windows | Screenshot + GIF capture with instant editing | Free |
| ScreenToGif | Windows | Record a region of screen directly to GIF | Free |
| Gifski | Mac | Convert video files to high-quality GIFs | Free |
| Built-in screen recording | Mac (Cmd+Shift+5) | Quick screen recordings and screenshots | Free |
| GeForce Experience | Windows (NVIDIA) | Instant replay — saves the last 30-60 seconds retroactively | Free |
| ffmpeg | All platforms | Command-line video/GIF conversion (powerful but technical) | Free |

**The replay buffer is your best friend.** OBS Studio and GeForce Experience both support "replay buffer" or "instant replay" — they continuously record the last 30-120 seconds of your screen, and when you press a hotkey, they save that buffer to disk. This means you never have to think about "I should start recording now." You're always recording. When something cool happens, you press one key and the last minute is saved. This eliminates the number one enemy of content capture: "I wish I had been recording when that happened."

**Setting up OBS for zero-friction capture:**

1. Install OBS Studio
2. Go to Settings → Output → Replay Buffer
3. Enable the replay buffer, set duration to 60-120 seconds
4. Set a hotkey for "Save Replay Buffer" (something easy to reach — I use F9)
5. Set recording quality to 1080p, 60fps (or match your game's resolution)
6. Start the replay buffer when you sit down to develop
7. Press the hotkey whenever something interesting happens on screen

**The capture mindset shift:** Stop thinking "I need to set aside time to create marketing content" and start thinking "I need to press a button when something cool happens." The content creation happens during development, not in addition to it. You're already generating interesting moments by building your game. The pipeline just captures them.

**Real-world example:** The developer of **Baba Is You** (Arvi Teikari) frequently shared GIFs of interesting puzzle solutions on Twitter during development. These weren't staged — they were natural moments from playtesting that he captured and shared. The simplicity and cleverness of the puzzles made each GIF inherently shareable, and the consistent posting built a dedicated following months before launch.

**Common mistake:** Capturing only when you think something is "good enough" for marketing. Capture everything. You can sort through it later. Your standards for "good enough" during a development session are different (and usually higher) than what actually performs well on social media. That janky animation you thought was embarrassing? It might be endearing and get more engagement than your polished showcase.

**Try this now:** Install OBS Studio (if you don't have it) and set up the replay buffer. Set a hotkey. Start your game and playtest for 10 minutes. Press the hotkey at least 5 times — every time something remotely interesting happens. At the end, review what you captured. You now have raw material for this week's content.

---

### 2. GIFs Are the Lingua Franca of Game Marketing

**A well-crafted GIF will outperform a screenshot on almost every platform.** Twitter, Reddit, Discord, Mastodon, Bluesky — they all autoplay GIFs and short videos in the feed. A static screenshot requires the viewer to imagine your game in motion. A GIF shows it. That difference in cognitive load translates directly to engagement.

**The anatomy of an effective game marketing GIF:**

| Element | Guideline |
|---------|-----------|
| **Length** | 3-8 seconds. Shorter is almost always better. The GIF should show one moment, one mechanic, one "oh, that's cool" reaction. |
| **Content** | One thing. Not "here's my game." One mechanic, one combo, one visual effect, one enemy encounter, one puzzle solution. |
| **Loop** | If possible, make the GIF loop smoothly. A GIF that loops back to its starting state gets watched multiple times, which increases engagement. |
| **Resolution** | 720p minimum for clarity on modern screens. 1080p if file size permits. |
| **File size** | Under 15MB for Twitter and Discord compatibility. Under 8MB for some platforms. If too large, reduce resolution, length, or framerate. |
| **Framerate** | 30fps is standard. 60fps is smoother but doubles file size. For most game marketing GIFs, 30fps is fine. |

**Converting recordings to GIFs:**

**Method 1: ScreenToGif (Windows, easiest)**
1. Open ScreenToGif
2. Use the "Recorder" to capture a region of your screen
3. In the editor, trim to the best 3-8 seconds
4. Export as GIF with quality settings optimized for size

**Method 2: Gifski (Mac, high quality)**
1. Record gameplay using the built-in screen recording
2. Open the recording in Gifski
3. Trim to the best segment
4. Export with quality slider adjusted for file size

**Method 3: ffmpeg (all platforms, most control)**
```
ffmpeg -ss 00:00:05 -t 6 -i recording.mp4 -vf "fps=30,scale=720:-1" -loop 0 output.gif
```
This takes 6 seconds starting at the 5-second mark, downscales to 720p width, and creates a looping GIF. Adjust the parameters to taste.

**Method 4: Upload as video instead.** Most platforms now prefer short video (MP4) over actual GIFs because videos compress better and look sharper. Twitter, Reddit, and Discord all support short video uploads that autoplay like GIFs. If file size is a struggle, upload a 5-second MP4 instead of a GIF. Same visual effect, smaller file, better quality.

**Real-world example:** **Vampire Survivors** spread primarily through GIFs and short clips. The game's visual spectacle — hundreds of enemies swarming the screen, massive area-of-effect attacks — was inherently GIF-able. Each clip was a self-contained argument for why the game was fun. The developer didn't need to explain the appeal. The GIFs did it.

**Real-world example:** **Noita** (by Nolla Games) generated massive pre-launch interest through GIFs of its physics simulation. A GIF of fire spreading through wood, or acid eating through rock, or a chain reaction destroying a cave was endlessly fascinating. Each GIF showed one emergent physics interaction and let viewers imagine the possibilities.

**Common mistake:** Making GIFs too long. A 20-second GIF loses most viewers before it finishes. If your GIF requires 20 seconds to be interesting, you're trying to show too much. Split it into three 6-second GIFs and post them separately over three days. More content, better engagement, same raw footage.

**Try this now:** Take one of the replay buffer clips you captured in Concept 1. Trim it to the best 3-8 seconds using any of the tools above. Export it as a GIF. If the file is over 15MB, reduce the resolution or framerate until it's under. Congratulations — you have your first marketing GIF.

---

### 3. Screenshot Composition

**A marketing screenshot is not a debug screenshot.** It's a carefully composed image designed to communicate your game's appeal in a single frame. The difference between a mediocre screenshot and a great one is composition — the deliberate arrangement of visual elements to guide the viewer's eye and tell a story.

**The Screenshot Composition Framework:**

**Rule of thirds.** Divide your screen into a 3×3 grid. Place the most important visual element (your character, the focal point of the action, the key object) at one of the four intersections. This creates naturally appealing compositions. Most game cameras don't center the player character, which helps — the character is already off-center, near an intersection.

**Show scale.** If your game has impressive scope (a massive city, a huge dungeon, a vast landscape), compose your screenshot to emphasize scale. Include a small player character dwarfed by the environment. The contrast between small character and large world communicates ambition and adventure.

**Capture mid-action.** A character standing still in an empty room is boring. A character mid-jump, mid-attack, mid-explosion is dynamic. Time your screenshots to capture the moment of maximum visual energy. In action games, this means combat impacts. In puzzle games, this means the moment of solution. In simulation games, this means peak complexity.

**Include meaningful UI.** There's an instinct to hide the HUD for "clean" screenshots. Resist it — especially for games with deep systems. A roguelike screenshot that shows health, items, abilities, and map all in view communicates mechanical depth. A city builder screenshot with population, resources, and happiness visible communicates simulation complexity. The UI is part of the game's visual identity.

**Compose for thumbnail.** Your screenshots will often be viewed at small sizes — in Steam search results, embedded in social media posts, displayed in press articles. What reads clearly at full size might be indecipherable at thumbnail. Simplify compositions. Reduce visual clutter. Make the focal point obvious even when small.

**Screenshot enhancement techniques:**

| Technique | When to Use | How |
|-----------|-------------|-----|
| Text overlays | To highlight a specific feature | Add a short caption: "Over 200 unique weapons" |
| Subtle zoom/crop | To focus on an interesting detail | Crop the screenshot to the most compelling 16:9 region |
| UI toggle | To choose between "systemic depth" and "visual beauty" | Capture both versions, use each where appropriate |
| Camera mode | If your game supports it, to find the best angle | Implement a basic screenshot camera for marketing purposes |
| Color grading | To punch up visual appeal | Slight contrast and saturation boost (don't overdo it — accuracy matters) |

**Real-world example:** **Dead Cells** screenshots consistently show mid-combat moments with particles, enemies, and the player's character in dynamic poses. Every screenshot has movement and energy. They never show the character standing still in an empty room. The UI is always visible, communicating the game's gear, health, and ability systems.

**Real-world example:** **Subnautica** uses scale beautifully in its screenshots. Many shots place the player's tiny submarine next to massive underwater creatures or structures. The contrast communicates the game's sense of exploration and wonder better than any description could.

**Common mistake:** Using automatically captured screenshots (like Steam's F12 default) without curation. Auto-captured screenshots are random moments, not composed images. Set up intentional capture sessions where you actively seek good compositions.

**Try this now:** Launch your game and capture 10 deliberately composed screenshots using the principles above. For each one, apply at least one composition technique (rule of thirds, show scale, mid-action, meaningful UI). Pick the best 3 and compare them to your current Steam page screenshots. Are the new ones better?

---

### 4. The Content Calendar

**A content calendar removes the daily decision of "what should I post today?"** Decision fatigue is one of the biggest killers of consistent content creation, especially for solo developers with ADHD. A calendar pre-decides what goes where and when, turning marketing from a creative decision into a checkbox task.

**The Minimum Viable Content Calendar:**

| Day | Platform | Content Type | Example |
|-----|----------|-------------|---------|
| Monday | Twitter/social media | Screenshot or GIF with short caption | "Just got the lighting system working in the crystal caves 🔮" |
| Thursday | Reddit or devlog | Longer-form post with context | "Devlog #12: How I built the procedural cave generator" or Reddit post with GIF + 2-3 paragraphs of context |

That's it. Two posts per week. One is quick and visual (5-10 minutes to prepare). One requires more thought and writing (30-60 minutes to prepare). This is a sustainable minimum that maintains visibility without eating into development time.

**Scaling up when ready:**

| Cadence | Weekly Posts | Time Investment | Audience Growth |
|---------|-------------|-----------------|-----------------|
| Minimum | 2 posts/week | 1-2 hours/week | Slow but steady |
| Moderate | 4-5 posts/week | 3-4 hours/week | Noticeable growth |
| Aggressive | Daily posts + longer-form weekly | 5-8 hours/week | Fast growth, risk of burnout |

Start at minimum. Stay there for at least a month. Scale up only if you have the energy and the results justify the time.

**Content batching:**

The most efficient approach is to batch your content creation into a single weekly session. Instead of creating content from scratch five times a week, spend one focused session (60-90 minutes) doing all of the following:

1. Review your replay buffer captures and screenshots from the past week
2. Select the best 3-5 pieces of raw material
3. Edit them (trim GIFs, compose screenshots, crop and enhance)
4. Write captions and descriptions for each piece
5. Schedule them across the week using a scheduling tool (Buffer, TweetDeck, native platform schedulers)

Batching works because it keeps you in "marketing mode" for one session instead of forcing context-switches between development and marketing multiple times per week. For ADHD brains, context-switching is the enemy. Batching is the antidote.

**Content categories to rotate:**

To avoid monotony (for both you and your audience), rotate through different content types:

- **Mechanic showcases:** GIFs showing a specific mechanic in action
- **Before/after:** Compare an old version of a feature with the current version
- **Environmental beauty shots:** Showcase your game's visual appeal
- **Behind the scenes:** Show your development environment, your notes, your workflow
- **Player reactions:** If you have playtesters, screen-record their reactions (with permission)
- **Numbers and milestones:** "Hit 1,000 wishlists!" or "Added the 100th item!"
- **Polls and questions:** "Which color palette do you prefer for the desert biome?"
- **Development challenges:** "Spent two days debugging this pathfinding issue — here's what it looked like broken vs. fixed"

**Real-world example:** **Eastward** (by Pixpil) maintained a consistent social media presence for years before launch, posting a mix of pixel art showcases, development progress GIFs, and environmental beauty shots. Their content calendar was clearly intentional — different types of content appeared at regular intervals, creating a varied and engaging feed that built a dedicated following.

**Common mistake:** Starting too ambitious and burning out. "I'll post every day on four platforms" lasts about two weeks. Start with two posts per week on one platform. Build the habit first. Expand later.

**Try this now:** Open a spreadsheet or calendar app. Plan your next two weeks of content. For each post, note: the date, the platform, the content type (screenshot, GIF, devlog), and a one-line description of the content. Don't create the content yet — just plan it. The plan makes execution dramatically easier.

---

### 5. Platform-Specific Formatting

**Each platform has its own technical requirements, cultural norms, and engagement patterns.** Content that crushes it on Twitter might flop on Reddit, and vice versa. Understanding these differences doesn't mean creating unique content for each platform — it means adapting the same core content to fit each platform's expectations.

**Twitter/X:**

| Aspect | Guideline |
|--------|-----------|
| **Best content** | Short video clips (under 30 seconds) and GIFs with punchy captions |
| **Caption length** | 1-2 sentences max. The visual should do the heavy lifting. |
| **Hashtags** | Use 2-3 relevant ones: #indiegame, #gamedev, #screenshotsaturday |
| **Timing** | 9-11 AM EST for US audience; test and adjust |
| **Video specs** | Under 2:20 for optimal engagement; MP4 preferred over GIF for quality |
| **What works** | "I just got X working" posts with a GIF showing it. Authenticity and developer voice. |
| **What doesn't** | "Please wishlist my game" posts. Desperate, transactional, ignored by the algorithm. |

**Reddit:**

| Aspect | Guideline |
|--------|-----------|
| **Best content** | GIFs with substantial context in the title and comments |
| **Title** | Write it like a pitch. "I've been working on a grappling hook mechanic for my platformer and I finally nailed the feel" > "My game progress" |
| **Self-promotion rules** | Read each subreddit's rules CAREFULLY. Most require a ratio of participation to promotion. |
| **Key subreddits** | r/indiegaming, r/indiegames, r/IndieDev, r/gamedev, plus genre-specific subs |
| **What works** | Development stories, interesting technical challenges, unique mechanics, polish showcases |
| **What doesn't** | "Check out my game" posts with no context. Reddit punishes lazy self-promotion. |
| **Video vs. GIF** | Reddit autoplays both. Upload directly to Reddit — don't link to YouTube or external sites. |

**Discord:**

| Aspect | Guideline |
|--------|-----------|
| **Best content** | Behind-the-scenes development updates, work-in-progress showcases |
| **Format** | GIF or screenshot with 2-3 sentences of context |
| **Where to post** | Your own server's update channel, plus screenshot/showcase channels in gamedev Discords |
| **What works** | Regular, informal updates that make members feel like insiders |
| **What doesn't** | Only posting when you want something (wishlists, feedback, sales) |

**Steam Community:**

| Aspect | Guideline |
|--------|-----------|
| **Best content** | Longer devlog-style posts with multiple images/GIFs |
| **Format** | Use Steam's formatting tools — headers, images, GIFs embedded inline |
| **Frequency** | 1-2 per month for Coming Soon games; more frequent around launches/updates |
| **What works** | Substantial development updates that make followers excited about progress |
| **What doesn't** | Micro-updates that feel like padding |

**TikTok / YouTube Shorts / Instagram Reels (short-form vertical video):**

| Aspect | Guideline |
|--------|-----------|
| **Best content** | 15-60 second clips with text overlays and trending audio |
| **Format** | 9:16 vertical aspect ratio (1080×1920) |
| **Style** | Fast-paced, text-heavy, personality-driven |
| **What works** | "Making a game in [genre] — Day 47" series, satisfying gameplay moments, development before/after comparisons |
| **What doesn't** | Horizontal gameplay with no adaptation for vertical format |
| **Note** | Highest growth potential for visual games, but requires most effort to produce |

**The platform priority decision:** You cannot be on every platform. Pick two — one for quick visual content (Twitter or TikTok) and one for longer-form engagement (Reddit or Steam community). Master those two before expanding.

**Real-world example:** **Coffee Stain Studios** (Satisfactory) uses different content strategies for different platforms. Twitter gets short, punchy GIFs of factory builds. Reddit gets detailed development updates with technical context. YouTube gets longer dev update videos. The core content (factory building progress) is the same. The presentation is platform-specific.

**Common mistake:** Cross-posting identical content to every platform with zero adaptation. "Posted my new screenshot on Twitter, Reddit, Discord, TikTok, and Instagram with the exact same caption." This usually works on one platform and floats on the others. Spend 5 extra minutes adapting for each platform.

**Try this now:** Pick the two platforms you'll focus on. For each one, note the optimal format, caption style, and posting rules from the table above. Now take the GIF you created in Concept 2 and write two different captions — one optimized for each platform. Notice how naturally they differ.

---

### 6. Building and Managing Your Content Library

**Every piece of content you create is an asset that lives forever.** Six months of weekly content means 50+ screenshots and GIFs that are discoverable through search, shareable by your community, and available for press kits, Steam page updates, and outreach emails. But only if you can find them. An organized content library is the difference between "I know I had a great GIF of the boss fight somewhere..." and "here it is, tagged and ready to use."

**Content library organization:**

Create a folder structure like this:

```
marketing/
├── raw/                    ← Unedited captures, replay buffer clips
│   ├── 2025-01/
│   ├── 2025-02/
│   └── ...
├── edited/                 ← Finished GIFs, cropped screenshots
│   ├── screenshots/
│   ├── gifs/
│   └── videos/
├── posted/                 ← Content that's been published (with dates/platforms noted)
│   ├── twitter/
│   ├── reddit/
│   └── steam/
└── press-kit/              ← High-res assets for press outreach
    ├── screenshots/
    ├── logos/
    └── key-art/
```

**Naming convention:** Use descriptive names, not sequential numbers. `crystal-cave-combat-grapple-hook.gif` is findable. `recording_2025-02-14_3.gif` is not.

**The "greatest hits" folder:** Maintain a separate folder (or tag) for your absolute best content — the GIFs that got the most engagement, the screenshots that best represent your game. This folder is what you pull from when a journalist asks for assets, when you're building your Steam page, or when you need a quick post and don't have time to create something new.

**Content recycling:** Great content can be posted more than once. A GIF you posted on Twitter three months ago can be posted on Reddit today. A screenshot from your Reddit post can appear in a Steam community update. Your audience on each platform is different, and even on the same platform, most followers didn't see your original post. Recycling is not lazy — it's efficient.

**Real-world example:** The **Hollow Knight** developers maintained a consistent visual library throughout their years of development. Key art, character designs, and environmental screenshots were reused across Kickstarter updates, social media, and eventually the Steam page. The same assets served multiple purposes because they were organized and accessible.

**Common mistake:** Not organizing at all and ending up with 500 unlabeled clips in a downloads folder. Twenty minutes spent setting up a folder structure now saves hours of searching later.

**Try this now:** Create the folder structure above (or a simplified version that works for you). Move any existing marketing content into the appropriate folders. Going forward, save every capture directly into the `raw/` folder organized by month. This small habit makes everything else in the pipeline smoother.

---

### 7. Advanced GIF Techniques

**Once you've mastered the basics of capture and conversion, these techniques will elevate your GIFs from "fine" to "shareable."**

**The perfect loop:** A GIF that loops seamlessly gets watched multiple times without the viewer realizing it. To create a perfect loop, capture footage that starts and ends in a similar state — the character returns to idle position, the camera angle resets, or the environment cycles. Trim the GIF so the last frame connects smoothly to the first. This subtle technique dramatically increases watch time.

**Speed ramping:** Not everything in your GIF needs to be at the same speed. Slow down the most impressive moment (a huge explosion, a perfect dodge, a satisfying click) and speed up the less interesting parts (setup, traversal). Most video editing tools and GIF editors support frame-by-frame speed adjustment. This technique focuses the viewer's attention where you want it.

**Isolated mechanic showcase:** Strip away everything except the one thing you want to show. If you're showcasing your grappling hook, find a moment where the grappling hook is the star — no distracting enemies, no complex UI, just the hook in action. Simplicity is clarity, and clarity is engagement.

**The comparison GIF:** Show "before" and "after" in a single GIF. Split the frame (side by side) or show them sequentially with a clear transition. Before/after GIFs are inherently compelling because they demonstrate progress, polish, and craft. "Here's what the lighting looked like last month vs. now" gets developers and players engaged for different reasons — both good.

**The zoom-in reveal:** Start your GIF at normal game camera distance, then zoom in to show a detail — texture quality, a small animation, a subtle environmental storytelling element. This technique works because it rewards attention and demonstrates craft at multiple scales.

**Optimization for file size:**

If your GIFs are too large:

| Technique | Size Reduction | Quality Impact |
|-----------|---------------|----------------|
| Reduce resolution (1080p → 720p) | ~50% | Slight — usually acceptable |
| Reduce framerate (60fps → 30fps) | ~50% | Slight — 30fps is standard for GIFs |
| Reduce length (8sec → 5sec) | ~35% | Forces tighter editing — often improves the GIF |
| Reduce color palette | ~20-40% | Depends on game art style — pixel art handles this well |
| Upload as MP4 instead | ~80% | No quality loss — just a different format |

**Common mistake:** Over-processing GIFs with filters, borders, and watermarks. Your game is the content. Let it speak for itself. A subtle watermark with your game's name is fine. A giant "WISHLIST NOW" banner across the bottom is not.

**Try this now:** Take one of your existing GIFs and try one advanced technique: create a perfect loop, add speed ramping, or create a before/after comparison. Post the improved version alongside the original and notice the difference.

---

### 8. Sustainable Content Creation (The ADHD-Friendly Approach)

**The biggest enemy of consistent content creation isn't lack of skill — it's lack of systems.** For developers with ADHD or anyone who struggles with consistency, the answer isn't "try harder" or "be more disciplined." The answer is to design systems that make consistent creation the path of least resistance.

**The Anti-Burnout Content Framework:**

**1. Lower the bar, raise the floor.**
Your weekly commitment should be embarrassingly small: one screenshot or GIF, posted once, on one platform. That's the floor. You can always do more, but the floor keeps you going during weeks when motivation is low. A mediocre GIF posted this week is worth infinitely more than the perfect content series you plan for next month and never execute.

**2. Batch creation, scheduled publishing.**
Spend one session per week (set a 45-minute timer) creating and scheduling content for the entire week. When the timer goes off, you're done. This means marketing interrupts your development exactly once per week, for less than an hour. Everything else runs on autopilot through scheduling tools.

**3. Development = content.**
Stop thinking of marketing content as a separate activity from development. Every feature you build, every bug you fix, every visual improvement you make is potential content. The replay buffer captures it automatically. Your job is just to select the best moments and share them.

**4. Templates eliminate decisions.**
Create a template for each post type:
- **Screenshot post:** "[Screenshot] + one sentence about what's happening + one sentence about what you're working on next"
- **GIF post:** "[GIF] + 'Just got [feature] working!' or 'Here's how [mechanic] looks in action'"
- **Devlog:** "Header + what I did this week (3 bullets) + what's coming next (1-2 sentences) + screenshot or GIF"

When you sit down to create content, you don't start from scratch. You fill in a template. This removes the creative paralysis of staring at a blank post.

**5. Accountability structures.**
- Join a gamedev Discord with a #marketing-monday or #screenshot-saturday channel
- Find an accountability buddy — another indie dev who checks in weekly on whether you posted
- Use a public tracker (a pinned thread in your Discord, a streak counter) that creates mild social pressure

**6. Celebrate posting, not engagement.**
You can't control whether a post goes viral. You can control whether you posted at all. Track your posting streak, not your like count. If you posted something this week, that's a win. If you posted something every week for a month, that's a bigger win. The engagement will come with time and consistency.

**Real-world example:** Many successful indie developers describe their marketing process as boring and routine — which is exactly the point. The developer of **Luck Be a Landlord** posted regular Twitter/GIF content about the game for months. It wasn't exciting or viral — it was consistent. The audience grew slowly, then faster, then faster. Consistency created compound growth that no single viral moment could match.

**Common mistake:** Waiting for inspiration to strike before creating content. Inspiration is unreliable. Systems are reliable. Design your pipeline so that content creation doesn't require inspiration — it requires pressing a hotkey, selecting a clip, and filling in a template.

**Try this now:** Set up your minimum viable system right now:
1. OBS replay buffer running during development? ✓/✗
2. GIF creation tool installed? ✓/✗
3. Content calendar for next 2 weeks planned? ✓/✗
4. Scheduling tool set up (even if it's just a reminder in your calendar)? ✓/✗
5. One post template written? ✓/✗

Check every box. The system is the strategy.

---

## Case Studies

### Case Study 1: Noita — Physics Porn as a Content Strategy

**The game:** A roguelite with simulated pixel-based physics where every pixel is part of the simulation, by Nolla Games.

**The content strategy:** Noita's entire pre-launch marketing was built on one insight: the game's pixel physics engine created endlessly shareable moments. Fire spreading through wood, acid dissolving terrain, explosions creating chain reactions — these emergent physics interactions made for irresistible GIFs.

**What they did:**
- Captured hundreds of emergent physics moments during playtesting
- Posted the most visually spectacular ones as GIFs on Twitter and Reddit
- Each GIF showed a single physical interaction — simple, clear, and fascinating
- Maintained a regular posting cadence for over a year before launch
- Let the physics be the star — minimal text, minimal explanation needed

**The result:** Noita built a massive pre-launch following through GIF content alone. Many of their posts went viral on r/gaming and r/indiegames because the content was inherently fascinating regardless of whether viewers knew the game. The GIFs served as both marketing and proof of concept.

**The lesson:** Identify the most visually interesting aspect of your game and build your content pipeline around it. For Noita, it was physics. For your game, it might be combat animations, building systems, character interactions, or environmental design. Find your game's "GIF hook" and lean into it hard.

---

### Case Study 2: Unpacking — The Satisfaction Loop

**The game:** A zen puzzle game about unpacking boxes after moving, by Witch Beam.

**The content strategy:** Unpacking's GIFs focused on the core satisfaction of the game — the ASMR-like pleasure of placing objects in a new home. Each GIF showed 5-8 seconds of objects being carefully arranged: books on a shelf, plates in a cabinet, decorations on a desk.

**What they did:**
- Created short, self-contained GIFs of satisfying object placement
- Used the game's gentle sound design (even in GIF form, viewers could "hear" the clicks)
- Posted consistently on Twitter with minimal captions — the visual did all the work
- Varied the content by showing different rooms, different life stages, different object types
- Participated in Steam Next Fest with a demo that let players create their own satisfying moments

**The result:** Unpacking's GIF content reached far beyond the typical "gamer" audience. People who never play games shared the GIFs because the satisfaction was universal. By launch, the game had a dedicated audience built almost entirely on the emotional response to short visual content.

**The lesson:** Your content doesn't need to show explosions or complex systems to be effective. It needs to evoke an emotional response. Unpacking evoked satisfaction. What emotion does your game evoke? Build your content around that emotion.

---

### Case Study 3: Luck Be a Landlord — The Slow Build

**The game:** A roguelike deckbuilder about slot machines, by TrampolineTales.

**The content strategy:** The developer posted regular GIFs on Twitter showing interesting item combinations and slot machine outcomes. No viral moments, no elaborate production — just consistent, weekly content showing the game being played.

**What they did:**
- Captured gameplay moments during development and playtesting
- Posted 2-3 GIFs per week showing different item synergies and outcomes
- Engaged with the community that formed around the tweets
- Used Twitter threads to explain interesting mechanical interactions
- Built wishlist momentum gradually over 6+ months

**The result:** Luck Be a Landlord accumulated over 100,000 wishlists before launch, primarily through consistent organic social media content. No ads, no influencer deals, no viral moments. Just a developer sharing their game regularly with a growing audience.

**The lesson:** The compounding effect of consistent posting is real but slow. The first month feels pointless. The third month shows tiny growth. By month six, the growth accelerates. By month twelve, you have an audience. Most developers quit during month two. Don't quit during month two.

---

## Exercises

### Exercise 1: Pipeline Setup (30–45 minutes)

Set up your complete capture-to-post pipeline:

1. Install OBS Studio (or your preferred capture tool) and configure the replay buffer
2. Install a GIF creation tool (ScreenToGif, Gifski, or set up ffmpeg)
3. Create the content library folder structure from Concept 6
4. Set a hotkey for replay buffer capture
5. Test the entire pipeline: capture gameplay → save replay → trim to GIF → save to library

Your pipeline is "done" when you can go from "something cool happened" to "here's a shareable GIF" in under 5 minutes.

**Stretch goal:** Time yourself going through the full pipeline. If it takes more than 10 minutes, identify and eliminate the bottleneck.

---

### Exercise 2: The Content Burst (45–60 minutes)

Capture 10 screenshots and 3 GIFs from your current build (or prototype). Then curate them:

1. Select the best 5 screenshots using the composition principles from Concept 3
2. Select the best 2 GIFs — the ones that best showcase one interesting aspect of your game
3. For each selected piece, write a one-line caption suitable for Twitter
4. Post one to a platform of your choice

This exercise proves you can generate a week's worth of content in a single session.

**Stretch goal:** Post the same content (adapted) on a second platform. Note any differences in engagement.

---

### Exercise 3: Two-Week Calendar (20–30 minutes)

Create a content calendar for the next two weeks:

1. Choose your two platforms
2. Plan 4 posts (2 per week, one per platform per week)
3. For each post, note: date, platform, content type (screenshot/GIF/devlog), and a one-line description
4. Pre-create or schedule at least the first two posts

**Stretch goal:** Actually execute the full two-week calendar. At the end, review: what was easy? What was hard? What would you change for the next two weeks?

---

### Exercise 4: The Anti-Marketing Friction Audit (20 minutes)

Identify the friction points in your current content creation process:

1. How many steps does it take to go from "cool moment" to "posted content"?
2. Which step takes the longest?
3. Which step do you dread the most?
4. What tool, habit, or template would eliminate that friction?

Write down one specific change you'll make this week to reduce friction. Implement it.

**Stretch goal:** Ask another indie dev about their content pipeline. Steal one idea from their process that would make yours easier.

---

## Recommended Reading

| Resource | Type | What You'll Learn |
|----------|------|-------------------|
| [How to Make Good Screenshots for Your Indie Game](https://howtomarketagame.com/2023/07/24/how-to-make-good-screenshots-for-your-indie-game/) — Chris Zukowski | Blog post | Practical screenshot composition advice for indie devs |
| [Indie Game Marketing in 2019](https://gdcvault.com/play/1025772/Indie-Game-Marketing-in-2019) — Mike Rose (GDC) | GDC talk | Practical content marketing talk with real examples |
| [OBS Studio](https://obsproject.com/) | Tool | Free, open-source screen recording for building your capture pipeline |
| [ScreenToGif](https://www.screentogif.com/) | Tool | Free Windows tool for recording and editing GIFs |
| [Gifski](https://gif.ski/) | Tool | High-quality GIF conversion for Mac |
| [Buffer](https://buffer.com/) | Tool | Social media scheduling tool (free tier available) |
| [How to Make Game GIFs That Get Attention](https://www.derek-lieu.com/blog/2017/7/17/how-to-make-game-gifs-that-get-attention) — Derek Lieu | Blog post | Professional game trailer editor on creating effective marketing GIFs |
| [Screenshot Saturday Best Practices](https://howtomarketagame.com/2022/04/25/how-to-participate-in-screenshot-saturday/) — Chris Zukowski | Blog post | How to make the most of #ScreenshotSaturday on Twitter |

---

## Key Takeaways

- **Capture everything, automatically.** Set up a replay buffer and press a hotkey when something interesting happens. Zero-friction capture is the foundation of the entire pipeline.

- **GIFs outperform screenshots on every platform.** 3-8 seconds, one mechanic, one moment. Keep them short, focused, and under 15MB.

- **Composition matters.** Marketing screenshots aren't random captures — they're deliberately composed images. Use rule of thirds, show scale, capture mid-action, and include meaningful UI.

- **A content calendar removes decision fatigue.** Plan what you'll post and where, one week at a time. Two posts per week is a sustainable minimum.

- **Each platform has its own rules.** Adapt your content for each platform's format, culture, and expectations. Cross-posting identical content rarely works.

- **Organize your content library.** Every screenshot and GIF is an asset. Name them descriptively, folder them by type, and maintain a "greatest hits" collection.

- **Consistency beats perfection.** A mediocre GIF posted this week is worth more than a perfect one you never post. Lower the bar, raise the floor, and show up every week.

- **Development is content.** Every feature you build is a potential post. Your pipeline captures development as marketing — no extra work required.

---

## What's Next?

**Next module:** [Module 4: Community Building](module-04-community-building.md) — You have content. Now you need a community to share it with. Module 4 shows you how to build and sustain a community around your game using Discord, Reddit, and devlogs.

**Parallel modules:** [Module 5: Press, Influencers & Key Distribution](module-05-press-influencers-key-distribution.md) and [Module 6: Trailers That Actually Work](module-06-trailers-that-actually-work.md) can be started once you've established your content pipeline. Both build on the capture and editing skills you've developed here.
