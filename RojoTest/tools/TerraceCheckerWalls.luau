-- Edit migration: checkered studded terrace walls in the World1 lobby (2026-11-01). Run once in
-- Edit, then save the place. Every earth face that looks into the lobby gets a 4-stud checker:
-- light cells are the wall itself, dark cells are 0.1-stud studded tiles in Map.World1.TerraceChecker.
-- Rows are fitted between the face top and whatever covers its foot (ground or a lower ledge),
-- columns follow the world grid. Wall faces without studs get them; their textures are tagged
-- TerraceCheckerStuds. Rollback: delete TerraceChecker and the tagged textures.
-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local map = workspace.Map.World1
assert(not map:GetAttribute("WorldLayoutReady"), "Historical builder: use LobbyWalls.apply on the current scene")
assert(not map:FindFirstChild("TerraceChecker"), "Terrace checker already applied")
local V = Vector3.new
local CELL = 4
local GROUND = 20
local Palette = require(game.ServerScriptService.Server.LobbyPalette)
local DARK = Palette.EarthDark
local DEPTH = Palette.WallCheckerDepth
local STUDS = "rbxassetid://88156646156237"
-- Lobby side of the perimeter: faces whose outside lies beyond these limits are never seen.
local INSIDE_X0, INSIDE_X1, INSIDE_Z1 = -57, 195, 356
game:GetService("ChangeHistoryService"):SetWaypoint("Before terrace checker")

-- Visible version of each terrace block: SurfaceSeparation draws some of them as copies.
local renders = {}
for _, render in map.SurfaceSeparation:GetChildren() do
	local link = render:FindFirstChild("OriginalPart")
	if link and link.Value and render:IsA("BasePart") then
		renders[link.Value] = render
	end
end
local walls, solids = {}, {}
local wallNames = { TerraceEarth = true, RearEarthLedge = true }
local solidNames = { TerraceEarth = true, RearEarthLedge = true, GrassShelf = true, RearGrassLedge = true }
for _, group in map.SpawnGarden:GetChildren() do
	if group.Name:match("^SideTerraces") or group.Name == "RearTerraces" then
		for _, p in group:GetChildren() do
			if p:IsA("BasePart") and solidNames[p.Name] then
				local visible = p.Transparency < 1 and p or renders[p]
				if visible then
					local half = visible.Size / 2
					table.insert(solids, { min = visible.Position - half, max = visible.Position + half })
					if wallNames[p.Name] then
						table.insert(walls, visible)
					end
				end
			end
		end
	end
end

local function component(v: Vector3, axis: string): number
	return (v :: any)[axis]
end
-- Parts of rectangle r (u0, u1, y0, y1) left after removing rectangle o.
local function subtract(r, o)
	if o[1] >= r[2] or o[2] <= r[1] or o[3] >= r[4] or o[4] <= r[3] then
		return { r }
	end
	local pieces = {}
	local function add(u0, u1, y0, y1)
		if u1 - u0 > 0.05 and y1 - y0 > 0.05 then
			table.insert(pieces, { u0, u1, y0, y1 })
		end
	end
	add(r[1], o[1], r[3], r[4])
	add(o[2], r[2], r[3], r[4])
	local u0, u1 = math.max(r[1], o[1]), math.min(r[2], o[2])
	add(u0, u1, r[3], o[3])
	add(u0, u1, o[4], r[4])
	return pieces
end
local function studs(p: BasePart, face: Enum.NormalId, transparency: number)
	local t = Instance.new("Texture")
	t.Name, t.Texture, t.Face = "TerraceCheckerStuds", STUDS, face
	t.StudsPerTileU, t.StudsPerTileV, t.Transparency = 8, 8, transparency
	t.Parent = p
end

