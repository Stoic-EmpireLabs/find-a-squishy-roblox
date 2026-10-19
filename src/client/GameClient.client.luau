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

local AvatarEditorService = game:GetService("AvatarEditorService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CreatorStoreGameplayKits = require(Shared:WaitForChild("CreatorStoreGameplayKits"))
local SlimeData = require(Shared:WaitForChild("SlimeData"))
local UIBuilder = require(Shared:WaitForChild("UIBuilder"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateSyncEvent = Remotes:WaitForChild("StateSync") :: RemoteEvent
local EggCapturedEvent = Remotes:WaitForChild("SquishyCaptured") :: RemoteEvent
local CoinCollectedEvent = Remotes:WaitForChild("CoinCollected") :: RemoteEvent
local GuardianAlertEvent = Remotes:WaitForChild("GuardianAlert") :: RemoteEvent
local BuySpeedUpgradeEvent = Remotes:WaitForChild("BuySpeedUpgrade") :: RemoteEvent
local BuyFenceUpgradeEvent = Remotes:WaitForChild("BuyFenceUpgrade") :: RemoteEvent
local BuySquishyHintEvent = Remotes:WaitForChild("BuySquishyHint") :: RemoteEvent
local UnlockStageGateEvent = Remotes:WaitForChild("UnlockStageGate") :: RemoteEvent
local TreadmillTapBoostEvent = Remotes:WaitForChild("TreadmillTapBoost") :: RemoteEvent
local RebirthRequestEvent = Remotes:WaitForChild("RebirthRequest") :: RemoteEvent
local ClaimDailyRewardEvent = Remotes:WaitForChild("ClaimDailyReward") :: RemoteEvent
local ClaimPlaytimeRewardEvent = Remotes:WaitForChild("ClaimPlaytimeReward") :: RemoteEvent
local ToggleSloMoEvent = Remotes:WaitForChild("ToggleSloMo") :: RemoteEvent
local SetSpeedThrottleEvent = Remotes:WaitForChild("SetSpeedThrottle") :: RemoteEvent
local SpinWheelRequestEvent = Remotes:WaitForChild("SpinWheelRequest") :: RemoteEvent
local BuySpinCashEvent = Remotes:WaitForChild("BuySpinCash") :: RemoteEvent
local BuyRobuxItemEvent = Remotes:WaitForChild("BuyRobuxItem") :: RemoteEvent
local ClaimLikeFavoriteEvent = Remotes:WaitForChild("ClaimLikeFavoriteReward") :: RemoteEvent
local OpenModalEvent = Remotes:WaitForChild("OpenModal") :: RemoteEvent
local GetInitialStateFunc = Remotes:WaitForChild("GetInitialState") :: RemoteFunction

local ui = UIBuilder.CreateHUD(playerGui)

-- Disable default Roblox health bar in favor of Creator Store Premium Health Bar HUD
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- Mount Creator Store assets into PlayerGui if available
CreatorStoreGameplayKits.MountPremiumHealthBar(playerGui)
CreatorStoreGameplayKits.MountSettingsPanelPro(playerGui)

-- Wire dynamic updates to Premium Health Bar (Creator Store 96150583459141)
local function bindHealth(character: Model)
	local hum = character:WaitForChild("Humanoid", 8) :: Humanoid?
	if not hum then
		return
	end
	local function updateHp()
		if not ui.PremiumHealthFill or not ui.PremiumHealthLabel then
			return
		end
		local maxHp = math.max(hum.MaxHealth, 1)
		local hp = math.clamp(hum.Health, 0, maxHp)
		local ratio = math.clamp(hp / maxHp, 0, 1)
		TweenService:Create(ui.PremiumHealthFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(ratio, 0, 1, 0),
			BackgroundColor3 = if ratio > 0.5 then Color3.fromRGB(80, 240, 120) elseif ratio > 0.25 then Color3.fromRGB(255, 200, 60) else Color3.fromRGB(240, 60, 70),
		}):Play()
		ui.PremiumHealthLabel.Text = string.format("❤️ %d / %d HP", math.ceil(hp), math.ceil(maxHp))
	end
	hum.HealthChanged:Connect(updateHp)
	updateHp()
end
if localPlayer.Character then
	task.spawn(bindHealth, localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(bindHealth)

local function hideWorldItemForLocalPlayer(target: Instance?)
	if not target then
		return
	end
	if target:IsA("BasePart") then
		target.Transparency = 1
		target.CanTouch = false
		target.CanQuery = false
		target.CanCollide = false
	end
	for _, d in ipairs(target:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = 1
			d.CanTouch = false
			d.CanQuery = false
			d.CanCollide = false
		elseif
			d:IsA("ProximityPrompt")
			or d:IsA("BillboardGui")
			or d:IsA("SurfaceGui")
			or d:IsA("ParticleEmitter")
			or d:IsA("Highlight")
			or d:IsA("PointLight")
		then
			(d :: any).Enabled = false
		elseif d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = 1
		end
	end
end

local function findWorldEggModel(worldEggsFolder: Instance?, sKey: string): Instance?
	if not worldEggsFolder then
		return nil
	end
	local k = tostring(sKey)
	return worldEggsFolder:FindFirstChild("ShiningSquishy_" .. k)
		or worldEggsFolder:FindFirstChild("Egg_" .. k)
		or worldEggsFolder:FindFirstChild("WorldEgg_" .. k)
		or worldEggsFolder:FindFirstChild(k)
end

local function findWorldCoinModel(worldCoinsFolder: Instance?, coinId: string): Instance?
	if not worldCoinsFolder then
		return nil
	end
	local c = tostring(coinId)
	return worldCoinsFolder:FindFirstChild("WorldCoin_" .. c)
		or worldCoinsFolder:FindFirstChild(c)
end

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

-- PS5 / Xbox Console Controller Navigation System & Cross-Platform Button Helper
local buttonCallbacks: { [GuiButton]: () -> () } = {}
local pinnedGuideSquishyId: string? = nil

local function isConsoleOrGamepad(): boolean
	local lastInput = UserInputService:GetLastInputType()
	return GuiService:IsTenFootInterface()
		or UserInputService.GamepadEnabled
		or #UserInputService:GetConnectedGamepads() > 0
		or lastInput == Enum.UserInputType.Gamepad1
		or lastInput == Enum.UserInputType.Gamepad2
		or lastInput == Enum.UserInputType.Focus
end

pcall(function()
	GuiService.AutoSelectGuiEnabled = true
	GuiService.GuiNavigationEnabled = true
end)

local currentConsoleFocus: GuiButton? = nil
local consoleFocusStroke: UIStroke = Instance.new("UIStroke")
consoleFocusStroke.Name = "ConsoleFocusHighlightStroke"
consoleFocusStroke.Color = Color3.fromRGB(255, 235, 65)
consoleFocusStroke.Thickness = 3.5
consoleFocusStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local function setConsoleFocus(btn: GuiButton?)
	currentConsoleFocus = btn
	if btn then
		consoleFocusStroke.Parent = btn
		pcall(function()
			GuiService.SelectedObject = btn
		end)
		-- If this is an IndexScroll card, auto-scroll to keep it centered in view
		if btn.Parent and btn.Parent.Name == "IndexScroll" then
			local scroll = btn.Parent :: ScrollingFrame
			local numStr = string.match(btn.Name, "%d+")
			local idx = tonumber(numStr) or 1
			local rowIdx = math.floor((idx - 1) / 3)
			local targetY = math.max(0, rowIdx * 116 - 116)
			if math.abs(scroll.CanvasPosition.Y - targetY) > 180 then
				scroll.CanvasPosition = Vector2.new(0, targetY)
			end
		end
	else
		consoleFocusStroke.Parent = nil
		pcall(function()
			GuiService.SelectedObject = nil
		end)
	end
end

GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
	local sel = GuiService.SelectedObject
	if sel and sel:IsA("GuiButton") then
		if currentConsoleFocus ~= sel then
			currentConsoleFocus = sel
			consoleFocusStroke.Parent = sel
			if sel.Parent and sel.Parent.Name == "IndexScroll" then
				local scroll = sel.Parent :: ScrollingFrame
				local numStr = string.match(sel.Name, "%d+")
				local idx = tonumber(numStr) or 1
				local rowIdx = math.floor((idx - 1) / 3)
				local targetY = math.max(0, rowIdx * 116 - 116)
				if math.abs(scroll.CanvasPosition.Y - targetY) > 180 then
					scroll.CanvasPosition = Vector2.new(0, targetY)
				end
			end
		end
	end
end)

local function unbindConsoleModalControls()
	pcall(function()
		ContextActionService:UnbindAction("ConsoleModalControl")
	end)
end

local function closeAllModals()
	ui.IndexModal.Visible = false
	ui.ShopModal.Visible = false
	ui.SpinModal.Visible = false
	if ui.LikeFavoriteModal then
		ui.LikeFavoriteModal.Visible = false
	end
	if ui.HowToPlayModal then
		ui.HowToPlayModal.Visible = false
	end
	if ui.SettingsProModal then
		ui.SettingsProModal.Visible = false
	end
	setConsoleFocus(nil)
	unbindConsoleModalControls()
end

local function getActiveModal(): Frame?
	if ui.IndexModal.Visible then return ui.IndexModal end
	if ui.ShopModal.Visible then return ui.ShopModal end
	if ui.SpinModal.Visible then return ui.SpinModal end
	if ui.SettingsProModal and ui.SettingsProModal.Visible then return ui.SettingsProModal end
	if ui.LikeFavoriteModal and ui.LikeFavoriteModal.Visible then return ui.LikeFavoriteModal end
	if ui.HowToPlayModal and ui.HowToPlayModal.Visible then return ui.HowToPlayModal end
	return nil
end

local function handleModalControllerInput(_actionName: string, inputState: Enum.UserInputState, inputObj: InputObject): Enum.ContextActionResult
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end

	local kc = inputObj.KeyCode
	if kc == Enum.KeyCode.ButtonA or kc == Enum.KeyCode.Return then
		local activeBtn = (GuiService.SelectedObject and GuiService.SelectedObject:IsA("GuiButton") and GuiService.SelectedObject :: GuiButton) or currentConsoleFocus
		if activeBtn then
			if buttonCallbacks[activeBtn] then
				buttonCallbacks[activeBtn]()
			elseif (activeBtn :: any).Activate then
				(activeBtn :: any):Activate()
			end
		end
		return Enum.ContextActionResult.Sink
	elseif kc == Enum.KeyCode.ButtonB or kc == Enum.KeyCode.Escape then
		closeAllModals()
		return Enum.ContextActionResult.Sink
	elseif kc == Enum.KeyCode.DPadUp then
		local cur = if currentConsoleFocus then currentConsoleFocus else activeBtn
		if cur and cur.NextSelectionUp and cur.NextSelectionUp:IsA("GuiButton") then
			setConsoleFocus(cur.NextSelectionUp :: GuiButton)
		end
		return Enum.ContextActionResult.Sink
	elseif kc == Enum.KeyCode.DPadDown then
		local cur = if currentConsoleFocus then currentConsoleFocus else activeBtn
		if cur and cur.NextSelectionDown and cur.NextSelectionDown:IsA("GuiButton") then
			setConsoleFocus(cur.NextSelectionDown :: GuiButton)
		end
		return Enum.ContextActionResult.Sink
	elseif kc == Enum.KeyCode.DPadLeft then
		local cur = if currentConsoleFocus then currentConsoleFocus else activeBtn
		if cur and cur.NextSelectionLeft and cur.NextSelectionLeft:IsA("GuiButton") then
			setConsoleFocus(cur.NextSelectionLeft :: GuiButton)
		end
		return Enum.ContextActionResult.Sink
	elseif kc == Enum.KeyCode.DPadRight then
		local cur = if currentConsoleFocus then currentConsoleFocus else activeBtn
		if cur and cur.NextSelectionRight and cur.NextSelectionRight:IsA("GuiButton") then
			setConsoleFocus(cur.NextSelectionRight :: GuiButton)
		end
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Sink
end

local function bindConsoleModalControls()
	pcall(function()
		ContextActionService:BindActionAtPriority(
			"ConsoleModalControl",
			handleModalControllerInput,
			false,
			3000,
			Enum.KeyCode.ButtonA,
			Enum.KeyCode.ButtonB,
			Enum.KeyCode.DPadUp,
			Enum.KeyCode.DPadDown,
			Enum.KeyCode.DPadLeft,
			Enum.KeyCode.DPadRight
		)
	end)
end

local function openOnlyModal(targetModal: Frame?, defaultSelectBtn: GuiObject?)
	if not targetModal then
		return
	end
	local shouldShow = not targetModal.Visible
	closeAllModals()
	if shouldShow then
		targetModal.Visible = true
		bindConsoleModalControls()
		if defaultSelectBtn and defaultSelectBtn:IsA("GuiButton") then
			setConsoleFocus(defaultSelectBtn :: GuiButton)
		end
		task.delay(0.05, function()
			if targetModal and targetModal.Visible and defaultSelectBtn and defaultSelectBtn:IsA("GuiButton") then
				setConsoleFocus(defaultSelectBtn :: GuiButton)
			end
		end)
	end
end

local function bindButton(btn: GuiButton?, fn: () -> ())
	if not btn then
		return
	end
	btn.Selectable = true
	local lastClick = 0
	local function onTrigger()
		local now = os.clock()
		if now - lastClick < 0.18 then
			return
		end
		lastClick = now
		fn()
	end
	buttonCallbacks[btn] = onTrigger
	btn.MouseButton1Click:Connect(onTrigger)
	btn.Activated:Connect(onTrigger)
end

local firstIndexCardBtn = (ui.IndexCards and ui.IndexCards["1"] and ui.IndexCards["1"].Frame) or ui.BuyHintIndexBtn or ui.IndexClose

local TAB_ORDER = {
	{ Modal = ui.IndexModal, DefaultBtn = firstIndexCardBtn },
	{ Modal = ui.ShopModal, DefaultBtn = (ui.PassButtonsByKey and ui.PassButtonsByKey["VIP"]) or ui.BuySpeedBtn or ui.ShopClose },
	{ Modal = ui.SpinModal, DefaultBtn = ui.SpinNowBtn or ui.BuySpinCashBtn or ui.SpinClose },
	{ Modal = ui.SettingsProModal, DefaultBtn = ui.KidFriendlyToggleBtn or ui.SettingsProClose },
	{ Modal = ui.LikeFavoriteModal, DefaultBtn = ui.FavoriteNowBtn or ui.ClaimLikeFavRewardBtn or ui.LikeFavClose },
}

local function cycleConsoleTab(direction: number)
	local curIndex = 0
	for i, tab in ipairs(TAB_ORDER) do
		if tab.Modal and tab.Modal.Visible then
			curIndex = i
			break
		end
	end
	local nextIndex = 1
	if curIndex == 0 then
		nextIndex = if direction > 0 then 1 else #TAB_ORDER
	else
		nextIndex = curIndex + direction
		if nextIndex > #TAB_ORDER then
			nextIndex = 1
		elseif nextIndex < 1 then
			nextIndex = #TAB_ORDER
		end
	end
	local targetTab = TAB_ORDER[nextIndex]
	if targetTab and targetTab.Modal then
		openOnlyModal(targetTab.Modal, targetTab.DefaultBtn)
	end
end

UserInputService.InputBegan:Connect(function(input: InputObject, _gameProcessed: boolean)
	if input.KeyCode == Enum.KeyCode.ButtonR1 then
		cycleConsoleTab(1)
	elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
		cycleConsoleTab(-1)
	elseif input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape then
		if getActiveModal() then
			closeAllModals()
		end
	elseif not getActiveModal() then
		-- DPad shortcuts when NO modal is open
		if input.KeyCode == Enum.KeyCode.DPadUp then
			openOnlyModal(ui.IndexModal, firstIndexCardBtn)
		elseif input.KeyCode == Enum.KeyCode.DPadRight then
			openOnlyModal(ui.ShopModal, (ui.PassButtonsByKey and ui.PassButtonsByKey["VIP"]) or ui.BuySpeedBtn or ui.ShopClose)
		elseif input.KeyCode == Enum.KeyCode.DPadDown then
			openOnlyModal(ui.SpinModal, ui.SpinNowBtn or ui.BuySpinCashBtn or ui.SpinClose)
		elseif input.KeyCode == Enum.KeyCode.DPadLeft then
			openOnlyModal(ui.SettingsProModal, ui.KidFriendlyToggleBtn or ui.SettingsProClose)
		end
	end
end)

-- Wire Top-Bar, Left 2x3 Sidebar, Right Dock, Bottom-Left, Speed Throttle (25%/50%/75%/100%) & Modal Buttons
if ui.SpeedThrottleButtons then
	for pct, btn in pairs(ui.SpeedThrottleButtons) do
		bindButton(btn, function()
			SetSpeedThrottleEvent:FireServer(pct / 100)
		end)
	end
end

if ui.TreadmillTurboBtn then
	bindButton(ui.TreadmillTurboBtn, function()
		TreadmillTapBoostEvent:FireServer()
	end)
end

bindButton(ui.TopIndexBtn, function()
	openOnlyModal(ui.IndexModal, firstIndexCardBtn)
end)

bindButton(ui.TopSpeedBtn, function()
	BuySpeedUpgradeEvent:FireServer()
end)

bindButton(ui.ShopBtn, function()
	openOnlyModal(ui.ShopModal, (ui.PassButtonsByKey and ui.PassButtonsByKey["VIP"]) or ui.BuySpeedBtn or ui.ShopClose)
end)

bindButton(ui.IndexBtn, function()
	openOnlyModal(ui.IndexModal, firstIndexCardBtn)
end)

bindButton(ui.DailyBtn, function()
	openOnlyModal(ui.SpinModal, ui.ClaimDailyModalBtn or ui.SpinNowBtn)
end)

local sloMoEnabled = false
bindButton(ui.SloMoBtn, function()
	sloMoEnabled = not sloMoEnabled
	if ui.SloMoBtn then
		ui.SloMoBtn.BackgroundColor3 = if sloMoEnabled then Color3.fromRGB(65, 195, 85) else Color3.fromRGB(185, 42, 42)
		ui.SloMoBtn.Text = if sloMoEnabled then "<b>SloMo: ON</b>" else "<b>SloMo: OFF</b>"
		local sloCap = ui.SloMoBtn:FindFirstChild("Caption") :: TextLabel?
		if sloCap then
			sloCap.Text = if sloMoEnabled then "<b>SloMo: ON</b>" else "<b>SloMo: OFF</b>"
		end
	end
	ToggleSloMoEvent:FireServer()
end)

bindButton(ui.WheelBtn, function()
	openOnlyModal(ui.SpinModal, ui.SpinNowBtn or ui.BuySpinCashBtn or ui.SpinClose)
end)

local function openExclusiveModal(targetModal: Frame?)
	openOnlyModal(targetModal, firstIndexCardBtn)
end

bindButton(ui.VIPBtn, function()
	openExclusiveModal(ui.IndexModal)
end)

bindButton(ui.EggsDockBtn, function()
	openOnlyModal(ui.IndexModal, firstIndexCardBtn)
end)

bindButton(ui.SpeedDockBtn, function()
	BuySpeedUpgradeEvent:FireServer()
end)

bindButton(ui.RebirthDockBtn, function()
	RebirthRequestEvent:FireServer()
end)

bindButton(ui.SpeedPlusBtn, function()
	BuySpeedUpgradeEvent:FireServer()
end)

bindButton(ui.CashPlusBtn, function()
	BuyRobuxItemEvent:FireServer("CashPack5K")
end)

bindButton(ui.IndexClose, function()
	closeAllModals()
end)

bindButton(ui.ShopClose, function()
	closeAllModals()
end)

bindButton(ui.SpinClose, function()
	closeAllModals()
end)

for passKey, btn in pairs(ui.PassButtonsByKey) do
	bindButton(btn, function()
		BuyRobuxItemEvent:FireServer(passKey)
	end)
end

for dpKey, btn in pairs(ui.DevProductButtons) do
	bindButton(btn, function()
		BuyRobuxItemEvent:FireServer(dpKey)
	end)
end

bindButton(ui.BuySpeedBtn, function()
	BuySpeedUpgradeEvent:FireServer()
end)

if ui.BuyFenceBtn then
	bindButton(ui.BuyFenceBtn, function()
		BuyFenceUpgradeEvent:FireServer()
	end)
end

if ui.BuyHintShopBtn then
	bindButton(ui.BuyHintShopBtn, function()
		BuySquishyHintEvent:FireServer()
	end)
end

if ui.BuyHintIndexBtn then
	bindButton(ui.BuyHintIndexBtn, function()
		BuySquishyHintEvent:FireServer()
	end)
end

bindButton(ui.RebirthBtn, function()
	RebirthRequestEvent:FireServer()
end)

bindButton(ui.SpinNowBtn, function()
	SpinWheelRequestEvent:FireServer()
end)

bindButton(ui.BuySpinCashBtn, function()
	BuySpinCashEvent:FireServer()
end)

bindButton(ui.BuySpinRobuxBtn, function()
	BuyRobuxItemEvent:FireServer("BuySpinRobux")
end)

for idx, ptBtn in ipairs(ui.PlaytimeButtons) do
	bindButton(ptBtn, function()
		ClaimPlaytimeRewardEvent:FireServer(idx)
	end)
end

bindButton(ui.ClaimDailyModalBtn, function()
	ClaimDailyRewardEvent:FireServer()
end)

-- Cache cosmetic client-side rotors, Moving Crystal Platforms, GateBarriers & StageChecklistBoards once
local cachedCosmeticRotors: { { Part: BasePart, Speed: number, Mode: string } } = {}
local cachedCrystalPlatforms: { { Part: BasePart, Index: number, BaseX: number, BaseY: number, BaseZ: number } } = {}
local cachedGateBarriers: { BasePart } = {}
local cachedVIPOnlyBarriers: { BasePart } = {}
local cachedChecklistBoards: { BasePart } = {}

local function refreshWorldCaches()
	local squishyWorld = Workspace:FindFirstChild("SquishyWorld")
	if not squishyWorld then
		return
	end
	table.clear(cachedCosmeticRotors)
	table.clear(cachedCrystalPlatforms)
	table.clear(cachedGateBarriers)
	table.clear(cachedVIPOnlyBarriers)
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

	local worldCoinsFolder = squishyWorld:FindFirstChild("WorldCoins")
	if worldCoinsFolder then
		for _, desc in ipairs(worldCoinsFolder:GetDescendants()) do
			if desc:IsA("BasePart") and desc:GetAttribute("CoinSpinRotor") and desc:GetAttribute("SpinSpeed") then
				table.insert(cachedCosmeticRotors, {
					Part = desc,
					Speed = desc:GetAttribute("SpinSpeed") :: number,
					Mode = "Y",
				})
			end
		end
	end

	for _, desc in ipairs(squishyWorld:GetDescendants()) do
		if desc:IsA("BasePart") then
			if string.find(desc.Name, "^GateBarrier_") then
				table.insert(cachedGateBarriers, desc)
			elseif desc:GetAttribute("VIPOnlyBarrier") == true then
				table.insert(cachedVIPOnlyBarriers, desc)
			elseif string.find(desc.Name, "^StageChecklistBoard_") then
				table.insert(cachedChecklistBoards, desc)
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

	if ui.TreadmillTurboBtn then
		ui.TreadmillTurboBtn.Visible = false
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

	if ui.SpeedCounterLbl then
		ui.SpeedCounterLbl.Text = string.format("⚡ <b>%s</b>", SlimeData.FormatNumber(spd))
	end
	ui.CashCounterLbl.Text = string.format("<b>$%s</b>", SlimeData.FormatNumber(state.Coins or 0))

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
			"✨ <b>FIND MY SQUISHY AND STEAL MY EGG (BRAINROT)</b>  |  Plot #%d  |  ⚡ <font color='#65FF8F'>$%s/sec</font>  |  Rebirths: %d%s",
			state.PlotIndex or 1,
			SlimeData.FormatNumber(state.PassiveIncomeRate or 0),
			state.Rebirths or 0,
			boostExtras
		)
		ui.TopContainer.BackgroundColor3 = Color3.fromRGB(18, 22, 40)
	end

	-- 1. 117 Squishy Collection Progress Bar (0 / 117 — 0% to 100%) using math.clamp
	local squishyRatio = math.clamp(foundCount / math.max(1, totalSquishies), 0, 1)
	if ui.SquishyBarFill then
		TweenService:Create(ui.SquishyBarFill, barTweenInfo, {
			Size = UDim2.fromScale(squishyRatio, 1),
		}):Play()
	end
	if ui.SquishyBarText then
		ui.SquishyBarText.Text = string.format(
			"📘 <b>117 SQUISHY COLLECTION:</b> <font color='#75FF9E'>%d / %d (%d%%)</font>",
			foundCount,
			totalSquishies,
			math.floor(squishyRatio * 100)
		)
	end

	if state.SloMoActive ~= nil then
		sloMoEnabled = state.SloMoActive == true
	end
	if ui.SloMoBtn then
		ui.SloMoBtn.BackgroundColor3 = if sloMoEnabled then Color3.fromRGB(65, 195, 85) else Color3.fromRGB(185, 42, 42)
		ui.SloMoBtn.Text = if sloMoEnabled then "<b>SloMo: ON</b>" else "<b>SloMo: OFF</b>"
		local sloCap = ui.SloMoBtn:FindFirstChild("Caption") :: TextLabel?
		if sloCap then
			sloCap.Text = if sloMoEnabled then "<b>SloMo: ON</b>" else "<b>SloMo: OFF</b>"
		end
	end

	local curFenceLvl = state.FenceLevel or 1

	if ui.BuyFenceBtn then
		if curFenceLvl >= #SlimeData.FenceLevels then
			ui.BuyFenceBtn.Text = "✅ <b>Fence MAX [Lv.8 • 35 Slots]</b>"
		else
			local nextFenceDef = SlimeData.GetFenceLevelDef(curFenceLvl + 1)
			local nextMax = if nextFenceDef then nextFenceDef.MaxBrainrots else 7
			ui.BuyFenceBtn.Text = string.format(
				"🧱 <b>Fence Lv.%d (%d Slots) - $%s</b>",
				curFenceLvl + 1,
				nextMax,
				SlimeData.FormatNumber(state.NextFenceCost or 500)
			)
		end
	end

	local hintStage = 1
	local foundMapForHint = state.Found or {}
	local unlockedHintsForHint = state.UnlockedHints or {}
	local unlockedLevelsForHint = state.UnlockedLevels or { ["1"] = true }
	for _, s in ipairs(SlimeData.Slimes) do
		local sKey = tostring((s :: any).Id)
		local numId = tonumber((s :: any).UnlockOrder or (s :: any).NumericId or s.Id) or 1
		if numId > 35 and not foundMapForHint[sKey] and not unlockedHintsForHint[sKey] then
			if unlockedLevelsForHint[tostring(s.Level)] then
				hintStage = s.Level
				break
			end
		end
	end
	local hintCost = SlimeData.GetHintCostForStage(hintStage)
	if ui.BuyHintShopBtn then
		ui.BuyHintShopBtn.Text = string.format("🔍 <b>Squishy Hint - $%s</b>", SlimeData.FormatNumber(hintCost))
	end
	if ui.BuyHintIndexBtn then
		ui.BuyHintIndexBtn.Text = string.format("🔍 <b>BUY SQUISHY HINT ($%s)</b>", SlimeData.FormatNumber(hintCost))
	end

	ui.RebirthBtn.Text = string.format(
		"🔥 <b>Rebirth #%d - $%s</b>",
		(state.Rebirths or 0) + 1,
		SlimeData.FormatNumber(state.NextRebirthCost or 5000)
	)
	ui.IndexTitle.Text = string.format("📘 <b>3D BRAINROT & SQUISHY INDEX (%d / %d)</b>", foundCount, totalSquishies)

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
		"🎁 <b>CLAIM DAILY LOGIN STREAK CHEST (DAY %d: +$1,500 CASH + 1 BONUS SPIN)</b>",
		(state.DailyStreak or 0) + 1
	)

	if state.OwnedPasses then
		for k, btn in pairs(ui.PassButtonsByKey) do
			if state.OwnedPasses[k] then
				btn.Text = "✅ <b>OWNED & ACTIVE</b>"
				btn.BackgroundColor3 = Color3.fromRGB(75, 225, 115)
			end
		end
		if state.OwnedPasses["LuckyEggRoll"] and ui.DevProductButtons and ui.DevProductButtons["LuckyEggRoll"] then
			local luckyBtn = ui.DevProductButtons["LuckyEggRoll"]
			local pill = luckyBtn:FindFirstChild("PricePill") :: TextLabel?
			if pill and pill:IsA("TextLabel") then
				pill.Text = "✅ <b>OWNED</b>"
				pill.BackgroundColor3 = Color3.fromRGB(75, 225, 115)
			end
		end
	end

	if state.Found then
		local sw = Workspace:FindFirstChild("SquishyWorld")
		local worldEggsFolder = sw and sw:FindFirstChild("WorldEggs")
		if worldEggsFolder then
			for sKey, isFound in pairs(state.Found) do
				if isFound then
					-- Both hatched Stage Eggs (#1-#35) and collected Squishies (#36-#117) permanently disappear on the client once completed!
					local m = findWorldEggModel(worldEggsFolder, tostring(sKey))
					hideWorldItemForLocalPlayer(m)
				end
			end
		end
	end

	if state.CollectedCoins then
		local sw = Workspace:FindFirstChild("SquishyWorld")
		local worldCoinsFolder = sw and sw:FindFirstChild("WorldCoins")
		if worldCoinsFolder then
			for coinId, isCollected in pairs(state.CollectedCoins) do
				if isCollected then
					local coinPart = findWorldCoinModel(worldCoinsFolder, tostring(coinId))
					hideWorldItemForLocalPlayer(coinPart)
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
					cardInfo.Status.Text = string.format("🔒 <b>$%d/s (+$%s Bonus)</b>", sData.IncomePerSec, SlimeData.FormatNumber(sData.CoinReward or 50))
					cardInfo.Status.TextColor3 = Color3.fromRGB(170, 180, 205)
				end
			end
		end
	end

	-- Toggle VIP Enclosure Walls (Only VIP members can walk through!)
	local isVIP = (state.OwnedPasses and state.OwnedPasses["VIP"]) == true
	for _, vipWall in ipairs(cachedVIPOnlyBarriers) do
		if vipWall and vipWall.Parent then
			vipWall.CanCollide = not isVIP
			vipWall.Transparency = if isVIP then 0.85 else 0.38
		end
	end

	-- Update cached Biome Gate Barriers (GateBarrier_2..9) with live counting-up requirements & picture cards!
	if #cachedGateBarriers == 0 then
		refreshWorldCaches()
	end
	if state.UnlockedLevels then
		for _, desc in ipairs(cachedGateBarriers) do
			if desc and desc.Parent then
				local lvlNum = tonumber(desc:GetAttribute("LevelId")) or 1
				local lvlId = tostring(lvlNum)
				local unlocked = state.UnlockedLevels[lvlId] == true
				desc.CanCollide = not unlocked
				desc.Transparency = if unlocked then 0.85 else 0.28
				desc.Color = if unlocked then Color3.fromRGB(15, 45, 25) else Color3.fromRGB(10, 12, 18)

				local prevStage = lvlNum - 1
				local reqFence = lvlNum
				local curFence = curFenceLvl
				local curCoins = cash

				local unlockPrompt = desc:FindFirstChild("UnlockStageGatePrompt", true) :: ProximityPrompt?
				if unlockPrompt then
					unlockPrompt.Enabled = not unlocked
					if prevStage >= 1 then
						unlockPrompt.ObjectText = string.format("Req: 100%% Stage %d + Fence Lv.%d", prevStage, reqFence)
					end
				end
				local skipPrompt = desc:FindFirstChild("SkipStageGatePaywallPrompt", true) :: ProximityPrompt?
				if skipPrompt then
					skipPrompt.Enabled = not unlocked
				end

				if prevStage >= 1 then
					local prevLvlInfo = SlimeData.Levels[prevStage]
					local prevStageName = if prevLvlInfo then string.upper(prevLvlInfo.Name) else ("STAGE " .. tostring(prevStage))
					local gateCost = (desc:GetAttribute("RequiredCoins") :: number?) or 0

					local foundBrainrots, totalBrainrots, foundSquishies, totalSquishies = SlimeData.GetStageBreakdown(state.Found or {}, prevStage)
					local totalStageItems = totalBrainrots + totalSquishies
					local foundStageItems = foundBrainrots + foundSquishies

					local headerText: string
					if unlocked then
						headerText = string.format("✅ STAGE %d UNLOCKED: %s  —  WAY TO STAGE %d IS OPEN!", prevStage, prevStageName, lvlNum)
					else
						headerText = string.format("📍 YOU ARE ON STAGE %d: %s  —  🔒 UNLOCK STAGE %d (%d / %d ITEMS FOUND)", prevStage, prevStageName, lvlNum, foundStageItems, totalStageItems)
					end

					-- Update SurfaceGuis on Front and Back faces of the Black Semi-Transparent Gate Wall
					for _, faceName in ipairs({ "Front", "Back" }) do
						local sg = desc:FindFirstChild("StageGateWallChecklistGui_" .. faceName) :: SurfaceGui?
						if sg then
							local hLbl = sg:FindFirstChild("WallHeaderLabel") :: TextLabel?
							if hLbl then
								hLbl.Text = headerText
								hLbl.TextColor3 = if unlocked then Color3.fromRGB(115, 255, 140) else Color3.fromRGB(255, 235, 75)
							end
							local summaryLbl = sg:FindFirstChild("WallReqSummaryLabel") :: TextLabel?
							if summaryLbl then
								summaryLbl.Text = string.format(
									"🥚 Brainrot Eggs: %d/%d   •   🧸 Squishies: %d/%d   •   🧱 Fence Level: Lv.%d/Lv.%d   •   💰 Gate Cash: $%s/$%s",
									foundBrainrots,
									totalBrainrots,
									foundSquishies,
									totalSquishies,
									curFence,
									reqFence,
									SlimeData.FormatNumber(curCoins),
									SlimeData.FormatNumber(gateCost)
								)
								summaryLbl.TextColor3 = if unlocked then Color3.fromRGB(180, 255, 200) else Color3.fromRGB(215, 235, 255)
							end
							local grid = sg:FindFirstChild("ItemsGridFrame")
							if grid then
								for _, card in ipairs(grid:GetChildren()) do
									if card:IsA("Frame") and card:GetAttribute("SlimeId") ~= nil then
										local sId = tostring(card:GetAttribute("SlimeId"))
										local isFound = (state.Found and state.Found[sId] == true)
										local countBadge = card:FindFirstChild("ItemCountBadge") :: TextLabel?
										if countBadge then
											if isFound then
												countBadge.Text = "1 / 1 ✅ FOUND!"
												countBadge.TextColor3 = Color3.fromRGB(85, 255, 125)
											else
												countBadge.Text = "0 / 1 ❌ MISSING"
												countBadge.TextColor3 = Color3.fromRGB(255, 85, 85)
											end
										end
										local stroke = card:FindFirstChild("CardStroke") :: UIStroke?
										if stroke then
											stroke.Color = if isFound then Color3.fromRGB(85, 255, 125) else Color3.fromRGB(60, 68, 85)
										end
										local icon = card:FindFirstChild("ItemIcon") :: ImageLabel?
										if icon then
											icon.ImageColor3 = if isFound then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(120, 120, 120)
										end
										card.BackgroundColor3 = if isFound then Color3.fromRGB(18, 42, 28) else Color3.fromRGB(24, 28, 38)
									end
								end
							end
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
					local foundEggs, totalEggs, foundSquishies, totalSquishiesInStage = SlimeData.GetStageBreakdown(state.Found, stageId)
					local totalItems = math.max(1, totalEggs + totalSquishiesInStage)
					local pct = math.floor(((foundEggs + foundSquishies) / totalItems) * 100)
					local jackpot = SlimeData.GetStageMasteryJackpot(stageId)
					local nextGateCost = if nextLevelInfo then SlimeData.GetStageGateUnlockCost(stageId + 1) else 0
					local nextReqText = if nextLevelInfo
						then string.format(
							"🔓 Stage %d Gate Req: 🧱 Fence Lv.%d/%d  |  💰 $%s",
							stageId + 1,
							curFenceLvl,
							stageId + 1,
							SlimeData.FormatNumber(nextGateCost)
						)
						else "👑 Final Stage: Complete 100% for Cosmic Mastery!"
					local statusPrefix = if pct >= 100 then "✅" else "🎯"
					local newText = string.format(
						"📋 STAGE %d: %s\n🥚 Brainrots: %d/%d  |  🧸 Squishies: %d/%d  |  🏆 100%% Jackpot: +$%s\n%s\n%s STAGE %d COMPLETION: %d%%",
						stageId,
						string.upper(levelInfo.Name),
						foundEggs,
						totalEggs,
						foundSquishies,
						totalSquishiesInStage,
						SlimeData.FormatNumber(jackpot),
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

	-- Update Like & Favorite VIP Reward Button State (PS5/Console & PC/Mobile safe)
	if ui.FavoriteNowBtn then
		if state.ClaimedLikeReward then
			ui.FavoriteNowBtn.Text = if isConsoleOrGamepad()
				then "⭐ <b>VIP SUPPORTER PERKS ACTIVE! (PRESS [O] TO CLOSE)</b>"
				else "⭐ <b>FAVORITE GAME ON ROBLOX!</b>"
		else
			ui.FavoriteNowBtn.Text = if isConsoleOrGamepad()
				then "⭐ <b>PRESS [X] TO CLAIM +$5,000 + 2 SPINS + 💖 VIP TAG!</b>"
				else "⭐ <b>FAVORITE GAME & CLAIM +$5,000 + 2 SPINS!</b>"
		end
	end
	if ui.ClaimLikeFavRewardBtn then
		if state.ClaimedLikeReward then
			ui.ClaimLikeFavRewardBtn.Text = "✅ <b>VIP SUPPORTER REWARDS CLAIMED!</b>"
			ui.ClaimLikeFavRewardBtn.BackgroundColor3 = Color3.fromRGB(65, 120, 95)
		else
			ui.ClaimLikeFavRewardBtn.Text = "🎁 <b>INSTANT CLAIM: +$5,000 + 2 SPINS + 💖 VIP TAG!</b>"
			ui.ClaimLikeFavRewardBtn.BackgroundColor3 = Color3.fromRGB(55, 215, 115)
		end
	end
	if ui.LikeFavHudBtn then
		local cap = ui.LikeFavHudBtn:FindFirstChild("Caption") :: TextLabel?
		if cap then
			cap.Text = if state.ClaimedLikeReward then "<b>💖 VIP!</b>" else "<b>+$5K FREE!</b>"
		end
		ui.LikeFavHudBtn.Text = if state.ClaimedLikeReward
			then "💖 <b>VIP SUPPORTER!</b>"
			else "💖 <b>LIKE & FAV (+$5K!)</b>"
	end
end

StateSyncEvent.OnClientEvent:Connect(applyStateToUI)

OpenModalEvent.OnClientEvent:Connect(function(modalName: string)
	closeAllModals()
	if modalName == "SpinWheel" or modalName == "DailyRewards" then
		ui.SpinModal.Visible = true
		if isConsoleOrGamepad() and ui.SpinNowBtn then
			pcall(function()
				GuiService.SelectedObject = ui.SpinNowBtn
			end)
		end
	elseif modalName == "RobuxShop" then
		ui.ShopModal.Visible = true
		local shopFocusBtn = (ui.PassButtonsByKey and ui.PassButtonsByKey["VIP"]) or ui.BuyFenceBtn or ui.ShopClose
		if isConsoleOrGamepad() and shopFocusBtn then
			pcall(function()
				GuiService.SelectedObject = shopFocusBtn
			end)
		end
	elseif modalName == "LikeFavorite" and ui.LikeFavoriteModal then
		ui.LikeFavoriteModal.Visible = true
		if isConsoleOrGamepad() and ui.ClaimLikeFavRewardBtn then
			pcall(function()
				GuiService.SelectedObject = ui.ClaimLikeFavRewardBtn
			end)
		end
	end
end)

if ui.LikeFavHudBtn and ui.LikeFavoriteModal then
	bindButton(ui.LikeFavHudBtn, function()
		openOnlyModal(ui.LikeFavoriteModal, ui.ClaimLikeFavRewardBtn or ui.FavoriteNowBtn)
	end)
end
if ui.LikeFavClose and ui.LikeFavoriteModal then
	bindButton(ui.LikeFavClose, function()
		closeAllModals()
	end)
end
if ui.FavoriteNowBtn then
	bindButton(ui.FavoriteNowBtn, function()
		-- 1. Always close all custom modals & clear gamepad selection first so CoreGui never collides with PlayerGui
		closeAllModals()
		-- 2. Immediately grant the +$5,000 Cash + 2 Spins + +15 Speed + 60s Shield + VIP Tag on 1st press!
		ClaimLikeFavoriteEvent:FireServer()
		-- 3. On PS5 / Console / Gamepad, NEVER call AvatarEditorService:PromptSetFavorite (CoreGui Favorite Item popup traps PS5 virtual cursor)
		if isConsoleOrGamepad() then
			showToast("💖 VIP SUPPORTER GIFT CLAIMED! +$5,000 Cash + 2 Spins + +15 Speed!", Color3.fromRGB(55, 215, 115))
		else
			task.delay(0.15, function()
				pcall(function()
					AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
				end)
			end)
		end
	end)
end
if ui.ClaimLikeFavRewardBtn then
	bindButton(ui.ClaimLikeFavRewardBtn, function()
		closeAllModals()
		ClaimLikeFavoriteEvent:FireServer()
	end)
end

if ui.GuideToggleBtn and ui.HowToPlayModal then
	bindButton(ui.GuideToggleBtn, function()
		openOnlyModal(ui.HowToPlayModal, ui.HowToPlayClose)
	end)
end
if ui.HowToPlayClose and ui.HowToPlayModal then
	bindButton(ui.HowToPlayClose, function()
		closeAllModals()
	end)
end

-- =========================================================================
-- ⚙️ SETTINGS PRO MODAL & CONTROLS WIRING (Creator Store 93583640955196 / 94517727460767)
-- =========================================================================
local voiceMultiplier = 1.0

if ui.SettingsProBtn and ui.SettingsProModal then
	bindButton(ui.SettingsProBtn, function()
		openOnlyModal(ui.SettingsProModal, ui.SettingsProClose)
	end)
end
if ui.SettingsProClose and ui.SettingsProModal then
	bindButton(ui.SettingsProClose, function()
		closeAllModals()
	end)
end

-- Row 1: 🧸 Kid-Friendly Easy Mode (Default ON: Gentle guidance & extra health)
local kidFriendlyMode = true
if ui.KidFriendlyToggleBtn then
	bindButton(ui.KidFriendlyToggleBtn, function()
		kidFriendlyMode = not kidFriendlyMode
		if kidFriendlyMode then
			ui.KidFriendlyToggleBtn.BackgroundColor3 = Color3.fromRGB(65, 215, 125)
			ui.KidFriendlyToggleBtn.Text = "ON (Gentle & Guided 💖)"
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.MaxHealth = 150
				hum.Health = 150
			end
		else
			ui.KidFriendlyToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 48, 68)
			ui.KidFriendlyToggleBtn.Text = "OFF (Normal Mode)"
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.MaxHealth = 100
				hum.Health = math.min(hum.Health, 100)
			end
		end
	end)
end

-- Row 2: Music & SFX Volume (0%, 50%, 100%)
if ui.SettingsVolumeBtns then
	for lvl, btn in pairs(ui.SettingsVolumeBtns) do
		bindButton(btn, function()
			local volFactor = lvl / 100
			for _, sound in ipairs(SoundService:GetDescendants()) do
				if sound:IsA("Sound") and not string.find(sound.Name, "BrainrotVoice") then
					pcall(function()
						sound.Volume = math.clamp(volFactor, 0, 1)
					end)
				end
			end
			for otherLvl, otherBtn in pairs(ui.SettingsVolumeBtns) do
				otherBtn.BackgroundColor3 = if otherLvl == lvl then Color3.fromRGB(65, 185, 255) else Color3.fromRGB(40, 48, 68)
			end
		end)
	end
end

-- Row 2: Brainrot Voice Volume (Mute / Normal / Boost)
if ui.SettingsVoiceBtns then
	for mode, btn in pairs(ui.SettingsVoiceBtns) do
		bindButton(btn, function()
			if mode == "Mute" then
				voiceMultiplier = 0.0
			elseif mode == "Boost" then
				voiceMultiplier = 2.0
			else
				voiceMultiplier = 1.0
			end
			for otherMode, otherBtn in pairs(ui.SettingsVoiceBtns) do
				otherBtn.BackgroundColor3 = if otherMode == mode then Color3.fromRGB(245, 95, 185) else Color3.fromRGB(40, 48, 68)
			end
		end)
	end
end

-- Row 3: Global Shadows (FPS Boost)
local shadowsEnabled = true
if ui.SettingsShadowsBtn then
	bindButton(ui.SettingsShadowsBtn, function()
		shadowsEnabled = not shadowsEnabled
		pcall(function()
			Lighting.GlobalShadows = shadowsEnabled
		end)
		if shadowsEnabled then
			ui.SettingsShadowsBtn.BackgroundColor3 = Color3.fromRGB(65, 215, 125)
			ui.SettingsShadowsBtn.Text = "ON (High Quality)"
		else
			ui.SettingsShadowsBtn.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
			ui.SettingsShadowsBtn.Text = "OFF (FPS Boost 🚀)"
		end
	end)
end

-- Row 4: FOV (70, 80, 90)
if ui.SettingsFovBtns then
	for fovVal, btn in pairs(ui.SettingsFovBtns) do
		bindButton(btn, function()
			local cam = Workspace.CurrentCamera
			if cam then
				TweenService:Create(cam, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					FieldOfView = fovVal,
				}):Play()
			end
			for otherFov, otherBtn in pairs(ui.SettingsFovBtns) do
				otherBtn.BackgroundColor3 = if otherFov == fovVal then Color3.fromRGB(255, 175, 45) else Color3.fromRGB(40, 48, 68)
			end
		end)
	end
end

-- Row 5: Hide Other Players (Lag Reducer)
local playersHidden = false
local function updatePlayerVisibility(plr: Player, hide: boolean)
	if plr == localPlayer then
		return
	end
	local char = plr.Character
	if not char then
		return
	end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") then
			part.LocalTransparencyModifier = if hide then 1 else 0
		end
	end
end
if ui.SettingsHidePlayersBtn then
	bindButton(ui.SettingsHidePlayersBtn, function()
		playersHidden = not playersHidden
		for _, plr in ipairs(Players:GetPlayers()) do
			updatePlayerVisibility(plr, playersHidden)
		end
		if playersHidden then
			ui.SettingsHidePlayersBtn.BackgroundColor3 = Color3.fromRGB(65, 215, 125)
			ui.SettingsHidePlayersBtn.Text = "ON (Hidden 👻)"
		else
			ui.SettingsHidePlayersBtn.BackgroundColor3 = Color3.fromRGB(40, 48, 68)
			ui.SettingsHidePlayersBtn.Text = "OFF (Show All)"
		end
	end)
	Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function()
			task.wait(0.5)
			if playersHidden then
				updatePlayerVisibility(plr, true)
			end
		end)
	end)
