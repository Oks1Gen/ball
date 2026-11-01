-- Edit migration: compact World1 lobby (2026-11-01). Run once in Edit, then save the place.
-- Walls move inward in multiples of 8 studs so the shared stud-texture phase is kept.
-- Every moved BasePart keeps its previous CFrame in the BeforeLobbyCompaction attribute;
-- removed decor goes to ServerStorage.WorldBackups.BeforeLobbyCompaction_20261101.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local map = workspace.Map.World1
assert(not map:GetAttribute("LobbyCompacted"), "Lobby already compacted")
local V = Vector3.new
local WEST, EAST, REAR = V(32, 0, 0), V(-24, 0, 0), V(0, 0, -32)
local WALL_W, WALL_E, WALL_R = -17, 155, 315
local server = game.ServerScriptService.Server
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby compaction")

local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name, backups.Parent = "WorldBackups", game.ServerStorage
local backup = Instance.new("Folder")
backup.Name, backup.Parent = "BeforeLobbyCompaction_20261101", backups

-- Render copies made by SurfaceSeparation must follow their original part.
local renders = {}
for _, render in map.SurfaceSeparation:GetChildren() do
	local link = render:FindFirstChild("OriginalPart")
	if link and link.Value then
		renders[link.Value] = renders[link.Value] or {}
		table.insert(renders[link.Value], render)
	end
end

local moved = 0
local function partsOf(item)
	local list = {}
	if item:IsA("BasePart") then
		table.insert(list, item)
	end
	for _, d in item:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end
-- Apply a rigid transform (world CFrame delta) to an instance and its separated renders.
local function transform(item, delta)
	for _, p in partsOf(item) do
		if p:GetAttribute("BeforeLobbyCompaction") == nil then
			p:SetAttribute("BeforeLobbyCompaction", p.CFrame)
		end
		for _, r in renders[p] or {} do
			if r:GetAttribute("BeforeLobbyCompaction") == nil then
				r:SetAttribute("BeforeLobbyCompaction", r.CFrame)
			end
			r.CFrame = delta * r.CFrame
		end
		p.CFrame = delta * p.CFrame
		moved += 1
	end
	for _, m in item:GetDescendants() do
		if m:IsA("Model") then
			m.WorldPivot = delta * m.WorldPivot
		end
	end
	if item:IsA("Model") then
		item.WorldPivot = delta * item.WorldPivot
	end
end
local function shift(item, offset)
	transform(item, CFrame.new(offset))
end
local function center(item)
	if item:IsA("BasePart") then
		return item.Position
	elseif item:IsA("Model") then
		return (item:GetBoundingBox()).Position
	end
	local parts = partsOf(item)
	if #parts == 0 then
		return nil
	end
	local sum = V()
	for _, p in parts do
		sum += p.Position
	end
	return sum / #parts
end
local removed = 0
local function retire(item, reason)
	local link = Instance.new("ObjectValue")
	link.Name, link.Value = "CompactionOriginalParent", item.Parent
	item:SetAttribute("CompactionOriginalPath", item:GetFullName())
	item:SetAttribute("CompactionReason", reason)
	for _, p in partsOf(item) do
		for _, r in renders[p] or {} do
			r.Parent = item
		end
	end
	item.Parent = backup
	link.Parent = item
	removed += 1
end
-- Decor near a wall moves with that wall.
local function byWall(item)
	local c = center(item)
	if not c then
		return
	end
	local offset = V()
	if c.X < WALL_W then
		offset += WEST
	elseif c.X > WALL_E then
		offset += EAST
	end
	if c.Z > WALL_R then
		offset += REAR
	end
	if offset.Magnitude > 0 then
		shift(item, offset)
	end
end

-- 1. Perimeter: terraces, plantings, wall crowns and the invisible boundary blockers.
local garden, polish, sw = map.SpawnGarden, map.SpawnGardenPolish, map.SkippingWorld
shift(garden.SideTerraces1, WEST)
shift(garden.SideTerraces2, EAST)
shift(garden.RearTerraces, REAR)
shift(polish.SideTerraces1Planting, WEST)
shift(polish.SideTerraces2Planting, EAST)
shift(polish.RearTerracesPlanting, REAR)
shift(polish.StoneOutcrops1, WEST)
shift(polish.StoneOutcrops2, EAST)
shift(map.PerimeterWalls.LobbyLeft, WEST)
shift(map.PerimeterWalls.LobbyRight, EAST)
shift(map.PerimeterWalls.LobbyBack, REAR)
for _, crown in sw:GetChildren() do
	if crown.Name == "GrassWallCrown" then
		byWall(crown)
	end
end
shift(map.LobbyWaterfallGarden, EAST)
shift(map.CornerRockGarden, WEST)
-- One waterfall now stands behind the trophy at the end of the boulevard.
shift(garden.CornerWaterfall1, V(90.5, 0, -32))
retire(garden.CornerWaterfall2, "Single central waterfall in the compact rear row")
shift(garden.GroundGarden1, V(18, 0, 10))
retire(garden.GroundGarden2, "Rear-left corner now holds a ranking board")
shift(garden.GroundGarden3, V(6.5, 0, -34))
shift(garden.GroundGarden4, V(-6, 0, -5))
retire(map.StoneGrassWalkway, "East walkway lies inside the new east terrace")

