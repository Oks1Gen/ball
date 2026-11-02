--!strict
-- Exact rectangle clipping: a partially covered face still keeps its exposed corners.
local Palette = require(script.Parent.LobbyPalette)
local Coverage = {}
type Rect = { number }
local V = Vector3.new
local earthNames = { TerraceEarth = true, RearEarthLedge = true }
local solidNames = { TerraceEarth = true, RearEarthLedge = true, GrassShelf = true, RearGrassLedge = true }

local function subtract(r: Rect, o: Rect): { Rect }
	local a, b, c, d = math.max(r[1], o[1]), math.min(r[2], o[2]), math.max(r[3], o[3]), math.min(r[4], o[4])
	if b <= a or d <= c then
		return { r }
	end
	local result = {}
	for _, p in { { r[1], a, r[3], r[4] }, { b, r[2], r[3], r[4] }, { a, b, r[3], c }, { a, b, d, r[4] } } do
		if p[2] - p[1] > 0.01 and p[4] - p[3] > 0.01 then
			table.insert(result, p)
		end
	end
	return result
end

local function studs(part: BasePart, face: Enum.NormalId)
	for _, t in part:GetChildren() do
		if t:IsA("Texture") and t.Face == face and t.Transparency < 1 then
			t.Transparency = Palette.StudsTransparency
			return
		end
	end
	local t = Instance.new("Texture")
	t.Name, t.Texture, t.Face = "CheckerStuds", Palette.Studs, face
	t.StudsPerTileU, t.StudsPerTileV = Palette.StudsPerTile, Palette.StudsPerTile
	t.Transparency = Palette.StudsTransparency
	t.Parent = part
end

function Coverage.apply(world: any): any
	local geometry = world.Lobby.Geometry
	local walls, solids, signature = {}, {}, {}
	for i, p in world.Lobby:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 and solidNames[p.Name] then
			local lo, hi = p.Position - p.Size / 2, p.Position + p.Size / 2
			table.insert(solids, { lo = lo, hi = hi })
			table.insert(signature, p.Name .. tostring(p.Position) .. tostring(p.Size))
			if earthNames[p.Name] then
				table.insert(walls, p)
			end
		end
		if i % 1500 == 0 then
			task.wait()
		end
	end
	table.sort(signature)
	local key = "2|" .. table.concat(signature, "|")
	local current = geometry:FindFirstChild("TerraceWallChecker")
	if current and current:GetAttribute("GeometrySignature") == key then
		return { rebuilt = false, tiles = current:GetAttribute("Tiles"), faces = current:GetAttribute("Faces") }
	end
	-- Replace only the old terrace skins; entrance arch skins retain their authored alignment.
	for _, p in geometry:GetChildren() do
		if p.Name == "TerraceEarthChecker" or p.Name == "RearEarthLedgeChecker" or p == current then
			p:Destroy()
		end
	end
	local root = Instance.new("Folder")
	root.Name, root.Parent = "TerraceWallChecker", geometry
	local tiles, faces = 0, 0
	local claimed: { [string]: { Rect } } = {}
	local cell, depth = Palette.CheckerCell, Palette.WallCheckerDepth
	for _, wall in walls do
		local lo, hi = wall.Position - wall.Size / 2, wall.Position + wall.Size / 2
		local directions = { { axis = "Z", u = "X", sign = -1, face = Enum.NormalId.Front } }
		if wall.Name == "TerraceEarth" then
			table.insert(directions, {
				axis = "X",
				u = "Z",
				sign = if wall.Position.X < 50 then 1 else -1,
				face = if wall.Position.X < 50 then Enum.NormalId.Right else Enum.NormalId.Left,
			})
		end
		for _, f in directions do
			local w = if f.sign > 0 then (hi :: any)[f.axis] else (lo :: any)[f.axis]
			local visible = { { (lo :: any)[f.u], (hi :: any)[f.u], math.max(20, lo.Y), hi.Y } }
			for _, s in solids do
				local near = if f.sign > 0 then (s.lo :: any)[f.axis] else -(s.hi :: any)[f.axis]
				local far = if f.sign > 0 then (s.hi :: any)[f.axis] else -(s.lo :: any)[f.axis]
				if near <= f.sign * w + 0.03 and far > f.sign * w + 0.04 then
					local rest = {}
					for _, r in visible do
						for _, piece in subtract(r, { (s.lo :: any)[f.u], (s.hi :: any)[f.u], s.lo.Y, s.hi.Y }) do
							table.insert(rest, piece)
						end
					end
					visible = rest
				end
			end
			if #visible == 0 then
				continue
			end
			studs(wall, f.face)
			-- Render repairs can make neighbouring source blocks overlap slightly.
			-- Claim their coplanar union once rather than laying two skins over it.
			local planeKey = f.axis .. f.sign .. ":" .. math.round(w * 1000)
			local previous: { Rect } = claimed[planeKey] or {}
			for _, r in ipairs(previous) do
				local rest = {}
				for _, open in visible do
					for _, piece in subtract(open, r) do
						table.insert(rest, piece)
					end
				end
				visible = rest
			end
			for _, r in visible do
				table.insert(previous, r)
			end
			claimed[planeKey] = previous
			if #visible == 0 then
				continue
			end
			faces += 1
			-- World-aligned rows remain continuous even at partially covered corners.
			local batch = Instance.new("Model")
			batch.Name = wall.Name .. "Checker"
			for _, r in visible do
				for column = math.floor(r[1] / cell), math.ceil(r[2] / cell) - 1 do
					for row = math.floor(r[3] / cell), math.ceil(r[4] / cell) - 1 do
						if (column + row) % 2 == 0 then
							continue
						end
						local u0, u1 = math.max(r[1], column * cell), math.min(r[2], (column + 1) * cell)
						local y0, y1 = math.max(r[3], row * cell), math.min(r[4], (row + 1) * cell)
						if u1 - u0 < 0.01 or y1 - y0 < 0.01 then
							continue
						end
						local t = Instance.new("Part")
						t.Name, t.Color, t.Material = "CheckerTile", Palette.EarthDark, Enum.Material.Plastic
						t.Anchored, t.CanCollide, t.CanTouch, t.CanQuery, t.CastShadow =
							true, false, false, false, false
						t.TopSurface, t.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
						local u, y, out = (u0 + u1) / 2, (y0 + y1) / 2, w + f.sign * depth / 2
						t.Size = if f.axis == "X" then V(depth, y1 - y0, u1 - u0) else V(u1 - u0, y1 - y0, depth)
						t.Position = if f.axis == "X" then V(out, y, u) else V(u, y, out)
						studs(t, f.face)
						t.Parent = batch
						tiles += 1
					end
				end
			end
			batch.Parent = root
			task.wait()
		end
	end
	root:SetAttribute("GeometrySignature", key)
	root:SetAttribute("Tiles", tiles)
	root:SetAttribute("Faces", faces)
	return { rebuilt = true, tiles = tiles, faces = faces }
end

return Coverage
