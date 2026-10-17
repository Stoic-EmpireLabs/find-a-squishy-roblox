--!strict
-- PrebuiltLoader.luau
-- Loads, unpacks, normalizes, and caches pre-built 3D community models from the Roblox Creator Store / Toolbox
-- into ReplicatedStorage.Models.PrebuiltAssets so Eggs, Squishies, Bosses, Obstacles, and Environment Props
-- use authentic pre-built 3D meshes and models instead of procedural primitives.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrebuiltLoader = {}

export type AssetSpec = {
	id: number,
	mode: "single" | "pack",
	maxItems: number?,
}

PrebuiltLoader.CATALOG = {
	Eggs = {
		{ id = 127464047535341, mode = "single" }, -- Dragon Egg
		{ id = 5168800671, mode = "single" }, -- Sculpted Egg Mesh
		{ id = 4873048229, mode = "single" }, -- Egg Mesh 2
		{ id = 14931559976, mode = "single" }, -- Blue Egg Mesh
		{ id = 15850322685, mode = "pack", maxItems = 26 }, -- Egg Pets KIT (26 Eggs & Pets)
	},
	Plushies = {
		{ id = 88570972702446, mode = "pack", maxItems = 8 }, -- Squishmallows Collection [4 Pack]
		{ id = 8539945428, mode = "single" }, -- Axolotl Squishmallow
		{ id = 5495888435, mode = "single" }, -- Archie Dino Squishmallow
		{ id = 18138469368, mode = "single" }, -- Owl Squishmallow
		{ id = 82569740083425, mode = "single" }, -- Chiikawa Sitting Plushie
		{ id = 14229848241, mode = "single" }, -- Alien Plushie
		{ id = 135340189465574, mode = "single" }, -- CodysTooBig Plushie
		{ id = 15850322685, mode = "pack", maxItems = 26 }, -- Egg Pets KIT (26 Pets/Eggs)
		{ id = 85981822715000, mode = "pack", maxItems = 35 }, -- Simulator Pet Pack
		{ id = 111425439021374, mode = "pack", maxItems = 35 }, -- Plushie Pack
	},
	Monsters = {
		{ id = 83305565669388, mode = "pack", maxItems = 26 }, -- Cute Stylized Monster Pack - 25 Enemies + Boss
		{ id = 16506307978, mode = "single" }, -- Cute Monster
	},
	Dinosaurs = {
		{ id = 5495888435, mode = "single" }, -- Dino Squishmallow
		{ id = 3104618524, mode = "pack", maxItems = 7 }, -- Custom Dinosaur Mesh Pack
		{ id = 8289268262, mode = "pack", maxItems = 16 }, -- Dinosaur Meshes Pack
	},
	Aquatic = {
		{ id = 8539945428, mode = "single" }, -- Axolotl Squishmallow
		{ id = 10712062163, mode = "single" }, -- Great White Shark Mesh
	},
	Dragons = {
		{ id = 5472478735, mode = "single" }, -- Dragon Mesh
		{ id = 18138469368, mode = "single" }, -- Owl Squishmallow
		{ id = 3104618524, mode = "pack", maxItems = 4 }, -- Winged/Dino Pack
	},
	Obstacles = {
		{ id = 7486694215, mode = "pack", maxItems = 35 }, -- The Obby Kit
		{ id = 2255919152, mode = "single" }, -- Obby Obstacle
	},
	Bridges = {
		{ id = 18262413487, mode = "single" }, -- Low Poly Bridge
		{ id = 86998896489021, mode = "single" }, -- Low Poly Bridge 2
	},
	Fences = {
		{ id = 4845879207, mode = "single" }, -- Low-Poly Fence
		{ id = 14901092331, mode = "single" }, -- Low-Poly Fence 2
	},
	Trees = {
		{ id = 4893246329, mode = "single" }, -- Low Poly Tree (1000+ upvotes)
		{ id = 12549617200, mode = "single" }, -- Low Poly Tree 2
		{ id = 10707210767, mode = "single" }, -- Low Poly Tree 3
		{ id = 114770591532161, mode = "pack", maxItems = 18 }, -- Low Poly Trees Bushes Rocks and Flowers
	},
	Rocks = {
		{ id = 130260542676735, mode = "single" }, -- Low Poly Rock
		{ id = 16098456067, mode = "single" }, -- Low-Poly Rock 2
		{ id = 109124332536987, mode = "pack", maxItems = 12 }, -- Stylized Low Poly Rock Pack
	},
	Bushes = {
		{ id = 7191673673, mode = "single" }, -- Low Poly Bush
	},
	Candy = {
		{ id = 13851469145, mode = "pack", maxItems = 24 }, -- Candy Asset Pack
		{ id = 10149073107, mode = "pack", maxItems = 16 }, -- Small Candy Pack (Decorations)
	},
	Crystals = {
		{ id = 134557069734192, mode = "pack", maxItems = 18 }, -- Stylized Gem Pack x35 Crystal Cluster Geode Shard
		{ id = 109124332536987, mode = "pack", maxItems = 12 }, -- Stylized Rock/Crystal Pack
	},
	Coral = {
		{ id = 14816833452, mode = "pack", maxItems = 18 }, -- [PBR] Coral Pack
	},
	PalmTrees = {
		{ id = 10562894034, mode = "single" }, -- Palm Tree (Realistic)
		{ id = 94325172197842, mode = "pack", maxItems = 6 }, -- Stylized Palm Tree Pack
	},
	VolcanoRocks = {
		{ id = 5425109622, mode = "single" }, -- Volcano Rock
	},
	Fountain = {
		{ id = 11423259371, mode = "single" }, -- Fountain (200+ votes)
		{ id = 2332885124, mode = "single" }, -- Park Fountain
	},
	Treadmill = {
		{ id = 109866492613700, mode = "single" }, -- Treadmill
		{ id = 114934621952263, mode = "pack", maxItems = 4 }, -- Treadmill Pack
	},
	MarketStall = {
		{ id = 10970560969, mode = "single" }, -- Tent Market Stall
		{ id = 104874561792809, mode = "single" }, -- Stylized Market Stall
		{ id = 86311252190175, mode = "single" }, -- Market Stall
	},
	BirdNest = {
		{ id = 444386649, mode = "single" }, -- Bird Nest (50+ votes)
		{ id = 2657877247, mode = "single" }, -- Bird Nest 2
	},
	Incubator = {
		{ id = 13011619510, mode = "single" }, -- Egg Incubator
		{ id = 8790154757, mode = "pack", maxItems = 6 }, -- Egg Incubators
	},
	Chest = {
		{ id = 85045294075801, mode = "single" }, -- Treasure Chest Mesh
	},
}

