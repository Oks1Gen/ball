--!strict
-- The training loop runs ten times a second for every player in the server.
-- The lane models and their playable strips are cached in the player state when
-- the player joins, so the tick never builds a lane name and never walks the
-- arena tree again.
local TrainingMotion = require(game.ReplicatedStorage.Shared.TrainingMotion)
local Area = require(game.ReplicatedStorage.Shared.TrainingArea)
local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
local Boost = require(game.ReplicatedStorage.Shared.Core.TrainingBoost)

local Tutorial = require(game.ReplicatedStorage.Shared.Core.Tutorial)

local Training = {}

export type Context = {
	states: { [Player]: any },
	Config: any,
	effect: RemoteEvent,
	publish: (Player, string?) -> (),
	startTraining: (Player, number) -> (),
	stopTraining: (Player, boolean?) -> (),
	throw: (Player, number?) -> (),
	kickTiming: any,
	inApron: (Player) -> boolean,
	arenaFor: (Player) -> any,
	rootFor: (Player) -> (any, any),
	multiplier: (any) -> number,
}

function Training.run(context: Context)
	task.spawn(function()
		while true do
			task.wait(0.1)
			for player, s in context.states do
				context.kickTiming.validate(player)
				local pos, hum = context.rootFor(player)
				local laneIndex = nil
				if pos and hum and hum.Health > 0 and os.clock() >= s.busyUntil then
					local lanes = s.lanes and s.lanes[s.data.world == 2 and 2 or 1]
					for i, def in context.Config.Lanes do
						local entry = lanes and lanes[i]
						local strip = entry and entry.strip
						if strip then
							if Area.contains(strip, pos.Position) then
								if s.data.rebirths >= def.rebirths then
									laneIndex = i
								else
									if os.clock() > (s.lockNotice or 0) then
										context.publish(player, "Need " .. def.rebirths .. " rebirths for this lane")
										s.lockNotice = os.clock() + 4
									end
								end
								break
							end
						end
					end
				end
				if
					s.blockedLane
					and (
						laneIndex ~= s.blockedLane
						or (pos and s.blockedPosition and Area.repositioned(s.blockedPosition, pos.Position))
					)
				then
					s.blockedLane = nil
					s.blockedPosition = nil
				end
				if s.lane and laneIndex ~= s.lane then
					context.stopTraining(player)
				end
				if laneIndex and laneIndex ~= s.blockedLane and not s.lane and os.clock() >= (s.stopUntil or 0) then
					context.startTraining(player, laneIndex)
				end
				local serverNow = workspace:GetServerTimeNow()
				local contacts = 0
				while s.lane and s.nextTraining and serverNow >= s.nextTraining and contacts < 8 do
					local cycleGain = context.Config.Lanes[s.lane].multiplier
						* context.multiplier(s)
						* 7
						* context.Config.TrainingCycle
						/ 0.8
					local gain, remainder = TrainingMotion.reward(cycleGain, s.lane, s.gainRemainder)
					s.gainRemainder = remainder
					if s.trainingHit == 1 and (not s.trainingBoostCycle or s.trainingBoostCycle < s.trainingCycle) then
						local paid = Boost.takeCharge(s.data)
						if paid then
							s.trainingBoostCycle = s.trainingCycle
							s.trainingBoostMultiplier = paid
							context.effect:FireClient(player, "TrainingBoost", {
								seed = s.trainingSeed,
								started = s.trainingStarted,
								cycle = s.trainingCycle,
								multiplier = paid,
							})
						end
					end
					local boosted = s.trainingBoostCycle == s.trainingCycle
					local boostMultiplier = if boosted then s.trainingBoostMultiplier else nil
					gain = Boost.reward(gain, s.trainingBoostCycle, s.trainingCycle, boostMultiplier)
					local beforeLevel = context.Config.level(s.data.skill, s.data.rebirths)
					Data.add(s.data, "skill", gain)
					Tutorial.train(s.data, gain)
					local gainedLevels = math.max(0, context.Config.level(s.data.skill, s.data.rebirths) - beforeLevel)
					s.trainingLevelsGained = (s.trainingLevelsGained or 0) + gainedLevels
					context.effect:FireClient(player, "Train", {
						gain = gain,
						lane = s.lane,
						hit = s.trainingHit,
						boosted = boosted,
						boostMultiplier = boostMultiplier,
					})
					s.trainingHit += 1
					contacts += 1
					s.nextPublish = 0
					if s.trainingHit > TrainingMotion.hitCount(s.lane) then
						s.trainingHit = 1
						s.trainingCycle += 1
					end
					s.nextTraining = s.trainingStarted
						+ s.trainingCycle * context.Config.TrainingCycle
						+ TrainingMotion.hitTime(s.lane, s.trainingHit)
				end
				if
					s.auto
					and not s.kickTiming
					and not laneIndex
					and context.inApron(player)
					and os.clock() >= s.busyUntil
				then
					context.throw(player)
				end
				if os.clock() >= (s.nextPublish or 0) then
					s.nextPublish = os.clock() + 0.4
					context.publish(player)
				end
			end
		end
	end)
end

return Training
