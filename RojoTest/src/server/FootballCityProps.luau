--!strict
-- Native plastic architecture. Every returned Model owns all of its details.
local Props = {}
local Palette = require(script.Parent.LobbyPalette)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local V, C = Vector3.new, Color3.fromRGB
local WHITE, DARK = C(245, 246, 235), C(67, 93, 121)
local SMOOTH = {
	Window = true,
	RoofLight = true,
	LampArray = true,
	Screen = true,
	Advertisement = true,
	Flag = true,
	StreetArt = true,
	TargetInset = true,
	NetCord = true,
	Wire = true,
	HoistCable = true,
	GoldTrim = true,
	ClubStripe = true,
	CargoLogo = true,
}

-- `tile`: Palette.StudsPerTile was measured in the 0.8 scene and follows the world scale.
local function studs(p: BasePart, face: Enum.NormalId, tile: number)
	local t = Instance.new("Texture")
	t.Name, t.Texture, t.Face = "CityStuds", Palette.Studs, face
	t.StudsPerTileU, t.StudsPerTileV = tile, tile
	t.Transparency = Palette.StudsTransparency
	if face == Enum.NormalId.Top then
		t.OffsetStudsU = (p.Position.X - p.Size.X / 2) % tile
		t.OffsetStudsV = (p.Position.Z - p.Size.Z / 2) % tile
	end
	t.Parent = p
end

function Props.context(field: BasePart, k: number): any
	local frame = field.CFrame * CFrame.new(0, field.Size.Y / 2, 0)
	local ctx: any = {}
	ctx.frame, ctx.scale = frame, k
	ctx.length = field.Size.Z / (270 * k)
	local tile = Palette.StudsPerTile * k / Scale.Measured
	function ctx.ground(x: number): number
		return if math.abs(x) < 78 then 3.74 else 8.74
	end
	function ctx.model(parent: Instance, name: string): Model
		local m = Instance.new("Model")
		m.Name, m.Parent = name, parent
		m.WorldPivot = frame
		return m
	end
	function ctx.part(
		parent: Instance,
		name: string,
		pos: Vector3,
		size: Vector3,
		color: Color3,
		rotation: CFrame?
	): Part
		local p = Instance.new("Part")
		p.Name, p.Size = name, size * k
		p.CFrame = frame * CFrame.new(pos * k) * (rotation or CFrame.identity)
		p.Color, p.Material = color, Enum.Material.Plastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CastShadow = size.Y > 2 and size.X > 1 and size.Z > 1
		if not SMOOTH[name] and math.min(size.X, size.Y, size.Z) >= 0.7 then
			for _, face in Enum.NormalId:GetEnumItems() do
				studs(p, face, tile)
			end
		elseif name == "CheckerTile" or name == "PavingBase" then
			studs(p, Enum.NormalId.Top, tile)
		end
		p.Parent = parent
		return p
	end
	function ctx.beam(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, color: Color3): Part
		local p = ctx.part(parent, name, (a + b) / 2, V(width, width, (b - a).Magnitude), color)
		p.CFrame = frame * CFrame.lookAt((a + b) / 2 * k, b * k)
		return p
	end
	function ctx.text(p: BasePart, text: string, face: Enum.NormalId?, color: Color3?)
		local gui = Instance.new("SurfaceGui")
		gui.Name, gui.Face = "Sign_" .. (face or Enum.NormalId.Front).Name, face or Enum.NormalId.Front
		gui.SizingMode, gui.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(800, 240)
		gui.LightInfluence, gui.MaxDistance = 0, 450
		gui.Parent = p
		local label = Instance.new("TextLabel")
		label.Name, label.Size = "Caption", UDim2.fromScale(0.94, 0.86)
		label.Position, label.BackgroundTransparency = UDim2.fromScale(0.03, 0.07), 1
		label.Font, label.TextScaled, label.TextColor3, label.Text = Enum.Font.FredokaOne, true, color or WHITE, text
		label.Parent = gui
	end
	return ctx
end

function Props.paving(
	ctx: any,
	parent: Instance,
	x: number,
	width: number,
	length: number,
	y: number,
	color: Color3,
	checker: Color3?,
	patternLength: number?,
	checkerAlt: Color3?
)
	local m = ctx.model(parent, "Promenade")
	m:SetAttribute("CitySurface", true)
	ctx.part(m, "PavingBase", V(x, y, 0), V(width, 0.18, length), color)
	if checker then
		-- A compact club forecourt, independent of the length of the sideline path.
		local span = math.min(patternLength or length, length)
		local cell = 10
		for ix = 0, math.ceil(width / cell) - 1 do
			for iz = 0, math.ceil(span / cell) - 1 do
				local sx, sz = math.min(cell, width - ix * cell), math.min(cell, span - iz * cell)
				ctx.part(
					m,
					"CheckerTile",
					V(x - width / 2 + ix * cell + sx / 2, y + 0.15, -span / 2 + iz * cell + sz / 2),
					V(sx, 0.12, sz),
					if (ix + iz) % 2 == 0 then checker else checkerAlt or color
				)
			end
		end
	end
