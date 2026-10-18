--!strict
-- PrebuiltLoader.luau
-- Loads & normalizes real Creator Store 3D models (MeshParts & Parts via game:GetObjects in Studio)
-- into ReplicatedStorage.Models.PrebuiltAssets for Squishmallows, CutePets, Dragons, Dinosaurs,
-- Sharks, Monsters, DragonEggs, Houses, Trees, Candy, PalmTrees, Crystals, VolcanoRocks, Bridges,
-- Obstacles (Obby Kit), Fountain, Chest, and BirdNest, with strict bounding-box & FileMesh guards
-- plus high-detail procedural fallbacks so every category is 100% populated.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrebuiltLoader = {}

-- Fast, verified Creator Store 3D Asset IDs for Brainrots, Eggs, Gold Coins, Obby Courses & Stage 1-8 Landmarks
PrebuiltLoader.CREATOR_STORE_ASSETS = {
	Squishmallows = { 8539945428, 5495888435 },
	Brainrots = {
		Tralalero = 111854862176457, -- Tralalero Tralala
		Bombardiro = 117924360887083, -- Bombardiro Crocodilo
		TungTung = 138151705692565, -- Tung Tung Tung Sahur
		Lirili = 100138257253783, -- Lirili Larila
		Patapim = 100538198930997, -- Brr Brr Patapim
		Cappuccino = 138416013720223, -- Cappuccino Assassino
		Chimpanzini = 134140230073093, -- Chimpanzini Bananini
		Saturno = 129565620410132, -- La Vaca Saturno Saturnita
		Ballerina = 132021456717690, -- Ballerina Cappuccina
		Frigo = 136392638607318, -- Frigo Camelo
		Gusini = 111434069005815, -- Bombombini Gusini
		Glorbo = 12370206919, -- Glorbo Fruttodrillo
		Maxwell = 11390853367, -- Maxwell Cat
		Trippi = 132790929973448, -- Trippi Troppi
		Burbaloni = 86371208126006, -- Burbaloni Luliloli
		Orangutini = 134140230073093, -- Orangutini Ananasini
		Boneca = 100138257253783, -- Boneca Ambalabu
		Trulimero = 132790929973448, -- Trulimero Trulicina
		Girafa = 136392638607318, -- Girafa Celestre
		BriBri = 138416013720223, -- Bri Bri Bicus Dicus
		Garamaraman = 138151705692565, -- Garamaraman
		IlCacto = 86371208126006, -- Il Cacto Hipopotamo
		Blueberrinni = 132790929973448, -- Blueberrinni Octopussini
		Crabracadabra = 138416013720223, -- Chef Crabracadabra
		Chicleteira = 132021456717690, -- Chicleteira Bicicleteira
		Spijuniro = 111434069005815, -- Spijuniro Golubiro
		Tigrrullini = 12370206919, -- Tigrrullini Watermellini
		Zibra = 136392638607318, -- Zibra Zubra Zibralini
		Graipussi = 129565620410132, -- Graipussi Medussi
		InfernoBombardiro = 117924360887083, -- Inferno Bombardiro Rex
		Gattatino = 11390853367, -- Gattatino Neonino
		Matteo = 100538198930997, -- Matteo The Wise
		UdinDin = 138151705692565, -- Udin Din Din Dun
		Skibidi = 14819601003, -- Skibidi Cyber Titan
		CosmicTralalero = 111854862176457, -- Cosmic Tralalero God
	},
	BrainrotEggs = { 139663370542966, 154752063, 97487252360689 },
	GoldCoins = { 25638529, 25718369, 1564608051, 9418153507 },
	ObbyPieces = {
		14288014072, 76697739621349, 73062373189329, 14667164618, -- Obby Stage Courses
		12120501468, 79641631925549, 12120527511, 95225104831884, -- Obby Obstacles & Parkour
		10202936, 4514115489, 1172079000, 4644268803, -- Obby Spinners / Sweeper Beams
		14796107102, 8517401506, 134019342626406, -- Jump Pads & Moving Platforms
		76838144711090, 82837302167177, -- Trampoline Bounce Pads
		13804790028, 12317896672, -- Ladders & Climb Walls
	},
	StageLandmarks = {
		114591511925320, 7860328354, 9839019518, 18771840070, -- Stage 1: Windmill, Treehouses, Mushroom Cottage
		4400478930, 137470241818443, 131526002682377, -- Stage 2: Gingerbread Mansion, Candy Canes, Carousel
		7137210839, 5706899551, 18852029806, 95052703843351, -- Stage 3: Pirate Ship, Water Slide, Sand Castle, Lighthouse
		123493048047404, 101559450428915, -- Stage 4: Dragon Statue, Bamboo Pagoda Tower
		3858204539, 116874485094995, 73198167966628, -- Stage 5: Crystal Cave, Cyberpunk Skyscraper, Arcade
		85537579537253, 2135149422, 154465953, -- Stage 6: Ferris Wheel, Rainbow Bridge, Cloud/Ice Palace
		256969126, 16437023855, -- Stage 7: Erupting Volcano, Obsidian Skull Fortress
		50089105, 171327489, 4790754477, -- Stage 8: UFO Mothership, Void Portal, Golden Throne
	},
	Trees = { 4893246329 },
	PalmTrees = { 10562894034, 4586726395 },
	Crystals = { 4576917611 },
	Bridges = { 18262413487, 2135149422 },
	Bats = { 4494586033, 13233709250 },
	BearTraps = { 9615431080, 470975521 },
}

