--!strict
-- A bounded, non-interactive screen burst with no rings or speed lines.
local React = require(game.ReplicatedStorage.Packages.React)
local Ripple = require(game.ReplicatedStorage.Packages.Ripple)
local Bubble = require(script.Parent.TrainingBoostBubble)
local e = React.createElement
local Feedback = {}

function Feedback.create(diameter: any, effects: () -> boolean, studs: string)
	local shown, setShown = React.createBinding(false)
	local position, setPosition = React.createBinding(UDim2.new())
	local progress, setProgress = React.createBinding(1)
	local definition, setDefinition = React.createBinding({ multiplier = 5, color = 1 })
	local reduced, setReduced = React.createBinding(false)
	local caption, setCaption = React.createBinding("")
	local motion = Ripple.createMotion(1, { start = true })
	local changed = motion:onChange(setProgress)
	local alive = true
	local completed = motion:onComplete(function()
		if alive then
			setShown(false)
		end
	end)
	local children: any = {
		Pop = e("CanvasGroup", {
			Name = "Pop",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = diameter:map(function(d: number)
				return UDim2.fromOffset(d, d)
			end),
			BackgroundTransparency = 1,
			ZIndex = 4,
			GroupTransparency = progress:map(function(t: number)
				return math.clamp((t - 0.28) / 0.36, 0, 1)
			end),
		}, {
			Scale = e("UIScale", {
				Scale = React.joinBindings({ progress, reduced }):map(function(v: any)
					local t = v[1]
					if v[2] then
						return 1
					end
					if t < 0.12 then
						return 1 - t / 0.12 * 0.18
					end
					if t < 0.3 then
						return 0.82 + (t - 0.12) / 0.18 * 0.38
					end
					return 1.2 - math.clamp((t - 0.3) / 0.34, 0, 1) * 0.95
				end),
			}),
			Face = Bubble.face({ diameter = diameter, definition = definition, studs = studs }),
		}),
		Reward = e("TextLabel", {
			Name = "BoostCaption",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = React.joinBindings({ progress, reduced }):map(function(v: any)
				return UDim2.new(0.5, 0, 0.5, if v[2] then -55 else -35 - v[1] * 65)
			end),
			Size = UDim2.fromOffset(270, 45),
			BackgroundTransparency = 1,
			Text = caption,
			Font = Enum.Font.GothamBlack,
			TextSize = 24,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = progress:map(function(t: number)
				return math.clamp((t - 0.65) / 0.35, 0, 1)
			end),
			ZIndex = 6,
		}, {
			Outline = e("UIStroke", {
				Color = Color3.new(),
				Thickness = 2.5,
				Transparency = progress:map(function(t: number)
					return math.clamp((t - 0.65) / 0.35, 0, 1)
				end),
			}),
		}),
	}
	for i = 1, 16 do
		local angle = i / 16 * math.pi * 2 + 0.12
		local distance = 62 + (i % 4) * 13
		children["Confetti" .. i] = e("Frame", {
			Name = "Confetti" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = progress:map(function(t: number)
				local reach = math.sin(math.min(t / 0.75, 1) * math.pi / 2) * distance
				return UDim2.new(0.5, math.cos(angle) * reach, 0.5, math.sin(angle) * reach + 56 * t * t)
			end),
			Size = UDim2.fromOffset(6 + i % 3 * 2, 6 + i % 3 * 2),
			BackgroundColor3 = Color3.fromHSV(i / 16, 0.65, 1),
			BackgroundTransparency = progress:map(function(t: number)
				return math.clamp((t - 0.45) / 0.55, 0, 1)
			end),
			BorderSizePixel = 0,
			Rotation = progress:map(function(t: number)
				return i * 27 + t * 210
			end),
			Visible = reduced:map(function(value: boolean)
				return not value
			end),
			ZIndex = 3,
		}, { Corner = e("UICorner", { CornerRadius = UDim.new(0.28, 0) }) })
	end
	return {
		element = e("Frame", {
			Name = "BoostHitFeedback",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = UDim2.fromOffset(360, 360),
			BackgroundTransparency = 1,
			Visible = shown,
			Active = false,
			Interactable = false,
			ZIndex = 10,
		}, children),
		play = function(at: UDim2, def: any, paid: boolean)
			if not alive then
				return
			end
			setPosition(at)
			setDefinition(def)
			setReduced(not effects())
			setCaption(if paid then "ROBUX BOOST" else "")
			motion:setPosition(0)
			setShown(true)
			motion:tween(1, { duration = if effects() then 0.7 else 0.18 })
		end,
		confirm = function(multiplier: number)
			if alive then
				setCaption(string.format("BOOST x%s!", tostring(multiplier)))
			end
		end,
		reduce = function()
			setReduced(true)
			motion:setPosition(1)
			setShown(false)
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