end

-- Row 6: Top HUD Visibility
if ui.SettingsTopHudToggleBtn then
	bindButton(ui.SettingsTopHudToggleBtn, function()
		ui.TopContainer.Visible = not ui.TopContainer.Visible
		if ui.TopContainer.Visible then
			ui.SettingsTopHudToggleBtn.BackgroundColor3 = Color3.fromRGB(65, 215, 125)
			ui.SettingsTopHudToggleBtn.Text = "Visible"
		else
			ui.SettingsTopHudToggleBtn.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
			ui.SettingsTopHudToggleBtn.Text = "Hidden"
		end
	end)
end

local BRAINROT_VOICE_SOUND_IDS: { [string]: string } = {
	["1"] = "rbxassetid://107015186635337", -- Tralalero Tralala
	["2"] = "rbxassetid://77891869376009", -- Lirili Larila
	["3"] = "rbxassetid://73597660759027", -- Trippi Troppi
	["4"] = "rbxassetid://105548451780438", -- Burbaloni Luliloli
	["5"] = "rbxassetid://132507332049936", -- Cappuccino Ninja
	["6"] = "rbxassetid://136160874492071", -- Ballerina Cappuccina
	["7"] = "rbxassetid://123254496530998", -- Chimpanzini Bananini
	["8"] = "rbxassetid://116835658278935", -- Frigo Camelo
	["9"] = "rbxassetid://138857089980331", -- Tung Tung Tung Sahur
	["10"] = "rbxassetid://95943432024838", -- Bombardiro Crocodilo
	["11"] = "rbxassetid://137909689525185", -- Bombombini Gusini
	["12"] = "rbxassetid://128210163482050", -- Glorbo Fruttodrillo
	["13"] = "rbxassetid://135871919265006", -- Brr Brr Patapim
	["14"] = "rbxassetid://78995795448312", -- Orangutini Ananasini
	["15"] = "rbxassetid://82401058692450", -- Boneca Ambalabu
	["16"] = "rbxassetid://81676654863951", -- Trulimero Trulicina
	["17"] = "rbxassetid://105522157502975", -- Girafa Celestre
	["18"] = "rbxassetid://129448508639486", -- Bri Bri Bicus Dicus
	["19"] = "rbxassetid://101820663420863", -- Garamaraman
	["20"] = "rbxassetid://130710880521053", -- Maxwell The Spinning Cat
	["21"] = "rbxassetid://112547585357624", -- La Vaca Saturno Saturnita
	["22"] = "rbxassetid://74500886543413", -- Il Cacto Hipopotamo
	["23"] = "rbxassetid://91691159755945", -- Blueberrinni Octopussini
	["24"] = "rbxassetid://71037632336586", -- Chef Crabracadabra
	["25"] = "rbxassetid://122317511050064", -- Chicleteira Bicicleteira
	["26"] = "rbxassetid://83344685907191", -- Spijuniro Golubiro
	["27"] = "rbxassetid://104643452311000", -- Tigrrullini Watermellini
	["28"] = "rbxassetid://73930806905242", -- Zibra Zubra Zibralini
	["29"] = "rbxassetid://80542793426400", -- Graipussi Medussi
	["30"] = "rbxassetid://78766358499084", -- Inferno Bombardiro Rex
	["31"] = "rbxassetid://127155994787755", -- Gattatino Neonino
	["32"] = "rbxassetid://105593983925243", -- Matteo The Wise
	["33"] = "rbxassetid://104532600549854", -- Udin Din Din Dun
	["34"] = "rbxassetid://133664122932845", -- Skibidi Cyber Titan
	["35"] = "rbxassetid://136631296291259", -- Cosmic Tralalero God
}

