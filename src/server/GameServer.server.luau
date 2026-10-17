--!strict
-- GameServer.server.luau
-- Authoritative Server Engine for Find a Squishy!
-- Handles DataStores, Base Pens, Million-Speed Treadmills, Egg Pickup/Carry/Planting,
-- Animal & Brainrot Chaser AI, Obby Hazards, Coloring Floor Trails, Paid Egg Guide, and Morphing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SlimeData = require(Shared:WaitForChild("SlimeData"))
local UpgradeData = require(Shared:WaitForChild("UpgradeData"))
local SquishyBuilder = require(Shared:WaitForChild("SquishyBuilder"))
local PrebuiltLoader = require(Shared:WaitForChild("PrebuiltLoader"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

-- ============================================================================
-- 1. REMOTE EVENTS SETUP
-- ============================================================================
local remotesFolder = ReplicatedStorage:FindFirstChild("SquishyRemotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "SquishyRemotes"
	remotesFolder.Parent = ReplicatedStorage
end

local stateSyncRemote = Instance.new("RemoteEvent")
stateSyncRemote.Name = "StateSync"
stateSyncRemote.Parent = remotesFolder

local notifyRemote = Instance.new("RemoteEvent")
notifyRemote.Name = "Notification"
notifyRemote.Parent = remotesFolder

local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name = "ActionRequest"
actionRemote.Parent = remotesFolder

-- ============================================================================
-- 2. ENSURE PRE-BUILT 3D COMMUNITY ASSETS & BUILD WORLD
-- ============================================================================
do
	local startWait = os.clock()
	while not ReplicatedStorage:GetAttribute("PrebuiltAssetsReady") and (os.clock() - startWait) < 6.0 do
		task.wait(0.1)
	end
	if not ReplicatedStorage:GetAttribute("PrebuiltAssetsReady") then
		pcall(function()
			PrebuiltLoader.EnsurePrebuiltAssets()
		end)
	end
end

local world = WorldBuilder.BuildWorld()

local dataStore = nil
pcall(function()
	dataStore = DataStoreService:GetDataStore("FindASquishy_Save_v2")
end)

export type IncubatingEggState = {
	EggId: number,
	SlotIdx: number,
	RemainingSec: number,
	Model: Model,
}

export type PlayerSession = {
	UserId: number,
	Coins: number,
	StoredPenCoins: number,
	SpeedPower: number,
	PenTier: number,
	TreadmillTier: number,
	GelTier: number,
	JumpTier: number,
	PlantedEggs: { [string]: boolean },
	SquishyLevels: { [string]: number },
	BackpackEggs: { [string]: number },
	OwnedTrails: { [string]: boolean },
	EquippedTrail: string,
	VIPGuideUnlocked: boolean,
	ActiveGuideEggId: number?,
	CurrentMorphId: number?,
	TinyMode: boolean,
	CarryingEggId: number?,
	PlotIndex: number?,
	ShieldExpiresAt: number,
}

local sessions: { [Player]: PlayerSession } = {}
local carriedEggModels: { [Player]: Model } = {}
local incubatingEggsByPlayer: { [Player]: { [number]: IncubatingEggState } } = {}
local touchCooldowns: { [string]: number } = {}
local guardianWaypoints: { [string]: Vector3 } = {}
local eggLiveOffsets: { [number]: Vector3 } = {}
local paintFolder = Instance.new("Folder")
paintFolder.Name = "FloorPaintSplats"
paintFolder.Parent = Workspace

for _, sDef in ipairs(SlimeData.Slimes) do
	eggLiveOffsets[sDef.Id] = sDef.Position
end

-- Spawns a dramatic 3D Shockwave Ring + Particle Burst + Floating 3D Text at any world position!
local function spawnCelebrationBurst(pos: Vector3, mainColor: Color3, secColor: Color3, bannerText: string)
	local anchor = Instance.new("Part")
	anchor.Name = "VFXBurstAnchor"
	anchor.Shape = Enum.PartType.Ball
	anchor.Material = Enum.Material.Neon
	anchor.Color = mainColor
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 0.15
	anchor.Size = Vector3.new(1.5, 1.5, 1.5)
	anchor.Position = pos
	anchor.Parent = Workspace

	local ring = Instance.new("Part")
	ring.Name = "ShockwaveRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = secColor
	ring.Anchored = true
	ring.CanCollide = false
	ring.Transparency = 0.1
	ring.Size = Vector3.new(0.4, 2.5, 2.5)
	ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = Workspace

	TweenService:Create(anchor, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(9.5, 9.5, 9.5),
		Transparency = 1,
	}):Play()
	TweenService:Create(ring, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, 16, 16),
		Transparency = 1,
	}):Play()

	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(mainColor, secColor)
	pe.LightEmission = 1
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(0.6, 1.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Lifetime = NumberRange.new(0.6, 1.1)
	pe.Speed = NumberRange.new(14, 28)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Rate = 0
	pe.Parent = anchor
	pe:Emit(35)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 240, 0, 64)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = anchor

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextScaled = true
	lbl.TextColor3 = mainColor
	lbl.TextStrokeColor3 = Color3.fromRGB(15, 20, 35)
	lbl.TextStrokeTransparency = 0
	lbl.Text = bannerText
	lbl.Parent = bb

	TweenService:Create(bb, TweenInfo.new(1.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 8.5, 0),
	}):Play()

	Debris:AddItem(ring, 0.8)
	Debris:AddItem(anchor, 1.2)
end

local function isOnCooldown(key: string, cooldownSec: number): boolean
	local now = os.clock()
	if touchCooldowns[key] and (now - touchCooldowns[key]) < cooldownSec then
		return true
	end
	touchCooldowns[key] = now
	return false
end

local function getPlantedCount(session: PlayerSession, levelFilter: number?): number
	local count = 0
	for idStr, isPlanted in pairs(session.PlantedEggs) do
		if isPlanted then
			local id = tonumber(idStr)
			if id then
				if levelFilter == nil then
					count += 1
				else
					local def = SlimeData.ById[id]
					if def and def.Level == levelFilter then
						count += 1
					end
				end
			end
		end
	end
	return count
end

local function isLevelCompleted(session: PlayerSession, levelNum: number): boolean
	local levelSlimes = SlimeData.ByLevel[levelNum]
	if not levelSlimes then
		return true
	end
	for _, sDef in ipairs(levelSlimes) do
		local key = tostring(sDef.Id)
		if not session.PlantedEggs[key] and not session.BackpackEggs[key] then
			return false
		end
	end
	return true
end

local function getMaxUnlockedLevel(session: PlayerSession): number
	for lvl = 1, 4 do
		if not isLevelCompleted(session, lvl) then
			return lvl
		end
	end
	return 5
end

local function getTotalIncomePerSec(session: PlayerSession): number
	local baseSum = 0
	for idStr, isPlanted in pairs(session.PlantedEggs) do
		if isPlanted then
			local id = tonumber(idStr)
			local def = if id then SlimeData.ById[id] else nil
			if def then
				local sqLvl = session.SquishyLevels[idStr] or 1
				baseSum += SlimeData.GetSquishyCoinsPerSec(def, sqLvl)
			end
		end
	end
	local gelMult = UpgradeData.GetGelTier(session.GelTier).Multiplier
	local trailDef = UpgradeData.GetTrailById(session.EquippedTrail)
	local trailMult = if trailDef then trailDef.CoinMultiplier else 1.0
	return math.floor(baseSum * gelMult * trailMult)
end

local function notifyPlayer(player: Player, message: string, colorType: string?)
	notifyRemote:FireClient(player, {
		Message = message,
		Kind = colorType or "Info",
	})
end

local function updateLeaderstats(player: Player, session: PlayerSession)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		return
	end
	local plantedVal = ls:FindFirstChild("Planted Eggs") :: StringValue?
	local speedVal = ls:FindFirstChild("Speed Power") :: StringValue?
	local coinsVal = ls:FindFirstChild("Coins") :: StringValue?
	if plantedVal then
		plantedVal.Value = string.format("%d / 35", getPlantedCount(session))
	end
	if speedVal then
		speedVal.Value = UpgradeData.FormatNumber(session.SpeedPower)
	end
	if coinsVal then
		coinsVal.Value = "$" .. UpgradeData.FormatNumber(session.Coins)
	end
end

local function applyCharacterStatsAndTrail(player: Player, session: PlayerSession)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp then
		return
	end

	humanoid.UseJumpPower = true
	humanoid.WalkSpeed = UpgradeData.SpeedPowerToWalkSpeed(session.SpeedPower)
	humanoid.JumpPower = UpgradeData.GetJumpTier(session.JumpTier).JumpPower

	-- Apply Coloring Ribbon Trail on Character
	local oldTrail = hrp:FindFirstChild("SquishyColorTrail")
	if oldTrail then
		oldTrail:Destroy()
	end
	local att0 = hrp:FindFirstChild("TrailAtt0") :: Attachment?
	local att1 = hrp:FindFirstChild("TrailAtt1") :: Attachment?
	if not att0 then
		att0 = Instance.new("Attachment")
		att0.Name = "TrailAtt0"
		att0.Position = Vector3.new(0, 1.4, 0)
		att0.Parent = hrp
	end
	if not att1 then
		att1 = Instance.new("Attachment")
		att1.Name = "TrailAtt1"
		att1.Position = Vector3.new(0, -1.6, 0)
		att1.Parent = hrp
	end

	local trailDef = UpgradeData.GetTrailById(session.EquippedTrail)
	if trailDef then
		local tr = Instance.new("Trail")
		tr.Name = "SquishyColorTrail"
		tr.Attachment0 = att0
		tr.Attachment1 = att1
		tr.Lifetime = 1.25
		tr.MinLength = 0.1
		tr.FaceCamera = true
		tr.LightEmission = 0.85
		tr.Color = ColorSequence.new(trailDef.Color1, trailDef.Color2)
		tr.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1.0),
		})
		tr.Parent = hrp
	end

	-- Apply Squishy Morph if active
	local morphDef = if session.CurrentMorphId then SlimeData.ById[session.CurrentMorphId] else nil
	SquishyBuilder.ApplyCharacterMorph(character, morphDef, session.TinyMode)
