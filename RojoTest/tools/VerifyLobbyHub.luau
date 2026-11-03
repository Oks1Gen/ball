-- Read-only checks of the lobby hub network, the removed entrance arch, the extended rear with
-- the leaderboard row and the egg plaza, the paved ball stand, and the framed kick zone with
-- its scrolling arrows.
-- Paving is cosmetic (CanQuery off), so probes hit disposable query copies of its surfaces.
local world = workspace.Map.World1
local lobby = world.Lobby
local paths = lobby.Paths
local refs = require(game.ReplicatedStorage.Shared.WorldRefs)
-- Authored coordinates below are in the unscaled lobby and map through the world scale.
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local k = Scale.factor(world)
local function at(x, y, z)
	return Scale.point(world, Vector3.new(x, y, z))
end
local sourceRoot = game.ServerScriptService.Server
local fresh = sourceRoot.KickZoneStyle:Clone()
fresh.Parent = sourceRoot
local curbWidth = require(fresh).CurbWidth
fresh:Destroy()
local paletteSource = sourceRoot.LobbyPalette:Clone()
paletteSource.Parent = sourceRoot
local Palette = require(paletteSource)
paletteSource:Destroy()
local lanes = refs.training(world)
local apron = refs.kickZoneFloor(world)
local spawn = refs.spawn(world)

local function rect(part)
	if part:IsA("Model") then
		local r = { math.huge, -math.huge, math.huge, -math.huge }
		for _, p in part:GetChildren() do
			if p:IsA("BasePart") and p.Name == "PavingSurface" then
				r[1] = math.min(r[1], p.Position.X - p.Size.X / 2)
				r[2] = math.max(r[2], p.Position.X + p.Size.X / 2)
				r[3] = math.min(r[3], p.Position.Z - p.Size.Z / 2)
				r[4] = math.max(r[4], p.Position.Z + p.Size.Z / 2)
			end
		end
		return r
	end
	local p, s = part.Position, part.Size / 2
	return { p.X - s.X, p.X + s.X, p.Z - s.Z, p.Z + s.Z }
end

local surfaces = {}
for _, group in paths:GetChildren() do
	for _, part in group:GetChildren() do
		if part:IsA("BasePart") and part.Name == "PavingSurface" then
			table.insert(surfaces, { group = group.Name, part = part, r = rect(part) })
		end
	end
end
-- Independently check the dimensions and joins that were visibly broken.
local checkerCount, rimCount = 0, 0
local floorParts = {}
local height = surfaces[1].part.Position.Y + surfaces[1].part.Size.Y / 2
local gridBounds = rect(paths.Hub)
for _, group in paths:GetChildren() do
	if group:GetAttribute("PathGridVersion") == 2 then
		for _, p in group:GetChildren() do
			if p:IsA("BasePart") then
				assert(p.Name == "PavingSurface" or p.Name == "PathCurb", "Old inset/frame fragment")
				assert(not p.CanCollide and not p.CanTouch and not p.CanQuery, "Paving affects physics")
				assert(math.abs(p.Position.Y + p.Size.Y / 2 - height) < 0.001, "Uneven paving level")
				for _, length in { p.Size.X, p.Size.Z } do
					assert(math.abs(length / 1.6 - math.round(length / 1.6)) < 0.001, "Partial stud row")
				end
				local bounds = rect(p)
				for _, edge in { bounds[1] - gridBounds[1], bounds[3] - gridBounds[3] } do
					assert(math.abs(edge / 1.6 - math.round(edge / 1.6)) < 0.001, "Shifted stud lattice")
				end
				if p:GetAttribute("CheckerCell") then
					assert(
						math.abs(p.Size.X - 6.4) < 0.001 and math.abs(p.Size.Z - 6.4) < 0.001,
						"Clipped checker square"
					)
					checkerCount += 1
				elseif p.Name == "PathCurb" then
					rimCount += 1
				end
				local texture = p:FindFirstChild("PathStuds")
				assert(
					texture
						and texture.StudsPerTileU == texture.StudsPerTileV
						and math.abs(texture.StudsPerTileU - 6.4) < 0.001,
					"Stretched studs"
				)
				assert(texture.OffsetStudsU == 0 and texture.OffsetStudsV == 0, "Cut stud phase")
				table.insert(floorParts, p)
			end
		end
	end
