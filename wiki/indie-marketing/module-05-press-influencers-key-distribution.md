# Module 5: Press, Influencers & Key Distribution

> *"Nobody is going to discover your game by accident. You have to put it in front of people — specifically, people whose job it is to put games in front of other people."*

---

**Part of:** [Indie Marketing Learning Roadmap](indie-marketing-learning-roadmap.md)
**Estimated time:** 4–6 hours
**Prerequisites:** [Module 2 — Steam Page Is Your Landing Page](module-02-steam-page-is-your-landing-page.md), [Module 3 — Screenshot & GIF Content Pipeline](module-03-screenshot-gif-content-pipeline.md)

---

## Overview

Press and influencer coverage can put your game in front of thousands — sometimes hundreds of thousands — of potential players in a single day. A well-timed YouTube video from the right creator can generate more wishlists than months of social media posting. A single feature on a respected gaming site can validate your project and change its trajectory.

But getting that coverage requires preparation, professionalism, and realistic expectations. Most indie games won't get covered by IGN or Kotaku, and that's fine. A YouTube channel with 50,000 subscribers who love roguelikes is worth infinitely more than a passing mention on a mainstream site with millions of readers who mostly care about the latest Call of Duty. The game isn't to get the biggest names — it's to get the *right* names.

This module teaches you how to build a professional press kit that makes journalists' lives easy, write outreach emails that actually get opened, distribute keys without getting scammed, and build lasting relationships with the press and content creators who cover your genre. You'll learn that press outreach is less about begging for attention and more about providing a service: you have a game that might interest their audience, and you're making it effortless for them to cover it.

---

## Learning Outcomes

After completing this module, you will be able to:

- Build a complete, professional press kit using presskit() or a custom web page
- Write personalized outreach emails using the three-question formula
- Identify and vet legitimate press contacts and content creators in your genre
- Distribute Steam keys safely without falling for key scams
- Time your outreach campaign around your launch window
- Build a press contact spreadsheet and manage follow-ups professionally
- Understand the difference between press, influencers, and streamers — and why each matters
- Measure the ROI of your outreach efforts and iterate on what works

---

## Core Concepts

### 1. The Modern Landscape — Press vs. Influencers vs. Streamers

The games media ecosystem has changed dramatically in the last decade. Understanding who's out there — and who actually drives wishlists — is the first step in effective outreach.

**Traditional press** includes websites like PC Gamer, Rock Paper Shotgun, Kotaku, and Eurogamer. They publish written articles — previews, reviews, features, news pieces. Coverage from these outlets still carries weight, particularly for credibility and SEO, but their direct impact on sales has declined relative to video content.

**YouTubers** create produced videos — reviews, first impressions, "let's try" compilations, top 10 lists. A single YouTube video can drive wishlists for weeks or months because it lives on the platform and continues to be recommended. YouTube coverage has the longest shelf life of any media type.

**Streamers** broadcast live gameplay, typically on Twitch. Stream coverage creates immediate spikes in traffic but has a shorter tail — once the stream is over, the content is harder to discover. However, a popular streamer playing your game live can create a "everyone's playing this" effect that cascades through their community.

| Channel | Shelf life | Discovery | Best for |
|---------|-----------|-----------|----------|
| Written press | Months (SEO) | Google search | Credibility, SEO, store page quotes |
| YouTube | Months–years | Recommendations, search | Sustained wishlist growth |
| Twitch | Hours–days | Live audience, clips | Launch-day spikes, community buzz |
| TikTok | Days–weeks | Algorithm-driven | Viral moments, broad awareness |

**The reality for most indie games:** You're not going to get covered by the big outlets on your first game. That's normal. Your outreach should focus on mid-tier YouTubers (10K–200K subscribers) and niche sites that specifically cover your genre. These creators are more responsive, more likely to actually play your game, and their audiences are more aligned with your target player.

**Common mistake:** Emailing only the biggest names. If your entire press list is IGN, Kotaku, and PewDiePie, you're going to get zero coverage. Build your list from the bottom up — creators who are actively looking for interesting indie games to cover.

---

### 2. Building Your Press Kit

Before you email anyone, you need a press kit. A press kit is a single page (or downloadable package) where journalists and content creators can find everything they need to cover your game — without having to email you back and ask.

**What goes in a press kit:**

