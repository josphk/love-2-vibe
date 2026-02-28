# Module 2: Platform Economics

**Part of:** [Game Monetization & Revenue Roadmap](game-monetization-learning-roadmap.md)
**Estimated study time:** 3-5 hours
**Prerequisites:** [Module 0: The Business of Indie Games](module-00-the-business-of-indie-games.md)

---

## Overview

Every platform you sell your game on is a business with its own incentives, and those incentives shape everything — what gets promoted, what gets buried, how money flows, and what behavior the platform rewards. If you don't understand the platform's business model, you can't make good decisions about your own.

This module takes apart the major game distribution platforms — Steam, itch.io, mobile stores, and console storefronts — and examines them not as neutral marketplaces but as businesses with goals that may or may not align with yours. You'll learn how their revenue splits work, how their discovery algorithms decide who gets seen, and what strategic implications each platform's incentives create for a small indie developer.

The short version: Steam is almost certainly your primary platform if you're making a PC game. Everything else is a secondary consideration until your Steam strategy is solid. But understanding *why* Steam dominates — and what the alternatives offer — helps you make platform decisions based on data rather than vibes.

For how platform dynamics affect your launch strategy and marketing plan, see the [Indie Game Marketing roadmap](../indie-marketing/indie-marketing-learning-roadmap.md). This module focuses on the economics — the money mechanics of each platform.

---

## Core Concepts

### 1. Steam — The 800-Pound Gorilla

Steam dominates PC game distribution with an estimated 75%+ market share. For most indie developers, Steam is not one platform among many — it's *the* platform, with everything else being supplementary.

**Why it matters:** Understanding Steam's economics isn't optional. It determines how you price, when you launch, how you market, and how you plan your revenue. The platform's mechanics are your operating environment.

**Key economics:**

| Factor | Detail |
|--------|--------|
| **Revenue split** | 70/30 (Valve takes 30%). Improves to 75/25 after $10M and 80/20 after $50M in revenue. For indie devs, it's 70/30. |
| **App deposit** | $100 per game (recoupable — returned after your game earns $1,000+). |
| **Payment schedule** | Net-30 from end of month. Revenue earned in March is paid in late April. |
| **Refund policy** | Full refund if played under 2 hours and purchased within 14 days. This impacts short games disproportionately. |
| **Regional pricing** | Steam provides recommended regional prices. Many developers accept them. Revenue per unit varies significantly by region. |
| **VAT handling** | Steam collects and remits VAT/GST for most countries. This is a massive administrative burden you don't have to deal with. |

**Examples:**
- **The 30% cut** is often complained about, but it includes: payment processing in 150+ countries, VAT handling, refund management, CDN distribution, community features (forums, reviews, workshop), discovery algorithms, and seasonal sales that drive traffic. No indie dev could replicate these services for 30% of revenue.
- **The refund policy** creates a structural incentive to build games longer than 2 hours. A 90-minute game will have a mechanically higher refund rate than a 10-hour game, even if the 90-minute game is better. This affects pricing strategy for short games — lower prices reduce the motivation to refund.
- **Regional pricing** means your $20 game might sell for $7 in Turkey, $10 in Brazil, and $14 in Russia. Accepting Steam's recommended regional prices maximizes your global audience but reduces your average revenue per unit. Rejecting them risks pricing out entire markets. Most devs accept the defaults.

**Common mistake:** Treating Steam's 30% cut as "too high" and choosing to sell primarily through your own website or itch.io to keep more revenue. The math rarely works. Steam's audience is so large and its discovery systems so effective that the 70% you keep on Steam typically yields more total revenue than the 90-100% you keep from a platform with 1% of the traffic. Optimize for total revenue, not margin percentage.

**Try this now:** If you have a Steamworks account, read through the payment FAQ and familiarize yourself with the financial reporting dashboard. If you don't, review the Steamworks "Getting Started" documentation and note the requirements for creating a developer account.

---

### 2. Steam's Discovery Algorithm — What Gets Seen