local function sanitizePart(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
	for _, child in ipairs(part:GetChildren()) do
		if
			child:IsA("LuaSourceContainer")
			or child:IsA("Sound")
			or child:IsA("BodyMover")
			or child:IsA("Constraint")
			or child:IsA("Weld")
			or child:IsA("Motor6D")
			or child:IsA("ClickDetector")
			or child:IsA("ProximityPrompt")
			or child:IsA("TouchTransmitter")
			or child:IsA("ParticleEmitter")
			or child:IsA("Fire")
			or child:IsA("Smoke")
			or child:IsA("Sparkles")
		then
			child:Destroy()
		end
	end
end

local function isDisplayBaseplate(part: BasePart): boolean
	local s = part.Size
	local maxHoriz = math.max(s.X, s.Z)
	if maxHoriz > 42 and s.Y < 4.5 then
		return true
	end
	local lower = string.lower(part.Name)
	if (lower == "baseplate" or lower == "base" or lower == "floor" or lower == "ground") and maxHoriz > 25 then
		return true
	end
	return false
end

local function wrapPartsAsNormalizedModel(parts: { BasePart }, name: string): Model?
	if #parts == 0 then
		return nil
	end
	local m = Instance.new("Model")
	m.Name = name
	for _, p in ipairs(parts) do
		local cloned = p:Clone()
		sanitizePart(cloned)
		cloned.Parent = m
	end

	local ok, bbCF, bbSize = pcall(function()
		return m:GetBoundingBox()
	end)
	if not ok or bbSize.Magnitude < 0.05 or bbSize.Magnitude > 500 then
		m:Destroy()
		return nil
	end

	-- Center the model near origin with bottom sitting at Y = 0
	local bottomCenter = bbCF.Position - Vector3.new(0, bbSize.Y * 0.5, 0)
	local offset = -bottomCenter
	for _, desc in ipairs(m:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CFrame = desc.CFrame + offset
		end
	end
	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end

-- Connected-components AABB clustering for multi-item packs
local function extractItemsFromPack(rootInstances: { Instance }, categoryName: string, maxItems: number): { Model }
	local results: { Model } = {}

	-- First collect all candidate valid BaseParts across rootInstances
	local allParts: { BasePart } = {}
	local function collect(inst: Instance)
		if inst:IsA("BasePart") then
			if not isDisplayBaseplate(inst) and inst.Transparency < 0.98 and inst.Size.Magnitude > 0.15 then
				table.insert(allParts, inst)
			end
		end
		for _, child in ipairs(inst:GetChildren()) do
			if not child:IsA("LuaSourceContainer") then
				collect(child)
			end
		end
	end
	for _, root in ipairs(rootInstances) do
		collect(root)
	end

	if #allParts == 0 then
		return results
	end

	-- Check if root already contains clean sub-Models before falling back to spatial clustering
	local subModels: { Model } = {}
	for _, root in ipairs(rootInstances) do
		if root:IsA("Model") or root:IsA("Folder") then
			for _, child in ipairs(root:GetChildren()) do
				if child:IsA("Model") then
					local ok, _, sz = pcall(function()
						return child:GetBoundingBox()
					end)
					if ok and sz.Magnitude > 0.2 and sz.Magnitude < 45 then
						table.insert(subModels, child)
					end
				end
			end
		end
	end

	if #subModels >= 2 then
		for idx, sm in ipairs(subModels) do
			if #results >= maxItems then
				break
			end
			local smParts: { BasePart } = {}
			for _, d in ipairs(sm:GetDescendants()) do
				if d:IsA("BasePart") and not isDisplayBaseplate(d) and d.Transparency < 0.98 then
					table.insert(smParts, d)
				end
			end
			local wrapped = wrapPartsAsNormalizedModel(smParts, string.format("%s_%d", categoryName, idx))
			if wrapped then
				table.insert(results, wrapped)
			end
		end
		if #results > 0 then
			return results
		end
	end

	-- Spatial AABB clustering
	local n = #allParts
	if n > 220 then
		n = 220 -- Cap to keep clustering instantaneous
	end
	local mins = table.create(n)
	local maxs = table.create(n)
	local pad = Vector3.new(0.45, 0.65, 0.45)
	for i = 1, n do
		local p = allParts[i]
		local pos = p.Position
		local half = p.Size * 0.5 + pad
		mins[i] = pos - half
		maxs[i] = pos + half
	end

	local visited = table.create(n, false)
	local clusterIdx = 0

	for i = 1, n do
		if not visited[i] then
			visited[i] = true
			local cluster: { BasePart } = { allParts[i] }
			local queue: { number } = { i }
			local head = 1
			while head <= #queue do
				local curr = queue[head]
				head += 1
				local cMin = mins[curr]
				local cMax = maxs[curr]
				for j = 1, n do
					if not visited[j] then
						local oMin = mins[j]
						local oMax = maxs[j]
						if
							cMin.X <= oMax.X
							and cMax.X >= oMin.X
							and cMin.Y <= oMax.Y
							and cMax.Y >= oMin.Y
							and cMin.Z <= oMax.Z
							and cMax.Z >= oMin.Z
						then
							visited[j] = true
							table.insert(cluster, allParts[j])
							table.insert(queue, j)
						end
					end
				end
			end

			clusterIdx += 1
			local wrapped = wrapPartsAsNormalizedModel(cluster, string.format("%s_%d", categoryName, clusterIdx))
			if wrapped then
				table.insert(results, wrapped)
				if #results >= maxItems then
					break
				end
			end
		end
	end

	return results
end

local function extractSingleItem(rootInstances: { Instance }, categoryName: string, index: number): Model?
	local parts: { BasePart } = {}
	local function collect(inst: Instance)
		if inst:IsA("BasePart") and not isDisplayBaseplate(inst) and inst.Transparency < 0.98 then
			table.insert(parts, inst)
		end
		for _, child in ipairs(inst:GetChildren()) do
			if not child:IsA("LuaSourceContainer") then
				collect(child)
			end
		end
	end
	for _, r in ipairs(rootInstances) do
		collect(r)
	end
	return wrapPartsAsNormalizedModel(parts, string.format("%s_Single_%d", categoryName, index))
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
	if
		existing
		and existing:IsA("Folder")
		and existing:GetAttribute("LoadedCount")
		and (existing:GetAttribute("LoadedCount") :: number) > 10
	then
		return existing
	end

	local prebuiltRoot = if existing and existing:IsA("Folder") then existing else Instance.new("Folder")
	prebuiltRoot.Name = "PrebuiltAssets"
	prebuiltRoot.Parent = modelsFolder

	local fetchObjects = customObjectFetcher
		or function(assetId: number): { Instance }?
			local ok, res = pcall(function()
				return game:GetObjects("rbxassetid://" .. tostring(assetId))
			end)
			if ok and res and #res > 0 then
				return res
			end
			local ok2, model = pcall(function()
				return InsertService:LoadAsset(assetId)
			end)
			if ok2 and model then
				return model:GetChildren()
			end
			return nil
		end

	-- Build flat job list across all categories and process with 4 workers so Studio AssetDelivery never throttles
	type Job = { categoryName: string, specIdx: number, spec: AssetSpec, catFolder: Folder }
	local jobs: { Job } = {}
	for categoryName, specs in pairs(PrebuiltLoader.CATALOG) do
		local catFolder = prebuiltRoot:FindFirstChild(categoryName)
		if not catFolder then
			local f = Instance.new("Folder")
			f.Name = categoryName
			f.Parent = prebuiltRoot
			catFolder = f
		end
		for specIdx, spec in ipairs(specs :: { AssetSpec }) do
			table.insert(jobs, {
				categoryName = categoryName,
				specIdx = specIdx,
				spec = spec,
				catFolder = catFolder :: Folder,
			})
		end
	end

	local totalLoaded = 0
	local jobIndex = 0
	local numWorkers = 4
	local activeWorkers = numWorkers

	for _ = 1, numWorkers do
		task.spawn(function()
			while true do
				jobIndex += 1
				local myIdx = jobIndex
				if myIdx > #jobs then
					break
				end
				local job = jobs[myIdx]
				local okFetch, objects = pcall(fetchObjects, job.spec.id)
				if okFetch and objects and #objects > 0 then
					pcall(function()
						if job.spec.mode == "single" then
							local model = extractSingleItem(objects, job.categoryName, job.specIdx)
							if model then
								model.Name = string.format("%s_%d", job.categoryName, #job.catFolder:GetChildren() + 1)
								model.Parent = job.catFolder
								totalLoaded += 1
							end
						else
							local models = extractItemsFromPack(objects, job.categoryName, job.spec.maxItems or 25)
							for _, m in ipairs(models) do
								m.Name = string.format("%s_%d", job.categoryName, #job.catFolder:GetChildren() + 1)
								m.Parent = job.catFolder
								totalLoaded += 1
							end
						end
					end)
					for _, obj in ipairs(objects) do
						pcall(function()
							obj:Destroy()
						end)
					end
				else
					warn(string.format("[PrebuiltLoader] Could not fetch asset %d (%s)", job.spec.id, job.categoryName))
				end
			end
			activeWorkers -= 1
		end)
	end

	local startWait = os.clock()
	while activeWorkers > 0 and (os.clock() - startWait) < 15.0 do
		task.wait(0.1)
	end

	prebuiltRoot:SetAttribute("LoadedCount", totalLoaded)
	ReplicatedStorage:SetAttribute("PrebuiltAssetsReady", true)
	warn(string.format("[PrebuiltLoader] Successfully unpacked %d pre-built 3D community models!", totalLoaded))
	return prebuiltRoot
end

function PrebuiltLoader.GetCategoryTemplates(categoryName: string): { Model }
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	local prebuiltRoot = if modelsFolder then modelsFolder:FindFirstChild("PrebuiltAssets") else nil
	local catFolder = if prebuiltRoot then prebuiltRoot:FindFirstChild(categoryName) else nil
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
	seedIndex: number,
	targetScale: number,
	canCollide: boolean?
): Model?
	local templates = PrebuiltLoader.GetCategoryTemplates(categoryName)
	if #templates == 0 then
		return nil
	end

	local chosen = templates[((math.max(1, math.floor(seedIndex)) - 1) % #templates) + 1]
	local cloned = chosen:Clone()

	local ok, bbCF, bbSize = pcall(function()
		return cloned:GetBoundingBox()
	end)
	if ok and bbSize.Magnitude > 0.05 then
		local currentDim = math.max(bbSize.Y, bbSize.X * 0.72, bbSize.Z * 0.72)
		local factor = math.clamp(targetScale / math.max(currentDim, 0.1), 0.03, 40)
		local scaledOk = pcall(function()
			cloned:ScaleTo(cloned:GetScale() * factor)
		end)
		local _, _, checkSize = pcall(function()
			return cloned:GetBoundingBox()
		end)
		if not scaledOk or (checkSize and math.abs(checkSize.Y - bbSize.Y) < 0.01 and math.abs(factor - 1) > 0.08) then
			for _, desc in ipairs(cloned:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Size = desc.Size * factor
					desc.Position = desc.Position * factor
					local sm = desc:FindFirstChildOfClass("SpecialMesh")
					if sm then
						sm.Scale = sm.Scale * factor
					end
				end
			end
		end
	end

	-- Re-measure after scaling and attach a Root PrimaryPart at the bottom-center
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
	root.Parent = cloned

	for _, desc in ipairs(cloned:GetDescendants()) do
		if desc:IsA("BasePart") and desc ~= root then
			desc.Anchored = true
			desc.CanCollide = if canCollide ~= nil then canCollide else false
			desc.CastShadow = false
		end
	end

	cloned.PrimaryPart = root
	cloned.WorldPivot = CFrame.new(bottomCenter)
	return cloned
end

return PrebuiltLoader
