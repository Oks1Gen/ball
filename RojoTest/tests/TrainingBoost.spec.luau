--!strict
local Boost = require("../src/shared/Core/TrainingBoost")
local Net = require("../src/shared/Net")
local Data = require("../src/shared/Core/ProfileData")

return {
	["free offers cover 5.0 to 15.0 with reproducible tenth steps"] = function()
		local minimum, maximum = math.huge, 0
		local colors = {}
		for seed = 1, 200 do
			for offer = 0, 25 do
				local def = Boost.offer(seed * 73123, offer)
				assert(def.multiplier == Boost.offer(seed * 73123, offer).multiplier)
				if not def.product then
					assert(def.multiplier >= 5 and def.multiplier <= 15)
					assert(math.abs(def.multiplier * 10 - math.round(def.multiplier * 10)) < 1e-8)
					minimum = math.min(minimum, def.multiplier)
					maximum = math.max(maximum, def.multiplier)
					colors[def.color] = true
				end
			end
		end
		assert(minimum == 5 and maximum == 15)
		for color = 1, 5 do
			assert(colors[color])
		end
	end,
	["rainbow offers rotate through receipt-only products"] = function()
		for index, multiplier in { 67, 69, 144, 67 } do
			local def = Boost.offer(73123, index * 5 - 1)
			assert(def.multiplier == multiplier and def.product == "TrainingBoost" .. multiplier and def.color == 6)
		end
	end,
	["offer window starts after falling and leaves a three second hold"] = function()
		local started = 100
		local lands = started + Boost.Delay + Boost.TravelTime
		assert(not Boost.inWindow(started, 0, lands - 0.001, 0.16))
		assert(Boost.inWindow(started, 0, lands + 0.001, 0))
		assert(Boost.inWindow(started, 0, lands + Boost.HoldTime - 0.001, 0))
		assert(not Boost.inWindow(started, 0, lands + Boost.HoldTime + 0.17, 999))
		assert(not Boost.inWindow(started, -1, lands, 0))
		assert(not Boost.inWindow(started, 0.5, lands, 0))
		assert(Boost.index(Boost.Delay + 0.01) == 0)
		assert(Boost.index(Boost.Delay + Boost.Interval + 0.01) == 1)
		assert(Boost.Interval - Boost.Lifetime > 3)
	end,
	["protocol accepts only session and offer identifiers"] = function()
		assert(Net.validAction("TrainingBoost", 73123, 0))
		for _, value in { false, {}, "73123", 0, -1, 1.5, math.huge, 0 / 0, 2147483647 } do
			assert(not Net.validAction("TrainingBoost", value, 0))
		end
		for _, offer in { false, {}, "0", -1, 0.5, math.huge, 0 / 0, 10000001 } do
			assert(not Net.validAction("TrainingBoost", 73123, offer))
		end
	end,
	["server-selected multiplier applies only to its complete kick"] = function()
		for _, multiplier in { 5, 10.1, 15, 67, 69, 144 } do
			for _, gain in { 24, 25, 100 } do
				assert(Boost.reward(gain, 7, 7, multiplier) == math.floor(gain * multiplier))
				assert(Boost.reward(gain, 7, 8, multiplier) == gain)
				assert(Boost.reward(gain, nil, 7, multiplier) == gain)
			end
		end
	end,
	["paid charges survive normalization and consume once per kick"] = function()
		local profile = Data.fresh()
		profile.trainingBoosts = { ["67"] = 2, ["69"] = -3, ["144"] = 1, ["999"] = 100 }
		local clean = Data.normalize(profile, { stones = { Pebble = true }, trails = { None = true }, pets = {} })
		assert(clean.trainingBoosts["999"] == nil and clean.trainingBoosts["69"] == 0)
		assert(Boost.takeCharge(clean) == 144)
		assert(Boost.takeCharge(clean) == 67)
		assert(Boost.takeCharge(clean) == 67)
		assert(Boost.takeCharge(clean) == nil)
		assert(Boost.takeCharge({}) == nil)
	end,
}