Steam's discovery system determines which games are shown to which players. It's the single biggest factor in a game's commercial success on the platform, and understanding how it works (to the extent that's possible from the outside) is essential.

**Why it matters:** You can't buy your way to the top of Steam's recommendations (not directly, at least). The algorithm surfaces games based on signals that you can influence through your development and marketing decisions. Understanding these signals lets you optimize for discovery rather than hoping for it.

**Key discovery signals:**

| Signal | What It Means | How to Influence It |
|--------|--------------|-------------------|
| **Wishlists** | Number of users who wishlist your game before and after launch | Pre-launch marketing, Coming Soon page quality, Next Fest demos |
| **Conversion rate** | Percentage of store page visitors who buy | Store page quality — capsule art, screenshots, trailer, description |
| **Engagement** | Player time, review activity, community engagement | Game quality, retention mechanics, community responsiveness |
| **Sales velocity** | How quickly you accumulate sales, especially at launch | Launch timing, marketing push, streamer/press coverage |
| **Tag relevance** | How well your game matches the genres/tags players browse | Accurate tagging, clear genre positioning on your store page |

**Examples:**
- **Wishlists are the pre-launch currency.** The commonly cited multiplier is that first-week revenue ≈ wishlists × $0.50–$1.50 (depending on price and conversion). A game with 20,000 wishlists at launch has dramatically different algorithmic prospects than one with 500. Wishlists signal to Steam that there's demand, which triggers more visibility, which generates more wishlists. It's a virtuous cycle — but you have to prime the pump.
- **Conversion rate** is why store page quality matters so much. Two games can get the same number of store page impressions, but the one with better capsule art, a more compelling trailer, and clearer screenshots will convert a higher percentage of visitors into buyers. Higher conversion = more algorithmic promotion = more impressions = more sales.
- **The "new release" visibility window** lasts roughly 2 weeks. During this period, your game gets boosted in discovery queues and personalized recommendations. The sales and engagement you generate during this window determine your long-term algorithmic placement. A strong launch compounds; a weak launch fades.

**Common mistake:** Launching before your wishlist count is high enough to generate algorithmic momentum. There's no magic number, but general guidance suggests 7,000–10,000 wishlists as a minimum for a meaningful launch on Steam. Below that, your launch spike may be too small to trigger the discovery feedback loop.

**Try this now:** If your game has a Coming Soon page, check your current wishlist count and calculate how long it took to accumulate. Extrapolate: at your current rate, how many wishlists will you have at your planned launch date? If the number is under 5,000, consider either delaying launch or significantly increasing your marketing effort.

---

### 3. itch.io — The Indie Sandbox

itch.io operates on a fundamentally different philosophy than Steam. It's a platform built by and for the indie community, with a focus on experimental games, game jams, and creator-friendly economics.

**Why it matters:** itch.io isn't a Steam competitor — it's a different tool for different purposes. Understanding what it's good at (and what it's not) lets you use it strategically alongside Steam rather than as a replacement.

**Key economics:**

| Factor | Detail |
|--------|--------|
| **Revenue split** | Creator-defined. You choose what percentage itch.io gets — including 0%. Default suggestion is 10%. |
| **Payout** | Direct to PayPal or Payoneer. Minimum $50 payout threshold. |
| **Pricing** | You set the price. Pay-what-you-want is supported and popular. Free games are the norm for jams. |
| **Fees** | Payment processing fees apply (PayPal/Stripe rates) on top of itch.io's share. |
| **Discovery** | Browse pages, tags, "Popular" and "New" feeds. Less algorithmic than Steam. |

**Examples:**
- **Game jam prototypes** on itch.io serve as concept validation and audience building. A well-received jam game with a "follow for updates on the full version" link is a free marketing tool. Many successful Steam launches started as itch.io jam games — Celeste began as a game jam prototype on itch.io.
- **Pay-what-you-want pricing** works surprisingly well for games with a built-in audience. Developers with a following can release itch.io-exclusive content at PWYW and earn meaningful revenue. For unknown developers, PWYW typically yields very little.
- **Asset packs and tools** sell well on itch.io. If you create reusable art, code, or design tools during your game's development, packaging them as assets can create a secondary revenue stream.

