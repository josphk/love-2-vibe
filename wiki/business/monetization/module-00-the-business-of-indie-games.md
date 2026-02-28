# Module 0: The Business of Indie Games

**Part of:** [Game Monetization & Revenue Roadmap](game-monetization-learning-roadmap.md)
**Estimated study time:** 2-3 hours
**Prerequisites:** None

---

## Overview

Here's the number nobody wants to hear: the median indie game on Steam earns somewhere between a few hundred and a few thousand dollars. That's *median* — half of all games make less. The average is higher, but that's because a handful of breakout hits distort the mean upward. You are not planning your life around being a statistical outlier.

This module is the cold shower before the warm bath. Before you learn about pricing strategy, platform economics, DLC models, and financial planning, you need to understand the landscape you're operating in. Not the curated success stories on Twitter. Not the GDC talks where someone describes their $2M launch. The *actual* distribution of outcomes for indie games — and what separates the games that make money from the ones that don't.

This isn't meant to discourage you. It's meant to make you dangerous. The developers who succeed financially aren't the ones with the best ideas or the most talent. They're the ones who understood the business early enough to make good decisions — about scope, about pricing, about marketing timing, about which platforms to target and which to ignore. Every module in this roadmap builds on the foundation you're laying here.

If you're building games as a hobby and don't care about revenue, that's completely valid — but you should still understand this module. Knowing how the money works changes how you think about scope, about audience, and about what "done" means. Even a hobby project benefits from understanding why some games find an audience and others don't.

---

## Core Concepts

### 1. Survivorship Bias — The Biggest Threat to Good Decisions

**Survivorship bias** is the cognitive error of drawing conclusions from visible successes while ignoring the invisible failures. In gamedev, it's epidemic. You see the solo dev who made $500K in a week. You don't see the 5,000 solo devs who launched the same month to twelve wishlists and zero press coverage.

**Why it matters:** Every financial decision you make should be based on the *base rate* — the typical outcome — not the highlight reel. If you plan your finances around being the next Stardew Valley, you're gambling. If you plan around being the median indie game and build upward from there, you're engineering.

**Examples:**
- **Hollow Knight** sold millions of copies and is held up as proof that a small team can make a massive hit. What's rarely mentioned: Team Cherry had years of savings, lived in one of the cheaper cities in Australia, and the game took 3.5 years to develop — during which they had essentially no income. They also had significant game jam exposure and early community traction before committing full-time. The success was real, but the survivable risk conditions were unusual.
- **Among Us** was released in 2018 to almost no audience. It became a phenomenon in 2020 due to Twitch streamers — two years after launch. The developers at InnerSloth had other income sources during those two years. If they'd been depending on Among Us revenue to eat, the game would have been abandoned long before it went viral.
- **Vampire Survivors** cost essentially nothing to make, was built by a solo dev as a side project, and became one of the biggest indie hits of its year. It's a real success story — but it's also a game that was built with near-zero financial risk. The developer didn't quit his job to make it. He made it *and then* quit his job after it was already earning.

**Common mistake:** Treating outlier successes as evidence that "if the game is good enough, the money will follow." Quality is necessary but nowhere near sufficient. Discovery, timing, marketing, genre fit, and platform dynamics matter at least as much. Plenty of excellent games earn almost nothing because nobody knows they exist.

**Try this now:** Go to Steam and browse the "New Releases" tab for any genre you like. Pick 10 games at random — not featured, not recommended, just 10 games from the list. Check their review counts. Most will have fewer than 50 reviews, many fewer than 10. That's the base rate. That's what "launching a game on Steam" usually looks like.

---

### 2. Revenue Tiers — Knowing the Landscape

Indie game revenue isn't a smooth distribution. It clusters into rough tiers, and knowing which tier your game is likely to land in helps you plan accordingly.

**Why it matters:** If you price your game at $15 and expect to sell 50,000 copies in the first year, you're targeting a "hit" outcome. If your marketing plan, genre selection, and audience-building don't support that target, your financial plan is fiction. Knowing the tiers lets you build plans that are calibrated to reality.

