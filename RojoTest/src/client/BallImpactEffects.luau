--!strict
-- Bounded, client-only impact accents. The owner removes the entire burst after 1.3s.
local Shapes = require(script.Parent.BallEffectShapes)
local Themes = require(script.Parent.TrailThemes)
local Effects = {}

function Effects.bounce(parent: Instance, position: Vector3, normal: Vector3, id: string, strength: number)
	local theme = Themes[id]
	if not theme then
		return
	end
	local host = Shapes.part(parent, id .. "Impact", theme.color)
	host.Size = Vector3.one * 0.1
	host.Transparency = 1
	host.Position = position
	host:SetAttribute("ImpactStyle", id)
	local center = position + normal * 0.18
	Shapes.ring(host, center, normal, theme.color, 3.5 * strength)
	theme.impact(host, center, normal, strength)
end

return Effects