local root = Instance.new("Folder")
root.Name, root.Parent = "TerraceChecker", map
local faces = {
	{ normal = V(1, 0, 0), axis = "X", u = "Z", face = Enum.NormalId.Right },
	{ normal = V(-1, 0, 0), axis = "X", u = "Z", face = Enum.NormalId.Left },
	{ normal = V(0, 0, 1), axis = "Z", u = "X", face = Enum.NormalId.Back },
	{ normal = V(0, 0, -1), axis = "Z", u = "X", face = Enum.NormalId.Front },
}
local tiles, faceCount = 0, 0
for _, wall in walls do
	local lo, hi = wall.Position - wall.Size / 2, wall.Position + wall.Size / 2
	for _, f in faces do
		local sign = component(f.normal, f.axis)
		local w = sign > 0 and component(hi, f.axis) or component(lo, f.axis)
		local outside = wall.Position + f.normal * (math.abs(w - component(wall.Position, f.axis)) + 0.5)
		if outside.X <= INSIDE_X0 or outside.X >= INSIDE_X1 or outside.Z >= INSIDE_Z1 then
			continue
		end
		-- Blocks touching this face from outside hide parts of it.
		local covers = {}
		for _, s in solids do
			local near = sign > 0 and component(s.min, f.axis) or -component(s.max, f.axis)
			local far = sign > 0 and component(s.max, f.axis) or -component(s.min, f.axis)
			if near < sign * w + 0.3 and far > sign * w + 0.02 then
				table.insert(covers, {
					component(s.min, f.u) - 0.12,
					component(s.max, f.u) + 0.12,
					s.min.Y - 0.12,
					s.max.Y + 0.12,
				})
			end
		end
		local u0, u1 = component(lo, f.u), component(hi, f.u)
		local top = hi.Y
		local foot = math.max(lo.Y, GROUND)
		local middle = (u0 + u1) / 2
		-- A ledge's earth and grass are separate blocks, so climb until nothing covers the foot.
		local raised = true
		while raised and foot < top do
			raised = false
			for _, c in covers do
				if c[1] <= middle and c[2] >= middle and c[3] <= foot + 0.2 and c[4] - 0.12 > foot + 0.01 then
					foot, raised = math.min(c[4] - 0.12, top), true
				end
			end
		end
		local visible = { { u0, u1, foot, top } }
		for _, c in covers do
			local rest = {}
			for _, r in visible do
				for _, piece in subtract(r, c) do
					table.insert(rest, piece)
				end
			end
			visible = rest
		end
		if #visible == 0 or top - foot < 1 then
			continue
		end
		faceCount += 1
		local textured = false
		for _, t in wall:GetChildren() do
			if t:IsA("Texture") and t.Face == f.face then
				textured = true
			end
		end
		if not textured then
			studs(wall, f.face, 0.28)
		end
		local rows = math.max(1, math.round((top - foot) / CELL))
		local height = (top - foot) / rows
		local group = Instance.new("Model")
		group.Name = wall.Name .. "Checker"
		for row = 0, rows - 1 do
			local y1 = top - row * height
			local y0 = y1 - height
			for column = math.floor(u0 / CELL), math.ceil(u1 / CELL) - 1 do
				if (column + row) % 2 == 0 then
					continue
				end
				local cell = { math.max(column * CELL, u0), math.min((column + 1) * CELL, u1), y0, y1 }
				for _, r in visible do
					local a0, a1 = math.max(cell[1], r[1]), math.min(cell[2], r[2])
					local b0, b1 = math.max(cell[3], r[3]), math.min(cell[4], r[4])
					if a1 - a0 > 0.05 and b1 - b0 > 0.05 then
						local tile = Instance.new("Part")
						tile.Name, tile.Color, tile.Material = "CheckerTile", DARK, Enum.Material.Plastic
						tile.Anchored, tile.CanCollide, tile.CanTouch, tile.CanQuery = true, false, false, false
						tile.CastShadow = false
						tile.TopSurface, tile.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
						local along = (a0 + a1) / 2
						local out = w + sign * DEPTH / 2
						if f.axis == "X" then
							tile.Size = V(DEPTH, b1 - b0, a1 - a0)
							tile.CFrame = CFrame.new(out, (b0 + b1) / 2, along)
						else
							tile.Size = V(a1 - a0, b1 - b0, DEPTH)
							tile.CFrame = CFrame.new(along, (b0 + b1) / 2, out)
						end
						studs(tile, f.face, 0.28)
						tile.Parent = group
						tiles += 1
					end
				end
			end
		end
		group.Parent = root
		task.wait()
	end
end
root:SetAttribute("Cell", CELL)
game:GetService("ChangeHistoryService"):SetWaypoint("Terrace checker")
return string.format("%d faces, %d tiles", faceCount, tiles)
