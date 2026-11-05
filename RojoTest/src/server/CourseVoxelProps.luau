--!strict
-- Voxel prop library for course locations (docs/course-voxel.md). Every prop is whole
-- p-sized cells with studs on all faces. Cells: u = n * p across, s = m * p along;
-- the pitch spans n -28..28, the terrace n 28..39 and the lawn n 39..52. Prop helpers take
-- n measured outward from the centre line and mirror it for the west side (side = -1).
-- Terrace columns: n 28 is the rim, n 29 the pitch-side boards; terrace props start at n 30.
local Props = {}
local Grid = require(game.ReplicatedStorage.Shared.Core.VoxelGrid)
local Landmarks = require(script.Parent.FootballCityLandmarks)
local C = Color3.fromRGB
local N = Enum.NormalId
local NEON = Enum.Material.Neon

Props.Skin = { C(255, 218, 176), C(240, 184, 134), C(198, 136, 90), C(132, 88, 58) }

function Props.pick(list: { any }, h: number): any
	return list[1 + math.floor(h * #list)]
end

-- Cell writer for one side: rows r0..r1 above `level`, n mirrored for side -1.
function Props.writer(kit: any, model: Instance, side: number, level: number)
	local p = kit.p
	return function(
		name: string,
		n0: number,
		n1: number,
		r0: number,
		r1: number,
		m0: number,
		m1: number,
		color: Color3,
		material: Enum.Material?
	): Part
		local a, b = n0, n1
		if side < 0 then
			a, b = -n1, -n0
		end
		return kit.cells(model, name, a, b, level + r0 * p, level + r1 * p, m0, m1, color, material)
	end
end

-- The face of a sided part that looks at the pitch.
function Props.inward(side: number): Enum.NormalId
	return if side > 0 then N.Left else N.Right
end

-- The location's landmark keeps FootballCityLandmarks' name and signature.
function Props.landmark(kit: any, city: Instance, field: BasePart, index: number): Model
	local model = kit.model(city, Landmarks.Names[index])
	model:SetAttribute("CityLandmark", true)
	model:SetAttribute("LandmarkSignature", Landmarks.signature(field))
	return model
end

-- Course furniture ---------------------------------------------------------------------

-- Pitch-side boards on the terrace front (n 29): plain panels under an ink trim, split by
-- posts. `spans` are free row ranges; `deck` holds the panel colours in turn.
function Props.adBoards(kit: any, city: Instance, side: number, spans: { { number } }, deck: { Color3 }, seed: number)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "AdBoards"), side, kit.levels.terrace)
	local i = seed
	for _, span in spans do
		local m, stop = span[1], span[2]
		if stop - m < 7 then
			continue
		end
		v("BoardPost", 29, 30, 0, 3, m, m + 1, c.Ink)
		m += 1
		while stop - m >= 6 do
			local length = math.min(15, stop - m - 1)
			local rest = stop - m - 1 - length
			if rest > 0 and rest < 6 then
				length += rest
			end
			v("AdBoard", 29, 30, 0, 2, m, m + length, deck[i % #deck + 1])
			i += 1
			v("BoardTrim", 29, 30, 2, 3, m, m + length, c.Ink)
			v("BoardPost", 29, 30, 0, 3, m + length, m + length + 1, c.Ink)
			m += length + 1
		end
	end
end

-- Free row ranges between occupied ones, inside 1 .. rows - 1.
function Props.gaps(rows: number, busy: { { number } }): { { number } }
	table.sort(busy, function(a, b)
		return a[1] < b[1]
	end)
	local out, m = {}, 1
	for _, range in busy do
		if range[1] > m then
			table.insert(out, { m, range[1] })
		end
		m = math.max(m, range[2])
	end
	if rows - 1 > m then
		table.insert(out, { m, rows - 1 })
	end
	return out
end

-- Seated fans: a shirt cell and a head cell, a few with a raised scarf. `skip` marks aisles;
-- each block between aisles wears one shirt colour, so a crowd reads as supporter sections.
function Props.fans(
	v: any,
	n: number,
	row: number,
	m0: number,
	m1: number,
	seed: number,
	shirts: { Color3 },
	density: number,
	skip: { [number]: boolean }?
)
	local section = 0
	for m = m0, m1 - 1 do
		if skip and skip[m] then
			section += 1
		elseif Grid.hash(n, m, seed) < density then
			local shirt = Props.pick(shirts, Grid.hash(section, row, seed + 1))
			v("FanBody", n, n + 1, row, row + 1, m, m + 1, shirt)
			v("FanHead", n, n + 1, row + 1, row + 2, m, m + 1, Props.pick(Props.Skin, Grid.hash(m, n, seed + 2)))
			if Grid.hash(m, n, seed + 3) < 0.05 then
				v("FanScarf", n, n + 1, row + 2, row + 3, m, m + 1, shirt)
			end
		end
	end
end

-- Seat tiers rising away from the pitch: tier t covers n0 + t * depth .. + depth with its
-- seats on row t; aisles every `block` rows; fans sit on the front cell of each tier.
-- spec = { n0, depth, tiers, m0, m1, block, seat = (tier, block) -> Color3, riser,
--          shirts?, density?, seed, name? }
function Props.stand(kit: any, city: Instance, side: number, level: number, spec: any): (Model, any)
	local model = kit.model(city, spec.name or "Grandstand")
	local v = Props.writer(kit, model, side, level)
	for t = 0, spec.tiers - 1 do
		local a = spec.n0 + t * spec.depth
		local b = a + spec.depth
		if t > 0 then
			v("StandTier", a, b, 0, t, spec.m0, spec.m1, spec.riser)
		end
		local aisles = {}
		local m, block = spec.m0, 0
		while m < spec.m1 do
			local stop = math.min(m + spec.block, spec.m1)
			v("Seats", a, b, t, t + 1, m, stop, spec.seat(t, block))
			if stop < spec.m1 then
				v("Aisle", a, b, t, t + 1, stop, stop + 1, spec.riser)
				aisles[stop] = true
				stop += 1
			end
			m, block = stop, block + 1
		end
		if spec.shirts then
			Props.fans(v, a, t + 1, spec.m0, spec.m1, spec.seed + t * 7, spec.shirts, spec.density or 0.45, aisles)
		end
	end
	return model, v
end

function Props.floodlight(kit: any, city: Instance, side: number, m: number, accent: Color3, mast: number?)
	local c = kit.colors
	local height = mast or 14
	local v = Props.writer(kit, kit.model(city, "Floodlight"), side, kit.levels.lawn)
	v("Footing", 47, 50, 0, 1, m - 1, m + 2, c.Stone)
	v("Mast", 48, 49, 1, height - 3, m, m + 1, c.Ink)
	v("MastBand", 48, 49, height - 3, height - 2, m, m + 1, accent)
	v("Mast", 48, 49, height - 2, height, m, m + 1, c.Ink)
	-- An ink frame around a 3x2 neon panel that faces the pitch.
	local top = height + 4
	v("Housing", 48, 49, height, top, m - 2, m + 3, c.Ink)
	v("HousingFrame", 47, 48, height, height + 1, m - 2, m + 3, c.Ink)
	v("HousingFrame", 47, 48, top - 1, top, m - 2, m + 3, c.Ink)
	for _, edge in { m - 2, m + 2 } do
		v("HousingFrame", 47, 48, height + 1, top - 1, edge, edge + 1, c.Ink)
	end
	v("Lamp", 47, 48, height + 1, top - 1, m - 1, m + 2, c.Lamp, NEON)
end

function Props.scoreboard(kit: any, city: Instance, side: number, m0: number, accent: Color3)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "Scoreboard"), side, kit.levels.lawn)
	for _, m in { m0 + 1, m0 + 11 } do
		v("Leg", 45, 46, 0, 6, m, m + 1, c.Ink)
	end
	local board = v("Board", 45, 46, 6, 11, m0, m0 + 13, c.Ink)
	v("Header", 45, 46, 11, 12, m0, m0 + 13, accent)
	kit.text(board, "0 : 0", Props.inward(side), c.White)
