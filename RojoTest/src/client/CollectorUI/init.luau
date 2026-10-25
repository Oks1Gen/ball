--!strict
local Players = game:GetService("Players")
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local _Config = require(game.ReplicatedStorage.Shared.GameConfig)
local U = require(script.Components)
local T = require(script.Theme)
local Screens = require(script.Screens)
local GuiInsets = require(script.Parent.Modules.GuiInsets)
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local MotionConfig = require(game.ReplicatedStorage.Shared.UiMotionConfig)
local Presentation = require(script.Parent.Modules.UiPresentation)
local InventoryTabs = require(script.InventoryTabs)
local InventoryWindow = require(script.InventoryWindow)
local InventoryPages = require(script.InventoryPages)
local e = React.createElement
local UI = {}
-- ReactRoblox mounts the children of an element in the hash order of the
-- props table, so the stacking of the canvas must never depend on the order
-- of the keys: every layer carries its own ZIndex. The dim behind the window
-- stays below the window, the window stays below the tab bar.
local LAYER_BLOCKER = 25
local LAYER_WINDOW = 30
local LAYER_NAVIGATION = 50
local navigation = {
	{ "Shop", "Shop" },
	{ "Pets", "Pets" },
	{ "Rebirth", "Rebirth" },
	{ "Eggs", "Egg" },
	{ "Trails", "Trails" },
	{ "Inventory", "Ball", "Balls" },
	{ "Gifts", "Gifts" },
}
-- The windows of the collector are copies of the Settings and Balls panels:
-- a translucent slate plate of a fixed size in the 1280x720 design space of
-- the HUD, with the heading floating over the upper edge, the icon over the
-- left corner and the red cross of the game over the right one.
local WINDOW_WIDTH = 680
local WINDOW_HEIGHT = 470
local WINDOW_MARGIN = MotionConfig.Window.ChromeMargin

type WindowProps = {
	Kind: string,
	Title: string,
	Width: number,
	Height: number,
	DesignScale: number,
	CenterX: number,
	CenterY: number,
	Visible: boolean,
	Reduced: boolean,
	Close: () -> (),
	Settled: () -> (),
	Children: { [string]: any },
	Phone: boolean,
}