end

-- ============================================================================
-- 3. REFRESH BASE PEN VISUALS & CLICK-TO-SQUISH FIDGET SLIMES
-- ============================================================================
local syncPlayerState: (Player) -> ()

local upgradePlacedSquishy: (Player, number) -> ()
local placeBackpackSquishyInPen: (Player, number, Tool?) -> ()
local giveHatchedSquishyToolToPlayer: (Player, SlimeData.SlimeDef, number?) -> Tool?

local function refreshPlotVisuals(plotIndex: number, player: Player?, session: PlayerSession?)
	local plot = world.Plots[plotIndex]
	if not plot then
		return
	end

	local function setSignText(titleStr: string, subStr: string)
		plot.SignLabel.Text = titleStr
		plot.SubSignLabel.Text = subStr
		local board = plot.Folder:FindFirstChild("OwnerSignBoard")
		if board then
			for _, desc in ipairs(board:GetDescendants()) do
				if desc:IsA("TextLabel") then
					if desc.Name == "Title" then
						desc.Text = titleStr
					elseif desc.Name == "Sub" then
						desc.Text = subStr
					end
				end
			end
		end
	end

	if not player or not session then
		plot.OwnerUserId = nil
		setSignText(string.format("🏡 PEN #%d (TOUCH TO CLAIM)", plotIndex), "Unclaimed Sanctuary Pen")
		plot.CashLabel.Text = "$0 Ready"
		plot.ShieldDome.Transparency = 1
		plot.ShieldDome.Size = Vector3.new(0.1, 0.1, 0.1)
		plot.ShieldDome.Position = plot.Origin + Vector3.new(0, -50, 0)
		for slotIdx = 1, 35 do
			local nest = plot.Nests[slotIdx]
			if nest.HatchedModel then
				nest.HatchedModel:Destroy()
				nest.HatchedModel = nil
			end
			nest.Pedestal.Transparency = if slotIdx <= 5 then 0.15 else 0.65
			nest.Pedestal.Color = if slotIdx <= 5
				then Color3.fromRGB(165, 245, 110)
				else Color3.fromRGB(90, 125, 85)
		end
		return
	end

	local penDef = UpgradeData.GetPenTier(session.PenTier)
	local plantedTotal = getPlantedCount(session)
	local incomeRate = getTotalIncomePerSec(session)

	setSignText(
		string.format("🏡 %s's SQUISHY PEN", string.upper(player.DisplayName)),
		string.format(
			"%s | %d / %d Squishies Making $%s/s",
			penDef.Name,
			plantedTotal,
			penDef.MaxNests,
			UpgradeData.FormatNumber(incomeRate)
		)
	)
	plot.CashLabel.Text = string.format("$%s Ready to Collect!", UpgradeData.FormatNumber(session.StoredPenCoins))

	-- Update Upgrade Pad Labels
	if session.PenTier < #UpgradeData.PenTiers then
		local nextPen = UpgradeData.GetPenTier(session.PenTier + 1)
		plot.ExpandLabel.Text = string.format("Tier %d (%d Slots): $%s", nextPen.Tier, nextPen.MaxNests, UpgradeData.FormatNumber(nextPen.Cost))
	else
		plot.ExpandLabel.Text = "MAX PEN SIZE (35/35 Slots)!"
	end

	if session.TreadmillTier < #UpgradeData.TreadmillTiers then
		local nextTm = UpgradeData.GetTreadmillTier(session.TreadmillTier + 1)
		plot.TreadmillLabel.Text = string.format(
			"%s (+%s Spd): $%s",
			nextTm.Name,
			UpgradeData.FormatNumber(nextTm.SpeedPerTick),
			UpgradeData.FormatNumber(nextTm.Cost)
		)
	else
		plot.TreadmillLabel.Text = "MAX GOD-SPEED DINO BELT!"
	end
	plot.TreadmillBelt.Color = UpgradeData.GetTreadmillTier(session.TreadmillTier).Color

	if session.GelTier < #UpgradeData.GelTiers then
		local nextGel = UpgradeData.GetGelTier(session.GelTier + 1)
		plot.GelLabel.Text = string.format("%s (%.1fx): $%s", nextGel.Name, nextGel.Multiplier, UpgradeData.FormatNumber(nextGel.Cost))
	else
		plot.GelLabel.Text = "MAX COSMIC GEL (12x)!"
	end

	local shieldRemaining = math.max(0, math.ceil(session.ShieldExpiresAt - os.clock()))
	if shieldRemaining > 0 then
		plot.ShieldDome.Size = Vector3.new(78, 34, 60)
		plot.ShieldDome.Position = plot.Origin + Vector3.new(0, 10, 0)
		plot.ShieldDome.Transparency = 0.65
		plot.ShieldLabel.Text = string.format("🛡️ SHIELD ACTIVE (%ds)", shieldRemaining)
	else
		plot.ShieldDome.Transparency = 1.0
		plot.ShieldDome.Size = Vector3.new(0.1, 0.1, 0.1)
		plot.ShieldDome.Position = plot.Origin + Vector3.new(0, -50, 0)
		plot.ShieldLabel.Text = "Step to Activate Laser Shield (60s)"
	end

	-- Update all 35 Nest Pedestals & Placed Squishies
	local playerIncubating = incubatingEggsByPlayer[player] or {}
	for slotIdx = 1, 35 do
		local nest = plot.Nests[slotIdx]
		local isSlotUnlocked = (slotIdx <= penDef.MaxNests)
		local isPlanted = session.PlantedEggs[tostring(slotIdx)] == true
		local sqLvl = session.SquishyLevels[tostring(slotIdx)] or 1
		local isIncubating = playerIncubating[slotIdx] ~= nil

		nest.Pedestal.Transparency = if isSlotUnlocked then 0.1 else 0.72
		nest.Pedestal.Color = if isPlanted
			then Color3.fromRGB(85, 255, 130)
			elseif isIncubating then Color3.fromRGB(195, 95, 255)
			elseif isSlotUnlocked then Color3.fromRGB(165, 245, 110)
			else Color3.fromRGB(85, 110, 85)

		if isPlanted then
			local needsRebuild = (not nest.HatchedModel)
				or (nest.HatchedModel:GetAttribute("GelTier") ~= session.GelTier)
				or (nest.HatchedModel:GetAttribute("SquishyLevel") ~= sqLvl)
			if needsRebuild then
				if nest.HatchedModel then
					nest.HatchedModel:Destroy()
				end
				local slimeDef = SlimeData.ById[slotIdx]
				if slimeDef then
					local spawnPos = nest.Pedestal.Position + Vector3.new(0, 2.3, 0)
					local squishyModel = SquishyBuilder.CreateHatchedSquishy(slimeDef, spawnPos, session.GelTier, sqLvl)
					squishyModel:SetAttribute("GelTier", session.GelTier)
					squishyModel:SetAttribute("SquishyLevel", sqLvl)
					squishyModel.Parent = plot.Folder
					nest.HatchedModel = squishyModel

					local body = squishyModel.PrimaryPart
					if body then
						-- Wire ProximityPrompt ("Level Up -> Lv.X") to upgrade this Squishy's $/sec!
						local upgPrompt = body:FindFirstChild("UpgradeSquishyPrompt") :: ProximityPrompt?
						if upgPrompt then
							upgPrompt.Triggered:Connect(function(triggerPlr: Player)
								if triggerPlr == player then
									upgradePlacedSquishy(player, slotIdx)
								end
							end)
						end

						-- Wire ClickDetector: Owner clicking either upgrades level (if affordable) or gives Squish Bonus!
						local clickDet = Instance.new("ClickDetector")
						clickDet.MaxActivationDistance = 38
						clickDet.Parent = body
						clickDet.MouseClick:Connect(function(clickingPlayer: Player)
							local clickSession = sessions[clickingPlayer]
							if not clickSession then
								return
							end
							local curLvl = clickSession.SquishyLevels[tostring(slotIdx)] or 1
							local upgCost = SlimeData.GetSquishyUpgradeCost(slimeDef, curLvl)
							if clickingPlayer == player and clickSession.Coins >= upgCost then
								upgradePlacedSquishy(player, slotIdx)
								return
							end

							local cps = SlimeData.GetSquishyCoinsPerSec(slimeDef, curLvl)
							local bonus = math.max(5, math.floor(cps * 1.5))
							clickSession.Coins += bonus
							updateLeaderstats(clickingPlayer, clickSession)
							syncPlayerState(clickingPlayer)

							local origSize = body.Size
							body.Size = Vector3.new(origSize.X * 1.35, origSize.Y * 0.45, origSize.Z * 1.35)
							TweenService:Create(
								body,
								TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
								{ Size = origSize }
							):Play()
							notifyPlayer(
								clickingPlayer,
								string.format(
									"🍮 SQUISH! +$%s Bonus from %s [Lv.%d]! (Need $%s to Level Up)",
									UpgradeData.FormatNumber(bonus),
									slimeDef.Name,
									curLvl,
									UpgradeData.FormatNumber(upgCost)
								),
								"Success"
							)
						end)
					end
				end
			end
		elseif not isIncubating then
			if nest.HatchedModel then
				nest.HatchedModel:Destroy()
				nest.HatchedModel = nil
			end
		end
	end
end

