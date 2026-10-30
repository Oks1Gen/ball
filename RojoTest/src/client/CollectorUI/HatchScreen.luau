--!strict
-- The clicked reveal covers the whole screen: the garden reaches under the bar
-- of the core UI, the stage is laid out in design units and scaled like the
-- windows.
local React = require(game.ReplicatedStorage.Packages.React)
local TweenService = game:GetService("TweenService")
local U = require(script.Parent.Components)
local Scenery = require(script.Parent.HatchScenery)
local HatchStage = require(script.Parent.HatchStage)
local e = React.createElement

type Props = {
	Area: Vector2,
	Inset: Vector2,
	Phone: boolean,
	Visible: boolean,
	Reduced: boolean,
	Stage: { [string]: any },
	Close: () -> (),
	Settled: () -> (),
}

return function(p: Props)
	local cover = React.useRef(nil :: Frame?)
	React.useEffect(function()
		-- No close animation: the view leaves as soon as it is hidden.
		if not p.Visible then
			p.Settled()
		end
	end, { p.Visible })
	React.useEffect(function()
		local frame = cover.current
		if frame == nil or p.Reduced then
			return function() end
		end
		-- The garden opens out of a white flash.
		frame.BackgroundTransparency = 0
		local tween = TweenService:Create(
			frame,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		tween:Play()
		return function()
			tween:Cancel()
		end
	end, {})
	local area = p.Area
	local scale = if p.Phone then math.min(1, area.Y / 460) else math.max(0.05, math.min(area.X / 1280, area.Y / 720))
	local w, h = math.floor(area.X / scale), math.floor(area.Y / scale)
	local stage = table.clone(p.Stage)
	stage.Width, stage.Height = w, h
	return e("Frame", {
		Name = "HatchScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Scenery.SkyTop,
		BorderSizePixel = 0,
		Active = true,
		Visible = p.Visible,
		ZIndex = 2,
	}, {
		Design = e("Frame", {
			Name = "HatchDesign",
			Position = UDim2.fromOffset(p.Inset.X, p.Inset.Y),
			Size = UDim2.fromOffset(w, h),
			BackgroundTransparency = 1,
			ZIndex = 1,
		}, {
			Fit = e("UIScale", { Scale = scale }),
			Stage = e(HatchStage, stage :: any),
			Close = e(U.CloseButton, {
				Name = "HatchClose",
				Position = UDim2.fromOffset(w - 40, 40),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(52, 52),
				OnActivated = p.Close,
				ZIndex = 40,
			}),
		}),
		Cover = e("Frame", {
			ref = cover,
			Name = "HatchOpenFlash",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = false,
			ZIndex = 3,
		}),
	})
end
