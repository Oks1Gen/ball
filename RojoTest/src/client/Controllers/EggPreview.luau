--!strict
-- The nearby egg's interactive billboard follows the visible shell in 3D.
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local MotionConfig = require(game.ReplicatedStorage.Shared.UiMotionConfig)
local WorldRefs = require(game.ReplicatedStorage.Shared.WorldRefs)
local U = require(script.Parent.Parent.CollectorUI.Components)
local EggPanel = require(script.Parent.Parent.CollectorUI.EggStandPanel)
local GuiInsets = require(script.Parent.Parent.Modules.GuiInsets)
local Presentation = require(script.Parent.Parent.Modules.UiPresentation)
local Input = game:GetService("UserInputService")
local e = React.createElement
local Preview = {}

export type Context = {
	parent: Instance,
	snapshot: () -> any?,
	pets: () -> { any },
	-- A window, a throw, a hatch or the map intro hides the panel.
	blocked: () -> boolean,
	hatch: (string, number) -> (),
	buyAdmin: () -> (),
	playSound: ((string, number?, number?) -> ())?,
	hudBounds: (() -> (Vector2, Vector2))?,
}

export type Handle = {
	frame: () -> (),
	refresh: () -> (),
	-- The egg in the open panel, nil when closed.
	egg: () -> string?,
	tutorialPoint: (string) -> Vector2?,
	destroy: () -> (),
}

type Station = {
	id: string,
	part: BasePart,
	visual: Model?,
	sign: BillboardGui?,
}

local ADMIN = "AdminEgg"
-- Horizontal studs from the egg. The panel stays a little longer than it takes
-- to appear, so it does not blink on the edge.
local ENTER, LEAVE = 14, 17
-- A neighbour takes the panel over only when it is clearly closer.
local SWITCH = 1.5
local UNITS_PER_STUD = 34
local CANVAS = EggPanel.Canvas
local CENTER = EggPanel.Center / CANVAS
local WINDOW_PEAK = MotionConfig.Window.OvershootScale + 0.015
local BEFORE_CENTER = EggPanel.Center * WINDOW_PEAK
local AFTER_CENTER = (CANVAS - EggPanel.Center) * WINDOW_PEAK
local SCREEN_GAP = Vector2.new(10, 10)
local MIN_READABLE_SCALE = 0.46

local function availableArea(viewport: Vector2, hudBounds: (() -> (Vector2, Vector2))?): (Vector2, Vector2)
	local rect = GuiInsets.granted()
	local lo = Vector2.new(rect.x, rect.y)
	local hi = lo + Vector2.new(rect.width, rect.height)
	if rect.width <= 0 or rect.height <= 0 then
		lo = GuiInsets.screenCenter(viewport) - viewport / 2
		hi = lo + viewport
	end
	if hudBounds then
		local hudLo, hudHi = hudBounds()
		local innerLo = Vector2.new(math.max(lo.X, hudLo.X), math.max(lo.Y, hudLo.Y))
		local innerHi = Vector2.new(math.min(hi.X, hudHi.X), math.min(hi.Y, hudHi.Y))
		if innerHi.X > innerLo.X + 2 * SCREEN_GAP.X and innerHi.Y > innerLo.Y + 2 * SCREEN_GAP.Y then
			lo, hi = innerLo, innerHi
		end
	end
	return lo + SCREEN_GAP, hi - SCREEN_GAP
end

local function attach(station: Station): Attachment
	local part, center = station.part, station.part.Position
	local visual = station.visual
	if visual then
		local visualPart = visual.PrimaryPart or visual:FindFirstChildWhichIsA("BasePart", true)
		if visualPart then
			part = visualPart
			center = visual:GetBoundingBox().Position
		end
	end
	local anchor = Instance.new("Attachment")
	anchor.Name = "EggPreviewCenter"
	anchor.Position = part.CFrame:PointToObjectSpace(center)
	anchor.Parent = part
	return anchor
end

local function inputKind(): string
	if Presentation.keyboard() then
		return "Keyboard"
	elseif Input.PreferredInput == Enum.PreferredInput.Gamepad then
		return "Gamepad"
	end
	return "Touch"
end

