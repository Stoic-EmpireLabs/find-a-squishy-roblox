--!strict
--[[
	GameServer.server.luau
	Pure "Steal My Egg!" Server Controller:
	  1. Steal Oversized Ornate Eggs from Sleeping Bosses (Hold E)
	  2. Exact Drop-In-Place Mechanic:
	     - Getting hit by a Boss, Hazard Moat, Spinning Sweeper, or Bat/Bear Trap
	       STOPS and DROPS the Egg at that EXACT ground spot (does NOT reset to nest!)
	     - Dropped Eggs stay at that spot with "[HOLD] Egg - Steal (Dropped!)" until stolen again
	     - Only when an Egg is Planted in a Base Incubator does a new Egg respawn at the Boss Nest
	  3. Base Plot Loop:
	     - Plant Egg in Purple Incubator Ring -> 00:05 Hatch Countdown -> Pick Up Hatched Squishy Tool
	     - Equip Squishy Tool -> Place on Lawn Pedestal -> Upgrade Level -> Collect $/sec Cash Chest
	     - Run on Giant 18-Stud Green Dino-Jaw Treadmill -> Permanent +1 Speed!
	  4. Hotbar Gear ("Bat" & "Bear Trap x3") to stun chasing Bosses or knock rival egg carriers
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SlimeData = require(Shared:WaitForChild("SlimeData"))
local SquishyBuilder = require(Shared:WaitForChild("SquishyBuilder"))
local PrebuiltLoader = require(Shared:WaitForChild("PrebuiltLoader"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

Workspace:SetAttribute("AgeRatingPolicy", "AllAges_Kids")
Workspace:SetAttribute("MaxPlayersPerServer", 7)
pcall(function()
	(Players :: any).MaxPlayersInternal = 7
end)
Players:SetAttribute("MaxPlayers", 7)

-- Ensure Remotes exist
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function ensureRemoteEvent(name: string): RemoteEvent
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = remotesFolder
	return ev
end

local function ensureRemoteFunction(name: string): RemoteFunction
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing
	end
	local fn = Instance.new("RemoteFunction")
	fn.Name = name
	fn.Parent = remotesFolder
	return fn
end

local StateSyncEvent = ensureRemoteEvent("StateSync")
local EggCapturedEvent = ensureRemoteEvent("SquishyCaptured")
local CoinCollectedEvent = ensureRemoteEvent("CoinCollected")
local GuardianAlertEvent = ensureRemoteEvent("GuardianAlert")
local EquipSquishyEvent = ensureRemoteEvent("EquipSquishy")
local BuySpeedUpgradeEvent = ensureRemoteEvent("BuySpeedUpgrade")
local BuyFenceUpgradeEvent = ensureRemoteEvent("BuyFenceUpgrade")
local BuySquishyHintEvent = ensureRemoteEvent("BuySquishyHint")
local UnlockStageGateEvent = ensureRemoteEvent("UnlockStageGate")
local RebirthRequestEvent = ensureRemoteEvent("RebirthRequest")
local ClaimDailyRewardEvent = ensureRemoteEvent("ClaimDailyReward")
local ClaimPlaytimeRewardEvent = ensureRemoteEvent("ClaimPlaytimeReward")
local ToggleSloMoEvent = ensureRemoteEvent("ToggleSloMo")
local SetSpeedThrottleEvent = ensureRemoteEvent("SetSpeedThrottle")
local SpinWheelRequestEvent = ensureRemoteEvent("SpinWheelRequest")
local BuySpinCashEvent = ensureRemoteEvent("BuySpinCash")
local BuyRobuxItemEvent = ensureRemoteEvent("BuyRobuxItem")
local ClaimLikeFavoriteEvent = ensureRemoteEvent("ClaimLikeFavoriteReward")
local OpenModalEvent = ensureRemoteEvent("OpenModal")
local TreadmillTapBoostEvent = ensureRemoteEvent("TreadmillTapBoost")
local GetInitialStateFunc = ensureRemoteFunction("GetInitialState")

-- Preload any missing assets if needed (instant 0ms if PrebuiltAssets is already in ReplicatedStorage)
PrebuiltLoader.EnsurePrebuiltAssets()

-- Build the 3D World
local world = WorldBuilder.BuildWorld()

export type IncubatorState = {
	EggId: string?,
	ReadyAt: number?,
	IsReady: boolean,
	VisualModel: Model?,
}

export type PlacedPedestalState = {
	SquishyId: string,
	Level: number,
	VisualModel: Model,
	HomePos: Vector3?,
	RoamPos: Vector3?,
	RoamTarget: Vector3?,
	NextRoamChange: number?,
}

export type PlayerSession = {
	Coins: number,
	LifetimeCoins: number,
	SpeedStat: number,
	SpeedLevel: number,
	FenceLevel: number,
	SpeedThrottleRatio: number,
	Rebirths: number,
	DailyStreak: number,
	LastDailyClaim: number,
	LastWheelSpin: number,
	NextFreeSpinAt: number,
	BonusSpins: number,
	SessionStartTime: number,
	ClaimedPlaytime: { [string]: boolean },
	ClaimedLikeReward: boolean,
	UnlockedHints: { [string]: boolean },
	CollectedCoins: { [string]: boolean },
	UnlockedGates: { [string]: boolean },
	ClaimedStageJackpots: { [string]: boolean },
	BossShieldUntil: number,
	MythicCashBoostUntil: number,
	SloMoActive: boolean,
	OwnedPasses: { [string]: boolean },
	PlotIndex: number,
	CarriedEggId: string?,
	CarriedEggVisual: Model?,
	CarriedEggIds: { string },
	CarriedEggVisuals: { Model },
	FoundEggs: { [string]: boolean },
	BackpackCounts: { [string]: number },
	EquippedId: string?,
	PassiveIncomeRate: number,
	UncollectedPlotCash: number,
	LastTreadmillStep: number,
	LastTreadmillTap: number?,
	TrapCharges: number,
	LastBatSwing: number,
	Incubators: { [number]: IncubatorState },
	Pedestals: { [number]: PlacedPedestalState },
}

local sessions: { [Player]: PlayerSession } = {}
local plotOwners: { [number]: Player? } = { [1] = nil, [2] = nil, [3] = nil, [4] = nil }
local guardianCatchCooldowns: { [Player]: number } = {}
local hazardHitCooldowns: { [Player]: number } = {}
local bossStunUntil: { [string]: number } = {}

-- Live world egg positions (tracks where each egg currently sits, whether at its nest OR dropped in place!)
local eggLiveOffsets: { [string]: Vector3 } = {}
local eggTakenByPlayer: { [string]: Player? } = {}

for _, slime in ipairs(SlimeData.Slimes) do
	eggLiveOffsets[slime.Id] = slime.SpawnOffset
	eggTakenByPlayer[slime.Id] = nil
end

local function getPlotModel(plotIdx: number): Model?
	local plotsFolder = world.WorldFolder:FindFirstChild("PlayerPlots")
	if not plotsFolder then
		return nil
	end
	return plotsFolder:FindFirstChild("Plot_" .. tostring(plotIdx)) :: Model?
end

local function recalculateIncome(session: PlayerSession): number
	local total = 0
	for _, pedState in pairs(session.Pedestals) do
		local sData = SlimeData.ById[pedState.SquishyId]
		if sData then
			total += SlimeData.GetSquishyCoinsPerSec(sData, pedState.Level)
		end
	end
	local rebirthMult = 1 + (session.Rebirths * 0.5)
	local passMult = if session.OwnedPasses and session.OwnedPasses["2xCash"] then 2.0 else 1.0
	local vipMult = if session.OwnedPasses and session.OwnedPasses["VIP"] then 1.5 else 1.0
	local boostMult = if session.MythicCashBoostUntil and session.MythicCashBoostUntil > os.clock() then 2.0 else 1.0
	session.PassiveIncomeRate = math.floor(total * rebirthMult * passMult * vipMult * boostMult)
	return session.PassiveIncomeRate
end

local function serializeSession(player: Player)
	local session = sessions[player]
	if not session then
		return nil
	end
	session.UnlockedGates = session.UnlockedGates or { ["1"] = true }
	session.UnlockedGates["1"] = true
	session.ClaimedStageJackpots = session.ClaimedStageJackpots or {}

	local unlockedLevels = {}
	local nextStageSpeedGoal = 250
	local nextStageName = "MAX STAGE"
	for _, lvl in ipairs(SlimeData.Levels) do
		local lvlId = (lvl :: any).Id or lvl.Level
		local reqSpd = (lvl :: any).RequiredSpeed or 0
		local isUnlocked = SlimeData.IsLevelUnlocked(session.FoundEggs, session.SpeedStat, lvlId, session.FenceLevel or 1, session.UnlockedGates)
		unlockedLevels[tostring(lvlId)] = isUnlocked
		if not isUnlocked and nextStageName == "MAX STAGE" then
			nextStageSpeedGoal = reqSpd
			local prevLvl = math.max(1, lvlId - 1)
			local foundPrev, totalPrev = SlimeData.GetLevelProgress(session.FoundEggs, prevLvl)
			nextStageName = string.format("Stage %d (%d/%d • Fence Lv.%d/%d) -> Stage %d", prevLvl, foundPrev, totalPrev, session.FenceLevel or 1, lvlId, lvlId)
		end
	end

	local nextTierDef = SlimeData.TreadmillTiers[session.SpeedLevel + 1]
	local nextSpeedCost = if nextTierDef and nextTierDef.UpgradeCost
		then nextTierDef.UpgradeCost
		else math.floor(650 * math.pow(3.5, math.max(0, session.SpeedLevel - 1)))
	local nextFenceCost = SlimeData.GetFenceUpgradeCost(session.FenceLevel or 1) or 0
	local maxBrainrots = SlimeData.GetMaxBrainrotsForFenceLevel(session.FenceLevel or 1)
	local nextRebirthCost = math.floor(5000 * math.pow(3.0, session.Rebirths))
	local now = os.clock()

	local hatchingCount = 0
	for idx = 1, 5 do
		if session.Incubators[idx] and session.Incubators[idx].EggId then
			hatchingCount += 1
		end
	end
	local ranchSquishyCount = 0
	local minSquishyUpgradeCost = math.huge
	for _, pedState in pairs(session.Pedestals) do
		ranchSquishyCount += 1
		local sData = SlimeData.ById[pedState.SquishyId]
		if sData and (pedState.Level or 1) < 15 then
			local c = SlimeData.GetSquishyUpgradeCost(sData, pedState.Level)
			if c < minSquishyUpgradeCost then
				minSquishyUpgradeCost = c
			end
		end
	end
	if minSquishyUpgradeCost == math.huge then
		minSquishyUpgradeCost = 0
	end

	return {
		Coins = session.Coins,
		LifetimeCoins = session.LifetimeCoins,
		SpeedStat = math.floor(session.SpeedStat),
		SpeedLevel = session.SpeedLevel,
		FenceLevel = session.FenceLevel or 1,
		MaxBrainrots = maxBrainrots,
		NextFenceCost = nextFenceCost,
		SpeedThrottleRatio = session.SpeedThrottleRatio or 1.0,
		NextSpeedCost = nextSpeedCost,
		NextStageSpeedGoal = nextStageSpeedGoal,
		NextStageName = nextStageName,
		Rebirths = session.Rebirths,
		NextRebirthCost = nextRebirthCost,
		DailyStreak = session.DailyStreak,
		FreeSpinReadyIn = math.max(0, math.ceil((session.NextFreeSpinAt or 0) - now)),
		BonusSpins = session.BonusSpins or 0,
		PlaytimeSeconds = math.floor(now - (session.SessionStartTime or now)),
		ClaimedPlaytime = session.ClaimedPlaytime,
		ClaimedLikeReward = session.ClaimedLikeReward == true,
		UnlockedHints = session.UnlockedHints or {},
		CollectedCoins = session.CollectedCoins or {},
		UnlockedGates = session.UnlockedGates,
		ClaimedStageJackpots = session.ClaimedStageJackpots,
		BossShieldRemaining = math.max(0, math.ceil((session.BossShieldUntil or 0) - now)),
		SpinCashBoostRemaining = math.max(0, math.ceil((session.MythicCashBoostUntil or 0) - now)),
		SpinCashMultiplier = 2,
		SloMoActive = session.SloMoActive,
		OwnedPasses = session.OwnedPasses,
		PlotIndex = session.PlotIndex,
		CarriedEggId = session.CarriedEggId,
		CarriedEggCount = #session.CarriedEggIds,
		HatchingCount = hatchingCount,
		RanchSquishyCount = ranchSquishyCount,
		MinSquishyUpgradeCost = if minSquishyUpgradeCost < math.huge then minSquishyUpgradeCost else 0,
		MaxCarryCapacity = if session.OwnedPasses and session.OwnedPasses["Carry2Eggs"] then 2 else 1,
		Found = session.FoundEggs,
		BackpackCounts = session.BackpackCounts,
		FoundCount = SlimeData.CountFound(session.FoundEggs),
		TotalSquishies = #SlimeData.Slimes,
		EquippedId = session.EquippedId,
		PassiveIncomeRate = session.PassiveIncomeRate,
		UncollectedPlotCash = session.UncollectedPlotCash,
		UnlockedLevels = unlockedLevels,
	}
end

local function syncPlayer(player: Player)
	local payload = serializeSession(player)
	if payload then
		StateSyncEvent:FireClient(player, payload)
	end

	local session = sessions[player]
	if session then
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local coinsVal = ls:FindFirstChild("Coins") :: IntValue?
			if coinsVal then
				coinsVal.Value = math.floor(session.Coins)
			end
			local squishVal = ls:FindFirstChild("Squishies") :: IntValue?
			if squishVal then
				squishVal.Value = SlimeData.CountFound(session.FoundEggs)
			end
			local speedVal = ls:FindFirstChild("Speed") :: IntValue?
			if speedVal then
				speedVal.Value = math.floor(session.SpeedStat)
			end
			local rebVal = ls:FindFirstChild("Rebirths") :: IntValue?
			if rebVal then
				rebVal.Value = session.Rebirths
			end
		end
	end
end

-- AUTOMATIC CALIBRATED WALKSPEED SYSTEM:
-- REALISTIC 1-TO-1 WALKSPEED SYSTEM:
-- 1. Exact 1-to-1 WalkSpeed for session.SpeedStat from 16 to 120 (e.g. 25 speed = 25 WalkSpeed, 60 speed = 60 WalkSpeed).
-- 2. Above 120 Speed: smooth power curve up to 240 Max WalkSpeed without wall-clipping.
-- 3. On Treadmill Belt: WalkSpeed = 18 so player runs forward against the moving conveyor belt!
-- 4. Immediately restores full gameplay WalkSpeed the instant player steps off belt.
local function applyPlayerSpeed(player: Player, inPrecisionZone: boolean?)
	local session = sessions[player]
	if not session then
		return
	end
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	local rawStat = math.max(16, session.SpeedStat or 16)
	local physicalSpeed: number
	if rawStat <= 120 then
		physicalSpeed = rawStat
	else
		physicalSpeed = 120 + math.pow(rawStat - 120, 0.55) * 2.5
	end
	physicalSpeed = math.clamp(physicalSpeed, 16, 240)

	if session.CarriedEggId then
		local eggData = SlimeData.ById[session.CarriedEggId]
		if eggData then
			local weightPenalty = 1 + (eggData.Level * 0.03)
			physicalSpeed = math.max(14, physicalSpeed / weightPenalty)
		end
	end

	local throttle = math.clamp(session.SpeedThrottleRatio or 1.0, 0.25, 1.0)
	if session.SloMoActive and throttle >= 0.99 then
		throttle = 0.50
	end

	local calibratedSpeed = math.clamp(physicalSpeed * throttle, 12, 240)
	if char:GetAttribute("OnTreadmillBelt") == true then
		calibratedSpeed = 18
	end
	hum.WalkSpeed = calibratedSpeed
end

-- Controls visibility & prompt of a World Egg (instant disappearance when picked up!)
local function setWorldEggTaken(eggId: string, isTaken: boolean, isDroppedInPlace: boolean?)
	local eggModel = world.WorldEggs[eggId]
	if not eggModel then
		return
	end
	local sData = SlimeData.ById[eggId]
	for _, desc in ipairs(eggModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanTouch = not isTaken
			desc.CanQuery = not isTaken
			if desc.Name == "EggShell" then
				desc.Transparency = if isTaken then 1 else 0.04
			elseif string.find(desc.Name, "^BirdNest") ~= nil or desc.Name == "NestRim" then
				-- Hide the nest if the egg was dropped on the floor mid-escape
				desc.Transparency = if (isTaken or isDroppedInPlace) then 1 else 0
			else
				desc.Transparency = if isTaken then 1 else 0
			end
		elseif desc:IsA("ProximityPrompt") then
			desc.Enabled = not isTaken
			if not isTaken and sData then
				if isDroppedInPlace then
					desc.ActionText = "Egg - Steal (Dropped!)"
					desc.ObjectText = string.format("📍 %s ($%d/s)", sData.Name, sData.IncomePerSec)
				else
					desc.ActionText = "Egg - Steal"
					desc.ObjectText = string.format("%s [%s] ($%d/s)", sData.Name, sData.Rarity, sData.IncomePerSec)
				end
			end
		elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") or desc:IsA("ParticleEmitter") or desc:IsA("Highlight") or desc:IsA("PointLight") then
			desc.Enabled = not isTaken
		end
	end
end

local function clearCarriedEgg(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	session.CarriedEggId = nil
	if session.CarriedEggVisual then
		session.CarriedEggVisual:Destroy()
		session.CarriedEggVisual = nil
	end
	for _, vis in ipairs(session.CarriedEggVisuals) do
		if vis and vis.Parent then
			vis:Destroy()
		end
	end
	table.clear(session.CarriedEggIds)
	table.clear(session.CarriedEggVisuals)
	applyPlayerSpeed(player)
end

local function popOneCarriedEgg(player: Player): string?
	local session = sessions[player]
	if not session or #session.CarriedEggIds == 0 then
		return nil
	end
	local topIdx = #session.CarriedEggIds
	local poppedEggId = table.remove(session.CarriedEggIds, topIdx)
	local poppedVis = table.remove(session.CarriedEggVisuals, topIdx)
	if poppedVis and poppedVis.Parent then
		poppedVis:Destroy()
	end
	session.CarriedEggId = session.CarriedEggIds[1]
	session.CarriedEggVisual = session.CarriedEggVisuals[1]
	applyPlayerSpeed(player)
	return poppedEggId
end

local playerEggDropCooldowns: { [string]: number } = {}

-- EXACT DROP-IN-PLACE MECHANIC:
-- When a player carrying an egg is hit by a Boss, Hazard Moat, Sweeper Bar, or Bat,
-- the egg STOPS and DROPS right at that exact spot (never resets to the nest)!
-- If the player has an active 60s Boss Shield (🛡️ BossShieldUntil), the hit is blocked!
local function dropCarriedEggAtSpot(player: Player, hitPosition: Vector3, reasonText: string)
	local session = sessions[player]
	if not session or #session.CarriedEggIds == 0 then
		return
	end

	-- Check 60s Boss Shield Immunity (🛡️ Boss Shield Developer Product / Reward)
	if session.BossShieldUntil and session.BossShieldUntil > os.clock() then
		local rem = math.ceil(session.BossShieldUntil - os.clock())
		GuardianAlertEvent:FireClient(
			player,
			string.format("🛡️ BOSS SHIELD PROTECTED YOUR EGG from %s! (%ds Shield left)", reasonText, rem)
		)
		return
	end

	local droppedEggId = popOneCarriedEgg(player)
	if not droppedEggId then
		return
	end
	playerEggDropCooldowns[tostring(player.UserId) .. "_" .. droppedEggId] = os.clock() + 1.6
	local eggData = SlimeData.ById[droppedEggId]

	-- Clamp inside the widened playable biome bounds (-110..110) so it drops cleanly on the floor right where they got hit
	local dropX = math.clamp(hitPosition.X, -110, 110)
	local dropZ = math.min(-6, hitPosition.Z)
	local exactDropPos = Vector3.new(dropX, 3.8, dropZ)

	eggLiveOffsets[droppedEggId] = exactDropPos
	eggTakenByPlayer[droppedEggId] = nil

	local worldEggModel = world.WorldEggs[droppedEggId]
	if worldEggModel then
		worldEggModel:PivotTo(CFrame.new(exactDropPos))
		-- Remove old drop marker if any
		local oldBeacon = worldEggModel:FindFirstChild("DroppedBeacon")
		if oldBeacon then
			oldBeacon:Destroy()
		end
		if worldEggModel.PrimaryPart then
			local bb = Instance.new("BillboardGui")
			bb.Name = "DroppedBeacon"
			bb.Size = UDim2.new(6.5, 0, 1.4, 0)
			bb.StudsOffset = Vector3.new(0, 5.2, 0)
			bb.AlwaysOnTop = false
			bb.LightInfluence = 0
			bb.MaxDistance = 55
			bb.Parent = worldEggModel.PrimaryPart

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundTransparency = 1
			lbl.Text = "📍 DROPPED EGG! (Steal Here)"
			lbl.TextColor3 = Color3.fromRGB(255, 235, 65)
			lbl.TextScaled = true
			lbl.Font = Enum.Font.FredokaOne
			lbl.Parent = bb

			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(20, 12, 30)
			stroke.Thickness = 2.4
			stroke.Parent = lbl
		end
	end

	setWorldEggTaken(droppedEggId, false, true)
	GuardianAlertEvent:FireClient(player, string.format("%s! %s dropped right where you got hit!", reasonText, if eggData then eggData.Name else "Egg"))
	syncPlayer(player)
end

local function attachCarriedEggToPlayer(player: Player, slimeData: any)
	local session = sessions[player]
	if not session then
		return
	end
	local maxCarry = if session.OwnedPasses and session.OwnedPasses["Carry2Eggs"] then 2 else 1
	if #session.CarriedEggIds >= maxCarry then
		return
	end

	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local slotNum = #session.CarriedEggIds + 1
	local carriedModel = SquishyBuilder.CreateCarriedEgg(slimeData)
	carriedModel.Parent = char

	local root = carriedModel.PrimaryPart
	if root then
		-- Egg #1 held in front, Egg #2 stacked right above when owning +2 Carry Capacity!
		local offset = if slotNum == 1 then CFrame.new(0, 2.2, -3.2) else CFrame.new(0, 5.4, -2.8)
		root.CFrame = hrp.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = root
		weld.Parent = root
	end

	table.insert(session.CarriedEggIds, slimeData.Id)
	table.insert(session.CarriedEggVisuals, carriedModel)
	session.CarriedEggId = session.CarriedEggIds[1]
	session.CarriedEggVisual = session.CarriedEggVisuals[1]
	applyPlayerSpeed(player)
end

-- Creates & Syncs Hotbar Tools: Creator Store 3D Baseball Bat (4494586033), Creator Store 3D Bear Trap (9615431080), plus Hatched Squishies!
local function ensureCombatGearInBackpack(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character
	if not backpack then
		return
	end

	-- 1. Creator Store 3D Baseball Bat (Asset 4494586033 — Swings to stun chasing Bosses or knock rival egg carriers!)
	local hasBat = backpack:FindFirstChild("Bat") or (char and char:FindFirstChild("Bat"))
	if not hasBat then
		local batTool = Instance.new("Tool")
		batTool.Name = "Bat"
		batTool.ToolTip = "🏏 Creator Store Baseball Bat — Swing to Stun Bosses or Knock Rival Egg Carriers!"
		batTool.RequiresHandle = true
		batTool:SetAttribute("OriginalAssetId", 4494586033)
		batTool.Grip = CFrame.new(0, -1.1, 0)

		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.85, 4.5, 0.85)
		handle.Color = Color3.fromRGB(198, 138, 76)
		handle.Material = Enum.Material.Wood
		handle.CanCollide = false
		handle:SetAttribute("OriginalAssetId", 4494586033)
		handle:SetAttribute("PreserveCreatorStoreMesh", true)
		handle.Parent = batTool

		local batMesh = Instance.new("SpecialMesh")
		batMesh.Name = "CreatorStoreBaseballBatMesh_4494586033"
		batMesh.MeshType = Enum.MeshType.FileMesh
		batMesh.MeshId = "rbxassetid://54983181"
		batMesh.TextureId = "rbxassetid://54983107"
		batMesh.Scale = Vector3.new(1.35, 1.35, 1.35)
		batMesh:SetAttribute("PreserveCreatorStoreMesh", true)
		batMesh.Parent = handle

		local gripTape = Instance.new("Part")
		gripTape.Name = "GripTape"
		gripTape.Size = Vector3.new(0.76, 1.25, 0.76)
		gripTape.Color = Color3.fromRGB(235, 55, 65)
		gripTape.Material = Enum.Material.Fabric
		gripTape.CanCollide = false
		gripTape.Massless = true
		gripTape.CFrame = handle.CFrame * CFrame.new(0, -1.25, 0)
		gripTape.Parent = batTool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = gripTape
		weld.Parent = handle

		batTool.Activated:Connect(function()
			local now = os.clock()
			if now - session.LastBatSwing < 0.75 then
				return
			end
			session.LastBatSwing = now

			local c = player.Character
			local hrp = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				return
			end

			-- Play R15/R6 slash animation on swing
			local hum = c:FindFirstChildOfClass("Humanoid")
			if hum then
				local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
				local swingAnim = Instance.new("Animation")
				swingAnim.AnimationId = "rbxassetid://522635514"
				pcall(function()
					local track = animator:LoadAnimation(swingAnim)
					track.Priority = Enum.AnimationPriority.Action
					track:Play(0.05, 1, 1.5)
				end)
			end

			-- Visual swing arc
			local wave = Instance.new("Part")
			wave.Name = "BatSwingWave"
			wave.Shape = Enum.PartType.Cylinder
			wave.Size = Vector3.new(0.6, 16, 16)
			wave.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, 0, math.rad(90))
			wave.Color = Color3.fromRGB(255, 220, 75)
			wave.Material = Enum.Material.Neon
			wave.Transparency = 0.35
			wave.Anchored = true
			wave.CanCollide = false
			wave.Parent = Workspace
			task.delay(0.22, function()
				if wave.Parent then
					wave:Destroy()
				end
			end)

			-- Stun any nearby Boss within 19 studs for 3.0 seconds!
			for gId, gEntry in pairs(world.Guardians) do
				if gEntry.Model.PrimaryPart then
					local d = (gEntry.Model.PrimaryPart.Position - hrp.Position).Magnitude
					if d <= 19 then
						bossStunUntil[gId] = now + 3.0
						local statusLbl = gEntry.Model:FindFirstChild("StatusLabel", true) :: TextLabel?
						if statusLbl then
							statusLbl.Text = "💫 STUNNED!"
							statusLbl.TextColor3 = Color3.fromRGB(255, 235, 70)
						end
					end
				end
			end

			-- Knock any rival player carrying an egg within 12 studs so their egg drops in place!
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= player and otherPlayer.Character then
					local oHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if oHrp and (oHrp.Position - hrp.Position).Magnitude <= 12 then
						dropCarriedEggAtSpot(otherPlayer, oHrp.Position, "🏏 Bonked by " .. player.DisplayName .. "'s Bat")
					end
				end
			end
		end)

		batTool.Parent = backpack
	end

	-- 2. Creator Store 3D Bear Trap Tool (Asset 9615431080 — Deploys a 3D Steel-Jaw Bear Trap on the ground that snares chasing Bosses!)
	local existingTrapTool: Tool? = nil
	for _, container in ipairs({ backpack, char }) do
		if container then
			for _, item in ipairs(container:GetChildren()) do
				if item:IsA("Tool") and item:GetAttribute("IsBearTrap") then
					existingTrapTool = item
					break
				end
			end
		end
	end

	if session.TrapCharges > 0 then
		if not existingTrapTool then
			local trapTool = Instance.new("Tool")
			trapTool.Name = string.format("Bear Trap x%d", session.TrapCharges)
			trapTool.ToolTip = "🪤 Creator Store Steel Bear Trap — Place on the floor to Snare Chasing Bosses!"
			trapTool.RequiresHandle = true
			trapTool:SetAttribute("IsBearTrap", true)
			trapTool:SetAttribute("OriginalAssetId", 9615431080)

			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(2.8, 0.8, 2.8)
			handle.Color = Color3.fromRGB(75, 80, 95)
			handle.Material = Enum.Material.Metal
			handle.CanCollide = false
			handle:SetAttribute("OriginalAssetId", 9615431080)
			handle:SetAttribute("PreserveCreatorStoreMesh", true)
			handle.Parent = trapTool

			local trapMesh = Instance.new("SpecialMesh")
			trapMesh.Name = "CreatorStoreBearTrapMesh_9615431080"
			trapMesh.MeshType = Enum.MeshType.FileMesh
			trapMesh.MeshId = "rbxassetid://11954776"
			trapMesh.TextureId = "rbxassetid://11954766"
			trapMesh.Scale = Vector3.new(1.45, 1.45, 1.45)
			trapMesh:SetAttribute("PreserveCreatorStoreMesh", true)
			trapMesh.Parent = handle

			trapTool.Activated:Connect(function()
				if session.TrapCharges <= 0 then
					return
				end
				local c = player.Character
				local hrp = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not hrp then
					return
				end

				session.TrapCharges -= 1
				if session.TrapCharges <= 0 then
					trapTool:Destroy()
				else
					trapTool.Name = string.format("Bear Trap x%d", session.TrapCharges)
				end

				local trapPart = Instance.new("Part")
				trapPart.Name = "DeployedBearTrap"
				trapPart.Size = Vector3.new(5.2, 1.1, 5.2)
				trapPart.CFrame = CFrame.new(hrp.Position.X, 0.55, hrp.Position.Z)
				trapPart.Color = Color3.fromRGB(65, 70, 82)
				trapPart.Material = Enum.Material.Metal
				trapPart.Anchored = true
				trapPart.CanCollide = false
				trapPart:SetAttribute("OwnerUserId", player.UserId)
				trapPart:SetAttribute("ActiveTrap", true)
				trapPart:SetAttribute("OriginalAssetId", 9615431080)
				trapPart:SetAttribute("PreserveCreatorStoreMesh", true)

				local deployedMesh = Instance.new("SpecialMesh")
				deployedMesh.Name = "CreatorStoreBearTrapMesh_9615431080"
				deployedMesh.MeshType = Enum.MeshType.FileMesh
				deployedMesh.MeshId = "rbxassetid://11954776"
				deployedMesh.TextureId = "rbxassetid://11954766"
				deployedMesh.Scale = Vector3.new(2.4, 2.4, 2.4)
				deployedMesh:SetAttribute("PreserveCreatorStoreMesh", true)
				deployedMesh.Parent = trapPart

				-- Add 3D toothed steel jaws + red pressure plate so the deployed trap is unmistakable on the ground
				local pressurePlate = Instance.new("Part")
				pressurePlate.Name = "PressurePlate"
				pressurePlate.Shape = Enum.PartType.Cylinder
				pressurePlate.Size = Vector3.new(0.35, 2.2, 2.2)
				pressurePlate.CFrame = trapPart.CFrame * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90))
				pressurePlate.Color = Color3.fromRGB(235, 65, 65)
				pressurePlate.Material = Enum.Material.Neon
				pressurePlate.Anchored = true
				pressurePlate.CanCollide = false
				pressurePlate.Parent = trapPart

				for jawSide = -1, 1, 2 do
					local jaw = Instance.new("Part")
					jaw.Name = if jawSide == -1 then "LeftJaw" else "RightJaw"
					jaw.Size = Vector3.new(4.4, 0.45, 1.6)
					jaw.CFrame = trapPart.CFrame * CFrame.new(0, 0.35, jawSide * 1.45) * CFrame.Angles(math.rad(jawSide * -18), 0, 0)
					jaw.Color = Color3.fromRGB(165, 175, 190)
					jaw.Material = Enum.Material.Metal
					jaw.Anchored = true
					jaw.CanCollide = false
					jaw.Parent = trapPart
				end

				trapPart.Parent = world.WorldFolder:FindFirstChild("DynamicObstacles") or Workspace

				task.delay(25, function()
					if trapPart.Parent then
						trapPart:Destroy()
					end
				end)
			end)

			trapTool.Parent = backpack
		else
			existingTrapTool.Name = string.format("Bear Trap x%d", session.TrapCharges)
		end
	end
end

local function refreshBackpackTools(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	ensureCombatGearInBackpack(player)

	-- Keep the bottom hotbar 100% clean (only Bat & Bear Trap gear; zero Squishy tool boxes in the bottom inventory bar!)
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") and not string.find(child.Name, "^Bat") and not string.find(child.Name, "^Bear Trap") then
			child:Destroy()
		end
	end
	local char = player.Character
	if char then
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Tool") and not string.find(child.Name, "^Bat") and not string.find(child.Name, "^Bear Trap") then
				child:Destroy()
			end
		end
	end
end

local function updatePlotOwnerSign(plotIdx: number, ownerName: string, incomeRate: number, uncollected: number)
	local plotModel = getPlotModel(plotIdx)
	if not plotModel then
		return
	end
	local signPart = plotModel:FindFirstChild("OwnerSign")
	if signPart then
		local signText = string.format("🏡 %s'S EGG RANCH\n⚡ $%d / sec", string.upper(ownerName), incomeRate)
		for _, desc in ipairs(signPart:GetDescendants()) do
			if desc:IsA("TextLabel") then
				desc.Text = signText
			end
		end
	end
	local collectPad = plotModel:FindFirstChild("CollectCashPad")
	if collectPad then
		local bb = collectPad:FindFirstChildOfClass("BillboardGui")
		local lbl = bb and bb:FindFirstChildOfClass("TextLabel")
		if lbl then
			lbl.Text = string.format("💰 COLLECT $%d\n(Step Here)", uncollected)
		end
	end
end

local function updateSpeedUpgradePrompt(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local plotModel = getPlotModel(session.PlotIndex)
	if not plotModel then
		return
	end
	local tierIdx = math.clamp(session.SpeedLevel, 1, #SlimeData.TreadmillTiers)
	local tierData = SlimeData.TreadmillTiers[tierIdx] or SlimeData.TreadmillTiers[1]
	local nextTierIdx = math.clamp(session.SpeedLevel + 1, 1, #SlimeData.TreadmillTiers)
	local nextTierData = SlimeData.TreadmillTiers[nextTierIdx] or tierData

	-- Sync Plot Treadmill belt attributes, overhead [x1 SPEED] -> [x4M SPEED] banner & scrolling Beam color!
	local belt = plotModel:FindFirstChild("TreadmillBelt_" .. tostring(session.PlotIndex)) :: BasePart?
	if belt then
		belt:SetAttribute("TreadmillTier", tierIdx)
		belt:SetAttribute("SpeedGainPerSec", tierData.SpeedPerSec)
		belt:SetAttribute("SpeedPerSec", tierData.SpeedPerSec)
		belt:SetAttribute("MultiplierLabel", tierData.MultiplierLabel)
		belt:SetAttribute("MultiplierText", tierData.MultiplierText or tierData.MultiplierLabel)
		local scrollBeam = (belt:FindFirstChild("TreadmillScrollBeam") or belt:FindFirstChild("BeltScrollBeam")) :: Beam?
		if scrollBeam then
			scrollBeam.Color = ColorSequence.new(tierData.PrimaryColor or tierData.Color, tierData.AccentColor or tierData.Color)
			scrollBeam.Texture = tierData.BeamTexture or "rbxassetid://6798365555"
			scrollBeam.TextureSpeed = tierData.TextureSpeed or (3.2 + (tierIdx * 0.45))
		end
		local auraEmitter = belt:FindFirstChild("TreadmillAuraEmitter") :: ParticleEmitter?
		if auraEmitter then
			auraEmitter.Color = ColorSequence.new(tierData.PrimaryColor or tierData.Color, tierData.AccentColor or tierData.Color)
		end
	end
	local tmModel = plotModel:FindFirstChild("DinoTreadmill_" .. tostring(session.PlotIndex))
	if tmModel then
		local bb = tmModel:FindFirstChild("TreadmillBillboard", true) :: BillboardGui?
		local bbLbl = bb and bb:FindFirstChildOfClass("TextLabel")
		if bbLbl then
			bbLbl.Text = string.format(
				"⚡ BASE %s [%s]\n🏃 Run Here = +%s Speed / Sec!",
				string.upper(tierData.Name),
				tierData.MultiplierLabel,
				SlimeData.FormatNumber(tierData.SpeedPerSec)
			)
			bbLbl.TextColor3 = tierData.AccentColor or tierData.Color
		end
		local screen = tmModel:FindFirstChild("TreadmillConsoleScreen", true) :: BasePart?
		if screen then
			local speedFormatted = SlimeData.FormatNumber(tierData.SpeedPerSec)
			local consoleText = string.format("⚡ TIER %d TREADMILL\n[%s]\n+%s SPD / SEC", tierIdx, tierData.MultiplierText or tierData.MultiplierLabel, speedFormatted)
			for _, sg in ipairs(screen:GetChildren()) do
				if sg:IsA("SurfaceGui") then
					local lbl = sg:FindFirstChild("SignLabel", true) :: TextLabel?
					if lbl then
						lbl.Text = consoleText
						lbl.TextColor3 = tierData.AccentColor or tierData.Color
					end
				end
			end
		end

		-- Dynamically swap the Prebuilt 3D Treadmill Visual Model to the newly unlocked tier!
		local oldVisual = tmModel:FindFirstChild("PrebuiltTreadmillVisual")
		if oldVisual then
			oldVisual:Destroy()
		end
		local faceDir = if belt then (belt:GetAttribute("FaceDir") :: number?) or 1 else 1
		local treadCenter = if belt then belt.Position - Vector3.new(0, 0.84, 0) else plotModel:GetPivot().Position
		local newVisual = PrebuiltLoader.CloneNormalizedTemplate("Treadmills", tierIdx, 13.5, false)
		if newVisual then
			newVisual.Name = "PrebuiltTreadmillVisual"
			newVisual:PivotTo(CFrame.new(treadCenter + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, if faceDir > 0 then 0 else math.pi, 0))
			for _, d in ipairs(newVisual:GetDescendants()) do
				if d:IsA("BasePart") then
					d.CanCollide = false
					d.CanTouch = false
					d.CanQuery = false
					d.Massless = true
					d.Anchored = true
					local nm = string.lower(d.Name)
					if string.find(nm, "belt") or string.find(nm, "surface") or string.find(nm, "chassis") or string.find(nm, "floor") or string.find(nm, "plate") then
						if math.abs(d.Position.Y - treadCenter.Y) < 1.8 then
							d.Transparency = 1
						end
					end
				end
			end
			newVisual.Parent = tmModel
		end
	end

	local stand = plotModel:FindFirstChild("SpeedUpgradeStand")
	local prompt = stand and stand:FindFirstChild("UpgradeSpeedPrompt", true) :: ProximityPrompt?
	if prompt then
		local cost = if nextTierData.UpgradeCost and nextTierData.UpgradeCost > 0
			then nextTierData.UpgradeCost
			else math.floor(650 * math.pow(3.5, math.max(0, session.SpeedLevel - 1)))
		prompt.ActionText = string.format("Upgrade Treadmill -> [%s] (Tier %d)", nextTierData.MultiplierLabel, session.SpeedLevel + 1)
		prompt.ObjectText = string.format(
			"🏃 Cost: $%s (Now: +%s/s)",
			SlimeData.FormatNumber(cost),
			SlimeData.FormatNumber(tierData.SpeedPerSec)
		)
	end
end

local tryUnlockStageGate: (player: Player, targetLevel: number) -> ()

local function upgradePlayerTreadmill(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	if session.SpeedLevel >= #SlimeData.TreadmillTiers then
		GuardianAlertEvent:FireClient(player, "⚡ Your Treadmill is already at MAX Cosmic Tier 8!")
		return
	end
	local nextTierIdx = session.SpeedLevel + 1
	local nextTierData = SlimeData.TreadmillTiers[nextTierIdx] or SlimeData.TreadmillTiers[#SlimeData.TreadmillTiers]
	local cost = if nextTierData and nextTierData.UpgradeCost and nextTierData.UpgradeCost > 0
		then nextTierData.UpgradeCost
		else math.floor(650 * math.pow(3.5, math.max(0, session.SpeedLevel - 1)))
	if session.Coins < cost then
		GuardianAlertEvent:FireClient(
			player,
			string.format("Need $%s Cash to purchase Treadmill Tier %d [%s]!", SlimeData.FormatNumber(cost), nextTierIdx, nextTierData.MultiplierLabel)
		)
		return
	end
	session.Coins -= cost
	session.SpeedLevel += 1
	local tierIdx = math.clamp(session.SpeedLevel, 1, #SlimeData.TreadmillTiers)
	local tierData = SlimeData.TreadmillTiers[tierIdx] or SlimeData.TreadmillTiers[1]
	local mult = if session.OwnedPasses and session.OwnedPasses["2xSpeed"] then 2 else 1
	local instantBoost = tierData.SpeedPerSec * 2 * mult
	session.SpeedStat += instantBoost
	applyPlayerSpeed(player)
	updateSpeedUpgradePrompt(player)
	GuardianAlertEvent:FireClient(
		player,
		string.format(
			"⚡ PURCHASED TREADMILL TIER %d [%s]! +%s Instant Speed & +%s/sec on Belt!",
			session.SpeedLevel,
			tierData.MultiplierLabel,
			SlimeData.FormatNumber(instantBoost),
			SlimeData.FormatNumber(tierData.SpeedPerSec * mult)
		)
	)
	syncPlayer(player)
end

-- 5.1 Updates the 🌱 Grow / Level-Up Brainrot Stand (Lv. 1 -> Lv. 15) on the left of the fence entrance!
local function updateGrowStandPrompt(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local plotModel = getPlotModel(session.PlotIndex)
	local hatcheryPen = plotModel and plotModel:FindFirstChild("HatcheryPen")
	local growStand = hatcheryPen and hatcheryPen:FindFirstChild("GrowSquishyStand")
	if not growStand then
		return
	end

	local chosenSlot: number? = nil
	local lowestCost = math.huge
	local totalCount = 0
	for slotIdx, pedState in pairs(session.Pedestals) do
		totalCount += 1
		if pedState.Level < 15 then
			local sData = SlimeData.ById[pedState.SquishyId]
			if sData then
				local c = SlimeData.GetSquishyUpgradeCost(sData, pedState.Level)
				if c < lowestCost then
					lowestCost = c
					chosenSlot = slotIdx
				end
			end
		end
	end

	local prompt = growStand:FindFirstChild("UpgradeSquishyPenPrompt", true) :: ProximityPrompt?
	local bb = growStand:FindFirstChildOfClass("BillboardGui")
	local bbLbl = bb and bb:FindFirstChildOfClass("TextLabel")

	if chosenSlot and session.Pedestals[chosenSlot] then
		local pedState = session.Pedestals[chosenSlot]
		local sData = SlimeData.ById[pedState.SquishyId]
		if sData then
			local nextLvl = math.min(15, pedState.Level + 1)
			local nextCps = SlimeData.GetSquishyCoinsPerSec(sData, nextLvl)
			if prompt then
				prompt.ActionText = string.format("🌱 Grow %s -> Lv.%d ($%s)", sData.Name, nextLvl, SlimeData.FormatNumber(lowestCost))
				prompt.ObjectText = string.format("Boosts Income to $%s/s (Lv.%d/15)", SlimeData.FormatNumber(nextCps), pedState.Level)
				prompt.Enabled = true
			end
			if bbLbl then
				bbLbl.Text = string.format(
					"🌱 GROW %s (Lv.%d -> Lv.%d)\nCost: $%s -> $%s/s!",
					string.upper(sData.Name),
					pedState.Level,
					nextLvl,
					SlimeData.FormatNumber(lowestCost),
					SlimeData.FormatNumber(nextCps)
				)
			end
			return
		end
	end

	if prompt then
		if totalCount == 0 then
			prompt.ActionText = "🌱 Grow & Level Up Brainrot (Lv.1 -> Lv.15)"
			prompt.ObjectText = "Hatch a Brainrot Egg inside your Fence first!"
			prompt.Enabled = false
		else
			prompt.ActionText = "🌟 All Active Brainrots at MAX Lv.15!"
			prompt.ObjectText = "Hatch more Brainrots to level them up!"
			prompt.Enabled = false
		end
	end
	if bbLbl then
		if totalCount == 0 then
			bbLbl.Text = "🌱 GROW / LEVEL UP BRAINROT (Lv.1 -> Lv.15)\nHatch Eggs in Fence to Grow!"
		else
			bbLbl.Text = "🌱 ALL ACTIVE BRAINROTS MAX LV.15!\nHatch More Brainrots to Level Up!"
		end
	end
end

-- 5.3 Physical 3D Fence Expansion (`resizePlayerFencePen`):
-- Expands the matte wooden/iron fence from 24x18 (4 Brainrots at Lv.1) -> 28x21 (7) -> 32x24 (10) -> 36x27 (14)
-- -> 40x30 (18) -> 44x33 (23) -> 48x36 (29) -> 56x42 studs (all 35 Brainrots at Lv.8!).
local function resizePlayerFencePen(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local plotModel = getPlotModel(session.PlotIndex)
	if not plotModel then
		return
	end
	local fenceLvl = math.clamp(session.FenceLevel or 1, 1, #SlimeData.FenceLevels)
	WorldBuilder.ResizePlayerFencePen(plotModel, fenceLvl)

	-- Update HomePos of any active roaming Brainrots to match the repositioned pasture slots!
	local pedestalsFolder = plotModel:FindFirstChild("Pedestals")
	if pedestalsFolder then
		for slotIdx, pedState in pairs(session.Pedestals) do
			local pedPart = pedestalsFolder:FindFirstChild("Pedestal_" .. tostring(slotIdx)) :: BasePart?
			if pedPart then
				pedState.HomePos = pedPart.Position + Vector3.new(0, 1.8, 0)
			end
		end
	end
end

-- 5.2 Updates the 🧱 Upgrade Fence Size Stand (Lv. 1 -> Lv. 8) on the right of the fence entrance and calls `resizePlayerFencePen`!
local function updateFenceUpgradePrompt(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local plotModel = getPlotModel(session.PlotIndex)
	if not plotModel then
		return
	end
	local fenceLvl = math.clamp(session.FenceLevel or 1, 1, #SlimeData.FenceLevels)
	local curDef = SlimeData.GetFenceLevelDef(fenceLvl)
	local nextCost = SlimeData.GetFenceUpgradeCost(fenceLvl)
	local nextDef = SlimeData.FenceLevels[fenceLvl + 1]

	resizePlayerFencePen(player)

	local hatcheryPen = plotModel:FindFirstChild("HatcheryPen")
	if hatcheryPen and curDef then
		local fenceStand = hatcheryPen:FindFirstChild("UpgradeFenceStand")
		local prompt = fenceStand and (fenceStand:FindFirstChild("UpgradeFencePrompt", true) or fenceStand:FindFirstChild("UpgradeFenceSizePrompt", true)) :: ProximityPrompt?
		local bb = fenceStand and fenceStand:FindFirstChildOfClass("BillboardGui")
		local bbLbl = bb and bb:FindFirstChildOfClass("TextLabel")
		if prompt then
			if nextDef and nextCost then
				prompt.ActionText = string.format("🧱 Upgrade Fence -> Lv.%d (%d Max Brainrots)", fenceLvl + 1, nextDef.MaxBrainrots)
				prompt.ObjectText = string.format("Cost: $%s | Fits Stage %d Size (%dx%d)", SlimeData.FormatNumber(nextCost), nextDef.MaxStageSizeAllowed, nextDef.Width, nextDef.Depth)
				prompt.Enabled = true
			else
				prompt.ActionText = "🧱 MAX FENCE LEVEL (Lv.8 - 35 Brainrots)"
				prompt.ObjectText = "Colossal Cosmic Enclosure Unlocked!"
				prompt.Enabled = false
			end
		end
		if bbLbl then
			if nextDef and nextCost then
				bbLbl.Text = string.format("🧱 UPGRADE FENCE SIZE (Lv.%d -> Lv.%d)\nFits %d Brainrots (%dx%d) • $%s", fenceLvl, fenceLvl + 1, nextDef.MaxBrainrots, nextDef.Width, nextDef.Depth, SlimeData.FormatNumber(nextCost))
			else
				bbLbl.Text = string.format("🧱 FENCE LEVEL %d (MAX 56x42)\nFits All 35 Colossal Brainrots!", fenceLvl)
			end
		end
	end
end

local function upgradePlayerFence(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local fenceLvl = math.clamp(session.FenceLevel or 1, 1, #SlimeData.FenceLevels)
	local nextCost = SlimeData.GetFenceUpgradeCost(fenceLvl)
	local nextDef = SlimeData.FenceLevels[fenceLvl + 1]
	if not nextDef or not nextCost then
		GuardianAlertEvent:FireClient(player, "🧱 Your Brainrot Fence is already at MAX Level 8 (Fits all 35 Colossal Brainrots)!")
		return
	end
	if session.Coins < nextCost then
		GuardianAlertEvent:FireClient(
			player,
			string.format("Need $%s Cash to upgrade your Brainrot Fence to Lv.%d (%d Max Brainrots)!", SlimeData.FormatNumber(nextCost), fenceLvl + 1, nextDef.MaxBrainrots)
		)
		return
	end
	session.Coins -= nextCost
	session.FenceLevel = fenceLvl + 1
	updateFenceUpgradePrompt(player)
	GuardianAlertEvent:FireClient(
		player,
		string.format(
			"🧱 FENCE EXPANDED TO LV.%d (%s - %dx%d Studs)! Now holds %d Brainrots & Stage %d Giant Sizes!",
			session.FenceLevel,
			nextDef.Label,
			nextDef.Width,
			nextDef.Depth,
			nextDef.MaxBrainrots,
			nextDef.MaxStageSizeAllowed
		)
	)
	syncPlayer(player)
end

-- Spawns or updates a Live Roaming Hatched Brainrot inside a Player's Fenced Hatchery Pen (growing bigger via ScaleTo & gaining Crowns as it levels up!)
local function refreshPedestalVisual(player: Player, slotIdx: number)
	local session = sessions[player]
	if not session then
		return
	end
	local plotModel = getPlotModel(session.PlotIndex)
	if not plotModel then
		return
	end
	local pedestalsFolder = plotModel:FindFirstChild("Pedestals")
	if not pedestalsFolder then
		return
	end
	local pedPart = pedestalsFolder:FindFirstChild("Pedestal_" .. tostring(slotIdx)) :: BasePart?
	if not pedPart then
		local hatcheryPen = plotModel:FindFirstChild("HatcheryPen")
		local penFloor = hatcheryPen and hatcheryPen:FindFirstChild("HatcheryPenFloor") :: BasePart?
		local baseCenter = if penFloor then penFloor.Position else plotModel:GetPivot().Position
		local newPart = Instance.new("Part")
		newPart.Name = "Pedestal_" .. tostring(slotIdx)
		newPart.Size = Vector3.new(2, 0.2, 2)
		newPart.Transparency = 1
		newPart.Anchored = true
		newPart.CanCollide = false
		newPart.CanQuery = false
		local angle = (slotIdx / 35) * math.pi * 2
		newPart.Position = baseCenter + Vector3.new(math.cos(angle) * 7, 0.3, math.sin(angle) * 5)
		newPart.Parent = pedestalsFolder
		pedPart = newPart
	end
	if pedPart then
		pedPart.Transparency = 1
		pedPart.CanCollide = false
		pedPart.CanQuery = false
	end

	local pedState = session.Pedestals[slotIdx]
	if not pedState then
		return
	end
	if pedState.VisualModel then
		pedState.VisualModel:Destroy()
	end

	local sData = SlimeData.ById[pedState.SquishyId]
	if not sData then
		return
	end

	local homePos = pedPart.Position + Vector3.new(0, 1.8, 0)
	pedState.HomePos = homePos
	if not pedState.RoamPos then
		pedState.RoamPos = homePos
	end
	if not pedState.RoamTarget then
		pedState.RoamTarget = homePos + Vector3.new((math.random() - 0.5) * 4.5, 0, (math.random() - 0.5) * 4.5)
	end

	local model = SquishyBuilder.CreateHatchedSquishy(sData, pedState.Level)
	model:PivotTo(CFrame.new(pedState.RoamPos or homePos))
	model.Parent = pedPart
	pedState.VisualModel = model
	updateGrowStandPrompt(player)

	local upgradeCost = SlimeData.GetSquishyUpgradeCost(sData, pedState.Level)
	local newCps = SlimeData.GetSquishyCoinsPerSec(sData, pedState.Level + 1)
	local stageScale = (sData :: any).StageHatchScale or 1.0
	local scaleMult = stageScale * (1 + math.min(0.95, pedState.Level * 0.14))
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("PedestalUpgradePrompt", true) :: ProximityPrompt?
	if prompt then
		if pedState.Level >= 15 then
			prompt.Enabled = false
			prompt.ActionText = "🌟 MAX LEVEL (Lv.15)"
			prompt.ObjectText = string.format("%s [MAX Lv.15 • %.2fx Size]", sData.Name, scaleMult)
		else
			prompt.Enabled = true
			prompt.ActionText = string.format("🌱 Grow & Level Up -> Lv.%d ($%s)", pedState.Level + 1, SlimeData.FormatNumber(upgradeCost))
			prompt.ObjectText = string.format("%s [Lv.%d • %.2fx Size] ($%s/s)", sData.Name, pedState.Level, scaleMult, SlimeData.FormatNumber(newCps))
		end
		prompt.Triggered:Connect(function(triggerPlayer: Player)
			if triggerPlayer ~= player then
				return
			end
			if pedState.Level >= 15 then
				return
			end
			if session.Coins < upgradeCost then
				GuardianAlertEvent:FireClient(
					player,
					string.format("Need $%s Cash to grow %s to Lv.%d!", SlimeData.FormatNumber(upgradeCost), sData.Name, pedState.Level + 1)
				)
				return
			end
			session.Coins -= upgradeCost
			pedState.Level = math.min(15, pedState.Level + 1)
			recalculateIncome(session)
			refreshPedestalVisual(player, slotIdx)
			updatePlotOwnerSign(session.PlotIndex, player.DisplayName, session.PassiveIncomeRate, session.UncollectedPlotCash)
			GuardianAlertEvent:FireClient(
				player,
				string.format("🌱 GREW %s TO LV.%d (%.2fx Size)! Now generating $%s/sec!", string.upper(sData.Name), pedState.Level, scaleMult, SlimeData.FormatNumber(newCps))
			)
			syncPlayer(player)
		end)
	end
end

-- Automatically releases a newly hatched Brainrot into an open slot inside the player's Fenced Hatchery Pen (respecting FenceLevel capacity 4..35)!
local function autoReleaseSquishyIntoPen(player: Player, squishyId: string): boolean
	local session = sessions[player]
	if not session then
		return false
	end
	local plotModel = getPlotModel(session.PlotIndex)
	local pedestalsFolder = plotModel and plotModel:FindFirstChild("Pedestals")
	local fenceDef = SlimeData.GetFenceLevelDef(session.FenceLevel or 1)
	local maxSlots = if fenceDef then fenceDef.MaxBrainrots else 4

	-- If this identical Brainrot is already in the pen, level it up (up to Lv. 15) automatically!
	for slotIdx = 1, maxSlots do
		local pedState = session.Pedestals[slotIdx]
		if pedState and pedState.SquishyId == squishyId and pedState.Level < 15 then
			pedState.Level += 1
			refreshPedestalVisual(player, slotIdx)
			recalculateIncome(session)
			updatePlotOwnerSign(session.PlotIndex, player.DisplayName, session.PassiveIncomeRate, session.UncollectedPlotCash)
			return true
		end
	end

	-- Look for an open slot (1..maxSlots) inside the Fenced Hatchery Pen
	for slotIdx = 1, maxSlots do
		if session.Pedestals[slotIdx] == nil then
			local pedPart = pedestalsFolder and pedestalsFolder:FindFirstChild("Pedestal_" .. tostring(slotIdx)) :: BasePart?
			local placePr = pedPart and pedPart:FindFirstChild("PlaceSquishyPrompt", true) :: ProximityPrompt?
			if placePr then
				placePr.Enabled = false
			end
			local homePos = if pedPart then pedPart.Position + Vector3.new(0, 1.8, 0) else Vector3.new(0, 2.4, 0)
			session.Pedestals[slotIdx] = {
				SquishyId = squishyId,
				Level = 1,
				VisualModel = nil :: any,
				HomePos = homePos,
				RoamPos = homePos,
				RoamTarget = homePos + Vector3.new((math.random() - 0.5) * 5.0, 0, (math.random() - 0.5) * 5.0),
				NextRoamChange = os.clock() + 1.5,
			}
			refreshPedestalVisual(player, slotIdx)
			recalculateIncome(session)
			updatePlotOwnerSign(session.PlotIndex, player.DisplayName, session.PassiveIncomeRate, session.UncollectedPlotCash)
			return true
		end
	end

	return false
end

local function ensurePlacePromptOnPedestal(pedPart: BasePart, plotIdx: number, slotIdx: number)
	-- Brainrots auto-drop and roam freely inside the pen; no floor prompt on Pedestal slots
	local prompt = pedPart:FindFirstChild("PlaceSquishyPrompt", true) :: ProximityPrompt?
	if prompt then
		prompt.Enabled = false
	end
	return
end

-- Drops a carried Mystery Brainrot Egg into an open Hatchery Nest inside the Fenced Hatchery Pen, wobbles during countdown (00:05 -> HATCH!),
-- and at 00:00 cracks open and rolls a weighted Stage Brainrot (#1-#35) directly into the player's Fenced Pen!
local function plantCarriedEggIntoHatcheryNest(player: Player, preferredIncIdx: number?): boolean
	local session = sessions[player]
	if not session or #session.CarriedEggIds == 0 then
		return false
	end
	local plotModel = getPlotModel(session.PlotIndex)
	local incubatorsFolder = plotModel and plotModel:FindFirstChild("Incubators")
	if not incubatorsFolder then
		return false
	end

	local targetIncIdx: number? = nil
	if preferredIncIdx and session.Incubators[preferredIncIdx] and not session.Incubators[preferredIncIdx].EggId then
		targetIncIdx = preferredIncIdx
	else
		for idx = 1, 5 do
			if session.Incubators[idx] and not session.Incubators[idx].EggId then
				targetIncIdx = idx
				break
			end
		end
	end
	if not targetIncIdx then
		return false
	end

	local incState = session.Incubators[targetIncIdx]
	local incPad = incubatorsFolder:FindFirstChild("Incubator_" .. tostring(targetIncIdx)) :: BasePart?
	if not incState or not incPad then
		return false
	end

	local plantedEggId = popOneCarriedEgg(player)
	local eggData = if plantedEggId then SlimeData.ById[plantedEggId] else nil
	if not plantedEggId or not eggData then
		return false
	end

	-- Respawn a fresh egg back at its Boss Nest now that this egg is safely inside the player's Fenced Hatchery Pen!
	eggLiveOffsets[plantedEggId] = eggData.SpawnOffset
	eggTakenByPlayer[plantedEggId] = nil
	local wEgg = world.WorldEggs[plantedEggId]
	if wEgg then
		local oldBeacon = wEgg:FindFirstChild("DroppedBeacon", true)
		if oldBeacon then
			oldBeacon:Destroy()
		end
		wEgg:PivotTo(CFrame.new(eggData.SpawnOffset))
	end
	setWorldEggTaken(plantedEggId, false, false)

	local hatchDuration = if session.OwnedPasses and session.OwnedPasses["AutoHatch"]
		then 1
		else math.clamp(3 + eggData.Level, 4, 6)
	local nestPivot = CFrame.new(incPad.Position + Vector3.new(0, 2.2, 0))
	local plantedVisual = SquishyBuilder.CreatePlantedEgg(eggData, hatchDuration)
	plantedVisual:PivotTo(nestPivot)
	plantedVisual.Parent = incPad

	incState.EggId = plantedEggId
	incState.ReadyAt = os.clock() + hatchDuration
	incState.IsReady = false
	incState.VisualModel = plantedVisual

	local prompt = incPad:FindFirstChild("IncubatorPrompt", true) :: ProximityPrompt?
	local bb = incPad:FindFirstChildOfClass("BillboardGui")
	local bbLabel = bb and bb:FindFirstChildOfClass("TextLabel")
	if prompt then
		prompt.Enabled = false
	end
	if bbLabel then
		bbLabel.Text = string.format("⏳ HATCHING STAGE %d BRAINROT EGG...", eggData.Level)
	end
	GuardianAlertEvent:FireClient(
		player,
		string.format("🥚 Planted Stage %d Mystery Brainrot Egg! Hatching in %ds...", eggData.Level, hatchDuration)
	)
	syncPlayer(player)

	-- Wobbling Hatch Timer Loop ("00:05" -> "✨ HATCH!" -> Rolls a Stage Brainrot #1-#35 inside the Fence!)
	task.spawn(function()
		local wobbleStep = 0
		while incState.EggId == plantedEggId and sessions[player] == session do
			wobbleStep += 1
			local rem = math.ceil((incState.ReadyAt or 0) - os.clock())
			local tLbl = plantedVisual:FindFirstChild("TimerLabel", true) :: TextLabel?

			-- Cute egg wobble animation as it prepares to crack open
			if plantedVisual.Parent then
				local tilt = math.rad(math.sin(wobbleStep * 1.4) * 12)
				plantedVisual:PivotTo(nestPivot * CFrame.Angles(0, 0, tilt))
			end

			if rem <= 0 then
				incState.IsReady = true
				if tLbl then
					tLbl.Text = "✨ HATCH!"
					tLbl.TextColor3 = Color3.fromRGB(95, 255, 130)
				end

				-- Authentic Roblox Speed Simulator 3D Egg Crack & Pop-Out Hatch Sequence
				if plantedVisual and plantedVisual.Parent then
					for i = 1, 6 do
						local tilt = math.rad(if i % 2 == 0 then 18 else -18)
						plantedVisual:PivotTo(nestPivot * CFrame.Angles(0, math.rad(i * 30), tilt))
						task.wait(0.06)
					end

					-- Spawn 2 cracking half-shells popping apart
					local eggColor = eggData.Color or Color3.fromRGB(255, 215, 65)
					local topShell = Instance.new("Part")
					topShell.Name = "TopEggShell"
					topShell.Shape = Enum.PartType.Ball
					topShell.Size = Vector3.new(2.4, 1.4, 2.4)
					topShell.Color = eggColor
					topShell.Material = Enum.Material.SmoothPlastic
					topShell.CFrame = nestPivot * CFrame.new(0, 1.2, 0)
					topShell.CanCollide = false
					topShell.Anchored = false
					topShell.Velocity = Vector3.new(math.random(-8, 8), 18, math.random(-8, 8))
					topShell.Parent = Workspace

					local btmShell = Instance.new("Part")
					btmShell.Name = "BottomEggShell"
					btmShell.Shape = Enum.PartType.Ball
					btmShell.Size = Vector3.new(2.4, 1.2, 2.4)
					btmShell.Color = eggColor
					btmShell.Material = Enum.Material.SmoothPlastic
					btmShell.CFrame = nestPivot * CFrame.new(0, -0.4, 0)
					btmShell.CanCollide = false
					btmShell.Anchored = false
					btmShell.Velocity = Vector3.new(math.random(-6, 6), 8, math.random(-6, 6))
					btmShell.Parent = Workspace

					local hatchBurst = Instance.new("ParticleEmitter")
					hatchBurst.Name = "EggHatchBurst"
					hatchBurst.Texture = "rbxassetid://9129151031"
					hatchBurst.Color = ColorSequence.new(eggColor, Color3.fromRGB(255, 255, 255))
					hatchBurst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0.2) })
					hatchBurst.Speed = NumberRange.new(12, 24)
					hatchBurst.Lifetime = NumberRange.new(0.4, 0.7)
					hatchBurst.Rate = 0
					hatchBurst.Parent = topShell
					hatchBurst:Emit(28)

					game:GetService("Debris"):AddItem(topShell, 0.8)
					game:GetService("Debris"):AddItem(btmShell, 0.8)
				end

				if incState.VisualModel then
					incState.VisualModel:Destroy()
					incState.VisualModel = nil
				end
				incState.EggId = nil
				incState.ReadyAt = nil
				incState.IsReady = false

				if prompt then
					prompt.ActionText = "Drop Brainrot Egg in Nest"
					prompt.ObjectText = "Hatchery Nest #" .. tostring(targetIncIdx)
					prompt.Enabled = false
				end
				if bbLabel then
					bbLabel.Text = "🥚 HATCHERY NEST #" .. tostring(targetIncIdx) .. "\n[READY]"
				end

				-- Roll which Brainrot (#1-#35) hatches from this Stage Egg (preferring unfound Brainrots so Stage completion never soft-locks!)
				local hasLucky = session.OwnedPasses and (session.OwnedPasses["LuckyEggRoll"] or session.OwnedPasses["VIP"])
				local rolledBrainrotId = if not session.FoundEggs[plantedEggId] and not hasLucky
					then plantedEggId
					else SlimeData.RollStageBrainrotId(eggData.Level, hasLucky, session.FoundEggs)
				local hatchedData = SlimeData.ById[rolledBrainrotId] or eggData

				local isFirst = not session.FoundEggs[rolledBrainrotId]
				session.FoundEggs[rolledBrainrotId] = true
				session.FoundEggs[plantedEggId] = true
				local passMult = if session.OwnedPasses and session.OwnedPasses["2xCash"] then 2.0 else 1.0
				local baseReward = (hatchedData :: any).CoinReward or eggData.CoinReward or 50
				local rewardCash = math.floor(baseReward * (if isFirst then 1.5 else 1.0) * passMult)
				session.Coins += rewardCash
				session.LifetimeCoins += rewardCash

				-- Spawn directly into the Fenced Hatchery Pen as a live roaming 3D Brainrot!
				local placedInPen = autoReleaseSquishyIntoPen(player, rolledBrainrotId)
				if not placedInPen then
					session.BackpackCounts[rolledBrainrotId] = (session.BackpackCounts[rolledBrainrotId] or 0) + 1
					refreshBackpackTools(player)
				end

				EggCapturedEvent:FireClient(player, {
					SquishyId = rolledBrainrotId,
					IsFirstDiscovery = isFirst,
					CoinsEarned = rewardCash,
					ActionType = "Hatched",
				})
				local stageScale = (hatchedData :: any).StageHatchScale or 1.0
				local firstTag = if isFirst then " ✨ NEW INDEX DISCOVERY BONUS!" else ""
				GuardianAlertEvent:FireClient(
					player,
					string.format(
						"🐣 HATCHED %s [%s • %.2fx Size]! (+$%s Cash%s • +$%s/sec in Fence!)",
						string.upper(hatchedData.Name),
						hatchedData.Rarity,
						stageScale,
						SlimeData.FormatNumber(rewardCash),
						firstTag,
						SlimeData.FormatNumber(hatchedData.IncomePerSec)
					)
				)
				-- Check 100% Stage Index Mastery Jackpot!
				session.ClaimedStageJackpots = session.ClaimedStageJackpots or {}
				local fB, tB, fS, tS = SlimeData.GetStageBreakdown(session.FoundEggs, eggData.Level)
				if (tB + tS) > 0 and fB >= tB and fS >= tS and not session.ClaimedStageJackpots[tostring(eggData.Level)] then
					session.ClaimedStageJackpots[tostring(eggData.Level)] = true
					local jackpot = math.floor(SlimeData.GetStageMasteryJackpot(eggData.Level) * passMult)
					session.Coins += jackpot
					session.LifetimeCoins += jackpot
					task.delay(0.6, function()
						if sessions[player] then
							GuardianAlertEvent:FireClient(
								player,
								string.format(
									"🏆 STAGE %d 100%% INDEX MASTERY JACKPOT! +$%s BONUS CASH! (%d/%d Brainrots & %d/%d Squishies!)",
									eggData.Level,
									SlimeData.FormatNumber(jackpot),
									fB,
									tB,
									fS,
									tS
								)
							)
							syncPlayer(player)
						end
					end)
				end
				syncPlayer(player)
				break
			else
				if tLbl then
					tLbl.Text = string.format("00:%02d", rem)
				end
			end
			task.wait(0.20)
		end
	end)

	return true
end

-- Phase 6.1: Enforce All 4 Stage Gate Unlock Requirements:
-- 1. Hatch 100% of Stage (S-1) Brainrots (#1-#35)
-- 2. Find 100% of Stage (S-1) Hidden Squishies (#36-#117)
-- 3. Upgrade Fence to Level S (Lv. 1 -> Lv. 8)
-- 4. Reach Required Speed on the Treadmill + Pay Stage Gate Cash Cost
tryUnlockStageGate = function(player: Player, targetLevel: number)
	local session = sessions[player]
	if not session or targetLevel <= 1 or targetLevel > #SlimeData.Levels then
		return
	end
	session.UnlockedGates = session.UnlockedGates or { ["1"] = true }
	if session.UnlockedGates[tostring(targetLevel)] then
		return
	end

	local status = SlimeData.GetStageGateStatus(
		session.FoundEggs,
		session.SpeedStat,
		session.FenceLevel or 1,
		session.UnlockedGates,
		targetLevel
	)
	local prevStage = targetLevel - 1
	local lvlInfo = SlimeData.Levels[targetLevel]
	local stageName = if lvlInfo then string.upper(lvlInfo.Name) else ("STAGE " .. tostring(targetLevel))

	if not status.RequirementsMet then
		GuardianAlertEvent:FireClient(
			player,
			string.format(
				"🔒 %s GATE LOCKED! Need: 🥚 Stage %d Brainrots (%d/%d) • 🧸 Squishies (%d/%d) • 🧱 Fence Lv.%d/%d • 💰 $%s",
				stageName,
				prevStage,
				status.FoundBrainrots,
				status.TotalBrainrots,
				status.FoundSquishies,
				status.TotalSquishies,
				status.CurrentFenceLevel,
				status.RequiredFenceLevel,
				SlimeData.FormatNumber(status.GateCost)
			)
		)
		return
	end

	if session.Coins < status.GateCost then
		GuardianAlertEvent:FireClient(
			player,
			string.format(
				"💰 All 4 Stage %d Requirements Met! Need $%s Cash to open the %s Gate!",
				prevStage,
				SlimeData.FormatNumber(status.GateCost),
				stageName
			)
		)
		return
	end

	session.Coins -= status.GateCost
	session.UnlockedGates[tostring(targetLevel)] = true
	GuardianAlertEvent:FireClient(
		player,
		string.format(
			"🔓 %s GATE UNLOCKED! (-$%s Cash) • All 4 Stage %d Requirements Complete!",
			stageName,
			SlimeData.FormatNumber(status.GateCost),
			prevStage
		)
	)
	syncPlayer(player)
end

UnlockStageGateEvent.OnServerEvent:Connect(function(player: Player, targetLevel: any)
	local lvl = tonumber(targetLevel)
	if not lvl then
		local session = sessions[player]
		if session then
			for i = 2, #SlimeData.Levels do
				if not (session.UnlockedGates and session.UnlockedGates[tostring(i)]) then
					lvl = i
					break
				end
			end
		end
	end
	if lvl then
		tryUnlockStageGate(player, lvl)
	end
end)

for lvlId, gateBarrier in pairs(world.GateBarriers) do
	if lvlId > 1 and gateBarrier then
		local gatePrompt = gateBarrier:FindFirstChild("UnlockStageGatePrompt", true) :: ProximityPrompt?
		if gatePrompt then
			gatePrompt.Triggered:Connect(function(player: Player)
				tryUnlockStageGate(player, lvlId)
			end)
		end
		local skipGatePrompt = gateBarrier:FindFirstChild("SkipStageGatePaywallPrompt", true) :: ProximityPrompt?
		if skipGatePrompt then
			skipGatePrompt.Triggered:Connect(function(player: Player)
				local session = sessions[player]
				if not session then
					return
				end
				if session.UnlockedGates and session.UnlockedGates[tostring(lvlId)] then
					GuardianAlertEvent:FireClient(player, string.format("✅ Stage %d Gate is already unlocked!", lvlId))
					return
				end
				if session.OwnedPasses and session.OwnedPasses["VIP"] then
					session.UnlockedGates[tostring(lvlId)] = true
					gateBarrier.Transparency = 1.0
					gateBarrier.CanCollide = false
					skipGatePrompt.Enabled = false
					if gatePrompt then
						gatePrompt.Enabled = false
					end
					GuardianAlertEvent:FireClient(player, string.format("👑 VIP PERK: Stage %d Gate instantly unlocked!", lvlId))
					syncPlayer(player)
				else
					GuardianAlertEvent:FireClient(player, string.format("💎 VIP / PAYWALL: Instant Stage %d Gate Unlock requires VIP! Opening VIP Shop...", lvlId))
					OpenModalEvent:FireClient(player, "RobuxShop")
				end
			end)
		end
		local gateTouchCooldowns: { [number]: number } = {}
		gateBarrier.Touched:Connect(function(hit: BasePart)
			local char = hit.Parent
			local player = if char then Players:GetPlayerFromCharacter(char) else nil
			local session = if player then sessions[player] else nil
			if not player or not session then
				return
			end
			if session.UnlockedGates and session.UnlockedGates[tostring(lvlId)] then
				return
			end
			local now = os.clock()
			if gateTouchCooldowns[player.UserId] and (now - gateTouchCooldowns[player.UserId]) < 2.2 then
				return
			end
			gateTouchCooldowns[player.UserId] = now
			tryUnlockStageGate(player, lvlId)
		end)
	end
end

BuySpeedUpgradeEvent.OnServerEvent:Connect(function(player: Player)
	upgradePlayerTreadmill(player)
end)

BuyFenceUpgradeEvent.OnServerEvent:Connect(function(player: Player)
	upgradePlayerFence(player)
end)

-- Connects all 7 Base Plots (Fenced Hatchery Pen, Walk-In Auto-Drop, Grow & Level Up Kiosk, Upgrade Fence Kiosk, Roaming Slots, Cash Collector, Treadmill Upgrade)
for plotIdx = 1, 7 do
	local plotModel = getPlotModel(plotIdx)
	if plotModel then
		local stand = plotModel:FindFirstChild("SpeedUpgradeStand")
		local upgPrompt = stand and stand:FindFirstChild("UpgradeSpeedPrompt", true) :: ProximityPrompt?
		if upgPrompt then
			upgPrompt.Triggered:Connect(function(player: Player)
				local session = sessions[player]
				if not session or session.PlotIndex ~= plotIdx then
					GuardianAlertEvent:FireClient(player, "Go to your own Base Plot to upgrade your Treadmill!")
					return
				end
				upgradePlayerTreadmill(player)
			end)
		end

		-- Touch-to-Upgrade on SpeedUpgradeStand Pad (1.5s debounce)
		if stand then
			local upgPad = stand:FindFirstChild("Pad") or stand:FindFirstChild("SpeedUpgradePad") or (if stand:IsA("BasePart") then stand else stand:FindFirstChildWhichIsA("BasePart"))
			if upgPad and upgPad:IsA("BasePart") then
				upgPad.CanTouch = true
				local standTouchCooldowns: { [number]: number } = {}
				upgPad.Touched:Connect(function(hit: BasePart)
					local char = hit.Parent
					local player = if char then Players:GetPlayerFromCharacter(char) else nil
					local session = if player then sessions[player] else nil
					if not player or not session or session.PlotIndex ~= plotIdx then
						return
					end
					local now = os.clock()
					if standTouchCooldowns[player.UserId] and (now - standTouchCooldowns[player.UserId]) < 1.5 then
						return
					end
					standTouchCooldowns[player.UserId] = now
					upgradePlayerTreadmill(player)
				end)
			end
		end

		local hatcheryPen = plotModel:FindFirstChild("HatcheryPen")

		-- Connect 🧱 Upgrade Fence Size Stand (Lv. 1 -> Lv. 8) on the right side of the Hatchery Pen Entrance!
		local fencePrompt = hatcheryPen and (hatcheryPen:FindFirstChild("UpgradeFencePrompt", true) or hatcheryPen:FindFirstChild("UpgradeFenceSizePrompt", true)) :: ProximityPrompt?
		if fencePrompt then
			fencePrompt.Triggered:Connect(function(player: Player)
				local session = sessions[player]
				if not session or session.PlotIndex ~= plotIdx then
					GuardianAlertEvent:FireClient(player, "Go to your own Fenced Hatchery Pen to upgrade your Fence Size!")
					return
				end
				upgradePlayerFence(player)
			end)
		end

		-- Connect 🌱 Grow & Level Up Brainrot Station Kiosk (Lv. 1 -> Lv. 15) on the left side of the Hatchery Pen Entrance!
		local growPrompt = hatcheryPen and hatcheryPen:FindFirstChild("UpgradeSquishyPenPrompt", true) :: ProximityPrompt?
		if growPrompt then
			growPrompt.Triggered:Connect(function(player: Player)
				local session = sessions[player]
				if not session or session.PlotIndex ~= plotIdx then
					GuardianAlertEvent:FireClient(player, "Go to your own Fenced Hatchery Pen to grow & level up your Brainrots!")
					return
				end
				-- Find the most affordable roaming Brainrot in the pen (below Lv. 15) to grow & level up
				local chosenSlot: number? = nil
				local lowestCost = math.huge
				for slotIdx, pedState in pairs(session.Pedestals) do
					if pedState.Level < 15 then
						local sData = SlimeData.ById[pedState.SquishyId]
						if sData then
							local c = SlimeData.GetSquishyUpgradeCost(sData, pedState.Level)
							if c < lowestCost then
								lowestCost = c
								chosenSlot = slotIdx
							end
						end
					end
				end
				if not chosenSlot then
					local count = 0
					for _ in pairs(session.Pedestals) do
						count += 1
					end
					if count > 0 then
						GuardianAlertEvent:FireClient(player, "🌟 All active Brainrots in your pen are at MAX Lv.15!")
					else
						GuardianAlertEvent:FireClient(player, "Hatch a Brainrot Egg in your Fenced Pen first so you have roaming Brainrots to level up!")
					end
					return
				end
				local pedState = session.Pedestals[chosenSlot]
				local sData = SlimeData.ById[pedState.SquishyId]
				if not sData then
					return
				end
				if session.Coins < lowestCost then
					GuardianAlertEvent:FireClient(
						player,
						string.format("Need $%s Cash to grow %s to Lv.%d!", SlimeData.FormatNumber(lowestCost), sData.Name, pedState.Level + 1)
					)
					return
				end
				session.Coins -= lowestCost
				pedState.Level = math.min(15, pedState.Level + 1)
				recalculateIncome(session)
				refreshPedestalVisual(player, chosenSlot)
				updatePlotOwnerSign(session.PlotIndex, player.DisplayName, session.PassiveIncomeRate, session.UncollectedPlotCash)
				local stageScale = (sData :: any).StageHatchScale or 1.0
				local scaleMult = stageScale * (1 + math.min(0.95, (pedState.Level - 1) * 0.14))
				local newCps = SlimeData.GetSquishyCoinsPerSec(sData, pedState.Level)
				GuardianAlertEvent:FireClient(
					player,
					string.format("🌱 GREW %s TO LV.%d (%.2fx Size)! Now earning $%s/sec!", string.upper(sData.Name), pedState.Level, scaleMult, SlimeData.FormatNumber(newCps))
				)
				syncPlayer(player)
			end)
		end

		-- Connect Walk-In Auto-Drop on HatcheryDropZone inside the Fenced Hatchery Pen!
		local dropZone = hatcheryPen and hatcheryPen:FindFirstChild("HatcheryDropZone") :: BasePart?
		if dropZone then
			dropZone.CanTouch = true
			dropZone.Touched:Connect(function(hit: BasePart)
				local char = hit.Parent
				local player = if char then Players:GetPlayerFromCharacter(char) else nil
				local session = if player then sessions[player] else nil
				if not player or not session or session.PlotIndex ~= plotIdx then
					return
				end
				while #session.CarriedEggIds > 0 do
					if not plantCarriedEggIntoHatcheryNest(player, nil) then
						break
					end
				end
			end)
		end

		local incubatorsFolder = plotModel:FindFirstChild("Incubators")
		if incubatorsFolder then
			for incIdx = 1, 5 do
				local incPad = incubatorsFolder:FindFirstChild("Incubator_" .. tostring(incIdx)) :: BasePart?
				local prompt = incPad and incPad:FindFirstChild("IncubatorPrompt", true) :: ProximityPrompt?

				if incPad and prompt then
					prompt.Triggered:Connect(function(player: Player)
						local session = sessions[player]
						if not session or session.PlotIndex ~= plotIdx then
							GuardianAlertEvent:FireClient(player, "Use the Fenced Hatchery Pen on your own Base Plot!")
							return
						end
						if #session.CarriedEggIds == 0 then
							GuardianAlertEvent:FireClient(player, "Steal a Brainrot Egg from a Stage Boss Nest first, then walk into your Fenced Hatchery Pen!")
							return
						end
						plantCarriedEggIntoHatcheryNest(player, incIdx)
					end)
				end
			end
		end

		local pedestalsFolder = plotModel:FindFirstChild("Pedestals")
		if pedestalsFolder then
			for slotIdx = 1, 35 do
				local pedPart = pedestalsFolder:FindFirstChild("Pedestal_" .. tostring(slotIdx)) :: BasePart?
				if pedPart then
					ensurePlacePromptOnPedestal(pedPart, plotIdx, slotIdx)
				end
			end
		end
	end
end

-- Connect Automatic Walk-Over Pickup + Instant Prompts on all 117 World Items (35 Boss Nest Eggs + 82 Shining Collectible Squishies!)
local shiningPlayerCooldowns: { [string]: number } = {}
local stageLockAlertCooldowns: { [number]: number } = {}
local COMBO_WINDOW_SEC = 12.0

local function advanceSquishFeverCombo(session: any): (number, number)
	local now = os.clock()
	if session.LastComboTime and (now - session.LastComboTime) <= COMBO_WINDOW_SEC then
		session.ComboCount = (session.ComboCount or 0) + 1
	else
		session.ComboCount = 1
	end
	session.LastComboTime = now
	local comboMult = math.clamp(1.0 + (session.ComboCount - 1) * 0.5, 1.0, 5.0)
	return session.ComboCount, comboMult
end

local function tryCollectOrStealWorldItem(player: Player, eggId: string)
	local session = sessions[player]
	if not session then
		return
	end
	local eggModel = world.WorldEggs[eggId]
	local slimeData = SlimeData.ById[eggId]
	if not eggModel or not slimeData then
		return
	end

	-- Strict 4-Requirement Stage Gate Check (All 8 Stages: 100% Brainrots + 100% Squishies + Fence Lv.S + Speed + Gate Cash Cost)
	local lvl = slimeData.Level
	if lvl > 1 and not SlimeData.IsLevelUnlocked(session.FoundEggs, session.SpeedStat, lvl, session.FenceLevel or 1, session.UnlockedGates) then
		local now = os.clock()
		if not stageLockAlertCooldowns[player.UserId] or (now - stageLockAlertCooldowns[player.UserId]) >= 2.2 then
			stageLockAlertCooldowns[player.UserId] = now
			tryUnlockStageGate(player, lvl)
		end
		return
	end

	local isShining = (slimeData :: any).IsShiningSquishy == true or eggModel:GetAttribute("IsShiningSquishy") == true
	local itemWorldPos = eggModel:GetPivot().Position

	-- CASE A: SHINING COLLECTIBLE SQUISHY (#36-#117 on Rooftops, Rainbow Staircase, Outer Mazes, Castle Walls & Obbies)
	-- Permanent One-Time Per-Player Pickup: Once collected, it disappears for that player and can NEVER be farmed repeatedly!
	if isShining then
		if session.FoundEggs[eggId] then
			return
		end
		local cdKey = tostring(player.UserId) .. "_" .. eggId
		local now = os.clock()
		if shiningPlayerCooldowns[cdKey] and (now - shiningPlayerCooldowns[cdKey]) < 2.0 then
			return
		end
		shiningPlayerCooldowns[cdKey] = now

		local comboCount, comboMult = advanceSquishFeverCombo(session)
		local passMult = if session.OwnedPasses and session.OwnedPasses["2xCash"] then 2.0 else 1.0
		local earnedCash = math.floor(slimeData.CoinReward * comboMult * passMult)
		session.FoundEggs[eggId] = true
		session.Coins += earnedCash
		session.LifetimeCoins += earnedCash

		refreshBackpackTools(player)
		EggCapturedEvent:FireClient(player, {
			SquishyId = eggId,
			IsFirstDiscovery = true,
			CoinsEarned = earnedCash,
			ComboCount = comboCount,
			ComboMultiplier = comboMult,
			ComboWindowSec = COMBO_WINDOW_SEC,
			WorldPos = itemWorldPos,
			ActionType = "SquishyPickup",
		})
		local stageFound, stageTotal = SlimeData.CountLevelProgress(session.FoundEggs, lvl)
		local comboSuffix = if comboCount >= 2 then string.format(" 🔥 x%.1f COMBO!", comboMult) else ""
		GuardianAlertEvent:FireClient(
			player,
			string.format(
				"✨ Found %s! (+$%s Cash%s • Stage %d: %d/%d • Index %d/117!)",
				slimeData.Name,
				SlimeData.FormatNumber(earnedCash),
				comboSuffix,
				lvl,
				stageFound,
				stageTotal,
				SlimeData.CountFound(session.FoundEggs)
			)
		)
		-- Check 100% Stage Index Mastery Jackpot!
		session.ClaimedStageJackpots = session.ClaimedStageJackpots or {}
		local fB, tB, fS, tS = SlimeData.GetStageBreakdown(session.FoundEggs, lvl)
		if (tB + tS) > 0 and fB >= tB and fS >= tS and not session.ClaimedStageJackpots[tostring(lvl)] then
			session.ClaimedStageJackpots[tostring(lvl)] = true
			local jackpot = math.floor(SlimeData.GetStageMasteryJackpot(lvl) * passMult)
			session.Coins += jackpot
			session.LifetimeCoins += jackpot
			task.delay(0.6, function()
				if sessions[player] then
					GuardianAlertEvent:FireClient(
						player,
						string.format(
							"🏆 STAGE %d 100%% INDEX MASTERY JACKPOT! +$%s BONUS CASH! (%d/%d Brainrots & %d/%d Squishies!)",
							lvl,
							SlimeData.FormatNumber(jackpot),
							fB,
							tB,
							fS,
							tS
						)
					)
					syncPlayer(player)
				end
			end)
		end
		syncPlayer(player)
		return
	end

	if session.FoundEggs[eggId] or eggTakenByPlayer[eggId] ~= nil then
		return
	end
	local dropCdKey = tostring(player.UserId) .. "_" .. eggId
	if playerEggDropCooldowns[dropCdKey] and os.clock() < playerEggDropCooldowns[dropCdKey] then
		return
	end

	-- CASE B: BOSS NEST EGG (#1-#35) -> Walk-Over Automatic Steal, Carry (up to 2 with +2 Carry Capacity!), and Hatch in Fenced Hatchery Pen!
	local maxCarry = if session.OwnedPasses and session.OwnedPasses["Carry2Eggs"] then 2 else 1
	if #session.CarriedEggIds >= maxCarry then
		local now = os.clock()
		if not stageLockAlertCooldowns[player.UserId] or (now - stageLockAlertCooldowns[player.UserId]) >= 2.5 then
			stageLockAlertCooldowns[player.UserId] = now
			if maxCarry == 1 then
				GuardianAlertEvent:FireClient(player, "Carrying 1/1 Boss Egg! Walk into your Fenced Hatchery Pen or unlock 🎒 +2 Carry Capacity!")
			else
				GuardianAlertEvent:FireClient(player, "Carrying 2/2 Boss Eggs! Walk into your Fenced Hatchery Pen to hatch them first!")
			end
		end
		return
	end

	local comboCount, comboMult = advanceSquishFeverCombo(session)
	local stealBonus = math.max(25, math.floor(slimeData.CoinReward * 0.25 * comboMult))
	session.Coins += stealBonus
	session.LifetimeCoins += stealBonus

	eggTakenByPlayer[eggId] = player
	setWorldEggTaken(eggId, true, false)
	attachCarriedEggToPlayer(player, slimeData)
	EggCapturedEvent:FireClient(player, {
		SquishyId = eggId,
		IsFirstDiscovery = false,
		CoinsEarned = stealBonus,
		ComboCount = comboCount,
		ComboMultiplier = comboMult,
		ComboWindowSec = COMBO_WINDOW_SEC,
		WorldPos = itemWorldPos,
		ActionType = "EggStolen",
	})
	syncPlayer(player)
end

for eggId, eggModel in pairs(world.WorldEggs) do
	local slimeData = SlimeData.ById[eggId]
	local prompt = eggModel:FindFirstChild("CapturePrompt", true) :: ProximityPrompt?
	if prompt and slimeData then
		prompt.HoldDuration = 0
		prompt.Triggered:Connect(function(player: Player)
			tryCollectOrStealWorldItem(player, eggId)
		end)
	end
	local shell = (eggModel:FindFirstChild("EggShell") or eggModel.PrimaryPart) :: BasePart?
	if shell and slimeData then
		shell.CanTouch = true
		shell.Touched:Connect(function(hit: BasePart)
			local char = hit.Parent
			local player = char and Players:GetPlayerFromCharacter(char)
			if player then
				tryCollectOrStealWorldItem(player, eggId)
			end
		end)
	end
end


-- Connect Hazard Moats, Spinning Sweepers, Super Bounce Pads, Disappearing Rainbow Steps, World Coins, Shortcut Bridges & Hub Booths!
local serverSweepers: { { Part: BasePart, Speed: number } } = {}
local cachedStatusLabels: { [string]: TextLabel? } = {}
for gId, gEntry in pairs(world.Guardians) do
	cachedStatusLabels[gId] = gEntry.Model:FindFirstChild("StatusLabel", true) :: TextLabel?
end

local function bindBiomeObstacles()
	for _, desc in ipairs(world.WorldFolder:GetDescendants()) do
		if desc:IsA("BasePart") then
			if desc:GetAttribute("DisappearingStep") == true then
				desc.CanTouch = true
				local stepBusy = false
				local origColor = desc.Color
				desc.Touched:Connect(function(hit: BasePart)
					if stepBusy then
						return
					end
					local char = hit.Parent
					if not char or not char:FindFirstChildOfClass("Humanoid") then
						return
					end
					stepBusy = true
					desc.Color = Color3.fromRGB(255, 255, 255)
					task.spawn(function()
						for i = 1, 5 do
							task.wait(0.11)
							desc.Transparency = 0.08 + (i * 0.17)
						end
						desc.Transparency = 1.0
						desc.CanCollide = false
						task.wait(3.8)
						desc.Color = origColor
						desc.Transparency = 0.08
						desc.CanCollide = true
						stepBusy = false
					end)
				end)
			elseif desc:GetAttribute("WorldCoinPickup") == true then
				-- Per-player one-time collection for all 120 Glowing 3D Gold Coins so they disappear immediately when picked up and can never be farmed!
				desc.CanTouch = true
				desc.Touched:Connect(function(hit: BasePart)
					local char = hit.Parent
					local player = if char then Players:GetPlayerFromCharacter(char) else nil
					local session = if player then sessions[player] else nil
					if not player or not session then
						return
					end
					local coinId = (desc:GetAttribute("CoinId") :: string?) or desc.Name
					if session.CollectedCoins[coinId] then
						return
					end
					local stageId = (desc:GetAttribute("StageId") :: number?) or 1
					if stageId > 1 and not SlimeData.IsLevelUnlocked(session.FoundEggs, session.SpeedStat, stageId, session.FenceLevel or 1, session.UnlockedGates) then
						return
					end
					session.CollectedCoins[coinId] = true
					local sound = desc:FindFirstChild("CoinChime") :: Sound?
					if sound then
						sound:Play()
					end
					local minVal = (desc:GetAttribute("MinCoinValue") :: number?) or (desc:GetAttribute("CoinValue") :: number?) or 80
					local maxVal = (desc:GetAttribute("MaxCoinValue") :: number?) or minVal
					local baseVal = math.random(minVal, math.max(minVal, maxVal))
					local rebirthMult = 1 + ((session.Rebirths or 0) * 0.5)
					local passMult = if session.OwnedPasses and session.OwnedPasses["2xCash"] then 2.0 else 1.0
					local vipMult = if session.OwnedPasses and session.OwnedPasses["VIP"] then 1.5 else 1.0
					local earned = math.max(10, math.floor(baseVal * rebirthMult * passMult * vipMult))
					session.Coins += earned
					session.LifetimeCoins += earned
					CoinCollectedEvent:FireClient(player, {
						CoinId = coinId,
						CoinsEarned = earned,
						WorldPos = desc.Position,
					})
					syncPlayer(player)
				end)
			elseif desc:GetAttribute("VIPOnlyBarrier") == true then
				desc.CanTouch = true
				desc.Touched:Connect(function(hit: BasePart)
					local char = hit.Parent
					local player = if char then Players:GetPlayerFromCharacter(char) else nil
					local session = if player then sessions[player] else nil
					if not player or not session then
						return
					end
					local isVIP = (session.OwnedPasses and session.OwnedPasses["VIP"]) == true
					if not isVIP then
						if not stageLockAlertCooldowns[player.UserId] or (os.clock() - stageLockAlertCooldowns[player.UserId]) >= 2.5 then
							stageLockAlertCooldowns[player.UserId] = os.clock()
							GuardianAlertEvent:FireClient(
								player,
								"👑 VIP ONLY Treadmill! Unlock VIP Gamepass in the Robux Shop or train at your Base Plot Treadmill!"
							)
						end
					end
				end)
			elseif desc:GetAttribute("ShortcutButtonLevel") ~= nil then
				-- Chapter 1 & 4 Timed Co-Op / Solo Bridge & Gate Button (Duration attribute + visual countdown + disables Hazard Moat)!
				desc.CanTouch = true
				local btnBusy = false
				local lvlId = desc:GetAttribute("ShortcutButtonLevel")
				local duration = (desc:GetAttribute("Duration") :: number?) or 12
				local origBtnColor = desc.Color
				local tagBb = desc:FindFirstChild("ShortcutButtonTag")
				local tagLbl = if tagBb then tagBb:FindFirstChildWhichIsA("TextLabel") else nil
				local defaultTagText = if tagLbl then tagLbl.Text else "⚡ SHORTCUT BRIDGE (12s)"
				desc.Touched:Connect(function(hit: BasePart)
					if btnBusy then
						return
					end
					local char = hit.Parent
					local player = if char then Players:GetPlayerFromCharacter(char) else nil
					if not player then
						return
					end
					btnBusy = true
					desc.Color = Color3.fromRGB(255, 215, 55)
					local obsFolder = world.WorldFolder:FindFirstChild("DynamicObstacles")
					local bridge = obsFolder and obsFolder:FindFirstChild("ShortcutCenterBridge_" .. tostring(lvlId)) :: BasePart?
					local moat = obsFolder and obsFolder:FindFirstChild("HazardMoat_" .. tostring(lvlId)) :: BasePart?
					if bridge then
						bridge.Transparency = 0.05
						bridge.CanCollide = true
					end
					if moat then
						moat.CanTouch = false
						moat.Transparency = 0.65
					end
					GuardianAlertEvent:FireClient(player, string.format("🌉 Stage %s Shortcut Bridge & Safe Moat Activated for %ds!", tostring(lvlId), duration))
					task.spawn(function()
						for remaining = duration, 1, -1 do
							if tagLbl then
								tagLbl.Text = string.format("⏳ BRIDGE OPEN: %ds", remaining)
								tagLbl.TextColor3 = Color3.fromRGB(255, 235, 85)
							end
							task.wait(1)
						end
						if bridge and bridge.Parent then
							bridge.Transparency = 0.72
							bridge.CanCollide = false
						end
						if moat and moat.Parent then
							moat.CanTouch = true
							moat.Transparency = 0
						end
						if desc.Parent then
							desc.Color = origBtnColor
						end
						if tagLbl then
							tagLbl.Text = defaultTagText
							tagLbl.TextColor3 = Color3.fromRGB(95, 255, 160)
						end
						btnBusy = false
					end)
				end)
			elseif desc.Name == "BouncePad" or desc:GetAttribute("SuperBouncePad") == true then
				desc.CanTouch = true
				desc.Touched:Connect(function(hit: BasePart)
					local char = hit.Parent
					if not char then
						return
					end
					local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						local impulse = (desc:GetAttribute("BounceVelocityY") :: number?) or (desc:GetAttribute("BounceImpulse") :: number?) or 95
						hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, impulse, hrp.AssemblyLinearVelocity.Z)
					end
				end)
			elseif desc:GetAttribute("HazardDropEgg") then
				desc.CanTouch = true
				if desc:GetAttribute("SpinSpeed") then
					table.insert(serverSweepers, {
						Part = desc,
						Speed = desc:GetAttribute("SpinSpeed") :: number,
					})
				end
				desc.Touched:Connect(function(hit: BasePart)
					local char = hit.Parent
					if not char then
						return
					end
					local player = Players:GetPlayerFromCharacter(char)
					if not player then
						return
					end
					local now = os.clock()
					if (hazardHitCooldowns[player] or 0) > now then
						return
					end
					hazardHitCooldowns[player] = now + 1.4

					local session = sessions[player]
					if session and session.BossShieldUntil and session.BossShieldUntil > now then
						local rem = math.ceil(session.BossShieldUntil - now)
						GuardianAlertEvent:FireClient(player, string.format("🛡️ BOSS SHIELD blocked obstacle hit! (%ds left)", rem))
						return
					end

					local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						if session and session.CarriedEggId then
							dropCarriedEggAtSpot(player, hrp.Position, "💥 Hit Obstacle")
						end
						local knock = (desc:GetAttribute("KnockbackImpulse") :: number?) or 60
						hrp.AssemblyLinearVelocity = Vector3.new(0, 42, knock)
					end
				end)
			elseif desc.Name == "SpawnLikeFavoritePad" then
				desc.CanTouch = true
				local likePadCooldowns: { [number]: number } = {}
				desc.Touched:Connect(function(hit: BasePart)
					local char = hit.Parent
					local player = if char then Players:GetPlayerFromCharacter(char) else nil
					local session = if player then sessions[player] else nil
					if not player or not session then
						return
					end
					local now = os.clock()
					if likePadCooldowns[player.UserId] and (now - likePadCooldowns[player.UserId]) < 6.0 then
						return
					end
					likePadCooldowns[player.UserId] = now
					OpenModalEvent:FireClient(player, "LikeFavorite")
				end)
			end
		elseif desc:IsA("ProximityPrompt") then
			if desc.Name == "SpinWheelPrompt" then
				desc.Triggered:Connect(function(player: Player)
					OpenModalEvent:FireClient(player, "SpinWheel")
				end)
			elseif desc.Name == "DailyChestPrompt" then
				desc.Triggered:Connect(function(player: Player)
					OpenModalEvent:FireClient(player, "DailyRewards")
				end)
			elseif desc.Name == "RobuxShopPrompt" then
				desc.Triggered:Connect(function(player: Player)
					OpenModalEvent:FireClient(player, "RobuxShop")
				end)
			elseif desc.Name == "LikeFavoritePrompt" then
				desc.Triggered:Connect(function(player: Player)
					OpenModalEvent:FireClient(player, "LikeFavorite")
				end)
			elseif desc.Name == "SkipObbyPrompt" or desc.Name == "SkipObbyPaywallPrompt" then
				desc.Triggered:Connect(function(player: Player)
					local session = sessions[player]
					if not session then
						return
					end
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if not hrp then
						return
					end
					local destPos = (desc:GetAttribute("SkipTargetPos") :: Vector3?) or (desc:GetAttribute("SummitPos") :: Vector3?)
					local stageNum = (desc:GetAttribute("SkipObbyStage") :: number?) or (desc:GetAttribute("StageId") :: number?) or 1
					if not destPos then
						return
					end

					-- 1. If player owns VIP Gamepass -> Instant FREE VIP Teleport!
					if session.OwnedPasses and session.OwnedPasses["VIP"] then
						hrp.CFrame = CFrame.new(destPos + Vector3.new(0, 3, 0))
						GuardianAlertEvent:FireClient(player, "👑 VIP PERK: Instant Obby Skip Teleported you to the Summit!")
						return
					end

					-- 2. In-Game Cash Paywall Fallback: $1,500 * stageNum
					local skipCost = 1500 * stageNum
					if session.Coins >= skipCost then
						session.Coins -= skipCost
						hrp.CFrame = CFrame.new(destPos + Vector3.new(0, 3, 0))
						GuardianAlertEvent:FireClient(
							player,
							string.format("💎 Paid $%s Paywall Skip! Teleported directly to Stage %d Obby Summit!", SlimeData.FormatNumber(skipCost), stageNum)
						)
						syncPlayer(player)
					else
						-- Prompt VIP Gamepass or show cash needed!
						if GAMEPASS_IDS["VIP"] and GAMEPASS_IDS["VIP"] > 0 then
							MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_IDS["VIP"])
						else
							OpenModalEvent:FireClient(player, "RobuxShop")
						end
						GuardianAlertEvent:FireClient(
							player,
							string.format("💎 PAYWALL: Need VIP Gamepass OR $%s Cash to Skip Stage %d Obby! (You have $%s)",
								SlimeData.FormatNumber(skipCost),
								stageNum,
								SlimeData.FormatNumber(session.Coins)
							)
						)
					end
				end)
			elseif desc.Name == "DonationPrompt" or desc.Name == "ObbyGamepassPrompt" then
				desc.Triggered:Connect(function(player: Player)
					OpenModalEvent:FireClient(player, "RobuxShop")
				end)
			end
		end
	end
end
bindBiomeObstacles()

-- Main Throttled Heartbeat Loop (20Hz step for zero server-to-client replication lag!):
local startClock = os.clock()
local stepAccum = 0
RunService.Heartbeat:Connect(function(rawDt: number)
	stepAccum += rawDt
	if stepAccum < 0.05 then
		return
	end
	local dt = stepAccum
	stepAccum = 0

	local now = os.clock()
	local elapsed = now - startClock
	local activePlayers = Players:GetPlayers()
	if #activePlayers == 0 then
		return
	end

	-- 1. Spin only the 5 physical Hazard Sweeper Bars on the server (cosmetic coins/windmills/wheels spin client-side!)
	for _, sw in ipairs(serverSweepers) do
		if sw.Part and sw.Part.Parent then
			sw.Part.CFrame = CFrame.new(sw.Part.Position) * CFrame.Angles(0, elapsed * sw.Speed, 0)
		end
	end

	local obsFolder = world.WorldFolder:FindFirstChild("DynamicObstacles")

	-- 2. Sleeping Boss Guardians AI (skips biomes with no nearby players!)
	for gId, gEntry in pairs(world.Guardians) do
		local gModel = gEntry.Model
		local gData = gEntry.Data
		local levelInfo = gEntry.LevelInfo
		local root = gModel.PrimaryPart
		if not root then
			continue
		end

		local statusLbl = cachedStatusLabels[gId]

		-- Check if stunned by Bat or Bear Trap
		if (bossStunUntil[gId] or 0) > now then
			if statusLbl and statusLbl.Text ~= "💫 STUNNED!" then
				statusLbl.Text = "💫 STUNNED!"
				statusLbl.TextColor3 = Color3.fromRGB(255, 235, 70)
			end
			continue
		end

		-- Find nearest player in this biome who is carrying a stolen egg (or trespassing closely)
		local targetPlayer: Player? = nil
		local targetHrp: BasePart? = nil
		local bestDist = 48

		for _, player in ipairs(activePlayers) do
			local session = sessions[player]
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if session and hrp and (session.BossShieldUntil or 0) <= now then
				local pPos = hrp.Position
				if pPos.Z <= levelInfo.ZStart - 2 and pPos.Z >= levelInfo.ZEnd + 2 then
					local d = (pPos - root.Position).Magnitude
					local aggroRange = if session.CarriedEggId then 48 else 22
					if d < aggroRange and d < bestDist then
						bestDist = d
						targetPlayer = player
						targetHrp = hrp
					end
				end
			end
		end

		if targetPlayer and targetHrp then
			-- Check if Boss stepped on an active DeployedBearTrap while chasing
			if obsFolder then
				for _, item in ipairs(obsFolder:GetChildren()) do
					if item.Name == "DeployedBearTrap" and item:IsA("BasePart") and item:GetAttribute("ActiveTrap") then
						if (item.Position - root.Position).Magnitude <= 6.5 then
							item:SetAttribute("ActiveTrap", false)
							item.Color = Color3.fromRGB(255, 75, 75)
							bossStunUntil[gId] = now + 4.0
							task.delay(1.0, function()
								if item.Parent then
									item:Destroy()
								end
							end)
							break
						end
					end
				end
			end

			-- WAKE UP ("!!") AND CHASE!
			if statusLbl and statusLbl.Text ~= "!!" then
				statusLbl.Text = "!!"
				statusLbl.TextColor3 = Color3.fromRGB(255, 55, 55)
			end

			local dir = Vector3.new(targetHrp.Position.X - root.Position.X, 0, targetHrp.Position.Z - root.Position.Z)
			local dist = dir.Magnitude
			if dist > 0.5 then
				local chaseSpeed = 16 + (levelInfo.Id * 2.2)
				local step = dir.Unit * math.min(dist, chaseSpeed * dt)
				local newPos = Vector3.new(
					math.clamp(root.Position.X + step.X, -74, 74),
					gData.Center.Y + math.abs(math.sin(elapsed * 7)) * 1.4,
					math.clamp(root.Position.Z + step.Z, levelInfo.ZEnd + 8, levelInfo.ZStart - 8)
				)
				gModel:PivotTo(CFrame.lookAt(newPos, Vector3.new(targetHrp.Position.X, newPos.Y, targetHrp.Position.Z)))
			end

			-- Catch Check: Drop carried egg AT THAT EXACT SPOT (do NOT reset egg to nest!)
			if dist <= 7.2 and (guardianCatchCooldowns[targetPlayer] or 0) < now then
				guardianCatchCooldowns[targetPlayer] = now + 1.8
				local tSession = sessions[targetPlayer]
				if tSession and (tSession.BossShieldUntil or 0) > now then
					local rem = math.ceil(tSession.BossShieldUntil - now)
					GuardianAlertEvent:FireClient(targetPlayer, string.format("🛡️ BOSS SHIELD blocked %s! (%ds left)", gData.Name, rem))
				else
					local hitSpot = targetHrp.Position
					if tSession and tSession.CarriedEggId then
						dropCarriedEggAtSpot(targetPlayer, hitSpot, "🚨 Caught by " .. gData.Name)
					else
						GuardianAlertEvent:FireClient(targetPlayer, "🚨 Bumped by " .. gData.Name .. "! Watch out!")
					end
					targetHrp.AssemblyLinearVelocity = Vector3.new(0, 42, 65)
				end
			end
		else
			-- SLEEPING ("Zzz") AT NEST (Zero PivotTo calls once at home!)
			if statusLbl and statusLbl.Text ~= "Zzz" then
				statusLbl.Text = "Zzz"
				statusLbl.TextColor3 = Color3.fromRGB(120, 225, 255)
			end
			local toHome = Vector3.new(gData.Center.X - root.Position.X, 0, gData.Center.Z - root.Position.Z)
			if toHome.Magnitude > 1.0 then
				local step = toHome.Unit * math.min(toHome.Magnitude, 14 * dt)
				local newPos = Vector3.new(root.Position.X + step.X, gData.Center.Y, root.Position.Z + step.Z)
				gModel:PivotTo(CFrame.lookAt(newPos, newPos + Vector3.new(0, 0, 1)))
			end
		end
	end

	-- 3. Creator Store Treadmill System (Assets 85105314510723, 105125399134543, 135041830463035, 98972491411819):
	-- Continuous counting & leveling-up loop (x1 SPEED -> x50M SPEED) + startRun(humanoid) (rbxassetid://507767714) across all Plot & Stage Treadmills!
	for _, player in ipairs(Players:GetPlayers()) do
		local session = sessions[player]
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not session or not char or not hrp or not hum then
			continue
		end

		-- Strict Server Z-Boundary Teleport Guard (Enforces all 4 Stage Gate requirements before entering Stage N+1!)
		for lvlId = 2, #SlimeData.Levels do
			local levelInfo = SlimeData.Levels[lvlId]
			if levelInfo and hrp.Position.Z <= (levelInfo.ZStart - 2.0) then
				if not SlimeData.IsLevelUnlocked(session.FoundEggs, session.SpeedStat, lvlId, session.FenceLevel or 1, session.UnlockedGates) then
					if not stageLockAlertCooldowns[player.UserId] or (now - stageLockAlertCooldowns[player.UserId]) >= 2.0 then
						stageLockAlertCooldowns[player.UserId] = now
						tryUnlockStageGate(player, lvlId)
					end
					if not SlimeData.IsLevelUnlocked(session.FoundEggs, session.SpeedStat, lvlId, session.FenceLevel or 1, session.UnlockedGates) then
						hrp.CFrame = CFrame.new(math.clamp(hrp.Position.X, -85, 85), math.max(hrp.Position.Y, 6), levelInfo.ZStart + 6.5)
						hrp.AssemblyLinearVelocity = Vector3.zero
						break
					end
				end
			end
		end

		-- Automatic Walk-Over Pickup Proximity Sweep (<= 7.2 studs — 100% walk-over touch & proximity pickup!)
		local nearPrecisionPickup = false
		for eggId, eggModel in pairs(world.WorldEggs) do
			if not session.FoundEggs[eggId] and eggModel and eggModel.Parent then
				local shell = (eggModel:FindFirstChild("EggShell") or eggModel.PrimaryPart) :: BasePart?
				if shell then
					local d = (hrp.Position - shell.Position).Magnitude
					if d <= 14.0 then
						nearPrecisionPickup = true
					end
					if d <= 7.2 then
						tryCollectOrStealWorldItem(player, eggId)
					end
				end
			end
		end

		-- Automatic Walk-Over Pickup Proximity Sweep for all 120 Glowing 3D Gold Coins (6.5 studs — Instant Disappearance per player!)
		if world.WorldCoins then
			for coinId, coinPart in pairs(world.WorldCoins) do
				if not session.CollectedCoins[coinId] and coinPart and coinPart.Parent then
					local coinPos = if coinPart:IsA("Model") then coinPart:GetPivot().Position else (coinPart :: any).Position
					local d = (hrp.Position - coinPos).Magnitude
					if d <= 6.5 then
						local stageId = (coinPart:GetAttribute("StageId") :: number?) or 1
						if stageId <= 1 or SlimeData.IsLevelUnlocked(session.FoundEggs, session.SpeedStat, stageId, session.FenceLevel or 1, session.UnlockedGates) then
							session.CollectedCoins[coinId] = true
							local sound = coinPart:FindFirstChild("CoinChime", true) :: Sound?
							if sound then
								sound:Play()
							end
							local minVal = (coinPart:GetAttribute("MinCoinValue") :: number?) or (coinPart:GetAttribute("CoinValue") :: number?) or 45
							local maxVal = (coinPart:GetAttribute("MaxCoinValue") :: number?) or minVal
							local baseVal = math.random(minVal, math.max(minVal, maxVal))
							local rebirthMult = 1 + ((session.Rebirths or 0) * 0.5)
							local passMult = if session.OwnedPasses and session.OwnedPasses["2xCash"] then 2.0 else 1.0
							local vipMult = if session.OwnedPasses and session.OwnedPasses["VIP"] then 1.5 else 1.0
							local earned = math.max(10, math.floor(baseVal * rebirthMult * passMult * vipMult))
							session.Coins += earned
							session.LifetimeCoins += earned
							CoinCollectedEvent:FireClient(player, {
								CoinId = coinId,
								CoinsEarned = earned,
								WorldPos = coinPos,
							})
							syncPlayer(player)
						end
					end
				end
			end
		end

		local plotModel = getPlotModel(session.PlotIndex)
		local inPlotArea = false
		if plotModel then
			local plotPivot = plotModel:GetPivot().Position
			if math.abs(hrp.Position.X - plotPivot.X) <= 34 and math.abs(hrp.Position.Z - plotPivot.Z) <= 28 then
				inPlotArea = true
			end
		end

		-- Discover which Treadmill Belt (Plot 1-4 OR Stage 1-8) the player is currently running on:
		local activeBelt: BasePart? = nil
		if plotModel then
			local pBelt = plotModel:FindFirstChild("TreadmillBelt_" .. tostring(session.PlotIndex)) :: BasePart?
			if pBelt then
				local rel = pBelt.CFrame:PointToObjectSpace(hrp.Position)
				if math.abs(rel.X) <= (pBelt.Size.X * 0.5 + 2.4) and math.abs(rel.Z) <= (pBelt.Size.Z * 0.5 + 2.4) and math.abs(hrp.Position.Y - pBelt.Position.Y) <= 7.5 then
					activeBelt = pBelt
				end
			end
		end
		if not activeBelt then
			local levelsFolder = world.WorldFolder:FindFirstChild("Levels")
			if levelsFolder then
				for stageIdx = 1, 8 do
					local sBelt = levelsFolder:FindFirstChild("TreadmillBelt_Stage_" .. tostring(stageIdx), true) :: BasePart?
					if sBelt then
						local rel = sBelt.CFrame:PointToObjectSpace(hrp.Position)
						if math.abs(rel.X) <= (sBelt.Size.X * 0.5 + 2.4) and math.abs(rel.Z) <= (sBelt.Size.Z * 0.5 + 2.4) and math.abs(hrp.Position.Y - sBelt.Position.Y) <= 7.5 then
							activeBelt = sBelt
							break
						end
					end
				end
			end
		end

		applyPlayerSpeed(player)

		if activeBelt then
			local isStageBelt = activeBelt:GetAttribute("IsStageTreadmill") == true or string.find(activeBelt.Name, "Stage") ~= nil
			local isVIP = (session.OwnedPasses and session.OwnedPasses["VIP"]) == true
			if isStageBelt and not isVIP then
				local faceDir = (activeBelt:GetAttribute("FaceDir") :: number?) or 1
				hrp.CFrame = hrp.CFrame + Vector3.new(faceDir * 18, 1, 0)
				GuardianAlertEvent:FireClient(player, "👑 VIP ONLY Treadmill! Use your Base Plot Treadmill or unlock VIP in the Robux Shop!")
				char:SetAttribute("OnTreadmillBelt", false)
				applyPlayerSpeed(player)
				continue
			end

			char:SetAttribute("OnTreadmillBelt", true)
			local beltFaceDir = (activeBelt:GetAttribute("FaceDir") :: number?) or 1
			char:SetAttribute("TreadmillFaceDir", beltFaceDir)
			local beltTier = (activeBelt:GetAttribute("TreadmillTier") :: number?) or (session.SpeedLevel or 1)
			local effectiveTier = math.clamp(beltTier, 1, #SlimeData.TreadmillTiers)
			char:SetAttribute("TreadmillAnimSpeed", 1.3 + (effectiveTier * 0.12))

			-- Open-Source Roblox Treadmill Training Loop: 1.0s tick (or 0.5s Turbo)
			local tickInterval = if session.TurboSpeedActive then 0.50 else 1.0
			if now - session.LastTreadmillStep >= tickInterval then
				session.LastTreadmillStep = now

				local tierData = SlimeData.TreadmillTiers[effectiveTier] or SlimeData.TreadmillTiers[1]
				local basePerSec = tierData.SpeedPerSec or 1
				local passMult = if session.OwnedPasses and session.OwnedPasses["2xSpeed"] then 2 else 1
				local vipMult = if session.OwnedPasses and session.OwnedPasses["VIP"] then 1.25 else 1
				local rebirthMult = 1 + (session.Rebirths * 0.5)
				local turboMult = if session.TurboSpeedActive then 2 else 1
				local speedGain = math.max(1, math.floor(basePerSec * passMult * vipMult * rebirthMult * turboMult))

				session.SpeedStat += speedGain
				local speedVal = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Speed") :: NumberValue?
				if speedVal then
					speedVal.Value = math.floor(session.SpeedStat)
				end

				applyPlayerSpeed(player)
				updateSpeedUpgradePrompt(player)
				syncPlayer(player)

				-- Spawn 3D Floating +N ⚡ SPEED Billboard popup above player's head
				local popup = Instance.new("BillboardGui")
				popup.Name = "SpeedGainPopup"
				popup.Adornee = char:FindFirstChild("Head") or hrp
				popup.Size = UDim2.new(5.5, 0, 1.4, 0)
				popup.StudsOffset = Vector3.new(0, 3.2, 0)
				popup.AlwaysOnTop = true
				popup.ResetOnSpawn = false
				popup.Parent = char

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.fromScale(1, 1)
				lbl.BackgroundTransparency = 1
				lbl.Font = Enum.Font.FredokaOne
				lbl.Text = string.format("+%s ⚡ SPEED", SlimeData.FormatNumber(speedGain))
				lbl.TextColor3 = Color3.fromRGB(85, 235, 255)
				lbl.TextStrokeColor3 = Color3.fromRGB(15, 25, 45)
				lbl.TextStrokeTransparency = 0
				lbl.TextScaled = true
				lbl.Parent = popup

				task.spawn(function()
					local t0 = os.clock()
					while os.clock() - t0 < 1.0 and popup.Parent do
						local alpha = (os.clock() - t0) / 1.0
						popup.StudsOffset = Vector3.new(0, 3.2 + alpha * 3.5, 0)
						lbl.TextTransparency = alpha
						lbl.TextStrokeTransparency = alpha
						task.wait(0.04)
					end
					if popup.Parent then
						popup:Destroy()
					end
				end)
				Debris:AddItem(popup, 1.1)
			end
		else
			if char:GetAttribute("OnTreadmillBelt") then
				char:SetAttribute("OnTreadmillBelt", false)
				applyPlayerSpeed(player)
			end
		end

		-- Check if stepping on Green Cash Collector Pad, Walking into Fenced Hatchery Pen, and Roaming Squishies AI!
		if plotModel then
			local collectPad = plotModel:FindFirstChild("CollectCashPad") :: BasePart?
			if collectPad and session.UncollectedPlotCash > 0 then
				if (Vector3.new(hrp.Position.X, collectPad.Position.Y, hrp.Position.Z) - collectPad.Position).Magnitude <= 5.5 then
					local claimed = session.UncollectedPlotCash
					session.UncollectedPlotCash = 0
					session.Coins += claimed
					session.LifetimeCoins += claimed
					updatePlotOwnerSign(session.PlotIndex, player.DisplayName, session.PassiveIncomeRate, 0)
					syncPlayer(player)
				end
			end

			local hatcheryPen = plotModel:FindFirstChild("HatcheryPen")
			local penFloor = hatcheryPen and hatcheryPen:FindFirstChild("HatcheryPenFloor") :: BasePart?

			-- Walk-In Auto-Drop: If carrying stolen Boss Eggs and walking into your Fenced Hatchery Pen, automatically drop them into Hatchery Nests!
			if penFloor and #session.CarriedEggIds > 0 then
				local relPen = penFloor.CFrame:PointToObjectSpace(hrp.Position)
				if math.abs(relPen.X) <= (penFloor.Size.X * 0.5 + 3.0) and math.abs(relPen.Z) <= (penFloor.Size.Z * 0.5 + 3.0) then
					while #session.CarriedEggIds > 0 do
						if not plantCarriedEggIntoHatcheryNest(player, nil) then
							break
						end
					end
				end
			end

			-- Live Roaming, Hopping & Bouncing Squishies inside the Fenced Hatchery Pen!
			local penCenter = if penFloor then penFloor.Position else plotModel:GetPivot().Position
			local maxRoamX = if penFloor then (penFloor.Size.X * 0.5 - 2.6) else 8.5
			local maxRoamZ = if penFloor then (penFloor.Size.Z * 0.5 - 2.6) else 7.0

			for slotIdx, pedState in pairs(session.Pedestals) do
				local vis = pedState.VisualModel
				if vis and vis.Parent and vis.PrimaryPart then
					local curPos = pedState.RoamPos or pedState.HomePos or (penCenter + Vector3.new(0, 1.8, 0))
					local targetPos = pedState.RoamTarget or curPos
					if now >= (pedState.NextRoamChange or 0) or (Vector3.new(targetPos.X - curPos.X, 0, targetPos.Z - curPos.Z)).Magnitude < 0.8 then
						pedState.NextRoamChange = now + 2.2 + (slotIdx % 3) * 0.7
						local rx = penCenter.X + (math.random() * 2 - 1) * maxRoamX
						local rz = penCenter.Z + (math.random() * 2 - 1) * maxRoamZ
						targetPos = Vector3.new(rx, curPos.Y, rz)
						pedState.RoamTarget = targetPos
					end

					local flatDelta = Vector3.new(targetPos.X - curPos.X, 0, targetPos.Z - curPos.Z)
					local dist = flatDelta.Magnitude
					local nextPos = curPos
					if dist > 0.25 then
						local roamSpeed = 3.6 + (pedState.Level * 0.25)
						local step = flatDelta.Unit * math.min(dist, roamSpeed * dt)
						nextPos = Vector3.new(
							math.clamp(curPos.X + step.X, penCenter.X - maxRoamX, penCenter.X + maxRoamX),
							curPos.Y,
							math.clamp(curPos.Z + step.Z, penCenter.Z - maxRoamZ, penCenter.Z + maxRoamZ)
						)
						pedState.RoamPos = nextPos
					end

					-- Cute Kawaii hop bounce + gentle waggle as the Squishy wanders inside the fence
					local hopY = math.abs(math.sin(elapsed * 4.8 + slotIdx * 1.35)) * 1.15
					local waggleRoll = math.sin(elapsed * 4.8 + slotIdx * 1.35) * math.rad(7)
					local lookTarget = if dist > 0.25
						then Vector3.new(targetPos.X, nextPos.Y + hopY, targetPos.Z)
						else (nextPos + Vector3.new(0, hopY, 1))
					vis:PivotTo(CFrame.lookAt(nextPos + Vector3.new(0, hopY, 0), lookTarget) * CFrame.Angles(0, 0, waggleRoll))
				end
			end
		end
	end
end)

-- 1-Second Passive Cash Generation & Live Playtime/Spin/Boost Countdown Tick
task.spawn(function()
	while true do
		task.wait(1.0)
		for _, player in ipairs(Players:GetPlayers()) do
			local session = sessions[player]
			if session then
				if session.PassiveIncomeRate > 0 then
					recalculateIncome(session)
					session.UncollectedPlotCash += session.PassiveIncomeRate
					updatePlotOwnerSign(session.PlotIndex, player.DisplayName, session.PassiveIncomeRate, session.UncollectedPlotCash)
				end
				syncPlayer(player)
			end
		end
	end
end)

-- Remote Events from HUD
local lastTreadmillTapByPlayer: { [Player]: number } = {}
TreadmillTapBoostEvent.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local char = player.Character
	if not char or char:GetAttribute("OnTreadmillBelt") ~= true then
		return
	end
	local now = os.clock()
	if now - (lastTreadmillTapByPlayer[player] or 0) < 0.22 then
		return
	end
	lastTreadmillTapByPlayer[player] = now

	local tierIdx = math.clamp(session.SpeedLevel or 1, 1, #SlimeData.TreadmillTiers)
	local tierData = SlimeData.TreadmillTiers[tierIdx] or SlimeData.TreadmillTiers[1]
	local passMult = if session.OwnedPasses and session.OwnedPasses["2xSpeed"] then 2 else 1
	local rebirthMult = 1 + (session.Rebirths * 0.5)
	local tapGain = math.max(1, math.floor((tierData.SpeedPerSec or 1) * 0.45 * rebirthMult * passMult))
	session.SpeedStat += tapGain
	char:SetAttribute("TreadmillAnimSpeed", 2.35)
	applyPlayerSpeed(player, true)
	updateSpeedUpgradePrompt(player)
	syncPlayer(player)
end)

RebirthRequestEvent.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local cost = math.floor(5000 * math.pow(3.0, session.Rebirths))
	if session.Coins < cost then
		GuardianAlertEvent:FireClient(player, string.format("Need $%s Cash to Rebirth!", SlimeData.FormatNumber(cost)))
		return
	end
	session.Coins = 0
	session.Rebirths += 1
	session.SpeedStat = 16 + (session.Rebirths * 15)
	session.SpeedLevel = 1
	session.TrapCharges = 3 + session.Rebirths
	recalculateIncome(session)
	applyPlayerSpeed(player)
	ensureCombatGearInBackpack(player)
	updateSpeedUpgradePrompt(player)
	GuardianAlertEvent:FireClient(player, string.format("✨ REBIRTH #%d COMPLETE! Permanent +50%% Cash & Faster Treadmill Gains!", session.Rebirths))
	syncPlayer(player)
end)

-- Helper: Activates a 60s Glowing Golden Boss Shield around the player
local function activateBossShield(player: Player, durationSec: number)
	local session = sessions[player]
	if not session then
		return
	end
	local now = os.clock()
	session.BossShieldUntil = math.max(session.BossShieldUntil or 0, now) + durationSec

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp and not hrp:FindFirstChild("BossShieldSphere") then
		local shield = Instance.new("Part")
		shield.Name = "BossShieldSphere"
		shield.Shape = Enum.PartType.Ball
		shield.Size = Vector3.new(9.5, 9.5, 9.5)
		shield.Color = Color3.fromRGB(255, 225, 65)
		shield.Material = Enum.Material.ForceField
		shield.Transparency = 0.35
		shield.CanCollide = false
		shield.Massless = true
		shield.CFrame = hrp.CFrame
		shield.Parent = hrp

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = shield
		weld.Parent = shield

		task.spawn(function()
			while shield.Parent and sessions[player] and (sessions[player].BossShieldUntil or 0) > os.clock() do
				task.wait(0.5)
			end
			if shield.Parent then
				shield:Destroy()
			end
		end)
	end
end

-- Helper: Attaches 3D Golden VIP Crown + Golden-Rainbow Trail for VIP Gamepass Owners!
local function attachVIPRainbowTrail(player: Player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	if not hrp:FindFirstChild("VIPRainbowTrail") then
		local att0 = Instance.new("Attachment")
		att0.Name = "VIPTrailAtt0"
		att0.Position = Vector3.new(0, 1.5, 0)
		att0.Parent = hrp

		local att1 = Instance.new("Attachment")
		att1.Name = "VIPTrailAtt1"
		att1.Position = Vector3.new(0, -1.5, 0)
		att1.Parent = hrp

		local trail = Instance.new("Trail")
		trail.Name = "VIPRainbowTrail"
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		trail.Lifetime = 0.85
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 215, 45)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 115, 195)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(65, 225, 255)),
		})
		trail.Parent = hrp
	end

	local head = char:FindFirstChild("Head") :: BasePart?
	if head and not head:FindFirstChild("VIPGoldenCrown") then
		local crown = Instance.new("Part")
		crown.Name = "VIPGoldenCrown"
		crown.Shape = Enum.PartType.Cylinder
		crown.Size = Vector3.new(0.75, 1.9, 1.9)
		crown.Color = Color3.fromRGB(255, 215, 45)
		crown.Material = Enum.Material.Neon
		crown.CanCollide = false
		crown.Massless = true
		crown.CFrame = head.CFrame * CFrame.new(0, 1.25, 0) * CFrame.Angles(0, 0, math.rad(90))
		crown.Parent = head

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = crown
		weld.Parent = crown
	end
end

-- Helper: Attaches overhead "💖 VIP SUPPORTER" Nametag Badge for players who Liked & Favorited the game!
local function attachSupporterTag(player: Player)
	local char = player.Character
	local head = char and char:FindFirstChild("Head") :: BasePart?
	if not head or head:FindFirstChild("SupporterOverheadBadge") then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "SupporterOverheadBadge"
	bb.Size = UDim2.new(5.8, 0, 1.35, 0)
	bb.StudsOffset = Vector3.new(0, 2.75, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 75
	bb.Parent = head

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = "💖 VIP SUPPORTER ⭐"
	lbl.TextColor3 = Color3.fromRGB(255, 115, 205)
	lbl.TextScaled = true
	lbl.Parent = bb

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(28, 12, 34)
	stroke.Thickness = 2.5
	stroke.Parent = lbl
end

-- Like & Favorite + Notify VIP Supporter Reward Handler (+$5,000 Cash, +2 Spins, +15 Speed, 60s Shield & Overhead Badge!)
ClaimLikeFavoriteEvent.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	if session.ClaimedLikeReward then
		GuardianAlertEvent:FireClient(player, "💖 You already claimed your Like & Favorite VIP Supporter Rewards! Thank you for supporting!")
		return
	end
	session.ClaimedLikeReward = true
	local mult = if session.OwnedPasses and session.OwnedPasses["2xCash"] then 2 else 1
	local rewardCash = 5000 * mult
	session.Coins += rewardCash
	session.LifetimeCoins += rewardCash
	session.BonusSpins = (session.BonusSpins or 0) + 2
	session.SpeedStat += 15
	applyPlayerSpeed(player)
	updateSpeedUpgradePrompt(player)
	activateBossShield(player, 60)
	attachSupporterTag(player)
	GuardianAlertEvent:FireClient(
		player,
		string.format(
			"💖 THANK YOU FOR LIKING & FAVORITING! Claimed +$%s Cash, +2 Lucky Spins, +15 Speed, 60s Shield & VIP SUPPORTER Tag!",
			SlimeData.FormatNumber(rewardCash)
		)
	)
	syncPlayer(player)
end)

-- Daily Login Streak Chest Handler
ClaimDailyRewardEvent.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local now = os.time()
	local DAILY_COOLDOWN = 72000 -- 20 hours
	if session.LastDailyClaim > 0 and (now - session.LastDailyClaim) < DAILY_COOLDOWN then
		local rem = DAILY_COOLDOWN - (now - session.LastDailyClaim)
		local remH = math.floor(rem / 3600)
		local remM = math.floor((rem % 3600) / 60)
		GuardianAlertEvent:FireClient(player, string.format("⏳ Daily Streak Chest on cooldown! Next reward available in %dh %dm.", remH, remM))
		return
	end
	session.LastDailyClaim = now
	session.DailyStreak = (session.DailyStreak % 7) + 1
	local mult = if session.OwnedPasses["2xCash"] then 2 else 1
	local bonusCash = 500 * session.DailyStreak * mult
	session.Coins += bonusCash
	session.LifetimeCoins += bonusCash
	session.SpeedStat += 4
	session.TrapCharges += 1
	applyPlayerSpeed(player)
	ensureCombatGearInBackpack(player)
	GuardianAlertEvent:FireClient(
		player,
		string.format("🎁 Day %d Login Streak Claimed: +$%d Cash, +4 Speed & +1 Bear Trap!", session.DailyStreak, bonusCash)
	)
	syncPlayer(player)
end)

-- Playtime Rewards Chest Handler (2m, 5m, 10m, 15m, 30m Milestones!)
local PLAYTIME_MILESTONES = {
	[1] = { Key = "2m", ReqSec = 120, Cash = 1500, Speed = 3, Spins = 0, ShieldSec = 0, Mythic = false },
	[2] = { Key = "5m", ReqSec = 300, Cash = 4000, Speed = 6, Spins = 0, ShieldSec = 0, Mythic = false },
	[3] = { Key = "10m", ReqSec = 600, Cash = 10000, Speed = 0, Spins = 1, ShieldSec = 0, Mythic = false },
	[4] = { Key = "15m", ReqSec = 900, Cash = 25000, Speed = 12, Spins = 0, ShieldSec = 60, Mythic = false },
	[5] = { Key = "30m", ReqSec = 1800, Cash = 75000, Speed = 25, Spins = 0, ShieldSec = 0, Mythic = true },
}

ClaimPlaytimeRewardEvent.OnServerEvent:Connect(function(player: Player, milestoneIdx: any)
	local session = sessions[player]
	local idx = tonumber(milestoneIdx)
	if not session or not idx or not PLAYTIME_MILESTONES[idx] then
		return
	end
	local ms = PLAYTIME_MILESTONES[idx]
	if session.ClaimedPlaytime[ms.Key] or session.ClaimedPlaytime[tostring(idx)] then
		GuardianAlertEvent:FireClient(player, string.format("✅ You already claimed the %s Playtime Reward!", ms.Key))
		return
	end
	local playedSec = os.clock() - session.SessionStartTime
	if playedSec < ms.ReqSec and not RunService:IsStudio() then
		local rem = math.ceil(ms.ReqSec - playedSec)
		GuardianAlertEvent:FireClient(
			player,
			string.format("⏳ Play %d more seconds to unlock the %s Playtime Reward!", rem, ms.Key)
		)
		return
	end

	session.ClaimedPlaytime[ms.Key] = true
	session.ClaimedPlaytime[tostring(idx)] = true
	local mult = if session.OwnedPasses["2xCash"] then 2 else 1
	local cashWon = ms.Cash * mult
	session.Coins += cashWon
	session.LifetimeCoins += cashWon
	if ms.Speed > 0 then
		session.SpeedStat += ms.Speed
		applyPlayerSpeed(player)
		updateSpeedUpgradePrompt(player)
	end
	if ms.Spins > 0 then
		session.BonusSpins += ms.Spins
	end
	if ms.ShieldSec > 0 then
		activateBossShield(player, ms.ShieldSec)
	end
	if ms.Mythic then
		local mythicSlime = SlimeData.Slimes[35] or SlimeData.Slimes[#SlimeData.Slimes]
		if mythicSlime then
			local sId = tostring(mythicSlime.Id)
			session.FoundEggs[sId] = true
			if not autoReleaseSquishyIntoPen(player, sId) then
				session.BackpackCounts[sId] = (session.BackpackCounts[sId] or 0) + 1
			end
			refreshBackpackTools(player)
		end
	end

	GuardianAlertEvent:FireClient(
		player,
		string.format("🎁 Claimed %s Playtime Reward! (+$%d Cash%s)", ms.Key, cashWon, if ms.Mythic then " + MYTHIC SQUISHY IN YOUR PEN!" else "")
	)
	syncPlayer(player)
end)

-- Lucky Squishy Spin Wheel Handler (1 Free Spin Every 5 Minutes + Buy Spins for Cash/Robux!)
local WHEEL_PRIZES = {
	{ Label = "💰 +$2,500 Cash", Type = "Cash", Amount = 2500 },
	{ Label = "⚡ +8 Speed Boost", Type = "Speed", Amount = 8 },
	{ Label = "👑 2x Mythic Cash Multiplier (2m)", Type = "MythicBoost", Amount = 120 },
	{ Label = "🛡️ 60s Boss Shield Immunity", Type = "Shield", Amount = 60 },
	{ Label = "💎 +$15,000 JACKPOT CASH!", Type = "Cash", Amount = 15000 },
	{ Label = "🌈 Mystery Rare/Mythic Squishy!", Type = "Squishy", Amount = 1 },
}

local function executeWheelSpin(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local prize = WHEEL_PRIZES[math.random(1, #WHEEL_PRIZES)]
	if prize.Type == "Cash" then
		local mult = if session.OwnedPasses["2xCash"] then 2 else 1
		local amt = prize.Amount * mult
		session.Coins += amt
		session.LifetimeCoins += amt
		GuardianAlertEvent:FireClient(player, string.format("🎡 LUCKY WHEEL WIN: %s (+$%d)!", prize.Label, amt))
	elseif prize.Type == "Speed" then
		session.SpeedStat += prize.Amount
		applyPlayerSpeed(player)
		updateSpeedUpgradePrompt(player)
		GuardianAlertEvent:FireClient(player, string.format("🎡 LUCKY WHEEL WIN: %s!", prize.Label))
	elseif prize.Type == "MythicBoost" then
		session.MythicCashBoostUntil = os.clock() + prize.Amount
		recalculateIncome(session)
		GuardianAlertEvent:FireClient(player, "🎡 LUCKY WHEEL WIN: 👑 2x Mythic Cash Multiplier for 2 Minutes!")
	elseif prize.Type == "Shield" then
		activateBossShield(player, prize.Amount)
		GuardianAlertEvent:FireClient(player, "🎡 LUCKY WHEEL WIN: 🛡️ 60s Boss Shield Immunity Activated!")
	else
		local randSlime = SlimeData.Slimes[math.random(15, 35)]
		if randSlime then
			local sId = tostring(randSlime.Id)
			session.FoundEggs[sId] = true
			if not autoReleaseSquishyIntoPen(player, sId) then
				session.BackpackCounts[sId] = (session.BackpackCounts[sId] or 0) + 1
			end
			refreshBackpackTools(player)
			GuardianAlertEvent:FireClient(player, string.format("🎡 JACKPOT! Won %s ($%d/s) — Now roaming inside your Fenced Pen!", randSlime.Name, randSlime.IncomePerSec))
		end
	end
	syncPlayer(player)
end

SpinWheelRequestEvent.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local now = os.clock()
	if now >= (session.NextFreeSpinAt or 0) then
		-- Consume the 5-minute Free Spin!
		session.NextFreeSpinAt = now + 300
		executeWheelSpin(player)
	elseif (session.BonusSpins or 0) > 0 then
		session.BonusSpins -= 1
		executeWheelSpin(player)
	else
		local rem = math.ceil((session.NextFreeSpinAt or 0) - now)
		GuardianAlertEvent:FireClient(
			player,
			string.format("⏳ Next Free Spin in %ds! Or Buy a Spin with Cash ($2,500) or Robux!", rem)
		)
	end
end)

BuySpinCashEvent.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local spinCost = 2500
	if session.Coins < spinCost then
		GuardianAlertEvent:FireClient(player, "Need $2,500 Cash to buy a Bonus Wheel Spin!")
		return
	end
	session.Coins -= spinCost
	executeWheelSpin(player)
end)

-- =========================================================================
-- MarketplaceService Gamepasses (PromptGamePassPurchase) & Developer Products (PromptProductPurchase + ProcessReceipt)
-- =========================================================================
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")

local GAMEPASS_IDS: { [string]: number } = {
	["2xCash"] = 0,
	["2xSpeed"] = 0,
	["AutoHatch"] = 0,
	["VIP"] = 0,
	["Carry2Eggs"] = 0,
	["SquishyRadar"] = 0,
}

local DEVPRODUCT_IDS: { [string]: number } = {
	["InstantHatchAll"] = 0,
	["BossShield60s"] = 0,
	["CashPack5K"] = 0,
	["CashPack25K"] = 0,
	["CashPack100K"] = 0,
	["BuySpinRobux"] = 0,
	["LuckyEggRoll"] = 0,
}

local PASS_CASH_COSTS: { [string]: number } = {
	["Carry2Eggs"] = 3500,
	["2xSpeed"] = 5000,
	["2xCash"] = 7500,
	["SquishyRadar"] = 10000,
	["AutoHatch"] = 12500,
	["VIP"] = 20000,
}

local DEVPRODUCT_CASH_COSTS: { [string]: number } = {
	["InstantHatchAll"] = 500,
	["BossShield60s"] = 750,
	["LuckyEggRoll"] = 1500,
	["BuySpinRobux"] = 5000,
}

-- Auto-discover any real Robux Developer Products on Roblox
task.spawn(function()
	pcall(function()
		local pages = MarketplaceService:GetDeveloperProductsAsync()
		while true do
			local items = pages:GetCurrentPage()
			for _, item in ipairs(items) do
				local pName = tostring(item.Name or "")
				local pId = tonumber(item.ProductId) or 0
				if pId > 0 then
					for key in pairs(DEVPRODUCT_IDS) do
						if string.find(string.lower(pName), string.lower(key)) then
							DEVPRODUCT_IDS[key] = pId
						elseif key == "InstantHatchAll" and string.find(string.lower(pName), "hatch") then
							DEVPRODUCT_IDS[key] = pId
						elseif key == "BossShield60s" and string.find(string.lower(pName), "shield") then
							DEVPRODUCT_IDS[key] = pId
						elseif key == "LuckyEggRoll" and string.find(string.lower(pName), "lucky") then
							DEVPRODUCT_IDS[key] = pId
						elseif key == "BuySpinRobux" and (string.find(string.lower(pName), "spin") or string.find(string.lower(pName), "wheel")) then
							DEVPRODUCT_IDS[key] = pId
						elseif key == "CashPack5K" and (string.find(pName, "5,000") or string.find(pName, "5000") or string.find(pName, "5K")) then
							DEVPRODUCT_IDS[key] = pId
						elseif key == "CashPack25K" and (string.find(pName, "25,000") or string.find(pName, "25000") or string.find(pName, "25K")) then
							DEVPRODUCT_IDS[key] = pId
						elseif key == "CashPack100K" and (string.find(pName, "100,000") or string.find(pName, "100000") or string.find(pName, "100K")) then
							DEVPRODUCT_IDS[key] = pId
						end
					end
				end
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
	end)
end)

local function grantGamePassReward(player: Player, passKey: string)
	local session = sessions[player]
	if not session then
		return
	end
	session.OwnedPasses[passKey] = true
	if passKey == "2xCash" then
		recalculateIncome(session)
		updatePlotOwnerSign(session.PlotIndex, player.DisplayName, session.PassiveIncomeRate, session.UncollectedPlotCash)
		GuardianAlertEvent:FireClient(player, "💰 Unlocked 2x CASH FOREVER Gamepass! All Cash & Brainrot Income Doubled!")
	elseif passKey == "2xSpeed" then
		session.SpeedStat += 16
		applyPlayerSpeed(player)
		updateSpeedUpgradePrompt(player)
		GuardianAlertEvent:FireClient(player, "⚡ Unlocked 2x TREADMILL SPEED FOREVER! +16 Speed & 2x Treadmill Gains!")
	elseif passKey == "AutoHatch" then
		GuardianAlertEvent:FireClient(player, "🥚 Unlocked FAST HATCH (1s Incubators)! All Brainrot Eggs Hatch in 1 Second!")
	elseif passKey == "VIP" then
		session.Coins += 10000
		session.LifetimeCoins += 10000
		session.SpeedStat += 25
		recalculateIncome(session)
		applyPlayerSpeed(player)
		attachVIPRainbowTrail(player)
		GuardianAlertEvent:FireClient(player, "👑 Unlocked VIP CROWN + GOLDEN TRAIL + +50% CASH (+10K Cash & +25 Speed)!")
	elseif passKey == "Carry2Eggs" then
		GuardianAlertEvent:FireClient(player, "🎒 Unlocked +2 CARRY CAPACITY! You can now steal & carry 2 Brainrot Eggs at once!")
	elseif passKey == "SquishyRadar" then
		GuardianAlertEvent:FireClient(player, "🧸 Unlocked SQUISHY RADAR FOREVER! Your Guiding Arrow can now track any hidden Squishy for free!")
	end
	syncPlayer(player)
end

local function grantDeveloperProductReward(player: Player, productKey: string): boolean
	local session = sessions[player]
	if not session then
		return false
	end
	if productKey == "InstantHatchAll" then
		for _, incState in pairs(session.Incubators) do
			if incState.EggId and not incState.IsReady then
				incState.ReadyAt = os.clock()
			end
		end
		GuardianAlertEvent:FireClient(player, "⚡ HATCH ALL INCUBATORS NOW: All planted Brainrot Eggs hatched instantly!")
	elseif productKey == "BossShield60s" then
		activateBossShield(player, 60)
		GuardianAlertEvent:FireClient(player, "🛡️ BOSS SHIELD ACTIVATED! 60 Seconds of complete Boss & Hazard Immunity!")
	elseif productKey == "CashPack5K" then
		session.Coins += 5000
		session.LifetimeCoins += 5000
		GuardianAlertEvent:FireClient(player, "💵 Starter Cash Pack: +$5,000 Cash added!")
	elseif productKey == "CashPack25K" then
		session.Coins += 25000
		session.LifetimeCoins += 25000
		GuardianAlertEvent:FireClient(player, "💵 Mega Cash Pack: +$25,000 Cash added!")
	elseif productKey == "CashPack100K" then
		session.Coins += 100000
		session.LifetimeCoins += 100000
		GuardianAlertEvent:FireClient(player, "💎 ULTIMATE CASH PACK: +$100,000 Cash added!")
	elseif productKey == "BuySpinRobux" then
		session.BonusSpins = (session.BonusSpins or 0) + 3
		GuardianAlertEvent:FireClient(player, "🎡 Purchased +3 Lucky Squishy Wheel Spins!")
	elseif productKey == "LuckyEggRoll" then
		session.OwnedPasses["LuckyEggRoll"] = true
		GuardianAlertEvent:FireClient(player, "🎲 LUCKY EGG ROLL ACTIVATED! 3.5x Higher Epic, Legendary & Mythic Brainrot Hatch Odds!")
	else
		return false
	end
	syncPlayer(player)
	return true
end

BuySquishyHintEvent.OnServerEvent:Connect(function(player: Player, targetIdArg: any)
	local session = sessions[player]
	if not session then
		return
	end
	local targetId = tostring(targetIdArg or "")
	local slimeDef = SlimeData.ById[targetId]
	if slimeDef then
		local tNum = tonumber((slimeDef :: any).UnlockOrder or (slimeDef :: any).NumericId or slimeDef.Id) or 1
		if tNum <= 35 then
			slimeDef = nil
		end
	end
	if not slimeDef then
		-- Find the first uncollected Hidden Collectible Squishy (#36-#117) in the player's current unlocked stages
		for _, s in ipairs(SlimeData.Slimes) do
			local sId = tostring((s :: any).Id)
			local numId = tonumber((s :: any).UnlockOrder or (s :: any).NumericId or s.Id) or 1
			if numId > 35 and not session.FoundEggs[sId] and not session.UnlockedHints[sId] then
				if SlimeData.IsLevelUnlocked(session.FoundEggs, session.SpeedStat, s.Level, session.FenceLevel or 1, session.UnlockedGates) then
					slimeDef = s
					targetId = sId
					break
				end
			end
		end
	end
	if not slimeDef then
		GuardianAlertEvent:FireClient(player, "🔍 You have already unlocked hints for all available Squishies in your unlocked Stages!")
		return
	end
	if session.OwnedPasses["SquishyRadar"] or session.UnlockedHints[targetId] then
		session.UnlockedHints[targetId] = true
		GuardianAlertEvent:FireClient(player, string.format("🔍 Radar locked onto %s (Stage %d)!", slimeDef.Name, slimeDef.Level))
		syncPlayer(player)
		return
	end
	local cost = SlimeData.GetHintCostForStage(slimeDef.Level)
	if session.Coins < cost then
		GuardianAlertEvent:FireClient(
			player,
			string.format("Need $%s Cash to buy a 🔍 Squishy Finder Hint for Stage %d (%s)!", SlimeData.FormatNumber(cost), slimeDef.Level, slimeDef.Name)
		)
		return
	end
	session.Coins -= cost
	session.UnlockedHints[targetId] = true
	GuardianAlertEvent:FireClient(
		player,
		string.format("🔍 Unlocked Hint & X-Ray Guiding Beam for %s (Stage %d): %s", slimeDef.Name, slimeDef.Level, slimeDef.Hint)
	)
	syncPlayer(player)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end
	for passKey, configuredId in pairs(GAMEPASS_IDS) do
		if configuredId > 0 and configuredId == gamePassId then
			grantGamePassReward(player, passKey)
			if savePlayerData then
				savePlayerData(player)
			end
			break
		end
	end
end)

local savePlayerData: (Player) -> ()

MarketplaceService.ProcessReceipt = function(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	for prodKey, configuredId in pairs(DEVPRODUCT_IDS) do
		if configuredId > 0 and configuredId == receiptInfo.ProductId then
			if grantDeveloperProductReward(player, prodKey) then
				savePlayerData(player)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

BuyRobuxItemEvent.OnServerEvent:Connect(function(player: Player, itemKey: any)
	local session = sessions[player]
	if not session or type(itemKey) ~= "string" then
		return
	end

	-- 1. If already owned, alert and return
	if session.OwnedPasses and session.OwnedPasses[itemKey] then
		GuardianAlertEvent:FireClient(player, string.format("✅ You already own %s!", itemKey))
		return
	end

	pcall(function()
		if GAMEPASS_IDS[itemKey] ~= nil then
			local passId = GAMEPASS_IDS[itemKey]
			if passId > 0 then
				MarketplaceService:PromptGamePassPurchase(player, passId)
			else
				local cashCost = PASS_CASH_COSTS[itemKey] or 10000
				if session.Coins >= cashCost then
					session.Coins -= cashCost
					grantGamePassReward(player, itemKey)
					if savePlayerData then
						savePlayerData(player)
					end
					GuardianAlertEvent:FireClient(
						player,
						string.format("🎉 Purchased %s for $%s In-Game Cash!", itemKey, SlimeData.FormatNumber(cashCost))
					)
				else
					GuardianAlertEvent:FireClient(
						player,
						string.format(
							"💰 Need $%s Cash to buy %s (You have $%s)!",
							SlimeData.FormatNumber(cashCost),
							itemKey,
							SlimeData.FormatNumber(session.Coins)
						)
					)
				end
			end
		elseif DEVPRODUCT_IDS[itemKey] ~= nil then
			local prodId = DEVPRODUCT_IDS[itemKey]
			if prodId > 0 then
				local isRestricted = false
				if itemKey == "BuySpinRobux" then
					local pSuccess, policy = pcall(function()
						return PolicyService:GetPolicyInfoForPlayerAsync(player)
					end)
					if pSuccess and policy and policy.ArePaidRandomItemsRestricted == true then
						isRestricted = true
					end
				end
				if isRestricted then
					GuardianAlertEvent:FireClient(player, "Paid random wheel spins are restricted by your account policy.")
					return
				end
				MarketplaceService:PromptProductPurchase(player, prodId)
			elseif itemKey == "CashPack5K" or itemKey == "CashPack25K" or itemKey == "CashPack100K" then
				if not session.ClaimedLikeReward then
					OpenModalEvent:FireClient(player, "LikeFavorite")
					GuardianAlertEvent:FireClient(
						player,
						"💖 Claim +$5,000 Free Starter Cash at the Like & Favorite VIP Booth!"
					)
				else
					GuardianAlertEvent:FireClient(
						player,
						"💎 Cash Packs require configured Developer Products! Complete Biome Stages & Treadmill runs for huge cash!"
					)
				end
			else
				local cashCost = DEVPRODUCT_CASH_COSTS[itemKey]
				if cashCost then
					if session.Coins >= cashCost then
						session.Coins -= cashCost
						if grantDeveloperProductReward(player, itemKey) then
							if savePlayerData then
								savePlayerData(player)
							end
							GuardianAlertEvent:FireClient(
								player,
								string.format("🎉 Purchased %s for $%s In-Game Cash!", itemKey, SlimeData.FormatNumber(cashCost))
							)
						end
					else
						GuardianAlertEvent:FireClient(
							player,
							string.format(
								"💰 Need $%s Cash to buy %s (You have $%s)!",
								SlimeData.FormatNumber(cashCost),
								itemKey,
								SlimeData.FormatNumber(session.Coins)
							)
						)
					end
				else
					GuardianAlertEvent:FireClient(player, "💎 Developer Product checkout coming soon!")
				end
			end
		end
	end)
end)

ToggleSloMoEvent.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	session.SloMoActive = not session.SloMoActive
	session.SpeedThrottleRatio = if session.SloMoActive then 0.50 else 1.00
	applyPlayerSpeed(player)
	syncPlayer(player)
end)

SetSpeedThrottleEvent.OnServerEvent:Connect(function(player: Player, ratioArg: any)
	local session = sessions[player]
	local ratio = tonumber(ratioArg)
	if not session or not ratio then
		return
	end
	-- Allowed HUD WalkSpeed Control Selector ratios: 25%, 50%, 75%, 100%
	local clamped = math.clamp(ratio, 0.25, 1.00)
	session.SpeedThrottleRatio = clamped
	session.SloMoActive = (clamped < 0.99)
	applyPlayerSpeed(player)
	syncPlayer(player)
end)

EquipSquishyEvent.OnServerEvent:Connect(function(player: Player, squishyId: any)
	local session = sessions[player]
	if not session or type(squishyId) ~= "string" then
		return
	end
	if (session.BackpackCounts[squishyId] or 0) > 0 then
		session.EquippedId = squishyId
		syncPlayer(player)
	end
end)

GetInitialStateFunc.OnServerInvoke = function(player: Player)
	local tries = 0
	while not sessions[player] and tries < 20 do
		task.wait(0.1)
		tries += 1
	end
	return serializeSession(player)
end

local DataStoreService = game:GetService("DataStoreService")
local playerDataStore: any = nil
local coinsODS: any = nil
local speedODS: any = nil
local squishiesODS: any = nil
if game.GameId > 0 then
	pcall(function()
		-- Global Reset v22: Resets all legacy currency & old gameplay settings so every player starts brand new!
		playerDataStore = DataStoreService:GetDataStore("FindMySquishy_GlobalReset_v22")
		coinsODS = DataStoreService:GetOrderedDataStore("FindMySquishy_GlobalCoins_v22")
		speedODS = DataStoreService:GetOrderedDataStore("FindMySquishy_GlobalSpeed_v22")
		squishiesODS = DataStoreService:GetOrderedDataStore("FindMySquishy_GlobalSquishies_v22")
	end)
end

function savePlayerData(player: Player)
	local session = sessions[player]
	if not session or game.GameId == 0 then
		return
	end
	if playerDataStore then
		local savedPedestals: { [string]: { SquishyId: string, Level: number } } = {}
		for slotIdx, pedState in pairs(session.Pedestals) do
			if pedState and pedState.SquishyId then
				savedPedestals[tostring(slotIdx)] = {
					SquishyId = tostring(pedState.SquishyId),
					Level = tonumber(pedState.Level) or 1,
				}
			end
		end
		local payload = {
			Coins = session.Coins,
			LifetimeCoins = session.LifetimeCoins,
			SpeedStat = session.SpeedStat,
			SpeedLevel = session.SpeedLevel,
			FenceLevel = session.FenceLevel or 1,
			Rebirths = session.Rebirths,
			DailyStreak = session.DailyStreak,
			LastDailyClaim = session.LastDailyClaim or 0,
			ClaimedLikeReward = session.ClaimedLikeReward == true,
			OwnedPasses = session.OwnedPasses,
			UnlockedHints = session.UnlockedHints,
			CollectedCoins = session.CollectedCoins,
			UnlockedGates = session.UnlockedGates,
			ClaimedStageJackpots = session.ClaimedStageJackpots,
			FoundEggs = session.FoundEggs,
			BackpackCounts = session.BackpackCounts,
			SavedPedestals = savedPedestals,
		}
		pcall(function()
			playerDataStore:SetAsync("Player_" .. tostring(player.UserId), payload)
		end)
	end
	pcall(function()
		if coinsODS then
			coinsODS:SetAsync(player.Name, math.floor(session.Coins))
		end
		if speedODS then
			speedODS:SetAsync(player.Name, math.floor(session.SpeedStat))
		end
		if squishiesODS then
			squishiesODS:SetAsync(player.Name, SlimeData.CountFound(session.FoundEggs))
		end
	end)
end

-- Live Global Top-10 OrderedDataStore 3D Leaderboard Updater (Updates CoinsBoard, SpeedBoard, SquishiesBoard!)
local BENCHMARK_CHAMPS = {
	{ Name = "SquishyKing99", Coins = 48500000, Speed = 250000000, Squishies = 114 },
	{ Name = "RainbowRunner", Coins = 12400000, Speed = 25000000, Squishies = 98 },
	{ Name = "DinoTreadmillPro", Coins = 3490000, Speed = 2500000, Squishies = 86 },
	{ Name = "CandyThiefX", Coins = 820000, Speed = 250000, Squishies = 74 },
	{ Name = "VolcanoLegend", Coins = 126000, Speed = 25000, Squishies = 62 },
	{ Name = "TikiExplorer", Coins = 28400, Speed = 2500, Squishies = 49 },
	{ Name = "CrystalHunter", Coins = 5200, Speed = 250, Squishies = 35 },
	{ Name = "MeadowScout", Coins = 2400, Speed = 120, Squishies = 22 },
	{ Name = "RookieHatch", Coins = 950, Speed = 45, Squishies = 11 },
}

local function updateGlobalLeaderboards()
	local hubFolder = world.WorldFolder:FindFirstChild("SafeZoneHub")
	local lbFolder = hubFolder and hubFolder:FindFirstChild("GlobalLeaderboards")
	if not lbFolder then
		return
	end

	local entriesByName: { [string]: { Name: string, Coins: number, Speed: number, Squishies: number } } = {}
	for _, b in ipairs(BENCHMARK_CHAMPS) do
		entriesByName[b.Name] = { Name = b.Name, Coins = b.Coins, Speed = b.Speed, Squishies = b.Squishies }
	end

	-- Query Global OrderedDataStores when published (Chapter 5 OrderedDataStore Global Leaderboards)
	local function mergeODS(ods: any, field: "Coins" | "Speed" | "Squishies")
		if not ods then
			return
		end
		pcall(function()
			local pages = ods:GetSortedAsync(false, 10)
			local topPage = pages:GetCurrentPage()
			for _, row in ipairs(topPage) do
				local keyName = tostring(row.key)
				local val = tonumber(row.value) or 0
				if not entriesByName[keyName] then
					entriesByName[keyName] = { Name = keyName, Coins = 0, Speed = 16, Squishies = 0 }
				end
				if val > (entriesByName[keyName][field] or 0) then
					entriesByName[keyName][field] = val
				end
			end
		end)
	end

	mergeODS(coinsODS, "Coins")
	mergeODS(speedODS, "Speed")
	mergeODS(squishiesODS, "Squishies")

	for _, p in ipairs(Players:GetPlayers()) do
		local s = sessions[p]
		if s then
			local liveKey = "⭐ " .. p.DisplayName
			entriesByName[liveKey] = {
				Name = liveKey,
				Coins = math.floor(s.Coins),
				Speed = math.floor(s.SpeedStat),
				Squishies = SlimeData.CountFound(s.FoundEggs),
			}
		end
	end

	local entries: { { Name: string, Coins: number, Speed: number, Squishies: number } } = {}
	for _, entry in pairs(entriesByName) do
		table.insert(entries, entry)
	end

	for _, boardModel in ipairs(lbFolder:GetChildren()) do
		local statKey = boardModel:GetAttribute("StatKey") :: string?
		local surface = boardModel:FindFirstChild("BoardSurface")
		if statKey and surface then
			local sorted = table.clone(entries)
			table.sort(sorted, function(a: any, b: any)
				return (a[statKey] or 0) > (b[statKey] or 0)
			end)

			for _, sg in ipairs(surface:GetChildren()) do
				if sg:IsA("SurfaceGui") then
					local container = sg:FindFirstChild("Container")
					local rows = container and container:FindFirstChild("Rows")
					if rows then
						for rank = 1, 10 do
							local rowLbl = rows:FindFirstChild("Rank_" .. tostring(rank)) :: TextLabel?
							local item = sorted[rank]
							if rowLbl and item then
								local formattedVal = if statKey == "Coins"
									then string.format("💰 $%s", SlimeData.FormatNumber(item.Coins))
									elseif statKey == "Speed" then string.format("⚡ %s Spd", SlimeData.FormatNumber(item.Speed))
									else string.format("✨ %d / 117", item.Squishies)
								local newLine = string.format("#%d  %s  —  %s", rank, item.Name, formattedVal)
								if rowLbl.Text ~= newLine then
									rowLbl.Text = newLine
								end
							end
						end
					end
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		updateGlobalLeaderboards()
		task.wait(8.0)
	end
end)

-- Player Lifecycle Setup
local function setupPlayer(player: Player)
	local assignedPlot = ((#Players:GetPlayers() - 1) % 7) + 1
	for idx = 1, 7 do
		if plotOwners[idx] == nil then
			assignedPlot = idx
			plotOwners[idx] = player
			break
		end
	end

	local incubators: { [number]: IncubatorState } = {}
	for i = 1, 5 do
		incubators[i] = {
			EggId = nil,
			ReadyAt = nil,
			IsReady = false,
			VisualModel = nil,
		}
	end

	local loadedData: any = nil
	if playerDataStore then
		pcall(function()
			loadedData = playerDataStore:GetAsync("Player_" .. tostring(player.UserId))
		end)
	end

	local savedGates = if loadedData and type(loadedData.UnlockedGates) == "table" then loadedData.UnlockedGates else { ["1"] = true }
	savedGates["1"] = true

	sessions[player] = {
		Coins = if loadedData and type(loadedData.Coins) == "number" then loadedData.Coins else 150,
		LifetimeCoins = if loadedData and type(loadedData.LifetimeCoins) == "number" then loadedData.LifetimeCoins else 150,
		SpeedStat = if loadedData and type(loadedData.SpeedStat) == "number" then loadedData.SpeedStat else 16,
		SpeedLevel = if loadedData and type(loadedData.SpeedLevel) == "number" then loadedData.SpeedLevel else 1,
		FenceLevel = if loadedData and type(loadedData.FenceLevel) == "number" then math.clamp(loadedData.FenceLevel, 1, 8) else 1,
		SpeedThrottleRatio = 1.0,
		Rebirths = if loadedData and type(loadedData.Rebirths) == "number" then loadedData.Rebirths else 0,
		DailyStreak = if loadedData and type(loadedData.DailyStreak) == "number" then loadedData.DailyStreak else 0,
		LastDailyClaim = if loadedData and type(loadedData.LastDailyClaim) == "number" then loadedData.LastDailyClaim else 0,
		LastWheelSpin = 0,
		NextFreeSpinAt = 0,
		BonusSpins = 1,
		SessionStartTime = os.clock(),
		ClaimedPlaytime = {},
		ClaimedLikeReward = if loadedData and loadedData.ClaimedLikeReward == true then true else false,
		UnlockedHints = if loadedData and type(loadedData.UnlockedHints) == "table" then loadedData.UnlockedHints else {},
		CollectedCoins = if loadedData and type(loadedData.CollectedCoins) == "table" then loadedData.CollectedCoins else {},
		UnlockedGates = savedGates,
		ClaimedStageJackpots = if loadedData and type(loadedData.ClaimedStageJackpots) == "table" then loadedData.ClaimedStageJackpots else {},
		BossShieldUntil = 0,
		MythicCashBoostUntil = 0,
		SloMoActive = false,
		OwnedPasses = if loadedData and type(loadedData.OwnedPasses) == "table" then loadedData.OwnedPasses else {},
		PlotIndex = assignedPlot,
		CarriedEggId = nil,
		CarriedEggVisual = nil,
		CarriedEggIds = {},
		CarriedEggVisuals = {},
		FoundEggs = if loadedData and type(loadedData.FoundEggs) == "table" then loadedData.FoundEggs else {},
		BackpackCounts = if loadedData and type(loadedData.BackpackCounts) == "table" then loadedData.BackpackCounts else {},
		EquippedId = nil,
		PassiveIncomeRate = 0,
		UncollectedPlotCash = 0,
		LastTreadmillStep = 0,
		TrapCharges = 3,
		LastBatSwing = 0,
		Incubators = incubators,
		Pedestals = {},
	}

	-- Check MarketplaceService GamePass ownership on join for any configured Gamepass IDs
	for passKey, passId in pairs(GAMEPASS_IDS) do
		if passId > 0 then
			pcall(function()
				if MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId) then
					sessions[player].OwnedPasses[passKey] = true
				end
			end)
		end
	end

	local plotModelForResize = getPlotModel(assignedPlot)
	if plotModelForResize then
		WorldBuilder.ResizePlayerFencePen(plotModelForResize, sessions[player].FenceLevel)
	end

	-- Restore saved hatched Ranch Pen Brainrots (#1-#35) onto the player's plot pedestals!
	if loadedData and type(loadedData.SavedPedestals) == "table" then
		local plotModel = getPlotModel(assignedPlot)
		local pedsFolder = plotModel and plotModel:FindFirstChild("Pedestals")
		local maxSavedSlots = SlimeData.GetMaxBrainrotsForFenceLevel(sessions[player].FenceLevel)
		for slotKey, pInfo in pairs(loadedData.SavedPedestals) do
			local slotIdx = tonumber(slotKey)
			local sId = if type(pInfo) == "table" then tostring(pInfo.SquishyId or "") else ""
			local sData = SlimeData.ById[sId]
			if slotIdx and slotIdx >= 1 and slotIdx <= maxSavedSlots and sData and not (sData :: any).IsShiningSquishy then
				local pedPart = pedsFolder and pedsFolder:FindFirstChild("Pedestal_" .. tostring(slotIdx)) :: BasePart?
				local homePos = if pedPart then (pedPart.Position + Vector3.new(0, 1.8, 0)) else Vector3.new(0, 2.5, 54)
				local pr = pedPart and pedPart:FindFirstChild("PlaceSquishyPrompt", true) :: ProximityPrompt?
				if pr then
					pr.Enabled = false
				end
				sessions[player].Pedestals[slotIdx] = {
					SquishyId = sId,
					Level = math.clamp(tonumber(pInfo.Level) or 1, 1, 15),
					VisualModel = nil :: any,
					HomePos = homePos,
					RoamPos = homePos,
					RoamTarget = homePos + Vector3.new((math.random() - 0.5) * 5.0, 0, (math.random() - 0.5) * 5.0),
					NextRoamChange = os.clock() + 1.5,
				}
				refreshPedestalVisual(player, slotIdx)
			end
		end
		recalculateIncome(sessions[player])
	end

	-- Official Server leaderstats Folder (Coins, Squishies, Speed, Rebirths)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local coinsVal = Instance.new("IntValue")
	coinsVal.Name = "Coins"
	coinsVal.Value = math.floor(sessions[player].Coins)
	coinsVal.Parent = ls

	local squishiesVal = Instance.new("IntValue")
	squishiesVal.Name = "Squishies"
	squishiesVal.Value = SlimeData.CountFound(sessions[player].FoundEggs)
	squishiesVal.Parent = ls

	local speedVal = Instance.new("IntValue")
	speedVal.Name = "Speed"
	speedVal.Value = math.floor(sessions[player].SpeedStat)
	speedVal.Parent = ls

	local rebVal = Instance.new("IntValue")
	rebVal.Name = "Rebirths"
	rebVal.Value = sessions[player].Rebirths
	rebVal.Parent = ls

	updatePlotOwnerSign(assignedPlot, player.DisplayName, sessions[player].PassiveIncomeRate, 0)
	updateSpeedUpgradePrompt(player)
	updateFenceUpgradePrompt(player)
	updateGrowStandPrompt(player)
	updateGlobalLeaderboards()

	player.CharacterAdded:Connect(function(char: Model)
		task.wait(0.15)
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = CFrame.new(Vector3.new(0, 4.5, 38), Vector3.new(0, 4.5, -55))
		end
		local s = sessions[player]
		if s then
			if s.OwnedPasses["VIP"] then
				attachVIPRainbowTrail(player)
			end
			if s.ClaimedLikeReward then
				attachSupporterTag(player)
			end
			if (s.BossShieldUntil or 0) > os.clock() then
				activateBossShield(player, math.ceil(s.BossShieldUntil - os.clock()))
			end
			-- Re-attach any carried eggs onto the respawned character so they are never lost!
			if #s.CarriedEggIds > 0 and hrp then
				for _, oldVis in ipairs(s.CarriedEggVisuals) do
					if oldVis and oldVis.Parent then
						oldVis:Destroy()
					end
				end
				table.clear(s.CarriedEggVisuals)
				for slotNum, eggId in ipairs(s.CarriedEggIds) do
					local eData = SlimeData.ById[eggId]
					if eData then
						local carriedModel = SquishyBuilder.CreateCarriedEgg(eData)
						carriedModel.Parent = char
						local root = carriedModel.PrimaryPart
						if root then
							local offset = if slotNum == 1 then CFrame.new(0, 2.2, -3.2) else CFrame.new(0, 5.4, -2.8)
							root.CFrame = hrp.CFrame * offset
							local weld = Instance.new("WeldConstraint")
							weld.Part0 = hrp
							weld.Part1 = root
							weld.Parent = root
						end
						table.insert(s.CarriedEggVisuals, carriedModel)
					end
				end
				s.CarriedEggVisual = s.CarriedEggVisuals[1]
			end
		end
		applyPlayerSpeed(player)
		refreshBackpackTools(player)
	end)

	if player.Character then
		task.spawn(function()
			local hrp = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				hrp.CFrame = CFrame.new(Vector3.new(0, 4.5, 38), Vector3.new(0, 4.5, -55))
			end
			if sessions[player] then
				if sessions[player].OwnedPasses["VIP"] then
					attachVIPRainbowTrail(player)
				end
				if sessions[player].ClaimedLikeReward then
					attachSupporterTag(player)
				end
			end
			applyPlayerSpeed(player)
			refreshBackpackTools(player)
		end)
	end

	syncPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	local session = sessions[player]
	if session then
		savePlayerData(player)
		session.BossShieldUntil = 0
		while #session.CarriedEggIds > 0 do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			dropCarriedEggAtSpot(player, if hrp then hrp.Position else Vector3.new(0, 3.8, -40), "Player Left")
		end
		-- Clean up placed Pedestals & Incubators on the player's plot
		local plotModel = getPlotModel(session.PlotIndex)
		for slotIdx, pedState in pairs(session.Pedestals) do
			if pedState.VisualModel and pedState.VisualModel.Parent then
				pedState.VisualModel:Destroy()
			end
			if plotModel then
				local peds = plotModel:FindFirstChild("Pedestals")
				local pedPart = peds and peds:FindFirstChild("Pedestal_" .. tostring(slotIdx))
				local pr = pedPart and pedPart:FindFirstChild("PlaceSquishyPrompt", true) :: ProximityPrompt?
				if pr then
					pr.Enabled = false
				end
			end
		end
		for incIdx, incState in pairs(session.Incubators) do
			if incState.VisualModel and incState.VisualModel.Parent then
				incState.VisualModel:Destroy()
			end
			incState.EggId = nil
			incState.IsReady = false
			if plotModel then
				local incs = plotModel:FindFirstChild("Incubators")
				local incPad = incs and incs:FindFirstChild("Incubator_" .. tostring(incIdx))
				local pr = incPad and incPad:FindFirstChild("IncubatorPrompt", true) :: ProximityPrompt?
				if pr then
					pr.ActionText = "Plant Carried Egg"
					pr.ObjectText = "Empty Incubator #" .. tostring(incIdx)
					pr.Enabled = false
				end
			end
		end
		if plotModel then
			WorldBuilder.ResizePlayerFencePen(plotModel, 1)
		end
		if plotOwners[session.PlotIndex] == player then
			plotOwners[session.PlotIndex] = nil
			updatePlotOwnerSign(session.PlotIndex, "UNCLAIMED", 0, 0)
		end
		sessions[player] = nil
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end)


