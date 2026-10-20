local Players = game:GetService("Players")
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local U = require(script.Components)
local T = require(script.Theme)
local Screens = require(script.Screens)
local e = React.createElement
local UI = {}
local navigation = {{"Shop", "Shop"}, {"Pets", "Pets"}, {"Eggs", "Egg"}, {"Trails", "Trails"},
	{"Inventory", "Inventory"}, {"Rebirth", "Rebirth"}, {"Gifts", "Gifts"}}
local function Window(p)
	local progress, goal = U.Hooks.useSpringBinding(0, {Frequency = 4.5, DampingRatio = 1}, p.Reduced, function(value)
		if value == 0 and not p.Visible then p.Settled() end
	end)
	React.useEffect(function() goal(p.Visible and 1 or 0) end, {p.Visible})
	local w, h = p.Width, p.Height
	local content = {
		Header = e(U.Surface, {Color = T.Colors[p.Kind] or T.Colors.Eggs, Position = UDim2.fromOffset(8, 8),
			Size = UDim2.new(1, -16, 0, 62), Shine = true, Children = {
				Icon = e(U.Icon, {Kind = (p.Kind == "Eggs" or p.Kind == "Hatch") and "Egg" or p.Kind, Position = UDim2.fromOffset(8, -2), Size = UDim2.fromOffset(62, 62)}),
				Title = e(U.Label, {Text = p.Title, Position = UDim2.fromOffset(80, 5), Size = UDim2.new(1, -155, 0, 48), Align = Enum.TextXAlignment.Left, TextSize = w < 550 and 28 or 36}),
				Close = e(U.Button, {Name = "Close", Text = "×", TextSize = 33, Color = T.Colors.Red,
					Position = UDim2.new(1, -55, 0, 6), Size = UDim2.fromOffset(46, 46), OnActivated = p.Close}),
			}}),
		Content = e("Frame", {Name = "ScreenContent", Position = UDim2.fromOffset(20, 84), Size = UDim2.fromOffset(w - 40, h - 100), BackgroundTransparency = 1, ZIndex = 10}, p.Children),
	}
	return e("CanvasGroup", {Name = "CollectorWindow", Size = UDim2.fromOffset(w + 12, h + 16), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = progress:map(function(value) return UDim2.new(0.5, 0, 0.5, 32 + math.round((1 - value) * 24)) end),
		GroupTransparency = progress:map(function(value) return 1 - math.clamp(value, 0, 1) end),
		Interactable = p.Visible, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 30}, {
		Shell = e(U.Surface, {Name = "WindowShell", Color = T.Body, Quiet = true, Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(w, h), Children = content}),
	})
