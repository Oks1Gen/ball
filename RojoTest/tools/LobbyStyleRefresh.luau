-- Edit pass: one look for the World1 lobby, its terraces and the entrance tunnel (2026-11-01).
-- Re-runnable: the wall checker is rebuilt, everything else only fills in what is missing.
-- Palette and rules: server/LobbyPalette.luau and docs/lobby-style.md. Run in Edit, then save.
--   1. every studs texture of the lobby folders gets one transparency and one tile size;
--   2. garden decor shades snap to the palette tokens, paths take the palette colours;
--   3. studded decor and stone blocks get studs on every face that is not buried;
--   4. every earth face seen from the lobby or the tunnel gets the 4-stud checker
--      (Map.World1.TerraceChecker), the tunnel ceiling included; faces hidden by neighbours
--      are cut out, and faces in one plane share one row pattern.
-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local Palette = require(game.ServerScriptService.Server.LobbyPalette)
local map = workspace.Map.World1
assert(not map:GetAttribute("WorldLayoutReady"), "Historical builder: use LobbyWalls.apply on the current scene")
local V = Vector3.new
local CELL = Palette.CheckerCell
-- The lobby, its terraces and the tunnel; biome scenery further out keeps its own look.
local REGION_MIN, REGION_MAX = V(-105, 0, 60), V(225, 140, 400)
-- Lobby folders whose studs share one look; stations, rankings and biome areas keep theirs.
local STYLED = {
	Lobby = true,
	SpawnGarden = true,
	SpawnGardenPolish = true,
	SmallMapFlowers = true,
	CornerRockGarden = true,
	CompactLobbyLayout = true,
	EnvironmentPolish = true,
	NativeEnvironment = true,
	SurfaceRepairs = true,
	TerraceChecker = true,
}
-- Garden decor: palette snap and studs on every face. Lobby ground tiles are not decor.
local DECOR = table.clone(STYLED)
DECOR.Lobby, DECOR.TerraceChecker = nil, nil
-- An earth face gets the checker when the point just outside it lies in one of these boxes
-- (bounds of the lobby centred on X 55 by tools/LobbyCenterRelayout.luau).
local SEEN = {
	{ V(-85, 0, 120), V(195, 100, 356) }, -- the lobby and the inner faces of its terraces
	{ V(-89.5, 0, 60), V(199.5, 100, 130) }, -- the entrance tunnel, inside and both ends
}
local FACES = {
	Enum.NormalId.Top,
	Enum.NormalId.Bottom,
	Enum.NormalId.Left,
	Enum.NormalId.Right,
	Enum.NormalId.Front,
	Enum.NormalId.Back,
}
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby style refresh")

local function within(p: Vector3, lo: Vector3, hi: Vector3): boolean
	return p.X > lo.X and p.X < hi.X and p.Y > lo.Y and p.Y < hi.Y and p.Z > lo.Z and p.Z < hi.Z
end
local function topFolder(inst: Instance): string?
	local x = inst
	while x.Parent and x.Parent ~= map do
		x = x.Parent :: Instance
	end
	return x.Parent == map and x.Name or nil
end
local function distance(a: Color3, b: Color3): number
	return math.sqrt((a.R - b.R) ^ 2 + (a.G - b.G) ^ 2 + (a.B - b.B) ^ 2) * 255
end
local function isWater(p: BasePart): boolean
	return p.Material == Enum.Material.Glass
		or p.Material == Enum.Material.Neon
		or p.Material == Enum.Material.ForceField
		or p.Name:find("Water") ~= nil
end
local function addStuds(p: BasePart, face: Enum.NormalId, name: string)
	local t = Instance.new("Texture")
	t.Name, t.Texture, t.Face = name, Palette.Studs, face
	t.StudsPerTileU, t.StudsPerTileV = Palette.StudsPerTile, Palette.StudsPerTile
	t.Transparency = Palette.StudsTransparency
	t.Parent = p
