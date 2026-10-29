-- Isolated real server-handler checks: no profile reads/writes or player rewards.
local Shared = game.ReplicatedStorage.Shared
local Rules = require(Shared.Core.TrainingBoost)
local Handler = require(game.ServerScriptService.Server.Gameplay.TrainingBoost)
local player = game.Players:GetPlayers()[1]
assert(player, "Run in Play with one player")
local checks, lanes = 0, 0
local function check(value, message)
	assert(value, message)
	checks += 1
end
for world = 1, 2 do
	local arena = workspace.Map:FindFirstChild(if world == 1 then "World1" else "World2")
	local zone = arena and arena:FindFirstChild("TrainingZone")
	for index = 1, 7 do
		local lane = zone and zone:FindFirstChild("TrainingLane" .. index)
		local strip = lane and lane:FindFirstChild("TrainingStrip")
		if not strip then
			continue
		end
		lanes += 1
		local s = {
			lane = index,
			trainingStarted = workspace:GetServerTimeNow() - Rules.Delay - 1,
			trainingSeed = 73123,
			trainingCycle = 7,
			trainingHit = 2,
			busyUntil = 0,
			data = { world = world, rebirths = 16 },
			lanes = { [world] = { [index] = { lane = lane, strip = strip } } },
		}
		local root, hum = { Position = strip.Position + Vector3.new(0, 3, 0) }, { Health = 100 }
		local acknowledgements, payload = 0, nil
		local context = {
			states = { [player] = s },
			rootFor = function()
				return root, hum
			end,
			effect = {
				FireClient = function(_, recipient, kind, info)
					check(recipient == player and kind == "TrainingBoost", "Ack belongs to owner")
					payload = info
					acknowledgements += 1
				end,
			},
		}
		check(not Handler.claim(context, player, 73122, 0), "Old session rejected")
		check(not Handler.claim(context, player, 73123, 1), "Future offer rejected")
		check(Handler.claim(context, player, 73123, 0), "Screen offer accepted between contacts")
		check(not Handler.claim(context, player, 73123, 0), "Duplicate rejected")
		check(acknowledgements == 1, "Exactly one acknowledgement")
		check(payload.cycle == 8 and payload.offer == 0 and payload.seed == s.trainingSeed, "Next unpaid kick reserved")
		check(payload.multiplier == Rules.multiplier(s.trainingSeed, 0), "Server chooses multiplier")
		check(Rules.reward(25, s.trainingBoostCycle, 7, s.trainingBoostMultiplier) == 25, "Part-paid kick unchanged")
		check(
			Rules.reward(25, s.trainingBoostCycle, 8, s.trainingBoostMultiplier) == math.floor(25 * payload.multiplier),
			"Reserved kick multiplied"
		)
		check(Rules.reward(25, s.trainingBoostCycle, 9, s.trainingBoostMultiplier) == 25, "Following kick unchanged")
		s.trainingBoostOffer = nil
		s.trainingHit = 1
		check(
			Handler.claim(context, player, 73123, 0) and s.trainingBoostCycle == 7,
			"Unpaid current kick can receive bonus"
		)
		s.trainingBoostOffer = nil
		s.trainingStarted = workspace:GetServerTimeNow() - Rules.Delay - Rules.Lifetime - 0.3
		check(not Handler.claim(context, player, 73123, 0), "Expired offer rejected")
		s.trainingStarted = workspace:GetServerTimeNow() - Rules.Delay - 1
		root.Position += Vector3.new(1000, 0, 0)
		check(not Handler.claim(context, player, 73123, 0), "Leaving strip rejects click")
		root.Position = strip.Position + Vector3.new(0, 3, 0)
		hum.Health = 0
		check(not Handler.claim(context, player, 73123, 0), "Death rejects click")
		hum.Health = 100
		s.busyUntil = os.clock() + 2
		check(not Handler.claim(context, player, 73123, 0), "Busy player rejected")
		s.busyUntil = 0
		s.lane = nil
		check(not Handler.claim(context, player, 73123, 0), "Stopped training rejected")
		task.wait()
	end
end
check(lanes > 0, "At least one lane tested")
return { checks = checks, lanes = lanes }