local activeBrainrotVoiceSound: Sound? = nil
local activeBrainrotTTS: Instance? = nil
local activeBrainrotTTSWire: Instance? = nil
local activeBrainrotTTSOutput: Instance? = nil

local function cleanupActiveBrainrotAudio()
	if activeBrainrotVoiceSound then
		pcall(function()
			activeBrainrotVoiceSound:Stop()
			activeBrainrotVoiceSound:Destroy()
		end)
		activeBrainrotVoiceSound = nil
	end
	if activeBrainrotTTSWire then
		pcall(function()
			activeBrainrotTTSWire:Destroy()
		end)
		activeBrainrotTTSWire = nil
	end
	if activeBrainrotTTSOutput then
		pcall(function()
			activeBrainrotTTSOutput:Destroy()
		end)
		activeBrainrotTTSOutput = nil
	end
	if activeBrainrotTTS then
		pcall(function()
			activeBrainrotTTS:Destroy()
		end)
		activeBrainrotTTS = nil
	end
end

local function playBrainrotVoiceAnnouncement(slimeId: string, slimeName: string)
	cleanupActiveBrainrotAudio()
	if voiceMultiplier <= 0 then
		return
	end

	local sIdStr = tostring(slimeId)
	local soundAsset = BRAINROT_VOICE_SOUND_IDS[sIdStr] or "rbxassetid://107015186635337"

	-- 1. Plays matching Roblox Brainrot Voice Sound in SoundService
	local voiceSound = Instance.new("Sound")
	voiceSound.Name = "BrainrotVoice_" .. sIdStr
	voiceSound.SoundId = soundAsset
	voiceSound.Volume = 2.4 * voiceMultiplier
	voiceSound.Parent = SoundService
	voiceSound:Play()
	activeBrainrotVoiceSound = voiceSound

	-- Cap playback duration to 4.5 seconds so longer songs play a crisp clip and never loop forever
	task.delay(4.5, function()
		if voiceSound == activeBrainrotVoiceSound then
			activeBrainrotVoiceSound = nil
		end
		if voiceSound.Parent then
			pcall(function()
				voiceSound:Stop()
			end)
			voiceSound:Destroy()
		end
	end)

	-- 2. Only trigger AudioTextToSpeech fallback if voiceSound fails to load
	task.delay(0.35, function()
		if voiceSound and voiceSound.Parent and not voiceSound.IsLoaded and voiceSound.TimeLength == 0 then
			pcall(function()
				local tts = Instance.new("AudioTextToSpeech")
				tts.Text = slimeName .. "!"
				tts.Volume = 2.0

				local output = Instance.new("AudioDeviceOutput")
				output.Player = localPlayer

				local wire = Instance.new("Wire")
				wire.SourceInstance = tts
				wire.TargetInstance = output

				tts.Parent = SoundService
				output.Parent = SoundService
				wire.Parent = SoundService

				activeBrainrotTTS = tts
				activeBrainrotTTSOutput = output
				activeBrainrotTTSWire = wire

				if (tts :: any).Play then
					(tts :: any):Play()
				end

				task.delay(4.5, function()
					if activeBrainrotTTS == tts then
						activeBrainrotTTS = nil
						activeBrainrotTTSOutput = nil
						activeBrainrotTTSWire = nil
					end
					pcall(function()
						wire:Destroy()
						output:Destroy()
						tts:Destroy()
					end)
				end)
			end)
		end
	end)
