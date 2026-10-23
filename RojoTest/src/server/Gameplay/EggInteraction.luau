--!strict
local Interaction = {}

-- Egg stands can be moved independently of the arena and Config spawn points.
-- Always validate against the authoritative shell in the player's own world.
function Interaction.inRange(arena: Instance, eggId: string, position: Vector3?): boolean
	if not position then
		return false
	end
	local scenery = arena:FindFirstChild("SkippingWorld")
	local stand = scenery and scenery:FindFirstChild("Egg_" .. eggId)
	local shell = stand and stand:FindFirstChild("EggShell")
	return shell ~= nil and shell:IsA("BasePart") and (position - shell.Position).Magnitude <= 19
end

return Interaction
