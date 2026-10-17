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
	p.Anchored = if props.Anchored ~= nil then props.Anchored else true
	p.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
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

-- Creates a crisp 3D Physical Signboard with SurfaceGui on both faces (Zero floating text clutter!)
local function createSurfaceBanner(boardPart: BasePart, titleText: string, subText: string, accentColor: Color3): (TextLabel, TextLabel)
	local mainTitle: TextLabel = nil :: any
	local mainSub: TextLabel = nil :: any

	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 35
		sg.Parent = boardPart

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(22, 26, 44)
		frame.BorderSizePixel = 0
		frame.Parent = sg

		local t1 = Instance.new("TextLabel")
		t1.Size = UDim2.new(0.94, 0, 0.56, 0)
		t1.Position = UDim2.new(0.03, 0, 0.04, 0)
		t1.BackgroundTransparency = 1
		t1.Font = Enum.Font.FredokaOne
		t1.TextScaled = true
		t1.TextColor3 = accentColor
		t1.Text = titleText
		t1.Parent = frame

		local t2 = Instance.new("TextLabel")
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

-- Helper to build a rich multi-canopy 3D Tree
local function buildTree(pos: Vector3, trunkColor: Color3, leafColor1: Color3, leafColor2: Color3, scale: number, parent: Instance)
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
	createPart({
		Name = "CanopyTop",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Grass,
		Color = leafColor2,
		Size = Vector3.new(10 * scale, 9 * scale, 10 * scale),
		Position = pos + Vector3.new(2 * scale, 18.5 * scale, -1.5 * scale),
		Parent = model,
	})
	createPart({
		Name = "CanopySide",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Grass,
		Color = leafColor2,
		Size = Vector3.new(11 * scale, 8.5 * scale, 11 * scale),
		Position = pos + Vector3.new(-3.5 * scale, 13 * scale, 2.5 * scale),
		Parent = model,
	})
end

-- Configures vibrant Simulator Lighting, Skybox, Atmosphere, Bloom, and ColorCorrection
local function configureLighting()
	Lighting.Ambient = Color3.fromRGB(125, 135, 160)
	Lighting.OutdoorAmbient = Color3.fromRGB(145, 155, 180)
	Lighting.Brightness = 2.6
	Lighting.ClockTime = 14.2
	Lighting.GlobalShadows = true

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