-- 2. Stations.
shift(sw.World2Portal, V(8, 0, 0))
local STAND = V(48, 0, 4)
shift(map.EmptyItemStand, STAND)
shift(workspace.AllBalls_NoTextures, STAND)
for _, item in sw:GetChildren() do
	if item.Name:match("^DisplayStone_") or item.Name:match("^BallLabelAnchor%d+$") then
		shift(item, STAND)
	end
end
-- The back row sits in the gaps of the front row as seen from the spawn.
local eggTargets = {
	Common = V(46, 0, 266),
	Uncommon = V(27, 0, 266),
	Rare = V(8, 0, 266),
	Rainbow = V(30, 0, 285),
}
for id, target in eggTargets do
	local egg = sw["Egg_" .. id]
	local pivot = egg:GetPivot().Position
	shift(egg, V(target.X - pivot.X, 0, target.Z - pivot.Z))
end
local admin = sw.HackedAdminEgg
local adminOffset = V(7 - admin.Position.X, 0, 285 - admin.Position.Z)
local adminOld = admin.Position
for _, item in sw:GetChildren() do
	local c = center(item)
	local named = item.Name == "HackedAdminEgg"
		or item.Name == "HackedEggStand"
		or item.Name == "VolcanicEggVisual"
		or item.Name == "VolcanicEggFallback"
		or item.Name == "AdminEggCaption"
		or item.Name == "LabelAnchor"
	if named and c and (V(c.X, 0, c.Z) - V(adminOld.X, 0, adminOld.Z)).Magnitude < 8 then
		shift(item, adminOffset)
	end
end

-- 3. Hall of fame: four boards in one straight row facing the boulevard, trophy in the middle.
local boardX = { ReservedFourthBoard = 7, skill = 37, wins = 98, best = 128 }
for name, x in boardX do
	local board = map.LobbyRankings[name]
	local frame = board.Frame
	local target = CFrame.new(x, frame.Position.Y, 305)
	transform(board, target * frame.CFrame:Inverse())
end
local trophy = workspace.ImportedTrophy
local tp = trophy:GetPivot()
transform(trophy, CFrame.new(67.5, tp.Y, 287) * tp:Inverse())

-- 4. Loose lobby decor follows the walls; anything left on a station or path is retired.
local looseSets = {
	map.SmallMapFlowers:GetChildren(),
	sw.ImprovedLobbyFlowers:GetChildren(),
	map.NativeEnvironment.LobbyAccents:GetChildren(),
	map.EnvironmentPolish.LobbyGardens:GetChildren(),
	{ map.Lobby.Trunk },
}
local loose = {}
for _, set in looseSets do
	for _, item in set do
		local c = center(item)
		if c and c.X > -100 and c.X < 230 and c.Z > 118 and c.Z < 400 then
			table.insert(loose, item)
			byWall(item)
		end
	end
end
-- Footprints that must stay clear: paths, stations and the hall row.
local clear = {
	{ 58, 77, 150, 279 },
	{ 47, 88, 279, 301 },
	{ -9, 47, 293, 309 },
	{ 88, 144, 293, 309 },
	{ -6, 30, 150, 194 },
	{ 30, 58, 165, 179 },
	{ 3, 34, 189, 255 },
	{ 34, 58, 215, 229 },
	{ -6, 58, 258, 279 },
	{ -6, 47, 279, 293 },
	{ 77, 150, 168, 290 },
	{ 50, 85, 276, 315 },
}
for _, item in loose do
	local c = center(item)
	if not c or c.Y > 30 then
		continue
	end
	for _, r in clear do
		if c.X > r[1] - 1 and c.X < r[2] + 1 and c.Z > r[3] - 1 and c.Z < r[4] + 1 then
			retire(item, "Overlapped a compact lobby path or station")
			break
		end
	end
end

-- Retired originals no longer match their SurfaceSeparation records; list them as expected.
local retiredIds = {}
for _, d in backup:GetDescendants() do
	local id = d:IsA("BasePart") and not d:FindFirstChild("OriginalPart") and d:GetAttribute("SurfaceSeparationId")
	if id then
		table.insert(retiredIds, id)
	end
end
table.sort(retiredIds)
map.SurfaceSeparation:SetAttribute("RetiredRecordIds", table.concat(retiredIds, ","))

-- 5. Redraw the cosmetic paving for the new placement.
retire(map.CompactLobbyLayout, "Replaced by compact lobby layout v2")
local source = server.CompactLobbyLayout:Clone()
source.Name, source.Parent = "CompactLobbyRelayoutMigration", server
local ok, result = pcall(function()
	local module = require(source)
	local root = assert(module.apply(map))
	require(server.MapHierarchy).organize(map)
	assert(root:IsA("Folder"), "Map sections must use the canonical Folder container")
	local count = #root:GetDescendants()
	assert(module.apply(map) == root and #root:GetDescendants() == count, "Repeated apply changed the result")
	return count
end)
source:Destroy()
assert(ok, result)
map:SetAttribute("LobbyCompacted", "2026-11-01")
game:GetService("ChangeHistoryService"):SetWaypoint("After lobby compaction")
return string.format("moved %d parts, retired %d items, layout %d instances", moved, removed, result)
