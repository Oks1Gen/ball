--!strict
local Interaction = {}

-- Resolve the real stand in the current world, including manually moved stands.
function Interaction.destination(arena: Instance, eggId: string, standingHeight: number): CFrame?
	local scenery = arena:FindFirstChild("SkippingWorld")
	local stand = scenery and scenery:FindFirstChild("Egg_" .. eggId)
	local shell = stand and stand:FindFirstChild("EggShell")
	if not shell or not shell:IsA("BasePart") then
		return nil
	end
	local forward = shell.CFrame.LookVector * Vector3.new(1, 0, 1)
	forward = if forward.Magnitude > 0.01 then forward.Unit else Vector3.new(0, 0, -1)
	local point = shell.Position + forward * 10
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { arena }
	params.RespectCanCollide = true
	local ground = workspace:Raycast(point + Vector3.new(0, 32, 0), Vector3.new(0, -160, 0), params)
	if not ground then
		return nil
	end
	local position = ground.Position + Vector3.new(0, standingHeight + 0.1, 0)
	return CFrame.lookAt(position, Vector3.new(shell.Position.X, position.Y, shell.Position.Z))
end

return Interaction
