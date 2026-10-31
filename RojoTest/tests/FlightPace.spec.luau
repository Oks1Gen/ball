--!strict
local Pace = require("../src/shared/Core/FlightPace")

return {
	["pace is zero for slow shots and one for the fastest"] = function()
		assert(Pace.factor(0) == 0)
		assert(Pace.factor(Pace.Slow) == 0)
		assert(Pace.factor(Pace.Fast) == 1)
		assert(Pace.factor(1000) == 1)
		local middle = Pace.factor((Pace.Slow + Pace.Fast) / 2)
		assert(math.abs(middle - 0.5) < 1e-9)
	end,
	["the hang keeps every contact and the finish on time"] = function()
		for _, strength in { 0, 0.4, 1 } do
			for contact = 0, 7 do
				local alpha = contact / 7
				assert(math.abs(Pace.hang(alpha, strength, 7) - alpha) < 1e-9, "contact moved")
			end
			assert(Pace.hang(-0.2, strength, 7) == 0)
			assert(Pace.hang(1.3, strength, 7) == 1)
		end
	end,
	["the hang never runs the ball backwards"] = function()
		local previous = 0
		for i = 1, 7000 do
			local value = Pace.hang(i / 7000, 1, 7)
			assert(value >= previous - 1e-12, "progress went backwards")
			previous = value
		end
	end,
	["a fast ball slows at the contact and makes the time up in the air"] = function()
		local step = 1e-4
		local function slope(alpha: number): number
			return (Pace.hang(alpha + step, 1, 7) - Pace.hang(alpha, 1, 7)) / step
		end
		local afterContact = slope(2 / 7 + step)
		assert(math.abs(afterContact - Pace.ContactSpeed) < 0.01, "contact speed")
		assert(slope(2.66 / 7) > 1.2, "the air part must be faster than an even shot")
		assert(Pace.hang(2.1 / 7, 1, 7) < 2.1 / 7, "the ball lags behind right after a contact")
		assert(Pace.hang(2.5 / 7, 0, 7) == 2.5 / 7, "zero strength keeps the shot even")
	end,
}
