--!strict
-- SlimeData.luau
-- Master data definitions for the 5 Massive Levels (240 studs wide x 260 studs long each),
-- 10 Million-Speed Animal & Brainrot Chaser Guardians, and all 35 hidden Squishy Eggs & Slimes.

local SlimeData = {}

export type SlimeBehavior = "Static" | "Disguised" | "Runaway" | "BounceWake"

export type SlimeDef = {
	Id: number,
	Name: string,
	Level: number,
	Rarity: string,
	Color: Color3,
	SecondaryColor: Color3,
	HatType: string,
	Behavior: SlimeBehavior,
	DisguiseProp: string?,
	CoinsPerSec: number,
	Hint: string,
	Position: Vector3,
	IsCoopVault: boolean?,
	IsMicroVent: boolean?,
	IsBoss: boolean?,
}

export type LevelDef = {
	Level: number,
	Name: string,
	Subtitle: string,
	ZStart: number,
	ZEnd: number,
	GateZ: number?,
	ThemeColor: Color3,
	FloorColor: Color3,
	RequiredPlantedCount: number,
	EggCount: number,
}

SlimeData.Levels = {
	{
		Level = 1,
		Name = "Squishy Meadow",
		Subtitle = "Steal & Hatch all 5 Meadow Eggs from the Sleeping Bear!",
		ZStart = 0,
		ZEnd = -95,
		GateZ = -95,
		ThemeColor = Color3.fromRGB(95, 215, 110),
		FloorColor = Color3.fromRGB(92, 198, 78),
		RequiredPlantedCount = 0,
		EggCount = 5,
	},
	{
		Level = 2,
		Name = "Chocolate Candy Land",
		Subtitle = "Steal & Hatch all 6 Candy Eggs from the Sleeping Shark!",
		ZStart = -95,
		ZEnd = -190,
		GateZ = -190,
		ThemeColor = Color3.fromRGB(255, 115, 190),
		FloorColor = Color3.fromRGB(162, 108, 96),
		RequiredPlantedCount = 5,
		EggCount = 6,
	},
	{
		Level = 3,
		Name = "Tropical Beach Lagoon",
		Subtitle = "Steal & Hatch all 7 Beach Eggs from the Sleeping Dino!",
		ZStart = -190,
		ZEnd = -285,
		GateZ = -285,
		ThemeColor = Color3.fromRGB(255, 205, 75),
		FloorColor = Color3.fromRGB(238, 210, 145),
		RequiredPlantedCount = 11,
		EggCount = 7,
	},
	{
		Level = 4,
		Name = "Crystal Cavern",
		Subtitle = "Steal & Hatch all 8 Crystal Eggs from the Sleeping Cyber-Croc!",
		ZStart = -285,
		ZEnd = -380,
		GateZ = -380,
		ThemeColor = Color3.fromRGB(65, 225, 255),
		FloorColor = Color3.fromRGB(72, 65, 118),
		RequiredPlantedCount = 18,
		EggCount = 8,
	},
	{
		Level = 5,
		Name = "Volcano Doom",
		Subtitle = "Steal & Hatch all 9 Mythic Eggs from the Sleeping Magma Dragon!",
		ZStart = -380,
		ZEnd = -475,
		GateZ = nil,
		ThemeColor = Color3.fromRGB(255, 95, 45),
		FloorColor = Color3.fromRGB(78, 42, 42),
		RequiredPlantedCount = 26,
		EggCount = 9,
	},
}

export type GuardianDef = {
	Id: string,
	Name: string,
	Title: string,
	Level: number,
	Style: "Bear" | "Shark" | "Dino" | "Croc" | "Dragon" | "BrainrotBat",
	PrimaryColor: Color3,
	AccentColor: Color3,
	PatrolSpeed: number,
	ChaseSpeed: number,
	RequiredSpeedPower: number,
	HomePosition: Vector3,
	PatrolRadius: number,
}

