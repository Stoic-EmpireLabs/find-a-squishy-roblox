--!strict
-- UpgradeData.luau
-- Definitions for Pen Expansions, Million-Scale Treadmill Tiers, Gel Multipliers, Jump Springs, Coloring Trails, and Paid Egg Guide.

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
	SpeedPerTick: number, -- Scales from +150 up to +500,000 Speed Power per stride!
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
	RobuxPassId: number,
	Color1: Color3,
	Color2: Color3,
	PaintFloor: boolean,
	Rainbow: boolean,
	SpeedMultiplier: number,
	CoinMultiplier: number,
	Description: string,
}

-- Helper to format huge numbers cleanly (e.g. 1,500,000 -> "1.50M", 25,000 -> "25.0K")
function UpgradeData.FormatNumber(n: number): string
	if n >= 1_000_000_000 then
		return string.format("%.2fB", n / 1_000_000_000)
	elseif n >= 1_000_000 then
		return string.format("%.2fM", n / 1_000_000)
	elseif n >= 10_000 then
		return string.format("%.1fK", n / 1_000)
	elseif n >= 1_000 then
		return string.format("%.2fK", n / 1_000)
	else
		return tostring(math.floor(n))
	end
end

-- Converts a player's Million-Scale SpeedPower into a controllable Roblox WalkSpeed (18..82)
-- so players feel super fast without clipping off Obby platforms!
function UpgradeData.SpeedPowerToWalkSpeed(speedPower: number): number
	local logVal = math.log10(math.max(100, speedPower)) -- 2.0 (at 100) to 7.3 (at 20,000,000)
	local normalized = math.clamp((logVal - 2.0) / 5.3, 0, 1)
	return math.floor(18 + normalized * 58)
end

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
		Cost = 250,
		Description = "Expands Pen to 11 Nests (Required for Level 2 Candy Eggs!)",
	},
	{
		Tier = 3,
		Name = "Toybox Mega Pen",
		MaxNests = 18,
		Cost = 3500,
		Description = "Expands Pen to 18 Nests (Required for Level 3 Toybox Eggs!)",
	},
	{
		Tier = 4,
		Name = "Cyber Holo-Dome Pen",
		MaxNests = 26,
		Cost = 45000,
		Description = "Expands Pen to 26 Nests (Required for Level 4 Cyber Eggs!)",
	},
	{
		Tier = 5,
		Name = "Sovereign Palace Pen",
		MaxNests = 35,
		Cost = 500000,
		Description = "Expands Pen to all 35 Nests (Holds every Squishy in the game!)",
	},
}

-- 6 Million-Scale Treadmill Tiers: Train from 100 Speed all the way into the Millions!
UpgradeData.TreadmillTiers = {
	{
		Tier = 1,
		Name = "Starter Meadow Belt",
		SpeedPerTick = 150,
		Cost = 0,
		Color = Color3.fromRGB(95, 220, 125),
		Description = "+150 Speed Power per stride (Reach 1,500+ for Level 1 Chasers!)",
	},
	{
		Tier = 2,
		Name = "Candy Turbo Treadmill",
		SpeedPerTick = 1_500,
		Cost = 300,
		Color = Color3.fromRGB(255, 115, 205),
		Description = "+1.5K Speed Power per stride (Reach 15,000+ for Level 2 Chasers!)",
	},
	{
		Tier = 3,
		Name = "Toybox Nitro Treadmill",
		SpeedPerTick = 15_000,
		Cost = 4_000,
		Color = Color3.fromRGB(255, 195, 55),
		Description = "+15K Speed Power per stride (Reach 150,000+ for Level 3 Chasers!)",
	},
	{
		Tier = 4,
		Name = "Cyber Warp Treadmill",
		SpeedPerTick = 125_000,
		Cost = 50_000,
		Color = Color3.fromRGB(0, 235, 255),
		Description = "+125K Speed Power per stride (Reach 1.5M+ for Level 4 Chasers!)",
	},
	{
		Tier = 5,
		Name = "Magma Millionaire Belt",
		SpeedPerTick = 750_000,
		Cost = 400_000,
		Color = Color3.fromRGB(255, 95, 35),
		Description = "+750K Speed Power per stride (Reach 10M+ for Level 5 Chasers!)",
	},
	{
		Tier = 6,
		Name = "God-Speed Infinity Belt",
		SpeedPerTick = 3_500_000,
		Cost = 2_500_000,
		Color = Color3.fromRGB(215, 75, 255),
		Description = "+3.5M Speed Power per stride (Outrun EVERY Brainrot & Boss!)",
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
		Multiplier = 2.5,
		Cost = 1_500,
		Color = Color3.fromRGB(255, 210, 60),
		Description = "2.5x Coin Income + Golden Shimmer on Pen Squishies!",
	},
	{
		Tier = 3,
		Name = "Rainbow Neon Gel Coat",
		Multiplier = 5.0,
		Cost = 35_000,
		Color = Color3.fromRGB(255, 95, 225),
		Description = "5.0x Coin Income + Animated Rainbow Pen Squishies!",
	},
	{
		Tier = 4,
		Name = "Cosmic Galaxy Gel Coat",
		Multiplier = 12.0,
		Cost = 650_000,
		Color = Color3.fromRGB(115, 85, 255),
		Description = "12.0x Coin Income + Millionaire Pen Boost!",
	},
}

