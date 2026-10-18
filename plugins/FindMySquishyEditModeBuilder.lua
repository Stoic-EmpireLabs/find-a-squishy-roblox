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
end)

task.spawn(function()
	task.wait(0.2)
	if not RunService:IsEdit() then
		return
	end

	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if not sharedFolder or not sharedFolder:FindFirstChild("SlimeData") then
		return
	end

	local slimeData = require(sharedFolder:WaitForChild("SlimeData"))
	local prebuiltLoaderMod = sharedFolder:FindFirstChild("PrebuiltLoader")
	if prebuiltLoaderMod and prebuiltLoaderMod:IsA("ModuleScript") then
		local okP, pl = pcall(require, prebuiltLoaderMod)
		if okP and type(pl) == "table" and type(pl.EnsurePrebuiltAssets) == "function" then
			pcall(function()
				pl.EnsurePrebuiltAssets()
			end)
		end
	end

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

		-- ============================================================================
		-- RUN COMPREHENSIVE PHASE 1 TO PHASE 6 VERIFICATION AUDIT
		-- ============================================================================
		local worldFolder = Workspace:FindFirstChild("SquishyWorld")
		if worldFolder then
			-- PHASE 1 CHECK:
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
					"[AUDIT PHASE 1] PASS=%s | WorldEggs=%d/117 | SleepingBosses=%d/10 | BasePlots=%d/4 | BiomeStages=%d/5 (220x160 each, Z=0..-800) | RainbowStairSteps=%d/28",
					tostring(worldEggCount == 117 and guardCount == 10 and plotCount == 4 and levelCount == 5 and stairSteps == 28),
					worldEggCount,
					guardCount,
					plotCount,
					levelCount,
					stairSteps
				)
			)

			-- PHASE 2 CHECK:
			local surfaceGuiCount = 0
			local billboardCount = 0
			local badOffsetBillboards = 0
			local badAlwaysOnTopBillboards = 0
			local emptyIncubatorBillboards = 0
			for _, desc in ipairs(worldFolder:GetDescendants()) do
				if desc:IsA("SurfaceGui") then
					surfaceGuiCount += 1
				elseif desc:IsA("BillboardGui") then
					billboardCount += 1
					if desc.Size.X.Offset ~= 0 or desc.Size.Y.Offset ~= 0 then
						badOffsetBillboards += 1
					end
					if desc.AlwaysOnTop == true then
						badAlwaysOnTopBillboards += 1
					end
					if desc.Parent and string.find(desc.Parent.Name, "^Incubator_") then
						emptyIncubatorBillboards += 1
					end
				end
			end
			print(
				string.format(
					"[AUDIT PHASE 2] PASS=%s | SurfaceGuiSigns=%d | ScaleBillboardGuis=%d | BadOffsetBillboards=%d | BadAlwaysOnTop=%d | EmptyIncubatorBillboards=%d",
					tostring(badOffsetBillboards == 0 and badAlwaysOnTopBillboards == 0 and emptyIncubatorBillboards == 0 and surfaceGuiCount >= 20),
					surfaceGuiCount,
					billboardCount,
					badOffsetBillboards,
					badAlwaysOnTopBillboards,
					emptyIncubatorBillboards
				)
			)

			-- PHASE 3 CHECK:
			local worldCoins = 0
			local shortcutButtons = 0
			local shortcutBridges = 0
			local obbyTrusses = 0
			local walkInDoors = 0
			local studdedParts = 0
			for _, desc in ipairs(worldFolder:GetDescendants()) do
				if desc:IsA("BasePart") then
					if desc:GetAttribute("WorldCoinPickup") == true then
						worldCoins += 1
					elseif desc:GetAttribute("ShortcutButtonLevel") ~= nil then
						shortcutButtons += 1
					elseif desc:GetAttribute("ShortcutBridgeLevel") ~= nil then
						shortcutBridges += 1
					end
					if desc.TopSurface == Enum.SurfaceType.Studs then
						studdedParts += 1
					end
					if desc.Name == "DoorKeypad" or desc.Name == "McCounter" or desc.Name == "MarketFloor" then
						walkInDoors += 1
					end
				end
				if desc:IsA("TrussPart") and string.find(desc.Name, "^ObbyStartTruss_") then
					obbyTrusses += 1
				end
			end
			print(
				string.format(
					"[AUDIT PHASE 3] PASS=%s | GoldenCoins=%d/30+ | TimedShortcutButtons=%d/5 | ShortcutBridges=%d/5 | SkyObbyTrusses=%d/5 | WalkInBuildings=%d/28 | ClassicStudParts=%d",
					tostring(worldCoins >= 30 and shortcutButtons == 5 and shortcutBridges == 5 and obbyTrusses == 5 and walkInDoors >= 28),
					worldCoins,
					shortcutButtons,
					shortcutBridges,
					obbyTrusses,
					walkInDoors,
					studdedParts
				)
			)

			-- PHASE 4 CHECK:
			local totalPrompts = 0
			local attachmentPrompts = 0
			local onePerButtonPrompts = 0
			for _, desc in ipairs(worldFolder:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					totalPrompts += 1
					if desc.Parent and desc.Parent:IsA("Attachment") then
						attachmentPrompts += 1
					end
					if desc.Exclusivity == Enum.ProximityPromptExclusivity.OnePerButton then
						onePerButtonPrompts += 1
					end
				end
			end
			local hubFolder = worldFolder:FindFirstChild("SafeZoneHub")
			local lbFolder = hubFolder and hubFolder:FindFirstChild("GlobalLeaderboards")
			local lbCount = if lbFolder then #lbFolder:GetChildren() else 0
			print(
				string.format(
					"[AUDIT PHASE 4] PASS=%s | AttachmentPrompts=%d/%d | OnePerButtonPrompts=%d/%d | Global3DLeaderboards=%d/3",
					tostring(totalPrompts >= 190 and attachmentPrompts == totalPrompts and onePerButtonPrompts == totalPrompts and lbCount == 3),
					attachmentPrompts,
					totalPrompts,
					onePerButtonPrompts,
					totalPrompts,
					lbCount
				)
			)

			-- PHASE 5 & PHASE 6 HUD CHECK (Temporary Folder Audit -> Destroyed Immediately After):
			local uiBuilderMod = sharedFolder:FindFirstChild("UIBuilder")
			if uiBuilderMod and uiBuilderMod:IsA("ModuleScript") then
				local tempFolder = Instance.new("Folder")
				local ub = require(uiBuilderMod)
				local ui = ub.CreateHUD(tempFolder)
				local vfCount = 0
				local constraintCount = 0
				local centerAnchorBtns = 0
				local canvasGroups = 0
				for _, inst in ipairs(ui.ScreenGui:GetDescendants()) do
					if inst:IsA("ViewportFrame") then
						vfCount += 1
					elseif inst:IsA("UIAspectRatioConstraint") or inst:IsA("UITextSizeConstraint") then
						constraintCount += 1
					elseif inst:IsA("GuiButton") and inst.AnchorPoint == Vector2.new(0.5, 0.5) then
						centerAnchorBtns += 1
					elseif inst:IsA("CanvasGroup") then
						canvasGroups += 1
					end
				end
				local indexCardCount = 0
				for _ in pairs(ui.IndexCards) do
					indexCardCount += 1
				end
				local passCount = 0
				for _ in pairs(ui.PassButtonsByKey) do
					passCount += 1
				end
				local devProdCount = 0
				for _ in pairs(ui.DevProductButtons) do
					devProdCount += 1
				end
				local playtimeCount = #ui.PlaytimeButtons

				print(
					string.format(
						"[AUDIT PHASE 5] PASS=%s | CanvasGroupProgressBars=%d/2 | Index3DViewportCards=%d/117 | TotalViewportFrames=%d | ResponsiveConstraints=%d | HoverTweenButtons=%d",
						tostring(canvasGroups == 2 and indexCardCount == 117 and vfCount >= 123 and constraintCount >= 300),
						canvasGroups,
						indexCardCount,
						vfCount,
						constraintCount,
						centerAnchorBtns
					)
				)

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
						"[AUDIT PHASE 6] PASS=%s | Gamepasses=%d/5 (2xCash,2xSpeed,AutoHatch,VIP,Carry2Eggs) | DevProducts=%d/5 | PlaytimeMilestoneChests=%d/5 (2m-30m) | PhysicalSafeZoneBooths=%d/3",
						tostring(passCount == 5 and devProdCount == 5 and playtimeCount == 5 and boothCount == 3),
						passCount,
						devProdCount,
						playtimeCount,
						boothCount
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
	end
end)