end
local function studdedFaces(p: BasePart): { [Enum.NormalId]: boolean }
	local have = {}
	for _, t in p:GetChildren() do
		if t:IsA("Texture") and t.Texture == Palette.Studs then
			have[t.Face] = true
		end
	end
	return have
end
-- World-axis bounds of a part turned only by quarter turns about Y; nil for any other rotation.
local function box(p: BasePart): (Vector3?, Vector3?)
	local cf = p.CFrame
	if math.abs(cf.UpVector.Y) < 0.999 then
		return nil, nil
	end
	local r = cf.RightVector
	if math.abs(r.X) < 0.999 and math.abs(r.Z) < 0.999 then
		return nil, nil
	end
	local s = p.Size
	local half = math.abs(r.X) > 0.5 and V(s.X, s.Y, s.Z) / 2 or V(s.Z, s.Y, s.X) / 2
	return cf.Position - half, cf.Position + half
end
-- A face is buried when something solid touches it at all four sample points.
local rays = RaycastParams.new()
rays.FilterType = Enum.RaycastFilterType.Exclude
local function solidHit(origin: Vector3, direction: Vector3): boolean
	local hit = workspace:Raycast(origin, direction, rays)
	return hit ~= nil and not (hit.Instance:IsA("BasePart") and isWater(hit.Instance))
end
local function buried(p: BasePart, owner: BasePart, face: Enum.NormalId): boolean
	rays.FilterDescendantsInstances = { p, owner }
	local n = Vector3.FromNormalId(face)
	local a = math.abs(n.X) > 0.5 and V(0, 1, 0) or V(1, 0, 0)
	local b = n:Cross(a)
	local s = p.Size
	local depth, ha, hb = math.abs(n:Dot(s)) / 2, math.abs(a:Dot(s)) / 2, math.abs(b:Dot(s)) / 2
	local normal = p.CFrame:VectorToWorldSpace(n)
	for _, k in { V(0.7, 0.7, 0), V(-0.7, 0.7, 0), V(0.7, -0.7, 0), V(-0.7, -0.7, 0) } do
		local point = p.CFrame:PointToWorldSpace(n * depth + a * ha * k.X + b * hb * k.Y)
		if not solidHit(point - normal * 0.05, normal * 0.7) and not solidHit(point + normal * 0.7, -normal * 0.68) then
			return false
		end
	end
	return true
end

-- Visible parts: SurfaceSeparation draws some originals as copies, which carry the textures.
local checker = map:FindFirstChild("TerraceChecker")
if checker then
	checker:Destroy()
end
local parts = {}
for _, p in map:GetDescendants() do
	if p:IsA("BasePart") and p.Transparency < 0.9 and within(p.Position, REGION_MIN, REGION_MAX) then
		local owner = p
		local link = p.Parent == map.SurfaceSeparation and p:FindFirstChild("OriginalPart")
		if link and link:IsA("ObjectValue") and link.Value then
			owner = link.Value :: BasePart
		end
		table.insert(parts, { part = p, owner = owner, folder = topFolder(owner) })
	end
end

