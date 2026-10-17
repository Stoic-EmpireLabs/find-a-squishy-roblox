--!strict
-- SquishyBuilder.luau
-- High-Detail Procedural 3D Model Factory for Ornate Saturn-Ringed Eggs,
-- Planted Countdown Eggs, Backpack Squishy Tools, Species-Sculpted Squishy Dumplings,
-- and Colossal Sleeping/Chasing Monster Bosses!

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
	part.Massless = true
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

local function formatNumber(n: number): string
	if n >= 1_000_000 then
		return string.format("%.1fM", n / 1_000_000)
	elseif n >= 1_000 then
		return string.format("%.1fK", n / 1_000)
	else
		return tostring(math.floor(n))
	end
end

local function addRarityParticles(parentPart: BasePart, color1: Color3, color2: Color3, rate: number)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "RaritySparkles"
	pe.Color = ColorSequence.new(color1, color2)
	pe.LightEmission = 0.95
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.5, 0.75),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(0.8, 1.5)
	pe.Rate = rate
	pe.Speed = NumberRange.new(2, 6)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = parentPart
end

-- Adds a rich Kawaii Squishmallow / Dumpling face with glossy black eyes, double white shine highlights, pink blush, and snout/mouth
local function addFaceToBody(body: BasePart, model: Instance, radiusZ: number, eyeScale: number?, anchored: boolean?): { BasePart }
	local isAnchored = if anchored ~= nil then anchored else true
	local scale = eyeScale or 1.0
	local center = body.CFrame
	local parts: { BasePart } = {}

	local function addFacialPart(p: Part)
		p.Anchored = isAnchored
		if not isAnchored then
			weldTo(body, p)
		end
		table.insert(parts, p)
		return p
	end

	local leftEye = addFacialPart(makePart({
		Name = "LeftEye",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.25,
		Color = Color3.fromRGB(15, 15, 24),
		Size = Vector3.new(0.68 * scale, 0.78 * scale, 0.42 * scale),
		CFrame = center * CFrame.new(-0.82 * scale, 0.32 * scale, -radiusZ + 0.08),
		Parent = model,
	}))
	local rightEye = addFacialPart(makePart({
		Name = "RightEye",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.25,
		Color = Color3.fromRGB(15, 15, 24),
		Size = Vector3.new(0.68 * scale, 0.78 * scale, 0.42 * scale),
		CFrame = center * CFrame.new(0.82 * scale, 0.32 * scale, -radiusZ + 0.08),
		Parent = model,
	}))
	-- Primary upper-left shine dot
	addFacialPart(makePart({
		Name = "LeftSparkleBig",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 255, 255),
		Size = Vector3.new(0.26 * scale, 0.26 * scale, 0.24 * scale),
		CFrame = leftEye.CFrame * CFrame.new(-0.12 * scale, 0.16 * scale, -0.14 * scale),
		Parent = model,
	}))
	addFacialPart(makePart({
		Name = "RightSparkleBig",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 255, 255),
		Size = Vector3.new(0.26 * scale, 0.26 * scale, 0.24 * scale),
		CFrame = rightEye.CFrame * CFrame.new(-0.12 * scale, 0.16 * scale, -0.14 * scale),
		Parent = model,
	}))
	-- Secondary lower-right shine dot for extra kawaii depth
	addFacialPart(makePart({
		Name = "LeftSparkleSmall",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 255, 255),
		Size = Vector3.new(0.14 * scale, 0.14 * scale, 0.14 * scale),
		CFrame = leftEye.CFrame * CFrame.new(0.12 * scale, -0.14 * scale, -0.14 * scale),
		Parent = model,
	}))
	addFacialPart(makePart({
		Name = "RightSparkleSmall",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 255, 255),
		Size = Vector3.new(0.14 * scale, 0.14 * scale, 0.14 * scale),
		CFrame = rightEye.CFrame * CFrame.new(0.12 * scale, -0.14 * scale, -0.14 * scale),
		Parent = model,
	}))
	-- Rosy kawaii cheek blush ovals
	addFacialPart(makePart({
		Name = "LeftBlush",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 95, 160),
		Transparency = 0.1,
		Size = Vector3.new(0.65 * scale, 0.36 * scale, 0.26 * scale),
		CFrame = center * CFrame.new(-1.22 * scale, -0.06 * scale, -radiusZ + 0.14),
		Parent = model,
	}))
	addFacialPart(makePart({
		Name = "RightBlush",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 95, 160),
		Transparency = 0.1,
		Size = Vector3.new(0.65 * scale, 0.36 * scale, 0.26 * scale),
		CFrame = center * CFrame.new(1.22 * scale, -0.06 * scale, -radiusZ + 0.14),
		Parent = model,
	}))
	-- Cute cat/dumpling mouth ("w" twin curves)
	addFacialPart(makePart({
		Name = "SmileL",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 120, 175),
		Size = Vector3.new(0.36 * scale, 0.24 * scale, 0.22 * scale),
		CFrame = center * CFrame.new(-0.14 * scale, -0.22 * scale, -radiusZ + 0.08),
		Parent = model,
	}))
	addFacialPart(makePart({
		Name = "SmileR",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 120, 175),
		Size = Vector3.new(0.36 * scale, 0.24 * scale, 0.22 * scale),
		CFrame = center * CFrame.new(0.14 * scale, -0.22 * scale, -radiusZ + 0.08),
		Parent = model,
	}))
	return parts
