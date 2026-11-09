--!strict
-- Proximity-only egg catalogue. Uses the same surfaces and button motion as Pets.
local React = require(game.ReplicatedStorage.Packages.React)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local OceanCatalog = require(game.ReplicatedStorage.Shared.OceanEggCatalog)
local Marketplace = require(script.Parent.Parent.Modules.MarketplaceCatalog)
local PetArt = require(script.Parent.Parent.Modules.PetCardArt)
local U = require(script.Parent.Components)
local T = require(script.Parent.Theme)
local Art = require(script.Parent.Art)
local Run = game:GetService("RunService")
local e = React.createElement
local Panel = {}
local CARD, GAP, PAD, TOP, COLUMNS = 128, 12, 16, 76, 3
local WIDTH = COLUMNS * CARD + (COLUMNS - 1) * GAP + PAD * 2
local LEFT, ACTION_W, ACTION_H = 24, 176, 88
local ACTION_X = LEFT + WIDTH + 24
local KEY_SIZE = 136
local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
Panel.Center = Vector2.new(ACTION_X + ACTION_W + 28 + KEY_SIZE / 2, 254)
Panel.Canvas = Vector2.new(Panel.Center.X + KEY_SIZE / 2 + 30, 2 * Panel.Center.Y)

local function pool(id: string, restricted: boolean?): { any }
	if id == "AdminEgg" then
		return { Config.AdminPet }
	end
	local items = Config.eggPets(id)
	return if restricted then { items[1] } else items
end

local function label(props: { [string]: any }, thickness: number?)
	props.BackgroundTransparency = 1
	props.Font = Enum.Font.GothamBlack
	props.TextColor3 = props.TextColor3 or T.Text
	props.TextStrokeTransparency = 1
	return e("TextLabel", props, {
		Stroke = e("UIStroke", {
			Color = T.Outline,
			Thickness = thickness or 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}),
	})
end

local function Price(p)
	return e("Frame", {
		Name = "Price",
		BackgroundTransparency = 1,
		Position = p.Position,
		Size = p.Size,
		ZIndex = 30,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),
		Icon = e(U.Icon, { Kind = p.Currency, Size = UDim2.fromOffset(30, 30), ZIndex = 31 }),
		Amount = label({
			Name = "Amount",
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			Text = p.Text,
			TextSize = p.TextSize or 25,
			ZIndex = 31,
		}),
	})
end

