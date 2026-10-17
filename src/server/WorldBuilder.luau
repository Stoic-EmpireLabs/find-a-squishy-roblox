--!strict
--[[
	WorldBuilder.luau
	Pure "Steal My Egg!" 3D World Builder (Compact Map, Oversized Objects, 60 FPS):
	  - Compact Map Width (136 studs) & 95-Stud Biome Arenas (Z = 0 to -475)
	  - Checkered Vibrant Green Safe Zone (Z = 0 to 105) framed by Big 26-32 Stud 3D Houses
	  - 4 Fenced Player Base Plots with:
	      * Giant 18-Stud 3D Green Dino-Jaw Speed Treadmill + Glowing Pink Belt
	      * 5 Purple Glowing Hatch Incubator Rings
	      * 12 Lawn Pedestals for Hatched Squishies + Cash Collector Chest + 26-Stud Base House
	  - Each Biome Arena has:
	      * Front Obby Gauntlet (Hazard Moat, 3D Bridges, Obby Kit Obstacles, Spinning Sweeper Bar, Super Bounce Pads)
	      * Back Boss Nest surrounded by Giant 18-28 Stud 3D Lollipops / Trees / Palm Trees / Crystals / Volcano Rocks
	      * 2 Giant 21-Stud Sleeping Bosses guarding a dense Cluster of 5-9 Oversized Ornate Eggs (6.8-8.5 studs tall)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SlimeData = require(Shared:WaitForChild("SlimeData"))
local SquishyBuilder = require(Shared:WaitForChild("SquishyBuilder"))
local PrebuiltLoader = require(Shared:WaitForChild("PrebuiltLoader"))

local WorldBuilder = {}

local MAP_WIDTH = 136
local WALL_HEIGHT = 24
local WALL_THICKNESS = 6

local function makePart(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = if props.Anchored ~= nil then props.Anchored else true
	p.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.Color = props.Color or Color3.fromRGB(200, 200, 200)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Transparency = props.Transparency or 0
	p.CastShadow = if props.CastShadow ~= nil then props.CastShadow else false
	if props.Shape then
		p.Shape = props.Shape
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

local function createBillboardText(parent: Instance, text: string, color: Color3, offset: Vector3, size: UDim2?): BillboardGui
	local bb = Instance.new("BillboardGui")
	bb.Size = size or UDim2.fromOffset(220, 56)
	bb.StudsOffset = offset
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
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
	stroke.Thickness = 2.5
	stroke.Parent = lbl

	return bb
end

local function setupVibrantLighting()
	Lighting.Ambient = Color3.fromRGB(155, 165, 185)
	Lighting.OutdoorAmbient = Color3.fromRGB(175, 185, 205)
	Lighting.Brightness = 2.4
	Lighting.ColorShift_Top = Color3.fromRGB(255, 250, 235)
	Lighting.ClockTime = 13.5
	Lighting.GeographicLatitude = 32
	Lighting.GlobalShadows = true

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
	atmo.Density = 0.20
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(190, 230, 255)
	atmo.Decay = Color3.fromRGB(150, 205, 250)
	atmo.Glare = 0.08
	atmo.Haze = 0.6
	atmo.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.03
	cc.Contrast = 0.14
	cc.Saturation = 0.25
	cc.Parent = Lighting
end

local function placePrebuiltAsset(category: string, index: number, parent: Instance, pos: Vector3, yawDeg: number, targetHeight: number, canCollide: boolean?): Model?
	local model = PrebuiltLoader.CloneNormalizedTemplate(category, index, targetHeight)
	if not model then
		return nil
	end
	if canCollide ~= nil and model.PrimaryPart then
		model.PrimaryPart.CanCollide = canCollide
	end
	model:PivotTo(CFrame.new(pos.X, pos.Y + (targetHeight * 0.5), pos.Z) * CFrame.Angles(0, math.rad(yawDeg), 0))
	model.Parent = parent
	return model
end

-- Builds a Big 26-30 Stud Cartoon House (uses Prebuilt "Houses" template if available, plus a vibrant 3D roof/door silhouette)
local function buildBigCartoonHouse(parent: Instance, pos: Vector3, yawDeg: number, wallColor: Color3, roofColor: Color3, houseIdx: number, targetHeight: number)
	local placed = placePrebuiltAsset("Houses", houseIdx, parent, pos, yawDeg, targetHeight, true)
	if placed then
		return placed
	end

	local hModel = Instance.new("Model")
	hModel.Name = "CartoonHouse_" .. tostring(houseIdx)
	local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(yawDeg), 0)

	local bodyH = targetHeight * 0.62
	local roofH = targetHeight * 0.38
	local w = targetHeight * 0.78
	local d = targetHeight * 0.68

	local body = makePart({
		Name = "HouseBody",
		Size = Vector3.new(w, bodyH, d),
		CFrame = cf * CFrame.new(0, bodyH * 0.5, 0),
		Color = wallColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = hModel,
	})
	hModel.PrimaryPart = body

	-- Pitched roof
	makePart({
		Name = "HouseRoof",
		Size = Vector3.new(w + 3.5, roofH, d + 3.5),
		CFrame = cf * CFrame.new(0, bodyH + roofH * 0.45, 0),
		Color = roofColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = hModel,
	})
	-- Chimney
	makePart({
		Name = "Chimney",
		Size = Vector3.new(3.2, roofH + 4, 3.2),
		CFrame = cf * CFrame.new(w * 0.28, bodyH + roofH * 0.65, -d * 0.18),
		Color = Color3.fromRGB(185, 85, 65),
		Material = Enum.Material.Brick,
		Parent = hModel,
	})
	-- Door & Glowing Windows
	makePart({
		Name = "FrontDoor",
		Size = Vector3.new(4.8, 8.2, 0.8),
		CFrame = cf * CFrame.new(0, 4.1, d * 0.5 + 0.2),
		Color = Color3.fromRGB(125, 72, 36),
		Material = Enum.Material.Wood,
		Parent = hModel,
	})
	for _, wx in ipairs({ -w * 0.26, w * 0.26 }) do
		makePart({
			Name = "Window",
			Size = Vector3.new(4.2, 4.2, 0.8),
			CFrame = cf * CFrame.new(wx, bodyH * 0.58, d * 0.5 + 0.2),
			Color = Color3.fromRGB(255, 240, 145),
			Material = Enum.Material.Neon,
			Parent = hModel,
		})
	end

	hModel.Parent = parent
	return hModel
end

-- Builds the Iconic Giant 18-Stud Green Dino-Jaw Speed Treadmill from the reference screenshot!
local function buildDinoJawTreadmill(parent: Instance, treadCenter: Vector3, faceDir: number, plotIdx: number): Part
	local dinoFolder = Instance.new("Model")
	dinoFolder.Name = "DinoTreadmill_" .. tostring(plotIdx)
	dinoFolder.Parent = parent

	-- 1. Treadmill Frame Base + Glowing Hot-Pink Belt + White Chevrons
	makePart({
		Name = "TreadmillBase",
		Size = Vector3.new(12.5, 1.2, 16.5),
		Position = treadCenter + Vector3.new(0, 0.6, 0),
		Color = Color3.fromRGB(40, 44, 58),
		Material = Enum.Material.Metal,
		Parent = dinoFolder,
	})

	for _, railZ in ipairs({ -7.4, 7.4 }) do
		makePart({
			Name = "SideRail",
			Size = Vector3.new(12.5, 1.9, 1.4),
			Position = treadCenter + Vector3.new(0, 1.25, railZ),
			Color = Color3.fromRGB(55, 210, 85),
			Material = Enum.Material.SmoothPlastic,
			Parent = dinoFolder,
		})
	end

	local belt = makePart({
		Name = "TreadmillBelt_" .. tostring(plotIdx),
		Size = Vector3.new(11.4, 1.35, 13.0),
		Position = treadCenter + Vector3.new(0, 0.82, 0),
		Color = Color3.fromRGB(255, 65, 150),
		Material = Enum.Material.Neon,
		Parent = parent,
	})
	belt:SetAttribute("PlotIndex", plotIdx)

	for s = -4, 4, 2 do
		makePart({
			Name = "BeltArrow",
			Size = Vector3.new(0.85, 1.42, 10.6),
			Position = treadCenter + Vector3.new(s * 1.1, 0.86, 0),
			Color = Color3.fromRGB(255, 245, 255),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = dinoFolder,
		})
	end

	-- 2. Giant 18-Stud Green T-Rex Arching Over the Back of the Treadmill!
	local archCenter = treadCenter + Vector3.new(-faceDir * 4.5, 0, 0)
	local yawDeg = if faceDir > 0 then 90 else -90

	-- Also place Prebuilt Dinosaur mesh if loaded
	placePrebuiltAsset("TreadmillDino", 1, dinoFolder, archCenter + Vector3.new(-faceDir * 2.2, 0, 0), yawDeg, 17.5, false)

	-- Guaranteed 3D Voxel Green Dino Head & Open Jaw Arching Over the Belt (exact match to real_game_annotated_1_base_loop.png)
	local dinoGreen = Color3.fromRGB(58, 198, 68)
	local dinoDark = Color3.fromRGB(38, 148, 48)
	local mouthRed = Color3.fromRGB(195, 55, 65)

	-- Left & Right Jaw Pillars framing the belt
	for _, sideZ in ipairs({ -6.4, 6.4 }) do
		makePart({
			Name = "DinoSidePillar",
			Size = Vector3.new(5.5, 12.5, 2.4),
			Position = treadCenter + Vector3.new(-faceDir * 2.8, 6.25, sideZ),
			Color = dinoGreen,
			Material = Enum.Material.SmoothPlastic,
			Parent = dinoFolder,
		})
	end

	-- Upper Snout / Roof of Open Mouth
	local snout = makePart({
		Name = "DinoUpperSnout",
		Size = Vector3.new(9.5, 4.8, 15.2),
		Position = treadCenter + Vector3.new(-faceDir * 1.6, 13.8, 0),
		Color = dinoGreen,
		Material = Enum.Material.SmoothPlastic,
		Parent = dinoFolder,
	})
	makePart({
		Name = "DinoCrest",
		Size = Vector3.new(6.8, 2.6, 12.0),
		Position = treadCenter + Vector3.new(-faceDir * 2.5, 16.8, 0),
		Color = dinoDark,
		Material = Enum.Material.SmoothPlastic,
		Parent = dinoFolder,
	})
	makePart({
		Name = "DinoMouthRoof",
		Size = Vector3.new(8.5, 0.9, 13.2),
		Position = treadCenter + Vector3.new(-faceDir * 1.4, 11.2, 0),
		Color = mouthRed,
		Material = Enum.Material.SmoothPlastic,
		Parent = dinoFolder,
	})

	-- Giant White Blocky Dino Teeth Hanging Down Over the Treadmill Entrance!
	for zTooth = -5.2, 5.2, 2.6 do
		makePart({
			Name = "UpperTooth",
			Size = Vector3.new(1.5, 2.4, 1.6),
			Position = treadCenter + Vector3.new(faceDir * 2.2, 10.3, zTooth),
			Color = Color3.fromRGB(250, 250, 255),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = dinoFolder,
		})
	end

	-- Dino Eyes on Both Sides of the Head
	for _, sideZ in ipairs({ -7.7, 7.7 }) do
		makePart({
			Name = "DinoEyeWhite",
			Size = Vector3.new(2.6, 2.6, 0.5),
			Position = treadCenter + Vector3.new(-faceDir * 1.2, 14.4, sideZ),
			Color = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.SmoothPlastic,
			Parent = dinoFolder,
		})
		makePart({
			Name = "DinoPupil",
			Size = Vector3.new(1.3, 1.3, 0.65),
			Position = treadCenter + Vector3.new(-faceDir * 0.8, 14.4, sideZ * 1.01),
			Color = Color3.fromRGB(20, 20, 25),
			Material = Enum.Material.SmoothPlastic,
			Parent = dinoFolder,
		})
	end

	createBillboardText(
		snout,
		"🦖 +1 SPEED TREADMILL\nRun on Pink Belt = Permanent +Speed!",
		Color3.fromRGB(85, 255, 140),
		Vector3.new(0, 5.5, 0),
		UDim2.fromOffset(250, 62)
	)

	return belt
end

-- Builds 4 Fenced Player Base Plots in the Checkered Green Safe Zone (Z = 0..105)
local function buildSafeZoneAndPlots(worldFolder: Folder)
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "SafeZoneHub"
	hubFolder.Parent = worldFolder

	-- Base Green Ground
	makePart({
		Name = "HubGrassMain",
		Size = Vector3.new(MAP_WIDTH, 2, 112),
		Position = Vector3.new(0, -1, 52),
		Color = Color3.fromRGB(88, 198, 78),
		Material = Enum.Material.LeafyGrass,
		Parent = hubFolder,
	})

	-- Checkered Green Lawn Tiles (matches real_game_annotated_1_base_loop.png)
	for xTile = -56, 56, 16 do
		for zTile = 12, 92, 16 do
			if ((math.floor((xTile + 64) / 16) + math.floor(zTile / 16)) % 2) == 0 then
				makePart({
					Name = "CheckeredTile",
					Size = Vector3.new(16, 0.12, 16),
					Position = Vector3.new(xTile, 0.06, zTile),
					Color = Color3.fromRGB(72, 178, 64),
					Material = Enum.Material.SmoothPlastic,
					CanCollide = false,
					Parent = hubFolder,
				})
			end
		end
	end

	-- Central Stone Path leading straight to Biome 1 Gate (Z = 0)
	makePart({
		Name = "CentralPath",
		Size = Vector3.new(24, 0.25, 104),
		Position = Vector3.new(0, 0.12, 50),
		Color = Color3.fromRGB(228, 214, 185),
		Material = Enum.Material.Cobblestone,
		Parent = hubFolder,
	})

	-- SpawnLocation right in the middle of the Safe Zone facing Biome 1 (-Z)
	local existingSpawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if not existingSpawn then
		local spawnLoc = Instance.new("SpawnLocation")
		spawnLoc.Name = "SpawnLocation"
		spawnLoc.Anchored = true
		spawnLoc.Size = Vector3.new(12, 1, 12)
		spawnLoc.CFrame = CFrame.new(0, 0.5, 52)
		spawnLoc.Neutral = true
		spawnLoc.Transparency = 1
		spawnLoc.CanCollide = false
		spawnLoc.Parent = Workspace
	else
		existingSpawn.CFrame = CFrame.new(0, 0.5, 52)
		existingSpawn.Transparency = 1
		existingSpawn.CanCollide = false
	end

	-- Center Hub Fountain at (0, 0, 82)
	local fountainModel = placePrebuiltAsset("HubFountain", 1, hubFolder, Vector3.new(0, 0, 84), 0, 14.0, true)
	local fountainTop = makePart({
		Name = "FountainSignAnchor",
		Size = Vector3.new(2, 2, 2),
		Position = Vector3.new(0, 15, 84),
		Transparency = 1,
		CanCollide = false,
		Parent = fountainModel or hubFolder,
	})
	createBillboardText(
		fountainTop,
		"🥚 STEAL MY EGG!\nSteal Boss Eggs ➔ Hatch at Base ➔ Run on Dino Treadmill!",
		Color3.fromRGB(255, 235, 90),
		Vector3.new(0, 2.5, 0),
		UDim2.fromOffset(300, 68)
	)

	-- Frame the Safe Zone with Big 26-32 Stud Cartoon Houses & Trees
	local borderHouses = {
		{ Pos = Vector3.new(-54, 0, 98), Yaw = 0, Wall = Color3.fromRGB(255, 195, 95), Roof = Color3.fromRGB(215, 65, 65), Idx = 1, H = 28 },
		{ Pos = Vector3.new(54, 0, 98), Yaw = 0, Wall = Color3.fromRGB(130, 210, 255), Roof = Color3.fromRGB(65, 105, 220), Idx = 2, H = 28 },
		{ Pos = Vector3.new(-24, 0, 99), Yaw = 0, Wall = Color3.fromRGB(255, 155, 195), Roof = Color3.fromRGB(185, 60, 145), Idx = 3, H = 26 },
		{ Pos = Vector3.new(24, 0, 99), Yaw = 0, Wall = Color3.fromRGB(165, 240, 155), Roof = Color3.fromRGB(55, 165, 85), Idx = 4, H = 26 },
	}
	for _, bh in ipairs(borderHouses) do
		buildBigCartoonHouse(hubFolder, bh.Pos, bh.Yaw, bh.Wall, bh.Roof, bh.Idx, bh.H)
	end

	-- Back & Side Safe Zone Walls
	makePart({
		Name = "SafeZoneBackWall",
		Size = Vector3.new(MAP_WIDTH + 8, WALL_HEIGHT, WALL_THICKNESS),
		Position = Vector3.new(0, WALL_HEIGHT * 0.5, 108),
		Color = Color3.fromRGB(95, 185, 80),
		Material = Enum.Material.SmoothPlastic,
		Parent = hubFolder,
	})
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "SafeZoneSideWall",
			Size = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, 112),
			Position = Vector3.new(side * (MAP_WIDTH * 0.5 + WALL_THICKNESS * 0.5), WALL_HEIGHT * 0.5, 52),
			Color = Color3.fromRGB(95, 185, 80),
			Material = Enum.Material.SmoothPlastic,
			Parent = hubFolder,
		})
	end

	-- Build the 4 Fenced Player Base Plots (2 on Left, 2 on Right)
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "PlayerPlots"
	plotsFolder.Parent = worldFolder

	local plotConfigs = {
		{ Index = 1, Center = Vector3.new(-38, 0, 30), Color = Color3.fromRGB(80, 190, 255), FaceDir = 1 },
		{ Index = 2, Center = Vector3.new(38, 0, 30), Color = Color3.fromRGB(255, 130, 195), FaceDir = -1 },
		{ Index = 3, Center = Vector3.new(-38, 0, 72), Color = Color3.fromRGB(120, 235, 130), FaceDir = 1 },
		{ Index = 4, Center = Vector3.new(38, 0, 72), Color = Color3.fromRGB(255, 200, 85), FaceDir = -1 },
	}

	local plotW = 46
	local plotD = 34

	for _, cfg in ipairs(plotConfigs) do
		local plotModel = Instance.new("Model")
		plotModel.Name = "Plot_" .. tostring(cfg.Index)
		plotModel:SetAttribute("PlotIndex", cfg.Index)
		plotModel.Parent = plotsFolder

		-- Plot Lawn Base
		local basePad = makePart({
			Name = "BasePad",
			Size = Vector3.new(plotW, 0.5, plotD),
			Position = cfg.Center + Vector3.new(0, 0.25, 0),
			Color = Color3.fromRGB(98, 212, 85),
			Material = Enum.Material.SmoothPlastic,
			Parent = plotModel,
		})
		plotModel.PrimaryPart = basePad

		-- Wooden Ranch Fence around the Plot (open facing the central stone path)
		local fenceColor = Color3.fromRGB(168, 112, 62)
		for _, zOff in ipairs({ -plotD * 0.5, plotD * 0.5 }) do
			makePart({
				Name = "FenceRailZ",
				Size = Vector3.new(plotW, 3.2, 1.0),
				Position = cfg.Center + Vector3.new(0, 1.8, zOff),
				Color = fenceColor,
				Material = Enum.Material.WoodPlanks,
				Parent = plotModel,
			})
		end
		makePart({
			Name = "FenceRailOuterX",
			Size = Vector3.new(1.0, 3.2, plotD),
			Position = cfg.Center + Vector3.new(-cfg.FaceDir * (plotW * 0.5), 1.8, 0),
			Color = fenceColor,
			Material = Enum.Material.WoodPlanks,
			Parent = plotModel,
		})

		-- Owner Signpost at Plot Entrance
		local signPost = makePart({
			Name = "OwnerSign",
			Size = Vector3.new(8.5, 4.2, 1.2),
			Position = cfg.Center + Vector3.new(cfg.FaceDir * (plotW * 0.42), 5.2, -plotD * 0.42),
			Color = cfg.Color,
			Material = Enum.Material.SmoothPlastic,
			Parent = plotModel,
		})
		createBillboardText(signPost, "🏠 PLOT #" .. tostring(cfg.Index) .. " (UNCLAIMED)", cfg.Color, Vector3.new(0, 3.4, 0))

		-- Big 24-Stud Player Base House on Outer Back Corner
		buildBigCartoonHouse(
			plotModel,
			cfg.Center + Vector3.new(-cfg.FaceDir * 15, 0.5, 8),
			if cfg.FaceDir > 0 then 90 else -90,
			cfg.Color,
			Color3.fromRGB(225, 75, 85),
			cfg.Index,
			22
		)

		-- 1. Giant 18-Stud Green Dino-Jaw Speed Treadmill on each Plot!
		local treadCenter = cfg.Center + Vector3.new(-cfg.FaceDir * 11, 0.5, -7.5)
		buildDinoJawTreadmill(plotModel, treadCenter, cfg.FaceDir, cfg.Index)

		-- 2. Cash Collector Chest + Glowing Green Pad at Front Entrance
		local collectPad = makePart({
			Name = "CollectCashPad",
			Size = Vector3.new(7.5, 0.8, 7.5),
			Position = cfg.Center + Vector3.new(cfg.FaceDir * 16, 0.65, -9.5),
			Color = Color3.fromRGB(65, 245, 110),
			Material = Enum.Material.Neon,
			Parent = plotModel,
		})
		placePrebuiltAsset("CashChest", 1, plotModel, collectPad.Position + Vector3.new(0, 0.3, 0), if cfg.FaceDir > 0 then 90 else -90, 4.2, false)
		createBillboardText(collectPad, "💰 COLLECT $0\n(Step Here)", Color3.fromRGB(95, 255, 130), Vector3.new(0, 5.2, 0))

		-- 3. Speed / Treadmill Upgrade Stall beside Cash Pad
		local upgStand = makePart({
			Name = "SpeedUpgradeStand",
			Size = Vector3.new(5.5, 4.5, 5.5),
			Position = cfg.Center + Vector3.new(cfg.FaceDir * 16, 2.5, 8.5),
			Color = Color3.fromRGB(165, 95, 255),
			Material = Enum.Material.SmoothPlastic,
			Parent = plotModel,
		})
		placePrebuiltAsset("MarketStalls", ((cfg.Index - 1) % 2) + 1, plotModel, Vector3.new(upgStand.Position.X, 0.5, upgStand.Position.Z), if cfg.FaceDir > 0 then 90 else -90, 10.5, false)
		local upgPrompt = Instance.new("ProximityPrompt")
		upgPrompt.Name = "UpgradeSpeedPrompt"
		upgPrompt.ActionText = "Upgrade Treadmill (+Speed)"
		upgPrompt.ObjectText = "🦖 Cost: $50"
		upgPrompt.HoldDuration = 0
		upgPrompt.MaxActivationDistance = 14
		upgPrompt.RequiresLineOfSight = false
		upgPrompt.Parent = upgStand

		-- 4. 5 Glowing Purple Hatch Incubator Rings Along the Front Edge of the Plot
		local incubatorsFolder = Instance.new("Folder")
		incubatorsFolder.Name = "Incubators"
		incubatorsFolder.Parent = plotModel

		for incIdx = 1, 5 do
			local zOff = -12 + (incIdx - 1) * 6.0
			local incPos = cfg.Center + Vector3.new(cfg.FaceDir * 8.5, 0.65, zOff)

			local incPad = makePart({
				Name = "Incubator_" .. tostring(incIdx),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1.1, 5.4, 5.4),
				CFrame = CFrame.new(incPos) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(190, 75, 255),
				Material = Enum.Material.Neon,
				Parent = incubatorsFolder,
			})
			incPad:SetAttribute("IncubatorIndex", incIdx)
			incPad:SetAttribute("State", "Empty")

			placePrebuiltAsset("IncubatorPod", 1, incubatorsFolder, incPos + Vector3.new(0, -0.2, 0), 0, 3.2, false)

			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "IncubatorPrompt"
			prompt.ActionText = "Plant Carried Egg"
			prompt.ObjectText = "Empty Incubator #" .. tostring(incIdx)
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 13
			prompt.RequiresLineOfSight = false
			prompt.Parent = incPad

			createBillboardText(incPad, "🥚 INCUBATOR #" .. tostring(incIdx) .. "\n[EMPTY]", Color3.fromRGB(225, 175, 255), Vector3.new(0, 4.8, 0), UDim2.fromOffset(175, 46))
		end

		-- 5. 12 Lawn Pedestals (4x3 grid) for Placing Hatched Squishies that earn $/sec
		local pedestalsFolder = Instance.new("Folder")
		pedestalsFolder.Name = "Pedestals"
		pedestalsFolder.Parent = plotModel

		local slotIndex = 1
		for row = 1, 3 do
			for col = 1, 4 do
				local xOff = -cfg.FaceDir * (0.5 + (row - 1) * 4.8)
				local zOff = 1.5 + (col - 1) * 3.8
				local pedPos = cfg.Center + Vector3.new(xOff, 0.6, zOff)

				local ped = makePart({
					Name = "Pedestal_" .. tostring(slotIndex),
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(0.7, 4.0, 4.0),
					CFrame = CFrame.new(pedPos) * CFrame.Angles(0, 0, math.rad(90)),
					Color = Color3.fromRGB(115, 225, 105),
					Material = Enum.Material.SmoothPlastic,
					Parent = pedestalsFolder,
				})
				ped:SetAttribute("SlotIndex", slotIndex)
				slotIndex += 1
			end
		end
	end
