-- Edit migration: extend the World1 lobby away from the course (2026-11-02). Run once in Edit,
-- then save the place. The rear wall goes back 32 studs to where the side terraces already end
-- (their tiers stop at Z 348, 357 and 366: the pre-compaction rear line). The leaderboards stand
-- in one row at the new wall, the waterfall between the pairs; the eggs stand in a shallow arc in
-- front of them with the Volcanic egg in the middle, in front of the waterfall. Afterwards the
-- server modules redraw the wall checker (LobbyWalls) and the paving (LobbyPaths).
-- Every moved BasePart keeps its previous CFrame in BeforeRearExtension; retired items go to
-- ServerStorage.WorldBackups.BeforeRearExtension_20261102 with RearExtensionOriginalPath.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local world = workspace.Map.World1
assert(not world:GetAttribute("LobbyRearExtended"), "Lobby rear already extended")
local V = Vector3.new
local REAR = V(0, 0, 32)
local OLD_WALL, NEW_WALL = 316, 348
local BOARD_Z = 340 -- frame centre: backs 4.5 studs off the new wall
-- Egg pivots (X, Z). Order seen from the hub: Common, Uncommon, Volcanic, Rare, Rainbow; each
-- egg stands in front of a board and keeps its turn towards the middle of the plaza.
local EGGS = {
	Egg_Common = { 116, 314 },
	Egg_Uncommon = { 86, 320 },
	VolcanicEgg = { 55.5, 323 },
	Egg_Rare = { 25, 320 },
	Egg_Rainbow = { -5, 314 },
}
-- Corner decor beside the board row moves back with the wall.
local ROW_X0, ROW_X1, CORNER_Z = -21, 132, 280

local lobby = world.Lobby
local env = lobby.Environment
local back = world.FootballCourse.Boundaries.LobbyBack
assert(math.abs(back.Position.Z - back.Size.Z / 2 - OLD_WALL) < 0.01, "Rear wall moved: remeasure")
for _, name in { "SideTerraces1", "SideTerraces2" } do
	local reach = -math.huge
	for _, p in env[name]:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "TerraceEarth" then
			reach = math.max(reach, p.Position.Z + p.Size.Z / 2)
		end
	end
	assert(reach >= NEW_WALL + 18 - 0.01, name .. " no longer reaches the extended rear wall")
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby rear extension")

-- Render copies made by SurfaceSeparation must follow their original part.
local renders = {}
for _, link in workspace:GetDescendants() do
	if link:IsA("ObjectValue") and link.Name == "OriginalPart" and link.Value and link.Parent:IsA("BasePart") then
		renders[link.Value] = renders[link.Value] or {}
		table.insert(renders[link.Value], link.Parent)
	end
end
local function originalOf(part)
	local link = part:FindFirstChild("OriginalPart")
	return if link and link:IsA("ObjectValue") and link.Value then link.Value else part
end
local function centre(item)
	if item:IsA("BasePart") then
		return item.Position
	end
	return (item:GetBoundingBox()).Position
end

-- Plan first, move last: support raycasts must see the scene as it was.
local plan, planned = {}, {}
local function assign(item, delta)
	if item and not planned[item] then
		planned[item] = true
		table.insert(plan, { item = item, delta = delta })
	end
end
local rear = CFrame.new(REAR)
assign(env.RearTerraces, rear)
assign(env.RearTerracesPlanting, rear)
assign(env.CornerWaterfall1, rear)
assign(back, rear)

-- Loose decor standing on the rear terraces goes with them.
local rays = RaycastParams.new()
rays.FilterType = Enum.RaycastFilterType.Exclude
local function onRearTerrace(item, c)
	rays.FilterDescendantsInstances = { item, lobby.Geometry.TerraceWallChecker }
	local hit = workspace:Raycast(c + V(0, 3, 0), V(0, -12, 0), rays)
	return hit ~= nil and originalOf(hit.Instance):IsDescendantOf(env.RearTerraces)
end
local loose = {}
for _, set in { env.Flowers, env.LobbyGardens, env.LobbyAccents, lobby.Paths.LawnTrees } do
	for _, item in set:GetChildren() do
		table.insert(loose, item)
	end
end
for _, item in env:GetChildren() do
	if item.Name == "GroundGarden3" then
		table.insert(loose, item)
	end
end
for _, item in lobby.Geometry:GetChildren() do
	if item.Name == "UnclassifiedBlock" then
		table.insert(loose, item)
	end
