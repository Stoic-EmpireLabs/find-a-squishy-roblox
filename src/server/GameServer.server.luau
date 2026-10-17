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
-- 2. BUILD WORLD & INITIALIZE STATE TABLES
-- ============================================================================
local world = WorldBuilder.BuildWorld()

local dataStore = nil
pcall(function()
	dataStore = DataStoreService:GetDataStore("FindASquishy_Save_v2")
end)

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
local touchCooldowns: { [string]: number } = {}
local guardianWaypoints: { [string]: Vector3 } = {}
local eggLiveOffsets: { [number]: Vector3 } = {}
local paintFolder = Instance.new("Folder")
paintFolder.Name = "FloorPaintSplats"
paintFolder.Parent = Workspace

for _, sDef in ipairs(SlimeData.Slimes) do
	eggLiveOffsets[sDef.Id] = sDef.Position
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
		if not session.PlantedEggs[tostring(sDef.Id)] then
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
				baseSum += def.CoinsPerSec
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
			nest.Pedestal.Transparency = if slotIdx <= 5 then 0 else 0.65
			nest.Pedestal.Color = if slotIdx <= 5
				then Color3.fromRGB(245, 205, 95)
				else Color3.fromRGB(90, 95, 110)
		end
		return
	end

	local penDef = UpgradeData.GetPenTier(session.PenTier)
	local plantedTotal = getPlantedCount(session)
	local incomeRate = getTotalIncomePerSec(session)

	setSignText(
		string.format("🏡 %s's SQUISHY PEN", string.upper(player.DisplayName)),
		string.format(
			"%s | %d / %d Eggs Planted ($%s/s)",
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
		plot.ExpandLabel.Text = string.format("Tier %d (%d Nests): $%s", nextPen.Tier, nextPen.MaxNests, UpgradeData.FormatNumber(nextPen.Cost))
	else
		plot.ExpandLabel.Text = "MAX PEN SIZE (35/35 Nests)!"
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
		plot.TreadmillLabel.Text = "MAX GOD-SPEED TREADMILL!"
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

	-- Update all 35 Nest Pedestals & Hatched Squishies
	for slotIdx = 1, 35 do
		local nest = plot.Nests[slotIdx]
		local isSlotUnlocked = (slotIdx <= penDef.MaxNests)
		local isPlanted = session.PlantedEggs[tostring(slotIdx)] == true

		nest.Pedestal.Transparency = if isSlotUnlocked then 0 else 0.72
		nest.Pedestal.Color = if isPlanted
			then Color3.fromRGB(95, 250, 135)
			elseif isSlotUnlocked then Color3.fromRGB(245, 205, 95)
			else Color3.fromRGB(85, 90, 105)

		if isPlanted then
			if not nest.HatchedModel or nest.HatchedModel:GetAttribute("GelTier") ~= session.GelTier then
				if nest.HatchedModel then
					nest.HatchedModel:Destroy()
				end
				local slimeDef = SlimeData.ById[slotIdx]
				if slimeDef then
					local spawnPos = nest.Pedestal.Position + Vector3.new(0, 2.5, 0)
					local squishyModel = SquishyBuilder.CreateHatchedSquishy(slimeDef, spawnPos, session.GelTier)
					squishyModel:SetAttribute("GelTier", session.GelTier)
					squishyModel.Parent = plot.Folder
					nest.HatchedModel = squishyModel

					-- Add Click-to-Squish Fidget Coin Bonus!
					local clickDet = Instance.new("ClickDetector")
					clickDet.MaxActivationDistance = 32
					clickDet.Parent = squishyModel.PrimaryPart
					clickDet.MouseClick:Connect(function(clickingPlayer: Player)
						local clickSession = sessions[clickingPlayer]
						if not clickSession then
							return
						end
						local bonus = math.max(5, math.floor(slimeDef.CoinsPerSec * 1.5))
						clickSession.Coins += bonus
						updateLeaderstats(clickingPlayer, clickSession)
						syncPlayerState(clickingPlayer)

						-- Pancake Squish Tween!
						local body = squishyModel.PrimaryPart
						if body then
							local origSize = body.Size
							body.Size = Vector3.new(origSize.X * 1.35, origSize.Y * 0.45, origSize.Z * 1.35)
							TweenService:Create(
								body,
								TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
								{ Size = origSize }
							):Play()
						end
						notifyPlayer(
							clickingPlayer,
							string.format("🍮 SQUISH! +%s Bonus Coins from %s!", UpgradeData.FormatNumber(bonus), slimeDef.Name),
							"Success"
						)
					end)
				end
			end
		else
			if nest.HatchedModel then
				nest.HatchedModel:Destroy()
				nest.HatchedModel = nil
			end
		end
	end
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
-- 4. EGG CARRYING & PLANTING LOGIC
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
			"🚨 GRABBED %s EGG! Run back to your Base Pen to Plant it before the Chasers catch you!",
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

	local penDef = UpgradeData.GetPenTier(session.PenTier)
	local currentPlanted = getPlantedCount(session)

	-- Verify player has grown their Pen enough to hold this Egg!
	if currentPlanted >= penDef.MaxNests or eggId > penDef.MaxNests then
		local requiredTier = slimeDef.Level
		local reqPenDef = UpgradeData.GetPenTier(requiredTier)
		notifyPlayer(
			player,
			string.format(
				"⚠️ Your Pen only has %d Nest Slots! Step on the orange [GROW PEN] pad ($%s) to unlock %d Nests!",
				penDef.MaxNests,
				UpgradeData.FormatNumber(reqPenDef.Cost),
				reqPenDef.MaxNests
			),
			"Error"
		)
		return
	end

	-- Plant the Egg and Hatch the Squishy!
	clearCarriedEgg(player)
	session.PlantedEggs[tostring(eggId)] = true
	if session.ActiveGuideEggId == eggId then
		session.ActiveGuideEggId = nil
	end

	-- Reward instant planting bonus
	local hatchBonus = slimeDef.CoinsPerSec * 4
	session.Coins += hatchBonus

	local lvlCompleted = isLevelCompleted(session, slimeDef.Level)
	if lvlCompleted and slimeDef.Level < 5 then
		local nextLvl = SlimeData.Levels[slimeDef.Level + 1]
		notifyPlayer(
			player,
			string.format(
				"🎉 ALL LEVEL %d EGGS PLANTED! Gate to Level %d (%s) is NOW UNLOCKED!",
				slimeDef.Level,
				nextLvl.Level,
				nextLvl.Name
			),
			"Success"
		)
	else
		local levelPlanted = getPlantedCount(session, slimeDef.Level)
		local levelTotal = #(SlimeData.ByLevel[slimeDef.Level] or {})
		notifyPlayer(
			player,
			string.format(
				"🐣 PLANTED & HATCHED %s! (+$%s/sec | Level %d: %d/%d Eggs Planted)",
				slimeDef.Name,
				UpgradeData.FormatNumber(slimeDef.CoinsPerSec),
				slimeDef.Level,
				levelPlanted,
				levelTotal
			),
			"Success"
		)
	end

	syncPlayerState(player)
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
end

-- Hook up World Eggs (Touch to Pickup / BounceWake 3x to Wake)
for eggId, eggModel in pairs(world.WorldEggs) do
	local slimeDef = SlimeData.ById[eggId]
	local primary = eggModel.PrimaryPart
	if primary and slimeDef then
		primary.Touched:Connect(function(hit: BasePart)
			local char = hit.Parent
			local plr = if char then Players:GetPlayerFromCharacter(char) else nil
			local session = if plr then sessions[plr] else nil
			if not plr or not session or not char then
				return
			end
			if isOnCooldown("EggTouch_" .. plr.UserId .. "_" .. eggId, 0.55) then
				return
			end

			-- Check if player already planted this Egg
			if session.PlantedEggs[tostring(eggId)] then
				notifyPlayer(plr, string.format("✅ You already planted & hatched %s in your Pen!", slimeDef.Name), "Info")
				return
			end

			-- Check if player is already carrying an Egg
			if session.CarryingEggId == eggId then
				return
			end

			-- Check Micro-Vent requirement
			if slimeDef.IsMicroVent and not session.TinyMode then
				notifyPlayer(
					plr,
					"🐭 Too big to reach inside the Tiny Vent! Open [Slimeopedia] -> Toggle [Tiny Squishy Size]!",
					"Warning"
				)
				return
			end

			-- Handle BounceWake Eggs (Jump on top 3 times!)
			if slimeDef.Behavior == "BounceWake" then
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 78, hrp.AssemblyLinearVelocity.Z)
				end
				local bounces = (eggModel:GetAttribute("BounceCount_" .. plr.UserId) or 0) + 1
				eggModel:SetAttribute("BounceCount_" .. plr.UserId, bounces)
				if bounces < 3 then
					notifyPlayer(
						plr,
						string.format("😴 *BOING!* (%d/3 Bounces to wake %s Egg!)", bounces, slimeDef.Name),
						"Info"
					)
					return
				end
				eggModel:SetAttribute("BounceCount_" .. plr.UserId, 0)
			end

			-- Attach the Egg to the player and trigger the Level Guardians to chase!
			attachCarriedEggToPlayer(plr, slimeDef)
		end)
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
					-- Non-lethal fun bounce-back knockback!
					hrp.AssemblyLinearVelocity = Vector3.new(0, 58, 42)
					notifyPlayer(plr, "⚡ Ouch! Watch out for the Obby Lasers & Lava! Upgrade Jump Springs to clear them!", "Warning")
				end
			end)
		end
	end
