--!strict
-- Whole-stud voxel cladding over one zone's pitch and cosmetic banks (docs/course-voxel.md).
-- Physics stays on the authored Field and BankSupport; every part here is cosmetic.
-- A location's look picks the terrace, lawn and wall patterns; patterns return colour keys.
local Ground = {}
local Grid = require(game.ReplicatedStorage.Shared.Core.VoxelGrid)

local N = Enum.NormalId
local TOP, BACK, FRONT = N.Top, N.Back, N.Front
local STRIPE, BAND = 10, 8

-- Turns painted rectangles into flush blocks. `place` maps a rectangle to a zone-local box.
local function paint(kit: any, parent: Instance, name: string, rects: { any }, colors: any, place: any, face: any)
	for i, r in rects do
		local u0, u1, h0, h1, s0, s1 = place(r)
		local part = if r.key == "Line" then "Line" else name
		kit.box(parent, part, u0, u1, h0, h1, s0, s1, assert(colors[r.key], r.key), { face })
		if i % 400 == 0 then
			task.wait()
		end
	end
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

-- Wall patterns by kind: x runs along the wall, r counts rows down from its top.
local function wall(kind: string, seed: number, length: number): (number, number) -> string
	if kind == "soil" then
		return soil(seed, length, 5)
	elseif kind == "masonry" then
		return masonry(seed, length)
	elseif kind == "brick" then
		-- Running bond: two-cell bricks, every other row shifted by one cell.
		return function(x: number, r: number): string
			if r == 0 then
				return "Coping"
			end
			local h = Grid.hash((x + r % 2) // 2, r, seed)
			return if h < 0.14 then "BrickDark" elseif h < 0.26 then "BrickLight" else "Brick"
		end
	elseif kind == "concrete" then
		return function(x: number, r: number): string
			if r == 0 then
				return "Coping"
			end
			return if Grid.hash(x // 5, (r - 1) // 2, seed) < 0.3 then "ConcreteDark" else "Concrete"
		end
	elseif kind == "timber" then
		-- Vertical boards with a joint every four rows.
		return function(x: number, r: number): string
			if r == 0 then
				return "TimberEdge"
			end
			local h = Grid.hash(x, (r - 1) // 4, seed)
			return if h < 0.25 then "WoodDark" elseif h < 0.45 then "WoodLight" else "Wood"
		end
	elseif kind == "facade" then
		-- Two-cell windows on three-row floors; some are lit.
		return function(x: number, r: number): string
			if r == 0 then
				return "Coping"
			end
			if r % 3 ~= 0 and x % 4 >= 1 and x % 4 <= 2 then
				return if Grid.hash(x // 4, r // 3, seed) < 0.35 then "WindowLit" else "Glass"
			end
			return "Facade"
		end
	end
	error("Unknown wall " .. kind)
end

-- Terrace top: rim column beside the pitch, then the location's paving.
local function terrace(kit: any, look: any, cols: number, seed: number): (number, number) -> string?
	local offset, forecourt = kit.rowOffset, look.forecourt
	return function(j: number, k: number): string?
		local row = j + offset
		if k == 0 then
			if look.rim == "hazard" then
				return if (row // 2) % 2 == 0 then "Hazard" else "HazardDark"
			end
			return "TerraceRim"
		end
		if forecourt and j >= forecourt[1] and j < forecourt[2] then
			return if ((k - 1) // 2 + j // 2) % 2 == 0 then "ClubLight" else "Club"
		end
		local style = look.terrace
		if style == "checker" then
			return if ((k - 1) // 5 + row // 5) % 2 == 0 then "TerraceA" else "TerraceB"
		elseif style == "slabs" then
			return if Grid.hash((k - 1) // 3, row // 3, seed) < 0.5 then "TerraceA" else "TerraceB"
		elseif style == "road" then
			if k == cols - 1 then
				return "TerraceRim"
			elseif k == cols // 2 and row % 8 < 4 then
				return "RoadLine"
			end
			return if Grid.hash(k, row // 6, seed) < 0.18 then "TerraceB" else "TerraceA"
		end
		error("Unknown terrace " .. tostring(style))
	end
end

-- Lawn top: k = 0 is the edge above the step wall, cols - 1 the outer edge.
local function lawn(kit: any, look: any, cols: number, rows: number, seed: number): (number, number) -> string?
	local offset, style = kit.rowOffset, look.lawn
	if style == "grass" then
		-- Lit edges, natural darker/lighter strokes and single flower pixels.
		local dark, light = {}, {}
		for k = 0, cols - 1 do
			dark[k] = Grid.strokes(rows, k, seed + 10, 0.05, 3)
			light[k] = Grid.strokes(rows, k, seed + 11, 0.035, 2)
		end
		local flowers, density = look.flowers, look.flowerDensity or 0.012
		return function(j: number, k: number): string?
			if k == 0 or k == cols - 1 then
				return "LawnLight"
			elseif Grid.hash(k, j, seed + 12) < density then
				return flowers[1 + math.floor(Grid.hash(k, j, seed + 13) * #flowers)]
			end
			return if dark[k][j] then "LawnDark" elseif light[k][j] then "LawnLight" else "Lawn"
		end
	elseif style == "planks" then
		-- Deck boards along the course, six rows long, joints staggered by column.
		return function(j: number, k: number): string?
			if k == 0 or k == cols - 1 then
				return "TimberEdge"
			end
			local h = Grid.hash(k, (j + offset + (k % 3) * 2) // 6, seed + 14)
			return if h < 0.2 then "WoodDark" elseif h < 0.45 then "WoodLight" else "Wood"
		end
	elseif style == "plaza" then
		return function(j: number, k: number): string?
			if k == 0 then
				return "Curb"
			end
			return if Grid.hash(k // 2, (j + offset) // 2, seed + 15) < 0.3 then "PlazaB" else "PlazaA"
		end
	elseif style == "gravel" then
		local a, b = {}, {}
		for k = 0, cols - 1 do
			a[k] = Grid.strokes(rows, k, seed + 16, 0.07, 2)
			b[k] = Grid.strokes(rows, k, seed + 17, 0.05, 2)
		end
		return function(j: number, k: number): string?
			if k == 0 then
				return "Curb"
			end
			return if a[k][j] then "GravelDark" elseif b[k][j] then "GravelLight" else "Gravel"
		end
	end
	error("Unknown lawn " .. tostring(style))
end

local function pitch(kit: any, look: any, colors: any): Model
	local p, half, base = kit.p, kit.bank.inner, kit.levels.base
	local model = Instance.new("Model")
	model.Name = "Pitch"
	local width = math.round(2 * half / p)
	local lines = Grid.pitchLines(width, kit.rows)
	local rects = Grid.rectangles(kit.rows, width, function(j: number, i: number): string?
		if lines[i .. ":" .. j] then
			return "Line"
		end
		-- Mown checker: stripes along the course crossed by 8-cell bands, continuous across zones.
		return if ((j + kit.rowOffset) // STRIPE + i // BAND) % 2 == 1 then "PitchDark" else "PitchLight"
	end)
	paint(kit, model, "Turf", rects, colors, function(r: any)
		return -half + p * r.y0, -half + p * (r.y1 + 1), 0, base, p * r.x0, p * (r.x1 + 1)
	end, TOP)
	if look.backEnd then
		-- The course ends here: a wall closes the island under the pitch.
		local rows = math.floor((base - kit.bank.bottom) / p + 0.001)
		local key = wall(look.pitchWall, 70, width)
		local length = p * kit.rows
		paint(kit, model, "PitchEnd", Grid.rectangles(width, rows, key), colors, function(r: any)
			return -half + p * r.x0,
				-half + p * (r.x1 + 1),
				base - p * (r.y1 + 1),
				base - p * r.y0,
				length,
				length + kit.layer
		end, FRONT)
		local band = base - rows * p
		if band - kit.bank.bottom > 0.01 then
			kit.box(
				model,
				"EndUnderside",
				-half,
				half,
				kit.bank.bottom,
				band,
				length,
				length + kit.layer,
				colors.EarthDeep,
				nil,
				Enum.Material.SmoothPlastic
			)
		end
	end
	return model
end

local function bank(kit: any, look: any, colors: any, side: number, seed: number): Model
	local p, rows, layer, b = kit.p, kit.rows, kit.layer, kit.bank
	local base, terraceTop, lawnTop = kit.levels.base, kit.levels.terrace, kit.levels.lawn
	local model = Instance.new("Model")
	model.Name = if side < 0 then "BankWest" else "BankEast"
	local inward = if side < 0 then N.Right else N.Left
	local outward = if side < 0 then N.Left else N.Right
	local function span(d0: number, d1: number): (number, number)
		if side > 0 then
			return d0, d1
		end
		return -d1, -d0
	end
	local terraceCols, lawnCols = math.round((b.step - b.inner) / p), math.round((b.outer - b.step) / p)
	if look.club then
		colors.Club = if side < 0 then look.club.west else look.club.east
		colors.ClubLight = look.club.light
	end

	paint(
		kit,
		model,
		"TerraceTop",
		Grid.rectangles(rows, terraceCols, terrace(kit, look, terraceCols, seed + 5)),
		colors,
		function(r: any)
			local u0, u1 = span(b.inner + p * r.y0, b.inner + p * (r.y1 + 1))
			-- Slabs sit on the old skins, so no end face shares the skins' plane.
			return u0, u1, b.innerTop, terraceTop, p * r.x0, p * (r.x1 + 1)
		end,
		TOP
	)
	paint(
		kit,
		model,
		"LawnTop",
		Grid.rectangles(rows, lawnCols, lawn(kit, look, lawnCols, rows, seed)),
		colors,
		function(r: any)
			local u0, u1 = span(b.step + p * r.y0, b.step + p * (r.y1 + 1))
			return u0, u1, b.outerTop, lawnTop, p * r.x0, p * (r.x1 + 1)
		end,
		TOP
	)

	-- Vertical faces: plates one layer in front of the bank bodies, rows counted down from `top`.
	local function face(name: string, d0: number, d1: number, top: number, count: number, key: any, normal: any)
		paint(kit, model, name, Grid.rectangles(rows, count, key), colors, function(r: any)
			local u0, u1 = span(d0, d1)
			return u0, u1, top - p * (r.y1 + 1), top - p * r.y0, p * r.x0, p * (r.x1 + 1)
		end, normal)
	end
	face(
		"PitchWall",
		b.inner - layer,
		b.inner,
		terraceTop,
		math.round((terraceTop - base) / p),
		wall(look.pitchWall, seed + 20, rows),
		inward
	)
	face(
		"StepWall",
		b.step - layer,
		b.step,
		lawnTop,
		math.round((lawnTop - terraceTop) / p),
		wall(look.stepWall, seed + 30, rows),
		inward
	)
	local outerRows = math.floor((lawnTop - b.bottom) / p + 0.001)
	face("OuterWall", b.outer, b.outer + layer, lawnTop, outerRows, wall(look.outerWall, seed + 40, rows), outward)
	local underside = lawnTop - outerRows * p
	if underside - b.bottom > 0.01 then
		-- Below the last whole row only a smooth band remains down to the island underside.
		local u0, u1 = span(b.outer, b.outer + layer)
		kit.box(
			model,
			"OuterUnderside",
			u0,
			u1,
			b.bottom,
			underside,
			0,
			p * rows,
			colors.EarthDeep,
			nil,
			Enum.Material.SmoothPlastic
		)
	end

	-- Bank ends: the lobby sees them at s = 0, where the bottom row sinks into its ground;
	-- the last zone ends in the open, so its end plates run down to the island underside.
	local function ends(
		name: string,
		d0: number,
		cols: number,
		top: number,
		count: number,
		key: any,
		s0: number,
		normal: any
	)
		paint(kit, model, name, Grid.rectangles(cols, count, key), colors, function(r: any)
			local u0, u1 = span(d0 + p * r.x0, d0 + p * (r.x1 + 1))
			return u0, u1, top - p * (r.y1 + 1), top - p * r.y0, s0, s0 + layer
		end, normal)
	end
	if look.frontEnd then
		local endRows = math.ceil((terraceTop + p / 2) / p)
		local bottom = terraceTop - endRows * p
		ends(
			"TerraceEnd",
			b.inner,
			terraceCols,
			terraceTop,
			endRows,
			wall(look.pitchWall, seed + 50, terraceCols),
			-layer,
			BACK
		)
		local lawnRows = math.round((lawnTop - bottom) / p)
		ends("LawnEnd", b.step, lawnCols, lawnTop, lawnRows, wall(look.outerWall, seed + 60, lawnCols), -layer, BACK)
	end
	if look.backEnd then
		local length = p * rows
		for _, piece: any in
			{
				{ "TerraceBackEnd", b.inner, terraceCols, terraceTop, look.pitchWall } :: { any },
				{ "LawnBackEnd", b.step, lawnCols, lawnTop, look.outerWall } :: { any },
			}
		do
			local top = piece[4]
			local count = math.floor((top - b.bottom) / p + 0.001)
			ends(piece[1], piece[2], piece[3], top, count, wall(piece[5], seed + 70, piece[3]), length, FRONT)
			local u0, u1 = span(piece[2], piece[2] + p * piece[3])
			local band = top - count * p
			if band - b.bottom > 0.01 then
				kit.box(
					model,
					"EndUnderside",
					u0,
					u1,
					b.bottom,
					band,
					length,
					length + layer,
					colors.EarthDeep,
					nil,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end
	return model
end

-- Fills an empty, already parented GroundCladding one finished object at a time.
-- `look` holds the location's patterns, colour overrides and which ends are open.
function Ground.build(kit: any, look: any, root: Model)
	local colors = table.clone(kit.colors)
	for key, color in look.colors or {} do
		colors[key] = color
	end
	colors.PitchLight = look.pitch
	colors.PitchDark = look.pitch:Lerp(Color3.new(0, 0, 0), 0.1)
	colors.Line = kit.colors.White
	for _, build in
		{
			function()
				return pitch(kit, look, colors)
			end,
			function()
				return bank(kit, look, table.clone(colors), -1, 1000)
			end,
			function()
				return bank(kit, look, table.clone(colors), 1, 2000)
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