end

function Props.dugout(kit: any, city: Instance, side: number, m0: number, accent: Color3)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "Dugout"), side, kit.levels.terrace)
	v("BackWall", 32, 33, 0, 3, m0, m0 + 7, c.Ink)
	for _, m in { m0, m0 + 6 } do
		v("SideWall", 30, 32, 0, 3, m, m + 1, c.Ink)
	end
	v("Bench", 31, 32, 0, 1, m0 + 1, m0 + 6, accent)
	v("RoofEdge", 30, 31, 3, 4, m0, m0 + 7, accent)
	v("Roof", 31, 33, 3, 4, m0, m0 + 7, c.White)
end

-- A pole on a pitch corner with a 2x2 pixel flag pointing into the pitch.
function Props.cornerFlag(kit: any, city: Instance, n: number, m: number, accent: Color3)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "CornerFlag"), 1, kit.levels.base)
	v("Pole", n, n + 1, 0, 3, m, m + 1, c.White)
	local dir = if n < 0 then 1 else -1
	for a = 0, 1 do
		for b = 0, 1 do
			local cell = n + dir * (a + 1)
			v("FlagPixel", cell, cell + 1, 2 - b, 3 - b, m, m + 1, if (a + b) % 2 == 0 then accent else c.Red)
		end
	end
