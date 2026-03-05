# Game Design Domain Map

A curated vocabulary reference for game design. Use these terms to prompt AI tools with specificity — each entry includes a plain-language definition and an example prompt showing the term in context.

**How to use this page:** Scan the branch that matches your design problem. Grab the precise term, drop it into your prompt, and get better results than vague descriptions ever produce.

---

## Systems Design

How games create rules, loops, and economies that players navigate.

### Core Loops & Mechanics

The fundamental actions and cycles that define what a game *is*.

- **Core Loop** — The repeating cycle of actions a player performs most often. In a roguelike: fight → loot → upgrade → fight again. Everything else orbits this loop.
  *"Design a core loop for a colony sim where the player balances resource gathering, building, and defending against raids."*

- **Mechanic** — A single rule expressed as a verb-consequence pair. "Press jump" is a mechanic. "Craft a sword from iron" is a mechanic. The atomic unit of game design.
  *"List five mechanics that would support a gravity-manipulation core mechanic in a puzzle platformer."*

- **Verb** — The action a player can take. Jump, shoot, place, trade, dodge. A game's verb set defines its identity more than its theme or art style.
  *"What verbs would differentiate a stealth game from an action game set in the same world?"*

- **Emergent Gameplay** — Complex behaviors that arise from simple rules interacting. Chess has six piece types but near-infinite strategies. Emergence is the payoff of good systems design.
  *"How can I design a fire-spreading mechanic that creates emergent gameplay when combined with wind and destructible environments?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=emergent+gameplay+examples+systemic+design)

- **Risk/Reward** — The tradeoff between potential gain and potential loss. Higher risk should offer higher reward, but the interesting design is in how the player evaluates that tradeoff.
  *"Design a risk/reward mechanic for a fishing minigame where waiting longer increases catch quality but also the chance of losing the line."*

- **Agency** — The degree to which a player's choices meaningfully affect outcomes. High agency means decisions matter. Low agency means the game plays itself.
  *"How can I increase player agency in a narrative game without creating an exponential branching problem?"*

- **Constraint** — A limitation that forces creative problem-solving. A time limit, limited inventory, or restricted movement. Constraints are what make mechanics interesting.
  *"What constraints could make a simple block-placement mechanic feel strategic rather than tedious?"*

- **State Space** — The total number of possible game states. Tic-tac-toe has a tiny state space. Go has a massive one. Larger state spaces generally support deeper strategy.
  *"Estimate the state space of my card game with 60 unique cards and a 10-card hand limit. Is it large enough for competitive depth?"*

- **Win Condition** — What the player must do to succeed. Can be explicit (capture the flag) or implicit (survive as long as possible). Defines the player's strategic goal.
  *"Design three alternative win conditions for a 4X strategy game beyond military conquest."*

- **Fail State** — What happens when the player loses. Permadeath, checkpoint restart, resource penalty. How failure works shapes how players approach risk.
  *"Compare fail states: permadeath vs. corpse-run vs. checkpoint restart. Which best suits a 30-minute roguelike run?"*

- **Procedural Generation** — Using algorithms to create content at runtime: levels, loot, terrain, quests. Trades authored precision for infinite variety and replayability.
  *"Design a procedural generation system for dungeon layouts that guarantees a critical path while allowing dead ends and secret rooms."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=procedural+generation+dungeon+level+algorithm)

### Economy & Resources

How value flows through a game — what players earn, spend, and chase.

- **Source** — Anything that generates resources. Mines produce gold, enemies drop loot, daily logins grant currency. Every economy starts at its sources.
  *"Map the sources in my RPG economy: quest rewards, enemy drops, crafting, and shops. Which one dominates?"*

- **Sink** — Anything that removes resources from the economy. Repair costs, consumables, upgrade fees. Without sinks, economies inflate and currency becomes meaningless.
  *"My MMO economy is inflating — design three new gold sinks that feel rewarding rather than punishing."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+economy+source+sink+diagram)

- **Currency** — A medium of exchange within the game. Can be soft (earned through play), hard (purchased with real money), or social (reputation, karma).
  *"Should my mobile game use a single soft currency or a dual-currency model? What are the design tradeoffs?"*

- **Inflation** — When currency accumulates faster than sinks remove it, everything becomes too cheap and rewards lose meaning. The slow death of an unmanaged economy.
  *"What inflation-prevention mechanics work in a player-driven auction house economy?"*

- **Scarcity** — Limiting supply to create value. Rare drops, seasonal items, limited crafting materials. Scarcity drives motivation but frustrates if overdone.
  *"How do I balance scarcity of legendary weapons so they feel special without making most players feel locked out?"*

- **Opportunity Cost** — What a player gives up by choosing one option over another. Spending gold on armor means not spending it on potions. Good design makes this choice painful in a fun way.
  *"Design a skill point system where every allocation has a meaningful opportunity cost."*

- **Loot Table** — A weighted probability list that determines what drops from an enemy, chest, or event. The invisible engine behind every "nice drop" moment.
  *"Create a loot table for a dungeon boss with common, rare, and legendary tiers. Include pity mechanics."*