**The tiers (rough, Steam-focused):**

| Tier | First-Year Gross Revenue | What It Looks Like |
|------|--------------------------|-------------------|
| **The Invisible** | $0 – $1,000 | Fewer than 10 reviews. No press coverage. No pre-launch marketing. This is where most games land. |
| **The Modest** | $1,000 – $10,000 | 10–100 reviews. Some niche community engagement. Enough to cover basic tooling costs but not living expenses. |
| **The Viable** | $10,000 – $50,000 | 100–500 reviews. Solid niche appeal, decent launch marketing, good store page. Might cover a few months of living expenses. |
| **The Successful** | $50,000 – $200,000 | 500–2,000 reviews. Strong genre fit, effective marketing, good launch timing. Could fund a year of development at modest living. |
| **The Hit** | $200,000 – $2,000,000 | 2,000–10,000+ reviews. Significant pre-launch buzz, press coverage, streamer attention. Career-changing money for a solo dev. |
| **The Mega-Hit** | $2,000,000+ | 10,000+ reviews. Cultural moment. You know these games by name. Do not plan for this. |

**Examples:**
- A **puzzle game** by a first-time developer with no social media presence and no marketing plan will almost certainly land in the Invisible or Modest tier — regardless of how clever the puzzles are. The game's quality is not the bottleneck; visibility is.
- A **roguelike** by a developer with 5,000 Twitter followers, a devlog community on itch.io, a polished demo, and a 6-month Coming Soon page might reasonably target the Viable tier and hope for Successful. The pre-launch work shifts the probability distribution upward.
- **Balatro** is a mega-hit — a solo-developed poker-roguelike that crossed $1M in revenue within 24 hours of launch. Extraordinary, and worth studying, but not worth modeling your financial plan around.

**Common mistake:** Planning your finances around the "Successful" tier without having the marketing infrastructure, genre fit, and pre-launch audience to support it. Most devs who plan for $100K in revenue and get $3K aren't unlucky — they didn't do the work that the $100K tier requires.

**Try this now:** Using VG Insights or SteamDB, look up 5 indie games in your genre that launched in the past year. Estimate which tier each one landed in based on review count and price. Now be honest: which tier does your current project most closely resemble in terms of marketing effort, audience size, and production quality?

---

### 3. Gross vs. Net Revenue — The Money You Actually Keep

The number on your Steam dashboard is not the number in your bank account. The gap between gross revenue and take-home pay is larger than most developers expect.

**Why it matters:** If your game grosses $50,000, you might take home $25,000–$30,000. That's a huge difference when you're planning whether you can afford to go full-time. Every financial projection in this roadmap needs to account for the gap between gross and net.

**The deductions stack up:**

| Deduction | Percentage | Cumulative |
|-----------|-----------|------------|
| **Steam's cut** | 30% | You keep 70% |
| **Refunds** | ~5-10% of sales | You keep ~63-67% |
| **Regional pricing discounts** | Varies (10-50% lower in some regions) | Effectively reduces average price |
| **Income tax** | 15-35% depending on country/bracket | You keep ~45-55% of gross |
| **Self-employment tax** (if applicable) | ~15% in the US | Further reduces take-home |

**Examples:**
- A game that grosses **$100,000** on Steam might yield roughly $70,000 after Steam's cut, $63,000 after refunds, and then $35,000–$45,000 after taxes depending on your jurisdiction and structure. That's your actual take-home. If the game took two years to make, that's $17,500–$22,500 per year — below minimum wage in many countries.
- **Regional pricing** means a $20 game might sell for $7 in some markets. If 30% of your sales come from lower-priced regions, your effective average selling price might be $14, not $20. This matters for revenue projections.
- **Refunds on Steam** run around 5-10% for most games, but can spike higher for short games (under 2 hours of content) since Steam's refund window is based on playtime. A 90-minute game has a structurally higher refund rate than a 40-hour game.

