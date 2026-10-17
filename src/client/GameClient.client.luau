--!strict
-- GameClient.client.luau
-- Interactive Client HUD, 3D Paid Egg Guide Beam, Slimeopedia + Morph Controls,
-- Coloring Trails Shop, Pen & Million-Speed Treadmill Upgrades, and Local Gate/Egg VFX!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SlimeData = require(Shared:WaitForChild("SlimeData"))
local UpgradeData = require(Shared:WaitForChild("UpgradeData"))

local remotesFolder = ReplicatedStorage:WaitForChild("SquishyRemotes")
local stateSyncRemote = remotesFolder:WaitForChild("StateSync") :: RemoteEvent
local notifyRemote = remotesFolder:WaitForChild("Notification") :: RemoteEvent
local actionRemote = remotesFolder:WaitForChild("ActionRequest") :: RemoteEvent

-- ============================================================================
-- 1. CLIENT STATE & SOUND SYNTHESIS
-- ============================================================================
local clientState = {
	Coins = 100,
	StoredPenCoins = 0,
	SpeedPower = 100,
	WalkSpeed = 18,
	PenTier = 1,
	TreadmillTier = 1,
	GelTier = 1,
	JumpTier = 1,
	PlantedEggs = {} :: { [string]: boolean },
	PlantedCount = 0,
	MaxUnlockedLevel = 1,
	IncomePerSec = 0,
	OwnedTrails = {} :: { [string]: boolean },
	EquippedTrail = "",
	VIPGuideUnlocked = false,
	ActiveGuideEggId = nil :: number?,
	CurrentMorphId = nil :: number?,
	TinyMode = false,
	CarryingEggId = nil :: number?,
	PlotIndex = nil :: number?,
}

local function playUiSound(soundId: string, pitch: number?, volume: number?)
	local snd = Instance.new("Sound")
	snd.SoundId = soundId
	snd.PlaybackSpeed = pitch or 1.0
	snd.Volume = volume or 0.5
	snd.Parent = SoundService
	snd:Play()
	snd.Ended:Connect(function()
		snd:Destroy()
	end)
end

-- ============================================================================
-- 2. BUILD COMPLETE PLAYER HUD & MODAL PANELS
-- ============================================================================
local existingGui = playerGui:FindFirstChild("FindASquishyHUD")
if existingGui then
	existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FindASquishyHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

