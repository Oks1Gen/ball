--!strict
local Shared = game.ReplicatedStorage.Shared
local Rules = require(Shared.Core.TrainingBoost)
local Config = require(Shared.GameConfig)
local Area = require(Shared.TrainingArea)
local Goal = require(Shared.TrainingGoal)
local Boost = {}

function Boost.claim(context: any, player: Player, seed: number, cycle: number): boolean
	local s = context.states[player]
	local root, hum = context.rootFor(player)
	if
		not s
		or not s.lane
		or not s.trainingStarted
		or seed ~= s.trainingSeed
		or s.trainingBoostCycle == cycle
		or s.trainingCycle ~= cycle
		or s.trainingHit ~= 1
		or not root
		or not hum
		or hum.Health <= 0
		or os.clock() < s.busyUntil
	then
		return false
	end
	local set = s.lanes and s.lanes[s.data.world == 2 and 2 or 1]
	local entry = set and set[s.lane]
	if
		not entry
		or not Area.contains(entry.strip, root.Position)
		or s.data.rebirths < Config.Lanes[s.lane].rebirths
		or not Goal.net(entry.lane)
		or not Rules.inWindow(
			s.trainingStarted,
			cycle,
			workspace:GetServerTimeNow(),
			Config.TrainingCycle,
			Config.KickContact,
			player:GetNetworkPing() + 0.04
		)
	then
		return false
	end
	-- Consume once before sending acknowledgement. Normal rewards keep their
	-- fractional carry; only the accepted kick's actual integer gains are doubled.
	s.trainingBoostCycle = cycle
	context.effect:FireClient(player, "TrainingBoost", {
		seed = seed,
		cycle = cycle,
		started = s.trainingStarted,
		lane = s.lane,
	})
	return true
end

return Boost