**Common mistake:** Quoting gross revenue when evaluating whether indie dev is financially viable. "$50K in the first year" sounds livable until you realize you're taking home half that. Always think in net terms.

**Try this now:** Calculate your personal "ramen profitable" number. Add up your monthly expenses (rent, food, insurance, tools, subscriptions). Multiply by 12 for annual cost. Then multiply by 2 to account for Steam's cut and taxes. That's roughly how much your game needs to gross annually for you to go full-time indie. Write this number down — you'll reference it throughout this roadmap.

---

### 4. The Long Tail — How Revenue Decays Over Time

Most game revenue is front-loaded. The first week is your biggest spike. The first month is your biggest month. After that, revenue declines — sometimes gradually, sometimes off a cliff.

**Why it matters:** If you're planning to "let the game build an audience over time," you're fighting gravity. Organic Steam discovery favors new releases. Press coverage favors new releases. Streamer interest favors new releases. The long tail exists, but it's thin, and most of the revenue in the tail comes from sale events, not organic full-price purchases.

**The typical revenue curve:**

```
Revenue
│
│█████                          ← Launch week (biggest spike)
│███                            ← Month 1 (rapid decline)
│██                             ← Months 2-3
│█   █    █      █         █    ← Months 4-12 (sale spikes only)
│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ← Baseline (near zero between sales)
└────────────────────────────── Time
```

**Examples:**
- **Slay the Spire** is an exception to the front-loaded rule. It launched in Early Access, built audience gradually through word-of-mouth and streamer coverage, and its full launch was bigger than its Early Access launch. But this was enabled by a game design that's inherently streamable (roguelike with visible decision-making), a long Early Access period with consistent updates, and a genre that was exploding in popularity. These conditions are unusual.
- Most premium indie games see **50-70% of their first-year revenue in the first month**, with the rest distributed across sale events. A game that grosses $30K in year one might earn $15K–$20K in month one and the remaining $10K–$15K across the other eleven months, primarily during Steam's seasonal sales.
- **Updates and content patches** can create secondary spikes, but they're almost always smaller than the launch spike. A major update might bring in 10-20% of launch-week revenue for a few days.

**Common mistake:** Delaying marketing effort until after launch because "the game will sell itself." By the time you realize the game isn't selling itself, you've already missed your highest-visibility window. Pre-launch marketing isn't optional — it's what determines the size of your launch spike, and the launch spike is most of your revenue.

**Try this now:** Go to SteamDB and look at the player count chart for any indie game you like. Notice how it peaks at launch and then drops. Find the sale event spikes. Estimate what percentage of total playtime (and by proxy, revenue) came from the first month versus the rest of the first year.

---

### 5. What Separates Games That Make Money

Games that reach the Viable tier and above tend to share observable patterns. None of these guarantee success, but their absence almost guarantees failure.

**Why it matters:** These patterns are actionable. You can't control whether your game goes viral, but you can control whether you have a Coming Soon page up six months before launch. Understanding these patterns turns "I hope my game sells" into "I'm doing the things that correlated games that sold have done."

**The patterns:**

1. **Pre-launch visibility work.** Games that sell well almost always had wishlists accumulating for months before launch. Coming Soon page live early, demo in a Next Fest, devlog presence, community engagement. The launch doesn't create the audience — it activates an audience that was already building.

2. **Genre-audience fit.** The game serves an identifiable audience that already buys games in that space. "Everyone will like it" is a red flag. "Fans of Slay the Spire who want more narrative" is a targeting statement you can act on.

3. **Store page quality.** The capsule art, screenshots, trailer, and description look professional. This doesn't mean expensive — it means the developer understood that the store page is a sales tool and invested time in it. A great game with a terrible store page will underperform a mediocre game with a great store page.

4. **Launch timing.** The game didn't launch into a crowded week, near a major Steam sale, or on the same day as a AAA release in the same genre. Timing is not destiny, but bad timing is sabotage.

