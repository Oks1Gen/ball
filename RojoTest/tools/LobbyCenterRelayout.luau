-- Edit migration: centre the World1 lobby on the field axis X 55 (2026-11-01). Run once in Edit
-- after CompactLobbyRelayout and before LobbyStyleRefresh, then save the place.
-- The field, the entrance arch and the kick zone are centred on X 55; the compact lobby was not
-- (walls -17..155, boulevard and rankings on X 67.5). Shifts are multiples of 4 studs so the
-- stud texture and the 4-stud wall checker keep their phase:
--   west wall -28 (inner face -45, mirrors the east wall at 155 inside the arch legs);
--   everything between the walls -12 (boulevard, stations, rankings, training lanes, rear
--   terraces and the rear waterfall), so the boulevard runs on X 55.5;
--   the east wall and its waterfall stay; the kick zone and the tunnel opening stay;
--   the east tunnel abutment is trimmed from 62 to 42 studs to mirror the west one.
-- Every moved BasePart keeps its previous CFrame in BeforeLobbyCentering (resized tunnel parts
-- also keep BeforeLobbyCenteringSize). Afterwards run tools/LobbyStyleRefresh.luau to rebuild
-- the wall checker.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local map = workspace.Map.World1
assert(map:GetAttribute("LobbyCompacted"), "Run CompactLobbyRelayout first")
assert(not map:GetAttribute("LobbyCentered"), "Lobby already centred")
local V = Vector3.new
local WEST, CENTRE, STAY = V(-28, 0, 0), V(-12, 0, 0), V()
local WALL_W, WALL_E, FRONT = -3, 145, 150
local TRIM = 20
local server = game.ServerScriptService.Server
local garden, polish, sw = map.SpawnGarden, map.SpawnGardenPolish, map.SkippingWorld
assert(math.abs(map.PerimeterWalls.LobbyLeft.Position.X + 20) < 0.01, "West wall moved: remeasure")
assert(math.abs(polish.EntranceTunnel.RightAbutment.Size.X - 62) < 0.01, "Tunnel changed: remeasure")
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby centring")

-- Render copies made by SurfaceSeparation must follow their original part.
local renders = {}
for _, render in map.SurfaceSeparation:GetChildren() do
	local link = render:FindFirstChild("OriginalPart")
	if link and link.Value then
		renders[link.Value] = renders[link.Value] or {}
		table.insert(renders[link.Value], render)
	end
end

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

-- Plan first, move last: support raycasts must see the scene as it was.
local plan, planned = {}, {}
local function assign(item, offset)
	if item and not planned[item] then
		planned[item] = true
		table.insert(plan, { item = item, offset = offset })
	end
end
local function byPosition(c)
	if c.X < WALL_W then
		return WEST
	elseif c.X > WALL_E or c.Z < FRONT then
		return STAY
	end
	return CENTRE
end

-- 1. Walls and terraces.
assign(garden.SideTerraces1, WEST)
assign(polish.SideTerraces1Planting, WEST)
assign(polish.StoneOutcrops1, WEST)
assign(map.CornerRockGarden, WEST)
assign(map.PerimeterWalls.LobbyLeft, WEST)
assign(garden.GroundGarden1, WEST)
assign(garden.RearTerraces, CENTRE)
assign(polish.RearTerracesPlanting, CENTRE)
assign(garden.CornerWaterfall1, CENTRE)
assign(map.PerimeterWalls.LobbyBack, CENTRE)
for _, crown in sw:GetChildren() do
	if crown.Name == "GrassWallCrown" then
		local c = crown.Position
		assign(crown, c.Z > 300 and CENTRE or c.X < WALL_W and WEST or STAY)
	end
end

