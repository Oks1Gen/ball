--!strict
-- Voxel scenes per course location (docs/course-voxel.md). Each entry gives the ground look
-- (terrace, lawn and wall patterns plus colours) and a builder that fills the zone's
-- Cityscape with whole-cell props. Layouts assume 270 rows per zone; n is measured outward
-- per side: boards stand on n 29, terrace props on n 30..39, lawn props on n 39..52.
-- Every location has pitch-side boards.
local Locations = {}
local Grid = require(game.ReplicatedStorage.Shared.Core.VoxelGrid)
local Props = require(script.Parent.CourseVoxelProps)
local C = Color3.fromRGB
local N = Enum.NormalId
local NEON = Enum.Material.Neon

local function darker(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

-- Location names appear on their sideline signs.
local function title(theme: any): string
	return string.upper(theme.name)
end

-- Plain pitch-side boards in the location's own colours.
local function boards(kit: any, city: Instance, colors: { Color3 })
	Props.adBoards(kit, city, -1, { { 1, kit.rows - 1 } }, colors, 0)
	Props.adBoards(kit, city, 1, { { 1, kit.rows - 1 } }, colors, 1)
end

local function floodlights(kit: any, city: Instance, accent: Color3)
	for _, side in { -1, 1 } do
		for _, m in { 47, kit.rows - 47 } do
			Props.floodlight(kit, city, side, m, accent)
		end
	end
end

local function lawnWriter(kit: any, city: Instance, name: string, side: number)
	return Props.writer(kit, kit.model(city, name), side, kit.levels.lawn)
end

local function terraceWriter(kit: any, city: Instance, name: string, side: number)
	return Props.writer(kit, kit.model(city, name), side, kit.levels.terrace)
end

-- A covered lawn stand: six tiers of fans, a back wall, end walls, a roof and a fascia.
local function lawnStand(
	kit: any,
	city: Instance,
	side: number,
	m0: number,
	m1: number,
	colors: { Color3 },
	shirts: { Color3 },
	density: number,
	seed: number
)
	local c = kit.colors
	local _, v = Props.stand(kit, city, side, kit.levels.lawn, {
		n0 = 40,
		depth = 2,
		tiers = 6,
		m0 = m0,
		m1 = m1,
		block = 12,
		seat = function(t: number, b: number): Color3
			return if t == 5 then c.White else colors[b % #colors + 1]
		end,
		riser = c.Concrete,
		shirts = shirts,
		density = density,
		seed = seed,
	})
	v("StandBack", 51, 52, 6, 13, m0, m1, colors[1])
	for _, m in { m0 - 1, m1 } do
		v("StandEnd", 40, 52, 0, 13, m, m + 1, colors[2] or c.Ink)
	end
	v("StandRoof", 40, 52, 13, 14, m0 - 1, m1 + 1, c.White)
	v("RoofFascia", 39, 40, 12, 14, m0 - 1, m1 + 1, colors[1])
end

-- A small stand on the terrace: four tiers of fans, optionally under a canopy. It stops at
-- n 38 so no tier shares the step wall's top or bottom plane.
local function terraceStand(
	kit: any,
	city: Instance,
	side: number,
	m0: number,
	m1: number,
	seat: { Color3 },
	shirts: { Color3 },
	seed: number,
	canopy: Color3?
)
	local c = kit.colors
	local _, v = Props.stand(kit, city, side, kit.levels.terrace, {
		n0 = 30,
		depth = 2,
		tiers = 4,
		m0 = m0,
		m1 = m1,
		block = 8,
		seat = function(t: number, b: number): Color3
			return seat[(t + b) % #seat + 1]
		end,
		riser = c.Curb,
		shirts = shirts,
		density = 0.5,
		seed = seed,
		name = if canopy then "CoveredStand" else "Bleacher",
	})
	if canopy then
		for _, m in { m0, m1 - 1 } do
			v("CanopyColumn", 37, 38, 4, 9, m, m + 1, c.Ink)
		end
		v("CanopyEdge", 30, 31, 9, 10, m0 - 1, m1 + 1, canopy)
		v("Canopy", 31, 38, 9, 10, m0 - 1, m1 + 1, c.White)
	end
end

local function ballCart(kit: any, city: Instance, side: number, m0: number, accent: Color3)
	local c = kit.colors
	local v = terraceWriter(kit, city, "BallCart", side)
	v("CartHandle", 30, 31, 0, 3, m0 + 1, m0 + 2, c.Ink)
	v("CartBase", 31, 36, 0, 1, m0, m0 + 3, c.Ink)
	for n = 31, 35 do
		for m = m0, m0 + 2 do
			if (n + m) % 2 == 0 then
				v("Ball", n, n + 1, 1, 2, m, m + 1, if (n + m) % 4 == 0 then accent else c.White)
			end
		end
	end
end

-- 01 Football Field ---------------------------------------------------------------------

local function clubTower(kit: any, city: Instance, field: BasePart, index: number, theme: any, m0: number)
	local c, accent = kit.colors, theme.accent
	local v = Props.writer(kit, Props.landmark(kit, city, field, index), -1, kit.levels.terrace)
	v("Plinth", 30, 37, 0, 1, m0 - 1, m0 + 6, c.Ink)
	local h = 1
	for i, band in { 3, 1, 3, 1, 3, 1, 2 } do
		local trim = i % 2 == 0
		v(if trim then "ClubTrim" else "ClubPylon", 31, 36, h, h + band, m0, m0 + 5, if trim then accent else c.Navy)
		h += band
	end
	v("ClubCap", 30, 37, h, h + 1, m0 - 1, m0 + 6, accent)
	v("ClubCrown", 32, 35, h + 1, h + 2, m0 + 1, m0 + 4, c.White)
	local sign = v("Advertisement", 30, 38, 9, 13, m0 - 1, m0, accent)
	kit.text(sign, title(theme), N.Back, c.Navy)
end

local function trainingCones(kit: any, city: Instance, side: number, m0: number, m1: number)
	local c = kit.colors
	local v = terraceWriter(kit, city, "TrainingCones", side)
	local i = 0
	for m = m0, m1 - 1, 4 do
		local n = if i % 2 == 0 then 32 else 35
		v("Cone", n, n + 1, 0, 1, m, m + 1, c.Orange)
		v("ConeTip", n, n + 1, 1, 2, m, m + 1, c.White)
		i += 1
	end
end

local function clubhouse(kit: any, city: Instance, side: number, m0: number, m1: number, accent: Color3)
	local c = kit.colors
	local model, rows = Props.building(kit, city, side, {
		n0 = 42,
		n1 = 52,
		m0 = m0,
		m1 = m1,
		floors = 2,
		wall = c.Cream,
		trim = c.Navy,
		roof = c.Brick,
		seed = m0,
		shop = true,
		roofless = true,
		name = "Clubhouse",
	})
	local v = Props.writer(kit, model, side, kit.levels.lawn)
	-- Stepped gable roof running along the course.
	for i = 0, 4 do
		v(
			"RoofStep",
			42 + i,
			52 - i,
			rows + i,
			rows + i + 1,
			m0 - 1,
			m1 + 1,
			if i % 2 == 0 then c.Brick else c.BrickDark
		)
	end
	v("Balcony", 41, 42, 3, 4, m0 + 6, m1 - 6, c.White)
	v("BalconyRail", 41, 42, 4, 5, m0 + 6, m1 - 6, accent)
end

local function footballField(kit: any, city: Instance, theme: any, index: number, field: BasePart)
	local c, accent = kit.colors, theme.accent
	local last = kit.rows - 1
	local fans = { accent, c.Navy, c.White, accent, c.Red }
	boards(kit, city, { accent, c.Navy })
	for _, n in { -27, 26 } do
		for _, m in { 10, last - 9 } do
			Props.cornerFlag(kit, city, n, m, accent)
		end
	end
	floodlights(kit, city, accent)
	for _, side in { -1, 1 } do
		for _, m in { 90, 180, 240 } do
			Props.lampPost(kit, city, side, 37, m, kit.levels.terrace, 5)
		end
	end
	task.wait()

	-- West: the covered club stand, dugouts, drills and the club tower.
	lawnStand(kit, city, -1, 95, 175, { accent, c.Navy }, fans, 0.4, 11)
	task.wait()
	for _, m in { 120, 140 } do
		Props.dugout(kit, city, -1, m, accent)
	end
	trainingCones(kit, city, -1, 30, 58)
	clubTower(kit, city, field, index, theme, 255)
	Props.tree(kit, city, -1, 45, 20)
	Props.tree(kit, city, -1, 45, 33, "blossom")
	Props.flowerbed(kit, city, -1, 40, 44, 8, 1)
	Props.tree(kit, city, -1, 45, 62)
	Props.pine(kit, city, -1, 45, 75)
	Props.poplar(kit, city, -1, 44, 86)
	Props.tree(kit, city, -1, 45, 186)
	Props.bigTree(kit, city, -1, 44, 203)
	Props.tree(kit, city, -1, 45, 236, "autumn")
	Props.flowerbed(kit, city, -1, 40, 244, 8, 2)
	task.wait()

	-- East: a family stand on the terrace, the clubhouse and scoreboard on the lawn.
	terraceStand(kit, city, 1, 118, 150, { accent, c.White }, fans, 21, accent)
	ballCart(kit, city, 1, 40, accent)
	for _, m in { 170, 228 } do
		Props.bench(kit, city, 1, kit.levels.terrace, 34, m, 6, accent)
	end
	clubhouse(kit, city, 1, 100, 160, accent)
	Props.scoreboard(kit, city, 1, 60, accent)
	Props.tree(kit, city, 1, 45, 20)
	Props.poplar(kit, city, 1, 44, 32)
	Props.tree(kit, city, 1, 45, 85, "blossom")
	Props.bush(kit, city, 1, 42, 92)
	Props.tree(kit, city, 1, 45, 172)
	Props.pine(kit, city, 1, 45, 186)
	Props.bigTree(kit, city, 1, 44, 203, "autumn")
	Props.tree(kit, city, 1, 45, 237)
	Props.flowerbed(kit, city, 1, 40, 244, 8, 3)
end

-- 02 Park Football ----------------------------------------------------------------------

local function pavilion(kit: any, city: Instance, field: BasePart, index: number, theme: any, m0: number)
	local c, accent = kit.colors, theme.accent
	local v = Props.writer(kit, Props.landmark(kit, city, field, index), -1, kit.levels.terrace)
	for _, n in { 30, 37 } do
		v("GatePost", n, n + 1, 0, 8, m0, m0 + 1, c.Wood)
	end
	local sign = v("Sign", 30, 38, 8, 11, m0, m0 + 1, accent)
	kit.text(sign, title(theme), N.Back, c.Ink)
	local p0 = m0 + 3
	v("Plinth", 30, 38, 0, 1, p0, p0 + 10, c.Stone)
	for _, n in { 31, 36 } do
		for _, m in { p0 + 1, p0 + 8 } do
			v("TimberColumn", n, n + 1, 1, 6, m, m + 1, c.Wood)
		end
	end
	v("PavilionBench", 33, 35, 1, 2, p0 + 3, p0 + 7, c.WoodDark)
	v("Roof", 30, 38, 6, 7, p0, p0 + 10, accent)
	v("Roof", 31, 37, 7, 8, p0 + 1, p0 + 9, c.White)
	v("Roof", 32, 36, 8, 9, p0 + 2, p0 + 8, accent)
	v("Roof", 33, 35, 9, 10, p0 + 3, p0 + 7, c.White)
	v("Finial", 33, 35, 10, 11, p0 + 4, p0 + 6, c.Gold)
end

local function pergola(kit: any, city: Instance, side: number, m0: number, m1: number, seed: number)
	local c = kit.colors
	local v = terraceWriter(kit, city, "ParkPergola", side)
	for m = m0, m1 - 1, 8 do
		for _, n in { 30, 37 } do
			v("Column", n, n + 1, 0, 5, m, m + 1, c.Wood)
		end
	end
	for _, n in { 30, 37 } do
		v("Beam", n, n + 1, 5, 6, m0, m1, c.WoodDark)
	end
	for m = m0, m1 - 1, 2 do
		v("Slat", 30, 38, 6, 7, m, m + 1, c.WoodLight)
		local h = Grid.hash(m, 0, seed)
		if h < 0.55 then
			local n = 30 + math.floor(Grid.hash(m, 1, seed) * 6)
			v(if h < 0.2 then "Bloom" else "Vine", n, n + 2, 7, 8, m, m + 1, if h < 0.2 then c.Blossom else c.Leaf)
		end
	end
end

local function fountain(kit: any, city: Instance, side: number, m0: number)
	local c = kit.colors
	local v = lawnWriter(kit, city, "ParkFountain", side)
	for _, m in { m0, m0 + 9 } do
		v("BasinRim", 41, 51, 0, 2, m, m + 1, c.Stone)
	end
	for _, n in { 41, 50 } do
		v("BasinRim", n, n + 1, 0, 2, m0 + 1, m0 + 9, c.Stone)
	end
	v("Water", 42, 50, 0, 1, m0 + 1, m0 + 9, c.Water)
	v("Pedestal", 45, 47, 1, 3, m0 + 4, m0 + 6, c.StoneLight)
	v("Jet", 45, 47, 3, 6, m0 + 4, m0 + 6, c.WaterLight)
	v("Splash", 44, 48, 6, 7, m0 + 3, m0 + 7, c.WaterLight)
end

local function pond(kit: any, city: Instance, side: number, m0: number, m1: number)
	local c = kit.colors
	local v = lawnWriter(kit, city, "ParkPond", side)
	for _, m in { m0, m1 - 1 } do
		v("PondRim", 41, 51, 0, 2, m, m + 1, c.Stone)
	end
	for _, n in { 41, 50 } do
		v("PondRim", n, n + 1, 0, 2, m0 + 1, m1 - 1, c.Stone)
	end
	v("Water", 42, 50, 0, 1, m0 + 1, m1 - 1, c.Water)
	-- Lily pads, ducks and reeds sit on the water surface.
	for i, pad in { { 44, 5 }, { 47, 9 }, { 43, 15 }, { 48, 20 }, { 45, 27 }, { 47, 31 } } do
		local m = m0 + pad[2]
		v("LilyPad", pad[1], pad[1] + 1, 1, 2, m, m + 1, c.LeafLight)
		if i % 2 == 1 then
			v("LilyFlower", pad[1], pad[1] + 1, 2, 3, m, m + 1, c.Blossom)
		end
	end
	for _, duck in { { 46, 11 }, { 44, 22 } } do
		local n, m = duck[1], m0 + duck[2]
		v("DuckBody", n, n + 1, 1, 2, m, m + 2, c.White)
		v("DuckHead", n, n + 1, 2, 3, m + 1, m + 2, c.White)
		v("DuckBeak", n, n + 1, 2, 3, m + 2, m + 3, c.Orange)
	end
	for _, reed in { { 42, 1 }, { 49, m1 - m0 - 2 } } do
		v("Reed", reed[1], reed[1] + 1, 1, 4, m0 + reed[2], m0 + reed[2] + 1, c.LeafDark)
	end
end

local function playground(kit: any, city: Instance, side: number, m0: number)
	local c = kit.colors
	local v = lawnWriter(kit, city, "Playground", side)
	v("SandPit", 40, 52, 0, 1, m0, m0 + 30, c.Sand)
	-- Slide tower: posts, platform, roof, ladder and a stepped slide.
	for _, n in { 44, 48 } do
		for _, m in { m0 + 3, m0 + 7 } do
			v("TowerPost", n, n + 1, 1, 6, m, m + 1, c.Red)
			v("TowerPost", n, n + 1, 7, 10, m, m + 1, c.Red)
		end
	end
	v("Platform", 44, 49, 6, 7, m0 + 3, m0 + 8, c.Yellow)
	v("TowerRoof", 44, 49, 10, 11, m0 + 3, m0 + 8, c.Red)
	v("TowerRoof", 45, 48, 11, 12, m0 + 4, m0 + 7, c.Yellow)
	for _, n in { 45, 47 } do
		v("LadderRail", n, n + 1, 1, 6, m0 + 2, m0 + 3, c.Blue)
	end
	for _, r in { 2, 4 } do
		v("LadderRung", 46, 47, r, r + 1, m0 + 2, m0 + 3, c.Yellow)
	end
	for i = 0, 4 do
		v("Slide", 45, 48, 5 - i, 6 - i, m0 + 8 + i, m0 + 9 + i, c.Blue)
	end
	-- Swings under an A-frame beam.
	for _, m in { m0 + 17, m0 + 27 } do
		for _, n in { 43, 49 } do
			v("SwingPost", n, n + 1, 1, 9, m, m + 1, c.Teal)
		end
		v("SwingFrame", 43, 50, 9, 10, m, m + 1, c.Teal)
	end
	v("SwingBeam", 46, 47, 9, 10, m0 + 18, m0 + 27, c.Teal)
	for i, m in { m0 + 20, m0 + 24 } do
		v("SwingChain", 46, 47, 3, 9, m, m + 1, c.Steel)
		v("SwingSeat", 45, 48, 2, 3, m, m + 1, if i == 1 then c.Red else c.Yellow)
	end
end

local function picnic(kit: any, city: Instance, side: number, m0: number, canopy: Color3)
	local c = kit.colors
	local v = lawnWriter(kit, city, "PicnicTable", side)
	for _, n in { 43, 46 } do
		for _, m in { m0 + 1, m0 + 3 } do
			v("TableLeg", n, n + 1, 0, 2, m, m + 1, c.WoodDark)
		end
	end
	v("TableTop", 43, 47, 2, 3, m0, m0 + 5, c.Wood)
	v("PicnicSeat", 41, 42, 0, 1, m0, m0 + 5, c.WoodLight)
	v("PicnicSeat", 48, 49, 0, 1, m0, m0 + 5, c.WoodLight)
	v("UmbrellaPole", 45, 46, 3, 7, m0 + 2, m0 + 3, c.White)
	v("Umbrella", 42, 49, 7, 8, m0 - 1, m0 + 1, canopy)
	v("Umbrella", 42, 49, 7, 8, m0 + 1, m0 + 4, c.White)
	v("Umbrella", 42, 49, 7, 8, m0 + 4, m0 + 6, canopy)
	v("UmbrellaTop", 44, 47, 8, 9, m0 + 1, m0 + 4, canopy)
end

local function iceCream(kit: any, city: Instance, side: number, m0: number)
	local c = kit.colors
	local v = terraceWriter(kit, city, "IceCreamCart", side)
	for _, n in { 32, 35 } do
		for _, m in { m0 + 1, m0 + 5 } do
			v("CartWheel", n, n + 1, 0, 1, m, m + 1, c.Black)
		end
	end
	v("CartBody", 31, 37, 1, 3, m0, m0 + 7, c.White)
	v("CartTrim", 31, 37, 3, 4, m0, m0 + 7, c.Blossom)
	v("Scoop", 32, 33, 4, 5, m0 + 5, m0 + 6, c.Blossom)
	v("Scoop", 32, 33, 4, 5, m0 + 1, m0 + 2, c.FlowerYellow)
	v("ParasolPole", 34, 35, 4, 8, m0 + 3, m0 + 4, c.White)
	v("Parasol", 31, 38, 8, 9, m0, m0 + 7, c.Blossom)
	v("ParasolTop", 33, 36, 9, 10, m0 + 2, m0 + 5, c.White)
end

local function park(kit: any, city: Instance, theme: any, index: number, field: BasePart)
	local c, accent = kit.colors, theme.accent
	local visitors = { c.Red, c.Blue, c.Yellow, c.White, c.Green, c.Pink, c.Orange }
	boards(kit, city, { c.LeafLight, c.Wood })
	floodlights(kit, city, accent)
	for _, side in { -1, 1 } do
		for _, m in { 25, 75, 150, 185, 225 } do
			Props.lampPost(kit, city, side, 37, m, kit.levels.terrace, 5)
		end
	end
	task.wait()

	-- West: pavilion, bleacher and benches; a pond and a playground among the trees.
	pavilion(kit, city, field, index, theme, 247)
	terraceStand(kit, city, -1, 115, 134, { c.Wood, c.WoodLight }, visitors, 31)
	for _, m in { 40, 90, 160, 200 } do
		Props.bench(kit, city, -1, kit.levels.terrace, 36, m, 5, c.Wood)
	end
	pond(kit, city, -1, 95, 131)
	playground(kit, city, -1, 160)
	Props.bigTree(kit, city, -1, 44, 18)
	Props.pine(kit, city, -1, 46, 33)
	Props.flowerbed(kit, city, -1, 40, 38, 7, 4)
	Props.tree(kit, city, -1, 45, 60, "blossom")
	Props.poplar(kit, city, -1, 43, 70)
	Props.tree(kit, city, -1, 45, 82, "autumn")
	Props.pine(kit, city, -1, 45, 140)
	Props.tree(kit, city, -1, 45, 150)
	Props.bigTree(kit, city, -1, 44, 203, "blossom")
	Props.tree(kit, city, -1, 45, 236)
	Props.poplar(kit, city, -1, 44, 246)
	Props.flowerbed(kit, city, -1, 40, 250, 8, 5)
	for _, m in { 26, 52, 90, 136, 156 } do
		Props.bush(kit, city, -1, 41, m)
	end
	task.wait()

	-- East: pergola, ice cream and benches; picnic tables, a fountain and more trees.
	pergola(kit, city, 1, 100, 141, index)
	iceCream(kit, city, 1, 60)
	for _, m in { 40, 160, 200 } do
		Props.bench(kit, city, 1, kit.levels.terrace, 36, m, 5, c.Wood)
	end
	picnic(kit, city, 1, 62, c.Red)
	picnic(kit, city, 1, 78, c.Blue)
	fountain(kit, city, 1, 128)
	Props.bigTree(kit, city, 1, 44, 18)
	Props.pine(kit, city, 1, 46, 33)
	Props.flowerbed(kit, city, 1, 40, 38, 7, 6)
	Props.tree(kit, city, 1, 45, 100, "blossom")
	Props.poplar(kit, city, 1, 44, 112)
	Props.pine(kit, city, 1, 46, 120)
	Props.tree(kit, city, 1, 45, 150, "autumn")
	Props.bigTree(kit, city, 1, 44, 168)
	Props.poplar(kit, city, 1, 44, 182)
	Props.tree(kit, city, 1, 45, 195)
	Props.flowerbed(kit, city, 1, 40, 205, 8, 7)
	Props.tree(kit, city, 1, 45, 236, "blossom")
	Props.pine(kit, city, 1, 46, 248)
end

-- 03 Street Football --------------------------------------------------------------------

local function streetSign(kit: any, city: Instance, field: BasePart, index: number, theme: any, m0: number)
	local c, accent = kit.colors, theme.accent
	local v = Props.writer(kit, Props.landmark(kit, city, field, index), -1, kit.levels.lawn)
	v("SignBase", 42, 52, 0, 1, m0, m0 + 5, c.Concrete)
	for _, n in { 43, 50 } do
		v("SignPost", n, n + 1, 1, 9, m0 + 2, m0 + 3, c.Ink)
	end
	v("NeonStrip", 44, 50, 8, 9, m0 + 2, m0 + 3, accent, NEON)
	local board = v("SignBoard", 42, 52, 9, 14, m0 + 2, m0 + 3, c.Ink)
	kit.text(board, title(theme), N.Back, accent)
	v("SignCap", 42, 52, 14, 15, m0 + 2, m0 + 3, accent)
end

local function car(kit: any, city: Instance, side: number, m0: number, color: Color3)
	local c = kit.colors
	local v = terraceWriter(kit, city, "ParkedCar", side)
	for _, n in { 30, 32 } do
		for _, m in { m0 + 1, m0 + 3 } do
			v("Wheel", n, n + 1, 0, 1, m, m + 1, c.Black)
		end
	end
	v("Body", 30, 33, 1, 2, m0, m0 + 5, color)
	v("Headlight", 30, 31, 1, 2, m0 + 5, m0 + 6, c.Lamp, NEON)
	v("Grille", 31, 32, 1, 2, m0 + 5, m0 + 6, darker(color, 0.25))
	v("Headlight", 32, 33, 1, 2, m0 + 5, m0 + 6, c.Lamp, NEON)
	v("Cabin", 30, 33, 2, 3, m0 + 1, m0 + 4, c.Glass)
	v("CarRoof", 30, 33, 3, 4, m0 + 1, m0 + 4, color)
end

local function streetLamp(kit: any, city: Instance, side: number, m: number)
	local c = kit.colors
	local v = lawnWriter(kit, city, "StreetLamp", side)
	v("Post", 40, 41, 0, 9, m, m + 1, c.SteelDark)
	v("Arm", 37, 41, 9, 10, m, m + 1, c.SteelDark)
	v("Lamp", 37, 38, 8, 9, m, m + 1, c.Lamp, NEON)
end

local function hydrant(kit: any, city: Instance, side: number, m: number)
	local c = kit.colors
	local v = lawnWriter(kit, city, "FireHydrant", side)
	v("Hydrant", 40, 41, 0, 2, m, m + 1, c.Red)
	v("HydrantCap", 40, 41, 2, 3, m, m + 1, c.Coping)
end

local function bin(kit: any, city: Instance, side: number, m: number)
	local c = kit.colors
	local v = lawnWriter(kit, city, "TrashBin", side)
	v("Bin", 41, 42, 0, 2, m, m + 1, c.Green)
	v("BinLid", 41, 42, 2, 3, m, m + 1, c.SteelDark)
end

local function planterTree(kit: any, city: Instance, side: number, m: number)
	local c = kit.colors
	local v = lawnWriter(kit, city, "StreetTree", side)
	v("Planter", 40, 43, 0, 1, m, m + 3, c.Concrete)
	v("Trunk", 41, 42, 1, 3, m + 1, m + 2, c.Wood)
	v("Canopy", 40, 43, 3, 5, m, m + 3, c.Leaf)
	v("CanopyTop", 41, 42, 5, 6, m + 1, m + 2, c.LeafLight)
end

local function street(kit: any, city: Instance, theme: any, index: number, field: BasePart)
	local c, accent = kit.colors, theme.accent
	boards(kit, city, { accent, c.Ink })
	task.wait()
	-- One block of the street; `front` adds an awning or a sign over the shop floor.
	local function block(m0: number, m1: number, floors: number, wall: Color3, trim: Color3, front: any?): any
		local spec = front or {}
		spec.m0, spec.m1, spec.floors, spec.wall, spec.trim = m0, m1, floors, wall, trim
		return spec
	end
	local function sign(color: Color3): any
		return { signColor = color }
	end
	local function awning(a: Color3, b: Color3): any
		return { awning = { a, b } }
	end
	-- Brick, render and stone facades; colour stays on the shop fronts.
	local blocks: any = {
		[-1] = {
			block(3, 25, 5, c.Brick, c.Cream, awning(c.Red, c.White)),
			block(26, 50, 6, c.Cream, c.BrickDark, sign(c.Ink)),
			block(52, 74, 4, c.BrickLight, c.Cream, awning(accent, c.White)),
			block(75, 101, 7, c.StoneLight, c.Ink, sign(c.BrickDark)),
			block(103, 127, 5, c.Brick, c.Cream, awning(c.Green, c.White)),
			block(141, 165, 6, c.Sand, c.BrickDark, sign(c.Ink)),
			block(166, 190, 4, c.BrickLight, c.Cream, awning(c.Red, c.White)),
			block(192, 216, 7, c.Cream, c.Ink, sign(c.BrickDark)),
			block(217, 240, 5, c.Brick, c.Cream, awning(accent, c.White)),
			block(258, 268, 3, c.Sand, c.BrickDark),
		},
		[1] = {
			block(3, 27, 6, c.Cream, c.Ink, sign(c.BrickDark)),
			block(28, 52, 4, c.Brick, c.Cream, awning(c.Green, c.White)),
			block(54, 80, 7, c.StoneLight, c.Ink, sign(c.Ink)),
			block(81, 105, 5, c.BrickLight, c.Cream, awning(c.Red, c.White)),
			block(121, 145, 6, c.Sand, c.BrickDark, sign(c.Ink)),
			block(146, 170, 4, c.Brick, c.Cream, awning(accent, c.White)),
			block(172, 196, 7, c.Cream, c.BrickDark, sign(c.Ink)),
			block(197, 221, 5, c.BrickLight, c.Cream, awning(c.Green, c.White)),
			block(223, 247, 6, c.StoneLight, c.Ink, sign(c.BrickDark)),
			block(248, 268, 4, c.Brick, c.Cream, awning(c.Red, c.White)),
		},
	}
	local plans: any = {
		[-1] = {
			lamps = { 14, 63, 115, 178, 228 },
			hydrants = { 40, 156 },
			bins = { 30, 94, 190, 236 },
			planters = { 20, 55, 100, 165, 210 },
			cars = { 30, 60, 112, 170, 215 },
			bench = 131,
		},
		[1] = {
			lamps = { 18, 66, 104, 172, 232 },
			hydrants = { 45, 160 },
			bins = { 34, 98, 186, 240 },
			planters = { 24, 56, 125, 150, 214 },
			cars = { 45, 95, 150, 190, 240 },
			bench = 110,
		},
	}
	local cars = { c.Red, c.Blue, c.Yellow, c.White, c.Teal, c.Orange, c.Purple }
	for _, side in { -1, 1 } do
		for i, spec in blocks[side] do
			spec.n0, spec.n1, spec.roof, spec.seed = 44, 52, c.Ink, side * 100 + i
			spec.shop = spec.signColor ~= nil or spec.awning ~= nil
			Props.building(kit, city, side, spec)
		end
		task.wait()
		local plan = plans[side]
		for _, m in plan.lamps do
			streetLamp(kit, city, side, m)
		end
		for _, m in plan.hydrants do
			hydrant(kit, city, side, m)
		end
		for _, m in plan.bins do
			bin(kit, city, side, m)
		end
		for _, m in plan.planters do
			planterTree(kit, city, side, m)
		end
		for j, m in plan.cars do
			car(kit, city, side, m, cars[(j + (if side > 0 then 3 else 0) - 1) % #cars + 1])
		end
		Props.bench(kit, city, side, kit.levels.lawn, 41, plan.bench, 5, c.Wood)
	end
	streetSign(kit, city, field, index, theme, 244)
end

-- 04 Dockyard Pitch ---------------------------------------------------------------------

local function lighthouse(kit: any, city: Instance, field: BasePart, index: number, theme: any, m0: number)
	local c = kit.colors
	local v = Props.writer(kit, Props.landmark(kit, city, field, index), -1, kit.levels.lawn)
	local sign = v("SignWall", 42, 52, 0, 4, m0, m0 + 1, theme.accent)
	kit.text(sign, title(theme), N.Back, c.Ink)
	v("Plinth", 43, 51, 0, 1, m0 + 2, m0 + 10, c.Stone)
	for i = 0, 5 do
		v("TowerBand", 44, 50, 1 + i * 3, 4 + i * 3, m0 + 3, m0 + 9, if i % 2 == 0 then c.Red else c.White)
	end
	v("Gallery", 43, 51, 19, 20, m0 + 2, m0 + 10, c.Ink)
	for _, n in { 45, 48 } do
		for _, m in { m0 + 4, m0 + 7 } do
			v("LanternPost", n, n + 1, 20, 23, m, m + 1, c.Ink)
		end
	end
	v("Beacon", 46, 48, 20, 23, m0 + 5, m0 + 7, c.Lamp, NEON)
	v("LanternRoof", 45, 49, 23, 24, m0 + 4, m0 + 8, c.Red)
	v("LanternRoof", 46, 48, 24, 25, m0 + 5, m0 + 7, c.Red)
	v("Vane", 46, 48, 25, 26, m0 + 5, m0 + 7, c.Ink)
end

local function harborCrane(kit: any, city: Instance, side: number, m0: number, accent: Color3)
	local c = kit.colors
	local v = lawnWriter(kit, city, "HarborCrane", side)
	for _, n in { 43, 50 } do
		for _, m in { m0, m0 + 11 } do
			v("CraneLeg", n, n + 1, 0, 18, m, m + 1, accent)
		end
		v("Girder", n, n + 1, 18, 19, m0 + 1, m0 + 11, accent)
	end
	for _, m in { m0, m0 + 11 } do
		v("CrossBeam", 43, 51, 18, 19, m, m + 1, accent)
	end
	v("Deck", 44, 50, 18, 19, m0 + 1, m0 + 11, c.SteelDark)
	v("MachineHouse", 44, 51, 19, 22, m0 + 2, m0 + 10, c.Ink)
	v("CabWindow", 43, 44, 19, 21, m0 + 4, m0 + 8, c.Glass)
	v("Jib", 30, 52, 22, 24, m0 + 5, m0 + 8, accent)
	v("Counterweight", 49, 52, 24, 26, m0 + 4, m0 + 9, c.Concrete)
	v("Trolley", 31, 34, 21, 22, m0 + 5, m0 + 8, c.Ink)
	v("HoistCable", 32, 33, 12, 21, m0 + 6, m0 + 7, c.Black)
	v("Hook", 32, 33, 11, 12, m0 + 6, m0 + 7, c.HazardDark)
	for i = 0, 7 do
		local color = if i % 2 == 0 then c.Orange else darker(c.Orange, 0.16)
		v("HangingContainer", 30, 33, 8, 11, m0 + 2 + i, m0 + 3 + i, color)
	end
end

-- Container stacks in three lanes; heights vary by hash and some slots stay empty.
local function yard(
	kit: any,
	city: Instance,
	side: number,
	m0: number,
	slots: number,
	seed: number,
	palette: { Color3 }
)
	for s = 0, slots - 1 do
		local m = m0 + 9 * s
		for lane, n in { 42, 45, 48 } do
			local h = Grid.hash(lane, m, seed)
			local stack = if h < 0.15 then 0 elseif h < 0.55 then 1 elseif h < 0.88 then 2 else 3
			for k = 0, stack - 1 do
				Props.container(kit, city, side, n, m, 3 * k, Props.pick(palette, Grid.hash(lane + k, m, seed + 1)))
			end
		end
	end
end

local function fishStall(kit: any, city: Instance, side: number, m0: number, stripe: Color3)
	local c = kit.colors
	local v = lawnWriter(kit, city, "FishStall", side)
	v("Counter", 41, 44, 0, 2, m0, m0 + 8, c.Wood)
	for i, m in { m0 + 1, m0 + 4 } do
		v("FishCrate", 41, 43, 2, 3, m, m + 3, c.Blue)
		v("Fish", 41, 43, 3, 4, m + 1, m + 2, if i == 1 then c.Steel else c.Orange)
	end
	for _, m in { m0, m0 + 7 } do
		v("StallPost", 44, 45, 0, 5, m, m + 1, c.WoodDark)
	end
	v("StallCanopy", 40, 46, 5, 6, m0 - 1, m0 + 9, stripe)
	v("StallCanopyTop", 42, 45, 6, 7, m0, m0 + 8, c.White)
end

local function cargo(kit: any, city: Instance, side: number, m: number)
	local c = kit.colors
	local v = terraceWriter(kit, city, "CargoPile", side)
	v("Crate", 33, 35, 0, 2, m, m + 2, c.Wood)
	v("Crate", 33, 35, 2, 4, m, m + 2, c.WoodLight)
	v("Crate", 35, 37, 0, 2, m, m + 2, c.WoodDark)
	v("Barrel", 33, 34, 0, 2, m + 3, m + 4, c.Blue)
	v("Barrel", 34, 35, 0, 2, m + 3, m + 4, c.Red)
end

local function lifebuoy(kit: any, city: Instance, side: number, m: number)
	local c = kit.colors
	local v = terraceWriter(kit, city, "Lifebuoy", side)
	v("BuoyPost", 37, 38, 0, 5, m, m + 1, c.Ink)
	for dy = 0, 2 do
		for dm = -1, 1 do
			if dy ~= 1 or dm ~= 0 then
				v("Buoy", 36, 37, 1 + dy, 2 + dy, m + dm, m + dm + 1, if (dy + dm) % 2 == 0 then c.Red else c.White)
			end
		end
	end
end

local function warehouse(kit: any, city: Instance, side: number, m0: number, wall: Color3, seed: number)
	local c = kit.colors
	Props.building(kit, city, side, {
		n0 = 42,
		n1 = 52,
		m0 = m0,
		m1 = m0 + 42,
		floors = 3,
		wall = wall,
		trim = c.White,
		roof = c.SteelDark,
		seed = seed,
		shop = true,
		signColor = c.Navy,
		name = "Warehouse",
	})
end

local function dock(kit: any, city: Instance, theme: any, index: number, field: BasePart)
	local c, accent = kit.colors, theme.accent
	local palette = { c.Blue, c.Orange, accent, c.Red, c.Teal, c.Green }
	boards(kit, city, { c.Navy, accent })
	task.wait()
	for _, side in { -1, 1 } do
		local v = terraceWriter(kit, city, "QuayBollards", side)
		for m = 6, kit.rows - 7, 12 do
			v("Bollard", 31, 32, 0, 1, m, m + 1, c.Black)
			v("BollardCap", 31, 32, 1, 2, m, m + 1, c.HazardDark)
		end
		for _, m in { 60, 140, 220 } do
			lifebuoy(kit, city, side, m)
		end
		for _, m in { 20, 100, 180, 250 } do
			Props.lampPost(kit, city, side, 37, m, kit.levels.terrace, 6)
		end
	end
	for _, m in { 110, 185 } do
		cargo(kit, city, -1, m)
	end
	for _, m in { 30, 170 } do
		cargo(kit, city, 1, m)
	end
	-- West quay: yards, a warehouse, the fish market and the lighthouse.
	yard(kit, city, -1, 12, 4, 41, palette)
	warehouse(kit, city, -1, 58, c.Blue, 4)
	task.wait()
	yard(kit, city, -1, 108, 4, 42, palette)
	for i, m in { 160, 174, 188 } do
		fishStall(kit, city, -1, m, if i % 2 == 0 then c.Blue else c.Red)
	end
	yard(kit, city, -1, 205, 3, 43, palette)
	lighthouse(kit, city, field, index, theme, 243)
	task.wait()
	-- East quay: yards, a harbour crane and a second warehouse.
	yard(kit, city, 1, 12, 4, 44, palette)
	harborCrane(kit, city, 1, 60, accent)
	yard(kit, city, 1, 82, 4, 45, palette)
	yard(kit, city, 1, 150, 4, 46, palette)
	warehouse(kit, city, 1, 196, c.Teal, 5)
	yard(kit, city, 1, 242, 2, 47, palette)
end

-- 05 Factory Arena ----------------------------------------------------------------------

-- A banded brick chimney from row `base` to `top` with smoke puffs drifting inward.
local function chimney(v: any, c: any, n0: number, m0: number, base: number, top: number)
	local h = base
	for i, band in { 5, 1, 5, 1 } do
		local stripe = i % 2 == 0
		v(
			if stripe then "ChimneyBand" else "Chimney",
			n0,
			n0 + 5,
			h,
			h + band,
			m0,
			m0 + 5,
			if stripe then c.Hazard else c.Brick
		)
		h += band
	end
	v("Chimney", n0, n0 + 5, h, top - 1, m0, m0 + 5, c.Brick)
	v("ChimneyRim", n0 - 1, n0 + 6, top - 1, top, m0 - 1, m0 + 6, c.BrickDark)
	v("Smoke", n0 + 1, n0 + 4, top + 1, top + 3, m0 + 1, m0 + 4, c.Smoke)
	v("Smoke", n0 - 1, n0 + 3, top + 3, top + 5, m0 + 2, m0 + 5, c.Smoke)
	v("Smoke", n0 - 2, n0 + 1, top + 6, top + 7, m0 + 3, m0 + 5, c.Smoke)
end

local function stacks(kit: any, city: Instance, field: BasePart, index: number, theme: any, m0: number)
	local c = kit.colors
	local v = Props.writer(kit, Props.landmark(kit, city, field, index), -1, kit.levels.lawn)
	local sign = v("Sign", 41, 52, 2, 5, m0, m0 + 1, theme.accent)
	kit.text(sign, title(theme), N.Back, c.Ink)
	v("BoilerHouse", 41, 52, 0, 6, m0 + 1, m0 + 20, c.BrickDark)
	chimney(v, c, 42, m0 + 4, 6, 26)
	chimney(v, c, 46, m0 + 13, 6, 31)
end

local function hall(
	kit: any,
	city: Instance,
	side: number,
	m0: number,
	m1: number,
	wall: Color3,
	roof: Color3,
	shop: boolean?
)
	local c = kit.colors
	local model, rows = Props.building(kit, city, side, {
		n0 = 42,
		n1 = 52,
		m0 = m0,
		m1 = m1,
		floors = 2,
		wall = wall,
		trim = c.BrickDark,
		roof = roof,
		seed = m0,
		shop = shop == true,
		signColor = c.Ink,
		roofless = true,
		name = "FactoryHall",
	})
	local v = Props.writer(kit, model, side, kit.levels.lawn)
	v("RoofSlab", 42, 52, rows, rows + 1, m0, m1, c.Concrete)
	-- Sawtooth roof: each tooth steps up to a glazed north light.
	for m = m0, m1 - 5, 5 do
		v("SawRoof", 42, 52, rows + 1, rows + 2, m, m + 4, roof)
		v("SawRoof", 42, 52, rows + 2, rows + 3, m + 2, m + 4, roof)
		v("SawRoof", 42, 52, rows + 3, rows + 4, m + 3, m + 4, roof)
		v("NorthLight", 42, 52, rows + 1, rows + 4, m + 4, m + 5, c.Glass)
	end
end

local function tank(kit: any, city: Instance, side: number, t: number, accent: Color3)
	local c = kit.colors
	local v = lawnWriter(kit, city, "StorageTank", side)
	local segments: { { any } } = { { 0, 3, c.Steel }, { 3, 4, accent }, { 4, 8, c.Steel } }
	for _, seg in segments do
		v("TankBody", 42, 48, seg[1], seg[2], t + 1, t + 5, seg[3])
		v("TankBody", 43, 47, seg[1], seg[2], t, t + 1, seg[3])
		v("TankBody", 43, 47, seg[1], seg[2], t + 5, t + 6, seg[3])
	end
	v("TankCap", 43, 47, 8, 9, t + 1, t + 5, c.SteelDark)
end

local function silo(kit: any, city: Instance, side: number, n0: number, m0: number, height: number, color: Color3)
	local c = kit.colors
	local v = lawnWriter(kit, city, "Silo", side)
	local segments: { { any } } = { { 0, 2, c.SteelDark }, { 2, height, color } }
	for _, seg in segments do
		v("SiloBody", n0 + 1, n0 + 5, seg[1], seg[2], m0, m0 + 6, seg[3])
		v("SiloBody", n0, n0 + 1, seg[1], seg[2], m0 + 1, m0 + 5, seg[3])
		v("SiloBody", n0 + 5, n0 + 6, seg[1], seg[2], m0 + 1, m0 + 5, seg[3])
	end
	v("SiloCone", n0 + 1, n0 + 5, height, height + 1, m0 + 1, m0 + 5, c.SteelDark)
	v("SiloCone", n0 + 2, n0 + 4, height + 1, height + 2, m0 + 2, m0 + 4, c.Hazard)
	v("SiloLadder", n0 - 1, n0, 0, height, m0 + 2, m0 + 3, c.Ink)
end

local function conveyor(kit: any, city: Instance, side: number, m0: number, m1: number, seed: number)
	local c = kit.colors
	local v = lawnWriter(kit, city, "Conveyor", side)
	for m = m0, m1 - 1, 8 do
		for _, n in { 41, 43 } do
			v("ConveyorLeg", n, n + 1, 0, 2, m, m + 1, c.SteelDark)
		end
	end
	v("Belt", 41, 44, 2, 3, m0, m1, c.Black)
	for m = m0 + 2, m1 - 3, 6 do
		v("BeltCrate", 41, 44, 3, 5, m, m + 3, if Grid.hash(m, 0, seed) < 0.5 then c.Wood else c.WoodLight)
	end
	v("Machine", 40, 46, 0, 6, m1, m1 + 6, c.Orange)
	v("MachineLight", 41, 42, 6, 7, m1 + 2, m1 + 3, c.Red, NEON)
end

local function forklift(kit: any, city: Instance, side: number, m0: number, accent: Color3)
	local c = kit.colors
	local v = terraceWriter(kit, city, "Forklift", side)
	for _, n in { 31, 33 } do
		for _, m in { m0 + 1, m0 + 3 } do
			v("Wheel", n, n + 1, 0, 1, m, m + 1, c.Black)
			v("CagePost", n, n + 1, 2, 5, m, m + 1, c.Ink)
		end
		v("Mast", n, n + 1, 0, 6, m0 + 5, m0 + 6, c.SteelDark)
		v("Fork", n, n + 1, 0, 1, m0 + 6, m0 + 9, c.SteelDark)
	end
	v("ForkliftBody", 31, 34, 1, 2, m0, m0 + 5, accent)
	v("Seat", 32, 33, 2, 3, m0 + 1, m0 + 2, c.Ink)
	v("CageRoof", 31, 34, 5, 6, m0 + 1, m0 + 4, c.Ink)
	v("Pallet", 31, 34, 1, 2, m0 + 6, m0 + 9, c.WoodDark)
	v("Crate", 31, 34, 2, 4, m0 + 6, m0 + 9, c.Wood)
end

local function pallets(kit: any, city: Instance, side: number, m0: number)
	local c = kit.colors
	local v = terraceWriter(kit, city, "PalletStack", side)
	v("Pallet", 34, 38, 0, 1, m0, m0 + 4, c.WoodDark)
	v("Crate", 34, 36, 1, 3, m0, m0 + 2, c.Wood)
	v("Crate", 36, 38, 1, 2, m0, m0 + 4, c.WoodLight)
	v("Barrel", 34, 35, 1, 3, m0 + 3, m0 + 4, c.Hazard)
	v("Barrel", 35, 36, 1, 3, m0 + 3, m0 + 4, c.Red)
end

local function powerHouse(kit: any, city: Instance, side: number, m0: number, accent: Color3)
	local c = kit.colors
	local model = Props.building(kit, city, side, {
		n0 = 42,
		n1 = 52,
		m0 = m0,
		m1 = m0 + 40,
		floors = 3,
		wall = c.Brick,
		trim = c.BrickDark,
		roof = c.SteelDark,
		seed = m0,
		shop = true,
		signColor = c.Ink,
		roofless = true,
		name = "PowerHouse",
	})
	local v = Props.writer(kit, model, side, kit.levels.lawn)
	v("RoofSlab", 42, 52, 9, 10, m0, m0 + 40, c.Concrete)
	chimney(v, c, 46, m0 + 26, 10, 30)
	v("Transformer", 44, 49, 10, 13, m0 + 4, m0 + 12, c.SteelDark)
	v("Insulator", 45, 46, 13, 15, m0 + 5, m0 + 6, accent)
	v("Insulator", 47, 48, 13, 15, m0 + 9, m0 + 10, accent)
end

local function factory(kit: any, city: Instance, theme: any, index: number, field: BasePart)
	local c, accent = kit.colors, theme.accent
	boards(kit, city, { c.BrickDark, accent })
	task.wait()
	for _, side in { -1, 1 } do
		local v = terraceWriter(kit, city, "SafetyBollards", side)
		for m = 8, kit.rows - 6, 16 do
			v("Bollard", 30, 31, 0, 1, m, m + 1, c.Hazard)
			v("BollardBand", 30, 31, 1, 2, m, m + 1, c.HazardDark)
			v("Bollard", 30, 31, 2, 3, m, m + 1, c.Hazard)
		end
	end
	forklift(kit, city, -1, 160, accent)
	forklift(kit, city, 1, 70, accent)
	for _, m in { 40, 120, 230 } do
		pallets(kit, city, -1, m)
	end
	for _, m in { 130, 210 } do
		pallets(kit, city, 1, m)
	end
	-- West: halls, tanks, silos and a conveyor up to the boiler house stacks.
	hall(kit, city, -1, 14, 64, c.Brick, c.SteelDark, true)
	tank(kit, city, -1, 70, accent)
	tank(kit, city, -1, 80, c.Red)
	silo(kit, city, -1, 43, 92, 16, c.Steel)
	silo(kit, city, -1, 43, 100, 18, c.Concrete)
	task.wait()
	hall(kit, city, -1, 112, 162, c.BrickLight, c.SteelDark, true)
	conveyor(kit, city, -1, 170, 224, 51)
	stacks(kit, city, field, index, theme, 236)
	task.wait()
	-- East: sawtooth sheds, tanks, the scoreboard and the power house.
	hall(kit, city, 1, 14, 54, c.BrickLight, c.SteelDark)
	tank(kit, city, 1, 60, c.Teal)
	tank(kit, city, 1, 70, accent)
	silo(kit, city, 1, 43, 82, 15, c.Steel)
	Props.scoreboard(kit, city, 1, 110, accent)
	hall(kit, city, 1, 130, 175, c.Brick, c.SteelDark, true)
	powerHouse(kit, city, 1, 190, accent)
end

-- 06 Rooftop Football -------------------------------------------------------------------

local function beacon(kit: any, city: Instance, field: BasePart, index: number, theme: any, m0: number)
	local c = kit.colors
	local v = Props.writer(kit, Props.landmark(kit, city, field, index), 1, kit.levels.lawn)
	v("BeaconBase", 44, 51, 0, 2, m0 + 2, m0 + 9, c.Concrete)
	local sign = v("Sign", 43, 52, 2, 6, m0 + 2, m0 + 3, theme.accent)
	kit.text(sign, title(theme), N.Back, c.Ink)
	for i = 0, 7 do
		v("MastBand", 46, 48, 2 + i * 4, 6 + i * 4, m0 + 5, m0 + 7, if i % 2 == 0 then c.Red else c.White)
	end
	v("Platform", 44, 50, 22, 23, m0 + 3, m0 + 5, c.Ink)
	v("Platform", 44, 50, 22, 23, m0 + 7, m0 + 9, c.Ink)
	v("Platform", 44, 46, 22, 23, m0 + 5, m0 + 7, c.Ink)
	v("Platform", 48, 50, 22, 23, m0 + 5, m0 + 7, c.Ink)
	v("Beacon", 46, 48, 34, 36, m0 + 5, m0 + 7, c.Red, NEON)
end

local function tower(
	kit: any,
	city: Instance,
	side: number,
	m0: number,
	m1: number,
	floors: number,
	wall: Color3,
	seed: number,
	antenna: boolean
)
	local c = kit.colors
	local model, top = Props.building(kit, city, side, {
		n0 = 42,
		n1 = 52,
		m0 = m0,
		m1 = m1,
		floors = floors,
		wall = wall,
		trim = c.Coping,
		roof = c.Concrete,
		seed = seed,
		name = "SkylineTower",
	})
	if antenna then
		local v = Props.writer(kit, model, side, kit.levels.lawn)
		local m = (m0 + m1) // 2
		v("Antenna", 50, 51, top - 1, top + 7, m, m + 1, c.SteelDark)
		v("AntennaLight", 50, 51, top + 7, top + 8, m, m + 1, c.Red, NEON)
	end
end

local function helipad(kit: any, city: Instance, side: number, m0: number, accent: Color3)
	local c = kit.colors
	local v = lawnWriter(kit, city, "Helipad", side)
	v("PadBase", 40, 52, 0, 1, m0, m0 + 12, c.SteelDark)
	v("PadH", 43, 44, 1, 2, m0 + 3, m0 + 9, c.White)
	v("PadH", 48, 49, 1, 2, m0 + 3, m0 + 9, c.White)
	v("PadH", 44, 48, 1, 2, m0 + 5, m0 + 7, c.White)
	for _, n in { 40, 51 } do
		for _, m in { m0, m0 + 11 } do
			v("PadLight", n, n + 1, 1, 2, m, m + 1, accent, NEON)
		end
	end
end

local function solar(kit: any, city: Instance, side: number, m0: number, m1: number)
	local c = kit.colors
	local v = terraceWriter(kit, city, "SolarPanels", side)
	for m = m0, m1 - 3, 4 do
		v("PanelStand", 34, 35, 0, 1, m + 1, m + 2, c.SteelDark)
		v("Panel", 32, 38, 1, 2, m, m + 3, c.Navy)
		v("PanelEdge", 37, 38, 2, 3, m, m + 3, c.Steel)
	end
end

local function rooftop(kit: any, city: Instance, theme: any, index: number, field: BasePart)
	local c, accent = kit.colors, theme.accent
	boards(kit, city, { c.Navy, accent })
	task.wait()
	local glass = { C(70, 92, 134), C(118, 132, 152), C(176, 186, 200), C(92, 78, 128), C(64, 118, 140) }
	-- West: towers, a water tower and a small roof garden.
	tower(kit, city, -1, 14, 40, 10, glass[1], 61, true)
	tower(kit, city, -1, 46, 70, 7, glass[3], 62, false)
	do
		local v = lawnWriter(kit, city, "WaterTower", -1)
		for _, n in { 43, 47 } do
			for _, m in { 104, 108 } do
				v("TowerLeg", n, n + 1, 0, 5, m, m + 1, c.WoodDark)
			end
		end
		v("Tank", 43, 48, 5, 8, 104, 109, c.Wood)
		v("TankBand", 43, 48, 8, 9, 104, 109, c.WoodDark)
		v("Tank", 43, 48, 9, 11, 104, 109, c.Wood)
		v("TankRoof", 44, 47, 11, 12, 105, 108, c.WoodDark)
		v("TankRoof", 45, 46, 12, 13, 106, 107, c.WoodDark)
	end
	tower(kit, city, -1, 115, 145, 12, glass[2], 63, true)
	task.wait()
	Props.bush(kit, city, -1, 42, 150)
	Props.tree(kit, city, -1, 45, 160)
	Props.bush(kit, city, -1, 42, 168)
	tower(kit, city, -1, 175, 205, 8, glass[4], 64, false)
	tower(kit, city, -1, 215, 238, 6, glass[5], 65, true)
	solar(kit, city, -1, 60, 76)
	solar(kit, city, -1, 170, 186)
	task.wait()
	-- East: towers around a helipad and the skyline beacon.
	tower(kit, city, 1, 14, 44, 9, glass[2], 66, false)
	tower(kit, city, 1, 50, 86, 6, glass[4], 67, true)
	helipad(kit, city, 1, 95, accent)
	tower(kit, city, 1, 140, 170, 11, glass[1], 68, true)
	task.wait()
	tower(kit, city, 1, 180, 226, 7, glass[3], 69, false)
	beacon(kit, city, field, index, theme, 238)
	solar(kit, city, 1, 30, 46)
	solar(kit, city, 1, 120, 136)
	for _, side in { -1, 1 } do
		for _, m in { 100, 200 } do
			local v = terraceWriter(kit, city, "AirConditioner", side)
			v("Unit", 33, 37, 0, 2, m, m + 4, c.Concrete)
			v("Fan", 34, 36, 2, 3, m + 1, m + 3, c.Black)
		end
	end
end

-- 07 Pro Academy ------------------------------------------------------------------------

local function academyTower(kit: any, city: Instance, field: BasePart, index: number, theme: any, m0: number)
	local c, accent = kit.colors, theme.accent
	local v = Props.writer(kit, Props.landmark(kit, city, field, index), -1, kit.levels.terrace)
	v("Plinth", 30, 38, 0, 1, m0 - 1, m0 + 9, c.Concrete)
	local h = 1
	for i, band in { 4, 1, 4, 1, 5 } do
		local stripe = i % 2 == 0
		v(
			if stripe then "ClubStripe" else "AcademyBody",
			31,
			37,
			h,
			h + band,
			m0 + 1,
			m0 + 8,
			if stripe then accent else c.White
		)
		h += band
	end
	v("AcademyRoof", 30, 38, h, h + 1, m0, m0 + 9, c.Navy)
	v("Crest", 32, 35, h + 1, h + 4, m0 + 3, m0 + 6, accent)
	v("CrestStar", 33, 34, h + 4, h + 5, m0 + 4, m0 + 5, c.Gold)
	local sign = v("Sign", 30, 38, 8, 12, m0, m0 + 1, accent)
	kit.text(sign, title(theme), N.Back, c.White)
end

local function flags(kit: any, city: Instance, side: number, m0: number, colors: { Color3 })
	local c = kit.colors
	for i, color in colors do
		local m = m0 + (i - 1) * 5
		local v = lawnWriter(kit, city, "AcademyFlag", side)
		v("FlagBase", 49, 51, 0, 1, m, m + 2, c.Concrete)
		v("FlagPole", 50, 51, 1, 13, m, m + 1, c.Steel)
		v("Flag", 46, 50, 9, 12, m, m + 1, color)
		v("FlagStripe", 46, 50, 12, 13, m, m + 1, c.White)
	end
end

local function trainingHall(
	kit: any,
	city: Instance,
	side: number,
	m0: number,
	m1: number,
	floors: number,
	wall: Color3,
	trim: Color3,
	roof: Color3,
	seed: number
)
	Props.building(kit, city, side, {
		n0 = 42,
		n1 = 52,
		m0 = m0,
		m1 = m1,
		floors = floors,
		wall = wall,
		trim = trim,
		roof = roof,
		seed = seed,
		shop = true,
		signColor = trim,
		name = "TrainingHall",
	})
end

local function academy(kit: any, city: Instance, theme: any, index: number, field: BasePart)
	local c, accent = kit.colors, theme.accent
	local juniors = { accent, c.White, c.Navy, accent, c.Yellow }
	boards(kit, city, { accent, c.White })
	task.wait()
	-- West terrace: mannequin walls; lawn: halls, trees, scoreboard and flags.
	for _, m in { 40, 80, 120, 160, 200 } do
		local v = terraceWriter(kit, city, "TrainingEquipment", -1)
		for _, n in { 31, 33, 35, 37 } do
			v("Mannequin", n, n + 1, 0, 3, m, m + 1, accent)
			v("MannequinHead", n, n + 1, 3, 4, m, m + 1, c.White)
		end
	end
	academyTower(kit, city, field, index, theme, 250)
	trainingHall(kit, city, -1, 16, 60, 3, c.White, accent, accent, 71)
	Props.tree(kit, city, -1, 45, 70)
	Props.pine(kit, city, -1, 45, 82)
	Props.tree(kit, city, -1, 45, 94, "blossom")
	Props.poplar(kit, city, -1, 44, 106)
	Props.scoreboard(kit, city, -1, 115, accent)
	flags(kit, city, -1, 132, { accent, c.Navy, accent })
	task.wait()
	trainingHall(kit, city, -1, 158, 202, 4, c.Cream, c.Navy, accent, 72)
	Props.tree(kit, city, -1, 45, 212)
	Props.pine(kit, city, -1, 45, 224)
	Props.tree(kit, city, -1, 45, 236, "autumn")
	Props.flowerbed(kit, city, -1, 40, 244, 8, 8)
	task.wait()
	-- East terrace: hurdles, slalom, a covered stand; lawn: halls and drills.
	for m = 30, 80, 10 do
		local v = terraceWriter(kit, city, "TrainingEquipment", 1)
		for _, n in { 30, 36 } do
			v("HurdlePost", n, n + 1, 0, 2, m, m + 1, c.White)
		end
		v("HurdleBar", 30, 37, 2, 3, m, m + 1, accent)
	end
	do
		local v = terraceWriter(kit, city, "TrainingEquipment", 1)
		for i, m in { 150, 155, 160, 165, 170, 175, 180, 185 } do
			local n = if i % 2 == 0 then 35 else 32
			v("SlalomPole", n, n + 1, 0, 3, m, m + 1, if i % 2 == 0 then c.Orange else c.Yellow)
		end
	end
	terraceStand(kit, city, 1, 100, 125, { accent, c.White }, juniors, 73, c.Navy)
	ballCart(kit, city, 1, 215, accent)
	trainingHall(kit, city, 1, 16, 56, 3, c.White, c.Navy, accent, 74)
	do
		local v = lawnWriter(kit, city, "AgilityLadder", 1)
		for _, n in { 42, 47 } do
			v("LadderRail", n, n + 1, 0, 1, 66, 90, c.Yellow)
		end
		for m = 67, 89, 2 do
			v("LadderRung", 43, 47, 0, 1, m, m + 1, c.Yellow)
		end
	end
	Props.tree(kit, city, 1, 45, 104)
	Props.pine(kit, city, 1, 45, 118)
	Props.tree(kit, city, 1, 45, 132, "blossom")
	trainingHall(kit, city, 1, 150, 196, 2, c.White, accent, c.Navy, 75)
	Props.bigTree(kit, city, 1, 44, 210)
	Props.tree(kit, city, 1, 45, 236)
	Props.flowerbed(kit, city, 1, 40, 244, 8, 9)
end

-- 08 City Stadium -----------------------------------------------------------------------

local function championshipTower(kit: any, city: Instance, field: BasePart, index: number, theme: any, m0: number)
	local c, accent = kit.colors, theme.accent
	local v = Props.writer(kit, Props.landmark(kit, city, field, index), -1, kit.levels.terrace)
	v("Plinth", 30, 38, 0, 1, m0 - 1, m0 + 9, c.Ink)
	local h = 1
	for i, band in { 4, 1, 4, 1, 4, 1, 3 } do
		local gold = i % 2 == 0
		v(
			if gold then "GoldBand" else "TowerBody",
			31,
			37,
			h,
			h + band,
			m0 + 1,
			m0 + 7,
			if gold then accent else c.Navy
		)
		h += band
	end
	v("CrownBase", 30, 38, h, h + 1, m0, m0 + 8, accent)
	for _, n in { 30, 37 } do
		for _, m in { m0, m0 + 7 } do
			v("CrownSpike", n, n + 1, h + 1, h + 3, m, m + 1, c.Gold)
		end
	end
	v("CrownGem", 33, 35, h + 1, h + 2, m0 + 3, m0 + 5, c.Red)
	local sign = v("Sign", 30, 38, 9, 13, m0, m0 + 1, accent)
	kit.text(sign, title(theme), N.Back, c.Navy)
end

local function bigScreen(kit: any, city: Instance, side: number, m0: number, m1: number, accent: Color3)
	local c = kit.colors
	local v = lawnWriter(kit, city, "BigScreen", side)
	for _, m in { m0 + 2, m1 - 3 } do
		v("ScreenLeg", 50, 51, 0, 10, m, m + 1, c.Ink)
	end
	local screen = v("Screen", 49, 50, 10, 20, m0, m1, c.Black)
	kit.text(screen, "0 : 0", Props.inward(side), accent)
	v("ScreenFrame", 49, 51, 20, 21, m0, m1, accent)
	v("ScreenFrame", 50, 51, 10, 20, m0, m1, c.Ink)
end

local function pyro(kit: any, city: Instance, side: number, m: number)
	local c = kit.colors
	local v = terraceWriter(kit, city, "Pyro", side)
	v("PyroBox", 33, 36, 0, 2, m, m + 3, c.Black)
	v("Flame", 34, 35, 2, 4, m + 1, m + 2, c.Orange, NEON)
	v("Flame", 34, 35, 4, 5, m + 1, m + 2, c.Yellow, NEON)
end

local function stadium(kit: any, city: Instance, theme: any, index: number, field: BasePart)
	local c, accent = kit.colors, theme.accent
	local pattern = theme.pavingPattern
	local team = { [-1] = pattern.west, [1] = pattern.east }
	boards(kit, city, { accent, c.Navy })
	task.wait()
	for _, side in { -1, 1 } do
		local colors = { team[side], darker(team[side], 0.25) }
		local fans = { team[side], team[side], c.White, darker(team[side], 0.25) }
		lawnStand(kit, city, side, 22, 118, colors, fans, 0.3, 80 + side)
		task.wait()
		lawnStand(kit, city, side, 152, 248, colors, fans, 0.3, 90 + side)
		task.wait()
		local v = terraceWriter(kit, city, "ChampionshipTrophy", side)
		v("Plinth", 30, 38, 0, 2, 131, 139, c.Ink)
		v("PlinthTrim", 30, 38, 2, 3, 131, 139, accent)
		Props.trophy(v, 31, 132, 3, c.Gold, c.GoldDark)
		for _, m in { 188, 206 } do
			pyro(kit, city, side, m)
		end
	end
	bigScreen(kit, city, -1, 122, 148, accent)
	Props.scoreboard(kit, city, 1, 121, accent)
	Props.floodlight(kit, city, 1, 143, accent, 22)
	championshipTower(kit, city, field, index, theme, 250)
end

-- Looks ---------------------------------------------------------------------------------

local function natural(colors: any, flowers: { string }, density: number?): any
	return {
		terrace = "checker",
		lawn = "grass",
		pitchWall = "masonry",
		stepWall = "soil",
		outerWall = "soil",
		flowers = flowers,
		flowerDensity = density,
		colors = colors,
	}
end

local function clubForecourt(look: any, theme: any, rows: { number }): any
	local pattern = theme.pavingPattern
	if pattern then
		look.club = { light = pattern.light, west = pattern.west, east = pattern.east }
		look.forecourt = rows
	end
	return look
end

-- Location name -> { ground = (theme, colours) -> look, props = builder }.
Locations["Football Field"] = {
	ground = function(_theme: any, c: any): any
		return natural(
			{ TerraceA = c.Path, TerraceB = c.PathDark, TerraceRim = c.Rim },
			{ "FlowerYellow", "FlowerWhite" }
		)
	end,
	props = footballField,
}

Locations["Park Football"] = {
	ground = function(theme: any, c: any): any
		return natural(
			{ TerraceA = theme.paving, TerraceB = darker(theme.paving, 0.12), TerraceRim = c.WoodDark },
			{ "FlowerYellow", "FlowerWhite", "FlowerPink", "FlowerRed" },
			0.03
		)
	end,
	props = park,
}

Locations["Street Football"] = {
	ground = function(_theme: any, c: any): any
		return {
			terrace = "road",
			lawn = "plaza",
			pitchWall = "concrete",
			stepWall = "concrete",
			outerWall = "brick",
			colors = {
				TerraceA = c.Asphalt,
				TerraceB = c.AsphaltDark,
				TerraceRim = c.CurbLight,
				Curb = c.CurbLight,
				PlazaA = C(184, 190, 198),
				PlazaB = C(166, 173, 182),
			},
		}
	end,
	props = street,
}

Locations["Dockyard Pitch"] = {
	ground = function(theme: any, _c: any): any
		return {
			terrace = "slabs",
			rim = "hazard",
			lawn = "planks",
			pitchWall = "masonry",
			stepWall = "masonry",
			outerWall = "timber",
			colors = { TerraceA = theme.paving, TerraceB = darker(theme.paving, 0.1) },
		}
	end,
	props = dock,
}

Locations["Factory Arena"] = {
	ground = function(theme: any, c: any): any
		return {
			terrace = "slabs",
			rim = "hazard",
			lawn = "gravel",
			pitchWall = "concrete",
			stepWall = "brick",
			outerWall = "brick",
			colors = { TerraceA = theme.paving, TerraceB = darker(theme.paving, 0.1), Curb = c.HazardDark },
		}
	end,
	props = factory,
}

Locations["Rooftop Football"] = {
	ground = function(theme: any, c: any): any
		return {
			terrace = "checker",
			lawn = "gravel",
			pitchWall = "concrete",
			stepWall = "concrete",
			outerWall = "facade",
			colors = {
				TerraceA = theme.paving,
				TerraceB = darker(theme.paving, 0.12),
				TerraceRim = c.Coping,
				Curb = c.Coping,
				Facade = C(104, 124, 158),
			},
		}
	end,
	props = rooftop,
}

Locations["Pro Academy"] = {
	ground = function(theme: any, c: any): any
		local look = natural(
			{ TerraceA = theme.paving, TerraceB = darker(theme.paving, 0.1), TerraceRim = c.Rim },
			{ "FlowerWhite", "FlowerBlue" }
		)
		return clubForecourt(look, theme, { 244, 262 })
	end,
	props = academy,
}

Locations["City Stadium"] = {
	ground = function(theme: any, c: any): any
		local look = natural(
			{ TerraceA = theme.paving, TerraceB = darker(theme.paving, 0.1), TerraceRim = c.Rim },
			{ "FlowerWhite", "FlowerYellow" }
		)
		return clubForecourt(look, theme, { 247, 261 })
	end,
	props = stadium,
}

return Locations