**Common mistake:** Treating itch.io as a primary revenue platform for a commercial game. The audience is smaller, the discovery is weaker, and the average revenue per game is dramatically lower than Steam. Use itch.io for jams, demos, free games, asset sales, and community building. Use Steam for commercial revenue.

**Try this now:** Browse itch.io's top-selling paid games for the past month. Note the prices, the production values, and the estimated sales numbers (itch.io shows download/purchase counts on some pages). Compare this to equivalent games on Steam. The delta illustrates why itch.io is a complement to Steam, not a substitute.

---

### 4. Mobile Platforms — The Expensive Arena

The iOS App Store and Google Play Store are technically open to indie developers, but the economic realities of mobile gaming make them hostile territory for small teams without marketing budgets.

**Why it matters:** Mobile is tempting because of the enormous install base — billions of devices. But install base is not addressable market. The mobile game economy is dominated by free-to-play games with massive user acquisition budgets. Understanding why helps you avoid a platform mismatch that could waste months or years.

**Key economics:**

| Factor | iOS App Store | Google Play Store |
|--------|--------------|------------------|
| **Revenue split** | 70/30 (85/15 for developers earning under $1M/year through the Small Business Program) | 70/30 (85/15 for first $1M in earnings) |
| **Developer fee** | $99/year | $25 one-time |
| **Payment processing** | Mandatory through Apple IAP | Mandatory through Google Play Billing (with some exceptions) |
| **Discovery** | Editorial curation + algorithmic | Algorithmic + editorial |
| **User acquisition cost** | $1–$5+ per install for paid acquisition | $0.50–$3+ per install for paid acquisition |

**Examples:**
- **Premium (paid) mobile games** are a dying category. The App Store's top-grossing charts are dominated by F2P games. A $5 paid game competes for attention against free games with million-dollar marketing budgets. The handful of premium mobile successes (Monument Valley, Alto's Adventure) benefit from exceptional production values and extensive press coverage — not organic App Store discovery.
- **User acquisition costs** make mobile math brutal for small devs. If it costs $2 to acquire a user and your game is free-to-play with a 3% conversion rate and $0.50 average revenue per paying user, you earn $0.015 per acquired user. You need to spend $133 in marketing to earn $1 in revenue. This is why mobile F2P requires massive scale.
- **Apple Arcade** offers a different model — a curated subscription service that pays developers based on engagement. It's invitation-only and the financial terms are under NDA, but it removes the user acquisition problem in exchange for giving up direct sales. Worth applying to if your game is a fit.

**Common mistake:** Porting your PC indie game to mobile and expecting meaningful revenue. The mobile audience has different expectations (touch-optimized UI, shorter sessions, F2P norms), and organic discovery is nearly non-existent. Unless your game is specifically designed for mobile or you have a marketing budget, mobile is a distraction.

**Try this now:** Search the App Store or Google Play for games similar to yours. Note the top results: what percentage are free-to-play? What percentage are paid? What are the download estimates for paid games in your genre? This gives you a realistic picture of mobile viability for your game type.

---

### 5. Console Platforms — The Second Stage

Nintendo eShop, PlayStation Store, and Xbox/Microsoft Store represent real revenue opportunities but come with barriers that make them a "second platform" decision for most indie developers.

**Why it matters:** Console audiences are different from PC audiences, and successfully launching on console requires understanding the platform-specific economics, requirements, and audience expectations. It's not just a port — it's a separate business decision.

**Key economics:**