-- 2. Stations, rankings, training lanes and the spawn keep their places relative to the boulevard.
assign(map.LobbyRankings, CENTRE)
assign(map.TrainingZone, CENTRE)
assign(map.EmptyItemStand, CENTRE)
assign(workspace:FindFirstChild("AllBalls_NoTextures"), CENTRE)
assign(map.Lobby.MapSpawn, CENTRE)
for _, item in sw:GetChildren() do
	if item.Name == "KickPad" or item.Name == "KickZonePrint" or item.Name == "ImprovedLobbyFlowers" then
		continue
	end
	local parts = partsOf(item)
	if #parts == 0 then
		continue
	end
	local lo, hi = V(math.huge, math.huge, math.huge), V(-math.huge, -math.huge, -math.huge)
	for _, p in parts do
		lo, hi = lo:Min(p.Position), hi:Max(p.Position)
	end
	if lo.Z > FRONT - 6 and lo.X > -60 and hi.X < 200 then
		assign(item, CENTRE)
	end
end
-- A loose brick lying on the rear terrace stays on its block.
local loose = workspace:FindFirstChild("Part")
if loose and loose:IsA("BasePart") and (loose.Position - V(107, 82.5, 348)).Magnitude < 2 then
	assign(loose, CENTRE)
end
-- Paths move with the boulevard; trees by the walls stay with their wall.
for _, item in map.CompactLobbyLayout:GetChildren() do
	if item.Name ~= "LawnTrees" then
		assign(item, CENTRE)
	end
end
for _, tree in map.CompactLobbyLayout.LawnTrees:GetChildren() do
	assign(tree, byPosition(tree:GetPivot().Position))
end

-- 3. Loose decor: on a terrace it follows that terrace, on the lawn it goes by position.
local groupOf = {
	[garden.SideTerraces1] = WEST,
	[polish.SideTerraces1Planting] = WEST,
	[polish.StoneOutcrops1] = WEST,
	[garden.RearTerraces] = CENTRE,
	[polish.RearTerracesPlanting] = CENTRE,
	[garden.SideTerraces2] = STAY,
	[polish.SideTerraces2Planting] = STAY,
	[polish.StoneOutcrops2] = STAY,
}
local rays = RaycastParams.new()
rays.FilterType = Enum.RaycastFilterType.Exclude
local function supportOffset(item, c)
	rays.FilterDescendantsInstances = { item, map.TerraceChecker }
	local hit = workspace:Raycast(c + V(0, 3, 0), V(0, -12, 0), rays)
	local x = hit and hit.Instance
	local link = x and x.Parent == map.SurfaceSeparation and x:FindFirstChild("OriginalPart")
	if link and link.Value then
		x = link.Value
	end
	while x and x ~= map do
		if groupOf[x] then
			return groupOf[x]
		end
		x = x.Parent
	end
	return nil
end
local looseSets = {
	map.SmallMapFlowers:GetChildren(),
	sw.ImprovedLobbyFlowers:GetChildren(),
	map.NativeEnvironment.LobbyAccents:GetChildren(),
	map.NativeEnvironment.Trees:GetChildren(),
	map.EnvironmentPolish.LobbyGardens:GetChildren(),
}
for _, set in looseSets do
	for _, item in set do
		local c = center(item)
		if c and c.X > -100 and c.X < 230 and c.Z > 124 and c.Z < 400 then
			local offset = c.Y > 25 and supportOffset(item, c) or nil
			assign(item, offset or byPosition(c))
		end
	end
end

-- 4. Apply the plan.
local moved = 0
local function remember(p)
	if p:GetAttribute("BeforeLobbyCentering") == nil then
		p:SetAttribute("BeforeLobbyCentering", p.CFrame)
	end
end
for i, step in plan do
	if i % 20 == 0 then
		task.wait()
	end
	if step.offset.Magnitude == 0 then
		continue
	end
	local delta = CFrame.new(step.offset)
	for _, p in partsOf(step.item) do
		remember(p)
		for _, r in renders[p] or {} do
			remember(r)
			r.CFrame = delta * r.CFrame
		end
		p.CFrame = delta * p.CFrame
		moved += 1
	end
	for _, m in step.item:GetDescendants() do
		if m:IsA("Model") then
			m.WorldPivot = delta * m.WorldPivot
		end
	end
	if step.item:IsA("Model") then
		step.item.WorldPivot = delta * step.item.WorldPivot
	end
