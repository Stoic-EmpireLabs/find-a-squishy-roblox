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

function SlimeData.FormatNumber(speed: number): string
	local n = math.floor(speed or 0)
	if n >= 1_000_000_000 then
		local s = string.format("%.1fB", n / 1_000_000_000):gsub("%.0B", "B")
		return s
	elseif n >= 1_000_000 then
		local s = string.format("%.1fM", n / 1_000_000):gsub("%.0M", "M")
		return s
	elseif n >= 1_000 then
		local s = string.format("%.1fk", n / 1_000):gsub("%.0k", "k")
		return s
	else
		return tostring(n)
	end
end

SlimeData.StageHatchScales = {
	[1] = 1.00, -- Stage 1: Normal size
	[2] = 1.25, -- Stage 2: Chubby size
	[3] = 1.50, -- Stage 3: Large size
	[4] = 1.80, -- Stage 4: Jumbo size
	[5] = 2.10, -- Stage 5: Giant size
	[6] = 2.45, -- Stage 6: Mega size
	[7] = 2.80, -- Stage 7: Titan size
	[8] = 3.20, -- Stage 8: Colossal Boss-Sized Brainrot!
}

SlimeData.FenceLevels = {
	[1] = { Level = 1, Width = 24, Depth = 18, MaxBrainrots = 4, MaxStageSizeAllowed = 1, UpgradeCost = 0, Label = "Starter Wood Fence" },
	[2] = { Level = 2, Width = 28, Depth = 21, MaxBrainrots = 7, MaxStageSizeAllowed = 2, UpgradeCost = 500, Label = "Candy Wood Fence" },
	[3] = { Level = 3, Width = 32, Depth = 24, MaxBrainrots = 10, MaxStageSizeAllowed = 3, UpgradeCost = 2_500, Label = "Lagoon Timber Fence" },
	[4] = { Level = 4, Width = 36, Depth = 27, MaxBrainrots = 14, MaxStageSizeAllowed = 4, UpgradeCost = 15_000, Label = "Jade Bamboo Fence" },
	[5] = { Level = 5, Width = 40, Depth = 30, MaxBrainrots = 18, MaxStageSizeAllowed = 5, UpgradeCost = 85_000, Label = "Reinforced Iron Fence" },
	[6] = { Level = 6, Width = 44, Depth = 33, MaxBrainrots = 23, MaxStageSizeAllowed = 6, UpgradeCost = 450_000, Label = "Gilded Iron Sanctuary Fence" },
	[7] = { Level = 7, Width = 48, Depth = 36, MaxBrainrots = 29, MaxStageSizeAllowed = 7, UpgradeCost = 2_500_000, Label = "Obsidian Iron Fortress Pen" },
	[8] = { Level = 8, Width = 56, Depth = 42, MaxBrainrots = 35, MaxStageSizeAllowed = 8, UpgradeCost = 15_000_000, Label = "Colossal Cosmic Iron Enclosure" },
}

SlimeData.TreadmillTiers = {
	[1] = {
		Tier = 1,
		Name = "Starter Treadmill",
		Badge = "x1 SPEED",
		MultiplierText = "x1 SPEED",
		MultiplierLabel = "x1 SPEED",
		SpeedPerSec = 1,
		RequiredSpeed = 0,
		RequiredStage = 1,
		UpgradeCost = 0,
		Color = Color3.fromRGB(85, 225, 115),
		BeltColor = Color3.fromRGB(255, 65, 150),
		PrimaryColor = Color3.fromRGB(85, 225, 115),
		AccentColor = Color3.fromRGB(255, 235, 75),
		BeamTexture = "rbxassetid://6798365555",
		TextureSpeed = 2.4,
		ParticleTexture = "rbxassetid://9129151031",
		MeshId = "",
		TextureId = "",
	},
	[2] = {
		Tier = 2,
		Name = "Candy Treadmill",
		Badge = "x3 SPEED",
		MultiplierText = "x3 SPEED",
		MultiplierLabel = "x3 SPEED",
		SpeedPerSec = 3,
		RequiredSpeed = 25,
		RequiredStage = 2,
		UpgradeCost = 250,
		Color = Color3.fromRGB(255, 105, 195),
		BeltColor = Color3.fromRGB(255, 115, 210),
		PrimaryColor = Color3.fromRGB(255, 105, 195),
		AccentColor = Color3.fromRGB(115, 245, 255),
		BeamTexture = "rbxassetid://6798365555",
		TextureSpeed = 2.8,
		ParticleTexture = "rbxassetid://9129151031",
		MeshId = "rbxassetid://10256224170",
		TextureId = "",
	},
	[3] = {
		Tier = 3,
		Name = "Gold Treadmill",
		Badge = "x7 SPEED",
		MultiplierText = "x7 SPEED",
		MultiplierLabel = "x7 SPEED",
		SpeedPerSec = 7,
		RequiredSpeed = 80,
		RequiredStage = 3,
		UpgradeCost = 1000,
		Color = Color3.fromRGB(255, 205, 55),
		BeltColor = Color3.fromRGB(255, 185, 45),
		PrimaryColor = Color3.fromRGB(255, 205, 55),
		AccentColor = Color3.fromRGB(255, 245, 135),
		BeamTexture = "rbxassetid://123374008022599",
		TextureSpeed = 3.2,
		ParticleTexture = "rbxassetid://7451822955",
		MeshId = "rbxassetid://2682037588",
		TextureId = "",
	},
	[4] = {
		Tier = 4,
		Name = "Jade Bamboo Treadmill",
		Badge = "x15 SPEED",
		MultiplierText = "x15 SPEED",
		MultiplierLabel = "x15 SPEED",
		SpeedPerSec = 15,
		RequiredSpeed = 220,
		RequiredStage = 4,
		UpgradeCost = 3500,
		Color = Color3.fromRGB(65, 235, 145),
		BeltColor = Color3.fromRGB(45, 215, 130),
		PrimaryColor = Color3.fromRGB(65, 235, 145),
		AccentColor = Color3.fromRGB(185, 255, 115),
		BeamTexture = "rbxassetid://123374008022599",
		TextureSpeed = 3.6,
		ParticleTexture = "rbxassetid://7451822955",
		MeshId = "",
		TextureId = "",
	},
	[5] = {
		Tier = 5,
		Name = "Diamond Treadmill",
		Badge = "x35 SPEED",
		MultiplierText = "x35 SPEED",
		MultiplierLabel = "x35 SPEED",
		SpeedPerSec = 35,
		RequiredSpeed = 600,
		RequiredStage = 5,
		UpgradeCost = 12000,
		Color = Color3.fromRGB(65, 225, 255),
		BeltColor = Color3.fromRGB(0, 195, 255),
		PrimaryColor = Color3.fromRGB(65, 225, 255),
		AccentColor = Color3.fromRGB(195, 115, 255),
		BeamTexture = "rbxassetid://4887782888",
		TextureSpeed = 4.0,
		ParticleTexture = "rbxassetid://9129151031",
		MeshId = "rbxassetid://15108756532",
		TextureId = "",
	},
	[6] = {
		Tier = 6,
		Name = "Cloud Sky Treadmill",
		Badge = "x80 SPEED",
		MultiplierText = "x80 SPEED",
		MultiplierLabel = "x80 SPEED",
		SpeedPerSec = 80,
		RequiredSpeed = 1600,
		RequiredStage = 6,
		UpgradeCost = 45000,
		Color = Color3.fromRGB(145, 215, 255),
		BeltColor = Color3.fromRGB(115, 185, 255),
		PrimaryColor = Color3.fromRGB(145, 215, 255),
		AccentColor = Color3.fromRGB(255, 235, 95),
		BeamTexture = "rbxassetid://4887782888",
		TextureSpeed = 4.4,
		ParticleTexture = "rbxassetid://7451822955",
		MeshId = "rbxassetid://10256224170",
		TextureId = "",
	},
	[7] = {
		Tier = 7,
		Name = "Magma Inferno Treadmill",
		Badge = "x200 SPEED",
		MultiplierText = "x200 SPEED",
		MultiplierLabel = "x200 SPEED",
		SpeedPerSec = 200,
		RequiredSpeed = 4500,
		RequiredStage = 7,
		UpgradeCost = 175000,
		Color = Color3.fromRGB(255, 85, 35),
		BeltColor = Color3.fromRGB(255, 65, 25),
		PrimaryColor = Color3.fromRGB(255, 85, 35),
		AccentColor = Color3.fromRGB(255, 225, 65),
		BeamTexture = "rbxassetid://4887782888",
		TextureSpeed = 4.8,
		ParticleTexture = "rbxassetid://9129151031",
		MeshId = "rbxassetid://2682037588",
		TextureId = "",
	},
	[8] = {
		Tier = 8,
		Name = "Cosmic Admin Treadmill",
		Badge = "x500 SPEED",
		MultiplierText = "x500 SPEED",
		MultiplierLabel = "x500 SPEED",
		SpeedPerSec = 500,
		RequiredSpeed = 12000,
		RequiredStage = 8,
		UpgradeCost = 750000,
		Color = Color3.fromRGB(195, 75, 255),
		BeltColor = Color3.fromRGB(175, 55, 255),
		PrimaryColor = Color3.fromRGB(195, 75, 255),
		AccentColor = Color3.fromRGB(85, 245, 255),
		BeamTexture = "rbxassetid://4887782888",
		TextureSpeed = 5.4,
		ParticleTexture = "rbxassetid://7451822955",
		MeshId = "rbxassetid://15108756532",
		TextureId = "",
	},
}

