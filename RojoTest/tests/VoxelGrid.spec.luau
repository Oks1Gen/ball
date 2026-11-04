--!strict
local Grid = require("../src/shared/Core/VoxelGrid")

return {
	["voxel hash is deterministic, bounded and not a regular lattice"] = function()
		local sum, steps = 0, {}
		for a = 0, 199 do
			local h = Grid.hash(a, 7, 3)
			assert(h >= 0 and h < 1 and h == Grid.hash(a, 7, 3))
			sum += h
			steps[string.format("%.4f", (Grid.hash(a + 1, 7, 3) - h) % 1)] = true
		end
		local distinct = 0
		for _ in steps do
			distinct += 1
		end
		assert(math.abs(sum / 200 - 0.5) < 0.08 and distinct > 150)
		assert(Grid.hash(-3, 4, 1) >= 0 and Grid.hash(3, 4, 1) ~= Grid.hash(3, 4, 2))
	end,
	["voxel rectangles cover each painted cell exactly once and merge whole cells"] = function()
		local function key(x: number, y: number): string?
			if x == 3 and y == 2 then
				return nil
			end
			return if (x // 5 + y // 5) % 2 == 0 then "Light" else "Dark"
		end
		local rects = Grid.rectangles(10, 10, key)
		local seen = {}
		for _, r in rects do
			for x = r.x0, r.x1 do
				for y = r.y0, r.y1 do
					assert(not seen[x .. ":" .. y], "Cell covered twice")
					assert(key(x, y) == r.key, "Rectangle paints a different key")
					seen[x .. ":" .. y] = true
				end
			end
		end
		for x = 0, 9 do
			for y = 0, 9 do
				assert((seen[x .. ":" .. y] == true) == (key(x, y) ~= nil), "Coverage mismatch")
			end
		end
		local whole = Grid.rectangles(10, 10, function(x, y)
			return if (x // 5 + y // 5) % 2 == 0 then "Light" else "Dark"
		end)
		assert(#whole == 4, "Checker cells must stay whole")
	end,
	["voxel strokes stay inside the lane with gaps and bounded lengths"] = function()
		local cells = Grid.strokes(270, 4, 11, 0.08, 3)
		local again = Grid.strokes(270, 4, 11, 0.08, 3)
		local run, count = 0, 0
		for x = 0, 269 do
			assert(cells[x] == again[x])
			if cells[x] then
				run += 1
				count += 1
				assert(run <= 3, "Stroke too long")
			else
				run = 0
			end
		end
		for x in cells do
			assert(x >= 0 and x < 270)
		end
		assert(count > 10 and count < 90, "Unexpected stroke density")
	end,
	["voxel ring is symmetric, thin and gap free"] = function()
		for _, case in { { 28, 135.5, 8 }, { 28, 22.5, 8 }, { 10.5, 10.5, 5 }, { 6, 6, 4 } } do
			local cx, cy = case[1], case[2]
			local cells = Grid.ring(cx, cy, case[3])
			local set = {}
			for _, c in cells do
				set[c.x .. ":" .. c.y] = true
			end
			for _, c in cells do
				local mx, my = 2 * cx - 1 - c.x, 2 * cy - 1 - c.y
				assert(set[mx .. ":" .. c.y] and set[c.x .. ":" .. my], "Ring is not mirrored")
				local neighbours = 0
				for dx = -1, 1 do
					for dy = -1, 1 do
						if (dx ~= 0 or dy ~= 0) and set[(c.x + dx) .. ":" .. (c.y + dy)] then
							neighbours += 1
						end
					end
				end
				assert(neighbours >= 2, "Ring has a gap")
				assert(
					not (
							set[(c.x + 1) .. ":" .. c.y]
							and set[c.x .. ":" .. (c.y + 1)]
							and set[(c.x + 1) .. ":" .. (c.y + 1)]
						),
					"Ring has a thick 2x2 clump"
				)
			end
		end
	end,
	["pitch lines are mirrored and the touchline runs between the goal lines"] = function()
		local lines = Grid.pitchLines(56, 270)
		for id in lines do
			local x, y = string.match(id, "^(%-?%d+):(%-?%d+)$")
			local cx, cy = tonumber(x) :: number, tonumber(y) :: number
			assert(cx >= 0 and cx < 56 and cy >= 0 and cy <= 270)
			assert(lines[(55 - cx) .. ":" .. cy] and lines[cx .. ":" .. (270 - cy)], "Markings are not mirrored")
		end
		for y = 10, 260 do
			assert(lines["1:" .. y] and lines["54:" .. y], "Broken touchline")
		end
		for x = 1, 54 do
			assert(lines[x .. ":10"] and lines[x .. ":135"] and lines[x .. ":260"], "Broken goal or halfway line")
		end
		assert(not lines["0:100"] and not lines["28:100"], "Paint outside the markings")
		assert(lines["28:127"] and lines["28:143"], "Missing centre circle")
	end,
}
