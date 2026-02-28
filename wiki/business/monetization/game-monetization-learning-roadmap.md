# Game Monetization & Revenue

**For:** Solo dev or small team · Wants to actually make money · ADHD-friendly · Steam-focused, multi-platform aware

---

## How This Roadmap Works

Most gamedev learning resources treat money like a dirty word. They'll teach you shaders, physics, and narrative design — but when it comes to actually paying rent with your game, you get vague platitudes about "finding your audience."

This roadmap fixes that. It's a structured path through the real economics of indie games: how money flows, where it disappears, and what levers you can actually pull. We're not teaching you to become a mobile whale-hunter or a crypto grifter. We're teaching you to ship a game and get paid for it — honestly, sustainably, and without losing your mind.

**The philosophy is simple:** understand the money before you need the money.

You don't have to go full-time indie to benefit from this. Even if games stay a side project forever, knowing how pricing, platform economics, and revenue work will make you a better decision-maker at every stage.

Each module below is a summary. Click the "Deep dive" link on any module to open the full study guide with detailed explanations, case studies, and additional exercises.

> **Note:** Marketing, community building, and launch strategy have their own dedicated roadmap at [Indie Game Marketing](../indie-marketing/indie-marketing-learning-roadmap.md). This roadmap focuses on the *money mechanics* — pricing, platforms, revenue models, and financial planning. The two roadmaps are designed to be studied together.

**Estimated total time:** 33–52 hours across all modules

### Dependency Graph

```
Module 0 ── The Business of Indie Games (start here)
   │
   ├──→ Module 1 ── Legal & Business Foundations
   │
   ├──→ Module 2 ── Platform Economics
   │       │
   │       └──→ Module 3 ── Pricing Psychology & Strategy
   │               │
   │               ├──→ Module 4 ── The Premium Model
   │               │       │
   │               │       └──→ Module 5 ── DLC & Post-Launch Revenue
   │               │
   │               └──→ Module 6 ── Free-to-Play & Live Service
   │
   ├──→ Module 7 ── Crowdfunding & Community Funding (independent)
   │
   └──→ Module 9 ── Revenue Diversification (independent)

   Module 4 ──→ Module 8 ── Sales, Bundles & Catalog Strategy
                                │
                                └──→ Module 10 ── Financial Planning & The Long Game
                                        ↑
   Module 9 ───────────────────────────┘
```

Start with Module 0 — it's the reality check. Modules 1, 7, and 9 can be done anytime after Module 0. The main "premium revenue track" runs 2 → 3 → 4 → 5. Module 10 ties everything together.

---

## Module 0: The Business of Indie Games

> **Deep dive:** [Full study guide](module-00-the-business-of-indie-games.md)

**Goal:** Understand the real financial landscape of indie games — who makes money, how much, and why most don't — so you can make informed decisions instead of operating on vibes.

Let's start with the number everyone avoids: the median revenue for an indie game on Steam is very low. Depending on the dataset and year, estimates range from a few hundred to a few thousand dollars. That's *median* — meaning half of all games make less than that. The average is higher because a handful of breakout hits pull it up, but you're not planning your life around being an outlier.

This isn't meant to be depressing. It's meant to be *clarifying*. The games that do make money tend to share patterns: they solve a real audience need, they're visible before launch, and the developer understood the business side early enough to make good decisions. That's what this entire roadmap teaches.

**Key concepts:**

- **Survivorship bias** is the biggest enemy of good decision-making in gamedev. You see the success stories on Twitter — the solo dev who made $500K in a week, the tiny team whose game exploded on TikTok. You don't see the thousands of games that launched the same week to zero coverage and twelve wishlists. Every decision you make should account for the base rate, not the highlight reel.

- **Revenue expectations by tier** are worth internalizing early. A "successful" indie game on Steam might gross $50K–$200K in its first year. A "hit" might do $500K–$2M. A "mega-hit" is $5M+. After Steam's cut, taxes, and development costs, the take-home is dramatically less than the gross. Knowing these tiers helps you budget your time and money realistically.

- **Gross vs. net revenue** — Steam takes 30% (dropping to 25% at $10M and 20% at $50M), then there's taxes, refunds, and regional pricing. Your take-home is roughly 50-60% of gross.

- **The long tail** — Most game revenue comes in the first month, then drops steeply. Sales events create spikes, but the trend is downward. Plan for front-loaded income.

**Read:**
- VG Insights — Steam market analysis: https://vginsights.com/insights/article/infographic-indie-game-revenues-on-steam — data on actual indie game revenues and trends
- "What is the Average Revenue of Indie Games?" by Chris Zukowski: https://howtomarketagame.com/2022/04/18/what-is-the-average-mass-of-a-mass-of-indie-games/ — data-driven look at indie game revenue
- Game Developer — The State of Indie: https://www.gamedeveloper.com/business/the-state-of-indie-game-development-in-2023 — industry perspective on indie sustainability