end

-- Wire clicking on all 117 Egg / Squishy cards in the Index Modal:
-- 1) Registers with bindButton for Console ButtonA + Mouse/Touch activation
-- 2) Sets pinnedGuideSquishyId = tostring(sId) so 3D arrow guides the player directly to that egg/squishy in the world!
-- 3) Plays authentic voice announcement for #1..#35 or satisfying pop for #36..#117
-- 4) Displays tracking toast
if ui.IndexCards then
	for sId, cardInfo in pairs(ui.IndexCards) do
		local sKey = tostring(sId)
		local numId = tonumber(sId) or 0
		local sData = SlimeData.ById[sKey]
		local sName = if sData then sData.Name else ("Squishy #" .. sKey)
		local stageNum = if sData then sData.Level else 1

		bindButton(cardInfo.Frame, function()
			pinnedGuideSquishyId = sKey
			setConsoleFocus(cardInfo.Frame)

			if numId >= 1 and numId <= 35 then
				playBrainrotVoiceAnnouncement(sKey, sName)
				showToast("🎯 <b>TRACKING EGG: " .. string.upper(sName) .. "!</b>\n🧭 Follow 3D Arrow to Stage " .. tostring(stageNum) .. "!", Color3.fromRGB(255, 215, 45))
			else
				pcall(function()
					local chime = Instance.new("Sound")
					chime.SoundId = "rbxassetid://9119713951"
					chime.Volume = 0.85
					chime.Parent = SoundService
					chime:Play()
					task.delay(1.5, function()
						chime:Destroy()
					end)
				end)
				showToast("🎯 <b>TRACKING SQUISHY: " .. string.upper(sName) .. "!</b>\n🧭 Follow 3D Arrow to Stage " .. tostring(stageNum) .. "!", Color3.fromRGB(115, 255, 140))
			end
		end)
	end
