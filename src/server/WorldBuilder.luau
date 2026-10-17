--!strict
-- WorldBuilder.luau
-- Procedurally constructs the Hub Plaza, 6 Expandable Base Pens (with Treadmills & Nests),
-- 5 Themed Level Biomes, Level Forcefield Gates, Co-op Vaults, Micro-Vents, 35 Hidden Eggs, and 10 Guardians.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SlimeData = require(Shared:WaitForChild("SlimeData"))
local UpgradeData = require(Shared:WaitForChild("UpgradeData"))
local SquishyBuilder = require(Shared:WaitForChild("SquishyBuilder"))

local WorldBuilder = {}

export type PlotRecord = {
	PlotIndex: number,
	OwnerUserId: number?,
	Origin: Vector3,
	Folder: Folder,
	SignLabel: TextLabel,
	SubSignLabel: TextLabel,
	PlantPad: Part,
	CashPad: Part,
	CashLabel: TextLabel,
	ExpandPad: Part,
	ExpandLabel: TextLabel,
	TreadmillBelt: Part,
	TreadmillUpgradePad: Part,
	TreadmillLabel: TextLabel,
	GelUpgradePad: Part,
	GelLabel: TextLabel,
	ShieldPad: Part,
	ShieldLabel: TextLabel,
	ShieldDome: Part,
	Nests: { [number]: { Pedestal: Part, HatchedModel: Model? } },
}

local function createPart(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = if props.Anchored ~= nil then p.Anchored else true
	p.CanCollide = if props.CanCollide ~= nil then p.CanCollide else true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(200, 200, 200)
	p.Size = props.Size or Vector3.new(4, 1, 4)
	if props.Shape then
		p.Shape = props.Shape
	end
	if props.Transparency then
		p.Transparency = props.Transparency
	end
	if props.CFrame then
		p.CFrame = props.CFrame
	elseif props.Position then
		p.Position = props.Position
	end
	p.Name = props.Name or "Part"
	if props.Parent then
		p.Parent = props.Parent
	end
	return p
end

local function addPadBillboard(pad: BasePart, titleText: string, subText: string, titleColor: Color3?): (TextLabel, TextLabel)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 185, 0, 68)
	bb.StudsOffset = Vector3.new(0, 3.8, 0)
	bb.MaxDistance = 75
	bb.Parent = pad

	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1, 0, 0.55, 0)
	t1.BackgroundTransparency = 1
	t1.Font = Enum.Font.FredokaOne
	t1.TextScaled = true
	t1.TextColor3 = titleColor or Color3.fromRGB(255, 255, 255)
	t1.TextStrokeTransparency = 0.15
	t1.Text = titleText
	t1.Parent = bb

	local t2 = Instance.new("TextLabel")
	t2.Size = UDim2.new(1, 0, 0.45, 0)
	t2.Position = UDim2.new(0, 0, 0.55, 0)
	t2.BackgroundTransparency = 1
	t2.Font = Enum.Font.GothamBold
	t2.TextScaled = true
	t2.TextColor3 = Color3.fromRGB(255, 240, 130)
	t2.TextStrokeTransparency = 0.2
	t2.Text = subText
	t2.Parent = bb

	return t1, t2
end

