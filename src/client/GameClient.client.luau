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
local TreadmillTapBoostEvent = Remotes:WaitForChild("TreadmillTapBoost") :: RemoteEvent
local RebirthRequestEvent = Remotes:WaitForChild("RebirthRequest") :: RemoteEvent
local ClaimDailyRewardEvent = Remotes:WaitForChild("ClaimDailyReward") :: RemoteEvent
local ClaimPlaytimeRewardEvent = Remotes:WaitForChild("ClaimPlaytimeReward") :: RemoteEvent
local ToggleSloMoEvent = Remotes:WaitForChild("ToggleSloMo") :: RemoteEvent
local SetSpeedThrottleEvent = Remotes:WaitForChild("SetSpeedThrottle") :: RemoteEvent
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

-- Wire Top-Bar, Left 2x3 Sidebar, Right Dock, Bottom-Left, Speed Throttle (25%/50%/75%/100%) & Modal Buttons
if ui.SpeedThrottleButtons then
	for pct, btn in pairs(ui.SpeedThrottleButtons) do
		btn.MouseButton1Click:Connect(function()
			SetSpeedThrottleEvent:FireServer(pct / 100)
		end)
	end
end

if ui.TreadmillTurboBtn then
	ui.TreadmillTurboBtn.Activated:Connect(function()
		TreadmillTapBoostEvent:FireServer()
	end)
end

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

-- Cache cosmetic client-side rotors, Moving Crystal Platforms, GateBarriers & StageChecklistBoards once
local cachedCosmeticRotors: { { Part: BasePart, Speed: number, Mode: string } } = {}
local cachedCrystalPlatforms: { { Part: BasePart, Index: number, BaseX: number, BaseY: number, BaseZ: number } } = {}
local cachedGateBarriers: { BasePart } = {}
local cachedChecklistBoards: { BasePart } = {}

local function refreshWorldCaches()
	local squishyWorld = Workspace:FindFirstChild("SquishyWorld")
	if not squishyWorld then
		return
	end
	table.clear(cachedCosmeticRotors)
	table.clear(cachedCrystalPlatforms)
	table.clear(cachedGateBarriers)
	table.clear(cachedChecklistBoards)

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
				if desc:IsA("BasePart") then
					if string.find(desc.Name, "^GateBarrier_") then
						table.insert(cachedGateBarriers, desc)
					elseif string.find(desc.Name, "^StageChecklistBoard_") then
						table.insert(cachedChecklistBoards, desc)
					end
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

-- Authentic Creator Store Treadmill startRun(humanoid) animation controller (Asset 105125399134543 — RUN_ANIM_ID = "rbxassetid://507767714")
local RUN_ANIM_ID = "rbxassetid://507767714"
local activeTreadmillTrack: AnimationTrack? = nil
local activeTreadmillHumanoid: Humanoid? = nil

local function startRun(humanoid: Humanoid, animSpeed: number)
	if activeTreadmillHumanoid == humanoid and activeTreadmillTrack and activeTreadmillTrack.IsPlaying then
		activeTreadmillTrack:AdjustSpeed(animSpeed)
		return
	end
	if activeTreadmillTrack then
		pcall(function()
			activeTreadmillTrack:Stop(0.15)
		end)
		activeTreadmillTrack = nil
	end
	activeTreadmillHumanoid = humanoid
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local runAnim = humanoid:FindFirstChild("CreatorStoreTreadmillRunAnim") :: Animation?
	if not runAnim then
		runAnim = Instance.new("Animation")
		runAnim.Name = "CreatorStoreTreadmillRunAnim"
		runAnim.AnimationId = RUN_ANIM_ID
		runAnim.Parent = humanoid
	end
	pcall(function()
		local track = animator:LoadAnimation(runAnim :: Animation)
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = true
		track:Play(0.12)
		track:AdjustSpeed(animSpeed)
		activeTreadmillTrack = track
	end)
end

local function stopRun()
	if activeTreadmillTrack then
		pcall(function()
			activeTreadmillTrack:Stop(0.18)
		end)
		activeTreadmillTrack = nil
		activeTreadmillHumanoid = nil
	end
end

