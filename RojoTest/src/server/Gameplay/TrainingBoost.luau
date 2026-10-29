--!strict
local Shared = game.ReplicatedStorage.Shared
local Rules = require(Shared.Core.TrainingBoost)
local Config = require(Shared.GameConfig)
local Area = require(Shared.TrainingArea)
local Boost = {}

function Boost.claim(context: any, player: Player, seed: number, offer: number): boolean
	local s = context.states[player]
	local root, hum = context.rootFor(player)
	if
		not s
		or not s.lane
		or not s.trainingStarted
		or seed ~= s.trainingSeed
		or s.trainingBoostOffer == offer
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
		or not Rules.inWindow(s.trainingStarted, offer, workspace:GetServerTimeNow(), player:GetNetworkPing() + 0.04)
	then
		return false
	end
	-- Consume this offer once; the next kick that has not paid any contact owns it.
	s.trainingBoostOffer = offer
	s.trainingBoostCycle = s.trainingCycle + (if s.trainingHit > 1 then 1 else 0)
	s.trainingBoostMultiplier = Rules.multiplier(seed, offer)
	context.effect:FireClient(player, "TrainingBoost", {
		seed = seed,
		offer = offer,
		cycle = s.trainingBoostCycle,
		started = s.trainingStarted,
		lane = s.lane,
		multiplier = s.trainingBoostMultiplier,
	})
	return true
end
return Boost