-- 1-3. Studs, palette snap and studs on every face of decor blocks.
local normalized, snapped, added = 0, 0, 0
for i, entry in parts do
	local p: BasePart = entry.part
	if not STYLED[entry.folder] then
		continue
	end
	for _, t in p:GetChildren() do
		-- Studs hidden on purpose (Transparency 1) stay hidden.
		if t:IsA("Texture") and t.Texture == Palette.Studs and t.Transparency < 0.95 then
			t.Transparency = Palette.StudsTransparency
			t.StudsPerTileU, t.StudsPerTileV = Palette.StudsPerTile, Palette.StudsPerTile
			normalized += 1
		end
	end
	local isEarth = distance(p.Color, Palette.Earth) < 6
		or distance(p.Color, Color3.fromRGB(159, 111, 72)) < 6
		or distance(p.Color, Color3.fromRGB(193, 155, 117)) < 6
		or distance(p.Color, Color3.fromRGB(211, 143, 71)) < 6
	if isEarth then
		p.Color, entry.owner.Color = Palette.Earth, Palette.Earth
	end
	if not DECOR[entry.folder] or isEarth or isWater(p) or not (p.ClassName == "Part" or p:IsA("WedgePart")) then
		continue
	end
	local best, bestDistance = nil, Palette.SnapDistance
	for _, token in Palette.SnapTokens do
		local d = distance(p.Color, token)
		if d < bestDistance then
			best, bestDistance = token, d
		end
	end
	if best and bestDistance > 0.5 then
		p.Color = best
		entry.owner.Color = best
		snapped += 1
	end
	local have = studdedFaces(p)
	local stone = distance(p.Color, Palette.Stone) < 1 or distance(p.Color, Palette.StoneLight) < 1
	local blockShaped = p:IsA("WedgePart") or (p :: Part).Shape == Enum.PartType.Block
	local s = p.Size
	if (next(have) or stone) and blockShaped and p.Transparency < 0.5 and math.min(s.X, s.Y, s.Z) >= 1.2 then
		for _, face in FACES do
			if not have[face] and not buried(p, entry.owner, face) then
				addStuds(p, face, "LobbyStuds")
				added += 1
			end
		end
	end
	if i % 150 == 0 then
		task.wait()
	end
end
for _, p in map.CompactLobbyLayout:GetDescendants() do
	if p:IsA("BasePart") then
		if p.Name == "PavingSurface" then
			p.Color = Palette.Path
		elseif p.Name == "InsetBorder" then
			p.Color = Palette.PathEdge
		elseif p.Name == "PathCurb" then
			p.Color = Palette.PathCurb
		end
	end
end

-- 4. Wall checker.
local solids, walls = {}, {}
for _, entry in parts do
	local p: BasePart = entry.part
	if p.ClassName ~= "Part" or (p :: Part).Shape ~= Enum.PartType.Block or p.Transparency >= 0.5 or isWater(p) then
		continue
	end
	local lo, hi = box(p)
	if not lo or not hi then
		continue
	end
	local size = hi - lo
	if math.max(size.X, size.Y, size.Z) >= 4 and math.min(size.X, size.Y, size.Z) >= 0.5 then
		table.insert(solids, { min = lo, max = hi })
	end
	if distance(p.Color, Palette.Earth) < 6 and math.min(size.X, size.Y, size.Z) >= 2 then
		table.insert(walls, { part = p, min = lo, max = hi })
	end
end

local function subtract(r, o)
	if o[1] >= r[2] or o[2] <= r[1] or o[3] >= r[4] or o[4] <= r[3] then
		return { r }
	end
	local pieces = {}
	local function add(u0, u1, v0, v1)
		if u1 - u0 > 0.05 and v1 - v0 > 0.05 then
			table.insert(pieces, { u0, u1, v0, v1 })
		end
	end
	add(r[1], o[1], r[3], r[4])
	add(o[2], r[2], r[3], r[4])
	local u0, u1 = math.max(r[1], o[1]), math.min(r[2], o[2])
	add(u0, u1, r[3], o[3])
	add(u0, u1, o[4], r[4])
	return pieces
end
local function subtractAll(rects, o)
	local rest = {}
	for _, r in rects do
		for _, piece in subtract(r, o) do
			table.insert(rest, piece)
		end
	end
	return rest
end
local function get(v: Vector3, axis: string): number
	return (v :: any)[axis]
end
local function seen(point: Vector3): boolean
	for _, b in SEEN do
		if within(point, b[1], b[2]) then
			return true
		end
	end
	return false
