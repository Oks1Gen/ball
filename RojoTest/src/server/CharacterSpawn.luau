--!strict
-- Characters load only after the lobby floor has streamed to the client. An
-- auto-loaded character is simulated by its client and falls through ground
-- that has not replicated yet; the loading screen hid it until it was skipped.
local Players = game:GetService("Players")
local WorldRefs = require(game.ReplicatedStorage.Shared.WorldRefs)
local CharacterSpawn = {}

function CharacterSpawn.start(map: Instance)
	Players.CharacterAutoLoads = false
	-- The spawn pad and the apron the session moves the character onto.
	local points: { Vector3 } = {}
	for _, part in { WorldRefs.spawn(map), WorldRefs.kickZoneFloor(map) } do
		table.insert(points, part.Position)
	end
	local function load(player: Player)
		if workspace.StreamingEnabled then
			for _, position in points do
				if not player.Parent then
					return
				end
				local ok, failure = pcall(player.RequestStreamAroundAsync, player, position, 15)
				if not ok then
					warn("[CharacterSpawn] streaming request failed: " .. tostring(failure))
				end
			end
		end
		if player.Parent then
			player:LoadCharacterAsync()
		end
	end
	local function watch(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid then
			return
		end
		humanoid.Died:Once(function()
			task.wait(Players.RespawnTime)
			if player.Parent and player.Character == character then
				load(player)
			end
		end)
	end
	local function join(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.spawn(watch, player, character)
		end)
		local character = player.Character
		if character then
			watch(player, character)
		else
			load(player)
		end
	end
	Players.PlayerAdded:Connect(join)
	for _, player in Players:GetPlayers() do
		task.spawn(join, player)
	end
end

return CharacterSpawn
