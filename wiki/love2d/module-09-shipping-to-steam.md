# Module 9: Shipping to Steam

**Part of:** [LOVE2D Learning Roadmap](love2d-learning-roadmap.md)
**Estimated study time:** 8-15 hours
**Prerequisites:** [Module 8: Build Your First Real Game](module-08-build-first-game.md)

---

## Overview

You have a finished game. People can play it. Now the question is: where do they find it?

Steam is the largest PC game distribution platform in the world. Getting your game on Steam means access to hundreds of millions of potential players, built-in payment processing, community features, and an algorithm that can surface your game to interested players. It also means a $100 upfront fee, a 30% revenue cut, and competition with thousands of other games releasing every month.

This module covers the entire pipeline: deciding if Steam is right for your game, setting up your store presence, building distributable executables, integrating Steamworks features, uploading builds, and managing your launch. It also covers itch.io as an alternative (or complement) -- because for a first game, itch.io might be the smarter starting point.

A reality check before we start: most first games do not make significant money on Steam. That is fine. The goal is to learn the full pipeline so that your second and third games are positioned to succeed. Shipping to Steam is a skill, just like making the game itself.

---

## Core Concepts

### Is Steam Right for Your First Game?

Be honest with yourself. Steam is a professional marketplace. Players have high expectations. A game that would be warmly received on itch.io ("nice little jam game!") might get negative reviews on Steam ("too short, not enough content, feels like a prototype").

**When Steam makes sense:** Your game has 30+ minutes of content, a polished UI, working audio, and a clear identity. You are prepared to create professional-quality capsule art and screenshots. You want to learn the Steamworks pipeline for future games.

**When itch.io makes more sense:** Your game is small (under 30 minutes), experimental, or your first-ever shipped project. You want quick feedback without the overhead. You are not ready to invest $100 and several days of setup.

**The pragmatic approach:** Ship to itch.io first. Get feedback. If the response is positive and you want to invest further, bring it to Steam. Many successful indie games started on itch.io before moving to Steam.

The $100 Steamworks fee is recoupable -- you get it back once your game earns $1,000 in revenue. Steam takes a 30% cut of all sales (dropping to 25% after $10M and 20% after $50M, which is not your immediate concern). Factor this into pricing decisions.

### Alternative Platforms

**itch.io** is the best starting point for indie developers. No fee to publish. You set your own revenue split (including 0% to itch.io if you want). Built-in payment processing. Simple upload process. Supportive community. The downside: much less traffic than Steam. You will need to drive your own audience.

**GOG** is curated. They reject most submissions. If your game has a retro aesthetic or strong narrative, it might fit. Otherwise, do not count on it for a first game.

**Epic Games Store** is even more curated and generally targets higher-profile releases. Not a realistic option for a first LOVE game.

**Direct sales** (your own website with something like Stripe or Gumroad) give you the highest revenue per sale but require you to handle everything: payment processing, download delivery, update distribution, refunds. Only worth it if you have an existing audience.

**Multi-platform strategy:** Ship on itch.io and Steam simultaneously. They are not mutually exclusive. Some players prefer itch.io for DRM-free downloads. Some prefer Steam for the library integration. Let them choose.

### Steamworks Setup