function Preview.mount(context: Context): Handle
	local gui = Instance.new("BillboardGui")
	gui.Name = "EggPreview"
	gui.Enabled = false
	gui.Active = true -- Billboard input is handled by PlayerGui.
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 80
	gui.Size = UDim2.fromScale(CANVAS.X / UNITS_PER_STUD, CANVAS.Y / UNITS_PER_STUD)
	-- Offset the canvas so the action, rather than the canvas midpoint,
	-- occupies the projected centre of the egg.
	gui.SizeOffset = Vector2.new(0.5, 0.5) - CENTER
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = context.parent
	local group = Instance.new("CanvasGroup")
	group.Name = "EggPreviewWindow"
	group.AnchorPoint = CENTER
	group.Position = UDim2.fromScale(CENTER.X, CENTER.Y)
	group.Size = UDim2.fromScale(1, 1)
	group.BackgroundTransparency = 1
	group.BorderSizePixel = 0
	group.Parent = gui
	local design = Instance.new("Frame")
	design.Name = "Design"
	design.AnchorPoint = CENTER
	design.Position = UDim2.fromScale(CENTER.X, CENTER.Y)
	design.Size = UDim2.fromOffset(CANVAS.X, CANVAS.Y)
	design.BackgroundTransparency = 1
	design.Parent = group
	local fit = Instance.new("UIScale")
	fit.Parent = design
	-- React owns every child of its container, so the scale stays one level up.
	local holder = Instance.new("Frame")
	holder.Name = "Root"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = design
	local root = ReactRoblox.createRoot(holder)

	local function reduced(): boolean
		local snapshot = context.snapshot()
		return snapshot ~= nil and snapshot.data.settings.effects == false
	end
	local animation = Motion.window(group, 1, reduced)
	local stations: { Station } = {}
	local stationArena: Instance? = nil
	local scanAt = 0
	local wanted: Station? = nil
	local shown: Station? = nil
	local anchor: Attachment? = nil
	local signWasEnabled = false
	local open = false

	local function scan(arena: Instance)
		stations = {}
		stationArena = arena
		local function add(id: string)
			local stand, part, visual = WorldRefs.eggStation(arena, id)
			if not part then
				return
			end
			for _, prompt in part:GetDescendants() do
				if prompt:IsA("ProximityPrompt") then
					prompt.Enabled = false
				end
			end
			local signAnchor = stand and stand:FindFirstChild("EggSignAnchor", true)
			local sign = signAnchor and signAnchor:FindFirstChild("EggSign")
			table.insert(stations, {
				id = id,
				part = part,
				visual = visual,
				sign = if sign and sign:IsA("BillboardGui") then sign else nil,
			})
		end
		local ocean = arena.Name == "World2"
		for _, egg in Config.eggsForWorld(if ocean then 2 else 1) do
			add(egg.id)
		end
		if ocean then
			add(ADMIN)
		end
	end

	local function render()
		if not shown then
			root:render(nil)
			return
		end
		local snapshot = context.snapshot()
		gui:SetAttribute("ReducedMotion", reduced())
		local pets = context.pets()
		local discovered = table.clone(snapshot and snapshot.data.discoveredPets or {})
		for _, pet in pets do
			discovered[pet.id] = true
		end
		local heading = shown.sign and shown.sign:FindFirstChild("Title")
		local title = if heading and heading:IsA("TextLabel") then heading else nil
		root:render(e(U.MotionContext.Provider, { value = reduced() }, {
			Panel = e(EggPanel.View, {
				Egg = shown.id,
				Title = title and title.Text,
				TitleColor = title and title.TextColor3,
				Discovered = discovered,
				World = snapshot and snapshot.data.world or 1,
				PaidRandomRestricted = snapshot and snapshot.paidRandomRestricted ~= false,
				PurchasePolicyReady = snapshot and snapshot.purchasePolicyReady == true,
				Pets = #pets,
				Input = inputKind(),
				Reduced = reduced(),
				Hatch = function(id: string, count: number)
					if context.playSound then
						context.playSound("rbxasset://sounds/volume_slider.ogg", 0.16, 1.35)
					end
					context.hatch(id, count)
				end,
				BuyAdmin = function()
					if context.playSound then
						context.playSound("rbxasset://sounds/volume_slider.ogg", 0.16, 1.35)
					end
					context.buyAdmin()
				end,
			}),
		}))
	end

	-- The key caps follow the device the player is using.
	local inputChanged = Input:GetPropertyChangedSignal("PreferredInput"):Connect(render)

	local function clear()
		gui.Enabled = false
		gui.Adornee = nil :: any -- Roblox accepts nil to detach the billboard.
		if shown and shown.sign then
			shown.sign.Enabled = signWasEnabled
		end
		if anchor then
			anchor:Destroy()
			anchor = nil
		end
		shown = nil
	end

	local function show(station: Station)
		shown = station
		local attachment = attach(station)
		anchor = attachment
		gui.Adornee = attachment
		gui.Enabled = true
		signWasEnabled = station.sign ~= nil and station.sign.Enabled
		if station.sign then
			station.sign.Enabled = false
		end
		open = true
		render()
		animation.setOpen(true)
		if context.playSound then
			context.playSound("rbxasset://sounds/volume_slider.ogg", 0.12, 1.15)
		end
	end
	local function target(station: Station?)
		if station and wanted and station.part == wanted.part and station.visual == wanted.visual then
			return
		end
		if not station and not wanted then
			return
		end
		wanted = station
		if open then
			open = false
			animation.setOpen(false, function()
				clear()
				if wanted then
					show(wanted)
				else
					render()
				end
			end)
		elseif station and not shown then
			show(station)
		end
	end

	local function nearest(): Station?
		local player = game.Players.LocalPlayer
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local snapshot = context.snapshot()
		if not rootPart or not rootPart:IsA("BasePart") or not humanoid or humanoid.Health <= 0 or not snapshot then
			return nil
		end
		local arena = WorldRefs.world(snapshot.data.world)
		if not arena then
			return nil
		end
		local now = os.clock()
		if arena ~= stationArena or now >= scanAt then
			scanAt = now + 2
			scan(arena)
		end
		local here = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
		local best: Station?, bestDistance = nil, math.huge
		local current: Station?, currentDistance = nil, math.huge
		for _, station in stations do
			local position = station.part.Position
			local distance = (Vector3.new(position.X, 0, position.Z) - here).Magnitude
			if distance < bestDistance then
				best, bestDistance = station, distance
			end
			if wanted and station.part == wanted.part then
				current, currentDistance = station, distance
			end
		end
		if current and currentDistance <= LEAVE and (not best or bestDistance > currentDistance - SWITCH) then
			return current
		end
		return if best and bestDistance <= ENTER then best else nil
	end

	local function screenPoint(): Vector2?
		local camera = workspace.CurrentCamera
		if not open or not gui.Enabled or not group.Visible or not camera or not anchor then
			return nil
		end
		local position = anchor.WorldPosition
		if (camera.CFrame.Position - position).Magnitude > gui.MaxDistance then
			return nil
		end
		local _, visible = camera:WorldToScreenPoint(position)
		if not visible then
			return nil
		end
		local point = camera:WorldToScreenPoint(position + camera.CFrame:VectorToWorldSpace(gui.StudsOffset))
		return Vector2.new(point.X, point.Y)
	end

	local function fitToView()
		local camera = workspace.CurrentCamera
		if not camera or not anchor then
			return
		end
		local worldPosition = anchor.WorldPosition
		local point, visible = camera:WorldToScreenPoint(worldPosition)
		local lo, hi = availableArea(camera.ViewportSize, context.hudBounds)
		group.Visible = visible and hi.X > lo.X and hi.Y > lo.Y
		if not group.Visible then
			return
		end
		local right = camera:WorldToScreenPoint(worldPosition + camera.CFrame.RightVector)
		local pixelsPerStud = right.X - point.X
		if pixelsPerStud <= 0 then
			return
		end
		local naturalScale = pixelsPerStud / UNITS_PER_STUD
		local anchoredScale = math.min(
			(point.X - lo.X) / BEFORE_CENTER.X,
			(point.Y - lo.Y) / BEFORE_CENTER.Y,
			(hi.X - point.X) / AFTER_CENTER.X,
			(hi.Y - point.Y) / AFTER_CENTER.Y
		)
		local span = hi - lo
		-- Leave space for the Ripple overshoot. If the anchor is on the edge,
		-- keep a readable size where possible and clamp only the excess offset.
		local scale = math.min(
			naturalScale,
			math.max(MIN_READABLE_SCALE, anchoredScale),
			span.X / (CANVAS.X * WINDOW_PEAK + 1),
			span.Y / (CANVAS.Y * WINDOW_PEAK + 1)
		)
		local x = math.clamp(point.X, lo.X + BEFORE_CENTER.X * scale, hi.X - AFTER_CENTER.X * scale)
		local y = math.clamp(point.Y, lo.Y + BEFORE_CENTER.Y * scale, hi.Y - AFTER_CENTER.Y * scale)
		local studScale = scale / pixelsPerStud
		gui.Size = UDim2.fromScale(CANVAS.X * studScale, CANVAS.Y * studScale)
		gui.StudsOffset = Vector3.new((x - point.X) / pixelsPerStud, (point.Y - y) / pixelsPerStud, 0)
		fit.Scale = scale
	end

	return {
		frame = function()
			target(if context.blocked() then nil else nearest())
			if shown then
				fitToView()
			end
		end,
		refresh = render,
		egg = function()
			return if shown and screenPoint() then shown.id else nil
		end,
		tutorialPoint = function(id: string)
			if not shown or shown.id ~= id then
				return nil
			end
			local point = screenPoint()
			local button = point and holder:FindFirstChild("EggPreviewCenter", true)
			return if point
					and button
					and button:IsA("GuiButton")
				then point + button.AbsoluteSize * Vector2.new(0.15, 0.5)
				else nil
		end,
		destroy = function()
			inputChanged:Disconnect()
			animation.destroy()
			clear()
			root:unmount()
			gui:Destroy()
		end,
	}
end

return Preview