-- Giant Sleeping Bosses guarding each Biome's Egg Cluster ("Zzz" -> "!!" when you steal an Egg!)
SlimeData.Guardians = {
	-- Level 1 Bosses (Z: 0 to -95)
	{
		Id = "L1_Bear",
		Name = "Grizzly Papa Bear",
		Title = "🐻 MEADOW BOSS",
		Level = 1,
		Style = "Bear",
		PrimaryColor = Color3.fromRGB(125, 78, 45),
		AccentColor = Color3.fromRGB(215, 165, 115),
		PatrolSpeed = 8,
		ChaseSpeed = 19,
		RequiredSpeedPower = 800,
		HomePosition = Vector3.new(-16, 5, -56),
		PatrolRadius = 22,
	},
	{
		Id = "L1_Brainrot",
		Name = "Tralalero Sneaker Shark",
		Title = "🦈 SHARK BOSS",
		Level = 1,
		Style = "Shark",
		PrimaryColor = Color3.fromRGB(65, 155, 245),
		AccentColor = Color3.fromRGB(255, 255, 255),
		PatrolSpeed = 8,
		ChaseSpeed = 21,
		RequiredSpeedPower = 1_800,
		HomePosition = Vector3.new(18, 5, -62),
		PatrolRadius = 22,
	},

	-- Level 2 Bosses (Z: -95 to -190)
	{
		Id = "L2_Shark",
		Name = "Sour Gummy Jaws",
		Title = "🍬 CANDY BOSS",
		Level = 2,
		Style = "Shark",
		PrimaryColor = Color3.fromRGB(255, 85, 175),
		AccentColor = Color3.fromRGB(115, 245, 255),
		PatrolSpeed = 9,
		ChaseSpeed = 26,
		RequiredSpeedPower = 12_000,
		HomePosition = Vector3.new(-18, 5, -150),
		PatrolRadius = 24,
	},
	{
		Id = "L2_Brainrot",
		Name = "Cappuccino Assassino",
		Title = "☕ CHOCO BOSS",
		Level = 2,
		Style = "BrainrotBat",
		PrimaryColor = Color3.fromRGB(165, 115, 75),
		AccentColor = Color3.fromRGB(255, 245, 230),
		PatrolSpeed = 9,
		ChaseSpeed = 29,
		RequiredSpeedPower = 28_000,
		HomePosition = Vector3.new(18, 5, -156),
		PatrolRadius = 24,
	},

	-- Level 3 Bosses (Z: -190 to -285)
	{
		Id = "L3_Dino",
		Name = "Stompy Beach T-Rex",
		Title = "🦖 DINO BOSS",
		Level = 3,
		Style = "Dino",
		PrimaryColor = Color3.fromRGB(95, 215, 85),
		AccentColor = Color3.fromRGB(255, 195, 55),
		PatrolSpeed = 10,
		ChaseSpeed = 35,
		RequiredSpeedPower = 150_000,
		HomePosition = Vector3.new(-18, 5, -245),
		PatrolRadius = 24,
	},
	{
		Id = "L3_Brainrot",
		Name = "Tung Tung Sahur",
		Title = "🪵 LAGOON BOSS",
		Level = 3,
		Style = "BrainrotBat",
		PrimaryColor = Color3.fromRGB(195, 130, 68),
		AccentColor = Color3.fromRGB(255, 85, 65),
		PatrolSpeed = 10,
		ChaseSpeed = 39,
		RequiredSpeedPower = 350_000,
		HomePosition = Vector3.new(18, 5, -252),
		PatrolRadius = 24,
	},

	-- Level 4 Bosses (Z: -285 to -380)
	{
		Id = "L4_Croc",
		Name = "Crystal Cyber-Croc",
		Title = "🐊 CRYSTAL BOSS",
		Level = 4,
		Style = "Croc",
		PrimaryColor = Color3.fromRGB(0, 225, 195),
		AccentColor = Color3.fromRGB(255, 65, 185),
		PatrolSpeed = 11,
		ChaseSpeed = 46,
		RequiredSpeedPower = 1_500_000,
		HomePosition = Vector3.new(-18, 5, -340),
		PatrolRadius = 25,
	},
	{
		Id = "L4_Hound",
		Name = "Amethyst Mecha-Wolf",
		Title = "🐺 CAVERN BOSS",
		Level = 4,
		Style = "Bear",
		PrimaryColor = Color3.fromRGB(135, 75, 235),
		AccentColor = Color3.fromRGB(0, 245, 255),
		PatrolSpeed = 11,
		ChaseSpeed = 51,
		RequiredSpeedPower = 3_800_000,
		HomePosition = Vector3.new(18, 5, -346),
		PatrolRadius = 25,
	},

	-- Level 5 Bosses (Z: -380 to -475)
	{
		Id = "L5_Dragon",
		Name = "Inferno Magma Dragon",
		Title = "🐉 VOLCANO BOSS",
		Level = 5,
		Style = "Dragon",
		PrimaryColor = Color3.fromRGB(235, 55, 35),
		AccentColor = Color3.fromRGB(255, 215, 55),
		PatrolSpeed = 12,
		ChaseSpeed = 58,
		RequiredSpeedPower = 8_500_000,
		HomePosition = Vector3.new(-18, 5, -435),
		PatrolRadius = 26,
	},
	{
		Id = "L5_Titan",
		Name = "Lava Titan Rex",
		Title = "🔥 15M SPEED BOSS",
		Level = 5,
		Style = "Dino",
		PrimaryColor = Color3.fromRGB(165, 45, 225),
		AccentColor = Color3.fromRGB(255, 125, 35),
		PatrolSpeed = 12,
		ChaseSpeed = 65,
		RequiredSpeedPower = 15_000_000,
		HomePosition = Vector3.new(18, 5, -442),
		PatrolRadius = 26,
	},
}