- **Crafting** — Combining resources to create items. Can be simple (recipe-based) or complex (experimentation-based). Good crafting makes gathering feel purposeful.
  *"Design a crafting system that rewards experimentation without making recipe-lookup mandatory."*

- **Inventory** — The system that governs what a player can carry. Weight limits, slot counts, and sorting all shape how players interact with loot.
  *"Compare grid-based inventory (Resident Evil 4) vs. weight-based (Skyrim) vs. list-based (Diablo). Which fits a survival horror game?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+inventory+system+design+grid+weight)

- **Drop Rate** — The probability of receiving a specific item from a loot source. 1% sounds rare until a player kills 500 enemies. Drop rates define the grind.
  *"What drop rate and pity system would target a median of 20 boss kills before a legendary drops?"*

### Progression & Retention

How players advance, unlock, and keep coming back.

- **Experience Curve** — The relationship between XP earned and levels gained. Flat curves feel fast early. Exponential curves slow the endgame. The shape defines the pacing of power growth.
  *"Plot an experience curve for a 50-hour RPG where levels 1-10 take 3 hours and levels 40-50 take 15 hours."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=experience+curve+XP+leveling+graph+game+design)

- **Power Curve** — How player power increases over time. Linear, exponential, or S-curve. Must stay ahead of difficulty curve by just enough to feel good.
  *"My power curve is exponential but my difficulty curve is linear — players steamroll after level 20. How do I fix this?"*

- **Gating** — Blocking progress until a condition is met. Level gates, story gates, skill gates. Controls pacing but frustrates if arbitrary.
  *"Design soft gates for a metroidvania that feel like discoveries rather than locked doors."*

- **Unlock** — Revealing new content, abilities, or options as a reward for progress. The drip-feed that keeps the game feeling fresh.
  *"Plan an unlock schedule for a 10-hour campaign that introduces one new mechanic per hour without overwhelming the player."*

- **Prestige** — Resetting progress in exchange for permanent bonuses. The foundation of idle games and deep progression systems.
  *"Design a prestige system for a tower defense game. What carries over, what resets, and what's the incentive to prestige?"*

- **Meta-progression** — Permanent upgrades that persist across individual runs or sessions. Unlocking new characters, starting bonuses, or shortcuts.
  *"Balance meta-progression in a roguelike so that skill still matters more than accumulated unlocks."*

- **Skill Tree** — A branching structure of abilities the player can unlock. Encourages build diversity and replayability when branches involve real tradeoffs.
  *"Design a skill tree with three branches where hybrid builds are viable but pure specialization is stronger."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=skill+tree+game+design+branching)

- **Milestone** — A significant achievement or checkpoint that marks progress. Beating a boss, reaching a new area, hitting a score threshold.
  *"Place milestones in a 40-level puzzle game so players feel a sense of accomplishment every 15-20 minutes."*

- **Grind** — Repetitive play required to advance. Some players love it (Diablo). Some hate it. The line between satisfying grind and tedious grind is engagement per repetition.
  *"My players say the mid-game grind is tedious. How can I add variety without changing the core loop?"*

- **Soft Cap** — A point where returns diminish sharply without hitting a hard limit. Level 50 might take 10x the XP of level 49 but isn't technically impossible.
  *"Implement a soft cap on attack speed so stacking speed items still helps but never breaks encounter balance."*

---

## Level Design

How physical and virtual spaces guide the player.

### Spatial Design

The architecture of game spaces — where things are and why.

- **Critical Path** — The shortest route through a level that completes the objective. Everything else is optional exploration branching off this spine.
  *"Sketch a critical path through a dungeon level with three optional side rooms that reward exploration."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=critical+path+level+design+diagram)

- **Sight Line** — What the player can see from a given position. Used to guide attention, reveal destinations, and create dramatic reveals.
  *"Place a sight line from the starting area that shows the final boss tower in the distance, establishing the goal immediately."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=sight+lines+level+design+game)

- **Chokepoint** — A narrow passage that forces encounters or creates defensible positions. Funnels player movement and creates tactical decisions.
  *"Design a chokepoint in a PvP map that advantages defenders but gives attackers two flanking routes."*

- **Arena** — An enclosed space designed for combat encounters. Clear boundaries, cover placement, and enemy spawn points define the fight.
  *"Design an arena for a boss fight that uses verticality and destructible pillars to evolve across three phases."*

- **Hub World** — A central area that connects to multiple levels or zones. Provides orientation, a sense of home, and a place to prepare between challenges.
  *"Design a hub world for a platformer that gradually reveals new paths as the player gains abilities."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=hub+world+game+design+map+layout)

- **Verticality** — Using height differences to create gameplay variety. Climbing, falling, overlapping paths, and elevation advantages.
  *"Add verticality to a flat arena shooter map. How do height advantages change weapon balance?"*

- **Negative Space** — Empty or low-detail areas that make important spaces feel more significant by contrast. The quiet between the loud.
  *"Use negative space in a horror game corridor to build tension before the player reaches the next scripted encounter."*

