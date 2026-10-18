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

SlimeData.TreadmillTiers = {
	[1] = {
		Tier = 1,
		Name = "Starter Treadmill",
		Badge = "x1 SPEED",
		MultiplierText = "x1 SPEED",
		MultiplierLabel = "x1 SPEED",
		SpeedPerSec = 25,
		RequiredSpeed = 0,
		Color = Color3.fromRGB(85, 225, 115),
		BeltColor = Color3.fromRGB(255, 65, 150),
		PrimaryColor = Color3.fromRGB(85, 225, 115),
		AccentColor = Color3.fromRGB(255, 235, 75),
		BeamTexture = "rbxassetid://6798365555",
		TextureSpeed = 2.4,
		ParticleTexture = "rbxassetid://9129151031",
		MeshId = "rbxassetid://9507455017",
		TextureId = "",
	},
	[2] = {
		Tier = 2,
		Name = "Candy Treadmill",
		Badge = "x3 SPEED",
		MultiplierText = "x3 SPEED",
		MultiplierLabel = "x3 SPEED",
		SpeedPerSec = 250,
		RequiredSpeed = 250,
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
		Badge = "x25 SPEED",
		MultiplierText = "x25 SPEED",
		MultiplierLabel = "x25 SPEED",
		SpeedPerSec = 2_500,
		RequiredSpeed = 2_500,
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
		Badge = "x250 SPEED",
		MultiplierText = "x250 SPEED",
		MultiplierLabel = "x250 SPEED",
		SpeedPerSec = 25_000,
		RequiredSpeed = 25_000,
		Color = Color3.fromRGB(65, 235, 145),
		BeltColor = Color3.fromRGB(45, 215, 130),
		PrimaryColor = Color3.fromRGB(65, 235, 145),
		AccentColor = Color3.fromRGB(185, 255, 115),
		BeamTexture = "rbxassetid://123374008022599",
		TextureSpeed = 3.6,
		ParticleTexture = "rbxassetid://7451822955",
		MeshId = "rbxassetid://9507455017",
		TextureId = "",
	},
	[5] = {
		Tier = 5,
		Name = "Diamond Treadmill",
		Badge = "x2.5k SPEED",
		MultiplierText = "x2.5k SPEED",
		MultiplierLabel = "x2.5k SPEED",
		SpeedPerSec = 250_000,
		RequiredSpeed = 250_000,
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
		Badge = "x25k SPEED",
		MultiplierText = "x25k SPEED",
		MultiplierLabel = "x25k SPEED",
		SpeedPerSec = 2_500_000,
		RequiredSpeed = 2_500_000,
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
		Badge = "x1M SPEED",
		MultiplierText = "x1M SPEED",
		MultiplierLabel = "x1M SPEED",
		SpeedPerSec = 25_000_000,
		RequiredSpeed = 25_000_000,
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
		Badge = "x50M SPEED",
		MultiplierText = "x50M SPEED",
		MultiplierLabel = "x50M SPEED",
		SpeedPerSec = 250_000_000,
		RequiredSpeed = 250_000_000,
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
		Subtitle = "Complete 100% of Stage 1 Squishies & Eggs + 250 Speed to Unlock Stage 2!",
		ZStart = 0,
		ZEnd = -160,
		GateZ = -160,
		ThemeColor = Color3.fromRGB(95, 215, 110),
		FloorColor = Color3.fromRGB(92, 198, 78),
		RequiredPlantedCount = 0,
		EggCount = 4,
	},
	{
		Level = 2,
		Name = "Chocolate Candy Kingdom",
		Subtitle = "Complete 100% of Stage 2 Squishies & Eggs + 2.5k Speed to Unlock Stage 3!",
		ZStart = -160,
		ZEnd = -320,
		GateZ = -320,
		ThemeColor = Color3.fromRGB(255, 115, 190),
		FloorColor = Color3.fromRGB(162, 108, 96),
		RequiredPlantedCount = 4,
		EggCount = 4,
	},
	{
		Level = 3,
		Name = "Tropical Beach Lagoon",
		Subtitle = "Complete 100% of Stage 3 Squishies & Eggs + 25k Speed to Unlock Stage 4!",
		ZStart = -320,
		ZEnd = -480,
		GateZ = -480,
		ThemeColor = Color3.fromRGB(255, 205, 75),
		FloorColor = Color3.fromRGB(238, 210, 145),
		RequiredPlantedCount = 8,
		EggCount = 4,
	},
	{
		Level = 4,
		Name = "Whispering Bamboo Forest",
		Subtitle = "Complete 100% of Stage 4 Squishies & Eggs + 250k Speed to Unlock Stage 5!",
		ZStart = -480,
		ZEnd = -640,
		GateZ = -640,
		ThemeColor = Color3.fromRGB(75, 225, 145),
		FloorColor = Color3.fromRGB(68, 158, 92),
		RequiredPlantedCount = 12,
		EggCount = 4,
	},
	{
		Level = 5,
		Name = "Crystal Cyber Cavern",
		Subtitle = "Complete 100% of Stage 5 Squishies & Eggs + 2.5M Speed to Unlock Stage 6!",
		ZStart = -640,
		ZEnd = -800,
		GateZ = -800,
		ThemeColor = Color3.fromRGB(65, 225, 255),
		FloorColor = Color3.fromRGB(72, 65, 118),
		RequiredPlantedCount = 16,
		EggCount = 4,
	},
	{
		Level = 6,
		Name = "Cloud Sky Sanctuary",
		Subtitle = "Complete 100% of Stage 6 Squishies & Eggs + 25M Speed to Unlock Stage 7!",
		ZStart = -800,
		ZEnd = -960,
		GateZ = -960,
		ThemeColor = Color3.fromRGB(135, 215, 255),
		FloorColor = Color3.fromRGB(215, 232, 250),
		RequiredPlantedCount = 20,
		EggCount = 5,
	},
	{
		Level = 7,
		Name = "Magma Volcano Doom",
		Subtitle = "Complete 100% of Stage 7 Squishies & Eggs + 250M Speed to Unlock Stage 8!",
		ZStart = -960,
		ZEnd = -1120,
		GateZ = -1120,
		ThemeColor = Color3.fromRGB(255, 95, 45),
		FloorColor = Color3.fromRGB(78, 42, 42),
		RequiredPlantedCount = 25,
		EggCount = 5,
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
		Name = "Cappuccino Assassino",
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
	[2] = 250,
	[3] = 2_500,
	[4] = 25_000,
	[5] = 250_000,
	[6] = 2_500_000,
	[7] = 25_000_000,
	[8] = 250_000_000,
}

for _, levelDef in ipairs(SlimeData.Levels) do
	local lvl = levelDef.Level
	local anyLvl = levelDef :: any
	anyLvl.Id = lvl
	anyLvl.SecondaryColor = levelDef.ThemeColor
	anyLvl.GateColor = levelDef.ThemeColor
	anyLvl.FloorMaterial = floorMaterials[lvl] or Enum.Material.SmoothPlastic
	anyLvl.RequiredSpeed = requiredSpeeds[lvl] or 0
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

-- Position the 35 Boss Nest Eggs (#1 to #35) across all 8 Stages (4, 4, 4, 4, 4, 5, 5, 5 per Stage) in Sector 3 (zStart - 116)
local levelEggIndices: { [number]: number } = {}
for idx, slime in ipairs(SlimeData.Slimes) do
	local anySlime = slime :: any
	anySlime.IsShiningSquishy = false
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
	local lvlDef = SlimeData.Levels[assignedLvl]
	levelEggIndices[assignedLvl] = (levelEggIndices[assignedLvl] or 0) + 1
	local idxInLvl = levelEggIndices[assignedLvl]
	local totalInLvl = if lvlDef then lvlDef.EggCount else 4
	local zCenter = if lvlDef then (lvlDef.ZStart - 116) else (-160 * (assignedLvl - 1) - 116)
	local frac = if totalInLvl > 1 then (idxInLvl - 1) / (totalInLvl - 1) else 0.5
	local xPos = -68 + frac * 136
	local zOffset = if idxInLvl % 2 == 0 then -14 else 14
	slime.Position = Vector3.new(xPos, 3.8, zCenter + zOffset)
	slime.CoinsPerSec = math.max(slime.CoinsPerSec, math.floor(10 * (2.6 ^ (assignedLvl - 1)) * idxInLvl))
	slime.Hint = string.format("Guarded by the Sleeping Boss in Stage %d (%s)! Walk over to Steal!", assignedLvl, if lvlDef then lvlDef.Name else ("Stage " .. assignedLvl))
end

-- ============================================================================
-- GENERATE 82 SHINING COLLECTIBLE SQUISHIES (#36 to #117) -> MAX = 117 TOTAL!
-- Distributed across all 8 Stages (Z < 0 — ZERO wild Squishies in the Safe Zone!)
-- on Biome House Rooftops, Giant Rainbow Staircase, Outer Side Mazes,
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

-- 1. BIOME HOUSE ROOFTOP SHINING SQUISHIES (16 Squishies: #36 to #51)
-- All 16 are inside Stages 1..8 (2 per Stage at X = ±114, Z = zStart - 56 & zStart - 94 — ZERO in Safe Zone!)
local rooftopPlacements = {
	-- Right-Side Biome Village Houses across Stages 1..8 (X = +114, Z = zStart - 94)
	{ Name = "Sunny Roof Mallow", Lvl = 1, Rarity = "Common", CPS = 18, Pos = Vector3.new(114, 22.5, -94), Hint = "Jump onto the Pink Meadow Cottage Roof on the right side of Stage 1!" },
	{ Name = "Sky Gables Kitty", Lvl = 2, Rarity = "Rare", CPS = 65, Pos = Vector3.new(114, 22.5, -254), Hint = "Bounce up the crates onto the Candy Villa Roof on the right side of Stage 2!" },
	{ Name = "Mint Chimney Puff", Lvl = 3, Rarity = "Rare", CPS = 190, Pos = Vector3.new(114, 22.5, -414), Hint = "Parkour onto the Coral Lagoon House Roof on the right side of Stage 3!" },
	{ Name = "Cobalt Shingle Pup", Lvl = 4, Rarity = "Epic", CPS = 520, Pos = Vector3.new(114, 22.5, -574), Hint = "Climb the crates onto the Jade Pavilion Roof on the right side of Stage 4!" },
	{ Name = "Ranch Gables Cow", Lvl = 5, Rarity = "Epic", CPS = 1_450, Pos = Vector3.new(114, 22.5, -734), Hint = "Perched atop the Violet Crystal Manor Roof on the right side of Stage 5!" },
	{ Name = "Blossom Attic Axolotl", Lvl = 6, Rarity = "Legendary", CPS = 4_200, Pos = Vector3.new(114, 22.5, -894), Hint = "Perched atop the Cloud Spire Villa Roof on the right side of Stage 6!" },
	{ Name = "Clover Ridge Frog", Lvl = 7, Rarity = "Legendary", CPS = 11_500, Pos = Vector3.new(114, 22.5, -1054), Hint = "Perched atop the Magma Bastion House Roof on the right side of Stage 7!" },
	{ Name = "Honeycomb Loft Bear", Lvl = 8, Rarity = "Mythic", CPS = 32_000, Pos = Vector3.new(114, 22.5, -1214), Hint = "Perched atop the Astral Void Sanctuary Roof on the right side of Stage 8!" },
	-- Left-Side & North Biome Village Parkour Houses across Stages 1..8 (X = ±114, Z = zStart - 56)
	{ Name = "Meadow Barn Loft", Lvl = 1, Rarity = "Rare", CPS = 45, Pos = Vector3.new(-114, 22.5, -56), Hint = "Jump onto the Red Meadow Barn Roof on the left of Stage 1!" },
	{ Name = "Gingerbread Roof Mallow", Lvl = 2, Rarity = "Epic", CPS = 120, Pos = Vector3.new(-114, 22.5, -216), Hint = "Bounce onto the Pink Candy Bakery Roof in Stage 2!" },
	{ Name = "Cabana Thatch Gecko", Lvl = 3, Rarity = "Epic", CPS = 380, Pos = Vector3.new(-114, 22.5, -376), Hint = "Jump onto the Coral Beach Cabana Roof in Stage 3!" },
	{ Name = "Bamboo Dojo Crane", Lvl = 4, Rarity = "Epic", CPS = 980, Pos = Vector3.new(114, 22.5, -536), Hint = "Jump onto the Jade Bamboo Dojo Roof in Stage 4!" },
	{ Name = "Crystal Observatory Owl", Lvl = 5, Rarity = "Legendary", CPS = 2_400, Pos = Vector3.new(-114, 22.5, -696), Hint = "Perched on the Amethyst Lodge Roof in Stage 5!" },
	{ Name = "Sky Sanctum Pegasus", Lvl = 6, Rarity = "Legendary", CPS = 6_200, Pos = Vector3.new(114, 22.5, -856), Hint = "Perched on the Cloud Temple Villa Roof in Stage 6!" },
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

-- 5. THEMED LEVEL OBBY OBSTACLE SHINING SQUISHIES (15 Squishies: #103 to #117)
-- Distributed across all 8 Stages perched on the Widened Left-Side Elevated Obby platforms (X = -83, -72)!
local obbyNames = {
	"Lilypad Hopper Squishy", "Log Beam Balancer",
	"Wafer Bridge Sprinter", "Peppermint Spinner Ace",
	"Surfboard Balance Puff", "Coral Archway Diver",
	"Bamboo Pole Vault Frog", "Jade Canopy Glider",
	"Laser Grid Dodger", "Floating Geode Hopper",
	"Cumulus Halo Jumper", "Thunder Ring Sprite",
	"Lava Geyser Leaper", "Obsidian Pendulum Pro",
	"Cosmic Singularity Grandmaster",
}
for i = 1, 15 do
	local lvl = math.clamp(math.ceil(i / 2), 1, 8)
	local subIdx = ((i - 1) % 2) + 1
	local zStart = SlimeData.Levels[lvl].ZStart
	local xPos = -94 + subIdx * 11 -- X = -83, -72 (matches widened ObbyGoalPlatform_1 and ObbyGoalPlatform_2)
	local yPos = 9.5 + subIdx * 2.8
	local zPos = zStart - 26 - subIdx * 22 -- Z = zStart - 48, -70
	local rarity = if lvl >= 7 then "Mythic" elseif lvl >= 5 then "Legendary" elseif lvl >= 3 then "Epic" else "Rare"
	local cps = math.floor(28 * (2.2 ^ (lvl - 1)) * subIdx)
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
	anySlime.UnlockOrder = numId

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

function SlimeData.IsLevelUnlocked(foundMap: { [any]: boolean }?, speedStat: number, targetLevel: number): boolean
	if targetLevel <= 1 then
		return true
	end
	-- Every previous level (1 .. targetLevel - 1) must have 100% of its Eggs & Squishies completed AND meet RequiredSpeed!
	for prev = 1, targetLevel - 1 do
		local foundInPrev, totalInPrev = SlimeData.GetLevelProgress(foundMap, prev)
		if totalInPrev > 0 and foundInPrev < totalInPrev then
			return false
		end
	end
	local lvlDef = SlimeData.Levels[targetLevel] :: any
	local reqSpd = if lvlDef then (lvlDef.RequiredSpeed or 16) else 16
	if (speedStat or 16) < reqSpd then
		return false
	end
	return true
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