end

-- Builds Themed Perimeter Walls for Each Compact 95-Stud Biome Arena
local function buildBiomePerimeter(parent: Instance, levelInfo: any, halfW: number)
	local zMid = (levelInfo.ZStart + levelInfo.ZEnd) * 0.5
	local length = math.abs(levelInfo.ZStart - levelInfo.ZEnd)

	for _, side in ipairs({ -1, 1 }) do
		local wallX = side * (halfW + WALL_THICKNESS * 0.5)
		makePart({
			Name = "BiomeWall_" .. tostring(levelInfo.Id) .. "_" .. tostring(side),
			Size = Vector3.new(WALL_THICKNESS, WALL_HEIGHT, length),
			Position = Vector3.new(wallX, WALL_HEIGHT * 0.5, zMid),
			Color = levelInfo.SecondaryColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = parent,
		})

		-- Level 2 Candy Kingdom: Giant 3D Chocolate Bar & Wafer Cookie Walls (matches real_game_annotated_2_biome_boss_eggs.png)
		if levelInfo.Id == 2 then
			for zSeg = levelInfo.ZStart - 10, levelInfo.ZEnd + 10, -18 do
				makePart({
					Name = "ChocoWallBlock",
					Size = Vector3.new(4.5, 20, 15),
					Position = Vector3.new(side * (halfW - 1.5), 10, zSeg),
					Color = Color3.fromRGB(108, 56, 30),
					Material = Enum.Material.SmoothPlastic,
					Parent = parent,
				})
				makePart({
					Name = "PinkIcingDrip",
					Size = Vector3.new(5.2, 4.2, 15.4),
					Position = Vector3.new(side * (halfW - 1.5), 19.5, zSeg),
					Color = Color3.fromRGB(255, 130, 195),
					Material = Enum.Material.SmoothPlastic,
					Parent = parent,
				})
			end
		end
	end