end

function Props.tree(ctx: any, parent: Instance, x: number, z: number, scale: number)
	local m = ctx.model(parent, "ParkTree")
	ctx.part(m, "Planter", V(x, 9.24, z), V(18 * scale, 1, 18 * scale), Palette.Grass)
	ctx.part(m, "Trunk", V(x, 8.74 + 9 * scale, z), V(3, 18, 3) * scale, Palette.Wood)
	for i, offset in { V(0, 25, 0), V(-5, 21, 1), V(5, 22, -2), V(1, 20, 5) } do
		local p = ctx.part(
			m,
			"Canopy",
			V(x, 8.5, z) + offset * scale,
			V(15, 13, 15) * scale,
			if i % 2 == 0 then Palette.Leaf else Palette.LeafLight,
			CFrame.Angles(0, i * 0.4, 0)
		)
		p.Material = Enum.Material.SmoothPlastic
	end
end

function Props.bench(ctx: any, parent: Instance, x: number, z: number, color: Color3)
	local m = ctx.model(parent, "TeamBench")
	local base = ctx.ground(x)
	for _, dz in { -6, 6 } do
		ctx.part(m, "Leg", V(x, base + 1.7, z + dz), V(4, 3.4, 0.8), DARK)
	end
	ctx.part(m, "Seat", V(x, base + 3.7, z), V(5, 0.6, 17), color)
	ctx.part(m, "Backrest", V(x + (if x > 0 then 2.2 else -2.2), base + 5.7, z), V(0.6, 3.4, 17), color)
end

function Props.lamp(ctx: any, parent: Instance, x: number, z: number, height: number, large: boolean?)
	local m = ctx.model(parent, "Floodlight")
	local base = ctx.ground(x)
	ctx.part(m, "Footing", V(x, base + 0.5, z), V(5, 1, 5), Palette.StoneLight)
	ctx.part(m, "Mast", V(x, base + height / 2, z), V(1.1, height, 1.1), DARK)
	local head = ctx.part(
		m,
		"Housing",
		V(x, height + base, z),
		V(if large then 3 else 2, if large then 6 else 3, if large then 15 else 7),
		DARK
	)
	local light = ctx.part(
		m,
		"LampArray",
		V(x + (if x > 0 then -1.8 else 1.8), height + base, z),
		V(0.3, if large then 4.8 else 2, if large then 13 else 5.5),
		WHITE
	)
	light.Material, head.CastShadow = Enum.Material.Neon, false
end

function Props.fence(ctx: any, parent: Instance, x: number, length: number, height: number, color: Color3)
	length *= ctx.length
	local m = ctx.model(parent, "BallFence")
	for z = -length / 2, length / 2, 18 do
		ctx.part(m, "Post", V(x, 3.74 + height / 2, z), V(0.65, height, 0.65), color)
	end
	for y = 4.74, 3.74 + height, 3 do
		ctx.part(m, "Wire", V(x, y, 0), V(0.14, 0.14, length), color)
	end
	for z = -length / 2, length / 2, 3 do
		-- A strand completely inside a post only duplicates its exposed end cap.
		if math.abs((z + length / 2) % 18) > 0.01 then
			ctx.part(m, "Wire", V(x + math.sign(x) * 0.14, 3.74 + height / 2, z), V(0.14, height, 0.14), color)
		end
	end
end

function Props.goal(ctx: any, parent: Instance, z: number, color: Color3)
	local m = ctx.model(parent, "FootballGoal")
	local dir = if z < 0 then -1 else 1
	for _, x in { -15, 15 } do
		ctx.part(m, "Post", V(x, 6, z), V(0.9, 12, 0.9), color)
		ctx.beam(m, "BackBrace", V(x, 12, z), V(x, 0.7, z + dir * 6), 0.4, WHITE)
	end
	ctx.part(m, "Crossbar", V(0, 11.55, z), V(29.1, 0.9, 0.9), color)
	for x = -15, 15, 3 do
		ctx.part(m, "NetCord", V(x, 5.6, z + dir * 5.8), V(0.1, 10.6, 0.1), WHITE)
	end
	for y = 0.6, 11, 2 do
		ctx.part(m, "NetCord", V(0, y, z + dir * 5.9), V(30, 0.1, 0.1), WHITE)
	end
