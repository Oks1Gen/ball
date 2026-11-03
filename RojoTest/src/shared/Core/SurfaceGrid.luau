--!strict
-- Rectangle unions and complete lattice cells, independent of Roblox instances.
local Grid = {}
export type Rect = { number }
export type Cell = { u: number, v: number }

function Grid.subtract(r: Rect, cut: Rect): { Rect }
	local a, b = math.max(r[1], cut[1]), math.min(r[2], cut[2])
	local c, d = math.max(r[3], cut[3]), math.min(r[4], cut[4])
	if b <= a or d <= c then
		return { r }
	end
	local result = {}
	for _, piece in { { r[1], a, r[3], r[4] }, { b, r[2], r[3], r[4] }, { a, b, r[3], c }, { a, b, d, r[4] } } do
		if piece[2] - piece[1] > 0.00001 and piece[4] - piece[3] > 0.00001 then
			table.insert(result, piece)
		end
	end
	return result
end

function Grid.union(rectangles: { Rect }): { Rect }
	local result: { Rect } = {}
	for _, rectangle in rectangles do
		local remaining = { rectangle }
		for _, previous in result do
			local nextPieces = {}
			for _, piece in remaining do
				for _, rest in Grid.subtract(piece, previous) do
					table.insert(nextPieces, rest)
				end
			end
			remaining = nextPieces
		end
		for _, piece in remaining do
			table.insert(result, piece)
		end
	end
	return result
end

function Grid.wholeCells(rectangles: { Rect }, step: number, originU: number, originV: number): { Cell }
	assert(step > 0, "Surface grid needs a positive step")
	local union = Grid.union(rectangles)
	local candidates: { [string]: Cell } = {}
	for _, r in union do
		for u = math.floor((r[1] - originU) / step), math.ceil((r[2] - originU) / step) - 1 do
			for v = math.floor((r[3] - originV) / step), math.ceil((r[4] - originV) / step) - 1 do
				candidates[u .. ":" .. v] = { u = u, v = v }
			end
		end
	end
	local cells = {}
	for _, cell in candidates do
		local u0, v0 = originU + cell.u * step, originV + cell.v * step
		local area = 0
		for _, r in union do
			area += math.max(0, math.min(u0 + step, r[2]) - math.max(u0, r[1])) * math.max(
				0,
				math.min(v0 + step, r[4]) - math.max(v0, r[3])
			)
		end
		-- World coordinates around 300 carry Float32 seam noise; real strips stay out.
		if area >= step * step - step * 0.0001 then
			table.insert(cells, cell)
		end
	end
	table.sort(cells, function(a, b)
		return if a.v ~= b.v then a.v < b.v else a.u < b.u
	end)
	return cells
end

function Grid.merge(cells: { Cell }): { Rect }
	local remaining: { [string]: Cell } = {}
	for _, cell in cells do
		remaining[cell.u .. ":" .. cell.v] = cell
	end
	local rectangles = {}
	for _, first in cells do
		if not remaining[first.u .. ":" .. first.v] then
			continue
		end
		local u1, v1 = first.u + 1, first.v + 1
		while remaining[u1 .. ":" .. first.v] do
			u1 += 1
		end
		while true do
			local full = true
			for u = first.u, u1 - 1 do
				if not remaining[u .. ":" .. v1] then
					full = false
					break
				end
			end
			if not full then
				break
			end
			v1 += 1
		end
		for u = first.u, u1 - 1 do
			for v = first.v, v1 - 1 do
				remaining[u .. ":" .. v] = nil
			end
		end
		table.insert(rectangles, { first.u, u1, first.v, v1 })
	end
	return rectangles
end

return Grid
