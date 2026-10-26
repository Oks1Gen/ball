--!strict
local Motion = require("../src/shared/Core/KickMotion")
return {
	["kick poses settle to neutral before training repeats"] = function()
		assert(Motion.Duration < 1.2)
		for _, time in { -0.1, 0, Motion.Duration, 1.2 } do
			for _, value in Motion.sample(time) do
				assert(value == 0)
			end
		end
		local nearEnd = Motion.sample(Motion.Duration - 0.0001)
		assert(nearEnd.weight < 0.00001 and math.abs(nearEnd.hip) < 0.0001)
	end,
	["kick curves stay continuous and inside anatomical limits"] = function()
		local prior = Motion.sample(0)
		for i = 1, 8600 do
			local current = Motion.sample(i / 10000)
			assert(current.weight >= -0.00001 and current.weight <= 1.00001)
			assert(current.knee >= -105 and current.knee <= 0.0001)
			assert(current.hip >= -55 and current.hip <= 70)
			for name, value in current do
				assert(value == value and math.abs(value) < 110)
				assert(math.abs(value - prior[name]) < 0.2, "Discontinuous joint: " .. name)
			end
			prior = current
		end
	end,
	["kick contact remains aligned while the leg follows through"] = function()
		local hit = Motion.sample(0.42)
		local retimed = Motion.sample(0.6, 0.6)
		for name, value in hit do
			assert(math.abs(value - retimed[name]) < 0.000001)
		end
		assert(hit.weight == 1)
		assert(Motion.sample(0.34).knee < hit.knee)
		assert(Motion.sample(0.5).hip > hit.hip)
		assert(Motion.sample(0.8).weight < Motion.sample(0.66).weight)
	end,
	["reference kick leans from the support ankle with wide balancing arms"] = function()
		local windup = Motion.sample(0.25)
		local hit = Motion.sample(Motion.Contact)
		assert(windup.hip < -45 and windup.lean >= 25)
		assert(hit.lean >= 25 and math.abs(hit.y) < 0.1)
		assert(windup.leftSpread >= 90 and windup.rightSpread + windup.lean >= 55)
		assert(windup.leftElbow <= 10 and windup.rightElbow <= 10)
		assert(Motion.sample(0.52).hip > 60)
		assert(Motion.sample(Motion.Duration).side == 0)
		assert(Motion.sample(Motion.Duration).lean == 0)
	end,
}
