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
local CreatorStoreGameplayKits = require(Shared:WaitForChild("CreatorStoreGameplayKits"))

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
	p.CastShadow = if props.CastShadow ~= nil then props.CastShadow else true
	p.Size = props.Size or Vector3.new(4, 1, 4)
	local rawColor: Color3 = props.Color or Color3.fromRGB(200, 200, 200)
	local reqMat: Enum.Material = props.Material or Enum.Material.SmoothPlastic
	if props.Shape then
		p.Shape = props.Shape
	end

	-- PHASE 2.1 ZERO MAP GLOW & ANTI-LEGO RULE:
	-- 1. Strip all Enum.Material.Neon from the map environment (only collectibles/eggs/coins in SquishyBuilder glow!)
	-- 2. Remove all Lego studs (Enum.SurfaceType.Studs / Inlet) across all terrain, walls, and buildings.
	if reqMat == Enum.Material.Neon and props.AllowCollectibleNeon ~= true then
		local partName = tostring(props.Name or "")
		if string.find(partName, "Laser") or string.find(partName, "Beam") or string.find(partName, "DropZone") or string.find(partName, "Bridge") then
			reqMat = Enum.Material.Glass
		elseif string.find(partName, "Pool") or string.find(partName, "Moat") or string.find(partName, "Lava") or string.find(partName, "Magma") then
			reqMat = Enum.Material.Slate
		else
			reqMat = Enum.Material.SmoothPlastic
		end
		-- Tone down overly bright neon environment colors into grounded natural tones
		local h, s, v = rawColor:ToHSV()
		rawColor = Color3.fromHSV(h, math.clamp(s * 0.72, 0, 0.82), math.clamp(v * 0.82, 0.18, 0.85))
	elseif reqMat == Enum.Material.Plastic then
		reqMat = Enum.Material.SmoothPlastic
	end

	p.Color = rawColor
	p.Material = reqMat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.FrontSurface = Enum.SurfaceType.Smooth
	p.BackSurface = Enum.SurfaceType.Smooth
	p.LeftSurface = Enum.SurfaceType.Smooth
	p.RightSurface = Enum.SurfaceType.Smooth

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
		sg.LightInfluence = 0.25
		sg.Brightness = 1.15
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

-- Phase 2.1 Grounded Matte Concentric Stone/Concrete Pad (Zero Map Glow!)
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
		Color = outerColor:Lerp(Color3.fromRGB(110, 114, 122), 0.32),
		Material = Enum.Material.Cobblestone,
		Parent = parent,
	})
	makePart({
		Name = "DarkCoreDisk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.70, outerDiameter * 0.80, outerDiameter * 0.80),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(44, 48, 56),
		Material = Enum.Material.Slate,
		CanCollide = false,
		Parent = outerRing,
	})
	makePart({
		Name = "InnerNeonRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.75, outerDiameter * 0.56, outerDiameter * 0.56),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = innerColor:Lerp(Color3.fromRGB(130, 134, 142), 0.28),
		Material = Enum.Material.Concrete,
		CanCollide = false,
		Parent = outerRing,
	})
	return outerRing
end

local function setupVibrantLighting()
	-- Phase 2.1 Grounded Non-Glowing Map Lighting:
	-- Lower Brightness to 1.85, Bloom.Intensity to 0.25, and tone down saturation so ONLY
	-- Collectible Squishies, Brainrot Eggs, Hatched Brainrots, and Gold Coins glow and pop!
	Lighting.Ambient = Color3.fromRGB(128, 136, 148)
	Lighting.OutdoorAmbient = Color3.fromRGB(148, 156, 168)
	Lighting.Brightness = 1.85
	Lighting.ColorShift_Top = Color3.fromRGB(242, 238, 228)
	Lighting.ClockTime = 13.5
	Lighting.GeographicLatitude = 32
	Lighting.GlobalShadows = true

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.SunAngularSize = 16
	sky.MoonAngularSize = 11
	sky.Parent = Lighting

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.20
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(185, 212, 235)
	atmo.Decay = Color3.fromRGB(145, 182, 215)
	atmo.Glare = 0.04
	atmo.Haze = 0.55
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.25
	bloom.Size = 18
	bloom.Threshold = 0.95
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.0
	cc.Contrast = 0.10
	cc.Saturation = 0.12
	cc.Parent = Lighting
end

local STAGE_THEME_PALETTES: { [number]: { Primary: Color3, Secondary: Color3, Trim: Color3, Mat: Enum.Material } } = {
	[1] = { Primary = Color3.fromRGB(82, 178, 92), Secondary = Color3.fromRGB(168, 118, 68), Trim = Color3.fromRGB(238, 212, 118), Mat = Enum.Material.WoodPlanks }, -- Stage 1: Squishy Meadow
	[2] = { Primary = Color3.fromRGB(228, 112, 152), Secondary = Color3.fromRGB(132, 78, 48), Trim = Color3.fromRGB(245, 222, 185), Mat = Enum.Material.SmoothPlastic }, -- Stage 2: Chocolate Candy Kingdom
	[3] = { Primary = Color3.fromRGB(58, 178, 215), Secondary = Color3.fromRGB(235, 118, 82), Trim = Color3.fromRGB(218, 185, 118), Mat = Enum.Material.Sand }, -- Stage 3: Tropical Beach Lagoon
	[4] = { Primary = Color3.fromRGB(78, 168, 88), Secondary = Color3.fromRGB(178, 56, 52), Trim = Color3.fromRGB(215, 178, 78), Mat = Enum.Material.WoodPlanks }, -- Stage 4: Whispering Bamboo Forest
	[5] = { Primary = Color3.fromRGB(138, 78, 215), Secondary = Color3.fromRGB(68, 188, 235), Trim = Color3.fromRGB(48, 52, 72), Mat = Enum.Material.Slate }, -- Stage 5: Crystal Cyber Cavern
	[6] = { Primary = Color3.fromRGB(235, 242, 252), Secondary = Color3.fromRGB(135, 198, 245), Trim = Color3.fromRGB(228, 195, 88), Mat = Enum.Material.Marble }, -- Stage 6: Cloud Sky Sanctuary
	[7] = { Primary = Color3.fromRGB(54, 48, 56), Secondary = Color3.fromRGB(225, 78, 35), Trim = Color3.fromRGB(185, 115, 42), Mat = Enum.Material.Basalt }, -- Stage 7: Magma Volcano Doom
	[8] = { Primary = Color3.fromRGB(58, 42, 98), Secondary = Color3.fromRGB(178, 72, 235), Trim = Color3.fromRGB(235, 198, 78), Mat = Enum.Material.Slate }, -- Stage 8: Cosmic Void Citadel
}

local function applyStageThemeToModel(model: Model?, stageId: number?)
	if not model or not stageId then
		return
	end
	local pal = STAGE_THEME_PALETTES[stageId]
	if not pal then
		return
	end
	local partIdx = 0
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			partIdx += 1
			local chosenTone = if partIdx % 3 == 1 then pal.Primary elseif partIdx % 3 == 2 then pal.Secondary else pal.Trim
			local isCharacter = false
			if desc:IsA("MeshPart") and desc.TextureID ~= "" then
				isCharacter = true
			end
			for _, sub in ipairs(desc:GetChildren()) do
				if sub:IsA("SpecialMesh") and sub.TextureId ~= "" then
					isCharacter = true
					break
				end
			end
			if not isCharacter then
				desc.Color = desc.Color:Lerp(chosenTone, 0.72)
				if desc.Material == Enum.Material.Plastic or desc.Material == Enum.Material.SmoothPlastic then
					desc.Material = pal.Mat
				end
			end
		end
	end
end

local function placePrebuiltAsset(
	category: string,
	index: any,
	parent: Instance,
	pos: Vector3,
	yawDeg: number,
	targetHeight: number,
	canCollide: boolean?,
	stageId: number?
): Model?
	local model = PrebuiltLoader.CloneNormalizedTemplate(category, index, targetHeight, canCollide)
	if not model then
		return nil
	end
	if stageId then
		applyStageThemeToModel(model, stageId)
	end
	model:PivotTo(CFrame.new(pos.X, pos.Y, pos.Z) * CFrame.Angles(0, math.rad(yawDeg), 0))
	model.Parent = parent
	return model
end

