--!strict
-- Pure raster helpers for whole-stud voxel surfaces (docs/course-voxel.md).
-- Cells are integer indices; one cell is one stud of the shared ground grid.
local Grid = {}

export type Rect = { x0: number, x1: number, y0: number, y1: number, key: string }
export type Cell = { x: number, y: number }

local TWO32 = 4294967296

local function mul32(a: number, b: number): number
	local aLo, aHi = a % 65536, a // 65536
	local bLo, bHi = b % 65536, b // 65536
	return ((aHi * bLo + aLo * bHi) % 65536 * 65536 + aLo * bLo) % TWO32
end

local function mix(x: number): number
	x = bit32.bxor(x, bit32.rshift(x, 16))
	x = mul32(x, 0x7feb352d)
	x = bit32.bxor(x, bit32.rshift(x, 15))
	x = mul32(x, 0x846ca68b)
	return bit32.bxor(x, bit32.rshift(x, 16))
end

-- Deterministic value in [0, 1): the same cell and seed always paint the same pixel.
function Grid.hash(a: number, b: number, seed: number): number
	local h = mix(seed % TWO32)
	h = mix((h + b % TWO32) % TWO32)
	h = mix((h + a % TWO32) % TWO32)
	return h / TWO32
end

-- Cover every painted cell exactly once: runs along x in each row, then identical
-- runs of consecutive rows stack into one rectangle. nil keys stay empty.
function Grid.rectangles(width: number, height: number, keyAt: (number, number) -> string?): { Rect }
	local out: { Rect } = {}
	local open: { [string]: Rect } = {}
	for y = 0, height - 1 do
		local nextOpen: { [string]: Rect } = {}
		local x = 0
		while x < width do
			local key = keyAt(x, y)
			local last = x
			while last + 1 < width and keyAt(last + 1, y) == key do
				last += 1
			end
			if key then
				local id = x .. ":" .. last .. ":" .. key
				local rect = open[id]
				if rect then
					rect.y1 = y
					nextOpen[id] = rect
				else
					local made: Rect = { x0 = x, x1 = last, y0 = y, y1 = y, key = key }
					table.insert(out, made)
					nextOpen[id] = made
				end
			end
			x = last + 1
		end
		open = nextOpen
	end
	return out
end

-- Natural strokes along one lane: a stroke starts with `chance`, lasts 1..maxLength
-- cells and is followed by at least one free cell. Returns cell -> variant in [0, 1).
function Grid.strokes(
	length: number,
	lane: number,
	seed: number,
	chance: number,
	maxLength: number
): { [number]: number }
	local out: { [number]: number } = {}
	local x = 0
	while x < length do
		if Grid.hash(lane, x, seed) < chance then
			local size = 1 + math.floor(Grid.hash(lane, x, seed + 1) * maxLength)
			local variant = Grid.hash(lane, x, seed + 2)
			for i = x, math.min(length - 1, x + size - 1) do
				out[i] = variant
			end
			x += size + 1
		else
			x += 1
		end
	end
	return out
end

-- Thin pixel ring. The centre is in cell units: an integer lies on a grid line,
-- a half-integer on a cell centre. Columns and rows are both sampled, so the ring
-- has no gaps, and the first quadrant is mirrored to keep it exactly symmetric.
function Grid.ring(cx: number, cy: number, radius: number): { Cell }
	local function shift(c: number): number
		return if math.abs(c % 1 - 0.5) < 0.000001 then 0 else 0.5
	end
	local sx, sy = shift(cx), shift(cy)
	local quadrant: { [string]: Cell } = {}
	local function mark(a: number, b: number)
		quadrant[a .. ":" .. b] = { x = a, y = b }
	end
	-- Nearest cell offset to a distance; ties go inward so the ring never bulges.
	local function nearest(distance: number, s: number): number
		return math.max(0, math.floor(distance - s + 0.5 - 0.000001))
	end
	for a = 0, math.floor(radius - sx) do
		local d = a + sx
		mark(a, nearest(math.sqrt(math.max(radius * radius - d * d, 0)), sy))
	end
	for b = 0, math.floor(radius - sy) do
		local d = b + sy
		mark(nearest(math.sqrt(math.max(radius * radius - d * d, 0)), sx), b)
	end
	local function indices(c: number, s: number, offset: number): { number }
		if s == 0 then
			local base = c - 0.5
			return if offset == 0 then { base } else { base + offset, base - offset }
		end
		return { c + offset, c - 1 - offset }
	end
	local seen: { [string]: boolean } = {}
	local out: { Cell } = {}
	for _, cell in quadrant do
		for _, x in indices(cx, sx, cell.x) do
			for _, y in indices(cy, sy, cell.y) do
				local id = x .. ":" .. y
				if not seen[id] then
					seen[id] = true
					table.insert(out, { x = x, y = y })
				end
			end
		end
	end
	table.sort(out, function(a, b)
		return if a.y == b.y then a.x < b.x else a.y < b.y
	end)
	return out
end

-- Football markings on a pitch of width x length cells. Mirrored across x and
-- about row length/2 (the halfway line), so both halves read the same.
function Grid.pitchLines(width: number, length: number): { [string]: boolean }
	local lines: { [string]: boolean } = {}
	local half = length // 2
	local mid = width // 2
	local function set(x: number, y: number)
		for _, row in { y, length - y } do
			for _, column in { x, width - 1 - x } do
				lines[column .. ":" .. row] = true
			end
		end
	end
	local function box(x0: number, y0: number, depth: number)
		for x = x0, mid - 1 do
			set(x, y0 + depth)
		end
		for y = y0, y0 + depth do
			set(x0, y)
		end
	end
	local goal = 10
	for y = goal, half do
		set(1, y)
	end
	for x = 1, mid - 1 do
		set(x, goal)
		set(x, half)
	end
	box(mid - 17, goal, 17)
	box(mid - 10, goal, 6)
	for _, cell in Grid.ring(mid, half + 0.5, 8) do
		set(cell.x, cell.y)
	end
	for y = half - 1, half do
		set(mid - 1, y)
	end
	local spot = goal + 12
	set(mid - 1, spot)
	for _, cell in Grid.ring(mid, spot + 0.5, 8) do
		if cell.y > goal + 17 then
			set(cell.x, cell.y)
		end
	end
	return lines
end

return Grid