end

-- A bench facing the pitch: legs, seat and a backrest on the outer column.
function Props.bench(
	kit: any,
	city: Instance,
	side: number,
	level: number,
	n0: number,
	m0: number,
	length: number,
	color: Color3
)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "ParkBench"), side, level)
	for _, m in { m0, m0 + length - 1 } do
		v("BenchLeg", n0, n0 + 2, 0, 1, m, m + 1, c.Ink)
	end
	v("Seat", n0, n0 + 2, 1, 2, m0, m0 + length, color)
	v("Backrest", n0 + 1, n0 + 2, 2, 3, m0, m0 + length, color)
end

function Props.lampPost(kit: any, city: Instance, side: number, n: number, m: number, level: number, height: number)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "LampPost"), side, level)
	v("Post", n, n + 1, 0, height, m, m + 1, c.Ink)
	v("Lamp", n, n + 1, height, height + 1, m, m + 1, c.Lamp, NEON)
	v("LampCap", n, n + 1, height + 1, height + 2, m, m + 1, c.Ink)
end

-- Plants ---------------------------------------------------------------------------------

local LEAVES = {
	oak = { "LeafDark", "Leaf", "LeafLight" },
	blossom = { "BlossomDark", "Blossom", "BlossomLight" },
	autumn = { "AutumnDark", "Autumn", "AutumnLight" },
}

-- A round voxel tree (footprint n-4..n+5, m-4..m+5): dark underside, full middle,
-- light crown and side bumps.
function Props.tree(kit: any, city: Instance, side: number, n: number, m: number, kind: string?)
	local c = kit.colors
	local tones = LEAVES[kind or "oak"]
	local dark, mid, light = c[tones[1]], c[tones[2]], c[tones[3]]
	local v = Props.writer(kit, kit.model(city, "VoxelTree"), side, kit.levels.lawn)
	v("Trunk", n, n + 1, 0, 3, m, m + 1, c.Wood)
	v("Canopy", n - 2, n + 3, 3, 4, m - 2, m + 3, dark)
	v("Canopy", n - 3, n + 4, 4, 6, m - 3, m + 4, mid)
	v("Canopy", n - 2, n + 3, 6, 7, m - 2, m + 3, light)
	v("Canopy", n - 1, n + 2, 7, 8, m - 1, m + 2, light)
	for _, offset in { { -4, -1 }, { 4, 1 }, { 1, -4 }, { -1, 4 } } do
		local bn, bm = n + offset[1], m + offset[2]
		v("LeafBump", bn, bn + 1, 4, 5, bm, bm + 1, light)
	end
end

-- A large tree with a 2x2 trunk (footprint n-5..n+7, m-5..m+7).
function Props.bigTree(kit: any, city: Instance, side: number, n: number, m: number, kind: string?)
	local c = kit.colors
	local tones = LEAVES[kind or "oak"]
	local dark, mid, light = c[tones[1]], c[tones[2]], c[tones[3]]
	local v = Props.writer(kit, kit.model(city, "VoxelTree"), side, kit.levels.lawn)
	v("Trunk", n, n + 2, 0, 5, m, m + 2, c.Wood)
	v("Canopy", n - 3, n + 5, 5, 6, m - 3, m + 5, dark)
	v("Canopy", n - 4, n + 6, 6, 9, m - 4, m + 6, mid)
	v("Canopy", n - 3, n + 5, 9, 10, m - 3, m + 5, light)
	v("Canopy", n - 1, n + 3, 10, 11, m - 1, m + 3, light)
	for _, offset in { { -5, 0 }, { 6, 1 }, { 1, -5 }, { 0, 6 } } do
		local bn, bm = n + offset[1], m + offset[2]
		v("LeafBump", bn, bn + 1, 7, 8, bm, bm + 1, mid)
	end
end

