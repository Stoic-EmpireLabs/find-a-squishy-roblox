--!strict
--[[
	WorldBuilder.luau
	Ultimate "Steal My Egg! + Find 117 Shining Squishies" 3D World Builder:
	  1. 117 Total Collectible / Stealable Shining Squishies & Eggs:
	       - 35 Oversized Ornate Boss Eggs (#1-#35) guarded by 10 Giant Sleeping Bosses
	       - 16 Rooftop Shining Squishies (#36-#51) atop properly colored Houses with Rooftop Parkour
	       - 12 Sky & Staircase Shining Squishies (#52-#63) on the Giant Rainbow Disappearing Staircase
	       - 20 Outer Maze Shining Squishies (#64-#83) hidden inside the Left & Right Outer Labyrinths
	       - 19 Castle Wall Shining Squishies (#84-#102) along the Crenellated Castle Wall Battlements
	       - 15 Biome Obby Shining Squishies (#103-#117) atop each Level's Themed Obby Gauntlet
	  2. Newer Graphics, Newer Concentric Glowing Neon Circles, Newer Proportions
	  3. Creator Store 3D Assets (Houses, Trees, Candy, PalmTrees, Crystals, VolcanoRocks, Bridges, ObbyStages, Fountain, Chest)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SlimeData = require(Shared:WaitForChild("SlimeData"))
local SquishyBuilder = require(Shared:WaitForChild("SquishyBuilder"))
local PrebuiltLoader = require(Shared:WaitForChild("PrebuiltLoader"))

local WorldBuilder = {}

local MAP_WIDTH = 296
local OUTER_MAZE_WIDTH = 56 -- Flanking outer mazes cleanly outside Castle Walls (X = ±154 to ±210)
local WALL_HEIGHT = 18
local WALL_THICKNESS = 5

local function makePart(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = if props.Anchored ~= nil then props.Anchored else true
	p.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
	p.CanTouch = if props.CanTouch ~= nil then props.CanTouch else false
	p.CanQuery = if props.CanQuery ~= nil then props.CanQuery else p.CanCollide
	p.CastShadow = false
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.Color = props.Color or Color3.fromRGB(200, 200, 200)
	local reqMat = props.Material or Enum.Material.Plastic
	if props.Shape then
		p.Shape = props.Shape
	end

	-- Authentic "Find The Squishies" Classic Stud Surface Aesthetic on all non-Neon/non-Glass Block parts!
	local isSpecialMat = (reqMat == Enum.Material.Neon or reqMat == Enum.Material.Glass or reqMat == Enum.Material.ForceField or reqMat == Enum.Material.Water)
	if not isSpecialMat and (not props.Shape or props.Shape == Enum.PartType.Block) and props.NoStuds ~= true then
		p.Material = Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Studs
		p.BottomSurface = Enum.SurfaceType.Inlet
		if p.Size.Y >= 2.2 then
			p.FrontSurface = Enum.SurfaceType.Studs
			p.BackSurface = Enum.SurfaceType.Studs
			p.LeftSurface = Enum.SurfaceType.Studs
			p.RightSurface = Enum.SurfaceType.Studs
		else
			p.FrontSurface = Enum.SurfaceType.Smooth
			p.BackSurface = Enum.SurfaceType.Smooth
			p.LeftSurface = Enum.SurfaceType.Smooth
			p.RightSurface = Enum.SurfaceType.Smooth
		end
	else
		p.Material = reqMat
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
	end

	p.Transparency = props.Transparency or 0
	p.Reflectance = props.Reflectance or 0
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

local function createBillboardText(
	parent: Instance,
	text: string,
	color: Color3,
	offset: Vector3,
	scaleSize: UDim2?,
	maxDist: number?
): BillboardGui
	local bb = Instance.new("BillboardGui")
	-- Chapter 2 Rule: Always use 3D Stud Scale (Offsets = 0), AlwaysOnTop = false, LightInfluence = 0, and tight MaxDistance!
	if scaleSize and (scaleSize.X.Offset > 0 or scaleSize.Y.Offset > 0) then
		bb.Size = UDim2.new(math.clamp(scaleSize.X.Offset / 28, 4.5, 11.5), 0, math.clamp(scaleSize.Y.Offset / 28, 1.3, 2.6), 0)
	else
		bb.Size = scaleSize or UDim2.new(7.5, 0, 1.8, 0)
	end
	bb.StudsOffset = offset
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.MaxDistance = maxDist or 52
	bb.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color
	lbl.TextScaled = true
	lbl.Font = Enum.Font.FredokaOne
	lbl.Parent = bb

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(15, 10, 30)
	stroke.Thickness = 2.2
	stroke.Parent = lbl

	return bb
end

-- Chapter 2 Rule: Render architectural signs directly onto 3D part faces using SurfaceGui!
local function createSurfaceSign(
	part: BasePart,
	text: string,
	textColor: Color3,
	bgColor: Color3?,
	faces: { Enum.NormalId }?,
	maxDist: number?
)
	local targetFaces = faces or { Enum.NormalId.Back, Enum.NormalId.Front }
	for _, face in ipairs(targetFaces) do
		local sg = Instance.new("SurfaceGui")
		sg.Name = "SurfaceSign_" .. face.Name
		sg.Face = face
		sg.AlwaysOnTop = false
		sg.LightInfluence = 0
		sg.Brightness = 2
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 36
		sg.MaxDistance = maxDist or 240
		sg.Parent = part

		local plate = Instance.new("Frame")
		plate.Name = "SignPlate"
		plate.Size = UDim2.fromScale(0.94, 0.86)
		plate.Position = UDim2.fromScale(0.5, 0.5)
		plate.AnchorPoint = Vector2.new(0.5, 0.5)
		plate.BackgroundColor3 = bgColor or Color3.fromRGB(20, 24, 42)
		plate.BackgroundTransparency = 0.12
		plate.BorderSizePixel = 0
		plate.Parent = sg

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.22, 0)
		corner.Parent = plate

		local plateStroke = Instance.new("UIStroke")
		plateStroke.Color = textColor
		plateStroke.Thickness = 3
		plateStroke.Parent = plate

		local lbl = Instance.new("TextLabel")
		lbl.Name = "SignLabel"
		lbl.Size = UDim2.fromScale(0.92, 0.86)
		lbl.Position = UDim2.fromScale(0.5, 0.5)
		lbl.AnchorPoint = Vector2.new(0.5, 0.5)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = textColor
		lbl.TextScaled = true
		lbl.Font = Enum.Font.FredokaOne
		lbl.Parent = plate

		local textStroke = Instance.new("UIStroke")
		textStroke.Color = Color3.fromRGB(12, 10, 24)
		textStroke.Thickness = 2.4
		textStroke.Parent = lbl
	end
end

-- Newer Concentric Glowing Neon Circle Pad (for Incubators, Pedestals, Collect Pads, and Landmarks)
local function buildGlowingNeonCircle(
	parent: Instance,
	name: string,
	pos: Vector3,
	outerDiameter: number,
	outerColor: Color3,
	innerColor: Color3
): Part
	local outerRing = makePart({
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.65, outerDiameter, outerDiameter),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = outerColor,
		Material = Enum.Material.Neon,
		Parent = parent,
	})
	makePart({
		Name = "DarkCoreDisk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.70, outerDiameter * 0.80, outerDiameter * 0.80),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(24, 28, 46),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = outerRing,
	})
	makePart({
		Name = "InnerNeonRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.75, outerDiameter * 0.56, outerDiameter * 0.56),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = innerColor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = outerRing,
	})
	return outerRing
end

local function setupVibrantLighting()
	Lighting.Ambient = Color3.fromRGB(158, 168, 190)
	Lighting.OutdoorAmbient = Color3.fromRGB(178, 188, 210)
	Lighting.Brightness = 2.5
	Lighting.ColorShift_Top = Color3.fromRGB(255, 250, 235)
	Lighting.ClockTime = 13.5
	Lighting.GeographicLatitude = 32
	Lighting.GlobalShadows = false

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.SunAngularSize = 18
	sky.MoonAngularSize = 11
	sky.Parent = Lighting

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.16
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(190, 232, 255)
	atmo.Decay = Color3.fromRGB(150, 205, 250)
	atmo.Glare = 0.08
	atmo.Haze = 0.45
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 22
	bloom.Threshold = 0.92
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.03
	cc.Contrast = 0.15
	cc.Saturation = 0.26
	cc.Parent = Lighting
end

local function placePrebuiltAsset(category: string, index: number, parent: Instance, pos: Vector3, yawDeg: number, targetHeight: number, canCollide: boolean?): Model?
	local model = PrebuiltLoader.CloneNormalizedTemplate(category, index, targetHeight, canCollide)
	if not model then
		return nil
	end
	model:PivotTo(CFrame.new(pos.X, pos.Y, pos.Z) * CFrame.Angles(0, math.rad(yawDeg), 0))
	model.Parent = parent
	return model
end

-- Helper: Builds an authentic "Find The Squishies" X-Braced Wooden Crate (`fts_frame_12.png`)
local function buildWoodenCrate(parent: Instance, cframe: CFrame, sizeVal: number): Part
	local crate = makePart({
		Name = "WoodenCrate",
		Size = Vector3.new(sizeVal, sizeVal, sizeVal),
		CFrame = cframe,
		Color = Color3.fromRGB(182, 126, 78),
		Material = Enum.Material.Plastic,
		Parent = parent,
	})
	-- Darker wooden frame border / diagonal brace accent on front & back
	for _, zSide in ipairs({ -1, 1 }) do
		makePart({
			Name = "CrateBrace",
			Size = Vector3.new(sizeVal * 0.86, sizeVal * 0.16, 0.25),
			CFrame = cframe * CFrame.new(0, 0, zSide * (sizeVal * 0.49)) * CFrame.Angles(0, 0, math.rad(45)),
			Color = Color3.fromRGB(128, 82, 46),
			Material = Enum.Material.Plastic,
			CanCollide = false,
			Parent = parent,
		})
	end
	return crate
end

-- Builds an Authentic "Find The Squishies" Walk-Inside Studded House (`fts_frame_01.png`, `fts_frame_10.png`, `fts_frame_12.png`, `fts_frame_15.png`)
-- Includes: Walk-in Open Doorway, Interior Blue Stud Floor, Purple Couch, Display Shelf, Door Code Keypad,
-- 4 Colored Square Windows (Red/Blue/Green/Yellow), Stepped Pitched Stud Roof, Tall Dark Chimney,
-- AND Stacked Wooden Crate Towers + Tilted Plank Bridge up to the Roof!
local function buildBigCartoonHouse(
	parent: Instance,
	pos: Vector3,
	yawDeg: number,
	wallColor: Color3,
	roofColor: Color3,
	houseIdx: number,
	targetHeight: number,
	biomeId: number?
)
	local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(yawDeg), 0)
	local hModel = Instance.new("Model")
	hModel.Name = "SquishyHouse_" .. tostring(houseIdx)
	hModel.Parent = parent

	local w = 18.0
	local d = 15.0
	local bodyH = math.max(12.5, targetHeight * 0.60)
	local roofH = math.max(7.5, targetHeight - bodyH)
	local wallT = 1.4

	-- 1. Interior Sky-Blue Studded Floor (`fts_frame_10.png`)
	local floorPart = makePart({
		Name = "HouseInteriorFloor",
		Size = Vector3.new(w - 0.4, 0.8, d - 0.4),
		CFrame = cf * CFrame.new(0, 0.4, 0),
		Color = Color3.fromRGB(118, 178, 212),
		Material = Enum.Material.Plastic,
		Parent = hModel,
	})
	hModel.PrimaryPart = floorPart

	-- 2. Hollow Walk-In Walls (Back, Left, Right, and Front with Open Doorway!)
	makePart({
		Name = "BackWall",
		Size = Vector3.new(w, bodyH, wallT),
		CFrame = cf * CFrame.new(0, bodyH * 0.5, d * 0.5 - wallT * 0.5),
		Color = wallColor,
		Material = Enum.Material.Plastic,
		Parent = hModel,
	})
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "SideWall",
			Size = Vector3.new(wallT, bodyH, d),
			CFrame = cf * CFrame.new(side * (w * 0.5 - wallT * 0.5), bodyH * 0.5, 0),
			Color = wallColor,
			Material = Enum.Material.Plastic,
			Parent = hModel,
		})
		-- Front wall flanking the 5.2-stud open doorway
		local sideFrontW = (w - 5.2) * 0.5
		makePart({
			Name = "FrontWallSide",
			Size = Vector3.new(sideFrontW, bodyH, wallT),
			CFrame = cf * CFrame.new(side * (2.6 + sideFrontW * 0.5), bodyH * 0.5, -d * 0.5 + wallT * 0.5),
			Color = wallColor,
			Material = Enum.Material.Plastic,
			Parent = hModel,
		})
	end
	-- Upper Front Wall Header above the 8.2-stud tall open doorway
	local headerH = bodyH - 8.2
	if headerH > 0.5 then
		makePart({
			Name = "FrontDoorHeader",
			Size = Vector3.new(5.2, headerH, wallT),
			CFrame = cf * CFrame.new(0, 8.2 + headerH * 0.5, -d * 0.5 + wallT * 0.5),
			Color = wallColor,
			Material = Enum.Material.Plastic,
			Parent = hModel,
		})
	end

	-- Brick Corner Pillars (`fts_frame_06.png` & `fts_frame_15.png`)
	local trimBrick = roofColor:Lerp(Color3.fromRGB(165, 85, 62), 0.55)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			makePart({
				Name = "CornerTrimPillar",
				Size = Vector3.new(1.8, bodyH + 0.2, 1.8),
				CFrame = cf * CFrame.new(sx * (w * 0.5 - 0.4), bodyH * 0.5, sz * (d * 0.5 - 0.4)),
				Color = trimBrick,
				Material = Enum.Material.Plastic,
				Parent = hModel,
			})
		end
	end

	-- 3. Stepped Stone Front Entrance Steps + Door Code Keypad (`fts_frame_01.png`)
	for s = 1, 3 do
		makePart({
			Name = "FrontDoorStep_" .. tostring(s),
			Size = Vector3.new(6.4, 0.5, 1.2 + (3 - s) * 1.1),
			CFrame = cf * CFrame.new(0, s * 0.35, -d * 0.5 - (4 - s) * 0.55),
			Color = Color3.fromRGB(145, 148, 162),
			Material = Enum.Material.Plastic,
			Parent = hModel,
		})
	end
	local keypad = makePart({
		Name = "DoorKeypad",
		Size = Vector3.new(1.8, 2.6, 0.4),
		CFrame = cf * CFrame.new(4.2, 4.8, -d * 0.5 - 0.15),
		Color = Color3.fromRGB(48, 52, 64),
		Material = Enum.Material.Plastic,
		Parent = hModel,
	})
	createSurfaceSign(keypad, "1710\n[1][2][3]\n[4][5][6]\n[7][8][9]", Color3.fromRGB(255, 255, 255), Color3.fromRGB(35, 38, 48), { Enum.NormalId.Front, Enum.NormalId.Back }, 45)

	-- 4. Iconic 4 Colored Square Windows on the Front Facade (`fts_frame_01.png`: Red, Blue, Green, Yellow!)
	local winColors = {
		Color3.fromRGB(235, 55, 65),
		Color3.fromRGB(55, 125, 245),
		Color3.fromRGB(65, 215, 75),
		Color3.fromRGB(255, 225, 55),
	}
	for wIdx, wCol in ipairs(winColors) do
		local wx = -6.0 + (wIdx - 1) * 4.0
		makePart({
			Name = "ColoredGableWindow_" .. tostring(wIdx),
			Size = Vector3.new(2.2, 2.4, 0.5),
			CFrame = cf * CFrame.new(wx, bodyH - 2.2, -d * 0.5 - 0.1),
			Color = wCol,
			Material = Enum.Material.Plastic,
			Parent = hModel,
		})
	end

	-- 5. Interior Furniture (`fts_frame_10.png` & `full_frame_05.png`): Cozy Purple Couch + Multi-Tier Shelf!
	makePart({
		Name = "InteriorCouchSeat",
		Size = Vector3.new(6.5, 1.8, 2.8),
		CFrame = cf * CFrame.new(-3.8, 1.5, 3.8),
		Color = Color3.fromRGB(165, 145, 225),
		Material = Enum.Material.Plastic,
		Parent = hModel,
	})
	makePart({
		Name = "InteriorCouchBack",
		Size = Vector3.new(6.5, 3.4, 1.0),
		CFrame = cf * CFrame.new(-3.8, 2.4, 4.8),
		Color = Color3.fromRGB(142, 122, 205),
		Material = Enum.Material.Plastic,
		Parent = hModel,
	})
	for tier = 1, 3 do
		makePart({
			Name = "InteriorShelf_" .. tostring(tier),
			Size = Vector3.new(5.2, 0.5, 2.0),
			CFrame = cf * CFrame.new(4.2, 1.5 + tier * 2.0, 4.5),
			Color = Color3.fromRGB(155, 138, 210),
			Material = Enum.Material.Plastic,
			Parent = hModel,
		})
	end

	-- 6. Stepped Pitched Stud Roof (`fts_frame_15.png`) + Walkable Top Landing + Tall Dark Brick Chimney!
	local numRoofSteps = 5
	for rStep = 1, numRoofSteps do
		local ratio = (rStep - 1) / numRoofSteps
		local stepW = (w + 3.6) * (1 - ratio * 0.42)
		local stepD = (d + 3.2) * (1 - ratio * 0.35)
		local stepH = roofH / numRoofSteps
		makePart({
			Name = "SteppedRoofTier_" .. tostring(rStep),
			Size = Vector3.new(stepW, stepH + 0.2, stepD),
			CFrame = cf * CFrame.new(0, bodyH + (rStep - 0.5) * stepH, 0),
			Color = roofColor,
			Material = Enum.Material.Plastic,
			Parent = hModel,
		})
	end

	-- Flat Roof Walkable Landing Platform so Rooftop Squishies (#36-#55) sit cleanly on top
	makePart({
		Name = "RoofWalkPad",
		Size = Vector3.new(11.5, 0.9, 10.5),
		CFrame = cf * CFrame.new(0, targetHeight - 1.4, 0),
		Color = roofColor,
		Material = Enum.Material.Plastic,
		Parent = hModel,
	})

	-- Tall Dark Studded Chimney (`fts_frame_15.png`)
	makePart({
		Name = "TallDarkChimney",
		Size = Vector3.new(3.6, 8.5, 3.6),
		CFrame = cf * CFrame.new(-4.8, targetHeight + 1.8, -2.6),
		Color = Color3.fromRGB(68, 56, 48),
		Material = Enum.Material.Plastic,
		Parent = hModel,
	})

	-- 7. Authentic "Find The Squishies" Stacked Wooden Crate Pyramid + Tilted Wooden Plank Bridge to Roof (`fts_frame_12.png`, `full_frame_06.png`)!
	-- Only build rooftop crate stairs in Stages 1-8 (pos.Z < 0) so Safe Zone Player Plots have zero crate box clutter next to the Hatchery Pen!
	if pos.Z < 0 then
		buildWoodenCrate(hModel, cf * CFrame.new(11.5, 2.0, 5.2), 4.0)
		buildWoodenCrate(hModel, cf * CFrame.new(11.5, 2.0, 1.0), 4.0)
		buildWoodenCrate(hModel, cf * CFrame.new(11.5, 6.0, 1.0), 4.0)
		buildWoodenCrate(hModel, cf * CFrame.new(11.5, 2.0, -3.2), 4.0)
		buildWoodenCrate(hModel, cf * CFrame.new(11.5, 6.0, -3.2), 4.0)
		buildWoodenCrate(hModel, cf * CFrame.new(11.5, 10.0, -3.2), 4.0)

		-- Tilted Narrow Wooden Plank Bridge from Top Crate onto the House Roof (`fts_frame_12.png`)!
		makePart({
			Name = "CrateToRoofPlankBridge",
			Size = Vector3.new(8.5, 0.6, 2.4),
			CFrame = (cf * CFrame.new(7.8, 12.8, -3.2)) * CFrame.Angles(0, 0, math.rad(16)),
			Color = Color3.fromRGB(198, 145, 92),
			Material = Enum.Material.Plastic,
			Parent = hModel,
		})

		-- Plus a Bouncy Awning Pad for fast launches to the roof!
		local bounceAwning = makePart({
			Name = "BouncePad",
			Size = Vector3.new(5.2, 1.0, 5.2),
			CFrame = cf * CFrame.new(11.5, 4.4, 5.2),
			Color = roofColor:Lerp(Color3.fromRGB(255, 235, 75), 0.45),
			Material = Enum.Material.Neon,
			Parent = hModel,
		})
		bounceAwning:SetAttribute("BounceImpulse", 78)
	end

	-- Biome-Specific Accent alongside the house
	if biomeId == 1 then
		makePart({
			Name = "MeadowSilo",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(targetHeight * 0.85, 6.5, 6.5),
			CFrame = (cf * CFrame.new(-11.5, targetHeight * 0.42, -2.0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(238, 225, 195),
			Material = Enum.Material.Plastic,
			Parent = hModel,
		})
	elseif biomeId == 2 then
		for g = -1, 1 do
			makePart({
				Name = "RoofGumdrop_" .. tostring(g),
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(3.4, 3.6, 3.4),
				CFrame = cf * CFrame.new(g * 4.2, targetHeight + 0.2, 2.5),
				Color = if g == 0 then Color3.fromRGB(255, 235, 75) else Color3.fromRGB(95, 235, 255),
				Material = Enum.Material.Neon,
				Parent = hModel,
			})
		end
	elseif biomeId == 3 then
		for _, torchX in ipairs({ -6.8, 6.8 }) do
			makePart({
				Name = "TikiTorchPole",
				Size = Vector3.new(0.9, 7.5, 0.9),
				CFrame = cf * CFrame.new(torchX, 3.75, -9.2),
				Color = Color3.fromRGB(168, 122, 58),
				Material = Enum.Material.Plastic,
				Parent = hModel,
			})
			makePart({
				Name = "TikiTorchFlame",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(2.0, 2.8, 2.0),
				CFrame = cf * CFrame.new(torchX, 8.0, -9.2),
				Color = Color3.fromRGB(255, 165, 35),
				Material = Enum.Material.Neon,
				Parent = hModel,
			})
		end
	elseif biomeId == 4 then
		for _, stalkX in ipairs({ -6.2, 6.2 }) do
			makePart({
				Name = "BambooRoofStalk",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(9.5, 2.0, 2.0),
				CFrame = (cf * CFrame.new(stalkX, targetHeight + 1.5, 2.0)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(95, 225, 115),
				Material = Enum.Material.SmoothPlastic,
				Parent = hModel,
			})
			makePart({
				Name = "JadeLanternOrb",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(3.2, 3.2, 3.2),
				CFrame = cf * CFrame.new(stalkX, targetHeight + 6.5, 2.0),
				Color = Color3.fromRGB(145, 255, 165),
				Material = Enum.Material.Neon,
				Parent = hModel,
			})
		end
	elseif biomeId == 5 then
		for _, spireX in ipairs({ -5.5, 5.5 }) do
			makePart({
				Name = "HouseCrystalSpire",
				Size = Vector3.new(2.4, 9.5, 2.4),
				CFrame = (cf * CFrame.new(spireX, targetHeight + 1.5, 2.0)) * CFrame.Angles(math.rad(12), 0, math.rad(spireX * 2.5)),
				Color = Color3.fromRGB(95, 235, 255),
				Material = Enum.Material.Neon,
				Parent = hModel,
			})
		end
	elseif biomeId == 6 then
		makePart({
			Name = "SkyTempleHaloRing",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.2, 11.5, 11.5),
			CFrame = (cf * CFrame.new(0, targetHeight + 4.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 235, 115),
			Material = Enum.Material.Neon,
			Parent = hModel,
		})
	elseif biomeId == 7 then
		for _, hornX in ipairs({ -6.0, 6.0 }) do
			makePart({
				Name = "ObsidianRoofHorn",
				Size = Vector3.new(2.2, 8.5, 2.2),
				CFrame = (cf * CFrame.new(hornX, targetHeight + 1.2, 2.0)) * CFrame.Angles(math.rad(-16), 0, math.rad(-hornX * 3)),
				Color = Color3.fromRGB(255, 85, 25),
				Material = Enum.Material.Neon,
				Parent = hModel,
			})
		end
	elseif biomeId == 8 then
		for _, voidX in ipairs({ -5.8, 5.8 }) do
			makePart({
				Name = "VoidStarMonolith",
				Size = Vector3.new(2.4, 10.0, 2.4),
				CFrame = (cf * CFrame.new(voidX, targetHeight + 1.8, 2.0)) * CFrame.Angles(math.rad(14), 0, math.rad(voidX * 2.5)),
				Color = Color3.fromRGB(195, 75, 255),
				Material = Enum.Material.Neon,
				Parent = hModel,
			})
		end
	end

	return hModel
end

-- Builds the Giant 28-Step Rainbow Disappearing Staircase on Stage 1's dedicated Outer West Sky Plaza (X = -236)
-- ascending from Z = -20 to the Sky Cloud Sanctuary at Z = -148 (100% inside Stage 1, zero wild Squishies in Safe Zone!)
local function buildRainbowDisappearingStaircase(worldFolder: Folder)
	local stairFolder = Instance.new("Folder")
	stairFolder.Name = "RainbowDisappearingStaircase"
	stairFolder.Parent = worldFolder

	local stairCenterX = -236

	-- Connector Walkway from Stage 1's West Outer Maze (X = -210) to the Rainbow Launch Plaza (X = -236, Z = -20)
	makePart({
		Name = "RainbowPlazaConnectorBridge",
		Size = Vector3.new(38, 1.2, 22),
		Position = Vector3.new(-220, -0.4, -20),
		Color = Color3.fromRGB(255, 195, 85),
		Material = Enum.Material.SmoothPlastic,
		Parent = stairFolder,
	})

	-- Rainbow Launch Plaza pad at (X = -236, Z = -18)
	buildGlowingNeonCircle(
		stairFolder,
		"RainbowLaunchPlaza",
		Vector3.new(stairCenterX, 0.35, -18),
		20,
		Color3.fromRGB(255, 95, 195),
		Color3.fromRGB(85, 235, 255)
	)

	-- Entrance Archway at (X = -236, Z = -20)
	for _, sideX in ipairs({ stairCenterX - 6.5, stairCenterX + 6.5 }) do
		makePart({
			Name = "RainbowGatePillar",
			Size = Vector3.new(2.4, 14, 2.4),
			Position = Vector3.new(sideX, 7.0, -20),
			Color = Color3.fromRGB(255, 235, 85),
			Material = Enum.Material.Neon,
			Parent = stairFolder,
		})
	end
	local header = makePart({
		Name = "RainbowArchHeader",
		Size = Vector3.new(18, 3.8, 2.8),
		Position = Vector3.new(stairCenterX, 15.2, -20),
		Color = Color3.fromRGB(255, 85, 185),
		Material = Enum.Material.SmoothPlastic,
		Parent = stairFolder,
	})
	createSurfaceSign(
		header,
		"🌈 RAINBOW DISAPPEARING STAIRCASE\nRun Up Fast Before Steps Fade to Grab 12 Sky Squishies!",
		Color3.fromRGB(255, 245, 115),
		Color3.fromRGB(45, 18, 58),
		{ Enum.NormalId.Back, Enum.NormalId.Front },
		220
	)

	-- 28 Glowing Rainbow Steps ascending from Y=1.5, Z=-22 up to Y=50.5, Z=-148 (4.5 studs per step in Z!)
	local totalSteps = 28
	for s = 1, totalSteps do
		local hue = ((s - 1) / totalSteps) % 1.0
		local stepColor = Color3.fromHSV(hue, 0.88, 1.0)
		local yPos = 1.2 + s * 1.75
		local zPos = -22 - s * 4.5
		local xPos = stairCenterX + math.sin(s * 0.25) * 3.5

		local stepPart = makePart({
			Name = "RainbowStep_" .. tostring(s),
			Size = Vector3.new(12.0, 1.1, 3.8),
			Position = Vector3.new(xPos, yPos, zPos),
			Color = stepColor,
			Material = Enum.Material.Neon,
			Transparency = 0.08,
			Parent = stairFolder,
		})
		stepPart:SetAttribute("DisappearingStep", true)
		stepPart:SetAttribute("StepIndex", s)

		-- Safe Mid-Landing Clouds every 7 steps so players can catch their breath & grab Staircase Squishies!
		if s % 7 == 0 then
			makePart({
				Name = "RainbowCloudLanding_" .. tostring(s),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1.6, 13, 13),
				CFrame = CFrame.new(xPos, yPos - 0.2, zPos) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(245, 250, 255),
				Material = Enum.Material.SmoothPlastic,
				Parent = stairFolder,
			})
		end
	end

	-- Giant Sky Cloud Sanctuary at the top of the Rainbow Staircase (X = -236, Y = 50.5, Z = -148)
	local skyCloud = makePart({
		Name = "SkySanctuaryCloud",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.6, 26, 26),
		CFrame = CFrame.new(stairCenterX, 49.5, -148) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(245, 250, 255),
		Material = Enum.Material.SmoothPlastic,
		Parent = stairFolder,
	})
	buildGlowingNeonCircle(
		stairFolder,
		"SkySanctuaryRing",
		Vector3.new(stairCenterX, 50.9, -148),
		14,
		Color3.fromRGB(255, 95, 205),
		Color3.fromRGB(85, 235, 255)
	)
	createBillboardText(
		skyCloud,
		"☁️ RAINBOW SKY SANCTUARY\nGrab the Mythic Rainbow Staircase Sovereign!",
		Color3.fromRGB(255, 225, 85),
		Vector3.new(0, 8.5, 0),
		UDim2.new(9.5, 0, 2.1, 0),
		65
	)
end

-- Builds Biome-Themed Crenellated Castle Wall Battlements along both sides of the expanded map (X = ±146)
-- Plus Overhead Biome Sky Archways & Rib Vaults so every stage has an unmistakable skyline silhouette!
local function buildCastleWallBattlements(parent: Instance, levelInfo: any, halfW: number)
	local id = levelInfo.Id or levelInfo.Level or 1
	local zStart = levelInfo.ZStart
	local zEnd = levelInfo.ZEnd
	local zMid = (zStart + zEnd) * 0.5
	local length = math.abs(zStart - zEnd)
	local themeColor = levelInfo.ThemeColor or Color3.fromRGB(120, 210, 120)

	-- Distinct Wall Palette & Material per Stage across all 8 Stages!
	local stoneColor = if id == 1 then Color3.fromRGB(158, 178, 138)
		elseif id == 2 then Color3.fromRGB(142, 78, 52)
		elseif id == 3 then Color3.fromRGB(232, 204, 148)
		elseif id == 4 then Color3.fromRGB(78, 148, 92)
		elseif id == 5 then Color3.fromRGB(64, 46, 108)
		elseif id == 6 then Color3.fromRGB(235, 242, 255)
		elseif id == 7 then Color3.fromRGB(42, 34, 40)
		else Color3.fromRGB(28, 18, 48)

	local trimStone = if id == 1 then Color3.fromRGB(112, 148, 92)
		elseif id == 2 then Color3.fromRGB(255, 135, 198)
		elseif id == 3 then Color3.fromRGB(55, 205, 230)
		elseif id == 4 then Color3.fromRGB(125, 235, 145)
		elseif id == 5 then Color3.fromRGB(135, 75, 255)
		elseif id == 6 then Color3.fromRGB(255, 225, 105)
		elseif id == 7 then Color3.fromRGB(255, 82, 24)
		else Color3.fromRGB(215, 65, 255)

	local wallMat = if id == 1 then Enum.Material.Cobblestone
		elseif id == 2 then Enum.Material.Brick
		elseif id == 3 then Enum.Material.Sandstone
		elseif id == 4 then Enum.Material.Slate
		elseif id == 5 then Enum.Material.Slate
		elseif id == 6 then Enum.Material.Marble
		elseif id == 7 then Enum.Material.Basalt
		else Enum.Material.Basalt

	local castleFolder = Instance.new("Folder")
	castleFolder.Name = "CastleWallBattlements_" .. tostring(id)
	castleFolder.Parent = parent

	for _, side in ipairs({ -1, 1 }) do
		local wallX = side * (halfW - 2.0) -- X = ±146

		-- Lower & Upper Castle Wall Sections with an 18-stud doorway opening at zMid into the Outer Maze!
		local segLen = (length - 18) * 0.5
		for _, zSegCenter in ipairs({ zStart - segLen * 0.5, zEnd + segLen * 0.5 }) do
			makePart({
				Name = "CastleWallBase",
				Size = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, segLen),
				Position = Vector3.new(wallX, WALL_HEIGHT * 0.5, zSegCenter),
				Color = stoneColor,
				Material = wallMat,
				Parent = castleFolder,
			})
		end

		-- Continuous Walkable Castle Rampart Walkway along the top (Y = 18)
		makePart({
			Name = "CastleRampartWalkway",
			Size = Vector3.new(WALL_THICKNESS + 3.0, 1.2, length),
			Position = Vector3.new(wallX, WALL_HEIGHT + 0.4, zMid),
			Color = trimStone,
			Material = wallMat,
			Parent = castleFolder,
		})

		-- Crenellated Castle Battlement Merlons along the top edge
		for zMerlon = zStart - 6, zEnd + 6, -12 do
			makePart({
				Name = "CastleMerlon",
				Size = Vector3.new(1.8, 3.6, 5.2),
				Position = Vector3.new(wallX - side * 2.4, WALL_HEIGHT + 2.6, zMerlon),
				Color = if (math.abs(zMerlon) % 24 == 0) then trimStone else stoneColor,
				Material = if id >= 5 and (math.abs(zMerlon) % 24 == 0) then Enum.Material.Neon else wallMat,
				Parent = castleFolder,
			})
		end

		-- Biome-Themed Watchtower Turrets at BOTH North (zStart - 12) and South (zEnd + 14) corners of each stage!
		for _, towerZ in ipairs({ zStart - 12, zEnd + 14 }) do
			local towerPos = Vector3.new(wallX, 0, towerZ)
			makePart({
				Name = "CastleWatchtower",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(24, 12.0, 12.0),
				CFrame = CFrame.new(towerPos + Vector3.new(0, 12.0, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = stoneColor,
				Material = wallMat,
				Parent = castleFolder,
			})
			makePart({
				Name = "WatchtowerRoofRim",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(2.2, 14.2, 14.2),
				CFrame = CFrame.new(towerPos + Vector3.new(0, 23.8, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Color = trimStone,
				Material = if id >= 5 then Enum.Material.Neon else Enum.Material.SmoothPlastic,
				Parent = castleFolder,
			})
			makePart({
				Name = "WatchtowerSpire",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(10, 11, 10),
				Position = towerPos + Vector3.new(0, 27.5, 0),
				Color = themeColor,
				Material = if id >= 5 then Enum.Material.Neon else Enum.Material.SmoothPlastic,
				Parent = castleFolder,
			})
		end

		-- Stone Climbing Stairs from the Biome Floor up to the Castle Wall Rampart (placed at zStart - 120)
		for step = 1, 9 do
			makePart({
				Name = "CastleClimbStep_" .. tostring(step),
				Size = Vector3.new(4.8, 1.2, 3.6),
				Position = Vector3.new(wallX - side * 5.2, step * 2.0, (zStart - 116) - step * 3.2),
				Color = themeColor:Lerp(Color3.fromRGB(240, 240, 245), 0.35),
				Material = wallMat,
				Parent = castleFolder,
			})
		end
	end

	-- Dramatic Overhead Biome Skyline Rib Archways spanning across the stage at zStart - 52 and zStart - 106!
	for archIdx, archZ in ipairs({ zStart - 52, zStart - 106 }) do
		for _, side in ipairs({ -1, 1 }) do
			-- Angled Lower Arch Rib rising from the Castle Wall toward the sky
			makePart({
				Name = string.format("SkylineArchLower_%d_%d", id, archIdx),
				Size = Vector3.new(3.6, 36, 3.6),
				CFrame = CFrame.new(side * (halfW - 24), 31, archZ) * CFrame.Angles(0, 0, math.rad(side * 34)),
				Color = if archIdx % 2 == 1 then themeColor else trimStone,
				Material = if id >= 5 then Enum.Material.Neon else wallMat,
				CanCollide = false,
				Parent = castleFolder,
			})
		end
		-- High Overhead Crown Beam / Skyline Banner at Y = 45
		if id >= 2 then
			makePart({
				Name = string.format("SkylineCrownArch_%d_%d", id, archIdx),
				Size = Vector3.new(halfW * 2 - 64, 2.8, 2.8),
				Position = Vector3.new(0, 44, archZ),
				Color = trimStone,
				Material = if id >= 5 then Enum.Material.Neon else Enum.Material.SmoothPlastic,
				CanCollide = false,
				Parent = castleFolder,
			})
		end
	end
end

-- Builds the Flanking Outer Mazes cleanly outside the Castle Walls on Left (X = -154..-210) and Right (X = +154..+210)!
local function buildOuterSideMazes(parent: Instance, levelInfo: any, halfW: number)
	local id = levelInfo.Id or levelInfo.Level or 1
	local zStart = levelInfo.ZStart
	local zEnd = levelInfo.ZEnd
	local zMid = (zStart + zEnd) * 0.5
	local length = math.abs(zStart - zEnd)
	local themeColor = levelInfo.ThemeColor or Color3.fromRGB(95, 215, 110)

	local mazeWallColor = if id == 1 then Color3.fromRGB(58, 168, 68)
		elseif id == 2 then Color3.fromRGB(235, 95, 165)
		elseif id == 3 then Color3.fromRGB(168, 125, 65)
		elseif id == 4 then Color3.fromRGB(75, 185, 95)
		elseif id == 5 then Color3.fromRGB(85, 195, 245)
		elseif id == 6 then Color3.fromRGB(155, 215, 255)
		elseif id == 7 then Color3.fromRGB(72, 48, 58)
		else Color3.fromRGB(115, 45, 175)

	local mazeMat = if id == 1 then Enum.Material.Grass
		elseif id == 2 then Enum.Material.SmoothPlastic
		elseif id == 3 then Enum.Material.WoodPlanks
		elseif id == 4 then Enum.Material.WoodPlanks
		elseif id == 5 then Enum.Material.Slate
		elseif id == 6 then Enum.Material.Marble
		elseif id == 7 then Enum.Material.Basalt
		else Enum.Material.Basalt

	local mazeFolder = Instance.new("Folder")
	mazeFolder.Name = "OuterSideMazes_" .. tostring(id)
	mazeFolder.Parent = parent

	local mazeInnerX = halfW + 6 -- 154 (6 studs outside halfW=148 so Watchtowers at ±146 never touch the maze!)
	local mazeOuterX = mazeInnerX + OUTER_MAZE_WIDTH -- 210
	local mazeCenterX = (mazeInnerX + mazeOuterX) * 0.5 -- 182

	for _, side in ipairs({ -1, 1 }) do
		-- Outer Maze Floor (including connector bridge across the 6-stud gap from the Castle Wall gate!)
		makePart({
			Name = "OuterMazeFloor",
			Size = Vector3.new(OUTER_MAZE_WIDTH + 8, 2, length),
			Position = Vector3.new(side * (mazeCenterX - 3), -1, zMid),
			Color = levelInfo.FloorColor:Lerp(Color3.fromRGB(45, 55, 45), 0.15),
			Material = levelInfo.FloorMaterial or Enum.Material.SmoothPlastic,
			Parent = mazeFolder,
		})

		-- Outer Perimeter Boundary Wall at X = ±210 (leaves doorway opening on West of Stage 1 at Z = -20 for Rainbow Staircase!)
		makePart({
			Name = "OuterMazeBoundaryWall",
			Size = Vector3.new(3.5, 14, length),
			Position = Vector3.new(side * mazeOuterX, 7, zMid),
			Color = mazeWallColor,
			Material = mazeMat,
			CanCollide = not (id == 1 and side == -1),
			Transparency = if (id == 1 and side == -1) then 0.65 else 0,
			Parent = mazeFolder,
		})

		-- Entrance Archway Sign at zMid (X = ±154)
		local archHeader = makePart({
			Name = "MazeArchHeader",
			Size = Vector3.new(3.2, 4.0, 18),
			Position = Vector3.new(side * mazeInnerX, 14.8, zMid),
			Color = themeColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = mazeFolder,
		})
		createSurfaceSign(
			archHeader,
			string.format("🌿 STAGE %d OUTER MAZE\nFind Hidden Shining Squishies Inside!", id),
			Color3.fromRGB(255, 245, 130),
			Color3.fromRGB(20, 34, 26),
			{ Enum.NormalId.Left, Enum.NormalId.Right },
			180
		)

		-- Winding Interior Labyrinth Corridors & Baffles (leaves wide 22-stud lanes at X = ±168 and X = ±194!)
		local wallH = 10.5
		-- Center Spine Divider at X = ±181 with Alternating Gaps
		for seg = 1, 3 do
			local zSeg = zStart - (seg * 40) + 6
			makePart({
				Name = "MazeSpine_" .. tostring(seg),
				Size = Vector3.new(2.8, wallH, 24),
				Position = Vector3.new(side * (mazeCenterX - 1), wallH * 0.5, zSeg),
				Color = mazeWallColor,
				Material = mazeMat,
				Parent = mazeFolder,
			})
		end

		-- Transverse Maze Baffles spaced cleanly between the Squishy positions (zStart - 26, -60, -94, -128)
		local baffleOffsets = {
			{ X = mazeCenterX - 16, Z = zStart - 43 },
			{ X = mazeCenterX + 12, Z = zStart - 77 },
			{ X = mazeCenterX - 16, Z = zStart - 111 },
			{ X = mazeCenterX + 12, Z = zStart - 144 },
		}
		for bIdx, b in ipairs(baffleOffsets) do
			makePart({
				Name = "MazeBaffle_" .. tostring(bIdx),
				Size = Vector3.new(20, wallH, 2.8),
				Position = Vector3.new(side * b.X, wallH * 0.5, b.Z),
				Color = mazeWallColor:Lerp(themeColor, 0.25),
				Material = mazeMat,
				Parent = mazeFolder,
			})
		end
	end
end

-- Builds the Authentic Creator Store 3D Speed Treadmill (Assets 85105314510723, 105125399134543, 135041830463035, 98972491411819)
-- Includes:
--   1. Creator Store 3D Treadmill Hood/Console Mesh (`rbxassetid://9507455017`, `10256224170`, `2682037588`, `15108756532`)
--   2. Hybrid AFK + Interactive Belt (Zero pushback so players stay centered & run AFK hands-free OR tap for 2x Turbo Speed!)
--   3. Scrolling `Beam` Belt Arrows (`rbxassetid://6798365555`, `123374008022599`, `4887782888`)
--   4. Speed Aura `ParticleEmitter` (`rbxassetid://9129151031`, `7451822955`)
--   5. Overhead `[x1 SPEED]` -> `[x50M SPEED]` Display Sign (`formatSpeed(speedPerSec)`)
local function buildDinoJawTreadmill(
	parent: Instance,
	treadCenter: Vector3,
	faceDir: number,
	plotIdx: number,
	stageTierOverride: number?
): Part
	local tierId = math.clamp(stageTierOverride or 1, 1, 8)
	local tier = SlimeData.TreadmillTiers[tierId] or SlimeData.TreadmillTiers[1]
	local isStageTreadmill = stageTierOverride ~= nil

	local tmModel = Instance.new("Model")
	tmModel.Name = if isStageTreadmill
		then ("StageTreadmill_" .. tostring(tierId))
		else ("DinoTreadmill_" .. tostring(plotIdx))
	tmModel.Parent = parent

	-- Heavy Steel & Neon Treadmill Base Deck
	makePart({
		Name = "TreadmillBase",
		Size = Vector3.new(12.8, 1.2, 16.8),
		Position = treadCenter + Vector3.new(0, 0.6, 0),
		Color = Color3.fromRGB(34, 38, 52),
		Material = Enum.Material.Metal,
		Parent = tmModel,
	})

	-- Glowing Tier-Colored Side Handrails
	for _, railZ in ipairs({ -7.4, 7.4 }) do
		makePart({
			Name = "SideRail",
			Size = Vector3.new(12.8, 2.2, 1.4),
			Position = treadCenter + Vector3.new(0, 1.4, railZ),
			Color = tier.PrimaryColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = tmModel,
		})
		makePart({
			Name = "SideRailNeonTrim",
			Size = Vector3.new(12.4, 0.45, 1.55),
			Position = treadCenter + Vector3.new(0, 2.35, railZ),
			Color = tier.AccentColor,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = tmModel,
		})
	end

	-- Active AFK + Interactive Treadmill Belt Part (`TreadmillBelt_<id>`)
	local beltName = if isStageTreadmill
		then ("TreadmillBelt_Stage_" .. tostring(tierId))
		else ("TreadmillBelt_" .. tostring(plotIdx))

	local belt = makePart({
		Name = beltName,
		Size = Vector3.new(11.6, 1.38, 13.2),
		Position = treadCenter + Vector3.new(0, 0.84, 0),
		Color = Color3.fromRGB(28, 30, 42),
		Material = Enum.Material.SmoothPlastic,
		CanTouch = true,
		Parent = parent,
	})
	belt:SetAttribute("IsCreatorStoreTreadmill", true)
	belt:SetAttribute("TreadmillTier", tierId)
	belt:SetAttribute("SpeedPerSec", tier.SpeedPerSec)
	belt:SetAttribute("MultiplierText", tier.MultiplierText)
	belt:SetAttribute("RunAnimSpeed", math.clamp(1.25 + (tierId * 0.12), 1.3, 2.25))
	belt:SetAttribute("FaceDir", faceDir)
	if not isStageTreadmill then
		belt:SetAttribute("PlotIndex", plotIdx)
	else
		belt:SetAttribute("StageId", tierId)
	end

	-- AFK-Friendly Zero Conveyor Pushback (players stay centered & run in place hands-free OR tap for 2x Turbo!)
	belt.AssemblyLinearVelocity = Vector3.zero

	-- Authentic Creator Store Scrolling `Beam` Belt Texture (`rbxassetid://6798365555`, `123374008022599`, `4887782888`)
	local att0 = Instance.new("Attachment")
	att0.Name = "BeltScrollAtt0"
	att0.Position = Vector3.new(-faceDir * 5.6, 0.72, 0)
	att0.Orientation = Vector3.new(0, 0, 90)
	att0.Parent = belt

	local att1 = Instance.new("Attachment")
	att1.Name = "BeltScrollAtt1"
	att1.Position = Vector3.new(faceDir * 5.6, 0.72, 0)
	att1.Orientation = Vector3.new(0, 0, 90)
	att1.Parent = belt

	local scrollBeam = Instance.new("Beam")
	scrollBeam.Name = "TreadmillScrollBeam"
	scrollBeam.Attachment0 = att0
	scrollBeam.Attachment1 = att1
	scrollBeam.Texture = tier.BeamTexture or "rbxassetid://6798365555"
	scrollBeam.TextureSpeed = tier.TextureSpeed or 2.4
	scrollBeam.TextureLength = 3.6
	scrollBeam.TextureMode = Enum.TextureMode.Wrap
	scrollBeam.Width0 = 11.8
	scrollBeam.Width1 = 11.8
	scrollBeam.FaceCamera = false
	scrollBeam.LightEmission = 0.85
	scrollBeam.LightInfluence = 0
	scrollBeam.Color = ColorSequence.new(tier.PrimaryColor, tier.AccentColor)
	scrollBeam.Transparency = NumberSequence.new(0.08)
	scrollBeam.Parent = belt

	-- Neon Belt Chevron Strips underneath the scrolling Beam for crisp visibility from any camera angle
	for s = -4, 4, 2 do
		makePart({
			Name = "BeltArrow",
			Size = Vector3.new(0.85, 1.42, 10.8),
			Position = treadCenter + Vector3.new(s * 1.1, 0.86, 0),
			Color = tier.AccentColor,
			Material = Enum.Material.Neon,
			Transparency = 0.25,
			CanCollide = false,
			Parent = tmModel,
		})
	end

	-- Authentic Creator Store Speed Aura `ParticleEmitter` (`rbxassetid://9129151031` / `7451822955`)
	local auraEmitter = Instance.new("ParticleEmitter")
	auraEmitter.Name = "TreadmillAuraEmitter"
	auraEmitter.Texture = tier.ParticleTexture or "rbxassetid://9129151031"
	auraEmitter.Color = ColorSequence.new(tier.PrimaryColor, tier.AccentColor)
	auraEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.6),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	auraEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	auraEmitter.Lifetime = NumberRange.new(0.55, 1.1)
	auraEmitter.Rate = 12
	auraEmitter.Speed = NumberRange.new(4, 9)
	auraEmitter.SpreadAngle = Vector2.new(35, 35)
	auraEmitter.LightEmission = 0.85
	auraEmitter.Parent = belt

	-- Authentic Creator Store 3D Treadmill Hood/Console Mesh (`PreserveCreatorStoreMesh = true`)
	local consoleMeshPart = makePart({
		Name = "CreatorStoreTreadmillMesh",
		Size = Vector3.new(4.2, 6.5, 10.5),
		Position = treadCenter + Vector3.new(-faceDir * 4.6, 4.2, 0),
		Color = tier.PrimaryColor,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = tmModel,
	})
	local sm = Instance.new("SpecialMesh")
	sm.Name = "CreatorStoreMesh"
	sm.MeshType = Enum.MeshType.FileMesh
	sm.MeshId = tier.MeshId or "rbxassetid://9507455017"
	sm.TextureId = tier.TextureId or "rbxassetid://9507455143"
	sm.Scale = Vector3.new(1.35, 1.35, 1.35)
	sm:SetAttribute("PreserveCreatorStoreMesh", true)
	sm.Parent = consoleMeshPart

	-- Sculpted Arch Frame & Overhead Multiplier Display Sign (`[x1 SPEED]` -> `[x50M SPEED]`)
	for _, sideZ in ipairs({ -6.4, 6.4 }) do
		makePart({
			Name = "TreadmillArchPillar",
			Size = Vector3.new(4.8, 12.5, 2.2),
			Position = treadCenter + Vector3.new(-faceDir * 2.8, 6.25, sideZ),
			Color = tier.PrimaryColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = tmModel,
		})
	end

	local snout = makePart({
		Name = "TreadmillHeaderArch",
		Size = Vector3.new(8.8, 4.6, 15.2),
		Position = treadCenter + Vector3.new(-faceDir * 1.6, 13.6, 0),
		Color = tier.PrimaryColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = tmModel,
	})
	makePart({
		Name = "TreadmillCrest",
		Size = Vector3.new(6.2, 2.2, 12.2),
		Position = treadCenter + Vector3.new(-faceDir * 2.4, 16.5, 0),
		Color = tier.AccentColor,
		Material = Enum.Material.Neon,
		Parent = tmModel,
	})

	local speedFormatted = SlimeData.FormatNumber(tier.SpeedPerSec)
	local signLabelText = if isStageTreadmill
		then string.format("⚡ STAGE %d %s [%s]\n🏃 Run Here = +%s Speed / Sec!", tierId, string.upper(tier.Name), tier.MultiplierText, speedFormatted)
		else string.format("⚡ BASE %s [%s]\n🏃 Run Here = +%s Speed / Sec!", string.upper(tier.Name), tier.MultiplierText, speedFormatted)

	local bb = createBillboardText(
		snout,
		signLabelText,
		tier.AccentColor,
		Vector3.new(0, 4.8, 0),
		UDim2.new(7.5, 0, 1.8, 0),
		65
	)
	bb.Name = "TreadmillBillboard"

	return belt
end

-- Chapter 4 Procedural Model Generator #1: Parameterized Picket Fence (automatically calculates picket count & spacing!)
local function buildProceduralPicketFence(
	parent: Instance,
	startPos: Vector3,
	endPos: Vector3,
	height: number,
	railColor: Color3,
	picketColor: Color3
)
	local fenceGroup = Instance.new("Folder")
	fenceGroup.Name = "ProceduralPicketFence"
	fenceGroup.Parent = parent

	local delta = endPos - startPos
	local dist = delta.Magnitude
	if dist < 1 then
		return
	end
	local mid = (startPos + endPos) * 0.5
	local railCF = CFrame.lookAt(mid, endPos)

	-- Top and Bottom Horizontal Rails
	for _, yRatio in ipairs({ 0.35, 0.78 }) do
		makePart({
			Name = "FenceRail",
			Size = Vector3.new(0.45, 0.42, dist),
			CFrame = railCF + Vector3.new(0, height * yRatio, 0),
			Color = railColor,
			Material = Enum.Material.WoodPlanks,
			Parent = fenceGroup,
		})
	end

	-- Automatically spaced Vertical Pickets (every 3.5 studs, zero clipping!)
	local numPickets = math.max(2, math.floor(dist / 3.5))
	for i = 0, numPickets do
		local alpha = i / numPickets
		local pPos = startPos:Lerp(endPos, alpha)
		makePart({
			Name = "FencePicket_" .. tostring(i),
			Size = Vector3.new(0.75, height, 0.75),
			Position = pPos + Vector3.new(0, height * 0.5, 0),
			Color = picketColor,
			Material = Enum.Material.WoodPlanks,
			Parent = fenceGroup,
		})
	end
end

-- Chapter 4 Procedural Model Generator #2: Parameterized Plank Bridge across Hazard Moats
local function buildProceduralPlankBridge(
	parent: Instance,
	centerPos: Vector3,
	width: number,
	length: number,
	plankColor: Color3,
	railColor: Color3
)
	local bridgeModel = Instance.new("Model")
	bridgeModel.Name = "ProceduralPlankBridge"
	bridgeModel.Parent = parent

	-- Support stringers
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "BridgeStringer",
			Size = Vector3.new(1.1, 1.0, length),
			Position = centerPos + Vector3.new(side * (width * 0.44), 0.7, 0),
			Color = railColor,
			Material = Enum.Material.WoodPlanks,
			Parent = bridgeModel,
		})
		makePart({
			Name = "BridgeHandrail",
			Size = Vector3.new(0.65, 0.65, length),
			Position = centerPos + Vector3.new(side * (width * 0.46), 3.4, 0),
			Color = railColor,
			Material = Enum.Material.WoodPlanks,
			Parent = bridgeModel,
		})
	end

	-- Automatically spaced cross-planks based on bridge length
	local numPlanks = math.max(5, math.floor(length / 2.2))
	local plankDepth = (length / numPlanks) * 0.84
	for i = 1, numPlanks do
		local zOff = -length * 0.5 + (i - 0.5) * (length / numPlanks)
		makePart({
			Name = "BridgePlank_" .. tostring(i),
			Size = Vector3.new(width, 0.6, plankDepth),
			Position = centerPos + Vector3.new(0, 1.35, zOff),
			Color = if i % 2 == 0 then plankColor else plankColor:Lerp(Color3.fromRGB(255, 235, 200), 0.14),
			Material = Enum.Material.WoodPlanks,
			Parent = bridgeModel,
		})
	end
end

-- Helper: Creates an Attachment-parented ProximityPrompt (Chapter 2 & 4 Best Practice: Exclusivity = OnePerButton)
local function createAttachmentPrompt(
	part: BasePart,
	name: string,
	actionText: string,
	objectText: string,
	offset: Vector3,
	maxDist: number?
): ProximityPrompt
	local att = Instance.new("Attachment")
	att.Name = name .. "_Attachment"
	att.Position = offset
	att.Parent = part

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = maxDist or 14
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.Parent = att
	return prompt
end

-- Builds the 3 Physical 3D Global OrderedDataStore Leaderboards + Spin Wheel, Daily Chest & VIP Robux Shop Booths on the Dedicated Outer East Hub Plaza (X = +162..+192)!
local function buildHubRetentionBoothsAndLeaderboards(hubFolder: Folder, obstaclesFolder: Folder)
	-- East-West Cross-Boulevard connecting the Central Path to the East Champions & Rewards Plaza
	makePart({
		Name = "EastRewardsPlazaPath",
		Size = Vector3.new(188, 0.25, 22),
		Position = Vector3.new(94, 0.12, 92),
		Color = Color3.fromRGB(228, 214, 185),
		Material = Enum.Material.Cobblestone,
		Parent = hubFolder,
	})
	makePart({
		Name = "EastRewardsPlazaPad",
		Size = Vector3.new(54, 0.25, 128),
		Position = Vector3.new(176, 0.12, 92),
		Color = Color3.fromRGB(228, 214, 185),
		Material = Enum.Material.Cobblestone,
		Parent = hubFolder,
	})

	-- 1. 3 Physical 3D Global OrderedDataStore Leaderboard Monuments on the Safe Zone Plaza (X = 192, Z = 52, 92, 132)
	local lbFolder = Instance.new("Folder")
	lbFolder.Name = "GlobalLeaderboards"
	lbFolder.Parent = hubFolder

	local lbConfigs = {
		{ Name = "CoinsBoard", StatKey = "Coins", Title = "💰 RICHEST PLAYERS (TOP 10)", Color = Color3.fromRGB(255, 205, 55), Z = 52 },
		{ Name = "SpeedBoard", StatKey = "Speed", Title = "⚡ FASTEST SPEED (TOP 10)", Color = Color3.fromRGB(65, 220, 255), Z = 92 },
		{ Name = "SquishiesBoard", StatKey = "Squishies", Title = "✨ MOST SQUISHIES (0/117)", Color = Color3.fromRGB(255, 115, 215), Z = 132 },
	}

	for _, cfg in ipairs(lbConfigs) do
		local boardModel = Instance.new("Model")
		boardModel.Name = cfg.Name
		boardModel:SetAttribute("StatKey", cfg.StatKey)
		boardModel.Parent = lbFolder

		makePart({
			Name = "MonumentStepBase",
			Size = Vector3.new(6.8, 1.0, 19.5),
			Position = Vector3.new(192, 0.5, cfg.Z),
			Color = Color3.fromRGB(72, 78, 98),
			Material = Enum.Material.Plastic,
			Parent = boardModel,
		})

		makePart({
			Name = "BoardPedestal",
			Size = Vector3.new(4.8, 1.6, 17.2),
			Position = Vector3.new(192, 1.5, cfg.Z),
			Color = Color3.fromRGB(52, 58, 78),
			Material = Enum.Material.Plastic,
			Parent = boardModel,
		})

		-- Twin Flanking Monument Columns
		for _, sideZ in ipairs({ -7.8, 7.8 }) do
			makePart({
				Name = "MonumentPillar",
				Size = Vector3.new(2.2, 16.5, 2.2),
				Position = Vector3.new(192, 9.6, cfg.Z + sideZ),
				Color = Color3.fromRGB(235, 238, 248),
				Material = Enum.Material.Plastic,
				Parent = boardModel,
			})
			makePart({
				Name = "MonumentPillarCap",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(2.8, 2.8, 2.8),
				Position = Vector3.new(192, 18.8, cfg.Z + sideZ),
				Color = cfg.Color,
				Material = Enum.Material.Neon,
				Parent = boardModel,
			})
		end

		local boardPart = makePart({
			Name = "BoardSurface",
			Size = Vector3.new(1.4, 15.5, 14.5),
			Position = Vector3.new(192, 9.6, cfg.Z),
			Color = Color3.fromRGB(22, 26, 44),
			Material = Enum.Material.SmoothPlastic,
			Parent = boardModel,
		})
		boardModel.PrimaryPart = boardPart

		makePart({
			Name = "BoardTopCrest",
			Size = Vector3.new(2.4, 1.8, 17.6),
			Position = Vector3.new(192, 18.0, cfg.Z),
			Color = cfg.Color,
			Material = Enum.Material.Neon,
			Parent = boardModel,
		})

		makePart({
			Name = "MonumentCrownOrb",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(3.6, 3.6, 3.6),
			Position = Vector3.new(192, 20.4, cfg.Z),
			Color = Color3.fromRGB(255, 225, 75),
			Material = Enum.Material.Neon,
			Parent = boardModel,
		})

		for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
			local sg = Instance.new("SurfaceGui")
			sg.Name = "LeaderboardGui_" .. face.Name
			sg.Face = face
			sg.AlwaysOnTop = false
			sg.LightInfluence = 0
			sg.Brightness = 1.6
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			sg.PixelsPerStud = 36
			sg.MaxDistance = 180
			sg.Parent = boardPart

			local bg = Instance.new("Frame")
			bg.Name = "Container"
			bg.Size = UDim2.fromScale(0.94, 0.94)
			bg.Position = UDim2.fromScale(0.5, 0.5)
			bg.AnchorPoint = Vector2.new(0.5, 0.5)
			bg.BackgroundColor3 = Color3.fromRGB(18, 22, 38)
			bg.BorderSizePixel = 0
			bg.Parent = sg

			local stroke = Instance.new("UIStroke")
			stroke.Color = cfg.Color
			stroke.Thickness = 4
			stroke.Parent = bg

			local header = Instance.new("TextLabel")
			header.Name = "Header"
			header.Size = UDim2.fromScale(1, 0.14)
			header.BackgroundColor3 = cfg.Color
			header.Font = Enum.Font.FredokaOne
			header.TextScaled = true
			header.TextColor3 = Color3.fromRGB(16, 20, 32)
			header.Text = cfg.Title
			header.Parent = bg

			local rowsFrame = Instance.new("Frame")
			rowsFrame.Name = "Rows"
			rowsFrame.Size = UDim2.fromScale(0.94, 0.82)
			rowsFrame.Position = UDim2.fromScale(0.03, 0.16)
			rowsFrame.BackgroundTransparency = 1
			rowsFrame.Parent = bg

			local listLayout = Instance.new("UIListLayout")
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder
			listLayout.Padding = UDim.new(0.012, 0)
			listLayout.Parent = rowsFrame

			local defaultRanks = {
				{ Name = "SquishyKing99", Coins = "$48,500", Speed = "⚡ 145 Spd", Squishies = "✨ 114 / 117" },
				{ Name = "RainbowRunner", Coins = "$32,400", Speed = "⚡ 128 Spd", Squishies = "✨ 98 / 117" },
				{ Name = "DinoTreadmillPro", Coins = "$24,900", Speed = "⚡ 112 Spd", Squishies = "✨ 86 / 117" },
				{ Name = "CandyThiefX", Coins = "$18,200", Speed = "⚡ 96 Spd", Squishies = "✨ 74 / 117" },
				{ Name = "VolcanoLegend", Coins = "$12,600", Speed = "⚡ 84 Spd", Squishies = "✨ 62 / 117" },
				{ Name = "TikiExplorer", Coins = "$8,400", Speed = "⚡ 68 Spd", Squishies = "✨ 49 / 117" },
				{ Name = "CrystalHunter", Coins = "$5,200", Speed = "⚡ 52 Spd", Squishies = "✨ 35 / 117" },
				{ Name = "MeadowScout", Coins = "$2,400", Speed = "⚡ 36 Spd", Squishies = "✨ 22 / 117" },
				{ Name = "RookieHatch", Coins = "$950", Speed = "⚡ 24 Spd", Squishies = "✨ 11 / 117" },
				{ Name = "⭐ You", Coins = "$100", Speed = "⚡ 18 Spd", Squishies = "✨ 0 / 117" },
			}
			for rank = 1, 10 do
				local row = Instance.new("TextLabel")
				row.Name = "Rank_" .. tostring(rank)
				row.LayoutOrder = rank
				row.Size = UDim2.fromScale(1, 0.086)
				row.BackgroundColor3 = if rank == 1
					then Color3.fromRGB(85, 68, 22)
					elseif rank <= 3 then Color3.fromRGB(36, 44, 72)
					else Color3.fromRGB(26, 32, 52)
				row.BorderSizePixel = 0
				row.Font = Enum.Font.FredokaOne
				row.TextScaled = true
				row.TextColor3 = if rank == 1 then Color3.fromRGB(255, 235, 95) else Color3.fromRGB(235, 242, 255)
				local rInfo = defaultRanks[rank]
				local valStr = if cfg.StatKey == "Coins"
					then rInfo.Coins
					elseif cfg.StatKey == "Speed" then rInfo.Speed
					else rInfo.Squishies
				row.Text = string.format("#%d  %s  —  %s", rank, rInfo.Name, valStr)
				row.Parent = rowsFrame
			end
		end
	end

	-- 2. 🎡 Lucky Squishy Spin Wheel Booth (Outer East Plaza North at X = 162, Z = 52)
	local spinBooth = Instance.new("Model")
	spinBooth.Name = "LuckySpinWheelBooth"
	spinBooth.Parent = hubFolder

	local spinPad = buildGlowingNeonCircle(
		spinBooth,
		"SpinWheelPad",
		Vector3.new(162, 0.35, 52),
		13,
		Color3.fromRGB(255, 95, 205),
		Color3.fromRGB(255, 235, 75)
	)
	spinBooth.PrimaryPart = spinPad

	makePart({
		Name = "WheelStandPost",
		Size = Vector3.new(2.6, 12.0, 2.6),
		Position = Vector3.new(164.5, 6.0, 52),
		Color = Color3.fromRGB(255, 215, 65),
		Material = Enum.Material.Plastic,
		Parent = spinBooth,
	})

	-- Studded Canopy Roof over Spin Wheel Booth
	makePart({
		Name = "SpinCanopyRoof",
		Size = Vector3.new(9.5, 1.4, 14.5),
		Position = Vector3.new(162.5, 15.2, 52),
		Color = Color3.fromRGB(255, 85, 195),
		Material = Enum.Material.Plastic,
		Parent = spinBooth,
	})

	-- Rotating 3D Prize Wheel Disk in DynamicObstacles so it spins smoothly!
	local wheelDisk = makePart({
		Name = "SpinWheelDisk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.4, 11.2, 11.2),
		CFrame = CFrame.new(163.2, 10.2, 52),
		Color = Color3.fromRGB(255, 85, 195),
		Material = Enum.Material.Neon,
		Parent = obstaclesFolder,
	})
	wheelDisk:SetAttribute("SpinWheelRotor", true)
	wheelDisk:SetAttribute("SpinSpeed", 1.35)

	local wheelHeader = makePart({
		Name = "SpinWheelSign",
		Size = Vector3.new(1.2, 3.4, 13.5),
		Position = Vector3.new(162.5, 17.6, 52),
		Color = Color3.fromRGB(255, 95, 205),
		Material = Enum.Material.SmoothPlastic,
		Parent = spinBooth,
	})
	createSurfaceSign(
		wheelHeader,
		"🎡 LUCKY SQUISHY SPIN WHEEL!\n1 Free Spin Every 5m • Buy Spins • Mythic Multipliers!",
		Color3.fromRGB(255, 245, 110),
		Color3.fromRGB(42, 18, 56),
		{ Enum.NormalId.Left, Enum.NormalId.Right },
		160
	)
	createAttachmentPrompt(spinPad, "SpinWheelPrompt", "Spin Lucky Wheel! (Free Every 5m)", "🎡 Lucky Squishy Spin Wheel", Vector3.new(0, 3.2, 0), 16)

	-- 3. 🎁 Daily Login Streak & Playtime Rewards Chest Shrine (Outer East Plaza Center at X = 162, Z = 92)
	local chestBooth = Instance.new("Model")
	chestBooth.Name = "DailyRewardChestBooth"
	chestBooth.Parent = hubFolder

	local chestPad = buildGlowingNeonCircle(
		chestBooth,
		"DailyChestPad",
		Vector3.new(162, 0.35, 92),
		13,
		Color3.fromRGB(255, 205, 55),
		Color3.fromRGB(85, 245, 130)
	)
	chestBooth.PrimaryPart = chestPad

	placePrebuiltAsset("CashChest", 1, chestBooth, Vector3.new(162, 0.8, 92), -90, 6.2, true)

	-- Twin Studded Golden Shrine Pillars
	for _, zSide in ipairs({ -5.2, 5.2 }) do
		makePart({
			Name = "ChestShrinePillar",
			Size = Vector3.new(2.0, 9.2, 2.0),
			Position = Vector3.new(164.2, 4.6, 92 + zSide),
			Color = Color3.fromRGB(255, 205, 55),
			Material = Enum.Material.Plastic,
			Parent = chestBooth,
		})
	end

	local chestHeader = makePart({
		Name = "DailyChestSign",
		Size = Vector3.new(1.2, 3.4, 13.5),
		Position = Vector3.new(164.2, 10.6, 92),
		Color = Color3.fromRGB(255, 195, 55),
		Material = Enum.Material.SmoothPlastic,
		Parent = chestBooth,
	})
	createSurfaceSign(
		chestHeader,
		"🎁 DAILY STREAK & PLAYTIME CHEST!\nFree Rewards at 2m • 5m • 10m • 15m • 30m!",
		Color3.fromRGB(95, 255, 140),
		Color3.fromRGB(44, 30, 14),
		{ Enum.NormalId.Left, Enum.NormalId.Right },
		160
	)
	createAttachmentPrompt(chestPad, "DailyChestPrompt", "Claim Daily & Playtime Chest", "🎁 2m/5m/10m/15m/30m Rewards", Vector3.new(0, 3.2, 0), 16)

	-- 4. 🛒 Premium Robux Shop & 5-Gamepass Kiosk (Outer East Plaza South at X = 162, Z = 132)
	local vipBooth = Instance.new("Model")
	vipBooth.Name = "VIPRobuxShopBooth"
	vipBooth.Parent = hubFolder

	local vipPad = buildGlowingNeonCircle(
		vipBooth,
		"VIPShopPad",
		Vector3.new(162, 0.35, 132),
		18,
		Color3.fromRGB(85, 215, 255),
		Color3.fromRGB(255, 215, 65)
	)
	vipBooth.PrimaryPart = vipPad

	-- Glossy Studded Golden Simulator Shop Canopy
	for _, zSide in ipairs({ -8.2, 8.2 }) do
		makePart({
			Name = "VIPShopColumn",
			Size = Vector3.new(2.2, 10.5, 2.2),
			Position = Vector3.new(164.8, 5.25, 132 + zSide),
			Color = Color3.fromRGB(255, 215, 65),
			Material = Enum.Material.Plastic,
			Parent = vipBooth,
		})
	end
	makePart({
		Name = "VIPShopCanopy",
		Size = Vector3.new(10.5, 1.4, 19.2),
		Position = Vector3.new(162.5, 10.2, 132),
		Color = Color3.fromRGB(32, 42, 78),
		Material = Enum.Material.Plastic,
		Parent = vipBooth,
	})

	local vipHeader = makePart({
		Name = "VIPShopSign",
		Size = Vector3.new(1.4, 3.8, 18.5),
		Position = Vector3.new(164.8, 12.6, 132),
		Color = Color3.fromRGB(65, 205, 255),
		Material = Enum.Material.SmoothPlastic,
		Parent = vipBooth,
	})
	createSurfaceSign(
		vipHeader,
		"🛒 ROBUX SHOP & VIP GAMEPASSES\n2x Cash • 2x Speed • Fast Hatch • VIP Crown • +2 Carry Eggs!",
		Color3.fromRGB(255, 235, 85),
		Color3.fromRGB(18, 28, 52),
		{ Enum.NormalId.Left, Enum.NormalId.Right },
		170
	)

	-- 5 Display Pedestals inside the VIP Booth (for the 5 Gamepasses: 2x Cash, 2x Speed, Fast Hatch, VIP Crown, +2 Carry Eggs!)
	local displayColors = {
		Color3.fromRGB(255, 215, 55),
		Color3.fromRGB(65, 225, 255),
		Color3.fromRGB(195, 95, 255),
		Color3.fromRGB(255, 95, 195),
		Color3.fromRGB(85, 245, 135),
	}
	for i, dColor in ipairs(displayColors) do
		local zOff = 132 + (i - 3) * 3.4
		makePart({
			Name = "VIPDisplayPillar_" .. tostring(i),
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3.0, 2.6, 2.6),
			CFrame = CFrame.new(162, 1.7, zOff) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(42, 48, 68),
			Material = Enum.Material.Plastic,
			Parent = vipBooth,
		})
		makePart({
			Name = "VIPDisplayOrb_" .. tostring(i),
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2.4, 2.4, 2.4),
			Position = Vector3.new(162, 4.4, zOff),
			Color = dColor,
			Material = Enum.Material.Neon,
			Parent = vipBooth,
		})
	end

	createAttachmentPrompt(vipPad, "RobuxShopPrompt", "Open VIP & Gamepass Shop", "🛒 2x Cash • VIP Crown • +2 Carry Eggs", Vector3.new(0, 3.2, 0), 18)
end

-- Helper: Builds an authentic "Find The Squishies" Multi-Tiered Stepped Dirt-and-Grass Cliff Hill (`full_frame_09.png`, `full_frame_12.png`)
local function buildSteppedDirtGrassHill(
	parent: Instance,
	basePos: Vector3,
	baseW: number,
	baseD: number,
	numTiers: number,
	grassColor: Color3?,
	dirtColor: Color3?
)
	local gCol = grassColor or Color3.fromRGB(108, 198, 72)
	local dCol = dirtColor or Color3.fromRGB(132, 92, 74)
	local tierH = 4.6
	for t = 1, numTiers do
		local ratio = 1 - (t - 1) * (0.22 / math.max(1, numTiers - 1))
		local w = baseW * ratio
		local d = baseD * ratio
		local yBottom = (t - 1) * tierH
		local xShift = (t - 1) * 1.4
		local zShift = (t - 1) * 1.6

		-- Studded Brown Dirt Base Block
		makePart({
			Name = "HillDirtTier_" .. tostring(t),
			Size = Vector3.new(w, tierH - 1.0, d),
			Position = basePos + Vector3.new(xShift, yBottom + (tierH - 1.0) * 0.5, zShift),
			Color = dCol,
			Material = Enum.Material.Plastic,
			Parent = parent,
		})
		-- Slightly Overhanging Bright Green Studded Grass Cap (`full_frame_09.png`)
		makePart({
			Name = "HillGrassCap_" .. tostring(t),
			Size = Vector3.new(w + 1.2, 1.1, d + 1.2),
			Position = basePos + Vector3.new(xShift, yBottom + tierH - 0.45, zShift),
			Color = if t % 2 == 0 then gCol:Lerp(Color3.fromRGB(145, 225, 85), 0.25) else gCol,
			Material = Enum.Material.Plastic,
			Parent = parent,
		})
	end
end

-- Helper: Builds an authentic "Find The Squishies" Twin Stacked Wooden Crate Archway with Narrow Plank Bridge & Traffic Cones (`fts_frame_12.png`, `full_frame_06.png`)
local function buildStackedCrateArchBridge(parent: Instance, centerPos: Vector3, yawDeg: number)
	local cf = CFrame.new(centerPos) * CFrame.Angles(0, math.rad(yawDeg), 0)
	local folder = Instance.new("Folder")
	folder.Name = "StackedCrateArchBridge"
	folder.Parent = parent

	-- Left 4-Crate Stepped Pyramid
	buildWoodenCrate(folder, cf * CFrame.new(-11.5, 2.0, 0), 4.0)
	buildWoodenCrate(folder, cf * CFrame.new(-7.4, 2.0, 0), 4.0)
	buildWoodenCrate(folder, cf * CFrame.new(-7.4, 6.0, 0), 4.0)
	buildWoodenCrate(folder, cf * CFrame.new(-7.4, 10.0, 0), 4.0)

	-- Right 3-Crate Stepped Pyramid
	buildWoodenCrate(folder, cf * CFrame.new(11.5, 2.0, 0), 4.0)
	buildWoodenCrate(folder, cf * CFrame.new(7.4, 2.0, 0), 4.0)
	buildWoodenCrate(folder, cf * CFrame.new(7.4, 6.0, 0), 4.0)

	-- Tilted Narrow Wooden Plank Bridge spanning between the two Crate Towers (`fts_frame_12.png`)!
	makePart({
		Name = "CrateArchPlankBridge",
		Size = Vector3.new(12.2, 0.55, 2.2),
		CFrame = (cf * CFrame.new(0, 10.2, 0)) * CFrame.Angles(0, 0, math.rad(-14)),
		Color = Color3.fromRGB(208, 156, 98),
		Material = Enum.Material.Plastic,
		Parent = folder,
	})

	-- Iconic Orange-and-White Traffic Cones on the grass nearby (`fts_frame_12.png`)!
	for _, coneOff in ipairs({ Vector3.new(-3.5, 0, 5.5), Vector3.new(4.2, 0, 6.2), Vector3.new(7.8, 0, 4.8) }) do
		makePart({
			Name = "TrafficConeBase",
			Size = Vector3.new(2.2, 0.4, 2.2),
			CFrame = cf * CFrame.new(coneOff + Vector3.new(0, 0.2, 0)),
			Color = Color3.fromRGB(35, 38, 45),
			Material = Enum.Material.Plastic,
			Parent = folder,
		})
		makePart({
			Name = "TrafficConeBody",
			Size = Vector3.new(1.5, 1.8, 1.5),
			CFrame = cf * CFrame.new(coneOff + Vector3.new(0, 1.2, 0)),
			Color = Color3.fromRGB(255, 105, 30),
			Material = Enum.Material.Plastic,
			Parent = folder,
		})
		makePart({
			Name = "TrafficConeStripe",
			Size = Vector3.new(1.1, 0.6, 1.1),
			CFrame = cf * CFrame.new(coneOff + Vector3.new(0, 1.8, 0)),
			Color = Color3.fromRGB(250, 250, 255),
			Material = Enum.Material.Plastic,
			Parent = folder,
		})
	end
end

-- Helper: Builds the Authentic "Find The Squishies" Town Street in the Safe Zone (`full_frame_05.png`, `full_frame_20.png`, `full_frame_24.png`, `fts_frame_15.png`):
-- Includes: Walk-in "McBurger's" Fast-Food Restaurant, Walk-in "Squishy Market" Supermarket with Purple Display Shelves,
-- Town Bus Stop Shelter, Red Shipping Container next to Houses, and the Red-Laser Security Vault!
local function buildFindTheSquishiesTownStreet(hubFolder: Folder, obstaclesFolder: Folder)
	local townFolder = Instance.new("Folder")
	townFolder.Name = "FindTheSquishiesTownStreet"
	townFolder.Parent = hubFolder

	-- 1. Walk-In "McBurger's" Fast-Food Restaurant at X = -142, Z = 22 (North-West Town Corner, widely spaced from Player Plots!)
	local mcPos = Vector3.new(-142, 0, 22)
	local mcModel = Instance.new("Model")
	mcModel.Name = "McBurgersRestaurant"
	mcModel.Parent = townFolder

	-- Striped Red & White Walls + Walk-in Doorway + Glass Display Window (`full_frame_24.png`)
	makePart({
		Name = "McFloor",
		Size = Vector3.new(26, 0.6, 18),
		Position = mcPos + Vector3.new(0, 0.3, 0),
		Color = Color3.fromRGB(225, 220, 210),
		Material = Enum.Material.Plastic,
		Parent = mcModel,
	})
	makePart({
		Name = "McBackWall",
		Size = Vector3.new(26, 13, 1.4),
		Position = mcPos + Vector3.new(0, 6.5, -8.3),
		Color = Color3.fromRGB(185, 68, 65),
		Material = Enum.Material.Plastic,
		Parent = mcModel,
	})
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "McSideWall",
			Size = Vector3.new(1.4, 13, 18),
			Position = mcPos + Vector3.new(side * 12.3, 6.5, 0),
			Color = Color3.fromRGB(185, 68, 65),
			Material = Enum.Material.Plastic,
			Parent = mcModel,
		})
	end
	-- Front Glass Window & Open Doorway
	makePart({
		Name = "McFrontWindow",
		Size = Vector3.new(11, 7.5, 0.6),
		Position = mcPos + Vector3.new(-5.5, 5.5, 8.6),
		Color = Color3.fromRGB(205, 238, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.45,
		Parent = mcModel,
	})
	makePart({
		Name = "McRoofOverhang",
		Size = Vector3.new(28, 2.2, 20),
		Position = mcPos + Vector3.new(0, 14.0, 0),
		Color = Color3.fromRGB(165, 55, 52),
		Material = Enum.Material.Plastic,
		Parent = mcModel,
	})
	local mcSign = makePart({
		Name = "McBurgersSignBoard",
		Size = Vector3.new(24, 5.2, 2.2),
		Position = mcPos + Vector3.new(0, 17.6, 4.0),
		Color = Color3.fromRGB(178, 82, 78),
		Material = Enum.Material.Plastic,
		Parent = mcModel,
	})
	createSurfaceSign(
		mcSign,
		"🍔 B   McBurger's",
		Color3.fromRGB(255, 225, 45),
		Color3.fromRGB(158, 52, 48),
		{ Enum.NormalId.Back, Enum.NormalId.Front },
		200
	)
	-- Indoor Order Counter & Dining Booths inside McBurger's
	makePart({
		Name = "McCounter",
		Size = Vector3.new(14, 3.8, 2.6),
		Position = mcPos + Vector3.new(0, 2.2, -3.5),
		Color = Color3.fromRGB(245, 195, 55),
		Material = Enum.Material.Plastic,
		Parent = mcModel,
	})

	-- 2. Walk-In "Squishy Market" Supermarket at X = 142, Z = 22 with Multi-Tier Purple Display Shelves inside (`full_frame_05.png`, `full_frame_24.png`)
	local mktPos = Vector3.new(142, 0, 22)
	local mktModel = Instance.new("Model")
	mktModel.Name = "SquishySupermarket"
	mktModel.Parent = townFolder

	makePart({
		Name = "MarketFloor",
		Size = Vector3.new(26, 0.6, 18),
		Position = mktPos + Vector3.new(0, 0.3, 0),
		Color = Color3.fromRGB(232, 228, 218),
		Material = Enum.Material.Plastic,
		Parent = mktModel,
	})
	makePart({
		Name = "MarketBackWall",
		Size = Vector3.new(26, 13, 1.4),
		Position = mktPos + Vector3.new(0, 6.5, -8.3),
		Color = Color3.fromRGB(198, 178, 152),
		Material = Enum.Material.Plastic,
		Parent = mktModel,
	})
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "MarketSideWall",
			Size = Vector3.new(1.4, 13, 18),
			Position = mktPos + Vector3.new(side * 12.3, 6.5, 0),
			Color = Color3.fromRGB(198, 178, 152),
			Material = Enum.Material.Plastic,
			Parent = mktModel,
		})
	end
	makePart({
		Name = "MarketRoof",
		Size = Vector3.new(28, 2.2, 20),
		Position = mktPos + Vector3.new(0, 14.0, 0),
		Color = Color3.fromRGB(128, 108, 88),
		Material = Enum.Material.Plastic,
		Parent = mktModel,
	})
	local mktSign = makePart({
		Name = "MarketSignBoard",
		Size = Vector3.new(22, 4.8, 2.0),
		Position = mktPos + Vector3.new(0, 17.4, 4.0),
		Color = Color3.fromRGB(72, 76, 94),
		Material = Enum.Material.Plastic,
		Parent = mktModel,
	})
	createSurfaceSign(
		mktSign,
		"🛒 Squishy Market",
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(58, 62, 78),
		{ Enum.NormalId.Back, Enum.NormalId.Front },
		200
	)
	-- Multi-Tier Purple Supermarket Display Shelves inside (`full_frame_05.png`)!
	for aisle = -1, 1, 2 do
		for tier = 1, 4 do
			makePart({
				Name = string.format("SupermarketShelf_%d_%d", aisle, tier),
				Size = Vector3.new(9.5, 0.5, 2.6),
				Position = mktPos + Vector3.new(aisle * 5.2, 1.2 + tier * 2.1, -1.5),
				Color = Color3.fromRGB(162, 152, 212),
				Material = Enum.Material.Plastic,
				Parent = mktModel,
			})
		end
	end

	-- (Removed RedShippingContainer and Safe Zone crate stack so zero random boxes clutter the Safe Zone Hub!)

	-- 4. Town Bus Stop Glass Shelter on the South Boulevard (`full_frame_24.png`)
	local busPos = Vector3.new(72, 0, 194)
	makePart({
		Name = "BusStopRoof",
		Size = Vector3.new(12, 0.8, 6.5),
		Position = busPos + Vector3.new(0, 9.2, 0),
		Color = Color3.fromRGB(165, 168, 175),
		Material = Enum.Material.Plastic,
		Parent = townFolder,
	})
	makePart({
		Name = "BusStopGlassBack",
		Size = Vector3.new(11.4, 8.8, 0.5),
		Position = busPos + Vector3.new(0, 4.6, 2.8),
		Color = Color3.fromRGB(210, 235, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.45,
		Parent = townFolder,
	})
	makePart({
		Name = "BusStopBench",
		Size = Vector3.new(7.5, 1.6, 2.2),
		Position = busPos + Vector3.new(0, 1.2, 1.4),
		Color = Color3.fromRGB(195, 185, 145),
		Material = Enum.Material.Plastic,
		Parent = townFolder,
	})

	-- 5. Iconic Dark Vault Building with Red Laser Door (`full_frame_20.png`) at X = 148, Z = 198!
	local vaultPos = Vector3.new(148, 0, 198)
	makePart({
		Name = "LaserVaultBack",
		Size = Vector3.new(18, 13, 14),
		Position = vaultPos + Vector3.new(0, 6.5, 0),
		Color = Color3.fromRGB(48, 52, 64),
		Material = Enum.Material.Plastic,
		Parent = townFolder,
	})
	for bar = -3, 3 do
		makePart({
			Name = "VaultRedLaserBar_" .. tostring(bar),
			Size = Vector3.new(0.45, 10.5, 0.45),
			Position = vaultPos + Vector3.new(bar * 1.8, 5.5, -7.2),
			Color = Color3.fromRGB(255, 35, 35),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = townFolder,
		})
	end

	-- 6. Stepped Dirt-and-Grass Cliff Hills framing the South-East & South-West corners (`full_frame_09.png`)
	buildSteppedDirtGrassHill(townFolder, Vector3.new(-158, 0, 96), 24, 24, 3)
	buildSteppedDirtGrassHill(townFolder, Vector3.new(152, 0, 214), 26, 20, 3)
end

-- Builds Dedicated Right-Side & Center Signature "Find The Squishies" Creative Sections, Landmarks, Puzzles & Obstacles in each Stage!
local function buildBiomeLandmarksAndInteractiveProps(parent: Instance, levelInfo: any, obstaclesFolder: Folder)
	local id = levelInfo.Id or levelInfo.Level or 1
	local zStart = levelInfo.ZStart
	local zNorth = zStart - 52
	local zSouth = zStart - 86
	local themeColor = levelInfo.ThemeColor or Color3.fromRGB(95, 225, 110)
	local secColor = levelInfo.SecondaryColor or themeColor

	local landmarksFolder = Instance.new("Folder")
	landmarksFolder.Name = "BiomeLandmarks_" .. tostring(id)
	landmarksFolder.Parent = parent

	-- =========================================================================================
	-- SECTOR 1 (Z = zStart - 12 to zStart - 34):
	-- Uniform Entry Plaza in EVERY Stage (Stages 1–8):
	-- 1. Left Side (X = -48, Z = zStart - 16): 3D Stage Completion Checklist Board (`StageChecklistBoard_<id>`)
	-- 2. Right Side (X = +48, Z = zStart - 16): Stage Treadmill Plaza Pad (`TreadmillPlazaPad_<id>`)
	-- 3. Center (X = 0, Z = zStart - 13): Timed Shortcut Bridge Button (`ShortcutBridgeButton_<id>`)
	-- =========================================================================================
	local totalEggsInStage = 0
	local totalSquishiesInStage = 0
	for _, sData in ipairs(SlimeData.Slimes) do
		if sData.Level == id then
			local numId = tonumber((sData :: any).UnlockOrder or (sData :: any).NumericId or sData.Id) or 1
			if numId <= 35 then
				totalEggsInStage += 1
			else
				totalSquishiesInStage += 1
			end
		end
	end
	local nextLevelInfo = SlimeData.Levels[id + 1]
	local nextReqSpeed = if nextLevelInfo then (nextLevelInfo.RequiredSpeed or 0) else 0
	local nextReqText = if nextLevelInfo
		then string.format("⚡ Next Gate (Stage %d): %s Speed + 100%% Stage %d", id + 1, SlimeData.FormatNumber(nextReqSpeed), id)
		else "👑 Final Stage: Complete 100% for Cosmic Mastery!"

	local checklistPos = Vector3.new(-48, 0, zStart - 16)
	buildGlowingNeonCircle(
		landmarksFolder,
		"StageChecklistPad_" .. tostring(id),
		checklistPos + Vector3.new(0, 0.35, 0),
		12.0,
		themeColor,
		secColor
	)
	for _, postSide in ipairs({ -1, 1 }) do
		makePart({
			Name = "ChecklistPost_" .. tostring(postSide),
			Size = Vector3.new(1.4, 13.0, 1.4),
			Position = checklistPos + Vector3.new(postSide * 7.8, 6.5, 0),
			Color = secColor,
			Material = Enum.Material.Metal,
			Parent = landmarksFolder,
		})
	end
	local checklistBoard = makePart({
		Name = "StageChecklistBoard_" .. tostring(id),
		Size = Vector3.new(17.5, 9.5, 1.2),
		Position = checklistPos + Vector3.new(0, 8.2, 0),
		Color = Color3.fromRGB(22, 26, 44),
		Material = Enum.Material.SmoothPlastic,
		Parent = landmarksFolder,
	})
	checklistBoard:SetAttribute("StageId", id)
	checklistBoard:SetAttribute("TotalEggs", totalEggsInStage)
	checklistBoard:SetAttribute("TotalSquishies", totalSquishiesInStage)
	checklistBoard:SetAttribute("NextRequiredSpeed", nextReqSpeed)

	createSurfaceSign(
		checklistBoard,
		string.format(
			"📋 STAGE %d: %s\n🥚 Boss Eggs: 0/%d  |  🧸 Squishies: 0/%d\n%s\n🔓 STAGE %d COMPLETION: 0%%",
			id,
			string.upper(levelInfo.Name),
			totalEggsInStage,
			totalSquishiesInStage,
			nextReqText,
			id
		),
		Color3.fromRGB(255, 245, 125),
		Color3.fromRGB(18, 22, 38),
		{ Enum.NormalId.Back, Enum.NormalId.Front },
		180
	)

	-- Dedicated Right-Side Sector 1 Creator Store 3D Treadmill at X = +48, Z = zStart - 16 (Tier 1..8: x1 SPEED -> x50M SPEED!)
	local tmTier = SlimeData.TreadmillTiers[id] or SlimeData.TreadmillTiers[1]
	local tmPlazaPad = buildGlowingNeonCircle(
		landmarksFolder,
		"TreadmillPlazaPad_" .. tostring(id),
		Vector3.new(48, 0.35, zStart - 16),
		16.5,
		tmTier.PrimaryColor,
		tmTier.AccentColor
	)
	tmPlazaPad:SetAttribute("TreadmillStageId", id)
	buildDinoJawTreadmill(landmarksFolder, Vector3.new(48, 0.35, zStart - 16), -1, 0, id)

	if id == 1 then
		-- =========================================================================================
		-- STAGE 1 (SQUISHY MEADOW):
		-- Authentic "Find The Squishies" Stepped Dirt-and-Grass Cliff Hills (`full_frame_09.png`),
		-- Stacked Wooden Crate Archway with Plank Bridge (`fts_frame_12.png`),
		-- Secret Dark Stone Cave Entrance with Downward Arrow (`fts_frame_02.png`), `1710` Keypad (`full_frame_17.png`),
		-- Giant Clickable/Touch Stone Block (`Clicks Remaining` from `full_frame_18.png`),
		-- Country Windmill, Wooden Park Gazebo (`full_frame_07.png`), and Honey Barrel Bounce Course!
		-- =========================================================================================

		-- 1. Multi-Tier Stepped Dirt-and-Grass Cliff Hill at X = 26, Z = zStart - 42 (`full_frame_09.png`)
		buildSteppedDirtGrassHill(landmarksFolder, Vector3.new(26, 0, zStart - 42), 20, 18, 3)

		-- 2. Twin Stacked Wooden Crate Archway with Tilted Plank Bridge & Traffic Cones at X = -26, Z = zStart - 54 (`fts_frame_12.png`)
		buildStackedCrateArchBridge(landmarksFolder, Vector3.new(-26, 0, zStart - 54), 0)

		-- 3. Dark Rocky Secret Cave Entrance with White Downward Arrow, `1710` Keypad & Breakable Stone Cube at X = 26, Z = zStart - 72 (`fts_frame_02.png`, `full_frame_17.png`, `full_frame_18.png`)
		makePart({
			Name = "SecretCaveOuterRock",
			Size = Vector3.new(18, 14, 13),
			Position = Vector3.new(26, 7.0, zStart - 72),
			Color = Color3.fromRGB(108, 106, 122),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "SecretCaveRoofStep",
			Size = Vector3.new(13, 3.0, 10),
			Position = Vector3.new(26, 15.5, zStart - 72),
			Color = Color3.fromRGB(128, 126, 144),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "SecretCaveDarkOpening",
			Size = Vector3.new(7.5, 9.5, 1.2),
			Position = Vector3.new(26, 4.75, zStart - 65.8),
			Color = Color3.fromRGB(12, 12, 16),
			Material = Enum.Material.SmoothPlastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "CaveDownArrow",
			Size = Vector3.new(2.6, 3.0, 0.8),
			Position = Vector3.new(26, 11.2, zStart - 65.4),
			Color = Color3.fromRGB(235, 245, 255),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		local caveKeypad = makePart({
			Name = "CaveCodeKeypad",
			Size = Vector3.new(2.4, 3.6, 0.6),
			Position = Vector3.new(19.8, 4.8, zStart - 65.5),
			Color = Color3.fromRGB(45, 48, 58),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		createSurfaceSign(
			caveKeypad,
			"1710\n[1][2][3]\n[4][5][6]\n[7][8][9]",
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(32, 36, 46),
			{ Enum.NormalId.Back, Enum.NormalId.Front },
			55
		)

		local clickCube = makePart({
			Name = "BreakableStoneCube_1",
			Size = Vector3.new(8.5, 8.5, 8.5),
			Position = Vector3.new(-26, 4.25, zStart - 76),
			Color = Color3.fromRGB(156, 154, 178),
			Material = Enum.Material.Plastic,
			Parent = obstaclesFolder,
		})
		clickCube:SetAttribute("WorldCoinPickup", true)
		clickCube:SetAttribute("MinCoinValue", 150)
		clickCube:SetAttribute("MaxCoinValue", 350)
		createBillboardText(
			clickCube,
			"🪨 SECRET STONE CUBE\n[Touch to Mine Bonus Cash!]",
			Color3.fromRGB(255, 255, 255),
			Vector3.new(0, 5.8, 0),
			UDim2.new(6.2, 0, 1.5, 0),
			42
		)

		-- 4. Dedicated Right-Side Signature Landmark #1: Giant Spinning Country Windmill at X = 64, zNorth (-52)
		makePart({
			Name = "WindmillTower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(22, 11, 11),
			CFrame = CFrame.new(64, 11, zNorth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(235, 215, 175),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "WindmillRoof",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(13, 9, 13),
			Position = Vector3.new(64, 21.5, zNorth),
			Color = Color3.fromRGB(215, 65, 55),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		local rotor1 = makePart({
			Name = "WindmillBlades_1",
			Size = Vector3.new(26, 2.2, 1.2),
			Position = Vector3.new(64, 18, zNorth + 6.2),
			Color = Color3.fromRGB(255, 240, 185),
			Material = Enum.Material.Plastic,
			CanCollide = false,
			Parent = obstaclesFolder,
		})
		rotor1:SetAttribute("WindmillRotor", true)
		rotor1:SetAttribute("SpinSpeed", 1.1)

		local rotor2 = makePart({
			Name = "WindmillBlades_2",
			Size = Vector3.new(2.2, 26, 1.2),
			Position = Vector3.new(64, 18, zNorth + 6.2),
			Color = Color3.fromRGB(255, 240, 185),
			Material = Enum.Material.Plastic,
			CanCollide = false,
			Parent = obstaclesFolder,
		})
		rotor2:SetAttribute("WindmillRotor", true)
		rotor2:SetAttribute("SpinSpeed", 1.1)

		-- 5. Dedicated Right-Side Signature Landmark #2: Flower Gazebo at X = 64, zSouth (-86)
		makePart({
			Name = "GazeboFloor",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.5, 16, 16),
			CFrame = CFrame.new(64, 0.75, zSouth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(215, 168, 115),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		for gp = 0, 3 do
			local ang = math.rad(gp * 90 + 45)
			makePart({
				Name = "GazeboPillar_" .. tostring(gp),
				Size = Vector3.new(1.4, 11, 1.4),
				Position = Vector3.new(64 + math.cos(ang) * 5.8, 6.2, zSouth + math.sin(ang) * 5.8),
				Color = Color3.fromRGB(245, 238, 225),
				Material = Enum.Material.Plastic,
				Parent = landmarksFolder,
			})
		end
		makePart({
			Name = "GazeboFloralCanopy",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3.2, 18, 18),
			CFrame = CFrame.new(64, 12.8, zSouth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 115, 185),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "GazeboTopFlower",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(6.5, 4.5, 6.5),
			Position = Vector3.new(64, 15.2, zSouth),
			Color = Color3.fromRGB(255, 225, 65),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})

		-- 6. Honey Barrel Bounce Course (`X = 48, Z = zStart - 36..-96`) + Creator Store Meadow Trees (`X = 72`)
		for b = 1, 4 do
			local bz = zStart - 24 - (b * 16)
			makePart({
				Name = "HoneyBarrel_" .. tostring(b),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(4.2, 6.0, 6.0),
				CFrame = CFrame.new(48, 2.1, bz) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(168, 108, 48),
				Material = Enum.Material.Plastic,
				Parent = landmarksFolder,
			})
			local topBounce = buildGlowingNeonCircle(landmarksFolder, "BouncePad", Vector3.new(48, 4.4, bz), 5.6, Color3.fromRGB(255, 215, 45), Color3.fromRGB(255, 165, 35))
			topBounce:SetAttribute("BounceImpulse", 84)
		end
		placePrebuiltAsset("MeadowTrees", 1, landmarksFolder, Vector3.new(72, 0, zStart - 68), 30, 24.0, true)

	elseif id == 2 then
		-- =========================================================================================
		-- STAGE 2 (CHOCOLATE CANDY KINGDOM):
		-- Dedicated Right-Side Signature Landmarks: Giant 3-Tier Flowing Chocolate Fountain +
		-- Giant Gumball Machine Tower + Spinning Peppermint Rollers + Creator Store Candy Props,
		-- plus ASMR Island Giant Mechanical Keyboard (`fts_frame_09.png`) & Rainbow Pop-It Board!
		-- =========================================================================================

		-- 1. ASMR Island Giant Mechanical Keyboard (`Q W E R T Y U I O P` pastel keycaps from `fts_frame_09.png`!) at X = -24, Z = zStart - 56
		local keyLetters = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S" }
		local keyColors = {
			Color3.fromRGB(255, 115, 195),
			Color3.fromRGB(95, 225, 255),
			Color3.fromRGB(145, 255, 95),
			Color3.fromRGB(255, 235, 75),
			Color3.fromRGB(195, 125, 255),
			Color3.fromRGB(255, 155, 85),
		}
		makePart({
			Name = "ASMRKeyboardTray",
			Size = Vector3.new(34, 1.4, 24),
			Position = Vector3.new(-24, 0.7, zStart - 56),
			Color = Color3.fromRGB(58, 52, 82),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		for kIdx, letter in ipairs(keyLetters) do
			local row = math.floor((kIdx - 1) / 4)
			local col = (kIdx - 1) % 4
			local kx = -35.5 + col * 7.6 + (row * 1.2)
			local kz = (zStart - 47) - row * 7.2
			local kCol = keyColors[((kIdx - 1) % #keyColors) + 1]
			local keyCap = makePart({
				Name = "ASMRKeycap_" .. letter,
				Size = Vector3.new(6.4, 3.2 + (row * 1.2), 6.4),
				Position = Vector3.new(kx, 1.6 + (row * 0.6), kz),
				Color = kCol,
				Material = Enum.Material.Plastic,
				Parent = landmarksFolder,
			})
			createSurfaceSign(keyCap, letter, Color3.fromRGB(25, 25, 35), kCol, { Enum.NormalId.Top }, 90)
			if kIdx % 3 == 0 then
				local bPad = buildGlowingNeonCircle(landmarksFolder, "BouncePad", Vector3.new(kx, 3.3 + row * 1.2, kz), 5.0, kCol, Color3.fromRGB(255, 255, 255))
				bPad:SetAttribute("BounceImpulse", 82)
			end
		end

		-- 2. Giant Rainbow Fidget Pop-It Stepping Board at X = 24, Z = zStart - 56 (`fts_frame_09.png`)
		for popRow = 1, 4 do
			local popCol = keyColors[popRow]
			makePart({
				Name = "PopItRow_" .. tostring(popRow),
				Size = Vector3.new(18, 1.6, 4.5),
				Position = Vector3.new(24, 0.8 + popRow * 0.8, zStart - 38 - popRow * 5.2),
				Color = popCol,
				Material = Enum.Material.Plastic,
				Parent = landmarksFolder,
			})
			for bubble = -1, 1 do
				makePart({
					Name = "PopItBubble",
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(3.6, 2.4, 3.6),
					Position = Vector3.new(24 + bubble * 5.2, 1.8 + popRow * 0.8, zStart - 38 - popRow * 5.2),
					Color = popCol:Lerp(Color3.fromRGB(255, 255, 255), 0.25),
					Material = Enum.Material.Neon,
					Parent = landmarksFolder,
				})
			end
		end

		-- 3. Dedicated Right-Side Signature Landmark #1: Giant 3-Tier Flowing Chocolate Fountain (X = 64, zNorth)
		for tier = 1, 3 do
			local dia = 20 - (tier - 1) * 5.0
			makePart({
				Name = "ChocoTier_" .. tostring(tier),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(3.2, dia, dia),
				CFrame = CFrame.new(64, tier * 4.5, zNorth) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(115, 58, 32),
				Material = Enum.Material.Plastic,
				Parent = landmarksFolder,
			})
			makePart({
				Name = "ChocoFlowColumn_" .. tostring(tier),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(4.5, dia * 0.68, dia * 0.68),
				CFrame = CFrame.new(64, (tier - 0.5) * 4.5, zNorth) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(145, 78, 42),
				Material = Enum.Material.SmoothPlastic,
				Parent = landmarksFolder,
			})
		end
		makePart({
			Name = "CherryTopper",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(5.2, 5.2, 5.2),
			Position = Vector3.new(64, 17.5, zNorth),
			Color = Color3.fromRGB(255, 45, 85),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})

		-- 4. Dedicated Right-Side Signature Landmark #2: Giant Gumball Machine Tower (X = 64, zSouth)
		makePart({
			Name = "GumballBase",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(10, 12, 12),
			CFrame = CFrame.new(64, 5.0, zSouth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(235, 55, 95),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "GumballCoinChute",
			Size = Vector3.new(3.2, 3.8, 1.6),
			Position = Vector3.new(58.2, 5.2, zSouth),
			Color = Color3.fromRGB(255, 215, 65),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "GumballGlassGlobe",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(16, 16, 16),
			Position = Vector3.new(64, 15.5, zSouth),
			Color = Color3.fromRGB(215, 245, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.42,
			Parent = landmarksFolder,
		})
		for gb = 1, 6 do
			local gAng = math.rad(gb * 60)
			makePart({
				Name = "InnerGumball_" .. tostring(gb),
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(3.6, 3.6, 3.6),
				Position = Vector3.new(64 + math.cos(gAng) * 3.8, 13.5 + (gb % 2) * 2.5, zSouth + math.sin(gAng) * 3.8),
				Color = keyColors[gb],
				Material = Enum.Material.Neon,
				Parent = landmarksFolder,
			})
		end

		-- 5. Spinning Peppermint Rollers (X = 46, Z = zStart - 36..-92) + Creator Store Candy Props (X = 72)
		for r = 1, 5 do
			local rz = zStart - 24 - (r * 14)
			local roller = makePart({
				Name = "PeppermintRoller_" .. tostring(r),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(10.5, 4.0, 4.0),
				CFrame = CFrame.new(46, 3.0, rz),
				Color = if r % 2 == 1 then Color3.fromRGB(255, 85, 145) else Color3.fromRGB(255, 245, 250),
				Material = Enum.Material.Plastic,
				Parent = obstaclesFolder,
			})
			roller:SetAttribute("SpinSpeed", 1.6 * (if r % 2 == 1 then 1 else -1))
		end
		placePrebuiltAsset("CandyProps", 1, landmarksFolder, Vector3.new(72, 0, zStart - 68), 45, 24.0, true)

	elseif id == 3 then
		-- =========================================================================================
		-- STAGE 3 (TROPICAL BEACH LAGOON):
		-- Dedicated Right-Side Signature Landmarks: Sunken Pirate Shipwreck Deck (climbable!) +
		-- Rotating Lighthouse Beacon + Surfboard Stepping Stones + Creator Store Palm Trees,
		-- plus Bright Blue Lagoon with Narrow Balance Plank & Giant Yellow Studded Sponge Island (`full_frame_14.png`)!
		-- =========================================================================================

		-- 1. Bright Blue Lagoon Water Pool + Narrow Balance Plank + Giant Yellow Studded Sponge Block Island (`full_frame_14.png`) at X = -14, Z = zStart - 56
		makePart({
			Name = "LagoonWaterPool",
			Size = Vector3.new(44, 0.6, 34),
			Position = Vector3.new(-10, 0.15, zStart - 56),
			Color = Color3.fromRGB(68, 196, 255),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "SpongeIslandBalancePlank",
			Size = Vector3.new(3.2, 1.2, 24),
			Position = Vector3.new(-14, 1.2, zStart - 48),
			Color = Color3.fromRGB(195, 125, 68),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "GiantYellowSpongeIsland",
			Size = Vector3.new(15, 9.5, 15),
			Position = Vector3.new(-14, 4.75, zStart - 66),
			Color = Color3.fromRGB(255, 242, 45),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})

		-- 2. Vertical Studded Rock-Climbing Hold Cliff Wall (`fts_frame_03.png`) at X = 26, Z = zStart - 56
		makePart({
			Name = "RockClimbingWall",
			Size = Vector3.new(4.5, 24, 18),
			Position = Vector3.new(26, 12, zStart - 56),
			Color = Color3.fromRGB(142, 118, 115),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		local holdColors = {
			Color3.fromRGB(255, 95, 125),
			Color3.fromRGB(255, 225, 65),
			Color3.fromRGB(95, 235, 115),
			Color3.fromRGB(85, 205, 255),
		}
		for h = 1, 7 do
			makePart({
				Name = "ClimbingHold_" .. tostring(h),
				Size = Vector3.new(2.6, 1.5, 2.8),
				Position = Vector3.new(23.2, 2.2 + h * 2.8, (zStart - 62) + ((h % 3) * 5.2)),
				Color = holdColors[((h - 1) % #holdColors) + 1],
				Material = Enum.Material.Plastic,
				Parent = landmarksFolder,
			})
		end

		-- 3. Dedicated Right-Side Signature Landmark #1: Sunken Pirate Shipwreck Deck (climbable!) at X = 64, zNorth
		makePart({
			Name = "PirateShipHull",
			Size = Vector3.new(16, 7.5, 30),
			CFrame = CFrame.new(64, 3.8, zNorth) * CFrame.Angles(math.rad(5), math.rad(-10), math.rad(4)),
			Color = Color3.fromRGB(128, 82, 42),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "PirateShipCaptainCabin",
			Size = Vector3.new(14, 6.5, 10),
			CFrame = CFrame.new(64, 10.2, zNorth - 8),
			Color = Color3.fromRGB(148, 96, 52),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "PirateShipBoardingRamp",
			Size = Vector3.new(6.5, 1.0, 16),
			CFrame = CFrame.new(55, 3.8, zNorth + 9) * CFrame.Angles(math.rad(-22), math.rad(-25), 0),
			Color = Color3.fromRGB(168, 112, 58),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "PirateShipMast",
			Size = Vector3.new(2.0, 25, 2.0),
			Position = Vector3.new(64, 14, zNorth),
			Color = Color3.fromRGB(98, 62, 32),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "PirateShipSail",
			Size = Vector3.new(14, 10, 0.9),
			Position = Vector3.new(64, 18, zNorth + 1.2),
			Color = Color3.fromRGB(245, 238, 215),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})

		-- 4. Dedicated Right-Side Signature Landmark #2: Rotating Lighthouse Beacon at X = 64, zSouth
		makePart({
			Name = "LighthouseTower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(24, 11.0, 11.0),
			CFrame = CFrame.new(64, 12, zSouth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(245, 75, 65),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "LighthouseWhiteStripe",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(8, 11.4, 11.4),
			CFrame = CFrame.new(64, 12, zSouth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(248, 248, 252),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "LighthouseLanternRoom",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(4.5, 9.5, 9.5),
			CFrame = CFrame.new(64, 25.5, zSouth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 245, 145),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		local beam = makePart({
			Name = "LighthouseBeam",
			Size = Vector3.new(32, 1.8, 1.8),
			Position = Vector3.new(64, 26.5, zSouth),
			Color = Color3.fromRGB(255, 245, 125),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Transparency = 0.25,
			Parent = obstaclesFolder,
		})
		beam:SetAttribute("SpinSpeed", 1.4)

		-- 5. Surfboard Stepping Stones (X = 46, Z = zStart - 36..-90) + Creator Store Palm Trees (X = 72)
		local surfColors = {
			Color3.fromRGB(55, 225, 255),
			Color3.fromRGB(255, 195, 55),
			Color3.fromRGB(255, 95, 175),
			Color3.fromRGB(95, 245, 135),
		}
		for s = 1, 4 do
			local sz = zStart - 24 - (s * 16)
			makePart({
				Name = "SurfboardStone_" .. tostring(s),
				Size = Vector3.new(4.8, 1.0, 10.5),
				CFrame = CFrame.new(46, 1.8 + s * 1.1, sz) * CFrame.Angles(0, math.rad((s - 2) * 14), 0),
				Color = surfColors[s],
				Material = Enum.Material.Plastic,
				Parent = landmarksFolder,
			})
		end
		placePrebuiltAsset("PalmTrees", 1, landmarksFolder, Vector3.new(72, 0, zStart - 68), 60, 25.0, true)

	elseif id == 4 then
		-- =========================================================================================
		-- STAGE 4 (WHISPERING BAMBOO FOREST):
		-- Jade Koi Lotus Pond + Arched Red Torii Bridge, Giant Hollow Bamboo Grove Climb,
		-- Spinning Jade Pagoda Tower (X = 64, zNorth), Glowing Zen Lantern Shrine (X = 64, zSouth),
		-- and Bamboo Stepping Stalks + Bounce Lotus Pads (X = 46)!
		-- =========================================================================================

		-- 1. Jade Koi Lotus Pond + Arched Crimson Torii Bridge at X = -14, Z = zStart - 56
		makePart({
			Name = "BambooLotusPond",
			Size = Vector3.new(38, 0.6, 30),
			Position = Vector3.new(-14, 0.15, zStart - 56),
			Color = Color3.fromRGB(55, 205, 175),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "ToriiBridgeDeck",
			Size = Vector3.new(6.5, 1.2, 28),
			Position = Vector3.new(-14, 1.8, zStart - 56),
			Color = Color3.fromRGB(225, 58, 52),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})
		for _, toriiZ in ipairs({ zStart - 44, zStart - 68 }) do
			for _, pSide in ipairs({ -3.2, 3.2 }) do
				makePart({
					Name = "ToriiGatePillar",
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(13, 1.4, 1.4),
					CFrame = CFrame.new(-14 + pSide, 7.5, toriiZ) * CFrame.Angles(0, 0, math.rad(90)),
					Color = Color3.fromRGB(225, 48, 42),
					Material = Enum.Material.SmoothPlastic,
					Parent = landmarksFolder,
				})
			end
			makePart({
				Name = "ToriiGateTopBeam",
				Size = Vector3.new(10.5, 1.6, 1.8),
				Position = Vector3.new(-14, 14.2, toriiZ),
				Color = Color3.fromRGB(235, 55, 48),
				Material = Enum.Material.SmoothPlastic,
				Parent = landmarksFolder,
			})
		end

		-- 2. Giant Hollow Bamboo Stalk Climb at X = 24, Z = zStart - 56
		for bIdx = 1, 5 do
			local bx = 20 + (bIdx % 2) * 8
			local bz = (zStart - 42) - bIdx * 5.5
			makePart({
				Name = "GiantBambooStalk_" .. tostring(bIdx),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(4.5 + bIdx * 2.5, 5.2, 5.2),
				CFrame = CFrame.new(bx, (4.5 + bIdx * 2.5) * 0.5, bz) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(95, 225, 115),
				Material = Enum.Material.SmoothPlastic,
				Parent = landmarksFolder,
			})
		end

		-- 3. Dedicated Right-Side Signature Landmark #1: 3-Tier Jade Pagoda Temple Tower (X = 64, zNorth)
		for pTier = 1, 3 do
			local w = 20 - (pTier - 1) * 4.5
			makePart({
				Name = "PagodaBody_" .. tostring(pTier),
				Size = Vector3.new(w * 0.75, 5.5, w * 0.75),
				Position = Vector3.new(64, (pTier - 0.5) * 6.5, zNorth),
				Color = Color3.fromRGB(235, 225, 195),
				Material = Enum.Material.SmoothPlastic,
				Parent = landmarksFolder,
			})
			makePart({
				Name = "PagodaJadeRoof_" .. tostring(pTier),
				Size = Vector3.new(w, 1.6, w),
				Position = Vector3.new(64, pTier * 6.5, zNorth),
				Color = Color3.fromRGB(58, 195, 105),
				Material = Enum.Material.SmoothPlastic,
				Parent = landmarksFolder,
			})
		end
		local pagodaOrb = makePart({
			Name = "PagodaJadeFinial",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(4.8, 4.8, 4.8),
			Position = Vector3.new(64, 23.0, zNorth),
			Color = Color3.fromRGB(135, 255, 155),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = obstaclesFolder,
		})
		pagodaOrb:SetAttribute("SpinSpeed", 1.5)

		-- 4. Dedicated Right-Side Signature Landmark #2: Glowing Zen Lantern Shrine (X = 64, zSouth)
		makePart({
			Name = "ZenShrineBase",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.0, 16, 16),
			CFrame = CFrame.new(64, 1.0, zSouth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(128, 138, 128),
			Material = Enum.Material.Slate,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "ZenLanternCore",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(9.5, 11.5, 9.5),
			Position = Vector3.new(64, 9.5, zSouth),
			Color = Color3.fromRGB(155, 255, 145),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "ZenLanternCap",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.4, 14, 14),
			CFrame = CFrame.new(64, 15.8, zSouth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(68, 165, 88),
			Material = Enum.Material.Slate,
			Parent = landmarksFolder,
		})

		-- 5. Lotus Bounce Stepping Course (X = 46, Z = zStart - 36..-90) + Meadow/Bamboo Trees (X = 72)
		for b = 1, 4 do
			local bz = zStart - 24 - (b * 16)
			local lotusPad = buildGlowingNeonCircle(
				landmarksFolder,
				"BouncePad",
				Vector3.new(46, 1.2 + b * 0.5, bz),
				6.2,
				Color3.fromRGB(95, 245, 135),
				Color3.fromRGB(255, 145, 205)
			)
			lotusPad:SetAttribute("BounceImpulse", 90)
		end
		placePrebuiltAsset("MeadowTrees", 2, landmarksFolder, Vector3.new(72, 0, zStart - 68), 45, 25.0, true)

	elseif id == 5 then
		-- =========================================================================================
		-- STAGE 5 (CRYSTAL CYBER CAVERN):
		-- Dedicated Right-Side Signature Landmarks: Levitating Cyber-Crystal Monolith Ring +
		-- Glowing Geode Archway + Moving Crystal Platforms + Creator Store Crystals,
		-- plus Underground Stone Wall-Jump Ledges over Glowing Cyan Pool (`full_frame_16.png`) & Laser Vault (`full_frame_20.png`)!
		-- =========================================================================================

		-- 1. Underground Stone Cavern Wall + Wall-Jump Ledges over Glowing Cyan Water Pool (`full_frame_16.png` & `full_frame_10.png`) at X = -14, Z = zStart - 56
		makePart({
			Name = "CavernCyanPool",
			Size = Vector3.new(36, 0.8, 28),
			Position = Vector3.new(-14, 0.2, zStart - 56),
			Color = Color3.fromRGB(85, 235, 255),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "CavernLedgeWall",
			Size = Vector3.new(4.5, 22, 28),
			Position = Vector3.new(6, 11, zStart - 56),
			Color = Color3.fromRGB(112, 108, 142),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		local codePlaque = makePart({
			Name = "HiddenCodePlaque_6",
			Size = Vector3.new(0.6, 3.8, 3.8),
			Position = Vector3.new(3.4, 16.5, zStart - 48),
			Color = Color3.fromRGB(235, 45, 65),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		createSurfaceSign(codePlaque, "6", Color3.fromRGB(255, 255, 255), Color3.fromRGB(225, 38, 58), { Enum.NormalId.Left, Enum.NormalId.Right }, 80)

		for l = 1, 5 do
			makePart({
				Name = "CavernWallJumpLedge_" .. tostring(l),
				Size = Vector3.new(5.5, 1.8, 5.2),
				Position = Vector3.new(1.5, l * 3.4, (zStart - 42) - l * 4.8),
				Color = Color3.fromRGB(148, 146, 168),
				Material = Enum.Material.Plastic,
				Parent = landmarksFolder,
			})
		end

		-- 2. Dark Vault Building with Red Laser Bars (`full_frame_20.png`) at X = 26, Z = zStart - 56
		makePart({
			Name = "CrystalLaserVault",
			Size = Vector3.new(16, 13, 14),
			Position = Vector3.new(26, 6.5, zStart - 56),
			Color = Color3.fromRGB(48, 52, 68),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		for lb = -2, 2 do
			makePart({
				Name = "Stage5LaserBar_" .. tostring(lb),
				Size = Vector3.new(0.45, 10.5, 0.45),
				Position = Vector3.new(26 + lb * 2.2, 5.5, zStart - 48.8),
				Color = Color3.fromRGB(255, 35, 45),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = landmarksFolder,
			})
		end

		-- 3. Dedicated Right-Side Signature Landmark #1: Levitating Cyber-Crystal Monolith Ring (X = 64, zNorth)
		for m = 0, 5 do
			local rad = math.rad(m * 60)
			makePart({
				Name = "CrystalMonolith_" .. tostring(m),
				Size = Vector3.new(3.4, 18, 3.4),
				CFrame = CFrame.new(64 + math.cos(rad) * 8.5, 9.5, zNorth + math.sin(rad) * 8.5) * CFrame.Angles(math.rad(12), rad, 0),
				Color = Color3.fromRGB(85, 225, 255),
				Material = Enum.Material.Neon,
				Parent = landmarksFolder,
			})
		end
		local coreCrystal = makePart({
			Name = "CyberMonolithCore",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(6.8, 6.8, 6.8),
			Position = Vector3.new(64, 14.5, zNorth),
			Color = Color3.fromRGB(225, 115, 255),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = obstaclesFolder,
		})
		coreCrystal:SetAttribute("SpinSpeed", 1.8)

		-- 4. Dedicated Right-Side Signature Landmark #2: Glowing Hollow Geode Archway (X = 64, zSouth)
		makePart({
			Name = "GeodeArchLeft",
			Size = Vector3.new(4.5, 17, 5.5),
			CFrame = CFrame.new(57.5, 8.5, zSouth) * CFrame.Angles(0, 0, math.rad(-10)),
			Color = Color3.fromRGB(165, 75, 255),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "GeodeArchRight",
			Size = Vector3.new(4.5, 17, 5.5),
			CFrame = CFrame.new(70.5, 8.5, zSouth) * CFrame.Angles(0, 0, math.rad(10)),
			Color = Color3.fromRGB(165, 75, 255),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "GeodeArchCrown",
			Size = Vector3.new(18, 4.5, 5.8),
			Position = Vector3.new(64, 18.0, zSouth),
			Color = Color3.fromRGB(95, 225, 255),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})

		-- 5. Moving Crystal Platforms (X = 46, Z = zStart - 36..-90) + Creator Store Crystals (X = 72)
		for c = 1, 4 do
			local cz = zStart - 24 - (c * 16)
			local baseY = 2.5 + c * 1.5
			local cPlat = makePart({
				Name = "CrystalPlatform_" .. tostring(c),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1.8, 7.8, 7.8),
				CFrame = CFrame.new(46, baseY, cz) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(85, 235, 255),
				Material = Enum.Material.Neon,
				Parent = obstaclesFolder,
			})
			cPlat:SetAttribute("CrystalPlatform", c)
			cPlat:SetAttribute("BaseX", 46)
			cPlat:SetAttribute("BaseY", baseY)
			cPlat:SetAttribute("BaseZ", cz)
		end
		placePrebuiltAsset("Crystals", 1, landmarksFolder, Vector3.new(72, 0, zStart - 68), 15, 24.0, true)

	elseif id == 6 then
		-- =========================================================================================
		-- STAGE 6 (CLOUD SKY SANCTUARY):
		-- Floating Rainbow Cloud Lagoon + Starlight Balance Bridge, Golden Sky Pillar Steps,
		-- Rotating Celestial Sun-Dial Observatory (X = 64, zNorth), Angelic Sky Temple Dome (X = 64, zSouth),
		-- and Cloud Bounce Pads (X = 46)!
		-- =========================================================================================

		-- 1. Glowing Sky Mirror Pool + Golden Starlight Bridge at X = -14, Z = zStart - 56
		makePart({
			Name = "SkyMirrorPool",
			Size = Vector3.new(38, 0.6, 30),
			Position = Vector3.new(-14, 0.15, zStart - 56),
			Color = Color3.fromRGB(155, 225, 255),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "StarlightBalanceBridge",
			Size = Vector3.new(5.5, 1.2, 28),
			Position = Vector3.new(-14, 1.8, zStart - 56),
			Color = Color3.fromRGB(255, 230, 105),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})

		-- 2. Golden Marble Pillar Climb at X = 24, Z = zStart - 56
		for p = 1, 5 do
			makePart({
				Name = "SkySanctuaryPillar_" .. tostring(p),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(3.5 + p * 2.5, 5.5, 5.5),
				CFrame = CFrame.new(20 + (p % 2) * 8, (3.5 + p * 2.5) * 0.5, (zStart - 42) - p * 5.5) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(248, 250, 255),
				Material = Enum.Material.Marble,
				Parent = landmarksFolder,
			})
		end

		-- 3. Dedicated Right-Side Signature Landmark #1: Celestial Sun-Dial Observatory (X = 64, zNorth)
		makePart({
			Name = "CelestialObservatoryBase",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(10, 16, 16),
			CFrame = CFrame.new(64, 5.0, zNorth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(245, 248, 255),
			Material = Enum.Material.Marble,
			Parent = landmarksFolder,
		})
		local sunRing = makePart({
			Name = "CelestialSunRing",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.2, 18, 18),
			CFrame = CFrame.new(64, 18.5, zNorth),
			Color = Color3.fromRGB(255, 225, 75),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = obstaclesFolder,
		})
		sunRing:SetAttribute("SpinSpeed", 1.6)

		-- 4. Dedicated Right-Side Signature Landmark #2: Angelic Sky Temple Dome (X = 64, zSouth)
		makePart({
			Name = "SkyTempleFloor",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.0, 18, 18),
			CFrame = CFrame.new(64, 1.0, zSouth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(245, 248, 255),
			Material = Enum.Material.Marble,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "SkyTempleGoldenDome",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(16, 14, 16),
			Position = Vector3.new(64, 13.5, zSouth),
			Color = Color3.fromRGB(255, 225, 95),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})

		-- 5. Cloud Bounce Course (X = 46, Z = zStart - 36..-90)
		for c = 1, 4 do
			local cz = zStart - 24 - (c * 16)
			local cloudBounce = buildGlowingNeonCircle(
				landmarksFolder,
				"BouncePad",
				Vector3.new(46, 1.5 + c * 0.6, cz),
				6.6,
				Color3.fromRGB(135, 220, 255),
				Color3.fromRGB(255, 235, 95)
			)
			cloudBounce:SetAttribute("BounceImpulse", 96)
		end
		placePrebuiltAsset("Crystals", 2, landmarksFolder, Vector3.new(72, 0, zStart - 68), 30, 24.0, true)

	elseif id == 7 then
		-- =========================================================================================
		-- STAGE 7 (MAGMA VOLCANO DOOM):
		-- Dedicated Right-Side Signature Landmarks: Giant Erupting Magma Volcano Crater +
		-- Obsidian Anvil Forge + Lava Geyser Jump Pads + Creator Store Volcano Rocks,
		-- plus Stepped Basalt-and-Lava Cliff Hill & Tall Metal Truss Ladder Tower (`fts_frame_05.png`)!
		-- =========================================================================================

		-- 1. Stepped Basalt-and-Magma Cliff Hill + Tall Climbable Truss Tower (`fts_frame_05.png`) at X = -18, Z = zStart - 54
		buildSteppedDirtGrassHill(
			landmarksFolder,
			Vector3.new(-18, 0, zStart - 54),
			24,
			22,
			3,
			Color3.fromRGB(255, 85, 25),
			Color3.fromRGB(48, 38, 46)
		)
		local truss = Instance.new("TrussPart")
		truss.Name = "VolcanoClimbTruss"
		truss.Anchored = true
		truss.Size = Vector3.new(2, 24, 2)
		truss.Position = Vector3.new(-4, 12, zStart - 54)
		truss.Color = Color3.fromRGB(95, 98, 115)
		truss.Material = Enum.Material.Metal
		truss.Parent = landmarksFolder

		-- 2. Boiling Magma Pool + Narrow Basalt Balance Bridge at X = 22, Z = zStart - 56
		makePart({
			Name = "CalderaMagmaPool",
			Size = Vector3.new(26, 0.8, 32),
			Position = Vector3.new(22, 0.2, zStart - 56),
			Color = Color3.fromRGB(255, 75, 20),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "CalderaBasaltBridge",
			Size = Vector3.new(4.2, 1.2, 30),
			Position = Vector3.new(22, 2.2, zStart - 56),
			Color = Color3.fromRGB(58, 48, 56),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})

		-- 3. Dedicated Right-Side Signature Landmark #1: Giant Erupting Magma Volcano Crater (X = 64, zNorth)
		makePart({
			Name = "VolcanoCone",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(20, 24, 24),
			CFrame = CFrame.new(64, 10, zNorth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(48, 36, 44),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "MagmaPoolTop",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.8, 15, 15),
			CFrame = CFrame.new(64, 20.2, zNorth) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 85, 20),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		for ep = 1, 3 do
			makePart({
				Name = "MagmaEruptionPlume_" .. tostring(ep),
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(4.5 - ep * 0.6, 4.5 - ep * 0.6, 4.5 - ep * 0.6),
				Position = Vector3.new(64 + (ep - 2) * 2.4, 22 + ep * 3.8, zNorth + (ep % 2) * 1.8),
				Color = Color3.fromRGB(255, 145, 35),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = landmarksFolder,
			})
		end

		-- 4. Dedicated Right-Side Signature Landmark #2: Sculpted Obsidian Anvil Forge & Molten Trough (X = 64, zSouth)
		makePart({
			Name = "ObsidianAnvilBase",
			Size = Vector3.new(14, 5.5, 8.5),
			Position = Vector3.new(64, 2.75, zSouth),
			Color = Color3.fromRGB(36, 36, 46),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "ObsidianAnvilHorn",
			Size = Vector3.new(18, 4.2, 6.8),
			Position = Vector3.new(64, 7.6, zSouth),
			Color = Color3.fromRGB(52, 52, 66),
			Material = Enum.Material.Plastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "ForgeMoltenLavaStrip",
			Size = Vector3.new(14, 0.6, 3.2),
			Position = Vector3.new(64, 9.9, zSouth),
			Color = Color3.fromRGB(255, 95, 25),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})

		-- 5. Lava Geyser Jump Pads (X = 46, Z = zStart - 36..-90) + Creator Store Volcano Rocks (X = 72)
		for g = 1, 4 do
			local gz = zStart - 24 - (g * 16)
			local geyser = buildGlowingNeonCircle(
				landmarksFolder,
				"BouncePad",
				Vector3.new(46, 0.8, gz),
				6.8,
				Color3.fromRGB(255, 85, 25),
				Color3.fromRGB(255, 225, 65)
			)
			geyser:SetAttribute("BounceImpulse", 108)
		end
		placePrebuiltAsset("VolcanoRocks", 1, landmarksFolder, Vector3.new(72, 0, zStart - 68), 75, 24.0, true)

	else
		-- =========================================================================================
		-- STAGE 8 (COSMIC VOID CITADEL):
		-- Zero-Gravity Nebula Rift Pool + Starlight Conduit Bridge, Quantum Forcefield Vault,
		-- Rotating Black Hole Singularity Reactor (X = 64, zNorth), Astral Citadel Stargate Arch (X = 64, zSouth),
		-- and Levitating Asteroid Jump Pads (X = 46)!
		-- =========================================================================================

		-- 1. Zero-Gravity Nebula Rift Pool + Starlight Conduit Bridge at X = -14, Z = zStart - 56
		makePart({
			Name = "CosmicNebulaPool",
			Size = Vector3.new(38, 0.8, 30),
			Position = Vector3.new(-14, 0.2, zStart - 56),
			Color = Color3.fromRGB(185, 55, 255),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "CosmicConduitBridge",
			Size = Vector3.new(5.5, 1.2, 28),
			Position = Vector3.new(-14, 2.0, zStart - 56),
			Color = Color3.fromRGB(85, 245, 255),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})

		-- 2. Quantum Forcefield Citadel Vault at X = 26, Z = zStart - 56
		makePart({
			Name = "QuantumCitadelVault",
			Size = Vector3.new(16, 14, 14),
			Position = Vector3.new(26, 7.0, zStart - 56),
			Color = Color3.fromRGB(28, 18, 48),
			Material = Enum.Material.Basalt,
			Parent = landmarksFolder,
		})
		for qb = -2, 2 do
			makePart({
				Name = "QuantumLaserBar_" .. tostring(qb),
				Size = Vector3.new(0.5, 11.5, 0.5),
				Position = Vector3.new(26 + qb * 2.2, 6.0, zStart - 48.8),
				Color = Color3.fromRGB(85, 245, 255),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = landmarksFolder,
			})
		end

		-- 3. Dedicated Right-Side Signature Landmark #1: Black Hole Singularity Reactor (X = 64, zNorth)
		local blackHoleCore = makePart({
			Name = "SingularityCore",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(11, 11, 11),
			Position = Vector3.new(64, 14.5, zNorth),
			Color = Color3.fromRGB(16, 8, 28),
			Material = Enum.Material.SmoothPlastic,
			Parent = landmarksFolder,
		})
		local accretionDisk = makePart({
			Name = "AccretionDiskRing",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.6, 22, 22),
			CFrame = CFrame.new(64, 14.5, zNorth) * CFrame.Angles(math.rad(25), 0, math.rad(75)),
			Color = Color3.fromRGB(235, 75, 255),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = obstaclesFolder,
		})
		accretionDisk:SetAttribute("SpinSpeed", 2.4)

		-- 4. Dedicated Right-Side Signature Landmark #2: Astral Citadel Stargate Arch (X = 64, zSouth)
		for sIdx = 0, 7 do
			local ang = math.rad(sIdx * 45)
			makePart({
				Name = "StargateSegment_" .. tostring(sIdx),
				Size = Vector3.new(3.8, 3.8, 5.5),
				Position = Vector3.new(64 + math.cos(ang) * 9.0, 11.5 + math.sin(ang) * 9.0, zSouth),
				Color = if sIdx % 2 == 0 then Color3.fromRGB(195, 65, 255) else Color3.fromRGB(85, 245, 255),
				Material = Enum.Material.Neon,
				Parent = landmarksFolder,
			})
		end

		-- 5. Cosmic Void Geyser Jump Pads (X = 46, Z = zStart - 36..-90)
		for g = 1, 4 do
			local gz = zStart - 24 - (g * 16)
			local voidPad = buildGlowingNeonCircle(
				landmarksFolder,
				"BouncePad",
				Vector3.new(46, 1.0, gz),
				6.8,
				Color3.fromRGB(195, 65, 255),
				Color3.fromRGB(85, 245, 255)
			)
			voidPad:SetAttribute("BounceImpulse", 112)
		end
		placePrebuiltAsset("Crystals", 3, landmarksFolder, Vector3.new(72, 0, zStart - 68), 60, 25.0, true)
	end

	-- Chapter 1 & 4 Interactive Respawning Golden Squishy Coins along Obbies, Landmark Courses, Center Courses & Outer Side Mazes (6 per Stage = 48 Total)!
	local coinSpots = {
		Vector3.new(-83, 13.8, zStart - 58), -- Left-Side Elevated Obby Coin #1
		Vector3.new(-72, 16.5, zStart - 80), -- Left-Side Elevated Obby Coin #2
		Vector3.new(54, 6.8, zStart - 48), -- Right-Side Landmark Course Coin #1
		Vector3.new(54, 8.2, zStart - 76), -- Right-Side Landmark Course Coin #2
		Vector3.new(-168, 3.2, zStart - 50), -- Left Outer Maze Coin
		Vector3.new(168, 3.2, zStart - 50), -- Right Outer Maze Coin
	}
	for cIdx, cPos in ipairs(coinSpots) do
		local coinPart = makePart({
			Name = string.format("WorldCoin_%d_%d", id, cIdx),
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.9, 3.8, 3.8),
			CFrame = CFrame.new(cPos),
			Color = Color3.fromRGB(255, 215, 45),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = obstaclesFolder,
		})
		coinPart:SetAttribute("WorldCoinPickup", true)
		coinPart:SetAttribute("CoinValue", 75 * id)
		coinPart:SetAttribute("MinCoinValue", 50 * id)
		coinPart:SetAttribute("MaxCoinValue", 125 * id)
		coinPart:SetAttribute("SpinSpeed", 2.2)

		local sfx = Instance.new("Sound")
		sfx.Name = "CoinChime"
		sfx.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sfx.Volume = 0.55
		sfx.Parent = coinPart
	end

	-- Chapter 1 & 4 Timed Co-Op / Solo Bridge & Gate Button (Duration attribute + live visual countdown!)
	local btnPad = buildGlowingNeonCircle(
		landmarksFolder,
		"ShortcutBridgeButton_" .. tostring(id),
		Vector3.new(0, 0.45, zStart - 13),
		6.2,
		Color3.fromRGB(85, 255, 130),
		Color3.fromRGB(255, 235, 75)
	)
	btnPad:SetAttribute("ShortcutButtonLevel", id)
	btnPad:SetAttribute("Duration", 12)

	local btnBB = createBillboardText(
		btnPad,
		"🌉 SHORTCUT BRIDGE BUTTON\n[Step to Open Bridge for 12s]",
		Color3.fromRGB(95, 255, 145),
		Vector3.new(0, 3.4, 0),
		UDim2.new(6.2, 0, 1.5, 0),
		40
	)
	btnBB.Name = "ShortcutButtonTag"

	local centerBridge = makePart({
		Name = "ShortcutCenterBridge_" .. tostring(id),
		Size = Vector3.new(16, 1.4, 20),
		Position = Vector3.new(0, 1.25, zStart - 24),
		Color = Color3.fromRGB(255, 215, 65),
		Material = Enum.Material.Neon,
		Transparency = 0.72,
		CanCollide = false,
		Parent = obstaclesFolder,
	})
	centerBridge:SetAttribute("ShortcutBridgeLevel", id)
end

-- Builds 4 Widely Spaced Fenced Player Base Plots + South Village Boulevard in the Expanded Safe Zone (490 x 240, Z = 0..238)
local function buildSafeZoneAndPlots(worldFolder: Folder, obstaclesFolder: Folder)
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "SafeZoneHub"
	hubFolder.Parent = worldFolder

	makePart({
		Name = "HubGrassMain",
		Size = Vector3.new(490, 2, 240),
		Position = Vector3.new(0, -1, 118),
		Color = Color3.fromRGB(88, 198, 78),
		Material = Enum.Material.LeafyGrass,
		Parent = hubFolder,
	})

	for xTile = -144, 144, 24 do
		for zTile = 16, 184, 24 do
			if ((math.floor((xTile + 144) / 24) + math.floor(zTile / 24)) % 2) == 0 then
				makePart({
					Name = "CheckeredTile",
					Size = Vector3.new(24, 0.12, 24),
					Position = Vector3.new(xTile, 0.06, zTile),
					Color = Color3.fromRGB(72, 178, 64),
					Material = Enum.Material.SmoothPlastic,
					CanCollide = false,
					Parent = hubFolder,
				})
			end
		end
	end

	-- Wide Central Stone Boulevard running North-South (X = -22..+22, Z = 0..192)
	makePart({
		Name = "CentralPath",
		Size = Vector3.new(44, 0.25, 196),
		Position = Vector3.new(0, 0.12, 98),
		Color = Color3.fromRGB(228, 214, 185),
		Material = Enum.Material.Cobblestone,
		Parent = hubFolder,
	})

	-- Wide South Village Cross-Boulevard (Z = 178, X = -190..+190)
	makePart({
		Name = "SouthBoulevardPath",
		Size = Vector3.new(380, 0.25, 24),
		Position = Vector3.new(0, 0.12, 178),
		Color = Color3.fromRGB(228, 214, 185),
		Material = Enum.Material.Cobblestone,
		Parent = hubFolder,
	})

	local existingSpawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if not existingSpawn then
		local spawnLoc = Instance.new("SpawnLocation")
		spawnLoc.Name = "SpawnLocation"
		spawnLoc.Anchored = true
		spawnLoc.Size = Vector3.new(14, 1, 14)
		spawnLoc.CFrame = CFrame.new(0, 0.5, 86)
		spawnLoc.Neutral = true
		spawnLoc.Transparency = 1
		spawnLoc.CanCollide = false
		spawnLoc.Parent = Workspace
	else
		existingSpawn.CFrame = CFrame.new(0, 0.5, 86)
		existingSpawn.Transparency = 1
		existingSpawn.CanCollide = false
	end

	local fountainModel = placePrebuiltAsset("HubFountain", 1, hubFolder, Vector3.new(0, 0, 162), 0, 14.0, true)
	local fountainTop = makePart({
		Name = "FountainSignAnchor",
		Size = Vector3.new(2, 2, 2),
		Position = Vector3.new(0, 15, 162),
		Transparency = 1,
		CanCollide = false,
		Parent = fountainModel or hubFolder,
	})
	createBillboardText(
		fountainTop,
		"🥚 FIND MY SQUISHY! [117 SQUISHIES]\nEnter Stage 1 Ahead -> Steal Boss Eggs & Grab 117 Squishies Across Stages 1-8!",
		Color3.fromRGB(255, 235, 90),
		Vector3.new(0, 2.5, 0),
		UDim2.new(11.5, 0, 2.4, 0),
		75
	)

	-- Frame the South Boulevard (Z = 202) with 4 Widely Spaced Properly Colored Houses!
	local borderHouses = {
		{ Pos = Vector3.new(-118, 0, 202), Yaw = 0, Wall = Color3.fromRGB(255, 205, 105), Roof = Color3.fromRGB(215, 58, 55), Idx = 1, H = 24 },
		{ Pos = Vector3.new(118, 0, 202), Yaw = 0, Wall = Color3.fromRGB(135, 212, 255), Roof = Color3.fromRGB(52, 96, 218), Idx = 2, H = 24 },
		{ Pos = Vector3.new(-44, 0, 202), Yaw = 0, Wall = Color3.fromRGB(255, 165, 205), Roof = Color3.fromRGB(185, 52, 138), Idx = 3, H = 23 },
		{ Pos = Vector3.new(44, 0, 202), Yaw = 0, Wall = Color3.fromRGB(162, 238, 158), Roof = Color3.fromRGB(48, 158, 82), Idx = 4, H = 23 },
	}
	for _, bh in ipairs(borderHouses) do
		buildBigCartoonHouse(hubFolder, bh.Pos, bh.Yaw, bh.Wall, bh.Roof, bh.Idx, bh.H, 1)
	end

	-- Build the Authentic "Find The Squishies" Town Street (McBurger's, Squishy Market, Bus Stop, Red Shipping Container & Laser Vault)!
	buildFindTheSquishiesTownStreet(hubFolder, obstaclesFolder)

	-- Build the Giant Rainbow Disappearing Staircase on Stage 1's dedicated Outer West Sky Plaza (X = -236, Z = -20..-148)!
	buildRainbowDisappearingStaircase(worldFolder)

	-- Build Global Top-10 OrderedDataStore 3D Leaderboards + Spin Wheel, Daily Chest & VIP Robux Shop Booths!
	buildHubRetentionBoothsAndLeaderboards(hubFolder, obstaclesFolder)

	-- Build the 4 Widely Spaced Fenced Player Base Plots (X = ±94, Z = 54 & 136 — 188 studs across road, 82 studs North-to-South!)
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "PlayerPlots"
	plotsFolder.Parent = worldFolder

	local plotConfigs = {
		{ Index = 1, Center = Vector3.new(-94, 0, 54), Color = Color3.fromRGB(80, 190, 255), Roof = Color3.fromRGB(45, 95, 210), FaceDir = 1 },
		{ Index = 2, Center = Vector3.new(94, 0, 54), Color = Color3.fromRGB(255, 140, 195), Roof = Color3.fromRGB(190, 52, 135), FaceDir = -1 },
		{ Index = 3, Center = Vector3.new(-94, 0, 136), Color = Color3.fromRGB(125, 235, 135), Roof = Color3.fromRGB(48, 155, 78), FaceDir = 1 },
		{ Index = 4, Center = Vector3.new(94, 0, 136), Color = Color3.fromRGB(255, 205, 90), Roof = Color3.fromRGB(215, 68, 55), FaceDir = -1 },
	}

	local plotW = 58
	local plotD = 44

	for _, cfg in ipairs(plotConfigs) do
		local plotModel = Instance.new("Model")
		plotModel.Name = "Plot_" .. tostring(cfg.Index)
		plotModel:SetAttribute("PlotIndex", cfg.Index)
		plotModel.Parent = plotsFolder

		local basePad = makePart({
			Name = "BasePad",
			Size = Vector3.new(plotW, 0.5, plotD),
			Position = cfg.Center + Vector3.new(0, 0.25, 0),
			Color = Color3.fromRGB(98, 212, 85),
			Material = Enum.Material.SmoothPlastic,
			Parent = plotModel,
		})
		plotModel.PrimaryPart = basePad

		-- Chapter 4 Procedural Picket Fences around the North, South, and Outer Back edges of each Plot!
		local fenceColor = Color3.fromRGB(168, 112, 62)
		local picketColor = Color3.fromRGB(242, 232, 210)
		local cFrontNorth = cfg.Center + Vector3.new(cfg.FaceDir * (plotW * 0.5), 0.3, -plotD * 0.5)
		local cBackNorth = cfg.Center + Vector3.new(-cfg.FaceDir * (plotW * 0.5), 0.3, -plotD * 0.5)
		local cBackSouth = cfg.Center + Vector3.new(-cfg.FaceDir * (plotW * 0.5), 0.3, plotD * 0.5)
		local cFrontSouth = cfg.Center + Vector3.new(cfg.FaceDir * (plotW * 0.5), 0.3, plotD * 0.5)

		buildProceduralPicketFence(plotModel, cFrontNorth, cBackNorth, 3.0, fenceColor, picketColor)
		buildProceduralPicketFence(plotModel, cBackNorth, cBackSouth, 3.0, fenceColor, picketColor)
		buildProceduralPicketFence(plotModel, cBackSouth, cFrontSouth, 3.0, fenceColor, picketColor)

		-- Chapter 2 Rule: Physical 3D Plot Signboard with SurfaceGui (No floating billboard clutter!)
		makePart({
			Name = "OwnerSignPole",
			Size = Vector3.new(1.1, 5.2, 1.1),
			Position = cfg.Center + Vector3.new(cfg.FaceDir * (plotW * 0.42), 2.8, -plotD * 0.44),
			Color = fenceColor,
			Material = Enum.Material.WoodPlanks,
			Parent = plotModel,
		})
		local signPost = makePart({
			Name = "OwnerSign",
			Size = Vector3.new(11.0, 4.2, 1.2),
			Position = cfg.Center + Vector3.new(cfg.FaceDir * (plotW * 0.42), 6.6, -plotD * 0.44),
			Color = cfg.Color,
			Material = Enum.Material.SmoothPlastic,
			Parent = plotModel,
		})
		createSurfaceSign(
			signPost,
			"🏠 PLOT #" .. tostring(cfg.Index) .. "\n(Unclaimed Ranch)",
			cfg.Color,
			Color3.fromRGB(22, 26, 44),
			{ Enum.NormalId.Back, Enum.NormalId.Front },
			180
		)

		-- Properly Colored Player Base House placed cleanly at the Outer Back Edge (-cfg.FaceDir * 22) with zero crate clutter!
		buildBigCartoonHouse(
			plotModel,
			cfg.Center + Vector3.new(-cfg.FaceDir * 22, 0.5, 10),
			if cfg.FaceDir > 0 then 90 else -90,
			cfg.Color,
			cfg.Roof,
			cfg.Index,
			21,
			1
		)

		-- 1. Giant 18-Stud Green Dino-Jaw Speed Treadmill
		local treadCenter = cfg.Center + Vector3.new(-cfg.FaceDir * 9, 0.5, -10.5)
		buildDinoJawTreadmill(plotModel, treadCenter, cfg.FaceDir, cfg.Index)

		-- 2. Newer Concentric Glowing Green Cash Collector Circle (Clean pad with zero blocky chest box clutter!)
		local collectPad = buildGlowingNeonCircle(
			plotModel,
			"CollectCashPad",
			cfg.Center + Vector3.new(cfg.FaceDir * 21, 0.6, -14.0),
			7.4,
			Color3.fromRGB(65, 250, 115),
			Color3.fromRGB(255, 235, 85)
		)
		createBillboardText(
			collectPad,
			"💰 COLLECT $0\n(Step Here)",
			Color3.fromRGB(95, 255, 130),
			Vector3.new(0, 4.2, 0),
			UDim2.new(6.5, 0, 1.6, 0),
			42
		)

		-- 3. Newer Concentric Glowing Cyan Speed Upgrade Circle (Attachment-based ProximityPrompt!)
		local upgStand = buildGlowingNeonCircle(
			plotModel,
			"SpeedUpgradeStand",
			cfg.Center + Vector3.new(cfg.FaceDir * 21, 0.7, 14.0),
			6.2,
			Color3.fromRGB(65, 215, 255),
			Color3.fromRGB(185, 110, 255)
		)
		createAttachmentPrompt(upgStand, "UpgradeSpeedPrompt", "Upgrade Treadmill (+Speed)", "🦖 Cost: $50", Vector3.new(0, 2.5, 0), 14)

		-- 4. Fenced Squishy Hatchery & Roaming Ranch Pen (`HatcheryPen` — Walk-In Auto-Drop, Hatch Timer 00:05 -> Live Roaming & Growing Squishies!)
		local penCenter = cfg.Center + Vector3.new(cfg.FaceDir * 6.5, 0.55, 5.0)
		local penW = 23.0
		local penD = 19.5

		local hatcheryPen = Instance.new("Model")
		hatcheryPen.Name = "HatcheryPen"
		hatcheryPen:SetAttribute("PlotIndex", cfg.Index)
		hatcheryPen.Parent = plotModel

		local penFloor = makePart({
			Name = "HatcheryPenFloor",
			Size = Vector3.new(penW, 0.32, penD),
			Position = penCenter,
			Color = Color3.fromRGB(115, 228, 95),
			Material = Enum.Material.Grass,
			Parent = hatcheryPen,
		})
		hatcheryPen.PrimaryPart = penFloor

		-- Glowing Golden Walk-In Auto-Drop Trigger Zone inside the Fenced Pen
		local dropZone = makePart({
			Name = "HatcheryDropZone",
			Size = Vector3.new(penW - 1.2, 0.4, penD - 1.2),
			Position = penCenter + Vector3.new(0, 0.08, 0),
			Color = Color3.fromRGB(255, 225, 75),
			Material = Enum.Material.Neon,
			Transparency = 0.78,
			CanCollide = false,
			Parent = hatcheryPen,
		})
		dropZone:SetAttribute("PlotIndex", cfg.Index)

		-- 4-Sided White & Gold Ranch Picket Enclosure around the Hatchery Pen (with wide walk-in Front Gate opening!)
		local penFenceRailCol = Color3.fromRGB(255, 205, 65)
		local penFencePicketCol = Color3.fromRGB(250, 248, 240)
		local pFN = penCenter + Vector3.new(cfg.FaceDir * (penW * 0.5), 0.1, -penD * 0.5)
		local pBN = penCenter + Vector3.new(-cfg.FaceDir * (penW * 0.5), 0.1, -penD * 0.5)
		local pBS = penCenter + Vector3.new(-cfg.FaceDir * (penW * 0.5), 0.1, penD * 0.5)
		local pFS = penCenter + Vector3.new(cfg.FaceDir * (penW * 0.5), 0.1, penD * 0.5)
		local pGateNorth = penCenter + Vector3.new(cfg.FaceDir * (penW * 0.5), 0.1, -4.2)
		local pGateSouth = penCenter + Vector3.new(cfg.FaceDir * (penW * 0.5), 0.1, 4.2)

		buildProceduralPicketFence(hatcheryPen, pFN, pBN, 2.6, penFenceRailCol, penFencePicketCol)
		buildProceduralPicketFence(hatcheryPen, pBN, pBS, 2.6, penFenceRailCol, penFencePicketCol)
		buildProceduralPicketFence(hatcheryPen, pBS, pFS, 2.6, penFenceRailCol, penFencePicketCol)
		buildProceduralPicketFence(hatcheryPen, pFN, pGateNorth, 2.6, penFenceRailCol, penFencePicketCol)
		buildProceduralPicketFence(hatcheryPen, pGateSouth, pFS, 2.6, penFenceRailCol, penFencePicketCol)

		-- Ranch Archway Gate & Overhead Sign at the Front Entrance of the Hatchery Pen
		for _, gateZ in ipairs({ -4.2, 4.2 }) do
			makePart({
				Name = "HatcheryGatePost",
				Size = Vector3.new(1.2, 8.8, 1.2),
				Position = penCenter + Vector3.new(cfg.FaceDir * (penW * 0.5), 4.4, gateZ),
				Color = penFenceRailCol,
				Material = Enum.Material.WoodPlanks,
				Parent = hatcheryPen,
			})
		end
		local gateHeader = makePart({
			Name = "HatcheryGateArch",
			Size = Vector3.new(1.4, 2.8, 10.6),
			Position = penCenter + Vector3.new(cfg.FaceDir * (penW * 0.5), 9.4, 0),
			Color = Color3.fromRGB(32, 38, 64),
			Material = Enum.Material.SmoothPlastic,
			Parent = hatcheryPen,
		})
		createSurfaceSign(
			gateHeader,
			"🥚 SQUISHY HATCHERY & RANCH PEN\nWalk In With Eggs -> Hatch & Roam Inside Fence!",
			Color3.fromRGB(255, 235, 85),
			Color3.fromRGB(24, 30, 52),
			{ Enum.NormalId.Left, Enum.NormalId.Right },
			150
		)

		-- 🌱 Grow & Level Up Station Kiosk right next to the Hatchery Pen Entrance
		local growStand = buildGlowingNeonCircle(
			hatcheryPen,
			"GrowSquishyStand",
			penCenter + Vector3.new(cfg.FaceDir * (penW * 0.5 + 2.2), 0.15, -6.8),
			4.6,
			Color3.fromRGB(95, 245, 135),
			Color3.fromRGB(255, 225, 75)
		)
		createAttachmentPrompt(
			growStand,
			"UpgradeSquishyPenPrompt",
			"🌱 Grow & Level Up Squishy (+$/s & Size!)",
			"🏡 Squishy Ranch Grow Station",
			Vector3.new(0, 2.4, 0),
			14
		)

		-- 5 Cozy Golden Hatching Nests inside the Front Edge of the Fenced Pen (`Incubators` / `Incubator_1..5`)
		local incubatorsFolder = Instance.new("Folder")
		incubatorsFolder.Name = "Incubators"
		incubatorsFolder.Parent = plotModel

		for incIdx = 1, 5 do
			local zOff = -3.0 + (incIdx - 1) * 4.0
			local incPos = cfg.Center + Vector3.new(cfg.FaceDir * 14.5, 0.6, zOff)

			local incPad = buildGlowingNeonCircle(
				incubatorsFolder,
				"Incubator_" .. tostring(incIdx),
				incPos,
				3.8,
				Color3.fromRGB(195, 75, 255),
				Color3.fromRGB(255, 220, 85)
			)
			incPad:SetAttribute("IncubatorIndex", incIdx)
			incPad:SetAttribute("State", "Empty")

			createAttachmentPrompt(
				incPad,
				"IncubatorPrompt",
				"Drop Egg in Hatchery Nest",
				"Hatchery Nest #" .. tostring(incIdx),
				Vector3.new(0, 2.2, 0),
				14
			)
		end

		-- 12 Roaming Ranch Pasture Spots inside the Fenced Hatchery Pen (`Pedestals` / `Pedestal_1..12`)
		local pedestalsFolder = Instance.new("Folder")
		pedestalsFolder.Name = "Pedestals"
		pedestalsFolder.Parent = plotModel

		local slotIndex = 1
		for row = 1, 3 do
			for col = 1, 4 do
				local xOff = cfg.FaceDir * (9.5 - (row - 1) * 5.2)
				local zOff = -2.2 + (col - 1) * 4.6
				local pedPos = cfg.Center + Vector3.new(xOff, 0.58, zOff)

				local ped = buildGlowingNeonCircle(
					pedestalsFolder,
					"Pedestal_" .. tostring(slotIndex),
					pedPos,
					3.4,
					Color3.fromRGB(85, 245, 145),
					cfg.Color
				)
				ped:SetAttribute("SlotIndex", slotIndex)
				createAttachmentPrompt(
					ped,
					"PlaceSquishyPrompt",
					"Release Squishy in Ranch Pen",
					"Ranch Pen Slot #" .. tostring(slotIndex),
					Vector3.new(0, 2.2, 0),
					13
				)
				slotIndex += 1
			end
		end
	end
end

-- Builds the Expanded Themed Obby Gauntlet + Properly Colored Biome Village Houses + Wide Boss Egg Nest in each 296 x 160 Biome Arena
local function buildBiomeArenaContent(parent: Instance, levelInfo: any, obstaclesFolder: Folder)
	local id = levelInfo.Id or levelInfo.Level or 1
	local zStart = levelInfo.ZStart
	local zEnd = levelInfo.ZEnd
	local zBoss = zStart - 116
	local secColor = levelInfo.SecondaryColor or levelInfo.ThemeColor or Color3.fromRGB(120, 220, 120)

	-- 1. Front Hazard Moat + Procedural Plank Bridges at zStart - 24
	local moatZ = zStart - 24
	local moatColor = if id == 1 then Color3.fromRGB(55, 175, 255)
		elseif id == 2 then Color3.fromRGB(255, 95, 175)
		elseif id == 3 then Color3.fromRGB(40, 210, 245)
		elseif id == 4 then Color3.fromRGB(65, 225, 135)
		elseif id == 5 then Color3.fromRGB(165, 75, 255)
		elseif id == 6 then Color3.fromRGB(135, 220, 255)
		elseif id == 7 then Color3.fromRGB(255, 75, 20)
		else Color3.fromRGB(205, 55, 255)

	local moat = makePart({
		Name = "HazardMoat_" .. tostring(id),
		Size = Vector3.new(196, 0.9, 16),
		Position = Vector3.new(0, 0.2, moatZ),
		Color = moatColor,
		Material = Enum.Material.Neon,
		Parent = obstaclesFolder,
	})
	moat:SetAttribute("HazardDropEgg", true)
	moat:SetAttribute("KnockbackImpulse", 55)

	for _, bridgeX in ipairs({ -48, 48 }) do
		buildProceduralPlankBridge(
			parent,
			Vector3.new(bridgeX, 0.2, moatZ),
			14,
			20,
			Color3.fromRGB(178, 122, 68),
			Color3.fromRGB(115, 74, 38)
		)
	end

	-- Build Sector 1 (Checklist Board + Treadmill Plaza Pad + Shortcut Button) & Sector 2 Landmarks!
	buildBiomeLandmarksAndInteractiveProps(parent, levelInfo, obstaclesFolder)

	-- 2. Dedicated Left-Side Elevated Biome Sky Obby Gauntlet (`full_frame_04.png`: White-and-Blue Sky Obby Beams, Truss Ladder & Crate Steps at X = -83 to -61, Z = zStart - 34 to zStart - 95) holding the Biome Obby Shining Squishies (#103-#117)!
	local obbyTruss = Instance.new("TrussPart")
	obbyTruss.Name = "ObbyStartTruss_" .. tostring(id)
	obbyTruss.Anchored = true
	obbyTruss.Size = Vector3.new(2, 12, 2)
	obbyTruss.Position = Vector3.new(-83, 6.0, zStart - 35)
	obbyTruss.Color = Color3.fromRGB(75, 145, 255)
	obbyTruss.Material = Enum.Material.Metal
	obbyTruss.Parent = parent

	for subIdx = 1, 3 do
		local xPos = -94 + subIdx * 11
		local yPos = 9.0 + subIdx * 2.8
		local zPos = zStart - 26 - subIdx * 22

		-- White-and-Blue Sky Obby Balance Beam + Stepping Pads (`full_frame_04.png`)
		if subIdx > 1 then
			local prevX = -94 + (subIdx - 1) * 11
			local prevY = 9.0 + (subIdx - 1) * 2.8
			local prevZ = zStart - 26 - (subIdx - 1) * 22
			local midPos = Vector3.new((prevX + xPos) * 0.5, (prevY + yPos) * 0.5 - 0.4, (prevZ + zPos) * 0.5)
			makePart({
				Name = string.format("SkyObbyWhiteBeam_%d", subIdx),
				Size = Vector3.new(2.2, 0.9, 14.5),
				CFrame = CFrame.lookAt(midPos, Vector3.new(xPos, yPos - 0.3, zPos)),
				Color = Color3.fromRGB(245, 248, 255),
				Material = Enum.Material.Plastic,
				Parent = parent,
			})
		end

		for step = 1, 3 do
			makePart({
				Name = string.format("ThemedObbyStep_%d_%d", subIdx, step),
				Size = Vector3.new(4.6, 1.4, 4.6),
				Position = Vector3.new(xPos + (step - 2) * 3.8, (yPos * step) / 3.4, zPos + (4 - step) * 4.0),
				Color = if step % 2 == 1 then Color3.fromRGB(45, 115, 245) else Color3.fromRGB(245, 248, 255),
				Material = Enum.Material.Plastic,
				Parent = parent,
			})
		end

		buildGlowingNeonCircle(
			parent,
			"ObbyGoalPlatform_" .. tostring(subIdx),
			Vector3.new(xPos, yPos - 0.3, zPos),
			8.5,
			secColor,
			Color3.fromRGB(255, 235, 85)
		)
	end

	-- Creator Store Obby Kit Stages on Left & Right approaches (X = ±78, Z = zStart - 28)
	placePrebuiltAsset("ObbyStages", ((id - 1) % 3) + 1, parent, Vector3.new(-78, 0, zStart - 28), 0, 11.0, true)
	placePrebuiltAsset("ObbyStages", (id % 3) + 1, parent, Vector3.new(78, 0, zStart - 28), 180, 11.0, true)

	-- 3. 4 Walk-Inside Biome Village Houses per Stage (32 Biome Houses total across Stages 1-8 at X = ±114, Z = zStart - 56 and Z = zStart - 94)!
	local biomeHouseConfigs: { [number]: { { Side: number, Wall: Color3, Roof: Color3, Z: number } } } = {
		[1] = {
			{ Side = -1, Wall = Color3.fromRGB(225, 78, 68), Roof = Color3.fromRGB(145, 42, 38), Z = -56 },
			{ Side = 1, Wall = Color3.fromRGB(255, 220, 115), Roof = Color3.fromRGB(65, 168, 82), Z = -56 },
			{ Side = -1, Wall = Color3.fromRGB(135, 215, 255), Roof = Color3.fromRGB(48, 102, 215), Z = -94 },
			{ Side = 1, Wall = Color3.fromRGB(255, 168, 212), Roof = Color3.fromRGB(192, 54, 138), Z = -94 },
		},
		[2] = {
			{ Side = -1, Wall = Color3.fromRGB(255, 175, 215), Roof = Color3.fromRGB(215, 55, 140), Z = -216 },
			{ Side = 1, Wall = Color3.fromRGB(155, 225, 255), Roof = Color3.fromRGB(65, 115, 235), Z = -216 },
			{ Side = -1, Wall = Color3.fromRGB(255, 225, 135), Roof = Color3.fromRGB(225, 115, 45), Z = -254 },
			{ Side = 1, Wall = Color3.fromRGB(205, 165, 255), Roof = Color3.fromRGB(125, 55, 215), Z = -254 },
		},
		[3] = {
			{ Side = -1, Wall = Color3.fromRGB(255, 195, 130), Roof = Color3.fromRGB(225, 95, 55), Z = -376 },
			{ Side = 1, Wall = Color3.fromRGB(130, 245, 225), Roof = Color3.fromRGB(35, 155, 165), Z = -376 },
			{ Side = -1, Wall = Color3.fromRGB(255, 235, 135), Roof = Color3.fromRGB(45, 165, 225), Z = -414 },
			{ Side = 1, Wall = Color3.fromRGB(255, 155, 175), Roof = Color3.fromRGB(215, 55, 85), Z = -414 },
		},
		[4] = {
			{ Side = -1, Wall = Color3.fromRGB(185, 245, 175), Roof = Color3.fromRGB(48, 165, 78), Z = -536 },
			{ Side = 1, Wall = Color3.fromRGB(245, 230, 185), Roof = Color3.fromRGB(215, 58, 52), Z = -536 },
			{ Side = -1, Wall = Color3.fromRGB(155, 235, 195), Roof = Color3.fromRGB(38, 145, 95), Z = -574 },
			{ Side = 1, Wall = Color3.fromRGB(215, 245, 155), Roof = Color3.fromRGB(65, 175, 68), Z = -574 },
		},
		[5] = {
			{ Side = -1, Wall = Color3.fromRGB(195, 155, 255), Roof = Color3.fromRGB(105, 52, 205), Z = -696 },
			{ Side = 1, Wall = Color3.fromRGB(125, 225, 255), Roof = Color3.fromRGB(45, 115, 215), Z = -696 },
			{ Side = -1, Wall = Color3.fromRGB(155, 135, 235), Roof = Color3.fromRGB(75, 42, 165), Z = -734 },
			{ Side = 1, Wall = Color3.fromRGB(225, 145, 255), Roof = Color3.fromRGB(145, 45, 195), Z = -734 },
		},
		[6] = {
			{ Side = -1, Wall = Color3.fromRGB(245, 250, 255), Roof = Color3.fromRGB(255, 215, 75), Z = -856 },
			{ Side = 1, Wall = Color3.fromRGB(225, 242, 255), Roof = Color3.fromRGB(95, 195, 255), Z = -856 },
			{ Side = -1, Wall = Color3.fromRGB(255, 242, 225), Roof = Color3.fromRGB(255, 145, 195), Z = -894 },
			{ Side = 1, Wall = Color3.fromRGB(235, 245, 255), Roof = Color3.fromRGB(165, 135, 255), Z = -894 },
		},
		[7] = {
			{ Side = -1, Wall = Color3.fromRGB(115, 78, 88), Roof = Color3.fromRGB(215, 65, 28), Z = -1016 },
			{ Side = 1, Wall = Color3.fromRGB(95, 75, 92), Roof = Color3.fromRGB(235, 78, 32), Z = -1016 },
			{ Side = -1, Wall = Color3.fromRGB(82, 68, 82), Roof = Color3.fromRGB(255, 115, 28), Z = -1054 },
			{ Side = 1, Wall = Color3.fromRGB(108, 68, 72), Roof = Color3.fromRGB(195, 42, 32), Z = -1054 },
		},
		[8] = {
			{ Side = -1, Wall = Color3.fromRGB(52, 32, 88), Roof = Color3.fromRGB(195, 55, 255), Z = -1176 },
			{ Side = 1, Wall = Color3.fromRGB(38, 42, 92), Roof = Color3.fromRGB(65, 225, 255), Z = -1176 },
			{ Side = -1, Wall = Color3.fromRGB(64, 28, 96), Roof = Color3.fromRGB(255, 65, 195), Z = -1214 },
			{ Side = 1, Wall = Color3.fromRGB(44, 34, 82), Roof = Color3.fromRGB(135, 85, 255), Z = -1214 },
		},
	}
	local housesForLvl = biomeHouseConfigs[id]
	if housesForLvl then
		for hIdx, hc in ipairs(housesForLvl) do
			buildBigCartoonHouse(
				parent,
				Vector3.new(hc.Side * 114, 0, hc.Z),
				if hc.Side < 0 then 90 else -90,
				hc.Wall,
				hc.Roof,
				id * 10 + hIdx,
				22,
				id
			)
		end
	end

	-- 4. Spinning Sweeper Knockback Bar at zStart - 86
	local spinnerPos = Vector3.new(0, 2.6, zStart - 86)
	makePart({
		Name = "SpinnerPost",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(5.2, 3.6, 3.6),
		CFrame = CFrame.new(spinnerPos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(55, 55, 70),
		Material = Enum.Material.Metal,
		Parent = obstaclesFolder,
	})
	local sweeper = makePart({
		Name = "SweeperBar_" .. tostring(id),
		Size = Vector3.new(42, 1.8, 1.8),
		Position = spinnerPos + Vector3.new(0, 0.4, 0),
		Color = Color3.fromRGB(255, 65, 95),
		Material = Enum.Material.Neon,
		Parent = obstaclesFolder,
	})
	sweeper:SetAttribute("SpinSpeed", (1.2 + id * 0.25) * (if id % 2 == 0 then 1 else -1))
	sweeper:SetAttribute("KnockbackImpulse", 75)
	sweeper:SetAttribute("HazardDropEgg", true)

	-- 2 Super Bounce Pads per Biome at X = ±44, Z = zStart - 88
	for _, bx in ipairs({ -44, 44 }) do
		local bPad = buildGlowingNeonCircle(
			parent,
			"BouncePad",
			Vector3.new(bx, 0.7, zStart - 88),
			8.0,
			Color3.fromRGB(255, 235, 55),
			Color3.fromRGB(255, 115, 45)
		)
		bPad:SetAttribute("BounceImpulse", 98)
	end

	-- 5. Sector 3: Concentric Glowing Boss Nest Arena Circle (146-stud diameter) under the 2 Giant Sleeping Bosses & Widened Egg Cluster
	buildGlowingNeonCircle(
		parent,
		"BossNestArenaPad",
		Vector3.new(0, 0.3, zBoss),
		146,
		secColor,
		secColor:Lerp(Color3.fromRGB(255, 255, 255), 0.35)
	)

	-- 6. Oversized 22-28 Stud Biome Scenery Framing the Expanded Arena (cleanly separated from Houses & Boss Nest!)
	local scenerySpots = {
		Vector3.new(-106, 0, zBoss - 8),
		Vector3.new(106, 0, zBoss - 8),
		Vector3.new(-96, 0, zEnd + 18),
		Vector3.new(96, 0, zEnd + 18),
		Vector3.new(-48, 0, zEnd + 16),
		Vector3.new(48, 0, zEnd + 16),
	}

	for idx, sPos in ipairs(scenerySpots) do
		local yaw = (idx * 53) % 360
		if id == 1 or id == 4 then
			placePrebuiltAsset("MeadowTrees", ((idx - 1) % 3) + 1, parent, sPos, yaw, 25.0, true)
		elseif id == 2 then
			placePrebuiltAsset("CandyProps", ((idx - 1) % 5) + 1, parent, sPos, yaw, 25.0, true)
		elseif id == 3 then
			placePrebuiltAsset("PalmTrees", ((idx - 1) % 3) + 1, parent, sPos, yaw, 26.0, true)
		elseif id == 5 or id == 6 or id == 8 then
			placePrebuiltAsset("Crystals", ((idx - 1) % 3) + 1, parent, sPos, yaw, 24.0, true)
		else
			placePrebuiltAsset("VolcanoRocks", ((idx - 1) % 3) + 1, parent, sPos, yaw, 25.0, true)
		end
	end
end

-- Builds an Open Sightline Castle Gate Archway between Biomes
local function buildLevelGate(parent: Instance, levelInfo: any, halfW: number): Part
	local id = levelInfo.Id or levelInfo.Level or 1
	local zPos = levelInfo.ZStart
	local gateColor = levelInfo.GateColor or levelInfo.ThemeColor or Color3.fromRGB(95, 215, 110)
	local secColor = levelInfo.SecondaryColor or levelInfo.ThemeColor or Color3.fromRGB(120, 230, 130)

	local gateModel = Instance.new("Model")
	gateModel.Name = "Gate_Level_" .. tostring(id)
	gateModel.Parent = parent

	local doorWidth = 48
	local sideWallWidth = halfW - (doorWidth * 0.5)

	for _, side in ipairs({ -1, 1 }) do
		if id > 1 then
			local xCenter = side * ((doorWidth * 0.5) + (sideWallWidth * 0.5))
			makePart({
				Name = "DividerFence",
				Size = Vector3.new(sideWallWidth, 4.5, 2.5),
				Position = Vector3.new(xCenter, 2.25, zPos),
				Color = gateColor,
				Material = Enum.Material.Cobblestone,
				Parent = gateModel,
			})
		end

		makePart({
			Name = "GatePillar",
			Size = Vector3.new(4.8, 20, 4.8),
			Position = Vector3.new(side * (doorWidth * 0.5), 10, zPos),
			Color = secColor,
			Material = Enum.Material.Cobblestone,
			Parent = gateModel,
		})
	end

	local header = makePart({
		Name = "GateHeader",
		Size = Vector3.new(doorWidth + 10, 5.2, 4.5),
		Position = Vector3.new(0, 21.8, zPos),
		Color = gateColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = gateModel,
	})

	local reqSpeed = levelInfo.RequiredSpeed or 0
	local reqText = if id <= 1
		then string.format("STAGE %d: %s (OPEN!)", id, string.upper(levelInfo.Name))
		else string.format(
			"STAGE %d: %s  [100%% STAGE %d + ⚡ %s SPEED]",
			id,
			string.upper(levelInfo.Name),
			id - 1,
			SlimeData.FormatNumber(reqSpeed)
		)

	createSurfaceSign(
		header,
		reqText,
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(20, 24, 42),
		{ Enum.NormalId.Back, Enum.NormalId.Front },
		260
	)

	-- Full-width 440-stud x 42-stud ForceField barrier across the central road, Castle Walls, and Outer Side Mazes
	-- so players cannot walk or jump around into a locked Stage before completing 100% of the previous Stage!
	local barrierWidth = if id <= 1 then (doorWidth - 2) else 440
	local barrierHeight = if id <= 1 then 18 else 42
	local barrier = makePart({
		Name = "GateBarrier_" .. tostring(id),
		Size = Vector3.new(barrierWidth, barrierHeight, 2.2),
		Position = Vector3.new(0, barrierHeight * 0.5, zPos),
		Color = gateColor,
		Material = Enum.Material.ForceField,
		Transparency = if id <= 1 then 1.0 else 0.45,
		CanCollide = id > 1,
		Parent = gateModel,
	})
	barrier:SetAttribute("LevelId", id)
	barrier:SetAttribute("RequiredCoins", levelInfo.RequiredCoins or 0)
	barrier:SetAttribute("RequiredSpeed", reqSpeed)

	return barrier
end

function WorldBuilder.BuildWorld(): {
	WorldFolder: Folder,
	GateBarriers: { [number]: Part },
	WorldEggs: { [string]: Model },
	Guardians: { [string]: { Model: Model, Data: any, LevelInfo: any } },
}
	setupVibrantLighting()
	PrebuiltLoader.EnsurePrebuiltAssets()

	local existing = Workspace:FindFirstChild("SquishyWorld")
	if existing then
		existing:Destroy()
	end

	local worldFolder = Instance.new("Folder")
	worldFolder.Name = "SquishyWorld"
	worldFolder.Parent = Workspace

	local halfW = MAP_WIDTH * 0.5
	local gateBarriers: { [number]: Part } = {}
	local worldEggs: { [string]: Model } = {}
	local guardians: { [string]: { Model: Model, Data: any, LevelInfo: any } } = {}

	local obstaclesFolder = Instance.new("Folder")
	obstaclesFolder.Name = "DynamicObstacles"
	obstaclesFolder.Parent = worldFolder

	buildSafeZoneAndPlots(worldFolder, obstaclesFolder)

	local levelsFolder = Instance.new("Folder")
	levelsFolder.Name = "Levels"
	levelsFolder.Parent = worldFolder

	local eggsFolder = Instance.new("Folder")
	eggsFolder.Name = "WorldEggs"
	eggsFolder.Parent = worldFolder

	local guardiansFolder = Instance.new("Folder")
	guardiansFolder.Name = "Guardians"
	guardiansFolder.Parent = worldFolder

	for _, levelInfo in ipairs(SlimeData.Levels) do
		local lvlId = levelInfo.Id or levelInfo.Level
		local lvlFolder = Instance.new("Folder")
		lvlFolder.Name = "Level_" .. tostring(lvlId) .. "_" .. levelInfo.Name
		lvlFolder.Parent = levelsFolder

		local zLength = math.abs(levelInfo.ZStart - levelInfo.ZEnd)
		local zMid = (levelInfo.ZStart + levelInfo.ZEnd) * 0.5

		makePart({
			Name = "Floor_" .. levelInfo.Name,
			Size = Vector3.new(MAP_WIDTH, 2, zLength),
			Position = Vector3.new(0, -1, zMid),
			Color = levelInfo.FloorColor,
			Material = levelInfo.FloorMaterial or Enum.Material.SmoothPlastic,
			Parent = lvlFolder,
		})

		makePart({
			Name = "CenterLane",
			Size = Vector3.new(20, 0.16, zLength - 8),
			Position = Vector3.new(0, 0.08, zMid),
			Color = levelInfo.SecondaryColor or levelInfo.ThemeColor,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = lvlFolder,
		})

		-- Build Medieval Castle Wall Battlements & Flanking Outer Side Mazes for each Level!
		buildCastleWallBattlements(lvlFolder, levelInfo, halfW)
		buildOuterSideMazes(lvlFolder, levelInfo, halfW)
		buildBiomeArenaContent(lvlFolder, levelInfo, obstaclesFolder)

		gateBarriers[lvlId] = buildLevelGate(lvlFolder, levelInfo, halfW)

		if levelInfo.Guardians then
			for idx, gData in ipairs(levelInfo.Guardians) do
				local gId = gData.Id or string.format("Guardian_%d_%d", lvlId, idx)
				local gModel = SquishyBuilder.CreateGuardianModel(gData)
				gModel.Name = gId
				local gPos = gData.Center or gData.HomePosition
				gModel:PivotTo(CFrame.new(gPos) * CFrame.Angles(0, math.rad(180), 0))
				gModel.Parent = guardiansFolder

				guardians[gId] = {
					Model = gModel,
					Data = gData,
					LevelInfo = levelInfo,
				}
			end
		end
	end

	local lastLevel = SlimeData.Levels[#SlimeData.Levels]
	makePart({
		Name = "EndOfWorldWall",
		Size = Vector3.new(MAP_WIDTH + OUTER_MAZE_WIDTH * 2 + 8, WALL_HEIGHT + 10, WALL_THICKNESS),
		Position = Vector3.new(0, (WALL_HEIGHT + 10) * 0.5, lastLevel.ZEnd - 2),
		Color = lastLevel.SecondaryColor or lastLevel.ThemeColor,
		Material = Enum.Material.Cobblestone,
		Parent = worldFolder,
	})

	-- Spawn all 117 Items (35 Boss Nest Eggs + 82 Shining Collectible Squishies across Rooftops, Rainbow Stairs, Mazes, Castle Walls & Obbies)!
	for _, slime in ipairs(SlimeData.Slimes) do
		local eggModel = SquishyBuilder.CreateWorldEgg(slime, true)
		eggModel:PivotTo(CFrame.new(slime.SpawnOffset or slime.Position))
		eggModel.Parent = eggsFolder
		worldEggs[tostring(slime.Id)] = eggModel
	end

	-- Strict Visual Sanitizer: preserve intentional Creator Store meshes while stripping accidental FileMeshes
	for _, desc in ipairs(worldFolder:GetDescendants()) do
		if desc:IsA("SpecialMesh") and desc.MeshType == Enum.MeshType.FileMesh and not desc:GetAttribute("PreserveCreatorStoreMesh") then
			desc:Destroy()
		end
	end

	return {
		WorldFolder = worldFolder,
		GateBarriers = gateBarriers,
		WorldEggs = worldEggs,
		Guardians = guardians,
	}
end

return WorldBuilder
