--!strict
local Timing = require("../src/shared/Core/KickTiming")
local function near(a: number, b: number)
	assert(math.abs(a - b) < 1e-8, string.format("%f ~= %f", a, b))
end
return {
	["kick scale has exact endpoints and neutral midpoint"] = function()
		near(Timing.multiplier(0), 0.5)
		near(Timing.multiplier(0.5), 1)
		near(Timing.multiplier(1), 2)
		near(Timing.multiplier(-1), 0.5)
		near(Timing.multiplier(2), 2)
		local previous = 0
		for i = 0, 1000 do
			local value = Timing.multiplier(i / 1000)
			assert(value > previous, "Every distinct height increases power")
			previous = value
		end
	end,
	["kick clock repeats and reverses without discontinuities"] = function()
		near(Timing.height(-1), 0)
		near(Timing.height(0), 0)
		near(Timing.height(0.4), 0.5)
		near(Timing.height(0.8), 1)
		near(Timing.height(1.2), 0.5)
		near(Timing.height(1.6), 0)
		for i = 0, 1600 do
			local t = i / 1000
			local h = Timing.height(t)
			assert(h >= 0 and h <= 1)
			near(h, Timing.height(t + Timing.Cycle * 100))
			near(h, Timing.height(Timing.Cycle - t))
			assert(math.abs(Timing.height(t + 0.0001) - h) < 0.001)
		end
	end,
	["kick release accepts latency but rejects fabricated clocks"] = function()
		assert(Timing.validRelease(10, 10.8, 10.9, 0.2))
		assert(not Timing.validRelease(10, 9.99, 10.1, 0.2), "Cannot hit before start")
		assert(not Timing.validRelease(10, 11.1, 10.9, 0.2), "Cannot hit in future")
		assert(not Timing.validRelease(10, 10.1, 10.9, 0.2), "Cannot backdate an entire cycle")
		assert(not Timing.validRelease(10, 0 / 0, 10.9, 0.2))
		assert(not Timing.validRelease(10, math.huge, 10.9, 0.2))
	end,
	["timing effects grow only above neutral power"] = function()
		near(Timing.quality(0.5), 0)
		near(Timing.quality(1), 0)
		near(Timing.quality(1.5), 0.5)
		near(Timing.quality(2), 1)
	end,
}