-- Rotate the hovered 3D ViewportFrame Squishy card + Featured 3D ViewportFrames + nearby cosmetic rotors at 30Hz
RunService.RenderStepped:Connect(function(dt: number)
	hoverSpinAngle += dt * 2.2

	-- Check if LocalPlayer is running on any Creator Store Treadmill belt (Plot 1-4 or Stage 1-8)
	local myChar = localPlayer.Character
	local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
	local onBelt = (myChar ~= nil) and (myHum ~= nil) and (myChar:GetAttribute("OnTreadmillBelt") == true)
	if ui.TreadmillTurboBtn then
		ui.TreadmillTurboBtn.Visible = onBelt
	end
	if onBelt and myHum and myChar then
		local animSpd = (myChar:GetAttribute("TreadmillAnimSpeed") :: number?) or 1.45
		startRun(myHum, animSpd)
	else
		stopRun()
	end

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

local latestState: any = nil

local function applyStateToUI(state: any)
	latestState = state
	local spd = state.SpeedStat or 18
	local cash = state.Coins or 0
	local foundCount = state.FoundCount or 0
	local totalSquishies = state.TotalSquishies or 117

	ui.SpeedCounterLbl.Text = string.format("⚡ <b>%s</b>", SlimeData.FormatNumber(spd))
	ui.CashCounterLbl.Text = string.format("💰 <b>$%s</b>", SlimeData.FormatNumber(cash))

	-- Highlight active HUD WalkSpeed Control Selector (25% / 50% / 75% / 100%)
	local activePct = math.round((state.SpeedThrottleRatio or 1.0) * 100)
	if ui.SpeedThrottleButtons then
		for pct, btn in pairs(ui.SpeedThrottleButtons) do
			local isSelected = math.abs(pct - activePct) <= 5
			btn.BackgroundColor3 = if isSelected then Color3.fromRGB(55, 215, 115) else Color3.fromRGB(34, 42, 68)
		end
	end

	local carriedCount = state.CarriedEggCount or (if state.CarriedEggId then 1 else 0)
	local maxCarry = state.MaxCarryCapacity or 1
	local shieldRem = state.BossShieldRemaining or 0

	if state.CarriedEggId then
		local sData = SlimeData.ById[state.CarriedEggId]
		local eggName = if sData then string.upper(sData.Name) else "EGG"
		local shieldTag = if shieldRem > 0 then string.format("  [🛡️ SHIELD %ds]", shieldRem) else ""
		ui.TopBannerLabel.Text = string.format(
			"🚨 <b>CARRYING %s (%d/%d EGGS)!</b> RUN TO PLOT #%d HATCHERY PEN!%s 🚨",
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
			"✨ <b>FIND MY SQUISHY!</b>  |  Plot #%d  |  ⚡ <font color='#65FF8F'>$%s/sec</font>  |  Rebirths: %d%s",
			state.PlotIndex or 1,
			SlimeData.FormatNumber(state.PassiveIncomeRate or 0),
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
	local nextGoal = state.NextStageSpeedGoal or 250
	local nextStageName = state.NextStageName or "MAX STAGE"
	local speedRatio = math.clamp(spd / math.max(1, nextGoal), 0, 1)
	TweenService:Create(ui.SpeedBarFill, barTweenInfo, {
		Size = UDim2.fromScale(speedRatio, 1),
	}):Play()
	if nextStageName == "MAX STAGE" then
		ui.SpeedBarText.Text = string.format(
			"⚡ <b>ALL 8 BIOME STAGES UNLOCKED!</b> <font color='#FFE865'>(Speed: %s — 100%%)</font>",
			SlimeData.FormatNumber(spd)
		)
	else
		ui.SpeedBarText.Text = string.format(
			"⚡ <b>NEXT STAGE UNLOCK (%s):</b> <font color='#FFE865'>%s / %s SPEED (%d%%)</font>",
			nextStageName,
			SlimeData.FormatNumber(spd),
			SlimeData.FormatNumber(nextGoal),
			math.floor(speedRatio * 100)
		)
	end

	local sloCap = ui.SloMoBtn:FindFirstChild("Caption") :: TextLabel?
	if sloCap then
		sloCap.Text = if state.SloMoActive then "<b>SloMo ON</b>" else "<b>SloMo</b>"
	end

	local curSpeedLvl = state.SpeedLevel or 1
	local nextTierIdx = math.clamp(curSpeedLvl + 1, 1, #SlimeData.TreadmillTiers)
	local nextTierData = SlimeData.TreadmillTiers[nextTierIdx] or SlimeData.TreadmillTiers[1]
	ui.BuySpeedBtn.Text = string.format(
		"🏃 <b>Upgrade Treadmill -> [%s] [Lv.%d] - $%s</b>",
		nextTierData.MultiplierLabel,
		curSpeedLvl + 1,
		SlimeData.FormatNumber(state.NextSpeedCost or 100)
	)
	ui.RebirthBtn.Text = string.format(
		"✨ <b>Rebirth #%d (+50%% Cash & Speed) - $%s</b>",
		(state.Rebirths or 0) + 1,
		SlimeData.FormatNumber(state.NextRebirthCost or 5000)
	)
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

	if state.Found then
		local sw = Workspace:FindFirstChild("SquishyWorld")
		local worldEggsFolder = sw and sw:FindFirstChild("WorldEggs")
		if worldEggsFolder then
			for sKey, isFound in pairs(state.Found) do
				if isFound then
					local sData = SlimeData.ById[sKey]
					local numId = if sData then (tonumber((sData :: any).UnlockOrder or (sData :: any).NumericId or sData.Id) or 1) else 999
					-- Collectible Squishies (#36-#117) permanently disappear on the client once collected!
					if numId > 35 then
						local m = worldEggsFolder:FindFirstChild("WorldEgg_" .. tostring(sKey)) or worldEggsFolder:FindFirstChild(tostring(sKey))
						if m then
							for _, d in ipairs(m:GetDescendants()) do
								if d:IsA("BasePart") then
									d.Transparency = 1
									d.CanTouch = false
									d.CanQuery = false
									d.CanCollide = false
								elseif d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("ParticleEmitter") then
									(d :: any).Enabled = false
								elseif d:IsA("Decal") or d:IsA("Texture") then
									d.Transparency = 1
								end
							end
						end
					end
				end
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

	-- Update cached Biome Gate Barriers & Sector 1 Stage Checklist Boards locally based on player's progress
	if #cachedGateBarriers == 0 or #cachedChecklistBoards == 0 then
		refreshWorldCaches()
	end
	if state.UnlockedLevels then
		for _, desc in ipairs(cachedGateBarriers) do
			if desc and desc.Parent then
				local lvlNum = tonumber(desc:GetAttribute("LevelId")) or 1
				local lvlId = tostring(lvlNum)
				local unlocked = state.UnlockedLevels[lvlId] == true
				desc.CanCollide = not unlocked
				desc.Transparency = if unlocked then 0.88 else 0.32
				desc.Color = if unlocked then Color3.fromRGB(85, 255, 130) else Color3.fromRGB(255, 65, 85)
				local levelInfo = SlimeData.Levels[lvlNum]
				if levelInfo and lvlNum > 1 then
					local prevFound, prevTotal = SlimeData.CountLevelProgress(state.Found or {}, lvlNum - 1)
					local prevPct = math.floor((prevFound / math.max(1, prevTotal)) * 100)
					local reqSpd = levelInfo.RequiredSpeed or 0
					local gateText = if unlocked
						then string.format(
							"✅ STAGE %d: %s — UNLOCKED!\n🏆 Stage %d 100%% Complete (%d/%d) • ⚡ %s Speed Reached!",
							lvlNum,
							string.upper(levelInfo.Name),
							lvlNum - 1,
							prevFound,
							prevTotal,
							SlimeData.FormatNumber(reqSpd)
						)
						else string.format(
							"🔒 STAGE %d: %s\n🎯 Stage %d Progress: %d/%d (%d%% — Need 100%%!)  •  ⚡ Speed: %s / %s",
							lvlNum,
							string.upper(levelInfo.Name),
							lvlNum - 1,
							prevFound,
							prevTotal,
							prevPct,
							SlimeData.FormatNumber(spd),
							SlimeData.FormatNumber(reqSpd)
						)
					for _, gDesc in ipairs((desc.Parent or desc):GetDescendants()) do
						if gDesc:IsA("TextLabel") then
							gDesc.Text = gateText
							gDesc.TextColor3 = if unlocked then Color3.fromRGB(115, 255, 150) else Color3.fromRGB(255, 240, 120)
						end
					end
				end
			end
		end
	end
	if state.Found then
		for _, board in ipairs(cachedChecklistBoards) do
			if board and board.Parent then
				local stageId = (board:GetAttribute("StageId") :: number?) or 1
				local levelInfo = SlimeData.Levels[stageId]
				local nextLevelInfo = SlimeData.Levels[stageId + 1]
				if levelInfo then
					local foundEggs = 0
					local totalEggs = 0
					local foundSquishies = 0
					local totalSquishiesInStage = 0
					for _, sData in ipairs(SlimeData.Slimes) do
						if sData.Level == stageId then
							local sKey = tostring(sData.Id)
							local numId = tonumber((sData :: any).UnlockOrder or (sData :: any).NumericId or sData.Id) or 1
							if numId <= 35 then
								totalEggs += 1
								if state.Found[sKey] then
									foundEggs += 1
								end
							else
								totalSquishiesInStage += 1
								if state.Found[sKey] then
									foundSquishies += 1
								end
							end
						end
					end
					local totalItems = math.max(1, totalEggs + totalSquishiesInStage)
					local pct = math.floor(((foundEggs + foundSquishies) / totalItems) * 100)
					local nextReqSpeed = if nextLevelInfo then (nextLevelInfo.RequiredSpeed or 0) else 0
					local nextReqText = if nextLevelInfo
						then string.format(
							"⚡ Next Gate (Stage %d): %s / %s Speed",
							stageId + 1,
							SlimeData.FormatNumber(spd),
							SlimeData.FormatNumber(nextReqSpeed)
						)
						else "👑 Final Stage: Complete 100% for Cosmic Mastery!"
					local statusPrefix = if pct >= 100 then "✅" else "🔓"
					local newText = string.format(
						"📋 STAGE %d: %s\n🥚 Boss Eggs: %d/%d  |  🧸 Squishies: %d/%d\n%s\n%s STAGE %d COMPLETION: %d%%",
						stageId,
						string.upper(levelInfo.Name),
						foundEggs,
						totalEggs,
						foundSquishies,
						totalSquishiesInStage,
						nextReqText,
						statusPrefix,
						stageId,
						pct
					)
					for _, d in ipairs(board:GetDescendants()) do
						if d:IsA("TextLabel") then
							d.Text = newText
							d.TextColor3 = if pct >= 100 then Color3.fromRGB(95, 255, 140) else Color3.fromRGB(255, 245, 125)
						end
					end
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

if ui.GuideToggleBtn and ui.HowToPlayModal then
	ui.GuideToggleBtn.MouseButton1Click:Connect(function()
		ui.HowToPlayModal.Visible = not ui.HowToPlayModal.Visible
	end)
end
if ui.HowToPlayClose and ui.HowToPlayModal then
	ui.HowToPlayClose.MouseButton1Click:Connect(function()
		ui.HowToPlayModal.Visible = false
	end)
end

local SoundService = game:GetService("SoundService")

-- Phase 5: Layered ASMR Squish/Pop + Rising Harmonic Combo Chime + Rarity Fanfare Audio
local function playLayeredASMRPickupSound(comboCount: number, rarity: string)
	-- Layer 1: Tactile Jelly Squish / Pop
	local squishSound = Instance.new("Sound")
	squishSound.Name = "ASMRSquishPop"
	squishSound.SoundId = "rbxassetid://9119713951"
	squishSound.Volume = 0.85
	squishSound.PlaybackSpeed = 0.95 + (math.random() * 0.14)
	squishSound.Parent = SoundService
	squishSound:Play()
	task.delay(1.5, function()
		if squishSound.Parent then
			squishSound:Destroy()
		end
	end)

	-- Layer 2: Rising-Pitch Harmonic Combo Chime (climbs in pitch with each consecutive pickup!)
	local comboChime = Instance.new("Sound")
	comboChime.Name = "ComboHarmonicChime"
	comboChime.SoundId = "rbxassetid://9113883106"
	comboChime.Volume = 0.75
	comboChime.PlaybackSpeed = math.clamp(1.0 + (math.max(1, comboCount) - 1) * 0.08, 1.0, 2.0)
	comboChime.Parent = SoundService
	comboChime:Play()
	task.delay(1.8, function()
		if comboChime.Parent then
			comboChime:Destroy()
		end
	end)

	-- Layer 3: Rarity Fanfare Sparkle for Epic / Legendary / Mythic / Cosmic
	if rarity == "Epic" or rarity == "Legendary" or rarity == "Mythic" or rarity == "Cosmic" then
		local fanfare = Instance.new("Sound")
		fanfare.Name = "RarityFanfare"
		fanfare.SoundId = "rbxassetid://4612373815"
		fanfare.Volume = 0.85
		fanfare.PlaybackSpeed = if rarity == "Mythic" or rarity == "Cosmic" then 1.15 else 1.0
		fanfare.Parent = SoundService
		fanfare:Play()
		task.delay(2.5, function()
			if fanfare.Parent then
				fanfare:Destroy()
			end
		end)
	end
end

-- Phase 5: 3D Elastic Squash-and-Stretch + Fly-To-Player Animation + 3D Star/Confetti Burst + Camera FOV Punch!
local function spawn3DDopaminePickupBurst(sData: any, info: any)
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local startPos: Vector3 = if typeof(info.WorldPos) == "Vector3"
		then info.WorldPos
		elseif sData.SpawnOffset then sData.SpawnOffset
		elseif hrp then (hrp.Position + Vector3.new(0, 3, -4))
		else Vector3.new(0, 5, 0)

	local bodyCol = sData.BodyColor or sData.Color or Color3.fromRGB(95, 225, 255)
	local accentCol = sData.AccentColor or sData.SecondaryColor or Color3.fromRGB(255, 235, 85)
	local earned = tonumber(info.CoinsEarned) or sData.CoinReward or 100
	local comboCount = tonumber(info.ComboCount) or 1
	local comboMult = tonumber(info.ComboMultiplier) or 1.0

	-- Camera Micro FOV Punch (70 -> 74.5 -> 70)
	local cam = Workspace.CurrentCamera
	if cam then
		TweenService:Create(cam, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = 74.5 }):Play()
		task.delay(0.09, function()
			if cam then
				TweenService:Create(cam, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { FieldOfView = 70 }):Play()
			end
		end)
	end

	-- 1. 3D Star/Confetti Burst Anchor + Rising 3D "+$Cash (xCombo!)" Floating Billboard at pickup spot
	local fxAnchor = Instance.new("Part")
	fxAnchor.Name = "DopaminePickupAnchor"
	fxAnchor.Size = Vector3.new(1, 1, 1)
	fxAnchor.Transparency = 1
	fxAnchor.Anchored = true
	fxAnchor.CanCollide = false
	fxAnchor.CanQuery = false
	fxAnchor.CanTouch = false
	fxAnchor.Position = startPos + Vector3.new(0, 1.5, 0)
	fxAnchor.Parent = Workspace

	local burstParticles = Instance.new("ParticleEmitter")
	burstParticles.Texture = "rbxassetid://243660364"
	burstParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, bodyCol),
		ColorSequenceKeypoint.new(0.5, accentCol),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	burstParticles.LightEmission = 1
	burstParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.35),
		NumberSequenceKeypoint.new(0.6, 0.85),
		NumberSequenceKeypoint.new(1, 0),
	})
	burstParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	burstParticles.Lifetime = NumberRange.new(0.45, 0.85)
	burstParticles.Speed = NumberRange.new(14, 26)
	burstParticles.SpreadAngle = Vector2.new(180, 180)
	burstParticles.Drag = 3.5
	burstParticles.Rate = 0
	burstParticles.Parent = fxAnchor
	burstParticles:Emit(24)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(9, 0, 2.4, 0)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = fxAnchor

	local popLbl = Instance.new("TextLabel")
	popLbl.Size = UDim2.fromScale(1, 1)
	popLbl.BackgroundTransparency = 1
	popLbl.Font = Enum.Font.FredokaOne
	popLbl.TextScaled = true
	popLbl.TextColor3 = if comboCount >= 2 then Color3.fromRGB(255, 235, 65) else Color3.fromRGB(95, 255, 145)
	local comboTag = if comboCount >= 2 then string.format("\n🔥 x%.1f SQUISH FEVER!", comboMult) else ""
	popLbl.Text = string.format("+$%s CASH!%s", SlimeData.FormatNumber(earned), comboTag)
	popLbl.Parent = bb

	local popStroke = Instance.new("UIStroke")
	popStroke.Color = Color3.fromRGB(16, 18, 32)
	popStroke.Thickness = 2.6
	popStroke.Parent = popLbl

	TweenService:Create(bb, TweenInfo.new(0.85, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 6.8, 0),
	}):Play()
	task.delay(0.90, function()
		if fxAnchor.Parent then
			fxAnchor:Destroy()
		end
	end)

	-- 2. 3D Elastic Squash-and-Stretch + Fly-To-Player Orb
	local flyOrb = Instance.new("Part")
	flyOrb.Name = "SquishFlyOrb"
	flyOrb.Shape = Enum.PartType.Ball
	flyOrb.Size = Vector3.new(2.2, 2.2, 2.2)
	flyOrb.Color = bodyCol
	flyOrb.Material = Enum.Material.Neon
	flyOrb.Anchored = true
	flyOrb.CanCollide = false
	flyOrb.CanQuery = false
	flyOrb.CanTouch = false
	flyOrb.CFrame = CFrame.new(startPos)
	flyOrb.Parent = Workspace

	-- Elastic squash-and-stretch pop (wide -> tall -> curve into player!)
	flyOrb.Size = Vector3.new(3.6, 1.4, 3.6)
	TweenService:Create(flyOrb, TweenInfo.new(0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(2.0, 3.2, 2.0),
		CFrame = CFrame.new(startPos + Vector3.new(0, 2.6, 0)),
	}):Play()

	task.delay(0.11, function()
		local flyStart = os.clock()
		local flyDur = 0.24
		local flyConn: RBXScriptConnection? = nil
		flyConn = RunService.RenderStepped:Connect(function()
			local alpha = math.clamp((os.clock() - flyStart) / flyDur, 0, 1)
			local targetPos = if hrp and hrp.Parent then hrp.Position else (startPos + Vector3.new(0, 3, 0))
			local arcPos = (startPos + Vector3.new(0, 2.6, 0)):Lerp(targetPos, alpha) + Vector3.new(0, math.sin(alpha * math.pi) * 3.2, 0)
			local shrink = math.max(0.25, 2.4 * (1 - alpha * 0.75))
			flyOrb.Size = Vector3.new(shrink, shrink, shrink)
			flyOrb.CFrame = CFrame.new(arcPos)
			if alpha >= 1 then
				if flyConn then
					flyConn:Disconnect()
				end
				if flyOrb.Parent then
					flyOrb:Destroy()
				end
			end
		end)
	end)
