--!strict
-- SquishyBuilder.luau
-- Procedural 3D Model Factory for World Eggs, Hatched Squishies, Player Morphs, and Animal/Brainrot Chaser Guardians!

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
	if props.CFrame then
		part.CFrame = props.CFrame
	elseif props.Position then
		part.Position = props.Position
	end
	if props.Name then
		part.Name = props.Name
	end
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

local function addFaceToBody(body: BasePart, model: Model, radiusZ: number, eyeScale: number?)
	local scale = eyeScale or 1.0
	local center = body.CFrame

	local leftEye = makePart({
		Name = "LeftEye",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(20, 20, 30),
		Size = Vector3.new(0.55 * scale, 0.65 * scale, 0.35 * scale),
		CFrame = center * CFrame.new(-0.75 * scale, 0.35 * scale, -radiusZ + 0.1),
		Parent = model,
	})
	local rightEye = makePart({
		Name = "RightEye",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(20, 20, 30),
		Size = Vector3.new(0.55 * scale, 0.65 * scale, 0.35 * scale),
		CFrame = center * CFrame.new(0.75 * scale, 0.35 * scale, -radiusZ + 0.1),
		Parent = model,
	})
	local leftSparkle = makePart({
		Name = "LeftSparkle",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 255, 255),
		Size = Vector3.new(0.22 * scale, 0.22 * scale, 0.22 * scale),
		CFrame = leftEye.CFrame * CFrame.new(-0.1 * scale, 0.14 * scale, -0.12 * scale),
		Parent = model,
	})
	local rightSparkle = makePart({
		Name = "RightSparkle",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 255, 255),
		Size = Vector3.new(0.22 * scale, 0.22 * scale, 0.22 * scale),
		CFrame = rightEye.CFrame * CFrame.new(-0.1 * scale, 0.14 * scale, -0.12 * scale),
		Parent = model,
	})
	local leftBlush = makePart({
		Name = "LeftBlush",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 115, 165),
		Transparency = 0.2,
		Size = Vector3.new(0.18 * scale, 0.55 * scale, 0.35 * scale),
		CFrame = center * CFrame.new(-1.15 * scale, -0.05 * scale, -radiusZ + 0.15) * CFrame.Angles(0, math.rad(90), 0),
		Parent = model,
	})
	local rightBlush = makePart({
		Name = "RightBlush",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 115, 165),
		Transparency = 0.2,
		Size = Vector3.new(0.18 * scale, 0.55 * scale, 0.35 * scale),
		CFrame = center * CFrame.new(1.15 * scale, -0.05 * scale, -radiusZ + 0.15) * CFrame.Angles(0, math.rad(90), 0),
		Parent = model,
	})
	local smile = makePart({
		Name = "Smile",
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(30, 20, 35),
		Size = Vector3.new(0.65 * scale, 0.2 * scale, 0.2 * scale),
		CFrame = center * CFrame.new(0, -0.25 * scale, -radiusZ + 0.08),
		Parent = model,
	})
	return { leftEye, rightEye, leftSparkle, rightSparkle, leftBlush, rightBlush, smile }
end

