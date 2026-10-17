--!strict
-- UpgradeData.luau
-- Definitions for Pen Expansions, Treadmill Tiers, Gel Multipliers, Jump Springs, Coloring Trails, and Paid Egg Guide.

local UpgradeData = {}

export type PenTierDef = {
	Tier: number,
	Name: string,
	MaxNests: number,
	Cost: number,
	Description: string,
}

export type TreadmillTierDef = {
	Tier: number,
	Name: string,
	SpeedPerTick: number,
	Cost: number,
	Color: Color3,
	Description: string,
}

export type GelTierDef = {
	Tier: number,
	Name: string,
	Multiplier: number,
	Cost: number,
	Color: Color3,
	Description: string,
}

export type JumpTierDef = {
	Tier: number,
	Name: string,
	JumpPower: number,
	Cost: number,
	Description: string,
}

export type TrailDef = {
	Id: string,
	Name: string,
	Cost: number,
	RobuxPassId: number, -- Set > 0 on create.roblox.com to prompt Robux Gamepass
	Color1: Color3,
	Color2: Color3,
	PaintFloor: boolean,
	Rainbow: boolean,
	SpeedBonus: number,
	CoinMultiplier: number,
	Description: string,
}

-- Pen Expansion Tiers: Players MUST grow their Pen to hold Eggs from higher levels!
UpgradeData.PenTiers = {
	{
		Tier = 1,
		Name = "Starter Meadow Pen",
		MaxNests = 5,
		Cost = 0,
		Description = "Holds 5 Eggs (Enough for Level 1: Meadow Gardens)",
	},
	{
		Tier = 2,
		Name = "Candy Sanctuary Pen",
		MaxNests = 11,
		Cost = 150,
		Description = "Expands Pen to 11 Nests (Required for Level 2 Candy Eggs!)",
	},
	{
		Tier = 3,
		Name = "Toybox Mega Pen",
		MaxNests = 18,
		Cost = 1200,
		Description = "Expands Pen to 18 Nests (Required for Level 3 Toybox Eggs!)",
	},
	{
		Tier = 4,
		Name = "Cyber Holo-Dome Pen",
		MaxNests = 26,
		Cost = 8500,
		Description = "Expands Pen to 26 Nests (Required for Level 4 Cyber Eggs!)",
	},
	{
		Tier = 5,
		Name = "Sovereign Palace Pen",
		MaxNests = 35,
		Cost = 45000,
		Description = "Expands Pen to all 35 Nests (Holds every Squishy in the game!)",
	},
}

-- Treadmill Tiers: Faster speed gain when running on your Base Treadmill
UpgradeData.TreadmillTiers = {
	{
		Tier = 1,
		Name = "Starter Jogger Belt",
		SpeedPerTick = 0.6,
		Cost = 0,
		Color = Color3.fromRGB(95, 220, 125),
		Description = "+0.6 WalkSpeed per stride on your Treadmill",
	},
	{
		Tier = 2,
		Name = "Turbo Neon Treadmill",
		SpeedPerTick = 1.6,
		Cost = 200,
		Color = Color3.fromRGB(65, 200, 255),
		Description = "+1.6 WalkSpeed per stride on your Treadmill",
	},
	{
		Tier = 3,
		Name = "Supersonic Cyber Belt",
		SpeedPerTick = 4.0,
		Cost = 1800,
		Color = Color3.fromRGB(215, 85, 255),
		Description = "+4.0 WalkSpeed per stride on your Treadmill",
	},
	{
		Tier = 4,
		Name = "Magma Hyper-Drive Belt",
		SpeedPerTick = 10.0,
		Cost = 15000,
		Color = Color3.fromRGB(255, 110, 45),
		Description = "+10.0 WalkSpeed per stride on your Treadmill",
	},
}

-- Gel Coating Tiers: Multiplies all Squishy income in your Pen
UpgradeData.GelTiers = {
	{
		Tier = 1,
		Name = "Classic Jelly Gloss",
		Multiplier = 1.0,
		Cost = 0,
		Color = Color3.fromRGB(140, 240, 170),
		Description = "1.0x Base Squishy Coin Income",
	},
	{
		Tier = 2,
		Name = "24K Golden Gel Coat",
		Multiplier = 2.0,
		Cost = 800,
		Color = Color3.fromRGB(255, 210, 60),
		Description = "2.0x Coin Income + Golden Shimmer on Pen Squishies!",
	},
	{
		Tier = 3,
		Name = "Rainbow Neon Gel Coat",
		Multiplier = 3.5,
		Cost = 9500,
		Color = Color3.fromRGB(255, 95, 225),
		Description = "3.5x Coin Income + Animated Rainbow Pen Squishies!",
	},
}

