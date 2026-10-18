--!strict
--[[
	UIBuilder.luau
	Phase 5: Premium Simulator HUD, Live CanvasGroup Progress Bars, ViewportFrame 3D Previews & Smooth Hover Animations
	  1. Top-Center Live Progress Bars (CanvasGroup + UICorner + UIGradient + UIStroke + math.clamp):
	     - 117 Squishy Collection Progress Bar (0 / 117 — 0% to 100%)
	     - Next Stage Speed Unlock Progress Bar
	  2. Smooth TweenService Button Hover & Click Animations:
	     - Every sidebar, top-bar, bottom-left, and modal button (AnchorPoint = 0.5, 0.5) smoothly scales up (1.08x)
	       and shifts color on MouseEnter, shrinks (0.94x) on click, and restores on MouseLeave.
	  3. RichText Markup & Responsive Constraints (UIAspectRatioConstraint, UITextSizeConstraint) across all HUD panels
	     for crisp scaling on PC, Phone, and Tablet.
	  4. 3D ViewportFrame Rotating Squishy Previews inside the 📘 Squishy Index (0/117) so each card shows a real 3D model
	     of that Squishy that zooms and spins when you hover over it.
]]

local TweenService = game:GetService("TweenService")
local SlimeData = require(script.Parent:WaitForChild("SlimeData"))

local UIBuilder = {}

export type RotatingViewportEntry = {
	Model: Model,
	BaseCFrame: CFrame,
	Speed: number,
}

export type IndexCardEntry = {
	Frame: Frame,
	Status: TextLabel,
	Viewport: ViewportFrame,
	Camera: Camera,
	SquishyModel: Model,
	BasePivot: CFrame,
}

local hoverTweenInfo = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local clickTweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local camZoomTweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

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

local function addTextStroke(ui: GuiObject, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = ui
end

local function addAspectRatio(ui: GuiObject, ratio: number)
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = ratio
	ar.AspectType = Enum.AspectType.FitWithinMaxSize
	ar.DominantAxis = Enum.DominantAxis.Width
	ar.Parent = ui
end

local function addTextSizeConstraint(ui: TextLabel | TextButton, minSize: number, maxSize: number)
	ui.RichText = true
	ui.TextScaled = true
	local tc = Instance.new("UITextSizeConstraint")
	tc.MinTextSize = minSize
	tc.MaxTextSize = maxSize
	tc.Parent = ui
end

local function scaleUDim2(sz: UDim2, factor: number): UDim2
	return UDim2.new(
		sz.X.Scale * factor,
		math.round(sz.X.Offset * factor),
		sz.Y.Scale * factor,
		math.round(sz.Y.Offset * factor)
	)
end

local function bindHoverAndClickTween(btn: GuiButton, baseSize: UDim2, baseColor: Color3)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	local hoverSize = scaleUDim2(baseSize, 1.08)
	local downSize = scaleUDim2(baseSize, 0.94)
	local hoverColor = baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.20)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, hoverTweenInfo, {
			Size = hoverSize,
			BackgroundColor3 = hoverColor,
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, hoverTweenInfo, {
			Size = baseSize,
			BackgroundColor3 = baseColor,
		}):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, clickTweenInfo, {
			Size = downSize,
		}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, hoverTweenInfo, {
			Size = hoverSize,
		}):Play()
	end)
end

-- Builds a 3D Kawaii Squishy or Boss Egg Model inside a ViewportFrame (with eyes, shine, blush, belly & topper)
local function build3DSquishyViewportModel(
	parent: Instance,
	primaryColor: Color3,
	accentColor: Color3,
	isBossEgg: boolean,
	rarity: string,
	shapeStyle: string?
): (Model, CFrame)
	local model = Instance.new("Model")
	model.Name = "Squishy3DPreview"

	local basePivot = CFrame.new(0, -0.05, 0) * CFrame.Angles(0, math.rad(-18), 0)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = primaryColor
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth

	if shapeStyle == "Crown" then
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(2.35, 2.15, 2.25)
	elseif isBossEgg then
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(2.05, 2.55, 2.05)
	else
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(2.40, 2.10, 2.25)
	end
	body.CFrame = basePivot
	body.Parent = model
	model.PrimaryPart = body

	-- Belly Patch / Egg Stripe
	local belly = Instance.new("Part")
	belly.Name = "BellyPatch"
	belly.Anchored = true
	belly.CanCollide = false
	belly.Material = Enum.Material.SmoothPlastic
	belly.Color = accentColor
	belly.Shape = Enum.PartType.Ball
	belly.Size = if isBossEgg then Vector3.new(1.75, 1.35, 1.55) else Vector3.new(1.65, 1.40, 1.45)
	belly.CFrame = basePivot * CFrame.new(0, -0.18, -0.52)
	belly.Parent = model

	-- Kawaii Left & Right Eyes (facing -Z towards the Viewport Camera at +Z or vice versa)
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = if side == -1 then "LeftEye" else "RightEye"
		eye.Anchored = true
		eye.CanCollide = false
		eye.Material = Enum.Material.SmoothPlastic
		eye.Color = Color3.fromRGB(18, 22, 32)
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.36, 0.44, 0.24)
		eye.CFrame = basePivot * CFrame.new(side * 0.48, 0.22, 1.02)
		eye.Parent = model

		local shine = Instance.new("Part")
		shine.Name = "EyeShine"
		shine.Anchored = true
		shine.CanCollide = false
		shine.Material = Enum.Material.Neon
		shine.Color = Color3.fromRGB(255, 255, 255)
		shine.Shape = Enum.PartType.Ball
		shine.Size = Vector3.new(0.14, 0.14, 0.14)
		shine.CFrame = basePivot * CFrame.new(side * 0.42, 0.30, 1.12)
		shine.Parent = model

		local blush = Instance.new("Part")
		blush.Name = "CheekBlush"
		blush.Anchored = true
		blush.CanCollide = false
		blush.Material = Enum.Material.SmoothPlastic
		blush.Color = Color3.fromRGB(255, 125, 175)
		blush.Shape = Enum.PartType.Ball
		blush.Size = Vector3.new(0.34, 0.20, 0.18)
		blush.CFrame = basePivot * CFrame.new(side * 0.68, 0.02, 0.96)
		blush.Parent = model
	end

	-- Topper / Halo / Ears based on Rarity or Boss Egg
	if rarity == "Mythic" or rarity == "Legendary" or shapeStyle == "Crown" then
		local halo = Instance.new("Part")
		halo.Name = "HaloCrown"
		halo.Anchored = true
		halo.CanCollide = false
		halo.Material = Enum.Material.Neon
		halo.Color = Color3.fromRGB(255, 225, 65)
		halo.Shape = Enum.PartType.Cylinder
		halo.Size = Vector3.new(0.26, 1.65, 1.65)
		halo.CFrame = basePivot * CFrame.new(0, 1.28, 0) * CFrame.Angles(0, 0, math.rad(90))
		halo.Parent = model
	else
		for _, side in ipairs({ -1, 1 }) do
			local ear = Instance.new("Part")
			ear.Name = "TopEar"
			ear.Anchored = true
			ear.CanCollide = false
			ear.Material = Enum.Material.SmoothPlastic
			ear.Color = accentColor
			ear.Shape = Enum.PartType.Ball
			ear.Size = Vector3.new(0.58, 0.68, 0.48)
			ear.CFrame = basePivot * CFrame.new(side * 0.62, 1.05, 0)
			ear.Parent = model
		end
	end

	model.Parent = parent
	return model, basePivot
end

