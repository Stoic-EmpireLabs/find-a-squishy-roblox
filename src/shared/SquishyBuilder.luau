--!strict
-- SquishyBuilder.luau
-- High-Detail Procedural 3D Model Factory for World Eggs, Hatched Squishies,
-- Multi-Limb Animal/Brainrot Chaser Guardians, and Player Morphs!

local SlimeData = require(script.Parent.SlimeData)

local SquishyBuilder = {}

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = if props.Anchored ~= nil then props.Anchored else true
	part.CanCollide = if props.CanCollide ~= nil then props.CanCollide else false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = props.Material or Enum.Material.SmoothPlastic
	part.Color = props.Color or Color3.fromRGB(255, 255, 255)
	part.Size = props.Size or Vector3.new(2, 2, 2)
	if props.Shape then
		part.Shape = props.Shape
	end
	if props.Transparency then
		part.Transparency = props.Transparency
	end
	if props.Reflectance then
		part.Reflectance = props.Reflectance
	end
	if props.CFrame then
		part.CFrame = props.CFrame
	elseif props.Position then
		part.Position = props.Position
	end
	part.Name = props.Name or "Part"
	if props.Parent then
		part.Parent = props.Parent
	end
	return part
end

local function weldTo(part0: BasePart, part1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part1
end

local function addRarityParticles(parentPart: BasePart, color1: Color3, color2: Color3, rate: number)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "RaritySparkles"
	pe.Color = ColorSequence.new(color1, color2)
	pe.LightEmission = 0.9
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.5, 0.65),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Rate = rate
	pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = parentPart
end

local function addFaceToBody(body: BasePart, model: Model, radiusZ: number, eyeScale: number?)
	local scale = eyeScale or 1.0
	local center = body.CFrame

	local leftEye = makePart({
		Name = "LeftEye",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(18, 18, 28),
		Size = Vector3.new(0.62 * scale, 0.72 * scale, 0.38 * scale),
		CFrame = center * CFrame.new(-0.78 * scale, 0.35 * scale, -radiusZ + 0.08),
		Parent = model,
	})
	local rightEye = makePart({
		Name = "RightEye",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(18, 18, 28),
		Size = Vector3.new(0.62 * scale, 0.72 * scale, 0.38 * scale),
		CFrame = center * CFrame.new(0.78 * scale, 0.35 * scale, -radiusZ + 0.08),
		Parent = model,
	})
	local leftSparkle = makePart({
		Name = "LeftSparkle",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 255, 255),
		Size = Vector3.new(0.25 * scale, 0.25 * scale, 0.25 * scale),
		CFrame = leftEye.CFrame * CFrame.new(-0.11 * scale, 0.15 * scale, -0.13 * scale),
		Parent = model,
	})
	local rightSparkle = makePart({
		Name = "RightSparkle",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 255, 255),
		Size = Vector3.new(0.25 * scale, 0.25 * scale, 0.25 * scale),
		CFrame = rightEye.CFrame * CFrame.new(-0.11 * scale, 0.15 * scale, -0.13 * scale),
		Parent = model,
	})
	local leftBlush = makePart({
		Name = "LeftBlush",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 105, 165),
		Transparency = 0.15,
		Size = Vector3.new(0.55 * scale, 0.32 * scale, 0.25 * scale),
		CFrame = center * CFrame.new(-1.18 * scale, -0.05 * scale, -radiusZ + 0.14),
		Parent = model,
	})
	local rightBlush = makePart({
		Name = "RightBlush",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 105, 165),
		Transparency = 0.15,
		Size = Vector3.new(0.55 * scale, 0.32 * scale, 0.25 * scale),
		CFrame = center * CFrame.new(1.18 * scale, -0.05 * scale, -radiusZ + 0.14),
		Parent = model,
	})
	local smile = makePart({
		Name = "Smile",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 130, 175),
		Size = Vector3.new(0.55 * scale, 0.32 * scale, 0.22 * scale),
		CFrame = center * CFrame.new(0, -0.26 * scale, -radiusZ + 0.08),
		Parent = model,
	})
	return { leftEye, rightEye, leftSparkle, rightSparkle, leftBlush, rightBlush, smile }
end