| Element | Details |
|---------|---------|
| Game title | Your game's name, obviously |
| One-line pitch | A single sentence describing your game |
| Short description | 2-3 paragraphs explaining the game, its genre, and what makes it interesting |
| Key features | 4-6 bullet points highlighting what's unique |
| Screenshots | 6-10 high-resolution screenshots, downloadable individually and as a zip |
| Key art | Your capsule art and logo in high resolution |
| Trailer | Embedded and/or a direct download link |
| GIFs | 3-5 GIFs showing core gameplay moments |
| Factsheet | Developer name, platform, release date (or window), price, engine |
| Contact info | Email address for press inquiries |
| Key request | A clear way to request a review key (link to form or email instructions) |
| Social links | Your Steam page, website, Twitter/X, Discord, etc. |

**The gold standard: presskit()**

Rami Ismail's presskit() tool (dopresskit.com) generates a clean, professional press page that journalists know and trust. It's a PHP-based tool you install on your web server, fill in your game's information, and it produces a standardized page that press are familiar with. Journalists have been using presskit() pages for over a decade — when they see one, they know exactly where to find what they need.

If you don't have a web server or don't want to use presskit(), alternatives include:

- **A dedicated page on your website** with downloadable assets and clear sections
- **A Notion page** made public (quick to set up, easy to update)
- **A Google Drive folder** with organized subfolders (screenshots, key art, logos, press release) — functional but less professional
- **itch.io's press kit features** if you're also publishing there

**What journalists actually look for first:**

1. Screenshots they can use immediately (high-res, no watermarks)
2. A trailer they can embed
3. A one-paragraph description they can copy-paste
4. A way to get a key without jumping through hoops

Everything else is secondary. If you nail those four things, your press kit is good enough.

**Common mistake:** Making journalists work to find your assets. If your screenshots are scattered across tweets, your trailer is unlisted on YouTube with no direct link, and getting a key requires a three-email chain — nobody will cover your game. Make it frictionless.

> **Try this now:** Open your game's current website or Steam page. If a journalist landed there right now, could they find everything they need to write about your game in under 60 seconds? If not, that's your immediate to-do.

---

### 3. Writing the Outreach Email — The Three-Question Formula

Your outreach email needs to answer three questions in the first two sentences:

1. **What is the game?** (Genre, core hook, one sentence)
2. **What's interesting about it?** (Why it's notable, what makes it stand out)
3. **Why should they care *right now*?** (Upcoming launch, new demo, an event, a milestone)

That's the formula. Here's what it looks like in practice:

**A bad outreach email:**

> Dear Sir/Madam,
>
> My name is Alex and I'm a solo indie developer working on an exciting new project. I've been developing games for three years and this is my most ambitious work yet. The game features innovative combat mechanics, a rich story, and beautiful pixel art. I believe your audience would really enjoy it.
>
> I was hoping you could take a look and maybe do a video about it? Please let me know if you're interested and I can send more information.
>
> Thank you for your time,
> Alex

**Why it fails:** No game name in the first paragraph. No genre. No hook. No reason to care right now. "Dear Sir/Madam" screams generic blast. "Maybe do a video about it" is vague and passive. The journalist has to reply asking basic questions before they can even evaluate if they're interested.

**A good outreach email:**