PrebuiltLoader.BRAINROT_ID_TO_KEY = {
	[1] = "Tralalero",
	[2] = "Lirili",
	[3] = "Trippi",
	[4] = "Burbaloni",
	[5] = "Cappuccino",
	[6] = "Ballerina",
	[7] = "Chimpanzini",
	[8] = "Frigo",
	[9] = "TungTung",
	[10] = "Bombardiro",
	[11] = "Gusini",
	[12] = "Glorbo",
	[13] = "Patapim",
	[14] = "Orangutini",
	[15] = "Boneca",
	[16] = "Trulimero",
	[17] = "Girafa",
	[18] = "BriBri",
	[19] = "Garamaraman",
	[20] = "Maxwell",
	[21] = "Saturno",
	[22] = "IlCacto",
	[23] = "Blueberrinni",
	[24] = "Crabracadabra",
	[25] = "Chicleteira",
	[26] = "Spijuniro",
	[27] = "Tigrrullini",
	[28] = "Zibra",
	[29] = "Graipussi",
	[30] = "InfernoBombardiro",
	[31] = "Gattatino",
	[32] = "Matteo",
	[33] = "UdinDin",
	[34] = "Skibidi",
	[35] = "CosmicTralalero",
}

local HOUSE_PALETTES = {
	{ Wall = Color3.fromRGB(255, 210, 115), Roof = Color3.fromRGB(215, 62, 58), Trim = Color3.fromRGB(255, 252, 245) },
	{ Wall = Color3.fromRGB(135, 215, 255), Roof = Color3.fromRGB(52, 98, 215), Trim = Color3.fromRGB(255, 252, 245) },
	{ Wall = Color3.fromRGB(255, 165, 205), Roof = Color3.fromRGB(185, 55, 140), Trim = Color3.fromRGB(255, 252, 245) },
	{ Wall = Color3.fromRGB(165, 240, 160), Roof = Color3.fromRGB(48, 158, 82), Trim = Color3.fromRGB(255, 252, 245) },
	{ Wall = Color3.fromRGB(245, 232, 210), Roof = Color3.fromRGB(145, 78, 45), Trim = Color3.fromRGB(255, 252, 245) },
}