local function addHatToBody(body: BasePart, model: Model, hatType: string, secondaryColor: Color3, topY: number)
	local center = body.CFrame
	if hatType == "Crown" then
		makePart({
			Name = "HatCrownBase",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 215, 45),
			Size = Vector3.new(0.95, 2.0, 2.0),
			CFrame = center * CFrame.new(0, topY + 0.35, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		})
		for i = 0, 3 do
			local angle = math.rad(i * 90)
			makePart({
				Name = "CrownGem_" .. i,
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 65, 125),
				Size = Vector3.new(0.45, 0.45, 0.45),
				CFrame = center * CFrame.new(math.cos(angle) * 0.95, topY + 0.85, math.sin(angle) * 0.95),
				Parent = model,
			})
		end
	elseif hatType == "Halo" then
		makePart({
			Name = "HatHalo",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 245, 125),
			Size = Vector3.new(0.32, 2.6, 2.6),
			CFrame = center * CFrame.new(0, topY + 1.0, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		})
	elseif hatType == "Sprout" or hatType == "Flower" then
		makePart({
			Name = "HatStem",
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(70, 200, 85),
			Size = Vector3.new(0.32, 1.1, 0.32),
			CFrame = center * CFrame.new(0, topY + 0.45, 0),
			Parent = model,
		})
		makePart({
			Name = "LeafL",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = secondaryColor,
			Size = Vector3.new(1.1, 0.4, 0.65),
			CFrame = center * CFrame.new(-0.5, topY + 0.95, 0) * CFrame.Angles(0, 0, math.rad(22)),
			Parent = model,
		})
		makePart({
			Name = "LeafR",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = secondaryColor,
			Size = Vector3.new(1.1, 0.4, 0.65),
			CFrame = center * CFrame.new(0.5, topY + 0.95, 0) * CFrame.Angles(0, 0, math.rad(-22)),
			Parent = model,
		})
	elseif hatType == "Horns" or hatType == "Antlers" then
		makePart({
			Name = "LeftHorn",
			Material = Enum.Material.Neon,
			Color = secondaryColor,
			Size = Vector3.new(0.45, 1.35, 0.45),
			CFrame = center * CFrame.new(-0.9, topY + 0.45, 0) * CFrame.Angles(0, 0, math.rad(28)),
			Parent = model,
		})
		makePart({
			Name = "RightHorn",
			Material = Enum.Material.Neon,
			Color = secondaryColor,
			Size = Vector3.new(0.45, 1.35, 0.45),
			CFrame = center * CFrame.new(0.9, topY + 0.45, 0) * CFrame.Angles(0, 0, math.rad(-28)),
			Parent = model,
		})
	elseif hatType == "Propeller" then
		makePart({
			Name = "Cap",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = secondaryColor,
			Size = Vector3.new(1.6, 0.75, 1.6),
			CFrame = center * CFrame.new(0, topY + 0.2, 0),
			Parent = model,
		})
		makePart({
			Name = "Blade",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 235, 65),
			Size = Vector3.new(2.5, 0.18, 0.4),
			CFrame = center * CFrame.new(0, topY + 0.7, 0),
			Parent = model,
		})
	else
		makePart({
			Name = "HatBrim",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.SmoothPlastic,
			Color = secondaryColor,
			Size = Vector3.new(0.25, 2.5, 2.5),
			CFrame = center * CFrame.new(0, topY + 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		})
		makePart({
			Name = "WizardCone",
			Material = Enum.Material.Neon,
			Color = secondaryColor,
			Size = Vector3.new(1.3, 1.6, 1.3),
			CFrame = center * CFrame.new(0, topY + 0.9, 0),
			Parent = model,
		})
	end
end

-- Creates a World Egg with glowing Nest Ring, Rarity Sparkles, and Short-Range Tooltip
function SquishyBuilder.CreateWorldEgg(slimeDef: SlimeData.SlimeDef, anchored: boolean?): Model
	local isAnchored = if anchored ~= nil then anchored else true
	local model = Instance.new("Model")
	model.Name = "Egg_" .. tostring(slimeDef.Id)
	model:SetAttribute("SlimeId", slimeDef.Id)
	model:SetAttribute("Level", slimeDef.Level)
	model:SetAttribute("Behavior", slimeDef.Behavior)
	model:SetAttribute("BounceCount", 0)

	local scale = if slimeDef.IsBoss then 1.45 else 1.15
	local eggSize = Vector3.new(3.4 * scale, 4.4 * scale, 3.4 * scale)

	local shell = makePart({
		Name = "EggShell",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.15,
		Color = slimeDef.Color,
		Size = eggSize,
		Position = slimeDef.Position,
		Anchored = isAnchored,
		CanCollide = false,
		Parent = model,
	})
	local eggMesh = Instance.new("SpecialMesh")
	eggMesh.MeshType = Enum.MeshType.Sphere
	eggMesh.Scale = Vector3.new(1.0, 1.28, 1.0)
	eggMesh.Parent = shell

	model.PrimaryPart = shell

	-- Glowing Halo Ring at the base of the Egg so it looks like a polished collectible!
	if isAnchored then
		makePart({
			Name = "EggPedestalRing",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = slimeDef.SecondaryColor,
			Size = Vector3.new(0.45, 4.8 * scale, 4.8 * scale),
			CFrame = CFrame.new(slimeDef.Position - Vector3.new(0, 1.9 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Anchored = true,
			CanCollide = false,
			Parent = model,
		})
	end

	-- Add Rarity Sparkles
	addRarityParticles(shell, slimeDef.Color, slimeDef.SecondaryColor, if slimeDef.IsBoss then 18 else 8)

	-- Decorative glowing Egg Spots
	local spotOffsets = {
		CFrame.new(0.95 * scale, 0.75 * scale, -1.18 * scale),
		CFrame.new(-0.98 * scale, -0.35 * scale, -1.18 * scale),
		CFrame.new(0.25 * scale, 1.25 * scale, 1.08 * scale),
		CFrame.new(-0.78 * scale, 0.55 * scale, 1.12 * scale),
		CFrame.new(0.92 * scale, -0.55 * scale, 0.98 * scale),
	}
	for idx, offset in ipairs(spotOffsets) do
		local spot = makePart({
			Name = "EggSpot_" .. idx,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = slimeDef.SecondaryColor,
			Size = Vector3.new(0.82 * scale, 0.82 * scale, 0.48 * scale),
			CFrame = shell.CFrame * offset,
			Anchored = isAnchored,
			Parent = model,
		})
		if not isAnchored then
			weldTo(shell, spot)
		end
	end

	local faceParts = addFaceToBody(shell, model, 1.62 * scale, 1.0 * scale)
	if not isAnchored then
		for _, fp in ipairs(faceParts) do
			fp.Anchored = false
			weldTo(shell, fp)
		end
	end

	if slimeDef.Behavior == "Disguised" and isAnchored then
		local disguise = makePart({
			Name = "DisguiseShell",
			Material = if slimeDef.DisguiseProp == "Bush"
				then Enum.Material.Grass
				elseif slimeDef.DisguiseProp == "LavaRock" then Enum.Material.Slate
				else Enum.Material.SmoothPlastic,
			Color = if slimeDef.DisguiseProp == "Bush"
				then Color3.fromRGB(65, 165, 75)
				elseif slimeDef.DisguiseProp == "Marshmallow" then Color3.fromRGB(250, 245, 250)
				elseif slimeDef.DisguiseProp == "CyberCrate" then Color3.fromRGB(45, 60, 95)
				elseif slimeDef.DisguiseProp == "LavaRock" then Color3.fromRGB(70, 50, 55)
				else Color3.fromRGB(235, 95, 75),
			Size = Vector3.new(5.4, 5.4, 5.4),
			Shape = if slimeDef.DisguiseProp == "Bush" then Enum.PartType.Ball else Enum.PartType.Block,
			CFrame = shell.CFrame,
			Transparency = 0.04,
			Parent = model,
		})
		disguise:SetAttribute("IsDisguise", true)
	end

	-- Clean Short-Range Billboard Tag (MaxDistance = 42 so it never clutters the distant screen!)
	local bb = Instance.new("BillboardGui")
	bb.Name = "EggTag"
	bb.Size = UDim2.new(0, 180, 0, 58)
	bb.StudsOffset = Vector3.new(0, 3.8 * scale, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 42
	bb.Parent = shell

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = slimeDef.Color
	title.TextStrokeTransparency = 0.1
	title.Text = "🥚 " .. slimeDef.Name
	title.Parent = bb

	local sub = Instance.new("TextLabel")
	sub.Name = "SubLabel"
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = SlimeData.RarityColors[slimeDef.Rarity] or Color3.fromRGB(255, 255, 255)
	sub.TextStrokeTransparency = 0.15
	local behaviorNote = if slimeDef.Behavior == "BounceWake"
		then " [Jump 3x!]"
		elseif slimeDef.Behavior == "Runaway" then " [Fast!]"
		elseif slimeDef.Behavior == "Disguised" then " [Disguised!]"
		else ""
	sub.Text = string.format("%s • +$%d/s%s", slimeDef.Rarity, slimeDef.CoinsPerSec, behaviorNote)
	sub.Parent = bb

	return model
end

-- Creates a Hatched Bouncing Squishy Slime inside the player's Base Pen
function SquishyBuilder.CreateHatchedSquishy(slimeDef: SlimeData.SlimeDef, position: Vector3, gelTier: number?): Model
	local tier = gelTier or 1
	local model = Instance.new("Model")
	model.Name = "Squishy_" .. tostring(slimeDef.Id)
	model:SetAttribute("SlimeId", slimeDef.Id)

	local scale = if slimeDef.IsBoss then 1.3 else 1.05
	local radius = 2.1 * scale

	local outerColor = if tier == 2
		then Color3.fromRGB(255, 215, 55)
		elseif tier >= 3 then Color3.fromHSV((slimeDef.Id * 0.11) % 1, 0.85, 1)
		else slimeDef.Color

	local body = makePart({
		Name = "JellyBody",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = if tier >= 2 then 0.25 else 0.1,
		Color = outerColor,
		Transparency = 0.14,
		Size = Vector3.new(radius * 2, radius * 1.82, radius * 2),
		Position = position,
		Parent = model,
	})
	model.PrimaryPart = body

	makePart({
		Name = "NeonCore",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = slimeDef.SecondaryColor,
		Transparency = 0.22,
		Size = Vector3.new(radius * 1.18, radius * 1.08, radius * 1.18),
		Position = position,
		Parent = model,
	})

	addRarityParticles(body, outerColor, slimeDef.SecondaryColor, if tier >= 2 then 10 else 4)
	addFaceToBody(body, model, radius * 0.96, scale)
	addHatToBody(body, model, slimeDef.HatType, slimeDef.SecondaryColor, radius * 0.88)

	local bb = Instance.new("BillboardGui")
	bb.Name = "SquishyTag"
	bb.Size = UDim2.new(0, 155, 0, 48)
	bb.StudsOffset = Vector3.new(0, radius + 1.8, 0)
	bb.MaxDistance = 28 -- Only visible when inside or near the Pen!
	bb.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = outerColor
	nameLabel.TextStrokeTransparency = 0.15
	nameLabel.Text = slimeDef.Name
	nameLabel.Parent = bb

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Size = UDim2.new(1, 0, 0.45, 0)
	rateLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.TextScaled = true
	rateLabel.TextColor3 = Color3.fromRGB(110, 255, 130)
	rateLabel.TextStrokeTransparency = 0.2
	rateLabel.Text = string.format("+$%d/s (Click!)", slimeDef.CoinsPerSec)
	rateLabel.Parent = bb

	return model
end

-- Creates a Rich Multi-Part 3D Animal or Brainrot Chaser Guardian!
function SquishyBuilder.CreateGuardianModel(guardianDef: SlimeData.GuardianDef): Model
	local model = Instance.new("Model")
	model.Name = "Guardian_" .. guardianDef.Id
	model:SetAttribute("GuardianId", guardianDef.Id)
	model:SetAttribute("Level", guardianDef.Level)

	local pos = guardianDef.HomePosition

	-- Main Torso
	local torso = makePart({
		Name = "Body",
		Material = Enum.Material.SmoothPlastic,
		Color = guardianDef.PrimaryColor,
		Size = Vector3.new(6.2, 6.4, 7.2),
		Position = pos + Vector3.new(0, 2.2, 0),
		Parent = model,
	})
	model.PrimaryPart = torso

	-- Glowing Belly Plate
	makePart({
		Name = "AccentBelly",
		Material = Enum.Material.Neon,
		Color = guardianDef.AccentColor,
		Size = Vector3.new(4.6, 4.4, 7.3),
		CFrame = torso.CFrame * CFrame.new(0, -0.35, 0),
		Parent = model,
	})

	-- Upper Head & Snout/Jaw
	local head = makePart({
		Name = "Head",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = guardianDef.PrimaryColor,
		Size = Vector3.new(5.8, 5.2, 5.8),
		CFrame = torso.CFrame * CFrame.new(0, 3.8, -1.6),
		Parent = model,
	})
	makePart({
		Name = "SnoutJaw",
		Material = Enum.Material.SmoothPlastic,
		Color = guardianDef.AccentColor,
		Size = Vector3.new(4.2, 2.2, 3.6),
		CFrame = head.CFrame * CFrame.new(0, -0.8, -2.2),
		Parent = model,
	})
	-- Sharp White Cartoon Teeth
	for t = -1, 1 do
		makePart({
			Name = "Tooth_" .. t,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 255, 255),
			Size = Vector3.new(0.7, 0.9, 0.5),
			CFrame = head.CFrame * CFrame.new(t * 1.15, -1.4, -3.7),
			Parent = model,
		})
	end

	-- Fierce Glowing Eyes & Angry Brow
	makePart({
		Name = "LeftEye",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 45, 45),
		Size = Vector3.new(1.25, 1.25, 0.7),
		CFrame = head.CFrame * CFrame.new(-1.35, 0.85, -2.5),
		Parent = model,
	})
	makePart({
		Name = "RightEye",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 45, 45),
		Size = Vector3.new(1.25, 1.25, 0.7),
		CFrame = head.CFrame * CFrame.new(1.35, 0.85, -2.5),
		Parent = model,
	})

	-- Chunky 3D Legs & Giant Sneakers/Claws
	makePart({
		Name = "LeftLeg",
		Material = Enum.Material.SmoothPlastic,
		Color = guardianDef.PrimaryColor,
		Size = Vector3.new(2.2, 3.2, 2.4),
		CFrame = torso.CFrame * CFrame.new(-2.0, -4.0, 0),
		Parent = model,
	})
	makePart({
		Name = "RightLeg",
		Material = Enum.Material.SmoothPlastic,
		Color = guardianDef.PrimaryColor,
		Size = Vector3.new(2.2, 3.2, 2.4),
		CFrame = torso.CFrame * CFrame.new(2.0, -4.0, 0),
		Parent = model,
	})
	makePart({
		Name = "LeftFootSneaker",
		Material = Enum.Material.Neon,
		Color = if guardianDef.Style == "Shark" then Color3.fromRGB(55, 185, 255) else guardianDef.AccentColor,
		Size = Vector3.new(2.6, 1.4, 4.0),
		CFrame = torso.CFrame * CFrame.new(-2.0, -5.6, -0.8),
		Parent = model,
	})
	makePart({
		Name = "RightFootSneaker",
		Material = Enum.Material.Neon,
		Color = if guardianDef.Style == "Shark" then Color3.fromRGB(55, 185, 255) else guardianDef.AccentColor,
		Size = Vector3.new(2.6, 1.4, 4.0),
		CFrame = torso.CFrame * CFrame.new(2.0, -5.6, -0.8),
		Parent = model,
	})

	-- Style-Specific Accessories (Shark Dorsal Fin & Tail, Tung Tung Wooden Bat, Dragon Wings, Bear Ears)
	if guardianDef.Style == "Shark" then
		makePart({
			Name = "DorsalFin",
			Material = Enum.Material.SmoothPlastic,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(1.0, 4.2, 3.6),
			CFrame = torso.CFrame * CFrame.new(0, 4.2, 1.2) * CFrame.Angles(math.rad(-25), 0, 0),
			Parent = model,
		})
		makePart({
			Name = "SharkTail",
			Material = Enum.Material.SmoothPlastic,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(1.2, 4.5, 3.2),
			CFrame = torso.CFrame * CFrame.new(0, 0.5, 4.8) * CFrame.Angles(math.rad(20), 0, 0),
			Parent = model,
		})
	elseif guardianDef.Style == "BrainrotBat" then
		makePart({
			Name = "RightArm",
			Material = Enum.Material.SmoothPlastic,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(1.8, 4.2, 1.8),
			CFrame = torso.CFrame * CFrame.new(3.8, 0.5, -1.0) * CFrame.Angles(math.rad(45), 0, 0),
			Parent = model,
		})
		makePart({
			Name = "WoodenClub",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Wood,
			Color = Color3.fromRGB(165, 105, 50),
			Size = Vector3.new(7.5, 1.8, 1.8),
			CFrame = torso.CFrame * CFrame.new(4.2, 2.5, -3.2) * CFrame.Angles(0, 0, math.rad(72)),
			Parent = model,
		})
	elseif guardianDef.Style == "Dragon" then
		makePart({
			Name = "LeftWing",
			Material = Enum.Material.Neon,
			Color = guardianDef.AccentColor,
			Size = Vector3.new(7.5, 4.2, 0.6),
			CFrame = torso.CFrame * CFrame.new(-6.0, 2.2, 1.0) * CFrame.Angles(0, math.rad(20), math.rad(18)),
			Parent = model,
		})
		makePart({
			Name = "RightWing",
			Material = Enum.Material.Neon,
			Color = guardianDef.AccentColor,
			Size = Vector3.new(7.5, 4.2, 0.6),
			CFrame = torso.CFrame * CFrame.new(6.0, 2.2, 1.0) * CFrame.Angles(0, math.rad(-20), math.rad(-18)),
			Parent = model,
		})
	else
		makePart({
			Name = "LeftEar",
			Shape = Enum.PartType.Ball,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(2.2, 2.2, 1.4),
			CFrame = head.CFrame * CFrame.new(-2.2, 2.2, 0),
			Parent = model,
		})
		makePart({
			Name = "RightEar",
			Shape = Enum.PartType.Ball,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(2.2, 2.2, 1.4),
			CFrame = head.CFrame * CFrame.new(2.2, 2.2, 0),
			Parent = model,
		})
	end

	addRarityParticles(torso, guardianDef.PrimaryColor, guardianDef.AccentColor, 12)

	-- Overhead Status Tag (MaxDistance = 85 so it's readable in your current level without cluttering the Hub)
	local bb = Instance.new("BillboardGui")
	bb.Name = "GuardianTag"
	bb.Size = UDim2.new(0, 220, 0, 70)
	bb.StudsOffset = Vector3.new(0, 7.6, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 85
	bb.Parent = torso

	local title = Instance.new("TextLabel")
	title.Name = "NameLabel"
	title.Size = UDim2.new(1, 0, 0.52, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 220, 65)
	title.TextStrokeTransparency = 0.1
	title.Text = guardianDef.Title .. ": " .. guardianDef.Name
	title.Parent = bb

	local status = Instance.new("TextLabel")
	status.Name = "StatusLabel"
	status.Size = UDim2.new(1, 0, 0.48, 0)
	status.Position = UDim2.new(0, 0, 0.52, 0)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.GothamBold
	status.TextScaled = true
	status.TextColor3 = Color3.fromRGB(255, 255, 255)
	status.TextStrokeTransparency = 0.15
	local reqSpd = guardianDef.RequiredSpeedPower or 800
	local reqStr = if reqSpd >= 1_000_000
		then string.format("%.1fM", reqSpd / 1_000_000)
		elseif reqSpd >= 1_000 then string.format("%.1fK", reqSpd / 1_000)
		else tostring(reqSpd)
	status.Text = string.format("😴 Guarding Eggs (Speed Power: %s)", reqStr)
	status.Parent = bb

	return model
end

-- Attaches a Squishy Morph shell + Tiny Size toggle to a player's character
function SquishyBuilder.ApplyCharacterMorph(character: Model, slimeDef: SlimeData.SlimeDef?, tinyMode: boolean)
	local existing = character:FindFirstChild("SquishyMorphCostume")
	if existing then
		existing:Destroy()
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return
	end

	character:SetAttribute("IsTinySquishy", tinyMode)
	for _, inst in ipairs(character:GetDescendants()) do
		if inst:IsA("BasePart") and inst.Name ~= "HumanoidRootPart" then
			if slimeDef ~= nil then
				inst.Transparency = 0.85
				inst.CanCollide = false
			else
				if inst.Name == "Head" or string.find(inst.Name, "Torso") or string.find(inst.Name, "Arm") or string.find(inst.Name, "Leg") or string.find(inst.Name, "Hand") or string.find(inst.Name, "Foot") then
					inst.Transparency = 0
				end
			end
		end
	end

	if not slimeDef then
		humanoid.HipHeight = 2
		return
	end

	local morphScale = if tinyMode then 0.45 else 1.1
	local costume = Instance.new("Model")
	costume.Name = "SquishyMorphCostume"
	costume.Parent = character

	local shell = makePart({
		Name = "MorphShell",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = slimeDef.Color,
		Transparency = 0.14,
		Size = Vector3.new(3.8 * morphScale, 3.5 * morphScale, 3.8 * morphScale),
		CFrame = hrp.CFrame * CFrame.new(0, if tinyMode then -1.1 else 0, 0),
		Anchored = false,
		CanCollide = false,
		Parent = costume,
	})
	weldTo(hrp, shell)

	local core = makePart({
		Name = "MorphCore",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = slimeDef.SecondaryColor,
		Transparency = 0.28,
		Size = Vector3.new(2.2 * morphScale, 2.0 * morphScale, 2.2 * morphScale),
		CFrame = shell.CFrame,
		Anchored = false,
		CanCollide = false,
		Parent = costume,
	})
	weldTo(shell, core)

	local faceParts = addFaceToBody(shell, costume, 1.85 * morphScale, morphScale)
	for _, fp in ipairs(faceParts) do
		fp.Anchored = false
		weldTo(shell, fp)
	end
end

return SquishyBuilder