| Factor | Nintendo eShop | PlayStation Store | Xbox/Microsoft Store |
|--------|---------------|------------------|---------------------|
| **Revenue split** | ~70/30 (not publicly confirmed) | ~70/30 | ~70/30 |
| **Dev kit cost** | Free (must apply to Nintendo Developer Portal) | Free (must apply to PlayStation Partners) | Free (must register for ID@Xbox) |
| **Certification** | Required (Nintendo Lotcheck) | Required (Sony QA) | Required (Microsoft certification) |
| **Age rating** | Required (IARC or ESRB/PEGI) | Required (IARC or regional rating bodies) | Required (IARC) |
| **Porting cost** | Varies ($5K–$50K+ depending on engine and complexity) | Lower if using Unity/Unreal (native support) | Often shared with PC (Windows/Xbox ecosystem) |

**Examples:**
- **Nintendo Switch** has been particularly strong for indie games. The audience actively seeks out indie content, the eShop browse experience favors discovery, and certain genres (roguelikes, platformers, cozy games) perform disproportionately well. However, the Switch's hardware limitations require optimization work, and porting costs can range from $5K to $50K+.
- **Xbox Game Pass** is a unique console opportunity. Microsoft pays developers for inclusion in Game Pass, providing guaranteed revenue regardless of how many subscribers play your game. The terms vary, but it can be a meaningful revenue source — especially for games that might struggle with direct sales.
- **PlayStation** has historically been harder for small indies to access, though the PlayStation Partners program has improved. The audience skews toward higher-production-value titles, and visibility on the PS Store is harder to achieve for small games.

**Common mistake:** Budgeting for a console port without factoring in certification, age rating, platform-specific QA, and the opportunity cost of time spent porting instead of making your next game. A console port that takes 3 months and earns $10K might have been better spent on 3 months of development on your next game.

**Try this now:** Research the developer program for one console platform you're interested in. Note: the application requirements, the dev kit process, the certification requirements, and the estimated timeline from "starting the port" to "game is live on the store." Compare the total cost (time + money) to your realistic revenue expectations for that platform.

---

### 6. Platform Strategy — Making the Decision

Choosing your platform isn't just about where you *can* sell — it's about where your effort generates the most return per hour invested.

**Why it matters:** Every platform you target costs time: porting, testing, store page creation, platform-specific marketing, customer support, and certification. Time spent on a secondary platform is time not spent on your primary platform or your next game. The opportunity cost matters.

**The decision framework:**

| Platform | Best For | Revenue Expectation | Effort Required |
|----------|---------|---------------------|----------------|
| **Steam** | Almost everyone making PC games | Primary revenue source | Moderate (store page, marketing, community) |
| **itch.io** | Jams, demos, free games, asset sales | Supplementary (small) | Low |
| **Mobile** | Games specifically designed for mobile with marketing budget | Highly variable (usually low without UA spend) | High (platform adaptation, UA, compliance) |
| **Nintendo Switch** | Games with proven PC success, especially in indie-friendly genres | Good secondary revenue | High (porting, certification) |
| **Xbox/PlayStation** | Games with strong PC sales looking to expand | Moderate secondary revenue | High (porting, certification) |

**Examples:**
- **The safest path for a solo indie dev** is: build for PC, launch on Steam, use itch.io for jams and demos. Only consider console ports after your Steam launch demonstrates market demand. Only consider mobile if your game was designed for it from the start.
- **Simultaneous multi-platform launches** are risky for small teams. Each platform demands attention at launch — customer support, bug fixes, store page optimization. Splitting your attention across Steam, Switch, and Xbox means doing a mediocre job on three platforms instead of a great job on one.
- **Epic Games Store** and **GOG** are sometimes viable but generally offer less discovery and lower volume than Steam for indie games. Epic occasionally offers exclusivity deals (guaranteed minimum revenue in exchange for timed exclusivity), which can be worth evaluating if offered.

**Common mistake:** Saying "I'll launch on every platform" without calculating the time and cost of each port. Each additional platform adds weeks or months of work. If your game only earns $3K on a secondary platform and the port took two months, your effective hourly rate for that port was terrible.

**Try this now:** List every platform you're currently planning to launch on. For each, write: estimated porting cost (in time and money), estimated first-year revenue (be honest), and the opportunity cost of the time spent. If any platform doesn't justify its cost, cut it from your initial plan and revisit after your primary platform launch.

---

## Case Studies

