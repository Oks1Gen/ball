--!strict
local Grid = require("../src/shared/Core/SurfaceGrid")

return {
	["checker partition covers an L-shaped lawn with whole squares and disjoint stud strips"] = function()
		local checker, edge = Grid.partition({ { 0, 8, 0, 8 }, { 8, 11.2, 0, 3.2 } }, 6.4, 1.6, 0, 0)
		assert(#checker == 1 and checker[1].u == 0 and checker[1].v == 0)
		local area, seen = #checker * 6.4 * 6.4, {}
		for _, r in edge do
			for u = r[1], r[2] - 1 do
				for v = r[3], r[4] - 1 do
					assert(not (u < 4 and v < 4), "Boundary overlaps a checker square")
					assert(not seen[u .. ":" .. v], "Duplicate boundary coverage")
					seen[u .. ":" .. v] = true
					area += 1.6 * 1.6
				end
			end
		end
		assert(math.abs(area - (64 + 3.2 * 3.2)) < 0.00001)
	end,
	["checker partition rejects a sub-stud leftover instead of hiding it"] = function()
		local ok = pcall(Grid.partition, { { 0, 6.45, 0, 6.4 } }, 6.4, 1.6, 0, 0)
		assert(not ok)
	end,
	["checker partition keeps one phase around a hole and shifted negative coordinates"] = function()
		local rects = Grid.subtract({ -9.6, 9.6, 20.12, 39.32 }, { -3.2, 3.2, 26.52, 32.92 })
		local checker, edge = Grid.partition(rects, 6.4, 1.6, -9.6, 20.12)
		local area = #checker * 6.4 * 6.4
		for _, r in edge do
			area += (r[2] - r[1]) * (r[4] - r[3]) * 1.6 * 1.6
		end
		assert(math.abs(area - (19.2 * 19.2 - 6.4 * 6.4)) < 0.00001)
	end,
	["surface grid merges a cap without filling its missing corner"] = function()
		local cells = Grid.wholeCells({ { 0, 3.2, 0, 1.6 }, { 0, 1.6, 1.6, 3.2 } }, 1.6, 0, 0)
		local rectangles = Grid.merge(cells)
		local area = 0
		for _, r in rectangles do
			area += (r[2] - r[1]) * (r[4] - r[3])
			assert(not (r[1] <= 1 and r[2] > 1 and r[3] <= 1 and r[4] > 1))
		end
		assert(area == 3 and #rectangles == 2)
	end,
	["surface grid joins neighbouring blocks before choosing whole cells"] = function()
		local cells = Grid.wholeCells({ { 0, 1.5, 0, 3.2 }, { 1.5, 6.4, 0, 3.2 } }, 3.2, 0, 0)
		assert(#cells == 2 and cells[1].u == 0 and cells[2].u == 1)
	end,
	["surface grid cannot count overlapping rectangles twice to fill a hole"] = function()
		local cells = Grid.wholeCells({ { 0, 2, 0, 3.2 }, { 0, 2, 0, 3.2 } }, 3.2, 0, 0)
		assert(#cells == 0)
	end,
	["surface grid omits clipped edges and cells cut by an occluder"] = function()
		local visible = Grid.subtract({ 0, 6.6, 0, 6.4 }, { 3, 6.6, 3, 6.4 })
		local cells = Grid.wholeCells(visible, 3.2, 0, 0)
		assert(#cells == 0)
		assert(#Grid.wholeCells({ { 0, 6.6, 0, 3.2 } }, 3.2, 0, 0) == 2)
	end,
	["surface grid preserves one origin across negative coordinates and small seams"] = function()
		local cells = Grid.wholeCells({ { -1.4, 1.8, 20.12, 23.32 }, { 1.80002, 5, 20.12, 23.32 } }, 3.2, 5, 20.12)
		assert(#cells == 2 and cells[1].u == -2 and cells[2].u == -1)
		assert(#Grid.wholeCells({ { 0, 1.5, 0, 3.2 }, { 1.51, 3.2, 0, 3.2 } }, 3.2, 0, 0) == 0)
	end,
}