function Props.pine(kit: any, city: Instance, side: number, n: number, m: number)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "VoxelPine"), side, kit.levels.lawn)
	v("Trunk", n, n + 1, 0, 2, m, m + 1, c.WoodDark)
	for _, layer: any in { { 2, 2, 4, c.Pine }, { 1, 4, 7, c.PineLight }, { 0, 7, 9, c.Pine } } do
		local r = layer[1]
		v("Needles", n - r, n + r + 1, layer[2], layer[3], m - r, m + r + 1, layer[4])
	end
end

-- A tall narrow tree (footprint n-2..n+3, m-1..m+2).
function Props.poplar(kit: any, city: Instance, side: number, n: number, m: number)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "VoxelPoplar"), side, kit.levels.lawn)
	v("Trunk", n, n + 1, 0, 2, m, m + 1, c.Wood)
	v("Crown", n - 1, n + 2, 2, 9, m - 1, m + 2, c.Leaf)
	v("Crown", n, n + 1, 9, 11, m, m + 1, c.LeafLight)
	v("LeafBump", n + 2, n + 3, 5, 7, m, m + 1, c.LeafLight)
	v("LeafBump", n - 2, n - 1, 3, 5, m, m + 1, c.LeafDark)
end

function Props.bush(kit: any, city: Instance, side: number, n: number, m: number)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "VoxelBush"), side, kit.levels.lawn)
	v("Leaves", n - 1, n + 2, 0, 1, m, m + 2, c.Leaf)
	v("Leaves", n, n + 1, 1, 2, m, m + 1, c.LeafLight)
end

-- A clipped hedge with light lumps on top.
function Props.hedge(
	kit: any,
	city: Instance,
	side: number,
	level: number,
	n0: number,
	n1: number,
	m0: number,
	m1: number,
	rows: number
)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "Hedge"), side, level)
	v("Hedge", n0, n1, 0, rows, m0, m1, c.Leaf)
	for m = m0 + 1, m1 - 3, 5 do
		v("HedgeTop", n0, n1, rows, rows + 1, m, m + 3, c.LeafLight)
	end
end

-- A planter of pixel flowers, 3 columns wide.
function Props.flowerbed(kit: any, city: Instance, side: number, n0: number, m0: number, length: number, seed: number)
	local c = kit.colors
	local v = Props.writer(kit, kit.model(city, "FlowerBed"), side, kit.levels.lawn)
	v("Planter", n0, n0 + 3, 0, 1, m0, m0 + length, c.WoodDark)
	local keys = { "FlowerPink", "FlowerYellow", "FlowerRed", "FlowerWhite", "FlowerBlue" }
	local rects = Grid.rectangles(length, 3, function(x: number, y: number): string?
		if (x + y) % 2 == 1 then
			return "Leaf"
		end
		return Props.pick(keys, Grid.hash(x, y, seed))
	end)
	for _, r in rects do
		v(r.key, n0 + r.y0, n0 + r.y1 + 1, 1, 2, m0 + r.x0, m0 + r.x1 + 1, c[r.key])
	end
end

-- Buildings ------------------------------------------------------------------------------

