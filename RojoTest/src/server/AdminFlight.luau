--!strict
-- Server-authorized, session-only noclip. Original collision values are restored exactly.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Access = require(script.Parent.AdminAccess)
local Flight = {}
type Session = {
	character: Model,
	humanoid: Humanoid,
	parts: { [BasePart]: boolean },
	added: RBXScriptConnection,
	removing: RBXScriptConnection,
}
local sessions: { [Player]: Session } = {}

function Flight.set(player: Player, enabled: boolean)
	assert(Access.isAuthorized(player.UserId), "Нет доступа.")
	local old = sessions[player]
	if enabled and old and old.character == player.Character then
		return
	end
	if old then
		sessions[player] = nil
		old.added:Disconnect()
		old.removing:Disconnect()
		for part, collidable in old.parts do
			if part.Parent then
				part.CanCollide = collidable
			end
		end
	end
	player:SetAttribute("AdminFlight", false)
	if not enabled then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	assert(character and humanoid and humanoid.Health > 0, "Персонаж ещё не готов")
	local parts: { [BasePart]: boolean } = {}
	local function include(node: Instance)
		if node:IsA("BasePart") then
			parts[node] = node.CanCollide
			node:SetAttribute("DevFlightCanCollide", node.CanCollide)
			node.CanCollide = false
		end
	end
	local added = character.DescendantAdded:Connect(include)
	for _, node in character:GetDescendants() do
		include(node)
	end
	local removing = player.CharacterRemoving:Connect(function()
		Flight.set(player, false)
	end)
	sessions[player] = { character = character, humanoid = humanoid, parts = parts, added = added, removing = removing }
	player:SetAttribute("AdminFlight", true)
end

RunService.PreSimulation:Connect(function()
	for player, session in sessions do
		if player.Character ~= session.character or session.humanoid.Health <= 0 then
			Flight.set(player, false)
		else
			for part in session.parts do
				if part.Parent then
					part.CanCollide = false
				end
			end
		end
	end
end)
Players.PlayerRemoving:Connect(function(player)
	if sessions[player] then
		Flight.set(player, false)
	end
end)
return Flight
