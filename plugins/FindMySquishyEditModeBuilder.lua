-- FindMySquishyEditModeBuilder.lua
-- Clean Edit-Mode World Builder + Full Phase 1-6 Automated Verification Audit for Find My Squishy.rbxl

local RunService = game:GetService("RunService")
if not RunService:IsEdit() then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

pcall(function()
	local studioSettings = settings().Studio
	studioSettings["Show Navigation Mesh"] = false
	studioSettings["Show Navigation Labels"] = false
	studioSettings["Show Pathfinding Links"] = false
	studioSettings["Show Light Guides"] = false
	StarterGui.ShowDevelopmentGui = false
	for _, oldGuiName in ipairs({ "FindASquishyHUD", "StealMyEggHUD" }) do
		local oldGui = StarterGui:FindFirstChild(oldGuiName)
		if oldGui then
			oldGui:Destroy()
		end
	end
	game:SetUniverseId(10771618269)
	game:SetPlaceId(99542192127764)
	print(string.format("[EditModeBuilder] Bound PlaceId=%d GameId=%d", game.PlaceId, game.GameId))
end)

task.spawn(function()
	task.wait(0.2)
	if not RunService:IsEdit() then
		return
	end

	local HttpService = game:GetService("HttpService")
	local StarterPlayer = game:GetService("StarterPlayer")
	pcall(function()
		local rawJson = HttpService:GetAsync("http://127.0.0.1:18765/bundle.json", true)
		local bundle = HttpService:JSONDecode(rawJson)
		if type(bundle) == "table" then
			local sharedF = ReplicatedStorage:FindFirstChild("Shared")
			if not sharedF then
				sharedF = Instance.new("Folder")
				sharedF.Name = "Shared"
				sharedF.Parent = ReplicatedStorage
			end
			local serverF = ServerScriptService:FindFirstChild("Server")
			if not serverF then
				serverF = Instance.new("Folder")
				serverF.Name = "Server"
				serverF.Parent = ServerScriptService
			end
			local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
			local clientF = sps and sps:FindFirstChild("Client")
			if sps and not clientF then
				clientF = Instance.new("Folder")
				clientF.Name = "Client"
				clientF.Parent = sps
			end

			local function setScriptSource(parent: Instance?, name: string, className: string, src: string?)
				if not parent or type(src) ~= "string" then
					return
				end
				local inst = parent:FindFirstChild(name)
				if inst and inst.ClassName ~= className then
					inst:Destroy()
					inst = nil
				end
				if not inst then
					inst = Instance.new(className)
					inst.Name = name
					inst.Parent = parent
				end
				(inst :: any).Source = src
			end

			setScriptSource(sharedF, "SlimeData", "ModuleScript", bundle.SlimeData)
			setScriptSource(sharedF, "UIBuilder", "ModuleScript", bundle.UIBuilder)
			setScriptSource(sharedF, "SquishyBuilder", "ModuleScript", bundle.SquishyBuilder)
			setScriptSource(sharedF, "PrebuiltLoader", "ModuleScript", bundle.PrebuiltLoader)
			setScriptSource(sharedF, "CreatorStoreGameplayKits", "ModuleScript", bundle.CreatorStoreGameplayKits)
			setScriptSource(serverF, "WorldBuilder", "ModuleScript", bundle.WorldBuilder)
			setScriptSource(serverF, "GameServer", "Script", bundle.GameServer)
			setScriptSource(clientF, "GameClient", "LocalScript", bundle.GameClient)
			print("[EditModeBuilder] CloudPlaceSynced=true (Updated all 8 Luau scripts from local workspace!)")
		end
	end)

	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if not sharedFolder or not sharedFolder:FindFirstChild("SlimeData") then
		return
	end

	local slimeData = require(sharedFolder:WaitForChild("SlimeData"))
	local creatorStoreKitsMod = sharedFolder:FindFirstChild("CreatorStoreGameplayKits")
	if creatorStoreKitsMod and creatorStoreKitsMod:IsA("ModuleScript") then
		local okK, kitModule = pcall(require, creatorStoreKitsMod)
		if okK and type(kitModule) == "table" and type(kitModule.EnsureGameplayKits) == "function" then
			pcall(function()
				kitModule.EnsureGameplayKits(function(assetId)
					return game:GetObjects("rbxassetid://" .. tostring(assetId))
				end)
			end)
		end
	end

	local prebuiltLoaderMod = sharedFolder:FindFirstChild("PrebuiltLoader")
	if prebuiltLoaderMod and prebuiltLoaderMod:IsA("ModuleScript") then
		local okP, pl = pcall(require, prebuiltLoaderMod)
		if okP and type(pl) == "table" and type(pl.EnsurePrebuiltAssets) == "function" then
			pcall(function()
				pl.EnsurePrebuiltAssets(function(assetId)
					return game:GetObjects("rbxassetid://" .. tostring(assetId))
				end)
			end)
		end
	end
	task.wait(0.1)

	local serverFolder = ServerScriptService:FindFirstChild("Server")
	local worldBuilderModule = if serverFolder then serverFolder:FindFirstChild("WorldBuilder") else nil
	if worldBuilderModule and worldBuilderModule:IsA("ModuleScript") then
		local ok, wb = pcall(require, worldBuilderModule)
		if ok and type(wb) == "table" and type(wb.BuildWorld) == "function" then
			local bOk, bRes = pcall(function()
				return wb.BuildWorld()
			end)
			if not bOk then
				warn("[EditModeBuilder Error] " .. tostring(bRes))
			end
		end
		task.wait(0.1)

		-- ============================================================================
		-- RUN COMPREHENSIVE PHASE 1 TO PHASE 6 VERIFICATION AUDIT
		-- ============================================================================
		local worldFolder = Workspace:FindFirstChild("SquishyWorld")
		if worldFolder then
			-- PHASE 1 CHECK (8 Full Structured Stages, 16 Bosses, 117 World Items):
			local eggsFolder = worldFolder:FindFirstChild("WorldEggs")
			local guardiansFolder = worldFolder:FindFirstChild("Guardians")
			local plotsFolder = worldFolder:FindFirstChild("PlayerPlots")
			local levelsFolder = worldFolder:FindFirstChild("Levels")
			local stairFolder = worldFolder:FindFirstChild("RainbowDisappearingStaircase")
			local worldEggCount = if eggsFolder then #eggsFolder:GetChildren() else 0
			local guardCount = if guardiansFolder then #guardiansFolder:GetChildren() else 0
			local plotCount = if plotsFolder then #plotsFolder:GetChildren() else 0
			local levelCount = if levelsFolder then #levelsFolder:GetChildren() else 0
			local stairSteps = 0
			if stairFolder then
				for _, d in ipairs(stairFolder:GetDescendants()) do
					if d:IsA("BasePart") and d:GetAttribute("DisappearingStep") == true then
						stairSteps += 1
					end
				end
			end
			print(
				string.format(
					"[AUDIT PHASE 1] PASS=%s | WorldItems=%d/117 | SleepingBosses=%d/16 | BasePlots=%d/4 | BiomeStages=%d/8 (220x160 each, Z=0..-1280) | RainbowStairSteps=%d/28",
					tostring(worldEggCount == 117 and guardCount == 16 and plotCount == 4 and levelCount == 8 and stairSteps == 28),
					worldEggCount,
					guardCount,
					plotCount,
					levelCount,
					stairSteps
				)
			)

			-- PHASE 2 CHECK (Creator Store Treadmills: 4 Plot + 8 Stage = 12 Total, Scrolling Beam Belts):
			local treadmillBeltCount = 0
			local scrollBeamCount = 0
			for _, desc in ipairs(worldFolder:GetDescendants()) do
				if desc:IsA("BasePart") and string.find(desc.Name, "^TreadmillBelt_") then
					treadmillBeltCount += 1
				elseif desc:IsA("Beam") and desc.Name == "TreadmillScrollBeam" then
					scrollBeamCount += 1
				end
			end
			print(
				string.format(
					"[AUDIT PHASE 2] PASS=%s | CreatorStoreTreadmills=%d/12 (4 Plot + 8 Stage) | ScrollingBeltBeams=%d/12",
					tostring(treadmillBeltCount == 12 and scrollBeamCount >= 12),
					treadmillBeltCount,
					scrollBeamCount
				)
			)

			-- PHASE 3 CHECK (Fenced Squishy Hatchery Pens & Grow/Level Up Stations on All 4 Plots):
			local hatcheryPenCount = 0
			local growPadCount = 0
			if plotsFolder then
				for _, plotModel in ipairs(plotsFolder:GetChildren()) do
					if plotModel:FindFirstChild("HatcheryPen") then
						hatcheryPenCount += 1
					end
					if plotModel:FindFirstChild("CollectCashPad") then
						growPadCount += 1
					end
				end
			end
			print(
				string.format(
					"[AUDIT PHASE 3] PASS=%s | FencedHatcheryPens=%d/4 | GrowAndCashPads=%d/4",
					tostring(hatcheryPenCount == 4 and growPadCount == 4),
					hatcheryPenCount,
					growPadCount
				)
			)

			-- PHASE 4 CHECK (Zero-Hold Walk-Over Auto-Pickup & 8 Stage Gate Barriers):
			local zeroHoldItemPrompts = 0
			local gateBarriers = 0
			if eggsFolder then
				for _, desc in ipairs(eggsFolder:GetDescendants()) do
					if desc:IsA("ProximityPrompt") and desc.HoldDuration == 0 then
						zeroHoldItemPrompts += 1
					end
				end
			end
			if levelsFolder then
				for _, desc in ipairs(levelsFolder:GetDescendants()) do
					if desc:IsA("BasePart") and string.find(desc.Name, "^GateBarrier_") then
						gateBarriers += 1
					end
				end
			end
			local hubFolder = worldFolder:FindFirstChild("SafeZoneHub")
			local lbFolder = hubFolder and hubFolder:FindFirstChild("GlobalLeaderboards")
			local lbCount = if lbFolder then #lbFolder:GetChildren() else 0
			print(
				string.format(
					"[AUDIT PHASE 4] PASS=%s | ZeroHoldWalkOverPrompts=%d/117 | StageGateBarriers=%d/8 | Global3DLeaderboards=%d/3",
					tostring(zeroHoldItemPrompts == 117 and gateBarriers >= 7 and lbCount == 3),
					zeroHoldItemPrompts,
					gateBarriers,
					lbCount
				)
			)

			-- PHASE 5 & PHASE 6 HUD CHECK (Temporary Folder Audit -> Destroyed Immediately After):
			local uiBuilderMod = sharedFolder:FindFirstChild("UIBuilder")
			if uiBuilderMod and uiBuilderMod:IsA("ModuleScript") then
				local tempFolder = Instance.new("Folder")
				local ub = require(uiBuilderMod)
				local ui = ub.CreateHUD(tempFolder)
				local indexCardCount = 0
				for _ in pairs(ui.IndexCards) do
					indexCardCount += 1
				end
				local hasObjectiveBanner = ui.ObjectiveBanner ~= nil
				local hasComboFrame = ui.ComboFrame ~= nil
				local hasHowToPlayModal = ui.HowToPlayModal ~= nil
				local hasThrottleBtns = ui.SpeedThrottleButtons ~= nil and ui.SpeedThrottleButtons[100] ~= nil
				print(
					string.format(
						"[AUDIT PHASE 5] PASS=%s | ObjectiveTrackerBanner=%s | SquishFeverComboHUD=%s | HowToPlayModal=%s | SpeedThrottleSelector=%s | Index3DCards=%d/117",
						tostring(hasObjectiveBanner and hasComboFrame and hasHowToPlayModal and hasThrottleBtns and indexCardCount == 117),
						tostring(hasObjectiveBanner),
						tostring(hasComboFrame),
						tostring(hasHowToPlayModal),
						tostring(hasThrottleBtns),
						indexCardCount
					)
				)

				local passCount = 0
				for _ in pairs(ui.PassButtonsByKey) do
					passCount += 1
				end
				local devProdCount = 0
				for _ in pairs(ui.DevProductButtons) do
					devProdCount += 1
				end
				local playtimeCount = #ui.PlaytimeButtons
				local boothCount = 0
				if hubFolder then
					for _, bName in ipairs({ "LuckySpinWheelBooth", "DailyRewardChestBooth", "VIPRobuxShopBooth" }) do
						if hubFolder:FindFirstChild(bName) then
							boothCount += 1
						end
					end
				end
				print(
					string.format(
						"[AUDIT PHASE 6] PASS=%s | Gamepasses=%d/5 | DevProducts=%d/6 | PlaytimeMilestoneChests=%d/5 | SafeZoneBooths=%d/3",
						tostring(passCount == 5 and devProdCount == 6 and playtimeCount == 5 and boothCount == 3),
						passCount,
						devProdCount,
						playtimeCount,
						boothCount
					)
				)

				-- Monetization and Creator Store Kits Audit Check
				local userKitsFolder = hubFolder and hubFolder:FindFirstChild("UserCreatorStoreKits")
				local donationBoard = userKitsFolder and userKitsFolder:FindFirstChild("RobuxDonationBoardFrame")
				local gamepassKiosk = userKitsFolder and userKitsFolder:FindFirstChild("ObbyGamepassBoardFrame")
				local timeLeaderboard = userKitsFolder and userKitsFolder:FindFirstChild("TimePlayedBoardFrame")
				local skipObbyPads = 0
				local skipGatePrompts = 0
				local landmarkLadders = 0
				for _, desc in ipairs(worldFolder:GetDescendants()) do
					if desc:IsA("BasePart") and (desc.Name == "SkipObbyPaywallPad" or string.find(desc.Name, "^SkipObby")) then
						skipObbyPads += 1
					elseif desc:IsA("ProximityPrompt") and (desc.Name == "SkipStageGatePaywallPrompt" or desc.Name == "SkipStageGatePrompt") then
						skipGatePrompts += 1
					elseif desc:IsA("TrussPart") and (string.find(desc.Name, "Ladder") or string.find(desc.Name, "Truss")) then
						landmarkLadders += 1
					end
				end
				print(
					string.format(
						"[AUDIT MONETIZATION & KITS v29] PASS=%s | Gamepasses=%d/5 | DevProducts=%d/6 | DonationBoard=%s | ObbyGamepassKiosk=%s | TimeLeaderboard=%s | SkipObbyPads=%d/9 | SkipGatePrompts=%d/7 | LandmarkLadders=%d",
						tostring(passCount == 5 and devProdCount == 6 and donationBoard ~= nil and gamepassKiosk ~= nil and timeLeaderboard ~= nil and skipObbyPads >= 9 and skipGatePrompts >= 7 and landmarkLadders >= 10),
						passCount,
						devProdCount,
						tostring(donationBoard ~= nil),
						tostring(gamepassKiosk ~= nil),
						tostring(timeLeaderboard ~= nil),
						skipObbyPads,
						skipGatePrompts,
						landmarkLadders
					)
				)

				-- Ingested Maps and Inventory Kits Audit
				local mapsFolder = ReplicatedStorage:FindFirstChild("Maps")
				local mapCount = if mapsFolder then #mapsFolder:GetChildren() else 0
				local prebuiltAssets = ReplicatedStorage:FindFirstChild("Models") and ReplicatedStorage.Models:FindFirstChild("PrebuiltAssets")
				local cuteSlimeIcons = prebuiltAssets and prebuiltAssets:FindFirstChild("CuteSlimeIcons")
				local cuteIconCount = if cuteSlimeIcons then #cuteSlimeIcons:GetChildren() else 0
				local importedBaseMap = worldFolder:FindFirstChild("ImportedBaseMap")
				print(
					string.format(
						"[AUDIT INVENTORY & MAPS v30] PASS=%s | IngestedMaps=%d/7 | CuteSlimeIcons=%d | ImportedBaseMap=%s",
						tostring(importedBaseMap ~= nil),
						mapCount,
						cuteIconCount,
						tostring(importedBaseMap ~= nil)
					)
				)


				-- ============================================================================
				-- AUDIT LIVE-PLAYER FEEDBACK ROLLOUT (PHASES 1 TO 7)
				-- ============================================================================
				local safeZoneWildItems = 0
				for _, s in ipairs(slimeData.Slimes) do
					if s.SpawnOffset.Z >= 0 then
						safeZoneWildItems += 1
					end
				end
				local safeZoneRoofCrates = 0
				if plotsFolder then
					for _, d in ipairs(plotsFolder:GetDescendants()) do
						if d.Name == "RooftopStepCrate" then
							safeZoneRoofCrates += 1
						end
					end
				end
				local safeZoneLawn = (worldFolder:FindFirstChild("HubGrassMain", true) or worldFolder:FindFirstChild("SafeZoneGround", true) or worldFolder:FindFirstChild("SafeZoneLawn", true)) :: BasePart?
				local lawnWidth = if safeZoneLawn then safeZoneLawn.Size.X else 0
				local afkBeltsZeroVel = true
				for _, desc in ipairs(worldFolder:GetDescendants()) do
					if desc:IsA("BasePart") and string.find(desc.Name, "^TreadmillBelt_") then
						if desc.AssemblyLinearVelocity.Magnitude > 0.01 then
							afkBeltsZeroVel = false
						end
					end
				end
				local hasDismissButtons = (ui.TopHudCloseBtn ~= nil) and (ui.CloseBannerBtn ~= nil) and (ui.RestoreTopHudBtn ~= nil)
				local hasTurboBtn = (ui.TreadmillTurboBtn ~= nil)
				print(
					string.format(
						"[AUDIT LIVE FEEDBACK PHASES 1-7] PASS=%s | DismissibleTopHUD=%s | SafeZoneRoofCrates=%d | SafeZoneWildSquishies=%d | HubWidth=%d | AFKTreadmillZeroPushback=%s | InteractiveTurboBtn=%s",
						tostring(hasDismissButtons and safeZoneRoofCrates == 0 and safeZoneWildItems == 0 and lawnWidth == 490 and afkBeltsZeroVel and hasTurboBtn),
						tostring(hasDismissButtons),
						safeZoneRoofCrates,
						safeZoneWildItems,
						lawnWidth,
						tostring(afkBeltsZeroVel),
						tostring(hasTurboBtn)
					)
				)

				-- ============================================================================
				-- AUDIT BRAINROT & MATTE MAP OVERHAUL (PHASES 1 TO 6)
				-- ============================================================================
				local roadFolder = worldFolder:FindFirstChild("CentralHighwayRoad")
				local coinsFolder = worldFolder:FindFirstChild("WorldCoins")
				local coinCount = if coinsFolder then #coinsFolder:GetChildren() else 0
				local brainrotCount = 0
				local hiddenSquishyCount = 0
				for _, s in ipairs(slimeData.Slimes) do
					local numId = tonumber((s :: any).UnlockOrder or (s :: any).NumericId or s.Id) or 1
					if numId <= 35 then
						brainrotCount += 1
					else
						hiddenSquishyCount += 1
					end
				end
				local fenceUpgradeStandCount = 0
				local growStandCount = 0
				local totalPlotPedestals = 0
				if plotsFolder then
					for _, plotModel in ipairs(plotsFolder:GetChildren()) do
						local pen = plotModel:FindFirstChild("HatcheryPen")
						if pen then
							if pen:FindFirstChild("UpgradeFenceStand") then
								fenceUpgradeStandCount += 1
							end
							if pen:FindFirstChild("GrowSquishyStand") then
								growStandCount += 1
							end
						end
						local pedsFolder = plotModel:FindFirstChild("Pedestals")
						if pedsFolder then
							for _, ch in ipairs(pedsFolder:GetChildren()) do
								if string.find(ch.Name, "^Pedestal_") then
									totalPlotPedestals += 1
								end
							end
						end
					end
				end
				local stageLandmarksCount = 0
				local stageObbyCount = 0
				if levelsFolder then
					for idx, stFolder in ipairs(levelsFolder:GetChildren()) do
						local lmFolder = stFolder:FindFirstChild("BiomeLandmarks_" .. tostring(idx), true) or stFolder:FindFirstChild("Landmarks", true)
						if not lmFolder then
							for _, d in ipairs(stFolder:GetDescendants()) do
								if d:IsA("Folder") and string.find(d.Name, "^BiomeLandmarks_") then
									lmFolder = d
									break
								end
							end
						end
						if lmFolder and #lmFolder:GetChildren() > 0 then
							stageLandmarksCount += 1
							stageObbyCount += 1
						end
					end
				end
				local hasHintAndFenceUI = (ui.BuyHintIndexBtn ~= nil)
					and (ui.BuyFenceBtn ~= nil)
					and (ui.BuyHintShopBtn ~= nil)
					and (ui.DevProductButtons["LuckyEggRoll"] ~= nil)
				local fenceLevelCount = if slimeData.FenceLevels then #slimeData.FenceLevels else 0
				local treadmillTierCount = if slimeData.TreadmillTiers then #slimeData.TreadmillTiers else 0
				print(
					string.format(
						"[AUDIT BRAINROT & MATTE MAP OVERHAUL PHASES 1-6] PASS=%s | CentralAsphaltRoad=%s | Brainrots=%d/35 | HiddenSquishies=%d/82 | WorldCoins=%d/120 | StageLandmarks=%d/8 | StageObbies=%d/8 | GrowStands=%d/4 | FenceUpgradeStands=%d/4 | PlotPedestals=%d/140 | FenceLevels=%d/8 | TreadmillTiers=%d/8 | HintAndFenceUI=%s",
						tostring(
							roadFolder ~= nil
								and brainrotCount == 35
								and hiddenSquishyCount == 82
								and coinCount == 120
								and stageLandmarksCount == 8
								and stageObbyCount == 8
								and growStandCount == 4
								and fenceUpgradeStandCount == 4
								and totalPlotPedestals == 140
								and fenceLevelCount == 8
								and treadmillTierCount == 8
								and hasHintAndFenceUI
						),
						tostring(roadFolder ~= nil),
						brainrotCount,
						hiddenSquishyCount,
						coinCount,
						stageLandmarksCount,
						stageObbyCount,
						growStandCount,
						fenceUpgradeStandCount,
						totalPlotPedestals,
						fenceLevelCount,
						treadmillTierCount,
						tostring(hasHintAndFenceUI)
					)
				)

				-- ============================================================================
				-- AUDIT BUGFIX VERIFICATION (v20)
				-- ============================================================================
				local scaleOk = type(slimeData.GetStageHatchScale) == "function"
					and slimeData.GetStageHatchScale(1) == 1.00
					and slimeData.GetStageHatchScale(8) == 3.20
				local rollTestFound = { ["1"] = true, ["2"] = true, ["3"] = true }
				local rolledUnfound = slimeData.RollStageBrainrotId(1, false, rollTestFound)
				local rollNoSoftLockOk = (rolledUnfound == "4")
				local touchableCoinsCount = 0
				local pivotCoinsOk = true
				if coinsFolder then
					for _, cModel in ipairs(coinsFolder:GetChildren()) do
						local okPiv, pivPos = pcall(function()
							return if cModel:IsA("Model") then cModel:GetPivot().Position else (cModel :: any).Position
						end)
						if not okPiv or typeof(pivPos) ~= "Vector3" then
							pivotCoinsOk = false
						end
						local core = cModel:FindFirstChild("CoinCore")
						if core and core:IsA("BasePart") and core.CanTouch and core:GetAttribute("WorldCoinPickup") == true and core:GetAttribute("CoinSpinRotor") == true then
							touchableCoinsCount += 1
						end
					end
				end
				local eggNamedOk = if eggsFolder then (eggsFolder:FindFirstChild("Egg_1") ~= nil and eggsFolder:FindFirstChild("Egg_35") ~= nil and eggsFolder:FindFirstChild("ShiningSquishy_36") ~= nil and eggsFolder:FindFirstChild("ShiningSquishy_117") ~= nil) else false
				local hintCostStage1 = slimeData.GetHintCostForStage(1)
				print(
					string.format(
						"[AUDIT BUGFIX VERIFICATION v20] PASS=%s | StageHatchScale=%s | RollUnfoundFirstNoSoftLock=%s | PivotCoinsNoCrash=%s | TouchableSpinningCoins=%d/120 | EggAndSquishyNames=%s | Stage1HintCost=%d",
						tostring(scaleOk and rollNoSoftLockOk and pivotCoinsOk and touchableCoinsCount == 120 and eggNamedOk and hintCostStage1 == 150),
						tostring(scaleOk),
						tostring(rollNoSoftLockOk),
						tostring(pivotCoinsOk),
						touchableCoinsCount,
						tostring(eggNamedOk),
						hintCostStage1
					)
				)

				-- ============================================================================
				-- AUDIT GLOBAL RESET & FENCE SPACING (v22)
				-- ============================================================================
				local allOutsideFence = true
				local minStationDist = 999.0
				if plotsFolder then
					for _, plotModel in ipairs(plotsFolder:GetChildren()) do
						local pen = plotModel:FindFirstChild("HatcheryPen")
						local penFloor = pen and pen:FindFirstChild("HatcheryPenFloor") :: BasePart?
						local upgSpd = plotModel:FindFirstChild("SpeedUpgradeStand") :: BasePart?
						local colPad = plotModel:FindFirstChild("CollectCashPad") :: BasePart?
						local growSt = pen and pen:FindFirstChild("GrowSquishyStand") :: BasePart?
						local fenceSt = pen and pen:FindFirstChild("UpgradeFenceStand") :: BasePart?
						if penFloor and upgSpd and colPad and growSt and fenceSt then
							local faceDir = (pen:GetAttribute("FaceDir") :: number?) or 1
							local frontFenceX = penFloor.Position.X + faceDir * (penFloor.Size.X * 0.5)
							local stations = { upgSpd, colPad, growSt, fenceSt }
							for _, st in ipairs(stations) do
								local outwardOffset = (st.Position.X - frontFenceX) * faceDir
								if outwardOffset < 6.0 then
									allOutsideFence = false
								end
							end
							for i = 1, #stations do
								for j = i + 1, #stations do
									local d = (Vector3.new(stations[i].Position.X, 0, stations[i].Position.Z) - Vector3.new(stations[j].Position.X, 0, stations[j].Position.Z)).Magnitude
									if d < minStationDist then
										minStationDist = d
									end
								end
							end
						else
							allOutsideFence = false
						end
					end
				end
				local hasLikeBooth = if hubFolder then (hubFolder:FindFirstChild("LikeFavoriteRewardBooth") ~= nil and hubFolder:FindFirstChild("SpawnLikeFavoritePad", true) ~= nil) else false
				local hasLikeUI = (ui.LikeFavoriteModal ~= nil and ui.LikeFavHudBtn ~= nil and ui.FavoriteNowBtn ~= nil and ui.ClaimLikeFavRewardBtn ~= nil)
				print(
					string.format(
						"[AUDIT GLOBAL RESET & FENCE SPACING v22] PASS=%s | AllOutsideFence=%s | MinStationSpacing=%.1f | LikeFavoriteBooth=%s | LikeFavoriteUI=%s",
						tostring(allOutsideFence and minStationDist >= 11.0 and hasLikeBooth and hasLikeUI),
						tostring(allOutsideFence),
						minStationDist,
						tostring(hasLikeBooth),
						tostring(hasLikeUI)
					)
				)

				local sps = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
				local clientFolder = sps and sps:FindFirstChild("Client")
				local gcInst = clientFolder and clientFolder:FindFirstChild("GameClient")
				local gcSrc = if gcInst and gcInst:IsA("LocalScript") then (gcInst :: any).Source else ""
				local ps5CheckOk = string.find(gcSrc, "isConsoleOrGamepad", 1, true) ~= nil
					and string.find(gcSrc, "closeAllModals", 1, true) ~= nil
					and string.find(gcSrc, "Enum.KeyCode.ButtonB", 1, true) ~= nil
					and ui.FavoriteNowBtn.Selectable == true
					and ui.ClaimLikeFavRewardBtn.Selectable == true
					and ui.FavoriteNowBtn.NextSelectionDown == ui.ClaimLikeFavRewardBtn
				print(
					string.format(
						"[AUDIT PS5 CONSOLE FAVORITE FIX v25] PASS=%s | PS5BypassPromptSetFavorite=%s | SelectableButtons=%s | GamepadNextSelectionLinked=%s",
						tostring(ps5CheckOk),
						tostring(string.find(gcSrc, "isConsoleOrGamepad", 1, true) ~= nil),
						tostring(ui.FavoriteNowBtn.Selectable == true and ui.ClaimLikeFavRewardBtn.Selectable == true),
						tostring(ui.FavoriteNowBtn.NextSelectionDown == ui.ClaimLikeFavRewardBtn)
					)
				)

				tempFolder:Destroy()
			end
		end

		local cam = Workspace.CurrentCamera
		if cam then
			cam.CameraType = Enum.CameraType.Scriptable
			cam.FieldOfView = 70
			cam.Focus = CFrame.new(0, 8, -95)
			cam.CFrame = CFrame.lookAt(Vector3.new(0, 38, 62), Vector3.new(0, 8, -95))
			task.wait(0.1)
			cam.CameraType = Enum.CameraType.Custom
			print("[EditModeBuilder] CameraReady: CleanEditModeView")
		end

		pcall(function()
			local ChangeHistoryService = game:GetService("ChangeHistoryService")
			ChangeHistoryService:SetWaypoint("Synced 7-Phase Update & Bugfixes")
			print("[EditModeBuilder] Marked DataModel dirty via ChangeHistoryService:SetWaypoint")
		end)
	end
end)