upgradePlacedSquishy = function(player: Player, eggId: number)
	local session = sessions[player]
	local slimeDef = SlimeData.ById[eggId]
	if not session or not slimeDef then
		return
	end
	local idStr = tostring(eggId)
	if not session.PlantedEggs[idStr] then
		notifyPlayer(player, "Place this Squishy from your Backpack into your Pen first!", "Warning")
		return
	end
	local currentLvl = session.SquishyLevels[idStr] or 1
	local cost = SlimeData.GetSquishyUpgradeCost(slimeDef, currentLvl)
	if session.Coins < cost then
		notifyPlayer(
			player,
			string.format(
				"Need $%s Coins to upgrade %s to Lv.%d!",
				UpgradeData.FormatNumber(cost),
				slimeDef.Name,
				currentLvl + 1
			),
			"Error"
		)
		return
	end

	session.Coins -= cost
	local newLvl = currentLvl + 1
	session.SquishyLevels[idStr] = newLvl
	local newCps = SlimeData.GetSquishyCoinsPerSec(slimeDef, newLvl)

	if session.PlotIndex then
		local plot = world.Plots[session.PlotIndex]
		local nest = if plot then plot.Nests[eggId] else nil
		if nest then
			spawnCelebrationBurst(
				nest.Pedestal.Position + Vector3.new(0, 3.5, 0),
				Color3.fromRGB(85, 255, 130),
				slimeDef.Color,
				string.format("⬆️ LV.%d! +$%s/s!", newLvl, UpgradeData.FormatNumber(newCps))
			)
		end
	end

	notifyPlayer(
		player,
		string.format(
			"⬆️ LEVEL UP! %s is now Lv.%d and makes +$%s/sec!",
			slimeDef.Name,
			newLvl,
			UpgradeData.FormatNumber(newCps)
		),
		"Success"
	)
	syncPlayerState(player)
end

placeBackpackSquishyInPen = function(player: Player, eggId: number, toolInstance: Tool?)
	local session = sessions[player]
	local slimeDef = SlimeData.ById[eggId]
	if not session or not slimeDef then
		return
	end
	if not session.PlotIndex then
		assignPlotToPlayer(player, session, nil)
	end

	local penDef = UpgradeData.GetPenTier(session.PenTier)
	if eggId > penDef.MaxNests then
		session.PenTier = math.max(session.PenTier, slimeDef.Level)
	end

	local idStr = tostring(eggId)
	local sqLvl = session.BackpackEggs[idStr] or session.SquishyLevels[idStr] or 1
	session.BackpackEggs[idStr] = nil
	session.PlantedEggs[idStr] = true
	session.SquishyLevels[idStr] = sqLvl

	if toolInstance then
		toolInstance:Destroy()
	else
		-- Remove matching tool from Backpack or Character if present
		for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
			if container then
				for _, child in ipairs(container:GetChildren()) do
					if child:IsA("Tool") and child:GetAttribute("SlimeId") == eggId then
						child:Destroy()
					end
				end
			end
		end
	end

	local cps = SlimeData.GetSquishyCoinsPerSec(slimeDef, sqLvl)
	if session.PlotIndex then
		local plot = world.Plots[session.PlotIndex]
		local nest = if plot then plot.Nests[eggId] else nil
		if nest then
			spawnCelebrationBurst(
				nest.Pedestal.Position + Vector3.new(0, 3.2, 0),
				slimeDef.Color,
				Color3.fromRGB(85, 255, 130),
				string.format("🥟 PLACED %s! +$%s/s", string.upper(slimeDef.Name), UpgradeData.FormatNumber(cps))
			)
		end
	end

	local lvlCompleted = isLevelCompleted(session, slimeDef.Level)
	if lvlCompleted and slimeDef.Level < 5 then
		local nextLvl = SlimeData.Levels[slimeDef.Level + 1]
		notifyPlayer(
			player,
			string.format(
				"🎉 ALL LEVEL %d SQUISHIES PLACED! Gate to Level %d (%s) is NOW UNLOCKED!",
				slimeDef.Level,
				nextLvl.Level,
				nextLvl.Name
			),
			"Success"
		)
	else
		notifyPlayer(
			player,
			string.format(
				"🥟 PLACED %s [Lv.%d] in your Pen! Now generating +$%s/sec! (Click or press E on it to Level Up!)",
				slimeDef.Name,
				sqLvl,
				UpgradeData.FormatNumber(cps)
			),
			"Success"
		)
	end

	syncPlayerState(player)
end

