# Module 10: Financial Planning & The Long Game

> **Roadmap:** [Game Monetization Learning Roadmap](game-monetization-learning-roadmap.md)
>
> **Study time:** 3–5 hours
>
> **Prerequisites:** All previous modules (this is the capstone)

---

## Overview

This is the capstone module. Everything you've learned — platform economics, pricing, revenue models, diversification — converges here into an actual plan.

Not a vague intention to "go indie someday." A spreadsheet with numbers, timelines, and decision points.

The developers who make it as full-time indies aren't necessarily the ones with the most talent or the best games. They're the ones who treated their career as a business with real financial constraints, made decisions based on data rather than hope, and adjusted their plans when reality didn't match their projections.

Financial planning isn't glamorous. It doesn't get likes on social media. Nobody makes viral videos about updating their budget spreadsheet. But it is the single most important skill separating developers who sustain a career from developers who burn out after one game.

This module walks you through the concrete math of going full-time, building revenue projections, budgeting your development time, and constructing a multi-game financial model that accounts for the compounding nature of an indie catalog.

---

## Core Concepts

### 1. The "Go Full-Time" Calculation

The decision to go full-time indie is simpler than most people make it. You need three numbers:

1. **Monthly burn rate:** All personal and business expenses combined
2. **Runway:** Total savings divided by monthly burn rate (in months)
3. **Revenue timeline:** When you realistically expect game revenue to cover your burn rate

If your runway is shorter than your revenue timeline, the math doesn't work. You either extend runway (save more, freelance, cut expenses) or shorten the timeline (reduce scope, ship faster). There is no third option. Hope is not a financial strategy.

**Why it matters:** Most indie developers who "fail" don't fail because their game was bad — they fail because they ran out of money before the game could find its audience. The go-full-time calculation forces you to confront the timeline honestly and make adjustments *before* you quit your job, not after.

**Calculating your burn rate:**
- **Fixed personal expenses:** Rent/mortgage, utilities, insurance, food, transportation, debt payments, subscriptions
- **Variable personal expenses:** Entertainment, dining out, travel, clothing
- **Business expenses:** Software licenses, asset purchases, contractor payments, marketing budget, conference attendance, hardware
- **Taxes:** Set aside 25–30% of all income for taxes (freelance income is taxed as self-employment in most countries)
- **Emergency buffer:** Add 10–15% to your total as a cushion for unexpected expenses

**Example burn rate for a solo US developer:**
| Category | Monthly |
|----------|---------|
| Rent (modest, shared housing) | $900 |
| Utilities + internet | $150 |
| Food | $400 |
| Health insurance | $350 |
| Transportation | $200 |
| Software/tools | $50 |
| Misc personal | $200 |
| Tax reserve (on supplemental income) | Variable |
| **Total** | **~$2,250** |

With $30,000 in savings, that's approximately 13 months of runway. Freelancing $1,000/month extends it to about 24 months.

**Common mistake:** Calculating burn rate based on your current spending without cutting non-essential expenses. Going full-time indie usually requires a period of reduced spending. If your burn rate is $4,000/month and you can get it to $2,500 by cutting discretionary spending, you've just added 40% to your runway. That's months of extra development time.

**Try this now:** Calculate your actual monthly burn rate using bank statements from the last 3 months. Be honest — include everything. Then calculate your runway at current savings. Then calculate your runway with realistic expense cuts. The gap between these numbers tells you how much lifestyle adjustment buys you in development time.

---

### 2. Revenue Projections

Revenue projections should be built on conservative, median-case scenarios — not best-case fantasies. The data from Module 0 is your foundation: the median indie game earns a few thousand dollars. Your projection needs to account for this reality while also modeling the upside.

**Why it matters:** Unrealistic revenue projections are the most common financial mistake in indie development. A developer who expects $100,000 in first-year revenue and earns $15,000 has a crisis. A developer who planned for $10,000 and earns $15,000 has a pleasant surprise and a sustainable business. The projections don't change your revenue — they change your decisions.

