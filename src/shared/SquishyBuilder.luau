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

-- Builds unmistakable 3D Brainrot Sculptures for all 35 Hatchable Brainrots (#1-#35):
-- Tralalero Shark in Blue Sneakers, Bombardiro Twin-Propeller Bomber Croc, Tung Tung Wooden Log + Baseball Bat,
-- Lirili Cactus Elephant in Sandals, Patapim Forest Troll, Cappuccino Katana Cup, Chimpanzini Banana Monkey,
-- La Vaca Saturno Cow, Ballerina Tutu Cup, Frigo Fridge Camel, Gusini Rocket Goose, Orangutini Pineapple, Boneca Tire Frog, etc.
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
	local bType = (slimeDef :: any).BrainrotType or ""

	local function attach(p: Part): Part
		p.Anchored = anchored
		if not anchored then
			weldTo(body, p)
		end
		return p
	end

	-- Determine archetype from BrainrotType, Name, or ID (#1-#35)
	local archetype = bType
	if archetype == "" then
		if string.find(nameLower, "tralal") or string.find(nameLower, "trulim") or numId == 1 or numId == 12 or numId == 31 then
			archetype = "Tralalero"
		elseif string.find(nameLower, "bombard") or string.find(nameLower, "crocod") or numId == 9 or numId == 27 or numId == 32 then
			archetype = "Bombardiro"
		elseif string.find(nameLower, "tung") or string.find(nameLower, "sahur") or numId == 13 or numId == 28 or numId == 34 then
			archetype = "TungTung"
		elseif string.find(nameLower, "liril") or string.find(nameLower, "cacto") or numId == 2 or numId == 24 then
			archetype = "Lirili"
		elseif string.find(nameLower, "patapim") or string.find(nameLower, "bicus") or numId == 4 or numId == 22 then
			archetype = "Patapim"
		elseif string.find(nameLower, "assassin") or string.find(nameLower, "cappuccin") and not string.find(nameLower, "ballerina") or numId == 14 then
			archetype = "Cappuccino"
		elseif string.find(nameLower, "chimpanz") or string.find(nameLower, "banan") or numId == 7 then
			archetype = "Chimpanzini"
		elseif string.find(nameLower, "saturn") or string.find(nameLower, "vaca") or numId == 21 or numId == 33 then
			archetype = "Saturno"
		elseif string.find(nameLower, "ballerina") or numId == 5 then
			archetype = "Ballerina"
		elseif string.find(nameLower, "frigo") or string.find(nameLower, "camel") or numId == 8 then
			archetype = "Frigo"
		elseif string.find(nameLower, "gusini") or string.find(nameLower, "bombomb") or numId == 10 or numId == 26 then
			archetype = "Gusini"
		elseif string.find(nameLower, "orangut") or string.find(nameLower, "ananas") or numId == 16 then
			archetype = "Orangutini"
		elseif string.find(nameLower, "boneca") or string.find(nameLower, "ambalabu") or numId == 15 then
			archetype = "Boneca"
		elseif string.find(nameLower, "glorbo") or string.find(nameLower, "burbal") or numId == 6 or numId == 11 then
			archetype = "Glorbo"
		elseif string.find(nameLower, "trippi") or string.find(nameLower, "crab") or numId == 3 or numId == 25 then
			archetype = "Trippi"
		elseif string.find(nameLower, "giraf") or string.find(nameLower, "talpa") or numId == 19 or numId == 23 then
			archetype = "Girafa"
		elseif string.find(nameLower, "skibidi") or string.find(nameLower, "garam") or string.find(nameLower, "madu") or numId == 17 or numId == 18 or numId == 29 then
			archetype = "Skibidi"
		elseif string.find(nameLower, "maxwell") or numId == 20 then
			archetype = "Maxwell"
		else
			local pool = {
				"Tralalero", "Lirili", "Trippi", "Patapim", "Ballerina",
				"Glorbo", "Chimpanzini", "Frigo", "Bombardiro", "Gusini",
				"TungTung", "Cappuccino", "Boneca", "Orangutini", "Saturno",
			}
			archetype = pool[((numId - 1) % #pool) + 1]
		end
	end

	if archetype == "Tralalero" then
		-- Shark Dorsal Fin, Shark Snout + Teeth, Tail Fin, and 3 Iconic Blue Nike Sneakers!
		attach(makePart({
			Name = "SharkSnout",
			Shape = Enum.PartType.Ball,
			Color = slimeDef.Color,
			Size = Vector3.new(radius * 1.15, radius * 0.72, radius * 0.95),
			CFrame = center * CFrame.new(0, -0.05 * scale, -radius * 0.95),
			Parent = model,
		}))
		attach(makePart({
			Name = "SharkDorsalFin",
			Color = slimeDef.Color,
			Size = Vector3.new(0.38 * scale, radius * 1.15, radius * 0.95),
			CFrame = center * CFrame.new(0, radius * 1.05, 0.15 * scale) * CFrame.Angles(math.rad(-22), 0, 0),
			Parent = model,
		}))
		attach(makePart({
			Name = "SharkTailFin",
			Color = slimeDef.Color,
			Size = Vector3.new(0.35 * scale, radius * 1.1, radius * 0.85),
			CFrame = center * CFrame.new(0, 0.1 * scale, radius * 1.08) * CFrame.Angles(math.rad(18), 0, 0),
			Parent = model,
		}))
		-- 3 Blue Sneakers (Left, Right, Rear Tail Leg)
		local sneakerOffsets = {
			Vector3.new(-radius * 0.68, -radius * 0.85, -radius * 0.35),
			Vector3.new(radius * 0.68, -radius * 0.85, -radius * 0.35),
			Vector3.new(0, -radius * 0.85, radius * 0.65),
		}
		for idx, off in ipairs(sneakerOffsets) do
			local shoe = attach(makePart({
				Name = "BlueSneaker_" .. idx,
				Color = Color3.fromRGB(28, 125, 255),
				Size = Vector3.new(0.82 * scale, 0.52 * scale, 1.35 * scale),
				CFrame = center * CFrame.new(off),
				Parent = model,
			}))
			attach(makePart({
				Name = "SneakerSole_" .. idx,
				Color = Color3.fromRGB(255, 255, 255),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.88 * scale, 0.22 * scale, 1.42 * scale),
				CFrame = shoe.CFrame * CFrame.new(0, -0.24 * scale, 0),
				Parent = model,
			}))
		end
	elseif archetype == "Bombardiro" then
		-- Alligator Snout + Twin Bomber Airplane Wings + Twin Propellers + Bomb Belly!
		attach(makePart({
			Name = "CrocSnout",
			Color = slimeDef.Color,
			Size = Vector3.new(radius * 1.1, radius * 0.58, radius * 1.35),
			CFrame = center * CFrame.new(0, -0.12 * scale, -radius * 1.05),
			Parent = model,
		}))
		attach(makePart({
			Name = "BomberWings",
			Color = Color3.fromRGB(145, 158, 142),
			Material = Enum.Material.Metal,
			Size = Vector3.new(radius * 3.6, 0.28 * scale, radius * 1.05),
			CFrame = center * CFrame.new(0, 0.18 * scale, 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			local engine = attach(makePart({
				Name = "WingEngine_" .. side,
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(75, 82, 90),
				Material = Enum.Material.Metal,
				Size = Vector3.new(1.15 * scale, 0.72 * scale, 0.72 * scale),
				CFrame = center * CFrame.new(side * radius * 1.25, 0.05 * scale, -0.35 * scale) * CFrame.Angles(0, math.rad(90), 0),
				Parent = model,
			}))
			attach(makePart({
				Name = "PropellerBlade_" .. side,
				Color = Color3.fromRGB(255, 225, 75),
				Material = Enum.Material.Neon,
				Size = Vector3.new(1.35 * scale, 0.18 * scale, 0.14 * scale),
				CFrame = engine.CFrame * CFrame.new(0.62 * scale, 0, 0) * CFrame.Angles(math.rad(35), math.rad(90), 0),
				Parent = model,
			}))
		end
	elseif archetype == "TungTung" then
		-- Wooden Log Crown Ring + Held Wooden Baseball Bat!
		body.Material = Enum.Material.Wood
		attach(makePart({
			Name = "LogTopBark",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(198, 152, 96),
			Material = Enum.Material.WoodPlanks,
			Size = Vector3.new(0.45 * scale, radius * 1.55, radius * 1.55),
			CFrame = center * CFrame.new(0, radius * 0.84, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "BaseballBat",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(168, 108, 52),
			Material = Enum.Material.Wood,
			Size = Vector3.new(radius * 2.15, 0.58 * scale, 0.58 * scale),
			CFrame = center * CFrame.new(radius * 1.12, 0.25 * scale, -0.45 * scale) * CFrame.Angles(math.rad(25), 0, math.rad(72)),
			Parent = model,
		}))
	elseif archetype == "Lirili" then
		-- Cactus Elephant Ears, Curved Trunk, White Tusks & Desert Sandals!
		attach(makePart({
			Name = "ElephantTrunk",
			Shape = Enum.PartType.Cylinder,
			Color = slimeDef.Color,
			Size = Vector3.new(radius * 1.25, 0.58 * scale, 0.58 * scale),
			CFrame = center * CFrame.new(0, -0.15 * scale, -radius * 1.05) * CFrame.Angles(math.rad(25), math.rad(90), 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "CactusEar_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(68, 185, 82),
				Size = Vector3.new(0.42 * scale, 1.45 * scale, 1.15 * scale),
				CFrame = center * CFrame.new(side * radius * 1.05, 0.22 * scale, -0.1 * scale),
				Parent = model,
			}))
			attach(makePart({
				Name = "IvoryTusk_" .. side,
				Color = Color3.fromRGB(255, 252, 235),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.28 * scale, 0.28 * scale, 0.92 * scale),
				CFrame = center * CFrame.new(side * 0.52 * scale, -0.25 * scale, -radius * 1.05),
				Parent = model,
			}))
			attach(makePart({
				Name = "DesertSandal_" .. side,
				Color = Color3.fromRGB(142, 86, 44),
				Material = Enum.Material.Wood,
				Size = Vector3.new(0.88 * scale, 0.35 * scale, 1.38 * scale),
				CFrame = center * CFrame.new(side * radius * 0.58, -radius * 0.88, -0.15 * scale),
				Parent = model,
			}))
		end
	elseif archetype == "Cappuccino" or archetype == "Ballerina" then
		-- Porcelain Coffee Cup Rim, Frothy Foam Top, Handle, and Twin Katanas or Pink Tutu!
		attach(makePart({
			Name = "CoffeeCupRim",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(250, 248, 242),
			Size = Vector3.new(0.42 * scale, radius * 1.85, radius * 1.85),
			CFrame = center * CFrame.new(0, radius * 0.78, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
		attach(makePart({
			Name = "CappuccinoFoam",
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(215, 165, 115),
			Size = Vector3.new(radius * 1.55, 0.65 * scale, radius * 1.55),
			CFrame = center * CFrame.new(0, radius * 0.92, 0),
			Parent = model,
		}))
		if archetype == "Ballerina" then
			attach(makePart({
				Name = "PinkTutuSkirt",
				Shape = Enum.PartType.Cylinder,
				Color = Color3.fromRGB(255, 135, 205),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.38 * scale, radius * 2.55, radius * 2.55),
				CFrame = center * CFrame.new(0, -radius * 0.35, 0) * CFrame.Angles(0, 0, math.rad(90)),
				Parent = model,
			}))
		else
			for _, side in ipairs({ -1, 1 }) do
				attach(makePart({
					Name = "KatanaBlade_" .. side,
					Color = Color3.fromRGB(210, 235, 255),
					Material = Enum.Material.Neon,
					Size = Vector3.new(0.18 * scale, radius * 2.25, 0.28 * scale),
					CFrame = center * CFrame.new(0, 0.35 * scale, radius * 0.92) * CFrame.Angles(0, 0, math.rad(side * 38)),
					Parent = model,
				}))
			end
		end
	elseif archetype == "Chimpanzini" then
		-- 4 Yellow Banana Peel Petals around waist + Monkey Ears!
		for p = 0, 3 do
			local ang = math.rad(p * 90 + 45)
			attach(makePart({
				Name = "BananaPeel_" .. p,
				Color = Color3.fromRGB(255, 225, 55),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.85 * scale, radius * 1.15, 0.32 * scale),
				CFrame = center * CFrame.Angles(0, ang, 0) * CFrame.new(0, -radius * 0.25, -radius * 0.95) * CFrame.Angles(math.rad(-32), 0, 0),
				Parent = model,
			}))
		end
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "MonkeyEar_" .. side,
				Shape = Enum.PartType.Ball,
				Color = Color3.fromRGB(138, 86, 48),
				Size = Vector3.new(0.35 * scale, 0.92 * scale, 0.92 * scale),
				CFrame = center * CFrame.new(side * radius * 0.98, 0.28 * scale, 0),
				Parent = model,
			}))
		end
	elseif archetype == "Saturno" then
		-- La Vaca Saturno Saturnita: Cow Horns + Glowing Tilted Planetary Saturn Ring!
		attach(makePart({
			Name = "SaturnPlanetaryRing",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(255, 215, 85),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.28 * scale, radius * 3.1, radius * 3.1),
			CFrame = center * CFrame.Angles(math.rad(18), 0, math.rad(72)),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "SaturnHorn_" .. side,
				Color = Color3.fromRGB(255, 240, 145),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.42 * scale, 1.05 * scale, 0.42 * scale),
				CFrame = center * CFrame.new(side * radius * 0.58, radius * 0.92, 0) * CFrame.Angles(0, 0, math.rad(-side * 24)),
				Parent = model,
			}))
		end
	elseif archetype == "Frigo" then
		-- Fridge Camel: Twin Humps + Metallic Refrigerator Door & Handle!
		attach(makePart({
			Name = "FridgeDoorFront",
			Color = Color3.fromRGB(225, 235, 245),
			Material = Enum.Material.Metal,
			Size = Vector3.new(radius * 1.25, radius * 1.35, 0.35 * scale),
			CFrame = center * CFrame.new(0, -0.1 * scale, -radius * 0.88),
			Parent = model,
		}))
		attach(makePart({
			Name = "FridgeHandle",
			Color = Color3.fromRGB(85, 225, 255),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.22 * scale, radius * 0.95, 0.25 * scale),
			CFrame = center * CFrame.new(radius * 0.45, -0.1 * scale, -radius * 1.05),
			Parent = model,
		}))
	elseif archetype == "Gusini" then
		-- Bombombini Gusini: Orange Duck/Goose Bill + Jet Wings + Twin Rockets!
		attach(makePart({
			Name = "GooseBill",
			Color = Color3.fromRGB(255, 155, 35),
			Material = Enum.Material.Neon,
			Size = Vector3.new(0.95 * scale, 0.38 * scale, 1.15 * scale),
			CFrame = center * CFrame.new(0, -0.05 * scale, -radius * 1.05),
			Parent = model,
		}))
		attach(makePart({
			Name = "GooseJetWings",
			Color = Color3.fromRGB(235, 240, 248),
			Size = Vector3.new(radius * 3.2, 0.26 * scale, radius * 0.92),
			CFrame = center * CFrame.new(0, 0.12 * scale, 0),
			Parent = model,
		}))
	elseif archetype == "Boneca" then
		-- Boneca Ambalabu: Black Rubber Tire Ring around body + Top Frog Eyes!
		attach(makePart({
			Name = "RubberTireTread",
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(32, 34, 38),
			Material = Enum.Material.Slate,
			Size = Vector3.new(0.95 * scale, radius * 2.35, radius * 2.35),
			CFrame = center * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		}))
	elseif archetype == "Orangutini" then
		-- Orangutini Ananasini: Spiky Green Pineapple Crown + Golden Arms!
		for leaf = 0, 5 do
			local ang = math.rad(leaf * 60)
			attach(makePart({
				Name = "PineappleLeaf_" .. leaf,
				Color = Color3.fromRGB(55, 215, 85),
				Material = Enum.Material.Neon,
				Size = Vector3.new(0.45 * scale, 1.35 * scale, 0.28 * scale),
				CFrame = center * CFrame.Angles(0, ang, 0) * CFrame.new(0, radius * 1.05, -0.35 * scale) * CFrame.Angles(math.rad(-28), 0, 0),
				Parent = model,
			}))
		end
	else
		-- Patapim / Glorbo / Trippi / Girafa / Maxwell / Skibidi: Bulbous Brainrot Crest + Glowing Halo Horns & Stomping Feet!
		attach(makePart({
			Name = "BrainrotCrest",
			Shape = Enum.PartType.Ball,
			Color = slimeDef.SecondaryColor,
			Material = Enum.Material.Neon,
			Size = Vector3.new(radius * 1.05, 0.75 * scale, radius * 1.05),
			CFrame = center * CFrame.new(0, radius * 0.92, 0),
			Parent = model,
		}))
		for _, side in ipairs({ -1, 1 }) do
			attach(makePart({
				Name = "BrainrotStompFoot_" .. side,
				Color = slimeDef.SecondaryColor,
				Size = Vector3.new(0.85 * scale, 0.45 * scale, 1.25 * scale),
				CFrame = center * CFrame.new(side * radius * 0.62, -radius * 0.86, -0.2 * scale),
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
	local isBrainrot = (tonumber(slimeDef.Id) or 1) <= 35

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

-- Creates a Live Roaming 3D Hatched Brainrot / Squishy inside the player's Fenced Pen,
-- scaling by BOTH its Stage Hatch Size (1.0x in Stage 1 up to 3.2x in Stage 8) AND its Level (Lv.1-Lv.15)!
function SquishyBuilder.CreateHatchedSquishy(
	slimeDef: SlimeData.SlimeDef,
	posOrLevel: any,
	maybeGelTier: number?,
	maybeLevel: number?
): Model
	local position = if typeof(posOrLevel) == "Vector3" then posOrLevel else Vector3.new(0, 0, 0)
	local lvl = if typeof(posOrLevel) == "number" then posOrLevel else (maybeLevel or 1)
	local tier = maybeGelTier or 1
	local numId = tonumber(slimeDef.Id) or 1
	local stageNum = math.clamp(tonumber(slimeDef.Level) or 1, 1, 8)
	local stageHatchScale = if SlimeData.GetStageHatchScale
		then SlimeData.GetStageHatchScale(stageNum)
		else (1.0 + (stageNum - 1) * 0.22)
	local levelScaleBoost = (1 + math.min(0.85, (lvl - 1) * 0.11)) * stageHatchScale
	local scale = (if slimeDef.IsBoss then 1.15 else 1.0)
	local radius = 2.05 * scale

	local model = Instance.new("Model")
	model.Name = "Squishy_" .. tostring(slimeDef.Id)
	local outerColor = if tier == 2
		then Color3.fromRGB(255, 215, 55)
		elseif tier >= 3 then Color3.fromHSV((numId * 0.11) % 1, 0.85, 1)
		else slimeDef.Color

	local body = makePart({
		Name = "JellyBody",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = if tier >= 2 or lvl >= 3 then 0.28 else 0.14,
		Color = outerColor,
		Transparency = 0.04,
		Size = Vector3.new(radius * 2, radius * 1.82, radius * 2),
		Position = position + Vector3.new(0, radius * 0.9, 0),
		Parent = model,
	})
	body.PivotOffset = CFrame.new(0, -radius * 0.9, 0)
	model.PrimaryPart = body
	addFaceToBody(body, model, radius * 0.96, scale, true)
	addSpeciesFeatures(body, model, slimeDef, radius, scale, true)
	attachCollectiblePopGlow(model, body, outerColor, slimeDef.SecondaryColor, 12, 1.35)

	-- Add 3D Golden/Rainbow Evolution Crown & Aura Ring when leveled up (Lv.2+)!
	if lvl >= 2 then
		local crownColor = if lvl >= 5 then Color3.fromRGB(85, 245, 255) else Color3.fromRGB(255, 215, 45)
		makePart({
			Name = "LevelCrown",
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = crownColor,
			Size = Vector3.new(0.45 * scale, 1.85 * scale, 1.85 * scale),
			CFrame = body.CFrame * CFrame.new(0, radius * 0.95, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Parent = model,
		})
	end

	-- Physically scale the 3D Brainrot model by StageHatchScale * LevelScaleBoost!
	if levelScaleBoost > 1.01 then
		pcall(function()
			model:ScaleTo(levelScaleBoost)
		end)
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
	local body = makePart({
		Name = "MorphBody",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.SmoothPlastic,
		Color = slimeDef.Color,
		Size = Vector3.new(radius * 2, radius * 1.85, radius * 2),
		CFrame = hrp.CFrame,
		Anchored = false,
		CanCollide = false,
		Parent = costume,
	})
	weldTo(hrp, body)
	addFaceToBody(body, costume, radius * 0.96, morphScale, false)
	addSpeciesFeatures(body, costume, slimeDef, radius, morphScale, false)
	costume.Parent = character
end

return SquishyBuilder

