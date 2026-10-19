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
local SquishyBuilder = require(script.Parent:WaitForChild("SquishyBuilder"))
local PrebuiltLoader = require(script.Parent:WaitForChild("PrebuiltLoader"))

local UIBuilder = {}


export type RotatingViewportEntry = {
	Model: Model,
	BaseCFrame: CFrame,
	Speed: number,
}

export type IndexCardEntry = {
	Frame: TextButton,
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
	btn.Selectable = true
	local hoverSize = scaleUDim2(baseSize, 1.08)
	local downSize = scaleUDim2(baseSize, 0.94)
	local hoverColor = baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.20)

	local function onHoverEnter()
		TweenService:Create(btn, hoverTweenInfo, {
			Size = hoverSize,
			BackgroundColor3 = hoverColor,
		}):Play()
	end
	local function onHoverLeave()
		TweenService:Create(btn, hoverTweenInfo, {
			Size = baseSize,
			BackgroundColor3 = baseColor,
		}):Play()
	end

	btn.MouseEnter:Connect(onHoverEnter)
	btn.MouseLeave:Connect(onHoverLeave)
	btn.SelectionGained:Connect(onHoverEnter)
	btn.SelectionLost:Connect(onHoverLeave)
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
	shapeStyle: string?,
	slimeDef: any?
): (Model, CFrame)
	local basePivot = CFrame.new(0, 0.05, 0) * CFrame.Angles(0, math.rad(-18), 0)

	if slimeDef and (slimeDef.IsBrainrot or (tonumber(slimeDef.Id) and tonumber(slimeDef.Id) <= 35)) then
		local hatched = SquishyBuilder.CreateHatchedSquishy(slimeDef, Vector3.zero, 1, 1)
		hatched.Name = "Squishy3DPreview"
		for _, desc in ipairs(hatched:GetDescendants()) do
			if
				desc:IsA("BillboardGui")
				or desc:IsA("ProximityPrompt")
				or desc:IsA("Highlight")
				or desc:IsA("Light")
				or desc:IsA("ParticleEmitter")
			then
				desc:Destroy()
			elseif desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
				desc.CanTouch = false
				desc.CanQuery = false
				desc.CastShadow = false
			end
		end

		local okBB, bbCF, bbSize = pcall(function()
			return hatched:GetBoundingBox()
		end)
		if okBB and bbSize.Magnitude > 0.05 then
			local maxDim = math.max(bbSize.X, bbSize.Y, bbSize.Z)
			local targetDim = 2.35
			local scaleFactor = math.clamp(targetDim / math.max(maxDim, 0.1), 0.08, 2.5)
			pcall(function()
				hatched:ScaleTo(hatched:GetScale() * scaleFactor)
			end)
		end

		local okBB2, bbCF2, bbSize2 = pcall(function()
			return hatched:GetBoundingBox()
		end)
		if okBB2 then
			local centerOffset = bbCF2.Position
			for _, desc in ipairs(hatched:GetDescendants()) do
				if desc:IsA("BasePart") then
					local relCF = CFrame.new(-centerOffset) * desc.CFrame
					desc.CFrame = basePivot * relCF
				end
			end
		end
		local root = Instance.new("Part")
		root.Name = "ViewportCenterRoot"
		root.Size = Vector3.new(0.05, 0.05, 0.05)
		root.Transparency = 1
		root.Anchored = true
		root.CanCollide = false
		root.CanTouch = false
		root.CanQuery = false
		root.CFrame = basePivot
		root.Parent = hatched
		hatched.PrimaryPart = root

		hatched.Parent = parent
		return hatched, basePivot
	end

	local model = Instance.new("Model")
	model.Name = "Squishy3DPreview"

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
	-- 1. TOP-CENTER LIVE PROGRESS BARS (Dismissible / Collapsible with 'X' Buttons!)
	-- =========================================================================
	local topContainer = Instance.new("Frame")
	topContainer.Name = "TopHUDContainer"
	topContainer.Size = UDim2.new(0.44, 0, 0.098, 0)
	topContainer.Position = UDim2.new(0.5, 0, 0.008, 0)
	topContainer.AnchorPoint = Vector2.new(0.5, 0)
	topContainer.BackgroundColor3 = Color3.fromRGB(18, 22, 40)
	topContainer.BackgroundTransparency = 0.08
	topContainer.Visible = false
	topContainer.Parent = screenGui
	addCorner(topContainer, 14)
	addStroke(topContainer, Color3.fromRGB(255, 215, 70), 2.5)
	addAspectRatio(topContainer, 6.2)

	-- Small Top-Right Restore Pill (Permanently hidden per HUD cleanup specification)
	local restoreTopHudBtnSize = UDim2.fromScale(0.11, 0.038)
	local restoreTopHudBtn = Instance.new("TextButton")
	restoreTopHudBtn.Name = "RestoreTopHudBtn"
	restoreTopHudBtn.Size = restoreTopHudBtnSize
	restoreTopHudBtn.AnchorPoint = Vector2.new(1, 0)
	restoreTopHudBtn.Position = UDim2.fromScale(0.988, 0.012)
	restoreTopHudBtn.BackgroundColor3 = Color3.fromRGB(28, 36, 64)
	restoreTopHudBtn.AutoButtonColor = false
	restoreTopHudBtn.Font = Enum.Font.FredokaOne
	restoreTopHudBtn.TextColor3 = Color3.fromRGB(255, 235, 85)
	restoreTopHudBtn.Text = "📊 <b>SHOW HUD</b>"
	restoreTopHudBtn.Visible = false
	restoreTopHudBtn.Parent = screenGui
	addCorner(restoreTopHudBtn, 10)
	addStroke(restoreTopHudBtn, Color3.fromRGB(255, 215, 70), 2.0)
	addTextSizeConstraint(restoreTopHudBtn, 9, 14)
	bindHoverAndClickTween(restoreTopHudBtn, restoreTopHudBtnSize, Color3.fromRGB(28, 36, 64))

	local topBannerLabel = Instance.new("TextLabel")
	topBannerLabel.Name = "TopBannerLabel"
	topBannerLabel.Size = UDim2.new(0.66, 0, 0.28, 0)
	topBannerLabel.Position = UDim2.fromScale(0.02, 0.04)
	topBannerLabel.BackgroundTransparency = 1
	topBannerLabel.Font = Enum.Font.FredokaOne
	topBannerLabel.TextXAlignment = Enum.TextXAlignment.Left
	topBannerLabel.TextColor3 = Color3.fromRGB(255, 245, 190)
	topBannerLabel.Text = "✨ <b>FIND MY SQUISHY AND STEAL MY EGG (BRAINROT)</b>  |  Plot #1  |  ⚡ <font color='#65FF8F'>$0/sec</font>"
	topBannerLabel.Parent = topContainer
	addTextSizeConstraint(topBannerLabel, 11, 18)
	addTextStroke(topBannerLabel, Color3.fromRGB(10, 12, 22), 1.8)

	-- Top-Bar Quick Action Buttons (AnchorPoint = 0.5, 0.5 + Smooth Hover & Click Tween!)
	local topIndexBtnSize = UDim2.fromScale(0.095, 0.24)
	local topIndexBtn = Instance.new("TextButton")
	topIndexBtn.Name = "TopIndexBtn"
	topIndexBtn.Size = topIndexBtnSize
	topIndexBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	topIndexBtn.Position = UDim2.fromScale(0.74, 0.18)
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

	local topSpeedBtnSize = UDim2.fromScale(0.095, 0.24)
	local topSpeedBtn = Instance.new("TextButton")
	topSpeedBtn.Name = "TopSpeedBtn"
	topSpeedBtn.Size = topSpeedBtnSize
	topSpeedBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	topSpeedBtn.Position = UDim2.fromScale(0.85, 0.18)
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

	-- Red Close / Hide Button ('✕') on TopHUDContainer so players can dismiss the top progress box anytime!
	local topCloseBtnSize = UDim2.fromScale(0.065, 0.24)
	local topHudCloseBtn = Instance.new("TextButton")
	topHudCloseBtn.Name = "TopHudCloseBtn"
	topHudCloseBtn.Size = topCloseBtnSize
	topHudCloseBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	topHudCloseBtn.Position = UDim2.fromScale(0.945, 0.18)
	topHudCloseBtn.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
	topHudCloseBtn.AutoButtonColor = false
	topHudCloseBtn.Font = Enum.Font.FredokaOne
	topHudCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	topHudCloseBtn.Text = "<b>✕</b>"
	topHudCloseBtn.Parent = topContainer
	addCorner(topHudCloseBtn, 8)
	addStroke(topHudCloseBtn, Color3.fromRGB(255, 255, 255), 1.6)
	addTextSizeConstraint(topHudCloseBtn, 10, 15)
	bindHoverAndClickTween(topHudCloseBtn, topCloseBtnSize, Color3.fromRGB(235, 65, 75))

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

	-- Progress Bar #2: Next Stage Speed Unlock Progress Bar (Hidden — Speed system removed)
	local speedBarGroup = Instance.new("CanvasGroup")
	speedBarGroup.Name = "SpeedGoalProgressBar"
	speedBarGroup.Size = UDim2.fromScale(0.96, 0.26)
	speedBarGroup.Position = UDim2.fromScale(0.02, 0.68)
	speedBarGroup.BackgroundColor3 = Color3.fromRGB(10, 14, 26)
	speedBarGroup.ClipsDescendants = true
	speedBarGroup.Visible = false
	speedBarGroup.Parent = topContainer
	addCorner(speedBarGroup, 10)
	addStroke(speedBarGroup, Color3.fromRGB(255, 175, 65), 2.0)

	local speedBarFill = Instance.new("Frame")
	speedBarFill.Name = "Fill"
	speedBarFill.Size = UDim2.fromScale(0, 1)
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
	speedBarText.Text = ""
	speedBarText.Parent = speedBarGroup
	addTextSizeConstraint(speedBarText, 9, 15)
	addTextStroke(speedBarText, Color3.fromRGB(10, 14, 24), 2.0)

	-- 1B. LIVE OBJECTIVE & GUIDING ARROW TRACKER BANNER + HOW-TO-PLAY BUTTON + CLOSE ('✕') BUTTON
	local objectiveBanner = Instance.new("Frame")
	objectiveBanner.Name = "ObjectiveTrackerBanner"
	objectiveBanner.Size = UDim2.fromScale(0.44, 0.038)
	objectiveBanner.Position = UDim2.fromScale(0.5, 0.112)
	objectiveBanner.AnchorPoint = Vector2.new(0.5, 0)
	objectiveBanner.BackgroundColor3 = Color3.fromRGB(16, 24, 46)
	objectiveBanner.BackgroundTransparency = 0.08
	objectiveBanner.Visible = false
	objectiveBanner.Parent = screenGui
	addCorner(objectiveBanner, 10)
	addStroke(objectiveBanner, Color3.fromRGB(85, 235, 255), 2.0)

	local objectiveText = Instance.new("TextLabel")
	objectiveText.Name = "ObjectiveText"
	objectiveText.Size = UDim2.fromScale(0.76, 0.90)
	objectiveText.Position = UDim2.fromScale(0.02, 0.05)
	objectiveText.BackgroundTransparency = 1
	objectiveText.Font = Enum.Font.FredokaOne
	objectiveText.TextXAlignment = Enum.TextXAlignment.Left
	objectiveText.TextColor3 = Color3.fromRGB(125, 255, 195)
	objectiveText.Text = "🧭 <b>FOLLOW 3D ARROW:</b> Steal Stage Eggs & Find Squishies!"
	objectiveText.Parent = objectiveBanner
	addTextSizeConstraint(objectiveText, 10, 15)
	addTextStroke(objectiveText, Color3.fromRGB(10, 14, 24), 1.8)

	local guideBtnSize = UDim2.fromScale(0.12, 0.78)
	local guideToggleBtn = Instance.new("TextButton")
	guideToggleBtn.Name = "GuideToggleBtn"
	guideToggleBtn.Size = guideBtnSize
	guideToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	guideToggleBtn.Position = UDim2.fromScale(0.85, 0.5)
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

	local closeBannerBtnSize = UDim2.fromScale(0.065, 0.78)
	local closeBannerBtn = Instance.new("TextButton")
	closeBannerBtn.Name = "CloseBannerBtn"
	closeBannerBtn.Size = closeBannerBtnSize
	closeBannerBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	closeBannerBtn.Position = UDim2.fromScale(0.955, 0.5)
	closeBannerBtn.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
	closeBannerBtn.AutoButtonColor = false
	closeBannerBtn.Font = Enum.Font.FredokaOne
	closeBannerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBannerBtn.Text = "<b>✕</b>"
	closeBannerBtn.Parent = objectiveBanner
	addCorner(closeBannerBtn, 8)
	addStroke(closeBannerBtn, Color3.fromRGB(255, 255, 255), 1.5)
	addTextSizeConstraint(closeBannerBtn, 9, 14)
	bindHoverAndClickTween(closeBannerBtn, closeBannerBtnSize, Color3.fromRGB(235, 65, 75))

	-- Permanently hide top HUD banner & restore button per clean screen directives
	local function updateRestoreBtnVisibility()
		restoreTopHudBtn.Visible = false
	end
	topHudCloseBtn.Activated:Connect(function()
		topContainer.Visible = false
		updateRestoreBtnVisibility()
	end)
	closeBannerBtn.Activated:Connect(function()
		objectiveBanner.Visible = false
		updateRestoreBtnVisibility()
	end)
	restoreTopHudBtn.Activated:Connect(function()
		restoreTopHudBtn.Visible = false
	end)

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
	htpTitle.Text = "🧭 <b>HOW TO PLAY — Find my Squishy and steal my egg (brainrot)</b>"
	htpTitle.Parent = howToPlayModal
	addTextSizeConstraint(htpTitle, 13, 22)

	local htpCloseSize = UDim2.fromOffset(34, 34)
	local htpClose = Instance.new("TextButton")
	htpClose.Name = "CloseBtn"
	htpClose.Size = htpCloseSize
	htpClose.AnchorPoint = Vector2.new(0.5, 0.5)
	htpClose.Position = UDim2.new(1, -26, 0, 26)
	htpClose.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
	htpClose.AutoButtonColor = false
	htpClose.Font = Enum.Font.FredokaOne
	htpClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	htpClose.Text = "<b>X</b>"
	htpClose.Parent = howToPlayModal
	addCorner(htpClose, 8)
	bindHoverAndClickTween(htpClose, htpCloseSize, Color3.fromRGB(235, 65, 75))

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
		"🧸 <b>STEP 1 — WALK OVER SQUISHIES:</b> Walk right over Collectible Squishies in Houses, Mazes, Castle Walls & Obbies (auto-pickup, zero button holding! Chain pickups for <b>x5.0 SQUISH FEVER CASH!</b>).",
		"🥚 <b>STEP 2 — STEAL BOSS EGGS:</b> Sneak into Sector 3's Sleeping Boss Arena & walk over Boss Eggs to steal them!",
		"🏡 <b>STEP 3 — HATCH IN FENCED PEN:</b> Walk into your Plot's <b>Fenced Hatchery Pen</b> — Eggs auto-drop, countdown (00:05), and hatch into live roaming Squishies!",
		"⬆️ <b>STEP 4 — GROW & CLAIM $/SEC CASH:</b> Upgrade your roaming Squishies in the pen so they physically grow larger, wear Crowns, and multiply $/sec Cash!",
		"🔓 <b>STEP 5 — 100% STAGE UNLOCK:</b> Complete <b>100% of all Stage Squishies + Boss Eggs</b> to unlock the next Stage Gate (Stages 1 -> 8)!",
	}, "\n\n")
	htpBody.Parent = howToPlayModal
	addTextSizeConstraint(htpBody, 10, 15)

	-- Alert Toast Banner (ZIndex = 250 so it always renders ON TOP of ShopModal, SpinModal, IndexModal & LikeFavoriteModal!)
	local alertToast = Instance.new("TextLabel")
	alertToast.Name = "AlertToast"
	alertToast.Size = UDim2.fromScale(0.56, 0.052)
	alertToast.Position = UDim2.fromScale(0.5, 0.085)
	alertToast.AnchorPoint = Vector2.new(0.5, 0)
	alertToast.BackgroundColor3 = Color3.fromRGB(215, 45, 65)
	alertToast.Font = Enum.Font.FredokaOne
	alertToast.TextColor3 = Color3.fromRGB(255, 255, 255)
	alertToast.Text = ""
	alertToast.ZIndex = 250
	alertToast.Visible = false
	alertToast.Parent = screenGui
	addCorner(alertToast, 12)
	addStroke(alertToast, Color3.fromRGB(255, 235, 95), 2.5)
	addTextSizeConstraint(alertToast, 11, 20)

	-- =========================================================================
	-- 2. LEFT HUD CLUSTER & RIGHT VERTICAL SQUARE DOCK (Custom Layered Vector Icons)
	-- =========================================================================
	local leftGrid = Instance.new("Frame")
	leftGrid.Name = "LeftMenuGrid"
	leftGrid.Size = UDim2.fromScale(0.135, 0.24)
	leftGrid.Position = UDim2.fromScale(0.012, 0.45)
	leftGrid.AnchorPoint = Vector2.new(0, 0.5)
	leftGrid.BackgroundTransparency = 1
	leftGrid.Parent = screenGui
	addAspectRatio(leftGrid, 0.85)

	-- Row 1: Wide Golden-Yellow Shop Button (shopBtn)
	local shopBtnSize = UDim2.fromScale(0.96, 0.31)
	local shopBtn = Instance.new("TextButton")
	shopBtn.Name = "ShopBtn"
	shopBtn.Size = shopBtnSize
	shopBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	shopBtn.Position = UDim2.fromScale(0.48, 0.17)
	shopBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 45)
	shopBtn.AutoButtonColor = false
	shopBtn.Text = ""
	shopBtn.Parent = leftGrid
	addCorner(shopBtn, 8)
	addStroke(shopBtn, Color3.fromRGB(24, 18, 10), 2.8)

	local shopGrad = Instance.new("UIGradient")
	shopGrad.Rotation = 90
	shopGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 230, 75)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(245, 165, 25)),
	})
	shopGrad.Parent = shopBtn

	-- Layered Red Shopping Basket Icon on the left
	local shopIconHolder = Instance.new("Frame")
	shopIconHolder.Name = "Icon"
	shopIconHolder.Size = UDim2.fromScale(0.26, 0.72)
	shopIconHolder.Position = UDim2.fromScale(0.06, 0.14)
	shopIconHolder.BackgroundTransparency = 1
	shopIconHolder.Parent = shopBtn

	local basketHandle = Instance.new("Frame")
	basketHandle.Name = "Handle"
	basketHandle.Size = UDim2.fromScale(0.52, 0.34)
	basketHandle.Position = UDim2.fromScale(0.24, 0.04)
	basketHandle.BackgroundTransparency = 1
	basketHandle.Parent = shopIconHolder
	addCorner(basketHandle, 4)
	addStroke(basketHandle, Color3.fromRGB(22, 12, 12), 2.2)

	local basketRim = Instance.new("Frame")
	basketRim.Name = "BasketRim"
	basketRim.Size = UDim2.fromScale(0.96, 0.18)
	basketRim.Position = UDim2.fromScale(0.02, 0.28)
	basketRim.BackgroundColor3 = Color3.fromRGB(248, 72, 72)
	basketRim.Parent = shopIconHolder
	addCorner(basketRim, 3)
	addStroke(basketRim, Color3.fromRGB(22, 12, 12), 1.8)

	local basketBody = Instance.new("Frame")
	basketBody.Name = "BasketBody"
	basketBody.Size = UDim2.fromScale(0.84, 0.52)
	basketBody.Position = UDim2.fromScale(0.08, 0.44)
	basketBody.BackgroundColor3 = Color3.fromRGB(235, 52, 52)
	basketBody.Parent = shopIconHolder
	addCorner(basketBody, 4)
	addStroke(basketBody, Color3.fromRGB(22, 12, 12), 2.0)

	for sIdx = 1, 2 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. tostring(sIdx)
		slot.Size = UDim2.fromScale(0.12, 0.62)
		slot.Position = UDim2.fromScale(if sIdx == 1 then 0.30 else 0.58, 0.19)
		slot.BackgroundColor3 = Color3.fromRGB(22, 12, 12)
		slot.BorderSizePixel = 0
		slot.Parent = basketBody
		addCorner(slot, 2)
	end

	local shopCap = Instance.new("TextLabel")
	shopCap.Name = "Caption"
	shopCap.Size = UDim2.fromScale(0.60, 0.80)
	shopCap.Position = UDim2.fromScale(0.35, 0.10)
	shopCap.BackgroundTransparency = 1
	shopCap.Font = Enum.Font.FredokaOne
	shopCap.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopCap.Text = "<b>Shop</b>"
	shopCap.Parent = shopBtn
	addTextSizeConstraint(shopCap, 12, 26)
	addTextStroke(shopCap, Color3.fromRGB(12, 12, 16), 2.6)
	bindHoverAndClickTween(shopBtn, shopBtnSize, Color3.fromRGB(255, 200, 45))

	-- Row 2 Left: Sky-Blue Index Button (indexBtn)
	local indexBtnSize = UDim2.fromScale(0.62, 0.30)
	local indexBtn = Instance.new("TextButton")
	indexBtn.Name = "IndexBtn"
	indexBtn.Size = indexBtnSize
	indexBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	indexBtn.Position = UDim2.fromScale(0.31, 0.53)
	indexBtn.BackgroundColor3 = Color3.fromRGB(65, 175, 255)
	indexBtn.AutoButtonColor = false
	indexBtn.Text = ""
	indexBtn.Parent = leftGrid
	addCorner(indexBtn, 8)
	addStroke(indexBtn, Color3.fromRGB(14, 28, 48), 2.8)

	local indexGrad = Instance.new("UIGradient")
	indexGrad.Rotation = 90
	indexGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(105, 205, 255)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(35, 128, 235)),
	})
	indexGrad.Parent = indexBtn

	local bookIcon = Instance.new("Frame")
	bookIcon.Name = "Icon"
	bookIcon.Size = UDim2.fromScale(0.28, 0.72)
	bookIcon.Position = UDim2.fromScale(0.07, 0.14)
	bookIcon.BackgroundColor3 = Color3.fromRGB(28, 95, 210)
	bookIcon.Parent = indexBtn
	addCorner(bookIcon, 4)
	addStroke(bookIcon, Color3.fromRGB(14, 24, 42), 2.0)

	local bookSpine = Instance.new("Frame")
	bookSpine.Name = "Spine"
	bookSpine.Size = UDim2.fromScale(0.24, 1.0)
	bookSpine.Position = UDim2.fromScale(0, 0)
	bookSpine.BackgroundColor3 = Color3.fromRGB(85, 175, 255)
	bookSpine.BorderSizePixel = 0
	bookSpine.Parent = bookIcon
	addCorner(bookSpine, 3)

	local bookPages = Instance.new("Frame")
	bookPages.Name = "Pages"
	bookPages.Size = UDim2.fromScale(0.72, 0.22)
	bookPages.Position = UDim2.fromScale(0.22, 0.72)
	bookPages.BackgroundColor3 = Color3.fromRGB(245, 248, 255)
	bookPages.BorderSizePixel = 0
	bookPages.Parent = bookIcon
	addCorner(bookPages, 2)

	local indexCap = Instance.new("TextLabel")
	indexCap.Name = "Caption"
	indexCap.Size = UDim2.fromScale(0.58, 0.76)
	indexCap.Position = UDim2.fromScale(0.37, 0.12)
	indexCap.BackgroundTransparency = 1
	indexCap.Font = Enum.Font.FredokaOne
	indexCap.TextColor3 = Color3.fromRGB(255, 255, 255)
	indexCap.Text = "<b>Index</b>"
	indexCap.Parent = indexBtn
	addTextSizeConstraint(indexCap, 11, 22)
	addTextStroke(indexCap, Color3.fromRGB(12, 16, 26), 2.5)
	bindHoverAndClickTween(indexBtn, indexBtnSize, Color3.fromRGB(65, 175, 255))

	-- Row 2 Right: Dark-Charcoal Daily Calendar Button (dailyBtn)
	local dailyBtnSize = UDim2.fromScale(0.30, 0.30)
	local dailyBtn = Instance.new("TextButton")
	dailyBtn.Name = "DailyBtn"
	dailyBtn.Size = dailyBtnSize
	dailyBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	dailyBtn.Position = UDim2.fromScale(0.81, 0.53)
	dailyBtn.BackgroundColor3 = Color3.fromRGB(58, 60, 68)
	dailyBtn.AutoButtonColor = false
	dailyBtn.Text = ""
	dailyBtn.Parent = leftGrid
	addCorner(dailyBtn, 8)
	addStroke(dailyBtn, Color3.fromRGB(18, 18, 24), 2.8)

	local calPage = Instance.new("Frame")
	calPage.Name = "Icon"
	calPage.Size = UDim2.fromScale(0.68, 0.54)
	calPage.Position = UDim2.fromScale(0.16, 0.08)
	calPage.BackgroundColor3 = Color3.fromRGB(238, 242, 248)
	calPage.ClipsDescendants = true
	calPage.Parent = dailyBtn
	addCorner(calPage, 4)
	addStroke(calPage, Color3.fromRGB(18, 18, 24), 1.8)

	local calHeader = Instance.new("Frame")
	calHeader.Name = "Header"
	calHeader.Size = UDim2.fromScale(1.0, 0.30)
	calHeader.Position = UDim2.fromScale(0, 0)
	calHeader.BackgroundColor3 = Color3.fromRGB(225, 55, 65)
	calHeader.BorderSizePixel = 0
	calHeader.Parent = calPage

	local calNum = Instance.new("TextLabel")
	calNum.Name = "DayNum"
	calNum.Size = UDim2.fromScale(1.0, 0.70)
	calNum.Position = UDim2.fromScale(0, 0.30)
	calNum.BackgroundTransparency = 1
	calNum.Font = Enum.Font.FredokaOne
	calNum.TextColor3 = Color3.fromRGB(24, 26, 34)
	calNum.Text = "<b>31</b>"
	calNum.Parent = calPage
	addTextSizeConstraint(calNum, 8, 15)

	local dailyCap = Instance.new("TextLabel")
	dailyCap.Name = "Caption"
	dailyCap.Size = UDim2.fromScale(0.92, 0.32)
	dailyCap.Position = UDim2.fromScale(0.04, 0.64)
	dailyCap.BackgroundTransparency = 1
	dailyCap.Font = Enum.Font.FredokaOne
	dailyCap.TextColor3 = Color3.fromRGB(255, 255, 255)
	dailyCap.Text = "<b>Daily</b>"
	dailyCap.Parent = dailyBtn
	addTextSizeConstraint(dailyCap, 8, 14)
	addTextStroke(dailyCap, Color3.fromRGB(12, 12, 18), 2.2)
	bindHoverAndClickTween(dailyBtn, dailyBtnSize, Color3.fromRGB(58, 60, 68))

	-- Row 3 under Daily: Compact Red SloMo: OFF Pill Button (sloMoBtn)
	local sloMoBtnSize = UDim2.fromScale(0.30, 0.14)
	local sloMoBtn = Instance.new("TextButton")
	sloMoBtn.Name = "SloMoBtn"
	sloMoBtn.Size = sloMoBtnSize
	sloMoBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	sloMoBtn.Position = UDim2.fromScale(0.81, 0.80)
	sloMoBtn.BackgroundColor3 = Color3.fromRGB(185, 42, 42)
	sloMoBtn.AutoButtonColor = false
	sloMoBtn.Font = Enum.Font.FredokaOne
	sloMoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	sloMoBtn.Text = "<b>SloMo: OFF</b>"
	sloMoBtn.Parent = leftGrid
	addCorner(sloMoBtn, 6)
	addStroke(sloMoBtn, Color3.fromRGB(24, 12, 12), 2.2)
	addTextSizeConstraint(sloMoBtn, 7, 12)
	addTextStroke(sloMoBtn, Color3.fromRGB(12, 12, 16), 2.0)

	local sloMoCap = Instance.new("TextLabel")
	sloMoCap.Name = "Caption"
	sloMoCap.Size = UDim2.fromScale(0.96, 0.90)
	sloMoCap.Position = UDim2.fromScale(0.02, 0.05)
	sloMoCap.BackgroundTransparency = 1
	sloMoCap.Font = Enum.Font.FredokaOne
	sloMoCap.TextColor3 = Color3.fromRGB(255, 255, 255)
	sloMoCap.Text = "<b>SloMo: OFF</b>"
	sloMoCap.Visible = false
	sloMoCap.Parent = sloMoBtn
	addTextSizeConstraint(sloMoCap, 7, 12)
	addTextStroke(sloMoCap, Color3.fromRGB(12, 12, 16), 2.0)
	sloMoCap:GetPropertyChangedSignal("Text"):Connect(function()
		sloMoBtn.Text = sloMoCap.Text
	end)
	bindHoverAndClickTween(sloMoBtn, sloMoBtnSize, Color3.fromRGB(185, 42, 42))

	-- Right Vertical Square Dock (Eggs, Pets, Rewards, Settings)
	local rightDock = Instance.new("Frame")
	rightDock.Name = "RightDock"
	rightDock.Size = UDim2.fromScale(0.056, 0.38)
	rightDock.Position = UDim2.new(0.988, 0, 0.52, 0)
	rightDock.AnchorPoint = Vector2.new(1, 0.5)
	rightDock.BackgroundTransparency = 1
	rightDock.Parent = screenGui
	addAspectRatio(rightDock, 0.24)

	local rightBtnSize = UDim2.fromScale(0.92, 0.22)
	local function makeRightDockSquareBtn(name: string, captionText: string, centerPos: UDim2): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = rightBtnSize
		btn.AnchorPoint = Vector2.new(0.5, 0.5)
		btn.Position = centerPos
		btn.BackgroundColor3 = Color3.fromRGB(54, 56, 62)
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.Parent = rightDock
		addCorner(btn, 10)
		addStroke(btn, Color3.fromRGB(18, 18, 22), 2.8)
		addAspectRatio(btn, 1.0)

		local innerFrame = Instance.new("Frame")
		innerFrame.Name = "InnerBorder"
		innerFrame.Size = UDim2.fromScale(0.90, 0.90)
		innerFrame.Position = UDim2.fromScale(0.05, 0.05)
		innerFrame.BackgroundTransparency = 1
		innerFrame.Parent = btn
		addCorner(innerFrame, 8)
		addStroke(innerFrame, Color3.fromRGB(150, 155, 168), 1.2)

		local cap = Instance.new("TextLabel")
		cap.Name = "Caption"
		cap.Size = UDim2.fromScale(0.94, 0.28)
		cap.Position = UDim2.fromScale(0.03, 0.69)
		cap.BackgroundTransparency = 1
		cap.Font = Enum.Font.FredokaOne
		cap.TextColor3 = Color3.fromRGB(255, 255, 255)
		cap.Text = "<b>" .. captionText .. "</b>"
		cap.ZIndex = 4
		cap.Parent = btn
		addTextSizeConstraint(cap, 8, 14)
		addTextStroke(cap, Color3.fromRGB(14, 14, 18), 2.2)

		bindHoverAndClickTween(btn, rightBtnSize, Color3.fromRGB(54, 56, 62))
		return btn
	end

	-- 1. Eggs Button (Custom 3D-shaded Cream/Tan Oval Egg icon)
	local eggsDockBtn = makeRightDockSquareBtn("EggsBtn", "Eggs", UDim2.fromScale(0.5, 0.12))
	do
		local eggShape = Instance.new("Frame")
		eggShape.Name = "Icon"
		eggShape.Size = UDim2.fromScale(0.46, 0.56)
		eggShape.Position = UDim2.fromScale(0.27, 0.11)
		eggShape.BackgroundColor3 = Color3.fromRGB(242, 222, 192)
		eggShape.Parent = eggsDockBtn
		local eggCorner = Instance.new("UICorner")
		eggCorner.CornerRadius = UDim.new(0.5, 0)
		eggCorner.Parent = eggShape
		addStroke(eggShape, Color3.fromRGB(22, 18, 14), 2.0)

		local eggGrad = Instance.new("UIGradient")
		eggGrad.Rotation = 125
		eggGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 248, 235)),
			ColorSequenceKeypoint.new(0.65, Color3.fromRGB(238, 214, 180)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(198, 168, 132)),
		})
		eggGrad.Parent = eggShape

		local spot1 = Instance.new("Frame")
		spot1.Size = UDim2.fromScale(0.26, 0.22)
		spot1.Position = UDim2.fromScale(0.22, 0.20)
		spot1.BackgroundColor3 = Color3.fromRGB(255, 250, 242)
		spot1.BackgroundTransparency = 0.2
		spot1.BorderSizePixel = 0
		spot1.Parent = eggShape
		addCorner(spot1, 99)

		local spot2 = Instance.new("Frame")
		spot2.Size = UDim2.fromScale(0.16, 0.14)
		spot2.Position = UDim2.fromScale(0.54, 0.42)
		spot2.BackgroundColor3 = Color3.fromRGB(224, 195, 158)
		spot2.BackgroundTransparency = 0.25
		spot2.BorderSizePixel = 0
		spot2.Parent = eggShape
		addCorner(spot2, 99)
	end

	-- 2. Pets Button (vipBtn -> Name = "PetsBtn", Caption = "Pets", Custom Dark Paw Print icon)
	local vipBtn = makeRightDockSquareBtn("PetsBtn", "Pets", UDim2.fromScale(0.5, 0.37))
	do
		local pawContainer = Instance.new("Frame")
		pawContainer.Name = "Icon"
		pawContainer.Size = UDim2.fromScale(0.62, 0.56)
		pawContainer.Position = UDim2.fromScale(0.19, 0.11)
		pawContainer.BackgroundTransparency = 1
		pawContainer.Parent = vipBtn

		local palmPad = Instance.new("Frame")
		palmPad.Name = "PalmPad"
		palmPad.Size = UDim2.fromScale(0.52, 0.46)
		palmPad.Position = UDim2.fromScale(0.24, 0.46)
		palmPad.BackgroundColor3 = Color3.fromRGB(28, 30, 34)
		palmPad.Parent = pawContainer
		addCorner(palmPad, 99)
		addStroke(palmPad, Color3.fromRGB(185, 192, 205), 1.5)

		local toeCoords = {
			{ X = 0.06, Y = 0.24, Rot = -22 },
			{ X = 0.28, Y = 0.06, Rot = -8 },
			{ X = 0.52, Y = 0.06, Rot = 8 },
			{ X = 0.74, Y = 0.24, Rot = 22 },
		}
		for tIdx, tc in ipairs(toeCoords) do
			local toe = Instance.new("Frame")
			toe.Name = "Toe" .. tostring(tIdx)
			toe.Size = UDim2.fromScale(0.20, 0.28)
			toe.Position = UDim2.fromScale(tc.X, tc.Y)
			toe.Rotation = tc.Rot
			toe.BackgroundColor3 = Color3.fromRGB(28, 30, 34)
			toe.Parent = pawContainer
			addCorner(toe, 99)
			addStroke(toe, Color3.fromRGB(185, 192, 205), 1.3)
		end
	end

	-- 3. Rewards Button (wheelBtn -> Name = "RewardsBtn", Caption = "Rewards", Custom Purple & Gold Gift Box icon)
	local wheelBtn = makeRightDockSquareBtn("RewardsBtn", "Rewards", UDim2.fromScale(0.5, 0.62))
	do
		local giftHolder = Instance.new("Frame")
		giftHolder.Name = "Icon"
		giftHolder.Size = UDim2.fromScale(0.58, 0.56)
		giftHolder.Position = UDim2.fromScale(0.21, 0.11)
		giftHolder.BackgroundTransparency = 1
		giftHolder.Parent = wheelBtn

		local bowLeft = Instance.new("Frame")
		bowLeft.Size = UDim2.fromScale(0.28, 0.22)
		bowLeft.Position = UDim2.fromScale(0.22, 0.04)
		bowLeft.Rotation = -20
		bowLeft.BackgroundColor3 = Color3.fromRGB(255, 195, 45)
		bowLeft.Parent = giftHolder
		addCorner(bowLeft, 99)
		addStroke(bowLeft, Color3.fromRGB(22, 16, 12), 1.4)

		local bowRight = Instance.new("Frame")
		bowRight.Size = UDim2.fromScale(0.28, 0.22)
		bowRight.Position = UDim2.fromScale(0.50, 0.04)
		bowRight.Rotation = 20
		bowRight.BackgroundColor3 = Color3.fromRGB(255, 195, 45)
		bowRight.Parent = giftHolder
		addCorner(bowRight, 99)
		addStroke(bowRight, Color3.fromRGB(22, 16, 12), 1.4)

		local giftBox = Instance.new("Frame")
		giftBox.Name = "BoxBase"
		giftBox.Size = UDim2.fromScale(0.76, 0.56)
		giftBox.Position = UDim2.fromScale(0.12, 0.38)
		giftBox.BackgroundColor3 = Color3.fromRGB(138, 65, 225)
		giftBox.Parent = giftHolder
		addCorner(giftBox, 4)
		addStroke(giftBox, Color3.fromRGB(22, 14, 32), 1.8)

		local hRibbon = Instance.new("Frame")
		hRibbon.Size = UDim2.fromScale(1.0, 0.24)
		hRibbon.Position = UDim2.fromScale(0, 0.38)
		hRibbon.BackgroundColor3 = Color3.fromRGB(255, 195, 45)
		hRibbon.BorderSizePixel = 0
		hRibbon.Parent = giftBox

		local giftLid = Instance.new("Frame")
		giftLid.Name = "BoxLid"
		giftLid.Size = UDim2.fromScale(0.86, 0.22)
		giftLid.Position = UDim2.fromScale(0.07, 0.22)
		giftLid.BackgroundColor3 = Color3.fromRGB(155, 82, 242)
		giftLid.Parent = giftHolder
		addCorner(giftLid, 3)
		addStroke(giftLid, Color3.fromRGB(22, 14, 32), 1.8)

		local vRibbon = Instance.new("Frame")
		vRibbon.Size = UDim2.fromScale(0.20, 0.72)
		vRibbon.Position = UDim2.fromScale(0.40, 0.22)
		vRibbon.BackgroundColor3 = Color3.fromRGB(255, 195, 45)
		vRibbon.BorderSizePixel = 0
		vRibbon.ZIndex = 3
		vRibbon.Parent = giftHolder
	end

	-- 4. Settings Button (settingsProBtn -> Name = "SettingsProBtn", Caption = "Settings", Custom Silver-Grey Gear Cog icon)
	local settingsProBtn = makeRightDockSquareBtn("SettingsProBtn", "Settings", UDim2.fromScale(0.5, 0.87))
	do
		local gearHolder = Instance.new("Frame")
		gearHolder.Name = "Icon"
		gearHolder.Size = UDim2.fromScale(0.56, 0.56)
		gearHolder.Position = UDim2.fromScale(0.22, 0.11)
		gearHolder.BackgroundTransparency = 1
		gearHolder.Parent = settingsProBtn

		for _, deg in ipairs({ 0, 45, 90, 135 }) do
			local tooth = Instance.new("Frame")
			tooth.Name = "Tooth_" .. tostring(deg)
			tooth.Size = UDim2.fromScale(0.28, 0.96)
			tooth.AnchorPoint = Vector2.new(0.5, 0.5)
			tooth.Position = UDim2.fromScale(0.5, 0.5)
			tooth.Rotation = deg
			tooth.BackgroundColor3 = Color3.fromRGB(185, 192, 205)
			tooth.Parent = gearHolder
			addCorner(tooth, 3)
			addStroke(tooth, Color3.fromRGB(20, 22, 28), 1.5)
		end

		local gearDisk = Instance.new("Frame")
		gearDisk.Name = "GearDisk"
		gearDisk.Size = UDim2.fromScale(0.72, 0.72)
		gearDisk.AnchorPoint = Vector2.new(0.5, 0.5)
		gearDisk.Position = UDim2.fromScale(0.5, 0.5)
		gearDisk.BackgroundColor3 = Color3.fromRGB(185, 192, 205)
		gearDisk.ZIndex = 2
		gearDisk.Parent = gearHolder
		addCorner(gearDisk, 99)
		addStroke(gearDisk, Color3.fromRGB(20, 22, 28), 1.6)

		local gearHole = Instance.new("Frame")
		gearHole.Name = "CenterHole"
		gearHole.Size = UDim2.fromScale(0.34, 0.34)
		gearHole.AnchorPoint = Vector2.new(0.5, 0.5)
		gearHole.Position = UDim2.fromScale(0.5, 0.5)
		gearHole.BackgroundColor3 = Color3.fromRGB(54, 56, 62)
		gearHole.ZIndex = 3
		gearHole.Parent = gearHolder
		addCorner(gearHole, 99)
		addStroke(gearHole, Color3.fromRGB(20, 22, 28), 1.6)
	end

	-- Hidden dummy buttons for removed speedDockBtn and rebirthDockBtn
	local speedDockBtn = Instance.new("TextButton")
	speedDockBtn.Name = "SpeedBtn"
	speedDockBtn.Visible = false
	speedDockBtn.Selectable = false

	local rebirthDockBtn = Instance.new("TextButton")
	rebirthDockBtn.Name = "RebirthDockBtn"
	rebirthDockBtn.Visible = false
	rebirthDockBtn.Selectable = false

	-- =========================================================================
	-- 3. BOTTOM-LEFT CURRENCY DISPLAY (+ ON LEFT, BRIGHT GREEN $CASH ON RIGHT)
	-- =========================================================================
	local bottomLeftFrame = Instance.new("Frame")
	bottomLeftFrame.Name = "BottomLeftStats"
	bottomLeftFrame.Size = UDim2.fromScale(0.22, 0.065)
	bottomLeftFrame.Position = UDim2.new(0.012, 0, 0.985, 0)
	bottomLeftFrame.AnchorPoint = Vector2.new(0, 1)
	bottomLeftFrame.BackgroundTransparency = 1
	bottomLeftFrame.Parent = screenGui

	local speedCounterLbl = Instance.new("TextLabel")
	speedCounterLbl.Name = "SpeedCounter"
	speedCounterLbl.Visible = false

	local speedPlusBtn = Instance.new("TextButton")
	speedPlusBtn.Name = "SpeedPlusBtn"
	speedPlusBtn.Visible = false
	speedPlusBtn.Selectable = false

	local plusBtnSize = UDim2.fromScale(0.18, 0.72)
	local cashPlusBtn = Instance.new("TextButton")
	cashPlusBtn.Name = "CashPlusBtn"
	cashPlusBtn.Size = plusBtnSize
	cashPlusBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	cashPlusBtn.Position = UDim2.fromScale(0.09, 0.50)
	cashPlusBtn.BackgroundColor3 = Color3.fromRGB(115, 215, 68)
	cashPlusBtn.AutoButtonColor = false
	cashPlusBtn.Font = Enum.Font.FredokaOne
	cashPlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cashPlusBtn.Text = "<b>+</b>"
	cashPlusBtn.Parent = bottomLeftFrame
	addCorner(cashPlusBtn, 6)
	addStroke(cashPlusBtn, Color3.fromRGB(18, 38, 14), 2.6)
	addAspectRatio(cashPlusBtn, 1.0)
	addTextSizeConstraint(cashPlusBtn, 14, 28)
	addTextStroke(cashPlusBtn, Color3.fromRGB(12, 24, 12), 2.0)
	bindHoverAndClickTween(cashPlusBtn, plusBtnSize, Color3.fromRGB(115, 215, 68))

	local cashCounterLbl = Instance.new("TextLabel")
	cashCounterLbl.Name = "CashCounter"
	cashCounterLbl.Size = UDim2.fromScale(0.77, 0.90)
	cashCounterLbl.Position = UDim2.fromScale(0.21, 0.05)
	cashCounterLbl.BackgroundTransparency = 1
	cashCounterLbl.Font = Enum.Font.FredokaOne
	cashCounterLbl.TextXAlignment = Enum.TextXAlignment.Left
	cashCounterLbl.TextColor3 = Color3.fromRGB(115, 238, 75)
	cashCounterLbl.Text = "<b>$100</b>"
	cashCounterLbl.Parent = bottomLeftFrame
	addTextSizeConstraint(cashCounterLbl, 18, 42)
	addTextStroke(cashCounterLbl, Color3.fromRGB(12, 24, 12), 3.2)

	-- Hidden WalkSpeed Control Selector
	local speedThrottleBar = Instance.new("Frame")
	speedThrottleBar.Name = "SpeedThrottleBar"
	speedThrottleBar.Visible = false
	local speedThrottleButtons: { [number]: TextButton } = {}

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
		UDim2.fromScale(0.065, 0.095),
		UDim2.fromScale(0.015, 0.015),
		Color3.fromRGB(115, 225, 255),
		Color3.fromRGB(255, 230, 85),
		"Squishy"
	)

	local indexTitle = Instance.new("TextLabel")
	indexTitle.Name = "IndexTitle"
	indexTitle.Size = UDim2.fromScale(0.54, 0.055)
	indexTitle.Position = UDim2.fromScale(0.095, 0.012)
	indexTitle.BackgroundTransparency = 1
	indexTitle.Font = Enum.Font.FredokaOne
	indexTitle.TextXAlignment = Enum.TextXAlignment.Left
	indexTitle.TextColor3 = Color3.fromRGB(255, 235, 95)
	indexTitle.Text = "📘 <b>3D BRAINROT & SQUISHY INDEX (0 / 117)</b>"
	indexTitle.Parent = indexModal
	addTextSizeConstraint(indexTitle, 13, 26)
	addTextStroke(indexTitle, Color3.fromRGB(12, 16, 28), 2.2)

	local buyHintIndexSize = UDim2.fromScale(0.26, 0.076)
	local buyHintIndexBtn = Instance.new("TextButton")
	buyHintIndexBtn.Name = "BuyHintIndexBtn"
	buyHintIndexBtn.Size = buyHintIndexSize
	buyHintIndexBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	buyHintIndexBtn.Position = UDim2.fromScale(0.785, 0.058)
	buyHintIndexBtn.BackgroundColor3 = Color3.fromRGB(45, 195, 255)
	buyHintIndexBtn.AutoButtonColor = false
	buyHintIndexBtn.Font = Enum.Font.FredokaOne
	buyHintIndexBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyHintIndexBtn.Text = "🔍 <b>BUY SQUISHY HINT ($500)</b>"
	buyHintIndexBtn.Parent = indexModal
	addCorner(buyHintIndexBtn, 10)
	addStroke(buyHintIndexBtn, Color3.fromRGB(255, 255, 255), 2.0)
	addTextSizeConstraint(buyHintIndexBtn, 10, 18)
	addTextStroke(buyHintIndexBtn, Color3.fromRGB(12, 24, 48), 1.8)
	bindHoverAndClickTween(buyHintIndexBtn, buyHintIndexSize, Color3.fromRGB(45, 195, 255))

	local indexHintLabel = Instance.new("TextLabel")
	indexHintLabel.Name = "IndexHintBox"
	indexHintLabel.Size = UDim2.fromScale(0.55, 0.042)
	indexHintLabel.Position = UDim2.fromScale(0.095, 0.068)
	indexHintLabel.BackgroundTransparency = 1
	indexHintLabel.Font = Enum.Font.GothamBold
	indexHintLabel.TextXAlignment = Enum.TextXAlignment.Left
	indexHintLabel.TextColor3 = Color3.fromRGB(165, 235, 255)
	indexHintLabel.Text = "💡 <b>Hover any card</b> for location hints • Complete 100% of any Stage for a <b>Stage Mastery Cash Jackpot!</b>"
	indexHintLabel.Parent = indexModal
	addTextSizeConstraint(indexHintLabel, 10, 18)

	local closeBtnSize = UDim2.fromScale(0.058, 0.082)
	local indexClose = Instance.new("TextButton")
	indexClose.Name = "CloseBtn"
	indexClose.Size = closeBtnSize
	indexClose.AnchorPoint = Vector2.new(0.5, 0.5)
	indexClose.Position = UDim2.fromScale(0.958, 0.060)
	indexClose.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
	indexClose.AutoButtonColor = false
	indexClose.Font = Enum.Font.FredokaOne
	indexClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	indexClose.Text = "<b>X</b>"
	indexClose.Parent = indexModal
	addCorner(indexClose, 10)
	addStroke(indexClose, Color3.fromRGB(255, 255, 255), 2.0)
	addTextSizeConstraint(indexClose, 14, 26)
	bindHoverAndClickTween(indexClose, closeBtnSize, Color3.fromRGB(235, 65, 75))

	local indexScroll = Instance.new("ScrollingFrame")
	indexScroll.Name = "IndexScroll"
	indexScroll.Size = UDim2.fromScale(0.96, 0.855)
	indexScroll.Position = UDim2.fromScale(0.02, 0.125)
	indexScroll.BackgroundTransparency = 1
	indexScroll.ScrollBarThickness = 10
	indexScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	indexScroll.CanvasSize = UDim2.fromScale(0, 0)
	indexScroll.Selectable = false
	indexScroll.Parent = indexModal

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.318, 0, 0, 104)
	gridLayout.CellPadding = UDim2.new(0.016, 0, 0, 12)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = indexScroll

	local indexCards: { [string]: IndexCardEntry } = {}
	local cardViewportBaseSize = UDim2.fromScale(0.28, 0.80)
	local cardViewportHoverSize = UDim2.fromScale(0.31, 0.88)

	for idx, slime in ipairs(SlimeData.Slimes) do
		local anySlime = slime :: any
		local card = Instance.new("TextButton")
		card.Name = "SquishyCard_" .. tostring(idx)
		card.LayoutOrder = idx
		card.Text = ""
		card.AutoButtonColor = false
		card.Selectable = true
		card.BackgroundColor3 = Color3.fromRGB(32, 38, 64)
		card.Parent = indexScroll
		addCorner(card, 12)

		local pColor = anySlime.BodyColor or slime.Color or Color3.fromRGB(115, 225, 255)
		local aColor = anySlime.AccentColor or slime.SecondaryColor or Color3.fromRGB(255, 230, 85)
		local rarity = tostring(anySlime.Rarity or "Common")
		local isBossEgg = idx <= 35
		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = pColor
		cardStroke.Thickness = 2.2
		cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cardStroke.Parent = card

		-- Real 3D ViewportFrame inside every single card (#1–#117) that zooms & spins on hover!
		local cardVF = Instance.new("ViewportFrame")
		cardVF.Name = "SquishyViewport3D"
		cardVF.Size = cardViewportBaseSize
		cardVF.AnchorPoint = Vector2.new(0.5, 0.5)
		cardVF.Position = UDim2.fromScale(0.16, 0.50)
		cardVF.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
		cardVF.BackgroundTransparency = 0.08
		cardVF.Ambient = Color3.fromRGB(215, 222, 242)
		cardVF.LightColor = Color3.fromRGB(255, 255, 255)
		cardVF.LightDirection = Vector3.new(-1, -1.2, -1)
		cardVF.Active = false
		cardVF.Selectable = false
		cardVF.Parent = card
		addCorner(cardVF, 12)
		addStroke(cardVF, aColor, 2.0)

		local cardCam = Instance.new("Camera")
		cardCam.FieldOfView = 50
		cardCam.CFrame = CFrame.lookAt(Vector3.new(0, 0.85, 4.4), Vector3.new(0, 0.05, 0))
		cardCam.Parent = cardVF
		cardVF.CurrentCamera = cardCam

		local squishy3DModel, basePivot = build3DSquishyViewportModel(cardVF, pColor, aColor, isBossEgg, rarity, nil, slime)

		if not isBossEgg then
			local slimeIcon = Instance.new("ImageLabel")
			slimeIcon.Name = "CuteSlimePackIcon"
			slimeIcon.Size = UDim2.fromScale(0.42, 0.42)
			slimeIcon.Position = UDim2.fromScale(0.56, 0.56)
			slimeIcon.BackgroundTransparency = 1
			slimeIcon.Active = false
			slimeIcon.Selectable = false
			slimeIcon.Image = PrebuiltLoader.GetCuteSlimeIconId(idx)
			slimeIcon.Parent = cardVF
		end

		local hintDesc = if isBossEgg
			then string.format("Steal from Stage %d Sleeping Boss Nest & hatch in your Fenced Pen!", slime.Level)
			elseif idx <= 55 then string.format("Climb Stacked Wooden Crates & Plank Bridge onto House Roofs in Stage %d!", slime.Level)
			elseif idx <= 67 then "Climb the 28-Step Rainbow Disappearing Staircase on West Plaza!"
			elseif idx <= 87 then string.format("Explore the Flanking Outer Side Mazes outside Stage %d Castle Walls!", slime.Level)
			elseif idx <= 102 then string.format("Climb the Castle Wall Battlements & Watchtowers in Stage %d!", slime.Level)
			else string.format("Beat the Elevated Sky Obby Gauntlet in Stage %d!", slime.Level)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "NameLabel"
		nameLbl.Size = UDim2.fromScale(0.65, 0.52)
		nameLbl.Position = UDim2.fromScale(0.32, 0.06)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.FredokaOne
		nameLbl.TextWrapped = true
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.Text = string.format("<b>#%d %s</b>\n<font color='#A5E5FF'>[Stage %d • %s]</font>", idx, slime.Name, slime.Level, rarity)
		nameLbl.Active = false
		nameLbl.Selectable = false
		nameLbl.Parent = card
		addTextSizeConstraint(nameLbl, 11, 18)

		local statusLbl = Instance.new("TextLabel")
		statusLbl.Name = "StatusLabel"
		statusLbl.Size = UDim2.fromScale(0.65, 0.32)
		statusLbl.Position = UDim2.fromScale(0.32, 0.60)
		statusLbl.BackgroundTransparency = 1
		statusLbl.Font = Enum.Font.GothamBold
		statusLbl.TextXAlignment = Enum.TextXAlignment.Left
		statusLbl.TextColor3 = Color3.fromRGB(170, 180, 205)
		statusLbl.Text = string.format("🔒 <b>$%d/s</b>", anySlime.IncomePerSec or slime.CoinsPerSec or 10)
		statusLbl.Active = false
		statusLbl.Selectable = false
		statusLbl.Parent = card
		addTextSizeConstraint(statusLbl, 10, 16)

		local cardEntry: IndexCardEntry = {
			Frame = card,
			Status = statusLbl,
			Viewport = cardVF,
			Camera = cardCam,
			SquishyModel = squishy3DModel,
			BasePivot = basePivot,
		}
		indexCards[tostring(slime.Id)] = cardEntry

		local function onCardFocus()
			activeHoveredCard = cardEntry
			card.BackgroundColor3 = Color3.fromRGB(52, 64, 108)
			cardStroke.Color = Color3.fromRGB(255, 245, 95)
			cardStroke.Thickness = 3.5

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

			local rowIdx = math.floor((idx - 1) / 3)
			local targetY = math.max(0, rowIdx * 116 - 116)
			if math.abs(indexScroll.CanvasPosition.Y - targetY) > 180 then
				indexScroll.CanvasPosition = Vector2.new(0, targetY)
			end
		end

		local function onCardBlur()
			if activeHoveredCard == cardEntry then
				activeHoveredCard = nil
			end
			card.BackgroundColor3 = Color3.fromRGB(32, 38, 64)
			cardStroke.Color = pColor
			cardStroke.Thickness = 2.2
			TweenService:Create(cardVF, hoverTweenInfo, {
				Size = cardViewportBaseSize,
				BackgroundColor3 = Color3.fromRGB(16, 20, 36),
			}):Play()
			TweenService:Create(cardCam, camZoomTweenInfo, {
				FieldOfView = 50,
			}):Play()
			squishy3DModel:PivotTo(basePivot)
		end

		card.MouseEnter:Connect(onCardFocus)
		card.SelectionGained:Connect(onCardFocus)
		card.MouseLeave:Connect(onCardBlur)
		card.SelectionLost:Connect(onCardBlur)
	end

	-- Wire explicit 3-column grid NextSelection links across all 117 cards (#1..#117)
	for sIdx = 1, #SlimeData.Slimes do
		local sEntry = indexCards[tostring(SlimeData.Slimes[sIdx].Id)]
		if sEntry then
			local cBtn = sEntry.Frame
			if sIdx > 1 then
				local prevE = indexCards[tostring(SlimeData.Slimes[sIdx - 1].Id)]
				if prevE then
					cBtn.NextSelectionLeft = prevE.Frame
				end
			end
			if sIdx < #SlimeData.Slimes then
				local nextE = indexCards[tostring(SlimeData.Slimes[sIdx + 1].Id)]
				if nextE then
					cBtn.NextSelectionRight = nextE.Frame
				end
			end
			if sIdx > 3 then
				local upE = indexCards[tostring(SlimeData.Slimes[sIdx - 3].Id)]
				if upE then
					cBtn.NextSelectionUp = upE.Frame
				end
			else
				cBtn.NextSelectionUp = if sIdx == 3 then indexClose else buyHintIndexBtn
			end
			if sIdx + 3 <= #SlimeData.Slimes then
				local downE = indexCards[tostring(SlimeData.Slimes[sIdx + 3].Id)]
				if downE then
					cBtn.NextSelectionDown = downE.Frame
				end
			end
		end
	end

	local firstCard = indexCards[tostring(SlimeData.Slimes[1].Id)]
	if firstCard then
		activeHoveredCard = firstCard
		firstCard.Camera.FieldOfView = 50
	end
	buyHintIndexBtn.NextSelectionDown = if firstCard then firstCard.Frame else nil
	indexClose.NextSelectionDown = (indexCards["3"] and indexCards["3"].Frame) or (if firstCard then firstCard.Frame else nil)
	buyHintIndexBtn.NextSelectionRight = indexClose
	indexClose.NextSelectionLeft = buyHintIndexBtn

	-- =========================================================================
	-- 5. MODAL #2: 💎 FRONT-PAGE SIMULATOR SUPER SHOP (100% Scale-Responsive, Zero Empty Space, Hero VIP Banner, 2x2 Power Passes, 5 Treasure Boost Cards & Dual Upgrade Bar)
	-- =========================================================================
	local shopModal = Instance.new("Frame")
	shopModal.Name = "ShopModal"
	shopModal.Size = UDim2.fromScale(0.64, 0.72)
	shopModal.Position = UDim2.fromScale(0.5, 0.51)
	shopModal.AnchorPoint = Vector2.new(0.5, 0.5)
	shopModal.BackgroundColor3 = Color3.fromRGB(22, 18, 46)
	shopModal.Visible = false
	shopModal.Parent = screenGui
	addCorner(shopModal, 20)
	addStroke(shopModal, Color3.fromRGB(255, 215, 65), 3.8)
	addAspectRatio(shopModal, 1.54)

	local shopBgGrad = Instance.new("UIGradient")
	shopBgGrad.Rotation = 135
	shopBgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(48, 28, 88)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(28, 32, 68)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(18, 22, 48)),
	})
	shopBgGrad.Parent = shopModal

	-- TOP HEADER BANNER (Y = 0.015 .. 0.110)
	local shopHeaderBanner = Instance.new("Frame")
	shopHeaderBanner.Name = "GlossyHeaderBanner"
	shopHeaderBanner.Size = UDim2.fromScale(0.97, 0.095)
	shopHeaderBanner.Position = UDim2.fromScale(0.015, 0.014)
	shopHeaderBanner.BackgroundColor3 = Color3.fromRGB(255, 165, 45)
	shopHeaderBanner.Parent = shopModal
	addCorner(shopHeaderBanner, 14)
	addStroke(shopHeaderBanner, Color3.fromRGB(255, 245, 145), 2.5)
	local shopBannerGrad = Instance.new("UIGradient")
	shopBannerGrad.Rotation = 0
	shopBannerGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 95, 185)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 175, 45)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(95, 215, 255)),
	})
	shopBannerGrad.Parent = shopHeaderBanner

	createFeaturedViewportPreview(
		shopHeaderBanner,
		UDim2.fromScale(0.062, 0.84),
		UDim2.fromScale(0.010, 0.08),
		Color3.fromRGB(255, 215, 55),
		Color3.fromRGB(255, 255, 255),
		"Crown"
	)

	local shopTitle = Instance.new("TextLabel")
	shopTitle.Size = UDim2.fromScale(0.82, 0.86)
	shopTitle.Position = UDim2.fromScale(0.082, 0.07)
	shopTitle.BackgroundTransparency = 1
	shopTitle.Font = Enum.Font.FredokaOne
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopTitle.Text = "💎 <b>SUPER SQUISHY SHOP — VIP BUNDLES, PASSES & MEGA BOOSTS!</b> ✨"
	shopTitle.Parent = shopHeaderBanner
	addTextSizeConstraint(shopTitle, 14, 30)
	addTextStroke(shopTitle, Color3.fromRGB(18, 12, 38), 2.8)

	local shopClose = Instance.new("TextButton")
	local shopCloseSize = UDim2.fromScale(0.055, 0.80)
	shopClose.Size = shopCloseSize
	shopClose.AnchorPoint = Vector2.new(0.5, 0.5)
	shopClose.Position = UDim2.fromScale(0.964, 0.50)
	shopClose.BackgroundColor3 = Color3.fromRGB(245, 55, 75)
	shopClose.AutoButtonColor = false
	shopClose.Font = Enum.Font.FredokaOne
	shopClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopClose.Text = "<b>X</b>"
	shopClose.Parent = shopHeaderBanner
	addCorner(shopClose, 10)
	addStroke(shopClose, Color3.fromRGB(255, 255, 255), 2.2)
	addTextSizeConstraint(shopClose, 14, 26)
	bindHoverAndClickTween(shopClose, shopCloseSize, Color3.fromRGB(245, 55, 75))

	local passButtonsByKey: { [string]: TextButton } = {}

	-- =========================================================================
	-- TIER 1: FEATURED VIP SUPREME KING HERO BANNER (Y = 0.122 .. 0.328)
	-- =========================================================================
	local vipHeroCard = Instance.new("Frame")
	vipHeroCard.Name = "GamepassCard_VIP"
	vipHeroCard.Size = UDim2.fromScale(0.97, 0.202)
	vipHeroCard.Position = UDim2.fromScale(0.015, 0.122)
	vipHeroCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	vipHeroCard.Parent = shopModal
	addCorner(vipHeroCard, 16)
	addStroke(vipHeroCard, Color3.fromRGB(255, 235, 85), 3.2)

	local vipHeroGrad = Instance.new("UIGradient")
	vipHeroGrad.Rotation = 15
	vipHeroGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(165, 35, 195)),
		ColorSequenceKeypoint.new(0.52, Color3.fromRGB(235, 65, 155)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 165, 35)),
	})
	vipHeroGrad.Parent = vipHeroCard

	-- Left 3D Golden King Squishy Showcase inside VIP Hero Card
	local vipVF = Instance.new("ViewportFrame")
	vipVF.Name = "GamepassViewport3D"
	vipVF.Size = UDim2.fromScale(0.135, 0.84)
	vipVF.Position = UDim2.fromScale(0.012, 0.08)
	vipVF.BackgroundColor3 = Color3.fromRGB(32, 16, 54)
	vipVF.Ambient = Color3.fromRGB(235, 235, 255)
	vipVF.LightColor = Color3.fromRGB(255, 245, 185)
	vipVF.LightDirection = Vector3.new(-1, -1.2, -1)
	vipVF.Parent = vipHeroCard
	addCorner(vipVF, 14)
	addStroke(vipVF, Color3.fromRGB(255, 235, 85), 2.5)

	local vipCam = Instance.new("Camera")
	vipCam.FieldOfView = 44
	vipCam.CFrame = CFrame.lookAt(Vector3.new(0, 0.85, 4.2), Vector3.new(0, 0.08, 0))
	vipCam.Parent = vipVF
	vipVF.CurrentCamera = vipCam

	local vipModel, vipPivot = build3DSquishyViewportModel(
		vipVF,
		Color3.fromRGB(255, 205, 55),
		Color3.fromRGB(255, 95, 205),
		false,
		"Cosmic",
		"Crown"
	)
	table.insert(rotatingViewportModels, {
		Model = vipModel,
		BaseCFrame = vipPivot,
		Speed = 1.65,
	})

	local vipCrownBadge = Instance.new("TextLabel")
	vipCrownBadge.Size = UDim2.fromScale(0.92, 0.28)
	vipCrownBadge.Position = UDim2.fromScale(0.04, 0.70)
	vipCrownBadge.BackgroundColor3 = Color3.fromRGB(255, 215, 45)
	vipCrownBadge.Font = Enum.Font.FredokaOne
	vipCrownBadge.TextColor3 = Color3.fromRGB(28, 16, 42)
	vipCrownBadge.Text = "👑 <b>KING VIP</b>"
	vipCrownBadge.Parent = vipVF
	addCorner(vipCrownBadge, 6)
	addTextSizeConstraint(vipCrownBadge, 8, 15)

	local vipBestTag = Instance.new("TextLabel")
	vipBestTag.Size = UDim2.fromScale(0.28, 0.22)
	vipBestTag.Position = UDim2.fromScale(0.16, 0.07)
	vipBestTag.BackgroundColor3 = Color3.fromRGB(255, 235, 65)
	vipBestTag.Font = Enum.Font.FredokaOne
	vipBestTag.TextColor3 = Color3.fromRGB(32, 14, 48)
	vipBestTag.Text = "🔥 <b>BEST VALUE • LIMITED BUNDLE!</b>"
	vipBestTag.Parent = vipHeroCard
	addCorner(vipBestTag, 8)
	addStroke(vipBestTag, Color3.fromRGB(255, 255, 255), 1.5)
	addTextSizeConstraint(vipBestTag, 9, 16)

	local vipTitleLbl = Instance.new("TextLabel")
	vipTitleLbl.Size = UDim2.fromScale(0.55, 0.34)
	vipTitleLbl.Position = UDim2.fromScale(0.16, 0.31)
	vipTitleLbl.BackgroundTransparency = 1
	vipTitleLbl.Font = Enum.Font.FredokaOne
	vipTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
	vipTitleLbl.TextColor3 = Color3.fromRGB(255, 248, 145)
	vipTitleLbl.Text = "👑 <b>ULTIMATE VIP KING PASS + RAINBOW TRAIL!</b>"
	vipTitleLbl.Parent = vipHeroCard
	addTextSizeConstraint(vipTitleLbl, 13, 28)
	addTextStroke(vipTitleLbl, Color3.fromRGB(24, 10, 42), 2.5)

	local vipPerksLbl = Instance.new("TextLabel")
	vipPerksLbl.Size = UDim2.fromScale(0.56, 0.26)
	vipPerksLbl.Position = UDim2.fromScale(0.16, 0.66)
	vipPerksLbl.BackgroundTransparency = 1
	vipPerksLbl.Font = Enum.Font.FredokaOne
	vipPerksLbl.TextXAlignment = Enum.TextXAlignment.Left
	vipPerksLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	vipPerksLbl.Text = "✅ <b>+50% CASH FOREVER</b>   •   👑 <b>GOLDEN CROWN</b>   •   🌈 <b>RAINBOW SPEED TRAIL</b>"
	vipPerksLbl.Parent = vipHeroCard
	addTextSizeConstraint(vipPerksLbl, 10, 19)
	addTextStroke(vipPerksLbl, Color3.fromRGB(20, 10, 36), 1.8)

	local vipBuySize = UDim2.fromScale(0.235, 0.72)
	local vipBuyBtn = Instance.new("TextButton")
	vipBuyBtn.Name = "BuyVIPBtn"
	vipBuyBtn.Size = vipBuySize
	vipBuyBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	vipBuyBtn.Position = UDim2.fromScale(0.865, 0.50)
	vipBuyBtn.BackgroundColor3 = Color3.fromRGB(65, 238, 105)
	vipBuyBtn.AutoButtonColor = false
	vipBuyBtn.Font = Enum.Font.FredokaOne
	vipBuyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	vipBuyBtn.Text = "🟢 <b>BUY VIP PASS\n$20K / 399 R$</b>"
	vipBuyBtn.Parent = vipHeroCard
	addCorner(vipBuyBtn, 14)
	addStroke(vipBuyBtn, Color3.fromRGB(255, 255, 255), 2.8)
	addTextSizeConstraint(vipBuyBtn, 12, 24)
	addTextStroke(vipBuyBtn, Color3.fromRGB(12, 48, 22), 2.2)
	bindHoverAndClickTween(vipBuyBtn, vipBuySize, Color3.fromRGB(65, 238, 105))
	passButtonsByKey["VIP"] = vipBuyBtn

	-- =========================================================================
	-- TIER 2: 3 FOREVER GAMEPASS POWER CARDS IN A RESPONSIVE GRID (Y = 0.338 .. 0.642)
	-- =========================================================================
	local gridGamepasses = {
		{
			Key = "2xCash",
			Ribbon = "🔥 MOST POPULAR!",
			EmojiBadge = "💰x2",
			Title = "💰 2x CASH FOREVER",
			Desc = "Doubles ALL Roaming Squishy $/sec & Pickup Cash Forever!",
			Price = "$7.5K / 199 R$",
			ColorTop = Color3.fromRGB(245, 165, 25),
			ColorBot = Color3.fromRGB(165, 95, 15),
			StrokeColor = Color3.fromRGB(255, 235, 95),
			BodyCol = Color3.fromRGB(255, 215, 55),
			AccCol = Color3.fromRGB(95, 255, 135),
			IsEgg = false,
			Pos = UDim2.fromScale(0.015, 0.338),
			Size = UDim2.fromScale(0.479, 0.144),
		},
		{
			Key = "AutoHatch",
			Ribbon = "🐣 ZERO WAIT!",
			EmojiBadge = "🐣1s",
			Title = "🥚 INSTANT 1s HATCH",
			Desc = "Hatches ALL Stolen Boss Eggs in 1 Second Inside Your Fence!",
			Price = "$12.5K / 249 R$",
			ColorTop = Color3.fromRGB(175, 55, 235),
			ColorBot = Color3.fromRGB(98, 28, 158),
			StrokeColor = Color3.fromRGB(235, 155, 255),
			BodyCol = Color3.fromRGB(205, 105, 255),
			AccCol = Color3.fromRGB(255, 235, 95),
			IsEgg = true,
			Pos = UDim2.fromScale(0.506, 0.338),
			Size = UDim2.fromScale(0.479, 0.144),
		},
		{
			Key = "Carry2Eggs",
			Ribbon = "🥚 DOUBLE STEAL!",
			EmojiBadge = "🎒+2",
			Title = "🎒 +2 EGG CARRY CAPACITY",
			Desc = "Carry 2 Boss Eggs at Once From Any Stage Back to Your Ranch!",
			Price = "$3.5K / 299 R$",
			ColorTop = Color3.fromRGB(35, 195, 115),
			ColorBot = Color3.fromRGB(18, 115, 68),
			StrokeColor = Color3.fromRGB(125, 255, 175),
			BodyCol = Color3.fromRGB(85, 245, 145),
			AccCol = Color3.fromRGB(255, 225, 75),
			IsEgg = true,
			Pos = UDim2.fromScale(0.015, 0.494),
			Size = UDim2.fromScale(0.970, 0.144),
		},
	}

	for _, gp in ipairs(gridGamepasses) do
		local card = Instance.new("Frame")
		card.Name = "GamepassCard_" .. gp.Key
		card.Size = gp.Size or UDim2.fromScale(0.479, 0.144)
		card.Position = gp.Pos
		card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		card.Parent = shopModal
		addCorner(card, 14)
		addStroke(card, gp.StrokeColor, 2.6)

		local cardGrad = Instance.new("UIGradient")
		cardGrad.Rotation = 90
		cardGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, gp.ColorTop),
			ColorSequenceKeypoint.new(1.0, gp.ColorBot),
		})
		cardGrad.Parent = card

		-- 3D ViewportFrame preview on each Gamepass Card!
		local gpVF = Instance.new("ViewportFrame")
		gpVF.Name = "GamepassViewport3D"
		gpVF.Size = UDim2.fromScale(0.20, 0.84)
		gpVF.Position = UDim2.fromScale(0.02, 0.08)
		gpVF.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
		gpVF.Ambient = Color3.fromRGB(225, 232, 250)
		gpVF.LightColor = Color3.fromRGB(255, 255, 255)
		gpVF.LightDirection = Vector3.new(-1, -1.2, -1)
		gpVF.Parent = card
		addCorner(gpVF, 12)
		addStroke(gpVF, gp.StrokeColor, 2.2)

		local gpCam = Instance.new("Camera")
		gpCam.FieldOfView = 46
		gpCam.CFrame = CFrame.lookAt(Vector3.new(0, 0.85, 4.3), Vector3.new(0, 0.05, 0))
		gpCam.Parent = gpVF
		gpVF.CurrentCamera = gpCam

		local gpModel, gpPivot = build3DSquishyViewportModel(gpVF, gp.BodyCol, gp.AccCol, gp.IsEgg, "Mythic", "Crown")
		table.insert(rotatingViewportModels, {
			Model = gpModel,
			BaseCFrame = gpPivot,
			Speed = 1.45,
		})

		local emojiTag = Instance.new("TextLabel")
		emojiTag.Size = UDim2.fromScale(0.90, 0.30)
		emojiTag.Position = UDim2.fromScale(0.05, 0.66)
		emojiTag.BackgroundColor3 = gp.StrokeColor
		emojiTag.Font = Enum.Font.FredokaOne
		emojiTag.TextColor3 = Color3.fromRGB(18, 20, 34)
		emojiTag.Text = "<b>" .. gp.EmojiBadge .. "</b>"
		emojiTag.Parent = gpVF
		addCorner(emojiTag, 6)
		addTextSizeConstraint(emojiTag, 8, 15)

		local ribbonLbl = Instance.new("TextLabel")
		ribbonLbl.Size = UDim2.fromScale(0.42, 0.22)
		ribbonLbl.Position = UDim2.fromScale(0.24, 0.06)
		ribbonLbl.BackgroundColor3 = Color3.fromRGB(255, 235, 75)
		ribbonLbl.Font = Enum.Font.FredokaOne
		ribbonLbl.TextColor3 = Color3.fromRGB(24, 16, 38)
		ribbonLbl.Text = "<b>" .. gp.Ribbon .. "</b>"
		ribbonLbl.Parent = card
		addCorner(ribbonLbl, 6)
		addTextSizeConstraint(ribbonLbl, 8, 14)

		local tLbl = Instance.new("TextLabel")
		tLbl.Size = UDim2.fromScale(0.46, 0.32)
		tLbl.Position = UDim2.fromScale(0.24, 0.29)
		tLbl.BackgroundTransparency = 1
		tLbl.Font = Enum.Font.FredokaOne
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		tLbl.Text = "<b>" .. gp.Title .. "</b>"
		tLbl.Parent = card
		addTextSizeConstraint(tLbl, 11, 22)
		addTextStroke(tLbl, Color3.fromRGB(14, 16, 32), 2.2)

		local dLbl = Instance.new("TextLabel")
		dLbl.Size = UDim2.fromScale(0.46, 0.32)
		dLbl.Position = UDim2.fromScale(0.24, 0.61)
		dLbl.BackgroundTransparency = 1
		dLbl.Font = Enum.Font.GothamBold
		dLbl.TextWrapped = true
		dLbl.TextXAlignment = Enum.TextXAlignment.Left
		dLbl.TextColor3 = Color3.fromRGB(245, 248, 255)
		dLbl.Text = gp.Desc
		dLbl.Parent = card
		addTextSizeConstraint(dLbl, 9, 15)
		addTextStroke(dLbl, Color3.fromRGB(14, 16, 32), 1.4)

		local buyBtn = Instance.new("TextButton")
		local buySize = UDim2.fromScale(0.26, 0.72)
		buyBtn.Size = buySize
		buyBtn.AnchorPoint = Vector2.new(0.5, 0.5)
		buyBtn.Position = UDim2.fromScale(0.85, 0.50)
		buyBtn.BackgroundColor3 = Color3.fromRGB(65, 238, 105)
		buyBtn.AutoButtonColor = false
		buyBtn.Font = Enum.Font.FredokaOne
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Text = "🟢 <b>BUY\n" .. gp.Price .. "</b>"
		buyBtn.Parent = card
		addCorner(buyBtn, 12)
		addStroke(buyBtn, Color3.fromRGB(255, 255, 255), 2.4)
		addTextSizeConstraint(buyBtn, 11, 20)
		addTextStroke(buyBtn, Color3.fromRGB(12, 48, 22), 2.0)
		bindHoverAndClickTween(buyBtn, buySize, Color3.fromRGB(65, 238, 105))
		passButtonsByKey[gp.Key] = buyBtn
	end

	-- =========================================================================
	-- TIER 3: 6 TREASURE & INSTANT POWER-UP CARDS (Y = 0.650 .. 0.858)
	-- =========================================================================
	local devProducts = {
		{
			Key = "InstantHatchAll",
			Tag = "⚡ INSTANT!",
			Icon = "🐣⚡",
			Title = "HATCH ALL EGGS",
			Sub = "Skip All Timers!",
			Price = "$500 / 29 R$",
			ColTop = Color3.fromRGB(195, 75, 255),
			ColBot = Color3.fromRGB(105, 28, 165),
			Stroke = Color3.fromRGB(235, 165, 255),
		},
		{
			Key = "BossShield60s",
			Tag = "🛡️ IMMORTAL!",
			Icon = "🛡️✨",
			Title = "60s BOSS SHIELD",
			Sub = "Bosses Can't Hit!",
			Price = "$750 / 39 R$",
			ColTop = Color3.fromRGB(45, 185, 255),
			ColBot = Color3.fromRGB(22, 95, 175),
			Stroke = Color3.fromRGB(135, 235, 255),
		},
		{
			Key = "LuckyEggRoll",
			Tag = "🥚 GUARANTEED!",
			Icon = "🥚✨",
			Title = "INSTANT STAGE EGG",
			Sub = "100% Guaranteed Unlock!",
			Price = "$1.5K / 79 R$",
			ColTop = Color3.fromRGB(45, 215, 115),
			ColBot = Color3.fromRGB(18, 118, 58),
			Stroke = Color3.fromRGB(145, 255, 185),
		},
		{
			Key = "CashPack5K",
			Tag = "💵 STARTER",
			Icon = "💵💰",
			Title = "+$5,000 CASH",
			Sub = "Instant Coins!",
			Price = "FREE GIFT / 49 R$",
			ColTop = Color3.fromRGB(55, 205, 105),
			ColBot = Color3.fromRGB(24, 115, 55),
			Stroke = Color3.fromRGB(135, 255, 165),
		},
		{
			Key = "CashPack25K",
			Tag = "🔥 POPULAR!",
			Icon = "💰💎",
			Title = "+$25,000 CASH",
			Sub = "5x Huge Vault!",
			Price = "149 R$",
			ColTop = Color3.fromRGB(255, 175, 35),
			ColBot = Color3.fromRGB(175, 95, 15),
			Stroke = Color3.fromRGB(255, 235, 95),
		},
		{
			Key = "CashPack100K",
			Tag = "👑 JACKPOT!",
			Icon = "💎👑",
			Title = "+$100,000 CASH",
			Sub = "Mega Rich Chest!",
			Price = "399 R$",
			ColTop = Color3.fromRGB(255, 65, 175),
			ColBot = Color3.fromRGB(155, 22, 105),
			Stroke = Color3.fromRGB(255, 165, 225),
		},
	}

	local devProductButtons: { [string]: TextButton } = {}
	for idx, dp in ipairs(devProducts) do
		local xCenter = 0.092 + (idx - 1) * 0.1632
		local dpSize = UDim2.fromScale(0.154, 0.204)
		local dpBtn = Instance.new("TextButton")
		dpBtn.Name = "DevProduct_" .. dp.Key
		dpBtn.Size = dpSize
		dpBtn.AnchorPoint = Vector2.new(0.5, 0.5)
		dpBtn.Position = UDim2.fromScale(xCenter, 0.754)
		dpBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		dpBtn.AutoButtonColor = false
		dpBtn.Text = ""
		dpBtn.Parent = shopModal
		addCorner(dpBtn, 14)
		addStroke(dpBtn, dp.Stroke, 2.4)

		local dpGrad = Instance.new("UIGradient")
		dpGrad.Rotation = 90
		dpGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, dp.ColTop),
			ColorSequenceKeypoint.new(1.0, dp.ColBot),
		})
		dpGrad.Parent = dpBtn

		local topTag = Instance.new("TextLabel")
		topTag.Size = UDim2.fromScale(0.88, 0.19)
		topTag.Position = UDim2.fromScale(0.06, 0.05)
		topTag.BackgroundColor3 = Color3.fromRGB(255, 235, 75)
		topTag.Font = Enum.Font.FredokaOne
		topTag.TextColor3 = Color3.fromRGB(24, 16, 38)
		topTag.Text = "<b>" .. dp.Tag .. "</b>"
		topTag.Parent = dpBtn
		addCorner(topTag, 6)
		addTextSizeConstraint(topTag, 8, 14)

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.fromScale(0.90, 0.26)
		iconLbl.Position = UDim2.fromScale(0.05, 0.24)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font = Enum.Font.FredokaOne
		iconLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		iconLbl.Text = dp.Icon
		iconLbl.Parent = dpBtn
		addTextSizeConstraint(iconLbl, 14, 28)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.fromScale(0.92, 0.20)
		titleLbl.Position = UDim2.fromScale(0.04, 0.50)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.FredokaOne
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.Text = "<b>" .. dp.Title .. "</b>"
		titleLbl.Parent = dpBtn
		addTextSizeConstraint(titleLbl, 9, 17)
		addTextStroke(titleLbl, Color3.fromRGB(14, 16, 32), 2.0)

		local pricePill = Instance.new("TextLabel")
		pricePill.Name = "PricePill"
		pricePill.Size = UDim2.fromScale(0.88, 0.23)
		pricePill.Position = UDim2.fromScale(0.06, 0.72)
		pricePill.BackgroundColor3 = Color3.fromRGB(65, 238, 105)
		pricePill.Font = Enum.Font.FredokaOne
		pricePill.TextColor3 = Color3.fromRGB(255, 255, 255)
		pricePill.Text = "🟢 <b>" .. dp.Price .. "</b>"
		pricePill.Parent = dpBtn
		addCorner(pricePill, 8)
		addStroke(pricePill, Color3.fromRGB(255, 255, 255), 1.8)
		addTextSizeConstraint(pricePill, 9, 17)
		addTextStroke(pricePill, Color3.fromRGB(12, 48, 22), 1.8)

		bindHoverAndClickTween(dpBtn, dpSize, Color3.fromRGB(255, 255, 255))
		devProductButtons[dp.Key] = dpBtn
	end

	-- =========================================================================
	-- TIER 4: BOTTOM 3-BUTTON CASH SINK & UPGRADE BAR (FENCE + HINT + REBIRTH, Y = 0.870 .. 0.982)
	-- =========================================================================
	local powerBtnSize = UDim2.fromScale(0.31, 0.110)

	local buySpeedBtn = Instance.new("TextButton")
	buySpeedBtn.Name = "BuySpeedBtn"
	buySpeedBtn.Visible = false
	buySpeedBtn.Selectable = false

	local buyFenceBtn = Instance.new("TextButton")
	buyFenceBtn.Name = "BuyFenceBtn"
	buyFenceBtn.Size = powerBtnSize
	buyFenceBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	buyFenceBtn.Position = UDim2.fromScale(0.175, 0.926)
	buyFenceBtn.BackgroundColor3 = Color3.fromRGB(235, 155, 45)
	buyFenceBtn.AutoButtonColor = false
	buyFenceBtn.Font = Enum.Font.FredokaOne
	buyFenceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyFenceBtn.Text = "🧱 <b>Fence Size [Lv.2] - $500</b>"
	buyFenceBtn.Parent = shopModal
	addCorner(buyFenceBtn, 14)
	addStroke(buyFenceBtn, Color3.fromRGB(255, 255, 255), 2.4)
	addTextSizeConstraint(buyFenceBtn, 10, 20)
	addTextStroke(buyFenceBtn, Color3.fromRGB(38, 22, 8), 2.0)
	bindHoverAndClickTween(buyFenceBtn, powerBtnSize, Color3.fromRGB(235, 155, 45))

	local buyHintShopBtn = Instance.new("TextButton")
	buyHintShopBtn.Name = "BuyHintShopBtn"
	buyHintShopBtn.Size = powerBtnSize
	buyHintShopBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	buyHintShopBtn.Position = UDim2.fromScale(0.500, 0.926)
	buyHintShopBtn.BackgroundColor3 = Color3.fromRGB(55, 215, 135)
	buyHintShopBtn.AutoButtonColor = false
	buyHintShopBtn.Font = Enum.Font.FredokaOne
	buyHintShopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyHintShopBtn.Text = "🔍 <b>Squishy Hint - $500</b>"
	buyHintShopBtn.Parent = shopModal
	addCorner(buyHintShopBtn, 14)
	addStroke(buyHintShopBtn, Color3.fromRGB(255, 255, 255), 2.4)
	addTextSizeConstraint(buyHintShopBtn, 10, 20)
	addTextStroke(buyHintShopBtn, Color3.fromRGB(12, 38, 22), 2.0)
	bindHoverAndClickTween(buyHintShopBtn, powerBtnSize, Color3.fromRGB(55, 215, 135))

	local rebirthBtn = Instance.new("TextButton")
	rebirthBtn.Name = "RebirthBtn"
	rebirthBtn.Size = powerBtnSize
	rebirthBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	rebirthBtn.Position = UDim2.fromScale(0.825, 0.926)
	rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 95, 195)
	rebirthBtn.AutoButtonColor = false
	rebirthBtn.Font = Enum.Font.FredokaOne
	rebirthBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthBtn.Text = "🔥 <b>Rebirth #1 - $5,000</b>"
	rebirthBtn.Parent = shopModal
	addCorner(rebirthBtn, 14)
	addStroke(rebirthBtn, Color3.fromRGB(255, 235, 85), 2.4)
	addTextSizeConstraint(rebirthBtn, 10, 20)
	addTextStroke(rebirthBtn, Color3.fromRGB(38, 12, 32), 2.0)
	bindHoverAndClickTween(rebirthBtn, powerBtnSize, Color3.fromRGB(255, 95, 195))

	-- ShopModal Console NextSelection Wiring
	shopClose.NextSelectionDown = vipBuyBtn
	vipBuyBtn.NextSelectionUp = shopClose
	vipBuyBtn.NextSelectionDown = passButtonsByKey["2xCash"]

	if passButtonsByKey["2xCash"] and passButtonsByKey["AutoHatch"] and passButtonsByKey["Carry2Eggs"] then
		passButtonsByKey["2xCash"].NextSelectionUp = vipBuyBtn
		passButtonsByKey["2xCash"].NextSelectionRight = passButtonsByKey["AutoHatch"]
		passButtonsByKey["2xCash"].NextSelectionDown = passButtonsByKey["Carry2Eggs"]

		passButtonsByKey["AutoHatch"].NextSelectionUp = vipBuyBtn
		passButtonsByKey["AutoHatch"].NextSelectionLeft = passButtonsByKey["2xCash"]
		passButtonsByKey["AutoHatch"].NextSelectionDown = passButtonsByKey["Carry2Eggs"]

		passButtonsByKey["Carry2Eggs"].NextSelectionUp = passButtonsByKey["2xCash"]
		passButtonsByKey["Carry2Eggs"].NextSelectionDown = devProductButtons["InstantHatchAll"] or buyFenceBtn
	end

	local dpKeys = { "InstantHatchAll", "BossShield60s", "LuckyEggRoll", "CashPack5K", "CashPack25K", "CashPack100K" }
	for dIdx, dKey in ipairs(dpKeys) do
		local dpB = devProductButtons[dKey]
		if dpB then
			dpB.Selectable = true
			dpB.NextSelectionUp = passButtonsByKey["Carry2Eggs"]
			if dIdx > 1 and devProductButtons[dpKeys[dIdx - 1]] then
				dpB.NextSelectionLeft = devProductButtons[dpKeys[dIdx - 1]]
			end
			if dIdx < #dpKeys and devProductButtons[dpKeys[dIdx + 1]] then
				dpB.NextSelectionRight = devProductButtons[dpKeys[dIdx + 1]]
			end
			dpB.NextSelectionDown = if dIdx <= 2 then buyFenceBtn elseif dIdx <= 4 then buyHintShopBtn else rebirthBtn
		end
	end

	buyFenceBtn.NextSelectionRight = buyHintShopBtn
	buyHintShopBtn.NextSelectionLeft = buyFenceBtn
	buyHintShopBtn.NextSelectionRight = rebirthBtn
	rebirthBtn.NextSelectionLeft = buyHintShopBtn

	buyFenceBtn.NextSelectionUp = devProductButtons["BossShield60s"] or passButtonsByKey["Carry2Eggs"]
	buyHintShopBtn.NextSelectionUp = devProductButtons["LuckyEggRoll"] or passButtonsByKey["Carry2Eggs"]
	rebirthBtn.NextSelectionUp = devProductButtons["CashPack100K"] or passButtonsByKey["Carry2Eggs"]

	-- =========================================================================
	-- 6. MODAL #3: 🎡 LUCKY SQUISHY SPIN WHEEL & 🎁 PLAYTIME REWARDS CHEST (100% Scale-Responsive!)
	-- =========================================================================
	local spinModal = Instance.new("Frame")
	spinModal.Name = "SpinWheelModal"
	spinModal.Size = UDim2.fromScale(0.62, 0.68)
	spinModal.Position = UDim2.fromScale(0.5, 0.51)
	spinModal.AnchorPoint = Vector2.new(0.5, 0.5)
	spinModal.BackgroundColor3 = Color3.fromRGB(28, 18, 52)
	spinModal.Visible = false
	spinModal.Parent = screenGui
	addCorner(spinModal, 18)
	addStroke(spinModal, Color3.fromRGB(255, 115, 220), 3.4)
	addAspectRatio(spinModal, 1.52)

	createFeaturedViewportPreview(
		spinModal,
		UDim2.fromScale(0.062, 0.095),
		UDim2.fromScale(0.016, 0.016),
		Color3.fromRGB(255, 95, 205),
		Color3.fromRGB(255, 235, 75),
		"Crown"
	)

	local spinTitle = Instance.new("TextLabel")
	spinTitle.Size = UDim2.fromScale(0.80, 0.085)
	spinTitle.Position = UDim2.fromScale(0.092, 0.018)
	spinTitle.BackgroundTransparency = 1
	spinTitle.Font = Enum.Font.FredokaOne
	spinTitle.TextXAlignment = Enum.TextXAlignment.Left
	spinTitle.TextColor3 = Color3.fromRGB(255, 235, 85)
	spinTitle.Text = "🎡 <b>LUCKY SPIN WHEEL (FREE EVERY 5M) & 🎁 PLAYTIME CHEST</b>"
	spinTitle.Parent = spinModal
	addTextSizeConstraint(spinTitle, 13, 26)
	addTextStroke(spinTitle, Color3.fromRGB(16, 10, 32), 2.2)

	local spinClose = Instance.new("TextButton")
	spinClose.Size = closeBtnSize
	spinClose.AnchorPoint = Vector2.new(0.5, 0.5)
	spinClose.Position = UDim2.fromScale(0.958, 0.060)
	spinClose.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
	spinClose.AutoButtonColor = false
	spinClose.Font = Enum.Font.FredokaOne
	spinClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	spinClose.Text = "<b>X</b>"
	spinClose.Parent = spinModal
	addCorner(spinClose, 10)
	addStroke(spinClose, Color3.fromRGB(255, 255, 255), 2.0)
	addTextSizeConstraint(spinClose, 14, 24)
	bindHoverAndClickTween(spinClose, closeBtnSize, Color3.fromRGB(235, 65, 75))

	local wheelPrizesInfo = {
		"💰 <b>+$2,500 Cash</b> (25%)",
		"💵 <b>+$5,000 Cash</b> (22%)",
		"👑 <b>2x Mythic Cash Mult</b> (18%)",
		"🛡️ <b>60s Boss Shield</b> (15%)",
		"💎 <b>+$15,000 Jackpot</b> (12%)",
		"🌈 <b>Rare/Mythic Squishy!</b> (8%)",
	}
	for idx, pText in ipairs(wheelPrizesInfo) do
		local col = (idx - 1) % 3
		local row = math.floor((idx - 1) / 3)
		local pCard = Instance.new("TextLabel")
		pCard.Size = UDim2.fromScale(0.31, 0.105)
		pCard.Position = UDim2.fromScale(0.02 + col * 0.325, 0.125 + row * 0.118)
		pCard.BackgroundColor3 = Color3.fromRGB(48, 34, 82)
		pCard.Font = Enum.Font.FredokaOne
		pCard.TextColor3 = Color3.fromRGB(255, 245, 200)
		pCard.Text = pText
		pCard.Parent = spinModal
		addCorner(pCard, 12)
		addStroke(pCard, Color3.fromRGB(255, 145, 225), 2.0)
		addTextSizeConstraint(pCard, 10, 20)
		addTextStroke(pCard, Color3.fromRGB(16, 10, 32), 1.6)
	end

	-- 3 Spin Action Buttons: Free Spin (Every 5m) + Buy 1 Spin ($2,500 Cash) + Buy 3 Spins (19 R$)
	local spinFreeSize = UDim2.fromScale(0.36, 0.11)
	local spinNowBtn = Instance.new("TextButton")
	spinNowBtn.Name = "SpinNowBtn"
	spinNowBtn.Size = spinFreeSize
	spinNowBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	spinNowBtn.Position = UDim2.fromScale(0.20, 0.43)
	spinNowBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 205)
	spinNowBtn.AutoButtonColor = false
	spinNowBtn.Font = Enum.Font.FredokaOne
	spinNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	spinNowBtn.Text = "🎡 <b>FREE SPIN (READY!)</b>"
	spinNowBtn.Parent = spinModal
	addCorner(spinNowBtn, 12)
	addStroke(spinNowBtn, Color3.fromRGB(255, 255, 255), 2.2)
	addTextSizeConstraint(spinNowBtn, 11, 22)
	addTextStroke(spinNowBtn, Color3.fromRGB(32, 10, 38), 2.0)
	bindHoverAndClickTween(spinNowBtn, spinFreeSize, Color3.fromRGB(255, 85, 205))

	local buySpinBtnSize = UDim2.fromScale(0.285, 0.11)
	local buySpinCashBtn = Instance.new("TextButton")
	buySpinCashBtn.Name = "BuySpinCashBtn"
	buySpinCashBtn.Size = buySpinBtnSize
	buySpinCashBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	buySpinCashBtn.Position = UDim2.fromScale(0.54, 0.43)
	buySpinCashBtn.BackgroundColor3 = Color3.fromRGB(65, 235, 115)
	buySpinCashBtn.AutoButtonColor = false
	buySpinCashBtn.Font = Enum.Font.FredokaOne
	buySpinCashBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buySpinCashBtn.Text = "💵 <b>BUY SPIN ($2,500)</b>"
	buySpinCashBtn.Parent = spinModal
	addCorner(buySpinCashBtn, 12)
	addStroke(buySpinCashBtn, Color3.fromRGB(255, 255, 255), 2.2)
	addTextSizeConstraint(buySpinCashBtn, 11, 20)
	addTextStroke(buySpinCashBtn, Color3.fromRGB(12, 42, 20), 2.0)
	bindHoverAndClickTween(buySpinCashBtn, buySpinBtnSize, Color3.fromRGB(65, 235, 115))

	local buySpinRobuxBtn = Instance.new("TextButton")
	buySpinRobuxBtn.Name = "BuySpinRobuxBtn"
	buySpinRobuxBtn.Size = buySpinBtnSize
	buySpinRobuxBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	buySpinRobuxBtn.Position = UDim2.fromScale(0.84, 0.43)
	buySpinRobuxBtn.BackgroundColor3 = Color3.fromRGB(255, 195, 45)
	buySpinRobuxBtn.AutoButtonColor = false
	buySpinRobuxBtn.Font = Enum.Font.FredokaOne
	buySpinRobuxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buySpinRobuxBtn.Text = "💎 <b>+3 SPINS ($5K / 19 R$)</b>"
	buySpinRobuxBtn.Parent = spinModal
	addCorner(buySpinRobuxBtn, 12)
	addStroke(buySpinRobuxBtn, Color3.fromRGB(255, 255, 255), 2.2)
	addTextSizeConstraint(buySpinRobuxBtn, 11, 20)
	addTextStroke(buySpinRobuxBtn, Color3.fromRGB(42, 24, 8), 2.0)
	bindHoverAndClickTween(buySpinRobuxBtn, buySpinBtnSize, Color3.fromRGB(255, 195, 45))

	-- Playtime Rewards Chest Section Header (2m, 5m, 10m, 15m, 30m)
	local playtimeHeader = Instance.new("TextLabel")
	playtimeHeader.Size = UDim2.fromScale(0.96, 0.06)
	playtimeHeader.Position = UDim2.fromScale(0.02, 0.505)
	playtimeHeader.BackgroundTransparency = 1
	playtimeHeader.Font = Enum.Font.FredokaOne
	playtimeHeader.TextXAlignment = Enum.TextXAlignment.Left
	playtimeHeader.TextColor3 = Color3.fromRGB(115, 245, 255)
	playtimeHeader.Text = "⏱️ <b>PLAYTIME REWARDS CHEST (2m • 5m • 10m • 15m • 30m)</b> — Stay in-game for free Cash, Spins & Mythics!"
	playtimeHeader.Parent = spinModal
	addTextSizeConstraint(playtimeHeader, 11, 20)
	addTextStroke(playtimeHeader, Color3.fromRGB(12, 16, 32), 1.8)

	local playtimeMilestones = {
		{ Index = 1, TimeLabel = "2m", RewardText = "+$1.5K\nCash", Color = Color3.fromRGB(75, 215, 255) },
		{ Index = 2, TimeLabel = "5m", RewardText = "+$4K\nCash", Color = Color3.fromRGB(95, 235, 135) },
		{ Index = 3, TimeLabel = "10m", RewardText = "+$10K\n+1 Spin", Color = Color3.fromRGB(255, 205, 65) },
		{ Index = 4, TimeLabel = "15m", RewardText = "+$25K\n+Shield", Color = Color3.fromRGB(205, 110, 255) },
		{ Index = 5, TimeLabel = "30m", RewardText = "+$75K\n+Mythic!", Color = Color3.fromRGB(255, 95, 195) },
	}
	local playtimeButtons: { [number]: TextButton } = {}
	for i, pm in ipairs(playtimeMilestones) do
		local cardX = 0.02 + (i - 1) * 0.194
		local pBox = Instance.new("Frame")
		pBox.Name = "PlaytimeCard_" .. pm.TimeLabel
		pBox.Size = UDim2.fromScale(0.182, 0.255)
		pBox.Position = UDim2.fromScale(cardX, 0.57)
		pBox.BackgroundColor3 = Color3.fromRGB(40, 30, 68)
		pBox.Parent = spinModal
		addCorner(pBox, 12)
		addStroke(pBox, pm.Color, 2.4)

		local tBadge = Instance.new("TextLabel")
		tBadge.Size = UDim2.fromScale(0.92, 0.22)
		tBadge.Position = UDim2.fromScale(0.04, 0.05)
		tBadge.BackgroundTransparency = 1
		tBadge.Font = Enum.Font.FredokaOne
		tBadge.TextColor3 = pm.Color
		tBadge.Text = "🎁 <b>" .. pm.TimeLabel .. " REWARD</b>"
		tBadge.Parent = pBox
		addTextSizeConstraint(tBadge, 9, 17)

		local rDesc = Instance.new("TextLabel")
		rDesc.Size = UDim2.fromScale(0.92, 0.38)
		rDesc.Position = UDim2.fromScale(0.04, 0.27)
		rDesc.BackgroundTransparency = 1
		rDesc.Font = Enum.Font.FredokaOne
		rDesc.TextColor3 = Color3.fromRGB(255, 255, 255)
		rDesc.Text = "<b>" .. pm.RewardText .. "</b>"
		rDesc.Parent = pBox
		addTextSizeConstraint(rDesc, 10, 18)

		local ptBtnSize = UDim2.fromScale(0.88, 0.26)
		local ptBtn = Instance.new("TextButton")
		ptBtn.Name = "ClaimPlaytime_" .. tostring(i)
		ptBtn.Size = ptBtnSize
		ptBtn.AnchorPoint = Vector2.new(0.5, 0.5)
		ptBtn.Position = UDim2.fromScale(0.5, 0.81)
		ptBtn.BackgroundColor3 = pm.Color
		ptBtn.AutoButtonColor = false
		ptBtn.Font = Enum.Font.FredokaOne
		ptBtn.TextColor3 = Color3.fromRGB(16, 20, 32)
		ptBtn.Text = "⏳ <b>" .. pm.TimeLabel .. "</b>"
		ptBtn.Parent = pBox
		addCorner(ptBtn, 8)
		addTextSizeConstraint(ptBtn, 10, 17)
		bindHoverAndClickTween(ptBtn, ptBtnSize, pm.Color)
		playtimeButtons[i] = ptBtn
	end

	local dailyBtnSize = UDim2.fromScale(0.96, 0.115)
	local claimDailyModalBtn = Instance.new("TextButton")
	claimDailyModalBtn.Size = dailyBtnSize
	claimDailyModalBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	claimDailyModalBtn.Position = UDim2.fromScale(0.50, 0.91)
	claimDailyModalBtn.BackgroundColor3 = Color3.fromRGB(65, 235, 115)
	claimDailyModalBtn.AutoButtonColor = false
	claimDailyModalBtn.Font = Enum.Font.FredokaOne
	claimDailyModalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimDailyModalBtn.Text = "🎁 <b>CLAIM DAILY LOGIN STREAK CHEST (+Cash, +Spins & +Bear Trap)</b>"
	claimDailyModalBtn.Parent = spinModal
	addCorner(claimDailyModalBtn, 14)
	addStroke(claimDailyModalBtn, Color3.fromRGB(255, 255, 255), 2.4)
	addTextSizeConstraint(claimDailyModalBtn, 12, 24)
	addTextStroke(claimDailyModalBtn, Color3.fromRGB(12, 42, 20), 2.0)
	bindHoverAndClickTween(claimDailyModalBtn, dailyBtnSize, Color3.fromRGB(65, 235, 115))

	-- SpinModal Console NextSelection Wiring
	spinClose.NextSelectionDown = buySpinRobuxBtn
	spinNowBtn.NextSelectionUp = spinClose
	buySpinCashBtn.NextSelectionUp = spinClose
	buySpinRobuxBtn.NextSelectionUp = spinClose

	spinNowBtn.NextSelectionRight = buySpinCashBtn
	buySpinCashBtn.NextSelectionLeft = spinNowBtn
	buySpinCashBtn.NextSelectionRight = buySpinRobuxBtn
	buySpinRobuxBtn.NextSelectionLeft = buySpinCashBtn

	spinNowBtn.NextSelectionDown = playtimeButtons[1] or claimDailyModalBtn
	buySpinCashBtn.NextSelectionDown = playtimeButtons[3] or claimDailyModalBtn
	buySpinRobuxBtn.NextSelectionDown = playtimeButtons[5] or claimDailyModalBtn

	for pIdx = 1, 5 do
		local ptB = playtimeButtons[pIdx]
		if ptB then
			ptB.Selectable = true
			ptB.NextSelectionUp = if pIdx <= 2 then spinNowBtn elseif pIdx <= 4 then buySpinCashBtn else buySpinRobuxBtn
			if pIdx > 1 and playtimeButtons[pIdx - 1] then
				ptB.NextSelectionLeft = playtimeButtons[pIdx - 1]
			end
			if pIdx < 5 and playtimeButtons[pIdx + 1] then
				ptB.NextSelectionRight = playtimeButtons[pIdx + 1]
			end
			ptB.NextSelectionDown = claimDailyModalBtn
		end
	end

	claimDailyModalBtn.NextSelectionUp = playtimeButtons[3] or buySpinCashBtn
	claimDailyModalBtn.NextSelectionDown = spinClose
	spinClose.NextSelectionUp = claimDailyModalBtn

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
	-- 8. HIDDEN TREADMILL TURBO BUTTON (Legacy compatibility stub)
	local treadmillTurboBtn = Instance.new("TextButton")
	treadmillTurboBtn.Name = "TreadmillTurboBtn"
	treadmillTurboBtn.Visible = false
	treadmillTurboBtn.Selectable = false

	-- 9. 💖 LIKE & ⭐ FAVORITE HUD BUTTON + REWARD MODAL
	local likeFavHudSize = UDim2.fromScale(0.115, 0.048)
	local likeFavHudBtn = Instance.new("TextButton")
	likeFavHudBtn.Name = "LikeFavHudBtn"
	likeFavHudBtn.Size = likeFavHudSize
	likeFavHudBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	likeFavHudBtn.Position = UDim2.fromScale(0.895, 0.145)
	likeFavHudBtn.BackgroundColor3 = Color3.fromRGB(235, 65, 145)
	likeFavHudBtn.AutoButtonColor = false
	likeFavHudBtn.Font = Enum.Font.FredokaOne
	likeFavHudBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	likeFavHudBtn.Text = "💖 <b>LIKE & FAV (+$5K!)</b>"
	likeFavHudBtn.Visible = false
	likeFavHudBtn.Selectable = false
	likeFavHudBtn.Parent = screenGui
	addCorner(likeFavHudBtn, 12)
	addStroke(likeFavHudBtn, Color3.fromRGB(255, 235, 85), 2.5)
	addTextSizeConstraint(likeFavHudBtn, 10, 18)
	bindHoverAndClickTween(likeFavHudBtn, likeFavHudSize, Color3.fromRGB(235, 65, 145))

	local likeFavoriteModal = Instance.new("Frame")
	likeFavoriteModal.Name = "LikeFavoriteModal"
	likeFavoriteModal.Size = UDim2.fromScale(0.46, 0.54)
	likeFavoriteModal.Position = UDim2.fromScale(0.5, 0.50)
	likeFavoriteModal.AnchorPoint = Vector2.new(0.5, 0.5)
	likeFavoriteModal.BackgroundColor3 = Color3.fromRGB(26, 20, 44)
	likeFavoriteModal.Visible = false
	likeFavoriteModal.Parent = screenGui
	addCorner(likeFavoriteModal, 18)
	addStroke(likeFavoriteModal, Color3.fromRGB(255, 105, 185), 3.2)
	addAspectRatio(likeFavoriteModal, 1.48)

	local lfTitle = Instance.new("TextLabel")
	lfTitle.Size = UDim2.fromScale(0.84, 0.15)
	lfTitle.Position = UDim2.fromScale(0.04, 0.03)
	lfTitle.BackgroundTransparency = 1
	lfTitle.Font = Enum.Font.FredokaOne
	lfTitle.TextColor3 = Color3.fromRGB(255, 235, 95)
	lfTitle.Text = "💖 <b>👍 LIKE & ⭐ FAVORITE VIP GIFT!</b> 💖"
	lfTitle.Parent = likeFavoriteModal
	addTextSizeConstraint(lfTitle, 14, 28)

	local lfCloseSize = UDim2.fromScale(0.085, 0.12)
	local likeFavClose = Instance.new("TextButton")
	likeFavClose.Name = "CloseLikeFavBtn"
	likeFavClose.Size = lfCloseSize
	likeFavClose.Position = UDim2.fromScale(0.935, 0.09)
	likeFavClose.BackgroundColor3 = Color3.fromRGB(225, 58, 72)
	likeFavClose.AutoButtonColor = false
	likeFavClose.Font = Enum.Font.FredokaOne
	likeFavClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	likeFavClose.Text = "<b>X</b>"
	likeFavClose.Parent = likeFavoriteModal
	addCorner(likeFavClose, 10)
	addTextSizeConstraint(likeFavClose, 12, 22)
	bindHoverAndClickTween(likeFavClose, lfCloseSize, Color3.fromRGB(225, 58, 72))

	local lfDesc = Instance.new("TextLabel")
	lfDesc.Size = UDim2.fromScale(0.90, 0.30)
	lfDesc.Position = UDim2.fromScale(0.05, 0.20)
	lfDesc.BackgroundColor3 = Color3.fromRGB(38, 28, 62)
	lfDesc.Font = Enum.Font.FredokaOne
	lfDesc.TextColor3 = Color3.fromRGB(245, 248, 255)
	lfDesc.Text = "🌟 <b>Support Find my Squishy and steal my egg (brainrot) & Unlock Exclusive VIP Perks:</b>\n💰 <font color='#65FF8F'>+$5,000 Bonus Cash</font>  •  🎡 <font color='#FFE865'>+2 Free Wheel Spins</font>\n💖 <font color='#FF95E8'>'VIP SUPPORTER' Overhead Tag</font>  •  🛡️ <font color='#FFE865'>60s Boss Shield!</font>"
	lfDesc.Parent = likeFavoriteModal
	addCorner(lfDesc, 12)
	addStroke(lfDesc, Color3.fromRGB(255, 215, 75), 2.0)
	addTextSizeConstraint(lfDesc, 11, 19)

	local favBtnSize = UDim2.fromScale(0.88, 0.17)
	local favoriteNowBtn = Instance.new("TextButton")
	favoriteNowBtn.Name = "FavoriteNowBtn"
	favoriteNowBtn.Size = favBtnSize
	favoriteNowBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	favoriteNowBtn.Position = UDim2.fromScale(0.50, 0.62)
	favoriteNowBtn.BackgroundColor3 = Color3.fromRGB(255, 185, 42)
	favoriteNowBtn.AutoButtonColor = false
	favoriteNowBtn.Font = Enum.Font.FredokaOne
	favoriteNowBtn.TextColor3 = Color3.fromRGB(20, 24, 38)
	favoriteNowBtn.Text = "⭐ <b>FAVORITE GAME & CLAIM +$5,000 + 2 SPINS!</b>"
	favoriteNowBtn.Parent = likeFavoriteModal
	addCorner(favoriteNowBtn, 12)
	addStroke(favoriteNowBtn, Color3.fromRGB(255, 255, 255), 2.4)
	addTextSizeConstraint(favoriteNowBtn, 12, 22)
	bindHoverAndClickTween(favoriteNowBtn, favBtnSize, Color3.fromRGB(255, 185, 42))

	local claimLfSize = UDim2.fromScale(0.88, 0.18)
	local claimLikeFavRewardBtn = Instance.new("TextButton")
	claimLikeFavRewardBtn.Name = "ClaimLikeFavRewardBtn"
	claimLikeFavRewardBtn.Size = claimLfSize
	claimLikeFavRewardBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	claimLikeFavRewardBtn.Position = UDim2.fromScale(0.50, 0.84)
	claimLikeFavRewardBtn.BackgroundColor3 = Color3.fromRGB(65, 225, 115)
	claimLikeFavRewardBtn.AutoButtonColor = false
	claimLikeFavRewardBtn.Font = Enum.Font.FredokaOne
	claimLikeFavRewardBtn.TextColor3 = Color3.fromRGB(16, 22, 34)
	claimLikeFavRewardBtn.Text = "🎁 <b>INSTANT CLAIM: +$5,000 + 2 SPINS + 💖 VIP TAG!</b>"
	claimLikeFavRewardBtn.Parent = likeFavoriteModal
	addCorner(claimLikeFavRewardBtn, 12)
	addStroke(claimLikeFavRewardBtn, Color3.fromRGB(255, 255, 255), 2.4)
	addTextSizeConstraint(claimLikeFavRewardBtn, 12, 22)
	bindHoverAndClickTween(claimLikeFavRewardBtn, claimLfSize, Color3.fromRGB(65, 225, 115))

	-- Wire explicit PS5 / Gamepad D-pad navigation links inside LikeFavoriteModal
	favoriteNowBtn.NextSelectionDown = claimLikeFavRewardBtn
	favoriteNowBtn.NextSelectionUp = likeFavClose
	claimLikeFavRewardBtn.NextSelectionUp = favoriteNowBtn
	claimLikeFavRewardBtn.NextSelectionDown = likeFavClose
	likeFavClose.NextSelectionDown = favoriteNowBtn
	likeFavClose.NextSelectionUp = claimLikeFavRewardBtn

	-- =========================================================================
	-- 10. ❤️ PREMIUM HEALTH BAR (Hidden per clean HUD layout)
	-- =========================================================================
	local healthBarSize = UDim2.fromScale(0.128, 0.044)
	local healthBarFrame = Instance.new("Frame")
	healthBarFrame.Name = "PremiumHealthBarFrame"
	healthBarFrame.Size = healthBarSize
	healthBarFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	healthBarFrame.Position = UDim2.fromScale(0.895, 0.082)
	healthBarFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	healthBarFrame.BackgroundTransparency = 0.08
	healthBarFrame.Visible = false
	healthBarFrame.Parent = screenGui
	addCorner(healthBarFrame, 10)
	addStroke(healthBarFrame, Color3.fromRGB(80, 240, 130), 2.4)

	local healthBarBg = Instance.new("Frame")
	healthBarBg.Name = "HealthBarBg"
	healthBarBg.Size = UDim2.new(1, -8, 1, -8)
	healthBarBg.Position = UDim2.fromOffset(4, 4)
	healthBarBg.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	healthBarBg.BorderSizePixel = 0
	healthBarBg.Parent = healthBarFrame
	addCorner(healthBarBg, 7)

	local healthFill = Instance.new("Frame")
	healthFill.Name = "PremiumHealthFill"
	healthFill.Size = UDim2.fromScale(1.0, 1.0)
	healthFill.Position = UDim2.fromScale(0, 0)
	healthFill.BackgroundColor3 = Color3.fromRGB(80, 240, 120)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBarBg
	addCorner(healthFill, 7)

	local healthGrad = Instance.new("UIGradient")
	healthGrad.Rotation = 90
	healthGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(180, 255, 190)),
	})
	healthGrad.Parent = healthFill

	local healthLabel = Instance.new("TextLabel")
	healthLabel.Name = "PremiumHealthLabel"
	healthLabel.Size = UDim2.fromScale(1.0, 1.0)
	healthLabel.Position = UDim2.fromScale(0, 0)
	healthLabel.BackgroundTransparency = 1
	healthLabel.Font = Enum.Font.FredokaOne
	healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthLabel.Text = "❤️ 100 / 100 HP"
	healthLabel.TextScaled = true
	healthLabel.ZIndex = 5
	healthLabel.Parent = healthBarFrame
	addTextStroke(healthLabel, Color3.fromRGB(10, 12, 18), 2.2)
	addTextSizeConstraint(healthLabel, 10, 16)

	-- =========================================================================
	-- 11. ⚙️ SETTINGS PRO ADVANCED PANEL (Triggered via RightDock SettingsProBtn)
	-- =========================================================================
	local settingsProModal = Instance.new("Frame")
	settingsProModal.Name = "SettingsProModal"
	settingsProModal.Size = UDim2.fromScale(0.48, 0.58)
	settingsProModal.Position = UDim2.fromScale(0.5, 0.50)
	settingsProModal.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsProModal.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
	settingsProModal.BackgroundTransparency = 0.05
	settingsProModal.Visible = false
	settingsProModal.Parent = screenGui
	addCorner(settingsProModal, 18)
	addStroke(settingsProModal, Color3.fromRGB(120, 175, 255), 3.0)
	addAspectRatio(settingsProModal, 1.42)

	local spTitle = Instance.new("TextLabel")
	spTitle.Size = UDim2.new(1, -60, 0, 40)
	spTitle.Position = UDim2.fromOffset(20, 12)
	spTitle.BackgroundTransparency = 1
	spTitle.Font = Enum.Font.FredokaOne
	spTitle.TextXAlignment = Enum.TextXAlignment.Left
	spTitle.TextColor3 = Color3.fromRGB(255, 235, 95)
	spTitle.Text = "⚙️ <b>SETTINGS PANEL PRO — ADVANCED</b>"
	spTitle.Parent = settingsProModal
	addTextSizeConstraint(spTitle, 13, 22)

	local spCloseSize = UDim2.fromOffset(36, 36)
	local spClose = Instance.new("TextButton")
	spClose.Name = "SettingsProCloseBtn"
	spClose.Size = spCloseSize
	spClose.AnchorPoint = Vector2.new(0.5, 0.5)
	spClose.Position = UDim2.new(1, -26, 0, 26)
	spClose.BackgroundColor3 = Color3.fromRGB(235, 65, 75)
	spClose.AutoButtonColor = false
	spClose.Font = Enum.Font.FredokaOne
	spClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	spClose.Text = "<b>X</b>"
	spClose.Parent = settingsProModal
	addCorner(spClose, 8)
	bindHoverAndClickTween(spClose, spCloseSize, Color3.fromRGB(235, 65, 75))

	local spContainer = Instance.new("ScrollingFrame")
	spContainer.Name = "SettingsContainer"
	spContainer.Size = UDim2.new(1, -36, 1, -70)
	spContainer.Position = UDim2.fromOffset(18, 56)
	spContainer.BackgroundTransparency = 1
	spContainer.BorderSizePixel = 0
	spContainer.CanvasSize = UDim2.new(0, 0, 0, 460)
	spContainer.ScrollBarThickness = 6
	spContainer.Selectable = false
	spContainer.Parent = settingsProModal

	local spLayout = Instance.new("UIListLayout")
	spLayout.SortOrder = Enum.SortOrder.LayoutOrder
	spLayout.Padding = UDim.new(0, 10)
	spLayout.Parent = spContainer

	local function setupSettingsFocusStroke(btn: TextButton)
		btn.Selectable = true
		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(80, 100, 140)
		st.Thickness = 1.6
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Parent = btn

		btn.SelectionGained:Connect(function()
			st.Color = Color3.fromRGB(255, 240, 95)
			st.Thickness = 2.8
		end)
		btn.MouseEnter:Connect(function()
			st.Color = Color3.fromRGB(255, 240, 95)
			st.Thickness = 2.8
		end)
		btn.SelectionLost:Connect(function()
			st.Color = Color3.fromRGB(80, 100, 140)
			st.Thickness = 1.6
		end)
		btn.MouseLeave:Connect(function()
			st.Color = Color3.fromRGB(80, 100, 140)
			st.Thickness = 1.6
		end)
	end

	local function makeSettingRow(order: number, icon: string, titleText: string, descText: string): (Frame, Frame)
		local row = Instance.new("Frame")
		row.Name = "Row_" .. tostring(order)
		row.LayoutOrder = order
		row.Size = UDim2.new(1, -8, 0, 52)
		row.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
		row.BackgroundTransparency = 0.2
		row.Parent = spContainer
		addCorner(row, 10)
		addStroke(row, Color3.fromRGB(65, 80, 115), 1.6)

		local infoLbl = Instance.new("TextLabel")
		infoLbl.Size = UDim2.new(0.55, -12, 1, 0)
		infoLbl.Position = UDim2.fromOffset(12, 0)
		infoLbl.BackgroundTransparency = 1
		infoLbl.Font = Enum.Font.FredokaOne
		infoLbl.TextXAlignment = Enum.TextXAlignment.Left
		infoLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
		infoLbl.Text = string.format("%s <b>%s</b>\n<font color='#A8B4CC' size='11'>%s</font>", icon, titleText, descText)
		infoLbl.Active = false
		infoLbl.Selectable = false
		infoLbl.Parent = row
		addTextSizeConstraint(infoLbl, 10, 15)

		local ctrlContainer = Instance.new("Frame")
		ctrlContainer.Name = "ControlArea"
		ctrlContainer.Size = UDim2.new(0.42, -8, 1, -12)
		ctrlContainer.Position = UDim2.new(0.58, 0, 0, 6)
		ctrlContainer.BackgroundTransparency = 1
		ctrlContainer.Parent = row

		return row, ctrlContainer
	end

	-- Row 1: 🧸 Kid-Friendly Easy Mode (Big Arrows + Extra Hearts) - DEFAULT ON
	local _, kidCtrl = makeSettingRow(1, "🧸", "Kid-Friendly Easy Mode", "Big guidance arrows, gentle gameplay & extra hearts")
	local kidBtnSize = UDim2.fromScale(0.96, 0.92)
	local kidFriendlyToggleBtn = Instance.new("TextButton")
	kidFriendlyToggleBtn.Name = "KidFriendlyToggleBtn"
	kidFriendlyToggleBtn.Size = kidBtnSize
	kidFriendlyToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	kidFriendlyToggleBtn.Position = UDim2.fromScale(0.5, 0.5)
	kidFriendlyToggleBtn.BackgroundColor3 = Color3.fromRGB(65, 215, 125)
	kidFriendlyToggleBtn.AutoButtonColor = false
	kidFriendlyToggleBtn.Font = Enum.Font.FredokaOne
	kidFriendlyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	kidFriendlyToggleBtn.Text = "ON (Gentle & Guided 💖)"
	kidFriendlyToggleBtn.Parent = kidCtrl
	addCorner(kidFriendlyToggleBtn, 8)
	setupSettingsFocusStroke(kidFriendlyToggleBtn)
	bindHoverAndClickTween(kidFriendlyToggleBtn, kidBtnSize, Color3.fromRGB(65, 215, 125))

	-- Row 2: Music & SFX Volume (0%, 50%, 100%)
	local _, volCtrl = makeSettingRow(2, "🎵", "Music & SFX Volume", "Game ambient background audio")
	local volBtnSize = UDim2.fromScale(0.30, 0.92)
	local volBtns = {}
	for idx, lvl in ipairs({ 0, 50, 100 }) do
		local b = Instance.new("TextButton")
		b.Name = "Vol_" .. tostring(lvl)
		b.Size = volBtnSize
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.fromScale(0.16 + (idx - 1) * 0.34, 0.5)
		b.BackgroundColor3 = if lvl == 100 then Color3.fromRGB(65, 185, 255) else Color3.fromRGB(40, 48, 68)
		b.AutoButtonColor = false
		b.Font = Enum.Font.FredokaOne
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Text = tostring(lvl) .. "%"
		b.Parent = volCtrl
		addCorner(b, 8)
		setupSettingsFocusStroke(b)
		bindHoverAndClickTween(b, volBtnSize, if lvl == 100 then Color3.fromRGB(65, 185, 255) else Color3.fromRGB(40, 48, 68))
		volBtns[lvl] = b
	end

	-- Row 3: Brainrot Voice Announcers (Mute / Normal / Boosted)
	local _, voiceCtrl = makeSettingRow(3, "🗣️", "Brainrot Voice Sound", "Hatching & Index character calls")
	local voiceBtnSize = UDim2.fromScale(0.30, 0.92)
	local voiceBtns = {}
	for idx, mode in ipairs({ "Mute", "Normal", "Boost" }) do
		local b = Instance.new("TextButton")
		b.Name = "Voice_" .. mode
		b.Size = voiceBtnSize
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.fromScale(0.16 + (idx - 1) * 0.34, 0.5)
		b.BackgroundColor3 = if mode == "Normal" then Color3.fromRGB(245, 95, 185) else Color3.fromRGB(40, 48, 68)
		b.AutoButtonColor = false
		b.Font = Enum.Font.FredokaOne
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Text = mode
		b.Parent = voiceCtrl
		addCorner(b, 8)
		setupSettingsFocusStroke(b)
		bindHoverAndClickTween(b, voiceBtnSize, if mode == "Normal" then Color3.fromRGB(245, 95, 185) else Color3.fromRGB(40, 48, 68))
		voiceBtns[mode] = b
	end

	-- Row 4: Global Shadows & Bloom (FPS Boost Toggle)
	local _, shadowCtrl = makeSettingRow(4, "☀️", "Global Shadows (FPS Boost)", "Turn OFF for maximum performance")
	local shadowBtnSize = UDim2.fromScale(0.96, 0.92)
	local shadowsToggleBtn = Instance.new("TextButton")
	shadowsToggleBtn.Name = "ShadowsToggleBtn"
	shadowsToggleBtn.Size = shadowBtnSize
	shadowsToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	shadowsToggleBtn.Position = UDim2.fromScale(0.5, 0.5)
	shadowsToggleBtn.BackgroundColor3 = Color3.fromRGB(65, 215, 125)
	shadowsToggleBtn.AutoButtonColor = false
	shadowsToggleBtn.Font = Enum.Font.FredokaOne
	shadowsToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	shadowsToggleBtn.Text = "ON (High Quality)"
	shadowsToggleBtn.Parent = shadowCtrl
	addCorner(shadowsToggleBtn, 8)
	setupSettingsFocusStroke(shadowsToggleBtn)
	bindHoverAndClickTween(shadowsToggleBtn, shadowBtnSize, Color3.fromRGB(65, 215, 125))

	-- Row 5: Camera FOV (70, 80, 90)
	local _, fovCtrl = makeSettingRow(5, "📷", "Field of View (FOV)", "Wider view angle on screen")
	local fovBtnSize = UDim2.fromScale(0.30, 0.92)
	local fovBtns = {}
	for idx, fovVal in ipairs({ 70, 80, 90 }) do
		local b = Instance.new("TextButton")
		b.Name = "Fov_" .. tostring(fovVal)
		b.Size = fovBtnSize
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.fromScale(0.16 + (idx - 1) * 0.34, 0.5)
		b.BackgroundColor3 = if fovVal == 70 then Color3.fromRGB(255, 175, 45) else Color3.fromRGB(40, 48, 68)
		b.AutoButtonColor = false
		b.Font = Enum.Font.FredokaOne
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Text = tostring(fovVal)
		b.Parent = fovCtrl
		addCorner(b, 8)
		setupSettingsFocusStroke(b)
		bindHoverAndClickTween(b, fovBtnSize, if fovVal == 70 then Color3.fromRGB(255, 175, 45) else Color3.fromRGB(40, 48, 68))
		fovBtns[fovVal] = b
	end

	-- Row 6: Hide Other Players (Lag Reducer)
	local _, hidePlayersCtrl = makeSettingRow(6, "👥", "Hide Other Players", "Reduce lag in crowded servers")
	local hideBtnSize = UDim2.fromScale(0.96, 0.92)
	local hidePlayersToggleBtn = Instance.new("TextButton")
	hidePlayersToggleBtn.Name = "HidePlayersToggleBtn"
	hidePlayersToggleBtn.Size = hideBtnSize
	hidePlayersToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	hidePlayersToggleBtn.Position = UDim2.fromScale(0.5, 0.5)
	hidePlayersToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 48, 68)
	hidePlayersToggleBtn.AutoButtonColor = false
	hidePlayersToggleBtn.Font = Enum.Font.FredokaOne
	hidePlayersToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	hidePlayersToggleBtn.Text = "OFF (Show All)"
	hidePlayersToggleBtn.Parent = hidePlayersCtrl
	addCorner(hidePlayersToggleBtn, 8)
	setupSettingsFocusStroke(hidePlayersToggleBtn)
	bindHoverAndClickTween(hidePlayersToggleBtn, hideBtnSize, Color3.fromRGB(40, 48, 68))

	-- Row 7: Top Progress HUD Visibility
	local _, topHudCtrl = makeSettingRow(7, "📊", "Top Progress HUD", "Show/Hide the top statistics bar")
	local topHudBtnSize = UDim2.fromScale(0.96, 0.92)
	local topHudToggleBtn = Instance.new("TextButton")
	topHudToggleBtn.Name = "TopHudToggleBtn"
	topHudToggleBtn.Size = topHudBtnSize
	topHudToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	topHudToggleBtn.Position = UDim2.fromScale(0.5, 0.5)
	topHudToggleBtn.BackgroundColor3 = Color3.fromRGB(65, 215, 125)
	topHudToggleBtn.AutoButtonColor = false
	topHudToggleBtn.Font = Enum.Font.FredokaOne
	topHudToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	topHudToggleBtn.Text = "Visible"
	topHudToggleBtn.Parent = topHudCtrl
	addCorner(topHudToggleBtn, 8)
	setupSettingsFocusStroke(topHudToggleBtn)
	bindHoverAndClickTween(topHudToggleBtn, topHudBtnSize, Color3.fromRGB(65, 215, 125))

	-- SettingsPro NextSelection Linking
	spClose.NextSelectionDown = kidFriendlyToggleBtn
	kidFriendlyToggleBtn.NextSelectionUp = spClose
	kidFriendlyToggleBtn.NextSelectionDown = volBtns[50] or volBtns[0]

	volBtns[0].NextSelectionRight = volBtns[50]
	volBtns[50].NextSelectionLeft = volBtns[0]
	volBtns[50].NextSelectionRight = volBtns[100]
	volBtns[100].NextSelectionLeft = volBtns[50]

	volBtns[0].NextSelectionUp = kidFriendlyToggleBtn
	volBtns[50].NextSelectionUp = kidFriendlyToggleBtn
	volBtns[100].NextSelectionUp = kidFriendlyToggleBtn

	volBtns[0].NextSelectionDown = voiceBtns["Mute"]
	volBtns[50].NextSelectionDown = voiceBtns["Normal"]
	volBtns[100].NextSelectionDown = voiceBtns["Boost"]

	voiceBtns["Mute"].NextSelectionRight = voiceBtns["Normal"]
	voiceBtns["Normal"].NextSelectionLeft = voiceBtns["Mute"]
	voiceBtns["Normal"].NextSelectionRight = voiceBtns["Boost"]
	voiceBtns["Boost"].NextSelectionLeft = voiceBtns["Normal"]

	voiceBtns["Mute"].NextSelectionUp = volBtns[0]
	voiceBtns["Normal"].NextSelectionUp = volBtns[50]
	voiceBtns["Boost"].NextSelectionUp = volBtns[100]

	voiceBtns["Mute"].NextSelectionDown = shadowsToggleBtn
	voiceBtns["Normal"].NextSelectionDown = shadowsToggleBtn
	voiceBtns["Boost"].NextSelectionDown = shadowsToggleBtn

	shadowsToggleBtn.NextSelectionUp = voiceBtns["Normal"]
	shadowsToggleBtn.NextSelectionDown = fovBtns[80] or fovBtns[70]

	fovBtns[70].NextSelectionRight = fovBtns[80]
	fovBtns[80].NextSelectionLeft = fovBtns[70]
	fovBtns[80].NextSelectionRight = fovBtns[90]
	fovBtns[90].NextSelectionLeft = fovBtns[80]

	fovBtns[70].NextSelectionUp = shadowsToggleBtn
	fovBtns[80].NextSelectionUp = shadowsToggleBtn
	fovBtns[90].NextSelectionUp = shadowsToggleBtn

	fovBtns[70].NextSelectionDown = hidePlayersToggleBtn
	fovBtns[80].NextSelectionDown = hidePlayersToggleBtn
	fovBtns[90].NextSelectionDown = hidePlayersToggleBtn

	hidePlayersToggleBtn.NextSelectionUp = fovBtns[80] or fovBtns[70]
	hidePlayersToggleBtn.NextSelectionDown = topHudToggleBtn

	topHudToggleBtn.NextSelectionUp = hidePlayersToggleBtn
	topHudToggleBtn.NextSelectionDown = spClose
	spClose.NextSelectionUp = topHudToggleBtn

	-- Global Console & Input Sanitization: ensure buttons are Selectable, scrolling frames are not, and child elements don't block input
	for _, desc in ipairs(screenGui:GetDescendants()) do
		if desc:IsA("GuiButton") then
			desc.Active = true
			desc.Selectable = true
		elseif desc:IsA("ScrollingFrame") then
			desc.Selectable = false
		elseif desc:IsA("GuiObject") then
			desc.Selectable = false
			if desc.Parent and desc.Parent:IsA("GuiButton") then
				desc.Active = false
			end
		end
	end

	return {
		ScreenGui = screenGui,
		TopContainer = topContainer,
		TopBannerLabel = topBannerLabel,
		TopIndexBtn = topIndexBtn,
		TopSpeedBtn = topSpeedBtn,
		TopHudCloseBtn = topHudCloseBtn,
		RestoreTopHudBtn = restoreTopHudBtn,
		SquishyBarGroup = squishyBarGroup,
		SquishyBarFill = squishyBarFill,
		SquishyBarText = squishyBarText,
		SpeedBarGroup = speedBarGroup,
		SpeedBarFill = speedBarFill,
		SpeedBarText = speedBarText,
		ObjectiveBanner = objectiveBanner,
		ObjectiveText = objectiveText,
		GuideToggleBtn = guideToggleBtn,
		CloseBannerBtn = closeBannerBtn,
		TreadmillTurboBtn = treadmillTurboBtn,
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
		BuyHintIndexBtn = buyHintIndexBtn,
		IndexHintLabel = indexHintLabel,
		IndexClose = indexClose,
		IndexCards = indexCards,
		ShopModal = shopModal,
		ShopClose = shopClose,
		PassButtonsByKey = passButtonsByKey,
		DevProductButtons = devProductButtons,
		BuySpeedBtn = buySpeedBtn,
		BuyFenceBtn = buyFenceBtn,
		BuyHintShopBtn = buyHintShopBtn,
		RebirthBtn = rebirthBtn,
		SpinModal = spinModal,
		SpinClose = spinClose,
		SpinNowBtn = spinNowBtn,
		BuySpinCashBtn = buySpinCashBtn,
		BuySpinRobuxBtn = buySpinRobuxBtn,
		PlaytimeButtons = playtimeButtons,
		ClaimDailyModalBtn = claimDailyModalBtn,
		LikeFavHudBtn = likeFavHudBtn,
		LikeFavoriteModal = likeFavoriteModal,
		LikeFavClose = likeFavClose,
		FavoriteNowBtn = favoriteNowBtn,
		ClaimLikeFavRewardBtn = claimLikeFavRewardBtn,
		YouFoundPopup = youFoundPopup,
		YfBadge = yfBadge,
		YfRarityLbl = yfRarityLbl,
		YfNameLbl = yfNameLbl,
		RotatingViewportModels = rotatingViewportModels,
		SettingsProBtn = settingsProBtn,
		SettingsProModal = settingsProModal,
		SettingsProClose = spClose,
		KidFriendlyToggleBtn = kidFriendlyToggleBtn,
		SettingsVolumeBtns = volBtns,
		SettingsVoiceBtns = voiceBtns,
		SettingsShadowsBtn = shadowsToggleBtn,
		SettingsFovBtns = fovBtns,
		SettingsHidePlayersBtn = hidePlayersToggleBtn,
		SettingsTopHudToggleBtn = topHudToggleBtn,
		PremiumHealthBarFrame = healthBarFrame,
		PremiumHealthFill = healthFill,
		PremiumHealthLabel = healthLabel,
		GetActiveHoveredCard = function(): IndexCardEntry?
			return activeHoveredCard
		end,
	}
end

return UIBuilder