local function addHatToBody(body: BasePart, model: Model, hatType: string, secondaryColor: Color3, topY: number)
	local center = body.CFrame
	if hatType == "Crown" then
		makePart({
			Name = "HatCrown",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 215, 55),
			Size = Vector3.new(0.9, 1.8, 1.8),
			CFrame = center * CFrame.new(0, topY + 0.35, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		})
	elseif hatType == "Halo" then
		makePart({
			Name = "HatHalo",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 250, 140),
			Size = Vector3.new(0.28, 2.4, 2.4),
			CFrame = center * CFrame.new(0, topY + 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		})
	elseif hatType == "Sprout" or hatType == "Flower" then
		makePart({
			Name = "HatStem",
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(70, 195, 85),
			Size = Vector3.new(0.3, 0.9, 0.3),
			CFrame = center * CFrame.new(0, topY + 0.4, 0),
			Parent = model,
		})
		makePart({
			Name = "HatPetal",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = secondaryColor,
			Size = Vector3.new(1.1, 0.5, 1.1),
			CFrame = center * CFrame.new(0, topY + 0.85, 0),
			Parent = model,
		})
	elseif hatType == "Horns" or hatType == "Antlers" then
		makePart({
			Name = "LeftHorn",
			Material = Enum.Material.Neon,
			Color = secondaryColor,
			Size = Vector3.new(0.4, 1.1, 0.4),
			CFrame = center * CFrame.new(-0.85, topY + 0.35, 0) * CFrame.Angles(0, 0, math.rad(25)),
			Parent = model,
		})
		makePart({
			Name = "RightHorn",
			Material = Enum.Material.Neon,
			Color = secondaryColor,
			Size = Vector3.new(0.4, 1.1, 0.4),
			CFrame = center * CFrame.new(0.85, topY + 0.35, 0) * CFrame.Angles(0, 0, math.rad(-25)),
			Parent = model,
		})
	elseif hatType == "Propeller" then
		makePart({
			Name = "Cap",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = secondaryColor,
			Size = Vector3.new(1.5, 0.7, 1.5),
			CFrame = center * CFrame.new(0, topY + 0.2, 0),
			Parent = model,
		})
		makePart({
			Name = "Blade",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 235, 65),
			Size = Vector3.new(2.2, 0.15, 0.35),
			CFrame = center * CFrame.new(0, topY + 0.65, 0),
			Parent = model,
		})
	else
		makePart({
			Name = "WizardCone",
			Material = Enum.Material.SmoothPlastic,
			Color = secondaryColor,
			Size = Vector3.new(1.3, 1.4, 1.3),
			CFrame = center * CFrame.new(0, topY + 0.5, 0),
			Parent = model,
		})
	end
end