end

-- Adds Species-Specific 3D Squishy Dumpling / Squishmallow Anatomy (Pleated Dumpling Crest, Cow Ears/Horns, Axolotl Gills, Boba Straw, Cat Ears, Dragon Wings, Stubby Paws)
local function addSpeciesFeatures(
	body: BasePart,
	model: Instance,
	slimeDef: SlimeData.SlimeDef,
	radius: number,
	scale: number,
	anchored: boolean
)
	local center = body.CFrame
	local species = slimeDef.Species or "Cow"

	local function attach(p: Part): Part
		p.Anchored = anchored
		if not anchored then
			weldTo(body, p)
		end
		return p
	end

	-- 1. Cute Stubby Kawaii Front Paws & Feet + Soft Belly Patch
	attach(makePart({
		Name = "BellyPatch",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(255, 250, 245),
		Size = Vector3.new(radius * 1.35, radius * 1.15, radius * 0.45),
		CFrame = center * CFrame.new(0, -radius * 0.22, -radius * 0.82),
		Parent = model,
	}))
	for side = -1, 1, 2 do
		attach(makePart({
			Name = "FrontPaw_" .. side,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = slimeDef.SecondaryColor,
			Size = Vector3.new(0.65 * scale, 0.55 * scale, 0.75 * scale),
			CFrame = center * CFrame.new(side * radius * 0.68, -radius * 0.62, -radius * 0.65),
			Parent = model,
		}))
	end

	-- 2. Pleated Squishy Dumpling Top Folds (signature look from Steal an Egg for Squishy Dumplings!)
	for i = 0, 5 do
		local ang = math.rad(i * 60)
		attach(makePart({
			Name = "DumplingPleat_" .. i,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = slimeDef.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.25),
			Size = Vector3.new(0.85 * scale, 0.48 * scale, 0.52 * scale),
			CFrame = center
				* CFrame.new(math.cos(ang) * (0.55 * scale), radius * 0.82, math.sin(ang) * (0.55 * scale))
				* CFrame.Angles(0, -ang, math.rad(20)),
			Parent = model,
		}))
	end

	-- 3. Species-Specific Ears, Horns, Gills, Wings, or Boba Straw
	if species == "Cow" then
		for side = -1, 1, 2 do
			attach(makePart({
				Name = "CowHorn_" .. side,
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 230, 140),
				Size = Vector3.new(0.42 * scale, 0.95 * scale, 0.42 * scale),
				CFrame = center * CFrame.new(side * radius * 0.55, radius * 0.85, 0) * CFrame.Angles(0, 0, math.rad(-side * 22)),
				Parent = model,
			}))
			attach(makePart({
				Name = "CowEar_" .. side,
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.SmoothPlastic,
				Color = slimeDef.SecondaryColor,
				Size = Vector3.new(0.95 * scale, 0.45 * scale, 0.45 * scale),
				CFrame = center * CFrame.new(side * radius * 0.92, radius * 0.48, 0) * CFrame.Angles(0, 0, math.rad(side * 18)),
				Parent = model,
			}))
		end
	elseif species == "Axolotl" then
		for side = -1, 1, 2 do
			for g = -1, 1 do
				attach(makePart({
					Name = "AxolotlGill_" .. side .. "_" .. g,
					Shape = Enum.PartType.Ball,
					Material = Enum.Material.Neon,
					Color = slimeDef.SecondaryColor,
					Size = Vector3.new(1.15 * scale, 0.38 * scale, 0.35 * scale),
					CFrame = center
						* CFrame.new(side * radius * 0.98, (0.28 + g * 0.34) * scale, 0)
						* CFrame.Angles(0, 0, math.rad(-side * g * 24)),
					Parent = model,
				}))
			end
		end
	elseif species == "Boba" then
		attach(makePart({
			Name = "BobaStraw",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = slimeDef.SecondaryColor,
			Size = Vector3.new(1.8 * scale, 0.52 * scale, 0.52 * scale),
			CFrame = center * CFrame.new(0.25 * scale, radius * 1.05, 0) * CFrame.Angles(math.rad(12), 0, math.rad(82)),
			Parent = model,
		}))
		for p = 1, 4 do
			attach(makePart({
				Name = "TapiocaPearl_" .. p,
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.SmoothPlastic,
				Color = Color3.fromRGB(35, 22, 18),
				Size = Vector3.new(0.48 * scale, 0.48 * scale, 0.48 * scale),
				CFrame = center * CFrame.new((p - 2.5) * 0.55 * scale, -radius * 0.55, -radius * 0.72),
				Parent = model,
			}))
		end
	elseif species == "Dragon" then
		for side = -1, 1, 2 do
			attach(makePart({
				Name = "DragonWing_" .. side,
				Material = Enum.Material.Neon,
				Color = slimeDef.SecondaryColor,
				Size = Vector3.new(1.65 * scale, 1.15 * scale, 0.25 * scale),
				CFrame = center * CFrame.new(side * radius * 1.05, 0.25 * scale, 0.35 * scale) * CFrame.Angles(0, math.rad(side * 25), math.rad(-side * 18)),
				Parent = model,
			}))
		end
	elseif species == "Unicorn" then
		attach(makePart({
			Name = "UnicornHorn",
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 240, 95),
			Size = Vector3.new(0.45 * scale, 1.55 * scale, 0.45 * scale),
			CFrame = center * CFrame.new(0, radius * 1.05, -0.35 * scale) * CFrame.Angles(math.rad(-18), 0, 0),
			Parent = model,
		}))
	else
		-- Cat / Puppy / Frog perked ears
		for side = -1, 1, 2 do
			attach(makePart({
				Name = "CuteEar_" .. side,
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Neon,
				Color = slimeDef.SecondaryColor,
				Size = Vector3.new(0.78 * scale, 0.88 * scale, 0.48 * scale),
				CFrame = center * CFrame.new(side * radius * 0.65, radius * 0.82, 0),
				Parent = model,
			}))
		end
	end