5. **Scope discipline.** The game shipped. Scope creep is the #1 killer of indie projects. Games that make money are games that exist. A 90% finished masterpiece earns exactly $0.

**Examples:**
- **Celeste** had a game jam prototype that built early interest, a clear genre identity (precision platformer), gorgeous store page materials, and a launch that capitalized on audience anticipation. The game's quality was exceptional — but the business execution was *also* exceptional.
- **Unpacking** is a niche concept — you unpack boxes in rooms. It succeeded because the developer identified a specific audience (cozy/narrative game fans), built a store page that communicated the experience perfectly, and timed the marketing around strong trailer moments that went viral.
- **Many excellent games** fail commercially because they skipped steps 1-4. A game that launches with 200 wishlists is dead on arrival regardless of its quality. The first week's sales won't generate enough algorithmic momentum to reach new audiences.

**Common mistake:** Believing that quality alone is sufficient. Quality is the table stakes — it gets you in the game. Marketing, positioning, timing, and business execution determine whether you win.

**Try this now:** Look at your current project (or your next planned project) and honestly assess: do you have a Coming Soon page live? Do you have wishlists accumulating? Can you name your target audience in one sentence? Is your store page competitive with similar games in your genre? For every "no," you've identified work that matters more than whatever feature you're currently building.

---

### 6. The Emotional Economics of Indie Dev

Money and creative work have a complicated relationship. Understanding the psychological traps of indie game business is as important as understanding the financial ones.

**Why it matters:** Developers make bad business decisions because of emotional reasoning — underpricing out of imposter syndrome, overscoping because cutting features feels like failure, avoiding financial planning because the numbers might be scary. Naming these patterns makes them easier to resist.

**Examples:**
- **Imposter syndrome pricing:** "Nobody would pay $20 for something I made." This is an emotional response, not a market analysis. If comparable games in your genre sell for $20, your game should probably be priced similarly. The market doesn't care about your self-doubt — it cares about perceived value relative to alternatives.
- **Sunk cost continuation:** "I've spent three years on this, I can't cut the crafting system now." Yes, you can. The three years are gone regardless. If the crafting system isn't making the game better and is preventing you from shipping, it's costing you *future* money on top of past time. Cut it.
- **Financial avoidance:** "I don't want to think about money, I just want to make games." Understandable, but the money will think about you whether you think about it or not. Rent is due every month. Not having a financial plan doesn't eliminate financial reality — it just means you'll face it unprepared.

**Common mistake:** Treating financial planning as "selling out" or as contrary to creative integrity. Knowing your market, pricing appropriately, and building an audience are not compromises — they're skills that make it possible to keep making games. The most creatively free developers are the ones who can afford to keep doing it.

**Try this now:** Write down three financial assumptions you're currently making about your game project. These might be things like "I'll sell at least X copies" or "I can finish it in Y months" or "I don't need marketing because the game is good." For each assumption, ask: what evidence do I have for this? If the answer is "none" or "vibes," you've identified a risk that needs investigation.

---

## Case Studies

### Case Study 1: Stardew Valley — The Outlier Everyone Cites

Stardew Valley is the most-cited indie success story, and for good reason: one person made a game that sold over 30 million copies. But using it as a planning template is dangerous without understanding the full context.

Eric Barone (ConcernedApe) worked on Stardew Valley for roughly 4.5 years before release. During that time, he was supported by his partner's income and lived in a low-cost area. He had no dependents. He was filling a specific market gap — Harvest Moon-style farming games didn't exist on PC in any modern form. The genre was underserved, and he was essentially the only serious competitor.

His marketing was also better than people realize. He posted consistently on fan forums for the genre. He built a community on the Stardew Valley subreddit and his own forums before launch. By the time the game released, there were thousands of people waiting for it.

The lessons from Stardew Valley are not "work hard for five years and you'll be rich." The lessons are:
- **Fill an underserved niche.** Barone identified a market gap and filled it before anyone else did.
- **Build your financial runway before you need it.** He had support that let him work without revenue for years.
- **Community building is pre-launch marketing.** He didn't launch into silence — he launched into an audience.
- **Scope discipline matters.** Despite being one person, he shipped a complete, polished game. He didn't add multiplayer until years later.