end

-- Live Squish Fever Combo State (x1.5 -> x5.0 Cash)
local activeComboExpiresAt = 0
local activeComboWindow = 12.0

local popupToken = 0
local confettiColors = {
	Color3.fromRGB(255, 85, 125),
	Color3.fromRGB(85, 225, 255),
	Color3.fromRGB(255, 230, 65),
	Color3.fromRGB(95, 250, 135),
	Color3.fromRGB(205, 105, 255),
}

local function showYouFoundPopup(sData: any, comboCount: number?, comboMult: number?)
	popupToken += 1
	local myToken = popupToken
	local rarity = tostring(sData.Rarity or "Common")
	local bodyCol = sData.BodyColor or sData.Color or Color3.fromRGB(95, 225, 255)
	ui.YfBadge.BackgroundColor3 = bodyCol
	local cMult = comboMult or 1.0
	local cTag = if (comboCount or 1) >= 2 then string.format("  •  🔥 x%.1f COMBO!", cMult) else ""
	ui.YfRarityLbl.Text = string.format("<b>[%s]  •  +$%s/sec%s</b>", string.upper(rarity), SlimeData.FormatNumber(sData.IncomePerSec or 10), cTag)
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
			local comboCount = tonumber(info.ComboCount) or 1
			local comboMult = tonumber(info.ComboMultiplier) or 1.0
			activeComboWindow = tonumber(info.ComboWindowSec) or 12.0
			activeComboExpiresAt = os.clock() + activeComboWindow

			if ui.ComboFrame and ui.ComboLabel then
				ui.ComboFrame.Visible = true
				ui.ComboLabel.Text = string.format(
					"🔥 <b>SQUISH FEVER COMBO: x%.1f CASH! (%dx CHAIN)</b> 🔥",
					comboMult,
					comboCount
				)
			end

			local rarity = tostring(sData.Rarity or "Common")
			playLayeredASMRPickupSound(comboCount, rarity)
			spawn3DDopaminePickupBurst(sData, info)
			showYouFoundPopup(sData, comboCount, comboMult)

			if info.ActionType == "EggStolen" then
				showToast(
					string.format(
						"🥚 STOLE [%s] %s! Follow the 3D Arrow into your Fenced Hatchery Pen to hatch it!",
						string.upper(rarity),
						string.upper(sData.Name)
					),
					Color3.fromRGB(255, 165, 45)
				)
			else
				-- Immediately hide collected Squishy (#36-#117) on the client so it vanishes on contact!
				local sw = Workspace:FindFirstChild("SquishyWorld")
				local worldEggsFolder = sw and sw:FindFirstChild("WorldEggs")
				if worldEggsFolder then
					local m = worldEggsFolder:FindFirstChild("WorldEgg_" .. tostring(info.SquishyId)) or worldEggsFolder:FindFirstChild(tostring(info.SquishyId))
					if m then
						for _, d in ipairs(m:GetDescendants()) do
							if d:IsA("BasePart") then
								d.Transparency = 1
								d.CanTouch = false
								d.CanQuery = false
								d.CanCollide = false
							elseif d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("ParticleEmitter") then
								(d :: any).Enabled = false
							elseif d:IsA("Decal") or d:IsA("Texture") then
								d.Transparency = 1
							end
						end
					end
				end

				showToast(
					string.format(
						"✨ COLLECTED [%s] %s! Added to your 117 Squishy Index (+$%s Cash)!",
						string.upper(rarity),
						string.upper(sData.Name),
						SlimeData.FormatNumber(info.CoinsEarned or sData.CoinReward or 200)
					),
					Color3.fromRGB(45, 175, 85)
				)
			end
		end
	end
end)

