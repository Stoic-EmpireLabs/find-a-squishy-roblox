# Find a Squishy! — Hybrid Roblox Game Design Specification

**Date:** 2026-10-17
**Project:** `Find a Squishy!` (Roblox / Luau / Rojo 7.7.1)
**Target Audience:** Family Co-op & Competitive Play (Parent + Kids) & Public Roblox Top-30 Loop

---

## 1. Executive Summary & Core Vision

**Find a Squishy!** combines the two highest-performing Roblox formats into one seamless, tactile experience:
1. **Level-Gated Scavenger Hunt (*Find the Markers / Chomiks*):** Players explore 5 vibrant, themed biomes to track down hidden, disguised, and runaway Squishy Slimes. Players **cannot unlock the next level gate** until they find **all Slimes** in their current level.
2. **Tycoon Sanctuary & Heist Action (*Steal an Egg / Steal a Brainrot*):** Every Squishy Slime discovered spawns inside the player's personal **Base Sanctuary**, generating passive `$Coins/sec`. Players can spam-click their base Slimes for fidget-toy coin showers, evolve them into **Golden/Rainbow** variants, buy **Speed, Jump, Radar, and Slime-Slap** upgrades, or carry Legendary Boss Squishies back to base while dodging family tags!

---

## 2. The 5 Signature Gameplay Twists

### Twist 1: Living Slime Behaviors (`BehaviorType`)
Instead of static parts, Slimes in the world have interactive AI/physics behaviors:
- **`Static` / `Hidden`:** Classic tucked-away hiding spots (behind waterfalls, inside hollow trees, atop obbies).
- **`Disguised`:** Looks like a normal prop (e.g., Bush, Marshmallow, Toy Block, Cyber Crate, Lava Rock) until a player approaches within 18 studs—then it sprouts cartoon eyes, blushes, and jiggles!
- **`Runaway` (Shy Slime):** Pops a `"!"` alert when a player gets within 16 studs and hops away in bursts away from the player. Players must use Speed upgrades or corner it with a family member.
- **`BounceWake` (Sleepy Giant Slime):** Snoozes (`"Zzz..."` billboard) until a player jumps onto its head **3 times**, triggering a huge trampoline bounce and waking it up for collection.

### Twist 2: Squishy Morphing & Micro-Vent Puzzles
- Any Slime unlocked in the **Slimeopedia** has a **`[Morph!]`** button (plus a `[Unmorph / Normal]` button and a **`[Tiny Squishy Size]`** toggle).
- Morphing attaches a glowing, jiggling Squishy shell and face to the player character, gives them a custom bouncy walk effect, and shrinks their hitbox when in **Micro-Squishy Mode** (`0.4x` scale), allowing them to walk straight through **Tiny Mouse-Hole Vents** (`3.5 x 3.5` stud tunnels blocked to normal-sized avatars) that hide secret Slimes!

### Twist 3: Click-to-Squish Fidget Base & Rainbow Blender
- **Click-to-Squish Fever:** Every Squishy inside the player's Base Sanctuary has a `ClickDetector`. Clicking it pancakes the Slime flat with a fast spring tween, plays an escalating high-pitched squeak sound, bursts particles, and awards instant bonus coins (`+BaseRate * ComboMultiplier`).
- **Rainbow / Golden Gel Machine:** A pedestal in the player's base lets them spend coins to upgrade their base's **Gel Coating Tier**:
  - *Tier 0 (Normal):* `1.0x` Base Income
  - *Tier 1 (Golden Gel):* `2.0x` Base Income + Golden metallic shimmer on base Slimes
  - *Tier 2 (Rainbow Neon Gel):* `3.5x` Base Income + Cycling HSV Rainbow glow on base Slimes

### Twist 4: Boss Squishy "Carry & Rescue" Rush (*Steal an Egg* Loop)
- The final Slime of each level (`#5, #11, #18, #26, #35` — the **Level Boss / Legendary Squishy**) triggers a **Carry & Rescue Event** when touched:
  - Instead of instantly collecting, the Boss Squishy attaches above the player's head with a glowing beam and alarm banner (`"🏃 CARRYING BOSS SQUISHY! Run to the Safe Zone Gate!"`).
  - The carrier must run back to the **Level Entrance Safe Zone** (or their Base) within 45 seconds to bank and permanently unlock the Boss Squishy.
  - Other players (kids/Dad) see a beacon over the carrier and can either escort them or boop them with the **Slime Slap Glove** to snatch the carried Boss Squishy!

### Twist 5: Co-op "Buddy Buttons" & Pet Weight Fallback
- Each level features a **Co-op Vault** with two glowing pressure plates (`Plate A` and `Plate B`).
- Standing on both plates simultaneously (2 players in family co-op) lowers the vault laser door to reveal the level's **Co-op Squishy**.
- **Solo Fallback:** Every player has a **`[Drop Decoy Squishy Weight]`** button on their HUD (or near the plate) that drops a heavy helper Slime from their collection onto Plate B for 20 seconds so solo play is never soft-locked.

---

## 3. World Layout & 5 Level Biomes (35 Unique Slimes)

All geometry is generated procedurally on server startup via `WorldBuilder.server.luau` along the `-Z` axis starting from the Central Hub (`0, 0, 0`).