- **Landmark** — A visually distinct feature that helps players orient themselves. A tall tower, a unique tree, a glowing crystal. Prevents getting lost.
  *"Place three landmarks in an open-world zone so players can triangulate their position without a minimap."*

- **Playable Space** — The actual area where the player can move and interact, as opposed to decorative background or inaccessible geometry.
  *"What percentage of my level is playable space vs. decoration? Am I wasting production time on areas players never reach?"*

- **Secret Area** — A hidden space that rewards exploration: tucked behind a fake wall, under a waterfall, or accessible only with a specific ability. Teaches players that curiosity pays off.
  *"Place three secret areas in my dungeon level: one that rewards observation, one that rewards backtracking with a new ability, and one that rewards environmental interaction."*

- **Level Geometry** — The physical shapes that make up the environment: floors, walls, ramps, platforms. The bones of a level before art is applied.
  *"Block out level geometry for a stealth mission using only cubes and ramps. Test it before adding any art."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=level+geometry+blockout+graybox+game+design)

### Flow & Pacing

How intensity and rest alternate to create rhythm.

- **Pacing Curve** — The graph of intensity over time. Good pacing alternates between peaks (action, challenge) and valleys (rest, exploration, story).
  *"Draw a pacing curve for a 90-minute play session that builds to two climaxes with a quiet midpoint."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=pacing+curve+game+design+intensity+graph)

- **Tension/Release** — The cycle of building pressure and then resolving it. A locked door with enemies behind it (tension). Opening it and clearing the room (release).
  *"Design a tension/release cycle for a horror sequence: 3 minutes of building dread, 30 seconds of action."*

- **Breadcrumbing** — Leaving small rewards or hints that lure the player forward. A coin trail, a distant sound, a glimpse of something interesting around the corner.
  *"Use breadcrumbing to guide players through an open cave system without explicit waypoints or markers."*

- **Point of No Return** — A moment after which the player cannot go back. Powerful for narrative weight but frustrating if the player missed something important.
  *"Signal an upcoming point of no return so players can prepare without spoiling what happens next."*

- **Safe Room** — A space free from threats where the player can save, manage inventory, and decompress. The exhale between inhales.
  *"Design a safe room for a survival horror game that feels genuinely calming without breaking immersion."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=safe+room+save+room+game+design+resident+evil)

- **Setpiece** — A scripted or heavily designed moment meant to be a highlight. A collapsing bridge, a dramatic chase, a massive reveal.
  *"Plan a setpiece for the midpoint of my action game that uses existing mechanics in a surprising new context."*

- **Beat** — A single unit of pacing — one event, one encounter, one emotional note. Levels are sequences of beats, like notes in a song.
  *"Break my tutorial level into 8 beats: teach, test, reward, teach, test, twist, test, celebrate."*

- **Crescendo** — A sustained escalation in intensity leading to a peak. More enemies, faster music, tighter time pressure, all building at once.
  *"Design a crescendo sequence for a horde-mode wave where enemy count, speed, and variety all increase simultaneously."*

- **Downtime** — Periods of low intensity that let players rest, reflect, and prepare. Without downtime, high-intensity moments lose their impact.
  *"Insert downtime between boss fights where players explore, craft, and absorb story at their own pace."*

- **Gating (Level Design)** — Using spatial barriers to control when players access areas. Locked doors, broken bridges, ability-locked paths. Distinct from progression gating — this is physical.
  *"Gate three areas of my metroidvania behind different traversal abilities: double jump, wall climb, and grapple."*

### Environmental Storytelling

Using space itself as narrative.

- **Environmental Storytelling** — Telling stories through the environment rather than dialogue or cutscenes. A ransacked room tells its own story.
  *"Design an abandoned laboratory that tells the story of an experiment gone wrong using only object placement and environmental damage."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=environmental+storytelling+game+design+examples)

- **Mise-en-scène** — The arrangement of everything within a scene: lighting, props, character positions. Borrowed from film, essential for creating mood.
  *"Use mise-en-scène to make a throne room feel oppressive: low lighting, towering architecture, a single spotlight on the throne."*

- **Vignette** — A small, self-contained environmental scene that tells a micro-story. A skeleton clutching a letter. A child's toy next to an overturned table.
  *"Create three vignettes for a post-apocalyptic suburb that show how different families responded to the crisis."*

- **Found Narrative** — Story that the player discovers rather than receives. Notes, recordings, environmental clues. The player assembles meaning from fragments.
  *"Scatter found narrative through a space station: crew logs, maintenance reports, and personal messages that piece together a mutiny."*

- **Signposting** — Visual cues that guide the player without explicit UI. A red door stands out. A lit path draws the eye. Paint splatters mark climbable surfaces.
  *"Design a signposting system for climbable surfaces that feels natural in a realistic art style."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+signposting+visual+cues+climbable+surfaces)

- **Diegetic UI** — Interface elements that exist within the game world. A health bar on the character's back, an in-world map, a watch that shows real time.
  *"Replace my HUD health bar with a diegetic alternative that fits a sci-fi setting."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=diegetic+UI+game+design+dead+space)