GuardianAlertEvent.OnClientEvent:Connect(function(msg: string)
	if type(msg) == "string" then
		showToast(msg, Color3.fromRGB(215, 50, 65))
	end
end)

-- =========================================================================
-- PHASE 7: SOLID 100% OPAQUE 3D GUIDING ARROWS (WIDE BEAM + 10 SOLID 3D GROUND CHEVRON ARROWS + 35-STUD SKY BEACON PILLAR!)
-- Points step-by-step from the player to:
--   [Step 1] Stage / Plot Treadmill -> [Step 2] Stage N Squishies -> [Step 3] Stage N Boss Egg Nest ->
--   [Step 4] Fenced Hatchery Pen -> [Step 5] Grow/Level Up & Cash Pad -> [Step 6] Unlocked Stage N+1 Gate
-- =========================================================================
local guidanceTargetPart = Instance.new("Part")
guidanceTargetPart.Name = "GuidanceTargetMarker3D"
guidanceTargetPart.Size = Vector3.new(3.2, 3.2, 3.2)
guidanceTargetPart.Shape = Enum.PartType.Ball
guidanceTargetPart.Color = Color3.fromRGB(85, 255, 165)
guidanceTargetPart.Material = Enum.Material.Neon
guidanceTargetPart.Transparency = 0
guidanceTargetPart.Anchored = true
guidanceTargetPart.CanCollide = false
guidanceTargetPart.CanQuery = false
guidanceTargetPart.CanTouch = false
guidanceTargetPart.Position = Vector3.new(-94, 6, 54)
guidanceTargetPart.Parent = Workspace