local function Window(p: WindowProps)
	local groupRef = React.useRef(nil)
	local animation: any = React.useRef(nil)
	local latest = React.useRef(p)
	latest.current = p
	React.useEffect(function()
		local group = groupRef.current
		if not group then
			return function() end
		end
		animation.current = Motion.window(group, 1, function()
			return latest.current.Reduced
		end)
		return function()
			animation.current.destroy()
			animation.current = nil
		end
	end, {})
	React.useEffect(function()
		if animation.current then
			animation.current.setOpen(p.Visible, function()
				if not latest.current.Visible then
					latest.current.Settled()
				end
			end)
		end
	end, { p.Visible, p.Reduced })
	local w, h = p.Width, p.Height
	local iconSize = p.Phone and 64 or 100
	local closeSize = p.Phone and 44 or 60
	local margin = WINDOW_MARGIN
	local chrome = {
		Icon = e(U.Icon, {
			-- The corner icon of the reference panels: it hangs over the top
			-- left corner of the plate.
			Kind = (p.Kind == "Eggs" or p.Kind == "Hatch") and "Egg" or p.Kind,
			Position = UDim2.fromOffset(WINDOW_MARGIN, WINDOW_MARGIN),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(iconSize, iconSize),
			ZIndex = 20,
		}),
		Title = e(U.Label, {
			Name = "Title",
			Text = p.Title,
			-- The heading of the reference panels stands half above the upper
			-- edge of the plate and keeps the corners clear for the icon and
			-- the cross.
			Position = UDim2.fromOffset(WINDOW_MARGIN + (p.Phone and 64 or 85), WINDOW_MARGIN - (p.Phone and 38 or 50)),
			Size = UDim2.fromOffset(w - (p.Phone and 128 or 170), p.Phone and 44 or 66),
			TextSize = p.Phone and 34 or T.TitleSize,
			Scaled = true,
			MinTextSize = T.TitleMin,
			MaxTextSize = p.Phone and 34 or T.TitleSize,
			ZIndex = 20,
		}),
		Close = e(U.CloseButton, {
			-- The cross of the reference panels hangs half above the top right
			-- corner of the plate.
			Position = UDim2.fromOffset(WINDOW_MARGIN + w, WINDOW_MARGIN),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(closeSize, closeSize),
			OnActivated = p.Close,
			ZIndex = 20,
		}),
	}
	-- The plate inside the group carries a margin, so the chrome can hang over
	-- the plate edges without being clipped by the group.
	local frameW, frameH = w + margin * 2, h + margin * 2
	local realW = math.round(frameW * p.DesignScale)
	local realH = math.round(frameH * p.DesignScale)
	return e("CanvasGroup", {
		ref = groupRef,
		Name = "CollectorWindow",
		Size = UDim2.fromOffset(realW, realH),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(math.round(p.CenterX), math.round(p.CenterY)),
		Interactable = p.Visible,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = LAYER_WINDOW,
	}, {
		Design = e("Frame", {
			Name = "Design",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(frameW, frameH),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = LAYER_WINDOW,
		}, {
			-- The design pixels of the reference panels become real ones at
			-- the same factor the HUD board uses.
			Fit = e("UIScale", { Scale = p.DesignScale }),
			Zoom = e("Frame", {
				Name = "Zoom",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(frameW, frameH),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = LAYER_WINDOW,
			}, {
				-- The plate of the reference panels: a translucent slate fill
				-- with a two pixel ink edge and squared corners.
				Shell = e("Frame", {
					Name = "WindowShell",
					Position = UDim2.fromOffset(margin, margin),
					Size = UDim2.fromOffset(w, h),
					BackgroundColor3 = T.Body,
					BackgroundTransparency = p.Kind == "Hatch" and 1 or 0.3,
					BorderSizePixel = 0,
					ZIndex = 1,
				}, {
					Edge = p.Kind ~= "Hatch" and e("UIStroke", {
						Thickness = T.WindowStroke,
						Color = T.Outline,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}) or nil,
					Content = e("Frame", {
						Name = "ScreenContent",
						Position = UDim2.fromOffset(12, p.Phone and 28 or 68),
						Size = UDim2.fromOffset(w - 24, h - (p.Phone and 40 or 80)),
						BackgroundTransparency = 1,
						ZIndex = 10,
					}, p.Children),
				}),
				-- The chrome hangs over the shell: the icon over the top left
				-- corner, the heading over the top edge and the cross over the
				-- top right one. A table of children has to be spread over the
				-- parent: a nested table is not a valid child.
				Icon = chrome.Icon,
				Title = chrome.Title,
				Close = chrome.Close,
			}),
		}),
	})
end

local function Navigation(p)
	local ref = React.useRef(nil)
	local animation: any = React.useRef(nil)
	React.useEffect(function()
		if not ref.current then
			return function() end
		end
		animation.current = Motion.slide(ref.current, "Left")
		animation.current.setHidden(p.Hidden, p.Reduced)
		return function()
			animation.current.destroy()
			animation.current = nil
		end
	end, {})
	React.useEffect(function()
		if animation.current then
			animation.current.setHidden(p.Hidden, p.Reduced)
		end
	end, { p.Hidden, p.Reduced })
	return e(
		"Frame",
		{ Name = "Navigation", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = LAYER_NAVIGATION },
		{
			Slide = e("Frame", {
				ref = ref,
				Name = "Left",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = LAYER_NAVIGATION,
			}, {
				Content = e(
					"Frame",
					{ Position = p.Position, Size = p.Size, BackgroundTransparency = 1, ZIndex = LAYER_NAVIGATION },
					p.Children
				),
			}),
		}
	)
end