end

-- ============================================================================
-- 6. CLIENT ACTION REQUEST HANDLER (UI Buttons, Morphs, Teleports, Family Boosts)
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
	elseif action == "MorphSlime" then
		local slimeId = tonumber(payload.SlimeId)
		if not slimeId or slimeId == 0 then
			session.CurrentMorphId = nil
			applyCharacterStatsAndTrail(player, session)
			notifyPlayer(player, "Returned to Normal Avatar!", "Info")
		elseif session.PlantedEggs[tostring(slimeId)] then
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
			-- Find nearest Co-op Plate B and place a helper Squishy weight on it for 25 seconds
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
			local decoy = SquishyBuilder.CreateHatchedSquishy(SlimeData.ById[1], dropPos, session.GelTier)
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
			-- If carrying an Egg outside the Safe Zone, require running to the Level Gate first!
			if session.CarryingEggId and hrp.Position.Z < -65 then
				notifyPlayer(player, "🏃 You're carrying an Egg! Outrun the Chasers to the Green Safe Line first!", "Warning")
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
							-- Steal carried Egg if they were holding one!
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
				session.PlantedEggs[tostring(sDef.Id)] = true
			end
			notifyPlayer(player, string.format("🐣 Family Boost: Planted all Level %d Eggs & Unlocked Gate!", maxLvl), "Success")
		end
		syncPlayerState(player)
	end