local function PetTile(p)
	local item = p.Item
	local image = PetArt.outlinedImage(item.id)
	local ref: any = React.useRef(nil)
	local rays: any = React.useRef(nil)
	local failed, setFailed = React.useState(false)
	React.useEffect(function()
		local picture = ref.current
		if not picture then
			return function() end
		end
		Art.bind(picture)
		local alive = true
		task.delay(4, function()
			if alive and picture.Parent and not picture.IsLoaded and picture.ImageContent.Object == nil then
				setFailed(true)
			end
		end)
		return function()
			alive = false
		end
	end, { image or "" })
	React.useEffect(function()
		local picture, glow = ref.current, rays.current
		if p.Reduced then
			if picture then
				picture.Position = UDim2.fromOffset(8, 5)
				picture.Rotation = 0
			end
			if glow then
				glow.Rotation = 0
			end
			return function() end
		end
		local phase = (string.byte(item.id) or 0) * 0.23
		local start = os.clock()
		local connection = Run.RenderStepped:Connect(function()
			local t = os.clock() - start + phase
			if picture then
				picture.Position = UDim2.fromOffset(8, 5 + math.sin(t * 1.7) * 3)
				picture.Rotation = math.sin(t * 0.9) * 2
			end
			if glow then
				glow.Rotation = (t * 8) % 360
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { p.Reduced == true, failed })
	local tint = if p.Known then WHITE else BLACK
	return e(U.Surface, {
		Name = "EggPreviewPet" .. item.id,
		Color = T.Rarity[item.rarity] or T.Slot,
		Radius = 12,
		Outline = T.Stroke,
		NoShadow = true,
		Studs = false,
		Position = p.Position,
		Size = UDim2.fromOffset(CARD, CARD),
		ZIndex = 12,
		Children = {
			Rays = e("ImageLabel", {
				ref = rays,
				Name = "Rays",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Image = Art.Sunburst,
				ImageTransparency = 0.7,
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 13,
			}, { Corner = U.corner(12) }),
			Pet = if image and not failed
				then e("ImageLabel", {
					ref = ref,
					Name = "PetCardArt",
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(8, 5),
					Size = UDim2.fromOffset(CARD - 16, CARD - 27),
					Image = image,
					ImageColor3 = tint,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 15,
				})
				else e(U.PetView, {
					Def = item,
					Key = item.id,
					Position = UDim2.fromOffset(8, 5),
					Size = UDim2.fromOffset(CARD - 16, CARD - 27),
					ImageColor3 = tint,
					FitToView = true,
					Animated = true,
					ReducedMotion = p.Reduced,
					ZIndex = 15,
				}),
			Chance = label({
				Name = "Chance",
				Text = p.Chance,
				Position = UDim2.fromOffset(0, CARD - 34),
				Size = UDim2.fromOffset(CARD, 34),
				TextSize = 29,
				ZIndex = 20,
			}, 3),
		},
	})
end

local function HatchButton(p)
	return e(U.Button, {
		Name = p.Name,
		Color = p.Color,
		Position = p.Position,
		Size = UDim2.fromOffset(ACTION_W, ACTION_H),
		Disabled = p.Disabled,
		Radius = T.PanelRadius,
		Studs = true,
		ZIndex = 20,
		OnActivated = p.OnActivated,
		Children = {
			Caption = label({
				Name = "Caption",
				Text = p.Text,
				Position = UDim2.fromOffset(0, 10),
				Size = UDim2.new(1, 0, 0, 36),
				TextSize = 29,
				ZIndex = 30,
			}, 2.5),
			Price = e(Price, {
				Currency = p.Currency,
				Text = p.Price,
				Position = UDim2.fromOffset(0, 49),
				Size = UDim2.new(1, 0, 0, 32),
			}),
			Key = p.Key and label({
				Name = "Letter",
				Text = p.Key,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 1, -3),
				Size = UDim2.fromOffset(44, 35),
				TextSize = 29,
				ZIndex = 35,
			}, 3),
		},
	})
end