local function addCorner(inst: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = inst
end

local function addStroke(inst: GuiObject, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
end

-- TOP STATUS BAR (Coins, Speed Power, Level Planted Progress, Quick Teleports)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(0, 760, 0, 62)
topBar.Position = UDim2.new(0.5, -380, 0, 10)
topBar.BackgroundColor3 = Color3.fromRGB(22, 26, 42)
topBar.BackgroundTransparency = 0.08
topBar.Parent = screenGui
addCorner(topBar, 14)
addStroke(topBar, Color3.fromRGB(95, 225, 255), 2.5)

local coinsBadge = Instance.new("TextLabel")
coinsBadge.Size = UDim2.new(0, 175, 0, 44)
coinsBadge.Position = UDim2.new(0, 10, 0, 9)
coinsBadge.BackgroundColor3 = Color3.fromRGB(36, 44, 68)
coinsBadge.Font = Enum.Font.FredokaOne
coinsBadge.TextSize = 18
coinsBadge.TextColor3 = Color3.fromRGB(255, 230, 65)
coinsBadge.Text = "💰 $100 (+0/s)"
coinsBadge.Parent = topBar
addCorner(coinsBadge, 10)

local speedBadge = Instance.new("TextLabel")
speedBadge.Size = UDim2.new(0, 185, 0, 44)
speedBadge.Position = UDim2.new(0, 192, 0, 9)
speedBadge.BackgroundColor3 = Color3.fromRGB(36, 44, 68)
speedBadge.Font = Enum.Font.FredokaOne
speedBadge.TextSize = 18
speedBadge.TextColor3 = Color3.fromRGB(95, 240, 255)
speedBadge.Text = "⚡ 100 SPEED"
speedBadge.Parent = topBar
addCorner(speedBadge, 10)

local progressBadge = Instance.new("TextLabel")
progressBadge.Size = UDim2.new(0, 210, 0, 44)
progressBadge.Position = UDim2.new(0, 384, 0, 9)
progressBadge.BackgroundColor3 = Color3.fromRGB(36, 44, 68)
progressBadge.Font = Enum.Font.FredokaOne
progressBadge.TextSize = 16
progressBadge.TextColor3 = Color3.fromRGB(125, 255, 145)
progressBadge.Text = "🥚 Lvl 1 Planted: 0 / 5"
progressBadge.Parent = topBar
addCorner(progressBadge, 10)

local homeBtn = Instance.new("TextButton")
homeBtn.Size = UDim2.new(0, 72, 0, 44)
homeBtn.Position = UDim2.new(0, 602, 0, 9)
homeBtn.BackgroundColor3 = Color3.fromRGB(65, 195, 110)
homeBtn.Font = Enum.Font.FredokaOne
homeBtn.TextSize = 15
homeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
homeBtn.Text = "🏠 Pen"
homeBtn.Parent = topBar
addCorner(homeBtn, 10)
homeBtn.MouseButton1Click:Connect(function()
	playUiSound("rbxassetid://12221967", 1.1, 0.4)
	actionRemote:FireServer({ Action = "TeleportTo", Target = "BasePen" })
end)

local tmBtn = Instance.new("TextButton")
tmBtn.Size = UDim2.new(0, 72, 0, 44)
tmBtn.Position = UDim2.new(0, 680, 0, 9)
tmBtn.BackgroundColor3 = Color3.fromRGB(55, 165, 245)
tmBtn.Font = Enum.Font.FredokaOne
tmBtn.TextSize = 15
tmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tmBtn.Text = "🏃 Train"
tmBtn.Parent = topBar
addCorner(tmBtn, 10)
tmBtn.MouseButton1Click:Connect(function()
	playUiSound("rbxassetid://12221967", 1.2, 0.4)
	actionRemote:FireServer({ Action = "TeleportTo", Target = "Treadmill" })
end)

-- CARRIED EGG / CHASE ALERT BANNER
local carryBanner = Instance.new("TextLabel")
carryBanner.Name = "CarryBanner"
carryBanner.Size = UDim2.new(0, 620, 0, 42)
carryBanner.Position = UDim2.new(0.5, -310, 0, 78)
carryBanner.BackgroundColor3 = Color3.fromRGB(220, 55, 65)
carryBanner.Font = Enum.Font.FredokaOne
carryBanner.TextSize = 18
carryBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
carryBanner.Text = "🚨 CARRYING EGG! RUN TO YOUR BASE PEN BEFORE THE CHASERS CATCH YOU! 🚨"
carryBanner.Visible = false
carryBanner.Parent = screenGui
addCorner(carryBanner, 10)
addStroke(carryBanner, Color3.fromRGB(255, 235, 85), 2.5)

-- ACTIVE 3D EGG GUIDE BANNER
local guideBanner = Instance.new("TextLabel")
guideBanner.Name = "GuideBanner"
guideBanner.Size = UDim2.new(0, 540, 0, 34)
guideBanner.Position = UDim2.new(0.5, -270, 0, 125)
guideBanner.BackgroundColor3 = Color3.fromRGB(45, 38, 18)
guideBanner.BackgroundTransparency = 0.1
guideBanner.Font = Enum.Font.GothamBold
guideBanner.TextSize = 15
guideBanner.TextColor3 = Color3.fromRGB(255, 225, 75)
guideBanner.Text = "🧭 Egg Guide Active: Follow the Golden Beam!"
guideBanner.Visible = false
guideBanner.Parent = screenGui
addCorner(guideBanner, 8)
addStroke(guideBanner, Color3.fromRGB(255, 210, 55), 2)

-- NOTIFICATION POPUP TOAST
local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(0, 580, 0, 40)
toastLabel.Position = UDim2.new(0.5, -290, 1, -135)
toastLabel.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
toastLabel.BackgroundTransparency = 0.08
toastLabel.Font = Enum.Font.FredokaOne
toastLabel.TextSize = 17
toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
toastLabel.Text = ""
toastLabel.Visible = false
toastLabel.Parent = screenGui
addCorner(toastLabel, 10)
addStroke(toastLabel, Color3.fromRGB(255, 255, 255), 2)

local toastToken = 0
notifyRemote.OnClientEvent:Connect(function(data: any)
	if type(data) ~= "table" then
		return
	end
	toastToken += 1
	local myToken = toastToken
	toastLabel.Text = tostring(data.Message or "")
	toastLabel.Visible = true
	if data.Kind == "Success" then
		toastLabel.TextColor3 = Color3.fromRGB(115, 255, 145)
		playUiSound("rbxassetid://12221967", 1.35, 0.55)
	elseif data.Kind == "Error" then
		toastLabel.TextColor3 = Color3.fromRGB(255, 95, 95)
		playUiSound("rbxassetid://12221967", 0.75, 0.55)
	elseif data.Kind == "Warning" then
		toastLabel.TextColor3 = Color3.fromRGB(255, 215, 75)
		playUiSound("rbxassetid://12221967", 1.0, 0.55)
	else
		toastLabel.TextColor3 = Color3.fromRGB(215, 240, 255)
	end
	task.delay(4.2, function()
		if toastToken == myToken then
			toastLabel.Visible = false
		end
	end)
end)

-- ============================================================================
-- 3. LEFT SIDE ACTION BUTTON DOCK
-- ============================================================================
local leftDock = Instance.new("Frame")
leftDock.Name = "LeftDock"
leftDock.Size = UDim2.new(0, 195, 0, 325)
leftDock.Position = UDim2.new(0, 14, 0.5, -162)
leftDock.BackgroundTransparency = 1
leftDock.Parent = screenGui

local dockLayout = Instance.new("UIListLayout")
dockLayout.Padding = UDim.new(0, 8)
dockLayout.Parent = leftDock

local function makeDockButton(text: string, bgColor: Color3, onClick: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 44)
	btn.BackgroundColor3 = bgColor
	btn.Font = Enum.Font.FredokaOne
	btn.TextSize = 15
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.Parent = leftDock
	addCorner(btn, 10)
	addStroke(btn, Color3.fromRGB(255, 255, 255), 1.5)
	btn.MouseButton1Click:Connect(function()
		playUiSound("rbxassetid://12221967", 1.15, 0.4)
		onClick()
	end)
	return btn
end

-- ============================================================================
-- 4. MODAL PANELS (Slimeopedia & Egg Guide, Coloring Trails Shop, Upgrades, Family Boosts)
-- ============================================================================
local activeModal: Frame? = nil
local function toggleModal(targetModal: Frame)
	if activeModal == targetModal then
		targetModal.Visible = false
		activeModal = nil
	else
		if activeModal then
			activeModal.Visible = false
		end
		targetModal.Visible = true
		activeModal = targetModal
	end
end

local function createBaseModal(titleText: string, accentColor: Color3): (Frame, ScrollingFrame)
	local modal = Instance.new("Frame")
	modal.Size = UDim2.new(0, 680, 0, 430)
	modal.Position = UDim2.new(0.5, -340, 0.5, -205)
	modal.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
	modal.Visible = false
	modal.Parent = screenGui
	addCorner(modal, 16)
	addStroke(modal, accentColor, 3)

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -60, 0, 46)
	header.Position = UDim2.new(0, 18, 0, 6)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.FredokaOne
	header.TextSize = 22
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = accentColor
	header.Text = titleText
	header.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 38, 0, 38)
	closeBtn.Position = UDim2.new(1, -46, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(215, 65, 75)
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "X"
	closeBtn.Parent = modal
	addCorner(closeBtn, 8)
	closeBtn.MouseButton1Click:Connect(function()
		modal.Visible = false
		if activeModal == modal then
			activeModal = nil
		end
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -28, 1, -66)
	scroll.Position = UDim2.new(0, 14, 0, 54)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 8
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = modal

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.Parent = scroll

	return modal, scroll
end

-- MODAL 1: SLIMEOPEDIA, MORPHING & PAID EGG GUIDE DIRECTOR
local slimeModal, slimeScroll = createBaseModal("📖 EGG & SLIMEOPEDIA (35 SQUISHIES + EGG GUIDE)", Color3.fromRGB(115, 245, 155))

-- Top Control Row inside Slimeopedia (Tiny Mode Toggle, Unmorph, VIP Unlimited Guide)
local slimeControlBar = Instance.new("Frame")
slimeControlBar.Size = UDim2.new(1, -10, 0, 44)
slimeControlBar.BackgroundColor3 = Color3.fromRGB(34, 42, 66)
slimeControlBar.Parent = slimeScroll
addCorner(slimeControlBar, 10)

local tinyToggleBtn = Instance.new("TextButton")
tinyToggleBtn.Size = UDim2.new(0.32, -6, 0, 34)
tinyToggleBtn.Position = UDim2.new(0, 5, 0, 5)
tinyToggleBtn.BackgroundColor3 = Color3.fromRGB(155, 85, 245)
tinyToggleBtn.Font = Enum.Font.FredokaOne
tinyToggleBtn.TextSize = 14
tinyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tinyToggleBtn.Text = "🐭 Toggle Tiny Vent Size"
tinyToggleBtn.Parent = slimeControlBar
addCorner(tinyToggleBtn, 8)
tinyToggleBtn.MouseButton1Click:Connect(function()
	actionRemote:FireServer({ Action = "ToggleTiny" })
end)

local unmorphBtn = Instance.new("TextButton")
unmorphBtn.Size = UDim2.new(0.28, -6, 0, 34)
unmorphBtn.Position = UDim2.new(0.33, 2, 0, 5)
unmorphBtn.BackgroundColor3 = Color3.fromRGB(85, 110, 145)
unmorphBtn.Font = Enum.Font.FredokaOne
unmorphBtn.TextSize = 14
unmorphBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unmorphBtn.Text = "🧍 Normal Avatar"
unmorphBtn.Parent = slimeControlBar
addCorner(unmorphBtn, 8)
unmorphBtn.MouseButton1Click:Connect(function()
	actionRemote:FireServer({ Action = "MorphSlime", SlimeId = 0 })
end)

local vipGuideBtn = Instance.new("TextButton")
vipGuideBtn.Size = UDim2.new(0.38, -6, 0, 34)
vipGuideBtn.Position = UDim2.new(0.62, 2, 0, 5)
vipGuideBtn.BackgroundColor3 = Color3.fromRGB(245, 185, 45)
vipGuideBtn.Font = Enum.Font.FredokaOne
vipGuideBtn.TextSize = 14
vipGuideBtn.TextColor3 = Color3.fromRGB(25, 25, 30)
vipGuideBtn.Text = string.format("🧭 Unlock VIP Unlimited Guide ($%s)", UpgradeData.FormatNumber(UpgradeData.GuidePricing.VIPUnlimitedGuideCost))
vipGuideBtn.Parent = slimeControlBar
addCorner(vipGuideBtn, 8)
vipGuideBtn.MouseButton1Click:Connect(function()
	actionRemote:FireServer({ Action = "BuyUpgrade", Category = "UnlockVIPGuide" })
end)

local slimeRowCards: { [number]: { Row: Frame, StatusLbl: TextLabel, ActionBtn: TextButton } } = {}
for _, sDef in ipairs(SlimeData.Slimes) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -10, 0, 62)
	row.BackgroundColor3 = Color3.fromRGB(30, 36, 56)
	row.Parent = slimeScroll
	addCorner(row, 10)

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.new(0, 44, 0, 44)
	swatch.Position = UDim2.new(0, 9, 0, 9)
	swatch.BackgroundColor3 = sDef.Color
	swatch.Parent = row
	addCorner(swatch, 22)
	addStroke(swatch, sDef.SecondaryColor, 2)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0, 370, 0, 26)
	nameLbl.Position = UDim2.new(0, 62, 0, 6)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextSize = 16
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Text = string.format("#%d [Lvl %d] %s (%s - +$%s/s)", sDef.Id, sDef.Level, sDef.Name, sDef.Rarity, UpgradeData.FormatNumber(sDef.CoinsPerSec))
	nameLbl.Parent = row

	local hintLbl = Instance.new("TextLabel")
	hintLbl.Size = UDim2.new(0, 390, 0, 24)
	hintLbl.Position = UDim2.new(0, 62, 0, 32)
	hintLbl.BackgroundTransparency = 1
	hintLbl.Font = Enum.Font.GothamMedium
	hintLbl.TextSize = 13
	hintLbl.TextXAlignment = Enum.TextXAlignment.Left
	hintLbl.TextColor3 = Color3.fromRGB(190, 210, 240)
	hintLbl.Text = "💡 Hint: " .. sDef.Hint
	hintLbl.Parent = row

	local actBtn = Instance.new("TextButton")
	actBtn.Size = UDim2.new(0, 175, 0, 42)
	actBtn.Position = UDim2.new(1, -185, 0, 10)
	actBtn.BackgroundColor3 = Color3.fromRGB(245, 185, 45)
	actBtn.Font = Enum.Font.FredokaOne
	actBtn.TextSize = 14
	actBtn.TextColor3 = Color3.fromRGB(20, 20, 30)
	actBtn.Text = string.format("🧭 Guide Me ($%d)", UpgradeData.GuidePricing.SingleEggGuideCoinCost)
	actBtn.Parent = row
	addCorner(actBtn, 8)

	actBtn.MouseButton1Click:Connect(function()
		local isPlanted = clientState.PlantedEggs[tostring(sDef.Id)] == true
		if isPlanted then
			actionRemote:FireServer({ Action = "MorphSlime", SlimeId = sDef.Id })
		else
			actionRemote:FireServer({ Action = "BuyUpgrade", Category = "GuideToEgg", Arg = sDef.Id })
			slimeModal.Visible = false
			activeModal = nil
		end
	end)

	slimeRowCards[sDef.Id] = {
		Row = row,
		StatusLbl = nameLbl,
		ActionBtn = actBtn,
	}