SlimeData.Levels = {
	{
		Level = 1,
		Name = "Squishy Meadow",
		Subtitle = "Complete 100% of Stage 1 Squishies & Eggs + Fence Lv.2 to Unlock Stage 2!",
		ZStart = 0,
		ZEnd = -160,
		GateZ = -160,
		ThemeColor = Color3.fromRGB(95, 215, 110),
		FloorColor = Color3.fromRGB(92, 198, 78),
		RequiredPlantedCount = 0,
		EggCount = 4,
		RequiredSpeed = 0,
		GateUnlockCost = 0,
	},
	{
		Level = 2,
		Name = "Chocolate Candy Kingdom",
		Subtitle = "Complete 100% of Stage 2 Squishies & Eggs + Fence Lv.3 to Unlock Stage 3!",
		ZStart = -160,
		ZEnd = -320,
		GateZ = -320,
		ThemeColor = Color3.fromRGB(255, 115, 190),
		FloorColor = Color3.fromRGB(162, 108, 96),
		RequiredPlantedCount = 4,
		EggCount = 4,
		RequiredSpeed = 0,
		GateUnlockCost = 150,
	},
	{
		Level = 3,
		Name = "Tropical Beach Lagoon",
		Subtitle = "Complete 100% of Stage 3 Squishies & Eggs + Fence Lv.4 to Unlock Stage 4!",
		ZStart = -320,
		ZEnd = -480,
		GateZ = -480,
		ThemeColor = Color3.fromRGB(255, 205, 75),
		FloorColor = Color3.fromRGB(238, 210, 145),
		RequiredPlantedCount = 8,
		EggCount = 4,
		RequiredSpeed = 0,
		GateUnlockCost = 600,
	},
	{
		Level = 4,
		Name = "Whispering Bamboo Forest",
		Subtitle = "Complete 100% of Stage 4 Squishies & Eggs + Fence Lv.5 to Unlock Stage 5!",
		ZStart = -480,
		ZEnd = -640,
		GateZ = -640,
		ThemeColor = Color3.fromRGB(75, 225, 145),
		FloorColor = Color3.fromRGB(68, 158, 92),
		RequiredPlantedCount = 12,
		EggCount = 4,
		RequiredSpeed = 0,
		GateUnlockCost = 2500,
	},
	{
		Level = 5,
		Name = "Crystal Cyber Cavern",
		Subtitle = "Complete 100% of Stage 5 Squishies & Eggs + Fence Lv.6 to Unlock Stage 6!",
		ZStart = -640,
		ZEnd = -800,
		GateZ = -800,
		ThemeColor = Color3.fromRGB(65, 225, 255),
		FloorColor = Color3.fromRGB(72, 65, 118),
		RequiredPlantedCount = 16,
		EggCount = 4,
		RequiredSpeed = 0,
		GateUnlockCost = 10000,
	},
	{
		Level = 6,
		Name = "Cloud Sky Sanctuary",
		Subtitle = "Complete 100% of Stage 6 Squishies & Eggs + Fence Lv.7 to Unlock Stage 7!",
		ZStart = -800,
		ZEnd = -960,
		GateZ = -960,
		ThemeColor = Color3.fromRGB(135, 215, 255),
		FloorColor = Color3.fromRGB(215, 232, 250),
		RequiredPlantedCount = 20,
		EggCount = 5,
		RequiredSpeed = 0,
		GateUnlockCost = 45000,
	},
	{
		Level = 7,
		Name = "Magma Volcano Island",
		Subtitle = "Complete 100% of Stage 7 Squishies & Eggs + Fence Lv.8 to Unlock Stage 8!",
		ZStart = -960,
		ZEnd = -1120,
		GateZ = -1120,
		ThemeColor = Color3.fromRGB(255, 95, 45),
		FloorColor = Color3.fromRGB(78, 42, 42),
		RequiredPlantedCount = 25,
		EggCount = 5,
		RequiredSpeed = 0,
		GateUnlockCost = 200000,
	},
	{
		Level = 8,
		Name = "Cosmic Void Citadel",
		Subtitle = "Complete 100% of Stage 8 Cosmic Squishies & Eggs for Ultimate Mastery!",
		ZStart = -1120,
		ZEnd = -1280,
		GateZ = nil,
		ThemeColor = Color3.fromRGB(195, 85, 255),
		FloorColor = Color3.fromRGB(38, 28, 68),
		RequiredPlantedCount = 30,
		EggCount = 5,
		RequiredSpeed = 0,
		GateUnlockCost = 1000000,
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

-- 16 Giant Sleeping Bosses guarding Sector 3 of all 8 Stages ("Zzz" -> "!!" when you steal an Egg!)
SlimeData.Guardians = {
	-- Stage 1 Bosses (Z: 0 to -160, Boss Nest at Z = -116)
	{
		Id = "L1_Bear",
		Name = "Grizzly Papa Bear",
		Title = "🐻 STAGE 1 MEADOW BOSS",
		Level = 1,
		Style = "Bear",
		PrimaryColor = Color3.fromRGB(125, 78, 45),
		AccentColor = Color3.fromRGB(215, 165, 115),
		PatrolSpeed = 8,
		ChaseSpeed = 19,
		RequiredSpeedPower = 100,
		HomePosition = Vector3.new(-34, 5, -112),
		PatrolRadius = 32,
	},
	{
		Id = "L1_Brainrot",
		Name = "Tralalero Sneaker Shark",
		Title = "🦈 STAGE 1 SHARK BOSS",
		Level = 1,
		Style = "Shark",
		PrimaryColor = Color3.fromRGB(65, 155, 245),
		AccentColor = Color3.fromRGB(255, 255, 255),
		PatrolSpeed = 8,
		ChaseSpeed = 21,
		RequiredSpeedPower = 200,
		HomePosition = Vector3.new(34, 5, -120),
		PatrolRadius = 32,
	},

	-- Stage 2 Bosses (Z: -160 to -320, Boss Nest at Z = -276)
	{
		Id = "L2_Shark",
		Name = "Sour Gummy Jaws",
		Title = "🍬 STAGE 2 CANDY BOSS",
		Level = 2,
		Style = "Shark",
		PrimaryColor = Color3.fromRGB(255, 85, 175),
		AccentColor = Color3.fromRGB(115, 245, 255),
		PatrolSpeed = 9,
		ChaseSpeed = 25,
		RequiredSpeedPower = 1_000,
		HomePosition = Vector3.new(-34, 5, -272),
		PatrolRadius = 34,
	},
	{
		Id = "L2_Brainrot",
		Name = "Cappuccino Ninja",
		Title = "☕ STAGE 2 CHOCO BOSS",
		Level = 2,
		Style = "BrainrotBat",
		PrimaryColor = Color3.fromRGB(165, 115, 75),
		AccentColor = Color3.fromRGB(255, 245, 230),
		PatrolSpeed = 9,
		ChaseSpeed = 28,
		RequiredSpeedPower = 2_000,
		HomePosition = Vector3.new(34, 5, -280),
		PatrolRadius = 34,
	},

	-- Stage 3 Bosses (Z: -320 to -480, Boss Nest at Z = -436)
	{
		Id = "L3_Dino",
		Name = "Stompy Beach T-Rex",
		Title = "🦖 STAGE 3 DINO BOSS",
		Level = 3,
		Style = "Dino",
		PrimaryColor = Color3.fromRGB(95, 215, 85),
		AccentColor = Color3.fromRGB(255, 195, 55),
		PatrolSpeed = 10,
		ChaseSpeed = 32,
		RequiredSpeedPower = 10_000,
		HomePosition = Vector3.new(-34, 5, -432),
		PatrolRadius = 34,
	},
	{
		Id = "L3_Brainrot",
		Name = "Tung Tung Sahur",
		Title = "🪵 STAGE 3 LAGOON BOSS",
		Level = 3,
		Style = "BrainrotBat",
		PrimaryColor = Color3.fromRGB(195, 130, 68),
		AccentColor = Color3.fromRGB(255, 85, 65),
		PatrolSpeed = 10,
		ChaseSpeed = 35,
		RequiredSpeedPower = 20_000,
		HomePosition = Vector3.new(34, 5, -440),
		PatrolRadius = 34,
	},

	-- Stage 4 Bosses (Z: -480 to -640, Boss Nest at Z = -596)
	{
		Id = "L4_Panda",
		Name = "Jade Bamboo Panda Boss",
		Title = "🎍 STAGE 4 BAMBOO BOSS",
		Level = 4,
		Style = "Bear",
		PrimaryColor = Color3.fromRGB(55, 195, 115),
		AccentColor = Color3.fromRGB(245, 250, 240),
		PatrolSpeed = 11,
		ChaseSpeed = 39,
		RequiredSpeedPower = 100_000,
		HomePosition = Vector3.new(-34, 5, -592),
		PatrolRadius = 35,
	},
	{
		Id = "L4_Brainrot",
		Name = "Brr Brr Patapim",
		Title = "🌿 STAGE 4 FOREST BOSS",
		Level = 4,
		Style = "BrainrotBat",
		PrimaryColor = Color3.fromRGB(85, 165, 75),
		AccentColor = Color3.fromRGB(255, 215, 75),
		PatrolSpeed = 11,
		ChaseSpeed = 42,
		RequiredSpeedPower = 200_000,
		HomePosition = Vector3.new(34, 5, -600),
		PatrolRadius = 35,
	},

	-- Stage 5 Bosses (Z: -640 to -800, Boss Nest at Z = -756)
	{
		Id = "L5_Croc",
		Name = "Crystal Cyber-Croc",
		Title = "🐊 STAGE 5 CRYSTAL BOSS",
		Level = 5,
		Style = "Croc",
		PrimaryColor = Color3.fromRGB(0, 225, 195),
		AccentColor = Color3.fromRGB(255, 65, 185),
		PatrolSpeed = 11,
		ChaseSpeed = 46,
		RequiredSpeedPower = 1_000_000,
		HomePosition = Vector3.new(-34, 5, -752),
		PatrolRadius = 35,
	},
	{
		Id = "L5_Hound",
		Name = "Amethyst Mecha-Wolf",
		Title = "🐺 STAGE 5 CAVERN BOSS",
		Level = 5,
		Style = "Bear",
		PrimaryColor = Color3.fromRGB(135, 75, 235),
		AccentColor = Color3.fromRGB(0, 245, 255),
		PatrolSpeed = 11,
		ChaseSpeed = 50,
		RequiredSpeedPower = 2_000_000,
		HomePosition = Vector3.new(34, 5, -760),
		PatrolRadius = 35,
	},

	-- Stage 6 Bosses (Z: -800 to -960, Boss Nest at Z = -916)
	{
		Id = "L6_Griffin",
		Name = "Thunder Cloud Griffin",
		Title = "☁️ STAGE 6 SKY BOSS",
		Level = 6,
		Style = "Dragon",
		PrimaryColor = Color3.fromRGB(115, 205, 255),
		AccentColor = Color3.fromRGB(255, 235, 95),
		PatrolSpeed = 12,
		ChaseSpeed = 54,
		RequiredSpeedPower = 10_000_000,
		HomePosition = Vector3.new(-34, 5, -912),
		PatrolRadius = 36,
	},
	{
		Id = "L6_Hawk",
		Name = "Bombardiro Sky Hawk",
		Title = "⚡ STAGE 6 STORM BOSS",
		Level = 6,
		Style = "Dino",
		PrimaryColor = Color3.fromRGB(85, 155, 245),
		AccentColor = Color3.fromRGB(255, 215, 65),
		PatrolSpeed = 12,
		ChaseSpeed = 58,
		RequiredSpeedPower = 20_000_000,
		HomePosition = Vector3.new(34, 5, -920),
		PatrolRadius = 36,
	},

	-- Stage 7 Bosses (Z: -960 to -1120, Boss Nest at Z = -1076)
	{
		Id = "L7_Dragon",
		Name = "Inferno Magma Dragon",
		Title = "🐉 STAGE 7 VOLCANO BOSS",
		Level = 7,
		Style = "Dragon",
		PrimaryColor = Color3.fromRGB(235, 55, 35),
		AccentColor = Color3.fromRGB(255, 215, 55),
		PatrolSpeed = 12,
		ChaseSpeed = 62,
		RequiredSpeedPower = 100_000_000,
		HomePosition = Vector3.new(-34, 5, -1072),
		PatrolRadius = 36,
	},
	{
		Id = "L7_Titan",
		Name = "Lava Titan Rex",
		Title = "🔥 STAGE 7 MAGMA BOSS",
		Level = 7,
		Style = "Dino",
		PrimaryColor = Color3.fromRGB(165, 45, 225),
		AccentColor = Color3.fromRGB(255, 125, 35),
		PatrolSpeed = 12,
		ChaseSpeed = 66,
		RequiredSpeedPower = 200_000_000,
		HomePosition = Vector3.new(34, 5, -1080),
		PatrolRadius = 36,
	},

	-- Stage 8 Bosses (Z: -1120 to -1280, Boss Nest at Z = -1236)
	{
		Id = "L8_Leviathan",
		Name = "Cosmic Void Leviathan",
		Title = "🌌 STAGE 8 COSMIC BOSS",
		Level = 8,
		Style = "Shark",
		PrimaryColor = Color3.fromRGB(165, 55, 255),
		AccentColor = Color3.fromRGB(65, 245, 255),
		PatrolSpeed = 13,
		ChaseSpeed = 70,
		RequiredSpeedPower = 500_000_000,
		HomePosition = Vector3.new(-34, 5, -1232),
		PatrolRadius = 36,
	},
	{
		Id = "L8_Sovereign",
		Name = "Galactic Singularity Dragon",
		Title = "👑 STAGE 8 VOID BOSS",
		Level = 8,
		Style = "Dragon",
		PrimaryColor = Color3.fromRGB(255, 65, 195),
		AccentColor = Color3.fromRGB(255, 235, 85),
		PatrolSpeed = 13,
		ChaseSpeed = 75,
		RequiredSpeedPower = 1_000_000_000,
		HomePosition = Vector3.new(34, 5, -1240),
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
	[4] = Enum.Material.Grass,
	[5] = Enum.Material.Slate,
	[6] = Enum.Material.Marble,
	[7] = Enum.Material.Basalt,
	[8] = Enum.Material.CrackedLava,
}

local requiredSpeeds = {
	[1] = 0,
	[2] = 25,
	[3] = 80,
	[4] = 220,
	[5] = 600,
	[6] = 1600,
	[7] = 4500,
	[8] = 12000,
}

local gateUnlockCosts = {
	[1] = 0,
	[2] = 150,
	[3] = 600,
	[4] = 2500,
	[5] = 10000,
	[6] = 45000,
	[7] = 200000,
	[8] = 1000000,
}

local stageMasteryJackpots = {
	[1] = 2_500,
	[2] = 8_000,
	[3] = 25_000,
	[4] = 85_000,
	[5] = 300_000,
	[6] = 1_200_000,
	[7] = 5_000_000,
	[8] = 25_000_000,
}

for _, levelDef in ipairs(SlimeData.Levels) do
	local lvl = levelDef.Level
	local anyLvl = levelDef :: any
	anyLvl.Id = lvl
	anyLvl.SecondaryColor = levelDef.ThemeColor
	anyLvl.GateColor = levelDef.ThemeColor
	anyLvl.FloorMaterial = floorMaterials[lvl] or Enum.Material.SmoothPlastic
	anyLvl.RequiredSpeed = requiredSpeeds[lvl] or 0
	anyLvl.RequiredFenceLevel = lvl
	anyLvl.GateUnlockCost = gateUnlockCosts[lvl] or 0
	anyLvl.StageMasteryJackpot = stageMasteryJackpots[lvl] or 2_500
	anyLvl.RequiredCoins = gateUnlockCosts[lvl] or ((lvl - 1) * 500)
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

-- 35 Hatchable Brainrots (#1 to #35) across all 8 Stages (4, 4, 4, 4, 4, 5, 5, 5 per Stage) in Sector 3 (zStart - 116)
local brainrotDefinitions = {
	-- Stage 1 (Scale 1.00x)
	[1] = { Name = "Tralalero Tralala", Rarity = "Common", ModelIdx = 1, CPS = 10, Reward = 50 },
	[2] = { Name = "Lirili Larila", Rarity = "Common", ModelIdx = 4, CPS = 14, Reward = 70 },
	[3] = { Name = "Trippi Troppi", Rarity = "Rare", ModelIdx = 10, CPS = 22, Reward = 110 },
	[4] = { Name = "Burbaloni Luliloli", Rarity = "Epic", ModelIdx = 13, CPS = 35, Reward = 180 },
	-- Stage 2 (Scale 1.25x)
	[5] = { Name = "Cappuccino Ninja", Rarity = "Common", ModelIdx = 6, CPS = 45, Reward = 220 },
	[6] = { Name = "Ballerina Cappuccina", Rarity = "Rare", ModelIdx = 9, CPS = 65, Reward = 320 },
	[7] = { Name = "Chimpanzini Bananini", Rarity = "Epic", ModelIdx = 7, CPS = 95, Reward = 480 },
	[8] = { Name = "Frigo Camelo", Rarity = "Legendary", ModelIdx = 11, CPS = 140, Reward = 700 },
	-- Stage 3 (Scale 1.50x)
	[9] = { Name = "Tung Tung Tung Sahur", Rarity = "Rare", ModelIdx = 3, CPS = 180, Reward = 900 },
	[10] = { Name = "Bombardiro Crocodilo", Rarity = "Epic", ModelIdx = 2, CPS = 260, Reward = 1_300 },
	[11] = { Name = "Bombombini Gusini", Rarity = "Epic", ModelIdx = 12, CPS = 380, Reward = 1_900 },
	[12] = { Name = "Glorbo Fruttodrillo", Rarity = "Legendary", ModelIdx = 14, CPS = 550, Reward = 2_800 },
	-- Stage 4 (Scale 1.80x)
	[13] = { Name = "Brr Brr Patapim", Rarity = "Rare", ModelIdx = 5, CPS = 750, Reward = 3_800 },
	[14] = { Name = "Orangutini Ananasini", Rarity = "Epic", ModelIdx = 7, CPS = 1_100, Reward = 5_500 },
	[15] = { Name = "Boneca Ambalabu", Rarity = "Legendary", ModelIdx = 4, CPS = 1_650, Reward = 8_200 },
	[16] = { Name = "Trulimero Trulicina", Rarity = "Legendary", ModelIdx = 10, CPS = 2_400, Reward = 12_000 },
	-- Stage 5 (Scale 2.10x)
	[17] = { Name = "Girafa Celestre", Rarity = "Epic", ModelIdx = 11, CPS = 3_500, Reward = 17_500 },
	[18] = { Name = "Bri Bri Bicus Dicus", Rarity = "Epic", ModelIdx = 6, CPS = 5_200, Reward = 26_000 },
	[19] = { Name = "Garamaraman", Rarity = "Legendary", ModelIdx = 3, CPS = 7_800, Reward = 39_000 },
	[20] = { Name = "Maxwell The Spinning Cat", Rarity = "Mythic", ModelIdx = 15, CPS = 12_000, Reward = 60_000 },
	-- Stage 6 (Scale 2.45x)
	[21] = { Name = "La Vaca Saturno Saturnita", Rarity = "Epic", ModelIdx = 8, CPS = 16_000, Reward = 80_000 },
	[22] = { Name = "Il Cacto Hipopotamo", Rarity = "Legendary", ModelIdx = 13, CPS = 24_000, Reward = 120_000 },
	[23] = { Name = "Blueberrinni Octopussini", Rarity = "Legendary", ModelIdx = 10, CPS = 36_000, Reward = 180_000 },
	[24] = { Name = "Chef Crabracadabra", Rarity = "Mythic", ModelIdx = 6, CPS = 52_000, Reward = 260_000 },
	[25] = { Name = "Chicleteira Bicicleteira", Rarity = "Mythic", ModelIdx = 9, CPS = 75_000, Reward = 375_000 },
	-- Stage 7 (Scale 2.80x)
	[26] = { Name = "Spijuniro Golubiro", Rarity = "Legendary", ModelIdx = 12, CPS = 105_000, Reward = 525_000 },
	[27] = { Name = "Tigrrullini Watermellini", Rarity = "Legendary", ModelIdx = 14, CPS = 155_000, Reward = 775_000 },
	[28] = { Name = "Zibra Zubra Zibralini", Rarity = "Mythic", ModelIdx = 11, CPS = 230_000, Reward = 1_150_000 },
	[29] = { Name = "Graipussi Medussi", Rarity = "Mythic", ModelIdx = 8, CPS = 340_000, Reward = 1_700_000 },
	[30] = { Name = "Inferno Bombardiro Rex", Rarity = "Mythic", ModelIdx = 2, CPS = 500_000, Reward = 2_500_000 },
	-- Stage 8 (Scale 3.20x Colossal)
	[31] = { Name = "Gattatino Neonino", Rarity = "Legendary", ModelIdx = 15, CPS = 720_000, Reward = 3_600_000 },
	[32] = { Name = "Matteo The Wise", Rarity = "Mythic", ModelIdx = 5, CPS = 1_050_000, Reward = 5_250_000 },
	[33] = { Name = "Udin Din Din Dun", Rarity = "Mythic", ModelIdx = 3, CPS = 1_550_000, Reward = 7_750_000 },
	[34] = { Name = "Skibidi Cyber Titan", Rarity = "Mythic", ModelIdx = 16, CPS = 2_300_000, Reward = 11_500_000 },
	[35] = { Name = "Cosmic Tralalero God", Rarity = "Mythic", ModelIdx = 1, CPS = 3_500_000, Reward = 17_500_000 },
}

local levelEggIndices: { [number]: number } = {}
for idx, slime in ipairs(SlimeData.Slimes) do
	local anySlime = slime :: any
	anySlime.IsShiningSquishy = false
	anySlime.IsBrainrot = true
	anySlime.ZoneTag = "BossNest"

	local assignedLvl = if idx <= 4 then 1
		elseif idx <= 8 then 2
		elseif idx <= 12 then 3
		elseif idx <= 16 then 4
		elseif idx <= 20 then 5
		elseif idx <= 25 then 6
		elseif idx <= 30 then 7
		else 8

	slime.Level = assignedLvl
	local bDef = brainrotDefinitions[idx]
	if bDef then
		slime.Name = bDef.Name
		slime.Rarity = bDef.Rarity
		slime.CoinsPerSec = bDef.CPS
		anySlime.BrainrotModelIndex = bDef.ModelIdx
		anySlime.CustomCoinReward = bDef.Reward
	end
	anySlime.StageHatchScale = SlimeData.StageHatchScales[assignedLvl] or 1.0

	local lvlDef = SlimeData.Levels[assignedLvl]
	levelEggIndices[assignedLvl] = (levelEggIndices[assignedLvl] or 0) + 1
	local idxInLvl = levelEggIndices[assignedLvl]
	local totalInLvl = if lvlDef then lvlDef.EggCount else 4
	local zCenter = if lvlDef then (lvlDef.ZStart - 116) else (-160 * (assignedLvl - 1) - 116)
	local frac = if totalInLvl > 1 then (idxInLvl - 1) / (totalInLvl - 1) else 0.5
	local xPos = -68 + frac * 136
	local zOffset = if idxInLvl % 2 == 0 then -14 else 14
	slime.Position = Vector3.new(xPos, 3.8, zCenter + zOffset)
	slime.Hint = string.format("Hatchable Brainrot #%d (%s)! Steal a Stage %d Brainrot Egg from the Sleeping Boss Nest and hatch it at your Fence!", idx, slime.Name, assignedLvl)
end

-- ============================================================================
-- GENERATE 82 SHINING COLLECTIBLE SQUISHIES (#36 to #117) -> MAX = 117 TOTAL!
-- Distributed across all 8 Stages (Z < 0 — ZERO wild Squishies in the Safe Zone!)
-- inside Unique Stage Landmarks, Secret Caves, Attics, Giant Rainbow Staircase,
-- Outer Side Mazes, Castle Wall Battlements, and Custom Stage Obby Courses!
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

-- 1. UNIQUE LANDMARK & ROOFTOP SHINING SQUISHIES (16 Squishies: #36 to #51)
-- Hidden inside Secret Caves, Attics, Ship Holds, and atop Stage 1..8 Landmarks & Houses!
local rooftopPlacements = {
	-- Stage 1..8 Right-Side Landmarks & Secret Interiors
	{ Name = "Sunny Cave Mallow", Lvl = 1, Rarity = "Common", CPS = 18, Pos = Vector3.new(-114, 2.5, -56), Hint = "Hidden inside the red Meadow Walk-In Cottage at (-114, 2, -56) on the left side of Stage 1!" },
	{ Name = "Carousel Ride Kitty", Lvl = 2, Rarity = "Rare", CPS = 65, Pos = Vector3.new(80, 14.5, -215), Hint = "Hidden inside the Spinning Candy Carousel Ride at (80, 14, -215) in Stage 2!" },
	{ Name = "Water Slide Splash Puff", Lvl = 3, Rarity = "Rare", CPS = 190, Pos = Vector3.new(82, 22.5, -375), Hint = "Climb the Giant Water Slide Tower on the right side of Stage 3!" },
	{ Name = "Dragon Shrine Pup", Lvl = 4, Rarity = "Epic", CPS = 520, Pos = Vector3.new(68, 16.5, -525), Hint = "Perched atop the East Twin Stone Dragon Statue in Stage 4!" },
	{ Name = "Retro Arcade Cow", Lvl = 5, Rarity = "Epic", CPS = 1_450, Pos = Vector3.new(-74, 16.5, -765), Hint = "Hidden atop the Retro Arcade Hall in Stage 5!" },
	{ Name = "Ice Palace Axolotl", Lvl = 6, Rarity = "Legendary", CPS = 4_200, Pos = Vector3.new(85, 24.5, -885), Hint = "Hidden inside the upper Marble Cloud & Ice Palace Spire in Stage 6!" },
	{ Name = "Magma Bastion Frog", Lvl = 7, Rarity = "Legendary", CPS = 11_500, Pos = Vector3.new(114, 22.5, -1054), Hint = "Perched atop the Magma Bastion House Roof on the right side of Stage 7!" },
	{ Name = "Portal Pedestal Bear", Lvl = 8, Rarity = "Mythic", CPS = 32_000, Pos = Vector3.new(84, 18.5, -1185), Hint = "Hovering above the Glowing Magical Portal Pedestal on the right side of Stage 8!" },
	-- Stage 1..8 Left-Side Village & Landmark Interiors
	{ Name = "Mushroom Cottage Loft", Lvl = 1, Rarity = "Rare", CPS = 45, Pos = Vector3.new(-72, 14.5, -118), Hint = "Tucked atop the Spotted Mushroom Cottage cap on the left of Stage 1!" },
	{ Name = "Gingerbread Attic Mallow", Lvl = 2, Rarity = "Epic", CPS = 120, Pos = Vector3.new(-114, 22.5, -216), Hint = "Tucked behind the Pink Candy Bakery chimney on the left of Stage 2!" },
	{ Name = "Captain's Hold Gecko", Lvl = 3, Rarity = "Epic", CPS = 380, Pos = Vector3.new(-114, 22.5, -376), Hint = "Hidden on the Coral Beach Cabana Roof near the Pirate Ship in Stage 3!" },
	{ Name = "Bamboo Dojo Crane", Lvl = 4, Rarity = "Epic", CPS = 980, Pos = Vector3.new(114, 22.5, -536), Hint = "Jump onto the Jade Bamboo Dojo Roof in Stage 4!" },
	{ Name = "Sky Sanctum Pegasus", Lvl = 6, Rarity = "Legendary", CPS = 6_200, Pos = Vector3.new(114, 22.5, -856), Hint = "Perched on the Cloud Temple Villa Roof in Stage 6!" },
	{ Name = "Crystal Walk-In Owl", Lvl = 5, Rarity = "Legendary", CPS = 2_400, Pos = Vector3.new(-114, 2.5, -696), Hint = "Hidden inside the purple Crystal Walk-In House at (-114, 2, -696) on the left side of Stage 5!" },
	{ Name = "Magma Forge Wyvern", Lvl = 7, Rarity = "Mythic", CPS = 16_500, Pos = Vector3.new(-114, 22.5, -1016), Hint = "Perched on the Obsidian Forge House Roof in Stage 7!" },
	{ Name = "Cosmic Citadel Astral Cat", Lvl = 8, Rarity = "Mythic", CPS = 45_000, Pos = Vector3.new(114, 22.5, -1176), Hint = "Perched on the Nebula Spire Manor Roof in Stage 8!" },
}
for i, r in ipairs(rooftopPlacements) do
	appendShiningSquishy(35 + i, r.Name, r.Lvl, r.Rarity, r.CPS, r.Pos, r.Hint, "Rooftop")
end

-- 2. GIANT RAINBOW DISAPPEARING STAIRCASE SQUISHIES (12 Squishies: #52 to #63)
-- Ascending inside Stage 1's Outer West Rainbow Sky Plaza (X = -236, Z = -22 to Z = -148 — completely out of the Safe Zone!)
for i = 1, 12 do
	local s = math.floor(i * 2.3)
	local yHeight = if i == 12 then 51.5 else (1.8 + s * 1.75)
	local zPos = if i == 12 then -148 else (-22 - s * 4.5)
	local xPos = if i == 12 then -236 else (-236 + math.sin(s * 0.25) * 3.5)
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
		1,
		rarity,
		cps,
		Vector3.new(xPos, yHeight, zPos),
		"Run up Stage 1's Giant Rainbow Disappearing Staircase on the West Sky Plaza before the steps fade out!",
		"RainbowStaircase"
	)
end

-- 3. OUTER SIDE MAZES SHINING SQUISHIES (20 Squishies: #64 to #83)
-- Distributed across all 8 Widened Stages inside the Left Outer Maze (X = -154 to -210) and Right Outer Maze (X = +154 to +210)!
local mazeNames = {
	"Hedge Labyrinth Sprout", "Clover Maze Mouse", "Bramble Secret Frog",
	"Candy Cane Maze Bear", "Peppermint Turn Puff", "Licorice Dead-End Cat",
	"Bamboo Maze Gecko", "Sandbar Labyrinth Crab", "Palm Hedge Toucan",
	"Jade Stalk Panda", "Lotus Lantern Koi",
	"Quartz Labyrinth Fox", "Prism Maze Spirit", "Geode Corner Golem",
	"Nimbus Cloud Puff", "Zephyr Maze Falcon",
	"Obsidian Maze Imp", "Cinder Labyrinth Hound",
	"Nebula Void Moth", "Cosmic Labyrinth Phoenix",
}
local mazeStageCounts: { [number]: number } = {}
for i = 1, 20 do
	local isRight = (i % 2 == 0)
	local sideSign = if isRight then 1 else -1
	local lvl = math.clamp(math.ceil((i / 20) * 8), 1, 8)
	mazeStageCounts[lvl] = (mazeStageCounts[lvl] or 0) + 1
	local idxInBiome = mazeStageCounts[lvl]
	local zBase = (SlimeData.Levels[lvl].ZStart - 28) - (idxInBiome - 1) * 38
	local laneOffset = if idxInBiome % 2 == 1 then 168 else 194
	local xPos = sideSign * laneOffset
	local rarity = if lvl >= 7 then "Mythic" elseif lvl >= 5 then "Legendary" elseif lvl >= 3 then "Epic" else "Rare"
	local cps = math.floor(20 * (2.2 ^ (lvl - 1)) * (1 + idxInBiome * 0.25))
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
-- Perched along the widened Crenellated Castle Wall walkways & corner watchtowers (X = ±146) across all 8 Stages!
local castleNames = {
	"Rampart Watch Knight", "Battlement Gargoyle Puff", "Turret Crown Slime", "Drawbridge Guard Pup",
	"Parapet Archer Kitty", "Citadel Banner Cow", "Keep Tower Dragonet", "Fortress Torch Boba",
	"Stone Crenel Frog", "Watchtower Bell Owl", "Bastion Shield Bear", "Moat Wall Axolotl",
	"Royal Gatehouse Unicorn", "Spire Battlement Fox", "Garrison Wall Panda", "Crusader Crest Griffin",
	"Obsidian Rampart Drake", "Volcano Bastion Wyvern", "Grand Castle Wall Emperor",
}
local castleStageCounts: { [number]: number } = {}
for i = 1, 19 do
	local lvl = math.clamp(math.ceil((i / 19) * 8), 1, 8)
	castleStageCounts[lvl] = (castleStageCounts[lvl] or 0) + 1
	local idxInBiome = castleStageCounts[lvl]
	local isRight = (i % 2 == 1)
	local sideSign = if isRight then 1 else -1
	local zPos = (SlimeData.Levels[lvl].ZStart - 24) - (idxInBiome - 1) * 44
	local xPos = sideSign * 146
	local yPos = if idxInBiome == 1 then 23.5 else 18.8
	local rarity = if i == 19 or lvl >= 7 then "Mythic" elseif lvl >= 5 then "Legendary" elseif lvl >= 3 then "Epic" else "Rare"
	local cps = math.floor(25 * (1.36 ^ i))
	appendShiningSquishy(
		83 + i,
		castleNames[i],
		lvl,
		rarity,
		cps,
		Vector3.new(xPos, yPos, zPos),
		string.format("Climb the Stage %d Castle Wall Battlement stairs and walk the ramparts!", lvl),
		"CastleWall"
	)
end

-- 5. CUSTOM STAGE 1-8 OBBY & HIGH LANDMARK SHINING SQUISHIES (15 Squishies: #103 to #117)
-- Placed directly at the high summit destinations of the Phase 2.3 Stage 1-8 Custom Obby Courses!
local obbyPlacements = {
	-- Stage 1 Obbies: Treehouse Roof & Dutch Windmill Balcony
	{ Name = "Oak Treehouse Hopper", Lvl = 1, Rarity = "Rare", CPS = 28, Pos = Vector3.new(78, 26.8, -65), Hint = "Bounce up the Stage 1 Trampoline & Sweeper Obby to the Giant Oak Treehouse Roof!" },
	{ Name = "Dutch Windmill Balancer", Lvl = 1, Rarity = "Epic", CPS = 56, Pos = Vector3.new(-78, 28.8, -55), Hint = "Cross the high rope bridge from the Treehouse to the Spinning Dutch Windmill Balcony in Stage 1!" },
	-- Stage 2 Obbies: Gingerbread Attic Chimney & High Cocoa Platform
	{ Name = "Gingerbread Chimney Sprinter", Lvl = 2, Rarity = "Rare", CPS = 125, Pos = Vector3.new(-82, 30.8, -210), Hint = "Complete the Peppermint Knockback Spinner Obby to reach the Gingerbread Mansion Chimney in Stage 2!" },
	{ Name = "High Cocoa Spinner Ace", Lvl = 2, Rarity = "Epic", CPS = 250, Pos = Vector3.new(-75, 36.8, -255), Hint = "Cross the Wafer Bridge to the High Cocoa Platform at (-75, 36, -255) in Stage 2!" },
	-- Stage 3 Obbies: Pirate Ship Crow's Nest & Lighthouse Lantern Room
	{ Name = "Pirate Crow's Nest Puff", Lvl = 3, Rarity = "Epic", CPS = 540, Pos = Vector3.new(-84, 38.8, -390), Hint = "Climb the Moving Surfboard & Rigging Ladder Obby to the Pirate Ship Crow's Nest in Stage 3!" },
	{ Name = "Lighthouse Lantern Diver", Lvl = 3, Rarity = "Legendary", CPS = 1_080, Pos = Vector3.new(76, 42.8, -445), Hint = "Scale the Coastal Lighthouse spiral to the top Lantern Room at (76, 42, -445) in Stage 3!" },
	-- Stage 4 Obbies: Canopy Suspension Treehouse & 3rd-Floor Pagoda Bell Chamber
	{ Name = "Bamboo Canopy Vault Frog", Lvl = 4, Rarity = "Epic", CPS = 2_400, Pos = Vector3.new(82, 34.8, -575), Hint = "Jump the Bamboo Poles & Truss Wall to the Canopy Suspension Treehouse in Stage 4!" },
	{ Name = "Pagoda Bell Chamber Glider", Lvl = 4, Rarity = "Legendary", CPS = 4_800, Pos = Vector3.new(-82, 36.8, -585), Hint = "Balance across the narrow bamboo beam to the 3rd-Floor Pagoda Bell Chamber in Stage 4!" },
	-- Stage 5 Obbies: Cyber Tower Penthouse & Floating Geode Summit
	{ Name = "Cyber Penthouse Dodger", Lvl = 5, Rarity = "Legendary", CPS = 10_500, Pos = Vector3.new(84, 44.8, -715), Hint = "Beat the Disappearing Tiles & Sweeper Spinner Tower to reach the Cyber Tower Penthouse in Stage 5!" },
	{ Name = "Amethyst Spire Hopper", Lvl = 5, Rarity = "Legendary", CPS = 21_000, Pos = Vector3.new(-84, 28.8, -700), Hint = "Climb the outer crystal ledges to the top of the Amethyst Crystal Cave Spire in Stage 5!" },
	-- Stage 6 Obbies: Ferris Wheel Top Cabin & High Arching Sky Bridge
	{ Name = "Ferris Wheel Summit Jumper", Lvl = 6, Rarity = "Legendary", CPS = 46_000, Pos = Vector3.new(-85, 48.8, -865), Hint = "Bounce up the Cloud Trampoline Chain onto the Giant Sky Ferris Wheel Top Cabin in Stage 6!" },
	{ Name = "Rainbow Sky Bridge Sprite", Lvl = 6, Rarity = "Mythic", CPS = 92_000, Pos = Vector3.new(0, 29.2, -915), Hint = "Cross the High Arching Sky Bridge over the highway at (0, 29, -915) in Stage 6!" },
	-- Stage 7 Obbies: Volcano Crater Rim & Obsidian Fortress Roof
	{ Name = "Volcano Crater Leaper", Lvl = 7, Rarity = "Mythic", CPS = 200_000, Pos = Vector3.new(-86, 46.8, -1035), Hint = "Survive the Spinning Fire-Bar & Crumbling Basalt Obby to the Erupting Volcano Crater Rim in Stage 7!" },
	{ Name = "Obsidian Fortress Pro", Lvl = 7, Rarity = "Mythic", CPS = 400_000, Pos = Vector3.new(86, 42.8, -1045), Hint = "Leap across the magma vents to the Obsidian Fortress Roof at (86, 42, -1045) in Stage 7!" },
	-- Stage 8 Obby: UFO Mothership & Golden Throne Summit
	{ Name = "UFO Mothership Grandmaster", Lvl = 8, Rarity = "Mythic", CPS = 950_000, Pos = Vector3.new(-84, 36.8, -1185), Hint = "Conquer the Anti-Gravity Bounce Pad & Disappearing Cosmic Tile Gauntlet into the UFO Mothership in Stage 8!" },
}
for i, o in ipairs(obbyPlacements) do
	appendShiningSquishy(102 + i, o.Name, o.Lvl, o.Rarity, o.CPS, o.Pos, o.Hint, "BiomeObby")
end

-- Finalize metadata and lookup tables for all 117 Squishies & Brainrot Eggs
for _, slime in ipairs(SlimeData.Slimes) do
	local anySlime = slime :: any
	local numId = tonumber(slime.Id) or 1
	anySlime.NumericId = numId
	anySlime.UnlockOrder = numId
	anySlime.IsBrainrotEgg = (numId <= 35)
	anySlime.Type = if numId <= 35 then "Egg" else "Squishy"

	-- Strictly align every Squishy/Egg's Level (1..8) with its actual physical Stage Z-coordinate
	-- so completing 100% of a Stage never requires entering a locked future Stage!
	local z = slime.Position.Z
	if z >= -160 then
		slime.Level = 1
	elseif z >= -320 then
		slime.Level = 2
	elseif z >= -480 then
		slime.Level = 3
	elseif z >= -640 then
		slime.Level = 4
	elseif z >= -800 then
		slime.Level = 5
	elseif z >= -960 then
		slime.Level = 6
	elseif z >= -1120 then
		slime.Level = 7
	else
		slime.Level = 8
	end

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
	anySlime.AccentColor = slime.SecondaryColor
	anySlime.IncomePerSec = slime.CoinsPerSec
	anySlime.CoinReward = anySlime.CustomCoinReward or math.max(25, slime.CoinsPerSec * 4)
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

function SlimeData.GetLevelProgress(foundMap: { [any]: boolean }?, levelNum: number): (number, number)
	local list = SlimeData.ByLevel[levelNum] or {}
	local total = #list
	local found = 0
	if foundMap then
		for _, slime in ipairs(list) do
			local sId = tostring((slime :: any).Id)
			if foundMap[sId] or foundMap[ tonumber(sId) :: any ] then
				found += 1
			end
		end
	end
	return found, total
end

SlimeData.CountLevelProgress = SlimeData.GetLevelProgress

function SlimeData.GetStageBreakdown(foundMap: { [any]: boolean }?, levelNum: number): (number, number, number, number)
	local list = SlimeData.ByLevel[levelNum] or {}
	local foundBrainrots = 0
	local totalBrainrots = 0
	local foundSquishies = 0
	local totalSquishies = 0
	for _, slime in ipairs(list) do
		local anySlime = slime :: any
		local sId = tostring(anySlime.Id)
		local numId = tonumber(anySlime.UnlockOrder or anySlime.NumericId or anySlime.Id) or 1
		local isFound = foundMap ~= nil and (foundMap[sId] == true or foundMap[numId] == true)
		if numId <= 35 then
			totalBrainrots += 1
			if isFound then
				foundBrainrots += 1
			end
		else
			totalSquishies += 1
			if isFound then
				foundSquishies += 1
			end
		end
	end
	return foundBrainrots, totalBrainrots, foundSquishies, totalSquishies
end

function SlimeData.GetStageMasteryJackpot(levelNum: number): number
	local lvlDef = SlimeData.Levels[levelNum] :: any
	return if lvlDef and lvlDef.StageMasteryJackpot then lvlDef.StageMasteryJackpot else math.floor(2_500 * (3.2 ^ math.max(0, levelNum - 1)))
end

function SlimeData.GetStageGateUnlockCost(targetLevel: number): number
	local lvlDef = SlimeData.Levels[targetLevel] :: any
	return if lvlDef and lvlDef.GateUnlockCost then lvlDef.GateUnlockCost else 0
end

function SlimeData.GetStageGateStatus(
	foundMap: { [any]: boolean }?,
	speedStat: number?,
	fenceLevel: number?,
	unlockedGates: { [string]: boolean }?,
	targetLevel: number
)
	if targetLevel <= 1 then
		return {
			Unlocked = true,
			RequirementsMet = true,
			FoundBrainrots = 0,
			TotalBrainrots = 0,
			FoundSquishies = 0,
			TotalSquishies = 0,
			RequiredFenceLevel = 1,
			CurrentFenceLevel = fenceLevel or 1,
			RequiredSpeed = 0,
			CurrentSpeed = speedStat or 18,
			GateCost = 0,
		}
	end

	local prevStage = targetLevel - 1
	local fBrainrots, tBrainrots, fSquishies, tSquishies = SlimeData.GetStageBreakdown(foundMap, prevStage)
	local lvlDef = SlimeData.Levels[targetLevel] :: any
	local reqSpeed = 0
	local reqSpd = 0
	local reqFence = if lvlDef then (lvlDef.RequiredFenceLevel or targetLevel) else targetLevel
	local gateCost = SlimeData.GetStageGateUnlockCost(targetLevel)
	local curFence = if fenceLevel ~= nil then fenceLevel else targetLevel
	local curSpd = speedStat or 16

	local allPrevDone = true
	for prev = 1, prevStage do
		local fb, tb, fs, ts = SlimeData.GetStageBreakdown(foundMap, prev)
		if (tb > 0 and fb < tb) or (ts > 0 and fs < ts) then
			allPrevDone = false
			break
		end
	end

	local speedOk = true
	local reqsMet = allPrevDone and (curFence >= reqFence) and speedOk
	local gatePaid = if unlockedGates ~= nil then (unlockedGates[tostring(targetLevel)] == true) else true

	return {
		Unlocked = reqsMet and gatePaid,
		RequirementsMet = reqsMet,
		GatePaid = gatePaid,
		FoundBrainrots = fBrainrots,
		TotalBrainrots = tBrainrots,
		FoundSquishies = fSquishies,
		TotalSquishies = tSquishies,
		RequiredFenceLevel = reqFence,
		CurrentFenceLevel = curFence,
		RequiredSpeed = reqSpeed,
		CurrentSpeed = curSpd,
		GateCost = gateCost,
	}
end

function SlimeData.IsLevelUnlocked(
	foundMap: { [any]: boolean }?,
	speedStat: number,
	targetLevel: number,
	fenceLevel: number?,
	unlockedGates: { [string]: boolean }?
): boolean
	if targetLevel <= 1 then
		return true
	end
	local status = SlimeData.GetStageGateStatus(foundMap, speedStat, fenceLevel, unlockedGates, targetLevel)
	return status.Unlocked
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

function SlimeData.GetFenceLevelDef(fenceLevel: number)
	local lvl = math.clamp(math.floor(fenceLevel or 1), 1, #SlimeData.FenceLevels)
	return SlimeData.FenceLevels[lvl]
end

function SlimeData.GetMaxBrainrotsForFenceLevel(fenceLevel: number): number
	local def = SlimeData.GetFenceLevelDef(fenceLevel)
	return if def then def.MaxBrainrots else 4
end

function SlimeData.GetFenceUpgradeCost(currentFenceLevel: number): number?
	local nextLvl = math.floor(currentFenceLevel or 1) + 1
	local nextDef = SlimeData.FenceLevels[nextLvl]
	if not nextDef then
		return nil
	end
	return nextDef.UpgradeCost
end

function SlimeData.GetHintCostForStage(stageNum: number): number
	local lvl = math.clamp(math.floor(stageNum or 1), 1, 8)
	local costs = {
		[1] = 150,
		[2] = 600,
		[3] = 2_400,
		[4] = 10_000,
		[5] = 45_000,
		[6] = 200_000,
		[7] = 950_000,
		[8] = 4_500_000,
	}
	return costs[lvl] or 150
end

function SlimeData.GetStageHatchScale(stageNum: number): number
	local lvl = math.clamp(math.floor(stageNum or 1), 1, 8)
	local scales = SlimeData.StageHatchScales or {
		[1] = 1.00,
		[2] = 1.25,
		[3] = 1.50,
		[4] = 1.80,
		[5] = 2.10,
		[6] = 2.45,
		[7] = 2.80,
		[8] = 3.20,
	}
	return scales[lvl] or (1.0 + (lvl - 1) * 0.28)
end

-- Weighted Random Brainrot Egg Roll for a Stage (guarantees uncollected Brainrots when completing Stage Eggs so players can never get soft-locked!)
function SlimeData.RollStageBrainrotId(stageLevel: number, hasLuckyRoll: boolean?, foundMap: { [any]: boolean }?): string
	local lvl = math.clamp(math.floor(stageLevel or 1), 1, 8)
	local stageBrainrots = {}
	local unfoundBrainrots = {}
	for idx = 1, 35 do
		local s = SlimeData.ById[idx]
		if s and s.Level == lvl then
			table.insert(stageBrainrots, s)
			local sId = tostring((s :: any).Id)
			local alreadyFound = foundMap and (foundMap[sId] or foundMap[tonumber(sId) :: any])
			if not alreadyFound then
				table.insert(unfoundBrainrots, s)
			end
		end
	end
	if #stageBrainrots == 0 then
		return "1"
	end

	local pool = if #unfoundBrainrots > 0 then unfoundBrainrots else stageBrainrots

	local rarityWeights = {
		Common = if hasLuckyRoll then 15 else 48,
		Rare = if hasLuckyRoll then 25 else 30,
		Epic = if hasLuckyRoll then 32 else 15,
		Legendary = if hasLuckyRoll then 20 else 6,
		Mythic = if hasLuckyRoll then 8 else 1,
	}

	local totalWeight = 0
	local weightedList = {}
	for _, b in ipairs(pool) do
		local w = rarityWeights[b.Rarity] or 20
		local sId = tostring((b :: any).Id)
		local alreadyFound = foundMap and (foundMap[sId] or foundMap[tonumber(sId) :: any])
		if not alreadyFound then
			w = math.floor(w * (if hasLuckyRoll then 3.5 else 1.8))
		end
		totalWeight += w
		table.insert(weightedList, { Id = sId, Weight = w })
	end

	local roll = math.random() * totalWeight
	local accum = 0
	for _, item in ipairs(weightedList) do
		accum += item.Weight
		if roll <= accum then
			return item.Id
		end
	end
	return weightedList[#weightedList].Id
end

return SlimeData
