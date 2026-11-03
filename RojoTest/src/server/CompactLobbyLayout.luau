--!strict
-- Compact lobby (v3): dark grey stud paths with square branches, checker lawn and chunky trees.
-- Station placement is an authored Edit migration (tools/CompactLobbyRelayout.luau, then
-- tools/LobbyCenterRelayout.luau, which centred the lobby on the field axis X 55 and moved
-- this layer 12 studs west); this module only draws cosmetic layers where the stations stand.
local Palette = require(script.Parent.LobbyPalette)
local Layout = {}
local V, P, RGB = Vector3.new, Vector2.new, Color3.fromRGB
local STUDS = Palette.Studs
local FILL = Palette.Path
local EDGE = Palette.PathEdge
local CURB = Palette.PathCurb
local LAWN_DARK = RGB(96, 180, 50)
local VERSION = 3
type Region = { name: string, polygon: { Vector2 }, openX: number?, openZ: number? }

local function cross(a: Vector2, b: Vector2): number
	return a.X * b.Y - a.Y * b.X
end

local function rectangle(x0: number, x1: number, z0: number, z1: number): { Vector2 }
	return { P(x0, z0), P(x1, z0), P(x1, z1), P(x0, z1) }
end

local function inside(p: Vector2, polygon: { Vector2 }): boolean
	for i, a in polygon do
		local b = polygon[i % #polygon + 1]
		if cross(b - a, p - a) < -0.0001 then
			return false
		end
	end
	return true
end

local function hideRetiredPaving(map: Instance)
	local old = map:FindFirstChild("GeometryPolish")
	if not old then
		return
	end
	for _, p in old:GetDescendants() do
		if p:IsA("BasePart") then
			if p:GetAttribute("BeforeCompactLobbyTransparency") == nil then
				p:SetAttribute("BeforeCompactLobbyTransparency", p.Transparency)
			end
			p.Transparency = 1
		elseif p:IsA("Decal") then
			p.Transparency = 1
		end
	end
end

-- Path colours are repainted on every start, so a palette change reaches an already drawn layer.
local function paint(root: Instance)
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name == "PavingSurface" then
				p.Color = FILL
			elseif p.Name == "InsetBorder" then
				p.Color = EDGE
			elseif p.Name == "PathCurb" then
				p.Color = CURB
			end
		end
	end
end

-- Alternate 16-stud lawn tiles; the render copies of separated tiles follow their originals.
local function checkerLawn(map: Instance)
	local lobby = map:FindFirstChild("Lobby")
	if not lobby then
		return
	end
	local renders: { [Instance]: { BasePart } } = {}
	local separation = map:FindFirstChild("SurfaceSeparation")
	if separation then
		for _, render in separation:GetChildren() do
			local link = render:FindFirstChild("OriginalPart")
			if render:IsA("BasePart") and link and link:IsA("ObjectValue") and link.Value then
				renders[link.Value] = renders[link.Value] or {}
				table.insert(renders[link.Value], render)
			end
		end
	end
	for _, tile in lobby:GetChildren() do
		if not tile:IsA("BasePart") or tile.Name ~= "GroundTile" or tile.Size.X < 15 then
			continue
		end
		local column = math.floor((tile.Position.X + 41) / 16 + 0.5)
		local row = math.floor((tile.Position.Z - 132) / 16 + 0.5)
		if (column + row) % 2 == 0 then
			continue
		end
		if tile:GetAttribute("BeforeCheckerColor") == nil then
			tile:SetAttribute("BeforeCheckerColor", tile.Color)
		end
		tile.Color = LAWN_DARK
		local copies = renders[tile]
		if copies then
			for _, render in copies do
				render.Color = LAWN_DARK
			end
		end
	end
end

function Layout.apply(map: Instance): Instance?
	if map.Name ~= "World1" then
		return nil
	end
	local existing = map:FindFirstChild("CompactLobbyLayout")
	if existing then
		assert(
			(existing:IsA("Folder") or existing:IsA("Model")) and existing:GetAttribute("Version") == VERSION,
			"Inspect partial compact lobby before retry"
		)
		paint(existing)
		hideRetiredPaving(map)
		return existing
	end
	local lobby = assert(map:FindFirstChild("Lobby"))
	local apron = assert(lobby:FindFirstChild("KickZoneFloor")) :: BasePart
	local zone = assert(map:FindFirstChild("TrainingZone"))
	local first = assert(zone:FindFirstChild("TrainingLane1"))
	local strip = assert(first:FindFirstChild("TrainingStrip")) :: BasePart
	assert((strip.Position - V(91, 21.4, 177)).Magnitude < 0.02, "Authored lobby changed: remeasure before applying")
	local top = apron.Position.Y - 0.3 + 0.26
	local root = Instance.new("Folder")
	root.Name = "CompactLobbyLayout"
	root.Parent = map
	-- Rectangles touch but never overlap; shared edges get no curb. The boulevard runs on the
	-- field axis (X 55.5).
	local regions: { Region } = {
		{ name = "Boulevard", polygon = rectangle(46, 65, 150, 279), openZ = 150 },
		{ name = "TrophyPlaza", polygon = rectangle(35, 76, 279, 301) },
		{ name = "HallWalkWest", polygon = rectangle(-21, 35, 293, 301) },
		{ name = "HallWalkEast", polygon = rectangle(76, 132, 293, 301) },
		{ name = "PortalCourt", polygon = rectangle(-18, 18, 150, 194) },
		{ name = "PortalPath", polygon = rectangle(18, 46, 165, 179) },
		{ name = "BallCourt", polygon = rectangle(8.5, 22, 189, 255) },
		{ name = "BallPath", polygon = rectangle(22, 46, 215, 229) },
		{ name = "EggCourt", polygon = rectangle(-18, 46, 255, 279) },
		{ name = "EggCourtBack", polygon = rectangle(-18, 35, 279, 293) },
	}
	for i = 1, 7 do
		local lane = assert(zone:FindFirstChild("TrainingLane" .. i))
		local surface = assert(lane:FindFirstChild("TrainingStrip")) :: BasePart
		local foundation = assert(lane:FindFirstChild("Foundation")) :: BasePart
		local front = foundation.Position.X - foundation.Size.X / 2
		table.insert(regions, {
			name = "TrainingApproach" .. i,
			polygon = rectangle(65, front, surface.Position.Z - 6.5, surface.Position.Z + 6.5),
			openX = front,
		})
	end

	local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
		p.Anchored = true
		p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end
	local function bar(
		parent: Instance,
		name: string,
		a: Vector2,
		b: Vector2,
		width: number,
		height: number,
		y: number,
		color: Color3
	): Part
		local start, finish = V(a.X, y, a.Y), V(b.X, y, b.Y)
		local p = part(
			parent,
			name,
			V(width, height, (finish - start).Magnitude),
			CFrame.lookAt((start + finish) / 2, finish),
			color
		)
		p.CastShadow = false
		return p
	end
	local function boundaryCuts(a: Vector2, b: Vector2, current: Region): { number }
		local values = { 0, 1 }
		local d = b - a
		for _, other in regions do
			if other == current then
				continue
			end
			for j, c in other.polygon do
				local e = other.polygon[j % #other.polygon + 1] - c
				local denominator = cross(d, e)
				if math.abs(denominator) > 0.00001 then
					local t, u = cross(c - a, e) / denominator, cross(c - a, d) / denominator
					if t > 0 and t < 1 and u >= -0.0001 and u <= 1.0001 then
						table.insert(values, t)
					end
				elseif math.abs(cross(c - a, d)) < 0.0001 then
					for _, p in { c, c + e } do
						local t = (p - a):Dot(d) / d:Dot(d)
						if t > 0 and t < 1 then
							table.insert(values, t)
						end
					end
				end
			end
		end
		table.sort(values)
		return values
	end
	for _, region in regions do
		local group = Instance.new("Model")
		group.Name, group.WorldPivot = region.name, CFrame.new(65, top, 224)
		local lo, hi = region.polygon[1], region.polygon[3]
		local surface = part(
			group,
			"PavingSurface",
			V(hi.X - lo.X, 0.2, hi.Y - lo.Y),
			CFrame.new((lo.X + hi.X) / 2, top - 0.1, (lo.Y + hi.Y) / 2),
			FILL
		)
		surface.Material = Enum.Material.Plastic
		local studs = Instance.new("Texture")
		studs.Name, studs.Texture, studs.Face = "PathStuds", STUDS, Enum.NormalId.Top
		studs.StudsPerTileU, studs.StudsPerTileV = Palette.StudsPerTile, Palette.StudsPerTile
		studs.Transparency = Palette.StudsTransparency
		-- Keep one stud phase across every rectangle.
		studs.OffsetStudsU, studs.OffsetStudsV = lo.X % 8, lo.Y % 8
		studs.Parent = surface
		for i, a in region.polygon do
			local b = region.polygon[i % #region.polygon + 1]
			if region.openX and math.abs(a.X - region.openX) < 0.001 and math.abs(b.X - region.openX) < 0.001 then
				continue
			end
			if region.openZ and math.abs(a.Y - region.openZ) < 0.001 and math.abs(b.Y - region.openZ) < 0.001 then
				continue
			end
			local d = b - a
			local outward = P(d.Y, -d.X).Unit
			local cuts = boundaryCuts(a, b, region)
			for j = 1, #cuts - 1 do
				if cuts[j + 1] - cuts[j] < 0.0001 then
					continue
				end
				local middle = a + d * ((cuts[j] + cuts[j + 1]) / 2) + outward * 0.02
				local exposed = true
				for _, other in regions do
					if other ~= region and inside(middle, other.polygon) then
						exposed = false
						break
					end
				end
				if exposed then
					local p, q = a + d * cuts[j], a + d * cuts[j + 1]
					bar(group, "PathCurb", p + outward * 0.35, q + outward * 0.35, 0.7, 0.32, top - 0.06, CURB)
					bar(group, "InsetBorder", p - outward * 0.8, q - outward * 0.8, 1.0, 0.025, top + 0.045, EDGE)
				end
			end
		end
		group.Parent = root
		task.wait()
	end

	-- Chunky studded trees stand along the walls instead of a lamp every few studs; the lawn
	-- islands stay open so no tree hides a station from the boulevard.
	local garden = map:FindFirstChild("SpawnGarden")
	local terraces = garden and garden:FindFirstChild("SideTerraces1")
	local template = terraces and terraces:FindFirstChild("TerraceTree")
	if template and template:IsA("Model") then
		local trees = Instance.new("Model")
		trees.Name, trees.WorldPivot = "LawnTrees", CFrame.new(65, top, 224)
		local base = template:GetPivot()
		for i, spot in
			{
				P(-39, 205),
				P(-39, 232),
				P(-40, 274),
				P(116, 159),
				P(150, 291),
			}
		do
			local tree = template:Clone()
			tree.Name = "LawnTree"
			tree:PivotTo(
				CFrame.new(spot.X, apron.Position.Y - 0.3, spot.Y) * base.Rotation * CFrame.Angles(0, i * 0.4, 0)
			)
			tree:ScaleTo(tree:GetScale() * (0.85 + (i % 3) * 0.08))
			tree.Parent = trees
		end
		trees.Parent = root
	end

	checkerLawn(map)
	hideRetiredPaving(map)
	root:SetAttribute("Version", VERSION)
	root:SetAttribute("PavingTop", top)
	return root
end

return Layout