end

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

			local numId = tonumber((sData :: any).UnlockOrder or (sData :: any).NumericId or sData.Id or info.SquishyId) or 1
			local isBrainrot = numId <= 35 or (sData :: any).IsBrainrot == true
			if isBrainrot and info.ActionType ~= "EggStolen" then
				playBrainrotVoiceAnnouncement(tostring(info.SquishyId), sData.Name)
				showToast("🗣️🔊 " .. string.upper(sData.Name) .. "!!", Color3.fromRGB(255, 215, 45))
			end

			-- Immediately hide collected Squishy (#36-#117) or hatched Egg (#1-#35) on the client so it vanishes on contact!
			-- (Stolen eggs are hidden server-side by setWorldEggTaken so they remain visible if dropped when hit by a Boss!)
			if info.ActionType ~= "EggStolen" then
				local sw = Workspace:FindFirstChild("SquishyWorld")
				local worldEggsFolder = sw and sw:FindFirstChild("WorldEggs")
				if worldEggsFolder then
					local m = findWorldEggModel(worldEggsFolder, tostring(info.SquishyId))
					hideWorldItemForLocalPlayer(m)
				end
			end

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
				showToast(
					string.format(
						"✨ COLLECTED [%s] %s! Added to your 117 Squishy Index (+$%s Cash)!",
						string.upper(rarity),
						string.upper(sData.Name),
						SlimeData.FormatNumber(info.CoinsEarned or sData.CoinReward or 200)
					),
					Color3.fromRGB(45, 175, 85)
				)
				if not (latestState and latestState.ClaimedLikeReward) and not _G.ShownLikeFavReminderOnce then
					local foundTotal = if latestState and type(latestState.FoundCount) == "number" then latestState.FoundCount else 0
					local numId = tonumber((sData :: any).UnlockOrder or (sData :: any).NumericId or sData.Id) or 1
					if numId <= 35 or foundTotal >= 2 then
						_G.ShownLikeFavReminderOnce = true
						task.delay(3.2, function()
							if
								ui.LikeFavoriteModal
								and not (latestState and latestState.ClaimedLikeReward)
								and not ui.ShopModal.Visible
								and not ui.IndexModal.Visible
								and not ui.SpinModal.Visible
							then
								openOnlyModal(ui.LikeFavoriteModal, ui.ClaimLikeFavRewardBtn or ui.FavoriteNowBtn)
							end
						end)
					end
				end
			end
		end
	end
end)