end)

-- ============================================================================
-- 7. MASTER HEARTBEAT LOOPS (Treadmill, Guardian Chasers, Living Eggs, Gates, Income)
-- ============================================================================

-- Loop A: Passive Pen Income & Treadmill Speed Training (Every 0.5s)
task.spawn(function()
	local tickCounter = 0
	while true do
		task.wait(0.5)
		tickCounter += 1

		for _, player in ipairs(Players:GetPlayers()) do
			local session = sessions[player]
			if session then
				-- 1. Every 1.0s (2 ticks), generate passive Pen Coins
				if tickCounter % 2 == 0 then
					local income = getTotalIncomePerSec(session)
					if income > 0 then
						session.StoredPenCoins += income
					end
				end

				-- 2. Check if Player is running on ANY Treadmill Belt + Spawn Floor Coloring Paint!
				local char = player.Character
				local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
				if hrp and hum and hum.Health > 0 then
					local pos = hrp.Position

					-- Check Base Treadmill or Public Hub Treadmill
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
					end

					-- 3. Floor Coloring Paint Trail Splat when moving!
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

					-- 4. Server-Side Level Gate Enforcement (Cannot pass Gate N unless Levels 1..N are 100% planted!)
					local maxUnlocked = getMaxUnlockedLevel(session)
					for gateLvl = 1, 4 do
						local gatePart = world.LevelGates[gateLvl]
						if gatePart and maxUnlocked <= gateLvl and pos.Z < (gatePart.Position.Z - 1.0) then
							-- Bounce player gently back in front of the locked gate
							hrp.CFrame = CFrame.new(math.clamp(pos.X, -65, 65), 5, gatePart.Position.Z + 8)
							if not isOnCooldown("GateWarn_" .. player.UserId, 2.0) then
								local plantedInLvl = getPlantedCount(session, gateLvl)
								local totalInLvl = #(SlimeData.ByLevel[gateLvl] or {})
								notifyPlayer(
									player,
									string.format(
										"🔒 Gate Locked! You must FIND & PLANT all %d Eggs in Level %d first! (Planted: %d/%d)",
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
					syncPlayerState(player)
				end
			end
		end
	end
end)

-- Loop B: Animal & Brainrot Chaser Guardians AI + Living Eggs + Co-op Buddy Vaults (Every 0.12s)
task.spawn(function()
	local dt = 0.12
	while true do
		task.wait(dt)
		local now = os.clock()

		-- 1. Update All 10 Animal & Brainrot Chaser Guardians!
		for gId, gEntry in pairs(world.WorldGuardians) do
			local gDef = gEntry.Def
			local gModel = gEntry.Model
			local gBody = gModel.PrimaryPart
			local lvlDef = SlimeData.Levels[gDef.Level]
			if gBody and lvlDef then
				-- Check if ANY player in this Level is currently carrying an Egg!
				local targetPlayer: Player? = nil
				local targetHrp: BasePart? = nil
				local bestDist = 260

				for _, plr in ipairs(Players:GetPlayers()) do
					local session = sessions[plr]
					local char = plr.Character
					local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
					if session and session.CarryingEggId and hrp then
						local pPos = hrp.Position
						-- Chasers hunt players inside their Level corridor (until they cross the Safe Line at ZStart!)
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

				if targetPlayer and targetHrp then
					-- CHASE THE EGG CARRIER!
					local targetPos = Vector3.new(targetHrp.Position.X, gDef.HomePosition.Y, targetHrp.Position.Z)
					local delta = targetPos - gBody.Position
					local dist = delta.Magnitude

					local session = sessions[targetPlayer]
					local playerSpdPower = if session then session.SpeedPower else 100
					-- Effective chase speed: if player trained their SpeedPower >= RequiredSpeedPower, player can outrun the Guardian!
					local speedRatio = math.clamp(gDef.RequiredSpeedPower / math.max(100, playerSpdPower), 0.55, 1.35)
					local effectiveStep = gDef.ChaseSpeed * speedRatio * dt

					if statusLbl then
						statusLbl.Text = string.format(
							"🚨 CHASING %s! (Req: %s Speed!)",
							string.upper(targetPlayer.DisplayName),
							UpgradeData.FormatNumber(gDef.RequiredSpeedPower)
						)
						statusLbl.TextColor3 = Color3.fromRGB(255, 75, 75)
					end

					if dist > 0.5 then
						local moveDir = delta.Unit
						local nextPos = gBody.Position + moveDir * math.min(dist, effectiveStep)
						local bounceY = math.abs(math.sin(now * 10)) * 1.2
						gModel:PivotTo(CFrame.lookAt(nextPos + Vector3.new(0, bounceY, 0), targetPos + Vector3.new(0, bounceY, 0)))
					end

					-- Did the Guardian catch the Egg Carrier?
					if dist <= 6.2 and session then
						local droppedId = session.CarryingEggId
						local droppedDef = if droppedId then SlimeData.ById[droppedId] else nil
						clearCarriedEgg(targetPlayer)
						targetHrp.AssemblyLinearVelocity = Vector3.new(0, 68, 55)
						notifyPlayer(
							targetPlayer,
							string.format(
								"💥 CAUGHT BY %s! You dropped the %s Egg! Train on your Treadmill to reach %s Speed Power!",
								string.upper(gDef.Name),
								if droppedDef then droppedDef.Name else "Squishy",
								UpgradeData.FormatNumber(gDef.RequiredSpeedPower)
							),
							"Error"
						)
						syncPlayerState(targetPlayer)
					end
				else
					-- PATROL MODE
					if statusLbl then
						statusLbl.Text = string.format(
							"😴 Guarding Eggs (Speed Power: %s)",
							UpgradeData.FormatNumber(gDef.RequiredSpeedPower)
						)
						statusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
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
						local hopY = math.abs(math.sin(now * 5)) * 0.5
						gModel:PivotTo(CFrame.lookAt(nextPos + Vector3.new(0, hopY, 0), wp + Vector3.new(0, hopY, 0)))
					end
				end
			end
		end

		-- 2. Update Living Egg Behaviors (Runaway Shy Eggs & Disguised Peekaboo Eggs)
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
							-- Clamp within level bounds near home
							nextPos = Vector3.new(
								math.clamp(nextPos.X, basePos.X - 20, basePos.X + 20),
								basePos.Y + math.abs(math.sin(now * 9)) * 1.4,
								math.clamp(nextPos.Z, basePos.Z - 16, basePos.Z + 16)
							)
							eggLiveOffsets[eggId] = nextPos
							eggModel:PivotTo(CFrame.new(nextPos))
						end
					else
						-- Gently return toward home spot
						local returnPos = curPos:Lerp(basePos, 0.08)
						eggLiveOffsets[eggId] = returnPos
						eggModel:PivotTo(CFrame.new(returnPos + Vector3.new(0, math.sin(now * 3 + eggId) * 0.35, 0)))
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

		-- 3. Update Co-op Buddy Plates (Open Vault Door when Plate A & Plate B are pressed or Decoy Weight is active!)
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

				local vaultOpen = (aPressed and bPressed) or bPressed -- If Decoy Weight is dropped or 2 players stand on plates!
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
		Coins = 100, -- Starter coins so kids can test anEgg Guide or Trail right away!
		StoredPenCoins = 0,
		SpeedPower = 100,
		PenTier = 1,
		TreadmillTier = 1,
		GelTier = 1,
		JumpTier = 1,
		PlantedEggs = {},
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

	player.CharacterAdded:Connect(function(character: Model)
		clearCarriedEgg(player)
		task.wait(0.25)
		applyCharacterStatsAndTrail(player, session)
		-- Spawn player right in front of their assigned Base Pen on join!
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
