--!strict
-- The reveal after a ball is bought at the stand or after a rebirth: the world
-- dims, a sunburst turns behind the ball spinning in 3D (or the rebirth icon),
-- and the name sits under the title. A click, tap or E closes it. The stand
-- prompts also name the action the next press really does (buy, equip or
-- nothing), since E no longer opens a menu. One screen serves both reveals.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPrompts = game:GetService("ProximityPromptService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local BallVisuals = require(Shared.BallVisuals)
local WorldRefs = require(Shared.WorldRefs)
local LevelSound = require(Shared.LevelUpSound)
local Motion = require(Shared.UiMotion)
local Assets = require(script.Parent.Parent.UIAssets)

local UnlockReveal = {}

local DESIGN = Vector2.new(1280, 720)
local CENTER_Y = 400
local INPUT_GUARD = 0.5
local DARK = Color3.fromRGB(24, 26, 36)
local CLOSE_KEYS = {
	[Enum.KeyCode.E] = true,
	[Enum.KeyCode.Return] = true,
	[Enum.KeyCode.KeypadEnter] = true,
	[Enum.KeyCode.ButtonA] = true,
}

export type Context = {
	player: Player,
	reduced: () -> boolean,
	playSound: (string, number?, number?) -> (),
}

local function label(parent: Instance, name: string, text: string, y: number, height: number, size: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromOffset(DESIGN.X / 2, y)
	l.Size = UDim2.fromOffset(DESIGN.X - 120, height)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.Text = text
	l.TextSize = size
	l.TextColor3 = Color3.new(1, 1, 1)
	l.ZIndex = 4
	l.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Color = DARK
	stroke.Thickness = if size >= 60 then 5 else 3
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = l
	return l
end

local function rays(parent: Instance, name: string, size: number, transparency: number): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Name = name
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromOffset(DESIGN.X / 2, CENTER_Y)
	image.Size = UDim2.fromOffset(size, size)
	image.BackgroundTransparency = 1
	image.Image = Assets.Sunburst
	image.ImageTransparency = transparency
	image.ZIndex = 1
	image.Parent = parent
	Assets.bind(image)
	return image
end

function UnlockReveal.mount(context: Context)
	local gui = Instance.new("ScreenGui")
	gui.Name = "UnlockReveal"
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 78 -- Above the upgrade cards, under the notices.
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	gui.Parent = context.player:WaitForChild("PlayerGui")

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.Selectable = false
	backdrop.Parent = gui

	local stage = Instance.new("Frame")
	stage.Name = "Stage"
	stage.AnchorPoint = Vector2.new(0.5, 0.5)
	stage.Position = UDim2.fromScale(0.5, 0.5)
	stage.Size = UDim2.fromOffset(DESIGN.X, DESIGN.Y)
	stage.BackgroundTransparency = 1
	stage.Parent = gui
	local fit = Instance.new("UIScale")
	fit.Parent = stage

	local reveal = Instance.new("CanvasGroup")
	reveal.Name = "Reveal"
	-- UIScale grows from the anchor point, so the pop starts from the centre.
	reveal.AnchorPoint = Vector2.new(0.5, 0.5)
	reveal.Position = UDim2.fromScale(0.5, 0.5)
	reveal.Size = UDim2.fromScale(1, 1)
	reveal.BackgroundTransparency = 1
	reveal.Parent = stage
	local window = Motion.window(reveal, 1, context.reduced)

	-- One layer: two counter-rotating bursts showed two centres through the icon.
	local outerRays = rays(reveal, "Rays", 760, 0.15)

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "BallPreview"
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.Position = UDim2.fromOffset(DESIGN.X / 2, CENTER_Y)
	viewport.Size = UDim2.fromOffset(420, 420)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(190, 190, 190)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-0.6, -1, -0.8)
	viewport.ZIndex = 3
	viewport.Parent = reveal
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 1.2, -11), Vector3.zero)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromOffset(DESIGN.X / 2, CENTER_Y)
	icon.Size = UDim2.fromOffset(320, 320)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 3
	icon.Visible = false
	icon.Parent = reveal

	local title = label(reveal, "Title", "", 92, 110, 96)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 240, 110), Color3.fromRGB(255, 170, 30))
	gradient.Rotation = 90
	gradient.Parent = title
	local name = label(reveal, "BallName", "", 180, 76, 66)
	local footer = label(reveal, "Bonus", "", 606, 56, 44)
	local hint = label(stage, "Hint", "Tap anywhere to continue", 668, 44, 30)
	hint.TextTransparency = 1
	local hintStroke = hint:FindFirstChildOfClass("UIStroke") :: UIStroke
	hintStroke.Transparency = 1

	local ball: Model? = nil
	local openedAt = 0
	local showing = false
	local closing = false
	local revision = 0
	local promptState: boolean? = nil
	local backdropTween: Tween? = nil
	local hintTweens: { Tween } = {}

	local function fitScreen()
		local size = gui.AbsoluteSize
		if size.X > 0 and size.Y > 0 then
			fit.Scale = math.min(size.X / DESIGN.X, size.Y / DESIGN.Y)
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitScreen)

	local function fadeBackdrop(goal: number, instant: boolean)
		if backdropTween then
			backdropTween:Cancel()
			backdropTween = nil
		end
		if instant then
			backdrop.BackgroundTransparency = goal
		else
			local tween = TweenService:Create(backdrop, TweenInfo.new(0.2), { BackgroundTransparency = goal })
			backdropTween = tween
			tween:Play()
		end
	end

	local function fadeHint(goal: number, delay: number, instant: boolean)
		for _, tween in hintTweens do
			tween:Cancel()
		end
		table.clear(hintTweens)
		if instant then
			hint.TextTransparency, hintStroke.Transparency = goal, goal
			return
		end
		local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delay)
		hintTweens = {
			TweenService:Create(hint, info, { TextTransparency = goal }),
			TweenService:Create(hintStroke, info, { Transparency = goal }),
		}
		for _, tween in hintTweens do
			tween:Play()
		end
	end

	local function restorePrompts()
		if promptState ~= nil then
			ProximityPrompts.Enabled = promptState
			promptState = nil
		end
	end

	local function finish()
		showing, closing = false, false
		gui.Enabled = false
		if ball then
			ball:Destroy()
			ball = nil
		end
		restorePrompts()
	end

	local function close()
		if not showing or closing or os.clock() - openedAt < INPUT_GUARD then
			return
		end
		closing = true
		local id = revision
		local reduced = context.reduced()
		gui:SetAttribute("ReducedMotion", reduced)
		fadeHint(1, 0, reduced)
		fadeBackdrop(1, reduced)
		window.setOpen(false, function()
			if revision == id then
				finish()
			end
		end)
	end

	backdrop.Activated:Connect(close)
	UserInputService.InputBegan:Connect(function(input: InputObject)
		if showing and CLOSE_KEYS[input.KeyCode] then
			close()
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not showing then
			return
		end
		local t = os.clock() - openedAt
		local still = context.reduced()
		if ball then
			ball:PivotTo(CFrame.Angles(0.3, 0, 0) * CFrame.Angles(0, t * 1.4, 0))
		end
		if not still then
			outerRays.Rotation = (t * 18) % 360
		end
	end)

	type Spec = {
		title: string,
		name: string,
		color: Color3,
		ballId: string?,
		image: string?,
		footer: string?,
	}
	local function present(spec: Spec)
		revision += 1
		local reduced = context.reduced()
		gui:SetAttribute("ReducedMotion", reduced)
		if ball then
			ball:Destroy()
			ball = nil
		end
		if spec.ballId then
			local model = BallVisuals.create(spec.ballId, 2.4)
			model.Parent = world
			ball = model
		end
		viewport.Visible = spec.ballId ~= nil
		icon.Visible = spec.image ~= nil
		icon.Image = spec.image or ""
		if spec.image then
			Assets.bind(icon)
		end
		title.Text = spec.title
		name.Text = spec.name
		name.TextColor3 = spec.color
		footer.Text = spec.footer or ""
		footer.Visible = spec.footer ~= nil
		outerRays.ImageColor3 = spec.color
		outerRays.Rotation = 0
		openedAt = os.clock()
		showing, closing = true, false
		if promptState == nil then
			promptState = ProximityPrompts.Enabled
			ProximityPrompts.Enabled = false
		end
		gui.Enabled = true
		fitScreen()
		fadeBackdrop(0.35, reduced)
		fadeHint(0, if reduced then 0 else 0.6, reduced)
		window.setOpen(true)
		context.playSound(LevelSound.id, LevelSound.volume, LevelSound.speed)
	end

	local function show(id: string)
		local item = Config.find(Config.Stones, id)
		if item then
			present({ title = "UNLOCKED!", name = string.upper(item.name), color = item.color, ballId = id })
		end
	end

	-- The rebirth multiplier is rebirths + 1, as in the Rebirth window.
	local function rebirth(count: number)
		present({
			title = "REBIRTH!",
			name = "REBIRTH " .. Config.format(count),
			color = Color3.fromRGB(226, 150, 255),
			image = Assets.Images.Rebirth,
			footer = "×" .. Config.format(count + 1) .. " SKILL FOREVER!",
		})
	end

	-- The stand prompts are written locally from the player's own data. The
	-- list is found once and searched again only after a prompt streams out.
	local prompts: { ProximityPrompt } = {}
	local promptWorld: number?
	local function standPrompts(worldIndex: number): { ProximityPrompt }
		local first = prompts[1]
		if promptWorld == worldIndex and first and first:IsDescendantOf(workspace) then
			return prompts
		end
		promptWorld = worldIndex
		table.clear(prompts)
		local stand = WorldRefs.balls(WorldRefs.world(worldIndex))
		if stand then
			for _, node in stand:GetDescendants() do
				if node:IsA("ProximityPrompt") and type(node:GetAttribute("BallId")) == "string" then
					table.insert(prompts, node)
				end
			end
		end
		return prompts
	end
	local function updatePrompts(info: any)
		local d = info.data
		for _, prompt in standPrompts(d.world) do
			local id = prompt:GetAttribute("BallId") :: string
			local item = Config.find(Config.Stones, id)
			if item then
				local text = if d.stone == id
					then "Equipped"
					elseif d.stones[id] then "Equip"
					else "Buy • " .. Config.format(item.cost) .. " Wins"
				if prompt.ActionText ~= text then
					prompt.ActionText = text
				end
			end
		end
	end

	return {
		show = show,
		rebirth = rebirth,
		active = function(): boolean
			return showing
		end,
		update = updatePrompts,
		destroy = function()
			revision += 1
			restorePrompts()
			window.destroy()
			gui:Destroy()
		end,
	}
end

return UnlockReveal
