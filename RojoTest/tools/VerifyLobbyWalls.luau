-- Read-only audit of the final wall and grass-cap facade.
local world = workspace.Map.World1
local sources = game.ServerScriptService.Server
local paletteModule = sources.LobbyPalette:Clone()
paletteModule.Parent = game.ServerStorage
local palette = require(paletteModule)
paletteModule:Destroy()
local total, caps, faces = 0, 0, 0
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
		local seen, rectangles = {}, {}
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
						math.abs(t.StudsPerTileU - 6.4) < 0.001 and math.abs(t.StudsPerTileV - 6.4) < 0.001,
						"Studs stretched or wrongly scaled"
					)
					assert(t.OffsetStudsU == 0 and t.OffsetStudsV == 0, "Cut stud phase")
					assert(math.abs(t.Transparency - palette.StudsTransparency) < 0.001, "Wrong stud visibility")
				end
			end
			assert(textures == 1, "Duplicate or missing stud layer")
			local a, b = component(p.Size, u), component(p.Size, v)
			if isCap then
				assert(p.Name == "CapSurface")
				for _, size in { a, b } do
					assert(math.abs(size / 1.6 - math.round(size / 1.6)) < 0.001, "Partial cap stud row")
				end
				caps += 1
			else
				assert(
					p.Name == "WallCell" and math.abs(a - 3.2) < 0.001 and math.abs(b - 3.2) < 0.001,
					"Clipped wall checker"
				)
				local gu, gv = p:GetAttribute("GridU"), p:GetAttribute("GridV")
				local id = gu .. ":" .. gv
				assert(not seen[id], "Overlapping wall checker cells")
				seen[id] = true
				assert(
					math.abs(component(p.Position, u) - a / 2 - group:GetAttribute("OriginU") - gu * 3.2) < 0.001,
					"Shifted checker column"
				)
				assert(
					math.abs(component(p.Position, v) - b / 2 - group:GetAttribute("OriginV") - gv * 3.2) < 0.001,
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
for _, name in { "TerraceWallChecker", "LeftAbutmentChecker", "RightAbutmentChecker" } do
	assert(not world.Lobby.Geometry:FindFirstChild(name), "Retired checker fragments remain")
end
assert(total > 2000 and caps > 0, "Missing wall facade")
return { cells = total, capParts = caps, faces = faces, studPitch = 1.6 }