local targetAtt = Instance.new("Attachment")
targetAtt.Name = "GuidanceTargetAtt"
targetAtt.Parent = guidanceTargetPart

-- 35-Stud Vertical Neon Sky Beacon Pillar at Target so players can see their objective from across the entire map!
local skyBeaconPillar = Instance.new("Part")
skyBeaconPillar.Name = "GuidanceSkyBeacon3D"
skyBeaconPillar.Shape = Enum.PartType.Cylinder
skyBeaconPillar.Size = Vector3.new(35.0, 2.2, 2.2)
skyBeaconPillar.Color = Color3.fromRGB(85, 255, 165)
skyBeaconPillar.Material = Enum.Material.Neon
skyBeaconPillar.Transparency = 0.22
skyBeaconPillar.Anchored = true
skyBeaconPillar.CanCollide = false
skyBeaconPillar.CanQuery = false
skyBeaconPillar.CanTouch = false
skyBeaconPillar.CFrame = CFrame.new(-94, 18.5, 54) * CFrame.Angles(0, 0, math.rad(90))
skyBeaconPillar.Parent = guidanceTargetPart

-- Bouncing 3D Downward Pointer Cone above the Target
local pointerShaft = Instance.new("Part")
pointerShaft.Name = "PointerArrow3D"
pointerShaft.Size = Vector3.new(2.2, 4.8, 2.2)
pointerShaft.Color = Color3.fromRGB(255, 235, 65)
pointerShaft.Material = Enum.Material.Neon
pointerShaft.Transparency = 0
pointerShaft.Anchored = true
pointerShaft.CanCollide = false
pointerShaft.CanQuery = false
pointerShaft.CanTouch = false
pointerShaft.Parent = guidanceTargetPart

local pointerBB = Instance.new("BillboardGui")
pointerBB.Name = "GuidanceTargetSign"
pointerBB.Size = UDim2.new(14, 0, 3.4, 0)
pointerBB.StudsOffset = Vector3.new(0, 6.2, 0)
pointerBB.AlwaysOnTop = true
pointerBB.LightInfluence = 0
pointerBB.Parent = guidanceTargetPart

local pointerSignLbl = Instance.new("TextLabel")
pointerSignLbl.Size = UDim2.fromScale(1, 1)
pointerSignLbl.BackgroundTransparency = 1
pointerSignLbl.Font = Enum.Font.FredokaOne
pointerSignLbl.TextScaled = true
pointerSignLbl.TextColor3 = Color3.fromRGB(255, 245, 95)
pointerSignLbl.Text = "⚡ STEP 1: RUN ON TREADMILL!"
pointerSignLbl.Parent = pointerBB