local function CenterButton(p)
	return e(U.Button, {
		Name = "EggPreviewCenter",
		Color = T.Text,
		BottomColor = T.Text:Lerp(T.Slot, 0.16),
		Position = UDim2.fromOffset(Panel.Center.X, Panel.Center.Y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(KEY_SIZE, KEY_SIZE),
		Radius = KEY_SIZE / 2,
		Outline = 4,
		Studs = false,
		Disabled = p.Disabled,
		OnActivated = p.OnActivated,
		Children = {
			Caption = label({
				Name = "BuyEgg",
				Text = "Buy Egg!",
				Position = UDim2.new(0.5, 0, 0, -43),
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.fromOffset(180, 36),
				TextSize = 28,
				ZIndex = 30,
			}, 3),
			Key = label({
				Name = "CenterKey",
				Text = p.Key or "Hatch",
				Size = UDim2.fromScale(1, 1),
				TextSize = if p.Key then 85 else 28,
				TextColor3 = T.Outline,
				ZIndex = 30,
			}, 0),
		},
	})
end

function Panel.View(p: any): any
	local id = p.Egg
	local admin = id == "AdminEgg"
	local items = pool(id, p.PaidRandomRestricted)
	local rows = math.ceil(#items / COLUMNS)
	local height = TOP + rows * CARD + (rows - 1) * GAP + PAD
	local ocean = OceanCatalog.find(id, p.World)
	local egg = if not admin then Config.find(Config.Eggs, id) else nil
	local title = p.Title or (ocean and ocean.theme .. " Egg") or (egg and egg.name) or "Admin Egg"
	local currency = if admin then "Robux" else "Wins"
	local cost = if egg then Config.eggCost(egg, p.World) else 0
	local price = if admin then Marketplace.label("AdminEgg") else Config.format(cost)
	local keyboard, gamepad = p.Input == "Keyboard", p.Input == "Gamepad"
	local singleKey = if keyboard then "E" elseif gamepad then "Y" else nil
	local singleDisabled = if admin
		then not Marketplace.available("AdminEgg")
		else not p.PurchasePolicyReady or p.Pets + 1 > 60
	local function hatchOne()
		if admin then
			p.BuyAdmin()
		else
			p.Hatch(id, 1)
		end
	end
	local total, known = 0, 0
	for _, item in items do
		total += item.weight or 1
		if p.Discovered[item.id] then
			known += 1
		end
	end
	local tiles: { [string]: any } = {}
	for i, item in items do
		local column, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
		local countInRow = math.min(COLUMNS, #items - row * COLUMNS)
		local rowInset = (COLUMNS - countInRow) * (CARD + GAP) / 2
		tiles[item.id] = e(PetTile, {
			Item = item,
			Known = p.Discovered[item.id] == true,
			Chance = string.format("%g%%", math.floor((item.weight or 1) / total * 10000 + 0.5) / 100),
			Position = UDim2.fromOffset(PAD + rowInset + column * (CARD + GAP), TOP + row * (CARD + GAP)),
			Reduced = p.Reduced,
		})
	end
	return e("Frame", {
		Name = "EggPreviewContent",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Plate = e(U.Surface, {
			Name = "EggPreviewPlate",
			Color = T.Body,
			Transparency = 0.3,
			Radius = T.PanelRadius,
			Outline = T.WindowStroke,
			Studs = false,
			Quiet = true,
			NoShadow = true,
			Position = UDim2.fromOffset(LEFT, Panel.Center.Y - height / 2),
			Size = UDim2.fromOffset(WIDTH, height),
			Children = {
				Title = label({
					Name = "Title",
					Text = title,
					Position = UDim2.fromOffset(0, -39),
					Size = UDim2.fromOffset(WIDTH, 64),
					TextSize = 43,
					TextColor3 = p.TitleColor or T.Text,
					ZIndex = 40,
				}, 3.5),
				Price = e(U.Surface, {
					Name = "EggPrice",
					Color = T.Colors.Green,
					Position = UDim2.fromOffset(PAD, 25),
					Size = UDim2.fromOffset(176, 36),
					NoShadow = true,
					Studs = false,
					Children = { Value = e(Price, { Currency = currency, Text = price, Size = UDim2.fromScale(1, 1) }) },
				}),
				Progress = label({
					Name = "Discovered",
					Text = string.format("%d / %d Found", known, #items),
					Position = UDim2.fromOffset(WIDTH - PAD - 190, 25),
					Size = UDim2.fromOffset(190, 36),
					TextSize = 24,
					ZIndex = 20,
				}),
				Tiles = e("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 10 }, tiles),
			},
		}),
		Center = e(CenterButton, { Key = singleKey, Disabled = singleDisabled, OnActivated = hatchOne }),
		Hatch = e(HatchButton, {
			Name = "EggPreviewHatch",
			Text = if p.PaidRandomRestricted and not admin then "Get Pet" else "Hatch 1",
			Key = singleKey,
			Currency = currency,
			Price = price,
			Color = T.Colors.Green,
			Position = UDim2.fromOffset(ACTION_X, Panel.Center.Y - ACTION_H / 2),
			Disabled = singleDisabled,
			OnActivated = hatchOne,
		}),
		Multi = not admin and e(HatchButton, {
			Name = "EggPreviewHatch3",
			Text = if p.PaidRandomRestricted then "Get 3 Pets" else "Hatch 3",
			Key = if keyboard then "R" elseif gamepad then "X" else nil,
			Currency = currency,
			Price = Config.format(cost * 3),
			Color = T.Colors.Gold,
			Position = UDim2.fromOffset(Panel.Center.X - ACTION_W / 2, Panel.Center.Y + KEY_SIZE / 2 + 23),
			Disabled = not p.PurchasePolicyReady or p.Pets + 3 > 60,
			OnActivated = function()
				p.Hatch(id, 3)
			end,
		}),
	})
end

return Panel