local function buildPlot(plotIndex: number, centerPos: Vector3, isLeftSide: boolean, parentFolder: Folder): PlotRecord
	local folder = Instance.new("Folder")
	folder.Name = "BasePen_" .. tostring(plotIndex)
	folder.Parent = parentFolder

	local faceDir = if isLeftSide then 1 else -1 -- Points toward the central Hub walkway

	-- Base Turf Platform (52 x 44)
	createPart({
		Name = "PenFloor",
		Material = Enum.Material.Plastic,
		Color = Color3.fromRGB(70, 165, 95),
		Size = Vector3.new(54, 2, 46),
		Position = centerPos + Vector3.new(0, -1, 0),
		Parent = folder,
	})

	-- Neon Border Trim
	createPart({
		Name = "PenBorder",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(95, 245, 155),
		Size = Vector3.new(55, 1.4, 47),
		Position = centerPos + Vector3.new(0, -1.2, 0),
		CanCollide = false,
		Parent = folder,
	})

	-- Giant Signpost at front of Base Pen
	local signPost = createPart({
		Name = "OwnerSignBoard",
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(35, 42, 65),
		Size = Vector3.new(2, 9, 20),
		Position = centerPos + Vector3.new(faceDir * 24, 6.5, 0),
		Parent = folder,
	})
	local signGui = Instance.new("BillboardGui")
	signGui.Size = UDim2.new(0, 260, 0, 90)
	signGui.StudsOffset = Vector3.new(0, 4.5, 0)
	signGui.MaxDistance = 120
	signGui.Parent = signPost

	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.new(1, 0, 0.58, 0)
	signLabel.BackgroundTransparency = 1
	signLabel.Font = Enum.Font.FredokaOne
	signLabel.TextScaled = true
	signLabel.TextColor3 = Color3.fromRGB(115, 255, 165)
	signLabel.TextStrokeTransparency = 0.1
	signLabel.Text = string.format("🏡 PEN #%d (TOUCH TO CLAIM)", plotIndex)
	signLabel.Parent = signGui

	local subSignLabel = Instance.new("TextLabel")
	subSignLabel.Size = UDim2.new(1, 0, 0.42, 0)
	subSignLabel.Position = UDim2.new(0, 0, 0.58, 0)
	subSignLabel.BackgroundTransparency = 1
	subSignLabel.Font = Enum.Font.GothamBold
	subSignLabel.TextScaled = true
	subSignLabel.TextColor3 = Color3.fromRGB(255, 235, 120)
	subSignLabel.TextStrokeTransparency = 0.15
	subSignLabel.Text = "Pen Tier 1: 0 / 5 Eggs Planted"
	subSignLabel.Parent = signGui

	-- 1. EGG PLANTING PAD (Bring carried Eggs here to hatch them into your Pen!)
	local plantPad = createPart({
		Name = "PlantEggPad",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(110, 255, 120),
		Size = Vector3.new(1.2, 8.5, 8.5),
		CFrame = CFrame.new(centerPos + Vector3.new(faceDir * 19, 0.6, -13)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = folder,
	})
	addPadBillboard(plantPad, "🥚 PLANT EGG HERE!", "Step here while carrying an Egg!", Color3.fromRGB(120, 255, 130))

	-- 2. CASH COLLECTOR PAD
	local cashPad = createPart({
		Name = "CashCollectorPad",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 225, 55),
		Size = Vector3.new(1.2, 8.0, 8.0),
		CFrame = CFrame.new(centerPos + Vector3.new(faceDir * 19, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = folder,
	})
	local _, cashLabel = addPadBillboard(cashPad, "💰 COLLECT PEN CASH", "$0 Ready", Color3.fromRGB(255, 235, 75))

	-- 3. SPEED TREADMILL STATION (Stand/Run on the belt to gain permanent WalkSpeed!)
	local treadmillBelt = createPart({
		Name = "TreadmillBelt",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(75, 215, 255),
		Size = Vector3.new(12, 1.0, 6.5),
		Position = centerPos + Vector3.new(faceDir * 16, 0.5, 13),
		Parent = folder,
	})
	treadmillBelt:SetAttribute("IsTreadmill", true)
	treadmillBelt:SetAttribute("PlotIndex", plotIndex)
	-- Treadmill handrails & display console
	createPart({
		Name = "TreadmillConsole",
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(45, 50, 70),
		Size = Vector3.new(1.5, 5.5, 6.5),
		Position = treadmillBelt.Position + Vector3.new(faceDir * 5.5, 2.5, 0),
		Parent = folder,
	})
	addPadBillboard(treadmillBelt, "🏃 SPEED TREADMILL", "Stand here to train WalkSpeed!", Color3.fromRGB(85, 235, 255))

	-- 4. UPGRADE PADS ROW (Expand Pen, Upgrade Treadmill, Upgrade Gel, Base Laser Shield)
	local expandPad = createPart({
		Name = "ExpandPenPad",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 145, 55),
		Size = Vector3.new(5.5, 1.0, 5.5),
		Position = centerPos + Vector3.new(faceDir * 9, 0.5, -17),
		Parent = folder,
	})
	local _, expandLabel = addPadBillboard(expandPad, "📈 GROW PEN (+NESTS)", "Tier 2 (11 Nests): $150", Color3.fromRGB(255, 175, 75))

	local treadmillUpgradePad = createPart({
		Name = "UpgradeTreadmillPad",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(85, 195, 255),
		Size = Vector3.new(5.5, 1.0, 5.5),
		Position = centerPos + Vector3.new(faceDir * 9, 0.5, -6),
		Parent = folder,
	})
	local _, treadmillLabel = addPadBillboard(treadmillUpgradePad, "⚡ UPGRADE TREADMILL", "Tier 2 (+1.6 Spd): $200", Color3.fromRGB(95, 215, 255))

	local gelUpgradePad = createPart({
		Name = "UpgradeGelPad",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 115, 235),
		Size = Vector3.new(5.5, 1.0, 5.5),
		Position = centerPos + Vector3.new(faceDir * 9, 0.5, 5),
		Parent = folder,
	})
	local _, gelLabel = addPadBillboard(gelUpgradePad, "🌈 GOLDEN/RAINBOW GEL", "2x Golden Gel: $800", Color3.fromRGB(255, 140, 245))

	local shieldPad = createPart({
		Name = "ShieldPad",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(95, 155, 255),
		Size = Vector3.new(5.5, 1.0, 5.5),
		Position = centerPos + Vector3.new(faceDir * 9, 0.5, 16),
		Parent = folder,
	})
	local _, shieldLabel = addPadBillboard(shieldPad, "🛡️ LASER SHIELD", "Step to Lock Out Raiders (60s)", Color3.fromRGB(115, 185, 255))

	local shieldDome = createPart({
		Name = "ShieldDome",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(65, 185, 255),
		Size = Vector3.new(58, 32, 50),
		Position = centerPos + Vector3.new(0, 8, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = folder,
	})

	-- 5. 35 EGG NEST PEDESTALS (7 columns x 5 rows in the back sanctuary of the Pen)
	local nests: { [number]: { Pedestal: Part, HatchedModel: Model? } } = {}
	for slotIdx = 1, 35 do
		local row = math.floor((slotIdx - 1) / 7) -- 0..4 (corresponds to Level 1..5)
		local col = (slotIdx - 1) % 7 -- 0..6
		local offsetX = -faceDir * (2 + row * 4.8)
		local offsetZ = -18 + (col * 6.0)
		local pedPos = centerPos + Vector3.new(offsetX, 0.6, offsetZ)

		local pedestal = createPart({
			Name = "NestPedestal_" .. tostring(slotIdx),
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.SmoothPlastic,
			Color = if slotIdx <= 5 then Color3.fromRGB(245, 205, 95) else Color3.fromRGB(90, 95, 110),
			Size = Vector3.new(1.2, 4.2, 4.2),
			CFrame = CFrame.new(pedPos) * CFrame.Angles(0, 0, math.rad(90)),
			Transparency = if slotIdx <= 5 then 0 else 0.65,
			Parent = folder,
		})
		nests[slotIdx] = {
			Pedestal = pedestal,
			HatchedModel = nil,
		}
	end

	return {
		PlotIndex = plotIndex,
		OwnerUserId = nil,
		Origin = centerPos,
		Folder = folder,
		SignLabel = signLabel,
		SubSignLabel = subSignLabel,
		PlantPad = plantPad,
		CashPad = cashPad,
		CashLabel = cashLabel,
		ExpandPad = expandPad,
		ExpandLabel = expandLabel,
		TreadmillBelt = treadmillBelt,
		TreadmillUpgradePad = treadmillUpgradePad,
		TreadmillLabel = treadmillLabel,
		GelUpgradePad = gelUpgradePad,
		GelLabel = gelLabel,
		ShieldPad = shieldPad,
		ShieldLabel = shieldLabel,
		ShieldDome = shieldDome,
		Nests = nests,
	}
end

function WorldBuilder.BuildWorld()
	-- Clean up previous build if re-running
	for _, childName in ipairs({ "SquishyWorld", "WorldEggs", "LevelGates", "WorldGuardians" }) do
		local old = Workspace:FindFirstChild(childName)
		if old then
			old:Destroy()
		end
	end
	local defaultBaseplate = Workspace:FindFirstChild("Baseplate")
	if defaultBaseplate then
		defaultBaseplate:Destroy()
	end

	local worldFolder = Instance.new("Folder")
	worldFolder.Name = "SquishyWorld"
	worldFolder.Parent = Workspace

	local eggsFolder = Instance.new("Folder")
	eggsFolder.Name = "WorldEggs"
	eggsFolder.Parent = Workspace

	local gatesFolder = Instance.new("Folder")
	gatesFolder.Name = "LevelGates"
	gatesFolder.Parent = Workspace

	local guardiansFolder = Instance.new("Folder")
	guardiansFolder.Name = "WorldGuardians"
	guardiansFolder.Parent = Workspace

	-- =========================================================================
	-- 1. CENTRAL HUB PLAZA & SPAWN (Z: +130 to -40)
	-- =========================================================================
	createPart({
		Name = "HubFloor",
		Material = Enum.Material.Cobblestone,
		Color = Color3.fromRGB(165, 175, 195),
		Size = Vector3.new(190, 4, 175),
		Position = Vector3.new(0, -2, 45),
		Parent = worldFolder,
	})

	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "HubSpawn"
	spawnLoc.Anchored = true
	spawnLoc.Size = Vector3.new(16, 1, 16)
	spawnLoc.Position = Vector3.new(0, 0.5, 95)
	spawnLoc.Material = Enum.Material.Neon
	spawnLoc.Color = Color3.fromRGB(95, 235, 255)
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.Parent = worldFolder

	-- Public Mega Treadmill in the Hub Center
	local hubTreadmill = createPart({
		Name = "HubPublicTreadmill",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(0, 235, 255),
		Size = Vector3.new(18, 1.2, 10),
		Position = Vector3.new(0, 0.6, 68),
		Parent = worldFolder,
	})
	hubTreadmill:SetAttribute("IsTreadmill", true)
	addPadBillboard(
		hubTreadmill,
		"⚡ PUBLIC TURBO TREADMILL ⚡",
		"Run here to boost WalkSpeed & outrun Chasers!",
		Color3.fromRGB(95, 250, 255)
	)

	-- 6 Player Base Pens (3 Left at X = -58, 3 Right at X = +58)
	local plots: { [number]: PlotRecord } = {}
	local zPositions = { 92, 38, -14 }
	local idx = 1
	for _, zPos in ipairs(zPositions) do
		plots[idx] = buildPlot(idx, Vector3.new(-58, 0, zPos), true, worldFolder)
		idx += 1
		plots[idx] = buildPlot(idx, Vector3.new(58, 0, zPos), false, worldFolder)
		idx += 1
	end

	-- =========================================================================
	-- 2. FIVE LEVEL BIOMES, MICRO-VENTS, CO-OP VAULTS & LEVEL GATES
	-- =========================================================================
	local levelGates: { [number]: Part } = {}
	local coopDoors: { [number]: Part } = {}
	local coopPlates: { [number]: { PlateA: Part, PlateB: Part } } = {}

	for _, lvl in ipairs(SlimeData.Levels) do
		local biomeFolder = Instance.new("Folder")
		biomeFolder.Name = "Biome_Level_" .. tostring(lvl.Level)
		biomeFolder.Parent = worldFolder

		local lengthZ = math.abs(lvl.ZEnd - lvl.ZStart)
		local midZ = (lvl.ZStart + lvl.ZEnd) / 2

		-- Main Biome Floor (120 studs wide x 180 studs long)
		createPart({
			Name = "BiomeFloor",
			Material = if lvl.Level == 1
				then Enum.Material.Grass
				elseif lvl.Level == 3 then Enum.Material.WoodPlanks
				elseif lvl.Level == 4 then Enum.Material.DiamondPlate
				elseif lvl.Level == 5 then Enum.Material.Basalt
				else Enum.Material.SmoothPlastic,
			Color = lvl.FloorColor,
			Size = Vector3.new(120, 4, lengthZ),
			Position = Vector3.new(0, -2, midZ),
			Parent = biomeFolder,
		})

		-- Side Perimeter Walls
		createPart({
			Name = "LeftWall",
			Material = Enum.Material.SmoothPlastic,
			Color = lvl.ThemeColor,
			Transparency = 0.25,
			Size = Vector3.new(4, 26, lengthZ),
			Position = Vector3.new(-60, 11, midZ),
			Parent = biomeFolder,
		})
		createPart({
			Name = "RightWall",
			Material = Enum.Material.SmoothPlastic,
			Color = lvl.ThemeColor,
			Transparency = 0.25,
			Size = Vector3.new(4, 26, lengthZ),
			Position = Vector3.new(60, 11, midZ),
			Parent = biomeFolder,
		})

		-- Welcome Arch Banner at Level Entrance
		local arch = createPart({
			Name = "LevelArch",
			Material = Enum.Material.Neon,
			Color = lvl.ThemeColor,
			Size = Vector3.new(46, 4, 3),
			Position = Vector3.new(0, 18, lvl.ZStart - 4),
			CanCollide = false,
			Parent = biomeFolder,
		})
		addPadBillboard(
			arch,
			string.format("🌟 LEVEL %d: %s 🌟", lvl.Level, string.upper(lvl.Name)),
			lvl.Subtitle,
			lvl.ThemeColor
		)

		-- SAFE ZONE LINE at Entrance of each Level (Guardians stop chasing once you cross back over!)
		local safeStrip = createPart({
			Name = "SafeZoneStrip",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(95, 255, 130),
			Size = Vector3.new(116, 0.4, 4),
			Position = Vector3.new(0, 0.2, lvl.ZStart - 2),
			CanCollide = false,
			Parent = biomeFolder,
		})

		-- CO-OP BUDDY VAULT (On the Left side of each level around X = -48)
		local vaultZ = lvl.ZEnd + 45
		if lvl.Level == 1 then
			vaultZ = -168
		elseif lvl.Level == 2 then
			vaultZ = -355
		elseif lvl.Level == 3 then
			vaultZ = -545
		elseif lvl.Level == 4 then
			vaultZ = -730
		elseif lvl.Level == 5 then
			vaultZ = -920
		end

		-- Vault Enclosure Walls
		createPart({
			Name = "VaultBack",
			Color = Color3.fromRGB(45, 50, 65),
			Size = Vector3.new(16, 12, 2),
			Position = Vector3.new(-48, 6, vaultZ - 8),
			Parent = biomeFolder,
		})
		createPart({
			Name = "VaultFront",
			Color = Color3.fromRGB(45, 50, 65),
			Size = Vector3.new(16, 12, 2),
			Position = Vector3.new(-48, 6, vaultZ + 8),
			Parent = biomeFolder,
		})
		createPart({
			Name = "VaultRoof",
			Color = Color3.fromRGB(45, 50, 65),
			Size = Vector3.new(18, 2, 18),
			Position = Vector3.new(-48, 12.5, vaultZ),
			Parent = biomeFolder,
		})
		local vaultDoor = createPart({
			Name = "CoopVaultDoor_" .. tostring(lvl.Level),
			Material = Enum.Material.ForceField,
			Color = Color3.fromRGB(255, 75, 95),
			Size = Vector3.new(1.5, 11, 14),
			Position = Vector3.new(-40, 5.5, vaultZ),
			Parent = biomeFolder,
		})
		addPadBillboard(
			vaultDoor,
			"🔒 CO-OP BUDDY VAULT",
			"Stand on Plate A & B (or use Decoy Weight button!)",
			Color3.fromRGB(255, 110, 120)
		)
		coopDoors[lvl.Level] = vaultDoor

		local plateA = createPart({
			Name = "BuddyPlateA",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 185, 55),
			Size = Vector3.new(0.8, 5, 5),
			CFrame = CFrame.new(-32, 0.4, vaultZ - 5) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = biomeFolder,
		})
		local plateB = createPart({
			Name = "BuddyPlateB",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 185, 55),
			Size = Vector3.new(0.8, 5, 5),
			CFrame = CFrame.new(-32, 0.4, vaultZ + 5) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = biomeFolder,
		})
		coopPlates[lvl.Level] = { PlateA = plateA, PlateB = plateB }

		-- MICRO-VENT ENCLOSURE (On the Right side around X = +48 for Levels 2-5)
		local ventZ = if lvl.Level == 2
			then -345
			elseif lvl.Level == 3 then -518
			elseif lvl.Level == 4 then -695
			elseif lvl.Level == 5 then -882
			else nil
		if ventZ then
			-- Low ceiling chamber where only Tiny Squishy Morph (or crouch/small) fits easily, with a Tiny-Morph Gate!
			createPart({
				Name = "VentChamberRoof",
				Color = Color3.fromRGB(55, 65, 85),
				Size = Vector3.new(18, 2, 16),
				Position = Vector3.new(48, 10, ventZ),
				Parent = biomeFolder,
			})
			createPart({
				Name = "VentWallN",
				Color = Color3.fromRGB(55, 65, 85),
				Size = Vector3.new(18, 10, 2),
				Position = Vector3.new(48, 5, ventZ - 7),
				Parent = biomeFolder,
			})
			createPart({
				Name = "VentWallS",
				Color = Color3.fromRGB(55, 65, 85),
				Size = Vector3.new(18, 10, 2),
				Position = Vector3.new(48, 5, ventZ + 7),
				Parent = biomeFolder,
			})
			-- Upper blocker leaving a 3.6-stud crawl opening + Tiny Gate indicator
			local ventHeader = createPart({
				Name = "MicroVentHeader",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(165, 95, 255),
				Size = Vector3.new(2, 5.5, 12),
				Position = Vector3.new(40, 6.8, ventZ),
				Parent = biomeFolder,
			})
			addPadBillboard(
				ventHeader,
				"🐭 TINY SQUISHY VENT",
				"Open Slimeopedia -> Morph + Toggle Tiny Size!",
				Color3.fromRGB(205, 145, 255)
			)
		end

		-- Helper to build an Obby Stepping Course + Hiding Alcove leading up to any Egg position
		local function buildObbyToEgg(eggPos: Vector3, stepCount: number, stepColor: Color3, hasLaserHurdles: boolean, hasHidingCover: boolean)
			local startZ = eggPos.Z + (stepCount * 6.5)
			local startX = if eggPos.X > 0 then eggPos.X - 10 elseif eggPos.X < 0 then eggPos.X + 10 else 0
			for s = 1, stepCount do
				local alpha = s / stepCount
				local px = startX + (eggPos.X - startX) * alpha + ((s % 2 == 0) and 3.5 or -3.5)
				local py = math.max(1.8, (eggPos.Y - 2.0) * alpha)
				local pz = startZ - (s * 6.0)
				createPart({
					Name = "ObbyPad_" .. s,
					Material = Enum.Material.Neon,
					Color = stepColor,
					Size = Vector3.new(5.5, 1.2, 5.5),
					Position = Vector3.new(px, py, pz),
					Parent = biomeFolder,
				})
				if hasLaserHurdles and s % 2 == 1 then
					local laser = createPart({
						Name = "ObbyLaser_" .. s,
						Material = Enum.Material.Neon,
						Color = Color3.fromRGB(255, 45, 75),
						Size = Vector3.new(6.5, 0.7, 0.7),
						Position = Vector3.new(px, py + 2.0, pz),
						CanCollide = false,
						Parent = biomeFolder,
					})
					laser:SetAttribute("IsObbyHazard", true)
				end
			end
			-- Platform under the Egg
			if eggPos.Y > 5 then
				createPart({
					Name = "EggSummitPad",
					Material = Enum.Material.SmoothPlastic,
					Color = stepColor,
					Size = Vector3.new(9, 1.5, 9),
					Position = eggPos - Vector3.new(0, 2.6, 0),
					Parent = biomeFolder,
				})
			end
			-- Secret Hiding Screens / Bushes / Crates so the Egg is hidden from plain view until you climb/peek behind!
			if hasHidingCover then
				createPart({
					Name = "HidingScreenFront",
					Material = Enum.Material.SmoothPlastic,
					Color = lvl.ThemeColor,
					Size = Vector3.new(8.5, 7.5, 1.5),
					Position = eggPos + Vector3.new(0, 1.2, 4.2),
					Parent = biomeFolder,
				})
				createPart({
					Name = "HidingScreenSide",
					Material = Enum.Material.SmoothPlastic,
					Color = lvl.FloorColor,
					Size = Vector3.new(1.5, 7.5, 8.5),
					Position = eggPos + Vector3.new(if eggPos.X >= 0 then -4.2 else 4.2, 1.2, 0),
					Parent = biomeFolder,
				})
			end
		end

		-- Build Obby Obstacles & Hiding Spots for the Eggs in this Level!
		for _, slimeDef in ipairs(SlimeData.ByLevel[lvl.Level] or {}) do
			if not slimeDef.IsCoopVault and not slimeDef.IsMicroVent then
				local steps = if slimeDef.Position.Y > 10 then 5 elseif slimeDef.IsBoss then 4 else 3
				local useLasers = (lvl.Level >= 2)
				local useCover = (slimeDef.Behavior == "Static" or slimeDef.Behavior == "Disguised")
				buildObbyToEgg(slimeDef.Position, steps, slimeDef.SecondaryColor, useLasers, useCover)
			end
		end

		-- Biome-Specific Landmarks & Parkour Obstacles
		if lvl.Level == 1 then
			-- Meadow Trees, Hollow Hiding Hedges, Creek & Bridge
			createPart({
				Name = "OakTrunk",
				Material = Enum.Material.Wood,
				Color = Color3.fromRGB(125, 85, 55),
				Size = Vector3.new(5, 14, 5),
				Position = Vector3.new(-36, 7, -75),
				Parent = biomeFolder,
			})
			createPart({
				Name = "OakLeaves",
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(65, 185, 85),
				Size = Vector3.new(18, 14, 18),
				Position = Vector3.new(-36, 17, -75),
				Parent = biomeFolder,
			})
			-- Hollow Bush Maze on Right side hiding Egg #2
			for b = 1, 5 do
				createPart({
					Name = "HedgeBush_" .. b,
					Shape = Enum.PartType.Ball,
					Material = Enum.Material.Grass,
					Color = Color3.fromRGB(55, 160, 70),
					Size = Vector3.new(7, 6.5, 7),
					Position = Vector3.new(30 + (b % 3) * 6, 3, -95 - b * 4),
					Parent = biomeFolder,
				})
			end
			createPart({
				Name = "CreekWater",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(65, 185, 255),
				Transparency = 0.3,
				Size = Vector3.new(116, 0.5, 18),
				Position = Vector3.new(0, 0.1, -135),
				CanCollide = false,
				Parent = biomeFolder,
			})
			createPart({
				Name = "CreekBridge",
				Material = Enum.Material.WoodPlanks,
				Color = Color3.fromRGB(155, 105, 65),
				Size = Vector3.new(18, 2, 20),
				Position = Vector3.new(0, 2.5, -135),
				Parent = biomeFolder,
			})
		elseif lvl.Level == 2 then
			-- Candy Lollipops, Frosting Waterfall Cave & Gumball Obby Steps leading to Y=16 at Z=-382
			createPart({
				Name = "FrostingWaterfall",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(145, 235, 255),
				Transparency = 0.35,
				Size = Vector3.new(16, 18, 1.5),
				Position = Vector3.new(-36, 9, -248),
				CanCollide = false,
				Parent = biomeFolder,
			})
			for step = 1, 5 do
				createPart({
					Name = "CandyStep_" .. step,
					Shape = Enum.PartType.Cylinder,
					Material = Enum.Material.SmoothPlastic,
					Color = Color3.fromHSV((step * 0.2) % 1, 0.65, 1),
					Size = Vector3.new(2.5, 8.5, 8.5),
					CFrame = CFrame.new((step % 2 == 0 and 9 or -9), step * 2.8, -346 - step * 6.5)
						* CFrame.Angles(0, 0, math.rad(90)),
					Parent = biomeFolder,
				})
			end
			createPart({
				Name = "GumballSummit",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 130, 215),
				Size = Vector3.new(14, 2, 14),
				Position = Vector3.new(0, 12.5, -382),
				Parent = biomeFolder,
			})
		elseif lvl.Level == 3 then
			-- Giant Bouncy Bed Trampoline at (36, 4, -465), Balance Beam & Bookshelf Steps at (-32, Y, -505)
			local mattress = createPart({
				Name = "BouncyBedMattress",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(115, 205, 255),
				Size = Vector3.new(20, 4.5, 24),
				Position = Vector3.new(36, 2.25, -465),
				Parent = biomeFolder,
			})
			mattress:SetAttribute("IsTrampoline", true)
			addPadBillboard(mattress, "🛏️ BOUNCY MATTRESS!", "Jump here for Super Obby Bounce!", Color3.fromRGB(135, 225, 255))

			-- Giant Climbing Truss up the Bookshelf
			local truss = Instance.new("TrussPart")
			truss.Name = "BookshelfLadder"
			truss.Anchored = true
			truss.Color = Color3.fromRGB(255, 195, 65)
			truss.Size = Vector3.new(2, 16, 2)
			truss.Position = Vector3.new(-25, 8, -505)
			truss.Parent = biomeFolder

			for shelf = 1, 3 do
				createPart({
					Name = "BookshelfStep_" .. shelf,
					Material = Enum.Material.Wood,
					Color = Color3.fromRGB(185, 125, 75),
					Size = Vector3.new(12, 2, 10),
					Position = Vector3.new(-32, shelf * 4.0, -480 - shelf * 8),
					Parent = biomeFolder,
				})
			end
		elseif lvl.Level == 4 then
			-- Cyber Laser Obby Beams & Hover Pads leading up to (0, 14, -712)
			for padIdx = 1, 4 do
				createPart({
					Name = "CyberHoverPad_" .. padIdx,
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(0, 240, 255),
					Size = Vector3.new(9.5, 1.5, 9.5),
					Position = Vector3.new((padIdx % 2 == 0 and -10 or 10), padIdx * 3.5, -676 - padIdx * 8),
					Parent = biomeFolder,
				})
			end
			createPart({
				Name = "QuantumPlatform",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(215, 75, 255),
				Size = Vector3.new(14, 1.5, 14),
				Position = Vector3.new(0, 13.5, -712),
				Parent = biomeFolder,
			})
		elseif lvl.Level == 5 then
			-- Lava Rivers, Stepping Stones, Volcanic Crystal Spire & Summit Altar
			local lavaRiver = createPart({
				Name = "LavaRiverHazard",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 75, 20),
				Size = Vector3.new(116, 0.6, 26),
				Position = Vector3.new(0, 0.2, -855),
				CanCollide = false,
				Parent = biomeFolder,
			})
			lavaRiver:SetAttribute("IsObbyHazard", true)
			for stone = 1, 5 do
				createPart({
					Name = "ObsidianSteppingStone_" .. stone,
					Material = Enum.Material.Basalt,
					Color = Color3.fromRGB(45, 40, 50),
					Size = Vector3.new(7, 2.2, 7),
					Position = Vector3.new(-30 + stone * 10, 1.1, -843 - (stone % 2) * 10),
					Parent = biomeFolder,
				})
			end

			for spireIdx = 1, 4 do
				createPart({
					Name = "CrystalStep_" .. spireIdx,
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(195, 85, 255),
					Size = Vector3.new(9.5, 2, 9.5),
					Position = Vector3.new((spireIdx % 2 == 0 and 11 or -11), spireIdx * 3.8, -868 - spireIdx * 7.5),
					Parent = biomeFolder,
				})
			end
			createPart({
				Name = "SpireTop",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 95, 45),
				Size = Vector3.new(14, 2, 14),
				Position = Vector3.new(0, 15.5, -902),
				Parent = biomeFolder,
			})
			createPart({
				Name = "SovereignAltar",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 205, 55),
				Size = Vector3.new(22, 9, 22),
				Position = Vector3.new(0, 4.5, -948),
				Parent = biomeFolder,
			})
			-- Climbing Truss on Sovereign Altar so kids can climb or super-jump
			local altarTruss = Instance.new("TrussPart")
			altarTruss.Name = "AltarClimbTruss"
			altarTruss.Anchored = true
			altarTruss.Color = Color3.fromRGB(255, 215, 55)
			altarTruss.Size = Vector3.new(2, 10, 2)
			altarTruss.Position = Vector3.new(0, 5, -936)
			altarTruss.Parent = biomeFolder

			-- Back wall at Z = -960
			createPart({
				Name = "VolcanoBackWall",
				Material = Enum.Material.Basalt,
				Color = Color3.fromRGB(45, 25, 30),
				Size = Vector3.new(124, 32, 4),
				Position = Vector3.new(0, 14, -960),
				Parent = biomeFolder,
			})
		end

		-- LEVEL FORCEFIELD GATE at the end of Levels 1..4
		if lvl.GateZ then
			local nextLvl = SlimeData.Levels[lvl.Level + 1]
			local gate = createPart({
				Name = "LevelGate_" .. tostring(lvl.Level),
				Material = Enum.Material.ForceField,
				Color = Color3.fromRGB(255, 65, 85),
				Size = Vector3.new(118, 26, 2.5),
				Position = Vector3.new(0, 11, lvl.GateZ),
				Parent = gatesFolder,
			})
			gate:SetAttribute("GateLevel", lvl.Level)
			gate:SetAttribute("RequiredPlantedCount", nextLvl.RequiredPlantedCount)
			addPadBillboard(
				gate,
				string.format("🔒 GATE TO LEVEL %d: %s", nextLvl.Level, string.upper(nextLvl.Name)),
				string.format("Plant ALL %d Eggs from Levels 1-%d in your Pen to Unlock!", nextLvl.RequiredPlantedCount, lvl.Level),
				Color3.fromRGB(255, 110, 125)
			)
			levelGates[lvl.Level] = gate
		end
	end

	-- =========================================================================
	-- 3. SPAWN ALL 35 HIDDEN SQUISHY EGGS
	-- =========================================================================
	local worldEggs: { [number]: Model } = {}
	for _, slimeDef in ipairs(SlimeData.Slimes) do
		local eggModel = SquishyBuilder.CreateWorldEgg(slimeDef, true)
		eggModel.Parent = eggsFolder
		worldEggs[slimeDef.Id] = eggModel
	end

	-- =========================================================================
	-- 4. SPAWN ALL 10 ANIMAL & BRAINROT CHASER GUARDIANS
	-- =========================================================================
	local worldGuardians: { [string]: { Def: SlimeData.GuardianDef, Model: Model } } = {}
	for _, gDef in ipairs(SlimeData.Guardians) do
		local gModel = SquishyBuilder.CreateGuardianModel(gDef)
		gModel.Parent = guardiansFolder
		worldGuardians[gDef.Id] = {
			Def = gDef,
			Model = gModel,
		}
	end

	return {
		Plots = plots,
		WorldEggs = worldEggs,
		WorldGuardians = worldGuardians,
		LevelGates = levelGates,
		CoopDoors = coopDoors,
		CoopPlates = coopPlates,
	}
end

return WorldBuilder
