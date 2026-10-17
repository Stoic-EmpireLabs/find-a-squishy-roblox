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
local ToggleSloMoEvent = ensureRemoteEvent("ToggleSloMo")
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
	SloMoActive: boolean,
	PlotIndex: number,
	CarriedEggId: string?,
	CarriedEggVisual: Model?,
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
			local levelMult = math.pow(1.35, pedState.Level - 1)
			total += math.floor(sData.IncomePerSec * levelMult)
		end
	end
	local rebirthMult = 1 + (session.Rebirths * 0.5)
	session.PassiveIncomeRate = math.floor(total * rebirthMult)
	return session.PassiveIncomeRate
end

local function serializeSession(player: Player)
	local session = sessions[player]
	if not session then
		return nil
	end

	local unlockedLevels = {}
	for _, lvl in ipairs(SlimeData.Levels) do
		local reqSpd = lvl.RequiredSpeed or 16
		unlockedLevels[tostring(lvl.Id)] = (session.SpeedStat >= reqSpd) or (session.LifetimeCoins >= lvl.RequiredCoins)
	end

	local nextSpeedCost = math.floor(50 * math.pow(1.45, session.SpeedLevel - 1))
	local nextRebirthCost = math.floor(5000 * math.pow(3.0, session.Rebirths))

	return {
		Coins = session.Coins,
		LifetimeCoins = session.LifetimeCoins,
		SpeedStat = math.floor(session.SpeedStat),
		SpeedLevel = session.SpeedLevel,
		NextSpeedCost = nextSpeedCost,
		Rebirths = session.Rebirths,
		NextRebirthCost = nextRebirthCost,
		DailyStreak = session.DailyStreak,
		SloMoActive = session.SloMoActive,
		PlotIndex = session.PlotIndex,
		CarriedEggId = session.CarriedEggId,
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
			local cashVal = ls:FindFirstChild("Cash") :: IntValue?
			if cashVal then
				cashVal.Value = session.Coins
			end
			local speedVal = ls:FindFirstChild("Speed") :: IntValue?
			if speedVal then
				speedVal.Value = math.floor(session.SpeedStat)
			end
			local eggsVal = ls:FindFirstChild("Eggs") :: IntValue?
			if eggsVal then
				eggsVal.Value = SlimeData.CountFound(session.FoundEggs)
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
			elseif desc.Name == "BirdNest" or desc.Name == "NestRim" then
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
	applyPlayerSpeed(player)
end

-- EXACT DROP-IN-PLACE MECHANIC:
-- When a player carrying an egg is hit by a Boss, Hazard Moat, Sweeper Bar, or Bat,
-- the egg STOPS and DROPS right at that exact spot (never resets to the nest)!
local function dropCarriedEggAtSpot(player: Player, hitPosition: Vector3, reasonText: string)
	local session = sessions[player]
	if not session or not session.CarriedEggId then
		return
	end

	local droppedEggId = session.CarriedEggId
	local eggData = SlimeData.ById[droppedEggId]
	clearCarriedEgg(player)

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
			bb.Size = UDim2.fromOffset(230, 48)
			bb.StudsOffset = Vector3.new(0, 6.2, 0)
			bb.AlwaysOnTop = true
			bb.MaxDistance = 120
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
	clearCarriedEgg(player)

	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local carriedModel = SquishyBuilder.CreateCarriedEgg(slimeData)
	carriedModel.Parent = char

	local root = carriedModel.PrimaryPart
	if root then
		root.CFrame = hrp.CFrame * CFrame.new(0, 2.2, -3.2)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = root
		weld.Parent = root
	end

	session.CarriedEggId = slimeData.Id
	session.CarriedEggVisual = carriedModel
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
				local tool = Instance.new("Tool")
				tool.Name = if count > 1 then string.format("%s (x%d)", sData.Name, count) else sData.Name
				tool.ToolTip = string.format("%s ($%d/s) - Walk to your Base Pedestal to Place!", sData.Rarity, sData.IncomePerSec)
				tool.RequiresHandle = true
				tool:SetAttribute("SquishyId", sId)

				local handle = Instance.new("Part")
				handle.Name = "Handle"
				handle.Shape = Enum.PartType.Ball
				handle.Size = Vector3.new(2.2, 2.2, 2.2)
				handle.Color = sData.BodyColor
				handle.Material = Enum.Material.SmoothPlastic
				handle.CanCollide = false
				handle.Massless = true
				handle.Parent = tool

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
		local bb = signPart:FindFirstChildOfClass("BillboardGui")
		local lbl = bb and bb:FindFirstChildOfClass("TextLabel")
		if lbl then
			lbl.Text = string.format("🏡 %s'S EGG RANCH\n⚡ $%d / sec", string.upper(ownerName), incomeRate)
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
	local prompt = stand and stand:FindFirstChild("UpgradeSpeedPrompt") :: ProximityPrompt?
	if prompt then
		local cost = math.floor(50 * math.pow(1.45, session.SpeedLevel - 1))
		prompt.ActionText = string.format("Upgrade Treadmill (+4 Speed) [Lv.%d]", session.SpeedLevel)
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

	local upgradeCost = math.floor(sData.CoinReward * 1.5 * math.pow(1.45, pedState.Level - 1))
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("PedestalUpgradePrompt") :: ProximityPrompt?
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
	local existing = pedPart:FindFirstChild("PlaceSquishyPrompt")
	if existing then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlaceSquishyPrompt"
	prompt.ActionText = "Place Squishy on Pedestal"
	prompt.ObjectText = "Pedestal #" .. tostring(slotIdx)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pedPart

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
		local upgPrompt = stand and stand:FindFirstChild("UpgradeSpeedPrompt") :: ProximityPrompt?
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
				session.SpeedStat += 4
				applyPlayerSpeed(player)
				updateSpeedUpgradePrompt(player)
				syncPlayer(player)
			end)
		end

		local incubatorsFolder = plotModel:FindFirstChild("Incubators")
		if incubatorsFolder then
			for incIdx = 1, 5 do
				local incPad = incubatorsFolder:FindFirstChild("Incubator_" .. tostring(incIdx)) :: BasePart?
				local prompt = incPad and incPad:FindFirstChild("IncubatorPrompt") :: ProximityPrompt?
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
							if not session.CarriedEggId then
								GuardianAlertEvent:FireClient(player, "Steal an Egg from a Biome first, then plant it here!")
								return
							end

							local plantedEggId = session.CarriedEggId
							local eggData = SlimeData.ById[plantedEggId]
							if not eggData then
								return
							end

							clearCarriedEgg(player)

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

							local hatchDuration = math.clamp(3 + eggData.Level, 4, 8)
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