end

-- Creates an Ornate World Egg with Saturn Rings, Golden Filigree Crown, Rarity Sparkles, and ProximityPrompt ("Steal Egg")!
function SquishyBuilder.CreateWorldEgg(slimeDef: SlimeData.SlimeDef, anchored: boolean?): Model
	local isAnchored = if anchored ~= nil then anchored else true
	local model = Instance.new("Model")
	model.Name = "Egg_" .. tostring(slimeDef.Id)
	model:SetAttribute("SlimeId", slimeDef.Id)
	model:SetAttribute("Level", slimeDef.Level)
	model:SetAttribute("Behavior", slimeDef.Behavior)
	model:SetAttribute("BounceCount", 0)

	local scale = if slimeDef.IsBoss then 1.48 else 1.18
	local eggSize = Vector3.new(3.5 * scale, 4.5 * scale, 3.5 * scale)

	local shell = makePart({
		Name = "EggShell",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.18,
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

	-- 1. Ornate Tilted Saturn Ring & Golden Filigree Crown (matches real_dense_08.png!)
	local saturnRing = makePart({
		Name = "SaturnRing",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = slimeDef.SecondaryColor,
		Transparency = 0.18,
		Size = Vector3.new(0.28 * scale, 5.8 * scale, 5.8 * scale),
		CFrame = shell.CFrame * CFrame.Angles(math.rad(18), math.rad(25), math.rad(72)),
		Anchored = isAnchored,
		Parent = model,
	})
	if not isAnchored then
		weldTo(shell, saturnRing)
	end

	-- Golden Royal Crown / Filigree Band around the top of the Egg
	local goldCrown = makePart({
		Name = "GoldenFiligreeBand",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 65),
		Size = Vector3.new(0.55 * scale, 3.85 * scale, 3.85 * scale),
		CFrame = shell.CFrame * CFrame.new(0, -0.85 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Anchored = isAnchored,
		Parent = model,
	})
	if not isAnchored then
		weldTo(shell, goldCrown)
	end

	-- Top Royal Gem
	local topGem = makePart({
		Name = "TopRoyalGem",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 230, 85),
		Size = Vector3.new(0.95 * scale, 0.95 * scale, 0.95 * scale),
		CFrame = shell.CFrame * CFrame.new(0, 2.35 * scale, 0),
		Anchored = isAnchored,
		Parent = model,
	})
	if not isAnchored then
		weldTo(shell, topGem)
	end

	-- Glowing Halo Pedestal Ring on the ground when in the world
	if isAnchored then
		makePart({
			Name = "EggPedestalRing",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = slimeDef.SecondaryColor,
			Size = Vector3.new(0.45, 5.2 * scale, 5.2 * scale),
			CFrame = CFrame.new(slimeDef.Position - Vector3.new(0, 1.9 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Anchored = true,
			CanCollide = false,
			Parent = model,
		})

		-- Interactive "[HOLD] Egg - Steal" ProximityPrompt just like real_dense_08.png!
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StealPrompt"
		prompt.ActionText = "Steal"
		prompt.ObjectText = slimeDef.Name .. " Egg ($" .. tostring(slimeDef.CoinsPerSec) .. "/s)"
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = shell
	end

	-- Add Rarity Sparkles
	addRarityParticles(shell, slimeDef.Color, slimeDef.SecondaryColor, if slimeDef.IsBoss then 20 else 10)

	-- Decorative glowing Egg Gems
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

	addFaceToBody(shell, model, 1.62 * scale, 1.0 * scale, isAnchored)

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

	-- Clean Short-Range Billboard Tag
	local bb = Instance.new("BillboardGui")
	bb.Name = "EggTag"
	bb.Size = UDim2.new(0, 195, 0, 62)
	bb.StudsOffset = Vector3.new(0, 3.9 * scale, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 48
	bb.Parent = shell

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = slimeDef.Color
	title.TextStrokeTransparency = 0.08
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
	sub.TextStrokeTransparency = 0.12
	sub.Text = string.format("%s • +$%s/s", slimeDef.Rarity, formatNumber(slimeDef.CoinsPerSec))
	sub.Parent = bb

	return model
end

-- Creates a Planted Egg inside a glowing purple/neon Incubator Ring with a giant live "00:08" Countdown Timer (matching real_frame_a_01.png!)
function SquishyBuilder.CreatePlantedEgg(slimeDef: SlimeData.SlimeDef, position: Vector3, hatchSeconds: number): Model
	local eggModel = SquishyBuilder.CreateWorldEgg(slimeDef, true)
	eggModel.Name = "PlantedEgg_" .. tostring(slimeDef.Id)
	local shell = eggModel.PrimaryPart :: BasePart
	if shell then
		eggModel:PivotTo(CFrame.new(position + Vector3.new(0, 2.3, 0)))
		local stealPrompt = shell:FindFirstChild("StealPrompt")
		if stealPrompt then
			stealPrompt:Destroy()
		end
		local oldTag = shell:FindFirstChild("EggTag")
		if oldTag then
			oldTag:Destroy()
		end
	end

	-- Glowing Purple/Magenta Magic Incubator Ring on the lawn (just like real_frame_a_01.png!)
	makePart({
		Name = "IncubatorMagicRing",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(195, 95, 255),
		Size = Vector3.new(0.55, 7.2, 7.2),
		CFrame = CFrame.new(position + Vector3.new(0, 0.28, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = eggModel,
	})
	makePart({
		Name = "IncubatorInnerRing",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 235, 110),
		Size = Vector3.new(0.62, 5.2, 5.2),
		CFrame = CFrame.new(position + Vector3.new(0, 0.32, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = eggModel,
	})

	-- Giant Bold White "00:08" Countdown Timer Billboard above the planted Egg!
	local timerBB = Instance.new("BillboardGui")
	timerBB.Name = "CountdownTag"
	timerBB.Size = UDim2.new(0, 200, 0, 82)
	timerBB.StudsOffset = Vector3.new(0, 5.2, 0)
	timerBB.AlwaysOnTop = true
	timerBB.MaxDistance = 75
	timerBB.Parent = shell

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, 0, 0.65, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Font = Enum.Font.FredokaOne
	timerLabel.TextScaled = true
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerLabel.TextStrokeColor3 = Color3.fromRGB(15, 20, 35)
	timerLabel.TextStrokeTransparency = 0
	timerLabel.Text = string.format("00:%02d", hatchSeconds)
	timerLabel.Parent = timerBB

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "SubLabel"
	subLabel.Size = UDim2.new(1, 0, 0.35, 0)
	subLabel.Position = UDim2.new(0, 0, 0.65, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.GothamBold
	subLabel.TextScaled = true
	subLabel.TextColor3 = Color3.fromRGB(255, 225, 85)
	subLabel.TextStrokeTransparency = 0.1
	subLabel.Text = "🥚 Hatching " .. slimeDef.Name .. "..."
	subLabel.Parent = timerBB

	return eggModel
end

-- Creates a 3D Hatched Squishy Tool for the player's Roblox Backpack (Bottom Hotbar)!
-- Selecting it from the Backpack holds the cute Squishy in your hand; clicking or walking into your Pen places it to make $/sec!
function SquishyBuilder.CreateSquishyBackpackTool(slimeDef: SlimeData.SlimeDef, squishyLevel: number?): Tool
	local lvl = squishyLevel or 1
	local cps = SlimeData.GetSquishyCoinsPerSec(slimeDef, lvl)

	local tool = Instance.new("Tool")
	tool.Name = string.format("🥟 %s ($%s/s)", slimeDef.Name, formatNumber(cps))
	tool.ToolTip = string.format("Equip & Click in your Pen to place %s (+$%s/sec)!", slimeDef.Name, formatNumber(cps))
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsSquishyTool", true)
	tool:SetAttribute("SlimeId", slimeDef.Id)
	tool:SetAttribute("SquishyLevel", lvl)
	tool.GripPos = Vector3.new(0, -0.4, 0.2)

	local scale = 0.65
	local radius = 1.65 * scale
	local handle = makePart({
		Name = "Handle",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.15,
		Color = slimeDef.Color,
		Size = Vector3.new(radius * 2, radius * 1.85, radius * 2),
		Anchored = false,
		CanCollide = false,
		Parent = tool,
	})

	addFaceToBody(handle, tool, radius * 0.95, scale, false)
	addSpeciesFeatures(handle, tool, slimeDef, radius, scale, false)
	addRarityParticles(handle, slimeDef.Color, slimeDef.SecondaryColor, 6)

	return tool
end

-- Creates a Placed Bouncing Squishy Dumpling inside the player's Base Pen that generates +$Coins/sec and can be Leveled Up!
function SquishyBuilder.CreateHatchedSquishy(
	slimeDef: SlimeData.SlimeDef,
	position: Vector3,
	gelTier: number?,
	squishyLevel: number?
): Model
	local tier = gelTier or 1
	local lvl = squishyLevel or 1
	local model = Instance.new("Model")
	model.Name = "Squishy_" .. tostring(slimeDef.Id)
	model:SetAttribute("SlimeId", slimeDef.Id)
	model:SetAttribute("SquishyLevel", lvl)

	local levelScaleBoost = 1 + math.min(0.65, (lvl - 1) * 0.08)
	local scale = (if slimeDef.IsBoss then 1.25 else 1.05) * levelScaleBoost
	local radius = 2.15 * scale

	local outerColor = if tier == 2
		then Color3.fromRGB(255, 215, 55)
		elseif tier >= 3 then Color3.fromHSV((slimeDef.Id * 0.11) % 1, 0.85, 1)
		else slimeDef.Color

	local body = makePart({
		Name = "JellyBody",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = if tier >= 2 then 0.28 else 0.14,
		Color = outerColor,
		Transparency = 0.06,
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
		Transparency = 0.35,
		Size = Vector3.new(radius * 1.15, radius * 1.05, radius * 1.15),
		Position = position,
		Parent = model,
	})

	addRarityParticles(body, outerColor, slimeDef.SecondaryColor, if tier >= 2 then 12 else 6)
	addFaceToBody(body, model, radius * 0.96, scale, true)
	addSpeciesFeatures(body, model, slimeDef, radius, scale, true)

	local cps = SlimeData.GetSquishyCoinsPerSec(slimeDef, lvl)
	local upgCost = SlimeData.GetSquishyUpgradeCost(slimeDef, lvl)

	-- ProximityPrompt so walking up to any placed Squishy lets you Level Up its $/sec right away!
	local upgPrompt = Instance.new("ProximityPrompt")
	upgPrompt.Name = "UpgradeSquishyPrompt"
	upgPrompt.ActionText = string.format("Level Up -> Lv.%d ($%s)", lvl + 1, formatNumber(upgCost))
	upgPrompt.ObjectText = string.format("%s (+$%s/s)", slimeDef.Name, formatNumber(cps))
	upgPrompt.HoldDuration = 0
	upgPrompt.MaxActivationDistance = 11
	upgPrompt.RequiresLineOfSight = false
	upgPrompt.KeyboardKeyCode = Enum.KeyCode.E
	upgPrompt.Parent = body

	-- Clean 3-Line Overhead Tag matching real_frame_a_01.png ("Woven / Common / +$36/s") + Level!
	local bb = Instance.new("BillboardGui")
	bb.Name = "SquishyTag"
	bb.Size = UDim2.new(0, 175, 0, 68)
	bb.StudsOffset = Vector3.new(0, radius + 2.1, 0)
	bb.MaxDistance = 42
	bb.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.38, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.08
	nameLabel.Text = string.format("%s [Lv.%d]", slimeDef.Name, lvl)
	nameLabel.Parent = bb

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0.28, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.36, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextScaled = true
	rarityLabel.TextColor3 = SlimeData.RarityColors[slimeDef.Rarity] or Color3.fromRGB(200, 200, 210)
	rarityLabel.TextStrokeTransparency = 0.15
	rarityLabel.Text = slimeDef.Rarity
	rarityLabel.Parent = bb

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Size = UDim2.new(1, 0, 0.34, 0)
	rateLabel.Position = UDim2.new(0, 0, 0.64, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Font = Enum.Font.FredokaOne
	rateLabel.TextScaled = true
	rateLabel.TextColor3 = Color3.fromRGB(85, 255, 120)
	rateLabel.TextStrokeTransparency = 0.08
	rateLabel.Text = string.format("+$%s/s", formatNumber(cps))
	rateLabel.Parent = bb

	return model
end

-- Creates a Colossal, High-Realism 3D Boss Monster / Giant Guardian Squishy with "Zzz" Sleep Status that wakes up with "!!" on Egg Steal!
function SquishyBuilder.CreateGuardianModel(guardianDef: SlimeData.GuardianDef): Model
	local model = Instance.new("Model")
	model.Name = "Guardian_" .. guardianDef.Id
	model:SetAttribute("GuardianId", guardianDef.Id)
	model:SetAttribute("Level", guardianDef.Level)

	local pos = guardianDef.HomePosition
	local s = 1.45 -- Colossal scale like the Giant Boss Squishies in real_dense_08.png!

	-- Sculpted Rounded Monster Torso
	local torso = makePart({
		Name = "Body",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.12,
		Color = guardianDef.PrimaryColor,
		Size = Vector3.new(7.4 * s, 6.8 * s, 8.2 * s),
		Position = pos + Vector3.new(0, 3.2 * s, 0),
		Parent = model,
	})
	model.PrimaryPart = torso

	-- Armored / Glowing Belly Scales
	makePart({
		Name = "AccentBelly",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = guardianDef.AccentColor,
		Transparency = 0.15,
		Size = Vector3.new(5.6 * s, 5.0 * s, 7.6 * s),
		CFrame = torso.CFrame * CFrame.new(0, -0.45 * s, -0.35 * s),
		Parent = model,
	})

	-- Colossal Sculpted Monster Head & Articulated Snout/Jaws
	local head = makePart({
		Name = "Head",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.15,
		Color = guardianDef.PrimaryColor,
		Size = Vector3.new(6.8 * s, 6.0 * s, 6.8 * s),
		CFrame = torso.CFrame * CFrame.new(0, 3.4 * s, -2.4 * s),
		Parent = model,
	})
	makePart({
		Name = "UpperJaw",
		Material = Enum.Material.SmoothPlastic,
		Color = guardianDef.PrimaryColor,
		Size = Vector3.new(5.0 * s, 2.2 * s, 4.2 * s),
		CFrame = head.CFrame * CFrame.new(0, -0.35 * s, -2.6 * s),
		Parent = model,
	})
	makePart({
		Name = "LowerJaw",
		Material = Enum.Material.SmoothPlastic,
		Color = guardianDef.AccentColor,
		Size = Vector3.new(4.6 * s, 1.5 * s, 3.8 * s),
		CFrame = head.CFrame * CFrame.new(0, -1.75 * s, -2.4 * s) * CFrame.Angles(math.rad(14), 0, 0),
		Parent = model,
	})

	-- Upper & Lower Rows of Sharp White 3D Fangs
	for t = -2, 2 do
		makePart({
			Name = "UpperFang_" .. t,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 255, 255),
			Size = Vector3.new(0.55 * s, 1.15 * s, 0.55 * s),
			CFrame = head.CFrame * CFrame.new(t * 0.95 * s, -1.15 * s, -4.3 * s) * CFrame.Angles(0, 0, math.rad(180)),
			Parent = model,
		})
		makePart({
			Name = "LowerFang_" .. t,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 255, 255),
			Size = Vector3.new(0.48 * s, 0.85 * s, 0.48 * s),
			CFrame = head.CFrame * CFrame.new(t * 0.88 * s, -1.45 * s, -4.0 * s),
			Parent = model,
		})
	end

	-- Fierce Glowing Eyes with Slit Pupils & Angled Brow Ridges
	for side = -1, 1, 2 do
		local eye = makePart({
			Name = "Eye_" .. side,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 215, 45),
			Size = Vector3.new(1.55 * s, 1.55 * s, 0.85 * s),
			CFrame = head.CFrame * CFrame.new(side * 1.65 * s, 1.05 * s, -2.85 * s),
			Parent = model,
		})
		makePart({
			Name = "Pupil_" .. side,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(15, 10, 20),
			Size = Vector3.new(0.55 * s, 1.25 * s, 0.45 * s),
			CFrame = eye.CFrame * CFrame.new(0, 0, -0.32 * s),
			Parent = model,
		})
		makePart({
			Name = "BrowRidge_" .. side,
			Material = Enum.Material.SmoothPlastic,
			Color = guardianDef.AccentColor,
			Size = Vector3.new(2.1 * s, 0.55 * s, 1.1 * s),
			CFrame = head.CFrame
				* CFrame.new(side * 1.65 * s, 1.95 * s, -2.95 * s)
				* CFrame.Angles(0, 0, math.rad(-side * 22)),
			Parent = model,
		})
	end

	-- Dorsal Spine Crests down the Monster's back
	for sp = 1, 4 do
		makePart({
			Name = "DorsalSpine_" .. sp,
			Material = Enum.Material.Neon,
			Color = guardianDef.AccentColor,
			Size = Vector3.new(0.85 * s, (2.4 - sp * 0.3) * s, 1.35 * s),
			CFrame = torso.CFrame
				* CFrame.new(0, 3.1 * s, (-1.0 + sp * 1.35) * s)
				* CFrame.Angles(math.rad(-22), 0, 0),
			Parent = model,
		})
	end

	-- Muscular Legs & Claws/Sneakers
	for side = -1, 1, 2 do
		local legName = if side == -1 then "LeftLeg" else "RightLeg"
		local footName = if side == -1 then "LeftFootSneaker" else "RightFootSneaker"
		makePart({
			Name = legName,
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.SmoothPlastic,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(3.6 * s, 2.6 * s, 2.6 * s),
			CFrame = torso.CFrame * CFrame.new(side * 2.3 * s, -3.4 * s, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		})
		makePart({
			Name = footName,
			Material = Enum.Material.Neon,
			Color = if guardianDef.Style == "Shark" then Color3.fromRGB(55, 195, 255) else guardianDef.AccentColor,
			Size = Vector3.new(2.9 * s, 1.5 * s, 4.4 * s),
			CFrame = torso.CFrame * CFrame.new(side * 2.3 * s, -5.0 * s, -0.8 * s),
			Parent = model,
		})
	end

	-- Style-Specific Boss Anatomy
	if guardianDef.Style == "Shark" then
		makePart({
			Name = "DorsalFin",
			Material = Enum.Material.SmoothPlastic,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(1.1 * s, 4.8 * s, 4.0 * s),
			CFrame = torso.CFrame * CFrame.new(0, 4.4 * s, 1.2 * s) * CFrame.Angles(math.rad(-25), 0, 0),
			Parent = model,
		})
		makePart({
			Name = "SharkTail",
			Material = Enum.Material.SmoothPlastic,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(1.3 * s, 5.0 * s, 3.6 * s),
			CFrame = torso.CFrame * CFrame.new(0, 0.5 * s, 5.0 * s) * CFrame.Angles(math.rad(20), 0, 0),
			Parent = model,
		})
	elseif guardianDef.Style == "BrainrotBat" then
		makePart({
			Name = "RightArm",
			Material = Enum.Material.SmoothPlastic,
			Color = guardianDef.PrimaryColor,
			Size = Vector3.new(2.0 * s, 4.4 * s, 2.0 * s),
			CFrame = torso.CFrame * CFrame.new(4.0 * s, 0.5 * s, -1.0 * s) * CFrame.Angles(math.rad(45), 0, 0),
			Parent = model,
		})
		makePart({
			Name = "WoodenClub",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Wood,
			Color = Color3.fromRGB(165, 105, 50),
			Size = Vector3.new(8.2 * s, 2.0 * s, 2.0 * s),
			CFrame = torso.CFrame * CFrame.new(4.5 * s, 2.6 * s, -3.4 * s) * CFrame.Angles(0, 0, math.rad(72)),
			Parent = model,
		})
	elseif guardianDef.Style == "Dragon" then
		for side = -1, 1, 2 do
			makePart({
				Name = if side == -1 then "LeftWing" else "RightWing",
				Material = Enum.Material.Neon,
				Color = guardianDef.AccentColor,
				Size = Vector3.new(8.5 * s, 4.8 * s, 0.7 * s),
				CFrame = torso.CFrame
					* CFrame.new(side * 6.4 * s, 2.4 * s, 1.0 * s)
					* CFrame.Angles(0, math.rad(-side * 20), math.rad(-side * 18)),
				Parent = model,
			})
		end
	else
		for side = -1, 1, 2 do
			makePart({
				Name = if side == -1 then "LeftEar" else "RightEar",
				Shape = Enum.PartType.Ball,
				Color = guardianDef.PrimaryColor,
				Size = Vector3.new(2.5 * s, 2.5 * s, 1.6 * s),
				CFrame = head.CFrame * CFrame.new(side * 2.4 * s, 2.5 * s, 0),
				Parent = model,
			})
		end
	end

	addRarityParticles(torso, guardianDef.PrimaryColor, guardianDef.AccentColor, 16)

	-- Giant Floating "Zzz" / "!!" Emote Billboard (matches the cyan "Z" sleep icon in real_dense_08.png!)
	local sleepBB = Instance.new("BillboardGui")
	sleepBB.Name = "SleepEmoteGui"
	sleepBB.Size = UDim2.new(0, 95, 0, 95)
	sleepBB.StudsOffset = Vector3.new(-4.8 * s, 5.5 * s, -2.0 * s)
	sleepBB.AlwaysOnTop = false
	sleepBB.MaxDistance = 120
	sleepBB.Parent = head

	local sleepText = Instance.new("TextLabel")
	sleepText.Name = "EmoteLabel"
	sleepText.Size = UDim2.new(1, 0, 1, 0)
	sleepText.BackgroundTransparency = 1
	sleepText.Font = Enum.Font.FredokaOne
	sleepText.TextScaled = true
	sleepText.TextColor3 = Color3.fromRGB(65, 225, 255)
	sleepText.TextStrokeColor3 = Color3.fromRGB(15, 25, 45)
	sleepText.TextStrokeTransparency = 0
	sleepText.Text = "Zzz"
	sleepText.Parent = sleepBB

	-- Overhead Boss Name & Speed Requirement Tag
	local bb = Instance.new("BillboardGui")
	bb.Name = "GuardianTag"
	bb.Size = UDim2.new(0, 240, 0, 76)
	bb.StudsOffset = Vector3.new(0, 8.8 * s, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 95
	bb.Parent = torso

	local title = Instance.new("TextLabel")
	title.Name = "NameLabel"
	title.Size = UDim2.new(1, 0, 0.52, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 220, 65)
	title.TextStrokeTransparency = 0.08
	title.Text = guardianDef.Title .. ": " .. guardianDef.Name
	title.Parent = bb

	local status = Instance.new("TextLabel")
	status.Name = "StatusLabel"
	status.Size = UDim2.new(1, 0, 0.48, 0)
	status.Position = UDim2.new(0, 0, 0.52, 0)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.GothamBold
	status.TextScaled = true
	status.TextColor3 = Color3.fromRGB(125, 235, 255)
	status.TextStrokeTransparency = 0.12
	local reqSpd = guardianDef.RequiredSpeedPower or 800
	status.Text = string.format("💤 Sleeping near Eggs (Speed: %s)", formatNumber(reqSpd))
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
				if
					inst.Name == "Head"
					or string.find(inst.Name, "Torso")
					or string.find(inst.Name, "Arm")
					or string.find(inst.Name, "Leg")
					or string.find(inst.Name, "Hand")
					or string.find(inst.Name, "Foot")
				then
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
		Transparency = 0.1,
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

	addFaceToBody(shell, costume, 1.85 * morphScale, morphScale, false)
	addSpeciesFeatures(shell, costume, slimeDef, 1.9 * morphScale, morphScale, false)
end

return SquishyBuilder
