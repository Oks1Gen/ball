--!strict
local Zones = require("../src/shared/Core/ZoneProgression")
return {
	["zone rewards use integer tenths without compounding"] = function()
		for zone = 1, 8 do
			assert(Zones.award(100, zone) == 100 + (zone - 1) * 10)
		end
		assert(Zones.award(17, 3) == 20)
		assert(Zones.multiplier(8) == 1.7)
	end,
	["a skipped frame reaches every crossed boundary and each shot starts at one"] = function()
		local crossings = { { alpha = 0.2, zone = 2 }, { alpha = 0.4, zone = 3 }, { alpha = 0.7, zone = 4 } }
		assert(Zones.reached(crossings, 0.1999) == 1)
		assert(Zones.reached(crossings, 0.2) == 2)
		assert(Zones.reached(crossings, 0.8) == 4)
		assert(Zones.reached({}, 1) == 1)
	end,
	["zone fov pulse is bounded and returns to zero"] = function()
		assert(Zones.pulse(-1) == 0 and Zones.pulse(0) == 0)
		assert(math.abs(Zones.pulse(0.08) - 7) < 0.0001)
		assert(Zones.pulse(0.2) > 0 and Zones.pulse(0.2) < 7)
		assert(Zones.pulse(0.4) == 0 and Zones.pulse(10) == 0)
	end,
}