local function placeGameplayKit(
	kitKey: string,
	parent: Instance,
	pos: Vector3,
	yawDeg: number,
	targetScale: number?,
	canCollide: boolean?,
	stageId: number?
): Model?
	local kit = CreatorStoreGameplayKits.GetKit(kitKey)
	if not kit then
		return nil
	end
	local cloned = kit:Clone()

	-- 1. Strip scripts, spawns, and giant floor/baseplate slabs
	for _, desc in ipairs(cloned:GetDescendants()) do
		if desc:IsA("LuaSourceContainer") or desc:IsA("SpawnLocation") then
			desc:Destroy()
		elseif desc:IsA("BasePart") then
			local lowerName = string.lower(desc.Name)
			if (desc.Size.X > 85 and desc.Size.Z > 85)
				or string.find(lowerName, "baseplate")
				or string.find(lowerName, "ground")
				or string.find(lowerName, "floor")
			then
				desc:Destroy()
			end
		end
	end

	if stageId then
		applyStageThemeToModel(cloned, stageId)
	end

	-- 2. Normalize cloned model using GetBoundingBox so targetScale is the target dimension in studs
	local okBB, _, bbSize = pcall(function()
		return cloned:GetBoundingBox()
	end)
	if okBB and bbSize.Magnitude > 0.05 then
		local tDim = if targetScale and targetScale > 1.5 then targetScale else 14.0
		local maxDim = math.max(bbSize.Y, bbSize.X * 0.65, bbSize.Z * 0.65)
		local factor = math.clamp(tDim / math.max(maxDim, 0.5), 0.04, 2.5)
		pcall(function()
			cloned:ScaleTo(cloned:GetScale() * factor)
		end)
	end

	-- 3. Re-query BoundingBox and position cloned so bottom-center sits cleanly at pos with yawDeg rotation
	local okBB2, bbCF2, bbSize2 = pcall(function()
		return cloned:GetBoundingBox()
	end)
	if okBB2 and bbCF2 and bbSize2 then
		local bottomCenter = bbCF2.Position - Vector3.new(0, bbSize2.Y * 0.5, 0)
		cloned.WorldPivot = CFrame.new(bottomCenter)
	end
	cloned:PivotTo(CFrame.new(pos.X, pos.Y, pos.Z) * CFrame.Angles(0, math.rad(yawDeg), 0))

	for _, d in ipairs(cloned:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			if canCollide ~= nil then
				d.CanCollide = canCollide
			end
		end
	end
	cloned.Parent = parent
	return cloned
end


local function buildLandmarkAccessLadderAndDeck(
	parent: Instance,
	namePrefix: string,
	targetPos: Vector3,
	deckW: number,
	deckD: number,
	deckColor: Color3?,
	deckMat: Enum.Material?
)
	local dColor = deckColor or Color3.fromRGB(138, 142, 155)
	local dMat = deckMat or Enum.Material.Cobblestone

	-- 1. Walkable landing deck at (targetPos.X, targetPos.Y - 1.0, targetPos.Z)
	makePart({
		Name = namePrefix .. "_LandingDeck",
		Size = Vector3.new(deckW + 4, 1.4, deckD + 4),
		Position = Vector3.new(targetPos.X, targetPos.Y - 1.0, targetPos.Z),
		Color = dColor,
		Material = dMat,
		Parent = parent,
	})

	-- 2. Vertical climbable TrussPart ladder from ground up to edge of deck
	local ladderX = targetPos.X - (deckW * 0.5 + 1.0)
	local ladderH = math.max(6, targetPos.Y)
	local ladder = Instance.new("TrussPart")
	ladder.Name = namePrefix .. "_ClimbLadder"
	ladder.Anchored = true
	ladder.Size = Vector3.new(3.2, ladderH, 2.4)
	ladder.Position = Vector3.new(ladderX, ladderH * 0.5, targetPos.Z)
	ladder.Color = Color3.fromRGB(112, 118, 138)
	ladder.Material = Enum.Material.Metal
	ladder.Parent = parent

	-- 3. Stepped 6-Step Staircase leading into the base of the ladder!
	for s = 1, 6 do
		makePart({
			Name = string.format("%s_StairStep_%d", namePrefix, s),
			Size = Vector3.new(8.0, 1.1, 2.8),
			Position = Vector3.new(ladderX - 2.5 - (s * 2.2), s * 0.85, targetPos.Z),
			Color = Color3.fromRGB(145, 148, 160),
			Material = Enum.Material.Cobblestone,
			Parent = parent,
		})
	end

	-- 4. Green Super Bounce Pad for instant launch option!
	local bPad = makePart({
		Name = namePrefix .. "_BouncePad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, 9.5, 9.5),
		CFrame = CFrame.new(ladderX - 18.0, 0.5, targetPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(85, 235, 115),
		Material = Enum.Material.Neon,
		Parent = parent,
	})
	bPad:SetAttribute("SuperBouncePad", true)
	bPad:SetAttribute("BounceVelocityY", math.clamp(ladderH * 2.8, 65, 115))
end

local function buildSkipObbyPaywallPad(
	parent: Instance,
	padName: string,
	padPos: Vector3,
	destPos: Vector3,
	stageNum: number
): Part
	local pad = makePart({
		Name = padName,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.65, 8.0, 8.0),
		CFrame = CFrame.new(padPos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 215, 65),
		Material = Enum.Material.Neon,
		Parent = parent,
	})
	pad:SetAttribute("SkipObbyStage", stageNum)
	pad:SetAttribute("SkipTargetPos", destPos)

	local innerRing = makePart({
		Name = "PaywallPadInnerCore",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.72, 5.5, 5.5),
		CFrame = CFrame.new(padPos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(185, 75, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = pad,
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SkipObbyPrompt"
	prompt.ActionText = "💎 Skip Obby to Top Summit (VIP / Paywall)"
	prompt.ObjectText = string.format("Instant Teleport to Stage %d Obby Reward!", stageNum)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("SkipObbyStage", stageNum)
	prompt:SetAttribute("SkipTargetPos", destPos)

	local att = Instance.new("Attachment")
	att.Name = "PromptAttachment"
	att.Position = Vector3.new(0, 3.2, 0)
	att.Parent = pad
	prompt.Parent = att

	return pad
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

		-- Guaranteed Reachability: Direct Climbable TrussPart Ladder to Roof!
		local roofTruss = Instance.new("TrussPart")
		roofTruss.Name = "HouseRoofLadder"
		roofTruss.Anchored = true
		roofTruss.Size = Vector3.new(2, targetHeight, 2)
		roofTruss.CFrame = cf * CFrame.new(-w * 0.5 - 1.0, targetHeight * 0.5, 0)
		roofTruss.Color = Color3.fromRGB(112, 118, 138)
		roofTruss.Material = Enum.Material.Metal
		roofTruss.Parent = hModel
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

	-- Paywall: 💎 Skip Rainbow Staircase Pad
	local rainbowPayPad = buildGlowingNeonCircle(
		stairFolder,
		"SkipRainbowStaircasePad",
		Vector3.new(stairCenterX - 8, 0.45, -18),
		8,
		Color3.fromRGB(255, 215, 65),
		Color3.fromRGB(185, 75, 255)
	)
	local rainbowPayPrompt = createAttachmentPrompt(
		rainbowPayPad,
		"SkipObbyPaywallPrompt",
		"💎 Skip Rainbow Staircase (VIP / Robux)",
		"⚡ Instant Teleport to Sky Cloud Sanctuary!",
		Vector3.new(0, 3.2, 0),
		16
	)
	if rainbowPayPrompt then
		rainbowPayPrompt:SetAttribute("StageId", 1)
		rainbowPayPrompt:SetAttribute("SummitPos", Vector3.new(stairCenterX, 52.0, -148))
	end

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
			Size = Vector3.new(18.5, 1.4, 4.4),
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
				Size = Vector3.new(2.0, 19.5, 19.5),
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
		Size = Vector3.new(2.8, 34, 34),
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
				Size = Vector3.new(8.5, 1.6, 4.2),
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

	-- Heavy Steel Low-Profile Treadmill Base Deck

	makePart({
		Name = "TreadmillBase",
		Size = Vector3.new(12.8, 0.6, 16.8),
		Position = treadCenter + Vector3.new(0, 0.3, 0),
		Color = Color3.fromRGB(34, 38, 52),
		Material = Enum.Material.Metal,
		Parent = tmModel,
	})

	-- Low-Profile Metallic Side Foot Rails & Tier Trim
	for _, sideZ in ipairs({ -7.2, 7.2 }) do
		makePart({
			Name = "SideRail",
			Size = Vector3.new(12.8, 0.85, 1.2),
			Position = treadCenter + Vector3.new(0, 0.45, sideZ),
			Color = Color3.fromRGB(44, 48, 62),
			Material = Enum.Material.Metal,
			Parent = tmModel,
		})
		makePart({
			Name = "SideRailTrim",
			Size = Vector3.new(12.4, 0.25, 1.25),
			Position = treadCenter + Vector3.new(0, 0.95, sideZ),
			Color = tier.PrimaryColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = tmModel,
		})
	end

	-- Front & Rear Cylindrical Conveyor Rollers
	makePart({
		Name = "FrontRoller",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(12.2, 1.1, 1.1),
		CFrame = CFrame.new(treadCenter + Vector3.new(-faceDir * 6.0, 0.65, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(68, 74, 88),
		Material = Enum.Material.Metal,
		Parent = tmModel,
	})
	makePart({
		Name = "RearRoller",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(12.2, 1.1, 1.1),
		CFrame = CFrame.new(treadCenter + Vector3.new(faceDir * 6.0, 0.65, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(68, 74, 88),
		Material = Enum.Material.Metal,
		Parent = tmModel,
	})

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

	-- Angled Left & Right Console Uprights at front of belt
	for _, upZ in ipairs({ -5.6, 5.6 }) do
		makePart({
			Name = "ConsoleUpright",
			Size = Vector3.new(0.8, 5.2, 0.8),
			CFrame = CFrame.new(treadCenter + Vector3.new(-faceDir * 5.2, 3.2, upZ)) * CFrame.Angles(0, 0, math.rad(faceDir * 14)),
			Color = Color3.fromRGB(48, 52, 64),
			Material = Enum.Material.Metal,
			Parent = tmModel,
		})
	end
	makePart({
		Name = "TreadmillHandrailCrossbar",
		Size = Vector3.new(0.8, 0.8, 12.0),
		Position = treadCenter + Vector3.new(-faceDir * 4.6, 5.4, 0),
		Color = Color3.fromRGB(36, 40, 52),
		Material = Enum.Material.Metal,
		Parent = tmModel,
	})

	-- Digital LED Treadmill Console Screen with SurfaceGui
	local consoleScreen = makePart({
		Name = "TreadmillConsoleScreen",
		Size = Vector3.new(0.6, 2.4, 8.4),
		CFrame = CFrame.new(treadCenter + Vector3.new(-faceDir * 4.5, 6.4, 0)) * CFrame.Angles(0, if faceDir > 0 then 0 else math.pi, math.rad(faceDir * -20)),
		Color = Color3.fromRGB(18, 22, 34),
		Material = Enum.Material.SmoothPlastic,
		Parent = tmModel,
	})

	local speedFormatted = SlimeData.FormatNumber(tier.SpeedPerSec)
	local consoleText = string.format("⚡ TIER %d TREADMILL\n[%s]\n+%s SPD / SEC", tierId, tier.MultiplierText or tier.MultiplierLabel, speedFormatted)
	createSurfaceSign(consoleScreen, consoleText, tier.AccentColor, Color3.fromRGB(14, 16, 28), { Enum.NormalId.Back, Enum.NormalId.Front, Enum.NormalId.Left, Enum.NormalId.Right }, 75)

	-- Clean Floating Treadmill Billboard above console
	local signLabelText = if isStageTreadmill
		then string.format("⚡ STAGE %d %s [%s]\n🏃 Run Here = +%s Speed / Sec!", tierId, string.upper(tier.Name), tier.MultiplierText, speedFormatted)
		else string.format("⚡ BASE %s [%s]\n🏃 Run Here = +%s Speed / Sec!", string.upper(tier.Name), tier.MultiplierText, speedFormatted)

	local bb = createBillboardText(
		consoleScreen,
		signLabelText,
		tier.AccentColor,
		Vector3.new(0, 2.8, 0),
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

	-- 5. 💖 Like & ⭐ Favorite + 🔔 Notify VIP Reward Shrine (Outer East Plaza at X = 162, Z = 172 + Spawn Welcome Kiosk at X = 24, Z = 86!)
	local likeBooth = Instance.new("Model")
	likeBooth.Name = "LikeFavoriteRewardBooth"
	likeBooth.Parent = hubFolder

	local likePad = buildGlowingNeonCircle(
		likeBooth,
		"LikeFavoritePad",
		Vector3.new(162, 0.35, 172),
		13,
		Color3.fromRGB(235, 75, 145),
		Color3.fromRGB(255, 215, 65)
	)
	likeBooth.PrimaryPart = likePad

	for _, zSide in ipairs({ -5.2, 5.2 }) do
		makePart({
			Name = "LikeShrinePillar",
			Size = Vector3.new(2.0, 9.5, 2.0),
			Position = Vector3.new(164.2, 4.75, 172 + zSide),
			Color = Color3.fromRGB(225, 85, 145),
			Material = Enum.Material.SmoothPlastic,
			Parent = likeBooth,
		})
	end

	-- 3D Golden Star & Pink Heart Trophy on Pedestal
	makePart({
		Name = "LikeTrophyPedestal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3.2, 4.2, 4.2),
		CFrame = CFrame.new(162, 1.8, 172) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(52, 44, 68),
		Material = Enum.Material.Cobblestone,
		Parent = likeBooth,
	})
	makePart({
		Name = "LikeTrophyHeartCore",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4.2, 4.2, 4.2),
		Position = Vector3.new(162, 5.5, 172),
		Color = Color3.fromRGB(255, 85, 155),
		Material = Enum.Material.SmoothPlastic,
		Parent = likeBooth,
	})

	local likeHeader = makePart({
		Name = "LikeFavoriteSign",
		Size = Vector3.new(1.2, 3.6, 14.5),
		Position = Vector3.new(164.2, 10.8, 172),
		Color = Color3.fromRGB(225, 65, 135),
		Material = Enum.Material.SmoothPlastic,
		Parent = likeBooth,
	})
	createSurfaceSign(
		likeHeader,
		"💖 👍 LIKE & ⭐ FAVORITE REWARD!\nClaim FREE +$5,000 Cash • +2 Spins • +15 Speed • 💖 Supporter Tag!",
		Color3.fromRGB(255, 245, 110),
		Color3.fromRGB(48, 16, 36),
		{ Enum.NormalId.Left, Enum.NormalId.Right },
		160
	)
	createAttachmentPrompt(
		likePad,
		"LikeFavoritePrompt",
		"⭐ Favorite & Claim VIP Gift! (+$5,000 + 2 Spins)",
		"💖 👍 Like & ⭐ Favorite Reward",
		Vector3.new(0, 3.2, 0),
		16
	)

	-- Spawn Plaza Quick-Access Like & Favorite Stand right beside the Central Highway at X = 26, Z = 86!
	local spawnLikeStand = buildGlowingNeonCircle(
		likeBooth,
		"SpawnLikeFavoritePad",
		Vector3.new(26, 0.35, 86),
		8.5,
		Color3.fromRGB(235, 75, 145),
		Color3.fromRGB(255, 215, 65)
	)
	local spawnLikeSign = makePart({
		Name = "SpawnLikeFavoriteBoard",
		Size = Vector3.new(9.5, 3.4, 1.0),
		Position = Vector3.new(26, 5.2, 86),
		Color = Color3.fromRGB(225, 65, 135),
		Material = Enum.Material.SmoothPlastic,
		Parent = likeBooth,
	})
	createSurfaceSign(
		spawnLikeSign,
		"👍 LIKE & ⭐ FAVORITE GAME!\nFREE +$5,000 Cash + 2 Spins + 💖 VIP Tag!",
		Color3.fromRGB(255, 245, 110),
		Color3.fromRGB(48, 16, 36),
		{ Enum.NormalId.Front, Enum.NormalId.Back },
		140
	)
	createAttachmentPrompt(
		spawnLikeStand,
		"LikeFavoritePrompt",
		"⭐ Favorite & Claim Free $5,000 Gift!",
		"💖 👍 Like & ⭐ Favorite Reward",
		Vector3.new(0, 3.0, 0),
		15
	)

	-- 6. User's Acquired Creator Store Gameplay & Monetization Monuments:
	-- Robux Donation Board (AssetId 140042750673504), Time Played Leaderboard (AssetId 5352156968), Obby Gamepass (AssetId 75354400953490)
	local userKitFolder = Instance.new("Folder")
	userKitFolder.Name = "UserCreatorStoreKits"
	userKitFolder.Parent = hubFolder

	-- A) Time Played Leaderboard (East Plaza: X = 146, Z = 68)
	local timePlayedPad = buildGlowingNeonCircle(
		userKitFolder,
		"TimePlayedPad",
		Vector3.new(146, 0.35, 68),
		14,
		Color3.fromRGB(95, 235, 255),
		Color3.fromRGB(255, 215, 65)
	)
	local timePlayedBoard = makePart({
		Name = "TimePlayedBoardFrame",
		Size = Vector3.new(1.4, 15.5, 13.5),
		Position = Vector3.new(146, 9.6, 68),
		Color = Color3.fromRGB(18, 22, 38),
		Material = Enum.Material.SmoothPlastic,
		Parent = userKitFolder,
	})
	createSurfaceSign(
		timePlayedBoard,
		"⏱️ TIME PLAYED LEADERBOARD\nPlay To Earn Free Mystery Brainrots & Cash!",
		Color3.fromRGB(95, 235, 255),
		Color3.fromRGB(18, 22, 38),
		{ Enum.NormalId.Left, Enum.NormalId.Right },
		150
	)

	-- B) Robux Donation Board (East Plaza: X = 146, Z = 112)
	local donationPad = buildGlowingNeonCircle(
		userKitFolder,
		"DonationBoardPad",
		Vector3.new(146, 0.35, 112),
		14,
		Color3.fromRGB(255, 185, 45),
		Color3.fromRGB(255, 85, 135)
	)
	local donationBoard = makePart({
		Name = "RobuxDonationBoardFrame",
		Size = Vector3.new(1.4, 15.5, 13.5),
		Position = Vector3.new(146, 9.6, 112),
		Color = Color3.fromRGB(24, 20, 36),
		Material = Enum.Material.SmoothPlastic,
		Parent = userKitFolder,
	})
	createSurfaceSign(
		donationBoard,
		"💖 ROBUX DONATION BOARD\nTop Donators & Supporters Get In-Game Perks!",
		Color3.fromRGB(255, 215, 65),
		Color3.fromRGB(24, 20, 36),
		{ Enum.NormalId.Left, Enum.NormalId.Right },
		150
	)
	createAttachmentPrompt(
		donationPad,
		"DonationPrompt",
		"Donate Robux & Support the Game!",
		"💖 Top Donator Board",
		Vector3.new(0, 3.2, 0),
		16
	)

	-- C) Obby Gamepass Kiosk (East Plaza: X = 146, Z = 152)
	local obbyGPPad = buildGlowingNeonCircle(
		userKitFolder,
		"ObbyGamepassPad",
		Vector3.new(146, 0.35, 152),
		12,
		Color3.fromRGB(145, 85, 255),
		Color3.fromRGB(65, 220, 255)
	)
	local obbyGPBoard = makePart({
		Name = "ObbyGamepassBoardFrame",
		Size = Vector3.new(1.4, 14.5, 11.5),
		Position = Vector3.new(146, 9.0, 152),
		Color = Color3.fromRGB(28, 18, 48),
		Material = Enum.Material.SmoothPlastic,
		Parent = userKitFolder,
	})
	createSurfaceSign(
		obbyGPBoard,
		"🏆 OBBY GAMEPASS SYSTEM\nSkip Stages • Speed Obby Pass • Checkpoint Teleport!",
		Color3.fromRGB(165, 115, 255),
		Color3.fromRGB(28, 18, 48),
		{ Enum.NormalId.Left, Enum.NormalId.Right },
		150
	)
	createAttachmentPrompt(
		obbyGPPad,
		"ObbyGamepassPrompt",
		"Browse Obby Gamepasses",
		"🏆 Stage Skip & Obby Passes",
		Vector3.new(0, 3.2, 0),
		16
	)

	-- D) 4 Dedicated Safe Zone Paywall Coil & Carpet Booth Pads on the East Rewards Plaza (X = 132)
	local coilCarpetPads = {
		{ Key = "FusionCoil", Name = "Fusion Coil", AssetId = 12124152417, Pos = Vector3.new(132, 0.35, 64), Color = Color3.fromRGB(135, 65, 255) },
		{ Key = "SpeedCoil", Name = "Speed Coil", AssetId = 11963709166, Pos = Vector3.new(132, 0.35, 88), Color = Color3.fromRGB(255, 65, 65) },
		{ Key = "GravityCoil", Name = "Gravity Coil", AssetId = 11987698523, Pos = Vector3.new(132, 0.35, 112), Color = Color3.fromRGB(65, 145, 255) },
		{ Key = "RainbowCarpet", Name = "Rainbow Carpet", AssetId = 17656533013, Pos = Vector3.new(132, 0.35, 136), Color = Color3.fromRGB(255, 215, 65) },
	}
	for _, gp in ipairs(coilCarpetPads) do
		local pad = buildGlowingNeonCircle(
			userKitFolder,
			gp.Key .. "Pad",
			gp.Pos,
			8.5,
			gp.Color,
			Color3.fromRGB(255, 255, 255)
		)
		pad:SetAttribute("GamepassAssetId", gp.AssetId)
		createAttachmentPrompt(
			pad,
			gp.Key .. "Prompt",
			string.format("⚡ Purchase %s (Gamepass)", gp.Name),
			string.format("🛒 %s Store Booth", gp.Name),
			Vector3.new(0, 3.0, 0),
			15
		)
		local stand = makePart({
			Name = gp.Key .. "StandSign",
			Size = Vector3.new(6.5, 3.2, 0.8),
			Position = gp.Pos + Vector3.new(0, 4.6, 0),
			Color = gp.Color,
			Material = Enum.Material.SmoothPlastic,
			Parent = userKitFolder,
		})
		createSurfaceSign(
			stand,
			string.format("⚡ %s\nInstant Super Boost Gamepass!", gp.Name),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(24, 20, 36),
			{ Enum.NormalId.Front, Enum.NormalId.Back },
			120
		)
	end

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
		-- STAGE 1 (Z = 0 to -160 — SQUISHY MEADOW):
		-- Landmarks:
		--   * Spinning Dutch Windmill (114591511925320 / StageLandmarks #1) at (-78, 0, -55)
		--   * Giant Oak Treehouse (7860328354 / StageLandmarks #2) at (78, 0, -65)
		--   * Mushroom Cottages (18771840070 / StageLandmarks #4) at (-72, 0, -118) & (74, 0, -122)
		-- Obby & Hidden Spots:
		--   * Meadow Trampoline, Log-Hop & Sweeper Spinner Obby (76838144711090, 14796107102, 10202936)
		--     from (42, 2, -45) up to the Treehouse Roof at (78, 26, -65) and across a rope bridge
		--     to the Windmill Balcony at (-78, 28, -55).
		-- =========================================================================================
		-- Procedural Dutch Windmill Tower at (-78, 0, -55)
		makePart({
			Name = "Stage1_WindmillTower",
			Size = Vector3.new(14, 27, 14),
			Position = Vector3.new(-78, 13.5, -55),
			Color = Color3.fromRGB(224, 210, 185),
			Material = Enum.Material.Brick,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage1_WindmillBalconyDeck",
			Size = Vector3.new(20, 1.5, 20),
			Position = Vector3.new(-78, 27.4, -55),
			Color = Color3.fromRGB(142, 96, 54),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})

		-- Procedural Giant Oak Treehouse at (78, 0, -65)
		makePart({
			Name = "Stage1_OakTreeTrunk",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(25, 9, 9),
			CFrame = CFrame.new(78, 12.5, -65) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(112, 72, 42),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage1_OakTreeCanopy",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(26, 14, 26),
			Position = Vector3.new(78, 22, -65),
			Color = Color3.fromRGB(58, 148, 52),
			Material = Enum.Material.LeafyGrass,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage1_TreehouseRoofDeck",
			Size = Vector3.new(20, 1.5, 20),
			Position = Vector3.new(78, 25.4, -65),
			Color = Color3.fromRGB(132, 88, 48),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})

		-- Procedural Spotted Mushroom Cottages at (-72, 0, -118) and (74, 0, -122)
		local shroomPositions = { Vector3.new(-72, 0, -118), Vector3.new(74, 0, -122) }
		for sIdx, sPos in ipairs(shroomPositions) do
			makePart({
				Name = "Stage1_MushroomStem_" .. tostring(sIdx),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(13, 10, 10),
				CFrame = CFrame.new(sPos.X, 6.5, sPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(245, 240, 225),
				Material = Enum.Material.SmoothPlastic,
				Parent = landmarksFolder,
			})
			makePart({
				Name = "Stage1_MushroomCap_" .. tostring(sIdx),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(3.5, 18, 18),
				CFrame = CFrame.new(sPos.X, 13.5, sPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(225, 52, 52),
				Material = Enum.Material.SmoothPlastic,
				Parent = landmarksFolder,
			})
		end

		-- Exact Landmark Access Ladders, Decks & Stairs (Mushroom Cottage, Treehouse, Windmill)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage1_MushroomCottage", Vector3.new(-72, 14.5, -118), 12, 12, Color3.fromRGB(132, 88, 48), Enum.Material.WoodPlanks)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage1_TreehouseRoof", Vector3.new(78, 26.8, -65), 12, 12, Color3.fromRGB(132, 88, 48), Enum.Material.WoodPlanks)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage1_WindmillBalcony", Vector3.new(-78, 28.8, -55), 12, 12, Color3.fromRGB(142, 96, 54), Enum.Material.WoodPlanks)

		-- Paywall: 💎 Skip Stage 1 Obby Pad
		buildSkipObbyPaywallPad(landmarksFolder, "SkipObbyPad_1", Vector3.new(34, 0.5, -42), Vector3.new(78, 28.5, -65), 1)
		-- Spinning Dutch Windmill Rotor Blades on the Windmill
		for rIdx = 1, 2 do
			local rotor = makePart({
				Name = "WindmillBlades_" .. tostring(rIdx),
				Size = if rIdx == 1 then Vector3.new(26, 2.2, 1.0) else Vector3.new(2.2, 26, 1.0),
				Position = Vector3.new(-78, 24, -46.5),
				Color = Color3.fromRGB(228, 214, 178),
				Material = Enum.Material.WoodPlanks,
				CanCollide = false,
				Parent = obstaclesFolder,
			})
			rotor:SetAttribute("WindmillRotor", true)
			rotor:SetAttribute("SpinSpeed", 1.1)
		end

		-- Meadow Trampoline, Log-Hop & Sweeper Spinner Obby from (42, 2, -45) -> (78, 26, -65) -> (-78, 28, -55)
		local trampPad = buildGlowingNeonCircle(
			landmarksFolder,
			"BouncePad",
			Vector3.new(42, 2.0, -45),
			11.0,
			Color3.fromRGB(72, 168, 84),
			Color3.fromRGB(218, 185, 64)
		)
		trampPad:SetAttribute("BounceImpulse", 92)

		for hop = 1, 4 do
			local t = hop / 4
			local logH = 4 + 21 * t
			makePart({
				Name = "MeadowLogHop_" .. tostring(hop),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(logH, 9.5, 9.5),
				CFrame = CFrame.new(
					42 + (78 - 42) * t,
					logH * 0.5,
					-45 + (-65 - -45) * t
				) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(122, 82, 46),
				Material = Enum.Material.WoodPlanks,
				Parent = landmarksFolder,
			})
		end

		-- High Aerial Rope Suspension Bridge connecting Treehouse Roof (78, 26, -65) to Windmill Balcony (-78, 28, -55)
		for seg = 1, 12 do
			local alpha = (seg - 0.5) / 12
			local sag = math.sin(alpha * math.pi) * 2.2
			local bx = 78 + (-78 - 78) * alpha
			local by = 25.4 + (27.4 - 25.4) * alpha - sag
			local bz = -65 + (-55 - -65) * alpha
			makePart({
				Name = "Stage1_RopeBridgePlank_" .. tostring(seg),
				Size = Vector3.new(11.5, 0.8, 5.4),
				Position = Vector3.new(bx, by, bz),
				Color = Color3.fromRGB(148, 102, 58),
				Material = Enum.Material.WoodPlanks,
				Parent = landmarksFolder,
			})
		end

		-- Secret Dark Stone Cave Entrance & `1710` Keypad at (26, 0, -72)
		makePart({
			Name = "SecretCaveOuterRock",
			Size = Vector3.new(18, 14, 13),
			Position = Vector3.new(26, 7.0, zStart - 72),
			Color = Color3.fromRGB(108, 110, 118),
			Material = Enum.Material.Slate,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "SecretCaveDarkOpening",
			Size = Vector3.new(7.5, 9.5, 1.2),
			Position = Vector3.new(26, 4.75, zStart - 65.8),
			Color = Color3.fromRGB(18, 20, 24),
			Material = Enum.Material.Slate,
			Parent = landmarksFolder,
		})
		local caveKeypad = makePart({
			Name = "CaveCodeKeypad",
			Size = Vector3.new(2.4, 3.6, 0.6),
			Position = Vector3.new(19.8, 4.8, zStart - 65.5),
			Color = Color3.fromRGB(52, 56, 64),
			Material = Enum.Material.Metal,
			Parent = landmarksFolder,
		})
		createSurfaceSign(
			caveKeypad,
			"1710\n[1][2][3]\n[4][5][6]\n[7][8][9]",
			Color3.fromRGB(245, 245, 245),
			Color3.fromRGB(32, 36, 46),
			{ Enum.NormalId.Back, Enum.NormalId.Front },
			55
		)

	elseif id == 2 then

		-- =========================================================================================
		-- STAGE 2 (Z = -160 to -320 — CHOCOLATE CANDY KINGDOM):
		-- Landmarks:
		--   * Walk-In Gingerbread Mansion (4400478930 / StageLandmarks #5) at (-82, 0, -210)
		--   * Spinning Candy Carousel Ride (131526002682377 / StageLandmarks #7) at (80, 0, -215)
		--   * Candy Cane Road Arches (137470241818443 / StageLandmarks #6) over the Central Road at Z = -190, -240, -290
		-- Obby & Hidden Spots:
		--   * Peppermint Knockback Spinner & Wafer Bridge Obby (4514115489, 12120501468)
		--     from (-45, 3, -195) spiraling up to the Gingerbread Attic Chimney at (-82, 30, -210)
		--     and High Cocoa Platform at (-75, 36, -255).
		-- =========================================================================================
		-- Procedural Gingerbread Manor at (-82, 0, -210)
		makePart({
			Name = "Stage2_GingerbreadManorBody",
			Size = Vector3.new(22, 28, 20),
			Position = Vector3.new(-82, 14, -210),
			Color = Color3.fromRGB(162, 96, 52),
			Material = Enum.Material.Brick,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage2_GingerbreadIcingTrim",
			Size = Vector3.new(22.8, 1.4, 20.8),
			Position = Vector3.new(-82, 28.5, -210),
			Color = Color3.fromRGB(250, 248, 245),
			Material = Enum.Material.SmoothPlastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage2_GingerbreadAtticPlatform",
			Size = Vector3.new(20, 1.5, 20),
			Position = Vector3.new(-82, 29.4, -210),
			Color = Color3.fromRGB(152, 92, 52),
			Material = Enum.Material.Brick,
			Parent = landmarksFolder,
		})

		-- Procedural Candy Carousel Pavilion at (80, 0, -215)
		makePart({
			Name = "Stage2_CarouselBase",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.5, 22, 22),
			CFrame = CFrame.new(80, 1.25, -215) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(245, 135, 185),
			Material = Enum.Material.SmoothPlastic,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage2_CarouselCanopy",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.5, 22, 22),
			CFrame = CFrame.new(80, 13.5, -215) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 215, 65),
			Material = Enum.Material.SmoothPlastic,
			Parent = landmarksFolder,
		})

		for _, archZ in ipairs({ -190, -240, -290 }) do
			for _, sideX in ipairs({ -21, 21 }) do
				makePart({
					Name = "CandyCanePillar_" .. tostring(sideX) .. "_" .. tostring(math.abs(archZ)),
					Size = Vector3.new(3.2, 21.5, 3.2),
					Position = Vector3.new(sideX, 10.75, archZ),
					Color = Color3.fromRGB(245, 245, 250),
					Material = Enum.Material.SmoothPlastic,
					Parent = landmarksFolder,
				})
			end
			makePart({
				Name = "CandyCaneRoadArchCrown_" .. tostring(math.abs(archZ)),
				Size = Vector3.new(44, 2.2, 2.4),
				Position = Vector3.new(0, 21.5, archZ),
				Color = Color3.fromRGB(205, 64, 78),
				Material = Enum.Material.SmoothPlastic,
				Parent = landmarksFolder,
			})
		end

		makePart({
			Name = "Stage2_HighCocoaPlatform",
			Size = Vector3.new(16, 1.4, 16),
			Position = Vector3.new(-75, 35.3, -255),
			Color = Color3.fromRGB(108, 62, 38),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})

		-- Exact Landmark Access Ladders, Decks & Stairs (Carousel, Gingerbread Chimney, High Cocoa)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage2_CarouselRide", Vector3.new(80, 14.5, -215), 12, 12, Color3.fromRGB(152, 92, 52), Enum.Material.WoodPlanks)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage2_GingerbreadChimney", Vector3.new(-82, 30.8, -210), 12, 12, Color3.fromRGB(152, 92, 52), Enum.Material.Brick)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage2_HighCocoaPlatform", Vector3.new(-75, 36.8, -255), 12, 12, Color3.fromRGB(108, 62, 38), Enum.Material.WoodPlanks)

		-- Paywall: 💎 Skip Stage 2 Obby Pad
		buildSkipObbyPaywallPad(landmarksFolder, "SkipObbyPad_2", Vector3.new(-38, 0.5, -192), Vector3.new(-75, 38.5, -255), 2)

		-- Peppermint Knockback Spinner & Wafer Bridge Obby from (-45, 3, -195) -> (-82, 30, -210) -> (-75, 36, -255)
		for step = 1, 6 do
			local alpha = step / 6
			makePart({
				Name = "PeppermintWaferStep_" .. tostring(step),
				Size = Vector3.new(10.0, 1.6, 7.5),
				Position = Vector3.new(
					-45 + (-82 - -45) * alpha,
					3 + 26.4 * alpha,
					-195 + (-210 - -195) * alpha
				),
				Color = if step % 2 == 0 then Color3.fromRGB(218, 182, 138) else Color3.fromRGB(208, 72, 98),
				Material = Enum.Material.WoodPlanks,
				Parent = landmarksFolder,
			})
		end
		-- High Wafer Bridge from Gingerbread Attic (-82, 30, -210) to High Cocoa Platform (-75, 36, -255)
		for wStep = 1, 5 do
			local alpha = wStep / 5
			makePart({
				Name = "CocoaWaferBridge_" .. tostring(wStep),
				Size = Vector3.new(9.0, 1.4, 8.5),
				Position = Vector3.new(
					-82 + (-75 - -82) * alpha,
					29.4 + (35.3 - 29.4) * alpha,
					-210 + (-255 - -210) * alpha
				),
				Color = Color3.fromRGB(178, 122, 74),
				Material = Enum.Material.WoodPlanks,
				Parent = landmarksFolder,
			})
		end

	elseif id == 3 then

		-- =========================================================================================
		-- STAGE 3 (Z = -320 to -480 — TROPICAL BEACH LAGOON):
		-- Landmarks:
		--   * Boardable Pirate Galleon Ship (7137210839 / StageLandmarks #8) at (-84, 0, -390)
		--   * Giant Water Slide Tower (5706899551 / StageLandmarks #9) at (82, 0, -375)
		--   * Coastal Lighthouse & Sand Castle (95052703843351, 18852029806 / StageLandmarks #11 & #10) at (76, 0, -445)
		-- Obby & Hidden Spots:
		--   * Moving Surfboard, Rigging Ladder & Mast Balance Obby (8517401506, 13804790028)
		--     from (-44, 3, -355) up to the Pirate Ship Crow's Nest at (-84, 38, -390),
		--     inside the Captain's Lower Hold, and top of the Lighthouse Lantern Room at (76, 42, -445).
		-- =========================================================================================
		-- Procedural Boardable Pirate Galleon Ship at (-84, 0, -390)
		makePart({
			Name = "Stage3_PirateShipHull",
			Size = Vector3.new(18, 12, 38),
			Position = Vector3.new(-84, 6, -390),
			Color = Color3.fromRGB(112, 74, 42),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage3_PirateShipMast",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(37, 3.2, 3.2),
			CFrame = CFrame.new(-84, 18.5, -390) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(98, 64, 36),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage3_PirateCrowsNestDeck",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.4, 18, 18),
			CFrame = CFrame.new(-84, 37.3, -390) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(122, 78, 42),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})
		local mastTruss = Instance.new("TrussPart")
		mastTruss.Name = "Stage3_PirateRiggingLadder"
		mastTruss.Anchored = true
		mastTruss.Size = Vector3.new(2, 36, 2)
		mastTruss.Position = Vector3.new(-80, 19, -390)
		mastTruss.Color = Color3.fromRGB(138, 96, 54)
		mastTruss.Material = Enum.Material.WoodPlanks
		mastTruss.Parent = landmarksFolder

		-- Procedural Aqua Water Slide Tower at (82, 0, -375)
		makePart({
			Name = "Stage3_WaterSlideTowerBody",
			Size = Vector3.new(16, 21.5, 16),
			Position = Vector3.new(82, 10.75, -375),
			Color = Color3.fromRGB(58, 185, 205),
			Material = Enum.Material.SmoothPlastic,
			Parent = landmarksFolder,
		})

		-- Procedural Coastal Lighthouse Tower at (76, 0, -445)
		makePart({
			Name = "Stage3_LighthouseTower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(41, 12, 12),
			CFrame = CFrame.new(76, 20.5, -445) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(245, 245, 250),
			Material = Enum.Material.Concrete,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage3_LighthouseLanternDeck",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.4, 18, 18),
			CFrame = CFrame.new(76, 41.3, -445) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(195, 62, 54),
			Material = Enum.Material.Concrete,
			Parent = landmarksFolder,
		})
		local lhTruss = Instance.new("TrussPart")
		lhTruss.Name = "Stage3_LighthouseClimbLadder"
		lhTruss.Anchored = true
		lhTruss.Size = Vector3.new(2, 40, 2)
		lhTruss.Position = Vector3.new(70, 20.5, -445)
		lhTruss.Color = Color3.fromRGB(215, 218, 224)
		lhTruss.Material = Enum.Material.Metal
		lhTruss.Parent = landmarksFolder

		-- Exact Landmark Access Ladders, Decks & Stairs (Water Slide)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage3_WaterSlide", Vector3.new(82, 22.5, -375), 12, 12, Color3.fromRGB(122, 78, 42), Enum.Material.WoodPlanks)

		-- Paywall: 💎 Skip Stage 3 Obby Pad
		buildSkipObbyPaywallPad(landmarksFolder, "SkipObbyPad_3", Vector3.new(-38, 0.5, -352), Vector3.new(-84, 40.5, -390), 3)

		-- Moving Surfboard, Rigging Ladder & Mast Balance Obby from (-44, 3, -355) -> (-84, 38, -390)
		local surfColors = {
			Color3.fromRGB(58, 168, 205),
			Color3.fromRGB(218, 165, 58),
			Color3.fromRGB(205, 84, 132),
			Color3.fromRGB(78, 185, 118),
			Color3.fromRGB(212, 112, 64),
		}
		for sIdx = 1, 5 do
			local alpha = sIdx / 5
			makePart({
				Name = "SurfboardObbyStep_" .. tostring(sIdx),
				Size = Vector3.new(8.0, 1.4, 12.0),
				Position = Vector3.new(
					-44 + (-80 - -44) * alpha,
					3 + 16 * alpha,
					-355 + (-390 - -355) * alpha
				),
				Color = surfColors[sIdx],
				Material = Enum.Material.SmoothPlastic,
				Parent = landmarksFolder,
			})
		end

	elseif id == 4 then

		-- =========================================================================================
		-- STAGE 4 (Z = -480 to -640 — WHISPERING BAMBOO FOREST):
		-- Landmarks:
		--   * Twin Stone Dragon Statues (123493048047404 / StageLandmarks #12) at (-68, 0, -525) & (68, 0, -525)
		--   * 3-Story Bamboo Dojo Pagoda (101559450428915 / StageLandmarks #13) at (-82, 0, -585)
		--   * Canopy Suspension Treehouse (9839019518 / StageLandmarks #3) at (82, 18, -575)
		-- Obby & Hidden Spots:
		--   * Bamboo Pole-Jump, Truss Wall & Swinging Bridge Obby (12317896672, 14288014072)
		--     from (38, 4, -510) to (82, 34, -575) and across a narrow bamboo beam
		--     to the 3rd-Floor Pagoda Bell Chamber at (-82, 36, -585).
		-- =========================================================================================
		-- Procedural Twin Jade Dragon Shrine Pedestals at (-68, 0, -525) and (68, 0, -525)
		for _, shrineX in ipairs({ -68, 68 }) do
			makePart({
				Name = "Stage4_DragonShrinePedestal_" .. tostring(shrineX),
				Size = Vector3.new(14, 15.5, 14),
				Position = Vector3.new(shrineX, 7.75, -525),
				Color = Color3.fromRGB(72, 138, 92),
				Material = Enum.Material.Cobblestone,
				Parent = landmarksFolder,
			})
		end

		-- Procedural 3-Story Bamboo Dojo Pagoda Tower at (-82, 0, -585)
		makePart({
			Name = "Stage4_PagodaTowerBody",
			Size = Vector3.new(18, 34.5, 18),
			Position = Vector3.new(-82, 17.25, -585),
			Color = Color3.fromRGB(168, 52, 48),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage4_PagodaBellChamberDeck",
			Size = Vector3.new(20, 1.5, 20),
			Position = Vector3.new(-82, 35.4, -585),
			Color = Color3.fromRGB(168, 52, 48),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})

		-- Procedural Canopy Suspension Treehouse at (82, 0, -575)
		makePart({
			Name = "Stage4_CanopyTreehouseTrunk",
			Size = Vector3.new(16, 33, 16),
			Position = Vector3.new(82, 16.5, -575),
			Color = Color3.fromRGB(112, 158, 78),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage4_CanopyTreehouseDeck",
			Size = Vector3.new(20, 1.5, 20),
			Position = Vector3.new(82, 33.4, -575),
			Color = Color3.fromRGB(118, 158, 82),
			Material = Enum.Material.WoodPlanks,
			Parent = landmarksFolder,
		})

		-- Exact Landmark Access Ladders, Decks & Stairs (Dragon Shrine, Bamboo Canopy, Pagoda Bell Chamber)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage4_DragonShrine", Vector3.new(68, 16.5, -525), 12, 12, Color3.fromRGB(118, 158, 82), Enum.Material.Cobblestone)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage4_BambooCanopy", Vector3.new(82, 34.8, -575), 12, 12, Color3.fromRGB(118, 158, 82), Enum.Material.WoodPlanks)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage4_PagodaBellChamber", Vector3.new(-82, 36.8, -585), 12, 12, Color3.fromRGB(168, 52, 48), Enum.Material.WoodPlanks)

		-- Paywall: 💎 Skip Stage 4 Obby Pad
		buildSkipObbyPaywallPad(landmarksFolder, "SkipObbyPad_4", Vector3.new(32, 0.5, -508), Vector3.new(82, 36.5, -575), 4)

		-- Bamboo Pole-Jump, Truss Wall & Swinging Bridge Obby from (38, 4, -510) -> (82, 34, -575) -> (-82, 36, -585)
		for pole = 1, 6 do
			local alpha = pole / 6
			local pHeight = 4 + 29.4 * alpha
			makePart({
				Name = "BambooPoleJump_" .. tostring(pole),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(pHeight, 8.5, 8.5),
				CFrame = CFrame.new(
					38 + (82 - 38) * alpha,
					pHeight * 0.5,
					-510 + (-575 - -510) * alpha
				) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(88, 164, 78),
				Material = Enum.Material.WoodPlanks,
				Parent = landmarksFolder,
			})
		end
		-- High Bamboo Balance Beam from Canopy Treehouse (82, 34, -575) to Pagoda Bell Chamber (-82, 36, -585)
		for seg = 1, 10 do
			local alpha = (seg - 0.5) / 10
			makePart({
				Name = "BambooSkyBridgeBeam_" .. tostring(seg),
				Size = Vector3.new(16.0, 1.4, 6.5),
				Position = Vector3.new(
					82 + (-82 - 82) * alpha,
					33.4 + (35.4 - 33.4) * alpha,
					-575 + (-585 - -575) * alpha
				),
				Color = Color3.fromRGB(98, 172, 84),
				Material = Enum.Material.WoodPlanks,
				Parent = landmarksFolder,
			})
		end

	elseif id == 5 then

		-- =========================================================================================
		-- STAGE 5 (Z = -640 to -800 — CRYSTAL CYBER CAVERN):
		-- Landmarks:
		--   * Deep Amethyst Crystal Cave (3858204539 / StageLandmarks #14) at (-84, 0, -700)
		--   * Dark Slate Cyber Tower (116874485094995 / StageLandmarks #15) at (84, 0, -715)
		--   * Retro Arcade Hall (73198167966628 / StageLandmarks #16) at (-74, 0, -765)
		-- Obby & Hidden Spots:
		--   * Timed Disappearing-Tile & Sweeper Spinner Tower Obby (76697739621349, 1172079000)
		--     from (44, 4, -675) scaling the Cyber Tower Exterior to (84, 44, -715)
		--     and deep inside the Crystal Cave Labyrinth at (-92, 4, -710).
		-- =========================================================================================
		-- Procedural Giant Amethyst Crystal Spire at (-84, 0, -700)
		makePart({
			Name = "Stage5_AmethystCrystalSpire",
			Size = Vector3.new(16, 27.5, 16),
			Position = Vector3.new(-84, 13.75, -700),
			Color = Color3.fromRGB(152, 65, 235),
			Material = Enum.Material.Neon,
			Parent = landmarksFolder,
		})

		-- Procedural Dark Slate Cyber Skyscraper at (84, 0, -715)
		makePart({
			Name = "Stage5_CyberTowerBody",
			Size = Vector3.new(18, 42.5, 18),
			Position = Vector3.new(84, 21.25, -715),
			Color = Color3.fromRGB(42, 48, 64),
			Material = Enum.Material.Slate,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage5_CyberTowerPenthouseDeck",
			Size = Vector3.new(20, 1.5, 20),
			Position = Vector3.new(84, 43.3, -715),
			Color = Color3.fromRGB(48, 54, 72),
			Material = Enum.Material.Slate,
			Parent = landmarksFolder,
		})

		-- Procedural Cyber Arcade Building at (-74, 0, -765)
		makePart({
			Name = "Stage5_RetroArcadeBuilding",
			Size = Vector3.new(16, 15.5, 16),
			Position = Vector3.new(-74, 7.75, -765),
			Color = Color3.fromRGB(62, 54, 98),
			Material = Enum.Material.Slate,
			Parent = landmarksFolder,
		})

		makePart({
			Name = "Stage5_CrystalCaveLabyrinthFloor",
			Size = Vector3.new(18, 1.0, 18),
			Position = Vector3.new(-92, 0.5, -710),
			Color = Color3.fromRGB(78, 58, 112),
			Material = Enum.Material.Slate,
			Parent = landmarksFolder,
		})

		-- Exact Landmark Access Ladders, Decks & Stairs (Retro Arcade, Amethyst Spire, Cyber Penthouse)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage5_RetroArcade", Vector3.new(-74, 16.5, -765), 12, 12, Color3.fromRGB(48, 54, 72), Enum.Material.Slate)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage5_AmethystSpire", Vector3.new(-84, 28.8, -700), 14, 14, Color3.fromRGB(78, 58, 112), Enum.Material.Slate)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage5_CyberPenthouse", Vector3.new(84, 44.8, -715), 14, 14, Color3.fromRGB(48, 54, 72), Enum.Material.Slate)

		-- Paywall: 💎 Skip Stage 5 Obby Pad
		buildSkipObbyPaywallPad(landmarksFolder, "SkipObbyPad_5", Vector3.new(38, 0.5, -672), Vector3.new(84, 46.5, -715), 5)

		-- Timed Disappearing-Tile & Sweeper Spinner Tower Obby from (44, 4, -675) -> (84, 44, -715)
		for step = 1, 8 do
			local alpha = step / 8
			local cPlat = makePart({
				Name = "CyberTowerClimbStep_" .. tostring(step),
				Size = Vector3.new(9.5, 1.6, 7.5),
				Position = Vector3.new(
					44 + (84 - 44) * alpha,
					4 + 39.3 * alpha,
					-675 + (-715 - -675) * alpha
				),
				Color = if step % 2 == 0 then Color3.fromRGB(68, 148, 195) else Color3.fromRGB(112, 74, 168),
				Material = Enum.Material.Slate,
				Parent = landmarksFolder,
			})
			if step % 2 == 0 then
				cPlat:SetAttribute("CrystalPlatform", step)
				cPlat:SetAttribute("BaseX", cPlat.Position.X)
				cPlat:SetAttribute("BaseY", cPlat.Position.Y)
				cPlat:SetAttribute("BaseZ", cPlat.Position.Z)
			end
		end

	elseif id == 6 then

		-- =========================================================================================
		-- STAGE 6 (Z = -800 to -960 — CLOUD SKY SANCTUARY):
		-- Landmarks:
		--   * Giant Rotating Sky Ferris Wheel (85537579537253 / StageLandmarks #17) at (-85, 0, -865)
		--   * Marble Cloud & Ice Palace (154465953 / StageLandmarks #19) at (85, 0, -885)
		--   * High Arching Sky Bridge (2135149422 / StageLandmarks #18) spanning (-70, 22, -915) to (70, 22, -915)
		-- Obby & Hidden Spots:
		--   * Trampoline Bounce-Chain & Moving Cloud Obby (82837302167177, 2135149422)
		--     from (-45, 2, -835) onto the High Sky Bridge (Y = 28), inside the Ice Palace Vault,
		--     and up to the Ferris Wheel Top Cabin at (-85, 48, -865).
		-- =========================================================================================
		-- Procedural Twin A-Frame & Sky Ferris Wheel Ring at (-85, 0, -865)
		makePart({
			Name = "Stage6_FerrisWheelAFrame",
			Size = Vector3.new(16, 46.5, 16),
			Position = Vector3.new(-85, 23.25, -865),
			Color = Color3.fromRGB(225, 205, 115),
			Material = Enum.Material.Marble,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage6_FerrisWheelTopCabinDeck",
			Size = Vector3.new(18, 1.5, 18),
			Position = Vector3.new(-85, 47.4, -865),
			Color = Color3.fromRGB(218, 188, 92),
			Material = Enum.Material.Marble,
			Parent = landmarksFolder,
		})

		-- Procedural Marble Cloud & Ice Palace at (85, 0, -885)
		makePart({
			Name = "Stage6_IcePalaceTowerBody",
			Size = Vector3.new(18, 23.5, 18),
			Position = Vector3.new(85, 11.75, -885),
			Color = Color3.fromRGB(215, 230, 245),
			Material = Enum.Material.Ice,
			Parent = landmarksFolder,
		})

		-- High Arching Sky Bridge Deck spanning (-70, 22, -915) to (70, 22, -915) with apex Y = 28
		for seg = 1, 11 do
			local alpha = (seg - 0.5) / 11
			local archY = 22 + math.sin(alpha * math.pi) * 6.0
			makePart({
				Name = "Stage6_SkyBridgeArchSegment_" .. tostring(seg),
				Size = Vector3.new(13.5, 1.2, 8.5),
				Position = Vector3.new(-70 + 140 * alpha, archY, -915),
				Color = Color3.fromRGB(225, 232, 242),
				Material = Enum.Material.Marble,
				Parent = landmarksFolder,
			})
		end

		-- Exact Landmark Access Ladders, Decks & Stairs (Ice Palace, Ferris Wheel Summit, Sky Bridge Dual Ladders)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage6_IcePalace", Vector3.new(85, 24.5, -885), 14, 14, Color3.fromRGB(225, 232, 242), Enum.Material.Marble)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage6_FerrisWheelSummit", Vector3.new(-85, 48.8, -865), 14, 14, Color3.fromRGB(218, 188, 92), Enum.Material.Marble)

		local sbTrussL = Instance.new("TrussPart")
		sbTrussL.Name = "Stage6_SkyBridgeLadderWest"
		sbTrussL.Anchored = true
		sbTrussL.Size = Vector3.new(2, 22, 2)
		sbTrussL.Position = Vector3.new(-70, 11.0, -915)
		sbTrussL.Color = Color3.fromRGB(215, 220, 235)
		sbTrussL.Material = Enum.Material.Metal
		sbTrussL.Parent = landmarksFolder

		local sbTrussR = Instance.new("TrussPart")
		sbTrussR.Name = "Stage6_SkyBridgeLadderEast"
		sbTrussR.Anchored = true
		sbTrussR.Size = Vector3.new(2, 22, 2)
		sbTrussR.Position = Vector3.new(70, 11.0, -915)
		sbTrussR.Color = Color3.fromRGB(215, 220, 235)
		sbTrussR.Material = Enum.Material.Metal
		sbTrussR.Parent = landmarksFolder

		-- Paywall: 💎 Skip Stage 6 Obby Pad
		buildSkipObbyPaywallPad(landmarksFolder, "SkipObbyPad_6", Vector3.new(-38, 0.5, -832), Vector3.new(-85, 50.5, -865), 6)

		-- Trampoline Bounce-Chain & Moving Cloud Obby from (-45, 2, -835) -> Sky Bridge -> Ferris Wheel Top Cabin (-85, 48, -865)
		for b = 1, 5 do
			local alpha = b / 5
			local cBounce = buildGlowingNeonCircle(
				landmarksFolder,
				"BouncePad",
				Vector3.new(
					-45 + (-85 - -45) * alpha,
					2 + 44 * alpha,
					-835 + (-865 - -835) * alpha
				),
				11.5,
				Color3.fromRGB(165, 198, 228),
				Color3.fromRGB(225, 198, 98)
			)
			cBounce:SetAttribute("BounceImpulse", 98)
		end

	elseif id == 7 then

		-- =========================================================================================
		-- STAGE 7 (Z = -960 to -1120 — MAGMA VOLCANO DOOM):
		-- Landmarks:
		--   * Giant Basalt Volcano Crater (256969126 / StageLandmarks #20) at (-86, 0, -1035)
		--   * Obsidian Skull Fortress (16437023855 / StageLandmarks #21) at (86, 0, -1045)
		--   * Basalt Highway Bridges over Lava Trenches at Z = -995, -1075
		-- Obby & Hidden Spots:
		--   * Sinking Basalt Pillars & Double Fire-Spinner Obby (4644268803, 79641631925549)
		--     from (-44, 3, -990) spiraling up the Volcano Crater Rim to (-86, 46, -1035)
		--     and across to the Obsidian Fortress Roof at (86, 42, -1045).
		-- =========================================================================================
		-- Procedural Giant Basalt Volcano Cone at (-86, 0, -1035)
		makePart({
			Name = "Stage7_BasaltVolcanoCone",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(44.5, 26, 26),
			CFrame = CFrame.new(-86, 22.25, -1035) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(48, 44, 46),
			Material = Enum.Material.Basalt,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage7_VolcanoCraterRimDeck",
			Size = Vector3.new(20, 1.5, 20),
			Position = Vector3.new(-86, 45.3, -1035),
			Color = Color3.fromRGB(58, 52, 56),
			Material = Enum.Material.Basalt,
			Parent = landmarksFolder,
		})

		-- Procedural Obsidian Skull Fortress Keep at (86, 0, -1045)
		makePart({
			Name = "Stage7_ObsidianKeepBody",
			Size = Vector3.new(20, 40.5, 20),
			Position = Vector3.new(86, 20.25, -1045),
			Color = Color3.fromRGB(38, 34, 42),
			Material = Enum.Material.Basalt,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage7_ObsidianFortressRoofDeck",
			Size = Vector3.new(20, 1.5, 20),
			Position = Vector3.new(86, 41.3, -1045),
			Color = Color3.fromRGB(42, 38, 46),
			Material = Enum.Material.Basalt,
			Parent = landmarksFolder,
		})

		-- Basalt Highway Bridges over Lava Trenches at Z = -995 and Z = -1075
		for _, bridgeZ in ipairs({ -995, -1075 }) do
			makePart({
				Name = "LavaTrench_" .. tostring(math.abs(bridgeZ)),
				Size = Vector3.new(196, 0.8, 12),
				Position = Vector3.new(0, 0.15, bridgeZ),
				Color = Color3.fromRGB(185, 68, 28),
				Material = Enum.Material.Slate,
				Parent = obstaclesFolder,
			})
			makePart({
				Name = "BasaltHighwayBridge_" .. tostring(math.abs(bridgeZ)),
				Size = Vector3.new(42, 1.6, 16),
				Position = Vector3.new(0, 0.8, bridgeZ),
				Color = Color3.fromRGB(54, 52, 58),
				Material = Enum.Material.Basalt,
				Parent = landmarksFolder,
			})
		end

		-- Exact Landmark Access Ladders, Decks & Stairs (Volcano Crater, Obsidian Fortress)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage7_VolcanoCrater", Vector3.new(-86, 46.8, -1035), 14, 14, Color3.fromRGB(58, 52, 56), Enum.Material.Basalt)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage7_ObsidianFortress", Vector3.new(86, 42.8, -1045), 14, 14, Color3.fromRGB(42, 38, 46), Enum.Material.Basalt)

		-- Paywall: 💎 Skip Stage 7 Obby Pad
		buildSkipObbyPaywallPad(landmarksFolder, "SkipObbyPad_7", Vector3.new(-38, 0.5, -988), Vector3.new(-86, 48.5, -1035), 7)

		-- Sinking Basalt Pillars & Double Fire-Spinner Obby from (-44, 3, -990) -> (-86, 46, -1035) -> (86, 42, -1045)
		for p = 1, 7 do
			local alpha = p / 7
			local pH = 3 + 42.3 * alpha
			makePart({
				Name = "BasaltObbyPillar_" .. tostring(p),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(pH, 10.0, 10.0),
				CFrame = CFrame.new(
					-44 + (-86 - -44) * alpha,
					pH * 0.5,
					-990 + (-1035 - -990) * alpha
				) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(64, 56, 62),
				Material = Enum.Material.Basalt,
				Parent = landmarksFolder,
			})
		end
		-- High Basalt Chain Bridge from Volcano Crater Rim (-86, 46, -1035) to Obsidian Fortress Roof (86, 42, -1045)
		for seg = 1, 10 do
			local alpha = (seg - 0.5) / 10
			makePart({
				Name = "ObsidianSkySpan_" .. tostring(seg),
				Size = Vector3.new(16.5, 1.4, 7.0),
				Position = Vector3.new(
					-86 + (86 - -86) * alpha,
					45.3 + (41.3 - 45.3) * alpha,
					-1035 + (-1045 - -1035) * alpha
				),
				Color = Color3.fromRGB(52, 48, 56),
				Material = Enum.Material.Basalt,
				Parent = landmarksFolder,
			})
		end

	else

		-- =========================================================================================
		-- STAGE 8 (Z = -1120 to -1280 — COSMIC VOID CITADEL):
		-- Landmarks:
		--   * Hovering Alien UFO Mothership (50089105 / StageLandmarks #22) at (-84, 36, -1185)
		--   * Twin Void Stone Portals (171327489 / StageLandmarks #23) at (-65, 0, -1150) & (65, 0, -1150)
		--   * Grand Champion Throne Citadel (4790754477 / StageLandmarks #24) at (0, 14, -1262)
		-- Obby & Hidden Spots:
		--   * Moving Asteroid Gauntlet & UFO Climb Obby (134019342626406, 73062373189329)
		--     from (42, 4, -1155) ascending into the UFO Mothership Deck at (-84, 36, -1185)
		--     and across a high walkway to the Champion Throne Summit at (0, 24, -1262).
		-- =========================================================================================
		-- Procedural Hovering Alien UFO Mothership at (-84, 35.0, -1185)
		makePart({
			Name = "Stage8_UFOSaucerRim",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3.5, 34, 34),
			CFrame = CFrame.new(-84, 34.0, -1185) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(98, 102, 118),
			Material = Enum.Material.Metal,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage8_UFOGlassCockpit",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(14, 9, 14),
			Position = Vector3.new(-84, 37.5, -1185),
			Color = Color3.fromRGB(85, 235, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.35,
			CanCollide = false,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage8_UFOMothershipDeck",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.0, 28, 28),
			CFrame = CFrame.new(-84, 35.0, -1185) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(68, 72, 88),
			Material = Enum.Material.Metal,
			Parent = landmarksFolder,
		})

		-- Procedural Void Portal Tower at (84, 0, -1185)
		makePart({
			Name = "Stage8_VoidPortalTower",
			Size = Vector3.new(16, 17.5, 16),
			Position = Vector3.new(84, 8.75, -1185),
			Color = Color3.fromRGB(58, 42, 84),
			Material = Enum.Material.Slate,
			Parent = landmarksFolder,
		})

		-- Procedural Grand Champion Golden Throne Citadel at (0, 0, -1262)
		makePart({
			Name = "Stage8_ChampionThroneCitadelBody",
			Size = Vector3.new(24, 22.5, 20),
			Position = Vector3.new(0, 11.25, -1262),
			Color = Color3.fromRGB(198, 162, 64),
			Material = Enum.Material.Marble,
			Parent = landmarksFolder,
		})
		makePart({
			Name = "Stage8_ChampionThroneSummitDeck",
			Size = Vector3.new(22, 1.5, 18),
			Position = Vector3.new(0, 23.25, -1262),
			Color = Color3.fromRGB(198, 162, 64),
			Material = Enum.Material.Marble,
			Parent = landmarksFolder,
		})

		-- Exact Landmark Access Ladders, Decks & Stairs (Portal Pedestal, UFO Mothership, Throne Citadel)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage8_PortalPedestal", Vector3.new(84, 18.5, -1185), 14, 14, Color3.fromRGB(68, 72, 88), Enum.Material.Metal)
		buildLandmarkAccessLadderAndDeck(landmarksFolder, "Stage8_UFOMothership", Vector3.new(-84, 36.8, -1185), 16, 16, Color3.fromRGB(68, 72, 88), Enum.Material.Metal)

		-- Glowing Cyan/Purple Tractor-Beam TrussPart Ladder under UFO Mothership
		local tractorBeamLadder = Instance.new("TrussPart")
		tractorBeamLadder.Name = "Stage8_UFOTractorBeamLadder"
		tractorBeamLadder.Anchored = true
		tractorBeamLadder.Size = Vector3.new(2.4, 35, 2.4)
		tractorBeamLadder.Position = Vector3.new(-72, 17.5, -1185)
		tractorBeamLadder.Color = Color3.fromRGB(85, 235, 255)
		tractorBeamLadder.Material = Enum.Material.Neon
		tractorBeamLadder.Parent = landmarksFolder

		-- Direct Throne Summit Ladder
		local throneLadder = Instance.new("TrussPart")
		throneLadder.Name = "Stage8_ThroneSummitLadder"
		throneLadder.Anchored = true
		throneLadder.Size = Vector3.new(2, 24, 2)
		throneLadder.Position = Vector3.new(12, 12.0, -1262)
		throneLadder.Color = Color3.fromRGB(255, 215, 65)
		throneLadder.Material = Enum.Material.Metal
		throneLadder.Parent = landmarksFolder

		-- Paywall: 💎 Skip Stage 8 Obby Pad
		buildSkipObbyPaywallPad(landmarksFolder, "SkipObbyPad_8", Vector3.new(36, 0.5, -1152), Vector3.new(-84, 38.5, -1185), 8)

		-- Moving Asteroid Gauntlet & UFO Climb Obby from (42, 4, -1155) -> (-84, 36, -1185) -> (0, 24, -1262)
		for ast = 1, 8 do
			local alpha = ast / 8
			local astPart = makePart({
				Name = "CosmicAsteroidStep_" .. tostring(ast),
				Size = Vector3.new(10.0, 2.2, 9.5),
				Position = Vector3.new(
					42 + (-84 - 42) * alpha,
					4 + 31.0 * alpha,
					-1155 + (-1185 - -1155) * alpha
				),
				Color = Color3.fromRGB(58, 52, 74),
				Material = Enum.Material.Basalt,
				Parent = landmarksFolder,
			})
			if ast % 2 == 0 then
				astPart:SetAttribute("CrystalPlatform", ast)
				astPart:SetAttribute("BaseX", astPart.Position.X)
				astPart:SetAttribute("BaseY", astPart.Position.Y)
				astPart:SetAttribute("BaseZ", astPart.Position.Z)
			end
		end
		-- High Citadel Walkway from UFO Mothership Deck (-84, 36, -1185) to Champion Throne Summit (0, 24, -1262)
		for seg = 1, 7 do
			local alpha = seg / 7
			makePart({
				Name = "ThroneSummitWalkway_" .. tostring(seg),
				Size = Vector3.new(13.5, 1.5, 8.0),
				Position = Vector3.new(
					-84 + (0 - -84) * alpha,
					35.0 + (23.25 - 35.0) * alpha,
					-1185 + (-1262 - -1185) * alpha
				),
				Color = Color3.fromRGB(78, 72, 98),
				Material = Enum.Material.Slate,
				Parent = landmarksFolder,
			})
		end
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
		Material = Enum.Material.Glass,
		Transparency = 0.72,
		CanCollide = false,
		Parent = obstaclesFolder,
	})
	centerBridge:SetAttribute("ShortcutBridgeLevel", id)
end

-- =========================================================================================
-- PHASE 2.2: CENTRAL PAVED HIGHWAY ROAD IN THE MIDDLE OF THE MAP (X = 0, Z = +180 to -1280)
--   * 36-Stud-Wide Dark Charcoal Matte Asphalt Road (Color3.fromRGB(42, 44, 48), Enum.Material.Asphalt)
--     running straight down X = -18 to +18 from Z = +180 (Safe Zone) to Z = -1280 (Stage 8).
--   * Raised Concrete Sidewalks & Curbs at X = -20 and X = +20 (Enum.Material.Concrete).
--   * Matte painted yellow dashed center lines, white crosswalks at each Stage Gate, and
--     Cobblestone Driveways branching into all Player Plots and each Stage's Boss Nest & Obby!
-- =========================================================================================
local function buildCentralHighwayRoad(worldFolder: Folder)
	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "CentralHighwayRoad"
	roadFolder.Parent = worldFolder

	local zNorthEnd = -1280
	local zSouthEnd = 180
	local totalRoadLength = zSouthEnd - zNorthEnd -- 1460 studs
	local zCenter = (zSouthEnd + zNorthEnd) * 0.5 -- -550

	-- 1. 36-Stud-Wide Dark Charcoal Matte Asphalt Highway Deck
	makePart({
		Name = "MainAsphaltHighway",
		Size = Vector3.new(36, 0.36, totalRoadLength),
		Position = Vector3.new(0, 0.18, zCenter),
		Color = Color3.fromRGB(42, 44, 48),
		Material = Enum.Material.Asphalt,
		Parent = roadFolder,
	})

	-- 2. Raised 4-Stud Concrete Sidewalks & Curbs on Left (X = -20) and Right (X = +20)
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = if side < 0 then "WestConcreteSidewalk" else "EastConcreteSidewalk",
			Size = Vector3.new(4.0, 0.62, totalRoadLength),
			Position = Vector3.new(side * 20, 0.31, zCenter),
			Color = Color3.fromRGB(168, 172, 178),
			Material = Enum.Material.Concrete,
			Parent = roadFolder,
		})
	end

	-- 3. Matte Painted Double-Yellow Dashed Center Striping down X = 0
	for zDash = zSouthEnd - 12, zNorthEnd + 12, -24 do
		makePart({
			Name = "HighwayYellowCenterDash",
			Size = Vector3.new(1.1, 0.38, 11.0),
			Position = Vector3.new(0, 0.20, zDash),
			Color = Color3.fromRGB(218, 182, 52),
			Material = Enum.Material.Concrete,
			CanCollide = false,
			Parent = roadFolder,
		})
	end

	-- 4. White Matte Crosswalks at Every Stage Gate (Z = 0, -160, -320, -480, -640, -800, -960, -1120) & Safe Zone (Z = 172)
	local crosswalkZs = { 172, 0, -160, -320, -480, -640, -800, -960, -1120 }
	for _, cwZ in ipairs(crosswalkZs) do
		for stripe = -14, 14, 4 do
			makePart({
				Name = "HighwayCrosswalkStripe",
				Size = Vector3.new(2.2, 0.40, 7.5),
				Position = Vector3.new(stripe, 0.21, cwZ - 5),
				Color = Color3.fromRGB(232, 236, 240),
				Material = Enum.Material.Concrete,
				CanCollide = false,
				Parent = roadFolder,
			})
		end
	end

	-- 5. Cobblestone Driveways branching from Central Highway into Safe Zone Player Plots (Z = 54 & 136)
	for _, plotZ in ipairs({ 54, 136 }) do
		for _, side in ipairs({ -1, 1 }) do
			makePart({
				Name = "PlotCobblestoneDriveway",
				Size = Vector3.new(46, 0.28, 14),
				Position = Vector3.new(side * 44, 0.14, plotZ),
				Color = Color3.fromRGB(148, 144, 136),
				Material = Enum.Material.Cobblestone,
				Parent = roadFolder,
			})
		end
	end

	-- 6. Cobblestone Branch Spurs into Each Stage's Entry Plaza, Landmarks/Obby & Boss Nest (Stages 1–8)
	for stageId = 1, 8 do
		local stageZStart = -(stageId - 1) * 160
		for _, spurOffset in ipairs({ -16, -65, -116 }) do
			makePart({
				Name = string.format("Stage%d_CobbleSpur_%d", stageId, math.abs(spurOffset)),
				Size = Vector3.new(112, 0.26, 10),
				Position = Vector3.new(0, 0.13, stageZStart + spurOffset),
				Color = Color3.fromRGB(138, 134, 128),
				Material = Enum.Material.Cobblestone,
				CanCollide = false,
				Parent = roadFolder,
			})
		end
	end
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
		Color = Color3.fromRGB(74, 134, 66),
		Material = Enum.Material.LeafyGrass,
		Parent = hubFolder,
	})

	-- Wide South Village Cross-Boulevard (Z = 178, X = -190..+190) in grounded Matte Asphalt + Concrete Curbs
	makePart({
		Name = "SouthBoulevardPath",
		Size = Vector3.new(380, 0.25, 24),
		Position = Vector3.new(0, 0.12, 178),
		Color = Color3.fromRGB(48, 50, 56),
		Material = Enum.Material.Asphalt,
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
		"🥚 Find my Squishy and steal my egg (brainrot)\nFollow the Central Highway -> Steal Brainrot Eggs & Find 117 Squishies Across Stages 1-8!",
		Color3.fromRGB(255, 235, 90),
		Vector3.new(0, 2.5, 0),
		UDim2.new(11.5, 0, 2.4, 0),
		75
	)

	-- Build the Giant Rainbow Disappearing Staircase on Stage 1's dedicated Outer West Sky Plaza (X = -236, Z = -20..-148)!
	buildRainbowDisappearingStaircase(worldFolder)

	-- Build Global Top-10 OrderedDataStore 3D Leaderboards + Spin Wheel, Daily Chest & VIP Robux Shop Booths!
	buildHubRetentionBoothsAndLeaderboards(hubFolder, obstaclesFolder)

	-- Build the 4 Widely Spaced Fenced Player Base Plots (X = ±94, Z = 54 & 136 — 188 studs across road, 82 studs North-to-South!)
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "PlayerPlots"
	plotsFolder.Parent = worldFolder

	local plotConfigs = {
		{ Index = 1, Center = Vector3.new(-94, 0, 54), Color = Color3.fromRGB(80, 165, 215), Roof = Color3.fromRGB(45, 85, 165), FaceDir = 1 },
		{ Index = 2, Center = Vector3.new(94, 0, 54), Color = Color3.fromRGB(205, 125, 165), Roof = Color3.fromRGB(145, 52, 108), FaceDir = -1 },
		{ Index = 3, Center = Vector3.new(-94, 0, 136), Color = Color3.fromRGB(105, 185, 115), Roof = Color3.fromRGB(48, 125, 68), FaceDir = 1 },
		{ Index = 4, Center = Vector3.new(94, 0, 136), Color = Color3.fromRGB(215, 175, 88), Roof = Color3.fromRGB(165, 64, 52), FaceDir = -1 },
	}

	local plotW = 64
	local plotD = 56

	for _, cfg in ipairs(plotConfigs) do
		local plotModel = Instance.new("Model")
		plotModel.Name = "Plot_" .. tostring(cfg.Index)
		plotModel:SetAttribute("PlotIndex", cfg.Index)
		plotModel.Parent = plotsFolder

		local basePad = makePart({
			Name = "BasePad",
			Size = Vector3.new(plotW, 0.5, plotD),
			Position = cfg.Center + Vector3.new(0, 0.25, 0),
			Color = Color3.fromRGB(82, 148, 74),
			Material = Enum.Material.LeafyGrass,
			Parent = plotModel,
		})
		plotModel.PrimaryPart = basePad

		-- Chapter 4 Procedural Picket Fences around the North, South, and Outer Back edges of each Plot!
		local fenceColor = Color3.fromRGB(148, 98, 56)
		local picketColor = Color3.fromRGB(228, 218, 198)
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
		local treadCenter = cfg.Center + Vector3.new(-cfg.FaceDir * 9, 0.5, -13.5)
		buildDinoJawTreadmill(plotModel, treadCenter, cfg.FaceDir, cfg.Index)

		-- Front Apron X-coordinate: 8.5 studs cleanly OUTSIDE the Hatchery Fence front wall (cfg.Center.X + FaceDir * 27.0)
		local apronX = cfg.Center.X + cfg.FaceDir * 27.0

		-- 2. Grounded Matte Speed Upgrade Circle (Outside Fence, North End beside Treadmill: Z = -20.0)
		local upgStand = buildGlowingNeonCircle(
			plotModel,
			"SpeedUpgradeStand",
			Vector3.new(apronX, 0.7, cfg.Center.Z - 20.0),
			6.2,
			Color3.fromRGB(65, 185, 225),
			Color3.fromRGB(165, 105, 225)
		)
		createAttachmentPrompt(upgStand, "UpgradeSpeedPrompt", "Upgrade Treadmill (+Speed)", "🦖 Cost: $50", Vector3.new(0, 2.5, 0), 14)

		-- 3. Grounded Matte Cash Collector Circle (Outside Fence, North-Center Apron: Z = -9.0, 11 studs from SpeedUpgradeStand)
		local collectPad = buildGlowingNeonCircle(
			plotModel,
			"CollectCashPad",
			Vector3.new(apronX, 0.6, cfg.Center.Z - 9.0),
			7.4,
			Color3.fromRGB(65, 215, 105),
			Color3.fromRGB(225, 195, 75)
		)
		createBillboardText(
			collectPad,
			"💰 COLLECT $0\n(Step Here)",
			Color3.fromRGB(95, 255, 130),
			Vector3.new(0, 4.2, 0),
			UDim2.new(6.5, 0, 1.6, 0),
			42
		)

		-- 4. Fenced Brainrot Hatchery & Roaming Ranch Pen (`HatcheryPen` — Walk-In Auto-Drop, Hatch Timer 00:05 -> Live Roaming & Growing Brainrots!)
		local penCenter = cfg.Center + Vector3.new(cfg.FaceDir * 6.5, 0.55, 5.0)
		local penW = 24.0
		local penD = 18.0

		local hatcheryPen = Instance.new("Model")
		hatcheryPen.Name = "HatcheryPen"
		hatcheryPen:SetAttribute("PlotIndex", cfg.Index)
		hatcheryPen:SetAttribute("FenceLevel", 1)
		hatcheryPen:SetAttribute("FaceDir", cfg.FaceDir)
		hatcheryPen:SetAttribute("BaseCenterX", penCenter.X)
		hatcheryPen:SetAttribute("BaseCenterY", penCenter.Y)
		hatcheryPen:SetAttribute("BaseCenterZ", penCenter.Z)
		hatcheryPen.Parent = plotModel

		local penFloor = makePart({
			Name = "HatcheryPenFloor",
			Size = Vector3.new(penW, 0.32, penD),
			Position = penCenter,
			Color = Color3.fromRGB(92, 168, 78),
			Material = Enum.Material.LeafyGrass,
			Parent = hatcheryPen,
		})
		hatcheryPen.PrimaryPart = penFloor

		-- Walk-In Auto-Drop Trigger Zone inside the Fenced Pen
		local dropZone = makePart({
			Name = "HatcheryDropZone",
			Size = Vector3.new(penW - 1.2, 0.4, penD - 1.2),
			Position = penCenter + Vector3.new(0, 0.08, 0),
			Color = Color3.fromRGB(225, 195, 75),
			Material = Enum.Material.Glass,
			Transparency = 0.82,
			CanCollide = false,
			Parent = hatcheryPen,
		})
		dropZone:SetAttribute("PlotIndex", cfg.Index)

		-- 4-Sided Matte Wooden/Iron Ranch Enclosure around the Hatchery Pen (stored in `FenceWalls` so `resizePlayerFencePen` Lv.1->Lv.8 dynamically rebuilds it!)
		local fenceWallsFolder = Instance.new("Folder")
		fenceWallsFolder.Name = "FenceWalls"
		fenceWallsFolder.Parent = hatcheryPen

		-- Ranch Archway Gate & Overhead Sign at the Front Entrance of the Hatchery Pen
		for postIdx, gateZ in ipairs({ -4.2, 4.2 }) do
			makePart({
				Name = "HatcheryGatePost_" .. tostring(postIdx),
				Size = Vector3.new(1.2, 8.8, 1.2),
				Position = penCenter + Vector3.new(cfg.FaceDir * (penW * 0.5), 4.4, gateZ),
				Color = Color3.fromRGB(168, 118, 58),
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
			"🥚 BRAINROT HATCHERY & RANCH PEN\nWalk In With Eggs -> Hatch & Roam Inside Fence!",
			Color3.fromRGB(255, 235, 85),
			Color3.fromRGB(24, 30, 52),
			{ Enum.NormalId.Left, Enum.NormalId.Right },
			150
		)

		-- 5.1 🌱 OUTSIDE FENCE (Center-South Apron, Z = cfg.Center.Z + 12.5): Grow & Level Up Brainrot Stand (`GrowSquishyStand`, Lv. 1 -> Lv. 15)
		local growStandPos = Vector3.new(apronX, penCenter.Y + 0.15, penCenter.Z + 7.5)
		local growStand = buildGlowingNeonCircle(
			hatcheryPen,
			"GrowSquishyStand",
			growStandPos,
			4.8,
			Color3.fromRGB(78, 178, 98),
			Color3.fromRGB(215, 185, 68)
		)
		local growPost = makePart({
			Name = "GrowStandPost",
			Size = Vector3.new(1.1, 4.6, 1.1),
			Position = growStandPos + Vector3.new(0, 2.3, 0),
			Color = Color3.fromRGB(122, 84, 48),
			Material = Enum.Material.WoodPlanks,
			Parent = growStand,
		})
		local growBoard = makePart({
			Name = "GrowStandBoard",
			Size = Vector3.new(1.0, 2.4, 5.8),
			Position = growStandPos + Vector3.new(0, 5.2, 0),
			Color = Color3.fromRGB(36, 78, 48),
			Material = Enum.Material.SmoothPlastic,
			Parent = growStand,
		})
		createSurfaceSign(
			growBoard,
			"🌱 GROW BRAINROT\nLv. 1 -> Lv. 15 (+$/s & Size!)",
			Color3.fromRGB(165, 255, 175),
			Color3.fromRGB(22, 46, 28),
			{ Enum.NormalId.Left, Enum.NormalId.Right },
			95
		)
		local growBb = createBillboardText(
			growStand,
			"🌱 GROW / LEVEL UP BRAINROT (Lv.1 -> Lv.15)\nBoosts $/sec & Giant Size!",
			Color3.fromRGB(125, 245, 145),
			Vector3.new(0, 6.8, 0),
			UDim2.new(6.8, 0, 1.6, 0),
			38
		)
		growBb.Name = "GrowStandBillboard"
		createAttachmentPrompt(
			growStand,
			"UpgradeSquishyPenPrompt",
			"🌱 Grow & Level Up Brainrot (Lv.1 -> Lv.15)",
			"🏡 Brainrot Ranch Grow Station (+$/s & Size)",
			Vector3.new(0, 2.6, 0),
			14
		)

		-- 5.2 🧱 OUTSIDE FENCE (Far-South Apron, Z = cfg.Center.Z + 24.5, 12 studs from GrowSquishyStand): Upgrade Fence Size Stand (`UpgradeFenceStand`, Lv. 1 -> Lv. 8)
		local fenceStandPos = Vector3.new(apronX, penCenter.Y + 0.15, penCenter.Z + 19.5)
		local fenceStand = buildGlowingNeonCircle(
			hatcheryPen,
			"UpgradeFenceStand",
			fenceStandPos,
			4.8,
			Color3.fromRGB(205, 158, 58),
			Color3.fromRGB(82, 168, 212)
		)
		local fencePost = makePart({
			Name = "FenceStandPost",
			Size = Vector3.new(1.1, 4.6, 1.1),
			Position = fenceStandPos + Vector3.new(0, 2.3, 0),
			Color = Color3.fromRGB(98, 104, 118),
			Material = Enum.Material.Metal,
			Parent = fenceStand,
		})
		local fenceBoard = makePart({
			Name = "FenceStandBoard",
			Size = Vector3.new(1.0, 2.4, 5.8),
			Position = fenceStandPos + Vector3.new(0, 5.2, 0),
			Color = Color3.fromRGB(44, 52, 78),
			Material = Enum.Material.SmoothPlastic,
			Parent = fenceStand,
		})
		createSurfaceSign(
			fenceBoard,
			"🧱 UPGRADE FENCE SIZE\nLv. 1 -> Lv. 8 (Up to 35 Brainrots!)",
			Color3.fromRGB(255, 225, 115),
			Color3.fromRGB(24, 30, 48),
			{ Enum.NormalId.Left, Enum.NormalId.Right },
			95
		)
		local fenceBb = createBillboardText(
			fenceStand,
			"🧱 UPGRADE FENCE SIZE (Lv.1 -> Lv.2)\nFits 7 Brainrots (28x21) • $500",
			Color3.fromRGB(255, 225, 95),
			Vector3.new(0, 6.8, 0),
			UDim2.new(6.8, 0, 1.6, 0),
			38
		)
		fenceBb.Name = "FenceStandBillboard"
		createAttachmentPrompt(
			fenceStand,
			"UpgradeFencePrompt",
			"🧱 Upgrade Fence -> Lv.2 (7 Max Brainrots)",
			"Cost: $500 | Fits Stage 2 Size (28x21)",
			Vector3.new(0, 2.6, 0),
			14
		)

		-- 5 Cozy Golden Hatching Nests inside the Front Edge of the Fenced Pen (`Incubators` / `Incubator_1..5`)
		local incubatorsFolder = Instance.new("Folder")
		incubatorsFolder.Name = "Incubators"
		incubatorsFolder.Parent = plotModel

		for incIdx = 1, 5 do
			local zOff = -6.4 + (incIdx - 1) * 3.2
			local incPos = penCenter + Vector3.new(cfg.FaceDir * (penW * 0.5 - 3.2), 0.1, zOff)

			local incPad = makePart({
				Name = "Incubator_" .. tostring(incIdx),
				Size = Vector3.new(2, 0.2, 2),
				Position = incPos,
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
				Parent = incubatorsFolder,
			})
			incPad:SetAttribute("IncubatorIndex", incIdx)
			incPad:SetAttribute("State", "Empty")

			local incPrompt = createAttachmentPrompt(
				incPad,
				"IncubatorPrompt",
				"Drop Egg in Hatchery Nest",
				"Hatchery Nest #" .. tostring(incIdx),
				Vector3.new(0, 2.2, 0),
				14
			)
			incPrompt.Enabled = false
		end

		-- All 35 Roaming Ranch Pasture Spots inside the Fenced Hatchery Pen (`Pedestals` / `Pedestal_1..35`)
		local pedestalsFolder = Instance.new("Folder")
		pedestalsFolder.Name = "Pedestals"
		pedestalsFolder.Parent = plotModel

		for slotIndex = 1, 35 do
			local row = math.floor((slotIndex - 1) / 5) + 1 -- 1..7
			local col = ((slotIndex - 1) % 5) + 1 -- 1..5
			local xOff = cfg.FaceDir * (4.5 - (row - 1) * 2.4)
			local zOff = -6.0 + (col - 1) * 3.0
			local pedPos = penCenter + Vector3.new(xOff, 0.06, zOff)

			local ped = makePart({
				Name = "Pedestal_" .. tostring(slotIndex),
				Size = Vector3.new(2, 0.2, 2),
				Position = pedPos,
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
				Parent = pedestalsFolder,
			})
			ped:SetAttribute("SlotIndex", slotIndex)
		end

		-- Initialize Physical 3D Fence at Level 1 (24x18 studs, 4 Brainrots)
		WorldBuilder.ResizePlayerFencePen(plotModel, 1)
	end
end

-- 5.3 Physical 3D Fence Expansion (`resizePlayerFencePen` / `WorldBuilder.ResizePlayerFencePen`):
-- Expands the matte wooden/iron fence from 24x18 (4 Brainrots at Lv.1) -> 28x21 (7) -> 32x24 (10) -> 36x27 (14)
-- -> 40x30 (18) -> 44x33 (23) -> 48x36 (29) -> 56x42 studs (all 35 Brainrots at Lv.8!).
function WorldBuilder.ResizePlayerFencePen(plotModel: Model, fenceLevel: number)
	if not plotModel then
		return
	end
	local hatcheryPen = plotModel:FindFirstChild("HatcheryPen") :: Model?
	if not hatcheryPen then
		return
	end

	local lvl = math.clamp(tonumber(fenceLevel) or 1, 1, #SlimeData.FenceLevels)
	local curDef = SlimeData.GetFenceLevelDef(lvl) or SlimeData.FenceLevels[1]
	local penW = curDef.Width
	local penD = curDef.Depth
	local maxSlots = curDef.MaxBrainrots
	local faceDir = (hatcheryPen:GetAttribute("FaceDir") :: number?) or 1
	local baseCenter = Vector3.new(
		(hatcheryPen:GetAttribute("BaseCenterX") :: number?) or 0,
		(hatcheryPen:GetAttribute("BaseCenterY") :: number?) or 0.55,
		(hatcheryPen:GetAttribute("BaseCenterZ") :: number?) or 0
	)
	hatcheryPen:SetAttribute("FenceLevel", lvl)

	-- Keep the front entrance fixed near the central road while expanding the pen outward & backward as Width/Depth grow!
	local extraW = math.max(0, penW - 24.0)
	local extraD = math.max(0, penD - 18.0)
	local penCenter = baseCenter + Vector3.new(-faceDir * (extraW * 0.5), 0, extraD * 0.25)

	local penFloor = hatcheryPen:FindFirstChild("HatcheryPenFloor") :: BasePart?
	if penFloor then
		penFloor.Size = Vector3.new(penW, 0.32, penD)
		penFloor.Position = penCenter
	end
	local dropZone = hatcheryPen:FindFirstChild("HatcheryDropZone") :: BasePart?
	if dropZone then
		dropZone.Size = Vector3.new(penW - 1.2, 0.4, penD - 1.2)
		dropZone.Position = penCenter + Vector3.new(0, 0.08, 0)
	end

	-- Rebuild the 4-Sided Matte Wooden (Lv. 1-4) or Matte Wrought-Iron (Lv. 5-8) Fence around the expanded perimeter!
	local fenceWallsFolder = hatcheryPen:FindFirstChild("FenceWalls")
	if fenceWallsFolder then
		fenceWallsFolder:ClearAllChildren()
		local isIronTier = lvl >= 5
		local railCol = if lvl == 1 then Color3.fromRGB(168, 122, 62)
			elseif lvl == 2 then Color3.fromRGB(185, 108, 72)
			elseif lvl == 3 then Color3.fromRGB(152, 114, 68)
			elseif lvl == 4 then Color3.fromRGB(92, 154, 84)
			elseif lvl == 5 then Color3.fromRGB(78, 86, 102)
			elseif lvl == 6 then Color3.fromRGB(188, 158, 68)
			elseif lvl == 7 then Color3.fromRGB(58, 52, 68)
			else Color3.fromRGB(112, 78, 158)
		local picketCol = if isIronTier
			then Color3.fromRGB(54, 60, 74)
			else Color3.fromRGB(228, 222, 208)
		local fenceHeight = 2.6 + (lvl - 1) * 0.18

		local pFN = penCenter + Vector3.new(faceDir * (penW * 0.5), 0.1, -penD * 0.5)
		local pBN = penCenter + Vector3.new(-faceDir * (penW * 0.5), 0.1, -penD * 0.5)
		local pBS = penCenter + Vector3.new(-faceDir * (penW * 0.5), 0.1, penD * 0.5)
		local pFS = penCenter + Vector3.new(faceDir * (penW * 0.5), 0.1, penD * 0.5)
		local pGateNorth = penCenter + Vector3.new(faceDir * (penW * 0.5), 0.1, -4.2)
		local pGateSouth = penCenter + Vector3.new(faceDir * (penW * 0.5), 0.1, 4.2)

		buildProceduralPicketFence(fenceWallsFolder, pFN, pBN, fenceHeight, railCol, picketCol)
		buildProceduralPicketFence(fenceWallsFolder, pBN, pBS, fenceHeight, railCol, picketCol)
		buildProceduralPicketFence(fenceWallsFolder, pBS, pFS, fenceHeight, railCol, picketCol)
		buildProceduralPicketFence(fenceWallsFolder, pFN, pGateNorth, fenceHeight, railCol, picketCol)
		buildProceduralPicketFence(fenceWallsFolder, pGateSouth, pFS, fenceHeight, railCol, picketCol)

		if isIronTier then
			for _, d in ipairs(fenceWallsFolder:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Material = Enum.Material.Metal
				end
			end
		end
	end

	-- Keep the Front Entrance Archway aligned with the front gate, and keep `GrowSquishyStand` & `UpgradeFenceStand` 8.5 studs OUTSIDE the fence with 12-stud Z spacing!
	local frontX = penCenter.X + faceDir * (penW * 0.5)
	local apronX = frontX + faceDir * 8.5
	local post1 = hatcheryPen:FindFirstChild("HatcheryGatePost_1") :: BasePart?
	local post2 = hatcheryPen:FindFirstChild("HatcheryGatePost_2") :: BasePart?
	local gateArch = hatcheryPen:FindFirstChild("HatcheryGateArch") :: BasePart?
	if post1 then
		post1.Position = Vector3.new(frontX, penCenter.Y + 4.4, penCenter.Z - 4.2)
	end
	if post2 then
		post2.Position = Vector3.new(frontX, penCenter.Y + 4.4, penCenter.Z + 4.2)
	end
	if gateArch then
		gateArch.Position = Vector3.new(frontX, penCenter.Y + 9.4, penCenter.Z)
	end

	local growStand = hatcheryPen:FindFirstChild("GrowSquishyStand") :: BasePart?
	if growStand then
		local gPos = Vector3.new(apronX, penCenter.Y + 0.15, baseCenter.Z + 7.5)
		local delta = gPos - growStand.Position
		growStand.Position = gPos
		for _, child in ipairs(growStand:GetChildren()) do
			if child:IsA("BasePart") then
				child.Position += delta
			end
		end
	end

	local fenceStand = hatcheryPen:FindFirstChild("UpgradeFenceStand") :: BasePart?
	if fenceStand then
		local fPos = Vector3.new(apronX, penCenter.Y + 0.15, baseCenter.Z + 19.5)
		local delta = fPos - fenceStand.Position
		fenceStand.Position = fPos
		for _, child in ipairs(fenceStand:GetChildren()) do
			if child:IsA("BasePart") then
				child.Position += delta
			end
		end
	end

	local incubatorsFolder = plotModel:FindFirstChild("Incubators")
	if incubatorsFolder then
		for incIdx = 1, 5 do
			local incPad = incubatorsFolder:FindFirstChild("Incubator_" .. tostring(incIdx)) :: BasePart?
			if incPad then
				local zOff = -6.4 + (incIdx - 1) * 3.2
				local incPos = penCenter + Vector3.new(faceDir * (penW * 0.5 - 3.2), 0.1, zOff)
				local delta = incPos - incPad.Position
				incPad.Position = incPos
				for _, child in ipairs(incPad:GetChildren()) do
					if child:IsA("BasePart") then
						child.Position += delta
					end
				end
			end
		end
	end

	-- Reposition all 35 Roaming Brainrot Pasture Slots (`Pedestal_1..35`) across the expanded `penW x penD` enclosure!
	local pedestalsFolder = plotModel:FindFirstChild("Pedestals")
	if pedestalsFolder then
		local usableW = math.max(14.0, penW - 9.0)
		local usableD = math.max(12.0, penD - 5.0)
		for slotIdx = 1, 35 do
			local ped = pedestalsFolder:FindFirstChild("Pedestal_" .. tostring(slotIdx)) :: BasePart?
			if ped then
				local row = math.floor((slotIdx - 1) / 5) -- 0..6 (7 rows)
				local col = (slotIdx - 1) % 5 -- 0..4 (5 cols)
				local xAlpha = (row / 6) - 0.5
				local zAlpha = (col / 4) - 0.5
				local newPedPos = penCenter + Vector3.new(-faceDir * (xAlpha * usableW), 0.06, zAlpha * usableD)
				local delta = newPedPos - ped.Position
				ped.Position = newPedPos
				ped.Transparency = 1
				ped.CanCollide = false
				ped.CanQuery = false
				for _, child in ipairs(ped:GetChildren()) do
					if child:IsA("BasePart") then
						child.Position += delta
						child.Transparency = 1
						child.CanCollide = false
						child.CanQuery = false
					end
				end
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

	-- 1. Front Hazard Moat + Procedural Plank Bridges at zStart - 24 (split cleanly outside the 36-stud Central Highway Road!)
	local moatZ = zStart - 24
	local moatColor = if id == 1 then Color3.fromRGB(55, 135, 185)
		elseif id == 2 then Color3.fromRGB(165, 78, 122)
		elseif id == 3 then Color3.fromRGB(48, 155, 185)
		elseif id == 4 then Color3.fromRGB(58, 155, 98)
		elseif id == 5 then Color3.fromRGB(115, 64, 168)
		elseif id == 6 then Color3.fromRGB(115, 168, 205)
		elseif id == 7 then Color3.fromRGB(185, 68, 28)
		else Color3.fromRGB(135, 52, 175)

	for _, side in ipairs({ -1, 1 }) do
		local moat = makePart({
			Name = string.format("HazardMoat_%d_%s", id, if side < 0 then "West" else "East"),
			Size = Vector3.new(76, 0.9, 16),
			Position = Vector3.new(side * 60, 0.2, moatZ),
			Color = moatColor,
			Material = Enum.Material.Slate,
			Parent = obstaclesFolder,
		})
		moat:SetAttribute("HazardDropEgg", true)
		moat:SetAttribute("KnockbackImpulse", 55)
	end

	for _, bridgeX in ipairs({ -48, 48 }) do
		buildProceduralPlankBridge(
			parent,
			Vector3.new(bridgeX, 0.2, moatZ),
			14,
			20,
			Color3.fromRGB(158, 108, 62),
			Color3.fromRGB(105, 68, 36)
		)
	end

	-- Build Sector 1 (Checklist Board + Treadmill Plaza Pad + Shortcut Button) & Sector 2 Unique Landmarks/Obbies!
	buildBiomeLandmarksAndInteractiveProps(parent, levelInfo, obstaclesFolder)

	-- 2. Dedicated Left-Side Elevated Biome Sky Obby Gauntlet holding the Biome Obby Shining Squishies (#103-#117)!
	local obbyTruss = Instance.new("TrussPart")
	obbyTruss.Name = "ObbyStartTruss_" .. tostring(id)
	obbyTruss.Anchored = true
	obbyTruss.Size = Vector3.new(4.0, 12, 4.0)
	obbyTruss.Position = Vector3.new(-83, 6.0, zStart - 35)
	obbyTruss.Color = Color3.fromRGB(78, 118, 168)
	obbyTruss.Material = Enum.Material.Metal
	obbyTruss.Parent = parent

	-- Paywall: 💎 Skip Stage Obby to Summit Pad
	local summitPos = Vector3.new(-94 + 3 * 11, 9.0 + 3 * 2.8 + 2.5, zStart - 26 - 3 * 22)
	local obbyPayPad = buildGlowingNeonCircle(
		parent,
		"SkipObbyPaywallPad_Stage_" .. tostring(id),
		Vector3.new(-83, 0.25, zStart - 35),
		8.0,
		Color3.fromRGB(255, 215, 65),
		Color3.fromRGB(185, 75, 255)
	)
	local obbyPayPrompt = createAttachmentPrompt(
		obbyPayPad,
		"SkipObbyPaywallPrompt",
		string.format("💎 Skip Obby to Summit (VIP / Robux)"),
		string.format("⚡ Instant Teleport to Stage %d Obby Summit!", id),
		Vector3.new(0, 3.2, 0),
		16
	)
	if obbyPayPrompt then
		obbyPayPrompt:SetAttribute("StageId", id)
		obbyPayPrompt:SetAttribute("SummitPos", summitPos)
	end

	-- Guaranteed Reachability: Super Bounce Pad right beside the start truss
	local startBounce = makePart({
		Name = "ObbyStartBouncePad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, 10.0, 10.0),
		CFrame = CFrame.new(-91, 0.5, zStart - 35) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(85, 235, 115),
		Material = Enum.Material.Neon,
		Parent = parent,
	})
	startBounce:SetAttribute("SuperBouncePad", true)
	startBounce:SetAttribute("BounceVelocityY", 75)

	-- Wide 6-Step Entry Staircase ascending directly onto the Sky Obby!
	for e = 1, 6 do
		local alpha = (e - 1) / 5
		makePart({
			Name = string.format("ObbyEntryStep_%d", e),
			Size = Vector3.new(9.5, 1.5, 3.2),
			Position = Vector3.new(-83, 1.5 + alpha * 8.0, (zStart - 23) - alpha * 15.0),
			Color = secColor:Lerp(Color3.fromRGB(240, 240, 245), 0.35),
			Material = Enum.Material.Concrete,
			Parent = parent,
		})
	end

	for subIdx = 1, 3 do
		local xPos = -94 + subIdx * 11
		local yPos = 9.0 + subIdx * 2.8
		local zPos = zStart - 26 - subIdx * 22

		if subIdx > 1 then
			local prevX = -94 + (subIdx - 1) * 11
			local prevY = 9.0 + (subIdx - 1) * 2.8
			local prevZ = zStart - 26 - (subIdx - 1) * 22
			local midPos = Vector3.new((prevX + xPos) * 0.5, (prevY + yPos) * 0.5 - 0.4, (prevZ + zPos) * 0.5)
			makePart({
				Name = string.format("SkyObbyWhiteBeam_%d", subIdx),
				Size = Vector3.new(6.5, 1.4, 15.0),
				CFrame = CFrame.lookAt(midPos, Vector3.new(xPos, yPos - 0.3, zPos)),
				Color = Color3.fromRGB(198, 204, 214),
				Material = Enum.Material.Concrete,
				Parent = parent,
			})
		end

		for step = 1, 3 do
			makePart({
				Name = string.format("ThemedObbyStep_%d_%d", subIdx, step),
				Size = Vector3.new(10.0, 1.6, 5.2),
				Position = Vector3.new(xPos + (step - 2) * 3.8, (yPos * step) / 3.4, zPos + (4 - step) * 4.0),
				Color = if step % 2 == 1 then Color3.fromRGB(72, 118, 185) else Color3.fromRGB(215, 220, 228),
				Material = Enum.Material.Concrete,
				Parent = parent,
			})
		end

		buildGlowingNeonCircle(
			parent,
			"ObbyGoalPlatform_" .. tostring(subIdx),
			Vector3.new(xPos, yPos - 0.3, zPos),
			15.0,
			secColor,
			Color3.fromRGB(215, 195, 85)
		)
	end

	-- 3. 4 Walk-Inside Biome Village Houses per Stage (32 Biome Houses total across Stages 1-8 at X = ±114, Z = zStart - 56 and Z = zStart - 94)!
	local biomeHouseConfigs: { [number]: { { Side: number, Wall: Color3, Roof: Color3, Z: number } } } = {
		[1] = {
			{ Side = -1, Wall = Color3.fromRGB(195, 78, 68), Roof = Color3.fromRGB(125, 42, 38), Z = -56 },
			{ Side = 1, Wall = Color3.fromRGB(215, 188, 108), Roof = Color3.fromRGB(62, 138, 74), Z = -56 },
			{ Side = -1, Wall = Color3.fromRGB(125, 182, 215), Roof = Color3.fromRGB(48, 88, 175), Z = -94 },
			{ Side = 1, Wall = Color3.fromRGB(212, 148, 182), Roof = Color3.fromRGB(154, 52, 115), Z = -94 },
		},
		[2] = {
			{ Side = -1, Wall = Color3.fromRGB(215, 152, 185), Roof = Color3.fromRGB(175, 52, 118), Z = -216 },
			{ Side = 1, Wall = Color3.fromRGB(142, 192, 218), Roof = Color3.fromRGB(58, 98, 188), Z = -216 },
			{ Side = -1, Wall = Color3.fromRGB(218, 192, 122), Roof = Color3.fromRGB(185, 98, 42), Z = -254 },
			{ Side = 1, Wall = Color3.fromRGB(178, 145, 215), Roof = Color3.fromRGB(108, 52, 175), Z = -254 },
		},
		[3] = {
			{ Side = -1, Wall = Color3.fromRGB(218, 168, 118), Roof = Color3.fromRGB(185, 84, 52), Z = -376 },
			{ Side = 1, Wall = Color3.fromRGB(118, 202, 188), Roof = Color3.fromRGB(35, 128, 138), Z = -376 },
			{ Side = -1, Wall = Color3.fromRGB(218, 198, 122), Roof = Color3.fromRGB(45, 138, 185), Z = -414 },
			{ Side = 1, Wall = Color3.fromRGB(215, 138, 154), Roof = Color3.fromRGB(175, 52, 76), Z = -414 },
		},
		[4] = {
			{ Side = -1, Wall = Color3.fromRGB(154, 198, 145), Roof = Color3.fromRGB(46, 134, 68), Z = -536 },
			{ Side = 1, Wall = Color3.fromRGB(208, 194, 158), Roof = Color3.fromRGB(175, 54, 48), Z = -536 },
			{ Side = -1, Wall = Color3.fromRGB(134, 194, 165), Roof = Color3.fromRGB(38, 118, 78), Z = -574 },
			{ Side = 1, Wall = Color3.fromRGB(178, 202, 134), Roof = Color3.fromRGB(58, 142, 62), Z = -574 },
		},
		[5] = {
			{ Side = -1, Wall = Color3.fromRGB(158, 128, 205), Roof = Color3.fromRGB(88, 46, 165), Z = -696 },
			{ Side = 1, Wall = Color3.fromRGB(112, 184, 212), Roof = Color3.fromRGB(42, 96, 175), Z = -696 },
			{ Side = -1, Wall = Color3.fromRGB(132, 115, 195), Roof = Color3.fromRGB(64, 38, 138), Z = -734 },
			{ Side = 1, Wall = Color3.fromRGB(184, 122, 208), Roof = Color3.fromRGB(118, 42, 158), Z = -734 },
		},
		[6] = {
			{ Side = -1, Wall = Color3.fromRGB(218, 224, 232), Roof = Color3.fromRGB(208, 178, 68), Z = -856 },
			{ Side = 1, Wall = Color3.fromRGB(198, 214, 228), Roof = Color3.fromRGB(82, 158, 208), Z = -856 },
			{ Side = -1, Wall = Color3.fromRGB(224, 212, 198), Roof = Color3.fromRGB(205, 122, 162), Z = -894 },
			{ Side = 1, Wall = Color3.fromRGB(208, 218, 228), Roof = Color3.fromRGB(138, 112, 208), Z = -894 },
		},
		[7] = {
			{ Side = -1, Wall = Color3.fromRGB(102, 72, 82), Roof = Color3.fromRGB(178, 58, 28), Z = -1016 },
			{ Side = 1, Wall = Color3.fromRGB(88, 68, 84), Roof = Color3.fromRGB(192, 68, 32), Z = -1016 },
			{ Side = -1, Wall = Color3.fromRGB(76, 62, 76), Roof = Color3.fromRGB(205, 96, 28), Z = -1054 },
			{ Side = 1, Wall = Color3.fromRGB(96, 62, 66), Roof = Color3.fromRGB(165, 38, 30), Z = -1054 },
		},
		[8] = {
			{ Side = -1, Wall = Color3.fromRGB(48, 32, 78), Roof = Color3.fromRGB(154, 48, 202), Z = -1176 },
			{ Side = 1, Wall = Color3.fromRGB(36, 40, 82), Roof = Color3.fromRGB(58, 178, 205), Z = -1176 },
			{ Side = -1, Wall = Color3.fromRGB(58, 28, 84), Roof = Color3.fromRGB(202, 56, 158), Z = -1214 },
			{ Side = 1, Wall = Color3.fromRGB(42, 32, 74), Roof = Color3.fromRGB(112, 72, 202), Z = -1214 },
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
		Color = Color3.fromRGB(205, 58, 78),
		Material = Enum.Material.Metal,
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
			Color3.fromRGB(218, 195, 55),
			Color3.fromRGB(205, 98, 45)
		)
		bPad:SetAttribute("BounceImpulse", 98)
	end

	-- 5. Sector 3: Grounded Matte Stone Boss Nest Arena Circle (146-stud diameter) under the 2 Giant Sleeping Bosses & Egg Cluster
	buildGlowingNeonCircle(
		parent,
		"BossNestArenaPad",
		Vector3.new(0, 0.12, zBoss),
		146,
		secColor,
		secColor:Lerp(Color3.fromRGB(215, 218, 224), 0.35)
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
	local gateCost = levelInfo.GateUnlockCost or levelInfo.RequiredCoins or 0
	local reqText = if id <= 1
		then string.format("STAGE %d: %s (OPEN!)", id, string.upper(levelInfo.Name))
		else string.format(
			"STAGE %d: %s\n[100%% STAGE %d • 🧱 FENCE LV.%d • ⚡ %s SPD • 💰 $%s]",
			id,
			string.upper(levelInfo.Name),
			id - 1,
			id,
			SlimeData.FormatNumber(reqSpeed),
			SlimeData.FormatNumber(gateCost)
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
	barrier:SetAttribute("RequiredCoins", gateCost)
	barrier:SetAttribute("RequiredSpeed", reqSpeed)
	barrier:SetAttribute("RequiredFenceLevel", id)

	if id > 1 then
		createAttachmentPrompt(
			barrier,
			"UnlockStageGatePrompt",
			string.format("🔓 Unlock Stage %d Gate ($%s)", id, SlimeData.FormatNumber(gateCost)),
			string.format("Req: 100%% Stage %d + Fence Lv.%d + %s Spd", id - 1, id, SlimeData.FormatNumber(reqSpeed)),
			Vector3.new(0, 4.5 - barrierHeight * 0.5, 0),
			18
		)

		-- Paywall: Instant Gate Unlock ProximityPrompt (VIP / Skip Grind)
		local attPay = (barrier:FindFirstChild("UnlockStageGatePrompt_Attachment") or barrier:FindFirstChild("UnlockStageGatePromptAttachment")) :: Attachment?
		local skipGatePrompt = Instance.new("ProximityPrompt")
		skipGatePrompt.Name = "SkipStageGatePaywallPrompt"
		skipGatePrompt.ActionText = string.format("💎 Instant Stage %d Gate Unlock (VIP / Robux)", id)
		skipGatePrompt.ObjectText = "💎 Skip Grind & Open Immediately!"
		skipGatePrompt.KeyboardKeyCode = Enum.KeyCode.F
		skipGatePrompt.HoldDuration = 0
		skipGatePrompt.MaxActivationDistance = 22
		skipGatePrompt.UIOffset = Vector2.new(0, -65)
		skipGatePrompt.RequiresLineOfSight = false
		skipGatePrompt:SetAttribute("LevelId", id)
		skipGatePrompt.Parent = if attPay then attPay else barrier
	end

	return barrier
end

function WorldBuilder.BuildWorld(): {
	WorldFolder: Folder,
	GateBarriers: { [number]: Part },
	WorldEggs: { [string]: Model },
	WorldCoins: { [string]: Model },
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
	local worldCoins: { [string]: Model } = {}
	local guardians: { [string]: { Model: Model, Data: any, LevelInfo: any } } = {}

	local obstaclesFolder = Instance.new("Folder")
	obstaclesFolder.Name = "DynamicObstacles"
	obstaclesFolder.Parent = worldFolder

	-- Foundation: Clean procedural world with empty ImportedBaseMap folder
	local baseMapFolder = Instance.new("Folder")
	baseMapFolder.Name = "ImportedBaseMap"
	baseMapFolder.Parent = worldFolder

	-- Phase 2.2: Build the continuous 36-stud Dark Charcoal Matte Asphalt Highway Road down the center of the map (Z = +180 to -1280)
	buildCentralHighwayRoad(worldFolder)
	buildSafeZoneAndPlots(worldFolder, obstaclesFolder)


	local levelsFolder = Instance.new("Folder")
	levelsFolder.Name = "Levels"
	levelsFolder.Parent = worldFolder

	local eggsFolder = Instance.new("Folder")
	eggsFolder.Name = "WorldEggs"
	eggsFolder.Parent = worldFolder

	local coinsFolder = Instance.new("Folder")
	coinsFolder.Name = "WorldCoins"
	coinsFolder.Parent = worldFolder

	local guardiansFolder = Instance.new("Folder")
	guardiansFolder.Name = "Guardians"
	guardiansFolder.Parent = worldFolder

	local naturalStageFloors: { [number]: { Color: Color3, Material: Enum.Material } } = {
		[1] = { Color = Color3.fromRGB(76, 138, 68), Material = Enum.Material.LeafyGrass },
		[2] = { Color = Color3.fromRGB(148, 108, 86), Material = Enum.Material.Cobblestone },
		[3] = { Color = Color3.fromRGB(198, 178, 128), Material = Enum.Material.Sand },
		[4] = { Color = Color3.fromRGB(68, 128, 74), Material = Enum.Material.LeafyGrass },
		[5] = { Color = Color3.fromRGB(64, 62, 82), Material = Enum.Material.Slate },
		[6] = { Color = Color3.fromRGB(204, 212, 224), Material = Enum.Material.Limestone },
		[7] = { Color = Color3.fromRGB(54, 48, 52), Material = Enum.Material.Basalt },
		[8] = { Color = Color3.fromRGB(38, 34, 52), Material = Enum.Material.Basalt },
	}

	for _, levelInfo in ipairs(SlimeData.Levels) do
		local lvlId = levelInfo.Id or levelInfo.Level
		local lvlFolder = Instance.new("Folder")
		lvlFolder.Name = "Level_" .. tostring(lvlId) .. "_" .. levelInfo.Name
		lvlFolder.Parent = levelsFolder

		local zLength = math.abs(levelInfo.ZStart - levelInfo.ZEnd)
		local zMid = (levelInfo.ZStart + levelInfo.ZEnd) * 0.5
		local floorStyle = naturalStageFloors[lvlId] or {
			Color = levelInfo.FloorColor,
			Material = levelInfo.FloorMaterial or Enum.Material.LeafyGrass,
		}

		makePart({
			Name = "Floor_" .. levelInfo.Name,
			Size = Vector3.new(MAP_WIDTH, 2, zLength),
			Position = Vector3.new(0, -1, zMid),
			Color = floorStyle.Color,
			Material = floorStyle.Material,
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

	-- Enforce Zero Map Glow Rule across all environment geometry before spawning glowing Eggs, Squishies, and Coins!
	for _, desc in ipairs(worldFolder:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Material == Enum.Material.Neon then
			desc.Material = Enum.Material.SmoothPlastic
		end
	end

	-- Phase 4.1: Spawn 120 Glowing 3D Gold Coins (15 per Stage across all 8 Stages: 6 on Central Road, 5 at Landmarks, 4 on Obby Courses)!
	local coinIdCounter = 0
	for stageIdx = 1, 8 do
		local zStart = -(stageIdx - 1) * 160
		local coinValue = math.floor(15 * (2.4 ^ (stageIdx - 1)))
		local stageCoinSpots = {
			-- 6 Coins along the Central Asphalt Road
			Vector3.new(-8, 2.8, zStart - 22),
			Vector3.new(8, 2.8, zStart - 46),
			Vector3.new(-8, 2.8, zStart - 70),
			Vector3.new(8, 2.8, zStart - 94),
			Vector3.new(-8, 2.8, zStart - 118),
			Vector3.new(8, 2.8, zStart - 142),
			-- 5 Coins inside/around Stage Landmarks & Village Houses
			Vector3.new(-62, 3.2, zStart - 54),
			Vector3.new(62, 3.2, zStart - 58),
			Vector3.new(-92, 3.2, zStart - 88),
			Vector3.new(92, 3.2, zStart - 88),
			Vector3.new(0, 3.2, zStart - 116),
			-- 4 Coins elevated along the Stage Obby Course
			Vector3.new(-52, 9.5, zStart - 48),
			Vector3.new(52, 12.5, zStart - 52),
			Vector3.new(-74, 18.5, zStart - 64),
			Vector3.new(74, 22.5, zStart - 68),
		}
		for cIdx, cPos in ipairs(stageCoinSpots) do
			coinIdCounter += 1
			local cIdStr = tostring(coinIdCounter)
			local coinModel = Instance.new("Model")
			coinModel.Name = "WorldCoin_" .. cIdStr
			coinModel:SetAttribute("CoinId", cIdStr)
			coinModel:SetAttribute("StageId", stageIdx)
			coinModel:SetAttribute("CoinValue", coinValue)
			coinModel.Parent = coinsFolder

			local disc = Instance.new("Part")
			disc.Name = "CoinCore"
			disc.Shape = Enum.PartType.Cylinder
			disc.Size = Vector3.new(0.85, 3.4, 3.4)
			disc.CFrame = CFrame.new(cPos) * CFrame.Angles(0, math.rad(cIdx * 24), 0)
			disc.Color = Color3.fromRGB(255, 215, 35)
			disc.Material = Enum.Material.Neon
			disc.Anchored = true
			disc.CanCollide = false
			disc.CanTouch = true
			disc:SetAttribute("WorldCoinPickup", true)
			disc:SetAttribute("CoinId", cIdStr)
			disc:SetAttribute("StageId", stageIdx)
			disc:SetAttribute("CoinValue", coinValue)
			disc:SetAttribute("CoinSpinRotor", true)
			disc:SetAttribute("SpinSpeed", 2.4)
			disc.Parent = coinModel
			coinModel.PrimaryPart = disc

			local rim = Instance.new("Part")
			rim.Name = "CoinRim"
			rim.Shape = Enum.PartType.Cylinder
			rim.Size = Vector3.new(0.65, 3.9, 3.9)
			rim.CFrame = disc.CFrame
			rim.Color = Color3.fromRGB(245, 175, 20)
			rim.Material = Enum.Material.Metal
			rim.Anchored = true
			rim.CanCollide = false
			rim.Parent = coinModel

			local hl = Instance.new("Highlight")
			hl.Name = "CoinPopHighlight"
			hl.FillColor = Color3.fromRGB(255, 225, 55)
			hl.OutlineColor = Color3.fromRGB(255, 255, 215)
			hl.FillTransparency = 0.55
			hl.OutlineTransparency = 0.05
			hl.DepthMode = Enum.HighlightDepthMode.Occluded
			hl.Parent = coinModel

			local ptLight = Instance.new("PointLight")
			ptLight.Name = "CoinPopLight"
			ptLight.Color = Color3.fromRGB(255, 220, 65)
			ptLight.Brightness = 1.65
			ptLight.Range = 11
			ptLight.Parent = disc

			createBillboardText(
				disc,
				string.format("🪙 +$%s", SlimeData.FormatNumber(coinValue)),
				Color3.fromRGB(255, 235, 75),
				Vector3.new(0, 2.6, 0),
				UDim2.new(4.2, 0, 1.1, 0),
				18
			)

			worldCoins[cIdStr] = coinModel
		end
	end

	-- Spawn all 117 Items (35 Boss Nest Brainrot Eggs + 82 Shining Collectible Squishies across Landmarks, Rainbow Stairs, Mazes, Castle Walls & Obbies)!
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
		WorldCoins = worldCoins,
		Guardians = guardians,
	}
end

return WorldBuilder
