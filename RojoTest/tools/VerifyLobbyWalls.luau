-- Read-only audit of the final wall and grass-cap facade.
local world = workspace.Map.World1
-- Lattice measured in the 0.8 scene; follows the world scale.
local relative = world:GetAttribute("WorldScale") / 0.8
local PITCH, CELL, TILE = 1.6 * relative, 3.2 * relative, 6.4 * relative
local sources = game.ServerScriptService.Server
local paletteModule = sources.LobbyPalette:Clone()
paletteModule.Parent = game.ServerStorage
local palette = require(paletteModule)
paletteModule:Destroy()
local total, caps, edges, faces = 0, 0, 0, 0
local physicalPlanes = {}
local function component(v, axis)
	return if axis == "X" then v.X elseif axis == "Y" then v.Y else v.Z
end
for _, name in { "SideTerraces1", "SideTerraces2", "RearTerraces", "EntranceTunnel" } do
	local owner = world.Lobby.Environment[name]
	local cladding = assert(owner:FindFirstChild("WallCladding"), name .. " has no facade")
	assert(cladding:GetAttribute("Builder") == "LobbyWallCoverage")
	for _, group in cladding:GetChildren() do
		local axis, sign = group:GetAttribute("Axis"), group:GetAttribute("Sign")
		local isCap = group:GetAttribute("IsCap")
		local u, v = if axis == "X" then "Z" else "X", if axis == "Y" then "Z" else "Y"
		local physicalKey = axis .. ":" .. sign .. ":" .. math.round(group:GetAttribute("Plane") * 1000)
		local rectangles = physicalPlanes[physicalKey] or {}
		physicalPlanes[physicalKey] = rectangles
		local seen = {}
		faces += 1
		for _, p in group:GetChildren() do
			assert(p:IsA("BasePart") and p.Anchored and p.Transparency == 0, "Invalid facade geometry")
			assert(
				not p.CanCollide and not p.CanTouch and not p.CanQuery and not p.CastShadow,
				"Facade affects physics"
			)
			assert(math.abs(component(p.Size, axis) - palette.WallCheckerDepth) < 0.00001, "Facade protrudes")
			local plane = component(p.Position, axis) - sign * component(p.Size, axis) / 2
			assert(math.abs(plane - group:GetAttribute("Plane")) < 0.001, "Skin is detached from wall")
			local textures = 0
			for _, t in p:GetChildren() do
				if t:IsA("Texture") then
					textures += 1
					assert(t.Name == "WallStuds" and t.Texture == palette.Studs, "Wrong wall texture")
					assert(
						math.abs(t.StudsPerTileU - TILE) < 0.001 and math.abs(t.StudsPerTileV - TILE) < 0.001,
						"Studs stretched or wrongly scaled"
					)
					assert(t.OffsetStudsU == 0 and t.OffsetStudsV == 0, "Cut stud phase")
					assert(math.abs(t.Transparency - palette.StudsTransparency) < 0.001, "Wrong stud visibility")
				end
			end
			assert(textures == 1, "Duplicate or missing stud layer")
			local a, b = component(p.Size, u), component(p.Size, v)
			if isCap or p.Name == "WallEdge" then
				assert(p.Name == "CapSurface" or p.Name == "WallEdge")
				for _, size in { a, b } do
					assert(math.abs(size / PITCH - math.round(size / PITCH)) < 0.001, "Partial cap stud row")
				end
				if isCap then
					caps += 1
				else
					edges += 1
				end
			else
				assert(
					p.Name == "WallCell" and math.abs(a - CELL) < 0.001 and math.abs(b - CELL) < 0.001,
					"Clipped wall checker"
				)
				local gu, gv = p:GetAttribute("GridU"), p:GetAttribute("GridV")
				local id = gu .. ":" .. gv
				assert(not seen[id], "Overlapping wall checker cells")
				seen[id] = true
				assert(
					math.abs(component(p.Position, u) - a / 2 - group:GetAttribute("OriginU") - gu * CELL) < 0.001,
					"Shifted checker column"
				)
				assert(
					math.abs(component(p.Position, v) - b / 2 - group:GetAttribute("OriginV") - gv * CELL) < 0.001,
					"Shifted checker row"
				)
				local color = if (gu + gv + group:GetAttribute("Parity")) % 2 == 0
					then palette.Earth
					else palette.EarthDark
				assert(p.Color == color, "Broken checker parity")
				total += 1
			end
			local r = {
				component(p.Position, u) - a / 2,
				component(p.Position, u) + a / 2,
				component(p.Position, v) - b / 2,
				component(p.Position, v) + b / 2,
			}
			for _, previous in rectangles do
				assert(
					math.min(r[2], previous[2]) - math.max(r[1], previous[1]) < 0.001
						or math.min(r[4], previous[4]) - math.max(r[3], previous[3]) < 0.001,
					"Overlapping coplanar surfaces"
				)
			end
			table.insert(rectangles, r)
		end
		task.wait()
	end
end
for _, p in world:GetDescendants() do
	assert(
		p.Name ~= "TerraceWallChecker" and p.Name ~= "LeftAbutmentChecker" and p.Name ~= "RightAbutmentChecker",
		"Retired checker fragments remain: " .. p:GetFullName()
	)
end
assert(total > 2000 and caps > 0, "Missing wall facade")
return { cells = total, capParts = caps, edgeParts = edges, faces = faces, studPitch = PITCH }
