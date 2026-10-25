--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local U = require(script.Parent.Components)
local T = require(script.Parent.Theme)
local Tabs = require(script.Parent.InventoryTabs)
local e = React.createElement
local C = Color3.fromRGB
local Spacing = require(game.ReplicatedStorage.Shared.UiSpacing)
local Ripple = require(game.ReplicatedStorage.Packages.Ripple)

local function PageTransition(p: any): any
	local ref: any = React.useRef(nil)
	React.useEffect(function()
		local motion = Ripple.createMotion(p.Reduced and 0 or 1, { start = true })
		local disconnect = motion:onChange(function(value)
			if ref.current then
				ref.current.GroupTransparency = math.clamp(value, 0, 1)
				ref.current.Position = UDim2.fromOffset(p.X + value * 10, p.Y)
			end
		end)
		motion:tween(0, { duration = p.Reduced and 0 or 0.22, easing = "sineOut" })
		return function()
			disconnect()
			motion:destroy()
		end
	end, { p.Tab, p.Reduced, p.X, p.Y })
	return e("CanvasGroup", {
		ref = ref,
		Name = "InventoryPageTransition",
		Position = UDim2.fromOffset(p.X, p.Y),
		Size = p.Size,
		BackgroundTransparency = 1,
	}, {
		Page = e("Frame", {
			Name = "InventoryPage",
			Position = UDim2.fromOffset(16, 16),
			Size = UDim2.new(1, -32, 1, -32),
			BackgroundTransparency = 1,
		}, p.Children),
	})
end

return function(p: any): any
	local ref: any = React.useRef(nil)
	local animation: any = React.useRef(nil)
	local latest: any = React.useRef(p)
	latest.current = p
	React.useEffect(function()
		animation.current = Motion.window(ref.current, 1, function()
			return latest.current.Reduced
		end)
		return function()
			animation.current.destroy()
		end
	end, {})
	React.useEffect(function()
		animation.current.setOpen(p.Visible, function()
			if not latest.current.Visible then
				latest.current.Settled()
			end
		end)
	end, { p.Visible, p.Reduced })
	local margin = 70
	local w, h = p.Width, p.Height
	local side = p.Phone and 104 or 164
	local mainW = w - side
	local tab = Tabs.resolve(p.Tab) or Tabs.Entries[1]
	local tabW = side - 24
	local tabH = p.Phone and 52 or 82
	local tabGap = Spacing.gap(tabW) + 8
	local tabs: any = {}
	for i, item in Tabs.Entries do
		local selected = item.Id == tab.Id
		tabs[item.Id] = e(U.Button, {
			Name = "InventoryTab" .. item.Id,
			Position = UDim2.fromOffset(0, (p.Phone and 12 or 22) + (i - 1) * (tabH + tabGap)),
			Size = UDim2.fromOffset(tabW, tabH),
			Color = C(67, 84, 91),
			Transparency = 0.3,
			Quiet = true,
			BorderColor = selected and C(123, 222, 255) or T.Outline,
			Radius = 6,
			Studs = false,
			NoShadow = true,
			ZIndex = 12,
			OnActivated = function()
				p.SelectTab(item.Route)
			end,
			Children = {
				Icon = e(U.Icon, {
					Kind = item.Icon,
					Position = UDim2.fromOffset((tabW - tabH) / 2, -2),
					Size = UDim2.fromOffset(tabH, tabH - 9),
				}),
				Caption = e(U.Label, {
					Text = item.Id,
					Position = UDim2.fromOffset(2, tabH - (p.Phone and 24 or 32)),
					Size = UDim2.fromOffset(tabW - 4, p.Phone and 24 or 32),
					TextSize = p.Phone and 20 or 28,
					ZIndex = 32,
				}),
			},
		})
	end
	local header = p.Phone and 38 or 64
	return e("CanvasGroup", {
		ref = ref,
		Name = "InventoryWindow",
		-- Symmetric space around the working shell keeps its centre fixed even during zoom.
		Size = UDim2.fromOffset((w + side + margin * 2) * p.DesignScale, (h + margin * 2) * p.DesignScale),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(p.CenterX, p.CenterY),
		BackgroundTransparency = 1,
		Interactable = p.Visible,
		ZIndex = 30,
	}, {
		Design = e("Frame", {
			Name = "Design",
			Size = UDim2.fromOffset(w + side + margin * 2, h + margin * 2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			Scale = e("UIScale", { Scale = p.DesignScale }),
			Content = e("Frame", {
				Position = UDim2.fromOffset(margin, margin),
				Size = UDim2.fromOffset(w, h),
				BackgroundTransparency = 1,
			}, {
				Tabs = e("Frame", {
					Name = "InventoryTabs",
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(side, h),
					ZIndex = 12,
				}, tabs),
				Shell = e(U.Surface, {
					Name = "InventoryShell",
					Position = UDim2.fromOffset(side, 0),
					Size = UDim2.fromOffset(mainW, h),
					Color = C(67, 84, 91),
					Transparency = 0.3,
					Quiet = true,
					NoShadow = true,
					Radius = p.Phone and 14 or 20,
					Outline = 2.5,
					Children = {
						Page = e(PageTransition, {
							X = -4,
							Y = header - 16,
							Size = UDim2.fromOffset(mainW + 8, h - header + 20),
							Tab = p.Tab,
							Reduced = p.Reduced,
							Children = p.Children,
						}),
					},
				}),
				Icon = e(U.Icon, {
					Kind = tab.Icon,
					Position = UDim2.fromOffset(side, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(p.Phone and 64 or 92, p.Phone and 64 or 92),
					ZIndex = 40,
				}),
				Title = e(U.Label, {
					Name = "InventoryTitle",
					Text = tab.Title,
					Position = UDim2.fromOffset(side + (p.Phone and 66 or 94), p.Phone and -28 or -47),
					Size = UDim2.fromOffset(mainW - (p.Phone and 118 or 172), p.Phone and 40 or 68),
					TextSize = p.Phone and 34 or 61,
					Scaled = true,
					ZIndex = 40,
				}),
				Close = e(U.CloseButton, {
					Position = UDim2.fromOffset(w, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(p.Phone and 48 or 64, p.Phone and 48 or 64),
					OnActivated = p.Close,
					ZIndex = 40,
				}),
			}),
		}),
	})
end
