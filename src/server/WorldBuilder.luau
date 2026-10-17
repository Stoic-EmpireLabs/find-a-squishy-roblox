--!strict
-- WorldBuilder.luau
-- High-Detail 3D World Generator for "Find My Squishy!"
-- Builds AAA Lighting/Atmosphere, a Massive 340x280 Hub Plaza with Golden Fountain & VIP Showcase,
-- 6 Spacious Fenced Base Pens (76x58 studs each) with Clean SurfaceGui Signboards & 3D Treadmills,
-- and 5 Huge 240x260 Themed Level Biomes packed with 3D Landmarks, Obbies, Hidden Eggs & 10 Guardians!

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SlimeData = require(Shared:WaitForChild("SlimeData"))
local SquishyBuilder = require(Shared:WaitForChild("SquishyBuilder"))
local PrebuiltLoader = require(Shared:WaitForChild("PrebuiltLoader"))

local WorldBuilder = {}

local treeSeedCounter = 0
local fenceSeedCounter = 0

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
	p.Anchored = if props.Anchored ~= nil then props.Anchored else true
	p.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
	p.CastShadow = if props.CastShadow ~= nil then props.CastShadow else false
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
	if props.Reflectance then
		p.Reflectance = props.Reflectance
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

-- Creates a clean short-range proximity tooltip (MaxDistance = 26) so pads NEVER clutter the distant screen!
local function addPadSign(pad: BasePart, titleText: string, subText: string, titleColor: Color3?, maxDist: number?): (TextLabel, TextLabel)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 175, 0, 56)
	bb.StudsOffset = Vector3.new(0, 3.4, 0)
	bb.MaxDistance = maxDist or 28
	bb.AlwaysOnTop = false
	bb.Parent = pad

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
	bg.BackgroundTransparency = 0.18
	bg.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bg
	local stroke = Instance.new("UIStroke")
	stroke.Color = titleColor or Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 2
	stroke.Parent = bg

	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1, -8, 0.54, 0)
	t1.Position = UDim2.new(0, 4, 0, 2)
	t1.BackgroundTransparency = 1
	t1.Font = Enum.Font.FredokaOne
	t1.TextScaled = true
	t1.TextColor3 = titleColor or Color3.fromRGB(255, 255, 255)
	t1.TextStrokeTransparency = 0.2
	t1.Text = titleText
	t1.Parent = bg

	local t2 = Instance.new("TextLabel")
	t2.Size = UDim2.new(1, -8, 0.42, 0)
	t2.Position = UDim2.new(0, 4, 0.54, 0)
	t2.BackgroundTransparency = 1
	t2.Font = Enum.Font.GothamBold
	t2.TextScaled = true
	t2.TextColor3 = Color3.fromRGB(255, 240, 140)
	t2.TextStrokeTransparency = 0.3
	t2.Text = subText
	t2.Parent = bg

	return t1, t2
end

-- Creates a crisp 3D Physical Signboard with SurfaceGui on Front & Back faces
local function createSurfaceBanner(boardPart: BasePart, titleText: string, subText: string, accentColor: Color3): (TextLabel, TextLabel)
	local mainTitle: TextLabel = nil :: any
	local mainSub: TextLabel = nil :: any

	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 24
		sg.MaxDistance = 160
		sg.Parent = boardPart

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(22, 26, 44)
		frame.BorderSizePixel = 0
		frame.Parent = sg

		local t1 = Instance.new("TextLabel")
		t1.Name = "Title"
		t1.Size = UDim2.new(0.94, 0, 0.56, 0)
		t1.Position = UDim2.new(0.03, 0, 0.04, 0)
		t1.BackgroundTransparency = 1
		t1.Font = Enum.Font.FredokaOne
		t1.TextScaled = true
		t1.TextColor3 = accentColor
		t1.Text = titleText
		t1.Parent = frame

		local t2 = Instance.new("TextLabel")
		t2.Name = "Sub"
		t2.Size = UDim2.new(0.94, 0, 0.36, 0)
		t2.Position = UDim2.new(0.03, 0, 0.60, 0)
		t2.BackgroundTransparency = 1
		t2.Font = Enum.Font.GothamBold
		t2.TextScaled = true
		t2.TextColor3 = Color3.fromRGB(255, 240, 150)
		t2.Text = subText
		t2.Parent = frame

		if not mainTitle then
			mainTitle = t1
			mainSub = t2
		end
	end

	return mainTitle, mainSub
end

