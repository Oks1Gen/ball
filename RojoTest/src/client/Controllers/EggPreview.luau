--!strict
-- The panel of the nearest egg: its pets with their chances and the hatch
-- buttons (E for one egg, R for three). Only one egg shows at a time; the
-- panel takes the place of that egg's sign and pops like the other windows.
-- The egg prompts are switched off on this client: the panel replaces them.
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local U = require(script.Parent.Parent.CollectorUI.Components)
local T = require(script.Parent.Parent.CollectorUI.Theme)
local Art = require(script.Parent.Parent.CollectorUI.Art)
local PetCardArt = require(script.Parent.Parent.Modules.PetCardArt)
local Insets = require(script.Parent.Parent.Modules.GuiInsets)
local Presentation = require(script.Parent.Parent.Modules.UiPresentation)
local Input = game:GetService("UserInputService")
local e, C = React.createElement, Color3.fromRGB
local Preview = {}

export type Context = {
	parent: Instance,
	snapshot: () -> any?,
	pets: () -> { any },
	-- A window, a throw, a hatch or the map intro hides the panel.
	blocked: () -> boolean,
	hatch: (string, number) -> (),
	buyAdmin: () -> (),
}

export type Handle = {
	frame: () -> (),
	refresh: () -> (),
	-- The egg in the open panel ("AdminEgg" for the Volcanic egg), nil when closed.
	egg: () -> string?,
	destroy: () -> (),
}

type Station = {
	id: string,
	position: Vector3,
	sign: BillboardGui?,
}