CoinCollectedEvent.OnClientEvent:Connect(function(info: any)
	if type(info) == "table" and info.CoinId then
		local sw = Workspace:FindFirstChild("SquishyWorld")
		local worldCoinsFolder = sw and sw:FindFirstChild("WorldCoins")
		if worldCoinsFolder then
			local coinPart = findWorldCoinModel(worldCoinsFolder, tostring(info.CoinId))
			hideWorldItemForLocalPlayer(coinPart)
		end
		local earned = tonumber(info.CoinsEarned) or 45
		showToast(string.format("🪙 GRABBED GOLD COIN! +$%s BONUS CASH!", SlimeData.FormatNumber(earned)), Color3.fromRGB(245, 185, 35))
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
guidanceTargetPart.Size = Vector3.new(0.5, 0.5, 0.5)
guidanceTargetPart.Shape = Enum.PartType.Ball
guidanceTargetPart.Color = Color3.fromRGB(85, 255, 165)
guidanceTargetPart.Material = Enum.Material.Neon
guidanceTargetPart.Transparency = 1
guidanceTargetPart.Anchored = true
guidanceTargetPart.CanCollide = false
guidanceTargetPart.CanQuery = false
guidanceTargetPart.CanTouch = false
guidanceTargetPart.Position = Vector3.new(-94, 6, 54)
guidanceTargetPart.Parent = Workspace

local targetAtt = Instance.new("Attachment")
targetAtt.Name = "GuidanceTargetAtt"
targetAtt.Parent = guidanceTargetPart

-- Vertical Sky Beacon Pillar at Target
local skyBeaconPillar = Instance.new("Part")
skyBeaconPillar.Name = "GuidanceSkyBeacon3D"
skyBeaconPillar.Shape = Enum.PartType.Cylinder
skyBeaconPillar.Size = Vector3.new(35.0, 2.2, 2.2)
skyBeaconPillar.Color = Color3.fromRGB(85, 255, 165)
skyBeaconPillar.Material = Enum.Material.Neon
skyBeaconPillar.Transparency = 1
skyBeaconPillar.Anchored = true
skyBeaconPillar.CanCollide = false
skyBeaconPillar.CanQuery = false
skyBeaconPillar.CanTouch = false
skyBeaconPillar.CFrame = CFrame.new(-94, 18.5, 54) * CFrame.Angles(0, 0, math.rad(90))
skyBeaconPillar.Parent = guidanceTargetPart

-- Downward Pointer Cone above the Target
local pointerShaft = Instance.new("Part")
pointerShaft.Name = "PointerArrow3D"
pointerShaft.Size = Vector3.new(2.2, 4.8, 2.2)
pointerShaft.Color = Color3.fromRGB(255, 235, 65)
pointerShaft.Material = Enum.Material.Neon
pointerShaft.Transparency = 1
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
pointerSignLbl.Text = "🥚 STEAL STAGE EGG!"
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
guidanceBeam.Width0 = 1.4
guidanceBeam.Width1 = 1.4
guidanceBeam.Brightness = 1.5
guidanceBeam.LightEmission = 0.5
guidanceBeam.LightInfluence = 0
guidanceBeam.FaceCamera = true
guidanceBeam.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.55),
	NumberSequenceKeypoint.new(0.5, 0.35),
	NumberSequenceKeypoint.new(1, 0.65),
})
guidanceBeam.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 245, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(95, 255, 135)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 235, 65)),
})
guidanceBeam.Attachment1 = targetAtt
guidanceBeam.Parent = guidanceTargetPart

