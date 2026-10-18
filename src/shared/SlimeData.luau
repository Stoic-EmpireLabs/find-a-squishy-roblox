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
		ZEnd = -160,
		GateZ = -160,
		ThemeColor = Color3.fromRGB(95, 215, 110),
		FloorColor = Color3.fromRGB(92, 198, 78),
		RequiredPlantedCount = 0,
		EggCount = 5,
	},
	{
		Level = 2,
		Name = "Chocolate Candy Land",
		Subtitle = "Steal & Hatch all 6 Candy Eggs from the Sleeping Shark!",
		ZStart = -160,
		ZEnd = -320,
		GateZ = -320,
		ThemeColor = Color3.fromRGB(255, 115, 190),
		FloorColor = Color3.fromRGB(162, 108, 96),
		RequiredPlantedCount = 5,
		EggCount = 6,
	},
	{
		Level = 3,
		Name = "Tropical Beach Lagoon",
		Subtitle = "Steal & Hatch all 7 Beach Eggs from the Sleeping Dino!",
		ZStart = -320,
		ZEnd = -480,
		GateZ = -480,
		ThemeColor = Color3.fromRGB(255, 205, 75),
		FloorColor = Color3.fromRGB(238, 210, 145),
		RequiredPlantedCount = 11,
		EggCount = 7,
	},
	{
		Level = 4,
		Name = "Crystal Cavern",
		Subtitle = "Steal & Hatch all 8 Crystal Eggs from the Sleeping Cyber-Croc!",
		ZStart = -480,
		ZEnd = -640,
		GateZ = -640,
		ThemeColor = Color3.fromRGB(65, 225, 255),
		FloorColor = Color3.fromRGB(72, 65, 118),
		RequiredPlantedCount = 18,
		EggCount = 8,
	},
	{
		Level = 5,
		Name = "Volcano Doom",
		Subtitle = "Steal & Hatch all 9 Mythic Eggs from the Sleeping Magma Dragon!",
		ZStart = -640,
		ZEnd = -800,
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
	-- Level 1 Bosses (Z: 0 to -160, Boss Nest at Z = -112)
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
		HomePosition = Vector3.new(-34, 5, -108),
		PatrolRadius = 32,
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
		HomePosition = Vector3.new(34, 5, -116),
		PatrolRadius = 32,
	},

	-- Level 2 Bosses (Z: -160 to -320, Boss Nest at Z = -272)
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
		HomePosition = Vector3.new(-34, 5, -268),
		PatrolRadius = 34,
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
		HomePosition = Vector3.new(34, 5, -276),
		PatrolRadius = 34,
	},

	-- Level 3 Bosses (Z: -320 to -480, Boss Nest at Z = -432)
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
		HomePosition = Vector3.new(-34, 5, -428),
		PatrolRadius = 34,
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
		HomePosition = Vector3.new(34, 5, -436),
		PatrolRadius = 34,
	},

	-- Level 4 Bosses (Z: -480 to -640, Boss Nest at Z = -592)
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
		HomePosition = Vector3.new(-34, 5, -588),
		PatrolRadius = 35,
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
		HomePosition = Vector3.new(34, 5, -596),
		PatrolRadius = 35,
	},

	-- Level 5 Bosses (Z: -640 to -800, Boss Nest at Z = -752)
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
		HomePosition = Vector3.new(-34, 5, -748),
		PatrolRadius = 36,
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
		HomePosition = Vector3.new(34, 5, -756),
		PatrolRadius = 36,
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

SlimeData.RarityColors = {
	Common = Color3.fromRGB(185, 225, 255),
	Uncommon = Color3.fromRGB(110, 250, 145),
	Rare = Color3.fromRGB(85, 195, 255),
	Epic = Color3.fromRGB(215, 115, 255),
	Legendary = Color3.fromRGB(255, 205, 65),
	Mythic = Color3.fromRGB(255, 85, 165),
}

SlimeData.ById = {} :: { [any]: SlimeDef }
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