**Exercise:** Calculate your personal "ramen profitable" number. Add up your monthly expenses (rent, food, insurance, tools, subscriptions). Multiply by 12. Then multiply by 2 (to account for Steam's cut and taxes). That's roughly how much your game needs to gross annually for you to go full-time. Write this number down — you'll reference it throughout this roadmap.

**Time:** 2–3 hours

---

## Module 1: Legal & Business Foundations

> **Deep dive:** [Full study guide](module-01-legal-business-foundations.md)

**Goal:** Set up the legal and financial infrastructure you need before you earn a single dollar — so that when money does come in, you're not scrambling.

Nobody gets into game development because they're excited about tax forms. But here's the thing: getting the legal and business stuff set up early is one of the highest-leverage things you can do. It takes a few hours now and saves you weeks of panic later. The devs who skip this step end up with nasty surprises around tax time or, worse, personal liability issues if something goes wrong.

If you're in the US, the most common structure for a solo indie dev is an **LLC (Limited Liability Company)**. It separates your personal assets from your business, it's relatively cheap to set up, and it gives you flexibility on how you're taxed. If you're outside the US, the equivalent structure varies — sole trader, ltd company, etc. The point is: don't operate as an unincorporated individual if you're receiving real revenue. The protection isn't worth skipping.

**Key concepts:**

- **Business entity selection** matters more than you think. An LLC isn't just about liability — it also affects how platforms pay you, how you handle contracts with collaborators, and whether you can deduct business expenses properly. Setting up takes an afternoon and costs $50–$500 depending on your state.

- **Tax obligations** catch a lot of indie devs off guard. If you're selling on Steam, you're receiving income. Depending on your country and structure, you might owe income tax, self-employment tax, VAT/GST, and more. Steam handles VAT for most regions, but you're responsible for your own income taxes. Set aside 25–30% of every dollar that comes in. Open a separate bank account. Future you will be grateful.

- **Contracts and collaboration** need to be formalized even with friends — *especially* with friends. If someone contributes art, music, or code to your game, you need a written agreement about who owns what and how revenue is split. A rev-share handshake on Discord is not a contract. Template agreements exist and they're cheap. Use them.

**Read:**
- Steamworks — Tax & Payment FAQ: https://partner.steamgames.com/doc/finance/taxfaq — Steam's official documentation on tax interviews and payment setup
- itch.io — Getting Paid: https://itch.io/docs/creators/payments — how itch.io handles payments, tax forms, and payouts
- Game Developer — Legal Basics for Indie Devs: https://www.gamedeveloper.com/business/a-practical-guide-to-game-law — practical legal advice for small game studios

**Exercise:** Draft a one-page "business setup checklist" for your situation. Include: business entity type, registration steps, bank account setup, tax ID requirements, and a list of any collaborators who need written agreements. You don't have to execute it all today — but having the checklist means you know exactly what needs doing.

**Time:** 3–5 hours

---

## Module 2: Platform Economics

> **Deep dive:** [Full study guide](module-02-platform-economics.md)

**Goal:** Understand how Steam, itch.io, mobile stores, and console platforms actually work as businesses — their revenue splits, discovery algorithms, and incentive structures — so you can make platform decisions strategically.

Every platform is a business with its own incentives, and those incentives shape what gets promoted, what gets buried, and how money flows. If you don't understand the platform's business model, you can't make good decisions about your own.

**Key concepts:**

- **Steam** is the 800-pound gorilla for PC indie games, and for good reason. Its 70/30 revenue split (improving to 75/25 at $10M and 80/20 at $50M) is the industry standard, and its discovery systems — while imperfect — still give small games a real shot at visibility. The algorithm rewards wishlists, conversion rates, and engagement. Steam also handles payments, refunds, regional pricing, and VAT in most countries. The Steamworks documentation is extensive and worth reading end to end.

- **itch.io** operates on a fundamentally different model. Sellers choose their own revenue split — including 0%. The platform is beloved by experimental and jam-oriented communities. Revenue expectations are lower, but it's an excellent place for free games, demos, pay-what-you-want experiments, and building an early audience. Many devs use itch.io as a testing ground before a Steam launch.

- **Mobile platforms** (iOS App Store, Google Play) take a 30% cut (15% for small developers under $1M/year on both platforms). But the real cost of mobile isn't the revenue split — it's the user acquisition. Organic discovery on mobile is essentially dead for paid games. Free-to-play dominates because it's the only model that supports the marketing spend required to acquire users. Unless your game has a very specific mobile-native audience, mobile is probably not where you want to be as a small indie.

- **Console platforms** (Nintendo eShop, PlayStation Store, Xbox/Microsoft Store) require developer program acceptance, dev kits, and often age rating certification. Revenue splits are typically 70/30. The audience is real, but the barriers to entry and porting costs are non-trivial. Console is usually a "second platform" decision, not a starting point.

> For how Steam's algorithm affects launch strategy and visibility, see the [Indie Game Marketing roadmap](../indie-marketing/indie-marketing-learning-roadmap.md).

**Read:**
- Steamworks — Store Presence: https://partner.steamgames.com/doc/store — official documentation on how your game appears on Steam
- itch.io — Creator Documentation: https://itch.io/docs/creators — everything about selling on itch.io
- SteamDB — Sales Tracker: https://steamdb.info/sales/ — real data on how Steam sales work, price history, and trends

**Exercise:** Pick three indie games in your genre that launched in the last two years. For each, research: what platforms they're on, their price on each platform, their estimated revenue (VG Insights or SteamDB), and their review count on Steam. Write a short analysis: which platform seems to drive most of their revenue, and why?

**Time:** 3–5 hours

---

## Module 3: Pricing Psychology & Strategy

> **Deep dive:** [Full study guide](module-03-pricing-psychology-strategy.md)

**Goal:** Learn how to price your game so that it communicates value, fits genre expectations, and maximizes revenue across your game's lifetime.

Pricing is one of the highest-leverage decisions you'll make, and one of the most emotionally fraught. Indie devs chronically underprice their games, usually out of imposter syndrome ("who would pay $20 for something *I* made?") or fear ("if it's cheap, more people will buy it"). Both instincts are wrong.

**Key concepts:**

- **Price anchoring** is the most important psychological concept in game pricing. Players don't evaluate your $15 game in a vacuum — they evaluate it against every other $15 game they've seen. If your game looks comparable to games priced at $20–$25, pricing at $15 feels like a deal. If comparable games are $10, your $15 feels expensive. Research your genre's price range before setting yours. Steam's "More Like This" section is a free focus group.

- **The $10 threshold** is psychologically significant. Below $10, a purchase feels trivial — players will impulse-buy more easily. Above $10, players start reading reviews and watching gameplay videos before purchasing. This doesn't mean you should always price under $10 — it means you need to understand that the purchase psychology changes. A $15 or $20 game needs stronger store page presentation, more social proof, and better marketing.

- **Perceived value** is driven by production quality signals: trailer quality, screenshot composition, store page copy, art style consistency, and content quantity. A game with 2 hours of content struggles at $20 regardless of how good those 2 hours are. A game with 40 hours of content at $20 feels like a steal. Content length isn't the *only* value signal, but it's one players weigh heavily.

- **Genre pricing norms** exist and you ignore them at your peril. Roguelikes cluster around $10–$20. Story-driven adventures range from $15–$30. Grand strategy games can charge $30–$50. Puzzle games struggle above $15 unless they have exceptional production values. Check what's normal for your genre, then decide whether to match, undercut, or exceed — and know why.

- **Discount depth planning** — Your launch price determines your discount floor. A $20 game at 50% off is $10 — still reasonable. A $5 game at 50% off is $2.50 — you're leaving money on the table. Price high enough that your eventual deep discounts still generate meaningful per-unit revenue.

**Read:**
- "Pricing Your Indie Game" by Chris Zukowski: https://howtomarketagame.com/2022/01/24/pricing-your-indie-game/ — practical guide to indie game pricing
- Steamworks — Pricing: https://partner.steamgames.com/doc/store/pricing — Steam's official pricing documentation, including regional pricing recommendations
- Game Developer — How to Price Your Indie Game: https://www.gamedeveloper.com/business/how-to-price-your-indie-game — deep dive into pricing psychology for games

**Exercise:** Create a "pricing grid" for your game (or a hypothetical one). Research 8–10 comparable games in your genre on Steam. For each, record: title, launch price, current price, lowest sale price, review count, and estimated revenue. Then decide on your launch price and write one paragraph justifying it based on your research.

**Time:** 3–4 hours

---

## Module 4: The Premium Model

> **Deep dive:** [Full study guide](module-04-the-premium-model.md)

**Goal:** Master the pay-once premium model — the most common and most viable revenue approach for small indie teams — from Coming Soon page through post-launch optimization.

The premium model (player pays once, gets the full game) is the bread and butter of indie games. It's straightforward, honest, and — when executed well — the most realistic path to sustainable indie revenue. Every other model in this roadmap is either a variation on premium or an alternative that comes with significantly more complexity.

**Key concepts:**

- **The Steam Coming Soon page** is your single most important business asset. From the moment it goes live, it starts accumulating wishlists — and wishlists are the best predictor of launch revenue we have. The commonly cited multiplier is that first-week revenue roughly equals wishlists x $0.50 to $1.50 (depending on price and conversion rate). If you have 10,000 wishlists at launch, you might expect $5K–$15K in first-week revenue. If you have 50,000, you're looking at $25K–$75K. This is *rough* math, but it's the best mental model we have. Your Coming Soon page should go live as early as possible — ideally 6–12 months before launch, sometimes earlier.

- **Steam Next Fest** is one of the most powerful free marketing tools available to indie devs. You get a demo slot in a curated festival that drives millions of players to browse and try new games. The wishlist conversion from a good Next Fest demo can be enormous. You only get one shot at it per game, so make it count: your demo should be polished, represent the final experience, and be short enough that players finish it (30–60 minutes is ideal).

- **Launch week optimization** — The first 2 weeks post-launch are critical. This is when you get algorithmic visibility, press coverage, and full-price sales. Don't launch into a crowded week, don't launch near a major sale event, and don't launch with known bugs. For detailed launch strategy, see the [Indie Game Marketing roadmap](../indie-marketing/indie-marketing-learning-roadmap.md).

- **Review velocity** — Early positive reviews compound your visibility. The jump from "no reviews" to "Positive (10 reviews)" is a massive credibility shift. Encourage reviews, respond to feedback, and fix reported bugs fast.

**Read:**
- Steamworks — Coming Soon: https://partner.steamgames.com/doc/store/coming_soon — official documentation on setting up your Coming Soon page
- "How Many Wishlists Do You Need?" by Chris Zukowski: https://howtomarketagame.com/2021/03/01/how-many-wishlists-do-you-need-to-be-successful-on-steam/ — data on the relationship between wishlists and revenue
- Steamworks — Steam Next Fest: https://partner.steamgames.com/doc/marketing/steamgamenextfest — how to participate and make the most of Next Fest

**Exercise:** Set up a Coming Soon page for your game on Steam (or plan one in detail if you're not ready). Write the short description, identify 5 comparison games for tags, plan your capsule art dimensions, and create a timeline for when your demo will be ready for Next Fest. If your game is hypothetical, do this exercise with a game concept and treat it as a business planning exercise.

**Time:** 4–6 hours

---

## Module 5: DLC, Expansions & Post-Launch Revenue

> **Deep dive:** [Full study guide](module-05-dlc-expansions-post-launch-revenue.md)

**Goal:** Learn how to extend your game's revenue life through additional paid content — DLC, expansions, and updates — without alienating your existing audience.

Your game's launch is the beginning of its revenue life, not the end. The developers who sustain themselves financially are usually the ones who figure out how to keep earning from a game after the initial sales spike fades. DLC and expansions are the most straightforward way to do this within the premium model.

**Key concepts:**

- **DLC value perception.** DLC on Steam can range from a $2 soundtrack to a $15 expansion that doubles the game's content. The key question is always: does this feel like genuine additional value, or does it feel like content that was cut from the base game? Players are hyper-sensitive to the second perception. The safest DLC is content that clearly couldn't have existed at launch — new campaigns, new characters, new game modes developed after release based on community feedback.

- **Content gating ethics** — Never hold back content from the base game to sell as DLC. Players will notice, reviews will reflect it, and the short-term revenue isn't worth the long-term reputation damage.

- **DLC attachment rate** — The percentage of base game owners who buy DLC. For indie games, 10–20% is typical. Plan your DLC revenue projections accordingly — if you sold 10,000 copies, expect 1,000–2,000 DLC sales.

- **Free updates vs. paid DLC** is a strategic choice. Free updates keep your existing player base engaged, generate goodwill, and can drive new sales as coverage of the update reaches new audiences. Paid DLC generates direct revenue but has a smaller audience. The ideal approach for most indie games is a mix: free updates that add quality-of-life improvements and minor content, paired with paid DLC for substantial new content.

- **The "complete edition" bundle** is an underrated strategy. Once you have your base game plus 2–3 DLCs, create a bundle that includes everything at a discount. This becomes your primary conversion tool during sales events. New players get a better deal, and the higher total price means your percentage discounts still yield meaningful per-unit revenue.

**Read:**
- Steamworks — DLC: https://partner.steamgames.com/doc/store/application/dlc — official documentation on creating and managing DLC on Steam
- "Tips for Keeping Your Game Selling After Launch" by Chris Zukowski: https://howtomarketagame.com/2023/08/14/tips-for-keeping-your-game-selling-after-launch/ — strategies for sustaining sales
- Steamworks — Bundles: https://partner.steamgames.com/doc/store/application/bundles — how to create bundles combining your base game and DLC

**Exercise:** Design a DLC roadmap for your game (or a game you've played recently). Plan three post-launch content releases: one free update, one small paid DLC ($3–$5), and one larger expansion ($8–$15). For each, describe the content, the development time needed, and the expected revenue based on realistic attachment rates. Calculate the total additional lifetime revenue this plan would generate.

**Time:** 3–5 hours

---

## Module 6: Free-to-Play & Live Service Models

> **Deep dive:** [Full study guide](module-06-free-to-play-live-service-models.md)

**Goal:** Understand how F2P and live service models actually work economically — and make an honest, informed decision about whether they're right for your situation (they probably aren't).

Let's be direct: if you're a solo developer or a team of 2–4 people, free-to-play is almost certainly the wrong model for you. This module explains why, while also covering how F2P actually works for the studios that do it successfully — because understanding the model helps you evaluate opportunities and avoid bad decisions.

**Key concepts:**

- **The F2P math problem** is simple but brutal. In a premium model, every download is a customer who paid you. In F2P, every download is a *cost* — server infrastructure, support burden, content expectations — and only 2–5% of players will ever spend money. Of those who do spend, a tiny fraction (the "whales") generate the majority of revenue. This means F2P games need enormous player bases to be profitable. We're talking hundreds of thousands of active players minimum. Acquiring those players costs money (marketing, user acquisition campaigns), which means you need capital before you earn capital.

- **The content treadmill** is the other killer. F2P players expect continuous new content — weekly events, monthly updates, seasonal battle passes. The moment you stop feeding the content machine, players leave and revenue drops. This requires a production pipeline that a small team simply cannot sustain. Studios that run successful F2P games have dedicated teams for live operations, monetization design, data analytics, and community management. That's not a lifestyle business — that's a startup.

- **Ethical monetization** in F2P is possible but difficult. The most respected F2P models sell cosmetics only (Path of Exile, Warframe, Fortnite). Pay-to-win mechanics generate short-term revenue but destroy community trust and long-term retention. If you do pursue F2P, the "cosmetics only" model is the only one that's both ethical and sustainable.

- **When F2P actually makes sense** for small teams: if you're making a multiplayer game where the primary growth loop is social (players invite friends), if you have the runway to operate at a loss for 6–12 months while building your player base, and if you're genuinely excited about live operations as a job. If any of those conditions aren't true, premium is the better model.

**Read:**
- Game Developer — F2P Economics: https://www.gamedeveloper.com/business/free-to-play-games-making-money — honest look at what makes F2P work and what doesn't
- GDC Vault — Free-to-Play Design: https://gdcvault.com/search.php#&category=free_to_play&firstfocus=&keyword=free+to+play — GDC talks on F2P design and monetization
- Steamworks — Free to Play: https://partner.steamgames.com/doc/store/application/freetoplay — Steam's documentation on running a F2P game

**Exercise:** Find a small indie F2P game on Steam (under 1,000 reviews) that launched in the last two years. Research: its monetization model, its player retention (SteamDB player charts), its update frequency, and its review sentiment around monetization. Write a one-page analysis: is this game's F2P model working? What would you change? Would premium have been a better choice?

**Time:** 3–5 hours

---

## Module 7: Crowdfunding & Community Funding

> **Deep dive:** [Full study guide](module-07-crowdfunding-community-funding.md)

**Goal:** Understand the real costs, prerequisites, and economics of Kickstarter, Steam Early Access, and ongoing community funding (Patreon/Ko-fi) — so you can decide if any of them fit your situation.

Crowdfunding is not free money. It's a specific deal: you promise to deliver something, people pay you in advance, and then you have to actually deliver it while managing expectations, communication, and fulfillment. It's harder than it looks, and the games that succeed on Kickstarter almost always had a significant existing audience before the campaign launched.

**Key concepts:**

- **Kickstarter economics** are counterintuitive. Kickstarter takes 5%, payment processing takes 3–5%, and if you offer physical rewards (posters, artbooks, physical copies), fulfillment and shipping can eat another 20–40% of the money raised. A campaign that raises $50,000 might net you $30,000–$35,000 after all costs. Factor in the 2–3 months of full-time work it takes to run a good campaign (video production, page design, backer communication, stretch goals), and the effective hourly rate drops fast.

- **The "existing audience" prerequisite** is the part most people skip. Successful Kickstarter campaigns don't build an audience during the campaign — they *activate* an audience they already have. If you don't have a mailing list, a social media following, or a demo with significant traction, your campaign will probably struggle. The typical advice is: if you can't get 1,000 people to sign up for a mailing list, you can't get 1,000 people to back a Kickstarter.

- **Steam Early Access** is a different form of crowdfunding, and for many indie devs, it's the better option. Instead of promising a game and delivering later, you sell an incomplete-but-playable game now and develop it publicly. The advantages: you get real revenue from real sales (not pledges), you get player feedback during development, and Steam's discovery systems work for you. The disadvantage: if your Early Access launch flops, you've "used up" your launch visibility and it's very hard to recover.

- **Patreon and ongoing support** models work best for developers with a public development process — regular devlogs, streams, or YouTube content. The revenue is usually modest ($500–$3,000/month for most indie devs who do it), but it's *recurring*, which helps with financial planning. Think of it as a supplement to game sales, not a replacement.

> For community building and audience development strategies, see the [Indie Game Marketing roadmap](../indie-marketing/indie-marketing-learning-roadmap.md).

**Read:**
- Kickstarter — Creator Handbook: https://www.kickstarter.com/help/handbook — Kickstarter's official guide for campaign creators
- Steamworks — Early Access: https://partner.steamgames.com/doc/store/earlyaccess — Steam's documentation and guidelines for Early Access
- "Should I Kickstart My Game?" by Chris Zukowski: https://howtomarketagame.com/2020/11/09/should-i-kickstart-my-game/ — practical advice on whether Kickstarter is right for your game

**Exercise:** Plan a hypothetical Kickstarter campaign for your game (even if you don't intend to run one). Define: your funding goal, three reward tiers with costs, a stretch goal plan, a pre-campaign audience building timeline, and a post-campaign delivery schedule. Then calculate the *net* revenue after all platform and fulfillment costs. Compare this to the revenue you'd expect from a premium Steam launch with similar marketing effort. Which is the better deal?

**Time:** 3–5 hours

---

## Module 8: Sales, Bundles & Catalog Strategy

> **Deep dive:** [Full study guide](module-08-sales-bundles-catalog-strategy.md)

**Goal:** Learn how to use Steam sales, third-party bundles, and cross-promotion to maximize lifetime revenue without devaluing your game.

After your launch window closes, sales events become your primary revenue driver. Understanding how to use them strategically — rather than just slashing prices whenever Steam suggests it — is the difference between a game that earns for years and one that flatlines after month three.

**Key concepts:**

- **The Steam seasonal sale cycle** is predictable and plannable. The four major sales (Spring, Summer, Autumn, Winter) plus events like the Steam Scream Fest and Turn-Based Fest are when the most eyeballs are browsing. Plan your discount schedule around these events. The general strategy: start with modest discounts (10–20%) in the first few months post-launch, deepen gradually (25–40% by month 6–12), and reach deeper discounts (50–75%) only after 1–2 years. Never discount more than 50% in the first year unless you have a very specific strategic reason.

- **The discount treadmill** is a real concern. Once you've offered your game at 75% off, a significant portion of potential buyers will wait for that discount to return rather than buying at a smaller discount. Every time you deepen your discount, you establish a new "real price" in consumers' minds. This is why starting price matters so much — your launch price is also your long-term discount ceiling.

- **Third-party bundles** (Humble Bundle, Fanatical, etc.) can generate meaningful revenue but at very low per-unit prices. A game in a Humble Bundle might earn $0.50–$2.00 per copy. The upside is volume — a good bundle can move tens of thousands of units. The potential downside is market saturation: if 50,000 people own your game from a $1 bundle, that's 50,000 people who won't buy your game later at a higher price. Use bundles strategically, typically for older games where full-price sales have already peaked.

- **Multi-game catalog strategy** is the long game. If you're building a career in indie games (not just making one game), your second and third games become cross-promotional tools for each other. A "developer bundle" on Steam that includes all your games at a combined discount is one of the most effective conversion tools available. Players who enjoy one of your games are your warmest leads for the next one.

**Read:**
- Steamworks — Discounting: https://partner.steamgames.com/doc/marketing/discounts — official rules and best practices for Steam discounts
- "What Is the Best Discount Strategy?" by Chris Zukowski: https://howtomarketagame.com/2021/06/07/what-is-the-best-discount-strategy-for-a-new-game/ — data-driven advice on when and how much to discount
- Steamworks — Bundles: https://partner.steamgames.com/doc/store/application/bundles — creating store bundles for cross-promotion

**Exercise:** Create a 2-year discount schedule for your game. Plan which Steam sales you'll participate in, what your discount will be at each event, and when you'll consider third-party bundles. Calculate your expected revenue at each discount tier based on realistic unit estimates. Then plan a "game 2" strategy: how would releasing a second game change your approach to discounting and bundling game 1?

**Time:** 3–4 hours

---

## Module 9: Revenue Diversification & Sustainability

> **Deep dive:** [Full study guide](module-09-revenue-diversification-sustainability.md)

**Goal:** Explore income streams beyond game sales — freelancing, asset creation, content creation, and other strategies that can extend your runway and reduce the pressure on any single game to pay all the bills.

Here's a truth that few gamedev influencers talk about: most successful full-time indie devs don't live on game revenue alone, especially in the early years. They supplement with freelancing, contract work, asset creation, teaching, or content creation. This isn't a failure — it's smart financial engineering. Diversifying your income reduces the existential pressure on each game release, which ironically makes you a better game developer because you can take more creative risks.

**Key concepts:**

- **Freelancing and contract work** is the most direct supplemental income for game developers. Your skills — programming, art, music, design — are valuable to other studios, and contract work lets you earn while building your own games on the side. The trick is managing your time so that freelancing funds your indie work without consuming it entirely. Many devs do a 60/40 or 70/30 split between contract and personal projects.

- **Asset creation and tool sales** can generate passive income from the same skills you use in your own games. Selling art packs, code libraries, shaders, or tools on the Unity Asset Store, itch.io, or your own site creates a revenue stream that doesn't require launching a game. Some developers earn more from assets than from their games, especially in underserved niches.

- **Content creation** (YouTube, Twitch, blogging, courses) is a longer-term play. Building an audience around your development process creates a marketing channel for your games *and* an independent revenue stream from ads, sponsorships, or course sales. The devs who do this well have built businesses that transcend any single game. But building an audience takes time — think years, not months.

- **Runway extension** — Every dollar earned from non-game sources is a dollar of pressure removed from your game's launch. A freelance gig that covers three months of rent means your game has three more months to find its audience.

**Read:**
- itch.io — Selling Assets: https://itch.io/docs/creators/assets — how to sell game assets and tools on itch.io
- Game Developer — Indie Sustainability: https://www.gamedeveloper.com/business/sustainable-indie-game-development — strategies for long-term indie sustainability
- "How to Build an Audience for Your Indie Game" by Chris Zukowski: https://howtomarketagame.com/2020/09/07/how-to-build-an-audience-for-your-indie-game/ — building an audience that supports multiple revenue streams

**Exercise:** List every monetizable skill you have (programming, art, music, writing, teaching, etc.). For each, identify one way you could earn supplemental income from it within the next 3 months. Then pick the two most realistic options and create a one-page plan for each: what you'd sell, where you'd sell it, what it would cost to produce, and what you'd realistically earn in the first 6 months.

**Time:** 2–4 hours

---

## Module 10: Financial Planning & The Long Game

> **Deep dive:** [Full study guide](module-10-financial-planning-the-long-game.md)

**Goal:** Build a multi-year financial plan that accounts for development costs, revenue projections, taxes, and the real math of going full-time — so you can make the leap (or decide not to) with clear eyes.

This is the capstone module. Everything you've learned — platform economics, pricing, revenue models, diversification — converges here into an actual plan. Not a vague intention to "go indie someday," but a spreadsheet with numbers, timelines, and decision points.

**Key concepts:**

- **The "go full-time" calculation** is simpler than most people make it. You need three numbers: your monthly burn rate (all personal and business expenses), your runway (savings divided by burn rate), and your expected revenue timeline. If your runway is 12 months and you expect your game to take 18 months to finish, the math doesn't work — you either need to extend your runway (savings, freelancing, reduce expenses) or shorten your timeline (scope cut). There is no third option. Hope is not a financial strategy.

- **Revenue projections** should be built on conservative, median-case scenarios, not best-case fantasies. Use the data from Module 0: median indie games earn a few thousand dollars. Model three scenarios: pessimistic (25th percentile), realistic (50th percentile), and optimistic (75th percentile). Make your financial decisions based on the pessimistic scenario. If the optimistic scenario happens, that's a bonus.

- **Development budgeting** means tracking your time as a cost even when you're not paying yourself. If you spend 2,000 hours on a game and your market rate is $50/hour, that game cost $100,000 to make — even if you never wrote yourself a check. This helps you evaluate whether your time is being spent on high-value activities.

- **The multi-game financial model** is where indie sustainability actually lives. Your first game is a learning experience — if it breaks even, that's a success. Your second game benefits from everything you learned and from your existing audience. By game three or four, you have a back catalog generating passive revenue, a mailing list of engaged players, and the skills to ship faster and smarter. The devs who make it full-time are almost never the ones who hit it big with game one — they're the ones who shipped four games, learned from each, and built a sustainable catalog business.

**Read:**
- "Can You Quit Your Job to Go Indie?" by Chris Zukowski: https://howtomarketagame.com/2021/01/18/can-you-quit-your-job-to-go-indie/ — honest math on whether going full-time makes sense
- Steamworks — Sales Reporting: https://partner.steamgames.com/doc/finance/payments_salesreporting — understanding your Steam financial reports and payment schedules
- Game Developer — Financial Planning for Indie Devs: https://www.gamedeveloper.com/business/financial-planning-for-indie-game-developers — long-term financial strategies

**Exercise:** Build a 3-year financial plan in a spreadsheet. Include: monthly burn rate, current savings/runway, expected development timeline for your next game, revenue projections (pessimistic/realistic/optimistic) based on wishlist and comp data, supplemental income from Module 9 strategies, tax obligations, and decision points ("if revenue is below $X by month Y, take a contract job"). This is the single most important exercise in this entire roadmap. Your plan will be wrong — but having a wrong plan that you update monthly is infinitely better than having no plan at all.

**Time:** 3–5 hours

---

## Essential Bookmarks

| Resource | URL | What It's For |
|----------|-----|---------------|
| SteamDB | [steamdb.info](https://steamdb.info) | Price history, player data, sales tracking, app info |
| VG Insights | [vginsights.com](https://vginsights.com) | Steam revenue estimates, market analysis, genre trends |
| Steamworks Documentation | [partner.steamgames.com](https://partner.steamgames.com/doc/home) | Official docs for everything Steam — pricing, DLC, wishlists, sales |
| How To Market A Game | [howtomarketagame.com](https://howtomarketagame.com) | Chris Zukowski's data-driven indie marketing and business blog |
| Game Developer | [gamedeveloper.com](https://www.gamedeveloper.com) | Industry news, postmortems, business analysis |
| GDC Vault | [gdcvault.com](https://gdcvault.com) | Conference talks on every aspect of game development and business |
| itch.io Creator Docs | [itch.io/docs/creators](https://itch.io/docs/creators) | Selling games and assets on itch.io |
| Kickstarter Handbook | [kickstarter.com/help/handbook](https://www.kickstarter.com/help/handbook) | Official campaign creation guide |
| Steam Revenue Calculator | [steam-revenue-calculator.com](https://steam-revenue-calculator.com) | Rough revenue estimates based on review count |
| r/gamedev | [reddit.com/r/gamedev](https://www.reddit.com/r/gamedev) | Community discussion on game business, launches, and revenue |

---

## ADHD-Friendly Tips

Business and financial planning is the kind of work that ADHD brains tend to avoid — it's abstract, it involves numbers, and the payoff feels distant. Here's how to make it manageable:

- **Start with Module 0 and nothing else.** The reality check module is the most important one. If you only do one module this month, make it that one. Everything else builds on it.

- **Use the exercises as forcing functions.** Don't just read about pricing — build the pricing grid. Don't just think about budgets — open a spreadsheet. The exercises exist because abstract knowledge without concrete application evaporates in 48 hours.

- **Batch the boring stuff.** Legal setup (Module 1) is tedious but finite. Block out one Saturday, put on a long playlist, and knock it all out. Don't spread business registration and tax setup across three weeks — that guarantees you'll never finish.

- **Set a "money Monday" habit.** Spend 30 minutes every Monday morning checking your Steam dashboard, reviewing sales data, and updating your financial plan. Small, regular check-ins prevent the "I haven't looked at my numbers in four months" anxiety spiral.

- **Pair business work with dopamine.** Do financial planning at your favorite coffee shop. Review pricing research while listening to a podcast you enjoy. Associate the boring work with an environment or activity that makes it tolerable.

- **The spreadsheet is your friend, not your enemy.** A single spreadsheet with your burn rate, revenue projections, and runway is the most powerful anxiety-reduction tool in this entire roadmap. The unknown is scarier than any number. Put the numbers in a spreadsheet and the fear gets smaller.

- **Don't compare your chapter 1 to someone else's chapter 20.** The dev posting $100K launch revenue on Twitter has probably shipped four games, built an audience over five years, and had three flops before the hit. Your first game's financial goal is to break even and teach you the business. That's a success.

- **Revenue diversification (Module 9) is ADHD gold.** If your brain craves variety, the freelancing/assets/content creation module gives you permission to explore adjacent income streams. This isn't procrastination — it's smart financial planning that also happens to be more stimulating than staring at your main project.

- **Automate what you can.** Set up automatic tax withholding transfers (25% of every payment goes to a separate savings account). Use accounting software from day one, even if your income is tiny. Future-you dealing with tax season will be profoundly grateful.

- **Remember: knowing the numbers is power, not punishment.** Every module in this roadmap is about replacing anxiety with information. You might not like the numbers, but knowing them puts you in control. That's the whole point.