> Hi [Name],
>
> [Game Name] is a turn-based tactical roguelike where you lead a crew of space pirates through procedurally generated nebula encounters — think Into the Breach meets FTL with a pirate radio soundtrack. It launches on Steam on [date].
>
> I saw your recent video on Cobalt Core and thought you might enjoy [Game Name] for similar reasons — the tactical depth is there, but we lean harder into crew management and narrative events between battles.
>
> Here's the press kit with screenshots, trailer, and a Steam key: [link]
>
> Happy to answer any questions or provide additional footage if it'd be helpful.
>
> Thanks,
> [Your name]
> [Your game's Steam page link]

**Why it works:** The journalist knows exactly what the game is by the second sentence. The personalization (referencing their Cobalt Core video) shows you actually watch their content. The press kit link gives them everything they need. The key is already available. The whole email is five sentences plus a sign-off.

**Subject line matters:** Your subject line should include your game's name and the reason you're emailing. Good: "[Game Name] — Launch Key & Press Kit (launches March 15)". Bad: "Exciting new indie game opportunity!"

**Personalization is non-negotiable.** Every email needs at least one specific reference to the recipient's work. This means you need to actually look at their content before emailing. Yes, this takes time. Yes, it's worth it. A personalized email to 30 people will get more responses than a generic blast to 300.

**Common mistake:** Writing a novel. Your email should be readable in 30 seconds. Journalists and creators get dozens of pitches per day. If your email requires scrolling, it's too long.

> **Try this now:** Write a draft outreach email for your game using the three-question formula. Time yourself — if it takes more than 10 minutes, you're overthinking it. Read it aloud. Does it sound like a human being wrote it? If it sounds like marketing copy, rewrite it in your natural voice.

---

### 4. Building Your Press and Creator List

A great outreach email means nothing if you're sending it to the wrong people. Building a targeted press list is one of the most time-intensive parts of marketing, but it pays dividends because you'll use this list for your entire game's lifecycle — and potentially your next game too.

**Where to find relevant press and creators:**

**For YouTubers and streamers:**
- Search YouTube for videos about games similar to yours. Look at who covered them.
- Check the "Similar Channels" section on relevant creators' pages.
- Browse Twitch under your game's genre category. Note who's streaming similar games.
- Use Keymailer's creator directory to find verified creators by genre.
- Look at who reviewed your competitor games on Steam — some reviewers are also content creators.

**For written press:**
- Search Google News for articles about games in your genre.
- Check which outlets covered games similar to yours.
- Look at the "press" sections on successful indie games' websites — they often list who covered them.
- Follow gaming journalists on Twitter/X — many openly share their beat and what they're looking for.

**What to record in your spreadsheet:**

| Column | Why |
|--------|-----|
| Name | The person, not just the outlet |
| Outlet/Channel | Where they publish |
| Email | Their press contact email |
| Subscriber/follower count | For prioritization |
| Genre coverage | What types of games they cover |
| Recent relevant video/article | For personalization reference |
| Date contacted | Tracking |
| Response | What they said (or didn't) |
| Key sent? | Yes/no, which platform |
| Coverage link | If they covered your game |

**Tiering your list:**

Organize your contacts into tiers:

- **Tier 1 (5-10 contacts):** Perfect genre match, engaged audience, most likely to cover you. These get the most personalized emails and earliest outreach.
- **Tier 2 (15-25 contacts):** Good genre overlap, decent audience size. Personalized but less individually researched.
- **Tier 3 (25-50 contacts):** Broader gaming coverage, worth reaching out to but lower probability. Can use a slightly more templated approach (still personalized subject lines and opening sentences).

**The magic range for indie games:** Creators with 10,000 to 100,000 subscribers are your sweet spot. They're large enough to drive meaningful traffic, small enough to be accessible, and hungry enough for interesting content that they'll actually play your game and give it a fair shot.

**Common mistake:** Confusing channel size with relevance. A 500K-subscriber channel that covers every genre is less valuable than a 30K-subscriber channel that exclusively covers your genre. The smaller channel's audience is pre-qualified — they already like the type of game you're making.

---

### 5. Key Distribution and Avoiding Scams

Steam keys are valuable. Every key you give away is a potential sale you won't make. That's fine when the key goes to someone who'll create content that drives many more sales — but there's an entire ecosystem of fake press outlets and key scammers trying to get free keys they'll resell on gray-market sites like G2A and Kinguin.

**Key distribution platforms:**

| Platform | What it does | Cost |
|----------|-------------|------|
| Keymailer | Connects developers with verified press and creators. Creators apply for keys, you approve them. | Free tier available |
| Woovit | Similar to Keymailer, with audience verification for creators | Free tier available |
| distribute() | Rami Ismail's key distribution tool with built-in vetting | Free |
| Manual (spreadsheet) | You track everything yourself | Free but labor-intensive |

**How to vet key requests:**

When someone emails asking for a key, check:

1. **Does this person exist?** Search their name/outlet. Do they have a real website, YouTube channel, or social media presence?
2. **Is their email legitimate?** Press contacts from real outlets use organizational email addresses (name@outlet.com), not Gmail accounts. YouTubers typically have a business email in their "About" section — verify the request came from that address.
3. **Do they cover your genre?** A channel that exclusively covers FPS games isn't going to meaningfully cover your cozy farming sim, no matter how many subscribers they have.
4. **What's their audience size?** There's no minimum, but a channel with 12 subscribers asking for a key is almost certainly a scammer or someone whose coverage won't move the needle.
5. **Is the email suspiciously generic?** Scam emails often say something like "I am a content creator with a large following and would love to review your game." No channel name, no specific reference to your game, no link to their content. This is a mass email sent to hundreds of developers.

**Red flags for key scams:**

- Email from a generic Gmail/Yahoo address claiming to represent an outlet
- No link to their channel or content in the email
- Asking for multiple keys ("for my team to review")
- Vague description of their audience with no verifiable numbers
- Email domains that look similar to real outlets but are slightly different (e.g., "pcgamer-reviews.com" instead of "pcgamer.com")
- Requesting keys before your game is even announced publicly

**The 50/500 rule:** It's better to distribute 50 keys to the right people than 500 keys to strangers. Every key that ends up on a resale site costs you a sale and provides zero marketing value. Be generous with creators you've vetted, and ruthless with everyone else.

**How to actually send keys:**

1. Generate keys in Steamworks (Partners → App → CD Keys → Generate Keys)
2. For vetted contacts: send the key directly in an email, clearly labeled
3. For platforms like Keymailer: upload keys in bulk and let the platform handle distribution
4. Keep a log of every key sent: who received it, when, and whether they created content

**Common mistake:** Sending keys proactively to people who didn't ask. This rarely results in coverage and often results in the key being forgotten or wasted. Instead, provide a link where interested parties can request a key, and then vet each request.

> **Try this now:** Google your game's name (or a similar game's name) plus "key request" or "review key." See what comes up. This is what the scam landscape looks like — and why vetting matters.

---

### 6. Timing Your Outreach Campaign

Sending the right email to the right person at the wrong time is almost as bad as sending the wrong email. Press and creators have lead times, and your outreach needs to respect those timelines.

**The outreach timeline:**

| When | What to do |
|------|-----------|
| 3-6 months before launch | Start building your press list. Follow relevant creators, note their email addresses and content patterns. |
| 2-4 weeks before launch | **First outreach wave.** Send your primary emails to Tier 1 contacts. Include press kit, key offer, and your launch date. |
| 1-2 weeks before launch | **Send keys.** Anyone who responded positively gets a key now. Send a brief follow-up to Tier 1 contacts who didn't respond. Begin outreach to Tier 2 contacts. |
| 1 week before launch | **Follow-up wave.** Brief, one-sentence follow-up to anyone who didn't respond. "Just wanted to make sure this didn't get lost — [Game Name] launches next [day]." Reach out to Tier 3 contacts. |
| Launch day | **"We're live" email.** Short email to everyone on your list: the game is now available, here's the Steam link, keys are still available for anyone who wants to cover it. |
| 1-2 weeks after launch | **Post-launch follow-up.** Email anyone who covered your game to thank them. Reach out to creators who missed the launch — post-launch coverage still drives sales. |

**Why 2-4 weeks before launch is the sweet spot:**

- Too early (2+ months): Creators won't remember your game by launch. They cover dozens of games; yours needs to be fresh in their mind.
- Too late (less than 1 week): Most creators need time to play the game, record footage, edit a video, and schedule publication. A week is tight. A day is impossible.
- The sweet spot gives them enough time to play, produce content, and publish around your launch day.

**Embargo vs. no embargo:**

An embargo is an agreement that press won't publish their coverage before a specific date (usually your launch day). Embargoes make sense for AAA games with coordinated global launches. For most indie games, don't bother with embargoes — any coverage at any time is good. If someone wants to publish early, let them. Pre-launch coverage builds wishlists.

**Common mistake:** Sending one email and giving up. Journalists get hundreds of emails. A polite follow-up one week later isn't pushy — it's professional. Many successful coverage placements happen because of the follow-up, not the initial email.

---

### 7. Managing Relationships, Not Transactions

The best press strategy isn't a one-time blast — it's an ongoing relationship with the people who cover your genre. A creator who covers your first game is much more likely to cover your second game, your updates, and your next project. Building these relationships is a long-term investment.

**How to build lasting press relationships:**

**Before you need them:**
- Follow creators who cover your genre on social media
- Engage genuinely with their content — comment on videos, share articles, join discussions
- Don't be the developer who only shows up when they need something
- Share their content with your community when it's relevant

**During outreach:**
- Be human. You're a person emailing another person, not a marketing department issuing a press release.
- Respect their time. Short emails, clear asks, no guilt trips.
- Accept "no" gracefully. Not everyone will cover your game, and that's fine.
- Make their job easy. Everything they need should be one click away.

**After coverage:**
- Thank them. A brief, genuine thank-you email goes a long way.
- Share their coverage on your social channels and tag them.
- Don't complain about criticism. If their review points out legitimate flaws, take the feedback gracefully.
- Keep them updated on major milestones (big updates, awards, sales figures they can reference).

**What NOT to do:**

- Don't send mass emails where everyone is CC'd (or even BCC'd with an obvious template)
- Don't follow up more than twice if someone doesn't respond
- Don't publicly complain about negative coverage
- Don't offer payment for positive coverage (this is different from paid sponsorships, which are disclosed — it's asking someone to lie)
- Don't take it personally. Press coverage is a business decision, not a judgment of your game's worth.

**The relationship flywheel:** Developer sends game → Creator covers it → Developer shares and thanks them → Creator's audience discovers developer → Creator follows developer's work → Developer's next game gets covered more easily → Repeat.

**Common mistake:** Treating outreach as a transaction rather than a relationship. The developers who consistently get covered are the ones who engage with the press community year-round, not just when they have something to sell.

> **Try this now:** Pick three YouTubers or writers who cover games in your genre. Watch or read their most recent content. Follow them on social media. Leave a genuine comment on their latest piece. You've just planted the seed for a future outreach relationship — and it took less than 15 minutes.

---

### 8. Measuring Outreach Success and Iterating

You've sent your emails, distributed your keys, and launch week is over. Now what? Understanding what worked — and what didn't — helps you improve for your next game, your next major update, and every outreach campaign after that.

**What to track:**

| Metric | How to find it | What it tells you |
|--------|---------------|-------------------|
| Email open rate | If using a mail merge tool (GMass, Mailchimp) | Whether your subject lines work |
| Response rate | Your inbox | Whether your emails are compelling |
| Key redemption rate | Steamworks → CD Keys | How many keys were actually used vs. ignored/resold |
| Coverage rate | Manual tracking | Percentage of contacts who created content |
| Traffic from coverage | Steam UTM links, referral data | How much traffic each piece of coverage drove |
| Wishlist/sales attribution | Correlate coverage dates with Steam traffic spikes | Which coverage had the biggest impact |

**Typical response rates for indie outreach:**

Don't be discouraged by low numbers. These are industry norms:

- **Email response rate:** 10-20% is good. Most emails go unanswered.
- **Coverage rate (of those who responded):** 30-50%. Not everyone who responds will cover your game.
- **Overall coverage rate (all contacts):** 5-15%. That's normal.
- **Key redemption rate:** Aim for 70%+. Below 50% suggests you're distributing too broadly.

**What these numbers mean in practice:** If you email 50 people, expect 5-10 responses, and 3-5 pieces of coverage. If you email 100 people, expect 10-20 responses, and 5-15 pieces of coverage. Quality targeting matters more than volume.

**How to correlate coverage with sales:**

Steam doesn't give you direct referral attribution, but you can:

1. Watch your Steam traffic dashboard on the days coverage goes live
2. Note which days had the biggest traffic spikes
3. Match those spikes to specific pieces of coverage
4. Over time, you'll learn which types of coverage (and which specific creators) drive the most traffic

**Iterating for next time:**

After your outreach campaign, review:

- Which email subject lines got the most opens?
- Which email templates got the most responses?
- Which tier of contacts had the highest coverage rate?
- Which pieces of coverage drove the most traffic?
- What questions did press contacts ask that you should have addressed in your initial email?
- What assets did creators request that you should include in your press kit?

Use these answers to refine your approach for your next game's outreach — or for outreach around major updates to this game.

**Common mistake:** Not tracking anything. You send a bunch of emails, get some coverage, and have no idea what worked. Without data, you can't improve. Even a simple spreadsheet with "contacted / responded / covered / traffic spike" columns gives you actionable information.

---

## Case Studies

### Case Study 1: Vampire Survivors — The Streamer Snowball

**What happened:** Vampire Survivors, developed by solo developer Luca Galante (poncle), became one of the most successful indie games in history — largely through organic streamer and YouTuber coverage rather than traditional press outreach.

**What they did right:**
- The game was inherently "streamable" — visually chaotic, easy to understand, and satisfying to watch even without playing
- Early access pricing ($2.99) made it a zero-risk impulse buy for anyone who saw a stream
- The developer engaged directly with the community on social media and Discord, creating a feedback loop that kept the game in conversation
- Rather than controlling the narrative, Galante let streamers and YouTubers discover the game organically and amplify it

**The lesson:** Your game's inherent watchability matters as much as your outreach strategy. If your game creates moments that are fun to watch, streamers will seek it out. While most games can't replicate this level of organic discovery, you can think about what makes your game interesting to *watch*, not just to play, and emphasize those moments in your outreach materials.

**What you can apply:** When creating your press kit and outreach emails, lead with the most visually engaging and immediately understandable aspects of your game. If a creator can see in 5 seconds why their audience would enjoy watching this game, you've won half the battle.

---

### Case Study 2: Unpacking — The Targeted Press Campaign

**What happened:** Unpacking, developed by Witch Beam, executed a masterful press and influencer campaign that built massive anticipation before launch through targeted, perfectly timed outreach.

**What they did right:**
- Witch Beam identified that their game appealed to an audience beyond traditional "gamers" — people who liked ASMR, organization, interior design, and cozy content
- They reached out to creators outside the usual gaming press — lifestyle YouTubers, organization-focused TikTokers, and ASMR channels
- Their press kit was immaculate: beautiful screenshots, a perfectly paced trailer, and clear, evocative descriptions
- Demo availability at events and during Steam Next Fest let the game speak for itself
- They timed their outreach so that coverage cascaded — niche outlets first, building buzz that attracted larger outlets

**The lesson:** Know your audience, even — especially — when your audience isn't the "typical" gamer. Unpacking's marketing succeeded because they looked beyond obvious press contacts and found creators whose audiences would genuinely love the game.

**What you can apply:** Think about which non-gaming communities might enjoy your game. A crafting game might appeal to DIY YouTubers. A cooking game might interest food bloggers. A music game might get traction with musicians. Expanding your outreach beyond gaming press can unlock audiences your competitors never reach.

---

### Case Study 3: Celeste — The Long-Tail Press Relationship

**What happened:** Celeste, by Maddy Thorson and Noel Berry (Extremely OK Games), maintained press relevance for years after launch through consistent updates, community engagement, and a willingness to talk openly about the game's themes and development.

**What they did right:**
- The developers were genuinely accessible — they responded to press inquiries quickly and openly
- They discussed the game's themes (mental health, gender identity) honestly, giving journalists compelling angles beyond "new platformer launches"
- Major content updates (like the Chapter 9 DLC) were treated as opportunities for renewed press outreach
- They shared development insights that made for interesting stories beyond just the game itself
- Their transparency about sales numbers and the game's reception gave press data-driven stories to write

**The lesson:** Press relationships don't end at launch. The developers who stay accessible, share interesting stories, and treat updates as press opportunities continue to get coverage long after their launch week. Every piece of post-launch coverage drives new sales.

**What you can apply:** Think about what stories your game (and your development journey) can tell beyond "game launches on date." Personal stories, development challenges, community responses, update announcements — all of these are angles that press can cover. Keep your press contacts warm with occasional updates, even when you're not actively promoting something.

---

## Exercises

### Exercise 1: Build Your Press Kit (2-3 hours)

Create a complete press kit for your game.

**Steps:**
1. Choose your format: presskit() (dopresskit.com), a page on your website, or a clean Notion page
2. Write your one-line pitch (one sentence that explains your game)
3. Write your short description (2-3 paragraphs covering genre, hook, key features)
4. Gather your assets: 6-10 high-res screenshots, key art, logo, trailer link, 3-5 GIFs
5. Create your factsheet: developer name, platform, release date/window, price, engine
6. Add contact information and a clear key request process
7. Organize everything and test the page — click every download link, watch the embedded trailer, check that images display correctly
8. Send the press kit link to a friend or fellow developer and ask: "Could you write about my game using only this page?"

**Stretch goal:** Create separate press kits for different types of outreach — one for gaming press (emphasizes mechanics and genre), one for lifestyle/mainstream press (emphasizes accessibility and unique appeal).

---

### Exercise 2: Write Your Outreach Template (1 hour)

Create a personalized outreach email template using the three-question formula.

**Steps:**
1. Write the core email: what is the game, what's interesting, why now
2. Identify three "personalization slots" where you'll insert creator-specific references
3. Write three different versions of your opening sentence, each referencing a different creator's recent work
4. Draft your subject line (include game name and the reason you're emailing)
5. Read each version aloud. Does it sound like a human being? Would you respond to this email?

**Stretch goal:** Write a separate template for each tier: a highly personalized Tier 1 version, a moderately personalized Tier 2 version, and an efficient Tier 3 version. All three should still follow the three-question formula.

---

### Exercise 3: Build Your Press Contact Spreadsheet (2-3 hours)

Research and compile a targeted list of press contacts and content creators.

**Steps:**
1. Search YouTube for videos about 3-5 games similar to yours. Note every creator who covered them.
2. Search Google for written coverage of those same games. Note the outlets and authors.
3. Check Keymailer's creator directory for relevant creators in your genre.
4. For each contact, find: their name, outlet/channel, email, subscriber/follower count, and a recent relevant piece of content.
5. Organize your list into tiers: Tier 1 (perfect genre match, 5-10 contacts), Tier 2 (good overlap, 15-25 contacts), Tier 3 (broader gaming coverage, 25-50 contacts).
6. For each Tier 1 contact, write a one-sentence personalization note you'll use in your outreach email.

**Stretch goal:** Find 5 creators outside the gaming press whose audience might enjoy your game. Think lifestyle, ASMR, education, art, music — whatever fits your game's themes.

---

### Exercise 4: Simulate an Outreach Campaign (1-2 hours)

Practice the full outreach workflow without actually sending anything.

**Steps:**
1. Pick 5 contacts from your Tier 1 list
2. Write a fully personalized outreach email for each one (using your template from Exercise 2)
3. Write a follow-up email for each one (one week later scenario)
4. Write a "we're live" launch-day email for your full list
5. Create a tracking spreadsheet with columns: contact, tier, date emailed, date followed up, response, key sent, coverage link
6. Review all five emails — are they each genuinely personalized? Do they pass the "would I respond to this?" test?

**Stretch goal:** Have a fellow developer review your emails and give honest feedback. Are they too long? Too generic? Missing key information? Outside perspective catches blind spots you can't see yourself.

---

## Recommended Reading

| Resource | Type | What you'll learn |
|----------|------|-------------------|
| [presskit() by Rami Ismail](https://dopresskit.com/) | Tool | The standard tool for creating indie game press kits |
| [How to Email the Press About Your Indie Game](https://howtomarketagame.com/2021/06/28/how-to-email-the-press-about-your-indie-game/) | Article | Chris Zukowski's guide to outreach emails that get responses |
| [Keymailer](https://www.keymailer.co/) | Platform | Managing key distribution to verified content creators |
| [Woovit](https://woovit.com/) | Platform | Alternative key distribution with audience verification |
| [How to Get Press Coverage for Your Indie Game](https://www.gamesindustry.biz/how-to-get-press-coverage-for-your-indie-game) | Article | GamesIndustry.biz guide to press outreach |
| [distribute() by Rami Ismail](https://dodistribute.com/) | Tool | Free key distribution tool with built-in vetting |
| [The YouTuber's Guide to Getting Review Copies](https://www.youtube.com/watch?v=example) | Video | Understanding the creator's perspective on key requests |
| [Game Press Resources List](https://github.com/게임-press-resources) | Repository | Community-maintained list of gaming outlets and contacts |

---

## Key Takeaways

- **Build your press kit before you email anyone.** A professional press kit with downloadable assets, a clear description, and a key request process is the foundation of all outreach.
- **Use the three-question formula.** Every outreach email should answer: what is the game, what's interesting about it, and why should they care right now — in the first two sentences.
- **Personalization isn't optional.** A personalized email to 30 contacts outperforms a generic blast to 300. Reference specific content the person has created.
- **Target the right size, not the biggest size.** Mid-tier YouTubers (10K-100K subs) in your genre are more valuable than mega-channels that cover everything.
- **Vet every key request.** Use platforms like Keymailer and Woovit. Check email addresses, verify channels, and never distribute keys to unverified contacts.
- **Time your outreach 2-4 weeks before launch.** Too early and they'll forget; too late and they won't have time to create content.
- **Follow up once, politely.** Many successful placements come from the follow-up, not the initial email. One follow-up is professional; three is spam.
- **Build relationships, not transactions.** The creators who cover your first game are your best contacts for your second game. Engage with their work year-round, not just when you need something.

---

## What's Next?

You've built your press kit and outreach strategy. Now you need a trailer that makes creators — and their audiences — excited about your game:

→ [Module 6: Trailers That Actually Work](module-06-trailers-that-actually-work.md)

You'll also want to coordinate your press outreach with your launch strategy:

→ [Module 7: Launch Strategy & The First Week](module-07-launch-strategy-first-week.md)
