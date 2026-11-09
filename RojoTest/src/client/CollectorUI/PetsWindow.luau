--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local U = require(script.Parent.Components)
local Controls = require(script.Parent.PetControls)
local e = React.createElement

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
	local margin = 50
	return e("CanvasGroup", {
		ref = ref,
		Name = "PetsWindow",
		Size = UDim2.fromOffset((p.Width + margin * 2) * p.DesignScale, (p.Height + margin * 2) * p.DesignScale),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(p.CenterX, p.CenterY),
		BackgroundTransparency = 1,
		Interactable = p.Visible,
		ZIndex = 30,
	}, {
		Design = e("Frame", {
			Name = "Design",
			Size = UDim2.fromOffset(p.Width + margin * 2, p.Height + margin * 2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			Scale = e("UIScale", { Scale = p.DesignScale }),
			Content = e("Frame", {
				Name = "Content",
				Position = UDim2.fromOffset(margin, margin),
				Size = UDim2.fromOffset(p.Width, p.Height),
				BackgroundTransparency = 1,
			}, {
				Shell = e(U.Surface, {
					Name = "InventoryShell",
					Size = UDim2.fromOffset(p.MainWidth, p.Height),
					Color = Color3.fromRGB(67, 84, 91),
					Transparency = 0.3,
					Quiet = true,
					NoShadow = true,
					Radius = 20,
					Outline = 2.5,
					Children = {
						Page = e("Frame", {
							Name = "InventoryPage",
							Position = UDim2.fromOffset(16, 64),
							Size = UDim2.fromOffset(p.MainWidth - 32, p.Height - 88),
							BackgroundTransparency = 1,
						}, p.Children),
					},
				}),
				Title = e(U.Label, {
					Name = "InventoryTitle",
					Text = "My Pets",
					Position = UDim2.fromOffset(166, -47),
					Size = UDim2.fromOffset(284, 70),
					TextSize = 66,
					Scaled = true,
					ZIndex = 40,
				}),
				Shards = e(Controls.Plate, {
					Name = "PetShards",
					Position = UDim2.fromOffset(p.MainWidth - 298, -23),
					Size = UDim2.fromOffset(190, 50),
					Color = Color3.fromRGB(255, 195, 32),
					ZIndex = 40,
					Children = {
						Icon = e(U.Icon, {
							Kind = "PetShard",
							Position = UDim2.fromOffset(6, 4),
							Size = UDim2.fromOffset(37, 39),
							ZIndex = 46,
						}),
						Text = e(U.Label, {
							Text = tostring(p.Shards) .. " Shards",
							Position = UDim2.fromOffset(44, 0),
							Size = UDim2.new(1, -50, 1, 0),
							TextSize = 26,
							Scaled = true,
							ZIndex = 46,
						}),
					},
				}),
				Close = e(U.CloseButton, {
					Position = UDim2.fromOffset(p.MainWidth - 22, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(60, 60),
					OnActivated = function()
						if p.Feedback then
							p.Feedback()
						end
						p.Close()
					end,
					ZIndex = 45,
				}),
			}),
		}),
	})
end