end
for _, item in loose do
	local solid = item:IsA("BasePart") or (item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart", true) ~= nil)
	if not solid then
		continue
	end
	local c = centre(item)
	local terrace = c.Y > 25 and c.Z > OLD_WALL - 2 and onRearTerrace(item, c)
	local corner = c.Y < 30 and c.Z > CORNER_Z and c.Z < OLD_WALL and (c.X < ROW_X0 or c.X > ROW_X1)
	if terrace or corner then
		assign(item, rear)
	end
end

-- Leaderboards: one row at the new wall, same X.
for _, board in lobby.Leaderboards:GetChildren() do
	local frame = board:FindFirstChild("Frame")
	assert(frame and frame:IsA("BasePart"), "Ranking frame missing: " .. board.Name)
	assign(board, CFrame.new(0, 0, BOARD_Z - frame.Position.Z))
end
-- Eggs: pure translation of the whole model, so turns, signs and anchors stay together.
for name, target in EGGS do
	local egg = lobby.EggShop:FindFirstChild(name)
	assert(egg, "Missing egg " .. name)
	local pivot = egg:GetPivot().Position
	assign(egg, CFrame.new(target[1] - pivot.X, 0, target[2] - pivot.Z))
end

-- The oak hidden inside the old rear terrace would stand on the new lawn in front of a board.
local retire = {}
for _, item in env:GetChildren() do
	if item.Name == "RobloxOak" and centre(item).X > ROW_X0 and centre(item).X < ROW_X1 + 10 then
		table.insert(retire, item)
	end
end

-- Apply the plan.
local moved = 0
local done = {}
local function remember(p)
	if p:GetAttribute("BeforeRearExtension") == nil then
		p:SetAttribute("BeforeRearExtension", p.CFrame)
	end
end
for i, step in plan do
	if i % 20 == 0 then
		task.wait()
	end
	local parts = {}
	-- Pivots are read before the parts move: a model whose pivot was never set follows its parts.
	local pivots = {}
	for _, d in { step.item, table.unpack(step.item:GetDescendants()) } do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		elseif d:IsA("Model") then
			pivots[d] = d.WorldPivot
		end
	end
	for _, p in parts do
		for _, q in { p, table.unpack(renders[p] or {}) } do
			if not done[q] then
				done[q] = true
				remember(q)
				q.CFrame = step.delta * q.CFrame
				moved += 1
			end
		end
	end
	for m, pivot in pivots do
		m.WorldPivot = step.delta * pivot
	end
end

-- Retire: originals with their render copies, out of the layout journal and SurfaceSeparation.
local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name, backups.Parent = "WorldBackups", game.ServerStorage
local backup = Instance.new("Folder")
backup.Name, backup.Parent = "BeforeRearExtension_20261102", backups
local covered, ids = {}, {}
for _, item in retire do
	local nodes = { item }
	for _, d in item:GetDescendants() do
		if d:IsA("BasePart") then
			for _, r in renders[d] or {} do
				if not r:IsDescendantOf(item) then
					table.insert(nodes, r)
				end
			end
		end
	end
	for _, node in nodes do
		for _, d in { node, table.unpack(node:GetDescendants()) } do
			covered[d] = true
			local id = d:GetAttribute("SurfaceSeparationId")
			if typeof(id) == "number" then
				ids[id] = true
			end
		end
		node:SetAttribute("RearExtensionOriginalPath", node.Parent:GetFullName())
		node.Parent = backup
	end
end
local journal = game.ServerStorage:FindFirstChild("WorldLayoutState")
journal = journal and journal:FindFirstChild(world.Name)
local moves = journal and journal:FindFirstChild("Moves")
if moves then
	for _, ref in moves:GetChildren() do
		if ref:IsA("ObjectValue") and ref.Value and covered[ref.Value] then
			ref:Destroy()
		end
	end
end
local sources = journal and journal:FindFirstChild("Sources")
local separation = world:FindFirstChild("SurfaceSeparation")
	or (sources and sources:FindFirstChild("SurfaceSeparation"))
if separation and next(ids) then
	local previous = separation:GetAttribute("RetiredRecordIds")
	for id in string.gmatch(if typeof(previous) == "string" then previous else "", "%d+") do
		ids[tonumber(id)] = true
	end
	local list = {}
	for id in ids do
		table.insert(list, id)
	end
	table.sort(list)
	separation:SetAttribute("RetiredRecordIds", table.concat(list, ","))
end

-- Redraw the wall checker and the paving for the new rear line. Fresh copies of the modules and
-- the palette they share bypass Studio's require cache from earlier Edit runs.
local server = game.ServerScriptService.Server
local fresh = Instance.new("Folder")
fresh.Name = "RearExtensionMigration"
for _, name in { "LobbyPalette", "LobbyPathRegions", "LobbyWallCoverage", "LobbyWalls", "LobbyPaths", "ThrowZoneStyle" } do
	server[name]:Clone().Parent = fresh
end
fresh.Parent = game.ServerScriptService
local results = {}
local ok, problem = pcall(function()
	for _, name in { "LobbyWalls", "LobbyPaths", "ThrowZoneStyle" } do
		results[name] = require(fresh[name]).apply(world)
	end
end)
fresh:Destroy()
assert(ok, problem)

world:SetAttribute("LobbyRearExtended", "2026-11-02")
game:GetService("ChangeHistoryService"):SetWaypoint("After lobby rear extension")
return string.format(
	"planned %d items, moved %d parts, retired %d items, wall checker rebuilt=%s, paving regions %s",
	#plan,
	moved,
	#retire,
	tostring(type(results.LobbyWalls) == "table" and results.LobbyWalls.rebuilt),
	tostring(results.LobbyPaths)
)