end

-- Builds the Front Obby Gauntlet + Oversized Scenery + Boss Egg Nest in each Biome Arena
local function buildBiomeArenaContent(parent: Instance, levelInfo: any, obstaclesFolder: Folder)
	local id = levelInfo.Id
	local zStart = levelInfo.ZStart
	local zEnd = levelInfo.ZEnd
	local zBoss = zStart - 56 -- Where the 2 Sleeping Bosses & Egg Cluster live

	-- 1. Front Obby Gauntlet (between Gate at zStart and Boss Nest at zBoss)
	local moatZ = zStart - 22
	local moatColor = if id == 1 then Color3.fromRGB(55, 175, 255)
		elseif id == 2 then Color3.fromRGB(255, 95, 175)
		elseif id == 3 then Color3.fromRGB(40, 210, 245)
		elseif id == 4 then Color3.fromRGB(165, 75, 255)
		else Color3.fromRGB(255, 75, 20)

	-- Hazard Moat across the center lane (touching it drops your stolen egg right at the moat edge!)
	local moat = makePart({
		Name = "HazardMoat_" .. tostring(id),
		Size = Vector3.new(96, 0.9, 14),
		Position = Vector3.new(0, 0.2, moatZ),
		Color = moatColor,
		Material = Enum.Material.Neon,
		Parent = obstaclesFolder,
	})
	moat:SetAttribute("HazardDropEgg", true)
	moat:SetAttribute("KnockbackImpulse", 55)

	-- Left & Right Safe Bridges + Stepping Stones across the Hazard Moat
	for _, bridgeX in ipairs({ -30, 30 }) do
		local placedBridge = placePrebuiltAsset("Bridges", ((id + (if bridgeX > 0 then 1 else 0)) % 2) + 1, parent, Vector3.new(bridgeX, 0.2, moatZ), 0, 5.2, true)
		if not placedBridge then
			makePart({
				Name = "SafeBridge",
				Size = Vector3.new(12, 1.5, 18),
				Position = Vector3.new(bridgeX, 1.2, moatZ),
				Color = Color3.fromRGB(165, 110, 62),
				Material = Enum.Material.WoodPlanks,
				Parent = parent,
			})
		end
	end

	-- Center Obby Stepping Pads across the Moat
	for idx, stepX in ipairs({ -10, 0, 10 }) do
		makePart({
			Name = "ObbyStepPad_" .. tostring(idx),
			Size = Vector3.new(6.5, 1.8, 6.5),
			Position = Vector3.new(stepX, 1.2, moatZ + (if idx % 2 == 0 then 2.5 else -2.5)),
			Color = Color3.fromRGB(255, 230, 75),
			Material = Enum.Material.SmoothPlastic,
			Parent = parent,
		})
	end

	-- Prebuilt Obby Stage Obstacles on Left & Right approaches
	placePrebuiltAsset("ObbyStages", ((id - 1) % 3) + 1, parent, Vector3.new(-46, 0, zStart - 34), 0, 12.0, true)
	placePrebuiltAsset("ObbyStages", (id % 3) + 1, parent, Vector3.new(46, 0, zStart - 34), 180, 12.0, true)

	-- Spinning Sweeper Knockback Bar at zStart - 35 (jump over it while escaping with an egg!)
	local spinnerPos = Vector3.new(0, 2.6, zStart - 35)
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
		Size = Vector3.new(34, 1.8, 1.8),
		Position = spinnerPos + Vector3.new(0, 0.4, 0),
		Color = Color3.fromRGB(255, 65, 95),
		Material = Enum.Material.Neon,
		Parent = obstaclesFolder,
	})
	sweeper:SetAttribute("SpinSpeed", (1.2 + id * 0.25) * (if id % 2 == 0 then 1 else -1))
	sweeper:SetAttribute("KnockbackImpulse", 75)
	sweeper:SetAttribute("HazardDropEgg", true)

	-- 2 Super Bounce Pads per Biome (quick aerial escape over the moat!)
	for _, bx in ipairs({ -22, 22 }) do
		local bPad = makePart({
			Name = "BouncePad",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.4, 7.5, 7.5),
			CFrame = CFrame.new(bx, 0.7, zStart - 42) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 235, 55),
			Material = Enum.Material.Neon,
			Parent = parent,
		})
		bPad:SetAttribute("BounceImpulse", 98)
	end

	-- 2. Central Boss Nest Carpet under the 2 Giant Sleeping Bosses & Egg Cluster
	makePart({
		Name = "BossNestArenaPad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 58, 58),
		CFrame = CFrame.new(0, 0.3, zBoss) * CFrame.Angles(0, 0, math.rad(90)),
		Color = levelInfo.SecondaryColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = parent,
	})

	-- 3. Oversized 18-28 Stud Biome Scenery Framing the Arena (No tiny clutter!)
	local scenerySpots = {
		Vector3.new(-52, 0, zStart - 16),
		Vector3.new(52, 0, zStart - 16),
		Vector3.new(-52, 0, zBoss),
		Vector3.new(52, 0, zBoss),
		Vector3.new(-48, 0, zEnd + 14),
		Vector3.new(48, 0, zEnd + 14),
		Vector3.new(-22, 0, zEnd + 12),
		Vector3.new(22, 0, zEnd + 12),
	}

	for idx, sPos in ipairs(scenerySpots) do
		local yaw = (idx * 53) % 360
		if id == 1 then
			placePrebuiltAsset("MeadowTrees", ((idx - 1) % 3) + 1, parent, sPos, yaw, 24.0, true)
		elseif id == 2 then
			-- Giant 22-26 Stud Swirl Lollipops & Candy Trees (matches real_game_annotated_2_biome_boss_eggs.png)
			local candyPlaced = placePrebuiltAsset("CandyProps", ((idx - 1) % 5) + 1, parent, sPos, yaw, 24.0, true)
			if not candyPlaced or idx % 2 == 0 then
				-- Guaranteed Giant Swirl Lollipop
				local stick = makePart({
					Name = "GiantLollipopStick",
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(18, 1.4, 1.4),
					CFrame = CFrame.new(sPos + Vector3.new(0, 9, 0)) * CFrame.Angles(0, 0, math.rad(90)),
					Color = Color3.fromRGB(255, 255, 255),
					Material = Enum.Material.SmoothPlastic,
					Parent = parent,
				})
				makePart({
					Name = "GiantLollipopHead",
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(2.6, 11.5, 11.5),
					CFrame = CFrame.new(stick.Position + Vector3.new(0, 11, 0)) * CFrame.Angles(0, math.rad(yaw), 0),
					Color = if idx % 3 == 0 then Color3.fromRGB(255, 85, 175) elseif idx % 3 == 1 then Color3.fromRGB(95, 225, 255) else Color3.fromRGB(255, 210, 70),
					Material = Enum.Material.SmoothPlastic,
					Parent = parent,
				})
			end
		elseif id == 3 then
			placePrebuiltAsset("PalmTrees", ((idx - 1) % 3) + 1, parent, sPos, yaw, 25.0, true)
		elseif id == 4 then
			placePrebuiltAsset("Crystals", ((idx - 1) % 3) + 1, parent, sPos, yaw, 22.0, true)
		else
			placePrebuiltAsset("VolcanoRocks", ((idx - 1) % 3) + 1, parent, sPos, yaw, 23.0, true)
		end
	end
