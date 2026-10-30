--!strict
local Shared = game.ReplicatedStorage.Shared
local Rules = require(Shared.Core.TrainingBoost)
local Config = require(Shared.GameConfig)
local Area = require(Shared.TrainingArea)
local Goal = require(Shared.TrainingGoal)
local Boost = {}

function Boost.claim(context: any, player: Player, seed: number, offer: number): boolean
	local s = context.states[player]
	local root, hum = context.rootFor(player)
	if
		not s
		or not s.lane
		or not s.trainingStarted
		or seed ~= s.trainingSeed
		or (s.trainingBoostOffer or -1) >= offer
		or not root
		or not hum
		or hum.Health <= 0
		or os.clock() < s.busyUntil
	then
		return false
	end
	local definition = Rules.offer(seed, offer)
	local now = workspace:GetServerTimeNow()
	local set = s.lanes and s.lanes[s.data.world == 2 and 2 or 1]
	local entry = set and set[s.lane]
	if
		definition.product
		or not entry
		or not Area.contains(entry.strip, root.Position)
		or s.data.rebirths < Config.Lanes[s.lane].rebirths
		or not Goal.net(entry.lane)
		or not Rules.inWindow(s.trainingStarted, offer, now, player:GetNetworkPing() + 0.04)
	then
		return false
	end
	-- Start with the next complete kick, never only the remaining bounces.
	local cycle = math.max(s.trainingCycle, math.floor((now - s.trainingStarted) / Config.TrainingCycle))
	if
		now >= s.trainingStarted + cycle * Config.TrainingCycle + Config.KickContact
		or (cycle == s.trainingCycle and s.trainingHit > 1)
	then
		cycle += 1
	end
	s.trainingBoostOffer = offer
	s.trainingBoostCycle = cycle
	s.trainingBoostMultiplier = definition.multiplier
	context.effect:FireClient(player, "TrainingBoost", {
		seed = seed,
		cycle = cycle,
		offer = offer,
		multiplier = definition.multiplier,
		started = s.trainingStarted,
		lane = s.lane,
	})
	return true
end

return Boost