local floorMaterials = {
	[1] = Enum.Material.LeafyGrass,
	[2] = Enum.Material.SmoothPlastic,
	[3] = Enum.Material.Sand,
	[4] = Enum.Material.Slate,
	[5] = Enum.Material.Basalt,
}

local requiredSpeeds = {
	[1] = 16,
	[2] = 24,
	[3] = 34,
	[4] = 46,
	[5] = 60,
}

for _, levelDef in ipairs(SlimeData.Levels) do
	local lvl = levelDef.Level
	local anyLvl = levelDef :: any
	anyLvl.Id = lvl
	anyLvl.SecondaryColor = levelDef.ThemeColor
	anyLvl.GateColor = levelDef.ThemeColor
	anyLvl.FloorMaterial = floorMaterials[lvl] or Enum.Material.SmoothPlastic
	anyLvl.RequiredSpeed = requiredSpeeds[lvl] or 16
	anyLvl.RequiredCoins = (lvl - 1) * 500
	anyLvl.Guardians = {}
	SlimeData.ByLevel[lvl] = {}
end

for _, g in ipairs(SlimeData.Guardians) do
	local anyG = g :: any
	anyG.Color = g.PrimaryColor
	anyG.Center = g.HomePosition
	anyG.Radius = g.PatrolRadius
	local lvlDef = SlimeData.Levels[g.Level] :: any
	if lvlDef and lvlDef.Guardians then
		table.insert(lvlDef.Guardians, g)
	end
end

-- Position the 35 Boss Nest Eggs (#1 to #35) in wide, non-overlapping arcs around the Sleeping Bosses
local levelEggIndices: { [number]: number } = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 }
for _, slime in ipairs(SlimeData.Slimes) do
	local anySlime = slime :: any
	anySlime.IsShiningSquishy = false
	anySlime.ZoneTag = "BossNest"

	local lvlNum = slime.Level
	local lvlDef = SlimeData.Levels[lvlNum]
	levelEggIndices[lvlNum] = (levelEggIndices[lvlNum] or 0) + 1
	local idxInLvl = levelEggIndices[lvlNum]
	local totalInLvl = if lvlDef then lvlDef.EggCount else 6
	local zCenter = if lvlDef then (lvlDef.ZStart - 112) else (-112 * lvlNum)
	local frac = if totalInLvl > 1 then (idxInLvl - 1) / (totalInLvl - 1) else 0.5
	local xPos = -58 + frac * 116
	local zOffset = if idxInLvl % 2 == 0 then -14 else 12
	slime.Position = Vector3.new(xPos, 3.8, zCenter + zOffset)
	slime.Hint = string.format("Guarded by the Sleeping Boss in %s! Hold E to Steal!", if lvlDef then lvlDef.Name else ("Zone " .. lvlNum))
end