end

-- Builds the Biome Divider Gate with a Speed Requirement Barrier in the Doorway
local function buildLevelGate(parent: Instance, levelInfo: any, halfW: number): Part
	local zPos = levelInfo.ZStart
	local gateModel = Instance.new("Model")
	gateModel.Name = "Gate_Level_" .. tostring(levelInfo.Id)
	gateModel.Parent = parent

	local doorWidth = 34
	local sideWallWidth = halfW - (doorWidth * 0.5)

	for _, side in ipairs({ -1, 1 }) do
		local xCenter = side * ((doorWidth * 0.5) + (sideWallWidth * 0.5))
		makePart({
			Name = "DividerWall",
			Size = Vector3.new(sideWallWidth, WALL_HEIGHT, 4),
			Position = Vector3.new(xCenter, WALL_HEIGHT * 0.5, zPos),
			Color = levelInfo.GateColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = gateModel,
		})

		makePart({
			Name = "GatePillar",
			Size = Vector3.new(5.5, WALL_HEIGHT + 5, 5.5),
			Position = Vector3.new(side * (doorWidth * 0.5), (WALL_HEIGHT + 5) * 0.5, zPos),
			Color = levelInfo.SecondaryColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = gateModel,
		})
	end

	local header = makePart({
		Name = "GateHeader",
		Size = Vector3.new(doorWidth + 10, 6.5, 6.5),
		Position = Vector3.new(0, WALL_HEIGHT + 3, zPos),
		Color = levelInfo.GateColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = gateModel,
	})

	local reqSpeed = levelInfo.RequiredSpeed or 16
	local reqText = if reqSpeed <= 16
		then string.format("STAGE %d: %s (OPEN!)", levelInfo.Id, string.upper(levelInfo.Name))
		else string.format("STAGE %d: %s  [⚡ %d SPEED REQUIRED]", levelInfo.Id, string.upper(levelInfo.Name), reqSpeed)

	createBillboardText(header, reqText, Color3.fromRGB(255, 255, 255), Vector3.new(0, 5.2, 0), UDim2.fromOffset(320, 68))

	local barrier = makePart({
		Name = "GateBarrier_" .. tostring(levelInfo.Id),
		Size = Vector3.new(doorWidth - 2, WALL_HEIGHT, 2.2),
		Position = Vector3.new(0, WALL_HEIGHT * 0.5, zPos),
		Color = levelInfo.GateColor,
		Material = Enum.Material.ForceField,
		Transparency = if reqSpeed <= 16 then 0.88 else 0.32,
		CanCollide = reqSpeed > 16,
		Parent = gateModel,
	})
	barrier:SetAttribute("LevelId", levelInfo.Id)
	barrier:SetAttribute("RequiredCoins", levelInfo.RequiredCoins)
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

	buildSafeZoneAndPlots(worldFolder)

	local levelsFolder = Instance.new("Folder")
	levelsFolder.Name = "Levels"
	levelsFolder.Parent = worldFolder

	local eggsFolder = Instance.new("Folder")
	eggsFolder.Name = "WorldEggs"
	eggsFolder.Parent = worldFolder

	local guardiansFolder = Instance.new("Folder")
	guardiansFolder.Name = "Guardians"
	guardiansFolder.Parent = worldFolder

	local obstaclesFolder = Instance.new("Folder")
	obstaclesFolder.Name = "DynamicObstacles"
	obstaclesFolder.Parent = worldFolder

	for _, levelInfo in ipairs(SlimeData.Levels) do
		local lvlFolder = Instance.new("Folder")
		lvlFolder.Name = "Level_" .. tostring(levelInfo.Id) .. "_" .. levelInfo.Name
		lvlFolder.Parent = levelsFolder

		local zLength = math.abs(levelInfo.ZStart - levelInfo.ZEnd)
		local zMid = (levelInfo.ZStart + levelInfo.ZEnd) * 0.5

		-- Biome Floor
		makePart({
			Name = "Floor_" .. levelInfo.Name,
			Size = Vector3.new(MAP_WIDTH, 2, zLength),
			Position = Vector3.new(0, -1, zMid),
			Color = levelInfo.FloorColor,
			Material = levelInfo.FloorMaterial,
			Parent = lvlFolder,
		})

		-- Center Path Lane leading to the Boss Egg Nest
		makePart({
			Name = "CenterLane",
			Size = Vector3.new(20, 0.16, zLength - 8),
			Position = Vector3.new(0, 0.08, zMid),
			Color = levelInfo.SecondaryColor,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = lvlFolder,
		})

		buildBiomePerimeter(lvlFolder, levelInfo, halfW)
		buildBiomeArenaContent(lvlFolder, levelInfo, obstaclesFolder)

		gateBarriers[levelInfo.Id] = buildLevelGate(lvlFolder, levelInfo, halfW)

		if levelInfo.Guardians then
			for idx, gData in ipairs(levelInfo.Guardians) do
				local gId = string.format("Guardian_%d_%d", levelInfo.Id, idx)
				local gModel = SquishyBuilder.CreateGuardianModel(gData.Name, gData.Color, gData.Radius)
				gModel.Name = gId
				gModel:PivotTo(CFrame.new(gData.Center))
				gModel.Parent = guardiansFolder

				guardians[gId] = {
					Model = gModel,
					Data = gData,
					LevelInfo = levelInfo,
				}
			end
		end
	end

	-- Final Back Wall behind Level 5
	local lastLevel = SlimeData.Levels[#SlimeData.Levels]
	makePart({
		Name = "EndOfWorldWall",
		Size = Vector3.new(MAP_WIDTH + 8, WALL_HEIGHT + 10, WALL_THICKNESS),
		Position = Vector3.new(0, (WALL_HEIGHT + 10) * 0.5, lastLevel.ZEnd - 2),
		Color = lastLevel.SecondaryColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = worldFolder,
	})

	-- Spawn the 35 Oversized Ornate Eggs Clustered Around the Sleeping Bosses!
	for _, slime in ipairs(SlimeData.Slimes) do
		local eggModel = SquishyBuilder.CreateWorldEgg(slime)
		eggModel:PivotTo(CFrame.new(slime.SpawnOffset))
		eggModel.Parent = eggsFolder
		worldEggs[slime.Id] = eggModel
	end

	return {
		WorldFolder = worldFolder,
		GateBarriers = gateBarriers,
		WorldEggs = worldEggs,
		Guardians = guardians,
	}
end

return WorldBuilder