end

-- MODAL 2: COLORING TRAILS SHOP
local trailsModal, trailsScroll = createBaseModal("🎨 COLORING TRAILS & FLOOR PAINT SHOP", Color3.fromRGB(255, 115, 225))
local trailButtons: { [string]: TextButton } = {}

for _, trailDef in ipairs(UpgradeData.Trails) do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 66)
	card.BackgroundColor3 = Color3.fromRGB(30, 36, 56)
	card.Parent = trailsScroll
	addCorner(card, 10)
	addStroke(card, trailDef.Color1, 2)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 410, 0, 28)
	title.Position = UDim2.new(0, 14, 0, 6)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = trailDef.Color1
	title.Text = "🎨 " .. trailDef.Name
	title.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0, 410, 0, 24)
	desc.Position = UDim2.new(0, 14, 0, 34)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.GothamBold
	desc.TextSize = 13
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextColor3 = Color3.fromRGB(215, 225, 245)
	desc.Text = trailDef.Description
	desc.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 175, 0, 44)
	buyBtn.Position = UDim2.new(1, -188, 0, 11)
	buyBtn.BackgroundColor3 = trailDef.Color1
	buyBtn.Font = Enum.Font.FredokaOne
	buyBtn.TextSize = 15
	buyBtn.TextColor3 = Color3.fromRGB(20, 22, 32)
	buyBtn.Text = "Buy $" .. UpgradeData.FormatNumber(trailDef.Cost)
	buyBtn.Parent = card
	addCorner(buyBtn, 8)

	buyBtn.MouseButton1Click:Connect(function()
		actionRemote:FireServer({ Action = "BuyUpgrade", Category = "BuyOrEquipTrail", Arg = trailDef.Id })
	end)
	trailButtons[trailDef.Id] = buyBtn