- **Ambient Dialogue** — Background conversations or announcements that build world texture without requiring player interaction. NPCs chatting, PA announcements, radio chatter.
  *"Write 10 ambient dialogue lines for marketplace NPCs that reveal the city is running low on food without stating it directly."*

- **Set Dressing** — Props and details added to a space to make it feel lived-in and believable. Books on shelves, food on tables, tools in a workshop.
  *"List set dressing items for a medieval blacksmith's shop that communicate the owner's personality and skill level."*

- **World Detail** — Small touches that reward close observation. Graffiti, worn paths in grass, water stains, flickering lights. The layer that makes a world feel real.
  *"Add world details to a cyberpunk alley that tell players this area is neglected by the city's maintenance systems."*

- **Readable** — An in-world text object the player can examine: letters, signs, books, computer terminals. Delivers lore on demand without forcing it.
  *"Write a readable for an ancient temple inscription that hints at the dungeon's puzzle solution without giving it away."*

---

## Player Experience

How players feel, learn, and stay motivated.

### Onboarding & Tutorials

Teaching without boring.

- **Tutorialization** — The design philosophy of teaching through play rather than instruction screens. Show, don't tell. Let the player discover rather than read.
  *"Tutorialize a wall-jump mechanic by designing a room where the only exit requires wall-jumping, with no text instructions."*

- **Gated Complexity** — Introducing mechanics one at a time, mastering each before adding the next. Prevents overwhelm. Builds confidence.
  *"Plan a gated complexity sequence: introduce sword combat in level 1, add shield in level 2, combine both against a miniboss in level 3."*

- **Scaffolding** — Providing temporary support that is removed as the player gains skill. Training wheels for game mechanics.
  *"Design scaffolding for a combo system: auto-complete combos early on, then gradually require manual input."*

- **Contextual Prompt** — A UI hint that appears only when relevant. "Press X to interact" when near a door, not on a permanent HUD element.
  *"Show contextual prompts for new mechanics the first three times, then fade them out permanently."*

- **Learning Curve** — How quickly a game demands increasing skill from the player. Steep curves filter players fast. Gentle curves risk boring experienced players.
  *"Compare the learning curves of Celeste (gentle with optional difficulty) vs. Sekiro (steep and fixed). When is each approach right?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=learning+curve+game+design+graph)

- **Safe Fail** — A situation where the player can fail without significant consequence, encouraging experimentation. Early enemies that deal minimal damage. Puzzles that reset instantly.
  *"Design a safe-fail zone at the start of each level where players can practice new mechanics without losing progress."*

- **Tutorial Island** — A self-contained starting area that teaches core mechanics in isolation before releasing the player into the main game.
  *"Design a tutorial island for an open-world survival game that covers gathering, crafting, building, and combat in 15 minutes."*

- **Just-in-Time Teaching** — Introducing a mechanic moments before the player needs it. Not in a front-loaded tutorial, but embedded in the flow of play.
  *"Teach the grapple hook mechanic just-in-time: place it on a pedestal right before a gap that's too wide to jump."*

- **Friction** — Intentional resistance that slows the player down. Can be good (makes choices feel weighty) or bad (needless busywork). The key is whether friction serves a design purpose.
  *"Is the friction in my crafting menu intentional (making choices feel significant) or accidental (bad UX)? How do I tell the difference?"*

- **Affordance** — A visual property that suggests how something can be used. A ledge that looks grabbable. A button that looks pressable. Good affordance means players know what to do without being told.
  *"Improve affordances in my puzzle game so players can identify interactive objects at a glance."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=affordance+game+design+interactive+objects)

### Difficulty & Challenge

Calibrating the struggle.

- **Difficulty Curve** — How challenge increases over time. Should generally rise but with valleys for rest. Too flat is boring. Too steep causes churn.
  *"Graph a difficulty curve for a 20-level puzzle game where each level introduces one new element."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=difficulty+curve+game+design+graph)

- **Dynamic Difficulty** — The game adjusts challenge based on player performance in real-time. Die too much and enemies get weaker. Ace it and they get tougher.
  *"Implement dynamic difficulty that adjusts enemy aggression and damage based on the player's death count per area."*

- **Rubber-banding** — A catch-up mechanic that helps losing players and slows winning ones. Named after the rubber-band effect in racing games where last-place gets speed boosts.
  *"Add rubber-banding to my racing game's AI so trailing racers get subtle speed boosts without it feeling unfair."*

- **Skill Floor** — The minimum competence required to play at all. A low skill floor means anyone can start. A high skill floor means only experienced players can engage.
  *"Lower the skill floor of my fighting game so new players can execute basic combos without frame-perfect timing."*

- **Skill Ceiling** — The maximum level of mastery the game supports. A high skill ceiling means there is always more to learn. Essential for competitive longevity.
  *"Raise the skill ceiling of my platformer by adding advanced techniques like wall-jump cancels and momentum preservation."*

- **Cheese** — An unintended strategy that trivializes a challenge. Sniping a boss from a ledge it can't reach. Sometimes it's a bug; sometimes it's a feature players love.
  *"Playtesters are cheesing my boss by hiding behind a pillar. Should I patch it or design around it?"*