-- ============================================================================
-- GENERATE 82 SHINING COLLECTIBLE SQUISHIES (#36 to #117) -> MAX = 117 TOTAL!
-- Placed on House Rooftops, Giant Rainbow Disappearing Staircase, Outer Mazes,
-- Castle Wall Battlements, and Themed Level Obby Obstacles!
-- ============================================================================
local shiningPalette = {
	{ Color3.fromRGB(255, 95, 165), Color3.fromRGB(255, 235, 95) },
	{ Color3.fromRGB(75, 225, 255), Color3.fromRGB(255, 130, 235) },
	{ Color3.fromRGB(115, 250, 135), Color3.fromRGB(255, 220, 85) },
	{ Color3.fromRGB(255, 185, 65), Color3.fromRGB(255, 85, 125) },
	{ Color3.fromRGB(190, 105, 255), Color3.fromRGB(95, 245, 255) },
	{ Color3.fromRGB(255, 95, 95), Color3.fromRGB(255, 240, 130) },
}

local hatRotation = { "Crown", "Halo", "Flower", "Sprout", "WizardHat", "Propeller", "ChefHat", "Horns" }

local function appendShiningSquishy(
	id: number,
	name: string,
	lvl: number,
	rarity: string,
	coinsPerSec: number,
	pos: Vector3,
	hint: string,
	zoneTag: string
)
	local pal = shiningPalette[((id - 1) % #shiningPalette) + 1]
	local entry: any = {
		Id = id,
		Name = name,
		Level = lvl,
		Rarity = rarity,
		Color = pal[1],
		SecondaryColor = pal[2],
		HatType = hatRotation[((id - 1) % #hatRotation) + 1],
		Behavior = "Static",
		CoinsPerSec = coinsPerSec,
		Hint = hint,
		Position = pos,
		IsShiningSquishy = true,
		ZoneTag = zoneTag,
		IsBoss = (rarity == "Mythic" or rarity == "Legendary"),
	}
	table.insert(SlimeData.Slimes, entry)
end

-- 1. HOUSE ROOFTOP SHINING SQUISHIES (16 Squishies: #36 to #51)
-- Players jump up bounce awnings/crates onto the properly colored house rooftops to grab these!
local rooftopPlacements = {
	-- Safe Zone Village Houses (4 South Boulevard Houses at Z = 166 + 4 Plot Houses at X = ±78)
	{ Name = "Sunny Roof Mallow", Lvl = 1, Rarity = "Common", CPS = 12, Pos = Vector3.new(-88, 24.5, 166), Hint = "Jump onto the Golden Cottage Roof on the South Boulevard of the Safe Zone!" },
	{ Name = "Sky Gables Kitty", Lvl = 1, Rarity = "Common", CPS = 14, Pos = Vector3.new(-30, 23.5, 166), Hint = "Bounce up the awning onto the Rose Villa Roof in the Safe Zone!" },
	{ Name = "Mint Chimney Puff", Lvl = 1, Rarity = "Common", CPS = 16, Pos = Vector3.new(30, 23.5, 166), Hint = "Parkour onto the Mint Cottage Roof in the Safe Zone!" },
	{ Name = "Cobalt Shingle Pup", Lvl = 1, Rarity = "Rare", CPS = 20, Pos = Vector3.new(88, 24.5, 166), Hint = "Climb the crates onto the Blue Manor Roof on the South Boulevard of the Safe Zone!" },
	{ Name = "Ranch Gables Cow", Lvl = 1, Rarity = "Rare", CPS = 22, Pos = Vector3.new(-78, 21.5, 53), Hint = "Perched atop the Plot #1 Ranch House Roof!" },
	{ Name = "Blossom Attic Axolotl", Lvl = 1, Rarity = "Rare", CPS = 24, Pos = Vector3.new(78, 21.5, 53), Hint = "Perched atop the Plot #2 Ranch House Roof!" },
	{ Name = "Clover Ridge Frog", Lvl = 1, Rarity = "Rare", CPS = 26, Pos = Vector3.new(-78, 21.5, 117), Hint = "Perched atop the Plot #3 Ranch House Roof!" },
	{ Name = "Honeycomb Loft Bear", Lvl = 1, Rarity = "Epic", CPS = 32, Pos = Vector3.new(78, 21.5, 117), Hint = "Perched atop the Plot #4 Ranch House Roof!" },
	-- Biome Village Parkour Houses (8 Houses at X = ±84 across the 5 Expanded Themed Levels)
	{ Name = "Meadow Barn Loft", Lvl = 1, Rarity = "Rare", CPS = 36, Pos = Vector3.new(-84, 22.5, -56), Hint = "Jump onto the Red Meadow Barn Roof on the left of Stage 1!" },
	{ Name = "Meadow Windmill Chick", Lvl = 1, Rarity = "Epic", CPS = 45, Pos = Vector3.new(84, 22.5, -56), Hint = "Jump onto the Yellow Meadow Cottage Roof on the right of Stage 1!" },
	{ Name = "Gingerbread Roof Mallow", Lvl = 2, Rarity = "Epic", CPS = 95, Pos = Vector3.new(-84, 22.5, -216), Hint = "Bounce onto the Pink Candy Bakery Roof in Stage 2!" },
	{ Name = "Frosting Chalet Bunny", Lvl = 2, Rarity = "Epic", CPS = 120, Pos = Vector3.new(84, 22.5, -216), Hint = "Bounce onto the Blue Icing Chalet Roof in Stage 2!" },
	{ Name = "Cabana Thatch Gecko", Lvl = 3, Rarity = "Epic", CPS = 380, Pos = Vector3.new(-84, 22.5, -376), Hint = "Jump onto the Coral Beach Cabana Roof in Stage 3!" },
	{ Name = "Tiki Bungalow Crab", Lvl = 3, Rarity = "Legendary", CPS = 520, Pos = Vector3.new(84, 22.5, -376), Hint = "Jump onto the Turquoise Surf Shack Roof in Stage 3!" },
	{ Name = "Crystal Observatory Owl", Lvl = 4, Rarity = "Legendary", CPS = 1850, Pos = Vector3.new(-84, 22.5, -536), Hint = "Perched on the Amethyst Lodge Roof in Stage 4!" },
	{ Name = "Magma Forge Wyvern", Lvl = 5, Rarity = "Mythic", CPS = 8500, Pos = Vector3.new(84, 22.5, -696), Hint = "Perched on the Obsidian Forge House Roof in Stage 5!" },
}
for i, r in ipairs(rooftopPlacements) do
	appendShiningSquishy(35 + i, r.Name, r.Lvl, r.Rarity, r.CPS, r.Pos, r.Hint, "Rooftop")
end

-- 2. GIANT RAINBOW DISAPPEARING STAIRCASE SQUISHIES (12 Squishies: #52 to #63)
-- Ascending from the dedicated Outer West Rainbow Plaza (X = -142, Z = 148) up 28 disappearing rainbow steps to the Sky Cloud Sanctuary (Z = 16)!
for i = 1, 12 do
	local stepFrac = i / 12
	local s = math.floor(i * 2.3)
	local yHeight = if i == 12 then 51.5 else (1.8 + s * 1.75)
	local zPos = if i == 12 then 16 else (148 - s * 4.5)
	local xPos = if i == 12 then -142 else (-142 + math.sin(s * 0.25) * 3.5)
	local rarity = if i == 12 then "Mythic" elseif i >= 9 then "Legendary" elseif i >= 5 then "Epic" else "Rare"
	local cps = math.floor(30 * (1.42 ^ i))
	local nameList = {
		"Red Beam Squishy",
		"Tangerine Step Puff",
		"Sunbeam Stair Mallow",
		"Emerald Cloud Hopper",
		"Sky-Blue Step Sprite",
		"Indigo Prism Kitty",
		"Violet Rainbow Boba",
		"Starlight Step Unicorn",
		"Aurora Stair Dragon",
		"Prism Halo Axolotl",
		"Celestial Cloud Bunny",
		"Rainbow Staircase Sovereign",
	}
	appendShiningSquishy(
		51 + i,
		nameList[i],
		math.clamp(math.ceil(stepFrac * 5), 1, 5),
		rarity,
		cps,
		Vector3.new(xPos, yHeight, zPos),
		"Run up the Giant Rainbow Disappearing Staircase on the West Plaza before the steps fade out!",
		"RainbowStaircase"
	)
end

-- 3. OUTER SIDE MAZES SHINING SQUISHIES (20 Squishies: #64 to #83)
-- 10 inside the Left Outer Maze (X = -116 to -172) and 10 inside the Right Outer Maze (X = +116 to +172)!
local mazeNames = {
	"Hedge Labyrinth Sprout", "Clover Maze Mouse", "Bramble Secret Frog", "Fern Alley Duckling",
	"Candy Cane Maze Bear", "Peppermint Turn Puff", "Licorice Dead-End Cat", "Gummy Corridor Pup",
	"Bamboo Maze Gecko", "Sandbar Labyrinth Crab", "Palm Hedge Toucan", "Lagoon Maze Axolotl",
	"Quartz Labyrinth Fox", "Prism Maze Spirit", "Geode Corner Golem", "Neon Hedge Moth",
	"Obsidian Maze Imp", "Cinder Labyrinth Hound", "Basalt Turn Wyrm", "Volcano Maze Phoenix",
}
for i = 1, 20 do
	local isRight = (i % 2 == 0)
	local sideSign = if isRight then 1 else -1
	local lvl = math.clamp(math.ceil(i / 4), 1, 5)
	local idxInBiome = ((i - 1) % 4) + 1
	local zBase = (SlimeData.Levels[lvl].ZStart - 26) - (idxInBiome - 1) * 34
	local laneOffset = if idxInBiome % 2 == 1 then 130 else 156
	local xPos = sideSign * laneOffset
	local rarity = if lvl == 5 then "Legendary" elseif lvl >= 3 then "Epic" else "Rare"
	local cps = math.floor(18 * (2.15 ^ (lvl - 1)) * (1 + idxInBiome * 0.25))
	appendShiningSquishy(
		63 + i,
		mazeNames[i],
		lvl,
		rarity,
		cps,
		Vector3.new(xPos, 4.2, zBase),
		string.format("Hidden inside the %s Outer Maze alongside Stage %d!", if isRight then "Right" else "Left", lvl),
		"OuterMaze"
	)
end

-- 4. CASTLE WALL BATTLEMENT SHINING SQUISHIES (19 Squishies: #84 to #102)
-- Perched along the crenellated Medieval Castle Wall walkways & corner watchtowers at X = ±108!
local castleNames = {
	"Rampart Watch Knight", "Battlement Gargoyle Puff", "Turret Crown Slime", "Drawbridge Guard Pup",
	"Parapet Archer Kitty", "Citadel Banner Cow", "Keep Tower Dragonet", "Fortress Torch Boba",
	"Stone Crenel Frog", "Watchtower Bell Owl", "Bastion Shield Bear", "Moat Wall Axolotl",
	"Royal Gatehouse Unicorn", "Spire Battlement Fox", "Garrison Wall Panda", "Crusader Crest Griffin",
	"Obsidian Rampart Drake", "Volcano Bastion Wyvern", "Grand Castle Wall Emperor",
}
for i = 1, 19 do
	local lvl = math.clamp(math.ceil((i / 19) * 5), 1, 5)
	local isRight = (i % 2 == 1)
	local sideSign = if isRight then 1 else -1
	local zPos = -12 - (i - 1) * 42
	local xPos = sideSign * 108
	local yPos = if i % 4 == 1 then 23.5 else 18.8
	local rarity = if i == 19 then "Mythic" elseif lvl >= 4 then "Legendary" elseif lvl >= 2 then "Epic" else "Rare"
	local cps = math.floor(25 * (1.32 ^ i))
	appendShiningSquishy(
		83 + i,
		castleNames[i],
		lvl,
		rarity,
		cps,
		Vector3.new(xPos, yPos, zPos),
		"Climb the Castle Wall Battlement stairs and walk the ramparts to grab this Shining Squishy!",
		"CastleWall"
	)
end

-- 5. THEMED LEVEL OBBY OBSTACLE SHINING SQUISHIES (15 Squishies: #103 to #117)
-- 3 per themed biome perched on wide, well-spaced elevated Obby platforms!
local obbyNames = {
	-- Level 1 Meadow Obby
	"Lilypad Hopper Squishy", "Log Beam Balancer", "Honeycomb Ring Champ",
	-- Level 2 Candy Obby
	"Wafer Bridge Sprinter", "Peppermint Spinner Ace", "Gummy Bear Pillar Star",
	-- Level 3 Beach Obby
	"Surfboard Balance Puff", "Coral Archway Diver", "Tiki Totem Jumper",
	-- Level 4 Crystal Obby
	"Laser Grid Dodger", "Floating Geode Hopper", "Quantum Ring Glider",
	-- Level 5 Volcano Obby
	"Lava Geyser Leaper", "Obsidian Pendulum Pro", "Inferno Obby Grandmaster",
}
for i = 1, 15 do
	local lvl = math.ceil(i / 3)
	local subIdx = ((i - 1) % 3) + 1
	local zStart = SlimeData.Levels[lvl].ZStart
	local xPos = -72 + subIdx * 11 -- X = -61, -50, -39 (Dedicated Left-Side Obby Gauntlet X = -62 to -38)
	local yPos = 9.5 + subIdx * 2.8
	local zPos = zStart - 26 - subIdx * 22 -- Z = zStart - 48, -70, -92 (within zStart - 38 to zStart - 95)
	local rarity = if lvl == 5 then "Mythic" elseif lvl >= 4 then "Legendary" elseif lvl >= 2 then "Epic" else "Rare"
	local cps = math.floor(22 * (2.3 ^ (lvl - 1)) * subIdx)
	appendShiningSquishy(
		102 + i,
		obbyNames[i],
		lvl,
		rarity,
		cps,
		Vector3.new(xPos, yPos, zPos),
		string.format("Complete the Stage %d Left-Side Elevated Obby Gauntlet to grab this Shining Squishy!", lvl),
		"BiomeObby"
	)
end

-- Finalize metadata and lookup tables for all 117 Squishies & Eggs
for _, slime in ipairs(SlimeData.Slimes) do
	local anySlime = slime :: any
	local numId = tonumber(slime.Id) or 1
	anySlime.NumericId = numId
	local sp = speciesRotation[((numId - 1) % #speciesRotation) + 1]
	local nm = string.lower(slime.Name)
	if string.find(nm, "frog") or string.find(nm, "sprout") or string.find(nm, "moss") or string.find(nm, "lily") then
		sp = "Frog"
	elseif string.find(nm, "milk") or string.find(nm, "cow") or string.find(nm, "butter") or string.find(nm, "ranch") then
		sp = "Cow"
	elseif string.find(nm, "boba") or string.find(nm, "soda") or string.find(nm, "cotton") or string.find(nm, "mallow") then
		sp = "Boba"
	elseif string.find(nm, "axolotl") or string.find(nm, "gummy") or string.find(nm, "plasma") or string.find(nm, "gecko") then
		sp = "Axolotl"
	elseif string.find(nm, "cat") or string.find(nm, "kitty") or string.find(nm, "plush") or string.find(nm, "pixel") then
		sp = "Cat"
	elseif string.find(nm, "dragon") or string.find(nm, "magma") or string.find(nm, "wyvern") or string.find(nm, "drake") then
		sp = "Dragon"
	elseif string.find(nm, "sovereign") or string.find(nm, "star") or string.find(nm, "celestial") or string.find(nm, "unicorn") then
		sp = "Unicorn"
	end
	anySlime.Species = sp
	anySlime.HatchTime = 3 + (slime.Level * 2)

	slime.Behavior = "Static"
	slime.IsCoopVault = false
	slime.IsMicroVent = false
	slime.DisguiseProp = nil

	anySlime.Id = tostring(numId)
	anySlime.BodyColor = slime.Color
	anySlime.IncomePerSec = slime.CoinsPerSec
	anySlime.CoinReward = math.max(25, slime.CoinsPerSec * 4)
	anySlime.SpawnOffset = slime.Position

	SlimeData.ById[numId] = slime
	SlimeData.ById[tostring(numId)] = slime
	if not SlimeData.ByLevel[slime.Level] then
		SlimeData.ByLevel[slime.Level] = {}
	end
	table.insert(SlimeData.ByLevel[slime.Level], slime)
end

SlimeData.TotalSquishies = #SlimeData.Slimes -- Guaranteed 117!

function SlimeData.CountFound(foundMap: { [any]: boolean }?): number
	if not foundMap then
		return 0
	end
	local count = 0
	for _, v in pairs(foundMap) do
		if v then
			count += 1
		end
	end
	return count
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