function UI.mount(context)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CollectorUI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 30
	GuiInsets.prepare(gui)
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer.PlayerGui
	local root = ReactRoblox.createRoot(gui)
	local handle = {
		Snapshot = nil,
		Active = nil,
		View = nil,
		Exiting = {},
		Serial = 0,
		Pending = nil,
		EggId = "Common",
		BallId = nil,
		SelectedPet = nil,
		Hidden = false,
		ModalOpen = false,
	}
	local render
	local function request(command, value, extra)
		if handle.Pending then
			return
		end
		handle.Pending = command
		handle.PendingAt = os.clock()
		context.send(command, value, extra)
		render()
		local requestAt = handle.PendingAt
		task.delay(5, function()
			if handle.PendingAt == requestAt and handle.Pending then
				handle.Pending = nil
				render()
			end
		end)
	end
	local function App()
		local area, setArea = React.useState(Vector2.zero)
		local inset, setInset = React.useState(Vector2.zero)
		local screenCenter, setScreenCenter = React.useState(Vector2.zero)
		local data = handle.Snapshot and handle.Snapshot.data
		local inventory = handle.Snapshot and handle.Snapshot.inventory
		local activeView = handle.View
		local children = {}
		local function open(name)
			context.open(name)
		end
		local reduced = data and data.settings.effects == false or false
		gui:SetAttribute("ReducedMotion", reduced)
		if area.X > 0 then
			local phone = game:GetService("UserInputService").TouchEnabled and area.Y < 520
			local size = if phone
				then math.clamp(math.floor(area.Y * 0.1), 44, 88)
				else math.clamp(math.floor(area.Y * 0.132), 52, 144)
			-- Reserve room for both neighbours at full hover during a fast cursor move.
			local gap = phone and area.Y < 300 and 4
				or math.max(
					MotionConfig.Navigation.MinimumGap,
					math.ceil(size * (MotionConfig.Button.MaximumScale - 1)) + MotionConfig.Navigation.HoverClearance
				)
			local width = size * 2 + gap
			local banner = math.max(phone and 44 or 36, math.floor(size * 0.62))
			local captionHeight = math.max(22, math.floor(size * 0.3))
			local navItems = {}
			for i, item in navigation do
				local shop = i == 1
				local index = i - 2
				local x = shop and 0 or index % 2 * (size + gap)
				local y = shop and 0 or banner + gap + math.floor(index / 2) * (size + gap)
				local bw, bh = shop and width or size, shop and banner or size
				navItems[item[1]] = e(U.Button, {
					Name = "Nav" .. item[1],
					Position = UDim2.fromOffset(x, y),
					Size = UDim2.fromOffset(bw, bh),
					Color = shop and T.Colors.Gold or Color3.fromRGB(77, 80, 76),
					Studs = shop,
					Transparency = 0.3,
					NoShadow = true,
					OnActivated = function()
						open(item[1])
					end,
					Children = {
						Ready = item[1] == "Gifts" and Presentation.readyGifts(handle.Snapshot) > 0 and e(U.Surface, {
							Name = "ReadyGifts",
							Position = UDim2.new(1, -22, 0, -6),
							Size = UDim2.fromOffset(24, 24),
							Color = T.Colors.Red,
							Radius = 12,
							Quiet = true,
							NoShadow = true,
							ZIndex = 40,
							Children = {
								Count = e(U.Label, {
									Text = tostring(Presentation.readyGifts(handle.Snapshot)),
									TextSize = 16,
									ZIndex = 45,
								}),
							},
						}) or nil,
						Art = e(U.Icon, {
							Kind = item[2],
							Position = UDim2.fromOffset(shop and 2 or 3, shop and -3 or 1),
							Size = UDim2.fromOffset(shop and banner + 8 or size - 6, shop and banner + 6 or size - 16),
							ZIndex = 30,
						}),
						Caption = e(U.Label, {
							Text = item[3] or item[1],
							Scaled = true,
							MinTextSize = 11,
							TextSize = shop and math.floor(size * 0.37) or math.max(13, math.floor(size * 0.29)),
							Position = shop and UDim2.fromOffset(banner + 5, 0)
								or UDim2.fromOffset(1, size - captionHeight + 1),
							Size = shop and UDim2.fromOffset(width - banner - 8, banner)
								or UDim2.fromOffset(size - 2, captionHeight),
							ZIndex = 31,
						}),
					},
				})
			end
			local totalH = banner + 3 * (size + gap)
			local navY = phone and (area.Y < 300 and 0 or 8)
				or math.min(math.floor(area.Y * 0.36), math.max(62, area.Y * 0.76 - totalH))
			children.Navigation = e(Navigation, {
				Hidden = handle.Hidden or handle.ModalOpen,
				Reduced = reduced,
				Position = UDim2.fromOffset(12, navY),
				Size = UDim2.fromOffset(width, totalH),
				BackgroundTransparency = 1,
				ZIndex = LAYER_NAVIGATION,
				Children = navItems,
			})
		end

		local views = table.clone(handle.Exiting)
		if activeView then
			views[activeView.Serial] = activeView
		end
		for _, windowView in views do
			local view = windowView
			if data and area.X > 120 and area.Y > 160 then
				-- The window is built in the design space of the reference panels:
				-- the plate is 680x470 and the HUD board scales it to the screen.
				local phone = game:GetService("UserInputService").TouchEnabled and area.Y < 520
				local designScale = phone and 1 or math.max(0.05, math.min(area.X / 1280, area.Y / 720))
				local collection = view.Kind == "Collection"
				local w = phone and math.min(collection and 900 or 680, area.X - (collection and 144 or 64))
					or (collection and 940 or WINDOW_WIDTH)
				local h = phone and math.max(227, area.Y - (collection and 72 or 96)) or WINDOW_HEIGHT
				local factor = phone and 1
					or math.min(
						1,
						(area.X - 24) / ((w + WINDOW_MARGIN * 2 + (collection and 164 or 0)) * designScale),
						(area.Y - 24) / ((h + WINDOW_MARGIN * 2) * designScale)
					)
				local centerY = screenCenter.Y
				-- The screen fills the plate. Only the collection grid asks for
				-- more room than it gets: its rows have a height of their own.
				local baseH = h - (collection and (phone and 50 or 76) or (phone and 40 or 80))
				local contentHeight = baseH
				local short = baseH < 420
				local props = {
					Data = data,
					Phone = phone,
					Inventory = inventory or { pets = {}, equipped = {} },
					Width = w - 24 - (collection and (phone and 104 or 164) or 0),
					Height = contentHeight,
					Request = request,
					Busy = handle.Pending ~= nil,
					Reduced = data.settings.effects == false,
					Short = short,
					EggId = handle.EggId,
					UnifiedInventory = collection,
					BallId = handle.BallId,
					SelectedPet = handle.SelectedPet,
					SelectBall = function(id)
						handle.BallId = id
						render()
					end,
					SelectPet = function(id)
						handle.SelectedPet = id
						render()
					end,
					Open = open,
					Close = context.close,
					SelectEgg = function(id)
						handle.EggId = id
						context.selectEgg(id)
						render()
					end,
					Hatched = view.Hatched,
				}
				local kind = view.Kind
				local title = kind == "Hatch" and "Your new pets!" or kind == "Pets" and "My Pets" or kind
				local serial = view.Serial
				-- The blocker lives only while a screen is open: a modal dim that
				-- outlives the close would swallow every click of the game.
				if view then
					children.Blocker = e("TextButton", {
						Name = "ModalBlocker",
						Text = "",
						AutoButtonColor = false,
						-- The reference panels do not dim the world: the blur and the
						-- translucent plate do the work, the blocker only swallows
						-- the clicks around the window.
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						-- Below the window: a modal dim in front of the window would
						-- swallow every click on the content underneath it.
						ZIndex = LAYER_BLOCKER,
						Modal = true,
					})
				end
				local page = collection and (InventoryPages[view.Tab] or Screens[view.Tab]) or Screens[kind]
				children["Window" .. serial] = e(collection and InventoryWindow or Window, {
					key = kind .. serial,
					Kind = kind,
					Tab = view.Tab,
					SelectTab = function(route)
						local nextTab = InventoryTabs.resolve(route)
						if nextTab and nextTab.Id ~= view.Tab then
							open(route)
						end
					end,
					Phone = phone,
					Title = title,
					Width = w,
					Height = h,
					DesignScale = designScale * factor,
					CenterX = screenCenter.X,
					CenterY = centerY,
					Visible = handle.Active ~= nil and handle.View == view,
					Reduced = props.Reduced,
					Close = context.close,
					Settled = function()
						if handle.View == view and handle.Active == nil then
							handle.View = nil
						elseif handle.View ~= view then
							handle.Exiting[serial] = nil
						end
						render()
					end,
					Children = {
						Screen = contentHeight > baseH and e(U.Scroll, {
							Name = "CompactScreenScroll",
							Size = UDim2.fromOffset(w - 24, baseH),
							Height = contentHeight + 6,
							Children = { Screen = e(page, props) },
						}) or e(page, props),
					},
				})
			end
		end
		return e(U.MotionContext.Provider, { value = data and data.settings.effects == false }, {
			Area = e("Frame", {
				Name = "SafeArea",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				[React.Change.AbsoluteSize] = function(instance: Frame)
					local viewport = workspace.CurrentCamera.ViewportSize
					local safe = GuiInsets.area(viewport, instance)
					setArea(safe.size)
					setInset(safe.offset)
					setScreenCenter(GuiInsets.screenCenter(viewport) - instance.AbsolutePosition - safe.offset)
				end,
			}, {
				Inset = e("Frame", {
					Name = "Inset",
					Position = UDim2.fromOffset(inset.X, inset.Y),
					Size = UDim2.fromOffset(math.max(1, area.X), math.max(1, area.Y)),
					BackgroundTransparency = 1,
				}, children),
			}),
		})
	end
	render = function()
		if not handle.Destroyed and gui.Parent then
			root:render(e(App))
		end
	end
	function handle:update(snapshot)
		self.Snapshot = snapshot
		self.Pending = nil
		render()
	end
	function handle:request(command, value, extra)
		request(command, value, extra)
	end
	function handle:setModalOpen(value)
		if self.ModalOpen == value then
			return
		end
		self.ModalOpen = value
		render()
	end
	function handle:setHidden(hidden)
		if self.Hidden == hidden then
			return
		end
		self.Hidden = hidden
		render()
	end
	function handle:open(kind, eggId)
		local tab = InventoryTabs.resolve(kind)
		if tab then
			if tab.Id == "Eggs" and eggId then
				self.EggId = eggId
			elseif tab.Id == "Balls" and eggId then
				self.BallId = eggId
			end
			eggId = nil
			if self.View and self.View.Kind == "Collection" then
				self.View.Tab = tab.Id
				self.Active = "Collection"
				self.Pending = nil
				render()
				return
			end
			kind = "Collection"
		end
		if self.View and self.View.Kind == kind then
			self.Active = kind
			if eggId then
				self.EggId = eggId
			end
			render()
			return
		end
		if self.View then
			self.Exiting[self.View.Serial] = self.View
		end
		for serial, previous in self.Exiting do
			if previous.Kind == kind then
				self.Exiting[serial] = nil
				self.View = previous
				previous.Tab = tab and tab.Id or nil
				self.Active = kind
				if eggId then
					self.EggId = eggId
				end
				render()
				return
			end
		end
		self.Serial += 1
		self.Active = kind
		self.Pending = nil
		if eggId then
			self.EggId = eggId
		end
		self.View = { Kind = kind, Serial = self.Serial, Tab = tab and tab.Id or nil }
		render()
	end
	function handle:isInventoryOpen()
		return self.Active == "Collection"
	end
	function handle:close()
		-- The view is cleared by the settle callback of the window, not here:
		-- clearing it now would skip the close animation.
		self.Active = nil
		self.Pending = nil
		render()
	end
	function handle:hatch(pets)
		if self.View then
			self.Exiting[self.View.Serial] = self.View
		end
		self.Serial += 1
		self.Active = "Hatch"
		self.Pending = nil
		self.View = { Kind = "Hatch", Serial = self.Serial, Hatched = pets }
		render()
	end
	function handle:destroy()
		if self.Destroyed then
			return
		end
		self.Destroyed = true
		self.Pending = nil
		root:unmount()
		gui:Destroy()
	end
	render()
	return handle
end
return UI