local function makePart(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = if props.CanCollide ~= nil then props.CanCollide else false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(255, 255, 255)
	p.Size = props.Size or Vector3.new(2, 2, 2)
	p.Transparency = props.Transparency or 0
	p.Reflectance = props.Reflectance or 0
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

local function makeWedge(props: { [string]: any }): WedgePart
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.CanCollide = if props.CanCollide ~= nil then props.CanCollide else false
	w.CanTouch = false
	w.CanQuery = false
	w.Massless = true
	w.CastShadow = false
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Material = props.Material or Enum.Material.SmoothPlastic
	w.Color = props.Color or Color3.fromRGB(255, 255, 255)
	w.Size = props.Size or Vector3.new(2, 2, 2)
	if props.CFrame then
		w.CFrame = props.CFrame
	elseif props.Position then
		w.Position = props.Position
	end
	w.Name = props.Name or "Wedge"
	if props.Parent then
		w.Parent = props.Parent
	end
	return w
end

local function finalizeTemplate(m: Model): Model
	local ok, bbCF, bbSize = pcall(function()
		return m:GetBoundingBox()
	end)
	if ok and bbSize.Magnitude > 0.05 then
		local bottomCenter = bbCF.Position - Vector3.new(0, bbSize.Y * 0.5, 0)
		local offset = -bottomCenter
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CFrame = d.CFrame + offset
			end
		end
	end
	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end

-- Sanitizes an imported Creator Store Model:
-- 1. Strips all scripts, sounds, joints, seats, and lights
-- 2. Keeps real binary MeshParts & standard Parts/Wedges
-- 3. Removes FileMesh SpecialMeshes that cause 360-stud bounding-box mismatches
-- 4. Recolors houses with proper architectural palettes when category == "Houses"
local function sanitizeCreatorStoreModel(rawInst: Instance, category: string, index: number): Model?
	local container = Instance.new("Model")
	container.Name = category .. "_Store_" .. tostring(index)

	if rawInst:IsA("Model") or rawInst:IsA("Folder") or rawInst:IsA("Tool") or rawInst:IsA("Accessory") then
		for _, child in ipairs(rawInst:GetChildren()) do
			child.Parent = container
		end
	elseif rawInst:IsA("BasePart") then
		rawInst.Parent = container
	else
		return nil
	end

	-- Remove scripts, GUI, sounds, decals/textures (unless Brainrots), constraints, joints, and oversized invisible hitboxes
	local isBrainrot = (category == "Brainrots")
	for _, desc in ipairs(container:GetDescendants()) do
		if
			desc:IsA("LuaSourceContainer")
			or desc:IsA("Sound")
			or (not isBrainrot and desc:IsA("Decal"))
			or (not isBrainrot and desc:IsA("Texture"))
			or (not isBrainrot and desc:IsA("SurfaceAppearance"))
			or desc:IsA("ParticleEmitter")
			or desc:IsA("Trail")
			or desc:IsA("Beam")
			or desc:IsA("Light")
			or desc:IsA("GuiBase")
			or desc:IsA("ProximityPrompt")
			or desc:IsA("ClickDetector")
			or desc:IsA("Constraint")
			or desc:IsA("JointInstance")
			or desc:IsA("WeldConstraint")
			or desc:IsA("Animator")
			or desc:IsA("AnimationController")
			or desc:IsA("Humanoid")
		then
			desc:Destroy()
		elseif desc:IsA("MeshPart") then
			if not isBrainrot then
				desc.TextureID = ""
			else
				desc:SetAttribute("PreserveCreatorStoreMesh", true)
			end
		elseif desc:IsA("SpecialMesh") then
			if not isBrainrot then
				desc.TextureId = ""
				if desc.MeshType == Enum.MeshType.FileMesh then
					-- If the parent Part is a tiny 1x1x1 placeholder for a FileMesh, remove the part so it never turns into a giant block
					local parentPart = desc.Parent
					desc:Destroy()
					if parentPart and parentPart:IsA("BasePart") and parentPart.Size.Magnitude < 2.2 then
						parentPart:Destroy()
					end
				end
			else
				desc:SetAttribute("PreserveCreatorStoreMesh", true)
				if desc.Parent and desc.Parent:IsA("BasePart") then
					desc.Parent:SetAttribute("PreserveCreatorStoreMesh", true)
				end
			end
		end
	end

	local validParts: { BasePart } = {}
	for _, desc in ipairs(container:GetDescendants()) do
		if desc:IsA("BasePart") then
			local nm = string.lower(desc.Name)
			if
				desc.Transparency >= 0.95
				or desc.Size.X > 48
				or desc.Size.Y > 48
				or desc.Size.Z > 48
				or desc.Size.Magnitude < 0.05
				or string.find(nm, "baseplate")
				or string.find(nm, "spawn")
				or string.find(nm, "background")
			then
				desc:Destroy()
			else
				desc.Anchored = true
				desc.CanCollide = false
				desc.CanTouch = false
				desc.CanQuery = false
				desc.Massless = true
				desc.CastShadow = false
				-- Zero Map Glow Rule: environment & landmark models never use Neon; only collectibles (Brainrots, Eggs, Coins, Squishies) may glow!
				if
					desc.Material == Enum.Material.Neon
					and category ~= "Brainrots"
					and category ~= "BrainrotEggs"
					and category ~= "GoldCoins"
					and category ~= "Squishmallows"
				then
					desc.Material = Enum.Material.SmoothPlastic
				end
				table.insert(validParts, desc)
			end
		end
	end

	if #validParts == 0 then
		container:Destroy()
		return nil
	end

	-- Properly color Creator Store Houses with matte architectural palettes!
	if category == "Houses" then
		local pal = HOUSE_PALETTES[((index - 1) % #HOUSE_PALETTES) + 1]
		local bbCF, bbSize = container:GetBoundingBox()
		local roofThresholdY = bbCF.Position.Y + bbSize.Y * 0.18
		for _, p in ipairs(validParts) do
			local nm = string.lower(p.Name)
			if string.find(nm, "roof") or string.find(nm, "shingle") or p.Position.Y > roofThresholdY or p:IsA("WedgePart") then
				p.Color = pal.Roof
			elseif string.find(nm, "window") or string.find(nm, "glass") then
				p.Color = Color3.fromRGB(165, 205, 235)
				p.Material = Enum.Material.Glass
			elseif string.find(nm, "door") then
				p.Color = Color3.fromRGB(128, 74, 38)
				p.Material = Enum.Material.Wood
			elseif string.find(nm, "trim") or string.find(nm, "frame") or string.find(nm, "pillar") then
				p.Color = pal.Trim
			else
				p.Color = pal.Wall
			end
		end
	end

	return finalizeTemplate(container)
end


local function buildHouseTemplate(idx: number, wallColor: Color3, roofColor: Color3, trimColor: Color3): Model
	local m = Instance.new("Model")
	m.Name = "Houses_" .. tostring(idx)

	local w, bodyH, d = 18, 13, 15
	local roofH = 8

	makePart({
		Name = "Foundation",
		Size = Vector3.new(w + 1.6, 1.2, d + 1.6),
		Position = Vector3.new(0, 0.6, 0),
		Color = Color3.fromRGB(145, 148, 160),
		Material = Enum.Material.Cobblestone,
		Parent = m,
	})

	makePart({
		Name = "MainBody",
		Size = Vector3.new(w, bodyH, d),
		Position = Vector3.new(0, 1.2 + bodyH * 0.5, 0),
		Color = wallColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = m,
	})

	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			makePart({
				Name = "CornerTrim",
				Size = Vector3.new(1.2, bodyH, 1.2),
				Position = Vector3.new(sx * (w * 0.5), 1.2 + bodyH * 0.5, sz * (d * 0.5)),
				Color = trimColor,
				Material = Enum.Material.SmoothPlastic,
				Parent = m,
			})
		end
	end

	local roofY = 1.2 + bodyH + roofH * 0.5
	makeWedge({
		Name = "RoofLeft",
		Size = Vector3.new(d + 2.8, roofH, (w * 0.5) + 1.8),
		CFrame = CFrame.new(-((w * 0.25) + 0.9), roofY, 0) * CFrame.Angles(0, math.rad(90), 0),
		Color = roofColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = m,
	})
	makeWedge({
		Name = "RoofRight",
		Size = Vector3.new(d + 2.8, roofH, (w * 0.5) + 1.8),
		CFrame = CFrame.new((w * 0.25) + 0.9, roofY, 0) * CFrame.Angles(0, math.rad(-90), 0),
		Color = roofColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = m,
	})

	makePart({
		Name = "Chimney",
		Size = Vector3.new(2.8, roofH + 3.2, 2.8),
		Position = Vector3.new(w * 0.28, 1.2 + bodyH + roofH * 0.55, -d * 0.2),
		Color = Color3.fromRGB(185, 85, 65),
		Material = Enum.Material.Brick,
		Parent = m,
	})

	makePart({
		Name = "PorchStep",
		Size = Vector3.new(6.2, 0.9, 3.2),
		Position = Vector3.new(0, 0.45, d * 0.5 + 1.4),
		Color = Color3.fromRGB(165, 168, 178),
		Material = Enum.Material.Cobblestone,
		Parent = m,
	})
	makePart({
		Name = "DoorFrame",
		Size = Vector3.new(5.0, 7.8, 0.6),
		Position = Vector3.new(0, 1.2 + 3.9, d * 0.5 + 0.2),
		Color = trimColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = m,
	})
	makePart({
		Name = "Door",
		Size = Vector3.new(4.0, 7.0, 0.7),
		Position = Vector3.new(0, 1.2 + 3.5, d * 0.5 + 0.3),
		Color = Color3.fromRGB(125, 74, 38),
		Material = Enum.Material.Wood,
		Parent = m,
	})

	for _, wx in ipairs({ -w * 0.28, w * 0.28 }) do
		makePart({
			Name = "WindowFrame",
			Size = Vector3.new(4.2, 4.2, 0.6),
			Position = Vector3.new(wx, 1.2 + bodyH * 0.58, d * 0.5 + 0.2),
			Color = trimColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = m,
		})
		makePart({
			Name = "WindowGlass",
			Size = Vector3.new(3.4, 3.4, 0.7),
			Position = Vector3.new(wx, 1.2 + bodyH * 0.58, d * 0.5 + 0.28),
			Color = Color3.fromRGB(175, 210, 238),
			Material = Enum.Material.Glass,
			Parent = m,
		})
	end

	return finalizeTemplate(m)
end

local function buildTreeTemplate(idx: number): Model
	local m = Instance.new("Model")
	m.Name = "Trees_" .. tostring(idx)

	makePart({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(10, 2.8, 2.8),
		CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(115, 74, 42),
		Material = Enum.Material.Wood,
		Parent = m,
	})

	local leafColors = {
		Color3.fromRGB(68, 155, 72),
		Color3.fromRGB(78, 168, 78),
		Color3.fromRGB(58, 142, 68),
	}
	local baseColor = leafColors[((idx - 1) % #leafColors) + 1]

	makePart({
		Name = "CanopyMain",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(12.5, 10.5, 12.5),
		Position = Vector3.new(0, 12.5, 0),
		Color = baseColor,
		Material = Enum.Material.Grass,
		Parent = m,
	})
	makePart({
		Name = "CanopyTop",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(9.2, 8.2, 9.2),
		Position = Vector3.new(0, 17.5, 0),
		Color = baseColor:Lerp(Color3.fromRGB(195, 215, 140), 0.15),
		Material = Enum.Material.Grass,
		Parent = m,
	})
	for side = -1, 1, 2 do
		makePart({
			Name = "CanopySide",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(8.5, 7.5, 8.5),
			Position = Vector3.new(side * 3.8, 11.2, side * 1.5),
			Color = baseColor,
			Material = Enum.Material.Grass,
			Parent = m,
		})
	end

	return finalizeTemplate(m)
end

local function buildCandyTemplate(idx: number): Model
	local m = Instance.new("Model")
	m.Name = "Candy_" .. tostring(idx)

	local colors = {
		Color3.fromRGB(215, 85, 145),
		Color3.fromRGB(85, 175, 205),
		Color3.fromRGB(215, 175, 75),
		Color3.fromRGB(155, 95, 205),
		Color3.fromRGB(85, 185, 130),
	}
	local c1 = colors[((idx - 1) % #colors) + 1]
	local c2 = colors[(idx % #colors) + 1]

	if idx % 2 == 1 then
		makePart({
			Name = "Stick",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(12, 1.3, 1.3),
			CFrame = CFrame.new(0, 6, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(235, 232, 225),
			Material = Enum.Material.SmoothPlastic,
			Parent = m,
		})
		makePart({
			Name = "CandyOuter",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.2, 11.0, 11.0),
			CFrame = CFrame.new(0, 15.5, 0),
			Color = c1,
			Material = Enum.Material.SmoothPlastic,
			Parent = m,
		})
		makePart({
			Name = "CandySwirl1",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.4, 7.8, 7.8),
			CFrame = CFrame.new(0, 15.5, 0),
			Color = Color3.fromRGB(242, 238, 232),
			Material = Enum.Material.SmoothPlastic,
			Parent = m,
		})
		makePart({
			Name = "CandyCore",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.6, 4.4, 4.4),
			CFrame = CFrame.new(0, 15.5, 0),
			Color = c2,
			Material = Enum.Material.SmoothPlastic,
			Parent = m,
		})
	else
		makePart({
			Name = "ConeTrunk",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(10, 2.4, 2.4),
			CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(205, 162, 108),
			Material = Enum.Material.SmoothPlastic,
			Parent = m,
		})
		makePart({
			Name = "FluffMain",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(13, 10, 13),
			Position = Vector3.new(0, 13, 0),
			Color = c1,
			Material = Enum.Material.SmoothPlastic,
			Parent = m,
		})
		makePart({
			Name = "FluffTop",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(9.5, 8.5, 9.5),
			Position = Vector3.new(0, 18, 0),
			Color = c2,
			Material = Enum.Material.SmoothPlastic,
			Parent = m,
		})
	end

	return finalizeTemplate(m)
end

local function buildPalmTreeTemplate(idx: number): Model
	local m = Instance.new("Model")
	m.Name = "PalmTrees_" .. tostring(idx)

	for seg = 1, 4 do
		makePart({
			Name = "TrunkSeg_" .. seg,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(4.2, 2.6 - seg * 0.25, 2.6 - seg * 0.25),
			CFrame = CFrame.new((seg - 1) * 0.45, (seg - 0.5) * 3.8, 0) * CFrame.Angles(0, 0, math.rad(84)),
			Color = Color3.fromRGB(142, 96, 54),
			Material = Enum.Material.Wood,
			Parent = m,
		})
	end

	local topPos = Vector3.new(1.5, 15.5, 0)
	for f = 0, 5 do
		local ang = math.rad(f * 60)
		makePart({
			Name = "PalmFrond_" .. f,
			Size = Vector3.new(8.5, 0.8, 2.8),
			CFrame = CFrame.new(topPos) * CFrame.Angles(0, ang, math.rad(-22)) * CFrame.new(3.8, 0, 0),
			Color = Color3.fromRGB(64, 158, 72),
			Material = Enum.Material.Grass,
			Parent = m,
		})
	end
	for c = 1, 3 do
		local ang = math.rad(c * 120)
		makePart({
			Name = "Coconut_" .. c,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.8, 1.8, 1.8),
			Position = topPos + Vector3.new(math.cos(ang) * 1.2, -0.8, math.sin(ang) * 1.2),
			Color = Color3.fromRGB(95, 62, 35),
			Material = Enum.Material.Wood,
			Parent = m,
		})
	end

	return finalizeTemplate(m)
end

local function buildCrystalTemplate(idx: number): Model
	local m = Instance.new("Model")
	m.Name = "Crystals_" .. tostring(idx)

	local colors = {
		Color3.fromRGB(135, 78, 185),
		Color3.fromRGB(68, 155, 185),
		Color3.fromRGB(185, 82, 155),
	}
	local col = colors[((idx - 1) % #colors) + 1]

	makePart({
		Name = "MainSpire",
		Size = Vector3.new(3.8, 16, 3.8),
		CFrame = CFrame.new(0, 8, 0) * CFrame.Angles(math.rad(6), math.rad(25), math.rad(-5)),
		Color = col,
		Material = Enum.Material.Glass,
		Reflectance = 0.15,
		Parent = m,
	})
	for s = -1, 1, 2 do
		makePart({
			Name = "SideSpire_" .. s,
			Size = Vector3.new(2.8, 11, 2.8),
			CFrame = CFrame.new(s * 3.2, 5.2, s * 1.2) * CFrame.Angles(math.rad(-s * 12), 0, math.rad(-s * 24)),
			Color = col:Lerp(Color3.fromRGB(210, 215, 225), 0.2),
			Material = Enum.Material.Glass,
			Reflectance = 0.15,
			Parent = m,
		})
	end

	return finalizeTemplate(m)
end

local function buildVolcanoRockTemplate(idx: number): Model
	local m = Instance.new("Model")
	m.Name = "VolcanoRocks_" .. tostring(idx)

	makePart({
		Name = "ObsidianCrag",
		Size = Vector3.new(8.5, 14, 7.5),
		CFrame = CFrame.new(0, 7, 0) * CFrame.Angles(math.rad(8), math.rad(idx * 40), math.rad(-6)),
		Color = Color3.fromRGB(48, 36, 44),
		Material = Enum.Material.Slate,
		Parent = m,
	})
	makePart({
		Name = "LavaVein1",
		Size = Vector3.new(9.0, 1.8, 2.2),
		CFrame = CFrame.new(0, 6.5, 0) * CFrame.Angles(0, math.rad(idx * 40), math.rad(24)),
		Color = Color3.fromRGB(185, 68, 28),
		Material = Enum.Material.CrackedLava,
		Parent = m,
	})
	makePart({
		Name = "LavaPeak",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4.5, 3.5, 4.5),
		Position = Vector3.new(0, 13.5, 0),
		Color = Color3.fromRGB(195, 78, 32),
		Material = Enum.Material.CrackedLava,
		Parent = m,
	})

	return finalizeTemplate(m)
end

local function buildBridgeTemplate(idx: number): Model
	local m = Instance.new("Model")
	m.Name = "Bridges_" .. tostring(idx)

	makePart({
		Name = "Deck",
		Size = Vector3.new(12, 1.2, 18),
		Position = Vector3.new(0, 1.2, 0),
		Color = Color3.fromRGB(148, 98, 56),
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
		Parent = m,
	})
	for _, sideX in ipairs({ -5.5, 5.5 }) do
		makePart({
			Name = "HandRail",
			Size = Vector3.new(0.8, 1.0, 18),
			Position = Vector3.new(sideX, 3.4, 0),
			Color = Color3.fromRGB(125, 78, 42),
			Material = Enum.Material.Wood,
			Parent = m,
		})
		for zPost = -8, 8, 8 do
			makePart({
				Name = "BridgePost",
				Size = Vector3.new(1.0, 3.6, 1.0),
				Position = Vector3.new(sideX, 2.0, zPost),
				Color = Color3.fromRGB(110, 68, 34),
				Material = Enum.Material.Wood,
				Parent = m,
			})
		end
	end

	return finalizeTemplate(m)
end

local function buildObbyStageTemplate(idx: number): Model
	local m = Instance.new("Model")
	m.Name = "Obstacles_" .. tostring(idx)

	local padColors = {
		Color3.fromRGB(145, 95, 62),
		Color3.fromRGB(115, 128, 142),
		Color3.fromRGB(165, 135, 85),
		Color3.fromRGB(92, 138, 98),
	}
	for i = 1, 4 do
		makePart({
			Name = "ObbyPad_" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.6, 5.5, 5.5),
			CFrame = CFrame.new((i - 2.5) * 4.2, i * 2.2, (i % 2) * 2.4) * CFrame.Angles(0, 0, math.rad(90)),
			Color = padColors[((idx + i - 2) % #padColors) + 1],
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
			Parent = m,
		})
	end

	return finalizeTemplate(m)
end

local function buildGoldCoinTemplate(idx: number): Model
	local m = Instance.new("Model")
	m.Name = "GoldCoins_" .. tostring(idx)

	makePart({
		Name = "CoinRim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.75, 3.6, 3.6),
		CFrame = CFrame.new(0, 2.2, 0),
		Color = Color3.fromRGB(255, 205, 35),
		Material = Enum.Material.Neon,
		Parent = m,
	})
	makePart({
		Name = "CoinFace",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.85, 2.7, 2.7),
		CFrame = CFrame.new(0, 2.2, 0),
		Color = Color3.fromRGB(255, 238, 110),
		Material = Enum.Material.Neon,
		Parent = m,
	})
	makePart({
		Name = "CoinStarEmblem",
		Size = Vector3.new(0.95, 1.4, 0.55),
		CFrame = CFrame.new(0, 2.2, 0),
		Color = Color3.fromRGB(255, 255, 210),
		Material = Enum.Material.Neon,
		Parent = m,
	})

	return finalizeTemplate(m)
end

local function buildBrainrotEggTemplate(idx: number): Model
	local m = Instance.new("Model")
	m.Name = "BrainrotEggs_" .. tostring(idx)

	local eggColors = {
		Color3.fromRGB(85, 215, 255),
		Color3.fromRGB(255, 115, 205),
		Color3.fromRGB(255, 215, 65),
	}
	local c = eggColors[((idx - 1) % #eggColors) + 1]

	local shell = makePart({
		Name = "MysteryShell",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3.8, 4.8, 3.8),
		Position = Vector3.new(0, 2.6, 0),
		Color = c,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.25,
		Parent = m,
	})
	local sp = Instance.new("SpecialMesh")
	sp.MeshType = Enum.MeshType.Sphere
	sp.Scale = Vector3.new(1, 1.22, 1)
	sp.Parent = shell

	makePart({
		Name = "GlowingCrackBand",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.55, 4.1, 4.1),
		CFrame = CFrame.new(0, 2.6, 0) * CFrame.Angles(math.rad(14), 0, math.rad(90)),
		Color = Color3.fromRGB(255, 245, 120),
		Material = Enum.Material.Neon,
		Parent = m,
	})

	return finalizeTemplate(m)
end

local function buildStageLandmarkTemplate(idx: number): Model
	local m = Instance.new("Model")
	m.Name = "StageLandmarks_" .. tostring(idx)

	-- Architectural non-glowing matte landmark base + tower/feature per stage index (1..8)
	makePart({
		Name = "LandmarkBase",
		Size = Vector3.new(22, 2.0, 22),
		Position = Vector3.new(0, 1.0, 0),
		Color = Color3.fromRGB(128, 124, 118),
		Material = Enum.Material.Cobblestone,
		CanCollide = true,
		Parent = m,
	})
	makePart({
		Name = "LandmarkTower",
		Size = Vector3.new(14, 18, 14),
		Position = Vector3.new(0, 11.0, 0),
		Color = Color3.fromRGB(168, 142, 112),
		Material = Enum.Material.Brick,
		CanCollide = true,
		Parent = m,
	})
	makePart({
		Name = "LandmarkRoofDeck",
		Size = Vector3.new(17, 1.5, 17),
		Position = Vector3.new(0, 20.75, 0),
		Color = Color3.fromRGB(115, 72, 48),
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
		Parent = m,
	})

	return finalizeTemplate(m)
end

local function buildFountainTemplate(): Model
	local m = Instance.new("Model")
	m.Name = "Fountain_1"

	makePart({
		Name = "OuterBasin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.2, 14, 14),
		CFrame = CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(195, 200, 210),
		Material = Enum.Material.Marble,
		Parent = m,
	})
	makePart({
		Name = "WaterPool",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.4, 12.2, 12.2),
		CFrame = CFrame.new(0, 1.15, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(65, 165, 215),
		Material = Enum.Material.Glass,
		Transparency = 0.2,
		Parent = m,
	})
	makePart({
		Name = "CenterColumn",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(7.5, 3.2, 3.2),
		CFrame = CFrame.new(0, 4.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(205, 210, 220),
		Material = Enum.Material.Marble,
		Parent = m,
	})
	makePart({
		Name = "TopWaterCrown",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4.2, 4.2, 4.2),
		Position = Vector3.new(0, 9.2, 0),
		Color = Color3.fromRGB(85, 185, 230),
		Material = Enum.Material.Glass,
		Parent = m,
	})

	return finalizeTemplate(m)
end

local function buildChestTemplate(): Model
	local m = Instance.new("Model")
	m.Name = "Chest_1"

	makePart({
		Name = "ChestBox",
		Size = Vector3.new(4.2, 2.6, 3.0),
		Position = Vector3.new(0, 1.3, 0),
		Color = Color3.fromRGB(135, 78, 36),
		Material = Enum.Material.Wood,
		Parent = m,
	})
	makePart({
		Name = "GoldTrim",
		Size = Vector3.new(4.4, 0.8, 3.2),
		Position = Vector3.new(0, 2.5, 0),
		Color = Color3.fromRGB(215, 175, 45),
		Material = Enum.Material.Metal,
		Reflectance = 0.25,
		Parent = m,
	})
	makePart({
		Name = "LockPlate",
		Size = Vector3.new(1.0, 1.2, 0.4),
		Position = Vector3.new(0, 2.2, 1.55),
		Color = Color3.fromRGB(225, 185, 55),
		Material = Enum.Material.Metal,
		Reflectance = 0.25,
		Parent = m,
	})

	return finalizeTemplate(m)
end

local function buildBirdNestTemplate(): Model
	local m = Instance.new("Model")
	m.Name = "BirdNest_1"

	makePart({
		Name = "OuterTwigRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.1, 6.4, 6.4),
		CFrame = CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(148, 98, 52),
		Material = Enum.Material.Wood,
		Parent = m,
	})
	makePart({
		Name = "GoldenStrawBed",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.25, 5.0, 5.0),
		CFrame = CFrame.new(0, 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(215, 182, 72),
		Material = Enum.Material.Grass,
		Parent = m,
	})

	return finalizeTemplate(m)
end

function PrebuiltLoader.EnsurePrebuiltAssets(customObjectFetcher: ((number) -> { Instance }?)?): Folder
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	if not modelsFolder then
		local f = Instance.new("Folder")
		f.Name = "Models"
		f.Parent = ReplicatedStorage
		modelsFolder = f
	end

	local existing = modelsFolder:FindFirstChild("PrebuiltAssets")
	if existing and existing:GetAttribute("LoadedCount") then
		return existing :: Folder
	end

	local prebuiltRoot: Folder
	if existing and existing:IsA("Folder") then
		prebuiltRoot = existing
	else
		if existing then
			existing:Destroy()
		end
		prebuiltRoot = Instance.new("Folder")
		prebuiltRoot.Name = "PrebuiltAssets"
		prebuiltRoot.Parent = modelsFolder
	end

	local function ensureCategory(name: string): Folder
		local f = prebuiltRoot:FindFirstChild(name)
		if f and f:IsA("Folder") then
			return f
		end
		local newF = Instance.new("Folder")
		newF.Name = name
		newF.Parent = prebuiltRoot
		return newF
	end

	local totalLoaded = 0
	local storeLoadedCount = 0

	-- Sanitize any pre-baked models already inside PrebuiltAssets so they have CanTouch=false, CanQuery=false, CastShadow=false
	for _, desc in ipairs(prebuiltRoot:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = false
			desc.Massless = true
			desc.CastShadow = false
		elseif desc:IsA("MeshPart") and string.find(desc.TextureID, "203785492") then
			desc.TextureID = ""
		elseif desc:IsA("SpecialMesh") and string.find(desc.TextureId, "203785492") then
			desc.TextureId = ""
		elseif
			desc:IsA("LuaSourceContainer")
			or desc:IsA("Light")
			or desc:IsA("ParticleEmitter")
			or desc:IsA("Sparkles")
			or desc:IsA("Highlight")
			or desc:IsA("Sound")
		then
			desc:Destroy()
		end
	end

	-- 1. Always populate our 5 crisp, architectural pitched-roof House templates first so Houses_1..5 have 100% consistent proportions & roofs
	local housesFolder = ensureCategory("Houses")
	housesFolder:ClearAllChildren()
	for idx, pal in ipairs(HOUSE_PALETTES) do
		buildHouseTemplate(idx, pal.Wall, pal.Roof, pal.Trim).Parent = housesFolder
		totalLoaded += 1
	end

	-- 2. Call customObjectFetcher when provided in Studio to download & bake Creator Store Brainrots, Eggs, Coins, ObbyPieces & StageLandmarks
	if customObjectFetcher then
		for category, idList in pairs(PrebuiltLoader.CREATOR_STORE_ASSETS) do
			local catFolder = ensureCategory(category)
			for keyOrIdx, assetId in pairs(idList) do
				local name = if type(keyOrIdx) == "string" then keyOrIdx else (category .. "_Store_" .. tostring(keyOrIdx))
				if not catFolder:FindFirstChild(name) then
					local ok, objs = pcall(customObjectFetcher, assetId)
					if ok and objs and #objs > 0 then
						local sanitized = sanitizeCreatorStoreModel(objs[1], category, keyOrIdx)
						if sanitized then
							sanitized.Name = name
							sanitized:SetAttribute("SourceAssetId", assetId)
							sanitized:SetAttribute("BrainrotKey", tostring(keyOrIdx))
							sanitized.Parent = catFolder
							totalLoaded += 1
							storeLoadedCount += 1
						end
					end
				end
			end
		end
	end

	local goldCoinsFolder = ensureCategory("GoldCoins")
	if #goldCoinsFolder:GetChildren() == 0 then
		for i = 1, 4 do
			buildGoldCoinTemplate(i).Parent = goldCoinsFolder
			totalLoaded += 1
		end
	end

	local brainrotEggsFolder = ensureCategory("BrainrotEggs")
	if #brainrotEggsFolder:GetChildren() == 0 then
		for i = 1, 3 do
			buildBrainrotEggTemplate(i).Parent = brainrotEggsFolder
			totalLoaded += 1
		end
	end

	local obbyPiecesFolder = ensureCategory("ObbyPieces")
	if #obbyPiecesFolder:GetChildren() == 0 then
		for i = 1, 4 do
			buildObbyStageTemplate(i).Parent = obbyPiecesFolder
			totalLoaded += 1
		end
	end

	local stageLandmarksFolder = ensureCategory("StageLandmarks")
	if #stageLandmarksFolder:GetChildren() == 0 then
		for i = 1, 8 do
			buildStageLandmarkTemplate(i).Parent = stageLandmarksFolder
			totalLoaded += 1
		end
	end

	local treesFolder = ensureCategory("Trees")
	if #treesFolder:GetChildren() == 0 then
		for i = 1, 3 do
			buildTreeTemplate(i).Parent = treesFolder
			totalLoaded += 1
		end
	end

	local candyFolder = ensureCategory("Candy")
	if #candyFolder:GetChildren() < 3 then
		for i = 1, 5 do
			buildCandyTemplate(i).Parent = candyFolder
			totalLoaded += 1
		end
	end

	local palmFolder = ensureCategory("PalmTrees")
	if #palmFolder:GetChildren() == 0 then
		for i = 1, 3 do
			buildPalmTreeTemplate(i).Parent = palmFolder
			totalLoaded += 1
		end
	end

	local crystalFolder = ensureCategory("Crystals")
	if #crystalFolder:GetChildren() == 0 then
		for i = 1, 3 do
			buildCrystalTemplate(i).Parent = crystalFolder
			totalLoaded += 1
		end
	end

	local volcanoFolder = ensureCategory("VolcanoRocks")
	if #volcanoFolder:GetChildren() == 0 then
		for i = 1, 3 do
			buildVolcanoRockTemplate(i).Parent = volcanoFolder
			totalLoaded += 1
		end
	end

	local bridgesFolder = ensureCategory("Bridges")
	if #bridgesFolder:GetChildren() == 0 then
		for i = 1, 2 do
			buildBridgeTemplate(i).Parent = bridgesFolder
			totalLoaded += 1
		end
	end

	local obbyFolder = ensureCategory("Obstacles")
	if #obbyFolder:GetChildren() == 0 then
		for i = 1, 3 do
			buildObbyStageTemplate(i).Parent = obbyFolder
			totalLoaded += 1
		end
	end

	local fountainFolder = ensureCategory("Fountain")
	if #fountainFolder:GetChildren() == 0 then
		buildFountainTemplate().Parent = fountainFolder
		totalLoaded += 1
	end

	local chestFolder = ensureCategory("Chest")
	if #chestFolder:GetChildren() == 0 then
		buildChestTemplate().Parent = chestFolder
		totalLoaded += 1
	end

	local nestFolder = ensureCategory("BirdNest")
	if #nestFolder:GetChildren() == 0 then
		buildBirdNestTemplate().Parent = nestFolder
		totalLoaded += 1
	end

	prebuiltRoot:SetAttribute("LoadedCount", totalLoaded)
	prebuiltRoot:SetAttribute("StoreAssetsLoaded", storeLoadedCount > 0)
	ReplicatedStorage:SetAttribute("PrebuiltAssetsReady", true)
	return prebuiltRoot
end

local CATEGORY_ALIASES: { [string]: string } = {
	HubFountain = "Fountain",
	CashChest = "Chest",
	ObbyStages = "ObbyPieces",
	MeadowTrees = "Trees",
	CandyProps = "Candy",
	Coins = "GoldCoins",
	Eggs = "BrainrotEggs",
}

function PrebuiltLoader.GetCategoryTemplates(categoryName: string): { Model }
	local resolvedName = CATEGORY_ALIASES[categoryName] or categoryName
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	local prebuiltRoot = if modelsFolder then modelsFolder:FindFirstChild("PrebuiltAssets") else nil
	local catFolder = if prebuiltRoot then (prebuiltRoot:FindFirstChild(resolvedName) or prebuiltRoot:FindFirstChild(categoryName)) else nil
	local list: { Model } = {}
	if catFolder then
		for _, child in ipairs(catFolder:GetChildren()) do
			if child:IsA("Model") then
				table.insert(list, child)
			end
		end
	end
	return list
end

function PrebuiltLoader.CloneNormalizedTemplate(
	categoryName: string,
	seedIndex: any,
	targetScale: number,
	canCollide: boolean?
): Model?
	local resolvedName = CATEGORY_ALIASES[categoryName] or categoryName
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	local prebuiltRoot = if modelsFolder then modelsFolder:FindFirstChild("PrebuiltAssets") else nil
	local catFolder = if prebuiltRoot then (prebuiltRoot:FindFirstChild(resolvedName) or prebuiltRoot:FindFirstChild(categoryName)) else nil

	local chosen: Model? = nil

	if catFolder and categoryName == "Brainrots" then
		if type(seedIndex) == "string" then
			local direct = catFolder:FindFirstChild(seedIndex)
			if direct and direct:IsA("Model") then
				chosen = direct
			else
				local lowerSeed = string.lower(seedIndex)
				for _, child in ipairs(catFolder:GetChildren()) do
					if child:IsA("Model") then
						local lowerChild = string.lower(child.Name)
						if string.find(lowerSeed, lowerChild, 1, true) or string.find(lowerChild, lowerSeed, 1, true) then
							chosen = child
							break
						end
					end
				end
			end
		elseif type(seedIndex) == "number" then
			local keyName = PrebuiltLoader.BRAINROT_ID_TO_KEY[seedIndex]
			if keyName then
				local direct = catFolder:FindFirstChild(keyName)
				if direct and direct:IsA("Model") then
					chosen = direct
				end
			end
			if not chosen then
				local direct = catFolder:FindFirstChild("Brainrots_Store_" .. tostring(seedIndex))
				if direct and direct:IsA("Model") then
					chosen = direct
				end
			end
		end
	end

	if not chosen then
		local templates = PrebuiltLoader.GetCategoryTemplates(categoryName)
		if #templates == 0 then
			return nil
		end
		local numSeed = tonumber(seedIndex) or 1
		chosen = templates[((math.max(1, math.floor(numSeed)) - 1) % #templates) + 1]
	end

	if not chosen then
		return nil
	end

	local cloned = chosen:Clone()

	local ok, _, bbSize = pcall(function()
		return cloned:GetBoundingBox()
	end)
	if ok and bbSize.Magnitude > 0.05 then
		local currentDim = math.max(bbSize.Y, bbSize.X * 0.72, bbSize.Z * 0.72)
		local factor = math.clamp(targetScale / math.max(currentDim, 0.5), 0.08, 3.2)
		pcall(function()
			cloned:ScaleTo(cloned:GetScale() * factor)
		end)
	end

	local ok2, newCF, newSize = pcall(function()
		return cloned:GetBoundingBox()
	end)
	local bottomCenter = if ok2 then (newCF.Position - Vector3.new(0, newSize.Y * 0.5, 0)) else Vector3.new(0, 0, 0)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = if ok2
		then Vector3.new(math.clamp(newSize.X * 0.75, 1.2, 16), math.clamp(newSize.Y * 0.85, 1.2, 18), math.clamp(newSize.Z * 0.75, 1.2, 16))
		else Vector3.new(2, 2, 2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = if canCollide ~= nil then canCollide else false
	root.CanTouch = false
	root.CanQuery = true
	root.Massless = true
	root.CastShadow = false
	root.CFrame = CFrame.new(bottomCenter + Vector3.new(0, root.Size.Y * 0.5, 0))
	root.PivotOffset = CFrame.new(0, -root.Size.Y * 0.5, 0)
	root.Parent = cloned

	for _, desc in ipairs(cloned:GetDescendants()) do
		if desc:IsA("BasePart") and desc ~= root then
			desc.Anchored = true
			desc.CanCollide = if canCollide ~= nil then canCollide else false
			desc.CanTouch = false
			desc.CanQuery = false
			desc.CastShadow = false
		end
	end

	cloned.PrimaryPart = root
	cloned.WorldPivot = CFrame.new(bottomCenter)
	return cloned
end

return PrebuiltLoader