-- Connect Steal Prompts on all 35 World Eggs
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
			if session.CarriedEggId then
				GuardianAlertEvent:FireClient(player, "You are already carrying an Egg! Plant it in your Base Incubator first!")
				return
			end

			local levelInfo = SlimeData.Levels[slimeData.Level]
			local reqSpd = if levelInfo then (levelInfo.RequiredSpeed or 16) else 16
			if session.SpeedStat < reqSpd and session.LifetimeCoins < (if levelInfo then levelInfo.RequiredCoins else 0) then
				GuardianAlertEvent:FireClient(player, string.format("Need %d Speed to steal Stage %d Eggs!", reqSpd, slimeData.Level))
				return
			end

			-- Steal the Egg! Hide the world egg at its current spot; if the player gets hit, it will drop at their hit spot!
			eggTakenByPlayer[eggId] = player
			setWorldEggTaken(eggId, true, false)
			attachCarriedEggToPlayer(player, slimeData)
			syncPlayer(player)
		end)
	end
end

-- Connect Hazard Moats, Spinning Sweepers & Super Bounce Pads
local function bindBiomeObstacles()
	for _, desc in ipairs(world.WorldFolder:GetDescendants()) do
		if desc:IsA("BasePart") then
			if desc.Name == "BouncePad" then
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
						-- Drop the carried egg right where the player got hit!
						if sessions[player] and sessions[player].CarriedEggId then
							dropCarriedEggAtSpot(player, hrp.Position, "💥 Hit Obstacle")
						end
						local knock = (desc:GetAttribute("KnockbackImpulse") :: number?) or 60
						hrp.AssemblyLinearVelocity = Vector3.new(0, 42, knock)
					end
				end)
			end
		end
	end
end
bindBiomeObstacles()