- **Punish Window** — The period after an enemy's attack where it is vulnerable. Longer punish windows make fights easier. Shorter ones demand precision.
  *"Design a boss with three attack patterns that each have different punish window lengths to test different player skills."*

- **Recovery** — How the player can regain health, resources, or position after taking a hit. Generous recovery lowers difficulty. Limited recovery raises it.
  *"Balance recovery in my survival game: health regenerates slowly out of combat, but only healing items work during fights."*

- **Accessibility Options** — Settings that let players with disabilities engage with the game. Remappable controls, colorblind modes, subtitle options, adjustable timings.
  *"List accessibility options my 2D platformer should ship with at minimum. What's low-effort but high-impact?"*

- **Assist Mode** — An optional reduced-difficulty mode that preserves the core experience while removing barriers. Celeste's assist mode is the gold standard.
  *"Design an assist mode for my action game that lets players toggle invincibility, slower game speed, and skip-encounter options independently."*

### Psychology & Motivation

Why players keep playing.

- **Flow State** — The mental zone where challenge perfectly matches skill. Too easy causes boredom. Too hard causes anxiety. Flow is the sweet spot between them.
  *"How do I keep players in a flow state during my rhythm game's middle difficulty levels?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=flow+state+diagram+csikszentmihalyi+game+design)

- **Intrinsic Motivation** — Playing because the activity itself is enjoyable. Curiosity, mastery, creativity. The player would play even without rewards.
  *"My sandbox game relies on intrinsic motivation. How do I sustain it over 100+ hours without extrinsic reward structures?"*

- **Extrinsic Motivation** — Playing for external rewards: achievements, leaderboards, unlocks, social status. Effective but can undermine intrinsic motivation if overused.
  *"Balance extrinsic rewards (daily login bonuses, achievement badges) so they supplement rather than replace intrinsic motivation."*

- **Variable Reward** — Rewards that vary in type, timing, or magnitude. Slot machines use this. So do loot drops. Unpredictability is more compelling than certainty.
  *"Design a variable reward chest system where players never know if they'll get gold, gear, or a rare cosmetic."*

- **Loss Aversion** — Players feel losses more strongly than equivalent gains. Losing 100 gold hurts more than gaining 100 gold feels good. Powerful but dangerous to exploit.
  *"Use loss aversion ethically: let players insure valuable items against death so the fear of loss drives engagement without frustration."*

- **Sunk Cost** — The tendency to continue something because of past investment, not future value. "I've played 200 hours, I can't quit now."
  *"Is my endgame retention driven by genuine fun or sunk cost? How do I test the difference?"*

- **FOMO** — Fear of missing out. Limited-time events, exclusive rewards, seasonal content. Drives engagement but breeds resentment if overused.
  *"Design a seasonal event system that creates FOMO-driven urgency without punishing players who miss a week."*

- **Autonomy** — The player's sense of self-direction. Open-world games excel at this. Autonomy means the player chooses *what* to do, not just *how* to do it.
  *"Increase autonomy in my linear RPG by offering meaningful side activities that aren't required but are rewarding."*

- **Mastery** — The satisfaction of getting better at something. The journey from struggling to effortless. Mastery requires that the game be deep enough to reward practice.
  *"Design a scoring system that lets players see their mastery progression: accuracy, speed, and consistency tracked over time."*

- **Compulsion Loop** — A cycle designed to be habit-forming: trigger → action → reward → trigger. Effective but ethically fraught. Know when you're designing engagement vs. exploitation.
  *"Audit my game's compulsion loops. Which ones serve player enjoyment and which ones just serve retention metrics?"*

---

## Narrative Design

How stories work in interactive media.

### Story Structure

The architecture of narrative.

- **Three-Act Structure** — Setup, confrontation, resolution. The most common story framework. Act 1 introduces, Act 2 complicates, Act 3 resolves.
  *"Outline a three-act structure for a 10-hour action RPG: what happens in each act and where are the act breaks?"*

- **Inciting Incident** — The event that disrupts the status quo and launches the story. The village burns. The letter arrives. The portal opens.
  *"Design an inciting incident for a cozy farming game that feels urgent without being violent."*

- **Rising Action** — The series of escalating events between the inciting incident and the climax. Each beat raises the stakes.
  *"Plan five rising-action beats for a mystery game where each clue makes the conspiracy feel larger."*

- **Climax** — The peak moment of confrontation where the central conflict is decided. The final boss. The big reveal. The hardest choice.
  *"Design a climax that is both a narrative payoff and the game's most mechanically challenging encounter."*

- **Denouement** — The wind-down after the climax. Resolves remaining threads, shows consequences, and gives the player emotional closure.
  *"Write a 5-minute playable denouement where the player walks through the world they saved, seeing the effects of their choices."*

- **Subplot** — A secondary storyline that runs alongside the main plot. Adds depth, develops characters, and provides variety. Should connect thematically to the main plot.
  *"Design three subplots for an RPG party: a romance, a rivalry, and a personal redemption arc. How do they intersect with the main quest?"*

