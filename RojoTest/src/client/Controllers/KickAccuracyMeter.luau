--!strict
-- Second-stage artwork only. The original vertical meter stays in KickTiming.
local React = require(game.ReplicatedStorage.Packages.React)
local Style = require(script.Parent.Parent.UiStyle)
local U = require(script.Parent.Parent.CollectorUI.Components)
local e = React.createElement

local function roundStroke(color: Color3, thickness: number)
	return {
		Corner = U.corner(1000),
		Stroke = e("UIStroke", { Color = color, Thickness = thickness }),
	}
end

return function(props: any)
	local compact = props.compact
	local centerY = if compact then 176 else 196
	local ringSize = props.height:map(function(h: number)
		local diameter = if compact then 96 - 24 * h else 140 - 40 * h
		return UDim2.fromOffset(diameter, diameter)
	end)
	local ringColor = props.height:map(function(h: number)
		return if h >= 1 then Style.Colors.Green else Style.Text
	end)
	return e("CanvasGroup", {
		Name = "AccuracyMeter",
		Visible = props.visible,
		Size = UDim2.fromOffset(176, 312),
		BackgroundTransparency = 1,
		GroupTransparency = props.progress:map(function(value: number)
			return 1 - math.clamp(value, 0, 1)
		end),
		ZIndex = 5,
	}, {
		Title = e(U.Label, {
			Text = "ACCURACY",
			Position = UDim2.fromOffset(0, 80),
			Size = UDim2.fromOffset(176, 24),
			TextSize = 18,
			ZIndex = 10,
		}),
		Maximum = e(U.Label, {
			Text = "×3",
			Position = UDim2.fromOffset(0, 103),
			Size = UDim2.fromOffset(176, 22),
			TextSize = 20,
			Color = Style.Colors.Green,
			ZIndex = 10,
		}),
		Target = e("Frame", {
			Name = "PerfectRing",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(88, centerY),
			Size = UDim2.fromOffset(if compact then 64 else 92, if compact then 64 else 92),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, {
			Corner = U.corner(1000),
			Stroke = e("UIStroke", { Color = Style.Ink, Thickness = if compact then 9 else 11 }),
			Face = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 7,
			}, roundStroke(Style.Colors.Green, if compact then 5 else 7)),
			InnerRim = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(if compact then 59 else 85, if compact then 59 else 85),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 8,
			}, roundStroke(Style.Colors.Green:Lerp(Style.Text, 0.5), 1)),
		}),
		Moving = e("Frame", {
			Name = "MovingRing",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(88, centerY),
			Size = ringSize,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 8,
		}, {
			Corner = U.corner(1000),
			Stroke = e("UIStroke", { Color = Style.Ink, Thickness = 5 }),
			Rim = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 9,
			}, {
				Corner = U.corner(1000),
				Stroke = e("UIStroke", { Color = ringColor, Thickness = 2 }),
			}),
			Dot = e("Frame", {
				Name = "RingDot",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.853553, 0.146447),
				Size = UDim2.fromOffset(9, 9),
				BackgroundColor3 = ringColor,
				BorderSizePixel = 0,
				ZIndex = 10,
			}, roundStroke(Style.Ink, 2)),
		}),
		Value = e(U.Label, {
			Name = "AccuracyMultiplier",
			Text = props.multiplier:map(function(value: number)
				return string.format("×%.2f", value)
			end),
			Position = UDim2.fromOffset(22, centerY - 20),
			Size = UDim2.fromOffset(132, 40),
			TextSize = if compact then 24 else 32,
			Color = ringColor,
			ZIndex = 10,
		}),
		Minimum = not compact and e(U.Label, {
			Text = "×0.5",
			Position = UDim2.fromOffset(0, if compact then 230 else 270),
			Size = UDim2.fromOffset(176, 22),
			TextSize = 20,
			Color = Style.Colors.Red,
			ZIndex = 10,
		}),
		Product = not compact and e(U.Label, {
			Name = "CombinedMultiplier",
			Text = props.product,
			Position = UDim2.fromOffset(0, if compact then 231 else 294),
			Size = UDim2.fromOffset(176, 18),
			TextSize = 14,
			Color = Style.Gold,
			ZIndex = 10,
		}),
	})
end
