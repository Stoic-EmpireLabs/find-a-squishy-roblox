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

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SlimeData = require(Shared:WaitForChild("SlimeData"))
local SquishyBuilder = require(Shared:WaitForChild("SquishyBuilder"))
local PrebuiltLoader = require(Shared:WaitForChild("PrebuiltLoader"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

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
local GuardianAlertEvent = ensureRemoteEvent("GuardianAlert")
local EquipSquishyEvent = ensureRemoteEvent("EquipSquishy")
local BuySpeedUpgradeEvent = ensureRemoteEvent("BuySpeedUpgrade")
local RebirthRequestEvent = ensureRemoteEvent("RebirthRequest")
local ClaimDailyRewardEvent = ensureRemoteEvent("ClaimDailyReward")
local ClaimPlaytimeRewardEvent = ensureRemoteEvent("ClaimPlaytimeReward")
local ToggleSloMoEvent = ensureRemoteEvent("ToggleSloMo")
local SpinWheelRequestEvent = ensureRemoteEvent("SpinWheelRequest")
local BuySpinCashEvent = ensureRemoteEvent("BuySpinCash")
local BuyRobuxItemEvent = ensureRemoteEvent("BuyRobuxItem")
local OpenModalEvent = ensureRemoteEvent("OpenModal")
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
}

export type PlayerSession = {
	Coins: number,
	LifetimeCoins: number,
	SpeedStat: number,
	SpeedLevel: number,
	Rebirths: number,
	DailyStreak: number,
	LastDailyClaim: number,
	LastWheelSpin: number,
	NextFreeSpinAt: number,
	BonusSpins: number,
	SessionStartTime: number,
	ClaimedPlaytime: { [string]: boolean },
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

	local unlockedLevels = {}
	local nextStageSpeedGoal = 140
	local nextStageName = "MAX STAGE"
	for _, lvl in ipairs(SlimeData.Levels) do
		local reqSpd = lvl.RequiredSpeed or 16
		local isUnlocked = (session.SpeedStat >= reqSpd) or (session.LifetimeCoins >= lvl.RequiredCoins)
		unlockedLevels[tostring(lvl.Id)] = isUnlocked
		if not isUnlocked and nextStageName == "MAX STAGE" then
			nextStageSpeedGoal = reqSpd
			nextStageName = string.format("Stage %d: %s", lvl.Id, lvl.Name)
		end
	end

	local nextSpeedCost = math.floor(50 * math.pow(1.45, session.SpeedLevel - 1))
	local nextRebirthCost = math.floor(5000 * math.pow(3.0, session.Rebirths))
	local now = os.clock()

	return {
		Coins = session.Coins,
		LifetimeCoins = session.LifetimeCoins,
		SpeedStat = math.floor(session.SpeedStat),
		SpeedLevel = session.SpeedLevel,
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
		BossShieldRemaining = math.max(0, math.ceil((session.BossShieldUntil or 0) - now)),
		SpinCashBoostRemaining = math.max(0, math.ceil((session.MythicCashBoostUntil or 0) - now)),
		SpinCashMultiplier = 2,
		SloMoActive = session.SloMoActive,
		OwnedPasses = session.OwnedPasses,
		PlotIndex = session.PlotIndex,
		CarriedEggId = session.CarriedEggId,
		CarriedEggCount = #session.CarriedEggIds,
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

local function applyPlayerSpeed(player: Player)
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

	local speed = session.SpeedStat
	if session.CarriedEggId then
		local eggData = SlimeData.ById[session.CarriedEggId]
		if eggData then
			local weightPenalty = 1 + (eggData.Level * 0.06)
			speed = math.max(12, speed / weightPenalty)
		end
	end
	if session.SloMoActive then
		speed = speed * 0.68
	end
	hum.WalkSpeed = speed
end

-- Controls visibility & prompt of a World Egg
local function setWorldEggTaken(eggId: string, isTaken: boolean, isDroppedInPlace: boolean?)
	local eggModel = world.WorldEggs[eggId]
	if not eggModel then
		return
	end
	local sData = SlimeData.ById[eggId]
	for _, desc in ipairs(eggModel:GetDescendants()) do
		if desc:IsA("BasePart") then
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
		elseif desc:IsA("BillboardGui") then
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
	local eggData = SlimeData.ById[droppedEggId]

	-- Clamp inside the playable biome bounds so it drops cleanly on the floor right where they got hit
	local dropX = math.clamp(hitPosition.X, -58, 58)
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

-- Creates & Syncs Hotbar Tools: "Bat", "Bear Trap x3", plus Hatched Squishies!
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

	-- 1. Bat Tool (Swings to stun chasing Bosses or knock rival egg carriers!)
	local hasBat = backpack:FindFirstChild("Bat") or (char and char:FindFirstChild("Bat"))
	if not hasBat then
		local batTool = Instance.new("Tool")
		batTool.Name = "Bat"
		batTool.ToolTip = "Swing to Stun Bosses or Knock Rival Egg Carriers!"
		batTool.RequiresHandle = true

		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.75, 4.4, 0.75)
		handle.Color = Color3.fromRGB(185, 125, 68)
		handle.Material = Enum.Material.Wood
		handle.CanCollide = false
		handle.Parent = batTool

		local gripTape = Instance.new("Part")
		gripTape.Name = "GripTape"
		gripTape.Size = Vector3.new(0.82, 1.3, 0.82)
		gripTape.Color = Color3.fromRGB(235, 65, 75)
		gripTape.Material = Enum.Material.SmoothPlastic
		gripTape.CanCollide = false
		gripTape.CFrame = handle.CFrame * CFrame.new(0, -1.2, 0)
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

	-- 2. Bear Trap Tool (Deploys a 3D Bear Trap on the ground that snares chasing Bosses!)
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
			trapTool.ToolTip = "Place a Bear Trap on the floor to Snare Chasing Bosses!"
			trapTool.RequiresHandle = true
			trapTool:SetAttribute("IsBearTrap", true)

			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Shape = Enum.PartType.Cylinder
			handle.Size = Vector3.new(0.6, 2.8, 2.8)
			handle.Orientation = Vector3.new(0, 0, 90)
			handle.Color = Color3.fromRGB(75, 80, 95)
			handle.Material = Enum.Material.Metal
			handle.CanCollide = false
			handle.Parent = trapTool

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
				trapPart.Shape = Enum.PartType.Cylinder
				trapPart.Size = Vector3.new(0.8, 5.5, 5.5)
				trapPart.CFrame = CFrame.new(hrp.Position.X, 0.45, hrp.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
				trapPart.Color = Color3.fromRGB(55, 60, 72)
				trapPart.Material = Enum.Material.Metal
				trapPart.Anchored = true
				trapPart.CanCollide = false
				trapPart:SetAttribute("OwnerUserId", player.UserId)
				trapPart:SetAttribute("ActiveTrap", true)
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

	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("SquishyId") then
			child:Destroy()
		end
	end

	local char = player.Character
	local equippedSquishyId: string? = nil
	if char then
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Tool") and child:GetAttribute("SquishyId") then
				local sId = child:GetAttribute("SquishyId") :: string
				if (session.BackpackCounts[sId] or 0) <= 0 then
					child:Destroy()
				else
					local sData = SlimeData.ById[sId]
					if sData then
						local count = session.BackpackCounts[sId]
						child.Name = if count > 1 then string.format("%s (x%d)", sData.Name, count) else sData.Name
					end
					equippedSquishyId = sId
				end
			end
		end
	end

	for sId, count in pairs(session.BackpackCounts) do
		if count > 0 and sId ~= equippedSquishyId then
			local sData = SlimeData.ById[sId]
			if sData then
				local tool = SquishyBuilder.CreateSquishyBackpackTool(sData, 1)
				tool.Name = if count > 1 then string.format("%s (x%d)", sData.Name, count) else sData.Name
				tool.ToolTip = string.format("%s ($%d/s) - Click or Press E on a Base Pedestal to Place!", sData.Rarity, sData.IncomePerSec)
				tool:SetAttribute("SquishyId", sId)

				tool.Equipped:Connect(function()
					session.EquippedId = sId
					syncPlayer(player)
				end)
				tool.Unequipped:Connect(function()
					if session.EquippedId == sId then
						session.EquippedId = nil
						syncPlayer(player)
					end
				end)

				tool.Parent = backpack
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
	local stand = plotModel:FindFirstChild("SpeedUpgradeStand")
	local prompt = stand and stand:FindFirstChild("UpgradeSpeedPrompt", true) :: ProximityPrompt?
	if prompt then
		local cost = math.floor(50 * math.pow(1.45, session.SpeedLevel - 1))
		local gain = if session.OwnedPasses and session.OwnedPasses["2xSpeed"] then 8 else 4
		prompt.ActionText = string.format("Upgrade Treadmill (+%d Speed) [Lv.%d]", gain, session.SpeedLevel)
		prompt.ObjectText = string.format("🦖 Cost: $%d (Current Speed: %d)", cost, math.floor(session.SpeedStat))
	end
end

-- Spawns or updates a Hatched Squishy on a Player's Base Pedestal
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
	local pedPart = pedestalsFolder and pedestalsFolder:FindFirstChild("Pedestal_" .. tostring(slotIdx)) :: BasePart?
	if not pedPart then
		return
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

	local model = SquishyBuilder.CreateHatchedSquishy(sData, pedState.Level)
	model:PivotTo(CFrame.new(pedPart.Position + Vector3.new(0, 1.8, 0)))
	model.Parent = pedPart
	pedState.VisualModel = model

	local upgradeCost = SlimeData.GetSquishyUpgradeCost(sData, pedState.Level)
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("PedestalUpgradePrompt", true) :: ProximityPrompt?
	if prompt then
		prompt.ActionText = string.format("Level Up -> Lv.%d ($%d)", pedState.Level + 1, upgradeCost)
		prompt.ObjectText = string.format("%s [Lv.%d]", sData.Name, pedState.Level)
		prompt.Triggered:Connect(function(triggerPlayer: Player)
			if triggerPlayer ~= player then
				return
			end
			if session.Coins < upgradeCost then
				GuardianAlertEvent:FireClient(player, string.format("Need $%d to upgrade %s to Lv.%d!", upgradeCost, sData.Name, pedState.Level + 1))
				return
			end
			session.Coins -= upgradeCost
			pedState.Level += 1
			recalculateIncome(session)
			refreshPedestalVisual(player, slotIdx)
			updatePlotOwnerSign(session.PlotIndex, player.DisplayName, session.PassiveIncomeRate, session.UncollectedPlotCash)
			syncPlayer(player)
		end)
	end
end

local function ensurePlacePromptOnPedestal(pedPart: BasePart, plotIdx: number, slotIdx: number)
	local prompt = pedPart:FindFirstChild("PlaceSquishyPrompt", true) :: ProximityPrompt?
	if not prompt then
		local att = Instance.new("Attachment")
		att.Name = "PlaceSquishyPrompt_Attachment"
		att.Position = Vector3.new(0, 2.2, 0)
		att.Parent = pedPart

		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PlaceSquishyPrompt"
		prompt.ActionText = "Place Squishy on Pedestal"
		prompt.ObjectText = "Pedestal #" .. tostring(slotIdx)
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		prompt.Parent = att
	end

	if prompt:GetAttribute("BoundServer") then
		return
	end
	prompt:SetAttribute("BoundServer", true)

	prompt.Triggered:Connect(function(player: Player)
		local session = sessions[player]
		if not session or session.PlotIndex ~= plotIdx then
			GuardianAlertEvent:FireClient(player, "This is not your Base Plot!")
			return
		end
		if session.Pedestals[slotIdx] ~= nil then
			return
		end

		local chosenId: string? = session.EquippedId
		if not chosenId or (session.BackpackCounts[chosenId] or 0) <= 0 then
			local bestInc = -1
			for sId, count in pairs(session.BackpackCounts) do
				if count > 0 then
					local d = SlimeData.ById[sId]
					if d and d.IncomePerSec > bestInc then
						bestInc = d.IncomePerSec
						chosenId = sId
					end
				end
			end
		end

		if not chosenId or (session.BackpackCounts[chosenId] or 0) <= 0 then
			GuardianAlertEvent:FireClient(player, "Hatch a stolen Egg in your Incubator first, then place the Squishy here!")
			return
		end

		session.BackpackCounts[chosenId] -= 1
		if session.BackpackCounts[chosenId] <= 0 then
			session.BackpackCounts[chosenId] = nil
		end

		prompt.Enabled = false
		session.Pedestals[slotIdx] = {
			SquishyId = chosenId,
			Level = 1,
			VisualModel = nil :: any,
		}
		refreshPedestalVisual(player, slotIdx)
		refreshBackpackTools(player)
		recalculateIncome(session)
		updatePlotOwnerSign(plotIdx, player.DisplayName, session.PassiveIncomeRate, session.UncollectedPlotCash)
		syncPlayer(player)
	end)
end

-- Connects all 4 Base Plots (Incubators, Pedestals, Cash Collector, Treadmill Upgrade)
for plotIdx = 1, 4 do
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
				local cost = math.floor(50 * math.pow(1.45, session.SpeedLevel - 1))
				if session.Coins < cost then
					GuardianAlertEvent:FireClient(player, string.format("Need $%d Cash to upgrade Treadmill!", cost))
					return
				end
				session.Coins -= cost
				session.SpeedLevel += 1
				local mult = if session.OwnedPasses and session.OwnedPasses["2xSpeed"] then 2 else 1
				session.SpeedStat += (4 * mult)
				applyPlayerSpeed(player)
				updateSpeedUpgradePrompt(player)
				syncPlayer(player)
			end)
		end

		local incubatorsFolder = plotModel:FindFirstChild("Incubators")
		if incubatorsFolder then
			for incIdx = 1, 5 do
				local incPad = incubatorsFolder:FindFirstChild("Incubator_" .. tostring(incIdx)) :: BasePart?
				local prompt = incPad and incPad:FindFirstChild("IncubatorPrompt", true) :: ProximityPrompt?
				local bb = incPad and incPad:FindFirstChildOfClass("BillboardGui")
				local bbLabel = bb and bb:FindFirstChildOfClass("TextLabel")

				if incPad and prompt then
					prompt.Triggered:Connect(function(player: Player)
						local session = sessions[player]
						if not session or session.PlotIndex ~= plotIdx then
							GuardianAlertEvent:FireClient(player, "Use the Incubators on your own Base Plot!")
							return
						end

						local incState = session.Incubators[incIdx]
						if not incState then
							return
						end

						-- CASE 1: Incubator is Empty -> Plant the Stolen Egg!
						if not incState.EggId then
							if #session.CarriedEggIds == 0 then
								GuardianAlertEvent:FireClient(player, "Steal an Egg from a Biome first, then plant it here!")
								return
							end

							local plantedEggId = popOneCarriedEgg(player)
							local eggData = if plantedEggId then SlimeData.ById[plantedEggId] else nil
							if not plantedEggId or not eggData then
								return
							end

							-- Now that the stolen egg was safely planted at Base, respawn a fresh egg back at its Boss Nest!
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
								else math.clamp(3 + eggData.Level, 4, 8)
							local plantedVisual = SquishyBuilder.CreatePlantedEgg(eggData, hatchDuration)
							plantedVisual:PivotTo(CFrame.new(incPad.Position + Vector3.new(0, 2.2, 0)))
							plantedVisual.Parent = incPad

							incState.EggId = plantedEggId
							incState.ReadyAt = os.clock() + hatchDuration
							incState.IsReady = false
							incState.VisualModel = plantedVisual

							prompt.Enabled = false
							if bbLabel then
								bbLabel.Text = string.format("⏳ HATCHING %s...", string.upper(eggData.Name))
							end
							syncPlayer(player)

							-- Countdown timer loop ("00:05" -> "READY!")
							task.spawn(function()
								while incState.EggId == plantedEggId and not incState.IsReady do
									local rem = math.ceil((incState.ReadyAt or 0) - os.clock())
									local tLbl = plantedVisual:FindFirstChild("TimerLabel", true) :: TextLabel?
									if rem <= 0 then
										incState.IsReady = true
										if tLbl then
											tLbl.Text = "✨ READY!"
											tLbl.TextColor3 = Color3.fromRGB(95, 255, 130)
										end
										if bbLabel then
											bbLabel.Text = string.format("✨ %s HATCHED!\n[PRESS E TO PICK UP]", string.upper(eggData.Name))
										end
										prompt.ActionText = "Pick Up Hatched Squishy"
										prompt.ObjectText = string.format("%s ($%d/s)", eggData.Name, eggData.IncomePerSec)
										prompt.Enabled = true
										break
									else
										if tLbl then
											tLbl.Text = string.format("00:%02d", rem)
										end
									end
									task.wait(0.25)
								end
							end)

						-- CASE 2: Incubator Finished Hatching -> Pick Up the Squishy into Hotbar!
						elseif incState.IsReady and incState.EggId then
							local hatchedId = incState.EggId
							local sData = SlimeData.ById[hatchedId]
							if incState.VisualModel then
								incState.VisualModel:Destroy()
								incState.VisualModel = nil
							end
							incState.EggId = nil
							incState.ReadyAt = nil
							incState.IsReady = false

							prompt.ActionText = "Plant Carried Egg"
							prompt.ObjectText = "Empty Incubator #" .. tostring(incIdx)
							if bbLabel then
								bbLabel.Text = "🥚 INCUBATOR #" .. tostring(incIdx) .. "\n[EMPTY]"
							end

							if sData then
								local isFirst = not session.FoundEggs[hatchedId]
								session.FoundEggs[hatchedId] = true
								session.BackpackCounts[hatchedId] = (session.BackpackCounts[hatchedId] or 0) + 1
								session.Coins += sData.CoinReward
								session.LifetimeCoins += sData.CoinReward

								refreshBackpackTools(player)
								EggCapturedEvent:FireClient(player, {
									SquishyId = hatchedId,
									IsFirstDiscovery = isFirst,
									CoinsEarned = sData.CoinReward,
								})
								syncPlayer(player)
							end
						end
					end)
				end
			end
		end

		local pedestalsFolder = plotModel:FindFirstChild("Pedestals")
		if pedestalsFolder then
			for slotIdx = 1, 12 do
				local pedPart = pedestalsFolder:FindFirstChild("Pedestal_" .. tostring(slotIdx)) :: BasePart?
				if pedPart then
					ensurePlacePromptOnPedestal(pedPart, plotIdx, slotIdx)
				end
			end
		end
	end
end

-- Connect Prompts on all 117 World Items (35 Boss Nest Eggs + 82 Shining Collectible Squishies!)
for eggId, eggModel in pairs(world.WorldEggs) do
	local slimeData = SlimeData.ById[eggId]
	local prompt = eggModel:FindFirstChild("CapturePrompt", true) :: ProximityPrompt?
	if prompt and slimeData then
		prompt.Triggered:Connect(function(player: Player)
			local session = sessions[player]
			if not session then
				return
			end
			if eggTakenByPlayer[eggId] ~= nil then
				return
			end

			local isShining = (slimeData :: any).IsShiningSquishy == true or eggModel:GetAttribute("IsShiningSquishy") == true

			-- CASE A: SHINING COLLECTIBLE SQUISHY (#36-#117 on Rooftops, Rainbow Staircase, Outer Mazes, Castle Walls & Obbies)
			-- Instant grab into the player's Squishy Index (X / 117) & Backpack Hotbar!
			if isShining then
				eggTakenByPlayer[eggId] = player
				setWorldEggTaken(eggId, true, false)

				local isFirst = not session.FoundEggs[eggId]
				session.FoundEggs[eggId] = true
				session.BackpackCounts[eggId] = (session.BackpackCounts[eggId] or 0) + 1
				session.Coins += slimeData.CoinReward
				session.LifetimeCoins += slimeData.CoinReward

				refreshBackpackTools(player)
				EggCapturedEvent:FireClient(player, {
					SquishyId = eggId,
					IsFirstDiscovery = isFirst,
					CoinsEarned = slimeData.CoinReward,
				})
				GuardianAlertEvent:FireClient(
					player,
					string.format("✨ Grabbed Shining %s! (+$%d Cash, Found %d/117!)", slimeData.Name, slimeData.CoinReward, SlimeData.CountFound(session.FoundEggs))
				)
				syncPlayer(player)

				-- Respawn the Shining Squishy after 18 seconds so others can grab it too
				task.delay(18, function()
					eggTakenByPlayer[eggId] = nil
					setWorldEggTaken(eggId, false, false)
				end)
				return
			end

			-- CASE B: BOSS NEST EGG (#1-#35) -> Steal, Carry (up to 2 with +2 Carry Capacity!), Drop-in-Place if Hit, and Hatch at Base Incubator!
			local maxCarry = if session.OwnedPasses and session.OwnedPasses["Carry2Eggs"] then 2 else 1
			if #session.CarriedEggIds >= maxCarry then
				if maxCarry == 1 then
					GuardianAlertEvent:FireClient(player, "Carrying 1/1 Egg! Plant it at Base or unlock 🎒 +2 Carry Capacity in the Shop!")
				else
					GuardianAlertEvent:FireClient(player, "Carrying 2/2 Boss Eggs! Plant them in your Base Incubators first!")
				end
				return
			end

			local levelInfo = SlimeData.Levels[slimeData.Level]
			local reqSpd = if levelInfo then (levelInfo.RequiredSpeed or 16) else 16
			if session.SpeedStat < reqSpd and session.LifetimeCoins < (if levelInfo then levelInfo.RequiredCoins else 0) then
				GuardianAlertEvent:FireClient(player, string.format("Need %d Speed to steal Stage %d Eggs!", reqSpd, slimeData.Level))
				return
			end

			eggTakenByPlayer[eggId] = player
			setWorldEggTaken(eggId, true, false)
			attachCarriedEggToPlayer(player, slimeData)
			syncPlayer(player)
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
				-- Chapter 1 & 4 Touch Debounce Mechanic for Respawning Golden Squishy Coins (math.random cash + sound effect)!
				desc.CanTouch = true
				local coinBusy = false
				desc.Touched:Connect(function(hit: BasePart)
					if coinBusy then
						return
					end
					local char = hit.Parent
					local player = if char then Players:GetPlayerFromCharacter(char) else nil
					local session = if player then sessions[player] else nil
					if not player or not session then
						return
					end
					coinBusy = true
					desc.Transparency = 1.0
					local sound = desc:FindFirstChild("CoinChime") :: Sound?
					if sound then
						sound:Play()
					end
					local minVal = (desc:GetAttribute("MinCoinValue") :: number?) or (desc:GetAttribute("CoinValue") :: number?) or 80
					local maxVal = (desc:GetAttribute("MaxCoinValue") :: number?) or (minVal * 2)
					local baseVal = math.random(minVal, math.max(minVal, maxVal))
					local mult = if session.OwnedPasses and session.OwnedPasses["2xCash"] then 2 else 1
					local earned = baseVal * mult
					session.Coins += earned
					session.LifetimeCoins += earned
					GuardianAlertEvent:FireClient(player, string.format("🪙 Grabbed Golden Squishy Coin! +$%d Bonus Cash!", earned))
					syncPlayer(player)
					task.delay(14, function()
						if desc.Parent then
							desc.Transparency = 0
						end
						coinBusy = false
					end)
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
			elseif desc.Name == "BouncePad" then
				desc.CanTouch = true
				desc.Touched:Connect(function(hit: BasePart)
					local char = hit.Parent
					if not char then
						return
					end
					local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						local impulse = (desc:GetAttribute("BounceImpulse") :: number?) or 95
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

					local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						if sessions[player] and sessions[player].CarriedEggId then
							dropCarriedEggAtSpot(player, hrp.Position, "💥 Hit Obstacle")
						end
						local knock = (desc:GetAttribute("KnockbackImpulse") :: number?) or 60
						hrp.AssemblyLinearVelocity = Vector3.new(0, 42, knock)
					end
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
			if session and hrp then
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
					math.clamp(root.Position.X + step.X, -54, 54),
					gData.Center.Y + math.abs(math.sin(elapsed * 7)) * 1.4,
					math.clamp(root.Position.Z + step.Z, levelInfo.ZEnd + 8, levelInfo.ZStart - 8)
				)
				gModel:PivotTo(CFrame.lookAt(newPos, Vector3.new(targetHrp.Position.X, newPos.Y, targetHrp.Position.Z)))
			end

			-- Catch Check: Drop carried egg AT THAT EXACT SPOT (do NOT reset egg to nest!)
			if dist <= 7.2 and (guardianCatchCooldowns[targetPlayer] or 0) < now then
				guardianCatchCooldowns[targetPlayer] = now + 1.8
				local hitSpot = targetHrp.Position
				if sessions[targetPlayer] and sessions[targetPlayer].CarriedEggId then
					dropCarriedEggAtSpot(targetPlayer, hitSpot, "🚨 Caught by " .. gData.Name)
				else
					GuardianAlertEvent:FireClient(targetPlayer, "🚨 Bumped by " .. gData.Name .. "! Watch out!")
				end
				targetHrp.AssemblyLinearVelocity = Vector3.new(0, 42, 65)
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

	-- 3. Check Player Treadmill Running & Cash Collector Pad
	for _, player in ipairs(Players:GetPlayers()) do
		local session = sessions[player]
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not session or not hrp or not hum then
			continue
		end

		local plotModel = getPlotModel(session.PlotIndex)
		if not plotModel then
			continue
		end

		-- Check if on Dino Treadmill Belt
		local belt = plotModel:FindFirstChild("TreadmillBelt_" .. tostring(session.PlotIndex)) :: BasePart?
		if belt then
			local rel = belt.CFrame:PointToObjectSpace(hrp.Position)
			if math.abs(rel.X) <= (belt.Size.X * 0.5 + 1.5) and math.abs(rel.Z) <= (belt.Size.Z * 0.5 + 1.5) and math.abs(hrp.Position.Y - belt.Position.Y) <= 6.5 then
				if now - session.LastTreadmillStep >= 0.55 then
					session.LastTreadmillStep = now
					local mult = if session.OwnedPasses and session.OwnedPasses["2xSpeed"] then 2 else 1
					local gain = (1 + session.Rebirths) * mult
					session.SpeedStat += gain
					applyPlayerSpeed(player)
					updateSpeedUpgradePrompt(player)
					syncPlayer(player)
				end
			end
		end

		-- Check if stepping on Green Cash Collector Pad
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
BuySpeedUpgradeEvent.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local cost = math.floor(50 * math.pow(1.45, session.SpeedLevel - 1))
	if session.Coins < cost then
		GuardianAlertEvent:FireClient(player, string.format("Need $%d Cash to upgrade Speed!", cost))
		return
	end
	session.Coins -= cost
	session.SpeedLevel += 1
	local mult = if session.OwnedPasses and session.OwnedPasses["2xSpeed"] then 2 else 1
	session.SpeedStat += (4 * mult)
	applyPlayerSpeed(player)
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
		GuardianAlertEvent:FireClient(player, string.format("Need $%d Cash to Rebirth!", cost))
		return
	end
	session.Coins = 0
	session.Rebirths += 1
	session.SpeedStat = 18 + (session.Rebirths * 4)
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

-- Daily Login Streak Chest Handler
ClaimDailyRewardEvent.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local now = os.clock()
	if session.LastDailyClaim > 0 and (now - session.LastDailyClaim) < 15 then
		GuardianAlertEvent:FireClient(player, "Daily Streak Chest claimed recently! Check your Playtime Milestones too!")
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
		local mythicSlime = SlimeData.Slimes[#SlimeData.Slimes]
		if mythicSlime then
			local sId = tostring(mythicSlime.Id)
			session.FoundEggs[sId] = true
			session.BackpackCounts[sId] = (session.BackpackCounts[sId] or 0) + 1
			refreshBackpackTools(player)
		end
	end

	GuardianAlertEvent:FireClient(
		player,
		string.format("🎁 Claimed %s Playtime Reward! (+$%d Cash%s)", ms.Key, cashWon, if ms.Mythic then " + MYTHIC SQUISHY!" else "")
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
		local randSlime = SlimeData.Slimes[math.random(36, #SlimeData.Slimes)]
		if randSlime then
			local sId = tostring(randSlime.Id)
			session.FoundEggs[sId] = true
			session.BackpackCounts[sId] = (session.BackpackCounts[sId] or 0) + 1
			refreshBackpackTools(player)
			GuardianAlertEvent:FireClient(player, string.format("🎡 JACKPOT! Won Shining %s ($%d/s)!", randSlime.Name, randSlime.IncomePerSec))
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
	session.BonusSpins = (session.BonusSpins or 0) + 1
	executeWheelSpin(player)
end)

-- =========================================================================
-- MarketplaceService Gamepasses (PromptGamePassPurchase) & Developer Products (PromptProductPurchase + ProcessReceipt)
-- =========================================================================
local MarketplaceService = game:GetService("MarketplaceService")

local GAMEPASS_IDS: { [string]: number } = {
	["2xCash"] = 0,
	["2xSpeed"] = 0,
	["AutoHatch"] = 0,
	["VIP"] = 0,
	["Carry2Eggs"] = 0,
}

local DEVPRODUCT_IDS: { [string]: number } = {
	["InstantHatchAll"] = 0,
	["BossShield60s"] = 0,
	["CashPack5K"] = 0,
	["CashPack25K"] = 0,
	["CashPack100K"] = 0,
	["BuySpinRobux"] = 0,
}

local function grantGamePassReward(player: Player, passKey: string)
	local session = sessions[player]
	if not session then
		return
	end
	session.OwnedPasses[passKey] = true
	if passKey == "2xCash" then
		recalculateIncome(session)
		updatePlotOwnerSign(session.PlotIndex, player.DisplayName, session.PassiveIncomeRate, session.UncollectedPlotCash)
		GuardianAlertEvent:FireClient(player, "💰 Unlocked 2x CASH FOREVER Gamepass! All Cash & Pedestal Income Doubled!")
	elseif passKey == "2xSpeed" then
		session.SpeedStat += 16
		applyPlayerSpeed(player)
		updateSpeedUpgradePrompt(player)
		GuardianAlertEvent:FireClient(player, "⚡ Unlocked 2x TREADMILL SPEED FOREVER! +16 Speed & 2x Treadmill Gains!")
	elseif passKey == "AutoHatch" then
		GuardianAlertEvent:FireClient(player, "🥚 Unlocked FAST HATCH (1s Incubators)! All Eggs Hatch in 1 Second!")
	elseif passKey == "VIP" then
		session.Coins += 10000
		session.LifetimeCoins += 10000
		session.SpeedStat += 25
		recalculateIncome(session)
		applyPlayerSpeed(player)
		attachVIPRainbowTrail(player)
		GuardianAlertEvent:FireClient(player, "👑 Unlocked VIP CROWN + GOLDEN TRAIL + +50% CASH (+10K Cash & +25 Speed)!")
	elseif passKey == "Carry2Eggs" then
		GuardianAlertEvent:FireClient(player, "🎒 Unlocked +2 CARRY CAPACITY! You can now steal & carry 2 Boss Eggs at once!")
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
		GuardianAlertEvent:FireClient(player, "⚡ HATCH ALL INCUBATORS NOW: All planted eggs hatched instantly!")
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
	else
		return false
	end
	syncPlayer(player)
	return true
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end
	for passKey, configuredId in pairs(GAMEPASS_IDS) do
		if configuredId > 0 and configuredId == gamePassId then
			grantGamePassReward(player, passKey)
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
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

BuyRobuxItemEvent.OnServerEvent:Connect(function(player: Player, itemKey: any)
	local session = sessions[player]
	if not session or type(itemKey) ~= "string" then
		return
	end
	pcall(function()
		if GAMEPASS_IDS[itemKey] ~= nil then
			local passId = GAMEPASS_IDS[itemKey]
			if passId > 0 and not RunService:IsStudio() then
				MarketplaceService:PromptGamePassPurchase(player, passId)
			else
				grantGamePassReward(player, itemKey)
			end
		elseif DEVPRODUCT_IDS[itemKey] ~= nil then
			local prodId = DEVPRODUCT_IDS[itemKey]
			if prodId > 0 and not RunService:IsStudio() then
				MarketplaceService:PromptProductPurchase(player, prodId)
			else
				grantDeveloperProductReward(player, itemKey)
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
		playerDataStore = DataStoreService:GetDataStore("StealMyEgg_117_v1")
		coinsODS = DataStoreService:GetOrderedDataStore("StealMyEgg_GlobalCoins_v1")
		speedODS = DataStoreService:GetOrderedDataStore("StealMyEgg_GlobalSpeed_v1")
		squishiesODS = DataStoreService:GetOrderedDataStore("StealMyEgg_GlobalSquishies_v1")
	end)
end

function savePlayerData(player: Player)
	local session = sessions[player]
	if not session or game.GameId == 0 then
		return
	end
	if playerDataStore then
		local payload = {
			Coins = session.Coins,
			LifetimeCoins = session.LifetimeCoins,
			SpeedStat = session.SpeedStat,
			SpeedLevel = session.SpeedLevel,
			Rebirths = session.Rebirths,
			DailyStreak = session.DailyStreak,
			OwnedPasses = session.OwnedPasses,
			FoundEggs = session.FoundEggs,
			BackpackCounts = session.BackpackCounts,
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
	{ Name = "SquishyKing99", Coins = 48500, Speed = 145, Squishies = 114 },
	{ Name = "RainbowRunner", Coins = 32400, Speed = 128, Squishies = 98 },
	{ Name = "DinoTreadmillPro", Coins = 24900, Speed = 112, Squishies = 86 },
	{ Name = "CandyThiefX", Coins = 18200, Speed = 96, Squishies = 74 },
	{ Name = "VolcanoLegend", Coins = 12600, Speed = 84, Squishies = 62 },
	{ Name = "TikiExplorer", Coins = 8400, Speed = 68, Squishies = 49 },
	{ Name = "CrystalHunter", Coins = 5200, Speed = 52, Squishies = 35 },
	{ Name = "MeadowScout", Coins = 2400, Speed = 36, Squishies = 22 },
	{ Name = "RookieHatch", Coins = 950, Speed = 24, Squishies = 11 },
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
					entriesByName[keyName] = { Name = keyName, Coins = 0, Speed = 18, Squishies = 0 }
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
									then string.format("💰 $%d", item.Coins)
									elseif statKey == "Speed" then string.format("⚡ %d Spd", item.Speed)
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
	local assignedPlot = 1
	for idx = 1, 4 do
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

	sessions[player] = {
		Coins = if loadedData and type(loadedData.Coins) == "number" then loadedData.Coins else 100,
		LifetimeCoins = if loadedData and type(loadedData.LifetimeCoins) == "number" then loadedData.LifetimeCoins else 100,
		SpeedStat = if loadedData and type(loadedData.SpeedStat) == "number" then loadedData.SpeedStat else 18,
		SpeedLevel = if loadedData and type(loadedData.SpeedLevel) == "number" then loadedData.SpeedLevel else 1,
		Rebirths = if loadedData and type(loadedData.Rebirths) == "number" then loadedData.Rebirths else 0,
		DailyStreak = if loadedData and type(loadedData.DailyStreak) == "number" then loadedData.DailyStreak else 0,
		LastDailyClaim = 0,
		LastWheelSpin = 0,
		NextFreeSpinAt = 0,
		BonusSpins = 1,
		SessionStartTime = os.clock(),
		ClaimedPlaytime = {},
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

	updatePlotOwnerSign(assignedPlot, player.DisplayName, 0, 0)
	updateSpeedUpgradePrompt(player)
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
			if sessions[player] and sessions[player].OwnedPasses["VIP"] then
				attachVIPRainbowTrail(player)
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
					pr.Enabled = true
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
					pr.Enabled = true
				end
			end
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


