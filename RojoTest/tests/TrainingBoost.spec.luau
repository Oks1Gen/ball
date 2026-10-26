--!strict
local Boost = require("../src/shared/Core/TrainingBoost")
local Net = require("../src/shared/Net")

return {
	["training targets leave at least three seconds between windup windows"] = function()
		for _, period in { 0.8, 1.2, 1.7, 4 } do
			local previous: number? = nil
			for cycle = 0, 120 do
				if Boost.available(cycle, period, 0.42) then
					local at = cycle * period
					if previous then
						assert(at - previous - 0.42 >= 3 - 1e-8)
					end
					previous = at
				end
			end
		end
		assert(Boost.available(0, 1.2, 0.42))
		assert(not Boost.available(1, 1.2, 0.42))
		assert(not Boost.available(2, 1.2, 0.42))
		assert(Boost.available(3, 1.2, 0.42))
		assert(not Boost.inWindow(100, 1, 101.3, 1.2, 0.42, 0.16))
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
	["training boost accepts only the current windup with bounded network grace"] = function()
		assert(Boost.inWindow(100, 0, 100.1, 1.2, 0.42, 0))
		assert(Boost.inWindow(100, 6, 107.5, 1.2, 0.42, 0))
		assert(Boost.inWindow(100, 0, 100.5, 1.2, 0.42, 0.1))
		assert(not Boost.inWindow(100, 0, 99.99, 1.2, 0.42, 0.16))
		assert(not Boost.inWindow(100, 0, 100.6, 1.2, 0.42, 999))
		assert(not Boost.inWindow(100, 0, 101.3, 1.2, 0.42, 0.16))
		assert(not Boost.inWindow(100, 2, 101.3, 1.2, 0.42, 0.16))
		assert(not Boost.inWindow(100, -1, 100.1, 1.2, 0.42, 0.16))
	end,
	["training boost doubles every actual contact of one kick without changing carry"] = function()
		local baseline, boosted, nextKick = 0, 0, 0
		for _, gain in { 24, 25, 24, 25 } do
			baseline += gain
			boosted += Boost.reward(gain, 7, 7)
			nextKick += Boost.reward(gain, 7, 8)
			assert(Boost.reward(gain, nil, 7) == gain)
		end
		assert(boosted == baseline * 2)
		assert(nextKick == baseline)
	end,
}