local pointerSignStroke = Instance.new("UIStroke")
pointerSignStroke.Color = Color3.fromRGB(14, 18, 32)
pointerSignStroke.Thickness = 3.0
pointerSignStroke.Parent = pointerSignLbl

local playerGuidanceAtt: Attachment? = nil
local guidanceBeam = Instance.new("Beam")
guidanceBeam.Name = "StageGuidanceBeam3D"
guidanceBeam.Texture = "rbxassetid://4887782888"
guidanceBeam.TextureMode = Enum.TextureMode.Wrap
guidanceBeam.TextureLength = 6.0
guidanceBeam.TextureSpeed = 4.2
guidanceBeam.Width0 = 4.5
guidanceBeam.Width1 = 4.8
guidanceBeam.Brightness = 4.5
guidanceBeam.LightEmission = 1
guidanceBeam.LightInfluence = 0
guidanceBeam.FaceCamera = true
-- 100% Solid Opaque Guiding Arrow Beam (Zero Transparency!)
guidanceBeam.Transparency = NumberSequence.new(0)
guidanceBeam.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 245, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(95, 255, 135)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 235, 65)),
})
guidanceBeam.Attachment1 = targetAtt
guidanceBeam.Parent = guidanceTargetPart

-- Live 10-Part Solid 3D Neon Ground Chevron Arrow Chain so players can follow unmistakable physical 3D arrows on the ground!
local arrowChainFolder = Instance.new("Folder")
arrowChainFolder.Name = "GuidanceArrowChainFolder"
arrowChainFolder.Parent = Workspace

local NUM_GROUND_ARROWS = 10
local groundArrowParts: { { LeftWing: Part, RightWing: Part } } = {}
for i = 1, NUM_GROUND_ARROWS do
	local leftWing = Instance.new("Part")
	leftWing.Name = "GroundArrowLeft_" .. tostring(i)
	leftWing.Size = Vector3.new(0.65, 0.35, 2.6)
	leftWing.Material = Enum.Material.Neon
	leftWing.Color = Color3.fromRGB(255, 235, 65)
	leftWing.Transparency = 0
	leftWing.Anchored = true
	leftWing.CanCollide = false
	leftWing.CanQuery = false
	leftWing.CanTouch = false
	leftWing.Parent = arrowChainFolder

	local rightWing = Instance.new("Part")
	rightWing.Name = "GroundArrowRight_" .. tostring(i)
	rightWing.Size = Vector3.new(0.65, 0.35, 2.6)
	rightWing.Material = Enum.Material.Neon
	rightWing.Color = Color3.fromRGB(255, 235, 65)
	rightWing.Transparency = 0
	rightWing.Anchored = true
	rightWing.CanCollide = false
	rightWing.CanQuery = false
	rightWing.CanTouch = false
	rightWing.Parent = arrowChainFolder

	table.insert(groundArrowParts, {
		LeftWing = leftWing,
		RightWing = rightWing,
	})
end

local FALLBACK_PLOT_COORDS = {
	[1] = Vector3.new(-94, 4, 54),
	[2] = Vector3.new(94, 4, 54),
	[3] = Vector3.new(-94, 4, 136),
	[4] = Vector3.new(94, 4, 136),
}

local function getPlotStationPos(plotIdx: number, stationName: string): Vector3
	local sw = Workspace:FindFirstChild("SquishyWorld")
	local plots = sw and sw:FindFirstChild("PlayerPlots")
	local pModel = plots and plots:FindFirstChild("Plot_" .. tostring(plotIdx))
	if pModel then
		if stationName == "HatcheryPen" then
			local pen = pModel:FindFirstChild("HatcheryPen")
			local floor = pen and pen:FindFirstChild("HatcheryPenFloor") :: BasePart?
			if floor then
				return floor.Position + Vector3.new(0, 2.5, 0)
			end
		elseif stationName == "GrowOrCash" then
			local pen = pModel:FindFirstChild("HatcheryPen")
			local growSign = pen and pen:FindFirstChild("GrowUpgradeStationSign") :: BasePart?
			if growSign then
				return growSign.Position
			end
			local cashPad = pModel:FindFirstChild("CollectCashPad") :: BasePart?
			if cashPad then
				return cashPad.Position + Vector3.new(0, 2.5, 0)
			end
		elseif stationName == "Treadmill" then
			local belt = pModel:FindFirstChild("TreadmillBelt_" .. tostring(plotIdx), true) :: BasePart?
			if belt then
				return belt.Position + Vector3.new(0, 2.5, 0)
			end
		end
	end
	return FALLBACK_PLOT_COORDS[plotIdx] or Vector3.new(-94, 4, 54)
end

local function getStageTreadmillPos(stageId: number, plotIdx: number): Vector3
	local sw = Workspace:FindFirstChild("SquishyWorld")
	local levelsFolder = sw and sw:FindFirstChild("Levels")
	if levelsFolder then
		local sBelt = levelsFolder:FindFirstChild("TreadmillBelt_Stage_" .. tostring(stageId), true) :: BasePart?
		if sBelt then
			return sBelt.Position + Vector3.new(0, 2.5, 0)
		end
	end
	return getPlotStationPos(plotIdx, "Treadmill")
end