local arrowChainFolder = Instance.new("Folder")
arrowChainFolder.Name = "GuidanceArrowChainFolder"
arrowChainFolder.Parent = Workspace

local NUM_GROUND_ARROWS = 0
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
	[1] = Vector3.new(-94, 4, 50),
	[2] = Vector3.new(94, 4, 50),
	[3] = Vector3.new(-94, 4, 122),
	[4] = Vector3.new(94, 4, 122),
	[5] = Vector3.new(-94, 4, 194),
	[6] = Vector3.new(94, 4, 194),
	[7] = Vector3.new(-94, 4, 266),
}

local function getPlotStationPos(plotIdx: number, stationName: string): Vector3
	local sw = Workspace:FindFirstChild("SquishyWorld")
	local plots = sw and sw:FindFirstChild("PlayerPlots")
	local pModel = plots and plots:FindFirstChild("Plot_" .. tostring(plotIdx))
	if pModel then
		if stationName == "HatcheryDropZone" or stationName == "HatcheryPen" then
			local dropZone = pModel:FindFirstChild("HatcheryDropZone", true) :: BasePart?
			if dropZone then
				return dropZone.Position + Vector3.new(0, 2.5, 0)
			end
			local pen = pModel:FindFirstChild("HatcheryPen")
			local floor = pen and pen:FindFirstChild("HatcheryPenFloor") :: BasePart?
			if floor then
				return floor.Position + Vector3.new(0, 2.5, 0)
			end
		elseif stationName == "UpgradeFenceStand" or stationName == "UpgradeFence" then
			local fenceStand = pModel:FindFirstChild("UpgradeFenceStand", true) :: BasePart?
			if fenceStand then
				return fenceStand.Position + Vector3.new(0, 2.5, 0)
			end
		elseif stationName == "CollectCashPad" or stationName == "GrowOrCash" then
			local cashPad = pModel:FindFirstChild("CollectCashPad", true) :: BasePart?
			if cashPad then
				return cashPad.Position + Vector3.new(0, 2.5, 0)
			end
			local pen = pModel:FindFirstChild("HatcheryPen")
			local growSign = pen and (pen:FindFirstChild("GrowSquishyStand") or pen:FindFirstChild("GrowUpgradeStationSign")) :: BasePart?
			if growSign then
				return growSign.Position + Vector3.new(0, 2.5, 0)
			end
		end
	end
	return FALLBACK_PLOT_COORDS[plotIdx] or Vector3.new(-94, 4, 50)
