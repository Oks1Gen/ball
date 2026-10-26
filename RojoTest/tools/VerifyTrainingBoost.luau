-- Isolated server handler checks. No profile reads/writes or actual player rewards.
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Motion = require(Shared.TrainingMotion)
local Rules = require(Shared.Core.TrainingBoost)
local Goal = require(Shared.TrainingGoal)
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
		if not strip or not Goal.net(lane) then
			continue
		end
		lanes += 1
		local s = {
			lane = index,
			trainingStarted = workspace:GetServerTimeNow() - 0.1,
			trainingSeed = 73123,
			trainingCycle = 0,
			trainingHit = 1,
			busyUntil = 0,
			data = { world = world, rebirths = 16 },
			lanes = { [world] = { [index] = { lane = lane, strip = strip } } },
		}
		local root, hum = { Position = strip.Position + Vector3.new(0, 3, 0) }, { Health = 100 }
		local acknowledgements = 0
		local context = {
			states = { [player] = s },
			rootFor = function()
				return root, hum
			end,
			effect = {
				FireClient = function(_, recipient, kind, payload)
					check(recipient == player and kind == "TrainingBoost", "Ack belongs to owner")
					check(payload.cycle == 0 and payload.seed == s.trainingSeed, "Ack identifies kick")
					acknowledgements += 1
				end,
			},
		}
		check(not Handler.claim(context, player, 73122, 0), "Old session rejected")
		check(not Handler.claim(context, player, 73123, 1), "Future kick rejected")
		check(Handler.claim(context, player, 73123, 0), "Current windup accepted")
		check(not Handler.claim(context, player, 73123, 0), "Duplicate click rejected")
		check(acknowledgements == 1, "Exactly one acknowledgement")
		local base, boosted, remainder = 0, 0, 0
		for _ = 1, Motion.hitCount(index) do
			local gain
			gain, remainder =
				Motion.reward(Config.Lanes[index].multiplier * 7 * Config.TrainingCycle / 0.8, index, remainder)
			base += gain
			boosted += Rules.reward(gain, s.trainingBoostCycle, 0)
		end
		check(boosted == base * 2, "Complete kick pays exactly twice normal")
		check(Rules.reward(17, s.trainingBoostCycle, 1) == 17, "Next kick has no bonus")
		s.trainingBoostCycle = nil
		s.trainingCycle = 1
		s.trainingStarted = workspace:GetServerTimeNow() - Config.TrainingCycle - 0.1
		check(not Handler.claim(context, player, 73123, 1), "Intervening kick has no target or bonus")
		s.trainingCycle = 0
		s.trainingStarted = workspace:GetServerTimeNow() - 0.8
		check(not Handler.claim(context, player, 73123, 0), "Late click rejected")
		s.trainingStarted = workspace:GetServerTimeNow() - 0.1
		root.Position += Vector3.new(1000, 0, 0)
		check(not Handler.claim(context, player, 73123, 0), "Leaving strip rejects click")
		root.Position = strip.Position + Vector3.new(0, 3, 0)
		hum.Health = 0
		check(not Handler.claim(context, player, 73123, 0), "Death rejects click")
		hum.Health = 100
		s.lane = nil
		check(not Handler.claim(context, player, 73123, 0), "Stopped training rejects click")
		task.wait()
	end
end
check(lanes > 0, "At least one real goal tested")
return { checks = checks, lanes = lanes }