end
local sides = {
	{ normal = V(1, 0, 0), axis = "X", u = "Z", v = "Y", face = Enum.NormalId.Right },
	{ normal = V(-1, 0, 0), axis = "X", u = "Z", v = "Y", face = Enum.NormalId.Left },
	{ normal = V(0, 0, 1), axis = "Z", u = "X", v = "Y", face = Enum.NormalId.Back },
	{ normal = V(0, 0, -1), axis = "Z", u = "X", v = "Y", face = Enum.NormalId.Front },
	{ normal = V(0, -1, 0), axis = "Y", u = "X", v = "Z", face = Enum.NormalId.Bottom },
}

-- 4a. The visible part of every seen earth face.
local faces = {}
for _, wall in walls do
	local lo, hi = wall.min, wall.max
	for _, f in sides do
		local sign = get(f.normal, f.axis)
		local w = sign > 0 and get(hi, f.axis) or get(lo, f.axis)
		local centre = (lo + hi) / 2
		local outside = centre + f.normal * (math.abs(w - get(centre, f.axis)) + 0.5)
		if not seen(outside) or (f.axis == "Y" and lo.Y < 21) then
			continue
		end
		-- Blocks touching this face from outside hide parts of it.
		local covers = {}
		for _, s in solids do
			local near = sign > 0 and get(s.min, f.axis) or -get(s.max, f.axis)
			local far = sign > 0 and get(s.max, f.axis) or -get(s.min, f.axis)
			if near < sign * w + 0.3 and far > sign * w + 0.02 then
				table.insert(covers, {
					get(s.min, f.u) - 0.12,
					get(s.max, f.u) + 0.12,
					get(s.min, f.v) - 0.12,
					get(s.max, f.v) + 0.12,
				})
			end
		end
		local u0, u1 = get(lo, f.u), get(hi, f.u)
		local v0, v1 = get(lo, f.v), get(hi, f.v)
		-- A wall's rows end at what covers its foot (ground or a lower ledge): climb from the
		-- bottom through stacked blocks at five columns and take the median.
		local foot = v0
		if f.v == "Y" then
			local feet = {}
			for k = 1, 5 do
				local at = u0 + (u1 - u0) * (k - 0.5) / 5
				local y = v0
				local raised = true
				while raised and y < v1 do
					raised = false
					for _, c in covers do
						if c[1] <= at and c[2] >= at and c[3] <= y + 0.2 and c[4] - 0.12 > y + 0.01 then
							y, raised = math.min(c[4] - 0.12, v1), true
						end
					end
				end
				table.insert(feet, y)
			end
			table.sort(feet)
			foot = feet[3]
		end
		local visible = { { u0, u1, foot, v1 } }
		for _, c in covers do
			visible = subtractAll(visible, c)
		end
		if #visible > 0 and v1 - foot >= 1 then
			table.insert(faces, {
				part = wall.part,
				f = f,
				sign = sign,
				w = w,
				u0 = u0,
				u1 = u1,
				foot = foot,
				top = v1,
				visible = visible,
				key = f.axis .. sign .. math.round(w * 2),
			})
		end
	end
end

-- 4b. Touching faces in one plane form one wall: one row pattern, and no tile laid twice.
local parent = {}
local function find(i: number): number
	while parent[i] ~= i do
		parent[i] = parent[parent[i]]
		i = parent[i]
	end
	return i
end
for i = 1, #faces do
	parent[i] = i
end
for i = 1, #faces do
	for j = i + 1, #faces do
		local a, b = faces[i], faces[j]
		if
			a.key == b.key
			and a.u0 <= b.u1 + 0.5
			and b.u0 <= a.u1 + 0.5
			and a.foot <= b.top + 0.5
			and b.foot <= a.top + 0.5
		then
			parent[find(i)] = find(j)
		end
	end
end
local groups = {}
for i, face in faces do
	local r = find(i)
	groups[r] = groups[r] or {}
	table.insert(groups[r], face)
end