-- Builds a Spacious 76x58 Fenced Tycoon Sanctuary Plot with 3D Treadmill, Entrance Arch & 35 Nests
-- Helper to build a 3D Dino-Jaw / Monster-Head Treadmill (matching real_frame_a_01.png!)
local function buildDinoJawHead(beltPart: BasePart, faceDir: number, scale: number, parent: Instance)
	local dinoModel = Instance.new("Model")
	dinoModel.Name = "DinoTreadmillHead"
	dinoModel.Parent = parent

	local center = beltPart.Position
	local backX = center.X - faceDir * (5.2 * scale)
	local limeGreen = Color3.fromRGB(138, 218, 32)
	local darkLime = Color3.fromRGB(98, 175, 22)

	-- Left & Right Dino Jaw Pillars
	for side = -1, 1, 2 do
		createPart({
			Name = "DinoNeck_" .. side,
			Material = Enum.Material.SmoothPlastic,
			Color = darkLime,
			Size = Vector3.new(3.6 * scale, 8.8 * scale, 1.8 * scale),
			Position = Vector3.new(backX, center.Y + 4.4 * scale, center.Z + side * (3.6 * scale)),
			Parent = dinoModel,
		})
		-- Pink belt side guards with little white lower teeth
		createPart({
			Name = "BeltSideGuard_" .. side,
			Material = Enum.Material.SmoothPlastic,
			Color = limeGreen,
			Size = Vector3.new(13.5 * scale, 1.8 * scale, 1.1 * scale),
			Position = Vector3.new(center.X, center.Y + 0.9 * scale, center.Z + side * (3.9 * scale)),
			Parent = dinoModel,
		})
		for t = -2, 2 do
			createPart({
				Name = "LowerTooth_" .. side .. "_" .. t,
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 255, 255),
				Size = Vector3.new(0.65 * scale, 1.25 * scale, 0.55 * scale),
				Position = Vector3.new(center.X + t * (2.2 * scale), center.Y + 2.1 * scale, center.Z + side * (3.8 * scale)),
				Parent = dinoModel,
			})
		end
	end

	-- Overarching Green T-Rex / Monster Upper Head & Snout
	local snout = createPart({
		Name = "DinoUpperSnout",
		Material = Enum.Material.SmoothPlastic,
		Color = limeGreen,
		Size = Vector3.new(11.5 * scale, 4.6 * scale, 9.2 * scale),
		CFrame = CFrame.new(center.X - faceDir * (1.2 * scale), center.Y + 9.2 * scale, center.Z)
			* CFrame.Angles(0, 0, math.rad(-faceDir * 14)),
		Parent = dinoModel,
	})
	-- Nostrils
	for side = -1, 1, 2 do
		createPart({
			Name = "Nostril_" .. side,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(25, 35, 18),
			Size = Vector3.new(0.9 * scale, 0.9 * scale, 0.9 * scale),
			CFrame = snout.CFrame * CFrame.new(faceDir * (5.4 * scale), 0.8 * scale, side * (2.2 * scale)),
			Parent = dinoModel,
		})
		-- Big Cartoon White + Black Eyes on sides of Dino Head
		createPart({
			Name = "DinoEyeWhite_" .. side,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 255, 255),
			Size = Vector3.new(2.8 * scale, 2.8 * scale, 0.6 * scale),
			CFrame = snout.CFrame * CFrame.new(-faceDir * (1.4 * scale), 0.6 * scale, side * (4.65 * scale)),
			Parent = dinoModel,
		})
		createPart({
			Name = "DinoEyePupil_" .. side,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(15, 15, 20),
			Size = Vector3.new(1.5 * scale, 1.8 * scale, 0.75 * scale),
			CFrame = snout.CFrame * CFrame.new(-faceDir * (0.9 * scale), 0.5 * scale, side * (4.72 * scale)),
			Parent = dinoModel,
		})
	end

	-- Hanging Upper Row of Sharp White Dino Teeth
	for t = -3, 3 do
		createPart({
			Name = "UpperDinoTooth_" .. t,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 255, 255),
			Size = Vector3.new(0.75 * scale, 1.55 * scale, 0.75 * scale),
			CFrame = snout.CFrame * CFrame.new(faceDir * (4.8 * scale), -2.6 * scale, t * (1.15 * scale)),
			Parent = dinoModel,
		})
	end
end

