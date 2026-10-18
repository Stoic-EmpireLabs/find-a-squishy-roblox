--!strict
--[[
	CreatorStoreGameplayKits.luau
	Dedicated loader & manager for Creator Store Gameplay Kits, Obby Kits,
	Custom Inventory Systems, and User-Acquired Creator Store Inventory Assets:
	  * 137461628889541: "Brainrot Pack [150+]" (User Inventory - 150+ 3D Brainrot Characters!)
	  * 17253530672: "rainbow obby" (User Inventory)
	  * 138151705692565: "Tung Tung Tung Sahur" (User Inventory)
	  * 74456202552253: "KIT 1+ ESCAPE DEL TECLADO. CRÉDITOS A ANTHONY" (Primary User Gameplay Kit)
	  * 5352156968: "Time Played Leaderboard with Player Thumbnails" (User Inventory)
	  * 140042750673504: "Robux Donation Board" (User Inventory)
	  * 75354400953490: "Obby Gamepass" (User Inventory)
	  * 8588705960: "Planets for space tycoon" (User Inventory)
	  * 8645565937: "For Space Tycoon" (User Inventory)
	  * 16070143698: "*Fixed!* Space Tycoon" (User Inventory)
	  * Creator Store Gym Treadmills, Speed Simulator Kits, Obby Kits, Inventory & Pet Systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreatorStoreGameplayKits = {}

export type KitEntry = {
	AssetId: number,
	Name: string,
	Description: string,
	Category: string,
}

export type MapTemplateEntry = {
	AssetId: number,
	Name: string,
	Description: string,
	Category: string,
}

-- ========================================================================
-- MODULAR IMPORTED MAP ARCHITECTURE (ReplicatedStorage.Maps)
-- All 7 maps are imported into ReplicatedStorage.Maps for future versions.
-- Only the active primary map is spawned into Workspace.SquishyWorld!
-- ========================================================================
CreatorStoreGameplayKits.MAP_TEMPLATES = {
	StealAnEgg = {
		AssetId = 106206596734864,
		Name = "StealAnEgg",
		Description = "Steal An Egg (Active Primary Map for v1)",
		Category = "PrimaryMap",
	},
	EscapeDelTeclado = {
		AssetId = 74456202552253,
		Name = "EscapeDelTeclado",
		Description = "KIT 1+ ESCAPE DEL TECLADO. CRÉDITOS A ANTHONY (Integrated Map/Obby)",
		Category = "IntegratedMap",
	},
	WildWest = {
		AssetId = 128960889355821,
		Name = "WildWest",
		Description = "Wild West (Reserved for future version)",
		Category = "ReservedMap",
	},
	DarkseedTempest = {
		AssetId = 106334655417321,
		Name = "DarkseedTempest",
		Description = "Darkseed Tempest (Reserved for future version)",
		Category = "ReservedMap",
	},
	Revenant = {
		AssetId = 79500758678401,
		Name = "Revenant",
		Description = "Revenant (Reserved for future version)",
		Category = "ReservedMap",
	},
	Halloween = {
		AssetId = 113280926555931,
		Name = "HalloweenPack",
		Description = "Halloween Pack (Reserved for future version)",
		Category = "ReservedMap",
	},
	SpaceTycoon = {
		AssetId = 16070143698,
		Name = "SpaceTycoonFixed",
		Description = "*Fixed!* Space Tycoon (Reserved for future version)",
		Category = "ReservedMap",
	},
}

CreatorStoreGameplayKits.ACTIVE_MAP_KEY = "StealAnEgg"


CreatorStoreGameplayKits.KITS = {
	-- ========================================================================
	-- COMPLETE 23-ITEM CREATOR ACCOUNT INVENTORY (truststoic17 / 5317274154)
	-- ========================================================================
	-- 1. Squishies (Cute Slime Icons Pack - 65+ UI Icons)
	CuteSlimeIcons = {
		AssetId = 85631681185830,
		Name = "CuteSlimeIconsPack",
		Description = "Cute Slime Icons Pack - 65+ UI Icons",
		Category = "Squishies",
	},
	-- 2. Brainrots
	BrainrotPack150 = {
		AssetId = 137461628889541,
		Name = "BrainrotPack150",
		Description = "Brainrot Pack [150+]",
		Category = "Brainrots",
	},
	TungTungSahur = {
		AssetId = 138151705692565,
		Name = "TungTungTungSahur",
		Description = "Tung Tung Tung Sahur",
		Category = "Brainrots",
	},
	-- 3. Obby Models
	ObbyMaze = {
		AssetId = 18822017935,
		Name = "ObbyMaze",
		Description = "Obby Maze",
		Category = "Obby",
	},
	ObbyTrusses = {
		AssetId = 13811206538,
		Name = "ObbyTrusses",
		Description = "Obby Trusses",
		Category = "Obby",
	},
	EasyObbyPart = {
		AssetId = 18839533016,
		Name = "EasyObbyPart",
		Description = "Easy Obby Part",
		Category = "Obby",
	},
	SwingsObby = {
		AssetId = 8550093744,
		Name = "SwingsObby",
		Description = "Swings (OBBY)",
		Category = "Obby",
	},
	ObbyStairs = {
		AssetId = 13903889013,
		Name = "ObbyStairs",
		Description = "Obby Stairs",
		Category = "Obby",
	},
	TrussLadder = {
		AssetId = 6740491328,
		Name = "TrussLadder",
		Description = "Truss ladder",
		Category = "Obby",
	},
	RainbowObby = {
		AssetId = 17253530672,
		Name = "RainbowObbyKit",
		Description = "rainbow obby",
		Category = "Obby",
	},
	KeycapKeyboard = {
		AssetId = 100762364640472,
		Name = "KeycapKeyboard",
		Description = "Keycap/Keyboard",
		Category = "Obby",
	},
	EscapeDelTeclado = {
		AssetId = 74456202552253,
		Name = "Kit1_EscapeDelTeclado",
		Description = "KIT 1+ ESCAPE DEL TECLADO. CRÉDITOS A ANTHONY",
		Category = "GameplayKit",
	},
	-- 4. Stage Theme Packs & Landmarks
	WildWest = {
		AssetId = 128960889355821,
		Name = "WildWest",
		Description = "Wild West",
		Category = "StageLandmarks",
	},
	DarkseedTempest = {
		AssetId = 106334655417321,
		Name = "DarkseedTempest",
		Description = "Darkseed Tempest",
		Category = "StageLandmarks",
	},
	Revenant = {
		AssetId = 79500758678401,
		Name = "Revenant",
		Description = "Revenant",
		Category = "StageLandmarks",
	},
	HalloweenLeftovers = {
		AssetId = 120609134807240,
		Name = "HalloweenLeftovers",
		Description = "Halloween Leftovers",
		Category = "StageLandmarks",
	},
	HalloweenPack = {
		AssetId = 113280926555931,
		Name = "HalloweenPack",
		Description = "Halloween Pack",
		Category = "StageLandmarks",
	},
	SpaceTycoonPlanets = {
		AssetId = 8588705960,
		Name = "SpaceTycoonPlanets",
		Description = "Planets for space tycoon",
		Category = "WorldDecor",
	},
	ForSpaceTycoon = {
		AssetId = 8645565937,
		Name = "ForSpaceTycoon",
		Description = "For Space Tycoon",
		Category = "WorldDecor",
	},
	SpaceTycoonFixed = {
		AssetId = 16070143698,
		Name = "SpaceTycoonFixedKit",
		Description = "*Fixed!* Space Tycoon",
		Category = "WorldDecor",
	},
	-- 5. Safe Zone Boards & Gamepasses
	TimePlayedLeaderboard = {
		AssetId = 5352156968,
		Name = "TimePlayedLeaderboard",
		Description = "Time Played Leaderboard with Player Thumbnails",
		Category = "Leaderboard",
	},
	DonationBoard = {
		AssetId = 140042750673504,
		Name = "RobuxDonationBoard",
		Description = "Robux Donation Board",
		Category = "Monetization",
	},
	ObbyGamepass = {
		AssetId = 75354400953490,
		Name = "ObbyGamepassKit",
		Description = "Obby Gamepass",
		Category = "Monetization",
	},
	FusionCoil = {
		AssetId = 12124152417,
		Name = "FusionCoil",
		Description = "Fusion Coil Gamepass",
		Category = "Gamepass",
	},
	SpeedCoil = {
		AssetId = 11963709166,
		Name = "SpeedCoil",
		Description = "Speed Coil Gamepass",
		Category = "Gamepass",
	},
	GravityCoil = {
		AssetId = 11987698523,
		Name = "GravityCoil",
		Description = "Gravity Coil Gamepass",
		Category = "Gamepass",
	},
	RainbowCarpet = {
		AssetId = 17656533013,
		Name = "RainbowCarpet",
		Description = "Rainbow Magic Carpet Gamepass",
		Category = "Gamepass",
	},
	SquishiesPack = {
		AssetId = 133057503426008,
		Name = "SquishiesPack",
		Description = "Squishies ? Pack (3D Squishmallows)",
		Category = "Squishies",
	},
	ObbyKitByJakeDev = {
		AssetId = 140630477631657,
		Name = "ObbyKitByJakeDev",
		Description = "obby kit by jakedev",
		Category = "Obby",
	},

	-- 2. Creator Store Treadmill & Speed Simulator Kits
	TreadmillsBySystem = {
		AssetId = 135041830463035,
		Name = "TreadmillsBySystem",
		Description = "Treadmills by System",
		Category = "Treadmills",
	},
	TreadmillEppobot = {
		AssetId = 916218035,
		Name = "TreadmillEppobot",
		Description = "Treadmill",
		Category = "Treadmills",
	},
	TreadmillGibran = {
		AssetId = 85105314510723,
		Name = "TreadmillGibran",
		Description = "Treadmill by fasszk Xgibean",
		Category = "Treadmills",
	},
	SpeedSimulatorKit = {
		AssetId = 2892634734,
		Name = "SpeedSimulatorKit",
		Description = "Speed Simulator Kit",
		Category = "Speed",
	},
	Plus1SpeedKit = {
		AssetId = 90082960989487,
		Name = "Plus1SpeedKit",
		Description = "+1 Speed V1 Kit",
		Category = "Speed",
	},
	SpeedPads = {
		AssetId = 3069966915,
		Name = "SpeedPads",
		Description = "speed pads",
		Category = "Speed",
	},
	SpeedSimulatorStats = {
		AssetId = 6513517021,
		Name = "SpeedSimulatorStats",
		Description = "Speed Simulator leaderstats + Speed Script",
		Category = "Speed",
	},

	-- 3. Creator Store Obby Kits
	SquidsObbyKit = {
		AssetId = 6167660526,
		Name = "SquidsObbyKit",
		Description = "Squid's Obby Kit - Checkpoints, Saving, Skip Stage",
		Category = "Obby",
	},
	MangoObbyKit = {
		AssetId = 10552670412,
		Name = "MangoObbyKit",
		Description = "Fun Easy Obby Kit By Mango",
		Category = "Obby",
	},
	FullObbyKit = {
		AssetId = 13336839729,
		Name = "FullObbyKit",
		Description = "Full Obby Kit",
		Category = "Obby",
	},
	TheObbyKit = {
		AssetId = 7486694215,
		Name = "TheObbyKit",
		Description = "The Obby Kit",
		Category = "Obby",
	},
	DisappearingStairs = {
		AssetId = 101631320,
		Name = "DisappearingStairs",
		Description = "Disappearing Stairs",
		Category = "Obby",
	},
	RainbowDisappearingStairs = {
		AssetId = 108024745,
		Name = "RainbowDisappearingStairs",
		Description = "Rainbow Disappearing stairs",
		Category = "Obby",
	},
	LavaSpinner = {
		AssetId = 1923415134,
		Name = "LavaSpinner",
		Description = "Lava Obby Part Spinner",
		Category = "Obby",
	},

	-- 4. Creator Store Custom Inventory & Hotbar Kits
	CustomInventorySystem = {
		AssetId = 73852738603629,
		Name = "CustomInventorySystem",
		Description = "Full Custom Inventory System",
		Category = "Inventory",
	},
	CustomToolBar = {
		AssetId = 6946265038,
		Name = "CustomToolBar",
		Description = "Custom ToolBar / inventory",
		Category = "Inventory",
	},
	InventoryStatsDisplay = {
		AssetId = 6698392160,
		Name = "InventoryStatsDisplay",
		Description = "Inventory, Stats & Display Gui",
		Category = "Inventory",
	},
	PetSimXInventory = {
		AssetId = 8283159584,
		Name = "PetSimXInventory",
		Description = "Pet Simulator X Pets Inventory",
		Category = "Inventory",
	},

	-- 5. Creator Store Egg Hatching & Pet Kits
	PetSystemKit = {
		AssetId = 13508080541,
		Name = "PetSystemKit",
		Description = "Pet System Kit",
		Category = "PetSystem",
	},
	EggHatchingSystem1 = {
		AssetId = 13310071542,
		Name = "EggHatchingSystem1",
		Description = "Egg Hatching System!",
		Category = "Hatching",
	},
	EggPetsKit = {
		AssetId = 15850322685,
		Name = "EggPetsKit",
		Description = "Egg Pets KIT",
		Category = "PetSystem",
	},
	EggHatchingSystem2 = {
		AssetId = 139346914213003,
		Name = "EggHatchingSystem2",
		Description = "Egg Hatching System",
		Category = "Hatching",
	},
	SimulatorEggFree = {
		AssetId = 5637626609,
		Name = "SimulatorEggFree",
		Description = "Simulator Egg {FREE}",
		Category = "Hatching",
	},
} :: { [string]: KitEntry }

-- Ingests and organizes all Creator Store Gameplay Kits into ReplicatedStorage.Models.GameplayKits
function CreatorStoreGameplayKits.EnsureGameplayKits(customObjectFetcher: ((number) -> { Instance }?)?): Folder
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	if not modelsFolder then
		local f = Instance.new("Folder")
		f.Name = "Models"
		f.Parent = ReplicatedStorage
		modelsFolder = f
	end

	local kitsFolder = modelsFolder:FindFirstChild("GameplayKits")
	if not kitsFolder then
		local f = Instance.new("Folder")
		f.Name = "GameplayKits"
		f.Parent = modelsFolder
		kitsFolder = f
	end

	local totalIngested = 0

	for kitKey, kitInfo in pairs(CreatorStoreGameplayKits.KITS) do
		local existing = kitsFolder:FindFirstChild(kitInfo.Name)
		if not existing and customObjectFetcher then
			local ok, objs = pcall(customObjectFetcher, kitInfo.AssetId)
			if ok and objs and #objs > 0 then
				local container = Instance.new("Model")
				container.Name = kitInfo.Name
				container:SetAttribute("SourceAssetId", kitInfo.AssetId)
				container:SetAttribute("KitKey", kitKey)
				container:SetAttribute("Description", kitInfo.Description)
				container:SetAttribute("Category", kitInfo.Category)

				local childCount = 0
				for _, inst in ipairs(objs) do
					inst.Parent = container
					childCount += 1
				end

				-- Sanitize parts so they anchor safely and avoid unanchored physics explosions
				for _, desc in ipairs(container:GetDescendants()) do
					if desc:IsA("BasePart") then
						desc.Anchored = true
						desc.CanCollide = false
						desc.CanTouch = false
						desc.CanQuery = false
					end
				end

				container.Parent = kitsFolder
				totalIngested += 1

				-- Detailed diagnostic logging for Studio log
				print(string.format(
					"[CreatorStoreGameplayKits] Ingested Kit '%s' (AssetId=%d, Children=%d, Descendants=%d, Category=%s)",
					kitInfo.Name,
					kitInfo.AssetId,
					childCount,
					#container:GetDescendants(),
					kitInfo.Category
				))

				-- Specific inspection for user-requested Kit 1+ Escape del Teclado
				if kitInfo.AssetId == 74456202552253 then
					print("[KIT 1+ ESCAPE DEL TECLADO] Inspected children:")
					for _, ch in ipairs(container:GetChildren()) do
						print(string.format("  -> %s (%s)", ch.Name, ch.ClassName))
						for _, sub in ipairs(ch:GetChildren()) do
							print(string.format("     -> %s (%s)", sub.Name, sub.ClassName))
						end
					end
				end

				-- Check for monetization items (DeveloperProducts or GamePasses)
				if kitInfo.Category == "Monetization" then
					for _, desc in ipairs(container:GetDescendants()) do
						if desc:IsA("ValueBase") then
							local val = (desc :: any).Value
							print(string.format("[KIT MONETIZATION CHECK] Found %s '%s' = %s", desc.ClassName, desc.Name, tostring(val)))
						end
					end
				end
			else
				warn(string.format("[CreatorStoreGameplayKits] Failed to fetch AssetId=%d (%s)", kitInfo.AssetId, kitInfo.Name))
			end
		elseif existing then
			totalIngested += 1
		end
		task.wait(0.04)
	end

	kitsFolder:SetAttribute("IngestedKitCount", totalIngested)

	-- ========================================================================
	-- INGEST MODULAR MAP TEMPLATES INTO ReplicatedStorage.Maps
	-- All 7 maps are stored here for future game version spins!
	-- ========================================================================
	local mapsFolder = ReplicatedStorage:FindFirstChild("Maps")
	if not mapsFolder then
		local f = Instance.new("Folder")
		f.Name = "Maps"
		f.Parent = ReplicatedStorage
		mapsFolder = f
	end

	for mapKey, tmplInfo in pairs(CreatorStoreGameplayKits.MAP_TEMPLATES) do
		local existing = mapsFolder:FindFirstChild(tmplInfo.Name) or mapsFolder:FindFirstChild(mapKey)
		if not existing and customObjectFetcher then
			local ok, objs = pcall(customObjectFetcher, tmplInfo.AssetId)
			if ok and objs and #objs > 0 then
				local container = Instance.new("Model")
				container.Name = tmplInfo.Name
				container:SetAttribute("SourceAssetId", tmplInfo.AssetId)
				container:SetAttribute("MapKey", mapKey)
				container:SetAttribute("Description", tmplInfo.Description)
				container:SetAttribute("Category", tmplInfo.Category)

				local childCount = 0
				for _, inst in ipairs(objs) do
					inst.Parent = container
					childCount += 1
				end

				for _, desc in ipairs(container:GetDescendants()) do
					if desc:IsA("BasePart") then
						desc.Anchored = true
						desc.CanCollide = false
						desc.CanTouch = false
						desc.CanQuery = false
					end
				end

				container.Parent = mapsFolder
				local bbOk, _, bbSize = pcall(function()
					return container:GetBoundingBox()
				end)
				local sizeStr = if bbOk then string.format("(%.1f, %.1f, %.1f)", bbSize.X, bbSize.Y, bbSize.Z) else "unknown"

				print(string.format(
					"[CreatorStoreGameplayKits] Ingested Map Template '%s' (Key=%s, AssetId=%d, Children=%d, Descendants=%d, BoundingBox=%s)",
					tmplInfo.Name,
					mapKey,
					tmplInfo.AssetId,
					childCount,
					#container:GetDescendants(),
					sizeStr
				))
			else
				warn(string.format("[CreatorStoreGameplayKits] Failed to fetch Map Template AssetId=%d (%s)", tmplInfo.AssetId, tmplInfo.Name))
			end
		end
		task.wait(0.04)
	end

	return kitsFolder
end

-- Backward compatibility alias
CreatorStoreGameplayKits.IngestAllKits = CreatorStoreGameplayKits.EnsureGameplayKits

function CreatorStoreGameplayKits.GetKit(kitKey: string): Model?
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	local kitsFolder = modelsFolder and modelsFolder:FindFirstChild("GameplayKits")
	if kitsFolder then
		local direct = kitsFolder:FindFirstChild(kitKey)
		if direct and direct:IsA("Model") then
			return direct
		end
		local kitInfo = CreatorStoreGameplayKits.KITS[kitKey]
		if kitInfo then
			local named = kitsFolder:FindFirstChild(kitInfo.Name)
			if named and named:IsA("Model") then
				return named
			end
		end
		for _, child in ipairs(kitsFolder:GetChildren()) do
			if child:IsA("Model") and (string.lower(child.Name) == string.lower(kitKey) or (kitInfo and string.lower(child.Name) == string.lower(kitInfo.Name))) then
				return child
			end
		end
	end

	-- Fallback to ReplicatedStorage.Maps (MAP_TEMPLATES)
	local mapTmpl = CreatorStoreGameplayKits.GetMapTemplate(kitKey)
	if mapTmpl then
		return mapTmpl
	end

	-- Also check ReplicatedStorage.Maps children directly
	local mapsFolder = ReplicatedStorage:FindFirstChild("Maps")
	if mapsFolder then
		local directMap = mapsFolder:FindFirstChild(kitKey)
		if directMap and directMap:IsA("Model") then
			return directMap
		end
		for _, child in ipairs(mapsFolder:GetChildren()) do
			if child:IsA("Model") and string.lower(child.Name) == string.lower(kitKey) then
				return child
			end
		end
	end

	-- Fallback to ReplicatedStorage.Models.PrebuiltAssets
	if modelsFolder then
		local prebuilt = modelsFolder:FindFirstChild("PrebuiltAssets")
		if prebuilt then
			local pDirect = prebuilt:FindFirstChild(kitKey)
			if pDirect and pDirect:IsA("Model") then
				return pDirect
			end
			for _, child in ipairs(prebuilt:GetChildren()) do
				if child:IsA("Model") and string.lower(child.Name) == string.lower(kitKey) then
					return child
				end
			end
		end
	end

	return nil
end

function CreatorStoreGameplayKits.GetMapTemplate(mapKey: string): Model?
	local mapsFolder = ReplicatedStorage:FindFirstChild("Maps")
	if not mapsFolder then
		return nil
	end
	local direct = mapsFolder:FindFirstChild(mapKey)
	if direct and direct:IsA("Model") then
		return direct
	end
	local tmplInfo = CreatorStoreGameplayKits.MAP_TEMPLATES[mapKey]
	if tmplInfo then
		local named = mapsFolder:FindFirstChild(tmplInfo.Name)
		if named and named:IsA("Model") then
			return named
		end
	end
	return nil
end

function CreatorStoreGameplayKits.GetActiveMap(): Model?
	return CreatorStoreGameplayKits.GetMapTemplate(CreatorStoreGameplayKits.ACTIVE_MAP_KEY)
end

return CreatorStoreGameplayKits