-- Jump Spring Tiers: Reach high obby platforms, crystal spires, and secret ledges
UpgradeData.JumpTiers = {
	{
		Tier = 1,
		Name = "Standard Sneakers",
		JumpPower = 54,
		Cost = 0,
		Description = "Standard Jump Height (54 Power)",
	},
	{
		Tier = 2,
		Name = "Slime Spring Boots",
		JumpPower = 72,
		Cost = 250,
		Description = "High Jump (72 Power) - Great for Candy & Toybox Obbies!",
	},
	{
		Tier = 3,
		Name = "Rocket Jelly Thrusters",
		JumpPower = 92,
		Cost = 3_500,
		Description = "Super Jump (92 Power) - Clear Cyber Laser Obbies easily!",
	},
	{
		Tier = 4,
		Name = "Zero-G Sovereign Wings",
		JumpPower = 115,
		Cost = 45_000,
		Description = "Mega Jump (115 Power) - Conquer the Volcano Summit Obby!",
	},
}

-- Monetized & Collectible Coloring Trails (Boosts both Treadmill Speed Multiplier & Coin Multiplier!)
UpgradeData.Trails = {
	{
		Id = "GreenSlime",
		Name = "Slime Splat Trail",
		Cost = 200,
		RobuxPassId = 0,
		Color1 = Color3.fromRGB(90, 255, 120),
		Color2 = Color3.fromRGB(190, 255, 110),
		PaintFloor = true,
		Rainbow = false,
		SpeedMultiplier = 1.25,
		CoinMultiplier = 1.15,
		Description = "Colors ground in green slime splats + 1.25x Treadmill Speed & 1.15x Coins!",
	},
	{
		Id = "CyanLaser",
		Name = "Electric Cyan Paint Trail",
		Cost = 1_200,
		RobuxPassId = 0,
		Color1 = Color3.fromRGB(0, 240, 255),
		Color2 = Color3.fromRGB(80, 130, 255),
		PaintFloor = true,
		Rainbow = false,
		SpeedMultiplier = 1.50,
		CoinMultiplier = 1.30,
		Description = "Paints a neon cyan path behind you + 1.5x Treadmill Speed & 1.3x Coins!",
	},
	{
		Id = "CottonCandy",
		Name = "Cotton Candy Ribbon",
		Cost = 6_500,
		RobuxPassId = 0,
		Color1 = Color3.fromRGB(255, 120, 215),
		Color2 = Color3.fromRGB(120, 230, 255),
		PaintFloor = true,
		Rainbow = false,
		SpeedMultiplier = 2.0,
		CoinMultiplier = 1.60,
		Description = "Pastel pink & blue floor coloring trail + 2x Treadmill Speed & 1.6x Coins!",
	},
	{
		Id = "SolarGold",
		Name = "24K Gold VIP Trail",
		Cost = 35_000,
		RobuxPassId = 0,
		Color1 = Color3.fromRGB(255, 215, 55),
		Color2 = Color3.fromRGB(255, 155, 25),
		PaintFloor = true,
		Rainbow = false,
		SpeedMultiplier = 3.0,
		CoinMultiplier = 2.25,
		Description = "Paints 24K golden footsteps everywhere + 3x Treadmill Speed & 2.25x Coins!",
	},
	{
		Id = "MagmaFlame",
		Name = "Magma Blaze Trail",
		Cost = 180_000,
		RobuxPassId = 0,
		Color1 = Color3.fromRGB(255, 75, 30),
		Color2 = Color3.fromRGB(255, 220, 60),
		PaintFloor = true,
		Rainbow = false,
		SpeedMultiplier = 5.0,
		CoinMultiplier = 3.5,
		Description = "Scorching lava paint trail + 5x Treadmill Speed & 3.5x Coins!",
	},
	{
		Id = "RainbowMaster",
		Name = "VIP Rainbow Painter Trail",
		Cost = 750_000,
		RobuxPassId = 0, -- Plug in your Robux Gamepass ID here when publishing!
		Color1 = Color3.fromRGB(255, 70, 180),
		Color2 = Color3.fromRGB(70, 255, 240),
		PaintFloor = true,
		Rainbow = true,
		SpeedMultiplier = 10.0,
		CoinMultiplier = 5.0,
		Description = "Colors the floor in animated Rainbow Paint + 10x Treadmill Speed & 5x Coins!",
	},
}

-- Paid Egg Guide ("Direct Me to Egg") & VIP Passes
UpgradeData.GuidePricing = {
	SingleEggGuideCoinCost = 100, -- Cost in Coins to summon the 3D Guide Beam to a specific Egg
	VIPUnlimitedGuideCost = 5_000, -- Unlock permanent unlimited Egg Guide Director
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