- **Foreshadowing** — Planting hints about future events. A cracked wall you'll later blow up. An NPC's offhand comment that gains meaning later.
  *"Add foreshadowing for the twist villain reveal in Act 3. What clues should exist in Act 1 that players will recognize on replay?"*

- **In Medias Res** — Starting the story in the middle of the action, then filling in backstory later. Hooks the player immediately.
  *"Open my game in medias res with the player fleeing a collapsing fortress, then flash back to show how they got there."*

- **Narrative Arc** — The overall shape of a character's or story's emotional journey. Rise, fall, transformation. Every compelling story has an arc.
  *"Map the narrative arc of my protagonist from naive recruit to disillusioned veteran to reluctant hero."*

- **Stakes** — What is at risk if the protagonist fails. Personal stakes (loved ones), global stakes (the world), or internal stakes (identity, morality).
  *"Escalate stakes across three acts: Act 1 threatens the player's village, Act 2 threatens the kingdom, Act 3 threatens reality itself."*

### Interactive Narrative

Player-driven storytelling.

- **Branching Narrative** — A story structure where player choices create diverging paths. Expensive to produce but deeply engaging when done well.
  *"Design a branching narrative with 3 major decision points that lead to 4 distinct endings without exponential content growth."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=branching+narrative+structure+diagram+game)

- **Player Agency (Narrative)** — The degree to which the player's choices shape the story. High agency means the player is a co-author. Low agency means the player is an audience.
  *"Increase narrative agency in my RPG without voice-acting every permutation. What techniques scale efficiently?"*

- **Consequence** — The result of a player's choice becoming visible later in the game. Saving a character in Act 1 means they help you in Act 3. Makes choices feel meaningful.
  *"Design a consequence system where three early-game choices each have visible effects in the final mission."*

- **Dialogue Tree** — A branching conversation system where the player chooses from response options. The backbone of RPG storytelling.
  *"Build a dialogue tree for a persuasion encounter with 3 approaches: intimidate, charm, or bribe. Each should feel distinct."*

- **Hub-and-Spoke** — A narrative structure where the player returns to a central hub between self-contained missions or story chapters. Common in RPGs and immersive sims.
  *"Design a hub-and-spoke structure for an investigation game where the hub is a detective's office and each spoke is a case."*

- **Flags** — Boolean or numeric variables that track player decisions and world state. "Saved the prisoner" = true. The invisible plumbing of interactive narrative.
  *"List the narrative flags I need to track in my branching murder mystery to ensure continuity across all paths."*

- **Reactivity** — The degree to which the game world responds to player actions. NPCs commenting on your deeds, environments changing, new options appearing.
  *"Add reactivity to my town hub: shopkeepers reference your recent quests, and buildings change based on story progress."*

- **Illusion of Choice** — Presenting choices that feel meaningful but converge to the same outcome. Useful for managing scope while maintaining engagement.
  *"Use illusion of choice in a dialogue scene where all three options lead to the same plot outcome but feel emotionally different."*

- **Multiple Endings** — Two or more distinct conclusions based on player choices throughout the game. Rewards replay and makes choices feel consequential.
  *"Design 4 endings for my RPG: best, good, bittersweet, and bad. What criteria determine which the player gets?"*

- **Narrative State** — The current configuration of all story variables at any point in the game. Which characters are alive, which quests are complete, which factions are allied.
  *"How do I manage narrative state across 30+ flags without creating impossible or contradictory combinations?"*

### World & Lore

The universe around the story.

- **Lore** — The history, rules, and background information of a game's world. Not the plot — the context that makes the plot meaningful.
  *"Write a one-page lore document for a fantasy world where magic is a finite resource that's running out."*

- **Worldbuilding** — The process of creating a coherent, believable setting. Includes geography, culture, history, politics, and rules of the world.
  *"Build a worldbuilding document for a sci-fi colony: planet conditions, political factions, technology level, and daily life."*

- **Codex** — An in-game encyclopedia that stores lore entries the player has discovered. Supplements the main narrative for players who want deeper context.
  *"Design a codex system that rewards exploration: each new area unlocks lore entries, and completing a category grants a bonus."*

- **Unreliable Narrator** — A narrator whose account cannot be fully trusted. Creates mystery, encourages critical thinking, and supports twist reveals.
  *"Frame my game's tutorial narrator as unreliable. What subtle lies should they tell that players only catch on a second playthrough?"*

- **Mythic Structure** — Story patterns drawn from mythology (Joseph Campbell's monomyth, hero's journey). Provides a tested emotional arc for the player character.
  *"Map my protagonist's journey to the hero's journey stages: call to adventure, crossing the threshold, ordeal, and return."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=hero%27s+journey+monomyth+diagram+game+narrative)

- **Faction** — A group within the game world with its own goals, values, and relationships to other factions. Creates political complexity and alliance choices.
  *"Design four factions for a post-apocalyptic game: what does each value, what do they offer the player, and why do they conflict?"*

- **Canon** — The officially accepted version of a story or world. What "really" happened vs. fan interpretation or non-canon side content.
  *"My game has multiple endings. Which is canon for the sequel, and how do I honor players who got different endings?"*

