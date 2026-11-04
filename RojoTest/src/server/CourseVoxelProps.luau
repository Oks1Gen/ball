--!strict
-- Voxel props per course location (docs/course-voxel.md). Cells: u = n * p across,
-- s = m * p along; the pitch spans n -28..28 and rows 0..269, the terrace n 28..39,
-- the lawn n 39..52 (mirrored for the west side). Studs only on whole-cell top faces.
local Props = {}
local Landmarks = require(script.Parent.FootballCityLandmarks)
local C = Color3.fromRGB
local FLAG_RED = C(232, 72, 58)

local function flip(side: number, n0: number, n1: number): (number, number)
	if side > 0 then
		return n0, n1
	end
	return -n1, -n0
end

-- Cell helper for one side: n is measured outward from the field centre line.
local function sided(kit: any, model: Model, side: number)
	return function(
		name: string,
		n0: number,
		n1: number,
		h0: number,
		h1: number,
		m0: number,
		m1: number,
		color: Color3,
		top: boolean?
	): Part
		local a, b = flip(side, n0, n1)
		return kit.cells(model, name, a, b, h0, h1, m0, m1, color, top)
	end
end

local function goal(kit: any, city: Model, row: number, dir: number)
	local colors, p, base = kit.colors, kit.p, kit.levels.base
	local model = kit.model(city, "FootballGoal")
	local top = base + 6 * p
	for _, n in { -5, 4 } do
		kit.cells(model, "Post", n, n + 1, base, base + 5 * p, row, row + 1, colors.White)
	end
	kit.cells(model, "Crossbar", -5, 5, base + 5 * p, top, row, row + 1, colors.White, true)
	-- The net hangs on the stud grid behind the goal line. Crossing cords are offset by
	-- a cord width, so no two cords share an exposed plane.
	local cord, half = 0.12, 0.06
	local front = p * (if dir < 0 then row else row + 1)
	local back = front + dir * 3 * p
	local s0, s1 = math.min(front, back), math.max(front, back)
	local function cordBox(u0: number, u1: number, h0: number, h1: number, a0: number, a1: number)
		kit.box(model, "NetCord", u0, u1, h0, h1, a0, a1, colors.White, nil, true)
	end
	for n = -5, 5 do
		cordBox(n * p - half, n * p + half, base, top - cord, back - half, back + half)
		cordBox(n * p - half, n * p + half, top - cord, top, s0, s1)
	end
	local rail = back + dir * cord
	for i = 1, 5 do
		local h = base + i * p
		cordBox(-6 - half, 6 + half, h - half, h + half, rail - half, rail + half)
		for _, u in { -6 - cord, 6 + cord } do
			cordBox(u - half, u + half, h - half, h + half, s0, s1)
		end
	end
	for j = 1, 2 do
		local s = back - dir * j * p
		cordBox(-6, 6, top - 2 * cord, top - cord, s - half, s + half)
		for _, u in { -6, 6 } do
			cordBox(u - half, u + half, base, top - 2 * cord, s - half, s + half)
		end
	end
end

local function cornerFlag(kit: any, city: Model, n: number, m: number, accent: Color3)
	local colors, p, base = kit.colors, kit.p, kit.levels.base
	local model = kit.model(city, "CornerFlag")
	local u, s = (n + 0.5) * p, (m + 0.5) * p
	local top = base + 3 * p
	kit.box(model, "Pole", u - 0.12, u + 0.12, base, top, s - 0.12, s + 0.12, colors.White, nil, true)
	local dir = if u < 0 then 1 else -1
	for a = 0, 1 do
		for b = 0, 1 do
			local near, far = u + dir * (0.12 + a * 0.6), u + dir * (0.12 + (a + 1) * 0.6)
			kit.box(
				model,
				"FlagPixel",
				math.min(near, far),
				math.max(near, far),
				top - (b + 1) * 0.6,
				top - b * 0.6,
				s - 0.05,
				s + 0.05,
				if (a + b) % 2 == 0 then accent else FLAG_RED,
				nil,
				true
			)
		end
	end
end