giveHatchedSquishyToolToPlayer = function(player: Player, slimeDef: SlimeData.SlimeDef, sqLvl: number?): Tool?
	local session = sessions[player]
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not session or not backpack then
		return nil
	end
	local lvl = sqLvl or 1
	session.BackpackEggs[tostring(slimeDef.Id)] = lvl

	-- Avoid duplicates in backpack
	for _, container in ipairs({ backpack, player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute("SlimeId") == slimeDef.Id then
					return child
				end
			end
		end
	end

	local tool = SquishyBuilder.CreateSquishyBackpackTool(slimeDef, lvl)
	tool.Activated:Connect(function()
		placeBackpackSquishyInPen(player, slimeDef.Id, tool)
	end)
	tool.Parent = backpack
	return tool
end

syncPlayerState = function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	updateLeaderstats(player, session)
	if session.PlotIndex then
		refreshPlotVisuals(session.PlotIndex, player, session)
	end
	stateSyncRemote:FireClient(player, {
		Coins = session.Coins,
		StoredPenCoins = session.StoredPenCoins,
		SpeedPower = session.SpeedPower,
		WalkSpeed = UpgradeData.SpeedPowerToWalkSpeed(session.SpeedPower),
		PenTier = session.PenTier,
		TreadmillTier = session.TreadmillTier,
		GelTier = session.GelTier,
		JumpTier = session.JumpTier,
		PlantedEggs = session.PlantedEggs,
		SquishyLevels = session.SquishyLevels,
		BackpackEggs = session.BackpackEggs,
		PlantedCount = getPlantedCount(session),
		MaxUnlockedLevel = getMaxUnlockedLevel(session),
		IncomePerSec = getTotalIncomePerSec(session),
		OwnedTrails = session.OwnedTrails,
		EquippedTrail = session.EquippedTrail,
		VIPGuideUnlocked = session.VIPGuideUnlocked,
		ActiveGuideEggId = session.ActiveGuideEggId,
		CurrentMorphId = session.CurrentMorphId,
		TinyMode = session.TinyMode,
		CarryingEggId = session.CarryingEggId,
		PlotIndex = session.PlotIndex,
	})
end

-- ============================================================================
-- 4. EGG COLLECT VFX, CARRYING, PLANTING COUNTDOWN & HATCHING INTO BACKPACK!
-- ============================================================================
local function clearCarriedEgg(player: Player)
	local session = sessions[player]
	if session then
		session.CarryingEggId = nil
	end
	local oldModel = carriedEggModels[player]
	if oldModel then
		oldModel:Destroy()
		carriedEggModels[player] = nil
	end
end

local function attachCarriedEggToPlayer(player: Player, slimeDef: SlimeData.SlimeDef)
	clearCarriedEgg(player)
	local session = sessions[player]
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not session or not hrp then
		return
	end

	-- Dramatic Collect / Steal Egg Celebration Burst at the World Egg!
	spawnCelebrationBurst(
		slimeDef.Position + Vector3.new(0, 2.5, 0),
		slimeDef.Color,
		slimeDef.SecondaryColor,
		string.format("🚨 STOLE %s EGG!", string.upper(slimeDef.Name))
	)

	session.CarryingEggId = slimeDef.Id
	local carriedModel = SquishyBuilder.CreateWorldEgg(slimeDef, false)
	carriedModel.Name = "CarriedEgg_" .. tostring(slimeDef.Id)
	local primary = carriedModel.PrimaryPart
	if primary then
		primary.CFrame = hrp.CFrame * CFrame.new(0, 4.8, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = primary
		weld.Parent = primary
	end
	carriedModel.Parent = character
	carriedEggModels[player] = carriedModel

	notifyPlayer(
		player,
		string.format(
			"🚨 STOLE %s EGG! The Boss Guardian woke up (!!) — Run back to your Base Pen to Plant & Hatch it!",
			string.upper(slimeDef.Name)
		),
		"Warning"
	)
	syncPlayerState(player)
end

local function plantCarriedEggInPen(player: Player)
	local session = sessions[player]
	if not session or not session.CarryingEggId then
		return
	end

	local eggId = session.CarryingEggId
	local slimeDef = SlimeData.ById[eggId]
	if not slimeDef then
		clearCarriedEgg(player)
		return
	end

	if not session.PlotIndex then
		assignPlotToPlayer(player, session, nil)
	end
	local plot = if session.PlotIndex then world.Plots[session.PlotIndex] else nil
	if not plot then
		return
	end

	local penDef = UpgradeData.GetPenTier(session.PenTier)
	local currentPlanted = getPlantedCount(session)

	-- Verify player has grown their Pen enough to hold this Egg!
	if currentPlanted >= penDef.MaxNests or eggId > penDef.MaxNests then
		local requiredTier = slimeDef.Level
		local reqPenDef = UpgradeData.GetPenTier(requiredTier)
		notifyPlayer(
			player,
			string.format(
				"⚠️ Your Pen only has %d Slots! Step on the orange [GROW PEN] pad ($%s) to unlock %d Slots!",
				penDef.MaxNests,
				UpgradeData.FormatNumber(reqPenDef.Cost),
				reqPenDef.MaxNests
			),
			"Error"
		)
		return
	end

	clearCarriedEgg(player)
	if session.ActiveGuideEggId == eggId then
		session.ActiveGuideEggId = nil
	end

	local nest = plot.Nests[eggId]
	local hatchPos = if nest then nest.Pedestal.Position else (plot.PlantPad.Position + Vector3.new(-6, 0, 0))
	local hatchSec = SlimeData.GetHatchTimeSeconds(slimeDef)

	-- Celebration VFX when Planting the Egg!
	spawnCelebrationBurst(
		hatchPos + Vector3.new(0, 3.0, 0),
		Color3.fromRGB(195, 95, 255),
		slimeDef.Color,
		string.format("🌱 PLANTED %s! (00:%02d)", string.upper(slimeDef.Name), hatchSec)
	)

	if not incubatingEggsByPlayer[player] then
		incubatingEggsByPlayer[player] = {}
	end
	if incubatingEggsByPlayer[player][eggId] and incubatingEggsByPlayer[player][eggId].Model then
		incubatingEggsByPlayer[player][eggId].Model:Destroy()
	end

	local plantedEggModel = SquishyBuilder.CreatePlantedEgg(slimeDef, hatchPos, hatchSec)
	plantedEggModel.Parent = plot.Folder
	if nest then
		nest.HatchedModel = plantedEggModel
	end

	local incState: IncubatingEggState = {
		EggId = eggId,
		SlotIdx = eggId,
		RemainingSec = hatchSec,
		Model = plantedEggModel,
	}
	incubatingEggsByPlayer[player][eggId] = incState

	-- Allow clicking the incubating Egg to speed up countdown by 2s per click!
	local shell = plantedEggModel.PrimaryPart
	if shell then
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 36
		cd.Parent = shell
		cd.MouseClick:Connect(function(clickPlr: Player)
			if clickPlr == player and incState.RemainingSec > 1 then
				incState.RemainingSec = math.max(1, incState.RemainingSec - 2)
			end
		end)
	end

	notifyPlayer(
		player,
		string.format(
			"🌱 PLANTED %s EGG! Watch the 00:%02d Countdown above the Egg (or click it to hatch faster)!",
			slimeDef.Name,
			hatchSec
		),
		"Info"
	)
	syncPlayerState(player)

	-- Live Countdown Loop (00:08 -> 00:00) with Egg Wobble -> Hatch Explosion -> Backpack Tool!
	task.spawn(function()
		local basePivot = plantedEggModel:GetPivot()
		while incState.RemainingSec > 0 and plantedEggModel.Parent ~= nil do
			-- Wobble left & right twice per second as it prepares to hatch!
			for step = 1, 2 do
				if plantedEggModel.Parent == nil then
					break
				end
				local tilt = math.rad(if step == 1 then 14 else -14)
				plantedEggModel:PivotTo(basePivot * CFrame.Angles(0, 0, tilt))
				task.wait(0.5)
			end
			incState.RemainingSec -= 1

			if shell and shell.Parent then
				local tag = shell:FindFirstChild("CountdownTag")
				local tLbl = if tag then tag:FindFirstChild("TimerLabel") :: TextLabel? else nil
				if tLbl then
					tLbl.Text = string.format("00:%02d", math.max(0, incState.RemainingSec))
					if incState.RemainingSec <= 2 then
						tLbl.TextColor3 = Color3.fromRGB(110, 255, 130)
					end
				end
			end
		end

		if not sessions[player] then
			return
		end

		if plantedEggModel.Parent then
			plantedEggModel:Destroy()
		end
		if nest and nest.HatchedModel == plantedEggModel then
			nest.HatchedModel = nil
		end
		if incubatingEggsByPlayer[player] then
			incubatingEggsByPlayer[player][eggId] = nil
		end

		-- MASSIVE HATCH EXPLOSION VFX!
		spawnCelebrationBurst(
			hatchPos + Vector3.new(0, 3.8, 0),
			 Color3.fromRGB(255, 230, 75),
			slimeDef.Color,
			string.format("🐣 HATCHED %s! CHECK BACKPACK!", string.upper(slimeDef.Name))
		)

		-- Reward Hatch Bonus Coins & Put the Hatched Squishy Tool into the Player's Roblox Backpack (Bottom Hotbar)!
		local hatchBonus = slimeDef.CoinsPerSec * 4
		session.Coins += hatchBonus
		local tool = giveHatchedSquishyToolToPlayer(player, slimeDef, 1)

		notifyPlayer(
			player,
			string.format(
				"🐣 %s HATCHED! (+$%s Bonus) Select [🥟 %s] in your bottom Backpack Hotbar & Click in your Pen to place it!",
				string.upper(slimeDef.Name),
				UpgradeData.FormatNumber(hatchBonus),
				slimeDef.Name
			),
			"Success"
		)
		syncPlayerState(player)
	end)
end

-- ============================================================================
-- 5. WIRE UP BASE PEN PADS, WORLD EGGS, OBBY HAZARDS & LEVEL GATES
-- ============================================================================
local function assignPlotToPlayer(player: Player, session: PlayerSession, preferredIdx: number?)
	if session.PlotIndex then
		return
	end
	if preferredIdx and world.Plots[preferredIdx] and world.Plots[preferredIdx].OwnerUserId == nil then
		world.Plots[preferredIdx].OwnerUserId = player.UserId
		session.PlotIndex = preferredIdx
		refreshPlotVisuals(preferredIdx, player, session)
		return
	end
	for idx = 1, 6 do
		if world.Plots[idx].OwnerUserId == nil then
			world.Plots[idx].OwnerUserId = player.UserId
			session.PlotIndex = idx
			refreshPlotVisuals(idx, player, session)
			return
		end
	end
end

local function buyUpgradeAction(player: Player, upgradeCategory: string, extraArg: any)
	local session = sessions[player]
	if not session then
		return
	end

	if upgradeCategory == "ExpandPen" then
		if session.PenTier >= #UpgradeData.PenTiers then
			notifyPlayer(player, "Your Pen is already at Maximum Size (35 Nests)!", "Info")
			return
		end
		local nextPen = UpgradeData.GetPenTier(session.PenTier + 1)
		if session.Coins < nextPen.Cost then
			notifyPlayer(
				player,
				string.format("Need $%s Coins to grow your Pen to %d Nests!", UpgradeData.FormatNumber(nextPen.Cost), nextPen.MaxNests),
				"Error"
			)
			return
		end
		session.Coins -= nextPen.Cost
		session.PenTier += 1
		notifyPlayer(
			player,
			string.format("🏡 PEN EXPANDED TO %s (%d Nest Slots)!", nextPen.Name, nextPen.MaxNests),
			"Success"
		)
		-- If the player is currently holding an Egg on their plot, auto-plant it!
		if session.CarryingEggId then
			plantCarriedEggInPen(player)
		end
	elseif upgradeCategory == "UpgradeTreadmill" then
		if session.TreadmillTier >= #UpgradeData.TreadmillTiers then
			notifyPlayer(player, "Your Treadmill is already at Maximum Tier!", "Info")
			return
		end
		local nextTm = UpgradeData.GetTreadmillTier(session.TreadmillTier + 1)
		if session.Coins < nextTm.Cost then
			notifyPlayer(
				player,
				string.format("Need $%s Coins for %s!", UpgradeData.FormatNumber(nextTm.Cost), nextTm.Name),
				"Error"
			)
			return
		end
		session.Coins -= nextTm.Cost
		session.TreadmillTier += 1
		notifyPlayer(
			player,
			string.format(
				"⚡ UPGRADED TO %s (+%s Speed Power per stride)!",
				nextTm.Name,
				UpgradeData.FormatNumber(nextTm.SpeedPerTick)
			),
			"Success"
		)
	elseif upgradeCategory == "UpgradeGel" then
		if session.GelTier >= #UpgradeData.GelTiers then
			notifyPlayer(player, "Your Pen Gel is already at Maximum Tier!", "Info")
			return
		end
		local nextGel = UpgradeData.GetGelTier(session.GelTier + 1)
		if session.Coins < nextGel.Cost then
			notifyPlayer(
				player,
				string.format("Need $%s Coins for %s!", UpgradeData.FormatNumber(nextGel.Cost), nextGel.Name),
				"Error"
			)
			return
		end
		session.Coins -= nextGel.Cost
		session.GelTier += 1
		notifyPlayer(
			player,
			string.format("🌈 UNLOCKED %s (%.1fx Pen Income)!", nextGel.Name, nextGel.Multiplier),
			"Success"
		)
	elseif upgradeCategory == "UpgradeJump" then
		if session.JumpTier >= #UpgradeData.JumpTiers then
			notifyPlayer(player, "Your Jump Springs are already at Maximum Tier!", "Info")
			return
		end
		local nextJump = UpgradeData.GetJumpTier(session.JumpTier + 1)
		if session.Coins < nextJump.Cost then
			notifyPlayer(
				player,
				string.format("Need $%s Coins for %s!", UpgradeData.FormatNumber(nextJump.Cost), nextJump.Name),
				"Error"
			)
			return
		end
		session.Coins -= nextJump.Cost
		session.JumpTier += 1
		applyCharacterStatsAndTrail(player, session)
		notifyPlayer(player, string.format("🦘 UNLOCKED %s!", nextJump.Name), "Success")
	elseif upgradeCategory == "BuyOrEquipTrail" then
		local trailId = tostring(extraArg)
		local trailDef = UpgradeData.GetTrailById(trailId)
		if not trailDef then
			return
		end
		if not session.OwnedTrails[trailId] then
			if session.Coins < trailDef.Cost then
				-- If a Robux Gamepass ID is configured on create.roblox.com, prompt it; otherwise tell coin price
				if trailDef.RobuxPassId > 0 then
					pcall(function()
						MarketplaceService:PromptGamePassPurchase(player, trailDef.RobuxPassId)
					end)
				end
				notifyPlayer(
					player,
					string.format("Need $%s Coins to unlock %s!", UpgradeData.FormatNumber(trailDef.Cost), trailDef.Name),
					"Error"
				)
				return
			end
			session.Coins -= trailDef.Cost
			session.OwnedTrails[trailId] = true
		end
		session.EquippedTrail = trailId
		applyCharacterStatsAndTrail(player, session)
		notifyPlayer(
			player,
			string.format("🎨 EQUIPPED %s (%.2fx Speed & %.2fx Coins)!", trailDef.Name, trailDef.SpeedMultiplier, trailDef.CoinMultiplier),
			"Success"
		)
	elseif upgradeCategory == "GuideToEgg" then
		local targetEggId = tonumber(extraArg)
		if not targetEggId then
			-- Find the first unplanted Egg for the player
			for _, sDef in ipairs(SlimeData.Slimes) do
				if not session.PlantedEggs[tostring(sDef.Id)] then
					targetEggId = sDef.Id
					break
				end
			end
		end
		if not targetEggId then
			notifyPlayer(player, "🎉 You have already planted ALL 35 Eggs!", "Success")
			return
		end
		local sDef = SlimeData.ById[targetEggId]
		if not sDef then
			return
		end

		if not session.VIPGuideUnlocked then
			local cost = UpgradeData.GuidePricing.SingleEggGuideCoinCost
			if session.Coins < cost then
				if UpgradeData.GuidePricing.GuideDevProductId > 0 then
					pcall(function()
						MarketplaceService:PromptProductPurchase(player, UpgradeData.GuidePricing.GuideDevProductId)
					end)
				end
				notifyPlayer(
					player,
					string.format("Need $%d Coins to hire the 3D Egg Guide Beam!", cost),
					"Error"
				)
				return
			end
			session.Coins -= cost
		end
		session.ActiveGuideEggId = targetEggId
		notifyPlayer(
			player,
			string.format("🧭 EGG GUIDE ACTIVE! Follow the Golden Beam to [%s Egg]! (%s)", sDef.Name, sDef.Hint),
			"Success"
		)
	elseif upgradeCategory == "UnlockVIPGuide" then
		if session.VIPGuideUnlocked then
			notifyPlayer(player, "You already own the Unlimited VIP Egg Guide!", "Info")
			return
		end
		local cost = UpgradeData.GuidePricing.VIPUnlimitedGuideCost
		if session.Coins < cost then
			if UpgradeData.GuidePricing.VIPGuidePassId > 0 then
				pcall(function()
					MarketplaceService:PromptGamePassPurchase(player, UpgradeData.GuidePricing.VIPGuidePassId)
				end)
			end
			notifyPlayer(player, string.format("Need $%s Coins for Unlimited VIP Egg Guide!", UpgradeData.FormatNumber(cost)), "Error")
			return
		end
		session.Coins -= cost
		session.VIPGuideUnlocked = true
		notifyPlayer(player, "🧭 UNLOCKED UNLIMITED VIP EGG GUIDE DIRECTOR!", "Success")
	end

	syncPlayerState(player)
end

-- Hook up all 6 Base Pen Pads
for plotIdx, plot in pairs(world.Plots) do
	local function getTouchingPlayer(hit: BasePart): (Player?, PlayerSession?)
		local char = hit.Parent
		local plr = if char then Players:GetPlayerFromCharacter(char) else nil
		if not plr then
			return nil, nil
		end
		return plr, sessions[plr]
	end

	-- Plant Egg Pad
	plot.PlantPad.Touched:Connect(function(hit)
		local plr, session = getTouchingPlayer(hit)
		if not plr or not session then
			return
		end
		if isOnCooldown("PlantPad_" .. plr.UserId, 0.7) then
			return
		end
		if session.PlotIndex == nil then
			assignPlotToPlayer(plr, session, plotIdx)
		end
		if session.PlotIndex ~= plotIdx then
			notifyPlayer(plr, "That's someone else's Pen! Head to your own Pen (click 🏠 My Pen at top)!", "Warning")
			return
		end
		if session.CarryingEggId then
			plantCarriedEggInPen(plr)
		else
			notifyPlayer(plr, "🥚 Go find a hidden Egg in the Levels and bring it back here to plant it!", "Info")
		end
	end)

	-- Cash Collector Pad (Also allows Family Raid if another player steps on an unshielded Cash Pad!)
	plot.CashPad.Touched:Connect(function(hit)
		local plr, session = getTouchingPlayer(hit)
		if not plr or not session then
			return
		end
		if isOnCooldown("CashPad_" .. plr.UserId, 0.8) then
			return
		end
		if session.PlotIndex == plotIdx then
			if session.StoredPenCoins > 0 then
				local collected = session.StoredPenCoins
				session.StoredPenCoins = 0
				session.Coins += collected
				notifyPlayer(plr, string.format("💰 Collected +$%s from your Squishy Pen!", UpgradeData.FormatNumber(collected)), "Success")
				syncPlayerState(plr)
			end
		elseif plot.OwnerUserId ~= nil then
			-- Family Raid / Steal Bonus!
			for ownerPlr, ownerSession in pairs(sessions) do
				if ownerSession.PlotIndex == plotIdx then
					if os.clock() < ownerSession.ShieldExpiresAt then
						notifyPlayer(plr, "🛡️ Blocked by Laser Shield! You can't raid this Pen right now!", "Error")
					elseif ownerSession.StoredPenCoins >= 20 then
						local stolen = math.floor(ownerSession.StoredPenCoins * 0.35)
						ownerSession.StoredPenCoins -= stolen
						session.Coins += stolen
						notifyPlayer(
							plr,
							string.format("🕵️ RAIDED +$%s Coins from %s's unshielded Pen!", UpgradeData.FormatNumber(stolen), ownerPlr.DisplayName),
							"Warning"
						)
						notifyPlayer(
							ownerPlr,
							string.format("🚨 %s snuck into your Pen and raided $%s! Activate your Laser Shield!", plr.DisplayName, UpgradeData.FormatNumber(stolen)),
							"Error"
						)
						syncPlayerState(plr)
						syncPlayerState(ownerPlr)
					end
					break
				end
			end
		end
	end)

	plot.ExpandPad.Touched:Connect(function(hit)
		local plr, session = getTouchingPlayer(hit)
		if not plr or not session or session.PlotIndex ~= plotIdx then
			return
		end
		if isOnCooldown("ExpandPad_" .. plr.UserId, 1.0) then
			return
		end
		buyUpgradeAction(plr, "ExpandPen", nil)
	end)

	plot.TreadmillUpgradePad.Touched:Connect(function(hit)
		local plr, session = getTouchingPlayer(hit)
		if not plr or not session or session.PlotIndex ~= plotIdx then
			return
		end
		if isOnCooldown("TmPad_" .. plr.UserId, 1.0) then
			return
		end
		buyUpgradeAction(plr, "UpgradeTreadmill", nil)
	end)

	plot.GelUpgradePad.Touched:Connect(function(hit)
		local plr, session = getTouchingPlayer(hit)
		if not plr or not session or session.PlotIndex ~= plotIdx then
			return
		end
		if isOnCooldown("GelPad_" .. plr.UserId, 1.0) then
			return
		end
		buyUpgradeAction(plr, "UpgradeGel", nil)
	end)

	plot.ShieldPad.Touched:Connect(function(hit)
		local plr, session = getTouchingPlayer(hit)
		if not plr or not session or session.PlotIndex ~= plotIdx then
			return
		end
		if isOnCooldown("ShieldPad_" .. plr.UserId, 1.2) then
			return
		end
		session.ShieldExpiresAt = os.clock() + 60
		notifyPlayer(plr, "🛡️ Base Laser Shield Activated for 60 seconds!", "Success")
		syncPlayerState(plr)
	end)
	-- Clicking the Pen Lawn or any Nest Pedestal while holding a Backpack Squishy Tool places it in your Pen!
	local function handlePlaceClick(clickPlr: Player)
		local session = sessions[clickPlr]
		if not session or session.PlotIndex ~= plotIdx then
			return
		end
		-- Check if holding a Squishy Tool in Character
		local char = clickPlr.Character
		if char then
			for _, child in ipairs(char:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute("IsSquishyTool") then
					local eggId = tonumber(child:GetAttribute("SlimeId"))
					if eggId then
						placeBackpackSquishyInPen(clickPlr, eggId, child)
						return
					end
				end
			end
		end
		-- Or if they have a Hatched Squishy in their Backpack, place the first one!
		for idStr in pairs(session.BackpackEggs) do
			local eggId = tonumber(idStr)
			if eggId then
				placeBackpackSquishyInPen(clickPlr, eggId, nil)
				return
			end
		end
	end

	local penLawn = plot.Folder:FindFirstChild("PenLawn")
	local lawnCd = if penLawn then penLawn:FindFirstChild("PlaceSquishyClick") :: ClickDetector? else nil
	if lawnCd then
		lawnCd.MouseClick:Connect(handlePlaceClick)
	end
	for _, nest in pairs(plot.Nests) do
		local slotCd = nest.Pedestal:FindFirstChild("PlaceSlotClick") :: ClickDetector?
		if slotCd then
			slotCd.MouseClick:Connect(handlePlaceClick)
		end
	end
end

-- Hook up World Eggs (Touch OR ProximityPrompt "Steal" to Pickup / BounceWake 3x to Wake)
for eggId, eggModel in pairs(world.WorldEggs) do
	local slimeDef = SlimeData.ById[eggId]
	local primary = eggModel.PrimaryPart
	if primary and slimeDef then
		local function tryStealEgg(plr: Player, fromPrompt: boolean)
			local session = sessions[plr]
			local char = plr.Character
			if not session or not char then
				return
			end
			if isOnCooldown("EggTouch_" .. plr.UserId .. "_" .. eggId, 0.55) then
				return
			end

			local idStr = tostring(eggId)
			if session.PlantedEggs[idStr] then
				notifyPlayer(plr, string.format("✅ You already placed %s in your Pen!", slimeDef.Name), "Info")
				return
			end
			if session.BackpackEggs[idStr] then
				notifyPlayer(plr, string.format("🎒 You already hatched %s! Select it in your Backpack Hotbar to place it in your Pen!", slimeDef.Name), "Info")
				return
			end
			if session.CarryingEggId == eggId then
				return
			end

			if slimeDef.IsMicroVent and not session.TinyMode then
				notifyPlayer(
					plr,
					"🐭 Too big to reach inside the Tiny Vent! Open [📘 Index] -> Toggle [Tiny Squishy Size]!",
					"Warning"
				)
				return
			end

			if slimeDef.Behavior == "BounceWake" and not fromPrompt then
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 78, hrp.AssemblyLinearVelocity.Z)
				end
				local bounces = (eggModel:GetAttribute("BounceCount_" .. plr.UserId) or 0) + 1
				eggModel:SetAttribute("BounceCount_" .. plr.UserId, bounces)
				if bounces < 3 then
					notifyPlayer(
						plr,
						string.format("😴 *BOING!* (%d/3 Bounces to wake %s Egg — or press [E] Steal!)", bounces, slimeDef.Name),
						"Info"
					)
					return
				end
				eggModel:SetAttribute("BounceCount_" .. plr.UserId, 0)
			end

			attachCarriedEggToPlayer(plr, slimeDef)
		end

		primary.Touched:Connect(function(hit: BasePart)
			local char = hit.Parent
			local plr = if char then Players:GetPlayerFromCharacter(char) else nil
			if plr then
				tryStealEgg(plr, false)
			end
		end)

		local stealPrompt = primary:FindFirstChild("StealPrompt") :: ProximityPrompt?
		if stealPrompt then
			stealPrompt.Triggered:Connect(function(plr: Player)
				tryStealEgg(plr, true)
			end)
		end
	end
end

-- Hook up Trampolines & Obby Laser Hazards across the World
for _, inst in ipairs(Workspace.SquishyWorld:GetDescendants()) do
	if inst:IsA("BasePart") then
		if inst:GetAttribute("IsTrampoline") then
			inst.Touched:Connect(function(hit: BasePart)
				local char = hit.Parent
				local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				if hrp and not isOnCooldown("Tramp_" .. tostring(char), 0.35) then
					hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 105, hrp.AssemblyLinearVelocity.Z)
				end
			end)
		elseif inst:GetAttribute("IsObbyHazard") then
			inst.Touched:Connect(function(hit: BasePart)
				local char = hit.Parent
				local plr = if char then Players:GetPlayerFromCharacter(char) else nil
				local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				if plr and hrp and not isOnCooldown("Hazard_" .. plr.UserId, 0.9) then
					hrp.AssemblyLinearVelocity = Vector3.new(0, 58, 42)
					notifyPlayer(plr, "⚡ Ouch! Watch out for the Obby Lasers & Lava! Upgrade Jump Springs to clear them!", "Warning")
				end
			end)
		end
	end
end

-- ============================================================================
-- 6. CLIENT ACTION REQUEST HANDLER (UI Buttons, Backpack Place, Level Up, Morphs, Teleports)
-- ============================================================================
actionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
	if type(payload) ~= "table" then
		return
	end
	local session = sessions[player]
	if not session then
		return
	end

	local action = payload.Action
	if action == "BuyUpgrade" then
		buyUpgradeAction(player, tostring(payload.Category), payload.Arg)
	elseif action == "UpgradeSquishyLevel" then
		local eggId = tonumber(payload.SlimeId)
		if eggId then
			upgradePlacedSquishy(player, eggId)
		end
	elseif action == "PlaceBackpackSquishy" then
		local eggId = tonumber(payload.SlimeId)
		if eggId and session.BackpackEggs[tostring(eggId)] then
			placeBackpackSquishyInPen(player, eggId, nil)
		end
	elseif action == "MorphSlime" then
		local slimeId = tonumber(payload.SlimeId)
		if not slimeId or slimeId == 0 then
			session.CurrentMorphId = nil
			applyCharacterStatsAndTrail(player, session)
			notifyPlayer(player, "Returned to Normal Avatar!", "Info")
		elseif session.PlantedEggs[tostring(slimeId)] or session.BackpackEggs[tostring(slimeId)] then
			session.CurrentMorphId = slimeId
			applyCharacterStatsAndTrail(player, session)
			local sDef = SlimeData.ById[slimeId]
			if sDef then
				notifyPlayer(player, string.format("✨ Morphed into %s!", sDef.Name), "Success")
			end
		else
			notifyPlayer(player, "Plant & Hatch this Egg in your Pen first to unlock its Morph!", "Error")
		end
		syncPlayerState(player)
	elseif action == "ToggleTiny" then
		session.TinyMode = not session.TinyMode
		applyCharacterStatsAndTrail(player, session)
		notifyPlayer(
			player,
			if session.TinyMode
				then "🐭 TINY SQUISHY SIZE ON! You can now crawl inside Tiny Mousehole Vents!"
				else "🐘 Normal Size restored!",
			"Info"
		)
		syncPlayerState(player)
	elseif action == "DropDecoyWeight" then
		local char = player.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if hrp then
			local bestPlate: BasePart? = nil
			local bestDist = 80
			for _, pair in pairs(world.CoopPlates) do
				local d = (pair.PlateB.Position - hrp.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestPlate = pair.PlateB
				end
			end
			local dropPos = if bestPlate then bestPlate.Position + Vector3.new(0, 2.2, 0) else hrp.Position + Vector3.new(0, 2, -4)
			local decoy = SquishyBuilder.CreateHatchedSquishy(SlimeData.ById[1], dropPos, session.GelTier, 1)
			decoy.Name = "DecoyBuddyWeight"
			decoy:SetAttribute("IsDecoyWeight", true)
			decoy.Parent = Workspace
			Debris:AddItem(decoy, 25)
			notifyPlayer(player, "🪨 Dropped Helper Squishy Weight on Buddy Plate B for 25s!", "Success")
		end
	elseif action == "TeleportTo" then
		local target = tostring(payload.Target)
		local char = player.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if not hrp then
			return
		end
		if target == "BasePen" and session.PlotIndex then
			local plot = world.Plots[session.PlotIndex]
			if session.CarryingEggId and hrp.Position.Z < -65 then
				notifyPlayer(player, "🏃 You're carrying an Egg! Outrun the Boss Guardian to the Green Safe Line first!", "Warning")
				return
			end
			hrp.CFrame = CFrame.new(plot.PlantPad.Position + Vector3.new(0, 4, 0))
			if session.CarryingEggId then
				plantCarriedEggInPen(player)
			end
		elseif target == "Treadmill" and session.PlotIndex then
			if session.CarryingEggId and hrp.Position.Z < -65 then
				notifyPlayer(player, "🏃 Outrun the Chasers to the Safe Zone before teleporting!", "Warning")
				return
			end
			local plot = world.Plots[session.PlotIndex]
			hrp.CFrame = CFrame.new(plot.TreadmillBelt.Position + Vector3.new(0, 4, 0))
		end
	elseif action == "EquipSlapTool" then
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack and not backpack:FindFirstChild("Slime Slap Glove") and not (player.Character and player.Character:FindFirstChild("Slime Slap Glove")) then
			local tool = Instance.new("Tool")
			tool.Name = "Slime Slap Glove"
			tool.RequiresHandle = true

			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(2.2, 2.2, 1.2)
			handle.Material = Enum.Material.Neon
			handle.Color = Color3.fromRGB(110, 255, 130)
			handle.Parent = tool

			tool.Activated:Connect(function()
				local char = player.Character
				local myHrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				if not myHrp then
					return
				end
				for _, otherPlr in ipairs(Players:GetPlayers()) do
					if otherPlr ~= player and otherPlr.Character then
						local otherHrp = otherPlr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						local otherSession = sessions[otherPlr]
						if otherHrp and (otherHrp.Position - myHrp.Position).Magnitude <= 12 then
							local dir = (otherHrp.Position - myHrp.Position).Unit
							otherHrp.AssemblyLinearVelocity = dir * 65 + Vector3.new(0, 48, 0)
							if otherSession and otherSession.CarryingEggId and not session.CarryingEggId then
								local stolenId = otherSession.CarryingEggId
								local sDef = SlimeData.ById[stolenId]
								clearCarriedEgg(otherPlr)
								syncPlayerState(otherPlr)
								if sDef then
									attachCarriedEggToPlayer(player, sDef)
									notifyPlayer(player, string.format("👋 SLIME-SLAPPED %s and snatched the %s Egg!", otherPlr.DisplayName, sDef.Name), "Success")
									notifyPlayer(otherPlr, string.format("😱 %s booped you with a Slime Slap and stole your carried Egg!", player.DisplayName), "Error")
								end
							else
								notifyPlayer(player, string.format("👋 Booped %s with the Slime Slap Glove!", otherPlr.DisplayName), "Info")
							end
						end
					end
				end
			end)

			tool.Parent = backpack
			notifyPlayer(player, "🧤 Equipped the Slime Slap Glove! Check your Hotbar at the bottom!", "Success")
		else
			notifyPlayer(player, "🧤 Slime Slap Glove is already in your Backpack/Hand!", "Info")
		end
	elseif action == "FamilyBoost" then
		local boostType = tostring(payload.BoostType)
		if boostType == "Coins" then
			session.Coins += 25000
			notifyPlayer(player, "🎁 Family Boost: +$25,000 Coins added!", "Success")
		elseif boostType == "Speed" then
			session.SpeedPower = math.max(session.SpeedPower * 3, session.SpeedPower + 50000)
			applyCharacterStatsAndTrail(player, session)
			notifyPlayer(player, string.format("⚡ Family Boost: Speed Power boosted to %s!", UpgradeData.FormatNumber(session.SpeedPower)), "Success")
		elseif boostType == "PlantCurrentLevel" then
			local maxLvl = getMaxUnlockedLevel(session)
			local targetTier = math.max(session.PenTier, maxLvl)
			session.PenTier = targetTier
			for _, sDef in ipairs(SlimeData.ByLevel[maxLvl] or {}) do
				local idStr = tostring(sDef.Id)
				session.PlantedEggs[idStr] = true
				session.SquishyLevels[idStr] = math.max(1, session.SquishyLevels[idStr] or 1)
			end
			notifyPlayer(player, string.format("🐣 Family Boost: Hatched & Placed all Level %d Squishies!", maxLvl), "Success")
		end
		syncPlayerState(player)
	end
end)

-- ============================================================================
-- 7. MASTER HEARTBEAT LOOPS (Treadmill, Guardian Chasers, Living Eggs, Gates, Income)
-- ============================================================================

-- Loop A: Passive Pen Income & Dino-Jaw Treadmill Speed Training (Every 0.5s)
task.spawn(function()
	local tickCounter = 0
	while true do
		task.wait(0.5)
		tickCounter += 1

		for _, player in ipairs(Players:GetPlayers()) do
			local session = sessions[player]
			if session then
				if tickCounter % 2 == 0 then
					local income = getTotalIncomePerSec(session)
					if income > 0 then
						session.StoredPenCoins += income
					end
				end

				local char = player.Character
				local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
				if hrp and hum and hum.Health > 0 then
					local pos = hrp.Position

					local onTreadmill = false
					if session.PlotIndex then
						local myBelt = world.Plots[session.PlotIndex].TreadmillBelt
						local rel = myBelt.CFrame:PointToObjectSpace(pos)
						if math.abs(rel.X) <= (myBelt.Size.X / 2 + 2.5) and math.abs(rel.Z) <= (myBelt.Size.Z / 2 + 2.5) and math.abs(rel.Y) <= 6 then
							onTreadmill = true
						end
					end
					if not onTreadmill then
						local pubBelt = Workspace.SquishyWorld:FindFirstChild("HubPublicTreadmill") :: BasePart?
						if pubBelt then
							local rel = pubBelt.CFrame:PointToObjectSpace(pos)
							if math.abs(rel.X) <= (pubBelt.Size.X / 2 + 2.5) and math.abs(rel.Z) <= (pubBelt.Size.Z / 2 + 2.5) and math.abs(rel.Y) <= 6 then
								onTreadmill = true
							end
						end
					end

					if onTreadmill then
						local tmDef = UpgradeData.GetTreadmillTier(session.TreadmillTier)
						local trailDef = UpgradeData.GetTrailById(session.EquippedTrail)
						local trailMult = if trailDef then trailDef.SpeedMultiplier else 1.0
						local gain = math.floor(tmDef.SpeedPerTick * trailMult)
						session.SpeedPower += gain
						hum.WalkSpeed = UpgradeData.SpeedPowerToWalkSpeed(session.SpeedPower)

						-- Floating Red Sneaker "+Speed" Popup just like real_frame_a_01.png!
						local popPart = Instance.new("Part")
						popPart.Name = "SneakerSpeedPopup"
						popPart.Size = Vector3.new(0.2, 0.2, 0.2)
						popPart.Transparency = 1
						popPart.Anchored = true
						popPart.CanCollide = false
						popPart.Position = pos + Vector3.new(math.random(-35, 35) / 10, math.random(10, 35) / 10, math.random(-35, 35) / 10)
						popPart.Parent = Workspace

						local sbb = Instance.new("BillboardGui")
						sbb.Size = UDim2.new(0, 125, 0, 42)
						sbb.AlwaysOnTop = true
						sbb.MaxDistance = 60
						sbb.Parent = popPart

						local slbl = Instance.new("TextLabel")
						slbl.Size = UDim2.new(1, 0, 1, 0)
						slbl.BackgroundTransparency = 1
						slbl.Font = Enum.Font.FredokaOne
						slbl.TextScaled = true
						slbl.TextColor3 = Color3.fromRGB(95, 245, 115)
						slbl.TextStrokeColor3 = Color3.fromRGB(15, 25, 20)
						slbl.TextStrokeTransparency = 0
						slbl.Text = "👟 +" .. UpgradeData.FormatNumber(gain)
						slbl.Parent = sbb

						TweenService:Create(popPart, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Position = popPart.Position + Vector3.new(0, 4.2, 0),
						}):Play()
						Debris:AddItem(popPart, 0.8)
					end

					-- Floor Coloring Paint Trail Splat when moving!
					local trailDef = UpgradeData.GetTrailById(session.EquippedTrail)
					if trailDef and trailDef.PaintFloor and hum.MoveDirection.Magnitude > 0.1 then
						local splat = Instance.new("Part")
						splat.Name = "PaintSplat"
						splat.Shape = Enum.PartType.Cylinder
						splat.Anchored = true
						splat.CanCollide = false
						splat.Material = Enum.Material.Neon
						splat.Color = if trailDef.Rainbow
							then Color3.fromHSV((os.clock() * 0.6) % 1, 0.85, 1)
							else trailDef.Color1
						splat.Size = Vector3.new(0.2, 3.6, 3.6)
						splat.CFrame = CFrame.new(pos.X, 0.12, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
						splat.Transparency = 0.25
						splat.Parent = paintFolder
						Debris:AddItem(splat, 3.5)
					end

					-- Server-Side Level Gate Enforcement
					local maxUnlocked = getMaxUnlockedLevel(session)
					for gateLvl = 1, 4 do
						local gatePart = world.LevelGates[gateLvl]
						if gatePart and maxUnlocked <= gateLvl and pos.Z < (gatePart.Position.Z - 1.0) then
							hrp.CFrame = CFrame.new(math.clamp(pos.X, -65, 65), 5, gatePart.Position.Z + 8)
							if not isOnCooldown("GateWarn_" .. player.UserId, 2.0) then
								local plantedInLvl = getPlantedCount(session, gateLvl)
								local totalInLvl = #(SlimeData.ByLevel[gateLvl] or {})
								notifyPlayer(
									player,
									string.format(
										"🔒 Gate Locked! You must HATCH & PLACE all %d Squishies in Level %d first! (%d/%d)",
										totalInLvl,
										gateLvl,
										plantedInLvl,
										totalInLvl
									),
									"Error"
								)
							end
							break
						end
					end
				end

				if tickCounter % 2 == 0 then
					updateLeaderstats(player, session)
					if session.PlotIndex then
						local plot = world.Plots[session.PlotIndex]
						if plot then
							plot.CashLabel.Text = string.format("$%s Ready to Collect!", UpgradeData.FormatNumber(session.StoredPenCoins))
						end
					end
					stateSyncRemote:FireClient(player, {
						Coins = session.Coins,
						StoredPenCoins = session.StoredPenCoins,
						SpeedPower = session.SpeedPower,
						WalkSpeed = UpgradeData.SpeedPowerToWalkSpeed(session.SpeedPower),
						IncomePerSec = getTotalIncomePerSec(session),
						LightTick = true,
					})
				end
			end
		end
	end
end)

-- Loop B: Colossal Boss Guardians AI ("Zzz" -> "!!") + Living Eggs + Co-op Buddy Vaults (Distance-Culled for 60 FPS!)
task.spawn(function()
	local dt = 0.18
	while true do
		task.wait(dt)
		local now = os.clock()

		-- Gather active player positions once per tick
		local playerPositions: { Vector3 } = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			local hrp = if plr.Character then plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			if hrp then
				table.insert(playerPositions, hrp.Position)
			end
		end

		-- 1. Update Colossal Boss Guardians (Only when a player is within 260 studs!)
		for gId, gEntry in pairs(world.WorldGuardians) do
			local gDef = gEntry.Def
			local gModel = gEntry.Model
			local gBody = gModel.PrimaryPart
			local lvlDef = SlimeData.Levels[gDef.Level]
			if gBody and lvlDef then
				local anyPlayerNear = false
				for _, pPos in ipairs(playerPositions) do
					if math.abs(pPos.Z - gBody.Position.Z) <= 240 then
						anyPlayerNear = true
						break
					end
				end

				if anyPlayerNear then
					local targetPlayer: Player? = nil
					local targetHrp: BasePart? = nil
					local bestDist = 240

					for _, plr in ipairs(Players:GetPlayers()) do
						local session = sessions[plr]
						local char = plr.Character
						local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
						if session and session.CarryingEggId and hrp then
							local pPos = hrp.Position
							if pPos.Z <= (lvlDef.ZStart - 2) and pPos.Z >= (lvlDef.ZEnd - 5) then
								local dist = (pPos - gBody.Position).Magnitude
								if dist < bestDist then
									bestDist = dist
									targetPlayer = plr
									targetHrp = hrp
								end
							end
						end
					end

					local tagGui = gBody:FindFirstChild("GuardianTag")
					local statusLbl = if tagGui then tagGui:FindFirstChild("StatusLabel") :: TextLabel? else nil
					local headPart = gModel:FindFirstChild("Head")
					local sleepGui = if headPart then headPart:FindFirstChild("SleepEmoteGui") else nil
					local emoteLbl = if sleepGui then sleepGui:FindFirstChild("EmoteLabel") :: TextLabel? else nil

					if targetPlayer and targetHrp then
						-- WAKE UP ("!!") & CHASE THE EGG THIEF!
						if emoteLbl then
							emoteLbl.Text = "!!"
							emoteLbl.TextColor3 = Color3.fromRGB(255, 55, 65)
						end

						local targetPos = Vector3.new(targetHrp.Position.X, gDef.HomePosition.Y, targetHrp.Position.Z)
						local delta = targetPos - gBody.Position
						local dist = delta.Magnitude

						local session = sessions[targetPlayer]
						local playerSpdPower = if session then session.SpeedPower else 100
						local speedRatio = math.clamp(gDef.RequiredSpeedPower / math.max(100, playerSpdPower), 0.55, 1.35)
						local effectiveStep = gDef.ChaseSpeed * speedRatio * dt

						if statusLbl then
							statusLbl.Text = string.format(
								"🚨 AWAKE! CHASING %s! (Req: %s Spd)",
								string.upper(targetPlayer.DisplayName),
								UpgradeData.FormatNumber(gDef.RequiredSpeedPower)
							)
							statusLbl.TextColor3 = Color3.fromRGB(255, 75, 75)
						end

						if dist > 0.5 then
							local moveDir = delta.Unit
							local nextPos = gBody.Position + moveDir * math.min(dist, effectiveStep)
							local bounceY = math.abs(math.sin(now * 10)) * 1.4
							gModel:PivotTo(CFrame.lookAt(nextPos + Vector3.new(0, bounceY, 0), targetPos + Vector3.new(0, bounceY, 0)))
						end

						if dist <= 6.2 and session then
							local droppedId = session.CarryingEggId
							local droppedDef = if droppedId then SlimeData.ById[droppedId] else nil
							clearCarriedEgg(targetPlayer)
							targetHrp.AssemblyLinearVelocity = Vector3.new(0, 68, 55)
							notifyPlayer(
								targetPlayer,
								string.format(
									"💥 CAUGHT BY %s! You dropped the %s Egg! Train on your Dino Treadmill to reach %s Speed Power!",
									string.upper(gDef.Name),
									if droppedDef then droppedDef.Name else "Squishy",
									UpgradeData.FormatNumber(gDef.RequiredSpeedPower)
								),
								"Error"
							)
							syncPlayerState(targetPlayer)
						end
					else
						-- SLEEPING / GUARDING MODE ("Zzz")
						if emoteLbl then
							emoteLbl.Text = if math.floor(now * 2) % 2 == 0 then "Zzz" else "Z"
							emoteLbl.TextColor3 = Color3.fromRGB(65, 225, 255)
						end
						if statusLbl then
							statusLbl.Text = string.format(
								"💤 Sleeping near Eggs (Speed: %s)",
								UpgradeData.FormatNumber(gDef.RequiredSpeedPower)
							)
							statusLbl.TextColor3 = Color3.fromRGB(125, 235, 255)
						end

						local wp = guardianWaypoints[gId]
						if not wp or (wp - gBody.Position).Magnitude < 5 then
							local angle = math.random() * math.pi * 2
							local r = math.random(18, gDef.PatrolRadius)
							wp = Vector3.new(
								math.clamp(gDef.HomePosition.X + math.cos(angle) * r, -95, 95),
								gDef.HomePosition.Y,
								math.clamp(gDef.HomePosition.Z + math.sin(angle) * (r * 0.65), lvlDef.ZEnd + 18, lvlDef.ZStart - 16)
							)
							guardianWaypoints[gId] = wp
						end

						local delta = wp - gBody.Position
						if delta.Magnitude > 0.5 then
							local nextPos = gBody.Position + delta.Unit * math.min(delta.Magnitude, gDef.PatrolSpeed * dt)
							local hopY = math.abs(math.sin(now * 4)) * 0.45
							gModel:PivotTo(CFrame.lookAt(nextPos + Vector3.new(0, hopY, 0), wp + Vector3.new(0, hopY, 0)))
						end
					end
				end
			end
		end

		-- 2. Update Living Egg Behaviors (Only when a player is nearby!)
		for eggId, eggModel in pairs(world.WorldEggs) do
			local sDef = SlimeData.ById[eggId]
			local primary = eggModel.PrimaryPart
			if sDef and primary then
				if sDef.Behavior == "Runaway" then
					local basePos = sDef.Position
					local curPos = eggLiveOffsets[eggId] or basePos
					local closestHrp: BasePart? = nil
					local closestDist = 18
					for _, plr in ipairs(Players:GetPlayers()) do
						local session = sessions[plr]
						if session and not session.PlantedEggs[tostring(eggId)] and plr.Character then
							local hrp = plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
							if hrp then
								local d = (hrp.Position - curPos).Magnitude
								if d < closestDist then
									closestDist = d
									closestHrp = hrp
								end
							end
						end
					end
					if closestHrp then
						local fleeDir = Vector3.new(curPos.X - closestHrp.Position.X, 0, curPos.Z - closestHrp.Position.Z)
						if fleeDir.Magnitude > 0.1 then
							local nextPos = curPos + fleeDir.Unit * (14 * dt)
							nextPos = Vector3.new(
								math.clamp(nextPos.X, basePos.X - 20, basePos.X + 20),
								basePos.Y + math.abs(math.sin(now * 9)) * 1.4,
								math.clamp(nextPos.Z, basePos.Z - 16, basePos.Z + 16)
							)
							eggLiveOffsets[eggId] = nextPos
							eggModel:PivotTo(CFrame.new(nextPos))
						end
					elseif (curPos - basePos).Magnitude > 0.25 then
						local returnPos = curPos:Lerp(basePos, 0.15)
						eggLiveOffsets[eggId] = returnPos
						eggModel:PivotTo(CFrame.new(returnPos))
					end
				elseif sDef.Behavior == "Disguised" then
					local disguisePart = eggModel:FindFirstChild("DisguiseShell") :: BasePart?
					if disguisePart then
						local someoneNear = false
						for _, plr in ipairs(Players:GetPlayers()) do
							if plr.Character then
								local hrp = plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
								if hrp and (hrp.Position - primary.Position).Magnitude <= 20 then
									someoneNear = true
									break
								end
							end
						end
						disguisePart.Transparency = if someoneNear then 0.68 else 0.02
					end
				end
			end
		end

		-- 3. Update Co-op Buddy Plates
		for lvlNum, plates in pairs(world.CoopPlates) do
			local door = world.CoopDoors[lvlNum]
			if door then
				local aPressed = false
				local bPressed = false
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr.Character then
						local hrp = plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						if hrp then
							if (hrp.Position - plates.PlateA.Position).Magnitude <= 6.5 then
								aPressed = true
							end
							if (hrp.Position - plates.PlateB.Position).Magnitude <= 6.5 then
								bPressed = true
							end
						end
					end
				end
				if not bPressed then
					for _, child in ipairs(Workspace:GetChildren()) do
						if child.Name == "DecoyBuddyWeight" and child:IsA("Model") and child.PrimaryPart then
							if (child.PrimaryPart.Position - plates.PlateB.Position).Magnitude <= 8 then
								bPressed = true
								break
							end
						end
					end
				end

				local vaultOpen = (aPressed and bPressed) or bPressed
				plates.PlateA.Color = if aPressed then Color3.fromRGB(85, 255, 120) else Color3.fromRGB(255, 185, 55)
				plates.PlateB.Color = if bPressed then Color3.fromRGB(85, 255, 120) else Color3.fromRGB(255, 185, 55)
				door.CanCollide = not vaultOpen
				door.Transparency = if vaultOpen then 0.85 else 0.25
				door.Color = if vaultOpen then Color3.fromRGB(85, 255, 125) else Color3.fromRGB(255, 75, 95)
			end
		end
	end
end)

-- ============================================================================
-- 8. PLAYER JOIN / LEAVE & DATASTORE PERSISTENCE
-- ============================================================================
local function loadPlayerSession(player: Player): PlayerSession
	local defaultSession: PlayerSession = {
		UserId = player.UserId,
		Coins = 100,
		StoredPenCoins = 0,
		SpeedPower = 100,
		PenTier = 1,
		TreadmillTier = 1,
		GelTier = 1,
		JumpTier = 1,
		PlantedEggs = {},
		SquishyLevels = {},
		BackpackEggs = {},
		OwnedTrails = {},
		EquippedTrail = "",
		VIPGuideUnlocked = false,
		ActiveGuideEggId = nil,
		CurrentMorphId = nil,
		TinyMode = false,
		CarryingEggId = nil,
		PlotIndex = nil,
		ShieldExpiresAt = 0,
	}

	if dataStore then
		local ok, saved = pcall(function()
			return dataStore:GetAsync("Player_" .. tostring(player.UserId))
		end)
		if ok and type(saved) == "table" then
			defaultSession.Coins = tonumber(saved.Coins) or 100
			defaultSession.SpeedPower = tonumber(saved.SpeedPower) or 100
			defaultSession.PenTier = tonumber(saved.PenTier) or 1
			defaultSession.TreadmillTier = tonumber(saved.TreadmillTier) or 1
			defaultSession.GelTier = tonumber(saved.GelTier) or 1
			defaultSession.JumpTier = tonumber(saved.JumpTier) or 1
			if type(saved.PlantedEggs) == "table" then
				defaultSession.PlantedEggs = saved.PlantedEggs
			end
			if type(saved.SquishyLevels) == "table" then
				defaultSession.SquishyLevels = saved.SquishyLevels
			end
			if type(saved.BackpackEggs) == "table" then
				defaultSession.BackpackEggs = saved.BackpackEggs
			end
			if type(saved.OwnedTrails) == "table" then
				defaultSession.OwnedTrails = saved.OwnedTrails
			end
			defaultSession.EquippedTrail = tostring(saved.EquippedTrail or "")
			defaultSession.VIPGuideUnlocked = saved.VIPGuideUnlocked == true
		end
	end

	return defaultSession
end

local function savePlayerSession(player: Player)
	local session = sessions[player]
	if not session or not dataStore then
		return
	end
	pcall(function()
		dataStore:SetAsync("Player_" .. tostring(player.UserId), {
			Coins = session.Coins + session.StoredPenCoins,
			SpeedPower = session.SpeedPower,
			PenTier = session.PenTier,
			TreadmillTier = session.TreadmillTier,
			GelTier = session.GelTier,
			JumpTier = session.JumpTier,
			PlantedEggs = session.PlantedEggs,
			SquishyLevels = session.SquishyLevels,
			BackpackEggs = session.BackpackEggs,
			OwnedTrails = session.OwnedTrails,
			EquippedTrail = session.EquippedTrail,
			VIPGuideUnlocked = session.VIPGuideUnlocked,
		})
	end)
end

local function onPlayerAdded(player: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local plantedStat = Instance.new("StringValue")
	plantedStat.Name = "Planted Eggs"
	plantedStat.Value = "0 / 35"
	plantedStat.Parent = ls

	local speedStat = Instance.new("StringValue")
	speedStat.Name = "Speed Power"
	speedStat.Value = "100"
	speedStat.Parent = ls

	local coinsStat = Instance.new("StringValue")
	coinsStat.Name = "Coins"
	coinsStat.Value = "$100"
	coinsStat.Parent = ls

	local session = loadPlayerSession(player)
	sessions[player] = session
	assignPlotToPlayer(player, session, nil)

	local function restoreBackpackTools()
		for idStr, lvl in pairs(session.BackpackEggs) do
			local id = tonumber(idStr)
			local sDef = if id then SlimeData.ById[id] else nil
			if sDef then
				giveHatchedSquishyToolToPlayer(player, sDef, lvl)
			end
		end
	end

	player.CharacterAdded:Connect(function(character: Model)
		clearCarriedEgg(player)
		task.wait(0.25)
		applyCharacterStatsAndTrail(player, session)
		restoreBackpackTools()
		if session.PlotIndex then
			local plot = world.Plots[session.PlotIndex]
			local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and plot then
				hrp.CFrame = CFrame.new(plot.PlantPad.Position + Vector3.new(0, 4, 6))
			end
		end
		syncPlayerState(player)
	end)

	player.CharacterRemoving:Connect(function()
		clearCarriedEgg(player)
	end)

	if player.Character then
		task.spawn(function()
			applyCharacterStatsAndTrail(player, session)
			restoreBackpackTools()
			syncPlayerState(player)
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, plr)
end

Players.PlayerRemoving:Connect(function(player: Player)
	clearCarriedEgg(player)
	if incubatingEggsByPlayer[player] then
		for _, inc in pairs(incubatingEggsByPlayer[player]) do
			if inc.Model and inc.Model.Parent then
				inc.Model:Destroy()
			end
		end
		incubatingEggsByPlayer[player] = nil
	end
	local session = sessions[player]
	if session and session.PlotIndex then
		refreshPlotVisuals(session.PlotIndex, nil, nil)
	end
	savePlayerSession(player)
	sessions[player] = nil
end)

game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		savePlayerSession(plr)
	end
end)
