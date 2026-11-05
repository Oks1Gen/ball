local Vector3 = require("@lune/roblox").Vector3
local Swim = require("../src/shared/Core/OceanSwimming")

return {
	["swimmers detect initial overlap and thin obstacles across a long step"] = function()
		assert(not Swim.clearBox(Vector3.zero, Vector3.new(10, 0, 0), Vector3.one, 0.5))
		assert(not Swim.clearBox(Vector3.new(-20, 0, 0), Vector3.new(20, 0, 0), Vector3.new(0.01, 8, 8), 1))
		assert(Swim.clearBox(Vector3.new(-20, 10, 0), Vector3.new(20, 10, 0), Vector3.one, 1))
	end,
	["two fish cannot exchange positions through one another"] = function()
		local a, b = Vector3.new(-4, 0, 0), Vector3.new(4, 0, 0)
		assert(not Swim.pairClear(a, b, b, a, 1))
		assert(Swim.pairClear(a, b, a + Vector3.new(0, 3, 0), b + Vector3.new(0, 3, 0), 2))
	end,
	["school members stay in the certified envelope while changing order"] = function()
		local before = Vector3.new(Swim.memberCoordinates(0, 3, 1))
		local after = Vector3.new(Swim.memberCoordinates(20, 3, 1))
		assert((before - after).Magnitude > 3)
		for t = 0, 600 do
			for i = 1, 12 do
				assert(Vector3.new(Swim.memberCoordinates(t, i, 1)).Magnitude < 10)
			end
		end
	end,
}