-- Main Heartbeat Loop:
-- 1. Sleeping Boss AI ("Zzz" asleep -> "!!" wakes & chases egg thief -> drops egg at exact hit spot!)
-- 2. Deployed Bear Traps snaring Bosses
-- 3. Dino-Jaw Speed Treadmill training (+1 Speed per 0.55s while running on the pink belt!)
-- 4. Cash Collector Pad step check
local startClock = os.clock()
RunService.Heartbeat:Connect(function(dt: number)
	local now = os.clock()
	local elapsed = now - startClock

	-- 1. Spin Sweeper Bars
	local obsFolder = world.WorldFolder:FindFirstChild("DynamicObstacles")
	if obsFolder then
		for _, child in ipairs(obsFolder:GetChildren()) do
			if child:IsA("BasePart") and child:GetAttribute("SpinSpeed") then
				local spd = child:GetAttribute("SpinSpeed") :: number
				child.CFrame = CFrame.new(child.Position) * CFrame.Angles(0, elapsed * spd, 0)
			end
		end
	end

	-- 2. Sleeping Boss Guardians AI
	for gId, gEntry in pairs(world.Guardians) do
		local gModel = gEntry.Model
		local gData = gEntry.Data
		local levelInfo = gEntry.LevelInfo
		local root = gModel.PrimaryPart
		if not root then
			continue
		end

		local statusLbl = gModel:FindFirstChild("StatusLabel", true) :: TextLabel?

		-- Check if stunned by Bat or Bear Trap
		if (bossStunUntil[gId] or 0) > now then
			if statusLbl then
				statusLbl.Text = "💫 STUNNED!"
				statusLbl.TextColor3 = Color3.fromRGB(255, 235, 70)
			end
			continue
		end

		-- Check ifBoss stepped on an active DeployedBearTrap
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

		-- Find nearest player in this biome who is carrying a stolen egg (or trespassing closely)
		local targetPlayer: Player? = nil
		local targetHrp: BasePart? = nil
		local bestDist = 48

		for _, player in ipairs(Players:GetPlayers()) do
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
			-- WAKE UP ("!!") AND CHASE!
			if statusLbl then
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
				-- Knock player back slightly (stays in biome so they can see the dropped egg!)
				targetHrp.AssemblyLinearVelocity = Vector3.new(0, 42, 65)
			end
		else
			-- SLEEPING ("Zzz") AT NEST
			if statusLbl then
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
					local gain = 1 + session.Rebirths
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

-- 1-Second Passive Cash Generation Tick for Placed Pedestal Squishies
task.spawn(function()
	while true do
		task.wait(1.0)
		for _, player in ipairs(Players:GetPlayers()) do
			local session = sessions[player]
			if session and session.PassiveIncomeRate > 0 then
				session.UncollectedPlotCash += session.PassiveIncomeRate
				updatePlotOwnerSign(session.PlotIndex, player.DisplayName, session.PassiveIncomeRate, session.UncollectedPlotCash)
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
	session.SpeedStat += 4
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

ClaimDailyRewardEvent.OnServerEvent:Connect(function(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	local now = os.clock()
	if session.LastDailyClaim > 0 and (now - session.LastDailyClaim) < 30 then
		GuardianAlertEvent:FireClient(player, "Daily Reward already claimed recently! Keep stealing eggs!")
		return
	end
	session.LastDailyClaim = now
	session.DailyStreak = (session.DailyStreak % 7) + 1
	local bonusCash = 150 * session.DailyStreak
	session.Coins += bonusCash
	session.LifetimeCoins += bonusCash
	session.SpeedStat += 2
	session.TrapCharges += 1
	applyPlayerSpeed(player)
	ensureCombatGearInBackpack(player)
	GuardianAlertEvent:FireClient(player, string.format("🎁 Day %d Reward: +$%d Cash, +2 Speed & +1 Bear Trap!", session.DailyStreak, bonusCash))
	syncPlayer(player)
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

	sessions[player] = {
		Coins = 100,
		LifetimeCoins = 100,
		SpeedStat = 18,
		SpeedLevel = 1,
		Rebirths = 0,
		DailyStreak = 0,
		LastDailyClaim = 0,
		SloMoActive = false,
		PlotIndex = assignedPlot,
		CarriedEggId = nil,
		CarriedEggVisual = nil,
		FoundEggs = {},
		BackpackCounts = {},
		EquippedId = nil,
		PassiveIncomeRate = 0,
		UncollectedPlotCash = 0,
		LastTreadmillStep = 0,
		TrapCharges = 3,
		LastBatSwing = 0,
		Incubators = incubators,
		Pedestals = {},
	}

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local cashVal = Instance.new("IntValue")
	cashVal.Name = "Cash"
	cashVal.Value = 100
	cashVal.Parent = ls

	local speedVal = Instance.new("IntValue")
	speedVal.Name = "Speed"
	speedVal.Value = 18
	speedVal.Parent = ls

	local eggsVal = Instance.new("IntValue")
	eggsVal.Name = "Eggs"
	eggsVal.Value = 0
	eggsVal.Parent = ls

	updatePlotOwnerSign(assignedPlot, player.DisplayName, 0, 0)
	updateSpeedUpgradePrompt(player)

	player.CharacterAdded:Connect(function(char: Model)
		task.wait(0.15)
		local plotModel = getPlotModel(assignedPlot)
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if plotModel and plotModel.PrimaryPart and hrp then
			hrp.CFrame = CFrame.new(plotModel.PrimaryPart.Position + Vector3.new(0, 4, -8), Vector3.new(0, 4, -40))
		end
		applyPlayerSpeed(player)
		refreshBackpackTools(player)
	end)

	if player.Character then
		task.spawn(function()
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
		if session.CarriedEggId then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			dropCarriedEggAtSpot(player, if hrp then hrp.Position else Vector3.new(0, 3.8, -40), "Player Left")
		end
		if plotOwners[session.PlotIndex] == player then
			plotOwners[session.PlotIndex] = nil
			updatePlotOwnerSign(session.PlotIndex, "UNCLAIMED", 0, 0)
		end
		sessions[player] = nil
	end
end)
