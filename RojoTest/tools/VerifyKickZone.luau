-- Run on the Studio server during Play. Isolated state: never changes a saved profile.
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Refs = require(Shared.WorldRefs)
local Throw = require(game.ServerScriptService.Server.Gameplay.Throw)
local Data = require(Shared.Core.ProfileData)
local player = assert(game.Players:GetPlayers()[1], "Run Play with one player")
local world = workspace.Map.World1
local apron = Refs.kickZoneFloor(world)
local checks, origins = 0, {}
local function check(value, message)
	assert(value, message)
	checks += 1
end
local root = Instance.new("Part")
root.Size = Vector3.new(2, 2, 1)
local hum = Instance.new("Humanoid")
hum.HipHeight = 2
local states = {}
local info
local throw = Throw.build({
	states = states,
	effect = {
		FireAllClients = function(_, kind, payload)
			check(kind == "Throw", "Emits the shot contract")
			info = payload
		end,
	},
	FlightStreaming = { start = function() end },
	publish = function() end,
	stopTraining = function() end,
	lockPose = function(_, _, _, stance)
		check((stance.Position - root.Position).Magnitude < 1e-5, "Kick never moves the character")
		check(stance.LookVector:Dot(apron.CFrame.LookVector) > 0.999, "Kick faces the course")
	end,
	releasePose = function() end,
	rootFor = function()
		return root, hum
	end,
	arenaFor = function()
		return world
	end,
	frameFor = function()
		return Config.arenaFrame(world)
	end,
	inKickZone = function()
		return Config.inKickZone(world, root.Position)
	end,
	multiplier = function()
		return 1
	end,
})
local height = apron.Size.Y / 2 + 3
for _, x in { -apron.Size.X / 2 + 0.2, 0, apron.Size.X / 2 - 0.2 } do
	for _, z in { -apron.Size.Z / 2 + 0.2, 0, apron.Size.Z / 2 - 0.2 } do
		root.CFrame = apron.CFrame * CFrame.new(x, height, z) * CFrame.Angles(0, 1.2, 0)
		check(Config.inKickZone(world, root.Position), "Entire orange surface is active")
		local data = Data.fresh()
		data.skill = 1000000
		states[player] = { data = data, busyUntil = 0, friends = 0 }
		throw(player, nil, 6)
		check(info ~= nil, "Starts a shot from every tested position")
		local localStart = CFrame.lookAt(root.Position, root.Position + apron.CFrame.LookVector)
			:PointToObjectSpace(info.startPosition)
		check(
			math.abs(localStart.X - 0.4) < 1e-4 and math.abs(localStart.Z + 1.7) < 1e-4,
			"Ball launches at the kicking foot"
		)
		check(info.distance <= Config.shotLimit(1, world, info.startPosition), "Maximum shot stays inside the course")
		table.insert(origins, tostring(info.startPosition))
		states[player] = nil -- Invalidates all scheduled reward callbacks.
		info = nil
	end
end
for _, offset in
	{
		Vector3.new(apron.Size.X / 2 + 0.1, height, 0),
		Vector3.new(0, height, apron.Size.Z / 2 + 0.1),
		Vector3.new(0, height, -apron.Size.Z / 2 - 0.1),
		Vector3.new(0, -1, 0),
		Vector3.new(0, 20, 0),
	}
do
	check(not Config.inKickZone(world, apron.CFrame:PointToWorldSpace(offset)), "Outside the visible zone is inactive")
end
root:Destroy()
hum:Destroy()
return { checks = checks, origins = origins }