-- Helper to build Warm Wooden Post-and-Rail Ranch Fencing around a Base Pen (matching real_frame_a_01.png!)
local function buildWoodenRanchFence(startPos: Vector3, endPos: Vector3, parent: Instance)
	local diff = endPos - startPos
	local dist = diff.Magnitude
	local mid = (startPos + endPos) * 0.5
	local woodBrown = Color3.fromRGB(138, 78, 36)
	local darkWood = Color3.fromRGB(108, 58, 24)

	-- Top and Bottom Horizontal Wooden Rails
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

	-- Vertical Wooden Fence Posts every 11 studs
	local numPosts = math.max(2, math.floor(dist / 11) + 1)
	for i = 0, numPosts - 1 do
		local alpha = i / math.max(1, numPosts - 1)
		local pPos = startPos:Lerp(endPos, alpha)
		createPart({
			Name = "FencePost",
			Material = Enum.Material.Wood,
			Color = darkWood,
			Size = Vector3.new(1.1, 4.4, 1.1),
			Position = pPos + Vector3.new(0, 2.2, 0),
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

	-- Two-Tone Checkered Grass Squares on the Pen Lawn (matching real_frame_a_01.png!)
	for gx = -3, 2 do
		for gz = -2, 2 do
			if (gx + gz) % 2 == 0 then
				createPart({
					Name = "CheckeredTile",
					Material = Enum.Material.SmoothPlastic,
					Color = Color3.fromRGB(134, 224, 68),
					Size = Vector3.new(11.5, 0.12, 10.5),
					Position = centerPos + Vector3.new(gx * 11.5 + 5, 0.04, gz * 10.5),
					CanCollide = false,
					Parent = folder,
				})
			end
		end
	end

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

	-- 3. 3D DINO-JAW SPEED TREADMILL MACHINE (Front-South of Pen, matching real_frame_a_01.png!)
	local treadmillBelt = createPart({
		Name = "TreadmillBelt",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 105, 215), -- Glowing Pink/Magenta Dino Tongue Belt!
		Size = Vector3.new(14.5, 1.2, 7.2),
		Position = centerPos + Vector3.new(faceDir * 24, 0.6, 18),
		Parent = folder,
	})
	treadmillBelt:SetAttribute("IsTreadmill", true)
	treadmillBelt:SetAttribute("PlotIndex", plotIndex)
	buildDinoJawHead(treadmillBelt, faceDir, 1.0, folder)
	addPadSign(treadmillBelt, "🦖 DINO SPEED TREADMILL", "Run inside Jaw for +Speed Power!", Color3.fromRGB(85, 245, 255), 34)

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

	-- 5. 35 SQUISHY LAWN SLOTS (with ClickDetectors so clicking any slot while holding a Backpack Squishy places it!)
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
		local slotClick = Instance.new("ClickDetector")
		slotClick.Name = "PlaceSlotClick"
		slotClick.MaxActivationDistance = 55
		slotClick.Parent = pedestal

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
	-- 1. CENTRAL HUB RESORT PLAZA WITH TWO-TONE CHECKERED LIME LAWN (matching real_frame_a_01.png!)
	-- =========================================================================
	createPart({
		Name = "HubOuterGrass",
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(112, 208, 52),
		Size = Vector3.new(340, 4, 280),
		Position = Vector3.new(0, -2.2, 80),
		Parent = worldFolder,
	})
	-- Checkered Bright Lime Grid across the Hub Promenade
	for cx = -3, 3 do
		for cz = -6, 6 do
			if (cx + cz) % 2 == 0 then
				createPart({
					Name = "HubCheckeredTile",
					Material = Enum.Material.SmoothPlastic,
					Color = Color3.fromRGB(132, 226, 68),
					Size = Vector3.new(18, 0.15, 18),
					Position = Vector3.new(cx * 18, 0.02, 80 + cz * 18),
					CanCollide = false,
					Parent = worldFolder,
				})
			end
		end
	end

	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "HubSpawn"
	spawnLoc.Anchored = true
	spawnLoc.Size = Vector3.new(22, 1.2, 22)
	spawnLoc.Position = Vector3.new(0, 0.6, 175)
	spawnLoc.Material = Enum.Material.Neon
	spawnLoc.Color = Color3.fromRGB(85, 235, 255)
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.Parent = worldFolder

	-- 3 Giant Rarity Odds & Showcase Display Boards (Gold, Cyan, Red — matching top-left of real_frame_a_01.png!)
	local showcaseSpecs = {
		{ Pos = Vector3.new(-32, 9, 198), Color = Color3.fromRGB(255, 210, 45), Title = "🌟 LEGENDARY EGGS", Sub = "Golden & Crowned • $600–$1,800/s" },
		{ Pos = Vector3.new(0, 10, 202), Color = Color3.fromRGB(55, 225, 255), Title = "💎 MYTHIC SQUISHIES", Sub = "Saturn-Ringed • $2,500–$8,000/s" },
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

	-- Grand Golden Squishy Fountain at Hub Center (0, Y, 130)
	createPart({
		Name = "FountainBasin",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(245, 245, 252),
		Size = Vector3.new(3.5, 28, 28),
		CFrame = CFrame.new(0, 1.75, 130) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = worldFolder,
	})
	createPart({
		Name = "FountainWater",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(75, 225, 255),
		Size = Vector3.new(3.8, 25, 25),
		CFrame = CFrame.new(0, 1.8, 130) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = worldFolder,
	})
	createPart({
		Name = "FountainPillar",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(255, 235, 175),
		Size = Vector3.new(10, 9, 9),
		CFrame = CFrame.new(0, 6.5, 130) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = worldFolder,
	})
	local statueSquishy = SquishyBuilder.CreateHatchedSquishy(SlimeData.ById[35], Vector3.new(0, 15, 130), 2, 5)
	statueSquishy.Name = "GoldenFountainStatue"
	statueSquishy.Parent = worldFolder

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
		"Run inside the T-Rex Mouth for +Speed Power!",
		Color3.fromRGB(95, 250, 255),
		48
	)

	-- Scenic Trees lining the Hub Resort
	for _, treePos in ipairs({
		Vector3.new(-52, 0, 195),
		Vector3.new(52, 0, 195),
		Vector3.new(-52, 0, -45),
		Vector3.new(52, 0, -45),
	}) do
		buildTree(treePos, Color3.fromRGB(125, 85, 55), Color3.fromRGB(68, 192, 88), Color3.fromRGB(105, 225, 115), 1.15, worldFolder)
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
	-- 2. FIVE MASSIVE LEVEL BIOMES (240 wide x 260 long each), LANDMARKS & OBBIES
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

		-- Two-Tone Checkered Biome Floor Tiles (matching real_dense_08.png!)
		local tileAccent = lvl.FloorColor:Lerp(lvl.ThemeColor, 0.22)
		for tx = -4, 4 do
			for tz = -4, 4 do
				if (tx + tz) % 2 == 0 then
					createPart({
						Name = "BiomeCheckeredTile",
						Material = Enum.Material.SmoothPlastic,
						Color = tileAccent,
						Size = Vector3.new(24, 0.14, 26),
						Position = Vector3.new(tx * 24, 0.04, midZ + tz * 26),
						CanCollide = false,
						Parent = biomeFolder,
					})
				end
			end
		end

		-- Scenic Side Cliffs / Perimeter Walls with 3D Chocolate / Neon Wall Slabs
		for side = -1, 1, 2 do
			createPart({
				Name = if side == -1 then "LeftBoundaryWall" else "RightBoundaryWall",
				Material = if lvl.Level == 5 then Enum.Material.Basalt else Enum.Material.SmoothPlastic,
				Color = lvl.ThemeColor:Lerp(Color3.fromRGB(75, 45, 35), if lvl.Level == 2 then 0.55 else 0.15),
				Size = Vector3.new(6, 36, lengthZ),
				Position = Vector3.new(side * 120, 16, midZ),
				Parent = biomeFolder,
			})
			for wz = -3, 3 do
				createPart({
					Name = "WallReliefSlab",
					Material = Enum.Material.SmoothPlastic,
					Color = lvl.ThemeColor,
					Size = Vector3.new(2.5, 22, 16),
					Position = Vector3.new(side * 116, 14, midZ + wz * 34),
					Parent = biomeFolder,
				})
			end
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

		-- SAFE ZONE LINE at Entrance of each Level (Guardians stop chasing once you cross back over!)
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

		-- Helper to build an Obby Stepping Course + Hiding Alcove leading up to any Egg position
		local function buildObbyToEgg(eggPos: Vector3, stepCount: number, stepColor: Color3, hasLaserHurdles: boolean, hasHidingCover: boolean)
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
				-- Climbing Truss so kids can always climb up or jump!
				local truss = Instance.new("TrussPart")
				truss.Name = "SummitClimbTruss"
				truss.Anchored = true
				truss.Color = stepColor
				truss.Size = Vector3.new(2, math.max(6, eggPos.Y - 2), 2)
				truss.Position = Vector3.new(eggPos.X, (eggPos.Y - 2) / 2, eggPos.Z + 6.5)
				truss.Parent = biomeFolder
			end
			if hasHidingCover then
				createPart({
					Name = "HidingScreenFront",
					Material = Enum.Material.SmoothPlastic,
					Color = lvl.ThemeColor,
					Size = Vector3.new(11, 9, 2),
					Position = eggPos + Vector3.new(0, 1.8, 5.5),
					Parent = biomeFolder,
				})
				createPart({
					Name = "HidingScreenSide",
					Material = Enum.Material.SmoothPlastic,
					Color = lvl.FloorColor,
					Size = Vector3.new(2, 9, 11),
					Position = eggPos + Vector3.new(if eggPos.X >= 0 then -5.5 else 5.5, 1.8, 0),
					Parent = biomeFolder,
				})
			end
		end

		for _, slimeDef in ipairs(SlimeData.ByLevel[lvl.Level] or {}) do
			if not slimeDef.IsCoopVault and not slimeDef.IsMicroVent then
				local steps = if slimeDef.Position.Y > 20 then 6 elseif slimeDef.Position.Y > 10 then 4 else 3
				local useLasers = (lvl.Level >= 2)
				local useCover = (slimeDef.Behavior == "Static" or slimeDef.Behavior == "Disguised")
				buildObbyToEgg(slimeDef.Position, steps, slimeDef.SecondaryColor, useLasers, useCover)
			end
		end

		-- =====================================================================
		-- BIOME-SPECIFIC MEGA 3D LANDMARKS & ARCHITECTURE
		-- =====================================================================
		if lvl.Level == 1 then
			-- 3D Red Meadow Barn at (-68, 0, -115)
			createPart({
				Name = "BarnWallL",
				Material = Enum.Material.WoodPlanks,
				Color = Color3.fromRGB(195, 55, 55),
				Size = Vector3.new(2, 16, 24),
				Position = Vector3.new(-80, 8, -115),
				Parent = biomeFolder,
			})
			createPart({
				Name = "BarnWallR",
				Material = Enum.Material.WoodPlanks,
				Color = Color3.fromRGB(195, 55, 55),
				Size = Vector3.new(2, 16, 24),
				Position = Vector3.new(-56, 8, -115),
				Parent = biomeFolder,
			})
			createPart({
				Name = "BarnRoof",
				Material = Enum.Material.Slate,
				Color = Color3.fromRGB(75, 45, 45),
				Size = Vector3.new(28, 3, 26),
				Position = Vector3.new(-68, 17, -115),
				Parent = biomeFolder,
			})
			-- Lush Forest of 12 Multi-Canopy Trees across Meadow Gardens
			for _, tPos in ipairs({
				Vector3.new(-95, 0, -85),
				Vector3.new(95, 0, -85),
				Vector3.new(-45, 0, -140),
				Vector3.new(45, 0, -140),
				Vector3.new(-95, 0, -210),
				Vector3.new(95, 0, -210),
				Vector3.new(64, 0, -285),
				Vector3.new(-55, 0, -290),
			}) do
				buildTree(tPos, Color3.fromRGB(120, 80, 50), Color3.fromRGB(65, 185, 80), Color3.fromRGB(95, 225, 110), 1.25, biomeFolder)
			end
			-- Rushing Blue River & Elevated Suspension Bridge at Z = -195
			createPart({
				Name = "MeadowRiver",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(65, 195, 255),
				Transparency = 0.25,
				Size = Vector3.new(234, 0.8, 28),
				Position = Vector3.new(0, 0.2, -195),
				CanCollide = false,
				Parent = biomeFolder,
			})
			createPart({
				Name = "SuspensionBridgeDeck",
				Material = Enum.Material.WoodPlanks,
				Color = Color3.fromRGB(155, 105, 62),
				Size = Vector3.new(24, 2, 34),
				Position = Vector3.new(0, 10, -195),
				Parent = biomeFolder,
			})
		elseif lvl.Level == 2 then
			-- Candy Kingdom: Frosting Waterfall Cave, Chocolate Castle & Giant Lollipops
			createPart({
				Name = "FrostingWaterfall",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(135, 235, 255),
				Transparency = 0.3,
				Size = Vector3.new(24, 24, 2),
				Position = Vector3.new(-72, 12, -365),
				CanCollide = false,
				Parent = biomeFolder,
			})
			-- Giant Swirl Lollipops lining the Candy Road
			for i = 1, 6 do
				local lx = if i % 2 == 0 then 52 else -52
				local lz = -345 - i * 32
				createPart({
					Name = "LollipopStick_" .. i,
					Shape = Enum.PartType.Cylinder,
					Color = Color3.fromRGB(255, 255, 255),
					Size = Vector3.new(18, 1.8, 1.8),
					CFrame = CFrame.new(lx, 9, lz) * CFrame.Angles(0, 0, math.rad(90)),
					Parent = biomeFolder,
				})
				createPart({
					Name = "LollipopCandy_" .. i,
					Shape = Enum.PartType.Cylinder,
					Material = Enum.Material.Neon,
					Color = Color3.fromHSV((i * 0.16) % 1, 0.7, 1),
					Size = Vector3.new(2.5, 11, 11),
					CFrame = CFrame.new(lx, 20, lz) * CFrame.Angles(0, math.rad(90), 0),
					Parent = biomeFolder,
				})
			end
		elseif lvl.Level == 3 then
			-- Toybox Bedroom: Giant 4-Poster Bouncy Bed at (68, 0, -665) & Study Desk at (45, 0, -808)
			local mattress = createPart({
				Name = "GiantBouncyMattress",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(105, 205, 255),
				Size = Vector3.new(34, 10, 42),
				Position = Vector3.new(68, 5, -665),
				Parent = biomeFolder,
			})
			mattress:SetAttribute("IsTrampoline", true)
			addPadSign(mattress, "🛏️ GIANT BOUNCY BED", "Jump for Super Obby Launch!", Color3.fromRGB(125, 225, 255), 40)

			createPart({
				Name = "GiantStudyDesk",
				Material = Enum.Material.Wood,
				Color = Color3.fromRGB(165, 110, 65),
				Size = Vector3.new(38, 2, 26),
				Position = Vector3.new(45, 20, -808),
				Parent = biomeFolder,
			})
			-- Giant Yellow Ruler Ramp leading up to the Study Desk!
			createPart({
				Name = "RulerRamp",
				Material = Enum.Material.SmoothPlastic,
				Color = Color3.fromRGB(255, 215, 65),
				Size = Vector3.new(10, 1.5, 42),
				CFrame = CFrame.new(45, 10, -780) * CFrame.Angles(math.rad(28), 0, 0),
				Parent = biomeFolder,
			})
		elseif lvl.Level == 4 then
			-- Neon Cyber Lab: Glowing Cyber Archways & Central Quantum Reactor
			for a = 1, 4 do
				local az = -860 - a * 52
				createPart({
					Name = "CyberRing_" .. a,
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(0, 240, 255),
					Size = Vector3.new(75, 2.5, 2.5),
					Position = Vector3.new(0, 26, az),
					Parent = biomeFolder,
				})
			end
			createPart({
				Name = "QuantumReactorCore",
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(195, 75, 255),
				Size = Vector3.new(18, 18, 18),
				Position = Vector3.new(0, 16, -955),
				Parent = biomeFolder,
			})
		elseif lvl.Level == 5 then
			-- Magma & Crystal Caverns: Boiling Lava River, Amethyst Crystal Spires & Volcano Temple Summit!
			local lavaRiver = createPart({
				Name = "LavaLakeHazard",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 75, 20),
				Size = Vector3.new(232, 0.8, 45),
				Position = Vector3.new(0, 0.2, -1230),
				CanCollide = false,
				Parent = biomeFolder,
			})
			lavaRiver:SetAttribute("IsObbyHazard", true)
			for stone = 1, 7 do
				createPart({
					Name = "ObsidianSteppingStone_" .. stone,
					Material = Enum.Material.Basalt,
					Color = Color3.fromRGB(48, 42, 55),
					Size = Vector3.new(10, 2.8, 10),
					Position = Vector3.new(-48 + stone * 12, 1.4, -1212 - (stone % 2) * 16),
					Parent = biomeFolder,
				})
			end
			-- Towering Volcano Summit Temple at (0, Y, -1358)
			createPart({
				Name = "VolcanoBaseTier",
				Material = Enum.Material.Basalt,
				Color = Color3.fromRGB(55, 35, 40),
				Size = Vector3.new(64, 14, 48),
				Position = Vector3.new(0, 7, -1358),
				Parent = biomeFolder,
			})
			createPart({
				Name = "VolcanoMidTier",
				Material = Enum.Material.Basalt,
				Color = Color3.fromRGB(70, 40, 45),
				Size = Vector3.new(44, 14, 34),
				Position = Vector3.new(0, 21, -1358),
				Parent = biomeFolder,
			})
			createPart({
				Name = "SovereignSummitAltar",
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 205, 55),
				Size = Vector3.new(26, 11, 24),
				Position = Vector3.new(0, 33.5, -1358),
				Parent = biomeFolder,
			})
			createPart({
				Name = "VolcanoBackWall",
				Material = Enum.Material.Basalt,
				Color = Color3.fromRGB(40, 24, 28),
				Size = Vector3.new(244, 52, 6),
				Position = Vector3.new(0, 24, -1382),
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
