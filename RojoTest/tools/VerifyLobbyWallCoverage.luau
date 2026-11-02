-- Read-only Edit/Server probes: exposed terrace corners must have studs and the correct grid.
local world = workspace.Map.World1
local palette = require(game.ServerScriptService.Server.LobbyPalette:Clone())
local root = assert(world.Lobby.Geometry:FindFirstChild("TerraceWallChecker"))
local walls, solids, tiles = {}, {}, {}
local names = { TerraceEarth = true, RearEarthLedge = true, GrassShelf = true, RearGrassLedge = true }
for _, p in world.Lobby:GetDescendants() do
	if p:IsA("BasePart") and p.Transparency < 1 and names[p.Name] then
		table.insert(solids, p)
		if p.Name == "TerraceEarth" or p.Name == "RearEarthLedge" then
			table.insert(walls, p)
		end
	end
end
for _, p in root:GetDescendants() do
	if p:IsA("BasePart") then
		table.insert(tiles, p)
	end
end
local probes, faces = 0, 0
for _, wall in walls do
	local lo, hi = wall.Position - wall.Size / 2, wall.Position + wall.Size / 2
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Right, Enum.NormalId.Left } do
		if face ~= Enum.NormalId.Front then
			if wall.Name ~= "TerraceEarth" then
				continue
			end
			if (face == Enum.NormalId.Right) ~= (wall.Position.X < 50) then
				continue
			end
		end
		local normal = Vector3.FromNormalId(face)
		local axis, u = if normal.X ~= 0 then "X" else "Z", if normal.X ~= 0 then "Z" else "X"
		local sign = normal[axis]
		local plane = if sign > 0 then hi[axis] else lo[axis]
		local hasStuds = false
		for _, t in wall:GetChildren() do
			if t:IsA("Texture") and t.Face == face and t.Transparency < 1 and t.Texture == palette.Studs then
				hasStuds = true
			end
		end
		local faceProbes = 0
		for horizontal = lo[u] + 0.53, hi[u] - 0.1, 1.73 do
			for y = math.max(20, lo.Y) + 0.53, hi.Y - 0.1, 1.73 do
				-- Stay clear of tile borders to make the expected colour unambiguous.
				local hu, vy = horizontal % palette.CheckerCell, y % palette.CheckerCell
				if math.min(hu, palette.CheckerCell - hu, vy, palette.CheckerCell - vy) < 0.05 then
					continue
				end
				local point = if axis == "X"
					then Vector3.new(plane, y, horizontal)
					else Vector3.new(horizontal, y, plane)
				local outside, blocked = point + normal * 0.06, false
				for _, solid in solids do
					if solid ~= wall then
						local p = solid.CFrame:PointToObjectSpace(outside)
						local h = solid.Size / 2
						if
							math.abs(p.X) < h.X - 0.001
							and math.abs(p.Y) < h.Y - 0.001
							and math.abs(p.Z) < h.Z - 0.001
						then
							blocked = true
							break
						end
					end
				end
				if blocked then
					continue
				end
				assert(hasStuds, "Exposed face has no studs: " .. wall:GetFullName() .. face.Name)
				local found = false
				for _, tile in tiles do
					local p = tile.CFrame:PointToObjectSpace(point + normal * palette.WallCheckerDepth / 2)
					local h = tile.Size / 2
					if
						math.abs(p.X) <= h.X + 0.001
						and math.abs(p.Y) <= h.Y + 0.001
						and math.abs(p.Z) <= h.Z + 0.001
					then
						assert(not found, "Overlapping terrace tiles")
						found = true
					end
				end
				local dark = (math.floor(horizontal / palette.CheckerCell) + math.floor(y / palette.CheckerCell)) % 2
					== 1
				assert(found == dark, "Missing/extra checker at " .. tostring(point))
				assert(wall.Color == palette.Earth, "Wrong wall base colour")
				probes += 1
				faceProbes += 1
			end
		end
		if faceProbes > 0 then
			faces += 1
		end
		task.wait()
	end
end
assert(faces > 0 and probes > 0, "No exposed terrace faces checked")
assert(
	not workspace.Map:FindFirstChild("World2") and not world.Lobby:FindFirstChild("Portal"),
	"Retired world/gate remains"
)
return { faces = faces, probes = probes, tiles = #tiles }
