--!strict
-- SquishyBuilder.luau
-- High-Detail Procedural 3D Model Factory for Ornate Saturn-Ringed Eggs,
-- Planted Countdown Eggs, Backpack Squishy Tools, Species-Sculpted Squishy Dumplings,
-- and Colossal Sleeping/Chasing Monster Bosses!

local SlimeData = require(script.Parent.SlimeData)
local PrebuiltLoader = require(script.Parent.PrebuiltLoader)

local SquishyBuilder = {}


local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = if props.Anchored ~= nil then props.Anchored else true
	part.CanCollide = if props.CanCollide ~= nil then props.CanCollide else false
	part.CanTouch = if props.CanTouch ~= nil then props.CanTouch else false
	part.CanQuery = if props.CanQuery ~= nil then props.CanQuery else false
	part.CastShadow = false
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

local function addRarityParticles(_parentPart: BasePart, _color1: Color3, _color2: Color3, _rate: number)
	-- Zero continuous ParticleEmitter overhead across 117 world items for locked 60 FPS
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

-- Attaches a crisp Highlight + PointLight ONLY to Collectibles (Brainrot Eggs, Hatched Brainrots, Squishies & Gold Coins)
-- so they pop and glow against the matte, non-glowing map!
local function attachCollectiblePopGlow(
	model: Model,
	primaryPart: BasePart,
	fillColor: Color3,
	outlineColor: Color3,
	lightRange: number,
	lightBrightness: number
)
	local hl = model:FindFirstChild("CollectiblePopHighlight") :: Highlight?
	if not hl then
		local newHl = Instance.new("Highlight")
		newHl.Name = "CollectiblePopHighlight"
		newHl.DepthMode = Enum.HighlightDepthMode.Occluded
		newHl.FillColor = fillColor
		newHl.OutlineColor = outlineColor
		newHl.FillTransparency = 0.68
		newHl.OutlineTransparency = 0.05
		newHl.Parent = model
	end

	local pt = primaryPart:FindFirstChild("CollectiblePopLight") :: PointLight?
	if not pt then
		local newPt = Instance.new("PointLight")
		newPt.Name = "CollectiblePopLight"
		newPt.Color = outlineColor:Lerp(fillColor, 0.35)
		newPt.Range = lightRange
		newPt.Brightness = lightBrightness
		newPt.Shadows = false
		newPt.Parent = primaryPart
	end
end

-- Builds big expressive cartoon eyes (white sclera + black pupils + brows) and open mouth/teeth/beak
local function addBrainrotEyesAndMouth(
	headPart: BasePart,
	model: Instance,
	scale: number,
	anchored: boolean,
	expressionType: string?
): { BasePart }
	local isAnchored = anchored
	local expr = expressionType or "Wide"
	local headCF = headPart.CFrame
	local parts: { BasePart } = {}

	local function attachPart(p: Part): Part
		p.Anchored = isAnchored
		if not isAnchored then
			weldTo(headPart, p)
		end
		table.insert(parts, p)
		return p
	end

	local eyeSize = Vector3.new(0.55 * scale, 0.65 * scale, 0.45 * scale)
	local pupilSize = Vector3.new(0.28 * scale, 0.35 * scale, 0.32 * scale)
	local eyeSpacing = if expr == "Derp" then 0.62 * scale else 0.48 * scale
	local eyeY = 0.24 * scale
	local eyeZ = -headPart.Size.Z * 0.48

	for _, side in ipairs({ -1, 1 }) do
		-- Sclera (White eye ball)
		local sclera = attachPart(makePart({
			Name = "BrainrotEyeWhite_" .. side,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(255, 255, 255),
			Size = eyeSize,
			CFrame = headCF * CFrame.new(side * eyeSpacing, eyeY, eyeZ),
			Parent = model,
		}))

		-- Pupil
		local pupilOffset = if expr == "Derp" then (if side == -1 then Vector3.new(-0.08 * scale, 0, -0.12 * scale) else Vector3.new(0.08 * scale, -0.05 * scale, -0.12 * scale))
			elseif expr == "Fierce" then Vector3.new(-side * 0.05 * scale, -0.03 * scale, -0.12 * scale)
			else Vector3.new(0, 0, -0.12 * scale)

		attachPart(makePart({
			Name = "BrainrotPupil_" .. side,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(15, 15, 22),
			Size = pupilSize,
			CFrame = sclera.CFrame * CFrame.new(pupilOffset),
			Parent = model,
		}))

		-- Glint / shine
		attachPart(makePart({
			Name = "BrainrotEyeShine_" .. side,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 255, 255),
			Size = Vector3.new(0.12 * scale, 0.12 * scale, 0.12 * scale),
			CFrame = sclera.CFrame * CFrame.new(0.08 * scale, 0.12 * scale, -0.18 * scale),
			Parent = model,
		}))

		-- Brow (furrowed or wide)
		local browRot = if expr == "Fierce" then math.rad(side * 28)
			elseif expr == "Derp" then math.rad(-side * 18)
			else math.rad(side * 12)
		attachPart(makePart({
			Name = "BrainrotBrow_" .. side,
			Color = Color3.fromRGB(35, 35, 45),
			Material = Enum.Material.SmoothPlastic,
			Size = Vector3.new(0.52 * scale, 0.14 * scale, 0.16 * scale),
			CFrame = headCF * CFrame.new(side * eyeSpacing, eyeY + 0.36 * scale, eyeZ - 0.04 * scale) * CFrame.Angles(0, 0, browRot),
			Parent = model,
		}))
	end

	-- Mouth
	if expr == "Fierce" or expr == "Grin" then
		local mouth = attachPart(makePart({
			Name = "BrainrotMouthInterior",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(50, 15, 20),
			Material = Enum.Material.SmoothPlastic,
			Size = Vector3.new(0.72 * scale, 0.45 * scale, 0.35 * scale),
			CFrame = headCF * CFrame.new(0, -0.22 * scale, eyeZ - 0.04 * scale),
			Parent = model,
		}))
		attachPart(makePart({
			Name = "BrainrotTeethTop",
			Color = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.55 * scale, 0.14 * scale, 0.22 * scale),
			CFrame = mouth.CFrame * CFrame.new(0, 0.14 * scale, -0.06 * scale),
			Parent = model,
		}))
		attachPart(makePart({
			Name = "BrainrotTeethBottom",
			Color = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.48 * scale, 0.12 * scale, 0.2 * scale),
			CFrame = mouth.CFrame * CFrame.new(0, -0.14 * scale, -0.06 * scale),
			Parent = model,
		}))
	elseif expr == "OpenMouth" or expr == "Derp" or expr == "Wide" then
		attachPart(makePart({
			Name = "BrainrotDerpMouth",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(60, 15, 25),
			Material = Enum.Material.SmoothPlastic,
			Size = Vector3.new(0.85 * scale, 0.52 * scale, 0.38 * scale),
			CFrame = headCF * CFrame.new(0, -0.24 * scale, eyeZ - 0.02 * scale),
			Parent = model,
		}))
		attachPart(makePart({
			Name = "BrainrotTongue",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(255, 95, 120),
			Material = Enum.Material.SmoothPlastic,
			Size = Vector3.new(0.45 * scale, 0.22 * scale, 0.3 * scale),
			CFrame = headCF * CFrame.new(0, -0.32 * scale, eyeZ - 0.12 * scale),
			Parent = model,
		}))
	end

	return parts
end

