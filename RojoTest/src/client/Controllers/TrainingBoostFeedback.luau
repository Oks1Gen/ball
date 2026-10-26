--!strict
-- Screen-space click feedback keeps the popped x2 bubble readable even when
-- its world-space aura is small, obscured by the net or outside the next frame.
local React = require(game.ReplicatedStorage.Packages.React)
local Ripple = require(game.ReplicatedStorage.Packages.Ripple)
local Style = require(script.Parent.Parent.UiStyle)
local e = React.createElement
local Feedback = {}

function Feedback.create(diameter: number, effects: () -> boolean)
	local shown, setShown = React.createBinding(false)
	local position, setPosition = React.createBinding(UDim2.new())
	local progress, setProgress = React.createBinding(1)
	local reduced, setReduced = React.createBinding(false)
	local motion = Ripple.createMotion(1, { start = true })
	local changed = motion:onChange(setProgress)
	local alive = true
	local completed = motion:onComplete(function()
		if alive then
			setShown(false)
		end
	end)
	local function round()
		return e("UICorner", { CornerRadius = UDim.new(0.5, 0) })
	end
	local children: any = {
		Bubble = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = React.joinBindings({ progress, reduced }):map(function(values: any)
				local size = if values[2] then diameter else math.max(8, math.round(diameter * (1 - values[1] * 0.84)))
				return UDim2.fromOffset(size, size)
			end),
			BackgroundColor3 = Style.Colors.Eggs,
			BackgroundTransparency = progress:map(function(value: number)
				return 0.08 + 0.92 * value
			end),
			BorderSizePixel = 0,
			ZIndex = 3,
		}, {
			Round = round(),
			Border = e("UIStroke", { Color = Color3.fromRGB(62, 18, 104), Thickness = 2.5 }),
			Shine = e("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.fromRGB(241, 213, 255), Color3.fromRGB(118, 65, 175)),
			}),
		}),
		Ring = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = progress:map(function(value: number)
				local size = diameter + math.round(72 * value)
				return UDim2.fromOffset(size, size)
			end),
			BackgroundTransparency = 1,
			Visible = reduced:map(function(value: boolean)
				return not value
			end),
			ZIndex = 2,
		}, {
			Round = round(),
			Stroke = e("UIStroke", {
				Color = Color3.fromRGB(215, 142, 255),
				Thickness = 2.5,
				Transparency = progress:map(function(value: number)
					return 0.05 + 0.95 * value
				end),
			}),
		}),
		-- The live text holds its physical size while the text-free bubble collapses.
		Label = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(diameter, diameter),
			BackgroundTransparency = 1,
			Text = "×2",
			Font = Enum.Font.GothamBlack,
			TextSize = 23,
			TextColor3 = Style.Text,
			TextStrokeColor3 = Color3.fromRGB(62, 18, 104),
			TextStrokeTransparency = 0,
			ZIndex = 4,
		}),
	}
	for i = 1, 6 do
		local angle = i / 6 * math.pi * 2
		children["Spark" .. i] = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = progress:map(function(value: number)
				local radius = diameter * 0.42 + value * 42
				return UDim2.new(0.5, math.round(math.cos(angle) * radius), 0.5, math.round(math.sin(angle) * radius))
			end),
			Size = UDim2.fromOffset(5, 5),
			BackgroundColor3 = Color3.fromRGB(231, 199, 255),
			BorderSizePixel = 0,
			Visible = reduced:map(function(value: boolean)
				return not value
			end),
			ZIndex = 2,
		}, { Round = round() })
	end
	return {
		element = e("CanvasGroup", {
			Name = "BoostHitFeedback",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = UDim2.fromOffset(diameter + 100, diameter + 100),
			BackgroundTransparency = 1,
			GroupTransparency = progress:map(function(value: number)
				return math.clamp((value - 0.35) / 0.65, 0, 1)
			end),
			Visible = shown,
			Active = false,
			Interactable = false,
			ZIndex = 10,
		}, children),
		play = function(at: UDim2)
			if not alive then
				return
			end
			setPosition(at)
			setReduced(not effects())
			motion:setPosition(0)
			setShown(true)
			motion:tween(1, { duration = if effects() then 0.34 else 0.18 })
		end,
		clear = function()
			setShown(false)
			motion:setPosition(1)
		end,
		destroy = function()
			alive = false
			changed()
			completed()
			motion:destroy()
		end,
	}
end

return Feedback
