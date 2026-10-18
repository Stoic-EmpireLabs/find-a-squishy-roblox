--!strict
--[[
	GameClient.client.luau
	Phase 5: Premium Simulator HUD, Live CanvasGroup Progress Bars, ViewportFrame 3D Previews & Smooth Hover Animations
	  - Top-Center Live Progress Bars (CanvasGroup + UICorner + UIGradient + UIStroke + math.clamp):
	      * 117 Squishy Collection Progress Bar (0 / 117 — 0% to 100%)
	      * Next Stage Speed Unlock Progress Bar
	  - Smooth TweenService Button Hover & Click Animations:
	      * Every sidebar, top-bar, bottom-left, and modal button (AnchorPoint = 0.5, 0.5) smoothly scales up (1.08x)
	        and shifts color on MouseEnter, shrinks (0.94x) on click, and restores on MouseLeave.
	  - RichText Markup & Responsive Constraints (UIAspectRatioConstraint, UITextSizeConstraint) across all HUD panels
	    for crisp scaling on PC, Phone, and Tablet.
	  - 3D ViewportFrame Rotating Squishy Previews inside the 📘 Squishy Index (0/117) so each card shows a real 3D model
	    of that Squishy that zooms and spins when you hover over it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SlimeData = require(Shared:WaitForChild("SlimeData"))
local UIBuilder = require(Shared:WaitForChild("UIBuilder"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateSyncEvent = Remotes:WaitForChild("StateSync") :: RemoteEvent
local EggCapturedEvent = Remotes:WaitForChild("SquishyCaptured") :: RemoteEvent
local GuardianAlertEvent = Remotes:WaitForChild("GuardianAlert") :: RemoteEvent
local BuySpeedUpgradeEvent = Remotes:WaitForChild("BuySpeedUpgrade") :: RemoteEvent
local RebirthRequestEvent = Remotes:WaitForChild("RebirthRequest") :: RemoteEvent
local ClaimDailyRewardEvent = Remotes:WaitForChild("ClaimDailyReward") :: RemoteEvent
local ClaimPlaytimeRewardEvent = Remotes:WaitForChild("ClaimPlaytimeReward") :: RemoteEvent
local ToggleSloMoEvent = Remotes:WaitForChild("ToggleSloMo") :: RemoteEvent
local SpinWheelRequestEvent = Remotes:WaitForChild("SpinWheelRequest") :: RemoteEvent
local BuySpinCashEvent = Remotes:WaitForChild("BuySpinCash") :: RemoteEvent
local BuyRobuxItemEvent = Remotes:WaitForChild("BuyRobuxItem") :: RemoteEvent
local OpenModalEvent = Remotes:WaitForChild("OpenModal") :: RemoteEvent
local GetInitialStateFunc = Remotes:WaitForChild("GetInitialState") :: RemoteFunction

local ui = UIBuilder.CreateHUD(playerGui)

local toastToken = 0
local function showToast(msg: string, bgColor: Color3?)
	toastToken += 1
	local myToken = toastToken
	ui.AlertToast.BackgroundColor3 = bgColor or Color3.fromRGB(215, 45, 65)
	ui.AlertToast.Text = "<b>" .. msg .. "</b>"
	ui.AlertToast.Visible = true
	task.delay(3.6, function()
		if toastToken == myToken then
			ui.AlertToast.Visible = false
		end
	end)
end

-- Wire Top-Bar, Left 2x3 Sidebar, Right Dock, Bottom-Left & Modal Buttons
ui.TopIndexBtn.MouseButton1Click:Connect(function()
	ui.IndexModal.Visible = not ui.IndexModal.Visible
	ui.ShopModal.Visible = false
	ui.SpinModal.Visible = false
end)

ui.TopSpeedBtn.MouseButton1Click:Connect(function()
	BuySpeedUpgradeEvent:FireServer()
end)

ui.ShopBtn.MouseButton1Click:Connect(function()
	ui.ShopModal.Visible = not ui.ShopModal.Visible
	ui.IndexModal.Visible = false
	ui.SpinModal.Visible = false
end)

ui.IndexBtn.MouseButton1Click:Connect(function()
	ui.IndexModal.Visible = not ui.IndexModal.Visible
	ui.ShopModal.Visible = false
	ui.SpinModal.Visible = false
end)

ui.DailyBtn.MouseButton1Click:Connect(function()
	ui.SpinModal.Visible = not ui.SpinModal.Visible
	ui.ShopModal.Visible = false
	ui.IndexModal.Visible = false
end)

ui.SloMoBtn.MouseButton1Click:Connect(function()
	ToggleSloMoEvent:FireServer()
end)

ui.WheelBtn.MouseButton1Click:Connect(function()
	ui.SpinModal.Visible = not ui.SpinModal.Visible
	ui.ShopModal.Visible = false
	ui.IndexModal.Visible = false
end)

ui.VIPBtn.MouseButton1Click:Connect(function()
	ui.ShopModal.Visible = true
	ui.IndexModal.Visible = false
	ui.SpinModal.Visible = false
end)

ui.EggsDockBtn.MouseButton1Click:Connect(function()
	ui.IndexModal.Visible = not ui.IndexModal.Visible
	ui.ShopModal.Visible = false
	ui.SpinModal.Visible = false
end)

ui.SpeedDockBtn.MouseButton1Click:Connect(function()
	BuySpeedUpgradeEvent:FireServer()
end)

ui.RebirthDockBtn.MouseButton1Click:Connect(function()
	RebirthRequestEvent:FireServer()
end)

ui.SpeedPlusBtn.MouseButton1Click:Connect(function()
	BuySpeedUpgradeEvent:FireServer()
end)

ui.CashPlusBtn.MouseButton1Click:Connect(function()
	BuyRobuxItemEvent:FireServer("CashPack5K")
end)

ui.IndexClose.MouseButton1Click:Connect(function()
	ui.IndexModal.Visible = false
end)

ui.ShopClose.MouseButton1Click:Connect(function()
	ui.ShopModal.Visible = false
end)

ui.SpinClose.MouseButton1Click:Connect(function()
	ui.SpinModal.Visible = false
end)

for passKey, btn in pairs(ui.PassButtonsByKey) do
	btn.MouseButton1Click:Connect(function()
		BuyRobuxItemEvent:FireServer(passKey)
	end)
end

for dpKey, btn in pairs(ui.DevProductButtons) do
	btn.MouseButton1Click:Connect(function()
		BuyRobuxItemEvent:FireServer(dpKey)
	end)
end

ui.BuySpeedBtn.MouseButton1Click:Connect(function()
	BuySpeedUpgradeEvent:FireServer()
end)

ui.RebirthBtn.MouseButton1Click:Connect(function()
	RebirthRequestEvent:FireServer()
end)

ui.SpinNowBtn.MouseButton1Click:Connect(function()
	SpinWheelRequestEvent:FireServer()
end)

ui.BuySpinCashBtn.MouseButton1Click:Connect(function()
	BuySpinCashEvent:FireServer()
end)

ui.BuySpinRobuxBtn.MouseButton1Click:Connect(function()
	BuyRobuxItemEvent:FireServer("BuySpinRobux")
end)

for idx, ptBtn in ipairs(ui.PlaytimeButtons) do
	ptBtn.MouseButton1Click:Connect(function()
		ClaimPlaytimeRewardEvent:FireServer(idx)
	end)
end

ui.ClaimDailyModalBtn.MouseButton1Click:Connect(function()
	ClaimDailyRewardEvent:FireServer()
end)

-- Cache cosmetic client-side rotors, Moving Crystal Platforms & GateBarriers once
local cachedCosmeticRotors: { { Part: BasePart, Speed: number, Mode: string } } = {}
local cachedCrystalPlatforms: { { Part: BasePart, Index: number, BaseX: number, BaseY: number, BaseZ: number } } = {}
local cachedGateBarriers: { BasePart } = {}

local function refreshWorldCaches()
	local squishyWorld = Workspace:FindFirstChild("SquishyWorld")
	if not squishyWorld then
		return
	end
	table.clear(cachedCosmeticRotors)
	table.clear(cachedCrystalPlatforms)
	table.clear(cachedGateBarriers)

	local obsFolder = squishyWorld:FindFirstChild("DynamicObstacles")
	if obsFolder then
		for _, child in ipairs(obsFolder:GetChildren()) do
			if child:IsA("BasePart") then
				if child:GetAttribute("SpinSpeed") and not child:GetAttribute("HazardDropEgg") then
					local mode = "Y"
					if child:GetAttribute("WindmillRotor") then
						mode = "Z"
					elseif child:GetAttribute("SpinWheelRotor") then
						mode = "X"
					end
					table.insert(cachedCosmeticRotors, {
						Part = child,
						Speed = child:GetAttribute("SpinSpeed") :: number,
						Mode = mode,
					})
				elseif child:GetAttribute("CrystalPlatform") then
					table.insert(cachedCrystalPlatforms, {
						Part = child,
						Index = (child:GetAttribute("CrystalPlatform") :: number?) or 1,
						BaseX = (child:GetAttribute("BaseX") :: number?) or child.Position.X,
						BaseY = (child:GetAttribute("BaseY") :: number?) or child.Position.Y,
						BaseZ = (child:GetAttribute("BaseZ") :: number?) or child.Position.Z,
					})
				end
			end
		end
	end

	local levelsFolder = squishyWorld:FindFirstChild("Levels")
	if levelsFolder then
		for _, lvlFolder in ipairs(levelsFolder:GetChildren()) do
			for _, desc in ipairs(lvlFolder:GetDescendants()) do
				if desc:IsA("BasePart") and string.find(desc.Name, "^GateBarrier_") then
					table.insert(cachedGateBarriers, desc)
				end
			end
		end
	end
end

task.spawn(function()
	Workspace:WaitForChild("SquishyWorld", 10)
	task.wait(0.2)
	refreshWorldCaches()
end)

local clientStartClock = os.clock()
local rotorAccum = 0
local hoverSpinAngle = 0

-- Rotate the hovered 3D ViewportFrame Squishy card + Featured 3D ViewportFrames + nearby cosmetic rotors at 30Hz
RunService.RenderStepped:Connect(function(dt: number)
	hoverSpinAngle += dt * 2.2

	if ui.IndexModal.Visible or ui.ShopModal.Visible or ui.SpinModal.Visible then
		for _, entry in ipairs(ui.RotatingViewportModels) do
			if entry.Model and entry.Model.Parent then
				entry.Model:PivotTo(entry.BaseCFrame * CFrame.Angles(0, hoverSpinAngle * (entry.Speed / 2.2), 0))
			end
		end

		local hoveredCard = ui.GetActiveHoveredCard()
		if hoveredCard and hoveredCard.SquishyModel and hoveredCard.SquishyModel.Parent then
			hoveredCard.SquishyModel:PivotTo(
				hoveredCard.BasePivot
					* CFrame.new(0, math.sin(hoverSpinAngle * 2.0) * 0.12, 0)
					* CFrame.Angles(0, hoverSpinAngle, 0)
			)
		end
	end

	rotorAccum += dt
	if rotorAccum < 0.033 then
		return
	end
	rotorAccum = 0

	local cam = Workspace.CurrentCamera
	local camPos = if cam then cam.CFrame.Position else Vector3.new(0, 0, 0)
	local elapsed = os.clock() - clientStartClock

	for _, r in ipairs(cachedCosmeticRotors) do
		local p = r.Part
		if p and p.Parent and (p.Position - camPos).Magnitude <= 165 then
			if r.Mode == "Z" then
				p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, 0, elapsed * r.Speed)
			elseif r.Mode == "X" then
				p.CFrame = CFrame.new(p.Position) * CFrame.Angles(elapsed * r.Speed, 0, 0)
			else
				p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, elapsed * r.Speed, 0)
			end
		end
	end

	for _, cp in ipairs(cachedCrystalPlatforms) do
		local p = cp.Part
		if p and p.Parent and (p.Position - camPos).Magnitude <= 165 then
			local phase = elapsed * 1.6 + cp.Index * 1.1
			local newX = cp.BaseX + math.sin(phase) * 3.2
			local newY = cp.BaseY + math.cos(phase * 1.3) * 1.2
			p.CFrame = CFrame.new(newX, newY, cp.BaseZ) * CFrame.Angles(0, 0, math.rad(90))
		end
	end
end)

-- Update Local Gate Barriers, Live CanvasGroup Progress Bars (math.clamp) & HUD on StateSync
local barTweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local lastRenderedFoundCount = -1
local PLAYTIME_THRESHOLDS = { 120, 300, 600, 900, 1800 }
local PLAYTIME_KEYS = { "2m", "5m", "10m", "15m", "30m" }

local function formatMMSS(sec: number): string
	local s = math.max(0, math.floor(sec))
	return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

local function applyStateToUI(state: any)
	local spd = state.SpeedStat or 18
	local cash = state.Coins or 0
	local foundCount = state.FoundCount or 0
	local totalSquishies = state.TotalSquishies or 117

	ui.SpeedCounterLbl.Text = string.format("⚡ <b>%d</b>", spd)
	ui.CashCounterLbl.Text = string.format("💰 <b>$%d</b>", cash)

	local carriedCount = state.CarriedEggCount or (if state.CarriedEggId then 1 else 0)
	local maxCarry = state.MaxCarryCapacity or 1
	local shieldRem = state.BossShieldRemaining or 0

	if state.CarriedEggId then
		local sData = SlimeData.ById[state.CarriedEggId]
		local eggName = if sData then string.upper(sData.Name) else "EGG"
		local shieldTag = if shieldRem > 0 then string.format("  [🛡️ SHIELD %ds]", shieldRem) else ""
		ui.TopBannerLabel.Text = string.format(
			"🚨 <b>CARRYING %s (%d/%d EGGS)!</b> RUN TO PLOT #%d INCUBATOR!%s 🚨",
			eggName,
			carriedCount,
			maxCarry,
			state.PlotIndex or 1,
			shieldTag
		)
		ui.TopContainer.BackgroundColor3 = Color3.fromRGB(165, 32, 52)
	else
		local boostExtras = ""
		if shieldRem > 0 then
			boostExtras ..= string.format("  |  🛡️ <font color='#FFE865'>Shield %ds</font>", shieldRem)
		end
		if (state.SpinCashBoostRemaining or 0) > 0 then
			boostExtras ..= string.format("  |  🎡 <font color='#FF95FF'>%dx Cash (%ds)</font>", state.SpinCashMultiplier or 2, state.SpinCashBoostRemaining)
		end
		ui.TopBannerLabel.Text = string.format(
			"✨ <b>FIND MY SQUISHY!</b>  |  Plot #%d  |  ⚡ <font color='#65FF8F'>$%d/sec</font>  |  Rebirths: %d%s",
			state.PlotIndex or 1,
			state.PassiveIncomeRate or 0,
			state.Rebirths or 0,
			boostExtras
		)
		ui.TopContainer.BackgroundColor3 = Color3.fromRGB(18, 22, 40)
	end

	-- 1. 117 Squishy Collection Progress Bar (0 / 117 — 0% to 100%) using math.clamp
	local squishyRatio = math.clamp(foundCount / math.max(1, totalSquishies), 0, 1)
	TweenService:Create(ui.SquishyBarFill, barTweenInfo, {
		Size = UDim2.fromScale(squishyRatio, 1),
	}):Play()
	ui.SquishyBarText.Text = string.format(
		"📘 <b>117 SQUISHY COLLECTION:</b> <font color='#75FF9E'>%d / %d (%d%%)</font>",
		foundCount,
		totalSquishies,
		math.floor(squishyRatio * 100)
	)

	-- 2. Next Stage Speed Unlock Progress Bar using math.clamp
	local nextGoal = state.NextStageSpeedGoal or 140
	local nextStageName = state.NextStageName or "MAX STAGE"
	local speedRatio = math.clamp(spd / math.max(1, nextGoal), 0, 1)
	TweenService:Create(ui.SpeedBarFill, barTweenInfo, {
		Size = UDim2.fromScale(speedRatio, 1),
	}):Play()
	if nextStageName == "MAX STAGE" then
		ui.SpeedBarText.Text = string.format("⚡ <b>ALL 5 BIOME STAGES UNLOCKED!</b> <font color='#FFE865'>(Speed: %d — 100%%)</font>", spd)
	else
		ui.SpeedBarText.Text = string.format(
			"⚡ <b>NEXT STAGE SPEED UNLOCK (%s):</b> <font color='#FFE865'>%d / %d SPEED (%d%%)</font>",
			nextStageName,
			spd,
			nextGoal,
			math.floor(speedRatio * 100)
		)
	end

	local sloCap = ui.SloMoBtn:FindFirstChild("Caption") :: TextLabel?
	if sloCap then
		sloCap.Text = if state.SloMoActive then "<b>SloMo ON</b>" else "<b>SloMo</b>"
	end

	local spdGain = if state.OwnedPasses and state.OwnedPasses["2xSpeed"] then 8 else 4
	ui.BuySpeedBtn.Text = string.format("🦖 <b>Upgrade Treadmill (+%d Speed) [Lv.%d] - $%d</b>", spdGain, state.SpeedLevel or 1, state.NextSpeedCost or 50)
	ui.RebirthBtn.Text = string.format("✨ <b>Rebirth #%d (+50%% Cash) - $%d</b>", (state.Rebirths or 0) + 1, state.NextRebirthCost or 5000)
	ui.IndexTitle.Text = string.format("📘 <b>3D SQUISHY & EGG INDEX (%d / %d)</b>", foundCount, totalSquishies)

	-- Update Spin Wheel Free Spin (5m) & Bonus Spins Button
	local freeSpinWait = state.FreeSpinReadyIn or 0
	local bonusSpins = state.BonusSpins or 0
	if freeSpinWait <= 0 then
		ui.SpinNowBtn.Text = "🎡 <b>FREE SPIN READY! (1 Free / 5m)</b>"
		ui.SpinNowBtn.BackgroundColor3 = Color3.fromRGB(55, 225, 110)
	elseif bonusSpins > 0 then
		ui.SpinNowBtn.Text = string.format("🎡 <b>USE BONUS SPIN (%d LEFT)!</b>", bonusSpins)
		ui.SpinNowBtn.BackgroundColor3 = Color3.fromRGB(255, 195, 45)
	else
		ui.SpinNowBtn.Text = string.format("⏳ <b>Next Free Spin: %s</b>", formatMMSS(freeSpinWait))
		ui.SpinNowBtn.BackgroundColor3 = Color3.fromRGB(95, 110, 145)
	end

	-- Update 5 Playtime Milestone Chest Buttons (2m, 5m, 10m, 15m, 30m)
	local playtimeSec = state.PlaytimeSeconds or 0
	local claimedPlaytime = state.ClaimedPlaytime or {}
	for idx, ptBtn in ipairs(ui.PlaytimeButtons) do
		local reqSec = PLAYTIME_THRESHOLDS[idx] or 120
		local msKey = PLAYTIME_KEYS[idx] or tostring(idx)
		if claimedPlaytime[tostring(idx)] or claimedPlaytime[msKey] then
			ptBtn.Text = "✅ <b>CLAIMED</b>"
			ptBtn.BackgroundColor3 = Color3.fromRGB(48, 125, 72)
		elseif playtimeSec >= reqSec then
			ptBtn.Text = "🟢 <b>CLAIM!</b>"
			ptBtn.BackgroundColor3 = Color3.fromRGB(55, 225, 110)
		else
			ptBtn.Text = string.format("⏳ <b>%s</b>", formatMMSS(reqSec - playtimeSec))
			ptBtn.BackgroundColor3 = Color3.fromRGB(68, 78, 110)
		end
	end

	ui.ClaimDailyModalBtn.Text = string.format(
		"🎁 <b>CLAIM DAILY LOGIN STREAK CHEST (DAY %d: +$1,500 CASH + +6 SPEED)</b>",
		(state.DailyStreak or 0) + 1
	)

	if state.OwnedPasses then
		for k, btn in pairs(ui.PassButtonsByKey) do
			if state.OwnedPasses[k] then
				btn.Text = "✅ <b>OWNED & ACTIVE</b>"
				btn.BackgroundColor3 = Color3.fromRGB(75, 225, 115)
			end
		end
	end

	if state.Found and foundCount ~= lastRenderedFoundCount then
		lastRenderedFoundCount = foundCount
		for sId, cardInfo in pairs(ui.IndexCards) do
			local sData = SlimeData.ById[sId]
			if sData then
				if state.Found[sId] then
					cardInfo.Frame.BackgroundColor3 = Color3.fromRGB(44, 78, 62)
					cardInfo.Status.Text = string.format("✅ <b>FOUND ($%d/s)</b>", sData.IncomePerSec)
					cardInfo.Status.TextColor3 = Color3.fromRGB(110, 255, 140)
				else
					cardInfo.Frame.BackgroundColor3 = Color3.fromRGB(32, 38, 64)
					cardInfo.Status.Text = string.format("🔒 <b>$%d/s</b>", sData.IncomePerSec)
					cardInfo.Status.TextColor3 = Color3.fromRGB(170, 180, 205)
				end
			end
		end
	end

	-- Update cached Biome Gate Barriers locally based on player's SpeedStat
	if #cachedGateBarriers == 0 then
		refreshWorldCaches()
	end
	if state.UnlockedLevels then
		for _, desc in ipairs(cachedGateBarriers) do
			if desc and desc.Parent then
				local lvlId = tostring(desc:GetAttribute("LevelId") or 1)
				local unlocked = state.UnlockedLevels[lvlId] == true
				desc.CanCollide = not unlocked
				desc.Transparency = if unlocked then 0.88 else 0.32
				if unlocked then
					desc.Color = Color3.fromRGB(85, 255, 130)
				end
			end
		end
	end
end

StateSyncEvent.OnClientEvent:Connect(applyStateToUI)

OpenModalEvent.OnClientEvent:Connect(function(modalName: string)
	if modalName == "SpinWheel" or modalName == "DailyRewards" then
		ui.SpinModal.Visible = true
		ui.ShopModal.Visible = false
		ui.IndexModal.Visible = false
	elseif modalName == "RobuxShop" then
		ui.ShopModal.Visible = true
		ui.SpinModal.Visible = false
		ui.IndexModal.Visible = false
	end
end)

local popupToken = 0
local confettiColors = {
	Color3.fromRGB(255, 85, 125),
	Color3.fromRGB(85, 225, 255),
	Color3.fromRGB(255, 230, 65),
	Color3.fromRGB(95, 250, 135),
	Color3.fromRGB(205, 105, 255),
}

local function showYouFoundPopup(sData: any)
	popupToken += 1
	local myToken = popupToken
	local rarity = tostring(sData.Rarity or "Common")
	local bodyCol = sData.BodyColor or sData.Color or Color3.fromRGB(95, 225, 255)
	ui.YfBadge.BackgroundColor3 = bodyCol
	ui.YfRarityLbl.Text = string.format("<b>[%s]  •  +$%d/sec</b>", string.upper(rarity), sData.IncomePerSec or 10)
	ui.YfRarityLbl.TextColor3 = bodyCol:Lerp(Color3.fromRGB(255, 255, 255), 0.25)
	ui.YfNameLbl.Text = "<b>" .. tostring(sData.Name) .. "</b>"

	ui.YouFoundPopup.Size = UDim2.fromOffset(220, 120)
	ui.YouFoundPopup.Visible = true
	TweenService:Create(
		ui.YouFoundPopup,
		TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(380, 210) }
	):Play()

	for i = 1, 14 do
		local piece = Instance.new("Frame")
		piece.Size = UDim2.fromOffset(12, 12)
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Position = UDim2.fromScale(0.5, 0.5)
		piece.BackgroundColor3 = confettiColors[((i - 1) % #confettiColors) + 1]
		piece.Rotation = (i * 27) % 360
		piece.Parent = ui.YouFoundPopup
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 3)
		c.Parent = piece

		local angle = math.rad((i / 14) * 360)
		local targetX = 0.5 + math.cos(angle) * 0.68
		local targetY = 0.5 + math.sin(angle) * 0.68
		TweenService:Create(
			piece,
			TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.fromScale(targetX, targetY),
				BackgroundTransparency = 1,
				Rotation = piece.Rotation + 140,
			}
		):Play()
		task.delay(0.8, function()
			if piece and piece.Parent then
				piece:Destroy()
			end
		end)
	end

	task.delay(2.8, function()
		if popupToken == myToken then
			ui.YouFoundPopup.Visible = false
		end
	end)
end

EggCapturedEvent.OnClientEvent:Connect(function(info: any)
	if type(info) == "table" and info.SquishyId then
		local sData = SlimeData.ById[info.SquishyId]
		if sData then
			showYouFoundPopup(sData)
			showToast(
				string.format("✨ YOU FOUND [%s] %s! Equip it from your Hotbar & place it on a Pedestal! (+$%d/s)", string.upper(tostring(sData.Rarity or "Common")), string.upper(sData.Name), sData.IncomePerSec),
				Color3.fromRGB(45, 175, 85)
			)
		end
	end
end)

GuardianAlertEvent.OnClientEvent:Connect(function(msg: string)
	if type(msg) == "string" then
		showToast(msg, Color3.fromRGB(215, 50, 65))
	end
end)

task.spawn(function()
	local ok, initData = pcall(function()
		return GetInitialStateFunc:InvokeServer()
	end)
	if ok and type(initData) == "table" then
		applyStateToUI(initData)
	end
end)