end
for i, a in floorParts do
	for j = i + 1, #floorParts do
		local b = floorParts[j]
		local x = (a.Size.X + b.Size.X) / 2 - math.abs(a.Position.X - b.Position.X)
		local z = (a.Size.Z + b.Size.Z) / 2 - math.abs(a.Position.Z - b.Position.Z)
		assert(x < 0.001 or z < 0.001, "Overlapping paving or doubled corner")
	end
end
assert(checkerCount > 100 and rimCount > 0, "Missing complete path grid")

local temporary = Instance.new("Folder")
temporary.Name = "LobbyHubVerification"
for _, s in surfaces do
	local copy = s.part:Clone()
	copy:ClearAllChildren()
	copy.CanQuery, copy.Transparency = true, 1
	copy.Parent = temporary
end
temporary.Parent = workspace
task.wait()

local ok, result = pcall(function()
	local render = RaycastParams.new()
	render.FilterType = Enum.RaycastFilterType.Include
	render.FilterDescendantsInstances = { temporary }
	local physical = RaycastParams.new()
	physical.FilterType = Enum.RaycastFilterType.Include
	physical.FilterDescendantsInstances = { world }
	physical.RespectCanCollide = true
	local top = surfaces[1].part.Position.Y + surfaces[1].part.Size.Y / 2
	local probes = 0
	local function paved(x, z)
		local hit = workspace:Raycast(Vector3.new(x, top + 2, z), Vector3.new(0, -4, 0), render)
			or workspace:Raycast(Vector3.new(x + 0.001, top + 2, z + 0.001), Vector3.new(0, -4, 0), render) -- Float32 tile seam.
		return hit ~= nil and math.abs(hit.Position.Y - top) < 0.01
	end
	local function walk(x, z)
		probes += 1
		assert(paved(x, z), string.format("Paving gap at %.1f, %.1f", x, z))
		assert(
			workspace:Raycast(Vector3.new(x, top + 2, z), Vector3.new(0, -12, 0), physical),
			"Missing walkable support"
		)
	end

	-- Rectangles touch but never overlap.
	for i, a in surfaces do
		for j = i + 1, #surfaces do
			local b = surfaces[j]
			local dx = math.min(a.r[2], b.r[2]) - math.max(a.r[1], b.r[1])
			local dz = math.min(a.r[4], b.r[4]) - math.max(a.r[3], b.r[3])
			assert(dx <= 0.001 or dz <= 0.001, "Paving overlaps: " .. a.group .. " / " .. b.group)
		end
	end

	-- Every activity is connected to the hub through touching paving.
	local reached, queue = {}, {}
	for i, s in surfaces do
		if s.group == "Hub" then
			reached[i] = true
			table.insert(queue, i)
		end
	end
	assert(#queue == 16, "Hub must contain sixteen complete checker squares")
	while #queue > 0 do
		local a = surfaces[table.remove(queue)]
		for j, b in surfaces do
			if not reached[j] then
				local dx = math.min(a.r[2], b.r[2]) - math.max(a.r[1], b.r[1])
				local dz = math.min(a.r[4], b.r[4]) - math.max(a.r[3], b.r[3])
				-- A shared edge at least a player wide.
				if (math.abs(dx) < 0.001 and dz > 3) or (math.abs(dz) < 0.001 and dx > 3) then
					reached[j] = true
					table.insert(queue, j)
				end
			end
		end
	end
	local groups = {}
	for i, s in surfaces do
		if reached[i] then
			groups[s.group] = true
		end
	end
	for _, name in
		{
			"KickZonePath",
			"TrainingPath",
			"TrainingFrame",
			"BallShopPath",
			"BallCourt",
			"NorthPath",
			"EggPlaza",
		}
	do
		assert(groups[name], name .. " is not connected to the hub")
	end

	-- The hub is the centre of the map and holds the spawn.
	local hub = paths.Hub
	local h = rect(hub)
	assert(math.abs((h[1] + h[2]) / 2 - apron.Position.X) < 0.5, "Hub off the field axis")
	assert(
		spawn.Position.X > h[1] and spawn.Position.X < h[2] and spawn.Position.Z > h[3] and spawn.Position.Z < h[4],
		"Spawn outside the hub"
	)
	-- Centre lines: hub to the kick zone, training, ball stand and north plaza.
	local cx, cz = (h[1] + h[2]) / 2, (h[3] + h[4]) / 2
	local apronEdge = apron.Position.Z + apron.Size.Z / 2
	-- The path ends at the outer face of the closed kick zone curb, never on top of it.
	local curbFace = apronEdge + curbWidth
	local kickPath = rect(paths.KickZonePath)
	assert(kickPath[3] <= curbFace and curbFace - kickPath[3] < 1.6, "Threshold must tuck below the orange curb")
	for _, part in paths.KickZonePath:GetDescendants() do
		if part:IsA("BasePart") then
			assert(part.Position.Z - part.Size.Z / 2 > curbFace - 1.61, "Path part runs into the kick zone curb")
		end
	end
	for z = curbFace + 0.5, cz, 1 do
		walk(cx, z)
	end
	-- Complete vector glyphs travel toward the orange zone and fade before the ends.
	local arrows = paths.KickPathArrows
	local origin = arrows.Origin
	local length = arrows:GetAttribute("PathLength")
	assert(origin.CFrame.LookVector:Dot(Vector3.new(0, 0, -1)) > 0.999, "Arrows point away from field")
	assert(math.abs(origin.Position.X - cx) < 0.5 and origin.Position.Y > top, "Arrows off path")
	assert(not arrows.VFX_KickPathArrows.Arrows.Enabled, "Legacy image beam must stay off")
	local source = game.ReplicatedStorage.Shared.PathArrowMotion:Clone()
	source.Parent = game.ReplicatedStorage.Shared
	local Motion = require(source)
	source:Destroy()
	local copy = arrows:Clone()
	for time = 0, 18, 0.3 do
		Motion.update(copy, time)
		for _, glyph in copy:GetChildren() do
			if glyph:IsA("Model") then
				local visible = false
				for _, p in glyph:GetChildren() do
					assert(
						p:IsA("BasePart") and p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,
						"Arrow physics"
					)
					if p.Transparency < 0.99 then
						visible = true
					end
				end
				if visible then
					for _, p in glyph:GetChildren() do
						local half = p.Size / 2
						for _, q in
							{
								Vector3.new(-1, -1, -1),
								Vector3.new(1, -1, -1),
								Vector3.new(-1, -1, 1),
								Vector3.new(1, -1, 1),
								Vector3.new(-1, 1, 1),
								Vector3.new(1, 1, 1),
							}
						do
							local point = copy.Origin.CFrame:PointToObjectSpace(p.CFrame:PointToWorldSpace(half * q))
							assert(math.abs(point.X) < 6.4, "Arrow leaves road sideways")
							assert(-point.Z >= -0.01 and -point.Z <= length + 0.01, "Arrow clipped at endpoint")
						end
					end
				end
			end
		end
	end
	Motion.update(copy, 1)
	local before = copy.Chevron1:GetPivot().Position
	Motion.update(copy, 1.2)
	local delta = copy.Chevron1:GetPivot().Position - before
	assert((delta - Vector3.new(0, 0, -0.512)).Magnitude < 0.001, "Arrow speed/direction")
	copy:Destroy()

	local trainingFront = lanes.TrainingLane1.Foundation.Position.X - lanes.TrainingLane1.Foundation.Size.X / 2
	for x = cx, trainingFront - 0.5, 1 do
		walk(x, cz)
	end
	-- The ball stand stands on paving that runs past its back and both ends.
	local shopCf, shopSize = refs.balls(world):GetBoundingBox()
	local shopBack, shopFront = shopCf.X - shopSize.X / 2, shopCf.X + shopSize.X / 2
	local shopLow, shopHigh = shopCf.Z - shopSize.Z / 2, shopCf.Z + shopSize.Z / 2
	for x = shopFront + 0.5, cx, 1 do
		walk(x, cz)
	end
	for z = shopLow + 0.5, shopHigh - 0.5, 1 do
		walk(shopBack - 1, z)
		assert(paved((shopBack + shopFront) / 2, z), "Ball stand not on paving")
	end
	for x = shopBack - 1, shopFront - 0.5, 1 do
		walk(x, shopLow - 1)
		walk(x, shopHigh + 1)
	end
	local plaza = rect(paths.EggPlaza)
	for z = cz, plaza[3] + 2, 1 do
		walk(cx, z)
	end
	for x = plaza[1] + 0.5, plaza[2] - 0.5, 1 do
		walk(x, plaza[3] + 0.5)
	end

	-- Extended rear: the wall stands where the side terraces end, the boards in one row at the
	-- wall, the eggs on the plaza in front of them, and the new lawn strip is walkable.
	local back = world.FootballCourse.Boundaries.LobbyBack
	local wall = back.Position.Z - back.Size.Z / 2
	assert(math.abs(wall - at(0, 0, 348).Z) < 0.01, "Rear collision wall not at authored Z 348")
	for _, p in lobby.Environment.RearTerraces:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "RearEarthLedge" then
			assert(p.Position.Z - p.Size.Z / 2 >= wall - 0.01, "Rear terrace in front of the wall")
		end
	end
	local boardFront = math.huge
	for _, board in refs.rankings(world):GetChildren() do
		local cf, size = board:GetBoundingBox()
		local z0, z1 = cf.Z - size.Z / 2, cf.Z + size.Z / 2
		assert(wall - z1 > 0 and wall - z1 < 6, "Leaderboard not at the wall: " .. board.Name)
		boardFront = math.min(boardFront, z0)
	end
	assert(
		plaza[4] >= boardFront and plaza[4] - boardFront < 6.4,
		"Full-cell plaza must reach below the leaderboard bases"
	)
	for _, egg in refs.eggs(world):GetChildren() do
		if egg:IsA("Model") and (egg.Name:match("^Egg_") or egg.Name == "VolcanicEgg") then
			local cf, size = egg:GetBoundingBox()
			assert(cf.Z + size.Z / 2 < boardFront, "Egg behind the leaderboard row: " .. egg.Name)
			assert(paved(egg:GetPivot().X, egg:GetPivot().Z), "Egg off the plaza: " .. egg.Name)
		end
	end
	local lawn = 0
	local ground = at(0, 20, 0).Y
	local inner0, inner1 = at(-43, 0, 0).X, at(153, 0, 0).X
	for x = inner0, inner1, 4 * k do
		for z = plaza[4] + 1, wall - 1, 2 do
			local hit = workspace:Raycast(Vector3.new(x, top + 2, z), Vector3.new(0, -4, 0), physical)
			if hit and math.abs(hit.Position.Y - ground) < 0.5 then
				lawn += 1
			end
		end
	end
	assert(lawn > 0, "New lawn strip has no floor")
	-- Along the wall the waterfall pool rim stands a little above the lawn.
	for x = inner0, inner1, 4 * k do
		local hit = workspace:Raycast(Vector3.new(x, top + 2, wall - 2 * k), Vector3.new(0, -4, 0), physical)
		local y = hit and hit.Position.Y - ground
		assert(y and y > -0.5 and y < 1.5, string.format("No floor by the rear wall at X %.1f", x))
	end

	-- The frame runs round every lane, and no lane is paved over.
	for i = 1, 7 do
		local f = lanes["TrainingLane" .. i].Foundation
		local r = rect(f)
		assert(not paved((r[1] + r[2]) / 2, (r[3] + r[4]) / 2), "Paving under training lane " .. i)
		for z = r[3] + 0.5, r[4] - 0.5, 1 do
			walk(r[1] - 1, z)
			walk(r[2] + 1, z)
		end
		for x = r[1] + 0.5, r[2] - 0.5, 2 do
			walk(x, r[3] - 0.4)
			walk(x, r[4] + 0.4)
		end
	end

	-- The arch is gone: nothing visible above the opening, nothing left to restore it.
	local tunnel = lobby.Environment.EntranceTunnel
	local left, right = tunnel.LeftAbutment, tunnel.RightAbutment
	-- One stud in from each abutment: wall skins and edge planting belong to the abutments.
	local x0, x1 = left.Position.X + left.Size.X / 2 + 1, right.Position.X - right.Size.X / 2 - 1
	local z0, z1 = left.Position.Z - left.Size.Z / 2, left.Position.Z + left.Size.Z / 2
	for _, part in world:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local p = part.Position
			assert(
				not (
						p.X > x0
						and p.X < x1
						and p.Z > z0
						and p.Z < z1
						and p.Y > left.Position.Y + left.Size.Y / 2 - 7 * k
					),
				"Arch remnant: " .. part:GetFullName()
			)
		end
	end
	assert(
		tunnel:FindFirstChild("LeftAbutmentGrassCap") and tunnel:FindFirstChild("RightAbutmentGrassCap"),
		"Missing grass caps"
	)
	local backup = game.ServerStorage.WorldBackups.BeforeArchRemoval_20261102
	local journal = 0
	for _, ref in game.ServerStorage.WorldLayoutState.World1.Moves:GetChildren() do
		if ref.Value and ref.Value:IsDescendantOf(backup) then
			journal += 1
		end
	end
	assert(journal == 0, "Layout journal still restores retired arch parts")

	-- Kick Zone: full cells and one complete stud row around the panel.
	assert(apron.Color == Palette.KickZoneEdge, "Kick Zone base must match its rim")
	local checker = apron.Parent.KickZoneChecker
	local apronTop = apron.Position.Y + apron.Size.Y / 2
	local tiles, flats, curbs = 0, {}, 0
	local cells = {}
	for _, tile in checker:GetDescendants() do
		if not tile:IsA("BasePart") then
			continue
		end
		assert(not tile.CanCollide and not tile.CanTouch and not tile.CanQuery, "Kick Zone overlay affects physics")
		assert(math.abs(tile.Position.Y + tile.Size.Y / 2 - apronTop - 0.04) < 0.001, "Uneven Kick Zone panel")
		local t = assert(tile:FindFirstChild("KickZoneStuds"))
		assert(
			math.abs(t.StudsPerTileU - 6.4) < 0.001 and math.abs(t.StudsPerTileV - 6.4) < 0.001,
			"Wrong Kick Zone stud scale"
		)
		assert(t.OffsetStudsU == 0 and t.OffsetStudsV == 0, "Cut Kick Zone stud phase")
		local p = apron.CFrame:PointToObjectSpace(tile.Position)
		assert(
			math.abs(p.X) + tile.Size.X / 2 <= apron.Size.X / 2 + 0.001
				and math.abs(p.Z) + tile.Size.Z / 2 <= apron.Size.Z / 2 + 0.001,
			"Panel extends past active floor"
		)
		for _, edgeLength in { tile.Size.X, tile.Size.Z } do
			assert(math.abs(edgeLength / 1.6 - math.round(edgeLength / 1.6)) < 0.001, "Partial Kick Zone stud row")
		end
		if tile.Name == "EdgeCurb" then
			assert(tile.Color == Palette.KickZoneEdge, "Curb colour")
			assert(math.abs(math.min(tile.Size.X, tile.Size.Z) - 1.6) < 0.001, "Rim cannot fit one stud")
			curbs += 1
		else
			assert(tile.Name == "CheckerTile", "Unexpected Kick Zone layer")
			assert(
				math.abs(tile.Size.X - 3.2) < 0.001 and math.abs(tile.Size.Z - 3.2) < 0.001,
				"Clipped Kick Zone cell"
			)
			local x, z = tile:GetAttribute("GridX"), tile:GetAttribute("GridZ")
			local id = x .. ":" .. z
			assert(not cells[id], "Duplicate Kick Zone cell")
			cells[id] = true
			assert(
				tile.Color == (if (x + z) % 2 == 0 then Palette.KickZoneChecker else Palette.KickZone),
				"Broken checker parity"
			)
			tiles += 1
		end
		table.insert(flats, rect(tile))
	end
	for i, a in flats do
		for j = i + 1, #flats do
			local b = flats[j]
			local dx = math.min(a[2], b[2]) - math.max(a[1], b[1])
			local dz = math.min(a[4], b[4]) - math.max(a[3], b[3])
			assert(dx <= 0.001 or dz <= 0.001, "Kick Zone overlays overlap")
		end
	end
	assert(
		curbs == 4 and tiles == checker:GetAttribute("Columns") * checker:GetAttribute("Rows"),
		"Incomplete Kick Zone panel"
	)
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, bounds in flats do
		minX, maxX = math.min(minX, bounds[1]), math.max(maxX, bounds[2])
		minZ, maxZ = math.min(minZ, bounds[3]), math.max(maxZ, bounds[4])
	end
	local floorBounds = rect(apron)
	for i, edge in { minX, maxX, minZ, maxZ } do
		assert(math.abs(edge - floorBounds[i]) < 0.001, "Kick Zone base protrudes beyond its rim")
	end
	local print = apron.Parent.KickZonePrint
	assert(print.KickZoneLabel.TextLabel.Text == "KICK ZONE", "Old Kick Zone lettering")
	assert(not apron:FindFirstChildWhichIsA("Texture"), "Floor texture overlaps the panel")
	return {
		surfaces = #surfaces,
		checkerCells = checkerCount,
		rimRectangles = rimCount,
		connectedGroups = #(function()
			local list = {}
			for name in groups do
				table.insert(list, name)
			end
			return list
		end)(),
		walkProbes = probes,
		kickZoneTiles = tiles,
		kickZoneCurbs = curbs,
		rearLawnFloorHits = lawn,
		retiredArchParts = #backup:GetChildren(),
	}
end)
temporary:Destroy()
assert(ok, result)
return result