SlimeData.RarityColors = {
	Common = Color3.fromRGB(130, 230, 140),
	Rare = Color3.fromRGB(85, 185, 255),
	Epic = Color3.fromRGB(200, 115, 255),
	Legendary = Color3.fromRGB(255, 195, 50),
	Mythic = Color3.fromRGB(255, 75, 145),
}

SlimeData.Slimes = {
	-- ==========================================
	-- LEVEL 1: MEADOW GARDENS (Eggs #1 - #5)
	-- Z: -60 to -320 (Width: -120 to +120)
	-- ==========================================
	{
		Id = 1,
		Name = "Dewdrop Sprout",
		Level = 1,
		Rarity = "Common",
		Color = Color3.fromRGB(110, 235, 130),
		SecondaryColor = Color3.fromRGB(190, 255, 180),
		HatType = "Sprout",
		Behavior = "Static",
		CoinsPerSec = 5,
		Hint = "Hidden inside the Red Meadow Barn on the left side!",
		Position = Vector3.new(-68, 5, -115),
	},
	{
		Id = 2,
		Name = "Berry Bushy",
		Level = 1,
		Rarity = "Common",
		Color = Color3.fromRGB(255, 105, 145),
		SecondaryColor = Color3.fromRGB(90, 200, 105),
		HatType = "Flower",
		Behavior = "Disguised",
		DisguiseProp = "Bush",
		CoinsPerSec = 8,
		Hint = "Deep inside the Green Hedge Maze on the right side!",
		Position = Vector3.new(72, 5, -145),
	},
	{
		Id = 3,
		Name = "Sleepy Creek Toad",
		Level = 1,
		Rarity = "Rare",
		Color = Color3.fromRGB(85, 210, 195),
		SecondaryColor = Color3.fromRGB(255, 235, 130),
		HatType = "Halo",
		Behavior = "BounceWake",
		CoinsPerSec = 14,
		Hint = "Snoozing high on the River Suspension Bridge Obby! Jump on its head 3x!",
		Position = Vector3.new(0, 14, -195),
	},
	{
		Id = 4,
		Name = "Picnic Basket Buddy",
		Level = 1,
		Rarity = "Epic",
		Color = Color3.fromRGB(255, 175, 80),
		SecondaryColor = Color3.fromRGB(255, 90, 90),
		HatType = "ChefHat",
		Behavior = "Static",
		IsCoopVault = true,
		CoinsPerSec = 22,
		Hint = "Locked in the Meadow Co-op Vault on the left! Step on both Buddy Plates!",
		Position = Vector3.new(-88, 5, -245),
	},
	{
		Id = 5,
		Name = "King Clover Blossom",
		Level = 1,
		Rarity = "Legendary",
		Color = Color3.fromRGB(95, 255, 140),
		SecondaryColor = Color3.fromRGB(255, 215, 60),
		HatType = "Crown",
		Behavior = "Runaway",
		IsBoss = true,
		CoinsPerSec = 38,
		Hint = "Atop the Giant Treehouse Obby on the back right hill!",
		Position = Vector3.new(64, 22, -285),
	},

	-- ==========================================
	-- LEVEL 2: CANDY KINGDOM (Eggs #6 - #11)
	-- Z: -320 to -580
	-- ==========================================
	{
		Id = 6,
		Name = "Sugar Swirl",
		Level = 2,
		Rarity = "Common",
		Color = Color3.fromRGB(255, 140, 215),
		SecondaryColor = Color3.fromRGB(140, 235, 255),
		HatType = "Flower",
		Behavior = "Static",
		CoinsPerSec = 45,
		Hint = "Hidden behind the Giant Frosting Waterfall Cave on the left!",
		Position = Vector3.new(-72, 6, -375),
	},
	{
		Id = 7,
		Name = "Sneaky Mallow",
		Level = 2,
		Rarity = "Rare",
		Color = Color3.fromRGB(255, 245, 250),
		SecondaryColor = Color3.fromRGB(255, 165, 210),
		HatType = "ChefHat",
		Behavior = "Disguised",
		DisguiseProp = "Marshmallow",
		CoinsPerSec = 65,
		Hint = "Disguised inside the Giant Hot Cocoa Cup Obby on the right!",
		Position = Vector3.new(74, 14, -405),
	},
	{
		Id = 8,
		Name = "Gumball Hopper",
		Level = 2,
		Rarity = "Rare",
		Color = Color3.fromRGB(255, 85, 125),
		SecondaryColor = Color3.fromRGB(255, 230, 85),
		HatType = "Propeller",
		Behavior = "Runaway",
		CoinsPerSec = 85,
		Hint = "Hopping across the Chocolate Castle Courtyard in the center!",
		Position = Vector3.new(0, 6, -445),
	},
	{
		Id = 9,
		Name = "Frosting Cave Jelly",
		Level = 2,
		Rarity = "Epic",
		Color = Color3.fromRGB(130, 225, 255),
		SecondaryColor = Color3.fromRGB(255, 255, 255),
		HatType = "WizardHat",
		Behavior = "Static",
		IsMicroVent = true,
		CoinsPerSec = 115,
		Hint = "Inside the Tiny Gingerbread House Vent on the right wall (Toggle Tiny Size)!",
		Position = Vector3.new(88, 5, -485),
	},
	{
		Id = 10,
		Name = "Wafer Vault Twin",
		Level = 2,
		Rarity = "Epic",
		Color = Color3.fromRGB(245, 190, 120),
		SecondaryColor = Color3.fromRGB(255, 120, 185),
		HatType = "Antlers",
		Behavior = "Static",
		IsCoopVault = true,
		CoinsPerSec = 150,
		Hint = "Locked inside the Candy Co-op Vault on the left!",
		Position = Vector3.new(-88, 5, -505),
	},
	{
		Id = 11,
		Name = "Empress Cotton Candy",
		Level = 2,
		Rarity = "Legendary",
		Color = Color3.fromRGB(255, 110, 225),
		SecondaryColor = Color3.fromRGB(115, 240, 255),
		HatType = "Crown",
		Behavior = "BounceWake",
		IsBoss = true,
		CoinsPerSec = 210,
		Hint = "High atop the 3-Story Gumball Machine Tower Obby! Climb up and bounce 3x!",
		Position = Vector3.new(0, 28, -548),
	},

	-- ==========================================
	-- LEVEL 3: TOYBOX BEDROOM (Eggs #12 - #18)
	-- Z: -580 to -840
	-- ==========================================
	{
		Id = 12,
		Name = "Blocky Cubeling",
		Level = 3,
		Rarity = "Common",
		Color = Color3.fromRGB(255, 85, 75),
		SecondaryColor = Color3.fromRGB(75, 165, 255),
		HatType = "Propeller",
		Behavior = "Disguised",
		DisguiseProp = "ToyBlock",
		CoinsPerSec = 260,
		Hint = "Hidden inside the Giant ABC Block Castle on the left!",
		Position = Vector3.new(-68, 12, -635),
	},
	{
		Id = 13,
		Name = "Pillow Bouncer",
		Level = 3,
		Rarity = "Rare",
		Color = Color3.fromRGB(175, 215, 255),
		SecondaryColor = Color3.fromRGB(255, 255, 255),
		HatType = "Halo",
		Behavior = "BounceWake",
		CoinsPerSec = 320,
		Hint = "Sleeping on the Giant 4-Poster Bouncy Bed on the right!",
		Position = Vector3.new(68, 16, -665),
	},
	{
		Id = 14,
		Name = "Wind-Up Zoomer",
		Level = 3,
		Rarity = "Rare",
		Color = Color3.fromRGB(255, 205, 55),
		SecondaryColor = Color3.fromRGB(255, 110, 45),
		HatType = "Propeller",
		Behavior = "Runaway",
		CoinsPerSec = 390,
		Hint = "Zooming around the Giant Train Track in the center of the bedroom!",
		Position = Vector3.new(0, 5, -705),
	},
	{
		Id = 15,
		Name = "Mousehole Dustbunny",
		Level = 3,
		Rarity = "Epic",
		Color = Color3.fromRGB(205, 185, 235),
		SecondaryColor = Color3.fromRGB(255, 150, 210),
		HatType = "Antlers",
		Behavior = "Static",
		IsMicroVent = true,
		CoinsPerSec = 470,
		Hint = "Inside the Baseboard Mousehole Vent on the right wall (Tiny Size required)!",
		Position = Vector3.new(88, 5, -745),
	},
	{
		Id = 16,
		Name = "Bookshelf Scholar",
		Level = 3,
		Rarity = "Epic",
		Color = Color3.fromRGB(120, 225, 165),
		SecondaryColor = Color3.fromRGB(255, 220, 110),
		HatType = "WizardHat",
		Behavior = "Static",
		CoinsPerSec = 560,
		Hint = "At the very top of the 4-Tier Giant Bookshelf Obby on the left!",
		Position = Vector3.new(-65, 28, -735),
	},
	{
		Id = 17,
		Name = "Toy Chest Guardian",
		Level = 3,
		Rarity = "Epic",
		Color = Color3.fromRGB(255, 145, 75),
		SecondaryColor = Color3.fromRGB(255, 235, 95),
		HatType = "ChefHat",
		Behavior = "Static",
		IsCoopVault = true,
		CoinsPerSec = 680,
		Hint = "Locked inside the Toybox Co-op Vault on the left!",
		Position = Vector3.new(-88, 5, -785),
	},
	{
		Id = 18,
		Name = "Mecha Rex Prime",
		Level = 3,
		Rarity = "Legendary",
		Color = Color3.fromRGB(75, 245, 195),
		SecondaryColor = Color3.fromRGB(255, 75, 95),
		HatType = "Crown",
		Behavior = "Runaway",
		IsBoss = true,
		CoinsPerSec = 850,
		Hint = "Atop the Giant Study Desk & Ruler Ramp Obby at the back of the bedroom!",
		Position = Vector3.new(45, 24, -808),
	},

	-- ==========================================
	-- LEVEL 4: NEON CYBER LAB (Eggs #19 - #26)
	-- Z: -840 to -1100
	-- ==========================================
	{
		Id = 19,
		Name = "Pixel Pulse",
		Level = 4,
		Rarity = "Common",
		Color = Color3.fromRGB(0, 240, 255),
		SecondaryColor = Color3.fromRGB(185, 85, 255),
		HatType = "Halo",
		Behavior = "Static",
		CoinsPerSec = 1000,
		Hint = "Hidden inside the Cyber Server Maze on the left!",
		Position = Vector3.new(-68, 6, -890),
	},
	{
		Id = 20,
		Name = "Holo-Cube Mimic",
		Level = 4,
		Rarity = "Rare",
		Color = Color3.fromRGB(195, 75, 255),
		SecondaryColor = Color3.fromRGB(0, 255, 220),
		HatType = "Propeller",
		Behavior = "Disguised",
		DisguiseProp = "CyberCrate",
		CoinsPerSec = 1200,
		Hint = "Disguised atop the Neon Containment Silo on the right!",
		Position = Vector3.new(68, 16, -920),
	},
	{
		Id = 21,
		Name = "Plasma Sprinter",
		Level = 4,
		Rarity = "Rare",
		Color = Color3.fromRGB(95, 255, 255),
		SecondaryColor = Color3.fromRGB(255, 255, 120),
		HatType = "Horns",
		Behavior = "Runaway",
		CoinsPerSec = 1450,
		Hint = "Sprinting around the Central Quantum Core Reactor!",
		Position = Vector3.new(0, 6, -955),
	},
	{
		Id = 22,
		Name = "Cryo-Pod Snoozer",
		Level = 4,
		Rarity = "Epic",
		Color = Color3.fromRGB(115, 175, 255),
		SecondaryColor = Color3.fromRGB(220, 255, 255),
		HatType = "Halo",
		Behavior = "BounceWake",
		CoinsPerSec = 1750,
		Hint = "Sleeping on the Elevated Cryo-Bridge on the left—bounce 3x to wake it!",
		Position = Vector3.new(-62, 18, -985),
	},
	{
		Id = 23,
		Name = "Nanobot Duct Crawler",
		Level = 4,
		Rarity = "Epic",
		Color = Color3.fromRGB(120, 255, 140),
		SecondaryColor = Color3.fromRGB(0, 215, 255),
		HatType = "Propeller",
		Behavior = "Static",
		IsMicroVent = true,
		CoinsPerSec = 2100,
		Hint = "Inside the Cyber Cooling Duct Vent on the right wall (Tiny Size required)!",
		Position = Vector3.new(88, 5, -1010),
	},
	{
		Id = 24,
		Name = "Quantum Jumper",
		Level = 4,
		Rarity = "Epic",
		Color = Color3.fromRGB(255, 85, 235),
		SecondaryColor = Color3.fromRGB(85, 245, 255),
		HatType = "WizardHat",
		Behavior = "Static",
		CoinsPerSec = 2500,
		Hint = "High atop the Floating Anti-Gravity Laser Obby in the center!",
		Position = Vector3.new(0, 30, -1035),
	},
	{
		Id = 25,
		Name = "Firewall Vault Core",
		Level = 4,
		Rarity = "Legendary",
		Color = Color3.fromRGB(255, 165, 45),
		SecondaryColor = Color3.fromRGB(0, 255, 240),
		HatType = "Horns",
		Behavior = "Static",
		IsCoopVault = true,
		CoinsPerSec = 3000,
		Hint = "Inside the Cyber Co-op Mainframe Vault on the left!",
		Position = Vector3.new(-88, 5, -1055),
	},
	{
		Id = 26,
		Name = "Overclocked Glitch Lord",
		Level = 4,
		Rarity = "Legendary",
		Color = Color3.fromRGB(255, 55, 175),
		SecondaryColor = Color3.fromRGB(55, 255, 225),
		HatType = "Crown",
		Behavior = "Runaway",
		IsBoss = true,
		CoinsPerSec = 3800,
		Hint = "Atop the Cyber Command Citadel on the back right!",
		Position = Vector3.new(58, 22, -1075),
	},

	-- ==========================================
	-- LEVEL 5: MAGMA & CRYSTAL CAVERNS (Eggs #27 - #35)
	-- Z: -1100 to -1380
	-- ==========================================
	{
		Id = 27,
		Name = "Ember Pebble",
		Level = 5,
		Rarity = "Rare",
		Color = Color3.fromRGB(255, 110, 45),
		SecondaryColor = Color3.fromRGB(255, 215, 65),
		HatType = "Horns",
		Behavior = "Disguised",
		DisguiseProp = "LavaRock",
		CoinsPerSec = 4500,
		Hint = "Disguised among the Obsidian Basalt Pillars on the left!",
		Position = Vector3.new(-68, 10, -1145),
	},
	{
		Id = 28,
		Name = "Amethyst Glimmer",
		Level = 5,
		Rarity = "Rare",
		Color = Color3.fromRGB(195, 95, 255),
		SecondaryColor = Color3.fromRGB(255, 185, 255),
		HatType = "Halo",
		Behavior = "Static",
		CoinsPerSec = 5400,
		Hint = "High inside the Giant Amethyst Crystal Cathedral on the right!",
		Position = Vector3.new(72, 18, -1175),
	},
	{
		Id = 29,
		Name = "Cinder Dash",
		Level = 5,
		Rarity = "Epic",
		Color = Color3.fromRGB(255, 75, 35),
		SecondaryColor = Color3.fromRGB(255, 240, 95),
		HatType = "Horns",
		Behavior = "Runaway",
		CoinsPerSec = 6500,
		Hint = "Darting across the Center Magma Island!",
		Position = Vector3.new(0, 6, -1210),
	},
	{
		Id = 30,
		Name = "Obsidian Slumber Golem",
		Level = 5,
		Rarity = "Epic",
		Color = Color3.fromRGB(95, 65, 115),
		SecondaryColor = Color3.fromRGB(255, 115, 45),
		HatType = "Crown",
		Behavior = "BounceWake",
		CoinsPerSec = 7800,
		Hint = "Sleeping on the Lava Fortress Bridge on the left—bounce 3x!",
		Position = Vector3.new(-62, 20, -1245),
	},
	{
		Id = 31,
		Name = "Crystal Fissure Sprite",
		Level = 5,
		Rarity = "Epic",
		Color = Color3.fromRGB(115, 255, 235),
		SecondaryColor = Color3.fromRGB(215, 115, 255),
		HatType = "WizardHat",
		Behavior = "Static",
		IsMicroVent = true,
		CoinsPerSec = 9200,
		Hint = "Inside the Crystal Fissure Micro-Vent on the right wall (Tiny Size required)!",
		Position = Vector3.new(88, 5, -1275),
	},
	{
		Id = 32,
		Name = "Volcanic Spire Drake",
		Level = 5,
		Rarity = "Legendary",
		Color = Color3.fromRGB(255, 60, 60),
		SecondaryColor = Color3.fromRGB(255, 200, 50),
		HatType = "Horns",
		Behavior = "Static",
		CoinsPerSec = 11000,
		Hint = "Perched atop the 34-Stud Crystal Spire Obby in the center!",
		Position = Vector3.new(0, 34, -1295),
	},
	{
		Id = 33,
		Name = "Magma Vault Phoenix",
		Level = 5,
		Rarity = "Legendary",
		Color = Color3.fromRGB(255, 155, 35),
		SecondaryColor = Color3.fromRGB(255, 250, 140),
		HatType = "Halo",
		Behavior = "Static",
		IsCoopVault = true,
		CoinsPerSec = 13500,
		Hint = "Inside the Final Obsidian Co-op Vault on the left!",
		Position = Vector3.new(-88, 5, -1325),
	},
	{
		Id = 34,
		Name = "Celestial Starlight Egg",
		Level = 5,
		Rarity = "Mythic",
		Color = Color3.fromRGB(135, 195, 255),
		SecondaryColor = Color3.fromRGB(255, 255, 190),
		HatType = "WizardHat",
		Behavior = "Runaway",
		CoinsPerSec = 17500,
		Hint = "Guarding the Volcano Rim Walkway on the back right!",
		Position = Vector3.new(65, 24, -1340),
	},
	{
		Id = 35,
		Name = "Mythic Rainbow Sovereign",
		Level = 5,
		Rarity = "Mythic",
		Color = Color3.fromRGB(255, 85, 165),
		SecondaryColor = Color3.fromRGB(85, 245, 255),
		HatType = "Crown",
		Behavior = "BounceWake",
		IsBoss = true,
		CoinsPerSec = 25000,
		Hint = "At the peak of the Golden Volcano Temple Altar (Y=42, Z=-1358)! Climb the Volcano Obby & Bounce 3x!",
		Position = Vector3.new(0, 42, -1358),
	},
}

SlimeData.ById = {} :: { [number]: SlimeDef }
SlimeData.ByLevel = {} :: { [number]: { SlimeDef } }

local speciesRotation = {
	"Cow",
	"Axolotl",
	"Boba",
	"Frog",
	"Cat",
	"Dragon",
	"Unicorn",
	"Puppy",
}

for _, levelDef in ipairs(SlimeData.Levels) do
	SlimeData.ByLevel[levelDef.Level] = {}
end

local levelEggIndices: { [number]: number } = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 }

for _, slime in ipairs(SlimeData.Slimes) do
	local sp = speciesRotation[((slime.Id - 1) % #speciesRotation) + 1]
	local nm = string.lower(slime.Name)
	if string.find(nm, "frog") or string.find(nm, "sprout") or string.find(nm, "moss") then
		sp = "Frog"
	elseif string.find(nm, "milk") or string.find(nm, "cow") or string.find(nm, "butter") or string.find(nm, "mochi") then
		sp = "Cow"
	elseif string.find(nm, "boba") or string.find(nm, "soda") or string.find(nm, "slush") or string.find(nm, "cotton") or string.find(nm, "taffy") then
		sp = "Boba"
	elseif string.find(nm, "axolotl") or string.find(nm, "gummy") or string.find(nm, "bubble") or string.find(nm, "plasma") then
		sp = "Axolotl"
	elseif string.find(nm, "cat") or string.find(nm, "teddy") or string.find(nm, "plush") or string.find(nm, "pixel") then
		sp = "Cat"
	elseif string.find(nm, "dragon") or string.find(nm, "magma") or string.find(nm, "lava") or string.find(nm, "obsidian") or string.find(nm, "cinder") then
		sp = "Dragon"
	elseif string.find(nm, "sovereign") or string.find(nm, "star") or string.find(nm, "celestial") or string.find(nm, "unicorn") then
		sp = "Unicorn"
	end
	slime.Species = sp
	slime.HatchTime = 3 + (slime.Level * 2) -- Fast exciting hatch timers: 5s, 7s, 9s, 11s, 13s!

	-- Pure "Steal My Egg" layout: all Eggs sit in rich clusters right around the Sleeping Bosses!
	slime.Behavior = "Static"
	slime.IsCoopVault = false
	slime.IsMicroVent = false
	slime.DisguiseProp = nil

	local lvlNum = slime.Level
	local lvlDef = SlimeData.Levels[lvlNum]
	levelEggIndices[lvlNum] = (levelEggIndices[lvlNum] or 0) + 1
	local idxInLvl = levelEggIndices[lvlNum]
	local totalInLvl = if lvlDef then lvlDef.EggCount else 6
	local zCenter = if lvlDef then (lvlDef.ZStart - 56) else (-56 * lvlNum)
	local frac = if totalInLvl > 1 then (idxInLvl - 1) / (totalInLvl - 1) else 0.5
	local xPos = -36 + frac * 72
	local zOffset = if idxInLvl % 2 == 0 then -8 else 6
	slime.Position = Vector3.new(xPos, 3.8, zCenter + zOffset)
	slime.Hint = string.format("Guarded by the Sleeping Boss in %s! Hold E to Steal!", if lvlDef then lvlDef.Name else ("Zone " .. lvlNum))

	SlimeData.ById[slime.Id] = slime
	if not SlimeData.ByLevel[slime.Level] then
		SlimeData.ByLevel[slime.Level] = {}
	end
	table.insert(SlimeData.ByLevel[slime.Level], slime)
end

function SlimeData.GetHatchTimeSeconds(slimeDef: SlimeDef): number
	return (slimeDef :: any).HatchTime or (4 + slimeDef.Level * 2)
end

function SlimeData.GetSquishyCoinsPerSec(slimeDef: SlimeDef, squishyLevel: number): number
	local lvl = math.clamp(squishyLevel or 1, 1, 15)
	return math.floor(slimeDef.CoinsPerSec * (1.55 ^ (lvl - 1)))
end

function SlimeData.GetSquishyUpgradeCost(slimeDef: SlimeDef, currentLvl: number): number
	local lvl = math.clamp(currentLvl or 1, 1, 15)
	return math.max(25, math.floor(slimeDef.CoinsPerSec * 10 * (1.75 ^ (lvl - 1))))
end

return SlimeData

