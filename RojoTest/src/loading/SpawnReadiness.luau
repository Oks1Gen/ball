--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Readiness = {}

function Readiness.start()
	local player = Players.LocalPlayer
	local shared = ReplicatedStorage:WaitForChild("Shared")
	local Protocol = require(shared:WaitForChild("SpawnProtocol"))
	local WorldRefs = require(shared:WaitForChild("WorldRefs"))
	local remote = ReplicatedStorage:WaitForChild(Protocol.Remote, 60) :: RemoteEvent?
	assert(remote, "Spawn service unavailable")
	local handled: Model? = nil
	local function prepare(character: Model)
		if handled == character then
			return
		end
		handled = character
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.RespectCanCollide = true
		while character.Parent and player.Character == character do
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local map = workspace:FindFirstChild("Map")
			local world = map and map:FindFirstChild("World1")
			local floor = WorldRefs.kickZoneFloor(world)
			if root and floor and character:GetAttribute(Protocol.Positioned) == true then
				params.FilterDescendantsInstances = { floor }
				local hit = workspace:Raycast(root.Position, Vector3.new(0, -12, 0), params)
				if hit and hit.Normal.Y > 0.5 then
					remote:FireServer(character)
					return
				end
			end
			RunService.Heartbeat:Wait()
		end
	end
	player.CharacterAdded:Connect(function(character)
		task.spawn(prepare, character)
	end)
	if player.Character then
		task.spawn(prepare, player.Character)
	end
end

function Readiness.isReady(): boolean
	local character = Players.LocalPlayer.Character
	return character ~= nil and character:GetAttribute("SpawnReady") == true
end

return Readiness