- **Retcon** — Retroactive continuity: changing established lore after the fact. Sometimes necessary, always risky. Handle with care.
  *"I need to retcon a character's backstory for the sequel. How do I do it without alienating fans of the original?"*

- **Flavor Text** — Short descriptive text on items, abilities, or UI elements that adds personality and world texture without being required reading.
  *"Write flavor text for 5 weapons in a dark fantasy RPG. Each should hint at the weapon's history in one sentence."*

- **Implied Narrative** — Story conveyed through implication rather than explicit telling. The player infers what happened from indirect evidence.
  *"Tell the story of a fallen kingdom through implied narrative: architecture, ruins, scattered belongings, and environmental decay."*

---

## Game Feel

The moment-to-moment sensation of interacting with a game.

### Input & Response

The connection between player and game.

- **Game Feel** — The tactile, kinesthetic sensation of controlling a game. The difference between a character that feels like a puppet and one that feels like an extension of your body.
  *"My platformer character feels 'floaty.' What specific parameters (gravity, acceleration, deceleration) should I tune to improve game feel?"*

- **Input Latency** — The delay between pressing a button and seeing the result on screen. Measured in milliseconds. Below 50ms feels instant. Above 100ms feels sluggish.
  *"What's an acceptable input latency budget for a fighting game? Break it down: input polling, game logic, render, display."*

- **Responsiveness** — How immediately and accurately the game reacts to player input. A responsive game feels snappy. An unresponsive one feels like you're fighting the controls.
  *"Improve responsiveness in my action game: should I prioritize animation canceling, input buffering, or reducing physics lag?"*

- **Animation Canceling** — Interrupting one animation to start another, prioritizing responsiveness over visual completeness. Players expect this in fast-paced games.
  *"Implement animation canceling for my melee combat: which animations should be cancelable and at what frames?"*

- **Input Buffer** — A window of time where the game accepts your next input before the current action finishes. Makes inputs feel forgiving without being sloppy.
  *"Add a 6-frame input buffer to my combo system so players can queue the next attack slightly before the current one ends."*

- **Coyote Time** — A brief grace period after walking off a ledge where the player can still jump. Named after Wile E. Coyote's hang time. Feels fair without being visible.
  *"Implement 100ms of coyote time in my platformer. Should I also add jump buffering for the landing side?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=coyote+time+game+design+platformer+diagram)

- **Dead Zone** — The area around a joystick's center where input is ignored. Prevents drift and unwanted movement. Too large and the stick feels unresponsive. Too small and it feels twitchy.
  *"What dead zone value should I use for my twin-stick shooter? How does it differ for movement vs. aiming?"*

- **Aim Assist** — Subtle adjustments that help controller players aim accurately. Magnetism, slowdown near targets, or auto-rotation. Essential for controllers, controversial in PvP.
  *"Design aim assist for my third-person shooter that feels helpful for PvE but doesn't dominate in PvP crossplay."*

- **Haptic Feedback** — Vibration or tactile response from the controller that corresponds to in-game events. Adds a physical dimension to game feel.
  *"Design haptic feedback profiles for walking on different surfaces: grass, metal, gravel, and water."*

- **Analog vs. Digital** — Whether input is on/off (digital: keyboard) or variable (analog: joystick, trigger). Analog allows nuance like walk vs. run. Digital is precise but binary.
  *"My game was designed for analog sticks. How do I make keyboard controls feel good without analog input?"*

### Juice & Feedback

Making actions feel satisfying.

- **Juice** — The collection of effects that make an action feel impactful: screen shake, particles, sound, animation stretch. The polish that transforms functional into fun.
  *"Add juice to my block-breaking mechanic: what combination of screen shake, particles, sound, and animation will make it feel satisfying?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=juice+game+feel+effects+before+after)

- **Screen Shake** — Brief camera movement that conveys impact. Small shakes for hits, big shakes for explosions. Too much causes nausea. Too little feels lifeless.
  *"Implement screen shake with intensity scaling: light shake for sword hits, medium for explosions, heavy for boss attacks. Include a disable option."*

- **Hitstop** — A brief freeze (1-5 frames) when an attack connects. Creates a sense of weight and impact. Fighting games and action games rely on this heavily.
  *"Add 3-frame hitstop to melee attacks in my hack-and-slash. Should I freeze just the attacker, just the target, or both?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=hitstop+hit+freeze+frame+game+feel)

- **Particle Burst** — A spray of particles triggered by an event: impact sparks, dust clouds, magic sparkles. Communicates energy and reinforces what just happened.
  *"Design particle bursts for three damage types: fire (embers + smoke), ice (shards + frost), and lightning (sparks + flash)."*

- **Impact Frame** — A single frame of high-contrast color or flash at the moment of impact. White flash, black frame, or color shift. Tiny duration, massive effect.
  *"Add a 1-frame white flash on enemy hit and a 1-frame red flash when the player takes damage."*

- **Squash and Stretch** — Deforming a sprite or model to convey motion and weight. A ball squashes on landing, stretches while falling. Borrowed from traditional animation.
  *"Apply squash and stretch to my character's jump: stretch 20% on launch, squash 15% on landing. What easing curve should I use?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=squash+and+stretch+game+animation+sprite)