end

-- MODAL 3: PEN & TREADMILL UPGRADES SHOP
local upgModal, upgScroll = createBaseModal("⚡ GROW PEN, MILLION-SPEED TREADMILLS & SPRINGS", Color3.fromRGB(85, 225, 255))

local function makeUpgradeRow(titleStr: string, subStr: string, btnColor: Color3, category: string): (TextLabel, TextButton)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 68)
	card.BackgroundColor3 = Color3.fromRGB(30, 36, 56)
	card.Parent = upgScroll
	addCorner(card, 10)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 420, 0, 54)
	lbl.Position = UDim2.new(0, 14, 0, 7)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 16
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextWrapped = true
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Text = titleStr .. "\n" .. subStr
	lbl.Parent = card

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 175, 0, 46)
	btn.Position = UDim2.new(1, -188, 0, 11)
	btn.BackgroundColor3 = btnColor
	btn.Font = Enum.Font.FredokaOne
	btn.TextSize = 15
	btn.TextColor3 = Color3.fromRGB(20, 22, 32)
	btn.Text = "Upgrade"
	btn.Parent = card
	addCorner(btn, 8)

	btn.MouseButton1Click:Connect(function()
		actionRemote:FireServer({ Action = "BuyUpgrade", Category = category })
	end)
	return lbl, btn