### Case Study 1: Hollow Knight — Platform Expansion Done Right

Team Cherry launched Hollow Knight on Steam in February 2017. The game was a hit, eventually selling over a million copies on PC. Only after establishing strong PC sales did they port to Nintendo Switch in June 2018 — sixteen months after the PC launch.

The Switch version was also a major success, reportedly selling over a million copies on the platform. But the key strategic insight is *sequencing*: they didn't split their tiny team (3 people) across multiple platforms at launch. They focused entirely on the PC version, iterated on it with free content updates (which kept the community engaged and drove new PC sales), and then used the proven market demand to justify the investment in a Switch port.

If they'd tried to launch simultaneously on PC and Switch, the additional workload could have delayed the launch, split their QA attention, and diluted their marketing focus. By sequencing, they got the full benefit of a focused PC launch *and* the full benefit of a focused Switch launch — effectively getting two launch windows for one game.

---

### Case Study 2: The Mobile Trap — A Cautionary Tale

A solo developer spent two years building a puzzle game designed for both PC and mobile simultaneously. They budgeted their time 50/50 between platforms. The PC version launched on Steam with a modest but reasonable store page. The mobile version launched on iOS and Google Play with minimal marketing.

Results after one year:
- **Steam:** $18,000 gross revenue (about 2,000 copies at $9.99, minus some sale revenue)
- **iOS App Store:** $400 gross revenue (about 80 paid downloads at $4.99)
- **Google Play:** $200 gross revenue (about 40 paid downloads at $4.99)

The mobile ports consumed approximately 50% of total development time (touch controls, UI adaptation, platform compliance, separate store page assets) and generated about 3% of total revenue. If that time had been spent on PC-specific improvements — better store page, more content, more marketing — the Steam revenue would likely have been significantly higher.

The lesson: mobile is not a "free" additional platform. It has real costs, and for most indie games, those costs dramatically exceed the revenue.

---

## Common Pitfalls

- **Optimizing for revenue split instead of total revenue.** Keeping 90% of $1,000 from itch.io is worse than keeping 70% of $50,000 from Steam. Go where the audience is.

- **Launching on too many platforms simultaneously.** Each platform demands attention at launch. A great launch on one platform beats a mediocre launch on three.

- **Ignoring Steam's discovery mechanics.** The algorithm rewards specific signals (wishlists, conversion, engagement). Not understanding these signals is like opening a retail store without understanding foot traffic.

- **Treating mobile as "easy additional revenue."** Mobile gaming economics are hostile to small developers. Unless your game is specifically designed for mobile and you have a marketing budget, avoid it.

- **Porting too early.** Port to secondary platforms after your primary platform launch proves there's demand — not before. Premature porting is premature optimization for revenue that may not exist.

- **Not reading platform agreements.** Each platform has specific terms about revenue splits, payment schedules, content requirements, and dispute resolution. These directly affect your business.

---

## Exercises

### Exercise 1: Platform Competitive Analysis (Research)

**Time:** 45-60 minutes
**Materials:** Steam, itch.io, App Store (or Google Play), spreadsheet

Pick three indie games in your genre that launched in the last two years. For each game, research:

1. Which platforms it's available on
2. Its price on each platform
3. Its estimated revenue on each platform (VG Insights for Steam, estimate for others)
4. Its review count / rating on each platform
5. How many months after the initial launch each subsequent platform was added

Write a short analysis: which platform drives the majority of revenue for each game? Is there a pattern? What does this tell you about platform strategy for your genre?

---

### Exercise 2: Your Platform Revenue Model (Planning)

**Time:** 30-45 minutes
**Materials:** Spreadsheet

Build a simple revenue model for your game across platforms:

| Platform | Porting Cost ($) | Porting Time (months) | Year 1 Revenue (pessimistic) | Year 1 Revenue (realistic) | Year 1 Revenue (optimistic) |
|----------|------------------|-----------------------|------------------------------|---------------------------|----------------------------|
| Steam | | | | | |
| itch.io | | | | | |
| Switch | | | | | |
| Mobile | | | | | |