end

local function computeNextGuidanceObjective(hrpPos: Vector3): (Vector3, string, string, Color3)
	if not latestState then
		return Vector3.new(0, 5, -95), "🥚 STEAL STAGE EGG!", "🧭 <b>FOLLOW 3D ARROW:</b> 🥚 Sneak into the Stage 1 Boss Nest to steal a Brainrot Egg!", Color3.fromRGB(255, 195, 65)
	end

	local plotIdx = tonumber(latestState.PlotIndex) or 1
	local foundMap = latestState.Found or {}
	local coins = tonumber(latestState.Coins) or 0
	local carriedEggs = tonumber(latestState.CarriedEggCount) or 0
	local hatchingCount = tonumber(latestState.HatchingCount) or 0
	local uncollectedCash = tonumber(latestState.UncollectedPlotCash) or 0
	local unlockedMap = latestState.UnlockedLevels or { ["1"] = true }
	local fenceLvl = tonumber(latestState.FenceLevel) or 1

	-- [PINNED TARGET] If the player clicked or selected any Squishy/Egg in the Index:
	if pinnedGuideSquishyId then
		local sKey = tostring(pinnedGuideSquishyId)
		local pData = SlimeData.ById[sKey]
		if pData then
			local isFound = foundMap[sKey] == true
			if not isFound then
				local sw = Workspace:FindFirstChild("SquishyWorld")
				local worldEggsFolder = sw and sw:FindFirstChild("WorldEggs")
				local itemPos = pData.SpawnOffset
				if worldEggsFolder then
					local m = findWorldEggModel(worldEggsFolder, sKey)
					if m and m:IsA("Model") then
						itemPos = m:GetPivot().Position
					end
				end
				local numId = tonumber((pData :: any).UnlockOrder or (pData :: any).NumericId or pData.Id) or 1
				local typeLabel = if numId <= 35 then "EGG" else "SQUISHY"
				return itemPos,
					string.format("🎯 PINNED %s: %s (STAGE %d)!", typeLabel, string.upper(pData.Name), pData.Level),
					string.format("🧭 <b>TRACKING %s:</b> Follow 3D Arrow to <b>%s</b> in Stage %d!", typeLabel, pData.Name, pData.Level),
					Color3.fromRGB(255, 215, 45)
			else
				pinnedGuideSquishyId = nil
			end
		else
			pinnedGuideSquishyId = nil
		end
	end

	-- 1. Carrying an Egg -> HatcheryDropZone ("🏡 DROP EGG IN FENCED PEN!")
	if carriedEggs > 0 or hatchingCount > 0 then
		local penPos = getPlotStationPos(plotIdx, "HatcheryDropZone")
		return penPos,
			"🏡 DROP EGG IN FENCED PEN!",
			"🧭 <b>FOLLOW 3D ARROW:</b> 🏡 Walk into your Plot's <b>Fenced Hatchery Pen</b> to drop & hatch your Brainrot Egg!",
			Color3.fromRGB(95, 255, 145)
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
	local reqFenceLvl = activeStage + 1
	local fCost = tonumber(latestState.NextFenceCost) or SlimeData.GetFenceUpgradeCost(fenceLvl)
	local gCost = if nextStageInfo then SlimeData.GetStageGateUnlockCost(activeStage + 1) else 0
	local neededCash = if fenceLvl < reqFenceLvl then fCost else gCost

	-- 2. Uncollected Plot Cash needed -> CollectCashPad ("💰 COLLECT RANCH CASH!")
	if uncollectedCash > 0 and ((foundInStage >= totalInStage and coins < neededCash) or uncollectedCash >= 250) then
		local cashPos = getPlotStationPos(plotIdx, "CollectCashPad")
		return cashPos,
			"💰 COLLECT RANCH CASH!",
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> 💰 Step on your Plot's <b>Collect Cash Pad</b> (+$%s Ready)!", SlimeData.FormatNumber(uncollectedCash)),
			Color3.fromRGB(95, 255, 145)
	end

	-- Find nearest available Boss Egg (#1-#35) and nearest uncollected Stage Squishy (#36-#117) in activeStage
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
					local m = findWorldEggModel(worldEggsFolder, sKey)
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

	-- 3. Missing Stage Brainrot Egg -> nearest Stage Boss Egg ("🥚 STEAL STAGE EGG!")
	if nearestEggPos then
		return nearestEggPos,
			"🥚 STEAL STAGE EGG!",
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> 🥚 Sneak into Stage %d Boss Nest & steal <b>%s</b> (%d/%d Found)!", activeStage, nearestEggName, foundInStage, totalInStage),
			Color3.fromRGB(255, 195, 65)
	end

	-- 4. Missing Stage Squishy -> nearest uncollected Stage Squishy ("🧸 FIND STAGE SQUISHY!")
	if nearestSquishyPos then
		return nearestSquishyPos,
			"🧸 FIND STAGE SQUISHY!",
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> 🧸 Find & collect <b>%s</b> in Stage %d (%d/%d Found)!", nearestSquishyName, activeStage, foundInStage, totalInStage),
			Color3.fromRGB(255, 145, 235)
	end

	-- 5. Fence Level < activeStage + 1 -> UpgradeFenceStand ("🧱 UPGRADE FENCE SIZE!")
	if nextStageInfo and fenceLvl < reqFenceLvl then
		local fencePos = getPlotStationPos(plotIdx, "UpgradeFenceStand")
		return fencePos,
			"🧱 UPGRADE FENCE SIZE!",
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> 🧱 Upgrade your Fence Size to <b>Lv.%d</b> ($%s) at your Plot!", reqFenceLvl, SlimeData.FormatNumber(fCost)),
			Color3.fromRGB(115, 255, 140)
	end

	-- 6. Ready to Unlock Next Stage Gate -> GateBarrier_<activeStage + 1> ("🔓 UNLOCK NEXT STAGE GATE!")
	if nextStageInfo then
		local gatePart = sw and sw:FindFirstChild("GateBarrier_" .. tostring(activeStage + 1), true) :: BasePart?
		local gatePos = if gatePart then gatePart.Position else Vector3.new(0, 5, nextStageInfo.ZStart)
		return gatePos,
			"🔓 UNLOCK NEXT STAGE GATE!",
			string.format("🧭 <b>FOLLOW 3D ARROW:</b> 🔓 Walk to <b>GateBarrier_%d</b> to unlock <b>%s</b> ($%s)!", activeStage + 1, nextStageInfo.Name, SlimeData.FormatNumber(gCost)),
			Color3.fromRGB(95, 255, 145)
	end

	-- Fallback when all 8 Stages are 100% Complete:
	local cashPos = getPlotStationPos(plotIdx, "CollectCashPad")
	return cashPos,
		"💰 COLLECT RANCH CASH!",
		"🧭 <b>100% ALL 8 STAGES COMPLETE!</b> 💰 Collect Ranch Cash or Rebirth for massive multipliers!",
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

		local targetPos, signText, hudText, themeCol = computeNextGuidanceObjective(hrp.Position)
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

		local dist = (targetPos - hrp.Position).Magnitude
		local showGuide = dist > 14.0
		guidanceBeam.Enabled = showGuide
		pointerBB.Enabled = showGuide

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
