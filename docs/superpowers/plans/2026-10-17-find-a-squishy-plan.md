# Find a Squishy! Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and compile a complete, standalone playable Roblox game (`FindASquishy.rbxl`) via Rojo 7.7.1 implementing the 5-level *Find a Squishy!* Egg Hunt, Treadmill Speed Training, Expandable Base Pen Tycoon, Paid Egg Guide Beam, and Coloring Trails Shop.

**Architecture:** Self-contained modular Luau architecture synced via Rojo (`default.project.json`). `ReplicatedStorage.Shared` holds pure data tables (`SlimeData`, `UpgradeData`) and the procedural 3D model factory (`SquishyBuilder`). `ServerScriptService.Server` builds the entire 3D world procedurally on startup (`WorldBuilder`) and runs authoritative game loops, DataStores, MarketplaceService hooks, Treadmill training, Egg Carrying/Planting, and Coloring Trails (`GameServer`). `StarterPlayerScripts.Client` drives the interactive HUD, 3D Guide Beam, local gate unlocking, and visual effects (`GameClient`).

**Tech Stack:** Roblox Luau, Rojo 7.7.1 (`rokit`), Roblox `DataStoreService`, `MarketplaceService`, `TweenService`, `RunService`.

**Spec:** `docs/superpowers/specs/2026-10-17-find-a-squishy-design.md`

## Global Constraints

- Zero external package dependencies: all 3D models, UI, levels, and scripts must be 100% self-contained in `src/` and compile cleanly via `rojo build -o FindASquishy.rbxl`.
- Every Level Gate (`1 -> 2`, `2 -> 3`, `3 -> 4`, `4 -> 5`) strictly requires 100% of prior levels' Eggs to be **physically planted** in the player's Base Pen.
- Planting an Egg requires an available **Nest Slot** in the player's Pen; players start at Pen Tier 1 (`5 Nest Slots`) and spend Coins earned from hatched Squishies to expand their Pen up to `35 Nest Slots`.
- All Monetization items (Egg Guide Director, Coloring Trails, 2x Coins, Auto-Runner Treadmill, Skip Gate) must support both `MarketplaceService` Robux IDs (when configured > 0) and instant In-Game Coin / Studio Family-Play unlocks so everything works out-of-the-box today.

## Review Focus

- Player respawns or disconnects while carrying an unplanted Egg: `CharacterRemoving` / `Humanoid.Died` must clear `CarryingEggId` and destroy the overhead carried Egg model cleanly so the player can pick up another Egg after respawning.
- Player tries to plant an Egg when their Base Pen is full (e.g., found a Level 2 Egg before buying Pen Tier 2): the server must keep the Egg in their hands and send a clear notification prompting them to step on the **[Expand Pen]** pad or open the Upgrades UI.
- Player enters the game and touches an Egg before claiming one of the 6 Base Pens: `GameServer` must auto-assign them an unclaimed Base Pen on join (or on first Egg pickup) so planting never fails due to `PlotIndex == nil`.
- Paid Egg Guide Beam target validation: if the guided Egg is planted or the player switches targets, the 3D `Beam` and attachments must update or clean up without leaking instances in `Workspace`.
- DataStore calls in unpublished local `.rbxl` Studio files: all `DataStoreService` and `MarketplaceService` calls must be wrapped in `pcall` with in-memory session fallbacks so Studio solo/multi-player tests never throw unhandled errors.

---

### Task 1: Rojo Project Configuration & Shared Data Modules (`SlimeData` & `UpgradeData`)

**Files:**
- Create: `default.project.json`
- Create: `src/shared/SlimeData.luau`
- Create: `src/shared/UpgradeData.luau`