**The three-scenario model:**
- **Pessimistic (25th percentile):** Your game underperforms. Low review count, mediocre conversion, limited organic discovery. Revenue: $2,000–$8,000 in year one.
- **Realistic (50th percentile):** Your game performs at the median for its genre and price point. Decent review count, average conversion, some organic growth. Revenue: $8,000–$25,000 in year one.
- **Optimistic (75th percentile):** Your game overperforms. Strong reviews, good word-of-mouth, featured placement. Revenue: $25,000–$75,000 in year one.

**Make all financial decisions based on the pessimistic scenario.** If you can survive on pessimistic revenue, the realistic and optimistic scenarios are bonuses. If you need the optimistic scenario to pay rent, you're gambling.

**Estimating revenue from wishlists:**
A common heuristic (imperfect but useful):
- Pre-launch wishlists × 0.2 = approximate first-month units sold (20% conversion)
- First-month revenue = units × price × 0.7 (after Steam's 30% cut)
- Year-one revenue ≈ first-month revenue × 3–5 (accounting for seasonal sales and long-tail)

**Example:** A game with 5,000 wishlists at launch and a $14.99 price:
- First-month units: 5,000 × 0.2 = 1,000 copies
- First-month revenue: 1,000 × $14.99 × 0.7 = $10,493
- Year-one estimate: $10,493 × 3.5 = ~$36,700

But this is the realistic case. The pessimistic case might be half that: $18,000. The optimistic case might be double: $73,000. Plan for $18,000.

**Common mistake:** Using best-case comparisons as your baseline. Finding a game similar to yours that earned $200,000 and assuming you'll do the same is survivorship bias in action. For every game that earned $200,000, there are dozens in the same genre that earned $5,000. Use median data, not outliers.

**Try this now:** Find 5–10 games comparable to yours on SteamDB or VG Insights. Note their estimated revenue, review count, and time since launch. Calculate the median revenue for this cohort. Use that as your realistic scenario and halve it for your pessimistic scenario. Are these numbers compatible with your financial plan?

---

### 3. Development Budgeting

Even when you're not paying yourself a salary, your time has a cost. If you spend 2,000 hours on a game and your market rate is $50/hour, that game cost $100,000 to make — even if you never wrote yourself a check.

**Why it matters:** Tracking your time as a cost helps you make better decisions about where to spend your development effort. If a feature will take 200 hours to build and your market rate is $50/hour, that feature costs $10,000. Is it worth $10,000 in additional revenue? If not, cut it.

**This isn't about guilt or pressure.** It's about using opportunity cost as a decision-making tool. When you understand the real cost of your time, you make better scoping decisions, cut features more willingly, and avoid the trap of spending six months on a system that adds minimal player value.

**Time tracking for developers:**
- **Track hours weekly, not daily.** Daily tracking is tedious and creates guilt on low-output days. Weekly totals smooth out the natural variation in productivity.
- **Categorize broadly:** Programming, art, design, marketing, business/admin, testing. You don't need granular task-level tracking — you need to know where your months are going.
- **Review monthly:** At the end of each month, look at your time allocation. Is 40% of your time going to a system that represents 5% of the player experience? Adjust.

**The scope-time-cost triangle:**

| Scope | Dev Time | Opportunity Cost (@$50/hr) |
|-------|----------|---------------------------|
| Tiny (game jam scope) | 200 hours | $10,000 |
| Small (3–6 month project) | 500–1,000 hours | $25,000–$50,000 |
| Medium (1–2 year project) | 1,500–3,000 hours | $75,000–$150,000 |
| Large (2–3 year project) | 3,000–5,000 hours | $150,000–$250,000 |

Most solo indie developers are making $50,000–$150,000 games. The question is whether the market will return that investment. For a first game with no audience, the honest answer is: probably not directly. But the skills, audience, and catalog value you build are part of the return.

**Example:** A developer tracks their time and discovers they spent 800 hours on their game's combat system and 100 hours on the story — in a game where players consistently praise the story and complain about combat. For their next game, they flip the ratio: simpler combat, deeper story. The development cost drops and the product-market fit improves.

**Common mistake:** Not tracking time at all. Without data, you can't evaluate whether your time allocation matches your priorities. You don't need to be rigid about it — a simple weekly log in a spreadsheet is enough. The goal is awareness, not micromanagement.

**Try this now:** Start a simple weekly time log. At the end of each week, estimate hours spent on: programming, art, design, marketing, admin, and other. After one month, review the allocation. Does it match your priorities? Where are you spending time that doesn't contribute to the player experience or your business goals?

---

### 4. The Multi-Game Financial Model

Your first game is a learning experience. If it breaks even, that's a success. The real financial sustainability of an indie career lives in the multi-game model — the compounding effect of skills, audience, and back-catalog revenue over multiple releases.

**Why it matters:** Evaluating your indie career based on game one's revenue is like evaluating a restaurant based on its first week's receipts. The first game teaches you how to ship, how to market, and what your audience wants. The second game benefits from everything you learned. By game three or four, you have a back catalog generating passive revenue, a mailing list of engaged players, and the skills to ship faster and smarter.

**The compounding model:**

| | Game 1 | Game 2 | Game 3 | Game 4 |
|---|--------|--------|--------|--------|
| **Development time** | 24 months | 18 months | 14 months | 12 months |
| **Launch audience** | 0 | 2,000 | 5,000 | 10,000 |
| **Year-1 revenue** | $15,000 | $35,000 | $60,000 | $90,000 |
| **Back-catalog boost** | — | +$3,000 to G1 | +$5,000 to G1-2 | +$8,000 to G1-3 |
| **Cumulative revenue** | $15,000 | $53,000 | $118,000 | $216,000 |

These numbers are illustrative, not predictive. But the pattern is real and consistent across successful indie careers:
- Development time decreases as you get more experienced
- Launch audience grows as your mailing list and catalog expand
- Revenue per game increases because you're launching to a larger audience
- Back-catalog revenue adds a passive income floor that grows with each release

**The inflection point:** For most indie developers, the inflection point — where game revenue alone covers living expenses — comes between game two and game four. The developers who make it to that point are the ones who treated games one and two as investments in their career, not as make-or-break financial bets.

**Example:** A developer's first game earns $12,000. Disappointing, but they learned how to ship on Steam, built a mailing list of 800 people, and identified what their audience responds to. Their second game, launched 14 months later to that mailing list, earns $40,000 in year one. Game one gets a $4,000 back-catalog bump from cross-promotion. Total earnings across both games: $56,000 over roughly 3 years. Not enough to live on alone — but with freelance supplementation (Module 9), it's a viable career trajectory.

**Common mistake:** Quitting after game one underperforms. Many developers ship one game, see modest revenue, conclude that indie development "doesn't work," and give up. They're evaluating a catalog business based on one data point. The developers who succeed are the ones who ship game two.

**Try this now:** Model a four-game career in a spreadsheet. For each game: estimated development time, estimated launch audience (mailing list + wishlist), estimated year-one revenue (pessimistic), and back-catalog boost to previous games. Sum the cumulative revenue at each stage. At what point does the cumulative revenue start covering your cumulative living expenses?

---

### 5. Tax Planning and Business Finance

Taxes are the most overlooked aspect of indie game finance. Game revenue is income, and income is taxed. If you don't plan for taxes, a $30,000 game can quickly become $20,000 after self-employment tax, income tax, and state/local taxes.

**Why it matters:** Failing to set aside money for taxes is the most common financial crisis for new indie developers. You receive a Steam payment of $5,000, spend it all on living expenses, and then owe $1,500 in taxes you don't have. This is entirely preventable with basic planning.

**Tax fundamentals for indie developers (US-focused, but principles are universal):**
- **Self-employment tax:** In the US, self-employed individuals pay both the employer and employee portions of Social Security and Medicare — approximately 15.3% of net income.
- **Income tax:** Federal income tax on top of self-employment tax, at your marginal rate (10–37% depending on total income).
- **State tax:** Varies by state (0–13.3%). Some states have no income tax.
- **Quarterly estimated payments:** If you expect to owe $1,000+ in taxes, the IRS requires quarterly estimated payments. Missing these triggers penalties.

**The 25–30% rule:** Set aside 25–30% of every revenue payment in a separate savings account dedicated to taxes. Don't touch this money. When tax time comes, the money is there. This single habit prevents more financial crises than any other advice in this module.

**Deductible expenses:**
- Software licenses and subscriptions (game engines, art tools, project management)
- Hardware purchased for development (computer, drawing tablet, audio equipment)
- Asset purchases and contractor payments
- Marketing and advertising costs
- Home office deduction (percentage of rent/mortgage and utilities)
- Conference attendance and professional development
- Health insurance premiums (if self-employed)

**Example:** A developer earns $40,000 from game sales in a year. They have $8,000 in deductible business expenses. Taxable income: $32,000. Self-employment tax: ~$4,900. Federal income tax: ~$2,400. State tax (varies): ~$1,600. Total tax burden: ~$8,900, or about 22% of gross revenue. If they set aside 25% ($10,000), they have a comfortable buffer.

**Common mistake:** Not tracking expenses throughout the year. Come tax time, you need receipts and records for every deduction. Use accounting software (Wave is free, QuickBooks Self-Employed is ~$15/month) from day one, even when your income is tiny. Your future self during tax season will thank you.

**Try this now:** Open a separate savings account labeled "taxes." Set up an automatic transfer: every time you receive game revenue or freelance income, move 25% to the tax account. If you don't have income yet, set up the account anyway so the system is in place when revenue arrives.

---

### 6. Decision Points and Contingency Planning

A financial plan isn't a prediction — it's a decision framework. The most valuable part of your plan isn't the revenue projections (which will be wrong). It's the decision points: the "if X happens by date Y, I will do Z" statements that tell you when to pivot, when to persist, and when to take a different path.

**Why it matters:** Without pre-committed decision points, you'll make financial decisions emotionally — continuing to pour money into a project out of sunk-cost fallacy, or quitting too early because of a bad week. Decision points made in advance, when you're calm and rational, are better than decisions made under financial stress.

**Key decision points to define in advance:**

1. **The "take a contract job" trigger:** "If my runway drops below N months and monthly revenue is below $X, I will take a freelance contract to extend runway."
2. **The "scope cut" trigger:** "If development is N months behind schedule, I will cut features X, Y, and Z to ship on the revised timeline."
3. **The "pivot" trigger:** "If wishlists are below X at N months before planned launch, I will reassess my marketing strategy and consider whether the game has sufficient market demand."
4. **The "ship it" trigger:** "The game ships on [date] regardless of remaining polish items, unless a critical bug prevents a functional release."
5. **The "next game" trigger:** "I will begin planning game 2 when game 1 revenue stabilizes and the post-launch update cycle is complete, regardless of game 1's financial performance."

**Example decision framework:**
- Month 6: If wishlists < 2,000, increase marketing effort (social media, festival submissions, demo release)
- Month 9: If wishlists < 3,000, consider whether game concept has market viability. If yes, continue with adjusted marketing. If no, scope down to ship within 3 months and move to next project.
- Month 12: If runway < 6 months, take a 3-month freelance contract to extend runway
- Launch month: Ship the game. Period.
- Launch + 3 months: Evaluate revenue against pessimistic projection. If above pessimistic, continue updates. If below, begin planning game 2 immediately.

**Common mistake:** Not having decision points at all. Without them, you'll "just one more month" your way through your savings, always believing the breakthrough is around the corner. Pre-committed decision points are emotional circuit breakers. They don't prevent you from feeling the emotions — they prevent the emotions from driving your decisions.

**Try this now:** Write five decision points for your current game project. For each: the condition (measurable metric), the date by which you'll evaluate, and the action you'll take. Share these with a trusted friend or partner who can hold you accountable.

---

## Case Studies

### Case Study 1: The Spreadsheet That Saved a Career

A developer quit their job with 12 months of savings and a game that was "almost done." Six months later, the game was still six months from done (the classic development time estimation problem). With six months of runway left, they had to make a decision.

Because they had a financial plan with pre-committed decision points, they didn't panic. The plan said: "If runway drops below 6 months, take a 3-month contract at 80% time." They did. The contract extended their runway by 5 months (3 months of income plus reduced burn during that period). They shipped the game 4 months later.

The game earned $22,000 in its first year — below their realistic projection but above their pessimistic one. Because they'd planned for the pessimistic scenario, they were fine. They started game two with a mailing list, a shipped title, and financial stability.

**Lesson:** The financial plan didn't predict the future correctly (it never does). But it gave the developer a framework for making good decisions under stress. The decision point system turned a potential crisis into a planned adjustment.

### Case Study 2: The Four-Game Climb

A developer shipped four games over seven years:
- **Game 1** (2 years, solo): $8,000 lifetime revenue. Built basic skills, learned Steam, grew mailing list to 500.
- **Game 2** (18 months, solo): $28,000 lifetime revenue. Launched to existing audience, better marketing, stronger Steam presence. Mailing list grew to 2,000.
- **Game 3** (14 months, with contractor help): $65,000 lifetime revenue. Strong wishlist pre-launch, developer bundle cross-promoted games 1 and 2. Mailing list: 5,500.
- **Game 4** (12 months, with contractor help): $110,000 year-one revenue. Launched to a 10,000-person mailing list with three games of brand credibility behind it.

Total revenue across all four games: $225,000 over 7 years, with the trajectory accelerating. Games 1–2 earned during their back-catalog phase contributed an additional $15,000 from cross-promotion during games 3 and 4 launches.

By game 4, the developer was earning enough from game revenue alone to cover living expenses. But they reached that point because games 1–3 were funded by freelancing and frugal living — not because any single game was a breakout hit.

**Lesson:** The multi-game model works, but it requires patience, financial discipline, and the willingness to treat early games as investments rather than paychecks.

### Case Study 3: The Developer Who Planned for Failure

Before starting development, a developer built a financial plan with explicit failure scenarios:
- **Scenario A (best case):** Game earns $50,000+ in year one. Continue full-time indie development.
- **Scenario B (base case):** Game earns $15,000–$50,000. Continue indie development with freelance supplementation.
- **Scenario C (worst case):** Game earns less than $15,000. Return to full-time employment, develop game 2 on nights and weekends.

The game launched and earned $11,000 in year one — Scenario C. Because the developer had pre-committed to the decision framework, they returned to employment without shame or crisis. They developed game 2 over the next two years on evenings and weekends, launched it to a modest but real mailing list, and earned $35,000 in year one — solidly in Scenario B territory.

**Lesson:** Planning for failure isn't pessimism — it's preparation. Having a worst-case plan removes the existential terror from a poor launch and lets you make clear-headed decisions about what comes next.

---

## Common Pitfalls

1. **No financial plan at all:** "I'll figure it out when I need to." You won't. The time to figure it out is before you need to, when you can think clearly.

2. **Best-case-only planning:** Building your financial life around the optimistic scenario. When the realistic or pessimistic scenario materializes, you're unprepared.

3. **Ignoring taxes:** Spending all revenue as it arrives and owing thousands at tax time. The 25% savings rule prevents this entirely.

4. **Sunk-cost trap:** Continuing to invest in a game that isn't working because you've already invested so much. Your past investment is gone regardless — the question is whether future investment has a positive expected return.

5. **No decision points:** Drifting through development without pre-committed triggers for action. Decision points made in advance, when you're calm, are better than decisions made under stress.

6. **Comparing to outliers:** Using top-performing indie games as your financial baseline. Use median data. The median is your realistic case; outliers are lottery tickets.

7. **Quitting after game one:** Evaluating a catalog business based on a single release. The multi-game model requires patience and multiple data points.

---

## Exercises

1. **Complete financial plan:** Build a spreadsheet with the following sheets:
   - **Burn rate:** Monthly expenses, categorized and totaled
   - **Runway:** Current savings ÷ effective burn rate (after supplemental income)
   - **Revenue projections:** Three scenarios (pessimistic, realistic, optimistic) for your next game
   - **Decision points:** Five if/then triggers with dates and actions
   - **Multi-game model:** Four-game career projection with cumulative revenue

   This is the single most important exercise in this entire roadmap.

2. **Tax setup:** Open a separate savings account for taxes. Set up a system to automatically transfer 25% of every revenue payment. If you already have one, review your current tax reserve and ensure it's adequate.

3. **Decision point workshop:** Write five decision points for your current project. Share them with a trusted friend, partner, or fellow developer. Ask them to hold you accountable when the dates arrive.

4. **Retrospective (if you've shipped a game):** Compare your pre-launch financial projections to actual results. Where were you right? Where were you wrong? What would you change about your projections for the next game? If you haven't shipped yet, do this exercise using a comparable game's publicly available postmortem data.

---

## Recommended Reading

- **"Can You Quit Your Job to Go Indie?" by Chris Zukowski** — https://howtomarketagame.com/2021/01/18/can-you-quit-your-job-to-go-indie/ — honest math on whether going full-time makes sense
- **Steamworks — Sales Reporting** — https://partner.steamgames.com/doc/finance/payments_salesreporting — understanding your Steam financial reports and payment schedules
- **Game Developer — Financial Planning for Indie Devs** — https://www.gamedeveloper.com/business/financial-planning-for-indie-game-developers — long-term financial strategies
- **IRS Self-Employment Tax Guide** — https://www.irs.gov/businesses/small-businesses-self-employed/self-employment-tax-social-security-and-medicare-taxes — US tax obligations for self-employed developers
- **Wave Accounting** — https://www.waveapps.com — free accounting software suitable for solo indie developers

---

## Key Takeaways

- The "go full-time" decision comes down to three numbers: monthly burn rate, runway, and revenue timeline
- Build revenue projections on pessimistic scenarios — if you survive the worst case, everything else is a bonus
- Track your development time as a cost even when you're not paying yourself — it reveals where your effort is actually going
- The multi-game financial model is where indie sustainability lives: each game compounds skills, audience, and back-catalog revenue
- Set aside 25–30% of all income for taxes in a separate account — this prevents the most common financial crisis for new indie developers
- Pre-commit to decision points (measurable triggers with dates and actions) before you need them — calm decisions are better than panicked ones
- Your first game is a learning investment. Breaking even on game one is a success. The career is built over multiple releases.
- Having a wrong plan that you update monthly is infinitely better than having no plan at all

---

## What's Next

Congratulations — you've completed the Game Monetization Learning Roadmap. You now have a framework for thinking about the business of indie games that covers everything from platform economics to long-term financial planning.

The next step is the most important one: **build the spreadsheet.** Not tomorrow, not next week — now. Open a spreadsheet, plug in your real numbers, and see where you stand. The plan will be wrong. Update it monthly. The act of planning is more valuable than the plan itself.

Then go make your game. The business knowledge you've built here is the foundation. The game is the building. Go build it.

Return to the [Game Monetization Learning Roadmap](game-monetization-learning-roadmap.md) for a complete overview of all modules and resources.