-- Creates a World Egg to be hunted, picked up, and planted in the player's Pen
function SquishyBuilder.CreateWorldEgg(slimeDef: SlimeData.SlimeDef, anchored: boolean?): Model
	local isAnchored = if anchored ~= nil then anchored else true
	local model = Instance.new("Model")
	model.Name = "Egg_" .. tostring(slimeDef.Id)
	model:SetAttribute("SlimeId", slimeDef.Id)
	model:SetAttribute("Level", slimeDef.Level)
	model:SetAttribute("Behavior", slimeDef.Behavior)
	model:SetAttribute("BounceCount", 0)

	local scale = if slimeDef.IsBoss then 1.35 else 1.0
	local eggSize = Vector3.new(3.2 * scale, 4.2 * scale, 3.2 * scale)

	local shell = makePart({
		Name = "EggShell",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = slimeDef.Color,
		Size = eggSize,
		Position = slimeDef.Position,
		Anchored = isAnchored,
		CanCollide = false,
		Parent = model,
	})
	-- Make it egg-shaped with a SpecialMesh
	local eggMesh = Instance.new("SpecialMesh")
	eggMesh.MeshType = Enum.MeshType.Sphere
	eggMesh.Scale = Vector3.new(1.0, 1.28, 1.0)
	eggMesh.Parent = shell

	model.PrimaryPart = shell

	-- Decorative glowing Egg Spots
	local spotOffsets = {
		CFrame.new(0.85 * scale, 0.7 * scale, -1.1 * scale),
		CFrame.new(-0.9 * scale, -0.3 * scale, -1.1 * scale),
		CFrame.new(0.2 * scale, 1.2 * scale, 1.0 * scale),
		CFrame.new(-0.7 * scale, 0.5 * scale, 1.05 * scale),
		CFrame.new(0.85 * scale, -0.5 * scale, 0.9 * scale),
	}
	for idx, offset in ipairs(spotOffsets) do
		local spot = makePart({
			Name = "EggSpot_" .. idx,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = slimeDef.SecondaryColor,
			Size = Vector3.new(0.75 * scale, 0.75 * scale, 0.45 * scale),
			CFrame = shell.CFrame * offset,
			Anchored = isAnchored,
			Parent = model,
		})
		if not isAnchored then
			weldTo(shell, spot)
		end
	end

	-- Cute peeking eyes on the Egg
	local faceParts = addFaceToBody(shell, model, 1.55 * scale, 0.95 * scale)
	if not isAnchored then
		for _, fp in ipairs(faceParts) do
			fp.Anchored = false
			weldTo(shell, fp)
		end
	end

	-- Optional Disguise Shell for Disguised Eggs
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
			Size = Vector3.new(4.6, 4.6, 4.6),
			Shape = if slimeDef.DisguiseProp == "Bush" then Enum.PartType.Ball else Enum.PartType.Block,
			CFrame = shell.CFrame,
			Transparency = 0.05,
			Parent = model,
		})
		disguise:SetAttribute("IsDisguise", true)
	end

	-- Billboard Label over World Egg
	local bb = Instance.new("BillboardGui")
	bb.Name = "EggTag"
	bb.Size = UDim2.new(0, 200, 0, 72)
	bb.StudsOffset = Vector3.new(0, 3.6 * scale, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 75
	bb.Parent = shell

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = slimeDef.Color
	title.TextStrokeTransparency = 0.15
	title.Text = "🥚 " .. slimeDef.Name .. " Egg"
	title.Parent = bb

	local sub = Instance.new("TextLabel")
	sub.Name = "SubLabel"
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = SlimeData.RarityColors[slimeDef.Rarity] or Color3.fromRGB(255, 255, 255)
	sub.TextStrokeTransparency = 0.2
	local behaviorNote = if slimeDef.Behavior == "BounceWake"
		then " [😴 Bounce 3x!]"
		elseif slimeDef.Behavior == "Runaway" then " [🏃 Fast!]"
		elseif slimeDef.Behavior == "Disguised" then " [🫣 Sneaky!]"
		else ""
	sub.Text = string.format("[%s] $%d/s%s", slimeDef.Rarity, slimeDef.CoinsPerSec, behaviorNote)
	sub.Parent = bb

	return model
end

-- Creates a Hatched Bouncing Squishy Slime inside the player's Base Pen
function SquishyBuilder.CreateHatchedSquishy(slimeDef: SlimeData.SlimeDef, position: Vector3, gelTier: number?): Model
	local tier = gelTier or 1
	local model = Instance.new("Model")
	model.Name = "Squishy_" .. tostring(slimeDef.Id)
	model:SetAttribute("SlimeId", slimeDef.Id)

	local scale = if slimeDef.IsBoss then 1.25 else 1.0
	local radius = 2.0 * scale

	local outerColor = if tier == 2
		then Color3.fromRGB(255, 215, 55)
		elseif tier >= 3 then Color3.fromHSV((slimeDef.Id * 0.11) % 1, 0.85, 1)
		else slimeDef.Color

	-- Outer squishy translucent jelly body
	local body = makePart({
		Name = "JellyBody",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = outerColor,
		Transparency = 0.18,
		Size = Vector3.new(radius * 2, radius * 1.85, radius * 2),
		Position = position,
		Parent = model,
	})
	model.PrimaryPart = body

	-- Glowing inner core
	makePart({
		Name = "NeonCore",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = slimeDef.SecondaryColor,
		Transparency = 0.25,
		Size = Vector3.new(radius * 1.15, radius * 1.05, radius * 1.15),
		Position = position,
		Parent = model,
	})

	addFaceToBody(body, model, radius * 0.96, scale)
	addHatToBody(body, model, slimeDef.HatType, slimeDef.SecondaryColor, radius * 0.88)

	local bb = Instance.new("BillboardGui")
	bb.Name = "SquishyTag"
	bb.Size = UDim2.new(0, 190, 0, 64)
	bb.StudsOffset = Vector3.new(0, radius + 1.8, 0)
	bb.MaxDistance = 65
	bb.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = outerColor
	nameLabel.TextStrokeTransparency = 0.15
	nameLabel.Text = "✨ " .. slimeDef.Name
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
	rateLabel.Text = string.format("+$%d/sec (Click to Squish!)", slimeDef.CoinsPerSec)
	rateLabel.Parent = bb

	return model
end

-- Creates a 3D Animal or Brainrot Chaser Guardian that patrols a level and chases Egg carriers!
function SquishyBuilder.CreateGuardianModel(guardianDef: SlimeData.GuardianDef): Model
	local model = Instance.new("Model")
	model.Name = "Guardian_" .. guardianDef.Id
	model:SetAttribute("GuardianId", guardianDef.Id)
	model:SetAttribute("Level", guardianDef.Level)

	local pos = guardianDef.HomePosition

	local torso = makePart({
		Name = "Body",
		Material = Enum.Material.SmoothPlastic,
		Color = guardianDef.PrimaryColor,
		Size = Vector3.new(5.5, 5.5, 6.5),
		Position = pos,
		Parent = model,
	})
	model.PrimaryPart = torso

	-- Belly / Accent plate
	makePart({
		Name = "AccentBelly",
		Material = Enum.Material.Neon,
		Color = guardianDef.AccentColor,
		Size = Vector3.new(4.2, 3.8, 6.6),
		CFrame = torso.CFrame * CFrame.new(0, -0.3, 0),
		Parent = model,
	})

	-- Fierce glowing eyes
	makePart({
		Name = "LeftEye",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 55, 55),
		Size = Vector3.new(1.1, 1.1, 0.6),
		CFrame = torso.CFrame * CFrame.new(-1.3, 1.2, -3.2),
		Parent = model,
	})
	makePart({
		Name = "RightEye",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 55, 55),
		Size = Vector3.new(1.1, 1.1, 0.6),
		CFrame = torso.CFrame * CFrame.new(1.3, 1.2, -3.2),
		Parent = model,
	})

	-- Style-specific features (Shark Fin + Sneakers for Tralalero, Bat for Tung Tung, Ears for Bear, Horns for Dragon)
	if guardianDef.Style == "Shark" then
		makePart({
			Name = "DorsalFin",
			Material = Enum.Material.SmoothPlastic,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(0.8, 3.2, 3.0),
			CFrame = torso.CFrame * CFrame.new(0, 3.8, 0.5) * CFrame.Angles(math.rad(-20), 0, 0),
			Parent = model,
		})
		-- Blue/White Brainrot Sneakers!
		makePart({
			Name = "LeftSneaker",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(65, 195, 255),
			Size = Vector3.new(1.8, 1.2, 3.2),
			CFrame = torso.CFrame * CFrame.new(-1.8, -3.1, -0.5),
			Parent = model,
		})
		makePart({
			Name = "RightSneaker",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(65, 195, 255),
			Size = Vector3.new(1.8, 1.2, 3.2),
			CFrame = torso.CFrame * CFrame.new(1.8, -3.1, -0.5),
			Parent = model,
		})
	elseif guardianDef.Style == "BrainrotBat" then
		makePart({
			Name = "WoodenClub",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Wood,
			Color = Color3.fromRGB(165, 105, 55),
			Size = Vector3.new(6.0, 1.4, 1.4),
			CFrame = torso.CFrame * CFrame.new(3.4, 1.0, -1.5) * CFrame.Angles(0, 0, math.rad(65)),
			Parent = model,
		})
	elseif guardianDef.Style == "Bear" then
		makePart({
			Name = "LeftEar",
			Shape = Enum.PartType.Ball,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(1.8, 1.8, 1.2),
			CFrame = torso.CFrame * CFrame.new(-2.1, 3.0, -1.0),
			Parent = model,
		})
		makePart({
			Name = "RightEar",
			Shape = Enum.PartType.Ball,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(1.8, 1.8, 1.2),
			CFrame = torso.CFrame * CFrame.new(2.1, 3.0, -1.0),
			Parent = model,
		})
	else
		makePart({
			Name = "BackSpikes",
			Material = Enum.Material.Neon,
			Color = guardianDef.AccentColor,
			Size = Vector3.new(1.2, 2.6, 4.8),
			CFrame = torso.CFrame * CFrame.new(0, 3.5, 0),
			Parent = model,
		})
	end

	-- Overhead Status Tag
	local bb = Instance.new("BillboardGui")
	bb.Name = "GuardianTag"
	bb.Size = UDim2.new(0, 240, 0, 82)
	bb.StudsOffset = Vector3.new(0, 5.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	bb.Parent = torso

	local title = Instance.new("TextLabel")
	title.Name = "NameLabel"
	title.Size = UDim2.new(1, 0, 0.52, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 215, 75)
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

	-- Handle Tiny Squishy Mode (allows squeezing into 3.5-stud Micro-Vents!)
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

	local morphScale = if tinyMode then 0.48 else 1.05
	local costume = Instance.new("Model")
	costume.Name = "SquishyMorphCostume"
	costume.Parent = character

	local shell = makePart({
		Name = "MorphShell",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = slimeDef.Color,
		Transparency = 0.15,
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
		Transparency = 0.3,
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