end

function Props.stand(
	ctx: any,
	parent: Instance,
	side: number,
	z: number,
	length: number,
	rows: number,
	color: Color3,
	roof: boolean?,
	tierBase: number?,
	inset: number?
)
	local m = ctx.model(parent, "Grandstand")
	local base, offset = tierBase or 0, inset or 0
	for row = 1, rows do
		local x, y = side * (62 + offset + row * 4.8), 4 + row * 2.7 + base
		ctx.part(m, "Terrace", V(x, y / 2, z), V(4.8, y, length), Palette.PathCurb)
		for seat = -length / 2 + 3, length / 2 - 3, 5 do
			if math.abs(seat) > 4 then
				ctx.part(
					m,
					"Seat",
					V(x, y + 0.7, z + seat),
					V(3.1, 0.7, 3.6),
					if math.floor(seat / 5) % 4 == 0 then WHITE else color
				)
				ctx.part(m, "SeatBack", V(x + side * 1.3, y + 1.8, z + seat), V(0.5, 1.5, 3.6), color)
			end
		end
	end
	if roof then
		local outer = side * (64 + offset + rows * 4.8)
		local high = 17 + rows * 2.7 + base
		for _, dz in { -length / 2 + 2, length / 2 - 2 } do
			ctx.part(m, "CanopyColumn", V(outer, high / 2, z + dz), V(1, high, 1), DARK)
		end
		ctx.part(m, "Canopy", V(side * (63 + offset + rows * 2.4), high, z), V(rows * 4.8 + 10, 1.1, length + 4), WHITE)
		ctx.part(m, "Fascia", V(side * (57.5 + offset), high - 1, z), V(1, 3, length + 4), color)
	end
end

function Props.building(
	ctx: any,
	parent: Instance,
	x: number,
	z: number,
	width: number,
	depth: number,
	height: number,
	color: Color3,
	glass: Color3
)
	local m = ctx.model(parent, "CityBuilding")
	ctx.part(m, "BuildingBody", V(x, 8.5 + height / 2, z), V(width, height, depth), color)
	ctx.part(m, "RoofCoping", V(x, 9 + height, z), V(width + 1.2, 1, depth + 1.2), WHITE)
	for y = 14, height + 3, 8 do
		for _, side in { -1, 1 } do
			for dz = -depth / 2 + 4, depth / 2 - 3, 7 do
				ctx.part(m, "Window", V(x + side * (width / 2 + 0.24), y, z + dz), V(0.2, 4.5, 3.8), glass)
			end
			for dx = -width / 2 + 4, width / 2 - 3, 7 do
				ctx.part(m, "Window", V(x + dx, y, z + side * (depth / 2 + 0.24)), V(3.8, 4.5, 0.2), glass)
			end
		end
	end
	local face = x - math.sign(x) * (width / 2 + 0.24)
	for _, dz in { -depth / 2 + 2, depth / 2 - 2 } do
		ctx.part(m, "CornerPier", V(face, 8.5 + height / 2, z + dz), V(0.5, height, 1), color:Lerp(WHITE, 0.25))
	end
	return m
end

function Props.container(ctx: any, parent: Instance, x: number, z: number, y: number, color: Color3)
	local m = ctx.model(parent, "ShippingContainer")
	ctx.part(m, "Body", V(x, y + 6, z), V(18, 12, 34), color)
	for dz = -16, 16, 3.2 do
		for _, dx in { -9.2, 9.2 } do
			ctx.part(m, "Corrugation", V(x + dx, y + 6, z + dz), V(0.4, 11, 0.5), color:Lerp(WHITE, 0.16))
		end
	end
	for _, dx in { -8.6, 0, 8.6 } do
		ctx.part(m, "DoorRail", V(x + dx, y + 6, z + 17.2), V(0.4, 11.6, 0.4), WHITE)
	end
	ctx.text(ctx.part(m, "CargoLogo", V(x, y + 7, z + 17.45), V(12, 4, 0.15), DARK), "CITY FC", Enum.NormalId.Back)
end

function Props.scoreboard(ctx: any, parent: Instance, x: number, z: number, title: string, accent: Color3)
	local m = ctx.model(parent, "Scoreboard")
	for _, dz in { -12, 12 } do
		ctx.part(m, "Support", V(x, 21.24, z + dz), V(1.5, 25, 1.5), DARK)
	end
	local board = ctx.part(m, "Screen", V(x, 33.24, z), V(2, 16, 34), DARK)
	ctx.text(board, title .. "\nHOME  0 : 0  AWAY", Enum.NormalId.Left)
	ctx.text(board, title .. "\nHOME  0 : 0  AWAY", Enum.NormalId.Right)
	ctx.part(m, "Header", V(x, 42.24, z), V(2.3, 2, 35), accent)