-- Builds unmistakable distinct 3D Brainrot Character Sculptures for all 35 Brainrots (#1 to #35)
local function addBrainrotFeatures(
	body: BasePart,
	model: Instance,
	slimeDef: SlimeData.SlimeDef,
	radius: number,
	scale: number,
	anchored: boolean
)
	local center = body.CFrame
	local numId = tonumber(slimeDef.Id) or 1
	local nameLower = string.lower(slimeDef.Name or "")

	local function attach(p: Part): Part
		p.Anchored = anchored
		if not anchored then
			weldTo(body, p)
		end
		return p
	end

	local targetId = numId
	if targetId < 1 or targetId > 35 then
		if string.find(nameLower, "tralal") then targetId = if string.find(nameLower, "cosmic") then 35 else 1
		elseif string.find(nameLower, "liril") then targetId = 2
		elseif string.find(nameLower, "trippi") then targetId = 3
		elseif string.find(nameLower, "burbal") then targetId = 4
		elseif string.find(nameLower, "assassin") or (string.find(nameLower, "cappuccin") and not string.find(nameLower, "ballerina")) then targetId = 5
		elseif string.find(nameLower, "ballerina") then targetId = 6
		elseif string.find(nameLower, "chimpanz") or string.find(nameLower, "banan") then targetId = 7
		elseif string.find(nameLower, "frigo") then targetId = 8
		elseif string.find(nameLower, "tung") then targetId = 9
		elseif string.find(nameLower, "bombard") then targetId = if string.find(nameLower, "inferno") then 30 else 10
		elseif string.find(nameLower, "gusini") or string.find(nameLower, "bombomb") then targetId = 11
		elseif string.find(nameLower, "glorbo") or string.find(nameLower, "fruttodr") then targetId = 12
		elseif string.find(nameLower, "patapim") then targetId = 13
		elseif string.find(nameLower, "orangut") or string.find(nameLower, "ananas") then targetId = 14
		elseif string.find(nameLower, "boneca") or string.find(nameLower, "ambalabu") then targetId = 15
		elseif string.find(nameLower, "trulim") then targetId = 16
		elseif string.find(nameLower, "giraf") or string.find(nameLower, "celestre") then targetId = 17
		elseif string.find(nameLower, "bicus") then targetId = 18
		elseif string.find(nameLower, "garam") then targetId = 19
		elseif string.find(nameLower, "maxwell") then targetId = 20
		elseif string.find(nameLower, "saturn") or string.find(nameLower, "vaca") then targetId = 21
		elseif string.find(nameLower, "cacto") or string.find(nameLower, "hipo") then targetId = 22
		elseif string.find(nameLower, "blueberrin") or string.find(nameLower, "octopuss") then targetId = 23
		elseif string.find(nameLower, "crabracadabra") then targetId = 24
		elseif string.find(nameLower, "chicleteira") or string.find(nameLower, "bicicleteira") then targetId = 25
		elseif string.find(nameLower, "spijun") or string.find(nameLower, "golub") then targetId = 26
		elseif string.find(nameLower, "tigrr") or string.find(nameLower, "waterm") then targetId = 27
		elseif string.find(nameLower, "zibra") then targetId = 28
		elseif string.find(nameLower, "graipussi") or string.find(nameLower, "medussi") then targetId = 29
		elseif string.find(nameLower, "inferno") then targetId = 30
		elseif string.find(nameLower, "gattatino") or string.find(nameLower, "neonino") then targetId = 31
		elseif string.find(nameLower, "matteo") then targetId = 32
		elseif string.find(nameLower, "udin") then targetId = 33
		elseif string.find(nameLower, "skibidi") then targetId = 34
		elseif string.find(nameLower, "cosmic") then targetId = 35
		else
			targetId = ((numId - 1) % 35) + 1
		end
	end

	if targetId == 1 then
		-- #1: Tralalero Tralala (Sleek Blue Great-White Shark in 3 Blue Nike Sneakers)
		attach(makePart({
			Name = "SharkTorso",
			Color = Color3.fromRGB(45, 145, 245),
			Size = Vector3.new(2.4 * scale, 2.1 * scale, 5.2 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "SharkBelly",
			Color = Color3.fromRGB(245, 250, 255),
			Size = Vector3.new(2.1 * scale, 0.65 * scale, 4.6 * scale),
			CFrame = center * CFrame.new(0, -0.75 * scale, 0),
			Parent = model,
		}))
		local snout = attach(makePart({
			Name = "SharkSnout",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(45, 145, 245),
			Size = Vector3.new(2.0 * scale, 1.4 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, -0.05 * scale, -2.6 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "SharkJaw",
			Color = Color3.fromRGB(245, 250, 255),
			Size = Vector3.new(1.8 * scale, 0.42 * scale, 1.9 * scale),
			CFrame = center * CFrame.new(0, -0.58 * scale, -2.3 * scale) * CFrame.Angles(math.rad(18), 0, 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "SharkTeeth_" .. side,
				Color = Color3.fromRGB(255, 255, 255),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.75 * scale, 0.16 * scale, 0.25 * scale),
				CFrame = center * CFrame.new(side * 0.45 * scale, -0.42 * scale, -2.75 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "PectoralFin_" .. side,
				Color = Color3.fromRGB(45, 145, 245),
				Size = Vector3.new(1.6 * scale, 0.26 * scale, 1.1 * scale),
				CFrame = center * CFrame.new(side * 1.65 * scale, -0.35 * scale, -0.5 * scale) * CFrame.Angles(0, math.rad(-side * 22), math.rad(-side * 25)),
				Parent = model,
			}))
		end
		attach(makePart({
			Name = "SharkDorsalFin",
			Color = Color3.fromRGB(45, 145, 245),
			Size = Vector3.new(0.38 * scale, 2.1 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 1.65 * scale, 0.2 * scale) * CFrame.Angles(math.rad(-25), 0, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "SharkTailFin",
			Color = Color3.fromRGB(45, 145, 245),
			Size = Vector3.new(0.35 * scale, 2.2 * scale, 1.4 * scale),
			CFrame = center * CFrame.new(0, 0.4 * scale, 2.8 * scale) * CFrame.Angles(math.rad(22), 0, 0),
			Parent = model,
		}))
		addBrainrotEyesAndMouth(snout, model, scale, anchored, "Fierce")
		local sneakerOffsets = {
			Vector3.new(-1.15 * scale, -1.25 * scale, -0.6 * scale),
			Vector3.new(1.15 * scale, -1.25 * scale, -0.6 * scale),
			Vector3.new(0, -1.25 * scale, 1.7 * scale),
		}
		for idx, off in ipairs(sneakerOffsets) do
			local shoe = attach(makePart({
				Name = "BlueNikeSneaker_" .. idx,
				Color = Color3.fromRGB(28, 125, 255),
				Size = Vector3.new(0.95 * scale, 0.62 * scale, 1.65 * scale),
				CFrame = center * CFrame.new(off),
				Parent = model,
			}))
			attach(makePart({
				Name = "NikeSole_" .. idx,
				Color = Color3.fromRGB(255, 255, 255),
				Material = Enum.Material.Neon,
				Size = Vector3.new(1.02 * scale, 0.24 * scale, 1.75 * scale),
				CFrame = shoe.CFrame * CFrame.new(0, -0.25 * scale, 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "NikeSwoosh_" .. idx,
				Color = Color3.fromRGB(255, 255, 255),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.12 * scale, 0.22 * scale, 0.85 * scale),
				CFrame = shoe.CFrame * CFrame.new((if off.X <= 0 then -0.48 * scale else 0.48 * scale), 0.08 * scale, 0) * CFrame.Angles(0, 0, math.rad(15)),
				Parent = model,
			}))
		end

	elseif targetId == 2 then
		-- #2: Lirili Larila (Prickly Cactus Elephant in Desert Sandals)
		attach(makePart({
			Name = "CactusElephantBody",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(68, 178, 78),
			Size = Vector3.new(3.0 * scale, 2.8 * scale, 3.6 * scale),
			CFrame = center,
			Parent = model,
		}))
		for i = 0, 7 do
			local ang = math.rad(i * 45)
			attach(makePart({
				Name = "CactusSpine_" .. i,
				Color = Color3.fromRGB(255, 255, 255),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.18 * scale, 0.55 * scale, 0.18 * scale),
				CFrame = center * CFrame.Angles(0, ang, 0) * CFrame.new(0, 1.25 * scale, -1.35 * scale) * CFrame.Angles(math.rad(30), 0, 0),
				Parent = model,
			}))
		end
		local elHead = attach(makePart({
			Name = "ElephantHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(68, 178, 78),
			Size = Vector3.new(2.4 * scale, 2.2 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 0.3 * scale, -1.8 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "ElephantTrunk",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(68, 178, 78),
			Size = Vector3.new(2.4 * scale, 0.65 * scale, 0.65 * scale),
			CFrame = center * CFrame.new(0, -0.1 * scale, -2.8 * scale) * CFrame.Angles(math.rad(35), math.rad(90), 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "FloppyEar_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(75, 195, 88),
				Size = Vector3.new(0.38 * scale, 2.2 * scale, 1.8 * scale),
				CFrame = center * CFrame.new(side * 1.8 * scale, 0.5 * scale, -1.6 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "IvoryTusk_" .. side,
				Color = Color3.fromRGB(255, 252, 235),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.28 * scale, 0.28 * scale, 1.25 * scale),
				CFrame = center * CFrame.new(side * 0.65 * scale, -0.35 * scale, -2.6 * scale) * CFrame.Angles(math.rad(-18), 0, 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "ElephantLeg_" .. side,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(68, 178, 78),
				Size = Vector3.new(1.4 * scale, 0.95 * scale, 0.95 * scale),
				CFrame = center * CFrame.new(side * 1.1 * scale, -0.85 * scale, -0.8 * scale) * CFrame.Angles(math.rad(90), 0, 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "DesertSandal_" .. side,
				Color = Color3.fromRGB(142, 86, 44),
				Material = Enum.Material.Wood,
				Size = Vector3.new(1.15 * scale, 0.38 * scale, 1.75 * scale),
				CFrame = center * CFrame.new(side * 1.1 * scale, -1.35 * scale, -0.8 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "SandalStrap_" .. side,
				Color = Color3.fromRGB(85, 48, 25),
				Size = Vector3.new(1.22 * scale, 0.16 * scale, 0.45 * scale),
				CFrame = center * CFrame.new(side * 1.1 * scale, -1.15 * scale, -0.8 * scale),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(elHead, model, scale, anchored, "Derp")

	elseif targetId == 3 then
		-- #3: Trippi Troppi (Coral Shrimp/Cat Hybrid with Pincers & Whiskers)
		attach(makePart({
			Name = "ShrimpBody",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(255, 85, 75),
			Size = Vector3.new(2.6 * scale, 2.0 * scale, 4.2 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "ShrimpTailFan",
			Color = Color3.fromRGB(255, 120, 105),
			Size = Vector3.new(1.8 * scale, 0.28 * scale, 1.6 * scale),
			CFrame = center * CFrame.new(0, 0.45 * scale, 2.3 * scale) * CFrame.Angles(math.rad(28), 0, 0),
			Parent = model,
		}))
		local catHead = attach(makePart({
			Name = "ShrimpCatHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(255, 110, 95),
			Size = Vector3.new(2.2 * scale, 2.0 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 0.2 * scale, -1.8 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "CatEar_" .. side,
				Color = Color3.fromRGB(255, 85, 75),
				Size = Vector3.new(0.55 * scale, 0.75 * scale, 0.45 * scale),
				CFrame = catHead.CFrame * CFrame.new(side * 0.72 * scale, 1.05 * scale, 0) * CFrame.Angles(0, 0, math.rad(-side * 20)),
				Parent = model,
			}))
			local pincer = attach(makePart({
				Name = "GiantPincer_" .. side,
				Color = Color3.fromRGB(235, 45, 45),
				Size = Vector3.new(0.85 * scale, 1.45 * scale, 1.85 * scale),
				CFrame = center * CFrame.new(side * 1.75 * scale, 0.1 * scale, -1.8 * scale) * CFrame.Angles(0, math.rad(side * 25), 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "PincerTip_" .. side,
				Color = Color3.fromRGB(255, 135, 125),
				Size = Vector3.new(0.42 * scale, 0.55 * scale, 1.15 * scale),
				CFrame = pincer.CFrame * CFrame.new(0, 0.35 * scale, -0.85 * scale) * CFrame.Angles(math.rad(-25), 0, 0),
				Parent = model,
			}))
			for legIdx = 1, 3 do
				attach(makePart({
					Name = "ShrimpLeg_" .. side .. "_" .. legIdx,
					Color = Color3.fromRGB(255, 110, 95),
					Size = Vector3.new(0.28 * scale, 0.95 * scale, 0.28 * scale),
					CFrame = center * CFrame.new(side * 1.35 * scale, -0.75 * scale, (-0.6 + legIdx * 0.7) * scale) * CFrame.Angles(0, 0, math.rad(side * 35)),
					Parent = model,
				}))
			end
		end
		addBrainrotEyesAndMouth(catHead, model, scale, anchored, "Wide")

	elseif targetId == 4 then
		-- #4: Burbaloni Luliloli (Coconut Capybara — Round Fuzzy Coconut Shell + Capybara Snout)
		attach(makePart({
			Name = "CoconutShell",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(112, 75, 48),
			Material = Enum.Material.Slate,
			Size = Vector3.new(3.2 * scale, 3.0 * scale, 3.4 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "CoconutFiberRing",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(168, 125, 82),
			Material = Enum.Material.WoodPlanks,
			Size = Vector3.new(0.55 * scale, 3.3 * scale, 3.3 * scale),
			CFrame = center * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		local capyHead = attach(makePart({
			Name = "CapybaraSnout",
			Color = Color3.fromRGB(145, 98, 62),
			Size = Vector3.new(1.8 * scale, 1.5 * scale, 2.0 * scale),
			CFrame = center * CFrame.new(0, -0.15 * scale, -1.9 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "CapyNose",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(35, 25, 20),
			Size = Vector3.new(0.45 * scale, 0.35 * scale, 0.35 * scale),
			CFrame = capyHead.CFrame * CFrame.new(0, -0.15 * scale, -1.05 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "CapyEar_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(115, 78, 48),
				Size = Vector3.new(0.45 * scale, 0.55 * scale, 0.35 * scale),
				CFrame = capyHead.CFrame * CFrame.new(side * 0.75 * scale, 0.8 * scale, 0.3 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "CapyFootFront_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(98, 65, 38),
				Size = Vector3.new(0.75 * scale, 0.55 * scale, 1.15 * scale),
				CFrame = center * CFrame.new(side * 1.1 * scale, -1.35 * scale, -1.1 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "CapyFootBack_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(98, 65, 38),
				Size = Vector3.new(0.75 * scale, 0.55 * scale, 1.15 * scale),
				CFrame = center * CFrame.new(side * 1.1 * scale, -1.35 * scale, 1.1 * scale),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(capyHead, model, scale, anchored, "Derp")

	elseif targetId == 5 then
		-- #5: Cappuccino Assassino (Porcelain Coffee Cup Ninja with Headband & Dual Katanas)
		local cup = attach(makePart({
			Name = "CoffeeCupBody",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(250, 250, 252),
			Size = Vector3.new(3.4 * scale, 3.0 * scale, 3.0 * scale),
			CFrame = center * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "CupHandle",
			Color = Color3.fromRGB(250, 250, 252),
			Size = Vector3.new(0.45 * scale, 1.65 * scale, 0.95 * scale),
			CFrame = center * CFrame.new(-1.65 * scale, 0, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "CappuccinoFoamDome",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(215, 170, 120),
			Size = Vector3.new(2.7 * scale, 0.85 * scale, 2.7 * scale),
			CFrame = center * CFrame.new(0, 1.55 * scale, 0),
			Parent = model,
		}))
		local headband = attach(makePart({
			Name = "NinjaHeadband",
			Color = Color3.fromRGB(25, 25, 28),
			Size = Vector3.new(3.05 * scale, 0.65 * scale, 3.05 * scale),
			CFrame = center * CFrame.new(0, 0.75 * scale, 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "HeadbandTie_" .. side,
				Color = Color3.fromRGB(225, 35, 45),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.22 * scale, 1.45 * scale, 0.35 * scale),
				CFrame = center * CFrame.new(side * 0.45 * scale, 0.45 * scale, 1.7 * scale) * CFrame.Angles(math.rad(-25), 0, math.rad(side * 18)),
				Parent = model,
			}))
			attach(makePart({
				Name = "CrossedKatana_" .. side,
				Color = Color3.fromRGB(220, 235, 255),
				Material = Enum.Material.Metal,
				Size = Vector3.new(0.18 * scale, 3.8 * scale, 0.28 * scale),
				CFrame = center * CFrame.new(0, 0.65 * scale, 1.55 * scale) * CFrame.Angles(0, 0, math.rad(side * 38)),
				Parent = model,
			}))
			attach(makePart({
				Name = "NinjaLeg_" .. side,
				Color = Color3.fromRGB(25, 25, 28),
				Size = Vector3.new(0.65 * scale, 0.85 * scale, 0.85 * scale),
				CFrame = center * CFrame.new(side * 0.75 * scale, -1.85 * scale, 0),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(headband, model, scale, anchored, "Fierce")

	elseif targetId == 6 then
		-- #6: Ballerina Cappuccina (Teacup Ballerina in Pink Tutu & Pointe Slippers)
		local cupHead = attach(makePart({
			Name = "TeacupHead",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(252, 250, 252),
			Size = Vector3.new(1.8 * scale, 2.2 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 1.35 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "CupRimGold",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(255, 215, 65),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.25 * scale, 2.3 * scale, 2.3 * scale),
			CFrame = center * CFrame.new(0, 2.2 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "SlenderTorso",
			Color = Color3.fromRGB(255, 170, 215),
			Size = Vector3.new(1.2 * scale, 1.8 * scale, 1.2 * scale),
			CFrame = center * CFrame.new(0, 0.1 * scale, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "PinkTutuSkirt",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(255, 125, 205),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.45 * scale, 5.2 * scale, 5.2 * scale),
			CFrame = center * CFrame.new(0, -0.45 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "BalletArm_" .. side,
				Color = Color3.fromRGB(255, 220, 210),
				Size = Vector3.new(0.35 * scale, 1.65 * scale, 0.35 * scale),
				CFrame = center * CFrame.new(side * 1.15 * scale, 0.75 * scale, 0) * CFrame.Angles(0, 0, math.rad(-side * 45)),
				Parent = model,
			}))
			attach(makePart({
				Name = "PointeSlipper_" .. side,
				Color = Color3.fromRGB(255, 135, 195),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.45 * scale, 0.85 * scale, 0.95 * scale),
				CFrame = center * CFrame.new(side * 0.55 * scale, -1.45 * scale, 0),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(cupHead, model, scale, anchored, "Wide")

	elseif targetId == 7 then
		-- #7: Chimpanzini Bananini (Chimpanzee emerging from 4 Peeled Yellow Banana Flaps)
		attach(makePart({
			Name = "BananaBase",
			Color = Color3.fromRGB(255, 225, 45),
			Size = Vector3.new(2.4 * scale, 2.6 * scale, 2.4 * scale),
			CFrame = center * CFrame.new(0, -0.6 * scale, 0),
			Parent = model,
		}))
		for p = 0, 3 do
			local ang = math.rad(p * 90 + 45)
			attach(makePart({
				Name = "BananaPeel_" .. p,
				Color = Color3.fromRGB(255, 225, 45),
				Material = Enum.Material.Neon,
				Size = Vector3.new(1.15 * scale, 2.2 * scale, 0.35 * scale),
				CFrame = center * CFrame.Angles(0, ang, 0) * CFrame.new(0, -0.35 * scale, -1.65 * scale) * CFrame.Angles(math.rad(-38), 0, 0),
				Parent = model,
			}))
		end
		attach(makePart({
			Name = "ChimpTorso",
			Color = Color3.fromRGB(115, 75, 42),
			Size = Vector3.new(2.0 * scale, 1.8 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 0.65 * scale, 0),
			Parent = model,
		}))
		local chimpHead = attach(makePart({
			Name = "ChimpHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(115, 75, 42),
			Size = Vector3.new(1.8 * scale, 1.8 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 1.65 * scale, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "TanMuzzle",
			Color = Color3.fromRGB(215, 175, 135),
			Size = Vector3.new(1.2 * scale, 0.75 * scale, 0.95 * scale),
			CFrame = chimpHead.CFrame * CFrame.new(0, -0.3 * scale, -0.75 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "MonkeyEar_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(155, 105, 65),
				Size = Vector3.new(0.35 * scale, 0.95 * scale, 0.95 * scale),
				CFrame = chimpHead.CFrame * CFrame.new(side * 1.05 * scale, 0.2 * scale, 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "ChimpArm_" .. side,
				Color = Color3.fromRGB(115, 75, 42),
				Size = Vector3.new(0.55 * scale, 1.45 * scale, 0.55 * scale),
				CFrame = center * CFrame.new(side * 1.35 * scale, 0.45 * scale, -0.45 * scale) * CFrame.Angles(math.rad(25), 0, math.rad(-side * 25)),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(chimpHead, model, scale, anchored, "Grin")

	elseif targetId == 8 then
		-- #8: Frigo Camelo (Stainless Steel Refrigerator Camel in Boots)
		attach(makePart({
			Name = "FridgeBody",
			Color = Color3.fromRGB(215, 228, 240),
			Material = Enum.Material.Metal,
			Size = Vector3.new(2.8 * scale, 4.2 * scale, 2.4 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "ChromeHandleTop",
			Color = Color3.fromRGB(240, 245, 255),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.22 * scale, 1.25 * scale, 0.28 * scale),
			CFrame = center * CFrame.new(1.15 * scale, 1.1 * scale, -1.35 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "ChromeHandleBottom",
			Color = Color3.fromRGB(240, 245, 255),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.22 * scale, 1.25 * scale, 0.28 * scale),
			CFrame = center * CFrame.new(1.15 * scale, -0.9 * scale, -1.35 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "IceDispenser",
			Color = Color3.fromRGB(65, 185, 245),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.85 * scale, 0.95 * scale, 0.22 * scale),
			CFrame = center * CFrame.new(-0.45 * scale, 0.85 * scale, -1.32 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "CamelHump",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(205, 155, 95),
			Size = Vector3.new(1.8 * scale, 1.6 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 2.65 * scale, 0.5 * scale),
			Parent = model,
		}))
		local camelHead = attach(makePart({
			Name = "CamelHead",
			Color = Color3.fromRGB(210, 165, 110),
			Size = Vector3.new(1.4 * scale, 1.6 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 3.2 * scale, -0.8 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "CamelBootFront_" .. side,
				Color = Color3.fromRGB(95, 55, 32),
				Size = Vector3.new(0.85 * scale, 0.85 * scale, 1.35 * scale),
				CFrame = center * CFrame.new(side * 1.05 * scale, -2.45 * scale, -0.75 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "CamelBootBack_" .. side,
				Color = Color3.fromRGB(95, 55, 32),
				Size = Vector3.new(0.85 * scale, 0.85 * scale, 1.35 * scale),
				CFrame = center * CFrame.new(side * 1.05 * scale, -2.45 * scale, 0.75 * scale),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(camelHead, model, scale, anchored, "Derp")

	elseif targetId == 9 then
		-- #9: Tung Tung Tung Sahur (Tall Carved Wooden Log with Wooden Baseball Bat)
		local logBody = attach(makePart({
			Name = "WoodenLogBody",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(162, 106, 56),
			Material = Enum.Material.Wood,
			Size = Vector3.new(5.2 * scale, 2.5 * scale, 2.5 * scale),
			CFrame = center * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "LogTopRing",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(215, 178, 128),
			Material = Enum.Material.WoodPlanks,
			Size = Vector3.new(0.45 * scale, 2.55 * scale, 2.55 * scale),
			CFrame = center * CFrame.new(0, 2.5 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "LogBottomRing",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(215, 178, 128),
			Material = Enum.Material.WoodPlanks,
			Size = Vector3.new(0.45 * scale, 2.55 * scale, 2.55 * scale),
			CFrame = center * CFrame.new(0, -2.5 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "BaseballBat",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(168, 108, 52),
			Material = Enum.Material.Wood,
			Size = Vector3.new(3.2 * scale, 0.55 * scale, 0.55 * scale),
			CFrame = center * CFrame.new(1.85 * scale, 0.35 * scale, -0.65 * scale) * CFrame.Angles(math.rad(25), 0, math.rad(72)),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "WoodenArm_" .. side,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(152, 98, 48),
				Material = Enum.Material.Wood,
				Size = Vector3.new(1.8 * scale, 0.45 * scale, 0.45 * scale),
				CFrame = center * CFrame.new(side * 1.55 * scale, 0.65 * scale, 0) * CFrame.Angles(0, 0, math.rad(side * 35)),
				Parent = model,
			}))
			attach(makePart({
				Name = "WoodenLeg_" .. side,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(152, 98, 48),
				Material = Enum.Material.Wood,
				Size = Vector3.new(1.4 * scale, 0.55 * scale, 0.55 * scale),
				CFrame = center * CFrame.new(side * 0.75 * scale, -2.95 * scale, 0) * CFrame.Angles(math.rad(90), 0, 0),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(logBody, model, scale, anchored, "OpenMouth")

	elseif targetId == 10 then
		-- #10: Bombardiro Crocodilo (Olive Military Bomber Alligator + Twin Propellers + Bomb)
		attach(makePart({
			Name = "BomberFuselage",
			Color = Color3.fromRGB(85, 135, 72),
			Size = Vector3.new(2.6 * scale, 2.0 * scale, 5.8 * scale),
			CFrame = center,
			Parent = model,
		}))
		local crocSnout = attach(makePart({
			Name = "CrocSnout",
			Color = Color3.fromRGB(85, 135, 72),
			Size = Vector3.new(2.2 * scale, 0.85 * scale, 2.8 * scale),
			CFrame = center * CFrame.new(0, -0.15 * scale, -3.2 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "CockpitCanopy",
			Color = Color3.fromRGB(120, 220, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(1.6 * scale, 0.75 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 1.15 * scale, -0.8 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "BomberWings",
			Color = Color3.fromRGB(92, 142, 78),
			Material = Enum.Material.Metal,
			Size = Vector3.new(8.8 * scale, 0.35 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 0.25 * scale, 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			local eng = attach(makePart({
				Name = "WingEngine_" .. side,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(55, 62, 68),
				Material = Enum.Material.Metal,
				Size = Vector3.new(2.0 * scale, 1.05 * scale, 1.05 * scale),
				CFrame = center * CFrame.new(side * 2.6 * scale, 0.15 * scale, -0.5 * scale) * CFrame.Angles(0, math.rad(90), 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "PropellerBlade_" .. side,
				Color = Color3.fromRGB(255, 225, 75),
				Material = Enum.Material.Neon,
				Size = Vector3.new(2.4 * scale, 0.28 * scale, 0.22 * scale),
				CFrame = eng.CFrame * CFrame.new(1.15 * scale, 0, 0) * CFrame.Angles(math.rad(45), math.rad(90), 0),
				Parent = model,
			}))
		end
		attach(makePart({
			Name = "UnderbellyBomb",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(35, 38, 42),
			Material = Enum.Material.Metal,
			Size = Vector3.new(2.4 * scale, 0.95 * scale, 0.95 * scale),
			CFrame = center * CFrame.new(0, -1.25 * scale, 0) * CFrame.Angles(0, math.rad(90), 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "TailFin",
			Color = Color3.fromRGB(85, 135, 72),
			Size = Vector3.new(0.35 * scale, 2.1 * scale, 1.6 * scale),
			CFrame = center * CFrame.new(0, 1.25 * scale, 2.6 * scale) * CFrame.Angles(math.rad(22), 0, 0),
			Parent = model,
		}))
		addBrainrotEyesAndMouth(crocSnout, model, scale, anchored, "Fierce")

	elseif targetId == 11 then
		-- #11: Bombombini Gusini (White Fighter-Jet Goose with Twin Under-Wing Rockets)
		attach(makePart({
			Name = "GooseBody",
			Color = Color3.fromRGB(250, 252, 255),
			Size = Vector3.new(2.2 * scale, 1.8 * scale, 3.4 * scale),
			CFrame = center,
			Parent = model,
		}))
		local gooseHead = attach(makePart({
			Name = "GooseHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(250, 252, 255),
			Size = Vector3.new(1.4 * scale, 1.4 * scale, 1.6 * scale),
			CFrame = center * CFrame.new(0, 1.85 * scale, -1.8 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "GooseNeck",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(250, 252, 255),
			Size = Vector3.new(1.8 * scale, 0.7 * scale, 0.7 * scale),
			CFrame = center * CFrame.new(0, 0.95 * scale, -1.35 * scale) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "OrangeBill",
			Color = Color3.fromRGB(255, 140, 25),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.95 * scale, 0.38 * scale, 1.35 * scale),
			CFrame = gooseHead.CFrame * CFrame.new(0, -0.2 * scale, -1.15 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "SweptJetWings",
			Color = Color3.fromRGB(235, 240, 248),
			Size = Vector3.new(7.6 * scale, 0.28 * scale, 2.0 * scale),
			CFrame = center * CFrame.new(0, 0.25 * scale, 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			local missile = attach(makePart({
				Name = "Missile_" .. side,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(180, 185, 195),
				Material = Enum.Material.Metal,
				Size = Vector3.new(2.2 * scale, 0.45 * scale, 0.45 * scale),
				CFrame = center * CFrame.new(side * 2.4 * scale, -0.25 * scale, 0) * CFrame.Angles(0, math.rad(90), 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "MissileWarhead_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(255, 45, 45),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.55 * scale, 0.55 * scale, 0.55 * scale),
				CFrame = missile.CFrame * CFrame.new(1.15 * scale, 0, 0),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(gooseHead, model, scale, anchored, "Fierce")

	elseif targetId == 12 then
		-- #12: Glorbo Fruttodrillo (Watermelon Swamp Alligator + Seeds)
		local gatorTorso = attach(makePart({
			Name = "WatermelonGatorTorso",
			Color = Color3.fromRGB(38, 125, 52),
			Size = Vector3.new(2.6 * scale, 1.8 * scale, 5.6 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "WatermelonBelly",
			Color = Color3.fromRGB(255, 65, 95),
			Size = Vector3.new(2.2 * scale, 0.55 * scale, 5.0 * scale),
			CFrame = center * CFrame.new(0, -0.65 * scale, 0),
			Parent = model,
		}))
		local gatorSnout = attach(makePart({
			Name = "WatermelonSnout",
			Color = Color3.fromRGB(38, 125, 52),
			Size = Vector3.new(2.1 * scale, 0.8 * scale, 2.6 * scale),
			CFrame = center * CFrame.new(0, -0.15 * scale, -3.2 * scale),
			Parent = model,
		}))
		for s = -2, 2 do
			attach(makePart({
				Name = "WatermelonSeed_" .. s,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(25, 25, 28),
				Size = Vector3.new(0.18 * scale, 0.18 * scale, 0.18 * scale),
				CFrame = center * CFrame.new(s * 0.45 * scale, -0.68 * scale, -s * 0.8 * scale),
				Parent = model,
			}))
		end
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "GatorClaw_" .. side,
				Color = Color3.fromRGB(38, 125, 52),
				Size = Vector3.new(1.15 * scale, 0.45 * scale, 1.45 * scale),
				CFrame = center * CFrame.new(side * 1.55 * scale, -0.75 * scale, -0.8 * scale),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(gatorSnout, model, scale, anchored, "Fierce")

	elseif targetId == 13 then
		-- #13: Brr Brr Patapim (Mossy Forest Troll + 2 Enormous Stomping Feet)
		local trollTorso = attach(makePart({
			Name = "MossyTrollTorso",
			Color = Color3.fromRGB(118, 92, 58),
			Size = Vector3.new(2.8 * scale, 2.8 * scale, 2.6 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "TreeCanopyHair",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(48, 142, 56),
			Size = Vector3.new(3.4 * scale, 2.2 * scale, 3.2 * scale),
			CFrame = center * CFrame.new(0, 1.85 * scale, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "ProboscisNose",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(142, 108, 68),
			Size = Vector3.new(0.75 * scale, 1.55 * scale, 0.75 * scale),
			CFrame = center * CFrame.new(0, -0.15 * scale, -1.65 * scale) * CFrame.Angles(math.rad(22), 0, 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "GiantStompingFoot_" .. side,
				Color = Color3.fromRGB(118, 92, 58),
				Size = Vector3.new(1.35 * scale, 0.65 * scale, 2.4 * scale),
				CFrame = center * CFrame.new(side * 1.05 * scale, -1.35 * scale, -0.6 * scale),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(trollTorso, model, scale, anchored, "Derp")

	elseif targetId == 14 then
		-- #14: Orangutini Ananasini (Golden Diamond Pineapple Orangutan)
		local pineTorso = attach(makePart({
			Name = "PineappleTorso",
			Color = Color3.fromRGB(245, 192, 42),
			Material = Enum.Material.DiamondPlate,
			Size = Vector3.new(2.8 * scale, 3.6 * scale, 2.8 * scale),
			CFrame = center,
			Parent = model,
		}))
		for leaf = 0, 5 do
			local ang = math.rad(leaf * 60)
			attach(makePart({
				Name = "PineCrownLeaf_" .. leaf,
				Color = Color3.fromRGB(45, 195, 65),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.45 * scale, 1.85 * scale, 0.32 * scale),
				CFrame = center * CFrame.Angles(0, ang, 0) * CFrame.new(0, 2.2 * scale, -0.45 * scale) * CFrame.Angles(math.rad(-32), 0, 0),
				Parent = model,
			}))
		end
		local apeHead = attach(makePart({
			Name = "OrangutanHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(215, 95, 35),
			Size = Vector3.new(2.2 * scale, 1.9 * scale, 2.0 * scale),
			CFrame = center * CFrame.new(0, 0.65 * scale, -1.2 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "ApeArm_" .. side,
				Color = Color3.fromRGB(215, 95, 35),
				Size = Vector3.new(0.65 * scale, 2.4 * scale, 0.65 * scale),
				CFrame = center * CFrame.new(side * 1.85 * scale, -0.35 * scale, 0) * CFrame.Angles(0, 0, math.rad(-side * 28)),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(apeHead, model, scale, anchored, "Grin")

	elseif targetId == 15 then
		-- #15: Boneca Ambalabu (Black Rubber Car Tire Torso with Green Frog Head & Legs)
		attach(makePart({
			Name = "RubberTireTorso",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(32, 35, 42),
			Material = Enum.Material.Slate,
			Size = Vector3.new(1.6 * scale, 4.2 * scale, 4.2 * scale),
			CFrame = center * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "SilverWheelRim",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(200, 205, 215),
			Material = Enum.Material.Metal,
			Size = Vector3.new(1.65 * scale, 2.4 * scale, 2.4 * scale),
			CFrame = center * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		local frogHead = attach(makePart({
			Name = "GreenFrogHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(60, 210, 75),
			Size = Vector3.new(2.4 * scale, 1.8 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 2.2 * scale, 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "FrogLeg_" .. side,
				Color = Color3.fromRGB(60, 210, 75),
				Size = Vector3.new(0.55 * scale, 2.2 * scale, 0.75 * scale),
				CFrame = center * CFrame.new(side * 1.65 * scale, -0.65 * scale, 0) * CFrame.Angles(0, 0, math.rad(-side * 25)),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(frogHead, model, scale, anchored, "Wide")

	elseif targetId == 16 then
		-- #16: Trulimero Trulicina (Cat-Headed Swimming Fish with Fins & Whiskers)
		attach(makePart({
			Name = "IridescentFishBody",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(55, 190, 245),
			Size = Vector3.new(2.2 * scale, 2.0 * scale, 4.6 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "FishTailCaudal",
			Color = Color3.fromRGB(85, 225, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.32 * scale, 2.2 * scale, 1.6 * scale),
			CFrame = center * CFrame.new(0, 0.35 * scale, 2.4 * scale) * CFrame.Angles(math.rad(22), 0, 0),
			Parent = model,
		}))
		local catHead = attach(makePart({
			Name = "TrulimeroCatHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(240, 240, 250),
			Size = Vector3.new(2.2 * scale, 2.0 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 0.15 * scale, -1.9 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "PerkedCatEar_" .. side,
				Color = Color3.fromRGB(240, 240, 250),
				Size = Vector3.new(0.55 * scale, 0.75 * scale, 0.35 * scale),
				CFrame = catHead.CFrame * CFrame.new(side * 0.75 * scale, 1.05 * scale, 0) * CFrame.Angles(0, 0, math.rad(-side * 22)),
				Parent = model,
			}))
			attach(makePart({
				Name = "FishPectoralFin_" .. side,
				Color = Color3.fromRGB(85, 225, 255),
				Material = Enum.Material.Neon,
				Size = Vector3.new(1.4 * scale, 0.25 * scale, 0.95 * scale),
				CFrame = center * CFrame.new(side * 1.35 * scale, -0.35 * scale, -0.45 * scale) * CFrame.Angles(0, math.rad(-side * 25), math.rad(-side * 25)),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(catHead, model, scale, anchored, "Wide")

	elseif targetId == 17 then
		-- #17: Girafa Celestre (Cosmic Star-Spotted Astronaut Giraffe)
		attach(makePart({
			Name = "CosmicGiraffeBody",
			Color = Color3.fromRGB(35, 45, 115),
			Size = Vector3.new(2.4 * scale, 2.4 * scale, 3.6 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "GiraffeNeck",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(35, 45, 115),
			Size = Vector3.new(4.8 * scale, 0.85 * scale, 0.85 * scale),
			CFrame = center * CFrame.new(0, 2.6 * scale, -1.2 * scale) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		local girHead = attach(makePart({
			Name = "GiraffeHead",
			Color = Color3.fromRGB(35, 45, 115),
			Size = Vector3.new(1.4 * scale, 1.4 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 4.8 * scale, -1.5 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "AstronautVisor",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(255, 225, 90),
			Material = Enum.Material.Glass,
			Transparency = 0.45,
			Size = Vector3.new(2.4 * scale, 2.4 * scale, 2.4 * scale),
			CFrame = girHead.CFrame,
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "OssiconeHorn_" .. side,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(255, 215, 65),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.85 * scale, 0.22 * scale, 0.22 * scale),
				CFrame = girHead.CFrame * CFrame.new(side * 0.45 * scale, 0.95 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
				Parent = model,
			}))
			attach(makePart({
				Name = "GiraffeLegFront_" .. side,
				Color = Color3.fromRGB(35, 45, 115),
				Size = Vector3.new(0.55 * scale, 2.4 * scale, 0.55 * scale),
				CFrame = center * CFrame.new(side * 0.95 * scale, -1.85 * scale, -1.1 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "GiraffeLegBack_" .. side,
				Color = Color3.fromRGB(35, 45, 115),
				Size = Vector3.new(0.55 * scale, 2.4 * scale, 0.55 * scale),
				CFrame = center * CFrame.new(side * 0.95 * scale, -1.85 * scale, 1.1 * scale),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(girHead, model, scale, anchored, "Wide")

	elseif targetId == 18 then
		-- #18: Bri Bri Bicus Dicus (Roman Centurion Bird in Golden Galea Helmet & Red Cape)
		local birdBody = attach(makePart({
			Name = "CenturionBirdBody",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(245, 245, 250),
			Size = Vector3.new(2.4 * scale, 2.8 * scale, 2.4 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "RomanArmorCuirass",
			Color = Color3.fromRGB(235, 185, 45),
			Material = Enum.Material.Metal,
			Size = Vector3.new(2.45 * scale, 1.85 * scale, 2.45 * scale),
			CFrame = center * CFrame.new(0, -0.2 * scale, 0),
			Parent = model,
		}))
		local bicusHead = attach(makePart({
			Name = "CenturionHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(245, 245, 250),
			Size = Vector3.new(1.8 * scale, 1.8 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 1.65 * scale, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "GaleaCrestPlume",
			Color = Color3.fromRGB(215, 35, 45),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.35 * scale, 1.65 * scale, 2.4 * scale),
			CFrame = bicusHead.CFrame * CFrame.new(0, 1.25 * scale, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "RomanEagleBeak",
			Color = Color3.fromRGB(255, 195, 35),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.65 * scale, 0.55 * scale, 1.15 * scale),
			CFrame = bicusHead.CFrame * CFrame.new(0, -0.2 * scale, -0.95 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "CrimsonCape",
			Color = Color3.fromRGB(195, 25, 35),
			Size = Vector3.new(2.2 * scale, 2.8 * scale, 0.35 * scale),
			CFrame = center * CFrame.new(0, -0.25 * scale, 1.35 * scale) * CFrame.Angles(math.rad(15), 0, 0),
			Parent = model,
		}))
		addBrainrotEyesAndMouth(bicusHead, model, scale, anchored, "Fierce")

	elseif targetId == 19 then
		-- #19: Garamaraman (Tall Salt-and-Honey Shaker Duo Character)
		local jarBody = attach(makePart({
			Name = "HoneyJarBody",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(245, 235, 215),
			Size = Vector3.new(4.2 * scale, 2.6 * scale, 2.6 * scale),
			CFrame = center * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "HoneyDrips",
			Color = Color3.fromRGB(255, 185, 35),
			Material = Enum.Material.Neon,
			Size = Vector3.new(2.65 * scale, 1.85 * scale, 2.65 * scale),
			CFrame = center * CFrame.new(0, 0.65 * scale, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "SilverShakerCap",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(215, 220, 230),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.55 * scale, 2.4 * scale, 2.4 * scale),
			CFrame = center * CFrame.new(0, 2.2 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "CompanionMiniShaker",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(240, 245, 255),
			Size = Vector3.new(2.2 * scale, 1.4 * scale, 1.4 * scale),
			CFrame = center * CFrame.new(1.65 * scale, -0.65 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		addBrainrotEyesAndMouth(jarBody, model, scale, anchored, "OpenMouth")

	elseif targetId == 20 then
		-- #20: Maxwell The Spinning Cat (Sleek Black-and-White Tuxedo Loaf Cat)
		local catLoaf = attach(makePart({
			Name = "MaxwellLoafBody",
			Color = Color3.fromRGB(25, 25, 28),
			Size = Vector3.new(2.2 * scale, 1.9 * scale, 3.8 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "WhiteChestBib",
			Color = Color3.fromRGB(250, 250, 255),
			Size = Vector3.new(1.65 * scale, 1.25 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, -0.35 * scale, -0.9 * scale),
			Parent = model,
		}))
		local maxwellHead = attach(makePart({
			Name = "MaxwellHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(25, 25, 28),
			Size = Vector3.new(2.0 * scale, 1.8 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 0.45 * scale, -1.85 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "WhiteMuzzle",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(250, 250, 255),
			Size = Vector3.new(1.1 * scale, 0.65 * scale, 0.85 * scale),
			CFrame = maxwellHead.CFrame * CFrame.new(0, -0.35 * scale, -0.75 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "CurlingTail",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(25, 25, 28),
			Size = Vector3.new(2.2 * scale, 0.38 * scale, 0.38 * scale),
			CFrame = center * CFrame.new(0, 0.85 * scale, 2.2 * scale) * CFrame.Angles(math.rad(45), 0, math.rad(90)),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "MaxwellEar_" .. side,
				Color = Color3.fromRGB(25, 25, 28),
				Size = Vector3.new(0.55 * scale, 0.75 * scale, 0.35 * scale),
				CFrame = maxwellHead.CFrame * CFrame.new(side * 0.65 * scale, 0.95 * scale, 0) * CFrame.Angles(0, 0, math.rad(-side * 22)),
				Parent = model,
			}))
			attach(makePart({
				Name = "WhitePawFront_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(250, 250, 255),
				Size = Vector3.new(0.65 * scale, 0.45 * scale, 0.85 * scale),
				CFrame = center * CFrame.new(side * 0.75 * scale, -0.95 * scale, -1.4 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "WhitePawBack_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(250, 250, 255),
				Size = Vector3.new(0.65 * scale, 0.45 * scale, 0.85 * scale),
				CFrame = center * CFrame.new(side * 0.75 * scale, -0.95 * scale, 1.4 * scale),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(maxwellHead, model, scale, anchored, "Wide")

	elseif targetId == 21 then
		-- #21: La Vaca Saturno Saturnita (Spotted Dairy Cow inside Saturn Ring + Human Sneakers)
		attach(makePart({
			Name = "DairyCowBody",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(245, 245, 250),
			Size = Vector3.new(2.8 * scale, 2.4 * scale, 3.4 * scale),
			CFrame = center,
			Parent = model,
		}))
		for spot = 1, 4 do
			attach(makePart({
				Name = "CowSpot_" .. spot,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(25, 25, 28),
				Size = Vector3.new(0.85 * scale, 0.85 * scale, 0.85 * scale),
				CFrame = center * CFrame.new((spot % 2 == 0 and 1 or -1) * 1.15 * scale, 0.45 * scale, (spot > 2 and 0.8 or -0.8) * scale),
				Parent = model,
			}))
		end
		attach(makePart({
			Name = "SaturnPlanetaryRing",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(255, 220, 85),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.35 * scale, 7.6 * scale, 7.6 * scale),
			CFrame = center * CFrame.Angles(math.rad(18), 0, math.rad(72)),
			Parent = model,
		}))
		local cowHead = attach(makePart({
			Name = "CowHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(245, 245, 250),
			Size = Vector3.new(1.8 * scale, 1.8 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 0.65 * scale, -1.8 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "BovineSnout",
			Color = Color3.fromRGB(255, 175, 195),
			Size = Vector3.new(1.2 * scale, 0.75 * scale, 0.95 * scale),
			CFrame = cowHead.CFrame * CFrame.new(0, -0.35 * scale, -0.75 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "GoldenHorn_" .. side,
				Color = Color3.fromRGB(255, 215, 65),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.35 * scale, 0.85 * scale, 0.35 * scale),
				CFrame = cowHead.CFrame * CFrame.new(side * 0.65 * scale, 0.95 * scale, 0) * CFrame.Angles(0, 0, math.rad(-side * 25)),
				Parent = model,
			}))
			local shoe = attach(makePart({
				Name = "GiantHumanSneaker_" .. side,
				Color = Color3.fromRGB(235, 45, 45),
				Size = Vector3.new(1.2 * scale, 0.7 * scale, 2.2 * scale),
				CFrame = center * CFrame.new(side * 1.15 * scale, -1.45 * scale, -0.35 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "SneakerSole_" .. side,
				Color = Color3.fromRGB(255, 255, 255),
				Material = Enum.Material.Neon,
				Size = Vector3.new(1.28 * scale, 0.25 * scale, 2.3 * scale),
				CFrame = shoe.CFrame * CFrame.new(0, -0.25 * scale, 0),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(cowHead, model, scale, anchored, "Wide")

	elseif targetId == 22 then
		-- #22: Il Cacto Hipopotamo (Giant Desert Cactus Hippo with Wide Jaws & Sandals)
		attach(makePart({
			Name = "CactusHippoBody",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(58, 165, 68),
			Size = Vector3.new(3.6 * scale, 2.8 * scale, 4.4 * scale),
			CFrame = center,
			Parent = model,
		}))
		local hippoJaws = attach(makePart({
			Name = "HippoJaws",
			Color = Color3.fromRGB(58, 165, 68),
			Size = Vector3.new(2.6 * scale, 1.6 * scale, 2.8 * scale),
			CFrame = center * CFrame.new(0, 0.15 * scale, -2.6 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "HippoTeethPegs",
			Color = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(2.2 * scale, 0.25 * scale, 0.35 * scale),
			CFrame = hippoJaws.CFrame * CFrame.new(0, -0.45 * scale, -1.25 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "HippoSandal_" .. side,
				Color = Color3.fromRGB(135, 78, 38),
				Material = Enum.Material.Wood,
				Size = Vector3.new(1.35 * scale, 0.45 * scale, 1.85 * scale),
				CFrame = center * CFrame.new(side * 1.35 * scale, -1.35 * scale, -0.95 * scale),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(hippoJaws, model, scale, anchored, "OpenMouth")

	elseif targetId == 23 then
		-- #23: Blueberrinni Octopussini (Round Blue Berry Octopus + 8 Tentacles)
		local berryHead = attach(makePart({
			Name = "BerryOctoHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(45, 95, 225),
			Size = Vector3.new(3.0 * scale, 3.0 * scale, 3.0 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "BerryCalyxCrown",
			Color = Color3.fromRGB(65, 195, 65),
			Material = Enum.Material.Neon,
			Size = Vector3.new(1.2 * scale, 0.35 * scale, 1.2 * scale),
			CFrame = center * CFrame.new(0, 1.6 * scale, 0),
			Parent = model,
		}))
		for t = 0, 7 do
			local ang = math.rad(t * 45)
			attach(makePart({
				Name = "BlueTentacle_" .. t,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(45, 95, 225),
				Size = Vector3.new(0.75 * scale, 0.75 * scale, 1.85 * scale),
				CFrame = center * CFrame.Angles(0, ang, 0) * CFrame.new(0, -1.25 * scale, -1.85 * scale) * CFrame.Angles(math.rad(28), 0, 0),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(berryHead, model, scale, anchored, "Wide")

	elseif targetId == 24 then
		-- #24: Chef Crabracadabra (Red King Crab Chef with Tall Toque Hat & Spatula)
		local crabBody = attach(makePart({
			Name = "CrabShell",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(225, 45, 45),
			Size = Vector3.new(3.2 * scale, 1.8 * scale, 2.8 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "ChefToqueHat",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(255, 255, 255),
			Size = Vector3.new(1.8 * scale, 1.6 * scale, 1.6 * scale),
			CFrame = center * CFrame.new(0, 1.65 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "LeftClawPincer",
			Color = Color3.fromRGB(245, 55, 55),
			Size = Vector3.new(0.85 * scale, 1.45 * scale, 1.65 * scale),
			CFrame = center * CFrame.new(-2.1 * scale, 0.1 * scale, -1.2 * scale),
			Parent = model,
		}))
		local rightClaw = attach(makePart({
			Name = "RightClawHoldingSpatula",
			Color = Color3.fromRGB(245, 55, 55),
			Size = Vector3.new(0.85 * scale, 1.45 * scale, 1.65 * scale),
			CFrame = center * CFrame.new(2.1 * scale, 0.1 * scale, -1.2 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "CookingSpatula",
			Color = Color3.fromRGB(220, 225, 235),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.25 * scale, 2.6 * scale, 0.65 * scale),
			CFrame = rightClaw.CFrame * CFrame.new(0, 1.1 * scale, -0.45 * scale) * CFrame.Angles(math.rad(35), 0, 0),
			Parent = model,
		}))
		addBrainrotEyesAndMouth(crabBody, model, scale, anchored, "Grin")

	elseif targetId == 25 then
		-- #25: Chicleteira Bicicleteira (Pink Bubblegum Machine on Bicycle Frame)
		local globe = attach(makePart({
			Name = "GumballGlobe",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(255, 120, 185),
			Size = Vector3.new(2.4 * scale, 2.4 * scale, 2.4 * scale),
			CFrame = center * CFrame.new(0, 1.15 * scale, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "GumballBase",
			Color = Color3.fromRGB(225, 35, 45),
			Size = Vector3.new(1.8 * scale, 1.2 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, -0.2 * scale, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "BicycleFrame",
			Color = Color3.fromRGB(55, 185, 255),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.28 * scale, 1.8 * scale, 3.6 * scale),
			CFrame = center * CFrame.new(0, -0.95 * scale, 0),
			Parent = model,
		}))
		for _, wheelZ in ipairs({ -1.6, 1.6 }) do
			attach(makePart({
				Name = "BikeWheel_" .. tostring(wheelZ),
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(35, 38, 42),
				Material = Enum.Material.Slate,
				Size = Vector3.new(0.35 * scale, 2.2 * scale, 2.2 * scale),
				CFrame = center * CFrame.new(0, -1.65 * scale, wheelZ * scale) * CFrame.Angles(0, 0, math.rad(90)),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(globe, model, scale, anchored, "Wide")

	elseif targetId == 26 then
		-- #26: Spijuniro Golubiro (Trenchcoat Spy Pigeon + Sunglasses & Camera)
		local pigeonBody = attach(makePart({
			Name = "TrenchcoatBody",
			Color = Color3.fromRGB(195, 165, 125),
			Size = Vector3.new(2.2 * scale, 2.6 * scale, 2.2 * scale),
			CFrame = center,
			Parent = model,
		}))
		local pHead = attach(makePart({
			Name = "PigeonHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(145, 135, 165),
			Size = Vector3.new(1.6 * scale, 1.6 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 1.85 * scale, -0.45 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "OrangeBeak",
			Color = Color3.fromRGB(255, 140, 35),
			Size = Vector3.new(0.55 * scale, 0.45 * scale, 0.95 * scale),
			CFrame = pHead.CFrame * CFrame.new(0, -0.2 * scale, -1.05 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "SpyFedora",
			Color = Color3.fromRGB(40, 40, 48),
			Size = Vector3.new(2.2 * scale, 0.55 * scale, 2.4 * scale),
			CFrame = pHead.CFrame * CFrame.new(0, 0.85 * scale, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "DarkSunglasses",
			Color = Color3.fromRGB(15, 15, 20),
			Material = Enum.Material.Neon,
			Size = Vector3.new(1.4 * scale, 0.35 * scale, 0.25 * scale),
			CFrame = pHead.CFrame * CFrame.new(0, 0.15 * scale, -0.92 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "SpyCamera",
			Color = Color3.fromRGB(45, 50, 58),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.85 * scale, 0.65 * scale, 0.45 * scale),
			CFrame = center * CFrame.new(0, 0.25 * scale, -1.25 * scale),
			Parent = model,
		}))
		addBrainrotEyesAndMouth(pHead, model, scale, anchored, "Fierce")

	elseif targetId == 27 then
		-- #27: Tigrrullini Watermellini (Orange Tiger Head & Limbs + Watermelon Rind Torso)
		attach(makePart({
			Name = "WatermelonRindTorso",
			Color = Color3.fromRGB(45, 145, 55),
			Size = Vector3.new(2.8 * scale, 2.4 * scale, 4.4 * scale),
			CFrame = center,
			Parent = model,
		}))
		for stripe = -2, 2 do
			attach(makePart({
				Name = "LimeStripe_" .. stripe,
				Color = Color3.fromRGB(125, 235, 95),
				Size = Vector3.new(2.85 * scale, 0.25 * scale, 0.45 * scale),
				CFrame = center * CFrame.new(0, 0.85 * scale, stripe * 0.9 * scale),
				Parent = model,
			}))
		end
		local tigerHead = attach(makePart({
			Name = "TigerHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(255, 125, 25),
			Size = Vector3.new(2.4 * scale, 2.2 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 0.45 * scale, -2.2 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "WhiteTigerMuzzle",
			Color = Color3.fromRGB(250, 250, 255),
			Size = Vector3.new(1.4 * scale, 0.85 * scale, 1.15 * scale),
			CFrame = tigerHead.CFrame * CFrame.new(0, -0.35 * scale, -0.85 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "SaberFang_" .. side,
				Color = Color3.fromRGB(255, 255, 255),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.22 * scale, 0.65 * scale, 0.22 * scale),
				CFrame = tigerHead.CFrame * CFrame.new(side * 0.45 * scale, -0.65 * scale, -1.15 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "TigerPawFront_" .. side,
				Color = Color3.fromRGB(255, 125, 25),
				Size = Vector3.new(0.75 * scale, 1.25 * scale, 1.15 * scale),
				CFrame = center * CFrame.new(side * 1.25 * scale, -1.05 * scale, -1.2 * scale),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(tigerHead, model, scale, anchored, "Fierce")

	elseif targetId == 28 then
		-- #28: Zibra Zubra Zibralini (Striped Zebra Monster with Neon Mohawk)
		local zebraBody = attach(makePart({
			Name = "ZebraTorso",
			Color = Color3.fromRGB(245, 245, 250),
			Size = Vector3.new(2.4 * scale, 2.6 * scale, 3.8 * scale),
			CFrame = center,
			Parent = model,
		}))
		for s = -3, 3 do
			attach(makePart({
				Name = "BlackZebraStripe_" .. s,
				Color = Color3.fromRGB(25, 25, 28),
				Size = Vector3.new(2.45 * scale, 0.25 * scale, 0.35 * scale),
				CFrame = center * CFrame.new(0, 0.45 * scale, s * 0.55 * scale),
				Parent = model,
			}))
		end
		local zHead = attach(makePart({
			Name = "ZebraHead",
			Color = Color3.fromRGB(245, 245, 250),
			Size = Vector3.new(1.6 * scale, 1.8 * scale, 2.4 * scale),
			CFrame = center * CFrame.new(0, 1.45 * scale, -1.8 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "NeonPunkMohawk",
			Color = Color3.fromRGB(255, 45, 185),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.35 * scale, 1.45 * scale, 3.2 * scale),
			CFrame = center * CFrame.new(0, 2.35 * scale, -0.6 * scale),
			Parent = model,
		}))
		addBrainrotEyesAndMouth(zHead, model, scale, anchored, "Fierce")

	elseif targetId == 29 then
		-- #29: Graipussi Medussi (Purple Grape-Cluster Medusa with Vine Tentacles)
		local grapeCenter = attach(makePart({
			Name = "GrapeClusterCenter",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(135, 45, 185),
			Size = Vector3.new(2.8 * scale, 2.8 * scale, 2.8 * scale),
			CFrame = center,
			Parent = model,
		}))
		for g = 1, 6 do
			local ang = math.rad(g * 60)
			attach(makePart({
				Name = "OuterGrape_" .. g,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(115, 35, 165),
				Size = Vector3.new(1.35 * scale, 1.35 * scale, 1.35 * scale),
				CFrame = center * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0.45 * scale, -1.45 * scale),
				Parent = model,
			}))
		end
		local medusaFace = attach(makePart({
			Name = "MedusaFace",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(165, 85, 215),
			Size = Vector3.new(1.8 * scale, 1.8 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 0.45 * scale, -1.45 * scale),
			Parent = model,
		}))
		for v = 1, 5 do
			local ang = math.rad(v * 72)
			attach(makePart({
				Name = "VineSnakeHair_" .. v,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(55, 175, 75),
				Material = Enum.Material.Neon,
				Size = Vector3.new(2.2 * scale, 0.35 * scale, 0.35 * scale),
				CFrame = medusaFace.CFrame * CFrame.Angles(0, ang, 0) * CFrame.new(0, 1.25 * scale, -0.85 * scale) * CFrame.Angles(math.rad(45), 0, 0),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(medusaFace, model, scale, anchored, "Fierce")

	elseif targetId == 30 then
		-- #30: Inferno Bombardiro Rex (Magma Twin-Jet Bomber Dragon/Croc)
		attach(makePart({
			Name = "VolcanicFuselage",
			Color = Color3.fromRGB(35, 25, 28),
			Material = Enum.Material.Slate,
			Size = Vector3.new(2.8 * scale, 2.2 * scale, 6.2 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "MagmaCrackVein",
			Color = Color3.fromRGB(255, 105, 25),
			Material = Enum.Material.Neon,
			Size = Vector3.new(2.85 * scale, 0.35 * scale, 5.8 * scale),
			CFrame = center * CFrame.new(0, 0.15 * scale, 0),
			Parent = model,
		}))
		local rexHead = attach(makePart({
			Name = "InfernoRexSnout",
			Color = Color3.fromRGB(35, 25, 28),
			Size = Vector3.new(2.4 * scale, 1.05 * scale, 3.2 * scale),
			CFrame = center * CFrame.new(0, -0.15 * scale, -3.4 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "InfernoWings",
			Color = Color3.fromRGB(45, 30, 32),
			Size = Vector3.new(9.2 * scale, 0.45 * scale, 2.6 * scale),
			CFrame = center * CFrame.new(0, 0.35 * scale, 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			local jetEng = attach(makePart({
				Name = "JetTurbine_" .. side,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(45, 45, 52),
				Material = Enum.Material.Metal,
				Size = Vector3.new(2.4 * scale, 1.15 * scale, 1.15 * scale),
				CFrame = center * CFrame.new(side * 2.8 * scale, 0.25 * scale, -0.45 * scale) * CFrame.Angles(0, math.rad(90), 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "FlameExhaust_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(255, 95, 25),
				Material = Enum.Material.Neon,
				Size = Vector3.new(1.05 * scale, 1.05 * scale, 1.85 * scale),
				CFrame = jetEng.CFrame * CFrame.new(-1.65 * scale, 0, 0),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(rexHead, model, scale, anchored, "Fierce")

	elseif targetId == 31 then
		-- #31: Gattatino Neonino (Glowing Neon Cyber-Cat with Laser Visor & Twin Tails)
		attach(makePart({
			Name = "CyberCatBody",
			Color = Color3.fromRGB(38, 42, 52),
			Size = Vector3.new(2.2 * scale, 1.9 * scale, 3.8 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "CyanCircuitStrip",
			Color = Color3.fromRGB(45, 235, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(2.25 * scale, 0.25 * scale, 3.4 * scale),
			CFrame = center * CFrame.new(0, 0.35 * scale, 0),
			Parent = model,
		}))
		local cyberHead = attach(makePart({
			Name = "CyberHead",
			Color = Color3.fromRGB(38, 42, 52),
			Size = Vector3.new(2.0 * scale, 1.8 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 0.45 * scale, -1.85 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "LaserVisor",
			Color = Color3.fromRGB(255, 45, 165),
			Material = Enum.Material.Neon,
			Size = Vector3.new(1.85 * scale, 0.45 * scale, 0.28 * scale),
			CFrame = cyberHead.CFrame * CFrame.new(0, 0.15 * scale, -0.92 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "CyberTail_" .. side,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(45, 235, 255),
				Material = Enum.Material.Neon,
				Size = Vector3.new(2.4 * scale, 0.32 * scale, 0.32 * scale),
				CFrame = center * CFrame.new(side * 0.45 * scale, 0.95 * scale, 2.2 * scale) * CFrame.Angles(math.rad(45), 0, math.rad(side * 18)),
				Parent = model,
			}))
			attach(makePart({
				Name = "CyberEar_" .. side,
				Color = Color3.fromRGB(200, 215, 230),
				Material = Enum.Material.Metal,
				Size = Vector3.new(0.45 * scale, 0.75 * scale, 0.35 * scale),
				CFrame = cyberHead.CFrame * CFrame.new(side * 0.65 * scale, 0.95 * scale, 0),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(cyberHead, model, scale, anchored, "Fierce")

	elseif targetId == 32 then
		-- #32: Matteo The Wise (Bearded Wise Forest Elder with Wizard Hat & Glowing Staff)
		local elderTorso = attach(makePart({
			Name = "ElderRobeTorso",
			Color = Color3.fromRGB(65, 88, 55),
			Size = Vector3.new(2.4 * scale, 3.4 * scale, 2.4 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "FlowingWhiteBeard",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(245, 245, 250),
			Size = Vector3.new(1.65 * scale, 2.4 * scale, 1.25 * scale),
			CFrame = center * CFrame.new(0, 0.35 * scale, -1.35 * scale),
			Parent = model,
		}))
		local elderHead = attach(makePart({
			Name = "ElderHead",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(245, 215, 185),
			Size = Vector3.new(1.6 * scale, 1.6 * scale, 1.6 * scale),
			CFrame = center * CFrame.new(0, 1.85 * scale, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "WizardHatBrim",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(45, 58, 75),
			Size = Vector3.new(0.35 * scale, 3.2 * scale, 3.2 * scale),
			CFrame = elderHead.CFrame * CFrame.new(0, 0.75 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "WizardHatCone",
			Color = Color3.fromRGB(45, 58, 75),
			Size = Vector3.new(1.6 * scale, 2.2 * scale, 1.6 * scale),
			CFrame = elderHead.CFrame * CFrame.new(0, 1.85 * scale, -0.2 * scale) * CFrame.Angles(math.rad(-15), 0, 0),
			Parent = model,
		}))
		local staff = attach(makePart({
			Name = "CelestialStaff",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(135, 92, 55),
			Material = Enum.Material.Wood,
			Size = Vector3.new(4.6 * scale, 0.35 * scale, 0.35 * scale),
			CFrame = center * CFrame.new(1.65 * scale, 0.25 * scale, -0.65 * scale) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "CelestialOrb",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(85, 245, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.85 * scale, 0.85 * scale, 0.85 * scale),
			CFrame = staff.CFrame * CFrame.new(-2.35 * scale, 0, 0),
			Parent = model,
		}))
		addBrainrotEyesAndMouth(elderHead, model, scale, anchored, "Wide")

	elseif targetId == 33 then
		-- #33: Udin Din Din Dun (Citrus Strongman Flexing Biceps)
		local citrusBody = attach(makePart({
			Name = "CitrusStrongmanBody",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(255, 135, 25),
			Size = Vector3.new(3.4 * scale, 3.2 * scale, 3.4 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "CitrusStem",
			Color = Color3.fromRGB(55, 175, 45),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.35 * scale, 0.75 * scale, 0.35 * scale),
			CFrame = center * CFrame.new(0, 1.75 * scale, 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			local bicep = attach(makePart({
				Name = "FlexingBicep_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(255, 135, 25),
				Size = Vector3.new(1.35 * scale, 1.55 * scale, 1.35 * scale),
				CFrame = center * CFrame.new(side * 2.1 * scale, 0.85 * scale, 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "ForearmFist_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(255, 135, 25),
				Size = Vector3.new(1.15 * scale, 1.15 * scale, 1.15 * scale),
				CFrame = bicep.CFrame * CFrame.new(side * 0.45 * scale, 1.15 * scale, 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "StrongmanBoot_" .. side,
				Color = Color3.fromRGB(35, 35, 42),
				Size = Vector3.new(1.05 * scale, 0.75 * scale, 1.65 * scale),
				CFrame = center * CFrame.new(side * 1.1 * scale, -1.65 * scale, 0),
				Parent = model,
			}))
		end
		addBrainrotEyesAndMouth(citrusBody, model, scale, anchored, "OpenMouth")

	elseif targetId == 34 then
		-- #34: Skibidi Cyber Titan (Cyber Mech + Shoulder Subwoofers + Core Reactor)
		local mechTorso = attach(makePart({
			Name = "CyberMechTorso",
			Color = Color3.fromRGB(45, 50, 60),
			Material = Enum.Material.Metal,
			Size = Vector3.new(3.4 * scale, 3.8 * scale, 2.4 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "ChestCoreReactor",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(85, 240, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(1.4 * scale, 1.4 * scale, 0.8 * scale),
			CFrame = center * CFrame.new(0, 0.35 * scale, -1.25 * scale),
			Parent = model,
		}))
		local cameraHead = attach(makePart({
			Name = "CCTVCameraHead",
			Color = Color3.fromRGB(35, 38, 48),
			Material = Enum.Material.Metal,
			Size = Vector3.new(1.8 * scale, 1.4 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 2.4 * scale, -0.45 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "ScanningOpticLens",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(255, 35, 45),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.85 * scale, 0.85 * scale, 0.45 * scale),
			CFrame = cameraHead.CFrame * CFrame.new(0, 0, -1.15 * scale),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			local speakerBox = attach(makePart({
				Name = "SpeakerCabinet_" .. side,
				Color = Color3.fromRGB(25, 28, 35),
				Material = Enum.Material.Metal,
				Size = Vector3.new(1.6 * scale, 2.6 * scale, 1.8 * scale),
				CFrame = center * CFrame.new(side * 2.6 * scale, 1.65 * scale, 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "SubwooferCone_" .. side,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(15, 18, 22),
				Size = Vector3.new(0.25 * scale, 1.25 * scale, 1.25 * scale),
				CFrame = speakerBox.CFrame * CFrame.new(0, 0, -0.92 * scale) * CFrame.Angles(0, math.rad(90), 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "MechLeg_" .. side,
				Color = Color3.fromRGB(45, 50, 60),
				Material = Enum.Material.Metal,
				Size = Vector3.new(1.2 * scale, 2.2 * scale, 1.4 * scale),
				CFrame = center * CFrame.new(side * 1.35 * scale, -2.4 * scale, 0),
				Parent = model,
			}))
		end

	elseif targetId == 35 then
		-- #35: Cosmic Tralalero God (Galaxy Shark in 3 Neon Rainbow Sneakers + Cosmic Wings)
		attach(makePart({
			Name = "GalaxySharkTorso",
			Color = Color3.fromRGB(75, 45, 175),
			Size = Vector3.new(2.6 * scale, 2.3 * scale, 5.6 * scale),
			CFrame = center,
			Parent = model,
		}))
		attach(makePart({
			Name = "NebulaBelly",
			Color = Color3.fromRGB(115, 245, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(2.3 * scale, 0.75 * scale, 5.0 * scale),
			CFrame = center * CFrame.new(0, -0.85 * scale, 0),
			Parent = model,
		}))
		local divineSnout = attach(makePart({
			Name = "DivineSnout",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(75, 45, 175),
			Size = Vector3.new(2.2 * scale, 1.6 * scale, 2.4 * scale),
			CFrame = center * CFrame.new(0, -0.05 * scale, -2.8 * scale),
			Parent = model,
		}))
		attach(makePart({
			Name = "DivineGoldenCrown",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(255, 225, 45),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.55 * scale, 2.6 * scale, 2.6 * scale),
			CFrame = center * CFrame.new(0, 2.2 * scale, -0.8 * scale) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "CosmicCelestialWing_" .. side,
				Color = Color3.fromRGB(165, 125, 255),
				Material = Enum.Material.Glass,
				Transparency = 0.25,
				Size = Vector3.new(3.8 * scale, 0.35 * scale, 1.8 * scale),
				CFrame = center * CFrame.new(side * 2.8 * scale, 0.45 * scale, -0.45 * scale) * CFrame.Angles(0, math.rad(-side * 25), math.rad(-side * 28)),
				Parent = model,
			}))
		end
		attach(makePart({
			Name = "DivineDorsalFin",
			Color = Color3.fromRGB(115, 245, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.45 * scale, 2.6 * scale, 2.2 * scale),
			CFrame = center * CFrame.new(0, 1.95 * scale, 0.35 * scale) * CFrame.Angles(math.rad(-25), 0, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "DivineTailFin",
			Color = Color3.fromRGB(115, 245, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.42 * scale, 2.6 * scale, 1.8 * scale),
			CFrame = center * CFrame.new(0, 0.55 * scale, 3.2 * scale) * CFrame.Angles(math.rad(22), 0, 0),
			Parent = model,
		}))
		addBrainrotEyesAndMouth(divineSnout, model, scale, anchored, "Fierce")
		local sneakerOffsets = {
			Vector3.new(-1.25 * scale, -1.35 * scale, -0.65 * scale),
			Vector3.new(1.25 * scale, -1.35 * scale, -0.65 * scale),
			Vector3.new(0, -1.35 * scale, 1.85 * scale),
		}
		for idx, off in ipairs(sneakerOffsets) do
			local shoe = attach(makePart({
				Name = "RainbowGodSneaker_" .. idx,
				Color = Color3.fromRGB(145, 65, 255),
				Size = Vector3.new(1.05 * scale, 0.72 * scale, 1.85 * scale),
				CFrame = center * CFrame.new(off),
				Parent = model,
			}))
			attach(makePart({
				Name = "RainbowNeonSole_" .. idx,
				Color = if idx == 1 then Color3.fromRGB(255, 65, 125) elseif idx == 2 then Color3.fromRGB(65, 255, 185) else Color3.fromRGB(255, 225, 45),
				Material = Enum.Material.Neon,
				Size = Vector3.new(1.12 * scale, 0.28 * scale, 1.95 * scale),
				CFrame = shoe.CFrame * CFrame.new(0, -0.28 * scale, 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "GodSwoosh_" .. idx,
				Color = Color3.fromRGB(255, 235, 85),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.12 * scale, 0.25 * scale, 0.95 * scale),
				CFrame = shoe.CFrame * CFrame.new((if off.X <= 0 then -0.52 * scale else 0.52 * scale), 0.1 * scale, 0) * CFrame.Angles(0, 0, math.rad(15)),
				Parent = model,
			}))
		end
	end
end

-- Adds Species-Specific 3D Squishy Dumpling / Squishmallow Anatomy (or Brainrot Anatomy for IDs #1-#35!)
local function addSpeciesFeatures(
	body: BasePart,
	model: Instance,
	slimeDef: SlimeData.SlimeDef,
	radius: number,
	scale: number,
	anchored: boolean
)
	local numId = tonumber(slimeDef.Id) or 1
	if numId <= 35 or (slimeDef :: any).IsBrainrot == true then
		addBrainrotFeatures(body, model, slimeDef, radius, scale, anchored)
		return
	end

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

-- Creates a Glowing, Spinning 3D Collectible World Coin that pops against the matte map and disappears on pickup!
function SquishyBuilder.CreateWorldCoin(coinId: number, stageLevel: number, coinValue: number, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "WorldCoin_" .. tostring(coinId)
	model:SetAttribute("CoinId", coinId)
	model:SetAttribute("StageLevel", stageLevel)
	model:SetAttribute("CoinValue", coinValue)
	model:SetAttribute("IsWorldCoin", true)

	local s = 1.0 + math.min(0.45, (stageLevel - 1) * 0.06)
	local rim = makePart({
		Name = "CoinRim",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 205, 35),
		Size = Vector3.new(0.65 * s, 3.2 * s, 3.2 * s),
		CFrame = CFrame.new(position + Vector3.new(0, 2.2 * s, 0)),
		Anchored = true,
		CanCollide = false,
		CanTouch = true,
		CanQuery = true,
		Parent = model,
	})
	rim.PivotOffset = CFrame.new(0, -2.2 * s, 0)
	model.PrimaryPart = rim

	makePart({
		Name = "CoinInnerFace",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 240, 115),
		Size = Vector3.new(0.76 * s, 2.35 * s, 2.35 * s),
		CFrame = rim.CFrame,
		Anchored = true,
		CanCollide = false,
		Parent = model,
	})

	attachCollectiblePopGlow(model, rim, Color3.fromRGB(255, 215, 45), Color3.fromRGB(255, 250, 165), 11, 1.35)

	local bb = Instance.new("BillboardGui")
	bb.Name = "CoinTag"
	bb.Size = UDim2.new(3.2, 0, 0.95, 0)
	bb.StudsOffset = Vector3.new(0, 2.3 * s, 0)
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.MaxDistance = 24
	bb.Parent = rim

	local lbl = Instance.new("TextLabel")
	lbl.Name = "ValueLabel"
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(255, 235, 75)
	lbl.TextStrokeTransparency = 0.08
	lbl.Text = string.format("🪙 +$%s", formatNumber(coinValue))
	lbl.Parent = bb

	return model
end

-- Creates either:
--  (A) A Shining Collectible 3D Squishy (for IDs #36-#117 hidden inside Landmarks, Caves, Attics & Obbies)
--  (B) A Glowing Mystery Brainrot Egg (for IDs #1-#35 in the Boss Nests, scaling larger per Stage!)
function SquishyBuilder.CreateWorldEgg(slimeDef: SlimeData.SlimeDef, anchored: boolean?): Model
	local isAnchored = if anchored ~= nil then anchored else true
	local isShining = (slimeDef :: any).IsShiningSquishy == true

	if isShining and isAnchored then
		local sScale = if slimeDef.IsBoss then 1.32 else 1.12
		local radius = 2.0 * sScale
		local origin = Vector3.new(0, 0, 0)

		local model = Instance.new("Model")
		model.Name = "ShiningSquishy_" .. tostring(slimeDef.Id)
		model:SetAttribute("SlimeId", slimeDef.Id)
		model:SetAttribute("Level", slimeDef.Level)
		model:SetAttribute("IsShiningSquishy", true)

		local shell = makePart({
			Name = "EggShell",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Reflectance = 0.28,
			Color = slimeDef.Color,
			Size = Vector3.new(radius * 2, radius * 1.84, radius * 2),
			Position = origin + Vector3.new(0, radius * 0.92 + 0.65, 0),
			Anchored = true,
			CanCollide = false,
			Parent = model,
		})
		shell.PivotOffset = CFrame.new(0, -radius * 0.92 - 0.65, 0)
		model.PrimaryPart = shell

		addFaceToBody(shell, model, radius * 0.95, sScale, true)
		addSpeciesFeatures(shell, model, slimeDef, radius, sScale, true)

		-- Concentric Glowing Neon Ring Pedestal underneath the Shining Squishy
		makePart({
			Name = "OuterNeonRing",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = slimeDef.Color,
			Size = Vector3.new(0.45, 5.2 * sScale, 5.2 * sScale),
			CFrame = CFrame.new(origin + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Anchored = true,
			CanCollide = false,
			Parent = model,
		})
		makePart({
			Name = "InnerDarkCircle",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(22, 26, 42),
			Size = Vector3.new(0.52, 4.1 * sScale, 4.1 * sScale),
			CFrame = CFrame.new(origin + Vector3.new(0, 0.28, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Anchored = true,
			CanCollide = false,
			Parent = model,
		})
		makePart({
			Name = "CenterGoldCircle",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = slimeDef.SecondaryColor,
			Size = Vector3.new(0.58, 2.6 * sScale, 2.6 * sScale),
			CFrame = CFrame.new(origin + Vector3.new(0, 0.32, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Anchored = true,
			CanCollide = false,
			Parent = model,
		})

		makePart({
			Name = "ShiningHalo",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = slimeDef.SecondaryColor,
			Size = Vector3.new(0.32, 2.2 * sScale, 2.2 * sScale),
			CFrame = shell.CFrame * CFrame.new(0, radius + 0.55, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Anchored = true,
			CanCollide = false,
			Parent = model,
		})

		-- Make the Collectible Squishy pop & glow against the matte map!
		attachCollectiblePopGlow(model, shell, slimeDef.Color, slimeDef.SecondaryColor, 14, 1.55)

		local promptAtt = Instance.new("Attachment")
		promptAtt.Name = "PromptAttachment"
		promptAtt.Position = Vector3.new(0, 1.35 * sScale, 0)
		promptAtt.Parent = shell

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CapturePrompt"
		prompt.ActionText = "✨ Grab Hidden Squishy!"
		prompt.ObjectText = string.format("%s [%s] (+$%s/s)", slimeDef.Name, slimeDef.Rarity, formatNumber(slimeDef.CoinsPerSec))
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 15
		prompt.RequiresLineOfSight = false
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		prompt.Parent = promptAtt

		local bb = Instance.new("BillboardGui")
		bb.Name = "EggTag"
		bb.Size = UDim2.new(5.2, 0, 1.35, 0)
		bb.StudsOffset = Vector3.new(0, 2.7 * sScale, 0)
		bb.AlwaysOnTop = false
		bb.LightInfluence = 0
		-- Close-range discovery distance (18 studs) so players explore landmarks/obbies or use Squishy Radar!
		bb.MaxDistance = 18
		bb.Parent = shell

		local title = Instance.new("TextLabel")
		title.Name = "TitleLabel"
		title.Size = UDim2.new(1, 0, 0.55, 0)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.FredokaOne
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(255, 250, 175)
		title.TextStrokeTransparency = 0.05
		title.Text = "✨ " .. slimeDef.Name
		title.Parent = bb

		local sub = Instance.new("TextLabel")
		sub.Name = "SubLabel"
		sub.Size = UDim2.new(1, 0, 0.45, 0)
		sub.Position = UDim2.new(0, 0, 0.55, 0)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.GothamBold
		sub.TextScaled = true
		sub.TextColor3 = SlimeData.RarityColors[slimeDef.Rarity] or Color3.fromRGB(255, 255, 255)
		sub.TextStrokeTransparency = 0.1
		sub.Text = string.format("SQUISHY %s • +$%s/s", string.upper(slimeDef.Rarity), formatNumber(slimeDef.CoinsPerSec))
		sub.Parent = bb

		if slimeDef.Position then
			model:PivotTo(CFrame.new(slimeDef.Position))
		end

		return model
	end

	-- Per-Stage Egg Scaling: Eggs in higher stages (Stages 1..8) are physically grander!
	local stageNum = math.clamp(tonumber(slimeDef.Level) or 1, 1, 8)
	local stageEggFactor = if isAnchored then (1.0 + (stageNum - 1) * 0.12) else 1.0
	local scale = (if slimeDef.IsBoss then 1.55 else 1.32) * stageEggFactor
	local numId = tonumber(slimeDef.Id) or 1
	local origin = Vector3.new(0, 0, 0)

	local model = Instance.new("Model")
	model.Name = "Egg_" .. tostring(slimeDef.Id)
	local eggSize = Vector3.new(3.8 * scale, 4.9 * scale, 3.8 * scale)
	local shell = makePart({
		Name = "EggShell",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.22,
		Color = slimeDef.Color,
		Size = eggSize,
		Position = origin + Vector3.new(0, eggSize.Y * 0.5 + 0.95, 0),
		Anchored = isAnchored,
		CanCollide = false,
		Parent = model,
	})
	shell.PivotOffset = CFrame.new(0, -eggSize.Y * 0.5 - 0.95, 0)
	local eggMesh = Instance.new("SpecialMesh")
	eggMesh.MeshType = Enum.MeshType.Sphere
	eggMesh.Scale = Vector3.new(1.0, 1.24, 1.0)
	eggMesh.Parent = shell
	model.PrimaryPart = shell

	local centerPos = shell.Position

	-- Ornate Polka-Dot Spots on the EggShell
	for gIdx = 0, 5 do
		local ang = math.rad(gIdx * 60)
		local yOff = if gIdx % 2 == 0 then 0.75 * scale else -0.65 * scale
		makePart({
			Name = "EggSpotGem_" .. gIdx,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = slimeDef.SecondaryColor,
			Size = Vector3.new(0.95 * scale, 1.12 * scale, 0.58 * scale),
			CFrame = CFrame.new(centerPos)
				* CFrame.Angles(0, ang, 0)
				* CFrame.new(0, yOff, -1.66 * scale),
			Anchored = isAnchored,
			CanCollide = false,
			Parent = model,
		})
	end

	-- Orbiting Planetary Ring of 8 Glowing Star Pearls around the Brainrot Egg
	local ringTilt = CFrame.new(centerPos) * CFrame.Angles(math.rad(20), math.rad(numId * 25), math.rad(-16))
	for rIdx = 0, 7 do
		local rAng = math.rad(rIdx * 45)
		makePart({
			Name = "SaturnPearl_" .. rIdx,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = if rIdx % 2 == 0 then slimeDef.SecondaryColor else Color3.fromRGB(255, 230, 85),
			Size = Vector3.new(0.58 * scale, 0.42 * scale, 0.92 * scale),
			CFrame = ringTilt * CFrame.Angles(0, rAng, 0) * CFrame.new(0, 0, -2.65 * scale),
			Anchored = isAnchored,
			CanCollide = false,
			Parent = model,
		})
	end

	-- Royal Gold Crown on Top of the Brainrot Egg
	makePart({
		Name = "RoyalCrown",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 55),
		Size = Vector3.new(0.88 * scale, 2.0 * scale, 2.0 * scale),
		CFrame = CFrame.new(centerPos + Vector3.new(0, 2.75 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Anchored = isAnchored,
		CanCollide = false,
		Parent = model,
	})

	-- Make the Brainrot Egg pop & glow against the matte map!
	attachCollectiblePopGlow(model, shell, slimeDef.Color, slimeDef.SecondaryColor, 16, 1.75)

	if not isAnchored then
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = false
				desc.CanCollide = false
				desc.Massless = true
				if desc ~= shell then
					weldTo(shell, desc)
				end
			end
		end
	end

	model:SetAttribute("SlimeId", slimeDef.Id)
	model:SetAttribute("Level", slimeDef.Level)
	model:SetAttribute("Behavior", slimeDef.Behavior)
	model:SetAttribute("BounceCount", 0)

	if isAnchored then
		makePart({
			Name = "BirdNestOuter",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Wood,
			Color = Color3.fromRGB(148, 96, 48),
			Size = Vector3.new(0.85, 4.6 * scale, 4.6 * scale),
			CFrame = CFrame.new(origin + Vector3.new(0, 0.42, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Anchored = true,
			CanCollide = false,
			Parent = model,
		})
		makePart({
			Name = "BirdNestStraw",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Grass,
			Color = Color3.fromRGB(215, 182, 72),
			Size = Vector3.new(0.98, 3.8 * scale, 3.8 * scale),
			CFrame = CFrame.new(origin + Vector3.new(0, 0.49, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Anchored = true,
			CanCollide = false,
			Parent = model,
		})

		local eggPromptAtt = Instance.new("Attachment")
		eggPromptAtt.Name = "PromptAttachment"
		eggPromptAtt.Position = Vector3.new(0, 1.45 * scale, 0)
		eggPromptAtt.Parent = shell

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CapturePrompt"
		prompt.ActionText = string.format("🥚 Grab Stage %d Brainrot Egg!", stageNum)
		prompt.ObjectText = string.format("Mystery Brainrot Egg [Stage %d] ($%s/s+)", stageNum, formatNumber(slimeDef.CoinsPerSec))
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 15
		prompt.RequiresLineOfSight = false
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		prompt.Parent = eggPromptAtt
	end

	addRarityParticles(shell, slimeDef.Color, slimeDef.SecondaryColor, if slimeDef.IsBoss then 18 else 10)

	local bb = Instance.new("BillboardGui")
	bb.Name = "EggTag"
	bb.Size = UDim2.new(5.6, 0, 1.45, 0)
	bb.StudsOffset = Vector3.new(0, 3.2 * scale, 0)
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.MaxDistance = 38
	bb.Parent = shell

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0.05
	title.Text = string.format("🥚 Stage %d Brainrot Egg (%s)", stageNum, slimeDef.Name)
	title.Parent = bb

	local sub = Instance.new("TextLabel")
	sub.Name = "SubLabel"
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = SlimeData.RarityColors[slimeDef.Rarity] or Color3.fromRGB(255, 255, 255)
	sub.TextStrokeTransparency = 0.1
	sub.Text = string.format("%s BRAINROT • +$%s/s", string.upper(slimeDef.Rarity), formatNumber(slimeDef.CoinsPerSec))
	sub.Parent = bb

	if slimeDef.Position then
		model:PivotTo(CFrame.new(slimeDef.Position))
	end

	return model
end

function SquishyBuilder.CreateCarriedEgg(slimeDef: SlimeData.SlimeDef): Model
	return SquishyBuilder.CreateWorldEgg(slimeDef, false)
end

-- Creates a Planted Egg on a Glowing Purple Incubator Pad with a live "00:05" Countdown Timer!
function SquishyBuilder.CreatePlantedEgg(slimeDef: SlimeData.SlimeDef, posOrSeconds: any, maybeSeconds: number?): Model
	local hatchSeconds: number = if typeof(posOrSeconds) == "number" then posOrSeconds else (maybeSeconds or 5)
	local targetPos: Vector3 = if typeof(posOrSeconds) == "Vector3" then posOrSeconds else Vector3.new(0, 0, 0)

	local eggModel = SquishyBuilder.CreateWorldEgg(slimeDef, true)
	eggModel.Name = "PlantedEgg_" .. tostring(slimeDef.Id)
	local shell = eggModel.PrimaryPart :: BasePart
	if shell then
		for _, child in ipairs(eggModel:GetDescendants()) do
			if
				child:IsA("ProximityPrompt")
				or child.Name == "PromptAttachment"
				or child.Name == "EggTag"
				or string.find(child.Name, "^BirdNest") ~= nil
			then
				child:Destroy()
			end
		end
	end

	-- Giant Bold White "00:05" Countdown Timer Billboard above the planted Egg (using pure 3D stud Scale!)
	local timerBB = Instance.new("BillboardGui")
	timerBB.Name = "CountdownTag"
	timerBB.Size = UDim2.new(5.5, 0, 2.0, 0)
	timerBB.StudsOffset = Vector3.new(0, 4.8, 0)
	timerBB.AlwaysOnTop = false
	timerBB.LightInfluence = 0
	timerBB.MaxDistance = 45
	timerBB.Parent = shell

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, 0, 0.68, 0)
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
	subLabel.Size = UDim2.new(1, 0, 0.32, 0)
	subLabel.Position = UDim2.new(0, 0, 0.68, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.GothamBold
	subLabel.TextScaled = true
	subLabel.TextColor3 = Color3.fromRGB(255, 225, 85)
	subLabel.TextStrokeTransparency = 0.1
	subLabel.Text = "🧠🥚 Hatching Brainrot..."
	subLabel.Parent = timerBB

	eggModel:PivotTo(CFrame.new(targetPos))
	return eggModel
end

-- Creates a 3D Hatched Brainrot / Squishy Tool for the player's Roblox Backpack (Bottom Hotbar)
function SquishyBuilder.CreateSquishyBackpackTool(slimeDef: SlimeData.SlimeDef, squishyLevel: number?): Tool
	local lvl = squishyLevel or 1
	local cps = SlimeData.GetSquishyCoinsPerSec(slimeDef, lvl)
	local numId = tonumber(slimeDef.Id) or 1
	local isBrainrot = numId <= 35 or (slimeDef :: any).IsBrainrot == true

	local tool = Instance.new("Tool")
	tool.Name = string.format("%s %s ($%s/s)", if isBrainrot then "🧠" else "🥟", slimeDef.Name, formatNumber(cps))
	tool.ToolTip = string.format("Equip & Click in your Pen to place %s (+$%s/sec)!", slimeDef.Name, formatNumber(cps))
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsSquishyTool", true)
	tool:SetAttribute("SlimeId", slimeDef.Id)
	tool:SetAttribute("SquishyLevel", lvl)
	tool.GripPos = Vector3.new(0, -0.4, 0.2)

	local scale = 0.72
	local radius = 1.65 * scale

	local prebuiltBrainrot: Model? = nil
	if isBrainrot then
		local modelIdx = (slimeDef :: any).BrainrotModelIndex or numId
		prebuiltBrainrot = PrebuiltLoader.CloneNormalizedTemplate("Brainrots", slimeDef.Name or modelIdx, 2.4 * scale, false)
			or PrebuiltLoader.CloneNormalizedTemplate("Brainrots", modelIdx, 2.4 * scale, false)
	end

	local handle: BasePart
	if prebuiltBrainrot then
		handle = prebuiltBrainrot.PrimaryPart or makePart({
			Name = "Handle",
			Shape = Enum.PartType.Block,
			Material = Enum.Material.SmoothPlastic,
			Color = slimeDef.Color,
			Size = Vector3.new(2.2 * scale, 2.6 * scale, 2.2 * scale),
			Transparency = 1,
			Anchored = false,
			CanCollide = false,
		})
		handle.Name = "Handle"
		handle.Anchored = false
		handle.CanCollide = false
		handle.Parent = tool
		for _, desc in ipairs(prebuiltBrainrot:GetDescendants()) do
			if desc:IsA("BasePart") and desc ~= handle then
				desc.Anchored = false
				desc.CanCollide = false
				weldTo(handle, desc)
			end
		end
		prebuiltBrainrot.Parent = tool
	else
		handle = makePart({
			Name = "Handle",
			Shape = if isBrainrot then Enum.PartType.Block else Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Reflectance = 0.15,
			Color = slimeDef.Color,
			Size = if isBrainrot then Vector3.new(2.2 * scale, 2.6 * scale, 2.2 * scale) else Vector3.new(radius * 2, radius * 1.85, radius * 2),
			Transparency = if isBrainrot then 1 else 0,
			Anchored = false,
			CanCollide = false,
			Parent = tool,
		})

		if not isBrainrot then
			addFaceToBody(handle, tool, radius * 0.95, scale, false)
		end
		addSpeciesFeatures(handle, tool, slimeDef, radius, scale, false)
	end

	addRarityParticles(handle, slimeDef.Color, slimeDef.SecondaryColor, 6)

	return tool
end

-- Creates a Live Roaming 3D Hatched Brainrot / Squishy inside the player's Fenced Pen,
-- scaling by BOTH its Stage Hatch Size (1.0x in Stage 1 up to 3.2x in Stage 8) AND its Level (Lv.1-Lv.15)!
function SquishyBuilder.CreateHatchedSquishy(
	slimeDef: SlimeData.SlimeDef,
	posOrLevel: any,
	maybeGelTier: any?,
	maybeLevel: number?,
	customScale: number?
): Model
	local position = if typeof(posOrLevel) == "Vector3" then posOrLevel else Vector3.new(0, 0, 0)
	local lvl = if typeof(posOrLevel) == "number" then posOrLevel else (maybeLevel or 1)
	local tier = 1
	local finalScale = customScale
	if typeof(maybeGelTier) == "number" then
		if maybeGelTier > 0 and maybeGelTier < 1.0 and not finalScale then
			finalScale = maybeGelTier
			tier = 1
		else
			tier = math.floor(maybeGelTier)
		end
	end
	local numId = tonumber(slimeDef.Id) or 1
	local stageNum = math.clamp(tonumber(slimeDef.Level) or 1, 1, 8)
	local stageHatchScale = if SlimeData.GetStageHatchScale
		then SlimeData.GetStageHatchScale(stageNum)
		else (1.0 + (stageNum - 1) * 0.22)
	local levelScaleBoost = (1 + math.min(0.85, (lvl - 1) * 0.11)) * stageHatchScale
	local scale = (if slimeDef.IsBoss then 1.15 else 1.0)
	local radius = 2.05 * scale

	local outerColor = if tier == 2
		then Color3.fromRGB(255, 215, 55)
		elseif tier >= 3 then Color3.fromHSV((numId * 0.11) % 1, 0.85, 1)
		else slimeDef.Color

	local isBrainrot = numId <= 35 or (slimeDef :: any).IsBrainrot == true
	local model: Model
	local body: BasePart
	local prebuiltBrainrot: Model? = nil

	if isBrainrot then
		local modelIdx = (slimeDef :: any).BrainrotModelIndex or numId
		prebuiltBrainrot = PrebuiltLoader.CloneNormalizedTemplate("Brainrots", slimeDef.Name or modelIdx, 4.2 * levelScaleBoost, false)
			or PrebuiltLoader.CloneNormalizedTemplate("Brainrots", modelIdx, 4.2 * levelScaleBoost, false)
	end

	if prebuiltBrainrot then
		model = prebuiltBrainrot
		model.Name = "Squishy_" .. tostring(slimeDef.Id)
		body = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") or Instance.new("Part")
		body.Name = "JellyBody"
		body.Anchored = true
		body.CanCollide = false
		model.PrimaryPart = body
		model:PivotTo(CFrame.new(position + Vector3.new(0, 1.3 * scale * levelScaleBoost, 0)))
		attachCollectiblePopGlow(model, body, outerColor, slimeDef.SecondaryColor, 12, 1.35)
	else
		model = Instance.new("Model")
		model.Name = "Squishy_" .. tostring(slimeDef.Id)

		body = makePart({
			Name = "JellyBody",
			Shape = if isBrainrot then Enum.PartType.Block else Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Reflectance = if tier >= 2 or lvl >= 3 then 0.28 else 0.14,
			Color = outerColor,
			Transparency = if isBrainrot then 1 else 0.04,
			Size = if isBrainrot then Vector3.new(2.2 * scale, 2.6 * scale, 2.2 * scale) else Vector3.new(radius * 2, radius * 1.82, radius * 2),
			Position = position + Vector3.new(0, if isBrainrot then 1.3 * scale else radius * 0.9, 0),
			Parent = model,
		})
		body.PivotOffset = CFrame.new(0, if isBrainrot then -1.3 * scale else -radius * 0.9, 0)
		model.PrimaryPart = body
		if not isBrainrot then
			addFaceToBody(body, model, radius * 0.96, scale, true)
		end
		addSpeciesFeatures(body, model, slimeDef, radius, scale, true)
		attachCollectiblePopGlow(model, body, outerColor, slimeDef.SecondaryColor, 12, 1.35)

		-- Physically scale the procedural 3D model by StageHatchScale * LevelScaleBoost!
		if levelScaleBoost > 1.01 then
			pcall(function()
				model:ScaleTo(levelScaleBoost)
			end)
		end
	end

	model:SetAttribute("SlimeId", slimeDef.Id)
	model:SetAttribute("SquishyLevel", lvl)
	model:SetAttribute("StageHatchScale", stageHatchScale)
	model:SetAttribute("ScaleMultiplier", levelScaleBoost)

	local cps = SlimeData.GetSquishyCoinsPerSec(slimeDef, lvl)
	local upgCost = SlimeData.GetSquishyUpgradeCost(slimeDef, lvl)

	local upgAtt = Instance.new("Attachment")
	upgAtt.Name = "UpgradePromptAttachment"
	upgAtt.Position = Vector3.new(0, 1.35 * scale * levelScaleBoost, 0)
	upgAtt.Parent = body

	local upgPrompt = Instance.new("ProximityPrompt")
	upgPrompt.Name = "PedestalUpgradePrompt"
	upgPrompt.ActionText = string.format("🌱 Level Up Brainrot -> Lv.%d ($%s)", lvl + 1, formatNumber(upgCost))
	upgPrompt.ObjectText = string.format("%s [Lv.%d • Stage %d %.1fx Size] (+$%s/s)", slimeDef.Name, lvl, stageNum, levelScaleBoost, formatNumber(cps))
	upgPrompt.HoldDuration = 0
	upgPrompt.MaxActivationDistance = 14
	upgPrompt.RequiresLineOfSight = false
	upgPrompt.KeyboardKeyCode = Enum.KeyCode.E
	upgPrompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	upgPrompt.Parent = upgAtt

	local bb = Instance.new("BillboardGui")
	bb.Name = "SquishyTag"
	bb.Size = UDim2.new(5.4, 0, 1.85, 0)
	bb.StudsOffset = Vector3.new(0, (radius * levelScaleBoost) + 2.2, 0)
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
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
	nameLabel.Text = string.format("%s%s [Lv.%d]", if lvl >= 2 then "👑 " else "🧠 ", slimeDef.Name, lvl)
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
	rarityLabel.Text = string.format("%s • Stage %d (%.1fx Size)", slimeDef.Rarity, stageNum, levelScaleBoost)
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

	if finalScale and finalScale > 0 and math.abs(finalScale - 1.0) > 0.01 then
		pcall(function()
			model:ScaleTo(model:GetScale() * finalScale)
		end)
	end

	return model
end

-- Creates a Colossal 18-21 Stud 3D Boss Guardian with full sculpted face, fangs, horns/wings/fins, and "Zzz" / "!!" emote!
function SquishyBuilder.CreateGuardianModel(gDefOrName: any, maybeColor: Color3?, maybeRadius: number?): Model
	local guardianDef: any
	if type(gDefOrName) == "table" then
		guardianDef = gDefOrName
	else
		guardianDef = {
			Id = tostring(gDefOrName or "Boss"),
			Name = tostring(gDefOrName or "Boss Guardian"),
			Title = "👑 BIOME BOSS",
			Level = 1,
			Style = "Monster",
			PrimaryColor = maybeColor or Color3.fromRGB(220, 80, 90),
			AccentColor = Color3.fromRGB(255, 215, 70),
			HomePosition = Vector3.new(0, 0, 0),
			PatrolRadius = maybeRadius or 22,
		}
	end

	local pos = guardianDef.HomePosition or guardianDef.Center or Vector3.new(0, 0, 0)
	local s = 1.45
	local lvlNum = tonumber(guardianDef.Level) or 1
	local pColor = guardianDef.PrimaryColor or Color3.fromRGB(215, 75, 85)
	local aColor = guardianDef.AccentColor or Color3.fromRGB(255, 215, 70)

	local model = Instance.new("Model")
	model.Name = "Guardian_" .. tostring(guardianDef.Id)

	local torso = makePart({
		Name = "Body",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.14,
		Color = pColor,
		Size = Vector3.new(8.2 * s, 7.4 * s, 8.6 * s),
		Position = pos + Vector3.new(0, 3.7 * s, 0),
		Parent = model,
	})
	torso.PivotOffset = CFrame.new(0, -3.7 * s, 0)
	model.PrimaryPart = torso

	-- Belly Patch
	makePart({
		Name = "BellyPatch",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = pColor:Lerp(Color3.fromRGB(255, 252, 245), 0.55),
		Size = Vector3.new(5.6 * s, 5.2 * s, 2.4 * s),
		CFrame = torso.CFrame * CFrame.new(0, -0.4 * s, -3.4 * s),
		Parent = model,
	})

	-- Sculpted Boss Head
	local head = makePart({
		Name = "Head",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = pColor,
		Size = Vector3.new(6.8 * s, 5.8 * s, 6.8 * s),
		CFrame = torso.CFrame * CFrame.new(0, 3.6 * s, -1.6 * s),
		Parent = model,
	})

	-- Boss Snout + Open Mouth + Blocky White Fangs
	makePart({
		Name = "BossSnout",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = pColor:Lerp(Color3.fromRGB(255, 255, 255), 0.18),
		Size = Vector3.new(4.4 * s, 2.5 * s, 3.2 * s),
		CFrame = head.CFrame * CFrame.new(0, -0.45 * s, -2.6 * s),
		Parent = model,
	})
	makePart({
		Name = "BossMouth",
		Size = Vector3.new(3.2 * s, 1.1 * s, 1.4 * s),
		CFrame = head.CFrame * CFrame.new(0, -1.1 * s, -2.9 * s),
		Color = Color3.fromRGB(165, 35, 50),
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})
	for _, fangX in ipairs({ -1.0, -0.35, 0.35, 1.0 }) do
		makePart({
			Name = "BossFang",
			Size = Vector3.new(0.45 * s, 0.85 * s, 0.45 * s),
			CFrame = head.CFrame * CFrame.new(fangX * s, -0.82 * s, -3.4 * s),
			Color = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.SmoothPlastic,
			Parent = model,
		})
	end

	-- Fierce Glowing Eyes + Angled Boss Eyebrows
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "BossEye_" .. side,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 240, 95),
			Size = Vector3.new(1.35 * s, 1.35 * s, 0.75 * s),
			CFrame = head.CFrame * CFrame.new(side * 1.45 * s, 0.65 * s, -2.95 * s),
			Parent = model,
		})
		makePart({
			Name = "BossPupil_" .. side,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(18, 18, 24),
			Size = Vector3.new(0.72 * s, 0.82 * s, 0.65 * s),
			CFrame = head.CFrame * CFrame.new(side * 1.45 * s, 0.65 * s, -3.15 * s),
			Parent = model,
		})
		makePart({
			Name = "BossBrow_" .. side,
			Size = Vector3.new(1.85 * s, 0.48 * s, 0.85 * s),
			CFrame = head.CFrame * CFrame.new(side * 1.45 * s, 1.45 * s, -2.95 * s) * CFrame.Angles(0, 0, math.rad(-side * 18)),
			Color = aColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = model,
		})
	end

	-- Muscular Boss Arms / Claws & Stomping Feet
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			Name = "BossArm_" .. side,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = pColor,
			Size = Vector3.new(2.4 * s, 3.4 * s, 2.6 * s),
			CFrame = torso.CFrame * CFrame.new(side * 4.2 * s, 0.4 * s, -1.5 * s) * CFrame.Angles(math.rad(-25), 0, math.rad(-side * 20)),
			Parent = model,
		})
		makePart({
			Name = "BossFoot_" .. side,
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.SmoothPlastic,
			Color = aColor,
			Size = Vector3.new(2.8 * s, 1.8 * s, 3.6 * s),
			CFrame = torso.CFrame * CFrame.new(side * 2.5 * s, -3.1 * s, -1.2 * s),
			Parent = model,
		})
		-- Curved Boss Horns
		makePart({
			Name = "BossHorn_" .. side,
			Material = Enum.Material.Neon,
			Color = aColor,
			Size = Vector3.new(1.1 * s, 3.2 * s, 1.1 * s),
			CFrame = head.CFrame * CFrame.new(side * 2.2 * s, 2.6 * s, -0.4 * s) * CFrame.Angles(math.rad(-12), 0, math.rad(-side * 26)),
			Parent = model,
		})
	end

	-- Royal Boss Crown on top of head
	makePart({
		Name = "BossCrown",
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 215, 55),
		Size = Vector3.new(1.4 * s, 3.2 * s, 3.2 * s),
		CFrame = head.CFrame * CFrame.new(0, 3.1 * s, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = model,
	})

	model:SetAttribute("GuardianId", guardianDef.Id)
	model:SetAttribute("Level", lvlNum)

	-- Weld all sub-parts to torso so PivotTo only moves 1 Anchored PrimaryPart instead of 25 anchored parts
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") and desc ~= torso then
			desc.Anchored = false
			desc.CanCollide = false
			desc.Massless = true
			weldTo(torso, desc)
		end
	end

	addRarityParticles(torso, pColor, aColor, 18)

	local sleepBB = Instance.new("BillboardGui")
	sleepBB.Name = "SleepEmoteGui"
	sleepBB.Size = UDim2.new(3.2, 0, 3.2, 0)
	sleepBB.StudsOffset = Vector3.new(-3.4 * s, 5.2 * s, 0)
	sleepBB.AlwaysOnTop = false
	sleepBB.LightInfluence = 0
	sleepBB.MaxDistance = 65
	sleepBB.Parent = torso

	local sleepText = Instance.new("TextLabel")
	sleepText.Name = "StatusLabel"
	sleepText.Size = UDim2.new(1, 0, 1, 0)
	sleepText.BackgroundTransparency = 1
	sleepText.Font = Enum.Font.FredokaOne
	sleepText.TextScaled = true
	sleepText.TextColor3 = Color3.fromRGB(65, 225, 255)
	sleepText.TextStrokeColor3 = Color3.fromRGB(15, 25, 45)
	sleepText.TextStrokeTransparency = 0
	sleepText.Text = "Zzz"
	sleepText.Parent = sleepBB

	local bb = Instance.new("BillboardGui")
	bb.Name = "GuardianTag"
	bb.Size = UDim2.new(9.5, 0, 2.2, 0)
	bb.StudsOffset = Vector3.new(0, 7.2 * s, 0)
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.MaxDistance = 75
	bb.Parent = torso

	local title = Instance.new("TextLabel")
	title.Name = "NameLabel"
	title.Size = UDim2.new(1, 0, 1, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 220, 65)
	title.TextStrokeTransparency = 0.08
	title.Text = (guardianDef.Title or "👑 BOSS") .. ": " .. tostring(guardianDef.Name)
	title.Parent = bb

	return model
end

-- Attaches a 3D Squishy Morph costume + Tiny Size toggle to a player's character
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

	local morphScale = if tinyMode then 0.55 else 1.15
	local radius = 2.0 * morphScale
	local costume = Instance.new("Model")
	costume.Name = "SquishyMorphCostume"
	local isBrainrot = (tonumber(slimeDef.Id) or 1) <= 35 or (slimeDef :: any).IsBrainrot == true
	local body = makePart({
		Name = "MorphBody",
		Shape = if isBrainrot then Enum.PartType.Block else Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = slimeDef.Color,
		Size = if isBrainrot then Vector3.new(2.2 * morphScale, 2.6 * morphScale, 2.2 * morphScale) else Vector3.new(radius * 2, radius * 1.85, radius * 2),
		Transparency = if isBrainrot then 1 else 0,
		CFrame = hrp.CFrame,
		Anchored = false,
		CanCollide = false,
		Parent = costume,
	})
	weldTo(hrp, body)
	if not isBrainrot then
		addFaceToBody(body, costume, radius * 0.96, morphScale, false)
	end
	addSpeciesFeatures(body, costume, slimeDef, radius, morphScale, false)
	costume.Parent = character
end

return SquishyBuilder

