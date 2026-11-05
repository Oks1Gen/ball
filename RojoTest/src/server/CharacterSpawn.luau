--!strict
-- Spawn the avatar immediately, but keep physics paused until its client has
-- confirmed the actual standing surface. Streaming requests alone are not proof.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldRefs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local SpawnProtocol = require(game.ReplicatedStorage.Shared.SpawnProtocol)
local CharacterSpawn = {}

function CharacterSpawn.start(map: Instance, world2: Instance?)
	Players.CharacterAutoLoads = false
	local function arenaFor(player: Player): Instance
		return if world2 and player:GetAttribute("SkippingWorld") == 2 then world2 else map
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = SpawnProtocol.Remote
	remote.Parent = ReplicatedStorage
	local pending: { [Player]: Model } = {}
	remote.OnServerEvent:Connect(function(player, character, ...)
		if
			select("#", ...) ~= 0
			or typeof(character) ~= "Instance"
			or not character:IsA("Model")
			or pending[player] ~= character
			or player.Character ~= character
		then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or character:GetAttribute(SpawnProtocol.Positioned) ~= true then
			return
		end
		pending[player] = nil -- One acknowledgement per server-created character.
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.Anchored = false
		player.ReplicationFocus = nil
		character:SetAttribute(SpawnProtocol.Ready, true)
	end)
	Players.PlayerRemoving:Connect(function(player)
		pending[player] = nil
	end)
	local function load(player: Player)
		if player.Parent then
			player.ReplicationFocus = WorldRefs.kickZoneFloor(arenaFor(player))
			local ok, failure = pcall(player.LoadCharacterAsync, player)
			if not ok and player.Parent then
				warn("[CharacterSpawn] avatar load failed: " .. tostring(failure))
				player:Kick("Your character could not load. Please rejoin.")
			end
		end
	end
	local function watch(player: Player, character: Model)
		local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		if not root or player.Character ~= character then
			return
		end
		root.Anchored = true
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid or player.Character ~= character then
			return
		end
		local arena = arenaFor(player)
		root.CFrame = Config.kickZoneCharacterPose(arena, root, humanoid, Config.KickZoneStandFromFront)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		pending[player] = character
		character:SetAttribute(SpawnProtocol.World, if arena == world2 then 2 else 1)
		character:SetAttribute(SpawnProtocol.Positioned, true)
		task.delay(60, function()
			if pending[player] == character and player.Parent then
				player:Kick("The starting area could not load. Please rejoin.")
			end
		end)
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