-- Three stepped seat rows on a terrace; aisles split the seats into blocks of five.
local function grandstand(kit: any, city: Model, side: number, m0: number, length: number, accent: Color3)
	local colors, p, t1 = kit.colors, kit.p, kit.levels.terrace
	local model = kit.model(city, "Grandstand")
	local cell = sided(kit, model, side)
	for step = 1, 3 do
		local n0, n1 = 28 + 1 + (step - 1) * 3, 28 + 1 + step * 3
		local seatTop = t1 + step * p
		if step > 1 then
			cell("StandTier", n0, n1, t1, seatTop - p, m0, m0 + length, colors.Curb)
		end
		local m = m0
		while m < m0 + length do
			local function key(x: number): string
				if (x - m0) % 6 == 0 then
					return "Aisle"
				end
				return if ((x - m0) // 6 + step) % 2 == 0 then "Accent" else "White"
			end
			local k, last = key(m), m
			while last + 1 < m0 + length and key(last + 1) == k do
				last += 1
			end
			local color = if k == "Aisle" then colors.Curb elseif k == "Accent" then accent else colors.White
			cell(if k == "Aisle" then "Aisle" else "Seats", n0, n1, seatTop - p, seatTop, m, last + 1, color, true)
			m = last + 1
		end
	end
	local roof = t1 + 8 * p
	for _, m in { m0, m0 + length - 1 } do
		cell("CanopyColumn", 37, 38, t1 + 3 * p, roof, m, m + 1, colors.Ink)
	end
	cell("CanopyFascia", 29, 30, roof, roof + p, m0 - 1, m0 + length + 1, accent, true)
	cell("Canopy", 30, 38, roof, roof + p, m0 - 1, m0 + length + 1, colors.White, true)
end

local function dugout(kit: any, city: Model, side: number, m0: number, accent: Color3)
	local colors, p, t1 = kit.colors, kit.p, kit.levels.terrace
	local model = kit.model(city, "Dugout")
	local cell = sided(kit, model, side)
	cell("BackWall", 31, 32, t1, t1 + 3 * p, m0, m0 + 7, colors.Ink)
	for _, m in { m0, m0 + 6 } do
		cell("SideWall", 29, 31, t1, t1 + 3 * p, m, m + 1, colors.Ink)
	end
	cell("Bench", 30, 31, t1, t1 + p, m0 + 1, m0 + 6, accent, true)
	cell("RoofEdge", 29, 30, t1 + 3 * p, t1 + 4 * p, m0, m0 + 7, accent, true)
	cell("Roof", 30, 32, t1 + 3 * p, t1 + 4 * p, m0, m0 + 7, colors.White, true)
end

local function floodlight(kit: any, city: Model, side: number, m: number, accent: Color3)
	local colors, p, t2 = kit.colors, kit.p, kit.levels.lawn
	local model = kit.model(city, "Floodlight")
	local cell = sided(kit, model, side)
	cell("Footing", 47, 50, t2, t2 + p, m - 1, m + 2, colors.Stone, true)
	cell("Mast", 48, 49, t2 + p, t2 + 11 * p, m, m + 1, colors.Ink)
	cell("MastBand", 48, 49, t2 + 11 * p, t2 + 12 * p, m, m + 1, accent)
	cell("Mast", 48, 49, t2 + 12 * p, t2 + 14 * p, m, m + 1, colors.Ink)
	cell("Housing", 47, 49, t2 + 14 * p, t2 + 18 * p, m - 2, m + 3, colors.Ink, true)
	-- Pixel lamps on the pitch-facing side of the housing.
	for dm = -1, 1 do
		for row = 15, 16 do
			local a, b = flip(side, 47 * p - 0.1, 47 * p)
			local lamp = kit.box(
				model,
				"Lamp",
				a,
				b,
				t2 + row * p + 0.15,
				t2 + (row + 1) * p - 0.15,
				(m + dm) * p + 0.15,
				(m + dm + 1) * p - 0.15,
				colors.Lamp,
				nil,
				true
			)
			lamp.Material = Enum.Material.Neon
		end
	end
end

local function tree(kit: any, city: Model, side: number, n: number, m: number)
	local colors, p, t2 = kit.colors, kit.p, kit.levels.lawn
	local model = kit.model(city, "VoxelTree")
	local cell = sided(kit, model, side)
	cell("Trunk", n, n + 1, t2, t2 + 3 * p, m, m + 1, colors.Wood)
	for _, layer in
		{
			{ 2, 3, 4, colors.Leaf },
			{ 3, 4, 6, colors.Leaf },
			{ 2, 6, 7, colors.LeafLight },
			{ 1, 7, 8, colors.LeafLight },
		}
	do
		local r = layer[1]
		cell("Canopy", n - r, n + r + 1, t2 + layer[2] * p, t2 + layer[3] * p, m - r, m + r + 1, layer[4], true)
	end
	for _, offset in { { -4, -1 }, { 4, 1 }, { 1, -4 }, { -1, 4 } } do
		local bn, bm = n + offset[1], m + offset[2]
		cell("LeafBump", bn, bn + 1, t2 + 4 * p, t2 + 5 * p, bm, bm + 1, colors.LeafLight, true)
	end
end

local function bush(kit: any, city: Model, side: number, n: number, m: number)
	local colors, p, t2 = kit.colors, kit.p, kit.levels.lawn
	local model = kit.model(city, "VoxelBush")
	local cell = sided(kit, model, side)
	cell("Leaves", n - 1, n + 2, t2, t2 + p, m, m + 2, colors.Leaf, true)
	cell("Leaves", n, n + 1, t2 + p, t2 + 2 * p, m, m + 1, colors.LeafLight, true)
end

local function scoreboard(kit: any, city: Model, side: number, m0: number, title: string, accent: Color3)
	local colors, p, t2 = kit.colors, kit.p, kit.levels.lawn
	local model = kit.model(city, "Scoreboard")
	local cell = sided(kit, model, side)
	for _, m in { m0 + 1, m0 + 11 } do
		cell("Leg", 45, 46, t2, t2 + 6 * p, m, m + 1, colors.Ink)
	end
	local board = cell("Board", 45, 46, t2 + 6 * p, t2 + 11 * p, m0, m0 + 13, colors.Ink)
	cell("Header", 45, 46, t2 + 11 * p, t2 + 12 * p, m0, m0 + 13, accent, true)
	kit.text(
		board,
		title .. "\nHOME  0 : 0  AWAY",
		if side > 0 then Enum.NormalId.Left else Enum.NormalId.Right,
		colors.White
	)
end

local function pennant(kit: any, city: Model, side: number, m: number, label: string, accent: Color3)
	local colors, p, t2 = kit.colors, kit.p, kit.levels.lawn
	local model = kit.model(city, "TournamentPennant")
	local cell = sided(kit, model, side)
	cell("Base", 50, 51, t2, t2 + p, m, m + 1, colors.Stone, true)
	local u0, u1 = flip(side, 50.5 * p - 0.15, 50.5 * p + 0.15)
	local s = (m + 0.5) * p
	kit.box(model, "Pole", u0, u1, t2 + p, t2 + 9 * p, s - 0.15, s + 0.15, colors.Ink, nil, true)
	local f0, f1 = flip(side, 46 * p, 50.5 * p - 0.15)
	local flag = kit.box(model, "Flag", f0, f1, t2 + 6 * p, t2 + 9 * p, s - 0.1, s + 0.1, accent, nil, true)
	kit.text(flag, label, Enum.NormalId.Back, colors.Ink)
	kit.text(flag, label, Enum.NormalId.Front, colors.Ink)
end

local function landmark(kit: any, city: Model, field: BasePart, side: number, m0: number, title: string, accent: Color3)
	local colors, p, t1 = kit.colors, kit.p, kit.levels.terrace
	local model = kit.model(city, "LocalClubTower")
	model:SetAttribute("CityLandmark", true)
	model:SetAttribute("LandmarkSignature", Landmarks.signature(field))
	local cell = sided(kit, model, side)
	cell("Plinth", 30, 37, t1, t1 + p, m0 - 1, m0 + 6, colors.Ink, true)
	local h = t1 + p
	for i, band in { 3, 1, 3, 1, 3, 1, 2 } do
		cell(
			if i % 2 == 0 then "ClubTrim" else "ClubPylon",
			31,
			36,
			h,
			h + band * p,
			m0,
			m0 + 5,
			if i % 2 == 0 then accent else colors.Ink
		)
		h += band * p
	end
	cell("ClubCap", 30, 37, h, h + p, m0 - 1, m0 + 6, accent, true)
	cell("ClubCrown", 32, 35, h + p, h + 2 * p, m0 + 1, m0 + 4, colors.White, true)
	local a, b = flip(side, 29 * p, 38 * p)
	local sign = kit.box(model, "Advertisement", a, b, t1 + 9 * p, t1 + 13 * p, m0 * p - 0.5, m0 * p, accent, nil, true)
	kit.text(sign, title, Enum.NormalId.Back, colors.Ink)
end

-- "Football Field": the local club ground in front of the Kick Zone.
function Props.footballField(kit: any, city: Model, theme: any, index: number, field: BasePart)
	local accent = theme.accent
	local label = string.format("%02d", index)
	local last = kit.rows - 1
	goal(kit, city, 10, -1)
	goal(kit, city, last - 9, 1)
	for _, n in { -27, 26 } do
		for _, m in { 10, last - 9 } do
			cornerFlag(kit, city, n, m, accent)
		end
	end
	grandstand(kit, city, -1, 123, 25, accent)
	for _, m in { 126, 138 } do
		dugout(kit, city, 1, m, accent)
	end
	for _, side in { -1, 1 } do
		for _, m in { 47, last - 46 } do
			floodlight(kit, city, side, m, accent)
		end
		for _, m in { 71, last - 70 } do
			tree(kit, city, side, 45, m)
		end
		for _, m in { 7, last - 6 } do
			pennant(kit, city, side, m, label, accent)
		end
		task.wait()
	end
	for _, m in { 30, 112, 180, 236 } do
		bush(kit, city, -1, 42, m)
	end
	for _, m in { 24, 100, 178, 246 } do
		bush(kit, city, 1, 42, m)
	end
	scoreboard(kit, city, 1, 151, "LOCAL FOOTBALL", accent)
	landmark(kit, city, field, -1, 255, string.format("%s  %s", label, string.upper(theme.name)), accent)
end

return Props