The process starts at [partner.steamgames.com](https://partner.steamgames.com):

1. **Create a Steamworks account.** You need a regular Steam account first, then apply for a Steamworks partner account.
2. **Pay the $100 app credit fee.** This is per-game, not per-account. It is recoupable after $1,000 in adjusted gross revenue.
3. **Create your app.** Navigate to "Create New App" in the Steamworks dashboard. You will get an **App ID** -- this is the unique identifier for your game on Steam. You will use this number in your Steamworks integration code.
4. **Navigate the dashboard.** The Steamworks dashboard is large and occasionally confusing. The key sections are: Store Page (your public listing), Depots (your build uploads), and Technical Tools (SDK downloads, SteamCMD).

The dashboard has a learning curve. Budget an hour just to explore it before trying to configure anything. Valve provides video walkthroughs in their documentation.

### Store Page Essentials

Your store page is your game's shopfront. It is the first thing potential players see, and it determines whether they click "Add to Wishlist" or scroll past.

**Capsule art** is the most important visual asset. Steam uses several sizes:

| Image | Size | Where It Appears |
|---|---|---|
| Header Capsule | 460 x 215 | Search results, featured lists |
| Main Capsule | 616 x 353 | Top of your store page |
| Small Capsule | 231 x 87 | Wishlists, recommendations |
| Library Capsule | 600 x 900 | Player's Steam library |
| Library Hero | 3840 x 1240 | Library detail view background |

Your capsule art needs to include your game's title, be legible at small sizes, and look professional. This is not the place for programmer art. If you cannot make good capsule art yourself, budget $50-200 for a freelance artist. It is the single highest-ROI investment you can make.

**Screenshots** should show actual gameplay, not menus. Four to six screenshots that showcase different aspects of your game: action, environments, UI, variety. Capture them at your game's native resolution.

**Description** should answer three questions in the first two sentences: What is this game? What do you do in it? Why is it fun? Then expand with a feature list. Do not oversell. Players who feel misled leave negative reviews.

**Tags** help Steam's algorithm recommend your game. Pick the most specific, accurate tags. "Indie" is too broad. "Top-Down Shooter" or "Roguelike Deckbuilder" tells the algorithm who might enjoy it.

**The "Coming Soon" strategy:** Publish your store page as "Coming Soon" weeks or months before launch. This lets players wishlist your game. Wishlists are the single most important metric for launch success. Steam notifies wishlisters when your game releases, creating a burst of first-day traffic. Launching without a Coming Soon period means launching with zero wishlists, which is launching into silence.

### Building LOVE Games for Distribution

The fusing process creates standalone executables that do not require LOVE to be installed on the player's machine.

**Windows (the most important platform by player count):**

```bash
# 1. Create the .love file
zip -9 -r mygame.love . -x "*.git*" -x "builds/*"

# 2. Fuse with love.exe
cat love-win64/love.exe mygame.love > builds/win64/mygame.exe

# 3. Copy all DLLs to the same directory
cp love-win64/*.dll builds/win64/
```

The final folder should contain: `mygame.exe`, `love.dll`, `lua51.dll`, `mpg123.dll`, `msvcp120.dll`, `msvcr120.dll`, `OpenAL32.dll`, `SDL2.dll`. Missing any of these causes crashes on machines that do not have LOVE installed. This is the number one distribution bug.

**macOS:**

```bash
# 1. Copy the LOVE.app bundle and rename
cp -R love.app builds/MyGame.app

# 2. Place .love inside the bundle
cp mygame.love builds/MyGame.app/Contents/Resources/

# 3. Update Info.plist
# Change CFBundleIdentifier to com.yourstudio.mygame
# Change CFBundleName to "My Game"
```

macOS builds face a code signing challenge. Without an Apple Developer certificate ($99/year), macOS Gatekeeper will warn users that the app is from an unidentified developer. The workaround: tell users to right-click the app and select "Open" the first time. For Steam distribution, Valve's infrastructure partially addresses this.

**Linux:**

The simplest approach is shipping the `.love` file with a shell script:

```bash
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
love "$DIR/mygame.love"
```

This requires the user to have LOVE installed. For a standalone build, use an AppImage or bundle the LOVE runtime.

**conf.lua for distribution:**

```lua
function love.conf(t)
    t.identity = "mygame"           -- NEVER change after release
    t.version = "11.5"
    t.console = false               -- MUST be false for release
    t.window.title = "My Game"
    t.window.icon = "assets/icon.png"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
end
```

### Build Automation

**makelove** is the recommended build tool. Install with pip, configure with a `makelove.toml` file:

```toml
name = "mygame"
love_version = "11.5"
default_targets = ["win64", "macos"]

[build]
# Files/directories to exclude from the .love archive
excludes = [
    ".git", ".gitignore", "*.md", "builds",
    "makelove.toml", "*.aseprite", "TODO*"
]
```

Then build:

```bash
makelove              # builds all default targets
makelove win64        # just Windows
makelove --version 1.0.0  # tags the build with a version
```

**GitHub Actions** can automate builds on every push or tag:

```yaml
# .github/workflows/build.yml
name: Build
on:
  push:
    tags: ['v*']
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.x'
      - run: pip install makelove
      - run: makelove
      - uses: actions/upload-artifact@v4
        with:
          name: builds
          path: makelove-build/
```

### Steamworks Integration

**luasteam** provides Lua bindings for the Steamworks SDK. It lets you unlock achievements, use cloud saves, detect the Steam overlay, and more.

Install by downloading the pre-built binaries from the [luasteam releases page](https://github.com/uspgamedev/luasteam/releases) and placing the shared library (`.dll`, `.dylib`, or `.so`) in your project's `lib/` directory.

**Minimal integration module:**

```lua
-- steam.lua
local Steam = {}
local hasSteam = false
local luasteam = nil

function Steam.init()
    local ok, mod = pcall(require, "luasteam")
    if not ok then
        print("luasteam not found -- running without Steam")
        return false
    end
    luasteam = mod
    hasSteam = luasteam.init()
    if not hasSteam then
        print("Steam not running -- continuing without Steam features")
    end
    return hasSteam
end

function Steam.update()
    if hasSteam then luasteam.runCallbacks() end
end

function Steam.shutdown()
    if hasSteam then luasteam.shutdown() end
end

function Steam.unlockAchievement(id)
    if not hasSteam then return end
    luasteam.userStats.setAchievement(id)
    luasteam.userStats.storeStats()
end

function Steam.cloudWrite(filename, data)
    if not hasSteam then return false end
    return luasteam.remoteStorage.write(filename, data)
end

function Steam.cloudRead(filename)
    if not hasSteam then return nil end
    return luasteam.remoteStorage.read(filename)
end

return Steam
```

The critical design principle: **everything degrades gracefully.** If luasteam is missing (itch.io build), or Steam is not running, or an API call fails, the game continues without Steam features. Never let Steamworks bugs prevent the player from playing.

Wire it into `main.lua`:

```lua
local Steam = require("steam")

function love.load()
    Steam.init()
end

function love.update(dt)
    Steam.update()
end

function love.quit()
    Steam.shutdown()
end
```

### The Depot System

Steam uses **depots** to manage game builds. A depot is a collection of files that makes up your game for a specific platform. You typically have one depot per platform: Windows, macOS, Linux.

**Depot configuration** lives in VDF files (Valve Data Format):

```
"DepotBuildConfig"
{
    "DepotID" "YOUR_DEPOT_ID"
    "ContentRoot" "./builds/win64/"
    "FileMapping"
    {
        "LocalPath" "*"
        "DepotPath" "."
        "recursive" "1"
    }
    "FileExclusion" "*.pdb"
}
```

**Uploading with SteamCMD:**

```bash
steamcmd +login your_username +run_app_build /path/to/app_build.vdf +quit
```

SteamCMD handles incremental uploads -- only changed files are re-uploaded after the first time. The initial upload can take a while; subsequent updates are fast.

**Branch management:** Steam supports branches (called "betas" in the dashboard). The `default` branch is what players get. You can create a `testing` branch for beta testers. This lets you push updates to testers before rolling them out to everyone.

### Pre-Release Checklist

Before hitting the release button:

- [ ] Windows build runs on a clean machine (no LOVE installed)
- [ ] macOS build opens without crashing (right-click > Open for unsigned)
- [ ] Steam overlay works (Shift+Tab in-game)
- [ ] Achievements unlock correctly (test, then reset before launch)
- [ ] Cloud saves sync (test between two machines or by deleting local saves)
- [ ] Store page is complete: description, screenshots, capsule art, tags, system requirements
- [ ] Store page has been live as "Coming Soon" for at least 2 weeks
- [ ] Game has been reviewed and approved by Valve's review team
- [ ] You have a release date set in the Steamworks dashboard
- [ ] You have prepared an announcement post for launch day

### Post-Launch

**First week matters most.** Steam's algorithm judges your game primarily on first-week performance: sales velocity, review sentiment, refund rate. This is when your visibility is highest.

**Updates and patch notes.** Players expect bugs to be fixed. Post updates through Steam's announcement system with clear patch notes. Even small fixes show players you are active.

**Reviews.** Steam reviews are binary (thumbs up / thumbs down) and aggregate into an overall rating. Anything below "Mostly Positive" hurts sales. The best way to get positive reviews: make a game that works and is honest about what it is.

**Sales.** Steam runs seasonal sales (Summer, Autumn, Winter, Spring). Participating with a modest discount (10-20%) generates a visibility burst. Do not discount too heavily too early -- a 75% discount in month one signals desperation.

**Steam Next Fest** is one of the best visibility events for indie games. If you have a playable demo ready, Next Fest runs three times a year and gives prominent placement to games with demos. The wishlist bump can be significant.

---

## Code Walkthrough

### Complete Build Script

```bash
#!/bin/bash
# build.sh -- Create distributable builds
set -e

GAME_NAME="mygame"
VERSION="${1:-dev}"
BUILD_DIR="builds"
LOVE_DIR="love-binaries"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "=== Creating .love file ==="
zip -9 -r "$BUILD_DIR/$GAME_NAME.love" \
    *.lua assets/ lib/ conf.lua \
    -x "*.git*" "*.md" "builds/*" "love-binaries/*" "*.sh"

echo "=== Building Windows ==="
WIN_DIR="$BUILD_DIR/${GAME_NAME}-${VERSION}-win64"
mkdir -p "$WIN_DIR"
cat "$LOVE_DIR/love-win64/love.exe" "$BUILD_DIR/$GAME_NAME.love" \
    > "$WIN_DIR/$GAME_NAME.exe"
cp "$LOVE_DIR/love-win64/"*.dll "$WIN_DIR/"

echo "=== Building macOS ==="
MAC_DIR="$BUILD_DIR/${GAME_NAME}-${VERSION}-macos"
mkdir -p "$MAC_DIR"
cp -R "$LOVE_DIR/love-macos/love.app" "$MAC_DIR/$GAME_NAME.app"
cp "$BUILD_DIR/$GAME_NAME.love" \
    "$MAC_DIR/$GAME_NAME.app/Contents/Resources/"

echo "=== Creating archives ==="
cd "$BUILD_DIR"
zip -9 -r "${GAME_NAME}-${VERSION}-win64.zip" "${GAME_NAME}-${VERSION}-win64/"
zip -9 -r "${GAME_NAME}-${VERSION}-macos.zip" "${GAME_NAME}-${VERSION}-macos/"

echo "=== Done ==="
```

### Butler for itch.io

```bash
# One-time setup
butler login

# Upload builds
butler push builds/mygame-1.0-win64/ yourusername/mygame:win
butler push builds/mygame-1.0-macos/ yourusername/mygame:mac
```

---

## API Reference

### luasteam Functions

| Function | Description |
|---|---|
| `Steam.init()` | Initialize Steamworks. Returns boolean. Call in `love.load`. |
| `Steam.shutdown()` | Clean up. Call in `love.quit`. |
| `Steam.runCallbacks()` | Process Steam events. Call every frame. |
| `Steam.userStats.setAchievement(name)` | Unlock an achievement |
| `Steam.userStats.getAchievement(name)` | Check if unlocked. Returns boolean. |
| `Steam.userStats.storeStats()` | Push changes to Steam servers |
| `Steam.remoteStorage.write(name, data)` | Write string to Steam Cloud |
| `Steam.remoteStorage.read(name)` | Read string from Steam Cloud |
| `Steam.user.getSteamID()` | Get current user's Steam ID |

### SteamCMD Commands

| Command | Description |
|---|---|
| `steamcmd +login <user>` | Log in (prompts for password) |
| `+run_app_build <vdf>` | Upload a build |
| `+quit` | Exit after operations |

### Butler Commands

| Command | Description |
|---|---|
| `butler login` | Authenticate with itch.io |
| `butler push dir user/game:channel` | Upload a build |
| `butler status user/game` | Show current uploads |

---

## Libraries & Tools

| Tool | Purpose | URL |
|---|---|---|
| **makelove** | Build tool for LOVE games | [github.com/pfirsich/makelove](https://github.com/pfirsich/makelove) |
| **love-release** | Alternative build tool | [github.com/MisterDA/love-release](https://github.com/MisterDA/love-release) |
| **luasteam** | Steamworks bindings for Lua | [github.com/uspgamedev/luasteam](https://github.com/uspgamedev/luasteam) |
| **SteamCMD** | Command-line depot uploader | [developer.valvesoftware.com/wiki/SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD) |
| **Butler** | itch.io command-line uploader | [itch.io/docs/butler](https://itch.io/docs/butler/) |

---

## Common Pitfalls

**1. Missing DLLs in Windows builds.** Your dev machine has LOVE installed, so Windows finds the DLLs. Your player's machine does not. Always copy every `.dll` from the LOVE download into the same folder as your fused `.exe`. Test on a clean machine.

**2. macOS code signing headaches.** Without an Apple Developer certificate, Gatekeeper warns users. For itch.io distribution, tell macOS users to right-click and select "Open." For Steam, Valve's code signing helps but does not fully solve the issue.

**3. Wrong conf.lua identity.** If you forget `t.identity` or change it after release, players lose their save data. Set it before your first release. Never change it.

**4. Untested fused builds.** You test with `love .` during development. The fused build crashes because of a hardcoded path or missing asset. Test your fused build on every target platform, ideally on machines that are not your dev machine.

**5. Underestimating store page art.** You spend months on the game and twenty minutes on capsule art. Capsule art is the first thing anyone sees. Bad capsule art kills your conversion rate. Budget real time or money for it.

**6. Launching without a Coming Soon period.** You finish and release on the same day. Zero wishlists. Zero first-day notifications. Zero algorithmic support. Publish Coming Soon weeks before launch. Build wishlists. Even 500 is dramatically better than zero.

---

## Exercises

### Exercise 1: Build Fused Executables

**Time:** 1.5-2 hours

1. Install makelove: `pip install makelove`
2. Write a `makelove.toml` for your game
3. Build for Windows and macOS
4. Test the Windows build on a machine without LOVE installed

### Exercise 2: Publish to itch.io

**Time:** 2-3 hours

1. Create an itch.io account
2. Create a new game page
3. Upload builds using Butler
4. Write a description, upload screenshots and cover art
5. Publish and send the link to someone

### Exercise 3: Full Steam Setup (If Ready)

**Time:** 5-8 hours (spread over days due to review wait times)

1. Register on Steamworks and pay the $100 fee
2. Create your app and note your App ID
3. Create capsule art (header, main, library)
4. Set up the store page as "Coming Soon"
5. Configure a depot and upload a build via SteamCMD
6. Test the build through Steam (overlay, achievements if applicable)

---

## Recommended Reading & Resources

### Essential

| Resource | URL | What You Get |
|---|---|---|
| Steamworks Documentation | [partner.steamgames.com/doc](https://partner.steamgames.com/doc/home) | Official docs for depots, achievements, store pages |
| makelove | [github.com/pfirsich/makelove](https://github.com/pfirsich/makelove) | Build tool documentation |
| luasteam | [github.com/uspgamedev/luasteam](https://github.com/uspgamedev/luasteam) | Steamworks bindings with examples |
| LOVE Wiki: Game Distribution | [love2d.org/wiki/Game_Distribution](https://love2d.org/wiki/Game_Distribution) | Official fusing and distribution guide |

### Go Deeper

| Resource | URL | What You Get |
|---|---|---|
| Chris Zukowski's Blog | [howtomarketagame.com](https://howtomarketagame.com) | Data-driven Steam visibility and launch strategy |
| itch.io Publishing Guide | [itch.io/docs/creators](https://itch.io/docs/creators/getting-started) | Complete itch.io publishing reference |
| SteamCMD Documentation | [developer.valvesoftware.com/wiki/SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD) | Depot upload tool reference |
| Butler Documentation | [itch.io/docs/butler](https://itch.io/docs/butler/) | itch.io CLI upload tool |

---

## Key Takeaways

- **itch.io first, Steam later.** For a first game, itch.io gets you in front of players with zero cost. Steam is the professional pipeline, but the $100 and setup overhead are better invested once you have confidence.

- **A fused build is love.exe + your .love file + DLLs.** The concept is simple. The bugs are in missing DLLs, code signing, and untested builds. Use makelove to automate it.

- **Set `t.identity` before your first release and never change it.** This determines where saves go. Changing it means every player loses their progress.

- **Set `t.console = false` before shipping.** A command prompt alongside your game on Windows looks unprofessional and confuses players.

- **Steam integration should degrade gracefully.** If luasteam is missing or Steam is not running, the game still works.

- **Capsule art matters more than your description.** It is the first thing anyone sees. Budget real time for it.

- **Always use a Coming Soon period.** Wishlists before launch are the biggest factor in first-week sales.

---

## What's Next?

You have built a game, packaged it, and learned how to get it in front of players. Whether you launched on itch.io, Steam, or both, you now understand the full pipeline from first pixel to public release.

[Module 10: What's Next](module-10-whats-next.md) maps the paths forward: deeper into LOVE, moving to other engines, advanced topics, and how to grow as a game developer beyond the roadmap.

Back to the [LOVE2D Learning Roadmap](love2d-learning-roadmap.md).
