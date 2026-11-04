--!strict
-- Whole-stud voxel cladding over one zone's pitch and cosmetic banks (docs/course-voxel.md).
-- Physics stays on the authored Field and BankSupport; every part here is cosmetic.
local Ground = {}
local Grid = require(game.ReplicatedStorage.Shared.Core.VoxelGrid)

local TOP, BACK = Enum.NormalId.Top, Enum.NormalId.Back
local SMOOTH = { Line = true }
local STRIPE = 10

-- Turns painted rectangles into flush blocks. `place` maps a rectangle to a zone-local box.
local function paint(kit: any, parent: Instance, name: string, rects: { any }, colors: any, place: any, face: any)
	for i, r in rects do
		local u0, u1, h0, h1, s0, s1 = place(r)
		local smooth = SMOOTH[r.key] == true
		kit.box(
			parent,
			if smooth then r.key else name,
			u0,
			u1,
			h0,
			h1,
			s0,
			s1,
			assert(colors[r.key], r.key),
			if smooth then nil else { face },
			smooth
		)
		if i % 400 == 0 then
			task.wait()
		end
	end
end

local function pitch(kit: any, colors: any): Model
	local p, half, base = kit.p, kit.bank.inner, kit.levels.base
	local model = Instance.new("Model")
	model.Name = "Pitch"
	local width = math.round(2 * half / p)
	local lines = Grid.pitchLines(width, kit.rows)
	local rects = Grid.rectangles(kit.rows, width, function(j: number, i: number): string?
		if lines[i .. ":" .. j] then
			return "Line"
		end
		return if (j // STRIPE) % 2 == 1 then "PitchDark" else "PitchLight"
	end)
	paint(kit, model, "Turf", rects, colors, function(r: any)
		return -half + p * r.y0, -half + p * (r.y1 + 1), 0, base, p * r.x0, p * (r.x1 + 1)
	end, TOP)
	return model
end

-- Earth strata below a grass lip: grass drips, then light earth, then a darker band.
local function soil(seed: number, length: number, deep: number): (number, number) -> string
	local drips, strokes = {}, {}
	for x = 0, length - 1 do
		local h = Grid.hash(x, 0, seed)
		drips[x] = if h < 0.08 then 2 elseif h < 0.38 then 1 else 0
	end
	return function(x: number, r: number): string
		if r <= drips[x] then
			return "Lawn"
		end
		if not strokes[r] then
			strokes[r] = {
				a = Grid.strokes(length, r, seed + 1, if r < deep then 0.07 else 0.05, 3),
				b = Grid.strokes(length, r, seed + 2, if r < deep then 0.04 else 0.06, 2),
			}
		end
		local s = strokes[r]
		if r < deep then
			return if s.a[x] then "EarthDark" elseif s.b[x] then "EarthLight" else "Earth"
		end
		if Grid.hash(x, r, seed + 3) < 0.012 then
			return "StoneDark"
		end
		return if s.a[x] then "Earth" elseif s.b[x] then "EarthDeep" else "EarthDark"
	end
end

-- Stone wall under a dark curb row, matching the terrace rim.
local function masonry(seed: number, length: number): (number, number) -> string
	local strokes = {}
	return function(x: number, r: number): string
		if r == 0 then
			return "Rim"
		end
		if not strokes[r] then
			strokes[r] = {
				a = Grid.strokes(length, r, seed + 1, 0.06, 3),
				b = Grid.strokes(length, r, seed + 2, 0.04, 2),
			}
		end
		local s = strokes[r]
		return if s.a[x] then "StoneLight" elseif s.b[x] then "StoneDark" else "Stone"
	end
end

local function bank(kit: any, colors: any, side: number, seed: number, frontEnd: boolean): Model
	local p, rows, layer, b = kit.p, kit.rows, kit.layer, kit.bank
	local base, terrace, lawn = kit.levels.base, kit.levels.terrace, kit.levels.lawn
	local model = Instance.new("Model")
	model.Name = if side < 0 then "BankWest" else "BankEast"
	local inward = if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left
	local outward = if side < 0 then Enum.NormalId.Left else Enum.NormalId.Right
	local function span(d0: number, d1: number): (number, number)
		if side > 0 then
			return d0, d1
		end
		return -d1, -d0
	end
	local terraceCols, lawnCols = math.round((b.step - b.inner) / p), math.round((b.outer - b.step) / p)

	-- Terrace top: a dark rim beside the pitch, then 5x5-stud paving checker.
	paint(
		kit,
		model,
		"TerraceTop",
		Grid.rectangles(rows, terraceCols, function(j: number, k: number): string?
			if k == 0 then
				return "Rim"
			end
			return if ((k - 1) // 5 + j // 5) % 2 == 0 then "Path" else "PathDark"
		end),
		colors,
		function(r: any)
			local u0, u1 = span(b.inner + p * r.y0, b.inner + p * (r.y1 + 1))
			-- Slabs sit on the old skins, so no end face shares the skins' plane.
			return u0, u1, b.innerTop, terrace, p * r.x0, p * (r.x1 + 1)
		end,
		TOP
	)

	-- Lawn top: lit edges, natural darker/lighter strokes and single flower pixels.
	local dark, light = {}, {}
	for k = 0, lawnCols - 1 do
		dark[k] = Grid.strokes(rows, k, seed + 10, 0.05, 3)
		light[k] = Grid.strokes(rows, k, seed + 11, 0.035, 2)
	end
	paint(
		kit,
		model,
		"LawnTop",
		Grid.rectangles(rows, lawnCols, function(j: number, k: number): string?
			if k == 0 or k == lawnCols - 1 then
				return "LawnLight"
			elseif Grid.hash(k, j, seed + 12) < 0.012 then
				return if Grid.hash(k, j, seed + 13) < 0.5 then "FlowerYellow" else "FlowerWhite"
			end
			return if dark[k][j] then "LawnDark" elseif light[k][j] then "LawnLight" else "Lawn"
		end),
		colors,
		function(r: any)
			local u0, u1 = span(b.step + p * r.y0, b.step + p * (r.y1 + 1))
			return u0, u1, b.outerTop, lawn, p * r.x0, p * (r.x1 + 1)
		end,
		TOP
	)

	-- Vertical faces: plates one layer in front of the bank bodies, rows counted down from `top`.
	local function wall(name: string, d0: number, d1: number, top: number, count: number, key: any, face: any)
		paint(kit, model, name, Grid.rectangles(rows, count, key), colors, function(r: any)
			local u0, u1 = span(d0, d1)
			return u0, u1, top - p * (r.y1 + 1), top - p * r.y0, p * r.x0, p * (r.x1 + 1)
		end, face)
	end
	wall(
		"PitchWall",
		b.inner - layer,
		b.inner,
		terrace,
		math.round((terrace - base) / p),
		masonry(seed + 20, rows),
		inward
	)
	wall("StepWall", b.step - layer, b.step, lawn, math.round((lawn - terrace) / p), soil(seed + 30, rows, 5), inward)
	local outerRows = math.floor((lawn - b.bottom) / p + 0.001)
	wall("OuterWall", b.outer, b.outer + layer, lawn, outerRows, soil(seed + 40, rows, 5), outward)
	local underside = lawn - outerRows * p
	if underside - b.bottom > 0.01 then
		-- Below the last whole row only a smooth band remains down to the island underside.
		local u0, u1 = span(b.outer, b.outer + layer)
		kit.box(model, "OuterUnderside", u0, u1, b.bottom, underside, 0, p * rows, colors.EarthDeep, nil, true)
	end

	if frontEnd then
		-- The lobby sees the bank ends at s = 0; their bottom row sinks into the lobby ground.
		local endRows = math.ceil((terrace + p / 2) / p)
		local bottom = terrace - endRows * p
		local function face(name: string, d0: number, cols: number, top: number, count: number, key: any)
			paint(kit, model, name, Grid.rectangles(cols, count, key), colors, function(r: any)
				local u0, u1 = span(d0 + p * r.x0, d0 + p * (r.x1 + 1))
				return u0, u1, top - p * (r.y1 + 1), top - p * r.y0, -layer, 0
			end, BACK)
		end
		face("TerraceEnd", b.inner, terraceCols, terrace, endRows, masonry(seed + 50, terraceCols))
		face("LawnEnd", b.step, lawnCols, lawn, math.round((lawn - bottom) / p), soil(seed + 60, lawnCols, 5))
	end
	return model
end

-- Fills an empty, already parented GroundCladding one finished object at a time.
function Ground.build(kit: any, theme: any, frontEnd: boolean, root: Model)
	local colors = table.clone(kit.colors)
	colors.PitchLight = theme.pitch
	colors.PitchDark = theme.pitch:Lerp(Color3.new(0, 0, 0), 0.1)
	colors.Line = kit.colors.White
	for _, build in
		{
			function()
				return pitch(kit, colors)
			end,
			function()
				return bank(kit, colors, -1, 1000, frontEnd)
			end,
			function()
				return bank(kit, colors, 1, 2000, frontEnd)
			end,
		}
	do
		local part = build()
		part.WorldPivot = kit.frame
		part.Parent = root
		task.wait()
	end
end

return Ground
