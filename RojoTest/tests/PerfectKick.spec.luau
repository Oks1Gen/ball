--!strict
local Perfect = require("../src/shared/Core/PerfectKick")
local Motion = require("../src/shared/Core/KickMotion")
return {
	["perfect accents depend on individual stages, never the combined multiplier"] = function()
		assert(Perfect.count(1, 2) == 0)
		assert(Perfect.count(2, 0.5) == 1, "Weak combined shot retains perfect power feedback")
		assert(Perfect.count(0.5, 3) == 1, "Perfect accuracy works with low power")
		assert(Perfect.count(2, 3) == 2)
		assert(Perfect.count(1.8, 2.99) == 0)
	end,
	["slow windup accelerates into the exact shared contact and recovers"] = function()
		for count = 0, 2 do
			local hit = Perfect.windup(count)
			assert(math.abs(Perfect.phase(hit, count) - Motion.Contact) < 1e-8)
			local before = Motion.sample(Perfect.phase(hit, count))
			local original = Motion.sample(Motion.Contact)
			for name, value in before do
				assert(math.abs(value - original[name]) < 1e-8)
			end
			local previous = -1
			for i = 0, 1400 do
				local phase = Perfect.phase(i / 1000, count)
				assert(phase >= previous and phase - previous < 0.003 or previous == -1)
				previous = phase
			end
			if count > 0 then
				assert(Perfect.phase(hit - 0.13, count) < 0.32)
				assert(Perfect.phase(hit - 0.01, count) > 0.40)
				assert(Perfect.phase(hit + 0.34, count) > Motion.Duration)
			end
		end
	end,
	["perfect camera pulses are bounded and return to their original baseline"] = function()
		assert(Perfect.selectionFov(-1) == 0 and Perfect.selectionFov(0) == 0)
		assert(Perfect.selectionFov(0.1) == -8)
		assert(Perfect.selectionFov(0.52) == 0)
		assert(Perfect.impactFov(-0.01, 2) == 0 and Perfect.impactFov(0.1, 0) == 0)
		for i = 0, 3000 do
			local time = i / 1000
			assert(Perfect.selectionFov(time) >= -8 and Perfect.selectionFov(time) <= 0)
			assert(math.abs(Perfect.impactFov(time, 2)) < 19)
		end
		assert(math.abs(Perfect.impactFov(3, 2)) < 0.001)
	end,
}