end

local penUpgLbl, penUpgBtn = makeUpgradeRow("🏡 Grow Base Pen (+Nest Slots)", "Expand your Pen to plant Eggs from higher levels!", Color3.fromRGB(255, 165, 55), "ExpandPen")
local tmUpgLbl, tmUpgBtn = makeUpgradeRow("🏃 Upgrade Speed Treadmill", "Gain up to +3.5M Speed Power per stride!", Color3.fromRGB(85, 215, 255), "UpgradeTreadmill")
local gelUpgLbl, gelUpgBtn = makeUpgradeRow("🌈 Upgrade Pen Gel Coating", "Multiply all Squishy Coins/sec up to 12x!", Color3.fromRGB(255, 115, 235), "UpgradeGel")
local jumpUpgLbl, jumpUpgBtn = makeUpgradeRow("🦘 Upgrade Obby Jump Springs", "Jump higher over Obby Lasers & Spires!", Color3.fromRGB(125, 245, 135), "UpgradeJump")

-- MODAL 4: VIP GAMEPASSES & MONETIZATION SHOP
local vipModal, vipScroll = createBaseModal("💎 VIP PASSES, SPEED BUNDLES & EGG RADAR SHOP", Color3.fromRGB(255, 215, 55))

local function makeVipShopCard(titleText: string, descText: string, priceText: string, badgeColor: Color3, onActivate: () -> ())
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 72)
	card.BackgroundColor3 = Color3.fromRGB(32, 36, 58)
	card.Parent = vipScroll
	addCorner(card, 12)
	addStroke(card, badgeColor, 2)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 415, 0, 28)
	title.Position = UDim2.new(0, 14, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = badgeColor
	title.Text = titleText
	title.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0, 415, 0, 26)
	desc.Position = UDim2.new(0, 14, 0, 36)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.GothamBold
	desc.TextSize = 13
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextColor3 = Color3.fromRGB(220, 230, 250)
	desc.Text = descText
	desc.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 185, 0, 46)
	buyBtn.Position = UDim2.new(1, -198, 0, 13)
	buyBtn.BackgroundColor3 = badgeColor
	buyBtn.Font = Enum.Font.FredokaOne
	buyBtn.TextSize = 15
	buyBtn.TextColor3 = Color3.fromRGB(20, 22, 30)
	buyBtn.Text = priceText
	buyBtn.Parent = card
	addCorner(buyBtn, 10)
	buyBtn.MouseButton1Click:Connect(function()
		playUiSound("rbxassetid://12221967", 1.3, 0.5)
		onActivate()
	end)
end

makeVipShopCard(
	"🧭 VIP Unlimited 3D Egg Guide Radar",
	"Unlimited Golden Guide Beams to every hidden Egg across all 5 Biomes!",
	"Unlock ($5,000 / VIP)",
	Color3.fromRGB(255, 215, 55),
	function()
		actionRemote:FireServer({ Action = "BuyUpgrade", Category = "UnlockVIPGuide" })
	end
)

makeVipShopCard(
	"⚡ Hyper-Speed Treadmill Overdrive (3X Speed)",
	"Triple your current Speed Power immediately to outrun Brainrot Chasers!",
	"Activate 3X Speed",
	Color3.fromRGB(85, 235, 255),
	function()
		actionRemote:FireServer({ Action = "FamilyBoost", BoostType = "Speed" })
	end
)

makeVipShopCard(
	"💰 Sovereign Treasure Chest (+$25,000 Coins)",
	"Instant +$25,000 Coins for Pen Expansions, Treadmills & Coloring Trails!",
	"Claim +$25,000",
	Color3.fromRGB(110, 250, 135),
	function()
		actionRemote:FireServer({ Action = "FamilyBoost", BoostType = "Coins" })
	end
)