**Interfaces:**
- Produces:
  - `SlimeData.Levels`: array of 5 level configs (`{ Level: number, Name: string, ZStart: number, ZEnd: number, ThemeColor: Color3, RequiredPlantedCount: number, EggCount: number }`)
  - `SlimeData.Slimes`: array of 35 Egg/Squishy definitions (`{ Id: number, Name: string, Level: number, Rarity: string, Color: Color3, SecondaryColor: Color3, HatType: string, Behavior: "Static" | "Disguised" | "Runaway" | "BounceWake", DisguiseProp: string?, CoinsPerSec: number, Hint: string, Position: Vector3, IsCoopVault: boolean?, IsMicroVent: boolean?, IsBoss: boolean? }`)
  - `SlimeData.ById`: dictionary lookup `[id: number] -> SlimeDef`
  - `UpgradeData.PenTiers`: array of 5 Pen expansion tiers (`{ Tier: number, MaxNests: number, Cost: number, Name: string }`)
  - `UpgradeData.TreadmillTiers`: array of 4 Treadmill tiers (`{ Tier: number, SpeedPerTick: number, Cost: number, Name: string, Color: Color3 }`)
  - `UpgradeData.GelTiers`: array of 3 Gel tiers (`{ Tier: number, Multiplier: number, Cost: number, Name: string }`)
  - `UpgradeData.JumpTiers`: array of 4 Jump tiers (`{ Tier: number, JumpPower: number, Cost: number, Name: string }`)
  - `UpgradeData.Trails`: array of 6 Coloring Trails (`{ Id: string, Name: string, Cost: number, RobuxPassId: number, Color1: Color3, Color2: Color3, PaintFloor: boolean, Rainbow: boolean, SpeedBonus: number, CoinMultiplier: number, Description: string }`)
  - `UpgradeData.GuidePricing`: `{ SingleEggGuideCoinCost: number, VIPUnlimitedGuideCost: number, GuideDevProductId: number, VIPGuidePassId: number }`

- [ ] **Step 1: Create `default.project.json` mapping `src/shared`, `src/server`, and `src/client`**
  Configure `$className: "DataModel"` with `ReplicatedStorage.Shared -> src/shared`, `ServerScriptService.Server -> src/server`, `StarterPlayer.StarterPlayerScripts.Client -> src/client`, and `Workspace` / `Lighting` / `SoundService` properties.

- [ ] **Step 2: Implement `src/shared/SlimeData.luau` with all 5 levels and 35 Squishy Eggs**
  Define exact coordinates inside each level's Z-corridor (`Level 1: -40 to -220`, `Level 2: -220 to -400`, `Level 3: -400 to -580`, `Level 4: -580 to -760`, `Level 5: -760 to -960`), varied behaviors (`Static`, `Disguised`, `Runaway`, `BounceWake`), `IsMicroVent`, `IsCoopVault`, `IsBoss`, hints, and `CoinsPerSec` scaling from `5/s` (Level 1 Common) up to `2500/s` (Level 5 Mythic Sovereign).

- [ ] **Step 3: Implement `src/shared/UpgradeData.luau` with Pen Tiers, Treadmill Tiers, Gel Tiers, Jump Tiers, Coloring Trails, and Guide Pricing**
  Include helper functions `UpgradeData.GetPenTier(tier)`, `UpgradeData.GetTreadmillTier(tier)`, and `UpgradeData.GetTrailById(trailId)`.

- [ ] **Step 4: Verify Rojo compiles the data modules into a valid binary place file**
  Run: `rojo build -o FindASquishy.rbxl`
  Expected: `Built project to FindASquishy.rbxl` with exit code 0.

- [ ] **Step 5: Commit Task 1**
  Run: `git add default.project.json src/shared/SlimeData.luau src/shared/UpgradeData.luau && git commit -m "feat: add Rojo config, SlimeData (35 eggs/5 levels), and UpgradeData"`

---

### Task 2: Procedural 3D Egg & Squishy Slime Builder (`SquishyBuilder.luau`)

**Files:**
- Create: `src/shared/SquishyBuilder.luau`

**Interfaces:**
- Consumes: `SlimeData.ById`
- Produces:
  - `SquishyBuilder.CreateWorldEgg(slimeDef: table) -> Model`: Builds a 3D spotted glowing Egg (or initial disguised prop shell for `Disguised` eggs) with `BillboardGui` name/rarity/behavior tag and `PrimaryPart`.
  - `SquishyBuilder.CreateHatchedSquishy(slimeDef: table, gelTier: number?) -> Model`: Builds a translucent outer jelly sphere + glowing neon core + cartoon eyes + pink blush cheeks + themed hat (`Crown`, `Antlers`, `ChefHat`, `Halo`, `Horns`, `Propeller`, `WizardHat`) + `BillboardGui` showing name and `+$Coins/sec`.
  - `SquishyBuilder.AttachMorphToCharacter(character: Model, slimeDef: table, tinyMode: boolean)`: Attaches a lightweight non-colliding Squishy costume to the player's `HumanoidRootPart` and scales character height/speed or sets `TinyMode` scale (`0.4x`).