-- 4c. Tiles: dark cells only; the light cells are the studded wall itself.
local root = Instance.new("Folder")
root.Name = "TerraceChecker"
root:SetAttribute("Cell", CELL)
root.Parent = map
local tiles, faceCount = 0, 0
local function tile(face, visible, top: number, foot: number)
	local f, w, sign = face.f, face.w, face.sign
	local rows, height, origin
	if f.v == "Y" then
		rows = math.max(1, math.round((top - foot) / CELL))
		height, origin = (top - foot) / rows, top
	else
		-- Ceilings follow the world grid both ways.
		rows = math.ceil(face.top / CELL) - math.floor(face.foot / CELL)
		height, origin = -CELL, math.floor(face.foot / CELL) * CELL
	end
	local group = Instance.new("Model")
	group.Name = face.part.Name .. "Checker"
	for row = 0, rows - 1 do
		local a, b = origin - row * height, origin - (row + 1) * height
		local r0, r1 = math.min(a, b), math.max(a, b)
		local parity = f.v == "Y" and row or math.floor(r0 / CELL + 0.5)
		for column = math.floor(face.u0 / CELL), math.ceil(face.u1 / CELL) - 1 do
			if (column + parity) % 2 == 0 then
				continue
			end
			local cell = { column * CELL, (column + 1) * CELL, r0, r1 }
			for _, r in visible do
				local a0, a1 = math.max(cell[1], r[1]), math.min(cell[2], r[2])
				local b0, b1 = math.max(cell[3], r[3]), math.min(cell[4], r[4])
				if a1 - a0 > 0.05 and b1 - b0 > 0.05 then
					local t = Instance.new("Part")
					t.Name, t.Color, t.Material = "CheckerTile", Palette.EarthDark, Enum.Material.Plastic
					t.Anchored, t.CanCollide, t.CanTouch, t.CanQuery = true, false, false, false
					t.CastShadow = false
					t.TopSurface, t.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
					local out = w + sign * Palette.WallCheckerDepth / 2
					local along, up = (a0 + a1) / 2, (b0 + b1) / 2
					if f.axis == "X" then
						t.Size, t.CFrame = V(Palette.WallCheckerDepth, b1 - b0, a1 - a0), CFrame.new(out, up, along)
					elseif f.axis == "Z" then
						t.Size, t.CFrame = V(a1 - a0, b1 - b0, Palette.WallCheckerDepth), CFrame.new(along, up, out)
					else
						t.Size, t.CFrame = V(a1 - a0, Palette.WallCheckerDepth, b1 - b0), CFrame.new(along, out, up)
					end
					addStuds(t, f.face, "CheckerStuds")
					t.Parent = group
					tiles += 1
				end
			end
		end
	end
	if not studdedFaces(face.part)[f.face] then
		addStuds(face.part, f.face, "LobbyStuds")
	end
	faceCount += 1
	group.Parent = root
	task.wait()
end
for _, group in groups do
	table.sort(group, function(a, b)
		return (a.u1 - a.u0) * (a.top - a.foot) > (b.u1 - b.u0) * (b.top - b.foot)
	end)
	local top, foot = -math.huge, math.huge
	for _, face in group do
		top, foot = math.max(top, face.top), math.min(foot, face.foot)
	end
	local claimed = {}
	for _, face in group do
		local visible = face.visible
		for _, c in claimed do
			visible = subtractAll(visible, c)
		end
		for _, r in visible do
			table.insert(claimed, r)
		end
		if #visible > 0 then
			tile(face, visible, top, foot)
		end
	end
end
map:SetAttribute("LobbyStyle", 2)
game:GetService("ChangeHistoryService"):SetWaypoint("Lobby style refresh")
return string.format(
	"studs normalized %d, colours snapped %d, faces studded %d, checker %d faces / %d tiles",
	normalized,
	snapped,
	added,
	faceCount,
	tiles
)