-- A lawn building whose facade column n0 faces the pitch: floor bands, windows (a few lit),
-- an optional shop front under a striped awning or a plain sign band, a parapet and roof clutter.
-- spec = { n0, n1, m0, m1, floors, wall, trim, roof, seed, shop?, awning?, signColor?,
--          roofless?, name? }; a roofless building returns its wall height for a custom roof.
function Props.building(kit: any, city: Instance, side: number, spec: any): (Model, number)
	local c = kit.colors
	local model = kit.model(city, spec.name or "CityBuilding")
	local v = Props.writer(kit, model, side, kit.levels.lawn)
	local n0, n1, m0, m1 = spec.n0, spec.n1, spec.m0, spec.m1
	local length, rows = m1 - m0, spec.floors * 3
	local door = length // 2
	-- Muted glass keeps the facade one colour with a window rhythm, not a checkerboard.
	local colors = {
		Wall = spec.wall,
		Trim = spec.trim,
		Window = c.Glass:Lerp(c.Ink, 0.45),
		Lit = c.WindowLit,
		Door = c.Ink,
		Shop = c.Glass,
		Sign = spec.signColor or spec.trim,
	}
	local rects = Grid.rectangles(length, rows, function(x: number, y: number): string?
		if y < 3 then
			if y < 2 and (x == door or x == door - 1) then
				return "Door"
			elseif spec.shop then
				if y == 2 then
					return "Sign"
				end
				return if x % 6 == 0 or x == length - 1 then "Wall" else "Shop"
			end
		end
		if y % 3 == 0 then
			return if y == 0 then "Wall" else "Trim"
		end
		if (x % 4 == 1 or x % 4 == 2) and x < length - 1 then
			return if Grid.hash(x // 4, y // 3, spec.seed) < 0.1 then "Lit" else "Window"
		end
		return "Wall"
	end)
	for _, r in rects do
		v(r.key, n0, n0 + 1, r.y0, r.y1 + 1, m0 + r.x0, m0 + r.x1 + 1, colors[r.key])
	end
	v("Body", n0 + 1, n1, 0, rows, m0, m1, spec.wall)
	if spec.awning then
		for m = m0, m1 - 1, 2 do
			local stripe = if ((m - m0) // 2) % 2 == 0 then spec.awning[1] else spec.awning[2]
			v("Awning", n0 - 1, n0, 2, 3, m, math.min(m + 2, m1), stripe)
		end
	end
	if spec.roofless then
		return model, rows
	end
	v("Roof", n0, n1, rows, rows + 1, m0, m1, spec.roof)
	v("Parapet", n0, n0 + 1, rows + 1, rows + 2, m0, m1, spec.trim)
	-- Roof clutter: a water tank on long roofs, otherwise an air-conditioning box.
	local h = Grid.hash(m0, rows, spec.seed + 9)
	local top = rows + 1
	if length >= 14 and h < 0.5 then
		local tm = m0 + 3 + math.floor(h * 6)
		for _, leg in { { n0 + 3, tm }, { n0 + 5, tm }, { n0 + 3, tm + 3 }, { n0 + 5, tm + 3 } } do
			v("TankLeg", leg[1], leg[1] + 1, top, top + 2, leg[2], leg[2] + 1, c.WoodDark)
		end
		v("WaterTank", n0 + 3, n0 + 6, top + 2, top + 5, tm, tm + 4, c.Wood)
		v("TankRoof", n0 + 4, n0 + 5, top + 5, top + 6, tm + 1, tm + 3, c.WoodDark)
	else
		local am = m0 + 2 + math.floor(h * math.max(1, length - 6))
		v("AirUnit", n0 + 2, n0 + 5, top, top + 2, am, am + 3, c.Concrete)
		v("AirFan", n0 + 3, n0 + 4, top + 2, top + 3, am + 1, am + 2, c.Black)
	end
	return model, rows + 2
end

-- A ribbed shipping container: eight slices along the course, the last one its doors.
function Props.container(kit: any, city: Instance, side: number, n0: number, m0: number, r0: number, color: Color3)
	local v = Props.writer(kit, kit.model(city, "ShippingContainer"), side, kit.levels.lawn)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.16)
	for i = 0, 7 do
		v(
			if i == 7 then "Doors" else "Rib",
			n0,
			n0 + 3,
			r0,
			r0 + 3,
			m0 + i,
			m0 + i + 1,
			if i % 2 == 0 then color else dark
		)
	end
end

-- A gold cup: base, stem, narrow and wide bowl rows and two handles. Footprint n0-1..n0+7.
function Props.trophy(v: any, n0: number, m0: number, r0: number, gold: Color3, dark: Color3)
	v("TrophyBase", n0 + 1, n0 + 5, r0, r0 + 1, m0 + 1, m0 + 5, dark)
	v("TrophyStem", n0 + 2, n0 + 4, r0 + 1, r0 + 3, m0 + 2, m0 + 4, gold)
	v("TrophyCup", n0 + 1, n0 + 5, r0 + 3, r0 + 4, m0 + 1, m0 + 5, gold)
	v("TrophyCup", n0, n0 + 6, r0 + 4, r0 + 6, m0, m0 + 6, gold)
	v("TrophyHandle", n0 - 1, n0, r0 + 4, r0 + 6, m0 + 2, m0 + 4, dark)
	v("TrophyHandle", n0 + 6, n0 + 7, r0 + 4, r0 + 6, m0 + 2, m0 + 4, dark)
end

-- A railing along the course: posts every eight rows under one top rail.
function Props.fence(
	kit: any,
	city: Instance,
	side: number,
	level: number,
	n: number,
	m0: number,
	m1: number,
	color: Color3,
	height: number
)
	local v = Props.writer(kit, kit.model(city, "Railing"), side, level)
	for m = m0, m1 - 1, 8 do
		v("RailPost", n, n + 1, 0, height, m, m + 1, color)
	end
	v("TopRail", n, n + 1, height, height + 1, m0, m1, color)
end

return Props