- **Easing** — The acceleration curve of an animation or movement. Linear motion looks robotic. Ease-in-out looks natural. The right easing makes everything feel alive.
  *"Replace linear interpolation with ease-out on my UI panel transitions. What easing function looks best for a snappy menu?"*

- **Anticipation** — A small preparatory motion before the main action. A character crouches before jumping, winds up before punching. Tells the player what's coming.
  *"Add anticipation frames to my character's attack animation: 3 frames of wind-up before the swing."*

- **Follow-through** — Motion that continues after the main action completes. A sword swing that arcs past the target, a character's hair settling after a stop. Sells the physics.
  *"Add follow-through to my dash ability: the character slides slightly and their cloak settles after the dash ends."*

- **Visual Weight** — How heavy or light something appears based on its visual treatment. Large, dark, slow objects feel heavy. Small, bright, fast objects feel light.
  *"Make my giant boss enemy feel heavy: slower animations, screen shake on footsteps, dust clouds, and a deep audio pitch."*

- **HUD** — Heads-up display: the persistent on-screen interface showing health, ammo, minimap, and other status info. The layer between the game world and the player's awareness.
  *"Design a minimal HUD for a survival game that shows health, stamina, and hunger without cluttering the screen. When should elements auto-hide?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=game+HUD+design+minimal+UI+examples)

- **Damage Numbers** — Floating numbers that appear when damage is dealt. Communicate effectiveness, enable build comparison, and add juice to combat. Optional but beloved.
  *"Implement damage numbers with color coding (white normal, yellow crit, red DoT) and size scaling based on damage magnitude."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=damage+numbers+floating+combat+text+game)

- **Cooldown Indicator** — A visual element showing when an ability will be available again. Radial wipes, graying out, countdown timers. Critical for ability-based games.
  *"Design cooldown indicators for a MOBA-style ability bar: radial sweep for long cooldowns, flash pulse when ready, and a numeric overlay for cooldowns over 10 seconds."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=cooldown+indicator+ability+UI+game+design)

### Combat & Encounter Design

The art of fighting.

- **Hitbox** — The invisible shape that represents where an attack can land. Does not need to match the visual exactly — the best hitboxes are slightly generous.
  *"Debug my sword attack hitbox: should it match the blade sprite exactly or extend slightly beyond it for better feel?"*
  [Visual reference](https://www.google.com/search?tbm=isch&q=hitbox+hurtbox+visualization+game+design)

- **Hurtbox** — The invisible shape that represents where a character can be hit. Usually matches the character's body. Can shrink during certain animations for strategic depth.
  *"Shrink the player's hurtbox during the dodge roll to make i-frames feel more visually intuitive."*

- **I-frames** — Invincibility frames: a brief period during an animation (usually a dodge or roll) where the character cannot be hit. The backbone of dodge-based combat.
  *"Give my dodge roll 8 i-frames out of a 20-frame animation. Where in the animation should the i-frames start?"*

- **Stagger** — A brief interruption to a character's action caused by taking a hit. Determines whether attacks can interrupt enemies and vice versa.
  *"Design a stagger system: light attacks stagger small enemies, heavy attacks stagger medium enemies, and nothing staggers bosses except a special move."*

- **Knockback** — Pushing a character backward when hit. Creates spacing, prevents stunlocking in melee, and communicates hit power.
  *"Implement knockback that scales with attack damage: light attacks nudge, heavy attacks launch, and charged attacks send enemies flying."*

- **Tells** — Visual or audio cues that signal an upcoming enemy action. A glowing hand before a fireball, a grunt before a charge. Tells make difficult combat fair.
  *"Design tells for a boss with 4 attacks: a quick slash (subtle tell), a sweep (medium tell), a grab (long tell), and an AOE (very long tell)."*
  [Visual reference](https://www.google.com/search?tbm=isch&q=boss+attack+tells+wind+up+animation+game)

- **Wind-up** — The preparatory animation before an attack. Longer wind-ups signal stronger attacks. Gives the player time to react. The counterpart to anticipation.
  *"Balance wind-up times for three enemy types: fast enemies (6 frames), standard (12 frames), heavy (24 frames)."*

- **Recovery Frames** — The period after an attack where the attacker is vulnerable and cannot act. Creates openings for counterplay. Longer recovery = more punishable.
  *"Design recovery frames for the player's combo: light attack (8 frames), heavy attack (16 frames), combo finisher (24 frames)."*

- **Aggro** — The system that determines which target an enemy attacks. Usually based on proximity, threat level, or most recent attacker. Critical for games with companions or multiplayer.
  *"Implement an aggro system for my party RPG: tanks generate high threat, healers generate medium threat, and DPS generates threat based on damage dealt."*

- **Encounter Design** — The art of composing individual combat scenarios: which enemies, how many, where they spawn, and what the arena looks like. The level design of fighting.
  *"Design three encounters for a cave dungeon: a skirmish (3 melee enemies), an ambush (ranged enemies on ledges), and a miniboss with 2 adds."*