-- Spawns a pre-built 3D Low-Poly Tree from PrebuiltLoader (falling back to procedural only if needed)
local function buildTree(pos: Vector3, trunkColor: Color3, leafColor1: Color3, leafColor2: Color3, scale: number, parent: Instance)
	treeSeedCounter += 1
	local prebuiltTree = PrebuiltLoader.CloneNormalizedTemplate("Trees", treeSeedCounter, 18.0 * scale, true)
	if prebuiltTree then
		prebuiltTree.Name = "PrebuiltTree_" .. tostring(treeSeedCounter)
		prebuiltTree:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad((treeSeedCounter * 67) % 360), 0))
		prebuiltTree.Parent = parent
		return
	end

	local model = Instance.new("Model")
	model.Name = "ScenicTree"
	model.Parent = parent

	createPart({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Wood,
		Color = trunkColor,
		Size = Vector3.new(12 * scale, 3.2 * scale, 3.2 * scale),
		CFrame = CFrame.new(pos + Vector3.new(0, 6 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = model,
	})
	createPart({
		Name = "CanopyMain",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Grass,
		Color = leafColor1,
		Size = Vector3.new(15 * scale, 12 * scale, 15 * scale),
		Position = pos + Vector3.new(0, 14 * scale, 0),
		Parent = model,
	})
end

-- Configures vibrant Simulator Lighting, Skybox, Atmosphere, Bloom, and ColorCorrection
local function configureLighting()
	Lighting.Ambient = Color3.fromRGB(125, 135, 160)
	Lighting.OutdoorAmbient = Color3.fromRGB(145, 155, 180)
	Lighting.Brightness = 2.4
	Lighting.ClockTime = 14.2
	Lighting.GlobalShadows = false

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.SunAngularSize = 18
	sky.Parent = Lighting

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.24
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(190, 225, 255)
	atmo.Decay = Color3.fromRGB(145, 185, 240)
	atmo.Glare = 0.1
	atmo.Haze = 0.8
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 22
	bloom.Threshold = 1.8
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.03
	cc.Contrast = 0.12
	cc.Saturation = 0.18
	cc.Parent = Lighting
end

-- Spawns a pre-built 3D Treadmill + pre-built 3D Dinosaur on top of the interactive TreadmillBelt!
local function buildDinoJawHead(beltPart: BasePart, faceDir: number, scale: number, parent: Instance)
	local center = beltPart.Position
	local lookCF = CFrame.lookAt(center, center + Vector3.new(faceDir, 0, 0))

	local prebuiltTreadmill = PrebuiltLoader.CloneNormalizedTemplate("Treadmill", 1, 9.5 * scale, false)
	if prebuiltTreadmill then
		prebuiltTreadmill.Name = "PrebuiltTreadmill"
		prebuiltTreadmill:PivotTo(lookCF)
		prebuiltTreadmill.Parent = parent
	end

	local prebuiltDino = PrebuiltLoader.CloneNormalizedTemplate("Dinosaurs", 1, 11.5 * scale, false)
	if prebuiltDino then
		prebuiltDino.Name = "PrebuiltTreadmillDino"
		prebuiltDino:PivotTo(CFrame.lookAt(center - Vector3.new(faceDir * 6.5 * scale, 0.5, 0), center + Vector3.new(faceDir * 10, 0, 0)))
		prebuiltDino.Parent = parent
		return
	end
end

-- Spawns pre-built 3D Low-Poly Fence models along a perimeter line!
local function buildWoodenRanchFence(startPos: Vector3, endPos: Vector3, parent: Instance)
	local diff = endPos - startPos
	local dist = diff.Magnitude
	local numSegments = math.max(1, math.floor(dist / 12))

	local hasPrebuiltFence = #PrebuiltLoader.GetCategoryTemplates("Fences") > 0
	if hasPrebuiltFence then
		for i = 0, numSegments - 1 do
			fenceSeedCounter += 1
			local a0 = i / numSegments
			local a1 = (i + 1) / numSegments
			local segMid = startPos:Lerp(endPos, (a0 + a1) * 0.5)
			local fenceModel = PrebuiltLoader.CloneNormalizedTemplate("Fences", fenceSeedCounter, 5.2, true)
			if fenceModel then
				fenceModel.Name = "PrebuiltFence_" .. tostring(fenceSeedCounter)
				fenceModel:PivotTo(CFrame.lookAt(segMid, endPos) * CFrame.Angles(0, math.rad(90), 0))
				fenceModel.Parent = parent
			end
		end
		return
	end

	local mid = (startPos + endPos) * 0.5
	local woodBrown = Color3.fromRGB(138, 78, 36)
	for _, railY in ipairs({ 1.6, 3.2 }) do
		createPart({
			Name = "FenceRail",
			Material = Enum.Material.Wood,
			Color = woodBrown,
			Size = Vector3.new(0.55, 0.55, dist),
			CFrame = CFrame.lookAt(mid + Vector3.new(0, railY, 0), endPos + Vector3.new(0, railY, 0)),
			Parent = parent,
		})
	end
end

local function buildPlot(plotIndex: number, centerPos: Vector3, isLeftSide: boolean, parentFolder: Folder): PlotRecord
	local folder = Instance.new("Folder")
	folder.Name = "BasePen_" .. tostring(plotIndex)
	folder.Parent = parentFolder

	local faceDir = if isLeftSide then 1 else -1 -- Points toward the central Hub walkway

	-- Main Lush Lawn Floor (76 x 58) with ClickDetector so players can click with a Backpack Squishy Tool to place it!
	local penLawn = createPart({
		Name = "PenLawn",
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(118, 212, 58),
		Size = Vector3.new(76, 2.4, 58),
		Position = centerPos + Vector3.new(0, -1.2, 0),
		Parent = folder,
	})
	penLawn:SetAttribute("PlotIndex", plotIndex)
	local lawnClick = Instance.new("ClickDetector")
	lawnClick.Name = "PlaceSquishyClick"
	lawnClick.MaxActivationDistance = 65
	lawnClick.Parent = penLawn

	-- Clean Central Accent Walkway Stripe inside the Pen (Zero coplanar tile overdraw!)
	createPart({
		Name = "PenWalkwayStripe",
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(134, 224, 68),
		Size = Vector3.new(20, 0.1, 54),
		Position = centerPos + Vector3.new(faceDir * 22, 0.03, 0),
		CanCollide = false,
		Parent = folder,
	})

	-- Warm Wooden Ranch Fences enclosing Back, North, South, and Front Corners (leaving center gate open)
	local cNW = centerPos + Vector3.new(-faceDir * 37, 0, -28)
	local cSW = centerPos + Vector3.new(-faceDir * 37, 0, 28)
	local cNE = centerPos + Vector3.new(faceDir * 37, 0, -28)
	local cSE = centerPos + Vector3.new(faceDir * 37, 0, 28)
	local gateN = centerPos + Vector3.new(faceDir * 37, 0, -11)
	local gateS = centerPos + Vector3.new(faceDir * 37, 0, 11)

	buildWoodenRanchFence(cNW, cSW, folder)
	buildWoodenRanchFence(cNW, cNE, folder)
	buildWoodenRanchFence(cSW, cSE, folder)
	buildWoodenRanchFence(cNE, gateN, folder)
	buildWoodenRanchFence(gateS, cSE, folder)

	-- Grand Entrance Archway & Overhead Scoreboard Sign
	createPart({
		Name = "ArchPillarL",
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(115, 62, 28),
		Size = Vector3.new(2.4, 15, 2.4),
		Position = centerPos + Vector3.new(faceDir * 36, 7.5, -11),
		Parent = folder,
	})
	createPart({
		Name = "ArchPillarR",
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(115, 62, 28),
		Size = Vector3.new(2.4, 15, 2.4),
		Position = centerPos + Vector3.new(faceDir * 36, 7.5, 11),
		Parent = folder,
	})
	local signBoard = createPart({
		Name = "OwnerSignBoard",
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(25, 32, 52),
		Size = Vector3.new(2.2, 6.2, 25),
		Position = centerPos + Vector3.new(faceDir * 36, 15.2, 0),
		Parent = folder,
	})
	local signLabel, subSignLabel = createSurfaceBanner(
		signBoard,
		string.format("🏡 PEN #%d (READY)", plotIndex),
		"Pen Tier 1: 0 / 5 Squishies Placed",
		Color3.fromRGB(115, 255, 165)
	)

	-- 1. EGG PLANTING INCUBATOR PAD (Front-North of Pen)
	local plantPad = createPart({
		Name = "PlantEggPad",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(185, 95, 255),
		Size = Vector3.new(1.2, 9.5, 9.5),
		CFrame = CFrame.new(centerPos + Vector3.new(faceDir * 26, 0.6, -18)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = folder,
	})
	addPadSign(plantPad, "🥚 PLANT & HATCH EGG", "Starts Hatch Countdown -> Backpack!", Color3.fromRGB(215, 135, 255), 34)
	local penIncubator = PrebuiltLoader.CloneNormalizedTemplate("Incubator", plotIndex, 6.2, false)
	if penIncubator then
		penIncubator.Name = "PrebuiltPenIncubator"
		penIncubator:PivotTo(CFrame.new(centerPos + Vector3.new(faceDir * 26, 0.2, -23.5)))
		penIncubator.Parent = folder
	end

	-- 2. CASH COLLECTOR VAULT PAD (Front-Center of Pen)
	local cashPad = createPart({
		Name = "CashCollectorPad",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(85, 255, 120),
		Size = Vector3.new(1.2, 9.0, 9.0),
		CFrame = CFrame.new(centerPos + Vector3.new(faceDir * 26, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = folder,
	})
	local _, cashLabel = addPadSign(cashPad, "💰 COLLECT CASH", "$0 Ready", Color3.fromRGB(115, 255, 140), 34)
	local penChest = PrebuiltLoader.CloneNormalizedTemplate("Chest", plotIndex, 4.5, false)
	if penChest then
		penChest.Name = "PrebuiltCashChest"
		penChest:PivotTo(CFrame.new(centerPos + Vector3.new(faceDir * 26, 0.2, 5.5)))
		penChest.Parent = folder
	end

	-- 3. 3D DINO-JAW SPEED TREADMILL MACHINE (Front-South of Pen)
	local treadmillBelt = createPart({
		Name = "TreadmillBelt",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 105, 215),
		Size = Vector3.new(14.5, 1.2, 7.2),
		Position = centerPos + Vector3.new(faceDir * 24, 0.6, 18),
		Parent = folder,
	})
	treadmillBelt:SetAttribute("IsTreadmill", true)
	treadmillBelt:SetAttribute("PlotIndex", plotIndex)
	buildDinoJawHead(treadmillBelt, faceDir, 1.0, folder)
	addPadSign(treadmillBelt, "🦖 DINO SPEED TREADMILL", "Run on Belt for +Speed Power!", Color3.fromRGB(85, 245, 255), 34)

	-- 4. UPGRADE BUTTON PADS ROW (Spaced 12 studs apart)
	local expandPad = createPart({
		Name = "ExpandPenPad",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 145, 50),
		Size = Vector3.new(6.2, 1.0, 6.2),
		Position = centerPos + Vector3.new(faceDir * 13, 0.5, -20),
		Parent = folder,
	})
	local _, expandLabel = addPadSign(expandPad, "📈 GROW PEN (+SLOTS)", "Tier 2 (11 Slots): $250", Color3.fromRGB(255, 175, 75), 26)

	local treadmillUpgradePad = createPart({
		Name = "UpgradeTreadmillPad",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(75, 195, 255),
		Size = Vector3.new(6.2, 1.0, 6.2),
		Position = centerPos + Vector3.new(faceDir * 13, 0.5, -7),
		Parent = folder,
	})
	local _, treadmillLabel = addPadSign(treadmillUpgradePad, "⚡ UPGRADE DINO BELT", "Candy Belt (+1.5K Spd): $300", Color3.fromRGB(95, 215, 255), 26)

	local gelUpgradePad = createPart({
		Name = "UpgradeGelPad",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 110, 230),
		Size = Vector3.new(6.2, 1.0, 6.2),
		Position = centerPos + Vector3.new(faceDir * 13, 0.5, 6),
		Parent = folder,
	})
	local _, gelLabel = addPadSign(gelUpgradePad, "🌈 GOLDEN/RAINBOW GEL", "2.5x Golden Gel: $1.50K", Color3.fromRGB(255, 140, 245), 26)

	local shieldPad = createPart({
		Name = "ShieldPad",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(95, 155, 255),
		Size = Vector3.new(6.2, 1.0, 6.2),
		Position = centerPos + Vector3.new(faceDir * 13, 0.5, 19),
		Parent = folder,
	})
	local _, shieldLabel = addPadSign(shieldPad, "🛡️ LASER SHIELD", "Lock Out Raiders (60s)", Color3.fromRGB(115, 185, 255), 26)

	local shieldDome = createPart({
		Name = "ShieldDome",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(65, 185, 255),
		Size = Vector3.new(0.1, 0.1, 0.1),
		Position = centerPos + Vector3.new(0, -20, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = folder,
	})

	-- 5. 35 SQUISHY LAWN SLOTS (with pre-built 3D Bird Nests on starter slots!)
	local nests: { [number]: { Pedestal: Part, HatchedModel: Model? } } = {}
	for slotIdx = 1, 35 do
		local row = math.floor((slotIdx - 1) / 7) -- 0..4
		local col = (slotIdx - 1) % 7 -- 0..6
		local offsetX = -faceDir * (-2 + row * 6.8)
		local offsetZ = -21 + (col * 7.0)
		local pedPos = centerPos + Vector3.new(offsetX, 0.4, offsetZ)

		local pedestal = createPart({
			Name = "NestPedestal_" .. tostring(slotIdx),
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.SmoothPlastic,
			Color = if slotIdx <= 5 then Color3.fromRGB(165, 245, 110) else Color3.fromRGB(95, 135, 85),
			Size = Vector3.new(0.8, 4.8, 4.8),
			CFrame = CFrame.new(pedPos) * CFrame.Angles(0, 0, math.rad(90)),
			Transparency = if slotIdx <= 5 then 0.15 else 0.55,
			Parent = folder,
		})
		pedestal:SetAttribute("PlotIndex", plotIndex)
		pedestal:SetAttribute("SlotIdx", slotIdx)

		if slotIdx <= 6 then
			local slotNest = PrebuiltLoader.CloneNormalizedTemplate("BirdNest", slotIdx, 4.4, false)
			if slotNest then
				slotNest.Name = "PrebuiltSlotNest_" .. tostring(slotIdx)
				slotNest:PivotTo(CFrame.new(pedPos))
				slotNest.Parent = folder
			end
		end

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
	configureLighting()
	treeSeedCounter = 0
	fenceSeedCounter = 0

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
	-- 1. CENTRAL HUB RESORT PLAZA (With Pre-Built Fountain, Market Stalls, Treadmill & Trees!)
	-- =========================================================================
	createPart({
		Name = "HubOuterGrass",
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(112, 208, 52),
		Size = Vector3.new(340, 4, 280),
		Position = Vector3.new(0, -2.2, 80),
		Parent = worldFolder,
	})
	createPart({
		Name = "HubPromenadeLawn",
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(132, 226, 68),
		Size = Vector3.new(86, 0.15, 250),
		Position = Vector3.new(0, 0.02, 80),
		CanCollide = false,
		Parent = worldFolder,
	})

	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "HubSpawn"
	spawnLoc.Anchored = true
	spawnLoc.Size = Vector3.new(22, 1.2, 22)
	spawnLoc.Position = Vector3.new(0, 0.6, 175)
	spawnLoc.Material = Enum.Material.Neon
	spawnLoc.Color = Color3.fromRGB(85, 235, 255)
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.Parent = worldFolder

	-- 3 Giant Rarity Odds & Showcase Display Boards
	local showcaseSpecs = {
		{ Pos = Vector3.new(-32, 9, 198), Color = Color3.fromRGB(255, 210, 45), Title = "🌟 LEGENDARY EGGS", Sub = "Golden & Crowned • $600–$1,800/s" },
		{ Pos = Vector3.new(0, 10, 202), Color = Color3.fromRGB(55, 225, 255), Title = "💎 MYTHIC SQUISHIES", Sub = "50+ Sculpted Eggs • $2,500–$8,000/s" },
		{ Pos = Vector3.new(32, 9, 198), Color = Color3.fromRGB(255, 65, 95), Title = "👑 BOSS GUARDIANS", Sub = "Steal While Sleeping ('Zzz') • $12,000/s!" },
	}
	for _, spec in ipairs(showcaseSpecs) do
		local board = createPart({
			Name = "RarityShowcaseBoard",
			Material = Enum.Material.SmoothPlastic,
			Color = spec.Color,
			Size = Vector3.new(26, 16, 2.4),
			Position = spec.Pos,
			Parent = worldFolder,
		})
		createSurfaceBanner(board, spec.Title, spec.Sub, spec.Color)
	end

	-- Pre-Built 3D Fountain at Hub Center (0, 0, 130) + Golden Statue Crown!
	local prebuiltFountain = PrebuiltLoader.CloneNormalizedTemplate("Fountain", 1, 24.0, true)
	if prebuiltFountain then
		prebuiltFountain.Name = "PrebuiltHubFountain"
		prebuiltFountain:PivotTo(CFrame.new(0, 0, 130))
		prebuiltFountain.Parent = worldFolder
	else
		createPart({
			Name = "FountainBasin",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Marble,
			Color = Color3.fromRGB(245, 245, 252),
			Size = Vector3.new(3.5, 28, 28),
			CFrame = CFrame.new(0, 1.75, 130) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = worldFolder,
		})
	end
	local statueSquishy = SquishyBuilder.CreateHatchedSquishy(SlimeData.ById[35], Vector3.new(0, 16, 130), 2, 5)
	statueSquishy.Name = "GoldenFountainStatue"
	statueSquishy.Parent = worldFolder

	-- Pre-Built 3D Market Stalls flanking the Hub Plaza!
	for idxStall, stallSpec in ipairs({
		{ Pos = Vector3.new(-38, 0, 135), Look = Vector3.new(0, 0, 135) },
		{ Pos = Vector3.new(38, 0, 135), Look = Vector3.new(0, 0, 135) },
		{ Pos = Vector3.new(-38, 0, 35), Look = Vector3.new(0, 0, 35) },
		{ Pos = Vector3.new(38, 0, 35), Look = Vector3.new(0, 0, 35) },
	}) do
		local stall = PrebuiltLoader.CloneNormalizedTemplate("MarketStall", idxStall, 14.5, true)
		if stall then
			stall.Name = "PrebuiltMarketStall_" .. tostring(idxStall)
			stall:PivotTo(CFrame.lookAt(stallSpec.Pos, stallSpec.Look))
			stall.Parent = worldFolder
		end
	end

	-- Public Mega Dino-Jaw Treadmill in the Hub Center (0, 0.7, 85)
	local hubTreadmill = createPart({
		Name = "HubPublicTreadmill",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 95, 215),
		Size = Vector3.new(24, 1.4, 12),
		Position = Vector3.new(0, 0.7, 85),
		Parent = worldFolder,
	})
	hubTreadmill:SetAttribute("IsTreadmill", true)
	buildDinoJawHead(hubTreadmill, 1, 1.45, worldFolder)
	addPadSign(
		hubTreadmill,
		"🦖 MEGA DINO TREADMILL 🦖",
		"Run on Belt for +Speed Power!",
		Color3.fromRGB(95, 250, 255),
		48
	)

	-- Pre-Built Scenic Trees, Bushes & Rocks lining the Hub Resort
	for idxTree, treePos in ipairs({
		Vector3.new(-52, 0, 195),
		Vector3.new(52, 0, 195),
		Vector3.new(-52, 0, 115),
		Vector3.new(52, 0, 115),
		Vector3.new(-52, 0, 45),
		Vector3.new(52, 0, 45),
		Vector3.new(-52, 0, -35),
		Vector3.new(52, 0, -35),
	}) do
		buildTree(treePos, Color3.fromRGB(125, 85, 55), Color3.fromRGB(68, 192, 88), Color3.fromRGB(105, 225, 115), 1.15, worldFolder)
		local bush = PrebuiltLoader.CloneNormalizedTemplate("Bushes", idxTree, 4.5, false)
		if bush then
			bush.Name = "HubBush_" .. tostring(idxTree)
			bush:PivotTo(CFrame.new(treePos + Vector3.new(if treePos.X < 0 then 6 else -6, 0, 5)))
			bush.Parent = worldFolder
		end
	end

	-- 6 Spacious Player Base Pens (3 Left at X = -105, 3 Right at X = +105; Z = 155, 80, 5)
	local plots: { [number]: PlotRecord } = {}
	local zPositions = { 155, 80, 5 }
	local idx = 1
	for _, zPos in ipairs(zPositions) do
		plots[idx] = buildPlot(idx, Vector3.new(-105, 0, zPos), true, worldFolder)
		idx += 1
		plots[idx] = buildPlot(idx, Vector3.new(105, 0, zPos), false, worldFolder)
		idx += 1
	end

	-- =========================================================================
	-- 2. FIVE MASSIVE LEVEL BIOMES (240 wide x 260 long each) PACKED WITH
	--    PRE-BUILT OBSTACLE COURSES, OBBY KIT PIECES, BRIDGES & BIOME PROPS!
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

		-- Main Biome Floor (240 studs wide x 260 studs long)
		createPart({
			Name = "BiomeFloor",
			Material = if lvl.Level == 1
				then Enum.Material.SmoothPlastic
				elseif lvl.Level == 3 then Enum.Material.WoodPlanks
				elseif lvl.Level == 4 then Enum.Material.DiamondPlate
				elseif lvl.Level == 5 then Enum.Material.Basalt
				else Enum.Material.SmoothPlastic,
			Color = lvl.FloorColor,
			Size = Vector3.new(240, 4, lengthZ),
			Position = Vector3.new(0, -2, midZ),
			Parent = biomeFolder,
		})

		-- Clean Central Biome Walkway Stripe
		local tileAccent = lvl.FloorColor:Lerp(lvl.ThemeColor, 0.22)
		createPart({
			Name = "BiomeCenterPath",
			Material = Enum.Material.SmoothPlastic,
			Color = tileAccent,
			Size = Vector3.new(36, 0.14, lengthZ - 12),
			Position = Vector3.new(0, 0.04, midZ),
			CanCollide = false,
			Parent = biomeFolder,
		})

		-- Scenic Side Cliffs / Perimeter Walls
		for side = -1, 1, 2 do
			createPart({
				Name = if side == -1 then "LeftBoundaryWall" else "RightBoundaryWall",
				Material = if lvl.Level == 5 then Enum.Material.Basalt else Enum.Material.SmoothPlastic,
				Color = lvl.ThemeColor:Lerp(Color3.fromRGB(75, 45, 35), if lvl.Level == 2 then 0.55 else 0.15),
				Size = Vector3.new(6, 36, lengthZ),
				Position = Vector3.new(side * 120, 16, midZ),
				Parent = biomeFolder,
			})
		end

		-- Grand Level Entrance Archway & SurfaceGui Signboard
		createPart({
			Name = "ArchPillarL",
			Material = Enum.Material.SmoothPlastic,
			Color = lvl.ThemeColor,
			Size = Vector3.new(5, 28, 5),
			Position = Vector3.new(-32, 14, lvl.ZStart - 5),
			Parent = biomeFolder,
		})
		createPart({
			Name = "ArchPillarR",
			Material = Enum.Material.SmoothPlastic,
			Color = lvl.ThemeColor,
			Size = Vector3.new(5, 28, 5),
			Position = Vector3.new(32, 14, lvl.ZStart - 5),
			Parent = biomeFolder,
		})
		local archBoard = createPart({
			Name = "LevelArchSign",
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(24, 30, 48),
			Size = Vector3.new(70, 8, 3),
			Position = Vector3.new(0, 29, lvl.ZStart - 5),
			Parent = biomeFolder,
		})
		createSurfaceBanner(
			archBoard,
			string.format("🌟 LEVEL %d: %s 🌟", lvl.Level, string.upper(lvl.Name)),
			lvl.Subtitle,
			lvl.ThemeColor
		)

		-- SAFE ZONE LINE at Entrance of each Level
		createPart({
			Name = "SafeZoneStrip",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(95, 255, 130),
			Size = Vector3.new(234, 0.5, 5),
			Position = Vector3.new(0, 0.25, lvl.ZStart - 3),
			CanCollide = false,
			Parent = biomeFolder,
		})

		-- CO-OP BUDDY VAULT (On the Left side of each level at X = -88)
		local vaultZ = if lvl.Level == 1
			then -245
			elseif lvl.Level == 2 then -505
			elseif lvl.Level == 3 then -785
			elseif lvl.Level == 4 then -1055
			else -1325

		createPart({
			Name = "VaultBack",
			Color = Color3.fromRGB(45, 50, 68),
			Size = Vector3.new(22, 14, 2),
			Position = Vector3.new(-88, 7, vaultZ - 10),
			Parent = biomeFolder,
		})
		createPart({
			Name = "VaultFront",
			Color = Color3.fromRGB(45, 50, 68),
			Size = Vector3.new(22, 14, 2),
			Position = Vector3.new(-88, 7, vaultZ + 10),
			Parent = biomeFolder,
		})
		createPart({
			Name = "VaultRoof",
			Color = Color3.fromRGB(45, 50, 68),
			Size = Vector3.new(24, 2, 22),
			Position = Vector3.new(-88, 14.5, vaultZ),
			Parent = biomeFolder,
		})
		local vaultDoor = createPart({
			Name = "CoopVaultDoor_" .. tostring(lvl.Level),
			Material = Enum.Material.ForceField,
			Color = Color3.fromRGB(255, 75, 95),
			Size = Vector3.new(1.5, 13, 18),
			Position = Vector3.new(-77, 6.5, vaultZ),
			Parent = biomeFolder,
		})
		addPadSign(
			vaultDoor,
			"🔒 CO-OP BUDDY VAULT",
			"Stand on Plates A & B (or Drop Buddy Weight!)",
			Color3.fromRGB(255, 110, 120),
			36
		)
		coopDoors[lvl.Level] = vaultDoor

		local plateA = createPart({
			Name = "BuddyPlateA",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 185, 55),
			Size = Vector3.new(0.8, 6, 6),
			CFrame = CFrame.new(-66, 0.4, vaultZ - 6) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = biomeFolder,
		})
		local plateB = createPart({
			Name = "BuddyPlateB",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 185, 55),
			Size = Vector3.new(0.8, 6, 6),
			CFrame = CFrame.new(-66, 0.4, vaultZ + 6) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = biomeFolder,
		})
		coopPlates[lvl.Level] = { PlateA = plateA, PlateB = plateB }

		-- MICRO-VENT ENCLOSURE (On the Right side at X = +88 for Levels 2-5)
		local ventZ = if lvl.Level == 2
			then -485
			elseif lvl.Level == 3 then -745
			elseif lvl.Level == 4 then -1010
			elseif lvl.Level == 5 then -1275
			else nil
		if ventZ then
			createPart({
				Name = "VentChamberRoof",
				Color = Color3.fromRGB(55, 65, 88),
				Size = Vector3.new(22, 2, 18),
				Position = Vector3.new(88, 11, ventZ),
				Parent = biomeFolder,
			})
			createPart({
				Name = "VentWallN",
				Color = Color3.fromRGB(55, 65, 88),
				Size = Vector3.new(22, 11, 2),
				Position = Vector3.new(88, 5.5, ventZ - 8),
				Parent = biomeFolder,
			})
			createPart({
				Name = "VentWallS",
				Color = Color3.fromRGB(55, 65, 88),
				Size = Vector3.new(22, 11, 2),
				Position = Vector3.new(88, 5.5, ventZ + 8),
				Parent = biomeFolder,
			})
			local ventHeader = createPart({
				Name = "MicroVentHeader",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(165, 95, 255),
				Size = Vector3.new(2.2, 6.2, 14),
				Position = Vector3.new(77, 7.2, ventZ),
				Parent = biomeFolder,
			})
			addPadSign(
				ventHeader,
				"🐭 TINY SQUISHY VENT",
				"Slimeopedia -> Toggle Tiny Size!",
				Color3.fromRGB(205, 145, 255),
				36
			)
		end

		-- =====================================================================
		-- DENSE PRE-BUILT OBSTACLE COURSE & PARKOUR GAUNTLET IN EVERY SECTION!
		-- =====================================================================
		local propCat = if lvl.Level == 1
			then "Trees"
			elseif lvl.Level == 2 then "Candy"
			elseif lvl.Level == 3 then "Crystals"
			elseif lvl.Level == 4 then "Coral"
			else "VolcanoRocks"

		local secondaryPropCat = if lvl.Level == 1
			then "Rocks"
			elseif lvl.Level == 2 then "Bushes"
			elseif lvl.Level == 3 then "Obstacles"
			elseif lvl.Level == 4 then "PalmTrees"
			else "Crystals"

		-- 1. Front & Mid Hazard Moats crossed by Pre-Built 3D Low-Poly Bridges!
		for moatIdx, moatZ in ipairs({ lvl.ZStart - 52, lvl.ZStart - 168 }) do
			local moatHazard = createPart({
				Name = "BiomeHazardMoat_" .. tostring(moatIdx),
				Material = Enum.Material.Neon,
				Color = if lvl.Level == 5
					then Color3.fromRGB(255, 75, 20)
					elseif lvl.Level == 2 then Color3.fromRGB(255, 85, 195)
					elseif lvl.Level == 4 then Color3.fromRGB(0, 235, 255)
					else Color3.fromRGB(115, 245, 75),
				Transparency = 0.2,
				Size = Vector3.new(228, 0.7, 18),
				Position = Vector3.new(0, 0.25, moatZ),
				CanCollide = false,
				Parent = biomeFolder,
			})
			if lvl.Level >= 2 then
				moatHazard:SetAttribute("IsObbyHazard", true)
			end

			-- 2 Pre-built 3D Bridges + Center Stepping Stones across each Moat!
			for bIdx, bx in ipairs({ -44, 44 }) do
				local bridgeDeck = createPart({
					Name = "BridgeCollider_" .. tostring(moatIdx) .. "_" .. tostring(bIdx),
					Material = Enum.Material.WoodPlanks,
					Color = Color3.fromRGB(155, 102, 58),
					Size = Vector3.new(14, 1.2, 24),
					Position = Vector3.new(bx, 1.6, moatZ),
					Transparency = 0.85,
					Parent = biomeFolder,
				})
				local prebuiltBridge = PrebuiltLoader.CloneNormalizedTemplate("Bridges", lvl.Level + bIdx, 24.0, true)
				if prebuiltBridge then
					prebuiltBridge.Name = "PrebuiltBridge_" .. tostring(moatIdx) .. "_" .. tostring(bIdx)
					prebuiltBridge:PivotTo(CFrame.new(bx, 0.2, moatZ))
					prebuiltBridge.Parent = biomeFolder
				else
					bridgeDeck.Transparency = 0
				end
			end

			-- Center Stepping Stones over the Moat
			for st = -1, 1 do
				createPart({
					Name = "MoatSteppingStone_" .. tostring(st),
					Shape = Enum.PartType.Cylinder,
					Material = Enum.Material.SmoothPlastic,
					Color = lvl.ThemeColor,
					Size = Vector3.new(1.8, 7.5, 7.5),
					CFrame = CFrame.new(st * 11, 0.9, moatZ + (st % 2) * 3) * CFrame.Angles(0, 0, math.rad(90)),
					Parent = biomeFolder,
				})
			end
		end

		-- 2. Three Rows of Pre-Built Obby Kit Obstacles & Barricades across every section!
		local obstacleRowsZ = {
			lvl.ZStart - 30,
			lvl.ZStart - 88,
			lvl.ZStart - 140,
			lvl.ZStart - 208,
		}
		local obstacleLanesX = { -75, -36, 0, 36, 75 }

		for rIdx, rz in ipairs(obstacleRowsZ) do
			for cIdx, cx in ipairs(obstacleLanesX) do
				-- Alternate lanes so players weave through a real obstacle course!
				if (rIdx + cIdx) % 2 == 0 then
					local seed = (lvl.Level * 13) + (rIdx * 5) + cIdx
					local obbyModel = PrebuiltLoader.CloneNormalizedTemplate("Obstacles", seed, 12.5, true)
					if obbyModel then
						obbyModel.Name = string.format("PrebuiltObstacle_R%d_C%d", rIdx, cIdx)
						obbyModel:PivotTo(CFrame.new(cx, 0.1, rz) * CFrame.Angles(0, math.rad(((rIdx + cIdx) % 4) * 90), 0))
						obbyModel.Parent = biomeFolder
					end

					-- Add a glowing Laser Jump Hurdle in front of every obstacle!
					local hurdle = createPart({
						Name = string.format("LaserHurdle_R%d_C%d", rIdx, cIdx),
						Material = Enum.Material.Neon,
						Color = Color3.fromRGB(255, 45, 75),
						Size = Vector3.new(16, 1.1, 1.1),
						Position = Vector3.new(cx, 2.2, rz + 7),
						CanCollide = false,
						Parent = biomeFolder,
					})
					hurdle:SetAttribute("IsObbyHazard", true)
				else
					-- Spawn a Pre-Built Biome Prop Obstacle (Tree, Candy, Crystal, Coral, VolcanoRock, Fence, Rock)
					local seed = (lvl.Level * 17) + (rIdx * 7) + cIdx
					local usePrimary = (cIdx % 2 == 1)
					local chosenCat = if usePrimary then propCat else secondaryPropCat
					local propScale = if chosenCat == "Trees" or chosenCat == "PalmTrees" then 17.5 else 10.5
					local propModel = PrebuiltLoader.CloneNormalizedTemplate(chosenCat, seed, propScale, true)
					if propModel then
						propModel.Name = string.format("PrebuiltBiomeProp_R%d_C%d", rIdx, cIdx)
						propModel:PivotTo(CFrame.new(cx, 0.1, rz) * CFrame.Angles(0, math.rad((seed * 45) % 360), 0))
						propModel.Parent = biomeFolder
					end

					-- Also add a pre-built Fence barricade wing beside the prop!
					local fenceWing = PrebuiltLoader.CloneNormalizedTemplate("Fences", seed, 6.5, true)
					if fenceWing then
						fenceWing.Name = string.format("ObstacleFence_R%d_C%d", rIdx, cIdx)
						fenceWing:PivotTo(CFrame.new(cx + (if cx >= 0 then -8 else 8), 0.1, rz + 4))
						fenceWing.Parent = biomeFolder
					end
				end
			end
		end

		-- 3. Four Interactive Super Bounce / Trampoline Pads in EVERY Biome Section!
		for bIdx, bPos in ipairs({
			Vector3.new(-52, 0.8, lvl.ZStart - 68),
			Vector3.new(52, 0.8, lvl.ZStart - 68),
			Vector3.new(-52, 0.8, lvl.ZStart - 182),
			Vector3.new(52, 0.8, lvl.ZStart - 182),
		}) do
			local bouncePad = createPart({
				Name = "BiomeBouncePad_" .. tostring(bIdx),
				Shape = Enum.PartType.Cylinder,
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(65, 235, 255),
				Size = Vector3.new(1.6, 10.5, 10.5),
				CFrame = CFrame.new(bPos) * CFrame.Angles(0, 0, math.rad(90)),
				Parent = biomeFolder,
			})
			bouncePad:SetAttribute("IsTrampoline", true)
			addPadSign(bouncePad, "🚀 SUPER BOUNCE PAD", "Jump to Launch Over Obstacles!", Color3.fromRGB(95, 245, 255), 32)
		end

		-- 4. Obby Stepping Course + Pre-Built Obstacles leading up to each Egg position!
		local function buildObbyToEgg(eggPos: Vector3, stepCount: number, stepColor: Color3, hasLaserHurdles: boolean, hasHidingCover: boolean, eggId: number)
			local startZ = eggPos.Z + (stepCount * 8.0)
			local startX = if eggPos.X > 0 then eggPos.X - 16 elseif eggPos.X < 0 then eggPos.X + 16 else 0
			for s = 1, stepCount do
				local alpha = s / stepCount
				local px = startX + (eggPos.X - startX) * alpha + ((s % 2 == 0) and 5.0 or -5.0)
				local py = math.max(2.2, (eggPos.Y - 2.0) * alpha)
				local pz = startZ - (s * 7.5)
				createPart({
					Name = "ObbyPad_" .. s,
					Material = Enum.Material.Neon,
					Color = stepColor,
					Size = Vector3.new(7.5, 1.5, 7.5),
					Position = Vector3.new(px, py, pz),
					Parent = biomeFolder,
				})
				if hasLaserHurdles and s % 2 == 1 then
					local laser = createPart({
						Name = "ObbyLaser_" .. s,
						Material = Enum.Material.Neon,
						Color = Color3.fromRGB(255, 45, 75),
						Size = Vector3.new(8.5, 0.8, 0.8),
						Position = Vector3.new(px, py + 2.2, pz),
						CanCollide = false,
						Parent = biomeFolder,
					})
					laser:SetAttribute("IsObbyHazard", true)
				end
			end
			if eggPos.Y > 6 then
				createPart({
					Name = "EggSummitPad",
					Material = Enum.Material.SmoothPlastic,
					Color = stepColor,
					Size = Vector3.new(13, 2.0, 13),
					Position = eggPos - Vector3.new(0, 2.8, 0),
					Parent = biomeFolder,
				})
				local truss = Instance.new("TrussPart")
				truss.Name = "SummitClimbTruss"
				truss.Anchored = true
				truss.Color = stepColor
				truss.Size = Vector3.new(2, math.max(6, eggPos.Y - 2), 2)
				truss.Position = Vector3.new(eggPos.X, (eggPos.Y - 2) / 2, eggPos.Z + 6.5)
				truss.Parent = biomeFolder
			end
			if hasHidingCover then
				-- Spawn Pre-Built Rocks & Fences as Hiding Cover around the Egg!
				local coverRock = PrebuiltLoader.CloneNormalizedTemplate(propCat, eggId, 9.5, true)
				if coverRock then
					coverRock.Name = "EggGuardProp_" .. tostring(eggId)
					coverRock:PivotTo(CFrame.new(eggPos + Vector3.new(0, -1.8, 6.5)))
					coverRock.Parent = biomeFolder
				end
				local coverFence = PrebuiltLoader.CloneNormalizedTemplate("Fences", eggId, 6.2, true)
				if coverFence then
					coverFence.Name = "EggGuardFence_" .. tostring(eggId)
					coverFence:PivotTo(CFrame.new(eggPos + Vector3.new(if eggPos.X >= 0 then -6.5 else 6.5, -1.8, 0)))
					coverFence.Parent = biomeFolder
				end
			end
		end

		for _, slimeDef in ipairs(SlimeData.ByLevel[lvl.Level] or {}) do
			if not slimeDef.IsCoopVault and not slimeDef.IsMicroVent then
				local steps = if slimeDef.Position.Y > 20 then 6 elseif slimeDef.Position.Y > 10 then 4 else 3
				local useLasers = (lvl.Level >= 1)
				local useCover = (slimeDef.Behavior == "Static" or slimeDef.Behavior == "Disguised")
				buildObbyToEgg(slimeDef.Position, steps, slimeDef.SecondaryColor, useLasers, useCover, slimeDef.Id)
			end
		end

		-- LEVEL FORCEFIELD GATE at the end of Levels 1..4
		if lvl.GateZ then
			local nextLvl = SlimeData.Levels[lvl.Level + 1]
			local gate = createPart({
				Name = "LevelGate_" .. tostring(lvl.Level),
				Material = Enum.Material.ForceField,
				Color = Color3.fromRGB(255, 65, 85),
				Size = Vector3.new(234, 32, 3),
				Position = Vector3.new(0, 14, lvl.GateZ),
				Parent = gatesFolder,
			})
			gate:SetAttribute("GateLevel", lvl.Level)
			gate:SetAttribute("RequiredPlantedCount", nextLvl.RequiredPlantedCount)
			addPadSign(
				gate,
				string.format("🔒 GATE TO LEVEL %d: %s", nextLvl.Level, string.upper(nextLvl.Name)),
				string.format("Plant ALL %d Eggs from Levels 1-%d in your Pen to Unlock!", nextLvl.RequiredPlantedCount, lvl.Level),
				Color3.fromRGB(255, 110, 125),
				65
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