-- Jump Spring Tiers: Reach high shelves, crystal spires, and obbies
UpgradeData.JumpTiers = {
	{
		Tier = 1,
		Name = "Standard Sneakers",
		JumpPower = 52,
		Cost = 0,
		Description = "Standard Jump Height (52 Power)",
	},
	{
		Tier = 2,
		Name = "Slime Spring Boots",
		JumpPower = 72,
		Cost = 180,
		Description = "High Jump (72 Power) - Great for Gumball & Bookshelf!",
	},
	{
		Tier = 3,
		Name = "Rocket Jelly Thrusters",
		JumpPower = 94,
		Cost = 1500,
		Description = "Super Jump (94 Power) - Reach Cyber Hover Pads easily!",
	},
	{
		Tier = 4,
		Name = "Zero-G Sovereign Wings",
		JumpPower = 118,
		Cost = 12000,
		Description = "Mega Jump (118 Power) - Leap straight up the Volcano Spire!",
	},
}

-- Monetized & Collectible Coloring Trails
UpgradeData.Trails = {
	{
		Id = "GreenSlime",
		Name = "Slime Splat Trail",
		Cost = 100,
		RobuxPassId = 0,
		Color1 = Color3.fromRGB(90, 255, 120),
		Color2 = Color3.fromRGB(190, 255, 110),
		PaintFloor = true,
		Rainbow = false,
		SpeedBonus = 2,
		CoinMultiplier = 1.05,
		Description = "Leaves glowing green slime splats on the ground +2 Speed!",
	},
	{
		Id = "CyanLaser",
		Name = "Electric Cyan Paint Trail",
		Cost = 350,
		RobuxPassId = 0,
		Color1 = Color3.fromRGB(0, 240, 255),
		Color2 = Color3.fromRGB(80, 130, 255),
		PaintFloor = true,
		Rainbow = false,
		SpeedBonus = 4,
		CoinMultiplier = 1.10,
		Description = "Paints a neon cyan path behind you +4 Speed & +10% Coins!",
	},
	{
		Id = "CottonCandy",
		Name = "Cotton Candy Ribbon",
		Cost = 900,
		RobuxPassId = 0,
		Color1 = Color3.fromRGB(255, 120, 215),
		Color2 = Color3.fromRGB(120, 230, 255),
		PaintFloor = true,
		Rainbow = false,
		SpeedBonus = 6,
		CoinMultiplier = 1.20,
		Description = "Pastel pink & blue floor coloring trail +6 Speed & +20% Coins!",
	},
	{
		Id = "SolarGold",
		Name = "24K Gold VIP Trail",
		Cost = 2500,
		RobuxPassId = 0,
		Color1 = Color3.fromRGB(255, 215, 55),
		Color2 = Color3.fromRGB(255, 155, 25),
		PaintFloor = true,
		Rainbow = false,
		SpeedBonus = 10,
		CoinMultiplier = 1.35,
		Description = "Paints golden footsteps everywhere +10 Speed & +35% Coins!",
	},
	{
		Id = "MagmaFlame",
		Name = "Magma Blaze Trail",
		Cost = 7500,
		RobuxPassId = 0,
		Color1 = Color3.fromRGB(255, 75, 30),
		Color2 = Color3.fromRGB(255, 220, 60),
		PaintFloor = true,
		Rainbow = false,
		SpeedBonus = 15,
		CoinMultiplier = 1.50,
		Description = "Scorching lava paint trail +15 Speed & +50% Coins!",
	},
	{
		Id = "RainbowMaster",
		Name = "VIP Rainbow Painter Trail",
		Cost = 15000,
		RobuxPassId = 0, -- Plug in your Robux Gamepass ID here when publishing!
		Color1 = Color3.fromRGB(255, 70, 180),
		Color2 = Color3.fromRGB(70, 255, 240),
		PaintFloor = true,
		Rainbow = true,
		SpeedBonus = 22,
		CoinMultiplier = 2.0,
		Description = "Colors the floor in animated Rainbow Paint +22 Speed & 2x Coins!",
	},
}

-- Paid Egg Guide ("Direct Me to Egg") & VIP Passes
UpgradeData.GuidePricing = {
	SingleEggGuideCoinCost = 75, -- Cost in Coins to summon the 3D Guide Beam to a specific Egg
	VIPUnlimitedGuideCost = 1500, -- Unlock permanent unlimited Egg Guide Director
	GuideDevProductId = 0, -- Optional Robux Developer Product ID for single guide
	VIPGuidePassId = 0, -- Optional Robux Gamepass ID for Unlimited Egg Guide
	DoubleCoinsPassId = 0, -- Optional Robux Gamepass ID for 2x Coins
}

function UpgradeData.GetPenTier(tier: number): PenTierDef
	return UpgradeData.PenTiers[math.clamp(tier, 1, #UpgradeData.PenTiers)]
end

function UpgradeData.GetTreadmillTier(tier: number): TreadmillTierDef
	return UpgradeData.TreadmillTiers[math.clamp(tier, 1, #UpgradeData.TreadmillTiers)]
end

function UpgradeData.GetGelTier(tier: number): GelTierDef
	return UpgradeData.GelTiers[math.clamp(tier, 1, #UpgradeData.GelTiers)]
end

function UpgradeData.GetJumpTier(tier: number): JumpTierDef
	return UpgradeData.JumpTiers[math.clamp(tier, 1, #UpgradeData.JumpTiers)]
end

function UpgradeData.GetTrailById(trailId: string): TrailDef?
	for _, trail in ipairs(UpgradeData.Trails) do
		if trail.Id == trailId then
			return trail
		end
	end
	return nil
end

return UpgradeData