Fill in the table with honest estimates. For each platform, calculate: revenue minus porting cost. If any platform is negative in the realistic scenario, it shouldn't be in your launch plan.

---

### Exercise 3: Steam Store Page Audit (Applied)

**Time:** 30-45 minutes
**Materials:** Steam, your game's store page (or a comparable game's page)

If you have a Coming Soon page, audit it against the discovery signals discussed in this module. If you don't have one yet, pick a game in your genre and audit theirs.

For each discovery signal, rate 1-5:
1. **Capsule art quality** — Does it stand out in a grid of thumbnails?
2. **Screenshot effectiveness** — Do they show gameplay, not menus?
3. **Trailer quality** — Does it hook in the first 5 seconds?
4. **Description clarity** — Can someone understand the game in 10 seconds?
5. **Tag accuracy** — Do the tags match what the game actually is?

For any rating below 4, write a specific improvement you'd make. These improvements directly affect your conversion rate, which directly affects your algorithmic visibility, which directly affects your revenue.

---

## Recommended Reading & Resources

### Essential (Do These)

| Resource | Author/Source | Type | Why |
|----------|--------------|------|-----|
| Steamworks — Store Presence | Valve | Documentation | Official documentation on how your game appears on Steam. The foundation of Steam platform strategy. |
| itch.io — Creator Documentation | itch.io | Documentation | Everything about selling on itch.io. Quick read, useful for supplementary strategy. |
| SteamDB — Sales Tracker | SteamDB | Tool | Real data on Steam sales, price history, player counts, and trends. Essential competitive research. |

### Go Deeper (If You're Hooked)

| Resource | Author/Source | Type | Why |
|----------|--------------|------|-----|
| "How Steam's Algorithm Works" | Chris Zukowski | Blog post | Best external analysis of Steam's discovery system. Practical and data-driven. |
| Steamworks — Discovery Queue | Valve | Documentation | How Steam decides which games to show users. Understanding the algorithm from the inside. |
| Nintendo Developer Portal | Nintendo | Documentation | Requirements and process for publishing on Nintendo platforms. Read before committing to a Switch port. |
| ID@Xbox | Microsoft | Documentation | Xbox's indie developer program. Streamlined process for getting on Xbox and PC Game Pass. |
| "The State of Mobile Gaming" (annual reports) | data.ai (formerly App Annie) | Report | Annual data on mobile gaming economics, user acquisition costs, and market trends. Sobering reading. |

---

## Key Takeaways

- **Steam is the primary revenue platform for most PC indie games. Optimize your Steam strategy before investing in secondary platforms.**

- **Steam's discovery algorithm rewards wishlists, conversion rate, and engagement. These are signals you can directly influence through marketing, store page quality, and game design.**

- **itch.io is a complement to Steam — excellent for jams, demos, free games, and community building, but not a substitute for commercial revenue.**

- **Mobile gaming economics are hostile to small developers. Don't target mobile unless your game is specifically designed for it and you have a user acquisition budget.**

- **Console ports should follow proven PC success, not precede it. Sequence your platform launches to maximize focus and minimize wasted effort.**

---

## What's Next?

You understand where the money comes from (platforms) and how the discovery systems work. Now you need to figure out the most critical revenue decision you'll make: how much to charge.

**[Module 3: Pricing Psychology & Strategy](module-03-pricing-psychology-strategy.md)** covers price anchoring, genre norms, the $10 psychological threshold, and how to set a launch price that communicates value and maximizes lifetime revenue.

Also relevant:
- **[Module 4: The Premium Model](module-04-the-premium-model.md)** — How to execute the pay-once model from Coming Soon page through post-launch optimization.
- **[Module 8: Sales, Bundles & Catalog Strategy](module-08-sales-bundles-catalog-strategy.md)** — How to use Steam's sale events and bundles to maximize long-tail revenue (builds directly on platform economics).

[Back to Game Monetization & Revenue Roadmap](game-monetization-learning-roadmap.md)
