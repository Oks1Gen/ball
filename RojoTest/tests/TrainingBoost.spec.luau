--!strict
local Boost = require("../src/shared/Core/TrainingBoost")
local Net = require("../src/shared/Net")
return {
	["screen boosts have independent three second windows and bounded grace"] = function()
		assert(Boost.index(0.5) == -1 and Boost.index(0.6) == 0)
		assert(not Boost.inWindow(100, 0, 100.7, 0))
		assert(Boost.inWindow(100, 0, 101.5, 0))
		assert(Boost.inWindow(100, 0, 103.65, 0.1))
		assert(not Boost.inWindow(100, 0, 103.8, 999))
		assert(not Boost.inWindow(100, 0, 107, 0))
		assert(not Boost.inWindow(100, -1, 101, 0))
		assert(not Boost.inWindow(100, 0.5, 101, 0))
		assert(Boost.index(6.7) == 1)
		assert(Boost.Interval - Boost.Lifetime >= 3)
	end,
	["boost multiplier is deterministic and never exceeds four"] = function()
		local counts: { [number]: number } = {}
		for seed = 1, 2000 do
			local m = Boost.multiplier(seed, 17)
			assert(m == Boost.multiplier(seed, 17))
			assert(m == 1.6 or m == 2 or m == 2.5 or m == 3 or m == 4)
			counts[m] = (counts[m] or 0) + 1
		end
		assert(counts[1.6] > counts[4] and counts[4] > 0)
	end,
	["fractional boosts affect only the reserved kick and floor whole gains"] = function()
		assert(Boost.reward(25, 7, 7, 1.6) == 40)
		assert(Boost.reward(25, 7, 7, 2.5) == 62)
		assert(Boost.reward(25, 7, 7, 4) == 100)
		assert(Boost.reward(25, 7, 8, 4) == 25)
		assert(Boost.reward(25, nil, 7, 4) == 25)
		assert(Boost.reward(25, 7, 7, 100) == 100)
	end,
	["training boost protocol rejects malformed and reward-like payloads"] = function()
		assert(Net.validAction("TrainingBoost", 73123, 0))
		assert(Net.validAction("TrainingBoost", 2147483646, 10000000))
		for _, value in { false, {}, "73123", 0, -1, 1.5, math.huge, 0 / 0, 2147483647 } do
			assert(not Net.validAction("TrainingBoost", value, 0))
		end
		for _, cycle in { false, {}, "0", -1, 0.5, math.huge, 0 / 0, 10000001 } do
			assert(not Net.validAction("TrainingBoost", 73123, cycle))
		end
		assert(not Net.validAction("TrainingBoost", 73123, nil))
	end,
}
