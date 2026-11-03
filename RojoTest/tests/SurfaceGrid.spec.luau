--!strict
local Grid = require("../src/shared/Core/SurfaceGrid")

return {
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