local ADMIN = "AdminEgg"
-- Horizontal studs from the egg. The panel stays a little longer than it takes
-- to appear, so it does not blink on the edge.
local ENTER, LEAVE = 14, 17
-- A neighbour takes the panel over only when it is clearly closer.
local SWITCH = 1.5
local PANEL_WIDTH_STUDS = 8
local SIGN_HALF = 2.1 -- half the height of an egg sign
local CARD, GAP, PAD, TOP, COLUMNS = 108, 10, 14, 38, 3
local BUTTON_H, PRICE_H = 84, 42
local LAVA = C(255, 112, 38)
local MARGIN = 48 -- room around the content for the title and the button motion
local PLATE_W = COLUMNS * CARD + (COLUMNS - 1) * GAP + PAD * 2
local function plateHeight(id: string): number
	local rows = if id == ADMIN then 1 else math.ceil(#Config.eggPets(id) / COLUMNS)
	return TOP + rows * CARD + (rows - 1) * GAP + PAD
end
-- The whole content: the plate, the buttons and the price line.
local function size(id: string): Vector2
	return Vector2.new(PLATE_W, plateHeight(id) + 10 + BUTTON_H + 4 + PRICE_H)
end

local function outlined(props: { [string]: any }, thickness: number)
	props.BackgroundTransparency = 1
	props.Font = Enum.Font.GothamBlack
	props.TextStrokeTransparency = 1
	return e("TextLabel", props, {
		Stroke = e("UIStroke", {
			Color = T.Outline,
			Thickness = thickness,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}),
	})
end

-- A rarity tile: the rarity colour, rays behind the pet picture and the chance
-- written over the lower edge.
local function PetTile(p)
	local item = p.Item
	local image = PetCardArt.image(item.id)
	local ref: any = React.useRef(nil)
	-- A picture the experience cannot use never loads: the 3D pet stands in.
	local failed, setFailed = React.useState(false)
	React.useEffect(function()
		local label = ref.current
		if not label then
			return function() end
		end
		Art.bind(label)
		local alive = true
		task.delay(4, function()
			if alive and label.Parent and not label.IsLoaded and label.ImageContent.Object == nil then
				setFailed(true)
			end
		end)
		return function()
			alive = false
		end
	end, { image or "" })
	if failed then
		image = nil
	end
	local color = T.Rarity[item.rarity] or T.Slot
	return e(U.Surface, {
		Name = "EggPreviewPet" .. item.id,
		Color = color,
		Radius = 14,
		Outline = 3,
		NoShadow = true,
		Studs = false,
		Position = p.Position,
		Size = UDim2.fromOffset(CARD, CARD),
		ZIndex = 12,
		Children = {
			Rays = e("ImageLabel", {
				Name = "Rays",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Image = Art.Sunburst,
				ImageColor3 = Color3.new(1, 1, 1),
				ImageTransparency = 0.55,
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 13,
				Active = false,
			}, { Corner = U.corner(14) }),
			Pet = if image
				then e("ImageLabel", {
					ref = ref,
					Name = "PetCardArt",
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(8, 4),
					Size = UDim2.fromOffset(CARD - 16, CARD - 24),
					Image = image,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 15,
					Active = false,
				})
				else e(U.PetView, {
					Def = item,
					Key = item.id,
					Position = UDim2.fromOffset(8, 4),
					Size = UDim2.fromOffset(CARD - 16, CARD - 24),
					FitToView = true,
					Animated = true,
					ReducedMotion = p.Reduced,
					ZIndex = 15,
				}),
			Chance = outlined({
				Name = "Chance",
				Text = p.Chance,
				Position = UDim2.fromOffset(-6, CARD - 34),
				Size = UDim2.fromOffset(CARD + 12, 34),
				TextSize = 26,
				TextColor3 = T.Text,
				ZIndex = 20,
			}, 3),
		},
	})
end

-- A big key button: the key letter over the action. Without a keyboard or a
-- gamepad the action alone fills the button.
local function KeyButton(p)
	local children: { [string]: any } = {}
	if p.Key then
		children.Letter = outlined({
			Name = "Letter",
			Text = p.Key,
			Position = UDim2.fromOffset(0, 4),
			Size = UDim2.new(1, 0, 0, 46),
			TextSize = 46,
			TextColor3 = T.Text,
			ZIndex = 30,
		}, 3.5)
	end
	children.Caption = outlined({
		Name = "Caption",
		Text = p.Text,
		Position = if p.Key then UDim2.fromOffset(0, 48) else UDim2.fromOffset(0, 0),
		Size = if p.Key then UDim2.new(1, 0, 0, 28) else UDim2.fromScale(1, 1),
		TextSize = if p.Key then 25 else 30,
		TextColor3 = T.Text,
		ZIndex = 30,
	}, 2.5)
	return e(U.Button, {
		Name = p.Name,
		Color = p.Color,
		Position = p.Position,
		Size = p.Size,
		Disabled = p.Disabled,
		Radius = 16,
		Studs = false,
		ZIndex = 20,
		OnActivated = p.OnActivated,
		Children = children,
	})
end

type PanelProps = {
	Egg: string,
	World: number,
	Wins: number,
	Pets: number,
	Input: string,
	Reduced: boolean,
	Hatch: (string, number) -> (),
	BuyAdmin: () -> (),
}

local function Panel(p: PanelProps)
	local id = p.Egg
	local admin = id == ADMIN
	local plateH = plateHeight(id)
	local buttonY = plateH + 10
	local buttonW = math.floor((PLATE_W - GAP) / 2)
	local keyboard = p.Input == "Keyboard"
	local gamepad = p.Input == "Gamepad"
	local tiles: { [string]: any } = {}
	local title: string, titleColor: Color3
	local currency: string, price: string, affordable: boolean
	local buttons: { [string]: any } = {}
	if admin then
		local pet = Config.AdminPet
		title, titleColor = "Volcanic Inferno", LAVA
		currency, price, affordable = "Robux", Config.format(assert(Config.Products.AdminEgg.price)), true
		tiles.Card = e(PetTile, {
			Item = pet,
			Chance = "100%",
			Position = UDim2.fromOffset(PAD, TOP),
			Reduced = p.Reduced,
		})
		local infoX = PAD + CARD + 16
		local function info(name: string, text: string, y: number, textSize: number, color: Color3)
			tiles[name] = outlined({
				Name = name,
				Text = text,
				Position = UDim2.fromOffset(infoX, y),
				Size = UDim2.fromOffset(PLATE_W - infoX - PAD, textSize + 8),
				TextSize = textSize,
				TextColor3 = color,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 20,
			}, if textSize >= 24 then 2.5 else 2)
		end
		info("PetName", pet.name, TOP + 6, 25, T.Text)
		info("Rarity", "MYTHIC", TOP + 40, 21, T.Rarity.Mythic)
		info("Boost", "×" .. pet.boost .. " Skill", TOP + 70, 25, T.Gold)
		buttons.Hatch = e(KeyButton, {
			Name = "EggPreviewHatch",
			Text = "Hatch",
			Key = if keyboard then "E" elseif gamepad then "Y" else nil,
			Color = T.Colors.Green,
			Position = UDim2.fromOffset(math.floor((PLATE_W - buttonW) / 2), buttonY),
			Size = UDim2.fromOffset(buttonW, BUTTON_H),
			OnActivated = p.BuyAdmin,
		})
	else
		local egg = assert(Config.find(Config.Eggs, id), "Unknown egg " .. id)
		title, titleColor = string.gsub(egg.name, " Egg$", ""), egg.color
		local cost = egg.cost
		currency, price, affordable = "Wins", Config.format(cost), p.Wins >= cost
		local pool = Config.eggPets(id)
		local total = 0
		for _, item in pool do
			total += item.weight
		end
		for i, item in pool do
			local column, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
			tiles[item.id] = e(PetTile, {
				Item = item,
				Chance = string.format("%g%%", math.floor(item.weight / total * 10000 + 0.5) / 100),
				Position = UDim2.fromOffset(PAD + column * (CARD + GAP), TOP + row * (CARD + GAP)),
				Reduced = p.Reduced,
			})
		end
		buttons.Hatch = e(KeyButton, {
			Name = "EggPreviewHatch",
			Text = "Hatch",
			Key = if keyboard then "E" elseif gamepad then "Y" else nil,
			Color = T.Colors.Green,
			Position = UDim2.fromOffset(0, buttonY),
			Size = UDim2.fromOffset(buttonW, BUTTON_H),
			Disabled = p.Pets + 1 > 60,
			OnActivated = function()
				p.Hatch(id, 1)
			end,
		})
		buttons.Multi = e(KeyButton, {
			Name = "EggPreviewHatch3",
			Text = "Multi ×3",
			Key = if keyboard then "R" elseif gamepad then "X" else nil,
			Color = T.Colors.Gold,
			Position = UDim2.fromOffset(PLATE_W - buttonW, buttonY),
			Size = UDim2.fromOffset(buttonW, BUTTON_H),
			Disabled = p.Pets + 3 > 60,
			OnActivated = function()
				p.Hatch(id, 3)
			end,
		})
	end
	return e("Frame", {
		Name = "EggPreviewContent",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(MARGIN, MARGIN),
		Size = UDim2.fromOffset(PLATE_W, size(id).Y),
		ZIndex = 2,
	}, {
		Plate = e(U.Surface, {
			Name = "EggPreviewPlate",
			Color = T.Body,
			Radius = T.PanelRadius,
			Outline = T.WindowStroke,
			Size = UDim2.fromOffset(PLATE_W, plateH),
			ZIndex = 2,
			Children = {
				Title = outlined({
					Name = "Title",
					Text = title,
					Position = UDim2.fromOffset(0, -32),
					Size = UDim2.fromOffset(PLATE_W, 60),
					TextSize = 42,
					TextColor3 = titleColor,
					ZIndex = 40,
				}, 4),
				Tiles = e("Frame", {
					Name = "Tiles",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 10,
				}, tiles),
			},
		}),
		Hatch = buttons.Hatch,
		Multi = buttons.Multi,
		Price = e("Frame", {
			Name = "Price",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, buttonY + BUTTON_H + 4),
			Size = UDim2.fromOffset(PLATE_W, PRICE_H),
			ZIndex = 20,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
			}),
			Icon = e(U.Icon, { Kind = currency, Size = UDim2.fromOffset(40, 40), ZIndex = 21 }),
			Amount = outlined({
				Name = "Amount",
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, PRICE_H),
				Text = price,
				TextSize = 38,
				TextColor3 = if affordable then T.Colors.Green else T.Colors.Red,
				ZIndex = 21,
			}, 3),
		}),
	})
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
	local gui = Instance.new("ScreenGui")
	gui.Name = "EggPreview"
	Insets.prepare(gui)
	-- Positions come from WorldToViewportPoint: the layer covers the whole viewport.
	gui.ScreenInsets = Enum.ScreenInsets.None
	-- Above the HUD (20), below the collector windows (30).
	gui.DisplayOrder = 25
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = context.parent
	local probe = Instance.new("Frame")
	probe.Name = "PreviewArea"
	probe.BackgroundTransparency = 1
	probe.Size = UDim2.fromScale(1, 1)
	probe.Parent = gui
	local group = Instance.new("CanvasGroup")
	group.Name = "EggPreviewWindow"
	group.AnchorPoint = Vector2.new(0.5, 1)
	group.BackgroundTransparency = 1
	group.BorderSizePixel = 0
	group.Parent = probe
	local design = Instance.new("Frame")
	design.Name = "Design"
	design.AnchorPoint = Vector2.new(0.5, 0.5)
	design.Position = UDim2.fromScale(0.5, 0.5)
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
	local wanted: string? = nil
	local shown: string? = nil
	local open = false

	local function scan(arena: Instance)
		stations = {}
		stationArena = arena
		local scenery = require(game.ReplicatedStorage.Shared.WorldRefs).eggs(arena)
		if not scenery then
			return
		end
		local function add(id: string, part: Instance?, anchorParent: Instance?)
			if not part or not part:IsA("BasePart") then
				return
			end
			for _, prompt in part:GetDescendants() do
				if prompt:IsA("ProximityPrompt") then
					prompt.Enabled = false
				end
			end
			local anchor = anchorParent and anchorParent:FindFirstChild("EggSignAnchor")
			local sign = anchor and anchor:FindFirstChild("EggSign")
			table.insert(stations, {
				id = id,
				position = part.Position,
				sign = if sign and sign:IsA("BillboardGui") then sign else nil,
			})
		end
		for _, egg in Config.Eggs do
			local model = scenery:FindFirstChild("Egg_" .. egg.id)
			add(egg.id, model and model:FindFirstChild("EggShell"), model)
		end
		local volcanic = require(game.ReplicatedStorage.Shared.WorldRefs).volcanic(arena)
		add(
			ADMIN,
			volcanic and (volcanic:FindFirstChild("InteractionAnchor") or volcanic:FindFirstChild("HackedAdminEgg")),
			volcanic and (volcanic:FindFirstChild("Sign") or volcanic:FindFirstChild("AdminEggCaption"))
		)
	end

	local function render()
		if not shown then
			root:render(nil)
			return
		end
		local snapshot = context.snapshot()
		local content = size(shown)
		design.Size = UDim2.fromOffset(content.X + MARGIN * 2, content.Y + MARGIN * 2)
		root:render(e(U.MotionContext.Provider, { value = reduced() }, {
			Panel = e(Panel, {
				Egg = shown,
				World = snapshot and snapshot.data.world or 1,
				Wins = snapshot and snapshot.data.wins or 0,
				Pets = #context.pets(),
				Input = inputKind(),
				Reduced = reduced(),
				Hatch = context.hatch,
				BuyAdmin = context.buyAdmin,
			}),
		}))
	end

	-- The key caps follow the device the player is using.
	local inputChanged = Input:GetPropertyChangedSignal("PreferredInput"):Connect(render)

	local function show(id: string)
		shown = id
		open = true
		render()
		animation.setOpen(true)
	end
	local function target(id: string?)
		if id == wanted then
			return
		end
		wanted = id
		if open then
			open = false
			animation.setOpen(false, function()
				shown = nil
				if wanted then
					show(wanted)
				else
					render()
				end
			end)
		elseif id then
			show(id)
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
		local map = workspace:FindFirstChild("Map")
		local arena = map and map:FindFirstChild("World1")
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
			local distance = (Vector3.new(station.position.X, 0, station.position.Z) - here).Magnitude
			if distance < bestDistance then
				best, bestDistance = station, distance
			end
			if station.id == wanted then
				current, currentDistance = station, distance
			end
		end
		if current and currentDistance <= LEAVE and (not best or bestDistance > currentDistance - SWITCH) then
			return current
		end
		return if best and bestDistance <= ENTER then best else nil
	end

	local function place(station: Station)
		local camera = workspace.CurrentCamera
		local adornee = station.sign and station.sign.Adornee
		local anchor = if adornee and adornee:IsA("BasePart")
			then adornee.Position - Vector3.new(0, SIGN_HALF, 0)
			else station.position + Vector3.new(0, 8, 0)
		local point = camera:WorldToViewportPoint(anchor)
		group.Visible = point.Z > 0.5
		if not group.Visible then
			return
		end

		-- Project a fixed width at the egg's depth. Keep the controls in
		-- PlayerGui so their clicks and existing button motion work as usual.
		local edge = camera:WorldToViewportPoint(anchor + camera.CFrame.RightVector * PANEL_WIDTH_STUDS)
		local scale = (edge.X - point.X) / PLATE_W
		fit.Scale = scale
		local content = size(station.id)
		group.Size = UDim2.fromOffset((content.X + MARGIN * 2) * scale, (content.Y + MARGIN * 2) * scale)
		group.Position = UDim2.fromOffset(point.X, point.Y + MARGIN * scale)
	end

	return {
		frame = function()
			local station = if context.blocked() then nil else nearest()
			target(station and station.id)
			local placed: Station? = nil
			for _, item in stations do
				if item.id == shown then
					placed = item
				end
				if item.sign then
					-- The open panel stands in for the sign of its egg.
					item.sign.Enabled = item.id ~= shown
				end
			end
			if placed then
				place(placed)
			end
		end,
		refresh = render,
		egg = function()
			return if open then shown else nil
		end,
		destroy = function()
			inputChanged:Disconnect()
			animation.destroy()
			root:unmount()
			gui:Destroy()
		end,
	}
end

return Preview