Using Stardew Valley as your revenue model is like using a lottery winner as your retirement plan. Study the methods; don't assume the magnitude.

---

### Case Study 2: The Invisible Majority — Games That Launch to Silence

For every Stardew Valley, there are thousands of games that launch to essentially zero audience. Understanding *why* is more instructive than studying successes.

A typical invisible launch looks like this: A developer spends 1-2 years building a game. They don't create a Coming Soon page until the game is nearly finished. They don't build a social media presence. They don't participate in Next Fest. They put the game up on Steam, tell their friends, post on Reddit once, and wait.

The result: 5-20 wishlists at launch. First-week sales of $50-$200. Steam's algorithm sees low conversion and doesn't surface the game to new audiences. The discovery loop never kicks in. The game earns a few hundred dollars over its lifetime and the developer is confused because "the game is actually good."

The game might *be* good. That's not the point. The failure mode is almost never quality — it's visibility. The game was invisible because:
- No Coming Soon page accumulating wishlists for months
- No demo in Next Fest generating interest
- No community engagement building anticipation
- No press or streamer outreach creating coverage
- No store page optimization making the game look appealing to browsers

Each of these is fixable. None of them require spending money. All of them require spending time and effort *before* launch, on activities that don't feel like "making the game." That's the uncomfortable truth of indie game business: the work that makes the game successful is largely separate from the work that makes the game exist.

---

## Common Pitfalls

- **Mistaking gross revenue for take-home pay.** Steam's cut, refunds, regional pricing, and taxes mean you keep roughly 50-60% of gross revenue. Always project in net terms.

- **Using success stories as planning baselines.** The games you've heard of are, by definition, outliers. Plan around the median, not the mean. Hope for the best, plan for the worst.

- **Ignoring the pre-launch period.** The months before launch are when your revenue potential is determined. Marketing, wishlists, community building, and store page quality are not post-launch activities — they're pre-launch investments.

- **Confusing "build it and they will come" with a marketing strategy.** They won't come. Nobody knows your game exists unless you tell them, and the telling needs to start months before launch.

- **Avoiding financial planning because the numbers are scary.** The numbers exist whether you look at them or not. A scary number you can plan around is infinitely better than an unknown number you can't.

- **Comparing your first game to someone else's fifth game.** The developer posting $100K launch revenue on Twitter has probably shipped four games, built an audience over five years, and had three commercial failures before the hit. Your first game's financial goal is to break even and teach you the business.

---

## Exercises

### Exercise 1: The Base Rate Reality Check (Research)

**Time:** 30-45 minutes
**Materials:** Steam, SteamDB or VG Insights, a spreadsheet

Go to Steam and pick a genre you're interested in making games for. Find 20 games in that genre that launched in the last 12 months. For each game, record:

1. Title
2. Price
3. Review count
4. Estimated revenue tier (using the tier table from this module)
5. Whether they had a demo before launch
6. How many months their Coming Soon page was active before launch (check SteamDB for the "added to Steam" date)

Calculate what percentage of the 20 games landed in each tier. This is the base rate for your genre. Write one paragraph about what this tells you about your own project's realistic revenue expectations.

---

### Exercise 2: Your Ramen Profitable Number (Financial)

**Time:** 20-30 minutes
**Materials:** Calculator or spreadsheet, your real financial information

Calculate your personal "ramen profitable" number — the minimum your game needs to gross annually for you to go full-time:

1. Monthly expenses: rent, food, insurance, tools, subscriptions, transportation, debt payments
2. Annual expenses = monthly × 12
3. Add 20% buffer for unexpected costs
4. Multiply by 2 (to account for Steam's cut, taxes, and self-employment costs)
5. That's your annual gross revenue target

Now compare this number to the tier table. Which tier does your target fall in? What percentage of indie games in your genre reach that tier?

**Stretch variant:** Calculate the number of copies you'd need to sell at your planned price point to hit this target. Then estimate the number of wishlists you'd need to generate those sales (using the rough multiplier of first-year revenue ≈ wishlists × $1–$3). Is that wishlist number realistic for your marketing plan?

---

### Exercise 3: The Survivorship Bias Audit (Analysis)

**Time:** 45-60 minutes
**Materials:** Your favorite gamedev Twitter/Reddit follows, a notebook

Go through your gamedev social media feeds and find 5 success stories that have influenced your thinking about indie game business (revenue milestones, launch celebrations, "I quit my job" posts). For each one, research:

1. How many years the developer had been making games before this success
2. Whether they had previous games or industry experience
3. What their financial situation was during development (did they have a partner's income? savings? a day job?)
4. What their marketing and community building looked like pre-launch
5. Whether their genre was trending or underserved at the time

Write a one-paragraph "corrected narrative" for each success story that includes the context usually omitted from the highlight reel. How does this change your own planning assumptions?

---

## Recommended Reading & Resources

### Essential (Do These)

| Resource | Author/Source | Type | Why |
|----------|--------------|------|-----|
| VG Insights — Steam Revenue Analysis | VG Insights | Data/Article | Real data on actual indie game revenues and trends. Destroys assumptions with numbers. |
| "What is the Average Revenue of Indie Games?" | Chris Zukowski | Blog post (15 min) | The most data-driven, honest look at what indie games actually earn. Required reading before any financial planning. |
| SteamDB — Sales Tracker | SteamDB | Tool | Real data on how Steam sales work, price history, player counts. Your reality-checking tool. |

### Go Deeper (If You're Hooked)

| Resource | Author/Source | Type | Why |
|----------|--------------|------|-----|
| *Blood, Sweat, and Pixels* | Jason Schreier | Book | Behind-the-scenes stories of game development, including the financial pressures. Entertaining and educational. |
| Game Developer — The State of Indie | Game Developer | Article series | Annual industry perspective on indie sustainability and market trends. |
| "How Many Wishlists Do You Need?" | Chris Zukowski | Blog post (10 min) | Data on the relationship between wishlists and revenue. Turns wishlist count into revenue projections. |
| Steam Revenue Calculator | steam-revenue-calculator.com | Tool | Rough revenue estimates based on review count. Useful for competitive analysis. |
| r/gamedev postmortems | Reddit | Community | Real developers sharing real numbers — successes and failures. Filter for posts with actual financial data. |

---

## Key Takeaways

- **The median indie game on Steam earns a few hundred to a few thousand dollars. Plan around the median, not the outliers.**

- **Gross revenue and take-home pay are dramatically different. You keep roughly 50-60% of gross after platform cuts, refunds, and taxes.**

- **Revenue is front-loaded. The first month is your biggest month, and most subsequent revenue comes from sale events, not organic purchases.**

- **Games that make money share patterns: pre-launch visibility work, genre-audience fit, store page quality, launch timing, and scope discipline. None of these are about game quality alone.**

- **Survivorship bias is the biggest threat to good financial decisions. Base your plans on the typical outcome, not the highlight reel.**

---

## What's Next?

Now that you understand the financial landscape of indie games, you need the legal and financial infrastructure to operate within it.

**[Module 1: Legal & Business Foundations](module-01-legal-business-foundations.md)** covers business entity setup, tax obligations, contracts, and the practical infrastructure you need before you earn your first dollar.

Also critical as you progress:
- **[Module 2: Platform Economics](module-02-platform-economics.md)** — How Steam, itch.io, and other platforms work as businesses, and what that means for your revenue.
- **[Module 3: Pricing Psychology & Strategy](module-03-pricing-psychology-strategy.md)** — How to price your game so it communicates value and maximizes lifetime revenue.

[Back to Game Monetization & Revenue Roadmap](game-monetization-learning-roadmap.md)
