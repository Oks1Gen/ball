--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local U = require(script.Parent.Components)
local e = React.createElement
local C = Color3.fromRGB
local Controls = {}
Controls.FeedbackContext = React.createContext(nil)
Controls.Cyan = C(0, 189, 245)
Controls.Ink = C(0, 42, 54)

-- These are plates, not baked screenshots: labels, state and icons stay live.
function Controls.Button(p: any): any
	local feedback = React.useContext(Controls.FeedbackContext)
	local props = table.clone(p)
	props.OnActivated = function()
		if feedback then
			feedback()
		end
		if p.OnActivated then
			p.OnActivated()
		end
	end
	props.Studs = false
	props.Shine = false
	props.Gloss = true
	props.Radius = p.Radius or 25
	props.BorderColor = Controls.Ink
	props.Outline = 3
	props.ShadowOffset = 9
	props.ShadowColor = Controls.Ink
	props.ShadowTransparency = 0.01
	props.Centered = true
	return e(U.Button, props)
end

function Controls.Plate(p: any): any
	local props = table.clone(p)
	props.Color = p.Color or Controls.Cyan
	props.Studs = false
	props.Shine = false
	props.Gloss = true
	props.Radius = p.Radius or 25
	props.BorderColor = Controls.Ink
	props.Outline = 3
	props.ShadowOffset = 7
	props.ShadowColor = Controls.Ink
	props.ShadowTransparency = 0.01
	return e(U.Surface, props)
end

function Controls.Action(p: any): any
	local feedback = React.useContext(Controls.FeedbackContext)
	return e(U.Button, {
		Name = p.Name,
		Position = p.Position,
		Size = p.Size,
		Disabled = p.Disabled,
		OnActivated = function()
			if feedback then
				feedback()
			end
			if p.OnActivated then
				p.OnActivated()
			end
		end,
		Transparency = 1,
		Outline = 0,
		Quiet = true,
		NoShadow = true,
		Studs = false,
		Children = {
			Icon = e(U.Icon, {
				Kind = p.Icon,
				Position = UDim2.fromScale(0.02, -0.06),
				Size = UDim2.fromScale(0.96, 0.82),
				ZIndex = 32,
			}),
			Caption = e(U.Label, {
				Text = p.Text,
				Position = UDim2.fromScale(-0.12, 0.70),
				Size = UDim2.fromScale(1.24, 0.34),
				TextSize = 17,
				Scaled = true,
				MinTextSize = 12,
				ZIndex = 32,
			}),
		},
	})
end
return Controls