local function computeCurrent6StepTarget(hrpPos: Vector3): (Vector3, string, string, Color3)
	if not latestState then
		return Vector3.new(-94, 4, 54), "⚡ STEP 1: RUN ON TREADMILL!", "🧭 <b>FOLLOW 3D ARROW:</b> [Step 1] ⚡ Run on Treadmill to Train Speed!", Color3.fromRGB(85, 235, 255)
	end

	local plotIdx = tonumber(latestState.PlotIndex) or 1
	local foundMap = latestState.Found or {}
	local spd = tonumber(latestState.SpeedStat) or 16
	local coins = tonumber(latestState.Coins) or 0
	local carriedEggs = tonumber(latestState.CarriedEggCount) or 0
	local hatchingCount = tonumber(latestState.HatchingCount) or 0
	local ranchCount = tonumber(latestState.RanchSquishyCount) or 0
	local minUpgradeCost = tonumber(latestState.MinSquishyUpgradeCost) or 0
	local uncollectedCash = tonumber(latestState.UncollectedPlotCash) or 0
	local unlockedMap = latestState.UnlockedLevels or { ["1"] = true }

	-- [STEP 4] Carrying a stolen Boss Egg -> Go straight to your Plot's Fenced Hatchery Pen!
	if carriedEggs > 0 then
		local penPos = getPlotStationPos(plotIdx, "HatcheryPen")
		return penPos,
			"🏡 STEP 4: WALK INTO FENCED PEN TO HATCH!",
			"🧭 <b>FOLLOW 3D ARROW:</b> [Step 4/6] 🏡 Walk into your Plot's <b>Fenced Hatchery Pen</b> to Auto-Drop & Hatch your Boss Egg!",
			Color3.fromRGB(95, 255, 145)
	end

	-- [STEP 5] Eggs currently hatching in Fenced Pen OR player is near their plot and can Grow/Level Up a Roaming Squishy or Claim Cash!
	local growPos = getPlotStationPos(plotIdx, "GrowOrCash")
	if hatchingCount > 0 then
		return growPos,
			"⏳ STEP 4/5: HATCHING IN FENCED PEN!",
			"🧭 <b>FOLLOW 3D ARROW:</b> [Step 4/6] 🐣 Watch your Egg wobble & hatch into a Roaming Squishy inside the Fence!",
			Color3.fromRGB(255, 225, 75)
	end
	if ranchCount > 0 and minUpgradeCost > 0 and coins >= minUpgradeCost and (hrpPos - growPos).Magnitude <= 95 then
		return growPos,
			string.format("⬆️ STEP 5: GROW SQUISHY ($%s)!", SlimeData.FormatNumber(minUpgradeCost)),
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> [Step 5/6] 🌱 Grow & Level Up your Roaming Squishy in the Fenced Pen ($%s)!", SlimeData.FormatNumber(minUpgradeCost)),
			Color3.fromRGB(115, 255, 140)
	end
	if uncollectedCash >= math.max(250, (tonumber(latestState.PassiveIncomeRate) or 10) * 8) and (hrpPos - growPos).Magnitude <= 95 then
		local sw = Workspace:FindFirstChild("SquishyWorld")
		local plots = sw and sw:FindFirstChild("PlayerPlots")
		local pModel = plots and plots:FindFirstChild("Plot_" .. tostring(plotIdx))
		local cashPad = pModel and pModel:FindFirstChild("CollectCashPad") :: BasePart?
		local padPos = if cashPad then (cashPad.Position + Vector3.new(0, 2.5, 0)) else growPos
		return padPos,
			string.format("💰 STEP 5: CLAIM $%s CASH!", SlimeData.FormatNumber(uncollectedCash)),
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> [Step 5/6] 💰 Step on your Plot's Green Cash Pad to claim $%s!", SlimeData.FormatNumber(uncollectedCash)),
			Color3.fromRGB(85, 255, 125)
	end

	-- Determine current active Stage (1..8): first stage that is not 100% completed OR whose next Stage Gate is still locked!
	local activeStage = 8
	for stageId = 1, #SlimeData.Levels do
		local foundInStage, totalInStage = SlimeData.CountLevelProgress(foundMap, stageId)
		local nextUnlocked = if stageId < #SlimeData.Levels then (unlockedMap[tostring(stageId + 1)] == true) else false
		if foundInStage < totalInStage or (stageId < #SlimeData.Levels and not nextUnlocked) then
			activeStage = stageId
			break
		end
	end

	local stageInfo = SlimeData.Levels[activeStage]
	local nextStageInfo = SlimeData.Levels[activeStage + 1]
	local foundInStage, totalInStage = SlimeData.CountLevelProgress(foundMap, activeStage)

	-- [STEP 6] If the player just unlocked activeStage (activeStage > 1) and is still standing back in Stage (activeStage - 1), guide them through the newly unlocked Gate!
	if activeStage > 1 and stageInfo and hrpPos.Z > (stageInfo.ZStart + 6) then
		local gatePos = Vector3.new(0, 5, stageInfo.ZStart)
		return gatePos,
			string.format("🔓 STEP 6: ENTER STAGE %d (%s)!", activeStage, string.upper(stageInfo.Name)),
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> [Step 6/6] 🔓 Stage %d Gate is UNLOCKED! Run through the Gate into <b>%s</b>!", activeStage, stageInfo.Name),
			Color3.fromRGB(95, 255, 145)
	end

	-- [STEP 1] If player is at very start of Stage 1 with low Speed (< 45) OR has 100% of activeStage items and needs Speed for Stage (activeStage + 1):
	local nextReqSpeed = if nextStageInfo then (nextStageInfo.RequiredSpeed or 250) else 0
	if (activeStage == 1 and spd < 45 and foundInStage == 0) or (foundInStage >= totalInStage and nextStageInfo and spd < nextReqSpeed) then
		local tmPos = getStageTreadmillPos(activeStage, plotIdx)
		local targetSpd = if foundInStage >= totalInStage then nextReqSpeed else 45
		return tmPos,
			string.format("⚡ STEP 1: RUN ON TREADMILL (%s / %s SPD)!", SlimeData.FormatNumber(spd), SlimeData.FormatNumber(targetSpd)),
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> [Step 1/6] ⚡ Run on the Stage %d Treadmill to reach <b>%s Speed</b>!", activeStage, SlimeData.FormatNumber(targetSpd)),
			Color3.fromRGB(85, 235, 255)
	end

	-- Find nearest uncollected Collectible Squishy (#36-#117) and nearest available Boss Egg (#1-#35) in activeStage
	local sw = Workspace:FindFirstChild("SquishyWorld")
	local worldEggsFolder = sw and sw:FindFirstChild("WorldEggs")
	local nearestSquishyPos: Vector3? = nil
	local nearestSquishyDist = math.huge
	local nearestSquishyName = ""
	local nearestEggPos: Vector3? = nil
	local nearestEggDist = math.huge
	local nearestEggName = ""

	for _, sData in ipairs(SlimeData.Slimes) do
		if sData.Level == activeStage then
			local sKey = tostring(sData.Id)
			if not foundMap[sKey] then
				local itemPos = sData.SpawnOffset
				if worldEggsFolder then
					local m = worldEggsFolder:FindFirstChild("WorldEgg_" .. sKey) or worldEggsFolder:FindFirstChild(sKey)
					if m and m:IsA("Model") then
						itemPos = m:GetPivot().Position
					end
				end
				local d = (hrpPos - itemPos).Magnitude
				local numId = tonumber((sData :: any).UnlockOrder or (sData :: any).NumericId or sData.Id) or 1
				if numId > 35 then
					if d < nearestSquishyDist then
						nearestSquishyDist = d
						nearestSquishyPos = itemPos
						nearestSquishyName = sData.Name
					end
				else
					if d < nearestEggDist then
						nearestEggDist = d
						nearestEggPos = itemPos
						nearestEggName = sData.Name
					end
				end
			end
		end
	end

	-- [STEP 2] Collect Stage N Collectible Squishies (Walk-Over Auto-Pickup!)
	if nearestSquishyPos then
		return nearestSquishyPos,
			string.format("🧸 STEP 2: WALK OVER %s (%d/%d)!", string.upper(nearestSquishyName), foundInStage, totalInStage),
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> [Step 2/6] 🧸 Walk over <b>%s</b> in Stage %d (%d/%d Found for 100%%)!", nearestSquishyName, activeStage, foundInStage, totalInStage),
			Color3.fromRGB(255, 145, 235)
	end

	-- [STEP 3] Steal Stage N Boss Egg from Sector 3 Sleeping Boss Arena!
	if nearestEggPos then
		return nearestEggPos,
			string.format("🥚 STEP 3: STEAL %s (%d/%d)!", string.upper(nearestEggName), foundInStage, totalInStage),
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> [Step 3/6] 🥚 Sneak into Stage %d Boss Nest & walk over <b>%s</b> (%d/%d Found)!", activeStage, nearestEggName, foundInStage, totalInStage),
			Color3.fromRGB(255, 195, 65)
	end

	-- Fallback: Stage 8 100% Complete!
	local tmPos = getStageTreadmillPos(activeStage, plotIdx)
	return tmPos,
		"👑 100% COSMIC MASTERY! TRAIN MAX SPEED!",
		"🧭 <b>100% ALL 8 STAGES COMPLETE!</b> 👑 Keep running on the Cosmic Treadmill or Rebirth for massive multipliers!",
		Color3.fromRGB(255, 225, 75)
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()

	-- Update Squish Fever Combo Bar countdown
	if ui.ComboFrame and ui.ComboFrame.Visible then
		local rem = activeComboExpiresAt - now
		if rem <= 0 then
			ui.ComboFrame.Visible = false
		elseif ui.ComboFill then
			ui.ComboFill.Size = UDim2.fromScale(math.clamp(rem / math.max(1, activeComboWindow), 0, 1), 1)
		end
	end

	-- Update 3D Guiding Arrow Beam + 10-Part Ground Chevron Chain + 35-Stud Sky Beacon Pillar
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		if not playerGuidanceAtt or playerGuidanceAtt.Parent ~= hrp then
			if playerGuidanceAtt then
				playerGuidanceAtt:Destroy()
			end
			local att = Instance.new("Attachment")
			att.Name = "PlayerGuidanceAtt"
			att.Position = Vector3.new(0, -1.2, 0)
			att.Parent = hrp
			playerGuidanceAtt = att
			guidanceBeam.Attachment0 = att
		end

		local targetPos, signText, hudText, themeCol = computeCurrent6StepTarget(hrp.Position)
		local bobY = math.sin(now * 4.5) * 1.15
		guidanceTargetPart.Position = targetPos + Vector3.new(0, 1.4 + bobY * 0.35, 0)
		guidanceTargetPart.Color = themeCol
		skyBeaconPillar.CFrame = CFrame.new(targetPos + Vector3.new(0, 18.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		skyBeaconPillar.Color = themeCol
		pointerShaft.CFrame = CFrame.new(targetPos + Vector3.new(0, 4.8 + bobY, 0)) * CFrame.Angles(0, now * 2.4, 0)
		pointerShaft.Color = themeCol
		pointerSignLbl.Text = signText
		pointerSignLbl.TextColor3 = themeCol:Lerp(Color3.fromRGB(255, 255, 255), 0.35)
		if ui.ObjectiveText then
			ui.ObjectiveText.Text = hudText
		end

		-- Animate the 10 Solid 3D Ground Chevron Arrows marching from the player to the target!
		local startGround = hrp.Position + Vector3.new(0, -1.6, 0)
		local endGround = targetPos + Vector3.new(0, 0.5, 0)
		local delta = endGround - startGround
		local dist = delta.Magnitude
		local dir = if dist > 0.5 then delta.Unit else Vector3.new(0, 0, -1)
		local flatDir = Vector3.new(dir.X, 0, dir.Z)
		if flatDir.Magnitude < 0.05 then
			flatDir = Vector3.new(0, 0, -1)
		else
			flatDir = flatDir.Unit
		end
		local marchOffset = (now * 1.65) % 1.0
		local maxChainDist = math.min(dist, 95)

		for i, chevron in ipairs(groundArrowParts) do
			if dist < 4.0 then
				chevron.LeftWing.Transparency = 1
				chevron.RightWing.Transparency = 1
			else
				local frac = ((i - 1 + marchOffset) / NUM_GROUND_ARROWS)
				local dAlong = 4.0 + frac * math.max(2.0, maxChainDist - 5.0)
				local arrowCenter = startGround + dir * dAlong + Vector3.new(0, math.sin(now * 5.0 + i * 0.7) * 0.18, 0)
				local baseCF = CFrame.lookAt(arrowCenter, arrowCenter + flatDir)
				local pulseCol = if (math.floor(now * 6) + i) % 3 == 0
					then Color3.fromRGB(255, 255, 160)
					else themeCol
				chevron.LeftWing.Color = pulseCol
				chevron.RightWing.Color = pulseCol
				chevron.LeftWing.Transparency = 0
				chevron.RightWing.Transparency = 0
				chevron.LeftWing.CFrame = baseCF * CFrame.new(-0.78, 0, 0) * CFrame.Angles(0, math.rad(-35), 0)
				chevron.RightWing.CFrame = baseCF * CFrame.new(0.78, 0, 0) * CFrame.Angles(0, math.rad(35), 0)
			end
		end
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