end

-- 5. Tunnel: trim the east end by TRIM so both abutments are 42 studs wide, and pull the roof
-- decor of the east half in so it stays on the shorter roof (west half untouched).
local tunnel = polish.EntranceTunnel
local east = tunnel.RightAbutment.Position.X + tunnel.RightAbutment.Size.X / 2
local function trimEast(p)
	assert(p.CFrame.RightVector:FuzzyEq(V(1, 0, 0), 0.001), p:GetFullName() .. " is not axis aligned")
	for _, q in { p, table.unpack(renders[p] or {}) } do
		remember(q)
		if q:GetAttribute("BeforeLobbyCenteringSize") == nil then
			q:SetAttribute("BeforeLobbyCenteringSize", q.Size)
		end
		q.Size -= V(TRIM, 0, 0)
		q.CFrame = CFrame.new(-TRIM / 2, 0, 0) * q.CFrame
	end
end
for _, name in { "RightAbutment", "TunnelRoof", "TunnelGrassRoof" } do
	trimEast(tunnel[name])
end
local axis = 55
local squeeze = (east - TRIM - axis) / (east - axis)
local function squeezed(c)
	return V(axis + (c.X - axis) * squeeze - c.X, 0, 0)
end
-- A roof flower is a Stem with its Petals and Pollen: the whole flower takes its stem's offset.
local stems = {}
for _, item in tunnel:GetChildren() do
	if item.Name == "Stem" and item.Position.X > axis then
		table.insert(stems, item)
	end
end
local function flowerOffset(c)
	local best, bestDistance = nil, 3
	for _, stem in stems do
		local d = (V(stem.Position.X, 0, stem.Position.Z) - V(c.X, 0, c.Z)).Magnitude
		if d < bestDistance then
			best, bestDistance = stem, d
		end
	end
	return best and squeezed(best.Position)
end
local roofDecor = 0
for _, item in tunnel:GetChildren() do
	local c = center(item)
	if c and c.Y > 84 and c.X > axis - 3 then
		local offset = (item.Name == "Petals" or item.Name == "Pollen") and flowerOffset(c) or squeezed(c)
		if offset.X > -0.001 then
			continue
		end
		local delta = CFrame.new(offset)
		for _, p in partsOf(item) do
			remember(p)
			for _, r in renders[p] or {} do
				remember(r)
				r.CFrame = delta * r.CFrame
			end
			p.CFrame = delta * p.CFrame
		end
		if item:IsA("Model") then
			for _, m in item:GetDescendants() do
				if m:IsA("Model") then
					m.WorldPivot = delta * m.WorldPivot
				end
			end
			item.WorldPivot = delta * item.WorldPivot
		end
		roofDecor += 1
	end
end

-- 6. The cosmetic paving was moved as a whole; mark it as the v3 layout it now matches.
map.CompactLobbyLayout:SetAttribute("Version", 3)
local source = server.CompactLobbyLayout:Clone()
source.Name, source.Parent = "LobbyCenterRelayoutMigration", server
local ok, result = pcall(function()
	local module = require(source)
	local root = assert(module.apply(map))
	assert(root == map.CompactLobbyLayout, "Layout was rebuilt instead of kept")
	return #root:GetDescendants()
end)
source:Destroy()
assert(ok, result)

map:SetAttribute("LobbyCentered", "2026-11-01")
game:GetService("ChangeHistoryService"):SetWaypoint("After lobby centring")
return string.format(
	"planned %d items, moved %d parts, tunnel roof decor %d, layout %d",
	#plan,
	moved,
	roofDecor,
	result
)