| Zone | Z-Range | Theme & Visual Palette | Slimes Required to Enter | Slimes in Zone | Special Features |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Hub Plaza & 6 Bases** | `+120` to `-40` | Bright grass plaza, neon fountain, 6 Tycoon Sanctuary Plots (3 Left, 3 Right) | `0` (Spawn) | `0` (Sanctuary) | Claimable plots, Cash Collector, Gel Blender, Upgrade Shop Pads, Base Laser Shield |
| **Level 1: Meadow Gardens** | `-40` to `-220` | Lush green hills, oak trees, wooden bridge over creek, picnic table, hollow bushes | `0` (Open) | **5 Slimes** (`#1–#5`) | Disguised Bush Slime, Sleepy Bridge Slime, Micro-Vent under hill, Co-op Picnic Vault, Boss King Sprout Carry |
| **Level 2: Candy Kingdom** | `-220` to `-400` | Pastel pink turf, giant lollipops, gumball obby towers, frosting waterfall, marshmallow pits | **5 / 5** Level 1 Slimes | **6 Slimes** (`#6–#11`) | Disguised Marshmallow, Runaway Gummy Bear Slime, Frosting Waterfall secret cave, Boss Cotton Candy Crown Carry |
| **Level 3: Toybox Bedroom** | `-400` to `-580` | Warm wood floor, giant ABC blocks, bouncy bed mattress trampoline, bookshelf climb, toy chest | **11 / 11** (L1+L2) | **7 Slimes** (`#12–#18`) | High-bounce Bed Trampoline (`Velocity` launchpad), Mouse-hole baseboard Micro-Vent, Runaway Wind-up Slime, Boss Mecha-Bot Carry |
| **Level 4: Neon Cyber Lab** | `-580` to `-760` | Dark slate & cyan/magenta neon grid, containment tubes, floating laser platforms, server racks | **18 / 18** (L1–L3) | **8 Slimes** (`#19–#26`) | Moving/elevated cyber platforms, Disguised Hologram Cube, Cyber Vent shaft, Co-op Mainframe Vault, Boss Glitch Core Carry |
| **Level 5: Magma & Crystal Caverns** | `-760` to `-960` | Basalt rock, glowing lava rivers (non-lethal bounce-back hazard), amethyst crystals, volcano peak | **26 / 26** (L1–L4) | **9 Slimes** (`#27–#35`) | Lava stepping stones, Crystal Spire high-jump climb, Sleepy Magma Golem Slime, Final **Mythic Rainbow Sovereign** Boss Carry |

---

## 4. Technical Architecture & File Structure

Built with **Rojo 7.7.1** (`default.project.json`) so `rojo build -o FindASquishy.rbxl` produces a complete, standalone Roblox place file ready to open in Roblox Studio and publish to Roblox Creations.

```text
clever-maxwell/
├── default.project.json          # Rojo project mapping
├── rokit.toml                    # Toolchain manifest (rojo 7.7.1)
├── FindASquishy.rbxl             # Compiled ready-to-play Roblox Studio file
└── src/
    ├── shared/                   # ReplicatedStorage.Shared
    │   ├── SlimeData.luau        # All 35 Slimes: ID, Name, Level, Rarity, Color, Behavior, Income, Hint, Position
    │   ├── UpgradeData.luau      # Upgrades (Speed, Jump, Radar, Gel Tier, Shield, Slap Tool) & Level Definitions
    │   └── SquishyBuilder.luau   # Procedural 3D Slime mesh/part builder (eyes, blush, hats, accessories, labels)
    ├── server/                   # ServerScriptService.Server
    │   ├── WorldBuilder.luau     # Builds Hub, 6 Tycoon Plots, 5 Biomes, Gates, Co-op Plates, Vents, and Spawns Slimes
    │   └── GameServer.server.luau# DataStore/Session state, Slime AI loop, Carry-Escape, Base Income, Morph, Raids
    └── client/                   # StarterPlayer.StarterPlayerScripts.Client
        └── GameClient.client.luau# Full HUD, Slimeopedia, Morph Controls, Radar Tracker, Sound/VFX, Gate Transparency
```

### Data Flow & State Management
1. **Remotes (`ReplicatedStorage.SquishyRemotes`):**
   - `StateSync` (`RemoteEvent` Server -> Client): Sends full player profile (`Coins`, `StoredBaseCoins`, `FoundSlimes` table, `Upgrades` table, `CurrentMorph`, `TinyMode`, `CarryingSlimeId`).
   - `Notification` (`RemoteEvent` Server -> Client): Triggers celebratory banners, sound effects, and confetti on the client.
   - `ActionRequest` (`RemoteEvent` Client -> Server): Handles UI actions (`BuyUpgrade`, `MorphSlime`, `ToggleTiny`, `DropDecoyWeight`, `TeleportZone`, `UnlockAllDemo`).
2. **Per-Player Level Gate Enforcement:**
   - Each Level Gate between Level $N$ and Level $N+1$ checks if the player has found 100% of Slimes in Levels $1 \dots N$.
   - On the Server, if an unauthorized player touches or crosses a locked gate's Z-boundary, they are gently bounced back to the gate entrance with a hint prompt (`"Find X more Slimes in Level N to unlock!"`).
   - On the Client (`GameClient.client.luau`), once a player finds all Slimes required for Gate $N$, that gate's forcefield turns **green, translucent (`0.85`), and `CanCollide = false`** locally so they can walk smoothly into the next level while other players who haven't finished still see it locked!
3. **Resilience & Testing:**
   - Includes automatic `DataStoreService` persistence wrapped in `pcall` so it works seamlessly both in unpublished local Roblox Studio test sessions and once published to `create.roblox.com`.
   - Includes a **"Dad / Creator Fast-Test Panel"** toggle so you can test any level or gift your kids bonus coins anytime.
