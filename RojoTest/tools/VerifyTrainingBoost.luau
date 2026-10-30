-- Isolated checks: no real remotes, profile writes, or Marketplace prompts.
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Motion = require(Shared.TrainingMotion)
local Rules = require(Shared.Core.TrainingBoost)
local Data = require(Shared.Core.ProfileData)
local Goal = require(Shared.TrainingGoal)
local Handler = require(game.ServerScriptService.Server.Gameplay.TrainingBoost)
local Receipts = require(game.ServerScriptService.Server.Gameplay.Receipts)
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
		local age = Rules.Delay + Rules.TravelTime + 1
		local s = {
			lane = index,
			trainingStarted = workspace:GetServerTimeNow() - age,
			trainingSeed = 73123,
			trainingCycle = math.floor(age / Config.TrainingCycle),
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
					check(payload.offer == 0 and payload.seed == s.trainingSeed, "Ack identifies offer/session")
					check(payload.multiplier == Rules.offer(s.trainingSeed, 0).multiplier, "Value is server-selected")
					acknowledgements += 1
				end,
			},
		}
		check(not Handler.claim(context, player, 73122, 0), "Old session rejected")
		check(not Handler.claim(context, player, 73123, 1), "Future offer rejected")
		check(Handler.claim(context, player, 73123, 0), "Landed bubble accepted")
		check(not Handler.claim(context, player, 73123, 0), "Duplicate click rejected")
		check(acknowledgements == 1, "Exactly one acknowledgement")
		local cycle = s.trainingBoostCycle
		check(
			s.trainingStarted + cycle * Config.TrainingCycle + Config.KickContact > workspace:GetServerTimeNow(),
			"Bonus starts at a future contact"
		)
		for _ = 1, Motion.hitCount(index) do
			check(
				Rules.reward(100, cycle, cycle, s.trainingBoostMultiplier)
					== math.floor(100 * s.trainingBoostMultiplier),
				"Every bounce uses displayed multiplier"
			)
			check(Rules.reward(100, cycle, cycle + 1, s.trainingBoostMultiplier) == 100, "Following kick is normal")
		end
		s.trainingBoostOffer = nil
		s.trainingStarted = workspace:GetServerTimeNow() - Rules.Delay - Rules.Lifetime - 1
		check(not Handler.claim(context, player, 73123, 0), "Expired bubble rejected")
		s.trainingStarted = workspace:GetServerTimeNow() - Rules.Delay - 0.1
		check(not Handler.claim(context, player, 73123, 0), "Falling bubble cannot claim early")
		s.trainingStarted = workspace:GetServerTimeNow() - Rules.Delay - Rules.Interval * 4 - 2
		check(not Handler.claim(context, player, 73123, 4), "Rainbow cannot use free claim")
		s.trainingStarted = workspace:GetServerTimeNow() - age
		root.Position += Vector3.new(1000, 0, 0)
		check(not Handler.claim(context, player, 73123, 0), "Off-strip click rejected")
		root.Position = strip.Position + Vector3.new(0, 3, 0)
		hum.Health = 0
		check(not Handler.claim(context, player, 73123, 0), "Death rejects click")
		hum.Health = 100
		s.lane = nil
		check(not Handler.claim(context, player, 73123, 0), "Stopped training rejects click")
		task.wait()
	end
end
check(lanes > 0, "At least one real lane tested")
-- Exercise the real receipt processor with an isolated product catalog and save stub.
for _, multiplier in Rules.Paid do
	local s = { data = Data.fresh() }
	local saved, saves = false, 0
	local context = {
		states = { [player] = s },
		Config = { Products = { TestBoost = { id = 111, trainingBoost = multiplier } } },
		save = function()
			saves += 1
			return saved
		end,
		publish = function() end,
	}
	local receipt = { ProductId = 111, PurchaseId = "isolated-boost-" .. multiplier }
	check(
		Receipts.process(context, player, receipt) == Enum.ProductPurchaseDecision.NotProcessedYet,
		"Unconfirmed save retries"
	)
	check(s.data.trainingBoosts[tostring(multiplier)] == 1, "Receipt reserves one charge")
	saved = true
	check(
		Receipts.process(context, player, receipt) == Enum.ProductPurchaseDecision.PurchaseGranted,
		"Saved receipt granted"
	)
	check(s.data.trainingBoosts[tostring(multiplier)] == 1 and saves == 2, "Receipt retry never doubles charge")
	local clean = Data.normalize(s.data, { stones = { Pebble = true }, trails = { None = true }, pets = {} })
	check(
		Rules.takeCharge(clean) == multiplier and Rules.takeCharge(clean) == nil,
		"Reload preserves exactly one consumable"
	)
	check(
		Receipts.process(context, player, { ProductId = 999, PurchaseId = "unknown" })
			== Enum.ProductPurchaseDecision.NotProcessedYet,
		"Unknown product never grants"
	)
end
return { checks = checks, lanes = lanes, paidProducts = #Rules.Paid }
