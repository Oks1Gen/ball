--!strict
-- Reusable Studio UI artwork: the existing studs image, real text and gradients.
local React = require(game.ReplicatedStorage.Packages.React)
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local Assets = require(script.Parent.Parent.UIAssets)
local e = React.createElement
local Bubble = {}
local C = Color3.fromRGB
local INK = C(0, 0, 0)
local WHITE = C(255, 255, 255)
local palettes = {
	{ C(99, 240, 255), C(15, 135, 255) },
	{ C(255, 140, 239), C(178, 49, 255) },
	{ C(226, 255, 92), C(42, 205, 98) },
	{ C(255, 222, 93), C(255, 103, 63) },
	{ C(193, 169, 255), C(89, 74, 243) },
}

function Bubble.caption(definition: any): string
	return if definition.product then "x" .. definition.multiplier else string.format("x%.1f", definition.multiplier)
end

function Bubble.color(definition: any): Color3
	return if definition.product then C(255, 126, 233) else palettes[definition.color][1]
end

local function round()
	return e("UICorner", { CornerRadius = UDim.new(0.5, 0) })
end

function Bubble.face(p: any)
	return e("Frame", {
		Name = "BubbleFace",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.88, 0.88),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {
		Round = round(),
		Outline = e("UIStroke", {
			Color = INK,
			Thickness = p.diameter:map(function(d: number)
				return math.max(3, d * 0.035)
			end),
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Gradient = e("UIGradient", {
			Rotation = 90,
			Color = p.definition:map(function(def: any)
				if def.product then
					return ColorSequence.new({
						ColorSequenceKeypoint.new(0, C(255, 99, 139)),
						ColorSequenceKeypoint.new(0.2, C(255, 212, 76)),
						ColorSequenceKeypoint.new(0.4, C(136, 245, 104)),
						ColorSequenceKeypoint.new(0.6, C(68, 218, 255)),
						ColorSequenceKeypoint.new(0.8, C(149, 112, 255)),
						ColorSequenceKeypoint.new(1, C(255, 104, 219)),
					})
				end
				local colors = palettes[def.color]
				return ColorSequence.new(colors[1], colors[2])
			end),
		}),
		Studs = e("ImageLabel", {
			Name = "Studs",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = p.studs,
			ImageTransparency = 0.56,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = p.diameter:map(function(d: number)
				return UDim2.fromOffset(d / 3, d / 3)
			end),
			ZIndex = 2,
		}, { Round = round() }),
		Multiplier = e("TextLabel", {
			Name = "Multiplier",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = p.definition:map(function(def: any)
				return UDim2.fromScale(0.5, if def.product then 0.43 else 0.5)
			end),
			Size = UDim2.fromScale(0.94, 0.53),
			BackgroundTransparency = 1,
			Text = p.definition:map(Bubble.caption),
			Font = Enum.Font.GothamBlack,
			TextColor3 = WHITE,
			TextScaled = true,
			ZIndex = 3,
		}, {
			Outline = e("UIStroke", {
				Color = INK,
				Thickness = p.diameter:map(function(d: number)
					return math.max(2.5, d * 0.027)
				end),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			}),
		}),
		Paid = e("Frame", {
			Name = "RobuxOnly",
			Position = UDim2.fromScale(0.17, 0.67),
			Size = UDim2.fromScale(0.66, 0.17),
			BackgroundTransparency = 1,
			Visible = p.definition:map(function(def: any)
				return def.product ~= nil
			end),
			ZIndex = 4,
		}, {
			Icon = e("ImageLabel", {
				Size = UDim2.fromScale(0.22, 1),
				BackgroundTransparency = 1,
				Image = Assets.Images.Robux,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 4,
			}),
			Label = e("TextLabel", {
				Position = UDim2.fromScale(0.24, 0),
				Size = UDim2.fromScale(0.76, 1),
				BackgroundTransparency = 1,
				Text = "ROBUX",
				Font = Enum.Font.GothamBlack,
				TextColor3 = WHITE,
				TextScaled = true,
				ZIndex = 4,
			}, { Outline = e("UIStroke", { Color = INK, Thickness = 1.5 }) }),
		}),
	})
end

function Bubble.Button(p: any)
	local button, visual = React.useRef(nil), React.useRef(nil)
	React.useEffect(function()
		return Motion.button(button.current :: any, visual.current :: any)
	end, {})
	return e("TextButton", {
		ref = button,
		Name = "BoostTarget",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = p.position,
		Size = p.diameter:map(function(d: number)
			return UDim2.fromOffset(d, d)
		end),
		BackgroundTransparency = 1,
		Visible = p.shown,
		Active = p.ready,
		Selectable = true,
		ZIndex = 1,
		[React.Event.Activated] = p.press,
	}, {
		Visual = e("Frame", {
			ref = visual,
			Name = "ButtonVisual",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, { Face = Bubble.face(p) }),
	})
end

return Bubble