- [ ] **Step 1: Implement `SquishyBuilder.luau` with `CreateWorldEgg`, `CreateHatchedSquishy`, and `AttachMorphToCharacter`**
  Ensure every part in generated models is `Anchored = true` (for world/pen models) or welded with `WeldConstraint` and `CanCollide = false` (for carried eggs and player morphs). Tag world eggs with `IntValue` or attribute `SlimeId = slimeDef.Id`.

- [ ] **Step 2: Verify Rojo build passes with `SquishyBuilder.luau`**
  Run: `rojo build -o FindASquishy.rbxl`
  Expected: `Built project to FindASquishy.rbxl` with exit code 0.

- [ ] **Step 3: Commit Task 2**
  Run: `git add src/shared/SquishyBuilder.luau && git commit -m "feat: add procedural 3D Egg, Hatched Squishy, and Morph builder"`

---

### Task 3: Procedural World, 6 Expandable Base Pens, Treadmills & 5 Biomes (`WorldBuilder.luau`)

**Files:**
- Create: `src/server/WorldBuilder.luau`

**Interfaces:**
- Consumes: `SlimeData`, `UpgradeData`, `SquishyBuilder`
- Produces:
  - `WorldBuilder.BuildWorld() -> { Plots: table, WorldEggs: { [number]: Model }, LevelGates: { [number]: BasePart }, CoopVaultDoors: { [number]: BasePart }, CoopPlates: { [number]: { PlateA: BasePart, PlateB: BasePart } } }`
  - `WorldBuilder.RefreshPlotVisuals(plotData: table, playerState: table)`: Updates owner sign, visible Nest pedestals up to `MaxNests`, planted Squishy models in nests with `ClickDetector`s, Treadmill tier visuals, and Base Laser Shield dome.

- [ ] **Step 1: Implement `WorldBuilder.luau` to construct the Hub, 6 Base Pens (with Treadmills, Plant Zones, Cash Collectors, Expand Pads, Shield Pads, and 35 Nest Pedestals), and 5 Level Biomes**
  Include themed obstacles in each biome (Meadow trees/bridge/picnic/vent, Candy lollipops/gumball obby/frosting waterfall, Toybox ABC blocks/bouncy bed mattress trampoline/mouse-hole vent, Cyber neon platforms/tubes/vent, Magma lava stepping stones/crystal spire), 4 Level Gates (`Gate_1` to `Gate_4`), Co-op Buddy Plates per level, and all 35 hidden Eggs.

- [ ] **Step 2: Verify Rojo build succeeds with `WorldBuilder.luau`**
  Run: `rojo build -o FindASquishy.rbxl`
  Expected: `Built project to FindASquishy.rbxl` with exit code 0.

- [ ] **Step 3: Commit Task 3**
  Run: `git add src/server/WorldBuilder.luau && git commit -m "feat: add procedural WorldBuilder for Hub, 6 Base Pens, Treadmills, and 5 Biomes"`

---

### Task 4: Authoritative Server Engine (`GameServer.server.luau`)

**Files:**
- Create: `src/server/GameServer.server.luau`

**Interfaces:**
- Consumes: `SlimeData`, `UpgradeData`, `SquishyBuilder`, `WorldBuilder`
- Produces:
  - `ReplicatedStorage.SquishyRemotes.StateSync` (`RemoteEvent`)
  - `ReplicatedStorage.SquishyRemotes.Notification` (`RemoteEvent`)
  - `ReplicatedStorage.SquishyRemotes.ActionRequest` (`RemoteEvent`)
  - Complete server loops for:
    - Player Plot auto-assignment & DataStore load/save
    - Egg Touch -> Carry overhead model (`CarryingEggId`)
    - Base Planting Zone touch -> Verifies open Nest Slot (`PlantedCount < MaxNests`), plants Egg, hatches Squishy in Pen with Click-to-Squish `ClickDetector`, checks if all Level Eggs are planted to unlock the next Level Gate!
    - Treadmill Speed Training loop (detects players on any Treadmill belt, awards `+Speed` every 0.4s based on Treadmill Tier, updates `Humanoid.WalkSpeed`)
    - Living Egg AI tick (`Runaway` hops away from nearby players unless they are fast, `Disguised` reveals eyes when within 18 studs, `BounceWake` counts 3 head bounces and launches player upward)
    - Co-op Buddy Plates & Solo Decoy Squishy Weight spawning
    - Coloring Trails attachment (`Trail` instance + floor paint splat spawning for paint trails + rainbow HSV cycling)
    - Paid Egg Guide Director unlock (single-egg guide or VIP unlimited guide via Coins or `MarketplaceService`)
    - Family Slime-Slap tool & Base Raid / Shield logic

