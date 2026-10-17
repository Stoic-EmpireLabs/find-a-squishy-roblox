--!strict
--[[
	GameClient.client.luau
	Pure "Steal My Egg!" Client HUD & Controller (Zero Per-Frame Lag, 60 FPS):
	  - Matches the real game reference HUD (real_game_annotated_1_base_loop.png):
	      * Left 2x2 / Vertical Icon Grid: Shop, Index, Daily, SloMo
	      * Bottom-Left Stacked Speed ("⚡ 18 [+]") & Cash ("$100 [+]") Counters
	      * Right Dock: Eggs, +Speed, Rebirth
	      * Top Alert / Carried Egg Banner
	  - Updates GateBarriers on StateSync (zero RenderStepped Workspace scanning!)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SlimeData = require(Shared:WaitForChild("SlimeData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateSyncEvent = Remotes:WaitForChild("StateSync") :: RemoteEvent
local EggCapturedEvent = Remotes:WaitForChild("SquishyCaptured") :: RemoteEvent
local GuardianAlertEvent = Remotes:WaitForChild("GuardianAlert") :: RemoteEvent
local BuySpeedUpgradeEvent = Remotes:WaitForChild("BuySpeedUpgrade") :: RemoteEvent
local RebirthRequestEvent = Remotes:WaitForChild("RebirthRequest") :: RemoteEvent
local ClaimDailyRewardEvent = Remotes:WaitForChild("ClaimDailyReward") :: RemoteEvent
local ToggleSloMoEvent = Remotes:WaitForChild("ToggleSloMo") :: RemoteEvent
local GetInitialStateFunc = Remotes:WaitForChild("GetInitialState") :: RemoteFunction

local currentState: any = {
	Coins = 100,
	SpeedStat = 18,
	SpeedLevel = 1,
	NextSpeedCost = 50,
	Rebirths = 0,
	NextRebirthCost = 5000,
	DailyStreak = 0,
	SloMoActive = false,
	PlotIndex = 1,
	CarriedEggId = nil,
	Found = {},
	BackpackCounts = {},
	FoundCount = 0,
	TotalSquishies = #SlimeData.Slimes,
	PassiveIncomeRate = 0,
	UncollectedPlotCash = 0,
	UnlockedLevels = { ["1"] = true },
}

-- Remove old HUD if present
for _, name in ipairs({ "FindASquishyHUD", "StealMyEggHUD" }) do
	local old = playerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StealMyEggHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

local function addCorner(ui: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = ui
end

local function addStroke(ui: GuiObject, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = ui
end

-- 1. Top Status & Carried Egg Banner
local topBanner = Instance.new("Frame")
topBanner.Name = "TopBanner"
topBanner.Size = UDim2.fromOffset(560, 48)
topBanner.Position = UDim2.new(0.5, -280, 0, 10)
topBanner.BackgroundColor3 = Color3.fromRGB(24, 28, 46)
topBanner.BackgroundTransparency = 0.08
topBanner.Parent = screenGui
addCorner(topBanner, 14)
addStroke(topBanner, Color3.fromRGB(255, 215, 70), 2.5)

local topBannerLabel = Instance.new("TextLabel")
topBannerLabel.Size = UDim2.fromScale(1, 1)
topBannerLabel.BackgroundTransparency = 1
topBannerLabel.Font = Enum.Font.FredokaOne
topBannerLabel.TextSize = 19
topBannerLabel.TextColor3 = Color3.fromRGB(255, 245, 190)
topBannerLabel.Text = "🥚 STEAL MY EGG!  |  Plot #1  |  ⚡ $0/sec"
topBannerLabel.Parent = topBanner

-- Alert Toast Banner (Boss / Dropped Egg / Hatch Notifications)
local alertToast = Instance.new("TextLabel")
alertToast.Name = "AlertToast"
alertToast.Size = UDim2.fromOffset(620, 44)
alertToast.Position = UDim2.new(0.5, -310, 0, 66)
alertToast.BackgroundColor3 = Color3.fromRGB(215, 45, 65)
alertToast.Font = Enum.Font.FredokaOne
alertToast.TextSize = 20
alertToast.TextColor3 = Color3.fromRGB(255, 255, 255)
alertToast.Text = ""
alertToast.Visible = false
alertToast.Parent = screenGui
addCorner(alertToast, 12)
addStroke(alertToast, Color3.fromRGB(255, 235, 95), 2.5)

local toastToken = 0
local function showToast(msg: string, bgColor: Color3?)
	toastToken += 1
	local myToken = toastToken
	alertToast.BackgroundColor3 = bgColor or Color3.fromRGB(215, 45, 65)
	alertToast.Text = msg
	alertToast.Visible = true
	task.delay(3.6, function()
		if toastToken == myToken then
			alertToast.Visible = false
		end
	end)
end

-- 2. Left 2x2 Icon Grid (Shop, Index, Daily, SloMo - matches real_game_annotated_1_base_loop.png)
local leftGrid = Instance.new("Frame")
leftGrid.Name = "LeftMenuGrid"
leftGrid.Size = UDim2.fromOffset(164, 164)
leftGrid.Position = UDim2.new(0, 16, 0.5, -90)
leftGrid.BackgroundTransparency = 1
leftGrid.Parent = screenGui

local function makeSquareBtn(parent: Instance, name: string, iconText: string, labelText: string, bgColor: Color3, pos: UDim2, onClick: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.fromOffset(74, 74)
	btn.Position = pos
	btn.BackgroundColor3 = bgColor
	btn.Text = ""
	btn.Parent = parent
	addCorner(btn, 14)
	addStroke(btn, Color3.fromRGB(255, 255, 255), 2.5)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 42)
	icon.Position = UDim2.fromOffset(0, 4)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.FredokaOne
	icon.TextSize = 28
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.Text = iconText
	icon.Parent = btn

	local cap = Instance.new("TextLabel")
	cap.Name = "Caption"
	cap.Size = UDim2.new(1, 0, 0, 24)
	cap.Position = UDim2.fromOffset(0, 46)
	cap.BackgroundTransparency = 1
	cap.Font = Enum.Font.FredokaOne
	cap.TextSize = 15
	cap.TextColor3 = Color3.fromRGB(255, 255, 255)
	cap.Text = labelText
	cap.Parent = btn
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(15, 15, 25)
	st.Thickness = 2
	st.Parent = cap

	btn.MouseButton1Click:Connect(onClick)
	return btn
end

-- 3. Bottom-Left Stacked Speed & Cash Counters (matches real_game_annotated_1_base_loop.png)
local bottomLeftFrame = Instance.new("Frame")
bottomLeftFrame.Name = "BottomLeftStats"
bottomLeftFrame.Size = UDim2.fromOffset(240, 96)
bottomLeftFrame.Position = UDim2.new(0, 18, 1, -116)
bottomLeftFrame.BackgroundTransparency = 1
bottomLeftFrame.Parent = screenGui

local speedCounterLbl = Instance.new("TextLabel")
speedCounterLbl.Name = "SpeedCounter"
speedCounterLbl.Size = UDim2.fromOffset(180, 42)
speedCounterLbl.Position = UDim2.fromOffset(0, 0)
speedCounterLbl.BackgroundTransparency = 1
speedCounterLbl.Font = Enum.Font.FredokaOne
speedCounterLbl.TextSize = 34
speedCounterLbl.TextXAlignment = Enum.TextXAlignment.Left
speedCounterLbl.TextColor3 = Color3.fromRGB(65, 220, 255)
speedCounterLbl.Text = "⚡ 18"
speedCounterLbl.Parent = bottomLeftFrame
local spStroke = Instance.new("UIStroke")
spStroke.Color = Color3.fromRGB(12, 18, 30)
spStroke.Thickness = 3
spStroke.Parent = speedCounterLbl

local speedPlusBtn = Instance.new("TextButton")
speedPlusBtn.Size = UDim2.fromOffset(36, 36)
speedPlusBtn.Position = UDim2.fromOffset(186, 4)
speedPlusBtn.BackgroundColor3 = Color3.fromRGB(65, 225, 85)
speedPlusBtn.Font = Enum.Font.FredokaOne
speedPlusBtn.TextSize = 24
speedPlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
speedPlusBtn.Text = "+"
speedPlusBtn.Parent = bottomLeftFrame
addCorner(speedPlusBtn, 8)
addStroke(speedPlusBtn, Color3.fromRGB(15, 40, 18), 2.5)
speedPlusBtn.MouseButton1Click:Connect(function()
	BuySpeedUpgradeEvent:FireServer()
end)

local cashCounterLbl = Instance.new("TextLabel")
cashCounterLbl.Name = "CashCounter"
cashCounterLbl.Size = UDim2.fromOffset(180, 44)
cashCounterLbl.Position = UDim2.fromOffset(0, 46)
cashCounterLbl.BackgroundTransparency = 1
cashCounterLbl.Font = Enum.Font.FredokaOne
cashCounterLbl.TextSize = 34
cashCounterLbl.TextXAlignment = Enum.TextXAlignment.Left
cashCounterLbl.TextColor3 = Color3.fromRGB(75, 245, 95)
cashCounterLbl.Text = "$100"
cashCounterLbl.Parent = bottomLeftFrame
local cashStroke = Instance.new("UIStroke")
cashStroke.Color = Color3.fromRGB(12, 28, 14)
cashStroke.Thickness = 3
cashStroke.Parent = cashCounterLbl

local cashPlusBtn = Instance.new("TextButton")
cashPlusBtn.Size = UDim2.fromOffset(36, 36)
cashPlusBtn.Position = UDim2.fromOffset(186, 50)
cashPlusBtn.BackgroundColor3 = Color3.fromRGB(65, 225, 85)
cashPlusBtn.Font = Enum.Font.FredokaOne
cashPlusBtn.TextSize = 24
cashPlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cashPlusBtn.Text = "+"
cashPlusBtn.Parent = bottomLeftFrame
addCorner(cashPlusBtn, 8)
addStroke(cashPlusBtn, Color3.fromRGB(15, 40, 18), 2.5)
cashPlusBtn.MouseButton1Click:Connect(function()
	ClaimDailyRewardEvent:FireServer()
end)

-- 4. Right Vertical Dock (Eggs, +Speed, Rebirth)
local rightDock = Instance.new("Frame")
rightDock.Name = "RightDock"
rightDock.Size = UDim2.fromOffset(82, 250)
rightDock.Position = UDim2.new(1, -96, 0.5, -125)
rightDock.BackgroundTransparency = 1
rightDock.Parent = screenGui

-- 5. Modals: Egg Index Modal & Shop/Upgrade Modal
local indexModal = Instance.new("Frame")
indexModal.Name = "EggIndexModal"
indexModal.Size = UDim2.fromOffset(620, 420)
indexModal.Position = UDim2.new(0.5, -310, 0.5, -210)
indexModal.BackgroundColor3 = Color3.fromRGB(24, 28, 46)
indexModal.Visible = false
indexModal.Parent = screenGui
addCorner(indexModal, 16)
addStroke(indexModal, Color3.fromRGB(85, 200, 255), 3)

local indexTitle = Instance.new("TextLabel")
indexTitle.Size = UDim2.new(1, -60, 0, 48)
indexTitle.Position = UDim2.fromOffset(18, 6)
indexTitle.BackgroundTransparency = 1
indexTitle.Font = Enum.Font.FredokaOne
indexTitle.TextSize = 24
indexTitle.TextXAlignment = Enum.TextXAlignment.Left
indexTitle.TextColor3 = Color3.fromRGB(255, 235, 95)
indexTitle.Text = "📘 STOLEN EGG INDEX (0 / 35)"
indexTitle.Parent = indexModal

local indexClose = Instance.new("TextButton")
indexClose.Size = UDim2.fromOffset(38, 38)
indexClose.Position = UDim2.new(1, -48, 0, 10)
indexClose.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
indexClose.Font = Enum.Font.FredokaOne
indexClose.TextSize = 20
indexClose.TextColor3 = Color3.fromRGB(255, 255, 255)
indexClose.Text = "X"
indexClose.Parent = indexModal
addCorner(indexClose, 10)
indexClose.MouseButton1Click:Connect(function()
	indexModal.Visible = false
end)

local indexScroll = Instance.new("ScrollingFrame")
indexScroll.Size = UDim2.new(1, -28, 1, -68)
indexScroll.Position = UDim2.fromOffset(14, 56)
indexScroll.BackgroundTransparency = 1
indexScroll.ScrollBarThickness = 8
indexScroll.Parent = indexModal

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(136, 92)
gridLayout.CellPadding = UDim2.fromOffset(10, 10)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = indexScroll

local indexCards: { [string]: { Frame: Frame, Status: TextLabel } } = {}
for idx, slime in ipairs(SlimeData.Slimes) do
	local anySlime = slime :: any
	local card = Instance.new("Frame")
	card.LayoutOrder = idx
	card.BackgroundColor3 = Color3.fromRGB(36, 42, 68)
	card.Parent = indexScroll
	addCorner(card, 10)
	addStroke(card, anySlime.BodyColor or slime.Color or Color3.fromRGB(255, 255, 255), 2)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -8, 0, 42)
	nameLbl.Position = UDim2.fromOffset(4, 4)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextSize = 14
	nameLbl.TextWrapped = true
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Text = string.format("%s\n[Stage %d]", slime.Name, slime.Level)
	nameLbl.Parent = card

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Size = UDim2.new(1, -8, 0, 34)
	statusLbl.Position = UDim2.fromOffset(4, 50)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Font = Enum.Font.GothamBold
	statusLbl.TextSize = 13
	statusLbl.TextColor3 = Color3.fromRGB(170, 180, 205)
	statusLbl.Text = string.format("🔒 $%d/s", anySlime.IncomePerSec or slime.CoinsPerSec or 10)
	statusLbl.Parent = card

	indexCards[tostring(slime.Id)] = { Frame = card, Status = statusLbl }
end
indexScroll.CanvasSize = UDim2.fromOffset(0, math.ceil(#SlimeData.Slimes / 4) * 104)

-- Shop & Speed Upgrade Modal
local shopModal = Instance.new("Frame")
shopModal.Name = "ShopModal"
shopModal.Size = UDim2.fromOffset(480, 310)
shopModal.Position = UDim2.new(0.5, -240, 0.5, -155)
shopModal.BackgroundColor3 = Color3.fromRGB(24, 28, 46)
shopModal.Visible = false
shopModal.Parent = screenGui
addCorner(shopModal, 16)
addStroke(shopModal, Color3.fromRGB(255, 195, 55), 3)

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, -60, 0, 48)
shopTitle.Position = UDim2.fromOffset(18, 6)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.FredokaOne
shopTitle.TextSize = 24
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.TextColor3 = Color3.fromRGB(255, 215, 70)
shopTitle.Text = "🛒 SPEED TREADMILL & REBIRTH SHOP"
shopTitle.Parent = shopModal

local shopClose = Instance.new("TextButton")
shopClose.Size = UDim2.fromOffset(38, 38)
shopClose.Position = UDim2.new(1, -48, 0, 10)
shopClose.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
shopClose.Font = Enum.Font.FredokaOne
shopClose.TextSize = 20
shopClose.TextColor3 = Color3.fromRGB(255, 255, 255)
shopClose.Text = "X"
shopClose.Parent = shopModal
addCorner(shopClose, 10)
shopClose.MouseButton1Click:Connect(function()
	shopModal.Visible = false
end)

local buySpeedBtn = Instance.new("TextButton")
buySpeedBtn.Size = UDim2.new(1, -36, 0, 64)
buySpeedBtn.Position = UDim2.fromOffset(18, 68)
buySpeedBtn.BackgroundColor3 = Color3.fromRGB(55, 195, 255)
buySpeedBtn.Font = Enum.Font.FredokaOne
buySpeedBtn.TextSize = 20
buySpeedBtn.TextColor3 = Color3.fromRGB(15, 20, 32)
buySpeedBtn.Text = "🦖 Upgrade Treadmill (+4 Speed) - $50"
buySpeedBtn.Parent = shopModal
addCorner(buySpeedBtn, 12)
buySpeedBtn.MouseButton1Click:Connect(function()
	BuySpeedUpgradeEvent:FireServer()
end)

local rebirthBtn = Instance.new("TextButton")
rebirthBtn.Size = UDim2.new(1, -36, 0, 64)
rebirthBtn.Position = UDim2.fromOffset(18, 146)
rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 125, 215)
rebirthBtn.Font = Enum.Font.FredokaOne
rebirthBtn.TextSize = 20
rebirthBtn.TextColor3 = Color3.fromRGB(20, 15, 30)
rebirthBtn.Text = "✨ Rebirth (+50% Cash & Faster Treadmill) - $5,000"
rebirthBtn.Parent = shopModal
addCorner(rebirthBtn, 12)
rebirthBtn.MouseButton1Click:Connect(function()
	RebirthRequestEvent:FireServer()
end)

local dailyBtn = Instance.new("TextButton")
dailyBtn.Size = UDim2.new(1, -36, 0, 58)
dailyBtn.Position = UDim2.fromOffset(18, 224)
dailyBtn.BackgroundColor3 = Color3.fromRGB(95, 235, 115)
dailyBtn.Font = Enum.Font.FredokaOne
dailyBtn.TextSize = 19
dailyBtn.TextColor3 = Color3.fromRGB(15, 25, 18)
dailyBtn.Text = "🎁 Claim Daily Reward (+Cash, +Speed & +Bear Trap)"
dailyBtn.Parent = shopModal
addCorner(dailyBtn, 12)
dailyBtn.MouseButton1Click:Connect(function()
	ClaimDailyRewardEvent:FireServer()
end)

-- Populate Left 2x2 Grid & Right Dock Buttons
makeSquareBtn(leftGrid, "ShopBtn", "🛒", "Shop", Color3.fromRGB(255, 175, 45), UDim2.fromOffset(0, 0), function()
	shopModal.Visible = not shopModal.Visible
	indexModal.Visible = false
end)

makeSquareBtn(leftGrid, "IndexBtn", "📘", "Index", Color3.fromRGB(55, 185, 255), UDim2.fromOffset(84, 0), function()
	indexModal.Visible = not indexModal.Visible
	shopModal.Visible = false
end)

makeSquareBtn(leftGrid, "DailyBtn", "🎁", "Daily", Color3.fromRGB(245, 95, 185), UDim2.fromOffset(0, 84), function()
	ClaimDailyRewardEvent:FireServer()
end)

local sloMoBtn = makeSquareBtn(leftGrid, "SloMoBtn", "🐢", "SloMo", Color3.fromRGB(95, 215, 125), UDim2.fromOffset(84, 84), function()
	ToggleSloMoEvent:FireServer()
end)

makeSquareBtn(rightDock, "EggsBtn", "🥚", "Eggs", Color3.fromRGB(175, 95, 255), UDim2.fromOffset(4, 0), function()
	indexModal.Visible = not indexModal.Visible
	shopModal.Visible = false
end)

makeSquareBtn(rightDock, "SpeedBtn", "🦖", "+Speed", Color3.fromRGB(55, 205, 255), UDim2.fromOffset(4, 84), function()
	BuySpeedUpgradeEvent:FireServer()
end)

makeSquareBtn(rightDock, "RebirthDockBtn", "✨", "Rebirth", Color3.fromRGB(255, 125, 75), UDim2.fromOffset(4, 168), function()
	RebirthRequestEvent:FireServer()
end)

-- Update Local Gate Barriers & HUD on StateSync
local function applyStateToUI(state: any)
	currentState = state

	speedCounterLbl.Text = string.format("⚡ %d", state.SpeedStat or 18)
	cashCounterLbl.Text = string.format("$%d", state.Coins or 0)

	if state.CarriedEggId then
		local sData = SlimeData.ById[state.CarriedEggId]
		local eggName = if sData then string.upper(sData.Name) else "EGG"
		topBannerLabel.Text = string.format("🚨 CARRYING %s! RUN TO PLOT #%d INCUBATOR! 🚨", eggName, state.PlotIndex or 1)
		topBanner.BackgroundColor3 = Color3.fromRGB(185, 35, 55)
	else
		topBannerLabel.Text = string.format(
			"🥚 Plot #%d  |  ⚡ $%d/sec  |  Eggs: %d/%d",
			state.PlotIndex or 1,
			state.PassiveIncomeRate or 0,
			state.FoundCount or 0,
			state.TotalSquishies or 35
		)
		topBanner.BackgroundColor3 = Color3.fromRGB(24, 28, 46)
	end

	local sloCap = sloMoBtn:FindFirstChild("Caption") :: TextLabel?
	if sloCap then
		sloCap.Text = if state.SloMoActive then "SloMo ON" else "SloMo"
	end

	buySpeedBtn.Text = string.format("🦖 Upgrade Treadmill (+4 Speed) [Lv.%d] - $%d", state.SpeedLevel or 1, state.NextSpeedCost or 50)
	rebirthBtn.Text = string.format("✨ Rebirth #%d (+50%% Cash) - $%d", (state.Rebirths or 0) + 1, state.NextRebirthCost or 5000)
	indexTitle.Text = string.format("📘 STOLEN EGG INDEX (%d / %d)", state.FoundCount or 0, state.TotalSquishies or 35)

	if state.Found then
		for sId, cardInfo in pairs(indexCards) do
			local sData = SlimeData.ById[sId]
			if sData then
				if state.Found[sId] then
					cardInfo.Frame.BackgroundColor3 = Color3.fromRGB(48, 78, 62)
					cardInfo.Status.Text = string.format("✅ HATCHED ($%d/s)", sData.IncomePerSec)
					cardInfo.Status.TextColor3 = Color3.fromRGB(110, 255, 140)
				else
					cardInfo.Frame.BackgroundColor3 = Color3.fromRGB(36, 42, 68)
					cardInfo.Status.Text = string.format("🔒 $%d/s", sData.IncomePerSec)
					cardInfo.Status.TextColor3 = Color3.fromRGB(170, 180, 205)
				end
			end
		end
	end

	-- Update Biome Gate Barriers locally based on player's SpeedStat
	local squishyWorld = Workspace:FindFirstChild("SquishyWorld")
	local levelsFolder = squishyWorld and squishyWorld:FindFirstChild("Levels")
	if levelsFolder and state.UnlockedLevels then
		for _, lvlFolder in ipairs(levelsFolder:GetChildren()) do
			for _, desc in ipairs(lvlFolder:GetDescendants()) do
				if desc:IsA("BasePart") and string.find(desc.Name, "^GateBarrier_") then
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
end

StateSyncEvent.OnClientEvent:Connect(applyStateToUI)

EggCapturedEvent.OnClientEvent:Connect(function(info: any)
	if type(info) == "table" and info.SquishyId then
		local sData = SlimeData.ById[info.SquishyId]
		if sData then
			showToast(
				string.format("✨ HATCHED %s! Equip it from your Hotbar & place it on a Pedestal! (+$%d/s)", string.upper(sData.Name), sData.IncomePerSec),
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