makeVipShopCard(
	"🔓 Instant Biome Level Completer",
	"Auto-Plants all Eggs in your current Biome & unlocks the next Level Gate!",
	"Unlock Current Level",
	Color3.fromRGB(255, 115, 225),
	function()
		actionRemote:FireServer({ Action = "FamilyBoost", BoostType = "PlantCurrentLevel" })
	end
)

-- Populate Left Dock Buttons
leftDock.Size = UDim2.new(0, 200, 0, 380)
leftDock.Position = UDim2.new(0, 14, 0.5, -190)

makeDockButton("🧭 Guide Next Egg", Color3.fromRGB(245, 185, 40), function()
	actionRemote:FireServer({ Action = "BuyUpgrade", Category = "GuideToEgg", Arg = nil })
end)
makeDockButton("📖 Slimeopedia & Morph", Color3.fromRGB(75, 195, 120), function()
	toggleModal(slimeModal)
end)
makeDockButton("🎨 Coloring Trails", Color3.fromRGB(235, 95, 195), function()
	toggleModal(trailsModal)
end)
makeDockButton("⚡ Grow Pen & Speed", Color3.fromRGB(55, 175, 245), function()
	toggleModal(upgModal)
end)
makeDockButton("💎 VIP & Boost Shop", Color3.fromRGB(245, 145, 35), function()
	toggleModal(vipModal)
end)
makeDockButton("🪨 Co-op Buddy Weight", Color3.fromRGB(165, 110, 245), function()
	actionRemote:FireServer({ Action = "DropDecoyWeight" })
end)
makeDockButton("🧤 Slime Slap Glove", Color3.fromRGB(255, 125, 55), function()
	actionRemote:FireServer({ Action = "EquipSlapTool" })
end)

-- Bottom-Right Family / Creator Quick Boost Bar (So you & your kids can test Million Speed or Coins anytime!)
local familyBar = Instance.new("Frame")
familyBar.Size = UDim2.new(0, 350, 0, 38)
familyBar.Position = UDim2.new(1, -362, 1, -48)
familyBar.BackgroundColor3 = Color3.fromRGB(25, 30, 48)
familyBar.BackgroundTransparency = 0.15
familyBar.Parent = screenGui
addCorner(familyBar, 10)
addStroke(familyBar, Color3.fromRGB(255, 215, 65), 1.5)

local function makeBoostBtn(text: string, posScale: number, boostType: string)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.32, -6, 0, 28)
	b.Position = UDim2.new(posScale, 4, 0, 5)
	b.BackgroundColor3 = Color3.fromRGB(55, 68, 105)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = Color3.fromRGB(255, 235, 115)
	b.Text = text
	b.Parent = familyBar
	addCorner(b, 6)
	b.MouseButton1Click:Connect(function()
		actionRemote:FireServer({ Action = "FamilyBoost", BoostType = boostType })
	end)
end

makeBoostBtn("🎁 +$25K Coins", 0.0, "Coins")
makeBoostBtn("⚡ 3x Speed Boost", 0.33, "Speed")
makeBoostBtn("🔓 Plant Level", 0.66, "PlantCurrentLevel")

-- ============================================================================
-- 5. STATE SYNC & LOCAL WORLD VISUALS (Gates, Ghost Planted Eggs, 3D Guide Beam)
-- ============================================================================
local function spawnSpeedPopup(gainAmount: number)
	local pop = Instance.new("TextLabel")
	pop.Size = UDim2.new(0, 220, 0, 32)
	pop.Position = UDim2.new(0.5, math.random(-140, 60), 0, 74)
	pop.BackgroundTransparency = 1
	pop.Font = Enum.Font.FredokaOne
	pop.TextSize = 22
	pop.TextColor3 = Color3.fromRGB(95, 250, 255)
	pop.TextStrokeTransparency = 0.15
	pop.Text = string.format("⚡ +%s SPEED POWER!", UpgradeData.FormatNumber(gainAmount))
	pop.Parent = screenGui
	task.spawn(function()
		for i = 1, 18 do
			task.wait(0.03)
			pop.Position = pop.Position - UDim2.new(0, 0, 0, 2)
			pop.TextTransparency = i / 18
			pop.TextStrokeTransparency = 0.15 + (i / 18)
		end
		pop:Destroy()
	end)
end

