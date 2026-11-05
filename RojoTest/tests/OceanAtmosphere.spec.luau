local Atmosphere = require("../src/shared/Core/OceanAtmosphere")
return {
	["ocean sound zones crossfade continuously and conserve total volume"] = function()
		for p = -2, 11, 0.125 do
			local total = 0
			for _, w in Atmosphere.zoneWeights(p) do
				assert(w >= 0 and w <= 1)
				total += w
			end
			assert(math.abs(total - 1) < 1e-6)
		end
		local a, b = Atmosphere.zoneWeights(3.999), Atmosphere.zoneWeights(4.001)
		for i = 1, 8 do
			assert(math.abs(a[i] - b[i]) < 0.003)
		end
	end,
	["ocean encounters fade at their boundaries and repeat without a pop"] = function()
		assert(Atmosphere.envelope(0, 78, 30, 0) == 0)
		assert(Atmosphere.envelope(10, 78, 30, 0) == 1)
		assert(Atmosphere.envelope(30, 78, 30, 0) == 0)
		assert(Atmosphere.envelope(77.99, 78, 30, 0) == 0)
		assert(Atmosphere.envelope(78.01, 78, 30, 0) < 0.001)
	end,
	["jellyfish wave reaches successive positions at successive times"] = function()
		assert(Atmosphere.jellyWave(7, 0) > Atmosphere.jellyWave(7, 520))
		assert(math.abs(Atmosphere.jellyWave(7, 0) - Atmosphere.jellyWave(17, 520)) < 1e-6)
	end,
}