- [ ] **Step 1: Implement `src/server/GameServer.server.luau` with all authoritative game loops and RemoteEvents**
  Ensure all 5 Review Focus edge cases are handled cleanly (character death clears carried egg, full pen notifies player to expand pen, auto-claim plot on join, safe DataStore/MarketplaceService `pcall` wrappers).

- [ ] **Step 2: Verify Rojo build passes with `GameServer.server.luau`**
  Run: `rojo build -o FindASquishy.rbxl`
  Expected: `Built project to FindASquishy.rbxl` with exit code 0.

- [ ] **Step 3: Commit Task 4**
  Run: `git add src/server/GameServer.server.luau && git commit -m "feat: implement GameServer with Egg Carry/Plant, Treadmill, Trails, and Egg Guide"`

---

### Task 5: Interactive Client HUD, 3D Egg Guide Beam & Local Effects (`GameClient.client.luau`)

**Files:**
- Create: `src/client/GameClient.client.luau`

**Interfaces:**
- Consumes: `SlimeData`, `UpgradeData`, `ReplicatedStorage.SquishyRemotes`
- Produces:
  - Top HUD Bar: Level Progress (`Planted: X / Y Eggs in Level N`), Coins counter, Treadmill Speed readout,Carried Egg status banner, Quick Teleport buttons (`🏠 My Pen`, `🏃 Treadmill`, `🧭 Guide Me to Next Egg`).
  - Left/Bottom Action Dock:
    - `📖 Egg & Slimeopedia` (Shows all 35 Eggs/Squishies by level, riddles/hints, `[🧭 Direct Me to Egg]` button for unplanted eggs, and `[✨ Morph into Squishy]` + `[🐭 Tiny Size]` toggle for hatched Squishies)
    - `🎨 Coloring Trails Shop` (Buy & equip the 6 Coloring Trails including Floor-Painting Rainbow Trail)
    - `⚡ Pen & Treadmill Upgrades` (Expand Pen Nest Slots, Upgrade Treadmill Tier, Upgrade Jump Springs, Upgrade Golden/Rainbow Pen Gel, Activate Base Shield, Equip Slime Slap Glove)
    - `🛠️ Family / Creator Boosts` (Instant "+5,000 Coins", "+25 Speed", "Drop Co-op Buddy Weight", or "Unlock All Gates" for quick family testing)
  - 3D Egg Guide Beam (`Beam` + floating pulsing Guide Orb pointing directly from player's `HumanoidRootPart` to the target Egg in `Workspace.WorldEggs`, with live stud distance readout).
  - Local Egg & Gate Visuals: Already-planted Eggs appear ghostly translucent (`Transparency = 0.75`) so you know which ones you already planted while your kids still see theirs solid; unlocked Level Gates turn green and `CanCollide = false` locally.

- [ ] **Step 1: Implement `src/client/GameClient.client.luau` with full UI, 3D Guide Beam, sound synthesis, and local gate/egg visuals**

- [ ] **Step 2: Build the final `FindASquishy.rbxl` artifact and verify zero errors**
  Run: `rojo build -o FindASquishy.rbxl`
  Expected: `Built project to FindASquishy.rbxl` with exit code 0 and file size > 50 KB.

- [ ] **Step 3: Commit Task 5**
  Run: `git add src/client/GameClient.client.luau FindASquishy.rbxl && git commit -m "feat: add GameClient HUD, 3D Egg Guide Beam, Coloring Trails UI, and compiled rbxl"`
