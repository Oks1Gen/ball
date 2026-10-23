--!strict
local Vector3 = require("@lune/roblox").Vector3
local Path = require("../src/client/FlamePath")

return {
	["flame follows the old side of a bounce instead of current velocity"] = function()
		local path = Path.new()
		path.push(Vector3.new(0, 5, 0))
		path.push(Vector3.new(5, 0, 0))
		path.push(Vector3.new(10, 5, 0))
		local head = Vector3.new(10, 5, 0)
		local point = path.sample(head, math.sqrt(50) + 2, Vector3.new(-1, -1, 0).Unit)
		assert(point.Y > 1, "The tail must turn upwards on the older descending arc")
		assert(point.X < 5, "The tail must continue past the contact point")
	end,
	["new and cleared flames do not invent a straight tail"] = function()
		local path = Path.new()
		local head = Vector3.new(1, 2, 3)
		assert(path.sample(head, 16, Vector3.new(-1, 0, 0)) == head)
		path.push(Vector3.new(-10, 2, 3))
		path.clear()
		assert(path.sample(head, 16, Vector3.new(-1, 0, 0)) == head)
	end,
	["teleporting does not draw a flame bridge across the map"] = function()
		local path = Path.new()
		path.push(Vector3.new(0, 0, 0))
		local head = Vector3.new(100, 0, 0)
		path.push(head)
		assert(path.sample(head, 16, Vector3.new(-1, 0, 0)) == head)
	end,
	["long flights retain only the recent flame path"] = function()
		local path = Path.new()
		for i = 1, 1000 do
			path.push(Vector3.new(i * 0.5, 0, 0))
		end
		local head = Vector3.new(500, 0, 0)
		local oldest = path.sample(head, 1000, Vector3.new(-1, 0, 0))
		assert(head.X - oldest.X <= 20.5, "Old flight history must be pruned")
		assert(head.X - oldest.X >= 16, "The whole visible tail must remain available")
	end,
}