function UIBuilder.CreateHUD(parentGui: Instance)
	for _, name in ipairs({ "FindASquishyHUD", "StealMyEggHUD" }) do
		local old = parentGui:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StealMyEggHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = parentGui

	local rotatingViewportModels: { RotatingViewportEntry } = {}
	local activeHoveredCard: IndexCardEntry? = nil

	-- Helper for Featured Header 3D ViewportFrames (Index Header & VIP Shop Header)
	local function createFeaturedViewportPreview(
		parent: Instance,
		size: UDim2,
		pos: UDim2,
		primaryColor: Color3,
		accentColor: Color3,
		shapeStyle: string
	): (ViewportFrame, Model, CFrame)
		local vf = Instance.new("ViewportFrame")
		vf.Name = "PreviewViewport"
		vf.Size = size
		vf.Position = pos
		vf.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
		vf.BackgroundTransparency = 0.08
		vf.Ambient = Color3.fromRGB(215, 222, 242)
		vf.LightColor = Color3.fromRGB(255, 255, 255)
		vf.LightDirection = Vector3.new(-1, -1.2, -1)
		vf.Parent = parent
		addCorner(vf, 12)
		addStroke(vf, accentColor, 2.0)

		local worldModel = Instance.new("WorldModel")
		worldModel.Parent = vf

		local cam = Instance.new("Camera")
		cam.FieldOfView = 46
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.9, 4.5), Vector3.new(0, 0.05, 0))
		cam.Parent = vf
		vf.CurrentCamera = cam

		local model, basePivot = build3DSquishyViewportModel(worldModel, primaryColor, accentColor, false, "Mythic", shapeStyle)
		table.insert(rotatingViewportModels, {
			Model = model,
			BaseCFrame = basePivot,
			Speed = 1.65,
		})
		return vf, model, basePivot
	end

	-- =========================================================================
	-- 1. TOP-CENTER LIVE PROGRESS BARS (CanvasGroup + UICorner + UIGradient + UIStroke + math.clamp)
	-- =========================================================================
	local topContainer = Instance.new("Frame")
	topContainer.Name = "TopHUDContainer"
	topContainer.Size = UDim2.new(0.46, 0, 0.115, 0)
	topContainer.Position = UDim2.new(0.5, 0, 0.01, 0)
	topContainer.AnchorPoint = Vector2.new(0.5, 0)
	topContainer.BackgroundColor3 = Color3.fromRGB(18, 22, 40)
	topContainer.BackgroundTransparency = 0.06
	topContainer.Parent = screenGui
	addCorner(topContainer, 14)
	addStroke(topContainer, Color3.fromRGB(255, 215, 70), 2.5)
	addAspectRatio(topContainer, 5.85)

	local topBannerLabel = Instance.new("TextLabel")
	topBannerLabel.Name = "TopBannerLabel"
	topBannerLabel.Size = UDim2.new(0.74, 0, 0.28, 0)
	topBannerLabel.Position = UDim2.fromScale(0.02, 0.04)
	topBannerLabel.BackgroundTransparency = 1
	topBannerLabel.Font = Enum.Font.FredokaOne
	topBannerLabel.TextXAlignment = Enum.TextXAlignment.Left
	topBannerLabel.TextColor3 = Color3.fromRGB(255, 245, 190)
	topBannerLabel.Text = "✨ <b>FIND MY SQUISHY!</b>  |  Plot #1  |  ⚡ <font color='#65FF8F'>$0/sec</font>"
	topBannerLabel.Parent = topContainer
	addTextSizeConstraint(topBannerLabel, 11, 19)
	addTextStroke(topBannerLabel, Color3.fromRGB(10, 12, 22), 1.8)

	-- Top-Bar Quick Action Buttons (AnchorPoint = 0.5, 0.5 + Smooth Hover & Click Tween!)
	local topIndexBtnSize = UDim2.fromScale(0.11, 0.24)
	local topIndexBtn = Instance.new("TextButton")
	topIndexBtn.Name = "TopIndexBtn"
	topIndexBtn.Size = topIndexBtnSize
	topIndexBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	topIndexBtn.Position = UDim2.fromScale(0.81, 0.18)
	topIndexBtn.BackgroundColor3 = Color3.fromRGB(55, 185, 255)
	topIndexBtn.AutoButtonColor = false
	topIndexBtn.Font = Enum.Font.FredokaOne
	topIndexBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	topIndexBtn.Text = "📘 <b>117</b>"
	topIndexBtn.Parent = topContainer
	addCorner(topIndexBtn, 8)
	addStroke(topIndexBtn, Color3.fromRGB(255, 255, 255), 1.6)
	addTextSizeConstraint(topIndexBtn, 10, 15)
	bindHoverAndClickTween(topIndexBtn, topIndexBtnSize, Color3.fromRGB(55, 185, 255))

	local topSpeedBtnSize = UDim2.fromScale(0.11, 0.24)
	local topSpeedBtn = Instance.new("TextButton")
	topSpeedBtn.Name = "TopSpeedBtn"
	topSpeedBtn.Size = topSpeedBtnSize
	topSpeedBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	topSpeedBtn.Position = UDim2.fromScale(0.93, 0.18)
	topSpeedBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 45)
	topSpeedBtn.AutoButtonColor = false
	topSpeedBtn.Font = Enum.Font.FredokaOne
	topSpeedBtn.TextColor3 = Color3.fromRGB(18, 22, 34)
	topSpeedBtn.Text = "⚡ <b>+SPD</b>"
	topSpeedBtn.Parent = topContainer
	addCorner(topSpeedBtn, 8)
	addStroke(topSpeedBtn, Color3.fromRGB(255, 255, 255), 1.6)
	addTextSizeConstraint(topSpeedBtn, 10, 15)
	bindHoverAndClickTween(topSpeedBtn, topSpeedBtnSize, Color3.fromRGB(255, 180, 45))

	-- Progress Bar #1: 117 Squishy Collection Progress Bar (0 / 117 — 0% to 100%)
	local squishyBarGroup = Instance.new("CanvasGroup")
	squishyBarGroup.Name = "SquishyMasteryProgressBar"
	squishyBarGroup.Size = UDim2.fromScale(0.96, 0.28)
	squishyBarGroup.Position = UDim2.fromScale(0.02, 0.36)
	squishyBarGroup.BackgroundColor3 = Color3.fromRGB(10, 14, 26)
	squishyBarGroup.ClipsDescendants = true
	squishyBarGroup.Parent = topContainer
	addCorner(squishyBarGroup, 10)
	addStroke(squishyBarGroup, Color3.fromRGB(85, 215, 255), 2.0)

	local squishyBarFill = Instance.new("Frame")
	squishyBarFill.Name = "Fill"
	squishyBarFill.Size = UDim2.fromScale(math.clamp(0 / 117, 0, 1), 1)
	squishyBarFill.BackgroundColor3 = Color3.fromRGB(85, 235, 145)
	squishyBarFill.BorderSizePixel = 0
	squishyBarFill.Parent = squishyBarGroup
	addCorner(squishyBarFill, 10)

	local squishyGrad = Instance.new("UIGradient")
	squishyGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(55, 215, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(95, 250, 145)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 230, 75)),
	})
	squishyGrad.Parent = squishyBarFill

	local squishyBarText = Instance.new("TextLabel")
	squishyBarText.Name = "ProgressLabel"
	squishyBarText.Size = UDim2.fromScale(0.96, 0.88)
	squishyBarText.Position = UDim2.fromScale(0.02, 0.06)
	squishyBarText.BackgroundTransparency = 1
	squishyBarText.Font = Enum.Font.FredokaOne
	squishyBarText.TextColor3 = Color3.fromRGB(255, 255, 255)
	squishyBarText.Text = "📘 <b>117 SQUISHY COLLECTION:</b> <font color='#75FF9E'>0 / 117 (0%)</font>"
	squishyBarText.Parent = squishyBarGroup
	addTextSizeConstraint(squishyBarText, 10, 16)
	addTextStroke(squishyBarText, Color3.fromRGB(10, 14, 24), 2.0)

	-- Progress Bar #2: Next Stage Speed Unlock Progress Bar
	local speedBarGroup = Instance.new("CanvasGroup")
	speedBarGroup.Name = "SpeedGoalProgressBar"
	speedBarGroup.Size = UDim2.fromScale(0.96, 0.26)
	speedBarGroup.Position = UDim2.fromScale(0.02, 0.68)
	speedBarGroup.BackgroundColor3 = Color3.fromRGB(10, 14, 26)
	speedBarGroup.ClipsDescendants = true
	speedBarGroup.Parent = topContainer
	addCorner(speedBarGroup, 10)
	addStroke(speedBarGroup, Color3.fromRGB(255, 175, 65), 2.0)

	local speedBarFill = Instance.new("Frame")
	speedBarFill.Name = "Fill"
	speedBarFill.Size = UDim2.fromScale(math.clamp(18 / 32, 0, 1), 1)
	speedBarFill.BackgroundColor3 = Color3.fromRGB(255, 185, 55)
	speedBarFill.BorderSizePixel = 0
	speedBarFill.Parent = speedBarGroup
	addCorner(speedBarFill, 10)

	local speedGrad = Instance.new("UIGradient")
	speedGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 115, 65)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 185, 55)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 240, 85)),
	})
	speedGrad.Parent = speedBarFill

	local speedBarText = Instance.new("TextLabel")
	speedBarText.Name = "ProgressLabel"
	speedBarText.Size = UDim2.fromScale(0.96, 0.88)
	speedBarText.Position = UDim2.fromScale(0.02, 0.06)
	speedBarText.BackgroundTransparency = 1
	speedBarText.Font = Enum.Font.FredokaOne
	speedBarText.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedBarText.Text = "⚡ <b>NEXT STAGE SPEED UNLOCK (Stage 2: Candy Kingdom):</b> <font color='#FFE865'>18 / 32 SPEED (56%)</font>"
	speedBarText.Parent = speedBarGroup
	addTextSizeConstraint(speedBarText, 9, 15)
	addTextStroke(speedBarText, Color3.fromRGB(10, 14, 24), 2.0)

	-- 1B. LIVE 6-STEP OBJECTIVE & GUIDING ARROW TRACKER BANNER + HOW-TO-PLAY BUTTON
	local objectiveBanner = Instance.new("Frame")
	objectiveBanner.Name = "ObjectiveTrackerBanner"
	objectiveBanner.Size = UDim2.fromScale(0.46, 0.042)
	objectiveBanner.Position = UDim2.fromScale(0.5, 0.130)
	objectiveBanner.AnchorPoint = Vector2.new(0.5, 0)
	objectiveBanner.BackgroundColor3 = Color3.fromRGB(16, 24, 46)
	objectiveBanner.BackgroundTransparency = 0.08
	objectiveBanner.Parent = screenGui
	addCorner(objectiveBanner, 10)
	addStroke(objectiveBanner, Color3.fromRGB(85, 235, 255), 2.0)

	local objectiveText = Instance.new("TextLabel")
	objectiveText.Name = "ObjectiveText"
	objectiveText.Size = UDim2.fromScale(0.83, 0.90)
	objectiveText.Position = UDim2.fromScale(0.02, 0.05)
	objectiveText.BackgroundTransparency = 1
	objectiveText.Font = Enum.Font.FredokaOne
	objectiveText.TextXAlignment = Enum.TextXAlignment.Left
	objectiveText.TextColor3 = Color3.fromRGB(125, 255, 195)
	objectiveText.Text = "🧭 <b>FOLLOW 3D ARROW:</b> [Step 1] ⚡ Run on Treadmill to Train Speed!"
	objectiveText.Parent = objectiveBanner
	addTextSizeConstraint(objectiveText, 10, 16)
	addTextStroke(objectiveText, Color3.fromRGB(10, 14, 24), 1.8)

	local guideBtnSize = UDim2.fromScale(0.13, 0.78)
	local guideToggleBtn = Instance.new("TextButton")
	guideToggleBtn.Name = "GuideToggleBtn"
	guideToggleBtn.Size = guideBtnSize
	guideToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	guideToggleBtn.Position = UDim2.fromScale(0.92, 0.5)
	guideToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 205, 55)
	guideToggleBtn.AutoButtonColor = false
	guideToggleBtn.Font = Enum.Font.FredokaOne
	guideToggleBtn.TextColor3 = Color3.fromRGB(18, 22, 34)
	guideToggleBtn.Text = "❓ <b>GUIDE</b>"
	guideToggleBtn.Parent = objectiveBanner
	addCorner(guideToggleBtn, 8)
	addStroke(guideToggleBtn, Color3.fromRGB(255, 255, 255), 1.5)
	addTextSizeConstraint(guideToggleBtn, 9, 14)
	bindHoverAndClickTween(guideToggleBtn, guideBtnSize, Color3.fromRGB(255, 205, 55))

	-- 1C. SQUISH FEVER COMBO MULTIPLIER BAR (x1.5 -> x5.0 CASH!)
	local comboFrame = Instance.new("Frame")
	comboFrame.Name = "SquishFeverComboFrame"
	comboFrame.Size = UDim2.fromScale(0.32, 0.044)
	comboFrame.Position = UDim2.fromScale(0.5, 0.228)
	comboFrame.AnchorPoint = Vector2.new(0.5, 0)
	comboFrame.BackgroundColor3 = Color3.fromRGB(36, 16, 48)
	comboFrame.BackgroundTransparency = 0.06
	comboFrame.Visible = false
	comboFrame.Parent = screenGui
	addCorner(comboFrame, 12)
	addStroke(comboFrame, Color3.fromRGB(255, 115, 235), 2.5)

	local comboLabel = Instance.new("TextLabel")
	comboLabel.Name = "ComboLabel"
	comboLabel.Size = UDim2.fromScale(0.94, 0.62)
	comboLabel.Position = UDim2.fromScale(0.03, 0.04)
	comboLabel.BackgroundTransparency = 1
	comboLabel.Font = Enum.Font.FredokaOne
	comboLabel.TextColor3 = Color3.fromRGB(255, 235, 85)
	comboLabel.Text = "🔥 <b>SQUISH FEVER COMBO: x1.5 CASH! (2x CHAIN)</b> 🔥"
	comboLabel.Parent = comboFrame
	addTextSizeConstraint(comboLabel, 10, 17)
	addTextStroke(comboLabel, Color3.fromRGB(18, 8, 26), 2.0)

	local comboBarBg = Instance.new("Frame")
	comboBarBg.Name = "ComboBarBg"
	comboBarBg.Size = UDim2.fromScale(0.92, 0.22)
	comboBarBg.Position = UDim2.fromScale(0.04, 0.70)
	comboBarBg.BackgroundColor3 = Color3.fromRGB(14, 8, 22)
	comboBarBg.BorderSizePixel = 0
	comboBarBg.Parent = comboFrame
	addCorner(comboBarBg, 6)

	local comboFill = Instance.new("Frame")
	comboFill.Name = "ComboFill"
	comboFill.Size = UDim2.fromScale(1, 1)
	comboFill.BackgroundColor3 = Color3.fromRGB(255, 195, 55)
	comboFill.BorderSizePixel = 0
	comboFill.Parent = comboBarBg
	addCorner(comboFill, 6)

	local comboGrad = Instance.new("UIGradient")
	comboGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 75, 165)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 195, 55)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(85, 255, 165)),
	})
	comboGrad.Parent = comboFill

	-- 1D. 6-STEP HOW-TO-PLAY POPUP CARD
	local howToPlayModal = Instance.new("Frame")
	howToPlayModal.Name = "HowToPlayModal"
	howToPlayModal.Size = UDim2.fromScale(0.42, 0.44)
	howToPlayModal.Position = UDim2.fromScale(0.5, 0.50)
	howToPlayModal.AnchorPoint = Vector2.new(0.5, 0.5)
	howToPlayModal.BackgroundColor3 = Color3.fromRGB(18, 24, 44)
	howToPlayModal.BackgroundTransparency = 0.04
	howToPlayModal.Visible = false
	howToPlayModal.Parent = screenGui
	addCorner(howToPlayModal, 16)
	addStroke(howToPlayModal, Color3.fromRGB(85, 235, 255), 3.0)

	local htpTitle = Instance.new("TextLabel")
	htpTitle.Size = UDim2.new(1, -60, 0, 36)
	htpTitle.Position = UDim2.fromOffset(18, 10)
	htpTitle.BackgroundTransparency = 1
	htpTitle.Font = Enum.Font.FredokaOne
	htpTitle.TextXAlignment = Enum.TextXAlignment.Left
	htpTitle.TextColor3 = Color3.fromRGB(255, 235, 85)
	htpTitle.Text = "🧭 <b>HOW TO PLAY — 6-STEP STAGE MASTERY LOOP</b>"
	htpTitle.Parent = howToPlayModal
	addTextSizeConstraint(htpTitle, 13, 22)

	local htpClose = Instance.new("TextButton")
	htpClose.Name = "CloseBtn"
	htpClose.Size = UDim2.fromOffset(34, 34)
	htpClose.AnchorPoint = Vector2.new(0.5, 0.5)
	htpClose.Position = UDim2.new(1, -26, 0, 26)
	htpClose.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
	htpClose.Font = Enum.Font.FredokaOne
	htpClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	htpClose.Text = "<b>X</b>"
	htpClose.Parent = howToPlayModal
	addCorner(htpClose, 8)

	local htpBody = Instance.new("TextLabel")
	htpBody.Size = UDim2.new(1, -36, 1, -62)
	htpBody.Position = UDim2.fromOffset(18, 50)
	htpBody.BackgroundTransparency = 1
	htpBody.Font = Enum.Font.GothamBold
	htpBody.TextXAlignment = Enum.TextXAlignment.Left
	htpBody.TextYAlignment = Enum.TextYAlignment.Top
	htpBody.TextWrapped = true
	htpBody.TextColor3 = Color3.fromRGB(235, 245, 255)
	htpBody.Text = table.concat({
		"⚡ <b>STEP 1 — TRAIN SPEED ON TREADMILL:</b> Run on your Plot or Stage Treadmill (x1 -> x50M Speed!). Use the <b>25% / 50% / 75% / 100%</b> Speed Bar to control high speed!",
		"🧸 <b>STEP 2 — WALK OVER SQUISHIES:</b> Walk right over Collectible Squishies in Houses, Mazes, Castle Walls & Obbies (auto-pickup, zero button holding! Chain pickups for <b>x5.0 SQUISH FEVER CASH!</b>).",
		"🥚 <b>STEP 3 — STEAL BOSS EGGS:</b> Sneak into Sector 3's Sleeping Boss Arena & walk over Boss Eggs to steal them!",
		"🏡 <b>STEP 4 — HATCH IN FENCED PEN:</b> Walk into your Plot's <b>Fenced Hatchery Pen</b> — Eggs auto-drop, countdown (00:05), and hatch into live roaming Squishies!",
		"⬆️ <b>STEP 5 — GROW & CLAIM $/SEC CASH:</b> Upgrade your roaming Squishies in the pen so they physically grow larger, wear Crowns, and multiply $/sec Cash!",
		"🔓 <b>STEP 6 — 100% STAGE UNLOCK:</b> Complete <b>100% of all Stage Squishies + Boss Eggs + Speed Goal</b> to unlock the next Stage Gate (Stages 1 -> 8)!",
	}, "\n\n")
	htpBody.Parent = howToPlayModal
	addTextSizeConstraint(htpBody, 10, 15)

	-- Alert Toast Banner
	local alertToast = Instance.new("TextLabel")
	alertToast.Name = "AlertToast"
	alertToast.Size = UDim2.fromScale(0.44, 0.044)
	alertToast.Position = UDim2.fromScale(0.5, 0.178)
	alertToast.AnchorPoint = Vector2.new(0.5, 0)
	alertToast.BackgroundColor3 = Color3.fromRGB(215, 45, 65)
	alertToast.Font = Enum.Font.FredokaOne
	alertToast.TextColor3 = Color3.fromRGB(255, 255, 255)
	alertToast.Text = ""
	alertToast.Visible = false
	alertToast.Parent = screenGui
	addCorner(alertToast, 12)
	addStroke(alertToast, Color3.fromRGB(255, 235, 95), 2.5)
	addTextSizeConstraint(alertToast, 11, 20)

	-- =========================================================================
	-- 2. LEFT 2x3 SIDEBAR MENU GRID & RIGHT DOCK (Smooth Hover 1.08x & Click 0.94x)
	-- =========================================================================
	local leftGrid = Instance.new("Frame")
	leftGrid.Name = "LeftMenuGrid"
	leftGrid.Size = UDim2.fromScale(0.115, 0.28)
	leftGrid.Position = UDim2.new(0.012, 0, 0.5, 0)
	leftGrid.AnchorPoint = Vector2.new(0, 0.5)
	leftGrid.BackgroundTransparency = 1
	leftGrid.Parent = screenGui
	addAspectRatio(leftGrid, 0.67)

	local function makeSquareBtn(
		parent: Instance,
		name: string,
		iconText: string,
		labelText: string,
		bgColor: Color3,
		centerPos: UDim2,
		baseSize: UDim2
	): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = baseSize
		btn.AnchorPoint = Vector2.new(0.5, 0.5)
		btn.Position = centerPos
		btn.BackgroundColor3 = bgColor
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.Parent = parent
		addCorner(btn, 14)
		addStroke(btn, Color3.fromRGB(255, 255, 255), 2.5)
		addAspectRatio(btn, 1.0)

		local btnGrad = Instance.new("UIGradient")
		btnGrad.Rotation = 90
		btnGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(215, 220, 235)),
		})
		btnGrad.Parent = btn

		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.fromScale(0.9, 0.56)
		icon.Position = UDim2.fromScale(0.05, 0.06)
		icon.BackgroundTransparency = 1
		icon.Font = Enum.Font.FredokaOne
		icon.TextColor3 = Color3.fromRGB(255, 255, 255)
		icon.Text = iconText
		icon.Parent = btn
		addTextSizeConstraint(icon, 14, 30)

		local cap = Instance.new("TextLabel")
		cap.Name = "Caption"
		cap.Size = UDim2.fromScale(0.92, 0.32)
		cap.Position = UDim2.fromScale(0.04, 0.63)
		cap.BackgroundTransparency = 1
		cap.Font = Enum.Font.FredokaOne
		cap.TextColor3 = Color3.fromRGB(255, 255, 255)
		cap.Text = "<b>" .. labelText .. "</b>"
		cap.Parent = btn
		addTextSizeConstraint(cap, 9, 15)
		addTextStroke(cap, Color3.fromRGB(15, 15, 25), 2.0)

		bindHoverAndClickTween(btn, baseSize, bgColor)
		return btn
	end

	local leftBtnSize = UDim2.fromScale(0.45, 0.295)
	local shopBtn = makeSquareBtn(leftGrid, "ShopBtn", "🛒", "Shop", Color3.fromRGB(255, 175, 45), UDim2.fromScale(0.25, 0.16), leftBtnSize)
	local indexBtn = makeSquareBtn(leftGrid, "IndexBtn", "📘", "Index", Color3.fromRGB(55, 185, 255), UDim2.fromScale(0.75, 0.16), leftBtnSize)
	local dailyBtn = makeSquareBtn(leftGrid, "DailyBtn", "🎁", "Daily", Color3.fromRGB(245, 95, 185), UDim2.fromScale(0.25, 0.50), leftBtnSize)
	local sloMoBtn = makeSquareBtn(leftGrid, "SloMoBtn", "🐢", "SloMo", Color3.fromRGB(95, 215, 125), UDim2.fromScale(0.75, 0.50), leftBtnSize)
	local wheelBtn = makeSquareBtn(leftGrid, "WheelBtn", "🎡", "Spin", Color3.fromRGB(195, 95, 255), UDim2.fromScale(0.25, 0.84), leftBtnSize)
	local vipBtn = makeSquareBtn(leftGrid, "VIPBtn", "👑", "VIP", Color3.fromRGB(255, 215, 55), UDim2.fromScale(0.75, 0.84), leftBtnSize)

	-- Right Vertical Dock (Eggs, +Speed, Rebirth)
	local rightDock = Instance.new("Frame")
	rightDock.Name = "RightDock"
	rightDock.Size = UDim2.fromScale(0.058, 0.28)
	rightDock.Position = UDim2.new(0.988, 0, 0.5, 0)
	rightDock.AnchorPoint = Vector2.new(1, 0.5)
	rightDock.BackgroundTransparency = 1
	rightDock.Parent = screenGui
	addAspectRatio(rightDock, 0.34)

	local rightBtnSize = UDim2.fromScale(0.90, 0.295)
	local eggsDockBtn = makeSquareBtn(rightDock, "EggsBtn", "🥚", "Eggs", Color3.fromRGB(175, 95, 255), UDim2.fromScale(0.5, 0.16), rightBtnSize)
	local speedDockBtn = makeSquareBtn(rightDock, "SpeedBtn", "🦖", "+Speed", Color3.fromRGB(55, 205, 255), UDim2.fromScale(0.5, 0.50), rightBtnSize)
	local rebirthDockBtn = makeSquareBtn(rightDock, "RebirthDockBtn", "✨", "Rebirth", Color3.fromRGB(255, 125, 75), UDim2.fromScale(0.5, 0.84), rightBtnSize)

	-- =========================================================================
	-- 3. BOTTOM-LEFT STACKED SPEED & CASH COUNTERS (with RichText & UITextSizeConstraint)
	-- =========================================================================
	local bottomLeftFrame = Instance.new("Frame")
	bottomLeftFrame.Name = "BottomLeftStats"
	bottomLeftFrame.Size = UDim2.fromScale(0.165, 0.105)
	bottomLeftFrame.Position = UDim2.new(0.012, 0, 0.982, 0)
	bottomLeftFrame.AnchorPoint = Vector2.new(0, 1)
	bottomLeftFrame.BackgroundTransparency = 1
	bottomLeftFrame.Parent = screenGui
	addAspectRatio(bottomLeftFrame, 2.55)

	local speedCounterLbl = Instance.new("TextLabel")
	speedCounterLbl.Name = "SpeedCounter"
	speedCounterLbl.Size = UDim2.fromScale(0.74, 0.45)
	speedCounterLbl.Position = UDim2.fromScale(0, 0)
	speedCounterLbl.BackgroundTransparency = 1
	speedCounterLbl.Font = Enum.Font.FredokaOne
	speedCounterLbl.TextXAlignment = Enum.TextXAlignment.Left
	speedCounterLbl.TextColor3 = Color3.fromRGB(65, 220, 255)
	speedCounterLbl.Text = "⚡ <b>18</b>"
	speedCounterLbl.Parent = bottomLeftFrame
	addTextSizeConstraint(speedCounterLbl, 14, 34)
	addTextStroke(speedCounterLbl, Color3.fromRGB(12, 18, 30), 3.0)

	local plusBtnSize = UDim2.fromScale(0.16, 0.38)
	local speedPlusBtn = Instance.new("TextButton")
	speedPlusBtn.Name = "SpeedPlusBtn"
	speedPlusBtn.Size = plusBtnSize
	speedPlusBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	speedPlusBtn.Position = UDim2.fromScale(0.86, 0.23)
	speedPlusBtn.BackgroundColor3 = Color3.fromRGB(65, 225, 85)
	speedPlusBtn.AutoButtonColor = false
	speedPlusBtn.Font = Enum.Font.FredokaOne
	speedPlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedPlusBtn.Text = "<b>+</b>"
	speedPlusBtn.Parent = bottomLeftFrame
	addCorner(speedPlusBtn, 8)
	addStroke(speedPlusBtn, Color3.fromRGB(15, 40, 18), 2.5)
	addAspectRatio(speedPlusBtn, 1.0)
	addTextSizeConstraint(speedPlusBtn, 12, 24)
	bindHoverAndClickTween(speedPlusBtn, plusBtnSize, Color3.fromRGB(65, 225, 85))

	local cashCounterLbl = Instance.new("TextLabel")
	cashCounterLbl.Name = "CashCounter"
	cashCounterLbl.Size = UDim2.fromScale(0.74, 0.45)
	cashCounterLbl.Position = UDim2.fromScale(0, 0.52)
	cashCounterLbl.BackgroundTransparency = 1
	cashCounterLbl.Font = Enum.Font.FredokaOne
	cashCounterLbl.TextXAlignment = Enum.TextXAlignment.Left
	cashCounterLbl.TextColor3 = Color3.fromRGB(75, 245, 95)
	cashCounterLbl.Text = "💰 <b>$100</b>"
	cashCounterLbl.Parent = bottomLeftFrame
	addTextSizeConstraint(cashCounterLbl, 14, 34)
	addTextStroke(cashCounterLbl, Color3.fromRGB(12, 28, 14), 3.0)

	local cashPlusBtn = Instance.new("TextButton")
	cashPlusBtn.Name = "CashPlusBtn"
	cashPlusBtn.Size = plusBtnSize
	cashPlusBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	cashPlusBtn.Position = UDim2.fromScale(0.86, 0.75)
	cashPlusBtn.BackgroundColor3 = Color3.fromRGB(65, 225, 85)
	cashPlusBtn.AutoButtonColor = false
	cashPlusBtn.Font = Enum.Font.FredokaOne
	cashPlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cashPlusBtn.Text = "<b>+</b>"
	cashPlusBtn.Parent = bottomLeftFrame
	addCorner(cashPlusBtn, 8)
	addStroke(cashPlusBtn, Color3.fromRGB(15, 40, 18), 2.5)
	addAspectRatio(cashPlusBtn, 1.0)
	addTextSizeConstraint(cashPlusBtn, 12, 24)
	bindHoverAndClickTween(cashPlusBtn, plusBtnSize, Color3.fromRGB(65, 225, 85))

	-- =========================================================================
	-- 3B. HUD WALKSPEED CONTROL SELECTOR (25% / 50% / 75% / 100% — Controllable Speed at 250M+!)
	-- =========================================================================
	local speedThrottleBar = Instance.new("Frame")
	speedThrottleBar.Name = "SpeedThrottleBar"
	speedThrottleBar.Size = UDim2.fromScale(0.165, 0.042)
	speedThrottleBar.Position = UDim2.new(0.012, 0, 0.868, 0)
	speedThrottleBar.AnchorPoint = Vector2.new(0, 1)
	speedThrottleBar.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
	speedThrottleBar.BackgroundTransparency = 0.08
	speedThrottleBar.Parent = screenGui
	addCorner(speedThrottleBar, 10)
	addStroke(speedThrottleBar, Color3.fromRGB(75, 215, 255), 1.8)
	addAspectRatio(speedThrottleBar, 6.2)

	local speedThrottleButtons: { [number]: TextButton } = {}
	local throttleRatios = { 0.25, 0.50, 0.75, 1.00 }
	for idx, ratio in ipairs(throttleRatios) do
		local pct = math.round(ratio * 100)
		local btn = Instance.new("TextButton")
		btn.Name = string.format("Throttle_%d", pct)
		local btnSize = UDim2.fromScale(0.225, 0.78)
		btn.Size = btnSize
		btn.AnchorPoint = Vector2.new(0.5, 0.5)
		btn.Position = UDim2.fromScale(0.13 + (idx - 1) * 0.246, 0.5)
		local isDefault = (pct == 100)
		local bgCol = if isDefault then Color3.fromRGB(55, 215, 115) else Color3.fromRGB(34, 42, 68)
		btn.BackgroundColor3 = bgCol
		btn.AutoButtonColor = false
		btn.Font = Enum.Font.FredokaOne
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = string.format("<b>%d%%</b>", pct)
		btn.Parent = speedThrottleBar
		addCorner(btn, 7)
		addStroke(btn, Color3.fromRGB(255, 255, 255), 1.2)
		addTextSizeConstraint(btn, 9, 14)
		speedThrottleButtons[pct] = btn
	end

	-- =========================================================================
	-- 4. MODAL #1: 📘 117 SQUISHY & EGG INDEX MODAL WITH 3D VIEWPORTFRAME ROTATING PREVIEWS ON EVERY CARD!
	-- =========================================================================
	local indexModal = Instance.new("Frame")
	indexModal.Name = "EggIndexModal"
	indexModal.Size = UDim2.fromScale(0.56, 0.64)
	indexModal.Position = UDim2.fromScale(0.5, 0.52)
	indexModal.AnchorPoint = Vector2.new(0.5, 0.5)
	indexModal.BackgroundColor3 = Color3.fromRGB(20, 24, 42)
	indexModal.Visible = false
	indexModal.Parent = screenGui
	addCorner(indexModal, 16)
	addStroke(indexModal, Color3.fromRGB(85, 205, 255), 3.0)
	addAspectRatio(indexModal, 1.52)

	-- Featured 3D Rotating Inspector in the Index Header
	local indexFeaturedViewport, indexFeaturedModel = createFeaturedViewportPreview(
		indexModal,
		UDim2.fromOffset(52, 52),
		UDim2.fromOffset(14, 8),
		Color3.fromRGB(115, 225, 255),
		Color3.fromRGB(255, 230, 85),
		"Squishy"
	)

	local indexTitle = Instance.new("TextLabel")
	indexTitle.Name = "IndexTitle"
	indexTitle.Size = UDim2.new(1, -135, 0, 28)
	indexTitle.Position = UDim2.fromOffset(76, 6)
	indexTitle.BackgroundTransparency = 1
	indexTitle.Font = Enum.Font.FredokaOne
	indexTitle.TextXAlignment = Enum.TextXAlignment.Left
	indexTitle.TextColor3 = Color3.fromRGB(255, 235, 95)
	indexTitle.Text = "📘 <b>3D SQUISHY & EGG INDEX (0 / 117)</b>"
	indexTitle.Parent = indexModal
	addTextSizeConstraint(indexTitle, 13, 22)

	local indexHintLabel = Instance.new("TextLabel")
	indexHintLabel.Name = "IndexHintBox"
	indexHintLabel.Size = UDim2.new(1, -135, 0, 22)
	indexHintLabel.Position = UDim2.fromOffset(76, 35)
	indexHintLabel.BackgroundTransparency = 1
	indexHintLabel.Font = Enum.Font.GothamBold
	indexHintLabel.TextXAlignment = Enum.TextXAlignment.Left
	indexHintLabel.TextColor3 = Color3.fromRGB(165, 235, 255)
	indexHintLabel.Text = "💡 <b>Hover any 3D Squishy card</b> to zoom & spin its 3D model and reveal its secret biome location!"
	indexHintLabel.Parent = indexModal
	addTextSizeConstraint(indexHintLabel, 10, 14)

	local closeBtnSize = UDim2.fromOffset(38, 38)
	local indexClose = Instance.new("TextButton")
	indexClose.Name = "CloseBtn"
	indexClose.Size = closeBtnSize
	indexClose.AnchorPoint = Vector2.new(0.5, 0.5)
	indexClose.Position = UDim2.new(1, -29, 0, 31)
	indexClose.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
	indexClose.AutoButtonColor = false
	indexClose.Font = Enum.Font.FredokaOne
	indexClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	indexClose.Text = "<b>X</b>"
	indexClose.Parent = indexModal
	addCorner(indexClose, 10)
	addTextSizeConstraint(indexClose, 14, 20)
	bindHoverAndClickTween(indexClose, closeBtnSize, Color3.fromRGB(235, 65, 75))

	local indexScroll = Instance.new("ScrollingFrame")
	indexScroll.Name = "IndexScroll"
	indexScroll.Size = UDim2.new(1, -28, 1, -76)
	indexScroll.Position = UDim2.fromOffset(14, 64)
	indexScroll.BackgroundTransparency = 1
	indexScroll.ScrollBarThickness = 8
	indexScroll.Parent = indexModal

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.fromOffset(212, 92)
	gridLayout.CellPadding = UDim2.fromOffset(10, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = indexScroll

	local indexCards: { [string]: IndexCardEntry } = {}
	local cardViewportBaseSize = UDim2.fromOffset(72, 72)
	local cardViewportHoverSize = UDim2.fromOffset(80, 80)

	for idx, slime in ipairs(SlimeData.Slimes) do
		local anySlime = slime :: any
		local card = Instance.new("Frame")
		card.Name = "SquishyCard_" .. tostring(idx)
		card.LayoutOrder = idx
		card.BackgroundColor3 = Color3.fromRGB(32, 38, 64)
		card.Parent = indexScroll
		addCorner(card, 12)

		local pColor = anySlime.BodyColor or slime.Color or Color3.fromRGB(115, 225, 255)
		local aColor = anySlime.AccentColor or slime.SecondaryColor or Color3.fromRGB(255, 230, 85)
		local rarity = tostring(anySlime.Rarity or "Common")
		local isBossEgg = idx <= 35
		addStroke(card, pColor, 2.0)

		-- Real 3D ViewportFrame inside every single card (#1–#117) that zooms & spins on hover!
		local cardVF = Instance.new("ViewportFrame")
		cardVF.Name = "SquishyViewport3D"
		cardVF.Size = cardViewportBaseSize
		cardVF.AnchorPoint = Vector2.new(0.5, 0.5)
		cardVF.Position = UDim2.fromOffset(44, 46)
		cardVF.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
		cardVF.BackgroundTransparency = 0.08
		cardVF.Ambient = Color3.fromRGB(215, 222, 242)
		cardVF.LightColor = Color3.fromRGB(255, 255, 255)
		cardVF.LightDirection = Vector3.new(-1, -1.2, -1)
		cardVF.Parent = card
		addCorner(cardVF, 12)
		addStroke(cardVF, aColor, 2.0)

		local cardCam = Instance.new("Camera")
		cardCam.FieldOfView = 50
		cardCam.CFrame = CFrame.lookAt(Vector3.new(0, 0.85, 4.4), Vector3.new(0, 0.05, 0))
		cardCam.Parent = cardVF
		cardVF.CurrentCamera = cardCam

		local squishy3DModel, basePivot = build3DSquishyViewportModel(cardVF, pColor, aColor, isBossEgg, rarity, nil)

		local hintDesc = if isBossEgg
			then string.format("Steal from Stage %d Sleeping Boss Nest & hatch in Incubator!", slime.Level)
			elseif idx <= 55 then string.format("Climb Stacked Wooden Crates & Plank Bridge onto House Roofs in Stage %d!", slime.Level)
			elseif idx <= 67 then "Climb the 28-Step Rainbow Disappearing Staircase on West Plaza!"
			elseif idx <= 87 then string.format("Explore the Flanking Outer Side Mazes outside Stage %d Castle Walls!", slime.Level)
			elseif idx <= 102 then string.format("Climb the Castle Wall Battlements & Watchtowers in Stage %d!", slime.Level)
			else string.format("Beat the Elevated Sky Obby Gauntlet in Stage %d!", slime.Level)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "NameLabel"
		nameLbl.Size = UDim2.new(1, -90, 0, 44)
		nameLbl.Position = UDim2.fromOffset(86, 6)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.FredokaOne
		nameLbl.TextWrapped = true
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.Text = string.format("<b>#%d %s</b>\n<font color='#A5E5FF'>[Stage %d • %s]</font>", idx, slime.Name, slime.Level, rarity)
		nameLbl.Parent = card
		addTextSizeConstraint(nameLbl, 10, 14)

		local statusLbl = Instance.new("TextLabel")
		statusLbl.Name = "StatusLabel"
		statusLbl.Size = UDim2.new(1, -90, 0, 26)
		statusLbl.Position = UDim2.fromOffset(86, 54)
		statusLbl.BackgroundTransparency = 1
		statusLbl.Font = Enum.Font.GothamBold
		statusLbl.TextXAlignment = Enum.TextXAlignment.Left
		statusLbl.TextColor3 = Color3.fromRGB(170, 180, 205)
		statusLbl.Text = string.format("🔒 <b>$%d/s</b>", anySlime.IncomePerSec or slime.CoinsPerSec or 10)
		statusLbl.Parent = card
		addTextSizeConstraint(statusLbl, 10, 13)

		local cardEntry: IndexCardEntry = {
			Frame = card,
			Status = statusLbl,
			Viewport = cardVF,
			Camera = cardCam,
			SquishyModel = squishy3DModel,
			BasePivot = basePivot,
		}
		indexCards[tostring(slime.Id)] = cardEntry

		-- Hovering any card zooms in its 3D ViewportFrame camera, starts 3D rotation, and updates the Featured Header Inspector!
		card.MouseEnter:Connect(function()
			activeHoveredCard = cardEntry
			TweenService:Create(cardVF, hoverTweenInfo, {
				Size = cardViewportHoverSize,
				BackgroundColor3 = Color3.fromRGB(28, 36, 66),
			}):Play()
			TweenService:Create(cardCam, camZoomTweenInfo, {
				FieldOfView = 34,
			}):Play()

			local featBody = indexFeaturedModel:FindFirstChild("Body") :: BasePart?
			local featBelly = indexFeaturedModel:FindFirstChild("BellyPatch") :: BasePart?
			if featBody then
				featBody.Color = pColor
			end
			if featBelly then
				featBelly.Color = aColor
			end
			indexHintLabel.Text = string.format(
				"💡 <b>#%d %s (%s)</b> : <font color='#FFE875'>%s</font>",
				idx,
				slime.Name,
				rarity,
				hintDesc
			)
		end)

		card.MouseLeave:Connect(function()
			if activeHoveredCard == cardEntry then
				activeHoveredCard = nil
			end
			TweenService:Create(cardVF, hoverTweenInfo, {
				Size = cardViewportBaseSize,
				BackgroundColor3 = Color3.fromRGB(16, 20, 36),
			}):Play()
			TweenService:Create(cardCam, camZoomTweenInfo, {
				FieldOfView = 50,
			}):Play()
			squishy3DModel:PivotTo(basePivot)
		end)
	end
	indexScroll.CanvasSize = UDim2.fromOffset(0, math.ceil(#SlimeData.Slimes / 3) * 104)

	-- Allow triggering hover preview programmatically on Card #1 for default showcase
	local firstCard = indexCards[tostring(SlimeData.Slimes[1].Id)]
	if firstCard then
		activeHoveredCard = firstCard
		firstCard.Camera.FieldOfView = 35
	end

	-- =========================================================================
	-- 5. MODAL #2: 🛒 PREMIUM ROBUX SHOP (Glossy Studded Simulator Styling, 5 Gamepasses + 5 DevProducts & 3D ViewportFrames)
	-- =========================================================================
	local shopModal = Instance.new("Frame")
	shopModal.Name = "ShopModal"
	shopModal.Size = UDim2.fromScale(0.56, 0.65)
	shopModal.Position = UDim2.fromScale(0.5, 0.52)
	shopModal.AnchorPoint = Vector2.new(0.5, 0.5)
	shopModal.BackgroundColor3 = Color3.fromRGB(20, 24, 42)
	shopModal.Visible = false
	shopModal.Parent = screenGui
	addCorner(shopModal, 16)
	addStroke(shopModal, Color3.fromRGB(255, 205, 55), 3.0)
	addAspectRatio(shopModal, 1.50)

	-- Glossy Studded Simulator Header Banner
	local shopHeaderBanner = Instance.new("Frame")
	shopHeaderBanner.Name = "GlossyHeaderBanner"
	shopHeaderBanner.Size = UDim2.new(1, -16, 0, 48)
	shopHeaderBanner.Position = UDim2.fromOffset(8, 6)
	shopHeaderBanner.BackgroundColor3 = Color3.fromRGB(36, 44, 78)
	shopHeaderBanner.Parent = shopModal
	addCorner(shopHeaderBanner, 12)
	addStroke(shopHeaderBanner, Color3.fromRGB(255, 215, 75), 1.8)
	local shopBannerGrad = Instance.new("UIGradient")
	shopBannerGrad.Rotation = 90
	shopBannerGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(185, 195, 230)),
	})
	shopBannerGrad.Parent = shopHeaderBanner

	createFeaturedViewportPreview(
		shopModal,
		UDim2.fromOffset(42, 42),
		UDim2.fromOffset(14, 9),
		Color3.fromRGB(255, 195, 45),
		Color3.fromRGB(255, 255, 255),
		"Crown"
	)

	local shopTitle = Instance.new("TextLabel")
	shopTitle.Size = UDim2.new(1, -125, 0, 42)
	shopTitle.Position = UDim2.fromOffset(66, 9)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Font = Enum.Font.FredokaOne
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.TextColor3 = Color3.fromRGB(255, 225, 75)
	shopTitle.Text = "🛒 <b>PREMIUM ROBUX SHOP — GAMEPASSES & DEV PRODUCTS</b>"
	shopTitle.Parent = shopModal
	addTextSizeConstraint(shopTitle, 12, 20)
	addTextStroke(shopTitle, Color3.fromRGB(12, 16, 28), 2.0)

	local shopClose = Instance.new("TextButton")
	shopClose.Size = closeBtnSize
	shopClose.AnchorPoint = Vector2.new(0.5, 0.5)
	shopClose.Position = UDim2.new(1, -29, 0, 30)
	shopClose.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
	shopClose.AutoButtonColor = false
	shopClose.Font = Enum.Font.FredokaOne
	shopClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopClose.Text = "<b>X</b>"
	shopClose.Parent = shopModal
	addCorner(shopClose, 10)
	addTextSizeConstraint(shopClose, 14, 20)
	bindHoverAndClickTween(shopClose, closeBtnSize, Color3.fromRGB(235, 65, 75))

	-- 5 Gamepasses (MarketplaceService:PromptGamePassPurchase) with 3D ViewportFrame Icons!
	local gamepassConfigs = {
		{ Key = "2xCash", Title = "💰 2x CASH FOREVER", Desc = "Double all Cash & Pedestal $/s!", Price = "199 R$", Color = Color3.fromRGB(255, 195, 45), X = 12, Y = 60, W = 204 },
		{ Key = "2xSpeed", Title = "⚡ 2x TREADMILL SPEED", Desc = "+16 Spd & 2x Treadmill Forever!", Price = "149 R$", Color = Color3.fromRGB(55, 205, 255), X = 224, Y = 60, W = 204 },
		{ Key = "AutoHatch", Title = "🥚 FAST 1s INCUBATORS", Desc = "Instant 1s Hatch on All Eggs!", Price = "249 R$", Color = Color3.fromRGB(195, 95, 255), X = 436, Y = 60, W = 208 },
		{ Key = "VIP", Title = "👑 VIP CROWN + TRAIL", Desc = "VIP Crown, Gold Trail & +50% Cash!", Price = "399 R$", Color = Color3.fromRGB(255, 95, 195), X = 12, Y = 152, W = 310 },
		{ Key = "Carry2Eggs", Title = "🎒 +2 CARRY CAPACITY", Desc = "Carry 2 Boss Eggs at Once to Base!", Price = "299 R$", Color = Color3.fromRGB(75, 235, 130), X = 334, Y = 152, W = 310 },
	}

	local passButtonsByKey: { [string]: TextButton } = {}
	for _, gp in ipairs(gamepassConfigs) do
		local card = Instance.new("Frame")
		card.Name = "GamepassCard_" .. gp.Key
		card.Size = UDim2.fromOffset(gp.W, 84)
		card.Position = UDim2.fromOffset(gp.X, gp.Y)
		card.BackgroundColor3 = Color3.fromRGB(30, 36, 62)
		card.Parent = shopModal
		addCorner(card, 12)
		addStroke(card, gp.Color, 2.0)

		local cardGrad = Instance.new("UIGradient")
		cardGrad.Rotation = 90
		cardGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(205, 212, 235)),
		})
		cardGrad.Parent = card

		-- 3D ViewportFrame preview on each Gamepass Card!
		local gpVF = Instance.new("ViewportFrame")
		gpVF.Name = "GamepassViewport3D"
		gpVF.Size = UDim2.fromOffset(58, 58)
		gpVF.Position = UDim2.fromOffset(8, 13)
		gpVF.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
		gpVF.Ambient = Color3.fromRGB(215, 222, 242)
		gpVF.LightColor = Color3.fromRGB(255, 255, 255)
		gpVF.LightDirection = Vector3.new(-1, -1.2, -1)
		gpVF.Parent = card
		addCorner(gpVF, 10)
		addStroke(gpVF, gp.Color, 1.8)

		local gpCam = Instance.new("Camera")
		gpCam.FieldOfView = 48
		gpCam.CFrame = CFrame.lookAt(Vector3.new(0, 0.85, 4.4), Vector3.new(0, 0.05, 0))
		gpCam.Parent = gpVF
		gpVF.CurrentCamera = gpCam

		local isEggPass = (gp.Key == "AutoHatch" or gp.Key == "Carry2Eggs")
		local gpModel, gpPivot = build3DSquishyViewportModel(gpVF, gp.Color, Color3.fromRGB(255, 245, 120), isEggPass, "Mythic", "Crown")
		table.insert(rotatingViewportModels, {
			Model = gpModel,
			BaseCFrame = gpPivot,
			Speed = 1.45,
		})

		local textW = gp.W - 76
		local tLbl = Instance.new("TextLabel")
		tLbl.Size = UDim2.fromOffset(textW, 22)
		tLbl.Position = UDim2.fromOffset(72, 5)
		tLbl.BackgroundTransparency = 1
		tLbl.Font = Enum.Font.FredokaOne
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.TextColor3 = gp.Color
		tLbl.Text = "<b>" .. gp.Title .. "</b>"
		tLbl.Parent = card
		addTextSizeConstraint(tLbl, 9, 14)

		local dLbl = Instance.new("TextLabel")
		dLbl.Size = UDim2.fromOffset(textW, 18)
		dLbl.Position = UDim2.fromOffset(72, 26)
		dLbl.BackgroundTransparency = 1
		dLbl.Font = Enum.Font.GothamBold
		dLbl.TextXAlignment = Enum.TextXAlignment.Left
		dLbl.TextColor3 = Color3.fromRGB(215, 225, 245)
		dLbl.Text = gp.Desc
		dLbl.Parent = card
		addTextSizeConstraint(dLbl, 8, 11)

		local buyBtn = Instance.new("TextButton")
		local buySize = UDim2.fromOffset(textW - 4, 26)
		buyBtn.Size = buySize
		buyBtn.AnchorPoint = Vector2.new(0.5, 0.5)
		buyBtn.Position = UDim2.fromOffset(72 + (textW - 4) * 0.5, 62)
		buyBtn.BackgroundColor3 = gp.Color
		buyBtn.AutoButtonColor = false
		buyBtn.Font = Enum.Font.FredokaOne
		buyBtn.TextColor3 = Color3.fromRGB(16, 20, 32)
		buyBtn.Text = "🟢 <b>BUY PASS (" .. gp.Price .. ")</b>"
		buyBtn.Parent = card
		addCorner(buyBtn, 8)
		addTextSizeConstraint(buyBtn, 9, 13)
		bindHoverAndClickTween(buyBtn, buySize, gp.Color)
		passButtonsByKey[gp.Key] = buyBtn
	end

	-- 5 Developer Products (MarketplaceService:PromptProductPurchase + ProcessReceipt):
	-- ⚡ Hatch All Incubators Now, 🛡️ Boss Shield (60s), 💵 Starter / Mega / Ultimate Cash Packs!
	local devProducts = {
		{ Key = "InstantHatchAll", Label = "⚡ Hatch All Now (29 R$)", Color = Color3.fromRGB(190, 110, 255), X = 68, W = 120 },
		{ Key = "BossShield60s", Label = "🛡️ Boss Shield 60s (39 R$)", Color = Color3.fromRGB(65, 215, 255), X = 196, W = 124 },
		{ Key = "CashPack5K", Label = "💵 Starter +$5K (49 R$)", Color = Color3.fromRGB(85, 235, 125), X = 324, W = 120 },
		{ Key = "CashPack25K", Label = "💵 Mega +$25K (149 R$)", Color = Color3.fromRGB(255, 205, 55), X = 450, W = 120 },
		{ Key = "CashPack100K", Label = "💎 Ultimate +$100K (399 R$)", Color = Color3.fromRGB(255, 110, 195), X = 580, W = 128 },
	}
	local devProductButtons: { [string]: TextButton } = {}
	for _, dp in ipairs(devProducts) do
		local dpSize = UDim2.fromOffset(dp.W, 42)
		local dpBtn = Instance.new("TextButton")
		dpBtn.Name = "DevProduct_" .. dp.Key
		dpBtn.Size = dpSize
		dpBtn.AnchorPoint = Vector2.new(0.5, 0.5)
		dpBtn.Position = UDim2.fromOffset(dp.X, 266)
		dpBtn.BackgroundColor3 = dp.Color
		dpBtn.AutoButtonColor = false
		dpBtn.Font = Enum.Font.FredokaOne
		dpBtn.TextColor3 = Color3.fromRGB(16, 20, 32)
		dpBtn.Text = "<b>" .. dp.Label .. "</b>"
		dpBtn.Parent = shopModal
		addCorner(dpBtn, 10)
		addStroke(dpBtn, Color3.fromRGB(255, 255, 255), 1.5)
		addTextSizeConstraint(dpBtn, 8, 12)
		bindHoverAndClickTween(dpBtn, dpSize, dp.Color)
		devProductButtons[dp.Key] = dpBtn
	end

	local buySpeedSize = UDim2.fromOffset(630, 48)
	local buySpeedBtn = Instance.new("TextButton")
	buySpeedBtn.Size = buySpeedSize
	buySpeedBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	buySpeedBtn.Position = UDim2.fromOffset(328, 324)
	buySpeedBtn.BackgroundColor3 = Color3.fromRGB(55, 195, 255)
	buySpeedBtn.AutoButtonColor = false
	buySpeedBtn.Font = Enum.Font.FredokaOne
	buySpeedBtn.TextColor3 = Color3.fromRGB(15, 20, 32)
	buySpeedBtn.Text = "🦖 <b>Upgrade Treadmill (+4 Speed) - $50</b>"
	buySpeedBtn.Parent = shopModal
	addCorner(buySpeedBtn, 12)
	addTextSizeConstraint(buySpeedBtn, 12, 18)
	bindHoverAndClickTween(buySpeedBtn, buySpeedSize, Color3.fromRGB(55, 195, 255))

	local rebirthBtn = Instance.new("TextButton")
	rebirthBtn.Size = buySpeedSize
	rebirthBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	rebirthBtn.Position = UDim2.fromOffset(328, 384)
	rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 125, 215)
	rebirthBtn.AutoButtonColor = false
	rebirthBtn.Font = Enum.Font.FredokaOne
	rebirthBtn.TextColor3 = Color3.fromRGB(20, 15, 30)
	rebirthBtn.Text = "✨ <b>Rebirth (+50% Cash & Faster Treadmill) - $5,000</b>"
	rebirthBtn.Parent = shopModal
	addCorner(rebirthBtn, 12)
	addTextSizeConstraint(rebirthBtn, 12, 18)
	bindHoverAndClickTween(rebirthBtn, buySpeedSize, Color3.fromRGB(255, 125, 215))

	-- =========================================================================
	-- 6. MODAL #3: 🎡 LUCKY SQUISHY SPIN WHEEL (1 Free Spin / 5m + Cash/R$ Spins) & 🎁 PLAYTIME REWARDS CHEST (2m, 5m, 10m, 15m, 30m)
	-- =========================================================================
	local spinModal = Instance.new("Frame")
	spinModal.Name = "SpinWheelModal"
	spinModal.Size = UDim2.fromScale(0.56, 0.65)
	spinModal.Position = UDim2.fromScale(0.5, 0.52)
	spinModal.AnchorPoint = Vector2.new(0.5, 0.5)
	spinModal.BackgroundColor3 = Color3.fromRGB(24, 18, 44)
	spinModal.Visible = false
	spinModal.Parent = screenGui
	addCorner(spinModal, 16)
	addStroke(spinModal, Color3.fromRGB(255, 105, 215), 3.0)
	addAspectRatio(spinModal, 1.50)

	createFeaturedViewportPreview(
		spinModal,
		UDim2.fromOffset(42, 42),
		UDim2.fromOffset(14, 8),
		Color3.fromRGB(255, 95, 205),
		Color3.fromRGB(255, 235, 75),
		"Crown"
	)

	local spinTitle = Instance.new("TextLabel")
	spinTitle.Size = UDim2.new(1, -120, 0, 42)
	spinTitle.Position = UDim2.fromOffset(66, 8)
	spinTitle.BackgroundTransparency = 1
	spinTitle.Font = Enum.Font.FredokaOne
	spinTitle.TextXAlignment = Enum.TextXAlignment.Left
	spinTitle.TextColor3 = Color3.fromRGB(255, 235, 85)
	spinTitle.Text = "🎡 <b>LUCKY SPIN WHEEL (FREE EVERY 5M) & 🎁 PLAYTIME CHEST</b>"
	spinTitle.Parent = spinModal
	addTextSizeConstraint(spinTitle, 12, 20)

	local spinClose = Instance.new("TextButton")
	spinClose.Size = closeBtnSize
	spinClose.AnchorPoint = Vector2.new(0.5, 0.5)
	spinClose.Position = UDim2.new(1, -29, 0, 29)
	spinClose.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
	spinClose.AutoButtonColor = false
	spinClose.Font = Enum.Font.FredokaOne
	spinClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	spinClose.Text = "<b>X</b>"
	spinClose.Parent = spinModal
	addCorner(spinClose, 10)
	addTextSizeConstraint(spinClose, 14, 20)
	bindHoverAndClickTween(spinClose, closeBtnSize, Color3.fromRGB(235, 65, 75))

	local wheelPrizesInfo = {
		"💰 <b>+$2,500 Cash</b> (25%)",
		"⚡ <b>+8 Speed Boost</b> (22%)",
		"👑 <b>2x Mythic Cash Mult</b> (18%)",
		"🛡️ <b>60s Boss Shield</b> (15%)",
		"💎 <b>+$15,000 Jackpot</b> (12%)",
		"🌈 <b>Rare/Mythic Squishy!</b> (8%)",
	}
	for idx, pText in ipairs(wheelPrizesInfo) do
		local col = (idx - 1) % 3
		local row = math.floor((idx - 1) / 3)
		local pCard = Instance.new("TextLabel")
		pCard.Size = UDim2.fromOffset(204, 42)
		pCard.Position = UDim2.fromOffset(14 + col * 212, 56 + row * 48)
		pCard.BackgroundColor3 = Color3.fromRGB(44, 32, 72)
		pCard.Font = Enum.Font.FredokaOne
		pCard.TextColor3 = Color3.fromRGB(255, 245, 200)
		pCard.Text = pText
		pCard.Parent = spinModal
		addCorner(pCard, 10)
		addStroke(pCard, Color3.fromRGB(255, 145, 225), 1.8)
		addTextSizeConstraint(pCard, 9, 14)
	end

	-- 3 Spin Action Buttons: Free Spin (Every 5m) + Buy 1 Spin ($2,500 Cash) + Buy 3 Spins (19 R$)
	local spinFreeSize = UDim2.fromOffset(252, 46)
	local spinNowBtn = Instance.new("TextButton")
	spinNowBtn.Name = "SpinNowBtn"
	spinNowBtn.Size = spinFreeSize
	spinNowBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	spinNowBtn.Position = UDim2.fromOffset(140, 180)
	spinNowBtn.BackgroundColor3 = Color3.fromRGB(255, 95, 205)
	spinNowBtn.AutoButtonColor = false
	spinNowBtn.Font = Enum.Font.FredokaOne
	spinNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	spinNowBtn.Text = "🎡 <b>FREE SPIN (READY!)</b>"
	spinNowBtn.Parent = spinModal
	addCorner(spinNowBtn, 12)
	addStroke(spinNowBtn, Color3.fromRGB(255, 255, 255), 1.8)
	addTextSizeConstraint(spinNowBtn, 10, 16)
	bindHoverAndClickTween(spinNowBtn, spinFreeSize, Color3.fromRGB(255, 95, 205))

	local buySpinBtnSize = UDim2.fromOffset(180, 46)
	local buySpinCashBtn = Instance.new("TextButton")
	buySpinCashBtn.Name = "BuySpinCashBtn"
	buySpinCashBtn.Size = buySpinBtnSize
	buySpinCashBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	buySpinCashBtn.Position = UDim2.fromOffset(366, 180)
	buySpinCashBtn.BackgroundColor3 = Color3.fromRGB(85, 225, 120)
	buySpinCashBtn.AutoButtonColor = false
	buySpinCashBtn.Font = Enum.Font.FredokaOne
	buySpinCashBtn.TextColor3 = Color3.fromRGB(16, 28, 18)
	buySpinCashBtn.Text = "💵 <b>BUY SPIN ($2,500)</b>"
	buySpinCashBtn.Parent = spinModal
	addCorner(buySpinCashBtn, 12)
	addStroke(buySpinCashBtn, Color3.fromRGB(255, 255, 255), 1.8)
	addTextSizeConstraint(buySpinCashBtn, 10, 15)
	bindHoverAndClickTween(buySpinCashBtn, buySpinBtnSize, Color3.fromRGB(85, 225, 120))

	local buySpinRobuxBtn = Instance.new("TextButton")
	buySpinRobuxBtn.Name = "BuySpinRobuxBtn"
	buySpinRobuxBtn.Size = buySpinBtnSize
	buySpinRobuxBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	buySpinRobuxBtn.Position = UDim2.fromOffset(554, 180)
	buySpinRobuxBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 55)
	buySpinRobuxBtn.AutoButtonColor = false
	buySpinRobuxBtn.Font = Enum.Font.FredokaOne
	buySpinRobuxBtn.TextColor3 = Color3.fromRGB(20, 18, 28)
	buySpinRobuxBtn.Text = "💎 <b>+3 SPINS (19 R$)</b>"
	buySpinRobuxBtn.Parent = spinModal
	addCorner(buySpinRobuxBtn, 12)
	addStroke(buySpinRobuxBtn, Color3.fromRGB(255, 255, 255), 1.8)
	addTextSizeConstraint(buySpinRobuxBtn, 10, 15)
	bindHoverAndClickTween(buySpinRobuxBtn, buySpinBtnSize, Color3.fromRGB(255, 200, 55))

	-- Playtime Rewards Chest Section Header (2m, 5m, 10m, 15m, 30m)
	local playtimeHeader = Instance.new("TextLabel")
	playtimeHeader.Size = UDim2.new(1, -28, 0, 24)
	playtimeHeader.Position = UDim2.fromOffset(14, 212)
	playtimeHeader.BackgroundTransparency = 1
	playtimeHeader.Font = Enum.Font.FredokaOne
	playtimeHeader.TextXAlignment = Enum.TextXAlignment.Left
	playtimeHeader.TextColor3 = Color3.fromRGB(115, 245, 255)
	playtimeHeader.Text = "⏱️ <b>PLAYTIME REWARDS CHEST (2m • 5m • 10m • 15m • 30m)</b> — Stay in-game for free Cash, Speed & Mythics!"
	playtimeHeader.Parent = spinModal
	addTextSizeConstraint(playtimeHeader, 10, 15)

	local playtimeMilestones = {
		{ Index = 1, TimeLabel = "2m", RewardText = "+$1.5K\n+3 Spd", Color = Color3.fromRGB(75, 215, 255) },
		{ Index = 2, TimeLabel = "5m", RewardText = "+$4K\n+6 Spd", Color = Color3.fromRGB(95, 235, 135) },
		{ Index = 3, TimeLabel = "10m", RewardText = "+$10K\n+1 Spin", Color = Color3.fromRGB(255, 205, 65) },
		{ Index = 4, TimeLabel = "15m", RewardText = "+$25K\n+Shield", Color = Color3.fromRGB(205, 110, 255) },
		{ Index = 5, TimeLabel = "30m", RewardText = "+$75K\n+Mythic!", Color = Color3.fromRGB(255, 95, 195) },
	}
	local playtimeButtons: { [number]: TextButton } = {}
	for i, pm in ipairs(playtimeMilestones) do
		local cardW = 120
		local cardX = 14 + (i - 1) * 127
		local pBox = Instance.new("Frame")
		pBox.Name = "PlaytimeCard_" .. pm.TimeLabel
		pBox.Size = UDim2.fromOffset(cardW, 108)
		pBox.Position = UDim2.fromOffset(cardX, 240)
		pBox.BackgroundColor3 = Color3.fromRGB(36, 28, 62)
		pBox.Parent = spinModal
		addCorner(pBox, 10)
		addStroke(pBox, pm.Color, 2.0)

		local tBadge = Instance.new("TextLabel")
		tBadge.Size = UDim2.new(1, -8, 0, 22)
		tBadge.Position = UDim2.fromOffset(4, 4)
		tBadge.BackgroundTransparency = 1
		tBadge.Font = Enum.Font.FredokaOne
		tBadge.TextColor3 = pm.Color
		tBadge.Text = "🎁 <b>" .. pm.TimeLabel .. " REWARD</b>"
		tBadge.Parent = pBox
		addTextSizeConstraint(tBadge, 9, 13)

		local rDesc = Instance.new("TextLabel")
		rDesc.Size = UDim2.new(1, -8, 0, 40)
		rDesc.Position = UDim2.fromOffset(4, 26)
		rDesc.BackgroundTransparency = 1
		rDesc.Font = Enum.Font.FredokaOne
		rDesc.TextColor3 = Color3.fromRGB(255, 255, 255)
		rDesc.Text = "<b>" .. pm.RewardText .. "</b>"
		rDesc.Parent = pBox
		addTextSizeConstraint(rDesc, 9, 13)

		local ptBtnSize = UDim2.fromOffset(106, 28)
		local ptBtn = Instance.new("TextButton")
		ptBtn.Name = "ClaimPlaytime_" .. tostring(i)
		ptBtn.Size = ptBtnSize
		ptBtn.AnchorPoint = Vector2.new(0.5, 0.5)
		ptBtn.Position = UDim2.fromOffset(cardW * 0.5, 86)
		ptBtn.BackgroundColor3 = pm.Color
		ptBtn.AutoButtonColor = false
		ptBtn.Font = Enum.Font.FredokaOne
		ptBtn.TextColor3 = Color3.fromRGB(16, 20, 32)
		ptBtn.Text = "⏳ <b>" .. pm.TimeLabel .. "</b>"
		ptBtn.Parent = pBox
		addCorner(ptBtn, 8)
		addTextSizeConstraint(ptBtn, 9, 13)
		bindHoverAndClickTween(ptBtn, ptBtnSize, pm.Color)
		playtimeButtons[i] = ptBtn
	end

	local dailyBtnSize = UDim2.fromOffset(630, 48)
	local claimDailyModalBtn = Instance.new("TextButton")
	claimDailyModalBtn.Size = dailyBtnSize
	claimDailyModalBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	claimDailyModalBtn.Position = UDim2.fromOffset(328, 382)
	claimDailyModalBtn.BackgroundColor3 = Color3.fromRGB(85, 235, 115)
	claimDailyModalBtn.AutoButtonColor = false
	claimDailyModalBtn.Font = Enum.Font.FredokaOne
	claimDailyModalBtn.TextColor3 = Color3.fromRGB(16, 28, 18)
	claimDailyModalBtn.Text = "🎁 <b>CLAIM DAILY LOGIN STREAK CHEST (+Cash, +Speed & +Bear Trap)</b>"
	claimDailyModalBtn.Parent = spinModal
	addCorner(claimDailyModalBtn, 12)
	addTextSizeConstraint(claimDailyModalBtn, 11, 18)
	bindHoverAndClickTween(claimDailyModalBtn, dailyBtnSize, Color3.fromRGB(85, 235, 115))

	-- =========================================================================
	-- 7. CENTER-SCREEN "🎉 YOU FOUND 🎉" CELEBRATION POPUP
	-- =========================================================================
	local youFoundPopup = Instance.new("Frame")
	youFoundPopup.Name = "YouFoundCelebrationPopup"
	youFoundPopup.Size = UDim2.fromOffset(380, 210)
	youFoundPopup.Position = UDim2.fromScale(0.5, 0.44)
	youFoundPopup.AnchorPoint = Vector2.new(0.5, 0.5)
	youFoundPopup.BackgroundColor3 = Color3.fromRGB(24, 30, 52)
	youFoundPopup.BackgroundTransparency = 0.06
	youFoundPopup.Visible = false
	youFoundPopup.Parent = screenGui
	addCorner(youFoundPopup, 18)
	addStroke(youFoundPopup, Color3.fromRGB(255, 225, 75), 3.5)
	addAspectRatio(youFoundPopup, 1.81)

	local yfHeader = Instance.new("TextLabel")
	yfHeader.Size = UDim2.new(1, -20, 0, 42)
	yfHeader.Position = UDim2.fromOffset(10, 10)
	yfHeader.BackgroundTransparency = 1
	yfHeader.Font = Enum.Font.FredokaOne
	yfHeader.TextColor3 = Color3.fromRGB(255, 235, 75)
	yfHeader.Text = "🎉 <b>YOU FOUND</b> 🎉"
	yfHeader.Parent = youFoundPopup
	addTextSizeConstraint(yfHeader, 16, 32)
	addTextStroke(yfHeader, Color3.fromRGB(16, 20, 34), 2.5)

	local yfBadge = Instance.new("Frame")
	yfBadge.Size = UDim2.fromOffset(74, 74)
	yfBadge.Position = UDim2.new(0.5, 0, 0, 92)
	yfBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	yfBadge.BackgroundColor3 = Color3.fromRGB(95, 225, 255)
	yfBadge.Parent = youFoundPopup
	addCorner(yfBadge, 37)
	addStroke(yfBadge, Color3.fromRGB(255, 255, 255), 3.0)

	local yfEmoji = Instance.new("TextLabel")
	yfEmoji.Size = UDim2.fromScale(1, 1)
	yfEmoji.BackgroundTransparency = 1
	yfEmoji.Font = Enum.Font.FredokaOne
	yfEmoji.TextColor3 = Color3.fromRGB(255, 255, 255)
	yfEmoji.Text = "✨"
	yfEmoji.Parent = yfBadge
	addTextSizeConstraint(yfEmoji, 18, 38)

	local yfRarityLbl = Instance.new("TextLabel")
	yfRarityLbl.Size = UDim2.new(1, -20, 0, 26)
	yfRarityLbl.Position = UDim2.fromOffset(10, 134)
	yfRarityLbl.BackgroundTransparency = 1
	yfRarityLbl.Font = Enum.Font.FredokaOne
	yfRarityLbl.TextColor3 = Color3.fromRGB(115, 245, 145)
	yfRarityLbl.Text = "<b>[COMMON]</b>"
	yfRarityLbl.Parent = youFoundPopup
	addTextSizeConstraint(yfRarityLbl, 12, 20)
	addTextStroke(yfRarityLbl, Color3.fromRGB(14, 18, 30), 2.0)

	local yfNameLbl = Instance.new("TextLabel")
	yfNameLbl.Size = UDim2.new(1, -20, 0, 34)
	yfNameLbl.Position = UDim2.fromOffset(10, 162)
	yfNameLbl.BackgroundTransparency = 1
	yfNameLbl.Font = Enum.Font.FredokaOne
	yfNameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	yfNameLbl.Text = "<b>Squishy Name</b>"
	yfNameLbl.Parent = youFoundPopup
	addTextSizeConstraint(yfNameLbl, 14, 25)
	addTextStroke(yfNameLbl, Color3.fromRGB(14, 18, 30), 2.5)

	return {
		ScreenGui = screenGui,
		TopContainer = topContainer,
		TopBannerLabel = topBannerLabel,
		TopIndexBtn = topIndexBtn,
		TopSpeedBtn = topSpeedBtn,
		SquishyBarGroup = squishyBarGroup,
		SquishyBarFill = squishyBarFill,
		SquishyBarText = squishyBarText,
		SpeedBarGroup = speedBarGroup,
		SpeedBarFill = speedBarFill,
		SpeedBarText = speedBarText,
		ObjectiveBanner = objectiveBanner,
		ObjectiveText = objectiveText,
		GuideToggleBtn = guideToggleBtn,
		HowToPlayModal = howToPlayModal,
		HowToPlayClose = htpClose,
		ComboFrame = comboFrame,
		ComboLabel = comboLabel,
		ComboFill = comboFill,
		AlertToast = alertToast,
		ShopBtn = shopBtn,
		IndexBtn = indexBtn,
		DailyBtn = dailyBtn,
		SloMoBtn = sloMoBtn,
		WheelBtn = wheelBtn,
		VIPBtn = vipBtn,
		EggsDockBtn = eggsDockBtn,
		SpeedDockBtn = speedDockBtn,
		RebirthDockBtn = rebirthDockBtn,
		SpeedCounterLbl = speedCounterLbl,
		SpeedPlusBtn = speedPlusBtn,
		CashCounterLbl = cashCounterLbl,
		CashPlusBtn = cashPlusBtn,
		SpeedThrottleButtons = speedThrottleButtons,
		IndexModal = indexModal,
		IndexFeaturedViewport = indexFeaturedViewport,
		IndexFeaturedModel = indexFeaturedModel,
		IndexTitle = indexTitle,
		IndexHintLabel = indexHintLabel,
		IndexClose = indexClose,
		IndexCards = indexCards,
		ShopModal = shopModal,
		ShopClose = shopClose,
		PassButtonsByKey = passButtonsByKey,
		DevProductButtons = devProductButtons,
		BuySpeedBtn = buySpeedBtn,
		RebirthBtn = rebirthBtn,
		SpinModal = spinModal,
		SpinClose = spinClose,
		SpinNowBtn = spinNowBtn,
		BuySpinCashBtn = buySpinCashBtn,
		BuySpinRobuxBtn = buySpinRobuxBtn,
		PlaytimeButtons = playtimeButtons,
		ClaimDailyModalBtn = claimDailyModalBtn,
		YouFoundPopup = youFoundPopup,
		YfBadge = yfBadge,
		YfRarityLbl = yfRarityLbl,
		YfNameLbl = yfNameLbl,
		RotatingViewportModels = rotatingViewportModels,
		GetActiveHoveredCard = function(): IndexCardEntry?
			return activeHoveredCard
		end,
	}
end

return UIBuilder