end
function UI.mount(context)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CollectorUI" gui.ResetOnSpawn = false gui.DisplayOrder = 30
	gui.IgnoreGuiInset = true gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer.PlayerGui
	local root = ReactRoblox.createRoot(gui)
	local handle = {Snapshot = nil, Active = nil, View = nil, Serial = 0, Pending = nil, EggId = "Common", Hidden = false}
	local render
	local function request(command, value, extra)
		if handle.Pending then return end
		handle.Pending = command
		handle.PendingAt = os.clock()
		context.send(command, value, extra)
		render()
		local requestAt = handle.PendingAt
		task.delay(5, function()
			if handle.PendingAt == requestAt and handle.Pending then handle.Pending = nil render() end
		end)
	end
	local function App()
		local area, setArea = React.useState(Vector2.zero)
		local data = handle.Snapshot and handle.Snapshot.data
		local view = handle.View
		local children = {}
		local function open(name) context.open(name) end
		local navVisible = not handle.Hidden and (view == nil or handle.Active ~= nil) and (not data or not data.settings.hideHUD)
		if navVisible and area.X > 0 then
			local compact = area.Y < 520 or area.X < 750
			local size = compact and 60 or 74
			local navItems = {}
			local entries = view and {navigation[1], navigation[2], navigation[3], navigation[4]} or navigation
			for i, item in entries do
				local x, y
				if compact or view then x, y = (i - 1) * (size + 10), 0
				else x, y = ((i - 1) % 2) * (size + 10), math.floor((i - 1) / 2) * (size + 12) end
				navItems[item[1]] = e(U.Button, {Name = "Nav" .. item[1], Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(size, size),
					Color = T.Colors[item[1]] or T.Colors.Blue, Studs = true, OnActivated = function() open(item[1]) end,
					Children = {
						Art = e(U.Icon, {Kind = item[2], Position = UDim2.fromOffset(5, -2), Size = UDim2.fromOffset(size - 10, size - 18), ZIndex = 30}),
						Caption = e(U.Label, {Text = item[1], TextSize = size == 60 and 15 or 18, Position = UDim2.fromOffset(2, size - 26), Size = UDim2.fromOffset(size - 4, 24), ZIndex = 30}),
					}})
			end
			local horizontal = compact or view ~= nil
			local nw = horizontal and (#entries * (size + 10) - 10) or size * 2 + 10
			local navY = view and 8 or compact and 4 or math.max(85, math.floor(area.Y * 0.30))
			if nw > area.X - 24 then
				children.Navigation = e("ScrollingFrame", {Name = "Navigation", Position = UDim2.fromOffset(12, navY),
					Size = UDim2.fromOffset(area.X - 24, size + 10), CanvasSize = UDim2.fromOffset(nw, 0),
					ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 3, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 50}, navItems)
			else
				children.Navigation = e("Frame", {Name = "Navigation", Position = UDim2.new(horizontal and 0.5 or 0, horizontal and -math.floor(nw / 2) or 16, 0, navY),
					Size = UDim2.fromOffset(nw, horizontal and size or (size + 12) * 4), BackgroundTransparency = 1, ZIndex = 50}, navItems)
			end
		end
		if view and data and area.X > 120 and area.Y > 160 then
			local compact = area.X < 750 or area.Y < 520
			local w = math.floor(math.min(1040, area.X - 40))
			local h = math.floor(math.min(650, area.Y - (compact and 100 or 128)))
			h = math.max(180, h)
			local short = h - 100 < 420
			local ownScroll = view.Kind == "Shop" or view.Kind == "Trails"
			local contentHeight = ownScroll and (h - 100) or math.max(420, h - 100)
			if short and view.Kind == "Pets" then
				local columns = w - 40 < 380 and 2 or 3
				contentHeight = math.ceil(math.max(9, #data.pets) / columns) * 152 + 86
			end
			local props = {Data = data, Width = w - 40, Height = contentHeight, Request = request, Busy = handle.Pending ~= nil,
				Reduced = data.settings.effects == false, Short = short, EggId = handle.EggId, Open = open, Close = context.close,
				SelectEgg = function(id) handle.EggId = id context.selectEgg(id) render() end, Hatched = view.Hatched}
			local kind = view.Kind
			local title = kind == "Hatch" and "Your new pets!" or kind
			local serial = view.Serial
			children.Blocker = e("TextButton", {Name = "ModalBlocker", Text = "", AutoButtonColor = false,
				BackgroundColor3 = Color3.new(0.02, 0.04, 0.09), BackgroundTransparency = 0.34,
				Size = UDim2.fromScale(1, 1), ZIndex = 25, Modal = true})
			children.Window = e(Window, {key = kind .. serial, Kind = kind, Title = title, Width = w, Height = h,
				Visible = handle.Active ~= nil, Reduced = props.Reduced, Close = context.close,
				Settled = function() if handle.Serial == serial and handle.Active == nil then handle.View = nil render() end end,
				Children = {Screen = contentHeight > h - 100 and e(U.Scroll, {Name = "CompactScreenScroll", Size = UDim2.fromOffset(w - 40, h - 100),
					Height = contentHeight + 6, Children = {Screen = e(Screens[kind], props)}}) or e(Screens[kind], props)},
			})
		end
		return e(U.MotionContext.Provider, {value = data and data.settings.effects == false}, {
			Area = e("Frame", {Name = "SafeArea", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
				[React.Change.AbsoluteSize] = function(instance) setArea(instance.AbsoluteSize) end}, children),
		})
	end
	render = function() if not handle.Destroyed and gui.Parent then root:render(e(App)) end end
	function handle:update(snapshot)
		self.Snapshot = snapshot self.Pending = nil render()
	end
	function handle:request(command, value, extra) request(command, value, extra) end
	function handle:setHidden(hidden) if self.Hidden == hidden then return end self.Hidden = hidden render() end
	function handle:open(kind, eggId)
		self.Serial += 1 self.Active = kind self.Pending = nil
		if eggId then self.EggId = eggId end
		self.View = {Kind = kind, Serial = self.Serial}
		render()
	end
	function handle:close()
		self.Active = nil self.Pending = nil render()
	end
	function handle:hatch(pets)
		self.Serial += 1 self.Active = "Hatch" self.Pending = nil
		self.View = {Kind = "Hatch", Serial = self.Serial, Hatched = pets}
		render()
	end
	function handle:destroy()
		if self.Destroyed then return end
		self.Destroyed = true self.Pending = nil root:unmount() gui:Destroy()
	end
	render()
	return handle
end
return UI