end

function Props.trophy(ctx: any, parent: Instance, x: number, z: number, base: number)
	local m = ctx.model(parent, "ChampionshipTrophy")
	local gold = C(255, 199, 52)
	ctx.part(m, "Plinth", V(x, base + 1.5, z), V(9, 3, 9), DARK)
	ctx.part(m, "Stem", V(x, base + 6, z), V(2.5, 6, 2.5), gold)
	ctx.part(m, "Cup", V(x, base + 10, z), V(8, 5, 7), gold)
	ctx.part(m, "Rim", V(x, base + 13, z), V(9.5, 1, 8.5), C(255, 224, 116))
	for _, s in { -1, 1 } do
		ctx.part(m, "Handle", V(x + s * 6, base + 10, z), V(1, 4, 1), gold)
		ctx.part(m, "HandleTop", V(x + s * 4.5, base + 12.5, z), V(4, 1, 1), gold)
		ctx.part(m, "HandleBase", V(x + s * 4.5, base + 7.5, z), V(4, 1, 1), gold)
	end
end

-- Spread finished props as rigid objects. Continuous paths/fences use the
-- longer footprint directly; the props keep their authored proportions.
function Props.spread(ctx: any, root: Model)
	for _, node in root:GetChildren() do
		if node:IsA("Model") then
			if
				node.Name == "Promenade"
				or node.Name == "BallFence"
				or node.Name == "ServicePipe"
				or node.Name == "RooftopParapet"
			then
				continue
			end
			local cf = node:GetBoundingBox()
			local z = ctx.frame:PointToObjectSpace(cf.Position).Z
			node:PivotTo(node:GetPivot() + ctx.frame.ZVector * z * (ctx.length - 1))
		elseif node:IsA("BasePart") then
			local z = ctx.frame:PointToObjectSpace(node.Position).Z
			node.CFrame += ctx.frame.ZVector * z * (ctx.length - 1)
		end
	end
end

-- Cut checker cells around real footings rather than leaving intersecting
-- vertical tile edges inside buildings, terraces or furniture foundations.
function Props.finish(ctx: any, root: Model)
	local solids, tiles = {}, {}
	local function bounds(p: BasePart): (Vector3, Vector3)
		local cf, h = ctx.frame:ToObjectSpace(p.CFrame), p.Size / (2 * ctx.scale)
		local e = V(
			math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z,
			math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z,
			math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
		)
		local p0 = cf.Position / ctx.scale
		return p0 - e, p0 + e
	end
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name == "CheckerTile" then
				table.insert(tiles, p)
			elseif p.Parent and not p.Parent:GetAttribute("CitySurface") then
				local lo, hi = bounds(p)
				if lo.Y < 9 and hi.Y > 3.8 then
					table.insert(solids, { lo = lo, hi = hi })
				end
			end
		end
	end
	local cut = 0
	for _, tile in tiles do
		local low, high = bounds(tile)
		local rects = { { low.X, low.Z, high.X, high.Z } }
		for _, solid in solids do
			if solid.lo.Y <= high.Y and solid.hi.Y > high.Y + 0.15 then
				local nextRects = {}
				for _, r in rects do
					local x0, z0 = math.max(r[1], solid.lo.X), math.max(r[2], solid.lo.Z)
					local x1, z1 = math.min(r[3], solid.hi.X), math.min(r[4], solid.hi.Z)
					if x1 - x0 > 0.001 and z1 - z0 > 0.001 then
						for _, remain in
							{
								{ r[1], r[2], x0, r[4] },
								{ x1, r[2], r[3], r[4] },
								{ x0, r[2], x1, z0 },
								{ x0, z1, x1, r[4] },
							}
						do
							if remain[3] - remain[1] > 0.05 and remain[4] - remain[2] > 0.05 then
								table.insert(nextRects, remain)
							end
						end
					else
						table.insert(nextRects, r)
					end
				end
				rects = nextRects
			end
		end
		if
			#rects ~= 1
			or rects[1][1] ~= low.X
			or rects[1][2] ~= low.Z
			or rects[1][3] ~= high.X
			or rects[1][4] ~= high.Z
		then
			for _, r in rects do
				ctx.part(
					tile.Parent,
					"CheckerTile",
					V((r[1] + r[3]) / 2, (low.Y + high.Y) / 2, (r[2] + r[4]) / 2),
					V(r[3] - r[1], high.Y - low.Y, r[4] - r[2]),
					tile.Color
				)
			end
			tile:Destroy()
			cut += 1
		end
	end
	root:SetAttribute("TrimmedCheckerCells", cut)
end

return Props