local function refreshLocalWorldAndModals()
	-- Top Bar
	coinsBadge.Text = string.format("💰 $%s (+%s/s)", UpgradeData.FormatNumber(clientState.Coins), UpgradeData.FormatNumber(clientState.IncomePerSec))
	speedBadge.Text = string.format("⚡ %s SPEED", UpgradeData.FormatNumber(clientState.SpeedPower))

	local curLvl = math.min(5, clientState.MaxUnlockedLevel)
	local plantedInCur = 0
	local totalInCur = #(SlimeData.ByLevel[curLvl] or {})
	for _, sDef in ipairs(SlimeData.ByLevel[curLvl] or {}) do
		if clientState.PlantedEggs[tostring(sDef.Id)] then
			plantedInCur += 1
		end
	end
	progressBadge.Text = string.format("🥚 Lvl %d: %d/%d (%d/35)", curLvl, plantedInCur, totalInCur, clientState.PlantedCount)

	-- Carry Banner
	if clientState.CarryingEggId then
		local cDef = SlimeData.ById[clientState.CarryingEggId]
		carryBanner.Visible = true
		carryBanner.Text = string.format(
			"🚨 CARRYING %s EGG! RUN TO YOUR BASE PEN TO PLANT IT! 🚨",
			if cDef then string.upper(cDef.Name) else "SQUISHY"
		)
	else
		carryBanner.Visible = false
	end

	-- Update Slimeopedia Cards
	for id, cardInfo in pairs(slimeRowCards) do
		local isPlanted = clientState.PlantedEggs[tostring(id)] == true
		if isPlanted then
			cardInfo.ActionBtn.BackgroundColor3 = Color3.fromRGB(85, 225, 130)
			cardInfo.ActionBtn.Text = if clientState.CurrentMorphId == id then "✨ Morphed!" else "✨ Morph Squishy"
		else
			cardInfo.ActionBtn.BackgroundColor3 = Color3.fromRGB(245, 185, 45)
			cardInfo.ActionBtn.Text = if clientState.VIPGuideUnlocked
				then "🧭 Guide Me (VIP)"
				else string.format("🧭 Guide Me ($%d)", UpgradeData.GuidePricing.SingleEggGuideCoinCost)
		end
	end
	if clientState.VIPGuideUnlocked then
		vipGuideBtn.Text = "🧭 VIP Unlimited Guide OWNED!"
		vipGuideBtn.BackgroundColor3 = Color3.fromRGB(85, 225, 130)
	end

	-- Update Coloring Trails Modal
	for trailId, btn in pairs(trailButtons) do
		local tDef = UpgradeData.GetTrailById(trailId)
		if clientState.EquippedTrail == trailId then
			btn.Text = "✅ EQUIPPED"
			btn.BackgroundColor3 = Color3.fromRGB(95, 245, 135)
		elseif clientState.OwnedTrails[trailId] then
			btn.Text = "Equip Trail"
			btn.BackgroundColor3 = Color3.fromRGB(85, 185, 255)
		elseif tDef then
			btn.Text = "Buy $" .. UpgradeData.FormatNumber(tDef.Cost)
		end
	end

	-- Update Upgrades Modal
	if clientState.PenTier < #UpgradeData.PenTiers then
		local nextPen = UpgradeData.GetPenTier(clientState.PenTier + 1)
		penUpgLbl.Text = string.format("🏡 Grow Pen -> %s (%d Nests)\n%s", nextPen.Name, nextPen.MaxNests, nextPen.Description)
		penUpgBtn.Text = "$" .. UpgradeData.FormatNumber(nextPen.Cost)
	else
		penUpgLbl.Text = "🏡 Sovereign Palace Pen (MAX 35/35 Nests)"
		penUpgBtn.Text = "MAXED"
	end

	if clientState.TreadmillTier < #UpgradeData.TreadmillTiers then
		local nextTm = UpgradeData.GetTreadmillTier(clientState.TreadmillTier + 1)
		tmUpgLbl.Text = string.format("🏃 %s\n%s", nextTm.Name, nextTm.Description)
		tmUpgBtn.Text = "$" .. UpgradeData.FormatNumber(nextTm.Cost)
	else
		tmUpgLbl.Text = "🏃 God-Speed Infinity Treadmill (MAX)"
		tmUpgBtn.Text = "MAXED"
	end

	if clientState.GelTier < #UpgradeData.GelTiers then
		local nextGel = UpgradeData.GetGelTier(clientState.GelTier + 1)
		gelUpgLbl.Text = string.format("🌈 %s\n%s", nextGel.Name, nextGel.Description)
		gelUpgBtn.Text = "$" .. UpgradeData.FormatNumber(nextGel.Cost)
	else
		gelUpgLbl.Text = "🌈 Cosmic Galaxy Gel (MAX 12x Income)"
		gelUpgBtn.Text = "MAXED"
	end

	if clientState.JumpTier < #UpgradeData.JumpTiers then
		local nextJump = UpgradeData.GetJumpTier(clientState.JumpTier + 1)
		jumpUpgLbl.Text = string.format("🦘 %s\n%s", nextJump.Name, nextJump.Description)
		jumpUpgBtn.Text = "$" .. UpgradeData.FormatNumber(nextJump.Cost)
	else
		jumpUpgLbl.Text = "🦘 Zero-G Sovereign Wings (MAX Jump)"
		jumpUpgBtn.Text = "MAXED"
	end

	-- Local World Egg Transparency (Ghost out Eggs this player has already planted so they know what's left!)
	local worldEggsFolder = Workspace:FindFirstChild("WorldEggs")
	if worldEggsFolder then
		for _, eggModel in ipairs(worldEggsFolder:GetChildren()) do
			local sId = eggModel:GetAttribute("SlimeId")
			if sId then
				local isPlanted = clientState.PlantedEggs[tostring(sId)] == true
				local shell = eggModel:FindFirstChild("EggShell") :: BasePart?
				if shell then
					shell.Transparency = if isPlanted then 0.72 else 0.0
				end
			end
		end
	end

	-- Local Level Gate Unlocking (Turn unlocked gates Green & CanCollide = false for this player!)
	local gatesFolder = Workspace:FindFirstChild("LevelGates")
	if gatesFolder then
		for _, gatePart in ipairs(gatesFolder:GetChildren()) do
			if gatePart:IsA("BasePart") then
				local gateLvl = tonumber(gatePart:GetAttribute("GateLevel")) or 1
				local isUnlocked = (clientState.MaxUnlockedLevel > gateLvl)
				gatePart.CanCollide = not isUnlocked
				gatePart.Color = if isUnlocked then Color3.fromRGB(85, 255, 130) else Color3.fromRGB(255, 65, 85)
				gatePart.Transparency = if isUnlocked then 0.82 else 0.25
			end
		end
	end
end

stateSyncRemote.OnClientEvent:Connect(function(newState: any)
	if type(newState) ~= "table" then
		return
	end
	local prevSpeed = clientState.SpeedPower
	for k, v in pairs(newState) do
		(clientState :: any)[k] = v
	end
	if type(newState.SpeedPower) == "number" and newState.SpeedPower > prevSpeed then
		spawnSpeedPopup(newState.SpeedPower - prevSpeed)
	end
	refreshLocalWorldAndModals()
end)

-- ============================================================================
-- 6. 3D PAID EGG GUIDE BEAM & WORLD FOUNTAIN / EGG ANIMATION LOOP
-- ============================================================================
local guideBeamPart = Instance.new("Part")
guideBeamPart.Name = "ClientGuideOrb"
guideBeamPart.Shape = Enum.PartType.Ball
guideBeamPart.Anchored = true
guideBeamPart.CanCollide = false
guideBeamPart.Material = Enum.Material.Neon
guideBeamPart.Color = Color3.fromRGB(255, 225, 55)
guideBeamPart.Size = Vector3.new(2.2, 2.2, 2.2)
guideBeamPart.Transparency = 1
guideBeamPart.Parent = Workspace

local orbAtt = Instance.new("Attachment")
orbAtt.Parent = guideBeamPart

local guideBeam = Instance.new("Beam")
guideBeam.Color = ColorSequence.new(Color3.fromRGB(255, 230, 65), Color3.fromRGB(95, 255, 165))
guideBeam.Width0 = 1.4
guideBeam.Width1 = 1.8
guideBeam.FaceCamera = true
guideBeam.LightEmission = 1
guideBeam.Enabled = false
guideBeam.Parent = guideBeamPart

RunService.RenderStepped:Connect(function()
	local now = os.clock()

	-- Gently rotate the Golden Squishy Fountain Statue in the Hub Plaza
	local squishyWorld = Workspace:FindFirstChild("SquishyWorld")
	if squishyWorld then
		local statue = squishyWorld:FindFirstChild("GoldenFountainStatue")
		if statue and statue:IsA("Model") and statue.PrimaryPart then
			local bob = math.sin(now * 2.2) * 0.45
			statue:PivotTo(CFrame.new(0, 7.6 + bob, 95) * CFrame.Angles(0, now * 0.85, 0))
		end
	end

	local guideId = clientState.ActiveGuideEggId
	local char = localPlayer.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	local worldEggsFolder = Workspace:FindFirstChild("WorldEggs")

	if guideId and hrp and worldEggsFolder then
		local targetEggModel = worldEggsFolder:FindFirstChild("Egg_" .. tostring(guideId)) :: Model?
		local sDef = SlimeData.ById[guideId]
		if targetEggModel and targetEggModel.PrimaryPart and sDef then
			local pAtt = hrp:FindFirstChild("TrailAtt0") :: Attachment?
			if pAtt then
				local targetPos = targetEggModel.PrimaryPart.Position + Vector3.new(0, 2.5 + math.sin(now * 5) * 0.8, 0)
				guideBeamPart.Position = targetPos
				guideBeamPart.Transparency = 0.1
				guideBeam.Attachment0 = pAtt
				guideBeam.Attachment1 = orbAtt
				guideBeam.Enabled = true

				local dist = math.floor((targetPos - hrp.Position).Magnitude)
				guideBanner.Visible = true
				guideBanner.Text = string.format(
					"🧭 EGG GUIDE -> [%s Egg] (%d studs away | Level %d)",
					sDef.Name,
					dist,
					sDef.Level
				)
				return
			end
		end
	end

	guideBeam.Enabled = false
	guideBeamPart.Transparency = 1
	guideBanner.Visible = false
end)
